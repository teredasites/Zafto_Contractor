// Supabase Edge Function: recon-material-order
// Maps trade_bid_data material list → supplier product search → pricing comparison.
// Gated: Unwrangle API key required for real-time pricing.
// Without API key: returns material list with "manual pricing" flag.

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

interface MaterialItem {
  item: string
  quantity: number
  unit: string
  waste_pct: number
  total_with_waste: number
}

interface SupplierPrice {
  supplier: string
  sku: string | null
  product_name: string | null
  unit_price: number | null
  total_price: number | null
  in_stock: boolean | null
  url: string | null
}

interface PricedMaterial {
  item: string
  quantity: number
  unit: string
  total_with_waste: number
  suppliers: SupplierPrice[]
  best_price: number | null
  best_supplier: string | null
}

// Map generic material names to search terms for supplier catalogs
function materialSearchTerm(item: string): string {
  const mappings: Record<string, string> = {
    '3-tab shingles': 'asphalt shingles 3 tab bundle',
    'architectural shingles': 'architectural shingles bundle',
    'synthetic underlayment': 'synthetic roofing underlayment roll',
    'ice & water shield': 'ice water shield roofing roll',
    'drip edge': 'drip edge roofing 10ft',
    'ridge cap shingles': 'ridge cap shingles bundle',
    'hip & ridge cap': 'hip ridge cap shingles',
    'roofing nails': 'roofing nails coil',
    'step flashing': 'step flashing roofing',
    'pipe boots': 'pipe boot roofing',
    'ridge vent': 'ridge vent roofing',
    'vinyl siding': 'vinyl siding panel',
    'fiber cement siding': 'fiber cement siding hardie',
    'house wrap': 'house wrap roll tyvek',
    'j-channel': 'j channel vinyl siding',
    'corner posts': 'corner post vinyl siding',
    'siding nails': 'stainless steel siding nails',
    'starter strip': 'starter strip siding',
    'gutters (5")': '5 inch gutter section aluminum',
    'gutters (6")': '6 inch gutter section aluminum',
    'downspouts': 'downspout 10ft aluminum',
    'gutter hangers': 'gutter hanger hidden',
    'end caps': 'gutter end cap',
    'gutter screws': 'gutter screws hex',
    'exterior paint': 'exterior paint gallon',
    'exterior primer': 'exterior primer gallon',
    'caulk': 'paintable exterior caulk',
    'painters tape': 'painters tape blue',
    'drop cloths': 'canvas drop cloth',
    'solar panels': 'solar panel 400w',
    'micro-inverters': 'micro inverter solar',
    'racking/mounting': 'solar panel mounting rail',
    'wiring': 'solar wiring cable',
    'concrete (yards)': 'ready mix concrete 80lb',
    'rebar': 'rebar #4 20ft',
    'wire mesh': 'welded wire mesh concrete',
    'expansion joints': 'expansion joint concrete',
    'fence posts': 'fence post treated 4x4',
    'fence panels (6\')': 'fence panel 6ft privacy',
    'post caps': 'fence post cap 4x4',
    'concrete (per post)': 'concrete mix 50lb quikrete',
    'post brackets': 'fence post bracket',
  }

  const lower = item.toLowerCase()
  for (const [key, value] of Object.entries(mappings)) {
    if (lower.includes(key.toLowerCase())) return value
  }
  return item
}

// Query Unwrangle API for product pricing (GATED — requires API key)
async function queryUnwrangle(
  searchTerm: string,
  apiKey: string,
  supplier: 'homedepot' | 'lowes'
): Promise<{ sku: string; product_name: string; price: number; in_stock: boolean; url: string } | null> {
  try {
    const params = new URLSearchParams({
      api_key: apiKey,
      search: searchTerm,
      source: supplier === 'homedepot' ? 'homedepot' : 'lowes',
      type: 'search',
      page: '1',
    })

    const res = await fetch(`https://api.unwrangle.com/api/getter/?${params}`)
    if (!res.ok) return null

    const data = await res.json()
    const results = data?.results || data?.search_results || []

    if (results.length === 0) return null

    const first = results[0]
    return {
      sku: first.sku || first.product_id || '',
      product_name: first.title || first.name || searchTerm,
      price: Number(first.price || first.current_price || 0),
      in_stock: first.in_stock !== false,
      url: first.url || first.link || '',
    }
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
    const { scan_id, trade, selected_suppliers } = body as {
      scan_id: string
      trade?: string
      selected_suppliers?: string[] // ['homedepot', 'lowes']
    }

    if (!scan_id) {
      return jsonResponse({ error: 'scan_id required' }, 400)
    }

    // Load trade bid data
    const query = supabase
      .from('trade_bid_data')
      .select('*')
      .eq('scan_id', scan_id)

    if (trade) {
      query.eq('trade', trade)
    }

    const { data: bids, error: bidErr } = await query
    if (bidErr) throw bidErr
    if (!bids || bids.length === 0) {
      return jsonResponse({ error: 'No trade bid data found for this scan' }, 404)
    }

    const unwrangleKey = Deno.env.get('UNWRANGLE_API_KEY')
    const hasApi = !!unwrangleKey
    const suppliers = selected_suppliers || ['homedepot', 'lowes']

    const results: Record<string, PricedMaterial[]> = {}

    for (const bid of bids) {
      const materials = (bid.material_list as MaterialItem[]) || []
      const pricedMaterials: PricedMaterial[] = []

      for (const mat of materials) {
        const priced: PricedMaterial = {
          item: mat.item,
          quantity: mat.quantity,
          unit: mat.unit,
          total_with_waste: mat.total_with_waste,
          suppliers: [],
          best_price: null,
          best_supplier: null,
        }

        if (hasApi && unwrangleKey) {
          const searchTerm = materialSearchTerm(mat.item)

          for (const supplier of suppliers) {
            if (supplier === 'homedepot' || supplier === 'lowes') {
              const result = await queryUnwrangle(searchTerm, unwrangleKey, supplier)
              if (result) {
                const totalPrice = result.price * mat.total_with_waste
                priced.suppliers.push({
                  supplier,
                  sku: result.sku,
                  product_name: result.product_name,
                  unit_price: result.price,
                  total_price: Math.round(totalPrice * 100) / 100,
                  in_stock: result.in_stock,
                  url: result.url,
                })

                if (priced.best_price === null || totalPrice < priced.best_price) {
                  priced.best_price = Math.round(totalPrice * 100) / 100
                  priced.best_supplier = supplier
                }
              } else {
                priced.suppliers.push({
                  supplier,
                  sku: null,
                  product_name: null,
                  unit_price: null,
                  total_price: null,
                  in_stock: null,
                  url: null,
                })
              }

              // Rate limit: 1 request per 200ms
              await new Promise(r => setTimeout(r, 200))
            }
          }
        } else {
          // No API key — return materials without pricing
          for (const supplier of suppliers) {
            priced.suppliers.push({
              supplier,
              sku: null,
              product_name: null,
              unit_price: null,
              total_price: null,
              in_stock: null,
              url: null,
            })
          }
        }

        pricedMaterials.push(priced)
      }

      results[bid.trade as string] = pricedMaterials
    }

    return jsonResponse({
      scan_id,
      pricing_available: hasApi,
      suppliers,
      trades: results,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
