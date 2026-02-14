// DB → TypeScript mappers for Team Portal
// Adapted from web-portal/src/lib/hooks/mappers.ts

// ==================== JOB TYPES ====================

export type JobType = 'standard' | 'insurance_claim' | 'warranty_dispatch';

export interface InsuranceMetadata {
  claimNumber: string;
  policyNumber?: string;
  insuranceCompany: string;
  adjustorName?: string;
  adjustorPhone?: string;
  adjustorEmail?: string;
  dateOfLoss?: string;
  deductible?: number;
  coveredAmount?: number;
  approvalStatus?: 'pending' | 'approved' | 'denied' | 'supplemental';
}

export interface WarrantyMetadata {
  warrantyCompany: string;
  dispatchNumber: string;
  authorizationLimit?: number;
  warrantyType?: string;
  contractNumber?: string;
  expirationDate?: string;
  coveredComponents?: string[];
  notToExceed?: number;
}

export interface JobData {
  id: string;
  title: string;
  customerName: string;
  address: string;
  city: string;
  state: string;
  status: string;
  type: string;
  jobType: JobType;
  typeMetadata: InsuranceMetadata | WarrantyMetadata | Record<string, unknown>;
  propertyId: string | null;
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
  locationPings: Array<{ lat: number; lng: number; timestamp: string; type: string }>;
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

export interface CertificationData {
  id: string;
  userId: string;
  companyId: string;
  certificationType: string;
  certificationName: string;
  issuingAuthority: string | null;
  certificationNumber: string | null;
  issuedDate: string | null;
  expirationDate: string | null;
  renewalRequired: boolean;
  renewalReminderDays: number;
  documentUrl: string | null;
  status: 'active' | 'expired' | 'pending_renewal' | 'revoked';
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export function mapCertification(row: Record<string, unknown>): CertificationData {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    companyId: row.company_id as string,
    certificationType: (row.certification_type as string) || 'other',
    certificationName: (row.certification_name as string) || '',
    issuingAuthority: row.issuing_authority as string | null,
    certificationNumber: row.certification_number as string | null,
    issuedDate: row.issued_date as string | null,
    expirationDate: row.expiration_date as string | null,
    renewalRequired: (row.renewal_required as boolean) ?? true,
    renewalReminderDays: (row.renewal_reminder_days as number) ?? 30,
    documentUrl: row.document_url as string | null,
    status: (row.status as CertificationData['status']) || 'active',
    notes: row.notes as string | null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
    updatedAt: (row.updated_at as string) || new Date().toISOString(),
  };
}

// --- Certification Type Config (from certification_types table) ---

export interface CertificationTypeConfig {
  typeKey: string;
  displayName: string;
  category: string;
  description: string | null;
  regulationReference: string | null;
  isSystem: boolean;
}

export function mapCertificationType(row: Record<string, unknown>): CertificationTypeConfig {
  return {
    typeKey: (row.type_key as string) || 'other',
    displayName: (row.display_name as string) || '',
    category: (row.category as string) || 'trade',
    description: row.description as string | null,
    regulationReference: row.regulation_reference as string | null,
    isSystem: (row.is_system as boolean) ?? false,
  };
}

// ==================== INSURANCE / RESTORATION ====================

export type ClaimStatus =
  | 'new' | 'scope_requested' | 'scope_submitted' | 'estimate_pending'
  | 'estimate_approved' | 'supplement_submitted' | 'supplement_approved'
  | 'work_in_progress' | 'work_complete' | 'final_inspection'
  | 'settled' | 'closed' | 'denied';

export type EquipmentStatus = 'deployed' | 'removed' | 'maintenance' | 'lost';
export type EquipmentType = 'dehumidifier' | 'air_mover' | 'air_scrubber' | 'heater' | 'moisture_meter' | 'thermal_camera' | 'hydroxyl_generator' | 'negative_air_machine' | 'other';
export type MaterialMoistureType = 'drywall' | 'wood' | 'concrete' | 'carpet' | 'pad' | 'insulation' | 'subfloor' | 'hardwood' | 'laminate' | 'tile_backer' | 'other';
export type ReadingUnit = 'percent' | 'relative' | 'wme' | 'grains';
export type DryingLogType = 'setup' | 'daily' | 'adjustment' | 'equipment_change' | 'completion' | 'note';
export type TpiInspectionType = 'initial' | 'progress' | 'supplement' | 'final' | 're_inspection';
export type TpiStatus = 'pending' | 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled' | 'rescheduled';
export type TpiResult = 'passed' | 'failed' | 'conditional' | 'deferred';

export type ClaimCategory = 'restoration' | 'storm' | 'reconstruction' | 'commercial';

export interface InsuranceClaimSummary {
  id: string;
  jobId: string;
  insuranceCompany: string;
  claimNumber: string;
  dateOfLoss: string;
  claimStatus: ClaimStatus;
  claimCategory: ClaimCategory;
  deductible: number;
  approvedAmount?: number;
  workStartedAt?: string;
  workCompletedAt?: string;
}

export interface MoistureReadingData {
  id: string;
  jobId: string;
  claimId?: string;
  areaName: string;
  materialType: MaterialMoistureType;
  readingValue: number;
  readingUnit: ReadingUnit;
  targetValue?: number;
  isDry: boolean;
  recordedAt: string;
}

export interface DryingLogData {
  id: string;
  jobId: string;
  claimId?: string;
  logType: DryingLogType;
  summary: string;
  equipmentCount: number;
  dehumidifiersRunning: number;
  airMoversRunning: number;
  airScrubbersRunning: number;
  indoorTempF?: number;
  indoorHumidity?: number;
  recordedAt: string;
}

export interface RestorationEquipmentData {
  id: string;
  jobId: string;
  claimId?: string;
  equipmentType: EquipmentType;
  serialNumber?: string;
  areaDeployed: string;
  deployedAt: string;
  removedAt?: string;
  status: EquipmentStatus;
}

export interface TpiInspectionData {
  id: string;
  claimId: string;
  inspectionType: TpiInspectionType;
  scheduledDate?: string;
  completedDate?: string;
  status: TpiStatus;
  result?: TpiResult;
  inspectorName?: string;
}

export function mapInsuranceClaim(row: Record<string, unknown>): InsuranceClaimSummary {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    insuranceCompany: (row.insurance_company as string) || '',
    claimNumber: (row.claim_number as string) || '',
    dateOfLoss: (row.date_of_loss as string) || '',
    claimStatus: (row.claim_status as ClaimStatus) || 'new',
    claimCategory: (row.claim_category as ClaimCategory) || 'restoration',
    deductible: Number(row.deductible) || 0,
    approvedAmount: row.approved_amount != null ? Number(row.approved_amount) : undefined,
    workStartedAt: (row.work_started_at as string) || undefined,
    workCompletedAt: (row.work_completed_at as string) || undefined,
  };
}

export function mapMoistureReading(row: Record<string, unknown>): MoistureReadingData {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    claimId: (row.claim_id as string) || undefined,
    areaName: (row.area_name as string) || '',
    materialType: (row.material_type as MaterialMoistureType) || 'drywall',
    readingValue: Number(row.reading_value) || 0,
    readingUnit: (row.reading_unit as ReadingUnit) || 'percent',
    targetValue: row.target_value != null ? Number(row.target_value) : undefined,
    isDry: (row.is_dry as boolean) || false,
    recordedAt: (row.recorded_at as string) || '',
  };
}

export function mapDryingLog(row: Record<string, unknown>): DryingLogData {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    claimId: (row.claim_id as string) || undefined,
    logType: (row.log_type as DryingLogType) || 'daily',
    summary: (row.summary as string) || '',
    equipmentCount: (row.equipment_count as number) || 0,
    dehumidifiersRunning: (row.dehumidifiers_running as number) || 0,
    airMoversRunning: (row.air_movers_running as number) || 0,
    airScrubbersRunning: (row.air_scrubbers_running as number) || 0,
    indoorTempF: row.indoor_temp_f != null ? Number(row.indoor_temp_f) : undefined,
    indoorHumidity: row.indoor_humidity != null ? Number(row.indoor_humidity) : undefined,
    recordedAt: (row.recorded_at as string) || '',
  };
}

export function mapRestorationEquipment(row: Record<string, unknown>): RestorationEquipmentData {
  return {
    id: row.id as string,
    jobId: row.job_id as string,
    claimId: (row.claim_id as string) || undefined,
    equipmentType: (row.equipment_type as EquipmentType) || 'other',
    serialNumber: (row.serial_number as string) || undefined,
    areaDeployed: (row.area_deployed as string) || '',
    deployedAt: (row.deployed_at as string) || '',
    removedAt: (row.removed_at as string) || undefined,
    status: (row.status as EquipmentStatus) || 'deployed',
  };
}

export function mapTpiInspection(row: Record<string, unknown>): TpiInspectionData {
  return {
    id: row.id as string,
    claimId: row.claim_id as string,
    inspectionType: (row.inspection_type as TpiInspectionType) || 'progress',
    scheduledDate: (row.scheduled_date as string) || undefined,
    completedDate: (row.completed_date as string) || undefined,
    status: (row.status as TpiStatus) || 'pending',
    result: (row.result as TpiResult) || undefined,
    inspectorName: (row.inspector_name as string) || undefined,
  };
}

// ==================== PROPERTY MANAGEMENT ====================

export type MaintenanceRequestStatus = 'new' | 'assigned' | 'in_progress' | 'on_hold' | 'completed' | 'cancelled';
export type MaintenanceUrgency = 'low' | 'normal' | 'high' | 'emergency';

export interface MaintenanceRequestData {
  id: string;
  propertyId: string;
  unitId: string | null;
  tenantId: string | null;
  jobId: string | null;
  title: string;
  description: string;
  category: string;
  urgency: MaintenanceUrgency;
  status: MaintenanceRequestStatus;
  assignedTo: string[];
  propertyName: string;
  unitNumber: string | null;
  tenantName: string | null;
  tenantPhone: string | null;
  tenantEmail: string | null;
  photos: string[];
  scheduledDate: string | null;
  completedAt: string | null;
  createdAt: string;
}

export interface PropertySummary {
  id: string;
  name: string;
  address: string;
  city: string;
  state: string;
  propertyType: string;
  unitCount: number;
}

export interface PropertyAssetData {
  id: string;
  propertyId: string;
  unitId: string | null;
  assetType: string;
  brand: string;
  model: string;
  serialNumber: string | null;
  installDate: string | null;
  warrantyExpiration: string | null;
  lastServiceDate: string | null;
  nextServiceDate: string | null;
  condition: string;
  notes: string;
}

export function mapMaintenanceRequest(row: Record<string, unknown>): MaintenanceRequestData {
  const property = row.properties as Record<string, unknown> | null;
  const unit = row.units as Record<string, unknown> | null;
  const tenant = row.tenants as Record<string, unknown> | null;
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    unitId: (row.unit_id as string) || null,
    tenantId: (row.tenant_id as string) || null,
    jobId: (row.job_id as string) || null,
    title: (row.title as string) || '',
    description: (row.description as string) || '',
    category: (row.category as string) || 'general',
    urgency: (row.urgency as MaintenanceUrgency) || 'normal',
    status: (row.status as MaintenanceRequestStatus) || 'new',
    assignedTo: (row.assigned_user_ids as string[]) || [],
    propertyName: (property?.name as string) || '',
    unitNumber: (unit?.unit_number as string) || null,
    tenantName: (tenant?.name as string) || null,
    tenantPhone: (tenant?.phone as string) || null,
    tenantEmail: (tenant?.email as string) || null,
    photos: (row.photos as string[]) || [],
    scheduledDate: (row.scheduled_date as string) || null,
    completedAt: (row.completed_at as string) || null,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

export function mapPropertySummary(row: Record<string, unknown>): PropertySummary {
  return {
    id: row.id as string,
    name: (row.name as string) || '',
    address: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    propertyType: (row.property_type as string) || 'residential',
    unitCount: (row.unit_count as number) || 0,
  };
}

export function mapPropertyAsset(row: Record<string, unknown>): PropertyAssetData {
  return {
    id: row.id as string,
    propertyId: row.property_id as string,
    unitId: (row.unit_id as string) || null,
    assetType: (row.asset_type as string) || '',
    brand: (row.brand as string) || '',
    model: (row.model as string) || '',
    serialNumber: (row.serial_number as string) || null,
    installDate: (row.install_date as string) || null,
    warrantyExpiration: (row.warranty_expiration as string) || null,
    lastServiceDate: (row.last_service_date as string) || null,
    nextServiceDate: (row.next_service_date as string) || null,
    condition: (row.condition as string) || 'good',
    notes: (row.notes as string) || '',
  };
}

export const URGENCY_COLORS: Record<MaintenanceUrgency, { bg: string; text: string }> = {
  low: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-600 dark:text-slate-400' },
  normal: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-600 dark:text-blue-400' },
  high: { bg: 'bg-orange-100 dark:bg-orange-900/30', text: 'text-orange-600 dark:text-orange-400' },
  emergency: { bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-600 dark:text-red-400' },
};

export const MAINTENANCE_STATUS_LABELS: Record<MaintenanceRequestStatus, string> = {
  new: 'New',
  assigned: 'Assigned',
  in_progress: 'In Progress',
  on_hold: 'On Hold',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

// --- Job Type Maps ---

export const JOB_TYPE_LABELS: Record<JobType, string> = {
  standard: 'Standard',
  insurance_claim: 'Insurance Claim',
  warranty_dispatch: 'Warranty Dispatch',
};

export const JOB_TYPE_COLORS: Record<JobType, { bg: string; text: string; dot: string }> = {
  standard: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-700 dark:text-blue-300', dot: 'bg-blue-500' },
  insurance_claim: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-700 dark:text-amber-300', dot: 'bg-amber-500' },
  warranty_dispatch: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-700 dark:text-purple-300', dot: 'bg-purple-500' },
};

// --- Mappers ---

const JOB_STATUS_FROM_DB: Record<string, string> = {
  draft: 'draft', scheduled: 'scheduled', dispatched: 'dispatched',
  enRoute: 'en_route', en_route: 'en_route',
  inProgress: 'in_progress', in_progress: 'in_progress',
  onHold: 'on_hold', on_hold: 'on_hold',
  completed: 'completed', invoiced: 'invoiced', cancelled: 'cancelled',
};

export function mapJob(row: Record<string, unknown>): JobData {
  const jobType = ((row.job_type as string) || 'standard') as JobType;
  return {
    id: row.id as string,
    title: (row.title as string) || 'Untitled Job',
    customerName: (row.customer_name as string) || '',
    address: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    status: JOB_STATUS_FROM_DB[(row.status as string)] || (row.status as string) || 'draft',
    type: jobType,
    jobType,
    typeMetadata: (row.type_metadata as Record<string, unknown>) || {},
    propertyId: (row.property_id as string) || null,
    scheduledStart: (row.scheduled_start as string) || null,
    scheduledEnd: (row.scheduled_end as string) || null,
    description: (row.description as string) || '',
    assignedTo: (row.assigned_user_ids as string[]) || [],
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
    locationPings: Array.isArray(row.location_pings) ? row.location_pings as Array<{ lat: number; lng: number; timestamp: string; type: string }> : [],
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
    assignedTo: (row.assigned_to_user_id as string) || null,
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
    orderNumber: (row.change_order_number as string) || '',
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
    totalAmount: (row.total as number) || 0,
    createdAt: (row.created_at as string) || new Date().toISOString(),
  };
}

// ==================== ESTIMATES ====================

export type EstimateType = 'regular' | 'insurance';
export type EstimateStatus = 'draft' | 'sent' | 'approved' | 'declined' | 'revised' | 'completed';

export const ESTIMATE_STATUS_LABELS: Record<EstimateStatus, string> = {
  draft: 'Draft', sent: 'Sent', approved: 'Approved',
  declined: 'Declined', revised: 'Revised', completed: 'Completed',
};

export const ESTIMATE_STATUS_COLORS: Record<EstimateStatus, { bg: string; text: string }> = {
  draft: { bg: 'bg-slate-100 dark:bg-slate-900/30', text: 'text-slate-600 dark:text-slate-400' },
  sent: { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-600 dark:text-blue-400' },
  approved: { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-600 dark:text-emerald-400' },
  declined: { bg: 'bg-red-100 dark:bg-red-900/30', text: 'text-red-600 dark:text-red-400' },
  revised: { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-600 dark:text-amber-400' },
  completed: { bg: 'bg-purple-100 dark:bg-purple-900/30', text: 'text-purple-600 dark:text-purple-400' },
};

export interface EstimateData {
  id: string;
  jobId: string | null;
  customerId: string | null;
  customerName: string;
  propertyAddress: string;
  estimateNumber: string;
  title: string;
  estimateType: EstimateType;
  status: EstimateStatus;
  subtotal: number;
  overheadPercent: number;
  overheadAmount: number;
  profitPercent: number;
  profitAmount: number;
  taxPercent: number;
  taxAmount: number;
  grandTotal: number;
  notes: string;
  claimNumber: string;
  carrierName: string;
  deductible: number;
  validUntil: string | null;
  sentAt: string | null;
  createdAt: string;
}

export interface EstimateAreaData {
  id: string;
  estimateId: string;
  name: string;
  lengthFt: number;
  widthFt: number;
  heightFt: number;
  floorSf: number;
  sortOrder: number;
}

export interface EstimateLineItemData {
  id: string;
  estimateId: string;
  areaId: string | null;
  zaftoCode: string;
  description: string;
  actionType: string;
  quantity: number;
  unitCode: string;
  unitPrice: number;
  lineTotal: number;
  sortOrder: number;
}

export function mapEstimate(row: Record<string, unknown>): EstimateData {
  return {
    id: row.id as string,
    jobId: row.job_id as string | null,
    customerId: row.customer_id as string | null,
    customerName: (row.customer_name as string) || '',
    propertyAddress: (row.property_address as string) || '',
    estimateNumber: (row.estimate_number as string) || '',
    title: (row.title as string) || '',
    estimateType: (row.estimate_type as EstimateType) || 'regular',
    status: (row.status as EstimateStatus) || 'draft',
    subtotal: Number(row.subtotal || 0),
    overheadPercent: Number(row.overhead_percent || 0),
    overheadAmount: Number(row.overhead_amount || 0),
    profitPercent: Number(row.profit_percent || 0),
    profitAmount: Number(row.profit_amount || 0),
    taxPercent: Number(row.tax_percent || 0),
    taxAmount: Number(row.tax_amount || 0),
    grandTotal: Number(row.grand_total || 0),
    notes: (row.notes as string) || '',
    claimNumber: (row.claim_number as string) || '',
    carrierName: (row.carrier_name as string) || '',
    deductible: Number(row.deductible || 0),
    validUntil: row.valid_until as string | null,
    sentAt: row.sent_at as string | null,
    createdAt: (row.created_at as string) || '',
  };
}

export function mapEstimateArea(row: Record<string, unknown>): EstimateAreaData {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    name: (row.name as string) || '',
    lengthFt: Number(row.length_ft || 0),
    widthFt: Number(row.width_ft || 0),
    heightFt: Number(row.height_ft || 8),
    floorSf: Number(row.floor_sf || 0),
    sortOrder: Number(row.sort_order || 0),
  };
}

export function mapEstimateLineItem(row: Record<string, unknown>): EstimateLineItemData {
  return {
    id: row.id as string,
    estimateId: row.estimate_id as string,
    areaId: row.area_id as string | null,
    zaftoCode: (row.zafto_code as string) || '',
    description: (row.description as string) || '',
    actionType: (row.action_type as string) || 'replace',
    quantity: Number(row.quantity || 1),
    unitCode: (row.unit_code as string) || 'EA',
    unitPrice: Number(row.unit_price || 0),
    lineTotal: Number(row.line_total || 0),
    sortOrder: Number(row.sort_order || 0),
  };
}
