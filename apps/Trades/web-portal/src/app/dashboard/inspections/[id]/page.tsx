'use client';

import { useState, useEffect, useCallback, use } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  ClipboardCheck,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Calendar,
  User,
  MapPin,
  Camera,
  FileText,
  BarChart3,
  Clock,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatDate, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { mapInspection } from '@/lib/hooks/mappers';
import type { InspectionData } from '@/lib/hooks/mappers';
import { useTranslation } from '@/lib/translations';

export default function InspectionDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { t } = useTranslation();
  const { id } = use(params);
  const router = useRouter();
  const [inspection, setInspection] = useState<InspectionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInspection = useCallback(async () => {
    try {
      setLoading(true);
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('compliance_records')
        .select('*, jobs(title, customer_name, address, city, state)')
        .eq('id', id)
        .single();

      if (err) throw err;
      setInspection(mapInspection(data));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load inspection');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchInspection();
  }, [fetchInspection]);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="skeleton h-7 w-64 mb-2" />
        <div className="grid grid-cols-2 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-5 w-32" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl p-6"><div className="skeleton h-4 w-24 mb-4" />{[...Array(5)].map((_, i) => <div key={i} className="skeleton h-8 w-full mb-2" />)}</div>
      </div>
    );
  }

  if (error || !inspection) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => router.back()}><ArrowLeft size={16} />{t('common.back')}</Button>
        <Card><CardContent className="p-12 text-center">
          <AlertTriangle size={48} className="mx-auto text-red-500 mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">{t('inspections.inspectionNotFound')}</h3>
          <p className="text-muted">{error || 'The requested inspection does not exist.'}</p>
        </CardContent></Card>
      </div>
    );
  }

  const completedItems = inspection.checklist.filter(c => c.completed).length;
  const totalItems = inspection.checklist.length;
  const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;
  const passedItems = inspection.checklist.filter(c => c.completed).length;
  const failedItems = totalItems - passedItems;

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => router.back()}><ArrowLeft size={16} /></Button>
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-main">{inspection.title}</h1>
          <p className="text-muted mt-1">{inspection.jobName} — {inspection.address}</p>
        </div>
        <StatusBadge status={inspection.status} />
      </div>

      {/* Info grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.assignedTo')}</p>
          <div className="flex items-center gap-2"><User size={14} className="text-muted" /><span className="font-medium text-main">{inspection.assignedTo}</span></div>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.scheduled')}</p>
          <div className="flex items-center gap-2"><Calendar size={14} className="text-muted" /><span className="font-medium text-main">{formatDate(inspection.scheduledDate)}</span></div>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.score')}</p>
          <div className="flex items-center gap-2"><BarChart3 size={14} className="text-muted" /><span className="font-medium text-main">{inspection.overallScore !== undefined ? `${inspection.overallScore}%` : '—'}</span></div>
        </CardContent></Card>
        <Card><CardContent className="p-4">
          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.photos')}</p>
          <div className="flex items-center gap-2"><Camera size={14} className="text-muted" /><span className="font-medium text-main">{inspection.photos}</span></div>
        </CardContent></Card>
      </div>

      {/* Progress */}
      <Card>
        <CardHeader><CardTitle className="text-base">{t('common.progress')}</CardTitle></CardHeader>
        <CardContent>
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-main">{completedItems} / {totalItems} items completed</span>
            <span className="text-sm font-semibold text-main">{progress}%</span>
          </div>
          <div className="w-full h-3 bg-secondary rounded-full overflow-hidden">
            <div className={cn('h-full rounded-full transition-all', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-gray-300')} style={{ width: `${progress}%` }} />
          </div>
          <div className="flex items-center gap-6 mt-4 text-sm">
            <span className="flex items-center gap-1.5"><CheckCircle size={14} className="text-emerald-500" />{passedItems} passed</span>
            <span className="flex items-center gap-1.5"><XCircle size={14} className="text-red-500" />{failedItems} remaining</span>
          </div>
        </CardContent>
      </Card>

      {/* Checklist */}
      <Card>
        <CardHeader><CardTitle className="text-base">{t('common.checklistItems')}</CardTitle></CardHeader>
        <CardContent>
          <div className="space-y-2">
            {inspection.checklist.map(item => (
              <div key={item.id} className={cn('flex items-start gap-3 p-3 rounded-lg border', item.completed ? 'bg-emerald-50/50 dark:bg-emerald-900/5 border-emerald-200 dark:border-emerald-800/30' : 'bg-surface border-main')}>
                <div className="mt-0.5">{item.completed ? <CheckCircle size={18} className="text-emerald-500" /> : <div className="w-[18px] h-[18px] border-2 border-main rounded" />}</div>
                <div className="flex-1">
                  <p className="text-sm text-main">{item.label}</p>
                  {item.note && <p className="text-xs text-muted mt-1">{item.note}</p>}
                  {item.photoRequired && (
                    <span className={cn('text-xs flex items-center gap-1 mt-1', item.hasPhoto ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400')}>
                      <Camera size={12} />{item.hasPhoto ? 'Photo attached' : 'Photo required'}
                    </span>
                  )}
                </div>
              </div>
            ))}

            {inspection.checklist.length === 0 && (
              <p className="text-center text-muted py-6">{t('inspections.noChecklistItemsRecorded')}</p>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Notes */}
      {inspection.notes && (
        <Card>
          <CardHeader><CardTitle className="text-base">{t('common.notes')}</CardTitle></CardHeader>
          <CardContent><p className="text-sm text-main">{inspection.notes}</p></CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex items-center gap-3">
        <Button variant="secondary"><FileText size={16} />{t('common.generateReport')}</Button>
        {inspection.status !== 'passed' && <Button><CheckCircle size={16} />{t('common.markPassed')}</Button>}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const config: Record<string, { label: string; color: string; bg: string }> = {
    scheduled: { label: 'Scheduled', color: 'text-blue-700 dark:text-blue-300', bg: 'bg-blue-100 dark:bg-blue-900/30' },
    in_progress: { label: 'In Progress', color: 'text-amber-700 dark:text-amber-300', bg: 'bg-amber-100 dark:bg-amber-900/30' },
    passed: { label: 'Passed', color: 'text-emerald-700 dark:text-emerald-300', bg: 'bg-emerald-100 dark:bg-emerald-900/30' },
    failed: { label: 'Failed', color: 'text-red-700 dark:text-red-300', bg: 'bg-red-100 dark:bg-red-900/30' },
    partial: { label: 'Partial', color: 'text-purple-700 dark:text-purple-300', bg: 'bg-purple-100 dark:bg-purple-900/30' },
  };
  const c = config[status] || config.scheduled;
  return <span className={cn('px-3 py-1 rounded-full text-xs font-medium', c.bg, c.color)}>{c.label}</span>;
}
