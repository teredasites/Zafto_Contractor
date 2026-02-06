-- ============================================================
-- ZAFTO CORE SCHEMA — A3b: Business Tables
-- Sprint A3b | Session 39
--
-- Run against: dev first, then staging, then prod
-- Tables: customers, jobs, invoices, bids, time_entries
-- Depends on: A3a (companies, users, audit_trigger_fn)
-- ============================================================

-- CUSTOMERS
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  name text NOT NULL,
  email text,
  phone text,
  alternate_phone text,
  address text,
  city text,
  state text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  type text NOT NULL DEFAULT 'residential' CHECK (type IN ('residential', 'commercial')),
  company_name text,
  tags text[] DEFAULT '{}',
  notes text,
  access_instructions text,
  referred_by text,
  preferred_tech_id uuid,
  email_opt_in boolean DEFAULT true,
  sms_opt_in boolean DEFAULT false,
  -- Denormalized stats (updated by triggers or edge functions)
  job_count int DEFAULT 0,
  invoice_count int DEFAULT 0,
  total_revenue numeric(12,2) DEFAULT 0,
  outstanding_balance numeric(12,2) DEFAULT 0,
  last_job_date timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER customers_audit AFTER INSERT OR UPDATE OR DELETE ON customers FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "customers_select" ON customers FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "customers_insert" ON customers FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "customers_update" ON customers FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "customers_delete" ON customers FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- JOBS
CREATE TABLE jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  customer_id uuid REFERENCES customers(id),
  assigned_to_user_id uuid REFERENCES auth.users(id),
  assigned_user_ids uuid[] DEFAULT '{}',
  team_id uuid,
  -- Details
  title text,
  description text,
  internal_notes text,
  trade_type text NOT NULL DEFAULT 'electrical',
  -- Customer (denormalized for offline)
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_phone text,
  -- Location
  address text NOT NULL DEFAULT '',
  city text,
  state text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'dispatched', 'enRoute', 'inProgress', 'onHold', 'completed', 'invoiced', 'cancelled')),
  priority text NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  -- Job Type (progressive disclosure — D1)
  job_type text NOT NULL DEFAULT 'standard' CHECK (job_type IN ('standard', 'insurance_claim', 'warranty_dispatch')),
  type_metadata jsonb DEFAULT '{}',
  -- Scheduling
  scheduled_start timestamptz,
  scheduled_end timestamptz,
  estimated_duration int, -- minutes
  started_at timestamptz,
  completed_at timestamptz,
  -- Financial
  estimated_amount numeric(12,2) DEFAULT 0,
  actual_amount numeric(12,2),
  -- Tags
  tags text[] DEFAULT '{}',
  -- Links
  invoice_id uuid,
  quote_id uuid,
  -- Sync
  synced_to_cloud boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_jobs_company_status ON jobs (company_id, status);
CREATE INDEX idx_jobs_company_date ON jobs (company_id, scheduled_start);
CREATE INDEX idx_jobs_assigned ON jobs (assigned_to_user_id);
CREATE TRIGGER jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER jobs_audit AFTER INSERT OR UPDATE OR DELETE ON jobs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "jobs_select" ON jobs FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "jobs_insert" ON jobs FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "jobs_update" ON jobs FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "jobs_delete" ON jobs FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- INVOICES
CREATE TABLE invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  customer_id uuid REFERENCES customers(id),
  invoice_number text NOT NULL,
  -- Customer (denormalized for PDF)
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_phone text,
  customer_address text NOT NULL DEFAULT '',
  -- Line items
  line_items jsonb DEFAULT '[]',
  -- Totals
  subtotal numeric(12,2) DEFAULT 0,
  discount_amount numeric(12,2) DEFAULT 0,
  discount_reason text,
  tax_rate numeric(5,2) DEFAULT 0,
  tax_amount numeric(12,2) DEFAULT 0,
  total numeric(12,2) DEFAULT 0,
  amount_paid numeric(12,2) DEFAULT 0,
  amount_due numeric(12,2) DEFAULT 0,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pendingApproval', 'approved', 'rejected', 'sent', 'viewed', 'partiallyPaid', 'paid', 'voided', 'overdue')),
  -- Approval
  requires_approval boolean DEFAULT false,
  approved_by_user_id uuid,
  approved_at timestamptz,
  rejection_reason text,
  -- Sending
  sent_at timestamptz,
  sent_via text,
  viewed_at timestamptz,
  -- Payment
  paid_at timestamptz,
  payment_method text,
  payment_reference text,
  -- Signature
  signature_data text,
  signed_by_name text,
  signed_at timestamptz,
  -- PDF
  pdf_path text,
  pdf_url text,
  -- Dates
  due_date timestamptz,
  notes text,
  terms text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_invoices_company_status ON invoices (company_id, status);
CREATE TRIGGER invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER invoices_audit AFTER INSERT OR UPDATE OR DELETE ON invoices FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "invoices_select" ON invoices FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "invoices_insert" ON invoices FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "invoices_update" ON invoices FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "invoices_delete" ON invoices FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- BIDS
CREATE TABLE bids (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  customer_id uuid REFERENCES customers(id),
  job_id uuid REFERENCES jobs(id),
  bid_number text NOT NULL,
  title text NOT NULL DEFAULT '',
  customer_name text NOT NULL DEFAULT '',
  customer_email text,
  customer_address text,
  -- Content
  line_items jsonb DEFAULT '[]',
  scope_of_work text,
  terms text,
  valid_until timestamptz,
  -- Totals
  subtotal numeric(12,2) DEFAULT 0,
  tax_rate numeric(5,2) DEFAULT 0,
  tax_amount numeric(12,2) DEFAULT 0,
  total numeric(12,2) DEFAULT 0,
  -- Status
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'accepted', 'rejected', 'expired')),
  sent_at timestamptz,
  viewed_at timestamptz,
  accepted_at timestamptz,
  rejected_at timestamptz,
  rejection_reason text,
  -- Signature
  signature_data text,
  signed_by_name text,
  signed_at timestamptz,
  -- PDF
  pdf_path text,
  pdf_url text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER bids_updated_at BEFORE UPDATE ON bids FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER bids_audit AFTER INSERT OR UPDATE OR DELETE ON bids FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "bids_select" ON bids FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "bids_insert" ON bids FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "bids_update" ON bids FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "bids_delete" ON bids FOR DELETE USING (company_id = auth.company_id() AND auth.user_role() IN ('owner', 'admin'));

-- TIME ENTRIES
CREATE TABLE time_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  clock_in timestamptz NOT NULL,
  clock_out timestamptz,
  break_minutes int DEFAULT 0,
  total_minutes int,
  hourly_rate numeric(8,2),
  labor_cost numeric(12,2),
  overtime_minutes int DEFAULT 0,
  notes text,
  location_pings jsonb DEFAULT '[]',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'approved', 'rejected')),
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE time_entries ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_time_entries_company_user ON time_entries (company_id, user_id);
CREATE INDEX idx_time_entries_job ON time_entries (job_id);
CREATE TRIGGER time_entries_updated_at BEFORE UPDATE ON time_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER time_entries_audit AFTER INSERT OR UPDATE OR DELETE ON time_entries FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "time_entries_select" ON time_entries FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "time_entries_insert" ON time_entries FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "time_entries_update" ON time_entries FOR UPDATE USING (company_id = auth.company_id() AND (auth.user_role() IN ('owner', 'admin') OR user_id = auth.uid()));
