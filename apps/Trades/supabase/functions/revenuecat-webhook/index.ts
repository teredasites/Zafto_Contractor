// Supabase Edge Function: revenuecat-webhook
// Migrated from Firebase revenueCatWebhook
// Processes IAP credit purchases from RevenueCat
// POST (webhook payload from RevenueCat)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CREDIT_PRODUCTS: Record<string, number> = {
  'zafto_credits_10': 10,
  'zafto_credits_25': 25,
  'zafto_credits_50': 50,
  'zafto_credits_100': 100,
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  // SEC-AUDIT-1: Fail-closed — reject ALL requests if webhook secret not configured
  const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
  if (!webhookSecret) {
    console.error('REVENUECAT_WEBHOOK_SECRET not configured — rejecting all requests')
    return new Response('Webhook secret not configured', { status: 500 })
  }
  const authToken = req.headers.get('x-revenuecat-webhook-auth-token')
  if (authToken !== webhookSecret) {
    console.error('Invalid RevenueCat webhook auth token')
    return new Response('Unauthorized', { status: 401 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  try {
    const event = await req.json()
    const eventType = event.event?.type || event.event

    // Handle purchase events
    if (eventType === 'INITIAL_PURCHASE' || eventType === 'NON_RENEWING_PURCHASE') {
      const appUserId = event.event?.app_user_id || event.app_user_id
      const productId = event.event?.product_id || event.product_id

      const creditsToAdd = CREDIT_PRODUCTS[productId]

      if (!creditsToAdd || !appUserId) {
        console.log(`Ignoring event: unknown product ${productId} or missing user`)
        return new Response('OK', { status: 200 })
      }

      // SEC-AUDIT-1: Use atomic RPC to prevent race conditions on credit updates
      // First ensure user_credits row exists
      const { data: existing } = await supabase
        .from('user_credits')
        .select('id')
        .eq('user_id', appUserId)
        .single()

      if (!existing) {
        // Get company_id for the user
        const { data: userData } = await supabase
          .from('users')
          .select('company_id')
          .eq('id', appUserId)
          .single()

        await supabase.from('user_credits').insert({
          user_id: appUserId,
          company_id: userData?.company_id || null,
          free_credits: 3,
          paid_credits: 0,
          total_scans: 0,
        })
      }

      // Atomic increment via SECURITY DEFINER RPC (no race condition)
      await supabase.rpc('increment_user_credits', {
        p_user_id: appUserId,
        p_amount: creditsToAdd,
      })

      // Log the purchase
      const { data: userData } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', appUserId)
        .single()

      await supabase.from('credit_purchases').insert({
        user_id: appUserId,
        company_id: userData?.company_id || null,
        product_id: productId,
        transaction_id: event.event?.transaction_id || event.transaction_id || null,
        credits_added: creditsToAdd,
        source: 'revenuecat',
        event_type: eventType,
        status: 'completed',
      })

      console.log(`Added ${creditsToAdd} credits to user ${appUserId} via ${productId}`)
    }

    // Handle refund events
    if (eventType === 'CANCELLATION' || eventType === 'REFUND') {
      const appUserId = event.event?.app_user_id || event.app_user_id
      const productId = event.event?.product_id || event.product_id
      const creditsToRemove = CREDIT_PRODUCTS[productId]

      if (creditsToRemove && appUserId) {
        // SEC-AUDIT-1: Atomic decrement via SECURITY DEFINER RPC
        // decrement_user_credits checks paid_credits + free_credits >= amount
        // If insufficient, returns empty set (no update) — safe
        await supabase.rpc('decrement_user_credits', {
          p_user_id: appUserId,
          p_amount: creditsToRemove,
        })

        // Mark purchase as refunded
        await supabase
          .from('credit_purchases')
          .update({ status: 'refunded' })
          .eq('user_id', appUserId)
          .eq('product_id', productId)
          .eq('status', 'completed')
          .order('created_at', { ascending: false })
          .limit(1)

        console.log(`Refunded ${creditsToRemove} credits from user ${appUserId}`)
      }
    }

    return new Response('OK', { status: 200 })
  } catch (err) {
    console.error('revenuecat-webhook error:', err)
    return new Response('OK', { status: 200 }) // Always return 200 to prevent retries
  }
})
