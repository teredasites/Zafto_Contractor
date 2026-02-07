// Supabase Edge Function: walkthrough-generate-bid
// THE MAIN FUNCTION — Generates a complete bid from walkthrough data.
// Supports 6 formats: standard, three_tier, insurance, aia, trade_specific, inspection.
// POST { walkthrough_id, format, options } → returns structured bid + creates bid record.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type BidFormat = 'standard' | 'three_tier' | 'insurance' | 'aia' | 'trade_specific' | 'inspection'
type TradeType = 'plumbing' | 'electrical' | 'hvac' | 'general' | 'roofing' | 'painting'

interface BidOptions {
  include_photos: boolean
  include_floor_plan: boolean
  markup_percentage: number
  overhead_percentage: number
  profit_percentage: number
  trade_type: TradeType
}

interface BidLineItem {
  description: string
  quantity: number
  unit: string
  unit_price: number
  total: number
  code?: string
  material_cost?: number
  labor_cost?: number
  equipment_cost?: number
}

interface BidSection {
  name: string
  items: BidLineItem[]
  subtotal: number
}

interface GeneratedBid {
  format: BidFormat
  title: string
  sections: BidSection[]
  subtotal: number
  overhead: number
  profit: number
  total: number
  notes: string
  terms: string
  valid_days: number
  tiers?: Array<{ name: string; description: string; sections: BidSection[]; total: number }>
  schedule_of_values?: Array<{ number: string; description: string; scheduled_value: number }>
  findings?: Array<{ area: string; finding: string; priority: string; recommendation: string; photo_refs: string[] }>
}

// ── Format-specific system prompts ──

function getSystemPrompt(format: BidFormat, options: BidOptions): string {
  const base = `You are a professional contractor bid writer. Generate accurate, detailed bids based on property walkthrough data. Use realistic pricing for the region. All monetary values should be numbers (not strings).`

  switch (format) {
    case 'standard':
      return `${base}

Generate a professional line-item bid with materials, labor, and subtotals organized by work section.
Each section groups related work (e.g., Demolition, Framing, Electrical, Plumbing, Finishes).
Each item needs: description, quantity, unit (EA, SF, LF, HR, LS, SY, CY), unit_price, total.
Apply ${options.overhead_percentage}% overhead and ${options.profit_percentage}% profit to the subtotal.
Include professional notes and standard terms.

Return JSON matching this exact structure:
{
  "title": "Project title based on scope",
  "sections": [
    {
      "name": "Section Name",
      "items": [
        { "description": "Line item description", "quantity": 1, "unit": "LS", "unit_price": 850.00, "total": 850.00 }
      ],
      "subtotal": 850.00
    }
  ],
  "subtotal": 15000.00,
  "overhead": 1500.00,
  "profit": 1500.00,
  "total": 18000.00,
  "notes": "Professional notes about scope, exclusions, assumptions",
  "terms": "Payment terms, warranty info, change order policy",
  "valid_days": 30
}`

    case 'three_tier':
      return `${base}

Generate a Good/Better/Best three-tier bid. Each tier adds scope and quality:
- GOOD: Basic scope, standard materials, minimum required work. Budget-friendly.
- BETTER: Enhanced scope, mid-range materials, additional improvements. Best value.
- BEST: Premium scope, high-end materials, comprehensive work. Maximum quality.

Each tier has its own sections with line items. Higher tiers include everything from lower tiers plus upgrades.
Apply ${options.overhead_percentage}% overhead and ${options.profit_percentage}% profit to each tier.

Return JSON:
{
  "title": "Project title",
  "tiers": [
    {
      "name": "Good",
      "description": "Brief tier description",
      "sections": [
        { "name": "Section", "items": [{ "description": "...", "quantity": 1, "unit": "LS", "unit_price": 500, "total": 500 }], "subtotal": 500 }
      ],
      "subtotal": 10000,
      "overhead": 1000,
      "profit": 1000,
      "total": 12000
    },
    { "name": "Better", "description": "...", "sections": [...], "subtotal": 15000, "overhead": 1500, "profit": 1500, "total": 18000 },
    { "name": "Best", "description": "...", "sections": [...], "subtotal": 22000, "overhead": 2200, "profit": 2200, "total": 26400 }
  ],
  "sections": [],
  "subtotal": 0,
  "overhead": 0,
  "profit": 0,
  "total": 0,
  "notes": "Explanation of tier differences and recommendations",
  "terms": "Payment terms, warranty info",
  "valid_days": 30
}`

    case 'insurance':
      return `${base}

Generate an insurance-style estimate in Xactimate format. Organize by room/area with category codes.
Include MAT (material), LAB (labor), EQU (equipment) cost breakdown per line item.
Add O&P (Overhead & Profit) line at ${options.overhead_percentage}% + ${options.profit_percentage}%.
Include depreciation considerations where applicable.

Each item should have a realistic Xactimate-style code (e.g., "DRY HANG", "RFG SHGL", "PLM FIXT").

Return JSON:
{
  "title": "Insurance Estimate - Property Address",
  "sections": [
    {
      "name": "Room/Area Name",
      "items": [
        {
          "description": "Remove & replace drywall - 1/2 inch",
          "code": "DRY HANG",
          "quantity": 120,
          "unit": "SF",
          "unit_price": 2.85,
          "total": 342.00,
          "material_cost": 1.20,
          "labor_cost": 1.45,
          "equipment_cost": 0.20
        }
      ],
      "subtotal": 342.00
    }
  ],
  "subtotal": 15000.00,
  "overhead": 1500.00,
  "profit": 1500.00,
  "total": 18000.00,
  "notes": "Scope based on property walkthrough. Xactimate codes for reference. Subject to field verification.",
  "terms": "Insurance claim terms - payment upon approval. Supplemental scope may be required for concealed damage.",
  "valid_days": 60
}`

    case 'aia':
      return `${base}

Generate an AIA G702/G703 format — Schedule of Values with application for payment structure.
Each line represents a major work category with a scheduled value.
Items are numbered sequentially (001, 002, etc.).
This format is used for commercial projects and progress billing.

Return JSON:
{
  "title": "Schedule of Values - Project Name",
  "schedule_of_values": [
    { "number": "001", "description": "General Conditions", "scheduled_value": 5000 },
    { "number": "002", "description": "Site Work / Demolition", "scheduled_value": 3500 },
    { "number": "003", "description": "Concrete / Foundation", "scheduled_value": 8000 }
  ],
  "sections": [
    {
      "name": "Schedule of Values",
      "items": [
        { "description": "001 - General Conditions", "quantity": 1, "unit": "LS", "unit_price": 5000, "total": 5000 }
      ],
      "subtotal": 50000
    }
  ],
  "subtotal": 50000,
  "overhead": 5000,
  "profit": 5000,
  "total": 60000,
  "notes": "AIA G702/G703 format. Progress payments based on percentage of completion per line item.",
  "terms": "Net 30 on approved applications for payment. Retainage: 10% until substantial completion.",
  "valid_days": 30
}`

    case 'trade_specific':
      return `${base}

Generate a bid specific to ${options.trade_type} trade work. Use trade-specific terminology, materials, and pricing.

Trade-specific details:
${options.trade_type === 'plumbing' ? '- Include fixture counts, pipe sizes/types, drain/vent specs, water heater details, rough-in vs finish' : ''}
${options.trade_type === 'electrical' ? '- Include panel specs, circuit counts, wire gauge, outlet/switch counts, fixture types, code compliance items' : ''}
${options.trade_type === 'hvac' ? '- Include tonnage, SEER ratings, ductwork specs, thermostat type, refrigerant type, load calculations' : ''}
${options.trade_type === 'general' ? '- Include all trades with appropriate detail for each scope area' : ''}
${options.trade_type === 'roofing' ? '- Include squares, material type (shingle/metal/tile), underlayment, flashing, ridge vent, tear-off layers' : ''}
${options.trade_type === 'painting' ? '- Include surface prep, primer, coats, paint grade, SF calculations, trim/accent colors, ceiling vs wall' : ''}

Return JSON with same structure as standard format:
{
  "title": "${options.trade_type.charAt(0).toUpperCase() + options.trade_type.slice(1)} Bid - Property",
  "sections": [...],
  "subtotal": 0,
  "overhead": 0,
  "profit": 0,
  "total": 0,
  "notes": "Trade-specific notes and specifications",
  "terms": "Standard terms",
  "valid_days": 30
}`

    case 'inspection':
      return `${base}

Generate a detailed inspection report (NOT a bid). This is for documenting property condition.
Include findings organized by area, with priority ratings and recommendations.
Reference photos where applicable.

Return JSON:
{
  "title": "Property Inspection Report - Address",
  "findings": [
    {
      "area": "Kitchen",
      "finding": "Water damage visible under sink cabinet. Particle board swollen, indicating ongoing leak.",
      "priority": "high",
      "recommendation": "Replace sink supply lines and P-trap. Replace cabinet base. Check for mold.",
      "photo_refs": ["kitchen_photo_1", "kitchen_photo_2"]
    }
  ],
  "sections": [
    {
      "name": "Recommended Repairs (Estimated Costs)",
      "items": [
        { "description": "Kitchen plumbing repair + cabinet replacement", "quantity": 1, "unit": "LS", "unit_price": 2500, "total": 2500 }
      ],
      "subtotal": 2500
    }
  ],
  "subtotal": 0,
  "overhead": 0,
  "profit": 0,
  "total": 0,
  "notes": "This is an inspection report, not a bid. Estimated costs are approximate and subject to detailed scoping.",
  "terms": "Inspection findings valid for 90 days. Conditions may change.",
  "valid_days": 90
}`

    default:
      return base
  }
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
    const { walkthrough_id, format: bidFormat, options: rawOptions } = body

    if (!walkthrough_id) {
      return new Response(JSON.stringify({ error: 'walkthrough_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const validFormats: BidFormat[] = ['standard', 'three_tier', 'insurance', 'aia', 'trade_specific', 'inspection']
    const format: BidFormat = validFormats.includes(bidFormat) ? bidFormat : 'standard'

    const options: BidOptions = {
      include_photos: rawOptions?.include_photos ?? true,
      include_floor_plan: rawOptions?.include_floor_plan ?? false,
      markup_percentage: rawOptions?.markup_percentage ?? 20,
      overhead_percentage: rawOptions?.overhead_percentage ?? 10,
      profit_percentage: rawOptions?.profit_percentage ?? 10,
      trade_type: rawOptions?.trade_type ?? 'general',
    }

    // ── Fetch ALL walkthrough data ──

    const { data: walkthrough, error: wtErr } = await supabase
      .from('walkthroughs')
      .select('*')
      .eq('id', walkthrough_id)
      .single()

    if (wtErr || !walkthrough) {
      return new Response(JSON.stringify({ error: 'Walkthrough not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { data: rooms } = await supabase
      .from('walkthrough_rooms')
      .select('*')
      .eq('walkthrough_id', walkthrough_id)
      .order('sort_order')

    const walkthroughRooms = rooms || []

    const { data: photos } = await supabase
      .from('walkthrough_photos')
      .select('*')
      .eq('walkthrough_id', walkthrough_id)
      .order('created_at')

    const walkthroughPhotos = photos || []

    // Fetch user's company info for the bid record
    const { data: profile } = await supabase
      .from('users')
      .select('company_id, name')
      .eq('id', user.id)
      .single()

    const companyId = profile?.company_id || null

    // Check for xactimate codes if insurance format
    let xactCodes: Array<{ full_code: string; description: string; unit: string }> = []
    if (format === 'insurance') {
      const { data: codes } = await supabase
        .from('xactimate_codes')
        .select('full_code, description, unit')
        .limit(200)

      xactCodes = codes || []
    }

    // Check for pricing entries
    let pricingData: Array<{ code_id: string; total_cost: number; unit: string }> = []
    if (format === 'insurance') {
      const { data: pricing } = await supabase
        .from('pricing_entries')
        .select('code_id, total_cost, unit')
        .is('company_id', null)
        .limit(500)

      pricingData = pricing || []
    }

    // ── Build comprehensive context ──

    // Group photos by room for context
    const photosByRoom = new Map<string, typeof walkthroughPhotos>()
    for (const photo of walkthroughPhotos) {
      const roomId = photo.room_id || '__general__'
      const existing = photosByRoom.get(roomId) || []
      existing.push(photo)
      photosByRoom.set(roomId, existing)
    }

    const roomContext = walkthroughRooms.map(room => {
      const roomPhotos = photosByRoom.get(room.id) || []
      const photoAnalyses = roomPhotos
        .filter((p: Record<string, unknown>) => p.ai_analysis)
        .map((p: Record<string, unknown>) => {
          const analysis = p.ai_analysis as Record<string, unknown>
          const roomAnalysis = analysis?.roomAnalysis as Record<string, unknown>
          return roomAnalysis ? JSON.stringify(roomAnalysis) : null
        })
        .filter(Boolean)

      return `
=== ${room.name} (${room.type || 'general'}) ===
${room.dimensions ? `Dimensions: L=${(room.dimensions as Record<string, unknown>).length || '?'}ft x W=${(room.dimensions as Record<string, unknown>).width || '?'}ft x H=${(room.dimensions as Record<string, unknown>).height || '?'}ft, Area=${(room.dimensions as Record<string, unknown>).area || '?'}sqft` : 'Dimensions: Not measured'}
Condition: ${room.condition_rating || 'Not rated'}/5
Notes: ${room.notes || 'None'}
Tags: ${room.tags && room.tags.length > 0 ? room.tags.join(', ') : 'None'}
Photos: ${roomPhotos.length} photos
${photoAnalyses.length > 0 ? `AI Photo Analysis:\n${photoAnalyses.join('\n')}` : 'No AI photo analysis available'}`
    }).join('\n')

    const walkthroughContext = `
PROPERTY WALKTHROUGH DATA
========================
Name: ${walkthrough.name || 'Untitled'}
Type: ${walkthrough.type || 'general'}
Address: ${walkthrough.address || 'Not provided'}
Date: ${walkthrough.created_at ? new Date(walkthrough.created_at).toLocaleDateString('en-US') : 'Unknown'}
Weather: ${walkthrough.weather || 'Not noted'}
Overall Notes: ${walkthrough.notes || 'None'}
Rooms: ${walkthroughRooms.length}
Total Photos: ${walkthroughPhotos.length}

ROOM-BY-ROOM DATA:
${roomContext || 'No rooms recorded.'}
`

    const xactContext = format === 'insurance' && xactCodes.length > 0
      ? `\nAVAILABLE XACTIMATE CODES (use these where applicable):\n${xactCodes.slice(0, 100).map(c => `${c.full_code}: ${c.description} (${c.unit})`).join('\n')}\n`
      : ''

    // ── Call Claude to generate bid ──

    const systemPrompt = getSystemPrompt(format, options)

    const userPrompt = `Generate a ${format === 'three_tier' ? 'three-tier Good/Better/Best' : format} bid/estimate based on this property walkthrough data.

${walkthroughContext}
${xactContext}

OPTIONS:
- Overhead: ${options.overhead_percentage}%
- Profit: ${options.profit_percentage}%
${format === 'trade_specific' ? `- Trade: ${options.trade_type}` : ''}

Generate a complete, professional bid with realistic pricing. Be thorough — include all necessary line items for the scope of work identified in the walkthrough.

Return ONLY valid JSON as specified in the system instructions.`

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
        system: systemPrompt,
        messages: [{ role: 'user', content: userPrompt }],
      }),
    })

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text()
      console.error('Claude API error:', errText)
      return new Response(JSON.stringify({ error: 'AI bid generation failed', detail: errText }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const claudeResult = await claudeResponse.json()
    const responseText = claudeResult.content?.[0]?.text || ''

    // Parse generated bid JSON
    let generatedBid: GeneratedBid
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON in response')
      generatedBid = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('JSON parse error:', parseErr)
      return new Response(JSON.stringify({
        error: 'Failed to parse AI-generated bid',
        rawResponse: responseText.substring(0, 3000),
      }), {
        status: 422,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Ensure format field is set
    generatedBid.format = format

    // Calculate totals if not provided correctly by AI
    if (generatedBid.sections && generatedBid.sections.length > 0) {
      // Recalculate section subtotals
      for (const section of generatedBid.sections) {
        section.subtotal = section.items.reduce((sum, item) => sum + (Number(item.total) || 0), 0)
      }

      const calculatedSubtotal = generatedBid.sections.reduce((sum, s) => sum + s.subtotal, 0)

      // Only override if AI returned sections with items (not three_tier where sections may be empty)
      if (calculatedSubtotal > 0) {
        generatedBid.subtotal = calculatedSubtotal
        generatedBid.overhead = calculatedSubtotal * (options.overhead_percentage / 100)
        generatedBid.profit = calculatedSubtotal * (options.profit_percentage / 100)
        generatedBid.total = generatedBid.subtotal + generatedBid.overhead + generatedBid.profit
      }
    }

    // For three_tier, recalculate each tier
    if (format === 'three_tier' && generatedBid.tiers) {
      for (const tier of generatedBid.tiers) {
        if (tier.sections && tier.sections.length > 0) {
          for (const section of tier.sections) {
            section.subtotal = section.items.reduce((sum, item) => sum + (Number(item.total) || 0), 0)
          }
          tier.subtotal = tier.sections.reduce((sum, s) => sum + s.subtotal, 0)
          const tierOverhead = tier.subtotal * (options.overhead_percentage / 100)
          const tierProfit = tier.subtotal * (options.profit_percentage / 100)
          tier.total = tier.subtotal + tierOverhead + tierProfit
        }
      }
    }

    // ── Create bid record in database ──

    // Determine total for the bid record
    const bidTotal = format === 'three_tier' && generatedBid.tiers
      ? generatedBid.tiers[1]?.total || generatedBid.tiers[0]?.total || 0  // Default to "Better" tier
      : generatedBid.total || 0

    const validUntil = new Date()
    validUntil.setDate(validUntil.getDate() + (generatedBid.valid_days || 30))

    const { data: bidRecord, error: bidErr } = await supabase
      .from('bids')
      .insert({
        company_id: companyId,
        job_id: walkthrough.job_id || null,
        customer_id: walkthrough.customer_id || null,
        title: generatedBid.title || `Bid - ${walkthrough.address || 'Property'}`,
        description: generatedBid.notes || '',
        status: 'draft',
        total_amount: bidTotal,
        valid_until: validUntil.toISOString(),
        metadata: {
          format,
          walkthrough_id,
          generated_bid: generatedBid,
          options,
          generated_at: new Date().toISOString(),
          model: 'claude-sonnet-4-5-20250929',
          token_usage: {
            input: claudeResult.usage?.input_tokens || 0,
            output: claudeResult.usage?.output_tokens || 0,
          },
        },
      })
      .select('id')
      .single()

    if (bidErr) {
      console.error('Bid insert error:', bidErr)
      // Still return the generated bid even if DB insert fails
      return new Response(JSON.stringify({
        success: true,
        warning: 'Bid generated but failed to save to database',
        bid_id: null,
        ...generatedBid,
        tokenUsage: {
          input: claudeResult.usage?.input_tokens || 0,
          output: claudeResult.usage?.output_tokens || 0,
        },
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Update walkthrough status and link bid
    await supabase
      .from('walkthroughs')
      .update({
        status: 'bid_generated',
        bid_id: bidRecord.id,
      })
      .eq('id', walkthrough_id)

    return new Response(JSON.stringify({
      success: true,
      bid_id: bidRecord.id,
      ...generatedBid,
      tokenUsage: {
        input: claudeResult.usage?.input_tokens || 0,
        output: claudeResult.usage?.output_tokens || 0,
      },
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Walkthrough generate-bid error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
