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
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput } from '@/components/ui/input';
import { useTranslation } from '@/lib/translations';
import { useCompliance, type Certification, type ComplianceCategory } from '@/lib/hooks/use-compliance';

const CATEGORY_CONFIG: Record<string, { label: string; icon: React.ComponentType<{ className?: string }>; color: string }> = {
  license: { label: 'Licenses', icon: Award, color: 'text-blue-400' },
  insurance: { label: 'Insurance', icon: Shield, color: 'text-emerald-400' },
  bond: { label: 'Bonds', icon: Building, color: 'text-purple-400' },
  osha: { label: 'OSHA', icon: FileCheck, color: 'text-amber-400' },
  epa: { label: 'EPA', icon: FileCheck, color: 'text-green-400' },
  vehicle: { label: 'Vehicle', icon: FileCheck, color: 'text-cyan-400' },
  certification: { label: 'Certifications', icon: Award, color: 'text-indigo-400' },
  other: { label: 'Other', icon: FileCheck, color: 'text-zinc-400' },
};

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
  const { certifications, summary, loading, error } = useCompliance();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  const filtered = useMemo(() => {
    let certs = certifications;
    if (selectedCategory) {
      certs = certs.filter(c => (c.compliance_category || 'other') === selectedCategory);
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
  }, [certifications, selectedCategory, searchQuery]);

  const expiringSoon = useMemo(() => {
    const now = Date.now();
    const thirtyDays = 30 * 86400000;
    return certifications
      .filter(c => c.status === 'active' && c.expiration_date && (new Date(c.expiration_date).getTime() - now) <= thirtyDays && (new Date(c.expiration_date).getTime() - now) > 0)
      .sort((a, b) => new Date(a.expiration_date!).getTime() - new Date(b.expiration_date!).getTime());
  }, [certifications]);

  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <Card>
          <CardContent className="p-8 text-center">
            <p className="text-red-400 mb-2">Failed to load compliance data</p>
            <p className="text-sm text-zinc-500">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-white">{t('compliance.title')}</h1>
        <p className="text-sm text-zinc-400 mt-1">Licenses, insurance, bonds, OSHA, and regulatory compliance at a glance</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard label="Total Certifications" value={summary.totalCerts} icon={FileCheck} />
        <StatCard label={t('automations.active')} value={summary.activeCerts} icon={CheckCircle} variant="success" />
        <StatCard label={t('certifications.expired')} value={summary.expiredCerts} icon={XCircle} variant="error" />
        <StatCard label={t('certifications.expiring')} value={summary.expiringSoon} icon={AlertTriangle} variant="warning" />
        <StatCard
          label="Total Coverage"
          value={summary.totalCoverage > 0 ? `$${(summary.totalCoverage / 1000000).toFixed(1)}M` : '$0'}
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
                  <div key={cert.id} className="flex items-center justify-between py-2 border-b border-zinc-800 last:border-0">
                    <div className="flex items-center gap-3">
                      <div className="p-1.5 rounded bg-amber-500/10">
                        <Clock className="h-3.5 w-3.5 text-amber-400" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-white">{cert.certification_name}</p>
                        <p className="text-xs text-zinc-500">{cert.certification_type} - {cert.issuing_authority}</p>
                      </div>
                    </div>
                    <Badge variant="warning" size="sm">
                      {daysLeft} day{daysLeft !== 1 ? 's' : ''} left
                    </Badge>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Category Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        {Object.entries(summary.categories).map(([cat, data]) => {
          const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
          const Icon = config.icon;
          const isSelected = selectedCategory === cat;
          return (
            <button
              key={cat}
              onClick={() => setSelectedCategory(isSelected ? null : cat)}
              className={`p-4 rounded-xl border text-left transition-colors ${
                isSelected
                  ? 'border-blue-500/50 bg-blue-500/5'
                  : 'border-zinc-800 bg-zinc-900 hover:border-zinc-700'
              }`}
            >
              <div className="flex items-center gap-2 mb-2">
                <Icon className={`h-4 w-4 ${config.color}`} />
                <span className="text-sm font-medium text-white">{config.label}</span>
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

      {/* Search + List */}
      <div>
        <div className="mb-4">
          <SearchInput
            placeholder="Search certifications..."
            value={searchQuery}
            onChange={setSearchQuery}
          />
        </div>

        {filtered.length === 0 ? (
          <Card>
            <CardContent className="p-8 text-center">
              <Shield className="h-12 w-12 text-zinc-600 mx-auto mb-3" />
              <p className="text-zinc-400">{t('common.noCertificationsFound')}</p>
              <p className="text-sm text-zinc-500 mt-1">
                {searchQuery ? 'Try adjusting your search' : 'Add certifications to track compliance'}
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-2">
            {filtered.map((cert: Certification) => {
              const cat = cert.compliance_category || 'other';
              const config = CATEGORY_CONFIG[cat] || CATEGORY_CONFIG.other;
              const Icon = config.icon;

              return (
                <Card key={cert.id} className="hover:border-zinc-600 transition-colors">
                  <CardContent className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-zinc-800">
                          <Icon className={`h-4 w-4 ${config.color}`} />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h3 className="text-sm font-semibold text-white">{cert.certification_name}</h3>
                            <Badge variant={certStatusVariant(cert.status)} size="sm">
                              {cert.status.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}
                            </Badge>
                          </div>
                          <div className="flex items-center gap-3 mt-1 text-xs text-zinc-500">
                            <span>{cert.certification_type}</span>
                            {cert.issuing_authority && <span>{cert.issuing_authority}</span>}
                            {cert.certification_number && <span>#{cert.certification_number}</span>}
                          </div>
                        </div>
                      </div>
                      <div className="text-right text-xs">
                        {cert.expiration_date && (
                          <div className="flex items-center gap-1.5 text-zinc-400">
                            <Calendar className="h-3 w-3" />
                            <span>Exp: {formatDate(cert.expiration_date)}</span>
                          </div>
                        )}
                        {cert.coverage_amount != null && cert.coverage_amount > 0 && (
                          <div className="flex items-center gap-1.5 text-zinc-400 mt-1">
                            <DollarSign className="h-3 w-3" />
                            <span>${cert.coverage_amount.toLocaleString()}</span>
                          </div>
                        )}
                        {cert.policy_number && (
                          <p className="text-zinc-600 mt-1">Policy: {cert.policy_number}</p>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
