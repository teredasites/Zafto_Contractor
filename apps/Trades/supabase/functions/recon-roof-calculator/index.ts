// Supabase Edge Function: recon-roof-calculator
// Accepts roof_measurement_id → calculate edge lengths from facet geometry
// → calculate total edges (ridge, hip, valley, eave, rake)
// → update roof_measurements → calculate complexity score

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse } from '../_shared/cors.ts'

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
    return jsonResponse({ error: 'Missing authorization' }, 401, origin)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401, origin)
  }

  try {
    const body = await req.json()
    const { roof_measurement_id } = body as { roof_measurement_id: string }

    if (!roof_measurement_id) {
      return jsonResponse({ error: 'roof_measurement_id required' }, 400, origin)
    }

    // Get measurement + verify company access via inner join
    const { data: measurement, error: mErr } = await supabase
      .from('roof_measurements')
      .select('*, property_scans!inner(company_id)')
      .eq('id', roof_measurement_id)
      .single()

    if (mErr || !measurement) {
      console.error('[roof-calculator] Measurement not found:', { roof_measurement_id, error: mErr?.message })
      return jsonResponse({ error: 'Measurement not found', detail: mErr?.message }, 404, origin)
    }

    // Verify company access
    const companyId = user.app_metadata?.company_id
    if (measurement.property_scans?.company_id !== companyId) {
      return jsonResponse({ error: 'Access denied' }, 403, origin)
    }

    const { data: facets } = await supabase
      .from('roof_facets')
      .select('*')
      .eq('roof_measurement_id', roof_measurement_id)
      .order('facet_number')

    const facetList = facets || []
    const totalArea = measurement.total_area_sqft || 0
    const facetCount = facetList.length

    // P-FIX1: Log diagnostic data for roof bug investigation
    console.log('[roof-calculator] Input data:', {
      roof_measurement_id,
      totalArea,
      facetCount,
      shape: measurement.predominant_shape,
      pitch: measurement.pitch_degrees,
      penetrations: measurement.penetration_count,
    })

    if (totalArea === 0) {
      console.warn('[roof-calculator] total_area_sqft is 0 — all edge calculations will be 0')
    }

    // Estimate edge lengths from roof geometry
    // Using industry estimation formulas based on roof area and shape
    const shape = measurement.predominant_shape || 'gable'
    const avgPitch = measurement.pitch_degrees || 20

    // Approximate building footprint from roof area and pitch
    const pitchRad = avgPitch * Math.PI / 180
    const pitchFactor = 1 / Math.cos(pitchRad)
    const footprintArea = totalArea / pitchFactor
    const footprintSide = Math.sqrt(footprintArea)

    let ridgeLength = 0
    let hipLength = 0
    let valleyLength = 0
    let eaveLength = 0
    let rakeLength = 0

    switch (shape) {
      case 'gable':
        // Simple gable: ridge = length, eaves = 2 × length, rakes = 4 × rafter length
        ridgeLength = footprintSide * 1.2  // slightly longer
        eaveLength = footprintSide * 2.4
        rakeLength = footprintSide * 2 / Math.cos(pitchRad)
        break

      case 'hip':
        // Hip roof: ridges + hips, no rakes, eaves all around
        ridgeLength = footprintSide * 0.6
        hipLength = footprintSide * 2.8 / Math.cos(pitchRad)
        eaveLength = footprintSide * 4
        break

      case 'flat':
        eaveLength = footprintSide * 4
        break

      case 'gambrel':
        ridgeLength = footprintSide * 1.2
        eaveLength = footprintSide * 2.4
        rakeLength = footprintSide * 3 / Math.cos(pitchRad)
        break

      case 'mansard':
        ridgeLength = footprintSide * 0.4
        hipLength = footprintSide * 1.6
        eaveLength = footprintSide * 4
        break

      default: // mixed
        ridgeLength = footprintSide * 0.8
        hipLength = footprintSide * 1.5
        valleyLength = footprintSide * 0.6
        eaveLength = footprintSide * 3.5
        rakeLength = footprintSide * 1.0
        break
    }

    // Add valleys based on facet count (more facets = more intersections)
    if (facetCount > 4) {
      valleyLength += (facetCount - 4) * footprintSide * 0.3
    }

    // Complexity score (1-10)
    let complexity = 1
    complexity += Math.min(3, facetCount * 0.3)
    complexity += valleyLength > 0 ? 1.5 : 0
    complexity += hipLength > footprintSide * 2 ? 1 : 0
    complexity += measurement.penetration_count > 3 ? 1 : 0
    complexity += avgPitch > 35 ? 1 : 0
    complexity = Math.min(10, Math.round(complexity * 10) / 10)

    // Round all values
    const round = (n: number) => Math.round(n * 100) / 100

    const { error: updateErr } = await supabase
      .from('roof_measurements')
      .update({
        ridge_length_ft: round(ridgeLength),
        hip_length_ft: round(hipLength),
        valley_length_ft: round(valleyLength),
        eave_length_ft: round(eaveLength),
        rake_length_ft: round(rakeLength),
        complexity_score: complexity,
      })
      .eq('id', roof_measurement_id)

    if (updateErr) throw updateErr

    return jsonResponse({
      roof_measurement_id,
      edges: {
        ridge_ft: round(ridgeLength),
        hip_ft: round(hipLength),
        valley_ft: round(valleyLength),
        eave_ft: round(eaveLength),
        rake_ft: round(rakeLength),
      },
      complexity_score: complexity,
      shape,
      total_edge_ft: round(ridgeLength + hipLength + valleyLength + eaveLength + rakeLength),
    }, 200, origin)
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    console.error('[roof-calculator] Error:', message)
    return jsonResponse({ error: message }, 500, origin)
  }
})
