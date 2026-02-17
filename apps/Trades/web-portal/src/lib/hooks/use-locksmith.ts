'use client';

import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

export interface LocksmithServiceLog {
  id: string;
  company_id: string;
  job_id: string | null;
  property_id: string | null;
  service_type: string;
  lock_brand: string | null;
  lock_type: string | null;
  key_type: string | null;
  pins: number | null;
  bitting_code: string | null;
  master_key_system_id: string | null;
  keyway: string | null;
  vin_number: string | null;
  vehicle_year: number | null;
  vehicle_make: string | null;
  vehicle_model: string | null;
  diagnosis: string | null;
  work_performed: string | null;
  parts_used: Record<string, unknown>[];
  photos: string[];
  diagnostic_steps: Record<string, unknown>[];
  labor_minutes: number | null;
  parts_cost: number | null;
  labor_cost: number | null;
  total_cost: number | null;
  technician_name: string | null;
  notes: string | null;
  created_at: string;
}

export const LOCKSMITH_SERVICE_LABELS: Record<string, string> = {
  rekey: 'Rekey', lockout: 'Lockout', lock_change: 'Lock Change',
  master_key: 'Master Key', safe: 'Safe', automotive_lockout: 'Automotive Lockout',
  transponder_key: 'Transponder Key', high_security: 'High Security',
  access_control: 'Access Control', key_duplication: 'Key Duplication',
  lock_repair: 'Lock Repair', deadbolt_install: 'Deadbolt Install',
  commercial_lockout: 'Commercial Lockout',
};

export const LOCK_TYPE_LABELS: Record<string, string> = {
  deadbolt: 'Deadbolt', knob: 'Knob', lever: 'Lever', padlock: 'Padlock',
  mortise: 'Mortise', rim: 'Rim', cam: 'Cam', electronic: 'Electronic',
  smart: 'Smart', automotive: 'Automotive', cabinet: 'Cabinet',
  mailbox: 'Mailbox', safe: 'Safe',
};

export function useLocksmithLogs() {
  const supabase = createClient();
  const [logs, setLogs] = useState<LocksmithServiceLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetch = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const { data, error: err } = await supabase
        .from('locksmith_service_logs')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (err) throw err;
      setLogs((data ?? []) as LocksmithServiceLog[]);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [supabase]);

  useEffect(() => {
    fetch();
    const channel = supabase
      .channel('locksmith_rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'locksmith_service_logs' }, () => { fetch(); })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [supabase, fetch]);

  const create = useCallback(async (payload: Partial<LocksmithServiceLog>) => {
    const { data, error: err } = await supabase.from('locksmith_service_logs').insert(payload).select().single();
    if (err) throw err;
    return data as LocksmithServiceLog;
  }, [supabase]);

  return { logs, loading, error, refetch: fetch, create };
}
