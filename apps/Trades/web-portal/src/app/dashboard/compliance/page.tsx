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
  Plus,
  X,
  Edit,
  Trash2,
  RefreshCw,
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

const CATEGORY_CONFIG: Record<string, { label: string; icon: React.ComponentType<{ className?: string; size?: number }>; color: string }> = {
  license: { label: 'Licenses', icon: Award, color: 'text-blue-400' },
  insurance: { label: 'Insurance', icon: Shield, color: 'text-emerald-400' },
  bond: { label: 'Bonds', icon: Building, color: 'text-purple-400' },
  osha: { label: 'OSHA', icon: FileCheck, color: 'text-amber-400' },
  epa: { label: 'EPA', icon: FileCheck, color: 'text-green-400' },
  vehicle: { label: 'Vehicle', icon: FileCheck, color: 'text-cyan-400' },
  certification: { label: 'Certifications', icon: Award, color: 'text-indigo-400' },
  other: { label: 'Other', icon: FileCheck, color: 'text-zinc-400' },
};

const CATEGORY_OPTIONS = [
  { value: 'license', label: 'License' },
  { value: 'insurance', label: 'Insurance' },
  { value: 'bond', label: 'Bond' },
  { value: 'osha', label: 'OSHA' },
  { value: 'epa', label: 'EPA' },
  { value: 'vehicle', label: 'Vehicle' },
  { value: 'certification', label: 'Certification' },
  { value: 'other', label: 'Other' },
];

const STATUS_OPTIONS = [
  { value: 'active', label: 'Active' },
  { value: 'expired', label: 'Expired' },
  { value: 'pending_renewal', label: 'Pending Renewal' },
  { value: 'revoked', label: 'Revoked' },
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
    default: 'text-zinc-400',
  };
  const bgMap = {
    success: 'bg-emerald-500/10',
    warning: 'bg-amber-500/10',
    error: 'bg-red-500/10',
    default: 'bg-zinc-800',
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
            <p className="text-xs text-zinc-500">{label}</p>
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

export default function CompliancePage() {
  const { t, formatDate } = useTranslation();
  const { certifications, summary, loading, error, createCertification, updateCertification, deleteCertification } = useCompliance();
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
          <p className="text-sm text-muted mt-1">Licenses, insurance, bonds, OSHA, and regulatory compliance at a glance</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Certification
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label="Total Certifications" value={summary.totalCerts} icon={FileCheck} />
        <StatCard label="Active" value={summary.activeCerts} icon={CheckCircle} variant="success" />
        <StatCard label="Expired" value={summary.expiredCerts} icon={XCircle} variant="error" />
        <StatCard label="Expiring Soon" value={summary.expiringSoon} icon={AlertTriangle} variant="warning" />
        <StatCard
          label="Total Coverage"
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
              Expiring Within 30 Days ({expiringSoon.length})
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
                        {daysLeft} day{daysLeft !== 1 ? 's' : ''} left
                      </Badge>
                      <Button variant="ghost" size="sm" onClick={(e) => {
                        e.stopPropagation();
                        setEditingCert(cert);
                      }}>
                        <RefreshCw size={14} />
                        Renew
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
                <span className="text-sm font-medium text-main">{config.label}</span>
              </div>
              <div className="flex items-center gap-3 text-xs">
                <span className="text-emerald-400">{data.active} active</span>
                {data.expired > 0 && <span className="text-red-400">{data.expired} expired</span>}
                {data.expiringSoon > 0 && <span className="text-amber-400">{data.expiringSoon} expiring</span>}
              </div>
            </button>
          );
        })}
      </div>

      {/* Search + Status Filter */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          placeholder="Search certifications..."
          value={searchQuery}
          onChange={setSearchQuery}
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...STATUS_OPTIONS,
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
            <h3 className="text-lg font-medium text-main mb-2">No certifications found</h3>
            <p className="text-muted mb-4">
              {searchQuery ? 'Try adjusting your search' : 'Add certifications to track compliance'}
            </p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />
              Add Certification
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
                            {cert.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
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
                            <span>Exp: {formatDate(cert.expiration_date)}</span>
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
                          {daysLeft}d left
                        </Badge>
                      )}
                      {daysLeft !== null && daysLeft <= 0 && cert.status === 'active' && (
                        <Badge variant="error" size="sm">
                          Overdue
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
                  <p className="text-sm font-medium text-main">Annual Renewal Cost</p>
                  <p className="text-xs text-muted">Total cost to maintain all certifications</p>
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
            if (!confirm('Are you sure you want to remove this certification?')) return;
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
            <CardTitle>{isEdit ? 'Edit Certification' : 'Add Certification'}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input
            label="Certification Name *"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g., General Contractor License"
          />
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Category *</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                {CATEGORY_OPTIONS.map(o => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
            </div>
            <Input
              label="Type"
              value={type}
              onChange={(e) => setType(e.target.value)}
              placeholder="e.g., state_license"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Issuing Authority"
              value={issuingAuthority}
              onChange={(e) => setIssuingAuthority(e.target.value)}
              placeholder="e.g., State Board of Contractors"
            />
            <Input
              label="Certificate / License Number"
              value={certNumber}
              onChange={(e) => setCertNumber(e.target.value)}
              placeholder="e.g., GC-12345"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Policy Number"
              value={policyNumber}
              onChange={(e) => setPolicyNumber(e.target.value)}
              placeholder="Insurance policy #"
            />
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Status</label>
              <select
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
                value={status}
                onChange={(e) => setStatus(e.target.value as Certification['status'])}
              >
                {STATUS_OPTIONS.map(o => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Issued Date"
              type="date"
              value={issuedDate}
              onChange={(e) => setIssuedDate(e.target.value)}
            />
            <Input
              label="Expiration Date"
              type="date"
              value={expirationDate}
              onChange={(e) => setExpirationDate(e.target.value)}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Coverage Amount ($)"
              type="number"
              value={coverageAmount}
              onChange={(e) => setCoverageAmount(e.target.value)}
              placeholder="0.00"
            />
            <Input
              label="Annual Renewal Cost ($)"
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
              <span className="text-sm text-main">Renewal Required</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={autoRenew}
                onChange={(e) => setAutoRenew(e.target.checked)}
                className="rounded border-main"
              />
              <span className="text-sm text-main">Auto-Renew</span>
            </label>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea
              rows={3}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Additional notes about this certification..."
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
            />
          </div>
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim()}>
              {saving ? 'Saving...' : isEdit ? 'Update' : 'Add Certification'}
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
                    {cert.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                  </Badge>
                  <span className="text-xs text-muted">{config.label}</span>
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
                <p className="text-xs text-muted mb-1">Type</p>
                <p className="text-sm text-main">{cert.certification_type}</p>
              </div>
            )}
            {cert.issuing_authority && (
              <div>
                <p className="text-xs text-muted mb-1">Issuing Authority</p>
                <p className="text-sm text-main">{cert.issuing_authority}</p>
              </div>
            )}
            {cert.certification_number && (
              <div>
                <p className="text-xs text-muted mb-1">Certificate Number</p>
                <p className="text-sm text-main font-mono">{cert.certification_number}</p>
              </div>
            )}
            {cert.policy_number && (
              <div>
                <p className="text-xs text-muted mb-1">Policy Number</p>
                <p className="text-sm text-main font-mono">{cert.policy_number}</p>
              </div>
            )}
          </div>

          {/* Dates */}
          <div className="p-4 bg-secondary rounded-lg">
            <div className="grid grid-cols-2 gap-4">
              {cert.issued_date && (
                <div>
                  <p className="text-xs text-muted mb-1">Issued</p>
                  <p className="text-sm text-main">{formatDateLocale(cert.issued_date)}</p>
                </div>
              )}
              {cert.expiration_date && (
                <div>
                  <p className="text-xs text-muted mb-1">Expires</p>
                  <p className={cn('text-sm font-medium', daysLeft !== null && daysLeft <= 30 ? 'text-amber-400' : daysLeft !== null && daysLeft <= 0 ? 'text-red-400' : 'text-main')}>
                    {formatDateLocale(cert.expiration_date)}
                    {daysLeft !== null && daysLeft > 0 && (
                      <span className="text-xs text-muted ml-2">({daysLeft} days left)</span>
                    )}
                    {daysLeft !== null && daysLeft <= 0 && (
                      <span className="text-xs text-red-400 ml-2">(Expired)</span>
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
                  <p className="text-xs text-muted">Coverage Amount</p>
                </div>
              )}
              {cert.renewal_cost != null && cert.renewal_cost > 0 && (
                <div className="text-center p-3 bg-secondary rounded-lg">
                  <p className="text-lg font-semibold text-main">{formatCurrency(cert.renewal_cost)}</p>
                  <p className="text-xs text-muted">Renewal Cost</p>
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
              <span className="text-muted">Renewal Required</span>
            </div>
            <div className="flex items-center gap-2">
              {cert.auto_renew ? (
                <CheckCircle size={14} className="text-emerald-400" />
              ) : (
                <XCircle size={14} className="text-muted" />
              )}
              <span className="text-muted">Auto-Renew</span>
            </div>
          </div>

          {cert.notes && (
            <div>
              <p className="text-xs text-muted mb-1">Notes</p>
              <p className="text-sm text-main whitespace-pre-wrap">{cert.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button className="flex-1" onClick={() => { onClose(); onEdit(); }}>
              <Edit size={16} />
              Edit
            </Button>
            <Button variant="danger" onClick={onDelete}>
              <Trash2 size={16} />
              Remove
            </Button>
            <Button variant="ghost" onClick={onClose}>
              Close
            </Button>
          </div>
        </CardContent>
      </Card>
      </div>
    </div>
  );
}
