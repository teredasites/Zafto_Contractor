// Supabase Edge Function: signalwire-voice
// Handles inbound call routing + outbound call initiation via SignalWire
// POST { action: 'call' | 'answer' | 'hangup' | 'transfer' }
// Also serves as webhook target for inbound calls (returns LaML)

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

  const SW_SPACE = Deno.env.get('SIGNALWIRE_SPACE_NAME') ?? ''
  const SW_PROJECT = Deno.env.get('SIGNALWIRE_PROJECT_KEY') ?? ''
  const SW_TOKEN = Deno.env.get('SIGNALWIRE_API_TOKEN') ?? ''
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
  const swBase = `https://${SW_SPACE}.signalwire.com/api/laml/2010-04-01/Accounts/${SW_PROJECT}`
  const swAuth = btoa(`${SW_PROJECT}:${SW_TOKEN}`)

  const url = new URL(req.url)
  const isWebhook = url.searchParams.get('type') === 'inbound'

  try {
    // ========================================================================
    // INBOUND CALL WEBHOOK (SignalWire hits this URL when a call comes in)
    // Returns LaML XML for call routing
    // ========================================================================
    if (isWebhook) {
      const formData = await req.formData()
      const callSid = formData.get('CallSid') as string
      const from = formData.get('From') as string
      const to = formData.get('To') as string
      const callStatus = formData.get('CallStatus') as string

      // Look up which company owns this number
      const { data: line } = await supabase
        .from('phone_lines')
        .select('*, company_id')
        .eq('phone_number', to)
        .eq('is_active', true)
        .single()

      if (!line) {
        // Unknown number — reject
        return new Response(
          '<Response><Reject reason="rejected"/></Response>',
          { headers: { 'Content-Type': 'text/xml' } }
        )
      }

      // Look up caller in CRM
      const { data: customer } = await supabase
        .from('customers')
        .select('id, name')
        .eq('company_id', line.company_id)
        .or(`phone.eq.${from},mobile.eq.${from},work_phone.eq.${from}`)
        .limit(1)
        .single()

      // Log the inbound call
      await supabase.from('phone_calls').insert({
        company_id: line.company_id,
        signalwire_call_id: callSid,
        direction: 'inbound',
        from_number: from,
        to_number: to,
        to_user_id: line.user_id,
        customer_id: customer?.id || null,
        status: 'ringing',
        started_at: new Date().toISOString(),
      })

      // Get company phone config for routing
      const { data: config } = await supabase
        .from('phone_config')
        .select('*')
        .eq('company_id', line.company_id)
        .single()

      // Route based on line type
      if (line.line_type === 'main' && config?.auto_attendant_enabled) {
        return buildAutoAttendantLaml(config)
      }

      // Direct line — ring the user
      if (line.user_id && !line.dnd_enabled) {
        // Ring the user's line, fallback to voicemail after 30s
        const webhookBase = `${SUPABASE_URL}/functions/v1/signalwire-webhook`
        return new Response(
          `<Response>
            <Dial timeout="30" callerId="${to}" action="${webhookBase}?type=dial_status&company_id=${line.company_id}&call_sid=${callSid}">
              <Number>${line.phone_number}</Number>
            </Dial>
            <Say voice="alice">Please leave a message after the tone.</Say>
            <Record maxLength="120" action="${webhookBase}?type=voicemail&line_id=${line.id}&company_id=${line.company_id}&from=${from}&call_sid=${callSid}" />
          </Response>`,
          { headers: { 'Content-Type': 'text/xml' } }
        )
      }

      // DND or unassigned — voicemail
      const webhookBase = `${SUPABASE_URL}/functions/v1/signalwire-webhook`
      return new Response(
        `<Response>
          <Say voice="alice">The person you are trying to reach is unavailable. Please leave a message after the tone.</Say>
          <Record maxLength="120" action="${webhookBase}?type=voicemail&line_id=${line.id}&company_id=${line.company_id}&from=${from}&call_sid=${callSid}" />
        </Response>`,
        { headers: { 'Content-Type': 'text/xml' } }
      )
    }

    // ========================================================================
    // AUTHENTICATED API CALLS (from app)
    // ========================================================================
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

    // Get user's company + phone line
    const { data: userData } = await supabase
      .from('users')
      .select('company_id')
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
      case 'call':
        return await handleOutboundCall(supabase, swBase, swAuth, userData.company_id, user.id, body)
      case 'hangup':
        return await handleHangup(swBase, swAuth, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('signalwire-voice error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// OUTBOUND CALL
// ============================================================================
async function handleOutboundCall(
  supabase: ReturnType<typeof createClient>,
  swBase: string,
  swAuth: string,
  companyId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const { toNumber, fromLineId, customerId, jobId } = body as {
    toNumber: string
    fromLineId?: string
    customerId?: string
    jobId?: string
  }

  if (!toNumber) {
    return new Response(JSON.stringify({ error: 'toNumber required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get caller's phone line
  const lineQuery = fromLineId
    ? supabase.from('phone_lines').select('*').eq('id', fromLineId).single()
    : supabase.from('phone_lines').select('*').eq('user_id', userId).eq('company_id', companyId).eq('is_active', true).limit(1).single()

  const { data: line } = await lineQuery
  if (!line) {
    return new Response(JSON.stringify({ error: 'No phone line assigned' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const statusCallback = `${SUPABASE_URL}/functions/v1/signalwire-webhook?type=call_status&company_id=${companyId}`

  // Initiate call via SignalWire REST API
  const callParams = new URLSearchParams({
    From: line.phone_number,
    To: toNumber,
    Url: `${SUPABASE_URL}/functions/v1/signalwire-voice?type=outbound_connect`,
    StatusCallback: statusCallback,
    StatusCallbackEvent: 'initiated ringing answered completed',
  })

  const swResponse = await fetch(`${swBase}/Calls.json`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${swAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: callParams.toString(),
  })

  const callData = await swResponse.json()

  if (!swResponse.ok) {
    console.error('SignalWire call error:', callData)
    return new Response(JSON.stringify({ error: 'Failed to initiate call', detail: callData.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Log the outbound call
  await supabase.from('phone_calls').insert({
    company_id: companyId,
    signalwire_call_id: callData.sid,
    direction: 'outbound',
    from_number: line.phone_number,
    to_number: toNumber,
    from_user_id: userId,
    customer_id: customerId || null,
    job_id: jobId || null,
    status: 'initiated',
    started_at: new Date().toISOString(),
  })

  return new Response(JSON.stringify({
    success: true,
    callSid: callData.sid,
    from: line.phone_number,
    to: toNumber,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// HANGUP
// ============================================================================
async function handleHangup(
  swBase: string,
  swAuth: string,
  body: Record<string, unknown>,
) {
  const { callSid } = body as { callSid: string }
  if (!callSid) {
    return new Response(JSON.stringify({ error: 'callSid required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  await fetch(`${swBase}/Calls/${callSid}.json`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${swAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'Status=completed',
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// AUTO-ATTENDANT LaML
// ============================================================================
function buildAutoAttendantLaml(config: Record<string, unknown>) {
  const greeting = (config.greeting_text as string) || 'Thank you for calling. Please hold.'
  const menuOptions = (config.menu_options as Array<{ key: string; label: string; action: string; target: string }>) || []

  let gatherBody = `<Say voice="alice">${greeting}</Say>`
  if (menuOptions.length === 0) {
    gatherBody = `<Say voice="alice">${greeting} Please hold while we connect you.</Say>`
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const companyId = config.company_id as string

  return new Response(
    `<Response>
      <Gather numDigits="1" action="${SUPABASE_URL}/functions/v1/signalwire-voice?type=menu_selection&company_id=${companyId}" timeout="10">
        ${gatherBody}
      </Gather>
      <Say voice="alice">We didn't receive any input. Goodbye.</Say>
    </Response>`,
    { headers: { 'Content-Type': 'text/xml' } }
  )
}
