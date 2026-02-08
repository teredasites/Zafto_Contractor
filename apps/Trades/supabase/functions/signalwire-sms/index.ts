// Supabase Edge Function: signalwire-sms
// Send + receive SMS via SignalWire
// POST { action: 'send' } — authenticated user sends SMS
// POST ?type=inbound — SignalWire webhook for incoming SMS

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
  const isInbound = url.searchParams.get('type') === 'inbound'

  try {
    // ========================================================================
    // INBOUND SMS WEBHOOK
    // ========================================================================
    if (isInbound) {
      const formData = await req.formData()
      const messageSid = formData.get('MessageSid') as string
      const from = formData.get('From') as string
      const to = formData.get('To') as string
      const body = formData.get('Body') as string
      const numMedia = parseInt(formData.get('NumMedia') as string || '0')

      // Collect media URLs if MMS
      const mediaUrls: string[] = []
      for (let i = 0; i < numMedia; i++) {
        const mediaUrl = formData.get(`MediaUrl${i}`) as string
        if (mediaUrl) mediaUrls.push(mediaUrl)
      }

      // Find the company that owns this number
      const { data: line } = await supabase
        .from('phone_lines')
        .select('company_id, user_id')
        .eq('phone_number', to)
        .eq('is_active', true)
        .single()

      if (!line) {
        console.log(`Inbound SMS to unknown number: ${to}`)
        return new Response('<Response></Response>', {
          headers: { 'Content-Type': 'text/xml' },
        })
      }

      // Match sender to CRM customer
      const { data: customer } = await supabase
        .from('customers')
        .select('id')
        .eq('company_id', line.company_id)
        .or(`phone.eq.${from},mobile.eq.${from},work_phone.eq.${from}`)
        .limit(1)
        .single()

      // Store inbound message
      await supabase.from('phone_messages').insert({
        company_id: line.company_id,
        signalwire_message_id: messageSid,
        direction: 'inbound',
        from_number: from,
        to_number: to,
        customer_id: customer?.id || null,
        body: body || '',
        media_urls: mediaUrls,
        status: 'received',
      })

      console.log(`Inbound SMS from ${from} to ${to}: ${body?.substring(0, 50)}`)

      // Return empty response (no auto-reply by default)
      return new Response('<Response></Response>', {
        headers: { 'Content-Type': 'text/xml' },
      })
    }

    // ========================================================================
    // AUTHENTICATED API — SEND SMS
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

    if (action === 'send') {
      return await handleSendSms(supabase, swBase, swAuth, userData.company_id, user.id, body)
    }

    if (action === 'send_template') {
      return await handleSendTemplate(supabase, swBase, swAuth, userData.company_id, user.id, body)
    }

    return new Response(JSON.stringify({ error: 'Invalid action. Use "send" or "send_template".' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('signalwire-sms error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// SEND SMS
// ============================================================================
async function handleSendSms(
  supabase: ReturnType<typeof createClient>,
  swBase: string,
  swAuth: string,
  companyId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const { toNumber, message, fromLineId, customerId, jobId } = body as {
    toNumber: string
    message: string
    fromLineId?: string
    customerId?: string
    jobId?: string
  }

  if (!toNumber || !message) {
    return new Response(JSON.stringify({ error: 'toNumber and message required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get sender's phone line
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
  const statusCallback = `${SUPABASE_URL}/functions/v1/signalwire-webhook?type=sms_status&company_id=${companyId}`

  // Send via SignalWire
  const smsParams = new URLSearchParams({
    From: line.phone_number,
    To: toNumber,
    Body: message,
    StatusCallback: statusCallback,
  })

  const swResponse = await fetch(`${swBase}/Messages.json`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${swAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: smsParams.toString(),
  })

  const smsData = await swResponse.json()

  if (!swResponse.ok) {
    console.error('SignalWire SMS error:', smsData)
    return new Response(JSON.stringify({ error: 'Failed to send SMS', detail: smsData.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Log the outbound message
  await supabase.from('phone_messages').insert({
    company_id: companyId,
    signalwire_message_id: smsData.sid,
    direction: 'outbound',
    from_number: line.phone_number,
    to_number: toNumber,
    from_user_id: userId,
    customer_id: customerId || null,
    job_id: jobId || null,
    body: message,
    status: 'sent',
  })

  return new Response(JSON.stringify({
    success: true,
    messageSid: smsData.sid,
    from: line.phone_number,
    to: toNumber,
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// SEND TEMPLATE (automated messages)
// ============================================================================
async function handleSendTemplate(
  supabase: ReturnType<typeof createClient>,
  swBase: string,
  swAuth: string,
  companyId: string,
  userId: string,
  body: Record<string, unknown>,
) {
  const { templateId, toNumber, variables, customerId, jobId } = body as {
    templateId: string
    toNumber: string
    variables: Record<string, string>
    customerId?: string
    jobId?: string
  }

  if (!templateId || !toNumber) {
    return new Response(JSON.stringify({ error: 'templateId and toNumber required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get template
  const { data: template } = await supabase
    .from('phone_message_templates')
    .select('*')
    .eq('id', templateId)
    .eq('company_id', companyId)
    .single()

  if (!template) {
    return new Response(JSON.stringify({ error: 'Template not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Replace variables in template: {customer_name} → "John Smith"
  let message = template.body_template
  if (variables) {
    for (const [key, value] of Object.entries(variables)) {
      message = message.replace(new RegExp(`\\{${key}\\}`, 'g'), value)
    }
  }

  // Reuse send logic
  return await handleSendSms(supabase, swBase, swAuth, companyId, userId, {
    toNumber,
    message,
    customerId,
    jobId,
    action: 'send',
  })
}
