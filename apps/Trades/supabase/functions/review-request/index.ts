// Supabase Edge Function: review-request
// Send review requests via SMS (SignalWire) and/or Email (SendGrid)
// POST { action: 'send', review_request_id: string }
// POST { action: 'submit_rating', review_request_id: string, rating: number, feedback?: string }

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
    const body = await req.json()
    const { action } = body

    if (action === 'send') {
      return await handleSendReview(req, supabase, body)
    }

    if (action === 'submit_rating') {
      return await handleSubmitRating(supabase, body)
    }

    return new Response(JSON.stringify({ error: 'Invalid action. Use "send" or "submit_rating".' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('review-request error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// SEND REVIEW REQUEST
// ============================================================================
async function handleSendReview(
  req: Request,
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  // Authenticate caller
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

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company found' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const reviewRequestId = body.review_request_id as string
  if (!reviewRequestId) {
    return new Response(JSON.stringify({ error: 'review_request_id required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch the review request with customer and job details
  const { data: request, error: fetchErr } = await supabase
    .from('review_requests')
    .select('*, customers(first_name, last_name, email, phone, mobile), jobs(title)')
    .eq('id', reviewRequestId)
    .eq('company_id', companyId)
    .single()

  if (fetchErr || !request) {
    return new Response(JSON.stringify({ error: 'Review request not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (request.status !== 'pending') {
    return new Response(JSON.stringify({ error: `Cannot send — status is ${request.status}` }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get company review settings and name
  const { data: company } = await supabase
    .from('companies')
    .select('name, review_settings')
    .eq('id', companyId)
    .single()

  const settings = company?.review_settings || {}
  const companyName = company?.name || 'Our Company'
  const customer = request.customers as Record<string, unknown> | null
  const customerName = customer ? `${customer.first_name || ''} ${customer.last_name || ''}`.trim() : 'Valued Customer'
  const customerEmail = customer?.email as string | null
  const customerPhone = (customer?.phone || customer?.mobile) as string | null
  const jobTitle = (request.jobs as Record<string, unknown>)?.title || 'your recent project'
  const reviewUrl = request.review_url || settings.google_review_url || ''

  // Template variable substitution
  const replaceVars = (template: string) => {
    return template
      .replace(/\{customer_name\}/g, customerName)
      .replace(/\{company_name\}/g, companyName)
      .replace(/\{job_title\}/g, jobTitle)
      .replace(/\{review_url\}/g, reviewUrl)
  }

  const channel = request.channel as string
  let smsSent = false
  let emailSent = false
  const errors: string[] = []

  // Send SMS via SignalWire
  if ((channel === 'sms' || channel === 'both') && customerPhone) {
    const smsTemplate = settings.template_sms ||
      'Hi {customer_name}, thank you for choosing {company_name}! We\'d love your feedback: {review_url}'
    const smsBody = replaceVars(smsTemplate)

    try {
      const SW_SPACE = Deno.env.get('SIGNALWIRE_SPACE_NAME') ?? ''
      const SW_PROJECT = Deno.env.get('SIGNALWIRE_PROJECT_KEY') ?? ''
      const SW_TOKEN = Deno.env.get('SIGNALWIRE_API_TOKEN') ?? ''

      if (SW_SPACE && SW_PROJECT && SW_TOKEN) {
        const swBase = `https://${SW_SPACE}.signalwire.com/api/laml/2010-04-01/Accounts/${SW_PROJECT}`
        const swAuth = btoa(`${SW_PROJECT}:${SW_TOKEN}`)

        // Get company phone line for sending
        const { data: line } = await supabase
          .from('phone_lines')
          .select('phone_number')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .limit(1)
          .single()

        if (line?.phone_number) {
          const smsParams = new URLSearchParams({
            From: line.phone_number,
            To: customerPhone,
            Body: smsBody,
          })

          const swResponse = await fetch(`${swBase}/Messages.json`, {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${swAuth}`,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: smsParams.toString(),
          })

          if (swResponse.ok) {
            smsSent = true
          } else {
            const swErr = await swResponse.json()
            errors.push(`SMS failed: ${swErr.message || 'Unknown error'}`)
          }
        } else {
          errors.push('SMS failed: No phone line assigned to company')
        }
      } else {
        errors.push('SMS failed: SignalWire not configured')
      }
    } catch (smsErr) {
      errors.push(`SMS error: ${smsErr instanceof Error ? smsErr.message : 'Unknown'}`)
    }
  }

  // Send Email via SendGrid
  if ((channel === 'email' || channel === 'both') && customerEmail) {
    const emailTemplate = settings.template_email ||
      'Hi {customer_name},\n\nThank you for choosing {company_name}. We\'d appreciate your feedback:\n{review_url}\n\nThank you!\n{company_name}'
    const emailBody = replaceVars(emailTemplate)

    try {
      const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')

      if (SENDGRID_API_KEY) {
        const sgResponse = await fetch('https://api.sendgrid.com/v3/mail/send', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${SENDGRID_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            personalizations: [{
              to: [{ email: customerEmail, name: customerName }],
            }],
            from: { email: `reviews@${companyName.toLowerCase().replace(/\s+/g, '')}.zafto.cloud`, name: companyName },
            subject: `How was your experience with ${companyName}?`,
            content: [
              { type: 'text/plain', value: emailBody },
              { type: 'text/html', value: emailBody.replace(/\n/g, '<br>') },
            ],
          }),
        })

        if (sgResponse.ok || sgResponse.status === 202) {
          emailSent = true
        } else {
          const sgErr = await sgResponse.text()
          errors.push(`Email failed: ${sgErr}`)
        }
      } else {
        errors.push('Email failed: SendGrid not configured')
      }
    } catch (emailErr) {
      errors.push(`Email error: ${emailErr instanceof Error ? emailErr.message : 'Unknown'}`)
    }
  }

  // Update review request status
  const newStatus = (smsSent || emailSent) ? 'sent' : 'failed'
  await supabase
    .from('review_requests')
    .update({
      status: newStatus,
      sent_at: newStatus === 'sent' ? new Date().toISOString() : null,
    })
    .eq('id', reviewRequestId)

  return new Response(JSON.stringify({
    success: newStatus === 'sent',
    status: newStatus,
    sms_sent: smsSent,
    email_sent: emailSent,
    errors: errors.length > 0 ? errors : undefined,
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// ============================================================================
// SUBMIT RATING (from client portal — no auth required, uses request ID)
// ============================================================================
async function handleSubmitRating(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const reviewRequestId = body.review_request_id as string
  const rating = body.rating as number
  const feedback = body.feedback as string | undefined

  if (!reviewRequestId || !rating || rating < 1 || rating > 5) {
    return new Response(JSON.stringify({ error: 'review_request_id and rating (1-5) required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch the request to get review URL
  const { data: request, error: fetchErr } = await supabase
    .from('review_requests')
    .select('review_url, review_platform, company_id')
    .eq('id', reviewRequestId)
    .single()

  if (fetchErr || !request) {
    return new Response(JSON.stringify({ error: 'Review request not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Update the review request
  await supabase
    .from('review_requests')
    .update({
      rating_received: rating,
      feedback_text: feedback || null,
      status: 'completed',
      completed_at: new Date().toISOString(),
    })
    .eq('id', reviewRequestId)

  // If rating >= 4, redirect to public review page
  const redirectUrl = rating >= 4 ? (request.review_url || null) : null

  return new Response(JSON.stringify({
    success: true,
    redirect_url: redirectUrl,
    message: rating >= 4
      ? 'Thank you! We\'d love if you shared your experience publicly.'
      : 'Thank you for your feedback. We\'ll use it to improve our service.',
  }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
