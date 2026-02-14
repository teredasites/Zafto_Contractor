'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  Zap,
  ZapOff,
  Play,
  Pause,
  Clock,
  Mail,
  MessageSquare,
  Bell,
  FileText,
  DollarSign,
  Users,
  Briefcase,
  ArrowRight,
  MoreHorizontal,
  CheckCircle,
  AlertTriangle,
  Settings,
  Repeat,
  Timer,
  Send,
  CalendarCheck,
  Star,
  UserPlus,
  Receipt,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { useAutomations, type AutomationData } from '@/lib/hooks/use-automations';

type AutomationStatus = 'active' | 'paused' | 'draft';
type TriggerType = 'job_status' | 'invoice_overdue' | 'lead_idle' | 'time_based' | 'customer_event' | 'bid_event';
type ActionType = 'send_email' | 'send_sms' | 'create_task' | 'notify_team' | 'update_status' | 'create_followup';

interface AutomationAction {
  type: ActionType;
  label: string;
  config: Record<string, string>;
}

interface Automation {
  id: string;
  name: string;
  description: string;
  status: AutomationStatus;
  trigger: {
    type: TriggerType;
    label: string;
    condition: string;
  };
  delay?: string;
  actions: AutomationAction[];
  lastRun?: Date;
  runCount: number;
  createdAt: Date;
}

const statusConfig: Record<AutomationStatus, { label: string; color: string; bgColor: string; icon: typeof Zap }> = {
  active: { label: 'Active', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30', icon: Zap },
  paused: { label: 'Paused', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30', icon: Pause },
  draft: { label: 'Draft', color: 'text-zinc-700 dark:text-zinc-300', bgColor: 'bg-zinc-100 dark:bg-zinc-900/30', icon: FileText },
};

const triggerConfig: Record<TriggerType, { label: string; icon: typeof Briefcase; color: string }> = {
  job_status: { label: 'Job Status Change', icon: Briefcase, color: 'text-blue-600 dark:text-blue-400' },
  invoice_overdue: { label: 'Invoice Overdue', icon: Receipt, color: 'text-red-600 dark:text-red-400' },
  lead_idle: { label: 'Lead Idle', icon: UserPlus, color: 'text-amber-600 dark:text-amber-400' },
  time_based: { label: 'Scheduled', icon: Timer, color: 'text-purple-600 dark:text-purple-400' },
  customer_event: { label: 'Customer Event', icon: Users, color: 'text-cyan-600 dark:text-cyan-400' },
  bid_event: { label: 'Bid Event', icon: FileText, color: 'text-indigo-600 dark:text-indigo-400' },
};

const actionConfig: Record<ActionType, { label: string; icon: typeof Mail }> = {
  send_email: { label: 'Send Email', icon: Mail },
  send_sms: { label: 'Send SMS', icon: MessageSquare },
  create_task: { label: 'Create Task', icon: CalendarCheck },
  notify_team: { label: 'Notify Team', icon: Bell },
  update_status: { label: 'Update Status', icon: CheckCircle },
  create_followup: { label: 'Create Follow-up', icon: Star },
};

const mockAutomations: Automation[] = [
  {
    id: 'a1',
    name: 'Job Complete → Review Request',
    description: 'Send a review request email 3 days after a job is marked complete',
    status: 'active',
    trigger: { type: 'job_status', label: 'Job marked as Complete', condition: 'status = complete' },
    delay: '3 days',
    actions: [
      { type: 'send_email', label: 'Send review request email', config: { template: 'review_request', to: 'customer' } },
    ],
    lastRun: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    runCount: 47,
    createdAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a2',
    name: 'Invoice 30 Days Overdue → Reminder',
    description: 'Send payment reminder when invoice is 30 days past due',
    status: 'active',
    trigger: { type: 'invoice_overdue', label: 'Invoice unpaid for 30 days', condition: 'days_overdue >= 30' },
    actions: [
      { type: 'send_email', label: 'Send payment reminder email', config: { template: 'payment_reminder', to: 'customer' } },
      { type: 'notify_team', label: 'Alert office manager', config: { role: 'office_manager' } },
    ],
    lastRun: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    runCount: 23,
    createdAt: new Date(Date.now() - 120 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a3',
    name: 'Lead Untouched 48hrs → Alert',
    description: 'Alert sales team when a new lead has no activity for 48 hours',
    status: 'active',
    trigger: { type: 'lead_idle', label: 'Lead idle for 48 hours', condition: 'last_activity > 48h' },
    actions: [
      { type: 'notify_team', label: 'Alert assigned salesperson', config: { role: 'assigned' } },
      { type: 'send_sms', label: 'SMS to sales manager', config: { to: 'sales_manager' } },
    ],
    lastRun: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    runCount: 56,
    createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a4',
    name: 'Bid Accepted → Create Job',
    description: 'Automatically create a job when a bid is accepted by the customer',
    status: 'active',
    trigger: { type: 'bid_event', label: 'Bid status changed to Accepted', condition: 'status = accepted' },
    actions: [
      { type: 'update_status', label: 'Create job from bid', config: { action: 'create_job' } },
      { type: 'notify_team', label: 'Notify project manager', config: { role: 'project_manager' } },
      { type: 'send_email', label: 'Send confirmation to customer', config: { template: 'bid_accepted', to: 'customer' } },
    ],
    lastRun: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    runCount: 18,
    createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a5',
    name: 'New Customer → Welcome Sequence',
    description: 'Send welcome email and create onboarding task for new customers',
    status: 'active',
    trigger: { type: 'customer_event', label: 'New customer created', condition: 'event = created' },
    actions: [
      { type: 'send_email', label: 'Send welcome email', config: { template: 'welcome', to: 'customer' } },
      { type: 'create_task', label: 'Create onboarding checklist', config: { template: 'onboarding' } },
    ],
    lastRun: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    runCount: 31,
    createdAt: new Date(Date.now() - 100 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a6',
    name: 'Weekly Job Report',
    description: 'Send weekly summary of all active jobs to the owner every Monday at 8 AM',
    status: 'active',
    trigger: { type: 'time_based', label: 'Every Monday at 8:00 AM', condition: 'cron: 0 8 * * 1' },
    actions: [
      { type: 'send_email', label: 'Send weekly job report', config: { template: 'weekly_report', to: 'owner' } },
    ],
    lastRun: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    runCount: 14,
    createdAt: new Date(Date.now() - 100 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a7',
    name: 'Invoice 60 Days → Collections Notice',
    description: 'Send formal collections notice for invoices 60+ days overdue',
    status: 'paused',
    trigger: { type: 'invoice_overdue', label: 'Invoice unpaid for 60 days', condition: 'days_overdue >= 60' },
    actions: [
      { type: 'send_email', label: 'Send collections notice', config: { template: 'collections', to: 'customer' } },
      { type: 'create_task', label: 'Create collections follow-up task', config: { template: 'collections_followup' } },
      { type: 'notify_team', label: 'Alert owner', config: { role: 'owner' } },
    ],
    lastRun: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    runCount: 5,
    createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a8',
    name: 'Warranty Expiring → Renewal Offer',
    description: 'Send renewal offer 30 days before warranty expires',
    status: 'draft',
    trigger: { type: 'time_based', label: 'Warranty expiring in 30 days', condition: 'warranty_days_remaining <= 30' },
    delay: 'immediate',
    actions: [
      { type: 'send_email', label: 'Send warranty renewal offer', config: { template: 'warranty_renewal', to: 'customer' } },
      { type: 'create_followup', label: 'Schedule follow-up call', config: { days: '7' } },
    ],
    runCount: 0,
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
  },
  {
    id: 'a9',
    name: 'Permit Approved → Notify Crew',
    description: 'When a permit is approved, notify the assigned crew to schedule the work',
    status: 'active',
    trigger: { type: 'job_status', label: 'Permit status changed to Approved', condition: 'permit_status = approved' },
    actions: [
      { type: 'notify_team', label: 'Notify assigned crew lead', config: { role: 'crew_lead' } },
      { type: 'send_sms', label: 'SMS crew members', config: { to: 'assigned_crew' } },
      { type: 'create_task', label: 'Schedule job start', config: { template: 'schedule_start' } },
    ],
    lastRun: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
    runCount: 12,
    createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
  },
];

function toAutomation(d: AutomationData): Automation {
  const triggerLabel = d.triggerConfig?.label as string || d.triggerConfig?.condition as string || d.triggerType;
  const triggerCondition = d.triggerConfig?.condition as string || '';
  return {
    id: d.id,
    name: d.name,
    description: d.description || '',
    status: d.status as AutomationStatus,
    trigger: {
      type: d.triggerType as TriggerType,
      label: triggerLabel,
      condition: triggerCondition,
    },
    delay: d.delayMinutes > 0 ? `${d.delayMinutes} min` : undefined,
    actions: d.actions.map(a => ({ type: a.type, label: a.label, config: a.config })),
    lastRun: d.lastRunAt ? new Date(d.lastRunAt) : undefined,
    runCount: d.runCount,
    createdAt: new Date(d.createdAt),
  };
}

export default function AutomationsPage() {
  const { automations: rawAutomations, loading } = useAutomations();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [triggerFilter, setTriggerFilter] = useState('all');
  const [selectedAutomation, setSelectedAutomation] = useState<Automation | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);

  const allAutomations = rawAutomations.map(toAutomation);

  const filteredAutomations = allAutomations.filter((a) => {
    const matchesSearch =
      a.name.toLowerCase().includes(search.toLowerCase()) ||
      a.description.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || a.status === statusFilter;
    const matchesTrigger = triggerFilter === 'all' || a.trigger.type === triggerFilter;
    return matchesSearch && matchesStatus && matchesTrigger;
  });

  const activeCount = allAutomations.filter((a) => a.status === 'active').length;
  const pausedCount = allAutomations.filter((a) => a.status === 'paused').length;
  const totalExecutions = allAutomations.reduce((sum, a) => sum + a.runCount, 0);
  const draftCount = allAutomations.filter((a) => a.status === 'draft').length;

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Automations</h1>
          <p className="text-muted mt-1">Automate repetitive tasks with trigger-based workflows</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          New Automation
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Zap size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeCount}</p>
                <p className="text-sm text-muted">Active</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Pause size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{pausedCount}</p>
                <p className="text-sm text-muted">Paused</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Repeat size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalExecutions}</p>
                <p className="text-sm text-muted">Total Runs</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-zinc-100 dark:bg-zinc-900/30 rounded-lg">
                <FileText size={20} className="text-zinc-600 dark:text-zinc-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{draftCount}</p>
                <p className="text-sm text-muted">Drafts</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search automations..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'active', label: 'Active' },
            { value: 'paused', label: 'Paused' },
            { value: 'draft', label: 'Draft' },
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[
            { value: 'all', label: 'All Triggers' },
            { value: 'job_status', label: 'Job Status' },
            { value: 'invoice_overdue', label: 'Invoice Overdue' },
            { value: 'lead_idle', label: 'Lead Idle' },
            { value: 'time_based', label: 'Scheduled' },
            { value: 'customer_event', label: 'Customer Event' },
            { value: 'bid_event', label: 'Bid Event' },
          ]}
          value={triggerFilter}
          onChange={(e) => setTriggerFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Automations List */}
      <div className="space-y-3">
        {filteredAutomations.map((automation) => {
          const sConfig = statusConfig[automation.status];
          const tConfig = triggerConfig[automation.trigger.type];
          const StatusIcon = sConfig.icon;
          const TriggerIcon = tConfig.icon;

          return (
            <Card key={automation.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => setSelectedAutomation(automation)}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={cn('p-2.5 rounded-lg', sConfig.bgColor)}>
                      <StatusIcon size={22} className={sConfig.color} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-main">{automation.name}</h3>
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                          {sConfig.label}
                        </span>
                      </div>
                      <p className="text-sm text-muted mb-3">{automation.description}</p>
                      {/* Workflow Visual */}
                      <div className="flex items-center gap-2 flex-wrap">
                        <div className="flex items-center gap-1.5 px-2.5 py-1 bg-secondary rounded-md">
                          <TriggerIcon size={14} className={tConfig.color} />
                          <span className="text-xs font-medium text-main">{automation.trigger.label}</span>
                        </div>
                        {automation.delay && (
                          <>
                            <ArrowRight size={14} className="text-muted" />
                            <div className="flex items-center gap-1.5 px-2.5 py-1 bg-secondary rounded-md">
                              <Clock size={14} className="text-muted" />
                              <span className="text-xs text-muted">Wait {automation.delay}</span>
                            </div>
                          </>
                        )}
                        {automation.actions.map((action, i) => {
                          const aConfig = actionConfig[action.type];
                          const ActionIcon = aConfig.icon;
                          return (
                            <span key={i} className="contents">
                              <ArrowRight size={14} className="text-muted" />
                              <div className="flex items-center gap-1.5 px-2.5 py-1 bg-secondary rounded-md">
                                <ActionIcon size={14} className="text-muted" />
                                <span className="text-xs text-main">{action.label}</span>
                              </div>
                            </span>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 ml-4">
                    <p className="text-sm font-medium text-main">{automation.runCount} runs</p>
                    {automation.lastRun && (
                      <p className="text-xs text-muted mt-1">Last: {formatDate(automation.lastRun)}</p>
                    )}
                    <p className="text-xs text-muted mt-1">Created {formatDate(automation.createdAt)}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}

        {filteredAutomations.length === 0 && (
          <Card>
            <CardContent className="p-12 text-center">
              <Zap size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">No automations found</h3>
              <p className="text-muted mb-4">Create workflow automations to save time on repetitive tasks.</p>
              <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Automation</Button>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Modals */}
      {selectedAutomation && <AutomationDetailModal automation={selectedAutomation} onClose={() => setSelectedAutomation(null)} />}
      {showNewModal && <NewAutomationModal onClose={() => setShowNewModal(false)} />}
    </div>
  );
}

function AutomationDetailModal({ automation, onClose }: { automation: Automation; onClose: () => void }) {
  const sConfig = statusConfig[automation.status];
  const tConfig = triggerConfig[automation.trigger.type];
  const TriggerIcon = tConfig.icon;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Automation Details</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><ZapOff size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <h3 className="font-medium text-main text-lg">{automation.name}</h3>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>
                {sConfig.label}
              </span>
            </div>
            <p className="text-sm text-muted">{automation.description}</p>
          </div>

          {/* Trigger */}
          <div className="p-4 bg-secondary rounded-lg">
            <p className="text-xs text-muted uppercase tracking-wider mb-2">When this happens...</p>
            <div className="flex items-center gap-2">
              <TriggerIcon size={18} className={tConfig.color} />
              <span className="font-medium text-main">{automation.trigger.label}</span>
            </div>
            <p className="text-xs text-muted mt-1 ml-7">Condition: {automation.trigger.condition}</p>
          </div>

          {/* Delay */}
          {automation.delay && (
            <div className="flex items-center gap-3 px-4">
              <div className="w-px h-8 bg-main ml-2" />
              <Clock size={16} className="text-muted" />
              <span className="text-sm text-muted">Wait {automation.delay}</span>
            </div>
          )}

          {/* Actions */}
          <div className="space-y-2">
            <p className="text-xs text-muted uppercase tracking-wider">Then do this...</p>
            {automation.actions.map((action, i) => {
              const aConfig = actionConfig[action.type];
              const ActionIcon = aConfig.icon;
              return (
                <div key={i} className="flex items-center gap-3 p-3 bg-secondary rounded-lg">
                  <div className="p-1.5 bg-main rounded">
                    <ActionIcon size={14} className="text-muted" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-main">{action.label}</p>
                    <p className="text-xs text-muted">{aConfig.label}</p>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 p-4 bg-secondary rounded-lg">
            <div>
              <p className="text-xs text-muted uppercase tracking-wider">Total Runs</p>
              <p className="text-lg font-semibold text-main">{automation.runCount}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wider">Last Run</p>
              <p className="text-sm font-medium text-main">{automation.lastRun ? formatDate(automation.lastRun) : 'Never'}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wider">Created</p>
              <p className="text-sm font-medium text-main">{formatDate(automation.createdAt)}</p>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
            {automation.status === 'active' ? (
              <Button variant="secondary" className="flex-1"><Pause size={16} />Pause</Button>
            ) : (
              <Button className="flex-1"><Play size={16} />Activate</Button>
            )}
            <Button className="flex-1"><Settings size={16} />Edit</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewAutomationModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>New Automation</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Name *</label>
            <input type="text" placeholder="e.g., Job Complete → Review Request" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description</label>
            <textarea rows={2} placeholder="What does this automation do?" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Trigger *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">Select trigger...</option>
              <option value="job_status">Job Status Change</option>
              <option value="invoice_overdue">Invoice Overdue</option>
              <option value="lead_idle">Lead Idle</option>
              <option value="time_based">Scheduled (Time-Based)</option>
              <option value="customer_event">Customer Event</option>
              <option value="bid_event">Bid Event</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Condition</label>
            <input type="text" placeholder="e.g., status = complete" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Delay (optional)</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">No delay (immediate)</option>
              <option value="1h">1 hour</option>
              <option value="24h">24 hours</option>
              <option value="3d">3 days</option>
              <option value="7d">7 days</option>
              <option value="30d">30 days</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Action *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">Select action...</option>
              <option value="send_email">Send Email</option>
              <option value="send_sms">Send SMS</option>
              <option value="create_task">Create Task</option>
              <option value="notify_team">Notify Team</option>
              <option value="update_status">Update Status</option>
              <option value="create_followup">Create Follow-up</option>
            </select>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Create Automation</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
