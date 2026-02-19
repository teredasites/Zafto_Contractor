// Supabase Edge Function: meeting-recording
// Handles LiveKit Egress webhooks — download recording, store in Supabase Storage
// POST from LiveKit egress_ended webhook

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { jwtVerify } from 'https://esm.sh/jose@5.2.2'

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
  const LIVEKIT_API_KEY = Deno.env.get('LIVEKIT_API_KEY') ?? ''
  const LIVEKIT_API_SECRET = Deno.env.get('LIVEKIT_API_SECRET') ?? ''

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  try {
    // Verify LiveKit webhook signature
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const token = authHeader.replace('Bearer ', '')
    try {
      const secret = new TextEncoder().encode(LIVEKIT_API_SECRET)
      const { payload } = await jwtVerify(token, secret)
      if (payload.iss !== LIVEKIT_API_KEY) {
        throw new Error('Invalid issuer')
      }
    } catch (verifyErr) {
      console.error('LiveKit webhook verification failed:', verifyErr)
      return new Response(JSON.stringify({ error: 'Invalid webhook signature' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json()
    const { event, egressInfo } = body

    if (event === 'egress_ended' && egressInfo) {
      return await handleEgressEnded(supabase, egressInfo)
    }

    if (event === 'egress_started' && egressInfo) {
      return await handleEgressStarted(supabase, egressInfo)
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('meeting-recording error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handleEgressStarted(
  supabase: ReturnType<typeof createClient>,
  egressInfo: Record<string, unknown>,
) {
  const roomName = egressInfo.room_name as string
  if (!roomName) {
    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Find meeting by livekit_room_name
  const { data: meeting } = await supabase
    .from('meetings')
    .select('id')
    .eq('livekit_room_name', roomName)
    .single()

  if (meeting) {
    await supabase
      .from('meetings')
      .update({
        livekit_room_sid: egressInfo.egress_id as string,
        is_recorded: true,
      })
      .eq('id', meeting.id)
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleEgressEnded(
  supabase: ReturnType<typeof createClient>,
  egressInfo: Record<string, unknown>,
) {
  const roomName = egressInfo.room_name as string
  const egressId = egressInfo.egress_id as string
  const fileResults = egressInfo.file_results as Record<string, unknown> | undefined
  const streamResults = egressInfo.stream_results as Record<string, unknown> | undefined

  if (!roomName) {
    return new Response(JSON.stringify({ error: 'No room name' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Find the meeting
  const { data: meeting } = await supabase
    .from('meetings')
    .select('id, company_id, title')
    .eq('livekit_room_name', roomName)
    .single()

  if (!meeting) {
    console.error('Meeting not found for room:', roomName)
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get the recording file URL from LiveKit egress result
  let fileUrl: string | null = null
  let fileDuration = 0

  if (fileResults) {
    fileUrl = (fileResults as Record<string, unknown>).download_url as string
    fileDuration = ((fileResults as Record<string, unknown>).duration as number) || 0
  }

  // If LiveKit provides a download URL, fetch and store in Supabase
  if (fileUrl) {
    try {
      const recordingRes = await fetch(fileUrl)
      if (!recordingRes.ok) throw new Error(`Failed to download recording: ${recordingRes.status}`)

      const recordingBlob = await recordingRes.blob()
      const recordingBytes = new Uint8Array(await recordingBlob.arrayBuffer())

      const storagePath = `recordings/${meeting.company_id}/${meeting.id}.mp4`

      const { error: uploadErr } = await supabase.storage
        .from('meeting-recordings')
        .upload(storagePath, recordingBytes, {
          contentType: 'video/mp4',
          upsert: true,
        })

      if (uploadErr) {
        console.error('Failed to upload recording:', uploadErr)
      } else {
        // Update meeting with recording path
        await supabase
          .from('meetings')
          .update({
            recording_path: storagePath,
            recording_duration_seconds: Math.round(fileDuration / 1e9), // nanoseconds to seconds
          })
          .eq('id', meeting.id)
      }
    } catch (err) {
      console.error('Recording download/upload failed:', err)
    }
  }

  return new Response(JSON.stringify({
    success: true,
    meetingId: meeting.id,
    recorded: !!fileUrl,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
