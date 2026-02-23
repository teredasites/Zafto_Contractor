'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Building2,
  Home,
  DollarSign,
  Percent,
  Users,
  MapPin,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { formatCurrency, cn } from '@/lib/utils';
import { useProperties } from '@/lib/hooks/use-properties';
import type { PropertyStats } from '@/lib/hooks/use-properties';
import {
  formatPropertyAddress,
  propertyTypeLabels,
} from '@/lib/hooks/pm-mappers';
import type { PropertyData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

const propertyStatusLabels: Record<PropertyData['status'], string> = {
  active: 'Active',
  inactive: 'Inactive',
  sold: 'Sold',
  rehab: 'Rehab',
};

const statusVariant: Record<PropertyData['status'], 'success' | 'secondary' | 'error' | 'warning'> = {
  active: 'success',
  inactive: 'secondary',
  sold: 'error',
  rehab: 'warning',
};

export default function PropertiesPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { properties, loading, getPropertyStats, formatPropertyAddress: fmtAddr, propertyTypeLabels: typeLabels } = useProperties();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [stats, setStats] = useState<PropertyStats | null>(null);

  useEffect(() => {
    getPropertyStats().then(setStats).catch(() => {});
  }, [getPropertyStats]);

  const filteredProperties = properties.filter((p) => {
    const addr = formatPropertyAddress(p).toLowerCase();
    const matchesSearch = addr.includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || p.propertyType === typeFilter;
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
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
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-6">
              <div className="skeleton h-5 w-48 mb-3" />
              <div className="skeleton h-4 w-32 mb-2" />
              <div className="skeleton h-4 w-24" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('properties.title')}</h1>
          <p className="text-[13px] text-muted mt-1">Manage your property portfolio</p>
        </div>
        <Button onClick={() => router.push('/dashboard/properties/new')}>
          <Plus size={16} />
          Add Property
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Building2 size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats?.totalProperties ?? properties.length}</p>
                <p className="text-sm text-muted">Total Properties</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg">
                <Home size={20} className="text-indigo-600 dark:text-indigo-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats?.totalUnits ?? 0}</p>
                <p className="text-sm text-muted">{t('common.totalUnits')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Percent size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats?.occupancyRate?.toFixed(1) ?? '0.0'}%</p>
                <p className="text-sm text-muted">Occupancy Rate</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(stats?.totalRentCollected ?? 0)}</p>
                <p className="text-sm text-muted">Rent Collected</p>
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
          placeholder="Search properties..."
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Types' },
            ...Object.entries(propertyTypeLabels).map(([value, label]) => ({ value, label })),
          ]}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(propertyStatusLabels).map(([value, label]) => ({ value, label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Property Cards Grid */}
      {filteredProperties.length === 0 ? (
        <div className="py-12 text-center">
          <Building2 size={48} className="mx-auto text-muted mb-3 opacity-50" />
          <p className="text-muted">No properties found</p>
          <Button className="mt-4" onClick={() => router.push('/dashboard/properties/new')}>
            <Plus size={16} />
            Add Your First Property
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {filteredProperties.map((property) => (
            <PropertyCard
              key={property.id}
              property={property}
              onClick={() => router.push(`/dashboard/properties/${property.id}`)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function PropertyCard({ property, onClick }: { property: PropertyData; onClick: () => void }) {
  const occupiedCount = property.unitCount;
  const vacantEstimate = 0; // Actual vacancy comes from units query; shown as placeholder
  const monthlyRent = property.mortgagePayment ?? 0;

  return (
    <Card hover onClick={onClick} className="p-6">
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <h3 className="font-semibold text-main truncate">{property.addressLine1}</h3>
            <Badge variant={statusVariant[property.status]} size="sm">
              {propertyStatusLabels[property.status]}
            </Badge>
          </div>
          <p className="text-sm text-muted">
            {property.city}, {property.state} {property.zip}
          </p>
        </div>
        <Badge variant="info" size="sm">
          {propertyTypeLabels[property.propertyType]}
        </Badge>
      </div>

      <div className="grid grid-cols-2 gap-4 pt-4 border-t border-main">
        <div>
          <p className="text-xs text-muted mb-0.5">Units</p>
          <p className="text-sm font-semibold text-main">{property.unitCount}</p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Year Built</p>
          <p className="text-sm font-semibold text-main">{property.yearBuilt ?? '--'}</p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Current Value</p>
          <p className="text-sm font-semibold text-main">
            {property.currentValue ? formatCurrency(property.currentValue) : '--'}
          </p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Monthly Mortgage</p>
          <p className="text-sm font-semibold text-main">
            {property.mortgagePayment ? formatCurrency(property.mortgagePayment) : '--'}
          </p>
        </div>
      </div>
    </Card>
  );
}
