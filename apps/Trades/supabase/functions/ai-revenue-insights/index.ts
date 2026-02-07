// Supabase Edge Function: ai-revenue-insights
// Revenue intelligence engine. Queries real company financial data from invoices, jobs, and customers,
// then passes aggregated metrics to Claude for business analysis and recommendations.
// POST { company_id: string, period?: 'month'|'quarter'|'year', focus?: string }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RevenueInsightsRequest {
  company_id: string
  period?: 'month' | 'quarter' | 'year'
  focus?: string
}

interface PeriodRange {
  start: string
  end: string
  prev_start: string
  prev_end: string
  label: string
}

function getPeriodRange(period: 'month' | 'quarter' | 'year'): PeriodRange {
  const now = new Date()
  const end = now.toISOString()

  let start: Date
  let prevStart: Date
  let prevEnd: Date
  let label: string

  if (period === 'month') {
    start = new Date(now.getFullYear(), now.getMonth(), 1)
    prevEnd = new Date(start.getTime() - 1)
    prevStart = new Date(prevEnd.getFullYear(), prevEnd.getMonth(), 1)
    label = `${start.toLocaleString('default', { month: 'long' })} ${start.getFullYear()}`
  } else if (period === 'quarter') {
    const currentQuarter = Math.floor(now.getMonth() / 3)
    start = new Date(now.getFullYear(), currentQuarter * 3, 1)
    prevEnd = new Date(start.getTime() - 1)
    const prevQuarter = Math.floor(prevEnd.getMonth() / 3)
    prevStart = new Date(prevEnd.getFullYear(), prevQuarter * 3, 1)
    label = `Q${currentQuarter + 1} ${start.getFullYear()}`
  } else {
    start = new Date(now.getFullYear(), 0, 1)
    prevStart = new Date(now.getFullYear() - 1, 0, 1)
    prevEnd = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59)
    label = `${now.getFullYear()}`
  }

  return {
    start: start.toISOString(),
    end,
    prev_start: prevStart.toISOString(),
    prev_end: prevEnd.toISOString(),
    label,
  }
}

function buildSystemPrompt(focus?: string): string {
  return `You are an expert business analyst specializing in the trades and contractor industry (HVAC, electrical, plumbing, roofing, etc.). You have deep knowledge of contractor business operations, seasonal patterns, pricing strategies, and growth levers.

You will receive real financial data from a contractor's business. Analyze it thoroughly and provide actionable insights.

ANALYSIS REQUIREMENTS:
- Be specific and data-driven. Reference actual numbers from the data provided.
- Compare current period to previous period and calculate percentage changes.
- Identify patterns, anomalies, and opportunities.
- Provide actionable recommendations a contractor can implement immediately.
- Consider seasonality typical for the trades industry.
- If data is sparse (new company), acknowledge it and provide forward-looking guidance instead.
${focus ? `- Pay special attention to: ${focus}` : ''}

Return ONLY valid JSON matching this exact structure:
{
  "revenue_trend": {
    "current_period_revenue": 0,
    "previous_period_revenue": 0,
    "percent_change": 0,
    "trend_direction": "up|down|flat",
    "summary": "One-line trend summary"
  },
  "profit_margins": {
    "estimated_gross_margin_percent": 0,
    "analysis": "Margin analysis based on available data",
    "industry_comparison": "How this compares to typical trade contractor margins",
    "improvement_suggestions": ["suggestion 1", "suggestion 2"]
  },
  "top_services": [
    {
      "trade_type": "electrical",
      "job_count": 0,
      "total_revenue": 0,
      "avg_job_value": 0,
      "insight": "Specific insight about this service line"
    }
  ],
  "pricing_recommendations": [
    {
      "recommendation": "Specific pricing action",
      "rationale": "Why this makes sense based on the data",
      "estimated_impact": "Expected revenue impact"
    }
  ],
  "seasonal_patterns": {
    "current_season_outlook": "Analysis of current seasonal position",
    "upcoming_opportunities": ["opportunity 1", "opportunity 2"],
    "preparation_actions": ["action 1", "action 2"]
  },
  "growth_opportunities": [
    {
      "opportunity": "Specific growth lever",
      "priority": "high|medium|low",
      "effort": "low|medium|high",
      "expected_impact": "Description of potential impact",
      "first_step": "Immediate actionable first step"
    }
  ],
  "key_metrics": {
    "avg_job_value": 0,
    "collection_rate_percent": 0,
    "avg_days_to_payment": 0,
    "repeat_customer_rate_percent": 0,
    "jobs_completed_this_period": 0,
    "outstanding_receivables": 0
  },
  "executive_summary": "2-3 sentence high-level summary of the business health and top priority"
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
    const body: RevenueInsightsRequest = await req.json()
    const { company_id, period = 'month', focus } = body

    // Validate required fields
    if (!company_id || typeof company_id !== 'string') {
      return new Response(JSON.stringify({ error: 'company_id is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const validPeriods = ['month', 'quarter', 'year']
    if (!validPeriods.includes(period)) {
      return new Response(JSON.stringify({ error: `Invalid period. Must be one of: ${validPeriods.join(', ')}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const range = getPeriodRange(period as 'month' | 'quarter' | 'year')

    // Query all data in parallel using service role (bypasses RLS)
    const [
      currentInvoicesRes,
      prevInvoicesRes,
      currentJobsRes,
      prevJobsRes,
      customersRes,
      allInvoicesRes,
      overdueInvoicesRes,
    ] = await Promise.all([
      // Current period invoices
      supabase
        .from('invoices')
        .select('id, total, amount_paid, amount_due, status, created_at, paid_at, sent_at, customer_id, job_id')
        .eq('company_id', company_id)
        .is('deleted_at', null)
        .gte('created_at', range.start)
        .lte('created_at', range.end),

      // Previous period invoices
      supabase
        .from('invoices')
        .select('id, total, amount_paid, amount_due, status, created_at, paid_at, sent_at, customer_id')
        .eq('company_id', company_id)
        .is('deleted_at', null)
        .gte('created_at', range.prev_start)
        .lte('created_at', range.prev_end),

      // Current period jobs
      supabase
        .from('jobs')
        .select('id, status, trade_type, estimated_amount, actual_amount, customer_id, scheduled_start, completed_at, created_at, source')
        .eq('company_id', company_id)
        .is('deleted_at', null)
        .gte('created_at', range.start)
        .lte('created_at', range.end),

      // Previous period jobs
      supabase
        .from('jobs')
        .select('id, status, trade_type, estimated_amount, actual_amount, customer_id, completed_at, created_at')
        .eq('company_id', company_id)
        .is('deleted_at', null)
        .gte('created_at', range.prev_start)
        .lte('created_at', range.prev_end),

      // All customers (for repeat rate calculation)
      supabase
        .from('customers')
        .select('id, job_count, total_revenue, outstanding_balance, created_at, last_job_date, type')
        .eq('company_id', company_id),

      // All-time invoices for collection metrics
      supabase
        .from('invoices')
        .select('id, total, amount_paid, amount_due, status, created_at, paid_at, sent_at')
        .eq('company_id', company_id)
        .is('deleted_at', null)
        .limit(500),

      // Overdue invoices
      supabase
        .from('invoices')
        .select('id, total, amount_due, status, due_date, customer_name')
        .eq('company_id', company_id)
        .eq('status', 'overdue')
        .is('deleted_at', null),
    ])

    // Aggregate current period data
    const currentInvoices = currentInvoicesRes.data || []
    const prevInvoices = prevInvoicesRes.data || []
    const currentJobs = currentJobsRes.data || []
    const prevJobs = prevJobsRes.data || []
    const customers = customersRes.data || []
    const allInvoices = allInvoicesRes.data || []
    const overdueInvoices = overdueInvoicesRes.data || []

    // Revenue metrics
    const currentRevenue = currentInvoices.reduce((sum: number, inv: { total: number }) => sum + Number(inv.total || 0), 0)
    const prevRevenue = prevInvoices.reduce((sum: number, inv: { total: number }) => sum + Number(inv.total || 0), 0)
    const currentPaid = currentInvoices.reduce((sum: number, inv: { amount_paid: number }) => sum + Number(inv.amount_paid || 0), 0)
    const totalOutstanding = allInvoices.reduce((sum: number, inv: { amount_due: number }) => sum + Number(inv.amount_due || 0), 0)

    // Job metrics by trade type
    const tradeBreakdown: Record<string, { count: number; revenue: number; estimated: number }> = {}
    for (const job of currentJobs) {
      const trade = (job as { trade_type: string }).trade_type || 'general'
      if (!tradeBreakdown[trade]) {
        tradeBreakdown[trade] = { count: 0, revenue: 0, estimated: 0 }
      }
      tradeBreakdown[trade].count++
      tradeBreakdown[trade].revenue += Number((job as { actual_amount?: number }).actual_amount || 0)
      tradeBreakdown[trade].estimated += Number((job as { estimated_amount?: number }).estimated_amount || 0)
    }

    // Job status breakdown
    const jobStatusCounts: Record<string, number> = {}
    for (const job of currentJobs) {
      const status = (job as { status: string }).status
      jobStatusCounts[status] = (jobStatusCounts[status] || 0) + 1
    }

    // Customer metrics
    const totalCustomers = customers.length
    const repeatCustomers = customers.filter((c: { job_count: number }) => (c.job_count || 0) > 1).length
    const repeatRate = totalCustomers > 0 ? Math.round((repeatCustomers / totalCustomers) * 100) : 0

    // Collection rate (all-time)
    const totalInvoiced = allInvoices.reduce((sum: number, inv: { total: number }) => sum + Number(inv.total || 0), 0)
    const totalCollected = allInvoices.reduce((sum: number, inv: { amount_paid: number }) => sum + Number(inv.amount_paid || 0), 0)
    const collectionRate = totalInvoiced > 0 ? Math.round((totalCollected / totalInvoiced) * 100) : 0

    // Average days to payment (for paid invoices with both sent_at and paid_at)
    const paidInvoices = allInvoices.filter((inv: { status: string; paid_at: string | null; sent_at: string | null }) =>
      inv.status === 'paid' && inv.paid_at && inv.sent_at
    )
    let avgDaysToPayment = 0
    if (paidInvoices.length > 0) {
      const totalDays = paidInvoices.reduce((sum: number, inv: { paid_at: string; sent_at: string }) => {
        const paid = new Date(inv.paid_at).getTime()
        const sent = new Date(inv.sent_at).getTime()
        return sum + Math.max(0, Math.round((paid - sent) / (1000 * 60 * 60 * 24)))
      }, 0)
      avgDaysToPayment = Math.round(totalDays / paidInvoices.length)
    }

    // Job source breakdown
    const sourceBreakdown: Record<string, number> = {}
    for (const job of currentJobs) {
      const source = (job as { source?: string }).source || 'direct'
      sourceBreakdown[source] = (sourceBreakdown[source] || 0) + 1
    }

    // Completed jobs this period
    const completedJobs = currentJobs.filter((j: { status: string }) =>
      ['completed', 'invoiced'].includes(j.status)
    ).length

    // Average job value
    const jobsWithAmount = currentJobs.filter((j: { actual_amount?: number; estimated_amount?: number }) =>
      Number(j.actual_amount || j.estimated_amount || 0) > 0
    )
    const avgJobValue = jobsWithAmount.length > 0
      ? Math.round(jobsWithAmount.reduce((sum: number, j: { actual_amount?: number; estimated_amount?: number }) =>
          sum + Number(j.actual_amount || j.estimated_amount || 0), 0) / jobsWithAmount.length)
      : 0

    // Build data summary for Claude
    const dataSummary = `COMPANY FINANCIAL DATA — ${range.label} (${period})

=== REVENUE ===
Current period invoiced: $${currentRevenue.toFixed(2)} (${currentInvoices.length} invoices)
Previous period invoiced: $${prevRevenue.toFixed(2)} (${prevInvoices.length} invoices)
Current period collected: $${currentPaid.toFixed(2)}
Total outstanding receivables: $${totalOutstanding.toFixed(2)}
Overdue invoices: ${overdueInvoices.length} totaling $${overdueInvoices.reduce((s: number, i: { amount_due: number }) => s + Number(i.amount_due || 0), 0).toFixed(2)}
All-time collection rate: ${collectionRate}%
Average days to payment: ${avgDaysToPayment} days

=== JOBS ===
Current period: ${currentJobs.length} jobs (prev: ${prevJobs.length})
Completed this period: ${completedJobs}
Average job value: $${avgJobValue}
Status breakdown: ${Object.entries(jobStatusCounts).map(([s, c]) => `${s}: ${c}`).join(', ') || 'none'}

=== JOBS BY TRADE TYPE ===
${Object.entries(tradeBreakdown).map(([trade, data]) =>
  `${trade}: ${data.count} jobs, $${data.revenue.toFixed(2)} actual / $${data.estimated.toFixed(2)} estimated`
).join('\n') || 'No jobs this period'}

=== JOB SOURCES ===
${Object.entries(sourceBreakdown).map(([src, count]) => `${src}: ${count}`).join(', ') || 'No data'}

=== CUSTOMERS ===
Total customers: ${totalCustomers}
Repeat customers (2+ jobs): ${repeatCustomers} (${repeatRate}%)
Customer types: Residential ${customers.filter((c: { type: string }) => c.type === 'residential').length}, Commercial ${customers.filter((c: { type: string }) => c.type === 'commercial').length}
Top customers by revenue: ${customers
  .sort((a: { total_revenue: number }, b: { total_revenue: number }) => Number(b.total_revenue || 0) - Number(a.total_revenue || 0))
  .slice(0, 5)
  .map((c: { total_revenue: number; job_count: number }) => `$${Number(c.total_revenue || 0).toFixed(2)} (${c.job_count || 0} jobs)`)
  .join(', ') || 'No data'}

=== INVOICE STATUS DISTRIBUTION ===
${allInvoices.reduce((acc: Record<string, number>, inv: { status: string }) => {
  acc[inv.status] = (acc[inv.status] || 0) + 1
  return acc
}, {} as Record<string, number>) ? Object.entries(allInvoices.reduce((acc: Record<string, number>, inv: { status: string }) => {
  acc[inv.status] = (acc[inv.status] || 0) + 1
  return acc
}, {} as Record<string, number>)).map(([s, c]) => `${s}: ${c}`).join(', ') : 'none'}

${focus ? `\n=== SPECIAL FOCUS ===\nThe business owner wants specific insight on: ${focus}` : ''}`

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
        system: buildSystemPrompt(focus),
        messages: [{ role: 'user', content: dataSummary }],
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
    let insights: Record<string, unknown>
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      insights = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      // Return structured fallback
      insights = {
        revenue_trend: {
          current_period_revenue: currentRevenue,
          previous_period_revenue: prevRevenue,
          percent_change: prevRevenue > 0 ? Math.round(((currentRevenue - prevRevenue) / prevRevenue) * 100) : 0,
          trend_direction: currentRevenue >= prevRevenue ? 'up' : 'down',
          summary: 'Unable to generate AI analysis. Raw metrics provided.',
        },
        profit_margins: {
          estimated_gross_margin_percent: 0,
          analysis: 'AI analysis unavailable. Review raw data.',
          industry_comparison: 'Typical trade contractor gross margins range 35-55%.',
          improvement_suggestions: [],
        },
        top_services: Object.entries(tradeBreakdown).map(([trade, data]) => ({
          trade_type: trade,
          job_count: data.count,
          total_revenue: data.revenue,
          avg_job_value: data.count > 0 ? Math.round(data.revenue / data.count) : 0,
          insight: 'AI analysis unavailable.',
        })),
        pricing_recommendations: [],
        seasonal_patterns: {
          current_season_outlook: 'AI analysis unavailable.',
          upcoming_opportunities: [],
          preparation_actions: [],
        },
        growth_opportunities: [],
        key_metrics: {
          avg_job_value: avgJobValue,
          collection_rate_percent: collectionRate,
          avg_days_to_payment: avgDaysToPayment,
          repeat_customer_rate_percent: repeatRate,
          jobs_completed_this_period: completedJobs,
          outstanding_receivables: totalOutstanding,
        },
        executive_summary: 'AI analysis could not be parsed. Raw financial metrics have been provided in key_metrics.',
      }
    }

    // Log usage for monitoring
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      period: range.label,
      period_type: period,
      ...insights,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-revenue-insights error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
