'use client';

// DEPTH33: Data Privacy Controls Hook (CRM Portal)
// Consent management (opt-in/out), data export requests,
// data deletion requests, privacy policy versions.
// GDPR/CCPA compliant — full CRUD for owners/admins.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type ConsentType =
  | 'pricing_data_sharing'
  | 'ai_training'
  | 'analytics'
  | 'marketing_emails'
  | 'push_notifications';

export type ExportStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'expired';
export type ExportFormat = 'json' | 'csv';
export type DeletionStatus = 'pending' | 'confirmed' | 'processing' | 'completed' | 'cancelled';
export type DeletionScope = 'user_data' | 'company_data';

export interface UserConsent {
  id: string;
  userId: string;
  companyId: string;
  consentType: ConsentType;
  granted: boolean;
  grantedAt: string | null;
  revokedAt: string | null;
  consentVersion: string;
  createdAt: string;
  updatedAt: string;
}

export interface DataExportRequest {
  id: string;
  userId: string;
  companyId: string;
  status: ExportStatus;
  exportFormat: ExportFormat;
  downloadUrl: string | null;
  downloadExpires: string | null;
  requestedAt: string;
  completedAt: string | null;
  fileSizeBytes: number | null;
  errorMessage: string | null;
  createdAt: string;
}

export interface DataDeletionRequest {
  id: string;
  userId: string;
  companyId: string;
  status: DeletionStatus;
  confirmationCode: string | null;
  confirmedAt: string | null;
  gracePeriodEnds: string | null;
  processedAt: string | null;
  scope: DeletionScope;
  reason: string | null;
  createdAt: string;
}

export interface PrivacyPolicyVersion {
  id: string;
  version: string;
  title: string;
  summary: string | null;
  effectiveAt: string;
  contentUrl: string | null;
  changes: string[];
  createdAt: string;
}

// ============================================================================
// HELPERS
// ============================================================================

function snakeToCamel(row: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(row)) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    result[camelKey] = value;
  }
  return result;
}

// ============================================================================
// HOOK: useConsentManager — manage all consent preferences
// ============================================================================

export function useConsentManager() {
  const [consents, setConsents] = useState<UserConsent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadConsents = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('user_consent')
        .select('*')
        .order('consent_type');
      if (err) throw err;
      setConsents(
        (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as UserConsent
        )
      );
    } catch (e) {
      console.error('Failed to load consents:', e);
      setError('Could not load privacy preferences.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadConsents();
  }, [loadConsents]);

  const setConsent = useCallback(
    async (consentType: ConsentType, granted: boolean) => {
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const companyId = user.app_metadata?.company_id;
        const now = new Date().toISOString();

        const { error: err } = await supabase.from('user_consent').insert({
          user_id: user.id,
          company_id: companyId,
          consent_type: consentType,
          granted,
          granted_at: granted ? now : null,
          revoked_at: granted ? null : now,
          consent_version: '1.0',
        });
        if (err) throw err;
        await loadConsents();
      } catch (e) {
        console.error('Failed to set consent:', e);
        setError('Could not update privacy preference.');
      }
    },
    [loadConsents]
  );

  // Get the latest consent status per type
  const consentStatus: Record<ConsentType, boolean> = {
    pricing_data_sharing: false,
    ai_training: false,
    analytics: true, // Default ON
    marketing_emails: false,
    push_notifications: false,
  };
  for (const consent of consents) {
    consentStatus[consent.consentType] = consent.granted;
  }

  return { consents, consentStatus, loading, error, setConsent, reload: loadConsents };
}

// ============================================================================
// HOOK: useDataExport — request and track data exports
// ============================================================================

export function useDataExport() {
  const [requests, setRequests] = useState<DataExportRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadRequests = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('data_export_requests')
        .select('*')
        .order('created_at', { ascending: false });
      if (err) throw err;
      setRequests(
        (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as DataExportRequest
        )
      );
    } catch (e) {
      console.error('Failed to load export requests:', e);
      setError('Could not load data export requests.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRequests();
  }, [loadRequests]);

  const requestExport = useCallback(
    async (format: ExportFormat = 'json') => {
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const companyId = user.app_metadata?.company_id;
        const { error: err } = await supabase
          .from('data_export_requests')
          .insert({
            user_id: user.id,
            company_id: companyId,
            export_format: format,
          });
        if (err) throw err;
        await loadRequests();
      } catch (e) {
        console.error('Failed to request export:', e);
        setError('Could not request data export.');
      }
    },
    [loadRequests]
  );

  return { requests, loading, error, requestExport, reload: loadRequests };
}

// ============================================================================
// HOOK: useDataDeletion — request and track data deletion
// ============================================================================

export function useDataDeletion() {
  const [requests, setRequests] = useState<DataDeletionRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadRequests = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('data_deletion_requests')
        .select('*')
        .order('created_at', { ascending: false });
      if (err) throw err;
      setRequests(
        (data ?? []).map(
          (row: Record<string, unknown>) =>
            snakeToCamel(row) as unknown as DataDeletionRequest
        )
      );
    } catch (e) {
      console.error('Failed to load deletion requests:', e);
      setError('Could not load data deletion requests.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadRequests();
  }, [loadRequests]);

  const requestDeletion = useCallback(
    async (scope: DeletionScope = 'user_data', reason?: string) => {
      try {
        const supabase = getSupabase();
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (!user) throw new Error('Not authenticated');

        const companyId = user.app_metadata?.company_id;
        const { error: err } = await supabase
          .from('data_deletion_requests')
          .insert({
            user_id: user.id,
            company_id: companyId,
            scope,
            reason: reason ?? null,
          });
        if (err) throw err;
        await loadRequests();
      } catch (e) {
        console.error('Failed to request deletion:', e);
        setError('Could not request data deletion.');
      }
    },
    [loadRequests]
  );

  const confirmDeletion = useCallback(
    async (id: string, confirmationCode: string) => {
      try {
        const supabase = getSupabase();
        const now = new Date();
        const gracePeriodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        const { error: err } = await supabase
          .from('data_deletion_requests')
          .update({
            status: 'confirmed',
            confirmation_code: confirmationCode,
            confirmed_at: now.toISOString(),
            grace_period_ends: gracePeriodEnd.toISOString(),
          })
          .eq('id', id)
          .eq('status', 'pending');
        if (err) throw err;
        await loadRequests();
      } catch (e) {
        console.error('Failed to confirm deletion:', e);
        setError('Could not confirm data deletion.');
      }
    },
    [loadRequests]
  );

  const cancelDeletion = useCallback(
    async (id: string) => {
      try {
        const supabase = getSupabase();
        const { error: err } = await supabase
          .from('data_deletion_requests')
          .update({ status: 'cancelled' })
          .eq('id', id);
        if (err) throw err;
        await loadRequests();
      } catch (e) {
        console.error('Failed to cancel deletion:', e);
        setError('Could not cancel data deletion.');
      }
    },
    [loadRequests]
  );

  return {
    requests,
    loading,
    error,
    requestDeletion,
    confirmDeletion,
    cancelDeletion,
    reload: loadRequests,
  };
}

// ============================================================================
// HOOK: usePrivacyPolicy — view policy versions
// ============================================================================

export function usePrivacyPolicy() {
  const [versions, setVersions] = useState<PrivacyPolicyVersion[]>([]);
  const [current, setCurrent] = useState<PrivacyPolicyVersion | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadPolicies = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('privacy_policy_versions')
        .select('*')
        .order('effective_at', { ascending: false });
      if (err) throw err;
      const mapped = (data ?? []).map(
        (row: Record<string, unknown>) =>
          snakeToCamel(row) as unknown as PrivacyPolicyVersion
      );
      setVersions(mapped);
      if (mapped.length > 0) {
        setCurrent(mapped[0]);
      }
    } catch (e) {
      console.error('Failed to load privacy policies:', e);
      setError('Could not load privacy policy.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPolicies();
  }, [loadPolicies]);

  return { versions, current, loading, error, reload: loadPolicies };
}
