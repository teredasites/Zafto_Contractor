'use client';

import { useState, useCallback, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Building,
  RefreshCw,
  Plus,
  CreditCard,
  PiggyBank,
  Landmark,
  Unlink,
  CheckCircle,
  AlertCircle,
  Search,
  ChevronDown,
  ArrowUpRight,
  ArrowDownLeft,
} from 'lucide-react';
import { usePlaidLink } from 'react-plaid-link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useBanking,
  ACCOUNT_TYPE_LABELS,
  CATEGORY_LABELS,
} from '@/lib/hooks/use-banking';
import type { BankAccountData, BankTransactionData } from '@/lib/hooks/use-banking';

// ZBooks Navigation (shared across ZBooks sub-pages)
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Vendor Payments', href: '/dashboard/books/vendor-payments', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: true },
];

const accountTypeIcon: Record<string, typeof Building> = {
  checking: Landmark,
  savings: PiggyBank,
  credit_card: CreditCard,
};

function PlaidLinkButton({ onSuccess }: {
  onSuccess: (publicToken: string, metadata: { institution: { name: string; institution_id: string } | null }) => void;
}) {
  const { createLinkToken } = useBanking();
  const [linkToken, setLinkToken] = useState<string | null>(null);
  const [fetching, setFetching] = useState(false);

  const fetchToken = useCallback(async () => {
    setFetching(true);
    const token = await createLinkToken();
    setLinkToken(token);
    setFetching(false);
  }, [createLinkToken]);

  const { open, ready } = usePlaidLink({
    token: linkToken,
    onSuccess: (public_token, metadata) => {
      onSuccess(public_token, {
        institution: metadata.institution ? {
          name: metadata.institution.name,
          institution_id: metadata.institution.institution_id,
        } : null,
      });
      setLinkToken(null);
    },
    onExit: () => {
      setLinkToken(null);
    },
  });

  useEffect(() => {
    if (linkToken && ready) {
      open();
    }
  }, [linkToken, ready, open]);

  return (
    <Button onClick={fetchToken} disabled={fetching}>
      {fetching ? (
        <RefreshCw size={16} className="animate-spin" />
      ) : (
        <Plus size={16} />
      )}
      Connect Bank Account
    </Button>
  );
}

function AccountCard({
  account,
  syncing,
  onSync,
  onRefresh,
  onDisconnect,
  onSelect,
  isSelected,
}: {
  account: BankAccountData;
  syncing: boolean;
  onSync: () => void;
  onRefresh: () => void;
  onDisconnect: () => void;
  onSelect: () => void;
  isSelected: boolean;
}) {
  const [showMenu, setShowMenu] = useState(false);
  const Icon = accountTypeIcon[account.accountType] || Landmark;

  return (
    <Card
      className={cn(
        'cursor-pointer transition-all hover:border-accent/50',
        isSelected && 'border-accent ring-1 ring-accent/20'
      )}
      onClick={onSelect}
    >
      <CardContent className="p-5">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
              <Icon size={20} className="text-accent" />
            </div>
            <div>
              <p className="font-medium text-main text-sm">{account.accountName}</p>
              <p className="text-muted text-xs">
                {account.institutionName || 'Bank'}
                {account.mask && ` ••••${account.mask}`}
              </p>
            </div>
          </div>
          <div className="relative">
            <button
              onClick={(e) => { e.stopPropagation(); setShowMenu(!showMenu); }}
              className="p-1 hover:bg-secondary rounded"
            >
              <ChevronDown size={14} className="text-muted" />
            </button>
            {showMenu && (
              <div className="absolute right-0 top-8 z-10 w-44 bg-primary border border-default rounded-lg shadow-lg py-1">
                <button
                  onClick={(e) => { e.stopPropagation(); onSync(); setShowMenu(false); }}
                  className="w-full text-left px-3 py-2 text-sm text-main hover:bg-secondary flex items-center gap-2"
                  disabled={syncing}
                >
                  <RefreshCw size={14} className={syncing ? 'animate-spin' : ''} />
                  Sync Transactions
                </button>
                <button
                  onClick={(e) => { e.stopPropagation(); onRefresh(); setShowMenu(false); }}
                  className="w-full text-left px-3 py-2 text-sm text-main hover:bg-secondary flex items-center gap-2"
                  disabled={syncing}
                >
                  <RefreshCw size={14} />
                  Refresh Balance
                </button>
                <hr className="my-1 border-default" />
                <button
                  onClick={(e) => { e.stopPropagation(); onDisconnect(); setShowMenu(false); }}
                  className="w-full text-left px-3 py-2 text-sm text-red-500 hover:bg-secondary flex items-center gap-2"
                >
                  <Unlink size={14} />
                  Disconnect
                </button>
              </div>
            )}
          </div>
        </div>

        <div className="mt-4">
          <p className="text-2xl font-bold text-main">{formatCurrency(account.currentBalance)}</p>
          <div className="flex items-center gap-3 mt-1">
            <Badge variant="secondary">
              {ACCOUNT_TYPE_LABELS[account.accountType] || account.accountType}
            </Badge>
            {account.lastSyncedAt && (
              <span className="text-xs text-muted">
                Synced {new Date(account.lastSyncedAt).toLocaleDateString()}
              </span>
            )}
          </div>
        </div>

        {syncing && (
          <div className="mt-3 flex items-center gap-2 text-xs text-accent">
            <RefreshCw size={12} className="animate-spin" />
            Syncing...
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function TransactionRow({
  txn,
  onCategorize,
  onReview,
}: {
  txn: BankTransactionData;
  onCategorize: (id: string, category: string) => void;
  onReview: (id: string) => void;
}) {
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);

  return (
    <div className={cn(
      'flex items-center gap-3 px-4 py-3 border-b border-default last:border-b-0 hover:bg-secondary/50 transition-colors',
      !txn.isReviewed && 'bg-accent/5'
    )}>
      {/* Direction icon */}
      <div className={cn(
        'w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0',
        txn.isIncome ? 'bg-emerald-500/10' : 'bg-red-500/10'
      )}>
        {txn.isIncome ? (
          <ArrowDownLeft size={14} className="text-emerald-500" />
        ) : (
          <ArrowUpRight size={14} className="text-red-500" />
        )}
      </div>

      {/* Description */}
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-main truncate">{txn.description}</p>
        <div className="flex items-center gap-2 mt-0.5">
          <span className="text-xs text-muted">{txn.transactionDate}</span>
          {txn.merchantName && txn.merchantName !== txn.description && (
            <span className="text-xs text-muted truncate">{txn.merchantName}</span>
          )}
        </div>
      </div>

      {/* Category */}
      <div className="relative">
        <button
          onClick={() => setShowCategoryDropdown(!showCategoryDropdown)}
          className="text-xs px-2 py-1 rounded bg-secondary text-muted hover:text-main transition-colors"
        >
          {CATEGORY_LABELS[txn.category] || txn.category}
          {txn.categoryConfidence != null && txn.categoryConfidence < 1 && (
            <span className="ml-1 opacity-50">
              {Math.round(txn.categoryConfidence * 100)}%
            </span>
          )}
        </button>
        {showCategoryDropdown && (
          <div className="absolute right-0 top-8 z-20 w-40 max-h-64 overflow-y-auto bg-primary border border-default rounded-lg shadow-lg py-1">
            {Object.entries(CATEGORY_LABELS).map(([value, label]) => (
              <button
                key={value}
                onClick={() => {
                  onCategorize(txn.id, value);
                  setShowCategoryDropdown(false);
                }}
                className={cn(
                  'w-full text-left px-3 py-1.5 text-xs hover:bg-secondary',
                  txn.category === value ? 'text-accent font-medium' : 'text-main'
                )}
              >
                {label}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Matched */}
      {txn.matchedInvoiceId && (
        <Badge variant="success" className="text-xs">Matched</Badge>
      )}

      {/* Review status */}
      {!txn.isReviewed ? (
        <button
          onClick={() => onReview(txn.id)}
          className="text-muted hover:text-accent transition-colors"
          title="Mark as reviewed"
        >
          <AlertCircle size={16} />
        </button>
      ) : (
        <CheckCircle size={16} className="text-emerald-500 flex-shrink-0" />
      )}

      {/* Amount */}
      <span className={cn(
        'text-sm font-semibold tabular-nums min-w-[80px] text-right',
        txn.isIncome ? 'text-emerald-600' : 'text-main'
      )}>
        {txn.isIncome ? '+' : '-'}{formatCurrency(txn.amount)}
      </span>
    </div>
  );
}

export default function BankingPage() {
  const router = useRouter();
  const {
    accounts,
    transactions,
    loading,
    syncing,
    totalBalance,
    unreviewedCount,
    exchangeToken,
    syncTransactions,
    refreshBalance,
    disconnectAccount,
    categorizeTransaction,
    reviewTransaction,
    fetchTransactions,
  } = useBanking();

  const [selectedAccountId, setSelectedAccountId] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterReviewed, setFilterReviewed] = useState<'all' | 'unreviewed' | 'reviewed'>('all');

  const handlePlaidSuccess = async (publicToken: string, metadata: { institution: { name: string; institution_id: string } | null }) => {
    await exchangeToken(publicToken, metadata.institution);
  };

  const handleSync = async (accountId: string) => {
    const result = await syncTransactions(accountId);
    if (result) {
      console.log(`Synced ${result.synced} transactions, matched ${result.matched} invoices`);
    }
  };

  const handleDisconnect = async (accountId: string) => {
    if (!confirm('Disconnect this bank account? Transaction history will be preserved.')) return;
    await disconnectAccount(accountId);
    if (selectedAccountId === accountId) {
      setSelectedAccountId(null);
    }
  };

  // Filter transactions by selected account
  useEffect(() => {
    if (selectedAccountId) {
      fetchTransactions(selectedAccountId);
    } else {
      fetchTransactions();
    }
  }, [selectedAccountId, fetchTransactions]);

  // Apply search and filter
  const filteredTransactions = transactions.filter(txn => {
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (!txn.description.toLowerCase().includes(q) &&
          !(txn.merchantName || '').toLowerCase().includes(q)) {
        return false;
      }
    }
    if (filterReviewed === 'unreviewed' && txn.isReviewed) return false;
    if (filterReviewed === 'reviewed' && !txn.isReviewed) return false;
    return true;
  });

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center">
        <RefreshCw size={24} className="animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Banking</h1>
          <p className="text-muted mt-1">Connect and manage your bank accounts</p>
        </div>
        <PlaidLinkButton onSuccess={handlePlaidSuccess} />
      </div>

      {/* ZBooks Navigation */}
      <div className="flex items-center gap-2">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                <Building size={20} className="text-emerald-500" />
              </div>
              <div>
                <p className="text-muted text-xs">Total Balance</p>
                <p className="text-xl font-bold text-main">{formatCurrency(totalBalance)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
                <Landmark size={20} className="text-accent" />
              </div>
              <div>
                <p className="text-muted text-xs">Connected Accounts</p>
                <p className="text-xl font-bold text-main">{accounts.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
                <AlertCircle size={20} className="text-amber-500" />
              </div>
              <div>
                <p className="text-muted text-xs">Needs Review</p>
                <p className="text-xl font-bold text-main">{unreviewedCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Connected Accounts */}
      {accounts.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Building size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No bank accounts connected</h3>
            <p className="text-muted text-sm mb-6">
              Connect your business bank account to automatically import transactions and reconcile your books.
            </p>
            <PlaidLinkButton onSuccess={handlePlaidSuccess} />
          </CardContent>
        </Card>
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {accounts.map((account) => (
              <AccountCard
                key={account.id}
                account={account}
                syncing={syncing === account.id}
                onSync={() => handleSync(account.id)}
                onRefresh={() => refreshBalance(account.id)}
                onDisconnect={() => handleDisconnect(account.id)}
                onSelect={() => setSelectedAccountId(
                  selectedAccountId === account.id ? null : account.id
                )}
                isSelected={selectedAccountId === account.id}
              />
            ))}
          </div>

          {/* Transactions */}
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">
                  Transactions
                  {selectedAccountId && (
                    <span className="text-muted font-normal ml-2">
                      ({accounts.find(a => a.id === selectedAccountId)?.accountName})
                    </span>
                  )}
                </CardTitle>
                <div className="flex items-center gap-2">
                  {/* Search */}
                  <div className="relative">
                    <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-muted" />
                    <input
                      type="text"
                      placeholder="Search transactions..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="pl-8 pr-3 py-1.5 text-sm bg-secondary border border-default rounded-lg w-48 text-main placeholder:text-muted focus:outline-none focus:ring-1 focus:ring-accent"
                    />
                  </div>
                  {/* Filter */}
                  {(['all', 'unreviewed', 'reviewed'] as const).map((f) => (
                    <button
                      key={f}
                      onClick={() => setFilterReviewed(f)}
                      className={cn(
                        'px-3 py-1.5 text-xs font-medium rounded-lg transition-colors',
                        filterReviewed === f
                          ? 'bg-accent text-white'
                          : 'bg-secondary text-muted hover:text-main'
                      )}
                    >
                      {f === 'all' ? 'All' : f === 'unreviewed' ? 'Needs Review' : 'Reviewed'}
                    </button>
                  ))}
                </div>
              </div>
            </CardHeader>
            <CardContent className="p-0">
              {filteredTransactions.length === 0 ? (
                <div className="p-8 text-center text-muted text-sm">
                  {transactions.length === 0
                    ? 'No transactions yet. Click "Sync Transactions" on an account to import.'
                    : 'No transactions match your filters.'}
                </div>
              ) : (
                <div className="divide-y divide-default">
                  {filteredTransactions.map((txn) => (
                    <TransactionRow
                      key={txn.id}
                      txn={txn}
                      onCategorize={categorizeTransaction}
                      onReview={reviewTransaction}
                    />
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
