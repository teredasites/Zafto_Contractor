// Supabase Edge Function: meeting-capture
// Save freeze-frames, photos, and annotations from video meetings
// POST { action: 'capture' | 'annotate' | 'list' }

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
      .select('company_id, name')
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
      case 'capture':
        return await handleCapture(supabase, userData, user.id, body)
      case 'list':
        return await handleList(supabase, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('meeting-capture error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function handleCapture(
  supabase: ReturnType<typeof createClient>,
  userData: { company_id: string; name: string },
  userId: string,
  body: Record<string, unknown>,
) {
  const {
    meetingId,
    captureType,
    imageData,
    annotationData,
    note,
    timestampInMeeting,
  } = body as {
    meetingId: string
    captureType: string
    imageData?: string // base64 encoded image
    annotationData?: Record<string, unknown>
    note?: string
    timestampInMeeting?: number
  }

  if (!meetingId || !captureType) {
    return new Response(JSON.stringify({ error: 'meetingId and captureType required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Verify meeting exists and belongs to company
  const { data: meeting } = await supabase
    .from('meetings')
    .select('id, company_id, job_id')
    .eq('id', meetingId)
    .eq('company_id', userData.company_id)
    .single()

  if (!meeting) {
    return new Response(JSON.stringify({ error: 'Meeting not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  let filePath: string | null = null
  let thumbnailPath: string | null = null

  // Upload image to storage if provided
  if (imageData) {
    const base64Data = imageData.replace(/^data:image\/\w+;base64,/, '')
    const imageBytes = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0))

    const timestamp = Date.now()
    filePath = `captures/${meeting.company_id}/${meetingId}/${captureType}_${timestamp}.png`

    const { error: uploadErr } = await supabase.storage
      .from('meeting-captures')
      .upload(filePath, imageBytes, {
        contentType: 'image/png',
        upsert: false,
      })

    if (uploadErr) {
      console.error('Failed to upload capture:', uploadErr)
      return new Response(JSON.stringify({ error: 'Failed to upload capture' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  }

  // Insert capture record
  const { data: capture, error: insertErr } = await supabase
    .from('meeting_captures')
    .insert({
      company_id: userData.company_id,
      meeting_id: meetingId,
      job_id: meeting.job_id,
      capture_type: captureType,
      timestamp_in_meeting: timestampInMeeting || null,
      file_path: filePath,
      thumbnail_path: thumbnailPath,
      annotation_data: annotationData || null,
      note: note || null,
      captured_by: userId,
      linked_to_job_photos: !!meeting.job_id,
    })
    .select()
    .single()

  if (insertErr) {
    console.error('Failed to insert capture:', insertErr)
    return new Response(JSON.stringify({ error: 'Failed to save capture' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // If linked to a job, also create a job photo record
  if (meeting.job_id && filePath) {
    await supabase.from('job_photos').insert({
      company_id: userData.company_id,
      job_id: meeting.job_id,
      file_path: filePath,
      photo_type: captureType === 'freeze_frame' ? 'progress' : 'documentation',
      caption: note || `Meeting capture: ${captureType.replace('_', ' ')}`,
      uploaded_by: userId,
    }).catch(() => {
      // Best effort — job_photos table might not exist yet
    })
  }

  return new Response(JSON.stringify({
    success: true,
    captureId: capture.id,
    filePath,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

async function handleList(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { meetingId } = body as { meetingId: string }

  if (!meetingId) {
    return new Response(JSON.stringify({ error: 'meetingId required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const { data: captures, error } = await supabase
    .from('meeting_captures')
    .select('*')
    .eq('meeting_id', meetingId)
    .order('created_at', { ascending: true })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ captures: captures || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
