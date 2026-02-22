// weather-forecast-fetch — NOAA/NWS Weather API integration
// Fetches 7-day forecast for a given ZIP/coordinates
// Caches in weather_forecasts table (6h TTL)
// Auto-flags adverse conditions for scheduling
// NOAA API: api.weather.gov — FREE, no API key needed
//
// Endpoints:
//   POST { zip?, latitude?, longitude?, dates? }  → fetch & cache forecast
//   GET  ?zip=32801&date=2026-02-22                → read cached forecast

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

const NOAA_BASE = 'https://api.weather.gov'
const NOAA_USER_AGENT = '(Zafto, support@zafto.cloud)'

// Geocode ZIP to lat/lng using Nominatim (free, cached in api_cache)
async function geocodeZip(zip: string): Promise<{ lat: number; lng: number } | null> {
  try {
    const resp = await fetch(
      `https://nominatim.openstreetmap.org/search?postalcode=${zip}&country=US&format=json&limit=1`,
      { headers: { 'User-Agent': NOAA_USER_AGENT } }
    )
    if (!resp.ok) return null
    const data = await resp.json()
    if (!data.length) return null
    return { lat: parseFloat(data[0].lat), lng: parseFloat(data[0].lon) }
  } catch { return null }
}

// Get NOAA grid point from lat/lng
async function getGridPoint(lat: number, lng: number): Promise<{
  office: string; gridX: number; gridY: number; forecastUrl: string
} | null> {
  try {
    const resp = await fetch(
      `${NOAA_BASE}/points/${lat.toFixed(4)},${lng.toFixed(4)}`,
      { headers: { 'User-Agent': NOAA_USER_AGENT, 'Accept': 'application/geo+json' } }
    )
    if (!resp.ok) return null
    const data = await resp.json()
    const props = data.properties
    return {
      office: props.gridId,
      gridX: props.gridX,
      gridY: props.gridY,
      forecastUrl: props.forecast,
    }
  } catch { return null }
}

// Fetch 7-day forecast from NOAA
async function fetchForecast(forecastUrl: string): Promise<any[] | null> {
  try {
    const resp = await fetch(forecastUrl, {
      headers: { 'User-Agent': NOAA_USER_AGENT, 'Accept': 'application/geo+json' }
    })
    if (!resp.ok) return null
    const data = await resp.json()
    return data.properties?.periods || null
  } catch { return null }
}

// Fetch active alerts for a point
async function fetchAlerts(lat: number, lng: number): Promise<any[]> {
  try {
    const resp = await fetch(
      `${NOAA_BASE}/alerts/active?point=${lat.toFixed(4)},${lng.toFixed(4)}`,
      { headers: { 'User-Agent': NOAA_USER_AGENT, 'Accept': 'application/geo+json' } }
    )
    if (!resp.ok) return []
    const data = await resp.json()
    return (data.features || []).map((f: any) => ({
      alert_id: f.properties.id,
      event: f.properties.event,
      severity: f.properties.severity,
      headline: f.properties.headline,
      expires: f.properties.expires,
    }))
  } catch { return [] }
}

// Determine if weather is adverse for outdoor work
function checkAdverse(period: any, alerts: any[]): { is_adverse: boolean; reasons: string[]; flag_type: string } {
  const reasons: string[] = []
  let flag_type = 'info'

  const precip = period.probabilityOfPrecipitation?.value ?? 0
  const wind = parseInt(period.windSpeed?.replace(/[^\d]/g, '') || '0')
  const temp = period.temperature ?? 70

  if (precip > 50) { reasons.push('rain_above_50pct'); flag_type = 'warning' }
  if (wind > 25) { reasons.push('wind_above_25mph'); flag_type = wind > 40 ? 'severe' : 'warning' }
  if (temp < 20) { reasons.push('temp_below_20f'); flag_type = flag_type === 'severe' ? 'severe' : 'warning' }
  if (temp > 105) { reasons.push('extreme_heat'); flag_type = 'severe' }
  if (alerts.length > 0) { reasons.push('nws_alert_active'); flag_type = 'extreme' }

  return { is_adverse: reasons.length > 0, reasons, flag_type }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return corsResponse(req)

  const cors = getCorsHeaders(req)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Auth check
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return errorResponse('Missing authorization', 401, cors)
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )
  const { data: { user }, error: authErr } = await userClient.auth.getUser()
  if (authErr || !user) return errorResponse('Unauthorized', 401, cors)

  try {
    // GET: Read cached forecast
    if (req.method === 'GET') {
      const url = new URL(req.url)
      const zip = url.searchParams.get('zip')
      const date = url.searchParams.get('date') || new Date().toISOString().split('T')[0]

      if (!zip) return errorResponse('zip parameter required', 400, cors)

      const { data: cached } = await supabase
        .from('weather_forecasts')
        .select('*')
        .eq('zip', zip)
        .eq('forecast_date', date)
        .gt('expires_at', new Date().toISOString())
        .order('fetched_at', { ascending: false })
        .limit(1)
        .single()

      if (cached) {
        return new Response(JSON.stringify({ source: 'cache', forecast: cached }), {
          headers: { ...cors, 'Content-Type': 'application/json' }
        })
      }

      return new Response(JSON.stringify({ source: 'none', message: 'No cached forecast. POST to fetch.' }), {
        status: 404,
        headers: { ...cors, 'Content-Type': 'application/json' }
      })
    }

    // POST: Fetch fresh forecast from NOAA
    if (req.method === 'POST') {
      const body = await req.json()
      let { zip, latitude, longitude } = body

      // Resolve coordinates
      if (zip && (!latitude || !longitude)) {
        const geo = await geocodeZip(zip)
        if (!geo) return errorResponse(`Could not geocode ZIP: ${zip}`, 400, cors)
        latitude = geo.lat
        longitude = geo.lng
      }

      if (!latitude || !longitude) {
        return errorResponse('Provide zip or latitude+longitude', 400, cors)
      }

      // Get NOAA grid point
      const grid = await getGridPoint(latitude, longitude)
      if (!grid) return errorResponse('NOAA grid point lookup failed', 502, cors)

      // Fetch forecast
      const periods = await fetchForecast(grid.forecastUrl)
      if (!periods) return errorResponse('NOAA forecast fetch failed', 502, cors)

      // Fetch active alerts
      const alerts = await fetchAlerts(latitude, longitude)

      // Process and cache each period
      const forecasts: any[] = []
      for (const period of periods) {
        const forecastDate = period.startTime?.split('T')[0]
        if (!forecastDate) continue

        const windMph = parseInt(period.windSpeed?.replace(/[^\d]/g, '') || '0')
        const precip = period.probabilityOfPrecipitation?.value ?? 0
        const adverse = checkAdverse(period, alerts.filter(a =>
          !a.expires || new Date(a.expires) > new Date()
        ))

        // Build active alerts for this date
        const dateAlerts = alerts.filter(a => {
          if (!a.expires) return true
          return new Date(a.expires) > new Date(forecastDate)
        })

        const record = {
          zip: zip || null,
          latitude,
          longitude,
          grid_office: grid.office,
          grid_x: grid.gridX,
          grid_y: grid.gridY,
          forecast_date: forecastDate,
          period_name: period.name,
          temperature_high_f: period.isDaytime ? period.temperature : null,
          temperature_low_f: !period.isDaytime ? period.temperature : null,
          temperature_unit: period.temperatureUnit || 'F',
          wind_speed_mph: windMph,
          wind_direction: period.windDirection,
          precipitation_pct: precip,
          weather_condition: period.shortForecast,
          short_forecast: period.shortForecast,
          detailed_forecast: period.detailedForecast,
          icon_url: period.icon,
          is_adverse: adverse.is_adverse,
          adverse_reasons: adverse.reasons,
          active_alerts: dateAlerts,
          raw_response: period,
          fetched_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 6 * 60 * 60 * 1000).toISOString(),
        }

        // Upsert (replace old forecast for same location/date/period)
        const { data: upserted, error: upsertErr } = await supabase
          .from('weather_forecasts')
          .upsert(record, {
            onConflict: 'id',
            ignoreDuplicates: false
          })
          .select()
          .single()

        if (!upsertErr) {
          forecasts.push(upserted || record)
        }
      }

      return new Response(JSON.stringify({
        source: 'noaa',
        grid: { office: grid.office, x: grid.gridX, y: grid.gridY },
        alerts_active: alerts.length,
        forecasts_cached: forecasts.length,
        forecasts,
      }), {
        headers: { ...cors, 'Content-Type': 'application/json' }
      })
    }

    return errorResponse('Method not allowed', 405, cors)
  } catch (err) {
    return errorResponse(`Internal error: ${(err as Error).message}`, 500, cors)
  }
})
