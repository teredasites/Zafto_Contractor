'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Plus,
  Loader2,
  FileText,
  Send,
  CheckCircle,
  DollarSign,
  HardHat,
  ClipboardList,
  Printer,
  X,
  Trash2,
  ChevronDown,
  ChevronRight,
  Unlock,
  Calendar,
  Users,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';

import {
  useConstructionAccounting,
} from '@/lib/hooks/use-construction-accounting';
import type {
  ProgressBilling,
  ScheduleOfValuesItem,
  RetentionRecord,
  WIPRow,
  CertifiedPayrollRow,
} from '@/lib/hooks/use-construction-accounting';
import { useTranslation } from '@/lib/translations';

// ────────────────────────────────────────────
// Ledger Navigation
// ────────────────────────────────────────────

const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Chart of Accounts', href: '/dashboard/books/accounts', active: false },
  { label: 'Expenses', href: '/dashboard/books/expenses', active: false },
  { label: 'Vendors', href: '/dashboard/books/vendors', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Construction', href: '/dashboard/books/construction', active: true },
];

// ────────────────────────────────────────────
// Tab types
// ────────────────────────────────────────────

type TabId = 'billing' | 'retention' | 'wip' | 'payroll';

const TABS: { id: TabId; label: string; icon: typeof FileText }[] = [
  { id: 'billing', label: 'Progress Billing', icon: FileText },
  { id: 'retention', label: 'Retention', icon: DollarSign },
  { id: 'wip', label: 'WIP Report', icon: ClipboardList },
  { id: 'payroll', label: 'Certified Payroll', icon: Users },
];

// ────────────────────────────────────────────
// Status configs
// ────────────────────────────────────────────

const billingStatusConfig: Record<string, { label: string; variant: 'default' | 'info' | 'warning' | 'success' }> = {
  draft: { label: 'Draft', variant: 'default' },
  submitted: { label: 'Submitted', variant: 'info' },
  approved: { label: 'Approved', variant: 'warning' },
  paid: { label: 'Paid', variant: 'success' },
};

const retentionStatusConfig: Record<string, { label: string; variant: 'info' | 'warning' | 'success' }> = {
  active: { label: 'Active', variant: 'info' },
  partially_released: { label: 'Partially Released', variant: 'warning' },
  fully_released: { label: 'Fully Released', variant: 'success' },
};

const wipStatusConfig: Record<string, { label: string; variant: 'warning' | 'error' | 'success' }> = {
  over_billed: { label: 'Over-billed', variant: 'warning' },
  under_billed: { label: 'Under-billed', variant: 'error' },
  on_track: { label: 'On Track', variant: 'success' },
};

// ────────────────────────────────────────────
// Main Page
// ────────────────────────────────────────────

export default function ConstructionAccountingPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const {
    billings,
    retentionRecords,
    loading,
    error,
    fetchBillings,
    createBilling,
    submitBilling,
    approveBilling,
    fetchRetention,
    createRetention,
    releaseRetention,
    fetchWIPReport,
    fetchCertifiedPayroll,
  } = useConstructionAccounting();

  const [activeTab, setActiveTab] = useState<TabId>('billing');
  const [jobFilter, setJobFilter] = useState('');
  const [jobs, setJobs] = useState<{ id: string; title: string; customerName: string }[]>([]);
  const [jobsLoading, setJobsLoading] = useState(true);

  // Billing modal
  const [billingModalOpen, setBillingModalOpen] = useState(false);
  const [expandedBillingId, setExpandedBillingId] = useState<string | null>(null);

  // Retention modal
  const [retentionModalOpen, setRetentionModalOpen] = useState(false);
  const [releaseModalId, setReleaseModalId] = useState<string | null>(null);
  const [releaseAmount, setReleaseAmount] = useState('');

  // WIP
  const [wipData, setWipData] = useState<WIPRow[]>([]);
  const [wipLoaded, setWipLoaded] = useState(false);

  // Payroll
  const [payrollJobId, setPayrollJobId] = useState('');
  const [payrollWeekStart, setPayrollWeekStart] = useState('');
  const [payrollData, setPayrollData] = useState<CertifiedPayrollRow[]>([]);
  const [payrollLoaded, setPayrollLoaded] = useState(false);

  // Load jobs list (for dropdowns)
  useEffect(() => {
    let cancelled = false;
    const loadJobs = async () => {
      try {
        const { getSupabase } = await import('@/lib/supabase');
        const supabase = getSupabase();
        const { data } = await supabase
          .from('jobs')
          .select('id, title, customer_name')
          .order('title');

        if (!cancelled && data) {
          setJobs(data.map((j: Record<string, unknown>) => ({
            id: j.id as string,
            title: (j.title as string) || 'Untitled',
            customerName: (j.customer_name as string) || 'Unknown',
          })));
        }
      } catch {
        // Graceful degradation
      } finally {
        if (!cancelled) setJobsLoading(false);
      }
    };
    loadJobs();
    return () => { cancelled = true; };
  }, []);

  // Load data on tab switch
  useEffect(() => {
    if (activeTab === 'billing') {
      fetchBillings(jobFilter || undefined);
    } else if (activeTab === 'retention') {
      fetchRetention(jobFilter || undefined);
    } else if (activeTab === 'wip' && !wipLoaded) {
      fetchWIPReport().then((rows) => {
        setWipData(rows);
        setWipLoaded(true);
      });
    }
  }, [activeTab, jobFilter, fetchBillings, fetchRetention, fetchWIPReport, wipLoaded]);

  // Payroll fetch handler
  const handleFetchPayroll = useCallback(async () => {
    if (!payrollJobId || !payrollWeekStart) return;
    const rows = await fetchCertifiedPayroll(payrollJobId, payrollWeekStart);
    setPayrollData(rows);
    setPayrollLoaded(true);
  }, [payrollJobId, payrollWeekStart, fetchCertifiedPayroll]);

  // Billing actions
  const handleSubmitBilling = async (id: string) => {
    await submitBilling(id);
    fetchBillings(jobFilter || undefined);
  };

  const handleApproveBilling = async (id: string) => {
    await approveBilling(id, 'Admin');
    fetchBillings(jobFilter || undefined);
  };

  // Retention release
  const handleReleaseRetention = async () => {
    if (!releaseModalId || !releaseAmount) return;
    await releaseRetention(releaseModalId, parseFloat(releaseAmount));
    setReleaseModalId(null);
    setReleaseAmount('');
    fetchRetention(jobFilter || undefined);
  };

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => router.push('/dashboard/books')}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={18} className="text-muted" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('booksConstruction.title')}</h1>
            <p className="text-muted mt-0.5">
              G702/G703 billing, retention, WIP analysis, and certified payroll
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="p-2.5 bg-amber-100 dark:bg-amber-900/30 rounded-xl">
            <HardHat size={20} className="text-amber-600 dark:text-amber-400" />
          </div>
          <Badge variant="warning" size="md">{t('common.enterprise')}</Badge>
        </div>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
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

      {/* Sub-tabs for Construction */}
      <div className="flex items-center gap-1 border-b border-main pb-px">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px',
                activeTab === tab.id
                  ? 'border-accent text-accent'
                  : 'border-transparent text-muted hover:text-main'
              )}
            >
              <Icon size={15} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Error display */}
      {error && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">
          {error}
        </div>
      )}

      {/* Tab Content */}
      {activeTab === 'billing' && (
        <BillingTab
          billings={billings}
          jobs={jobs}
          jobFilter={jobFilter}
          setJobFilter={setJobFilter}
          loading={loading || jobsLoading}
          expandedBillingId={expandedBillingId}
          setExpandedBillingId={setExpandedBillingId}
          onNewBilling={() => setBillingModalOpen(true)}
          onSubmit={handleSubmitBilling}
          onApprove={handleApproveBilling}
        />
      )}

      {activeTab === 'retention' && (
        <RetentionTab
          records={retentionRecords}
          jobs={jobs}
          jobFilter={jobFilter}
          setJobFilter={setJobFilter}
          loading={loading || jobsLoading}
          onNew={() => setRetentionModalOpen(true)}
          onRelease={(id) => { setReleaseModalId(id); setReleaseAmount(''); }}
        />
      )}

      {activeTab === 'wip' && (
        <WIPTab
          data={wipData}
          loading={loading && !wipLoaded}
          onRefresh={() => {
            setWipLoaded(false);
            fetchWIPReport().then((rows) => {
              setWipData(rows);
              setWipLoaded(true);
            });
          }}
        />
      )}

      {activeTab === 'payroll' && (
        <PayrollTab
          jobs={jobs}
          jobsLoading={jobsLoading}
          payrollJobId={payrollJobId}
          setPayrollJobId={setPayrollJobId}
          payrollWeekStart={payrollWeekStart}
          setPayrollWeekStart={setPayrollWeekStart}
          data={payrollData}
          loaded={payrollLoaded}
          loading={loading}
          onFetch={handleFetchPayroll}
        />
      )}

      {/* New Billing Modal */}
      {billingModalOpen && (
        <NewBillingModal
          jobs={jobs}
          onSave={async (data) => {
            await createBilling(data);
            setBillingModalOpen(false);
            fetchBillings(jobFilter || undefined);
          }}
          onClose={() => setBillingModalOpen(false)}
        />
      )}

      {/* New Retention Modal */}
      {retentionModalOpen && (
        <NewRetentionModal
          jobs={jobs}
          onSave={async (jobId, rate, conditions) => {
            await createRetention(jobId, rate, conditions);
            setRetentionModalOpen(false);
            fetchRetention(jobFilter || undefined);
          }}
          onClose={() => setRetentionModalOpen(false)}
        />
      )}

      {/* Release Retention Modal */}
      {releaseModalId && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={() => setReleaseModalId(null)}>
          <div className="bg-surface rounded-xl shadow-2xl w-full max-w-sm border border-main p-6" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-semibold text-main mb-4">Release Retention</h3>
            <div className="mb-4">
              <label className="block text-sm font-medium text-main mb-1">Release Amount</label>
              <Input
                type="number"
                step="0.01"
                min="0.01"
                value={releaseAmount}
                onChange={(e) => setReleaseAmount(e.target.value)}
                placeholder="0.00"
              />
            </div>
            <div className="flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setReleaseModalId(null)}>{t('common.cancel')}</Button>
              <Button onClick={handleReleaseRetention} disabled={!releaseAmount || Number(releaseAmount) <= 0}>
                <Unlock size={14} />
                Release
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ────────────────────────────────────────────
// Tab 1: Progress Billing
// ────────────────────────────────────────────

function BillingTab({
  billings,
  jobs,
  jobFilter,
  setJobFilter,
  loading,
  expandedBillingId,
  setExpandedBillingId,
  onNewBilling,
  onSubmit,
  onApprove,
}: {
  billings: ProgressBilling[];
  jobs: { id: string; title: string }[];
  jobFilter: string;
  setJobFilter: (v: string) => void;
  loading: boolean;
  expandedBillingId: string | null;
  setExpandedBillingId: (v: string | null) => void;
  onNewBilling: () => void;
  onSubmit: (id: string) => Promise<void>;
  onApprove: (id: string) => Promise<void>;
}) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 size={24} className="animate-spin text-muted" />
        <span className="ml-3 text-muted text-sm">Loading billings...</span>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className="flex items-center justify-between">
        <select
          value={jobFilter}
          onChange={(e) => setJobFilter(e.target.value)}
          className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
        >
          <option value="">All Jobs</option>
          {jobs.map((j) => (
            <option key={j.id} value={j.id}>{j.title}</option>
          ))}
        </select>
        <Button onClick={onNewBilling}>
          <Plus size={16} />
          New Application
        </Button>
      </div>

      {/* Billing List */}
      <Card>
        <CardContent className="p-0">
          {/* Header */}
          <div className="grid grid-cols-12 gap-2 px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-main">
            <div className="col-span-1">App #</div>
            <div className="col-span-2">Job</div>
            <div className="col-span-2">Period</div>
            <div className="col-span-2 text-right">Contract</div>
            <div className="col-span-1 text-right">Completed</div>
            <div className="col-span-1 text-right">Retainage</div>
            <div className="col-span-1 text-right">Payment Due</div>
            <div className="col-span-1 text-center">Status</div>
            <div className="col-span-1 text-right">Actions</div>
          </div>
          <div className="divide-y divide-main">
            {billings.length === 0 ? (
              <div className="px-6 py-12 text-center text-sm text-muted">
                No billing applications found. Create one to get started.
              </div>
            ) : (
              billings.map((b) => {
                const sc = billingStatusConfig[b.status] || billingStatusConfig.draft;
                const isExpanded = expandedBillingId === b.id;
                return (
                  <div key={b.id}>
                    <div
                      className="grid grid-cols-12 gap-2 px-6 py-3 items-center hover:bg-surface-hover transition-colors cursor-pointer"
                      onClick={() => setExpandedBillingId(isExpanded ? null : b.id)}
                    >
                      <div className="col-span-1 flex items-center gap-1">
                        {isExpanded
                          ? <ChevronDown size={14} className="text-muted" />
                          : <ChevronRight size={14} className="text-muted" />}
                        <span className="text-sm font-medium text-main">#{b.applicationNumber}</span>
                      </div>
                      <div className="col-span-2">
                        <p className="text-sm font-medium text-main truncate">{b.jobTitle}</p>
                        <p className="text-xs text-muted truncate">{b.customerName}</p>
                      </div>
                      <div className="col-span-2 text-sm text-muted">
                        {b.billingPeriodStart} to {b.billingPeriodEnd}
                      </div>
                      <div className="col-span-2 text-right text-sm font-medium text-main tabular-nums">
                        {formatCurrency(b.revisedContract)}
                      </div>
                      <div className="col-span-1 text-right text-sm text-main tabular-nums">
                        {formatCurrency(b.totalCompletedToDate)}
                      </div>
                      <div className="col-span-1 text-right text-sm text-main tabular-nums">
                        {formatCurrency(b.totalRetainage)}
                      </div>
                      <div className="col-span-1 text-right text-sm font-semibold text-main tabular-nums">
                        {formatCurrency(b.currentPaymentDue)}
                      </div>
                      <div className="col-span-1 text-center">
                        <Badge variant={sc.variant} size="sm">{sc.label}</Badge>
                      </div>
                      <div className="col-span-1 flex items-center justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                        {b.status === 'draft' && (
                          <button
                            onClick={() => onSubmit(b.id)}
                            className="p-1 text-muted hover:text-blue-600 rounded transition-colors"
                            title="Submit"
                          >
                            <Send size={14} />
                          </button>
                        )}
                        {b.status === 'submitted' && (
                          <button
                            onClick={() => onApprove(b.id)}
                            className="p-1 text-muted hover:text-emerald-600 rounded transition-colors"
                            title="Approve"
                          >
                            <CheckCircle size={14} />
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Expanded: G703 Schedule of Values */}
                    {isExpanded && b.scheduleOfValues.length > 0 && (
                      <div className="px-6 py-4 bg-secondary/30 border-t border-main">
                        <h4 className="text-xs font-semibold text-muted uppercase tracking-wide mb-3">
                          G703 - Schedule of Values
                        </h4>
                        <div className="overflow-x-auto">
                          <table className="w-full text-xs">
                            <thead>
                              <tr className="border-b border-main">
                                <th className="text-left py-2 px-2 text-muted font-medium">Item</th>
                                <th className="text-left py-2 px-2 text-muted font-medium">Description</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Scheduled</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Prev.</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">This Period</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Materials</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Total</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">%</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Balance</th>
                                <th className="text-right py-2 px-2 text-muted font-medium">Retainage</th>
                              </tr>
                            </thead>
                            <tbody>
                              {b.scheduleOfValues.map((sov, i) => (
                                <tr key={i} className="border-b border-main/50">
                                  <td className="py-1.5 px-2 text-main">{sov.item}</td>
                                  <td className="py-1.5 px-2 text-main">{sov.description}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.scheduled_value)}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.prev_completed)}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.this_period)}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.materials_stored)}</td>
                                  <td className="py-1.5 px-2 text-right font-medium text-main tabular-nums">{formatCurrency(sov.total_completed)}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{sov.percent_complete.toFixed(1)}%</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.balance_to_finish)}</td>
                                  <td className="py-1.5 px-2 text-right text-main tabular-nums">{formatCurrency(sov.retainage)}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────
// Tab 2: Retention Tracking
// ────────────────────────────────────────────

function RetentionTab({
  records,
  jobs,
  jobFilter,
  setJobFilter,
  loading,
  onNew,
  onRelease,
}: {
  records: RetentionRecord[];
  jobs: { id: string; title: string }[];
  jobFilter: string;
  setJobFilter: (v: string) => void;
  loading: boolean;
  onNew: () => void;
  onRelease: (id: string) => void;
}) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 size={24} className="animate-spin text-muted" />
        <span className="ml-3 text-muted text-sm">Loading retention records...</span>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className="flex items-center justify-between">
        <select
          value={jobFilter}
          onChange={(e) => setJobFilter(e.target.value)}
          className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
        >
          <option value="">All Jobs</option>
          {jobs.map((j) => (
            <option key={j.id} value={j.id}>{j.title}</option>
          ))}
        </select>
        <Button onClick={onNew}>
          <Plus size={16} />
          New Retention Record
        </Button>
      </div>

      {/* Retention List */}
      <Card>
        <CardContent className="p-0">
          <div className="grid grid-cols-12 gap-2 px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-main">
            <div className="col-span-2">Job</div>
            <div className="col-span-1 text-right">Rate</div>
            <div className="col-span-2 text-right">Total Billed</div>
            <div className="col-span-2 text-right">Total Retained</div>
            <div className="col-span-1 text-right">Released</div>
            <div className="col-span-1 text-right">Balance</div>
            <div className="col-span-1 text-center">Status</div>
            <div className="col-span-2 text-right">Actions</div>
          </div>
          <div className="divide-y divide-main">
            {records.length === 0 ? (
              <div className="px-6 py-12 text-center text-sm text-muted">
                No retention records found.
              </div>
            ) : (
              records.map((r) => {
                const sc = retentionStatusConfig[r.status] || retentionStatusConfig.active;
                return (
                  <div key={r.id} className="grid grid-cols-12 gap-2 px-6 py-3 items-center hover:bg-surface-hover transition-colors">
                    <div className="col-span-2">
                      <p className="text-sm font-medium text-main truncate">{r.jobTitle}</p>
                      <p className="text-xs text-muted truncate">{r.customerName}</p>
                    </div>
                    <div className="col-span-1 text-right text-sm text-main tabular-nums">{r.retentionRate}%</div>
                    <div className="col-span-2 text-right text-sm text-main tabular-nums">{formatCurrency(r.totalBilled)}</div>
                    <div className="col-span-2 text-right text-sm text-main tabular-nums">{formatCurrency(r.totalRetained)}</div>
                    <div className="col-span-1 text-right text-sm text-emerald-600 tabular-nums">{formatCurrency(r.totalReleased)}</div>
                    <div className="col-span-1 text-right text-sm font-semibold text-main tabular-nums">{formatCurrency(r.balanceHeld)}</div>
                    <div className="col-span-1 text-center">
                      <Badge variant={sc.variant} size="sm">{sc.label}</Badge>
                    </div>
                    <div className="col-span-2 flex justify-end">
                      {r.status !== 'fully_released' && (
                        <Button variant="secondary" size="sm" onClick={() => onRelease(r.id)}>
                          <Unlock size={13} />
                          Release
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────
// Tab 3: WIP Report
// ────────────────────────────────────────────

function WIPTab({
  data,
  loading,
  onRefresh,
}: {
  data: WIPRow[];
  loading: boolean;
  onRefresh: () => void;
}) {
  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 size={24} className="animate-spin text-muted" />
        <span className="ml-3 text-muted text-sm">Generating WIP report...</span>
      </div>
    );
  }

  const totalCosts = data.reduce((s, r) => s + r.costsIncurred, 0);
  const totalBillings = data.reduce((s, r) => s + r.billingsToDate, 0);
  const totalEstimated = data.reduce((s, r) => s + r.estimatedGross, 0);
  const totalOverUnder = data.reduce((s, r) => s + r.overUnder, 0);

  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted">{data.length} active job{data.length !== 1 ? 's' : ''}</p>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={onRefresh}>
            <Loader2 size={14} />
            Refresh
          </Button>
          <Button variant="secondary" onClick={() => window.print()}>
            <Printer size={14} />
            Print WIP Schedule
          </Button>
        </div>
      </div>

      {/* WIP Table */}
      <Card>
        <CardContent className="p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-main bg-secondary/50">
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide">Job</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Costs Incurred</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Billings to Date</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Estimated Gross</th>
                <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Over/Under</th>
                <th className="text-center px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {data.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-sm text-muted">
                    No active jobs with cost data found.
                  </td>
                </tr>
              ) : (
                <>
                  {data.map((row) => {
                    const sc = wipStatusConfig[row.status] || wipStatusConfig.on_track;
                    return (
                      <tr key={row.jobId} className="hover:bg-surface-hover transition-colors">
                        <td className="px-6 py-3">
                          <p className="font-medium text-main">{row.jobTitle}</p>
                          <p className="text-xs text-muted">{row.customerName}</p>
                        </td>
                        <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(row.costsIncurred)}</td>
                        <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(row.billingsToDate)}</td>
                        <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(row.estimatedGross)}</td>
                        <td className={cn(
                          'px-4 py-3 text-right font-medium tabular-nums',
                          row.overUnder >= 0 ? 'text-emerald-600' : 'text-red-600'
                        )}>
                          {formatCurrency(row.overUnder)}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <Badge variant={sc.variant} size="sm">{sc.label}</Badge>
                        </td>
                      </tr>
                    );
                  })}
                  {/* Total row */}
                  <tr className="bg-secondary/50 font-semibold">
                    <td className="px-6 py-3 text-main">Total</td>
                    <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(totalCosts)}</td>
                    <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(totalBillings)}</td>
                    <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(totalEstimated)}</td>
                    <td className={cn(
                      'px-4 py-3 text-right tabular-nums',
                      totalOverUnder >= 0 ? 'text-emerald-600' : 'text-red-600'
                    )}>
                      {formatCurrency(totalOverUnder)}
                    </td>
                    <td className="px-4 py-3" />
                  </tr>
                </>
              )}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  );
}

// ────────────────────────────────────────────
// Tab 4: Certified Payroll (WH-347)
// ────────────────────────────────────────────

function PayrollTab({
  jobs,
  jobsLoading,
  payrollJobId,
  setPayrollJobId,
  payrollWeekStart,
  setPayrollWeekStart,
  data,
  loaded,
  loading,
  onFetch,
}: {
  jobs: { id: string; title: string }[];
  jobsLoading: boolean;
  payrollJobId: string;
  setPayrollJobId: (v: string) => void;
  payrollWeekStart: string;
  setPayrollWeekStart: (v: string) => void;
  data: CertifiedPayrollRow[];
  loaded: boolean;
  loading: boolean;
  onFetch: () => void;
}) {
  const totalRegHours = data.reduce((s, r) => s + r.regularHours, 0);
  const totalOTHours = data.reduce((s, r) => s + r.overtimeHours, 0);
  const totalGross = data.reduce((s, r) => s + r.grossPay, 0);
  // Placeholder deduction rate
  const deductionRate = 0.22;

  return (
    <div className="space-y-4">
      {/* Controls */}
      <Card>
        <CardContent className="p-4">
          <div className="flex items-end gap-4 flex-wrap">
            <div className="flex-1 min-w-[200px]">
              <label className="text-xs text-muted block mb-1">Job</label>
              <select
                value={payrollJobId}
                onChange={(e) => setPayrollJobId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
                disabled={jobsLoading}
              >
                <option value="">Select job...</option>
                {jobs.map((j) => (
                  <option key={j.id} value={j.id}>{j.title}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs text-muted block mb-1">Week Starting</label>
              <input
                type="date"
                value={payrollWeekStart}
                onChange={(e) => setPayrollWeekStart(e.target.value)}
                className="px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              />
            </div>
            <Button
              onClick={onFetch}
              disabled={!payrollJobId || !payrollWeekStart || loading}
            >
              {loading ? <Loader2 size={14} className="animate-spin" /> : <Calendar size={14} />}
              Generate
            </Button>
            {loaded && data.length > 0 && (
              <Button variant="secondary" onClick={() => window.print()}>
                <Printer size={14} />
                Print WH-347
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Payroll Table */}
      {loaded && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              WH-347 Certified Payroll Report
            </CardTitle>
            <p className="text-xs text-muted mt-1">
              Week of {payrollWeekStart}
            </p>
          </CardHeader>
          <CardContent className="p-0">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-main bg-secondary/50">
                  <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide">Employee</th>
                  <th className="text-left px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Classification</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">ST Hours</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">OT Hours</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Rate</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Gross Pay</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Deductions</th>
                  <th className="text-right px-4 py-3 text-xs font-medium text-muted uppercase tracking-wide">Net Pay</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-main">
                {data.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="px-6 py-12 text-center text-sm text-muted">
                      No time entries found for this job and week.
                    </td>
                  </tr>
                ) : (
                  <>
                    {data.map((row, i) => {
                      const deductions = Math.round(row.grossPay * deductionRate * 100) / 100;
                      const netPay = Math.round((row.grossPay - deductions) * 100) / 100;
                      return (
                        <tr key={i} className="hover:bg-surface-hover transition-colors">
                          <td className="px-6 py-3 font-medium text-main">{row.employeeName}</td>
                          <td className="px-4 py-3 text-main capitalize">{row.classification}</td>
                          <td className="px-4 py-3 text-right text-main tabular-nums">{row.regularHours.toFixed(1)}</td>
                          <td className="px-4 py-3 text-right text-main tabular-nums">{row.overtimeHours.toFixed(1)}</td>
                          <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(row.regularRate)}</td>
                          <td className="px-4 py-3 text-right font-medium text-main tabular-nums">{formatCurrency(row.grossPay)}</td>
                          <td className="px-4 py-3 text-right text-red-600 tabular-nums">{formatCurrency(deductions)}</td>
                          <td className="px-4 py-3 text-right font-semibold text-main tabular-nums">{formatCurrency(netPay)}</td>
                        </tr>
                      );
                    })}
                    {/* Total row */}
                    <tr className="bg-secondary/50 font-semibold">
                      <td className="px-6 py-3 text-main">Total</td>
                      <td className="px-4 py-3" />
                      <td className="px-4 py-3 text-right text-main tabular-nums">{totalRegHours.toFixed(1)}</td>
                      <td className="px-4 py-3 text-right text-main tabular-nums">{totalOTHours.toFixed(1)}</td>
                      <td className="px-4 py-3" />
                      <td className="px-4 py-3 text-right text-main tabular-nums">{formatCurrency(totalGross)}</td>
                      <td className="px-4 py-3 text-right text-red-600 tabular-nums">
                        {formatCurrency(Math.round(totalGross * deductionRate * 100) / 100)}
                      </td>
                      <td className="px-4 py-3 text-right text-main tabular-nums">
                        {formatCurrency(Math.round(totalGross * (1 - deductionRate) * 100) / 100)}
                      </td>
                    </tr>
                  </>
                )}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// ────────────────────────────────────────────
// New Billing Modal
// ────────────────────────────────────────────

function NewBillingModal({
  jobs,
  onSave,
  onClose,
}: {
  jobs: { id: string; title: string }[];
  onSave: (data: {
    jobId: string;
    billingPeriodStart: string;
    billingPeriodEnd: string;
    contractAmount: number;
    changeOrdersAmount: number;
    scheduleOfValues: ScheduleOfValuesItem[];
  }) => Promise<void>;
  onClose: () => void;
}) {
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [jobId, setJobId] = useState('');
  const [periodStart, setPeriodStart] = useState('');
  const [periodEnd, setPeriodEnd] = useState('');
  const [contractAmount, setContractAmount] = useState('');
  const [changeOrders, setChangeOrders] = useState('0');
  const [retainageRate, setRetainageRate] = useState(10);

  const defaultItem: ScheduleOfValuesItem = {
    item: '1',
    description: '',
    scheduled_value: 0,
    prev_completed: 0,
    this_period: 0,
    materials_stored: 0,
    total_completed: 0,
    percent_complete: 0,
    balance_to_finish: 0,
    retainage: 0,
  };

  const [sovItems, setSovItems] = useState<ScheduleOfValuesItem[]>([{ ...defaultItem }]);

  const recalcItem = (item: ScheduleOfValuesItem): ScheduleOfValuesItem => {
    const totalCompleted = item.prev_completed + item.this_period + item.materials_stored;
    const percentComplete = item.scheduled_value > 0
      ? Math.round((totalCompleted / item.scheduled_value) * 1000) / 10
      : 0;
    const balanceToFinish = Math.max(item.scheduled_value - totalCompleted, 0);
    const retainage = Math.round(totalCompleted * (retainageRate / 100) * 100) / 100;
    return {
      ...item,
      total_completed: totalCompleted,
      percent_complete: percentComplete,
      balance_to_finish: balanceToFinish,
      retainage,
    };
  };

  const updateItem = (index: number, field: keyof ScheduleOfValuesItem, value: string | number) => {
    setSovItems((prev) => {
      const next = [...prev];
      const updated = { ...next[index], [field]: value };
      next[index] = recalcItem(updated);
      return next;
    });
  };

  const addItem = () => {
    setSovItems((prev) => [
      ...prev,
      { ...defaultItem, item: String(prev.length + 1) },
    ]);
  };

  const removeItem = (index: number) => {
    if (sovItems.length <= 1) return;
    setSovItems((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (status: 'draft' | 'submitted') => {
    setSaving(true);
    setErr(null);
    try {
      if (!jobId) throw new Error('Select a job');
      if (!periodStart || !periodEnd) throw new Error('Billing period is required');
      if (!contractAmount || Number(contractAmount) <= 0) throw new Error('Contract amount is required');

      const recalcedItems = sovItems.map(recalcItem);

      await onSave({
        jobId,
        billingPeriodStart: periodStart,
        billingPeriodEnd: periodEnd,
        contractAmount: Number(contractAmount),
        changeOrdersAmount: Number(changeOrders) || 0,
        scheduleOfValues: recalcedItems,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-4xl border border-main max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main flex items-center justify-between">
          <h2 className="text-lg font-semibold text-main">New Progress Billing Application</h2>
          <button onClick={onClose} className="p-1 hover:bg-surface-hover rounded-lg">
            <X size={18} className="text-muted" />
          </button>
        </div>

        <div className="p-6 space-y-5">
          {/* Job & Period */}
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Job *</label>
              <select
                value={jobId}
                onChange={(e) => setJobId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="">Select job...</option>
                {jobs.map((j) => (
                  <option key={j.id} value={j.id}>{j.title}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Period Start *</label>
              <Input type="date" value={periodStart} onChange={(e) => setPeriodStart(e.target.value)} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Period End *</label>
              <Input type="date" value={periodEnd} onChange={(e) => setPeriodEnd(e.target.value)} />
            </div>
          </div>

          {/* Amounts */}
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Original Contract Amount *</label>
              <Input
                type="number"
                step="0.01"
                min="0"
                value={contractAmount}
                onChange={(e) => setContractAmount(e.target.value)}
                placeholder="0.00"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Change Orders</label>
              <Input
                type="number"
                step="0.01"
                value={changeOrders}
                onChange={(e) => setChangeOrders(e.target.value)}
                placeholder="0.00"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Retainage Rate (%)</label>
              <Input
                type="number"
                step="0.5"
                min="0"
                max="100"
                value={String(retainageRate)}
                onChange={(e) => setRetainageRate(Number(e.target.value) || 10)}
              />
            </div>
          </div>

          {/* Schedule of Values */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-main">Schedule of Values (G703)</h3>
              <Button variant="secondary" size="sm" onClick={addItem}>
                <Plus size={13} />
                Add Line
              </Button>
            </div>
            <div className="overflow-x-auto border border-main rounded-lg">
              <table className="w-full text-xs">
                <thead>
                  <tr className="bg-secondary/50 border-b border-main">
                    <th className="text-left px-2 py-2 text-muted font-medium w-14">Item</th>
                    <th className="text-left px-2 py-2 text-muted font-medium min-w-[140px]">Description</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Scheduled</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Prev. Done</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">This Period</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Materials</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Total</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-14">%</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Balance</th>
                    <th className="text-right px-2 py-2 text-muted font-medium w-24">Retainage</th>
                    <th className="w-8" />
                  </tr>
                </thead>
                <tbody>
                  {sovItems.map((item, i) => (
                    <tr key={i} className="border-b border-main/50">
                      <td className="px-2 py-1.5">
                        <input
                          type="text"
                          value={item.item}
                          onChange={(e) => updateItem(i, 'item', e.target.value)}
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs focus:outline-none focus:border-accent"
                        />
                      </td>
                      <td className="px-2 py-1.5">
                        <input
                          type="text"
                          value={item.description}
                          onChange={(e) => updateItem(i, 'description', e.target.value)}
                          placeholder="Description..."
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs focus:outline-none focus:border-accent"
                        />
                      </td>
                      <td className="px-2 py-1.5">
                        <input
                          type="number"
                          step="0.01"
                          value={item.scheduled_value || ''}
                          onChange={(e) => updateItem(i, 'scheduled_value', Number(e.target.value) || 0)}
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs text-right focus:outline-none focus:border-accent tabular-nums"
                        />
                      </td>
                      <td className="px-2 py-1.5">
                        <input
                          type="number"
                          step="0.01"
                          value={item.prev_completed || ''}
                          onChange={(e) => updateItem(i, 'prev_completed', Number(e.target.value) || 0)}
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs text-right focus:outline-none focus:border-accent tabular-nums"
                        />
                      </td>
                      <td className="px-2 py-1.5">
                        <input
                          type="number"
                          step="0.01"
                          value={item.this_period || ''}
                          onChange={(e) => updateItem(i, 'this_period', Number(e.target.value) || 0)}
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs text-right focus:outline-none focus:border-accent tabular-nums"
                        />
                      </td>
                      <td className="px-2 py-1.5">
                        <input
                          type="number"
                          step="0.01"
                          value={item.materials_stored || ''}
                          onChange={(e) => updateItem(i, 'materials_stored', Number(e.target.value) || 0)}
                          className="w-full px-1 py-1 bg-transparent border-b border-main/50 text-main text-xs text-right focus:outline-none focus:border-accent tabular-nums"
                        />
                      </td>
                      <td className="px-2 py-1.5 text-right text-main tabular-nums font-medium">
                        {formatCurrency(item.total_completed)}
                      </td>
                      <td className="px-2 py-1.5 text-right text-main tabular-nums">
                        {item.percent_complete.toFixed(1)}%
                      </td>
                      <td className="px-2 py-1.5 text-right text-main tabular-nums">
                        {formatCurrency(item.balance_to_finish)}
                      </td>
                      <td className="px-2 py-1.5 text-right text-main tabular-nums">
                        {formatCurrency(item.retainage)}
                      </td>
                      <td className="px-1 py-1.5">
                        {sovItems.length > 1 && (
                          <button
                            onClick={() => removeItem(i)}
                            className="p-0.5 text-muted hover:text-red-600 transition-colors"
                          >
                            <Trash2 size={12} />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Summary */}
          <div className="grid grid-cols-3 gap-4 bg-secondary/50 rounded-lg p-4">
            <div>
              <p className="text-xs text-muted">Total Completed to Date</p>
              <p className="text-lg font-semibold text-main tabular-nums">
                {formatCurrency(sovItems.reduce((s, item) => s + item.total_completed, 0))}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted">Total Retainage</p>
              <p className="text-lg font-semibold text-main tabular-nums">
                {formatCurrency(sovItems.reduce((s, item) => s + item.retainage, 0))}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted">Current Payment Due</p>
              <p className="text-lg font-bold text-accent tabular-nums">
                {formatCurrency(
                  sovItems.reduce((s, item) => s + item.total_completed, 0)
                  - sovItems.reduce((s, item) => s + item.retainage, 0)
                )}
              </p>
            </div>
          </div>

          {err && <p className="text-sm text-red-600">{err}</p>}

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="secondary" onClick={onClose}>Cancel</Button>
            <Button variant="secondary" onClick={() => handleSubmit('draft')} disabled={saving}>
              {saving ? 'Saving...' : 'Save as Draft'}
            </Button>
            <Button onClick={() => handleSubmit('submitted')} disabled={saving}>
              <Send size={14} />
              {saving ? 'Saving...' : 'Submit'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ────────────────────────────────────────────
// New Retention Modal
// ────────────────────────────────────────────

function NewRetentionModal({
  jobs,
  onSave,
  onClose,
}: {
  jobs: { id: string; title: string }[];
  onSave: (jobId: string, rate: number, conditions?: string) => Promise<void>;
  onClose: () => void;
}) {
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [jobId, setJobId] = useState('');
  const [rate, setRate] = useState('10');
  const [conditions, setConditions] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      if (!jobId) throw new Error('Select a job');
      if (!rate || Number(rate) <= 0) throw new Error('Retention rate is required');
      await onSave(jobId, Number(rate), conditions || undefined);
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to save');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-md border border-main"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main flex items-center justify-between">
          <h2 className="text-lg font-semibold text-main">New Retention Record</h2>
          <button onClick={onClose} className="p-1 hover:bg-surface-hover rounded-lg">
            <X size={18} className="text-muted" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1">Job *</label>
            <select
              value={jobId}
              onChange={(e) => setJobId(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
            >
              <option value="">Select job...</option>
              {jobs.map((j) => (
                <option key={j.id} value={j.id}>{j.title}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Retention Rate (%) *</label>
            <Input
              type="number"
              step="0.5"
              min="0"
              max="100"
              value={rate}
              onChange={(e) => setRate(e.target.value.replace(/[^0-9.]/g, ''))}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1">Release Conditions</label>
            <textarea
              value={conditions}
              onChange={(e) => setConditions(e.target.value)}
              rows={3}
              placeholder="e.g., Upon substantial completion and receipt of lien waivers"
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none"
            />
          </div>
          {err && <p className="text-sm text-red-600">{err}</p>}
          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>Cancel</Button>
            <Button type="submit" disabled={saving}>{saving ? 'Saving...' : 'Create Record'}</Button>
          </div>
        </form>
      </div>
    </div>
  );
}
