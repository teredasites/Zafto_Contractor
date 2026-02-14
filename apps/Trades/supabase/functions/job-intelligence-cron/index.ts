// J2: Job Intelligence CRON — Monthly aggregation engine
// 1. Calls autopsy generator catch-up (completed jobs without autopsies)
// 2. Regenerates autopsy_insights (by job_type, tech, season)
// 3. Generates estimate_adjustments where variance pattern is consistent (>5 jobs, >10% variance)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Minimum jobs required to generate an insight or adjustment
const MIN_SAMPLE_SIZE = 3;
// Minimum consistent variance to suggest an adjustment
const MIN_VARIANCE_PCT = 10;
// Minimum jobs for estimate adjustment suggestions
const MIN_ADJUSTMENT_JOBS = 5;

interface Autopsy {
  id: string;
  company_id: string;
  job_id: string;
  job_type: string | null;
  trade_type: string | null;
  primary_tech_id: string | null;
  gross_margin_pct: number | null;
  variance_pct: number | null;
  revenue: number | null;
  gross_profit: number | null;
  actual_labor_hours: number | null;
  actual_labor_cost: number | null;
  actual_material_cost: number | null;
  estimated_labor_cost: number | null;
  estimated_material_cost: number | null;
  estimated_total: number | null;
  actual_total: number | null;
  completed_at: string | null;
}

// ── Insight Generators ──────────────────────────────────────

function profitabilityByJobType(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  const groups: Record<string, Autopsy[]> = {};
  for (const a of autopsies) {
    const key = a.job_type || 'unknown';
    (groups[key] ??= []).push(a);
  }

  const insights: Array<Record<string, unknown>> = [];
  for (const [jobType, group] of Object.entries(groups)) {
    if (group.length < MIN_SAMPLE_SIZE) continue;

    const avgMargin = group.reduce((s, a) => s + (a.gross_margin_pct || 0), 0) / group.length;
    const totalRevenue = group.reduce((s, a) => s + (a.revenue || 0), 0);
    const totalProfit = group.reduce((s, a) => s + (a.gross_profit || 0), 0);
    const avgVariance = group.reduce((s, a) => s + (a.variance_pct || 0), 0) / group.length;

    insights.push({
      company_id: companyId,
      insight_type: 'profitability_by_job_type',
      insight_key: jobType,
      insight_data: {
        avg_margin_pct: round2(avgMargin),
        total_revenue: round2(totalRevenue),
        total_profit: round2(totalProfit),
        avg_variance_pct: round2(avgVariance),
        job_count: group.length,
      },
      sample_size: group.length,
      confidence_score: Math.min(0.5 + group.length * 0.05, 0.95),
    });
  }
  return insights;
}

function profitabilityByTech(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  const groups: Record<string, Autopsy[]> = {};
  for (const a of autopsies) {
    if (!a.primary_tech_id) continue;
    (groups[a.primary_tech_id] ??= []).push(a);
  }

  const insights: Array<Record<string, unknown>> = [];
  for (const [techId, group] of Object.entries(groups)) {
    if (group.length < MIN_SAMPLE_SIZE) continue;

    const avgMargin = group.reduce((s, a) => s + (a.gross_margin_pct || 0), 0) / group.length;
    const totalRevenue = group.reduce((s, a) => s + (a.revenue || 0), 0);
    const avgLaborHours = group.reduce((s, a) => s + (a.actual_labor_hours || 0), 0) / group.length;

    insights.push({
      company_id: companyId,
      insight_type: 'profitability_by_tech',
      insight_key: techId,
      insight_data: {
        avg_margin_pct: round2(avgMargin),
        total_revenue: round2(totalRevenue),
        avg_labor_hours: round2(avgLaborHours),
        job_count: group.length,
      },
      sample_size: group.length,
      confidence_score: Math.min(0.5 + group.length * 0.05, 0.95),
    });
  }
  return insights;
}

function profitabilityBySeason(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  const seasonOf = (dateStr: string | null): string => {
    if (!dateStr) return 'unknown';
    const month = new Date(dateStr).getMonth() + 1;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  };

  const groups: Record<string, Autopsy[]> = {};
  for (const a of autopsies) {
    const key = seasonOf(a.completed_at);
    (groups[key] ??= []).push(a);
  }

  const insights: Array<Record<string, unknown>> = [];
  for (const [season, group] of Object.entries(groups)) {
    if (group.length < MIN_SAMPLE_SIZE || season === 'unknown') continue;

    const avgMargin = group.reduce((s, a) => s + (a.gross_margin_pct || 0), 0) / group.length;
    const avgRevenue = group.reduce((s, a) => s + (a.revenue || 0), 0) / group.length;

    insights.push({
      company_id: companyId,
      insight_type: 'profitability_by_season',
      insight_key: season,
      insight_data: {
        avg_margin_pct: round2(avgMargin),
        avg_revenue: round2(avgRevenue),
        job_count: group.length,
      },
      sample_size: group.length,
      confidence_score: Math.min(0.4 + group.length * 0.06, 0.90),
    });
  }
  return insights;
}

function varianceTrends(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  // Group by month for trend analysis
  const monthly: Record<string, { variances: number[]; count: number }> = {};
  for (const a of autopsies) {
    if (!a.completed_at || a.variance_pct == null) continue;
    const monthKey = a.completed_at.slice(0, 7); // YYYY-MM
    if (!monthly[monthKey]) monthly[monthKey] = { variances: [], count: 0 };
    monthly[monthKey].variances.push(a.variance_pct);
    monthly[monthKey].count++;
  }

  const months = Object.keys(monthly).sort();
  if (months.length < 2) return [];

  const trendData: Array<{ month: string; avg_variance: number; count: number }> = [];
  for (const m of months) {
    const avg = monthly[m].variances.reduce((a, b) => a + b, 0) / monthly[m].count;
    trendData.push({ month: m, avg_variance: round2(avg), count: monthly[m].count });
  }

  return [{
    company_id: companyId,
    insight_type: 'variance_trend',
    insight_key: 'monthly',
    insight_data: { trend: trendData },
    sample_size: autopsies.length,
    confidence_score: Math.min(0.5 + months.length * 0.05, 0.90),
  }];
}

function materialOverrunPatterns(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  const overruns = autopsies.filter(
    (a) =>
      a.actual_material_cost != null &&
      a.estimated_material_cost != null &&
      a.estimated_material_cost > 0 &&
      a.actual_material_cost > a.estimated_material_cost,
  );

  if (overruns.length < MIN_SAMPLE_SIZE) return [];

  const byJobType: Record<string, { total_overrun: number; count: number }> = {};
  for (const a of overruns) {
    const key = a.job_type || 'unknown';
    if (!byJobType[key]) byJobType[key] = { total_overrun: 0, count: 0 };
    const pct = ((a.actual_material_cost! - a.estimated_material_cost!) / a.estimated_material_cost!) * 100;
    byJobType[key].total_overrun += pct;
    byJobType[key].count++;
  }

  const patterns = Object.entries(byJobType)
    .filter(([_, v]) => v.count >= 2)
    .map(([jobType, v]) => ({
      job_type: jobType,
      avg_overrun_pct: round2(v.total_overrun / v.count),
      occurrences: v.count,
    }));

  if (patterns.length === 0) return [];

  return [{
    company_id: companyId,
    insight_type: 'material_overrun_pattern',
    insight_key: 'by_job_type',
    insight_data: { patterns },
    sample_size: overruns.length,
    confidence_score: Math.min(0.5 + overruns.length * 0.04, 0.90),
  }];
}

function laborOverrunPatterns(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  const overruns = autopsies.filter(
    (a) =>
      a.actual_labor_cost != null &&
      a.estimated_labor_cost != null &&
      a.estimated_labor_cost > 0 &&
      a.actual_labor_cost > a.estimated_labor_cost,
  );

  if (overruns.length < MIN_SAMPLE_SIZE) return [];

  const byJobType: Record<string, { total_overrun: number; count: number }> = {};
  for (const a of overruns) {
    const key = a.job_type || 'unknown';
    if (!byJobType[key]) byJobType[key] = { total_overrun: 0, count: 0 };
    const pct = ((a.actual_labor_cost! - a.estimated_labor_cost!) / a.estimated_labor_cost!) * 100;
    byJobType[key].total_overrun += pct;
    byJobType[key].count++;
  }

  const patterns = Object.entries(byJobType)
    .filter(([_, v]) => v.count >= 2)
    .map(([jobType, v]) => ({
      job_type: jobType,
      avg_overrun_pct: round2(v.total_overrun / v.count),
      occurrences: v.count,
    }));

  if (patterns.length === 0) return [];

  return [{
    company_id: companyId,
    insight_type: 'labor_overrun_pattern',
    insight_key: 'by_job_type',
    insight_data: { patterns },
    sample_size: overruns.length,
    confidence_score: Math.min(0.5 + overruns.length * 0.04, 0.90),
  }];
}

// ── Estimate Adjustment Generator ───────────────────────────

function generateAdjustments(
  autopsies: Autopsy[],
  companyId: string,
): Array<Record<string, unknown>> {
  // Group by job_type
  const groups: Record<string, Autopsy[]> = {};
  for (const a of autopsies) {
    const key = a.job_type || 'unknown';
    (groups[key] ??= []).push(a);
  }

  const adjustments: Array<Record<string, unknown>> = [];

  for (const [jobType, group] of Object.entries(groups)) {
    if (group.length < MIN_ADJUSTMENT_JOBS) continue;

    // Overall cost variance
    const withVariance = group.filter((a) => a.variance_pct != null && a.estimated_total && a.estimated_total > 0);
    if (withVariance.length < MIN_ADJUSTMENT_JOBS) continue;

    const avgVariance = withVariance.reduce((s, a) => s + (a.variance_pct || 0), 0) / withVariance.length;

    // Only suggest if consistent overrun (positive variance > threshold)
    if (Math.abs(avgVariance) < MIN_VARIANCE_PCT) continue;

    // Total cost multiplier adjustment
    const multiplier = 1 + avgVariance / 100;
    adjustments.push({
      company_id: companyId,
      job_type: jobType,
      trade_type: null,
      adjustment_type: 'total_cost_multiplier',
      suggested_multiplier: round3(multiplier),
      suggested_flat_amount: null,
      based_on_jobs: withVariance.length,
      avg_variance_pct: round2(avgVariance),
      status: 'pending',
    });

    // Labor-specific adjustment
    const laborOverruns = group.filter(
      (a) => a.actual_labor_cost != null && a.estimated_labor_cost != null && a.estimated_labor_cost > 0,
    );
    if (laborOverruns.length >= MIN_ADJUSTMENT_JOBS) {
      const avgLaborVariance = laborOverruns.reduce((s, a) => {
        const pct = ((a.actual_labor_cost! - a.estimated_labor_cost!) / a.estimated_labor_cost!) * 100;
        return s + pct;
      }, 0) / laborOverruns.length;

      if (Math.abs(avgLaborVariance) >= MIN_VARIANCE_PCT) {
        adjustments.push({
          company_id: companyId,
          job_type: jobType,
          trade_type: null,
          adjustment_type: 'labor_hours_multiplier',
          suggested_multiplier: round3(1 + avgLaborVariance / 100),
          suggested_flat_amount: null,
          based_on_jobs: laborOverruns.length,
          avg_variance_pct: round2(avgLaborVariance),
          status: 'pending',
        });
      }
    }

    // Material-specific adjustment
    const materialOverruns = group.filter(
      (a) => a.actual_material_cost != null && a.estimated_material_cost != null && a.estimated_material_cost > 0,
    );
    if (materialOverruns.length >= MIN_ADJUSTMENT_JOBS) {
      const avgMaterialVariance = materialOverruns.reduce((s, a) => {
        const pct = ((a.actual_material_cost! - a.estimated_material_cost!) / a.estimated_material_cost!) * 100;
        return s + pct;
      }, 0) / materialOverruns.length;

      if (Math.abs(avgMaterialVariance) >= MIN_VARIANCE_PCT) {
        adjustments.push({
          company_id: companyId,
          job_type: jobType,
          trade_type: null,
          adjustment_type: 'material_cost_multiplier',
          suggested_multiplier: round3(1 + avgMaterialVariance / 100),
          suggested_flat_amount: null,
          based_on_jobs: materialOverruns.length,
          avg_variance_pct: round2(avgMaterialVariance),
          status: 'pending',
        });
      }
    }

    // Drive time flat add (if average drive cost > $50)
    const withDrive = group.filter((a) => (a as Record<string, unknown>)['actual_drive_cost'] as number > 0);
    if (withDrive.length >= MIN_ADJUSTMENT_JOBS) {
      const avgDriveCost =
        withDrive.reduce((s, a) => s + ((a as Record<string, unknown>)['actual_drive_cost'] as number || 0), 0) /
        withDrive.length;

      if (avgDriveCost > 50) {
        adjustments.push({
          company_id: companyId,
          job_type: jobType,
          trade_type: null,
          adjustment_type: 'drive_time_add',
          suggested_multiplier: null,
          suggested_flat_amount: round2(avgDriveCost),
          based_on_jobs: withDrive.length,
          avg_variance_pct: null,
          status: 'pending',
        });
      }
    }
  }

  return adjustments;
}

// ── Helpers ─────────────────────────────────────────────────

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

function round3(n: number): number {
  return Math.round(n * 1000) / 1000;
}

// ── Main Handler ────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // 1. Trigger catch-up autopsy generation first
    let catchUpCount = 0;
    try {
      const catchUpResp = await fetch(
        `${SUPABASE_URL}/functions/v1/job-cost-autopsy-generator`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ mode: 'catch_up' }),
        },
      );
      const catchUpResult = await catchUpResp.json();
      catchUpCount = catchUpResult.generated || 0;
      console.log(`Catch-up autopsies generated: ${catchUpCount}`);
    } catch (e) {
      console.error('Catch-up autopsy generation failed:', (e as Error).message);
    }

    // 2. Fetch all autopsies grouped by company
    const { data: allAutopsies, error: fetchErr } = await supabase
      .from('job_cost_autopsies')
      .select('*')
      .is('deleted_at', null);

    if (fetchErr) {
      throw new Error(`Failed to fetch autopsies: ${fetchErr.message}`);
    }

    const autopsies = (allAutopsies || []) as Autopsy[];

    // Group by company
    const byCompany: Record<string, Autopsy[]> = {};
    for (const a of autopsies) {
      (byCompany[a.company_id] ??= []).push(a);
    }

    let totalInsights = 0;
    let totalAdjustments = 0;

    for (const [companyId, companyAutopsies] of Object.entries(byCompany)) {
      // 3. Generate insights
      const insights: Array<Record<string, unknown>> = [
        ...profitabilityByJobType(companyAutopsies, companyId),
        ...profitabilityByTech(companyAutopsies, companyId),
        ...profitabilityBySeason(companyAutopsies, companyId),
        ...varianceTrends(companyAutopsies, companyId),
        ...materialOverrunPatterns(companyAutopsies, companyId),
        ...laborOverrunPatterns(companyAutopsies, companyId),
      ];

      // Add period timestamps
      const now = new Date();
      const periodEnd = now.toISOString().split('T')[0];
      const periodStart = new Date(now.getFullYear(), now.getMonth() - 1, 1)
        .toISOString()
        .split('T')[0];

      for (const ins of insights) {
        ins.period_start = periodStart;
        ins.period_end = periodEnd;
      }

      // Clear stale insights for this company and re-insert
      if (insights.length > 0) {
        await supabase
          .from('autopsy_insights')
          .delete()
          .eq('company_id', companyId);

        // Insert in chunks
        for (let i = 0; i < insights.length; i += 50) {
          const chunk = insights.slice(i, i + 50);
          const { error: insErr } = await supabase.from('autopsy_insights').insert(chunk);
          if (insErr) console.error(`Insight insert error for ${companyId}:`, insErr.message);
        }
        totalInsights += insights.length;
      }

      // 4. Generate estimate adjustments
      const adjustments = generateAdjustments(companyAutopsies, companyId);

      if (adjustments.length > 0) {
        // Don't delete existing — only add new pending ones that don't overlap
        for (const adj of adjustments) {
          // Check for existing pending/accepted adjustment of same type + job_type
          const { count } = await supabase
            .from('estimate_adjustments')
            .select('id', { count: 'exact', head: true })
            .eq('company_id', companyId)
            .eq('job_type', adj.job_type as string)
            .eq('adjustment_type', adj.adjustment_type as string)
            .in('status', ['pending', 'accepted']);

          if ((count || 0) === 0) {
            const { error: adjErr } = await supabase.from('estimate_adjustments').insert(adj);
            if (adjErr) {
              console.error(`Adjustment insert error:`, adjErr.message);
            } else {
              totalAdjustments++;
            }
          }
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        companies_processed: Object.keys(byCompany).length,
        catch_up_autopsies: catchUpCount,
        insights_generated: totalInsights,
        adjustments_generated: totalAdjustments,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('job-intelligence-cron error:', (e as Error).message);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: corsHeaders },
    );
  }
});
