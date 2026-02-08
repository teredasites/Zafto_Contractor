// Supabase Edge Function: signalwire-ai-receptionist
// AI answers calls when nobody picks up — STT → Claude → TTS
// Called from signalwire-voice when AI receptionist is enabled
// POST (LaML callback from SignalWire with speech recognition result)

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? ''

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  const url = new URL(req.url)
  const companyId = url.searchParams.get('company_id')
  const callSid = url.searchParams.get('call_sid')
  const step = url.searchParams.get('step') || 'greet'

  try {
    if (!companyId) {
      return new Response('<Response><Say>Sorry, an error occurred.</Say><Hangup/></Response>', {
        headers: { 'Content-Type': 'text/xml' },
      })
    }

    // Get company config + AI receptionist settings
    const { data: config } = await supabase
      .from('phone_config')
      .select('ai_receptionist_enabled, ai_receptionist_config')
      .eq('company_id', companyId)
      .single()

    if (!config?.ai_receptionist_enabled) {
      return new Response(
        '<Response><Say voice="alice">Please leave a message after the tone.</Say><Record maxLength="120" /></Response>',
        { headers: { 'Content-Type': 'text/xml' } }
      )
    }

    // Get company info for context
    const { data: company } = await supabase
      .from('companies')
      .select('name, phone, address, city, state')
      .eq('id', companyId)
      .single()

    const companyName = company?.name || 'our company'
    const webhookBase = `${SUPABASE_URL}/functions/v1/signalwire-ai-receptionist`

    // ========================================================================
    // STEP 1: GREET
    // ========================================================================
    if (step === 'greet') {
      return new Response(
        `<Response>
          <Gather input="speech" speechTimeout="3" action="${webhookBase}?step=respond&company_id=${companyId}&call_sid=${callSid}" timeout="10">
            <Say voice="alice">Hi, thanks for calling ${companyName}! I'm the virtual assistant. How can I help you today?</Say>
          </Gather>
          <Say voice="alice">I didn't catch that. Please leave a message after the tone.</Say>
          <Record maxLength="120" />
        </Response>`,
        { headers: { 'Content-Type': 'text/xml' } }
      )
    }

    // ========================================================================
    // STEP 2: RESPOND (process speech, generate response via Claude)
    // ========================================================================
    if (step === 'respond') {
      const formData = await req.formData()
      const speechResult = formData.get('SpeechResult') as string
      const confidence = parseFloat(formData.get('Confidence') as string || '0')

      if (!speechResult || confidence < 0.3) {
        return new Response(
          `<Response>
            <Gather input="speech" speechTimeout="3" action="${webhookBase}?step=respond&company_id=${companyId}&call_sid=${callSid}" timeout="10">
              <Say voice="alice">I'm sorry, I didn't quite catch that. Could you repeat that please?</Say>
            </Gather>
            <Say voice="alice">Please leave a message after the tone.</Say>
            <Record maxLength="120" />
          </Response>`,
          { headers: { 'Content-Type': 'text/xml' } }
        )
      }

      // Call Claude to generate response
      const aiResponse = await generateAiResponse(ANTHROPIC_API_KEY, companyName, speechResult, config.ai_receptionist_config)

      // Continue conversation or end
      if (aiResponse.shouldCollectInfo) {
        return new Response(
          `<Response>
            <Gather input="speech" speechTimeout="3" action="${webhookBase}?step=collect&company_id=${companyId}&call_sid=${callSid}" timeout="10">
              <Say voice="alice">${aiResponse.message}</Say>
            </Gather>
            <Say voice="alice">Please leave a message after the tone.</Say>
            <Record maxLength="120" />
          </Response>`,
          { headers: { 'Content-Type': 'text/xml' } }
        )
      }

      return new Response(
        `<Response>
          <Say voice="alice">${aiResponse.message}</Say>
          <Say voice="alice">Is there anything else I can help you with?</Say>
          <Gather input="speech" speechTimeout="3" action="${webhookBase}?step=respond&company_id=${companyId}&call_sid=${callSid}" timeout="8">
            <Pause length="1"/>
          </Gather>
          <Say voice="alice">Thank you for calling ${companyName}. Have a great day!</Say>
          <Hangup/>
        </Response>`,
        { headers: { 'Content-Type': 'text/xml' } }
      )
    }

    // ========================================================================
    // STEP 3: COLLECT (capture lead info — name, phone, what they need)
    // ========================================================================
    if (step === 'collect') {
      const formData = await req.formData()
      const speechResult = formData.get('SpeechResult') as string
      const from = formData.get('From') as string || url.searchParams.get('from') || ''

      // Use Claude to extract info and create lead
      if (speechResult) {
        const extracted = await extractLeadInfo(ANTHROPIC_API_KEY, speechResult)

        if (extracted.name) {
          await supabase.from('leads').insert({
            company_id: companyId,
            name: extracted.name,
            phone: from,
            source: 'ai_receptionist',
            stage: 'new',
            notes: `AI Receptionist: ${extracted.intent || speechResult}`,
          })
        }
      }

      return new Response(
        `<Response>
          <Say voice="alice">Got it! I've noted your information and someone from our team will get back to you shortly. Thank you for calling ${companyName}!</Say>
          <Hangup/>
        </Response>`,
        { headers: { 'Content-Type': 'text/xml' } }
      )
    }

    // Default fallback
    return new Response(
      '<Response><Say voice="alice">Thank you for calling. Goodbye.</Say><Hangup/></Response>',
      { headers: { 'Content-Type': 'text/xml' } }
    )
  } catch (err) {
    console.error('AI receptionist error:', err)
    return new Response(
      '<Response><Say voice="alice">Sorry, I encountered an error. Please leave a message after the tone.</Say><Record maxLength="120" /></Response>',
      { headers: { 'Content-Type': 'text/xml' } }
    )
  }
})

// ============================================================================
// CLAUDE AI — Generate conversational response
// ============================================================================
async function generateAiResponse(
  apiKey: string,
  companyName: string,
  userSpeech: string,
  config: Record<string, unknown> | null,
): Promise<{ message: string; shouldCollectInfo: boolean }> {
  if (!apiKey) {
    return { message: "I'd be happy to help! Can I get your name and what you're looking for so our team can follow up?", shouldCollectInfo: true }
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 200,
        system: `You are a friendly AI receptionist for ${companyName}, a contractor business. Keep responses brief (1-2 sentences) for phone conversation. Be warm and professional. If the caller needs service/estimate/appointment, collect their name and what they need. Respond with JSON: {"message": "your response", "shouldCollectInfo": true/false}`,
        messages: [{ role: 'user', content: userSpeech }],
      }),
    })

    const result = await response.json()
    const text = result.content?.[0]?.text || ''

    try {
      return JSON.parse(text)
    } catch {
      return { message: text.substring(0, 200), shouldCollectInfo: false }
    }
  } catch (err) {
    console.error('Claude API error:', err)
    return { message: "I'd be happy to help! Can I get your name and number so our team can follow up?", shouldCollectInfo: true }
  }
}

// ============================================================================
// CLAUDE AI — Extract lead info from speech
// ============================================================================
async function extractLeadInfo(
  apiKey: string,
  speech: string,
): Promise<{ name: string | null; intent: string | null }> {
  if (!apiKey) return { name: null, intent: speech }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 100,
        system: 'Extract the caller\'s name and what they need from their speech. Respond with JSON: {"name": "their name or null", "intent": "what they need"}',
        messages: [{ role: 'user', content: speech }],
      }),
    })

    const result = await response.json()
    const text = result.content?.[0]?.text || ''
    return JSON.parse(text)
  } catch {
    return { name: null, intent: speech }
  }
}
