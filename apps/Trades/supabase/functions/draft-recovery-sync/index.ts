// Supabase Edge Function: draft-recovery-sync
// DEPTH27: Handles draft upsert, conflict detection, expiry cleanup
// Called by web portals for cloud sync layer (Layer 3)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') return corsResponse(origin)

  try {
    // Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return errorResponse('Missing authorization', 401, origin)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) return errorResponse('Unauthorized', 401, origin)

    const companyId = user.app_metadata?.company_id
    if (!companyId) return errorResponse('No company', 403, origin)

    const url = new URL(req.url)
    const action = url.searchParams.get('action') || 'upsert'

    if (action === 'upsert' && req.method === 'POST') {
      const body = await req.json()
      const {
        feature,
        screen_route,
        state_json,
        device_id = '',
        device_type = 'web',
        version = 1,
        is_pinned = false,
        checksum = '',
      } = body

      if (!feature || !screen_route) {
        return errorResponse('Missing feature or screen_route', 400, origin)
      }

      // Check for existing draft (conflict detection)
      const { data: existing } = await supabase
        .from('draft_recovery')
        .select('id, version, updated_at')
        .eq('user_id', user.id)
        .eq('feature', feature)
        .eq('screen_route', screen_route)
        .eq('is_active', true)
        .is('deleted_at', null)
        .maybeSingle()

      const stateSize = JSON.stringify(state_json).length

      if (existing) {
        // Update existing — newer version wins
        if (version > existing.version) {
          const { error: updateError } = await supabase
            .from('draft_recovery')
            .update({
              state_json,
              state_size_bytes: stateSize,
              device_id,
              device_type,
              version,
              is_pinned,
              checksum,
              updated_at: new Date().toISOString(),
            })
            .eq('id', existing.id)

          if (updateError) return errorResponse(updateError.message, 500, origin)

          return new Response(
            JSON.stringify({ status: 'updated', id: existing.id }),
            { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
          )
        } else {
          // Server has newer or same version — return conflict info
          return new Response(
            JSON.stringify({
              status: 'conflict',
              server_version: existing.version,
              server_updated_at: existing.updated_at,
              client_version: version,
            }),
            { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
          )
        }
      } else {
        // Insert new draft
        const { data: inserted, error: insertError } = await supabase
          .from('draft_recovery')
          .insert({
            company_id: companyId,
            user_id: user.id,
            feature,
            screen_route,
            state_json,
            state_size_bytes: stateSize,
            device_id,
            device_type,
            version,
            is_active: true,
            is_pinned,
            checksum,
          })
          .select('id')
          .single()

        if (insertError) return errorResponse(insertError.message, 500, origin)

        return new Response(
          JSON.stringify({ status: 'created', id: inserted.id }),
          { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
        )
      }
    }

    if (action === 'expire') {
      // Expire inactive drafts older than 7 days (non-pinned)
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

      const { data: expired, error: expireError } = await supabase
        .from('draft_recovery')
        .update({ expired_at: new Date().toISOString(), is_active: false })
        .eq('company_id', companyId)
        .eq('is_active', true)
        .eq('is_pinned', false)
        .is('deleted_at', null)
        .lt('updated_at', sevenDaysAgo)
        .select('id')

      if (expireError) return errorResponse(expireError.message, 500, origin)

      // Hard delete drafts expired for 30+ days
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
      await supabase
        .from('draft_recovery')
        .update({ deleted_at: new Date().toISOString() })
        .eq('company_id', companyId)
        .eq('is_active', false)
        .is('deleted_at', null)
        .not('expired_at', 'is', null)
        .lt('expired_at', thirtyDaysAgo)

      return new Response(
        JSON.stringify({ status: 'expired', count: expired?.length ?? 0 }),
        { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'recover' && req.method === 'POST') {
      const body = await req.json()
      const { draft_id } = body

      if (!draft_id) return errorResponse('Missing draft_id', 400, origin)

      const { error: recoverError } = await supabase
        .from('draft_recovery')
        .update({ recovered_at: new Date().toISOString(), is_active: false })
        .eq('id', draft_id)
        .eq('user_id', user.id)

      if (recoverError) return errorResponse(recoverError.message, 500, origin)

      return new Response(
        JSON.stringify({ status: 'recovered' }),
        { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
      )
    }

    return errorResponse('Invalid action', 400, origin)
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Internal error'
    return errorResponse(msg, 500, req.headers.get('Origin'))
  }
})
