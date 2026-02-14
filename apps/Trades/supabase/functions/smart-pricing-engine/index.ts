// J5: Smart Pricing Engine
// POST { company_id, estimate_id, base_price, job_type, trade_type, customer_id?, urgency?, distance_miles? }
// Returns: { suggested_price, factors_applied[], total_adjustment }
// Evaluates active pricing_rules for the company against job parameters.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface PricingRule {
  id: string;
  company_id: string;
  rule_type: string;
  rule_config: Record<string, unknown>;
  trade_type: string | null;
  active: boolean;
  priority: number;
}

interface PricingFactor {
  rule_type: string;
  label: string;
  adjustment_pct: number;
  amount: number;
}

interface PricingRequest {
  company_id: string;
  estimate_id?: string;
  job_id?: string;
  base_price: number;
  job_type?: string;
  trade_type?: string;
  customer_id?: string;
  urgency?: 'standard' | 'next_day' | 'same_day' | 'emergency';
  distance_miles?: number;
  scheduled_date?: string;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const body: PricingRequest = await req.json();

    if (!body.company_id || !body.base_price) {
      return new Response(
        JSON.stringify({ error: 'company_id and base_price are required' }),
        { status: 400, headers: corsHeaders },
      );
    }

    // 1. Fetch active pricing rules for this company
    let rulesQuery = supabase
      .from('pricing_rules')
      .select('*')
      .eq('company_id', body.company_id)
      .eq('active', true)
      .is('deleted_at', null)
      .order('priority', { ascending: false });

    const { data: allRules, error: rulesErr } = await rulesQuery;
    if (rulesErr) throw rulesErr;

    // Filter rules by trade_type (null = applies to all trades)
    const rules = (allRules || []).filter(
      (r: PricingRule) => r.trade_type === null || r.trade_type === body.trade_type,
    ) as PricingRule[];

    // 2. Evaluate each rule
    const factors: PricingFactor[] = [];
    let currentPrice = body.base_price;

    for (const rule of rules) {
      const factor = await evaluateRule(supabase, rule, body, currentPrice);
      if (factor) {
        factors.push(factor);
        currentPrice += factor.amount;
      }
    }

    const suggestedPrice = Math.round(currentPrice * 100) / 100;
    const totalAdjustment = Math.round((suggestedPrice - body.base_price) * 100) / 100;

    // 3. Save suggestion to pricing_suggestions table
    if (body.estimate_id || body.job_id) {
      await supabase.from('pricing_suggestions').insert({
        company_id: body.company_id,
        estimate_id: body.estimate_id || null,
        job_id: body.job_id || null,
        base_price: body.base_price,
        suggested_price: suggestedPrice,
        factors_applied: factors,
      });
    }

    return new Response(
      JSON.stringify({
        base_price: body.base_price,
        suggested_price: suggestedPrice,
        total_adjustment: totalAdjustment,
        total_adjustment_pct: body.base_price > 0
          ? Math.round((totalAdjustment / body.base_price) * 10000) / 100
          : 0,
        factors_applied: factors,
        rules_evaluated: rules.length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    console.error('smart-pricing-engine error:', (e as Error).message);
    return new Response(
      JSON.stringify({ error: (e as Error).message }),
      { status: 500, headers: corsHeaders },
    );
  }
});

// ── Rule Evaluators ─────────────────────────────────────────

async function evaluateRule(
  supabase: ReturnType<typeof createClient>,
  rule: PricingRule,
  req: PricingRequest,
  currentPrice: number,
): Promise<PricingFactor | null> {
  const config = rule.rule_config;

  switch (rule.rule_type) {
    case 'demand_surge':
      return evaluateDemandSurge(supabase, config, req, currentPrice);

    case 'distance_markup':
      return evaluateDistanceMarkup(config, req, currentPrice);

    case 'seasonal':
      return evaluateSeasonal(config, req, currentPrice);

    case 'urgency':
      return evaluateUrgency(config, req, currentPrice);

    case 'complexity':
      return null; // Requires job complexity scoring — future enhancement

    case 'repeat_customer':
      return evaluateRepeatCustomer(supabase, config, req, currentPrice);

    case 'material_market':
      return evaluateMaterialMarket(config, currentPrice);

    case 'time_of_day':
      return evaluateTimeOfDay(config, req, currentPrice);

    default:
      return null;
  }
}

async function evaluateDemandSurge(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, unknown>,
  req: PricingRequest,
  currentPrice: number,
): Promise<PricingFactor | null> {
  const thresholdPct = (config.threshold_pct as number) || 80;
  const surgeMultiplier = (config.surge_multiplier as number) || 1.15;
  const lookbackDays = (config.lookback_days as number) || 7;

  // Count scheduled jobs in the next lookback period
  const futureDate = new Date();
  futureDate.setDate(futureDate.getDate() + lookbackDays);

  const { count: scheduledCount } = await supabase
    .from('jobs')
    .select('id', { count: 'exact', head: true })
    .eq('company_id', req.company_id)
    .in('status', ['scheduled', 'dispatched', 'enRoute', 'inProgress'])
    .lte('scheduled_start', futureDate.toISOString())
    .is('deleted_at', null);

  // Assume max capacity = 20 jobs/week (configurable future)
  const maxCapacity = (config.max_weekly_capacity as number) || 20;
  const utilization = ((scheduledCount || 0) / maxCapacity) * 100;

  if (utilization >= thresholdPct) {
    const adjustment = currentPrice * (surgeMultiplier - 1);
    return {
      rule_type: 'demand_surge',
      label: 'High Demand',
      adjustment_pct: Math.round((surgeMultiplier - 1) * 10000) / 100,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  return null;
}

function evaluateDistanceMarkup(
  config: Record<string, unknown>,
  req: PricingRequest,
  _currentPrice: number,
): PricingFactor | null {
  if (!req.distance_miles) return null;

  const baseMiles = (config.base_miles as number) || 15;
  const perMileRate = (config.per_mile_rate as number) || 2.50;
  const maxMarkup = (config.max_markup as number) || 150;

  if (req.distance_miles <= baseMiles) return null;

  const extraMiles = req.distance_miles - baseMiles;
  const markup = Math.min(extraMiles * perMileRate, maxMarkup);

  return {
    rule_type: 'distance_markup',
    label: `Distance (+${extraMiles.toFixed(0)} mi)`,
    adjustment_pct: 0,
    amount: Math.round(markup * 100) / 100,
  };
}

function evaluateSeasonal(
  config: Record<string, unknown>,
  req: PricingRequest,
  currentPrice: number,
): PricingFactor | null {
  const peakMonths = (config.peak_months as number[]) || [6, 7, 8];
  const peakMultiplier = (config.peak_multiplier as number) || 1.10;
  const offPeakDiscount = (config.off_peak_discount as number) || 0.95;

  const targetDate = req.scheduled_date ? new Date(req.scheduled_date) : new Date();
  const month = targetDate.getMonth() + 1;

  if (peakMonths.includes(month)) {
    const adjustment = currentPrice * (peakMultiplier - 1);
    return {
      rule_type: 'seasonal',
      label: 'Peak Season',
      adjustment_pct: Math.round((peakMultiplier - 1) * 10000) / 100,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  if (offPeakDiscount < 1) {
    const adjustment = currentPrice * (offPeakDiscount - 1);
    return {
      rule_type: 'seasonal',
      label: 'Off-Peak Discount',
      adjustment_pct: Math.round((offPeakDiscount - 1) * 10000) / 100,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  return null;
}

function evaluateUrgency(
  config: Record<string, unknown>,
  req: PricingRequest,
  currentPrice: number,
): PricingFactor | null {
  if (!req.urgency || req.urgency === 'standard') return null;

  const multipliers: Record<string, number> = {
    same_day: (config.same_day_multiplier as number) || 1.25,
    next_day: (config.next_day_multiplier as number) || 1.10,
    emergency: (config.emergency_multiplier as number) || 1.50,
  };

  const multiplier = multipliers[req.urgency];
  if (!multiplier || multiplier <= 1) return null;

  const labels: Record<string, string> = {
    same_day: 'Same-Day Service',
    next_day: 'Next-Day Service',
    emergency: 'Emergency Service',
  };

  const adjustment = currentPrice * (multiplier - 1);
  return {
    rule_type: 'urgency',
    label: labels[req.urgency] || 'Urgency Premium',
    adjustment_pct: Math.round((multiplier - 1) * 10000) / 100,
    amount: Math.round(adjustment * 100) / 100,
  };
}

async function evaluateRepeatCustomer(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, unknown>,
  req: PricingRequest,
  currentPrice: number,
): Promise<PricingFactor | null> {
  if (!req.customer_id) return null;

  const discountPct = (config.discount_pct as number) || 5;
  const minPreviousJobs = (config.min_previous_jobs as number) || 3;

  const { count } = await supabase
    .from('jobs')
    .select('id', { count: 'exact', head: true })
    .eq('company_id', req.company_id)
    .eq('customer_id', req.customer_id)
    .eq('status', 'completed')
    .is('deleted_at', null);

  if ((count || 0) >= minPreviousJobs) {
    const adjustment = -(currentPrice * discountPct / 100);
    return {
      rule_type: 'repeat_customer',
      label: 'Loyal Customer',
      adjustment_pct: -discountPct,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  return null;
}

function evaluateMaterialMarket(
  config: Record<string, unknown>,
  currentPrice: number,
): PricingFactor | null {
  const markupPct = (config.markup_pct as number) || 0;
  if (markupPct <= 0) return null;

  const adjustment = currentPrice * markupPct / 100;
  return {
    rule_type: 'material_market',
    label: 'Material Markup',
    adjustment_pct: markupPct,
    amount: Math.round(adjustment * 100) / 100,
  };
}

function evaluateTimeOfDay(
  config: Record<string, unknown>,
  req: PricingRequest,
  currentPrice: number,
): PricingFactor | null {
  const afterHoursMultiplier = (config.after_hours_multiplier as number) || 1.50;
  const weekendMultiplier = (config.weekend_multiplier as number) || 1.25;

  const targetDate = req.scheduled_date ? new Date(req.scheduled_date) : new Date();
  const day = targetDate.getDay();
  const hour = targetDate.getHours();

  // Weekend check (0 = Sunday, 6 = Saturday)
  if (day === 0 || day === 6) {
    const adjustment = currentPrice * (weekendMultiplier - 1);
    return {
      rule_type: 'time_of_day',
      label: 'Weekend Service',
      adjustment_pct: Math.round((weekendMultiplier - 1) * 10000) / 100,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  // After hours (before 7am or after 6pm)
  if (hour < 7 || hour >= 18) {
    const adjustment = currentPrice * (afterHoursMultiplier - 1);
    return {
      rule_type: 'time_of_day',
      label: 'After-Hours Service',
      adjustment_pct: Math.round((afterHoursMultiplier - 1) * 10000) / 100,
      amount: Math.round(adjustment * 100) / 100,
    };
  }

  return null;
}
