'use client';

// L4: Compliance Hook — certifications, compliance requirements, compliance packets
// Aggregates company compliance posture: licenses, insurance, bonds, OSHA, EPA, vehicle regs.

import { useState, useEffect, useCallback, useMemo } from 'react';
import { createClient } from '../supabase';

const supabase = createClient();

export interface Certification {
  id: string;
  company_id: string;
  user_id: string;
  certification_type: string;
  certification_name: string;
  issuing_authority: string | null;
  certification_number: string | null;
  issued_date: string | null;
  expiration_date: string | null;
  renewal_required: boolean;
  renewal_reminder_days: number;
  document_url: string | null;
  status: 'active' | 'expired' | 'pending_renewal' | 'revoked';
  notes: string | null;
  compliance_category: string | null;
  policy_number: string | null;
  coverage_amount: number | null;
  renewal_cost: number | null;
  auto_renew: boolean;
  document_path: string | null;
  created_at: string;
  updated_at: string;
}

export interface ComplianceRequirement {
  id: string;
  trade_type: string;
  job_type_pattern: string | null;
  required_compliance_category: string;
  required_certification_type: string | null;
  state_code: string | null;
  description: string;
  regulatory_reference: string | null;
  penalty_description: string | null;
  severity: 'required' | 'recommended' | 'optional';
  created_at: string;
}

export interface CompliancePacket {
  id: string;
  company_id: string;
  packet_name: string;
  requested_by: string | null;
  documents: Array<{ type: string; certificationId: string; name: string }>;
  generated_at: string | null;
  shared_via: string | null;
  share_link: string | null;
  expires_at: string | null;
  notes: string | null;
  created_at: string;
}

export type ComplianceCategory = 'license' | 'insurance' | 'bond' | 'osha' | 'epa' | 'vehicle' | 'certification' | 'other';

export interface ComplianceSummary {
  totalCerts: number;
  activeCerts: number;
  expiredCerts: number;
  expiringSoon: number;
  categories: Record<string, { total: number; active: number; expired: number; expiringSoon: number }>;
  totalCoverage: number;
  totalRenewalCost: number;
}

export function useCompliance() {
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [requirements, setRequirements] = useState<ComplianceRequirement[]>([]);
  const [packets, setPackets] = useState<CompliancePacket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [certsRes, reqsRes, packetsRes] = await Promise.all([
        supabase.from('certifications').select('*').order('expiration_date'),
        supabase.from('compliance_requirements').select('*').order('trade_type'),
        supabase.from('compliance_packets').select('*').order('created_at', { ascending: false }),
      ]);

      if (certsRes.error) throw certsRes.error;
      if (reqsRes.error) throw reqsRes.error;
      if (packetsRes.error) throw packetsRes.error;

      setCertifications(certsRes.data || []);
      setRequirements(reqsRes.data || []);
      setPackets(packetsRes.data || []);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load compliance data');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    const channel = supabase
      .channel('compliance-rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certifications' }, () => load())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [load]);

  const summary: ComplianceSummary = useMemo(() => {
    const now = Date.now();
    const thirtyDays = 30 * 86400000;
    const categories: ComplianceSummary['categories'] = {};

    let totalCoverage = 0;
    let totalRenewalCost = 0;

    certifications.forEach(cert => {
      const cat = cert.compliance_category || 'other';
      if (!categories[cat]) categories[cat] = { total: 0, active: 0, expired: 0, expiringSoon: 0 };
      categories[cat].total++;

      if (cert.status === 'active') {
        categories[cat].active++;
        if (cert.expiration_date) {
          const daysUntil = new Date(cert.expiration_date).getTime() - now;
          if (daysUntil > 0 && daysUntil <= thirtyDays) categories[cat].expiringSoon++;
        }
      } else if (cert.status === 'expired') {
        categories[cat].expired++;
      }

      if (cert.coverage_amount) totalCoverage += cert.coverage_amount;
      if (cert.renewal_cost) totalRenewalCost += cert.renewal_cost;
    });

    return {
      totalCerts: certifications.length,
      activeCerts: certifications.filter(c => c.status === 'active').length,
      expiredCerts: certifications.filter(c => c.status === 'expired').length,
      expiringSoon: certifications.filter(c => {
        if (!c.expiration_date || c.status !== 'active') return false;
        const d = new Date(c.expiration_date).getTime() - now;
        return d > 0 && d <= thirtyDays;
      }).length,
      categories,
      totalCoverage,
      totalRenewalCost,
    };
  }, [certifications]);

  const createCertification = useCallback(async (cert: Partial<Certification>) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error: err } = await supabase.from('certifications').insert({
      company_id: user.app_metadata?.company_id,
      user_id: user.id,
      certification_type: cert.certification_type || 'license',
      certification_name: cert.certification_name || '',
      issuing_authority: cert.issuing_authority || null,
      certification_number: cert.certification_number || null,
      issued_date: cert.issued_date || null,
      expiration_date: cert.expiration_date || null,
      renewal_required: cert.renewal_required ?? true,
      renewal_reminder_days: cert.renewal_reminder_days ?? 30,
      status: cert.status || 'active',
      notes: cert.notes || null,
      compliance_category: cert.compliance_category || 'other',
      policy_number: cert.policy_number || null,
      coverage_amount: cert.coverage_amount ?? null,
      renewal_cost: cert.renewal_cost ?? null,
      auto_renew: cert.auto_renew ?? false,
    });
    if (err) throw err;
    await load();
  }, [load]);

  const updateCertification = useCallback(async (id: string, updates: Partial<Certification>) => {
    const payload: Record<string, unknown> = {};
    if (updates.certification_name !== undefined) payload.certification_name = updates.certification_name;
    if (updates.certification_type !== undefined) payload.certification_type = updates.certification_type;
    if (updates.issuing_authority !== undefined) payload.issuing_authority = updates.issuing_authority;
    if (updates.certification_number !== undefined) payload.certification_number = updates.certification_number;
    if (updates.issued_date !== undefined) payload.issued_date = updates.issued_date;
    if (updates.expiration_date !== undefined) payload.expiration_date = updates.expiration_date;
    if (updates.status !== undefined) payload.status = updates.status;
    if (updates.notes !== undefined) payload.notes = updates.notes;
    if (updates.compliance_category !== undefined) payload.compliance_category = updates.compliance_category;
    if (updates.policy_number !== undefined) payload.policy_number = updates.policy_number;
    if (updates.coverage_amount !== undefined) payload.coverage_amount = updates.coverage_amount;
    if (updates.renewal_cost !== undefined) payload.renewal_cost = updates.renewal_cost;
    if (updates.auto_renew !== undefined) payload.auto_renew = updates.auto_renew;
    if (updates.renewal_required !== undefined) payload.renewal_required = updates.renewal_required;
    if (updates.renewal_reminder_days !== undefined) payload.renewal_reminder_days = updates.renewal_reminder_days;

    const { error: err } = await supabase.from('certifications').update(payload).eq('id', id);
    if (err) throw err;
    await load();
  }, [load]);

  const deleteCertification = useCallback(async (id: string) => {
    const { error: err } = await supabase.from('certifications')
      .update({ deleted_at: new Date().toISOString() } as Record<string, unknown>)
      .eq('id', id);
    if (err) throw err;
    await load();
  }, [load]);

  const createPacket = useCallback(async (packet: Partial<CompliancePacket>) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const { error: err } = await supabase.from('compliance_packets').insert({
      ...packet,
      company_id: user.app_metadata?.company_id,
      requested_by: user.id,
    });
    if (err) throw err;
    await load();
  }, [load]);

  const getRequirementsForTrade = useCallback((tradeType: string) => {
    return requirements.filter(r => r.trade_type === tradeType || r.trade_type === 'general');
  }, [requirements]);

  const checkCompliance = useCallback((tradeType: string) => {
    const reqs = getRequirementsForTrade(tradeType);
    const results = reqs.map(req => {
      const matchingCert = certifications.find(c =>
        c.compliance_category === req.required_compliance_category &&
        (req.required_certification_type ? c.certification_type === req.required_certification_type : true) &&
        c.status === 'active'
      );
      return {
        requirement: req,
        met: !!matchingCert,
        certification: matchingCert || null,
      };
    });
    return {
      results,
      totalRequired: results.filter(r => r.requirement.severity === 'required').length,
      metRequired: results.filter(r => r.requirement.severity === 'required' && r.met).length,
      compliant: results.filter(r => r.requirement.severity === 'required').every(r => r.met),
    };
  }, [certifications, getRequirementsForTrade]);

  return {
    certifications,
    requirements,
    packets,
    summary,
    loading,
    error,
    createCertification,
    updateCertification,
    deleteCertification,
    createPacket,
    getRequirementsForTrade,
    checkCompliance,
    reload: load,
  };
}
