// Supabase Edge Function: permit-requirement-lookup
// Geocode an address via Nominatim (free), match to jurisdiction, return permit requirements.
// Flow: address → Nominatim geocode → extract city/county/state → match permit_jurisdictions → return requirements
// $0 API cost — uses OpenStreetMap Nominatim (free, 1 req/sec, attribution required).

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NominatimResult {
  lat: string
  lon: string
  display_name: string
  address: {
    house_number?: string
    road?: string
    city?: string
    town?: string
    village?: string
    hamlet?: string
    county?: string
    state?: string
    state_code?: string
    postcode?: string
    country?: string
    country_code?: string
  }
}

interface GeocodedAddress {
  city: string | null
  county: string | null
  state: string | null
  stateCode: string | null
  lat: number
  lng: number
  displayName: string
}

// ── Geocode via Nominatim ──────────────────────────────
async function geocodeAddress(address: string): Promise<GeocodedAddress | null> {
  const encoded = encodeURIComponent(address)
  const url = `https://nominatim.openstreetmap.org/search?q=${encoded}&format=json&addressdetails=1&limit=1&countrycodes=us`

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'ZaftoContractor/1.0 (permit-lookup)',
      'Accept': 'application/json',
    },
  })

  if (!response.ok) return null

  const results: NominatimResult[] = await response.json()
  if (!results.length) return null

  const r = results[0]
  const addr = r.address

  // Nominatim returns city/town/village depending on locality size
  const city = addr.city || addr.town || addr.village || addr.hamlet || null

  // State code: Nominatim doesn't always give state_code, so we map from full name
  const stateCode = addr.state ? stateNameToCode(addr.state) : null

  return {
    city,
    county: addr.county?.replace(' County', '') || null,
    state: addr.state || null,
    stateCode,
    lat: parseFloat(r.lat),
    lng: parseFloat(r.lon),
    displayName: r.display_name,
  }
}

// ── State name → code mapping ──────────────────────────
const STATE_CODES: Record<string, string> = {
  'Alabama': 'AL', 'Alaska': 'AK', 'Arizona': 'AZ', 'Arkansas': 'AR',
  'California': 'CA', 'Colorado': 'CO', 'Connecticut': 'CT', 'Delaware': 'DE',
  'Florida': 'FL', 'Georgia': 'GA', 'Hawaii': 'HI', 'Idaho': 'ID',
  'Illinois': 'IL', 'Indiana': 'IN', 'Iowa': 'IA', 'Kansas': 'KS',
  'Kentucky': 'KY', 'Louisiana': 'LA', 'Maine': 'ME', 'Maryland': 'MD',
  'Massachusetts': 'MA', 'Michigan': 'MI', 'Minnesota': 'MN', 'Mississippi': 'MS',
  'Missouri': 'MO', 'Montana': 'MT', 'Nebraska': 'NE', 'Nevada': 'NV',
  'New Hampshire': 'NH', 'New Jersey': 'NJ', 'New Mexico': 'NM', 'New York': 'NY',
  'North Carolina': 'NC', 'North Dakota': 'ND', 'Ohio': 'OH', 'Oklahoma': 'OK',
  'Oregon': 'OR', 'Pennsylvania': 'PA', 'Rhode Island': 'RI', 'South Carolina': 'SC',
  'South Dakota': 'SD', 'Tennessee': 'TN', 'Texas': 'TX', 'Utah': 'UT',
  'Vermont': 'VT', 'Virginia': 'VA', 'Washington': 'WA', 'West Virginia': 'WV',
  'Wisconsin': 'WI', 'Wyoming': 'WY', 'District of Columbia': 'DC',
}

function stateNameToCode(name: string): string | null {
  return STATE_CODES[name] || null
}

// ── Jurisdiction matching (cascading: city → county → state) ───
async function findJurisdiction(
  supabase: ReturnType<typeof createClient>,
  geo: GeocodedAddress
): Promise<{ jurisdiction: Record<string, unknown> | null; matchType: string }> {
  // 1. Try exact city match
  if (geo.city && geo.stateCode) {
    const { data: cityMatch } = await supabase
      .from('permit_jurisdictions')
      .select('*')
      .ilike('city_name', geo.city)
      .eq('state_code', geo.stateCode)
      .limit(1)
      .maybeSingle()

    if (cityMatch) return { jurisdiction: cityMatch, matchType: 'city' }
  }

  // 2. Try county match
  if (geo.county && geo.stateCode) {
    const { data: countyMatch } = await supabase
      .from('permit_jurisdictions')
      .select('*')
      .ilike('jurisdiction_name', `%${geo.county}%`)
      .eq('state_code', geo.stateCode)
      .eq('jurisdiction_type', 'county')
      .limit(1)
      .maybeSingle()

    if (countyMatch) return { jurisdiction: countyMatch, matchType: 'county' }
  }

  // 3. Fall back to state-level
  if (geo.stateCode) {
    const { data: stateMatch } = await supabase
      .from('permit_jurisdictions')
      .select('*')
      .eq('state_code', geo.stateCode)
      .eq('jurisdiction_type', 'state')
      .limit(1)
      .maybeSingle()

    if (stateMatch) return { jurisdiction: stateMatch, matchType: 'state' }
  }

  return { jurisdiction: null, matchType: 'none' }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Verify user
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { address, trade_type, job_id } = body

    if (!address || typeof address !== 'string') {
      return new Response(JSON.stringify({ error: 'address is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Step 1: Geocode address
    const geo = await geocodeAddress(address)
    if (!geo) {
      return new Response(JSON.stringify({
        error: 'Could not geocode address',
        address,
        jurisdiction: null,
        requirements: [],
        matchType: 'none',
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Step 2: Match to jurisdiction (cascading: city → county → state)
    const { jurisdiction, matchType } = await findJurisdiction(supabase, geo)

    // Step 3: Get requirements for matched jurisdiction
    let requirements: Record<string, unknown>[] = []
    if (jurisdiction) {
      let query = supabase
        .from('permit_requirements')
        .select('*')
        .eq('jurisdiction_id', jurisdiction.id)

      if (trade_type) {
        // Get requirements for this trade or generic (no trade_type specified)
        query = query.or(`trade_type.eq.${trade_type},trade_type.is.null`)
      }

      const { data: reqs } = await query.order('work_type')
      requirements = reqs || []
    }

    // Step 4: Return full result
    const result = {
      address,
      geocoded: {
        city: geo.city,
        county: geo.county,
        state: geo.state,
        stateCode: geo.stateCode,
        lat: geo.lat,
        lng: geo.lng,
        displayName: geo.displayName,
      },
      jurisdiction: jurisdiction
        ? {
            id: jurisdiction.id,
            name: jurisdiction.jurisdiction_name,
            type: jurisdiction.jurisdiction_type,
            stateCode: jurisdiction.state_code,
            buildingDeptName: jurisdiction.building_dept_name,
            buildingDeptPhone: jurisdiction.building_dept_phone,
            buildingDeptUrl: jurisdiction.building_dept_url,
            onlineSubmissionUrl: jurisdiction.online_submission_url,
            avgTurnaroundDays: jurisdiction.avg_turnaround_days,
          }
        : null,
      matchType,
      requirements: requirements.map((r: Record<string, unknown>) => ({
        id: r.id,
        workType: r.work_type,
        tradeType: r.trade_type,
        permitRequired: r.permit_required,
        permitType: r.permit_type,
        estimatedFee: r.estimated_fee,
        inspectionsRequired: r.inspections_required,
        typicalDocuments: r.typical_documents,
        exemptions: r.exemptions,
        verified: r.verified,
      })),
      requirementCount: requirements.length,
      attribution: 'Address data © OpenStreetMap contributors',
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
