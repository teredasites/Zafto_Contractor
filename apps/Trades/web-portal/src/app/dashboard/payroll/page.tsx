'use client';

import { useState, useCallback, useMemo } from 'react';
import {
  Plus,
  DollarSign,
  Users,
  Calendar,
  FileText,
  ChevronDown,
  ChevronRight,
  CheckCircle,
  Clock,
  AlertTriangle,
  Banknote,
  Calculator,
  HardHat,
  Download,
  Printer,
  TrendingUp,
  Building,
  Briefcase,
  BarChart3,
  Shield,
  CircleDollarSign,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { StatsCard } from '@/components/ui/stats-card';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  usePayroll,
  type PayPeriod,
  type PayStub,
  type PeriodStatus,
} from '@/lib/hooks/use-payroll';
import { useTranslation } from '@/lib/translations';

// ────────────────────────────────────────────────────────
// Types & Config
// ────────────────────────────────────────────────────────

type PayrollTab = 'periods' | 'calculator' | 'labor' | 'certified';

const TABS: { key: PayrollTab; label: string; icon: typeof Calendar }[] = [
  { key: 'periods', label: 'Pay Periods', icon: Calendar },
  { key: 'calculator', label: 'Payroll Calculator', icon: Calculator },
  { key: 'labor', label: 'Labor Distribution', icon: BarChart3 },
  { key: 'certified', label: 'Certified Payroll', icon: Shield },
];

const periodStatusConfig: Record<PeriodStatus, { label: string; variant: 'secondary' | 'info' | 'warning' | 'success' | 'error' }> = {
  draft: { label: 'Draft', variant: 'secondary' },
  processing: { label: 'Processing', variant: 'info' },
  approved: { label: 'Approved', variant: 'warning' },
  paid: { label: 'Paid', variant: 'success' },
  voided: { label: 'Voided', variant: 'error' },
};

const periodTypeLabels: Record<string, string> = {
  weekly: 'Weekly',
  biweekly: 'Bi-Weekly',
  semimonthly: 'Semi-Monthly',
  monthly: 'Monthly',
};

// ── Demo data for depth features ──

interface LaborAllocation {
  jobId: string;
  jobName: string;
  customerName: string;
  totalHours: number;
  regularHours: number;
  overtimeHours: number;
  laborCost: number;
  employeeCount: number;
  costPerHour: number;
  percentOfTotal: number;
}

interface CertifiedPayrollEntry {
  employeeName: string;
  ssn: string;
  classification: string;
  totalHours: number;
  regularHours: number;
  overtimeHours: number;
  rate: number;
  otRate: number;
  grossPay: number;
  deductions: number;
  netPay: number;
  fringes: number;
}

interface CertifiedProject {
  id: string;
  projectName: string;
  contractNumber: string;
  contractor: string;
  prevailingWageArea: string;
  weekEnding: string;
  entries: CertifiedPayrollEntry[];
}


// ────────────────────────────────────────────────────────
// Page
// ────────────────────────────────────────────────────────

export default function PayrollPage() {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<PayrollTab>('periods');
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedPeriod, setExpandedPeriod] = useState<string | null>(null);
  const [periodStubs, setPeriodStubs] = useState<Record<string, PayStub[]>>({});
  const [loadingStubs, setLoadingStubs] = useState<Record<string, boolean>>({});

  const {
    payPeriods,
    loading,
    currentPeriod,
    totalPayroll,
    pendingApproval,
    getStubsForPeriod,
    updatePayPeriodStatus,
  } = usePayroll();

  // ── Load stubs on expand ──
  const handleTogglePeriod = useCallback(async (periodId: string) => {
    if (expandedPeriod === periodId) {
      setExpandedPeriod(null);
      return;
    }
    setExpandedPeriod(periodId);
    if (!periodStubs[periodId]) {
      try {
        setLoadingStubs((prev) => ({ ...prev, [periodId]: true }));
        const stubs = await getStubsForPeriod(periodId);
        setPeriodStubs((prev) => ({ ...prev, [periodId]: stubs }));
      } catch {
        // silent
      } finally {
        setLoadingStubs((prev) => ({ ...prev, [periodId]: false }));
      }
    }
  }, [expandedPeriod, periodStubs, getStubsForPeriod]);

  const handleStatusUpdate = useCallback(async (id: string, status: PeriodStatus) => {
    try {
      await updatePayPeriodStatus(id, status);
    } catch {
      // silent
    }
  }, [updatePayPeriodStatus]);

  const filteredPeriods = payPeriods.filter((p) =>
    statusFilter === 'all' || p.status === statusFilter
  );

  const totalEmployees = currentPeriod?.employeeCount || 0;
  const currentNet = currentPeriod?.totalNet || 0;

  // ── Totals for labor (derived from time entries when available) ──
  const laborAllocations: LaborAllocation[] = [];
  const totalLaborHours = laborAllocations.reduce((s, a) => s + a.totalHours, 0);
  const totalLaborCost = laborAllocations.reduce((s, a) => s + a.laborCost, 0);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-32 mb-2" /><div className="skeleton h-4 w-48" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" />
            </div>
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
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('payroll.title')}</h1>
          <p className="text-muted mt-1">Manage pay periods, calculate payroll, labor distribution, and certified payroll</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary"><Download size={16} />Export</Button>
          <Button><Plus size={16} />{t('payroll.newPayPeriod')}</Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatsCard
          title={t('payroll.currentPeriod')}
          value={currentPeriod
            ? `${formatDate(currentPeriod.startDate).split(',')[0]} – ${formatDate(currentPeriod.endDate).split(',')[0]}`
            : 'None'}
          icon={<Calendar size={20} />}
        />
        <StatsCard title={t('payroll.totalGross')} value={formatCurrency(totalPayroll)} icon={<DollarSign size={20} />} />
        <StatsCard title={t('payroll.totalNet')} value={formatCurrency(currentNet)} icon={<Banknote size={20} />} />
        <StatsCard title={t('common.employees')} value={String(totalEmployees)} icon={<Users size={20} />} />
        <StatsCard
          title="Pending Approval"
          value={String(pendingApproval)}
          icon={<AlertTriangle size={20} />}
          className={pendingApproval > 0 ? 'border-amber-200 dark:border-amber-800/40' : ''}
        />
      </div>

      {/* Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium whitespace-nowrap transition-colors',
                activeTab === tab.key
                  ? 'bg-accent text-white'
                  : 'bg-secondary text-muted hover:text-main hover:bg-surface-hover'
              )}
            >
              <Icon size={16} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      {activeTab === 'periods' && (
        <PayPeriodsTab
          periods={filteredPeriods}
          statusFilter={statusFilter}
          onStatusFilter={setStatusFilter}
          expandedPeriod={expandedPeriod}
          periodStubs={periodStubs}
          loadingStubs={loadingStubs}
          onTogglePeriod={handleTogglePeriod}
          onStatusUpdate={handleStatusUpdate}
        />
      )}
      {activeTab === 'calculator' && <PayrollCalculatorTab />}
      {activeTab === 'labor' && (
        <LaborDistributionTab
          allocations={laborAllocations}
          totalHours={totalLaborHours}
          totalCost={totalLaborCost}
        />
      )}
      {activeTab === 'certified' && <CertifiedPayrollTab project={null} />}
    </div>
  );
}

// ════════════════════════════════════════════════════════
// TAB 1: Pay Periods
// ════════════════════════════════════════════════════════

function PayPeriodsTab({
  periods,
  statusFilter,
  onStatusFilter,
  expandedPeriod,
  periodStubs,
  loadingStubs,
  onTogglePeriod,
  onStatusUpdate,
}: {
  periods: PayPeriod[];
  statusFilter: string;
  onStatusFilter: (v: string) => void;
  expandedPeriod: string | null;
  periodStubs: Record<string, PayStub[]>;
  loadingStubs: Record<string, boolean>;
  onTogglePeriod: (id: string) => void;
  onStatusUpdate: (id: string, status: PeriodStatus) => void;
}) {
  const { t } = useTranslation();

  return (
    <div className="space-y-6">
      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'draft', label: 'Draft' },
            { value: 'processing', label: 'Processing' },
            { value: 'approved', label: 'Approved' },
            { value: 'paid', label: 'Paid' },
            { value: 'voided', label: 'Voided' },
          ]}
          value={statusFilter}
          onChange={(e) => onStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Pay Periods Table */}
      <Card>
        <CardContent className="p-0">
          {periods.length === 0 ? (
            <div className="py-12 text-center text-muted">
              <FileText size={40} className="mx-auto mb-2 opacity-50" />
              <p>{t('payroll.noRecords')}</p>
            </div>
          ) : (
            <div className="divide-y divide-main">
              {/* Table Header */}
              <div className="px-6 py-3 bg-secondary/50 grid grid-cols-12 gap-4 text-xs font-medium text-muted uppercase tracking-wider">
                <div className="col-span-1" />
                <div className="col-span-2">{t('payroll.dateRange')}</div>
                <div className="col-span-1">{t('common.type')}</div>
                <div className="col-span-1">{t('common.status')}</div>
                <div className="col-span-1">{t('common.employees')}</div>
                <div className="col-span-2">{t('common.grossPay')}</div>
                <div className="col-span-1">{t('common.taxes')}</div>
                <div className="col-span-2">{t('common.netPay')}</div>
                <div className="col-span-1">{t('common.actions')}</div>
              </div>

              {periods.map((period) => {
                const isExpanded = expandedPeriod === period.id;
                const stubs = periodStubs[period.id] || [];
                const isLoadingStubs = loadingStubs[period.id] || false;

                return (
                  <div key={period.id}>
                    <PayPeriodRow
                      period={period}
                      isExpanded={isExpanded}
                      onToggle={() => onTogglePeriod(period.id)}
                      onApprove={() => onStatusUpdate(period.id, 'approved')}
                      onProcess={() => onStatusUpdate(period.id, 'processing')}
                    />
                    {isExpanded && (
                      <PayPeriodDetail stubs={stubs} loading={isLoadingStubs} />
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Pay Period Row
// ────────────────────────────────────────────────────────

function PayPeriodRow({
  period,
  isExpanded,
  onToggle,
  onApprove,
  onProcess,
}: {
  period: PayPeriod;
  isExpanded: boolean;
  onToggle: () => void;
  onApprove: () => void;
  onProcess: () => void;
}) {
  const statusCfg = periodStatusConfig[period.status];

  return (
    <div
      className={cn(
        'px-6 py-4 grid grid-cols-12 gap-4 items-center cursor-pointer hover:bg-surface-hover transition-colors',
        isExpanded && 'bg-surface-hover'
      )}
      onClick={onToggle}
    >
      <div className="col-span-1 flex items-center">
        {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
      </div>
      <div className="col-span-2">
        <p className="text-sm font-medium text-main">
          {formatDate(period.startDate)} - {formatDate(period.endDate)}
        </p>
        <p className="text-xs text-muted mt-0.5 flex items-center gap-1">
          <Clock size={10} />Pay date: {formatDate(period.payDate)}
        </p>
      </div>
      <div className="col-span-1">
        <span className="text-sm text-muted">{periodTypeLabels[period.periodType] || period.periodType}</span>
      </div>
      <div className="col-span-1">
        <Badge variant={statusCfg.variant} dot>{statusCfg.label}</Badge>
      </div>
      <div className="col-span-1">
        <div className="flex items-center gap-1">
          <Users size={14} className="text-muted" />
          <span className="text-sm text-main">{period.employeeCount}</span>
        </div>
      </div>
      <div className="col-span-2">
        <p className="text-sm font-semibold text-main">{formatCurrency(period.totalGross)}</p>
      </div>
      <div className="col-span-1">
        <p className="text-sm text-muted">{formatCurrency(period.totalTaxes)}</p>
      </div>
      <div className="col-span-2">
        <p className="text-sm font-semibold text-emerald-600 dark:text-emerald-400">{formatCurrency(period.totalNet)}</p>
      </div>
      <div className="col-span-1" onClick={(e) => e.stopPropagation()}>
        {period.status === 'draft' && (
          <Button variant="outline" size="sm" onClick={onProcess}>Process</Button>
        )}
        {period.status === 'processing' && (
          <Button variant="primary" size="sm" onClick={onApprove}>
            <CheckCircle size={14} />Approve
          </Button>
        )}
        {period.status === 'paid' && (
          <Button variant="ghost" size="sm"><Printer size={14} /></Button>
        )}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Expanded Detail — Pay Stubs
// ────────────────────────────────────────────────────────

function PayPeriodDetail({ stubs, loading }: { stubs: PayStub[]; loading: boolean }) {
  const { t } = useTranslation();

  if (loading) {
    return (
      <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
        <div className="space-y-2">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="p-3 bg-surface border border-main rounded-lg">
              <div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-64" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // ── YTD Totals ──
  const ytdGross = stubs.reduce((s, st) => s + st.ytdGross, 0);
  const ytdNet = stubs.reduce((s, st) => s + st.ytdNet, 0);

  return (
    <div className="px-6 pb-6 pt-2 bg-secondary/30 border-t border-main">
      <div className="flex items-center justify-between mb-3">
        <h4 className="text-sm font-medium text-main flex items-center gap-2">
          <FileText size={14} />Pay Stubs ({stubs.length})
        </h4>
        {stubs.length > 0 && (
          <div className="flex items-center gap-4 text-xs text-muted">
            <span>YTD Gross: <span className="font-semibold text-main">{formatCurrency(ytdGross)}</span></span>
            <span>YTD Net: <span className="font-semibold text-emerald-600">{formatCurrency(ytdNet)}</span></span>
          </div>
        )}
      </div>

      {stubs.length === 0 ? (
        <p className="text-sm text-muted py-2">{t('payroll.noPayStubsForThisPeriod')}</p>
      ) : (
        <div className="space-y-2">
          <div className="grid grid-cols-12 gap-3 px-3 py-2 text-xs font-medium text-muted uppercase tracking-wider">
            <div className="col-span-2">{t('common.employee')}</div>
            <div className="col-span-1">{t('payroll.regHrs')}</div>
            <div className="col-span-1">{t('payroll.otHrs')}</div>
            <div className="col-span-2">{t('common.grossPay')}</div>
            <div className="col-span-2">{t('common.taxes')}</div>
            <div className="col-span-2">{t('common.deductions')}</div>
            <div className="col-span-2">{t('common.netPay')}</div>
          </div>

          {stubs.map((stub) => {
            const totalTaxes = stub.federalTax + stub.stateTax + stub.localTax + stub.socialSecurity + stub.medicare;
            return (
              <div key={stub.id} className="grid grid-cols-12 gap-3 items-center p-3 bg-surface border border-main rounded-lg">
                <div className="col-span-2">
                  <p className="text-sm font-medium text-main truncate">{stub.userId.slice(0, 8)}...</p>
                  <p className="text-xs text-muted capitalize">{stub.paymentMethod.replace('_', ' ')}</p>
                </div>
                <div className="col-span-1"><p className="text-sm text-main">{stub.hoursRegular}h</p></div>
                <div className="col-span-1">
                  <p className={cn('text-sm', stub.hoursOvertime > 0 ? 'text-amber-600 dark:text-amber-400 font-medium' : 'text-muted')}>
                    {stub.hoursOvertime}h
                  </p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm font-semibold text-main">{formatCurrency(stub.grossPay)}</p>
                  <p className="text-[10px] text-muted">${stub.rateRegular}/hr reg · ${stub.rateOvertime}/hr OT</p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-red-600 dark:text-red-400">{formatCurrency(totalTaxes)}</p>
                  <p className="text-[10px] text-muted">
                    Fed {formatCurrency(stub.federalTax)} / St {formatCurrency(stub.stateTax)}
                  </p>
                </div>
                <div className="col-span-2">
                  <p className="text-sm text-muted">{formatCurrency(stub.totalDeductions)}</p>
                  {stub.retirement401k > 0 && <p className="text-[10px] text-muted">401k: {formatCurrency(stub.retirement401k)}</p>}
                  {stub.healthInsurance > 0 && <p className="text-[10px] text-muted">Health: {formatCurrency(stub.healthInsurance)}</p>}
                </div>
                <div className="col-span-2">
                  <p className="text-sm font-semibold text-emerald-600 dark:text-emerald-400">{formatCurrency(stub.netPay)}</p>
                  {stub.hoursPto > 0 && <p className="text-[10px] text-muted">PTO: {stub.hoursPto}h</p>}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════
// TAB 2: Payroll Calculator
// ════════════════════════════════════════════════════════

function PayrollCalculatorTab() {
  const [regHours, setRegHours] = useState(80);
  const [otHours, setOtHours] = useState(0);
  const [hourlyRate, setHourlyRate] = useState(35);
  const [filingStatus, setFilingStatus] = useState<'single' | 'married'>('single');
  const [allowances, setAllowances] = useState(1);

  // ── Tax calculations (simplified demonstration) ──
  const regPay = regHours * hourlyRate;
  const otPay = otHours * hourlyRate * 1.5;
  const grossPay = regPay + otPay;

  // Federal brackets approximation (2026 simplified)
  const annualized = grossPay * 26; // bi-weekly
  const fedRate = filingStatus === 'single'
    ? (annualized <= 11600 ? 0.10 : annualized <= 47150 ? 0.12 : annualized <= 100525 ? 0.22 : 0.24)
    : (annualized <= 23200 ? 0.10 : annualized <= 94300 ? 0.12 : annualized <= 201050 ? 0.22 : 0.24);
  const federalTax = grossPay * fedRate;
  const stateTax = grossPay * 0.05;
  const socialSecurity = grossPay * 0.062;
  const medicare = grossPay * 0.0145;
  const totalTaxes = federalTax + stateTax + socialSecurity + medicare;

  const health = 125;
  const dental = 25;
  const retirement = grossPay * 0.06;
  const totalDeductions = health + dental + retirement;

  const netPay = grossPay - totalTaxes - totalDeductions;

  const annualGross = grossPay * 26;
  const annualNet = netPay * 26;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Input */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Calculator size={18} />
              Payroll Calculator
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase mb-1 block">Regular Hours</label>
                <input
                  type="number"
                  value={regHours}
                  onChange={(e) => setRegHours(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase mb-1 block">Overtime Hours</label>
                <input
                  type="number"
                  value={otHours}
                  onChange={(e) => setOtHours(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>
            </div>
            <div>
              <label className="text-xs font-medium text-muted uppercase mb-1 block">Hourly Rate</label>
              <input
                type="number"
                value={hourlyRate}
                onChange={(e) => setHourlyRate(Number(e.target.value))}
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-xs font-medium text-muted uppercase mb-1 block">Filing Status</label>
                <select
                  value={filingStatus}
                  onChange={(e) => setFilingStatus(e.target.value as 'single' | 'married')}
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                >
                  <option value="single">Single</option>
                  <option value="married">Married Filing Jointly</option>
                </select>
              </div>
              <div>
                <label className="text-xs font-medium text-muted uppercase mb-1 block">Allowances</label>
                <input
                  type="number"
                  value={allowances}
                  onChange={(e) => setAllowances(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm focus:outline-none focus:ring-2 focus:ring-accent/50"
                />
              </div>
            </div>

            <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800/30 rounded-lg">
              <p className="text-xs text-blue-800 dark:text-blue-300">
                This calculator provides estimates. Actual payroll should be processed through your payroll provider (Gusto, ADP, etc.) for accurate tax withholdings.
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Output */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <CircleDollarSign size={18} />
              Pay Breakdown
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Earnings */}
            <div>
              <h4 className="text-xs font-medium text-muted uppercase mb-2">Earnings</h4>
              <div className="space-y-2">
                <div className="flex items-center justify-between py-1.5">
                  <span className="text-sm text-main">Regular Pay ({regHours}h x ${hourlyRate})</span>
                  <span className="text-sm font-medium text-main">{formatCurrency(regPay)}</span>
                </div>
                {otHours > 0 && (
                  <div className="flex items-center justify-between py-1.5">
                    <span className="text-sm text-main">Overtime Pay ({otHours}h x ${(hourlyRate * 1.5).toFixed(2)})</span>
                    <span className="text-sm font-medium text-amber-600">{formatCurrency(otPay)}</span>
                  </div>
                )}
                <div className="flex items-center justify-between py-2 border-t border-main font-semibold">
                  <span className="text-sm text-main">Gross Pay</span>
                  <span className="text-sm text-main">{formatCurrency(grossPay)}</span>
                </div>
              </div>
            </div>

            {/* Taxes */}
            <div>
              <h4 className="text-xs font-medium text-muted uppercase mb-2">Tax Withholdings</h4>
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Federal Income Tax ({(fedRate * 100).toFixed(0)}%)</span>
                  <span className="text-sm text-red-600">-{formatCurrency(federalTax)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">State Income Tax (5.0%)</span>
                  <span className="text-sm text-red-600">-{formatCurrency(stateTax)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Social Security (6.2%)</span>
                  <span className="text-sm text-red-600">-{formatCurrency(socialSecurity)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Medicare (1.45%)</span>
                  <span className="text-sm text-red-600">-{formatCurrency(medicare)}</span>
                </div>
                <div className="flex items-center justify-between pt-1.5 border-t border-main">
                  <span className="text-sm font-medium text-main">Total Taxes</span>
                  <span className="text-sm font-medium text-red-600">-{formatCurrency(totalTaxes)}</span>
                </div>
              </div>
            </div>

            {/* Deductions */}
            <div>
              <h4 className="text-xs font-medium text-muted uppercase mb-2">Deductions</h4>
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Health Insurance</span>
                  <span className="text-sm text-muted">-{formatCurrency(health)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">Dental Insurance</span>
                  <span className="text-sm text-muted">-{formatCurrency(dental)}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted">401(k) (6%)</span>
                  <span className="text-sm text-muted">-{formatCurrency(retirement)}</span>
                </div>
                <div className="flex items-center justify-between pt-1.5 border-t border-main">
                  <span className="text-sm font-medium text-main">Total Deductions</span>
                  <span className="text-sm font-medium text-muted">-{formatCurrency(totalDeductions)}</span>
                </div>
              </div>
            </div>

            {/* Net Pay */}
            <div className="p-4 bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-800/30 rounded-xl">
              <div className="flex items-center justify-between">
                <span className="text-base font-semibold text-main">Net Pay</span>
                <span className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">{formatCurrency(netPay)}</span>
              </div>
              <div className="flex items-center justify-between mt-2 text-xs text-muted">
                <span>Annualized Gross: {formatCurrency(annualGross)}</span>
                <span>Annualized Net: {formatCurrency(annualNet)}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Employer Costs */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Building size={18} />
            Employer Tax Obligations (per employee per period)
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Employer SS (6.2%)', value: formatCurrency(socialSecurity), color: 'text-blue-600' },
              { label: 'Employer Medicare (1.45%)', value: formatCurrency(medicare), color: 'text-blue-600' },
              { label: 'FUTA (0.6%)', value: formatCurrency(grossPay * 0.006), color: 'text-purple-600' },
              { label: 'SUTA (est 2.7%)', value: formatCurrency(grossPay * 0.027), color: 'text-purple-600' },
            ].map((item) => (
              <div key={item.label} className="p-4 bg-secondary rounded-xl">
                <p className="text-xs text-muted mb-1">{item.label}</p>
                <p className={cn('text-lg font-semibold', item.color)}>{item.value}</p>
              </div>
            ))}
          </div>
          <div className="mt-4 p-3 bg-secondary rounded-lg flex items-center justify-between">
            <span className="text-sm font-medium text-main">Total Employer Cost Per Employee</span>
            <span className="text-lg font-bold text-main">
              {formatCurrency(grossPay + socialSecurity + medicare + grossPay * 0.006 + grossPay * 0.027)}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// TAB 3: Labor Distribution
// ════════════════════════════════════════════════════════

function LaborDistributionTab({
  allocations,
  totalHours,
  totalCost,
}: {
  allocations: LaborAllocation[];
  totalHours: number;
  totalCost: number;
}) {
  const maxCost = Math.max(...allocations.map((a) => a.laborCost), 1);

  if (allocations.length === 0) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatsCard title="Total Labor Hours" value="0" icon={<Clock size={20} />} />
          <StatsCard title="Total Labor Cost" value={formatCurrency(0)} icon={<DollarSign size={20} />} />
          <StatsCard title="Avg Cost / Hour" value={formatCurrency(0)} icon={<TrendingUp size={20} />} />
          <StatsCard title="Jobs Allocated" value="0" icon={<Briefcase size={20} />} />
        </div>
        <Card>
          <CardContent className="p-12 text-center">
            <Briefcase size={32} className="mx-auto mb-3 text-muted" />
            <p className="text-main font-medium">No Labor Distribution Data</p>
            <p className="text-muted text-sm mt-1">Labor allocation by job will appear here once time entries are logged against jobs.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title="Total Labor Hours" value={totalHours.toLocaleString()} icon={<Clock size={20} />} />
        <StatsCard title="Total Labor Cost" value={formatCurrency(totalCost)} icon={<DollarSign size={20} />} />
        <StatsCard
          title="Avg Cost / Hour"
          value={formatCurrency(totalHours > 0 ? totalCost / totalHours : 0)}
          icon={<TrendingUp size={20} />}
        />
        <StatsCard
          title="Jobs Allocated"
          value={String(allocations.filter((a) => a.jobName !== 'Overhead / Shop Time').length)}
          icon={<Briefcase size={20} />}
        />
      </div>

      {/* Distribution Bar */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Labor Cost by Job</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Stacked bar */}
          <div className="h-8 rounded-full overflow-hidden flex mb-6">
            {allocations.map((a, i) => {
              const colors = ['bg-emerald-500', 'bg-blue-500', 'bg-purple-500', 'bg-amber-500', 'bg-muted'];
              return (
                <div
                  key={a.jobId}
                  className={cn('h-full transition-all', colors[i % colors.length])}
                  style={{ width: `${a.percentOfTotal}%` }}
                  title={`${a.jobName}: ${a.percentOfTotal}%`}
                />
              );
            })}
          </div>

          {/* Legend + Table */}
          <div className="space-y-3">
            {allocations.map((a, i) => {
              const colors = ['bg-emerald-500', 'bg-blue-500', 'bg-purple-500', 'bg-amber-500', 'bg-muted'];
              const widthPct = maxCost > 0 ? (a.laborCost / maxCost) * 100 : 0;
              return (
                <div key={a.jobId} className="p-4 bg-secondary rounded-xl">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-3">
                      <span className={cn('w-3 h-3 rounded-full', colors[i % colors.length])} />
                      <div>
                        <p className="text-sm font-medium text-main">{a.jobName}</p>
                        <p className="text-xs text-muted">{a.customerName}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-semibold text-main">{formatCurrency(a.laborCost)}</p>
                      <p className="text-xs text-muted">{a.percentOfTotal}% of total</p>
                    </div>
                  </div>
                  <div className="h-1.5 bg-surface rounded-full overflow-hidden mb-2">
                    <div className={cn('h-full rounded-full', colors[i % colors.length])} style={{ width: `${widthPct}%` }} />
                  </div>
                  <div className="flex items-center gap-6 text-xs text-muted">
                    <span>{a.totalHours}h total ({a.regularHours}h reg + {a.overtimeHours}h OT)</span>
                    <span>{a.employeeCount} employees</span>
                    <span>${a.costPerHour.toFixed(2)}/hr avg</span>
                  </div>
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>

      {/* Overtime Analysis */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Overtime Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-xs font-medium text-muted uppercase px-4 py-3">Job</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3">Regular</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3">Overtime</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3">OT %</th>
                  <th className="text-right text-xs font-medium text-muted uppercase px-4 py-3">OT Cost Premium</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {allocations.map((a) => {
                  const otPct = a.totalHours > 0 ? (a.overtimeHours / a.totalHours) * 100 : 0;
                  const otPremium = a.overtimeHours * (a.costPerHour * 0.5); // 0.5x premium portion
                  return (
                    <tr key={a.jobId} className="hover:bg-surface-hover">
                      <td className="px-4 py-3 text-sm font-medium text-main">{a.jobName}</td>
                      <td className="px-4 py-3 text-sm text-right text-main">{a.regularHours}h</td>
                      <td className="px-4 py-3 text-sm text-right">
                        <span className={cn(a.overtimeHours > 0 ? 'text-amber-600 font-medium' : 'text-muted')}>
                          {a.overtimeHours}h
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Badge variant={otPct > 15 ? 'error' : otPct > 5 ? 'warning' : 'success'}>
                          {otPct.toFixed(1)}%
                        </Badge>
                      </td>
                      <td className="px-4 py-3 text-sm text-right text-red-600">
                        {otPremium > 0 ? `+${formatCurrency(otPremium)}` : '—'}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-secondary/50">
                  <td className="px-4 py-3 text-sm font-semibold text-main">Total</td>
                  <td className="px-4 py-3 text-sm text-right font-semibold text-main">
                    {allocations.reduce((s, a) => s + a.regularHours, 0)}h
                  </td>
                  <td className="px-4 py-3 text-sm text-right font-semibold text-amber-600">
                    {allocations.reduce((s, a) => s + a.overtimeHours, 0)}h
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Badge variant="info">
                      {((allocations.reduce((s, a) => s + a.overtimeHours, 0) / totalHours) * 100).toFixed(1)}%
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-sm text-right font-semibold text-red-600">
                    +{formatCurrency(allocations.reduce((s, a) => s + a.overtimeHours * (a.costPerHour * 0.5), 0))}
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════
// TAB 4: Certified Payroll (WH-347)
// ════════════════════════════════════════════════════════

function CertifiedPayrollTab({ project }: { project: CertifiedProject | null }) {
  if (!project) {
    return (
      <div className="space-y-6">
        {/* Info Banner */}
        <div className="flex items-start gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800/30 rounded-xl">
          <Shield size={20} className="text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
          <div>
            <p className="text-sm font-medium text-blue-800 dark:text-blue-300">Certified Payroll (WH-347)</p>
            <p className="text-xs text-blue-700 dark:text-blue-400 mt-1">
              Required for Davis-Bacon prevailing wage projects and government contracts. Generated from approved timesheets and prevailing wage rates for the project area.
            </p>
          </div>
        </div>
        <Card>
          <CardContent className="p-12 text-center">
            <Shield size={32} className="mx-auto mb-3 text-muted" />
            <p className="text-main font-medium">No Certified Payroll Projects</p>
            <p className="text-muted text-sm mt-1">Certified payroll reports will appear here when you set up prevailing wage projects with approved timesheets.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const totalGross = project.entries.reduce((s, e) => s + e.grossPay, 0);
  const totalDeductions = project.entries.reduce((s, e) => s + e.deductions, 0);
  const totalNet = project.entries.reduce((s, e) => s + e.netPay, 0);
  const totalHours = project.entries.reduce((s, e) => s + e.totalHours, 0);

  return (
    <div className="space-y-6">
      {/* Info Banner */}
      <div className="flex items-start gap-3 p-4 bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800/30 rounded-xl">
        <Shield size={20} className="text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
        <div>
          <p className="text-sm font-medium text-blue-800 dark:text-blue-300">Certified Payroll (WH-347)</p>
          <p className="text-xs text-blue-700 dark:text-blue-400 mt-1">
            Required for Davis-Bacon prevailing wage projects and government contracts. Generated from approved timesheets and prevailing wage rates for the project area.
          </p>
        </div>
      </div>

      {/* Project Header */}
      <Card>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div>
              <p className="text-xs text-muted uppercase font-medium">Project</p>
              <p className="text-sm font-semibold text-main mt-1">{project.projectName}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase font-medium">Contract Number</p>
              <p className="text-sm font-semibold text-main mt-1">{project.contractNumber}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase font-medium">Prevailing Wage Area</p>
              <p className="text-sm font-semibold text-main mt-1">{project.prevailingWageArea}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase font-medium">Week Ending</p>
              <p className="text-sm font-semibold text-main mt-1">{formatDate(project.weekEnding)}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard title="Total Workers" value={String(project.entries.length)} icon={<HardHat size={20} />} />
        <StatsCard title="Total Hours" value={String(totalHours)} icon={<Clock size={20} />} />
        <StatsCard title="Total Gross" value={formatCurrency(totalGross)} icon={<DollarSign size={20} />} />
        <StatsCard title="Total Net" value={formatCurrency(totalNet)} icon={<Banknote size={20} />} />
      </div>

      {/* WH-347 Table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base">WH-347 Payroll Report</CardTitle>
              <p className="text-xs text-muted mt-1">Contractor: {project.contractor}</p>
            </div>
            <div className="flex items-center gap-2">
              <Button variant="secondary" size="sm"><Printer size={14} />Print</Button>
              <Button variant="secondary" size="sm"><Download size={14} />Export PDF</Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main bg-secondary/50">
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Name</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">SSN</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase">Classification</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Hrs</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">OT Hrs</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Rate</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">OT Rate</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Gross</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Ded.</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Net</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase">Fringes/Hr</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {project.entries.map((entry, idx) => (
                  <tr key={idx} className="hover:bg-surface-hover">
                    <td className="px-4 py-3 font-medium text-main">{entry.employeeName}</td>
                    <td className="px-4 py-3 text-muted font-mono text-xs">{entry.ssn}</td>
                    <td className="px-4 py-3">
                      <Badge variant="info">{entry.classification}</Badge>
                    </td>
                    <td className="px-4 py-3 text-right text-main">{entry.regularHours}</td>
                    <td className="px-4 py-3 text-right">
                      <span className={cn(entry.overtimeHours > 0 ? 'text-amber-600 font-medium' : 'text-muted')}>
                        {entry.overtimeHours}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right text-main">${entry.rate.toFixed(2)}</td>
                    <td className="px-4 py-3 text-right text-muted">${entry.otRate.toFixed(2)}</td>
                    <td className="px-4 py-3 text-right font-semibold text-main">{formatCurrency(entry.grossPay)}</td>
                    <td className="px-4 py-3 text-right text-red-600">{formatCurrency(entry.deductions)}</td>
                    <td className="px-4 py-3 text-right font-semibold text-emerald-600">{formatCurrency(entry.netPay)}</td>
                    <td className="px-4 py-3 text-right text-muted">${entry.fringes.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-main bg-secondary/50 font-semibold">
                  <td className="px-4 py-3 text-main" colSpan={3}>Totals</td>
                  <td className="px-4 py-3 text-right text-main">
                    {project.entries.reduce((s, e) => s + e.regularHours, 0)}
                  </td>
                  <td className="px-4 py-3 text-right text-amber-600">
                    {project.entries.reduce((s, e) => s + e.overtimeHours, 0)}
                  </td>
                  <td className="px-4 py-3" colSpan={2} />
                  <td className="px-4 py-3 text-right text-main">{formatCurrency(totalGross)}</td>
                  <td className="px-4 py-3 text-right text-red-600">{formatCurrency(totalDeductions)}</td>
                  <td className="px-4 py-3 text-right text-emerald-600">{formatCurrency(totalNet)}</td>
                  <td className="px-4 py-3" />
                </tr>
              </tfoot>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Compliance Statement */}
      <Card>
        <CardContent className="p-6">
          <h4 className="text-sm font-semibold text-main mb-3">Statement of Compliance</h4>
          <div className="p-4 bg-secondary rounded-lg text-xs text-muted leading-relaxed">
            <p>
              I, the undersigned, do hereby state: (1) That I pay or supervise the payment of the persons
              employed by {project.contractor} on the {project.projectName}; that during the payroll
              period commencing on the week ending {formatDate(project.weekEnding)}, all persons employed on
              said project have been paid the full weekly wages earned, that no rebates have been or will be
              made either directly or indirectly to or on behalf of said {project.contractor} from the
              full weekly wages earned by any person and that no deductions have been made either directly
              or indirectly from the full wages earned by any person, other than permissible deductions as
              defined in Regulations, Part 3 (29 C.F.R. Subtitle A), issued by the Secretary of Labor under
              the Copeland Act, as amended (48 Stat. 948, 63 Stat. 108, 72 Stat. 967; 40 U.S.C. 3145).
            </p>
          </div>
          <div className="grid grid-cols-2 gap-6 mt-4">
            <div>
              <p className="text-xs text-muted mb-2">Signature</p>
              <div className="h-12 border-b-2 border-dashed border-main" />
            </div>
            <div>
              <p className="text-xs text-muted mb-2">Date</p>
              <div className="h-12 border-b-2 border-dashed border-main" />
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
