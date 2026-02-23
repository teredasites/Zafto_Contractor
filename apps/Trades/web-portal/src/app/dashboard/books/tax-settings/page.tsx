'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  FileText,
  Download,
  AlertTriangle,
  CheckCircle,
  RefreshCw,
  ChevronDown,
  Calculator,
  Receipt,
  Users,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useTaxCompliance,
} from '@/lib/hooks/use-tax-compliance';
import type {
  TaxCategory,
  AccountMapping,
  Vendor1099,
  ScheduleCLine,
} from '@/lib/hooks/use-tax-compliance';
import { useTranslation } from '@/lib/translations';

// Ledger Navigation (shared across Ledger sub-pages)
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Vendor Payments', href: '/dashboard/books/vendor-payments', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reconciliation', href: '/dashboard/books/reconciliation', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Tax & 1099', href: '/dashboard/books/tax-settings', active: true },
];

const ACCOUNT_TYPE_LABELS: Record<string, string> = {
  asset: 'Assets',
  liability: 'Liabilities',
  equity: 'Equity',
  revenue: 'Revenue',
  cogs: 'Cost of Goods Sold',
  expense: 'Expenses',
};

const ACCOUNT_TYPE_ORDER = ['revenue', 'cogs', 'expense', 'asset', 'liability', 'equity'];

type TabKey = 'mapping' | 'vendors' | 'schedule-c';

function maskTaxId(taxId: string | null): string {
  if (!taxId) return '--';
  // Show only last 4 digits: ***-**-1234
  const digits = taxId.replace(/\D/g, '');
  if (digits.length < 4) return '***-**-' + digits;
  const last4 = digits.slice(-4);
  return '***-**-' + last4;
}

// ── Tax Mapping Row ──
function TaxMappingRow({
  account,
  taxCategories,
  onUpdate,
}: {
  account: AccountMapping;
  taxCategories: TaxCategory[];
  onUpdate: (accountId: string, taxCategoryId: string | null) => Promise<void>;
}) {
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  const handleChange = async (value: string) => {
    setSaving(true);
    setSaved(false);
    try {
      await onUpdate(account.id, value === '' ? null : value);
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      // Error handled by parent
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className={cn(
      'flex items-center gap-4 px-4 py-3 border-b border-default last:border-b-0',
      !account.isActive && 'opacity-50'
    )}>
      <div className="w-20 text-sm text-muted tabular-nums font-mono">
        {account.accountNumber}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-main truncate">{account.accountName}</p>
      </div>
      <div className="w-64 relative">
        <select
          value={account.taxCategoryId || ''}
          onChange={(e) => handleChange(e.target.value)}
          disabled={saving}
          className={cn(
            'w-full px-3 py-1.5 text-sm bg-secondary border border-default rounded-lg',
            'text-main appearance-none pr-8',
            'focus:outline-none focus:ring-1 focus:ring-accent focus:border-accent',
            'transition-colors'
          )}
        >
          <option value="">-- No tax mapping --</option>
          {taxCategories.map((cat) => (
            <option key={cat.id} value={cat.id}>
              {cat.taxLine ? `${cat.taxLine}: ` : ''}{cat.categoryName}
            </option>
          ))}
        </select>
        <ChevronDown size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
      </div>
      <div className="w-8 flex items-center justify-center">
        {saving && <RefreshCw size={14} className="animate-spin text-muted" />}
        {saved && <CheckCircle size={14} className="text-emerald-500" />}
      </div>
    </div>
  );
}

// ── 1099 Vendor Row ──
function VendorRow({ vendor }: { vendor: Vendor1099 }) {
  const missingTaxId = !vendor.taxId;
  const meetsThreshold = vendor.ytdPayments >= 600;

  return (
    <div className="flex items-center gap-4 px-4 py-3 border-b border-default last:border-b-0 hover:bg-secondary/50 transition-colors">
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-main">{vendor.vendorName}</p>
      </div>
      <div className="w-32 text-sm text-main tabular-nums font-mono">
        {maskTaxId(vendor.taxId)}
        {missingTaxId && (
          <Badge variant="warning" className="ml-2">Missing</Badge>
        )}
      </div>
      <div className="w-28 text-sm text-main tabular-nums text-right font-semibold">
        {formatCurrency(vendor.ytdPayments)}
      </div>
      <div className="w-28 flex justify-end">
        {meetsThreshold ? (
          missingTaxId ? (
            <Badge variant="error" dot>Action Needed</Badge>
          ) : (
            <Badge variant="success" dot>Ready</Badge>
          )
        ) : (
          <Badge variant="secondary">Under $600</Badge>
        )}
      </div>
    </div>
  );
}

// ── Schedule C Line Row ──
function ScheduleCRow({ line }: { line: ScheduleCLine }) {
  const isSubtotal = line.isComputed;
  const isNetProfit = line.line === 'Line 31';

  return (
    <div className={cn(
      'flex items-center gap-4 px-4 py-2.5',
      isSubtotal ? 'bg-secondary/70 border-y border-default' : 'border-b border-default last:border-b-0',
      isNetProfit && 'bg-accent/5 border-y-2 border-accent/20'
    )}>
      <div className="w-20 text-xs text-muted tabular-nums">{line.line}</div>
      <div className="flex-1">
        <p className={cn(
          'text-sm',
          isSubtotal ? 'font-semibold text-main' : 'text-main',
          isNetProfit && 'font-bold'
        )}>
          {line.label}
        </p>
      </div>
      <div className={cn(
        'w-32 text-right tabular-nums font-mono text-sm',
        isNetProfit && line.amount < 0 ? 'text-red-600 font-bold' : '',
        isNetProfit && line.amount >= 0 ? 'text-emerald-600 font-bold' : '',
        isSubtotal && !isNetProfit ? 'font-semibold text-main' : 'text-main'
      )}>
        {formatCurrency(line.amount)}
      </div>
    </div>
  );
}

export default function TaxSettingsPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const {
    taxCategories,
    accountMappings,
    vendors1099,
    allEligibleVendors,
    scheduleCData,
    loading,
    error,
    updateAccountTaxCategory,
    fetchVendors1099,
    fetchScheduleC,
    export1099CSV,
  } = useTaxCompliance();

  const [activeTab, setActiveTab] = useState<TabKey>('mapping');
  const [vendorYear, setVendorYear] = useState(new Date().getFullYear());
  const [scheduleCYear, setScheduleCYear] = useState(new Date().getFullYear());
  const [showAllVendors, setShowAllVendors] = useState(false);
  const [updateError, setUpdateError] = useState<string | null>(null);

  // Fetch Schedule C data when tab is selected or year changes
  useEffect(() => {
    if (activeTab === 'schedule-c') {
      fetchScheduleC(scheduleCYear);
    }
  }, [activeTab, scheduleCYear, fetchScheduleC]);

  // Refresh 1099 vendors when year changes
  useEffect(() => {
    if (activeTab === 'vendors') {
      fetchVendors1099(vendorYear);
    }
  }, [activeTab, vendorYear, fetchVendors1099]);

  const handleUpdateMapping = async (accountId: string, taxCategoryId: string | null) => {
    try {
      setUpdateError(null);
      await updateAccountTaxCategory(accountId, taxCategoryId);
    } catch (e: unknown) {
      setUpdateError(e instanceof Error ? e.message : 'Failed to update mapping');
    }
  };

  // Group accounts by type for the mapping tab
  const groupedAccounts = ACCOUNT_TYPE_ORDER.reduce<Record<string, AccountMapping[]>>((groups, type) => {
    const filtered = accountMappings.filter((a) => a.accountType === type);
    if (filtered.length > 0) {
      groups[type] = filtered;
    }
    return groups;
  }, {});

  // Vendors to display based on toggle
  const displayedVendors = showAllVendors ? allEligibleVendors : vendors1099;

  // Year options for selectors
  const currentYear = new Date().getFullYear();
  const yearOptions = Array.from({ length: 5 }, (_, i) => currentYear - i);

  // Summary stats
  const mappedAccounts = accountMappings.filter((a) => a.taxCategoryId !== null).length;
  const totalAccounts = accountMappings.length;
  const vendorsNeedingTaxId = vendors1099.filter((v) => !v.taxId).length;
  const total1099Payments = vendors1099.reduce((sum, v) => sum + v.ytdPayments, 0);

  const tabs: { key: TabKey; label: string; icon: typeof FileText }[] = [
    { key: 'mapping', label: 'Tax Mapping', icon: FileText },
    { key: 'vendors', label: '1099 Vendors', icon: Users },
    { key: 'schedule-c', label: 'Schedule C', icon: Calculator },
  ];

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center h-64">
        <RefreshCw size={24} className="animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Tax & 1099 Compliance</h1>
          <p className="text-muted mt-1">Map accounts to tax lines, track 1099 vendors, and preview your Schedule C</p>
        </div>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2 overflow-x-auto">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors whitespace-nowrap',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Error Banner */}
      {(error || updateError) && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg flex items-center gap-2">
          <AlertTriangle size={16} className="text-red-500 flex-shrink-0" />
          <p className="text-sm text-red-700 dark:text-red-300">{error || updateError}</p>
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
                <FileText size={20} className="text-accent" />
              </div>
              <div>
                <p className="text-muted text-xs">Tax Mappings</p>
                <p className="text-xl font-bold text-main">{mappedAccounts} / {totalAccounts}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
                <Receipt size={20} className="text-amber-500" />
              </div>
              <div>
                <p className="text-muted text-xs">1099 Vendors ($600+)</p>
                <div className="flex items-center gap-2">
                  <p className="text-xl font-bold text-main">{vendors1099.length}</p>
                  {vendorsNeedingTaxId > 0 && (
                    <Badge variant="warning">{vendorsNeedingTaxId} missing Tax ID</Badge>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                <Calculator size={20} className="text-emerald-500" />
              </div>
              <div>
                <p className="text-muted text-xs">Total 1099 Payments (YTD)</p>
                <p className="text-xl font-bold text-main">{formatCurrency(total1099Payments)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tab Navigation */}
      <div className="flex items-center gap-1 border-b border-default">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-[1px]',
                activeTab === tab.key
                  ? 'border-accent text-accent'
                  : 'border-transparent text-muted hover:text-main hover:border-default'
              )}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      {activeTab === 'mapping' && (
        <TaxMappingTab
          groupedAccounts={groupedAccounts}
          taxCategories={taxCategories}
          onUpdate={handleUpdateMapping}
        />
      )}
      {activeTab === 'vendors' && (
        <Vendors1099Tab
          vendors={displayedVendors}
          showAll={showAllVendors}
          onToggleShowAll={() => setShowAllVendors(!showAllVendors)}
          totalAboveThreshold={vendors1099.length}
          totalEligible={allEligibleVendors.length}
          year={vendorYear}
          yearOptions={yearOptions}
          onYearChange={setVendorYear}
          onExport={export1099CSV}
        />
      )}
      {activeTab === 'schedule-c' && (
        <ScheduleCTab
          data={scheduleCData}
          year={scheduleCYear}
          yearOptions={yearOptions}
          onYearChange={setScheduleCYear}
        />
      )}
    </div>
  );
}

// ── Tax Mapping Tab ──
function TaxMappingTab({
  groupedAccounts,
  taxCategories,
  onUpdate,
}: {
  groupedAccounts: Record<string, AccountMapping[]>;
  taxCategories: TaxCategory[];
  onUpdate: (accountId: string, taxCategoryId: string | null) => Promise<void>;
}) {
  // Filter to only Schedule C categories for the dropdown
  const scheduleCCategories = taxCategories.filter((c) => c.taxForm === 'schedule_c');

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted">
          Map each account to a Schedule C tax line. This determines where amounts appear on your tax return.
        </p>
      </div>

      {Object.entries(groupedAccounts).map(([type, accounts]) => (
        <Card key={type}>
          <CardHeader>
            <CardTitle>{ACCOUNT_TYPE_LABELS[type] || type}</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-default">
              {/* Column header */}
              <div className="flex items-center gap-4 px-4 py-2 bg-secondary/50 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="w-20">Acct #</div>
                <div className="flex-1">Account Name</div>
                <div className="w-64">Tax Category</div>
                <div className="w-8" />
              </div>
              {accounts.map((account) => (
                <TaxMappingRow
                  key={account.id}
                  account={account}
                  taxCategories={scheduleCCategories}
                  onUpdate={onUpdate}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      ))}

      {Object.keys(groupedAccounts).length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <FileText size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No accounts found</h3>
            <p className="text-muted text-sm">
              Set up your Chart of Accounts first, then return here to map them to tax categories.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ── 1099 Vendors Tab ──
function Vendors1099Tab({
  vendors,
  showAll,
  onToggleShowAll,
  totalAboveThreshold,
  totalEligible,
  year,
  yearOptions,
  onYearChange,
  onExport,
}: {
  vendors: Vendor1099[];
  showAll: boolean;
  onToggleShowAll: () => void;
  totalAboveThreshold: number;
  totalEligible: number;
  year: number;
  yearOptions: number[];
  onYearChange: (year: number) => void;
  onExport: () => void;
}) {
  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="relative">
            <select
              value={year}
              onChange={(e) => onYearChange(Number(e.target.value))}
              className="px-3 py-1.5 text-sm bg-secondary border border-default rounded-lg text-main appearance-none pr-8 focus:outline-none focus:ring-1 focus:ring-accent"
            >
              {yearOptions.map((y) => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
            <ChevronDown size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
          </div>
          <button
            onClick={onToggleShowAll}
            className={cn(
              'px-3 py-1.5 text-xs font-medium rounded-lg transition-colors',
              showAll
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {showAll
              ? `All Eligible (${totalEligible})`
              : `$600+ Only (${totalAboveThreshold})`}
          </button>
        </div>
        <Button
          variant="secondary"
          size="sm"
          onClick={onExport}
          disabled={totalAboveThreshold === 0}
        >
          <Download size={14} />
          Export CSV
        </Button>
      </div>

      {/* Table */}
      <Card>
        <CardContent className="p-0">
          {/* Column header */}
          <div className="flex items-center gap-4 px-4 py-2 bg-secondary/50 text-xs font-medium text-muted uppercase tracking-wider border-b border-default">
            <div className="flex-1">Vendor Name</div>
            <div className="w-32">Tax ID</div>
            <div className="w-28 text-right">YTD Payments</div>
            <div className="w-28 text-right">Status</div>
          </div>
          {vendors.length === 0 ? (
            <div className="p-8 text-center text-muted text-sm">
              {showAll
                ? 'No 1099-eligible vendors found. Mark vendors as 1099-eligible in the Vendors page.'
                : 'No vendors with payments of $600 or more this year.'}
            </div>
          ) : (
            <div className="divide-y divide-default">
              {vendors.map((vendor) => (
                <VendorRow key={vendor.id} vendor={vendor} />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 1099 Summary */}
      {totalAboveThreshold > 0 && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <AlertTriangle size={16} className="text-amber-500 flex-shrink-0" />
              <p className="text-sm text-main">
                <span className="font-medium">{totalAboveThreshold} vendor{totalAboveThreshold !== 1 ? 's' : ''}</span>
                {' '}require 1099-NEC forms for {year}.
                {vendors.filter((v) => v.ytdPayments >= 600 && !v.taxId).length > 0 && (
                  <span className="text-red-600 dark:text-red-400 font-medium">
                    {' '}{vendors.filter((v) => v.ytdPayments >= 600 && !v.taxId).length} missing Tax ID — collect W-9 forms.
                  </span>
                )}
              </p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ── Schedule C Tab ──
function ScheduleCTab({
  data,
  year,
  yearOptions,
  onYearChange,
}: {
  data: ReturnType<typeof useTaxCompliance>['scheduleCData'];
  year: number;
  yearOptions: number[];
  onYearChange: (year: number) => void;
}) {
  return (
    <div className="space-y-6">
      {/* Year selector */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted">
          Preview based on posted journal entries mapped to Schedule C tax categories.
        </p>
        <div className="relative">
          <select
            value={year}
            onChange={(e) => onYearChange(Number(e.target.value))}
            className="px-3 py-1.5 text-sm bg-secondary border border-default rounded-lg text-main appearance-none pr-8 focus:outline-none focus:ring-1 focus:ring-accent"
          >
            {yearOptions.map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
          <ChevronDown size={14} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted pointer-events-none" />
        </div>
      </div>

      {/* Schedule C */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0">
          <div>
            <CardTitle>Schedule C (Form 1040) — {year}</CardTitle>
            <p className="text-xs text-muted mt-1">Profit or Loss From Business (Sole Proprietorship)</p>
          </div>
          <Badge variant="info">Preview</Badge>
        </CardHeader>
        <CardContent className="p-0">
          {!data ? (
            <div className="p-8 text-center">
              <RefreshCw size={24} className="mx-auto animate-spin text-muted mb-3" />
              <p className="text-sm text-muted">Loading Schedule C data...</p>
            </div>
          ) : data.lines.length <= 5 && data.netProfit === 0 ? (
            <div className="p-8 text-center">
              <Calculator size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">No data for {year}</h3>
              <p className="text-muted text-sm">
                Post journal entries and map accounts to tax categories to see your Schedule C preview.
              </p>
            </div>
          ) : (
            <div>
              {data.lines.map((line) => (
                <ScheduleCRow key={line.line} line={line} />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Quarterly Tax Estimate */}
      {data && data.netProfit !== 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Estimated Quarterly Tax Payments</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="space-y-1">
                <p className="text-xs text-muted uppercase tracking-wider">Self-Employment Tax (15.3%)</p>
                <p className="text-xl font-bold text-main tabular-nums">{formatCurrency(data.seTax)}</p>
                <p className="text-xs text-muted">
                  {data.netProfit > 0 ? '92.35%' : '0%'} of net profit x 15.3%
                </p>
              </div>
              <div className="space-y-1">
                <p className="text-xs text-muted uppercase tracking-wider">Est. Income Tax</p>
                <p className="text-xl font-bold text-main tabular-nums">
                  {formatCurrency(Math.max(0, (data.seTax + data.estimatedQuarterlyTax * 4 - data.seTax)))}
                </p>
                <p className="text-xs text-muted">Based on federal brackets (single filer)</p>
              </div>
              <div className="space-y-1">
                <p className="text-xs text-muted uppercase tracking-wider">Quarterly Payment</p>
                <p className={cn(
                  'text-2xl font-bold tabular-nums',
                  data.estimatedQuarterlyTax > 0 ? 'text-accent' : 'text-main'
                )}>
                  {formatCurrency(data.estimatedQuarterlyTax)}
                </p>
                <p className="text-xs text-muted">Due Jan 15, Apr 15, Jun 15, Sep 15</p>
              </div>
            </div>

            {/* Quarterly breakdown */}
            <div className="mt-6 pt-4 border-t border-default">
              <div className="grid grid-cols-4 gap-4">
                {[
                  { quarter: 'Q1', due: `Jan 15, ${year + 1}` },
                  { quarter: 'Q2', due: `Apr 15, ${year + 1}` },
                  { quarter: 'Q3', due: `Jun 15, ${year + 1}` },
                  { quarter: 'Q4', due: `Sep 15, ${year + 1}` },
                ].map((q) => (
                  <div
                    key={q.quarter}
                    className="p-3 bg-secondary rounded-lg text-center"
                  >
                    <p className="text-xs text-muted font-medium">{q.quarter}</p>
                    <p className="text-sm font-bold text-main tabular-nums mt-1">
                      {formatCurrency(data.estimatedQuarterlyTax)}
                    </p>
                    <p className="text-[10px] text-muted mt-0.5">Due {q.due}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="mt-4 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg flex items-start gap-2">
              <AlertTriangle size={14} className="text-amber-500 mt-0.5 flex-shrink-0" />
              <p className="text-xs text-amber-700 dark:text-amber-300">
                This is an estimate based on current journal entries. Consult your CPA for actual tax obligations.
                State taxes, credits, and deductions are not included.
              </p>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
