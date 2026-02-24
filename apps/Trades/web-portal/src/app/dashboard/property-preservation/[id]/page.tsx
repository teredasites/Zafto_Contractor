'use client';

import { useState, useMemo, useCallback } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Home,
  Clock,
  DollarSign,
  CheckCircle,
  MapPin,
  Calendar,
  Camera,
  Shield,
  Snowflake,
  Trash2,
  Wrench,
  Zap,
  Eye,
  FileText,
  Loader2,
  Building2,
  ChevronRight,
  AlertTriangle,
  Thermometer,
  Droplets,
  X,
  Plus,
  Save,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import {
  usePpWorkOrders,
  usePpWinterization,
  usePpDebris,
  usePpUtilities,
  usePpReferenceData,
  usePpChargebacks,
  type PpWorkOrder,
  type PpWorkOrderStatus,
  type PpWorkOrderCategory,
  type PpWinterizationRecord,
  type PpDebrisEstimate,
  type PpUtilityTracking,
  type PpChargeback,
} from '@/lib/hooks/use-property-preservation';

// ── Types & Constants ──

type LucideIcon = React.ComponentType<{ size?: number; className?: string }>;

type TabKey = 'details' | 'category' | 'photos' | 'chargeback';

const STATUS_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  assigned: { label: 'Assigned', color: 'text-blue-400', bg: 'bg-blue-500/10' },
  in_progress: { label: 'In Progress', color: 'text-yellow-400', bg: 'bg-yellow-500/10' },
  completed: { label: 'Completed', color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
  submitted: { label: 'Submitted', color: 'text-purple-400', bg: 'bg-purple-500/10' },
  approved: { label: 'Approved', color: 'text-green-400', bg: 'bg-green-500/10' },
  rejected: { label: 'Rejected', color: 'text-red-400', bg: 'bg-red-500/10' },
  disputed: { label: 'Disputed', color: 'text-orange-400', bg: 'bg-orange-500/10' },
};

const CATEGORY_ICONS: Record<string, LucideIcon> = {
  securing: Shield,
  winterization: Snowflake,
  debris: Trash2,
  lawn_snow: Home,
  inspection: Eye,
  repair: Wrench,
  utility: Zap,
  specialty: FileText,
};

const CATEGORY_LABELS: Record<string, string> = {
  securing: 'Securing',
  winterization: 'Winterization',
  debris: 'Debris Removal',
  lawn_snow: 'Lawn/Snow',
  inspection: 'Inspection',
  repair: 'Repair',
  utility: 'Utility',
  specialty: 'Specialty',
};

const NEXT_STATUS: Record<string, PpWorkOrderStatus> = {
  assigned: 'in_progress',
  in_progress: 'completed',
  completed: 'submitted',
};

const NEXT_STATUS_LABEL: Record<string, string> = {
  assigned: 'Start Work',
  in_progress: 'Mark Completed',
  completed: 'Submit to National',
};

// ── Winterization checklist items ──
const WINTERIZATION_CHECKLIST = [
  'toilet_bowls', 'toilet_tanks', 'p_traps', 'water_heater_drain',
  'washing_machine', 'dishwasher', 'outdoor_faucets', 'sprinkler_system',
  'sump_pump', 'crawlspace_lines',
];

const WINTERIZATION_LABELS: Record<string, string> = {
  toilet_bowls: 'Toilet Bowls',
  toilet_tanks: 'Toilet Tanks',
  p_traps: 'P-Traps',
  water_heater_drain: 'Water Heater Drain',
  washing_machine: 'Washing Machine',
  dishwasher: 'Dishwasher',
  outdoor_faucets: 'Outdoor Faucets',
  sprinkler_system: 'Sprinkler System',
  sump_pump: 'Sump Pump',
  crawlspace_lines: 'Crawlspace Lines',
};

// ── Securing checklist items ──
const SECURING_CHECKLIST = [
  'front_door', 'back_door', 'garage_door', 'side_doors',
  'windows_boarded', 'padlocks_installed', 'hasp_installed',
  'lock_code_set', 'property_secured',
];

const SECURING_LABELS: Record<string, string> = {
  front_door: 'Front Door',
  back_door: 'Back Door',
  garage_door: 'Garage Door',
  side_doors: 'Side Doors',
  windows_boarded: 'Windows Boarded',
  padlocks_installed: 'Padlocks Installed',
  hasp_installed: 'Hasp Installed',
  lock_code_set: 'Lock Code Set',
  property_secured: 'Property Fully Secured',
};

// ── Photo requirements per category ──
const REQUIRED_PHOTOS: Record<string, string[]> = {
  securing: ['Front Exterior', 'Rear Exterior', 'All Doors', 'All Windows', 'All Locks', 'Board-ups', 'Lock Code'],
  winterization: ['Furnace/Boiler', 'Water Heater', 'Pressure Gauge Start', 'Pressure Gauge End', 'All Fixtures', 'Antifreeze', 'Winterization Sticker'],
  debris: ['Before - Each Room', 'During - Loading', 'After - Each Room', 'Dumpster', 'Haul Receipt'],
  lawn_snow: ['Before - Front', 'Before - Rear', 'After - Front', 'After - Rear', 'Trim Areas'],
  inspection: ['Front Exterior', 'Rear Exterior', 'All Rooms', 'Utilities', 'Damage Areas', 'Violations'],
  utility: ['Meter Reading', 'Shut-off Location', 'Utility Box', 'Status Documentation'],
};

// ── Main Page ──

export default function WorkOrderDetailPage() {
  const router = useRouter();
  const params = useParams();
  const workOrderId = params.id as string;

  const [activeTab, setActiveTab] = useState<TabKey>('details');

  const { workOrders, loading: woLoading, updateWorkOrderStatus } = usePpWorkOrders();
  const { records: winterRecords, loading: wintLoading, createRecord: createWinterRecord } = usePpWinterization();
  const { estimates: debrisEstimates, loading: debrisLoading, createEstimate: createDebrisEstimate } = usePpDebris();
  const { utilities, loading: utilLoading, createUtility, updateUtility } = usePpUtilities();
  const { chargebacks, loading: cbLoading, createChargeback } = usePpChargebacks();
  const { nationals, woTypes } = usePpReferenceData();

  const workOrder = useMemo(() => workOrders.find(wo => wo.id === workOrderId), [workOrders, workOrderId]);
  const woType = useMemo(() => {
    if (!workOrder) return null;
    return woTypes.find(t => t.id === workOrder.workOrderTypeId) ?? null;
  }, [workOrder, woTypes]);
  const national = useMemo(() => {
    if (!workOrder?.nationalCompanyId) return null;
    return nationals.find(n => n.id === workOrder.nationalCompanyId) ?? null;
  }, [workOrder, nationals]);

  // Filter related records for this work order
  const woWinterRecords = useMemo(() => winterRecords.filter(r => r.workOrderId === workOrderId), [winterRecords, workOrderId]);
  const woDebrisEstimates = useMemo(() => debrisEstimates.filter(e => e.workOrderId === workOrderId), [debrisEstimates, workOrderId]);
  const woChargebacks = useMemo(() => chargebacks.filter(c => c.workOrderId === workOrderId), [chargebacks, workOrderId]);

  const loading = woLoading;

  // Chargeback protection score
  const chargebackScore = useMemo(() => {
    if (!workOrder) return 0;
    let score = 0;
    const checklist = workOrder.checklistProgress || {};
    const totalCheckItems = Object.keys(checklist).length;
    const completedCheckItems = Object.values(checklist).filter(v => v === true).length;

    // Checklist completion: 30 points
    if (totalCheckItems > 0) score += Math.round((completedCheckItems / totalCheckItems) * 30);

    // Has notes: 10 points
    if (workOrder.notes) score += 10;

    // Has bid amount: 10 points
    if (workOrder.bidAmount != null && workOrder.bidAmount > 0) score += 10;

    // Has external order ID: 10 points
    if (workOrder.externalOrderId) score += 10;

    // Winter record / debris estimate exists: 20 points
    if (woWinterRecords.length > 0 || woDebrisEstimates.length > 0) score += 20;

    // Status progression (started, completed, submitted): 20 points
    const statusScores: Record<string, number> = {
      assigned: 0, in_progress: 5, completed: 10, submitted: 15, approved: 20, rejected: 10, disputed: 10,
    };
    score += statusScores[workOrder.status] || 0;

    return Math.min(100, score);
  }, [workOrder, woWinterRecords, woDebrisEstimates]);

  const handleAdvanceStatus = useCallback(async () => {
    if (!workOrder) return;
    const next = NEXT_STATUS[workOrder.status];
    if (!next) return;
    await updateWorkOrderStatus(workOrder.id, workOrder.updatedAt, next);
  }, [workOrder, updateWorkOrderStatus]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-accent" />
      </div>
    );
  }

  if (!workOrder) {
    return (
      <div className="text-center py-12">
        <Home size={48} className="mx-auto text-muted mb-4" />
        <h2 className="text-xl font-semibold text-main">Work Order Not Found</h2>
        <p className="text-muted mt-2">This work order may have been deleted.</p>
        <Button variant="secondary" className="mt-4" onClick={() => router.push('/dashboard/property-preservation')}>
          Back to PP Dashboard
        </Button>
      </div>
    );
  }

  const statusConf = STATUS_CONFIG[workOrder.status] || STATUS_CONFIG.assigned;
  const CatIcon = CATEGORY_ICONS[woType?.category || ''] || FileText;
  const category = woType?.category || 'other';

  const tabs: { key: TabKey; label: string; icon: LucideIcon }[] = [
    { key: 'details', label: 'Details', icon: FileText },
    { key: 'category', label: CATEGORY_LABELS[category] || 'Category', icon: CatIcon },
    { key: 'photos', label: 'Photos', icon: Camera },
    { key: 'chargeback', label: 'Protection', icon: Shield },
  ];

  return (
    <div className="space-y-6 pb-8">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={() => router.push('/dashboard/property-preservation')}>
          <ArrowLeft size={16} />
        </Button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-3">
            <CatIcon size={22} className="text-muted" />
            <h1 className="text-xl font-bold text-main">{woType?.name || 'Work Order'}</h1>
            <Badge className={cn('text-xs', statusConf.color, statusConf.bg)}>
              {statusConf.label}
            </Badge>
          </div>
          <div className="flex items-center gap-3 mt-1 text-sm text-muted">
            {national && (
              <span className="flex items-center gap-1">
                <Building2 size={12} />
                {national.name}
              </span>
            )}
            {workOrder.externalOrderId && (
              <span className="font-mono">#{workOrder.externalOrderId}</span>
            )}
            <span className="flex items-center gap-1">
              <Calendar size={12} />
              Created {formatDate(workOrder.createdAt)}
            </span>
          </div>
        </div>
        {NEXT_STATUS[workOrder.status] && (
          <Button onClick={handleAdvanceStatus}>
            {NEXT_STATUS_LABEL[workOrder.status]}
          </Button>
        )}
      </div>

      {/* Status Pipeline */}
      <div className="flex items-center gap-1">
        {Object.entries(STATUS_CONFIG).map(([key, conf], idx, arr) => {
          const statusOrder = ['assigned', 'in_progress', 'completed', 'submitted', 'approved'];
          const currentIdx = statusOrder.indexOf(workOrder.status);
          const stepIdx = statusOrder.indexOf(key);
          const isPast = stepIdx < currentIdx;
          const isCurrent = key === workOrder.status;
          if (!statusOrder.includes(key)) return null;
          return (
            <div key={key} className="flex items-center gap-1 flex-1">
              <div className={cn(
                'flex-1 h-1.5 rounded-full transition-colors',
                isPast || isCurrent ? (isCurrent ? conf.bg.replace('/10', '/40') : 'bg-emerald-500/40') : 'bg-secondary'
              )} />
            </div>
          );
        })}
      </div>

      {/* Quick Stats Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Card className="p-3">
          <div className="text-xs text-muted mb-0.5">Bid Amount</div>
          <p className="text-lg font-bold text-main">
            {workOrder.bidAmount != null ? formatCurrency(workOrder.bidAmount) : '--'}
          </p>
        </Card>
        <Card className="p-3">
          <div className="text-xs text-muted mb-0.5">Approved</div>
          <p className="text-lg font-bold text-emerald-400">
            {workOrder.approvedAmount != null ? formatCurrency(workOrder.approvedAmount) : '--'}
          </p>
        </Card>
        <Card className="p-3">
          <div className="text-xs text-muted mb-0.5">Due Date</div>
          <p className={cn('text-lg font-bold', workOrder.dueDate ? 'text-main' : 'text-muted')}>
            {workOrder.dueDate ? formatDate(workOrder.dueDate) : 'Not set'}
          </p>
        </Card>
        <Card className="p-3">
          <div className="text-xs text-muted mb-0.5">Protection Score</div>
          <p className={cn(
            'text-lg font-bold',
            chargebackScore >= 80 ? 'text-emerald-400' :
            chargebackScore >= 50 ? 'text-yellow-400' : 'text-red-400'
          )}>
            {chargebackScore}%
          </p>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-main overflow-x-auto">
        {tabs.map(tab => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'flex items-center gap-2 px-4 py-2.5 text-sm font-medium whitespace-nowrap border-b-2 transition-colors',
                activeTab === tab.key
                  ? 'border-accent text-accent'
                  : 'border-transparent text-muted hover:text-main'
              )}
            >
              <Icon size={14} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-4">
          {activeTab === 'details' && (
            <DetailsPanel workOrder={workOrder} woType={woType} national={national} />
          )}
          {activeTab === 'category' && (
            <CategoryPanel
              workOrder={workOrder}
              category={category}
              winterRecords={woWinterRecords}
              debrisEstimates={woDebrisEstimates}
              utilities={utilities.filter(u => u.propertyId === workOrder.propertyId)}
              onCreateWinterRecord={createWinterRecord}
              onCreateDebrisEstimate={createDebrisEstimate}
              onCreateUtility={createUtility}
              onUpdateUtility={updateUtility}
            />
          )}
          {activeTab === 'photos' && (
            <PhotosPanel category={category} workOrder={workOrder} national={national} />
          )}
          {activeTab === 'chargeback' && (
            <ChargebackPanel
              workOrder={workOrder}
              chargebacks={woChargebacks}
              score={chargebackScore}
              winterRecordCount={woWinterRecords.length}
              debrisEstimateCount={woDebrisEstimates.length}
            />
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-4">
          {/* Work Order Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-sm">Work Order Info</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted">Status</span>
                <Badge className={cn('text-xs', statusConf.color, statusConf.bg)}>{statusConf.label}</Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-muted">Category</span>
                <span className="text-main">{CATEGORY_LABELS[category] || category}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted">Photo Mode</span>
                <span className="text-main capitalize">{workOrder.photoMode.replace('_', ' ')}</span>
              </div>
              {workOrder.assignedTo && (
                <div className="flex justify-between">
                  <span className="text-muted">Assigned To</span>
                  <span className="text-main">{workOrder.assignedTo}</span>
                </div>
              )}
              {workOrder.startedAt && (
                <div className="flex justify-between">
                  <span className="text-muted">Started</span>
                  <span className="text-main">{formatDate(workOrder.startedAt)}</span>
                </div>
              )}
              {workOrder.completedAt && (
                <div className="flex justify-between">
                  <span className="text-muted">Completed</span>
                  <span className="text-main">{formatDate(workOrder.completedAt)}</span>
                </div>
              )}
              {workOrder.submittedAt && (
                <div className="flex justify-between">
                  <span className="text-muted">Submitted</span>
                  <span className="text-main">{formatDate(workOrder.submittedAt)}</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* National Company */}
          {national && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm flex items-center gap-2">
                  <Building2 size={14} className="text-muted" />
                  {national.name}
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-sm">
                {national.submissionDeadlineHours > 0 && (
                  <div className="flex justify-between">
                    <span className="text-muted">Deadline</span>
                    <span className="text-main">{national.submissionDeadlineHours}h</span>
                  </div>
                )}
                {national.paySchedule && (
                  <div className="flex justify-between">
                    <span className="text-muted">Pay</span>
                    <span className="text-main capitalize">{national.paySchedule}</span>
                  </div>
                )}
                {national.phone && (
                  <div className="flex justify-between">
                    <span className="text-muted">Phone</span>
                    <span className="text-main">{national.phone}</span>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Notes */}
          {workOrder.notes && (
            <Card>
              <CardHeader>
                <CardTitle className="text-sm">Notes</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-main whitespace-pre-wrap">{workOrder.notes}</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Details Panel ──

function DetailsPanel({ workOrder, woType, national }: {
  workOrder: PpWorkOrder;
  woType: { name: string; category: string; description: string | null; estimatedHours: number | null; defaultChecklist: unknown[]; requiredPhotos: unknown[] } | null;
  national: { name: string; submissionDeadlineHours: number; phone: string | null; email: string | null; portalUrl: string | null } | null;
}) {
  const checklist = workOrder.checklistProgress || {};
  const checklistKeys = Object.keys(checklist);
  const completedCount = Object.values(checklist).filter(v => v === true).length;

  return (
    <div className="space-y-4">
      {/* Type Description */}
      {woType?.description && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Work Order Type</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-main">{woType.description}</p>
            {woType.estimatedHours && (
              <p className="text-xs text-muted mt-2">Estimated: {woType.estimatedHours} hours</p>
            )}
          </CardContent>
        </Card>
      )}

      {/* Checklist Progress */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Checklist</CardTitle>
            {checklistKeys.length > 0 && (
              <span className="text-xs text-muted">{completedCount}/{checklistKeys.length} complete</span>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {checklistKeys.length === 0 ? (
            <p className="text-sm text-muted text-center py-4">No checklist items configured for this work order type</p>
          ) : (
            <div className="space-y-2">
              {/* Progress bar */}
              <div className="w-full bg-secondary rounded-full h-2 mb-4">
                <div
                  className="bg-emerald-500 h-2 rounded-full transition-all"
                  style={{ width: `${checklistKeys.length > 0 ? (completedCount / checklistKeys.length) * 100 : 0}%` }}
                />
              </div>
              {checklistKeys.map(key => (
                <div key={key} className="flex items-center gap-3 py-1">
                  <div className={cn(
                    'w-5 h-5 rounded border-2 flex items-center justify-center',
                    checklist[key] === true ? 'bg-emerald-500/20 border-emerald-500' : 'border-muted'
                  )}>
                    {checklist[key] === true && <CheckCircle size={12} className="text-emerald-400" />}
                  </div>
                  <span className={cn('text-sm', checklist[key] === true ? 'text-muted line-through' : 'text-main')}>
                    {key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </span>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Timeline */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Timeline</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {workOrder.assignedAt && (
              <TimelineItem date={workOrder.assignedAt} label="Assigned" color="text-blue-400" />
            )}
            {workOrder.startedAt && (
              <TimelineItem date={workOrder.startedAt} label="Work Started" color="text-yellow-400" />
            )}
            {workOrder.completedAt && (
              <TimelineItem date={workOrder.completedAt} label="Completed" color="text-emerald-400" />
            )}
            {workOrder.submittedAt && (
              <TimelineItem date={workOrder.submittedAt} label="Submitted to National" color="text-purple-400" />
            )}
            {!workOrder.assignedAt && !workOrder.startedAt && (
              <p className="text-sm text-muted text-center py-4">No timeline events yet</p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function TimelineItem({ date, label, color }: { date: string; label: string; color: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className={cn('w-2 h-2 rounded-full', color.replace('text-', 'bg-'))} />
      <div className="flex-1 flex items-center justify-between">
        <span className={cn('text-sm font-medium', color)}>{label}</span>
        <span className="text-xs text-muted">{formatDate(date)}</span>
      </div>
    </div>
  );
}

// ── Category-Specific Panel ──

function CategoryPanel({ workOrder, category, winterRecords, debrisEstimates, utilities, onCreateWinterRecord, onCreateDebrisEstimate, onCreateUtility, onUpdateUtility }: {
  workOrder: PpWorkOrder;
  category: string;
  winterRecords: PpWinterizationRecord[];
  debrisEstimates: PpDebrisEstimate[];
  utilities: PpUtilityTracking[];
  onCreateWinterRecord: (rec: Omit<PpWinterizationRecord, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onCreateDebrisEstimate: (est: Omit<PpDebrisEstimate, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onCreateUtility: (u: Omit<PpUtilityTracking, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onUpdateUtility: (id: string, updatedAt: string, patch: Partial<PpUtilityTracking>) => Promise<void>;
}) {
  if (category === 'winterization') {
    return <WinterizationPanel workOrder={workOrder} records={winterRecords} onCreate={onCreateWinterRecord} />;
  }
  if (category === 'debris') {
    return <DebrisPanel workOrder={workOrder} estimates={debrisEstimates} onCreate={onCreateDebrisEstimate} />;
  }
  if (category === 'securing') {
    return <SecuringPanel workOrder={workOrder} />;
  }
  if (category === 'utility') {
    return <UtilityPanel workOrder={workOrder} utilities={utilities} onCreate={onCreateUtility} onUpdate={onUpdateUtility} />;
  }

  // Generic panel for lawn_snow, inspection, repair, specialty
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          {CATEGORY_LABELS[category] || category} Details
        </CardTitle>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted">
          Use the checklist on the Details tab to track completion of {CATEGORY_LABELS[category]?.toLowerCase() || category} tasks.
          Document everything with photos on the Photos tab.
        </p>
      </CardContent>
    </Card>
  );
}

// ── Winterization Panel ──

function WinterizationPanel({ workOrder, records, onCreate }: {
  workOrder: PpWorkOrder;
  records: PpWinterizationRecord[];
  onCreate: (rec: Omit<PpWinterizationRecord, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
}) {
  const [showForm, setShowForm] = useState(records.length === 0);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    heatType: 'gas',
    hasWell: false,
    hasSeptic: false,
    hasSprinkler: false,
    pressureTestStartPsi: '35',
    pressureTestEndPsi: '',
    pressureTestDurationMin: '30',
    antifreezeGallons: '2',
    fixtureCount: '',
    notes: '',
    checklist: Object.fromEntries(WINTERIZATION_CHECKLIST.map(k => [k, false])),
  });

  const handleSave = async () => {
    setSaving(true);
    try {
      await onCreate({
        companyId: workOrder.companyId,
        workOrderId: workOrder.id,
        propertyId: workOrder.propertyId,
        recordType: 'winterization',
        heatType: form.heatType,
        hasWell: form.hasWell,
        hasSeptic: form.hasSeptic,
        hasSprinkler: form.hasSprinkler,
        pressureTestStartPsi: form.pressureTestStartPsi ? Number(form.pressureTestStartPsi) : null,
        pressureTestEndPsi: form.pressureTestEndPsi ? Number(form.pressureTestEndPsi) : null,
        pressureTestDurationMin: Number(form.pressureTestDurationMin) || 30,
        pressureTestPassed: form.pressureTestEndPsi ? Number(form.pressureTestEndPsi) >= (Number(form.pressureTestStartPsi) - 2) : null,
        antifreezeGallons: form.antifreezeGallons ? Number(form.antifreezeGallons) : null,
        fixtureCount: form.fixtureCount ? Number(form.fixtureCount) : null,
        checklistData: form.checklist,
        completedBy: null,
        completedAt: null,
        certificateUrl: null,
        notes: form.notes || null,
      });
      setShowForm(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Existing Records */}
      {records.map(rec => (
        <Card key={rec.id}>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Snowflake size={16} className="text-blue-400" />
              Winterization Record
              {rec.pressureTestPassed === true && (
                <Badge variant="success" className="text-xs">Test Passed</Badge>
              )}
              {rec.pressureTestPassed === false && (
                <Badge variant="error" className="text-xs">Test Failed</Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
              {rec.heatType && (
                <div>
                  <span className="text-xs text-muted block">Heat Type</span>
                  <span className="text-main capitalize">{rec.heatType}</span>
                </div>
              )}
              {rec.pressureTestStartPsi != null && (
                <div>
                  <span className="text-xs text-muted block">Pressure Start</span>
                  <span className="text-main">{rec.pressureTestStartPsi} PSI</span>
                </div>
              )}
              {rec.pressureTestEndPsi != null && (
                <div>
                  <span className="text-xs text-muted block">Pressure End</span>
                  <span className="text-main">{rec.pressureTestEndPsi} PSI</span>
                </div>
              )}
              <div>
                <span className="text-xs text-muted block">Duration</span>
                <span className="text-main">{rec.pressureTestDurationMin} min</span>
              </div>
              {rec.antifreezeGallons != null && (
                <div>
                  <span className="text-xs text-muted block">Antifreeze</span>
                  <span className="text-main">{rec.antifreezeGallons} gal</span>
                </div>
              )}
              {rec.fixtureCount != null && (
                <div>
                  <span className="text-xs text-muted block">Fixtures</span>
                  <span className="text-main">{rec.fixtureCount}</span>
                </div>
              )}
            </div>
            <div className="flex gap-4 mt-3 text-xs text-muted">
              {rec.hasWell && <span>Has Well</span>}
              {rec.hasSeptic && <span>Has Septic</span>}
              {rec.hasSprinkler && <span>Has Sprinkler</span>}
            </div>
          </CardContent>
        </Card>
      ))}

      {/* Add Form */}
      {showForm && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">New Winterization Record</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Heat Type */}
            <div>
              <label className="block text-xs font-medium text-muted mb-1">Heating System Type</label>
              <select
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                value={form.heatType}
                onChange={e => setForm(f => ({ ...f, heatType: e.target.value }))}
              >
                <option value="gas">Gas (Dry Heat)</option>
                <option value="electric">Electric</option>
                <option value="oil">Oil</option>
                <option value="propane">Propane</option>
                <option value="radiant">Wet/Radiant Heat</option>
                <option value="steam">Steam</option>
                <option value="none">No Heating System</option>
              </select>
              {form.heatType === 'gas' && (
                <p className="text-xs text-blue-400 mt-1">Dry heat: 35 PSI, hold 30 min</p>
              )}
              {form.heatType === 'radiant' && (
                <p className="text-xs text-blue-400 mt-1">Wet/Radiant: 53 PSI heating system, antifreeze all lines</p>
              )}
              {form.heatType === 'steam' && (
                <p className="text-xs text-blue-400 mt-1">Steam: Close valves at BOTTOM of radiators</p>
              )}
            </div>

            {/* Property Features */}
            <div className="flex gap-4">
              <label className="flex items-center gap-2 text-sm text-main">
                <input type="checkbox" checked={form.hasWell} onChange={e => setForm(f => ({ ...f, hasWell: e.target.checked }))} />
                Has Well
              </label>
              <label className="flex items-center gap-2 text-sm text-main">
                <input type="checkbox" checked={form.hasSeptic} onChange={e => setForm(f => ({ ...f, hasSeptic: e.target.checked }))} />
                Has Septic
              </label>
              <label className="flex items-center gap-2 text-sm text-main">
                <input type="checkbox" checked={form.hasSprinkler} onChange={e => setForm(f => ({ ...f, hasSprinkler: e.target.checked }))} />
                Has Sprinkler
              </label>
            </div>

            {/* Pressure Test */}
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Start PSI</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={form.pressureTestStartPsi}
                  onChange={e => setForm(f => ({ ...f, pressureTestStartPsi: e.target.value }))}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">End PSI</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={form.pressureTestEndPsi}
                  onChange={e => setForm(f => ({ ...f, pressureTestEndPsi: e.target.value }))}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Duration (min)</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={form.pressureTestDurationMin}
                  onChange={e => setForm(f => ({ ...f, pressureTestDurationMin: e.target.value }))}
                />
              </div>
            </div>

            {/* Antifreeze */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Antifreeze (gallons)</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={form.antifreezeGallons}
                  onChange={e => setForm(f => ({ ...f, antifreezeGallons: e.target.value }))}
                />
                <p className="text-xs text-muted mt-1">Pink RV propylene glycol ONLY</p>
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Fixture Count</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={form.fixtureCount}
                  onChange={e => setForm(f => ({ ...f, fixtureCount: e.target.value }))}
                />
              </div>
            </div>

            {/* Winterization Checklist */}
            <div>
              <label className="block text-xs font-medium text-muted mb-2">Winterization Checklist</label>
              <div className="grid grid-cols-2 gap-2">
                {WINTERIZATION_CHECKLIST.map(item => (
                  <label key={item} className="flex items-center gap-2 text-sm text-main">
                    <input
                      type="checkbox"
                      checked={!!form.checklist[item]}
                      onChange={e => setForm(f => ({
                        ...f,
                        checklist: { ...f.checklist, [item]: e.target.checked },
                      }))}
                    />
                    {WINTERIZATION_LABELS[item] || item}
                  </label>
                ))}
              </div>
            </div>

            {/* Notes */}
            <div>
              <label className="block text-xs font-medium text-muted mb-1">Notes</label>
              <textarea
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm h-20 resize-none"
                value={form.notes}
                onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
              />
            </div>

            <div className="flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setShowForm(false)}>Cancel</Button>
              <Button onClick={handleSave} disabled={saving}>
                {saving ? <><Loader2 size={14} className="animate-spin" /> Saving...</> : <><Save size={14} /> Save Record</>}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {!showForm && (
        <Button variant="secondary" onClick={() => setShowForm(true)}>
          <Plus size={14} />
          Add Winterization Record
        </Button>
      )}
    </div>
  );
}

// ── Debris Panel ──

const DEBRIS_RATES: Record<string, { min: number; max: number }> = {
  broom_clean: { min: 0.5, max: 1.0 },
  normal: { min: 1.5, max: 3.0 },
  heavy: { min: 3.0, max: 5.0 },
  hoarder: { min: 5.0, max: 10.0 },
};

const DUMPSTER_SIZES = [
  { max: 10, label: 'Trailer', cost: '$100-200' },
  { max: 15, label: '10-yd Dumpster', cost: '$220-580' },
  { max: 25, label: '20-yd Dumpster', cost: '$280-700' },
  { max: 35, label: '30-yd Dumpster', cost: '$311-718' },
  { max: Infinity, label: '40-yd Dumpster', cost: '$350-780' },
];

function DebrisPanel({ workOrder, estimates, onCreate }: {
  workOrder: PpWorkOrder;
  estimates: PpDebrisEstimate[];
  onCreate: (est: Omit<PpDebrisEstimate, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
}) {
  const [showCalc, setShowCalc] = useState(estimates.length === 0);
  const [saving, setSaving] = useState(false);
  const [sqft, setSqft] = useState('');
  const [level, setLevel] = useState('normal');
  const [hudRate, setHudRate] = useState('40');

  const calcResults = useMemo(() => {
    const area = Number(sqft) || 0;
    const rate = DEBRIS_RATES[level] || DEBRIS_RATES.normal;
    const minCy = (area / 100) * rate.min;
    const maxCy = (area / 100) * rate.max;
    const avgCy = (minCy + maxCy) / 2;
    const dumpster = DUMPSTER_SIZES.find(d => avgCy <= d.max) || DUMPSTER_SIZES[DUMPSTER_SIZES.length - 1];
    const hudRevenue = avgCy * (Number(hudRate) || 40);
    const preApproval = avgCy > 12;
    return { minCy, maxCy, avgCy, dumpster, hudRevenue, preApproval };
  }, [sqft, level, hudRate]);

  const handleSaveEstimate = async () => {
    setSaving(true);
    try {
      await onCreate({
        companyId: workOrder.companyId,
        workOrderId: workOrder.id,
        propertyId: workOrder.propertyId,
        estimationMethod: 'sqft',
        roomsData: [],
        propertySqft: Number(sqft) || null,
        cleanoutLevel: level,
        hoardingLevel: level === 'hoarder' ? 4 : null,
        totalCubicYards: Math.round(calcResults.avgCy * 10) / 10,
        estimatedWeightLbs: Math.round(calcResults.avgCy * 300),
        recommendedDumpsterSize: calcResults.dumpster.max === Infinity ? 40 : calcResults.dumpster.max,
        dumpsterPulls: Math.ceil(calcResults.avgCy / 20),
        hudRatePerCy: Number(hudRate) || null,
        estimatedRevenue: Math.round(calcResults.hudRevenue),
        estimatedCost: null,
        notes: null,
      });
      setShowCalc(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Existing Estimates */}
      {estimates.map(est => (
        <Card key={est.id}>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Trash2 size={16} className="text-orange-400" />
              Debris Estimate
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
              <div>
                <span className="text-xs text-muted block">Total CY</span>
                <span className="text-main text-lg font-bold">{est.totalCubicYards ?? '--'}</span>
              </div>
              <div>
                <span className="text-xs text-muted block">Est. Weight</span>
                <span className="text-main">{est.estimatedWeightLbs ? `${est.estimatedWeightLbs.toLocaleString()} lbs` : '--'}</span>
              </div>
              <div>
                <span className="text-xs text-muted block">Dumpster</span>
                <span className="text-main">{est.recommendedDumpsterSize ? `${est.recommendedDumpsterSize}-yd` : '--'}</span>
              </div>
              {est.hudRatePerCy != null && (
                <div>
                  <span className="text-xs text-muted block">HUD Rate</span>
                  <span className="text-main">{formatCurrency(est.hudRatePerCy)}/CY</span>
                </div>
              )}
              {est.estimatedRevenue != null && (
                <div>
                  <span className="text-xs text-muted block">Est. Revenue</span>
                  <span className="text-emerald-400 font-bold">{formatCurrency(est.estimatedRevenue)}</span>
                </div>
              )}
              {(est.totalCubicYards ?? 0) > 12 && (
                <div>
                  <Badge variant="warning" className="text-xs">Pre-approval Required ({'>'} 12 CY)</Badge>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      ))}

      {/* Calculator */}
      {showCalc && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Debris Estimation Calculator</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Property Sq Ft</label>
                <input
                  type="number"
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  placeholder="1200"
                  value={sqft}
                  onChange={e => setSqft(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Cleanout Level</label>
                <select
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm"
                  value={level}
                  onChange={e => setLevel(e.target.value)}
                >
                  <option value="broom_clean">Broom Clean (0.5-1.0 CY/100sf)</option>
                  <option value="normal">Normal (1.5-3.0 CY/100sf)</option>
                  <option value="heavy">Heavy (3.0-5.0 CY/100sf)</option>
                  <option value="hoarder">Hoarder (5.0-10.0 CY/100sf)</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-muted mb-1">HUD Rate ($/CY)</label>
              <input
                type="number"
                className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-main text-sm max-w-xs"
                value={hudRate}
                onChange={e => setHudRate(e.target.value)}
              />
            </div>

            {Number(sqft) > 0 && (
              <div className="p-4 bg-secondary rounded-lg space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Estimated CY</span>
                  <span className="text-main font-bold">{calcResults.minCy.toFixed(1)} - {calcResults.maxCy.toFixed(1)} CY</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Average</span>
                  <span className="text-main font-bold">{calcResults.avgCy.toFixed(1)} CY</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Recommended</span>
                  <span className="text-main">{calcResults.dumpster.label} ({calcResults.dumpster.cost})</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted">Est. Revenue</span>
                  <span className="text-emerald-400 font-bold">{formatCurrency(calcResults.hudRevenue)}</span>
                </div>
                {calcResults.preApproval && (
                  <div className="flex items-center gap-2 text-xs text-orange-400 mt-2">
                    <AlertTriangle size={12} />
                    Exceeds 12 CY — pre-approval required from national
                  </div>
                )}
              </div>
            )}

            <div className="flex justify-end gap-3">
              <Button variant="secondary" onClick={() => setShowCalc(false)}>Cancel</Button>
              <Button onClick={handleSaveEstimate} disabled={saving || !sqft}>
                {saving ? <><Loader2 size={14} className="animate-spin" /> Saving...</> : <><Save size={14} /> Save Estimate</>}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {!showCalc && (
        <Button variant="secondary" onClick={() => setShowCalc(true)}>
          <Plus size={14} />
          New Debris Estimate
        </Button>
      )}
    </div>
  );
}

// ── Securing Panel ──

function SecuringPanel({ workOrder }: { workOrder: PpWorkOrder }) {
  const checklist = workOrder.checklistProgress || {};

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Shield size={16} className="text-blue-400" />
            Securing Checklist
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {SECURING_CHECKLIST.map(item => (
              <div key={item} className="flex items-center gap-3 py-1">
                <div className={cn(
                  'w-5 h-5 rounded border-2 flex items-center justify-center',
                  checklist[item] === true ? 'bg-emerald-500/20 border-emerald-500' : 'border-muted'
                )}>
                  {checklist[item] === true && <CheckCircle size={12} className="text-emerald-400" />}
                </div>
                <span className={cn('text-sm', checklist[item] === true ? 'text-muted line-through' : 'text-main')}>
                  {SECURING_LABELS[item] || item}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Lock Code Reference */}
      <Card>
        <CardHeader>
          <CardTitle className="text-sm">Common Bank Key Codes</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-5 gap-2">
            {['13226', '14334', '21121', '23323', '35241', '35453', '44535', '64445', '67767', '76667'].map(code => (
              <div key={code} className="text-center p-2 bg-secondary rounded-lg">
                <span className="text-sm font-mono text-main">{code}</span>
              </div>
            ))}
          </div>
          <p className="text-xs text-muted mt-2">Standard KW-1 bank lock codes. Verify with national for property-specific codes.</p>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Utility Panel ──

function UtilityPanel({ workOrder, utilities, onCreate, onUpdate }: {
  workOrder: PpWorkOrder;
  utilities: PpUtilityTracking[];
  onCreate: (u: Omit<PpUtilityTracking, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  onUpdate: (id: string, updatedAt: string, patch: Partial<PpUtilityTracking>) => Promise<void>;
}) {
  const utilityTypes = ['electric', 'gas', 'water', 'oil', 'propane'] as const;

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Zap size={16} className="text-yellow-400" />
            Utility Status
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-main/50">
            {utilityTypes.map(type => {
              const util = utilities.find(u => u.utilityType === type);
              const statusColors: Record<string, string> = {
                on: 'text-emerald-400',
                off: 'text-red-400',
                meter_pulled: 'text-orange-400',
                winterized: 'text-blue-400',
                unknown: 'text-muted',
              };
              return (
                <div key={type} className="px-5 py-3 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    {type === 'electric' && <Zap size={14} className="text-yellow-400" />}
                    {type === 'gas' && <Thermometer size={14} className="text-orange-400" />}
                    {type === 'water' && <Droplets size={14} className="text-blue-400" />}
                    {type === 'oil' && <Thermometer size={14} className="text-amber-400" />}
                    {type === 'propane' && <Thermometer size={14} className="text-red-400" />}
                    <span className="text-sm font-medium text-main capitalize">{type}</span>
                  </div>
                  {util ? (
                    <div className="flex items-center gap-3">
                      <span className={cn('text-sm font-medium capitalize', statusColors[util.status] || 'text-muted')}>
                        {util.status.replace('_', ' ')}
                      </span>
                      {util.providerName && (
                        <span className="text-xs text-muted">{util.providerName}</span>
                      )}
                    </div>
                  ) : (
                    <span className="text-xs text-muted">Not tracked</span>
                  )}
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Photos Panel ──

function PhotosPanel({ category, workOrder, national }: {
  category: string;
  workOrder: PpWorkOrder;
  national: { name: string; photoNaming: string | null; requiredShots: Record<string, unknown> } | null;
}) {
  const requiredPhotos = REQUIRED_PHOTOS[category] || [];

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Camera size={16} className="text-blue-400" />
            Photo Documentation
            <Badge variant="default" className="text-xs ml-auto capitalize">{workOrder.photoMode.replace('_', ' ')}</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted mb-4">
            Required photos for {CATEGORY_LABELS[category]?.toLowerCase() || category} work orders.
            GPS-stamped photos are mandatory for chargeback protection.
          </p>

          {/* Required shots checklist */}
          <div className="space-y-2">
            {requiredPhotos.map(photo => (
              <div key={photo} className="flex items-center gap-3 py-1">
                <div className="w-5 h-5 rounded border-2 border-muted flex items-center justify-center">
                  <Camera size={10} className="text-muted" />
                </div>
                <span className="text-sm text-main">{photo}</span>
              </div>
            ))}
          </div>

          {national?.photoNaming && (
            <div className="mt-4 p-3 bg-secondary rounded-lg">
              <p className="text-xs font-medium text-muted mb-1">National Photo Naming Convention</p>
              <p className="text-sm text-main">{national.photoNaming}</p>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-6 text-center">
          <Camera size={32} className="mx-auto text-muted mb-2 opacity-30" />
          <p className="text-sm text-muted">Photo upload coming soon</p>
          <p className="text-xs text-muted mt-1">Use the Zafto mobile app to capture GPS-stamped photos in the field</p>
        </CardContent>
      </Card>
    </div>
  );
}

// ── Chargeback Protection Panel ──

function ChargebackPanel({ workOrder, chargebacks, score, winterRecordCount, debrisEstimateCount }: {
  workOrder: PpWorkOrder;
  chargebacks: PpChargeback[];
  score: number;
  winterRecordCount: number;
  debrisEstimateCount: number;
}) {
  const checklist = workOrder.checklistProgress || {};
  const checklistItems = Object.keys(checklist).length;
  const checklistComplete = Object.values(checklist).filter(v => v === true).length;

  const protectionItems = [
    { label: 'External Order ID', done: !!workOrder.externalOrderId, weight: 'Ties to national' },
    { label: 'Bid Amount Set', done: workOrder.bidAmount != null && workOrder.bidAmount > 0, weight: 'Revenue tracking' },
    { label: 'Notes Documented', done: !!workOrder.notes, weight: 'Written record' },
    { label: 'Checklist Progress', done: checklistItems > 0 && checklistComplete >= checklistItems * 0.5, weight: `${checklistComplete}/${checklistItems}` },
    { label: 'Category Records', done: winterRecordCount > 0 || debrisEstimateCount > 0, weight: 'Detailed work data' },
    { label: 'Status Advanced', done: ['completed', 'submitted', 'approved'].includes(workOrder.status), weight: 'Workflow tracked' },
  ];

  return (
    <div className="space-y-4">
      {/* Score Card */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Shield size={16} className="text-blue-400" />
            Chargeback Protection Score
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-4 mb-4">
            <div className={cn(
              'text-4xl font-bold',
              score >= 80 ? 'text-emerald-400' : score >= 50 ? 'text-yellow-400' : 'text-red-400'
            )}>
              {score}%
            </div>
            <div>
              <p className={cn(
                'text-sm font-medium',
                score >= 80 ? 'text-emerald-400' : score >= 50 ? 'text-yellow-400' : 'text-red-400'
              )}>
                {score >= 80 ? 'Strong Protection' : score >= 50 ? 'Moderate Protection' : 'Weak Protection'}
              </p>
              <p className="text-xs text-muted">Document everything to protect against chargebacks</p>
            </div>
          </div>

          {/* Progress bar */}
          <div className="w-full bg-secondary rounded-full h-3 mb-4">
            <div
              className={cn(
                'h-3 rounded-full transition-all',
                score >= 80 ? 'bg-emerald-500' : score >= 50 ? 'bg-yellow-500' : 'bg-red-500'
              )}
              style={{ width: `${score}%` }}
            />
          </div>

          {/* Protection Items */}
          <div className="space-y-2">
            {protectionItems.map(item => (
              <div key={item.label} className="flex items-center gap-3 py-1">
                <div className={cn(
                  'w-5 h-5 rounded-full flex items-center justify-center',
                  item.done ? 'bg-emerald-500/20' : 'bg-secondary'
                )}>
                  {item.done ? (
                    <CheckCircle size={12} className="text-emerald-400" />
                  ) : (
                    <X size={10} className="text-muted" />
                  )}
                </div>
                <span className={cn('text-sm flex-1', item.done ? 'text-main' : 'text-muted')}>{item.label}</span>
                <span className="text-xs text-muted">{item.weight}</span>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Chargebacks on this WO */}
      {chargebacks.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <AlertTriangle size={16} className="text-red-400" />
              Chargebacks ({chargebacks.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-main/50">
              {chargebacks.map(cb => (
                <div key={cb.id} className="px-5 py-3">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium text-red-400">{formatCurrency(cb.amount)}</span>
                    <Badge variant={
                      cb.disputeStatus === 'resolved_won' ? 'success' :
                      cb.disputeStatus === 'resolved_lost' || cb.disputeStatus === 'denied' ? 'error' :
                      cb.disputeStatus === 'submitted' || cb.disputeStatus === 'under_review' ? 'warning' : 'default'
                    } className="text-xs">
                      {cb.disputeStatus.replace('_', ' ')}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted">{cb.reason}</p>
                  <p className="text-xs text-muted mt-0.5">{formatDate(cb.chargebackDate)}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
