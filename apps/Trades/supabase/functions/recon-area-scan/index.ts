// Supabase Edge Function: recon-area-scan
// Batch area scanning — takes a polygon GeoJSON, finds parcels/structures
// within the area, queues property scans, and computes lead scores.
// Works with FREE data sources at launch (Microsoft Building Footprints).

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

// Simple point-in-polygon (ray casting)
function pointInPolygon(point: [number, number], polygon: [number, number][]): boolean {
  const [x, y] = point
  let inside = false
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const [xi, yi] = polygon[i]
    const [xj, yj] = polygon[j]
    if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) {
      inside = !inside
    }
  }
  return inside
}

// Calculate bounding box from polygon coordinates
function getBoundingBox(coords: [number, number][]): { south: number; west: number; north: number; east: number } {
  let south = 90, north = -90, west = 180, east = -180
  for (const [lng, lat] of coords) {
    if (lat < south) south = lat
    if (lat > north) north = lat
    if (lng < west) west = lng
    if (lng > east) east = lng
  }
  return { south, west, north, east }
}

// Fetch building footprints from Microsoft via Overpass API (FREE)
async function fetchBuildingsInBbox(bbox: { south: number; west: number; north: number; east: number }): Promise<Array<{ lat: number; lng: number; footprintSqft: number }>> {
  const { south, west, north, east } = bbox

  // Overpass query for buildings in bounding box
  const query = `[out:json][timeout:30];way["building"](${south},${west},${north},${east});out center;`

  try {
    const res = await fetch('https://overpass-api.de/api/interpreter', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `data=${encodeURIComponent(query)}`,
    })

    if (!res.ok) return []

    const data = await res.json()
    const buildings: Array<{ lat: number; lng: number; footprintSqft: number }> = []

    for (const element of (data.elements || [])) {
      if (element.center) {
        // Rough area estimate from tags or default
        const levels = Number(element.tags?.['building:levels']) || 1
        // Default footprint estimate if no area tag
        const areaSqm = Number(element.tags?.['building:area']) || 150 // ~1600 sqft default
        buildings.push({
          lat: element.center.lat,
          lng: element.center.lon,
          footprintSqft: Math.round(areaSqm * 10.764 * levels),
        })
      }
    }

    return buildings
  } catch {
    return []
  }
}

// Reverse geocode a coordinate to get an approximate address (FREE — Nominatim)
async function reverseGeocode(lat: number, lng: number): Promise<string | null> {
  try {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`,
      { headers: { 'User-Agent': 'Zafto-Recon/1.0' } }
    )
    if (!res.ok) return null
    const data = await res.json()
    return data.display_name || null
  } catch {
    return null
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
      name,
      scan_type,
      polygon_geojson,
      storm_event_id,
      storm_date,
      storm_type,
    } = body as {
      name?: string
      scan_type?: string
      polygon_geojson: { type: string; coordinates: number[][][] }
      storm_event_id?: string
      storm_date?: string
      storm_type?: string
    }

    if (!polygon_geojson?.coordinates?.[0]) {
      return jsonResponse({ error: 'polygon_geojson with coordinates required' }, 400)
    }

    const polygonCoords = polygon_geojson.coordinates[0] as [number, number][]

    // Create area_scan record
    const { data: areaScan, error: insertErr } = await supabase
      .from('area_scans')
      .insert({
        company_id: companyId,
        name: name || `Area Scan ${new Date().toISOString().split('T')[0]}`,
        scan_type: scan_type || 'prospecting',
        polygon_geojson,
        storm_event_id: storm_event_id || null,
        storm_date: storm_date || null,
        storm_type: storm_type || null,
        status: 'scanning',
        created_by: user.id,
      })
      .select('id')
      .single()

    if (insertErr || !areaScan) {
      return jsonResponse({ error: 'Failed to create area scan' }, 500)
    }

    const areaScanId = areaScan.id

    // Get bounding box and fetch buildings
    const bbox = getBoundingBox(polygonCoords)
    const buildings = await fetchBuildingsInBbox(bbox)

    // Filter buildings that are inside the polygon
    const insideBuildings = buildings.filter(b =>
      pointInPolygon([b.lng, b.lat], polygonCoords)
    )

    // Update total parcels
    await supabase
      .from('area_scans')
      .update({ total_parcels: insideBuildings.length })
      .eq('id', areaScanId)

    // Cap at 200 buildings per scan to avoid overloading
    const maxBuildings = 200
    const toScan = insideBuildings.slice(0, maxBuildings)

    let scannedCount = 0
    let hotCount = 0
    let warmCount = 0
    let coldCount = 0

    // Process each building — create property scans and score them
    for (const building of toScan) {
      try {
        // Reverse geocode for address
        const address = await reverseGeocode(building.lat, building.lng)
        if (!address) {
          scannedCount++
          continue
        }

        // Check if we already have a scan for this address
        const { data: existingScan } = await supabase
          .from('property_scans')
          .select('id')
          .eq('company_id', companyId)
          .eq('address', address)
          .is('deleted_at', null)
          .limit(1)
          .maybeSingle()

        let scanId: string

        if (existingScan) {
          scanId = existingScan.id
        } else {
          // Create a lightweight property scan record
          const { data: newScan, error: scanErr } = await supabase
            .from('property_scans')
            .insert({
              company_id: companyId,
              address,
              latitude: building.lat,
              longitude: building.lng,
              status: 'partial',
              scan_sources: ['overpass', 'nominatim'],
              confidence_score: 30,
              confidence_grade: 'low',
              confidence_factors: { source: 'area_scan', footprint_estimated: true },
            })
            .select('id')
            .single()

          if (scanErr || !newScan) {
            scannedCount++
            continue
          }
          scanId = newScan.id

          // Insert structure record
          await supabase
            .from('property_structures')
            .insert({
              property_scan_id: scanId,
              structure_type: 'primary',
              footprint_sqft: building.footprintSqft,
              estimated_stories: 1,
              data_source: 'overpass',
            })
        }

        // Compute lead score via the lead scoring function
        // Instead of calling the EF, compute inline (faster for batch)
        const { data: roof } = await supabase
          .from('roof_measurements')
          .select('total_area_sqft, facet_count')
          .eq('scan_id', scanId)
          .limit(1)
          .maybeSingle()

        const { data: features } = await supabase
          .from('property_features')
          .select('year_built, assessed_value, last_sale_date, stories, elevation_ft')
          .eq('scan_id', scanId)
          .limit(1)
          .maybeSingle()

        const { data: structure } = await supabase
          .from('property_structures')
          .select('footprint_sqft, estimated_stories')
          .eq('property_scan_id', scanId)
          .eq('structure_type', 'primary')
          .limit(1)
          .maybeSingle()

        const roofArea = Number(roof?.total_area_sqft) || 0
        const facetCount = Number(roof?.facet_count) || 0
        const footprint = Number(structure?.footprint_sqft) || building.footprintSqft
        const elevation = features?.elevation_ft != null ? Number(features.elevation_ft) : null
        const yearBuilt = features?.year_built != null ? Number(features.year_built) : null
        const assessedValue = features?.assessed_value != null ? Number(features.assessed_value) : null
        const lastSaleDate = features?.last_sale_date as string | null
        const stories = Number(features?.stories || structure?.estimated_stories) || 1
        const sources = ['overpass']

        // Inline lead score computation (mirrors recon-lead-score)
        const currentYear = new Date().getFullYear()

        let roofAreaScore = 0
        if (roofArea > 5000) roofAreaScore = 20
        else if (roofArea > 3000) roofAreaScore = 15
        else if (roofArea > 2000) roofAreaScore = 12
        else if (roofArea > 1000) roofAreaScore = 8
        else if (roofArea > 0) roofAreaScore = 5

        let roofComplexityScore = 0
        if (facetCount > 12) roofComplexityScore = 10
        else if (facetCount > 8) roofComplexityScore = 8
        else if (facetCount > 4) roofComplexityScore = 5
        else if (facetCount > 0) roofComplexityScore = 3

        let buildingSizeScore = 0
        if (footprint > 3000) buildingSizeScore = 10
        else if (footprint > 2000) buildingSizeScore = 8
        else if (footprint > 1000) buildingSizeScore = 5
        else if (footprint > 0) buildingSizeScore = 3

        const elevationScore = elevation && elevation > 2000 ? 3 : 0
        const conditionScore = stories > 2 ? 5 : stories > 1 ? 3 : 0

        let roofAgeScore = 0
        if (yearBuilt) {
          const age = currentYear - yearBuilt
          if (age > 25) roofAgeScore = 25
          else if (age > 20) roofAgeScore = 20
          else if (age > 15) roofAgeScore = 15
          else if (age > 10) roofAgeScore = 8
          else roofAgeScore = 3
        }

        let propertyValueScore = 0
        if (assessedValue) {
          if (assessedValue > 500000) propertyValueScore = 15
          else if (assessedValue > 300000) propertyValueScore = 12
          else if (assessedValue > 200000) propertyValueScore = 10
          else if (assessedValue > 100000) propertyValueScore = 7
          else propertyValueScore = 4
        }

        let ownerTenureScore = 0
        if (lastSaleDate) {
          const saleYear = new Date(lastSaleDate).getFullYear()
          const tenure = currentYear - saleYear
          if (tenure > 15) ownerTenureScore = 10
          else if (tenure > 10) ownerTenureScore = 8
          else if (tenure > 5) ownerTenureScore = 5
          else ownerTenureScore = 2
        }

        const hasAttom = sources.includes('attom')
        let totalScore = 0
        if (hasAttom) {
          totalScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
            elevationScore + roofAgeScore + propertyValueScore + ownerTenureScore + conditionScore
        } else {
          const freeScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
            elevationScore + conditionScore
          totalScore = Math.round(freeScore * 1.4)
        }
        totalScore = Math.min(100, Math.max(0, totalScore))
        const grade = totalScore >= 70 ? 'hot' : totalScore >= 40 ? 'warm' : 'cold'

        if (grade === 'hot') hotCount++
        else if (grade === 'warm') warmCount++
        else coldCount++

        // Upsert lead score
        const { data: existingScore } = await supabase
          .from('property_lead_scores')
          .select('id')
          .eq('property_scan_id', scanId)
          .eq('company_id', companyId)
          .limit(1)
          .maybeSingle()

        const scoreRow = {
          property_scan_id: scanId,
          company_id: companyId,
          area_scan_id: areaScanId,
          overall_score: totalScore,
          grade,
          roof_age_score: roofAgeScore,
          property_value_score: propertyValueScore,
          owner_tenure_score: ownerTenureScore,
          condition_score: conditionScore,
          permit_score: 0,
          storm_damage_probability: 0,
          scoring_factors: {
            roof_area_score: roofAreaScore,
            roof_complexity_score: roofComplexityScore,
            building_size_score: buildingSizeScore,
            storm_proximity_score: 0,
            elevation_score: elevationScore,
            roof_age_score: roofAgeScore,
            property_value_score: propertyValueScore,
            owner_tenure_score: ownerTenureScore,
            condition_score: conditionScore,
            data_confidence: 'basic',
            sources_used: sources,
          },
        }

        if (existingScore) {
          await supabase.from('property_lead_scores').update(scoreRow).eq('id', existingScore.id)
        } else {
          await supabase.from('property_lead_scores').insert(scoreRow)
        }

        scannedCount++

        // Update progress every 10 buildings
        if (scannedCount % 10 === 0) {
          await supabase
            .from('area_scans')
            .update({
              scanned_parcels: scannedCount,
              hot_leads: hotCount,
              warm_leads: warmCount,
              cold_leads: coldCount,
            })
            .eq('id', areaScanId)
        }

        // Throttle Nominatim requests (1 per second policy)
        if (!existingScan) {
          await new Promise(resolve => setTimeout(resolve, 1100))
        }
      } catch {
        scannedCount++
        // Skip individual failures, continue batch
      }
    }

    // Final update
    await supabase
      .from('area_scans')
      .update({
        status: 'complete',
        scanned_parcels: scannedCount,
        hot_leads: hotCount,
        warm_leads: warmCount,
        cold_leads: coldCount,
      })
      .eq('id', areaScanId)

    return jsonResponse({
      area_scan_id: areaScanId,
      total_parcels: insideBuildings.length,
      scanned: scannedCount,
      hot_leads: hotCount,
      warm_leads: warmCount,
      cold_leads: coldCount,
      status: 'complete',
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
