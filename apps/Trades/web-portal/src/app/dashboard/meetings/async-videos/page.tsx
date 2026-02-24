'use client';

import { useState } from 'react';
import {
  Video,
  Play,
  Eye,
  Clock,
  Users,
  Briefcase,
  Send,
  Reply,
  ExternalLink,
  Copy,
  Loader2,
} from 'lucide-react';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { useAsyncVideos } from '@/lib/hooks/use-async-videos';
import type { AsyncVideo } from '@/lib/hooks/use-async-videos';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale } from '@/lib/format-locale';

const recipientTypeLabels: Record<string, string> = {
  client: 'Client',
  team_member: 'Team',
  adjuster: 'Adjuster',
  subcontractor: 'Subcontractor',
  guest: 'Guest',
};

function formatDuration(seconds: number | null): string {
  if (!seconds) return '—';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${s.toString().padStart(2, '0')}`;
}

function formatFileSize(bytes: number | null): string {
  if (!bytes) return '';
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function VideoRow({ video }: { video: AsyncVideo }) {
  const copyShareLink = () => {
    navigator.clipboard.writeText(`https://zafto.cloud/watch/${video.shareToken}`);
  };

  return (
    <div className="flex items-center gap-4 px-4 py-3 hover:bg-surface-hover border-b border-main">
      <div className="flex-shrink-0 w-10 h-10 rounded bg-secondary flex items-center justify-center">
        <Play className="h-4 w-4 text-muted" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="font-medium text-main truncate">
            {video.title || `Video to ${video.recipientName || video.recipientEmail || 'Unknown'}`}
          </span>
          <Badge className="bg-blue-500/10 text-blue-400 border-blue-500/20">
            {recipientTypeLabels[video.recipientType] || video.recipientType}
          </Badge>
          {video.replyToId && (
            <Badge className="bg-violet-500/10 text-violet-400 border-violet-500/20">
              <Reply className="h-2.5 w-2.5 mr-0.5" />Reply
            </Badge>
          )}
        </div>
        <div className="flex items-center gap-3 text-xs text-muted mt-0.5">
          <span className="flex items-center gap-1">
            <Send className="h-3 w-3" />
            {video.sentByName}
          </span>
          <span className="flex items-center gap-1">
            <Clock className="h-3 w-3" />
            {formatDuration(video.durationSeconds)}
          </span>
          {video.fileSizeBytes && (
            <span>{formatFileSize(video.fileSizeBytes)}</span>
          )}
          {video.jobTitle && (
            <span className="flex items-center gap-1">
              <Briefcase className="h-3 w-3" />
              {video.jobTitle}
            </span>
          )}
          <span>{formatDateLocale(video.sentAt)}</span>
        </div>
        {video.message && (
          <p className="text-xs text-muted mt-1 line-clamp-1">{video.message}</p>
        )}
      </div>
      <div className="flex items-center gap-2 flex-shrink-0">
        <span className={cn(
          'flex items-center gap-1 text-xs',
          video.viewCount > 0 ? 'text-emerald-400' : 'text-muted'
        )}>
          <Eye className="h-3 w-3" />
          {video.viewCount > 0 ? `Viewed ${video.viewCount}x` : 'Not viewed'}
        </span>
        <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={copyShareLink} title="Copy share link">
          <Copy className="h-3.5 w-3.5" />
        </Button>
        <Button variant="ghost" size="sm" className="h-7 w-7 p-0" title="Open">
          <ExternalLink className="h-3.5 w-3.5" />
        </Button>
      </div>
    </div>
  );
}

type VideoTab = 'all' | 'sent' | 'unviewed';

export default function AsyncVideosPage() {
  const { t } = useTranslation();
  const { videos, sent, unviewed, loading, error } = useAsyncVideos();
  const [tab, setTab] = useState<VideoTab>('all');
  const [search, setSearch] = useState('');

  const displayed = tab === 'sent' ? sent : tab === 'unviewed' ? unviewed : videos;
  const filtered = displayed.filter(v => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (v.title || '').toLowerCase().includes(q) ||
      (v.recipientName || '').toLowerCase().includes(q) ||
      (v.jobTitle || '').toLowerCase().includes(q) ||
      v.sentByName.toLowerCase().includes(q);
  });

  return (
    <>
      <CommandPalette />
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{t('meetingsAsyncVideos.title')}</h1>
            <p className="text-sm text-muted mt-1">{t('meetingsAsync.loomstyleVideoMessagesTiedToJobs')}</p>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Video className="h-4 w-4" />Total Videos
              </div>
              <p className="text-2xl font-bold text-main mt-1">{videos.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Send className="h-4 w-4" />Sent
              </div>
              <p className="text-2xl font-bold text-main mt-1">{sent.length}</p>
            </CardContent>
          </Card>
          <Card className="bg-surface border-main">
            <CardContent className="p-4">
              <div className="flex items-center gap-2 text-sm text-muted">
                <Eye className="h-4 w-4 text-amber-400" />Not Viewed
              </div>
              <p className="text-2xl font-bold text-main mt-1">{unviewed.length}</p>
            </CardContent>
          </Card>
        </div>

        <Card className="bg-surface border-main">
          <CardHeader className="pb-0">
            <div className="flex items-center justify-between">
              <div className="flex gap-1">
                {(['all', 'sent', 'unviewed'] as VideoTab[]).map(t => (
                  <Button
                    key={t}
                    variant={tab === t ? 'default' : 'ghost'}
                    size="sm"
                    onClick={() => setTab(t)}
                    className="capitalize"
                  >
                    {t}
                    {t === 'unviewed' && unviewed.length > 0 && (
                      <span className="ml-1 text-xs bg-amber-500/20 text-amber-400 rounded-full px-1.5">
                        {unviewed.length}
                      </span>
                    )}
                  </Button>
                ))}
              </div>
              <SearchInput
                placeholder="Search videos..."
                value={search}
                onChange={(v) => setSearch(v)}
                className="w-60"
              />
            </div>
          </CardHeader>
          <CardContent className="p-0 mt-4">
            {loading ? (
              <div className="flex items-center justify-center py-12 text-muted">
                <Loader2 className="h-5 w-5 animate-spin mr-2" />Loading...
              </div>
            ) : error ? (
              <div className="text-red-400 text-center py-12">{error}</div>
            ) : filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <Video className="h-8 w-8 mb-2 opacity-50" />
                <p>No {tab === 'all' ? '' : tab} videos</p>
                <p className="text-xs mt-1">{t('meetingsAsync.recordAVideoFromAnyJobPage')}</p>
              </div>
            ) : (
              <div>
                {filtered.map(video => (
                  <VideoRow key={video.id} video={video} />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
