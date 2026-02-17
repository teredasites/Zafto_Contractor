// Supabase Edge Function: send-message
// Sends a message in a conversation. Validates sender is a participant.
// Creates conversation_member records if missing (first message in new conversation).
// POST { conversation_id, content?, message_type?, file_url?, file_name?, file_size?, file_mime_type?, reply_to_id? }
// Also supports: action: 'create_conversation' to create + send first message atomically.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limiter.ts'

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

  // Rate limit: 60 messages per minute per user
  const rateCheck = await checkRateLimit(supabase, {
    key: `user:${user.id}:send-message`,
    maxRequests: 60,
    windowSeconds: 60,
  })
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const { action } = body

    if (action === 'create_conversation') {
      return await handleCreateConversation(supabase, user.id, companyId, body)
    }

    return await handleSendMessage(supabase, user.id, companyId, body)
  } catch (err) {
    console.error('[send-message] Error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handleCreateConversation(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  companyId: string,
  body: Record<string, unknown>
) {
  const { type, title, participant_ids, job_id, content } = body as {
    type: string
    title?: string
    participant_ids: string[]
    job_id?: string
    content?: string
  }

  if (!participant_ids || !Array.isArray(participant_ids) || participant_ids.length === 0) {
    return new Response(JSON.stringify({ error: 'participant_ids required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Ensure creator is in participants
  const allParticipants = [...new Set([userId, ...participant_ids])]

  // For direct conversations, check if one already exists between these two users
  if (type === 'direct' && allParticipants.length === 2) {
    const { data: existing } = await supabase
      .from('conversations')
      .select('id')
      .eq('company_id', companyId)
      .eq('type', 'direct')
      .contains('participant_ids', allParticipants)
      .is('deleted_at', null)
      .limit(1)
      .single()

    if (existing) {
      // Send message to existing conversation
      if (content) {
        const { data: msg, error: msgErr } = await supabase
          .from('messages')
          .insert({
            company_id: companyId,
            conversation_id: existing.id,
            sender_id: userId,
            content,
            message_type: 'text',
          })
          .select()
          .single()

        if (msgErr) throw msgErr
        return new Response(JSON.stringify({ conversation_id: existing.id, message: msg }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      return new Response(JSON.stringify({ conversation_id: existing.id }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  }

  // Create conversation
  const { data: conversation, error: convErr } = await supabase
    .from('conversations')
    .insert({
      company_id: companyId,
      type: type || 'direct',
      title: title || null,
      participant_ids: allParticipants,
      job_id: job_id || null,
      created_by: userId,
    })
    .select()
    .single()

  if (convErr) throw convErr

  // Create conversation_members for all participants
  const memberInserts = allParticipants.map(pid => ({
    conversation_id: conversation.id,
    user_id: pid,
    company_id: companyId,
    unread_count: pid === userId ? 0 : (content ? 1 : 0),
  }))

  await supabase.from('conversation_members').insert(memberInserts)

  // Send first message if content provided
  let message = null
  if (content) {
    const { data: msg, error: msgErr } = await supabase
      .from('messages')
      .insert({
        company_id: companyId,
        conversation_id: conversation.id,
        sender_id: userId,
        content,
        message_type: 'text',
      })
      .select()
      .single()

    if (msgErr) throw msgErr
    message = msg
  }

  return new Response(JSON.stringify({ conversation, message }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleSendMessage(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  companyId: string,
  body: Record<string, unknown>
) {
  const {
    conversation_id,
    content,
    message_type = 'text',
    file_url,
    file_name,
    file_size,
    file_mime_type,
    reply_to_id,
  } = body as {
    conversation_id: string
    content?: string
    message_type?: string
    file_url?: string
    file_name?: string
    file_size?: number
    file_mime_type?: string
    reply_to_id?: string
  }

  if (!conversation_id) {
    return new Response(JSON.stringify({ error: 'conversation_id required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!content && !file_url) {
    return new Response(JSON.stringify({ error: 'content or file_url required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Verify user is participant in conversation
  const { data: conv, error: convErr } = await supabase
    .from('conversations')
    .select('id, participant_ids')
    .eq('id', conversation_id)
    .eq('company_id', companyId)
    .is('deleted_at', null)
    .single()

  if (convErr || !conv) {
    return new Response(JSON.stringify({ error: 'Conversation not found' }), {
      status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!conv.participant_ids.includes(userId)) {
    return new Response(JSON.stringify({ error: 'Not a participant in this conversation' }), {
      status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Insert message
  const { data: message, error: msgErr } = await supabase
    .from('messages')
    .insert({
      company_id: companyId,
      conversation_id,
      sender_id: userId,
      content: content || null,
      message_type,
      file_url: file_url || null,
      file_name: file_name || null,
      file_size: file_size || null,
      file_mime_type: file_mime_type || null,
      reply_to_id: reply_to_id || null,
    })
    .select()
    .single()

  if (msgErr) throw msgErr

  // Note: conversation.last_message_at and conversation_members.unread_count
  // are updated automatically by the database trigger (update_conversation_last_message)

  return new Response(JSON.stringify({ message }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
