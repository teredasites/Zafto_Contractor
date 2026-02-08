'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';

// ==================== TYPES ====================

export type PostingStatus = 'draft' | 'active' | 'paused' | 'filled' | 'closed' | 'expired';
export type EmploymentType = 'full_time' | 'part_time' | 'contract' | 'seasonal' | 'intern' | 'apprentice';
export type PayType = 'hourly' | 'salary' | 'commission' | 'per_job';
export type ApplicantSource = 'direct' | 'indeed' | 'linkedin' | 'ziprecruiter' | 'referral' | 'website' | 'walk_in' | 'other';
export type ApplicantStage =
  | 'applied'
  | 'screening'
  | 'phone_screen'
  | 'interview'
  | 'skills_test'
  | 'reference_check'
  | 'background_check'
  | 'offer'
  | 'hired'
  | 'rejected'
  | 'withdrawn';
export type InterviewType = 'in_person' | 'phone' | 'video' | 'working_interview' | 'group';
export type InterviewStatus = 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled' | 'no_show' | 'rescheduled';

export interface JobPosting {
  id: string;
  companyId: string;
  createdByUserId: string;
  title: string;
  department: string;
  employmentType: EmploymentType;
  tradeCategory: string;
  description: string;
  requirements: string;
  responsibilities: string;
  qualifications: string;
  payType: PayType;
  payRangeMin: number;
  payRangeMax: number;
  benefits: string;
  location: string;
  isRemote: boolean;
  postToIndeed: boolean;
  postToLinkedin: boolean;
  postToZiprecruiter: boolean;
  postToWebsite: boolean;
  indeedJobId?: string;
  linkedinJobId?: string;
  ziprecruiterJobId?: string;
  status: PostingStatus;
  publishedAt?: Date;
  expiresAt?: Date;
  positionsAvailable: number;
  positionsFilled: number;
  totalViews: number;
  totalApplications: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface Applicant {
  id: string;
  companyId: string;
  jobPostingId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  source: ApplicantSource;
  resumePath?: string;
  coverLetterPath?: string;
  portfolioUrl?: string;
  yearsExperience: number;
  tradeSpecialties: string[];
  certifications: string[];
  licenses: string[];
  stage: ApplicantStage;
  stageChangedAt?: Date;
  rating: number;
  interviewerNotes: string;
  skillsAssessment: Record<string, unknown>;
  checkrCandidateId?: string;
  checkrReportId?: string;
  backgroundCheckStatus?: string;
  backgroundCheckCompletedAt?: Date;
  everifyCaseNumber?: string;
  everifyStatus?: string;
  offeredPayRate?: number;
  offeredPayType?: string;
  offeredStartDate?: Date;
  offerSentAt?: Date;
  offerResponse?: string;
  offerRespondedAt?: Date;
  hiredAt?: Date;
  rejectedAt?: Date;
  rejectionReason?: string;
  employeeRecordId?: string;
  createdAt: Date;
  updatedAt: Date;
  // Joined data
  jobTitle?: string;
}

export interface InterviewSchedule {
  id: string;
  companyId: string;
  applicantId: string;
  interviewType: InterviewType;
  scheduledAt: Date;
  durationMinutes: number;
  location: string;
  meetingUrl?: string;
  interviewerUserIds: string[];
  interviewGuide?: string;
  questions: Record<string, unknown>;
  status: InterviewStatus;
  feedback: Record<string, unknown>;
  overallRecommendation?: string;
  completedAt?: Date;
  reminderSent: boolean;
  createdAt: Date;
  updatedAt: Date;
  // Joined data
  applicantName?: string;
  applicantJobTitle?: string;
}

// ==================== MAPPERS ====================

function mapJobPosting(row: Record<string, unknown>): JobPosting {
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    createdByUserId: (row.created_by_user_id as string) || '',
    title: (row.title as string) || '',
    department: (row.department as string) || '',
    employmentType: ((row.employment_type as string) || 'full_time') as EmploymentType,
    tradeCategory: (row.trade_category as string) || '',
    description: (row.description as string) || '',
    requirements: (row.requirements as string) || '',
    responsibilities: (row.responsibilities as string) || '',
    qualifications: (row.qualifications as string) || '',
    payType: ((row.pay_type as string) || 'hourly') as PayType,
    payRangeMin: Number(row.pay_range_min) || 0,
    payRangeMax: Number(row.pay_range_max) || 0,
    benefits: (row.benefits as string) || '',
    location: (row.location as string) || '',
    isRemote: (row.is_remote as boolean) ?? false,
    postToIndeed: (row.post_to_indeed as boolean) ?? false,
    postToLinkedin: (row.post_to_linkedin as boolean) ?? false,
    postToZiprecruiter: (row.post_to_ziprecruiter as boolean) ?? false,
    postToWebsite: (row.post_to_website as boolean) ?? true,
    indeedJobId: (row.indeed_job_id as string) || undefined,
    linkedinJobId: (row.linkedin_job_id as string) || undefined,
    ziprecruiterJobId: (row.ziprecruiter_job_id as string) || undefined,
    status: ((row.status as string) || 'draft') as PostingStatus,
    publishedAt: row.published_at ? new Date(row.published_at as string) : undefined,
    expiresAt: row.expires_at ? new Date(row.expires_at as string) : undefined,
    positionsAvailable: Number(row.positions_available) || 1,
    positionsFilled: Number(row.positions_filled) || 0,
    totalViews: Number(row.total_views) || 0,
    totalApplications: Number(row.total_applications) || 0,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

function mapApplicant(row: Record<string, unknown>): Applicant {
  const jobData = row.job_postings as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    jobPostingId: (row.job_posting_id as string) || '',
    firstName: (row.first_name as string) || '',
    lastName: (row.last_name as string) || '',
    email: (row.email as string) || '',
    phone: (row.phone as string) || '',
    address: (row.address as string) || '',
    city: (row.city as string) || '',
    state: (row.state as string) || '',
    zipCode: (row.zip_code as string) || '',
    source: ((row.source as string) || 'direct') as ApplicantSource,
    resumePath: (row.resume_path as string) || undefined,
    coverLetterPath: (row.cover_letter_path as string) || undefined,
    portfolioUrl: (row.portfolio_url as string) || undefined,
    yearsExperience: Number(row.years_experience) || 0,
    tradeSpecialties: (row.trade_specialties as string[]) || [],
    certifications: (row.certifications as string[]) || [],
    licenses: (row.licenses as string[]) || [],
    stage: ((row.stage as string) || 'applied') as ApplicantStage,
    stageChangedAt: row.stage_changed_at ? new Date(row.stage_changed_at as string) : undefined,
    rating: Number(row.rating) || 0,
    interviewerNotes: (row.interviewer_notes as string) || '',
    skillsAssessment: (row.skills_assessment as Record<string, unknown>) || {},
    checkrCandidateId: (row.checkr_candidate_id as string) || undefined,
    checkrReportId: (row.checkr_report_id as string) || undefined,
    backgroundCheckStatus: (row.background_check_status as string) || undefined,
    backgroundCheckCompletedAt: row.background_check_completed_at ? new Date(row.background_check_completed_at as string) : undefined,
    everifyCaseNumber: (row.everify_case_number as string) || undefined,
    everifyStatus: (row.everify_status as string) || undefined,
    offeredPayRate: row.offered_pay_rate != null ? Number(row.offered_pay_rate) : undefined,
    offeredPayType: (row.offered_pay_type as string) || undefined,
    offeredStartDate: row.offered_start_date ? new Date(row.offered_start_date as string) : undefined,
    offerSentAt: row.offer_sent_at ? new Date(row.offer_sent_at as string) : undefined,
    offerResponse: (row.offer_response as string) || undefined,
    offerRespondedAt: row.offer_responded_at ? new Date(row.offer_responded_at as string) : undefined,
    hiredAt: row.hired_at ? new Date(row.hired_at as string) : undefined,
    rejectedAt: row.rejected_at ? new Date(row.rejected_at as string) : undefined,
    rejectionReason: (row.rejection_reason as string) || undefined,
    employeeRecordId: (row.employee_record_id as string) || undefined,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    jobTitle: jobData ? (jobData.title as string) || '' : undefined,
  };
}

function mapInterview(row: Record<string, unknown>): InterviewSchedule {
  const applicantData = row.applicants as Record<string, unknown> | null;
  const jobData = applicantData?.job_postings as Record<string, unknown> | null;
  return {
    id: row.id as string,
    companyId: (row.company_id as string) || '',
    applicantId: (row.applicant_id as string) || '',
    interviewType: ((row.interview_type as string) || 'in_person') as InterviewType,
    scheduledAt: new Date(row.scheduled_at as string),
    durationMinutes: Number(row.duration_minutes) || 60,
    location: (row.location as string) || '',
    meetingUrl: (row.meeting_url as string) || undefined,
    interviewerUserIds: (row.interviewer_user_ids as string[]) || [],
    interviewGuide: (row.interview_guide as string) || undefined,
    questions: (row.questions as Record<string, unknown>) || {},
    status: ((row.status as string) || 'scheduled') as InterviewStatus,
    feedback: (row.feedback as Record<string, unknown>) || {},
    overallRecommendation: (row.overall_recommendation as string) || undefined,
    completedAt: row.completed_at ? new Date(row.completed_at as string) : undefined,
    reminderSent: (row.reminder_sent as boolean) ?? false,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
    applicantName: applicantData ? `${(applicantData.first_name as string) || ''} ${(applicantData.last_name as string) || ''}`.trim() : undefined,
    applicantJobTitle: jobData ? (jobData.title as string) || '' : undefined,
  };
}

// ==================== HOOK ====================

export function useHiring() {
  const [postings, setPostings] = useState<JobPosting[]>([]);
  const [applicants, setApplicants] = useState<Applicant[]>([]);
  const [interviews, setInterviews] = useState<InterviewSchedule[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPostings = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('job_postings')
        .select('*')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setPostings((data || []).map(mapJobPosting));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load job postings';
      setError(msg);
    }
  }, []);

  const fetchApplicants = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('applicants')
        .select('*, job_postings(title)')
        .order('created_at', { ascending: false });

      if (err) throw err;
      setApplicants((data || []).map(mapApplicant));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load applicants';
      setError(msg);
    }
  }, []);

  const fetchInterviews = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('interview_schedules')
        .select('*, applicants(first_name, last_name, job_postings(title))')
        .order('scheduled_at', { ascending: true });

      if (err) throw err;
      setInterviews((data || []).map(mapInterview));
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to load interviews';
      setError(msg);
    }
  }, []);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    await Promise.all([fetchPostings(), fetchApplicants(), fetchInterviews()]);
    setLoading(false);
  }, [fetchPostings, fetchApplicants, fetchInterviews]);

  useEffect(() => {
    fetchAll();

    const supabase = getSupabase();
    const channel = supabase
      .channel('hiring-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'applicants' }, () => {
        fetchApplicants();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'job_postings' }, () => {
        fetchPostings();
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'interview_schedules' }, () => {
        fetchInterviews();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchAll, fetchApplicants, fetchPostings, fetchInterviews]);

  // ==================== MUTATIONS ====================

  const createPosting = async (input: {
    title: string;
    department?: string;
    employmentType?: EmploymentType;
    tradeCategory?: string;
    description?: string;
    requirements?: string;
    responsibilities?: string;
    qualifications?: string;
    payType?: PayType;
    payRangeMin?: number;
    payRangeMax?: number;
    benefits?: string;
    location?: string;
    isRemote?: boolean;
    positionsAvailable?: number;
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('job_postings')
      .insert({
        company_id: companyId,
        created_by_user_id: user.id,
        title: input.title,
        department: input.department || null,
        employment_type: input.employmentType || 'full_time',
        trade_category: input.tradeCategory || null,
        description: input.description || null,
        requirements: input.requirements || null,
        responsibilities: input.responsibilities || null,
        qualifications: input.qualifications || null,
        pay_type: input.payType || 'hourly',
        pay_range_min: input.payRangeMin || null,
        pay_range_max: input.payRangeMax || null,
        benefits: input.benefits || null,
        location: input.location || null,
        is_remote: input.isRemote || false,
        positions_available: input.positionsAvailable || 1,
        status: 'draft',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updatePosting = async (id: string, data: Partial<JobPosting>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.title !== undefined) updateData.title = data.title;
    if (data.department !== undefined) updateData.department = data.department;
    if (data.employmentType !== undefined) updateData.employment_type = data.employmentType;
    if (data.tradeCategory !== undefined) updateData.trade_category = data.tradeCategory;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.requirements !== undefined) updateData.requirements = data.requirements;
    if (data.responsibilities !== undefined) updateData.responsibilities = data.responsibilities;
    if (data.qualifications !== undefined) updateData.qualifications = data.qualifications;
    if (data.payType !== undefined) updateData.pay_type = data.payType;
    if (data.payRangeMin !== undefined) updateData.pay_range_min = data.payRangeMin;
    if (data.payRangeMax !== undefined) updateData.pay_range_max = data.payRangeMax;
    if (data.benefits !== undefined) updateData.benefits = data.benefits;
    if (data.location !== undefined) updateData.location = data.location;
    if (data.isRemote !== undefined) updateData.is_remote = data.isRemote;
    if (data.positionsAvailable !== undefined) updateData.positions_available = data.positionsAvailable;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.postToIndeed !== undefined) updateData.post_to_indeed = data.postToIndeed;
    if (data.postToLinkedin !== undefined) updateData.post_to_linkedin = data.postToLinkedin;
    if (data.postToZiprecruiter !== undefined) updateData.post_to_ziprecruiter = data.postToZiprecruiter;
    if (data.postToWebsite !== undefined) updateData.post_to_website = data.postToWebsite;

    const { error: err } = await supabase.from('job_postings').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const publishPosting = async (id: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('job_postings')
      .update({
        status: 'active',
        published_at: new Date().toISOString(),
      })
      .eq('id', id);
    if (err) throw err;
  };

  const addApplicant = async (input: {
    jobPostingId: string;
    firstName: string;
    lastName: string;
    email?: string;
    phone?: string;
    source?: ApplicantSource;
    yearsExperience?: number;
    tradeSpecialties?: string[];
    certifications?: string[];
    licenses?: string[];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('applicants')
      .insert({
        company_id: companyId,
        job_posting_id: input.jobPostingId,
        first_name: input.firstName,
        last_name: input.lastName,
        email: input.email || null,
        phone: input.phone || null,
        source: input.source || 'direct',
        years_experience: input.yearsExperience || null,
        trade_specialties: input.tradeSpecialties || [],
        certifications: input.certifications || [],
        licenses: input.licenses || [],
        stage: 'applied',
        stage_changed_at: new Date().toISOString(),
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateApplicantStage = async (id: string, stage: ApplicantStage) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {
      stage,
      stage_changed_at: new Date().toISOString(),
    };

    if (stage === 'hired') updateData.hired_at = new Date().toISOString();
    if (stage === 'rejected') updateData.rejected_at = new Date().toISOString();

    const { error: err } = await supabase.from('applicants').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const scheduleInterview = async (input: {
    applicantId: string;
    interviewType?: InterviewType;
    scheduledAt: string;
    durationMinutes?: number;
    location?: string;
    meetingUrl?: string;
    interviewerUserIds?: string[];
  }): Promise<string> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const companyId = user.app_metadata?.company_id;
    if (!companyId) throw new Error('No company associated');

    const { data: result, error: err } = await supabase
      .from('interview_schedules')
      .insert({
        company_id: companyId,
        applicant_id: input.applicantId,
        interview_type: input.interviewType || 'in_person',
        scheduled_at: input.scheduledAt,
        duration_minutes: input.durationMinutes || 60,
        location: input.location || null,
        meeting_url: input.meetingUrl || null,
        interviewer_user_ids: input.interviewerUserIds || [],
        status: 'scheduled',
      })
      .select('id')
      .single();

    if (err) throw err;
    return result.id;
  };

  const updateInterview = async (id: string, data: Partial<InterviewSchedule>) => {
    const supabase = getSupabase();
    const updateData: Record<string, unknown> = {};

    if (data.interviewType !== undefined) updateData.interview_type = data.interviewType;
    if (data.scheduledAt !== undefined) updateData.scheduled_at = data.scheduledAt instanceof Date ? data.scheduledAt.toISOString() : data.scheduledAt;
    if (data.durationMinutes !== undefined) updateData.duration_minutes = data.durationMinutes;
    if (data.location !== undefined) updateData.location = data.location;
    if (data.meetingUrl !== undefined) updateData.meeting_url = data.meetingUrl;
    if (data.status !== undefined) updateData.status = data.status;
    if (data.overallRecommendation !== undefined) updateData.overall_recommendation = data.overallRecommendation;
    if (data.status === 'completed') updateData.completed_at = new Date().toISOString();

    const { error: err } = await supabase.from('interview_schedules').update(updateData).eq('id', id);
    if (err) throw err;
  };

  const sendOffer = async (applicantId: string, input: {
    payRate: number;
    payType: string;
    startDate: string;
  }) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('applicants')
      .update({
        stage: 'offer',
        stage_changed_at: new Date().toISOString(),
        offered_pay_rate: input.payRate,
        offered_pay_type: input.payType,
        offered_start_date: input.startDate,
        offer_sent_at: new Date().toISOString(),
      })
      .eq('id', applicantId);
    if (err) throw err;
  };

  const rejectApplicant = async (applicantId: string, reason?: string) => {
    const supabase = getSupabase();
    const { error: err } = await supabase
      .from('applicants')
      .update({
        stage: 'rejected',
        stage_changed_at: new Date().toISOString(),
        rejected_at: new Date().toISOString(),
        rejection_reason: reason || null,
      })
      .eq('id', applicantId);
    if (err) throw err;
  };

  // ==================== COMPUTED ====================

  const activePostings = useMemo(() => postings.filter((p) => p.status === 'active'), [postings]);

  const totalApplicants = useMemo(() => applicants.length, [applicants]);

  const inPipeline = useMemo(
    () => applicants.filter((a) => !['hired', 'rejected', 'withdrawn'].includes(a.stage)).length,
    [applicants]
  );

  const interviewsThisWeek = useMemo(() => {
    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7);

    return interviews.filter(
      (i) => i.scheduledAt >= startOfWeek && i.scheduledAt < endOfWeek && i.status !== 'cancelled'
    ).length;
  }, [interviews]);

  const hiredCount = useMemo(() => {
    const startOfYear = new Date(new Date().getFullYear(), 0, 1);
    return applicants.filter((a) => a.stage === 'hired' && a.hiredAt && new Date(a.hiredAt) >= startOfYear).length;
  }, [applicants]);

  return {
    postings,
    applicants,
    interviews,
    loading,
    error,
    // Mutations
    createPosting,
    updatePosting,
    publishPosting,
    addApplicant,
    updateApplicantStage,
    scheduleInterview,
    updateInterview,
    sendOffer,
    rejectApplicant,
    // Computed
    activePostings,
    totalApplicants,
    inPipeline,
    interviewsThisWeek,
    hiredCount,
    // Refetch
    refetch: fetchAll,
  };
}
