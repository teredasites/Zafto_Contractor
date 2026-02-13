// Supabase Edge Function: recon-lead-score
// Computes lead qualification score (0-100) and grade (hot/warm/cold)
// from available property data. Works with FREE data sources at launch,
// improves when ATTOM data is added.
//
// FREE signals: roof_area, roof_complexity, building_footprint, storm_proximity, elevation
// ATTOM-enhanced: year_built, assessed_value, owner_tenure, construction_type, permit_history

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

interface ScoreFactors {
  roof_area_score: number
  roof_complexity_score: number
  building_size_score: number
  storm_proximity_score: number
  elevation_score: number
  roof_age_score: number
  property_value_score: number
  owner_tenure_score: number
  condition_score: number
  data_confidence: string
  sources_used: string[]
}

function computeLeadScore(
  roofAreaSqft: number,
  facetCount: number,
  footprintSqft: number,
  elevationFt: number | null,
  yearBuilt: number | null,
  assessedValue: number | null,
  lastSaleDate: string | null,
  stories: number,
  sources: string[],
): { score: number; grade: string; factors: ScoreFactors } {
  const currentYear = new Date().getFullYear()

  // ── FREE SIGNALS ──

  // Roof area: larger roof = larger job value (0-20)
  let roofAreaScore = 0
  if (roofAreaSqft > 5000) roofAreaScore = 20
  else if (roofAreaSqft > 3000) roofAreaScore = 15
  else if (roofAreaSqft > 2000) roofAreaScore = 12
  else if (roofAreaSqft > 1000) roofAreaScore = 8
  else if (roofAreaSqft > 0) roofAreaScore = 5

  // Roof complexity: more facets = higher price per square (0-10)
  let roofComplexityScore = 0
  if (facetCount > 12) roofComplexityScore = 10
  else if (facetCount > 8) roofComplexityScore = 8
  else if (facetCount > 4) roofComplexityScore = 5
  else if (facetCount > 0) roofComplexityScore = 3

  // Building size: larger building = more exterior work (0-10)
  let buildingSizeScore = 0
  if (footprintSqft > 3000) buildingSizeScore = 10
  else if (footprintSqft > 2000) buildingSizeScore = 8
  else if (footprintSqft > 1000) buildingSizeScore = 5
  else if (footprintSqft > 0) buildingSizeScore = 3

  // Elevation/slope: steep terrain adds complexity (0-5)
  const elevationScore = elevationFt && elevationFt > 2000 ? 3 : 0

  // Storm proximity placeholder: 0 (NOAA cross-reference in P9)
  const stormProximityScore = 0

  // ── ATTOM-ENHANCED SIGNALS ──

  // Roof age: older roof = more likely needs replacement (0-25)
  let roofAgeScore = 0
  if (yearBuilt) {
    const age = currentYear - yearBuilt
    if (age > 25) roofAgeScore = 25
    else if (age > 20) roofAgeScore = 20
    else if (age > 15) roofAgeScore = 15
    else if (age > 10) roofAgeScore = 8
    else roofAgeScore = 3
  }

  // Property value: higher value = larger budget (0-15)
  let propertyValueScore = 0
  if (assessedValue) {
    if (assessedValue > 500000) propertyValueScore = 15
    else if (assessedValue > 300000) propertyValueScore = 12
    else if (assessedValue > 200000) propertyValueScore = 10
    else if (assessedValue > 100000) propertyValueScore = 7
    else propertyValueScore = 4
  }

  // Owner tenure: longer tenure = more equity, invest-ready (0-10)
  let ownerTenureScore = 0
  if (lastSaleDate) {
    const saleYear = new Date(lastSaleDate).getFullYear()
    const tenure = currentYear - saleYear
    if (tenure > 15) ownerTenureScore = 10
    else if (tenure > 10) ownerTenureScore = 8
    else if (tenure > 5) ownerTenureScore = 5
    else ownerTenureScore = 2
  }

  // Condition score from stories (multi-story = larger exterior)
  const conditionScore = stories > 2 ? 5 : stories > 1 ? 3 : 0

  // ── OVERALL CALCULATION ──

  // Weights depend on which data sources are available
  const hasAttom = sources.includes('attom')

  let totalScore = 0
  if (hasAttom) {
    // Full score with all data
    totalScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
      stormProximityScore + elevationScore + roofAgeScore +
      propertyValueScore + ownerTenureScore + conditionScore
  } else {
    // Basic score with free data only — scale up proportionally
    const freeScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
      stormProximityScore + elevationScore + conditionScore
    // Free signals max ~48 points, scale to ~65 max (basic score ceiling)
    totalScore = Math.round(freeScore * 1.4)
  }

  totalScore = Math.min(100, Math.max(0, totalScore))

  const grade = totalScore >= 70 ? 'hot' : totalScore >= 40 ? 'warm' : 'cold'

  return {
    score: totalScore,
    grade,
    factors: {
      roof_area_score: roofAreaScore,
      roof_complexity_score: roofComplexityScore,
      building_size_score: buildingSizeScore,
      storm_proximity_score: stormProximityScore,
      elevation_score: elevationScore,
      roof_age_score: roofAgeScore,
      property_value_score: propertyValueScore,
      owner_tenure_score: ownerTenureScore,
      condition_score: conditionScore,
      data_confidence: hasAttom ? 'full' : 'basic',
      sources_used: sources,
    },
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
    const { property_scan_id, area_scan_id } = body as {
      property_scan_id: string
      area_scan_id?: string
    }

    if (!property_scan_id) {
      return jsonResponse({ error: 'property_scan_id required' }, 400)
    }

    // Load scan data
    const { data: scan, error: scanErr } = await supabase
      .from('property_scans')
      .select('*')
      .eq('id', property_scan_id)
      .eq('company_id', companyId)
      .single()

    if (scanErr || !scan) {
      return jsonResponse({ error: 'Scan not found' }, 404)
    }

    // Load roof measurement
    const { data: roof } = await supabase
      .from('roof_measurements')
      .select('total_area_sqft, facet_count')
      .eq('scan_id', property_scan_id)
      .limit(1)
      .maybeSingle()

    // Load property features
    const { data: features } = await supabase
      .from('property_features')
      .select('year_built, assessed_value, last_sale_date, stories, elevation_ft')
      .eq('scan_id', property_scan_id)
      .limit(1)
      .maybeSingle()

    // Load primary structure
    const { data: structure } = await supabase
      .from('property_structures')
      .select('footprint_sqft, estimated_stories')
      .eq('property_scan_id', property_scan_id)
      .eq('structure_type', 'primary')
      .limit(1)
      .maybeSingle()

    const roofArea = Number(roof?.total_area_sqft) || 0
    const facetCount = Number(roof?.facet_count) || 0
    const footprint = Number(structure?.footprint_sqft) || 0
    const elevation = features?.elevation_ft != null ? Number(features.elevation_ft) : null
    const yearBuilt = features?.year_built != null ? Number(features.year_built) : null
    const assessedValue = features?.assessed_value != null ? Number(features.assessed_value) : null
    const lastSaleDate = features?.last_sale_date as string | null
    const stories = Number(features?.stories || structure?.estimated_stories) || 1
    const sources = (scan.scan_sources as string[]) || []

    const { score, grade, factors } = computeLeadScore(
      roofArea, facetCount, footprint, elevation,
      yearBuilt, assessedValue, lastSaleDate, stories, sources
    )

    // Upsert lead score
    const { data: existing } = await supabase
      .from('property_lead_scores')
      .select('id')
      .eq('property_scan_id', property_scan_id)
      .eq('company_id', companyId)
      .limit(1)
      .maybeSingle()

    const row = {
      property_scan_id,
      company_id: companyId,
      area_scan_id: area_scan_id || null,
      overall_score: score,
      grade,
      roof_age_score: factors.roof_age_score,
      property_value_score: factors.property_value_score,
      owner_tenure_score: factors.owner_tenure_score,
      condition_score: factors.condition_score,
      permit_score: 0,
      storm_damage_probability: 0,
      scoring_factors: factors,
    }

    if (existing) {
      await supabase.from('property_lead_scores').update(row).eq('id', existing.id)
    } else {
      await supabase.from('property_lead_scores').insert(row)
    }

    return jsonResponse({
      property_scan_id,
      score,
      grade,
      factors,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
