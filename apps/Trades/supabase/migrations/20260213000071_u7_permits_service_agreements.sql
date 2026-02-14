-- U7: Permits + Service Agreements tables
-- Permits: per-job permit tracking with inspections JSONB
-- Service Agreements: recurring service contracts

-- ══════════════════════════════════════════════
-- PERMITS
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS permits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  customer_id uuid REFERENCES customers(id),
  created_by uuid REFERENCES auth.users(id),
  permit_number text,
  permit_type text NOT NULL DEFAULT 'other' CHECK (permit_type IN ('electrical', 'plumbing', 'mechanical', 'building', 'roofing', 'solar', 'demolition', 'fire', 'other')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'applied', 'in_review', 'approved', 'inspection_scheduled', 'passed', 'failed', 'expired', 'cancelled')),
  description text,
  address text,
  jurisdiction text,
  fee numeric(10,2) DEFAULT 0,
  applied_date timestamptz,
  approved_date timestamptz,
  expiration_date timestamptz,
  inspections jsonb DEFAULT '[]', -- [{id, date, inspector, result, notes, corrections}]
  documents jsonb DEFAULT '[]', -- [{name, type, storage_path, uploaded_at}]
  notes text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE permits ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_permits_company ON permits (company_id);
CREATE INDEX idx_permits_job ON permits (job_id);
CREATE INDEX idx_permits_status ON permits (company_id, status);
CREATE TRIGGER permits_updated_at BEFORE UPDATE ON permits FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER permits_audit AFTER INSERT OR UPDATE OR DELETE ON permits FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "permits_select" ON permits FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "permits_insert" ON permits FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "permits_update" ON permits FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "permits_delete" ON permits FOR DELETE USING (company_id = requesting_company_id());

-- ══════════════════════════════════════════════
-- SERVICE AGREEMENTS
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS service_agreements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id),
  created_by uuid REFERENCES auth.users(id),
  agreement_number text,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'expired', 'cancelled', 'pending_renewal')),
  agreement_type text NOT NULL DEFAULT 'maintenance' CHECK (agreement_type IN ('maintenance', 'service', 'warranty', 'support', 'inspection', 'other')),
  description text,
  start_date date,
  end_date date,
  renewal_type text DEFAULT 'manual' CHECK (renewal_type IN ('auto', 'manual', 'none')),
  billing_frequency text DEFAULT 'monthly' CHECK (billing_frequency IN ('monthly', 'quarterly', 'semi_annual', 'annual', 'one_time')),
  billing_amount numeric(10,2) DEFAULT 0,
  total_value numeric(10,2) DEFAULT 0,
  services jsonb DEFAULT '[]', -- [{name, description, frequency, included}]
  documents jsonb DEFAULT '[]', -- [{name, type, storage_path, uploaded_at}]
  notes text,
  last_service_date timestamptz,
  next_service_date timestamptz,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE service_agreements ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_service_agreements_company ON service_agreements (company_id);
CREATE INDEX idx_service_agreements_customer ON service_agreements (customer_id);
CREATE INDEX idx_service_agreements_status ON service_agreements (company_id, status);
CREATE TRIGGER service_agreements_updated_at BEFORE UPDATE ON service_agreements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER service_agreements_audit AFTER INSERT OR UPDATE OR DELETE ON service_agreements FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "service_agreements_select" ON service_agreements FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "service_agreements_insert" ON service_agreements FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "service_agreements_update" ON service_agreements FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "service_agreements_delete" ON service_agreements FOR DELETE USING (company_id = requesting_company_id());

-- ══════════════════════════════════════════════
-- WARRANTIES (standalone table, extends existing warranty_dispatches)
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS warranties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id),
  job_id uuid REFERENCES jobs(id),
  created_by uuid REFERENCES auth.users(id),
  warranty_number text,
  title text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'claimed', 'voided')),
  warranty_type text NOT NULL DEFAULT 'labor' CHECK (warranty_type IN ('labor', 'parts', 'full', 'manufacturer', 'extended', 'other')),
  description text,
  coverage_details text,
  start_date date,
  end_date date,
  duration_months integer,
  terms text,
  claims jsonb DEFAULT '[]', -- [{id, date, description, status, resolution, cost}]
  documents jsonb DEFAULT '[]', -- [{name, type, storage_path, uploaded_at}]
  notes text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE warranties ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_warranties_company ON warranties (company_id);
CREATE INDEX idx_warranties_customer ON warranties (customer_id);
CREATE INDEX idx_warranties_status ON warranties (company_id, status);
CREATE TRIGGER warranties_updated_at BEFORE UPDATE ON warranties FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER warranties_audit AFTER INSERT OR UPDATE OR DELETE ON warranties FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "warranties_select" ON warranties FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "warranties_insert" ON warranties FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "warranties_update" ON warranties FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "warranties_delete" ON warranties FOR DELETE USING (company_id = requesting_company_id());

-- ══════════════════════════════════════════════
-- AUTOMATIONS
-- ══════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS automations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_by uuid REFERENCES auth.users(id),
  name text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('active', 'paused', 'draft')),
  trigger_type text NOT NULL CHECK (trigger_type IN ('job_status', 'invoice_overdue', 'lead_idle', 'time_based', 'customer_event', 'bid_event')),
  trigger_config jsonb NOT NULL DEFAULT '{}', -- {condition, value, etc.}
  delay_minutes integer DEFAULT 0,
  actions jsonb NOT NULL DEFAULT '[]', -- [{type, label, config}]
  last_run_at timestamptz,
  run_count integer DEFAULT 0,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE automations ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_automations_company ON automations (company_id);
CREATE INDEX idx_automations_status ON automations (company_id, status);
CREATE TRIGGER automations_updated_at BEFORE UPDATE ON automations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER automations_audit AFTER INSERT OR UPDATE OR DELETE ON automations FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "automations_select" ON automations FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "automations_insert" ON automations FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "automations_update" ON automations FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "automations_delete" ON automations FOR DELETE USING (company_id = requesting_company_id());
