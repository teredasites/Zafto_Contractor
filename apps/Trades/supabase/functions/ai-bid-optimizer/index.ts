// Supabase Edge Function: ai-bid-optimizer
// Bid Brain — AI-powered bid optimization engine.
// Analyzes historical bids, win/loss patterns, and competitive pricing to optimize bid strategy.
// POST { company_id: string, bid_id?: string, scope_of_work?: string, estimated_amount?: number }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BidOptimizerRequest {
  company_id: string
  bid_id?: string
  scope_of_work?: string
  estimated_amount?: number
}

interface PriceRange {
  low: number
  optimal: number
  high: number
}

interface ScopeSuggestion {
  title: string
  description: string
  estimated_value: number
  priority: 'high' | 'medium' | 'low'
  rationale: string
}

interface PricingAdjustment {
  item: string
  current_price: number
  suggested_price: number
  reason: string
  impact: 'positive' | 'negative' | 'neutral'
}

interface RiskFactor {
  category: string
  description: string
  severity: 'high' | 'medium' | 'low'
  mitigation: string
}

interface BidOptimizationResult {
  win_probability: number
  recommended_price_range: PriceRange
  scope_suggestions: ScopeSuggestion[]
  pricing_adjustments: PricingAdjustment[]
  competitive_analysis: string
  risk_factors: RiskFactor[]
}

function buildSystemPrompt(): string {
  return `You are Bid Brain, an elite bid optimization AI for contractors and trade professionals. You analyze historical bid data, pricing patterns, and competitive dynamics to maximize win rates while maintaining profitability.

YOUR EXPERTISE INCLUDES:
- Statistical analysis of bid win/loss patterns by price, scope, and market conditions
- Competitive pricing strategy for residential and commercial trade work
- Scope gap analysis — identifying missing items that cause change orders or lost bids
- Risk assessment for pricing, scope, timeline, and market factors
- Value engineering — maximizing perceived value while controlling costs

ANALYSIS APPROACH:
1. Examine historical bid data for win rate patterns at different price points
2. Identify scope items commonly missed or underpriced
3. Assess competitive position based on market data
4. Calculate optimal pricing that balances win probability with profit margin
5. Flag risks that could impact bid success or project profitability

RESPONSE REQUIREMENTS:
- Win probability must be a realistic number 0-100 based on data patterns
- Price recommendations must account for material costs, labor, overhead, and profit margin
- Scope suggestions should be specific, actionable, and include estimated value
- Risk factors must include severity and clear mitigation strategies
- Be honest about confidence levels — if data is limited, say so

Return ONLY valid JSON matching this exact structure:
{
  "win_probability": 65,
  "recommended_price_range": {
    "low": 0,
    "optimal": 0,
    "high": 0
  },
  "scope_suggestions": [
    {
      "title": "Add specific scope item",
      "description": "Detailed description of what to include",
      "estimated_value": 500,
      "priority": "high",
      "rationale": "Why this improves the bid"
    }
  ],
  "pricing_adjustments": [
    {
      "item": "Specific line item or category",
      "current_price": 0,
      "suggested_price": 0,
      "reason": "Why adjust this price",
      "impact": "positive"
    }
  ],
  "competitive_analysis": "Detailed analysis of competitive positioning and market factors",
  "risk_factors": [
    {
      "category": "pricing|scope|timeline|market|client",
      "description": "Specific risk description",
      "severity": "high",
      "mitigation": "How to address this risk"
    }
  ]
}`
}

function buildUserMessage(
  bidData: Record<string, unknown> | null,
  historicalStats: Record<string, unknown>,
  scopeOfWork: string | null,
  estimatedAmount: number | null,
  similarBids: Record<string, unknown>[]
): string {
  const parts: string[] = []

  parts.push('=== BID OPTIMIZATION REQUEST ===')

  if (bidData) {
    parts.push(`\nCURRENT BID:`)
    parts.push(`Title: ${bidData.title || 'Untitled'}`)
    parts.push(`Bid Number: ${bidData.bid_number || 'N/A'}`)
    parts.push(`Customer: ${bidData.customer_name || 'Unknown'}`)
    parts.push(`Status: ${bidData.status || 'draft'}`)
    parts.push(`Current Total: $${bidData.total || 0}`)
    parts.push(`Subtotal: $${bidData.subtotal || 0}`)
    parts.push(`Tax Rate: ${bidData.tax_rate || 0}%`)
    if (bidData.scope_of_work) parts.push(`Scope of Work: ${bidData.scope_of_work}`)
    if (bidData.line_items) parts.push(`Line Items: ${JSON.stringify(bidData.line_items)}`)
    if (bidData.valid_until) parts.push(`Valid Until: ${bidData.valid_until}`)
  }

  if (scopeOfWork && !bidData?.scope_of_work) {
    parts.push(`\nSCOPE OF WORK: ${scopeOfWork}`)
  }

  if (estimatedAmount && !bidData?.total) {
    parts.push(`\nESTIMATED AMOUNT: $${estimatedAmount}`)
  }

  parts.push(`\nHISTORICAL BID STATISTICS:`)
  parts.push(`Total Bids: ${historicalStats.total_bids || 0}`)
  parts.push(`Accepted: ${historicalStats.accepted || 0}`)
  parts.push(`Rejected: ${historicalStats.rejected || 0}`)
  parts.push(`Win Rate: ${historicalStats.win_rate || 0}%`)
  parts.push(`Average Bid Amount: $${historicalStats.avg_amount || 0}`)
  parts.push(`Average Accepted Amount: $${historicalStats.avg_accepted_amount || 0}`)
  parts.push(`Average Rejected Amount: $${historicalStats.avg_rejected_amount || 0}`)
  parts.push(`Median Bid Amount: $${historicalStats.median_amount || 0}`)

  if (similarBids.length > 0) {
    parts.push(`\nSIMILAR PAST BIDS (${similarBids.length}):`)
    for (const sb of similarBids) {
      parts.push(`- ${sb.title} | $${sb.total} | Status: ${sb.status}${sb.scope_of_work ? ` | Scope: ${(sb.scope_of_work as string).substring(0, 200)}` : ''}`)
    }
  }

  parts.push(`\nAnalyze this bid and provide optimization recommendations. Focus on:
1. Win probability based on historical patterns
2. Optimal pricing range (low/competitive, optimal/recommended, high/premium)
3. Scope gaps or additions that could improve the bid
4. Specific pricing adjustments for line items or categories
5. Competitive positioning analysis
6. Risk factors that could affect this bid`)

  return parts.join('\n')
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
    const body: BidOptimizerRequest = await req.json()
    const { company_id, bid_id, scope_of_work, estimated_amount } = body

    // Validate required fields
    if (!company_id || typeof company_id !== 'string') {
      return new Response(JSON.stringify({ error: 'company_id is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify user belongs to this company
    const userCompanyId = user.app_metadata?.company_id
    if (userCompanyId !== company_id) {
      return new Response(JSON.stringify({ error: 'Unauthorized: company mismatch' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch the specific bid if bid_id provided
    let bidData: Record<string, unknown> | null = null
    if (bid_id) {
      const { data: bid, error: bidErr } = await supabase
        .from('bids')
        .select('*')
        .eq('id', bid_id)
        .eq('company_id', company_id)
        .single()

      if (bidErr) {
        return new Response(JSON.stringify({ error: 'Bid not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      bidData = bid
    }

    // Fetch historical bid statistics for the company
    const { data: allBids, error: statsErr } = await supabase
      .from('bids')
      .select('id, title, status, total, subtotal, scope_of_work, created_at, customer_name')
      .eq('company_id', company_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(200)

    if (statsErr) {
      console.error('Failed to fetch historical bids:', statsErr)
    }

    const bids = allBids || []
    const acceptedBids = bids.filter((b: Record<string, unknown>) => b.status === 'accepted')
    const rejectedBids = bids.filter((b: Record<string, unknown>) => b.status === 'rejected')
    const decidedBids = [...acceptedBids, ...rejectedBids]

    const avgAmount = bids.length > 0
      ? bids.reduce((sum: number, b: Record<string, unknown>) => sum + ((b.total as number) || 0), 0) / bids.length
      : 0

    const avgAccepted = acceptedBids.length > 0
      ? acceptedBids.reduce((sum: number, b: Record<string, unknown>) => sum + ((b.total as number) || 0), 0) / acceptedBids.length
      : 0

    const avgRejected = rejectedBids.length > 0
      ? rejectedBids.reduce((sum: number, b: Record<string, unknown>) => sum + ((b.total as number) || 0), 0) / rejectedBids.length
      : 0

    const sortedAmounts = bids.map((b: Record<string, unknown>) => (b.total as number) || 0).sort((a: number, b: number) => a - b)
    const medianAmount = sortedAmounts.length > 0
      ? sortedAmounts[Math.floor(sortedAmounts.length / 2)]
      : 0

    const winRate = decidedBids.length > 0
      ? Math.round((acceptedBids.length / decidedBids.length) * 100)
      : 0

    const historicalStats = {
      total_bids: bids.length,
      accepted: acceptedBids.length,
      rejected: rejectedBids.length,
      win_rate: winRate,
      avg_amount: Math.round(avgAmount * 100) / 100,
      avg_accepted_amount: Math.round(avgAccepted * 100) / 100,
      avg_rejected_amount: Math.round(avgRejected * 100) / 100,
      median_amount: Math.round(medianAmount * 100) / 100,
    }

    // Find similar past bids based on scope of work
    const searchScope = scope_of_work || (bidData?.scope_of_work as string) || ''
    let similarBids: Record<string, unknown>[] = []

    if (searchScope && bids.length > 0) {
      // Simple keyword matching — find bids with overlapping scope terms
      const keywords = searchScope.toLowerCase().split(/\s+/).filter((w: string) => w.length > 3)
      similarBids = bids
        .filter((b: Record<string, unknown>) => {
          if (bid_id && b.id === bid_id) return false // Exclude current bid
          const bScope = ((b.scope_of_work as string) || '').toLowerCase()
          const bTitle = ((b.title as string) || '').toLowerCase()
          return keywords.some((kw: string) => bScope.includes(kw) || bTitle.includes(kw))
        })
        .slice(0, 10)
    }

    // If no similar bids found by scope, use recent decided bids
    if (similarBids.length === 0) {
      similarBids = decidedBids.slice(0, 10)
    }

    // Build the prompt
    const userMessage = buildUserMessage(
      bidData,
      historicalStats,
      scope_of_work || null,
      estimated_amount || null,
      similarBids
    )

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
    let optimization: BidOptimizationResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      optimization = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      // Return a structured fallback
      optimization = {
        win_probability: 50,
        recommended_price_range: {
          low: (estimated_amount || (bidData?.total as number) || 0) * 0.85,
          optimal: estimated_amount || (bidData?.total as number) || 0,
          high: (estimated_amount || (bidData?.total as number) || 0) * 1.15,
        },
        scope_suggestions: [],
        pricing_adjustments: [],
        competitive_analysis: 'Unable to generate detailed analysis. Please try again.',
        risk_factors: [
          {
            category: 'analysis',
            description: 'AI analysis could not be fully parsed. Results may be incomplete.',
            severity: 'low',
            mitigation: 'Review bid manually and regenerate analysis.',
          },
        ],
      }
    }

    // Log usage for monitoring
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      bid_id: bid_id || null,
      company_id,
      historical_stats: historicalStats,
      ...optimization,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-bid-optimizer error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
