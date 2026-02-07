// Supabase Edge Function: ai-equipment-insights
// Analyzes property equipment for health scores, maintenance schedules, parts to stock,
// and replacement timelines. Uses Claude for intelligent lifecycle analysis.
// POST { company_id: string, property_id?: string, equipment_id?: string }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface EquipmentInsightsRequest {
  company_id: string
  property_id?: string
  equipment_id?: string
}

interface MaintenanceItem {
  task: string
  interval_months: number
  next_due: string
  priority: 'high' | 'medium' | 'low'
  estimated_cost: number
  notes: string
}

interface PartSuggestion {
  name: string
  part_number: string
  reason: string
  estimated_cost: number
  urgency: 'immediate' | 'soon' | 'stock'
}

interface ReplacementTimeline {
  equipment_id: string
  equipment_name: string
  expected_replacement_year: number
  estimated_replacement_cost: number
  risk_level: 'high' | 'medium' | 'low'
  recommendation: string
}

interface EquipmentHealthResult {
  equipment_health: number
  next_service_date: string
  maintenance_schedule: MaintenanceItem[]
  parts_to_stock: PartSuggestion[]
  replacement_timeline: ReplacementTimeline[]
  estimated_annual_cost: number
  summary: string
}

function buildSystemPrompt(): string {
  return `You are an expert equipment lifecycle analyst for a multi-trade contractor company. You specialize in HVAC, plumbing, electrical, and general building equipment.

YOUR EXPERTISE INCLUDES:
- Equipment lifespan data by manufacturer, model, and type
- Preventive maintenance schedules and best practices
- Common failure patterns and parts that wear out first
- Cost estimation for maintenance, parts, and replacements
- Risk assessment based on equipment age, condition, and service history

ANALYSIS REQUIREMENTS:
- Calculate equipment_health as a score from 1-100 based on age vs expected lifespan, condition, and service history
- Generate realistic maintenance schedules with specific intervals
- Suggest parts that should be stocked based on equipment age and common failure points
- Provide replacement timelines with cost estimates
- Be practical and cost-conscious — prioritize what matters most

Return ONLY valid JSON matching this exact structure:
{
  "equipment_health": 85,
  "next_service_date": "2025-06-15",
  "maintenance_schedule": [
    {
      "task": "Filter replacement and coil cleaning",
      "interval_months": 6,
      "next_due": "2025-06-15",
      "priority": "high",
      "estimated_cost": 150,
      "notes": "Critical for efficiency and warranty compliance"
    }
  ],
  "parts_to_stock": [
    {
      "name": "Capacitor 45/5 MFD",
      "part_number": "CPT0075",
      "reason": "Common failure point at 3+ years, leads to compressor issues",
      "estimated_cost": 25,
      "urgency": "stock"
    }
  ],
  "replacement_timeline": [
    {
      "equipment_id": "eq-uuid",
      "equipment_name": "Carrier 24ACC636A003",
      "expected_replacement_year": 2038,
      "estimated_replacement_cost": 5500,
      "risk_level": "low",
      "recommendation": "On track. Continue regular maintenance."
    }
  ],
  "estimated_annual_cost": 450,
  "summary": "Brief overall assessment of the equipment portfolio health"
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
    const body: EquipmentInsightsRequest = await req.json()
    const { company_id, property_id, equipment_id } = body

    // Validate required fields
    if (!company_id || typeof company_id !== 'string') {
      return new Response(JSON.stringify({ error: 'company_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Query equipment data
    let query = supabase
      .from('property_equipment')
      .select('id, property_id, type, brand, model, serial_number, install_date, last_service_date, condition, warranty_expiry, expected_lifespan_years, notes')
      .eq('company_id', company_id)

    if (property_id) {
      query = query.eq('property_id', property_id)
    }
    if (equipment_id) {
      query = query.eq('id', equipment_id)
    }

    const { data: equipment, error: eqError } = await query.limit(50)

    if (eqError) {
      console.error('Equipment query error:', eqError)
      return new Response(JSON.stringify({ error: 'Failed to query equipment data' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!equipment || equipment.length === 0) {
      return new Response(JSON.stringify({
        success: true,
        equipment_health: 0,
        next_service_date: null,
        maintenance_schedule: [],
        parts_to_stock: [],
        replacement_timeline: [],
        estimated_annual_cost: 0,
        summary: 'No equipment found for the specified criteria.',
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Build context for Claude
    const equipmentSummary = equipment.map((eq) => {
      const ageYears = eq.install_date
        ? Math.round((Date.now() - new Date(eq.install_date).getTime()) / (365.25 * 24 * 60 * 60 * 1000) * 10) / 10
        : null
      return {
        id: eq.id,
        type: eq.type,
        brand: eq.brand,
        model: eq.model,
        serial_number: eq.serial_number,
        install_date: eq.install_date,
        age_years: ageYears,
        last_service_date: eq.last_service_date,
        condition: eq.condition,
        warranty_expiry: eq.warranty_expiry,
        expected_lifespan_years: eq.expected_lifespan_years,
        notes: eq.notes,
      }
    })

    const userMessage = `Analyze the following equipment portfolio and provide maintenance insights, parts recommendations, and replacement planning.

EQUIPMENT DATA:
${JSON.stringify(equipmentSummary, null, 2)}

TODAY'S DATE: ${new Date().toISOString().split('T')[0]}

Provide a comprehensive analysis with health scores, maintenance schedules, parts to stock, and replacement timelines.`

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
        system: buildSystemPrompt(),
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
    let insights: EquipmentHealthResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      insights = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      insights = {
        equipment_health: 50,
        next_service_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
        maintenance_schedule: [],
        parts_to_stock: [],
        replacement_timeline: [],
        estimated_annual_cost: 0,
        summary: 'Analysis could not be fully parsed. Raw response available.',
      }
    }

    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      ...insights,
      equipment_count: equipment.length,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-equipment-insights error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
