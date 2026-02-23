'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  FileText,
  Clock,
  RefreshCcw,
  DollarSign,
  AlertTriangle,
  Loader2,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useLeases } from '@/lib/hooks/use-leases';
import { leaseStatusLabels } from '@/lib/hooks/pm-mappers';
import type { LeaseData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type LeaseStatus = LeaseData['status'];

const statusConfig: Record<LeaseStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  active: { label: 'Active', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  expired: { label: 'Expired', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  terminated: { label: 'Terminated', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-900/30' },
  renewed: { label: 'Renewed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
};

const leaseTypeLabels: Record<LeaseData['leaseType'], string> = {
  fixed: 'Fixed Term',
  month_to_month: 'Month-to-Month',
  week_to_week: 'Week-to-Week',
};

function isExpiringSoon(lease: LeaseData, days: number = 30): boolean {
  if (lease.status !== 'active' || !lease.endDate) return false;
  const now = new Date();
  const endDate = new Date(lease.endDate);
  const diffMs = endDate.getTime() - now.getTime();
  const diffDays = diffMs / (1000 * 60 * 60 * 24);
  return diffDays >= 0 && diffDays <= days;
}

export default function LeasesPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { leases, loading, error } = useLeases();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');

  if (loading && leases.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-14" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-36 mb-2" /><div className="skeleton h-3 w-28" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  const filteredLeases = leases.filter((lease) => {
    const matchesSearch =
      (lease.tenantName || '').toLowerCase().includes(search.toLowerCase()) ||
      (lease.propertyAddress || '').toLowerCase().includes(search.toLowerCase()) ||
      (lease.unitNumber || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || lease.status === statusFilter;
    const matchesType = typeFilter === 'all' || lease.leaseType === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const activeCount = leases.filter((l) => l.status === 'active').length;
  const expiringCount = leases.filter((l) => isExpiringSoon(l, 30)).length;
  const monthToMonthCount = leases.filter((l) => l.status === 'active' && l.leaseType === 'month_to_month').length;
  const totalMonthlyRent = leases
    .filter((l) => l.status === 'active')
    .reduce((sum, l) => sum + l.rentAmount, 0);

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    ...Object.entries(leaseStatusLabels).map(([k, v]) => ({ value: k, label: v })),
  ];

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...Object.entries(leaseTypeLabels).map(([k, v]) => ({ value: k, label: v })),
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Leases</h1>
          <p className="text-muted mt-1">Manage tenant leases, renewals, and terms</p>
        </div>
        <Button onClick={() => router.push('/dashboard/properties/leases/new')}>
          <Plus size={16} />
          New Lease
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><FileText size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{activeCount}</p><p className="text-sm text-muted">Active Leases</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{expiringCount}</p><p className="text-sm text-muted">Expiring (30 days)</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><RefreshCcw size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{monthToMonthCount}</p><p className="text-sm text-muted">Month-to-Month</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg"><DollarSign size={20} className="text-cyan-600 dark:text-cyan-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{formatCurrency(totalMonthlyRent)}</p><p className="text-sm text-muted">Total Monthly Rent</p></div>
        </div></CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search leases..." className="sm:w-80" />
        <Select options={statusOptions} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
        <Select options={typeOptions} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
      </div>

      {/* Table */}
      <div className="bg-surface border border-main rounded-xl divide-y divide-main">
        {/* Header row */}
        <div className="hidden md:grid grid-cols-12 gap-4 px-6 py-3 text-sm font-medium text-muted">
          <div className="col-span-2">Tenant</div>
          <div className="col-span-3">Property / Unit</div>
          <div className="col-span-1 text-right">Rent</div>
          <div className="col-span-1">Start</div>
          <div className="col-span-1">End</div>
          <div className="col-span-1">Type</div>
          <div className="col-span-1">Status</div>
          <div className="col-span-1">Auto-Renew</div>
          <div className="col-span-1"></div>
        </div>

        {filteredLeases.map((lease) => {
          const sConfig = statusConfig[lease.status];
          const expiring = isExpiringSoon(lease, 30);

          return (
            <div
              key={lease.id}
              className={cn(
                'grid grid-cols-1 md:grid-cols-12 gap-4 px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors items-center',
                expiring && 'bg-amber-50/50 dark:bg-amber-900/5'
              )}
              onClick={() => router.push(`/dashboard/properties/leases/${lease.id}`)}
            >
              <div className="col-span-2">
                <p className={cn('font-medium text-main text-sm', expiring && 'text-amber-700 dark:text-amber-300')}>
                  {lease.tenantName || 'Unknown Tenant'}
                </p>
              </div>
              <div className="col-span-3">
                <p className="text-sm text-main">{lease.propertyAddress || 'N/A'}</p>
                {lease.unitNumber && <p className="text-xs text-muted">Unit {lease.unitNumber}</p>}
              </div>
              <div className="col-span-1 text-right">
                <p className="text-sm font-medium text-main">{formatCurrency(lease.rentAmount)}</p>
              </div>
              <div className="col-span-1">
                <p className="text-sm text-muted">{formatDate(lease.startDate)}</p>
              </div>
              <div className="col-span-1">
                <p className={cn('text-sm', expiring ? 'text-amber-600 dark:text-amber-400 font-medium' : 'text-muted')}>
                  {lease.endDate ? formatDate(lease.endDate) : 'Open'}
                </p>
              </div>
              <div className="col-span-1">
                <p className="text-xs text-muted">{leaseTypeLabels[lease.leaseType]}</p>
              </div>
              <div className="col-span-1">
                <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                  {sConfig.label}
                </span>
              </div>
              <div className="col-span-1">
                {lease.autoRenew ? (
                  <span className="text-xs text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                    <RefreshCcw size={12} />
                    Yes
                  </span>
                ) : (
                  <span className="text-xs text-muted">No</span>
                )}
              </div>
              <div className="col-span-1 text-right">
                {expiring && (
                  <span className="text-xs text-amber-600 dark:text-amber-400 flex items-center gap-1 justify-end">
                    <Clock size={12} />
                    Expiring
                  </span>
                )}
              </div>
            </div>
          );
        })}

        {filteredLeases.length === 0 && (
          <div className="px-6 py-12 text-center">
            <FileText size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No leases found</h3>
            <p className="text-muted mb-4">Create your first lease to start tracking rental agreements.</p>
            <Button onClick={() => router.push('/dashboard/properties/leases/new')}>
              <Plus size={16} />
              New Lease
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
