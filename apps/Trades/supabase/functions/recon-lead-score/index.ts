// Supabase Edge Function: recon-lead-score
// Computes lead qualification score (0-100) and grade (hot/warm/cold)
// from available property data. Works with FREE data sources at launch,
// improves when ATTOM data is added.
//
// Scoring logic lives in _shared/lead-scoring.ts (single source of truth).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'
import { computeLeadScore } from '../_shared/lead-scoring.ts'

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

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return jsonResponse({ error: 'No company' }, 403, origin)
  }

  try {
    const body = await req.json()
    const { property_scan_id, area_scan_id } = body as {
      property_scan_id: string
      area_scan_id?: string
    }

    if (!property_scan_id) {
      return jsonResponse({ error: 'property_scan_id required' }, 400, origin)
    }

    // Load scan data
    const { data: scan, error: scanErr } = await supabase
      .from('property_scans')
      .select('*')
      .eq('id', property_scan_id)
      .eq('company_id', companyId)
      .single()

    if (scanErr || !scan) {
      return jsonResponse({ error: 'Scan not found' }, 404, origin)
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
    }, 200, origin)
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500, origin)
  }
})
