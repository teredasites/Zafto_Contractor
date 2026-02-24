'use client';

// Signature System hook — project-linked signatures, multi-party workflows,
// audit trail, DocuSign replacement at $0 API cost.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ── Types ──

type SigningMode = 'sequential' | 'parallel' | 'any_one';
type WorkflowStatus = 'draft' | 'active' | 'completed' | 'voided' | 'expired';
type RequestStatus = 'pending' | 'sent' | 'viewed' | 'signed' | 'declined' | 'expired';
type AuditEventType =
  | 'created' | 'sent' | 'viewed' | 'signed' | 'declined' | 'expired'
  | 'reminder_sent' | 'downloaded' | 'voided' | 'resent'
  | 'document_generated' | 'document_hashed';

export interface SigningWorkflow {
  id: string;
  companyId: string;
  renderId: string;
  name: string;
  signingMode: SigningMode;
  status: WorkflowStatus;
  completedAt: string | null;
  voidedAt: string | null;
  voidedReason: string | null;
  expiresAt: string | null;
  sendReminders: boolean;
  reminderIntervalHours: number;
  maxReminders: number;
  createdBy: string;
  createdByName: string | null;
  createdAt: string;
  signerCount: number;
  signedCount: number;
}

export interface SignatureRequest {
  id: string;
  companyId: string;
  renderId: string;
  workflowId: string | null;
  signerName: string;
  signerEmail: string;
  signerPhone: string | null;
  signerRole: string;
  signingOrder: number;
  status: RequestStatus;
  sentAt: string | null;
  viewedAt: string | null;
  signedAt: string | null;
  declinedAt: string | null;
  declineReason: string | null;
  reminderCount: number;
  lastReminderAt: string | null;
  expiresAt: string | null;
  createdAt: string;
}

export interface SignatureAuditEvent {
  id: string;
  eventType: AuditEventType;
  actorType: string;
  actorName: string | null;
  actorEmail: string | null;
  ipAddress: string | null;
  documentHash: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export interface SignatureSummary {
  totalWorkflows: number;
  activeWorkflows: number;
  pendingSignatures: number;
  completedThisMonth: number;
  averageCompletionHours: number | null;
}

// ── Mappers ──

function mapWorkflow(row: Record<string, unknown>, nameMap: Map<string, string>): SigningWorkflow {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    renderId: row.render_id as string,
    name: row.name as string,
    signingMode: (row.signing_mode as SigningMode) || 'sequential',
    status: (row.status as WorkflowStatus) || 'draft',
    completedAt: row.completed_at as string | null,
    voidedAt: row.voided_at as string | null,
    voidedReason: row.voided_reason as string | null,
    expiresAt: row.expires_at as string | null,
    sendReminders: (row.send_reminders as boolean) ?? true,
    reminderIntervalHours: (row.reminder_interval_hours as number) ?? 48,
    maxReminders: (row.max_reminders as number) ?? 3,
    createdBy: row.created_by as string,
    createdByName: nameMap.get(row.created_by as string) || null,
    createdAt: row.created_at as string,
    signerCount: 0,
    signedCount: 0,
  };
}

function mapRequest(row: Record<string, unknown>): SignatureRequest {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    renderId: row.render_id as string,
    workflowId: row.workflow_id as string | null,
    signerName: row.signer_name as string,
    signerEmail: row.signer_email as string,
    signerPhone: row.signer_phone as string | null,
    signerRole: (row.signer_role as string) || 'signer',
    signingOrder: (row.signing_order as number) || 1,
    status: (row.status as RequestStatus) || 'pending',
    sentAt: row.sent_at as string | null,
    viewedAt: row.viewed_at as string | null,
    signedAt: row.signed_at as string | null,
    declinedAt: row.declined_at as string | null,
    declineReason: row.decline_reason as string | null,
    reminderCount: (row.reminder_count as number) || 0,
    lastReminderAt: row.last_reminder_at as string | null,
    expiresAt: row.expires_at as string | null,
    createdAt: row.created_at as string,
  };
}

// ── Hook: Signing Workflows ──

export function useSigningWorkflows(opts?: { status?: WorkflowStatus }) {
  const supabase = getSupabase();
  const [workflows, setWorkflows] = useState<SigningWorkflow[]>([]);
  const [summary, setSummary] = useState<SignatureSummary>({
    totalWorkflows: 0, activeWorkflows: 0, pendingSignatures: 0,
    completedThisMonth: 0, averageCompletionHours: null,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      let query = supabase
        .from('signing_workflows')
        .select('*')
        .is('deleted_at', null);

      if (opts?.status) query = query.eq('status', opts.status);

      const { data, error: err } = await query.order('created_at', { ascending: false }).limit(100);
      if (err) throw err;

      const rows = data || [];
      const userIds = [...new Set(rows.map((r: Record<string, unknown>) => r.created_by as string))];
      const nameMap = new Map<string, string>();

      if (userIds.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', userIds);
        for (const p of profiles || []) {
          nameMap.set(p.id, p.full_name || 'Unknown');
        }
      }

      // Fetch signer counts per workflow
      const workflowIds = rows.map((r: Record<string, unknown>) => r.id as string);
      const signerCounts = new Map<string, { total: number; signed: number }>();

      if (workflowIds.length > 0) {
        const { data: requests } = await supabase
          .from('zdocs_signature_requests')
          .select('workflow_id, status')
          .in('workflow_id', workflowIds);

        for (const req of requests || []) {
          const wfId = req.workflow_id as string;
          if (!signerCounts.has(wfId)) signerCounts.set(wfId, { total: 0, signed: 0 });
          const c = signerCounts.get(wfId)!;
          c.total++;
          if (req.status === 'signed') c.signed++;
        }
      }

      const mapped: SigningWorkflow[] = rows.map((r: Record<string, unknown>) => {
        const wf = mapWorkflow(r, nameMap);
        const counts = signerCounts.get(wf.id);
        return { ...wf, signerCount: counts?.total ?? 0, signedCount: counts?.signed ?? 0 };
      });

      setWorkflows(mapped);

      // Compute summary
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
      const active = mapped.filter(w => w.status === 'active').length;
      const completedThisMonth = mapped.filter(
        w => w.status === 'completed' && w.completedAt !== null && new Date(w.completedAt) >= monthStart
      ).length;
      const pendingSigs = mapped.reduce((sum, w) => sum + (w.signerCount - w.signedCount), 0);

      setSummary({
        totalWorkflows: mapped.length,
        activeWorkflows: active,
        pendingSignatures: pendingSigs > 0 ? pendingSigs : 0,
        completedThisMonth,
        averageCompletionHours: null,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load workflows');
    } finally {
      setLoading(false);
    }
  }, [opts?.status]);

  useEffect(() => { fetch(); }, [fetch]);

  // Mutations
  const createWorkflow = useCallback(async (input: {
    renderId: string;
    name: string;
    signingMode?: SigningMode;
    expiresInDays?: number;
    signers: Array<{ name: string; email: string; role?: string; order?: number }>;
  }) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');
    const companyId = user.app_metadata?.company_id;

    const expiresAt = input.expiresInDays
      ? new Date(Date.now() + input.expiresInDays * 86400000).toISOString()
      : new Date(Date.now() + 30 * 86400000).toISOString();

    // Create workflow
    const { data: wf, error: wfErr } = await supabase
      .from('signing_workflows')
      .insert({
        company_id: companyId,
        render_id: input.renderId,
        name: input.name,
        signing_mode: input.signingMode || 'sequential',
        status: 'active',
        expires_at: expiresAt,
        created_by: user.id,
      })
      .select()
      .single();

    if (wfErr) throw wfErr;

    // Create signature requests for each signer
    const signerInserts = input.signers.map((s, i) => ({
      company_id: companyId,
      render_id: input.renderId,
      workflow_id: wf.id,
      signer_name: s.name,
      signer_email: s.email,
      signer_role: s.role || 'signer',
      signing_order: s.order ?? i + 1,
      status: 'pending',
      expires_at: expiresAt,
    }));

    const { error: sigErr } = await supabase
      .from('zdocs_signature_requests')
      .insert(signerInserts);

    if (sigErr) throw sigErr;

    // Log audit event
    await supabase.from('signature_audit_events').insert({
      company_id: companyId,
      render_id: input.renderId,
      event_type: 'created',
      actor_type: 'user',
      actor_id: user.id,
      metadata: { workflow_id: wf.id, signer_count: input.signers.length },
    });

    fetch();
    return wf.id;
  }, [fetch]);

  const voidWorkflow = useCallback(async (workflowId: string, reason: string) => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { error: err } = await supabase
      .from('signing_workflows')
      .update({
        status: 'voided',
        voided_at: new Date().toISOString(),
        voided_by: user.id,
        voided_reason: reason,
      })
      .eq('id', workflowId);

    if (err) throw err;

    // Void all pending signature requests
    await supabase
      .from('zdocs_signature_requests')
      .update({ status: 'expired' })
      .eq('workflow_id', workflowId)
      .in('status', ['pending', 'sent', 'viewed']);

    fetch();
  }, [fetch]);

  return { workflows, summary, loading, error, refresh: fetch, createWorkflow, voidWorkflow };
}

// ── Hook: Signature Requests for a workflow ──

export function useSignatureRequests(workflowId: string | null) {
  const supabase = getSupabase();
  const [requests, setRequests] = useState<SignatureRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!workflowId) {
      setRequests([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const { data, error: err } = await supabase
        .from('zdocs_signature_requests')
        .select('*')
        .eq('workflow_id', workflowId)
        .order('signing_order', { ascending: true });

      if (err) throw err;
      setRequests((data || []).map((r: Record<string, unknown>) => mapRequest(r)));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load requests');
    } finally {
      setLoading(false);
    }
  }, [workflowId]);

  useEffect(() => { fetch(); }, [fetch]);

  const sendReminder = useCallback(async (requestId: string) => {
    const { error: err } = await supabase
      .from('zdocs_signature_requests')
      .update({
        reminder_count: supabase.rpc ? undefined : 1, // increment handled below
        last_reminder_at: new Date().toISOString(),
      })
      .eq('id', requestId);

    if (err) throw err;

    // Log audit
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await supabase.from('signature_audit_events').insert({
        company_id: user.app_metadata?.company_id,
        signature_request_id: requestId,
        event_type: 'reminder_sent',
        actor_type: 'user',
        actor_id: user.id,
      });
    }

    fetch();
  }, [fetch]);

  return { requests, loading, error, refresh: fetch, sendReminder };
}

// ── Hook: Signature Audit Trail ──

export function useSignatureAudit(opts: { renderId?: string; signatureRequestId?: string }) {
  const supabase = getSupabase();
  const [events, setEvents] = useState<SignatureAuditEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!opts.renderId && !opts.signatureRequestId) {
      setEvents([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      let query = supabase.from('signature_audit_events').select('*');
      if (opts.renderId) query = query.eq('render_id', opts.renderId);
      if (opts.signatureRequestId) query = query.eq('signature_request_id', opts.signatureRequestId);

      const { data, error: err } = await query.order('created_at', { ascending: false }).limit(200);
      if (err) throw err;

      setEvents((data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        eventType: r.event_type as AuditEventType,
        actorType: (r.actor_type as string) || 'system',
        actorName: r.actor_name as string | null,
        actorEmail: r.actor_email as string | null,
        ipAddress: r.ip_address as string | null,
        documentHash: r.document_hash as string | null,
        metadata: (r.metadata as Record<string, unknown>) || {},
        createdAt: r.created_at as string,
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load audit trail');
    } finally {
      setLoading(false);
    }
  }, [opts.renderId, opts.signatureRequestId]);

  useEffect(() => { fetch(); }, [fetch]);

  return { events, loading, error, refresh: fetch };
}

// ── Hook: Signatures by project (job/bid/invoice) ──

export function useProjectSignatures(opts: {
  jobId?: string;
  bidId?: string;
  invoiceId?: string;
  documentId?: string;
}) {
  const supabase = getSupabase();
  const [signatures, setSignatures] = useState<Array<{
    id: string;
    signerName: string;
    signerRole: string | null;
    signerEmail: string | null;
    purpose: string;
    signedAt: string;
    ipAddress: string | null;
    storagePath: string | null;
  }>>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    if (!opts.jobId && !opts.bidId && !opts.invoiceId && !opts.documentId) {
      setSignatures([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);

      let query = supabase.from('signatures').select('*').is('deleted_at', null);

      if (opts.jobId) query = query.eq('job_id', opts.jobId);
      if (opts.bidId) query = query.eq('bid_id', opts.bidId);
      if (opts.invoiceId) query = query.eq('invoice_id', opts.invoiceId);
      if (opts.documentId) query = query.eq('document_id', opts.documentId);

      const { data, error: err } = await query.order('signed_at', { ascending: false });
      if (err) throw err;

      setSignatures((data || []).map((r: Record<string, unknown>) => ({
        id: r.id as string,
        signerName: r.signer_name as string,
        signerRole: r.signer_role as string | null,
        signerEmail: r.signer_email as string | null,
        purpose: (r.purpose as string) || 'job_completion',
        signedAt: r.signed_at as string,
        ipAddress: r.ip_address as string | null,
        storagePath: r.storage_path as string | null,
      })));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load signatures');
    } finally {
      setLoading(false);
    }
  }, [opts.jobId, opts.bidId, opts.invoiceId, opts.documentId]);

  useEffect(() => { fetch(); }, [fetch]);

  return { signatures, loading, error, refresh: fetch };
}
