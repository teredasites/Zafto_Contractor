// Supabase Edge Function: recon-storm-assess
// NOAA Storm Events integration + damage probability model.
// FREE data sources: NOAA Storm Events Database, SPC Storm Reports.
// Computes per-parcel damage probability for area scans.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

interface StormEvent {
  event_id: string
  event_type: string // 'Hail', 'Thunderstorm Wind', 'Tornado'
  begin_date: string
  end_date: string
  state: string
  cz_name: string // county/zone name
  magnitude: number | null // hail size in inches, wind speed in knots
  magnitude_type: string | null
  begin_lat: number | null
  begin_lon: number | null
  damage_property: string | null
  tor_f_scale: string | null // Tornado F/EF scale
}

// Fetch storm events from NOAA Storm Events Database (FREE)
async function fetchNoaaStormEvents(
  state: string,
  startDate: string,
  endDate: string,
  county?: string,
): Promise<StormEvent[]> {
  try {
    // NOAA Storm Events CSV API
    const year = new Date(startDate).getFullYear()
    const url = `https://www.ncdc.noaa.gov/stormevents/csv?eventType=ALL&beginDate_mm=${
      String(new Date(startDate).getMonth() + 1).padStart(2, '0')
    }&beginDate_dd=${
      String(new Date(startDate).getDate()).padStart(2, '0')
    }&beginDate_yyyy=${year}&endDate_mm=${
      String(new Date(endDate).getMonth() + 1).padStart(2, '0')
    }&endDate_dd=${
      String(new Date(endDate).getDate()).padStart(2, '0')
    }&endDate_yyyy=${new Date(endDate).getFullYear()}&county=${
      county ? encodeURIComponent(county.toUpperCase()) : 'ALL'
    }&hailfilter=0.00&tornfilter=0&windfilter=000&sort=DT&submitbutton=Search&staession=${
      encodeURIComponent(state.toUpperCase())
    }`

    const res = await fetch(url)
    if (!res.ok) return []

    const text = await res.text()
    return parseStormCsv(text)
  } catch {
    return []
  }
}

// Fetch SPC storm reports (FREE — plain text)
async function fetchSpcReports(date: string): Promise<StormEvent[]> {
  try {
    // SPC uses YYMMDD format
    const d = new Date(date)
    const yy = String(d.getFullYear()).slice(2)
    const mm = String(d.getMonth() + 1).padStart(2, '0')
    const dd = String(d.getDate()).padStart(2, '0')

    const events: StormEvent[] = []

    // Fetch hail reports
    const hailRes = await fetch(`https://www.spc.noaa.gov/climo/reports/${yy}${mm}${dd}_rpts_hail.csv`)
    if (hailRes.ok) {
      const text = await hailRes.text()
      const parsed = parseSpcCsv(text, 'Hail')
      events.push(...parsed)
    }

    // Fetch wind reports
    const windRes = await fetch(`https://www.spc.noaa.gov/climo/reports/${yy}${mm}${dd}_rpts_wind.csv`)
    if (windRes.ok) {
      const text = await windRes.text()
      const parsed = parseSpcCsv(text, 'Thunderstorm Wind')
      events.push(...parsed)
    }

    // Fetch tornado reports
    const torRes = await fetch(`https://www.spc.noaa.gov/climo/reports/${yy}${mm}${dd}_rpts_torn.csv`)
    if (torRes.ok) {
      const text = await torRes.text()
      const parsed = parseSpcCsv(text, 'Tornado')
      events.push(...parsed)
    }

    return events
  } catch {
    return []
  }
}

function parseStormCsv(csv: string): StormEvent[] {
  const lines = csv.split('\n').filter(l => l.trim())
  if (lines.length < 2) return []

  const events: StormEvent[] = []
  // Skip header row
  for (let i = 1; i < lines.length && i < 500; i++) {
    const cols = lines[i].split(',').map(c => c.replace(/"/g, '').trim())
    if (cols.length < 10) continue

    events.push({
      event_id: cols[0] || `noaa_${i}`,
      event_type: cols[1] || 'Unknown',
      begin_date: cols[2] || '',
      end_date: cols[3] || '',
      state: cols[4] || '',
      cz_name: cols[5] || '',
      magnitude: cols[6] ? Number(cols[6]) || null : null,
      magnitude_type: cols[7] || null,
      begin_lat: cols[8] ? Number(cols[8]) || null : null,
      begin_lon: cols[9] ? Number(cols[9]) || null : null,
      damage_property: cols[10] || null,
      tor_f_scale: cols[11] || null,
    })
  }
  return events
}

function parseSpcCsv(csv: string, eventType: string): StormEvent[] {
  const lines = csv.split('\n').filter(l => l.trim())
  if (lines.length < 2) return []

  const events: StormEvent[] = []
  for (let i = 1; i < lines.length && i < 500; i++) {
    const cols = lines[i].split(',').map(c => c.replace(/"/g, '').trim())
    if (cols.length < 8) continue

    events.push({
      event_id: `spc_${eventType}_${i}`,
      event_type: eventType,
      begin_date: cols[0] || '',
      end_date: cols[0] || '',
      state: cols[5] || '',
      cz_name: cols[6] || '',
      magnitude: cols[4] ? Number(cols[4]) || null : null,
      magnitude_type: eventType === 'Hail' ? 'inches' : 'knots',
      begin_lat: cols[2] ? Number(cols[2]) || null : null,
      begin_lon: cols[3] ? Number(cols[3]) || null : null,
      damage_property: null,
      tor_f_scale: eventType === 'Tornado' ? (cols[4] || null) : null,
    })
  }
  return events
}

// Haversine distance in miles
function haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 3959 // Earth radius in miles
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

// Damage probability model
// P(damage) = f(hail_size, wind_speed, roof_age, proximity)
function computeDamageProbability(
  events: StormEvent[],
  lat: number,
  lon: number,
  yearBuilt: number | null,
): { probability: number; maxHailInches: number; maxWindKnots: number; nearestEventMiles: number } {
  const currentYear = new Date().getFullYear()
  const roofAge = yearBuilt ? currentYear - yearBuilt : 20 // assume 20 if unknown

  let maxHail = 0
  let maxWind = 0
  let nearestEvent = Infinity

  for (const event of events) {
    if (event.begin_lat && event.begin_lon) {
      const dist = haversineDistance(lat, lon, event.begin_lat, event.begin_lon)
      nearestEvent = Math.min(nearestEvent, dist)

      // Only consider events within 10 miles
      if (dist > 10) continue

      if (event.event_type === 'Hail' && event.magnitude) {
        maxHail = Math.max(maxHail, event.magnitude)
      }
      if (event.event_type.includes('Wind') && event.magnitude) {
        maxWind = Math.max(maxWind, event.magnitude)
      }
      if (event.event_type === 'Tornado') {
        maxWind = Math.max(maxWind, 100) // Tornado = high wind
      }
    }
  }

  // Probability model
  let prob = 0

  // Hail damage probability
  if (maxHail >= 2.0) prob += 0.45  // Golf ball+
  else if (maxHail >= 1.5) prob += 0.35
  else if (maxHail >= 1.0) prob += 0.25
  else if (maxHail >= 0.75) prob += 0.10

  // Wind damage probability
  if (maxWind >= 80) prob += 0.30  // 80+ knots
  else if (maxWind >= 65) prob += 0.20
  else if (maxWind >= 50) prob += 0.10

  // Roof age modifier
  if (roofAge > 25) prob *= 1.5
  else if (roofAge > 20) prob *= 1.3
  else if (roofAge > 15) prob *= 1.1
  else if (roofAge < 5) prob *= 0.6

  // Cap at 95%
  prob = Math.min(0.95, Math.max(0, prob))

  return {
    probability: Math.round(prob * 100),
    maxHailInches: maxHail,
    maxWindKnots: maxWind,
    nearestEventMiles: nearestEvent === Infinity ? -1 : Math.round(nearestEvent * 10) / 10,
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return jsonResponse({ error: 'Missing authorization' }, 401)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401)
  }

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return jsonResponse({ error: 'No company' }, 403)
  }

  try {
    const body = await req.json()
    const {
      area_scan_id,
      property_scan_id,
      storm_date,
      state,
      county,
    } = body as {
      area_scan_id?: string
      property_scan_id?: string
      storm_date: string
      state: string
      county?: string
    }

    if (!storm_date || !state) {
      return jsonResponse({ error: 'storm_date and state required' }, 400)
    }

    // Create date range (3 days around storm date)
    const stormDate = new Date(storm_date)
    const startDate = new Date(stormDate)
    startDate.setDate(startDate.getDate() - 1)
    const endDate = new Date(stormDate)
    endDate.setDate(endDate.getDate() + 1)

    // Fetch storm events from both sources
    const [noaaEvents, spcEvents] = await Promise.all([
      fetchNoaaStormEvents(state, startDate.toISOString(), endDate.toISOString(), county),
      fetchSpcReports(storm_date),
    ])

    const allEvents = [...noaaEvents, ...spcEvents]

    // Single property assessment
    if (property_scan_id) {
      const { data: scan } = await supabase
        .from('property_scans')
        .select('id, latitude, longitude')
        .eq('id', property_scan_id)
        .eq('company_id', companyId)
        .single()

      if (!scan || !scan.latitude || !scan.longitude) {
        return jsonResponse({ error: 'Scan not found or missing coordinates' }, 404)
      }

      const { data: features } = await supabase
        .from('property_features')
        .select('year_built')
        .eq('scan_id', property_scan_id)
        .limit(1)
        .maybeSingle()

      const yearBuilt = features?.year_built ? Number(features.year_built) : null
      const result = computeDamageProbability(
        allEvents,
        Number(scan.latitude),
        Number(scan.longitude),
        yearBuilt,
      )

      // Update lead score with storm data
      await supabase
        .from('property_lead_scores')
        .update({ storm_damage_probability: result.probability })
        .eq('property_scan_id', property_scan_id)
        .eq('company_id', companyId)

      return jsonResponse({
        property_scan_id,
        storm_events_found: allEvents.length,
        ...result,
      })
    }

    // Area scan assessment
    if (area_scan_id) {
      const { data: leads } = await supabase
        .from('property_lead_scores')
        .select('id, property_scan_id, property_scans(latitude, longitude)')
        .eq('area_scan_id', area_scan_id)
        .eq('company_id', companyId)

      const results: Array<{
        property_scan_id: string
        probability: number
        max_hail: number
        max_wind: number
      }> = []

      for (const lead of (leads || [])) {
        const ps = lead.property_scans as Record<string, unknown> | null
        if (!ps?.latitude || !ps?.longitude) continue

        const result = computeDamageProbability(
          allEvents,
          Number(ps.latitude),
          Number(ps.longitude),
          null,
        )

        // Update storm probability on lead score
        await supabase
          .from('property_lead_scores')
          .update({ storm_damage_probability: result.probability })
          .eq('id', lead.id)

        results.push({
          property_scan_id: lead.property_scan_id as string,
          probability: result.probability,
          max_hail: result.maxHailInches,
          max_wind: result.maxWindKnots,
        })
      }

      // Sort by probability (highest first)
      results.sort((a, b) => b.probability - a.probability)

      return jsonResponse({
        area_scan_id,
        storm_events_found: allEvents.length,
        properties_assessed: results.length,
        high_probability: results.filter(r => r.probability >= 50).length,
        medium_probability: results.filter(r => r.probability >= 25 && r.probability < 50).length,
        low_probability: results.filter(r => r.probability < 25).length,
        results: results.slice(0, 100),
      })
    }

    return jsonResponse({ error: 'area_scan_id or property_scan_id required' }, 400)
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
