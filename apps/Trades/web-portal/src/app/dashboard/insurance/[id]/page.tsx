'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  Shield, ArrowLeft, Building2, Calendar, DollarSign, User, Phone, Mail,
  FileText, Droplets, ThermometerSun, Wrench, ClipboardCheck, ChevronRight,
  AlertTriangle, Plus, Send, Trash2, Check, CheckCircle, XCircle, Award, Camera, PenTool, Clock,
  CloudLightning, HardHat,
  type LucideIcon,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useClaim, updateClaimStatus, createSupplement, updateSupplementStatus, deleteSupplement } from '@/lib/hooks/use-insurance';
import type { SupplementReason } from '@/types';
import { CLAIM_STATUS_LABELS, CLAIM_STATUS_COLORS, LOSS_TYPE_LABELS, EQUIPMENT_TYPE_LABELS, CLAIM_CATEGORY_LABELS, CLAIM_CATEGORY_COLORS } from '@/lib/hooks/mappers';
import type { ClaimStatus, InsuranceClaimData, MoistureReadingData, DryingLogData, RestorationEquipmentData, TpiInspectionData, StormClaimData, ReconstructionClaimData, CommercialClaimData } from '@/types';
import { useTranslation } from '@/lib/translations';

type TabId = 'overview' | 'supplements' | 'tpi' | 'moisture' | 'drying' | 'equipment' | 'completion';

const TABS: { id: TabId; label: string; icon: LucideIcon }[] = [
  { id: 'overview', label: 'Overview', icon: Shield },
  { id: 'supplements', label: 'Supplements', icon: FileText },
  { id: 'tpi', label: 'TPI', icon: ClipboardCheck },
  { id: 'moisture', label: 'Moisture', icon: Droplets },
  { id: 'drying', label: 'Drying Log', icon: ThermometerSun },
  { id: 'equipment', label: 'Equipment', icon: Wrench },
  { id: 'completion', label: 'Completion', icon: Award },
];

// Status transitions: current → allowed next statuses
const STATUS_TRANSITIONS: Partial<Record<ClaimStatus, { label: string; status: ClaimStatus }[]>> = {
  new: [{ label: 'Request Scope', status: 'scope_requested' }],
  scope_requested: [{ label: 'Mark Scope Submitted', status: 'scope_submitted' }],
  scope_submitted: [{ label: 'Estimate Pending', status: 'estimate_pending' }],
  estimate_pending: [{ label: 'Approve Estimate', status: 'estimate_approved' }],
  estimate_approved: [{ label: 'Start Work', status: 'work_in_progress' }],
  supplement_submitted: [{ label: 'Approve Supplement', status: 'supplement_approved' }],
  supplement_approved: [{ label: 'Continue Work', status: 'work_in_progress' }],
  work_in_progress: [
    { label: 'Submit Supplement', status: 'supplement_submitted' },
    { label: 'Mark Complete', status: 'work_complete' },
  ],
  work_complete: [{ label: 'Final Inspection', status: 'final_inspection' }],
  final_inspection: [{ label: 'Settle Claim', status: 'settled' }],
  settled: [{ label: 'Close Claim', status: 'closed' }],
};

export default function ClaimDetailPage() {
  const { t, formatDate } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const claimId = params.id as string;
  const { claim, supplements, tpiInspections, moistureReadings, dryingLogs, equipment, loading, error, refetch } = useClaim(claimId);
  const [activeTab, setActiveTab] = useState<TabId>('overview');
  const [transitioning, setTransitioning] = useState(false);

  const handleStatusTransition = async (newStatus: ClaimStatus) => {
    setTransitioning(true);
    try {
      await updateClaimStatus(claimId, newStatus);
      refetch();
    } catch {
      // Error handled silently — real-time will update
    } finally {
      setTransitioning(false);
    }
  };

  const handleDeny = async () => {
    if (!confirm('Are you sure you want to deny this claim?')) return;
    await handleStatusTransition('denied');
  };

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="h-8 w-64 rounded-lg bg-muted animate-pulse" />
        <div className="h-48 rounded-xl bg-muted animate-pulse" />
        <div className="h-96 rounded-xl bg-muted animate-pulse" />
      </div>
    );
  }

  if (error || !claim) {
    return (
      <div className="flex flex-col items-center justify-center py-20">
        <AlertTriangle className="w-8 h-8 text-red-500 mb-3" />
        <p className="text-sm font-medium">Claim not found</p>
        <button onClick={() => router.back()} className="text-sm text-amber-500 mt-2 hover:underline">Go back</button>
      </div>
    );
  }

  const transitions = STATUS_TRANSITIONS[claim.claimStatus] || [];
  const netPayable = (claim.approvedAmount || 0) + claim.supplementTotal - claim.deductible - claim.depreciation;

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push('/dashboard/insurance')} className="p-1.5 rounded-lg hover:bg-muted transition-colors">
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-amber-500" />
              <h1 className="text-xl font-semibold">{claim.job?.title || 'Insurance Claim'}</h1>
              <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${CLAIM_STATUS_COLORS[claim.claimStatus]}`}>
                {CLAIM_STATUS_LABELS[claim.claimStatus]}
              </span>
              {claim.claimCategory !== 'restoration' && (
                <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-medium ${CLAIM_CATEGORY_COLORS[claim.claimCategory]}`}>
                  {CLAIM_CATEGORY_LABELS[claim.claimCategory]}
                </span>
              )}
            </div>
            <p className="text-sm text-muted-foreground mt-0.5">
              {claim.claimNumber} &middot; {claim.insuranceCompany} &middot; {LOSS_TYPE_LABELS[claim.lossType] || claim.lossType}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {claim.claimStatus !== 'denied' && claim.claimStatus !== 'closed' && (
            <button
              onClick={handleDeny}
              disabled={transitioning}
              className="px-3 py-1.5 rounded-lg text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
            >
              Deny
            </button>
          )}
          {transitions.map((t) => (
            <button
              key={t.status}
              onClick={() => handleStatusTransition(t.status)}
              disabled={transitioning}
              className="px-4 py-1.5 rounded-lg bg-amber-500 text-white text-sm font-medium hover:bg-amber-600 transition-colors disabled:opacity-50"
            >
              {t.label}
            </button>
          ))}
          <button
            onClick={() => router.push(`/dashboard/jobs/${claim.jobId}`)}
            className="px-3 py-1.5 rounded-lg text-sm font-medium border border-border hover:bg-muted transition-colors"
          >
            View Job
          </button>
        </div>
      </div>

      {/* Main Content: Tabs + Content + Sidebar */}
      <div className="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6">
        {/* Left: Tabs + Content */}
        <div className="space-y-4">
          {/* Tabs */}
          <div className="flex items-center gap-1 border-b border-border pb-px overflow-x-auto">
            {TABS.map((tab) => {
              const Icon = tab.icon;
              const completionPassed = tab.id === 'completion' ? [
                moistureReadings.length > 0 && moistureReadings.every(r => r.isDry),
                equipment.length === 0 || equipment.every(e => e.status !== 'deployed' && e.status !== 'maintenance'),
                dryingLogs.some(d => d.logType === 'completion'),
                tpiInspections.some(t => t.inspectionType === 'final' && t.status === 'completed' && t.result === 'passed'),
              ].filter(Boolean).length : 0;
              const count = tab.id === 'supplements' ? supplements.length
                : tab.id === 'tpi' ? tpiInspections.length
                : tab.id === 'moisture' ? moistureReadings.length
                : tab.id === 'drying' ? dryingLogs.length
                : tab.id === 'equipment' ? equipment.length
                : tab.id === 'completion' ? completionPassed : 0;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-1.5 px-3 py-2 text-sm font-medium border-b-2 transition-colors whitespace-nowrap ${
                    activeTab === tab.id
                      ? 'border-amber-500 text-foreground'
                      : 'border-transparent text-muted-foreground hover:text-foreground'
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  {tab.label}
                  {tab.id === 'completion' && (
                    <span className={`ml-1 px-1.5 py-0.5 rounded-full text-[10px] ${
                      completionPassed === 4 ? 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400' : 'bg-muted'
                    }`}>{completionPassed}/4</span>
                  )}
                  {tab.id !== 'overview' && tab.id !== 'completion' && count > 0 && (
                    <span className="ml-1 px-1.5 py-0.5 rounded-full bg-muted text-[10px]">{count}</span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Tab Content */}
          <div className="min-h-[400px]">
            {activeTab === 'overview' && (
              <div className="space-y-4">
                {/* Loss Details */}
                <div className="rounded-xl border border-border bg-card p-5">
                  <h3 className="text-[15px] font-semibold mb-3">Loss Details</h3>
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <DetailRow label="Category" value={CLAIM_CATEGORY_LABELS[claim.claimCategory]} />
                    <DetailRow label="Loss Type" value={LOSS_TYPE_LABELS[claim.lossType] || claim.lossType} />
                    <DetailRow label="Date of Loss" value={formatDate(claim.dateOfLoss)} />
                    {claim.lossDescription && <DetailRow label="Description" value={claim.lossDescription} className="col-span-2" />}
                  </div>
                </div>

                {/* Category-specific data */}
                {claim.claimCategory !== 'restoration' && Object.keys(claim.data).length > 0 && (
                  <CategoryDataCard claim={claim} />
                )}

                {/* Financials */}
                <div className="rounded-xl border border-border bg-card p-5">
                  <h3 className="text-[15px] font-semibold mb-3">Financials</h3>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                    <FinancialCard label="Approved" value={claim.approvedAmount} />
                    <FinancialCard label="Supplements" value={claim.supplementTotal} />
                    <FinancialCard label="Deductible" value={claim.deductible} negative />
                    <FinancialCard label="Depreciation" value={claim.depreciation} negative />
                    <FinancialCard label="ACV" value={claim.acv} />
                    <FinancialCard label="RCV" value={claim.rcv} />
                  </div>
                  <div className="mt-3 pt-3 border-t border-border flex items-center justify-between">
                    <span className="text-sm font-medium">Net Payable</span>
                    <span className={`text-lg font-semibold ${netPayable >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      ${netPayable.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>

                {/* Xactimate */}
                {(claim.xactimateClaimId || claim.xactimateFileUrl) && (
                  <div className="rounded-xl border border-border bg-card p-5">
                    <h3 className="text-[15px] font-semibold mb-3">Xactimate</h3>
                    <div className="grid grid-cols-2 gap-3 text-sm">
                      {claim.xactimateClaimId && <DetailRow label="Claim ID" value={claim.xactimateClaimId} />}
                      {claim.xactimateFileUrl && <DetailRow label="File URL" value={claim.xactimateFileUrl} />}
                    </div>
                  </div>
                )}

                {/* Notes */}
                {claim.notes && (
                  <div className="rounded-xl border border-border bg-card p-5">
                    <h3 className="text-[15px] font-semibold mb-2">{t('common.notes')}</h3>
                    <p className="text-sm text-muted-foreground whitespace-pre-wrap">{claim.notes}</p>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'supplements' && (
              <SupplementsTab
                claimId={claimId}
                supplements={supplements}
                onRefresh={refetch}
              />
            )}

            {activeTab === 'tpi' && (
              <div className="space-y-3">
                {tpiInspections.length === 0 && <EmptyTab icon={ClipboardCheck} label="No inspections scheduled" />}
                {tpiInspections.map((t) => (
                  <div key={t.id} className="rounded-xl border border-border bg-card p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium capitalize">{t.inspectionType.replace('_', ' ')} Inspection</span>
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${
                          t.status === 'completed' ? 'bg-green-100 text-green-700' :
                          t.status === 'cancelled' ? 'bg-red-100 text-red-700' :
                          'bg-blue-100 text-blue-700'
                        }`}>{t.status.replace('_', ' ')}</span>
                      </div>
                      {t.result && (
                        <span className={`text-xs font-medium ${t.result === 'passed' ? 'text-green-600' : t.result === 'failed' ? 'text-red-600' : 'text-yellow-600'}`}>
                          {t.result}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-4 text-xs text-muted-foreground">
                      {t.inspectorName && <span>{t.inspectorName}</span>}
                      {t.inspectorCompany && <span>{t.inspectorCompany}</span>}
                      {t.scheduledDate && <span>Scheduled: {formatDate(t.scheduledDate)}</span>}
                    </div>
                    {t.findings && <p className="text-xs text-muted-foreground mt-2">{t.findings}</p>}
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'moisture' && (
              <div className="space-y-3">
                {moistureReadings.length === 0 && <EmptyTab icon={Droplets} label="No moisture readings recorded" />}
                {moistureReadings.length > 0 && (
                  <div className="rounded-xl border border-border bg-card overflow-hidden">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-border bg-muted/50">
                          <th className="text-left px-4 py-2 font-medium text-xs">{t('common.area')}</th>
                          <th className="text-left px-4 py-2 font-medium text-xs">{t('common.material')}</th>
                          <th className="text-right px-4 py-2 font-medium text-xs">{t('common.reading')}</th>
                          <th className="text-right px-4 py-2 font-medium text-xs">{t('common.target')}</th>
                          <th className="text-center px-4 py-2 font-medium text-xs">{t('common.status')}</th>
                          <th className="text-right px-4 py-2 font-medium text-xs">{t('common.date')}</th>
                        </tr>
                      </thead>
                      <tbody>
                        {moistureReadings.map((r) => (
                          <tr key={r.id} className="border-b border-border last:border-0">
                            <td className="px-4 py-2 font-medium">{r.areaName}</td>
                            <td className="px-4 py-2 text-muted-foreground capitalize">{r.materialType.replace('_', ' ')}</td>
                            <td className="px-4 py-2 text-right font-mono">{r.readingValue}%</td>
                            <td className="px-4 py-2 text-right font-mono text-muted-foreground">{r.targetValue || '—'}%</td>
                            <td className="px-4 py-2 text-center">
                              <span className={`inline-block w-2 h-2 rounded-full ${r.isDry ? 'bg-green-500' : 'bg-red-500'}`} />
                            </td>
                            <td className="px-4 py-2 text-right text-muted-foreground">{formatDate(r.recordedAt)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'drying' && (
              <div className="space-y-3">
                {dryingLogs.length === 0 && <EmptyTab icon={ThermometerSun} label="No drying logs recorded" />}
                {dryingLogs.map((d) => (
                  <div key={d.id} className="rounded-xl border border-border bg-card p-4">
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${
                          d.logType === 'completion' ? 'bg-green-100 text-green-700' :
                          d.logType === 'setup' ? 'bg-blue-100 text-blue-700' :
                          'bg-gray-100 text-gray-700'
                        }`}>{d.logType.replace('_', ' ')}</span>
                        <span className="text-sm font-medium">{d.summary}</span>
                      </div>
                      <span className="text-xs text-muted-foreground">{new Date(d.recordedAt).toLocaleString()}</span>
                    </div>
                    {d.details && <p className="text-xs text-muted-foreground mb-2">{d.details}</p>}
                    <div className="flex items-center gap-4 text-xs text-muted-foreground">
                      {d.dehumidifiersRunning > 0 && <span>Dehus: {d.dehumidifiersRunning}</span>}
                      {d.airMoversRunning > 0 && <span>Air Movers: {d.airMoversRunning}</span>}
                      {d.airScrubbersRunning > 0 && <span>Scrubbers: {d.airScrubbersRunning}</span>}
                      {d.indoorTempF != null && <span>Indoor: {d.indoorTempF}°F / {d.indoorHumidity}% RH</span>}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'equipment' && (
              <div className="space-y-3">
                {equipment.length === 0 && <EmptyTab icon={Wrench} label="No equipment deployed" />}
                {equipment.map((e) => {
                  const days = e.totalDays || Math.max(1, Math.ceil((Date.now() - new Date(e.deployedAt).getTime()) / 86400000));
                  const totalCost = e.dailyRate * days;
                  return (
                    <div key={e.id} className="rounded-xl border border-border bg-card p-4">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <Wrench className="w-3.5 h-3.5 text-muted-foreground" />
                          <span className="text-sm font-medium">{EQUIPMENT_TYPE_LABELS[e.equipmentType] || e.equipmentType}</span>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium ${
                            e.status === 'deployed' ? 'bg-green-100 text-green-700' :
                            e.status === 'removed' ? 'bg-gray-100 text-gray-500' :
                            'bg-yellow-100 text-yellow-700'
                          }`}>{e.status}</span>
                        </div>
                        <span className="text-sm font-medium">${totalCost.toLocaleString()}</span>
                      </div>
                      <div className="flex items-center gap-4 text-xs text-muted-foreground">
                        <span>Area: {e.areaDeployed}</span>
                        {e.make && <span>{e.make} {e.model || ''}</span>}
                        <span>${e.dailyRate}/day &times; {days} days</span>
                        <span>Deployed: {formatDate(e.deployedAt)}</span>
                        {e.removedAt && <span>Removed: {formatDate(e.removedAt)}</span>}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {activeTab === 'completion' && (
              <CompletionTab
                claim={claim}
                moistureReadings={moistureReadings}
                equipment={equipment}
                dryingLogs={dryingLogs}
                tpiInspections={tpiInspections}
                onTransition={handleStatusTransition}
                transitioning={transitioning}
              />
            )}
          </div>
        </div>

        {/* Right Sidebar */}
        <div className="space-y-4">
          {/* Claim Info */}
          <div className="rounded-xl border border-border bg-card p-5">
            <h3 className="text-[15px] font-semibold mb-3">Claim Info</h3>
            <div className="space-y-2.5 text-sm">
              <DetailRow label="Claim #" value={claim.claimNumber} />
              <DetailRow label="Carrier" value={claim.insuranceCompany} />
              {claim.policyNumber && <DetailRow label="Policy #" value={claim.policyNumber} />}
              <DetailRow label="Loss Type" value={LOSS_TYPE_LABELS[claim.lossType] || claim.lossType} />
              <DetailRow label="Date of Loss" value={formatDate(claim.dateOfLoss)} />
              {claim.coverageLimit != null && <DetailRow label="Coverage Limit" value={`$${claim.coverageLimit.toLocaleString()}`} />}
            </div>
          </div>

          {/* Adjuster */}
          {claim.adjusterName && (
            <div className="rounded-xl border border-border bg-card p-5">
              <h3 className="text-[15px] font-semibold mb-3">{t('common.adjuster')}</h3>
              <div className="space-y-2.5 text-sm">
                <div className="flex items-center gap-2">
                  <User className="w-3.5 h-3.5 text-muted-foreground" />
                  <span>{claim.adjusterName}</span>
                </div>
                {claim.adjusterCompany && (
                  <div className="flex items-center gap-2">
                    <Building2 className="w-3.5 h-3.5 text-muted-foreground" />
                    <span>{claim.adjusterCompany}</span>
                  </div>
                )}
                {claim.adjusterPhone && (
                  <div className="flex items-center gap-2">
                    <Phone className="w-3.5 h-3.5 text-muted-foreground" />
                    <a href={`tel:${claim.adjusterPhone}`} className="text-amber-600 hover:underline">{claim.adjusterPhone}</a>
                  </div>
                )}
                {claim.adjusterEmail && (
                  <div className="flex items-center gap-2">
                    <Mail className="w-3.5 h-3.5 text-muted-foreground" />
                    <a href={`mailto:${claim.adjusterEmail}`} className="text-amber-600 hover:underline">{claim.adjusterEmail}</a>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Timeline */}
          <div className="rounded-xl border border-border bg-card p-5">
            <h3 className="text-[15px] font-semibold mb-3">{t('common.timeline')}</h3>
            <div className="space-y-2 text-xs">
              <TimelineRow label="Created" date={claim.createdAt} />
              {claim.scopeSubmittedAt && <TimelineRow label="Scope Submitted" date={claim.scopeSubmittedAt} />}
              {claim.estimateApprovedAt && <TimelineRow label="Estimate Approved" date={claim.estimateApprovedAt} />}
              {claim.workStartedAt && <TimelineRow label="Work Started" date={claim.workStartedAt} />}
              {claim.workCompletedAt && <TimelineRow label="Work Completed" date={claim.workCompletedAt} />}
              {claim.settledAt && <TimelineRow label="Settled" date={claim.settledAt} />}
            </div>
          </div>

          {/* Quick Stats */}
          <div className="rounded-xl border border-border bg-card p-5">
            <h3 className="text-[15px] font-semibold mb-3">{t('common.summary')}</h3>
            <div className="grid grid-cols-2 gap-3">
              <StatCard label="Supplements" value={supplements.length.toString()} />
              <StatCard label="Inspections" value={tpiInspections.length.toString()} />
              <StatCard label="Readings" value={moistureReadings.length.toString()} />
              <StatCard label="Equipment" value={equipment.filter(e => e.status === 'deployed').length.toString()} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function DetailRow({ label, value, className = '' }: { label: string; value: React.ReactNode; className?: string }) {
  return (
    <div className={`flex items-start gap-2 ${className}`}>
      <span className="text-muted-foreground w-28 flex-shrink-0">{label}</span>
      <span className="font-medium">{value}</span>
    </div>
  );
}

function FinancialCard({ label, value, negative }: { label: string; value?: number; negative?: boolean }) {
  return (
    <div className="p-3 rounded-lg bg-muted/50">
      <p className="text-[10px] text-muted-foreground uppercase tracking-wide">{label}</p>
      <p className={`text-sm font-semibold mt-0.5 ${value == null ? 'text-muted-foreground' : negative ? 'text-red-600' : ''}`}>
        {value != null ? `${negative ? '-' : ''}$${Math.abs(value).toLocaleString()}` : '—'}
      </p>
    </div>
  );
}

function TimelineRow({ label, date }: { label: string; date: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium">{new Date(date).toLocaleDateString()}</span>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="p-2.5 rounded-lg bg-muted/50 text-center">
      <p className="text-lg font-semibold">{value}</p>
      <p className="text-[10px] text-muted-foreground">{label}</p>
    </div>
  );
}

function EmptyTab({ icon: Icon, label }: { icon: LucideIcon; label: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center mb-3">
        <Icon className="w-5 h-5 text-muted-foreground" />
      </div>
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  );
}

// ==================== CATEGORY DATA CARD ====================

const STORM_SEVERITY_COLORS: Record<string, string> = {
  minor: 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400',
  moderate: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400',
  severe: 'bg-orange-100 text-orange-700 dark:bg-orange-900/40 dark:text-orange-400',
  catastrophic: 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400',
};

function CategoryDataCard({ claim }: { claim: InsuranceClaimData }) {
  const Icon = claim.claimCategory === 'storm' ? CloudLightning
    : claim.claimCategory === 'reconstruction' ? HardHat
    : Building2;
  const borderColor = claim.claimCategory === 'storm' ? 'border-purple-500/30'
    : claim.claimCategory === 'reconstruction' ? 'border-orange-500/30'
    : 'border-emerald-500/30';
  const title = claim.claimCategory === 'storm' ? 'Storm Details'
    : claim.claimCategory === 'reconstruction' ? 'Reconstruction Details'
    : 'Commercial Details';

  const d = claim.data as Record<string, unknown>;

  return (
    <div className={`rounded-xl border ${borderColor} bg-card p-5`}>
      <div className="flex items-center gap-2 mb-3">
        <Icon className="w-4 h-4 text-muted-foreground" />
        <h3 className="text-[15px] font-semibold">{title}</h3>
      </div>
      <div className="grid grid-cols-2 gap-3 text-sm">
        {claim.claimCategory === 'storm' && <StormDetails data={d as unknown as StormClaimData} />}
        {claim.claimCategory === 'reconstruction' && <ReconDetails data={d as unknown as ReconstructionClaimData} />}
        {claim.claimCategory === 'commercial' && <CommercialDetails data={d as unknown as CommercialClaimData} />}
      </div>
    </div>
  );
}

function StormDetails({ data }: { data: StormClaimData }) {
  return (
    <>
      <DetailRow label="Severity" value={
        <span className={`inline-flex px-2 py-0.5 rounded-full text-[10px] font-medium ${STORM_SEVERITY_COLORS[data.stormSeverity] || ''}`}>
          {(data.stormSeverity || 'moderate').charAt(0).toUpperCase() + (data.stormSeverity || 'moderate').slice(1)}
        </span>
      } />
      {data.weatherEventType && <DetailRow label="Event Type" value={data.weatherEventType.replace(/_/g, ' ')} />}
      {data.emergencyTarped && <DetailRow label="Emergency Tarped" value="Yes" />}
      {data.aerialAssessmentNeeded && <DetailRow label="Aerial Assessment" value="Needed" />}
      {data.temporaryRepairs && <DetailRow label="Temp Repairs" value={data.temporaryRepairs} className="col-span-2" />}
    </>
  );
}

const RECON_STAGES = [
  { key: 'scope_review', label: 'Scope Review' },
  { key: 'selections', label: 'Selections' },
  { key: 'materials', label: 'Materials' },
  { key: 'demo', label: 'Demo' },
  { key: 'rough_in', label: 'Rough-In' },
  { key: 'inspection', label: 'Inspection' },
  { key: 'finish', label: 'Finish' },
  { key: 'walkthrough', label: 'Walkthrough' },
  { key: 'supplements', label: 'Supplements' },
  { key: 'payment', label: 'Payment' },
] as const;

function ReconDetails({ data }: { data: ReconstructionClaimData }) {
  const currentIdx = RECON_STAGES.findIndex(s => s.key === (data.currentPhase || 'scope_review'));
  return (
    <>
      <div className="col-span-2 mb-1">
        <p className="text-[11px] text-muted-foreground mb-2 font-medium">Workflow</p>
        <div className="flex items-start gap-0 overflow-x-auto pb-1">
          {RECON_STAGES.map((stage, i) => {
            const isComplete = currentIdx >= 0 && i < currentIdx;
            const isCurrent = i === currentIdx;
            return (
              <div key={stage.key} className="flex items-center">
                <div className="flex flex-col items-center min-w-[52px]">
                  <div className={cn(
                    'w-4 h-4 rounded-full border-[1.5px] flex items-center justify-center',
                    isCurrent ? 'border-orange-500 bg-orange-500' :
                    isComplete ? 'border-orange-500/50 bg-orange-500/20' :
                    'border-border bg-transparent'
                  )}>
                    {isComplete && <Check size={9} className="text-orange-600 dark:text-orange-400" />}
                    {isCurrent && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                  </div>
                  <span className={cn(
                    'text-[9px] mt-1 text-center leading-tight',
                    isCurrent ? 'text-orange-600 dark:text-orange-400 font-semibold' : 'text-muted-foreground'
                  )}>{stage.label}</span>
                </div>
                {i < RECON_STAGES.length - 1 && (
                  <div className={cn('w-3 h-[1.5px] -mt-3', isComplete ? 'bg-orange-500/40' : 'bg-border')} />
                )}
              </div>
            );
          })}
        </div>
      </div>
      {data.expectedDurationMonths && <DetailRow label="Duration" value={`${data.expectedDurationMonths} months`} />}
      {data.permitsRequired && <DetailRow label="Permits" value={data.permitStatus ? data.permitStatus.replace(/_/g, ' ') : 'Required'} />}
      {data.multiContractor && <DetailRow label="Contractors" value="Multi-contractor" />}
    </>
  );
}

function CommercialDetails({ data }: { data: CommercialClaimData }) {
  return (
    <>
      {data.propertyType && <DetailRow label="Property Type" value={data.propertyType.replace(/_/g, ' ')} />}
      {data.businessName && <DetailRow label="Business" value={data.businessName} />}
      {data.tenantName && <DetailRow label="Tenant" value={data.tenantName} />}
      {data.tenantContact && <DetailRow label="Tenant Contact" value={data.tenantContact} />}
      {data.businessIncomeLoss != null && <DetailRow label="Income Loss" value={`$${Number(data.businessIncomeLoss).toLocaleString()}`} />}
      {data.businessInterruptionDays != null && <DetailRow label="Interruption" value={`${data.businessInterruptionDays} days`} />}
      {data.emergencyAuthAmount != null && <DetailRow label="Emergency Auth" value={`$${Number(data.emergencyAuthAmount).toLocaleString()}`} />}
    </>
  );
}

// ==================== SUPPLEMENTS TAB ====================

const REASON_OPTIONS: { value: SupplementReason; label: string }[] = [
  { value: 'hidden_damage', label: 'Hidden Damage' },
  { value: 'code_upgrade', label: 'Code Upgrade' },
  { value: 'scope_change', label: 'Scope Change' },
  { value: 'material_upgrade', label: 'Material Upgrade' },
  { value: 'additional_repair', label: 'Additional Repair' },
  { value: 'other', label: 'Other' },
];

const SUPPLEMENT_STATUS_STYLES: Record<string, string> = {
  draft: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300',
  submitted: 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400',
  under_review: 'bg-purple-100 text-purple-700 dark:bg-purple-900/40 dark:text-purple-400',
  approved: 'bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-400',
  denied: 'bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-400',
  partially_approved: 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400',
};

function SupplementsTab({
  claimId,
  supplements,
  onRefresh,
}: {
  claimId: string;
  supplements: import('@/types').ClaimSupplementData[];
  onRefresh: () => void;
}) {
  const { t } = useTranslation();
  const [showCreate, setShowCreate] = useState(false);
  const [saving, setSaving] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [reason, setReason] = useState<SupplementReason>('hidden_damage');
  const [amount, setAmount] = useState('');
  const [rcvAmount, setRcvAmount] = useState('');
  const [acvAmount, setAcvAmount] = useState('');

  const resetForm = () => {
    setTitle(''); setDescription(''); setReason('hidden_damage');
    setAmount(''); setRcvAmount(''); setAcvAmount('');
    setShowCreate(false);
  };

  const handleCreate = async () => {
    if (!title.trim()) return;
    setSaving(true);
    try {
      await createSupplement({
        claimId,
        title: title.trim(),
        description: description.trim() || undefined,
        reason,
        amount: parseFloat(amount) || 0,
        rcvAmount: parseFloat(rcvAmount) || undefined,
        acvAmount: parseFloat(acvAmount) || undefined,
        depreciationAmount: (parseFloat(rcvAmount) || 0) - (parseFloat(acvAmount) || 0) > 0
          ? (parseFloat(rcvAmount) || 0) - (parseFloat(acvAmount) || 0) : 0,
      });
      resetForm();
      onRefresh();
    } catch (e) {
      alert(`Error: ${e}`);
    } finally {
      setSaving(false);
    }
  };

  const handleStatusChange = async (supplementId: string, status: import('@/types').SupplementStatus) => {
    try {
      await updateSupplementStatus(supplementId, status);
      onRefresh();
    } catch (e) {
      alert(`Error: ${e}`);
    }
  };

  const handleDelete = async (supplementId: string) => {
    if (!confirm('Delete this supplement?')) return;
    try {
      await deleteSupplement(supplementId);
      onRefresh();
    } catch (e) {
      alert(`Error: ${e}`);
    }
  };

  const totalRequested = supplements.reduce((s, x) => s + x.amount, 0);
  const totalApproved = supplements.reduce((s, x) => s + (x.approvedAmount || 0), 0);
  const pendingCount = supplements.filter(s => ['draft', 'submitted', 'under_review'].includes(s.status)).length;

  return (
    <div className="space-y-3">
      {/* Summary bar */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4 text-xs text-muted-foreground">
          <span>{supplements.length} supplement{supplements.length !== 1 ? 's' : ''}</span>
          {totalRequested > 0 && <span>${totalRequested.toLocaleString()} requested</span>}
          {totalApproved > 0 && <span className="text-green-600">${totalApproved.toLocaleString()} approved</span>}
          {pendingCount > 0 && <span className="text-amber-600">{pendingCount} pending</span>}
        </div>
        <button
          onClick={() => setShowCreate(!showCreate)}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 text-xs font-medium hover:bg-amber-500/20 transition-colors"
        >
          <Plus className="w-3.5 h-3.5" />
          Add Supplement
        </button>
      </div>

      {/* Create form */}
      {showCreate && (
        <div className="rounded-xl border border-amber-500/30 bg-card p-4 space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">New Supplement</span>
            <div className="flex items-center gap-2">
              <button onClick={resetForm} className="text-xs text-muted-foreground hover:text-foreground">{t('common.cancel')}</button>
              <button
                onClick={handleCreate}
                disabled={saving || !title.trim()}
                className="px-3 py-1 rounded-lg bg-amber-500 text-white text-xs font-medium hover:bg-amber-600 disabled:opacity-50 transition-colors"
              >
                {saving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
          <input
            type="text"
            placeholder="Title — e.g. Hidden water damage behind kitchen wall"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3 py-2 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30"
          />
          <textarea
            placeholder="Description (optional)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            rows={2}
            className="w-full px-3 py-2 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30 resize-none"
          />
          <div>
            <label className="text-xs text-muted-foreground mb-1.5 block">Reason</label>
            <div className="flex flex-wrap gap-1.5">
              {REASON_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  onClick={() => setReason(opt.value)}
                  className={`px-2.5 py-1 rounded-md text-xs font-medium transition-colors ${
                    reason === opt.value
                      ? 'bg-amber-500 text-white'
                      : 'bg-muted text-muted-foreground hover:bg-muted/80'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">Amount ($)</label>
              <input type="number" step="0.01" min="0" placeholder="0" value={amount} onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
                className="w-full px-3 py-1.5 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">RCV</label>
              <input type="number" step="0.01" min="0" placeholder="Optional" value={rcvAmount} onChange={(e) => setRcvAmount(e.target.value.replace(/[^0-9.]/g, ''))}
                className="w-full px-3 py-1.5 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30" />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">ACV</label>
              <input type="number" step="0.01" min="0" placeholder="Optional" value={acvAmount} onChange={(e) => setAcvAmount(e.target.value.replace(/[^0-9.]/g, ''))}
                className="w-full px-3 py-1.5 text-sm rounded-lg border border-border bg-background focus:outline-none focus:ring-2 focus:ring-amber-500/30" />
            </div>
          </div>
        </div>
      )}

      {/* Empty state */}
      {supplements.length === 0 && !showCreate && <EmptyTab icon={FileText} label="No supplements yet — tap Add to create one" />}

      {/* Supplement cards */}
      {supplements.map((s) => (
        <div key={s.id} className="rounded-xl border border-border bg-card p-4">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-2">
              <span className="text-xs font-mono text-muted-foreground">#{s.supplementNumber}</span>
              <span className="text-sm font-medium">{s.title}</span>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-medium capitalize ${SUPPLEMENT_STATUS_STYLES[s.status] || ''}`}>
              {s.status.replace('_', ' ')}
            </span>
          </div>
          {s.description && <p className="text-xs text-muted-foreground mb-2">{s.description}</p>}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4 text-xs text-muted-foreground">
              <span className="capitalize">{s.reason.replace('_', ' ')}</span>
              <span className="font-medium text-foreground">${s.amount.toLocaleString()}</span>
              {s.approvedAmount != null && (
                <span className="text-green-600 font-medium">Approved: ${s.approvedAmount.toLocaleString()}</span>
              )}
            </div>
            {/* RCV/ACV/Depreciation */}
            {(s.rcvAmount != null || s.acvAmount != null) && (
              <div className="flex items-center gap-2 text-[10px] text-muted-foreground">
                {s.rcvAmount != null && <span>RCV: ${s.rcvAmount.toLocaleString()}</span>}
                {s.acvAmount != null && <span>ACV: ${s.acvAmount.toLocaleString()}</span>}
                {s.depreciationAmount > 0 && <span>Dep: ${s.depreciationAmount.toLocaleString()}</span>}
              </div>
            )}
          </div>
          {/* Action buttons */}
          <div className="flex items-center gap-2 mt-3 pt-2 border-t border-border">
            {s.status === 'draft' && (
              <>
                <button onClick={() => handleStatusChange(s.id, 'submitted')}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-blue-500/10 text-blue-600 dark:text-blue-400 text-xs font-medium hover:bg-blue-500/20 transition-colors">
                  <Send className="w-3 h-3" /> Submit
                </button>
                <button onClick={() => handleDelete(s.id)}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-red-500/10 text-red-600 dark:text-red-400 text-xs font-medium hover:bg-red-500/20 transition-colors">
                  <Trash2 className="w-3 h-3" /> Delete
                </button>
              </>
            )}
            {(s.status === 'submitted' || s.status === 'under_review') && (
              <>
                <button onClick={() => handleStatusChange(s.id, 'approved')}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-green-500/10 text-green-600 dark:text-green-400 text-xs font-medium hover:bg-green-500/20 transition-colors">
                  <CheckCircle className="w-3 h-3" /> Approve
                </button>
                <button onClick={() => handleStatusChange(s.id, 'denied')}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-red-500/10 text-red-600 dark:text-red-400 text-xs font-medium hover:bg-red-500/20 transition-colors">
                  <XCircle className="w-3 h-3" /> Deny
                </button>
                {s.status === 'submitted' && (
                  <button onClick={() => handleStatusChange(s.id, 'under_review')}
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md bg-purple-500/10 text-purple-600 dark:text-purple-400 text-xs font-medium hover:bg-purple-500/20 transition-colors">
                    Under Review
                  </button>
                )}
              </>
            )}
            {(s.status === 'approved' || s.status === 'denied' || s.status === 'partially_approved') && (
              <span className="text-xs text-muted-foreground">
                {s.reviewedAt ? `Reviewed ${new Date(s.reviewedAt).toLocaleDateString()}` : 'Reviewed'}
              </span>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

// ==================== COMPLETION TAB ====================

interface CompletionCheck {
  id: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  passed: boolean;
  detail: string;
}

function CompletionTab({
  claim,
  moistureReadings,
  equipment,
  dryingLogs,
  tpiInspections,
  onTransition,
  transitioning,
}: {
  claim: InsuranceClaimData;
  moistureReadings: MoistureReadingData[];
  equipment: RestorationEquipmentData[];
  dryingLogs: DryingLogData[];
  tpiInspections: TpiInspectionData[];
  onTransition: (status: ClaimStatus) => Promise<void>;
  transitioning: boolean;
}) {
  // Compute completion checks from existing data
  const moistureAllDry = moistureReadings.length > 0 && moistureReadings.every(r => r.isDry);
  const stillDeployed = equipment.filter(e => e.status === 'deployed' || e.status === 'maintenance');
  const equipmentAllRemoved = equipment.length === 0 || stillDeployed.length === 0;
  const hasDryingCompletion = dryingLogs.some(d => d.logType === 'completion');
  const hasTpiFinalPassed = tpiInspections.some(
    t => t.inspectionType === 'final' && t.status === 'completed' && t.result === 'passed'
  );

  const checks: CompletionCheck[] = [
    {
      id: 'moisture',
      title: 'Moisture Readings at Target',
      subtitle: 'All moisture readings show dry conditions',
      icon: Droplets,
      passed: moistureAllDry,
      detail: moistureReadings.length === 0
        ? 'No readings recorded'
        : moistureAllDry
          ? `All ${moistureReadings.length} readings dry`
          : `${moistureReadings.filter(r => !r.isDry).length} of ${moistureReadings.length} still wet`,
    },
    {
      id: 'equipment',
      title: 'All Equipment Removed',
      subtitle: 'Restoration equipment removed from site',
      icon: Wrench,
      passed: equipmentAllRemoved,
      detail: equipment.length === 0
        ? 'No equipment was deployed'
        : equipmentAllRemoved
          ? `All ${equipment.length} pieces removed`
          : `${stillDeployed.length} still on site`,
    },
    {
      id: 'drying',
      title: 'Drying Completion Logged',
      subtitle: 'Drying log has a completion entry',
      icon: ThermometerSun,
      passed: hasDryingCompletion,
      detail: hasDryingCompletion ? 'Completion entry recorded' : 'No drying completion entry',
    },
    {
      id: 'tpi',
      title: 'TPI Final Inspection Passed',
      subtitle: 'Third-party inspector approved the work',
      icon: ClipboardCheck,
      passed: hasTpiFinalPassed,
      detail: hasTpiFinalPassed
        ? 'Final inspection passed'
        : tpiInspections.some(t => t.inspectionType === 'final')
          ? 'Final inspection not yet passed'
          : 'No final inspection scheduled',
    },
  ];

  const passedCount = checks.filter(c => c.passed).length;
  const allPassed = passedCount === checks.length;
  const progress = checks.length > 0 ? passedCount / checks.length : 0;

  // Determine available actions based on claim status
  const isWorkInProgress = claim.claimStatus === 'work_in_progress';
  const isWorkComplete = claim.claimStatus === 'work_complete';
  const isFinalInspection = claim.claimStatus === 'final_inspection';
  const isSettled = claim.claimStatus === 'settled' || claim.claimStatus === 'closed';
  const canMarkComplete = isWorkInProgress && allPassed;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="rounded-xl border border-border bg-card p-5">
        <div className="flex items-center justify-between mb-3">
          <div>
            <h3 className="text-[15px] font-semibold">Certificate of Completion</h3>
            <p className="text-xs text-muted-foreground mt-0.5">
              {isSettled
                ? 'Claim has been settled'
                : allPassed
                  ? 'All requirements met — ready to advance'
                  : `${passedCount} of ${checks.length} requirements met`}
            </p>
          </div>
          {!isSettled && (
            <span className={`text-lg font-bold ${allPassed ? 'text-green-600' : 'text-amber-500'}`}>
              {Math.round(progress * 100)}%
            </span>
          )}
        </div>
        {!isSettled && (
          <div className="w-full h-2 rounded-full bg-muted overflow-hidden">
            <div
              className={`h-full rounded-full transition-all duration-500 ${allPassed ? 'bg-green-500' : 'bg-amber-500'}`}
              style={{ width: `${progress * 100}%` }}
            />
          </div>
        )}
      </div>

      {/* Checklist */}
      <div className="space-y-2">
        {checks.map((check) => {
          const Icon = check.icon;
          return (
            <div
              key={check.id}
              className={`rounded-xl border bg-card p-4 transition-colors ${
                check.passed ? 'border-green-200 dark:border-green-900/40' : 'border-border'
              }`}
            >
              <div className="flex items-center gap-3">
                <div className={`w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 ${
                  check.passed
                    ? 'bg-green-100 dark:bg-green-900/30'
                    : 'bg-muted'
                }`}>
                  {check.passed
                    ? <CheckCircle className="w-4 h-4 text-green-600" />
                    : <Icon className="w-4 h-4 text-muted-foreground" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className={`text-sm font-medium ${check.passed ? 'text-muted-foreground' : ''}`}>
                    {check.title}
                  </p>
                  <p className={`text-xs ${check.passed ? 'text-green-600' : 'text-muted-foreground'}`}>
                    {check.detail}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Action Buttons */}
      {!isSettled && (
        <div className="rounded-xl border border-border bg-card p-5">
          {isWorkInProgress && (
            <button
              onClick={() => onTransition('work_complete')}
              disabled={!allPassed || transitioning}
              className={`w-full py-3 rounded-lg text-sm font-semibold transition-colors ${
                allPassed
                  ? 'bg-green-600 text-white hover:bg-green-700'
                  : 'bg-muted text-muted-foreground cursor-not-allowed'
              }`}
            >
              {transitioning ? 'Processing...' : allPassed ? 'Mark Work Complete' : 'Complete all checks to proceed'}
            </button>
          )}
          {isWorkComplete && (
            <button
              onClick={() => onTransition('final_inspection')}
              disabled={transitioning}
              className="w-full py-3 rounded-lg text-sm font-semibold bg-amber-500 text-white hover:bg-amber-600 transition-colors disabled:opacity-50"
            >
              {transitioning ? 'Processing...' : 'Request Final Inspection'}
            </button>
          )}
          {isFinalInspection && (
            <button
              onClick={() => onTransition('settled')}
              disabled={transitioning}
              className="w-full py-3 rounded-lg text-sm font-semibold bg-green-600 text-white hover:bg-green-700 transition-colors disabled:opacity-50"
            >
              {transitioning ? 'Processing...' : 'Settle Claim'}
            </button>
          )}
          {!isWorkInProgress && !isWorkComplete && !isFinalInspection && (
            <p className="text-sm text-muted-foreground text-center">
              Claim must be in &quot;Work In Progress&quot; status to begin completion workflow
            </p>
          )}
        </div>
      )}

      {/* Settled confirmation */}
      {isSettled && (
        <div className="rounded-xl border border-green-200 dark:border-green-900/40 bg-green-50 dark:bg-green-950/20 p-5 flex items-center gap-3">
          <CheckCircle className="w-6 h-6 text-green-600 flex-shrink-0" />
          <div>
            <p className="text-sm font-semibold text-green-800 dark:text-green-300">Claim Settled</p>
            <p className="text-xs text-green-700 dark:text-green-400">
              {claim.settledAt ? `Settled on ${new Date(claim.settledAt).toLocaleDateString()}` : 'This claim has been settled'}
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
