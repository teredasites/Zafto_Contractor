// Supabase Edge Function: estimate-parse-pdf
// Accepts a PDF upload (base64), sends to Claude Vision for extraction,
// maps extracted items to xactimate_codes, returns structured line items.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ParsedLineItem {
  code: string
  description: string
  quantity: number
  unit: string
  unitPrice: number
  total: number
  materialCost: number
  laborCost: number
  equipmentCost: number
  room: string
  coverageGroup: string
  depreciationRate: number
}

interface ParseResult {
  claimNumber: string
  customerName: string
  propertyAddress: string
  lossType: string
  dateOfLoss: string
  carrier: string
  policyNumber: string
  adjusterName: string
  items: ParsedLineItem[]
  rawOverhead: number
  rawProfit: number
  rawTotal: number
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
    const { pdfBase64, claimId } = body

    if (!pdfBase64) {
      return new Response(JSON.stringify({ error: 'pdfBase64 required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Call Claude Vision to extract estimate data from PDF
    const extractionPrompt = `You are an expert insurance restoration estimator. Analyze this Xactimate estimate PDF and extract ALL data into structured JSON.

Extract the following:
1. Claim info: claim number, customer name, property address, loss type, date of loss, insurance carrier, policy number, adjuster name
2. ALL line items with: Xactimate code, description, quantity, unit, unit price, total, material cost, labor cost, equipment cost, room/area name, coverage group (structural/contents/other), depreciation rate
3. Summary totals: overhead amount, profit amount, grand total

IMPORTANT:
- Extract EVERY line item, even if across multiple pages
- Xactimate codes look like "RFG SHGL", "DRY EQMD", "PLM BATH" etc.
- Coverage groups: structural (building/construction), contents (personal property), other
- If MAT/LAB/EQU breakdown isn't shown, set them to 0
- If depreciation isn't shown per line, set to 0

Return ONLY valid JSON in this exact format:
{
  "claimNumber": "",
  "customerName": "",
  "propertyAddress": "",
  "lossType": "",
  "dateOfLoss": "",
  "carrier": "",
  "policyNumber": "",
  "adjusterName": "",
  "items": [
    {
      "code": "RFG SHGL",
      "description": "Remove & replace composition shingles",
      "quantity": 25.5,
      "unit": "SQ",
      "unitPrice": 185.50,
      "total": 4730.25,
      "materialCost": 95.00,
      "laborCost": 80.50,
      "equipmentCost": 10.00,
      "room": "Roof",
      "coverageGroup": "structural",
      "depreciationRate": 15
    }
  ],
  "rawOverhead": 1500.00,
  "rawProfit": 1500.00,
  "rawTotal": 18500.00
}`

    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 8192,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'document',
              source: {
                type: 'base64',
                media_type: 'application/pdf',
                data: pdfBase64,
              },
            },
            {
              type: 'text',
              text: extractionPrompt,
            },
          ],
        }],
      }),
    })

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text()
      console.error('Claude API error:', errText)
      return new Response(JSON.stringify({ error: 'AI extraction failed', detail: errText }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const claudeResult = await claudeResponse.json()
    const assistantText = claudeResult.content?.[0]?.text || ''

    // Parse JSON from Claude's response
    let parsed: ParseResult
    try {
      // Extract JSON from response (might be wrapped in markdown code block)
      const jsonMatch = assistantText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      parsed = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('JSON parse error:', parseErr)
      return new Response(JSON.stringify({
        error: 'Failed to parse AI extraction',
        rawResponse: assistantText.substring(0, 2000),
      }), {
        status: 422,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Map extracted codes to our xactimate_codes table
    const extractedCodes = [...new Set(parsed.items.map(i => i.code).filter(Boolean))]
    let codeMap = new Map<string, { id: string; full_code: string }>()

    if (extractedCodes.length > 0) {
      const { data: matchedCodes } = await supabase
        .from('xactimate_codes')
        .select('id, full_code')
        .in('full_code', extractedCodes)

      for (const mc of (matchedCodes || [])) {
        codeMap.set(mc.full_code, mc)
      }
    }

    // Look up ZAFTO pricing for matched codes (for discrepancy detection)
    const matchedCodeIds = Array.from(codeMap.values()).map(c => c.id)
    let pricingMap = new Map<string, { total_cost: number; confidence: string }>()

    if (matchedCodeIds.length > 0) {
      const { data: pricing } = await supabase
        .from('pricing_entries')
        .select('code_id, total_cost, confidence')
        .in('code_id', matchedCodeIds)
        .is('company_id', null)

      for (const p of (pricing || [])) {
        pricingMap.set(p.code_id, p)
      }
    }

    // Enrich items with code matches and price discrepancies
    const enrichedItems = parsed.items.map((item, index) => {
      const matchedCode = codeMap.get(item.code)
      const codeId = matchedCode?.id || null
      const zaftoPrice = codeId ? pricingMap.get(codeId) : null

      let priceDiscrepancy: number | null = null
      let discrepancyPct: number | null = null
      if (zaftoPrice && item.unitPrice > 0) {
        priceDiscrepancy = item.unitPrice - Number(zaftoPrice.total_cost)
        discrepancyPct = (priceDiscrepancy / item.unitPrice) * 100
      }

      return {
        ...item,
        lineNumber: index + 1,
        codeId,
        codeMatched: !!matchedCode,
        zaftoUnitPrice: zaftoPrice ? Number(zaftoPrice.total_cost) : null,
        zaftoConfidence: zaftoPrice?.confidence || null,
        priceDiscrepancy,
        discrepancyPct,
      }
    })

    // Return enriched results for review
    return new Response(JSON.stringify({
      success: true,
      claimInfo: {
        claimNumber: parsed.claimNumber,
        customerName: parsed.customerName,
        propertyAddress: parsed.propertyAddress,
        lossType: parsed.lossType,
        dateOfLoss: parsed.dateOfLoss,
        carrier: parsed.carrier,
        policyNumber: parsed.policyNumber,
        adjusterName: parsed.adjusterName,
      },
      items: enrichedItems,
      summary: {
        lineCount: enrichedItems.length,
        matchedCodes: enrichedItems.filter(i => i.codeMatched).length,
        unmatchedCodes: enrichedItems.filter(i => !i.codeMatched).length,
        rawOverhead: parsed.rawOverhead,
        rawProfit: parsed.rawProfit,
        rawTotal: parsed.rawTotal,
        itemsWithDiscrepancy: enrichedItems.filter(i => i.priceDiscrepancy !== null && Math.abs(i.priceDiscrepancy) > 0.01).length,
      },
      tokenUsage: {
        input: claudeResult.usage?.input_tokens || 0,
        output: claudeResult.usage?.output_tokens || 0,
      },
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Parse PDF error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
