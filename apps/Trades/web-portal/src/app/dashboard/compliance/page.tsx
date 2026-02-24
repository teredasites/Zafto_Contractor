'use client';

// L4: Compliance Dashboard — all company compliance at a glance
// Licenses, insurance, bonds, OSHA, EPA, vehicle regs. Expiration tracking.

import { useState, useMemo } from 'react';
import {
  Shield,
  FileCheck,
  AlertTriangle,
  CheckCircle,
  Clock,
  DollarSign,
  Calendar,
  Award,
  Building,
  XCircle,
  ChevronRight,
  ChevronDown,
  Plus,
  X,
  Edit,
  Trash2,
  RefreshCw,
  MapPin,
  ExternalLink,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input, Select, SearchInput } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { formatCompactCurrency, formatDateLocale } from '@/lib/format-locale';
import { useTranslation } from '@/lib/translations';
import { useCompliance, type Certification, type ComplianceCategory } from '@/lib/hooks/use-compliance';
import {
  STATE_LICENSING_CONFIGS,
  getStateLicensingConfig,
  getStatesRequiringStateLicense,
} from '@/lib/official-state-licensing';

const CATEGORY_CONFIG: Record<string, { tKey: string; icon: React.ComponentType<{ className?: string; size?: number }>; color: string }> = {
  license: { tKey: 'compliance.categoryLicenses', icon: Award, color: 'text-blue-400' },
  insurance: { tKey: 'compliance.categoryInsurance', icon: Shield, color: 'text-emerald-400' },
  bond: { tKey: 'compliance.categoryBonds', icon: Building, color: 'text-purple-400' },
  osha: { tKey: 'compliance.categoryOsha', icon: FileCheck, color: 'text-amber-400' },
  epa: { tKey: 'compliance.categoryEpa', icon: FileCheck, color: 'text-green-400' },
  vehicle: { tKey: 'compliance.categoryVehicle', icon: FileCheck, color: 'text-cyan-400' },
  certification: { tKey: 'compliance.categoryCertifications', icon: Award, color: 'text-indigo-400' },
  other: { tKey: 'compliance.categoryOther', icon: FileCheck, color: 'text-muted' },
};

const CATEGORY_OPTIONS = [
  { value: 'license', tKey: 'compliance.categoryLicense' },
  { value: 'insurance', tKey: 'compliance.categoryInsurance' },
  { value: 'bond', tKey: 'compliance.categoryBond' },
  { value: 'osha', tKey: 'compliance.categoryOsha' },
  { value: 'epa', tKey: 'compliance.categoryEpa' },
  { value: 'vehicle', tKey: 'compliance.categoryVehicle' },
  { value: 'certification', tKey: 'compliance.categoryCertification' },
  { value: 'other', tKey: 'compliance.categoryOther' },
];

const STATUS_OPTIONS = [
  { value: 'active', tKey: 'compliance.statusActive' },
  { value: 'expired', tKey: 'compliance.statusExpired' },
  { value: 'pending_renewal', tKey: 'compliance.statusPendingRenewal' },
  { value: 'revoked', tKey: 'compliance.statusRevoked' },
];

function StatCard({ label, value, icon: Icon, variant }: {
  label: string;
  value: string | number;
  icon: React.ComponentType<{ className?: string }>;
  variant?: 'success' | 'warning' | 'error' | 'default';
}) {
  const colorMap = {
    success: 'text-emerald-400',
    warning: 'text-amber-400',
    error: 'text-red-400',
    default: 'text-muted',
  };
  const bgMap = {
    success: 'bg-emerald-500/10',
    warning: 'bg-amber-500/10',
    error: 'bg-red-500/10',
    default: 'bg-secondary',
  };
  const v = variant || 'default';

  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${bgMap[v]}`}>
            <Icon className={`h-4 w-4 ${colorMap[v]}`} />
          </div>
          <div>
            <p className={`text-2xl font-bold ${colorMap[v]}`}>{value}</p>
            <p className="text-xs text-muted">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function certStatusVariant(status: string): 'success' | 'error' | 'warning' | 'secondary' {
  switch (status) {
    case 'active': return 'success';
    case 'expired': return 'error';
    case 'pending_renewal': return 'warning';
    case 'revoked': return 'error';
    default: return 'secondary';
  }
}

// ── State Licensing Reference (official 50-state data) ──
const LICENSING_STATES_SORTED = Object.values(STATE_LICENSING_CONFIGS).sort((a, b) => a.stateName.localeCompare(b.stateName));

function StateLicensingReference() {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);
  const [selectedState, setSelectedState] = useState<string | null>(null);
  const stateConfig = selectedState ? getStateLicensingConfig(selectedState) : null;

  const TRADE_NAME_MAP: Record<string, string> = {
    generalContractor: t('compliance.tradeGeneralContractor'),
    electrician: t('compliance.tradeElectrician'),
    plumber: t('compliance.tradePlumber'),
    hvac: t('compliance.tradeHvac'),
    roofing: t('compliance.tradeRoofing'),
  };

  return (
    <Card>
      <CardHeader>
        <button onClick={() => setExpanded(!expanded)} className="w-full flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <MapPin size={18} className="text-blue-400" />
            {t('compliance.stateLicensingTitle')}
          </CardTitle>
          {expanded ? <ChevronDown size={18} className="text-muted" /> : <ChevronRight size={18} className="text-muted" />}
        </button>
      </CardHeader>
      {expanded && (
        <CardContent className="space-y-4">
          <p className="text-sm text-muted">{t('compliance.stateLicensingDesc')}</p>
          <div className="flex flex-wrap gap-1.5">
            {LICENSING_STATES_SORTED.map(s => (
              <button
                key={s.stateCode}
                onClick={() => setSelectedState(selectedState === s.stateCode ? null : s.stateCode)}
                className={cn(
                  'px-2 py-1 text-xs rounded border transition-colors',
                  selectedState === s.stateCode
                    ? 'bg-blue-900/30 border-blue-700/50 text-blue-300'
                    : s.requiresStateLicense
                    ? 'bg-surface border-main text-main hover:border-muted'
                    : 'bg-surface border-main text-muted hover:border-muted'
                )}
              >
                {s.stateCode}
              </button>
            ))}
          </div>
          {stateConfig && (
            <div className="border border-main rounded-lg p-4 space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="font-semibold text-main">{stateConfig.stateName}</h4>
                <a href={stateConfig.boardUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-1 text-xs text-blue-400 hover:underline">
                  <ExternalLink size={12} /> {stateConfig.licensingBoard}
                </a>
              </div>
              <div className="flex flex-wrap gap-2">
                <Badge variant={stateConfig.requiresStateLicense ? 'warning' : 'secondary'} size="sm">
                  {stateConfig.licensingModel === 'state' ? t('compliance.stateLicenseRequired') : stateConfig.licensingModel === 'local' ? t('compliance.localOnly') : stateConfig.licensingModel === 'registration' ? t('compliance.registration') : t('compliance.hybrid')}
                </Badge>
                {stateConfig.examRequired && <Badge variant="info" size="sm">{t('compliance.examRequired')}</Badge>}
                {stateConfig.bondRequired && <Badge variant="purple" size="sm">{t('compliance.bondRequired')}</Badge>}
                {stateConfig.insuranceRequired && <Badge variant="info" size="sm">{t('compliance.insuranceRequired')}</Badge>}
                {stateConfig.ceRequired && <Badge variant="secondary" size="sm">{t('compliance.ceRequired')}</Badge>}
                {stateConfig.monetaryThreshold && <Badge variant="secondary" size="sm">{t('compliance.threshold', { amount: `$${stateConfig.monetaryThreshold.toLocaleString()}` })}</Badge>}
              </div>
              <div className="grid grid-cols-2 lg:grid-cols-5 gap-3 text-xs">
                {(['generalContractor', 'electrician', 'plumber', 'hvac', 'roofing'] as const).map(trade => {
                  const req = stateConfig[trade];
                  return (
                    <div key={trade} className="p-2 rounded border border-main">
                      <p className="font-medium text-main capitalize mb-1">{TRADE_NAME_MAP[trade] || trade}</p>
                      <Badge variant={req.requiresLicense ? 'warning' : 'success'} size="sm">
                        {req.requiresLicense ? t('compliance.licenseLevel', { level: req.licenseLevel }) : t('compliance.noLicense')}
                      </Badge>
                      {req.experienceYears && <p className="text-muted mt-1">{t('compliance.yrExp', { years: String(req.experienceYears) })}</p>}
                      {req.notes && <p className="text-muted mt-1 line-clamp-2">{req.notes}</p>}
                    </div>
                  );
                })}
              </div>
              {stateConfig.reciprocityStates.length > 0 && (
                <p className="text-xs text-muted">{t('compliance.reciprocity', { states: stateConfig.reciprocityStates.join(', ') })}</p>
              )}
              {stateConfig.specialNotes.length > 0 && (
                <div className="text-xs text-muted space-y-1">
                  {stateConfig.specialNotes.map((note, i) => <p key={i}>• {note}</p>)}
                </div>
              )}
            </div>
          )}
        </CardContent>
      )}
    </Card>
  );
}

export default function CompliancePage() {
  const { t, formatDate } = useTranslation();
  const { certifications, summary, loading, error, createCertification, updateCertification, deleteCertification } = useCompliance();

  const statusLabel = (status: string) => {
    const opt = STATUS_OPTIONS.find(o => o.value === status);
    return opt ? t(opt.tKey) : status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  };
  const categoryLabel = (key: string) => {
    const config = CATEGORY_CONFIG[key] || CATEGORY_CONFIG.other;
    return t(config.tKey);
  };
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedCert, setSelectedCert] = useState<Certification | null>(null);
  const [editingCert, setEditingCert] = useState<Certification | null>(null);

  const filtered = useMemo(() => {
    let certs = certifications;
    if (selectedCategory) {
      certs = certs.filter(c => (c.compliance_category || 'other') === selectedCategory);
    }
    if (statusFilter !== 'all') {
      certs = certs.filter(c => c.status === statusFilter);
    }
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      certs = certs.filter(c =>
        c.certification_name.toLowerCase().includes(q) ||
        c.certification_type.toLowerCase().includes(q) ||
        c.issuing_authority?.toLowerCase().includes(q) ||
        c.policy_number?.toLowerCase().includes(q)
      );
    }
    return certs;
  }, [certifications, selectedCategory, statusFilter, searchQuery]);

  const expiringSoon = useMemo(() => {
    const now = Date.now();
    const thirtyDays = 30 * 86400000;
    return certifications
      .filter(c => c.status === 'active' && c.expiration_date && (new Date(c.expiration_date).getTime() - now) <= thirtyDays && (new Date(c.expiration_date).getTime() - now) > 0)
      .sort((a, b) => new Date(a.expiration_date!).getTime() - new Date(b.expiration_date!).getTime());
  }, [certifications]);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
          {[...Array(5)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-4"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-4"><div className="skeleton h-4 w-24 mb-2" /><div className="skeleton h-3 w-16" /></div>)}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <Card>
          <CardContent className="p-8 text-center">
            <AlertTriangle size={48} className="mx-auto text-red-400 mb-4" />
            <p className="text-red-400 mb-2">{t('compliance.failedToLoadComplianceData')}</p>
            <p className="text-sm text-muted">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('compliance.title')}</h1>
          <p className="text-sm text-muted mt-1">{t('compliance.subtitle')}</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          {t('compliance.addCertification')}
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label={t('compliance.totalCertifications')} value={summary.totalCerts} icon={FileCheck} />
        <StatCard label={t('common.active')} value={summary.activeCerts} icon={CheckCircle} variant="success" />
        <StatCard label={t('compliance.expired')} value={summary.expiredCerts} icon={XCircle} variant="error" />
        <StatCard label={t('compliance.expiringSoon')} value={summary.expiringSoon} icon={AlertTriangle} variant="warning" />
        <StatCard
          label={t('compliance.totalCoverage')}
          value={summary.totalCoverage > 0 ? formatCompactCurrency(summary.totalCoverage) : '$0'}
          icon={Shield}
        />
      </div>

      {/* Expiring Soon Alert */}
      {expiringSoon.length > 0 && (
        <Card className="border-amber-500/30">
          <CardHeader className="pb-2">
            <CardTitle className="text-base text-amber-400 flex items-center gap-2">
              <AlertTriangle className="h-4 w-4" />
              {t('compliance.expiringWithinDays', { count: String(expiringSoon.length) })}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              {expiringSoon.map(cert => {
                const daysLeft = Math.ceil((new Date(cert.expiration_date!).getTime() - Date.now()) / 86400000);
                return (
                  <div
                    key={cert.id}
                    className="flex items-center justify-between py-2 border-b border-main last:border-0 cursor-pointer hover:bg-surface-hover rounded px-2 -mx-2 transition-colors"
                    onClick={() => setSelectedCert(cert)}
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-1.5 rounded bg-amber-500/10">
                        <Clock className="h-3.5 w-3.5 text-amber-400" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-main">{cert.certification_name}</p>
                        <p className="text-xs text-muted">{cert.certification_type} - {cert.issuing_authority}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge variant="warning" size="sm">
                        {t('compliance.daysLeft', { count: String(daysLeft) })}
                      </Badge>
                      <Button variant="ghost" size="sm" onClick={(e) => {
                        e.stopPropagation();
                        setEditingCert(cert);
                      }}>
                        <RefreshCw size={14} />
                        {t('compliance.renew')}
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Category Filter Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {Object.entries(summary.categories).map(([cat, data]) => {
          const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
          const Icon = config.icon;
          const isSelected = selectedCategory === cat;
          return (
            <button
              key={cat}
              onClick={() => setSelectedCategory(isSelected ? null : cat)}
              className={cn(
                'p-4 rounded-xl border text-left transition-colors',
                isSelected
                  ? 'border-accent bg-accent-light'
                  : 'border-main bg-surface hover:border-muted'
              )}
            >
              <div className="flex items-center gap-2 mb-2">
                <Icon className={`h-4 w-4 ${config.color}`} />
                <span className="text-sm font-medium text-main">{t(config.tKey)}</span>
              </div>
              <div className="flex items-center gap-3 text-xs">
                <span className="text-emerald-400">{t('compliance.nActive', { count: String(data.active) })}</span>
                {data.expired > 0 && <span className="text-red-400">{t('compliance.nExpired', { count: String(data.expired) })}</span>}
                {data.expiringSoon > 0 && <span className="text-amber-400">{t('compliance.nExpiring', { count: String(data.expiringSoon) })}</span>}
              </div>
            </button>
          );
        })}
      </div>

      {/* Search + Status Filter */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          placeholder={t('compliance.searchCertifications')}
          value={searchQuery}
          onChange={setSearchQuery}
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: t('compliance.allStatuses') },
            ...STATUS_OPTIONS.map(o => ({ value: o.value, label: t(o.tKey) })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Certifications List */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Shield size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('compliance.noCertificationsFound')}</h3>
            <p className="text-muted mb-4">
              {searchQuery ? t('compliance.tryAdjustingSearch') : t('compliance.addCertificationsToTrack')}
            </p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />
              {t('compliance.addCertification')}
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-2">
          {filtered.map((cert: Certification) => {
            const cat = cert.compliance_category || 'other';
            const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
            const Icon = config.icon;
            const daysLeft = cert.expiration_date
              ? Math.ceil((new Date(cert.expiration_date).getTime() - Date.now()) / 86400000)
              : null;

            return (
              <Card
                key={cert.id}
                className="hover:border-muted transition-colors cursor-pointer"
                onClick={() => setSelectedCert(cert)}
              >
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <div className="p-2 rounded-lg bg-secondary">
                        <Icon className={`h-4 w-4 ${config.color}`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <h3 className="text-sm font-semibold text-main truncate">{cert.certification_name}</h3>
                          <Badge variant={certStatusVariant(cert.status)} size="sm">
                            {statusLabel(cert.status)}
                          </Badge>
                        </div>
                        <div className="flex items-center gap-3 mt-1 text-xs text-muted">
                          <span>{cert.certification_type}</span>
                          {cert.issuing_authority && <span>{cert.issuing_authority}</span>}
                          {cert.certification_number && <span>#{cert.certification_number}</span>}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-right text-xs">
                        {cert.expiration_date && (
                          <div className="flex items-center gap-1.5 text-muted">
                            <Calendar className="h-3 w-3" />
                            <span>{t('compliance.expPrefix', { date: formatDate(cert.expiration_date) })}</span>
                          </div>
                        )}
                        {cert.coverage_amount != null && cert.coverage_amount > 0 && (
                          <div className="flex items-center gap-1.5 text-muted mt-1">
                            <DollarSign className="h-3 w-3" />
                            <span>{formatCurrency(cert.coverage_amount)}</span>
                          </div>
                        )}
                      </div>
                      {daysLeft !== null && daysLeft > 0 && daysLeft <= 30 && (
                        <Badge variant="warning" size="sm">
                          {t('compliance.daysLeftShort', { count: String(daysLeft) })}
                        </Badge>
                      )}
                      {daysLeft !== null && daysLeft <= 0 && cert.status === 'active' && (
                        <Badge variant="error" size="sm">
                          {t('compliance.overdue')}
                        </Badge>
                      )}
                      <ChevronRight size={16} className="text-muted" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* State Licensing Requirements — official data from 50 states */}
      <StateLicensingReference />

      {/* Annual Renewal Cost */}
      {summary.totalRenewalCost > 0 && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-purple-500/10">
                  <DollarSign className="h-4 w-4 text-purple-400" />
                </div>
                <div>
                  <p className="text-sm font-medium text-main">{t('compliance.annualRenewalCost')}</p>
                  <p className="text-xs text-muted">{t('compliance.totalCostToMaintain')}</p>
                </div>
              </div>
              <p className="text-xl font-semibold text-main">{formatCurrency(summary.totalRenewalCost)}</p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Add/Edit Modal */}
      {(showAddModal || editingCert) && (
        <CertificationFormModal
          cert={editingCert || undefined}
          onClose={() => { setShowAddModal(false); setEditingCert(null); }}
          onSave={async (data) => {
            if (editingCert) {
              await updateCertification(editingCert.id, data);
            } else {
              await createCertification(data);
            }
            setShowAddModal(false);
            setEditingCert(null);
          }}
        />
      )}

      {/* Detail Modal */}
      {selectedCert && !editingCert && (
        <CertificationDetailModal
          cert={selectedCert}
          onClose={() => setSelectedCert(null)}
          onEdit={() => { setEditingCert(selectedCert); }}
          onDelete={async () => {
            if (!confirm(t('compliance.confirmRemoveCertification'))) return;
            await deleteCertification(selectedCert.id);
            setSelectedCert(null);
          }}
        />
      )}
    </div>
  );
}

// ── Add/Edit Certification Modal ──
function CertificationFormModal({
  cert,
  onClose,
  onSave,
}: {
  cert?: Certification;
  onClose: () => void;
  onSave: (data: Partial<Certification>) => Promise<void>;
}) {
  const { t } = useTranslation();
  const isEdit = !!cert;
  const [saving, setSaving] = useState(false);
  const [name, setName] = useState(cert?.certification_name || '');
  const [type, setType] = useState(cert?.certification_type || 'license');
  const [category, setCategory] = useState(cert?.compliance_category || 'license');
  const [issuingAuthority, setIssuingAuthority] = useState(cert?.issuing_authority || '');
  const [certNumber, setCertNumber] = useState(cert?.certification_number || '');
  const [policyNumber, setPolicyNumber] = useState(cert?.policy_number || '');
  const [issuedDate, setIssuedDate] = useState(cert?.issued_date || '');
  const [expirationDate, setExpirationDate] = useState(cert?.expiration_date || '');
  const [status, setStatus] = useState(cert?.status || 'active');
  const [coverageAmount, setCoverageAmount] = useState(cert?.coverage_amount?.toString() || '');
  const [renewalCost, setRenewalCost] = useState(cert?.renewal_cost?.toString() || '');
  const [renewalRequired, setRenewalRequired] = useState(cert?.renewal_required ?? true);
  const [autoRenew, setAutoRenew] = useState(cert?.auto_renew ?? false);
  const [notes, setNotes] = useState(cert?.notes || '');

  const handleSubmit = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      await onSave({
        certification_name: name.trim(),
        certification_type: type,
        compliance_category: category,
        issuing_authority: issuingAuthority || null,
        certification_number: certNumber || null,
        policy_number: policyNumber || null,
        issued_date: issuedDate || null,
        expiration_date: expirationDate || null,
        status: status as Certification['status'],
        coverage_amount: coverageAmount ? parseFloat(coverageAmount) : null,
        renewal_cost: renewalCost ? parseFloat(renewalCost) : null,
        renewal_required: renewalRequired,
        auto_renew: autoRenew,
        notes: notes || null,
      });
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="w-full max-w-2xl max-h-[90vh] overflow-y-auto" onClick={(e: React.MouseEvent) => e.stopPropagation()}>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{isEdit ? t('compliance.editCertification') : t('compliance.addCertification')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input
            label={`${t('compliance.certificationName')} *`}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder={t('compliance.placeholderCertName')}
          />
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.category')} *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                {CATEGORY_OPTIONS.map(o => (
                  <option key={o.value} value={o.value}>{t(o.tKey)}</option>
                ))}
              </select>
            </div>
            <Input
              label={t('common.type')}
              value={type}
              onChange={(e) => setType(e.target.value)}
              placeholder={t('compliance.placeholderType')}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label={t('compliance.issuingAuthority')}
              value={issuingAuthority}
              onChange={(e) => setIssuingAuthority(e.target.value)}
              placeholder={t('compliance.placeholderAuthority')}
            />
            <Input
              label={t('compliance.certLicenseNumber')}
              value={certNumber}
              onChange={(e) => setCertNumber(e.target.value)}
              placeholder={t('compliance.placeholderCertNumber')}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label={t('compliance.policyNumber')}
              value={policyNumber}
              onChange={(e) => setPolicyNumber(e.target.value)}
              placeholder={t('compliance.placeholderPolicyNumber')}
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.status')}</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={status}
                onChange={(e) => setStatus(e.target.value as Certification['status'])}
              >
                {STATUS_OPTIONS.map(o => (
                  <option key={o.value} value={o.value}>{t(o.tKey)}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label={t('compliance.issuedDate')}
              type="date"
              value={issuedDate}
              onChange={(e) => setIssuedDate(e.target.value)}
            />
            <Input
              label={t('compliance.expirationDate')}
              type="date"
              value={expirationDate}
              onChange={(e) => setExpirationDate(e.target.value)}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label={t('compliance.coverageAmountLabel')}
              type="number"
              value={coverageAmount}
              onChange={(e) => setCoverageAmount(e.target.value)}
              placeholder="0.00"
            />
            <Input
              label={t('compliance.annualRenewalCostLabel')}
              type="number"
              value={renewalCost}
              onChange={(e) => setRenewalCost(e.target.value)}
              placeholder="0.00"
            />
          </div>
          <div className="flex items-center gap-6">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={renewalRequired}
                onChange={(e) => setRenewalRequired(e.target.checked)}
                className="rounded border-main"
              />
              <span className="text-sm text-main">{t('compliance.renewalRequired')}</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoRenew}
                onChange={(e) => setAutoRenew(e.target.checked)}
                className="rounded border-main"
              />
              <span className="text-sm text-main">{t('compliance.autoRenew')}</span>
            </label>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder={t('compliance.placeholderNotes')}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
            />
          </div>
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim()}>
              {saving ? t('common.saving') : isEdit ? t('common.update') : t('compliance.addCertification')}
            </Button>
          </div>
        </CardContent>
      </Card>
      </div>
    </div>
  );
}

// ── Certification Detail Modal ──
function CertificationDetailModal({
  cert,
  onClose,
  onEdit,
  onDelete,
}: {
  cert: Certification;
  onClose: () => void;
  onEdit: () => void;
  onDelete: () => Promise<void>;
}) {
  const { t } = useTranslation();
  const cat = cert.compliance_category || 'other';
  const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
  const Icon = config.icon;
  const daysLeft = cert.expiration_date
    ? Math.ceil((new Date(cert.expiration_date).getTime() - Date.now()) / 86400000)
    : null;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div className="w-full max-w-lg max-h-[90vh] overflow-y-auto" onClick={(e: React.MouseEvent) => e.stopPropagation()}>
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg bg-secondary`}>
                <Icon className={`h-5 w-5 ${config.color}`} />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-main">{cert.certification_name}</h2>
                <div className="flex items-center gap-2 mt-1">
                  <Badge variant={certStatusVariant(cert.status)} size="sm">
                    {(() => { const opt = STATUS_OPTIONS.find(o => o.value === cert.status); return opt ? t(opt.tKey) : cert.status; })()}
                  </Badge>
                  <span className="text-xs text-muted">{t(config.tKey)}</span>
                </div>
              </div>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Key details */}
          <div className="grid grid-cols-2 gap-4">
            {cert.certification_type && (
              <div>
                <p className="text-xs text-muted mb-1">{t('compliance.detailType')}</p>
                <p className="text-sm text-main">{cert.certification_type}</p>
              </div>
            )}
            {cert.issuing_authority && (
              <div>
                <p className="text-xs text-muted mb-1">{t('compliance.detailIssuingAuthority')}</p>
                <p className="text-sm text-main">{cert.issuing_authority}</p>
              </div>
            )}
            {cert.certification_number && (
              <div>
                <p className="text-xs text-muted mb-1">{t('compliance.detailCertificateNumber')}</p>
                <p className="text-sm text-main font-mono">{cert.certification_number}</p>
              </div>
            )}
            {cert.policy_number && (
              <div>
                <p className="text-xs text-muted mb-1">{t('compliance.detailPolicyNumber')}</p>
                <p className="text-sm text-main font-mono">{cert.policy_number}</p>
              </div>
            )}
          </div>

          {/* Dates */}
          <div className="p-4 bg-secondary rounded-lg">
            <div className="grid grid-cols-2 gap-4">
              {cert.issued_date && (
                <div>
                  <p className="text-xs text-muted mb-1">{t('compliance.detailIssued')}</p>
                  <p className="text-sm text-main">{formatDateLocale(cert.issued_date)}</p>
                </div>
              )}
              {cert.expiration_date && (
                <div>
                  <p className="text-xs text-muted mb-1">{t('compliance.detailExpires')}</p>
                  <p className={cn('text-sm font-medium', daysLeft !== null && daysLeft <= 30 ? 'text-amber-400' : daysLeft !== null && daysLeft <= 0 ? 'text-red-400' : 'text-main')}>
                    {formatDateLocale(cert.expiration_date)}
                    {daysLeft !== null && daysLeft > 0 && (
                      <span className="text-xs text-muted ml-2">{t('compliance.detailDaysLeft', { count: String(daysLeft) })}</span>
                    )}
                    {daysLeft !== null && daysLeft <= 0 && (
                      <span className="text-xs text-red-400 ml-2">{t('compliance.detailExpired')}</span>
                    )}
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Financial */}
          {(cert.coverage_amount || cert.renewal_cost) && (
            <div className="grid grid-cols-2 gap-4">
              {cert.coverage_amount != null && cert.coverage_amount > 0 && (
                <div className="text-center p-3 bg-secondary rounded-lg">
                  <p className="text-lg font-semibold text-main">{formatCurrency(cert.coverage_amount)}</p>
                  <p className="text-xs text-muted">{t('compliance.coverageAmount')}</p>
                </div>
              )}
              {cert.renewal_cost != null && cert.renewal_cost > 0 && (
                <div className="text-center p-3 bg-secondary rounded-lg">
                  <p className="text-lg font-semibold text-main">{formatCurrency(cert.renewal_cost)}</p>
                  <p className="text-xs text-muted">{t('compliance.renewalCost')}</p>
                </div>
              )}
            </div>
          )}

          {/* Flags */}
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              {cert.renewal_required ? (
                <CheckCircle size={14} className="text-emerald-400" />
              ) : (
                <XCircle size={14} className="text-muted" />
              )}
              <span className="text-muted">{t('compliance.renewalRequired')}</span>
            </div>
            <div className="flex items-center gap-2">
              {cert.auto_renew ? (
                <CheckCircle size={14} className="text-emerald-400" />
              ) : (
                <XCircle size={14} className="text-muted" />
              )}
              <span className="text-muted">{t('compliance.autoRenew')}</span>
            </div>
          </div>

          {cert.notes && (
            <div>
              <p className="text-xs text-muted mb-1">{t('common.notes')}</p>
              <p className="text-sm text-main whitespace-pre-wrap">{cert.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button className="flex-1" onClick={() => { onClose(); onEdit(); }}>
              <Edit size={16} />
              {t('common.edit')}
            </Button>
            <Button variant="danger" onClick={onDelete}>
              <Trash2 size={16} />
              {t('common.remove')}
            </Button>
            <Button variant="ghost" onClick={onClose}>
              {t('common.close')}
            </Button>
          </div>
        </CardContent>
      </Card>
      </div>
    </div>
  );
}
