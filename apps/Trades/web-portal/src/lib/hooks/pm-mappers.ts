// DB row → TypeScript type mappers for Property Management (D5d)
// Maps snake_case Supabase rows to camelCase TypeScript interfaces

// --- Property ---
export interface PropertyData {
  id: string;
  companyId: string;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  state: string;
  zip: string;
  country: string;
  propertyType: 'single_family' | 'duplex' | 'triplex' | 'quadplex' | 'multi_unit' | 'commercial' | 'mixed_use';
  unitCount: number;
  yearBuilt: number | null;
  squareFootage: number | null;
  lotSize: string | null;
  purchaseDate: string | null;
  purchasePrice: number | null;
  currentValue: number | null;
  mortgageLender: string | null;
  mortgageRate: number | null;
  mortgagePayment: number | null;
  mortgageEscrow: number | null;
  mortgagePrincipalBalance: number | null;
  insuranceCarrier: string | null;
  insurancePolicyNumber: string | null;
  insurancePremium: number | null;
  insuranceExpiry: string | null;
  propertyTaxAnnual: number | null;
  notes: string | null;
  photos: string[];
  status: 'active' | 'inactive' | 'sold' | 'rehab';
  createdAt: Date;
  updatedAt: Date;
}

export function mapProperty(row: Record<string, unknown>): PropertyData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    addressLine1: row.address_line1 as string,
    addressLine2: (row.address_line2 as string) || null,
    city: row.city as string,
    state: row.state as string,
    zip: row.zip as string,
    country: (row.country as string) || 'US',
    propertyType: row.property_type as PropertyData['propertyType'],
    unitCount: Number(row.unit_count) || 1,
    yearBuilt: row.year_built ? Number(row.year_built) : null,
    squareFootage: row.square_footage ? Number(row.square_footage) : null,
    lotSize: (row.lot_size as string) || null,
    purchaseDate: (row.purchase_date as string) || null,
    purchasePrice: row.purchase_price ? Number(row.purchase_price) : null,
    currentValue: row.current_value ? Number(row.current_value) : null,
    mortgageLender: (row.mortgage_lender as string) || null,
    mortgageRate: row.mortgage_rate ? Number(row.mortgage_rate) : null,
    mortgagePayment: row.mortgage_payment ? Number(row.mortgage_payment) : null,
    mortgageEscrow: row.mortgage_escrow ? Number(row.mortgage_escrow) : null,
    mortgagePrincipalBalance: row.mortgage_principal_balance ? Number(row.mortgage_principal_balance) : null,
    insuranceCarrier: (row.insurance_carrier as string) || null,
    insurancePolicyNumber: (row.insurance_policy_number as string) || null,
    insurancePremium: row.insurance_premium ? Number(row.insurance_premium) : null,
    insuranceExpiry: (row.insurance_expiry as string) || null,
    propertyTaxAnnual: row.property_tax_annual ? Number(row.property_tax_annual) : null,
    notes: (row.notes as string) || null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    status: (row.status as PropertyData['status']) || 'active',
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Unit ---
export interface UnitData {
  id: string;
  companyId: string;
  propertyId: string;
  unitNumber: string;
  bedrooms: number;
  bathrooms: number;
  squareFootage: number | null;
  floorLevel: number | null;
  amenities: string[];
  marketRent: number | null;
  photos: string[];
  notes: string | null;
  status: 'vacant' | 'occupied' | 'maintenance' | 'listed' | 'unit_turn' | 'rehab';
  createdAt: Date;
  updatedAt: Date;
}

export function mapUnit(row: Record<string, unknown>): UnitData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitNumber: row.unit_number as string,
    bedrooms: Number(row.bedrooms) || 1,
    bathrooms: Number(row.bathrooms) || 1,
    squareFootage: row.square_footage ? Number(row.square_footage) : null,
    floorLevel: row.floor_level ? Number(row.floor_level) : null,
    amenities: Array.isArray(row.amenities) ? row.amenities as string[] : [],
    marketRent: row.market_rent ? Number(row.market_rent) : null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    notes: (row.notes as string) || null,
    status: (row.status as UnitData['status']) || 'vacant',
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Tenant ---
export interface TenantData {
  id: string;
  companyId: string;
  authUserId: string | null;
  firstName: string;
  lastName: string;
  email: string | null;
  phone: string | null;
  dateOfBirth: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
  employer: string | null;
  monthlyIncome: number | null;
  vehicleInfo: Record<string, unknown> | null;
  petInfo: Record<string, unknown> | null;
  notes: string | null;
  status: 'applicant' | 'active' | 'past' | 'evicted';
  createdAt: Date;
  updatedAt: Date;
}

export function mapTenant(row: Record<string, unknown>): TenantData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    authUserId: (row.auth_user_id as string) || null,
    firstName: row.first_name as string,
    lastName: row.last_name as string,
    email: (row.email as string) || null,
    phone: (row.phone as string) || null,
    dateOfBirth: (row.date_of_birth as string) || null,
    emergencyContactName: (row.emergency_contact_name as string) || null,
    emergencyContactPhone: (row.emergency_contact_phone as string) || null,
    employer: (row.employer as string) || null,
    monthlyIncome: row.monthly_income ? Number(row.monthly_income) : null,
    vehicleInfo: row.vehicle_info as Record<string, unknown> | null,
    petInfo: row.pet_info as Record<string, unknown> | null,
    notes: (row.notes as string) || null,
    status: (row.status as TenantData['status']) || 'active',
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Lease ---
export interface LeaseData {
  id: string;
  companyId: string;
  propertyId: string;
  unitId: string;
  tenantId: string;
  leaseType: 'fixed' | 'month_to_month' | 'week_to_week';
  startDate: string;
  endDate: string | null;
  rentAmount: number;
  rentDueDay: number;
  depositAmount: number;
  depositHeld: boolean;
  gracePeriodDays: number;
  lateFeeType: 'flat' | 'percent' | 'daily' | 'none';
  lateFeeAmount: number;
  autoRenew: boolean;
  paymentProcessorFee: 'landlord' | 'tenant' | 'split';
  partialPaymentsAllowed: boolean;
  autoPayRequired: boolean;
  termsNotes: string | null;
  status: 'draft' | 'active' | 'expired' | 'terminated' | 'renewed';
  signedAt: Date | null;
  terminatedAt: Date | null;
  terminationReason: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined data
  propertyAddress?: string;
  unitNumber?: string;
  tenantName?: string;
}

export function mapLease(row: Record<string, unknown>): LeaseData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const tenant = row.tenants as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitId: row.unit_id as string,
    tenantId: row.tenant_id as string,
    leaseType: (row.lease_type as LeaseData['leaseType']) || 'fixed',
    startDate: row.start_date as string,
    endDate: (row.end_date as string) || null,
    rentAmount: Number(row.rent_amount) || 0,
    rentDueDay: Number(row.rent_due_day) || 1,
    depositAmount: Number(row.deposit_amount) || 0,
    depositHeld: row.deposit_held === true,
    gracePeriodDays: Number(row.grace_period_days) || 5,
    lateFeeType: (row.late_fee_type as LeaseData['lateFeeType']) || 'none',
    lateFeeAmount: Number(row.late_fee_amount) || 0,
    autoRenew: row.auto_renew === true,
    paymentProcessorFee: (row.payment_processor_fee as LeaseData['paymentProcessorFee']) || 'landlord',
    partialPaymentsAllowed: row.partial_payments_allowed === true,
    autoPayRequired: row.auto_pay_required === true,
    termsNotes: (row.terms_notes as string) || null,
    status: (row.status as LeaseData['status']) || 'draft',
    signedAt: row.signed_at ? new Date(row.signed_at as string) : null,
    terminatedAt: row.terminated_at ? new Date(row.terminated_at as string) : null,
    terminationReason: (row.termination_reason as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    propertyAddress: property ? `${property.address_line1}` : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
    tenantName: tenant ? `${tenant.first_name} ${tenant.last_name}` : undefined,
  };
}

// --- Lease Document ---
export interface LeaseDocumentData {
  id: string;
  companyId: string;
  leaseId: string;
  documentType: 'lease_agreement' | 'addendum' | 'notice' | 'move_in_checklist' | 'move_out_checklist' | 'other';
  title: string;
  storagePath: string;
  signedByTenant: boolean;
  signedByLandlord: boolean;
  signedAt: Date | null;
  notes: string | null;
  createdAt: Date;
}

export function mapLeaseDocument(row: Record<string, unknown>): LeaseDocumentData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    leaseId: row.lease_id as string,
    documentType: (row.document_type as LeaseDocumentData['documentType']) || 'other',
    title: row.title as string,
    storagePath: row.storage_path as string,
    signedByTenant: row.signed_by_tenant === true,
    signedByLandlord: row.signed_by_landlord === true,
    signedAt: row.signed_at ? new Date(row.signed_at as string) : null,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- Rent Charge ---
export interface RentChargeData {
  id: string;
  companyId: string;
  leaseId: string;
  unitId: string;
  tenantId: string;
  propertyId: string;
  chargeType: 'rent' | 'late_fee' | 'utility' | 'parking' | 'pet' | 'damage' | 'other';
  description: string | null;
  amount: number;
  dueDate: string;
  status: 'pending' | 'partial' | 'paid' | 'overdue' | 'waived' | 'credited';
  paidAmount: number;
  paidAt: Date | null;
  journalEntryId: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined data
  tenantName?: string;
  unitNumber?: string;
  propertyAddress?: string;
}

export function mapRentCharge(row: Record<string, unknown>): RentChargeData {
  const tenant = row.tenants as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const property = row.properties as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    leaseId: row.lease_id as string,
    unitId: row.unit_id as string,
    tenantId: row.tenant_id as string,
    propertyId: row.property_id as string,
    chargeType: (row.charge_type as RentChargeData['chargeType']) || 'rent',
    description: (row.description as string) || null,
    amount: Number(row.amount) || 0,
    dueDate: row.due_date as string,
    status: (row.status as RentChargeData['status']) || 'pending',
    paidAmount: Number(row.paid_amount) || 0,
    paidAt: row.paid_at ? new Date(row.paid_at as string) : null,
    journalEntryId: (row.journal_entry_id as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    tenantName: tenant ? `${tenant.first_name} ${tenant.last_name}` : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
    propertyAddress: property ? (property.address_line1 as string) : undefined,
  };
}

// --- Payment Types ---
export type PaymentMethodType =
  | 'stripe' | 'ach' | 'credit_card' | 'debit_card' | 'cash' | 'check' | 'money_order'
  | 'direct_deposit' | 'wire_transfer' | 'zelle' | 'venmo' | 'cashapp'
  | 'housing_voucher' | 'government_direct' | 'other';

export type VerificationStatus = 'auto_verified' | 'pending_verification' | 'verified' | 'disputed' | 'rejected';
export type PaymentSource = 'tenant' | 'housing_authority' | 'government_program' | 'third_party' | 'other';

export const paymentMethodLabels: Record<string, string> = {
  stripe: 'Stripe',
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

export const verificationStatusLabels: Record<string, string> = {
  auto_verified: 'Verified',
  pending_verification: 'Pending Verification',
  verified: 'Verified',
  disputed: 'Disputed',
  rejected: 'Rejected',
};

export const paymentSourceLabels: Record<string, string> = {
  tenant: 'Tenant',
  housing_authority: 'Housing Authority',
  government_program: 'Government Program',
  third_party: 'Third Party',
  other: 'Other',
};

// --- Rent Payment ---
export interface RentPaymentData {
  id: string;
  companyId: string;
  rentChargeId: string;
  tenantId: string;
  amount: number;
  paymentMethod: PaymentMethodType;
  stripePaymentIntentId: string | null;
  processingFee: number;
  feePaidBy: 'landlord' | 'tenant';
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'refunded';
  journalEntryId: string | null;
  paidAt: Date | null;
  notes: string | null;
  createdAt: Date;
  // Verification fields
  reportedBy: string | null;
  verificationStatus: VerificationStatus;
  verifiedBy: string | null;
  verifiedAt: Date | null;
  verificationNotes: string | null;
  proofDocumentUrl: string | null;
  // Payment source
  paymentSource: PaymentSource;
  sourceName: string | null;
  sourceReference: string | null;
  paymentDate: string | null;
  // Joined
  tenantName?: string;
}

export function mapRentPayment(row: Record<string, unknown>): RentPaymentData {
  const tenant = row.tenants as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    rentChargeId: row.rent_charge_id as string,
    tenantId: row.tenant_id as string,
    amount: Number(row.amount) || 0,
    paymentMethod: (row.payment_method as PaymentMethodType) || 'other',
    stripePaymentIntentId: (row.stripe_payment_intent_id as string) || null,
    processingFee: Number(row.processing_fee) || 0,
    feePaidBy: (row.fee_paid_by as RentPaymentData['feePaidBy']) || 'landlord',
    status: (row.status as RentPaymentData['status']) || 'pending',
    journalEntryId: (row.journal_entry_id as string) || null,
    paidAt: row.paid_at ? new Date(row.paid_at as string) : null,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
    // Verification
    reportedBy: (row.reported_by as string) || null,
    verificationStatus: (row.verification_status as VerificationStatus) || 'auto_verified',
    verifiedBy: (row.verified_by as string) || null,
    verifiedAt: row.verified_at ? new Date(row.verified_at as string) : null,
    verificationNotes: (row.verification_notes as string) || null,
    proofDocumentUrl: (row.proof_document_url as string) || null,
    // Source
    paymentSource: (row.payment_source as PaymentSource) || 'tenant',
    sourceName: (row.source_name as string) || null,
    sourceReference: (row.source_reference as string) || null,
    paymentDate: (row.payment_date as string) || null,
    // Joined
    tenantName: tenant ? `${tenant.first_name} ${tenant.last_name}` : undefined,
  };
}

// --- Government Payment Program ---
export type GovernmentProgramType =
  | 'section_8_hcv' | 'vash' | 'public_housing' | 'project_based_voucher'
  | 'state_program' | 'local_program' | 'employer_assistance' | 'other';

export const governmentProgramLabels: Record<string, string> = {
  section_8_hcv: 'Section 8 (HCV)',
  vash: 'VASH (Veterans)',
  public_housing: 'Public Housing',
  project_based_voucher: 'Project-Based Voucher',
  state_program: 'State Program',
  local_program: 'Local Program',
  employer_assistance: 'Employer Assistance',
  other: 'Other',
};

export interface GovernmentProgramData {
  id: string;
  companyId: string;
  tenantId: string;
  programType: GovernmentProgramType;
  programName: string;
  authorityName: string | null;
  authorityContactName: string | null;
  authorityPhone: string | null;
  authorityEmail: string | null;
  authorityAddress: string | null;
  voucherNumber: string | null;
  hapContractNumber: string | null;
  monthlyHapAmount: number | null;
  tenantPortion: number | null;
  utilityAllowance: number | null;
  paymentStandard: number | null;
  effectiveDate: string | null;
  expirationDate: string | null;
  recertificationDate: string | null;
  inspectionDate: string | null;
  nextInspectionDate: string | null;
  isActive: boolean;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export function mapGovernmentProgram(row: Record<string, unknown>): GovernmentProgramData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    tenantId: row.tenant_id as string,
    programType: (row.program_type as GovernmentProgramType) || 'other',
    programName: row.program_name as string || '',
    authorityName: (row.authority_name as string) || null,
    authorityContactName: (row.authority_contact_name as string) || null,
    authorityPhone: (row.authority_phone as string) || null,
    authorityEmail: (row.authority_email as string) || null,
    authorityAddress: (row.authority_address as string) || null,
    voucherNumber: (row.voucher_number as string) || null,
    hapContractNumber: (row.hap_contract_number as string) || null,
    monthlyHapAmount: row.monthly_hap_amount ? Number(row.monthly_hap_amount) : null,
    tenantPortion: row.tenant_portion ? Number(row.tenant_portion) : null,
    utilityAllowance: row.utility_allowance ? Number(row.utility_allowance) : null,
    paymentStandard: row.payment_standard ? Number(row.payment_standard) : null,
    effectiveDate: (row.effective_date as string) || null,
    expirationDate: (row.expiration_date as string) || null,
    recertificationDate: (row.recertification_date as string) || null,
    inspectionDate: (row.inspection_date as string) || null,
    nextInspectionDate: (row.next_inspection_date as string) || null,
    isActive: (row.is_active as boolean) ?? true,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Payment Verification Log ---
export interface PaymentVerificationLogData {
  id: string;
  companyId: string;
  paymentId: string;
  paymentContext: 'rent' | 'invoice' | 'bid_deposit';
  action: 'reported' | 'verified' | 'disputed' | 'rejected' | 'updated' | 'proof_uploaded';
  performedBy: string;
  oldStatus: string | null;
  newStatus: string | null;
  notes: string | null;
  createdAt: Date;
}

export function mapVerificationLog(row: Record<string, unknown>): PaymentVerificationLogData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    paymentId: row.payment_id as string,
    paymentContext: (row.payment_context as PaymentVerificationLogData['paymentContext']) || 'rent',
    action: (row.action as PaymentVerificationLogData['action']) || 'reported',
    performedBy: row.performed_by as string,
    oldStatus: (row.old_status as string) || null,
    newStatus: (row.new_status as string) || null,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- Maintenance Request ---
export interface MaintenanceRequestData {
  id: string;
  companyId: string;
  propertyId: string;
  unitId: string | null;
  tenantId: string | null;
  title: string;
  description: string;
  urgency: 'low' | 'medium' | 'high' | 'emergency';
  category: 'plumbing' | 'electrical' | 'hvac' | 'appliance' | 'structural' | 'pest' | 'landscaping' | 'cleaning' | 'safety' | 'other';
  preferredTimes: string[] | null;
  jobId: string | null;
  assignedTo: string | null;
  assignedVendorId: string | null;
  status: 'submitted' | 'reviewed' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  completedAt: Date | null;
  tenantRating: number | null;
  tenantFeedback: string | null;
  estimatedCost: number | null;
  actualCost: number | null;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  propertyAddress?: string;
  unitNumber?: string;
  tenantName?: string;
}

export function mapMaintenanceRequest(row: Record<string, unknown>): MaintenanceRequestData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const tenant = row.tenants as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitId: (row.unit_id as string) || null,
    tenantId: (row.tenant_id as string) || null,
    title: row.title as string,
    description: row.description as string,
    urgency: (row.urgency as MaintenanceRequestData['urgency']) || 'medium',
    category: (row.category as MaintenanceRequestData['category']) || 'other',
    preferredTimes: row.preferred_times as string[] | null,
    jobId: (row.job_id as string) || null,
    assignedTo: (row.assigned_to as string) || null,
    assignedVendorId: (row.assigned_vendor_id as string) || null,
    status: (row.status as MaintenanceRequestData['status']) || 'submitted',
    completedAt: row.completed_at ? new Date(row.completed_at as string) : null,
    tenantRating: row.tenant_rating ? Number(row.tenant_rating) : null,
    tenantFeedback: (row.tenant_feedback as string) || null,
    estimatedCost: row.estimated_cost ? Number(row.estimated_cost) : null,
    actualCost: row.actual_cost ? Number(row.actual_cost) : null,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    propertyAddress: property ? (property.address_line1 as string) : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
    tenantName: tenant ? `${tenant.first_name} ${tenant.last_name}` : undefined,
  };
}

// --- Work Order Action (immutable audit log) ---
export interface WorkOrderActionData {
  id: string;
  companyId: string;
  jobId: string | null;
  maintenanceRequestId: string | null;
  actionType: string;
  actorType: 'user' | 'tenant' | 'vendor' | 'system';
  actorId: string | null;
  actorName: string;
  notes: string | null;
  photos: string[];
  metadata: Record<string, unknown> | null;
  createdAt: Date;
}

export function mapWorkOrderAction(row: Record<string, unknown>): WorkOrderActionData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: (row.job_id as string) || null,
    maintenanceRequestId: (row.maintenance_request_id as string) || null,
    actionType: row.action_type as string,
    actorType: (row.actor_type as WorkOrderActionData['actorType']) || 'user',
    actorId: (row.actor_id as string) || null,
    actorName: row.actor_name as string,
    notes: (row.notes as string) || null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    metadata: row.metadata as Record<string, unknown> | null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- Approval Record ---
export interface ApprovalRecordData {
  id: string;
  companyId: string;
  entityType: string;
  entityId: string;
  requestedBy: string;
  requestedAt: Date;
  thresholdAmount: number;
  status: 'pending' | 'approved' | 'rejected';
  decidedBy: string | null;
  decidedAt: Date | null;
  notes: string | null;
  createdAt: Date;
}

export function mapApprovalRecord(row: Record<string, unknown>): ApprovalRecordData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    entityType: row.entity_type as string,
    entityId: row.entity_id as string,
    requestedBy: row.requested_by as string,
    requestedAt: new Date(row.requested_at as string),
    thresholdAmount: Number(row.threshold_amount) || 0,
    status: (row.status as ApprovalRecordData['status']) || 'pending',
    decidedBy: (row.decided_by as string) || null,
    decidedAt: row.decided_at ? new Date(row.decided_at as string) : null,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- PM Inspection ---
export interface PmInspectionData {
  id: string;
  companyId: string;
  propertyId: string;
  unitId: string | null;
  leaseId: string | null;
  inspectionType: 'move_in' | 'move_out' | 'routine' | 'drive_by' | 'annual' | 'emergency';
  inspectedBy: string | null;
  inspectionDate: string;
  overallCondition: 'excellent' | 'good' | 'fair' | 'poor' | null;
  notes: string | null;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  completedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  propertyAddress?: string;
  unitNumber?: string;
  items?: PmInspectionItemData[];
}

export function mapPmInspection(row: Record<string, unknown>): PmInspectionData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const items = row.pm_inspection_items as Record<string, unknown>[] | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitId: (row.unit_id as string) || null,
    leaseId: (row.lease_id as string) || null,
    inspectionType: (row.inspection_type as PmInspectionData['inspectionType']) || 'routine',
    inspectedBy: (row.inspected_by as string) || null,
    inspectionDate: row.inspection_date as string,
    overallCondition: (row.overall_condition as PmInspectionData['overallCondition']) || null,
    notes: (row.notes as string) || null,
    status: (row.status as PmInspectionData['status']) || 'scheduled',
    completedAt: row.completed_at ? new Date(row.completed_at as string) : null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    propertyAddress: property ? (property.address_line1 as string) : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
    items: items ? items.map(mapPmInspectionItem) : undefined,
  };
}

// --- PM Inspection Item ---
export interface PmInspectionItemData {
  id: string;
  inspectionId: string;
  area: string;
  item: string;
  condition: 'excellent' | 'good' | 'fair' | 'poor' | 'damaged' | 'missing';
  notes: string | null;
  photos: string[];
  requiresRepair: boolean;
  repairCostEstimate: number | null;
  depositDeduction: number | null;
  createdAt: Date;
}

export function mapPmInspectionItem(row: Record<string, unknown>): PmInspectionItemData {
  return {
    id: row.id as string,
    inspectionId: row.inspection_id as string,
    area: row.area as string,
    item: row.item as string,
    condition: (row.condition as PmInspectionItemData['condition']) || 'good',
    notes: (row.notes as string) || null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    requiresRepair: row.requires_repair === true,
    repairCostEstimate: row.repair_cost_estimate ? Number(row.repair_cost_estimate) : null,
    depositDeduction: row.deposit_deduction ? Number(row.deposit_deduction) : null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- Property Asset ---
export interface PropertyAssetData {
  id: string;
  companyId: string;
  propertyId: string;
  unitId: string | null;
  assetType: 'hvac' | 'water_heater' | 'appliance' | 'roof' | 'plumbing' | 'electrical_panel' | 'flooring' | 'windows' | 'doors' | 'garage' | 'other';
  manufacturer: string | null;
  model: string | null;
  serialNumber: string | null;
  installDate: string | null;
  purchasePrice: number | null;
  warrantyExpiry: string | null;
  expectedLifespanYears: number | null;
  lastServiceDate: string | null;
  nextServiceDue: string | null;
  condition: 'new' | 'excellent' | 'good' | 'fair' | 'poor' | 'replace_soon' | 'failed';
  status: 'active' | 'replaced' | 'removed';
  notes: string | null;
  photos: string[];
  recurringIssues: string[] | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  propertyAddress?: string;
  unitNumber?: string;
}

export function mapPropertyAsset(row: Record<string, unknown>): PropertyAssetData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitId: (row.unit_id as string) || null,
    assetType: (row.asset_type as PropertyAssetData['assetType']) || 'other',
    manufacturer: (row.manufacturer as string) || null,
    model: (row.model as string) || null,
    serialNumber: (row.serial_number as string) || null,
    installDate: (row.install_date as string) || null,
    purchasePrice: row.purchase_price ? Number(row.purchase_price) : null,
    warrantyExpiry: (row.warranty_expiry as string) || null,
    expectedLifespanYears: row.expected_lifespan_years ? Number(row.expected_lifespan_years) : null,
    lastServiceDate: (row.last_service_date as string) || null,
    nextServiceDue: (row.next_service_due as string) || null,
    condition: (row.condition as PropertyAssetData['condition']) || 'good',
    status: (row.status as PropertyAssetData['status']) || 'active',
    notes: (row.notes as string) || null,
    photos: Array.isArray(row.photos) ? row.photos as string[] : [],
    recurringIssues: Array.isArray(row.recurring_issues) ? row.recurring_issues as string[] : null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    propertyAddress: property ? (property.address_line1 as string) : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
  };
}

// --- Asset Service Record ---
export interface AssetServiceRecordData {
  id: string;
  companyId: string;
  assetId: string;
  serviceDate: string;
  serviceType: 'preventive' | 'repair' | 'replacement' | 'inspection' | 'emergency';
  jobId: string | null;
  vendorId: string | null;
  performedByUserId: string | null;
  performedByName: string | null;
  cost: number | null;
  partsUsed: Record<string, unknown>[] | null;
  notes: string | null;
  beforePhotos: string[];
  afterPhotos: string[];
  nextServiceRecommended: string | null;
  createdAt: Date;
}

export function mapAssetServiceRecord(row: Record<string, unknown>): AssetServiceRecordData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    assetId: row.asset_id as string,
    serviceDate: row.service_date as string,
    serviceType: (row.service_type as AssetServiceRecordData['serviceType']) || 'repair',
    jobId: (row.job_id as string) || null,
    vendorId: (row.vendor_id as string) || null,
    performedByUserId: (row.performed_by_user_id as string) || null,
    performedByName: (row.performed_by_name as string) || null,
    cost: row.cost ? Number(row.cost) : null,
    partsUsed: row.parts_used as Record<string, unknown>[] | null,
    notes: (row.notes as string) || null,
    beforePhotos: Array.isArray(row.before_photos) ? row.before_photos as string[] : [],
    afterPhotos: Array.isArray(row.after_photos) ? row.after_photos as string[] : [],
    nextServiceRecommended: (row.next_service_recommended as string) || null,
    createdAt: new Date(row.created_at as string),
  };
}

// --- Unit Turn ---
export interface UnitTurnData {
  id: string;
  companyId: string;
  propertyId: string;
  unitId: string;
  outgoingLeaseId: string | null;
  incomingLeaseId: string | null;
  moveOutDate: string | null;
  targetReadyDate: string | null;
  actualReadyDate: string | null;
  moveOutInspectionId: string | null;
  moveInInspectionId: string | null;
  totalCost: number;
  depositDeductions: number;
  status: 'pending' | 'in_progress' | 'ready' | 'listed' | 'leased';
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  propertyAddress?: string;
  unitNumber?: string;
  tasks?: UnitTurnTaskData[];
}

export function mapUnitTurn(row: Record<string, unknown>): UnitTurnData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const tasks = row.unit_turn_tasks as Record<string, unknown>[] | null;
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    propertyId: row.property_id as string,
    unitId: row.unit_id as string,
    outgoingLeaseId: (row.outgoing_lease_id as string) || null,
    incomingLeaseId: (row.incoming_lease_id as string) || null,
    moveOutDate: (row.move_out_date as string) || null,
    targetReadyDate: (row.target_ready_date as string) || null,
    actualReadyDate: (row.actual_ready_date as string) || null,
    moveOutInspectionId: (row.move_out_inspection_id as string) || null,
    moveInInspectionId: (row.move_in_inspection_id as string) || null,
    totalCost: Number(row.total_cost) || 0,
    depositDeductions: Number(row.deposit_deductions) || 0,
    status: (row.status as UnitTurnData['status']) || 'pending',
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    propertyAddress: property ? (property.address_line1 as string) : undefined,
    unitNumber: unit ? (unit.unit_number as string) : undefined,
    tasks: tasks ? tasks.map(mapUnitTurnTask) : undefined,
  };
}

// --- Unit Turn Task ---
export interface UnitTurnTaskData {
  id: string;
  unitTurnId: string;
  taskType: 'cleaning' | 'painting' | 'flooring' | 'appliance' | 'plumbing' | 'electrical' | 'hvac' | 'general_repair' | 'pest_control' | 'landscaping' | 'inspection' | 'other';
  description: string;
  jobId: string | null;
  assignedTo: string | null;
  vendorId: string | null;
  estimatedCost: number | null;
  actualCost: number | null;
  status: 'pending' | 'in_progress' | 'completed' | 'skipped';
  completedAt: Date | null;
  notes: string | null;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

export function mapUnitTurnTask(row: Record<string, unknown>): UnitTurnTaskData {
  return {
    id: row.id as string,
    unitTurnId: row.unit_turn_id as string,
    taskType: (row.task_type as UnitTurnTaskData['taskType']) || 'other',
    description: row.description as string,
    jobId: (row.job_id as string) || null,
    assignedTo: (row.assigned_to as string) || null,
    vendorId: (row.vendor_id as string) || null,
    estimatedCost: row.estimated_cost ? Number(row.estimated_cost) : null,
    actualCost: row.actual_cost ? Number(row.actual_cost) : null,
    status: (row.status as UnitTurnTaskData['status']) || 'pending',
    completedAt: row.completed_at ? new Date(row.completed_at as string) : null,
    notes: (row.notes as string) || null,
    sortOrder: Number(row.sort_order) || 0,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Approval Threshold ---
export interface ApprovalThresholdData {
  id: string;
  companyId: string;
  entityType: string;
  thresholdAmount: number;
  requiresRole: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export function mapApprovalThreshold(row: Record<string, unknown>): ApprovalThresholdData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    entityType: row.entity_type as string,
    thresholdAmount: Number(row.threshold_amount) || 0,
    requiresRole: row.requires_role as string,
    isActive: row.is_active !== false,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

// --- Helpers ---
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount);
}

export function formatPropertyAddress(p: PropertyData): string {
  const parts = [p.addressLine1];
  if (p.addressLine2) parts.push(p.addressLine2);
  parts.push(`${p.city}, ${p.state} ${p.zip}`);
  return parts.join(', ');
}

export const propertyTypeLabels: Record<PropertyData['propertyType'], string> = {
  single_family: 'Single Family',
  duplex: 'Duplex',
  triplex: 'Triplex',
  quadplex: 'Quadplex',
  multi_unit: 'Multi-Unit',
  commercial: 'Commercial',
  mixed_use: 'Mixed Use',
};

export const unitStatusLabels: Record<UnitData['status'], string> = {
  vacant: 'Vacant',
  occupied: 'Occupied',
  maintenance: 'Maintenance',
  listed: 'Listed',
  unit_turn: 'Unit Turn',
  rehab: 'Rehab',
};

export const maintenanceStatusLabels: Record<MaintenanceRequestData['status'], string> = {
  submitted: 'Submitted',
  reviewed: 'Reviewed',
  scheduled: 'Scheduled',
  in_progress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

export const urgencyLabels: Record<MaintenanceRequestData['urgency'], string> = {
  low: 'Low',
  medium: 'Medium',
  high: 'High',
  emergency: 'Emergency',
};

export const leaseStatusLabels: Record<LeaseData['status'], string> = {
  draft: 'Draft',
  active: 'Active',
  expired: 'Expired',
  terminated: 'Terminated',
  renewed: 'Renewed',
};

export const turnStatusLabels: Record<UnitTurnData['status'], string> = {
  pending: 'Pending',
  in_progress: 'In Progress',
  ready: 'Ready',
  listed: 'Listed',
  leased: 'Leased',
};
