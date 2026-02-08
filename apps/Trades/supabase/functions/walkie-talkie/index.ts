// Supabase Edge Function: walkie-talkie
// Push-to-Talk (PTT) via LiveKit audio-only rooms
// Actions: create_channel, join, leave, list_channels

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

  const LIVEKIT_URL = Deno.env.get('LIVEKIT_URL') ?? ''
  const LIVEKIT_API_KEY = Deno.env.get('LIVEKIT_API_KEY') ?? ''
  const LIVEKIT_API_SECRET = Deno.env.get('LIVEKIT_API_SECRET') ?? ''
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
      case 'create_channel':
        return await handleCreateChannel(supabase, userData, user.id, body)
      case 'join':
        return await handleJoin(supabase, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, userData, user.id, body)
      case 'leave':
        return await handleLeave(supabase, userData, user.id, body)
      case 'list_channels':
        return await handleListChannels(supabase, userData)
      case 'log_message':
        return await handleLogMessage(supabase, userData, user.id, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('walkie-talkie error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handleCreateChannel(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { name, channelType, jobId, memberUserIds } = body as {
    name: string
    channelType: string
    jobId?: string
    memberUserIds?: string[]
  }

  if (!name || !channelType) {
    return new Response(JSON.stringify({ error: 'name and channelType required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const roomName = `ptt-${userData.company_id.substring(0, 8)}-${Date.now()}`

  const { data: channel, error: err } = await supabase
    .from('walkie_talkie_channels')
    .insert({
      company_id: userData.company_id,
      job_id: jobId || null,
      name,
      channel_type: channelType,
      livekit_room_name: roomName,
      member_user_ids: memberUserIds || [],
      created_by: userId,
    })
    .select()
    .single()

  if (err || !channel) {
    return new Response(JSON.stringify({ error: 'Failed to create channel' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true, channel }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleJoin(
  supabase: ReturnType<typeof createClient>,
  livekitUrl: string,
  apiKey: string,
  apiSecret: string,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { channelId } = body as { channelId: string }

  if (!channelId) {
    return new Response(JSON.stringify({ error: 'channelId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { data: channel } = await supabase
    .from('walkie_talkie_channels')
    .select('*')
    .eq('id', channelId)
    .eq('company_id', userData.company_id)
    .single()

  if (!channel) {
    return new Response(JSON.stringify({ error: 'Channel not found' }), {
      status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Generate audio-only LiveKit token
  const token = await generatePTTToken(
    apiKey, apiSecret, channel.livekit_room_name, userData.name, userId
  )

  return new Response(JSON.stringify({
    success: true,
    channelId: channel.id,
    channelName: channel.name,
    roomName: channel.livekit_room_name,
    livekitUrl,
    token,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleLeave(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  // Client-side disconnect from LiveKit handles the actual leave
  // This endpoint is for logging/cleanup
  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleListChannels(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
) {
  const { data: channels } = await supabase
    .from('walkie_talkie_channels')
    .select('*, jobs(title)')
    .eq('company_id', userData.company_id)
    .eq('is_active', true)
    .order('name')

  return new Response(JSON.stringify({ channels: channels || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleLogMessage(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { channelId, durationSeconds, transcript, audioPath } = body as {
    channelId: string
    durationSeconds?: number
    transcript?: string
    audioPath?: string
  }

  if (!channelId) {
    return new Response(JSON.stringify({ error: 'channelId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get channel's job_id
  const { data: channel } = await supabase
    .from('walkie_talkie_channels')
    .select('job_id')
    .eq('id', channelId)
    .single()

  const { data: msg, error: err } = await supabase
    .from('walkie_talkie_messages')
    .insert({
      company_id: userData.company_id,
      channel_id: channelId,
      job_id: channel?.job_id || null,
      sender_id: userId,
      sender_name: userData.name,
      duration_seconds: durationSeconds || null,
      transcript: transcript || null,
      audio_path: audioPath || null,
    })
    .select()
    .single()

  if (err) {
    return new Response(JSON.stringify({ error: 'Failed to log message' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ success: true, messageId: msg.id }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function generatePTTToken(
  apiKey: string,
  apiSecret: string,
  roomName: string,
  participantName: string,
  participantIdentity: string,
): Promise<string> {
  const header = { alg: 'HS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)

  const claims = {
    iss: apiKey,
    sub: participantIdentity,
    name: participantName,
    nbf: now,
    exp: now + 86400,
    video: {
      room: roomName,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
      // Audio-only: video publishing handled client-side by not enabling video tracks
    },
  }

  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '')
  const claimsB64 = btoa(JSON.stringify(claims)).replace(/=/g, '')
  const signingInput = `${headerB64}.${claimsB64}`

  const key = await crypto.subtle.importKey(
    'raw', encoder.encode(apiSecret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  )

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(signingInput))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')

  return `${headerB64}.${claimsB64}.${sigB64}`
}
