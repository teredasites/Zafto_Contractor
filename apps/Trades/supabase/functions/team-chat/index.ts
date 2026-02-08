// Supabase Edge Function: team-chat
// Internal team messaging — job threads, crew channels, direct messages
// Actions: send, list, mark_read

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

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: userData } = await supabase
      .from('users')
      .select('company_id, name, role')
      .eq('id', user.id)
      .single()

    if (!userData?.company_id) {
      return new Response(JSON.stringify({ error: 'No company found' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'send':
        return await handleSend(supabase, userData, user.id, body)
      case 'list':
        return await handleList(supabase, userData, body)
      case 'channels':
        return await handleChannels(supabase, userData, user.id)
      case 'mark_read':
        return await handleMarkRead(supabase, user.id, body)
      case 'edit':
        return await handleEdit(supabase, user.id, body)
      case 'delete':
        return await handleDelete(supabase, user.id, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('team-chat error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handleSend(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { channelType, channelId, messageText, attachmentPath, attachmentType, mentionedUserIds } = body as {
    channelType: string
    channelId: string
    messageText?: string
    attachmentPath?: string
    attachmentType?: string
    mentionedUserIds?: string[]
  }

  if (!channelType || !channelId) {
    return new Response(JSON.stringify({ error: 'channelType and channelId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!messageText && !attachmentPath) {
    return new Response(JSON.stringify({ error: 'messageText or attachmentPath required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const jobId = channelType === 'job' ? channelId : null

  const { data: msg, error: err } = await supabase
    .from('team_messages')
    .insert({
      company_id: userData.company_id,
      channel_type: channelType,
      channel_id: channelId,
      job_id: jobId,
      sender_id: userId,
      sender_name: userData.name,
      message_text: messageText || null,
      attachment_path: attachmentPath || null,
      attachment_type: attachmentType || null,
      mentioned_user_ids: mentionedUserIds || [],
    })
    .select()
    .single()

  if (err || !msg) {
    return new Response(JSON.stringify({ error: 'Failed to send message' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Auto-update read status for sender
  await supabase
    .from('team_message_reads')
    .upsert({
      user_id: userId,
      channel_type: channelType,
      channel_id: channelId,
      last_read_at: new Date().toISOString(),
    })

  return new Response(JSON.stringify({ success: true, message: msg }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleList(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  body: Record<string, unknown>,
) {
  const { channelType, channelId, limit: msgLimit, before } = body as {
    channelType: string
    channelId: string
    limit?: number
    before?: string
  }

  if (!channelType || !channelId) {
    return new Response(JSON.stringify({ error: 'channelType and channelId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let query = supabase
    .from('team_messages')
    .select('*')
    .eq('company_id', userData.company_id)
    .eq('channel_type', channelType)
    .eq('channel_id', channelId)
    .eq('is_deleted', false)
    .order('created_at', { ascending: false })
    .limit(msgLimit || 50)

  if (before) {
    query = query.lt('created_at', before)
  }

  const { data: messages, error: err } = await query

  if (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ messages: (messages || []).reverse() }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleChannels(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  userId: string,
) {
  // Get distinct channels the user's company has messages in
  const { data: messages } = await supabase
    .from('team_messages')
    .select('channel_type, channel_id, created_at, message_text, sender_name')
    .eq('company_id', userData.company_id)
    .eq('is_deleted', false)
    .order('created_at', { ascending: false })
    .limit(500)

  // Get user's read timestamps
  const { data: reads } = await supabase
    .from('team_message_reads')
    .select('channel_type, channel_id, last_read_at')
    .eq('user_id', userId)

  const readMap = new Map<string, string>()
  for (const r of (reads || [])) {
    readMap.set(`${r.channel_type}:${r.channel_id}`, r.last_read_at)
  }

  // Build channel list with latest message and unread count
  const channelMap = new Map<string, {
    channelType: string
    channelId: string
    lastMessage: string
    lastSender: string
    lastAt: string
    unreadCount: number
  }>()

  for (const msg of (messages || [])) {
    const key = `${msg.channel_type}:${msg.channel_id}`
    if (!channelMap.has(key)) {
      const lastRead = readMap.get(key)
      const isUnread = !lastRead || new Date(msg.created_at) > new Date(lastRead)
      channelMap.set(key, {
        channelType: msg.channel_type,
        channelId: msg.channel_id,
        lastMessage: msg.message_text || '[attachment]',
        lastSender: msg.sender_name,
        lastAt: msg.created_at,
        unreadCount: isUnread ? 1 : 0,
      })
    } else {
      const ch = channelMap.get(key)!
      const lastRead = readMap.get(key)
      if (!lastRead || new Date(msg.created_at) > new Date(lastRead)) {
        ch.unreadCount++
      }
    }
  }

  // Resolve job names for job channels
  const jobIds = [...channelMap.values()]
    .filter(c => c.channelType === 'job')
    .map(c => c.channelId)

  let jobNames: Record<string, string> = {}
  if (jobIds.length > 0) {
    const { data: jobs } = await supabase
      .from('jobs')
      .select('id, title')
      .in('id', jobIds)
    for (const j of (jobs || [])) {
      jobNames[j.id] = j.title
    }
  }

  const channels = [...channelMap.values()].map(c => ({
    ...c,
    displayName: c.channelType === 'job'
      ? jobNames[c.channelId] || `Job ${c.channelId.substring(0, 8)}`
      : c.channelType === 'company'
        ? 'Company'
        : c.channelId,
  }))

  channels.sort((a, b) => new Date(b.lastAt).getTime() - new Date(a.lastAt).getTime())

  return new Response(JSON.stringify({ channels }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleMarkRead(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  body: Record<string, unknown>,
) {
  const { channelType, channelId } = body as { channelType: string; channelId: string }

  if (!channelType || !channelId) {
    return new Response(JSON.stringify({ error: 'channelType and channelId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  await supabase
    .from('team_message_reads')
    .upsert({
      user_id: userId,
      channel_type: channelType,
      channel_id: channelId,
      last_read_at: new Date().toISOString(),
    })

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleEdit(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  body: Record<string, unknown>,
) {
  const { messageId, messageText } = body as { messageId: string; messageText: string }

  if (!messageId || !messageText) {
    return new Response(JSON.stringify({ error: 'messageId and messageText required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { error: err } = await supabase
    .from('team_messages')
    .update({
      message_text: messageText,
      is_edited: true,
      edited_at: new Date().toISOString(),
    })
    .eq('id', messageId)
    .eq('sender_id', userId) // Can only edit own messages

  if (err) {
    return new Response(JSON.stringify({ error: 'Failed to edit message' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleDelete(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  body: Record<string, unknown>,
) {
  const { messageId } = body as { messageId: string }

  if (!messageId) {
    return new Response(JSON.stringify({ error: 'messageId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Soft delete — only own messages
  const { error: err } = await supabase
    .from('team_messages')
    .update({ is_deleted: true })
    .eq('id', messageId)
    .eq('sender_id', userId)

  if (err) {
    return new Response(JSON.stringify({ error: 'Failed to delete message' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
