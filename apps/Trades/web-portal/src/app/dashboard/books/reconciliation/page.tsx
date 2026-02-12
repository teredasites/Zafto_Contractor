'use client';

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  CheckCircle,
  AlertCircle,
  RefreshCw,
  ArrowLeft,
  Save,
  Ban,
  ArrowDownLeft,
  ArrowUpRight,
  Landmark,
  Calendar,
  DollarSign,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import { useBanking, ACCOUNT_TYPE_LABELS } from '@/lib/hooks/use-banking';
import {
  useReconciliation,
} from '@/lib/hooks/use-reconciliation';
import type { ReconciliationData, ReconciliationTransaction } from '@/lib/hooks/use-reconciliation';
import type { BankAccountData } from '@/lib/hooks/use-banking';

// Ledger Navigation
const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reconciliation', href: '/dashboard/books/reconciliation', active: true },
];

type View = 'list' | 'active';

export default function ReconciliationPage() {
  const router = useRouter();
  const { accounts, loading: accountsLoading } = useBanking();
  const {
    reconciliations,
    loading: recLoading,
    startReconciliation,
    fetchUnreconciledTransactions,
    fetchMatchedTransactions,
    completeReconciliation,
    saveProgress,
    voidReconciliation,
    fetchReconciliations,
  } = useReconciliation();

  const [view, setView] = useState<View>('list');

  // Start form
  const [selectedAccountId, setSelectedAccountId] = useState('');
  const [statementDate, setStatementDate] = useState('');
  const [statementBalance, setStatementBalance] = useState('');
  const [starting, setStarting] = useState(false);

  // Active reconciliation
  const [activeRec, setActiveRec] = useState<ReconciliationData | null>(null);
  const [transactions, setTransactions] = useState<ReconciliationTransaction[]>([]);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(new Set());
  const [filterMode, setFilterMode] = useState<'all' | 'cleared' | 'uncleared'>('all');
  const [saving, setSaving] = useState(false);

  // Load active in-progress reconciliation if any
  useEffect(() => {
    const inProgress = reconciliations.find(r => r.status === 'in_progress');
    if (inProgress && view === 'list') {
      // Don't auto-open, just show in list
    }
  }, [reconciliations, view]);

  const handleStart = async () => {
    if (!selectedAccountId || !statementDate || !statementBalance) return;
    setStarting(true);

    const rec = await startReconciliation(
      selectedAccountId,
      statementDate,
      parseFloat(statementBalance),
    );

    if (rec) {
      setActiveRec(rec);
      const txns = await fetchUnreconciledTransactions(selectedAccountId);
      setTransactions(txns);
      setCheckedIds(new Set());
      setView('active');
    }
    setStarting(false);
  };

  const handleResume = async (rec: ReconciliationData) => {
    setActiveRec(rec);
    // Fetch both unreconciled AND already-tagged transactions
    const [unreconciled, matched] = await Promise.all([
      fetchUnreconciledTransactions(rec.bankAccountId),
      fetchMatchedTransactions(rec.id),
    ]);

    // Merge: matched ones should be checked
    const matchedIds = new Set(matched.map(t => t.id));
    const allTxns = [...matched, ...unreconciled.filter(t => !matchedIds.has(t.id))];
    allTxns.sort((a, b) => a.transactionDate.localeCompare(b.transactionDate));

    setTransactions(allTxns);
    setCheckedIds(matchedIds);
    setView('active');
  };

  const handleToggle = (txnId: string) => {
    setCheckedIds(prev => {
      const next = new Set(prev);
      if (next.has(txnId)) next.delete(txnId);
      else next.add(txnId);
      return next;
    });
  };

  const handleSelectAll = () => {
    const visible = filteredTransactions.map(t => t.id);
    setCheckedIds(prev => {
      const next = new Set(prev);
      const allChecked = visible.every(id => next.has(id));
      if (allChecked) {
        visible.forEach(id => next.delete(id));
      } else {
        visible.forEach(id => next.add(id));
      }
      return next;
    });
  };

  // Calculate cleared balance
  const clearedBalance = useMemo(() => {
    let total = 0;
    for (const txn of transactions) {
      if (checkedIds.has(txn.id)) {
        total += txn.isIncome ? txn.amount : -txn.amount;
      }
    }
    return Math.round(total * 100) / 100;
  }, [transactions, checkedIds]);

  const stmtBal = activeRec?.statementBalance ?? 0;
  const difference = Math.round((stmtBal - clearedBalance) * 100) / 100;
  const isBalanced = Math.abs(difference) < 0.005;

  const filteredTransactions = useMemo(() => {
    return transactions.filter(txn => {
      if (filterMode === 'cleared') return checkedIds.has(txn.id);
      if (filterMode === 'uncleared') return !checkedIds.has(txn.id);
      return true;
    });
  }, [transactions, filterMode, checkedIds]);

  const handleComplete = async () => {
    if (!activeRec || !isBalanced) return;
    setSaving(true);
    const success = await completeReconciliation(
      activeRec.id,
      Array.from(checkedIds),
      clearedBalance,
      stmtBal,
    );
    setSaving(false);
    if (success) {
      setView('list');
      setActiveRec(null);
    }
  };

  const handleSaveProgress = async () => {
    if (!activeRec) return;
    setSaving(true);
    await saveProgress(
      activeRec.id,
      Array.from(checkedIds),
      clearedBalance,
      stmtBal,
    );
    setSaving(false);
  };

  const handleVoid = async (recId: string) => {
    if (!confirm('Void this reconciliation? All matched transactions will be un-reconciled.')) return;
    await voidReconciliation(recId);
  };

  const handleBack = () => {
    setView('list');
    setActiveRec(null);
    fetchReconciliations();
  };

  const loading = accountsLoading || recLoading;

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center">
        <RefreshCw size={24} className="animate-spin text-muted" />
      </div>
    );
  }

  const selectedAccount = accounts.find(a => a.id === (activeRec?.bankAccountId || selectedAccountId));

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {view === 'active' && (
            <button onClick={handleBack} className="p-2 hover:bg-secondary rounded-lg">
              <ArrowLeft size={20} className="text-muted" />
            </button>
          )}
          <div>
            <h1 className="text-2xl font-semibold text-main">Bank Reconciliation</h1>
            <p className="text-muted mt-1">
              {view === 'active'
                ? `Reconciling ${selectedAccount?.accountName || 'Account'}`
                : 'Match your bank statements to your records'}
            </p>
          </div>
        </div>
      </div>

      {/* Ledger Navigation */}
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

      {view === 'list' ? (
        <>
          {/* Start New Reconciliation */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Start New Reconciliation</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-end gap-4">
                <div className="flex-1">
                  <label className="text-xs text-muted block mb-1">Bank Account</label>
                  <select
                    value={selectedAccountId}
                    onChange={(e) => setSelectedAccountId(e.target.value)}
                    className="w-full px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
                  >
                    <option value="">Select account...</option>
                    {accounts.map((acct) => (
                      <option key={acct.id} value={acct.id}>
                        {acct.accountName} ({ACCOUNT_TYPE_LABELS[acct.accountType]} {acct.mask ? `••••${acct.mask}` : ''})
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-xs text-muted block mb-1">Statement Date</label>
                  <input
                    type="date"
                    value={statementDate}
                    onChange={(e) => setStatementDate(e.target.value)}
                    className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main focus:outline-none focus:ring-1 focus:ring-accent"
                  />
                </div>
                <div>
                  <label className="text-xs text-muted block mb-1">Statement Ending Balance</label>
                  <input
                    type="number"
                    step="0.01"
                    value={statementBalance}
                    onChange={(e) => setStatementBalance(e.target.value)}
                    placeholder="0.00"
                    className="px-3 py-2 bg-secondary border border-default rounded-lg text-sm text-main w-40 focus:outline-none focus:ring-1 focus:ring-accent"
                  />
                </div>
                <Button
                  onClick={handleStart}
                  disabled={!selectedAccountId || !statementDate || !statementBalance || starting}
                >
                  {starting ? <RefreshCw size={16} className="animate-spin" /> : <Landmark size={16} />}
                  Start
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Past Reconciliations */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Reconciliation History</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {reconciliations.length === 0 ? (
                <div className="p-8 text-center text-muted text-sm">
                  No reconciliations yet. Start one above.
                </div>
              ) : (
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b border-default">
                      <th className="text-left px-4 py-3 text-muted font-medium">Account</th>
                      <th className="text-left px-4 py-3 text-muted font-medium">Statement Date</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Statement Balance</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Difference</th>
                      <th className="text-center px-4 py-3 text-muted font-medium">Status</th>
                      <th className="text-right px-4 py-3 text-muted font-medium">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reconciliations.map((rec) => {
                      const acct = accounts.find(a => a.id === rec.bankAccountId);
                      return (
                        <tr key={rec.id} className="border-b border-default last:border-b-0 hover:bg-secondary/50">
                          <td className="px-4 py-3 text-main">
                            {acct?.accountName || 'Unknown'}
                            {acct?.mask && <span className="text-muted ml-1">••••{acct.mask}</span>}
                          </td>
                          <td className="px-4 py-3 text-main">{rec.statementDate}</td>
                          <td className="px-4 py-3 text-main text-right tabular-nums">
                            {formatCurrency(rec.statementBalance)}
                          </td>
                          <td className={cn(
                            'px-4 py-3 text-right tabular-nums font-medium',
                            rec.difference === 0 ? 'text-emerald-600' : 'text-red-500'
                          )}>
                            {rec.difference != null ? formatCurrency(rec.difference) : '-'}
                          </td>
                          <td className="px-4 py-3 text-center">
                            <Badge variant={
                              rec.status === 'completed' ? 'success'
                                : rec.status === 'voided' ? 'error'
                                : 'warning'
                            }>
                              {rec.status === 'in_progress' ? 'In Progress' : rec.status}
                            </Badge>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <div className="flex items-center justify-end gap-2">
                              {rec.status === 'in_progress' && (
                                <Button variant="secondary" onClick={() => handleResume(rec)}>
                                  Resume
                                </Button>
                              )}
                              {rec.status === 'completed' && (
                                <Button variant="secondary" onClick={() => handleVoid(rec.id)}>
                                  <Ban size={14} />
                                  Void
                                </Button>
                              )}
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              )}
            </CardContent>
          </Card>
        </>
      ) : (
        /* Active Reconciliation View */
        <>
          {/* Balance Summary */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-1">
                  <Calendar size={14} className="text-muted" />
                  <span className="text-xs text-muted">Statement Date</span>
                </div>
                <p className="text-lg font-semibold text-main">{activeRec?.statementDate}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-1">
                  <DollarSign size={14} className="text-muted" />
                  <span className="text-xs text-muted">Statement Balance</span>
                </div>
                <p className="text-lg font-semibold text-main">{formatCurrency(stmtBal)}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-1">
                  <CheckCircle size={14} className="text-muted" />
                  <span className="text-xs text-muted">Cleared Balance</span>
                </div>
                <p className="text-lg font-semibold text-main">{formatCurrency(clearedBalance)}</p>
              </CardContent>
            </Card>
            <Card className={cn(isBalanced ? 'border-emerald-500/50' : 'border-red-500/50')}>
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-1">
                  {isBalanced
                    ? <CheckCircle size={14} className="text-emerald-500" />
                    : <AlertCircle size={14} className="text-red-500" />
                  }
                  <span className="text-xs text-muted">Difference</span>
                </div>
                <p className={cn(
                  'text-lg font-semibold',
                  isBalanced ? 'text-emerald-600' : 'text-red-500'
                )}>
                  {formatCurrency(difference)}
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Action Bar */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              {(['all', 'cleared', 'uncleared'] as const).map((f) => (
                <button
                  key={f}
                  onClick={() => setFilterMode(f)}
                  className={cn(
                    'px-3 py-1.5 text-xs font-medium rounded-lg transition-colors',
                    filterMode === f
                      ? 'bg-accent text-white'
                      : 'bg-secondary text-muted hover:text-main'
                  )}
                >
                  {f === 'all' ? `All (${transactions.length})`
                    : f === 'cleared' ? `Cleared (${checkedIds.size})`
                    : `Uncleared (${transactions.length - checkedIds.size})`}
                </button>
              ))}
            </div>
            <div className="flex items-center gap-2">
              <Button variant="secondary" onClick={handleSaveProgress} disabled={saving}>
                <Save size={14} />
                {saving ? 'Saving...' : 'Finish Later'}
              </Button>
              <Button
                onClick={handleComplete}
                disabled={!isBalanced || saving || checkedIds.size === 0}
              >
                <CheckCircle size={14} />
                Complete Reconciliation
              </Button>
            </div>
          </div>

          {/* Transaction List */}
          <Card>
            <CardContent className="p-0">
              {/* Header row */}
              <div className="flex items-center gap-3 px-4 py-3 border-b border-default bg-secondary/30">
                <input
                  type="checkbox"
                  checked={filteredTransactions.length > 0 && filteredTransactions.every(t => checkedIds.has(t.id))}
                  onChange={handleSelectAll}
                  className="w-4 h-4 accent-accent"
                />
                <span className="flex-1 text-xs font-medium text-muted">Date</span>
                <span className="flex-[3] text-xs font-medium text-muted">Description</span>
                <span className="w-24 text-right text-xs font-medium text-muted">Deposits</span>
                <span className="w-24 text-right text-xs font-medium text-muted">Payments</span>
              </div>

              {filteredTransactions.length === 0 ? (
                <div className="p-8 text-center text-muted text-sm">
                  No transactions to reconcile.
                </div>
              ) : (
                filteredTransactions.map((txn) => {
                  const isChecked = checkedIds.has(txn.id);
                  return (
                    <div
                      key={txn.id}
                      className={cn(
                        'flex items-center gap-3 px-4 py-3 border-b border-default last:border-b-0 cursor-pointer hover:bg-secondary/50 transition-colors',
                        isChecked && 'bg-emerald-500/5'
                      )}
                      onClick={() => handleToggle(txn.id)}
                    >
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => handleToggle(txn.id)}
                        onClick={(e) => e.stopPropagation()}
                        className="w-4 h-4 accent-accent"
                      />
                      <span className="flex-1 text-sm text-main tabular-nums">
                        {txn.transactionDate}
                      </span>
                      <div className="flex-[3] flex items-center gap-2">
                        {txn.isIncome ? (
                          <ArrowDownLeft size={12} className="text-emerald-500 flex-shrink-0" />
                        ) : (
                          <ArrowUpRight size={12} className="text-red-500 flex-shrink-0" />
                        )}
                        <span className="text-sm text-main truncate">{txn.description}</span>
                      </div>
                      <span className="w-24 text-right text-sm tabular-nums text-emerald-600">
                        {txn.isIncome ? formatCurrency(txn.amount) : ''}
                      </span>
                      <span className="w-24 text-right text-sm tabular-nums text-main">
                        {!txn.isIncome ? formatCurrency(txn.amount) : ''}
                      </span>
                    </div>
                  );
                })
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
