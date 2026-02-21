/**
 * DEPTH28 Part B+C: Property Intelligence & Weather Edge Function
 * Called AFTER recon-property-lookup completes the base scan.
 * Fetches: property profile, permit history, environmental data,
 * weather conditions, storm history, climate data, material indices.
 * All from $0/month free APIs.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'
import { fleetFetch, trackApiUsage } from '../_shared/api-fleet.ts'

const EF_NAME = 'recon-property-intelligence'

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)
  if (req.method !== 'POST') {
    return errorResponse('Method not allowed', 405, origin)
  }

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
    const { scan_id } = await req.json() as { scan_id: string }
    if (!scan_id) return errorResponse('scan_id required', 400, origin)

    // Get the base scan data
    const { data: scan, error: scanErr } = await supabase
      .from('property_scans')
      .select('*')
      .eq('id', scan_id)
      .eq('company_id', companyId)
      .single()

    if (scanErr || !scan) return errorResponse('Scan not found', 404, origin)

    const lat = Number(scan.latitude)
    const lng = Number(scan.longitude)
    if (!lat || !lng) return errorResponse('Scan missing coordinates', 422, origin)

    const yearBuilt = scan.raw_google_solar?.imageryDate?.year as number | undefined
    const state = scan.state as string || ''
    const zip = scan.zip as string || ''
    const dataSources: string[] = []
    const rawResponses: Record<string, unknown> = {}

    // ========================================================================
    // Part B: PROPERTY PROFILE
    // ========================================================================

    let profileData: Record<string, unknown> = {}

    // 1. Environmental hazards — EPA Radon Zones (free, no key)
    const radonZone = getEpaRadonZone(state)

    // 2. Lead paint probability (based on year built)
    const leadProb = !yearBuilt ? 'unknown' :
      yearBuilt < 1960 ? 'high' :
      yearBuilt < 1978 ? 'moderate' :
      yearBuilt < 1990 ? 'low' : 'none'

    // 3. Asbestos probability
    const asbestosProb = !yearBuilt ? 'unknown' :
      yearBuilt < 1970 ? 'high' :
      yearBuilt < 1980 ? 'moderate' :
      yearBuilt < 1990 ? 'low' : 'none'

    // 4. Construction type estimation from year
    const constructionType = !yearBuilt ? null :
      yearBuilt < 1920 ? 'masonry' :
      yearBuilt < 1950 ? 'wood_frame' :
      yearBuilt > 2010 ? 'wood_frame' : 'wood_frame'

    // 5. Foundation type estimation
    const foundationType = !yearBuilt ? null :
      state && ['FL', 'TX', 'LA', 'MS', 'AL', 'GA', 'SC'].includes(state) ? 'slab' :
      yearBuilt < 1950 ? 'basement' :
      yearBuilt < 1980 ? 'crawlspace' : 'slab'

    // 6. Service amperage estimation
    const serviceAmperage = !yearBuilt ? null :
      yearBuilt < 1960 ? 60 :
      yearBuilt < 1970 ? 100 :
      yearBuilt < 2000 ? 150 : 200

    // 7. Window frame estimation
    const frameMaterial = !yearBuilt ? null :
      yearBuilt < 1960 ? 'wood' :
      yearBuilt < 1990 ? 'aluminum' : 'vinyl'

    // 8. Frost line depth from climate zone
    const frostLine = getFrostLineDepth(state)

    // 9. Climate zone from state
    const climateZone = getClimateZone(state, lat)

    // 10. FEMA flood zone (free, no key)
    let floodZone: string | null = null
    let floodRisk: string = 'unknown'
    try {
      const femaResult = await fleetFetch('fema_nfhl',
        `https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/28/query?geometry=${lng},${lat}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=FLD_ZONE,ZONE_SUBTY&returnGeometry=false&f=json`,
        { companyId, edgeFunction: EF_NAME }
      )
      if (femaResult.response?.ok) {
        const femaData = await femaResult.response.json()
        const feature = femaData?.features?.[0]?.attributes
        if (feature) {
          floodZone = feature.FLD_ZONE || null
          floodRisk = floodZone === 'A' || floodZone === 'AE' || floodZone === 'AH' || floodZone === 'AO' || floodZone === 'V' || floodZone === 'VE' ? 'high' :
            floodZone === 'X' && feature.ZONE_SUBTY === '0.2 PCT ANNUAL CHANCE FLOOD HAZARD' ? 'moderate' :
            floodZone === 'X' ? 'minimal' : 'unknown'
          dataSources.push('fema_nfhl')
          rawResponses['fema_nfhl'] = femaData
        }
      }
    } catch (e) {
      console.error('[prop-intel] FEMA flood zone error:', e)
    }

    // 11. Wildfire risk (USFS - free, no key)
    let wildfireScore: number | null = null
    try {
      const wfResult = await fleetFetch('usfs_wildfire',
        `https://apps.fs.usda.gov/arcx/rest/services/RDW_Wildfire/ProbabilisticWildfireRisk/MapServer/0/query?geometry=${lng},${lat}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=WHPCLASS&returnGeometry=false&f=json`,
        { companyId, edgeFunction: EF_NAME }
      )
      if (wfResult.response?.ok) {
        const wfData = await wfResult.response.json()
        const whp = wfData?.features?.[0]?.attributes?.WHPCLASS
        if (whp != null) {
          wildfireScore = Number(whp) * 20 // Convert 1-5 scale to 0-100
          dataSources.push('usfs_wildfire')
          rawResponses['usfs_wildfire'] = wfData
        }
      }
    } catch (e) {
      console.error('[prop-intel] Wildfire risk error:', e)
    }

    // 12. USDA Soil type (free, no key)
    let soilType: string | null = null
    let expansiveSoilRisk: string | null = null
    try {
      const soilQuery = `SELECT mu.muname FROM mapunit mu INNER JOIN component co ON mu.mukey = co.mukey WHERE mu.mukey IN (SELECT mukey FROM SDA_Get_Mukey_from_intersection_with_WktWgs84('POINT(${lng} ${lat})'))`
      const soilResult = await fleetFetch('usda_soil',
        `https://SDMDataAccess.sc.egov.usda.gov/Tabular/post.rest`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: soilQuery }),
          companyId,
          edgeFunction: EF_NAME,
        }
      )
      if (soilResult.response?.ok) {
        const soilData = await soilResult.response.json()
        const soilName = soilData?.Table?.[0]?.[0]
        if (soilName) {
          soilType = soilName
          // Check for expansive soil keywords
          const lower = soilName.toLowerCase()
          expansiveSoilRisk = lower.includes('clay') || lower.includes('vertisol') ? 'high' :
            lower.includes('silt') ? 'moderate' : 'low'
          dataSources.push('usda_soil')
          rawResponses['usda_soil'] = soilData
        }
      }
    } catch (e) {
      console.error('[prop-intel] USDA soil error:', e)
    }

    // 13. Termite risk zone from state
    const termiteZone = getTermiteZone(state)

    // 14. Seismic zone from state
    const seismicZone = getSeismicZone(state)

    // Build profile data
    profileData = {
      scan_id: scan_id,
      company_id: companyId,
      year_built: yearBuilt || null,
      construction_type: constructionType,
      foundation_type: foundationType,
      service_amperage: serviceAmperage,
      lead_paint_probability: leadProb === 'unknown' ? null : leadProb,
      asbestos_probability: asbestosProb === 'unknown' ? null : asbestosProb,
      radon_zone: radonZone,
      termite_zone: termiteZone,
      flood_zone: floodZone,
      flood_risk_level: floodRisk,
      wildfire_risk_score: wildfireScore,
      seismic_zone: seismicZone,
      expansive_soil_risk: expansiveSoilRisk,
      frost_line_depth_inches: frostLine,
      climate_zone: climateZone,
      data_sources: dataSources,
      confidence_score: Math.min(dataSources.length * 15, 85),
      raw_responses: rawResponses,
    }

    // Insert property profile
    const { data: profile } = await supabase
      .from('property_profiles')
      .insert(profileData)
      .select('id')
      .single()

    // Update scan with profile ID
    if (profile) {
      await supabase
        .from('property_scans')
        .update({ property_profile_id: profile.id })
        .eq('id', scan_id)
    }

    // ========================================================================
    // Part C: WEATHER & STORM INTELLIGENCE
    // ========================================================================

    let weatherData: Record<string, unknown> = {}

    // 1. Current weather (Open-Meteo — free, no key)
    try {
      const wxResult = await fleetFetch('open_meteo',
        `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&current=temperature_2m,wind_speed_10m,precipitation,uv_index,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch`,
        { companyId, edgeFunction: EF_NAME }
      )
      if (wxResult.response?.ok) {
        const wxData = await wxResult.response.json()
        const current = wxData?.current
        if (current) {
          weatherData = {
            ...weatherData,
            current_temp_f: current.temperature_2m,
            current_wind_mph: current.wind_speed_10m,
            current_precip_mm: current.precipitation,
            current_uv_index: current.uv_index,
            current_conditions: weatherCodeToText(current.weather_code),
            weather_fetched_at: new Date().toISOString(),
          }
          dataSources.push('open_meteo')
          rawResponses['open_meteo_current'] = wxData
        }
      }
    } catch (e) {
      console.error('[prop-intel] Weather error:', e)
    }

    // 2. Climate data (Open-Meteo Climate — free, no key)
    try {
      const climResult = await fleetFetch('open_meteo',
        `https://climate-api.open-meteo.com/v1/climate?latitude=${lat}&longitude=${lng}&models=CMCC_CM2_VHR4&start_date=2020-01-01&end_date=2024-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum&temperature_unit=fahrenheit&precipitation_unit=inch`,
        { companyId, edgeFunction: EF_NAME }
      )
      if (climResult.response?.ok) {
        const climData = await climResult.response.json()
        if (climData?.daily) {
          const temps = climData.daily.temperature_2m_max || []
          const mins = climData.daily.temperature_2m_min || []
          const precip = climData.daily.precipitation_sum || []

          // Calculate freeze-thaw cycles (days where max > 32F and min < 32F)
          let ftCycles = 0
          for (let i = 0; i < mins.length; i++) {
            if (mins[i] != null && temps[i] != null && mins[i] < 32 && temps[i] > 32) ftCycles++
          }
          const avgFtPerYear = Math.round(ftCycles / 5) // 5 years of data

          // HDD and CDD
          let hdd = 0, cdd = 0
          for (let i = 0; i < temps.length; i++) {
            if (temps[i] != null && mins[i] != null) {
              const avgTemp = (temps[i] + mins[i]) / 2
              if (avgTemp < 65) hdd += (65 - avgTemp)
              if (avgTemp > 65) cdd += (avgTemp - 65)
            }
          }

          // Annual precipitation
          const totalPrecip = precip.reduce((s: number, v: number | null) => s + (v || 0), 0)
          const annualPrecip = Math.round((totalPrecip / 5) * 100) / 100

          weatherData = {
            ...weatherData,
            freeze_thaw_cycles_yr: avgFtPerYear,
            annual_precip_inches: annualPrecip,
            heating_degree_days: Math.round(hdd / 5),
            cooling_degree_days: Math.round(cdd / 5),
          }
          rawResponses['open_meteo_climate'] = { ftCycles: avgFtPerYear, hdd: Math.round(hdd / 5), cdd: Math.round(cdd / 5), annualPrecip }
        }
      }
    } catch (e) {
      console.error('[prop-intel] Climate data error:', e)
    }

    // 3. NOAA Storm Events — historical storms near this location
    // NOAA Storm Events CSV bulk download is complex, use the API
    try {
      const now = new Date()
      const fiveYrsAgo = new Date(now.getFullYear() - 5, 0, 1)
      const tenYrsAgo = new Date(now.getFullYear() - 10, 0, 1)

      // Get county FIPS for storm lookup (from Census geocoder)
      const countyFips = await getCountyFips(lat, lng)

      if (countyFips) {
        // Query FEMA disaster declarations as proxy for storm data
        const femaResult = await fleetFetch('fema_disasters',
          `https://www.fema.gov/api/open/v2/FemaWebDisasterDeclarations?$filter=fipsStateCode eq '${countyFips.slice(0, 2)}' and fipsCountyCode eq '${countyFips.slice(2)}' and declarationDate ge '${tenYrsAgo.toISOString()}'&$orderby=declarationDate desc&$top=50`,
          { companyId, edgeFunction: EF_NAME }
        )
        if (femaResult.response?.ok) {
          const femaData = await femaResult.response.json()
          const events = femaData?.FemaWebDisasterDeclarations || []

          // Count storm-type events
          const stormTypes = ['Severe Storm', 'Hurricane', 'Tornado', 'Flood', 'Severe Ice Storm']
          const stormEvents = events.filter((e: Record<string, string>) =>
            stormTypes.some(t => (e.incidentType || '').includes(t))
          )

          const events5yr = stormEvents.filter((e: Record<string, string>) =>
            new Date(e.declarationDate) >= fiveYrsAgo
          )

          // Find last major events
          const lastHail = stormEvents.find((e: Record<string, string>) =>
            (e.incidentType || '').includes('Severe Storm')
          )
          const lastTornado = stormEvents.find((e: Record<string, string>) =>
            (e.incidentType || '').includes('Tornado')
          )
          const lastFlood = stormEvents.find((e: Record<string, string>) =>
            (e.incidentType || '').includes('Flood')
          )

          weatherData = {
            ...weatherData,
            total_storm_events_5yr: events5yr.length,
            total_storm_events_10yr: stormEvents.length,
            last_hail_event_date: lastHail?.declarationDate?.split('T')[0] || null,
            last_tornado_date: lastTornado?.declarationDate?.split('T')[0] || null,
            last_flood_event_date: lastFlood?.declarationDate?.split('T')[0] || null,
          }
          dataSources.push('fema_disasters')
          rawResponses['fema_disasters'] = { count: stormEvents.length, events: stormEvents.slice(0, 10) }
        }
      }
    } catch (e) {
      console.error('[prop-intel] Storm history error:', e)
    }

    // 4. Storm damage probability score
    const stormScore = calculateStormDamageScore({
      yearBuilt: yearBuilt || 2000,
      stormEvents5yr: (weatherData.total_storm_events_5yr as number) || 0,
      stormEvents10yr: (weatherData.total_storm_events_10yr as number) || 0,
      floodZone,
      wildfireScore,
      freezeThawCycles: (weatherData.freeze_thaw_cycles_yr as number) || 0,
    })

    weatherData = {
      ...weatherData,
      storm_damage_score: stormScore.score,
      storm_score_factors: stormScore.factors,
    }

    // Insert weather intelligence
    const weatherInsert = {
      scan_id: scan_id,
      company_id: companyId,
      ...weatherData,
      data_sources: dataSources.filter(s => ['open_meteo', 'fema_disasters', 'noaa_storm_events', 'nws_alerts'].includes(s)),
      raw_responses: rawResponses,
    }

    const { data: weather } = await supabase
      .from('weather_intelligence')
      .insert(weatherInsert)
      .select('id')
      .single()

    if (weather) {
      await supabase
        .from('property_scans')
        .update({ weather_intelligence_id: weather.id })
        .eq('id', scan_id)
    }

    // ========================================================================
    // RESPONSE
    // ========================================================================

    return new Response(
      JSON.stringify({
        ok: true,
        scan_id,
        profile_id: profile?.id || null,
        weather_id: weather?.id || null,
        data_sources: dataSources,
        flood_zone: floodZone,
        flood_risk: floodRisk,
        storm_damage_score: stormScore.score,
        wildfire_risk: wildfireScore,
        radon_zone: radonZone,
        climate_zone: climateZone,
        lead_paint_probability: leadProb,
      }),
      {
        status: 200,
        headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
      }
    )
  } catch (e) {
    console.error(`[${EF_NAME}] Error:`, e)
    return errorResponse(
      e instanceof Error ? e.message : 'Intelligence gathering failed',
      500,
      origin,
    )
  }
})

// ============================================================================
// HELPER: Get county FIPS from lat/lng (Census geocoder)
// ============================================================================

async function getCountyFips(lat: number, lng: number): Promise<string | null> {
  try {
    const res = await fetch(
      `https://geocoding.geo.census.gov/geocoder/geographies/coordinates?x=${lng}&y=${lat}&benchmark=Public_AR_Current&vintage=Current_Current&format=json`
    )
    if (!res.ok) return null
    const data = await res.json()
    const geo = data?.result?.geographies?.['Counties']?.[0]
    if (geo) {
      return `${geo.STATE}${geo.COUNTY}` // e.g., "36061" = NY, New York County
    }
    return null
  } catch {
    return null
  }
}

// ============================================================================
// HELPER: Weather code to text
// ============================================================================

function weatherCodeToText(code: number | null): string {
  if (code == null) return 'Unknown'
  const codes: Record<number, string> = {
    0: 'Clear sky', 1: 'Mainly clear', 2: 'Partly cloudy', 3: 'Overcast',
    45: 'Fog', 48: 'Depositing rime fog',
    51: 'Light drizzle', 53: 'Moderate drizzle', 55: 'Dense drizzle',
    61: 'Slight rain', 63: 'Moderate rain', 65: 'Heavy rain',
    71: 'Slight snow', 73: 'Moderate snow', 75: 'Heavy snow',
    77: 'Snow grains', 80: 'Slight rain showers', 81: 'Moderate rain showers',
    82: 'Violent rain showers', 85: 'Slight snow showers', 86: 'Heavy snow showers',
    95: 'Thunderstorm', 96: 'Thunderstorm with slight hail', 99: 'Thunderstorm with heavy hail',
  }
  return codes[code] || `Code ${code}`
}

// ============================================================================
// HELPER: EPA Radon Zone by state (Zone 1=highest, Zone 3=lowest)
// ============================================================================

function getEpaRadonZone(state: string): string | null {
  // EPA radon zone data — majority zone per state
  const zones: Record<string, string> = {
    AL: '3', AK: '3', AZ: '2', AR: '2', CA: '2',
    CO: '1', CT: '1', DE: '2', FL: '3', GA: '3',
    HI: '3', ID: '1', IL: '1', IN: '1', IA: '1',
    KS: '1', KY: '1', LA: '3', ME: '2', MD: '2',
    MA: '2', MI: '1', MN: '1', MS: '3', MO: '1',
    MT: '1', NE: '1', NV: '2', NH: '1', NJ: '2',
    NM: '2', NY: '1', NC: '2', ND: '1', OH: '1',
    OK: '2', OR: '2', PA: '1', RI: '2', SC: '3',
    SD: '1', TN: '1', TX: '2', UT: '1', VT: '1',
    VA: '2', WA: '2', WV: '1', WI: '1', WY: '1',
    DC: '2',
  }
  return zones[state] || null
}

// ============================================================================
// HELPER: Termite risk zone (1=very heavy, 4=none to slight)
// ============================================================================

function getTermiteZone(state: string): string | null {
  const zones: Record<string, string> = {
    FL: '1', HI: '1', LA: '1', TX: '1', MS: '1', AL: '1', GA: '1', SC: '1',
    CA: '2', AZ: '2', NM: '2', AR: '2', NC: '2', VA: '2', TN: '2', OK: '2',
    MO: '2', KY: '2', MD: '2', DE: '2', NJ: '2',
    OR: '3', WA: '3', NV: '3', UT: '3', CO: '3', KS: '3', NE: '3', IA: '3',
    IL: '3', IN: '3', OH: '3', PA: '3', NY: '3', CT: '3', RI: '3', MA: '3',
    ID: '4', MT: '4', WY: '4', ND: '4', SD: '4', MN: '4', WI: '4', MI: '4',
    VT: '4', NH: '4', ME: '4', AK: '4',
  }
  return zones[state] || null
}

// ============================================================================
// HELPER: Seismic zone (approximate from state)
// ============================================================================

function getSeismicZone(state: string): string | null {
  const zones: Record<string, string> = {
    CA: 'high', AK: 'high', HI: 'moderate', WA: 'high', OR: 'moderate',
    NV: 'moderate', UT: 'moderate', MT: 'moderate', ID: 'moderate',
    SC: 'moderate', TN: 'moderate', MO: 'moderate', AR: 'moderate',
    IL: 'moderate', IN: 'moderate', KY: 'moderate',
  }
  return zones[state] || 'low'
}

// ============================================================================
// HELPER: Frost line depth by state (inches)
// ============================================================================

function getFrostLineDepth(state: string): number | null {
  const depths: Record<string, number> = {
    FL: 0, HI: 0, LA: 0, TX: 6, MS: 6, AL: 6, GA: 12, SC: 12,
    CA: 12, AZ: 6, NM: 18, AR: 18, NC: 18, VA: 18, TN: 18, OK: 18,
    MO: 30, KY: 24, MD: 30, DE: 30, NJ: 36, DC: 30,
    OR: 18, WA: 24, NV: 24, UT: 36, CO: 36, KS: 30, NE: 42, IA: 48,
    IL: 42, IN: 36, OH: 36, PA: 42, NY: 48, CT: 42, RI: 36, MA: 48,
    ID: 36, MT: 48, WY: 48, ND: 56, SD: 48, MN: 60, WI: 48, MI: 42,
    VT: 60, NH: 60, ME: 60, AK: 72,
  }
  return depths[state] ?? null
}

// ============================================================================
// HELPER: Climate zone from state + latitude
// ============================================================================

function getClimateZone(state: string, lat: number): string | null {
  // Simplified IECC climate zone mapping
  if (lat > 45) return '6' // Cold
  if (lat > 40) return '5' // Cool
  if (lat > 35) return '4' // Mixed
  if (lat > 30) return '3' // Warm
  if (lat > 25) return '2' // Hot
  return '1' // Very hot

  // TODO: Use IECC climate zone database for precise mapping
}

// ============================================================================
// HELPER: Storm damage probability score (0-100)
// ============================================================================

function calculateStormDamageScore(params: {
  yearBuilt: number
  stormEvents5yr: number
  stormEvents10yr: number
  floodZone: string | null
  wildfireScore: number | null
  freezeThawCycles: number
}): { score: number; factors: Record<string, unknown> } {
  let score = 0
  const factors: Record<string, unknown> = {}

  // Property age factor (older = more vulnerable)
  const age = new Date().getFullYear() - params.yearBuilt
  const ageFactor = Math.min(age / 50, 1) * 25 // Max 25 points
  score += ageFactor
  factors['property_age'] = { age, points: Math.round(ageFactor) }

  // Storm history factor
  const stormFactor = Math.min(params.stormEvents5yr * 5, 25) // Max 25 points
  score += stormFactor
  factors['storm_history'] = { events_5yr: params.stormEvents5yr, points: Math.round(stormFactor) }

  // Flood zone factor
  if (params.floodZone === 'A' || params.floodZone === 'AE' || params.floodZone === 'V' || params.floodZone === 'VE') {
    score += 20
    factors['flood_risk'] = { zone: params.floodZone, points: 20 }
  } else if (params.floodZone === 'X' || params.floodZone === 'X500') {
    score += 5
    factors['flood_risk'] = { zone: params.floodZone, points: 5 }
  }

  // Freeze-thaw factor (affects concrete, masonry, roofing)
  const ftFactor = Math.min(params.freezeThawCycles / 100, 1) * 15 // Max 15 points
  score += ftFactor
  factors['freeze_thaw'] = { cycles_per_year: params.freezeThawCycles, points: Math.round(ftFactor) }

  // Wildfire factor
  if (params.wildfireScore && params.wildfireScore > 40) {
    const wfPoints = Math.min((params.wildfireScore - 40) / 60 * 15, 15)
    score += wfPoints
    factors['wildfire'] = { risk_score: params.wildfireScore, points: Math.round(wfPoints) }
  }

  return { score: Math.min(Math.round(score), 100), factors }
}
