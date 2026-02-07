// Zafto Web Portal - Core Types

// ==================== USER & AUTH ====================
export interface User {
  id: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  companyId: string;
  role: UserRole;
  createdAt: Date;
}

export type UserRole = 'owner' | 'admin' | 'office' | 'field_tech' | 'subcontractor';

// ==================== COMPANY ====================
export interface Company {
  id: string;
  name: string;
  trade: string;
  email: string;
  phone: string;
  address: Address;
  logo?: string;
  website?: string;
  licenseNumber?: string;
  insuranceExpiry?: Date;
  stripeAccountId?: string;
  subscriptionTier: SubscriptionTier;
  createdAt: Date;
}

export type SubscriptionTier = 'solo' | 'pro' | 'team' | 'business' | 'enterprise';

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
}

// ==================== CUSTOMERS ====================
export interface Customer {
  id: string;
  companyId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: Address;
  tags: string[];
  notes?: string;
  source?: string;
  totalRevenue: number;
  jobCount: number;
  createdAt: Date;
  updatedAt: Date;
}

// ==================== BIDS ====================
export interface Bid {
  id: string;
  companyId: string;
  bidNumber: string;
  customerId?: string;
  customer?: Customer;

  // Customer info (denormalized for offline)
  customerName: string;
  customerEmail?: string;
  customerPhone?: string;
  customerAddress?: Address;

  // Job site (can differ from customer)
  jobSiteAddress?: Address;
  jobSiteSameAsCustomer: boolean;

  // Project details
  title: string;
  description?: string;
  scopeOfWork?: string;
  trade?: string;

  // Status
  status: BidStatus;

  // Pricing - can have single option or multiple (Good/Better/Best)
  options: BidOption[];
  selectedOptionId?: string;

  // Add-ons (optional extras)
  addOns: BidAddOn[];
  selectedAddOnIds: string[];

  // Totals (calculated from selected option + add-ons)
  subtotal: number;
  taxRate: number;
  tax: number;
  discountAmount: number;
  discountReason?: string;
  total: number;

  // Deposit
  depositPercent: number;
  depositAmount: number;
  depositPaid: boolean;
  depositPaidAt?: Date;
  depositPaymentId?: string;

  // Validity
  validUntil: Date;
  estimatedStartDate?: Date;
  estimatedDuration?: string;

  // Terms
  termsAndConditions?: string;
  internalNotes?: string;

  // Signatures
  signatureData?: string;
  signedByName?: string;
  signedAt?: Date;

  // Timestamps
  sentAt?: Date;
  viewedAt?: Date;
  respondedAt?: Date;
  convertedToJobId?: string;
  createdAt: Date;
  updatedAt: Date;

  // Client portal
  accessToken?: string;
}

export type BidStatus = 'draft' | 'sent' | 'viewed' | 'accepted' | 'rejected' | 'expired' | 'converted';

export interface BidOption {
  id: string;
  name: string;
  description?: string;
  lineItems: BidLineItem[];
  subtotal: number;
  taxAmount: number;
  total: number;
  isRecommended: boolean;
  sortOrder: number;
}

export interface BidLineItem {
  id: string;
  description: string;
  quantity: number;
  unit: string;
  unitCost?: number;  // Hidden from customer
  unitPrice: number;
  total: number;
  category: LineItemCategory;
  isTaxable: boolean;
  notes?: string;
  calculatorId?: string;
  sortOrder: number;
}

export type LineItemCategory = 'labor' | 'materials' | 'equipment' | 'permits' | 'subcontractor' | 'fee' | 'other';

export interface BidAddOn {
  id: string;
  name: string;
  description?: string;
  price: number;
  isSelected: boolean;
}

// ==================== JOB TYPES ====================
export type JobType = 'standard' | 'insurance_claim' | 'warranty_dispatch';

export interface InsuranceMetadata {
  claimNumber: string;
  policyNumber?: string;
  insuranceCompany: string;
  adjusterName?: string;
  adjusterPhone?: string;
  adjusterEmail?: string;
  dateOfLoss: string;
  deductible?: number;
  coverageLimit?: number;
  approvalStatus?: 'pending' | 'approved' | 'denied' | 'supplemental';
}

export interface WarrantyMetadata {
  warrantyCompany: string;
  dispatchNumber: string;
  authorizationLimit?: number;
  serviceFee?: number;
  warrantyType?: 'home_warranty' | 'manufacturer' | 'extended';
  expirationDate?: string;
  recallId?: string;
}

// ==================== JOBS ====================
export interface Job {
  id: string;
  companyId: string;
  customerId: string;
  customer?: Customer;
  bidId?: string;
  title: string;
  description?: string;
  jobType: JobType;
  typeMetadata: InsuranceMetadata | WarrantyMetadata | Record<string, unknown>;
  status: JobStatus;
  priority: JobPriority;
  address: Address;
  scheduledStart?: Date;
  scheduledEnd?: Date;
  actualStart?: Date;
  actualEnd?: Date;
  assignedTo: string[];
  teamMembers?: TeamMember[];
  estimatedValue: number;
  actualCost: number;
  notes: JobNote[];
  photos: JobPhoto[];
  source: string;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

export type JobStatus =
  | 'lead'
  | 'scheduled'
  | 'in_progress'
  | 'on_hold'
  | 'completed'
  | 'invoiced'
  | 'paid'
  | 'cancelled';

export type JobPriority = 'low' | 'normal' | 'high' | 'urgent';

export interface JobNote {
  id: string;
  content: string;
  authorId: string;
  authorName: string;
  createdAt: Date;
}

export interface JobPhoto {
  id: string;
  url: string;
  caption?: string;
  type: 'before' | 'during' | 'after' | 'receipt' | 'other';
  uploadedAt: Date;
}

// ==================== INVOICES ====================
export interface Invoice {
  id: string;
  companyId: string;
  customerId: string;
  customer?: Customer;
  jobId?: string;
  invoiceNumber: string;
  status: InvoiceStatus;
  lineItems: InvoiceLineItem[];
  subtotal: number;
  taxRate: number;
  tax: number;
  total: number;
  amountPaid: number;
  amountDue: number;
  dueDate: Date;
  sentAt?: Date;
  paidAt?: Date;
  paymentMethod?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export type InvoiceStatus =
  | 'draft'
  | 'sent'
  | 'viewed'
  | 'partial'
  | 'paid'
  | 'overdue'
  | 'void'
  | 'refunded';

export type PaymentSource = 'standard' | 'carrier' | 'deductible' | 'upgrade';

export interface InvoiceLineItem {
  id: string;
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
  paymentSource?: PaymentSource;
}

// ==================== TEAM ====================
export interface TeamMember {
  id: string;
  companyId: string;
  userId: string;
  email: string;
  name: string;
  role: UserRole;
  phone?: string;
  avatar?: string;
  isActive: boolean;
  lastActive?: Date;
  location?: {
    lat: number;
    lng: number;
    timestamp: Date;
  };
  createdAt: Date;
}

// ==================== CALENDAR ====================
export interface ScheduledItem {
  id: string;
  type: 'job' | 'appointment' | 'reminder';
  title: string;
  description?: string;
  start: Date;
  end: Date;
  allDay: boolean;
  jobId?: string;
  customerId?: string;
  assignedTo: string[];
  color?: string;
}

// ==================== FINANCES (ZAFTO BOOKS) ====================
export interface BankAccount {
  id: string;
  companyId: string;
  plaidItemId: string;
  plaidAccountId: string;
  name: string;
  officialName?: string;
  type: 'checking' | 'savings' | 'credit';
  subtype?: string;
  mask: string;
  currentBalance: number;
  availableBalance?: number;
  lastSynced: Date;
  isActive: boolean;
}

export interface Transaction {
  id: string;
  companyId: string;
  bankAccountId: string;
  plaidTransactionId?: string;
  date: Date;
  description: string;
  merchantName?: string;
  amount: number;
  category: TransactionCategory;
  categoryConfidence?: number;
  isIncome: boolean;
  invoiceId?: string;
  notes?: string;
  isReviewed: boolean;
  createdAt: Date;
}

export type TransactionCategory =
  | 'materials'
  | 'labor'
  | 'fuel'
  | 'tools'
  | 'equipment'
  | 'vehicle'
  | 'insurance'
  | 'permits'
  | 'advertising'
  | 'office'
  | 'utilities'
  | 'subcontractor'
  | 'income'
  | 'refund'
  | 'transfer'
  | 'uncategorized';

export interface FinancialSummary {
  period: 'week' | 'month' | 'quarter' | 'year';
  startDate: Date;
  endDate: Date;
  totalIncome: number;
  totalExpenses: number;
  netProfit: number;
  incomeByCategory: Record<string, number>;
  expensesByCategory: Record<TransactionCategory, number>;
}

// ==================== AI ASSISTANT ====================
export interface AIThread {
  id: string;
  companyId: string;
  userId: string;
  title: string;
  messageCount: number;
  lastMessageAt: Date;
  linkedEntity?: {
    type: 'job' | 'customer' | 'bid' | 'invoice' | 'general';
    id: string;
    name: string;
  };
  createdAt: Date;
}

export interface AIMessage {
  id: string;
  threadId: string;
  role: 'user' | 'assistant';
  content: string;
  toolCalls?: AIToolCall[];
  createdAt: Date;
}

export interface AIToolCall {
  id: string;
  name: string;
  arguments: Record<string, unknown>;
  result?: unknown;
  status: 'pending' | 'approved' | 'executed' | 'rejected';
}

// ==================== ACTIVITY ====================
export interface Activity {
  id: string;
  companyId: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  type: ActivityType;
  entityType: 'bid' | 'job' | 'invoice' | 'customer' | 'team' | 'system';
  entityId: string;
  entityName: string;
  description: string;
  createdAt: Date;
}

export type ActivityType =
  | 'created'
  | 'updated'
  | 'deleted'
  | 'sent'
  | 'viewed'
  | 'accepted'
  | 'rejected'
  | 'paid'
  | 'signed'
  | 'assigned'
  | 'completed'
  | 'comment';

// ==================== STATS ====================
export interface DashboardStats {
  bids: {
    pending: number;
    sent: number;
    accepted: number;
    totalValue: number;
    conversionRate: number;
  };
  jobs: {
    scheduled: number;
    inProgress: number;
    completed: number;
    completedThisMonth: number;
  };
  invoices: {
    draft: number;
    sent: number;
    overdue: number;
    overdueAmount: number;
    paidThisMonth: number;
  };
  revenue: {
    today: number;
    thisWeek: number;
    thisMonth: number;
    lastMonth: number;
    monthOverMonthChange: number;
  };
}

// ==================== REPORTS ====================
export interface RevenueReport {
  period: string;
  startDate: Date;
  endDate: Date;
  data: {
    date: string;
    revenue: number;
    expenses: number;
    profit: number;
  }[];
  totals: {
    revenue: number;
    expenses: number;
    profit: number;
  };
}

export interface JobsReport {
  period: string;
  completed: number;
  averageValue: number;
  averageDuration: number;
  byStatus: Record<JobStatus, number>;
  byTech: { techId: string; techName: string; count: number }[];
}

// ==================== INSURANCE / RESTORATION ====================

export type ClaimStatus =
  | 'new'
  | 'scope_requested'
  | 'scope_submitted'
  | 'estimate_pending'
  | 'estimate_approved'
  | 'supplement_submitted'
  | 'supplement_approved'
  | 'work_in_progress'
  | 'work_complete'
  | 'final_inspection'
  | 'settled'
  | 'closed'
  | 'denied';

export type LossType =
  | 'fire'
  | 'water'
  | 'storm'
  | 'wind'
  | 'hail'
  | 'theft'
  | 'vandalism'
  | 'mold'
  | 'flood'
  | 'earthquake'
  | 'other'
  | 'unknown';

export type SupplementStatus =
  | 'draft'
  | 'submitted'
  | 'under_review'
  | 'approved'
  | 'denied'
  | 'partially_approved';

export type SupplementReason =
  | 'hidden_damage'
  | 'code_upgrade'
  | 'scope_change'
  | 'material_upgrade'
  | 'additional_repair'
  | 'other';

export type TpiInspectionType =
  | 'initial'
  | 'progress'
  | 'supplement'
  | 'final'
  | 're_inspection';

export type TpiStatus =
  | 'pending'
  | 'scheduled'
  | 'confirmed'
  | 'in_progress'
  | 'completed'
  | 'cancelled'
  | 'rescheduled';

export type TpiResult = 'passed' | 'failed' | 'conditional' | 'deferred';

export type EquipmentType =
  | 'dehumidifier'
  | 'air_mover'
  | 'air_scrubber'
  | 'heater'
  | 'moisture_meter'
  | 'thermal_camera'
  | 'hydroxyl_generator'
  | 'negative_air_machine'
  | 'other';

export type EquipmentStatus = 'deployed' | 'removed' | 'maintenance' | 'lost';

export type MaterialMoistureType =
  | 'drywall'
  | 'wood'
  | 'concrete'
  | 'carpet'
  | 'pad'
  | 'insulation'
  | 'subfloor'
  | 'hardwood'
  | 'laminate'
  | 'tile_backer'
  | 'other';

export type ReadingUnit = 'percent' | 'relative' | 'wme' | 'grains';

export type DryingLogType =
  | 'setup'
  | 'daily'
  | 'adjustment'
  | 'equipment_change'
  | 'completion'
  | 'note';

export type ClaimCategory = 'restoration' | 'storm' | 'reconstruction' | 'commercial';

export interface InsuranceClaimData {
  id: string;
  companyId: string;
  jobId: string;
  insuranceCompany: string;
  claimNumber: string;
  policyNumber?: string;
  dateOfLoss: string;
  lossType: LossType;
  lossDescription?: string;
  adjusterName?: string;
  adjusterPhone?: string;
  adjusterEmail?: string;
  adjusterCompany?: string;
  deductible: number;
  coverageLimit?: number;
  approvedAmount?: number;
  supplementTotal: number;
  depreciation: number;
  acv?: number;
  rcv?: number;
  depreciationRecovered: boolean;
  amountCollected: number;
  claimStatus: ClaimStatus;
  claimCategory: ClaimCategory;
  scopeSubmittedAt?: string;
  estimateApprovedAt?: string;
  workStartedAt?: string;
  workCompletedAt?: string;
  settledAt?: string;
  xactimateClaimId?: string;
  xactimateFileUrl?: string;
  notes?: string;
  data: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
  // Joined
  job?: { title: string; customer_name: string; address?: string };
}

// Category-specific JSONB data structures
export interface StormClaimData {
  weatherEventDate?: string;
  stormSeverity: 'minor' | 'moderate' | 'severe' | 'catastrophic';
  aerialAssessmentNeeded: boolean;
  batchEventId?: string;
  emergencyTarped: boolean;
  temporaryRepairs?: string;
  weatherEventType?: 'hurricane' | 'tornado' | 'hailstorm' | 'thunderstorm' | 'ice_storm' | 'flood';
  affectedUnits?: number;
}

export interface ReconstructionClaimData {
  currentPhase: 'scope_review' | 'selections' | 'materials' | 'demo' | 'rough_in' | 'inspection' | 'finish' | 'walkthrough' | 'supplements' | 'payment';
  phases: { name: string; status: 'pending' | 'in_progress' | 'complete'; budgetAmount?: number; completionPercent?: number }[];
  multiContractor: boolean;
  expectedDurationMonths?: number;
  permitsRequired: boolean;
  permitStatus?: 'not_applied' | 'pending' | 'approved' | 'denied';
}

export interface CommercialClaimData {
  propertyType?: 'office' | 'retail' | 'warehouse' | 'restaurant' | 'industrial' | 'multi_unit' | 'hotel' | 'other';
  businessName?: string;
  tenantName?: string;
  tenantContact?: string;
  businessIncomeLoss?: number;
  businessInterruptionDays?: number;
  emergencyAuthAmount?: number;
  emergencyServiceAuthorized: boolean;
}

export interface ClaimSupplementData {
  id: string;
  companyId: string;
  claimId: string;
  supplementNumber: number;
  title: string;
  description?: string;
  reason: SupplementReason;
  amount: number;
  rcvAmount?: number;
  acvAmount?: number;
  depreciationAmount: number;
  status: SupplementStatus;
  approvedAmount?: number;
  lineItems: Record<string, unknown>[];
  photos: Record<string, unknown>[];
  submittedAt?: string;
  reviewedAt?: string;
  reviewerNotes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface TpiInspectionData {
  id: string;
  companyId: string;
  claimId: string;
  jobId: string;
  inspectorName?: string;
  inspectorCompany?: string;
  inspectorPhone?: string;
  inspectorEmail?: string;
  inspectionType: TpiInspectionType;
  scheduledDate?: string;
  completedDate?: string;
  status: TpiStatus;
  result?: TpiResult;
  findings?: string;
  photos: Record<string, unknown>[];
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface MoistureReadingData {
  id: string;
  companyId: string;
  jobId: string;
  claimId?: string;
  areaName: string;
  floorLevel?: string;
  materialType: MaterialMoistureType;
  readingValue: number;
  readingUnit: ReadingUnit;
  targetValue?: number;
  meterType?: string;
  meterModel?: string;
  ambientTempF?: number;
  ambientHumidity?: number;
  isDry: boolean;
  recordedByUserId?: string;
  recordedAt: string;
  createdAt: string;
}

export interface DryingLogData {
  id: string;
  companyId: string;
  jobId: string;
  claimId?: string;
  logType: DryingLogType;
  summary: string;
  details?: string;
  equipmentCount: number;
  dehumidifiersRunning: number;
  airMoversRunning: number;
  airScrubbersRunning: number;
  outdoorTempF?: number;
  outdoorHumidity?: number;
  indoorTempF?: number;
  indoorHumidity?: number;
  photos: Record<string, unknown>[];
  recordedByUserId?: string;
  recordedAt: string;
  createdAt: string;
}

export interface RestorationEquipmentData {
  id: string;
  companyId: string;
  jobId: string;
  claimId?: string;
  equipmentType: EquipmentType;
  make?: string;
  model?: string;
  serialNumber?: string;
  assetTag?: string;
  areaDeployed: string;
  deployedAt: string;
  removedAt?: string;
  dailyRate: number;
  totalDays?: number;
  status: EquipmentStatus;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}
