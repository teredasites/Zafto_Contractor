// Supabase Edge Function: estimate-scope-assist
// AI-powered scope analysis: gap detection, photo analysis, supplement generation,
// and pricing dispute letter generation.

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

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!anthropicKey) {
    return new Response(JSON.stringify({ error: 'AI service not configured' }), {
      status: 503,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const { action, claimId, photoBase64, photoMediaType } = body

    if (!action) {
      return new Response(JSON.stringify({ error: 'action required (gap_detection, photo_analysis, supplement, dispute_letter)' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch claim and estimate data for context
    let claimData: Record<string, unknown> | null = null
    let estimateLines: Record<string, unknown>[] = []

    if (claimId) {
      const { data: claim } = await supabase
        .from('insurance_claims')
        .select('*')
        .eq('id', claimId)
        .single()
      claimData = claim

      const { data: lines } = await supabase
        .from('xactimate_estimate_lines')
        .select('*')
        .eq('claim_id', claimId)
        .order('room_name')
        .order('line_number')
      estimateLines = lines || []
    }

    // Build context string from existing estimate
    const estimateContext = estimateLines.map((l, i) =>
      `${i + 1}. [${l.item_code}] ${l.description} — Qty: ${l.quantity} ${l.unit} @ $${l.unit_price} = $${l.total} (${l.room_name || 'Unassigned'}, ${l.coverage_group})`
    ).join('\n')

    const claimContext = claimData ? `
Claim #: ${claimData.claim_number}
Customer: ${claimData.customer_name}
Loss Type: ${(claimData.loss_type as string || '').replace(/_/g, ' ')}
Property: ${claimData.property_address}
Carrier: ${claimData.insurance_carrier}
Date of Loss: ${claimData.date_of_loss}
Status: ${claimData.claim_status}
` : 'No claim data available.'

    let prompt = ''
    const messages: Array<{ role: string; content: unknown }> = []

    // ── Action: Gap Detection ──
    if (action === 'gap_detection') {
      prompt = `You are an expert insurance restoration estimator with deep knowledge of Xactimate codes and standard scopes of work.

Analyze this estimate for a ${(claimData?.loss_type as string || 'unknown').replace(/_/g, ' ')} claim and identify MISSING line items that should be included based on industry standards and the work already scoped.

CLAIM INFO:
${claimContext}

CURRENT ESTIMATE (${estimateLines.length} items):
${estimateContext || 'No line items yet.'}

Identify gaps in this scope. For each missing item, provide:
1. The Xactimate code (e.g., "RFG FELT" for roofing felt)
2. Description
3. Why it's likely missing
4. Estimated quantity (if determinable)
5. Priority: HIGH (insurance will flag as incomplete), MEDIUM (commonly included), LOW (nice to have)

Also flag any items that seem unusual or potentially overbilled.

Return JSON:
{
  "missingItems": [
    {
      "code": "RFG FELT",
      "description": "Roofing felt - 30 lb",
      "reason": "Shingle replacement typically requires underlayment replacement",
      "estimatedQty": null,
      "unit": "SQ",
      "priority": "HIGH"
    }
  ],
  "unusualItems": [
    {
      "lineNumber": 3,
      "code": "RFG SHGL",
      "issue": "Quantity seems high for property size",
      "recommendation": "Verify roof measurement"
    }
  ],
  "overallAssessment": "Brief assessment of scope completeness"
}`

      messages.push({ role: 'user', content: prompt })
    }

    // ── Action: Photo Analysis ──
    else if (action === 'photo_analysis') {
      if (!photoBase64) {
        return new Response(JSON.stringify({ error: 'photoBase64 required for photo_analysis' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      prompt = `You are an expert insurance restoration estimator. Analyze this damage photo and suggest Xactimate line items for the repair scope.

CLAIM CONTEXT:
${claimContext}

EXISTING ESTIMATE:
${estimateContext || 'No line items yet.'}

Based on the visible damage in this photo:
1. Identify the type of damage (water, fire, wind, impact, etc.)
2. Identify affected materials/systems
3. Suggest specific Xactimate codes and line items
4. Note any secondary/hidden damage that should be investigated

Return JSON:
{
  "damageType": "water",
  "affectedAreas": ["ceiling", "drywall", "insulation"],
  "severity": "moderate",
  "suggestedItems": [
    {
      "code": "DRY HANG",
      "description": "Hang drywall - 1/2 inch",
      "reason": "Water-damaged drywall visible in photo",
      "estimatedQty": null,
      "unit": "SF",
      "priority": "HIGH"
    }
  ],
  "investigations": [
    "Check for mold behind damaged drywall",
    "Verify insulation condition above ceiling"
  ],
  "notes": "Additional observations"
}`

      messages.push({
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: photoMediaType || 'image/jpeg',
              data: photoBase64,
            },
          },
          { type: 'text', text: prompt },
        ],
      })
    }

    // ── Action: Supplement Generator ──
    else if (action === 'supplement') {
      const { supplementReason, additionalNotes } = body

      prompt = `You are an expert insurance restoration estimator writing a supplement request for an insurance claim.

CLAIM INFO:
${claimContext}

CURRENT APPROVED ESTIMATE (${estimateLines.length} items):
${estimateContext}

REASON FOR SUPPLEMENT: ${supplementReason || 'Additional damage discovered during repairs'}
ADDITIONAL NOTES: ${additionalNotes || 'None'}

Generate a professional supplement package including:
1. A formal supplement justification narrative (2-3 paragraphs)
2. Suggested additional line items with Xactimate codes
3. Reference to IICRC S500/S520 standards where applicable
4. Explanation of why each item is necessary

Return JSON:
{
  "narrative": "Professional multi-paragraph justification...",
  "additionalItems": [
    {
      "code": "DRY EQMD",
      "description": "Equipment - dehumidifier, per day",
      "quantity": 5,
      "unit": "DAY",
      "reason": "Extended drying required due to concealed moisture in wall cavity"
    }
  ],
  "standardsReferenced": ["IICRC S500 Section 12.3"],
  "estimatedAdditionalCost": 3500.00
}`

      messages.push({ role: 'user', content: prompt })
    }

    // ── Action: Pricing Dispute Letter ──
    else if (action === 'dispute_letter') {
      const { disputeItems, companyName } = body

      // Get ZAFTO pricing for disputed items
      let pricingContext = ''
      if (disputeItems && disputeItems.length > 0) {
        for (const item of disputeItems) {
          pricingContext += `- ${item.code}: Xactimate price $${item.xactPrice}/unit, Market price $${item.marketPrice}/unit (${item.description})\n`
        }
      }

      prompt = `You are a professional insurance restoration contractor writing a pricing dispute letter to an insurance carrier.

CLAIM INFO:
${claimContext}

COMPANY: ${companyName || 'ZAFTO Contractor'}

DISPUTED ITEMS:
${pricingContext || 'General pricing dispute - Xactimate pricing below market rates'}

Write a professional, firm but respectful pricing dispute letter that:
1. References specific line items and the price differential
2. Cites market rate data and industry standards
3. References the contractor's right to fair compensation
4. Requests a pricing review meeting or desk adjuster assignment
5. Maintains a professional tone suitable for formal correspondence

Return JSON:
{
  "letterText": "Full formatted letter text...",
  "subject": "Pricing Dispute - Claim #...",
  "keyPoints": ["Point 1", "Point 2"],
  "suggestedFollowUp": "Recommended next steps"
}`

      messages.push({ role: 'user', content: prompt })
    }

    else {
      return new Response(JSON.stringify({ error: 'Unknown action. Use: gap_detection, photo_analysis, supplement, dispute_letter' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Call Claude API
    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 4096,
        messages,
      }),
    })

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text()
      console.error('Claude API error:', errText)
      return new Response(JSON.stringify({ error: 'AI analysis failed' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const claudeResult = await claudeResponse.json()
    const responseText = claudeResult.content?.[0]?.text || ''

    // Parse JSON from response
    let result: Record<string, unknown>
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON in response')
      result = JSON.parse(jsonMatch[0])
    } catch {
      return new Response(JSON.stringify({
        error: 'Failed to parse AI response',
        rawResponse: responseText.substring(0, 2000),
      }), {
        status: 422,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({
      success: true,
      action,
      result,
      tokenUsage: {
        input: claudeResult.usage?.input_tokens || 0,
        output: claudeResult.usage?.output_tokens || 0,
      },
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Scope assist error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
