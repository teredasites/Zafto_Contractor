'use client';

import { useState, useMemo } from 'react';
import {
  Landmark,
  FileText,
  Settings,
  Calculator,
  BarChart3,
  Search,
  Plus,
  AlertCircle,
  CreditCard,
  ArrowUpRight,
  DollarSign,
  Clock,
  CheckCircle,
  XCircle,
  Send,
  RefreshCcw,
  TrendingUp,
  Percent,
  Zap,
  Shield,
  Key,
  Filter,
  Calendar,
  Building2,
  Banknote,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { useFinancing, type ApplicationStatus, type FinancingApplication, type FinancingProvider } from '@/lib/hooks/use-financing';
import { useTranslation } from '@/lib/translations';
import { formatCurrency } from '@/lib/format-locale';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
type Tab = 'applications' | 'providers' | 'calculator' | 'analytics';

// ---------------------------------------------------------------------------
// Status config
// ---------------------------------------------------------------------------
const statusConfig: Record<ApplicationStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  offered:   { label: 'Offered',   variant: 'secondary' },
  applied:   { label: 'Applied',   variant: 'info' },
  approved:  { label: 'Approved',  variant: 'success' },
  denied:    { label: 'Denied',    variant: 'error' },
  funded:    { label: 'Funded',    variant: 'purple' },
  expired:   { label: 'Expired',   variant: 'default' },
  cancelled: { label: 'Cancelled', variant: 'default' },
};

// ---------------------------------------------------------------------------
// Tab definitions
// ---------------------------------------------------------------------------
const TABS: { key: Tab; label: string; icon: typeof FileText }[] = [
  { key: 'applications', label: 'Applications', icon: FileText },
  { key: 'providers',    label: 'Providers',    icon: Settings },
  { key: 'calculator',   label: 'Calculator',   icon: Calculator },
  { key: 'analytics',    label: 'Analytics',    icon: BarChart3 },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function fmtPct(n: number): string {
  return `${n.toFixed(1)}%`;
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function calcMonthly(principal: number, annualRate: number, months: number): number {
  if (annualRate === 0) return principal / months;
  const r = annualRate / 100 / 12;
  return (principal * r * Math.pow(1 + r, months)) / (Math.pow(1 + r, months) - 1);
}

// ---------------------------------------------------------------------------
// Main Page Component
// ---------------------------------------------------------------------------
export default function FinancingPage() {
  const { t } = useTranslation();
  const { applications, providers, summary, loading, error, refresh } = useFinancing();
  const [activeTab, setActiveTab] = useState<Tab>('applications');

  // ---- Loading state ----
  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-52 mb-2" />
          <div className="skeleton h-4 w-80" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-24 mb-3" />
              <div className="skeleton h-7 w-20" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl">
          <div className="px-6 py-4 border-b border-main">
            <div className="skeleton h-5 w-40" />
          </div>
          {[...Array(5)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4 border-b border-main last:border-0">
              <div className="flex-1">
                <div className="skeleton h-4 w-44 mb-2" />
                <div className="skeleton h-3 w-32" />
              </div>
              <div className="skeleton h-5 w-20 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // ---- Error state ----
  if (error) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <h1 className="text-xl font-bold text-main">{t('financing.title')}</h1>
          <p className="text-sm text-muted mt-1">{t('financing.subtitle')}</p>
        </div>
        <Card>
          <CardContent className="py-16 text-center">
            <AlertCircle className="w-10 h-10 text-red-400 mx-auto mb-3" />
            <p className="text-main font-medium mb-1">{t('financing.failedToLoad')}</p>
            <p className="text-sm text-muted mb-4">{error}</p>
            <Button variant="outline" onClick={refresh}>
              <RefreshCcw className="w-4 h-4" />
              {t('common.retry')}
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  // ---- Data state ----
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-xl font-bold text-main flex items-center gap-2.5">
            <Landmark className="w-6 h-6 text-[var(--accent)]" />
            {t('financing.title')}
          </h1>
          <p className="text-sm text-muted mt-1">{t('financing.subtitle')}</p>
        </div>
        <Button onClick={() => setActiveTab('calculator')}>
          <Plus className="w-4 h-4" />
          {t('financing.offerFinancing')}
        </Button>
      </div>

      {/* Summary cards */}
      <SummaryCards applications={applications} summary={summary} />

      {/* Tab bar */}
      <div className="flex items-center gap-1 border-b border-main">
        {TABS.map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => setActiveTab(key)}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
              activeTab === key
                ? 'border-[var(--accent)] text-[var(--accent)]'
                : 'border-transparent text-muted hover:text-main'
            }`}
          >
            <Icon className="w-4 h-4" />
            {label}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === 'applications' && <ApplicationsTab applications={applications} />}
      {activeTab === 'providers' && <ProvidersTab providers={providers} />}
      {activeTab === 'calculator' && <CalculatorTab />}
      {activeTab === 'analytics' && <AnalyticsTab applications={applications} providers={providers} />}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Summary Cards
// ---------------------------------------------------------------------------
function SummaryCards({ applications, summary }: { applications: FinancingApplication[]; summary: { totalFundedAmount: number; activeApplications: number; totalFunded: number; avgFinancedAmount: number } }) {
  const cards = [
    { label: 'Total Funded', value: formatCurrency(summary.totalFundedAmount), icon: Banknote, accent: 'text-emerald-400' },
    { label: 'Active Applications', value: String(summary.activeApplications), icon: Clock, accent: 'text-blue-400' },
    { label: 'Funded This Month', value: String(summary.totalFunded), icon: CheckCircle, accent: 'text-purple-400' },
    { label: 'Avg. Financed Amount', value: formatCurrency(summary.avgFinancedAmount), icon: DollarSign, accent: 'text-amber-400' },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
      {cards.map((c) => (
        <Card key={c.label}>
          <CardContent className="py-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-muted uppercase tracking-wider">{c.label}</span>
              <c.icon className={`w-4 h-4 ${c.accent}`} />
            </div>
            <p className="text-2xl font-bold text-main">{c.value}</p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Applications Tab
// ---------------------------------------------------------------------------
function ApplicationsTab({ applications }: { applications: FinancingApplication[] }) {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | ApplicationStatus>('all');

  const filtered = useMemo(() => {
    return applications.filter(a => {
      const matchSearch = search === '' ||
        a.customerName.toLowerCase().includes(search.toLowerCase()) ||
        (a.jobName || '').toLowerCase().includes(search.toLowerCase()) ||
        (a.providerName || '').toLowerCase().includes(search.toLowerCase());
      const matchStatus = statusFilter === 'all' || a.status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [applications, search, statusFilter]);

  // Status pipeline counts
  const displayStatuses: ApplicationStatus[] = ['offered', 'applied', 'approved', 'denied', 'funded'];
  const pipelineCounts: Record<ApplicationStatus, number> = {
    offered: applications.filter(a => a.status === 'offered').length,
    applied: applications.filter(a => a.status === 'applied').length,
    approved: applications.filter(a => a.status === 'approved').length,
    denied: applications.filter(a => a.status === 'denied').length,
    funded: applications.filter(a => a.status === 'funded').length,
    expired: applications.filter(a => a.status === 'expired').length,
    cancelled: applications.filter(a => a.status === 'cancelled').length,
  };

  return (
    <div className="space-y-6">
      {/* Pipeline */}
      <div className="grid grid-cols-5 gap-3">
        {displayStatuses.map((s) => {
          const cfg = statusConfig[s];
          const isActive = statusFilter === s;
          return (
            <button
              key={s}
              onClick={() => setStatusFilter(statusFilter === s ? 'all' : s)}
              className={`flex flex-col items-center gap-1 p-3 rounded-xl border transition-all ${
                isActive
                  ? 'border-[var(--accent)] bg-[var(--accent)]/10'
                  : 'border-main bg-surface hover:border-[var(--accent)]/30'
              }`}
            >
              <span className="text-2xl font-bold text-main">{pipelineCounts[s]}</span>
              <Badge variant={cfg.variant} size="sm">{cfg.label}</Badge>
            </button>
          );
        })}
      </div>

      {/* Search + filter bar */}
      <div className="flex items-center gap-3">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted" />
          <input
            type="text"
            placeholder="Search by customer, job, or provider..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] transition-colors text-sm"
          />
        </div>
        <Button variant="outline" size="sm">
          <Filter className="w-4 h-4" />
          Filter
        </Button>
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <Card>
          <CardContent className="py-16 text-center">
            <FileText className="w-10 h-10 text-muted mx-auto mb-3" />
            <p className="text-main font-medium mb-1">No applications found</p>
            <p className="text-sm text-muted">
              {search || statusFilter !== 'all'
                ? 'Try adjusting your filters or search terms'
                : 'Offer financing on your next estimate to get started'}
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Customer</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Job</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Amount</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Monthly</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Term</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Provider</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Status</th>
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {filtered.map((app) => {
                  const cfg = statusConfig[app.status];
                  return (
                    <tr key={app.id} className="hover:bg-surface-hover transition-colors cursor-pointer">
                      <td className="px-6 py-3.5">
                        <span className="font-medium text-main">{app.customerName}</span>
                      </td>
                      <td className="px-6 py-3.5 text-muted">{app.jobName || '-'}</td>
                      <td className="px-6 py-3.5 font-medium text-main">{formatCurrency(app.amount)}</td>
                      <td className="px-6 py-3.5 text-muted">{app.monthlyPayment ? `${formatCurrency(app.monthlyPayment)}/mo` : '-'}</td>
                      <td className="px-6 py-3.5 text-muted">
                        {app.termMonths && app.interestRate
                          ? `${app.termMonths} mo @ ${fmtPct(app.interestRate)}`
                          : app.termMonths ? `${app.termMonths} mo` : '-'}
                      </td>
                      <td className="px-6 py-3.5 text-muted">{app.providerName || '-'}</td>
                      <td className="px-6 py-3.5">
                        <Badge variant={cfg.variant} dot>{cfg.label}</Badge>
                      </td>
                      <td className="px-6 py-3.5 text-muted">{fmtDate(app.dateApplied || app.createdAt)}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Providers Tab
// ---------------------------------------------------------------------------
function ProvidersTab({ providers }: { providers: FinancingProvider[] }) {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted">Connect financing providers to offer payment plans on your estimates.</p>
        <Button variant="outline" size="sm">
          <Plus className="w-4 h-4" />
          Add Provider
        </Button>
      </div>

      {providers.length === 0 ? (
        <Card>
          <CardContent className="py-16 text-center">
            <Building2 className="w-10 h-10 text-muted mx-auto mb-3" />
            <p className="text-main font-medium mb-1">No financing providers configured</p>
            <p className="text-sm text-muted">Add a provider like Wisetack, GreenSky, or Hearth to start offering financing</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {providers.map((p) => (
            <Card key={p.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-lg bg-[var(--accent)]/10 flex items-center justify-center text-[var(--accent)] font-bold text-lg">
                      {p.providerName.charAt(0)}
                    </div>
                    <div>
                      <CardTitle>{p.providerName}</CardTitle>
                    </div>
                  </div>
                  <Badge variant={p.connected ? 'success' : 'secondary'} dot>
                    {p.connected ? 'Connected' : 'Not Connected'}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {/* Connection status rows */}
                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 text-muted">
                        <Key className="w-3.5 h-3.5" />
                        API Key
                      </span>
                      {p.apiKeyConfigured ? (
                        <span className="flex items-center gap-1 text-emerald-400 text-xs font-medium">
                          <CheckCircle className="w-3.5 h-3.5" />
                          Configured
                        </span>
                      ) : (
                        <span className="flex items-center gap-1 text-muted text-xs font-medium">
                          <XCircle className="w-3.5 h-3.5" />
                          Not Set
                        </span>
                      )}
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 text-muted">
                        <Shield className="w-3.5 h-3.5" />
                        Merchant Fee
                      </span>
                      <span className="text-main font-medium">{fmtPct(p.merchantFeePct)}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 text-muted">
                        <DollarSign className="w-3.5 h-3.5" />
                        Range
                      </span>
                      <span className="text-main font-medium">{formatCurrency(p.minAmount)} - {formatCurrency(p.maxAmount)}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 text-muted">
                        <Calendar className="w-3.5 h-3.5" />
                        Terms
                      </span>
                      <span className="text-main font-medium">{p.availableTerms.map(t => `${t}mo`).join(', ')}</span>
                    </div>
                  </div>

                  {/* Action */}
                  <div className="pt-3">
                    {p.connected ? (
                      <Button variant="outline" size="sm" className="w-full">
                        <Settings className="w-4 h-4" />
                        Manage Settings
                      </Button>
                    ) : (
                      <Button variant="primary" size="sm" className="w-full">
                        <Zap className="w-4 h-4" />
                        Connect {p.providerName}
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Calculator Tab
// ---------------------------------------------------------------------------
function CalculatorTab() {
  const [jobAmount, setJobAmount] = useState<string>('15000');
  const [interestRate, setInterestRate] = useState<string>('7.99');
  const [selectedTerm, setSelectedTerm] = useState<number | null>(null);

  const amount = parseFloat(jobAmount) || 0;
  const rate = parseFloat(interestRate) || 0;
  const terms = [12, 24, 36, 48, 60];

  const paymentOptions = useMemo(() => {
    if (amount <= 0) return [];
    return terms.map(t => ({
      months: t,
      monthly: calcMonthly(amount, rate, t),
      totalCost: calcMonthly(amount, rate, t) * t,
      totalInterest: calcMonthly(amount, rate, t) * t - amount,
    }));
  }, [amount, rate]);

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Input panel */}
        <Card className="lg:col-span-1">
          <CardHeader>
            <CardTitle>Financing Parameters</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-5">
              <Input
                label="Job Amount"
                type="number"
                value={jobAmount}
                onChange={(e) => setJobAmount(e.target.value)}
                icon={<DollarSign className="w-4 h-4" />}
                placeholder="Enter job total"
              />
              <Input
                label="Annual Interest Rate (%)"
                type="number"
                value={interestRate}
                onChange={(e) => setInterestRate(e.target.value)}
                icon={<Percent className="w-4 h-4" />}
                placeholder="e.g. 7.99"
              />
              <div className="pt-2 space-y-2">
                <p className="text-xs text-muted">Quick Rates</p>
                <div className="flex flex-wrap gap-2">
                  {[0, 4.99, 5.99, 7.99, 9.99, 12.99].map(r => (
                    <button
                      key={r}
                      onClick={() => setInterestRate(String(r))}
                      className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-colors ${
                        parseFloat(interestRate) === r
                          ? 'border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]'
                          : 'border-main bg-surface text-muted hover:text-main'
                      }`}
                    >
                      {r === 0 ? '0% Promo' : `${r}%`}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Payment options */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Monthly Payment Options</CardTitle>
              {amount > 0 && (
                <span className="text-sm text-muted">
                  Financing {formatCurrency(amount)} at {fmtPct(rate)} APR
                </span>
              )}
            </div>
          </CardHeader>
          <CardContent>
            {amount <= 0 ? (
              <div className="py-12 text-center">
                <Calculator className="w-10 h-10 text-muted mx-auto mb-3" />
                <p className="text-main font-medium mb-1">Enter a job amount</p>
                <p className="text-sm text-muted">Set the job amount and interest rate to see monthly payment options</p>
              </div>
            ) : (
              <div className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  {paymentOptions.map((opt) => (
                    <button
                      key={opt.months}
                      onClick={() => setSelectedTerm(selectedTerm === opt.months ? null : opt.months)}
                      className={`p-4 rounded-xl border text-left transition-all ${
                        selectedTerm === opt.months
                          ? 'border-[var(--accent)] bg-[var(--accent)]/10 ring-1 ring-[var(--accent)]'
                          : 'border-main bg-surface hover:border-[var(--accent)]/30'
                      }`}
                    >
                      <p className="text-xs text-muted mb-1">{opt.months} months</p>
                      <p className="text-2xl font-bold text-main">{formatCurrency(opt.monthly)}</p>
                      <p className="text-xs text-muted mt-1">per month</p>
                      <div className="mt-3 pt-3 border-t border-main space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-muted">Total Cost</span>
                          <span className="text-main">{formatCurrency(Math.round(opt.totalCost))}</span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-muted">Total Interest</span>
                          <span className="text-amber-400">{formatCurrency(Math.round(opt.totalInterest))}</span>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>

                {selectedTerm !== null && (
                  <div className="flex items-center justify-between p-4 rounded-xl border border-[var(--accent)]/30 bg-[var(--accent)]/5">
                    <div>
                      <p className="text-sm font-medium text-main">
                        {selectedTerm}-month plan selected: {formatCurrency(calcMonthly(amount, rate, selectedTerm))}/mo
                      </p>
                      <p className="text-xs text-muted mt-0.5">
                        Customer pays {formatCurrency(Math.round(calcMonthly(amount, rate, selectedTerm) * selectedTerm))} total
                      </p>
                    </div>
                    <Button>
                      <Send className="w-4 h-4" />
                      Offer Financing
                    </Button>
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Info callout */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-start gap-3">
            <CreditCard className="w-5 h-5 text-[var(--accent)] mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-main">How Customer Financing Works</p>
              <p className="text-sm text-muted mt-1">
                When you offer financing, the customer receives a link to apply through the selected provider.
                Once approved and funded, you receive the full job amount minus the merchant fee. The customer
                makes monthly payments directly to the financing provider.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Analytics Tab
// ---------------------------------------------------------------------------
function AnalyticsTab({ applications, providers }: { applications: FinancingApplication[]; providers: FinancingProvider[] }) {
  const funded = applications.filter(a => a.status === 'funded');
  const totalFundedRevenue = funded.reduce((s, a) => s + a.amount, 0);
  const avgFinancedJob = funded.length > 0 ? totalFundedRevenue / funded.length : 0;

  const approvalRate = applications.length > 0
    ? Math.round((applications.filter(a => a.status === 'approved' || a.status === 'funded').length / applications.length) * 100)
    : 0;

  // Group by provider
  const providerStats = providers.map(p => {
    const provApps = applications.filter(a => a.providerId === p.id || a.providerName === p.providerName);
    const provFunded = provApps.filter(a => a.status === 'funded');
    return {
      name: p.providerName,
      applications: provApps.length,
      funded: provFunded.reduce((s, a) => s + a.amount, 0),
      approvalRate: provApps.length > 0
        ? Math.round((provApps.filter(a => a.status === 'approved' || a.status === 'funded').length / provApps.length) * 100)
        : 0,
      merchantFee: p.merchantFeePct,
    };
  }).filter(p => p.applications > 0);

  return (
    <div className="space-y-6">
      {/* Metric cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Approval Rate</p>
            <p className="text-2xl font-bold text-emerald-400">{approvalRate}%</p>
            <p className="text-xs text-muted mt-1">{applications.length} total applications</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Avg. Financed Job</p>
            <p className="text-2xl font-bold text-main">{formatCurrency(avgFinancedJob)}</p>
            <p className="text-xs text-muted mt-1">{funded.length} funded deals</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Total Financed Revenue</p>
            <p className="text-2xl font-bold text-main">{formatCurrency(totalFundedRevenue)}</p>
            <p className="text-xs text-muted mt-1">{funded.length} funded applications</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Connected Providers</p>
            <p className="text-2xl font-bold text-purple-400">{providers.filter(p => p.connected).length}</p>
            <p className="text-xs text-muted mt-1">{providers.length} total configured</p>
          </CardContent>
        </Card>
      </div>

      {/* Provider comparison table */}
      <Card>
        <CardHeader>
          <CardTitle>Provider Comparison</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {providerStats.length === 0 ? (
            <div className="py-12 text-center">
              <Building2 className="w-10 h-10 text-muted mx-auto mb-3" />
              <p className="text-main font-medium mb-1">No provider data yet</p>
              <p className="text-sm text-muted">Analytics will appear once financing applications are created</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-main">
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Provider</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Applications</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Funded</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Approval Rate</th>
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Merchant Fee</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {providerStats.map((ps) => (
                    <tr key={ps.name} className="hover:bg-surface-hover transition-colors">
                      <td className="px-6 py-3.5 font-medium text-main">{ps.name}</td>
                      <td className="px-6 py-3.5 text-muted">{ps.applications}</td>
                      <td className="px-6 py-3.5 text-emerald-400 font-medium">{formatCurrency(ps.funded)}</td>
                      <td className="px-6 py-3.5">
                        <div className="flex items-center gap-2">
                          <div className="w-16 h-1.5 bg-surface rounded-full overflow-hidden border border-main">
                            <div className="h-full bg-emerald-500 rounded-full" style={{ width: `${ps.approvalRate}%` }} />
                          </div>
                          <span className="text-main">{fmtPct(ps.approvalRate)}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3.5 text-amber-400">{fmtPct(ps.merchantFee)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Info card */}
      <Card>
        <CardContent className="py-4">
          <div className="flex items-start gap-3">
            <TrendingUp className="w-5 h-5 text-[var(--accent)] mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-main">Financing Impact</p>
              <p className="text-sm text-muted mt-1">
                Analytics are calculated from your actual financing data. As you process more applications,
                this section will show approval rates, close rate comparisons, job size impact, and provider performance.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
