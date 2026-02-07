// Supabase Edge Function: ai-customer-insights
// Customer intelligence engine. Queries real customer data (jobs, invoices, activity) from Supabase,
// then passes aggregated profiles to Claude for scoring, churn risk, and upsell analysis.
// POST { company_id: string, customer_id?: string }
// If customer_id provided: detailed single customer analysis. If not: top 20 customers overview.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CustomerInsightsRequest {
  company_id: string
  customer_id?: string
}

interface CustomerProfile {
  id: string
  name: string
  type: string
  total_revenue: number
  outstanding_balance: number
  job_count: number
  last_job_date: string | null
  created_at: string
  jobs: JobSummary[]
  invoices: InvoiceSummary[]
}

interface JobSummary {
  id: string
  title: string | null
  trade_type: string
  status: string
  estimated_amount: number
  actual_amount: number | null
  created_at: string
  completed_at: string | null
}

interface InvoiceSummary {
  id: string
  invoice_number: string
  total: number
  amount_paid: number
  amount_due: number
  status: string
  created_at: string
  sent_at: string | null
  paid_at: string | null
  due_date: string | null
}

function buildSingleCustomerPrompt(): string {
  return `You are an expert customer relationship analyst for the trades and contractor industry (HVAC, electrical, plumbing, roofing, etc.). You deeply understand customer lifecycle, retention, and revenue optimization for service businesses.

You will receive detailed data about a single customer. Analyze their history and provide actionable insights.

ANALYSIS REQUIREMENTS:
- Score the customer 1-100 based on lifetime value, payment behavior, frequency, and recency.
- Assess churn risk based on time since last activity, payment patterns, and engagement.
- Identify specific upsell and cross-sell opportunities based on their service history.
- Provide concrete recommended actions the contractor should take.
- Be specific — reference actual data points, not generic advice.

Return ONLY valid JSON matching this exact structure:
{
  "customer_score": 85,
  "score_breakdown": {
    "lifetime_value_score": 0,
    "payment_behavior_score": 0,
    "frequency_score": 0,
    "recency_score": 0,
    "explanation": "Why this customer scored this way"
  },
  "lifetime_value": {
    "total_spent": 0,
    "avg_job_value": 0,
    "projected_annual_value": 0,
    "projection_basis": "How the projection was calculated"
  },
  "churn_risk": "low|medium|high",
  "churn_risk_factors": ["factor 1", "factor 2"],
  "churn_prevention_actions": ["action 1", "action 2"],
  "payment_behavior": {
    "avg_days_to_pay": 0,
    "on_time_rate_percent": 0,
    "outstanding_amount": 0,
    "assessment": "Description of payment patterns"
  },
  "upsell_opportunities": [
    {
      "service": "Specific service or upgrade",
      "rationale": "Why this makes sense for this customer",
      "estimated_value": "$X,XXX",
      "timing": "When to propose this"
    }
  ],
  "recommended_actions": [
    {
      "action": "Specific action to take",
      "priority": "high|medium|low",
      "timing": "When to do it",
      "expected_outcome": "What this should achieve"
    }
  ],
  "relationship_summary": "2-3 sentence summary of this customer relationship and top priority"
}`
}

function buildMultiCustomerPrompt(): string {
  return `You are an expert customer relationship analyst for the trades and contractor industry (HVAC, electrical, plumbing, roofing, etc.). You deeply understand customer portfolio management, segmentation, and revenue optimization.

You will receive data about a contractor's top customers. Analyze the portfolio and provide strategic insights.

ANALYSIS REQUIREMENTS:
- Score each customer 1-100 based on value, payment behavior, frequency, and recency.
- Assess churn risk for each customer.
- Identify the most valuable upsell opportunities across the portfolio.
- Provide portfolio-level strategic recommendations.
- Be specific and reference actual data.

Return ONLY valid JSON matching this exact structure:
{
  "customers": [
    {
      "customer_id": "uuid",
      "customer_name": "Name",
      "customer_score": 85,
      "lifetime_value": 0,
      "churn_risk": "low|medium|high",
      "upsell_opportunities": ["opportunity 1"],
      "recommended_actions": ["action 1"],
      "payment_behavior": "good|fair|poor",
      "key_insight": "One-line insight about this customer"
    }
  ],
  "portfolio_summary": {
    "total_customers_analyzed": 0,
    "avg_customer_score": 0,
    "high_value_count": 0,
    "at_risk_count": 0,
    "total_lifetime_revenue": 0,
    "total_outstanding": 0
  },
  "strategic_recommendations": [
    {
      "recommendation": "Specific strategic action",
      "priority": "high|medium|low",
      "affected_customers": 0,
      "expected_impact": "Revenue or retention impact"
    }
  ],
  "segment_analysis": {
    "champions": { "count": 0, "description": "High value, frequent, recent" },
    "loyal": { "count": 0, "description": "Consistent repeat customers" },
    "at_risk": { "count": 0, "description": "Previously active, declining engagement" },
    "new": { "count": 0, "description": "Recent first-time customers" },
    "dormant": { "count": 0, "description": "No activity in 6+ months" }
  },
  "executive_summary": "2-3 sentence portfolio health summary and top priority"
}`
}

function calculateDaysBetween(dateA: string, dateB: string): number {
  const a = new Date(dateA).getTime()
  const b = new Date(dateB).getTime()
  return Math.max(0, Math.round(Math.abs(b - a) / (1000 * 60 * 60 * 24)))
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
    const body: CustomerInsightsRequest = await req.json()
    const { company_id, customer_id } = body

    // Validate required fields
    if (!company_id || typeof company_id !== 'string') {
      return new Response(JSON.stringify({ error: 'company_id is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let dataSummary: string
    let systemPrompt: string
    let mode: 'single' | 'portfolio'

    if (customer_id) {
      // --- SINGLE CUSTOMER MODE ---
      mode = 'single'
      systemPrompt = buildSingleCustomerPrompt()

      // Query customer, their jobs, and their invoices in parallel
      const [customerRes, jobsRes, invoicesRes] = await Promise.all([
        supabase
          .from('customers')
          .select('id, name, email, phone, type, company_name, job_count, invoice_count, total_revenue, outstanding_balance, last_job_date, created_at, tags, referred_by')
          .eq('company_id', company_id)
          .eq('id', customer_id)
          .single(),

        supabase
          .from('jobs')
          .select('id, title, trade_type, status, estimated_amount, actual_amount, created_at, completed_at, scheduled_start')
          .eq('company_id', company_id)
          .eq('customer_id', customer_id)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(50),

        supabase
          .from('invoices')
          .select('id, invoice_number, total, amount_paid, amount_due, status, created_at, sent_at, paid_at, due_date')
          .eq('company_id', company_id)
          .eq('customer_id', customer_id)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(50),
      ])

      if (customerRes.error || !customerRes.data) {
        return new Response(JSON.stringify({ error: 'Customer not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      const customer = customerRes.data
      const jobs = jobsRes.data || []
      const invoices = invoicesRes.data || []

      // Calculate payment speed for paid invoices
      const paidInvoices = invoices.filter((inv: InvoiceSummary) => inv.status === 'paid' && inv.paid_at && inv.sent_at)
      let avgDaysToPay = 0
      let onTimeCount = 0
      if (paidInvoices.length > 0) {
        const totalDays = paidInvoices.reduce((sum: number, inv: InvoiceSummary) => {
          const days = calculateDaysBetween(inv.sent_at!, inv.paid_at!)
          if (inv.due_date && new Date(inv.paid_at!) <= new Date(inv.due_date)) {
            onTimeCount++
          }
          return sum + days
        }, 0)
        avgDaysToPay = Math.round(totalDays / paidInvoices.length)
      }

      // Trade type breakdown
      const tradeTypes: Record<string, number> = {}
      for (const job of jobs) {
        const trade = (job as JobSummary).trade_type || 'general'
        tradeTypes[trade] = (tradeTypes[trade] || 0) + 1
      }

      // Job status breakdown
      const jobStatuses: Record<string, number> = {}
      for (const job of jobs) {
        const status = (job as JobSummary).status
        jobStatuses[status] = (jobStatuses[status] || 0) + 1
      }

      // Time between jobs (frequency)
      const jobDates = jobs
        .map((j: JobSummary) => j.created_at)
        .sort((a: string, b: string) => new Date(a).getTime() - new Date(b).getTime())
      let avgDaysBetweenJobs = 0
      if (jobDates.length > 1) {
        const gaps: number[] = []
        for (let i = 1; i < jobDates.length; i++) {
          gaps.push(calculateDaysBetween(jobDates[i - 1], jobDates[i]))
        }
        avgDaysBetweenJobs = Math.round(gaps.reduce((a: number, b: number) => a + b, 0) / gaps.length)
      }

      const daysSinceLastJob = customer.last_job_date
        ? calculateDaysBetween(customer.last_job_date, new Date().toISOString())
        : -1

      dataSummary = `SINGLE CUSTOMER ANALYSIS

=== CUSTOMER PROFILE ===
Name: ${customer.name}
Type: ${customer.type}${customer.company_name ? ` (${customer.company_name})` : ''}
Customer since: ${customer.created_at}
Referred by: ${customer.referred_by || 'Unknown'}
Tags: ${(customer.tags || []).join(', ') || 'None'}

=== FINANCIAL SUMMARY ===
Total revenue: $${Number(customer.total_revenue || 0).toFixed(2)}
Outstanding balance: $${Number(customer.outstanding_balance || 0).toFixed(2)}
Total jobs: ${customer.job_count || 0}
Total invoices: ${customer.invoice_count || 0}
Last job date: ${customer.last_job_date || 'Never'}
Days since last job: ${daysSinceLastJob >= 0 ? daysSinceLastJob : 'N/A'}

=== JOB HISTORY (${jobs.length} jobs) ===
Trade types: ${Object.entries(tradeTypes).map(([t, c]) => `${t}: ${c}`).join(', ') || 'None'}
Status breakdown: ${Object.entries(jobStatuses).map(([s, c]) => `${s}: ${c}`).join(', ') || 'None'}
Average days between jobs: ${avgDaysBetweenJobs || 'N/A (single job)'}
Recent jobs:
${jobs.slice(0, 10).map((j: JobSummary) =>
  `  - ${j.title || 'Untitled'} (${j.trade_type}) — ${j.status} — Est: $${Number(j.estimated_amount || 0).toFixed(2)}, Actual: $${Number(j.actual_amount || 0).toFixed(2)} — ${j.created_at}`
).join('\n') || '  No jobs'}

=== INVOICE HISTORY (${invoices.length} invoices) ===
Average days to pay: ${avgDaysToPay || 'N/A'}
On-time payment rate: ${paidInvoices.length > 0 ? Math.round((onTimeCount / paidInvoices.length) * 100) : 'N/A'}%
Invoice statuses: ${invoices.reduce((acc: Record<string, number>, inv: InvoiceSummary) => {
  acc[inv.status] = (acc[inv.status] || 0) + 1
  return acc
}, {} as Record<string, number>) ? Object.entries(invoices.reduce((acc: Record<string, number>, inv: InvoiceSummary) => {
  acc[inv.status] = (acc[inv.status] || 0) + 1
  return acc
}, {} as Record<string, number>)).map(([s, c]) => `${s}: ${c}`).join(', ') : 'None'}
Recent invoices:
${invoices.slice(0, 10).map((inv: InvoiceSummary) =>
  `  - #${inv.invoice_number} — $${Number(inv.total || 0).toFixed(2)} — ${inv.status} — Paid: $${Number(inv.amount_paid || 0).toFixed(2)} — Due: ${inv.due_date || 'N/A'} — ${inv.created_at}`
).join('\n') || '  No invoices'}`

    } else {
      // --- PORTFOLIO MODE (Top 20 customers) ---
      mode = 'portfolio'
      systemPrompt = buildMultiCustomerPrompt()

      // Get top 20 customers by revenue
      const customersRes = await supabase
        .from('customers')
        .select('id, name, type, company_name, job_count, invoice_count, total_revenue, outstanding_balance, last_job_date, created_at, tags')
        .eq('company_id', company_id)
        .order('total_revenue', { ascending: false })
        .limit(20)

      const customers = customersRes.data || []

      if (customers.length === 0) {
        // No customers yet — return empty insights gracefully
        return new Response(JSON.stringify({
          success: true,
          mode: 'portfolio',
          customers: [],
          portfolio_summary: {
            total_customers_analyzed: 0,
            avg_customer_score: 0,
            high_value_count: 0,
            at_risk_count: 0,
            total_lifetime_revenue: 0,
            total_outstanding: 0,
          },
          strategic_recommendations: [{
            recommendation: 'Focus on acquiring your first customers through local networking, referrals, and online presence.',
            priority: 'high',
            affected_customers: 0,
            expected_impact: 'Foundation for revenue growth',
          }],
          segment_analysis: {
            champions: { count: 0, description: 'High value, frequent, recent' },
            loyal: { count: 0, description: 'Consistent repeat customers' },
            at_risk: { count: 0, description: 'Previously active, declining engagement' },
            new: { count: 0, description: 'Recent first-time customers' },
            dormant: { count: 0, description: 'No activity in 6+ months' },
          },
          executive_summary: 'No customer data available yet. Focus on building your customer base.',
          token_usage: { input: 0, output: 0 },
          model: 'claude-sonnet-4-5-20250929',
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Get customer IDs for batch queries
      const customerIds = customers.map((c: { id: string }) => c.id)

      // Query jobs and invoices for all top customers in parallel
      const [jobsRes, invoicesRes] = await Promise.all([
        supabase
          .from('jobs')
          .select('id, customer_id, trade_type, status, estimated_amount, actual_amount, created_at, completed_at')
          .eq('company_id', company_id)
          .in('customer_id', customerIds)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(500),

        supabase
          .from('invoices')
          .select('id, customer_id, total, amount_paid, amount_due, status, created_at, sent_at, paid_at, due_date')
          .eq('company_id', company_id)
          .in('customer_id', customerIds)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(500),
      ])

      const allJobs = jobsRes.data || []
      const allInvoices = invoicesRes.data || []

      // Group by customer
      const jobsByCustomer: Record<string, typeof allJobs> = {}
      const invoicesByCustomer: Record<string, typeof allInvoices> = {}
      for (const job of allJobs) {
        const cid = (job as { customer_id: string }).customer_id
        if (!jobsByCustomer[cid]) jobsByCustomer[cid] = []
        jobsByCustomer[cid].push(job)
      }
      for (const inv of allInvoices) {
        const cid = (inv as { customer_id: string }).customer_id
        if (!invoicesByCustomer[cid]) invoicesByCustomer[cid] = []
        invoicesByCustomer[cid].push(inv)
      }

      // Build portfolio summary
      const now = new Date().toISOString()
      const customerSummaries = customers.map((c: { id: string; name: string; type: string; company_name?: string; job_count: number; total_revenue: number; outstanding_balance: number; last_job_date: string | null; created_at: string; tags?: string[] }) => {
        const cJobs = jobsByCustomer[c.id] || []
        const cInvoices = invoicesByCustomer[c.id] || []

        // Trade breakdown
        const trades: Record<string, number> = {}
        for (const j of cJobs) {
          const t = (j as { trade_type: string }).trade_type
          trades[t] = (trades[t] || 0) + 1
        }

        // Payment speed
        const paid = cInvoices.filter((i: { status: string; paid_at: string | null; sent_at: string | null }) => i.status === 'paid' && i.paid_at && i.sent_at)
        let avgPay = 0
        if (paid.length > 0) {
          avgPay = Math.round(paid.reduce((s: number, i: { sent_at: string; paid_at: string }) =>
            s + calculateDaysBetween(i.sent_at, i.paid_at), 0) / paid.length)
        }

        const daysSinceLast = c.last_job_date ? calculateDaysBetween(c.last_job_date, now) : -1

        return `Customer: ${c.name}${c.company_name ? ` (${c.company_name})` : ''} [${c.id}]
  Type: ${c.type} | Since: ${c.created_at.substring(0, 10)} | Tags: ${(c.tags || []).join(', ') || 'none'}
  Revenue: $${Number(c.total_revenue || 0).toFixed(2)} | Outstanding: $${Number(c.outstanding_balance || 0).toFixed(2)}
  Jobs: ${c.job_count || 0} | Trades: ${Object.entries(trades).map(([t, n]) => `${t}:${n}`).join(', ') || 'none'}
  Last activity: ${c.last_job_date || 'never'} (${daysSinceLast >= 0 ? `${daysSinceLast} days ago` : 'N/A'})
  Avg days to pay: ${avgPay || 'N/A'} | Paid invoices: ${paid.length}/${cInvoices.length}`
      })

      const totalPortfolioRevenue = customers.reduce((s: number, c: { total_revenue: number }) => s + Number(c.total_revenue || 0), 0)
      const totalPortfolioOutstanding = customers.reduce((s: number, c: { outstanding_balance: number }) => s + Number(c.outstanding_balance || 0), 0)

      dataSummary = `CUSTOMER PORTFOLIO ANALYSIS — Top ${customers.length} Customers

=== PORTFOLIO OVERVIEW ===
Total customers analyzed: ${customers.length}
Combined lifetime revenue: $${totalPortfolioRevenue.toFixed(2)}
Combined outstanding balance: $${totalPortfolioOutstanding.toFixed(2)}
Total jobs across portfolio: ${allJobs.length}
Total invoices across portfolio: ${allInvoices.length}

=== INDIVIDUAL CUSTOMERS ===
${customerSummaries.join('\n\n')}`
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
        system: systemPrompt,
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
      // Return structured fallback based on mode
      if (mode === 'single') {
        insights = {
          customer_score: 0,
          score_breakdown: {
            lifetime_value_score: 0,
            payment_behavior_score: 0,
            frequency_score: 0,
            recency_score: 0,
            explanation: 'AI analysis could not be parsed. Raw data was provided to the model.',
          },
          lifetime_value: {
            total_spent: 0,
            avg_job_value: 0,
            projected_annual_value: 0,
            projection_basis: 'Unable to calculate — AI parsing failed.',
          },
          churn_risk: 'medium' as const,
          churn_risk_factors: ['Unable to assess — AI analysis unavailable.'],
          churn_prevention_actions: [],
          payment_behavior: {
            avg_days_to_pay: 0,
            on_time_rate_percent: 0,
            outstanding_amount: 0,
            assessment: 'AI analysis unavailable.',
          },
          upsell_opportunities: [],
          recommended_actions: [],
          relationship_summary: 'AI analysis could not be parsed. Please retry.',
        }
      } else {
        insights = {
          customers: [],
          portfolio_summary: {
            total_customers_analyzed: 0,
            avg_customer_score: 0,
            high_value_count: 0,
            at_risk_count: 0,
            total_lifetime_revenue: 0,
            total_outstanding: 0,
          },
          strategic_recommendations: [],
          segment_analysis: {
            champions: { count: 0, description: 'High value, frequent, recent' },
            loyal: { count: 0, description: 'Consistent repeat customers' },
            at_risk: { count: 0, description: 'Previously active, declining engagement' },
            new: { count: 0, description: 'Recent first-time customers' },
            dormant: { count: 0, description: 'No activity in 6+ months' },
          },
          executive_summary: 'AI analysis could not be parsed. Please retry.',
        }
      }
    }

    // Log usage for monitoring
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      mode,
      ...insights,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-customer-insights error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
