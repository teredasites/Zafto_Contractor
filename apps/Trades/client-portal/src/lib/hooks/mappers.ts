// Client Portal data types and mappers
// Maps Supabase DB rows → TypeScript interfaces

// ==================== JOB TYPES ====================

export type JobType = 'standard' | 'insurance_claim' | 'warranty_dispatch';

export const JOB_TYPE_LABELS: Record<JobType, string> = {
  standard: 'Standard',
  insurance_claim: 'Insurance Claim',
  warranty_dispatch: 'Warranty Dispatch',
};

export interface ProjectData {
  id: string;
  name: string;
  contractor: string;
  trade: string;
  status: 'active' | 'scheduled' | 'completed' | 'on_hold';
  progress: number;
  lastUpdate: string;
  totalCost: number;
  startDate: string | null;
  endDate: string | null;
  description: string;
  address: string;
  city: string;
  state: string;
  jobType: JobType;
  typeMetadata: Record<string, unknown>;
  assignedUserIds: string[];
  scheduledStart: string | null;
  rawStatus: string;
}

export interface InvoiceData {
  id: string;
  number: string;
  project: string;
  projectId: string | null;
  amount: number;
  amountDue: number;
  status: 'due' | 'overdue' | 'paid' | 'partial';
  dueDate: string | null;
  paidDate: string | null;
  createdAt: string;
  lineItems: Array<{ description: string; quantity: number; unitPrice: number; total: number }>;
}

export interface BidData {
  id: string;
  number: string;
  title: string;
  totalAmount: number;
  status: string;
  createdAt: string;
  expiresAt: string | null;
  description: string;
}

export interface ChangeOrderData {
  id: string;
  orderNumber: string;
  title: string;
  description: string;
  amount: number;
  status: string;
  jobTitle: string;
  createdAt: string;
}

export interface MessageData {
  id: string;
  content: string;
  senderName: string;
  senderId: string;
  isClient: boolean;
  createdAt: string;
  readAt: string | null;
}

// DB status → client-friendly status
const JOB_STATUS_MAP: Record<string, ProjectData['status']> = {
  draft: 'scheduled',
  scheduled: 'scheduled',
  dispatched: 'active',
  en_route: 'active',
  in_progress: 'active',
  inProgress: 'active',
  on_hold: 'on_hold',
  onHold: 'on_hold',
  completed: 'completed',
  invoiced: 'completed',
  cancelled: 'completed',
};

const INVOICE_STATUS_MAP: Record<string, InvoiceData['status']> = {
  draft: 'due',
  sent: 'due',
  viewed: 'due',
  overdue: 'overdue',
  partially_paid: 'partial',
  partiallyPaid: 'partial',
  paid: 'paid',
  voided: 'paid',
};

export function mapProject(row: Record<string, unknown>): ProjectData {
  const status = JOB_STATUS_MAP[row.status as string] || 'scheduled';
  const progress = status === 'completed' ? 100
    : 0;

  return {
    id: row.id as string,
    name: row.title as string || '',
    contractor: row.customer_name as string || '',
    trade: (row.tags as string[])?.[0] || '',
    status,
    progress,
    lastUpdate: formatRelative(row.updated_at as string),
    totalCost: (row.estimated_amount as number) || 0,
    startDate: row.scheduled_start as string || null,
    endDate: row.scheduled_end as string || null,
    description: row.description as string || '',
    address: row.address as string || '',
    city: row.city as string || '',
    state: row.state as string || '',
    jobType: ((row.job_type as string) || 'standard') as JobType,
    typeMetadata: (row.type_metadata as Record<string, unknown>) || {},
    assignedUserIds: Array.isArray(row.assigned_user_ids) ? row.assigned_user_ids as string[] : [],
    scheduledStart: (row.scheduled_start as string) || null,
    rawStatus: (row.status as string) || 'draft',
  };
}

export function mapInvoice(row: Record<string, unknown>): InvoiceData {
  const status = INVOICE_STATUS_MAP[row.status as string] || 'due';
  const dueDate = row.due_date as string || null;

  // Check if overdue
  let finalStatus = status;
  if (status === 'due' && dueDate && new Date(dueDate) < new Date()) {
    finalStatus = 'overdue';
  }

  return {
    id: row.id as string,
    number: row.invoice_number as string || '',
    project: (row as Record<string, Record<string, unknown>>).jobs?.title as string || '',
    projectId: row.job_id as string || null,
    amount: (row.total as number) || 0,
    amountDue: (row.amount_due as number) || 0,
    status: finalStatus,
    dueDate,
    paidDate: row.paid_at as string || null,
    createdAt: row.created_at as string || '',
    lineItems: Array.isArray(row.line_items) ? row.line_items as InvoiceData['lineItems'] : [],
  };
}

export function mapBid(row: Record<string, unknown>): BidData {
  return {
    id: row.id as string,
    number: row.bid_number as string || '',
    title: row.title as string || '',
    totalAmount: (row.total as number) || 0,
    status: row.status as string || 'draft',
    createdAt: row.created_at as string || '',
    expiresAt: row.valid_until as string || null,
    description: row.scope_of_work as string || '',
  };
}

export function mapChangeOrder(row: Record<string, unknown>): ChangeOrderData {
  return {
    id: row.id as string,
    orderNumber: row.change_order_number as string || '',
    title: row.title as string || '',
    description: row.description as string || '',
    amount: (row.amount as number) || 0,
    status: row.status as string || 'draft',
    jobTitle: (row as Record<string, Record<string, unknown>>).jobs?.title as string || '',
    createdAt: row.created_at as string || '',
  };
}

// ==================== ESTIMATES ====================

export type EstimateStatus = 'draft' | 'sent' | 'approved' | 'declined' | 'revised' | 'completed';

export const ESTIMATE_STATUS_LABELS: Record<EstimateStatus, string> = {
  draft: 'Draft',
  sent: 'Pending Review',
  approved: 'Approved',
  declined: 'Declined',
  revised: 'Revised',
  completed: 'Completed',
};

export interface EstimateData {
  id: string;
  jobId: string | null;
  estimateNumber: string;
  title: string;
  estimateType: 'regular' | 'insurance';
  status: EstimateStatus;
  customerName: string;
  propertyAddress: string;
  subtotal: number;
  overheadAmount: number;
  profitAmount: number;
  taxAmount: number;
  grandTotal: number;
  notes: string;
  validUntil: string | null;
  sentAt: string | null;
  approvedAt: string | null;
  declinedAt: string | null;
  createdAt: string;
}

export interface EstimateAreaData {
  id: string;
  name: string;
  floorSf: number;
  sortOrder: number;
}

export interface EstimateLineItemData {
  id: string;
  areaId: string | null;
  description: string;
  actionType: string;
  quantity: number;
  unitCode: string;
  unitPrice: number;
  lineTotal: number;
}

export function mapEstimate(row: Record<string, unknown>): EstimateData {
  return {
    id: row.id as string,
    jobId: row.job_id as string | null,
    estimateNumber: (row.estimate_number as string) || '',
    title: (row.title as string) || '',
    estimateType: (row.estimate_type as 'regular' | 'insurance') || 'regular',
    status: (row.status as EstimateStatus) || 'draft',
    customerName: (row.customer_name as string) || '',
    propertyAddress: (row.property_address as string) || '',
    subtotal: Number(row.subtotal || 0),
    overheadAmount: Number(row.overhead_amount || 0),
    profitAmount: Number(row.profit_amount || 0),
    taxAmount: Number(row.tax_amount || 0),
    grandTotal: Number(row.grand_total || 0),
    notes: (row.notes as string) || '',
    validUntil: row.valid_until as string | null,
    sentAt: row.sent_at as string | null,
    approvedAt: row.approved_at as string | null,
    declinedAt: row.declined_at as string | null,
    createdAt: (row.created_at as string) || '',
  };
}

export function mapEstimateArea(row: Record<string, unknown>): EstimateAreaData {
  return {
    id: row.id as string,
    name: (row.name as string) || '',
    floorSf: Number(row.floor_sf || 0),
    sortOrder: Number(row.sort_order || 0),
  };
}

export function mapEstimateLineItem(row: Record<string, unknown>): EstimateLineItemData {
  return {
    id: row.id as string,
    areaId: row.area_id as string | null,
    description: (row.description as string) || '',
    actionType: (row.action_type as string) || 'replace',
    quantity: Number(row.quantity || 1),
    unitCode: (row.unit_code as string) || 'EA',
    unitPrice: Number(row.unit_price || 0),
    lineTotal: Number(row.line_total || 0),
  };
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
}

export function formatDate(dateStr: string | null): string {
  if (!dateStr) return '';
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatRelative(dateStr: string | null): string {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  if (diffDays < 7) return `${diffDays}d ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)}w ago`;
  return date.toLocaleDateString();
}
