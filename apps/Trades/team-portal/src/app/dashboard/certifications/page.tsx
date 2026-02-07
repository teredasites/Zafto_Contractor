'use client';

import { useState } from 'react';
import { Award, Search, CheckCircle2, AlertTriangle, XCircle, Clock, Calendar, Building2, FileText } from 'lucide-react';
import { useMyCertifications, useCertificationTypes } from '@/lib/hooks/use-certifications';
import type { CertificationData } from '@/lib/hooks/mappers';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';

// ============================================================
// CERTIFICATION TYPES — loaded dynamically from certification_types table
// ============================================================

// ============================================================
// STATUS HELPERS
// ============================================================

type FilterTab = 'all' | 'active' | 'expiring' | 'expired';

function getCertStatus(cert: CertificationData): 'active' | 'expiring' | 'expired' | 'revoked' {
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

function getDaysUntilExpiry(cert: CertificationData): number | null {
  if (!cert.expirationDate) return null;
  return Math.ceil((new Date(cert.expirationDate).getTime() - Date.now()) / 86400000);
}

const STATUS_STYLES: Record<string, { label: string; bg: string; text: string; icon: typeof CheckCircle2 }> = {
  active: { label: 'Active', bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-700 dark:text-emerald-300', icon: CheckCircle2 },
  expiring: { label: 'Expiring Soon', bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300', icon: AlertTriangle },
  expired: { label: 'Expired', bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-700 dark:text-red-300', icon: XCircle },
  revoked: { label: 'Revoked', bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-700 dark:text-red-300', icon: XCircle },
};

// ============================================================
// SKELETON
// ============================================================

function CertsSkeleton() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div className="h-8 w-40 bg-surface-hover animate-pulse rounded" />
      <div className="grid grid-cols-3 gap-4">
        {[...Array(3)].map((_, i) => <div key={i} className="h-20 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
      <div className="space-y-3">
        {[...Array(4)].map((_, i) => <div key={i} className="h-24 bg-surface-hover animate-pulse rounded-xl" />)}
      </div>
    </div>
  );
}

// ============================================================
// MAIN PAGE
// ============================================================

export default function CertificationsPage() {
  const { certifications, loading } = useMyCertifications();
  const { typeMap, loading: typesLoading } = useCertificationTypes();
  const [filter, setFilter] = useState<FilterTab>('all');
  const [search, setSearch] = useState('');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  if (loading || typesLoading) return <CertsSkeleton />;

  // Compute statuses
  const certsWithStatus = certifications.map(c => ({ ...c, computedStatus: getCertStatus(c) }));

  const counts = {
    all: certsWithStatus.length,
    active: certsWithStatus.filter(c => c.computedStatus === 'active').length,
    expiring: certsWithStatus.filter(c => c.computedStatus === 'expiring').length,
    expired: certsWithStatus.filter(c => c.computedStatus === 'expired' || c.computedStatus === 'revoked').length,
  };

  // Filter
  const filtered = certsWithStatus.filter(c => {
    if (filter === 'active' && c.computedStatus !== 'active') return false;
    if (filter === 'expiring' && c.computedStatus !== 'expiring') return false;
    if (filter === 'expired' && c.computedStatus !== 'expired' && c.computedStatus !== 'revoked') return false;
    if (search) {
      const q = search.toLowerCase();
      const typeLabel = typeMap[c.certificationType]?.displayName || c.certificationType;
      return c.certificationName.toLowerCase().includes(q) ||
        typeLabel.toLowerCase().includes(q) ||
        (c.certificationNumber || '').toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">My Certifications</h1>
        <p className="text-sm text-muted mt-1">Your licenses, certifications, and compliance credentials</p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <CheckCircle2 size={20} className="mx-auto mb-1.5 text-emerald-500" />
          <div className="text-2xl font-bold text-main">{counts.active}</div>
          <div className="text-xs text-muted">Active</div>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <AlertTriangle size={20} className="mx-auto mb-1.5 text-amber-500" />
          <div className="text-2xl font-bold text-main">{counts.expiring}</div>
          <div className="text-xs text-muted">Expiring Soon</div>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4 text-center">
          <XCircle size={20} className="mx-auto mb-1.5 text-red-500" />
          <div className="text-2xl font-bold text-main">{counts.expired}</div>
          <div className="text-xs text-muted">Expired</div>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          type="text"
          placeholder="Search certifications..."
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
          { key: 'expiring' as FilterTab, label: 'Expiring', count: counts.expiring },
          { key: 'expired' as FilterTab, label: 'Expired', count: counts.expired },
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

      {/* Certifications List */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <Award size={40} className="text-muted opacity-30 mb-3" />
          <p className="text-main font-medium">
            {counts.all === 0 ? 'No certifications on file' : 'No matching certifications'}
          </p>
          <p className="text-sm text-muted mt-1">
            {counts.all === 0 ? 'Your admin will add your certifications here' : 'Try adjusting your search or filter'}
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {filtered.map(cert => {
            const status = STATUS_STYLES[cert.computedStatus];
            const days = getDaysUntilExpiry(cert);
            const typeLabel = typeMap[cert.certificationType]?.displayName || cert.certificationType;
            const isExpanded = expandedId === cert.id;
            const StatusIcon = status.icon;

            return (
              <Card
                key={cert.id}
                className={cn('transition-all', isExpanded && 'ring-2 ring-accent/20')}
                onClick={() => setExpandedId(isExpanded ? null : cert.id)}
              >
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className={cn('w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0', status.bg)}>
                      <Award size={20} className={status.text} />
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className="text-[15px] font-semibold text-main truncate">{cert.certificationName}</span>
                        <span className={cn('px-2 py-0.5 rounded-full text-[11px] font-medium inline-flex items-center gap-1', status.bg, status.text)}>
                          <StatusIcon size={10} />
                          {status.label}
                        </span>
                      </div>
                      <div className="text-xs text-muted">{typeLabel}</div>
                    </div>

                    <div className="flex-shrink-0 text-right">
                      {days !== null ? (
                        <div className={cn('text-sm font-semibold',
                          days <= 0 ? 'text-red-500' : days <= 30 ? 'text-amber-500' : 'text-emerald-500'
                        )}>
                          {days <= 0 ? `${Math.abs(days)}d overdue` : `${days}d left`}
                        </div>
                      ) : (
                        <div className="text-xs text-muted">No expiration</div>
                      )}
                      {cert.expirationDate && (
                        <div className="text-[11px] text-muted">{new Date(cert.expirationDate).toLocaleDateString()}</div>
                      )}
                    </div>
                  </div>

                  {/* Expanded Detail */}
                  {isExpanded && (
                    <div className="mt-4 pt-4 border-t border-main space-y-2.5">
                      {cert.issuingAuthority && (
                        <DetailRow icon={Building2} label="Issuing Authority" value={cert.issuingAuthority} />
                      )}
                      {cert.certificationNumber && (
                        <DetailRow icon={FileText} label="Certificate Number" value={cert.certificationNumber} />
                      )}
                      {cert.issuedDate && (
                        <DetailRow icon={Calendar} label="Issued" value={new Date(cert.issuedDate).toLocaleDateString()} />
                      )}
                      {cert.expirationDate && (
                        <DetailRow icon={Calendar} label="Expires" value={new Date(cert.expirationDate).toLocaleDateString()} />
                      )}
                      {cert.renewalRequired && (
                        <DetailRow icon={Clock} label="Renewal Reminder" value={`${cert.renewalReminderDays} days before expiration`} />
                      )}
                      {cert.notes && (
                        <div className="pt-2">
                          <p className="text-xs text-muted mb-1">Notes</p>
                          <p className="text-sm text-main">{cert.notes}</p>
                        </div>
                      )}
                    </div>
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}

function DetailRow({ icon: Icon, label, value }: { icon: typeof Building2; label: string; value: string }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      <Icon size={14} className="text-muted flex-shrink-0" />
      <span className="text-muted">{label}:</span>
      <span className="text-main font-medium">{value}</span>
    </div>
  );
}
