'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  GraduationCap, AlertTriangle, CheckCircle2, Clock, BookOpen,
  Award, ExternalLink, Calendar, Search, ClipboardList,
} from 'lucide-react';
import { useMyTraining, TRAINING_TYPE_LABELS, TRAINING_TYPE_COLORS } from '@/lib/hooks/use-my-training';
import type { TrainingRecord, TrainingType } from '@/lib/hooks/use-my-training';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn, formatDate } from '@/lib/utils';

// ============================================================
// SKELETON
// ============================================================

function TrainingSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="h-8 w-48 bg-surface-hover animate-pulse rounded" />
      <div className="grid grid-cols-3 gap-4">
        {[...Array(3)].map((_, i) => <div key={i} className="h-24 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
      <div className="space-y-3">
        {[...Array(4)].map((_, i) => <div key={i} className="h-20 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
    </div>
  );
}

// ============================================================
// STATUS HELPERS
// ============================================================

type FilterTab = 'all' | 'active' | 'completed' | 'expiring';

function getTrainingStatusVariant(status: string): 'success' | 'warning' | 'error' | 'info' | 'default' {
  switch (status) {
    case 'completed': return 'success';
    case 'in_progress': return 'info';
    case 'assigned': return 'warning';
    case 'expired': return 'error';
    case 'waived': return 'default';
    default: return 'default';
  }
}

const STATUS_LABELS: Record<string, string> = {
  assigned: 'Assigned',
  in_progress: 'In Progress',
  completed: 'Completed',
  expired: 'Expired',
  waived: 'Waived',
};

function getDaysUntilExpiry(record: TrainingRecord): number | null {
  if (!record.expiresDate) return null;
  return Math.ceil((new Date(record.expiresDate).getTime() - Date.now()) / 86400000);
}

// ============================================================
// MAIN PAGE
// ============================================================

export default function TrainingPage() {
  const {
    trainingRecords, expiringSoon, completedTraining, activeTraining, incompleteChecklists,
    loading, error,
  } = useMyTraining();

  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');

  if (loading) return <TrainingSkeleton />;

  // Counts
  const counts = {
    all: trainingRecords.length,
    active: activeTraining.length,
    completed: completedTraining.length,
    expiring: expiringSoon.length,
  };

  // Filter records
  const filtered = trainingRecords.filter(r => {
    if (filter === 'active' && r.status !== 'assigned' && r.status !== 'in_progress') return false;
    if (filter === 'completed' && r.status !== 'completed') return false;
    if (filter === 'expiring') {
      const days = getDaysUntilExpiry(r);
      if (days === null || days <= 0 || days > 60) return false;
    }
    if (search) {
      const q = search.toLowerCase();
      return r.courseName.toLowerCase().includes(q) ||
        r.provider.toLowerCase().includes(q) ||
        r.trainingType.toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">My Training</h1>
        <p className="text-sm text-muted mt-1">
          Your training records, certifications, and onboarding progress
        </p>
      </div>

      {error && (
        <div className="px-4 py-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <CheckCircle2 size={20} className="mx-auto mb-1.5 text-emerald-500" />
          <div className="text-2xl font-bold text-main">{counts.completed}</div>
          <div className="text-xs text-muted">Completed</div>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <BookOpen size={20} className="mx-auto mb-1.5 text-blue-500" />
          <div className="text-2xl font-bold text-main">{counts.active}</div>
          <div className="text-xs text-muted">In Progress</div>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <AlertTriangle size={20} className="mx-auto mb-1.5 text-amber-500" />
          <div className="text-2xl font-bold text-main">{counts.expiring}</div>
          <div className="text-xs text-muted">Expiring Soon</div>
        </div>
      </div>

      {/* Expiring Soon Alert */}
      {expiringSoon.length > 0 && (
        <Card className="border-amber-200 dark:border-amber-800">
          <CardContent className="p-4">
            <div className="flex items-start gap-3">
              <AlertTriangle size={20} className="text-amber-500 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-sm font-semibold text-amber-700 dark:text-amber-300">
                  {expiringSoon.length} training{expiringSoon.length > 1 ? 's' : ''} expiring within 60 days
                </p>
                <div className="mt-2 space-y-1">
                  {expiringSoon.map(r => {
                    const days = getDaysUntilExpiry(r);
                    return (
                      <div key={r.id} className="flex items-center justify-between text-sm">
                        <span className="text-main">{r.courseName}</span>
                        <span className={cn(
                          'text-xs font-medium',
                          days !== null && days <= 14 ? 'text-red-500' : 'text-amber-500'
                        )}>
                          {days}d left
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Onboarding Checklists */}
      {incompleteChecklists.length > 0 && (
        <div className="space-y-3">
          <p className="text-sm font-semibold text-muted">Onboarding Checklists</p>
          {incompleteChecklists.map(checklist => {
            const totalItems = checklist.items.length;
            const completedItems = checklist.items.filter(i => i.status === 'completed').length;
            const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

            return (
              <Card key={checklist.id}>
                <CardContent className="p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="p-2 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 flex-shrink-0">
                      <ClipboardList size={18} className="text-emerald-600 dark:text-emerald-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-semibold text-main">{checklist.templateName}</p>
                      <p className="text-xs text-muted">{completedItems} of {totalItems} complete</p>
                    </div>
                    <span className="text-sm font-bold text-accent">{progress}%</span>
                  </div>

                  {/* Progress bar */}
                  <div className="w-full h-2 bg-secondary rounded-full overflow-hidden">
                    <div
                      className="h-full bg-accent rounded-full transition-all"
                      style={{ width: `${progress}%` }}
                    />
                  </div>

                  {/* Checklist items */}
                  <div className="mt-3 space-y-1.5">
                    {checklist.items.map(item => (
                      <div key={item.id} className="flex items-center gap-2 text-sm">
                        {item.status === 'completed' ? (
                          <CheckCircle2 size={14} className="text-emerald-500 flex-shrink-0" />
                        ) : (
                          <div className="w-3.5 h-3.5 rounded-full border-2 border-slate-300 dark:border-slate-600 flex-shrink-0" />
                        )}
                        <span className={cn(
                          'truncate',
                          item.status === 'completed' ? 'text-muted line-through' : 'text-main'
                        )}>
                          {item.title}
                        </span>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search training records..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 rounded-lg border border-main bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30"
        />
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        {([
          { key: 'all' as FilterTab, label: 'All', count: counts.all },
          { key: 'active' as FilterTab, label: 'Active', count: counts.active },
          { key: 'completed' as FilterTab, label: 'Completed', count: counts.completed },
          { key: 'expiring' as FilterTab, label: 'Expiring', count: counts.expiring },
        ]).map(tab => (
          <button
            key={tab.key}
            onClick={() => setFilter(tab.key)}
            className={cn(
              'px-3 py-2 rounded-lg text-xs font-medium transition-colors',
              filter === tab.key
                ? 'bg-accent/10 text-accent'
                : 'text-muted hover:text-main hover:bg-surface-hover'
            )}
          >
            {tab.label}
            <span className="ml-1 opacity-60">({tab.count})</span>
          </button>
        ))}
      </div>

      {/* Training Records List */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <GraduationCap size={40} className="text-muted opacity-30 mb-3" />
          <p className="text-main font-medium">
            {counts.all === 0 ? 'No training records' : 'No matching training records'}
          </p>
          <p className="text-sm text-muted mt-1">
            {counts.all === 0 ? 'Your training records will appear here.' : 'Try adjusting your search or filter.'}
          </p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(record => {
            const days = getDaysUntilExpiry(record);
            const typeColors = TRAINING_TYPE_COLORS[record.trainingType as TrainingType] || TRAINING_TYPE_COLORS.other;

            return (
              <Card key={record.id}>
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className={cn('w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0', typeColors.bg)}>
                      <GraduationCap size={20} className={typeColors.text} />
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="text-[15px] font-semibold text-main truncate">{record.courseName}</span>
                        <Badge variant={getTrainingStatusVariant(record.status)}>
                          {STATUS_LABELS[record.status] || record.status}
                        </Badge>
                      </div>
                      <div className="flex flex-wrap items-center gap-2 text-xs text-muted mt-1">
                        <span className={cn('px-1.5 py-0.5 rounded text-[11px] font-medium', typeColors.bg, typeColors.text)}>
                          {TRAINING_TYPE_LABELS[record.trainingType as TrainingType] || record.trainingType}
                        </span>
                        {record.provider && (
                          <span className="flex items-center gap-1">
                            <BookOpen size={11} />
                            {record.provider}
                          </span>
                        )}
                        {record.completedDate && (
                          <span className="flex items-center gap-1">
                            <Calendar size={11} />
                            {formatDate(record.completedDate)}
                          </span>
                        )}
                        {record.score !== null && (
                          <span>Score: {record.score}%</span>
                        )}
                      </div>
                    </div>

                    <div className="flex-shrink-0 text-right">
                      {days !== null ? (
                        <div className={cn('text-sm font-semibold',
                          days <= 0 ? 'text-red-500' : days <= 30 ? 'text-amber-500' : 'text-emerald-500'
                        )}>
                          {days <= 0 ? `${Math.abs(days)}d overdue` : `${days}d left`}
                        </div>
                      ) : record.expiresDate ? (
                        <div className="text-xs text-muted">
                          Expires {formatDate(record.expiresDate)}
                        </div>
                      ) : (
                        <div className="text-xs text-muted">No expiration</div>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Link to Certifications */}
      <Link
        href="/dashboard/certifications"
        className="flex items-center gap-2 text-sm font-medium text-accent hover:underline mt-4"
      >
        <Award size={16} />
        View My Certifications
        <ExternalLink size={12} />
      </Link>
    </div>
  );
}
