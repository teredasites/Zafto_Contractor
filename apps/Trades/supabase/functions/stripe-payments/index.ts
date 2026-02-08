// Supabase Edge Function: stripe-payments
// Migrated from Firebase createPaymentIntent + getPaymentStatus
// POST { action: 'create' | 'status', ... }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.14.0?target=deno'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Auth check
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

    // Verify JWT and get user
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get user's company
    const { data: userData } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', user.id)
      .single()

    if (!userData?.company_id) {
      return new Response(JSON.stringify({ error: 'User has no company' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { action } = body

    if (action === 'create') {
      return await handleCreate(supabase, user, userData.company_id, body)
    } else if (action === 'status') {
      return await handleStatus(supabase, userData.company_id, body)
    } else {
      return new Response(JSON.stringify({ error: 'Invalid action. Use "create" or "status".' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  } catch (err) {
    console.error('stripe-payments error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// CREATE PAYMENT INTENT
// ============================================================================
async function handleCreate(
  supabase: ReturnType<typeof createClient>,
  user: { id: string; email?: string },
  companyId: string,
  body: Record<string, unknown>,
) {
  const { amount, currency = 'usd', type, referenceId, customerId, customerEmail, description } = body as {
    amount: number
    currency?: string
    type: string
    referenceId: string
    customerId?: string
    customerEmail?: string
    description?: string
  }

  // Validate
  if (!amount || amount < 50) {
    return new Response(JSON.stringify({ error: 'Amount must be at least $0.50 (50 cents)' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!type || !['bid_deposit', 'invoice', 'subscription', 'credit_purchase'].includes(type)) {
    return new Response(JSON.stringify({ error: 'Invalid payment type' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!referenceId) {
    return new Response(JSON.stringify({ error: 'referenceId is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
  if (!stripeKey) {
    return new Response(JSON.stringify({ error: 'Stripe not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' })

  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true },
    metadata: {
      type,
      referenceId,
      customerId: customerId || '',
      userId: user.id,
      companyId,
      source: 'zafto_app',
    },
    receipt_email: customerEmail || user.email || undefined,
    description: description || `ZAFTO ${type === 'bid_deposit' ? 'Deposit' : type === 'invoice' ? 'Invoice' : 'Payment'}`,
  })

  // Log the payment intent in Supabase
  await supabase.from('payment_intents').insert({
    company_id: companyId,
    stripe_payment_intent_id: paymentIntent.id,
    user_id: user.id,
    customer_id: customerId || null,
    payment_type: type,
    reference_id: referenceId,
    amount,
    currency,
    status: paymentIntent.status === 'requires_payment_method' ? 'pending' : paymentIntent.status,
    receipt_email: customerEmail || user.email || null,
  })

  return new Response(JSON.stringify({
    success: true,
    clientSecret: paymentIntent.client_secret,
    paymentIntentId: paymentIntent.id,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// GET PAYMENT STATUS
// ============================================================================
async function handleStatus(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  body: Record<string, unknown>,
) {
  const { type, referenceId } = body as { type: string; referenceId: string }

  if (!type || !referenceId) {
    return new Response(JSON.stringify({ error: 'type and referenceId are required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { data, error } = await supabase
    .from('payment_intents')
    .select('status, amount, currency, created_at, succeeded_at')
    .eq('company_id', companyId)
    .eq('payment_type', type)
    .eq('reference_id', referenceId)
    .order('created_at', { ascending: false })
    .limit(1)
    .single()

  if (error || !data) {
    return new Response(JSON.stringify({ hasPayment: false, status: null }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({
    hasPayment: true,
    status: data.status,
    amount: data.amount,
    currency: data.currency,
    createdAt: data.created_at,
    succeededAt: data.succeeded_at,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
