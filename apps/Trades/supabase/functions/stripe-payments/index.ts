// Supabase Edge Function: stripe-payments
// Actions: create | status | create_connect_account | check_connect_status | create_checkout_session
// POST { action, ... }

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
    } else if (action === 'create_connect_account') {
      return await handleCreateConnectAccount(supabase, user, userData.company_id, body)
    } else if (action === 'check_connect_status') {
      return await handleCheckConnectStatus(supabase, userData.company_id)
    } else if (action === 'create_checkout_session') {
      return await handleCreateCheckoutSession(supabase, user, userData.company_id, body)
    } else {
      return new Response(JSON.stringify({ error: 'Invalid action' }), {
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

  // Check if company has Stripe Connect — route payment to contractor's account
  const { data: companyData } = await supabase
    .from('companies')
    .select('stripe_account_id, stripe_connect_status')
    .eq('id', companyId)
    .single()

  const connectedAccountId = companyData?.stripe_connect_status === 'active'
    ? companyData?.stripe_account_id
    : null

  const platformFeePercent = 2.9 // Zafto platform fee %
  const applicationFeeAmount = connectedAccountId
    ? Math.round(amount * platformFeePercent / 100)
    : undefined

  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true },
    ...(connectedAccountId ? {
      transfer_data: { destination: connectedAccountId },
      application_fee_amount: applicationFeeAmount,
    } : {}),
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

// ============================================================================
// CREATE STRIPE CONNECT ACCOUNT (Express onboarding)
// ============================================================================
async function handleCreateConnectAccount(
  supabase: ReturnType<typeof createClient>,
  user: { id: string; email?: string },
  companyId: string,
  body: Record<string, unknown>,
) {
  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
  if (!stripeKey) {
    return new Response(JSON.stringify({ error: 'Stripe not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' })

  // Check if company already has a Connect account
  const { data: company } = await supabase
    .from('companies')
    .select('stripe_account_id, stripe_connect_status, name')
    .eq('id', companyId)
    .single()

  let accountId = company?.stripe_account_id

  if (!accountId) {
    // Create new Express account
    const account = await stripe.accounts.create({
      type: 'express',
      email: user.email,
      metadata: { companyId, source: 'zafto' },
      business_profile: {
        name: company?.name || undefined,
        product_description: 'Trade contractor services',
      },
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
    })
    accountId = account.id

    // Store account ID on company
    await supabase.from('companies').update({
      stripe_account_id: accountId,
      stripe_connect_status: 'onboarding_incomplete',
    }).eq('id', companyId)
  }

  // Generate onboarding link
  const { returnUrl, refreshUrl } = body as { returnUrl?: string; refreshUrl?: string }
  const accountLink = await stripe.accountLinks.create({
    account: accountId,
    refresh_url: refreshUrl || `${Deno.env.get('APP_URL') || 'https://zafto.cloud'}/dashboard/settings?tab=billing&connect=refresh`,
    return_url: returnUrl || `${Deno.env.get('APP_URL') || 'https://zafto.cloud'}/dashboard/settings?tab=billing&connect=success`,
    type: 'account_onboarding',
  })

  return new Response(JSON.stringify({
    success: true,
    accountId,
    onboardingUrl: accountLink.url,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// CHECK STRIPE CONNECT STATUS
// ============================================================================
async function handleCheckConnectStatus(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
) {
  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
  if (!stripeKey) {
    return new Response(JSON.stringify({ error: 'Stripe not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { data: company } = await supabase
    .from('companies')
    .select('stripe_account_id, stripe_connect_status')
    .eq('id', companyId)
    .single()

  if (!company?.stripe_account_id) {
    return new Response(JSON.stringify({
      connected: false,
      status: 'not_connected',
      details: null,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' })
  const account = await stripe.accounts.retrieve(company.stripe_account_id)

  // Determine status
  let connectStatus = 'onboarding_incomplete'
  if (account.charges_enabled && account.payouts_enabled) {
    connectStatus = 'active'
  } else if (account.requirements?.disabled_reason) {
    connectStatus = 'restricted'
  }

  // Update company record if status changed
  if (connectStatus !== company.stripe_connect_status) {
    await supabase.from('companies').update({
      stripe_connect_status: connectStatus,
      ...(connectStatus === 'active' ? { stripe_connect_onboarded_at: new Date().toISOString() } : {}),
    }).eq('id', companyId)
  }

  return new Response(JSON.stringify({
    connected: connectStatus === 'active',
    status: connectStatus,
    details: {
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      detailsSubmitted: account.details_submitted,
      requirements: account.requirements?.currently_due || [],
      dashboardUrl: `https://dashboard.stripe.com/${account.id}`,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// CREATE CHECKOUT SESSION (for client portal Pay Now)
// ============================================================================
async function handleCreateCheckoutSession(
  supabase: ReturnType<typeof createClient>,
  user: { id: string; email?: string },
  companyId: string,
  body: Record<string, unknown>,
) {
  const { invoiceId, amount, customerEmail, successUrl, cancelUrl } = body as {
    invoiceId: string
    amount: number
    customerEmail?: string
    successUrl?: string
    cancelUrl?: string
  }

  if (!invoiceId || !amount || amount < 50) {
    return new Response(JSON.stringify({ error: 'invoiceId and amount (min 50 cents) required' }), {
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

  // Fetch invoice details
  const { data: invoice } = await supabase
    .from('invoices')
    .select('invoice_number, customer_name, total, company_id')
    .eq('id', invoiceId)
    .single()

  // Fetch company's Connect account for payment routing
  const { data: companyData } = await supabase
    .from('companies')
    .select('stripe_account_id, stripe_connect_status, name')
    .eq('id', companyId)
    .single()

  const connectedAccountId = companyData?.stripe_connect_status === 'active'
    ? companyData?.stripe_account_id
    : null

  const platformFeePercent = 2.9
  const applicationFeeAmount = connectedAccountId
    ? Math.round(amount * platformFeePercent / 100)
    : undefined

  const baseUrl = Deno.env.get('CLIENT_PORTAL_URL') || 'https://client.zafto.cloud'

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    line_items: [{
      price_data: {
        currency: 'usd',
        product_data: {
          name: `Invoice ${invoice?.invoice_number || invoiceId}`,
          description: `Payment to ${companyData?.name || 'contractor'}`,
        },
        unit_amount: amount,
      },
      quantity: 1,
    }],
    customer_email: customerEmail || user.email || undefined,
    success_url: successUrl || `${baseUrl}/payments/${invoiceId}?status=success`,
    cancel_url: cancelUrl || `${baseUrl}/payments/${invoiceId}?status=cancelled`,
    metadata: {
      type: 'invoice',
      referenceId: invoiceId,
      companyId,
      userId: user.id,
      source: 'zafto_client_portal',
    },
    ...(connectedAccountId ? {
      payment_intent_data: {
        transfer_data: { destination: connectedAccountId },
        application_fee_amount: applicationFeeAmount,
      },
    } : {}),
  })

  // Log the payment intent
  if (session.payment_intent) {
    await supabase.from('payment_intents').insert({
      company_id: companyId,
      stripe_payment_intent_id: session.payment_intent as string,
      user_id: user.id,
      customer_id: null,
      payment_type: 'invoice',
      reference_id: invoiceId,
      amount,
      currency: 'usd',
      status: 'pending',
      receipt_email: customerEmail || user.email || null,
    })
  }

  return new Response(JSON.stringify({
    success: true,
    checkoutUrl: session.url,
    sessionId: session.id,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
