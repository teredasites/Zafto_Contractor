'use client';

// L8: CE Credit Tracking — log CE hours, track progress toward renewal, verify credits

import { useState, useMemo } from 'react';
import {
  GraduationCap,
  Plus,
  CheckCircle,
  Clock,
  Award,
  ArrowLeft,
  FileText,
  BarChart3,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useCECredits, useLicenseRenewals, type CECreditLog } from '@/lib/hooks/use-ce-tracking';
import { useTranslation } from '@/lib/translations';

function StatCard({ label, value, icon: Icon, variant }: {
  label: string; value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  variant?: 'success' | 'warning' | 'error' | 'default';
}) {
  const colors = {
    success: { text: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    warning: { text: 'text-amber-400', bg: 'bg-amber-500/10' },
    error: { text: 'text-red-400', bg: 'bg-red-500/10' },
    default: { text: 'text-zinc-400', bg: 'bg-zinc-800' },
  }[variant || 'default'];

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${colors.bg}`}>
            <Icon className={`h-4 w-4 ${colors.text}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${colors.text}`}>{value}</p>
            <p className="text-xs text-zinc-500">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ProgressBar({ completed, required }: { completed: number; required: number }) {
  const pct = required > 0 ? Math.min((completed / required) * 100, 100) : 0;
  const color = pct >= 100 ? 'bg-emerald-500' : pct >= 50 ? 'bg-blue-500' : 'bg-amber-500';

  return (
    <div className="w-full">
      <div className="flex items-center justify-between text-xs mb-1">
        <span className="text-zinc-400">{completed} / {required} credits</span>
        <span className="text-zinc-500">{Math.round(pct)}%</span>
      </div>
      <div className="h-2 bg-zinc-800 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default function CETrackingPage() {
  const { t, formatDate } = useTranslation();
  const { credits, summary, loading: creditsLoading, error: creditsError } = useCECredits();
  const { renewals, renewalSummary, loading: renewalsLoading } = useLicenseRenewals();
  const [searchQuery, setSearchQuery] = useState('');

  const loading = creditsLoading || renewalsLoading;

  const filtered = useMemo(() => {
    if (!searchQuery) return credits;
    const q = searchQuery.toLowerCase();
    return credits.filter(c =>
      c.course_name.toLowerCase().includes(q) ||
      (c.provider || '').toLowerCase().includes(q) ||
      (c.ce_category || '').toLowerCase().includes(q)
    );
  }, [credits, searchQuery]);

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (creditsError) {
    return (
      <div className="p-6">
        <Card><CardContent className="p-8 text-center"><p className="text-red-400">{creditsError}</p></CardContent></Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/compliance">
          <Button variant="ghost" size="sm"><ArrowLeft className="h-4 w-4 mr-1" /> {t('common.back')}</Button>
        </Link>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-white">{t('complianceCeTracking.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">Track continuing education hours toward license renewals</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label="Total Credits" value={summary.totalCredits} icon={GraduationCap} />
        <StatCard label="Courses Completed" value={summary.totalCourses} icon={Award} />
        <StatCard label="Verified" value={summary.verifiedCredits} icon={CheckCircle} variant="success" />
        <StatCard label="Pending Verification" value={summary.pendingCredits} icon={Clock} variant="warning" />
        <StatCard label="Renewals Due" value={renewalSummary.upcoming} icon={FileText} variant={renewalSummary.overdue > 0 ? 'error' : 'default'} />
      </div>

      {/* Renewal Progress */}
      {renewals.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <BarChart3 className="h-4 w-4 text-blue-400" />
              License Renewal Progress
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {renewals.filter(r => r.status !== 'completed' && r.status !== 'waived').map(renewal => {
              const daysUntil = Math.ceil(
                (new Date(renewal.renewal_due_date).getTime() - Date.now()) / 86400000
              );
              return (
                <div key={renewal.id} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-white">
                      Renewal #{renewal.id.slice(0, 8)}
                    </span>
                    <div className="flex items-center gap-2">
                      <Badge
                        variant={renewal.status === 'overdue' ? 'error' : daysUntil <= 30 ? 'warning' : 'secondary'}
                        size="sm"
                      >
                        {renewal.status === 'overdue' ? 'Overdue' : `${daysUntil}d remaining`}
                      </Badge>
                      {!renewal.fee_paid && renewal.renewal_fee && (
                        <span className="text-xs text-amber-400">${renewal.renewal_fee} fee</span>
                      )}
                    </div>
                  </div>
                  <ProgressBar completed={renewal.ce_credits_completed} required={renewal.ce_credits_required} />
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}

      {/* Category Breakdown */}
      {summary.categoryBreakdown.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Credits by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
              {summary.categoryBreakdown.map(({ category, hours }) => (
                <div key={category} className="p-3 bg-zinc-800/50 rounded-lg">
                  <p className="text-xs text-zinc-500">{category}</p>
                  <p className="text-lg font-bold text-white">{hours} hrs</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Search + Credit List */}
      <SearchInput
        placeholder="Search courses, providers, categories..."
        value={searchQuery}
        onChange={setSearchQuery}
      />

      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-8 text-center">
            <GraduationCap className="h-12 w-12 text-zinc-600 mx-auto mb-3" />
            <p className="text-zinc-400">No CE credits recorded yet</p>
            <p className="text-sm text-zinc-500 mt-1">Credits will appear here as courses are completed</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filtered.map((credit: CECreditLog) => (
            <Card key={credit.id} className="hover:border-zinc-600 transition-colors">
              <CardContent className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${credit.verified ? 'bg-emerald-500/10' : 'bg-zinc-800'}`}>
                      {credit.verified
                        ? <CheckCircle className="h-4 w-4 text-emerald-400" />
                        : <Clock className="h-4 w-4 text-zinc-400" />}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="text-sm font-semibold text-white">{credit.course_name}</h3>
                        <Badge variant={credit.verified ? 'success' : 'warning'} size="sm">
                          {credit.verified ? 'Verified' : 'Pending'}
                        </Badge>
                      </div>
                      <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                        {credit.provider && <span>{credit.provider}</span>}
                        {credit.ce_category && (
                          <Badge variant="secondary" size="sm">{credit.ce_category}</Badge>
                        )}
                        <span>{formatDate(credit.completion_date)}</span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="text-right">
                      <p className="text-lg font-bold text-white">{credit.credit_hours}</p>
                      <p className="text-xs text-zinc-500">hours</p>
                    </div>
                    {credit.certificate_document_path && (
                      <FileText className="h-4 w-4 text-blue-400" />
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
