'use client';

// L8: CE Tracking Hook — continuing education credits, license renewals
// Tracks CE hours by user/certification, renewal deadlines, credit progress.

import { useState, useEffect, useCallback, useMemo } from 'react';
import { createClient } from '../supabase';

const supabase = createClient();

export interface CECreditLog {
  id: string;
  company_id: string;
  user_id: string;
  certification_id: string | null;
  course_name: string;
  provider: string | null;
  credit_hours: number;
  ce_category: string | null;
  completion_date: string;
  certificate_document_path: string | null;
  verified: boolean;
  verified_by: string | null;
  verified_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LicenseRenewal {
  id: string;
  company_id: string;
  certification_id: string;
  user_id: string;
  renewal_due_date: string;
  ce_credits_required: number;
  ce_credits_completed: number;
  ce_credits_remaining: number;
  status: 'upcoming' | 'in_progress' | 'pending_approval' | 'completed' | 'overdue' | 'waived';
  renewal_fee: number | null;
  fee_paid: boolean;
  submitted_date: string | null;
  approved_date: string | null;
  new_expiration_date: string | null;
  document_path: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface CESummary {
  totalCredits: number;
  totalCourses: number;
  verifiedCredits: number;
  pendingCredits: number;
  categoryBreakdown: { category: string; hours: number }[];
}

export interface RenewalSummary {
  totalRenewals: number;
  upcoming: number;
  overdue: number;
  completed: number;
  totalFeesOwed: number;
}

export function useCECredits(userId?: string) {
  const [credits, setCredits] = useState<CECreditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchCredits = useCallback(async () => {
    try {
      setLoading(true);
      let query = supabase
        .from('ce_credit_log')
        .select('*')
        .order('completion_date', { ascending: false });

      if (userId) query = query.eq('user_id', userId);

      const { data, error: err } = await query;
      if (err) throw err;
      setCredits(data || []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load CE credits');
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => { fetchCredits(); }, [fetchCredits]);

  // Real-time
  useEffect(() => {
    const channel = supabase
      .channel('ce-credits-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'ce_credit_log' }, () => {
        fetchCredits();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchCredits]);

  const summary: CESummary = useMemo(() => {
    const verified = credits.filter(c => c.verified);
    const pending = credits.filter(c => !c.verified);

    const categoryMap = new Map<string, number>();
    for (const c of credits) {
      const cat = c.ce_category || 'Uncategorized';
      categoryMap.set(cat, (categoryMap.get(cat) || 0) + c.credit_hours);
    }

    return {
      totalCredits: credits.reduce((sum, c) => sum + c.credit_hours, 0),
      totalCourses: credits.length,
      verifiedCredits: verified.reduce((sum, c) => sum + c.credit_hours, 0),
      pendingCredits: pending.reduce((sum, c) => sum + c.credit_hours, 0),
      categoryBreakdown: Array.from(categoryMap.entries())
        .map(([category, hours]) => ({ category, hours }))
        .sort((a, b) => b.hours - a.hours),
    };
  }, [credits]);

  const addCredit = useCallback(async (credit: Partial<CECreditLog>) => {
    const { error: err } = await supabase.from('ce_credit_log').insert(credit);
    if (err) throw err;
    await fetchCredits();
  }, [fetchCredits]);

  const verifyCredit = useCallback(async (creditId: string) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase
      .from('ce_credit_log')
      .update({ verified: true, verified_by: user.id, verified_at: new Date().toISOString() })
      .eq('id', creditId);
    if (err) throw err;
    await fetchCredits();
  }, [fetchCredits]);

  return { credits, summary, loading, error, addCredit, verifyCredit, refresh: fetchCredits };
}

export function useLicenseRenewals(userId?: string) {
  const [renewals, setRenewals] = useState<LicenseRenewal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRenewals = useCallback(async () => {
    try {
      setLoading(true);
      let query = supabase
        .from('license_renewals')
        .select('*')
        .order('renewal_due_date', { ascending: true });

      if (userId) query = query.eq('user_id', userId);

      const { data, error: err } = await query;
      if (err) throw err;
      setRenewals(data || []);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load renewals');
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => { fetchRenewals(); }, [fetchRenewals]);

  useEffect(() => {
    const channel = supabase
      .channel('license-renewals-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'license_renewals' }, () => {
        fetchRenewals();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchRenewals]);

  const renewalSummary: RenewalSummary = useMemo(() => ({
    totalRenewals: renewals.length,
    upcoming: renewals.filter(r => r.status === 'upcoming' || r.status === 'in_progress').length,
    overdue: renewals.filter(r => r.status === 'overdue').length,
    completed: renewals.filter(r => r.status === 'completed').length,
    totalFeesOwed: renewals
      .filter(r => !r.fee_paid && r.renewal_fee)
      .reduce((sum, r) => sum + (r.renewal_fee || 0), 0),
  }), [renewals]);

  const updateRenewalStatus = useCallback(async (renewalId: string, status: LicenseRenewal['status']) => {
    const update: Record<string, unknown> = { status };
    if (status === 'completed') update.approved_date = new Date().toISOString().split('T')[0];
    if (status === 'pending_approval') update.submitted_date = new Date().toISOString().split('T')[0];

    const { error: err } = await supabase
      .from('license_renewals')
      .update(update)
      .eq('id', renewalId);
    if (err) throw err;
    await fetchRenewals();
  }, [fetchRenewals]);

  const updateCEProgress = useCallback(async (renewalId: string, creditsCompleted: number) => {
    const { error: err } = await supabase
      .from('license_renewals')
      .update({ ce_credits_completed: creditsCompleted })
      .eq('id', renewalId);
    if (err) throw err;
    await fetchRenewals();
  }, [fetchRenewals]);

  return { renewals, renewalSummary, loading, error, updateRenewalStatus, updateCEProgress, refresh: fetchRenewals };
}
