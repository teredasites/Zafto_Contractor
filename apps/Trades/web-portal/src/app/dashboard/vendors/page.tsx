'use client';

import { useState } from 'react';
import {
  Plus,
  Building,
  Mail,
  Phone,
  Star,
  DollarSign,
  Package,
  X,
  FileText,
  Globe,
  MapPin,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useVendors, VENDOR_TYPE_LABELS as ZBOOKS_TYPE_LABELS, PAYMENT_TERMS_LABELS as ZBOOKS_TERMS_LABELS } from '@/lib/hooks/use-vendors';
import {
  useProcurement,
  VENDOR_TYPES as PROC_VENDOR_TYPES,
  VENDOR_TYPE_LABELS as PROC_TYPE_LABELS,
  PAYMENT_TERMS as PROC_PAYMENT_TERMS,
  PAYMENT_TERMS_LABELS as PROC_TERMS_LABELS,
} from '@/lib/hooks/use-procurement';
import { useTranslation } from '@/lib/translations';

type TabKey = 'accounting' | 'suppliers';

export default function VendorsPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabKey>('suppliers');
  const [search, setSearch] = useState('');

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('vendors.title')}</h1>
          <p className="text-muted mt-1">Manage suppliers and accounting vendors</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-main">
        <button
          onClick={() => { setActiveTab('suppliers'); setSearch(''); }}
          className={cn(
            'px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-px',
            activeTab === 'suppliers'
              ? 'border-accent text-accent'
              : 'border-transparent text-muted hover:text-main'
          )}
        >
          Supplier Directory
        </button>
        <button
          onClick={() => { setActiveTab('accounting'); setSearch(''); }}
          className={cn(
            'px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-px',
            activeTab === 'accounting'
              ? 'border-accent text-accent'
              : 'border-transparent text-muted hover:text-main'
          )}
        >
          Accounting Vendors
        </button>
      </div>

      {activeTab === 'suppliers' ? (
        <SupplierDirectoryTab search={search} setSearch={setSearch} />
      ) : (
        <AccountingVendorsTab search={search} setSearch={setSearch} />
      )}
    </div>
  );
}

// ============================================================
// Supplier Directory Tab (vendor_directory via use-procurement)
// ============================================================

function SupplierDirectoryTab({ search, setSearch }: { search: string; setSearch: (v: string) => void }) {
  const { t } = useTranslation();
  const { vendors, activeVendors, loading, error, createVendor } = useProcurement();
  const [typeFilter, setTypeFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...PROC_VENDOR_TYPES.map((t) => ({ value: t, label: PROC_TYPE_LABELS[t] || t })),
  ];

  const filteredVendors = vendors.filter((v) => {
    const matchesSearch =
      v.name.toLowerCase().includes(search.toLowerCase()) ||
      v.contactName?.toLowerCase().includes(search.toLowerCase()) ||
      v.email?.toLowerCase().includes(search.toLowerCase()) ||
      v.tradeCategories.some((tc) => tc.toLowerCase().includes(search.toLowerCase()));
    const matchesType = typeFilter === 'all' || v.vendorType === typeFilter;
    return matchesSearch && matchesType;
  });

  const avgRating = activeVendors.length > 0
    ? activeVendors.reduce((sum, v) => sum + (v.rating || 0), 0) / activeVendors.filter((v) => v.rating).length || 0
    : 0;

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}><CardContent className="p-4"><div className="skeleton h-3 w-20 mb-3" /><div className="skeleton h-7 w-16" /></CardContent></Card>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <>
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Building size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{vendors.length}</p>
                <p className="text-sm text-muted">Total Suppliers</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Package size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeVendors.length}</p>
                <p className="text-sm text-muted">{t('common.active')}</p>
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
                <p className="text-2xl font-semibold text-main">{avgRating.toFixed(1)}</p>
                <p className="text-sm text-muted">Avg Rating</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Globe size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {new Set(vendors.flatMap((v) => v.tradeCategories)).size}
                </p>
                <p className="text-sm text-muted">Trade Categories</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex flex-col sm:flex-row gap-4">
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Search suppliers..."
            className="sm:w-80"
          />
          <Select
            options={typeOptions}
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="sm:w-48"
          />
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          Add Supplier
        </Button>
      </div>

      {/* Suppliers Table */}
      {filteredVendors.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Building size={40} className="mx-auto mb-2 opacity-50 text-muted" />
            <p className="text-muted">{error || 'No suppliers found'}</p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Supplier</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.contact')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Categories</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Terms</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Rating</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredVendors.map((vendor) => (
                  <tr key={vendor.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-3">
                        <Avatar name={vendor.name} size="md" />
                        <div>
                          <p className="font-medium text-main">{vendor.name}</p>
                          {vendor.city && vendor.state && (
                            <p className="text-xs text-muted">{vendor.city}, {vendor.state}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant="secondary" size="sm">
                        {PROC_TYPE_LABELS[vendor.vendorType] || vendor.vendorType}
                      </Badge>
                    </td>
                    <td className="px-6 py-3">
                      <div className="text-sm">
                        {vendor.contactName && <p className="text-main">{vendor.contactName}</p>}
                        {vendor.phone && (
                          <p className="text-xs text-muted flex items-center gap-1">
                            <Phone size={12} />
                            {vendor.phone}
                          </p>
                        )}
                        {vendor.email && (
                          <p className="text-xs text-muted flex items-center gap-1">
                            <Mail size={12} />
                            {vendor.email}
                          </p>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <div className="flex flex-wrap gap-1">
                        {vendor.tradeCategories.slice(0, 3).map((cat) => (
                          <Badge key={cat} variant="default" size="sm">{cat}</Badge>
                        ))}
                        {vendor.tradeCategories.length > 3 && (
                          <Badge variant="secondary" size="sm">+{vendor.tradeCategories.length - 3}</Badge>
                        )}
                        {vendor.tradeCategories.length === 0 && (
                          <span className="text-xs text-muted">-</span>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-3 text-sm text-muted">
                      {PROC_TERMS_LABELS[vendor.paymentTerms] || vendor.paymentTerms}
                    </td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-0.5">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star
                            key={star}
                            size={14}
                            className={cn(
                              vendor.rating && star <= vendor.rating
                                ? 'text-amber-500 fill-amber-500'
                                : 'text-muted'
                            )}
                          />
                        ))}
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant={vendor.isActive ? 'success' : 'default'} size="sm">
                        {vendor.isActive ? 'Active' : 'Inactive'}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      {/* New Supplier Modal */}
      {showNewModal && (
        <NewSupplierModal
          onClose={() => setShowNewModal(false)}
          onCreate={createVendor}
        />
      )}
    </>
  );
}

// ============================================================
// Accounting Vendors Tab (vendors via use-vendors / Ledger)
// ============================================================

function AccountingVendorsTab({ search, setSearch }: { search: string; setSearch: (v: string) => void }) {
  const { t } = useTranslation();
  const { vendors, loading, error } = useVendors();
  const [typeFilter, setTypeFilter] = useState('all');

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...Object.entries(ZBOOKS_TYPE_LABELS).map(([value, label]) => ({ value, label })),
  ];

  const filteredVendors = vendors.filter((v) => {
    const matchesSearch =
      v.vendorName.toLowerCase().includes(search.toLowerCase()) ||
      v.contactName?.toLowerCase().includes(search.toLowerCase()) ||
      v.email?.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || v.vendorType === typeFilter;
    return matchesSearch && matchesType;
  });

  const ytdTotal = vendors.reduce((sum, v) => sum + (v.ytdPayments || 0), 0);
  const eligible1099 = vendors.filter((v) => v.is1099Eligible);
  const over600 = eligible1099.filter((v) => (v.ytdPayments || 0) >= 600);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-40">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  return (
    <>
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Building size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{vendors.length}</p>
                <p className="text-sm text-muted">Accounting Vendors</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(ytdTotal)}</p>
                <p className="text-sm text-muted">YTD Payments</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <FileText size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{eligible1099.length}</p>
                <p className="text-sm text-muted">1099 Eligible</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <FileText size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{over600.length}</p>
                <p className="text-sm text-muted">1099 Required ($600+)</p>
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
          placeholder="Search accounting vendors..."
          className="sm:w-80"
        />
        <Select
          options={typeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Vendors Table */}
      {filteredVendors.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Building size={40} className="mx-auto mb-2 opacity-50 text-muted" />
            <p className="text-muted">{error || 'No accounting vendors found'}</p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardContent className="p-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.vendor')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.contact')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Terms</th>
                  <th className="text-right text-sm font-medium text-muted px-6 py-3">YTD Payments</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">1099</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredVendors.map((vendor) => (
                  <tr key={vendor.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-3">
                        <Avatar name={vendor.vendorName} size="md" />
                        <div>
                          <p className="font-medium text-main">{vendor.vendorName}</p>
                          {vendor.city && vendor.state && (
                            <p className="text-xs text-muted">{vendor.city}, {vendor.state}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant="secondary" size="sm">
                        {ZBOOKS_TYPE_LABELS[vendor.vendorType] || vendor.vendorType}
                      </Badge>
                    </td>
                    <td className="px-6 py-3">
                      <div className="text-sm">
                        {vendor.contactName && <p className="text-main">{vendor.contactName}</p>}
                        {vendor.email && <p className="text-xs text-muted">{vendor.email}</p>}
                      </div>
                    </td>
                    <td className="px-6 py-3 text-sm text-muted">
                      {ZBOOKS_TERMS_LABELS[vendor.paymentTerms] || vendor.paymentTerms}
                    </td>
                    <td className="px-6 py-3 text-right">
                      <span className="font-medium text-main">{formatCurrency(vendor.ytdPayments || 0)}</span>
                    </td>
                    <td className="px-6 py-3">
                      {vendor.is1099Eligible ? (
                        <Badge
                          variant={(vendor.ytdPayments || 0) >= 600 ? 'error' : 'warning'}
                          size="sm"
                        >
                          {(vendor.ytdPayments || 0) >= 600 ? '1099 Required' : '1099 Eligible'}
                        </Badge>
                      ) : (
                        <span className="text-xs text-muted">N/A</span>
                      )}
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant={vendor.isActive ? 'success' : 'default'} size="sm">
                        {vendor.isActive ? 'Active' : 'Inactive'}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}
    </>
  );
}

// ============================================================
// New Supplier Modal
// ============================================================

function NewSupplierModal({
  onClose,
  onCreate,
}: {
  onClose: () => void;
  onCreate: (data: {
    name: string;
    contactName?: string;
    email?: string;
    phone?: string;
    address?: string;
    city?: string;
    state?: string;
    zipCode?: string;
    website?: string;
    paymentTerms?: string;
    vendorType: string;
    tradeCategories?: string[];
    notes?: string;
  }) => Promise<string>;
}) {
  const [name, setName] = useState('');
  const [contactName, setContactName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [vendorType, setVendorType] = useState('supplier');
  const [paymentTerms, setPaymentTerms] = useState('net_30');
  const [saving, setSaving] = useState(false);

  const vendorTypeOptions = PROC_VENDOR_TYPES.map((t) => ({
    value: t,
    label: PROC_TYPE_LABELS[t] || t,
  }));

  const termsOptions = PROC_PAYMENT_TERMS.map((t) => ({
    value: t,
    label: PROC_TERMS_LABELS[t] || t,
  }));

  const handleCreate = async () => {
    if (!name.trim()) return;
    try {
      setSaving(true);
      await onCreate({
        name: name.trim(),
        contactName: contactName || undefined,
        email: email || undefined,
        phone: phone || undefined,
        vendorType,
        paymentTerms,
      });
      onClose();
    } catch {
      // Error handled by hook
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Supplier</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input
            label="Company Name *"
            placeholder="Electrical Supply Co."
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <Input
            label="Contact Name"
            placeholder="John Smith"
            value={contactName}
            onChange={(e) => setContactName(e.target.value)}
          />
          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Email"
              type="email"
              placeholder="orders@company.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            <Input
              label="Phone"
              type="tel"
              placeholder="(555) 123-4567"
              value={phone}
              onChange={(e) => {
                const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                setPhone(formatted);
              }}
            />
          </div>
          <Select
            label="Vendor Type"
            options={vendorTypeOptions}
            value={vendorType}
            onChange={(e) => setVendorType(e.target.value)}
          />
          <Select
            label="Payment Terms"
            options={termsOptions}
            value={paymentTerms}
            onChange={(e) => setPaymentTerms(e.target.value)}
          />
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleCreate} loading={saving} disabled={!name.trim()}>
              <Plus size={16} />
              Add Supplier
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
