-- F5g: HR Suite tables
-- Employee records, onboarding, training tracking, performance reviews

-- Employee Records (extends auth.users via linked table)
CREATE TABLE employee_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  -- Personal
  date_of_birth DATE,
  ssn_last_four TEXT,  -- Only last 4 stored, full SSN encrypted in Gusto
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT,
  -- Employment
  hire_date DATE NOT NULL,
  termination_date DATE,
  employment_type TEXT DEFAULT 'full_time' CHECK (employment_type IN ('full_time','part_time','contract','seasonal','intern')),
  department TEXT,
  job_title TEXT,
  pay_type TEXT DEFAULT 'hourly' CHECK (pay_type IN ('hourly','salary')),
  pay_rate NUMERIC(10,2),
  -- Benefits
  health_plan TEXT,
  dental_plan TEXT,
  vision_plan TEXT,
  retirement_plan TEXT,
  pto_balance_hours NUMERIC(8,2) DEFAULT 0,
  sick_leave_hours NUMERIC(8,2) DEFAULT 0,
  -- Tax
  federal_filing_status TEXT,
  state_filing_status TEXT,
  allowances INTEGER DEFAULT 0,
  additional_withholding NUMERIC(10,2) DEFAULT 0,
  -- Documents
  w4_path TEXT,
  i9_path TEXT,
  direct_deposit_path TEXT,
  -- Integration
  gusto_employee_id TEXT,
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active','on_leave','terminated','suspended')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Onboarding Checklists
CREATE TABLE onboarding_checklists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  employee_user_id UUID NOT NULL REFERENCES auth.users(id),
  template_name TEXT NOT NULL DEFAULT 'Standard Onboarding',
  items JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{title, description, required, completed, completed_at, completed_by}]
  due_date DATE,
  status TEXT DEFAULT 'in_progress' CHECK (status IN ('not_started','in_progress','completed','cancelled')),
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Training Records
CREATE TABLE training_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  training_type TEXT NOT NULL CHECK (training_type IN ('safety','osha','trade_specific','company','compliance','equipment','other')),
  title TEXT NOT NULL,
  description TEXT,
  provider TEXT,
  -- Dates
  training_date DATE NOT NULL,
  expiration_date DATE,
  -- Results
  passed BOOLEAN DEFAULT true,
  score NUMERIC(5,2),
  certificate_number TEXT,
  certificate_path TEXT,
  -- OSHA specific
  osha_standard TEXT,
  training_hours NUMERIC(6,2),
  -- Status
  status TEXT DEFAULT 'completed' CHECK (status IN ('scheduled','in_progress','completed','failed','expired')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Performance Reviews
CREATE TABLE performance_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  employee_user_id UUID NOT NULL REFERENCES auth.users(id),
  reviewer_user_id UUID NOT NULL REFERENCES auth.users(id),
  review_period_start DATE NOT NULL,
  review_period_end DATE NOT NULL,
  review_type TEXT DEFAULT 'annual' CHECK (review_type IN ('annual','semi_annual','quarterly','probation','promotion','pip')),
  -- Ratings (1-5)
  quality_rating INTEGER CHECK (quality_rating BETWEEN 1 AND 5),
  productivity_rating INTEGER CHECK (productivity_rating BETWEEN 1 AND 5),
  reliability_rating INTEGER CHECK (reliability_rating BETWEEN 1 AND 5),
  teamwork_rating INTEGER CHECK (teamwork_rating BETWEEN 1 AND 5),
  safety_rating INTEGER CHECK (safety_rating BETWEEN 1 AND 5),
  overall_rating INTEGER CHECK (overall_rating BETWEEN 1 AND 5),
  -- Text
  strengths TEXT,
  areas_for_improvement TEXT,
  goals TEXT,
  employee_comments TEXT,
  manager_summary TEXT,
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','submitted','acknowledged','completed')),
  submitted_at TIMESTAMPTZ,
  acknowledged_at TIMESTAMPTZ,
  employee_signature_path TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE employee_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE training_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY employee_records_company ON employee_records FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY onboarding_company ON onboarding_checklists FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY training_company ON training_records FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY reviews_company ON performance_reviews FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_employee_records_company ON employee_records(company_id);
CREATE INDEX idx_employee_records_user ON employee_records(user_id);
CREATE INDEX idx_onboarding_employee ON onboarding_checklists(employee_user_id);
CREATE INDEX idx_training_user ON training_records(user_id);
CREATE INDEX idx_training_expiration ON training_records(expiration_date) WHERE expiration_date IS NOT NULL AND status != 'expired';
CREATE INDEX idx_reviews_employee ON performance_reviews(employee_user_id);
CREATE INDEX idx_reviews_reviewer ON performance_reviews(reviewer_user_id);

-- Triggers
CREATE TRIGGER employee_records_updated BEFORE UPDATE ON employee_records FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER onboarding_updated BEFORE UPDATE ON onboarding_checklists FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER training_updated BEFORE UPDATE ON training_records FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER reviews_updated BEFORE UPDATE ON performance_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at();
