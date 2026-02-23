'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Search,
  Users,
  Mail,
  Phone,
  MapPin,
  MoreHorizontal,
  DollarSign,
  Briefcase,
  Tag,
  Star,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useCustomers } from '@/lib/hooks/use-customers';
import { useTranslation } from '@/lib/translations';
import type { Customer } from '@/types';

export default function CustomersPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [tagFilter, setTagFilter] = useState('all');
  const [view, setView] = useState<'list' | 'grid'>('list');
  const { customers, loading: customersLoading } = useCustomers();

  // Get unique tags
  const allTags = [...new Set(customers.flatMap((c) => c.tags))];

  const filteredCustomers = customers.filter((customer) => {
    const matchesSearch =
      customer.firstName.toLowerCase().includes(search.toLowerCase()) ||
      customer.lastName.toLowerCase().includes(search.toLowerCase()) ||
      customer.email.toLowerCase().includes(search.toLowerCase());

    const matchesTag = tagFilter === 'all' || customer.tags.includes(tagFilter);

    return matchesSearch && matchesTag;
  });

  const totalRevenue = customers.reduce((sum, c) => sum + c.totalRevenue, 0);
  const totalJobs = customers.reduce((sum, c) => sum + c.jobCount, 0);

  if (customersLoading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-40 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-4"><div className="skeleton h-4 w-20 mb-2" /><div className="skeleton h-6 w-12" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="skeleton w-10 h-10 rounded-full" /><div className="flex-1"><div className="skeleton h-4 w-32 mb-2" /><div className="skeleton h-3 w-48" /></div><div className="skeleton h-4 w-20" /></div>)}
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
          <h1 className="text-2xl font-semibold text-main">{t('customers.title')}</h1>
          <p className="text-[13px] text-muted mt-1">{t('customers.manageDesc')}</p>
        </div>
        <Button onClick={() => router.push('/dashboard/customers/new')}>
          <Plus size={16} />
          {t('customers.addCustomer')}
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Users size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{customers.length}</p>
                <p className="text-sm text-muted">{t('customers.totalCustomers')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <DollarSign size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalRevenue)}</p>
                <p className="text-sm text-muted">{t('customers.totalRevenue')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Briefcase size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalJobs}</p>
                <p className="text-sm text-muted">{t('customers.totalJobs')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Star size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {formatCurrency(customers.length > 0 ? totalRevenue / customers.length : 0)}
                </p>
                <p className="text-sm text-muted">{t('customers.avgRevenue')}</p>
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
          placeholder={t('customers.searchCustomers')}
          className="sm:w-80"
        />
        <Select
          options={[
            { value: 'all', label: 'All Tags' },
            ...allTags.map((tag) => ({ value: tag, label: tag.charAt(0).toUpperCase() + tag.slice(1) })),
          ]}
          value={tagFilter}
          onChange={(e) => setTagFilter(e.target.value)}
          className="sm:w-48"
        />
        <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg ml-auto">
          <button
            onClick={() => setView('list')}
            className={cn(
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              view === 'list'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            List
          </button>
          <button
            onClick={() => setView('grid')}
            className={cn(
              'px-3 py-1.5 text-sm rounded-md transition-colors',
              view === 'grid'
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            Grid
          </button>
        </div>
      </div>

      {/* Customers */}
      {view === 'list' ? (
        <Card>
          <CardContent className="p-0">
            {filteredCustomers.length === 0 ? (
              <div className="py-12 text-center text-muted">
                <Users size={40} className="mx-auto mb-2 opacity-50" />
                <p>{t('customers.noCustomers')}</p>
              </div>
            ) : (
              <div className="divide-y divide-main">
                {filteredCustomers.map((customer) => (
                  <CustomerRow
                    key={customer.id}
                    customer={customer}
                    onClick={() => router.push(`/dashboard/customers/${customer.id}`)}
                  />
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredCustomers.map((customer) => (
            <CustomerCard
              key={customer.id}
              customer={customer}
              onClick={() => router.push(`/dashboard/customers/${customer.id}`)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function CustomerRow({ customer, onClick }: { customer: Customer; onClick: () => void }) {
  const { t } = useTranslation();
  return (
    <div
      className="px-6 py-4 hover:bg-surface-hover cursor-pointer transition-colors"
      onClick={onClick}
    >
      <div className="flex items-center gap-4">
        <Avatar name={`${customer.firstName} ${customer.lastName}`} size="lg" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 className="font-medium text-main">
              {customer.firstName} {customer.lastName}
            </h4>
            {customer.tags.includes('vip') && (
              <Badge variant="warning" size="sm">{t('common.vip')}</Badge>
            )}
          </div>
          <div className="flex items-center gap-4 mt-1 text-sm text-muted">
            <span className="flex items-center gap-1">
              <Mail size={14} />
              {customer.email}
            </span>
            <span className="flex items-center gap-1">
              <Phone size={14} />
              {customer.phone}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <div className="text-right">
            <p className="font-semibold text-main">{formatCurrency(customer.totalRevenue)}</p>
            <p className="text-sm text-muted">{customer.jobCount} jobs</p>
          </div>
          <div className="flex items-center gap-2">
            {customer.tags.slice(0, 2).map((tag) => (
              <Badge key={tag} variant="default" size="sm">
                {tag}
              </Badge>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function CustomerCard({ customer, onClick }: { customer: Customer; onClick: () => void }) {
  const { t } = useTranslation();
  return (
    <Card hover onClick={onClick} className="p-6">
      <div className="flex items-start gap-4">
        <Avatar name={`${customer.firstName} ${customer.lastName}`} size="lg" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h4 className="font-medium text-main truncate">
              {customer.firstName} {customer.lastName}
            </h4>
            {customer.tags.includes('vip') && (
              <Badge variant="warning" size="sm">{t('common.vip')}</Badge>
            )}
          </div>
          <p className="text-sm text-muted truncate">{customer.email}</p>
        </div>
      </div>
      <div className="mt-4 pt-4 border-t border-main">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted">{t('customers.totalRevenue')}</span>
          <span className="font-semibold text-main">{formatCurrency(customer.totalRevenue)}</span>
        </div>
        <div className="flex items-center justify-between text-sm mt-2">
          <span className="text-muted">{t('customers.tabs.jobs')}</span>
          <span className="font-medium text-main">{customer.jobCount}</span>
        </div>
      </div>
      <div className="flex items-center gap-2 mt-4">
        {customer.tags.map((tag) => (
          <Badge key={tag} variant="default" size="sm">
            {tag}
          </Badge>
        ))}
      </div>
    </Card>
  );
}
