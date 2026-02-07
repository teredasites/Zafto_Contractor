// Supabase Edge Function: ai-repair-guide
// Generates step-by-step repair instructions tailored to skill level.
// POST { trade: string, issue: string, skill_level: string, tools_available?: string[] }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RepairGuideRequest {
  trade: string
  issue: string
  skill_level: string
  tools_available?: string[]
}

interface SafetyPrecaution {
  severity: 'critical' | 'warning' | 'info'
  precaution: string
  detail: string
}

interface RepairStep {
  step_number: number
  instruction: string
  detail: string
  tip?: string
  warning?: string
  photo_suggestion?: string
}

interface CodeReference {
  code: string
  section: string
  description: string
}

interface RepairGuideResult {
  title: string
  estimated_time: string
  difficulty: number
  safety_precautions: SafetyPrecaution[]
  steps: RepairStep[]
  tools_required: string[]
  materials_needed: string[]
  code_references: CodeReference[]
  when_to_stop: string
}

const VALID_SKILL_LEVELS = ['apprentice', 'journeyman', 'master']

const VALID_TRADES = [
  'electrical', 'hvac', 'plumbing', 'carpentry', 'roofing',
  'painting', 'flooring', 'concrete', 'drywall', 'insulation',
  'landscaping', 'general', 'fire_protection', 'solar', 'siding',
  'windows_doors', 'appliance', 'locksmith', 'fencing', 'gutters',
]

const SKILL_LEVEL_DESCRIPTIONS: Record<string, string> = {
  apprentice: `The reader is an APPRENTICE (1-3 years experience):
- Explain every step in detail, assume limited hands-on experience
- Define technical terms when first used
- Include safety reminders at every potentially hazardous step
- Suggest when to get a journeyman or master to verify work
- Recommend taking photos before and after each major step for learning and documentation
- Provide "why" explanations — apprentices learn better when they understand the reason behind each step`,

  journeyman: `The reader is a JOURNEYMAN (4-8 years experience):
- Provide clear, professional-level instructions
- Use standard trade terminology without excessive explanation
- Include code references and best practices
- Note areas where regional code variations may apply
- Focus on efficiency and quality workmanship
- Include tips for common pitfalls at this level`,

  master: `The reader is a MASTER tradesperson (10+ years experience):
- Provide concise, high-level guidance
- Focus on the specific issue rather than general procedures
- Include advanced diagnostics and less obvious failure modes
- Reference specific code sections and manufacturer bulletins
- Note any recent code changes or updated best practices
- Include efficiency tips and professional techniques`,
}

function buildSystemPrompt(trade: string, skillLevel: string, toolsAvailable?: string[]): string {
  const skillDescription = SKILL_LEVEL_DESCRIPTIONS[skillLevel] || SKILL_LEVEL_DESCRIPTIONS['journeyman']
  const toolsContext = toolsAvailable && toolsAvailable.length > 0
    ? `\nThe technician has the following tools available: ${toolsAvailable.join(', ')}. Tailor your instructions to use these tools where possible. If additional tools are required, clearly list them in tools_required.`
    : ''

  return `You are an expert ${trade} repair instructor and master tradesperson. You create clear, safe, code-compliant repair guides for field technicians.

SKILL LEVEL OF THE READER:
${skillDescription}

${toolsContext}

GUIDE REQUIREMENTS:
1. SAFETY FIRST — Always start with safety precautions. Critical precautions (electrical lockout, gas shutoff, structural shoring) must come before ANY work steps.
2. Be specific — Use exact measurements, torque specs, wire gauges, pipe sizes, and material specifications.
3. Be sequential — Each step must follow logically from the previous. Never assume the reader will figure out intermediate steps.
4. Include verification — After critical steps, include how to verify the work was done correctly.
5. Code compliance — Reference applicable building codes for the work being performed.
6. Know the limits — Clearly state when a repair exceeds the scope of field repair and requires professional intervention, engineering review, or permitting.

DIFFICULTY SCALE (1-5):
1 = Basic maintenance (filter changes, caulking, simple adjustments)
2 = Routine repair (replacing fixtures, patching, basic component swaps)
3 = Intermediate repair (circuit modifications, pipe rerouting, structural patches)
4 = Advanced repair (panel work, system redesign, load-bearing modifications)
5 = Expert/specialist (high-voltage, gas line work, structural engineering required)

PHOTO SUGGESTIONS:
For each step where documentation would be valuable, include a photo_suggestion describing what the tech should photograph (for QA, client documentation, or inspection purposes).

Return ONLY valid JSON matching this exact structure:
{
  "title": "Clear, descriptive title for this repair guide",
  "estimated_time": "X-Y hours (adjusted for the specified skill level)",
  "difficulty": 3,
  "safety_precautions": [
    {
      "severity": "critical",
      "precaution": "Short precaution title",
      "detail": "Detailed explanation of the hazard and how to mitigate it"
    },
    {
      "severity": "warning",
      "precaution": "Short precaution title",
      "detail": "Detailed explanation"
    },
    {
      "severity": "info",
      "precaution": "Short precaution title",
      "detail": "Helpful information"
    }
  ],
  "steps": [
    {
      "step_number": 1,
      "instruction": "Clear, concise action statement",
      "detail": "Detailed instructions with specifications, measurements, and technique",
      "tip": "Optional pro tip for this step",
      "warning": "Optional safety warning specific to this step",
      "photo_suggestion": "Optional: what to photograph at this step"
    }
  ],
  "tools_required": ["Specific tool with size/type (e.g., 'Phillips #2 screwdriver', '1/2-inch torque wrench')"],
  "materials_needed": ["Specific material with spec (e.g., '12 AWG THHN copper wire, 15 ft', '1/2-inch Type L copper coupling')"],
  "code_references": [
    {
      "code": "Code name",
      "section": "Section number",
      "description": "What this code section requires for this repair"
    }
  ],
  "when_to_stop": "Clear description of conditions under which the technician should stop work and escalate to a specialist, inspector, or engineer"
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
    const body: RepairGuideRequest = await req.json()
    const { trade, issue, skill_level, tools_available } = body

    // Validate trade
    if (!trade || typeof trade !== 'string') {
      return new Response(JSON.stringify({ error: 'trade is required and must be a string' }), {
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

    // Validate issue
    if (!issue || typeof issue !== 'string') {
      return new Response(JSON.stringify({ error: 'issue is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (issue.length > 5000) {
      return new Response(JSON.stringify({ error: 'issue must be under 5000 characters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate skill_level
    if (!skill_level || typeof skill_level !== 'string') {
      return new Response(JSON.stringify({ error: 'skill_level is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const normalizedSkillLevel = skill_level.toLowerCase().trim()
    if (!VALID_SKILL_LEVELS.includes(normalizedSkillLevel)) {
      return new Response(JSON.stringify({
        error: `Invalid skill_level. Must be one of: ${VALID_SKILL_LEVELS.join(', ')}`,
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate tools_available (optional)
    if (tools_available !== undefined) {
      if (!Array.isArray(tools_available)) {
        return new Response(JSON.stringify({ error: 'tools_available must be an array of strings' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      if (tools_available.some(t => typeof t !== 'string')) {
        return new Response(JSON.stringify({ error: 'All items in tools_available must be strings' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // Build user message
    const toolsList = tools_available && tools_available.length > 0
      ? `\nTools Available: ${tools_available.join(', ')}`
      : ''

    const userMessage = `Generate a complete repair guide for the following:

Trade: ${normalizedTrade}
Issue: ${issue}
Skill Level: ${normalizedSkillLevel}${toolsList}

Provide a thorough, safe, code-compliant step-by-step repair guide appropriate for the specified skill level.`

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
        max_tokens: 6144,
        system: buildSystemPrompt(normalizedTrade, normalizedSkillLevel, tools_available),
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
    let guide: RepairGuideResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      guide = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      guide = {
        title: `${normalizedTrade} Repair Guide`,
        estimated_time: 'Unknown',
        difficulty: 3,
        safety_precautions: [{
          severity: 'critical',
          precaution: 'General Safety',
          detail: 'Always follow standard safety procedures. Wear appropriate PPE. De-energize systems before working on them.',
        }],
        steps: [{
          step_number: 1,
          instruction: 'Structured guide generation failed',
          detail: responseText.substring(0, 2000),
        }],
        tools_required: [],
        materials_needed: [],
        code_references: [],
        when_to_stop: 'If you encounter any situation not covered by this guide, stop work and consult a licensed professional.',
      }
    }

    // Validate difficulty is 1-5
    if (typeof guide.difficulty !== 'number' || guide.difficulty < 1) {
      guide.difficulty = 1
    } else if (guide.difficulty > 5) {
      guide.difficulty = 5
    }
    guide.difficulty = Math.round(guide.difficulty)

    // Ensure safety_precautions is always first in the response and non-empty
    if (!guide.safety_precautions || guide.safety_precautions.length === 0) {
      guide.safety_precautions = [{
        severity: 'warning',
        precaution: 'General Safety',
        detail: 'Always wear appropriate personal protective equipment (PPE) and follow OSHA guidelines for the work being performed.',
      }]
    }

    // Ensure steps are properly numbered
    if (guide.steps && Array.isArray(guide.steps)) {
      guide.steps = guide.steps.map((step, index) => ({
        ...step,
        step_number: index + 1,
      }))
    }

    // Token usage
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      trade: normalizedTrade,
      skill_level: normalizedSkillLevel,
      ...guide,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-repair-guide error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
