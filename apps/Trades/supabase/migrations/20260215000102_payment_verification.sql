-- Payment Verification & Government Program Support
-- Enables: tenant self-report offline payments, owner verification workflow,
-- Section 8 / HCV / VASH / government program tracking, expanded payment methods
-- Tables: ALTER rent_payments, CREATE government_payment_programs, CREATE payment_verification_log, ALTER invoices

-- =============================================================================
-- 1. Expand rent_payments.payment_method to cover ALL real-world methods
-- =============================================================================

-- Drop the auto-generated CHECK constraint
ALTER TABLE rent_payments DROP CONSTRAINT rent_payments_payment_method_check;

-- Add expanded payment methods
ALTER TABLE rent_payments ADD CONSTRAINT rent_payments_payment_method_check
  CHECK (payment_method IN (
    'ach', 'credit_card', 'debit_card', 'cash', 'check', 'money_order',
    'direct_deposit', 'wire_transfer', 'zelle', 'venmo', 'cashapp',
    'housing_voucher', 'government_direct', 'other'
  ));

-- =============================================================================
-- 2. Add verification + payment source columns to rent_payments
-- =============================================================================

-- Who reported this payment (NULL = owner/admin recorded, non-NULL = self-reported by tenant)
ALTER TABLE rent_payments ADD COLUMN reported_by uuid REFERENCES auth.users(id);

-- Verification workflow status
ALTER TABLE rent_payments ADD COLUMN verification_status text NOT NULL DEFAULT 'auto_verified'
  CHECK (verification_status IN ('auto_verified', 'pending_verification', 'verified', 'disputed', 'rejected'));

-- Who verified and when
ALTER TABLE rent_payments ADD COLUMN verified_by uuid REFERENCES auth.users(id);
ALTER TABLE rent_payments ADD COLUMN verified_at timestamptz;
ALTER TABLE rent_payments ADD COLUMN verification_notes text;

-- Proof of payment (receipt photo, check image, confirmation screenshot)
ALTER TABLE rent_payments ADD COLUMN proof_document_url text;

-- Payment source: who actually sent the money
ALTER TABLE rent_payments ADD COLUMN payment_source text NOT NULL DEFAULT 'tenant'
  CHECK (payment_source IN ('tenant', 'housing_authority', 'government_program', 'third_party', 'other'));
ALTER TABLE rent_payments ADD COLUMN source_name text;       -- e.g. "Metro Housing Authority"
ALTER TABLE rent_payments ADD COLUMN source_reference text;  -- voucher #, HAP contract #, confirmation code

-- Date the payment was actually made (vs created_at which is when it was recorded)
ALTER TABLE rent_payments ADD COLUMN payment_date date;

-- =============================================================================
-- 3. Government Payment Programs (per-tenant program tracking)
-- =============================================================================

CREATE TABLE government_payment_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  program_type text NOT NULL CHECK (program_type IN (
    'section_8_hcv',           -- Section 8 Housing Choice Voucher
    'vash',                     -- Veterans Affairs Supportive Housing
    'public_housing',           -- Public Housing Authority
    'project_based_voucher',    -- Project-Based Voucher (tied to property)
    'state_program',            -- State housing assistance
    'local_program',            -- County/city housing assistance
    'employer_assistance',      -- Employer housing benefit
    'other'                     -- Other third-party program
  )),
  program_name text NOT NULL,             -- "Metro Housing Authority Section 8"
  authority_name text,                     -- housing authority name
  authority_contact_name text,
  authority_phone text,
  authority_email text,
  authority_address text,
  voucher_number text,                     -- HCV voucher number
  hap_contract_number text,                -- HAP contract number
  monthly_hap_amount numeric(10,2),        -- government portion (fixed)
  tenant_portion numeric(10,2),            -- tenant's share of rent
  utility_allowance numeric(10,2),         -- utility allowance amount
  payment_standard numeric(10,2),          -- HUD payment standard for area
  effective_date date,
  expiration_date date,
  recertification_date date,               -- annual recertification deadline
  inspection_date date,                    -- last HQS inspection date
  next_inspection_date date,               -- next HQS inspection due
  is_active boolean NOT NULL DEFAULT true,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz                   -- soft delete
);

-- Indexes
CREATE INDEX idx_govt_programs_tenant ON government_payment_programs(tenant_id) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_govt_programs_company ON government_payment_programs(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_govt_programs_recert ON government_payment_programs(recertification_date) WHERE is_active = true AND deleted_at IS NULL;
CREATE UNIQUE INDEX idx_govt_programs_unique_active ON government_payment_programs(tenant_id, program_type) WHERE is_active = true AND deleted_at IS NULL;

-- Updated_at trigger
CREATE TRIGGER update_govt_programs_updated_at BEFORE UPDATE ON government_payment_programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 4. Payment Verification Log (immutable audit trail)
-- =============================================================================

CREATE TABLE payment_verification_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  payment_id uuid NOT NULL REFERENCES rent_payments(id),
  payment_context text NOT NULL DEFAULT 'rent' CHECK (payment_context IN ('rent', 'invoice', 'bid_deposit')),
  action text NOT NULL CHECK (action IN ('reported', 'verified', 'disputed', 'rejected', 'updated', 'proof_uploaded')),
  performed_by uuid NOT NULL REFERENCES auth.users(id),
  old_status text,
  new_status text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
  -- No updated_at: this table is immutable (append-only)
);

-- Indexes
CREATE INDEX idx_verification_log_payment ON payment_verification_log(payment_id, created_at DESC);
CREATE INDEX idx_verification_log_company ON payment_verification_log(company_id, created_at DESC);

-- =============================================================================
-- 5. Rent payments verification index
-- =============================================================================

CREATE INDEX idx_rent_payments_verification ON rent_payments(company_id, verification_status)
  WHERE verification_status = 'pending_verification';

CREATE INDEX idx_rent_payments_source ON rent_payments(company_id, payment_source)
  WHERE payment_source != 'tenant';

-- =============================================================================
-- 6. ALTER invoices — add offline payment tracking
-- =============================================================================

ALTER TABLE invoices ADD COLUMN last_payment_method text;
ALTER TABLE invoices ADD COLUMN last_payment_source text
  CHECK (last_payment_source IN ('customer', 'financing', 'insurance', 'third_party', 'government', 'other'));
ALTER TABLE invoices ADD COLUMN last_payment_reference text;
ALTER TABLE invoices ADD COLUMN last_payment_proof_url text;

-- =============================================================================
-- 7. RLS Policies
-- =============================================================================

-- Government Payment Programs: company-scoped access
ALTER TABLE government_payment_programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "govt_programs_select" ON government_payment_programs
  FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);

CREATE POLICY "govt_programs_insert" ON government_payment_programs
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "govt_programs_update" ON government_payment_programs
  FOR UPDATE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin', 'office_manager'));

CREATE POLICY "govt_programs_delete" ON government_payment_programs
  FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- Tenant can view their own programs
CREATE POLICY "govt_programs_tenant" ON government_payment_programs
  FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));

-- Payment Verification Log: company-scoped, INSERT only for all, SELECT for company
ALTER TABLE payment_verification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "verification_log_select" ON payment_verification_log
  FOR SELECT USING (company_id = requesting_company_id());

CREATE POLICY "verification_log_insert" ON payment_verification_log
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

-- No UPDATE or DELETE policies: immutable audit trail

-- Tenant self-report: allow tenant to INSERT rent_payments with pending_verification status
CREATE POLICY "rent_payments_tenant_report" ON rent_payments
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid())
    AND verification_status = 'pending_verification'
    AND reported_by = auth.uid()
  );

-- Tenant can view verification log entries for their own payments
CREATE POLICY "verification_log_tenant" ON payment_verification_log
  FOR SELECT USING (
    payment_id IN (
      SELECT rp.id FROM rent_payments rp
      JOIN tenants t ON rp.tenant_id = t.id
      WHERE t.auth_user_id = auth.uid()
    )
  );

-- =============================================================================
-- 8. Audit Triggers
-- =============================================================================

CREATE TRIGGER govt_programs_audit AFTER INSERT OR UPDATE OR DELETE ON government_payment_programs
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER verification_log_audit AFTER INSERT ON payment_verification_log
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
