// Supabase Edge Function: ai-growth-actions
// Generates AI-driven revenue growth actions: follow-ups, upsells, campaigns, review requests.
// Queries customer/job data and uses Claude to create personalized outreach suggestions.
// POST { company_id: string, action_type?: 'follow_up'|'upsell'|'campaign'|'review' }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GrowthActionsRequest {
  company_id: string
  action_type?: 'follow_up' | 'upsell' | 'campaign' | 'review'
}

interface GrowthAction {
  type: 'follow_up' | 'upsell' | 'campaign' | 'review'
  customer_id: string | null
  customer_name: string | null
  title: string
  description: string
  priority: 'high' | 'medium' | 'low'
  suggested_date: string
  draft_message: string | null
  estimated_value: number | null
  confidence: number
}

interface GrowthActionsResult {
  actions: GrowthAction[]
  summary: string
  total_estimated_value: number
}

function buildSystemPrompt(): string {
  return `You are a revenue growth strategist for a multi-trade contractor company. You analyze customer data, job history, and seasonal patterns to identify revenue opportunities.

YOUR EXPERTISE INCLUDES:
- Customer reactivation strategies for service businesses
- Seasonal marketing for trades (HVAC, plumbing, electrical)
- Upsell and cross-sell identification based on job history
- Review and referral solicitation best practices
- Personalized outreach messaging that feels genuine, not salesy

RESPONSE REQUIREMENTS:
- Generate specific, actionable growth suggestions
- Personalize messages using actual customer names and job history
- Prioritize by estimated revenue impact and likelihood of conversion
- Include realistic confidence scores (0.0-1.0)
- Draft messages should be conversational, professional, and brief (2-3 sentences max)
- Include estimated dollar value where applicable

Return ONLY valid JSON matching this exact structure:
{
  "actions": [
    {
      "type": "follow_up",
      "customer_id": "uuid-or-null",
      "customer_name": "Customer Name",
      "title": "Brief action title",
      "description": "Why this action matters and what to expect",
      "priority": "high",
      "suggested_date": "2025-03-15",
      "draft_message": "Hi [Name], personalized message here...",
      "estimated_value": 500,
      "confidence": 0.82
    }
  ],
  "summary": "Brief overview of the growth opportunity landscape",
  "total_estimated_value": 15000
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
    const body: GrowthActionsRequest = await req.json()
    const { company_id, action_type } = body

    // Validate required fields
    if (!company_id || typeof company_id !== 'string') {
      return new Response(JSON.stringify({ error: 'company_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (action_type && !['follow_up', 'upsell', 'campaign', 'review'].includes(action_type)) {
      return new Response(JSON.stringify({ error: 'Invalid action_type. Must be one of: follow_up, upsell, campaign, review' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Query customers, jobs, and invoices in parallel
    const now = new Date()
    const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000).toISOString()

    const [customersRes, jobsRes, invoicesRes] = await Promise.all([
      supabase
        .from('customers')
        .select('id, name, email, phone, address, tags, created_at')
        .eq('company_id', company_id)
        .limit(200),
      supabase
        .from('jobs')
        .select('id, customer_id, customer_name, title, status, tags, estimated_amount, actual_amount, completed_at, created_at')
        .eq('company_id', company_id)
        .order('created_at', { ascending: false })
        .limit(500),
      supabase
        .from('invoices')
        .select('id, customer_id, status, total, paid_at, created_at')
        .eq('company_id', company_id)
        .order('created_at', { ascending: false })
        .limit(200),
    ])

    const customers: Record<string, unknown>[] = customersRes.data || []
    const jobs: Record<string, unknown>[] = jobsRes.data || []
    const invoices: Record<string, unknown>[] = invoicesRes.data || []

    // Analyze patterns
    // 1. Customers with no jobs in 90+ days
    const customerJobMap: Record<string, { lastJob: string; jobCount: number; totalSpend: number; trades: string[] }> = {}
    for (const job of jobs) {
      const custId = job.customer_id as string
      if (!custId) continue
      const completedAt = (job.completed_at as string) || (job.created_at as string)
      const tags = (job.tags as string[]) || []
      if (!customerJobMap[custId]) {
        customerJobMap[custId] = { lastJob: completedAt, jobCount: 0, totalSpend: 0, trades: [] }
      }
      customerJobMap[custId].jobCount++
      customerJobMap[custId].totalSpend += Number(job.actual_amount || job.estimated_amount || 0)
      for (const tag of tags) {
        if (!customerJobMap[custId].trades.includes(tag)) {
          customerJobMap[custId].trades.push(tag)
        }
      }
      if (completedAt > customerJobMap[custId].lastJob) {
        customerJobMap[custId].lastJob = completedAt
      }
    }

    const inactiveCustomers = customers
      .filter((c) => {
        const map = customerJobMap[c.id as string]
        if (!map) return true // No jobs ever
        return map.lastJob < ninetyDaysAgo
      })
      .map((c) => ({
        id: c.id,
        name: c.name,
        email: c.email,
        address: c.address,
        days_inactive: customerJobMap[c.id as string]
          ? Math.floor((now.getTime() - new Date(customerJobMap[c.id as string].lastJob).getTime()) / (1000 * 60 * 60 * 24))
          : 999,
        total_spend: customerJobMap[c.id as string]?.totalSpend || 0,
        job_count: customerJobMap[c.id as string]?.jobCount || 0,
        trades: customerJobMap[c.id as string]?.trades || [],
      }))
      .sort((a, b) => b.total_spend - a.total_spend)
      .slice(0, 30)

    // 2. Completed jobs without reviews (recent ones)
    const completedJobs = jobs
      .filter((j) => j.status === 'completed' || j.status === 'invoiced')
      .slice(0, 30)
      .map((j) => ({
        id: j.id,
        customer_id: j.customer_id,
        customer_name: j.customer_name,
        title: j.title,
        completed_at: j.completed_at,
        amount: Number(j.actual_amount || j.estimated_amount || 0),
        tags: j.tags,
      }))

    // 3. Seasonal data
    const currentMonth = now.getMonth() + 1
    const seasonalContext = currentMonth >= 3 && currentMonth <= 5
      ? 'Spring: AC tune-ups, outdoor electrical, spring plumbing checks'
      : currentMonth >= 6 && currentMonth <= 8
        ? 'Summer: AC repairs peak, electrical for pools/outdoor, irrigation'
        : currentMonth >= 9 && currentMonth <= 11
          ? 'Fall: Heating prep, weatherization, gutter/roof checks, generator service'
          : 'Winter: Emergency heating, pipe freeze prevention, indoor projects'

    // Build context for Claude
    const contextMessage = `Analyze this contractor company data and generate revenue growth actions.

CURRENT DATE: ${now.toISOString().split('T')[0]}
CURRENT SEASON: ${seasonalContext}
${action_type ? `FOCUS: Generate only "${action_type}" type actions` : 'Generate a mix of all action types'}

INACTIVE CUSTOMERS (90+ days since last job):
${JSON.stringify(inactiveCustomers, null, 2)}

RECENT COMPLETED JOBS (potential review requests):
${JSON.stringify(completedJobs, null, 2)}

COMPANY STATS:
- Total customers: ${customers.length}
- Total jobs: ${jobs.length}
- Inactive customers (90+ days): ${inactiveCustomers.length}

Generate 8-15 prioritized growth actions with personalized draft messages where applicable.`

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
        messages: [{ role: 'user', content: contextMessage }],
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
    let result: GrowthActionsResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      result = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      result = {
        actions: [],
        summary: 'Analysis could not be fully parsed.',
        total_estimated_value: 0,
      }
    }

    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      ...result,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-growth-actions error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
