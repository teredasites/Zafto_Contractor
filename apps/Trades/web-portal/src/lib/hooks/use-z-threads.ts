'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface ZThreadRow {
  id: string;
  title: string;
  pageContext: string | null;
  messages: Array<{ role: string; content: string }>;
  artifactId: string | null;
  tokenCount: number;
  createdAt: string;
  updatedAt: string;
}

function mapThread(row: Record<string, unknown>): ZThreadRow {
  return {
    id: row.id as string,
    title: (row.title as string) || 'New conversation',
    pageContext: row.page_context as string | null,
    messages: (row.messages as Array<{ role: string; content: string }>) || [],
    artifactId: row.artifact_id as string | null,
    tokenCount: (row.token_count as number) || 0,
    createdAt: row.created_at as string,
    updatedAt: row.updated_at as string,
  };
}

export function useZThreads() {
  const [threads, setThreads] = useState<ZThreadRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchThreads = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('z_threads')
        .select('*')
        .is('deleted_at', null)
        .order('updated_at', { ascending: false })
        .limit(50);

      if (err) throw err;
      setThreads((data || []).map(mapThread));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load threads';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchThreads();

    const supabase = getSupabase();
    const channel = supabase
      .channel('z-threads-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'z_threads' }, () => {
        fetchThreads();
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchThreads]);

  const createThread = useCallback(async (title: string, pageContext: string): Promise<string | null> => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      // Get company_id from user profile
      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', user.id)
        .single();

      if (!profile?.company_id) return null;

      const { data, error: err } = await supabase
        .from('z_threads')
        .insert({
          company_id: profile.company_id,
          user_id: user.id,
          title,
          page_context: pageContext,
          messages: [],
        })
        .select('id')
        .single();

      if (err) throw err;
      return data?.id || null;
    } catch (e: unknown) {
      console.error('Failed to create thread:', e);
      return null;
    }
  }, []);

  const deleteThread = useCallback(async (threadId: string) => {
    try {
      const supabase = getSupabase();
      await supabase
        .from('z_threads')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', threadId);
    } catch (e: unknown) {
      console.error('Failed to delete thread:', e);
    }
  }, []);

  return { threads, loading, error, fetchThreads, createThread, deleteThread };
}

export function useZThread(threadId: string | null) {
  const [thread, setThread] = useState<ZThreadRow | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!threadId) {
      setThread(null);
      return;
    }

    const fetchThread = async () => {
      setLoading(true);
      try {
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('z_threads')
          .select('*')
          .eq('id', threadId)
          .is('deleted_at', null)
          .single();

        if (err) throw err;
        setThread(data ? mapThread(data) : null);
      } catch {
        setThread(null);
      } finally {
        setLoading(false);
      }
    };

    fetchThread();
  }, [threadId]);

  return { thread, loading };
}
