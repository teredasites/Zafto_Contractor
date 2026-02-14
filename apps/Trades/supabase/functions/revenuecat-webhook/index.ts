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

  // Verify RevenueCat webhook auth token
  const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
  if (webhookSecret) {
    const authToken = req.headers.get('x-revenuecat-webhook-auth-token')
    if (authToken !== webhookSecret) {
      console.error('Invalid RevenueCat webhook auth token')
      return new Response('Unauthorized', { status: 401 })
    }
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

      // Upsert user credits — create if not exists, increment if exists
      const { data: existing } = await supabase
        .from('user_credits')
        .select('id, paid_credits')
        .eq('user_id', appUserId)
        .single()

      if (existing) {
        await supabase
          .from('user_credits')
          .update({
            paid_credits: existing.paid_credits + creditsToAdd,
          })
          .eq('user_id', appUserId)
      } else {
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
          paid_credits: creditsToAdd,
          total_scans: 0,
        })
      }

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
        const { data: existing } = await supabase
          .from('user_credits')
          .select('id, paid_credits')
          .eq('user_id', appUserId)
          .single()

        if (existing) {
          await supabase
            .from('user_credits')
            .update({
              paid_credits: Math.max(0, existing.paid_credits - creditsToRemove),
            })
            .eq('user_id', appUserId)
        }

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
