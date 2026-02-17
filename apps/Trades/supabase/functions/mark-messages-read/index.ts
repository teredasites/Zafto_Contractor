// Supabase Edge Function: mark-messages-read
// Marks messages as read for the authenticated user.
// POST { conversation_id } — marks all unread messages in conversation as read.
// Resets unread_count in conversation_members.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const { conversation_id } = await req.json()

    if (!conversation_id) {
      return new Response(JSON.stringify({ error: 'conversation_id required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify user is participant
    const { data: conv } = await supabase
      .from('conversations')
      .select('id, participant_ids')
      .eq('id', conversation_id)
      .eq('company_id', companyId)
      .is('deleted_at', null)
      .single()

    if (!conv || !conv.participant_ids.includes(user.id)) {
      return new Response(JSON.stringify({ error: 'Not a participant' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Add user to read_by array on all unread messages in this conversation
    // Uses array_append only if user not already in read_by
    const { error: updateErr } = await supabase.rpc('mark_conversation_read', {
      p_conversation_id: conversation_id,
      p_user_id: user.id,
    })

    if (updateErr) {
      // Fallback: direct update if RPC not available
      console.error('[mark-messages-read] RPC error, using fallback:', updateErr)
      await supabase
        .from('messages')
        .update({ read_by: supabase.rpc('array_append_unique', { arr: 'read_by', val: user.id }) })
        .eq('conversation_id', conversation_id)
        .eq('company_id', companyId)
        .not('read_by', 'cs', `{${user.id}}`)
    }

    // Reset unread count for this user in conversation_members
    await supabase
      .from('conversation_members')
      .update({
        unread_count: 0,
        last_read_at: new Date().toISOString(),
      })
      .eq('conversation_id', conversation_id)
      .eq('user_id', user.id)

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('[mark-messages-read] Error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
