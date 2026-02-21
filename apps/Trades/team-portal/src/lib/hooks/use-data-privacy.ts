'use client';

// DEPTH33: Data Privacy Controls Hook (Team Portal)
// Field technicians can view/manage their own consent preferences
// and view privacy policy. Read-only for export/deletion status.

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

export interface UserConsent {
  id: string;
  consentType: ConsentType;
  granted: boolean;
  consentVersion: string;
  createdAt: string;
}

export interface PrivacyPolicyVersion {
  id: string;
  version: string;
  title: string;
  summary: string | null;
  effectiveAt: string;
  changes: string[];
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
// HOOK: useMyConsent — view/manage own consent preferences
// ============================================================================

export function useMyConsent() {
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
        .select('id, consent_type, granted, consent_version, created_at')
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

  const toggleConsent = useCallback(
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
        console.error('Failed to update consent:', e);
        setError('Could not update privacy preference.');
      }
    },
    [loadConsents]
  );

  // Latest status per type
  const consentStatus: Record<ConsentType, boolean> = {
    pricing_data_sharing: false,
    ai_training: false,
    analytics: true,
    marketing_emails: false,
    push_notifications: false,
  };
  for (const consent of consents) {
    consentStatus[consent.consentType] = consent.granted;
  }

  return { consents, consentStatus, loading, error, toggleConsent, reload: loadConsents };
}

// ============================================================================
// HOOK: useTeamPrivacyPolicy — view current privacy policy
// ============================================================================

export function useTeamPrivacyPolicy() {
  const [current, setCurrent] = useState<PrivacyPolicyVersion | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('privacy_policy_versions')
          .select('id, version, title, summary, effective_at, changes')
          .order('effective_at', { ascending: false })
          .limit(1)
          .maybeSingle();
        if (err) throw err;
        if (data) {
          setCurrent(
            snakeToCamel(data as Record<string, unknown>) as unknown as PrivacyPolicyVersion
          );
        }
      } catch (e) {
        console.error('Failed to load privacy policy:', e);
        setError('Could not load privacy policy.');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  return { current, loading, error };
}
