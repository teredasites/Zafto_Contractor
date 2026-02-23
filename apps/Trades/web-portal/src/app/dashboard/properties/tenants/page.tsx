'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Users,
  UserCheck,
  UserX,
  UserPlus,
  Mail,
  Phone,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { useTenants } from '@/lib/hooks/use-tenants';
import { useLeases } from '@/lib/hooks/use-leases';
import type { TenantData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

const tenantStatusLabels: Record<TenantData['status'], string> = {
  applicant: 'Applicant',
  active: 'Active',
  past: 'Past',
  evicted: 'Evicted',
};

const tenantStatusVariant: Record<TenantData['status'], 'info' | 'success' | 'secondary' | 'error'> = {
  applicant: 'info',
  active: 'success',
  past: 'secondary',
  evicted: 'error',
};

export default function TenantsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { tenants, loading } = useTenants();
  const { leases } = useLeases();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  const filteredTenants = tenants.filter((t) => {
    const searchStr = `${t.firstName} ${t.lastName} ${t.email ?? ''} ${t.phone ?? ''}`.toLowerCase();
    const matchesSearch = searchStr.includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || t.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const activeCount = tenants.filter((t) => t.status === 'active').length;
  const pastCount = tenants.filter((t) => t.status === 'past').length;
  const applicantCount = tenants.filter((t) => t.status === 'applicant').length;

  // Build tenant-to-unit mapping from active leases
  const tenantUnitMap = new Map<string, string>();
  leases.forEach((l) => {
    if (l.status === 'active' && l.tenantId) {
      const unitLabel = l.unitNumber ? `Unit ${l.unitNumber}` : '';
      const propLabel = l.propertyAddress ?? '';
      tenantUnitMap.set(l.tenantId, [unitLabel, propLabel].filter(Boolean).join(' @ '));
    }
  });

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-40 mb-2" />
          <div className="skeleton h-4 w-56" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-4">
              <div className="skeleton h-4 w-20 mb-2" />
              <div className="skeleton h-6 w-12" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1">
                <div className="skeleton h-4 w-32 mb-2" />
                <div className="skeleton h-3 w-48" />
              </div>
              <div className="skeleton h-4 w-20" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold text-main">{t('propertiesTenants.title')}</h1>
        <p className="text-[13px] text-muted mt-1">Manage tenants across all your properties</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Users size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{tenants.length}</p>
                <p className="text-sm text-muted">Total Tenants</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <UserCheck size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeCount}</p>
                <p className="text-sm text-muted">{t('common.active')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-slate-100 dark:bg-slate-800 rounded-lg">
                <UserX size={20} className="text-slate-600 dark:text-slate-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{pastCount}</p>
                <p className="text-sm text-muted">Past</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <UserPlus size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{applicantCount}</p>
                <p className="text-sm text-muted">Applicants</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search tenants..."
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(tenantStatusLabels).map(([value, label]) => ({ value, label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Tenants Table */}
      {filteredTenants.length === 0 ? (
        <div className="py-12 text-center">
          <Users size={48} className="mx-auto text-muted mb-3 opacity-50" />
          <p className="text-muted">No tenants found</p>
        </div>
      ) : (
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {filteredTenants.map((tenant) => {
            const unitInfo = tenantUnitMap.get(tenant.id);

            return (
              <div
                key={tenant.id}
                onClick={() => router.push(`/dashboard/properties/tenants/${tenant.id}`)}
                className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center flex-shrink-0">
                    <span className="text-sm font-semibold text-accent">
                      {tenant.firstName[0]}{tenant.lastName[0]}
                    </span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h4 className="font-medium text-main">
                        {tenant.firstName} {tenant.lastName}
                      </h4>
                      <Badge variant={tenantStatusVariant[tenant.status]} size="sm">
                        {tenantStatusLabels[tenant.status]}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4 mt-1 text-sm text-muted">
                      {tenant.email && (
                        <span className="flex items-center gap-1">
                          <Mail size={14} />
                          {tenant.email}
                        </span>
                      )}
                      {tenant.phone && (
                        <span className="flex items-center gap-1">
                          <Phone size={14} />
                          {tenant.phone}
                        </span>
                      )}
                    </div>
                  </div>
                  {unitInfo && (
                    <div className="text-right">
                      <p className="text-sm text-main font-medium">{unitInfo}</p>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
