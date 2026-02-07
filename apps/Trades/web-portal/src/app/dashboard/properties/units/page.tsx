'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Home,
  DollarSign,
  Users,
  AlertCircle,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { formatCurrency, cn } from '@/lib/utils';
import { useUnits } from '@/lib/hooks/use-units';
import { unitStatusLabels } from '@/lib/hooks/pm-mappers';
import type { UnitData } from '@/lib/hooks/pm-mappers';
import type { UnitWithProperty } from '@/lib/hooks/use-units';

const unitStatusVariant: Record<UnitData['status'], 'success' | 'secondary' | 'error' | 'warning' | 'info' | 'purple'> = {
  occupied: 'success',
  vacant: 'error',
  maintenance: 'warning',
  listed: 'info',
  unit_turn: 'purple',
  rehab: 'warning',
};

export default function UnitsPage() {
  const router = useRouter();
  const { units, loading } = useUnits();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  const filteredUnits = units.filter((u) => {
    const searchStr = `${u.unitNumber} ${u.propertyAddress ?? ''}`.toLowerCase();
    const matchesSearch = searchStr.includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || u.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const occupiedCount = units.filter((u) => u.status === 'occupied').length;
  const vacantCount = units.filter((u) => u.status === 'vacant').length;
  const avgRent = units.length > 0
    ? units.reduce((sum, u) => sum + (u.marketRent ?? 0), 0) / units.length
    : 0;

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
        <h1 className="text-2xl font-semibold text-main">All Units</h1>
        <p className="text-[13px] text-muted mt-1">View and manage all units across your properties</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Home size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{units.length}</p>
                <p className="text-sm text-muted">Total Units</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Users size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{occupiedCount}</p>
                <p className="text-sm text-muted">Occupied</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <AlertCircle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{vacantCount}</p>
                <p className="text-sm text-muted">Vacant</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <DollarSign size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(avgRent)}</p>
                <p className="text-sm text-muted">Avg Rent</p>
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
          placeholder="Search units..."
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(unitStatusLabels).map(([value, label]) => ({ value, label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Units Table */}
      {filteredUnits.length === 0 ? (
        <div className="py-12 text-center">
          <Home size={48} className="mx-auto text-muted mb-3 opacity-50" />
          <p className="text-muted">No units found</p>
        </div>
      ) : (
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {/* Table Header */}
          <div className="px-6 py-3 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
            <div className="col-span-2">Unit</div>
            <div className="col-span-3">Property</div>
            <div className="col-span-2">Bed / Bath</div>
            <div className="col-span-1">Sq Ft</div>
            <div className="col-span-2 text-right">Market Rent</div>
            <div className="col-span-2 text-right">Status</div>
          </div>

          {/* Table Rows */}
          {filteredUnits.map((unit) => (
            <div
              key={unit.id}
              onClick={() => router.push(`/dashboard/properties/units/${unit.id}`)}
              className="px-6 py-4 grid grid-cols-12 gap-4 items-center hover:bg-surface-hover cursor-pointer transition-colors"
            >
              <div className="col-span-2">
                <p className="font-medium text-main">Unit {unit.unitNumber}</p>
              </div>
              <div className="col-span-3">
                <p className="text-sm text-muted truncate">{unit.propertyAddress ?? '--'}</p>
              </div>
              <div className="col-span-2">
                <p className="text-sm text-main">{unit.bedrooms} bd / {unit.bathrooms} ba</p>
              </div>
              <div className="col-span-1">
                <p className="text-sm text-main">{unit.squareFootage?.toLocaleString() ?? '--'}</p>
              </div>
              <div className="col-span-2 text-right">
                <p className="text-sm font-medium text-main">
                  {unit.marketRent ? formatCurrency(unit.marketRent) : '--'}
                </p>
              </div>
              <div className="col-span-2 text-right">
                <Badge variant={unitStatusVariant[unit.status]} size="sm">
                  {unitStatusLabels[unit.status]}
                </Badge>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
