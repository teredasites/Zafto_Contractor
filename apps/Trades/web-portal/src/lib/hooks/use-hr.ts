'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export type EmploymentType = 'full_time' | 'part_time' | 'contract' | 'seasonal' | 'intern';
export type PayType = 'hourly' | 'salary';
export type EmployeeStatus = 'active' | 'on_leave' | 'terminated' | 'suspended';

export type OnboardingStatus = 'not_started' | 'in_progress' | 'completed' | 'cancelled';

export type TrainingType = 'safety' | 'osha' | 'trade_specific' | 'company' | 'compliance' | 'equipment' | 'other';
export type TrainingStatus = 'scheduled' | 'in_progress' | 'completed' | 'failed' | 'expired';

export type ReviewType = 'annual' | 'semi_annual' | 'quarterly' | 'probation' | 'promotion' | 'pip';
export type ReviewStatus = 'draft' | 'submitted' | 'acknowledged' | 'completed';

export interface OnboardingItem {
  title: string;
  description: string;
  required: boolean;
  completed: boolean;
  completedAt: string | null;
  completedBy: string | null;
}

export interface EmployeeRecord {
  id: string;
  companyId: string;
  userId: string;
  dateOfBirth: string | null;
  ssnLastFour: string | null;
  emergencyContactName: string | null;
  emergencyContactPhone: string | null;
  emergencyContactRelation: string | null;
  hireDate: string | null;
  terminationDate: string | null;
  employmentType: EmploymentType;
  department: string | null;
  jobTitle: string | null;
  payType: PayType;
  payRate: number;
  healthPlan: string | null;
  dentalPlan: string | null;
  visionPlan: string | null;
  retirementPlan: string | null;
  ptoBalanceHours: number;
  sickLeaveHours: number;
  federalFilingStatus: string | null;
  stateFilingStatus: string | null;
  allowances: number;
  additionalWithholding: number;
  w4Path: string | null;
  i9Path: string | null;
  directDepositPath: string | null;
  gustoEmployeeId: string | null;
  status: EmployeeStatus;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined from users table
  userName?: string;
  userEmail?: string;
}

export interface OnboardingChecklist {
  id: string;
  companyId: string;
  employeeUserId: string;
  templateName: string;
  items: OnboardingItem[];
  dueDate: string | null;
  status: OnboardingStatus;
  completedAt: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  employeeName?: string;
}

export interface TrainingRecord {
  id: string;
  companyId: string;
  userId: string;
  trainingType: TrainingType;
  title: string;
  description: string | null;
  provider: string | null;
  trainingDate: string | null;
  expirationDate: string | null;
  passed: boolean | null;
  score: number | null;
  certificateNumber: string | null;
  certificatePath: string | null;
  oshaStandard: string | null;
  trainingHours: number;
  status: TrainingStatus;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  userName?: string;
}

export interface PerformanceReview {
  id: string;
  companyId: string;
  employeeUserId: string;
  reviewerUserId: string;
  reviewPeriodStart: string | null;
  reviewPeriodEnd: string | null;
  reviewType: ReviewType;
  qualityRating: number | null;
  productivityRating: number | null;
  reliabilityRating: number | null;
  teamworkRating: number | null;
  safetyRating: number | null;
  overallRating: number | null;
  strengths: string | null;
  areasForImprovement: string | null;
  goals: string | null;
  employeeComments: string | null;
  managerSummary: string | null;
  status: ReviewStatus;
  submittedAt: string | null;
  acknowledgedAt: string | null;
  employeeSignaturePath: string | null;
  createdAt: Date;
  updatedAt: Date;
  // Joined
  employeeName?: string;
  reviewerName?: string;
}

// ==================== MAPPERS ====================

function mapEmployee(row: Record<string, unknown>): EmployeeRecord {
  const userData = row.users as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    userId: (row.user_id as string) || '',
    dateOfBirth: (row.date_of_birth as string) || null,
    ssnLastFour: (row.ssn_last_four as string) || null,
    emergencyContactName: (row.emergency_contact_name as string) || null,
    emergencyContactPhone: (row.emergency_contact_phone as string) || null,
    emergencyContactRelation: (row.emergency_contact_relation as string) || null,
    hireDate: (row.hire_date as string) || null,
    terminationDate: (row.termination_date as string) || null,
    employmentType: ((row.employment_type as string) || 'full_time') as EmploymentType,
    department: (row.department as string) || null,
    jobTitle: (row.job_title as string) || null,
    payType: ((row.pay_type as string) || 'hourly') as PayType,
    payRate: Number(row.pay_rate) || 0,
    healthPlan: (row.health_plan as string) || null,
    dentalPlan: (row.dental_plan as string) || null,
    visionPlan: (row.vision_plan as string) || null,
    retirementPlan: (row.retirement_plan as string) || null,
    ptoBalanceHours: Number(row.pto_balance_hours) || 0,
    sickLeaveHours: Number(row.sick_leave_hours) || 0,
    federalFilingStatus: (row.federal_filing_status as string) || null,
    stateFilingStatus: (row.state_filing_status as string) || null,
    allowances: Number(row.allowances) || 0,
    additionalWithholding: Number(row.additional_withholding) || 0,
    w4Path: (row.w4_path as string) || null,
    i9Path: (row.i9_path as string) || null,
    directDepositPath: (row.direct_deposit_path as string) || null,
    gustoEmployeeId: (row.gusto_employee_id as string) || null,
    status: ((row.status as string) || 'active') as EmployeeStatus,
    notes: (row.notes as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    userName: userData ? (userData.full_name as string) || '' : undefined,
    userEmail: userData ? (userData.email as string) || '' : undefined,
  };
}

function mapOnboarding(row: Record<string, unknown>): OnboardingChecklist {
  const userData = row.users as Record<string, unknown> | null;
  const rawItems = row.items;
  const items: OnboardingItem[] = Array.isArray(rawItems)
    ? rawItems.map((item: Record<string, unknown>) => ({
        title: (item.title as string) || '',
        description: (item.description as string) || '',
        required: (item.required as boolean) ?? false,
        completed: (item.completed as boolean) ?? false,
        completedAt: (item.completed_at as string) || (item.completedAt as string) || null,
        completedBy: (item.completed_by as string) || (item.completedBy as string) || null,
      }))
    : [];

  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    employeeUserId: (row.employee_user_id as string) || '',
    templateName: (row.template_name as string) || '',
    items,
    dueDate: (row.due_date as string) || null,
    status: ((row.status as string) || 'not_started') as OnboardingStatus,
    completedAt: (row.completed_at as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    employeeName: userData ? (userData.full_name as string) || '' : undefined,
  };
}

function mapTraining(row: Record<string, unknown>): TrainingRecord {
  const userData = row.users as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    userId: (row.user_id as string) || '',
    trainingType: ((row.training_type as string) || 'other') as TrainingType,
    title: (row.title as string) || '',
    description: (row.description as string) || null,
    provider: (row.provider as string) || null,
    trainingDate: (row.training_date as string) || null,
    expirationDate: (row.expiration_date as string) || null,
    passed: row.passed != null ? (row.passed as boolean) : null,
    score: row.score != null ? Number(row.score) : null,
    certificateNumber: (row.certificate_number as string) || null,
    certificatePath: (row.certificate_path as string) || null,
    oshaStandard: (row.osha_standard as string) || null,
    trainingHours: Number(row.training_hours) || 0,
    status: ((row.status as string) || 'scheduled') as TrainingStatus,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    userName: userData ? (userData.full_name as string) || '' : undefined,
  };
}

function mapReview(row: Record<string, unknown>): PerformanceReview {
  const employeeData = row.employee as Record<string, unknown> | null;
  const reviewerData = row.reviewer as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    employeeUserId: (row.employee_user_id as string) || '',
    reviewerUserId: (row.reviewer_user_id as string) || '',
    reviewPeriodStart: (row.review_period_start as string) || null,
    reviewPeriodEnd: (row.review_period_end as string) || null,
    reviewType: ((row.review_type as string) || 'annual') as ReviewType,
    qualityRating: row.quality_rating != null ? Number(row.quality_rating) : null,
    productivityRating: row.productivity_rating != null ? Number(row.productivity_rating) : null,
    reliabilityRating: row.reliability_rating != null ? Number(row.reliability_rating) : null,
    teamworkRating: row.teamwork_rating != null ? Number(row.teamwork_rating) : null,
    safetyRating: row.safety_rating != null ? Number(row.safety_rating) : null,
    overallRating: row.overall_rating != null ? Number(row.overall_rating) : null,
    strengths: (row.strengths as string) || null,
    areasForImprovement: (row.areas_for_improvement as string) || null,
    goals: (row.goals as string) || null,
    employeeComments: (row.employee_comments as string) || null,
    managerSummary: (row.manager_summary as string) || null,
    status: ((row.status as string) || 'draft') as ReviewStatus,
    submittedAt: (row.submitted_at as string) || null,
    acknowledgedAt: (row.acknowledged_at as string) || null,
    employeeSignaturePath: (row.employee_signature_path as string) || null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    employeeName: employeeData ? (employeeData.full_name as string) || '' : undefined,
    reviewerName: reviewerData ? (reviewerData.full_name as string) || '' : undefined,
  };
}

// ==================== HOOK ====================

export function useHR() {
  const [employees, setEmployees] = useState<EmployeeRecord[]>([]);
  const [onboardingChecklists, setOnboardingChecklists] = useState<OnboardingChecklist[]>([]);
  const [trainingRecords, setTrainingRecords] = useState<TrainingRecord[]>([]);
  const [performanceReviews, setPerformanceReviews] = useState<PerformanceReview[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();

      const [empRes, onbRes, trainRes, revRes] = await Promise.all([
        supabase
          .from('employee_records')
          .select('*, users:user_id(full_name, email)')
          .order('created_at', { ascending: false }),
        supabase
          .from('onboarding_checklists')
          .select('*, users:employee_user_id(full_name, email)')
          .order('created_at', { ascending: false }),
        supabase
          .from('training_records')
          .select('*, users:user_id(full_name, email)')
          .order('created_at', { ascending: false }),
        supabase
          .from('performance_reviews')
          .select('*, employee:employee_user_id(full_name, email), reviewer:reviewer_user_id(full_name, email)')
          .order('created_at', { ascending: false }),
      ]);

      if (empRes.error) throw empRes.error;
      if (onbRes.error) throw onbRes.error;
      if (trainRes.error) throw trainRes.error;
      if (revRes.error) throw revRes.error;

      setEmployees((empRes.data || []).map(mapEmployee));
      setOnboardingChecklists((onbRes.data || []).map(mapOnboarding));
      setTrainingRecords((trainRes.data || []).map(mapTraining));
      setPerformanceReviews((revRes.data || []).map(mapReview));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load HR data';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('hr-employee-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'employee_records' }, () => {
        fetchAll();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll]);

  // ==================== MUTATIONS ====================

  const createEmployee = async (data: Partial<EmployeeRecord>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('employee_records')
      .insert({
        company_id: companyId,
        user_id: data.userId || null,
        date_of_birth: data.dateOfBirth || null,
        ssn_last_four: data.ssnLastFour || null,
        emergency_contact_name: data.emergencyContactName || null,
        emergency_contact_phone: data.emergencyContactPhone || null,
        emergency_contact_relation: data.emergencyContactRelation || null,
        hire_date: data.hireDate || new Date().toISOString().split('T')[0],
        employment_type: data.employmentType || 'full_time',
        department: data.department || null,
        job_title: data.jobTitle || null,
        pay_type: data.payType || 'hourly',
        pay_rate: data.payRate || 0,
        health_plan: data.healthPlan || null,
        dental_plan: data.dentalPlan || null,
        vision_plan: data.visionPlan || null,
        retirement_plan: data.retirementPlan || null,
        pto_balance_hours: data.ptoBalanceHours || 0,
        sick_leave_hours: data.sickLeaveHours || 0,
        status: data.status || 'active',
        notes: data.notes || null,
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateEmployee = async (id: string, data: Partial<EmployeeRecord>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.dateOfBirth !== undefined) updateData.date_of_birth = data.dateOfBirth;
    if (data.ssnLastFour !== undefined) updateData.ssn_last_four = data.ssnLastFour;
    if (data.emergencyContactName !== undefined) updateData.emergency_contact_name = data.emergencyContactName;
    if (data.emergencyContactPhone !== undefined) updateData.emergency_contact_phone = data.emergencyContactPhone;
    if (data.emergencyContactRelation !== undefined) updateData.emergency_contact_relation = data.emergencyContactRelation;
    if (data.hireDate !== undefined) updateData.hire_date = data.hireDate;
    if (data.terminationDate !== undefined) updateData.termination_date = data.terminationDate;
    if (data.employmentType !== undefined) updateData.employment_type = data.employmentType;
    if (data.department !== undefined) updateData.department = data.department;
    if (data.jobTitle !== undefined) updateData.job_title = data.jobTitle;
    if (data.payType !== undefined) updateData.pay_type = data.payType;
    if (data.payRate !== undefined) updateData.pay_rate = data.payRate;
    if (data.healthPlan !== undefined) updateData.health_plan = data.healthPlan;
    if (data.dentalPlan !== undefined) updateData.dental_plan = data.dentalPlan;
    if (data.visionPlan !== undefined) updateData.vision_plan = data.visionPlan;
    if (data.retirementPlan !== undefined) updateData.retirement_plan = data.retirementPlan;
    if (data.ptoBalanceHours !== undefined) updateData.pto_balance_hours = data.ptoBalanceHours;
    if (data.sickLeaveHours !== undefined) updateData.sick_leave_hours = data.sickLeaveHours;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.notes !== undefined) updateData.notes = data.notes;

    const { error: err } = await supabase.from('employee_records').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const createOnboarding = async (data: {
    employeeUserId: string;
    templateName: string;
    items: OnboardingItem[];
    dueDate?: string;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('onboarding_checklists')
      .insert({
        company_id: companyId,
        employee_user_id: data.employeeUserId,
        template_name: data.templateName,
        items: data.items.map((i) => ({
          title: i.title,
          description: i.description,
          required: i.required,
          completed: false,
          completed_at: null,
          completed_by: null,
        })),
        due_date: data.dueDate || null,
        status: 'not_started',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateOnboardingItem = async (checklistId: string, itemIndex: number, completed: boolean) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Fetch current checklist
    const { data: checklist, error: fetchErr } = await supabase
      .from('onboarding_checklists')
      .select('items, status')
      .eq('id', checklistId)
      .single();

    if (fetchErr) throw fetchErr;

    const items = [...(checklist.items as OnboardingItem[])];
    items[itemIndex] = {
      ...items[itemIndex],
      completed,
      completedAt: completed ? new Date().toISOString() : null,
      completedBy: completed ? user.id : null,
    };

    const allCompleted = items.every((i) => i.completed || !i.required);
    const anyCompleted = items.some((i) => i.completed);
    const newStatus: OnboardingStatus = allCompleted ? 'completed' : anyCompleted ? 'in_progress' : 'not_started';

    const updateData: Record<string, unknown> = { items, status: newStatus };
    if (allCompleted) updateData.completed_at = new Date().toISOString();

    const { error: err } = await supabase
      .from('onboarding_checklists')
      .update(updateData)
      .eq('id', checklistId);

    if (err) throw err;
    await fetchAll();
  };

  const addTraining = async (data: Partial<TrainingRecord>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('training_records')
      .insert({
        company_id: companyId,
        user_id: data.userId || user.id,
        training_type: data.trainingType || 'other',
        title: data.title || '',
        description: data.description || null,
        provider: data.provider || null,
        training_date: data.trainingDate || null,
        expiration_date: data.expirationDate || null,
        passed: data.passed ?? null,
        score: data.score ?? null,
        certificate_number: data.certificateNumber || null,
        osha_standard: data.oshaStandard || null,
        training_hours: data.trainingHours || 0,
        status: data.status || 'scheduled',
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const updateTraining = async (id: string, data: Partial<TrainingRecord>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.trainingType !== undefined) updateData.training_type = data.trainingType;
    if (data.title !== undefined) updateData.title = data.title;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.provider !== undefined) updateData.provider = data.provider;
    if (data.trainingDate !== undefined) updateData.training_date = data.trainingDate;
    if (data.expirationDate !== undefined) updateData.expiration_date = data.expirationDate;
    if (data.passed !== undefined) updateData.passed = data.passed;
    if (data.score !== undefined) updateData.score = data.score;
    if (data.certificateNumber !== undefined) updateData.certificate_number = data.certificateNumber;
    if (data.oshaStandard !== undefined) updateData.osha_standard = data.oshaStandard;
    if (data.trainingHours !== undefined) updateData.training_hours = data.trainingHours;
    if (data.status !== undefined) updateData.status = data.status;

    const { error: err } = await supabase.from('training_records').update(updateData).eq('id', id);
    if (err) throw err;
    await fetchAll();
  };

  const createReview = async (data: Partial<PerformanceReview>): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('performance_reviews')
      .insert({
        company_id: companyId,
        employee_user_id: data.employeeUserId || '',
        reviewer_user_id: data.reviewerUserId || user.id,
        review_period_start: data.reviewPeriodStart || null,
        review_period_end: data.reviewPeriodEnd || null,
        review_type: data.reviewType || 'annual',
        quality_rating: data.qualityRating ?? null,
        productivity_rating: data.productivityRating ?? null,
        reliability_rating: data.reliabilityRating ?? null,
        teamwork_rating: data.teamworkRating ?? null,
        safety_rating: data.safetyRating ?? null,
        overall_rating: data.overallRating ?? null,
        strengths: data.strengths || null,
        areas_for_improvement: data.areasForImprovement || null,
        goals: data.goals || null,
        manager_summary: data.managerSummary || null,
        status: 'draft',
      })
      .select('id')
      .single();

    if (err) throw err;
    await fetchAll();
    return result.id;
  };

  const submitReview = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('performance_reviews')
      .update({ status: 'submitted', submitted_at: new Date().toISOString() })
      .eq('id', id);

    if (err) throw err;
    await fetchAll();
  };

  // ==================== COMPUTED ====================

  const activeEmployees = useMemo(
    () => employees.filter((e) => e.status === 'active'),
    [employees]
  );

  const onLeave = useMemo(
    () => employees.filter((e) => e.status === 'on_leave'),
    [employees]
  );

  const expiringTraining = useMemo(() => {
    const now = new Date();
    const sixtyDaysOut = new Date(now.getTime() + 60 * 24 * 60 * 60 * 1000);
    return trainingRecords.filter((t) => {
      if (!t.expirationDate) return false;
      const expDate = new Date(t.expirationDate);
      return expDate >= now && expDate <= sixtyDaysOut;
    });
  }, [trainingRecords]);

  const pendingReviews = useMemo(
    () => performanceReviews.filter((r) => r.status === 'draft' || r.status === 'submitted'),
    [performanceReviews]
  );

  const avgOverallRating = useMemo(() => {
    const rated = performanceReviews.filter((r) => r.overallRating != null);
    if (rated.length === 0) return 0;
    return rated.reduce((sum, r) => sum + (r.overallRating || 0), 0) / rated.length;
  }, [performanceReviews]);

  return {
    employees,
    onboardingChecklists,
    trainingRecords,
    performanceReviews,
    loading,
    error,
    // Mutations
    createEmployee,
    updateEmployee,
    createOnboarding,
    updateOnboardingItem,
    addTraining,
    updateTraining,
    createReview,
    submitReview,
    // Computed
    activeEmployees,
    onLeave,
    expiringTraining,
    pendingReviews,
    avgOverallRating,
    // Refetch
    refetch: fetchAll,
  };
}
