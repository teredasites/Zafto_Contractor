// Supabase Edge Function: draft-recovery-list
// DEPTH27: Returns active drafts for user across all devices
// Used by recovery UI to show cross-device drafts

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

serve(async (req: Request) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') return corsResponse(origin)

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return errorResponse('Missing authorization', 401, origin)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) return errorResponse('Unauthorized', 401, origin)

    const url = new URL(req.url)
    const feature = url.searchParams.get('feature')
    const includeExpired = url.searchParams.get('include_expired') === 'true'

    let query = supabase
      .from('draft_recovery')
      .select('id, feature, screen_route, state_size_bytes, device_id, device_type, version, is_pinned, checksum, created_at, updated_at, expired_at')
      .eq('user_id', user.id)
      .is('deleted_at', null)
      .order('updated_at', { ascending: false })
      .limit(50)

    if (feature) {
      query = query.eq('feature', feature)
    }

    if (!includeExpired) {
      query = query.eq('is_active', true)
    }

    const { data, error: fetchError } = await query

    if (fetchError) return errorResponse(fetchError.message, 500, origin)

    return new Response(
      JSON.stringify({ drafts: data || [] }),
      { headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Internal error'
    return errorResponse(msg, 500, req.headers.get('Origin'))
  }
})
