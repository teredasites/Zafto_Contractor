'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export type TranscriptionStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface VoiceNoteData {
  id: string;
  companyId: string;
  jobId: string | null;
  userId: string;
  storagePath: string;
  durationSeconds: number;
  transcription: string | null;
  transcriptionStatus: TranscriptionStatus;
  tags: string[];
  createdAt: string;
  signedUrl?: string;
}

function mapVoiceNote(row: Record<string, unknown>): VoiceNoteData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || null,
    userId: (row.user_id as string) || '',
    storagePath: (row.storage_path as string) || '',
    durationSeconds: (row.duration_seconds as number) || 0,
    transcription: (row.transcription as string) || null,
    transcriptionStatus: (row.transcription_status as TranscriptionStatus) || 'pending',
    tags: (row.tags as string[]) || [],
    createdAt: (row.created_at as string) || '',
  };
}

export function useVoiceNotes(jobId?: string) {
  const [notes, setNotes] = useState<VoiceNoteData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchNotes = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      let query = supabase
        .from('voice_notes')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false });
      if (jobId) query = query.eq('job_id', jobId);
      const { data, error: err } = await query;
      if (err) throw err;

      const mapped = (data || []).map(mapVoiceNote);

      // Generate signed URLs for audio playback
      const withUrls = await Promise.all(
        mapped.map(async (n: VoiceNoteData) => {
          try {
            if (!n.storagePath) return n;
            const { data: urlData } = await supabase.storage
              .from('voice-notes')
              .createSignedUrl(n.storagePath, 3600);
            return { ...n, signedUrl: urlData?.signedUrl || '' };
          } catch {
            return n;
          }
        })
      );

      setNotes(withUrls);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load voice notes');
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => {
    fetchNotes();
    const supabase = getSupabase();
    const channel = supabase
      .channel('crm-voice-notes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'voice_notes' }, () => fetchNotes())
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [fetchNotes]);

  const updateTags = async (noteId: string, tags: string[]) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('voice_notes')
        .update({ tags })
        .eq('id', noteId);
      if (err) throw err;
      await fetchNotes();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to update voice note');
      throw e;
    }
  };

  const deleteNote = async (noteId: string) => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { error: err } = await supabase
        .from('voice_notes')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', noteId);
      if (err) throw err;
      await fetchNotes();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete voice note');
      throw e;
    }
  };

  const formatDuration = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const transcribedNotes = notes.filter(n => n.transcriptionStatus === 'completed');
  const pendingTranscription = notes.filter(n => n.transcriptionStatus === 'pending');
  const totalDuration = notes.reduce((sum, n) => sum + n.durationSeconds, 0);

  return {
    notes,
    loading,
    error,
    updateTags,
    deleteNote,
    formatDuration,
    transcribedNotes,
    pendingTranscription,
    totalDuration,
    refresh: fetchNotes,
  };
}
