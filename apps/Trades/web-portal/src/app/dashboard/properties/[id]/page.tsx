'use client';

import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Building2,
  Edit,
  Home,
  DollarSign,
  FileText,
  Wrench,
  Package,
  Calendar,
  Shield,
  CreditCard,
  MapPin,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useProperty } from '@/lib/hooks/use-properties';
import { useUnits } from '@/lib/hooks/use-units';
import { useLeases } from '@/lib/hooks/use-leases';
import {
  formatPropertyAddress,
  propertyTypeLabels,
  unitStatusLabels,
  leaseStatusLabels,
} from '@/lib/hooks/pm-mappers';
import type { PropertyData, UnitData, LeaseData } from '@/lib/hooks/pm-mappers';
import type { UnitWithProperty } from '@/lib/hooks/use-units';
import { useTranslation } from '@/lib/translations';

type TabType = 'overview' | 'units' | 'financials' | 'maintenance' | 'assets';

const statusVariant: Record<PropertyData['status'], 'success' | 'secondary' | 'error' | 'warning'> = {
  active: 'success',
  inactive: 'secondary',
  sold: 'error',
  rehab: 'warning',
};

const propertyStatusLabels: Record<PropertyData['status'], string> = {
  active: 'Active',
  inactive: 'Inactive',
  sold: 'Sold',
  rehab: 'Rehab',
};

const unitStatusVariant: Record<UnitData['status'], 'success' | 'secondary' | 'error' | 'warning' | 'info' | 'purple'> = {
  occupied: 'success',
  vacant: 'error',
  maintenance: 'warning',
  listed: 'info',
  unit_turn: 'purple',
  rehab: 'warning',
};

export default function PropertyDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const propertyId = params.id as string;

  const { property, loading } = useProperty(propertyId);
  const { units: allUnits, getUnitsByProperty } = useUnits();
  const { leases } = useLeases();
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [propertyUnits, setPropertyUnits] = useState<UnitWithProperty[]>([]);
  const [unitsLoading, setUnitsLoading] = useState(true);

  useEffect(() => {
    if (propertyId) {
      setUnitsLoading(true);
      getUnitsByProperty(propertyId)
        .then(setPropertyUnits)
        .catch(() => {})
        .finally(() => setUnitsLoading(false));
    }
  }, [propertyId, getUnitsByProperty]);

  const propertyLeases = leases.filter((l) => l.propertyId === propertyId);
  const activeLeases = propertyLeases.filter((l) => l.status === 'active');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!property) {
    return (
      <div className="text-center py-12">
        <Building2 size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">Property not found</h2>
        <p className="text-muted mt-2">The property you are looking for does not exist.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/properties')}>
          Back to Properties
        </Button>
      </div>
    );
  }

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'overview', label: 'Overview', icon: <Building2 size={16} /> },
    { id: 'units', label: 'Units', icon: <Home size={16} /> },
    { id: 'financials', label: 'Financials', icon: <DollarSign size={16} /> },
    { id: 'maintenance', label: 'Maintenance', icon: <Wrench size={16} /> },
    { id: 'assets', label: 'Assets', icon: <Package size={16} /> },
  ];

  // Financial calculations
  const totalMonthlyRent = activeLeases.reduce((sum, l) => sum + l.rentAmount, 0);
  const monthlyMortgage = property.mortgagePayment ?? 0;
  const monthlyInsurance = property.insurancePremium ? property.insurancePremium / 12 : 0;
  const monthlyTax = property.propertyTaxAnnual ? property.propertyTaxAnnual / 12 : 0;
  const monthlyExpenses = monthlyMortgage + monthlyInsurance + monthlyTax;
  const noi = totalMonthlyRent - monthlyExpenses;

  return (
    <div className="space-y-6 pb-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push('/dashboard/properties')}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">{property.addressLine1}</h1>
              <Badge variant={statusVariant[property.status]}>
                {propertyStatusLabels[property.status]}
              </Badge>
              <Badge variant="info">
                {propertyTypeLabels[property.propertyType]}
              </Badge>
            </div>
            <p className="text-muted mt-1">
              {property.city}, {property.state} {property.zip}
            </p>
          </div>
        </div>
        <Button variant="secondary" onClick={() => {}}>
          <Edit size={16} />
          Edit Property
        </Button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors',
              activeTab === tab.id
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Property Details */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <MapPin size={18} className="text-muted" />
                Property Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow label="Address" value={formatPropertyAddress(property)} />
              <DetailRow label="Property Type" value={propertyTypeLabels[property.propertyType]} />
              <DetailRow label="Unit Count" value={String(property.unitCount)} />
              <DetailRow label="Year Built" value={property.yearBuilt ? String(property.yearBuilt) : '--'} />
              <DetailRow label="Square Footage" value={property.squareFootage ? `${property.squareFootage.toLocaleString()} sq ft` : '--'} />
              <DetailRow label="Lot Size" value={property.lotSize ?? '--'} />
            </CardContent>
          </Card>

          {/* Financial Summary */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={18} className="text-muted" />
                Financial Summary
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow label="Purchase Price" value={property.purchasePrice ? formatCurrency(property.purchasePrice) : '--'} />
              <DetailRow label="Current Value" value={property.currentValue ? formatCurrency(property.currentValue) : '--'} />
              <DetailRow label="Purchase Date" value={property.purchaseDate ? formatDate(property.purchaseDate) : '--'} />
              <DetailRow label="Monthly Rent Income" value={formatCurrency(totalMonthlyRent)} />
              <DetailRow label="Monthly Expenses" value={formatCurrency(monthlyExpenses)} />
              <DetailRow label="Net Operating Income" value={formatCurrency(noi)} highlight={noi >= 0 ? 'positive' : 'negative'} />
            </CardContent>
          </Card>

          {/* Mortgage Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <CreditCard size={18} className="text-muted" />
                Mortgage
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow label="Lender" value={property.mortgageLender ?? '--'} />
              <DetailRow label="Interest Rate" value={property.mortgageRate ? `${property.mortgageRate}%` : '--'} />
              <DetailRow label="Monthly Payment" value={property.mortgagePayment ? formatCurrency(property.mortgagePayment) : '--'} />
              <DetailRow label="Escrow" value={property.mortgageEscrow ? formatCurrency(property.mortgageEscrow) : '--'} />
              <DetailRow label="Principal Balance" value={property.mortgagePrincipalBalance ? formatCurrency(property.mortgagePrincipalBalance) : '--'} />
            </CardContent>
          </Card>

          {/* Insurance & Tax */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Shield size={18} className="text-muted" />
                Insurance & Tax
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow label="Insurance Carrier" value={property.insuranceCarrier ?? '--'} />
              <DetailRow label="Policy Number" value={property.insurancePolicyNumber ?? '--'} />
              <DetailRow label="Annual Premium" value={property.insurancePremium ? formatCurrency(property.insurancePremium) : '--'} />
              <DetailRow label="Expiry Date" value={property.insuranceExpiry ? formatDate(property.insuranceExpiry) : '--'} />
              <DetailRow label="Annual Property Tax" value={property.propertyTaxAnnual ? formatCurrency(property.propertyTaxAnnual) : '--'} />
            </CardContent>
          </Card>

          {/* Notes */}
          {property.notes && (
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <FileText size={18} className="text-muted" />
                  Notes
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-main whitespace-pre-wrap">{property.notes}</p>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {activeTab === 'units' && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-base">Units ({propertyUnits.length})</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {unitsLoading ? (
              <div className="px-6 py-8 text-center">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent mx-auto" />
              </div>
            ) : propertyUnits.length === 0 ? (
              <div className="py-12 text-center">
                <Home size={40} className="mx-auto text-muted mb-2 opacity-50" />
                <p className="text-muted">No units added yet</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {propertyUnits.map((unit) => (
                  <div
                    key={unit.id}
                    onClick={() => router.push(`/dashboard/properties/units/${unit.id}`)}
                    className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-main">Unit {unit.unitNumber}</p>
                        <p className="text-sm text-muted">
                          {unit.bedrooms} bed / {unit.bathrooms} bath
                          {unit.squareFootage ? ` / ${unit.squareFootage.toLocaleString()} sq ft` : ''}
                        </p>
                      </div>
                      <div className="flex items-center gap-4">
                        <div className="text-right">
                          <p className="font-semibold text-main">
                            {unit.marketRent ? formatCurrency(unit.marketRent) : '--'}
                          </p>
                          <p className="text-xs text-muted">Market Rent</p>
                        </div>
                        <Badge variant={unitStatusVariant[unit.status]} size="sm">
                          {unitStatusLabels[unit.status]}
                        </Badge>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === 'financials' && (
        <div className="space-y-6">
          {/* Rent Roll */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalMonthlyRent)}</p>
                <p className="text-sm text-muted">Monthly Income</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-semibold text-main">{formatCurrency(monthlyExpenses)}</p>
                <p className="text-sm text-muted">Monthly Expenses</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 text-center">
                <p className={cn('text-2xl font-semibold', noi >= 0 ? 'text-emerald-600' : 'text-red-600')}>
                  {formatCurrency(noi)}
                </p>
                <p className="text-sm text-muted">NOI (Monthly)</p>
              </CardContent>
            </Card>
          </div>

          {/* Expense Breakdown */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Expense Breakdown</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Mortgage Payment</span>
                <span className="font-medium text-main">{formatCurrency(monthlyMortgage)}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Insurance (monthly)</span>
                <span className="font-medium text-main">{formatCurrency(monthlyInsurance)}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Property Tax (monthly)</span>
                <span className="font-medium text-main">{formatCurrency(monthlyTax)}</span>
              </div>
              <div className="flex items-center justify-between text-sm pt-3 border-t border-main">
                <span className="font-medium text-main">Total Monthly Expenses</span>
                <span className="font-semibold text-main">{formatCurrency(monthlyExpenses)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Active Leases / Rent Roll */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Rent Roll ({activeLeases.length} active leases)</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {activeLeases.length === 0 ? (
                <div className="py-8 text-center">
                  <p className="text-muted">No active leases</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {activeLeases.map((lease) => (
                    <div key={lease.id} className="px-6 py-3 flex items-center justify-between">
                      <div>
                        <p className="font-medium text-main text-sm">{lease.tenantName ?? 'Unknown Tenant'}</p>
                        <p className="text-xs text-muted">Unit {lease.unitNumber ?? '--'}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold text-main text-sm">{formatCurrency(lease.rentAmount)}</p>
                        <p className="text-xs text-muted">Due day {lease.rentDueDay}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      {activeTab === 'maintenance' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Maintenance Requests</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="py-8 text-center">
              <Wrench size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">Maintenance requests for this property will appear here</p>
              <p className="text-xs text-muted mt-1">Requests are managed from the main Maintenance section</p>
            </div>
          </CardContent>
        </Card>
      )}

      {activeTab === 'assets' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Property Assets</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="py-8 text-center">
              <Package size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">Track HVAC, water heaters, appliances, and more</p>
              <p className="text-xs text-muted mt-1">Asset tracking for this property will appear here</p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function DetailRow({
  label,
  value,
  highlight,
}: {
  label: string;
  value: string;
  highlight?: 'positive' | 'negative';
}) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-muted">{label}</span>
      <span
        className={cn(
          'font-medium',
          highlight === 'positive' && 'text-emerald-600 dark:text-emerald-400',
          highlight === 'negative' && 'text-red-600 dark:text-red-400',
          !highlight && 'text-main'
        )}
      >
        {value}
      </span>
    </div>
  );
}
