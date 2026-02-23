'use client';

import { useState } from 'react';
import {
  Award, Search, Plus, AlertTriangle, CheckCircle2, Clock, XCircle,
  ChevronDown, ChevronRight, Calendar, User, Building2, FileText, Trash2,
} from 'lucide-react';
import { useCertifications, useCertificationTypes, type Certification, type CertificationTypeConfig } from '@/lib/hooks/use-enterprise';
import { useTeam } from '@/lib/hooks/use-jobs';
import { PermissionGate, PERMISSIONS } from '@/components/permission-gate';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

// ============================================================
// CERTIFICATION TYPES — loaded from certification_types table
// Companies can add custom types; system defaults always available
// ============================================================

// ============================================================
// STATUS HELPERS
// ============================================================

type FilterStatus = 'all' | 'active' | 'expiring' | 'expired' | 'revoked';

function getCertStatus(cert: Certification): 'active' | 'expiring' | 'expired' | 'revoked' {
  if (cert.status === 'revoked') return 'revoked';
  if (cert.status === 'expired') return 'expired';
  if (cert.expirationDate) {
    const exp = new Date(cert.expirationDate);
    const now = new Date();
    if (exp < now) return 'expired';
    const daysLeft = Math.ceil((exp.getTime() - now.getTime()) / 86400000);
    if (daysLeft <= cert.renewalReminderDays) return 'expiring';
  }
  return 'active';
}

function getDaysUntilExpiry(cert: Certification): number | null {
  if (!cert.expirationDate) return null;
  return Math.ceil((new Date(cert.expirationDate).getTime() - Date.now()) / 86400000);
}

const STATUS_CONFIG: Record<string, { label: string; color: string; icon: typeof CheckCircle2 }> = {
  active: { label: 'Active', color: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300', icon: CheckCircle2 },
  expiring: { label: 'Expiring Soon', color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300', icon: AlertTriangle },
  expired: { label: 'Expired', color: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300', icon: XCircle },
  revoked: { label: 'Revoked', color: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300', icon: XCircle },
  pending_renewal: { label: 'Pending Renewal', color: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300', icon: Clock },
};

// ============================================================
// MAIN PAGE
// ============================================================

export default function CertificationsPage() {
  const { t, formatDate } = useTranslation();
  const { certifications, loading, createCertification, updateCertification, deleteCertification } = useCertifications();
  const { types: certTypes, typeMap: certTypeMap, loading: typesLoading } = useCertificationTypes();
  const { team: members } = useTeam();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<FilterStatus>('all');
  const [showCreate, setShowCreate] = useState(false);
  const [editingCert, setEditingCert] = useState<Certification | null>(null);

  // Compute status for each cert
  const certsWithStatus = certifications.map(c => ({ ...c, computedStatus: getCertStatus(c) }));

  // Counts
  const counts = {
    all: certsWithStatus.length,
    active: certsWithStatus.filter(c => c.computedStatus === 'active').length,
    expiring: certsWithStatus.filter(c => c.computedStatus === 'expiring').length,
    expired: certsWithStatus.filter(c => c.computedStatus === 'expired').length,
    revoked: certsWithStatus.filter(c => c.computedStatus === 'revoked').length,
  };

  // Filter
  const filtered = certsWithStatus.filter(c => {
    if (statusFilter !== 'all' && c.computedStatus !== statusFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      const typeName = certTypeMap[c.certificationType]?.displayName || c.certificationType;
      return c.certificationName.toLowerCase().includes(q) ||
        typeName.toLowerCase().includes(q) ||
        (c.certificationNumber || '').toLowerCase().includes(q) ||
        (c.issuingAuthority || '').toLowerCase().includes(q);
    }
    return true;
  });

  // User name lookup
  const userMap = Object.fromEntries(members.map(m => [m.userId || m.id, m.name || m.email || 'Unknown']));

  if (loading || typesLoading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div className="flex items-center justify-between">
          <div className="h-8 w-48 bg-surface-hover animate-pulse rounded" />
          <div className="h-10 w-36 bg-surface-hover animate-pulse rounded-lg" />
        </div>
        <div className="grid grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-surface-hover animate-pulse rounded-xl" />)}
        </div>
        <div className="space-y-3">
          {[...Array(5)].map((_, i) => <div key={i} className="h-20 bg-surface-hover animate-pulse rounded-xl" />)}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-main">{t('certifications.title')}</h1>
          <p className="text-sm text-muted mt-1">Track employee licenses, certifications, and compliance</p>
        </div>
        <PermissionGate permission={PERMISSIONS.CERTIFICATIONS_MANAGE}>
          <Button onClick={() => { setEditingCert(null); setShowCreate(true); }} className="gap-2">
            <Plus size={16} /> Add Certification
          </Button>
        </PermissionGate>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <SummaryCard label="Total" count={counts.all} icon={Award} color="text-main" />
        <SummaryCard label="Active" count={counts.active} icon={CheckCircle2} color="text-emerald-500" />
        <SummaryCard label="Expiring Soon" count={counts.expiring} icon={AlertTriangle} color="text-amber-500" />
        <SummaryCard label="Expired" count={counts.expired + counts.revoked} icon={XCircle} color="text-red-500" />
      </div>

      {/* Search + Filter */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <input
            type="text"
            placeholder="Search by name, type, number, or issuer..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2.5 rounded-lg border border-border bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30"
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          {(['all', 'active', 'expiring', 'expired', 'revoked'] as FilterStatus[]).map(status => (
            <button
              key={status}
              onClick={() => setStatusFilter(status)}
              className={cn(
                'px-3 py-2 rounded-lg text-xs font-medium transition-colors border',
                statusFilter === status
                  ? 'bg-accent/10 text-accent border-accent/30'
                  : 'bg-surface text-muted border-border hover:text-main hover:bg-surface-hover'
              )}
            >
              {status === 'all' ? 'All' : STATUS_CONFIG[status]?.label || status}
              {status !== 'all' && <span className="ml-1.5 opacity-70">({counts[status]})</span>}
            </button>
          ))}
        </div>
      </div>

      {/* Certifications List */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-muted">
          <Award size={48} className="mb-4 opacity-30" />
          <p className="text-lg font-medium text-main mb-1">{t('common.noCertificationsFound')}</p>
          <p className="text-sm">{search || statusFilter !== 'all' ? 'Try adjusting your search or filters' : 'Add your first certification to start tracking compliance'}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(cert => {
            const typeDef = certTypeMap[cert.certificationType];
            const statusCfg = STATUS_CONFIG[cert.computedStatus];
            const days = getDaysUntilExpiry(cert);
            const userName = userMap[cert.userId] || 'Unassigned';

            return (
              <Card key={cert.id} hover className="cursor-pointer" onClick={() => { setEditingCert(cert); setShowCreate(true); }}>
                <CardContent className="p-4">
                  <div className="flex items-start gap-4">
                    <div className={cn('w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0',
                      cert.computedStatus === 'active' ? 'bg-emerald-100 dark:bg-emerald-900/30' :
                      cert.computedStatus === 'expiring' ? 'bg-amber-100 dark:bg-amber-900/30' :
                      'bg-red-100 dark:bg-red-900/30'
                    )}>
                      <Award size={20} className={cn(
                        cert.computedStatus === 'active' ? 'text-emerald-600 dark:text-emerald-400' :
                        cert.computedStatus === 'expiring' ? 'text-amber-600 dark:text-amber-400' :
                        'text-red-600 dark:text-red-400'
                      )} />
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-[15px] font-semibold text-main truncate">{cert.certificationName}</span>
                        <span className={cn('px-2 py-0.5 rounded-full text-[11px] font-medium', statusCfg.color)}>
                          {statusCfg.label}
                        </span>
                      </div>
                      <div className="flex items-center gap-4 text-xs text-muted flex-wrap">
                        <span className="flex items-center gap-1">
                          <FileText size={12} />
                          {typeDef?.displayName || cert.certificationType}
                        </span>
                        <span className="flex items-center gap-1">
                          <User size={12} />
                          {userName}
                        </span>
                        {cert.issuingAuthority && (
                          <span className="flex items-center gap-1">
                            <Building2 size={12} />
                            {cert.issuingAuthority}
                          </span>
                        )}
                        {cert.certificationNumber && (
                          <span className="flex items-center gap-1">
                            # {cert.certificationNumber}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-3 flex-shrink-0">
                      {days !== null && (
                        <div className={cn('text-right text-xs', days <= 0 ? 'text-red-500' : days <= 30 ? 'text-amber-500' : 'text-muted')}>
                          <div className="font-semibold">{days <= 0 ? `${Math.abs(days)}d overdue` : `${days}d left`}</div>
                          <div className="opacity-70">
                            {cert.expirationDate ? formatDate(cert.expirationDate) : ''}
                          </div>
                        </div>
                      )}
                      {!cert.expirationDate && (
                        <div className="text-xs text-muted">No expiration</div>
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

      {/* Create/Edit Modal */}
      {showCreate && (
        <CertificationModal
          cert={editingCert}
          members={members}
          certTypes={certTypes}
          onClose={() => { setShowCreate(false); setEditingCert(null); }}
          onCreate={createCertification}
          onUpdate={updateCertification}
          onDelete={deleteCertification}
        />
      )}
    </div>
  );
}

// ============================================================
// SUMMARY CARD
// ============================================================

function SummaryCard({ label, count, icon: Icon, color }: { label: string; count: number; icon: typeof Award; color: string }) {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-muted mb-1">{label}</p>
            <p className="text-2xl font-bold text-main">{count}</p>
          </div>
          <Icon size={24} className={cn('opacity-50', color)} />
        </div>
      </CardContent>
    </Card>
  );
}

// ============================================================
// CREATE / EDIT MODAL
// ============================================================

interface CertModalProps {
  cert: Certification | null;
  members: { id: string; userId?: string; name?: string; email?: string }[];
  certTypes: CertificationTypeConfig[];
  onClose: () => void;
  onCreate: (data: Partial<Certification>) => Promise<string>;
  onUpdate: (id: string, data: Partial<Certification>) => Promise<void>;
  onDelete: (id: string) => Promise<void>;
}

function CertificationModal({ cert, members, certTypes, onClose, onCreate, onUpdate, onDelete }: CertModalProps) {
  const { t: tr } = useTranslation();
  const isEdit = !!cert;
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [certType, setCertType] = useState(cert?.certificationType || '');
  const [name, setName] = useState(cert?.certificationName || '');
  const [userId, setUserId] = useState(cert?.userId || '');
  const [authority, setAuthority] = useState(cert?.issuingAuthority || '');
  const [certNumber, setCertNumber] = useState(cert?.certificationNumber || '');
  const [issuedDate, setIssuedDate] = useState(cert?.issuedDate || '');
  const [expirationDate, setExpirationDate] = useState(cert?.expirationDate || '');
  const [renewalRequired, setRenewalRequired] = useState(cert?.renewalRequired ?? true);
  const [renewalDays, setRenewalDays] = useState(cert?.renewalReminderDays ?? 30);
  const [status, setStatus] = useState<Certification['status']>(cert?.status || 'active');
  const [notes, setNotes] = useState(cert?.notes || '');

  // Auto-fill name/authority/renewal from type selection
  const certTypeMap = Object.fromEntries(certTypes.map(t => [t.typeKey, t]));
  const handleTypeChange = (val: string) => {
    setCertType(val);
    const def = certTypeMap[val];
    if (def) {
      if (!name) setName(def.displayName);
      if (!authority && def.regulationReference) setAuthority(def.regulationReference);
      setRenewalRequired(def.defaultRenewalRequired);
      setRenewalDays(def.defaultRenewalDays || 30);
    }
  };

  const handleSave = async () => {
    if (!name.trim() || !certType || !userId) {
      setError('Name, type, and employee are required');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const payload: Partial<Certification> = {
        certificationType: certType,
        certificationName: name.trim(),
        userId,
        issuingAuthority: authority.trim() || null,
        certificationNumber: certNumber.trim() || null,
        issuedDate: issuedDate || null,
        expirationDate: expirationDate || null,
        renewalRequired,
        renewalReminderDays: renewalDays,
        status,
        notes: notes.trim() || null,
      };
      if (isEdit && cert) {
        await onUpdate(cert.id, payload);
      } else {
        await onCreate(payload);
      }
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!cert || !confirm('Delete this certification? This cannot be undone.')) return;
    setDeleting(true);
    try {
      await onDelete(cert.id);
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to delete');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative w-full max-w-lg bg-surface rounded-2xl border border-border shadow-2xl max-h-[90vh] overflow-y-auto mx-4">
        <div className="sticky top-0 bg-surface border-b border-border px-6 py-4 rounded-t-2xl">
          <h2 className="text-lg font-bold text-main">{isEdit ? 'Edit Certification' : 'Add Certification'}</h2>
          <p className="text-xs text-muted mt-0.5">Track trade licenses, safety certs, and compliance credentials</p>
        </div>

        <div className="px-6 py-4 space-y-4">
          {error && (
            <div className="px-3 py-2 rounded-lg bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 text-sm">{error}</div>
          )}

          {/* Employee */}
          <div>
            <label className="text-xs font-medium text-muted mb-1.5 block">Employee *</label>
            <select value={userId} onChange={e => setUserId(e.target.value)}
              className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/30">
              <option value="">Select employee...</option>
              {members.map(m => (
                <option key={m.id} value={m.userId || m.id}>{m.name || m.email}</option>
              ))}
            </select>
          </div>

          {/* Certification Type */}
          <div>
            <label className="text-xs font-medium text-muted mb-1.5 block">Certification Type *</label>
            <select value={certType} onChange={e => handleTypeChange(e.target.value)}
              className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/30">
              <option value="">Select type...</option>
              {certTypes.map(t => (
                <option key={t.typeKey} value={t.typeKey}>{t.displayName}</option>
              ))}
            </select>
          </div>

          {/* Name */}
          <div>
            <label className="text-xs font-medium text-muted mb-1.5 block">Certification Name *</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. EPA 608 Universal"
              className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30" />
          </div>

          {/* Issuing Authority + Number */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted mb-1.5 block">{tr('permits.issuingAuthority')}</label>
              <input type="text" value={authority} onChange={e => setAuthority(e.target.value)} placeholder="e.g. EPA"
                className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30" />
            </div>
            <div>
              <label className="text-xs font-medium text-muted mb-1.5 block">Certificate Number</label>
              <input type="text" value={certNumber} onChange={e => setCertNumber(e.target.value)} placeholder="License #"
                className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30" />
            </div>
          </div>

          {/* Dates */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs font-medium text-muted mb-1.5 block">{tr('permits.issuedDate')}</label>
              <input type="date" value={issuedDate} onChange={e => setIssuedDate(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/30" />
            </div>
            <div>
              <label className="text-xs font-medium text-muted mb-1.5 block">{tr('warranties.expirationDate')}</label>
              <input type="date" value={expirationDate} onChange={e => setExpirationDate(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/30" />
            </div>
          </div>

          {/* Renewal Settings */}
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" checked={renewalRequired} onChange={e => setRenewalRequired(e.target.checked)}
                className="rounded border-border text-accent focus:ring-accent" />
              <span className="text-sm text-main">Renewal required</span>
            </label>
            {renewalRequired && (
              <div className="flex items-center gap-2">
                <span className="text-xs text-muted">Remind</span>
                <select value={renewalDays} onChange={e => setRenewalDays(Number(e.target.value))}
                  className="px-2 py-1 rounded border border-border bg-surface text-sm text-main">
                  <option value={30}>30</option>
                  <option value={60}>60</option>
                  <option value={90}>90</option>
                </select>
                <span className="text-xs text-muted">days before</span>
              </div>
            )}
          </div>

          {/* Status (edit only) */}
          {isEdit && (
            <div>
              <label className="text-xs font-medium text-muted mb-1.5 block">{tr('common.status')}</label>
              <select value={status} onChange={e => setStatus(e.target.value as Certification['status'])}
                className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main focus:outline-none focus:ring-2 focus:ring-accent/30">
                <option value="active">{tr('common.active')}</option>
                <option value="expired">{tr('common.expired')}</option>
                <option value="pending_renewal">Pending Renewal</option>
                <option value="revoked">Revoked</option>
              </select>
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="text-xs font-medium text-muted mb-1.5 block">{tr('common.notes')}</label>
            <textarea value={notes} onChange={e => setNotes(e.target.value)} rows={3} placeholder="Additional notes, renewal instructions, etc."
              className="w-full px-3 py-2.5 rounded-lg border border-border bg-surface text-sm text-main placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/30 resize-none" />
          </div>
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-surface border-t border-border px-6 py-4 rounded-b-2xl flex items-center justify-between">
          <div>
            {isEdit && (
              <button onClick={handleDelete} disabled={deleting}
                className="flex items-center gap-1.5 text-sm text-red-500 hover:text-red-600 disabled:opacity-50">
                <Trash2 size={14} /> {deleting ? 'Deleting...' : 'Delete'}
              </button>
            )}
          </div>
          <div className="flex gap-2">
            <Button onClick={onClose} className="bg-surface border border-border text-muted hover:text-main">{tr('common.cancel')}</Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? 'Saving...' : isEdit ? 'Update' : 'Add Certification'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
