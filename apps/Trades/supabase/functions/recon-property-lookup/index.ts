// Supabase Edge Function: recon-property-lookup
// Full property intelligence pipeline (Phase 3A+3B enhanced):
// 1. Geocode address → lat/lng (Google → Nominatim → US Census fallback chain)
// 2. Google Solar API → roof segments, measurements, facets
// 3. USGS 3DEP Elevation (FREE) → elevation, terrain data
// 4. Microsoft/OSM Building Footprints (FREE) → multi-structure detection
// 5. ATTOM API (GATED) → property characteristics, sale history
// 6. Regrid API (GATED) → parcel boundaries, zoning, APN
// 7. Property features insert (ATTOM + Solar + USGS data combined)
// 7b. Google Street View Static API → exterior property image
// 7c. PARALLEL: FEMA Flood + Census ACS + NWS Alerts (8s timeout, Promise.allSettled)
// 7d. External deep links (Zillow, Redfin, Realtor.com, Google Maps, FEMA, County Assessor)
// 7d3. Property type inference from building footprint
// 7d4. PARALLEL: Open-Meteo Weather + NOAA Storm Events (8s timeout)
// 7d5. Computed measurements (lawn area, wall area, roof complexity, boundary perimeter)
// 7d6. Hazard Flags Engine (12 hazard types with severity + explanations)
// 7d7. Environmental + Code Requirements aggregation
// 7e. FIRE-AND-FORGET: Storage uploads (satellite, street view, recon report)
// 8. Confidence scoring → grade + factors
// 9. Auto-trigger roof calculator + trade estimator
// Inserts: property_scans, roof_measurements, roof_facets,
//          property_structures, property_features, parcel_boundaries
// Storage: recon-photos/{company_id}/{address}/satellite.jpg, street_view.jpg, recon_report.json

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse } from '../_shared/cors.ts'
import { logApiCall } from '../_shared/api-cost-logger.ts'
import { checkApiRateLimit } from '../_shared/api-rate-guard.ts'

const SQM_TO_SQFT = 10.764
const CACHE_DAYS = 30

// ============================================================================
// STATIC LOOKUP TABLES (no API calls needed)
// ============================================================================

/** EPA Radon Zones by state — Zone 1 = highest risk (>4 pCi/L predicted avg) */
const EPA_RADON_ZONES: Record<string, number> = {
  AL: 3, AK: 3, AZ: 2, AR: 3, CA: 2, CO: 1, CT: 1, DE: 2, FL: 3, GA: 3,
  HI: 3, ID: 2, IL: 1, IN: 1, IA: 1, KS: 1, KY: 1, LA: 3, ME: 2, MD: 1,
  MA: 1, MI: 1, MN: 1, MS: 3, MO: 1, MT: 1, NE: 1, NV: 3, NH: 1, NJ: 1,
  NM: 2, NY: 1, NC: 2, ND: 1, OH: 1, OK: 2, OR: 2, PA: 1, RI: 1, SC: 3,
  SD: 1, TN: 1, TX: 2, UT: 1, VT: 1, VA: 1, WA: 2, WV: 1, WI: 1, WY: 1,
  DC: 1,
}

/** Termite Infestation Probability by state (TIA zones) */
const TERMITE_ZONES: Record<string, string> = {
  AL: 'very_heavy', AK: 'none_to_slight', AZ: 'moderate_to_heavy', AR: 'very_heavy',
  CA: 'moderate_to_heavy', CO: 'none_to_slight', CT: 'moderate_to_heavy', DE: 'moderate_to_heavy',
  FL: 'very_heavy', GA: 'very_heavy', HI: 'very_heavy', ID: 'none_to_slight',
  IL: 'moderate_to_heavy', IN: 'moderate_to_heavy', IA: 'slight_to_moderate',
  KS: 'moderate_to_heavy', KY: 'moderate_to_heavy', LA: 'very_heavy', ME: 'none_to_slight',
  MD: 'moderate_to_heavy', MA: 'moderate_to_heavy', MI: 'slight_to_moderate',
  MN: 'slight_to_moderate', MS: 'very_heavy', MO: 'moderate_to_heavy', MT: 'none_to_slight',
  NE: 'slight_to_moderate', NV: 'slight_to_moderate', NH: 'slight_to_moderate',
  NJ: 'moderate_to_heavy', NM: 'moderate_to_heavy', NY: 'moderate_to_heavy',
  NC: 'very_heavy', ND: 'none_to_slight', OH: 'moderate_to_heavy', OK: 'moderate_to_heavy',
  OR: 'slight_to_moderate', PA: 'moderate_to_heavy', RI: 'moderate_to_heavy',
  SC: 'very_heavy', SD: 'none_to_slight', TN: 'very_heavy', TX: 'very_heavy',
  UT: 'slight_to_moderate', VT: 'none_to_slight', VA: 'very_heavy', WA: 'slight_to_moderate',
  WV: 'moderate_to_heavy', WI: 'slight_to_moderate', WY: 'none_to_slight', DC: 'moderate_to_heavy',
}

/** IECC Climate Zone by state (most common zone per state — simplified) */
const IECC_CLIMATE_ZONES: Record<string, string> = {
  AL: '3A', AK: '7', AZ: '2B', AR: '3A', CA: '3B', CO: '5B', CT: '5A', DE: '4A',
  FL: '2A', GA: '3A', HI: '1A', ID: '5B', IL: '5A', IN: '5A', IA: '5A',
  KS: '4A', KY: '4A', LA: '2A', ME: '6A', MD: '4A', MA: '5A', MI: '5A',
  MN: '6A', MS: '3A', MO: '4A', MT: '6B', NE: '5A', NV: '3B', NH: '6A',
  NJ: '4A', NM: '4B', NY: '5A', NC: '4A', ND: '6A', OH: '5A', OK: '3A',
  OR: '4C', PA: '5A', RI: '5A', SC: '3A', SD: '6A', TN: '4A', TX: '2A',
  UT: '5B', VT: '6A', VA: '4A', WA: '4C', WV: '5A', WI: '6A', WY: '6B', DC: '4A',
}

/** ASCE 7 approximate design parameters by climate zone (simplified national defaults) */
const ASCE7_DEFAULTS: Record<string, { wind_mph: number; snow_psf: number; frost_in: number; seismic: string }> = {
  '1A': { wind_mph: 150, snow_psf: 0, frost_in: 0, seismic: 'A' },
  '2A': { wind_mph: 130, snow_psf: 0, frost_in: 0, seismic: 'A' },
  '2B': { wind_mph: 120, snow_psf: 0, frost_in: 0, seismic: 'B' },
  '3A': { wind_mph: 120, snow_psf: 5, frost_in: 6, seismic: 'B' },
  '3B': { wind_mph: 110, snow_psf: 0, frost_in: 0, seismic: 'C' },
  '3C': { wind_mph: 110, snow_psf: 0, frost_in: 0, seismic: 'D0' },
  '4A': { wind_mph: 115, snow_psf: 20, frost_in: 24, seismic: 'B' },
  '4B': { wind_mph: 110, snow_psf: 10, frost_in: 18, seismic: 'B' },
  '4C': { wind_mph: 110, snow_psf: 10, frost_in: 18, seismic: 'D0' },
  '5A': { wind_mph: 115, snow_psf: 30, frost_in: 36, seismic: 'A' },
  '5B': { wind_mph: 115, snow_psf: 25, frost_in: 36, seismic: 'B' },
  '6A': { wind_mph: 115, snow_psf: 40, frost_in: 48, seismic: 'A' },
  '6B': { wind_mph: 115, snow_psf: 35, frost_in: 48, seismic: 'B' },
  '7':  { wind_mph: 115, snow_psf: 50, frost_in: 60, seismic: 'A' },
  '8':  { wind_mph: 130, snow_psf: 60, frost_in: 72, seismic: 'A' },
}

/** Insulation R-value requirements by IECC climate zone */
const INSULATION_R_VALUES: Record<string, { ceiling: string; wall: string; floor: string; basement: string }> = {
  '1A': { ceiling: 'R-30', wall: 'R-13', floor: 'R-0', basement: 'R-0' },
  '2A': { ceiling: 'R-38', wall: 'R-13', floor: 'R-0', basement: 'R-0' },
  '2B': { ceiling: 'R-38', wall: 'R-13', floor: 'R-0', basement: 'R-0' },
  '3A': { ceiling: 'R-38', wall: 'R-20', floor: 'R-19', basement: 'R-5/R-13' },
  '3B': { ceiling: 'R-38', wall: 'R-20', floor: 'R-19', basement: 'R-5/R-13' },
  '3C': { ceiling: 'R-38', wall: 'R-20', floor: 'R-19', basement: 'R-5/R-13' },
  '4A': { ceiling: 'R-49', wall: 'R-20', floor: 'R-19', basement: 'R-10/R-13' },
  '4B': { ceiling: 'R-49', wall: 'R-20', floor: 'R-19', basement: 'R-10/R-13' },
  '4C': { ceiling: 'R-49', wall: 'R-20', floor: 'R-19', basement: 'R-10/R-13' },
  '5A': { ceiling: 'R-49', wall: 'R-20+5', floor: 'R-30', basement: 'R-15/R-19' },
  '5B': { ceiling: 'R-49', wall: 'R-20+5', floor: 'R-30', basement: 'R-15/R-19' },
  '6A': { ceiling: 'R-49', wall: 'R-20+5', floor: 'R-30', basement: 'R-15/R-19' },
  '6B': { ceiling: 'R-49', wall: 'R-20+5', floor: 'R-30', basement: 'R-15/R-19' },
  '7':  { ceiling: 'R-49', wall: 'R-21+10', floor: 'R-38', basement: 'R-15/R-19' },
  '8':  { ceiling: 'R-49', wall: 'R-21+10', floor: 'R-38', basement: 'R-15/R-19' },
}

/** Known problem electrical panel brands by year */
const PROBLEM_PANELS = [
  { name: 'Federal Pacific (FPE Stab-Lok)', yearStart: 1950, yearEnd: 1990 },
  { name: 'Zinsco/GTE-Sylvania', yearStart: 1950, yearEnd: 1980 },
  { name: 'Pushmatic/ITE', yearStart: 1950, yearEnd: 1980 },
  { name: 'Challenger', yearStart: 1980, yearEnd: 2000 },
]

interface HazardFlag {
  type: string
  severity: 'red' | 'yellow' | 'green'
  title: string
  description: string
  what_to_do: string
  cost_implications: string
  regulatory: string
}

/** SHA-256 hash for address normalization (cache key) */
async function hashAddress(address: string): Promise<string> {
  const normalized = address.trim().toLowerCase().replace(/\s+/g, ' ')
  const data = new TextEncoder().encode(normalized)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('')
}

interface SolarResponse {
  name?: string
  center?: { latitude: number; longitude: number }
  imageryDate?: { year: number; month: number; day: number }
  imageryQuality?: string
  solarPotential?: {
    maxArrayPanelsCount?: number
    maxArrayAreaMeters2?: number
    maxSunshineHoursPerYear?: number
    roofSegmentStats?: Array<{
      pitchDegrees?: number
      azimuthDegrees?: number
      stats?: {
        areaMeters2?: number
        sunshineQuantiles?: number[]
        groundAreaMeters2?: number
      }
      center?: { latitude: number; longitude: number }
      planeHeightAtCenterMeters?: number
      boundingBox?: {
        sw: { latitude: number; longitude: number }
        ne: { latitude: number; longitude: number }
      }
    }>
    buildingStats?: {
      areaMeters2?: number
      sunshineQuantiles?: number[]
      groundAreaMeters2?: number
    }
    wholeRoofStats?: {
      areaMeters2?: number
      sunshineQuantiles?: number[]
      groundAreaMeters2?: number
    }
  }
}

interface GeoJsonPolygon {
  type: 'Polygon'
  coordinates: number[][][]
}

interface MSFootprint {
  type: string
  geometry: GeoJsonPolygon
  properties: {
    height?: number
    confidence?: number
  }
}

// Helper: calculate polygon area from GeoJSON coordinates (sq meters → sq ft)
function polygonAreaSqft(coords: number[][]): number {
  if (!coords || coords.length < 3) return 0
  // Shoelace formula on projected coordinates (approximate for small areas)
  let area = 0
  const n = coords.length
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n
    // Convert to approximate meters using lat/lng
    const x1 = coords[i][0] * 111320 * Math.cos((coords[i][1] * Math.PI) / 180)
    const y1 = coords[i][1] * 110540
    const x2 = coords[j][0] * 111320 * Math.cos((coords[j][1] * Math.PI) / 180)
    const y2 = coords[j][1] * 110540
    area += x1 * y2 - x2 * y1
  }
  return Math.abs(area / 2) * SQM_TO_SQFT / (SQM_TO_SQFT / SQM_TO_SQFT) // already in sq meters, convert
}

// More accurate polygon area calculation in sq ft
function geoJsonAreaSqft(polygon: GeoJsonPolygon): number {
  if (!polygon?.coordinates?.[0]) return 0
  const ring = polygon.coordinates[0]
  if (ring.length < 3) return 0

  // Spherical excess formula for accuracy
  const toRad = (d: number) => (d * Math.PI) / 180
  let total = 0
  for (let i = 0; i < ring.length - 1; i++) {
    const j = (i + 1) % (ring.length - 1)
    const lng1 = toRad(ring[i][0])
    const lat1 = toRad(ring[i][1])
    const lng2 = toRad(ring[j][0])
    const lat2 = toRad(ring[j][1])
    total += (lng2 - lng1) * (2 + Math.sin(lat1) + Math.sin(lat2))
  }
  const earthRadiusFt = 20902231 // feet
  return Math.abs((total * earthRadiusFt * earthRadiusFt) / 2)
}

// Helper: check if point is within radius of another point (haversine)
function distanceFt(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 20902231 // Earth radius in feet
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2)
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

// Helper: JSON response with CORS
function jsonResponse(body: Record<string, unknown>, status = 200, origin?: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
  })
}

serve(async (req) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') {
    return corsResponse(origin)
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405, origin)
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
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401)
  }

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return jsonResponse({ error: 'No company' }, 403)
  }

  try {
    const body = await req.json()
    const { address, job_id, latitude, longitude } = body as {
      address: string
      job_id?: string
      latitude?: number
      longitude?: number
    }

    if (!address) {
      return jsonResponse({ error: 'Address required' }, 400)
    }

    // ========================================================================
    // CHECK CACHE (30-day) — skip if previous scan had no solar/roof data
    // ========================================================================
    const { data: cached } = await supabase
      .from('property_scans')
      .select('id, status, cached_until, raw_google_solar')
      .eq('company_id', companyId)
      .eq('address', address)
      .is('deleted_at', null)
      .gt('cached_until', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cached && cached.status !== 'failed') {
      // Invalidate cache if previous scan was incomplete (no solar/roof data)
      const solarJson = cached.raw_google_solar as Record<string, unknown> | null
      const hasSolar = solarJson &&
        typeof solarJson === 'object' &&
        Object.keys(solarJson).length > 0

      if (hasSolar) {
        return jsonResponse({ scan_id: cached.id, cached: true }, 200, origin)
      }
      // Cache miss — previous scan was incomplete, expire stale record and re-scan
      await supabase
        .from('property_scans')
        .update({ cached_until: new Date(0).toISOString() })
        .eq('id', cached.id)
    } else if (cached && cached.status === 'failed') {
      // Expire failed scans so they get re-scanned
      await supabase
        .from('property_scans')
        .update({ cached_until: new Date(0).toISOString() })
        .eq('id', cached.id)
    }

    // ========================================================================
    // CHECK scan_cache (dedicated cache table — 30-day TTL)
    // ========================================================================
    const addressHash = await hashAddress(address)
    const { data: scanCacheHit } = await supabase
      .from('scan_cache')
      .select('id, scan_data')
      .eq('company_id', companyId)
      .eq('address_hash', addressHash)
      .gt('expires_at', new Date().toISOString())
      .maybeSingle()

    if (scanCacheHit?.scan_data?.scan_id) {
      // Verify the cached scan still exists and isn't failed/deleted
      const { data: cachedScan } = await supabase
        .from('property_scans')
        .select('id, status')
        .eq('id', scanCacheHit.scan_data.scan_id)
        .is('deleted_at', null)
        .maybeSingle()

      if (cachedScan && cachedScan.status !== 'failed') {
        return jsonResponse({ scan_id: cachedScan.id, cached: true }, 200, origin)
      }
      // Invalidate stale scan_cache entry
      await supabase
        .from('scan_cache')
        .delete()
        .eq('id', scanCacheHit.id)
    }

    // ========================================================================
    // CREATE SCAN RECORD
    // ========================================================================
    const cachedUntil = new Date()
    cachedUntil.setDate(cachedUntil.getDate() + CACHE_DAYS)

    const { data: scan, error: scanErr } = await supabase
      .from('property_scans')
      .insert({
        company_id: companyId,
        job_id: job_id || null,
        created_by: user.id,
        address,
        latitude: latitude || null,
        longitude: longitude || null,
        status: 'scanning',
        cached_until: cachedUntil.toISOString(),
      })
      .select()
      .single()

    if (scanErr) {
      console.error('[property-lookup] Failed to create scan record:', scanErr.message, scanErr.details)
      throw scanErr
    }
    console.log('[property-lookup] Scan record created:', scan.id)

    const scanId = scan.id
    const sources: string[] = []
    let lat = latitude
    let lng = longitude
    let elevationFt: number | null = null

    // ========================================================================
    // STEP 1: GEOCODE (Google Maps)
    // ========================================================================
    let geocodeCity: string | null = null
    let geocodeState: string | null = null
    let geocodeZip: string | null = null
    let geocodeStreet: string | null = null

    if (!lat || !lng) {
      const googleKey = Deno.env.get('GOOGLE_CLOUD_API_KEY')
      console.log('[property-lookup] Geocoding address:', address, 'hasKey:', !!googleKey)
      if (googleKey) {
        try {
          const geoRes = await fetch(
            `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${googleKey}`
          )
          const geoData = await geoRes.json()
          console.log('[property-lookup] Geocode status:', geoData.status, 'results:', geoData.results?.length || 0)
          if (geoData.status !== 'OK') {
            console.error('[property-lookup] Geocode API error:', geoData.status, geoData.error_message)
          }
          if (geoData.results?.[0]?.geometry?.location) {
            lat = geoData.results[0].geometry.location.lat
            lng = geoData.results[0].geometry.location.lng
            const comps = geoData.results[0].address_components || []
            geocodeCity = comps.find((c: { types: string[] }) => c.types.includes('locality'))?.long_name || null
            geocodeState = comps.find((c: { types: string[] }) => c.types.includes('administrative_area_level_1'))?.short_name || null
            geocodeZip = comps.find((c: { types: string[] }) => c.types.includes('postal_code'))?.long_name || null
            const streetNum = comps.find((c: { types: string[] }) => c.types.includes('street_number'))?.long_name || ''
            const streetRoute = comps.find((c: { types: string[] }) => c.types.includes('route'))?.long_name || ''
            geocodeStreet = streetNum && streetRoute ? `${streetNum} ${streetRoute}` : null

            await supabase
              .from('property_scans')
              .update({
                latitude: lat,
                longitude: lng,
                city: geocodeCity,
                state: geocodeState,
                zip: geocodeZip,
              })
              .eq('id', scanId)
          }
        } catch (geoErr) {
          console.error('[property-lookup] Geocode fetch failed:', geoErr)
        }
      }
    }

    // FREE FALLBACK: Nominatim (OpenStreetMap) — no API key required
    if (!lat || !lng) {
      console.log('[property-lookup] Google geocode unavailable, trying Nominatim...')
      try {
        const nomRes = await fetch(
          `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)}&format=json&limit=1&countrycodes=us&addressdetails=1`,
          { headers: { 'User-Agent': 'Zafto-PropertyIntelligence/1.0 (recon)' } }
        )
        if (nomRes.ok) {
          const nomData = await nomRes.json()
          if (nomData?.[0]) {
            lat = parseFloat(nomData[0].lat)
            lng = parseFloat(nomData[0].lon)
            const addr = nomData[0].address || {}
            geocodeCity = addr.city || addr.town || addr.village || null
            geocodeState = addr.state || null
            geocodeZip = addr.postcode || null
            if (addr.house_number && addr.road) geocodeStreet = `${addr.house_number} ${addr.road}`
            sources.push('nominatim')
            console.log('[property-lookup] Nominatim geocode success:', lat, lng)

            await supabase
              .from('property_scans')
              .update({
                latitude: lat,
                longitude: lng,
                city: geocodeCity,
                state: geocodeState,
                zip: geocodeZip,
              })
              .eq('id', scanId)
          }
        }
      } catch (nomErr) {
        console.error('[property-lookup] Nominatim geocode failed:', nomErr)
      }
    }

    // LAST RESORT: US Census Geocoder (free, no key, US-only)
    if (!lat || !lng) {
      console.log('[property-lookup] Trying US Census Geocoder...')
      try {
        const censusRes = await fetch(
          `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=${encodeURIComponent(address)}&benchmark=Public_AR_Current&format=json`
        )
        if (censusRes.ok) {
          const censusData = await censusRes.json()
          const match = censusData?.result?.addressMatches?.[0]
          if (match?.coordinates) {
            lat = match.coordinates.y
            lng = match.coordinates.x
            // Parse city/state from matched address
            geocodeCity = match.addressComponents?.city || null
            geocodeState = match.addressComponents?.state || null
            geocodeZip = match.addressComponents?.zip || null
            const cenStreet = match.addressComponents?.preDirection ? `${match.addressComponents.preDirection} ` : ''
            geocodeStreet = `${cenStreet}${match.addressComponents?.streetName || ''} ${match.addressComponents?.suffixType || ''}`.trim() || null
            if (geocodeStreet && match.addressComponents?.preQualifier) geocodeStreet = `${match.addressComponents.preQualifier} ${geocodeStreet}`
            sources.push('census_geocoder')
            console.log('[property-lookup] Census geocode success:', lat, lng)

            await supabase
              .from('property_scans')
              .update({
                latitude: lat,
                longitude: lng,
                city: geocodeCity,
                state: geocodeState,
                zip: geocodeZip,
              })
              .eq('id', scanId)
          }
        }
      } catch (censusErr) {
        console.error('[property-lookup] Census geocode failed:', censusErr)
      }
    }

    if (!lat || !lng) {
      await supabase
        .from('property_scans')
        .update({ status: 'failed', error_message: 'Could not geocode address — tried Google, Nominatim, and US Census' })
        .eq('id', scanId)

      return jsonResponse({ error: 'Could not geocode address', scan_id: scanId }, 422)
    }

    // ========================================================================
    // STEP 2: GOOGLE SOLAR API
    // ========================================================================
    const solarKey = Deno.env.get('GOOGLE_SOLAR_API_KEY') || Deno.env.get('GOOGLE_CLOUD_API_KEY')
    console.log('[property-lookup] Solar API step — hasSolarKey:', !!solarKey, 'lat:', lat, 'lng:', lng)
    let solarData: SolarResponse | null = null
    let imageryDate: Date | null = null
    let roofMeasurementId: string | null = null
    let totalRoofAreaSqft = 0
    const apiTimings: Array<{ api: string; ms: number; status: number; cost: number }> = []

    if (solarKey) {
      // Rate guard — skip Solar if at limit
      const solarRate = await checkApiRateLimit(supabase, companyId, 'google_solar')
      if (!solarRate.allowed) {
        console.warn('[property-lookup] Google Solar rate limited, skipping')
      } else {
        const t0 = performance.now()
        try {
          const solarRes = await fetch(
            `https://solar.googleapis.com/v1/buildingInsights:findClosest?location.latitude=${lat}&location.longitude=${lng}&requiredQuality=HIGH&key=${solarKey}`
          )

          console.log('[property-lookup] Solar API response status:', solarRes.status)
          if (solarRes.ok) {
            solarData = await solarRes.json()
            sources.push('google_solar')
            console.log('[property-lookup] Solar data received — segments:', solarData?.solarPotential?.roofSegmentStats?.length || 0)

            if (solarData?.imageryDate) {
              const { year, month, day } = solarData.imageryDate
              imageryDate = new Date(year, month - 1, day)
            }

            await supabase
              .from('property_scans')
              .update({
                raw_google_solar: solarData,
                imagery_date: imageryDate?.toISOString().split('T')[0] || null,
                imagery_source: 'google_solar',
                imagery_age_months: imageryDate
                  ? Math.round((Date.now() - imageryDate.getTime()) / (1000 * 60 * 60 * 24 * 30))
                  : null,
              })
              .eq('id', scanId)

            // Parse roof segments into facets
            if (solarData?.solarPotential?.roofSegmentStats) {
              const segments = solarData.solarPotential.roofSegmentStats

              const facets: Array<{
                facet_number: number
                area_sqft: number
                pitch_degrees: number
                azimuth_degrees: number
                annual_sun_hours: number
                shade_factor: number
              }> = []

              for (let i = 0; i < segments.length; i++) {
                const seg = segments[i]
                const areaSqft = (seg.stats?.areaMeters2 || 0) * SQM_TO_SQFT
                totalRoofAreaSqft += areaSqft

                const maxSun = solarData.solarPotential?.maxSunshineHoursPerYear || 1800
                const segSun = seg.stats?.sunshineQuantiles?.[5] || 0
                const shadeFactor = maxSun > 0 ? Math.min(1, segSun / maxSun) : 1

                facets.push({
                  facet_number: i + 1,
                  area_sqft: Math.round(areaSqft * 100) / 100,
                  pitch_degrees: seg.pitchDegrees || 0,
                  azimuth_degrees: seg.azimuthDegrees || 0,
                  annual_sun_hours: segSun,
                  shade_factor: Math.round(shadeFactor * 100) / 100,
                })
              }

              // Determine primary pitch
              const pitchCounts: Record<string, number> = {}
              for (const f of facets) {
                const rise = Math.round(Math.tan((f.pitch_degrees * Math.PI) / 180) * 12)
                const key = `${rise}/12`
                pitchCounts[key] = (pitchCounts[key] || 0) + 1
              }
              const primaryPitch =
                Object.entries(pitchCounts).sort((a, b) => b[1] - a[1])[0]?.[0] || '4/12'

              // Determine shape
              let shape: string = 'mixed'
              if (facets.length === 2) shape = 'gable'
              else if (facets.length === 4) shape = 'hip'
              else if (facets.length === 1) shape = 'flat'

              const { data: rm, error: rmErr } = await supabase
                .from('roof_measurements')
                .insert({
                  scan_id: scanId,
                  total_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
                  total_area_squares: Math.round((totalRoofAreaSqft / 100) * 100) / 100,
                  pitch_primary: primaryPitch,
                  pitch_degrees: facets[0]?.pitch_degrees || 0,
                  facet_count: facets.length,
                  predominant_shape: shape,
                  complexity_score: Math.min(10, facets.length * 0.8),
                  data_source: 'google_solar',
                  raw_response: solarData.solarPotential,
                })
                .select('id')
                .single()

              if (rmErr) {
                console.error('roof_measurements insert failed:', rmErr.message, rmErr.details)
              }

              if (rm) {
                roofMeasurementId = rm.id
                const { error: facetErr } = await supabase.from('roof_facets').insert(
                  facets.map((f) => ({
                    roof_measurement_id: rm.id,
                    ...f,
                  }))
                )
                if (facetErr) {
                  console.error('roof_facets insert failed:', facetErr.message, facetErr.details)
                }
              }
            }
          } else {
            const errBody = await solarRes.text()
            console.error('[property-lookup] Solar API error:', solarRes.status, errBody)
          }
          apiTimings.push({ api: 'google_solar', ms: Math.round(performance.now() - t0), status: solarRes.status, cost: 0 })
        } catch (solarErr) {
          console.error('[property-lookup] Solar API failed:', solarErr)
          apiTimings.push({ api: 'google_solar', ms: Math.round(performance.now() - t0), status: 0, cost: 0 })
        }
      }
    }

    // ========================================================================
    // STEP 3: USGS 3DEP ELEVATION (FREE)
    // ========================================================================
    try {
      const t1 = performance.now()
      const usgsRes = await fetch(
        `https://epqs.nationalmap.gov/v1/json?x=${lng}&y=${lat}&wkid=4326&units=Feet&includeDate=false`
      )
      if (usgsRes.ok) {
        const usgsData = await usgsRes.json()
        const elevation = usgsData?.value
        if (elevation && !isNaN(parseFloat(String(elevation)))) {
          elevationFt = parseFloat(String(elevation))
          sources.push('usgs')
        }
      }
      apiTimings.push({ api: 'usgs_3dep', ms: Math.round(performance.now() - t1), status: usgsRes.ok ? 200 : usgsRes.status, cost: 0 })
    } catch {
      /* USGS failed, non-critical */
    }

    // ========================================================================
    // STEP 4: MICROSOFT BUILDING FOOTPRINTS (FREE)
    // ========================================================================
    const structures: Array<{
      structure_type: string
      label: string
      footprint_sqft: number
      footprint_geojson: GeoJsonPolygon | null
      estimated_stories: number
      estimated_roof_area_sqft: number
      estimated_wall_area_sqft: number
    }> = []

    const t2 = performance.now()
    try {
      // Microsoft Building Footprints are available via open dataset
      // Query Overpass API for OpenStreetMap buildings as a free alternative
      // that also includes Microsoft-imported footprints
      const bbox = `${lat - 0.001},${lng - 0.001},${lat + 0.001},${lng + 0.001}`
      const overpassQuery = `[out:json][timeout:10];way["building"](${bbox});out geom;`
      const overpassRes = await fetch(
        `https://overpass-api.de/api/interpreter?data=${encodeURIComponent(overpassQuery)}`
      )

      if (overpassRes.ok) {
        const overpassData = await overpassRes.json()
        const buildings = overpassData?.elements || []

        if (buildings.length > 0) {
          sources.push('ms_footprints')

          // Sort by area (largest first) to classify primary/secondary/accessory
          const buildingData: Array<{
            area: number
            geojson: GeoJsonPolygon
            height: number
            levels: number
          }> = []

          for (const bld of buildings) {
            if (!bld.geometry) continue

            const coords = bld.geometry.map((n: { lon: number; lat: number }) => [n.lon, n.lat])
            if (coords.length < 3) continue
            // Close the ring
            coords.push(coords[0])

            const geojson: GeoJsonPolygon = { type: 'Polygon', coordinates: [coords] }
            const area = geoJsonAreaSqft(geojson)

            // Only include buildings within 200ft of geocoded point
            const centLat = coords.reduce((s: number, c: number[]) => s + c[1], 0) / (coords.length - 1)
            const centLng = coords.reduce((s: number, c: number[]) => s + c[0], 0) / (coords.length - 1)
            if (distanceFt(lat, lng, centLat, centLng) > 200) continue

            const height = parseFloat(bld.tags?.height || '0') || 0
            const levels = parseInt(bld.tags?.['building:levels'] || '1', 10) || 1

            buildingData.push({ area, geojson, height, levels })
          }

          // Sort largest first
          buildingData.sort((a, b) => b.area - a.area)

          for (let i = 0; i < buildingData.length; i++) {
            const b = buildingData[i]
            let structureType: string
            let label: string

            if (i === 0) {
              structureType = 'primary'
              label = 'Main Building'
            } else if (b.area > 400) {
              structureType = 'secondary'
              label = b.area > 600 ? 'Detached Garage' : 'Workshop/Outbuilding'
            } else {
              structureType = 'accessory'
              label = 'Shed/Accessory'
            }

            const stories = b.levels || (b.height > 16 ? 2 : 1)
            const wallHeight = stories * 9 // 9ft per story
            const perimeter = Math.sqrt(b.area) * 4 // approximate
            const wallArea = perimeter * wallHeight
            const roofArea = b.area * (1 / Math.cos((20 * Math.PI) / 180)) // assume 20deg pitch

            structures.push({
              structure_type: structureType,
              label,
              footprint_sqft: Math.round(b.area * 100) / 100,
              footprint_geojson: b.geojson,
              estimated_stories: stories,
              estimated_roof_area_sqft: Math.round(roofArea * 100) / 100,
              estimated_wall_area_sqft: Math.round(wallArea * 100) / 100,
            })
          }
        }
      }
    } catch (overpassErr) {
      console.warn('[property-lookup] Overpass footprints failed:', overpassErr)
    }
    apiTimings.push({ api: 'overpass', ms: Math.round(performance.now() - t2), status: structures.length > 0 ? 200 : 0, cost: 0 })

    // If no footprints found but we have solar data, create primary structure from solar
    if (structures.length === 0 && solarData?.solarPotential?.buildingStats) {
      const buildingArea = (solarData.solarPotential.buildingStats.groundAreaMeters2 || 0) * SQM_TO_SQFT
      if (buildingArea > 0) {
        structures.push({
          structure_type: 'primary',
          label: 'Main Building',
          footprint_sqft: Math.round(buildingArea * 100) / 100,
          footprint_geojson: null,
          estimated_stories: 1,
          estimated_roof_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
          estimated_wall_area_sqft: Math.round(Math.sqrt(buildingArea) * 4 * 9 * 100) / 100,
        })
      }
    }

    // Insert structures
    if (structures.length > 0) {
      const structureRows = structures.map((s) => ({
        property_scan_id: scanId,
        ...s,
        has_roof_measurement: s.structure_type === 'primary' && roofMeasurementId != null,
      }))
      await supabase.from('property_structures').insert(structureRows)
    }

    // ========================================================================
    // STEP 5: ATTOM API (GATED — only if ATTOM_API_KEY exists)
    // ========================================================================
    let attomData: Record<string, unknown> | null = null
    const attomKey = Deno.env.get('ATTOM_API_KEY')

    if (attomKey) {
      const attomRate = await checkApiRateLimit(supabase, companyId, 'attom')
      if (!attomRate.allowed) {
        console.warn('[property-lookup] ATTOM rate limited, skipping')
      } else {
        try {
          const t3 = performance.now()
          // ATTOM requires split address: address1=street, address2=city,state,zip
          const attomAddr1 = geocodeStreet || address.split(',')[0]?.trim() || address
          const addrParts = address.split(',').slice(1).join(',').trim()
          const attomAddr2 = geocodeCity && geocodeState
            ? `${geocodeCity}, ${geocodeState}${geocodeZip ? ` ${geocodeZip}` : ''}`
            : addrParts || ''
          if (!attomAddr2) {
            console.warn('[property-lookup] ATTOM skipped: could not parse city/state from address')
          }
          const attomRes = await fetch(
            `https://api.gateway.attomdata.com/propertyapi/v1.0.0/property/expandedprofile?address1=${encodeURIComponent(attomAddr1)}&address2=${encodeURIComponent(attomAddr2)}`,
            {
              headers: { apikey: attomKey, Accept: 'application/json' },
            }
          )
          apiTimings.push({ api: 'attom', ms: Math.round(performance.now() - t3), status: attomRes.status, cost: 5 })

          if (attomRes.ok) {
            const attomJson = await attomRes.json()
            const property = attomJson?.property?.[0]
            if (property) {
              attomData = property
              sources.push('attom')
              console.log('[property-lookup] ATTOM SUCCESS — got property data')
            } else {
              console.warn('[property-lookup] ATTOM returned OK but no property in response')
            }
          } else {
            const errText = await attomRes.text()
            console.warn('[property-lookup] ATTOM failed:', attomRes.status, errText.substring(0, 200))
          }
        } catch (attomErr) {
          console.warn('[property-lookup] ATTOM fetch error:', attomErr)
        }
      }
    }

    // ========================================================================
    // STEP 6: REGRID API (GATED — only if REGRID_API_KEY exists)
    // ========================================================================
    let regridData: Record<string, unknown> | null = null
    const regridKey = Deno.env.get('REGRID_API_KEY')

    if (regridKey) {
      const regridRate = await checkApiRateLimit(supabase, companyId, 'regrid')
      if (!regridRate.allowed) {
        console.warn('[property-lookup] Regrid rate limited, skipping')
      } else {
        try {
          const t4 = performance.now()
          const regridRes = await fetch(
            `https://app.regrid.com/api/v1/search.json?query=${encodeURIComponent(address)}&token=${regridKey}`
          )
          apiTimings.push({ api: 'regrid', ms: Math.round(performance.now() - t4), status: regridRes.status, cost: 2 })

          if (regridRes.ok) {
            const regridJson = await regridRes.json()
            const parcel = regridJson?.results?.[0]
            if (parcel) {
              regridData = parcel
              sources.push('regrid')

              // Insert parcel boundary
              await supabase.from('parcel_boundaries').insert({
                scan_id: scanId,
                apn: (parcel.fields?.parcelnumb as string) || null,
                boundary_geojson: parcel.geometry || null,
                lot_area_sqft: parcel.fields?.ll_gisacre
                  ? parseFloat(String(parcel.fields.ll_gisacre)) * 43560
                  : null,
                lot_width_ft: null,
                lot_depth_ft: null,
                zoning: (parcel.fields?.zoning as string) || null,
                zoning_description: (parcel.fields?.zoning_description as string) || null,
                owner_name: (parcel.fields?.owner as string) || null,
                owner_type: null,
                data_source: 'regrid',
                raw_regrid: regridData,
              })
            }
          }
        } catch {
          /* Regrid failed, non-critical */
        }
      }
    }

    // ========================================================================
    // STEP 7: INSERT PROPERTY FEATURES
    // ========================================================================
    const featureSources: string[] = []
    if (solarData) featureSources.push('google_solar')
    if (elevationFt != null) featureSources.push('usgs')
    if (attomData) featureSources.push('attom')

    // Extract ATTOM fields if available
    // ATTOM expandedprofile nesting: property[0].building, .lot, .assessment, .sale, .summary
    const attomObj = attomData as Record<string, unknown> | null
    const building = (attomObj?.building as Record<string, unknown>) || {}
    const buildingSize = (building.size as Record<string, unknown>) || {}
    const buildingRooms = (building.rooms as Record<string, unknown>) || {}
    const buildingConstruction = (building.construction as Record<string, unknown>) || {}
    const buildingUtility = (building.utility as Record<string, unknown>) || {}
    const buildingInterior = (building.interior as Record<string, unknown>) || {}
    const buildingParking = (building.parking as Record<string, unknown>) || {}
    const lot = (attomObj?.lot as Record<string, unknown>) || {}
    const assessment = (attomObj?.assessment as Record<string, unknown>) || {}
    const assessedVals = (assessment.assessed as Record<string, unknown>) || {}
    const market = (assessment.market as Record<string, unknown>) || {}
    const sale = (attomObj?.sale as Record<string, unknown>) || {}
    const saleAmount = (sale.amount as Record<string, unknown>) || {}
    const summary = (attomObj?.summary as Record<string, unknown>) || {}

    if (attomData) {
      console.log('[property-lookup] ATTOM fields: yearbuilt=', summary.yearbuilt, 'beds=', buildingRooms.beds, 'baths=', buildingRooms.bathstotal, 'sqft=', buildingSize.livingsize, 'lot=', lot.lotsize2)
    }

    await supabase.from('property_features').insert({
      scan_id: scanId,
      year_built: (summary.yearbuilt as number) || (building.yearbuilt as number) || null,
      stories: (buildingSize.stories as number) || (building.noofstories as number) || structures[0]?.estimated_stories || null,
      living_sqft: (buildingSize.livingsize as number) || (buildingSize.universalsize as number) || null,
      lot_sqft: (lot.lotsize2 as number) || (lot.lotsize1 as number) || null,
      beds: (buildingRooms.beds as number) || null,
      baths_full: (buildingRooms.bathsfull as number) || null,
      baths_half: (buildingRooms.bathshalf as number) || null,
      construction_type: (buildingConstruction.constructiontype as string) || null,
      wall_type: (buildingConstruction.wallType as string) || null,
      roof_type_record: (buildingConstruction.roofcover as string) || null,
      heating_type: (buildingUtility.heatingtype as string) || null,
      cooling_type: (buildingUtility.coolingtype as string) || null,
      pool_type: (lot.pooltype as string) || null,
      garage_spaces: (buildingParking.garagetype as number) || 0,
      assessed_value: (assessedVals.assdttlvalue as number) || (market.mktttlvalue as number) || null,
      last_sale_price: (saleAmount.saleamt as number) || null,
      last_sale_date: (sale.salesearchdate as string) || (saleAmount.salerecdate as string) || null,
      elevation_ft: elevationFt,
      terrain_slope_pct: null,
      tree_coverage_pct: null,
      building_height_ft: structures[0]?.estimated_stories
        ? structures[0].estimated_stories * 10
        : null,
      data_sources: featureSources,
      raw_attom: attomData,
      raw_regrid: regridData,
      // Enhanced property details from ATTOM or inferred
      basement_type: (buildingInterior.bsmttype as string) || null,
      foundation_type: (buildingConstruction.foundationtype as string) || null,
      exterior_material: (buildingConstruction.wallType as string) || null,
      roof_material: (buildingConstruction.roofcover as string) || null,
      neighborhood_type: null, // updated after census data fetch
      census_data: {},
    })

    // ========================================================================
    // STEP 7b: GOOGLE STREET VIEW (FREE with API key)
    // ========================================================================
    let streetViewUrl: string | null = null
    const googleKey2 = Deno.env.get('GOOGLE_CLOUD_API_KEY')
    if (googleKey2 && lat && lng) {
      streetViewUrl = `https://maps.googleapis.com/maps/api/streetview?size=800x600&location=${lat},${lng}&fov=90&heading=0&pitch=10&key=${googleKey2}`
      sources.push('google_streetview')
      console.log('[property-lookup] Street View URL generated')
    }

    // ========================================================================
    // STEP 7c-7d4: PARALLEL API CALLS (FEMA + Census + NWS)
    // All run concurrently with 8-second timeout to prevent EF timeout
    // ========================================================================
    let floodZone: string | null = null
    let floodRisk: string | null = null
    let censusData: Record<string, unknown> = {}
    let neighborhoodType: string | null = null
    let activeAlerts: Array<{ event: string; severity: string; headline: string; expires: string }> = []

    if (lat && lng) {
      const apiTimeout = 8000 // 8 seconds max per API group
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), apiTimeout)

      // --- FEMA Flood Zone (parallel) ---
      const femaPromise = (async () => {
        try {
          const t5 = performance.now()
          const femaRes = await fetch(
            `https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/28/query?geometry=${lng},${lat}&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=FLD_ZONE,ZONE_SUBTY,SFHA_TF&returnGeometry=false&f=json`,
            { signal: controller.signal }
          )
          apiTimings.push({ api: 'fema_flood', ms: Math.round(performance.now() - t5), status: femaRes.ok ? 200 : femaRes.status, cost: 0 })
          if (femaRes.ok) {
            const femaData = await femaRes.json()
            const feature = femaData?.features?.[0]?.attributes
            if (feature) {
              const zone = feature.FLD_ZONE || null
              if (zone) {
                const highRiskZones = ['A', 'AE', 'AH', 'AO', 'AR', 'A99', 'V', 'VE']
                const moderateRiskZones = ['B', 'X500', 'SHADED X']
                const zoneParts = zone.toUpperCase().split(',')
                let risk = 'low'
                if (zoneParts.some((z: string) => highRiskZones.includes(z.trim()))) risk = 'high'
                else if (zoneParts.some((z: string) => moderateRiskZones.includes(z.trim()))) risk = 'moderate'
                else if (zone.toUpperCase().includes('X') || zone.toUpperCase().includes('C')) risk = 'minimal'
                return { zone, risk }
              }
            }
          }
        } catch (e) { console.warn('[property-lookup] FEMA flood failed:', e) }
        return null
      })()

      // --- Census ACS (FCC FIPS → Census API, parallel) ---
      const censusPromise = (async () => {
        try {
          const t6 = performance.now()
          const fccRes = await fetch(
            `https://geo.fcc.gov/api/census/block/find?latitude=${lat}&longitude=${lng}&format=json`,
            { signal: controller.signal }
          )
          if (!fccRes.ok) return null
          const fccData = await fccRes.json()
          const stateFips = fccData?.State?.FIPS
          const countyFips = fccData?.County?.FIPS
          const tractCode = fccData?.Block?.FIPS?.substring(5, 11)
          const countyName = fccData?.County?.name
          if (!stateFips || !countyFips || !tractCode) return null

          const censusVars = 'B01003_001E,B19013_001E,B25077_001E,B25035_001E,B25024_001E,B01002_001E,B25003_001E,B25003_002E'
          const censusUrl = `https://api.census.gov/data/2022/acs/acs5?get=${censusVars}&for=tract:${tractCode}&in=state:${stateFips}+county:${countyFips.substring(2)}`
          const censusRes = await fetch(censusUrl, { signal: controller.signal })
          apiTimings.push({ api: 'us_census', ms: Math.round(performance.now() - t6), status: 200, cost: 0 })
          if (!censusRes.ok) return null
          const censusArr = await censusRes.json()
          if (!censusArr?.length || censusArr.length < 2) return null
          const vals = censusArr[1]
          const population = parseInt(vals[0]) || null
          const medianIncome = parseInt(vals[1]) || null
          const medianHomeValue = parseInt(vals[2]) || null
          const medianYearBuilt = parseInt(vals[3]) || null
          const totalHousingUnits = parseInt(vals[4]) || null
          const medianAge = parseFloat(vals[5]) || null
          const totalOccupied = parseInt(vals[6]) || null
          const ownerOccupied = parseInt(vals[7]) || null
          let nbType: string | null = null
          if (population && totalHousingUnits) {
            if (population > 8000) nbType = 'urban'
            else if (population > 3000) nbType = 'suburban'
            else if (population > 500) nbType = 'exurban'
            else nbType = 'rural'
          }
          return {
            data: {
              tract: tractCode, county: countyName, state_fips: stateFips,
              population, median_income: medianIncome, median_home_value: medianHomeValue,
              median_year_built: medianYearBuilt, total_housing_units: totalHousingUnits,
              median_age: medianAge,
              owner_occupied_pct: totalOccupied && ownerOccupied ? Math.round((ownerOccupied / totalOccupied) * 100) : null,
            },
            neighborhoodType: nbType,
          }
        } catch (e) { console.warn('[property-lookup] Census failed:', e) }
        return null
      })()

      // --- NWS Weather Alerts (parallel) ---
      const nwsPromise = (async () => {
        try {
          const nwsRes = await fetch(
            `https://api.weather.gov/alerts/active?point=${lat},${lng}&status=actual`,
            { headers: { 'User-Agent': 'Zafto-PropertyIntelligence/1.0 (recon)', Accept: 'application/geo+json' }, signal: controller.signal }
          )
          if (!nwsRes.ok) return []
          const nwsData = await nwsRes.json()
          const features = nwsData?.features || []
          return features.slice(0, 5).map((f: Record<string, Record<string, string>>) => ({
            event: f.properties?.event || 'Unknown',
            severity: f.properties?.severity || 'Unknown',
            headline: f.properties?.headline || '',
            expires: f.properties?.expires || '',
          }))
        } catch { return [] }
      })()

      // Run all 3 in parallel
      const [femaResult, censusResult, nwsResult] = await Promise.allSettled([femaPromise, censusPromise, nwsPromise])
      clearTimeout(timeoutId)

      // Extract FEMA results
      if (femaResult.status === 'fulfilled' && femaResult.value) {
        floodZone = femaResult.value.zone
        floodRisk = femaResult.value.risk
        sources.push('fema_flood')
        console.log('[property-lookup] FEMA flood zone:', floodZone, 'risk:', floodRisk)
      }

      // Extract Census results
      if (censusResult.status === 'fulfilled' && censusResult.value) {
        censusData = censusResult.value.data
        neighborhoodType = censusResult.value.neighborhoodType
        sources.push('us_census')
        console.log('[property-lookup] Census data loaded')
      }

      // Extract NWS results
      if (nwsResult.status === 'fulfilled' && nwsResult.value && nwsResult.value.length > 0) {
        activeAlerts = nwsResult.value
        sources.push('nws_alerts')
        console.log('[property-lookup] NWS alerts:', activeAlerts.length)
      }
    }

    // ========================================================================
    // STEP 7d: EXTERNAL PROPERTY LINKS (deep links — all free)
    // ========================================================================
    const encodedAddr = encodeURIComponent(address)
    const externalLinks: Record<string, string> = {}
    // Google Maps
    if (lat && lng) {
      externalLinks.google_maps = `https://www.google.com/maps/place/${lat},${lng}/@${lat},${lng},18z`
    }
    // Zillow deep link (address search)
    externalLinks.zillow = `https://www.zillow.com/homes/${encodedAddr.replace(/%20/g, '-')}_rb/`
    // Redfin deep link
    externalLinks.redfin = `https://www.redfin.com/search#query=${encodedAddr}`
    // Realtor.com deep link
    externalLinks.realtor = `https://www.realtor.com/realestateandhomes-search/${encodedAddr.replace(/%20/g, '_')}`
    // County assessor (generic search — user can refine)
    if (geocodeState && geocodeCity) {
      externalLinks.county_assessor = `https://www.google.com/search?q=${encodeURIComponent(`${geocodeCity} ${geocodeState} county assessor property search ${address}`)}`
    }
    // Trulia
    externalLinks.trulia = `https://www.trulia.com/home-search/${encodedAddr.replace(/%20/g, '-')}`
    // FEMA flood map
    if (lat && lng) {
      externalLinks.fema_flood_map = `https://msc.fema.gov/portal/search?AddressQuery=${encodedAddr}`
    }
    // Building department (generic search)
    if (geocodeState && geocodeCity) {
      externalLinks.building_department = `https://www.google.com/search?q=${encodeURIComponent(`${geocodeCity} ${geocodeState} building department permits`)}`
    }
    // Permit history (Shovels.ai)
    externalLinks.permit_history = `https://app.shovels.ai/search?address=${encodedAddr}`
    // Utility provider lookup
    if (geocodeZip) {
      externalLinks.utility_lookup = `https://www.google.com/search?q=${encodeURIComponent(`electric utility provider ${geocodeZip}`)}`
    }
    console.log('[property-lookup] External links generated:', Object.keys(externalLinks).length)

    // Update property_features with census/neighborhood data (non-blocking)
    if (Object.keys(censusData).length > 0 || neighborhoodType) {
      supabase
        .from('property_features')
        .update({
          neighborhood_type: neighborhoodType,
          census_data: censusData,
        })
        .eq('scan_id', scanId)
        .then(() => console.log('[property-lookup] Census features updated'))
        .catch((e: Error) => console.warn('[property-lookup] Census features update failed:', e))
    }

    // ========================================================================
    // STEP 7d3: INFER PROPERTY TYPE
    // ========================================================================
    let propertyType: string | null = null
    if (structures.length > 0) {
      const primary = structures[0]
      const footprint = primary.footprint_sqft
      const stories = primary.estimated_stories
      const totalSqft = footprint * stories

      // Simple heuristics based on building characteristics
      if (footprint > 10000) propertyType = 'commercial'
      else if (structures.length >= 3 && footprint > 2000) propertyType = 'multi_family'
      else if (totalSqft < 800) propertyType = 'condo'
      else if (footprint < 1200 && structures.length === 1) propertyType = 'townhouse'
      else propertyType = 'single_family'
    }

    // ========================================================================
    // STEP 7d4: PARALLEL FREE API CALLS — Weather + NOAA Storm Events
    // Open-Meteo (no key), NOAA Storm Events (free)
    // ========================================================================
    let weatherHistory: Record<string, unknown> = {}
    let noaaStormEvents: Array<{ date: string; event_type: string; magnitude: string; description: string }> = []
    let treeCanopyPct: number | null = null

    if (lat && lng) {
      const envTimeout = 8000
      const envController = new AbortController()
      const envTimeoutId = setTimeout(() => envController.abort(), envTimeout)

      // --- Open-Meteo Weather History (last 2 years) ---
      const openMeteoPromise = (async () => {
        try {
          const t7 = performance.now()
          const endDate = new Date().toISOString().split('T')[0]
          const startDate = new Date(Date.now() - 730 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
          const omRes = await fetch(
            `https://archive-api.open-meteo.com/v1/archive?latitude=${lat}&longitude=${lng}&start_date=${startDate}&end_date=${endDate}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max&timezone=America%2FNew_York`,
            { signal: envController.signal }
          )
          apiTimings.push({ api: 'open_meteo', ms: Math.round(performance.now() - t7), status: omRes.ok ? 200 : omRes.status, cost: 0 })
          if (omRes.ok) {
            const omData = await omRes.json()
            const daily = omData?.daily
            if (daily?.temperature_2m_max && daily?.temperature_2m_min) {
              const temps_max = daily.temperature_2m_max as number[]
              const temps_min = daily.temperature_2m_min as number[]
              const precip = (daily.precipitation_sum as number[]) || []
              const wind = (daily.wind_speed_10m_max as number[]) || []

              // Convert C to F
              const maxF = Math.round(Math.max(...temps_max.filter((t: number) => t != null)) * 9/5 + 32)
              const minF = Math.round(Math.min(...temps_min.filter((t: number) => t != null)) * 9/5 + 32)

              // Count freeze-thaw cycles (days where temp crosses 32F)
              let freezeThawCycles = 0
              for (let i = 0; i < temps_min.length; i++) {
                if (temps_min[i] != null && temps_max[i] != null) {
                  const minTempF = temps_min[i] * 9/5 + 32
                  const maxTempF = temps_max[i] * 9/5 + 32
                  if (minTempF < 32 && maxTempF > 32) freezeThawCycles++
                }
              }

              // Annual precipitation (sum then divide by years)
              const totalPrecipMm = precip.reduce((s: number, v: number) => s + (v || 0), 0)
              const annualPrecipIn = Math.round((totalPrecipMm / 25.4 / 2) * 10) / 10 // 2 years of data

              // Average max wind speed
              const avgWindKmh = wind.length > 0 ? wind.reduce((s: number, v: number) => s + (v || 0), 0) / wind.length : 0
              const avgWindMph = Math.round(avgWindKmh * 0.621371)

              weatherHistory = {
                freeze_thaw_cycles: freezeThawCycles,
                annual_precip_in: annualPrecipIn,
                temp_min_f: minF,
                temp_max_f: maxF,
                avg_wind_mph: avgWindMph,
                data_years: 2,
              }
              sources.push('open_meteo')
              console.log('[property-lookup] Open-Meteo: freeze-thaw=', freezeThawCycles, 'precip=', annualPrecipIn, 'in')
            }
          }
        } catch (e) { console.warn('[property-lookup] Open-Meteo failed:', e) }
      })()

      // --- NOAA Storm Events (county-level historical data) ---
      const noaaPromise = (async () => {
        try {
          if (!geocodeState) return
          const t8 = performance.now()
          // NOAA Storm Events CSV API — search by state/county
          const yearEnd = new Date().getFullYear()
          const yearStart = yearEnd - 10
          // Use the NCDC storm events search
          const noaaRes = await fetch(
            `https://www.ncdc.noaa.gov/stormevents/csv?eventType=Hail&eventType=Thunderstorm+Wind&eventType=Tornado&beginDate_mm=01&beginDate_dd=01&beginDate_yyyy=${yearStart}&endDate_mm=12&endDate_dd=31&endDate_yyyy=${yearEnd}&state=${encodeURIComponent(geocodeState)}&county=${encodeURIComponent(geocodeCity?.toUpperCase() || '')}&hailfilter=0.00&tornfilter=0&windfilter=000&sort=DT&submitbutton=Search&staession=0`,
            { signal: envController.signal, headers: { Accept: 'text/csv,application/json,*/*' } }
          )
          apiTimings.push({ api: 'noaa_storm', ms: Math.round(performance.now() - t8), status: noaaRes.ok ? 200 : noaaRes.status, cost: 0 })

          // NOAA may not return clean data, so we'll use a simplified approach
          // based on state + county for storm probability
          if (noaaRes.ok) {
            const noaaText = await noaaRes.text()
            // Parse basic events from response (CSV format)
            const lines = noaaText.split('\n').slice(1) // skip header
            const events: typeof noaaStormEvents = []
            for (const line of lines.slice(0, 20)) { // limit to 20 events
              const parts = line.split(',')
              if (parts.length >= 8) {
                events.push({
                  date: parts[1]?.replace(/"/g, '') || '',
                  event_type: parts[5]?.replace(/"/g, '') || '',
                  magnitude: parts[6]?.replace(/"/g, '') || '',
                  description: parts[7]?.replace(/"/g, '').substring(0, 200) || '',
                })
              }
            }
            if (events.length > 0) {
              noaaStormEvents = events
              sources.push('noaa_storm')
              console.log('[property-lookup] NOAA storm events:', events.length)
            }
          }
        } catch (e) { console.warn('[property-lookup] NOAA storm events failed:', e) }
      })()

      // --- NLCD Tree Canopy (USGS REST service) ---
      const nlcdPromise = (async () => {
        try {
          const t9 = performance.now()
          // NLCD Tree Canopy via USGS MapServer
          const nlcdRes = await fetch(
            `https://www.mrlc.gov/geoserver/mrlc_display/NLCD_2021_Tree_Canopy_L48/ows?service=WMS&version=1.1.1&request=GetFeatureInfo&layers=NLCD_2021_Tree_Canopy_L48&query_layers=NLCD_2021_Tree_Canopy_L48&info_format=application/json&x=128&y=128&width=256&height=256&srs=EPSG:4326&bbox=${lng-0.001},${lat-0.001},${lng+0.001},${lat+0.001}`,
            { signal: envController.signal }
          )
          apiTimings.push({ api: 'nlcd_canopy', ms: Math.round(performance.now() - t9), status: nlcdRes.ok ? 200 : nlcdRes.status, cost: 0 })
          if (nlcdRes.ok) {
            const nlcdData = await nlcdRes.json()
            const pixelValue = nlcdData?.features?.[0]?.properties?.GRAY_INDEX
            if (pixelValue != null && !isNaN(Number(pixelValue))) {
              treeCanopyPct = Math.min(100, Math.max(0, Number(pixelValue)))
              sources.push('nlcd_canopy')
              console.log('[property-lookup] NLCD tree canopy:', treeCanopyPct, '%')
            }
          }
        } catch (e) { console.warn('[property-lookup] NLCD canopy failed:', e) }
      })()

      const [omResult, noaaResult, nlcdResult] = await Promise.allSettled([openMeteoPromise, noaaPromise, nlcdPromise])
      clearTimeout(envTimeoutId)
      void omResult; void noaaResult; void nlcdResult
    }

    // ========================================================================
    // STEP 7d5: COMPUTED MEASUREMENTS (no API calls)
    // ========================================================================
    const facetCount = solarData?.solarPotential?.roofSegmentStats?.length || 0
    const yearBuilt = (summary.yearbuilt as number) || (building.yearbuilt as number) || null
    const lotSqft = (lot.lotsize2 as number) || (lot.lotsize1 as number) || null
    const livingSqft = (buildingSize.livingsize as number) || (buildingSize.universalsize as number) || null
    const primaryFootprint = structures[0]?.footprint_sqft || 0
    const primaryStories = structures[0]?.estimated_stories || 1

    // Lawn/Yard Area: lot - footprint - estimated driveway (15% of footprint for typical garage)
    const estimatedDrivewaySqft = primaryFootprint > 0 ? Math.round(primaryFootprint * 0.15) : 0
    const lawnAreaSqft = lotSqft && primaryFootprint
      ? Math.max(0, Math.round(lotSqft - primaryFootprint - estimatedDrivewaySqft))
      : null

    // Wall Area: perimeter * (stories * 9ft ceiling) - estimated windows/doors (15% of wall area)
    const buildingPerimeter = primaryFootprint > 0 ? Math.sqrt(primaryFootprint) * 4 : 0
    const grossWallArea = buildingPerimeter * (primaryStories * 9)
    const wallAreaSqft = grossWallArea > 0 ? Math.round(grossWallArea * 0.85) : null // 15% openings

    // Roof Complexity Factor: 1.0 simple → 2.0+ complex
    let roofComplexityFactor = 1.0
    if (facetCount <= 2) roofComplexityFactor = 1.0  // Simple gable
    else if (facetCount <= 4) roofComplexityFactor = 1.2  // Standard hip
    else if (facetCount <= 8) roofComplexityFactor = 1.5  // Complex hip/valley
    else if (facetCount <= 12) roofComplexityFactor = 1.8  // Very complex
    else roofComplexityFactor = 2.0 + (facetCount - 12) * 0.1  // Extreme complexity

    // Boundary Perimeter: from Regrid parcel boundary GeoJSON
    let boundaryPerimeterFt: number | null = null
    if (regridData) {
      const parcelGeom = (regridData as Record<string, unknown>).geometry as GeoJsonPolygon | null
      if (parcelGeom?.coordinates?.[0]) {
        const ring = parcelGeom.coordinates[0]
        let perimeterFt = 0
        for (let i = 0; i < ring.length - 1; i++) {
          perimeterFt += distanceFt(ring[i][1], ring[i][0], ring[i + 1][1], ring[i + 1][0])
        }
        boundaryPerimeterFt = Math.round(perimeterFt)
      }
    }

    const computedMeasurements = {
      lawn_area_sqft: lawnAreaSqft,
      wall_area_sqft: wallAreaSqft,
      roof_complexity_factor: Math.round(roofComplexityFactor * 100) / 100,
      boundary_perimeter_ft: boundaryPerimeterFt,
      driveway_area_sqft: estimatedDrivewaySqft,
      building_perimeter_ft: Math.round(buildingPerimeter),
    }

    // ========================================================================
    // STEP 7d6: HAZARD FLAGS ENGINE (12 types)
    // ========================================================================
    const hazardFlags: HazardFlag[] = []
    const stateCode = geocodeState?.toUpperCase() || ''

    // 1. Lead Paint (pre-1978)
    if (yearBuilt && yearBuilt < 1978) {
      hazardFlags.push({
        type: 'lead_paint',
        severity: 'red',
        title: 'Lead Paint Risk',
        description: `Built in ${yearBuilt} — pre-1978 construction has high probability of lead-based paint on interior and exterior surfaces.`,
        what_to_do: 'EPA RRP (Renovation, Repair, and Painting) certified contractor required. Lead testing before any paint disturbance. Containment and cleanup per EPA protocols.',
        cost_implications: 'Lead abatement adds 20-40% to painting/renovation costs. EPA RRP certification required for contractors.',
        regulatory: 'EPA RRP Rule (40 CFR 745). Contractors must be EPA-certified. Pre-renovation lead testing required. Violation penalties up to $37,500/day.',
      })
    }

    // 2. Asbestos (pre-1980)
    if (yearBuilt && yearBuilt < 1980) {
      hazardFlags.push({
        type: 'asbestos',
        severity: yearBuilt < 1970 ? 'red' : 'yellow',
        title: 'Asbestos Risk',
        description: `Built in ${yearBuilt} — pre-1980 construction may contain asbestos in insulation, floor tiles, siding, roofing, popcorn ceilings, pipe wrap, and duct insulation.`,
        what_to_do: 'Professional asbestos inspection before any demolition or renovation. Do NOT disturb suspected materials. Licensed abatement contractor for removal.',
        cost_implications: 'Asbestos testing: $200-$800. Abatement: $1,500-$30,000+ depending on scope. Do not disturb without testing.',
        regulatory: 'NESHAP (40 CFR 61). State licensing requirements vary. OSHA standards for worker protection. Improper removal is a federal crime.',
      })
    }

    // 3. Radon
    const radonZone = stateCode ? EPA_RADON_ZONES[stateCode] ?? null : null
    if (radonZone === 1) {
      hazardFlags.push({
        type: 'radon',
        severity: 'red',
        title: 'High Radon Risk (EPA Zone 1)',
        description: 'EPA Zone 1 — predicted indoor radon screening level > 4 pCi/L. Radon is the #2 cause of lung cancer.',
        what_to_do: 'Professional radon test required before any basement/foundation work. Radon mitigation system if levels exceed 4 pCi/L.',
        cost_implications: 'Radon test: $150-$300. Mitigation system: $800-$2,500. Required disclosure in most states.',
        regulatory: 'EPA recommends testing all homes. Many states require radon disclosure at sale. Some states require radon-resistant new construction.',
      })
    } else if (radonZone === 2) {
      hazardFlags.push({
        type: 'radon',
        severity: 'yellow',
        title: 'Moderate Radon Risk (EPA Zone 2)',
        description: 'EPA Zone 2 — predicted indoor radon screening level 2-4 pCi/L. Testing recommended.',
        what_to_do: 'Radon test recommended, especially if property has basement or crawl space.',
        cost_implications: 'Radon test: $150-$300. Mitigation if needed: $800-$2,500.',
        regulatory: 'EPA recommends testing. State requirements vary.',
      })
    }

    // 4. Flood Zone (already computed from FEMA)
    if (floodRisk === 'high') {
      hazardFlags.push({
        type: 'flood_zone',
        severity: 'red',
        title: `High-Risk Flood Zone (${floodZone})`,
        description: `FEMA Zone ${floodZone} — Special Flood Hazard Area (SFHA). 1% annual chance of flooding.`,
        what_to_do: 'Flood insurance required for federally-backed mortgages. Consider flood-resistant materials and elevated utilities. Check local floodplain ordinances.',
        cost_implications: 'Flood insurance: $700-$3,000+/year. Flood-resistant construction adds 15-25%. Materials below BFE must be flood-resistant.',
        regulatory: 'National Flood Insurance Program (NFIP). Local floodplain management ordinances. Substantial improvement/damage rules (50% threshold).',
      })
    } else if (floodRisk === 'moderate') {
      hazardFlags.push({
        type: 'flood_zone',
        severity: 'yellow',
        title: `Moderate Flood Risk (${floodZone})`,
        description: `FEMA Zone ${floodZone} — moderate flood risk area. 0.2% annual chance of flooding.`,
        what_to_do: 'Flood insurance recommended but not required. Consider water damage prevention measures.',
        cost_implications: 'Preferred risk flood policies available at lower cost.',
        regulatory: 'Not in SFHA but flood insurance still recommended by FEMA.',
      })
    }

    // 5. Wildfire Risk (state-based heuristic — USFS API would enhance this)
    const highWildfireStates = ['CA', 'CO', 'OR', 'WA', 'MT', 'ID', 'NM', 'AZ', 'UT', 'NV', 'TX', 'OK']
    if (highWildfireStates.includes(stateCode)) {
      hazardFlags.push({
        type: 'wildfire',
        severity: ['CA', 'CO', 'OR'].includes(stateCode) ? 'yellow' : 'green',
        title: 'Wildfire Risk Area',
        description: `Property is in ${stateCode}, which has elevated wildfire risk. Specific risk depends on proximity to wildland-urban interface.`,
        what_to_do: 'Maintain defensible space (30-100ft from structures). Use fire-resistant roofing and siding materials. Clear vegetation from eaves and vents.',
        cost_implications: 'Fire-resistant materials add 10-20% to exterior work. Defensible space maintenance: $500-$2,000/year.',
        regulatory: 'State fire codes vary. CA requires 100ft defensible space. WUI building codes may apply.',
      })
    }

    // 6. Seismic Risk
    const climateZone = stateCode ? IECC_CLIMATE_ZONES[stateCode] || null : null
    const asce7 = climateZone ? ASCE7_DEFAULTS[climateZone] || null : null
    const seismicCat = asce7?.seismic || null
    if (seismicCat && ['C', 'D0', 'D1', 'D2', 'E', 'F'].includes(seismicCat)) {
      hazardFlags.push({
        type: 'seismic',
        severity: ['D0', 'D1', 'D2', 'E', 'F'].includes(seismicCat) ? 'yellow' : 'green',
        title: `Seismic Design Category ${seismicCat}`,
        description: `ASCE 7 Seismic Design Category ${seismicCat}. Special foundation and framing requirements may apply.`,
        what_to_do: 'Ensure structural work meets seismic code requirements. Anchor water heaters, brace cripple walls, secure masonry chimneys.',
        cost_implications: 'Seismic retrofitting: $3,000-$10,000+. Seismic-compliant framing adds 5-15% to structural costs.',
        regulatory: 'IBC seismic provisions. Local amendments may be more stringent (especially CA, OR, WA).',
      })
    }

    // 7. Problem Electrical Panels
    if (yearBuilt) {
      for (const panel of PROBLEM_PANELS) {
        if (yearBuilt >= panel.yearStart && yearBuilt <= panel.yearEnd) {
          hazardFlags.push({
            type: 'problem_panels',
            severity: 'red',
            title: `Potential ${panel.name} Panel`,
            description: `Built in ${yearBuilt} — during the era of ${panel.name} electrical panels. These panels have a documented history of failing to trip during overcurrent, causing fires.`,
            what_to_do: 'Inspect electrical panel immediately. If confirmed, recommend full panel replacement. Do NOT add circuits to a known problem panel.',
            cost_implications: 'Panel replacement: $1,500-$4,000. Some insurance companies refuse coverage or charge higher premiums for homes with these panels.',
            regulatory: 'While not universally banned, many jurisdictions require replacement during renovation. Insurance companies may require replacement for coverage.',
          })
          break // Only flag once
        }
      }
    }

    // 8. Termite Risk
    const termiteZone = stateCode ? TERMITE_ZONES[stateCode] || null : null
    if (termiteZone === 'very_heavy') {
      hazardFlags.push({
        type: 'termite',
        severity: 'yellow',
        title: 'Very Heavy Termite Zone',
        description: `${stateCode} is in a very heavy termite infestation probability zone. Subterranean and/or drywood termites common.`,
        what_to_do: 'Termite inspection recommended before any wood-touching work. Check for mud tubes, damaged wood, frass. Pre-treat soil for new construction.',
        cost_implications: 'Termite inspection: $75-$150. Treatment: $500-$2,500. Annual prevention: $200-$400.',
        regulatory: 'Many states require termite inspection for real estate transactions. Pre-treatment required for new construction in high-risk zones.',
      })
    } else if (termiteZone === 'moderate_to_heavy') {
      hazardFlags.push({
        type: 'termite',
        severity: 'green',
        title: 'Moderate Termite Risk',
        description: `${stateCode} has moderate to heavy termite activity. Inspect wood-contacting areas.`,
        what_to_do: 'Termite inspection recommended for older homes. Maintain clearance between wood and soil.',
        cost_implications: 'Termite inspection: $75-$150. Treatment if needed: $500-$2,500.',
        regulatory: 'State-specific requirements. Inspection often required for real estate transactions.',
      })
    }

    // 9. Galvanized Pipe (pre-1960)
    if (yearBuilt && yearBuilt < 1960) {
      hazardFlags.push({
        type: 'galvanized_pipe',
        severity: 'yellow',
        title: 'Likely Galvanized Plumbing',
        description: `Built in ${yearBuilt} — likely has galvanized steel water supply pipes. These corrode internally, reducing water pressure and potentially leaching lead from solder joints.`,
        what_to_do: 'Check water pressure and flow at fixtures. Interior pipe inspection recommended. Plan for whole-house repipe with copper or PEX.',
        cost_implications: 'Whole-house repipe: $4,000-$15,000 depending on size and access. Water testing for lead: $20-$50.',
        regulatory: 'No mandate to replace, but lead levels must meet EPA standards. Disclosure may be required at sale.',
      })
    }

    // 10. Knob & Tube Wiring (pre-1950)
    if (yearBuilt && yearBuilt < 1950) {
      hazardFlags.push({
        type: 'knob_and_tube',
        severity: 'yellow',
        title: 'Possible Knob & Tube Wiring',
        description: `Built in ${yearBuilt} — may have original knob and tube wiring. K&T is not inherently dangerous but becomes hazardous when buried in insulation or modified improperly.`,
        what_to_do: 'Professional electrical inspection. Do NOT blow insulation over K&T wiring. Plan for rewiring if adding circuits or insulation.',
        cost_implications: 'Rewiring: $8,000-$20,000+. Many insurance companies refuse coverage or charge premium for K&T homes.',
        regulatory: 'NEC does not require removal of existing K&T, but modifications must meet current code. Insurance requirements often drive replacement.',
      })
    }

    // 11. Chinese Drywall (2001-2009)
    if (yearBuilt && yearBuilt >= 2001 && yearBuilt <= 2009) {
      hazardFlags.push({
        type: 'chinese_drywall',
        severity: 'yellow',
        title: 'Chinese Drywall Risk Era',
        description: `Built in ${yearBuilt} — construction era associated with imported defective drywall. Symptoms: corroded copper pipes/wiring, sulfur smell, HVAC coil failures, health complaints.`,
        what_to_do: 'Check for signs: blackened copper, corroded electrical outlets, sulfur odor. CPSC has testing protocols.',
        cost_implications: 'Full remediation: $100,000-$200,000+ (complete drywall replacement, rewiring, replumbing). Most cases covered by class action settlements.',
        regulatory: 'CPSC investigation and guidance. Class action settlements may apply. Disclosure required in many states.',
      })
    }

    // 12. Polybutylene Pipe (1978-1995)
    if (yearBuilt && yearBuilt >= 1978 && yearBuilt <= 1995) {
      hazardFlags.push({
        type: 'polybutylene_pipe',
        severity: 'yellow',
        title: 'Possible Polybutylene Plumbing',
        description: `Built in ${yearBuilt} — may have polybutylene (PB) water supply pipes. PB degrades from chlorine in water, causing micro-fractures and sudden pipe bursts.`,
        what_to_do: 'Inspect supply lines for gray plastic pipe (usually stamped "PB2110"). Plan for repipe with copper or PEX if confirmed.',
        cost_implications: 'Repipe: $4,000-$15,000. Original class action settlement (Cox v. Shell) expired but some insurers still cover. High burst risk means potential water damage.',
        regulatory: 'PB is no longer approved for new construction. No mandate to replace existing, but disclosure may be required at sale.',
      })
    }

    console.log('[property-lookup] Hazard flags generated:', hazardFlags.length)

    // ========================================================================
    // STEP 7d7: ENVIRONMENTAL + CODE REQUIREMENTS AGGREGATION
    // ========================================================================
    const environmentalData: Record<string, unknown> = {
      climate_zone: climateZone,
      radon_zone: radonZone,
      termite_zone: termiteZone,
      tree_canopy_pct: treeCanopyPct,
      frost_line_depth_in: asce7?.frost_in || null,
      soil_type: null, // Populated by SSURGO if available
      soil_drainage: null,
    }

    const codeRequirements: Record<string, unknown> = {
      wind_speed_mph: asce7?.wind_mph || null,
      snow_load_psf: asce7?.snow_psf || null,
      seismic_category: seismicCat,
      energy_code: climateZone ? `IECC ${climateZone}` : null,
      insulation_r_values: climateZone ? INSULATION_R_VALUES[climateZone] || null : null,
      frost_line_depth_in: asce7?.frost_in || null,
    }

    // ========================================================================
    // STEP 7d8: UPDATE PROPERTY FEATURES WITH ENVIRONMENTAL DATA
    // ========================================================================
    supabase
      .from('property_features')
      .update({
        radon_zone: radonZone,
        wildfire_risk: highWildfireStates.includes(stateCode) ? (['CA', 'CO', 'OR'].includes(stateCode) ? 'high' : 'moderate') : 'low',
        seismic_category: seismicCat,
        climate_zone: climateZone,
        frost_line_depth_in: asce7?.frost_in || null,
        design_wind_speed_mph: asce7?.wind_mph || null,
        snow_load_psf: asce7?.snow_psf || null,
        tree_canopy_pct: treeCanopyPct,
        lawn_area_sqft: lawnAreaSqft,
        wall_area_sqft: wallAreaSqft,
        roof_complexity_factor: Math.round(roofComplexityFactor * 100) / 100,
        boundary_perimeter_ft: boundaryPerimeterFt,
        termite_zone: termiteZone,
      })
      .eq('scan_id', scanId)
      .then(() => console.log('[property-lookup] Environmental features updated'))
      .catch((e: Error) => console.warn('[property-lookup] Environmental features update failed:', e))

    // ========================================================================
    // STEP 7e: AUTO-CREATE STORAGE FOLDER + SAVE IMAGES
    // ========================================================================
    const normalizedFolderName = address
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_|_$/g, '')
      .substring(0, 100)
    const storageFolder = `recon/${companyId}/${normalizedFolderName}`

    // FIRE-AND-FORGET: Storage uploads run in background, don't block scan response
    const mapboxToken = Deno.env.get('NEXT_PUBLIC_MAPBOX_TOKEN') || Deno.env.get('MAPBOX_TOKEN')
    const storagePromises: Promise<void>[] = []

    // Save satellite image (fire-and-forget)
    if (mapboxToken && lat && lng) {
      storagePromises.push((async () => {
        try {
          const satUrl = `https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${lng},${lat},18,0/800x600@2x?access_token=${mapboxToken}`
          const satRes = await fetch(satUrl)
          if (satRes.ok) {
            const satBlob = await satRes.arrayBuffer()
            await supabase.storage
              .from('recon-photos')
              .upload(`${storageFolder}/satellite.jpg`, satBlob, { contentType: 'image/jpeg', upsert: true })
            console.log('[property-lookup] Satellite image saved')
          }
        } catch (e) { console.warn('[property-lookup] Satellite save failed:', e) }
      })())
    }

    // Save Street View image (fire-and-forget)
    if (streetViewUrl) {
      storagePromises.push((async () => {
        try {
          const svRes = await fetch(streetViewUrl)
          if (svRes.ok) {
            const svBlob = await svRes.arrayBuffer()
            await supabase.storage
              .from('recon-photos')
              .upload(`${storageFolder}/street_view.jpg`, svBlob, { contentType: 'image/jpeg', upsert: true })
            console.log('[property-lookup] Street View image saved')
          }
        } catch (e) { console.warn('[property-lookup] Street View save failed:', e) }
      })())
    }

    // Save recon report JSON (fire-and-forget)
    const reconReport = {
      generated_at: new Date().toISOString(),
      scan_id: scanId, address,
      coordinates: { lat, lng },
      city: geocodeCity, state: geocodeState, zip: geocodeZip,
      elevation_ft: elevationFt, flood_zone: floodZone, flood_risk: floodRisk,
      property_type: propertyType, neighborhood_type: neighborhoodType,
      census: censusData, external_links: externalLinks,
      active_weather_alerts: activeAlerts, street_view_url: streetViewUrl,
      hazard_flags: hazardFlags,
      environmental: environmentalData,
      code_requirements: codeRequirements,
      weather_history: weatherHistory,
      computed_measurements: computedMeasurements,
      noaa_storm_events: noaaStormEvents,
      sources,
      structures: structures.map(s => ({
        type: s.structure_type, label: s.label,
        footprint_sqft: s.footprint_sqft, stories: s.estimated_stories,
        roof_area_sqft: s.estimated_roof_area_sqft, wall_area_sqft: s.estimated_wall_area_sqft,
      })),
      roof: roofMeasurementId ? {
        total_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
        facet_count: facetCount,
      } : null,
    }
    storagePromises.push((async () => {
      try {
        await supabase.storage
          .from('recon-photos')
          .upload(`${storageFolder}/recon_report.json`, JSON.stringify(reconReport, null, 2), { contentType: 'application/json', upsert: true })
        console.log('[property-lookup] Recon report saved')
      } catch (e) { console.warn('[property-lookup] Recon report save failed:', e) }
    })())

    // Don't await storage — let them complete in background
    Promise.allSettled(storagePromises).then(() => console.log('[property-lookup] All storage uploads done'))

    // ========================================================================
    // STEP 8: CONFIDENCE SCORING
    // ========================================================================
    let baseScore = solarData ? 95 : 50
    if (structures.length > 0 && !solarData) baseScore = 70 // footprint-only
    let treePenalty = 0
    let agePenalty = 0
    let complexityPenalty = 0
    let verificationBonus = 0

    if (imageryDate) {
      const ageMonths = Math.round(
        (Date.now() - imageryDate.getTime()) / (1000 * 60 * 60 * 24 * 30)
      )
      agePenalty = Math.min(20, ageMonths * 1.5)
    }

    const facetCountForScore = solarData?.solarPotential?.roofSegmentStats?.length || 0
    if (facetCountForScore > 12) complexityPenalty += 5
    if ((structures[0]?.estimated_stories || 1) > 2) complexityPenalty += 5

    // Bonus for multiple data sources
    if (sources.length >= 3) verificationBonus += 5

    // Bonus for flood + street view + census data + environmental
    if (floodZone) verificationBonus += 3
    if (streetViewUrl) verificationBonus += 2
    if (Object.keys(censusData).length > 0) verificationBonus += 3
    if (Object.keys(weatherHistory).length > 0) verificationBonus += 2
    if (treeCanopyPct != null) verificationBonus += 1
    if (hazardFlags.length > 0) verificationBonus += 2

    const confidence = Math.max(
      0,
      Math.min(
        100,
        Math.round(baseScore - treePenalty - agePenalty - complexityPenalty + verificationBonus)
      )
    )
    const grade = confidence >= 80 ? 'high' : confidence >= 50 ? 'moderate' : 'low'

    // Determine final status
    const hasRoofData = solarData != null && roofMeasurementId != null
    const hasStructures = structures.length > 0
    const finalStatus = hasRoofData ? 'complete' : hasStructures ? 'partial' : 'partial'

    await supabase
      .from('property_scans')
      .update({
        status: finalStatus,
        scan_sources: sources,
        confidence_score: confidence,
        confidence_grade: grade,
        confidence_factors: {
          base_score: baseScore,
          tree_penalty: treePenalty,
          imagery_age_penalty: agePenalty,
          complexity_penalty: complexityPenalty,
          verification_bonus: verificationBonus,
          sources_used: sources,
          structure_count: structures.length,
        },
        // Enhanced recon data
        storage_folder: storageFolder,
        street_view_url: streetViewUrl,
        external_links: externalLinks,
        property_type: propertyType,
        flood_zone: floodZone,
        flood_risk: floodRisk,
        // Phase 3A+3B: Hazard flags, environmental, code, weather
        hazard_flags: hazardFlags,
        environmental_data: environmentalData,
        code_requirements: codeRequirements,
        weather_history: weatherHistory,
        computed_measurements: computedMeasurements,
        noaa_storm_events: noaaStormEvents,
      })
      .eq('id', scanId)

    // Link to job if provided
    if (job_id) {
      await supabase.from('jobs').update({ property_scan_id: scanId }).eq('id', job_id)
    }

    // Auto-trigger roof calculator if we have a measurement
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    if (roofMeasurementId && supabaseUrl) {
      try {
        const roofCalcRes = await fetch(`${supabaseUrl}/functions/v1/recon-roof-calculator`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ roof_measurement_id: roofMeasurementId }),
        })
        if (!roofCalcRes.ok) {
          console.warn(`[property-lookup] Roof calculator returned ${roofCalcRes.status}`)
        }
      } catch (e) {
        console.warn('[property-lookup] Roof calculator auto-trigger failed:', e)
      }
    }

    // Auto-trigger trade estimator to generate all 10 trade pipelines
    if (supabaseUrl) {
      try {
        const tradeRes = await fetch(`${supabaseUrl}/functions/v1/recon-trade-estimator`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ scan_id: scanId }),
        })
        if (!tradeRes.ok) {
          console.warn(`[property-lookup] Trade estimator returned ${tradeRes.status}`)
        }
      } catch (e) {
        console.warn('[property-lookup] Trade estimator auto-trigger failed:', e)
      }
    }

    // ========================================================================
    // BATCH LOG: API cost tracking (non-blocking)
    // ========================================================================
    for (const timing of apiTimings) {
      logApiCall(supabase, {
        company_id: companyId,
        api_name: timing.api,
        endpoint: timing.api,
        response_status: timing.status,
        latency_ms: timing.ms,
        cost_cents: timing.cost,
        created_by: user.id,
      }).catch(() => {})
    }

    // ========================================================================
    // WRITE scan_cache (non-blocking — cache full scan result for reuse)
    // ========================================================================
    supabase.from('scan_cache').upsert({
      company_id: companyId,
      address_hash: addressHash,
      address_normalized: address.trim().toLowerCase(),
      scan_data: {
        scan_id: scanId,
        status: finalStatus,
        sources,
        confidence_score: confidence,
        structure_count: structures.length,
        roof_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
      },
      source_apis: sources,
      cached_at: new Date().toISOString(),
      expires_at: cachedUntil.toISOString(),
      hit_count: 0,
    }, { onConflict: 'company_id,address_hash' })

    return jsonResponse({
      scan_id: scanId,
      status: finalStatus,
      confidence_score: confidence,
      confidence_grade: grade,
      sources,
      structure_count: structures.length,
      roof_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
      has_roof_measurement: roofMeasurementId != null,
      roof_measurement_id: roofMeasurementId,
      imagery_date: imageryDate?.toISOString().split('T')[0] || null,
      elevation_ft: elevationFt,
      flood_zone: floodZone,
      flood_risk: floodRisk,
      property_type: propertyType,
      street_view_url: streetViewUrl,
      external_links: externalLinks,
      storage_folder: storageFolder,
      census_data: censusData,
      // Phase 3A+3B enhanced data
      hazard_flags: hazardFlags,
      hazard_count: hazardFlags.length,
      red_flags: hazardFlags.filter(f => f.severity === 'red').length,
      yellow_flags: hazardFlags.filter(f => f.severity === 'yellow').length,
      environmental_data: environmentalData,
      code_requirements: codeRequirements,
      weather_history: weatherHistory,
      computed_measurements: computedMeasurements,
      noaa_storm_events: noaaStormEvents.length,
    }, 200, origin)
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    console.error('[property-lookup] Error:', message)
    return jsonResponse({ error: message }, 500, origin)
  }
})
