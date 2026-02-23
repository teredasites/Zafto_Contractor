'use client';

import { useState } from 'react';
import {
  ChevronDown,
  ChevronRight,
  Plus,
  Pencil,
  Search,
  ToggleLeft,
  ToggleRight,
  Lock,
  ArrowLeft,
} from 'lucide-react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useAccounts, ACCOUNT_TYPE_LABELS } from '@/lib/hooks/use-accounts';
import { useAccountBalances } from '@/lib/hooks/use-zbooks';
import type { AccountData, TaxCategoryData } from '@/lib/hooks/use-accounts';
import { useTranslation } from '@/lib/translations';

const typeOrder = ['asset', 'liability', 'equity', 'revenue', 'cogs', 'expense'];
const typeColors: Record<string, string> = {
  asset: 'text-blue-600 dark:text-blue-400',
  liability: 'text-orange-600 dark:text-orange-400',
  equity: 'text-purple-600 dark:text-purple-400',
  revenue: 'text-emerald-600 dark:text-emerald-400',
  cogs: 'text-amber-600 dark:text-amber-400',
  expense: 'text-red-600 dark:text-red-400',
};
const typeBgColors: Record<string, string> = {
  asset: 'bg-blue-50 dark:bg-blue-900/20',
  liability: 'bg-orange-50 dark:bg-orange-900/20',
  equity: 'bg-purple-50 dark:bg-purple-900/20',
  revenue: 'bg-emerald-50 dark:bg-emerald-900/20',
  cogs: 'bg-amber-50 dark:bg-amber-900/20',
  expense: 'bg-red-50 dark:bg-red-900/20',
};

export default function ChartOfAccountsPage() {
  const { t } = useTranslation();
  const { accounts, groupedAccounts, taxCategories, loading, error, createAccount, updateAccount, deactivateAccount, reactivateAccount, checkAccountHasEntries, refetch } = useAccounts();
  const { accounts: balanceData } = useAccountBalances();
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<string>('all');
  const [showInactive, setShowInactive] = useState(false);
  const [expandedTypes, setExpandedTypes] = useState<Set<string>>(new Set(typeOrder));
  const [modalOpen, setModalOpen] = useState(false);
  const [editingAccount, setEditingAccount] = useState<AccountData | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  // Build balance lookup
  const balanceMap = new Map<string, { balance: number; totalDebits: number; totalCredits: number }>();
  for (const b of balanceData) {
    balanceMap.set(b.id, { balance: b.balance, totalDebits: b.totalDebits, totalCredits: b.totalCredits });
  }

  // Filter accounts
  const filteredAccounts = accounts.filter((a) => {
    if (!showInactive && !a.isActive) return false;
    if (filterType !== 'all' && a.accountType !== filterType) return false;
    if (search) {
      const q = search.toLowerCase();
      return a.accountNumber.toLowerCase().includes(q) || a.accountName.toLowerCase().includes(q);
    }
    return true;
  });

  // Group filtered
  const filteredGrouped = typeOrder.reduce((groups, type) => {
    groups[type] = filteredAccounts.filter((a) => a.accountType === type);
    return groups;
  }, {} as Record<string, AccountData[]>);

  const toggleType = (type: string) => {
    const next = new Set(expandedTypes);
    if (next.has(type)) next.delete(type);
    else next.add(type);
    setExpandedTypes(next);
  };

  // Summary totals
  const totalAssets = filteredAccounts.filter((a) => a.accountType === 'asset').reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);
  const totalLiabilities = filteredAccounts.filter((a) => a.accountType === 'liability').reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);
  const totalEquity = filteredAccounts.filter((a) => a.accountType === 'equity').reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);
  const totalRevenue = filteredAccounts.filter((a) => a.accountType === 'revenue').reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);
  const totalExpenses = filteredAccounts.filter((a) => a.accountType === 'cogs' || a.accountType === 'expense').reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);

  const handleDeactivate = async (account: AccountData) => {
    setActionError(null);
    try {
      await deactivateAccount(account.id);
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : 'Failed to deactivate account');
    }
  };

  const handleReactivate = async (account: AccountData) => {
    setActionError(null);
    try {
      await reactivateAccount(account.id);
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : 'Failed to reactivate account');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link href="/dashboard/books" className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </Link>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('booksAccounts.title')}</h1>
            <p className="text-muted mt-0.5">{accounts.filter((a) => a.isActive).length} active accounts</p>
          </div>
        </div>
        <Button onClick={() => { setEditingAccount(null); setModalOpen(true); }}>
          <Plus size={16} />
          Add Account
        </Button>
      </div>

      {/* Summary Row */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        <SummaryCard label={t('common.totalAssets')} value={totalAssets} color="blue" />
        <SummaryCard label="Total Liabilities" value={totalLiabilities} color="orange" />
        <SummaryCard label="Total Equity" value={totalEquity} color="purple" />
        <SummaryCard label={t('customers.totalRevenue')} value={totalRevenue} color="emerald" />
        <SummaryCard label={t('dashboard.totalExpenses')} value={totalExpenses} color="red" />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
          <Input
            placeholder="Search accounts..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <div className="flex items-center gap-1.5">
          {['all', ...typeOrder].map((type) => (
            <button
              key={type}
              onClick={() => setFilterType(type)}
              className={cn(
                'px-3 py-1.5 text-xs font-medium rounded-md transition-colors',
                filterType === type
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main'
              )}
            >
              {type === 'all' ? 'All' : ACCOUNT_TYPE_LABELS[type] || type}
            </button>
          ))}
        </div>
        <button
          onClick={() => setShowInactive(!showInactive)}
          className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md bg-secondary text-muted hover:text-main transition-colors"
        >
          {showInactive ? <ToggleRight size={14} /> : <ToggleLeft size={14} />}
          {showInactive ? 'Hiding inactive' : 'Show inactive'}
        </button>
      </div>

      {/* Error banner */}
      {(error || actionError) && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">
          {error || actionError}
        </div>
      )}

      {/* Account Groups */}
      <div className="space-y-3">
        {typeOrder.map((type) => {
          const typeAccounts = filteredGrouped[type] || [];
          if (typeAccounts.length === 0 && filterType !== 'all' && filterType !== type) return null;
          const isExpanded = expandedTypes.has(type);
          const typeTotal = typeAccounts.reduce((s, a) => s + (balanceMap.get(a.id)?.balance || 0), 0);

          return (
            <Card key={type}>
              <button
                onClick={() => toggleType(type)}
                className="w-full flex items-center justify-between px-6 py-4 hover:bg-surface-hover transition-colors"
              >
                <div className="flex items-center gap-3">
                  {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                  <div className={cn('px-2 py-0.5 rounded text-xs font-semibold uppercase tracking-wide', typeBgColors[type], typeColors[type])}>
                    {ACCOUNT_TYPE_LABELS[type]}
                  </div>
                  <span className="text-sm text-muted">{typeAccounts.length} account{typeAccounts.length !== 1 ? 's' : ''}</span>
                </div>
                <span className={cn('font-semibold tabular-nums', typeColors[type])}>
                  {formatCurrency(typeTotal)}
                </span>
              </button>

              {isExpanded && typeAccounts.length > 0 && (
                <div className="border-t border-main">
                  {/* Table header */}
                  <div className="grid grid-cols-12 gap-2 px-6 py-2 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50">
                    <div className="col-span-2">{t('booksAccounts.number')}</div>
                    <div className="col-span-4">{t('common.name')}</div>
                    <div className="col-span-2 text-right">{t('booksAccounts.debits')}</div>
                    <div className="col-span-2 text-right">{t('booksAccounts.credits')}</div>
                    <div className="col-span-1 text-right">{t('common.balance')}</div>
                    <div className="col-span-1 text-right">{t('common.actions')}</div>
                  </div>
                  {/* Rows */}
                  {typeAccounts.map((account) => {
                    const bal = balanceMap.get(account.id);
                    const isChild = !!account.parentAccountId;

                    return (
                      <div
                        key={account.id}
                        className={cn(
                          'grid grid-cols-12 gap-2 px-6 py-3 items-center border-t border-main/50 hover:bg-surface-hover transition-colors',
                          !account.isActive && 'opacity-50'
                        )}
                      >
                        <div className={cn('col-span-2 font-mono text-sm', isChild && 'pl-6')}>
                          {account.accountNumber}
                        </div>
                        <div className="col-span-4 flex items-center gap-2">
                          <span className="text-sm font-medium text-main truncate">{account.accountName}</span>
                          {account.isSystem && (
                            <Lock size={12} className="text-muted flex-shrink-0" />
                          )}
                          {!account.isActive && (
                            <Badge variant="default" size="sm">{t('common.inactive')}</Badge>
                          )}
                        </div>
                        <div className="col-span-2 text-right text-sm tabular-nums text-muted">
                          {formatCurrency(bal?.totalDebits || 0)}
                        </div>
                        <div className="col-span-2 text-right text-sm tabular-nums text-muted">
                          {formatCurrency(bal?.totalCredits || 0)}
                        </div>
                        <div className={cn(
                          'col-span-1 text-right text-sm font-medium tabular-nums',
                          (bal?.balance || 0) >= 0 ? 'text-main' : 'text-red-600'
                        )}>
                          {formatCurrency(bal?.balance || 0)}
                        </div>
                        <div className="col-span-1 flex items-center justify-end gap-1">
                          {!account.isSystem && (
                            <>
                              <button
                                onClick={() => { setEditingAccount(account); setModalOpen(true); }}
                                className="p-1 text-muted hover:text-main rounded transition-colors"
                                title={t('common.edit')}
                              >
                                <Pencil size={14} />
                              </button>
                              {account.isActive ? (
                                <button
                                  onClick={() => handleDeactivate(account)}
                                  className="p-1 text-muted hover:text-red-600 rounded transition-colors"
                                  title={t('common.deactivate')}
                                >
                                  <ToggleRight size={14} />
                                </button>
                              ) : (
                                <button
                                  onClick={() => handleReactivate(account)}
                                  className="p-1 text-muted hover:text-emerald-600 rounded transition-colors"
                                  title="Reactivate"
                                >
                                  <ToggleLeft size={14} />
                                </button>
                              )}
                            </>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {isExpanded && typeAccounts.length === 0 && (
                <div className="border-t border-main px-6 py-8 text-center text-sm text-muted">
                  No accounts in this category
                </div>
              )}
            </Card>
          );
        })}
      </div>

      {/* Add/Edit Modal */}
      {modalOpen && (
        <AccountModal
          account={editingAccount}
          accounts={accounts}
          taxCategories={taxCategories}
          onSave={async (data) => {
            if (editingAccount) {
              await updateAccount(editingAccount.id, data);
            } else {
              await createAccount(data as Parameters<typeof createAccount>[0]);
            }
            setModalOpen(false);
            setEditingAccount(null);
          }}
          onClose={() => { setModalOpen(false); setEditingAccount(null); }}
        />
      )}
    </div>
  );
}

function SummaryCard({ label, value, color }: { label: string; value: number; color: string }) {
  const colorMap: Record<string, string> = {
    blue: 'text-blue-600 dark:text-blue-400',
    orange: 'text-orange-600 dark:text-orange-400',
    purple: 'text-purple-600 dark:text-purple-400',
    emerald: 'text-emerald-600 dark:text-emerald-400',
    red: 'text-red-600 dark:text-red-400',
  };

  return (
    <Card>
      <CardContent className="p-4">
        <p className="text-xs text-muted uppercase tracking-wide">{label}</p>
        <p className={cn('text-lg font-semibold mt-1 tabular-nums', colorMap[color])}>
          {formatCurrency(value)}
        </p>
      </CardContent>
    </Card>
  );
}

function AccountModal({
  account,
  accounts,
  taxCategories,
  onSave,
  onClose,
}: {
  account: AccountData | null;
  accounts: AccountData[];
  taxCategories: TaxCategoryData[];
  onSave: (data: Record<string, unknown>) => Promise<void>;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const isEdit = !!account;
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [accountNumber, setAccountNumber] = useState(account?.accountNumber || '');
  const [accountName, setAccountName] = useState(account?.accountName || '');
  const [accountType, setAccountType] = useState(account?.accountType || 'expense');
  const [normalBalance, setNormalBalance] = useState(account?.normalBalance || 'debit');
  const [parentAccountId, setParentAccountId] = useState(account?.parentAccountId || '');
  const [taxCategoryId, setTaxCategoryId] = useState(account?.taxCategoryId || '');
  const [description, setDescription] = useState(account?.description || '');

  // Auto-set normal balance based on type
  const handleTypeChange = (type: string) => {
    setAccountType(type);
    if (['asset', 'cogs', 'expense'].includes(type)) {
      setNormalBalance('debit');
    } else {
      setNormalBalance('credit');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);

    try {
      if (isEdit) {
        await onSave({
          accountName,
          description: description || null,
          taxCategoryId: taxCategoryId || null,
        });
      } else {
        if (!accountNumber.trim()) throw new Error('Account number is required');
        if (!accountName.trim()) throw new Error('Account name is required');
        await onSave({
          accountNumber: accountNumber.trim(),
          accountName: accountName.trim(),
          accountType,
          normalBalance,
          parentAccountId: parentAccountId || null,
          taxCategoryId: taxCategoryId || null,
          description: description || null,
        });
      }
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Save failed');
      setSaving(false);
    }
  };

  // Possible parents: same account type, no parent themselves
  const possibleParents = accounts.filter((a) => a.accountType === accountType && !a.parentAccountId && a.id !== account?.id);

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">{isEdit ? 'Edit Account' : 'Add Account'}</h2>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {!isEdit && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-main mb-1">{t('booksAccounts.accountNumber')}</label>
                <Input
                  value={accountNumber}
                  onChange={(e) => setAccountNumber(e.target.value)}
                  placeholder="e.g. 6100"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-main mb-1">{t('booksAccounts.accountType')}</label>
                <select
                  value={accountType}
                  onChange={(e) => handleTypeChange(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
                >
                  {Object.entries(ACCOUNT_TYPE_LABELS).map(([val, label]) => (
                    <option key={val} value={val}>{label}</option>
                  ))}
                </select>
              </div>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-main mb-1">{t('common.accountName')}</label>
            <Input
              value={accountName}
              onChange={(e) => setAccountName(e.target.value)}
              placeholder="e.g. Marketing & Advertising"
              required
            />
          </div>

          {!isEdit && possibleParents.length > 0 && (
            <div>
              <label className="block text-sm font-medium text-main mb-1">Parent Account (optional)</label>
              <select
                value={parentAccountId}
                onChange={(e) => setParentAccountId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="">{t('common.none')}</option>
                {possibleParents.map((p) => (
                  <option key={p.id} value={p.id}>{p.accountNumber} — {p.accountName}</option>
                ))}
              </select>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-main mb-1">Tax Category (optional)</label>
            <select
              value={taxCategoryId}
              onChange={(e) => setTaxCategoryId(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
            >
              <option value="">{t('common.none')}</option>
              {taxCategories.map((tc) => (
                <option key={tc.id} value={tc.id}>
                  {tc.name}{tc.scheduleLineRef ? ` (${tc.scheduleLineRef})` : ''}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1">Description (optional)</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Optional description for this account"
              rows={2}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none"
            />
          </div>

          {err && (
            <p className="text-sm text-red-600">{err}</p>
          )}

          <div className="flex items-center justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>{t('common.cancel')}</Button>
            <Button type="submit" disabled={saving}>
              {saving ? 'Saving...' : isEdit ? 'Save Changes' : 'Add Account'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
