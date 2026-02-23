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
import { useTranslation } from '@/lib/translations';
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

// Delay label helper
const delayLabels: Record<string, string> = {
  '0': 'No delay',
  '60': '1 hour',
  '1440': '24 hours',
  '4320': '3 days',
  '10080': '7 days',
  '43200': '30 days',
};

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
  const { t } = useTranslation();
  const { automations: rawAutomations, loading, createAutomation, updateAutomation, deleteAutomation, toggleAutomation } = useAutomations();
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

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div><div className="skeleton h-7 w-44 mb-2" /><div className="skeleton h-4 w-72" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => (
            <Card key={i}><CardContent className="p-4"><div className="skeleton h-3 w-20 mb-3" /><div className="skeleton h-7 w-16" /></CardContent></Card>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1"><div className="skeleton h-4 w-48 mb-2" /><div className="skeleton h-3 w-36" /></div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('automations.title')}</h1>
          <p className="text-muted mt-1">{t('automations.automateRepetitiveTasksWithTriggerbasedWorkflows')}</p>
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
                <p className="text-sm text-muted">{t('common.active')}</p>
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
                <p className="text-sm text-muted">{t('common.paused')}</p>
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
                <p className="text-sm text-muted">{t('common.totalRuns')}</p>
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
                <p className="text-sm text-muted">{t('email.drafts')}</p>
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
              <h3 className="text-lg font-medium text-main mb-2">{t('automations.noRecords')}</h3>
              <p className="text-muted mb-4">{t('automations.createWorkflowAutomationsToSaveTimeOnRepetitiveTas')}</p>
              <Button onClick={() => setShowNewModal(true)}><Plus size={16} />{t('common.newAutomation')}</Button>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Modals */}
      {selectedAutomation && (
        <AutomationDetailModal
          automation={selectedAutomation}
          onClose={() => setSelectedAutomation(null)}
          onToggle={async () => {
            const isActive = selectedAutomation.status === 'active';
            await toggleAutomation(selectedAutomation.id, !isActive);
            setSelectedAutomation(null);
          }}
          onDelete={async () => {
            await deleteAutomation(selectedAutomation.id);
            setSelectedAutomation(null);
          }}
        />
      )}
      {showNewModal && (
        <NewAutomationModal
          onClose={() => setShowNewModal(false)}
          onCreate={async (data) => {
            await createAutomation(data);
            setShowNewModal(false);
          }}
        />
      )}
    </div>
  );
}

function AutomationDetailModal({ automation, onClose, onToggle, onDelete }: {
  automation: Automation;
  onClose: () => void;
  onToggle: () => Promise<void>;
  onDelete: () => Promise<void>;
}) {
  const { t } = useTranslation();
  const [busy, setBusy] = useState(false);
  const sConfig = statusConfig[automation.status];
  const tConfig = triggerConfig[automation.trigger.type];
  const TriggerIcon = tConfig.icon;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>{t('automations.automationDetails')}</CardTitle>
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
            <p className="text-xs text-muted uppercase tracking-wider mb-2">{t('automations.whenThisHappens')}</p>
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
            <p className="text-xs text-muted uppercase tracking-wider">{t('automations.thenDoThis')}</p>
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
              <p className="text-xs text-muted uppercase tracking-wider">{t('common.totalRuns')}</p>
              <p className="text-lg font-semibold text-main">{automation.runCount}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wider">{t('automations.lastRun')}</p>
              <p className="text-sm font-medium text-main">{automation.lastRun ? formatDate(automation.lastRun) : 'Never'}</p>
            </div>
            <div>
              <p className="text-xs text-muted uppercase tracking-wider">{t('common.created')}</p>
              <p className="text-sm font-medium text-main">{formatDate(automation.createdAt)}</p>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.close')}</Button>
            {automation.status === 'active' ? (
              <Button variant="secondary" className="flex-1" disabled={busy} onClick={async () => { setBusy(true); await onToggle(); }}>
                <Pause size={16} />Pause
              </Button>
            ) : (
              <Button className="flex-1" disabled={busy} onClick={async () => { setBusy(true); await onToggle(); }}>
                <Play size={16} />Activate
              </Button>
            )}
            <Button variant="secondary" className="flex-1 text-red-600 hover:text-red-700" disabled={busy} onClick={async () => { setBusy(true); await onDelete(); }}>
              <ZapOff size={16} />Delete
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewAutomationModal({ onClose, onCreate }: { onClose: () => void; onCreate: (data: Partial<AutomationData>) => Promise<void> }) {
  const { t } = useTranslation();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [triggerType, setTriggerType] = useState('');
  const [condition, setCondition] = useState('');
  const [delayMinutes, setDelayMinutes] = useState('0');
  const [actionType, setActionType] = useState('');
  const [busy, setBusy] = useState(false);

  const canCreate = name.trim() && triggerType && actionType;

  const handleCreate = async () => {
    if (!canCreate) return;
    setBusy(true);
    try {
      await onCreate({
        name: name.trim(),
        description: description.trim() || null,
        status: 'draft' as AutomationStatus,
        triggerType: triggerType as TriggerType,
        triggerConfig: condition ? { condition, label: condition } : {},
        delayMinutes: Number(delayMinutes) || 0,
        actions: [{
          type: actionType as ActionType,
          label: actionConfig[actionType as ActionType]?.label || actionType,
          config: {},
        }],
      });
    } catch (err) {
      console.error('Failed to create automation:', err);
      setBusy(false);
    }
  };

  const inputCls = 'w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent';

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{t('common.newAutomation')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Name *</label>
            <input type="text" value={name} onChange={e => setName(e.target.value)} placeholder="e.g., Job Complete -> Review Request" className={inputCls} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.description')}</label>
            <textarea rows={2} value={description} onChange={e => setDescription(e.target.value)} placeholder="What does this automation do?" className={cn(inputCls, 'resize-none')} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Trigger *</label>
            <select value={triggerType} onChange={e => setTriggerType(e.target.value)} className={inputCls}>
              <option value="">{t('automations.selectTrigger')}</option>
              <option value="job_status">{t('automations.jobStatusChange')}</option>
              <option value="invoice_overdue">{t('automations.invoiceOverdue')}</option>
              <option value="lead_idle">{t('automations.leadIdle')}</option>
              <option value="time_based">Scheduled (Time-Based)</option>
              <option value="customer_event">{t('automations.customerEvent')}</option>
              <option value="bid_event">{t('automations.bidEvent')}</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.condition')}</label>
            <input type="text" value={condition} onChange={e => setCondition(e.target.value)} placeholder="e.g., status = complete" className={inputCls} />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Delay (optional)</label>
            <select value={delayMinutes} onChange={e => setDelayMinutes(e.target.value)} className={inputCls}>
              <option value="0">No delay (immediate)</option>
              <option value="60">1 hour</option>
              <option value="1440">24 hours</option>
              <option value="4320">3 days</option>
              <option value="10080">7 days</option>
              <option value="43200">30 days</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Action *</label>
            <select value={actionType} onChange={e => setActionType(e.target.value)} className={inputCls}>
              <option value="">{t('automations.selectAction')}</option>
              <option value="send_email">{t('automations.sendEmail')}</option>
              <option value="send_sms">{t('automations.sendSms')}</option>
              <option value="create_task">{t('automations.createTask')}</option>
              <option value="notify_team">{t('automations.notifyTeam')}</option>
              <option value="update_status">{t('automations.updateStatus')}</option>
              <option value="create_followup">{t('automations.createFollowup')}</option>
            </select>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" disabled={!canCreate || busy} onClick={handleCreate}>
              <Plus size={16} />{busy ? 'Creating...' : 'Create Automation'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
