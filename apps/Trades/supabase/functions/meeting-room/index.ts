// Supabase Edge Function: meeting-room
// LiveKit room management: create, join (token gen), end, recording
// POST { action: 'create' | 'join' | 'end' | 'status' }

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
    // Auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: userData } = await supabase
      .from('users')
      .select('company_id, name, role')
      .eq('id', user.id)
      .single()

    if (!userData?.company_id) {
      return new Response(JSON.stringify({ error: 'No company found' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'create':
        return await handleCreate(supabase, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, userData, user.id, body)
      case 'join':
        return await handleJoin(supabase, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, userData, user.id, body)
      case 'end':
        return await handleEnd(supabase, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET, body)
      case 'status':
        return await handleStatus(supabase, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('meeting-room error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// GENERATE LIVEKIT JWT TOKEN
// ============================================================================
async function generateLiveKitToken(
  apiKey: string,
  apiSecret: string,
  roomName: string,
  participantName: string,
  participantIdentity: string,
  canPublish: boolean = true,
  canSubscribe: boolean = true,
): Promise<string> {
  // Build JWT for LiveKit access token
  const header = { alg: 'HS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)

  const claims = {
    iss: apiKey,
    sub: participantIdentity,
    name: participantName,
    nbf: now,
    exp: now + 86400, // 24 hours
    video: {
      room: roomName,
      roomJoin: true,
      canPublish,
      canSubscribe,
      canPublishData: true,
    },
  }

  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '')
  const claimsB64 = btoa(JSON.stringify(claims)).replace(/=/g, '')
  const signingInput = `${headerB64}.${claimsB64}`

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(apiSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(signingInput))
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')

  return `${headerB64}.${claimsB64}.${sigB64}`
}

// ============================================================================
// CREATE MEETING
// ============================================================================
async function handleCreate(
  supabase: ReturnType<typeof createClient>,
  livekitUrl: string,
  apiKey: string,
  apiSecret: string,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { title, meetingType, jobId, claimId, scheduled, durationMinutes, record } = body as {
    title: string
    meetingType: string
    jobId?: string
    claimId?: string
    scheduled?: string
    durationMinutes?: number
    record?: boolean
  }

  if (!title || !meetingType) {
    return new Response(JSON.stringify({ error: 'title and meetingType required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Generate unique room code
  const roomCode = generateRoomCode()
  const roomName = `zafto-${userData.company_id.substring(0, 8)}-${roomCode}`

  // Create meeting record
  const { data: meeting, error: insertErr } = await supabase
    .from('meetings')
    .insert({
      company_id: userData.company_id,
      job_id: jobId || null,
      claim_id: claimId || null,
      title,
      meeting_type: meetingType,
      room_code: roomCode,
      scheduled_at: scheduled || null,
      duration_minutes: durationMinutes || 30,
      livekit_room_name: roomName,
      is_recorded: record || false,
      status: scheduled ? 'scheduled' : 'in_progress',
      started_at: scheduled ? null : new Date().toISOString(),
      created_by: userId,
    })
    .select()
    .single()

  if (insertErr || !meeting) {
    console.error('Failed to create meeting:', insertErr)
    return new Response(JSON.stringify({ error: 'Failed to create meeting' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Generate host token
  const hostToken = await generateLiveKitToken(
    apiKey, apiSecret, roomName, userData.name || 'Host', userId, true, true
  )

  // Add host as participant
  await supabase.from('meeting_participants').insert({
    company_id: userData.company_id,
    meeting_id: meeting.id,
    user_id: userId,
    participant_type: 'host',
    name: userData.name || 'Host',
    can_see_context_panel: true,
    can_see_financials: ['owner', 'admin'].includes(userData.role),
    can_record: true,
    can_share_documents: true,
    livekit_token: hostToken,
  })

  return new Response(JSON.stringify({
    success: true,
    meetingId: meeting.id,
    roomCode,
    roomName,
    livekitUrl,
    token: hostToken,
    joinUrl: `${Deno.env.get('SUPABASE_URL')?.replace('supabase.co', 'zafto.cloud')}/meet/${roomCode}`,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// JOIN MEETING
// ============================================================================
async function handleJoin(
  supabase: ReturnType<typeof createClient>,
  livekitUrl: string,
  apiKey: string,
  apiSecret: string,
  userData: { company_id: string; name: string; role: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const { roomCode, participantType } = body as {
    roomCode: string
    participantType?: string
  }

  if (!roomCode) {
    return new Response(JSON.stringify({ error: 'roomCode required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Find the meeting
  const { data: meeting } = await supabase
    .from('meetings')
    .select('*')
    .eq('room_code', roomCode)
    .single()

  if (!meeting) {
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (meeting.status === 'completed' || meeting.status === 'cancelled') {
    return new Response(JSON.stringify({ error: 'Meeting has ended' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const pType = participantType || (
    meeting.company_id === userData.company_id ? 'team_member' : 'guest'
  )

  const isInternal = meeting.company_id === userData.company_id
  const canSeeContext = isInternal
  const canSeeFinancials = isInternal && ['owner', 'admin'].includes(userData.role)

  // Generate participant token
  const token = await generateLiveKitToken(
    apiKey, apiSecret, meeting.livekit_room_name, userData.name || 'Participant', userId, true, true
  )

  // Add as participant
  await supabase.from('meeting_participants').insert({
    company_id: meeting.company_id,
    meeting_id: meeting.id,
    user_id: userId,
    participant_type: pType,
    name: userData.name || 'Participant',
    can_see_context_panel: canSeeContext,
    can_see_financials: canSeeFinancials,
    can_annotate: true,
    can_share_documents: isInternal,
    livekit_token: token,
    join_method: 'app',
    joined_at: new Date().toISOString(),
  })

  // Start meeting if it was scheduled
  if (meeting.status === 'scheduled') {
    await supabase
      .from('meetings')
      .update({ status: 'in_progress', started_at: new Date().toISOString() })
      .eq('id', meeting.id)
  }

  return new Response(JSON.stringify({
    success: true,
    meetingId: meeting.id,
    roomName: meeting.livekit_room_name,
    livekitUrl,
    token,
    meeting: {
      title: meeting.title,
      meetingType: meeting.meeting_type,
      jobId: meeting.job_id,
      isRecorded: meeting.is_recorded,
    },
    permissions: {
      canSeeContext,
      canSeeFinancials,
      canAnnotate: true,
      canRecord: pType === 'host',
      canShareDocuments: isInternal,
    },
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// END MEETING
// ============================================================================
async function handleEnd(
  supabase: ReturnType<typeof createClient>,
  livekitUrl: string,
  apiKey: string,
  apiSecret: string,
  body: Record<string, unknown>,
) {
  const { meetingId } = body as { meetingId: string }

  if (!meetingId) {
    return new Response(JSON.stringify({ error: 'meetingId required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const now = new Date().toISOString()

  const { data: meeting } = await supabase
    .from('meetings')
    .select('*')
    .eq('id', meetingId)
    .single()

  if (!meeting) {
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Calculate actual duration
  const startedAt = meeting.started_at ? new Date(meeting.started_at) : new Date()
  const actualDuration = Math.round((new Date(now).getTime() - startedAt.getTime()) / 60000)

  // Update meeting record
  await supabase
    .from('meetings')
    .update({
      status: 'completed',
      ended_at: now,
      actual_duration_minutes: actualDuration,
    })
    .eq('id', meetingId)

  // Update all participants who haven't left
  await supabase
    .from('meeting_participants')
    .update({ left_at: now })
    .eq('meeting_id', meetingId)
    .is('left_at', null)

  return new Response(JSON.stringify({
    success: true,
    actualDuration,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// STATUS
// ============================================================================
async function handleStatus(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { meetingId, roomCode } = body as { meetingId?: string; roomCode?: string }

  let query = supabase.from('meetings').select('*, meeting_participants(name, participant_type, joined_at, left_at)')

  if (meetingId) {
    query = query.eq('id', meetingId)
  } else if (roomCode) {
    query = query.eq('room_code', roomCode)
  } else {
    return new Response(JSON.stringify({ error: 'meetingId or roomCode required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { data: meeting, error: err } = await query.single()

  if (err || !meeting) {
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({
    id: meeting.id,
    title: meeting.title,
    status: meeting.status,
    meetingType: meeting.meeting_type,
    roomCode: meeting.room_code,
    startedAt: meeting.started_at,
    participants: meeting.meeting_participants,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// HELPERS
// ============================================================================
function generateRoomCode(): string {
  const chars = 'abcdefghjkmnpqrstuvwxyz23456789'
  const parts: string[] = []
  for (let p = 0; p < 3; p++) {
    let segment = ''
    for (let i = 0; i < 3; i++) {
      segment += chars[Math.floor(Math.random() * chars.length)]
    }
    parts.push(segment)
  }
  return parts.join('-')
}
