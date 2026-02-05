'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  DollarSign,
  TrendingUp,
  TrendingDown,
  CreditCard,
  Building,
  Plus,
  Download,
  Filter,
  ArrowRight,
  CheckCircle,
  AlertCircle,
  RefreshCw,
  FileText,
  PiggyBank,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Select } from '@/components/ui/input';
import { SimpleAreaChart, DonutChart, DonutLegend, SimpleBarChart } from '@/components/ui/charts';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { mockBankAccounts, mockTransactions, mockRevenueData } from '@/lib/mock-data';
import type { Transaction, TransactionCategory } from '@/types';

const categoryLabels: Record<TransactionCategory, string> = {
  materials: 'Materials',
  labor: 'Labor',
  fuel: 'Fuel',
  tools: 'Tools',
  equipment: 'Equipment',
  vehicle: 'Vehicle',
  insurance: 'Insurance',
  permits: 'Permits',
  advertising: 'Advertising',
  office: 'Office',
  utilities: 'Utilities',
  subcontractor: 'Subcontractor',
  income: 'Income',
  refund: 'Refund',
  transfer: 'Transfer',
  uncategorized: 'Uncategorized',
};

const categoryColors: Record<string, string> = {
  materials: '#3b82f6',
  labor: '#10b981',
  fuel: '#f59e0b',
  tools: '#8b5cf6',
  equipment: '#ec4899',
  vehicle: '#06b6d4',
  insurance: '#ef4444',
  permits: '#84cc16',
  income: '#22c55e',
};

export default function BooksPage() {
  const router = useRouter();
  const [period, setPeriod] = useState('month');
  const [categoryFilter, setCategoryFilter] = useState('all');

  // Calculate totals
  const totalIncome = mockTransactions
    .filter((t) => t.isIncome)
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpenses = mockTransactions
    .filter((t) => !t.isIncome)
    .reduce((sum, t) => sum + Math.abs(t.amount), 0);

  const netProfit = totalIncome - totalExpenses;

  // Calculate expenses by category
  const expensesByCategory = mockTransactions
    .filter((t) => !t.isIncome)
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + Math.abs(t.amount);
      return acc;
    }, {} as Record<string, number>);

  const expenseChartData = Object.entries(expensesByCategory)
    .map(([category, value]) => ({
      name: categoryLabels[category as TransactionCategory] || category,
      value,
      color: categoryColors[category] || '#64748b',
    }))
    .sort((a, b) => b.value - a.value);

  // Filter transactions
  const filteredTransactions = mockTransactions.filter((t) => {
    if (categoryFilter === 'all') return true;
    if (categoryFilter === 'income') return t.isIncome;
    if (categoryFilter === 'expenses') return !t.isIncome;
    return t.category === categoryFilter;
  });

  // Revenue chart data
  const revenueChartData = mockRevenueData.map((d) => ({
    date: d.date,
    value: d.profit,
  }));

  const totalBalance = mockBankAccounts.reduce((sum, a) => sum + a.currentBalance, 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Zafto Books</h1>
          <p className="text-muted mt-1">Track your finances and cash flow</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary">
            <Download size={16} />
            Export
          </Button>
          <Button onClick={() => {}}>
            <Plus size={16} />
            Add Transaction
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="bg-gradient-to-br from-emerald-500 to-emerald-600 text-white border-0">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-emerald-100 text-sm">Total Balance</p>
                <p className="text-3xl font-bold mt-1">{formatCurrency(totalBalance)}</p>
              </div>
              <div className="p-3 bg-white/20 rounded-xl">
                <Building size={24} />
              </div>
            </div>
            <div className="flex items-center gap-2 mt-4">
              <span className="text-emerald-100 text-sm">
                {mockBankAccounts.length} connected account{mockBankAccounts.length !== 1 ? 's' : ''}
              </span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-muted text-sm">Income</p>
                <p className="text-2xl font-bold text-main mt-1">{formatCurrency(totalIncome)}</p>
              </div>
              <div className="p-3 bg-emerald-100 dark:bg-emerald-900/30 rounded-xl">
                <TrendingUp size={24} className="text-emerald-600 dark:text-emerald-400" />
              </div>
            </div>
            <p className="text-sm text-emerald-600 mt-2">This month</p>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-muted text-sm">Expenses</p>
                <p className="text-2xl font-bold text-main mt-1">{formatCurrency(totalExpenses)}</p>
              </div>
              <div className="p-3 bg-red-100 dark:bg-red-900/30 rounded-xl">
                <TrendingDown size={24} className="text-red-600 dark:text-red-400" />
              </div>
            </div>
            <p className="text-sm text-red-600 mt-2">This month</p>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-muted text-sm">Net Profit</p>
                <p className={cn(
                  'text-2xl font-bold mt-1',
                  netProfit >= 0 ? 'text-emerald-600' : 'text-red-600'
                )}>
                  {formatCurrency(netProfit)}
                </p>
              </div>
              <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-xl">
                <PiggyBank size={24} className="text-blue-600 dark:text-blue-400" />
              </div>
            </div>
            <p className={cn('text-sm mt-2', netProfit >= 0 ? 'text-emerald-600' : 'text-red-600')}>
              {netProfit >= 0 ? '+' : ''}{((netProfit / totalIncome) * 100).toFixed(1)}% margin
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Profit Trend */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div>
              <CardTitle>Profit Trend</CardTitle>
              <p className="text-sm text-muted mt-1">Monthly net profit</p>
            </div>
            <Select
              options={[
                { value: 'month', label: 'This Month' },
                { value: 'quarter', label: 'This Quarter' },
                { value: 'year', label: 'This Year' },
              ]}
              value={period}
              onChange={(e) => setPeriod(e.target.value)}
              className="w-36"
            />
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <SimpleAreaChart data={revenueChartData} height={256} color="#10b981" />
            </div>
          </CardContent>
        </Card>

        {/* Expenses by Category */}
        <Card>
          <CardHeader>
            <CardTitle>Expenses by Category</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-center mb-4">
              <DonutChart
                data={expenseChartData}
                size={140}
                thickness={20}
                centerValue={formatCurrency(totalExpenses)}
                centerLabel="Total"
              />
            </div>
            <DonutLegend
              data={expenseChartData.slice(0, 5)}
              formatValue={(v) => formatCurrency(v)}
            />
          </CardContent>
        </Card>
      </div>

      {/* Bank Accounts & Transactions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Bank Accounts */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle>Connected Accounts</CardTitle>
            <Button variant="ghost" size="sm">
              <Plus size={14} />
              Add
            </Button>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {mockBankAccounts.map((account) => (
                <div key={account.id} className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-secondary rounded-lg">
                      {account.type === 'credit' ? (
                        <CreditCard size={20} className="text-muted" />
                      ) : (
                        <Building size={20} className="text-muted" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-main">{account.name}</p>
                      <p className="text-sm text-muted">****{account.mask}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-main">
                        {formatCurrency(account.currentBalance)}
                      </p>
                      <p className="text-xs text-muted">
                        Synced {formatDate(account.lastSynced)}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <div className="px-6 py-3 bg-secondary/50 border-t border-main">
              <button className="flex items-center gap-2 text-sm text-accent hover:underline">
                <RefreshCw size={14} />
                Sync All Accounts
              </button>
            </div>
          </CardContent>
        </Card>

        {/* Transactions */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <CardTitle>Recent Transactions</CardTitle>
            <Select
              options={[
                { value: 'all', label: 'All' },
                { value: 'income', label: 'Income' },
                { value: 'expenses', label: 'Expenses' },
              ]}
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="w-32"
            />
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main max-h-96 overflow-y-auto">
              {filteredTransactions.map((transaction) => (
                <TransactionRow key={transaction.id} transaction={transaction} />
              ))}
            </div>
            <div className="px-6 py-3 bg-secondary/50 border-t border-main">
              <Button variant="ghost" size="sm" className="w-full">
                View All Transactions
                <ArrowRight size={14} />
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Reports Section */}
      <Card>
        <CardHeader>
          <CardTitle>Reports & Exports</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <ReportCard
              title="Profit & Loss"
              description="Income vs expenses breakdown"
              icon={<FileText size={20} />}
            />
            <ReportCard
              title="Cash Flow"
              description="Money in and out over time"
              icon={<TrendingUp size={20} />}
            />
            <ReportCard
              title="Tax Summary"
              description="Export for your CPA"
              icon={<Download size={20} />}
            />
            <ReportCard
              title="1099 Report"
              description="Subcontractor payments"
              icon={<FileText size={20} />}
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function TransactionRow({ transaction }: { transaction: Transaction }) {
  const isIncome = transaction.isIncome;

  return (
    <div className="px-6 py-4 hover:bg-surface-hover transition-colors">
      <div className="flex items-center gap-4">
        <div
          className={cn(
            'p-2 rounded-lg',
            isIncome
              ? 'bg-emerald-100 dark:bg-emerald-900/30'
              : 'bg-slate-100 dark:bg-slate-800'
          )}
        >
          {isIncome ? (
            <TrendingUp size={18} className="text-emerald-600 dark:text-emerald-400" />
          ) : (
            <TrendingDown size={18} className="text-slate-600 dark:text-slate-400" />
          )}
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-medium text-main">{transaction.merchantName || transaction.description}</p>
          <div className="flex items-center gap-2 mt-0.5">
            <span className="text-sm text-muted">{formatDate(transaction.date)}</span>
            <Badge variant="default" size="sm">
              {categoryLabels[transaction.category]}
            </Badge>
            {!transaction.isReviewed && (
              <Badge variant="warning" size="sm">Needs Review</Badge>
            )}
          </div>
        </div>
        <p
          className={cn(
            'font-semibold',
            isIncome ? 'text-emerald-600' : 'text-main'
          )}
        >
          {isIncome ? '+' : ''}{formatCurrency(transaction.amount)}
        </p>
      </div>
    </div>
  );
}

function ReportCard({
  title,
  description,
  icon,
}: {
  title: string;
  description: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="p-4 bg-secondary rounded-xl hover:bg-surface-hover cursor-pointer transition-colors group">
      <div className="flex items-center gap-3 mb-2">
        <div className="p-2 bg-accent-light rounded-lg text-accent group-hover:bg-accent group-hover:text-white transition-colors">
          {icon}
        </div>
        <h4 className="font-medium text-main">{title}</h4>
      </div>
      <p className="text-sm text-muted">{description}</p>
    </div>
  );
}
