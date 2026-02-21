/**
 * DEPTH28 S130: Storm Hunter Tool for Storm Contractors
 * Real-time severe weather alerts, hail swath maps, storm scoring,
 * territory mapping, integration with Recon for auto-scan.
 * ALL weather data is free (NWS/NOAA/FEMA).
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'
import { fleetFetch } from '../_shared/api-fleet.ts'

const EF_NAME = 'recon-storm-hunter'

interface StormEvent {
  id: string
  type: string            // 'hail', 'wind', 'tornado', 'flood'
  date: string
  state: string
  county: string
  latitude: number | null
  longitude: number | null
  magnitude: number | null
  magnitudeUnit: string | null
  description: string
  source: string
}

interface StormScore {
  overallScore: number      // 0-100
  hailScore: number
  windScore: number
  propertyDensityScore: number
  revenueEstimate: string   // qualitative: low/medium/high/very_high
  factors: Record<string, unknown>
}

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)
  if (req.method !== 'POST') return errorResponse('Method not allowed', 405, origin)

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return errorResponse('Missing authorization', 401, origin)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authErr } = await supabase.auth.getUser(token)
  if (authErr || !user) return errorResponse('Unauthorized', 401, origin)

  const companyId = user.app_metadata?.company_id
  if (!companyId) return errorResponse('No company', 403, origin)

  try {
    const body = await req.json() as {
      action: 'active_alerts' | 'recent_storms' | 'storm_score' | 'hail_swath'
      latitude?: number
      longitude?: number
      radius_miles?: number
      state?: string
      county?: string
      days_back?: number
    }

    switch (body.action) {
      case 'active_alerts':
        return await getActiveAlerts(body, companyId, origin)
      case 'recent_storms':
        return await getRecentStorms(body, companyId, origin)
      case 'storm_score':
        return await getStormScore(body, companyId, origin)
      case 'hail_swath':
        return await getHailSwath(body, companyId, origin)
      default:
        return errorResponse('Invalid action. Use: active_alerts, recent_storms, storm_score, hail_swath', 400, origin)
    }
  } catch (e) {
    console.error(`[${EF_NAME}] Error:`, e)
    return errorResponse(e instanceof Error ? e.message : 'Storm hunter failed', 500, origin)
  }
})

// ============================================================================
// ACTION: Get active NWS severe weather alerts
// ============================================================================

async function getActiveAlerts(
  params: { state?: string; latitude?: number; longitude?: number },
  companyId: string,
  origin: string | null,
): Promise<Response> {
  let url = 'https://api.weather.gov/alerts/active?status=actual&message_type=alert'

  if (params.state) {
    url += `&area=${params.state}`
  } else if (params.latitude && params.longitude) {
    // NWS alerts by point
    url = `https://api.weather.gov/alerts/active?point=${params.latitude},${params.longitude}`
  }

  // Filter for severe weather only
  url += '&severity=Extreme,Severe'

  const result = await fleetFetch('nws_alerts', url, { companyId, edgeFunction: EF_NAME })

  if (!result.response?.ok) {
    return json({ alerts: [], error: result.reason || 'NWS API unavailable' }, origin)
  }

  const data = await result.response.json()
  const features = data?.features || []

  const alerts = features.map((f: Record<string, unknown>) => {
    const props = f.properties as Record<string, unknown>
    return {
      id: props.id,
      event: props.event,               // 'Severe Thunderstorm Warning', 'Tornado Warning', etc.
      severity: props.severity,
      certainty: props.certainty,
      urgency: props.urgency,
      headline: props.headline,
      description: props.description,
      instruction: props.instruction,
      effective: props.effective,
      expires: props.expires,
      areas: props.areaDesc,
      senderName: props.senderName,
      // Extract hail/wind info from parameters
      maxHail: extractParam(props.parameters as Record<string, string[]>, 'maxHailSize'),
      maxWind: extractParam(props.parameters as Record<string, string[]>, 'maxWindGust'),
      tornadoDetection: extractParam(props.parameters as Record<string, string[]>, 'tornadoDetection'),
    }
  })

  // Sort by severity (Extreme first) then by time
  alerts.sort((a: Record<string, string>, b: Record<string, string>) => {
    const sevOrder: Record<string, number> = { Extreme: 0, Severe: 1, Moderate: 2, Minor: 3 }
    return (sevOrder[a.severity] || 9) - (sevOrder[b.severity] || 9)
  })

  return json({
    alerts,
    count: alerts.length,
    fetched_at: new Date().toISOString(),
    source: 'NWS',
  }, origin)
}

// ============================================================================
// ACTION: Get recent storm events from FEMA
// ============================================================================

async function getRecentStorms(
  params: { state?: string; days_back?: number; latitude?: number; longitude?: number },
  companyId: string,
  origin: string | null,
): Promise<Response> {
  const daysBack = params.days_back || 30
  const sinceDate = new Date()
  sinceDate.setDate(sinceDate.getDate() - daysBack)

  let url = `https://www.fema.gov/api/open/v2/FemaWebDisasterDeclarations?$orderby=declarationDate desc&$top=50&$filter=declarationDate ge '${sinceDate.toISOString()}'`

  if (params.state) {
    url += ` and stateCode eq '${params.state}'`
  }

  const result = await fleetFetch('fema_disasters', url, { companyId, edgeFunction: EF_NAME })

  if (!result.response?.ok) {
    return json({ storms: [], error: result.reason || 'FEMA API unavailable' }, origin)
  }

  const data = await result.response.json()
  const events = data?.FemaWebDisasterDeclarations || []

  // Filter for weather-related disasters
  const stormTypes = ['Severe Storm', 'Hurricane', 'Tornado', 'Flood', 'Severe Ice Storm', 'Typhoon']
  const storms = events
    .filter((e: Record<string, string>) =>
      stormTypes.some(t => (e.incidentType || '').includes(t))
    )
    .map((e: Record<string, string>) => ({
      id: e.disasterNumber,
      type: e.incidentType,
      title: e.declarationTitle,
      state: e.stateCode,
      county: e.designatedArea,
      date: e.declarationDate?.split('T')[0],
      incidentBegin: e.incidentBeginDate?.split('T')[0],
      incidentEnd: e.incidentEndDate?.split('T')[0],
      programsActive: {
        ihp: e.ihProgramDeclared === 'true',
        ia: e.iaProgramDeclared === 'true',
        pa: e.paProgramDeclared === 'true',
        hm: e.hmProgramDeclared === 'true',
      },
    }))

  return json({
    storms,
    count: storms.length,
    days_back: daysBack,
    fetched_at: new Date().toISOString(),
    source: 'FEMA',
  }, origin)
}

// ============================================================================
// ACTION: Storm scoring for canvassing
// ============================================================================

async function getStormScore(
  params: { latitude?: number; longitude?: number; state?: string; county?: string },
  companyId: string,
  origin: string | null,
): Promise<Response> {
  if (!params.latitude || !params.longitude) {
    return errorResponse('latitude and longitude required for storm scoring', 400, origin)
  }

  const lat = params.latitude
  const lng = params.longitude

  // Get active alerts for the area
  const alertResult = await fleetFetch('nws_alerts',
    `https://api.weather.gov/alerts/active?point=${lat},${lng}&severity=Extreme,Severe`,
    { companyId, edgeFunction: EF_NAME }
  )

  let activeAlerts = 0
  let maxHailInches = 0
  let maxWindMph = 0

  if (alertResult.response?.ok) {
    const alertData = await alertResult.response.json()
    const features = alertData?.features || []
    activeAlerts = features.length

    for (const f of features) {
      const props = f.properties as Record<string, unknown>
      const hail = extractParam(props.parameters as Record<string, string[]>, 'maxHailSize')
      const wind = extractParam(props.parameters as Record<string, string[]>, 'maxWindGust')
      if (hail) maxHailInches = Math.max(maxHailInches, parseFloat(hail) || 0)
      if (wind) maxWindMph = Math.max(maxWindMph, parseFloat(wind) || 0)
    }
  }

  // Calculate storm score
  const score: StormScore = {
    overallScore: 0,
    hailScore: 0,
    windScore: 0,
    propertyDensityScore: 50, // Default medium density
    revenueEstimate: 'low',
    factors: {},
  }

  // Hail scoring (golf ball+ = jackpot for roofers)
  if (maxHailInches >= 2.0) { score.hailScore = 100 }
  else if (maxHailInches >= 1.5) { score.hailScore = 85 }
  else if (maxHailInches >= 1.0) { score.hailScore = 70 }
  else if (maxHailInches >= 0.75) { score.hailScore = 50 }
  else if (maxHailInches > 0) { score.hailScore = 25 }

  // Wind scoring (>60 mph = significant damage potential)
  if (maxWindMph >= 80) { score.windScore = 100 }
  else if (maxWindMph >= 70) { score.windScore = 80 }
  else if (maxWindMph >= 60) { score.windScore = 60 }
  else if (maxWindMph >= 50) { score.windScore = 30 }

  // Active alert boost
  const alertBoost = Math.min(activeAlerts * 15, 30)

  // Overall score
  score.overallScore = Math.min(
    Math.round(score.hailScore * 0.4 + score.windScore * 0.3 + score.propertyDensityScore * 0.2 + alertBoost),
    100
  )

  // Revenue estimate
  score.revenueEstimate = score.overallScore >= 80 ? 'very_high' :
    score.overallScore >= 60 ? 'high' :
    score.overallScore >= 40 ? 'medium' : 'low'

  score.factors = {
    active_alerts: activeAlerts,
    max_hail_inches: maxHailInches,
    max_wind_mph: maxWindMph,
    alert_boost: alertBoost,
  }

  return json({
    score,
    location: { latitude: lat, longitude: lng },
    fetched_at: new Date().toISOString(),
    recommendation: score.overallScore >= 60
      ? 'HIGH OPPORTUNITY — Deploy canvassing crews to this area immediately'
      : score.overallScore >= 40
        ? 'MODERATE — Monitor and prepare for deployment'
        : 'LOW — No significant storm activity detected',
  }, origin)
}

// ============================================================================
// ACTION: Hail swath data from NOAA SPC
// ============================================================================

async function getHailSwath(
  params: { state?: string; days_back?: number },
  companyId: string,
  origin: string | null,
): Promise<Response> {
  const daysBack = params.days_back || 7

  // NOAA SPC storm reports (last N days)
  const today = new Date()
  const since = new Date(today.getTime() - daysBack * 86400000)
  const dateStr = `${since.getFullYear()}${String(since.getMonth() + 1).padStart(2, '0')}${String(since.getDate()).padStart(2, '0')}`

  // SPC filtered storm reports
  const result = await fleetFetch('noaa_spc',
    `https://www.spc.noaa.gov/climo/reports/${dateStr.slice(2)}_rpts_filtered_hail.csv`,
    { companyId, edgeFunction: EF_NAME }
  )

  const hailReports: Array<{
    date: string
    time: string
    size_inches: number
    location: string
    county: string
    state: string
    latitude: number
    longitude: number
  }> = []

  if (result.response?.ok) {
    const text = await result.response.text()
    const lines = text.split('\n').slice(1) // Skip header

    for (const line of lines) {
      const parts = line.split(',')
      if (parts.length < 8) continue

      const sizeInHundredths = parseInt(parts[4]) || 0
      const sizeInches = sizeInHundredths / 100

      if (params.state && parts[6]?.trim() !== params.state) continue

      hailReports.push({
        date: parts[0]?.trim() || '',
        time: parts[1]?.trim() || '',
        size_inches: sizeInches,
        location: parts[5]?.trim() || '',
        county: parts[7]?.trim() || '',
        state: parts[6]?.trim() || '',
        latitude: parseFloat(parts[2]) || 0,
        longitude: -(parseFloat(parts[3]) || 0), // SPC uses positive west
      })
    }
  }

  // Sort by hail size descending
  hailReports.sort((a, b) => b.size_inches - a.size_inches)

  return json({
    hail_reports: hailReports.slice(0, 100), // Limit to top 100
    count: hailReports.length,
    days_back: daysBack,
    max_hail: hailReports.length > 0 ? hailReports[0].size_inches : 0,
    states_affected: [...new Set(hailReports.map(r => r.state))],
    fetched_at: new Date().toISOString(),
    source: 'NOAA_SPC',
  }, origin)
}

// ============================================================================
// HELPERS
// ============================================================================

function extractParam(params: Record<string, string[]> | null, key: string): string | null {
  if (!params) return null
  const values = params[key]
  return values?.[0] || null
}

function json(body: Record<string, unknown>, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
  })
}
