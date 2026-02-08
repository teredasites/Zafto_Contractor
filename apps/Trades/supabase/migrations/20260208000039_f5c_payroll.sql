-- F5c: Payroll tables
-- Time clock → payroll calculations, pay runs, pay stubs

-- Pay Periods — biweekly/weekly/monthly pay periods
CREATE TABLE pay_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  pay_date DATE NOT NULL,
  frequency TEXT NOT NULL DEFAULT 'biweekly' CHECK (frequency IN ('weekly','biweekly','semimonthly','monthly')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','calculating','review','approved','paid','voided')),
  total_gross NUMERIC(12,2) DEFAULT 0,
  total_deductions NUMERIC(12,2) DEFAULT 0,
  total_net NUMERIC(12,2) DEFAULT 0,
  total_employer_taxes NUMERIC(12,2) DEFAULT 0,
  employee_count INTEGER DEFAULT 0,
  approved_by_user_id UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  gusto_payroll_id TEXT,  -- Gusto embedded integration reference
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Pay Stubs — individual employee pay for a period
CREATE TABLE pay_stubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  pay_period_id UUID NOT NULL REFERENCES pay_periods(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  employee_name TEXT NOT NULL,
  -- Hours
  regular_hours NUMERIC(6,2) DEFAULT 0,
  overtime_hours NUMERIC(6,2) DEFAULT 0,
  pto_hours NUMERIC(6,2) DEFAULT 0,
  holiday_hours NUMERIC(6,2) DEFAULT 0,
  -- Pay
  hourly_rate NUMERIC(8,2),
  salary_amount NUMERIC(12,2),
  gross_pay NUMERIC(12,2) NOT NULL DEFAULT 0,
  -- Deductions
  federal_tax NUMERIC(10,2) DEFAULT 0,
  state_tax NUMERIC(10,2) DEFAULT 0,
  local_tax NUMERIC(10,2) DEFAULT 0,
  social_security NUMERIC(10,2) DEFAULT 0,
  medicare NUMERIC(10,2) DEFAULT 0,
  health_insurance NUMERIC(10,2) DEFAULT 0,
  dental_insurance NUMERIC(10,2) DEFAULT 0,
  vision_insurance NUMERIC(10,2) DEFAULT 0,
  retirement_401k NUMERIC(10,2) DEFAULT 0,
  other_deductions NUMERIC(10,2) DEFAULT 0,
  total_deductions NUMERIC(12,2) DEFAULT 0,
  -- Net
  net_pay NUMERIC(12,2) NOT NULL DEFAULT 0,
  -- Additional
  reimbursements NUMERIC(10,2) DEFAULT 0,
  bonuses NUMERIC(10,2) DEFAULT 0,
  commissions NUMERIC(10,2) DEFAULT 0,
  -- YTD totals (computed per period)
  ytd_gross NUMERIC(12,2) DEFAULT 0,
  ytd_federal_tax NUMERIC(12,2) DEFAULT 0,
  ytd_state_tax NUMERIC(12,2) DEFAULT 0,
  ytd_social_security NUMERIC(12,2) DEFAULT 0,
  ytd_medicare NUMERIC(12,2) DEFAULT 0,
  ytd_net NUMERIC(12,2) DEFAULT 0,
  -- Metadata
  payment_method TEXT DEFAULT 'direct_deposit' CHECK (payment_method IN ('direct_deposit','check','cash')),
  check_number TEXT,
  gusto_pay_stub_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Payroll Tax Configs — employer tax rates per state
CREATE TABLE payroll_tax_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tax_year INTEGER NOT NULL,
  state TEXT NOT NULL,
  -- Federal
  futa_rate NUMERIC(6,4) DEFAULT 0.006,
  -- State
  suta_rate NUMERIC(6,4),
  suta_wage_base NUMERIC(12,2),
  state_income_tax_rate NUMERIC(6,4),
  -- Workers comp
  workers_comp_rate NUMERIC(6,4),
  workers_comp_class_code TEXT,
  -- Config
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, tax_year, state)
);

-- RLS
ALTER TABLE pay_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE pay_stubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll_tax_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY pay_periods_company ON pay_periods FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
-- Pay stubs: company access + individual employee can see their own
CREATE POLICY pay_stubs_company ON pay_stubs FOR SELECT USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);
CREATE POLICY pay_stubs_insert ON pay_stubs FOR INSERT WITH CHECK (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);
CREATE POLICY pay_stubs_update ON pay_stubs FOR UPDATE USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);
CREATE POLICY payroll_tax_company ON payroll_tax_configs FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_pay_periods_company ON pay_periods(company_id, period_start);
CREATE INDEX idx_pay_stubs_period ON pay_stubs(pay_period_id);
CREATE INDEX idx_pay_stubs_user ON pay_stubs(user_id);
CREATE INDEX idx_pay_stubs_company ON pay_stubs(company_id);
CREATE INDEX idx_payroll_tax_company ON payroll_tax_configs(company_id, tax_year);

-- Triggers
CREATE TRIGGER pay_periods_updated BEFORE UPDATE ON pay_periods FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER pay_stubs_updated BEFORE UPDATE ON pay_stubs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER payroll_tax_updated BEFORE UPDATE ON payroll_tax_configs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
