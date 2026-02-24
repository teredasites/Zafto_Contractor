'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  Star,
  Send,
  Clock,
  CheckCircle,
  XCircle,
  SkipForward,
  AlertTriangle,
  MoreHorizontal,
  MessageSquare,
  Mail,
  Smartphone,
  TrendingUp,
  BarChart3,
  Target,
  Users,
  Filter,
  Inbox,
  ExternalLink,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import {
  useReviewRequests,
  type ReviewRequestData,
  type ReviewStatus,
  type ReviewPlatform,
} from '@/lib/hooks/use-review-requests';
import { useTranslation } from '@/lib/translations';

const statusConfig: Record<ReviewStatus, { label: string; color: string; bgColor: string; icon: typeof Star }> = {
  pending: { label: 'Pending', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30', icon: Clock },
  sent: { label: 'Sent', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30', icon: Send },
  opened: { label: 'Opened', color: 'text-indigo-700 dark:text-indigo-300', bgColor: 'bg-indigo-100 dark:bg-indigo-900/30', icon: ExternalLink },
  completed: { label: 'Completed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30', icon: CheckCircle },
  skipped: { label: 'Skipped', color: 'text-slate-500 dark:text-slate-400', bgColor: 'bg-slate-100 dark:bg-slate-800/30', icon: SkipForward },
  failed: { label: 'Failed', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30', icon: XCircle },
};

const platformConfig: Record<ReviewPlatform, { label: string; color: string }> = {
  google: { label: 'Google', color: 'text-blue-600 dark:text-blue-400' },
  yelp: { label: 'Yelp', color: 'text-red-600 dark:text-red-400' },
  facebook: { label: 'Facebook', color: 'text-indigo-600 dark:text-indigo-400' },
  custom: { label: 'Custom', color: 'text-slate-600 dark:text-slate-400' },
};

const channelIcon: Record<string, typeof Mail> = {
  email: Mail,
  sms: Smartphone,
  both: MessageSquare,
};

function StarRating({ rating }: { rating: number | null }) {
  const { t } = useTranslation();
  if (rating == null) return <span className="text-xs text-muted">{t('reviews.noRating')}</span>;
  return (
    <div className="flex items-center gap-0.5">
      {[1, 2, 3, 4, 5].map(i => (
        <Star
          key={i}
          className={cn('h-3.5 w-3.5', i <= rating ? 'text-amber-500 fill-amber-500' : 'text-zinc-300 dark:text-zinc-600')}
        />
      ))}
      <span className="ml-1 text-xs font-medium">{rating}/5</span>
    </div>
  );
}

export default function ReviewsPage() {
  const { t } = useTranslation();
  const {
    reviewRequests,
    stats,
    loading,
    error,
    sendReviewRequest,
    skipReviewRequest,
    deleteReviewRequest,
  } = useReviewRequests();

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [platformFilter, setPlatformFilter] = useState<string>('all');
  const [sending, setSending] = useState<string | null>(null);

  const filtered = reviewRequests.filter(r => {
    if (search) {
      const q = search.toLowerCase();
      if (
        !r.customerName?.toLowerCase().includes(q) &&
        !r.jobTitle?.toLowerCase().includes(q)
      ) return false;
    }
    if (statusFilter !== 'all' && r.status !== statusFilter) return false;
    if (platformFilter !== 'all' && r.reviewPlatform !== platformFilter) return false;
    return true;
  });

  const handleSend = async (id: string) => {
    setSending(id);
    try {
      await sendReviewRequest(id);
    } catch {
      // Error handled via hook
    } finally {
      setSending(null);
    }
  };

  const handleSkip = async (id: string) => {
    try { await skipReviewRequest(id); } catch { /* handled */ }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3">
        <AlertTriangle className="h-8 w-8 text-red-400" />
        <p className="text-red-400">{error}</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 p-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('reviews.title')}</h1>
          <p className="text-sm text-muted mt-1">
            Track review requests and customer ratings
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('reviews.requestsSent')}</p>
                <p className="text-2xl font-bold text-main mt-1">{stats.totalSent}</p>
              </div>
              <div className="h-10 w-10 rounded-lg bg-blue-500/10 flex items-center justify-center">
                <Send className="h-5 w-5 text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('reviews.reviewsReceived')}</p>
                <p className="text-2xl font-bold text-main mt-1">{stats.totalCompleted}</p>
              </div>
              <div className="h-10 w-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                <CheckCircle className="h-5 w-5 text-emerald-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('common.avgRating')}</p>
                <div className="flex items-center gap-2 mt-1">
                  <p className="text-2xl font-bold text-main">{stats.avgRating > 0 ? stats.avgRating.toFixed(1) : '--'}</p>
                  {stats.avgRating > 0 && <Star className="h-5 w-5 text-amber-500 fill-amber-500" />}
                </div>
              </div>
              <div className="h-10 w-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
                <Star className="h-5 w-5 text-amber-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">{t('leadsPage.conversionRate')}</p>
                <p className="text-2xl font-bold text-main mt-1">{stats.conversionRate > 0 ? `${stats.conversionRate.toFixed(0)}%` : '--'}</p>
              </div>
              <div className="h-10 w-10 rounded-lg bg-purple-500/10 flex items-center justify-center">
                <Target className="h-5 w-5 text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="flex-1 max-w-sm">
          <SearchInput
            placeholder="Search by customer or job..."
            value={search}
            onChange={(value) => setSearch(value)}
          />
        </div>
        <Select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'pending', label: 'Pending' },
            { value: 'sent', label: 'Sent' },
            { value: 'opened', label: 'Opened' },
            { value: 'completed', label: 'Completed' },
            { value: 'skipped', label: 'Skipped' },
            { value: 'failed', label: 'Failed' },
          ]}
        />
        <Select
          value={platformFilter}
          onChange={(e) => setPlatformFilter(e.target.value)}
          options={[
            { value: 'all', label: 'All Platforms' },
            { value: 'google', label: 'Google' },
            { value: 'yelp', label: 'Yelp' },
            { value: 'facebook', label: 'Facebook' },
            { value: 'custom', label: 'Custom' },
          ]}
        />
      </div>

      {/* Pending Count */}
      {stats.pending > 0 && (
        <div className="flex items-center gap-2 px-3 py-2 bg-amber-500/10 border border-amber-500/20 rounded-lg">
          <Clock className="h-4 w-4 text-amber-400" />
          <span className="text-sm text-amber-300">{stats.pending} review request{stats.pending !== 1 ? 's' : ''} pending — ready to send</span>
        </div>
      )}

      {/* Review Requests List */}
      {filtered.length === 0 ? (
        <Card className="">
          <CardContent className="flex flex-col items-center justify-center py-16 gap-3">
            <Inbox className="h-12 w-12 text-muted opacity-50" />
            <p className="text-muted">{t('reviews.noReviewRequestsFound')}</p>
            <p className="text-xs text-muted">
              Review requests are created when jobs are marked complete
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filtered.map((request) => {
            const statusCfg = statusConfig[request.status];
            const StatusIcon = statusCfg.icon;
            const platformCfg = platformConfig[request.reviewPlatform];
            const ChannelIcon = channelIcon[request.channel] || MessageSquare;

            return (
              <Card key={request.id} className="hover:border-accent/30 transition-colors">
                <CardContent className="p-4">
                  <div className="flex items-center gap-4">
                    {/* Status Icon */}
                    <div className={cn('h-10 w-10 rounded-lg flex items-center justify-center shrink-0', statusCfg.bgColor)}>
                      <StatusIcon className={cn('h-5 w-5', statusCfg.color)} />
                    </div>

                    {/* Main Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium text-main truncate">
                          {request.customerName || 'Unknown Customer'}
                        </span>
                        <Badge variant="default" className={cn('text-[10px] px-1.5 py-0', statusCfg.color, statusCfg.bgColor)}>
                          {statusCfg.label}
                        </Badge>
                        <Badge variant="default" className={cn('text-[10px] px-1.5 py-0', platformCfg.color)}>
                          {platformCfg.label}
                        </Badge>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                        {request.jobTitle && (
                          <span className="truncate">{request.jobTitle}</span>
                        )}
                        <span className="flex items-center gap-1">
                          <ChannelIcon className="h-3 w-3" />
                          {request.channel}
                        </span>
                        <span>{formatDate(request.createdAt)}</span>
                        {request.sentAt && (
                          <span>Sent {formatDate(request.sentAt)}</span>
                        )}
                      </div>
                    </div>

                    {/* Rating */}
                    <div className="shrink-0">
                      <StarRating rating={request.ratingReceived} />
                    </div>

                    {/* Feedback */}
                    {request.feedbackText && (
                      <div className="shrink-0 max-w-[200px]">
                        <p className="text-xs text-muted italic truncate">
                          &ldquo;{request.feedbackText}&rdquo;
                        </p>
                      </div>
                    )}

                    {/* Actions */}
                    <div className="flex items-center gap-1 shrink-0">
                      {request.status === 'pending' && (
                        <>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-blue-400 hover:text-blue-300 hover:bg-blue-500/10 text-xs"
                            onClick={() => handleSend(request.id)}
                            disabled={sending === request.id}
                          >
                            <Send className="h-3.5 w-3.5 mr-1" />
                            {sending === request.id ? 'Sending...' : 'Send'}
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-muted hover:text-main text-xs"
                            onClick={() => handleSkip(request.id)}
                          >
                            <SkipForward className="h-3.5 w-3.5 mr-1" />
                            Skip
                          </Button>
                        </>
                      )}
                      {request.status === 'failed' && (
                        <Button
                          size="sm"
                          variant="ghost"
                          className="text-amber-400 hover:text-amber-300 hover:bg-amber-500/10 text-xs"
                          onClick={() => handleSend(request.id)}
                          disabled={sending === request.id}
                        >
                          <Send className="h-3.5 w-3.5 mr-1" />
                          Retry
                        </Button>
                      )}
                      {request.reviewUrl && request.status === 'completed' && (
                        <Button
                          size="sm"
                          variant="ghost"
                          className="text-muted hover:text-main text-xs"
                          onClick={() => window.open(request.reviewUrl!, '_blank')}
                        >
                          <ExternalLink className="h-3.5 w-3.5 mr-1" />
                          View
                        </Button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
