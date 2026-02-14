'use client';

// L9: Employee Compliance Status — CE credits, license renewals, compliance gaps
// Shows the logged-in employee their own compliance posture.

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '../supabase';

const supabase = getSupabase();

export interface CECredit {
  id: string;
  certificationId: string | null;
  courseName: string;
  provider: string | null;
  creditHours: number;
  ceCategory: string | null;
  completionDate: string;
  certificateDocumentPath: string | null;
  verified: boolean;
  verifiedAt: string | null;
  notes: string | null;
  createdAt: string;
}

export interface LicenseRenewal {
  id: string;
  certificationId: string;
  renewalDueDate: string;
  ceCreditsRequired: number;
  ceCreditsCompleted: number;
  ceCreditsRemaining: number;
  status: string;
  renewalFee: number | null;
  feePaid: boolean;
  submittedDate: string | null;
  approvedDate: string | null;
  notes: string | null;
}

export interface ComplianceGap {
  requirementName: string;
  category: string;
  description: string;
  tradeType: string;
}

function mapCECredit(row: Record<string, unknown>): CECredit {
  return {
    id: row.id as string,
    certificationId: row.certification_id as string | null,
    courseName: row.course_name as string,
    provider: row.provider as string | null,
    creditHours: Number(row.credit_hours) || 0,
    ceCategory: row.ce_category as string | null,
    completionDate: row.completion_date as string,
    certificateDocumentPath: row.certificate_document_path as string | null,
    verified: row.verified as boolean,
    verifiedAt: row.verified_at as string | null,
    notes: row.notes as string | null,
    createdAt: row.created_at as string,
  };
}

function mapRenewal(row: Record<string, unknown>): LicenseRenewal {
  return {
    id: row.id as string,
    certificationId: row.certification_id as string,
    renewalDueDate: row.renewal_due_date as string,
    ceCreditsRequired: Number(row.ce_credits_required) || 0,
    ceCreditsCompleted: Number(row.ce_credits_completed) || 0,
    ceCreditsRemaining: Number(row.ce_credits_remaining) || 0,
    status: row.status as string,
    renewalFee: row.renewal_fee != null ? Number(row.renewal_fee) : null,
    feePaid: row.fee_paid as boolean,
    submittedDate: row.submitted_date as string | null,
    approvedDate: row.approved_date as string | null,
    notes: row.notes as string | null,
  };
}

export function useMyComplianceStatus() {
  const [ceCredits, setCECredits] = useState<CECredit[]>([]);
  const [renewals, setRenewals] = useState<LicenseRenewal[]>([]);
  const [gaps, setGaps] = useState<ComplianceGap[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const [ceRes, renewalRes] = await Promise.all([
        supabase
          .from('ce_credit_log')
          .select('*')
          .eq('user_id', user.id)
          .order('completion_date', { ascending: false }),
        supabase
          .from('license_renewals')
          .select('*')
          .eq('user_id', user.id)
          .order('renewal_due_date', { ascending: true }),
      ]);

      if (ceRes.error) throw ceRes.error;
      if (renewalRes.error) throw renewalRes.error;

      setCECredits((ceRes.data || []).map(mapCECredit));
      setRenewals((renewalRes.data || []).map(mapRenewal));

      // Check compliance gaps
      const companyId = user.app_metadata?.company_id;
      if (companyId) {
        const [reqRes, certRes] = await Promise.all([
          supabase.from('compliance_requirements').select('*').eq('is_required', true),
          supabase.from('certifications').select('compliance_category, status').eq('user_id', user.id).eq('status', 'active'),
        ]);

        const activeCategories = new Set(
          (certRes.data || []).map((c: { compliance_category: string }) => c.compliance_category)
        );

        const foundGaps: ComplianceGap[] = [];
        for (const req of reqRes.data || []) {
          if (!activeCategories.has(req.required_compliance_category)) {
            foundGaps.push({
              requirementName: req.requirement_name,
              category: req.required_compliance_category,
              description: req.description || '',
              tradeType: req.trade_type,
            });
          }
        }
        setGaps(foundGaps);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load compliance status');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  useEffect(() => {
    const channel = supabase
      .channel('my-compliance-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'ce_credit_log' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'license_renewals' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const summary = useMemo(() => {
    const totalCE = ceCredits.reduce((s, c) => s + c.creditHours, 0);
    const verifiedCE = ceCredits.filter(c => c.verified).reduce((s, c) => s + c.creditHours, 0);
    const activeRenewals = renewals.filter(r => r.status !== 'completed' && r.status !== 'waived');
    const overdueRenewals = renewals.filter(r => r.status === 'overdue');

    return {
      totalCEHours: totalCE,
      verifiedCEHours: verifiedCE,
      pendingCEHours: totalCE - verifiedCE,
      courseCount: ceCredits.length,
      activeRenewals: activeRenewals.length,
      overdueRenewals: overdueRenewals.length,
      complianceGaps: gaps.length,
    };
  }, [ceCredits, renewals, gaps]);

  const addCECredit = useCallback(async (credit: {
    courseName: string;
    provider?: string;
    creditHours: number;
    ceCategory?: string;
    completionDate: string;
    certificationId?: string;
    notes?: string;
  }) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase.from('ce_credit_log').insert({
      company_id: user.app_metadata?.company_id,
      user_id: user.id,
      course_name: credit.courseName,
      provider: credit.provider || null,
      credit_hours: credit.creditHours,
      ce_category: credit.ceCategory || null,
      completion_date: credit.completionDate,
      certification_id: credit.certificationId || null,
      notes: credit.notes || null,
    });
    if (err) throw err;
    await fetchData();
  }, [fetchData]);

  return { ceCredits, renewals, gaps, summary, loading, error, addCECredit, refresh: fetchData };
}
