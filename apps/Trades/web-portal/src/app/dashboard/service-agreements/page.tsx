'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  FileText,
  Calendar,
  DollarSign,
  RefreshCw,
  Clock,
  CheckCircle,
  AlertTriangle,
  MoreHorizontal,
  X,
  User,
  Bell,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useServiceAgreements, type ServiceAgreementData } from '@/lib/hooks/use-service-agreements';
import { useTranslation } from '@/lib/translations';

type AgreementStatus = 'active' | 'pending' | 'expired' | 'cancelled';
type BillingFrequency = 'monthly' | 'quarterly' | 'semi_annual' | 'annual';

interface ServiceAgreement {
  id: string;
  name: string;
  customerId: string;
  customerName: string;
  customerEmail: string;
  type: string;
  status: AgreementStatus;
  startDate: Date;
  endDate: Date;
  amount: number;
  billingFrequency: BillingFrequency;
  nextBillingDate: Date;
  nextServiceDate?: Date;
  servicesIncluded: string[];
  autoRenew: boolean;
  notes?: string;
}

const statusConfig: Record<AgreementStatus, { label: string; color: string; bgColor: string }> = {
  active: { label: 'Active', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  pending: { label: 'Pending', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  expired: { label: 'Expired', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  cancelled: { label: 'Cancelled', color: 'text-slate-700 dark:text-slate-300', bgColor: 'bg-slate-100 dark:bg-slate-800' },
};

const frequencyLabels: Record<BillingFrequency, string> = {
  monthly: 'Monthly',
  quarterly: 'Quarterly',
  semi_annual: 'Semi-Annual',
  annual: 'Annual',
};

function toAgreement(d: ServiceAgreementData): ServiceAgreement {
  const status: AgreementStatus = d.status === 'pending_renewal' ? 'pending' : (d.status as AgreementStatus) || 'active';
  const nextBilling = d.nextServiceDate ? new Date(d.nextServiceDate) : new Date(Date.now() + 30 * 86400000);
  return {
    id: d.id,
    name: d.title,
    customerId: d.customerId || '',
    customerName: d.customerName || '',
    customerEmail: '',
    type: d.agreementType,
    status,
    startDate: d.startDate ? new Date(d.startDate) : new Date(d.createdAt),
    endDate: d.endDate ? new Date(d.endDate) : new Date(Date.now() + 365 * 86400000),
    amount: d.billingAmount,
    billingFrequency: d.billingFrequency as BillingFrequency,
    nextBillingDate: nextBilling,
    nextServiceDate: d.nextServiceDate ? new Date(d.nextServiceDate) : undefined,
    servicesIncluded: (d.services || []).filter(s => s.included).map(s => s.name),
    autoRenew: d.renewalType === 'auto',
    notes: d.notes || undefined,
  };
}

export default function ServiceAgreementsPage() {
  const { t } = useTranslation();
  const { agreements: rawAgreements, loading } = useServiceAgreements();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedAgreement, setSelectedAgreement] = useState<ServiceAgreement | null>(null);

  const allAgreements = rawAgreements.map(toAgreement);

  const filteredAgreements = allAgreements.filter((agreement) => {
    const matchesSearch =
      agreement.name.toLowerCase().includes(search.toLowerCase()) ||
      agreement.customerName.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || agreement.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'active', label: 'Active' },
    { value: 'pending', label: 'Pending' },
    { value: 'expired', label: 'Expired' },
    { value: 'cancelled', label: 'Cancelled' },
  ];

  // Stats
  const activeCount = allAgreements.filter((a) => a.status === 'active').length;
  const monthlyRecurring = allAgreements
    .filter((a) => a.status === 'active')
    .reduce((sum, a) => {
      switch (a.billingFrequency) {
        case 'monthly': return sum + a.amount;
        case 'quarterly': return sum + a.amount / 3;
        case 'semi_annual': return sum + a.amount / 6;
        case 'annual': return sum + a.amount / 12;
        default: return sum;
      }
    }, 0);
  const upcomingServices = allAgreements.filter((a) =>
    a.nextServiceDate && a.nextServiceDate.getTime() - Date.now() < 30 * 24 * 60 * 60 * 1000
  ).length;
  const expiringCount = allAgreements.filter((a) =>
    a.status === 'active' && a.endDate.getTime() - Date.now() < 60 * 24 * 60 * 60 * 1000
  ).length;

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('serviceAgreements.title')}</h1>
          <p className="text-muted mt-1">{t('serviceAgreements.manageRecurringMaintenanceContracts')}</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          New Agreement
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeCount}</p>
                <p className="text-sm text-muted">{t('serviceAgreements.activeAgreements')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <RefreshCw size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(monthlyRecurring)}</p>
                <p className="text-sm text-muted">{t('serviceAgreements.monthlyRecurring')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Calendar size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{upcomingServices}</p>
                <p className="text-sm text-muted">{t('serviceAgreements.servicesThisMonth')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className={expiringCount > 0 ? 'border-amber-500' : ''}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{expiringCount}</p>
                <p className="text-sm text-muted">{t('common.expiringSoon')}</p>
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
          placeholder="Search agreements..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Agreements List */}
      {filteredAgreements.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <FileText size={40} className="mx-auto mb-3 text-muted opacity-40" />
            <p className="text-sm font-medium text-main">No service agreements found</p>
            <p className="text-xs text-muted mt-1">{allAgreements.length === 0 ? 'Create your first service agreement to track recurring maintenance contracts' : 'Try adjusting your search or filters'}</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {filteredAgreements.map((agreement) => (
            <AgreementCard
              key={agreement.id}
              agreement={agreement}
              onClick={() => setSelectedAgreement(agreement)}
            />
          ))}
        </div>
      )}

      {/* New Modal */}
      {showNewModal && (
        <NewAgreementModal onClose={() => setShowNewModal(false)} />
      )}

      {/* Detail Modal */}
      {selectedAgreement && (
        <AgreementDetailModal
          agreement={selectedAgreement}
          onClose={() => setSelectedAgreement(null)}
        />
      )}
    </div>
  );
}

function AgreementCard({ agreement, onClick }: { agreement: ServiceAgreement; onClick: () => void }) {
  const { t } = useTranslation();
  const config = statusConfig[agreement.status];
  const isExpiringSoon = agreement.status === 'active' && agreement.endDate.getTime() - Date.now() < 60 * 24 * 60 * 60 * 1000;
  const hasUpcomingService = agreement.nextServiceDate && agreement.nextServiceDate.getTime() - Date.now() < 14 * 24 * 60 * 60 * 1000;

  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onClick}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-medium text-main">{agreement.name}</h3>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                {config.label}
              </span>
            </div>
            <p className="text-sm text-muted">{agreement.type}</p>
          </div>
          {agreement.autoRenew && (
            <RefreshCw size={16} className="text-blue-500" aria-label="Auto-renew enabled" />
          )}
        </div>

        <div className="flex items-center gap-3 mb-3">
          <Avatar name={agreement.customerName} size="sm" />
          <div>
            <p className="text-sm font-medium text-main">{agreement.customerName}</p>
            <p className="text-xs text-muted">{agreement.customerEmail}</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 py-3 border-t border-b border-main">
          <div>
            <p className="text-xs text-muted">{t('common.amount')}</p>
            <p className="font-semibold text-main">{formatCurrency(agreement.amount)}/{frequencyLabels[agreement.billingFrequency].toLowerCase()}</p>
          </div>
          <div>
            <p className="text-xs text-muted">{t('common.nextBilling')}</p>
            <p className="text-sm text-main">{formatDate(agreement.nextBillingDate)}</p>
          </div>
        </div>

        <div className="flex items-center justify-between mt-3">
          <div className="flex items-center gap-2 text-xs text-muted">
            <Calendar size={12} />
            <span>Ends {formatDate(agreement.endDate)}</span>
          </div>
          <div className="flex items-center gap-2">
            {isExpiringSoon && (
              <Badge variant="warning" size="sm">
                <AlertTriangle size={10} />
                Expiring
              </Badge>
            )}
            {hasUpcomingService && (
              <Badge variant="info" size="sm">
                <Bell size={10} />
                Service Due
              </Badge>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function AgreementDetailModal({ agreement, onClose }: { agreement: ServiceAgreement; onClose: () => void }) {
  const { t } = useTranslation();
  const config = statusConfig[agreement.status];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-semibold text-main">{agreement.name}</h2>
                <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                  {config.label}
                </span>
              </div>
              <p className="text-muted">{agreement.type}</p>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Customer */}
          <div className="flex items-center gap-3 p-4 bg-secondary rounded-lg">
            <Avatar name={agreement.customerName} size="md" />
            <div>
              <p className="font-medium text-main">{agreement.customerName}</p>
              <p className="text-sm text-muted">{agreement.customerEmail}</p>
            </div>
          </div>

          {/* Key Dates */}
          <div className="grid grid-cols-3 gap-4">
            <div className="p-4 bg-secondary rounded-lg text-center">
              <p className="text-sm text-muted mb-1">{t('common.startDate')}</p>
              <p className="font-semibold text-main">{formatDate(agreement.startDate)}</p>
            </div>
            <div className="p-4 bg-secondary rounded-lg text-center">
              <p className="text-sm text-muted mb-1">{t('common.endDate')}</p>
              <p className="font-semibold text-main">{formatDate(agreement.endDate)}</p>
            </div>
            <div className="p-4 bg-secondary rounded-lg text-center">
              <p className="text-sm text-muted mb-1">{t('common.nextService')}</p>
              <p className="font-semibold text-main">
                {agreement.nextServiceDate ? formatDate(agreement.nextServiceDate) : 'N/A'}
              </p>
            </div>
          </div>

          {/* Billing */}
          <div className="p-4 bg-secondary rounded-lg">
            <h3 className="font-medium text-main mb-3">{t('common.billing')}</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted mb-1">{t('common.amount')}</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(agreement.amount)}</p>
                <p className="text-sm text-muted">{frequencyLabels[agreement.billingFrequency]}</p>
              </div>
              <div>
                <p className="text-sm text-muted mb-1">{t('common.nextBilling')}</p>
                <p className="text-lg font-medium text-main">{formatDate(agreement.nextBillingDate)}</p>
                <div className="flex items-center gap-1 mt-1">
                  <RefreshCw size={12} className={agreement.autoRenew ? 'text-blue-500' : 'text-muted'} />
                  <span className="text-xs text-muted">
                    Auto-renew {agreement.autoRenew ? 'enabled' : 'disabled'}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Services Included */}
          <div>
            <h3 className="font-medium text-main mb-3">{t('serviceAgreements.servicesIncluded')}</h3>
            <ul className="space-y-2">
              {agreement.servicesIncluded.map((service, i) => (
                <li key={i} className="flex items-center gap-2 text-sm">
                  <CheckCircle size={14} className="text-emerald-500" />
                  <span className="text-main">{service}</span>
                </li>
              ))}
            </ul>
          </div>

          {agreement.notes && (
            <div>
              <h3 className="font-medium text-main mb-2">{t('common.notes')}</h3>
              <p className="text-muted">{agreement.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button className="flex-1">
              <Calendar size={16} />
              Schedule Service
            </Button>
            <Button variant="secondary">
              <FileText size={16} />
              View Contract
            </Button>
            {agreement.status === 'active' && (
              <Button variant="ghost">
                <RefreshCw size={16} />
                Renew
              </Button>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewAgreementModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{t('serviceAgreements.newServiceAgreement')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Agreement Name *" placeholder="HVAC Maintenance Plan" />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Customer *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">{t('serviceAgreements.selectCustomer')}</option>
              <option value="c1">{t('serviceAgreements.thompsonAutoShop')}</option>
              <option value="c2">{t('warranties.sarahMartinez')}</option>
            </select>
          </div>
          <Select
            label={t('common.type')}
            options={[
              { value: 'hvac', label: 'HVAC Maintenance' },
              { value: 'electrical', label: 'Electrical Inspection' },
              { value: 'plumbing', label: 'Plumbing Maintenance' },
              { value: 'generator', label: 'Generator Service' },
              { value: 'other', label: 'Other' },
            ]}
          />
          <div className="grid grid-cols-2 gap-4">
            <Input label={t('invoices.amount')} type="number" placeholder="199.00" />
            <Select
              label={t('common.frequency')}
              options={[
                { value: 'monthly', label: 'Monthly' },
                { value: 'quarterly', label: 'Quarterly' },
                { value: 'semi_annual', label: 'Semi-Annual' },
                { value: 'annual', label: 'Annual' },
              ]}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.startDate')}</label>
              <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.endDate')}</label>
              <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
          </div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" className="w-4 h-4 rounded border-main text-accent focus:ring-accent" />
            <span className="text-sm text-main">{t('serviceAgreements.autorenewAtEndOfTerm')}</span>
          </label>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1"><Plus size={16} />{t('serviceAgreements.createAgreement')}</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
