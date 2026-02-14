// J2: Job Cost Autopsy Generator
// Called via pg_net trigger when job.status -> 'completed', or manually via HTTP POST.
// Pulls time_entries, receipts, mileage_trips + estimate snapshot.
// Calculates actual vs estimated costs. Upserts into job_cost_autopsies.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// IRS standard mileage rate (cents per mile -> dollars)
const MILEAGE_RATE = 0.67;
// Average drive speed for time estimation (mph)
const AVG_DRIVE_SPEED_MPH = 35;

interface AutopsyResult {
  job_id: string;
  company_id: string;
  estimated_labor_hours: number | null;
  estimated_labor_cost: number | null;
  estimated_material_cost: number | null;
  estimated_total: number | null;
  actual_labor_hours: number;
  actual_labor_cost: number;
  actual_material_cost: number;
  actual_drive_time_hours: number;
  actual_drive_cost: number;
  actual_callbacks: number;
  actual_change_order_cost: number;
  actual_total: number;
  revenue: number;
  gross_profit: number;
  gross_margin_pct: number;
  variance_pct: number;
  job_type: string | null;
  trade_type: string | null;
  primary_tech_id: string | null;
  completed_at: string | null;
}

async function generateAutopsy(
  supabase: ReturnType<typeof createClient>,
  jobId: string,
  companyId: string,
): Promise<AutopsyResult | null> {
  // 1. Fetch job details
  const { data: job, error: jobErr } = await supabase
    .from('jobs')
    .select('id, company_id, status, job_type, actual_amount, completed_at, customer_id')
    .eq('id', jobId)
    .is('deleted_at', null)
    .single();

  if (jobErr || !job) {
    console.error(`Job ${jobId} not found:`, jobErr?.message);
    return null;
  }

  if (job.status !== 'completed') {
    console.log(`Job ${jobId} status is ${job.status}, not completed — skipping`);
    return null;
  }

  // 2. Fetch estimate snapshot (linked via estimates.job_id)
  const { data: estimate } = await supabase
    .from('estimates')
    .select('id, subtotal, grand_total')
    .eq('job_id', jobId)
    .is('deleted_at', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  // 3. Fetch estimate line items for labor/material breakdown
  let estimatedLaborCost: number | null = null;
  let estimatedMaterialCost: number | null = null;
  let estimatedLaborHours: number | null = null;

  if (estimate?.id) {
    const { data: lineItems } = await supabase
      .from('estimate_line_items')
      .select('quantity, labor_rate, material_cost, equipment_cost, line_total')
      .eq('estimate_id', estimate.id);

    if (lineItems && lineItems.length > 0) {
      estimatedLaborCost = lineItems.reduce(
        (sum: number, li: { quantity: number; labor_rate: number }) =>
          sum + (li.quantity || 0) * (li.labor_rate || 0),
        0,
      );
      estimatedMaterialCost = lineItems.reduce(
        (sum: number, li: { quantity: number; material_cost: number }) =>
          sum + (li.quantity || 0) * (li.material_cost || 0),
        0,
      );
    }
  }

  const estimatedTotal = estimate?.subtotal ?? null;

  // 4. Fetch actual labor from time_entries
  const { data: timeEntries } = await supabase
    .from('time_entries')
    .select('total_minutes, labor_cost, user_id')
    .eq('job_id', jobId)
    .is('deleted_at', null)
    .neq('status', 'rejected');

  const actualLaborMinutes = (timeEntries || []).reduce(
    (sum: number, te: { total_minutes: number | null }) => sum + (te.total_minutes || 0),
    0,
  );
  const actualLaborHours = Math.round((actualLaborMinutes / 60) * 100) / 100;
  const actualLaborCost = (timeEntries || []).reduce(
    (sum: number, te: { labor_cost: number | null }) => sum + (te.labor_cost || 0),
    0,
  );

  // Determine primary tech (most labor hours)
  const techHours: Record<string, number> = {};
  for (const te of timeEntries || []) {
    const uid = te.user_id as string;
    if (uid) techHours[uid] = (techHours[uid] || 0) + (te.total_minutes || 0);
  }
  const primaryTechId = Object.entries(techHours).sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;

  // 5. Fetch actual materials from receipts
  const { data: receipts } = await supabase
    .from('receipts')
    .select('amount')
    .eq('job_id', jobId)
    .is('deleted_at', null);

  const actualMaterialCost = (receipts || []).reduce(
    (sum: number, r: { amount: number | null }) => sum + (r.amount || 0),
    0,
  );

  // 6. Fetch mileage
  const { data: trips } = await supabase
    .from('mileage_trips')
    .select('distance_miles')
    .eq('job_id', jobId)
    .is('deleted_at', null);

  const totalMiles = (trips || []).reduce(
    (sum: number, t: { distance_miles: number | null }) => sum + (t.distance_miles || 0),
    0,
  );
  const actualDriveTimeHours = Math.round((totalMiles / AVG_DRIVE_SPEED_MPH) * 100) / 100;
  const actualDriveCost = Math.round(totalMiles * MILEAGE_RATE * 100) / 100;

  // 7. Count callbacks (completed jobs for same customer after this job was created)
  // Simple heuristic: count other jobs for same customer with 'callback' in notes or same job_type
  let actualCallbacks = 0;
  if (job.customer_id) {
    const { count } = await supabase
      .from('jobs')
      .select('id', { count: 'exact', head: true })
      .eq('customer_id', job.customer_id)
      .eq('company_id', companyId)
      .neq('id', jobId)
      .is('deleted_at', null)
      .gt('created_at', job.completed_at || new Date().toISOString());

    actualCallbacks = count || 0;
  }

  // 8. Calculate totals
  const actualChangeOrderCost = 0; // Future: pull from change_orders table when it exists
  const actualTotal = actualLaborCost + actualMaterialCost + actualDriveCost + actualChangeOrderCost;
  const revenue = job.actual_amount || estimate?.grand_total || actualTotal;
  const grossProfit = revenue - actualTotal;
  const grossMarginPct = revenue > 0
    ? Math.round((grossProfit / revenue) * 10000) / 100
    : 0;
  const variancePct = estimatedTotal && estimatedTotal > 0
    ? Math.round(((actualTotal - estimatedTotal) / estimatedTotal) * 10000) / 100
    : 0;

  // 9. Determine trade_type from job metadata or estimate
  const tradeType = null; // Future: pull from job.trade_type or company settings

  return {
    job_id: jobId,
    company_id: companyId,
    estimated_labor_hours: estimatedLaborHours,
    estimated_labor_cost: estimatedLaborCost,
    estimated_material_cost: estimatedMaterialCost,
    estimated_total: estimatedTotal,
    actual_labor_hours: actualLaborHours,
    actual_labor_cost: actualLaborCost,
    actual_material_cost: actualMaterialCost,
    actual_drive_time_hours: actualDriveTimeHours,
    actual_drive_cost: actualDriveCost,
    actual_callbacks: actualCallbacks,
    actual_change_order_cost: actualChangeOrderCost,
    actual_total: actualTotal,
    revenue,
    gross_profit: grossProfit,
    gross_margin_pct: grossMarginPct,
    variance_pct: variancePct,
    job_type: job.job_type || null,
    trade_type: tradeType,
    primary_tech_id: primaryTechId,
    completed_at: job.completed_at || new Date().toISOString(),
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const body = await req.json();

    // Support single job or batch mode
    const jobIds: Array<{ job_id: string; company_id: string }> = [];

    if (body.job_id && body.company_id) {
      // Single job (from DB trigger)
      jobIds.push({ job_id: body.job_id, company_id: body.company_id });
    } else if (body.mode === 'catch_up') {
      // Catch-up mode: find completed jobs without autopsies
      const { data: jobs } = await supabase
        .from('jobs')
        .select('id, company_id')
        .eq('status', 'completed')
        .is('deleted_at', null)
        .not('id', 'in', `(SELECT job_id FROM job_cost_autopsies)`)
        .limit(100);

      // The NOT IN subquery won't work via PostgREST — use a different approach
      const { data: existingAutopsies } = await supabase
        .from('job_cost_autopsies')
        .select('job_id');

      const existingJobIds = new Set((existingAutopsies || []).map((a: { job_id: string }) => a.job_id));

      const { data: completedJobs } = await supabase
        .from('jobs')
        .select('id, company_id')
        .eq('status', 'completed')
        .is('deleted_at', null)
        .limit(500);

      for (const j of completedJobs || []) {
        if (!existingJobIds.has(j.id)) {
          jobIds.push({ job_id: j.id, company_id: j.company_id });
        }
      }
    } else {
      return new Response(
        JSON.stringify({ error: 'Provide job_id + company_id, or mode=catch_up' }),
        { status: 400, headers: corsHeaders },
      );
    }

    let generated = 0;
    let failed = 0;

    for (const { job_id, company_id } of jobIds) {
      try {
        const autopsy = await generateAutopsy(supabase, job_id, company_id);
        if (!autopsy) {
          failed++;
          continue;
        }

        // Upsert (unique constraint on job_id)
        const { error: upsertErr } = await supabase
          .from('job_cost_autopsies')
          .upsert(autopsy, { onConflict: 'job_id' });

        if (upsertErr) {
          console.error(`Upsert failed for job ${job_id}:`, upsertErr.message);
          failed++;
        } else {
          generated++;
        }
      } catch (e) {
        console.error(`Autopsy generation failed for job ${job_id}:`, (e as Error).message);
        failed++;
      }
    }

    return new Response(
      JSON.stringify({ success: true, processed: jobIds.length, generated, failed }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('job-cost-autopsy-generator error:', (e as Error).message);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: corsHeaders },
    );
  }
});
