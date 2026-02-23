'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Briefcase,
  MapPin,
  Calendar,
  Clock,
  User,
  Phone,
  Mail,
  DollarSign,
  FileText,
  Camera,
  MessageSquare,
  CheckSquare,
  Edit,
  MoreHorizontal,
  Trash2,
  Receipt,
  PlayCircle,
  PauseCircle,
  CheckCircle,
  Plus,
  Package,
  Shield,
  Satellite,
  Ruler,
  AlertTriangle,
  GanttChart,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { StatusBadge, Badge } from '@/components/ui/badge';
import { Avatar, AvatarGroup } from '@/components/ui/avatar';
import { formatDate, formatDateTime, cn } from '@/lib/utils';
import { useJob, useTeam } from '@/lib/hooks/use-jobs';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useClaimByJob } from '@/lib/hooks/use-insurance';
import { usePropertyScan } from '@/lib/hooks/use-property-scan';
import { useLeadScore } from '@/lib/hooks/use-area-scan';
import { useJobSchedule } from '@/lib/hooks/use-job-schedule';
import { JOB_TYPE_LABELS, JOB_TYPE_COLORS } from '@/lib/hooks/mappers';
import { MiniGantt } from '@/components/scheduling/MiniGantt';
import { usePhotos } from '@/lib/hooks/use-photos';
import { useEstimates } from '@/lib/hooks/use-estimates';
import { useDocuments } from '@/lib/hooks/use-documents';
import { useChangeOrders } from '@/lib/hooks/use-change-orders';
import { usePermits } from '@/lib/hooks/use-permits';
import { useDailyLogs } from '@/lib/hooks/use-daily-logs';
import type { Job, JobType, InsuranceMetadata, WarrantyMetadata, PaymentSource } from '@/types';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

type TabType = 'overview' | 'tasks' | 'materials' | 'photos' | 'time' | 'notes' | 'estimates' | 'invoices' | 'documents' | 'changes' | 'permits' | 'logs';

export default function JobDetailPage() {
  const { t, formatDate } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const jobId = params.id as string;

  const { job, loading } = useJob(jobId);
  const { team } = useTeam();
  const { createInvoiceFromJob } = useInvoices();
  const { schedule, tasks: scheduleTasks } = useJobSchedule(jobId);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [menuOpen, setMenuOpen] = useState(false);
  const [completing, setCompleting] = useState(false);

  const handleComplete = async () => {
    if (completing || !job) return;
    setCompleting(true);
    try {
      const supabase = getSupabase();
      await supabase.from('jobs').update({ status: 'completed', completed_at: new Date().toISOString() }).eq('id', jobId);

      // Prompt to auto-generate invoice
      const shouldInvoice = window.confirm(
        'Job marked as completed. Would you like to generate a draft invoice for this job?'
      );
      if (shouldInvoice) {
        const invoiceId = await createInvoiceFromJob(jobId);
        if (invoiceId) {
          router.push(`/dashboard/invoices/${invoiceId}`);
          return;
        }
      }
      // Refresh page
      router.refresh();
    } catch {
      // Error silenced — job may still update via DB
    } finally {
      setCompleting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (!job) {
    return (
      <div className="text-center py-12">
        <Briefcase size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">{t('jobs.jobNotFound')}</h2>
        <p className="text-muted mt-2">{t('jobs.jobDoesntExist')}</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/jobs')}>
          Back to Jobs
        </Button>
      </div>
    );
  }

  const assignedMembers = job.assignedTo.map((id) => team.find((t) => t.id === id)).filter(Boolean);

  const tabs: { id: TabType; label: string; icon: React.ReactNode }[] = [
    { id: 'overview', label: t('common.overview'), icon: <Briefcase size={16} /> },
    { id: 'tasks', label: t('common.tasks'), icon: <CheckSquare size={16} /> },
    { id: 'estimates', label: t('estimates.title'), icon: <FileText size={16} /> },
    { id: 'invoices', label: t('invoices.title'), icon: <Receipt size={16} /> },
    { id: 'materials', label: t('common.materials'), icon: <Package size={16} /> },
    { id: 'documents', label: t('common.documents'), icon: <FileText size={16} /> },
    { id: 'changes', label: t('changeOrders.title'), icon: <Edit size={16} /> },
    { id: 'permits', label: t('permits.title'), icon: <Shield size={16} /> },
    { id: 'photos', label: t('common.photos'), icon: <Camera size={16} /> },
    { id: 'time', label: t('common.time'), icon: <Clock size={16} /> },
    { id: 'logs', label: t('common.dailyLogs'), icon: <Calendar size={16} /> },
    { id: 'notes', label: t('common.notes'), icon: <MessageSquare size={16} /> },
  ];

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.back()}
            className="p-2 hover:bg-surface-hover rounded-lg transition-colors"
          >
            <ArrowLeft size={20} className="text-muted" />
          </button>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-semibold text-main">{job.title}</h1>
              <StatusBadge status={job.status} />
              {job.jobType !== 'standard' && (
                <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', JOB_TYPE_COLORS[job.jobType].bg, JOB_TYPE_COLORS[job.jobType].text)}>
                  <span className={cn('w-1.5 h-1.5 rounded-full', JOB_TYPE_COLORS[job.jobType].dot)} />
                  {JOB_TYPE_LABELS[job.jobType]}
                </span>
              )}
              {job.priority === 'urgent' && <Badge variant="error">{t('common.urgent')}</Badge>}
              {job.priority === 'high' && <Badge variant="warning">{t('common.high')}</Badge>}
            </div>
            <p className="text-muted mt-1">
              {job.customer?.firstName} {job.customer?.lastName}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {job.status === 'scheduled' && (
            <Button>
              <PlayCircle size={16} />
              Start Job
            </Button>
          )}
          {job.status === 'in_progress' && (
            <>
              <Button variant="secondary">
                <PauseCircle size={16} />
                Pause
              </Button>
              <Button onClick={handleComplete} disabled={completing}>
                <CheckCircle size={16} />
                {completing ? 'Completing...' : 'Complete'}
              </Button>
            </>
          )}
          {job.status === 'completed' && (
            <Button onClick={() => router.push(`/dashboard/invoices/new?jobId=${job.id}`)}>
              <Receipt size={16} />
              Create Invoice
            </Button>
          )}
          <div className="relative">
            <Button variant="ghost" size="icon" onClick={() => setMenuOpen(!menuOpen)}>
              <MoreHorizontal size={18} />
            </Button>
            {menuOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setMenuOpen(false)} />
                <div className="absolute right-0 top-full mt-1 w-48 bg-surface border border-main rounded-lg shadow-lg py-1 z-50">
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <Edit size={16} />
                    Edit Job
                  </button>
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2">
                    <FileText size={16} />
                    View Bid
                  </button>
                  <hr className="my-1 border-main" />
                  <button className="w-full px-4 py-2 text-left text-sm hover:bg-red-50 dark:hover:bg-red-900/20 text-red-600 flex items-center gap-2">
                    <Trash2 size={16} />
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={cn(
              'flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-md transition-colors',
              activeTab === tab.id
                ? 'bg-surface text-main shadow-sm'
                : 'text-muted hover:text-main'
            )}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {activeTab === 'overview' && <OverviewTab job={job} />}
          {activeTab === 'tasks' && <TasksTab job={job} />}
          {activeTab === 'estimates' && <EstimatesTab jobId={job.id} />}
          {activeTab === 'invoices' && <InvoicesTab jobId={job.id} />}
          {activeTab === 'materials' && <MaterialsTab job={job} />}
          {activeTab === 'documents' && <DocumentsTab jobId={job.id} />}
          {activeTab === 'changes' && <ChangeOrdersTab jobId={job.id} />}
          {activeTab === 'permits' && <PermitsTab jobId={job.id} />}
          {activeTab === 'photos' && <PhotosTab job={job} />}
          {activeTab === 'time' && <TimeTab job={job} />}
          {activeTab === 'logs' && <DailyLogsTab jobId={job.id} />}
          {activeTab === 'notes' && <NotesTab job={job} />}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Job Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">{t('common.details')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm text-muted mb-1">{t('common.value')}</p>
                <p className="text-2xl font-semibold text-main">{formatCurrency(job.estimatedValue)}</p>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.type')}</span>
                <span className={cn('inline-flex items-center gap-1.5 px-2 py-0.5 text-xs font-medium rounded-full', JOB_TYPE_COLORS[job.jobType].bg, JOB_TYPE_COLORS[job.jobType].text)}>
                  {JOB_TYPE_LABELS[job.jobType]}
                </span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.status')}</span>
                <StatusBadge status={job.status} />
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.priority')}</span>
                <Badge variant={job.priority === 'urgent' ? 'error' : job.priority === 'high' ? 'warning' : 'default'}>
                  {job.priority.charAt(0).toUpperCase() + job.priority.slice(1)}
                </Badge>
              </div>
              {job.scheduledStart && (
                <div className="flex justify-between text-sm">
                  <span className="text-muted">{t('common.scheduled')}</span>
                  <span className="text-main">{formatDate(job.scheduledStart)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm">
                <span className="text-muted">{t('common.createdAt')}</span>
                <span className="text-main">{formatDate(job.createdAt)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Type Metadata */}
          {job.jobType !== 'standard' && job.typeMetadata && Object.keys(job.typeMetadata).length > 0 && (
            <TypeMetadataCard job={job} />
          )}

          {/* Upgrade Tracking Summary — insurance/warranty jobs only */}
          {(job.jobType === 'insurance_claim' || job.jobType === 'warranty_dispatch') && (
            <UpgradeTrackingSummary jobId={job.id} />
          )}

          {/* Customer */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Customer
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="font-medium text-main">
                {job.customer?.firstName} {job.customer?.lastName}
              </div>
              {job.customer?.email && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Mail size={14} />
                  <a href={`mailto:${job.customer.email}`} className="hover:text-accent">
                    {job.customer.email}
                  </a>
                </div>
              )}
              {job.customer?.phone && (
                <div className="flex items-center gap-2 text-sm text-muted">
                  <Phone size={14} />
                  <a href={`tel:${job.customer.phone}`} className="hover:text-accent">
                    {job.customer.phone}
                  </a>
                </div>
              )}
              <Button variant="secondary" size="sm" className="w-full" onClick={() => router.push(`/dashboard/customers/${job.customerId}`)}>
                View Customer
              </Button>
            </CardContent>
          </Card>

          {/* Location */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <MapPin size={18} className="text-muted" />
                Location
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-main">
                {job.address.street}<br />
                {job.address.city}, {job.address.state} {job.address.zip}
              </p>
              <Button variant="secondary" size="sm" className="w-full mt-3">
                Get Directions
              </Button>
            </CardContent>
          </Card>

          {/* Schedule */}
          {schedule && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base flex items-center gap-2">
                  <GanttChart size={18} className="text-muted" />
                  Schedule
                  <span className="ml-auto text-sm font-semibold text-accent">{schedule.overall_percent_complete?.toFixed(0) || 0}%</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="mb-3 h-1.5 bg-surface-alt rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-accent transition-all" style={{ width: `${Math.min(schedule.overall_percent_complete || 0, 100)}%` }} />
                </div>
                <MiniGantt
                  tasks={scheduleTasks.map((t) => ({
                    id: t.id,
                    name: t.name,
                    start: t.early_start || t.planned_start,
                    finish: t.early_finish || t.planned_finish,
                    percent_complete: t.percent_complete || 0,
                    is_critical: t.is_critical || false,
                    is_milestone: t.task_type === 'milestone',
                  }))}
                  height={100}
                  onClick={() => router.push(`/dashboard/scheduling/${schedule.id}`)}
                />
                <button
                  onClick={() => router.push(`/dashboard/scheduling/${schedule.id}`)}
                  className="flex items-center justify-center gap-1 w-full mt-3 text-sm font-medium text-accent hover:text-accent/80 transition-colors"
                >
                  View Full Schedule
                  <ChevronRight size={14} />
                </button>
              </CardContent>
            </Card>
          )}

          {/* Property Intelligence */}
          <PropertyIntelligenceCard job={job} />

          {/* Team */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base flex items-center gap-2">
                <User size={18} className="text-muted" />
                Assigned Team
              </CardTitle>
            </CardHeader>
            <CardContent>
              {assignedMembers.length === 0 ? (
                <p className="text-sm text-muted">{t('jobs.noTeamMembersAssigned')}</p>
              ) : (
                <div className="space-y-3">
                  {assignedMembers.map((member) => member && (
                    <div key={member.id} className="flex items-center gap-3">
                      <Avatar name={member.name} size="sm" />
                      <div>
                        <p className="text-sm font-medium text-main">{member.name}</p>
                        <p className="text-xs text-muted capitalize">{member.role.replace('_', ' ')}</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
              <Button variant="secondary" size="sm" className="w-full mt-3">
                <Plus size={14} />
                Assign Member
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}

function OverviewTab({ job }: { job: Job }) {
  const { t } = useTranslation();
  return (
    <div className="space-y-6">
      {/* Description */}
      {job.description && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('common.description')}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-main whitespace-pre-wrap">{job.description}</p>
          </CardContent>
        </Card>
      )}

      {/* Timeline */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{t('common.timeline')}</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <TimelineItem
              label={t('common.createdAt')}
              date={job.createdAt}
              completed={true}
            />
            <TimelineItem
              label={t('jobs.statusScheduled')}
              date={job.scheduledStart}
              completed={!!job.scheduledStart}
            />
            <TimelineItem
              label={t('common.started')}
              date={job.actualStart}
              completed={!!job.actualStart}
            />
            <TimelineItem
              label={t('inspections.completed')}
              date={job.actualEnd}
              completed={job.status === 'completed' || job.status === 'invoiced' || job.status === 'paid'}
              isLast
            />
          </div>
        </CardContent>
      </Card>

      {/* Tags */}
      {job.tags.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">{t('common.tags')}</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {job.tags.map((tag) => (
                <Badge key={tag} variant="default">{tag}</Badge>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

function TimelineItem({ label, date, completed, isLast = false }: { label: string; date?: Date; completed: boolean; isLast?: boolean }) {
  return (
    <div className="flex gap-3">
      <div className="flex flex-col items-center">
        <div className={cn(
          'w-3 h-3 rounded-full',
          completed ? 'bg-emerald-500' : 'bg-secondary border-2 border-main'
        )} />
        {!isLast && <div className={cn('w-0.5 h-8 mt-1', completed ? 'bg-emerald-500' : 'bg-main')} />}
      </div>
      <div className="flex-1 pb-4">
        <div className={cn('font-medium text-sm', completed ? 'text-main' : 'text-muted')}>
          {label}
        </div>
        {date && (
          <div className="text-xs text-muted">{formatDateTime(date)}</div>
        )}
      </div>
    </div>
  );
}

function TasksTab({ job }: { job: Job }) {
  const { t: tr } = useTranslation();
  const [tasks, setTasks] = useState<{ id: string; name: string; percent_complete: number; task_type: string; is_critical: boolean }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const fetchTasks = async () => {
      try {
        const supabase = getSupabase();
        // Find schedule project for this job
        const { data: project } = await supabase
          .from('schedule_projects')
          .select('id')
          .eq('job_id', job.id)
          .neq('status', 'archived')
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();

        if (!project || cancelled) { setTasks([]); return; }

        const { data: taskData } = await supabase
          .from('schedule_tasks')
          .select('id, name, percent_complete, task_type, is_critical')
          .eq('project_id', project.id)
          .is('deleted_at', null)
          .order('sort_order', { ascending: true });

        if (!cancelled) setTasks(taskData || []);
      } catch {
        if (!cancelled) setTasks([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    fetchTasks();
    return () => { cancelled = true; };
  }, [job.id]);

  const completedCount = tasks.filter((t) => t.percent_complete >= 100).length;

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{tr('common.taskChecklist')}</CardTitle>
          {tasks.length > 0 && (
            <p className="text-xs text-muted mt-1">{completedCount}/{tasks.length} complete</p>
          )}
        </div>
        <Button variant="secondary" size="sm" onClick={() => window.location.href = `/dashboard/scheduling?jobId=${job.id}`}>
          <GanttChart size={14} />
          Manage Schedule
        </Button>
      </CardHeader>
      <CardContent>
        {tasks.length === 0 ? (
          <div className="text-center py-8">
            <CheckSquare size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{tr('common.noTasksYet')}</p>
            <p className="text-xs text-muted mt-1">{tr('jobs.createScheduleToAddTasks')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {tasks.map((task) => {
              const completed = task.percent_complete >= 100;
              return (
                <div
                  key={task.id}
                  className={cn(
                    'flex items-center gap-3 p-3 rounded-lg border transition-colors',
                    completed ? 'border-emerald-200 bg-emerald-50 dark:border-emerald-900 dark:bg-emerald-900/20' : 'border-main',
                    task.is_critical && !completed && 'border-red-300 dark:border-red-800'
                  )}
                >
                  <div className={cn(
                    'w-5 h-5 rounded border-2 flex items-center justify-center flex-shrink-0',
                    completed ? 'bg-emerald-500 border-emerald-500 text-white' : 'border-muted'
                  )}>
                    {completed && <CheckCircle size={14} />}
                  </div>
                  <span className={cn('flex-1 text-sm', completed && 'line-through text-muted')}>
                    {task.name}
                  </span>
                  {!completed && task.percent_complete > 0 && (
                    <span className="text-xs text-accent font-medium">{Math.round(task.percent_complete)}%</span>
                  )}
                  {task.is_critical && !completed && (
                    <AlertTriangle size={14} className="text-red-500 flex-shrink-0" />
                  )}
                </div>
              );
            })}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function MaterialsTab({ job }: { job: Job }) {
  const { t } = useTranslation();
  const [materials, setMaterials] = useState<{ id: string; name: string; category: string; quantity: number; unit: string; unit_cost: number; total_cost: number; is_billable: boolean }[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', category: 'general', quantity: '1', unit: 'ea', unit_cost: '' });
  const [saving, setSaving] = useState(false);

  const fetchMaterials = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('job_materials')
        .select('id, name, category, quantity, unit, unit_cost, total_cost, is_billable')
        .eq('job_id', job.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: true });

      setMaterials(data || []);
    } catch {
      setMaterials([]);
    } finally {
      setLoading(false);
    }
  }, [job.id]);

  useEffect(() => { fetchMaterials(); }, [fetchMaterials]);

  const handleAdd = async () => {
    if (!formData.name.trim()) return;
    setSaving(true);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      const qty = Number(formData.quantity) || 1;
      const unitCost = Number(formData.unit_cost) || 0;
      await supabase.from('job_materials').insert({
        job_id: job.id,
        company_id: user?.app_metadata?.company_id,
        name: formData.name.trim(),
        category: formData.category,
        quantity: qty,
        unit: formData.unit,
        unit_cost: unitCost,
        total_cost: qty * unitCost,
        is_billable: true,
      });
      setFormData({ name: '', category: 'general', quantity: '1', unit: 'ea', unit_cost: '' });
      setShowForm(false);
      await fetchMaterials();
    } catch {
      // silent
    } finally {
      setSaving(false);
    }
  };

  const totalCost = materials.reduce((sum, m) => sum + (Number(m.total_cost) || Number(m.unit_cost) * Number(m.quantity) || 0), 0);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('common.materials')}</CardTitle>
          {materials.length > 0 && (
            <p className="text-xs text-muted mt-1">{materials.length} items &middot; {formatCurrency(totalCost)} total</p>
          )}
        </div>
        <Button variant="secondary" size="sm" onClick={() => setShowForm(!showForm)}>
          <Plus size={14} />
          Add Material
        </Button>
      </CardHeader>

      {/* Add Material Form */}
      {showForm && (
        <CardContent className="border-b border-main pb-4">
          <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
            <div className="col-span-2">
              <Input
                label="Item Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="e.g. Copper pipe 3/4"
              />
            </div>
            <Input
              label={t('common.qty')}
              type="number"
              value={formData.quantity}
              onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
              min="0"
            />
            <Input
              label={t('common.unit')}
              value={formData.unit}
              onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
              placeholder="ea, ft, gal"
            />
            <Input
              label={t('jobs.materials.unitCost')}
              type="number"
              value={formData.unit_cost}
              onChange={(e) => setFormData({ ...formData, unit_cost: e.target.value })}
              placeholder="0.00"
              min="0"
              step="0.01"
            />
          </div>
          <div className="flex items-center gap-2 mt-3">
            <Button size="sm" onClick={handleAdd} disabled={saving || !formData.name.trim()}>
              {saving ? 'Adding...' : 'Add'}
            </Button>
            <Button variant="ghost" size="sm" onClick={() => setShowForm(false)}>{t('common.cancel')}</Button>
          </div>
        </CardContent>
      )}

      {materials.length === 0 && !showForm ? (
        <CardContent>
          <div className="text-center py-8">
            <Package size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('jobs.noMaterialsLogged')}</p>
            <p className="text-xs text-muted mt-1">{t('jobs.addMaterialsToTrackCosts')}</p>
          </div>
        </CardContent>
      ) : materials.length > 0 ? (
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.item')}</th>
                <th className="text-left text-xs font-medium text-muted uppercase px-6 py-3">{t('common.category')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.qty')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.unitCost')}</th>
                <th className="text-right text-xs font-medium text-muted uppercase px-6 py-3">{t('common.total')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {materials.map((item) => (
                <tr key={item.id}>
                  <td className="px-6 py-4 font-medium text-main">{item.name}</td>
                  <td className="px-6 py-4 text-muted capitalize text-sm">{item.category}</td>
                  <td className="px-6 py-4 text-right text-muted">{item.quantity} {item.unit}</td>
                  <td className="px-6 py-4 text-right text-muted">{formatCurrency(Number(item.unit_cost) || 0)}</td>
                  <td className="px-6 py-4 text-right font-medium text-main">{formatCurrency(Number(item.total_cost) || Number(item.unit_cost) * Number(item.quantity) || 0)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      ) : null}
    </Card>
  );
}

function PhotosTab({ job }: { job: Job }) {
  const { t } = useTranslation();
  const { photos, loading: photosLoading, refresh } = usePhotos(job.id);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  const handleUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setUploading(true);
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;
      const companyId = user.app_metadata?.company_id;

      for (const file of Array.from(files)) {
        const timestamp = Date.now();
        const storagePath = `${companyId}/jobs/${job.id}/${timestamp}_${file.name}`;
        const { error: uploadErr } = await supabase.storage
          .from('photos')
          .upload(storagePath, file, { contentType: file.type });
        if (uploadErr) continue;

        await supabase.from('photos').insert({
          company_id: companyId,
          job_id: job.id,
          uploaded_by_user_id: user.id,
          storage_path: storagePath,
          file_name: file.name,
          file_size: file.size,
          mime_type: file.type,
          category: 'general',
          caption: '',
          tags: [],
          is_client_visible: false,
        });
      }
      await refresh();
    } catch {
      // silent
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  if (photosLoading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">Photos ({photos.length})</CardTitle>
        <Button
          variant="secondary"
          size="sm"
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
        >
          {uploading ? (
            <span className="flex items-center gap-2">
              <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-current" />
              Uploading...
            </span>
          ) : (
            <>
              <Plus size={14} />
              Upload Photo
            </>
          )}
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          multiple
          className="hidden"
          onChange={(e) => handleUpload(e.target.files)}
        />
      </CardHeader>
      <CardContent>
        {photos.length === 0 ? (
          <div className="py-12 text-center">
            <Camera size={48} className="mx-auto text-muted mb-4 opacity-50" />
            <p className="text-muted">{t('common.noPhotosUploadedYet')}</p>
            <Button
              variant="secondary"
              size="sm"
              className="mt-4"
              onClick={() => fileInputRef.current?.click()}
            >
              <Plus size={14} />
              Upload First Photo
            </Button>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
            {photos.map((photo) => (
              <div key={photo.id} className="aspect-square rounded-lg bg-secondary overflow-hidden relative group">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={photo.signedUrl || ''}
                  alt={photo.caption || photo.fileName}
                  className="w-full h-full object-cover"
                />
                {photo.category !== 'general' && (
                  <span className="absolute top-2 left-2 px-2 py-0.5 bg-black/60 text-white text-[10px] rounded capitalize">
                    {photo.category}
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function TimeTab({ job }: { job: Job }) {
  const { t } = useTranslation();
  const [entries, setEntries] = useState<{ id: string; user_name: string; clock_in: string; clock_out: string | null; hours: number }[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const fetchEntries = async () => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('time_entries')
          .select('id, clock_in, clock_out, total_hours, users!inner(full_name)')
          .eq('job_id', job.id)
          .is('deleted_at', null)
          .order('clock_in', { ascending: false });

        if (!cancelled && data) {
          setEntries(data.map((e: Record<string, unknown>) => {
            const user = e.users as Record<string, unknown> | null;
            const clockIn = e.clock_in as string;
            const clockOut = e.clock_out as string | null;
            const totalHours = Number(e.total_hours) || 0;
            const computed = clockOut
              ? (new Date(clockOut).getTime() - new Date(clockIn).getTime()) / 3600000
              : 0;
            return {
              id: e.id as string,
              user_name: (user?.full_name as string) || 'Unknown',
              clock_in: clockIn,
              clock_out: clockOut,
              hours: totalHours || Math.round(computed * 100) / 100,
            };
          }));
        }
      } catch {
        if (!cancelled) setEntries([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    fetchEntries();
    return () => { cancelled = true; };
  }, [job.id]);

  const totalHours = entries.reduce((sum, e) => sum + e.hours, 0);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('jobs.time.title')}</CardTitle>
          <p className="text-sm text-muted mt-1">
            {entries.length === 0 ? 'No time logged' : `Total: ${totalHours.toFixed(1)} hours`}
          </p>
        </div>
        <Button variant="secondary" size="sm" onClick={() => window.location.href = '/dashboard/time-clock'}>
          <Clock size={14} />
          Time Clock
        </Button>
      </CardHeader>
      {entries.length === 0 ? (
        <CardContent>
          <div className="text-center py-8">
            <Clock size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('jobs.noTimeEntriesYet')}</p>
            <p className="text-xs text-muted mt-1">{t('jobs.teamCanClockIn')}</p>
          </div>
        </CardContent>
      ) : (
        <CardContent className="p-0">
          <div className="divide-y divide-main">
            {entries.map((entry) => (
              <div key={entry.id} className="px-6 py-4 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Avatar name={entry.user_name} size="sm" />
                  <div>
                    <p className="font-medium text-main">{entry.user_name}</p>
                    <p className="text-sm text-muted">{formatDate(new Date(entry.clock_in))}</p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-medium text-main">{entry.hours.toFixed(1)} hrs</p>
                <p className="text-sm text-muted">
                  {formatTimeLocale(entry.clock_in)}
                  {entry.clock_out && (
                    <> - {formatTimeLocale(entry.clock_out)}</>
                  )}
                  {!entry.clock_out && ' (active)'}
                </p>
              </div>
            </div>
          ))}
        </div>
      </CardContent>
      )}
    </Card>
  );
}

function TypeMetadataCard({ job }: { job: Job }) {
  const { t } = useTranslation();
  const meta = job.typeMetadata;
  const colors = JOB_TYPE_COLORS[job.jobType];
  const router = useRouter();
  const { claim } = useClaimByJob(job.jobType === 'insurance_claim' ? job.id : null);

  if (job.jobType === 'insurance_claim') {
    const ins = meta as InsuranceMetadata;
    const approvalColors: Record<string, string> = {
      pending: 'text-amber-600 dark:text-amber-400',
      approved: 'text-emerald-600 dark:text-emerald-400',
      denied: 'text-red-600 dark:text-red-400',
      supplemental: 'text-blue-600 dark:text-blue-400',
    };
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <span className={cn('w-2 h-2 rounded-full', colors.dot)} />
            Insurance Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2.5 text-sm">
          <MetaRow label="Company" value={ins.insuranceCompany} />
          <MetaRow label="Claim #" value={ins.claimNumber} />
          {ins.policyNumber && <MetaRow label="Policy #" value={ins.policyNumber} />}
          {ins.dateOfLoss && <MetaRow label="Date of Loss" value={ins.dateOfLoss} />}
          {ins.adjusterName && <MetaRow label="Adjuster" value={ins.adjusterName} />}
          {ins.adjusterPhone && <MetaRow label="Adjuster Phone" value={ins.adjusterPhone} />}
          {ins.deductible != null && <MetaRow label="Deductible" value={formatCurrency(ins.deductible)} />}
          {ins.coverageLimit != null && <MetaRow label="Coverage Limit" value={formatCurrency(ins.coverageLimit)} />}
          {ins.approvalStatus && (
            <div className="flex justify-between">
              <span className="text-muted">{t('common.approval')}</span>
              <span className={cn('font-medium capitalize', approvalColors[ins.approvalStatus] || 'text-main')}>
                {ins.approvalStatus}
              </span>
            </div>
          )}
          {claim && (
            <button
              onClick={() => router.push(`/dashboard/insurance/${claim.id}`)}
              className="w-full mt-2 flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 text-xs font-medium hover:bg-amber-500/20 transition-colors"
            >
              <Shield className="w-3.5 h-3.5" />
              View Claim
            </button>
          )}
        </CardContent>
      </Card>
    );
  }

  if (job.jobType === 'warranty_dispatch') {
    const war = meta as WarrantyMetadata;
    const typeLabels: Record<string, string> = {
      home_warranty: 'Home Warranty',
      manufacturer: 'Manufacturer',
      extended: 'Extended',
    };
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <span className={cn('w-2 h-2 rounded-full', colors.dot)} />
            Warranty Details
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2.5 text-sm">
          <MetaRow label="Company" value={war.warrantyCompany} />
          <MetaRow label="Dispatch #" value={war.dispatchNumber} />
          {war.warrantyType && <MetaRow label="Type" value={typeLabels[war.warrantyType] || war.warrantyType} />}
          {war.authorizationLimit != null && <MetaRow label="Auth Limit" value={formatCurrency(war.authorizationLimit)} />}
          {war.serviceFee != null && <MetaRow label="Service Fee" value={formatCurrency(war.serviceFee)} />}
          {war.expirationDate && <MetaRow label="Expires" value={war.expirationDate} />}
        </CardContent>
      </Card>
    );
  }

  return null;
}

function MetaRow({ label, value }: { label: string; value?: string | number }) {
  if (!value) return null;
  return (
    <div className="flex justify-between">
      <span className="text-muted">{label}</span>
      <span className="text-main font-medium">{value}</span>
    </div>
  );
}

function NotesTab({ job }: { job: Job }) {
  const { t } = useTranslation();
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const fetchNotes = async () => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('jobs')
          .select('internal_notes')
          .eq('id', job.id)
          .single();
        if (!cancelled && data) {
          setNotes((data.internal_notes as string) || '');
        }
      } catch {
        // silent
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    fetchNotes();
    return () => { cancelled = true; };
  }, [job.id]);

  const handleSave = async () => {
    setSaving(true);
    setSaved(false);
    try {
      const supabase = getSupabase();
      const { error } = await supabase
        .from('jobs')
        .update({ internal_notes: notes })
        .eq('id', job.id);
      if (!error) {
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
      }
    } catch {
      // silent
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="text-base">{t('jobs.jobNotes')}</CardTitle>
        {saved && (
          <span className="flex items-center gap-1 text-xs text-emerald-500">
            <CheckCircle size={12} />
            Saved
          </span>
        )}
      </CardHeader>
      <CardContent className="space-y-3">
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Add notes about this job — scope details, access instructions, materials needed, customer preferences..."
          className="w-full px-4 py-3 bg-secondary border border-main rounded-lg resize-y text-main text-sm placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-accent/50 min-h-[150px]"
          rows={8}
        />
        <Button onClick={handleSave} disabled={saving}>
          {saving ? 'Saving...' : 'Save Notes'}
        </Button>
      </CardContent>
    </Card>
  );
}

// ── Estimates Tab ──
function EstimatesTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const router = useRouter();
  const { estimates, loading } = useEstimates();
  const jobEstimates = estimates.filter(e => e.jobId === jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  const STATUS_COLORS: Record<string, string> = {
    draft: 'bg-zinc-500/10 text-zinc-400',
    sent: 'bg-blue-500/10 text-blue-400',
    approved: 'bg-emerald-500/10 text-emerald-400',
    declined: 'bg-red-500/10 text-red-400',
    revised: 'bg-amber-500/10 text-amber-400',
    completed: 'bg-emerald-500/10 text-emerald-400',
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('estimates.title')}</CardTitle>
          {jobEstimates.length > 0 && (
            <p className="text-xs text-muted mt-1">
              {jobEstimates.length} {t('estimates.title').toLowerCase()} &middot; {formatCurrency(jobEstimates.reduce((s, e) => s + e.grandTotal, 0))} {t('common.total').toLowerCase()}
            </p>
          )}
        </div>
        <Button variant="secondary" size="sm" onClick={() => router.push('/dashboard/estimates')}>
          <Plus size={14} />
          {t('estimates.new')}
        </Button>
      </CardHeader>
      <CardContent>
        {jobEstimates.length === 0 ? (
          <div className="text-center py-8">
            <FileText size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('estimates.noEstimates')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {jobEstimates.map(est => (
              <button
                key={est.id}
                onClick={() => router.push(`/dashboard/estimates/${est.id}`)}
                className="w-full flex items-center gap-4 p-3 rounded-lg border border-main hover:bg-surface-hover transition-colors text-left"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-main truncate">{est.estimateNumber}</span>
                    <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', STATUS_COLORS[est.status] || 'bg-zinc-500/10 text-zinc-400')}>
                      {est.status}
                    </span>
                  </div>
                  <p className="text-xs text-muted mt-0.5 truncate">{est.title || est.customerName}</p>
                </div>
                <span className="text-sm font-medium text-main">{formatCurrency(est.grandTotal)}</span>
                <ChevronRight size={14} className="text-muted" />
              </button>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Invoices Tab ──
function InvoicesTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const router = useRouter();
  const { invoices, loading } = useInvoices();
  const jobInvoices = invoices.filter(inv => inv.jobId === jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('invoices.title')}</CardTitle>
          {jobInvoices.length > 0 && (
            <p className="text-xs text-muted mt-1">
              {jobInvoices.length} {t('invoices.title').toLowerCase()} &middot; {formatCurrency(jobInvoices.reduce((s, inv) => s + inv.total, 0))} {t('common.total').toLowerCase()}
            </p>
          )}
        </div>
        <Button variant="secondary" size="sm" onClick={() => router.push('/dashboard/invoices/new')}>
          <Plus size={14} />
          {t('invoices.title')}
        </Button>
      </CardHeader>
      <CardContent>
        {jobInvoices.length === 0 ? (
          <div className="text-center py-8">
            <Receipt size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('invoices.noRecords')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {jobInvoices.map(inv => (
              <button
                key={inv.id}
                onClick={() => router.push(`/dashboard/invoices/${inv.id}`)}
                className="w-full flex items-center gap-4 p-3 rounded-lg border border-main hover:bg-surface-hover transition-colors text-left"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-main">{inv.invoiceNumber}</span>
                    <StatusBadge status={inv.status} />
                  </div>
                  <p className="text-xs text-muted mt-0.5">
                    {t('common.dueDate')}: {formatDateLocale(inv.dueDate)}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-main">{formatCurrency(inv.total)}</p>
                  {inv.amountDue > 0 && (
                    <p className="text-xs text-amber-500">{t('invoices.overdueAmount')}: {formatCurrency(inv.amountDue)}</p>
                  )}
                </div>
                <ChevronRight size={14} className="text-muted" />
              </button>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Documents Tab ──
function DocumentsTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const { documents, loading } = useDocuments();
  const jobDocs = documents.filter(d => d.jobId === jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('common.documents')}</CardTitle>
          {jobDocs.length > 0 && (
            <p className="text-xs text-muted mt-1">{jobDocs.length} {t('common.documents').toLowerCase()}</p>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {jobDocs.length === 0 ? (
          <div className="text-center py-8">
            <FileText size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('documents.noDocuments')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {jobDocs.map(doc => (
              <div
                key={doc.id}
                className="flex items-center gap-3 p-3 rounded-lg border border-main hover:bg-surface-hover transition-colors"
              >
                <div className="w-8 h-8 rounded bg-blue-500/10 flex items-center justify-center flex-shrink-0">
                  <FileText size={16} className="text-blue-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-main truncate">{doc.name}</p>
                  <p className="text-xs text-muted">
                    {doc.documentType} &middot; {formatFileSize(doc.fileSizeBytes)} &middot; {formatDateLocale(doc.createdAt)}
                  </p>
                </div>
                {doc.requiresSignature && (
                  <span className={cn(
                    'text-[10px] px-1.5 py-0.5 rounded-full',
                    doc.signatureStatus === 'signed' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-400'
                  )}>
                    {doc.signatureStatus === 'signed' ? 'Signed' : 'Needs Signature'}
                  </span>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Change Orders Tab ──
function ChangeOrdersTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const { changeOrders, loading } = useChangeOrders();
  const jobCOs = changeOrders.filter(co => co.jobId === jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  const CO_STATUS_COLORS: Record<string, string> = {
    draft: 'bg-zinc-500/10 text-zinc-400',
    pending_approval: 'bg-amber-500/10 text-amber-400',
    approved: 'bg-emerald-500/10 text-emerald-400',
    rejected: 'bg-red-500/10 text-red-400',
    voided: 'bg-zinc-500/10 text-zinc-500',
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('changeOrders.title')}</CardTitle>
          {jobCOs.length > 0 && (
            <p className="text-xs text-muted mt-1">
              {jobCOs.length} {t('changeOrders.title').toLowerCase()} &middot; {formatCurrency(jobCOs.filter(co => co.status === 'approved').reduce((s, co) => s + co.amount, 0))} {t('changeOrders.approved')}
            </p>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {jobCOs.length === 0 ? (
          <div className="text-center py-8">
            <Edit size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('changeOrders.noChangeOrders')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {jobCOs.map(co => (
              <div
                key={co.id}
                className="flex items-center gap-4 p-3 rounded-lg border border-main hover:bg-surface-hover transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-main">{co.number || 'CO'}</span>
                    <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', CO_STATUS_COLORS[co.status] || 'bg-zinc-500/10 text-zinc-400')}>
                      {co.status.replace('_', ' ')}
                    </span>
                  </div>
                  <p className="text-xs text-muted mt-0.5 truncate">{co.title} &middot; {co.reason}</p>
                </div>
                <span className={cn(
                  'text-sm font-medium',
                  co.amount >= 0 ? 'text-emerald-500' : 'text-red-500'
                )}>
                  {co.amount >= 0 ? '+' : ''}{formatCurrency(co.amount)}
                </span>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Permits Tab ──
function PermitsTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const { permits, loading } = usePermits();
  const jobPermits = permits.filter(p => p.jobId === jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  const PERMIT_STATUS_COLORS: Record<string, string> = {
    draft: 'bg-zinc-500/10 text-zinc-400',
    applied: 'bg-blue-500/10 text-blue-400',
    approved: 'bg-emerald-500/10 text-emerald-400',
    rejected: 'bg-red-500/10 text-red-400',
    expired: 'bg-amber-500/10 text-amber-400',
    closed: 'bg-zinc-500/10 text-zinc-500',
  };

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('permits.title')}</CardTitle>
          {jobPermits.length > 0 && (
            <p className="text-xs text-muted mt-1">{jobPermits.length} {t('permits.title').toLowerCase()}</p>
          )}
        </div>
        <Button variant="secondary" size="sm" onClick={() => window.location.href = `/dashboard/permits/${jobId}`}>
          <Plus size={14} />
          {t('permits.title')}
        </Button>
      </CardHeader>
      <CardContent>
        {jobPermits.length === 0 ? (
          <div className="text-center py-8">
            <Shield size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('permits.noPermits')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {jobPermits.map(permit => (
              <div
                key={permit.id}
                className="flex items-center gap-4 p-3 rounded-lg border border-main hover:bg-surface-hover transition-colors"
              >
                <div className="w-8 h-8 rounded bg-purple-500/10 flex items-center justify-center flex-shrink-0">
                  <Shield size={16} className="text-purple-400" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-main">{permit.permitNumber || permit.permitType}</span>
                    <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', PERMIT_STATUS_COLORS[permit.status] || 'bg-zinc-500/10 text-zinc-400')}>
                      {permit.status}
                    </span>
                  </div>
                  <p className="text-xs text-muted mt-0.5 truncate">
                    {permit.description || permit.jurisdiction || 'No description'}
                    {permit.fee > 0 && ` · ${formatCurrency(permit.fee)}`}
                  </p>
                </div>
                {permit.expirationDate && (
                  <span className="text-xs text-muted">{t('permits.expires')}: {formatDateLocale(permit.expirationDate)}</span>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Daily Logs Tab ──
function DailyLogsTab({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const { logs, loading } = useDailyLogs(jobId);

  if (loading) {
    return (
      <Card>
        <CardContent className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="text-base">{t('common.dailyLogs')}</CardTitle>
          {logs.length > 0 && (
            <p className="text-xs text-muted mt-1">{logs.length} {t('common.dailyLogs').toLowerCase()}</p>
          )}
        </div>
      </CardHeader>
      <CardContent>
        {logs.length === 0 ? (
          <div className="text-center py-8">
            <Calendar size={32} className="mx-auto text-muted mb-2" />
            <p className="text-sm text-muted">{t('common.noResults')}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {logs.map(log => (
              <div
                key={log.id}
                className="p-4 rounded-lg border border-main hover:bg-surface-hover transition-colors"
              >
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Calendar size={14} className="text-accent" />
                    <span className="text-sm font-medium text-main">{formatDateLocale(log.logDate)}</span>
                  </div>
                  <div className="flex items-center gap-3 text-xs text-muted">
                    {log.crewCount > 0 && <span>{log.crewCount} crew</span>}
                    {log.hoursWorked > 0 && <span>{log.hoursWorked}h</span>}
                    {log.weather && <span>{log.weather}{log.temperatureF ? ` ${log.temperatureF}°F` : ''}</span>}
                  </div>
                </div>
                {log.summary && (
                  <p className="text-sm text-main mb-1">{log.summary}</p>
                )}
                {log.workPerformed && (
                  <p className="text-xs text-muted">{log.workPerformed}</p>
                )}
                {log.issues && (
                  <div className="mt-2 flex items-start gap-1.5 text-xs text-amber-500">
                    <AlertTriangle size={12} className="mt-0.5 flex-shrink-0" />
                    <span>{log.issues}</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

const SOURCE_CONFIG: Record<string, { label: string; color: string }> = {
  carrier: { label: 'Carrier Approved', color: 'text-blue-600 dark:text-blue-400' },
  deductible: { label: 'Deductible', color: 'text-amber-600 dark:text-amber-400' },
  upgrade: { label: 'Homeowner Upgrades', color: 'text-purple-600 dark:text-purple-400' },
  standard: { label: 'Standard', color: 'text-main' },
};

function UpgradeTrackingSummary({ jobId }: { jobId: string }) {
  const { t } = useTranslation();
  const [totals, setTotals] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);

  const fetchTotals = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('invoices')
        .select('line_items')
        .eq('job_id', jobId);

      const sums: Record<string, number> = {};
      for (const row of data || []) {
        const items = Array.isArray(row.line_items) ? row.line_items : [];
        for (const li of items) {
          const item = li as Record<string, unknown>;
          const src = (item.payment_source as string) || 'standard';
          const amt = Number(item.quantity || 1) * Number(item.unit_price ?? item.unitPrice ?? 0);
          sums[src] = (sums[src] || 0) + amt;
        }
      }
      setTotals(sums);
    } catch (_) {
      // silent
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => { fetchTotals(); }, [fetchTotals]);

  const hasNonStandard = Object.keys(totals).some((k) => k !== 'standard' && totals[k] > 0);
  if (loading || !hasNonStandard) return null;

  const grandTotal = Object.values(totals).reduce((a, b) => a + b, 0);

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <DollarSign size={18} className="text-muted" />
          Payment Source Breakdown
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-2.5 text-sm">
        {(['carrier', 'deductible', 'upgrade', 'standard'] as const).map((src) =>
          totals[src] ? (
            <div key={src} className="flex justify-between">
              <span className="text-muted">{SOURCE_CONFIG[src].label}</span>
              <span className={cn('font-medium', SOURCE_CONFIG[src].color)}>
                {formatCurrency(totals[src])}
              </span>
            </div>
          ) : null
        )}
        <div className="flex justify-between pt-2 border-t border-main font-semibold">
          <span>{t('common.total')}</span>
          <span>{formatCurrency(grandTotal)}</span>
        </div>
      </CardContent>
    </Card>
  );
}

// ============================================================================
// PROPERTY INTELLIGENCE CARD
// ============================================================================

const CONFIDENCE_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  high: { label: 'High Confidence', color: 'text-emerald-600 dark:text-emerald-400', bg: 'bg-emerald-500/10' },
  moderate: { label: 'Moderate Confidence', color: 'text-amber-600 dark:text-amber-400', bg: 'bg-amber-500/10' },
  low: { label: 'Low Confidence', color: 'text-red-600 dark:text-red-400', bg: 'bg-red-500/10' },
};

const SHAPE_LABELS: Record<string, string> = {
  gable: 'Gable', hip: 'Hip', flat: 'Flat', gambrel: 'Gambrel', mansard: 'Mansard', mixed: 'Complex/Mixed',
};

function PropertyIntelligenceCard({ job }: { job: Job }) {
  const { t } = useTranslation();
  const router = useRouter();
  const fullAddress = [job.address.street, job.address.city, job.address.state, job.address.zip].filter(Boolean).join(', ');
  const { scan, roof, loading, error, triggerScan } = usePropertyScan(job.id, 'job');
  const { leadScore } = useLeadScore(scan?.id || '');
  const [scanning, setScanning] = useState(false);

  const handleScan = async () => {
    if (!fullAddress) return;
    setScanning(true);
    await triggerScan(fullAddress, job.id);
    setScanning(false);
  };

  // Loading state
  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Satellite size={18} className="text-muted" />
            Property Intelligence
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-center py-4">
            <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-accent" />
          </div>
        </CardContent>
      </Card>
    );
  }

  // No scan yet — offer to run one
  if (!scan) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Satellite size={18} className="text-muted" />
            Property Intelligence
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-sm text-muted">
            No satellite scan data available for this property.
          </p>
          <Button
            variant="secondary"
            size="sm"
            className="w-full"
            onClick={handleScan}
            disabled={scanning || !fullAddress}
          >
            {scanning ? (
              <>
                <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-current mr-2" />
                Scanning...
              </>
            ) : (
              <>
                <Satellite size={14} />
                Run Property Scan
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    );
  }

  // Scan in progress
  if (scan.status === 'scanning' || scan.status === 'pending') {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Satellite size={18} className="text-accent" />
            Property Intelligence
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center gap-2 text-sm text-accent">
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-accent" />
            Scanning property...
          </div>
          <p className="text-xs text-muted">{t('jobs.satelliteDataIsBeingProcessedThisUsuallyTakesAFewS')}</p>
        </CardContent>
      </Card>
    );
  }

  // Scan failed
  if (scan.status === 'failed') {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Satellite size={18} className="text-red-500" />
            Property Intelligence
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-sm text-red-500">{t('jobs.scanFailed')}</p>
          <Button variant="secondary" size="sm" className="w-full" onClick={handleScan} disabled={scanning}>
            <Satellite size={14} />
            Retry Scan
          </Button>
        </CardContent>
      </Card>
    );
  }

  // Scan complete or partial — show data
  const conf = CONFIDENCE_CONFIG[scan.confidenceGrade] || CONFIDENCE_CONFIG.low;
  const imageryOld = scan.imageryAgeMonths != null && scan.imageryAgeMonths > 18;

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Satellite size={18} className="text-accent" />
          Property Intelligence
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {/* Confidence Badge + Lead Score */}
        <div className="flex items-center gap-2 flex-wrap">
          <div className={cn('inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium', conf.bg, conf.color)}>
            <div className={cn('w-1.5 h-1.5 rounded-full', scan.confidenceGrade === 'high' ? 'bg-emerald-500' : scan.confidenceGrade === 'moderate' ? 'bg-amber-500' : 'bg-red-500')} />
            {conf.label} ({scan.confidenceScore}%)
          </div>
          {leadScore && (
            <div className={cn(
              'inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium',
              leadScore.grade === 'hot' ? 'bg-red-500/10 text-red-400' :
              leadScore.grade === 'warm' ? 'bg-orange-500/10 text-orange-400' :
              'bg-blue-500/10 text-blue-400'
            )}>
              Lead: {leadScore.overallScore} ({leadScore.grade})
            </div>
          )}
        </div>

        {/* Roof Data */}
        {roof && (
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-muted">{t('common.roofArea')}</span>
              <span className="text-main font-medium">{roof.totalAreaSqft.toLocaleString()} sq ft ({roof.totalAreaSquares} sq)</span>
            </div>
            {roof.pitchPrimary && (
              <div className="flex justify-between">
                <span className="text-muted">{t('common.primaryPitch')}</span>
                <span className="text-main font-medium">{roof.pitchPrimary}</span>
              </div>
            )}
            {roof.predominantShape && (
              <div className="flex justify-between">
                <span className="text-muted">{t('common.shape')}</span>
                <span className="text-main font-medium">{SHAPE_LABELS[roof.predominantShape] || roof.predominantShape}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-muted">{t('common.facets')}</span>
              <span className="text-main font-medium">{roof.facetCount}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted">{t('common.complexity')}</span>
              <span className="text-main font-medium">{roof.complexityScore}/10</span>
            </div>
            {(roof.ridgeLengthFt > 0 || roof.eaveLengthFt > 0) && (
              <div className="pt-2 border-t border-main space-y-1.5">
                <p className="text-xs font-medium text-muted uppercase tracking-wider">{t('common.edgeLengths')}</p>
                {roof.ridgeLengthFt > 0 && <div className="flex justify-between"><span className="text-muted">{t('common.ridge')}</span><span className="text-main">{roof.ridgeLengthFt} ft</span></div>}
                {roof.hipLengthFt > 0 && <div className="flex justify-between"><span className="text-muted">{t('common.hip')}</span><span className="text-main">{roof.hipLengthFt} ft</span></div>}
                {roof.valleyLengthFt > 0 && <div className="flex justify-between"><span className="text-muted">{t('common.valley')}</span><span className="text-main">{roof.valleyLengthFt} ft</span></div>}
                {roof.eaveLengthFt > 0 && <div className="flex justify-between"><span className="text-muted">{t('jobs.eave')}</span><span className="text-main">{roof.eaveLengthFt} ft</span></div>}
                {roof.rakeLengthFt > 0 && <div className="flex justify-between"><span className="text-muted">{t('jobs.rake')}</span><span className="text-main">{roof.rakeLengthFt} ft</span></div>}
              </div>
            )}
          </div>
        )}

        {/* Imagery Info */}
        {scan.imageryDate && (
          <div className="text-sm">
            <div className="flex justify-between">
              <span className="text-muted">{t('jobs.imageryDate')}</span>
              <span className="text-main">{formatDate(scan.imageryDate)}</span>
            </div>
            {scan.imagerySource && (
              <div className="flex justify-between mt-1">
                <span className="text-muted">{t('leads.source')}</span>
                <span className="text-main capitalize">{scan.imagerySource.replace('_', ' ')}</span>
              </div>
            )}
          </div>
        )}

        {/* Imagery Age Warning */}
        {imageryOld && (
          <div className="flex items-start gap-2 p-2.5 rounded-lg bg-amber-500/10 text-amber-600 dark:text-amber-400 text-xs">
            <AlertTriangle size={14} className="mt-0.5 shrink-0" />
            <span>Imagery may not reflect recent changes ({scan.imageryAgeMonths} months old). Verify on site.</span>
          </div>
        )}

        {/* Partial scan warning */}
        {scan.status === 'partial' && (
          <div className="flex items-start gap-2 p-2.5 rounded-lg bg-blue-500/10 text-blue-600 dark:text-blue-400 text-xs">
            <AlertTriangle size={14} className="mt-0.5 shrink-0" />
            <span>Partial data — some sources were unavailable. Roof measurements may be estimated.</span>
          </div>
        )}

        {/* Action buttons */}
        <div className="flex gap-2">
          <Button
            variant="secondary"
            size="sm"
            className="flex-1"
            onClick={() => router.push(`/dashboard/recon/${scan.id}`)}
          >
            <Ruler size={14} />
            Full Report
          </Button>
          <Button variant="secondary" size="sm" onClick={handleScan} disabled={scanning}>
            <Satellite size={14} />
            {scanning ? '...' : 'Rescan'}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
