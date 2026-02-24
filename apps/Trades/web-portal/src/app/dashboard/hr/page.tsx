'use client';

import { useState } from 'react';
import {
  Users,
  UserPlus,
  ClipboardList,
  GraduationCap,
  Star,
  ChevronDown,
  ChevronRight,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Clock,
  Calendar,
  Shield,
  Heart,
  FileText,
  Phone,
  Award,
  Plus,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, formatCurrency, cn } from '@/lib/utils';
import {
  useHR,
  type EmployeeRecord,
  type OnboardingChecklist,
  type TrainingRecord,
  type PerformanceReview,
  type EmployeeStatus,
  type OnboardingStatus,
  type TrainingType,
  type TrainingStatus,
  type ReviewType,
  type ReviewStatus,
} from '@/lib/hooks/use-hr';
import { useTranslation } from '@/lib/translations';

// ==================== CONFIG ====================

type TabKey = 'employees' | 'onboarding' | 'training' | 'reviews';

const employeeStatusConfig: Record<EmployeeStatus, { label: string; variant: 'success' | 'warning' | 'error' | 'default' }> = {
  active: { label: 'Active', variant: 'success' },
  on_leave: { label: 'On Leave', variant: 'warning' },
  terminated: { label: 'Terminated', variant: 'error' },
  suspended: { label: 'Suspended', variant: 'default' },
};

const onboardingStatusConfig: Record<OnboardingStatus, { label: string; variant: 'default' | 'warning' | 'success' | 'error' }> = {
  not_started: { label: 'Not Started', variant: 'default' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'error' },
};

const trainingTypeConfig: Record<TrainingType, { label: string; variant: 'error' | 'warning' | 'info' | 'purple' | 'default' | 'success' | 'secondary' }> = {
  safety: { label: 'Safety', variant: 'error' },
  osha: { label: 'OSHA', variant: 'warning' },
  trade_specific: { label: 'Trade Specific', variant: 'info' },
  company: { label: 'Company', variant: 'purple' },
  compliance: { label: 'Compliance', variant: 'default' },
  equipment: { label: 'Equipment', variant: 'success' },
  other: { label: 'Other', variant: 'secondary' },
};

const trainingStatusConfig: Record<TrainingStatus, { label: string; variant: 'info' | 'warning' | 'success' | 'error' | 'default' }> = {
  scheduled: { label: 'Scheduled', variant: 'info' },
  in_progress: { label: 'In Progress', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
  failed: { label: 'Failed', variant: 'error' },
  expired: { label: 'Expired', variant: 'default' },
};

const reviewTypeConfig: Record<ReviewType, string> = {
  annual: 'Annual',
  semi_annual: 'Semi-Annual',
  quarterly: 'Quarterly',
  probation: 'Probation',
  promotion: 'Promotion',
  pip: 'PIP',
};

const reviewStatusConfig: Record<ReviewStatus, { label: string; variant: 'default' | 'info' | 'warning' | 'success' }> = {
  draft: { label: 'Draft', variant: 'default' },
  submitted: { label: 'Submitted', variant: 'info' },
  acknowledged: { label: 'Acknowledged', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
};

const employmentTypeLabels: Record<string, string> = {
  full_time: 'Full-Time',
  part_time: 'Part-Time',
  contract: 'Contract',
  seasonal: 'Seasonal',
  intern: 'Intern',
};

// ==================== MAIN PAGE ====================

export default function HRPage() {
  const { t } = useTranslation();
  const {
    employees,
    onboardingChecklists,
    trainingRecords,
    performanceReviews,
    loading,
    activeEmployees,
    onLeave,
    expiringTraining,
    pendingReviews,
  } = useHR();

  const [activeTab, setActiveTab] = useState<TabKey>('employees');
  const [search, setSearch] = useState('');

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
          {[...Array(5)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(5)].map((_, i) => <div key={i} className="px-6 py-4 flex items-center gap-4"><div className="flex-1"><div className="skeleton h-4 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div><div className="skeleton h-5 w-16 rounded-full" /></div>)}
        </div>
      </div>
    );
  }

  const tabs: { key: TabKey; label: string; icon: React.ReactNode; count: number }[] = [
    { key: 'employees', label: 'Employees', icon: <Users size={16} />, count: employees.length },
    { key: 'onboarding', label: 'Onboarding', icon: <ClipboardList size={16} />, count: onboardingChecklists.filter((o) => o.status !== 'completed' && o.status !== 'cancelled').length },
    { key: 'training', label: 'Training', icon: <GraduationCap size={16} />, count: trainingRecords.length },
    { key: 'reviews', label: 'Reviews', icon: <Star size={16} />, count: performanceReviews.length },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('hr.title')}</h1>
          <p className="text-muted mt-1">Employee management, onboarding, training, and performance reviews</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Users size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{employees.length}</p><p className="text-sm text-muted">{t('hr.totalEmployees')}</p></div>
        </div></CardContent></Card>

        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{activeEmployees.length}</p><p className="text-sm text-muted">{t('common.active')}</p></div>
        </div></CardContent></Card>

        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><Clock size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{onLeave.length}</p><p className="text-sm text-muted">{t('hr.onLeave')}</p></div>
        </div></CardContent></Card>

        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><AlertTriangle size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{expiringTraining.length}</p><p className="text-sm text-muted">{t('hr.expiringCerts')}</p></div>
        </div></CardContent></Card>

        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><FileText size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{pendingReviews.length}</p><p className="text-sm text-muted">{t('hr.pendingReviews')}</p></div>
        </div></CardContent></Card>
      </div>

      {/* Expiring Training Alert */}
      {expiringTraining.length > 0 && (
        <div className="p-4 bg-amber-50 dark:bg-amber-900/10 border border-amber-200 dark:border-amber-800/40 rounded-xl flex items-start gap-3">
          <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
          <div>
            <p className="font-medium text-amber-800 dark:text-amber-200">
              {expiringTraining.length} certification{expiringTraining.length !== 1 ? 's' : ''} expiring within 60 days
            </p>
            <p className="text-sm text-amber-700 dark:text-amber-300 mt-1">
              {expiringTraining.slice(0, 3).map((t) => `${t.userName || 'Unknown'} - ${t.title}`).join(', ')}
              {expiringTraining.length > 3 ? `, and ${expiringTraining.length - 3} more` : ''}
            </p>
          </div>
        </div>
      )}

      {/* Tab Navigation */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => { setActiveTab(tab.key); setSearch(''); }}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors',
              activeTab === tab.key
                ? 'bg-surface shadow-sm text-main'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
            <span className={cn(
              'ml-1 px-1.5 py-0.5 text-xs rounded-full',
              activeTab === tab.key
                ? 'bg-accent/10 text-accent'
                : 'bg-main/10 text-muted'
            )}>
              {tab.count}
            </span>
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'employees' && (
        <EmployeesTab employees={employees} search={search} onSearchChange={setSearch} />
      )}
      {activeTab === 'onboarding' && (
        <OnboardingTab checklists={onboardingChecklists} search={search} onSearchChange={setSearch} />
      )}
      {activeTab === 'training' && (
        <TrainingTab records={trainingRecords} search={search} onSearchChange={setSearch} />
      )}
      {activeTab === 'reviews' && (
        <ReviewsTab reviews={performanceReviews} search={search} onSearchChange={setSearch} />
      )}
    </div>
  );
}

// ==================== EMPLOYEES TAB ====================

function EmployeesTab({ employees, search, onSearchChange }: {
  employees: EmployeeRecord[];
  search: string;
  onSearchChange: (v: string) => void;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);

  const filtered = employees.filter((e) => {
    const matchesSearch =
      (e.userName || '').toLowerCase().includes(search.toLowerCase()) ||
      (e.jobTitle || '').toLowerCase().includes(search.toLowerCase()) ||
      (e.department || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || e.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex flex-col sm:flex-row gap-4">
          <SearchInput value={search} onChange={onSearchChange} placeholder={t('hr.searchEmployees')} className="sm:w-80" />
          <Select
            options={[
              { value: 'all', label: 'All Statuses' },
              ...Object.entries(employeeStatusConfig).map(([k, v]) => ({ value: k, label: v.label })),
            ]}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="sm:w-48"
          />
        </div>
        <Button onClick={() => setShowNewModal(true)}><UserPlus size={16} />{t('common.addEmployee')}</Button>
      </div>

      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">{t('common.employee')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.jobTitle')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('hiring.department')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.type')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('hr.hireDate')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('hr.payRate')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.status')}</th>
                <th className="px-4 py-3 w-10" />
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((emp) => {
                const isExpanded = expandedId === emp.id;
                const statusCfg = employeeStatusConfig[emp.status];
                return (
                  <EmployeeRow
                    key={emp.id}
                    employee={emp}
                    isExpanded={isExpanded}
                    statusVariant={statusCfg.variant}
                    statusLabel={statusCfg.label}
                    onToggle={() => setExpandedId(isExpanded ? null : emp.id)}
                  />
                );
              })}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <div className="p-12 text-center">
            <Users size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('hr.noEmployeesFound')}</h3>
            <p className="text-muted mb-4">{t('hr.addEmployeeRecords')}</p>
            <Button onClick={() => setShowNewModal(true)}><UserPlus size={16} />{t('common.addEmployee')}</Button>
          </div>
        )}
      </Card>

      {showNewModal && <NewEmployeeModal onClose={() => setShowNewModal(false)} />}
    </div>
  );
}

function EmployeeRow({ employee, isExpanded, statusVariant, statusLabel, onToggle }: {
  employee: EmployeeRecord;
  isExpanded: boolean;
  statusVariant: 'success' | 'warning' | 'error' | 'default';
  statusLabel: string;
  onToggle: () => void;
}) {
  const { t } = useTranslation();
  return (
    <>
      <tr className="hover:bg-surface-hover transition-colors cursor-pointer" onClick={onToggle}>
        <td className="px-6 py-3.5">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-accent/10 text-accent flex items-center justify-center text-sm font-medium">
              {(employee.userName || '?')[0]?.toUpperCase()}
            </div>
            <div>
              <p className="font-medium text-main text-sm">{employee.userName || 'Unknown'}</p>
              <p className="text-xs text-muted">{employee.userEmail || ''}</p>
            </div>
          </div>
        </td>
        <td className="px-4 py-3.5 text-sm text-main">{employee.jobTitle || '-'}</td>
        <td className="px-4 py-3.5 text-sm text-main">{employee.department || '-'}</td>
        <td className="px-4 py-3.5 text-sm text-main">{employmentTypeLabels[employee.employmentType] || employee.employmentType}</td>
        <td className="px-4 py-3.5 text-sm text-muted">{employee.hireDate ? formatDate(employee.hireDate) : '-'}</td>
        <td className="px-4 py-3.5 text-sm text-main font-medium">
          {formatCurrency(employee.payRate)}{employee.payType === 'hourly' ? '/hr' : '/yr'}
        </td>
        <td className="px-4 py-3.5">
          <Badge variant={statusVariant} dot>{statusLabel}</Badge>
        </td>
        <td className="px-4 py-3.5">
          {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
        </td>
      </tr>
      {isExpanded && (
        <tr>
          <td colSpan={8} className="px-6 py-4 bg-secondary/50">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Emergency Contact */}
              <div>
                <h4 className="text-xs font-medium text-muted uppercase tracking-wider mb-3 flex items-center gap-2">
                  <Phone size={14} /> Emergency Contact
                </h4>
                <div className="space-y-1.5">
                  <p className="text-sm text-main">{employee.emergencyContactName || 'Not provided'}</p>
                  {employee.emergencyContactPhone && <p className="text-sm text-muted">{employee.emergencyContactPhone}</p>}
                  {employee.emergencyContactRelation && <p className="text-xs text-muted">Relation: {employee.emergencyContactRelation}</p>}
                </div>
              </div>

              {/* Benefits */}
              <div>
                <h4 className="text-xs font-medium text-muted uppercase tracking-wider mb-3 flex items-center gap-2">
                  <Heart size={14} /> Benefits
                </h4>
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-muted w-16">Health:</span>
                    <span className="text-main">{employee.healthPlan || 'None'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-muted w-16">Dental:</span>
                    <span className="text-main">{employee.dentalPlan || 'None'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-muted w-16">Vision:</span>
                    <span className="text-main">{employee.visionPlan || 'None'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-muted w-16">401k:</span>
                    <span className="text-main">{employee.retirementPlan || 'None'}</span>
                  </div>
                </div>
              </div>

              {/* Documents & Time Off */}
              <div>
                <h4 className="text-xs font-medium text-muted uppercase tracking-wider mb-3 flex items-center gap-2">
                  <FileText size={14} /> Documents & Time Off
                </h4>
                <div className="space-y-1.5">
                  <div className="flex items-center gap-2 text-sm">
                    <span className={cn('w-2 h-2 rounded-full', employee.w4Path ? 'bg-emerald-500' : 'bg-red-500')} />
                    <span className="text-main">W-4 {employee.w4Path ? 'Filed' : 'Missing'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className={cn('w-2 h-2 rounded-full', employee.i9Path ? 'bg-emerald-500' : 'bg-red-500')} />
                    <span className="text-main">I-9 {employee.i9Path ? 'Filed' : 'Missing'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className={cn('w-2 h-2 rounded-full', employee.directDepositPath ? 'bg-emerald-500' : 'bg-red-500')} />
                    <span className="text-main">Direct Deposit {employee.directDepositPath ? 'Set' : 'Missing'}</span>
                  </div>
                  <div className="mt-2 pt-2 border-t border-main">
                    <p className="text-sm text-muted">PTO: <span className="text-main font-medium">{employee.ptoBalanceHours}h</span></p>
                    <p className="text-sm text-muted">Sick: <span className="text-main font-medium">{employee.sickLeaveHours}h</span></p>
                  </div>
                </div>
              </div>
            </div>
            {employee.notes && (
              <div className="mt-4 pt-4 border-t border-main">
                <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.notes')}</p>
                <p className="text-sm text-main">{employee.notes}</p>
              </div>
            )}
          </td>
        </tr>
      )}
    </>
  );
}

function NewEmployeeModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>{t('common.addEmployee')}</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><X size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job Title *</label>
            <input type="text" placeholder="Electrician" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Employment Type"
              options={Object.entries(employmentTypeLabels).map(([k, v]) => ({ value: k, label: v }))}
            />
            <Select
              label="Pay Type"
              options={[
                { value: 'hourly', label: 'Hourly' },
                { value: 'salary', label: 'Salary' },
              ]}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('hr.payRate')}</label>
              <input type="number" placeholder="0.00" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('hiring.department')}</label>
              <input type="text" placeholder={t('common.electrical')} className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('hr.hireDate')}</label>
            <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1"><UserPlus size={16} />{t('common.addEmployee')}</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ==================== ONBOARDING TAB ====================

function OnboardingTab({ checklists, search, onSearchChange }: {
  checklists: OnboardingChecklist[];
  search: string;
  onSearchChange: (v: string) => void;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filtered = checklists.filter((c) => {
    const matchesSearch =
      c.templateName.toLowerCase().includes(search.toLowerCase()) ||
      (c.employeeName || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || c.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder="Search onboarding..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(onboardingStatusConfig).map(([k, v]) => ({ value: k, label: v.label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <div className="space-y-3">
        {filtered.map((checklist) => {
          const completedCount = checklist.items.filter((i) => i.completed).length;
          const totalCount = checklist.items.length;
          const progress = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;
          const isExpanded = expandedId === checklist.id;
          const statusCfg = onboardingStatusConfig[checklist.status];

          return (
            <Card key={checklist.id} className="hover:border-accent/30 transition-colors">
              <CardContent className="p-5">
                <div
                  className="flex items-center justify-between cursor-pointer"
                  onClick={() => setExpandedId(isExpanded ? null : checklist.id)}
                >
                  <div className="flex items-center gap-4 flex-1">
                    <div className="p-2.5 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                      <ClipboardList size={22} className="text-blue-600 dark:text-blue-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-main">{checklist.templateName}</h3>
                        <Badge variant={statusCfg.variant}>{statusCfg.label}</Badge>
                      </div>
                      <p className="text-sm text-muted">
                        {checklist.employeeName || 'Unknown'} {checklist.dueDate ? ` -- Due: ${formatDate(checklist.dueDate)}` : ''}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4 ml-4">
                    <div className="text-right">
                      <span className="text-sm font-medium text-main">{completedCount}/{totalCount}</span>
                      <div className="w-24 h-2 bg-secondary rounded-full overflow-hidden mt-1">
                        <div
                          className={cn('h-full rounded-full transition-all', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-secondary')}
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    </div>
                    {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                  </div>
                </div>

                {isExpanded && (
                  <div className="mt-4 pt-4 border-t border-main space-y-2">
                    {checklist.items.map((item, idx) => (
                      <div
                        key={idx}
                        className={cn(
                          'flex items-start gap-3 p-3 rounded-lg border',
                          item.completed
                            ? 'bg-emerald-50/50 dark:bg-emerald-900/5 border-emerald-200 dark:border-emerald-800/30'
                            : 'bg-surface border-main'
                        )}
                      >
                        <div className="mt-0.5">
                          {item.completed
                            ? <CheckCircle size={18} className="text-emerald-500" />
                            : <div className="w-[18px] h-[18px] rounded-full border-2 border-muted" />}
                        </div>
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <p className="text-sm text-main">{item.title}</p>
                            {item.required && <Badge variant="error" size="sm">{t('common.required')}</Badge>}
                          </div>
                          {item.description && <p className="text-xs text-muted mt-0.5">{item.description}</p>}
                          {item.completedAt && (
                            <p className="text-xs text-emerald-600 dark:text-emerald-400 mt-1">
                              Completed {formatDate(item.completedAt)}
                            </p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}

        {filtered.length === 0 && (
          <Card><CardContent className="p-12 text-center">
            <ClipboardList size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('hr.noOnboardingChecklists')}</h3>
            <p className="text-muted">{t('hr.createChecklistsForOnboarding')}</p>
          </CardContent></Card>
        )}
      </div>
    </div>
  );
}

// ==================== TRAINING TAB ====================

function TrainingTab({ records, search, onSearchChange }: {
  records: TrainingRecord[];
  search: string;
  onSearchChange: (v: string) => void;
}) {
  const { t } = useTranslation();
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');

  const filtered = records.filter((r) => {
    const matchesSearch =
      r.title.toLowerCase().includes(search.toLowerCase()) ||
      (r.userName || '').toLowerCase().includes(search.toLowerCase()) ||
      (r.provider || '').toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || r.trainingType === typeFilter;
    const matchesStatus = statusFilter === 'all' || r.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder="Search training..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Types' },
            ...Object.entries(trainingTypeConfig).map(([k, v]) => ({ value: k, label: v.label })),
          ]}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(trainingStatusConfig).map(([k, v]) => ({ value: k, label: v.label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-6 py-3">{t('common.training')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.employee')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.type')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.date')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.expiration')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.score')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.result')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase tracking-wider px-4 py-3">{t('common.status')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filtered.map((record) => {
                const typeCfg = trainingTypeConfig[record.trainingType];
                const statusCfg = trainingStatusConfig[record.status];
                const isExpiring = record.expirationDate && (() => {
                  const now = new Date();
                  const exp = new Date(record.expirationDate as string);
                  const sixtyDays = new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000);
                  return exp >= now && exp <= sixtyDays;
                })();

                return (
                  <tr key={record.id} className="hover:bg-surface-hover transition-colors">
                    <td className="px-6 py-3.5">
                      <div>
                        <p className="font-medium text-main text-sm">{record.title}</p>
                        {record.provider && <p className="text-xs text-muted">{record.provider}</p>}
                        {record.certificateNumber && (
                          <div className="flex items-center gap-1 mt-0.5">
                            <Award size={12} className="text-muted" />
                            <p className="text-xs text-muted">{record.certificateNumber}</p>
                          </div>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-sm text-main">{record.userName || '-'}</td>
                    <td className="px-4 py-3.5"><Badge variant={typeCfg.variant}>{typeCfg.label}</Badge></td>
                    <td className="px-4 py-3.5 text-sm text-muted">{record.trainingDate ? formatDate(record.trainingDate) : '-'}</td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-1.5">
                        {isExpiring && <AlertTriangle size={14} className="text-amber-500" />}
                        <span className={cn('text-sm', isExpiring ? 'text-amber-600 dark:text-amber-400 font-medium' : 'text-muted')}>
                          {record.expirationDate ? formatDate(record.expirationDate) : '-'}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5 text-sm text-main">{record.score != null ? `${record.score}%` : '-'}</td>
                    <td className="px-4 py-3.5">
                      {record.passed != null ? (
                        record.passed
                          ? <Badge variant="success" dot>{t('common.pass')}</Badge>
                          : <Badge variant="error" dot>{t('common.fail')}</Badge>
                      ) : (
                        <span className="text-sm text-muted">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3.5"><Badge variant={statusCfg.variant}>{statusCfg.label}</Badge></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {filtered.length === 0 && (
          <div className="p-12 text-center">
            <GraduationCap size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('hr.noTrainingRecords')}</h3>
            <p className="text-muted">{t('hr.trackEmployeeTraining')}</p>
          </div>
        )}
      </Card>
    </div>
  );
}

// ==================== REVIEWS TAB ====================

function ReviewsTab({ reviews, search, onSearchChange }: {
  reviews: PerformanceReview[];
  search: string;
  onSearchChange: (v: string) => void;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const filtered = reviews.filter((r) => {
    const matchesSearch =
      (r.employeeName || '').toLowerCase().includes(search.toLowerCase()) ||
      (r.reviewerName || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || r.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={onSearchChange} placeholder="Search reviews..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            ...Object.entries(reviewStatusConfig).map(([k, v]) => ({ value: k, label: v.label })),
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <div className="space-y-3">
        {filtered.map((review) => {
          const isExpanded = expandedId === review.id;
          const statusCfg = reviewStatusConfig[review.status];

          return (
            <Card key={review.id} className="hover:border-accent/30 transition-colors">
              <CardContent className="p-5">
                <div
                  className="flex items-center justify-between cursor-pointer"
                  onClick={() => setExpandedId(isExpanded ? null : review.id)}
                >
                  <div className="flex items-center gap-4 flex-1">
                    <div className="p-2.5 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                      <Star size={22} className="text-purple-600 dark:text-purple-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-main">{review.employeeName || 'Unknown'}</h3>
                        <Badge variant="info">{reviewTypeConfig[review.reviewType]}</Badge>
                        <Badge variant={statusCfg.variant}>{statusCfg.label}</Badge>
                      </div>
                      <p className="text-sm text-muted">
                        {review.reviewPeriodStart && review.reviewPeriodEnd
                          ? `${formatDate(review.reviewPeriodStart)} - ${formatDate(review.reviewPeriodEnd)}`
                          : 'No period set'}
                        {review.reviewerName ? ` -- Reviewer: ${review.reviewerName}` : ''}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-4 ml-4">
                    {review.overallRating != null && (
                      <div className="flex items-center gap-1">
                        {[1, 2, 3, 4, 5].map((star) => (
                          <Star
                            key={star}
                            size={16}
                            className={cn(
                              star <= (review.overallRating || 0)
                                ? 'text-amber-400 fill-amber-400'
                                : 'text-muted'
                            )}
                          />
                        ))}
                        <span className="text-sm font-medium text-main ml-1">{review.overallRating}</span>
                      </div>
                    )}
                    {isExpanded ? <ChevronDown size={16} className="text-muted" /> : <ChevronRight size={16} className="text-muted" />}
                  </div>
                </div>

                {isExpanded && (
                  <div className="mt-4 pt-4 border-t border-main space-y-4">
                    {/* Rating Breakdown */}
                    <div>
                      <h4 className="text-xs font-medium text-muted uppercase tracking-wider mb-3">{t('common.ratingBreakdown')}</h4>
                      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
                        {[
                          { label: 'Quality', value: review.qualityRating },
                          { label: 'Productivity', value: review.productivityRating },
                          { label: 'Reliability', value: review.reliabilityRating },
                          { label: 'Teamwork', value: review.teamworkRating },
                          { label: 'Safety', value: review.safetyRating },
                        ].map((item) => (
                          <div key={item.label} className="p-3 bg-secondary rounded-lg text-center">
                            <p className="text-xs text-muted mb-1">{item.label}</p>
                            <div className="flex items-center justify-center gap-0.5">
                              {[1, 2, 3, 4, 5].map((star) => (
                                <Star
                                  key={star}
                                  size={14}
                                  className={cn(
                                    star <= (item.value || 0)
                                      ? 'text-amber-400 fill-amber-400'
                                      : 'text-muted'
                                  )}
                                />
                              ))}
                            </div>
                            <p className="text-sm font-medium text-main mt-1">
                              {item.value != null ? `${item.value}/5` : '-'}
                            </p>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Written Feedback */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {review.strengths && (
                        <div>
                          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.strengths')}</p>
                          <p className="text-sm text-main">{review.strengths}</p>
                        </div>
                      )}
                      {review.areasForImprovement && (
                        <div>
                          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.areasForImprovement')}</p>
                          <p className="text-sm text-main">{review.areasForImprovement}</p>
                        </div>
                      )}
                      {review.goals && (
                        <div>
                          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.goals')}</p>
                          <p className="text-sm text-main">{review.goals}</p>
                        </div>
                      )}
                      {review.managerSummary && (
                        <div>
                          <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.managerSummary')}</p>
                          <p className="text-sm text-main">{review.managerSummary}</p>
                        </div>
                      )}
                    </div>

                    {review.employeeComments && (
                      <div>
                        <p className="text-xs text-muted uppercase tracking-wider mb-1">{t('common.employeeComments')}</p>
                        <p className="text-sm text-main italic">{review.employeeComments}</p>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}

        {filtered.length === 0 && (
          <Card><CardContent className="p-12 text-center">
            <Star size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('hr.noPerformanceReviews')}</h3>
            <p className="text-muted">{t('common.trackEmployeePerformanceWithPeriodicReviewsAndRati')}</p>
          </CardContent></Card>
        )}
      </div>
    </div>
  );
}
