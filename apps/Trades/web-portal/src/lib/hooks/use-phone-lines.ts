'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface PhoneLine {
  id: string;
  companyId: string;
  userId: string | null;
  phoneNumber: string;
  lineType: 'main' | 'direct' | 'department' | 'fax';
  displayName: string | null;
  displayRole: string | null;
  callerIdName: string | null;
  isActive: boolean;
  voicemailEnabled: boolean;
  dndEnabled: boolean;
  status: 'online' | 'busy' | 'dnd' | 'offline';
  createdAt: string;
}

function mapLine(row: Record<string, unknown>): PhoneLine {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    userId: row.user_id as string | null,
    phoneNumber: row.phone_number as string,
    lineType: (row.line_type as PhoneLine['lineType']) || 'direct',
    displayName: row.display_name as string | null,
    displayRole: row.display_role as string | null,
    callerIdName: row.caller_id_name as string | null,
    isActive: row.is_active as boolean,
    voicemailEnabled: row.voicemail_enabled as boolean,
    dndEnabled: row.dnd_enabled as boolean,
    status: (row.status as PhoneLine['status']) || 'offline',
    createdAt: row.created_at as string,
  };
}

export function usePhoneLines() {
  const [lines, setLines] = useState<PhoneLine[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLines = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('phone_lines')
        .select('*')
        .eq('is_active', true)
        .order('line_type')
        .order('display_name');

      if (err) throw err;
      setLines((data || []).map(mapLine));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load phone lines');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLines();

    const supabase = getSupabase();
    const channel = supabase
      .channel('phone-lines-rt')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'phone_lines' }, () => fetchLines())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchLines]);

  const assignToUser = async (lineId: string, userId: string | null) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('phone_lines')
      .update({ user_id: userId })
      .eq('id', lineId);
    if (err) throw err;
  };

  const updateLine = async (lineId: string, updates: Partial<Record<string, unknown>>) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('phone_lines')
      .update(updates)
      .eq('id', lineId);
    if (err) throw err;
  };

  const getMainLine = () => lines.find((l) => l.lineType === 'main') || null;
  const getDirectLines = () => lines.filter((l) => l.lineType === 'direct');
  const getUnassignedLines = () => lines.filter((l) => !l.userId);

  return {
    lines,
    loading,
    error,
    assignToUser,
    updateLine,
    getMainLine,
    getDirectLines,
    getUnassignedLines,
    refetch: fetchLines,
  };
}
