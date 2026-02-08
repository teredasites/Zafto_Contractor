import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface PayrollRequest {
  action: 'calculate_period' | 'create_stubs' | 'approve_period' | 'get_tax_config' | 'sync_gusto';
  pay_period_id?: string;
  period_type?: string;
  start_date?: string;
  end_date?: string;
  state?: string;
  tax_year?: number;
}

// Federal tax brackets 2026 (simplified)
const FEDERAL_BRACKETS = [
  { min: 0, max: 11600, rate: 0.10 },
  { min: 11600, max: 47150, rate: 0.12 },
  { min: 47150, max: 100525, rate: 0.22 },
  { min: 100525, max: 191950, rate: 0.24 },
  { min: 191950, max: 243725, rate: 0.32 },
  { min: 243725, max: 609350, rate: 0.35 },
  { min: 609350, max: Infinity, rate: 0.37 },
];

const SS_RATE = 0.062;
const SS_WAGE_BASE = 168600;
const MEDICARE_RATE = 0.0145;
const MEDICARE_ADDITIONAL_RATE = 0.009;
const MEDICARE_ADDITIONAL_THRESHOLD = 200000;

function calculateFederalTax(annualGross: number): number {
  let tax = 0;
  for (const bracket of FEDERAL_BRACKETS) {
    if (annualGross <= bracket.min) break;
    const taxable = Math.min(annualGross, bracket.max) - bracket.min;
    tax += taxable * bracket.rate;
  }
  return tax;
}

function calculatePerPeriodFederalTax(periodGross: number, periodsPerYear: number): number {
  const annualized = periodGross * periodsPerYear;
  const annualTax = calculateFederalTax(annualized);
  return Math.round((annualTax / periodsPerYear) * 100) / 100;
}

function getPeriodsPerYear(periodType: string): number {
  switch (periodType) {
    case 'weekly': return 52;
    case 'biweekly': return 26;
    case 'semimonthly': return 24;
    case 'monthly': return 12;
    default: return 26;
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: PayrollRequest = await req.json();
    const { action } = body;

    // Extract company_id from auth
    const authHeader = req.headers.get('Authorization');
    let companyId: string | null = null;
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      const { data: { user } } = await supabase.auth.getUser(token);
      companyId = user?.app_metadata?.company_id || null;
    }

    if (!companyId) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    switch (action) {
      case 'calculate_period': {
        if (!body.start_date || !body.end_date) {
          return new Response(JSON.stringify({ error: 'start_date and end_date required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const periodType = body.period_type || 'biweekly';
        const periodsPerYear = getPeriodsPerYear(periodType);

        // Get employees with active status
        const { data: employees } = await supabase
          .from('employee_records')
          .select('user_id, pay_type, pay_rate, health_plan, dental_plan, vision_plan, retirement_plan')
          .eq('company_id', companyId)
          .eq('status', 'active');

        if (!employees || employees.length === 0) {
          return new Response(JSON.stringify({ stubs: [], totals: { gross: 0, net: 0, taxes: 0, deductions: 0, count: 0 } }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Get time entries for the period
        const { data: timeEntries } = await supabase
          .from('time_entries')
          .select('user_id, hours, entry_type')
          .eq('company_id', companyId)
          .gte('clock_in', body.start_date)
          .lte('clock_in', body.end_date + 'T23:59:59Z');

        // Get tax config
        const { data: taxConfig } = await supabase
          .from('payroll_tax_configs')
          .select('*')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .single();

        // Get YTD data for each employee
        const { data: ytdStubs } = await supabase
          .from('pay_stubs')
          .select('user_id, gross_pay, social_security, medicare')
          .eq('company_id', companyId)
          .gte('created_at', `${new Date().getFullYear()}-01-01`);

        const stubs = employees.map((emp: Record<string, unknown>) => {
          const userId = emp.user_id as string;
          const payType = emp.pay_type as string;
          const payRate = (emp.pay_rate as number) || 0;

          // Calculate hours from time entries
          const empEntries = (timeEntries || []).filter((t: Record<string, unknown>) => t.user_id === userId);
          const regularHours = empEntries
            .filter((t: Record<string, unknown>) => t.entry_type !== 'overtime')
            .reduce((sum: number, t: Record<string, unknown>) => sum + ((t.hours as number) || 0), 0);
          const overtimeHours = empEntries
            .filter((t: Record<string, unknown>) => t.entry_type === 'overtime')
            .reduce((sum: number, t: Record<string, unknown>) => sum + ((t.hours as number) || 0), 0);

          // Calculate gross
          let grossPay: number;
          if (payType === 'hourly') {
            grossPay = (regularHours * payRate) + (overtimeHours * payRate * 1.5);
          } else {
            grossPay = payRate / periodsPerYear;
          }
          grossPay = Math.round(grossPay * 100) / 100;

          // YTD calculations
          const empYtdStubs = (ytdStubs || []).filter((s: Record<string, unknown>) => s.user_id === userId);
          const ytdGross = empYtdStubs.reduce((sum: number, s: Record<string, unknown>) => sum + ((s.gross_pay as number) || 0), 0);
          const ytdSS = empYtdStubs.reduce((sum: number, s: Record<string, unknown>) => sum + ((s.social_security as number) || 0), 0);

          // Federal tax
          const federalTax = calculatePerPeriodFederalTax(grossPay, periodsPerYear);

          // State tax (simplified — use config rate or default 5%)
          const stateRate = taxConfig?.suta_rate || 0.05;
          const stateTax = Math.round(grossPay * stateRate * 100) / 100;

          // Social Security (check wage base)
          const ssWagesRemaining = Math.max(0, SS_WAGE_BASE - ytdGross);
          const ssTaxable = Math.min(grossPay, ssWagesRemaining);
          const socialSecurity = Math.round(ssTaxable * SS_RATE * 100) / 100;

          // Medicare
          let medicare = Math.round(grossPay * MEDICARE_RATE * 100) / 100;
          if (ytdGross + grossPay > MEDICARE_ADDITIONAL_THRESHOLD) {
            const additionalBase = Math.max(0, (ytdGross + grossPay) - MEDICARE_ADDITIONAL_THRESHOLD);
            medicare += Math.round(additionalBase * MEDICARE_ADDITIONAL_RATE * 100) / 100;
          }

          // Benefit deductions (simplified flat amounts per period)
          const healthInsurance = emp.health_plan ? 250 : 0;
          const dentalInsurance = emp.dental_plan ? 45 : 0;
          const visionInsurance = emp.vision_plan ? 15 : 0;
          const retirement401k = emp.retirement_plan ? Math.round(grossPay * 0.06 * 100) / 100 : 0;

          const totalDeductions = federalTax + stateTax + socialSecurity + medicare + healthInsurance + dentalInsurance + visionInsurance + retirement401k;
          const netPay = Math.round((grossPay - totalDeductions) * 100) / 100;

          return {
            user_id: userId,
            hours_regular: regularHours,
            hours_overtime: overtimeHours,
            rate_regular: payRate,
            rate_overtime: payType === 'hourly' ? payRate * 1.5 : 0,
            gross_pay: grossPay,
            federal_tax: federalTax,
            state_tax: stateTax,
            local_tax: 0,
            social_security: socialSecurity,
            medicare,
            health_insurance: healthInsurance,
            dental_insurance: dentalInsurance,
            vision_insurance: visionInsurance,
            retirement_401k: retirement401k,
            other_deductions: 0,
            total_deductions: Math.round(totalDeductions * 100) / 100,
            net_pay: Math.max(0, netPay),
            ytd_gross: ytdGross + grossPay,
            ytd_federal_tax: 0, // would need full calculation
            ytd_state_tax: 0,
            ytd_social_security: ytdSS + socialSecurity,
            ytd_medicare: 0,
            ytd_net: 0,
          };
        });

        const totals = {
          gross: stubs.reduce((s: number, st: Record<string, number>) => s + st.gross_pay, 0),
          net: stubs.reduce((s: number, st: Record<string, number>) => s + st.net_pay, 0),
          taxes: stubs.reduce((s: number, st: Record<string, number>) => s + st.federal_tax + st.state_tax + st.social_security + st.medicare, 0),
          deductions: stubs.reduce((s: number, st: Record<string, number>) => s + st.total_deductions, 0),
          count: stubs.length,
        };

        return new Response(JSON.stringify({ stubs, totals }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'create_stubs': {
        if (!body.pay_period_id) {
          return new Response(JSON.stringify({ error: 'pay_period_id required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Get pay period
        const { data: period } = await supabase
          .from('pay_periods')
          .select('*')
          .eq('id', body.pay_period_id)
          .eq('company_id', companyId)
          .single();

        if (!period) {
          return new Response(JSON.stringify({ error: 'Pay period not found' }), {
            status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        // Calculate and insert stubs (would call calculate_period internally)
        // For now, just mark as processing
        await supabase
          .from('pay_periods')
          .update({ status: 'processing' })
          .eq('id', body.pay_period_id);

        return new Response(JSON.stringify({ success: true, status: 'processing' }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'approve_period': {
        if (!body.pay_period_id) {
          return new Response(JSON.stringify({ error: 'pay_period_id required' }), {
            status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const authToken = authHeader?.replace('Bearer ', '');
        const { data: { user } } = await supabase.auth.getUser(authToken!);

        await supabase
          .from('pay_periods')
          .update({
            status: 'approved',
            approved_by_user_id: user?.id,
            approved_at: new Date().toISOString(),
          })
          .eq('id', body.pay_period_id)
          .eq('company_id', companyId);

        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      case 'get_tax_config': {
        const taxYear = body.tax_year || new Date().getFullYear();
        const state = body.state || 'CT';

        const { data: config } = await supabase
          .from('payroll_tax_configs')
          .select('*')
          .eq('company_id', companyId)
          .eq('tax_year', taxYear)
          .eq('state', state)
          .single();

        return new Response(JSON.stringify({
          config: config || {
            futa_rate: 0.006,
            suta_rate: 0.032,
            suta_wage_base: 15000,
            workers_comp_rate: 0.025,
          },
          federal: {
            ss_rate: SS_RATE,
            ss_wage_base: SS_WAGE_BASE,
            medicare_rate: MEDICARE_RATE,
            medicare_additional_rate: MEDICARE_ADDITIONAL_RATE,
            medicare_additional_threshold: MEDICARE_ADDITIONAL_THRESHOLD,
            brackets: FEDERAL_BRACKETS,
          },
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      default:
        return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
