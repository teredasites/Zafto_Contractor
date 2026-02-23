'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import {
  Shield,
  Plus,
  Pencil,
  Trash2,
  X,
  Save,
  ArrowLeft,
  Globe,
  Phone,
  Mail,
  Clock,
  DollarSign,
  AlertCircle,
  CheckCircle2,
  Pause,
  ToggleLeft,
  ToggleRight,
  ExternalLink,
  Building2,
  Users,
  FileText,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';
import {
  useTpaPrograms,
  useTpaProgram,
  useCompanyFeatures,
  createTpaProgram,
  updateTpaProgram,
  deleteTpaProgram,
  toggleTpaFeature,
  type TpaProgramData,
  type TpaProgramType,
  type TpaProgramStatus,
  type ReferralFeeType,
} from '@/lib/hooks/use-tpa-programs';
import { useTranslation } from '@/lib/translations';

// ==================== CONSTANTS ====================

const TPA_TYPES: { value: TpaProgramType; label: string; description: string }[] = [
  { value: 'national', label: 'National', description: 'Nationwide TPA network (e.g., Contractor Connection, Accuserve)' },
  { value: 'regional', label: 'Regional', description: 'Regional network covering specific states' },
  { value: 'carrier_direct', label: 'Carrier Direct', description: 'Direct relationship with insurance carrier' },
  { value: 'independent', label: 'Independent', description: 'Independent adjuster or local program' },
];

const FEE_TYPES: { value: ReferralFeeType; label: string }[] = [
  { value: 'percentage', label: 'Percentage of Invoice' },
  { value: 'flat', label: 'Flat Fee per Job' },
  { value: 'tiered', label: 'Tiered (by volume)' },
  { value: 'none', label: 'No Fee' },
];

const LOSS_TYPES: { value: string; label: string }[] = [
  { value: 'water', label: 'Water Damage' },
  { value: 'fire', label: 'Fire/Smoke' },
  { value: 'mold', label: 'Mold Remediation' },
  { value: 'storm', label: 'Storm/Wind' },
  { value: 'hail', label: 'Hail' },
  { value: 'flood', label: 'Flood' },
  { value: 'biohazard', label: 'Biohazard' },
  { value: 'vandalism', label: 'Vandalism' },
  { value: 'theft', label: 'Theft' },
  { value: 'other', label: 'Other' },
];

const STATUS_CONFIG: Record<TpaProgramStatus, { label: string; variant: string; icon: typeof CheckCircle2 }> = {
  active: { label: 'Active', variant: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20', icon: CheckCircle2 },
  inactive: { label: 'Inactive', variant: 'bg-zinc-500/10 text-zinc-400 border-zinc-500/20', icon: Pause },
  suspended: { label: 'Suspended', variant: 'bg-red-500/10 text-red-400 border-red-500/20', icon: AlertCircle },
  pending_approval: { label: 'Pending', variant: 'bg-amber-500/10 text-amber-400 border-amber-500/20', icon: Clock },
};

function formatSla(minutes: number): string {
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  if (remaining === 0) return hours === 1 ? '1 hour' : `${hours} hours`;
  return `${hours}h ${remaining}m`;
}

// ==================== FORM STATE ====================

interface ProgramFormState {
  name: string;
  tpaType: TpaProgramType;
  carrierNames: string;
  referralFeeType: ReferralFeeType;
  referralFeePct: string;
  referralFeeFlat: string;
  paymentTermsDays: string;
  overheadPct: string;
  profitPct: string;
  slaFirstContactMinutes: string;
  slaOnsiteMinutes: string;
  slaEstimateMinutes: string;
  slaCompletionDays: string;
  portalUrl: string;
  portalUsername: string;
  primaryContactName: string;
  primaryContactPhone: string;
  primaryContactEmail: string;
  secondaryContactName: string;
  secondaryContactPhone: string;
  secondaryContactEmail: string;
  serviceArea: string;
  lossTypesCovered: string[];
  notes: string;
}

const EMPTY_FORM: ProgramFormState = {
  name: '',
  tpaType: 'national',
  carrierNames: '',
  referralFeeType: 'percentage',
  referralFeePct: '',
  referralFeeFlat: '',
  paymentTermsDays: '30',
  overheadPct: '10',
  profitPct: '10',
  slaFirstContactMinutes: '120',
  slaOnsiteMinutes: '1440',
  slaEstimateMinutes: '1440',
  slaCompletionDays: '5',
  portalUrl: '',
  portalUsername: '',
  primaryContactName: '',
  primaryContactPhone: '',
  primaryContactEmail: '',
  secondaryContactName: '',
  secondaryContactPhone: '',
  secondaryContactEmail: '',
  serviceArea: '',
  lossTypesCovered: [],
  notes: '',
};

function programToForm(p: TpaProgramData): ProgramFormState {
  return {
    name: p.name,
    tpaType: p.tpaType,
    carrierNames: p.carrierNames.join(', '),
    referralFeeType: p.referralFeeType,
    referralFeePct: p.referralFeePct?.toString() ?? '',
    referralFeeFlat: p.referralFeeFlat?.toString() ?? '',
    paymentTermsDays: p.paymentTermsDays.toString(),
    overheadPct: p.overheadPct.toString(),
    profitPct: p.profitPct.toString(),
    slaFirstContactMinutes: p.slaFirstContactMinutes.toString(),
    slaOnsiteMinutes: p.slaOnsiteMinutes.toString(),
    slaEstimateMinutes: p.slaEstimateMinutes.toString(),
    slaCompletionDays: p.slaCompletionDays.toString(),
    portalUrl: p.portalUrl ?? '',
    portalUsername: p.portalUsername ?? '',
    primaryContactName: p.primaryContactName ?? '',
    primaryContactPhone: p.primaryContactPhone ?? '',
    primaryContactEmail: p.primaryContactEmail ?? '',
    secondaryContactName: p.secondaryContactName ?? '',
    secondaryContactPhone: p.secondaryContactPhone ?? '',
    secondaryContactEmail: p.secondaryContactEmail ?? '',
    serviceArea: p.serviceArea ?? '',
    lossTypesCovered: p.lossTypesCovered,
    notes: p.notes ?? '',
  };
}

// ==================== PAGE COMPONENT ====================

export default function TpaProgramsPage() {
  const { t } = useTranslation();
  const { programs, loading, error, refetch } = useTpaPrograms();
  const { isTpaEnabled, loading: featuresLoading } = useCompanyFeatures();

  const [mode, setMode] = useState<'list' | 'create' | 'edit'>('list');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<ProgramFormState>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [deleting, setDeleting] = useState<string | null>(null);
  const [togglingFeature, setTogglingFeature] = useState(false);

  const updateField = useCallback(<K extends keyof ProgramFormState>(key: K, value: ProgramFormState[K]) => {
    setForm(prev => ({ ...prev, [key]: value }));
  }, []);

  const handleCreate = useCallback(() => {
    setForm(EMPTY_FORM);
    setEditingId(null);
    setSaveError(null);
    setMode('create');
  }, []);

  const handleEdit = useCallback((program: TpaProgramData) => {
    setForm(programToForm(program));
    setEditingId(program.id);
    setSaveError(null);
    setMode('edit');
  }, []);

  const handleCancel = useCallback(() => {
    setMode('list');
    setEditingId(null);
    setSaveError(null);
  }, []);

  const handleSave = useCallback(async () => {
    if (!form.name.trim()) {
      setSaveError('Program name is required');
      return;
    }

    setSaving(true);
    setSaveError(null);

    try {
      const payload = {
        name: form.name.trim(),
        tpaType: form.tpaType,
        carrierNames: form.carrierNames.split(',').map(s => s.trim()).filter(Boolean),
        referralFeeType: form.referralFeeType,
        referralFeePct: form.referralFeePct ? parseFloat(form.referralFeePct) : undefined,
        referralFeeFlat: form.referralFeeFlat ? parseFloat(form.referralFeeFlat) : undefined,
        paymentTermsDays: parseInt(form.paymentTermsDays) || 30,
        overheadPct: parseFloat(form.overheadPct) || 10,
        profitPct: parseFloat(form.profitPct) || 10,
        slaFirstContactMinutes: parseInt(form.slaFirstContactMinutes) || 120,
        slaOnsiteMinutes: parseInt(form.slaOnsiteMinutes) || 1440,
        slaEstimateMinutes: parseInt(form.slaEstimateMinutes) || 1440,
        slaCompletionDays: parseInt(form.slaCompletionDays) || 5,
        portalUrl: form.portalUrl.trim() || undefined,
        portalUsername: form.portalUsername.trim() || undefined,
        primaryContactName: form.primaryContactName.trim() || undefined,
        primaryContactPhone: form.primaryContactPhone.trim() || undefined,
        primaryContactEmail: form.primaryContactEmail.trim() || undefined,
        secondaryContactName: form.secondaryContactName.trim() || undefined,
        secondaryContactPhone: form.secondaryContactPhone.trim() || undefined,
        secondaryContactEmail: form.secondaryContactEmail.trim() || undefined,
        serviceArea: form.serviceArea.trim() || undefined,
        lossTypesCovered: form.lossTypesCovered,
        notes: form.notes.trim() || undefined,
      };

      if (mode === 'create') {
        await createTpaProgram(payload);
      } else if (editingId) {
        await updateTpaProgram(editingId, payload);
      }

      setMode('list');
      setEditingId(null);
      refetch();
    } catch (e) {
      setSaveError(e instanceof Error ? e.message : 'Failed to save program');
    } finally {
      setSaving(false);
    }
  }, [form, mode, editingId, refetch]);

  const handleDelete = useCallback(async (programId: string) => {
    setDeleting(programId);
    try {
      await deleteTpaProgram(programId);
      refetch();
    } catch {
      // Real-time subscription will refresh, error is transient
    } finally {
      setDeleting(null);
    }
  }, [refetch]);

  const handleToggleFeature = useCallback(async () => {
    setTogglingFeature(true);
    try {
      await toggleTpaFeature(!isTpaEnabled);
      // Force page reload to reflect feature flag changes in sidebar
      window.location.reload();
    } catch {
      // Graceful — user can retry
    } finally {
      setTogglingFeature(false);
    }
  }, [isTpaEnabled]);

  const toggleLossType = useCallback((value: string) => {
    setForm(prev => ({
      ...prev,
      lossTypesCovered: prev.lossTypesCovered.includes(value)
        ? prev.lossTypesCovered.filter(v => v !== value)
        : [...prev.lossTypesCovered, value],
    }));
  }, []);

  // ── Render ──

  if (mode === 'create' || mode === 'edit') {
    return (
      <div className="space-y-6 animate-fade-in">
        {/* Header */}
        <div className="flex items-center gap-3">
          <button onClick={handleCancel} className="p-1.5 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors">
            <ArrowLeft size={18} />
          </button>
          <div>
            <h1 className="text-xl font-semibold text-main">
              {mode === 'create' ? 'Enroll in TPA Program' : 'Edit TPA Program'}
            </h1>
            <p className="text-sm text-muted mt-0.5">
              {mode === 'create' ? 'Add a new Third-Party Administrator program enrollment' : 'Update program details and SLA settings'}
            </p>
          </div>
        </div>

        {saveError && (
          <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
            <AlertCircle size={16} className="flex-shrink-0" />
            {saveError}
          </div>
        )}

        {/* Form */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Program Identity */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><Shield size={16} /> Program Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Program Name *</label>
                <Input
                  value={form.name}
                  onChange={e => updateField('name', e.target.value)}
                  placeholder="e.g., Contractor Connection"
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Program Type</label>
                <div className="grid grid-cols-2 gap-2 mt-1">
                  {TPA_TYPES.map(t => (
                    <button
                      key={t.value}
                      onClick={() => updateField('tpaType', t.value)}
                      className={cn(
                        'p-2.5 rounded-lg border text-left text-sm transition-colors',
                        form.tpaType === t.value
                          ? 'border-accent bg-accent/5 text-main'
                          : 'border-main/50 text-muted hover:border-main hover:bg-surface-hover',
                      )}
                    >
                      <span className="font-medium block">{t.label}</span>
                      <span className="text-[11px] text-muted block mt-0.5">{t.description}</span>
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Carrier Names</label>
                <Input
                  value={form.carrierNames}
                  onChange={e => updateField('carrierNames', e.target.value)}
                  placeholder="State Farm, Allstate, USAA (comma-separated)"
                  className="mt-1"
                />
                <p className="text-[11px] text-muted mt-1">Insurance carriers served by this TPA</p>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">{t('settings.serviceArea')}</label>
                <Input
                  value={form.serviceArea}
                  onChange={e => updateField('serviceArea', e.target.value)}
                  placeholder="e.g., Tri-state area, Nationwide"
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Loss Types Covered</label>
                <div className="flex flex-wrap gap-1.5 mt-1">
                  {LOSS_TYPES.map(lt => (
                    <button
                      key={lt.value}
                      onClick={() => toggleLossType(lt.value)}
                      className={cn(
                        'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors',
                        form.lossTypesCovered.includes(lt.value)
                          ? 'border-accent bg-accent/10 text-accent'
                          : 'border-main/50 text-muted hover:border-main',
                      )}
                    >
                      {lt.label}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">{t('common.notes')}</label>
                <textarea
                  value={form.notes}
                  onChange={e => updateField('notes', e.target.value)}
                  placeholder="Internal notes about this program..."
                  rows={3}
                  className="mt-1 w-full rounded-md border border-main/50 bg-transparent px-3 py-2 text-sm text-main placeholder:text-muted/50 focus:border-accent focus:outline-none focus:ring-1 focus:ring-accent"
                />
              </div>
            </CardContent>
          </Card>

          {/* Financial Terms */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><DollarSign size={16} /> Financial Terms</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Referral Fee Type</label>
                <div className="grid grid-cols-2 gap-2 mt-1">
                  {FEE_TYPES.map(ft => (
                    <button
                      key={ft.value}
                      onClick={() => updateField('referralFeeType', ft.value)}
                      className={cn(
                        'px-3 py-2 rounded-lg border text-sm font-medium transition-colors',
                        form.referralFeeType === ft.value
                          ? 'border-accent bg-accent/5 text-main'
                          : 'border-main/50 text-muted hover:border-main hover:bg-surface-hover',
                      )}
                    >
                      {ft.label}
                    </button>
                  ))}
                </div>
              </div>
              {form.referralFeeType === 'percentage' && (
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Referral Fee %</label>
                  <Input
                    type="number"
                    step="0.5"
                    min="0"
                    max="100"
                    value={form.referralFeePct}
                    onChange={e => updateField('referralFeePct', e.target.value)}
                    placeholder="3.0"
                    className="mt-1"
                  />
                </div>
              )}
              {form.referralFeeType === 'flat' && (
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Flat Fee per Job ($)</label>
                  <Input
                    type="number"
                    step="1"
                    min="0"
                    value={form.referralFeeFlat}
                    onChange={e => updateField('referralFeeFlat', e.target.value)}
                    placeholder="150"
                    className="mt-1"
                  />
                </div>
              )}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Overhead %</label>
                  <Input
                    type="number"
                    step="0.5"
                    value={form.overheadPct}
                    onChange={e => updateField('overheadPct', e.target.value)}
                    placeholder="10"
                    className="mt-1"
                  />
                </div>
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Profit %</label>
                  <Input
                    type="number"
                    step="0.5"
                    value={form.profitPct}
                    onChange={e => updateField('profitPct', e.target.value)}
                    placeholder="10"
                    className="mt-1"
                  />
                </div>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Payment Terms (days)</label>
                <Input
                  type="number"
                  min="0"
                  value={form.paymentTermsDays}
                  onChange={e => updateField('paymentTermsDays', e.target.value)}
                  placeholder="30"
                  className="mt-1"
                />
              </div>
            </CardContent>
          </Card>

          {/* SLA Settings */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><Clock size={16} /> SLA Thresholds</CardTitle>
              <CardDescription>Service Level Agreement deadlines auto-calculate from assignment time</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">First Contact (min)</label>
                  <Input
                    type="number"
                    min="0"
                    value={form.slaFirstContactMinutes}
                    onChange={e => updateField('slaFirstContactMinutes', e.target.value)}
                    placeholder="120"
                    className="mt-1"
                  />
                  <p className="text-[11px] text-muted mt-1">Default: 2 hours</p>
                </div>
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Onsite Visit (min)</label>
                  <Input
                    type="number"
                    min="0"
                    value={form.slaOnsiteMinutes}
                    onChange={e => updateField('slaOnsiteMinutes', e.target.value)}
                    placeholder="1440"
                    className="mt-1"
                  />
                  <p className="text-[11px] text-muted mt-1">Default: 24 hours</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Estimate Due (min)</label>
                  <Input
                    type="number"
                    min="0"
                    value={form.slaEstimateMinutes}
                    onChange={e => updateField('slaEstimateMinutes', e.target.value)}
                    placeholder="1440"
                    className="mt-1"
                  />
                  <p className="text-[11px] text-muted mt-1">Default: 24 hours</p>
                </div>
                <div>
                  <label className="text-xs font-medium text-muted uppercase tracking-wide">Completion (days)</label>
                  <Input
                    type="number"
                    min="0"
                    value={form.slaCompletionDays}
                    onChange={e => updateField('slaCompletionDays', e.target.value)}
                    placeholder="5"
                    className="mt-1"
                  />
                  <p className="text-[11px] text-muted mt-1">Business days</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Portal & Contacts */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2"><Globe size={16} /> Portal & Contacts</CardTitle>
              <CardDescription>TPA portal access and program contacts</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Portal URL</label>
                <Input
                  value={form.portalUrl}
                  onChange={e => updateField('portalUrl', e.target.value)}
                  placeholder="https://portal.contractorconnection.com"
                  className="mt-1"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase tracking-wide">Portal Username</label>
                <Input
                  value={form.portalUsername}
                  onChange={e => updateField('portalUsername', e.target.value)}
                  placeholder="your-username"
                  className="mt-1"
                />
              </div>
              <div className="border-t border-main/30 pt-4">
                <span className="text-xs font-semibold text-muted uppercase tracking-wide">Primary Contact</span>
                <div className="grid grid-cols-1 gap-3 mt-2">
                  <Input
                    value={form.primaryContactName}
                    onChange={e => updateField('primaryContactName', e.target.value)}
                    placeholder="Contact name"
                  />
                  <Input
                    value={form.primaryContactPhone}
                    onChange={e => updateField('primaryContactPhone', e.target.value)}
                    placeholder="Phone"
                  />
                  <Input
                    value={form.primaryContactEmail}
                    onChange={e => updateField('primaryContactEmail', e.target.value)}
                    placeholder="Email"
                    type="email"
                  />
                </div>
              </div>
              <div className="border-t border-main/30 pt-4">
                <span className="text-xs font-semibold text-muted uppercase tracking-wide">Secondary Contact</span>
                <div className="grid grid-cols-1 gap-3 mt-2">
                  <Input
                    value={form.secondaryContactName}
                    onChange={e => updateField('secondaryContactName', e.target.value)}
                    placeholder="Contact name"
                  />
                  <Input
                    value={form.secondaryContactPhone}
                    onChange={e => updateField('secondaryContactPhone', e.target.value)}
                    placeholder="Phone"
                  />
                  <Input
                    value={form.secondaryContactEmail}
                    onChange={e => updateField('secondaryContactEmail', e.target.value)}
                    placeholder="Email"
                    type="email"
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Save / Cancel */}
        <div className="flex items-center gap-3 pt-2">
          <Button onClick={handleSave} disabled={saving}>
            <Save size={16} className="mr-2" />
            {saving ? 'Saving...' : mode === 'create' ? 'Enroll Program' : 'Save Changes'}
          </Button>
          <Button variant="secondary" onClick={handleCancel} disabled={saving}>
            <X size={16} className="mr-2" />
            Cancel
          </Button>
        </div>

        {/* Legal disclaimer */}
        <p className="text-[11px] text-muted/60 max-w-2xl">
          ZAFTO is not affiliated with, endorsed by, or sponsored by any TPA network, insurance carrier, or claims administrator listed above.
          Program names and carrier names are used solely for organizational purposes under nominative fair use.
        </p>
      </div>
    );
  }

  // ── List View ──

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            href="/dashboard/settings"
            className="p-1.5 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors"
          >
            <ArrowLeft size={18} />
          </Link>
          <div>
            <h1 className="text-xl font-semibold text-main">{t('settingsTpaPrograms.title')}</h1>
            <p className="text-sm text-muted mt-0.5">Manage Third-Party Administrator program enrollments</p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {/* Feature Flag Toggle */}
          <button
            onClick={handleToggleFeature}
            disabled={togglingFeature || featuresLoading}
            className={cn(
              'flex items-center gap-2 px-3 py-1.5 rounded-lg border text-sm font-medium transition-colors',
              isTpaEnabled
                ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400'
                : 'border-main/50 text-muted hover:border-main hover:bg-surface-hover',
            )}
          >
            {isTpaEnabled ? <ToggleRight size={18} /> : <ToggleLeft size={18} />}
            {isTpaEnabled ? 'TPA Enabled' : 'TPA Disabled'}
          </button>
          <Button onClick={handleCreate}>
            <Plus size={16} className="mr-2" />
            Add Program
          </Button>
        </div>
      </div>

      {/* Error State */}
      {error && (
        <div className="flex items-center gap-2 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
          <AlertCircle size={16} className="flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Loading State */}
      {loading && (
        <div className="flex items-center justify-center py-20">
          <div className="w-6 h-6 border-2 border-accent border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* Empty State */}
      {!loading && !error && programs.length === 0 && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16 text-center">
            <Shield size={48} className="text-muted/30 mb-4" />
            <h3 className="text-lg font-semibold text-main mb-1">No TPA Programs</h3>
            <p className="text-sm text-muted mb-6 max-w-md">
              Enroll in a TPA program to start receiving insurance restoration assignments.
              Configure SLA thresholds, referral fees, and contacts for each program.
            </p>
            <Button onClick={handleCreate}>
              <Plus size={16} className="mr-2" />
              Enroll in First Program
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Programs Grid */}
      {!loading && programs.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
          {programs.map(program => {
            const statusCfg = STATUS_CONFIG[program.status];
            const StatusIcon = statusCfg.icon;
            const isDeleting = deleting === program.id;

            return (
              <Card key={program.id} className="group relative">
                <CardContent className="p-5">
                  {/* Header row */}
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1 min-w-0">
                      <h3 className="text-base font-semibold text-main truncate">{program.name}</h3>
                      <div className="flex items-center gap-2 mt-1">
                        <Badge variant="secondary" className="text-[11px]">
                          {TPA_TYPES.find(t => t.value === program.tpaType)?.label ?? program.tpaType}
                        </Badge>
                        <Badge variant="secondary" className={cn('text-[11px]', statusCfg.variant)}>
                          <StatusIcon size={10} className="mr-1" />
                          {statusCfg.label}
                        </Badge>
                      </div>
                    </div>
                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={() => handleEdit(program)}
                        className="p-1.5 rounded-md text-muted hover:text-main hover:bg-surface-hover transition-colors"
                        title="Edit"
                      >
                        <Pencil size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(program.id)}
                        disabled={isDeleting}
                        className="p-1.5 rounded-md text-muted hover:text-red-400 hover:bg-red-500/10 transition-colors"
                        title="Remove"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>

                  {/* Carriers */}
                  {program.carrierNames.length > 0 && (
                    <div className="flex flex-wrap gap-1 mb-3">
                      {program.carrierNames.slice(0, 3).map(c => (
                        <span key={c} className="px-2 py-0.5 rounded-full bg-surface-hover text-[11px] text-muted">
                          {c}
                        </span>
                      ))}
                      {program.carrierNames.length > 3 && (
                        <span className="px-2 py-0.5 rounded-full bg-surface-hover text-[11px] text-muted">
                          +{program.carrierNames.length - 3}
                        </span>
                      )}
                    </div>
                  )}

                  {/* Key metrics row */}
                  <div className="grid grid-cols-3 gap-3 py-3 border-t border-main/20">
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">Fee</p>
                      <p className="text-sm font-medium text-main mt-0.5">
                        {program.referralFeeType === 'percentage' && program.referralFeePct != null
                          ? `${program.referralFeePct}%`
                          : program.referralFeeType === 'flat' && program.referralFeeFlat != null
                            ? `$${program.referralFeeFlat}`
                            : program.referralFeeType === 'none'
                              ? 'None'
                              : 'Tiered'}
                      </p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">{t('common.oAndP')}</p>
                      <p className="text-sm font-medium text-main mt-0.5">
                        {program.overheadPct}/{program.profitPct}
                      </p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">Net Terms</p>
                      <p className="text-sm font-medium text-main mt-0.5">
                        {program.paymentTermsDays}d
                      </p>
                    </div>
                  </div>

                  {/* SLA row */}
                  <div className="grid grid-cols-3 gap-3 py-3 border-t border-main/20">
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">{t('common.contact')}</p>
                      <p className="text-xs text-main mt-0.5">{formatSla(program.slaFirstContactMinutes)}</p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">{t('common.onsite')}</p>
                      <p className="text-xs text-main mt-0.5">{formatSla(program.slaOnsiteMinutes)}</p>
                    </div>
                    <div>
                      <p className="text-[11px] text-muted uppercase tracking-wide">{t('common.estimate')}</p>
                      <p className="text-xs text-main mt-0.5">{formatSla(program.slaEstimateMinutes)}</p>
                    </div>
                  </div>

                  {/* Contact */}
                  {program.primaryContactName && (
                    <div className="pt-3 border-t border-main/20">
                      <div className="flex items-center gap-2 text-sm text-muted">
                        <Users size={12} className="flex-shrink-0" />
                        <span className="truncate">{program.primaryContactName}</span>
                      </div>
                    </div>
                  )}

                  {/* Portal link */}
                  {program.portalUrl && (
                    <div className="pt-2">
                      <a
                        href={program.portalUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-1.5 text-xs text-accent hover:underline"
                      >
                        <ExternalLink size={11} />
                        Open Portal
                      </a>
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Legal disclaimer */}
      <p className="text-[11px] text-muted/60 max-w-2xl">
        ZAFTO is not affiliated with, endorsed by, or sponsored by any TPA network, insurance carrier, or claims administrator.
        Program names are used solely for organizational purposes under nominative fair use.
        Estimates represent the contractor&apos;s scope of work and professional assessment.
      </p>
    </div>
  );
}
