// DB row → TypeScript type mappers
// Maps snake_case Supabase rows to camelCase TypeScript interfaces
import type { Customer, Job, JobType, Invoice, Bid, BidOption, TeamMember, Address, Activity } from '@/types';

// Local types for entities not yet in global types
export interface ChangeOrderItem {
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
}

export interface ChangeOrderData {
  id: string;
  companyId: string;
  jobId: string;
  jobName: string;
  customerName: string;
  number: string;
  title: string;
  description: string;
  reason: string;
  items: ChangeOrderItem[];
  amount: number;
  status: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'voided';
  approvedByName?: string;
  approvedAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface InspectionChecklistItem {
  id: string;
  label: string;
  completed: boolean;
  note?: string;
  photoRequired: boolean;
  hasPhoto: boolean;
}

export interface InspectionData {
  id: string;
  companyId: string;
  jobId: string;
  jobName: string;
  customerName: string;
  address: string;
  type: string;
  status: string;
  title: string;
  assignedTo: string;
  scheduledDate: Date;
  completedDate?: Date;
  checklist: InspectionChecklistItem[];
  overallScore?: number;
  notes?: string;
  photos: number;
  createdAt: Date;
}

export interface LeadData {
  id: string;
  companyId: string;
  createdByUserId: string;
  assignedToUserId?: string;
  name: string;
  email: string;
  phone: string;
  companyName?: string;
  source: string;
  stage: 'new' | 'contacted' | 'qualified' | 'proposal' | 'won' | 'lost';
  value: number;
  notes: string;
  address?: string;
  city?: string;
  state?: string;
  zipCode?: string;
  lastContactedAt?: Date;
  nextFollowUp?: Date;
  wonAt?: Date;
  lostAt?: Date;
  lostReason?: string;
  convertedToJobId?: string;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

// ==================== HELPERS ====================

function mapAddress(row: Record<string, unknown>): Address {
  return {
    street: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    zip: (row.zip_code as string) || '',
  };
}

function splitName(name: string): { firstName: string; lastName: string } {
  const parts = (name || '').trim().split(/\s+/);
  return {
    firstName: parts[0] || '',
    lastName: parts.slice(1).join(' ') || '',
  };
}

export function joinName(firstName: string, lastName: string): string {
  return `${firstName} ${lastName}`.trim();
}

// ==================== STATUS MAPS ====================

const JOB_STATUS_FROM_DB: Record<string, string> = {
  draft: 'lead',
  scheduled: 'scheduled',
  dispatched: 'scheduled',
  enRoute: 'in_progress',
  inProgress: 'in_progress',
  onHold: 'on_hold',
  completed: 'completed',
  invoiced: 'invoiced',
  cancelled: 'cancelled',
};

export const JOB_STATUS_TO_DB: Record<string, string> = {
  lead: 'draft',
  scheduled: 'scheduled',
  in_progress: 'inProgress',
  on_hold: 'onHold',
  completed: 'completed',
  invoiced: 'invoiced',
  paid: 'invoiced',
  cancelled: 'cancelled',
};

const INVOICE_STATUS_FROM_DB: Record<string, string> = {
  draft: 'draft',
  pendingApproval: 'draft',
  approved: 'draft',
  rejected: 'draft',
  sent: 'sent',
  viewed: 'viewed',
  partiallyPaid: 'partial',
  paid: 'paid',
  voided: 'void',
  overdue: 'overdue',
};

export const INVOICE_STATUS_TO_DB: Record<string, string> = {
  draft: 'draft',
  sent: 'sent',
  viewed: 'viewed',
  partial: 'partiallyPaid',
  paid: 'paid',
  overdue: 'overdue',
  void: 'voided',
  refunded: 'voided',
};

// ==================== JOB TYPE MAPS ====================

export const JOB_TYPE_LABELS: Record<JobType, string> = {
  standard: 'Standard',
  insurance_claim: 'Insurance Claim',
  warranty_dispatch: 'Warranty Dispatch',
  service_call: 'Service Call',
  installation: 'Installation',
  repair: 'Repair',
  maintenance: 'Maintenance',
  inspection: 'Inspection',
  emergency: 'Emergency',
  project: 'Project',
  consultation: 'Consultation',
  warranty_callback: 'Warranty Callback',
};

export const JOB_TYPE_COLORS: Record<JobType, { bg: string; text: string; dot: string }> = {
  standard: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300', dot: 'bg-blue-500' },
  insurance_claim: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300', dot: 'bg-amber-500' },
  warranty_dispatch: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300', dot: 'bg-purple-500' },
  service_call: { bg: 'bg-teal-100 dark:bg-teal-900/30', text: 'text-teal-700 dark:text-teal-300', dot: 'bg-teal-500' },
  installation: { bg: 'bg-green-100 dark:bg-green-900/30', text: 'text-green-700 dark:text-green-300', dot: 'bg-green-500' },
  repair: { bg: 'bg-orange-100 dark:bg-orange-900/30', text: 'text-orange-700 dark:text-orange-300', dot: 'bg-orange-500' },
  maintenance: { bg: 'bg-cyan-100 dark:bg-cyan-900/30', text: 'text-cyan-700 dark:text-cyan-300', dot: 'bg-cyan-500' },
  inspection: { bg: 'bg-indigo-100 dark:bg-indigo-900/30', text: 'text-indigo-700 dark:text-indigo-300', dot: 'bg-indigo-500' },
  emergency: { bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-700 dark:text-red-300', dot: 'bg-red-500' },
  project: { bg: 'bg-violet-100 dark:bg-violet-900/30', text: 'text-violet-700 dark:text-violet-300', dot: 'bg-violet-500' },
  consultation: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-700 dark:text-slate-300', dot: 'bg-slate-500' },
  warranty_callback: { bg: 'bg-fuchsia-100 dark:bg-fuchsia-900/30', text: 'text-fuchsia-700 dark:text-fuchsia-300', dot: 'bg-fuchsia-500' },
};

// ==================== ENTITY MAPPERS ====================

export function mapCustomer(row: Record<string, unknown>): Customer {
  const { firstName, lastName } = splitName((row.name as string) || '');
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    firstName,
    lastName,
    email: (row.email as string) || '',
    phone: (row.phone as string) || '',
    address: mapAddress(row),
    tags: (row.tags as string[]) || [],
    notes: (row.notes as string) || undefined,
    source: (row.referred_by as string) || undefined,
    customerType: (row.type as 'residential' | 'commercial') || undefined,
    alternatePhone: (row.alternate_phone as string) || undefined,
    accessInstructions: (row.access_instructions as string) || undefined,
    preferredContactMethod: (row.preferred_contact_method as 'phone' | 'email' | 'text') || undefined,
    emailOptIn: row.email_opt_in != null ? row.email_opt_in as boolean : undefined,
    smsOptIn: row.sms_opt_in != null ? row.sms_opt_in as boolean : undefined,
    totalRevenue: Number(row.total_revenue) || 0,
    jobCount: Number(row.job_count) || 0,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapJob(row: Record<string, unknown>): Job {
  const customerName = (row.customer_name as string) || '';
  const { firstName, lastName } = splitName(customerName);

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    customerId: (row.customer_id as string) || '',
    customer: row.customer_id
      ? {
          id: row.customer_id as string,
          companyId: (row.company_id as string) || '',
          firstName,
          lastName,
          email: (row.customer_email as string) || '',
          phone: (row.customer_phone as string) || '',
          address: mapAddress(row),
          tags: [],
          totalRevenue: 0,
          jobCount: 0,
          createdAt: new Date(row.created_at as string),
          updatedAt: new Date(row.updated_at as string),
        }
      : undefined,
    bidId: (row.quote_id as string) || undefined,
    title: (row.title as string) || 'Untitled Job',
    description: (row.description as string) || undefined,
    jobType: ((row.job_type as string) || 'standard') as JobType,
    typeMetadata: (row.type_metadata as Record<string, unknown>) || {},
    status: (JOB_STATUS_FROM_DB[row.status as string] || (row.status as string)) as Job['status'],
    priority: ((row.priority as string) || 'normal') as Job['priority'],
    address: mapAddress(row),
    scheduledStart: row.scheduled_start ? new Date(row.scheduled_start as string) : undefined,
    scheduledEnd: row.scheduled_end ? new Date(row.scheduled_end as string) : undefined,
    actualStart: row.started_at ? new Date(row.started_at as string) : undefined,
    actualEnd: row.completed_at ? new Date(row.completed_at as string) : undefined,
    assignedTo: (row.assigned_user_ids as string[]) || [],
    teamMembers: [],
    estimatedValue: Number(row.estimated_amount) || 0,
    actualCost: Number(row.actual_amount) || 0,
    notes: [],
    photos: [],
    source: (row.source as string) || 'direct',
    tags: (row.tags as string[]) || [],
    propertyId: (row.property_id as string) || undefined,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapInvoice(row: Record<string, unknown>): Invoice {
  const customerName = (row.customer_name as string) || '';
  const { firstName, lastName } = splitName(customerName);

  const rawLineItems = row.line_items;
  const lineItems = Array.isArray(rawLineItems)
    ? rawLineItems.map((li: Record<string, unknown>) => ({
        id: (li.id as string) || crypto.randomUUID(),
        description: (li.description as string) || '',
        quantity: Number(li.quantity) || 1,
        unitPrice: Number(li.unit_price ?? li.unitPrice) || 0,
        total: Number(li.amount ?? li.total) || 0,
        paymentSource: (li.payment_source ?? li.paymentSource ?? 'standard') as 'standard' | 'carrier' | 'deductible' | 'upgrade',
      }))
    : [];

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    customerId: (row.customer_id as string) || '',
    customer: row.customer_id
      ? {
          id: row.customer_id as string,
          companyId: (row.company_id as string) || '',
          firstName,
          lastName,
          email: (row.customer_email as string) || '',
          phone: (row.customer_phone as string) || '',
          address: { street: (row.customer_address as string) || '', city: '', state: '', zip: '' },
          tags: [],
          totalRevenue: 0,
          jobCount: 0,
          createdAt: new Date(row.created_at as string),
          updatedAt: new Date(row.updated_at as string),
        }
      : undefined,
    jobId: (row.job_id as string) || undefined,
    estimateId: (row.estimate_id as string) || undefined,
    parentInvoiceId: (row.parent_invoice_id as string) || undefined,
    invoiceNumber: (row.invoice_number as string) || '',
    title: (row.title as string) || undefined,
    status: (INVOICE_STATUS_FROM_DB[row.status as string] || (row.status as string)) as Invoice['status'],
    lineItems,
    subtotal: Number(row.subtotal) || 0,
    taxRate: Number(row.tax_rate) || 0,
    tax: Number(row.tax_amount) || 0,
    total: Number(row.total) || 0,
    amountPaid: Number(row.amount_paid) || 0,
    amountDue: Number(row.amount_due) || 0,
    dueDate: row.due_date ? new Date(row.due_date as string) : new Date(),
    sentAt: row.sent_at ? new Date(row.sent_at as string) : undefined,
    paidAt: row.paid_at ? new Date(row.paid_at as string) : undefined,
    paymentMethod: (row.payment_method as string) || undefined,
    notes: (row.notes as string) || undefined,
    poNumber: (row.po_number as string) || undefined,
    retainagePercent: row.retainage_percent != null ? Number(row.retainage_percent) : undefined,
    retainageAmount: row.retainage_amount != null ? Number(row.retainage_amount) : undefined,
    lateFeePerDay: row.late_fee_per_day != null ? Number(row.late_fee_per_day) : undefined,
    discountPercent: row.discount_percent != null ? Number(row.discount_percent) : undefined,
    paymentTerms: (row.payment_terms as string) || undefined,
    // Progress invoicing
    progressGroupId: (row.progress_group_id as string) || undefined,
    isProgressInvoice: row.is_progress_invoice === true,
    milestoneName: (row.milestone_name as string) || undefined,
    milestonePercent: row.milestone_percent != null ? Number(row.milestone_percent) : undefined,
    // Recurring invoicing
    isRecurringTemplate: row.is_recurring_template === true,
    recurringFrequency: (row.recurring_frequency as Invoice['recurringFrequency']) || undefined,
    recurringNextDate: row.recurring_next_date ? new Date(row.recurring_next_date as string) : undefined,
    recurringEndDate: row.recurring_end_date ? new Date(row.recurring_end_date as string) : undefined,
    recurringCount: row.recurring_count != null ? Number(row.recurring_count) : undefined,
    recurringTemplateId: (row.recurring_template_id as string) || undefined,
    serviceAgreementId: (row.service_agreement_id as string) || undefined,
    // Online payment
    paymentLinkToken: (row.payment_link_token as string) || undefined,
    paymentLinkUrl: (row.payment_link_url as string) || undefined,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapBid(row: Record<string, unknown>): Bid {
  const rawLineItems = row.line_items as Record<string, unknown> | unknown[] | null;

  // line_items JSONB may contain { options, addOns } or be a flat array
  let options: BidOption[];
  let addOns: Bid['addOns'] = [];

  if (rawLineItems && !Array.isArray(rawLineItems) && (rawLineItems as Record<string, unknown>).options) {
    const parsed = rawLineItems as Record<string, unknown>;
    options = (parsed.options as BidOption[]) || [];
    addOns = (parsed.addOns as Bid['addOns']) || [];
  } else {
    options = [
      {
        id: 'default',
        name: 'Standard',
        lineItems: Array.isArray(rawLineItems) ? (rawLineItems as BidOption['lineItems']) : [],
        subtotal: Number(row.subtotal) || 0,
        taxAmount: Number(row.tax_amount) || 0,
        total: Number(row.total) || 0,
        isRecommended: true,
        sortOrder: 0,
      },
    ];
  }

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    bidNumber: (row.bid_number as string) || '',
    customerId: (row.customer_id as string) || undefined,
    customerName: (row.customer_name as string) || '',
    customerEmail: (row.customer_email as string) || undefined,
    customerAddress: row.customer_address
      ? { street: row.customer_address as string, city: '', state: '', zip: '' }
      : undefined,
    jobSiteSameAsCustomer: true,
    title: (row.title as string) || '',
    scopeOfWork: (row.scope_of_work as string) || undefined,
    status: (row.status as Bid['status']) || 'draft',
    options,
    selectedOptionId: options[0]?.id,
    addOns,
    selectedAddOnIds: addOns.filter((a) => a.isSelected).map((a) => a.id),
    subtotal: Number(row.subtotal) || 0,
    taxRate: Number(row.tax_rate) || 0,
    tax: Number(row.tax_amount) || 0,
    discountAmount: 0,
    total: Number(row.total) || 0,
    depositPercent: 0,
    depositAmount: 0,
    depositPaid: false,
    validUntil: row.valid_until ? new Date(row.valid_until as string) : new Date(),
    termsAndConditions: (row.terms as string) || undefined,
    signatureData: (row.signature_data as string) || undefined,
    signedByName: (row.signed_by_name as string) || undefined,
    signedAt: row.signed_at ? new Date(row.signed_at as string) : undefined,
    sentAt: row.sent_at ? new Date(row.sent_at as string) : undefined,
    viewedAt: row.viewed_at ? new Date(row.viewed_at as string) : undefined,
    respondedAt: (row.accepted_at || row.rejected_at)
      ? new Date((row.accepted_at || row.rejected_at) as string)
      : undefined,
    convertedToJobId: (row.job_id as string) || undefined,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapTeamMember(row: Record<string, unknown>): TeamMember {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    userId: row.id as string,
    email: (row.email as string) || '',
    name: (row.full_name as string) || '',
    role: ((row.role as string) || 'field_tech') as TeamMember['role'],
    phone: (row.phone as string) || undefined,
    avatar: (row.avatar_url as string) || undefined,
    isActive: (row.is_active as boolean) ?? true,
    lastActive: row.last_login_at ? new Date(row.last_login_at as string) : undefined,
    createdAt: new Date(row.created_at as string),
  };
}

export function mapActivity(row: Record<string, unknown>): Activity {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    userId: (row.user_id as string) || '',
    userName: '',
    type: (row.action as Activity['type']) || 'updated',
    entityType: (row.table_name as Activity['entityType']) || 'system',
    entityId: (row.record_id as string) || '',
    entityName: '',
    description: `${row.action} ${row.table_name}`,
    createdAt: new Date(row.created_at as string),
  };
}

export function mapChangeOrder(row: Record<string, unknown>): ChangeOrderData {
  const rawItems = row.line_items;
  const items: ChangeOrderItem[] = Array.isArray(rawItems)
    ? rawItems.map((li: Record<string, unknown>) => ({
        description: (li.description as string) || '',
        quantity: Number(li.quantity) || 1,
        unitPrice: Number(li.unit_price ?? li.unitPrice) || 0,
        total: Number(li.total ?? li.amount) || 0,
      }))
    : [];

  // job data comes from nested select: change_orders(*, jobs(title, customer_name))
  const jobData = row.jobs as Record<string, unknown> | null;

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || '',
    jobName: jobData ? (jobData.title as string) || '' : '',
    customerName: jobData ? (jobData.customer_name as string) || '' : '',
    number: (row.change_order_number as string) || '',
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    reason: (row.reason as string) || '',
    items,
    amount: Number(row.amount) || 0,
    status: (row.status as ChangeOrderData['status']) || 'draft',
    approvedByName: (row.approved_by_name as string) || undefined,
    approvedAt: row.approved_at ? new Date(row.approved_at as string) : undefined,
    notes: (row.notes as string) || undefined,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapLead(row: Record<string, unknown>): LeadData {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    createdByUserId: (row.created_by_user_id as string) || '',
    assignedToUserId: (row.assigned_to_user_id as string) || undefined,
    name: (row.name as string) || '',
    email: (row.email as string) || '',
    phone: (row.phone as string) || '',
    companyName: (row.company_name as string) || undefined,
    source: (row.source as string) || 'website',
    stage: (row.stage as LeadData['stage']) || 'new',
    value: Number(row.value) || 0,
    notes: (row.notes as string) || '',
    address: (row.address as string) || undefined,
    city: (row.city as string) || undefined,
    state: (row.state as string) || undefined,
    zipCode: (row.zip_code as string) || undefined,
    lastContactedAt: row.last_contacted_at ? new Date(row.last_contacted_at as string) : undefined,
    nextFollowUp: row.next_follow_up ? new Date(row.next_follow_up as string) : undefined,
    wonAt: row.won_at ? new Date(row.won_at as string) : undefined,
    lostAt: row.lost_at ? new Date(row.lost_at as string) : undefined,
    lostReason: (row.lost_reason as string) || undefined,
    convertedToJobId: (row.converted_to_job_id as string) || undefined,
    tags: (row.tags as string[]) || [],
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

export function mapInspection(row: Record<string, unknown>): InspectionData {
  const data = (row.data as Record<string, unknown>) || {};

  // job data comes from nested select: compliance_records(*, jobs(title, customer_name, address, city, state))
  const jobData = row.jobs as Record<string, unknown> | null;

  const rawChecklist = data.checklist;
  const checklist: InspectionChecklistItem[] = Array.isArray(rawChecklist)
    ? rawChecklist.map((item: Record<string, unknown>) => ({
        id: (item.id as string) || crypto.randomUUID(),
        label: (item.label as string) || '',
        completed: (item.completed as boolean) ?? false,
        note: (item.note as string) || undefined,
        photoRequired: (item.photoRequired as boolean) ?? false,
        hasPhoto: (item.hasPhoto as boolean) ?? false,
      }))
    : [];

  const jobAddress = jobData
    ? [jobData.address, jobData.city, jobData.state].filter(Boolean).join(', ')
    : '';

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobId: (row.job_id as string) || '',
    jobName: jobData ? (jobData.title as string) || '' : '',
    customerName: jobData ? (jobData.customer_name as string) || '' : '',
    address: (data.address as string) || jobAddress,
    type: (data.inspection_type as string) || 'quality',
    status: (row.status as string) || 'scheduled',
    title: (data.title as string) || 'Inspection',
    assignedTo: (data.assigned_to as string) || '',
    scheduledDate: row.started_at ? new Date(row.started_at as string) : new Date(row.created_at as string),
    completedDate: row.ended_at ? new Date(row.ended_at as string) : undefined,
    checklist,
    overallScore: data.overall_score != null ? Number(data.overall_score) : undefined,
    notes: (data.notes as string) || (row.notes as string) || undefined,
    photos: Number(data.photo_count) || 0,
    createdAt: new Date(row.created_at as string),
  };
}

// ==================== INSURANCE / RESTORATION MAPPERS ====================

import type {
  InsuranceClaimData,
  ClaimSupplementData,
  TpiInspectionData,
  MoistureReadingData,
  DryingLogData,
  RestorationEquipmentData,
  ClaimStatus,
  ClaimCategory,
} from '@/types';

export const CLAIM_CATEGORY_LABELS: Record<ClaimCategory, string> = {
  restoration: 'Restoration',
  storm: 'Storm/Weather',
  reconstruction: 'Reconstruction',
  commercial: 'Commercial',
};

export const CLAIM_CATEGORY_COLORS: Record<ClaimCategory, string> = {
  restoration: 'bg-blue-100 text-blue-700',
  storm: 'bg-purple-100 text-purple-700',
  reconstruction: 'bg-orange-100 text-orange-700',
  commercial: 'bg-emerald-100 text-emerald-700',
};

export const CLAIM_STATUS_LABELS: Record<ClaimStatus, string> = {
  new: 'New',
  scope_requested: 'Scope Requested',
  scope_submitted: 'Scope Submitted',
  estimate_pending: 'Estimate Pending',
  estimate_approved: 'Estimate Approved',
  supplement_submitted: 'Supplement Submitted',
  supplement_approved: 'Supplement Approved',
  work_in_progress: 'Work In Progress',
  work_complete: 'Work Complete',
  final_inspection: 'Final Inspection',
  settled: 'Settled',
  closed: 'Closed',
  denied: 'Denied',
};

export const CLAIM_STATUS_COLORS: Record<ClaimStatus, string> = {
  new: 'bg-blue-100 text-blue-700',
  scope_requested: 'bg-yellow-100 text-yellow-700',
  scope_submitted: 'bg-yellow-100 text-yellow-700',
  estimate_pending: 'bg-orange-100 text-orange-700',
  estimate_approved: 'bg-green-100 text-green-700',
  supplement_submitted: 'bg-purple-100 text-purple-700',
  supplement_approved: 'bg-purple-100 text-purple-700',
  work_in_progress: 'bg-blue-100 text-blue-700',
  work_complete: 'bg-teal-100 text-teal-700',
  final_inspection: 'bg-indigo-100 text-indigo-700',
  settled: 'bg-green-100 text-green-700',
  closed: 'bg-gray-100 text-gray-500',
  denied: 'bg-red-100 text-red-700',
};

export const LOSS_TYPE_LABELS: Record<string, string> = {
  fire: 'Fire',
  water: 'Water',
  storm: 'Storm',
  wind: 'Wind',
  hail: 'Hail',
  theft: 'Theft',
  vandalism: 'Vandalism',
  mold: 'Mold',
  flood: 'Flood',
  earthquake: 'Earthquake',
  other: 'Other',
  unknown: 'Unknown',
};

export const EQUIPMENT_TYPE_LABELS: Record<string, string> = {
  dehumidifier: 'Dehumidifier',
  air_mover: 'Air Mover',
  air_scrubber: 'Air Scrubber',
  heater: 'Heater',
  moisture_meter: 'Moisture Meter',
  thermal_camera: 'Thermal Camera',
  hydroxyl_generator: 'Hydroxyl Generator',
  negative_air_machine: 'Negative Air Machine',
  other: 'Other',
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapInsuranceClaim(row: any): InsuranceClaimData {
  const jobData = row.jobs as { title?: string; customer_name?: string; address?: string } | null;
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    insuranceCompany: row.insurance_company || '',
    claimNumber: row.claim_number || '',
    policyNumber: row.policy_number || undefined,
    dateOfLoss: row.date_of_loss || '',
    lossType: row.loss_type || 'unknown',
    lossDescription: row.loss_description || undefined,
    adjusterName: row.adjuster_name || undefined,
    adjusterPhone: row.adjuster_phone || undefined,
    adjusterEmail: row.adjuster_email || undefined,
    adjusterCompany: row.adjuster_company || undefined,
    deductible: Number(row.deductible) || 0,
    coverageLimit: row.coverage_limit != null ? Number(row.coverage_limit) : undefined,
    approvedAmount: row.approved_amount != null ? Number(row.approved_amount) : undefined,
    supplementTotal: Number(row.supplement_total) || 0,
    depreciation: Number(row.depreciation) || 0,
    acv: row.acv != null ? Number(row.acv) : undefined,
    rcv: row.rcv != null ? Number(row.rcv) : undefined,
    depreciationRecovered: row.depreciation_recovered || false,
    amountCollected: Number(row.amount_collected) || 0,
    claimStatus: row.claim_status || 'new',
    claimCategory: row.claim_category || 'restoration',
    scopeSubmittedAt: row.scope_submitted_at || undefined,
    estimateApprovedAt: row.estimate_approved_at || undefined,
    workStartedAt: row.work_started_at || undefined,
    workCompletedAt: row.work_completed_at || undefined,
    settledAt: row.settled_at || undefined,
    xactimateClaimId: row.xactimate_claim_id || undefined,
    xactimateFileUrl: row.xactimate_file_url || undefined,
    notes: row.notes || undefined,
    data: row.data || {},
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    deletedAt: row.deleted_at || undefined,
    job: jobData ? {
      title: jobData.title || '',
      customer_name: jobData.customer_name || '',
      address: jobData.address || undefined,
    } : undefined,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapClaimSupplement(row: any): ClaimSupplementData {
  return {
    id: row.id,
    companyId: row.company_id,
    claimId: row.claim_id,
    supplementNumber: row.supplement_number || 1,
    title: row.title || '',
    description: row.description || undefined,
    reason: row.reason || 'hidden_damage',
    amount: Number(row.amount) || 0,
    rcvAmount: row.rcv_amount != null ? Number(row.rcv_amount) : undefined,
    acvAmount: row.acv_amount != null ? Number(row.acv_amount) : undefined,
    depreciationAmount: Number(row.depreciation_amount) || 0,
    status: row.status || 'draft',
    approvedAmount: row.approved_amount != null ? Number(row.approved_amount) : undefined,
    lineItems: row.line_items || [],
    photos: row.photos || [],
    submittedAt: row.submitted_at || undefined,
    reviewedAt: row.reviewed_at || undefined,
    reviewerNotes: row.reviewer_notes || undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapTpiInspection(row: any): TpiInspectionData {
  return {
    id: row.id,
    companyId: row.company_id,
    claimId: row.claim_id,
    jobId: row.job_id,
    inspectorName: row.inspector_name || undefined,
    inspectorCompany: row.inspector_company || undefined,
    inspectorPhone: row.inspector_phone || undefined,
    inspectorEmail: row.inspector_email || undefined,
    inspectionType: row.inspection_type || 'progress',
    scheduledDate: row.scheduled_date || undefined,
    completedDate: row.completed_date || undefined,
    status: row.status || 'pending',
    result: row.result || undefined,
    findings: row.findings || undefined,
    photos: row.photos || [],
    notes: row.notes || undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapMoistureReading(row: any): MoistureReadingData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    claimId: row.claim_id || undefined,
    areaName: row.area_name || '',
    floorLevel: row.floor_level || undefined,
    materialType: row.material_type || 'drywall',
    readingValue: Number(row.reading_value) || 0,
    readingUnit: row.reading_unit || 'percent',
    targetValue: row.target_value != null ? Number(row.target_value) : undefined,
    meterType: row.meter_type || undefined,
    meterModel: row.meter_model || undefined,
    ambientTempF: row.ambient_temp_f != null ? Number(row.ambient_temp_f) : undefined,
    ambientHumidity: row.ambient_humidity != null ? Number(row.ambient_humidity) : undefined,
    isDry: row.is_dry || false,
    recordedByUserId: row.recorded_by_user_id || undefined,
    recordedAt: row.recorded_at,
    createdAt: row.created_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapDryingLog(row: any): DryingLogData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    claimId: row.claim_id || undefined,
    logType: row.log_type || 'daily',
    summary: row.summary || '',
    details: row.details || undefined,
    equipmentCount: row.equipment_count || 0,
    dehumidifiersRunning: row.dehumidifiers_running || 0,
    airMoversRunning: row.air_movers_running || 0,
    airScrubbersRunning: row.air_scrubbers_running || 0,
    outdoorTempF: row.outdoor_temp_f != null ? Number(row.outdoor_temp_f) : undefined,
    outdoorHumidity: row.outdoor_humidity != null ? Number(row.outdoor_humidity) : undefined,
    indoorTempF: row.indoor_temp_f != null ? Number(row.indoor_temp_f) : undefined,
    indoorHumidity: row.indoor_humidity != null ? Number(row.indoor_humidity) : undefined,
    photos: row.photos || [],
    recordedByUserId: row.recorded_by_user_id || undefined,
    recordedAt: row.recorded_at,
    createdAt: row.created_at,
  };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function mapRestorationEquipment(row: any): RestorationEquipmentData {
  return {
    id: row.id,
    companyId: row.company_id,
    jobId: row.job_id,
    claimId: row.claim_id || undefined,
    equipmentType: row.equipment_type || 'other',
    make: row.make || undefined,
    model: row.model || undefined,
    serialNumber: row.serial_number || undefined,
    assetTag: row.asset_tag || undefined,
    areaDeployed: row.area_deployed || '',
    deployedAt: row.deployed_at,
    removedAt: row.removed_at || undefined,
    dailyRate: Number(row.daily_rate) || 0,
    totalDays: row.total_days != null ? Number(row.total_days) : undefined,
    status: row.status || 'deployed',
    notes: row.notes || undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
