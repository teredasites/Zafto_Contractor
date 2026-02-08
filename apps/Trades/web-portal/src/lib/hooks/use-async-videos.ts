'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface AsyncVideo {
  id: string;
  companyId: string;
  jobId: string | null;
  jobTitle?: string;
  title: string | null;
  videoPath: string;
  thumbnailPath: string | null;
  durationSeconds: number | null;
  fileSizeBytes: number | null;
  sentByName: string;
  recipientType: string;
  recipientName: string | null;
  recipientEmail: string | null;
  message: string | null;
  shareToken: string;
  aiSummary: string | null;
  sentAt: string;
  viewedAt: string | null;
  viewCount: number;
  replyToId: string | null;
  deliveredVia: string[];
  createdAt: string;
}

function mapVideo(row: Record<string, unknown>): AsyncVideo {
  const job = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    jobTitle: (job?.title as string) || undefined,
    title: (row.title as string) || null,
    videoPath: row.video_path as string,
    thumbnailPath: (row.thumbnail_path as string) || null,
    durationSeconds: (row.duration_seconds as number) || null,
    fileSizeBytes: (row.file_size_bytes as number) || null,
    sentByName: row.sent_by_name as string,
    recipientType: row.recipient_type as string,
    recipientName: (row.recipient_name as string) || null,
    recipientEmail: (row.recipient_email as string) || null,
    message: (row.message as string) || null,
    shareToken: row.share_token as string,
    aiSummary: (row.ai_summary as string) || null,
    sentAt: row.sent_at as string,
    viewedAt: (row.viewed_at as string) || null,
    viewCount: (row.view_count as number) || 0,
    replyToId: (row.reply_to_id as string) || null,
    deliveredVia: (row.delivered_via as string[]) || [],
    createdAt: row.created_at as string,
  };
}

export function useAsyncVideos() {
  const [videos, setVideos] = useState<AsyncVideo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const { data, error: err } = await supabase
        .from('async_videos')
        .select('*, jobs(title)')
        .order('sent_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setVideos((data || []).map(mapVideo));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load videos');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();

    const supabase = getSupabase();
    const channel = supabase
      .channel('async-videos-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'async_videos' }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchData]);

  const sent = videos.filter(v => !v.replyToId);
  const replies = videos.filter(v => !!v.replyToId);
  const unviewed = videos.filter(v => v.viewCount === 0 && v.recipientType !== 'team_member');

  return { videos, sent, replies, unviewed, loading, error, refetch: fetchData };
}
