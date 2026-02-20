// Supabase Edge Function: subscription-credits
// Migrated from Firebase getCredits + addCredits
// POST { action: 'get' | 'add' | 'deduct', ... }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CREDIT_COSTS: Record<string, number> = {
  panel: 1,
  nameplate: 1,
  wire: 1,
  violation: 2,
  smart: 1,
  photo_diagnose: 1,
  troubleshoot: 1,
  parts_identify: 1,
  repair_guide: 1,
}

const CREDIT_PRODUCTS: Record<string, number> = {
  'zafto_credits_10': 10,
  'zafto_credits_25': 25,
  'zafto_credits_50': 50,
  'zafto_credits_100': 100,
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

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'get':
        return await handleGetCredits(supabase, user.id)
      case 'add':
        return await handleAddCredits(supabase, user.id, body)
      case 'deduct':
        return await handleDeductCredits(supabase, user.id, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action. Use "get", "add", or "deduct".' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('subscription-credits error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// GET CREDITS
// ============================================================================
async function handleGetCredits(
  supabase: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data, error } = await supabase
    .from('user_credits')
    .select('free_credits, paid_credits, total_scans, last_scan_at')
    .eq('user_id', userId)
    .single()

  if (error || !data) {
    // New user — return defaults (row will be created on first deduct)
    return new Response(JSON.stringify({
      freeCredits: 3,
      paidCredits: 0,
      totalScans: 0,
      lastScanAt: null,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({
    freeCredits: data.free_credits,
    paidCredits: data.paid_credits,
    totalScans: data.total_scans,
    lastScanAt: data.last_scan_at,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// ADD CREDITS (client-side purchase verification — for manual/promo)
// ============================================================================
async function handleAddCredits(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  body: Record<string, unknown>,
) {
  const { productId, transactionId } = body as { productId: string; transactionId?: string }

  const creditsToAdd = CREDIT_PRODUCTS[productId]
  if (!creditsToAdd) {
    return new Response(JSON.stringify({ error: 'Invalid product' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get user company
  const { data: userData } = await supabase
    .from('users')
    .select('company_id')
    .eq('id', userId)
    .single()

  // Log purchase attempt as pending (webhook will confirm)
  await supabase.from('credit_purchases').insert({
    user_id: userId,
    company_id: userData?.company_id || null,
    product_id: productId,
    transaction_id: transactionId || null,
    credits_added: creditsToAdd,
    source: 'stripe',
    event_type: 'client_request',
    status: 'pending',
  })

  return new Response(JSON.stringify({
    success: true,
    message: 'Purchase recorded. Credits will be added after verification.',
    creditsToAdd,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// DEDUCT CREDITS (called by AI scan functions)
// ============================================================================
async function handleDeductCredits(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  body: Record<string, unknown>,
) {
  const { scanType } = body as { scanType: string }
  const cost = CREDIT_COSTS[scanType] || 1

  // Ensure user has a credit record (create with defaults if not)
  const { data: existing } = await supabase
    .from('user_credits')
    .select('user_id')
    .eq('user_id', userId)
    .single()

  if (!existing) {
    const { data: userData } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', userId)
      .single()

    await supabase
      .from('user_credits')
      .insert({
        user_id: userId,
        company_id: userData?.company_id || null,
        free_credits: 3,
        paid_credits: 0,
        total_scans: 0,
      })
  }

  // Atomic deduction: row-locked, free-first-then-paid, race-condition-proof
  const { data: result, error: rpcError } = await supabase.rpc('deduct_credits_atomic', {
    p_user_id: userId,
    p_amount: cost,
  })

  if (rpcError) {
    if (rpcError.message?.includes('INSUFFICIENT_CREDITS')) {
      // Fetch current balances for the error response
      const { data: current } = await supabase
        .from('user_credits')
        .select('free_credits, paid_credits')
        .eq('user_id', userId)
        .single()

      return new Response(JSON.stringify({
        error: 'Insufficient credits',
        freeCredits: current?.free_credits ?? 0,
        paidCredits: current?.paid_credits ?? 0,
        required: cost,
      }), {
        status: 402,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.error('deduct_credits_atomic error:', rpcError)
    return new Response(JSON.stringify({ error: 'Failed to deduct credits' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const row = Array.isArray(result) ? result[0] : result

  // Log the scan
  await supabase.from('scan_logs').insert({
    user_id: userId,
    company_id: row?.user_company_id || null,
    scan_type: scanType,
    success: true,
    credits_charged: cost,
  })

  return new Response(JSON.stringify({
    success: true,
    freeCredits: row?.new_free_credits ?? 0,
    paidCredits: row?.new_paid_credits ?? 0,
    charged: cost,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
