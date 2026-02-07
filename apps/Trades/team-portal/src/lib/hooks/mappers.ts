// DB → TypeScript mappers for Team Portal
// Adapted from web-portal/src/lib/hooks/mappers.ts

export interface JobData {
  id: string;
  title: string;
  customerName: string;
  address: string;
  city: string;
  state: string;
  status: string;
  type: string;
  scheduledStart: string | null;
  scheduledEnd: string | null;
  description: string;
  assignedTo: string[];
  estimatedAmount: number;
  completedAt: string | null;
  createdAt: string;
}

export interface TimeEntryData {
  id: string;
  userId: string;
  jobId: string | null;
  clockIn: string;
  clockOut: string | null;
  status: string;
  breakMinutes: number;
  totalHours: number;
  notes: string;
  jobTitle?: string;
}

export interface MaterialData {
  id: string;
  jobId: string;
  name: string;
  description: string;
  category: string;
  quantity: number;
  unit: string;
  unitCost: number;
  totalCost: number;
  isBillable: boolean;
  vendor: string;
  createdAt: string;
}

export interface DailyLogData {
  id: string;
  jobId: string;
  logDate: string;
  weather: string;
  temperatureF: number | null;
  summary: string;
  workPerformed: string;
  issues: string;
  crewCount: number;
  hoursWorked: number;
  createdAt: string;
}

export interface PunchListItemData {
  id: string;
  jobId: string;
  title: string;
  description: string;
  category: string;
  priority: string;
  status: string;
  assignedTo: string | null;
  dueDate: string | null;
  completedAt: string | null;
  createdAt: string;
}

export interface ChangeOrderData {
  id: string;
  jobId: string;
  orderNumber: string;
  title: string;
  description: string;
  reason: string;
  amount: number;
  status: string;
  items: ChangeOrderItem[];
  jobTitle?: string;
  createdAt: string;
}

export interface ChangeOrderItem {
  description: string;
  quantity: number;
  unitPrice: number;
}

export interface BidData {
  id: string;
  bidNumber: string;
  customerName: string;
  title: string;
  status: string;
  totalAmount: number;
  createdAt: string;
}

export interface NotificationData {
  id: string;
  type: string;
  title: string;
  message: string;
  read: boolean;
  createdAt: string;
  data: Record<string, unknown>;
}

// --- Mappers ---

const JOB_STATUS_FROM_DB: Record<string, string> = {
  draft: 'draft', scheduled: 'scheduled', dispatched: 'dispatched',
  enRoute: 'en_route', en_route: 'en_route',
  inProgress: 'in_progress', in_progress: 'in_progress',
  onHold: 'on_hold', on_hold: 'on_hold',
  completed: 'completed', invoiced: 'invoiced', cancelled: 'cancelled',
};

export function mapJob(row: Record<string, unknown>): JobData {
  return {
    id: row.id as string,
    title: (row.title as string) || 'Untitled Job',
    customerName: (row.customer_name as string) || '',
    address: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    status: JOB_STATUS_FROM_DB[(row.status as string)] || (row.status as string) || 'draft',
    type: (row.type as string) || 'standard',
    scheduledStart: (row.scheduled_start as string) || null,
    scheduledEnd: (row.scheduled_end as string) || null,
    description: (row.description as string) || '',
    assignedTo: (row.assigned_to as string[]) || [],
    estimatedAmount: (row.estimated_amount as number) || 0,
    completedAt: (row.completed_at as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapTimeEntry(row: Record<string, unknown>): TimeEntryData {
  const clockIn = new Date(row.clock_in as string);
  const clockOut = row.clock_out ? new Date(row.clock_out as string) : null;
  const breakMins = (row.break_minutes as number) || 0;
  const totalMs = clockOut ? clockOut.getTime() - clockIn.getTime() : Date.now() - clockIn.getTime();
  const totalHours = Math.max(0, (totalMs / 3600000) - (breakMins / 60));

  return {
    id: row.id as string,
    userId: row.user_id as string,
    jobId: (row.job_id as string) || null,
    clockIn: row.clock_in as string,
    clockOut: (row.clock_out as string) || null,
    status: (row.status as string) || 'active',
    breakMinutes: breakMins,
    totalHours: Math.round(totalHours * 100) / 100,
    notes: (row.notes as string) || '',
    jobTitle: (row.jobs as Record<string, unknown>)?.title as string || undefined,
  };
}

export function mapMaterial(row: Record<string, unknown>): MaterialData {
  const qty = (row.quantity as number) || 0;
  const unitCost = (row.unit_cost as number) || 0;
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    name: (row.name as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || 'material',
    quantity: qty,
    unit: (row.unit as string) || 'each',
    unitCost,
    totalCost: qty * unitCost,
    isBillable: (row.is_billable as boolean) ?? true,
    vendor: (row.vendor as string) || '',
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapDailyLog(row: Record<string, unknown>): DailyLogData {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    logDate: row.log_date as string,
    weather: (row.weather as string) || '',
    temperatureF: (row.temperature_f as number) || null,
    summary: (row.summary as string) || '',
    workPerformed: (row.work_performed as string) || '',
    issues: (row.issues as string) || '',
    crewCount: (row.crew_count as number) || 0,
    hoursWorked: (row.hours_worked as number) || 0,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapPunchListItem(row: Record<string, unknown>): PunchListItemData {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || '',
    priority: (row.priority as string) || 'normal',
    status: (row.status as string) || 'open',
    assignedTo: (row.assigned_to as string) || null,
    dueDate: (row.due_date as string) || null,
    completedAt: (row.completed_at as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapChangeOrder(row: Record<string, unknown>): ChangeOrderData {
  const items = ((row.line_items as ChangeOrderItem[]) || []);
  const jobData = row.jobs as Record<string, unknown> | null;
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    orderNumber: (row.order_number as string) || '',
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    reason: (row.reason as string) || '',
    amount: (row.amount as number) || 0,
    status: (row.status as string) || 'draft',
    items,
    jobTitle: jobData?.title as string || undefined,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapBid(row: Record<string, unknown>): BidData {
  return {
    id: row.id as string,
    bidNumber: (row.bid_number as string) || '',
    customerName: (row.customer_name as string) || '',
    title: (row.title as string) || '',
    status: (row.status as string) || 'draft',
    totalAmount: (row.total_amount as number) || 0,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}
