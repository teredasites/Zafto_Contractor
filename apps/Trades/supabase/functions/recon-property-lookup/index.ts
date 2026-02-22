// Supabase Edge Function: recon-property-lookup
// Full property intelligence pipeline:
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
          const attomRes = await fetch(
            `https://api.gateway.attomdata.com/propertyapi/v1.0.0/property/expandedprofile?address1=${encodeURIComponent(address)}&address2=`,
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
            }
          }
        } catch {
          /* ATTOM failed, non-critical */
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
    const building = (attomData as Record<string, Record<string, unknown>>)?.building || {}
    const lot = (attomData as Record<string, Record<string, unknown>>)?.lot || {}
    const assessment = (attomData as Record<string, Record<string, unknown>>)?.assessment || {}
    const sale = (attomData as Record<string, Record<string, unknown>>)?.sale || {}
    const saleHistory = sale?.amount as Record<string, unknown> | undefined

    await supabase.from('property_features').insert({
      scan_id: scanId,
      year_built: (building.yearbuilt as number) || null,
      stories: (building.noofstories as number) || structures[0]?.estimated_stories || null,
      living_sqft: (building.size?.livingsize as number) || null,
      lot_sqft: (lot.lotsize2 as number) || null,
      beds: (building.rooms?.beds as number) || null,
      baths_full: (building.rooms?.bathsfull as number) || null,
      baths_half: (building.rooms?.bathshalf as number) || null,
      construction_type: (building.construction?.constructiontype as string) || null,
      wall_type: (building.construction?.wallType as string) || null,
      roof_type_record: (building.construction?.roofcover as string) || null,
      heating_type: (building.utility?.heatingtype as string) || null,
      cooling_type: (building.utility?.coolingtype as string) || null,
      pool_type: (lot.pooltype as string) || null,
      garage_spaces: (building.parking?.garagetype as number) || 0,
      assessed_value: (assessment.assessed?.assdttlvalue as number) || null,
      last_sale_price: (saleHistory?.saleamt as number) || null,
      last_sale_date: (sale.salesearchdate as string) || null,
      elevation_ft: elevationFt,
      terrain_slope_pct: null,
      tree_coverage_pct: null,
      building_height_ft: structures[0]?.estimated_stories
        ? structures[0].estimated_stories * 10
        : null,
      data_sources: featureSources,
      raw_attom: attomData,
      raw_regrid: regridData,
      // NEW: enhanced property details from ATTOM or inferred
      basement_type: (building.interior?.bsmttype as string) || null,
      foundation_type: (building.construction?.foundationtype as string) || null,
      exterior_material: (building.construction?.wallType as string) || null,
      roof_material: (building.construction?.roofcover as string) || null,
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
      sources,
      structures: structures.map(s => ({
        type: s.structure_type, label: s.label,
        footprint_sqft: s.footprint_sqft, stories: s.estimated_stories,
        roof_area_sqft: s.estimated_roof_area_sqft, wall_area_sqft: s.estimated_wall_area_sqft,
      })),
      roof: roofMeasurementId ? {
        total_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
        facet_count: solarData?.solarPotential?.roofSegmentStats?.length || 0,
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

    const facetCount = solarData?.solarPotential?.roofSegmentStats?.length || 0
    if (facetCount > 12) complexityPenalty += 5
    if ((structures[0]?.estimated_stories || 1) > 2) complexityPenalty += 5

    // Bonus for multiple data sources
    if (sources.length >= 3) verificationBonus += 5

    // Bonus for flood + street view + census data
    if (floodZone) verificationBonus += 3
    if (streetViewUrl) verificationBonus += 2
    if (Object.keys(censusData).length > 0) verificationBonus += 3

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
        // NEW: Enhanced recon data
        storage_folder: storageFolder,
        street_view_url: streetViewUrl,
        external_links: externalLinks,
        property_type: propertyType,
        flood_zone: floodZone,
        flood_risk: floodRisk,
      })
      .eq('id', scanId)

    // Link to job if provided
    if (job_id) {
      await supabase.from('jobs').update({ property_scan_id: scanId }).eq('id', job_id)
    }

    // Auto-trigger roof calculator if we have a measurement
    if (roofMeasurementId) {
      try {
        await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/recon-roof-calculator`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ roof_measurement_id: roofMeasurementId }),
        })
      } catch {
        /* non-blocking */
      }
    }

    // Auto-trigger trade estimator to generate all 10 trade pipelines
    try {
      await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/recon-trade-estimator`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ scan_id: scanId }),
      })
    } catch {
      /* non-blocking — trade data can be generated on-demand */
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
    }, 200, origin)
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    console.error('[property-lookup] Error:', message)
    return jsonResponse({ error: message }, 500, origin)
  }
})
