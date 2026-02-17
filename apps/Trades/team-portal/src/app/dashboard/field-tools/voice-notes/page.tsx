'use client';

// ZAFTO Team Portal — Voice Notes Browser
// Created: Sprint FIELD3 (Session 131)
//
// List voice recordings by job, play in browser with native audio element.
// Show transcription if available. Filter by transcription status.
// Uses voice_notes table + Supabase Storage.

import { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import {
  ArrowLeft,
  Mic,
  Play,
  Pause,
  FileText,
  Clock,
  AlertTriangle,
  Loader2,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

// ════════════════════════════════════════════════════════════════
// TYPES
// ════════════════════════════════════════════════════════════════

interface VoiceNote {
  id: string;
  jobId: string | null;
  storagePath: string;
  durationSeconds: number | null;
  transcription: string | null;
  transcriptionStatus: string;
  tags: string[];
  recordedAt: string;
  signedUrl?: string;
  jobTitle?: string;
}

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

export default function VoiceNotesPage() {
  const [notes, setNotes] = useState<VoiceNote[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const fetchNotes = useCallback(async () => {
    try {
      setError(null);
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      const { data, error: err } = await supabase
        .from('voice_notes')
        .select('*, jobs(title)')
        .eq('recorded_by_user_id', user.id)
        .is('deleted_at', null)
        .order('recorded_at', { ascending: false })
        .limit(100);

      if (err) throw err;

      const mapped: VoiceNote[] = [];
      for (const row of (data || [])) {
        const r = row as Record<string, unknown>;
        const jobData = r.jobs as Record<string, unknown> | null;
        const storagePath = r.storage_path as string;

        const { data: urlData } = await supabase.storage
          .from('voice-notes')
          .createSignedUrl(storagePath, 3600);

        mapped.push({
          id: r.id as string,
          jobId: (r.job_id as string) || null,
          storagePath,
          durationSeconds: r.duration_seconds != null ? Number(r.duration_seconds) : null,
          transcription: (r.transcription as string) || null,
          transcriptionStatus: (r.transcription_status as string) || 'pending',
          tags: (r.tags as string[]) || [],
          recordedAt: r.recorded_at as string,
          signedUrl: urlData?.signedUrl || undefined,
          jobTitle: jobData?.title as string | undefined,
        });
      }

      setNotes(mapped);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load voice notes');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchNotes();
  }, [fetchNotes]);

  const togglePlay = (note: VoiceNote) => {
    if (playingId === note.id) {
      audioRef.current?.pause();
      setPlayingId(null);
      return;
    }

    if (audioRef.current) {
      audioRef.current.pause();
    }

    if (note.signedUrl) {
      const audio = new Audio(note.signedUrl);
      audio.onended = () => setPlayingId(null);
      audio.play().catch(() => setPlayingId(null));
      audioRef.current = audio;
      setPlayingId(note.id);
    }
  };

  useEffect(() => {
    return () => {
      audioRef.current?.pause();
    };
  }, []);

  function formatDuration(seconds: number | null): string {
    if (!seconds) return '--:--';
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, '0')}`;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <Link
          href="/dashboard/field-tools"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>Field Tools</span>
        </Link>
        <h1 className="text-xl font-bold text-main">Voice Notes</h1>
        <p className="text-sm text-muted mt-1">Browse and play recorded voice memos</p>
      </div>

      {/* Content */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-secondary rounded-lg p-4 animate-pulse">
              <div className="skeleton h-5 w-40 mb-2" />
              <div className="skeleton h-3 w-24" />
            </div>
          ))}
        </div>
      ) : error ? (
        <div className="text-center py-12">
          <AlertTriangle size={40} className="mx-auto text-red-400 mb-3" />
          <p className="text-main font-medium">Failed to load voice notes</p>
          <p className="text-sm text-muted mt-1">{error}</p>
          <button onClick={fetchNotes} className="mt-4 px-4 py-2 bg-accent text-white rounded-lg text-sm">
            Retry
          </button>
        </div>
      ) : notes.length === 0 ? (
        <div className="text-center py-16">
          <Mic size={48} className="mx-auto text-muted mb-4" />
          <p className="text-main font-medium">No voice notes</p>
          <p className="text-sm text-muted mt-1">Voice memos recorded in the mobile app will appear here</p>
        </div>
      ) : (
        <div className="space-y-3">
          {notes.map((note) => {
            const isPlaying = playingId === note.id;
            const isExpanded = expandedId === note.id;

            return (
              <Card key={note.id} className="p-4">
                <div className="flex items-center gap-3">
                  {/* Play button */}
                  <button
                    onClick={() => togglePlay(note)}
                    disabled={!note.signedUrl}
                    className={cn(
                      'flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center transition-colors',
                      isPlaying
                        ? 'bg-accent text-white'
                        : note.signedUrl
                          ? 'bg-secondary text-main hover:bg-accent/10'
                          : 'bg-secondary text-muted cursor-not-allowed',
                    )}
                  >
                    {isPlaying ? <Pause size={16} /> : <Play size={16} />}
                  </button>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-main text-sm">
                        {note.jobTitle || 'General Note'}
                      </p>
                      {note.transcriptionStatus === 'completed' && (
                        <span className="px-1.5 py-0.5 bg-emerald-500/10 text-emerald-500 text-xs rounded">
                          Transcribed
                        </span>
                      )}
                      {note.transcriptionStatus === 'processing' && (
                        <span className="px-1.5 py-0.5 bg-amber-500/10 text-amber-500 text-xs rounded flex items-center gap-1">
                          <Loader2 size={10} className="animate-spin" /> Processing
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
                      <span className="flex items-center gap-1">
                        <Clock size={10} />
                        {formatDuration(note.durationSeconds)}
                      </span>
                      <span>{new Date(note.recordedAt).toLocaleDateString()}</span>
                    </div>
                  </div>

                  {/* Expand transcription */}
                  {note.transcription && (
                    <button
                      onClick={() => setExpandedId(isExpanded ? null : note.id)}
                      className="p-2 hover:bg-secondary rounded-lg text-muted"
                    >
                      <FileText size={16} />
                    </button>
                  )}
                </div>

                {/* Transcription */}
                {isExpanded && note.transcription && (
                  <div className="mt-3 p-3 bg-secondary rounded-lg">
                    <p className="text-xs text-muted mb-1 font-medium">Transcription</p>
                    <p className="text-sm text-main leading-relaxed">{note.transcription}</p>
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
