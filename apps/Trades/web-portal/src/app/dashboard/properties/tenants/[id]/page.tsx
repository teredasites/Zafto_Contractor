'use client';

import { useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  User,
  Mail,
  Phone,
  Calendar,
  Briefcase,
  DollarSign,
  Shield,
  Car,
  PawPrint,
  FileText,
  CreditCard,
  Home,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useTenant } from '@/lib/hooks/use-tenants';
import { useLeases } from '@/lib/hooks/use-leases';
import { leaseStatusLabels } from '@/lib/hooks/pm-mappers';
import type { TenantData, LeaseData, RentChargeData } from '@/lib/hooks/pm-mappers';
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

export default function TenantDetailPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const tenantId = params.id as string;

  const { tenant, loading } = useTenant(tenantId);
  const { leases } = useLeases();

  // Find leases for this tenant
  const tenantLeases = leases.filter((l) => l.tenantId === tenantId);
  const activeLease = tenantLeases.find((l) => l.status === 'active');

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!tenant) {
    return (
      <div className="text-center py-12">
        <User size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">Tenant not found</h2>
        <p className="text-muted mt-2">The tenant you are looking for does not exist.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/properties/tenants')}>
          Back to Tenants
        </Button>
      </div>
    );
  }

  const vehicleInfo = tenant.vehicleInfo;
  const petInfo = tenant.petInfo;

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
          <div className="w-12 h-12 rounded-full bg-accent/10 flex items-center justify-center">
            <span className="text-lg font-semibold text-accent">
              {tenant.firstName[0]}{tenant.lastName[0]}
            </span>
          </div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">
                {tenant.firstName} {tenant.lastName}
              </h1>
              <Badge variant={tenantStatusVariant[tenant.status]}>
                {tenantStatusLabels[tenant.status]}
              </Badge>
            </div>
            <p className="text-muted mt-1">
              {tenant.email ?? 'No email on file'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Profile */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Profile
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow icon={<Mail size={16} />} label="Email" value={tenant.email ?? '--'} />
              <DetailRow icon={<Phone size={16} />} label="Phone" value={tenant.phone ?? '--'} />
              <DetailRow icon={<Calendar size={16} />} label="Date of Birth" value={tenant.dateOfBirth ? formatDate(tenant.dateOfBirth) : '--'} />
              <DetailRow icon={<Briefcase size={16} />} label="Employer" value={tenant.employer ?? '--'} />
              <DetailRow icon={<DollarSign size={16} />} label="Monthly Income" value={tenant.monthlyIncome ? formatCurrency(tenant.monthlyIncome) : '--'} />

              <div className="pt-3 border-t border-main">
                <h4 className="text-sm font-medium text-main mb-2">Emergency Contact</h4>
                <div className="space-y-2">
                  <DetailRow icon={<Shield size={16} />} label="Name" value={tenant.emergencyContactName ?? '--'} />
                  <DetailRow icon={<Phone size={16} />} label="Phone" value={tenant.emergencyContactPhone ?? '--'} />
                </div>
              </div>

              {vehicleInfo && Object.keys(vehicleInfo).length > 0 && (
                <div className="pt-3 border-t border-main">
                  <h4 className="text-sm font-medium text-main mb-2 flex items-center gap-2">
                    <Car size={16} className="text-muted" />
                    Vehicle
                  </h4>
                  <div className="space-y-1">
                    {Object.entries(vehicleInfo).map(([key, val]) => (
                      <div key={key} className="flex items-center justify-between text-sm">
                        <span className="text-muted capitalize">{key.replace(/_/g, ' ')}</span>
                        <span className="font-medium text-main">{String(val)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {petInfo && Object.keys(petInfo).length > 0 && (
                <div className="pt-3 border-t border-main">
                  <h4 className="text-sm font-medium text-main mb-2 flex items-center gap-2">
                    <PawPrint size={16} className="text-muted" />
                    Pet
                  </h4>
                  <div className="space-y-1">
                    {Object.entries(petInfo).map(([key, val]) => (
                      <div key={key} className="flex items-center justify-between text-sm">
                        <span className="text-muted capitalize">{key.replace(/_/g, ' ')}</span>
                        <span className="font-medium text-main">{String(val)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {tenant.notes && (
                <div className="pt-3 border-t border-main">
                  <h4 className="text-sm font-medium text-main mb-2 flex items-center gap-2">
                    <FileText size={16} className="text-muted" />
                    Notes
                  </h4>
                  <p className="text-sm text-main whitespace-pre-wrap">{tenant.notes}</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Lease History */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <Home size={18} className="text-muted" />
                Lease History
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {tenantLeases.length === 0 ? (
                <div className="py-8 text-center">
                  <FileText size={40} className="mx-auto text-muted mb-2 opacity-50" />
                  <p className="text-muted">No lease history</p>
                </div>
              ) : (
                <div className="divide-y divide-main">
                  {tenantLeases.map((lease) => (
                    <div key={lease.id} className="px-6 py-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-main text-sm">
                            {lease.propertyAddress ?? 'Unknown Property'}
                            {lease.unitNumber ? ` - Unit ${lease.unitNumber}` : ''}
                          </p>
                          <p className="text-xs text-muted mt-0.5">
                            {formatDate(lease.startDate)} - {lease.endDate ? formatDate(lease.endDate) : 'Ongoing'}
                          </p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-sm font-semibold text-main">{formatCurrency(lease.rentAmount)}/mo</span>
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
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Current Lease */}
          {activeLease ? (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <CreditCard size={18} className="text-muted" />
                  Current Lease
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Property</span>
                  <span className="font-medium text-main">{activeLease.propertyAddress ?? '--'}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Unit</span>
                  <span className="font-medium text-main">{activeLease.unitNumber ?? '--'}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Lease Type</span>
                  <span className="font-medium text-main capitalize">{activeLease.leaseType.replace('_', ' ')}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Start Date</span>
                  <span className="font-medium text-main">{formatDate(activeLease.startDate)}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">End Date</span>
                  <span className="font-medium text-main">{activeLease.endDate ? formatDate(activeLease.endDate) : 'Month-to-month'}</span>
                </div>
                <div className="pt-3 border-t border-main">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted">Monthly Rent</span>
                    <span className="text-lg font-semibold text-main">{formatCurrency(activeLease.rentAmount)}</span>
                  </div>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Deposit</span>
                  <span className="font-medium text-main">{formatCurrency(activeLease.depositAmount)}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted">Deposit Held</span>
                  <Badge variant={activeLease.depositHeld ? 'success' : 'warning'} size="sm">
                    {activeLease.depositHeld ? 'Yes' : 'No'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          ) : (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Current Lease</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted text-center py-4">No active lease</p>
              </CardContent>
            </Card>
          )}

          {/* Payment History */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <DollarSign size={18} className="text-muted" />
                Payment History
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="py-6 text-center">
                <DollarSign size={32} className="mx-auto text-muted mb-2 opacity-50" />
                <p className="text-sm text-muted">Rent charges and payments will appear here</p>
                <p className="text-xs text-muted mt-1">Powered by the rent ledger</p>
              </div>
            </CardContent>
          </Card>

          {/* Quick Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Quick Info</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Status</span>
                <Badge variant={tenantStatusVariant[tenant.status]} size="sm">
                  {tenantStatusLabels[tenant.status]}
                </Badge>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Total Leases</span>
                <span className="font-medium text-main">{tenantLeases.length}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted">Tenant Since</span>
                <span className="font-medium text-main">{formatDate(tenant.createdAt)}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function DetailRow({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="flex items-center gap-2 text-muted">
        {icon}
        {label}
      </span>
      <span className="font-medium text-main">{value}</span>
    </div>
  );
}
