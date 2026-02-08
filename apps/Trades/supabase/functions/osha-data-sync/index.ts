// Supabase Edge Function: osha-data-sync
// Pull OSHA enforcement data and standards
// Actions: sync_standards, lookup_violations, get_standards_for_trade

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// OSHA public API base URL
const OSHA_API_BASE = 'https://enforcedata.dol.gov/homePage/api'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  try {
    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'sync_standards':
        return await handleSyncStandards(supabase)
      case 'get_for_trade':
        return await handleGetForTrade(supabase, body)
      case 'lookup_violations':
        return await handleLookupViolations(body)
      case 'frequently_cited':
        return await handleFrequentlyCited(supabase, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('osha-data-sync error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// Frequently cited OSHA standards for construction trades
const TRADE_STANDARDS: Record<string, string[]> = {
  electrical: [
    '1926.405', '1926.416', '1926.417', '1926.431', '1926.432',
    '1910.303', '1910.304', '1910.305', '1910.333', '1910.334',
    '1926.1053', '1926.501', '1926.502',
  ],
  plumbing: [
    '1926.352', '1926.451', '1926.452', '1926.501', '1926.502',
    '1926.651', '1926.652', '1910.147',
  ],
  hvac: [
    '1926.353', '1926.55', '1926.62', '1910.134', '1910.147',
    '1926.501', '1926.502', '1926.1053',
  ],
  roofing: [
    '1926.501', '1926.502', '1926.503', '1926.451', '1926.452',
    '1926.453', '1926.1053', '1926.1060',
  ],
  general_construction: [
    '1926.20', '1926.21', '1926.28', '1926.100', '1926.102',
    '1926.451', '1926.501', '1926.1053', '1926.1060',
    '1910.1200', '1926.59',
  ],
  restoration: [
    '1926.62', '1926.1101', '1910.134', '1926.55', '1910.147',
    '1926.501', '1926.651', '1926.652',
  ],
  solar: [
    '1926.501', '1926.502', '1926.503', '1926.416', '1926.417',
    '1926.1053', '1926.1060', '1926.405',
  ],
}

async function handleSyncStandards(supabase: ReturnType<typeof createClient>) {
  // Seed frequently cited construction standards
  const standards = [
    { standard_number: '1926.501', title: 'Fall Protection — Duty to Have Fall Protection', part: '1926', subpart: 'M', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.502', title: 'Fall Protection — Fall Protection Systems Criteria', part: '1926', subpart: 'M', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.503', title: 'Fall Protection — Training Requirements', part: '1926', subpart: 'M', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.451', title: 'Scaffolds — General Requirements', part: '1926', subpart: 'L', trade_tags: ['general_construction', 'roofing'], is_frequently_cited: true },
    { standard_number: '1926.452', title: 'Scaffolds — Additional Requirements', part: '1926', subpart: 'L', trade_tags: ['general_construction'], is_frequently_cited: true },
    { standard_number: '1926.453', title: 'Scaffolds — Aerial Lifts', part: '1926', subpart: 'L', trade_tags: ['general_construction', 'roofing'], is_frequently_cited: true },
    { standard_number: '1926.1053', title: 'Ladders', part: '1926', subpart: 'X', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.1060', title: 'Training Requirements (Stairways/Ladders)', part: '1926', subpart: 'X', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.405', title: 'Wiring Methods, Components, and Equipment — General', part: '1926', subpart: 'K', trade_tags: ['electrical'], is_frequently_cited: true },
    { standard_number: '1926.416', title: 'Safety Requirements for Electrical Equipment', part: '1926', subpart: 'K', trade_tags: ['electrical', 'solar'], is_frequently_cited: true },
    { standard_number: '1926.417', title: 'Lockout and Tagging of Circuits', part: '1926', subpart: 'K', trade_tags: ['electrical', 'solar'], is_frequently_cited: true },
    { standard_number: '1910.147', title: 'Control of Hazardous Energy (LOTO)', part: '1910', subpart: 'J', trade_tags: ['electrical', 'hvac', 'plumbing'], is_frequently_cited: true },
    { standard_number: '1910.303', title: 'General Electrical Requirements', part: '1910', subpart: 'S', trade_tags: ['electrical'], is_frequently_cited: true },
    { standard_number: '1910.134', title: 'Respiratory Protection', part: '1910', subpart: 'I', trade_tags: ['restoration', 'hvac'], is_frequently_cited: true },
    { standard_number: '1910.1200', title: 'Hazard Communication (HazCom)', part: '1910', subpart: 'Z', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.651', title: 'Excavations — General Requirements', part: '1926', subpart: 'P', trade_tags: ['plumbing', 'general_construction'], is_frequently_cited: true },
    { standard_number: '1926.652', title: 'Excavations — Requirements for Protective Systems', part: '1926', subpart: 'P', trade_tags: ['plumbing', 'general_construction'], is_frequently_cited: true },
    { standard_number: '1926.100', title: 'Head Protection', part: '1926', subpart: 'E', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.102', title: 'Eye and Face Protection', part: '1926', subpart: 'E', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.20', title: 'General Safety and Health Provisions', part: '1926', subpart: 'C', trade_tags: ['all'], is_frequently_cited: true },
    { standard_number: '1926.62', title: 'Lead Exposure in Construction', part: '1926', subpart: 'D', trade_tags: ['restoration', 'general_construction'], is_frequently_cited: true },
    { standard_number: '1926.1101', title: 'Asbestos in Construction', part: '1926', subpart: 'Z', trade_tags: ['restoration', 'general_construction'], is_frequently_cited: true },
    { standard_number: '1926.352', title: 'Fire Prevention — Welding/Cutting', part: '1926', subpart: 'F', trade_tags: ['plumbing', 'hvac'], is_frequently_cited: true },
  ]

  let upsertCount = 0
  for (const std of standards) {
    const { error } = await supabase
      .from('osha_standards')
      .upsert(std, { onConflict: 'standard_number' })
    if (!error) upsertCount++
  }

  return new Response(JSON.stringify({
    success: true,
    upserted: upsertCount,
    total: standards.length,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleGetForTrade(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { trade } = body as { trade: string }

  if (!trade) {
    return new Response(JSON.stringify({ error: 'trade required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get standards that match this trade or 'all'
  const { data: standards, error } = await supabase
    .from('osha_standards')
    .select('*')
    .or(`trade_tags.cs.{${trade}},trade_tags.cs.{all}`)
    .order('standard_number')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ standards: standards || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleLookupViolations(body: Record<string, unknown>) {
  const { companyName, state } = body as { companyName?: string; state?: string }

  // OSHA public enforcement data API (free, no API key)
  // Note: This is a simplified lookup — in production, handle pagination
  try {
    let url = `${OSHA_API_BASE}/inspections?limit=25`
    if (companyName) url += `&estab_name=${encodeURIComponent(companyName)}`
    if (state) url += `&site_state=${encodeURIComponent(state)}`

    const res = await fetch(url, {
      headers: { 'Accept': 'application/json' },
    })

    if (!res.ok) {
      return new Response(JSON.stringify({ error: 'OSHA API unavailable', violations: [] }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const data = await res.json()

    return new Response(JSON.stringify({ violations: data || [] }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch {
    return new Response(JSON.stringify({ error: 'OSHA lookup failed', violations: [] }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
}

async function handleFrequentlyCited(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { trade } = body as { trade?: string }

  let query = supabase
    .from('osha_standards')
    .select('standard_number, title, part, subpart, trade_tags')
    .eq('is_frequently_cited', true)
    .order('standard_number')

  if (trade) {
    query = query.or(`trade_tags.cs.{${trade}},trade_tags.cs.{all}`)
  }

  const { data, error } = await query

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ standards: data || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
