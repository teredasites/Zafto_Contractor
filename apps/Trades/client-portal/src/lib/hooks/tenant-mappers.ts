// Client Portal tenant data types and mappers
// Maps Supabase DB rows → TypeScript interfaces for tenant flows

// ==================== TENANT TYPES ====================

export interface TenantData {
  id: string;
  firstName: string;
  lastName: string;
  email: string | null;
  phone: string | null;
  status: 'applicant' | 'active' | 'past' | 'evicted';
}

export interface LeaseData {
  id: string;
  propertyId: string;
  unitId: string;
  tenantId: string;
  leaseType: 'fixed' | 'month_to_month';
  startDate: string;
  endDate: string | null;
  rentAmount: number;
  rentDueDay: number;
  depositAmount: number;
  gracePeriodDays: number;
  lateFeeType: string;
  lateFeeAmount: number;
  autoRenew: boolean;
  partialPaymentsAllowed: boolean;
  status: string;
  signedAt: string | null;
  terminatedAt: string | null;
  terminationReason: string | null;
  termsNotes: string | null;
}

export interface PropertyInfo {
  id: string;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  state: string;
  zip: string;
  propertyType: string;
}

export interface UnitInfo {
  id: string;
  unitNumber: string;
  bedrooms: number;
  bathrooms: number;
  squareFootage: number | null;
}

export interface RentChargeData {
  id: string;
  companyId: string;
  leaseId: string;
  chargeType: string;
  description: string | null;
  amount: number;
  dueDate: string;
  status: 'pending' | 'partial' | 'paid' | 'overdue' | 'waived' | 'void';
  paidAmount: number;
  paidAt: string | null;
  createdAt: string;
}

export type PaymentMethodType =
  | 'ach' | 'credit_card' | 'debit_card' | 'cash' | 'check' | 'money_order'
  | 'direct_deposit' | 'wire_transfer' | 'zelle' | 'venmo' | 'cashapp'
  | 'housing_voucher' | 'government_direct' | 'other';

export type VerificationStatus = 'auto_verified' | 'pending_verification' | 'verified' | 'disputed' | 'rejected';

export type PaymentSource = 'tenant' | 'housing_authority' | 'government_program' | 'third_party' | 'other';

export interface RentPaymentData {
  id: string;
  rentChargeId: string;
  amount: number;
  paymentMethod: PaymentMethodType;
  processingFee: number;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'refunded';
  paidAt: string | null;
  notes: string | null;
  createdAt: string;
  // Verification fields
  reportedBy: string | null;
  verificationStatus: VerificationStatus;
  verifiedBy: string | null;
  verifiedAt: string | null;
  verificationNotes: string | null;
  proofDocumentUrl: string | null;
  // Payment source fields
  paymentSource: PaymentSource;
  sourceName: string | null;
  sourceReference: string | null;
  paymentDate: string | null;
}

export type GovernmentProgramType =
  | 'section_8_hcv' | 'vash' | 'public_housing' | 'project_based_voucher'
  | 'state_program' | 'local_program' | 'employer_assistance' | 'other';

export interface GovernmentProgramData {
  id: string;
  tenantId: string;
  programType: GovernmentProgramType;
  programName: string;
  authorityName: string | null;
  authorityContactName: string | null;
  authorityPhone: string | null;
  authorityEmail: string | null;
  voucherNumber: string | null;
  hapContractNumber: string | null;
  monthlyHapAmount: number | null;
  tenantPortion: number | null;
  utilityAllowance: number | null;
  effectiveDate: string | null;
  expirationDate: string | null;
  recertificationDate: string | null;
  isActive: boolean;
  notes: string | null;
}

export type MaintenanceUrgency = 'routine' | 'urgent' | 'emergency';
export type MaintenanceCategory = 'plumbing' | 'electrical' | 'hvac' | 'appliance' | 'structural' | 'pest' | 'lock_key' | 'exterior' | 'interior' | 'other';
export type MaintenanceStatus = 'submitted' | 'reviewed' | 'approved' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';

export interface MaintenanceRequestData {
  id: string;
  title: string;
  description: string;
  urgency: MaintenanceUrgency;
  category: MaintenanceCategory | null;
  status: MaintenanceStatus;
  preferredTimes: string[] | null;
  tenantRating: number | null;
  tenantFeedback: string | null;
  estimatedCost: number | null;
  actualCost: number | null;
  completedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MaintenanceMediaData {
  id: string;
  mediaType: 'photo' | 'video';
  storagePath: string;
  caption: string | null;
  uploadedBy: string;
  createdAt: string;
}

export interface WorkOrderActionData {
  id: string;
  actionType: string;
  actorType: string;
  actorName: string | null;
  notes: string | null;
  createdAt: string;
}

export type InspectionCondition = 'excellent' | 'good' | 'fair' | 'poor' | 'damaged';

export interface InspectionData {
  id: string;
  inspectionType: string;
  inspectionDate: string;
  overallCondition: InspectionCondition | null;
  status: string;
  notes: string | null;
  completedAt: string | null;
  createdAt: string;
}

export interface InspectionItemData {
  id: string;
  area: string;
  item: string;
  condition: string;
  notes: string | null;
  photos: string[];
  requiresRepair: boolean;
}

// ==================== MAPPERS ====================

export function mapTenant(row: Record<string, unknown>): TenantData {
  return {
    id: row.id as string,
    firstName: row.first_name as string || '',
    lastName: row.last_name as string || '',
    email: row.email as string || null,
    phone: row.phone as string || null,
    status: (row.status as TenantData['status']) || 'active',
  };
}

export function mapLease(row: Record<string, unknown>): LeaseData {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    unitId: row.unit_id as string,
    tenantId: row.tenant_id as string,
    leaseType: (row.lease_type as LeaseData['leaseType']) || 'fixed',
    startDate: row.start_date as string,
    endDate: row.end_date as string || null,
    rentAmount: (row.rent_amount as number) || 0,
    rentDueDay: (row.rent_due_day as number) || 1,
    depositAmount: (row.deposit_amount as number) || 0,
    gracePeriodDays: (row.grace_period_days as number) || 5,
    lateFeeType: row.late_fee_type as string || 'flat',
    lateFeeAmount: (row.late_fee_amount as number) || 0,
    autoRenew: (row.auto_renew as boolean) || false,
    partialPaymentsAllowed: (row.partial_payments_allowed as boolean) || false,
    status: row.status as string || 'draft',
    signedAt: row.signed_at as string || null,
    terminatedAt: row.terminated_at as string || null,
    terminationReason: row.termination_reason as string || null,
    termsNotes: row.terms_notes as string || null,
  };
}

export function mapProperty(row: Record<string, unknown>): PropertyInfo {
  return {
    id: row.id as string,
    addressLine1: row.address_line1 as string || '',
    addressLine2: row.address_line2 as string || null,
    city: row.city as string || '',
    state: row.state as string || '',
    zip: row.zip as string || '',
    propertyType: row.property_type as string || '',
  };
}

export function mapUnit(row: Record<string, unknown>): UnitInfo {
  return {
    id: row.id as string,
    unitNumber: row.unit_number as string || '',
    bedrooms: (row.bedrooms as number) || 0,
    bathrooms: (row.bathrooms as number) || 0,
    squareFootage: (row.square_footage as number) || null,
  };
}

export function mapRentCharge(row: Record<string, unknown>): RentChargeData {
  const status = row.status as string || 'pending';
  const dueDate = row.due_date as string;

  // Auto-detect overdue
  let finalStatus = status as RentChargeData['status'];
  if (status === 'pending' && dueDate && new Date(dueDate) < new Date()) {
    finalStatus = 'overdue';
  }

  return {
    id: row.id as string,
    companyId: row.company_id as string,
    leaseId: row.lease_id as string,
    chargeType: row.charge_type as string || 'rent',
    description: row.description as string || null,
    amount: (row.amount as number) || 0,
    dueDate,
    status: finalStatus,
    paidAmount: (row.paid_amount as number) || 0,
    paidAt: row.paid_at as string || null,
    createdAt: row.created_at as string || '',
  };
}

export function mapRentPayment(row: Record<string, unknown>): RentPaymentData {
  return {
    id: row.id as string,
    rentChargeId: row.rent_charge_id as string,
    amount: (row.amount as number) || 0,
    paymentMethod: (row.payment_method as PaymentMethodType) || 'other',
    processingFee: (row.processing_fee as number) || 0,
    status: (row.status as RentPaymentData['status']) || 'pending',
    paidAt: row.paid_at as string || null,
    notes: row.notes as string || null,
    createdAt: row.created_at as string || '',
    // Verification fields
    reportedBy: row.reported_by as string || null,
    verificationStatus: (row.verification_status as VerificationStatus) || 'auto_verified',
    verifiedBy: row.verified_by as string || null,
    verifiedAt: row.verified_at as string || null,
    verificationNotes: row.verification_notes as string || null,
    proofDocumentUrl: row.proof_document_url as string || null,
    // Payment source
    paymentSource: (row.payment_source as PaymentSource) || 'tenant',
    sourceName: row.source_name as string || null,
    sourceReference: row.source_reference as string || null,
    paymentDate: row.payment_date as string || null,
  };
}

export function mapGovernmentProgram(row: Record<string, unknown>): GovernmentProgramData {
  return {
    id: row.id as string,
    tenantId: row.tenant_id as string,
    programType: (row.program_type as GovernmentProgramType) || 'other',
    programName: row.program_name as string || '',
    authorityName: row.authority_name as string || null,
    authorityContactName: row.authority_contact_name as string || null,
    authorityPhone: row.authority_phone as string || null,
    authorityEmail: row.authority_email as string || null,
    voucherNumber: row.voucher_number as string || null,
    hapContractNumber: row.hap_contract_number as string || null,
    monthlyHapAmount: (row.monthly_hap_amount as number) || null,
    tenantPortion: (row.tenant_portion as number) || null,
    utilityAllowance: (row.utility_allowance as number) || null,
    effectiveDate: row.effective_date as string || null,
    expirationDate: row.expiration_date as string || null,
    recertificationDate: row.recertification_date as string || null,
    isActive: (row.is_active as boolean) ?? true,
    notes: row.notes as string || null,
  };
}

export function mapMaintenanceRequest(row: Record<string, unknown>): MaintenanceRequestData {
  return {
    id: row.id as string,
    title: row.title as string || '',
    description: row.description as string || '',
    urgency: (row.urgency as MaintenanceUrgency) || 'routine',
    category: (row.category as MaintenanceCategory) || null,
    status: (row.status as MaintenanceStatus) || 'submitted',
    preferredTimes: Array.isArray(row.preferred_times) ? row.preferred_times as string[] : null,
    tenantRating: (row.tenant_rating as number) || null,
    tenantFeedback: row.tenant_feedback as string || null,
    estimatedCost: (row.estimated_cost as number) || null,
    actualCost: (row.actual_cost as number) || null,
    completedAt: row.completed_at as string || null,
    createdAt: row.created_at as string || '',
    updatedAt: row.updated_at as string || '',
  };
}

export function mapMaintenanceMedia(row: Record<string, unknown>): MaintenanceMediaData {
  return {
    id: row.id as string,
    mediaType: (row.media_type as MaintenanceMediaData['mediaType']) || 'photo',
    storagePath: row.storage_path as string || '',
    caption: row.caption as string || null,
    uploadedBy: row.uploaded_by as string || '',
    createdAt: row.created_at as string || '',
  };
}

export function mapWorkOrderAction(row: Record<string, unknown>): WorkOrderActionData {
  return {
    id: row.id as string,
    actionType: row.action_type as string || '',
    actorType: row.actor_type as string || '',
    actorName: row.actor_name as string || null,
    notes: row.notes as string || null,
    createdAt: row.created_at as string || '',
  };
}

export function mapInspection(row: Record<string, unknown>): InspectionData {
  return {
    id: row.id as string,
    inspectionType: row.inspection_type as string || '',
    inspectionDate: row.inspection_date as string || '',
    overallCondition: (row.overall_condition as InspectionCondition) || null,
    status: row.status as string || 'scheduled',
    notes: row.notes as string || null,
    completedAt: row.completed_at as string || null,
    createdAt: row.created_at as string || '',
  };
}

export function mapInspectionItem(row: Record<string, unknown>): InspectionItemData {
  return {
    id: row.id as string,
    area: row.area as string || '',
    item: row.item as string || '',
    condition: row.condition as string || '',
    notes: row.notes as string || null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    requiresRepair: (row.requires_repair as boolean) || false,
  };
}

// ==================== DISPLAY HELPERS ====================

const CHARGE_TYPE_LABELS: Record<string, string> = {
  rent: 'Rent',
  late_fee: 'Late Fee',
  utility: 'Utility',
  pet_fee: 'Pet Fee',
  parking: 'Parking',
  other: 'Other',
};

export function chargeTypeLabel(type: string): string {
  return CHARGE_TYPE_LABELS[type] || type;
}

const PAYMENT_METHOD_LABELS: Record<string, string> = {
  ach: 'Bank Transfer (ACH)',
  credit_card: 'Credit Card',
  debit_card: 'Debit Card',
  cash: 'Cash',
  check: 'Check',
  money_order: 'Money Order',
  direct_deposit: 'Direct Deposit',
  wire_transfer: 'Wire Transfer',
  zelle: 'Zelle',
  venmo: 'Venmo',
  cashapp: 'Cash App',
  housing_voucher: 'Housing Voucher (Section 8)',
  government_direct: 'Government Direct Payment',
  other: 'Other',
};

const VERIFICATION_STATUS_LABELS: Record<string, string> = {
  auto_verified: 'Verified',
  pending_verification: 'Pending Verification',
  verified: 'Verified',
  disputed: 'Disputed',
  rejected: 'Rejected',
};

export function verificationStatusLabel(status: string): string {
  return VERIFICATION_STATUS_LABELS[status] || status;
}

const PAYMENT_SOURCE_LABELS: Record<string, string> = {
  tenant: 'Tenant',
  housing_authority: 'Housing Authority',
  government_program: 'Government Program',
  third_party: 'Third Party',
  other: 'Other',
};

export function paymentSourceLabel(source: string): string {
  return PAYMENT_SOURCE_LABELS[source] || source;
}

export function paymentMethodLabel(method: string): string {
  return PAYMENT_METHOD_LABELS[method] || method;
}

const URGENCY_LABELS: Record<string, string> = {
  routine: 'Routine',
  urgent: 'Urgent',
  emergency: 'Emergency',
};

export function urgencyLabel(urgency: string): string {
  return URGENCY_LABELS[urgency] || urgency;
}

const CATEGORY_LABELS: Record<string, string> = {
  plumbing: 'Plumbing',
  electrical: 'Electrical',
  hvac: 'HVAC',
  appliance: 'Appliance',
  structural: 'Structural',
  pest: 'Pest Control',
  lock_key: 'Lock & Key',
  exterior: 'Exterior',
  interior: 'Interior',
  other: 'Other',
};

export function categoryLabel(category: string | null): string {
  if (!category) return 'General';
  return CATEGORY_LABELS[category] || category;
}

const STATUS_LABELS: Record<string, string> = {
  submitted: 'Submitted',
  reviewed: 'Under Review',
  approved: 'Approved',
  scheduled: 'Scheduled',
  in_progress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

export function maintenanceStatusLabel(status: string): string {
  return STATUS_LABELS[status] || status;
}

const INSPECTION_TYPE_LABELS: Record<string, string> = {
  move_in: 'Move-In',
  move_out: 'Move-Out',
  routine: 'Routine',
  quarterly: 'Quarterly',
  annual: 'Annual',
  drive_by: 'Drive-By',
  pre_listing: 'Pre-Listing',
};

export function inspectionTypeLabel(type: string): string {
  return INSPECTION_TYPE_LABELS[type] || type;
}

const CONDITION_LABELS: Record<string, string> = {
  excellent: 'Excellent',
  good: 'Good',
  fair: 'Fair',
  poor: 'Poor',
  damaged: 'Damaged',
  missing: 'Missing',
  na: 'N/A',
};

export function conditionLabel(condition: string): string {
  return CONDITION_LABELS[condition] || condition;
}

const LEASE_STATUS_LABELS: Record<string, string> = {
  draft: 'Draft',
  pending_signature: 'Pending Signature',
  active: 'Active',
  month_to_month: 'Month-to-Month',
  expiring: 'Expiring Soon',
  expired: 'Expired',
  terminated: 'Terminated',
  renewed: 'Renewed',
};

export function leaseStatusLabel(status: string): string {
  return LEASE_STATUS_LABELS[status] || status;
}

export function formatAddress(prop: PropertyInfo, unit?: UnitInfo): string {
  const parts = [prop.addressLine1];
  if (unit && unit.unitNumber) parts.push(`Unit ${unit.unitNumber}`);
  if (prop.addressLine2) parts.push(prop.addressLine2);
  return `${parts.join(', ')}, ${prop.city}, ${prop.state} ${prop.zip}`;
}
