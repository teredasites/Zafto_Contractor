'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Building2,
  Home,
  DollarSign,
  Percent,
  MapPin,
  Shield,
  LayoutGrid,
  List,
  X,
  Loader2,
  Landmark,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
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

type SortField = 'address' | 'value' | 'units' | 'recent' | 'type';

export default function PropertiesPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const { properties, loading, createProperty, getPropertyStats } = useProperties();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [sortBy, setSortBy] = useState<SortField>('recent');
  const [view, setView] = useState<'grid' | 'list'>('grid');
  const [stats, setStats] = useState<PropertyStats | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);

  useEffect(() => {
    getPropertyStats().then(setStats).catch(() => {});
  }, [getPropertyStats]);

  // Portfolio totals
  const portfolio = useMemo(() => {
    const totalValue = properties.reduce((sum, p) => sum + (p.currentValue || 0), 0);
    const totalMortgage = properties.reduce((sum, p) => sum + (p.mortgagePayment || 0), 0);
    const totalInsurance = properties.reduce((sum, p) => sum + (p.insurancePremium || 0), 0);
    const totalTax = properties.reduce((sum, p) => sum + (p.propertyTaxAnnual || 0), 0);
    const totalSqFt = properties.reduce((sum, p) => sum + (p.squareFootage || 0), 0);
    const activeCount = properties.filter(p => p.status === 'active').length;
    const rehabCount = properties.filter(p => p.status === 'rehab').length;
    return { totalValue, totalMortgage, totalInsurance, totalTax, totalSqFt, activeCount, rehabCount };
  }, [properties]);

  const filteredProperties = useMemo(() => {
    return properties.filter((p) => {
      const addr = formatPropertyAddress(p).toLowerCase();
      const q = search.toLowerCase();
      const matchesSearch = !q || addr.includes(q) ||
        (p.propertyType || '').toLowerCase().includes(q) ||
        (p.notes || '').toLowerCase().includes(q);
      const matchesType = typeFilter === 'all' || p.propertyType === typeFilter;
      const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
      return matchesSearch && matchesType && matchesStatus;
    }).sort((a, b) => {
      switch (sortBy) {
        case 'address':
          return (a.addressLine1 || '').localeCompare(b.addressLine1 || '');
        case 'value':
          return (b.currentValue || 0) - (a.currentValue || 0);
        case 'units':
          return (b.unitCount || 0) - (a.unitCount || 0);
        case 'type':
          return (a.propertyType || '').localeCompare(b.propertyType || '');
        default:
          return new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime();
      }
    });
  }, [properties, search, typeFilter, statusFilter, sortBy]);

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
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('properties.title')}</h1>
          <p className="text-[13px] text-muted mt-1">{t('properties.managePropertyPortfolio')}</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Property
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Building2 size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{stats?.totalProperties ?? properties.length}</p>
                <p className="text-sm text-muted">{t('common.totalProperties')}</p>
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
                <p className="text-sm text-muted">{t('common.occupancyRate')}</p>
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
                <p className="text-sm text-muted">{t('common.rentCollected')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Portfolio Summary */}
      {properties.length > 0 && (
        <Card>
          <CardContent className="p-4">
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
              <div>
                <p className="text-xs text-muted mb-0.5">Portfolio Value</p>
                <p className="text-sm font-semibold text-main">{formatCurrency(portfolio.totalValue)}</p>
              </div>
              <div>
                <p className="text-xs text-muted mb-0.5">Monthly Mortgage</p>
                <p className="text-sm font-semibold text-main">{formatCurrency(portfolio.totalMortgage)}</p>
              </div>
              <div>
                <p className="text-xs text-muted mb-0.5">Annual Insurance</p>
                <p className="text-sm font-semibold text-main">{formatCurrency(portfolio.totalInsurance)}</p>
              </div>
              <div>
                <p className="text-xs text-muted mb-0.5">Annual Taxes</p>
                <p className="text-sm font-semibold text-main">{formatCurrency(portfolio.totalTax)}</p>
              </div>
              <div>
                <p className="text-xs text-muted mb-0.5">Total Sq Ft</p>
                <p className="text-sm font-semibold text-main">{portfolio.totalSqFt.toLocaleString()}</p>
              </div>
              <div>
                <p className="text-xs text-muted mb-0.5">In Rehab</p>
                <p className="text-sm font-semibold text-main">{portfolio.rehabCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 flex-wrap">
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
        <Select
          options={[
            { value: 'recent', label: 'Most Recent' },
            { value: 'address', label: 'Address A-Z' },
            { value: 'value', label: 'Highest Value' },
            { value: 'units', label: 'Most Units' },
            { value: 'type', label: 'Property Type' },
          ]}
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value as SortField)}
          className="sm:w-44"
        />
        <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg ml-auto">
          <button
            onClick={() => setView('grid')}
            className={cn(
              'p-2 rounded-md transition-colors',
              view === 'grid' ? 'bg-surface text-main shadow-sm' : 'text-muted hover:text-main'
            )}
          >
            <LayoutGrid size={16} />
          </button>
          <button
            onClick={() => setView('list')}
            className={cn(
              'p-2 rounded-md transition-colors',
              view === 'list' ? 'bg-surface text-main shadow-sm' : 'text-muted hover:text-main'
            )}
          >
            <List size={16} />
          </button>
        </div>
      </div>

      {/* Properties */}
      {filteredProperties.length === 0 ? (
        <div className="py-12 text-center">
          <Building2 size={48} className="mx-auto text-muted mb-3 opacity-50" />
          <p className="text-muted">{t('common.noPropertiesFound')}</p>
          <Button className="mt-4" onClick={() => setShowAddModal(true)}>
            <Plus size={16} />
            Add Your First Property
          </Button>
        </div>
      ) : view === 'grid' ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {filteredProperties.map((property) => (
            <PropertyCard
              key={property.id}
              property={property}
              onClick={() => router.push(`/dashboard/properties/${property.id}`)}
            />
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {filteredProperties.map((property) => (
                <PropertyRow
                  key={property.id}
                  property={property}
                  onClick={() => router.push(`/dashboard/properties/${property.id}`)}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Count */}
      {filteredProperties.length > 0 && (
        <p className="text-xs text-muted text-center">
          Showing {filteredProperties.length} of {properties.length} properties
        </p>
      )}

      {/* Add Property Modal */}
      {showAddModal && (
        <AddPropertyModal
          onClose={() => setShowAddModal(false)}
          onCreate={createProperty}
          onCreated={(id) => {
            setShowAddModal(false);
            router.push(`/dashboard/properties/${id}`);
          }}
        />
      )}
    </div>
  );
}

// ── Property Card (Grid View) ──────────────────────────────────────────

function PropertyCard({ property, onClick }: { property: PropertyData; onClick: () => void }) {
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
          <p className="text-sm text-muted flex items-center gap-1">
            <MapPin size={12} />
            {property.city}, {property.state} {property.zip}
          </p>
        </div>
        <Badge variant="info" size="sm">
          {propertyTypeLabels[property.propertyType]}
        </Badge>
      </div>

      <div className="grid grid-cols-3 gap-3 pt-4 border-t border-main">
        <div>
          <p className="text-xs text-muted mb-0.5">Units</p>
          <p className="text-sm font-semibold text-main">{property.unitCount}</p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Year Built</p>
          <p className="text-sm font-semibold text-main">{property.yearBuilt ?? '--'}</p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Sq Ft</p>
          <p className="text-sm font-semibold text-main">
            {property.squareFootage ? property.squareFootage.toLocaleString() : '--'}
          </p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Value</p>
          <p className="text-sm font-semibold text-main">
            {property.currentValue ? formatCurrency(property.currentValue) : '--'}
          </p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Mortgage</p>
          <p className="text-sm font-semibold text-main">
            {property.mortgagePayment ? formatCurrency(property.mortgagePayment) + '/mo' : '--'}
          </p>
        </div>
        <div>
          <p className="text-xs text-muted mb-0.5">Lot Size</p>
          <p className="text-sm font-semibold text-main">
            {property.lotSize ? `${property.lotSize.toLocaleString()} sqft` : '--'}
          </p>
        </div>
      </div>

      {/* Insurance & Tax mini bar */}
      {(property.insuranceCarrier || property.propertyTaxAnnual) && (
        <div className="flex items-center gap-4 mt-3 pt-3 border-t border-main/50 text-xs text-muted">
          {property.insuranceCarrier && (
            <span className="flex items-center gap-1">
              <Shield size={11} /> {property.insuranceCarrier}
            </span>
          )}
          {property.propertyTaxAnnual ? (
            <span className="flex items-center gap-1">
              <Landmark size={11} /> {formatCurrency(property.propertyTaxAnnual)}/yr tax
            </span>
          ) : null}
        </div>
      )}
    </Card>
  );
}

// ── Property Row (List View) ──────────────────────────────────────────

function PropertyRow({ property, onClick }: { property: PropertyData; onClick: () => void }) {
  return (
    <div
      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex-shrink-0">
          <Building2 size={20} className="text-blue-600 dark:text-blue-400" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 className="font-medium text-main truncate">{property.addressLine1}</h4>
            <Badge variant={statusVariant[property.status]} size="sm">
              {propertyStatusLabels[property.status]}
            </Badge>
            <Badge variant="info" size="sm">
              {propertyTypeLabels[property.propertyType]}
            </Badge>
          </div>
          <div className="flex items-center gap-4 mt-1 text-sm text-muted">
            <span className="flex items-center gap-1">
              <MapPin size={12} />
              {property.city}, {property.state} {property.zip}
            </span>
            <span>{property.unitCount} unit{property.unitCount !== 1 ? 's' : ''}</span>
            {property.squareFootage ? (
              <span>{property.squareFootage.toLocaleString()} sqft</span>
            ) : null}
            {property.yearBuilt ? <span>Built {property.yearBuilt}</span> : null}
          </div>
        </div>
        <div className="text-right flex-shrink-0">
          <p className="font-semibold text-main">
            {property.currentValue ? formatCurrency(property.currentValue) : '--'}
          </p>
          <p className="text-sm text-muted">
            {property.mortgagePayment ? formatCurrency(property.mortgagePayment) + '/mo' : 'No mortgage'}
          </p>
        </div>
      </div>
    </div>
  );
}

// ── Add Property Modal ──────────────────────────────────────────

function AddPropertyModal({
  onClose,
  onCreate,
  onCreated,
}: {
  onClose: () => void;
  onCreate: (data: Partial<PropertyData>) => Promise<string>;
  onCreated: (id: string) => void;
}) {
  const { t } = useTranslation();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [addressLine1, setAddressLine1] = useState('');
  const [addressLine2, setAddressLine2] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zip, setZip] = useState('');
  const [propertyType, setPropertyType] = useState<string>('single_family');
  const [unitCount, setUnitCount] = useState('1');
  const [yearBuilt, setYearBuilt] = useState('');
  const [squareFootage, setSquareFootage] = useState('');
  const [lotSize, setLotSize] = useState('');
  const [currentValue, setCurrentValue] = useState('');
  const [mortgagePayment, setMortgagePayment] = useState('');
  const [mortgageLender, setMortgageLender] = useState('');
  const [mortgageRate, setMortgageRate] = useState('');
  const [insuranceCarrier, setInsuranceCarrier] = useState('');
  const [insurancePremium, setInsurancePremium] = useState('');
  const [propertyTaxAnnual, setPropertyTaxAnnual] = useState('');
  const [notes, setNotes] = useState('');

  const handleSubmit = async () => {
    if (!addressLine1.trim() || !city.trim() || !state.trim() || !zip.trim()) {
      setError('Address, city, state, and zip are required.');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      const id = await onCreate({
        addressLine1: addressLine1.trim(),
        addressLine2: addressLine2.trim() || undefined,
        city: city.trim(),
        state: state.trim(),
        zip: zip.trim(),
        propertyType: propertyType as PropertyData['propertyType'],
        unitCount: parseInt(unitCount, 10) || 1,
        yearBuilt: yearBuilt ? parseInt(yearBuilt, 10) : undefined,
        squareFootage: squareFootage ? parseInt(squareFootage, 10) : undefined,
        lotSize: lotSize ? parseInt(lotSize, 10) : undefined,
        currentValue: currentValue ? parseFloat(currentValue) : undefined,
        mortgagePayment: mortgagePayment ? parseFloat(mortgagePayment) : undefined,
        mortgageLender: mortgageLender.trim() || undefined,
        mortgageRate: mortgageRate ? parseFloat(mortgageRate) : undefined,
        insuranceCarrier: insuranceCarrier.trim() || undefined,
        insurancePremium: insurancePremium ? parseFloat(insurancePremium) : undefined,
        propertyTaxAnnual: propertyTaxAnnual ? parseFloat(propertyTaxAnnual) : undefined,
        notes: notes.trim() || undefined,
      } as Partial<PropertyData>);
      onCreated(id);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to create property');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div onClick={(e: React.MouseEvent) => e.stopPropagation()}>
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Property</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {error && (
            <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-3 text-sm text-red-500">
              {error}
            </div>
          )}

          {/* Address */}
          <div>
            <h3 className="text-sm font-medium text-main mb-3">Address</h3>
            <div className="space-y-3">
              <Input
                label="Street Address *"
                value={addressLine1}
                onChange={(e) => setAddressLine1(e.target.value)}
                placeholder="123 Main Street"
              />
              <Input
                label="Unit / Suite / Apt"
                value={addressLine2}
                onChange={(e) => setAddressLine2(e.target.value)}
                placeholder="Suite 100"
              />
              <div className="grid grid-cols-3 gap-3">
                <Input
                  label="City *"
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  placeholder="Springfield"
                />
                <Input
                  label="State *"
                  value={state}
                  onChange={(e) => setState(e.target.value)}
                  placeholder="IL"
                />
                <Input
                  label="Zip *"
                  value={zip}
                  onChange={(e) => setZip(e.target.value)}
                  placeholder="62701"
                />
              </div>
            </div>
          </div>

          {/* Property Details */}
          <div>
            <h3 className="text-sm font-medium text-main mb-3">Property Details</h3>
            <div className="grid grid-cols-2 gap-3">
              <Select
                label="Property Type"
                options={Object.entries(propertyTypeLabels).map(([value, label]) => ({ value, label }))}
                value={propertyType}
                onChange={(e) => setPropertyType(e.target.value)}
              />
              <Input
                label="Units"
                type="number"
                value={unitCount}
                onChange={(e) => setUnitCount(e.target.value)}
                min={1}
              />
              <Input
                label="Year Built"
                type="number"
                value={yearBuilt}
                onChange={(e) => setYearBuilt(e.target.value)}
                placeholder="1985"
              />
              <Input
                label="Square Footage"
                type="number"
                value={squareFootage}
                onChange={(e) => setSquareFootage(e.target.value)}
                placeholder="2,400"
              />
              <Input
                label="Lot Size (sqft)"
                type="number"
                value={lotSize}
                onChange={(e) => setLotSize(e.target.value)}
                placeholder="7,500"
              />
              <Input
                label="Current Value ($)"
                type="number"
                value={currentValue}
                onChange={(e) => setCurrentValue(e.target.value)}
                placeholder="350000"
              />
            </div>
          </div>

          {/* Financial */}
          <div>
            <h3 className="text-sm font-medium text-main mb-3">Financial</h3>
            <div className="grid grid-cols-2 gap-3">
              <Input
                label="Mortgage Lender"
                value={mortgageLender}
                onChange={(e) => setMortgageLender(e.target.value)}
                placeholder="First National Bank"
              />
              <Input
                label="Monthly Payment ($)"
                type="number"
                value={mortgagePayment}
                onChange={(e) => setMortgagePayment(e.target.value)}
                placeholder="1850"
              />
              <Input
                label="Interest Rate (%)"
                type="number"
                value={mortgageRate}
                onChange={(e) => setMortgageRate(e.target.value)}
                placeholder="6.5"
                step="0.01"
              />
              <Input
                label="Annual Property Tax ($)"
                type="number"
                value={propertyTaxAnnual}
                onChange={(e) => setPropertyTaxAnnual(e.target.value)}
                placeholder="4200"
              />
              <Input
                label="Insurance Carrier"
                value={insuranceCarrier}
                onChange={(e) => setInsuranceCarrier(e.target.value)}
                placeholder="State Farm"
              />
              <Input
                label="Annual Premium ($)"
                type="number"
                value={insurancePremium}
                onChange={(e) => setInsurancePremium(e.target.value)}
                placeholder="2400"
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              placeholder="Any additional notes about this property..."
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent text-sm"
            />
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 pt-2">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving}>
              {saving ? (
                <>
                  <Loader2 size={16} className="animate-spin" />
                  Creating...
                </>
              ) : (
                <>
                  <Plus size={16} />
                  Create Property
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
      </div>
    </div>
  );
}
