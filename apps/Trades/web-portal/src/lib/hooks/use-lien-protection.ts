'use client';

// L7: Lien Protection Hook — lien rules, lien tracking, document templates
// Real-time subscription on lien_tracking.

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

const supabase = getSupabase();

export interface LienRule {
  id: string;
  state_code: string;
  state_name: string;
  preliminary_notice_required: boolean;
  preliminary_notice_deadline_days: number | null;
  preliminary_notice_from: string | null;
  preliminary_notice_recipients: string[];
  lien_filing_deadline_days: number;
  lien_filing_from: string;
  lien_enforcement_deadline_days: number | null;
  lien_enforcement_from: string | null;
  notice_of_intent_required: boolean;
  notice_of_intent_deadline_days: number | null;
  notarization_required: boolean;
  special_rules: Record<string, unknown>[];
  residential_different: boolean;
  residential_rules: Record<string, unknown> | null;
  statutory_reference: string | null;
  notes: string | null;
  created_at: string;
}

export interface LienRecord {
  id: string;
  company_id: string;
  job_id: string;
  customer_id: string | null;
  property_address: string;
  property_city: string | null;
  property_state: string;
  state_code: string;
  contract_amount: number | null;
  amount_owed: number | null;
  first_work_date: string | null;
  last_work_date: string | null;
  completion_date: string | null;
  preliminary_notice_sent: boolean;
  preliminary_notice_date: string | null;
  preliminary_notice_document_path: string | null;
  notice_of_intent_sent: boolean;
  notice_of_intent_date: string | null;
  lien_filed: boolean;
  lien_filing_date: string | null;
  lien_filing_document_path: string | null;
  lien_released: boolean;
  lien_release_date: string | null;
  lien_release_document_path: string | null;
  enforcement_filed: boolean;
  enforcement_filing_date: string | null;
  status: string;
  notes: string | null;
  created_at: string;
}

export interface LienTemplate {
  id: string;
  state_code: string;
  document_type: string;
  template_name: string;
  template_content: string;
  placeholders: string[];
  requires_notarization: boolean;
  filing_instructions: string | null;
}

export interface LienSummary {
  totalActive: number;
  totalAtRisk: number;
  totalAmountOwed: number;
  urgentCount: number;
  liensFiled: number;
  approachingDeadlines: number;
}

export function useLienProtection() {
  const [liens, setLiens] = useState<LienRecord[]>([]);
  const [rules, setRules] = useState<LienRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [liensRes, rulesRes] = await Promise.all([
        supabase.from('lien_tracking').select('*').is('deleted_at', null).order('created_at', { ascending: false }),
        supabase.from('lien_rules_by_state').select('*').order('state_code'),
      ]);
      if (liensRes.error) throw liensRes.error;
      if (rulesRes.error) throw rulesRes.error;
      setLiens(liensRes.data || []);
      setRules(rulesRes.data || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load lien data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    const channel = supabase
      .channel('lien-tracking-rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'lien_tracking' }, () => load())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [load]);

  const activeLiens = useMemo(() =>
    liens.filter(l => ['monitoring', 'notice_due', 'notice_sent', 'lien_eligible', 'lien_filed', 'enforcement'].includes(l.status)),
    [liens]
  );

  const summary: LienSummary = useMemo(() => {
    const active = activeLiens;
    return {
      totalActive: active.length,
      totalAtRisk: active.filter(l => (l.amount_owed ?? 0) > 0).length,
      totalAmountOwed: active.reduce((sum, l) => sum + (l.amount_owed ?? 0), 0),
      urgentCount: active.filter(l => ['notice_due', 'enforcement'].includes(l.status)).length,
      liensFiled: active.filter(l => l.lien_filed).length,
      approachingDeadlines: active.filter(l => {
        if (!l.last_work_date) return false;
        const rule = rules.find(r => r.state_code === l.state_code);
        if (!rule) return false;
        const deadline = new Date(l.last_work_date);
        deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days);
        const daysLeft = Math.ceil((deadline.getTime() - Date.now()) / 86400000);
        return daysLeft > 0 && daysLeft <= 30;
      }).length,
    };
  }, [activeLiens, rules]);

  const getRuleForState = useCallback((stateCode: string) =>
    rules.find(r => r.state_code === stateCode) || null,
    [rules]
  );

  const createLien = useCallback(async (lien: Partial<LienRecord>) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error: err } = await supabase.from('lien_tracking').insert({
      ...lien,
      company_id: user.app_metadata?.company_id,
    });
    if (err) throw err;
  }, []);

  const updateStatus = useCallback(async (id: string, status: string) => {
    const { error: err } = await supabase.from('lien_tracking').update({ status }).eq('id', id);
    if (err) throw err;
  }, []);

  return {
    liens, activeLiens, rules, summary, loading, error,
    getRuleForState, createLien, updateStatus, reload: load,
  };
}

// ── State Rules Hook (read-only) ────────────────────────
export function useLienRules() {
  const [rules, setRules] = useState<LienRule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      try {
        const { data, error: err } = await supabase
          .from('lien_rules_by_state')
          .select('*')
          .order('state_name');
        if (err) throw err;
        setRules(data || []);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : 'Failed to load rules');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return { rules, loading, error };
}
