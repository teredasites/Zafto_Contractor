'use client';

// Client Portal — Signature Requests hook
// Homeowners see documents waiting for their signature and can sign them.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface PendingSignature {
  id: string;
  documentTitle: string;
  senderName: string | null;
  signerRole: string;
  status: string;
  sentAt: string | null;
  expiresAt: string | null;
  createdAt: string;
}

export interface CompletedSignature {
  id: string;
  documentTitle: string;
  signedAt: string;
  signerName: string;
}

export function useMySignatureRequests() {
  const [pending, setPending] = useState<PendingSignature[]>([]);
  const [completed, setCompleted] = useState<CompletedSignature[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) { setLoading(false); return; }

      const email = user.email;
      if (!email) { setLoading(false); return; }

      // Fetch signature requests addressed to this user's email
      const { data, error: err } = await supabase
        .from('zdocs_signature_requests')
        .select('*, zdocs_renders(title, rendered_by_user_id)')
        .eq('signer_email', email)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);

      if (err) throw err;

      const rows = data || [];

      // Resolve sender names
      const senderIds = [...new Set(
        rows
          .map((r: Record<string, unknown>) => {
            const render = r.zdocs_renders as Record<string, unknown> | null;
            return render?.rendered_by_user_id as string | null;
          })
          .filter(Boolean) as string[]
      )];

      const nameMap = new Map<string, string>();
      if (senderIds.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, full_name')
          .in('id', senderIds);
        for (const p of profiles || []) {
          nameMap.set(p.id, p.full_name || 'Unknown');
        }
      }

      const pendingList: PendingSignature[] = [];
      const completedList: CompletedSignature[] = [];

      for (const row of rows) {
        const render = row.zdocs_renders as Record<string, unknown> | null;
        const title = (render?.title as string) || 'Document';
        const senderId = render?.rendered_by_user_id as string | null;

        if (row.status === 'signed') {
          completedList.push({
            id: row.id as string,
            documentTitle: title,
            signedAt: row.signed_at as string,
            signerName: row.signer_name as string,
          });
        } else if (['pending', 'sent', 'viewed'].includes(row.status as string)) {
          pendingList.push({
            id: row.id as string,
            documentTitle: title,
            senderName: senderId ? nameMap.get(senderId) || null : null,
            signerRole: (row.signer_role as string) || 'signer',
            status: row.status as string,
            sentAt: row.sent_at as string | null,
            expiresAt: row.expires_at as string | null,
            createdAt: row.created_at as string,
          });
        }
      }

      setPending(pendingList);
      setCompleted(completedList);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load signature requests');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetch();
    const supabase = getSupabase();
    const channel = supabase
      .channel('client-signatures')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'zdocs_signature_requests' }, () => fetch())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetch]);

  return { pending, completed, pendingCount: pending.length, loading, error, refresh: fetch };
}
