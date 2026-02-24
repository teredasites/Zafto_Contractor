'use client';

import { useState, useMemo, useEffect } from 'react';
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

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
type Tab = 'applications' | 'providers' | 'calculator' | 'analytics';

type ApplicationStatus = 'offered' | 'applied' | 'approved' | 'denied' | 'funded';

interface FinancingApplication {
  id: string;
  customerName: string;
  jobName: string;
  amount: number;
  monthlyPayment: number;
  term: number;
  rate: number;
  provider: string;
  status: ApplicationStatus;
  dateApplied: string;
  dateUpdated: string;
}

interface FinancingProvider {
  id: string;
  name: string;
  logo: string;
  connected: boolean;
  apiKeyConfigured: boolean;
  approvalRate: number;
  avgFundingDays: number;
  merchantFee: number;
  minAmount: number;
  maxAmount: number;
  terms: number[];
  applicationsCount: number;
  fundedAmount: number;
}

// ---------------------------------------------------------------------------
// Status config
// ---------------------------------------------------------------------------
const statusConfig: Record<ApplicationStatus, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  offered:  { label: 'Offered',  variant: 'secondary' },
  applied:  { label: 'Applied',  variant: 'info' },
  approved: { label: 'Approved', variant: 'success' },
  denied:   { label: 'Denied',   variant: 'error' },
  funded:   { label: 'Funded',   variant: 'purple' },
};

// ---------------------------------------------------------------------------
// Demo data — Applications
// ---------------------------------------------------------------------------
const DEMO_APPLICATIONS: FinancingApplication[] = [
  { id: 'fa-001', customerName: 'Marcus Johnson', jobName: 'Full HVAC Replacement', amount: 12500, monthlyPayment: 267.50, term: 60, rate: 7.99, provider: 'Wisetack', status: 'funded', dateApplied: '2026-02-10', dateUpdated: '2026-02-14' },
  { id: 'fa-002', customerName: 'Sarah Chen', jobName: 'Kitchen Remodel', amount: 28000, monthlyPayment: 822.67, term: 36, rate: 5.99, provider: 'GreenSky', status: 'approved', dateApplied: '2026-02-18', dateUpdated: '2026-02-20' },
  { id: 'fa-003', customerName: 'David Williams', jobName: 'Roof Replacement', amount: 18750, monthlyPayment: 401.56, term: 60, rate: 7.99, provider: 'Wisetack', status: 'applied', dateApplied: '2026-02-21', dateUpdated: '2026-02-21' },
  { id: 'fa-004', customerName: 'Angela Martinez', jobName: 'Bathroom Renovation', amount: 15200, monthlyPayment: 447.06, term: 36, rate: 5.99, provider: 'Hearth', status: 'offered', dateApplied: '2026-02-22', dateUpdated: '2026-02-22' },
  { id: 'fa-005', customerName: 'Robert Taylor', jobName: 'Electrical Panel Upgrade', amount: 4800, monthlyPayment: 211.20, term: 24, rate: 6.99, provider: 'Wisetack', status: 'denied', dateApplied: '2026-02-15', dateUpdated: '2026-02-17' },
  { id: 'fa-006', customerName: 'Lisa Park', jobName: 'Whole-Home Plumbing', amount: 22000, monthlyPayment: 470.80, term: 60, rate: 7.99, provider: 'GreenSky', status: 'funded', dateApplied: '2026-01-28', dateUpdated: '2026-02-05' },
  { id: 'fa-007', customerName: 'James Cooper', jobName: 'Window Replacement (12)', amount: 9600, monthlyPayment: 422.40, term: 24, rate: 6.99, provider: 'Hearth', status: 'funded', dateApplied: '2026-01-15', dateUpdated: '2026-01-22' },
  { id: 'fa-008', customerName: 'Maria Gonzalez', jobName: 'Siding + Gutters', amount: 16800, monthlyPayment: 493.92, term: 36, rate: 5.99, provider: 'Wisetack', status: 'approved', dateApplied: '2026-02-19', dateUpdated: '2026-02-21' },
];

// ---------------------------------------------------------------------------
// Demo data — Providers
// ---------------------------------------------------------------------------
const DEMO_PROVIDERS: FinancingProvider[] = [
  {
    id: 'prov-1', name: 'Wisetack', logo: 'W', connected: true, apiKeyConfigured: true,
    approvalRate: 73, avgFundingDays: 3, merchantFee: 3.9, minAmount: 500, maxAmount: 50000,
    terms: [12, 24, 36, 48, 60], applicationsCount: 42, fundedAmount: 312500,
  },
  {
    id: 'prov-2', name: 'GreenSky', logo: 'G', connected: true, apiKeyConfigured: true,
    approvalRate: 68, avgFundingDays: 5, merchantFee: 5.2, minAmount: 1000, maxAmount: 75000,
    terms: [12, 24, 36, 60], applicationsCount: 28, fundedAmount: 245000,
  },
  {
    id: 'prov-3', name: 'Hearth', logo: 'H', connected: false, apiKeyConfigured: false,
    approvalRate: 0, avgFundingDays: 0, merchantFee: 4.5, minAmount: 1000, maxAmount: 100000,
    terms: [12, 24, 36, 48, 60, 84], applicationsCount: 0, fundedAmount: 0,
  },
];

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
function fmtCurrency(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(n);
}

function fmtCurrencyCents(n: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function fmtPct(n: number): string {
  return `${n.toFixed(1)}%`;
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
  const [activeTab, setActiveTab] = useState<Tab>('applications');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Simulate loading
  useEffect(() => {
    const t = setTimeout(() => setLoading(false), 600);
    return () => clearTimeout(t);
  }, []);

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
          <h1 className="text-xl font-bold text-main">Customer Financing</h1>
          <p className="text-sm text-muted mt-1">Offer financing options to close more deals</p>
        </div>
        <Card>
          <CardContent className="py-16 text-center">
            <AlertCircle className="w-10 h-10 text-red-400 mx-auto mb-3" />
            <p className="text-main font-medium mb-1">Failed to load financing data</p>
            <p className="text-sm text-muted mb-4">{error}</p>
            <Button variant="outline" onClick={() => { setError(null); setLoading(true); setTimeout(() => setLoading(false), 600); }}>
              <RefreshCcw className="w-4 h-4" />
              Retry
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
            Customer Financing
          </h1>
          <p className="text-sm text-muted mt-1">Offer financing options to close more deals and increase average job size</p>
        </div>
        <Button onClick={() => setActiveTab('calculator')}>
          <Plus className="w-4 h-4" />
          Offer Financing
        </Button>
      </div>

      {/* Summary cards */}
      <SummaryCards applications={DEMO_APPLICATIONS} />

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
      {activeTab === 'applications' && <ApplicationsTab applications={DEMO_APPLICATIONS} />}
      {activeTab === 'providers' && <ProvidersTab providers={DEMO_PROVIDERS} />}
      {activeTab === 'calculator' && <CalculatorTab />}
      {activeTab === 'analytics' && <AnalyticsTab applications={DEMO_APPLICATIONS} providers={DEMO_PROVIDERS} />}
    </div>
  );
}

// ---------------------------------------------------------------------------
// Summary Cards
// ---------------------------------------------------------------------------
function SummaryCards({ applications }: { applications: FinancingApplication[] }) {
  const totalFinanced = applications.filter(a => a.status === 'funded').reduce((s, a) => s + a.amount, 0);
  const activeCount = applications.filter(a => a.status === 'applied' || a.status === 'approved').length;
  const fundedCount = applications.filter(a => a.status === 'funded').length;
  const avgAmount = applications.length > 0 ? applications.reduce((s, a) => s + a.amount, 0) / applications.length : 0;

  const cards = [
    { label: 'Total Funded', value: fmtCurrency(totalFinanced), icon: Banknote, accent: 'text-emerald-400' },
    { label: 'Active Applications', value: String(activeCount), icon: Clock, accent: 'text-blue-400' },
    { label: 'Funded This Month', value: String(fundedCount), icon: CheckCircle, accent: 'text-purple-400' },
    { label: 'Avg. Financed Amount', value: fmtCurrency(avgAmount), icon: DollarSign, accent: 'text-amber-400' },
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
        a.jobName.toLowerCase().includes(search.toLowerCase()) ||
        a.provider.toLowerCase().includes(search.toLowerCase());
      const matchStatus = statusFilter === 'all' || a.status === statusFilter;
      return matchSearch && matchStatus;
    });
  }, [applications, search, statusFilter]);

  // Status pipeline counts
  const pipelineCounts: Record<ApplicationStatus, number> = {
    offered: applications.filter(a => a.status === 'offered').length,
    applied: applications.filter(a => a.status === 'applied').length,
    approved: applications.filter(a => a.status === 'approved').length,
    denied: applications.filter(a => a.status === 'denied').length,
    funded: applications.filter(a => a.status === 'funded').length,
  };

  return (
    <div className="space-y-6">
      {/* Pipeline */}
      <div className="grid grid-cols-5 gap-3">
        {(Object.keys(statusConfig) as ApplicationStatus[]).map((s) => {
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
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Applied</th>
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
                      <td className="px-6 py-3.5 text-muted">{app.jobName}</td>
                      <td className="px-6 py-3.5 font-medium text-main">{fmtCurrency(app.amount)}</td>
                      <td className="px-6 py-3.5 text-muted">{fmtCurrencyCents(app.monthlyPayment)}/mo</td>
                      <td className="px-6 py-3.5 text-muted">{app.term} mo @ {fmtPct(app.rate)}</td>
                      <td className="px-6 py-3.5 text-muted">{app.provider}</td>
                      <td className="px-6 py-3.5">
                        <Badge variant={cfg.variant} dot>{cfg.label}</Badge>
                      </td>
                      <td className="px-6 py-3.5 text-muted">{fmtDate(app.dateApplied)}</td>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {providers.map((p) => (
          <Card key={p.id}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-[var(--accent)]/10 flex items-center justify-center text-[var(--accent)] font-bold text-lg">
                    {p.logo}
                  </div>
                  <div>
                    <CardTitle>{p.name}</CardTitle>
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
                    <span className="text-main font-medium">{fmtPct(p.merchantFee)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="flex items-center gap-2 text-muted">
                      <DollarSign className="w-3.5 h-3.5" />
                      Range
                    </span>
                    <span className="text-main font-medium">{fmtCurrency(p.minAmount)} - {fmtCurrency(p.maxAmount)}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="flex items-center gap-2 text-muted">
                      <Calendar className="w-3.5 h-3.5" />
                      Terms
                    </span>
                    <span className="text-main font-medium">{p.terms.map(t => `${t}mo`).join(', ')}</span>
                  </div>
                </div>

                {/* Stats (only for connected providers) */}
                {p.connected && (
                  <div className="pt-3 border-t border-main space-y-2">
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted">Approval Rate</span>
                      <span className="text-main font-medium">{fmtPct(p.approvalRate)}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted">Avg. Funding Speed</span>
                      <span className="text-main font-medium">{p.avgFundingDays} days</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted">Applications</span>
                      <span className="text-main font-medium">{p.applicationsCount}</span>
                    </div>
                    <div className="flex items-center justify-between text-sm">
                      <span className="text-muted">Total Funded</span>
                      <span className="text-emerald-400 font-medium">{fmtCurrency(p.fundedAmount)}</span>
                    </div>
                  </div>
                )}

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
                      Connect {p.name}
                    </Button>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
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
                  Financing {fmtCurrency(amount)} at {fmtPct(rate)} APR
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
                      <p className="text-2xl font-bold text-main">{fmtCurrencyCents(opt.monthly)}</p>
                      <p className="text-xs text-muted mt-1">per month</p>
                      <div className="mt-3 pt-3 border-t border-main space-y-1">
                        <div className="flex justify-between text-xs">
                          <span className="text-muted">Total Cost</span>
                          <span className="text-main">{fmtCurrency(Math.round(opt.totalCost))}</span>
                        </div>
                        <div className="flex justify-between text-xs">
                          <span className="text-muted">Total Interest</span>
                          <span className="text-amber-400">{fmtCurrency(Math.round(opt.totalInterest))}</span>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>

                {selectedTerm !== null && (
                  <div className="flex items-center justify-between p-4 rounded-xl border border-[var(--accent)]/30 bg-[var(--accent)]/5">
                    <div>
                      <p className="text-sm font-medium text-main">
                        {selectedTerm}-month plan selected: {fmtCurrencyCents(calcMonthly(amount, rate, selectedTerm))}/mo
                      </p>
                      <p className="text-xs text-muted mt-0.5">
                        Customer pays {fmtCurrency(Math.round(calcMonthly(amount, rate, selectedTerm) * selectedTerm))} total
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
                makes monthly payments directly to the financing provider. Average close rates increase by 17-22%
                when financing is offered.
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
  // Derived analytics from demo data
  const funded = applications.filter(a => a.status === 'funded');
  const totalFundedRevenue = funded.reduce((s, a) => s + a.amount, 0);
  const avgFinancedJob = funded.length > 0 ? totalFundedRevenue / funded.length : 0;
  const avgNonFinancedJob = 6200; // demo comparison baseline
  const closeRateWithFinancing = 68;
  const closeRateWithout = 42;
  const jobsSavedByFinancing = 14;
  const revenueFromSavedJobs = 187400;

  const providerStats = providers.filter(p => p.connected).map(p => ({
    name: p.name,
    applications: p.applicationsCount,
    funded: p.fundedAmount,
    approvalRate: p.approvalRate,
    merchantFee: p.merchantFee,
    avgFunding: p.avgFundingDays,
  }));

  return (
    <div className="space-y-6">
      {/* Impact banner */}
      <Card>
        <CardContent className="py-5">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center shrink-0">
              <TrendingUp className="w-6 h-6 text-emerald-400" />
            </div>
            <div>
              <p className="text-base font-semibold text-main">
                Financing increased your average job size by 34%
              </p>
              <p className="text-sm text-muted mt-0.5">
                {fmtCurrency(revenueFromSavedJobs)} in revenue from {jobsSavedByFinancing} jobs that would have been lost without financing options.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Metric cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Close Rate With Financing</p>
            <div className="flex items-end gap-2">
              <p className="text-2xl font-bold text-emerald-400">{closeRateWithFinancing}%</p>
              <div className="flex items-center gap-0.5 text-xs text-emerald-400 mb-1">
                <ArrowUpRight className="w-3 h-3" />
                +{closeRateWithFinancing - closeRateWithout}%
              </div>
            </div>
            <p className="text-xs text-muted mt-1">vs {closeRateWithout}% without</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Avg. Financed Job</p>
            <div className="flex items-end gap-2">
              <p className="text-2xl font-bold text-main">{fmtCurrency(avgFinancedJob)}</p>
              <div className="flex items-center gap-0.5 text-xs text-emerald-400 mb-1">
                <ArrowUpRight className="w-3 h-3" />
                +{fmtPct(((avgFinancedJob - avgNonFinancedJob) / avgNonFinancedJob) * 100)}
              </div>
            </div>
            <p className="text-xs text-muted mt-1">vs {fmtCurrency(avgNonFinancedJob)} without</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Total Financed Revenue</p>
            <p className="text-2xl font-bold text-main">{fmtCurrency(totalFundedRevenue)}</p>
            <p className="text-xs text-muted mt-1">{funded.length} funded applications</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="py-4">
            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">Jobs Saved</p>
            <div className="flex items-end gap-2">
              <p className="text-2xl font-bold text-purple-400">{jobsSavedByFinancing}</p>
            </div>
            <p className="text-xs text-muted mt-1">{fmtCurrency(revenueFromSavedJobs)} recovered revenue</p>
          </CardContent>
        </Card>
      </div>

      {/* Close rate visual comparison */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Close Rate Comparison</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-5">
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-main font-medium">With Financing</span>
                  <span className="text-emerald-400 font-bold">{closeRateWithFinancing}%</span>
                </div>
                <div className="h-4 bg-surface rounded-full overflow-hidden border border-main">
                  <div
                    className="h-full bg-emerald-500 rounded-full transition-all duration-700"
                    style={{ width: `${closeRateWithFinancing}%` }}
                  />
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-main font-medium">Without Financing</span>
                  <span className="text-muted font-bold">{closeRateWithout}%</span>
                </div>
                <div className="h-4 bg-surface rounded-full overflow-hidden border border-main">
                  <div
                    className="h-full bg-muted rounded-full transition-all duration-700"
                    style={{ width: `${closeRateWithout}%` }}
                  />
                </div>
              </div>
              <div className="pt-3 border-t border-main">
                <p className="text-sm text-muted">
                  Offering financing increases your estimate-to-job conversion rate by{' '}
                  <span className="text-emerald-400 font-medium">{closeRateWithFinancing - closeRateWithout} percentage points</span>.
                  Customers are more likely to approve estimates when monthly payment options are presented.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Average Job Size</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-5">
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-main font-medium">Financed Jobs</span>
                  <span className="text-[var(--accent)] font-bold">{fmtCurrency(avgFinancedJob)}</span>
                </div>
                <div className="h-4 bg-surface rounded-full overflow-hidden border border-main">
                  <div
                    className="h-full bg-[var(--accent)] rounded-full transition-all duration-700"
                    style={{ width: '100%' }}
                  />
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-main font-medium">Non-Financed Jobs</span>
                  <span className="text-muted font-bold">{fmtCurrency(avgNonFinancedJob)}</span>
                </div>
                <div className="h-4 bg-surface rounded-full overflow-hidden border border-main">
                  <div
                    className="h-full bg-muted rounded-full transition-all duration-700"
                    style={{ width: `${(avgNonFinancedJob / avgFinancedJob) * 100}%` }}
                  />
                </div>
              </div>
              <div className="pt-3 border-t border-main">
                <p className="text-sm text-muted">
                  Customers with financing commit to{' '}
                  <span className="text-[var(--accent)] font-medium">{fmtPct(((avgFinancedJob - avgNonFinancedJob) / avgNonFinancedJob) * 100)} larger</span>{' '}
                  jobs on average. Financing removes the lump-sum barrier, enabling customers to choose comprehensive solutions over budget patches.
                </p>
              </div>
            </div>
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
              <p className="text-main font-medium mb-1">No providers connected</p>
              <p className="text-sm text-muted">Connect a financing provider to see comparison analytics</p>
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
                    <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Avg. Funding</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-main">
                  {providerStats.map((ps) => (
                    <tr key={ps.name} className="hover:bg-surface-hover transition-colors">
                      <td className="px-6 py-3.5 font-medium text-main">{ps.name}</td>
                      <td className="px-6 py-3.5 text-muted">{ps.applications}</td>
                      <td className="px-6 py-3.5 text-emerald-400 font-medium">{fmtCurrency(ps.funded)}</td>
                      <td className="px-6 py-3.5">
                        <div className="flex items-center gap-2">
                          <div className="w-16 h-1.5 bg-surface rounded-full overflow-hidden border border-main">
                            <div className="h-full bg-emerald-500 rounded-full" style={{ width: `${ps.approvalRate}%` }} />
                          </div>
                          <span className="text-main">{fmtPct(ps.approvalRate)}</span>
                        </div>
                      </td>
                      <td className="px-6 py-3.5 text-amber-400">{fmtPct(ps.merchantFee)}</td>
                      <td className="px-6 py-3.5 text-muted">{ps.avgFunding} days</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Monthly trend (simplified visual) */}
      <Card>
        <CardHeader>
          <CardTitle>Monthly Financing Volume</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {[
              { month: 'Sep 2025', amount: 18200, apps: 3 },
              { month: 'Oct 2025', amount: 31500, apps: 5 },
              { month: 'Nov 2025', amount: 24800, apps: 4 },
              { month: 'Dec 2025', amount: 42100, apps: 7 },
              { month: 'Jan 2026', amount: 54600, apps: 8 },
              { month: 'Feb 2026', amount: 44100, apps: 6 },
            ].map((m) => {
              const maxAmount = 54600;
              const pct = (m.amount / maxAmount) * 100;
              return (
                <div key={m.month} className="flex items-center gap-4">
                  <span className="text-xs text-muted w-20 shrink-0">{m.month}</span>
                  <div className="flex-1 h-6 bg-surface rounded overflow-hidden border border-main">
                    <div
                      className="h-full bg-[var(--accent)]/70 rounded transition-all duration-500 flex items-center justify-end pr-2"
                      style={{ width: `${pct}%` }}
                    >
                      {pct > 25 && (
                        <span className="text-[10px] font-medium text-white">{fmtCurrency(m.amount)}</span>
                      )}
                    </div>
                  </div>
                  {pct <= 25 && (
                    <span className="text-xs text-muted">{fmtCurrency(m.amount)}</span>
                  )}
                  <span className="text-xs text-muted w-14 text-right shrink-0">{m.apps} apps</span>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
