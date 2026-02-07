// Supabase Edge Function: xact-code-search
// Full-text search + browse for Xactimate codes.
// Supports: search by description, filter by category, browse all categories.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Auth verification
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  try {
    const url = new URL(req.url)
    const action = url.searchParams.get('action') || 'search'
    const query = url.searchParams.get('q') || ''
    const category = url.searchParams.get('category') || ''
    const regionCode = url.searchParams.get('region') || ''
    const limit = Math.min(Number(url.searchParams.get('limit') || 50), 200)
    const offset = Number(url.searchParams.get('offset') || 0)

    if (action === 'categories') {
      // Return all distinct categories
      const { data, error } = await supabase
        .from('xactimate_codes')
        .select('category_code, category_name')
        .eq('deprecated', false)
        .order('category_code')

      if (error) throw error

      // Deduplicate
      const seen = new Set<string>()
      const categories = (data || []).filter((c) => {
        if (seen.has(c.category_code)) return false
        seen.add(c.category_code)
        return true
      })

      return new Response(JSON.stringify({ categories }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (action === 'search') {
      let dbQuery = supabase
        .from('xactimate_codes')
        .select('*')
        .eq('deprecated', false)

      if (query) {
        // Full-text search on description + exact match on codes
        dbQuery = dbQuery.or(
          `description.ilike.%${query}%,full_code.ilike.%${query}%,category_code.ilike.%${query}%`
        )
      }

      if (category) {
        dbQuery = dbQuery.eq('category_code', category.toUpperCase())
      }

      const { data: codes, error } = await dbQuery
        .order('category_code')
        .order('selector_code')
        .range(offset, offset + limit - 1)

      if (error) throw error

      // If region code provided, also fetch pricing
      let pricing: Record<string, unknown>[] = []
      if (regionCode && codes && codes.length > 0) {
        const codeIds = codes.map((c: { id: string }) => c.id)
        const { data: priceData } = await supabase
          .from('pricing_entries')
          .select('code_id, material_cost, labor_cost, equipment_cost, total_cost, confidence, source_count')
          .in('code_id', codeIds)
          .eq('region_code', regionCode)
          .is('company_id', null)

        pricing = priceData || []
      }

      // Merge pricing into codes
      const pricingMap = new Map<string, unknown>()
      for (const p of pricing) {
        pricingMap.set(p.code_id as string, p)
      }

      const results = (codes || []).map((code: Record<string, unknown>) => ({
        ...code,
        pricing: pricingMap.get(code.id as string) || null,
      }))

      return new Response(JSON.stringify({
        codes: results,
        total: results.length,
        offset,
        limit,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (action === 'lookup') {
      // Get pricing for a specific code
      const codeId = url.searchParams.get('code_id')
      if (!codeId) {
        return new Response(JSON.stringify({ error: 'code_id required' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const { data: code, error: codeErr } = await supabase
        .from('xactimate_codes')
        .select('*')
        .eq('id', codeId)
        .single()

      if (codeErr) throw codeErr

      // Get pricing entries (global + company overrides)
      let pricingQuery = supabase
        .from('pricing_entries')
        .select('*')
        .eq('code_id', codeId)

      if (regionCode) {
        pricingQuery = pricingQuery.eq('region_code', regionCode)
      }

      const { data: pricing } = await pricingQuery.order('effective_date', { ascending: false })

      return new Response(JSON.stringify({
        code,
        pricing: pricing || [],
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ error: 'Unknown action. Use: search, categories, or lookup' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
