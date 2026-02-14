// Supabase Edge Function: signalwire-webhook
// Handles all SignalWire status callbacks: call CDR, SMS delivery, voicemail, recording
// POST with form-encoded data from SignalWire

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const SW_PROJECT = Deno.env.get('SIGNALWIRE_PROJECT_KEY') ?? ''
  const SW_TOKEN = Deno.env.get('SIGNALWIRE_API_TOKEN') ?? ''
  const SW_WEBHOOK_SECRET = Deno.env.get('SIGNALWIRE_WEBHOOK_SECRET') ?? ''
  const swAuth = btoa(`${SW_PROJECT}:${SW_TOKEN}`)

  // Verify webhook secret to prevent forged requests
  const url = new URL(req.url)
  if (SW_WEBHOOK_SECRET) {
    const providedSecret = url.searchParams.get('secret')
    if (providedSecret !== SW_WEBHOOK_SECRET) {
      console.error('Invalid SignalWire webhook secret')
      return new Response('Unauthorized', { status: 401 })
    }
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  const webhookType = url.searchParams.get('type')

  try {
    switch (webhookType) {
      case 'call_status':
        return await handleCallStatus(supabase, req, url)

      case 'dial_status':
        return await handleDialStatus(supabase, req, url)

      case 'voicemail':
        return await handleVoicemail(supabase, req, url, swAuth)

      case 'recording':
        return await handleRecording(supabase, req, swAuth)

      case 'sms_status':
        return await handleSmsStatus(supabase, req)

      default:
        console.log(`Unknown webhook type: ${webhookType}`)
        return new Response('OK', { status: 200 })
    }
  } catch (err) {
    console.error('signalwire-webhook error:', err)
    return new Response('OK', { status: 200 })
  }
})

// ============================================================================
// CALL STATUS (initiated → ringing → in_progress → completed)
// ============================================================================
async function handleCallStatus(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  url: URL,
) {
  const formData = await req.formData()
  const callSid = formData.get('CallSid') as string
  const callStatus = formData.get('CallStatus') as string
  const duration = parseInt(formData.get('CallDuration') as string || '0')
  const companyId = url.searchParams.get('company_id')

  const statusMap: Record<string, string> = {
    'queued': 'initiated',
    'initiated': 'initiated',
    'ringing': 'ringing',
    'in-progress': 'in_progress',
    'completed': 'completed',
    'busy': 'busy',
    'no-answer': 'no_answer',
    'canceled': 'failed',
    'failed': 'failed',
  }

  const mappedStatus = statusMap[callStatus] || callStatus
  const now = new Date().toISOString()

  const updateData: Record<string, unknown> = {
    status: mappedStatus,
  }

  if (callStatus === 'in-progress') {
    updateData.answered_at = now
  }

  if (['completed', 'busy', 'no-answer', 'canceled', 'failed'].includes(callStatus)) {
    updateData.ended_at = now
    updateData.duration_seconds = duration
  }

  await supabase
    .from('phone_calls')
    .update(updateData)
    .eq('signalwire_call_id', callSid)

  console.log(`Call ${callSid} status: ${callStatus} (${duration}s)`)
  return new Response('OK', { status: 200 })
}

// ============================================================================
// DIAL STATUS (after <Dial> completes — determines if answered or voicemail)
// ============================================================================
async function handleDialStatus(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  url: URL,
) {
  const formData = await req.formData()
  const dialCallStatus = formData.get('DialCallStatus') as string
  const callSid = url.searchParams.get('call_sid')
  const companyId = url.searchParams.get('company_id')

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''

  // If nobody answered, send to voicemail
  if (dialCallStatus !== 'completed' && callSid) {
    await supabase
      .from('phone_calls')
      .update({ status: 'voicemail' })
      .eq('signalwire_call_id', callSid)

    // Get the line for voicemail
    const { data: call } = await supabase
      .from('phone_calls')
      .select('to_number')
      .eq('signalwire_call_id', callSid)
      .single()

    const { data: line } = call ? await supabase
      .from('phone_lines')
      .select('id')
      .eq('phone_number', call.to_number)
      .single() : { data: null }

    const from = formData.get('From') as string
    const webhookBase = `${SUPABASE_URL}/functions/v1/signalwire-webhook`

    return new Response(
      `<Response>
        <Say voice="alice">Please leave a message after the tone.</Say>
        <Record maxLength="120" action="${webhookBase}?type=voicemail&line_id=${line?.id}&company_id=${companyId}&from=${from}&call_sid=${callSid}" />
      </Response>`,
      { headers: { 'Content-Type': 'text/xml' } }
    )
  }

  return new Response('<Response></Response>', {
    headers: { 'Content-Type': 'text/xml' },
  })
}

// ============================================================================
// VOICEMAIL (recording completed for voicemail)
// ============================================================================
async function handleVoicemail(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  url: URL,
  swAuth: string,
) {
  const formData = await req.formData()
  const recordingUrl = formData.get('RecordingUrl') as string
  const recordingDuration = parseInt(formData.get('RecordingDuration') as string || '0')
  const lineId = url.searchParams.get('line_id')
  const companyId = url.searchParams.get('company_id')
  const from = url.searchParams.get('from')
  const callSid = url.searchParams.get('call_sid')

  if (!lineId || !companyId || !recordingUrl) {
    return new Response('<Response></Response>', {
      headers: { 'Content-Type': 'text/xml' },
    })
  }

  // Download recording from SignalWire and store in Supabase Storage
  let storagePath = ''
  try {
    const audioResponse = await fetch(`${recordingUrl}.mp3`, {
      headers: { 'Authorization': `Basic ${swAuth}` },
    })
    const audioBuffer = await audioResponse.arrayBuffer()
    const fileName = `voicemails/${companyId}/${Date.now()}_${callSid}.mp3`

    await supabase.storage
      .from('phone-documents')
      .upload(fileName, audioBuffer, {
        contentType: 'audio/mpeg',
        upsert: false,
      })

    storagePath = fileName
  } catch (err) {
    console.error('Failed to store voicemail recording:', err)
    storagePath = recordingUrl // Fallback to SignalWire URL
  }

  // Get call_id from the call record
  let callId = null
  if (callSid) {
    const { data: call } = await supabase
      .from('phone_calls')
      .select('id')
      .eq('signalwire_call_id', callSid)
      .single()
    callId = call?.id
  }

  // Match caller to CRM customer
  let customerId = null
  if (from) {
    const { data: customer } = await supabase
      .from('customers')
      .select('id')
      .eq('company_id', companyId)
      .or(`phone.eq.${from},mobile.eq.${from},work_phone.eq.${from}`)
      .limit(1)
      .single()
    customerId = customer?.id
  }

  // Insert voicemail record
  await supabase.from('phone_voicemails').insert({
    company_id: companyId,
    call_id: callId,
    line_id: lineId,
    from_number: from || 'unknown',
    customer_id: customerId,
    audio_path: storagePath,
    duration_seconds: recordingDuration,
  })

  console.log(`Voicemail saved: ${from} → line ${lineId} (${recordingDuration}s)`)

  return new Response(
    '<Response><Say voice="alice">Thank you for your message. Goodbye.</Say><Hangup/></Response>',
    { headers: { 'Content-Type': 'text/xml' } }
  )
}

// ============================================================================
// RECORDING COMPLETE (call recording, not voicemail)
// ============================================================================
async function handleRecording(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  swAuth: string,
) {
  const formData = await req.formData()
  const callSid = formData.get('CallSid') as string
  const recordingUrl = formData.get('RecordingUrl') as string
  const recordingDuration = parseInt(formData.get('RecordingDuration') as string || '0')

  if (!callSid || !recordingUrl) {
    return new Response('OK', { status: 200 })
  }

  // Get call to find company
  const { data: call } = await supabase
    .from('phone_calls')
    .select('id, company_id')
    .eq('signalwire_call_id', callSid)
    .single()

  if (!call) {
    console.log(`Recording for unknown call: ${callSid}`)
    return new Response('OK', { status: 200 })
  }

  // Download and store recording
  let storagePath = recordingUrl
  try {
    const audioResponse = await fetch(`${recordingUrl}.mp3`, {
      headers: { 'Authorization': `Basic ${swAuth}` },
    })
    const audioBuffer = await audioResponse.arrayBuffer()
    const fileName = `recordings/${call.company_id}/${callSid}.mp3`

    await supabase.storage
      .from('phone-documents')
      .upload(fileName, audioBuffer, {
        contentType: 'audio/mpeg',
        upsert: false,
      })

    storagePath = fileName
  } catch (err) {
    console.error('Failed to store call recording:', err)
  }

  // Update call record with recording path
  await supabase
    .from('phone_calls')
    .update({
      recording_path: storagePath,
      recording_url: recordingUrl,
    })
    .eq('signalwire_call_id', callSid)

  console.log(`Recording stored for call ${callSid}: ${storagePath}`)
  return new Response('OK', { status: 200 })
}

// ============================================================================
// SMS STATUS (delivery receipt)
// ============================================================================
async function handleSmsStatus(
  supabase: ReturnType<typeof createClient>,
  req: Request,
) {
  const formData = await req.formData()
  const messageSid = formData.get('MessageSid') as string
  const messageStatus = formData.get('MessageStatus') as string

  const statusMap: Record<string, string> = {
    'queued': 'queued',
    'sending': 'sent',
    'sent': 'sent',
    'delivered': 'delivered',
    'undelivered': 'failed',
    'failed': 'failed',
  }

  const mappedStatus = statusMap[messageStatus] || messageStatus

  await supabase
    .from('phone_messages')
    .update({ status: mappedStatus })
    .eq('signalwire_message_id', messageSid)

  return new Response('OK', { status: 200 })
}
