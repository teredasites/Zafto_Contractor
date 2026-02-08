// Supabase Edge Function: stripe-webhook
// Migrated from Firebase stripeWebhook
// Handles payment_intent.succeeded and payment_intent.payment_failed
// POST (raw body from Stripe)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.14.0?target=deno'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

  if (!stripeKey || !webhookSecret) {
    console.error('Stripe secrets not configured')
    return new Response('Server configuration error', { status: 500 })
  }

  const stripe = new Stripe(stripeKey, { apiVersion: '2023-10-16' })
  const signature = req.headers.get('stripe-signature')

  if (!signature) {
    return new Response('Missing stripe-signature header', { status: 400 })
  }

  // Read raw body for signature verification
  const body = await req.text()

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message)
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }

  // Service role client for database writes (bypasses RLS)
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(supabase, event.data.object as Stripe.PaymentIntent)
        break

      case 'payment_intent.payment_failed':
        await handlePaymentFailed(supabase, event.data.object as Stripe.PaymentIntent)
        break

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }
  } catch (err) {
    console.error(`Error handling ${event.type}:`, err)
    // Return 200 anyway to prevent Stripe retries on processing errors
    // The error is logged for debugging
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})

// ============================================================================
// PAYMENT SUCCESS
// ============================================================================
async function handlePaymentSuccess(
  supabase: ReturnType<typeof createClient>,
  paymentIntent: Stripe.PaymentIntent,
) {
  const { type, referenceId, userId, customerId, companyId } = paymentIntent.metadata

  console.log(`Payment succeeded: ${paymentIntent.id}, type: ${type}, ref: ${referenceId}`)

  // Update payment_intents record
  await supabase
    .from('payment_intents')
    .update({
      status: 'succeeded',
      succeeded_at: new Date().toISOString(),
    })
    .eq('stripe_payment_intent_id', paymentIntent.id)

  // Handle by payment type
  if (type === 'bid_deposit' && referenceId) {
    await supabase
      .from('bids')
      .update({
        deposit_paid: true,
        deposit_amount: paymentIntent.amount,
        deposit_paid_at: new Date().toISOString(),
        status: 'accepted',
        updated_at: new Date().toISOString(),
      })
      .eq('id', referenceId)

    console.log(`Bid ${referenceId} marked as deposit paid`)
  } else if (type === 'invoice' && referenceId) {
    await supabase
      .from('invoices')
      .update({
        status: 'paid',
        paid_amount: paymentIntent.amount,
        paid_at: new Date().toISOString(),
        payment_method: 'stripe',
        updated_at: new Date().toISOString(),
      })
      .eq('id', referenceId)

    console.log(`Invoice ${referenceId} marked as paid`)
  }

  // Create immutable payment record
  const companyIdResolved = companyId || await resolveCompanyId(supabase, userId)
  if (companyIdResolved) {
    await supabase.from('payments').insert({
      company_id: companyIdResolved,
      stripe_payment_intent_id: paymentIntent.id,
      user_id: userId,
      customer_id: customerId || null,
      payment_type: type,
      reference_id: referenceId || null,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
      status: 'succeeded',
      receipt_email: paymentIntent.receipt_email,
    })
  }
}

// ============================================================================
// PAYMENT FAILED
// ============================================================================
async function handlePaymentFailed(
  supabase: ReturnType<typeof createClient>,
  paymentIntent: Stripe.PaymentIntent,
) {
  const { type, referenceId } = paymentIntent.metadata
  const errorMessage = paymentIntent.last_payment_error?.message || 'Payment failed'
  const errorCode = paymentIntent.last_payment_error?.code || null

  console.log(`Payment failed: ${paymentIntent.id}, type: ${type}, ref: ${referenceId}`)

  // Update payment_intents record
  await supabase
    .from('payment_intents')
    .update({
      status: 'failed',
      failed_at: new Date().toISOString(),
      failure_message: errorMessage,
    })
    .eq('stripe_payment_intent_id', paymentIntent.id)

  // Log failure
  await supabase.from('payment_failures').insert({
    stripe_payment_intent_id: paymentIntent.id,
    payment_type: type || null,
    reference_id: referenceId || null,
    error_message: errorMessage,
    error_code: errorCode,
  })
}

// ============================================================================
// HELPERS
// ============================================================================
async function resolveCompanyId(
  supabase: ReturnType<typeof createClient>,
  userId?: string,
): Promise<string | null> {
  if (!userId) return null
  const { data } = await supabase
    .from('users')
    .select('company_id')
    .eq('id', userId)
    .single()
  return data?.company_id || null
}
