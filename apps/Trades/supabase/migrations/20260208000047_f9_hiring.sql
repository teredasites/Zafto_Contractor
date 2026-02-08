-- F9: Hiring System tables
-- Job postings, applicant tracking, background checks, interview scheduling

-- Job Postings
CREATE TABLE job_postings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- Position
  title TEXT NOT NULL,
  department TEXT,
  employment_type TEXT NOT NULL CHECK (employment_type IN ('full_time','part_time','contract','seasonal','intern','apprentice')),
  trade_category TEXT,
  -- Details
  description TEXT NOT NULL,
  requirements TEXT,
  responsibilities TEXT,
  qualifications TEXT,
  -- Compensation
  pay_type TEXT DEFAULT 'hourly' CHECK (pay_type IN ('hourly','salary','commission','per_job')),
  pay_range_min NUMERIC(10,2),
  pay_range_max NUMERIC(10,2),
  benefits TEXT,
  -- Location
  location TEXT,
  is_remote BOOLEAN DEFAULT false,
  -- Distribution
  post_to_indeed BOOLEAN DEFAULT true,
  post_to_linkedin BOOLEAN DEFAULT false,
  post_to_ziprecruiter BOOLEAN DEFAULT false,
  post_to_website BOOLEAN DEFAULT true,
  indeed_job_id TEXT,
  linkedin_job_id TEXT,
  ziprecruiter_job_id TEXT,
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','active','paused','filled','closed','expired')),
  published_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  positions_available INTEGER DEFAULT 1,
  positions_filled INTEGER DEFAULT 0,
  -- Metrics
  total_views INTEGER DEFAULT 0,
  total_applications INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Applicants
CREATE TABLE applicants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_posting_id UUID NOT NULL REFERENCES job_postings(id),
  -- Contact
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  -- Application
  source TEXT DEFAULT 'direct' CHECK (source IN ('direct','indeed','linkedin','ziprecruiter','referral','website','walk_in','other')),
  resume_path TEXT,
  cover_letter_path TEXT,
  portfolio_url TEXT,
  -- Experience
  years_experience INTEGER,
  trade_specialties TEXT[] DEFAULT '{}',
  certifications TEXT[] DEFAULT '{}',
  licenses TEXT[] DEFAULT '{}',
  -- Pipeline
  stage TEXT DEFAULT 'applied' CHECK (stage IN ('applied','screening','phone_screen','interview','skills_test','reference_check','background_check','offer','hired','rejected','withdrawn')),
  stage_changed_at TIMESTAMPTZ DEFAULT now(),
  -- Evaluation
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  interviewer_notes TEXT,
  skills_assessment JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {skill: score}
  -- Background check
  checkr_candidate_id TEXT,
  checkr_report_id TEXT,
  background_check_status TEXT CHECK (background_check_status IN ('pending','processing','clear','consider','suspended')),
  background_check_completed_at TIMESTAMPTZ,
  -- E-Verify
  everify_case_number TEXT,
  everify_status TEXT CHECK (everify_status IN ('pending','authorized','tentative_nonconfirmation','final_nonconfirmation')),
  -- Offer
  offered_pay_rate NUMERIC(10,2),
  offered_pay_type TEXT CHECK (offered_pay_type IN ('hourly','salary')),
  offered_start_date DATE,
  offer_sent_at TIMESTAMPTZ,
  offer_response TEXT CHECK (offer_response IN ('pending','accepted','declined','negotiating')),
  offer_responded_at TIMESTAMPTZ,
  -- Result
  hired_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  rejection_reason TEXT,
  -- Link to employee record
  employee_record_id UUID REFERENCES employee_records(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Interview Schedule
CREATE TABLE interview_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  applicant_id UUID NOT NULL REFERENCES applicants(id),
  -- Schedule
  interview_type TEXT DEFAULT 'in_person' CHECK (interview_type IN ('in_person','phone','video','working_interview','group')),
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER DEFAULT 60,
  location TEXT,
  meeting_url TEXT,  -- for video interviews (LiveKit or external)
  -- Interviewers
  interviewer_user_ids UUID[] DEFAULT '{}',
  -- Preparation
  interview_guide TEXT,
  questions JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{question, category, expected_answer}]
  -- Results
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','confirmed','in_progress','completed','cancelled','no_show','rescheduled')),
  feedback JSONB NOT NULL DEFAULT '{}'::jsonb,  -- {interviewer_id: {rating, notes, recommend}}
  overall_recommendation TEXT CHECK (overall_recommendation IN ('strong_yes','yes','neutral','no','strong_no')),
  completed_at TIMESTAMPTZ,
  -- Reminders
  reminder_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE job_postings ENABLE ROW LEVEL SECURITY;
ALTER TABLE applicants ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY postings_company ON job_postings FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY applicants_company ON applicants FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY interviews_company ON interview_schedules FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_postings_company ON job_postings(company_id);
CREATE INDEX idx_postings_status ON job_postings(status) WHERE status = 'active';
CREATE INDEX idx_applicants_company ON applicants(company_id);
CREATE INDEX idx_applicants_posting ON applicants(job_posting_id);
CREATE INDEX idx_applicants_stage ON applicants(stage);
CREATE INDEX idx_applicants_email ON applicants(email);
CREATE INDEX idx_interviews_applicant ON interview_schedules(applicant_id);
CREATE INDEX idx_interviews_scheduled ON interview_schedules(scheduled_at) WHERE status IN ('scheduled','confirmed');

-- Triggers
CREATE TRIGGER postings_updated BEFORE UPDATE ON job_postings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER applicants_updated BEFORE UPDATE ON applicants FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER interviews_updated BEFORE UPDATE ON interview_schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at();
