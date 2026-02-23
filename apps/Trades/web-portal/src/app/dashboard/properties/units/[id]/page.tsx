'use client';

import { useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Home,
  User,
  History,
  Package,
  Bed,
  Bath,
  Maximize,
  Layers,
  DollarSign,
  FileText,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useUnit } from '@/lib/hooks/use-units';
import { useTenants } from '@/lib/hooks/use-tenants';
import { useLeases } from '@/lib/hooks/use-leases';
import { unitStatusLabels, leaseStatusLabels } from '@/lib/hooks/pm-mappers';
import type { UnitData, LeaseData, TenantData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type TabType = 'info' | 'tenant' | 'history' | 'assets';

const unitStatusVariant: Record<UnitData['status'], 'success' | 'secondary' | 'error' | 'warning' | 'info' | 'purple'> = {
  occupied: 'success',
  vacant: 'error',
  maintenance: 'warning',
  listed: 'info',
  unit_turn: 'purple',
  rehab: 'warning',
};

export default function UnitDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const unitId = params.id as string;

  const { unit, loading } = useUnit(unitId);
  const { tenants } = useTenants();
  const { leases } = useLeases();
  const [activeTab, setActiveTab] = useState<TabType>('info');

  // Find active lease for this unit
  const activeLease = leases.find((l) => l.unitId === unitId && l.status === 'active');
  const activeTenant = activeLease
    ? tenants.find((t) => t.id === activeLease.tenantId)
    : null;

  // All leases for history
  const unitLeases = leases.filter((l) => l.unitId === unitId);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!unit) {
    return (
      <div className="text-center py-12">
        <Home size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">{t('units.notFound')}</h2>
        <p className="text-muted mt-2">{t('units.notFoundDesc')}</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/properties/units')}>
          {t('common.back')}
        </Button>
      </div>
    );
  }

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'info', label: 'Info', icon: <Home size={16} /> },
    { id: 'tenant', label: 'Current Tenant', icon: <User size={16} /> },
    { id: 'history', label: 'History', icon: <History size={16} /> },
    { id: 'assets', label: 'Assets', icon: <Package size={16} /> },
  ];

  return (
    <div className="space-y-6 pb-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">
                Unit {unit.unitNumber}
              </h1>
              <Badge variant={unitStatusVariant[unit.status]}>
                {unitStatusLabels[unit.status]}
              </Badge>
            </div>
            <p className="text-muted mt-1">{unit.propertyAddress ?? 'Unknown Property'}</p>
          </div>
        </div>
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

      {/* Info Tab */}
      {activeTab === 'info' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Unit Details */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Unit Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <Bed size={20} className="text-muted" />
                  <div>
                    <p className="text-xs text-muted">Bedrooms</p>
                    <p className="font-semibold text-main">{unit.bedrooms}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <Bath size={20} className="text-muted" />
                  <div>
                    <p className="text-xs text-muted">Bathrooms</p>
                    <p className="font-semibold text-main">{unit.bathrooms}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <Maximize size={20} className="text-muted" />
                  <div>
                    <p className="text-xs text-muted">{t('common.squareFootage')}</p>
                    <p className="font-semibold text-main">{unit.squareFootage?.toLocaleString() ?? '--'}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <Layers size={20} className="text-muted" />
                  <div>
                    <p className="text-xs text-muted">Floor Level</p>
                    <p className="font-semibold text-main">{unit.floorLevel ?? '--'}</p>
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between text-sm pt-3 border-t border-main">
                <span className="text-muted">{t('common.marketRent')}</span>
                <span className="font-semibold text-main">
                  {unit.marketRent ? formatCurrency(unit.marketRent) : '--'}
                </span>
              </div>
            </CardContent>
          </Card>

          {/* Amenities */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Amenities</CardTitle>
            </CardHeader>
            <CardContent>
              {unit.amenities.length === 0 ? (
                <p className="text-sm text-muted">No amenities listed</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {unit.amenities.map((amenity, idx) => (
                    <Badge key={idx} variant="default">{amenity}</Badge>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Notes */}
          {unit.notes && (
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <FileText size={18} className="text-muted" />
                  Notes
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-main whitespace-pre-wrap">{unit.notes}</p>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* Current Tenant Tab */}
      {activeTab === 'tenant' && (
        <div className="space-y-6">
          {unit.status === 'occupied' && activeTenant && activeLease ? (
            <>
              {/* Tenant Info */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-base flex items-center gap-2">
                    <User size={18} className="text-muted" />
                    Current Tenant
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Name</span>
                    <button
                      onClick={() => router.push(`/dashboard/properties/tenants/${activeTenant.id}`)}
                      className="font-medium text-accent hover:underline"
                    >
                      {activeTenant.firstName} {activeTenant.lastName}
                    </button>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Email</span>
                    <span className="font-medium text-main">{activeTenant.email ?? '--'}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Phone</span>
                    <span className="font-medium text-main">{activeTenant.phone ?? '--'}</span>
                  </div>
                </CardContent>
              </Card>

              {/* Lease Info */}
              <Card>
                <CardHeader>
                  <CardTitle className="text-base flex items-center gap-2">
                    <DollarSign size={18} className="text-muted" />
                    Active Lease
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.leaseType')}</span>
                    <span className="font-medium text-main capitalize">{activeLease.leaseType.replace('_', ' ')}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.startDate')}</span>
                    <span className="font-medium text-main">{formatDate(activeLease.startDate)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.endDate')}</span>
                    <span className="font-medium text-main">{activeLease.endDate ? formatDate(activeLease.endDate) : 'Month-to-month'}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.monthlyRent')}</span>
                    <span className="font-semibold text-main">{formatCurrency(activeLease.rentAmount)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.dueDay')}</span>
                    <span className="font-medium text-main">{activeLease.rentDueDay}th of each month</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">{t('common.deposit')}</span>
                    <span className="font-medium text-main">{formatCurrency(activeLease.depositAmount)}</span>
                  </div>
                </CardContent>
              </Card>
            </>
          ) : (
            <Card>
              <CardContent className="py-12 text-center">
                <User size={40} className="mx-auto text-muted mb-3 opacity-50" />
                <p className="text-muted">This unit is currently not occupied</p>
                <p className="text-xs text-muted mt-1">No active tenant or lease for this unit</p>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* History Tab */}
      {activeTab === 'history' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Lease History</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {unitLeases.length === 0 ? (
              <div className="py-12 text-center">
                <History size={40} className="mx-auto text-muted mb-2 opacity-50" />
                <p className="text-muted">No lease history for this unit</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {unitLeases.map((lease) => (
                  <div key={lease.id} className="px-6 py-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-main text-sm">{lease.tenantName ?? 'Unknown Tenant'}</p>
                        <p className="text-xs text-muted">
                          {formatDate(lease.startDate)} - {lease.endDate ? formatDate(lease.endDate) : 'Ongoing'}
                        </p>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-medium text-main">{formatCurrency(lease.rentAmount)}/mo</span>
                        <Badge
                          variant={lease.status === 'active' ? 'success' : lease.status === 'terminated' ? 'error' : 'secondary'}
                          size="sm"
                        >
                          {leaseStatusLabels[lease.status]}
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

      {/* Assets Tab */}
      {activeTab === 'assets' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Unit Assets</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="py-8 text-center">
              <Package size={40} className="mx-auto text-muted mb-2 opacity-50" />
              <p className="text-muted">Track appliances, fixtures, and equipment in this unit</p>
              <p className="text-xs text-muted mt-1">Asset tracking will appear here</p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
