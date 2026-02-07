// Supabase Edge Function: ai-troubleshoot
// Multi-trade diagnostics engine. Takes a trade, issue description, and optional context.
// Returns structured diagnosis with code references, safety warnings, and troubleshooting steps.
// POST { trade: string, issue: string, context?: { equipment_brand, equipment_model, building_type, region } }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TroubleshootContext {
  equipment_brand?: string
  equipment_model?: string
  building_type?: string
  region?: string
}

interface TroubleshootRequest {
  trade: string
  issue: string
  context?: TroubleshootContext
}

interface CodeReference {
  code: string
  section: string
  description: string
  relevance: string
}

interface TroubleshootStep {
  step_number: number
  action: string
  detail: string
  expected_result: string
  warning?: string
}

interface PartNeeded {
  name: string
  specification: string
  estimated_cost?: string
}

interface TroubleshootResult {
  diagnosis: {
    most_likely_cause: string
    probability: string
    explanation: string
    secondary_causes: string[]
  }
  code_references: CodeReference[]
  safety_warnings: string[]
  steps: TroubleshootStep[]
  parts_needed: PartNeeded[]
  specialist_required: boolean
  specialist_reason?: string
  estimated_repair_time: string
  difficulty_level: number
}

const VALID_TRADES = [
  'electrical', 'hvac', 'plumbing', 'carpentry', 'roofing',
  'painting', 'flooring', 'concrete', 'drywall', 'insulation',
  'landscaping', 'general', 'fire_protection', 'solar', 'siding',
  'windows_doors', 'appliance', 'locksmith', 'fencing', 'gutters',
]

const TRADE_CODE_MAP: Record<string, string> = {
  electrical: 'NEC (National Electrical Code, NFPA 70)',
  hvac: 'IMC (International Mechanical Code) and IRC (International Residential Code)',
  plumbing: 'IPC (International Plumbing Code) and UPC (Uniform Plumbing Code)',
  carpentry: 'IRC (International Residential Code) and IBC (International Building Code)',
  roofing: 'IRC Chapter 9 (Roof Assemblies) and IBC Chapter 15',
  painting: 'EPA RRP Rule (Lead Paint) and OSHA Standards',
  flooring: 'ADA Standards and IRC Section R303',
  concrete: 'ACI 318 (Building Code Requirements for Structural Concrete)',
  drywall: 'ASTM C840 and GA-216 (Gypsum Association)',
  insulation: 'IRC Chapter 11 (Energy Efficiency) and IECC',
  fire_protection: 'NFPA 13/13D/13R (Sprinkler Systems) and IFC',
  solar: 'NEC Article 690 (Solar Photovoltaic Systems) and IRC',
  general: 'IRC (International Residential Code) and IBC (International Building Code)',
}

function buildSystemPrompt(trade: string, context?: TroubleshootContext): string {
  const codeStandard = TRADE_CODE_MAP[trade] || TRADE_CODE_MAP['general']

  return `You are an expert ${trade} diagnostician with 25+ years of field experience across residential and commercial projects. You hold master-level licenses and certifications in your trade. You are deeply familiar with building codes, manufacturer specifications, and real-world troubleshooting.

YOUR EXPERTISE INCLUDES:
- Deep knowledge of ${codeStandard}
- Manufacturer-specific diagnostics and common failure patterns
- Safety-first approach — always identify hazards before troubleshooting
- Cost-effective repair strategies that meet code requirements
- Understanding of when a problem exceeds DIY/journeyman scope

RESPONSE REQUIREMENTS:
- Be specific and actionable. No vague advice.
- Reference specific code sections when applicable.
- Always lead with safety considerations.
- Rate probability of each diagnosis realistically.
- Include tool and part specifications (not just generic names).
- Be honest about when professional help is needed.
${context?.region ? `- Consider regional code amendments and climate factors for: ${context.region}` : ''}
${context?.equipment_brand ? `- Consider known issues and service bulletins for ${context.equipment_brand}${context.equipment_model ? ` ${context.equipment_model}` : ''}` : ''}
${context?.building_type ? `- Consider building type factors for: ${context.building_type}` : ''}

Return ONLY valid JSON matching this exact structure:
{
  "diagnosis": {
    "most_likely_cause": "Specific root cause description",
    "probability": "high|medium|low",
    "explanation": "Detailed technical explanation of why this is the most likely cause",
    "secondary_causes": ["Alternative cause 1", "Alternative cause 2"]
  },
  "code_references": [
    {
      "code": "Code name (e.g., NEC)",
      "section": "Specific section number",
      "description": "What this code section requires",
      "relevance": "How this applies to the current issue"
    }
  ],
  "safety_warnings": ["Warning 1 with specific hazard description", "Warning 2"],
  "steps": [
    {
      "step_number": 1,
      "action": "Clear action statement",
      "detail": "Detailed instructions for this step",
      "expected_result": "What you should see/find if this step is successful",
      "warning": "Optional safety note for this specific step"
    }
  ],
  "parts_needed": [
    {
      "name": "Part name",
      "specification": "Size, rating, material, or model number",
      "estimated_cost": "$XX-$XX range"
    }
  ],
  "specialist_required": false,
  "specialist_reason": "Only include if specialist_required is true",
  "estimated_repair_time": "X-Y hours for a journeyman-level technician",
  "difficulty_level": 3
}`
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Verify authorization
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

  // Verify Anthropic API key
  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!anthropicKey) {
    return new Response(JSON.stringify({ error: 'AI service not configured' }), {
      status: 503,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body: TroubleshootRequest = await req.json()
    const { trade, issue, context } = body

    // Validate required fields
    if (!trade || typeof trade !== 'string') {
      return new Response(JSON.stringify({ error: 'trade is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!issue || typeof issue !== 'string') {
      return new Response(JSON.stringify({ error: 'issue is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const normalizedTrade = trade.toLowerCase().trim()
    if (!VALID_TRADES.includes(normalizedTrade)) {
      return new Response(JSON.stringify({
        error: `Invalid trade. Must be one of: ${VALID_TRADES.join(', ')}`,
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (issue.length > 5000) {
      return new Response(JSON.stringify({ error: 'Issue description must be under 5000 characters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Build the user message with context
    const contextLines: string[] = []
    if (context?.equipment_brand) contextLines.push(`Equipment Brand: ${context.equipment_brand}`)
    if (context?.equipment_model) contextLines.push(`Equipment Model: ${context.equipment_model}`)
    if (context?.building_type) contextLines.push(`Building Type: ${context.building_type}`)
    if (context?.region) contextLines.push(`Region: ${context.region}`)

    const userMessage = `TRADE: ${normalizedTrade}
ISSUE: ${issue}
${contextLines.length > 0 ? `\nADDITIONAL CONTEXT:\n${contextLines.join('\n')}` : ''}

Diagnose this issue and provide a complete troubleshooting guide.`

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
        system: buildSystemPrompt(normalizedTrade, context),
        messages: [{ role: 'user', content: userMessage }],
      }),
    })

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text()
      console.error('Claude API error:', errText)
      return new Response(JSON.stringify({ error: 'AI service temporarily unavailable' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const claudeResult = await claudeResponse.json()
    const responseText = claudeResult.content?.[0]?.text || ''

    // Parse Claude's JSON response
    let diagnosis: TroubleshootResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      diagnosis = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      // Return a structured fallback
      diagnosis = {
        diagnosis: {
          most_likely_cause: 'Unable to parse structured diagnosis',
          probability: 'medium',
          explanation: responseText.substring(0, 2000),
          secondary_causes: [],
        },
        code_references: [],
        safety_warnings: ['Always follow standard safety procedures for your trade.'],
        steps: [],
        parts_needed: [],
        specialist_required: false,
        estimated_repair_time: 'Unknown',
        difficulty_level: 3,
      }
    }

    // Log usage for monitoring
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      trade: normalizedTrade,
      ...diagnosis,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-troubleshoot error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
