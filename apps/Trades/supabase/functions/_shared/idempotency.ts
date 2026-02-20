/**
 * Webhook idempotency utility — INFRA-5
 *
 * Every webhook handler MUST call ensureNotProcessed() before processing.
 * If the event was already processed, returns false (skip processing).
 * If new, inserts into webhook_events and returns true (proceed).
 *
 * Usage:
 * ```ts
 * import { ensureNotProcessed } from '../_shared/idempotency.ts'
 *
 * const eventId = body.id || req.headers.get('x-webhook-id')
 * const isNew = await ensureNotProcessed(supabaseService, eventId, 'stripe', body.type, body)
 * if (!isNew) return new Response('Already processed', { status: 200 })
 * ```
 */

import { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export async function ensureNotProcessed(
  supabase: SupabaseClient,
  eventId: string,
  source: string,
  eventType?: string,
  payload?: unknown,
): Promise<boolean> {
  if (!eventId) return true // No event ID = can't deduplicate, allow through

  try {
    const { error } = await supabase
      .from('webhook_events')
      .insert({
        event_id: eventId,
        source,
        event_type: eventType || null,
        payload: payload ? JSON.parse(JSON.stringify(payload)) : null,
      })

    if (error) {
      // Unique constraint violation = already processed
      if (error.code === '23505') return false
      // Other errors = log but allow through (fail open for webhooks is safer than dropping events)
      console.error('[idempotency] Insert error:', error.message)
      return true
    }

    return true // New event, proceed with processing
  } catch (err) {
    console.error('[idempotency] Unexpected error:', err)
    return true // Fail open — better to double-process than drop
  }
}
