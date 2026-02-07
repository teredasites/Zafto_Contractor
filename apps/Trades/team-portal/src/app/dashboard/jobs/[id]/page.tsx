'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import {
  ArrowLeft, MapPin, Calendar, Clock, FileText, Wrench,
  CheckSquare, Package, Play, ClipboardList,
  Droplets, Wind, Thermometer, CheckCircle2, AlertTriangle,
  Shield, Plus, X, Building2, Phone, Mail, User, Hammer,
} from 'lucide-react';
import { useJob } from '@/lib/hooks/use-jobs';
import { useJobPropertyContext, type JobPropertyContext } from '@/lib/hooks/use-pm-jobs';
import { useJobInsurance, addMoistureReading, addDryingLog, deployEquipment, removeEquipment } from '@/lib/hooks/use-insurance';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge';
import { formatDate, formatTime, formatCurrency, cn } from '@/lib/utils';
import { JOB_TYPE_LABELS, JOB_TYPE_COLORS, URGENCY_COLORS, MAINTENANCE_STATUS_LABELS } from '@/lib/hooks/mappers';
import type { JobType, InsuranceMetadata, WarrantyMetadata, ClaimStatus, MaterialMoistureType, DryingLogType, EquipmentType, MaintenanceUrgency, MaintenanceRequestStatus } from '@/lib/hooks/mappers';

const CLAIM_STATUS_LABELS: Record<ClaimStatus, string> = {
  new: 'New Claim',
  scope_requested: 'Scope Requested',
  scope_submitted: 'Scope Submitted',
  estimate_pending: 'Estimate Pending',
  estimate_approved: 'Estimate Approved',
  supplement_submitted: 'Supplement Filed',
  supplement_approved: 'Supplement Approved',
  work_in_progress: 'Work In Progress',
  work_complete: 'Work Complete',
  final_inspection: 'Final Inspection',
  settled: 'Settled',
  closed: 'Closed',
  denied: 'Denied',
};

function JobDetailSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-3">
        <div className="skeleton h-9 w-9 rounded-lg" />
        <div className="skeleton h-6 w-48 rounded-lg" />
      </div>
      <div className="skeleton h-8 w-64 rounded-lg" />
      <div className="skeleton h-40 w-full rounded-xl" />
      <div className="skeleton h-48 w-full rounded-xl" />
      <div className="grid grid-cols-2 gap-3">
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
        <div className="skeleton h-14 rounded-xl" />
      </div>
    </div>
  );
}

export default function JobDetailPage() {
  const params = useParams();
  const jobId = params.id as string;
  const { job, loading } = useJob(jobId);
  const isInsurance = job?.jobType === 'insurance_claim';
  const isPropertyJob = !!job?.propertyId;
  const { claim, moisture, dryingLogs, equipment, tpiInspections, loading: insLoading } = useJobInsurance(isInsurance ? jobId : null);
  const { context: pmContext, loading: pmLoading } = useJobPropertyContext(isPropertyJob ? jobId : null, job?.propertyId ?? null);

  if (loading) return <JobDetailSkeleton />;

  if (!job) {
    return (
      <div className="space-y-6 animate-fade-in">
        <Link
          href="/dashboard/jobs"
          className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors"
        >
          <ArrowLeft size={16} />
          Back to Jobs
        </Link>
        <Card>
          <CardContent className="py-12 text-center">
            <ClipboardList size={40} className="text-muted mx-auto mb-3" />
            <p className="text-sm font-medium text-main">Job not found</p>
            <p className="text-sm text-muted mt-1">This job may have been removed or you no longer have access.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const fullAddress = [job.address, job.city, job.state].filter(Boolean).join(', ');

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Back navigation */}
      <Link
        href="/dashboard/jobs"
        className="inline-flex items-center gap-2 text-sm text-muted hover:text-main transition-colors min-h-[44px]"
      >
        <ArrowLeft size={16} />
        Back to Jobs
      </Link>

      {/* Job Header */}
      <div className="flex flex-col sm:flex-row sm:items-start gap-3">
        <div className="flex-1 min-w-0">
          <h1 className="text-xl font-semibold text-main">{job.title}</h1>
          <p className="text-sm text-secondary mt-0.5">{job.customerName}</p>
        </div>
        <StatusBadge status={job.status} className="self-start" />
      </div>

      {/* Job Info */}
      <Card>
        <CardContent className="py-4 space-y-4">
          {/* Address */}
          {fullAddress && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <MapPin size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Address</p>
                <p className="text-sm text-main mt-0.5">{fullAddress}</p>
              </div>
            </div>
          )}

          {/* Scheduled Date */}
          {job.scheduledStart && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <Calendar size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Scheduled</p>
                <p className="text-sm text-main mt-0.5">
                  {formatDate(job.scheduledStart)} at {formatTime(job.scheduledStart)}
                  {job.scheduledEnd && (
                    <span className="text-muted"> - {formatTime(job.scheduledEnd)}</span>
                  )}
                </p>
              </div>
            </div>
          )}

          {/* Estimated Amount */}
          {job.estimatedAmount > 0 && (
            <div className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
                <FileText size={16} className="text-muted" />
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wide font-medium">Estimated</p>
                <p className="text-sm text-main mt-0.5">{formatCurrency(job.estimatedAmount)}</p>
              </div>
            </div>
          )}

          {/* Type */}
          <div className="flex items-start gap-3">
            <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
              <Wrench size={16} className="text-muted" />
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wide font-medium">Type</p>
              <span className={cn('inline-flex items-center gap-1.5 mt-1 px-2 py-0.5 text-xs font-medium rounded-full', JOB_TYPE_COLORS[job.jobType as JobType].bg, JOB_TYPE_COLORS[job.jobType as JobType].text)}>
                <span className={cn('w-1.5 h-1.5 rounded-full', JOB_TYPE_COLORS[job.jobType as JobType].dot)} />
                {JOB_TYPE_LABELS[job.jobType as JobType]}
              </span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Type Metadata */}
      {job.jobType !== 'standard' && job.typeMetadata && Object.keys(job.typeMetadata).length > 0 && (
        <TypeMetadataSection jobType={job.jobType as JobType} metadata={job.typeMetadata} />
      )}

      {/* Property Maintenance Context */}
      {isPropertyJob && !pmLoading && pmContext && (
        <PropertyMaintenanceSection context={pmContext} />
      )}

      {/* Insurance Restoration Progress */}
      {isInsurance && !insLoading && claim && (
        <RestorationProgress
          jobId={jobId}
          claim={claim}
          moisture={moisture}
          dryingLogs={dryingLogs}
          equipment={equipment}
          tpiInspections={tpiInspections}
        />
      )}

      {/* Description */}
      {job.description && (
        <Card>
          <CardHeader>
            <CardTitle>Description</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-secondary whitespace-pre-wrap leading-relaxed">{job.description}</p>
          </CardContent>
        </Card>
      )}

      {/* Quick Actions */}
      <div>
        <h2 className="text-[15px] font-semibold text-main mb-3">Quick Actions</h2>

        <div className="grid grid-cols-2 gap-3">
          <Link href={`/dashboard/time-clock?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Play size={20} />
              <span className="text-xs">Clock In</span>
            </Button>
          </Link>
          <Link href={`/dashboard/field-tools?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Wrench size={20} />
              <span className="text-xs">Field Tools</span>
            </Button>
          </Link>
          <Link href={`/dashboard/punch-list?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <CheckSquare size={20} />
              <span className="text-xs">Punch List</span>
            </Button>
          </Link>
          <Link href={`/dashboard/materials?jobId=${job.id}`}>
            <Button variant="secondary" size="lg" className="w-full min-h-[56px] flex-col gap-1 py-3">
              <Package size={20} />
              <span className="text-xs">Materials</span>
            </Button>
          </Link>
        </div>
      </div>
    </div>
  );
}

// ==================== PROPERTY MAINTENANCE ====================

function PropertyMaintenanceSection({ context }: { context: JobPropertyContext }) {
  return (
    <div className="space-y-4">
      {/* Property Info */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Building2 size={16} className="text-emerald-500" />
            Property Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <MetaRow label="Property" value={context.propertyName} />
          {context.propertyAddress && <MetaRow label="Address" value={context.propertyAddress} />}
          {context.unitNumber && <MetaRow label="Unit" value={context.unitNumber} />}
        </CardContent>
      </Card>

      {/* Tenant Contact */}
      {context.tenantName && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User size={16} className="text-blue-500" />
              Tenant
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="text-sm font-medium text-main">{context.tenantName}</p>
            {context.tenantPhone && (
              <a href={`tel:${context.tenantPhone}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                <Phone size={14} /> {context.tenantPhone}
              </a>
            )}
            {context.tenantEmail && (
              <a href={`mailto:${context.tenantEmail}`} className="flex items-center gap-2 text-sm text-accent hover:underline">
                <Mail size={14} /> {context.tenantEmail}
              </a>
            )}
          </CardContent>
        </Card>
      )}

      {/* Maintenance Request */}
      {context.maintenanceRequest && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Hammer size={16} className="text-orange-500" />
              Maintenance Request
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <p className="text-sm font-medium text-main">{context.maintenanceRequest.title}</p>
            {context.maintenanceRequest.description && (
              <p className="text-sm text-secondary whitespace-pre-wrap">{context.maintenanceRequest.description}</p>
            )}
            <div className="flex flex-wrap gap-2">
              {context.maintenanceRequest.category && (
                <span className="text-xs px-2 py-0.5 rounded-full bg-secondary text-muted font-medium">
                  {context.maintenanceRequest.category}
                </span>
              )}
              <span className={cn(
                'text-xs px-2 py-0.5 rounded-full font-medium',
                URGENCY_COLORS[context.maintenanceRequest.urgency as MaintenanceUrgency]?.bg || 'bg-secondary',
                URGENCY_COLORS[context.maintenanceRequest.urgency as MaintenanceUrgency]?.text || 'text-muted',
              )}>
                {context.maintenanceRequest.urgency}
              </span>
              <span className="text-xs px-2 py-0.5 rounded-full bg-secondary text-muted font-medium">
                {MAINTENANCE_STATUS_LABELS[context.maintenanceRequest.status as MaintenanceRequestStatus] || context.maintenanceRequest.status}
              </span>
            </div>
            {context.maintenanceRequest.photos.length > 0 && (
              <p className="text-xs text-muted">{context.maintenanceRequest.photos.length} photo{context.maintenanceRequest.photos.length !== 1 ? 's' : ''} attached</p>
            )}
          </CardContent>
        </Card>
      )}

      {/* Property Assets */}
      {context.assets.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Wrench size={16} className="text-violet-500" />
              Property Assets ({context.assets.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {context.assets.map((asset) => (
              <div key={asset.id} className="flex items-center justify-between text-sm py-1.5 border-b border-main/5 last:border-0">
                <div>
                  <span className="text-main font-medium capitalize">{asset.assetType.replace(/_/g, ' ')}</span>
                  {asset.brand && <span className="text-muted ml-2 text-xs">{asset.brand} {asset.model}</span>}
                </div>
                <span className={cn('text-xs font-medium capitalize',
                  asset.condition === 'good' || asset.condition === 'excellent' ? 'text-emerald-600 dark:text-emerald-400' :
                  asset.condition === 'fair' ? 'text-amber-600 dark:text-amber-400' :
                  'text-red-600 dark:text-red-400'
                )}>
                  {asset.condition}
                </span>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ==================== RESTORATION PROGRESS ====================

function RestorationProgress({
  jobId, claim, moisture, dryingLogs, equipment, tpiInspections,
}: {
  jobId: string;
  claim: { id: string; claimNumber: string; claimStatus: ClaimStatus; insuranceCompany: string; deductible: number };
  moisture: { id: string; areaName: string; materialType: string; readingValue: number; readingUnit: string; isDry: boolean; recordedAt: string }[];
  dryingLogs: { id: string; logType: string; summary: string; equipmentCount: number; dehumidifiersRunning: number; airMoversRunning: number; recordedAt: string }[];
  equipment: { id: string; equipmentType: string; areaDeployed: string; status: string; deployedAt: string; serialNumber?: string }[];
  tpiInspections: { id: string; inspectionType: string; status: string; result?: string; scheduledDate?: string; inspectorName?: string }[];
}) {
  const [showMoistureForm, setShowMoistureForm] = useState(false);
  const [showDryingForm, setShowDryingForm] = useState(false);
  const [showEquipForm, setShowEquipForm] = useState(false);

  const dryCount = moisture.filter(m => m.isDry).length;
  const wetCount = moisture.length - dryCount;
  const deployedEquipment = equipment.filter(e => e.status === 'deployed');
  const latestDryingLog = dryingLogs[0];
  const nextTpi = tpiInspections.find(t => t.status === 'scheduled' || t.status === 'confirmed');
  const completedTpi = tpiInspections.filter(t => t.status === 'completed');

  return (
    <div className="space-y-4">
      {/* Claim Status Banner */}
      <Card>
        <CardContent className="py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Shield size={16} className="text-amber-500" />
              <span className="text-sm font-medium text-main">
                {claim.insuranceCompany} — {claim.claimNumber}
              </span>
            </div>
            <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
              {CLAIM_STATUS_LABELS[claim.claimStatus]}
            </span>
          </div>
        </CardContent>
      </Card>

      {/* Moisture Readings */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Droplets size={16} className="text-blue-500" />
              Moisture Readings
            </CardTitle>
            <Button variant="secondary" size="sm" onClick={() => setShowMoistureForm(!showMoistureForm)}>
              {showMoistureForm ? <X size={14} /> : <Plus size={14} />}
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {/* Summary stats */}
          <div className="flex gap-4 text-sm">
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              <span className="text-secondary">{dryCount} dry</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-red-500" />
              <span className="text-secondary">{wetCount} wet</span>
            </div>
            <span className="text-muted text-xs">{moisture.length} total readings</span>
          </div>

          {/* Recent readings */}
          {moisture.slice(0, 5).map(m => (
            <div key={m.id} className="flex items-center justify-between text-sm py-1 border-b border-main/5 last:border-0">
              <div>
                <span className="text-main font-medium">{m.areaName}</span>
                <span className="text-muted ml-2 text-xs">{m.materialType}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="font-mono text-xs">{m.readingValue}{m.readingUnit === 'percent' ? '%' : ` ${m.readingUnit}`}</span>
                {m.isDry ? (
                  <CheckCircle2 size={14} className="text-emerald-500" />
                ) : (
                  <AlertTriangle size={14} className="text-red-500" />
                )}
              </div>
            </div>
          ))}

          {moisture.length === 0 && (
            <p className="text-xs text-muted text-center py-2">No readings recorded yet.</p>
          )}

          {/* Add Reading Form */}
          {showMoistureForm && (
            <MoistureForm jobId={jobId} claimId={claim.id} onDone={() => setShowMoistureForm(false)} />
          )}
        </CardContent>
      </Card>

      {/* Drying Status */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Wind size={16} className="text-cyan-500" />
              Drying Status
            </CardTitle>
            <Button variant="secondary" size="sm" onClick={() => setShowDryingForm(!showDryingForm)}>
              {showDryingForm ? <X size={14} /> : <Plus size={14} />}
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {latestDryingLog ? (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-sm">
                <span className="text-secondary">Latest: {latestDryingLog.summary}</span>
                <span className="text-xs text-muted">{formatDate(latestDryingLog.recordedAt)}</span>
              </div>
              <div className="flex gap-3 text-xs text-muted">
                <span>{latestDryingLog.dehumidifiersRunning} dehumidifiers</span>
                <span>{latestDryingLog.airMoversRunning} air movers</span>
                <span>{latestDryingLog.equipmentCount} total equip</span>
              </div>
            </div>
          ) : (
            <p className="text-xs text-muted text-center py-2">No drying logs recorded yet.</p>
          )}
          <p className="text-xs text-muted">{dryingLogs.length} log entries</p>

          {showDryingForm && (
            <DryingForm jobId={jobId} claimId={claim.id} onDone={() => setShowDryingForm(false)} />
          )}
        </CardContent>
      </Card>

      {/* Equipment */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2">
              <Thermometer size={16} className="text-orange-500" />
              Equipment ({deployedEquipment.length} deployed)
            </CardTitle>
            <Button variant="secondary" size="sm" onClick={() => setShowEquipForm(!showEquipForm)}>
              {showEquipForm ? <X size={14} /> : <Plus size={14} />}
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {deployedEquipment.map(e => (
            <div key={e.id} className="flex items-center justify-between text-sm py-1.5 border-b border-main/5 last:border-0">
              <div>
                <span className="text-main font-medium capitalize">{e.equipmentType.replace(/_/g, ' ')}</span>
                <span className="text-muted ml-2 text-xs">{e.areaDeployed}</span>
                {e.serialNumber && <span className="text-muted ml-1 text-xs">({e.serialNumber})</span>}
              </div>
              <Button variant="secondary" size="sm" onClick={() => removeEquipment(e.id)}>
                Remove
              </Button>
            </div>
          ))}
          {deployedEquipment.length === 0 && (
            <p className="text-xs text-muted text-center py-2">No equipment currently deployed.</p>
          )}

          {showEquipForm && (
            <EquipmentForm jobId={jobId} claimId={claim.id} onDone={() => setShowEquipForm(false)} />
          )}
        </CardContent>
      </Card>

      {/* TPI Inspections */}
      {(tpiInspections.length > 0 || nextTpi) && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ClipboardList size={16} className="text-violet-500" />
              TPI Inspections
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {nextTpi && (
              <div className="flex items-center justify-between text-sm p-2 bg-violet-50 dark:bg-violet-900/20 rounded-lg">
                <div>
                  <span className="font-medium text-violet-700 dark:text-violet-300 capitalize">{nextTpi.inspectionType.replace(/_/g, ' ')}</span>
                  {nextTpi.inspectorName && <span className="text-muted ml-2 text-xs">{nextTpi.inspectorName}</span>}
                </div>
                <span className="text-xs font-medium text-violet-600 dark:text-violet-400">
                  {nextTpi.scheduledDate ? formatDate(nextTpi.scheduledDate) : 'TBD'}
                </span>
              </div>
            )}
            {completedTpi.map(t => (
              <div key={t.id} className="flex items-center justify-between text-sm py-1 text-muted">
                <span className="capitalize">{t.inspectionType.replace(/_/g, ' ')}</span>
                <span className={cn('text-xs font-medium',
                  t.result === 'passed' ? 'text-emerald-600' : t.result === 'failed' ? 'text-red-600' : 'text-amber-600'
                )}>
                  {t.result || 'No result'}
                </span>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ==================== INLINE FORMS ====================

function MoistureForm({ jobId, claimId, onDone }: { jobId: string; claimId: string; onDone: () => void }) {
  const [area, setArea] = useState('');
  const [material, setMaterial] = useState<MaterialMoistureType>('drywall');
  const [value, setValue] = useState('');
  const [isDry, setIsDry] = useState(false);
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!area || !value) return;
    setSaving(true);
    try {
      await addMoistureReading({
        jobId, claimId, areaName: area,
        materialType: material,
        readingValue: parseFloat(value),
        isDry,
      });
      onDone();
    } catch { /* toast would go here */ }
    setSaving(false);
  };

  return (
    <div className="border border-main/10 rounded-lg p-3 space-y-3 bg-secondary/50">
      <div className="grid grid-cols-2 gap-2">
        <input placeholder="Area (e.g. Kitchen wall)" value={area} onChange={e => setArea(e.target.value)}
          className="col-span-2 text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main focus:outline-none focus:ring-1 focus:ring-accent" />
        <select value={material} onChange={e => setMaterial(e.target.value as MaterialMoistureType)}
          className="text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main">
          {(['drywall','wood','concrete','carpet','pad','insulation','subfloor','hardwood','laminate','tile_backer','other'] as MaterialMoistureType[]).map(m => (
            <option key={m} value={m}>{m.replace(/_/g, ' ')}</option>
          ))}
        </select>
        <input type="number" placeholder="Reading %" value={value} onChange={e => setValue(e.target.value)}
          className="text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main focus:outline-none focus:ring-1 focus:ring-accent" />
      </div>
      <div className="flex items-center justify-between">
        <label className="flex items-center gap-2 text-sm text-secondary cursor-pointer">
          <input type="checkbox" checked={isDry} onChange={e => setIsDry(e.target.checked)}
            className="rounded border-main/20" />
          Mark as dry
        </label>
        <Button size="sm" onClick={handleSave} loading={saving}>Save Reading</Button>
      </div>
    </div>
  );
}

function DryingForm({ jobId, claimId, onDone }: { jobId: string; claimId: string; onDone: () => void }) {
  const [logType, setLogType] = useState<DryingLogType>('daily');
  const [summary, setSummary] = useState('');
  const [dehumidifiers, setDehumidifiers] = useState('0');
  const [airMovers, setAirMovers] = useState('0');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!summary) return;
    setSaving(true);
    try {
      await addDryingLog({
        jobId, claimId, logType, summary,
        dehumidifiersRunning: parseInt(dehumidifiers) || 0,
        airMoversRunning: parseInt(airMovers) || 0,
        equipmentCount: (parseInt(dehumidifiers) || 0) + (parseInt(airMovers) || 0),
      });
      onDone();
    } catch { /* toast would go here */ }
    setSaving(false);
  };

  return (
    <div className="border border-main/10 rounded-lg p-3 space-y-3 bg-secondary/50">
      <select value={logType} onChange={e => setLogType(e.target.value as DryingLogType)}
        className="w-full text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main">
        {(['setup','daily','adjustment','equipment_change','completion','note'] as DryingLogType[]).map(t => (
          <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
        ))}
      </select>
      <input placeholder="Summary (e.g. Day 3 — readings improving)" value={summary} onChange={e => setSummary(e.target.value)}
        className="w-full text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main focus:outline-none focus:ring-1 focus:ring-accent" />
      <div className="grid grid-cols-2 gap-2">
        <label className="text-xs text-muted">
          Dehumidifiers
          <input type="number" value={dehumidifiers} onChange={e => setDehumidifiers(e.target.value)}
            className="w-full mt-1 text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main" />
        </label>
        <label className="text-xs text-muted">
          Air Movers
          <input type="number" value={airMovers} onChange={e => setAirMovers(e.target.value)}
            className="w-full mt-1 text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main" />
        </label>
      </div>
      <div className="flex justify-end">
        <Button size="sm" onClick={handleSave} loading={saving}>Save Log</Button>
      </div>
    </div>
  );
}

function EquipmentForm({ jobId, claimId, onDone }: { jobId: string; claimId: string; onDone: () => void }) {
  const [type, setType] = useState<EquipmentType>('dehumidifier');
  const [area, setArea] = useState('');
  const [serial, setSerial] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    if (!area) return;
    setSaving(true);
    try {
      await deployEquipment({
        jobId, claimId, equipmentType: type,
        areaDeployed: area,
        serialNumber: serial || undefined,
      });
      onDone();
    } catch { /* toast would go here */ }
    setSaving(false);
  };

  return (
    <div className="border border-main/10 rounded-lg p-3 space-y-3 bg-secondary/50">
      <select value={type} onChange={e => setType(e.target.value as EquipmentType)}
        className="w-full text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main">
        {(['dehumidifier','air_mover','air_scrubber','heater','moisture_meter','thermal_camera','hydroxyl_generator','negative_air_machine','other'] as EquipmentType[]).map(t => (
          <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>
        ))}
      </select>
      <div className="grid grid-cols-2 gap-2">
        <input placeholder="Area deployed" value={area} onChange={e => setArea(e.target.value)}
          className="text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main focus:outline-none focus:ring-1 focus:ring-accent" />
        <input placeholder="Serial # (optional)" value={serial} onChange={e => setSerial(e.target.value)}
          className="text-sm px-3 py-2 rounded-lg border border-main/10 bg-main text-main focus:outline-none focus:ring-1 focus:ring-accent" />
      </div>
      <div className="flex justify-end">
        <Button size="sm" onClick={handleSave} loading={saving}>Deploy</Button>
      </div>
    </div>
  );
}

// ==================== TYPE METADATA ====================

function TypeMetadataSection({ jobType, metadata }: { jobType: JobType; metadata: InsuranceMetadata | WarrantyMetadata | Record<string, unknown> }) {
  const colors = JOB_TYPE_COLORS[jobType];

  if (jobType === 'insurance_claim') {
    const ins = metadata as InsuranceMetadata;
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <span className={cn('w-2 h-2 rounded-full', colors.dot)} />
            Insurance Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {ins.insuranceCompany && <MetaRow label="Company" value={ins.insuranceCompany} />}
          {ins.claimNumber && <MetaRow label="Claim #" value={ins.claimNumber} />}
          {ins.policyNumber && <MetaRow label="Policy #" value={ins.policyNumber} />}
          {ins.dateOfLoss && <MetaRow label="Date of Loss" value={ins.dateOfLoss} />}
          {ins.adjustorName && <MetaRow label="Adjuster" value={ins.adjustorName} />}
          {ins.adjustorPhone && <MetaRow label="Adjuster Phone" value={ins.adjustorPhone} />}
          {ins.deductible != null && <MetaRow label="Deductible" value={formatCurrency(ins.deductible)} />}
          {ins.coveredAmount != null && <MetaRow label="Covered Amount" value={formatCurrency(ins.coveredAmount)} />}
          {ins.approvalStatus && (
            <div className="flex justify-between text-sm">
              <span className="text-muted">Approval</span>
              <span className={cn('font-medium capitalize',
                ins.approvalStatus === 'approved' ? 'text-emerald-600 dark:text-emerald-400' :
                ins.approvalStatus === 'denied' ? 'text-red-600 dark:text-red-400' :
                'text-amber-600 dark:text-amber-400'
              )}>
                {ins.approvalStatus}
              </span>
            </div>
          )}
        </CardContent>
      </Card>
    );
  }

  if (jobType === 'warranty_dispatch') {
    const war = metadata as WarrantyMetadata;
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <span className={cn('w-2 h-2 rounded-full', colors.dot)} />
            Warranty Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {war.warrantyCompany && <MetaRow label="Company" value={war.warrantyCompany} />}
          {war.dispatchNumber && <MetaRow label="Dispatch #" value={war.dispatchNumber} />}
          {war.warrantyType && <MetaRow label="Type" value={war.warrantyType.replace(/_/g, ' ')} />}
          {war.authorizationLimit != null && <MetaRow label="Auth Limit" value={formatCurrency(war.authorizationLimit)} />}
          {war.notToExceed != null && <MetaRow label="NTE" value={formatCurrency(war.notToExceed)} />}
          {war.contractNumber && <MetaRow label="Contract #" value={war.contractNumber} />}
          {war.expirationDate && <MetaRow label="Expires" value={war.expirationDate} />}
        </CardContent>
      </Card>
    );
  }

  return null;
}

function MetaRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between text-sm">
      <span className="text-muted">{label}</span>
      <span className="text-main font-medium">{value}</span>
    </div>
  );
}
