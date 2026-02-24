'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ────────────────────────────────────────────
// Types
// ────────────────────────────────────────────

export interface ScheduleOfValuesItem {
  item: string;
  description: string;
  scheduled_value: number;
  prev_completed: number;
  this_period: number;
  materials_stored: number;
  total_completed: number;
  percent_complete: number;
  balance_to_finish: number;
  retainage: number;
}

export interface ProgressBilling {
  id: string;
  jobId: string;
  jobTitle: string;
  customerName: string;
  applicationNumber: number;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  contractAmount: number;
  changeOrdersAmount: number;
  revisedContract: number;
  scheduleOfValues: ScheduleOfValuesItem[];
  totalCompletedToDate: number;
  totalRetainage: number;
  lessPreviousApplications: number;
  currentPaymentDue: number;
  status: 'draft' | 'submitted' | 'approved' | 'paid';
  submittedAt: string | null;
  approvedBy: string | null;
  approvedAt: string | null;
  createdAt: string;
}

export interface RetentionRecord {
  id: string;
  jobId: string;
  jobTitle: string;
  customerName: string;
  retentionRate: number;
  totalBilled: number;
  totalRetained: number;
  totalReleased: number;
  balanceHeld: number;
  releaseConditions: string | null;
  status: 'active' | 'partially_released' | 'fully_released';
  createdAt: string;
}

export interface WIPRow {
  jobId: string;
  jobTitle: string;
  customerName: string;
  costsIncurred: number;
  billingsToDate: number;
  estimatedGross: number;
  overUnder: number;
  status: 'over_billed' | 'under_billed' | 'on_track';
}

export interface CertifiedPayrollRow {
  employeeName: string;
  classification: string;
  regularHours: number;
  overtimeHours: number;
  regularRate: number;
  overtimeRate: number;
  grossPay: number;
}

// ────────────────────────────────────────────
// Mappers
// ────────────────────────────────────────────

function mapBilling(row: Record<string, unknown>): ProgressBilling {
  const job = (row.jobs || {}) as Record<string, unknown>;
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    jobTitle: (job.title as string) || 'Untitled Job',
    customerName: (job.customer_name as string) || 'Unknown',
    applicationNumber: Number(row.application_number || 0),
    billingPeriodStart: row.billing_period_start as string,
    billingPeriodEnd: row.billing_period_end as string,
    contractAmount: Number(row.contract_amount || 0),
    changeOrdersAmount: Number(row.change_orders_amount || 0),
    revisedContract: Number(row.revised_contract || 0),
    scheduleOfValues: (row.schedule_of_values as ScheduleOfValuesItem[]) || [],
    totalCompletedToDate: Number(row.total_completed_to_date || 0),
    totalRetainage: Number(row.total_retainage || 0),
    lessPreviousApplications: Number(row.less_previous_applications || 0),
    currentPaymentDue: Number(row.current_payment_due || 0),
    status: (row.status as ProgressBilling['status']) || 'draft',
    submittedAt: (row.submitted_at as string) || null,
    approvedBy: (row.approved_by as string) || null,
    approvedAt: (row.approved_at as string) || null,
    createdAt: row.created_at as string,
  };
}

function mapRetention(row: Record<string, unknown>): RetentionRecord {
  const job = (row.jobs || {}) as Record<string, unknown>;
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    jobTitle: (job.title as string) || 'Untitled Job',
    customerName: (job.customer_name as string) || 'Unknown',
    retentionRate: Number(row.retention_rate || 10),
    totalBilled: Number(row.total_billed || 0),
    totalRetained: Number(row.total_retained || 0),
    totalReleased: Number(row.total_released || 0),
    balanceHeld: Number(row.balance_held || 0),
    releaseConditions: (row.release_conditions as string) || null,
    status: (row.status as RetentionRecord['status']) || 'active',
    createdAt: row.created_at as string,
  };
}

// ────────────────────────────────────────────
// Hook
// ────────────────────────────────────────────

export function useConstructionAccounting() {
  const [billings, setBillings] = useState<ProgressBilling[]>([]);
  const [retentionRecords, setRetentionRecords] = useState<RetentionRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ──────── Progress Billing ────────

  const fetchBillings = useCallback(async (jobId?: string) => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase
        .from('progress_billings')
        .select('*, jobs(title, customer_name)')
        .order('application_number', { ascending: false });

      if (jobId) {
        query = query.eq('job_id', jobId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setBillings((data || []).map(mapBilling));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load progress billings');
    } finally {
      setLoading(false);
    }
  }, []);

  const createBilling = useCallback(async (input: {
    jobId: string;
    billingPeriodStart: string;
    billingPeriodEnd: string;
    contractAmount: number;
    changeOrdersAmount: number;
    scheduleOfValues: ScheduleOfValuesItem[];
  }) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      // Auto-increment application number per job
      const { data: lastApp } = await supabase
        .from('progress_billings')
        .select('application_number')
        .eq('job_id', input.jobId)
        .eq('company_id', companyId)
        .order('application_number', { ascending: false })
        .limit(1);

      const nextAppNum = (lastApp && lastApp.length > 0)
        ? Number(lastApp[0].application_number) + 1
        : 1;

      // Calculate totals from schedule of values
      const totalCompletedToDate = input.scheduleOfValues.reduce(
        (sum, item) => sum + (item.total_completed || 0), 0
      );
      const totalRetainage = input.scheduleOfValues.reduce(
        (sum, item) => sum + (item.retainage || 0), 0
      );

      // Get less_previous_applications from the previous billing for this job
      let lessPrevious = 0;
      if (nextAppNum > 1) {
        const { data: prevBilling } = await supabase
          .from('progress_billings')
          .select('total_completed_to_date, total_retainage')
          .eq('job_id', input.jobId)
          .eq('company_id', companyId)
          .eq('application_number', nextAppNum - 1)
          .limit(1);

        if (prevBilling && prevBilling.length > 0) {
          lessPrevious = Number(prevBilling[0].total_completed_to_date || 0)
            - Number(prevBilling[0].total_retainage || 0);
        }
      }

      const currentPaymentDue = totalCompletedToDate - totalRetainage - lessPrevious;
      const revisedContract = input.contractAmount + input.changeOrdersAmount;

      const { data: result, error: err } = await supabase
        .from('progress_billings')
        .insert({
          company_id: companyId,
          job_id: input.jobId,
          application_number: nextAppNum,
          billing_period_start: input.billingPeriodStart,
          billing_period_end: input.billingPeriodEnd,
          contract_amount: input.contractAmount,
          change_orders_amount: input.changeOrdersAmount,
          revised_contract: revisedContract,
          schedule_of_values: input.scheduleOfValues,
          total_completed_to_date: totalCompletedToDate,
          total_retainage: totalRetainage,
          less_previous_applications: lessPrevious,
          current_payment_due: currentPaymentDue,
          status: 'draft',
          created_by_user_id: user.id,
        })
        .select('id')
        .single();

      if (err) throw err;
      return result.id as string;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to create billing';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  const updateBilling = useCallback(async (id: string, data: Partial<{
    billingPeriodStart: string;
    billingPeriodEnd: string;
    contractAmount: number;
    changeOrdersAmount: number;
    scheduleOfValues: ScheduleOfValuesItem[];
  }>) => {
    try {
      setError(null);
      const supabase = getSupabase();

      const updateData: Record<string, unknown> = { updated_at: new Date().toISOString() };
      if (data.billingPeriodStart !== undefined) updateData.billing_period_start = data.billingPeriodStart;
      if (data.billingPeriodEnd !== undefined) updateData.billing_period_end = data.billingPeriodEnd;
      if (data.contractAmount !== undefined) updateData.contract_amount = data.contractAmount;
      if (data.changeOrdersAmount !== undefined) updateData.change_orders_amount = data.changeOrdersAmount;

      if (data.scheduleOfValues !== undefined) {
        updateData.schedule_of_values = data.scheduleOfValues;
        updateData.total_completed_to_date = data.scheduleOfValues.reduce(
          (sum, item) => sum + (item.total_completed || 0), 0
        );
        updateData.total_retainage = data.scheduleOfValues.reduce(
          (sum, item) => sum + (item.retainage || 0), 0
        );
      }

      if (data.contractAmount !== undefined || data.changeOrdersAmount !== undefined) {
        const contract = data.contractAmount ?? 0;
        const co = data.changeOrdersAmount ?? 0;
        updateData.revised_contract = contract + co;
      }

      const { error: err } = await supabase
        .from('progress_billings')
        .update(updateData)
        .eq('id', id);

      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to update billing';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  const submitBilling = useCallback(async (id: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('progress_billings')
        .update({
          status: 'submitted',
          submitted_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to submit billing';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  const approveBilling = useCallback(async (id: string, approvedBy: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('progress_billings')
        .update({
          status: 'approved',
          approved_by: approvedBy,
          approved_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to approve billing';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  // ──────── Retention Tracking ────────

  const fetchRetention = useCallback(async (jobId?: string) => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      let query = supabase
        .from('retention_tracking')
        .select('*, jobs(title, customer_name)')
        .order('created_at', { ascending: false });

      if (jobId) {
        query = query.eq('job_id', jobId);
      }

      const { data, error: err } = await query;
      if (err) throw err;
      setRetentionRecords((data || []).map(mapRetention));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load retention records');
    } finally {
      setLoading(false);
    }
  }, []);

  const createRetention = useCallback(async (
    jobId: string,
    retentionRate: number,
    releaseConditions?: string,
  ) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const companyId = user.app_metadata?.company_id;
      if (!companyId) throw new Error('No company associated');

      const { data: result, error: err } = await supabase
        .from('retention_tracking')
        .insert({
          company_id: companyId,
          job_id: jobId,
          retention_rate: retentionRate,
          total_billed: 0,
          total_retained: 0,
          total_released: 0,
          balance_held: 0,
          release_conditions: releaseConditions || null,
          status: 'active',
        })
        .select('id')
        .single();

      if (err) throw err;
      return result.id as string;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to create retention record';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  const updateRetention = useCallback(async (id: string, updates: Partial<{
    retentionRate: number;
    totalBilled: number;
    totalRetained: number;
    releaseConditions: string;
  }>) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const updateData: Record<string, unknown> = { updated_at: new Date().toISOString() };

      if (updates.retentionRate !== undefined) updateData.retention_rate = updates.retentionRate;
      if (updates.totalBilled !== undefined) updateData.total_billed = updates.totalBilled;
      if (updates.totalRetained !== undefined) updateData.total_retained = updates.totalRetained;
      if (updates.releaseConditions !== undefined) updateData.release_conditions = updates.releaseConditions;

      const { error: err } = await supabase
        .from('retention_tracking')
        .update(updateData)
        .eq('id', id);

      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to update retention';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  const releaseRetention = useCallback(async (id: string, releaseAmount: number) => {
    try {
      setError(null);
      const supabase = getSupabase();

      // Get current record
      const { data: current, error: fetchErr } = await supabase
        .from('retention_tracking')
        .select('total_released, balance_held, total_retained')
        .eq('id', id)
        .single();

      if (fetchErr) throw fetchErr;
      if (!current) throw new Error('Retention record not found');

      const newReleased = Number(current.total_released || 0) + releaseAmount;
      const newBalance = Number(current.balance_held || 0) - releaseAmount;
      const totalRetained = Number(current.total_retained || 0);

      const newStatus = newReleased >= totalRetained ? 'fully_released' : 'partially_released';

      const { error: err } = await supabase
        .from('retention_tracking')
        .update({
          total_released: newReleased,
          balance_held: Math.max(newBalance, 0),
          status: newStatus,
          updated_at: new Date().toISOString(),
        })
        .eq('id', id);

      if (err) throw err;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to release retention';
      setError(msg);
      throw new Error(msg);
    }
  }, []);

  // ──────── WIP Report ────────

  const fetchWIPReport = useCallback(async (): Promise<WIPRow[]> => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Get active jobs
      const { data: jobsData, error: jobsErr } = await supabase
        .from('jobs')
        .select('id, title, customer_name, status')
        .is('deleted_at', null)
        .not('status', 'in', '("completed","invoiced","cancelled","paid")');

      if (jobsErr) throw jobsErr;
      const activeJobs: Record<string, unknown>[] = jobsData || [];

      if (activeJobs.length === 0) {
        setLoading(false);
        return [];
      }

      const jobIds = activeJobs.map((j) => j.id as string);

      // Parallel queries for costs and billings
      const [materialsRes, expensesRes, timeRes, billingsRes] = await Promise.all([
        supabase.from('job_materials').select('job_id, total_cost').in('job_id', jobIds).is('deleted_at', null),
        supabase.from('expense_records').select('job_id, total').in('job_id', jobIds).is('deleted_at', null),
        supabase.from('time_entries').select('job_id, hours, hourly_rate').in('job_id', jobIds),
        supabase.from('progress_billings').select('job_id, total_completed_to_date, status').in('job_id', jobIds),
      ]);

      const materials: Record<string, unknown>[] = materialsRes.data || [];
      const expenses: Record<string, unknown>[] = expensesRes.data || [];
      const timeEntries: Record<string, unknown>[] = timeRes.data || [];
      const billingRows: Record<string, unknown>[] = billingsRes.data || [];

      // Aggregate costs by job
      const costsByJob: Record<string, number> = {};
      for (const m of materials) {
        const jid = m.job_id as string;
        costsByJob[jid] = (costsByJob[jid] || 0) + Number(m.total_cost || 0);
      }
      for (const exp of expenses) {
        const jid = exp.job_id as string;
        costsByJob[jid] = (costsByJob[jid] || 0) + Number(exp.total || 0);
      }
      for (const te of timeEntries) {
        const jid = te.job_id as string;
        const hours = Number(te.hours || 0);
        const rate = Number(te.hourly_rate || 0);
        costsByJob[jid] = (costsByJob[jid] || 0) + (hours * rate);
      }

      // Aggregate billings by job (non-draft only)
      const billingsByJob: Record<string, number> = {};
      for (const b of billingRows) {
        if (b.status !== 'draft') {
          const jid = b.job_id as string;
          // Take the max total_completed_to_date per job (latest billing cumulative)
          const completed = Number(b.total_completed_to_date || 0);
          billingsByJob[jid] = Math.max(billingsByJob[jid] || 0, completed);
        }
      }

      const defaultMargin = 0.15;

      const wipRows: WIPRow[] = activeJobs.map((job) => {
        const jid = job.id as string;
        const costsIncurred = costsByJob[jid] || 0;
        const billingsToDate = billingsByJob[jid] || 0;
        const estimatedGross = costsIncurred * (1 + defaultMargin);
        const overUnder = billingsToDate - estimatedGross;

        let status: WIPRow['status'] = 'on_track';
        if (billingsToDate > costsIncurred * (1 + defaultMargin)) {
          status = 'over_billed';
        } else if (billingsToDate < costsIncurred * (1 - 0.05)) {
          status = 'under_billed';
        }

        return {
          jobId: jid,
          jobTitle: (job.title as string) || 'Untitled Job',
          customerName: (job.customer_name as string) || 'Unknown',
          costsIncurred,
          billingsToDate,
          estimatedGross,
          overUnder,
          status,
        };
      });

      return wipRows;
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load WIP report');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  // ──────── Certified Payroll (WH-347) ────────

  const fetchCertifiedPayroll = useCallback(async (
    jobId: string,
    weekStartDate: string,
  ): Promise<CertifiedPayrollRow[]> => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      // Calculate week end (7 days from start)
      const start = new Date(weekStartDate);
      const end = new Date(start);
      end.setDate(end.getDate() + 6);
      const weekEnd = end.toISOString().split('T')[0];

      const { data, error: err } = await supabase
        .from('time_entries')
        .select('user_id, hours, hourly_rate, entry_date, users(full_name, role)')
        .eq('job_id', jobId)
        .gte('entry_date', weekStartDate)
        .lte('entry_date', weekEnd);

      if (err) throw err;

      const entries: Record<string, unknown>[] = data || [];

      // Group by user
      const byUser: Record<string, {
        name: string;
        classification: string;
        regularHours: number;
        overtimeHours: number;
        rate: number;
      }> = {};

      for (const entry of entries) {
        const userId = entry.user_id as string;
        const user = (entry.users || {}) as Record<string, unknown>;
        const hours = Number(entry.hours || 0);
        const rate = Number(entry.hourly_rate || 0);

        if (!byUser[userId]) {
          byUser[userId] = {
            name: (user.full_name as string) || 'Unknown Employee',
            classification: (user.role as string) || 'Laborer',
            regularHours: 0,
            overtimeHours: 0,
            rate: rate || 35.00, // Prevailing wage placeholder
          };
        }

        // Hours > 8 per day count as overtime
        if (hours > 8) {
          byUser[userId].regularHours += 8;
          byUser[userId].overtimeHours += (hours - 8);
        } else {
          byUser[userId].regularHours += hours;
        }

        // Use highest rate seen
        if (rate > byUser[userId].rate) {
          byUser[userId].rate = rate;
        }
      }

      const rows: CertifiedPayrollRow[] = Object.values(byUser).map((emp) => ({
        employeeName: emp.name,
        classification: emp.classification,
        regularHours: Math.round(emp.regularHours * 100) / 100,
        overtimeHours: Math.round(emp.overtimeHours * 100) / 100,
        regularRate: emp.rate,
        overtimeRate: emp.rate * 1.5,
        grossPay: Math.round(
          (emp.regularHours * emp.rate + emp.overtimeHours * emp.rate * 1.5) * 100
        ) / 100,
      }));

      return rows;
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load certified payroll');
      return [];
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    // State
    billings,
    retentionRecords,
    loading,
    error,

    // Progress Billing
    fetchBillings,
    createBilling,
    updateBilling,
    submitBilling,
    approveBilling,

    // Retention
    fetchRetention,
    createRetention,
    updateRetention,
    releaseRetention,

    // WIP Report
    fetchWIPReport,

    // Certified Payroll
    fetchCertifiedPayroll,
  };
}
