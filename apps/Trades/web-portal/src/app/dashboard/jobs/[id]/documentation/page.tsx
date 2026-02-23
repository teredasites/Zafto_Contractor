'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  FileCheck,
  CheckCircle2,
  Circle,
  AlertTriangle,
  Camera,
  FileText,
  PenTool,
  Activity,
  ClipboardList,
  ChevronDown,
  ChevronRight,
  Shield,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useDocumentationValidation,
  type DocChecklistItemData,
  type DocProgressData,
  type DocPhase,
} from '@/lib/hooks/use-documentation-validation';
import { useTranslation } from '@/lib/translations';

// ============================================================================
// CONSTANTS
// ============================================================================

const PHASE_LABELS: Record<DocPhase, string> = {
  initial_inspection: 'Initial Inspection',
  during_work: 'During Work',
  daily_monitoring: 'Daily Monitoring',
  completion: 'Completion',
  closeout: 'Closeout',
};

const PHASE_ICONS: Record<DocPhase, typeof Camera> = {
  initial_inspection: Camera,
  during_work: ClipboardList,
  daily_monitoring: Activity,
  completion: FileCheck,
  closeout: PenTool,
};

const EVIDENCE_LABELS: Record<string, string> = {
  photo: 'Photo',
  document: 'Document',
  signature: 'Signature',
  reading: 'Reading',
  form: 'Form',
  any: 'Any',
};

// ============================================================================
// PAGE
// ============================================================================

export default function JobDocumentationPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const jobId = params.id as string;

  const { checklistItems, progress, validation, coc, loading, error, markComplete, markIncomplete } = useDocumentationValidation(jobId);
  const [expandedPhases, setExpandedPhases] = useState<Set<string>>(new Set(['initial_inspection']));
  const [completing, setCompleting] = useState<string | null>(null);

  const togglePhase = (phase: string) => {
    setExpandedPhases(prev => {
      const next = new Set(prev);
      if (next.has(phase)) next.delete(phase);
      else next.add(phase);
      return next;
    });
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="skeleton h-8 w-8 rounded" />
          <div><div className="skeleton h-7 w-56 mb-2" /><div className="skeleton h-4 w-48" /></div>
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <button onClick={() => router.back()} className="flex items-center gap-2 text-muted hover:text-main">
          <ArrowLeft size={18} /><span>{t('common.backToJob')}</span>
        </button>
        <Card>
          <CardContent className="p-12 text-center">
            <AlertTriangle size={48} className="mx-auto text-red-500 mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">Failed to load documentation</h3>
            <p className="text-muted">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const progressMap = new Map(progress.map(p => [p.checklistItemId, p]));
  const complianceColor = validation.compliancePercentage >= 100
    ? 'text-emerald-600'
    : validation.compliancePercentage >= 70
    ? 'text-amber-600'
    : 'text-red-600';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('jobsDocumentation.title')}</h1>
            <p className="text-muted mt-0.5">TPA-compliant documentation checklist and tracking</p>
          </div>
        </div>
        {validation.isFullyCompliant && (
          <Badge variant="success">Fully Compliant</Badge>
        )}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <p className={cn('text-3xl font-bold', complianceColor)}>{validation.compliancePercentage}%</p>
            <p className="text-sm text-muted">{t('common.compliance')}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-3xl font-bold text-main">{validation.requiredCompleted}/{validation.requiredTotal}</p>
            <p className="text-sm text-muted">Required Items</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-3xl font-bold text-main">{validation.completedItems}/{validation.totalItems}</p>
            <p className="text-sm text-muted">All Items</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <div className="flex items-center justify-center gap-2">
              {coc ? (
                <>
                  <CheckCircle2 size={20} className="text-emerald-500" />
                  <p className="text-sm font-medium text-emerald-600">COC {coc.status === 'signed' ? 'Signed' : 'Draft'}</p>
                </>
              ) : (
                <>
                  <Circle size={20} className="text-muted" />
                  <p className="text-sm text-muted">No COC Yet</p>
                </>
              )}
            </div>
            <p className="text-sm text-muted mt-1">Certificate</p>
          </CardContent>
        </Card>
      </div>

      {/* Compliance Progress Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-main">Overall Compliance</span>
            <span className={cn('text-sm font-bold', complianceColor)}>{validation.compliancePercentage}%</span>
          </div>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
            <div
              className={cn(
                'h-3 rounded-full transition-all duration-500',
                validation.compliancePercentage >= 100 ? 'bg-emerald-500' :
                validation.compliancePercentage >= 70 ? 'bg-amber-500' : 'bg-red-500'
              )}
              style={{ width: `${Math.min(validation.compliancePercentage, 100)}%` }}
            />
          </div>
          <div className="flex justify-between mt-2">
            {validation.phases.map(phase => (
              <div key={phase.phase} className="text-center">
                <p className={cn(
                  'text-xs font-medium',
                  phase.percentage >= 100 ? 'text-emerald-600' : phase.percentage > 0 ? 'text-amber-600' : 'text-muted'
                )}>
                  {phase.percentage}%
                </p>
                <p className="text-[10px] text-muted">{PHASE_LABELS[phase.phase]}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Phase Checklists */}
      {checklistItems.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Shield size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No checklist template found</h3>
            <p className="text-muted">No documentation checklist is configured for this job type.</p>
          </CardContent>
        </Card>
      ) : (
        (['initial_inspection', 'during_work', 'daily_monitoring', 'completion', 'closeout'] as DocPhase[]).map(phase => {
          const phaseItems = checklistItems.filter(i => i.phase === phase);
          if (phaseItems.length === 0) return null;
          const phaseProgress = validation.phases.find(p => p.phase === phase);
          const isExpanded = expandedPhases.has(phase);
          const PhaseIcon = PHASE_ICONS[phase];

          return (
            <Card key={phase}>
              <button
                className="w-full p-4 flex items-center justify-between text-left"
                onClick={() => togglePhase(phase)}
              >
                <div className="flex items-center gap-3">
                  <div className={cn(
                    'p-2 rounded-lg',
                    phaseProgress?.percentage === 100
                      ? 'bg-emerald-100 dark:bg-emerald-900/30'
                      : 'bg-surface-hover'
                  )}>
                    <PhaseIcon size={18} className={
                      phaseProgress?.percentage === 100 ? 'text-emerald-600 dark:text-emerald-400' : 'text-muted'
                    } />
                  </div>
                  <div>
                    <span className="font-medium text-main">{PHASE_LABELS[phase]}</span>
                    <span className="text-sm text-muted ml-3">
                      {phaseProgress?.requiredCompleted}/{phaseProgress?.requiredItems} required
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  {phaseProgress?.percentage === 100 && (
                    <CheckCircle2 size={18} className="text-emerald-500" />
                  )}
                  {isExpanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                </div>
              </button>
              {isExpanded && (
                <CardContent className="pt-0 px-4 pb-4">
                  <div className="border-t border-main pt-3 space-y-1">
                    {phaseItems.map(item => {
                      const prog = progressMap.get(item.id);
                      const isComplete = prog?.isComplete && (prog.evidenceCount >= item.minCount);
                      return (
                        <div
                          key={item.id}
                          className={cn(
                            'flex items-start gap-3 py-2.5 px-3 rounded-lg transition-colors',
                            isComplete ? 'bg-emerald-50 dark:bg-emerald-900/10' : 'hover:bg-surface-hover'
                          )}
                        >
                          <button
                            className="mt-0.5 flex-shrink-0"
                            disabled={completing === item.id}
                            onClick={async () => {
                              setCompleting(item.id);
                              try {
                                if (isComplete) {
                                  await markIncomplete(item.id);
                                } else {
                                  await markComplete(item.id);
                                }
                              } finally {
                                setCompleting(null);
                              }
                            }}
                          >
                            {isComplete ? (
                              <CheckCircle2 size={18} className="text-emerald-500" />
                            ) : (
                              <Circle size={18} className="text-muted" />
                            )}
                          </button>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className={cn(
                                'text-sm font-medium',
                                isComplete ? 'text-emerald-700 dark:text-emerald-300 line-through' : 'text-main'
                              )}>
                                {item.itemName}
                              </span>
                              {item.isRequired && (
                                <Badge variant="error" className="text-[10px] px-1.5 py-0">{t('common.required')}</Badge>
                              )}
                              <Badge variant="secondary" className="text-[10px] px-1.5 py-0">
                                {EVIDENCE_LABELS[item.evidenceType]} x{item.minCount}
                              </Badge>
                            </div>
                            {item.description && (
                              <p className="text-xs text-muted mt-0.5">{item.description}</p>
                            )}
                            {prog && prog.evidenceCount > 0 && (
                              <p className="text-xs text-emerald-600 mt-0.5">
                                {prog.evidenceCount} evidence item(s) uploaded
                              </p>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </CardContent>
              )}
            </Card>
          );
        })
      )}
    </div>
  );
}
