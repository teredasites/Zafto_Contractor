// Supabase Edge Function: signalwire-fax
// Send fax (PDF → SignalWire) + receive fax webhook (auto-PDF → Storage)
// POST { action: 'send' } — authenticated user sends fax
// POST ?type=inbound — SignalWire webhook for incoming fax
// POST ?type=status — SignalWire webhook for fax status updates

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
  const webhookType = url.searchParams.get('type')

  try {
    // ========================================================================
    // INBOUND FAX WEBHOOK
    // ========================================================================
    if (webhookType === 'inbound') {
      // SEC-AUDIT-4: Verify inbound webhook secret — fail-closed
      const SW_INBOUND_SECRET = Deno.env.get('SIGNALWIRE_INBOUND_SECRET') ?? ''
      if (!SW_INBOUND_SECRET) {
        console.error('SIGNALWIRE_INBOUND_SECRET not configured — rejecting inbound fax')
        return new Response('Internal error', { status: 500 })
      }
      const providedSecret = req.headers.get('x-signalwire-inbound-secret') || url.searchParams.get('inbound_secret')
      if (providedSecret !== SW_INBOUND_SECRET) {
        console.error('Invalid SignalWire inbound webhook secret')
        return new Response('Unauthorized', { status: 401 })
      }

      const formData = await req.formData()
      const faxSid = formData.get('FaxSid') as string
      const from = formData.get('From') as string
      const to = formData.get('To') as string
      const mediaUrl = formData.get('MediaUrl') as string
      const numPages = parseInt(formData.get('NumPages') as string || '0')

      // Find company for this number
      const { data: line } = await supabase
        .from('phone_lines')
        .select('company_id')
        .eq('phone_number', to)
        .eq('is_active', true)
        .single()

      if (!line) {
        console.log(`Inbound fax to unknown number: ${to}`)
        return new Response('OK', { status: 200 })
      }

      // Download fax PDF from SignalWire and upload to Supabase Storage
      let storagePath = ''
      if (mediaUrl) {
        const pdfResponse = await fetch(mediaUrl, {
          headers: { 'Authorization': `Basic ${swAuth}` },
        })
        const pdfBuffer = await pdfResponse.arrayBuffer()
        const fileName = `faxes/${line.company_id}/${faxSid}.pdf`

        await supabase.storage
          .from('phone-documents')
          .upload(fileName, pdfBuffer, {
            contentType: 'application/pdf',
            upsert: false,
          })

        storagePath = fileName
      }

      // Match sender to CRM customer
      const { data: customer } = await supabase
        .from('customers')
        .select('id')
        .eq('company_id', line.company_id)
        .or(`phone.eq.${from},fax.eq.${from},work_phone.eq.${from}`)
        .limit(1)
        .single()

      // Log inbound fax
      await supabase.from('phone_faxes').insert({
        company_id: line.company_id,
        signalwire_fax_id: faxSid,
        direction: 'inbound',
        from_number: from,
        to_number: to,
        customer_id: customer?.id || null,
        pages: numPages,
        document_path: storagePath,
        status: 'received',
      })

      console.log(`Inbound fax from ${from}: ${numPages} pages → ${storagePath}`)
      return new Response('OK', { status: 200 })
    }

    // ========================================================================
    // FAX STATUS WEBHOOK
    // ========================================================================
    if (webhookType === 'status') {
      const formData = await req.formData()
      const faxSid = formData.get('FaxSid') as string
      const faxStatus = formData.get('FaxStatus') as string

      const statusMap: Record<string, string> = {
        'queued': 'queued',
        'processing': 'sending',
        'sending': 'sending',
        'delivered': 'delivered',
        'receiving': 'sending',
        'received': 'received',
        'no-answer': 'failed',
        'busy': 'failed',
        'failed': 'failed',
        'canceled': 'failed',
      }

      const mappedStatus = statusMap[faxStatus] || 'failed'
      const errorMessage = ['no-answer', 'busy', 'failed', 'canceled'].includes(faxStatus)
        ? `Fax ${faxStatus}`
        : null

      await supabase
        .from('phone_faxes')
        .update({
          status: mappedStatus,
          ...(errorMessage ? { error_message: errorMessage } : {}),
        })
        .eq('signalwire_fax_id', faxSid)

      return new Response('OK', { status: 200 })
    }

    // ========================================================================
    // AUTHENTICATED API — SEND FAX
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

    if (body.action !== 'send') {
      return new Response(JSON.stringify({ error: 'Invalid action. Use "send".' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { toNumber, documentUrl, fromLineId, customerId, jobId, sourceType, sourceId } = body as {
      toNumber: string
      documentUrl: string
      fromLineId?: string
      customerId?: string
      jobId?: string
      sourceType?: string
      sourceId?: string
    }

    if (!toNumber || !documentUrl) {
      return new Response(JSON.stringify({ error: 'toNumber and documentUrl required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get fax line (prefer fax-type line, fallback to user's main line)
    let lineQuery = supabase
      .from('phone_lines')
      .select('*')
      .eq('company_id', userData.company_id)
      .eq('is_active', true)

    if (fromLineId) {
      lineQuery = supabase.from('phone_lines').select('*').eq('id', fromLineId).single()
    } else {
      lineQuery = lineQuery.eq('line_type', 'fax').limit(1).single()
    }

    let { data: line } = await lineQuery

    // Fallback to user's direct line if no fax line
    if (!line && !fromLineId) {
      const { data: directLine } = await supabase
        .from('phone_lines')
        .select('*')
        .eq('user_id', user.id)
        .eq('company_id', userData.company_id)
        .eq('is_active', true)
        .limit(1)
        .single()
      line = directLine
    }

    if (!line) {
      return new Response(JSON.stringify({ error: 'No fax line available' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const statusCallback = `${SUPABASE_URL}/functions/v1/signalwire-fax?type=status`

    // Send fax via SignalWire
    const faxParams = new URLSearchParams({
      From: line.phone_number,
      To: toNumber,
      MediaUrl: documentUrl,
      StatusCallback: statusCallback,
    })

    const swResponse = await fetch(`${swBase}/Faxes.json`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${swAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: faxParams.toString(),
    })

    const faxData = await swResponse.json()

    if (!swResponse.ok) {
      console.error('SignalWire fax error:', faxData)
      return new Response(JSON.stringify({ error: 'Failed to send fax', detail: faxData.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Log outbound fax
    await supabase.from('phone_faxes').insert({
      company_id: userData.company_id,
      signalwire_fax_id: faxData.sid,
      direction: 'outbound',
      from_number: line.phone_number,
      to_number: toNumber,
      from_user_id: user.id,
      customer_id: customerId || null,
      job_id: jobId || null,
      document_url: documentUrl,
      source_type: sourceType || null,
      source_id: sourceId || null,
      status: 'queued',
    })

    return new Response(JSON.stringify({
      success: true,
      faxSid: faxData.sid,
      from: line.phone_number,
      to: toNumber,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('signalwire-fax error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
