// Supabase Edge Function: pricing-ingest
// D8i — Pricing Engine Foundation
// Handles: BLS data ingestion, FEMA equipment rates, pricing lookup, coverage stats
// Sources: BLS API v2 (OES + PPI), FEMA Equipment Rate Schedule

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// BLS OES Series ID format: OE + U + M/N + AREA(7) + INDUSTRY(6) + SOC(6) + DATATYPE(2)
// Datatype 03 = hourly mean wage, 04 = annual mean wage
const BLS_TRADES: Record<string, { soc: string; zaftoTrades: string[] }> = {
  electricians:    { soc: '472111', zaftoTrades: ['ELE', 'ELS'] },
  plumbers:        { soc: '472152', zaftoTrades: ['PLM'] },
  hvac:            { soc: '499021', zaftoTrades: ['HVC'] },
  roofers:         { soc: '472181', zaftoTrades: ['RFG'] },
  carpenters:      { soc: '472031', zaftoTrades: ['FRM', 'CAB', 'FNC'] },
  painters:        { soc: '472141', zaftoTrades: ['PNT', 'WPR'] },
  drywall:         { soc: '472081', zaftoTrades: ['DRY'] },
  tile_setters:    { soc: '472044', zaftoTrades: ['TIL', 'FCT'] },
  floor_layers:    { soc: '472042', zaftoTrades: ['FCV', 'FCW', 'FCC', 'FCR'] },
  laborers:        { soc: '472061', zaftoTrades: ['DMO', 'CLN', 'LAB'] },
  insulation:      { soc: '472131', zaftoTrades: ['INS'] },
  masons:          { soc: '472021', zaftoTrades: ['MAS', 'CNC'] },
  glaziers:        { soc: '472121', zaftoTrades: ['GLS', 'WDW'] },
}

// BLS PPI series for material cost tracking
const PPI_SERIES: Record<string, string> = {
  softwood_lumber: 'WPU0811',
  steel:           'WPU1017',
  copper:          'WPU1022',
  wire_cable:      'WPU1026',
  concrete:        'WPU1333',
  gypsum_drywall:  'WPU137',
  insulation:      'WPU1392',
  plywood:         'WPU0831',
}

// Top MSAs for BLS queries (CBSA codes)
const MAJOR_MSAS = [
  { cbsa: '0000000', areaType: 'N', label: 'National' },
  { cbsa: '0035620', areaType: 'M', label: 'New York' },
  { cbsa: '0031080', areaType: 'M', label: 'Los Angeles' },
  { cbsa: '0016980', areaType: 'M', label: 'Chicago' },
  { cbsa: '0019100', areaType: 'M', label: 'Dallas' },
  { cbsa: '0026420', areaType: 'M', label: 'Houston' },
  { cbsa: '0033100', areaType: 'M', label: 'Miami' },
  { cbsa: '0012060', areaType: 'M', label: 'Atlanta' },
  { cbsa: '0038060', areaType: 'M', label: 'Phoenix' },
  { cbsa: '0042660', areaType: 'M', label: 'Seattle' },
  { cbsa: '0019740', areaType: 'M', label: 'Denver' },
  { cbsa: '0036740', areaType: 'M', label: 'Orlando' },
]

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // ── GET: Coverage stats ──
    if (req.method === 'GET') {
      const url = new URL(req.url)
      const action = url.searchParams.get('action') || 'stats'

      if (action === 'stats') {
        // Count items with pricing
        const { count: totalItems } = await supabase
          .from('estimate_items')
          .select('*', { count: 'exact', head: true })
          .eq('source', 'zafto')

        const { count: pricedItems } = await supabase
          .from('estimate_pricing')
          .select('*', { count: 'exact', head: true })
          .eq('region_code', 'NATIONAL')
          .is('company_id', null)

        // Count distinct regions
        const { data: regions } = await supabase
          .from('estimate_pricing')
          .select('region_code')
          .is('company_id', null)

        const uniqueRegions = new Set((regions || []).map((r: { region_code: string }) => r.region_code))

        // Get freshness
        const { data: latest } = await supabase
          .from('estimate_pricing')
          .select('effective_date')
          .is('company_id', null)
          .order('effective_date', { ascending: false })
          .limit(1)

        // MSA coverage
        const { data: msaData } = await supabase
          .from('msa_regions')
          .select('cbsa_code, name, cost_index')
          .order('name')

        const msaCoverage = await Promise.all(
          (msaData || []).map(async (msa: { cbsa_code: string; name: string; cost_index: number }) => {
            const { count } = await supabase
              .from('estimate_pricing')
              .select('*', { count: 'exact', head: true })
              .eq('region_code', msa.cbsa_code)
              .is('company_id', null)
            return { ...msa, itemCount: count || 0 }
          })
        )

        return new Response(JSON.stringify({
          totalItems: totalItems || 0,
          pricedItems: pricedItems || 0,
          coveragePct: totalItems ? Math.round(((pricedItems || 0) / totalItems) * 100) : 0,
          regions: uniqueRegions.size,
          latestDate: latest?.[0]?.effective_date || null,
          msaCoverage,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Lookup pricing by ZIP
      if (action === 'lookup') {
        const zip = url.searchParams.get('zip')
        const itemId = url.searchParams.get('item_id')
        const companyId = url.searchParams.get('company_id')

        if (!zip || !itemId) {
          return new Response(JSON.stringify({ error: 'zip and item_id required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        // ZIP → MSA lookup
        const { data: msaResult } = await supabase.rpc('fn_zip_to_msa', { zip })
        const region = msaResult?.[0] || { cbsa_code: 'NATIONAL', region_name: 'National Average', cost_index: 1.0 }

        // Get pricing with fallback
        const { data: pricing } = await supabase.rpc('fn_get_item_pricing', {
          p_item_id: itemId,
          p_region_code: region.cbsa_code,
          p_company_id: companyId || null,
        })

        return new Response(JSON.stringify({
          region,
          pricing: pricing?.[0] || null,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      return new Response(JSON.stringify({ error: 'Unknown action' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── POST: Ingestion actions ──
    if (req.method === 'POST') {
      const body = await req.json()
      const { action } = body

      // Auth check — admin only for ingestion
      const authHeader = req.headers.get('authorization')
      if (!authHeader) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const token = authHeader.replace('Bearer ', '')
      const { data: { user }, error: authError } = await supabase.auth.getUser(token)
      if (authError || !user) {
        return new Response(JSON.stringify({ error: 'Invalid token' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Check super_admin role
      const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single()

      if (profile?.role !== 'super_admin') {
        return new Response(JSON.stringify({ error: 'super_admin required' }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // ── BLS Labor Rate Ingestion ──
      if (action === 'ingest-bls') {
        const blsKey = Deno.env.get('BLS_API_KEY')
        if (!blsKey) {
          return new Response(JSON.stringify({
            error: 'BLS_API_KEY not configured',
            help: 'Register at https://data.bls.gov/registrationEngine/ and set as Supabase secret',
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        let totalInserted = 0
        const errors: string[] = []

        // Build series IDs for all trades × all MSAs × hourly mean wage (datatype 03)
        for (const msa of MAJOR_MSAS) {
          const seriesIds: string[] = []
          const seriesTradeMap: Record<string, string[]> = {}

          for (const [tradeName, tradeConfig] of Object.entries(BLS_TRADES)) {
            const seriesId = `OEU${msa.areaType}${msa.cbsa}000000${tradeConfig.soc}03`
            seriesIds.push(seriesId)
            seriesTradeMap[seriesId] = tradeConfig.zaftoTrades
          }

          // BLS API v2 — max 50 series per request
          try {
            const blsResp = await fetch(
              `https://api.bls.gov/publicAPI/v2/timeseries/data/?registrationkey=${blsKey}`,
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  seriesid: seriesIds,
                  startyear: '2023',
                  endyear: '2025',
                  annualaverage: true,
                }),
              }
            )

            const blsData = await blsResp.json()

            if (blsData.status !== 'REQUEST_SUCCEEDED') {
              errors.push(`BLS error for ${msa.label}: ${blsData.message?.join(', ') || 'Unknown'}`)
              continue
            }

            for (const series of blsData.Results?.series || []) {
              const zaftoTrades = seriesTradeMap[series.seriesID]
              if (!zaftoTrades) continue

              // Get most recent annual average
              const annualData = series.data?.find(
                (d: { period: string }) => d.period === 'A01'
              )
              if (!annualData?.value) continue

              const hourlyWage = parseFloat(annualData.value)
              if (isNaN(hourlyWage) || hourlyWage <= 0) continue

              const regionCode = msa.areaType === 'N' ? 'NATIONAL' : msa.cbsa.replace(/^0+/, '')

              // Update estimate_labor_components for matching trades
              for (const trade of zaftoTrades) {
                const { error: updateError } = await supabase
                  .from('estimate_labor_components')
                  .update({
                    base_rate: hourlyWage,
                    source: 'bls',
                  })
                  .eq('trade', trade)
                  .ilike('code', `${trade}-BASE`)

                if (!updateError) totalInserted++
              }
            }
          } catch (e) {
            errors.push(`BLS fetch failed for ${msa.label}: ${(e as Error).message}`)
          }
        }

        return new Response(JSON.stringify({
          success: true,
          action: 'ingest-bls',
          updated: totalInserted,
          errors: errors.length > 0 ? errors : undefined,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // ── FEMA Equipment Rate Ingestion ──
      if (action === 'ingest-fema') {
        const { rates } = body // expects { rates: [{ code, description, specification, unit, rate, hp }] }

        if (!Array.isArray(rates) || rates.length === 0) {
          return new Response(JSON.stringify({
            error: 'rates array required',
            help: 'Parse FEMA PDF and send as JSON array: { code, description, specification, unit, rate, hp }',
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        // Find equipment-category estimate items and update pricing
        let updated = 0
        for (const femaRate of rates) {
          // Try to match to existing equipment items by description similarity
          const { data: items } = await supabase
            .from('estimate_items')
            .select('id')
            .eq('source', 'zafto')
            .ilike('description', `%${femaRate.description?.split(' ').slice(0, 2).join('%')}%`)
            .limit(1)

          if (items && items.length > 0) {
            const { error } = await supabase
              .from('estimate_pricing')
              .upsert({
                item_id: items[0].id,
                region_code: 'NATIONAL',
                labor_rate: 0,
                material_cost: 0,
                equipment_cost: parseFloat(femaRate.rate) || 0,
                effective_date: new Date().toISOString().split('T')[0],
                source: 'fema',
                confidence: 'high',
                sample_count: 1,
              }, {
                onConflict: 'item_id,region_code,effective_date',
              })

            if (!error) updated++
          }
        }

        return new Response(JSON.stringify({
          success: true,
          action: 'ingest-fema',
          received: rates.length,
          matched: updated,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // ── BLS PPI Material Index Fetch ──
      if (action === 'ingest-ppi') {
        const blsKey = Deno.env.get('BLS_API_KEY')
        if (!blsKey) {
          return new Response(JSON.stringify({
            error: 'BLS_API_KEY not configured',
          }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const seriesIds = Object.values(PPI_SERIES)

        try {
          const blsResp = await fetch(
            `https://api.bls.gov/publicAPI/v2/timeseries/data/?registrationkey=${blsKey}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                seriesid: seriesIds,
                startyear: '2023',
                endyear: '2025',
                calculations: true,
              }),
            }
          )

          const blsData = await blsResp.json()
          const indices: Record<string, { latest: number; yearChange: number }> = {}

          if (blsData.status === 'REQUEST_SUCCEEDED') {
            for (const series of blsData.Results?.series || []) {
              const name = Object.entries(PPI_SERIES).find(
                ([, id]) => id === series.seriesID
              )?.[0]
              if (!name) continue

              const latestData = series.data?.[0]
              if (latestData?.value) {
                indices[name] = {
                  latest: parseFloat(latestData.value),
                  yearChange: latestData.calculations?.pct_changes?.['12']
                    ? parseFloat(latestData.calculations.pct_changes['12'])
                    : 0,
                }
              }
            }
          }

          return new Response(JSON.stringify({
            success: true,
            action: 'ingest-ppi',
            indices,
            note: 'PPI indices stored for reference — use to adjust material costs over time',
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        } catch (e) {
          return new Response(JSON.stringify({
            error: `PPI fetch failed: ${(e as Error).message}`,
          }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      }

      // ── Pricing Lookup (POST variant for batch) ──
      if (action === 'lookup-batch') {
        const { items, zip, company_id } = body
        // items: [{ item_id: UUID }]

        if (!Array.isArray(items) || !zip) {
          return new Response(JSON.stringify({ error: 'items array and zip required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        // ZIP → MSA
        const { data: msaResult } = await supabase.rpc('fn_zip_to_msa', { zip })
        const region = msaResult?.[0] || { cbsa_code: 'NATIONAL', region_name: 'National Average', cost_index: 1.0 }

        // Batch lookup
        const results = await Promise.all(
          items.map(async (item: { item_id: string }) => {
            const { data: pricing } = await supabase.rpc('fn_get_item_pricing', {
              p_item_id: item.item_id,
              p_region_code: region.cbsa_code,
              p_company_id: company_id || null,
            })
            return {
              item_id: item.item_id,
              pricing: pricing?.[0] || null,
            }
          })
        )

        return new Response(JSON.stringify({ region, results }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
