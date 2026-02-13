'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  ClipboardList,
  Plus,
  Filter,
  Clock,
  AlertTriangle,
  CheckCircle2,
  Phone,
  MapPin,
  DollarSign,
  ChevronRight,
  X,
  Save,
  ArrowLeft,
  AlertCircle,
  Droplets,
  Flame,
  Wind,
  CloudRain,
  CloudHail,
  Bug,
  ShieldAlert,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useTpaAssignments,
  createTpaAssignment,
  getSlaStatus,
  formatTimeRemaining,
  type TpaAssignmentData,
  type TpaAssignmentStatus,
  type TpaLossType,
} from '@/lib/hooks/use-tpa-assignments';
import { useTpaPrograms, type TpaProgramData } from '@/lib/hooks/use-tpa-programs';

// ==================== CONSTANTS ====================

const STATUS_LABELS: Record<TpaAssignmentStatus, string> = {
  received: 'Received',
  contacted: 'Contacted',
  scheduled: 'Scheduled',
  onsite: 'On Site',
  inspecting: 'Inspecting',
  estimate_pending: 'Est. Pending',
  estimate_submitted: 'Est. Submitted',
  approved: 'Approved',
  in_progress: 'In Progress',
  supplement_pending: 'Supp. Pending',
  supplement_submitted: 'Supp. Submitted',
  drying: 'Drying',
  monitoring: 'Monitoring',
  completed: 'Completed',
  closed: 'Closed',
  declined: 'Declined',
  cancelled: 'Cancelled',
  reassigned: 'Reassigned',
};

const STATUS_VARIANTS: Record<string, string> = {
  received: 'bg-blue-500/10 text-blue-400',
  contacted: 'bg-sky-500/10 text-sky-400',
  scheduled: 'bg-indigo-500/10 text-indigo-400',
  onsite: 'bg-violet-500/10 text-violet-400',
  inspecting: 'bg-violet-500/10 text-violet-400',
  estimate_pending: 'bg-amber-500/10 text-amber-400',
  estimate_submitted: 'bg-amber-500/10 text-amber-400',
  approved: 'bg-emerald-500/10 text-emerald-400',
  in_progress: 'bg-cyan-500/10 text-cyan-400',
  supplement_pending: 'bg-orange-500/10 text-orange-400',
  supplement_submitted: 'bg-orange-500/10 text-orange-400',
  drying: 'bg-teal-500/10 text-teal-400',
  monitoring: 'bg-teal-500/10 text-teal-400',
  completed: 'bg-emerald-500/10 text-emerald-400',
  closed: 'bg-zinc-500/10 text-zinc-400',
  declined: 'bg-red-500/10 text-red-400',
  cancelled: 'bg-red-500/10 text-red-400',
  reassigned: 'bg-zinc-500/10 text-zinc-400',
};

const LOSS_TYPE_ICONS: Record<string, typeof Droplets> = {
  water: Droplets,
  fire: Flame,
  smoke: Flame,
  mold: Bug,
  storm: CloudRain,
  wind: Wind,
  hail: CloudHail,
  flood: Droplets,
  vandalism: ShieldAlert,
  biohazard: Bug,
};

const SLA_COLORS: Record<string, string> = {
  on_track: 'text-emerald-400',
  approaching: 'text-amber-400',
  overdue: 'text-red-400',
};

const SLA_BG: Record<string, string> = {
  on_track: 'bg-emerald-500/10',
  approaching: 'bg-amber-500/10',
  overdue: 'bg-red-500/10',
};

const LOSS_TYPES: { value: TpaLossType; label: string }[] = [
  { value: 'water', label: 'Water Damage' },
  { value: 'fire', label: 'Fire' },
  { value: 'smoke', label: 'Smoke' },
  { value: 'mold', label: 'Mold' },
  { value: 'storm', label: 'Storm' },
  { value: 'wind', label: 'Wind' },
  { value: 'hail', label: 'Hail' },
  { value: 'flood', label: 'Flood' },
  { value: 'vandalism', label: 'Vandalism' },
  { value: 'theft', label: 'Theft' },
  { value: 'biohazard', label: 'Biohazard' },
  { value: 'other', label: 'Other' },
];

// ==================== FORM STATE ====================

interface AssignmentFormState {
  tpaProgramId: string;
  assignmentNumber: string;
  claimNumber: string;
  policyNumber: string;
  carrierName: string;
  adjusterName: string;
  adjusterPhone: string;
  adjusterEmail: string;
  policyholderName: string;
  policyholderPhone: string;
  policyholderEmail: string;
  propertyAddress: string;
  propertyCity: string;
  propertyState: string;
  propertyZip: string;
  lossType: TpaLossType | '';
  lossDate: string;
  lossDescription: string;
  internalNotes: string;
}

const EMPTY_FORM: AssignmentFormState = {
  tpaProgramId: '',
  assignmentNumber: '',
  claimNumber: '',
  policyNumber: '',
  carrierName: '',
  adjusterName: '',
  adjusterPhone: '',
  adjusterEmail: '',
  policyholderName: '',
  policyholderPhone: '',
  policyholderEmail: '',
  propertyAddress: '',
  propertyCity: '',
  propertyState: '',
  propertyZip: '',
  lossType: '',
  lossDate: '',
  lossDescription: '',
  internalNotes: '',
};

// ==================== PAGE COMPONENT ====================

export default function TpaAssignmentsPage() {
  const { assignments, loading, error, refetch } = useTpaAssignments();
  const { programs } = useTpaPrograms();
  const router = useRouter();

  const [mode, setMode] = useState<'list' | 'create'>('list');
  const [statusFilter, setStatusFilter] = useState<TpaAssignmentStatus | ''>('');
  const [form, setForm] = useState<AssignmentFormState>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const updateField = useCallback(<K extends keyof AssignmentFormState>(key: K, value: AssignmentFormState[K]) => {
    setForm(prev => ({ ...prev, [key]: value }));
  }, []);

  const handleCreate = useCallback(() => {
    setForm({ ...EMPTY_FORM, tpaProgramId: programs[0]?.id ?? '' });
    setSaveError(null);
    setMode('create');
  }, [programs]);

  const handleSave = useCallback(async () => {
    if (!form.tpaProgramId) { setSaveError('Select a TPA program'); return; }
    setSaving(true);
    setSaveError(null);

    try {
      const id = await createTpaAssignment({
        tpaProgramId: form.tpaProgramId,
        assignmentNumber: form.assignmentNumber.trim() || undefined,
        claimNumber: form.claimNumber.trim() || undefined,
        policyNumber: form.policyNumber.trim() || undefined,
        carrierName: form.carrierName.trim() || undefined,
        adjusterName: form.adjusterName.trim() || undefined,
        adjusterPhone: form.adjusterPhone.trim() || undefined,
        adjusterEmail: form.adjusterEmail.trim() || undefined,
        policyholderName: form.policyholderName.trim() || undefined,
        policyholderPhone: form.policyholderPhone.trim() || undefined,
        policyholderEmail: form.policyholderEmail.trim() || undefined,
        propertyAddress: form.propertyAddress.trim() || undefined,
        propertyCity: form.propertyCity.trim() || undefined,
        propertyState: form.propertyState.trim() || undefined,
        propertyZip: form.propertyZip.trim() || undefined,
        lossType: (form.lossType as TpaLossType) || undefined,
        lossDate: form.lossDate || undefined,
        lossDescription: form.lossDescription.trim() || undefined,
        internalNotes: form.internalNotes.trim() || undefined,
      });

      setMode('list');
      refetch();
      router.push(`/dashboard/tpa/assignments/${id}`);
    } catch (e) {
      setSaveError(e instanceof Error ? e.message : 'Failed to create assignment');
    } finally {
      setSaving(false);
    }
  }, [form, refetch, router]);

  // Filter assignments
  const filteredAssignments = statusFilter
    ? assignments.filter(a => a.status === statusFilter)
    : assignments;

  // Summary counts
  const activeSlaViolations = assignments.filter(a =>
    getSlaStatus(a.firstContactDeadline, a.firstContactAt) === 'overdue' ||
    getSlaStatus(a.onsiteDeadline, a.onsiteAt) === 'overdue' ||
    getSlaStatus(a.estimateDeadline, a.estimateSubmittedAt) === 'overdue'
  ).length;

  const activeCount = assignments.filter(a => !['completed', 'closed', 'declined', 'cancelled', 'reassigned'].includes(a.status)).length;

  // ── Create Form ──

  if (mode === 'create') {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center gap-3">
          <button onClick={() => setMode('list')} className="p-1.5 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors">
            <ArrowLeft size={18} />
          </button>
          <div>
            <h1 className="text-xl font-semibold text-main">New TPA Assignment</h1>
            <p className="text-sm text-muted mt-0.5">Enter assignment details from TPA portal (manual entry only)</p>
          </div>
        </div>

        {saveError && (
          <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
            <AlertCircle size={16} className="flex-shrink-0" />
            {saveError}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Assignment Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><ClipboardList size={16} /> Assignment Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">TPA Program *</label>
                <select
                  value={form.tpaProgramId}
                  onChange={e => updateField('tpaProgramId', e.target.value)}
                  className="mt-1 w-full rounded-md border border-main/50 bg-transparent px-3 py-2 text-sm text-main focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                >
                  <option value="">Select program...</option>
                  {programs.map(p => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Assignment #</label>
                  <Input value={form.assignmentNumber} onChange={e => updateField('assignmentNumber', e.target.value)} placeholder="TPA-assigned ID" className="mt-1" />
                </div>
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Claim #</label>
                  <Input value={form.claimNumber} onChange={e => updateField('claimNumber', e.target.value)} placeholder="Claim number" className="mt-1" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Policy #</label>
                  <Input value={form.policyNumber} onChange={e => updateField('policyNumber', e.target.value)} placeholder="Policy number" className="mt-1" />
                </div>
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Carrier</label>
                  <Input value={form.carrierName} onChange={e => updateField('carrierName', e.target.value)} placeholder="Insurance carrier" className="mt-1" />
                </div>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Loss Type</label>
                <div className="flex flex-wrap gap-1.5 mt-1">
                  {LOSS_TYPES.map(lt => (
                    <button
                      key={lt.value}
                      onClick={() => updateField('lossType', form.lossType === lt.value ? '' : lt.value)}
                      className={cn(
                        'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors',
                        form.lossType === lt.value
                          ? 'border-accent bg-accent/10 text-accent'
                          : 'border-main/50 text-muted hover:border-main',
                      )}
                    >
                      {lt.label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Date of Loss</label>
                  <Input type="date" value={form.lossDate} onChange={e => updateField('lossDate', e.target.value)} className="mt-1" />
                </div>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Loss Description</label>
                <textarea
                  value={form.lossDescription}
                  onChange={e => updateField('lossDescription', e.target.value)}
                  placeholder="Describe the loss..."
                  rows={3}
                  className="mt-1 w-full rounded-md border border-main/50 bg-transparent px-3 py-2 text-sm text-main placeholder:text-muted/50 focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                />
              </div>
            </CardContent>
          </Card>

          {/* Contacts + Property */}
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2"><Phone size={16} /> Adjuster</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Input value={form.adjusterName} onChange={e => updateField('adjusterName', e.target.value)} placeholder="Adjuster name" />
                <div className="grid grid-cols-2 gap-3">
                  <Input value={form.adjusterPhone} onChange={e => updateField('adjusterPhone', e.target.value)} placeholder="Phone" />
                  <Input value={form.adjusterEmail} onChange={e => updateField('adjusterEmail', e.target.value)} placeholder="Email" type="email" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2"><Phone size={16} /> Policyholder</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Input value={form.policyholderName} onChange={e => updateField('policyholderName', e.target.value)} placeholder="Homeowner name" />
                <div className="grid grid-cols-2 gap-3">
                  <Input value={form.policyholderPhone} onChange={e => updateField('policyholderPhone', e.target.value)} placeholder="Phone" />
                  <Input value={form.policyholderEmail} onChange={e => updateField('policyholderEmail', e.target.value)} placeholder="Email" type="email" />
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2"><MapPin size={16} /> Property</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <Input value={form.propertyAddress} onChange={e => updateField('propertyAddress', e.target.value)} placeholder="Street address" />
                <div className="grid grid-cols-3 gap-3">
                  <Input value={form.propertyCity} onChange={e => updateField('propertyCity', e.target.value)} placeholder="City" />
                  <Input value={form.propertyState} onChange={e => updateField('propertyState', e.target.value)} placeholder="State" />
                  <Input value={form.propertyZip} onChange={e => updateField('propertyZip', e.target.value)} placeholder="Zip" />
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        <div className="flex items-center gap-3 pt-2">
          <Button onClick={handleSave} disabled={saving}>
            <Save size={16} className="mr-2" />
            {saving ? 'Creating...' : 'Create Assignment'}
          </Button>
          <Button variant="outline" onClick={() => setMode('list')} disabled={saving}>
            <X size={16} className="mr-2" />
            Cancel
          </Button>
        </div>
      </div>
    );
  }

  // ── List View ──

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold text-main">TPA Assignments</h1>
          <p className="text-sm text-muted mt-0.5">Track dispatched insurance restoration assignments</p>
        </div>
        <Button onClick={handleCreate}>
          <Plus size={16} className="mr-2" />
          New Assignment
        </Button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">Active</p>
            <p className="text-2xl font-semibold text-main mt-1">{activeCount}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">SLA Violations</p>
            <p className={cn('text-2xl font-semibold mt-1', activeSlaViolations > 0 ? 'text-red-400' : 'text-main')}>
              {activeSlaViolations}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">Total</p>
            <p className="text-2xl font-semibold text-main mt-1">{assignments.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <p className="text-xs text-muted uppercase tracking-wide">Programs</p>
            <p className="text-2xl font-semibold text-main mt-1">{programs.length}</p>
          </CardContent>
        </Card>
      </div>

      {/* Status Filter */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        <Filter size={14} className="text-muted flex-shrink-0" />
        <button
          onClick={() => setStatusFilter('')}
          className={cn(
            'px-2.5 py-1 rounded-full text-xs font-medium border whitespace-nowrap transition-colors',
            !statusFilter ? 'border-accent bg-accent/10 text-accent' : 'border-main/50 text-muted hover:border-main',
          )}
        >
          All
        </button>
        {['received', 'contacted', 'onsite', 'in_progress', 'drying', 'completed', 'closed'].map(s => (
          <button
            key={s}
            onClick={() => setStatusFilter(s as TpaAssignmentStatus)}
            className={cn(
              'px-2.5 py-1 rounded-full text-xs font-medium border whitespace-nowrap transition-colors',
              statusFilter === s ? 'border-accent bg-accent/10 text-accent' : 'border-main/50 text-muted hover:border-main',
            )}
          >
            {STATUS_LABELS[s as TpaAssignmentStatus]}
          </button>
        ))}
      </div>

      {/* Error */}
      {error && (
        <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
          <AlertCircle size={16} className="flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-20">
          <div className="w-6 h-6 border-2 border-accent border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* Empty */}
      {!loading && !error && filteredAssignments.length === 0 && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <ClipboardList size={48} className="text-muted/30 mb-4" />
            <h3 className="text-lg font-semibold text-main mb-1">No Assignments</h3>
            <p className="text-sm text-muted mb-6 max-w-md">
              {statusFilter ? 'No assignments match the selected filter.' : 'Enter your first TPA assignment from the TPA portal.'}
            </p>
            {!statusFilter && (
              <Button onClick={handleCreate}>
                <Plus size={16} className="mr-2" />
                New Assignment
              </Button>
            )}
          </CardContent>
        </Card>
      )}

      {/* Assignment Table */}
      {!loading && filteredAssignments.length > 0 && (
        <div className="space-y-2">
          {filteredAssignments.map(assignment => {
            const contactSla = getSlaStatus(assignment.firstContactDeadline, assignment.firstContactAt);
            const onsiteSla = getSlaStatus(assignment.onsiteDeadline, assignment.onsiteAt);
            const estimateSla = getSlaStatus(assignment.estimateDeadline, assignment.estimateSubmittedAt);
            const worstSla = [contactSla, onsiteSla, estimateSla].includes('overdue') ? 'overdue'
              : [contactSla, onsiteSla, estimateSla].includes('approaching') ? 'approaching'
              : 'on_track';
            const LossIcon = assignment.lossType ? LOSS_TYPE_ICONS[assignment.lossType] || AlertTriangle : AlertTriangle;

            return (
              <Link key={assignment.id} href={`/dashboard/tpa/assignments/${assignment.id}`}>
                <Card className={cn('group hover:border-accent/30 transition-colors cursor-pointer', worstSla === 'overdue' && 'border-red-500/30')}>
                  <CardContent className="p-4">
                    <div className="flex items-center gap-4">
                      {/* Loss type icon */}
                      <div className={cn('w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0', SLA_BG[worstSla])}>
                        <LossIcon size={18} className={SLA_COLORS[worstSla]} />
                      </div>

                      {/* Main info */}
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-semibold text-main truncate">
                            {assignment.claimNumber || assignment.assignmentNumber || 'No Number'}
                          </span>
                          <Badge variant="secondary" className={cn('text-[11px]', STATUS_VARIANTS[assignment.status])}>
                            {STATUS_LABELS[assignment.status]}
                          </Badge>
                          {assignment.program?.name && (
                            <span className="text-[11px] text-muted truncate hidden lg:inline">{assignment.program.name}</span>
                          )}
                        </div>
                        <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                          {assignment.policyholderName && <span>{assignment.policyholderName}</span>}
                          {assignment.propertyAddress && (
                            <span className="flex items-center gap-1 truncate">
                              <MapPin size={10} />
                              {assignment.propertyAddress}, {assignment.propertyCity}
                            </span>
                          )}
                          {assignment.lossType && (
                            <span className="capitalize">{assignment.lossType}</span>
                          )}
                        </div>
                      </div>

                      {/* SLA indicators */}
                      <div className="hidden md:flex items-center gap-4 flex-shrink-0">
                        <div className="text-right">
                          <p className="text-[10px] text-muted uppercase">Contact</p>
                          <p className={cn('text-xs font-medium', SLA_COLORS[contactSla])}>
                            {formatTimeRemaining(assignment.firstContactDeadline, assignment.firstContactAt)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-[10px] text-muted uppercase">Onsite</p>
                          <p className={cn('text-xs font-medium', SLA_COLORS[onsiteSla])}>
                            {formatTimeRemaining(assignment.onsiteDeadline, assignment.onsiteAt)}
                          </p>
                        </div>
                        <div className="text-right">
                          <p className="text-[10px] text-muted uppercase">Estimate</p>
                          <p className={cn('text-xs font-medium', SLA_COLORS[estimateSla])}>
                            {formatTimeRemaining(assignment.estimateDeadline, assignment.estimateSubmittedAt)}
                          </p>
                        </div>
                      </div>

                      {/* Financial */}
                      {assignment.totalEstimated > 0 && (
                        <div className="hidden xl:block text-right flex-shrink-0">
                          <p className="text-[10px] text-muted uppercase">Estimated</p>
                          <p className="text-sm font-medium text-main">
                            ${assignment.totalEstimated.toLocaleString()}
                          </p>
                        </div>
                      )}

                      <ChevronRight size={16} className="text-muted/30 group-hover:text-accent transition-colors flex-shrink-0" />
                    </div>
                  </CardContent>
                </Card>
              </Link>
            );
          })}
        </div>
      )}

      {/* Disclaimer */}
      <p className="text-[11px] text-muted/60 max-w-2xl">
        Assignment data is entered manually from TPA portals. ZAFTO does not scrape, automate, or directly interface with any TPA portal system.
      </p>
    </div>
  );
}
