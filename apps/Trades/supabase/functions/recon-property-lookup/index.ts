// Supabase Edge Function: recon-property-lookup
// Full property intelligence pipeline:
// 1. Geocode address → lat/lng
// 2. Google Solar API → roof segments, measurements, facets
// 3. Microsoft Building Footprints (FREE) → multi-structure detection
// 4. USGS 3DEP Elevation (FREE) → elevation, terrain data
// 5. ATTOM API (GATED) → property characteristics, sale history
// 6. Regrid API (GATED) → parcel boundaries, zoning, APN
// 7. Confidence scoring → grade + factors
// Inserts: property_scans, roof_measurements, roof_facets,
//          property_structures, property_features, parcel_boundaries

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const SQM_TO_SQFT = 10.764
const CACHE_DAYS = 30

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

// Helper: JSON response
function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
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
    // CHECK CACHE (30-day)
    // ========================================================================
    const { data: cached } = await supabase
      .from('property_scans')
      .select('id, cached_until')
      .eq('company_id', companyId)
      .eq('address', address)
      .gt('cached_until', new Date().toISOString())
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cached) {
      return jsonResponse({ scan_id: cached.id, cached: true })
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

    if (scanErr) throw scanErr

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
      if (googleKey) {
        try {
          const geoRes = await fetch(
            `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${googleKey}`
          )
          const geoData = await geoRes.json()
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
        } catch {
          /* geocode failed, continue */
        }
      }
    }

    if (!lat || !lng) {
      await supabase
        .from('property_scans')
        .update({ status: 'failed', error_message: 'Could not geocode address' })
        .eq('id', scanId)

      return jsonResponse({ error: 'Could not geocode address', scan_id: scanId }, 422)
    }

    // ========================================================================
    // STEP 2: GOOGLE SOLAR API
    // ========================================================================
    const solarKey = Deno.env.get('GOOGLE_SOLAR_API_KEY') || Deno.env.get('GOOGLE_CLOUD_API_KEY')
    let solarData: SolarResponse | null = null
    let imageryDate: Date | null = null
    let roofMeasurementId: string | null = null
    let totalRoofAreaSqft = 0

    if (solarKey) {
      try {
        const solarRes = await fetch(
          `https://solar.googleapis.com/v1/buildingInsights:findClosest?location.latitude=${lat}&location.longitude=${lng}&requiredQuality=HIGH&key=${solarKey}`
        )

        if (solarRes.ok) {
          solarData = await solarRes.json()
          sources.push('google_solar')

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

            const { data: rm } = await supabase
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

            if (rm) {
              roofMeasurementId = rm.id
              const facetRows = facets.map((f) => ({
                roof_measurement_id: rm.id,
                ...f,
              }))
              await supabase.from('roof_facets').insert(facetRows)
            }
          }
        }
      } catch {
        /* solar failed, continue with other sources */
      }
    }

    // ========================================================================
    // STEP 3: USGS 3DEP ELEVATION (FREE)
    // ========================================================================
    try {
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
    } catch {
      /* Footprints failed, non-critical */
    }

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
      try {
        const attomRes = await fetch(
          `https://api.gateway.attomdata.com/propertyapi/v1.0.0/property/expandedprofile?address1=${encodeURIComponent(address)}&address2=`,
          {
            headers: { apikey: attomKey, Accept: 'application/json' },
          }
        )

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

    // ========================================================================
    // STEP 6: REGRID API (GATED — only if REGRID_API_KEY exists)
    // ========================================================================
    let regridData: Record<string, unknown> | null = null
    const regridKey = Deno.env.get('REGRID_API_KEY')

    if (regridKey) {
      try {
        const regridRes = await fetch(
          `https://app.regrid.com/api/v1/search.json?query=${encodeURIComponent(address)}&token=${regridKey}`
        )

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
    })

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

    return jsonResponse({
      scan_id: scanId,
      status: finalStatus,
      confidence_score: confidence,
      confidence_grade: grade,
      sources,
      structure_count: structures.length,
      roof_area_sqft: Math.round(totalRoofAreaSqft * 100) / 100,
      imagery_date: imageryDate?.toISOString().split('T')[0] || null,
      elevation_ft: elevationFt,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
