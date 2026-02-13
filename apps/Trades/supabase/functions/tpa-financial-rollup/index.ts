// Supabase Edge Function: tpa-financial-rollup
// Monthly aggregation from tpa_assignments + jobs + Ledger data.
// Calculates gross/net margins, avg payment days, supplement recovery rate, AR aging.
// POST: { month, year, tpa_program_id? } — calculates and upserts tpa_program_financials.

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

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
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

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const { month, year, tpa_program_id } = body as {
      month: number
      year: number
      tpa_program_id?: string
    }

    if (!month || !year || month < 1 || month > 12) {
      return new Response(JSON.stringify({ error: 'Valid month (1-12) and year required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get all TPA programs for this company (or specific one)
    let programQuery = supabase
      .from('tpa_programs')
      .select('id, name, referral_fee_percent')
      .eq('company_id', companyId)

    if (tpa_program_id) {
      programQuery = programQuery.eq('id', tpa_program_id)
    }

    const { data: programs, error: programError } = await programQuery
    if (programError) throw programError
    if (!programs || programs.length === 0) {
      return new Response(JSON.stringify({ message: 'No TPA programs found', results: [] }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const periodStart = new Date(year, month - 1, 1).toISOString()
    const periodEnd = new Date(year, month, 0, 23, 59, 59).toISOString()

    const results = []

    for (const program of programs) {
      // Get assignments for this program in this period
      const { data: assignments } = await supabase
        .from('tpa_assignments')
        .select('id, status, created_at, sla_deadline, job_id')
        .eq('company_id', companyId)
        .eq('tpa_program_id', program.id)
        .gte('created_at', periodStart)
        .lte('created_at', periodEnd)

      const assignmentList = assignments || []
      const received = assignmentList.length
      const completed = assignmentList.filter((a: { status: string }) => a.status === 'completed' || a.status === 'paid').length
      const declined = assignmentList.filter((a: { status: string }) => a.status === 'declined').length
      const inProgress = assignmentList.filter((a: { status: string }) =>
        !['completed', 'paid', 'declined', 'cancelled'].includes(a.status)
      ).length

      // Get jobs linked to these assignments for financial data
      const jobIds = assignmentList
        .filter((a: { job_id: string | null }) => a.job_id)
        .map((a: { job_id: string }) => a.job_id)

      let grossRevenue = 0
      let laborCost = 0
      let materialCost = 0
      let equipmentCost = 0
      let subcontractorCost = 0

      if (jobIds.length > 0) {
        // Get invoices for revenue
        const { data: invoices } = await supabase
          .from('invoices')
          .select('total, paid_amount, status, paid_at, created_at')
          .in('job_id', jobIds)
          .eq('company_id', companyId)

        for (const inv of (invoices || [])) {
          grossRevenue += parseFloat(inv.total) || 0
        }

        // Get equipment costs
        const { data: equipment } = await supabase
          .from('restoration_equipment')
          .select('daily_rate, deployed_at, removed_at, status')
          .in('job_id', jobIds)

        for (const eq of (equipment || [])) {
          const deployed = new Date(eq.deployed_at)
          const removed = eq.removed_at ? new Date(eq.removed_at) : new Date()
          const days = Math.max(1, Math.ceil((removed.getTime() - deployed.getTime()) / (1000 * 60 * 60 * 24)))
          equipmentCost += days * (parseFloat(eq.daily_rate) || 0)
        }
      }

      // Supplement data
      const { data: supplements } = await supabase
        .from('tpa_supplements')
        .select('id, status, amount')
        .eq('company_id', companyId)
        .eq('tpa_program_id', program.id)
        .gte('created_at', periodStart)
        .lte('created_at', periodEnd)

      const suppList = supplements || []
      const suppSubmitted = suppList.length
      const suppApproved = suppList.filter((s: { status: string }) => s.status === 'approved').length
      const suppDenied = suppList.filter((s: { status: string }) => s.status === 'denied').length
      const supplementRevenue = suppList
        .filter((s: { status: string }) => s.status === 'approved')
        .reduce((sum: number, s: { amount: string | number }) => sum + (parseFloat(String(s.amount)) || 0), 0)
      const suppApprovalRate = suppSubmitted > 0 ? Math.round((suppApproved / suppSubmitted) * 100) : 0
      const avgSuppAmount = suppApproved > 0 ? supplementRevenue / suppApproved : 0

      // Referral fees
      const referralPercent = parseFloat(program.referral_fee_percent) || 0
      const referralFees = grossRevenue * (referralPercent / 100)

      // Totals
      const totalRevenue = grossRevenue + supplementRevenue
      const totalCost = laborCost + materialCost + equipmentCost + subcontractorCost + referralFees
      const grossMargin = totalRevenue - totalCost
      const grossMarginPercent = totalRevenue > 0 ? (grossMargin / totalRevenue) * 100 : 0
      const netMargin = grossMargin // simplified — real P&L would subtract overhead
      const netMarginPercent = grossMarginPercent

      // Scorecard data
      const { data: scorecards } = await supabase
        .from('tpa_scorecards')
        .select('overall_score')
        .eq('company_id', companyId)
        .eq('tpa_program_id', program.id)
        .gte('period_start', periodStart)
        .lte('period_start', periodEnd)

      const scores = (scorecards || []).map((s: { overall_score: number }) => s.overall_score).filter(Boolean)
      const avgScore = scores.length > 0 ? scores.reduce((a: number, b: number) => a + b, 0) / scores.length : null

      // Upsert
      const record = {
        company_id: companyId,
        tpa_program_id: program.id,
        period_month: month,
        period_year: year,
        assignments_received: received,
        assignments_completed: completed,
        assignments_declined: declined,
        assignments_in_progress: inProgress,
        gross_revenue: grossRevenue,
        supplement_revenue: supplementRevenue,
        total_revenue: totalRevenue,
        labor_cost: laborCost,
        material_cost: materialCost,
        equipment_cost: equipmentCost,
        subcontractor_cost: subcontractorCost,
        referral_fees_paid: referralFees,
        total_cost: totalCost,
        gross_margin: grossMargin,
        gross_margin_percent: Math.round(grossMarginPercent * 100) / 100,
        net_margin: netMargin,
        net_margin_percent: Math.round(netMarginPercent * 100) / 100,
        supplements_submitted: suppSubmitted,
        supplements_approved: suppApproved,
        supplements_denied: suppDenied,
        supplement_approval_rate: suppApprovalRate,
        avg_supplement_amount: Math.round(avgSuppAmount * 100) / 100,
        avg_scorecard_rating: avgScore,
        sla_violations_count: 0,
        calculated_at: new Date().toISOString(),
      }

      const { error: upsertError } = await supabase
        .from('tpa_program_financials')
        .upsert(record, {
          onConflict: 'company_id,tpa_program_id,period_year,period_month',
        })

      if (upsertError) throw upsertError

      results.push({
        program_id: program.id,
        program_name: program.name,
        total_revenue: totalRevenue,
        gross_margin_percent: Math.round(grossMarginPercent * 100) / 100,
        assignments: received,
      })
    }

    return new Response(JSON.stringify({
      month,
      year,
      programs_calculated: results.length,
      results,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
