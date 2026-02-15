-- W1: Warranty Intelligence Foundation
-- Extend home_equipment with warranty fields + 3 new tables

-- Create home_equipment if it doesn't exist yet (required for warranty tracking)
CREATE TABLE IF NOT EXISTS home_equipment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid REFERENCES properties(id),
  customer_id uuid REFERENCES customers(id),
  equipment_type text NOT NULL DEFAULT 'other',
  brand text,
  model text,
  install_date date,
  condition text DEFAULT 'good',
  notes text,
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE home_equipment ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'home_equipment' AND policyname = 'he_select') THEN
    CREATE POLICY he_select ON home_equipment FOR SELECT USING (company_id = requesting_company_id());
    CREATE POLICY he_insert ON home_equipment FOR INSERT WITH CHECK (company_id = requesting_company_id());
    CREATE POLICY he_update ON home_equipment FOR UPDATE USING (company_id = requesting_company_id());
    CREATE POLICY he_delete ON home_equipment FOR DELETE USING (company_id = requesting_company_id());
  END IF;
END $$;

CREATE TRIGGER he_updated BEFORE UPDATE ON home_equipment FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Extend home_equipment
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS warranty_start_date date;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS warranty_end_date date;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS warranty_type text CHECK (warranty_type IS NULL OR warranty_type IN ('manufacturer','extended','labor','parts_labor','home_warranty'));
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS warranty_provider text;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS warranty_document_path text;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS serial_number text;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS model_number text;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS manufacturer text;
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS installed_by_job_id uuid REFERENCES jobs(id);
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS installed_by_company_id uuid REFERENCES companies(id);
ALTER TABLE home_equipment ADD COLUMN IF NOT EXISTS recall_status text CHECK (recall_status IS NULL OR recall_status IN ('none','pending','acknowledged','resolved'));

-- Warranty outreach log
CREATE TABLE IF NOT EXISTS warranty_outreach_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  equipment_id uuid NOT NULL REFERENCES home_equipment(id),
  customer_id uuid REFERENCES customers(id),
  outreach_type text NOT NULL CHECK (outreach_type IN ('warranty_expiring','maintenance_reminder','recall_notice','upsell_extended','seasonal_check')),
  outreach_trigger text,
  message_content text,
  sent_at timestamptz,
  response_status text CHECK (response_status IS NULL OR response_status IN ('pending','opened','clicked','booked','declined','no_response')),
  resulting_job_id uuid REFERENCES jobs(id),
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Warranty claims
CREATE TABLE IF NOT EXISTS warranty_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  equipment_id uuid NOT NULL REFERENCES home_equipment(id),
  job_id uuid REFERENCES jobs(id),
  customer_id uuid REFERENCES customers(id),
  claim_date date NOT NULL DEFAULT CURRENT_DATE,
  claim_reason text NOT NULL,
  claim_status text NOT NULL DEFAULT 'submitted' CHECK (claim_status IN ('submitted','under_review','approved','denied','resolved','closed')),
  manufacturer_claim_number text,
  resolution_notes text,
  replacement_equipment_id uuid REFERENCES home_equipment(id),
  amount_claimed numeric(10,2),
  amount_approved numeric(10,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Product recalls
CREATE TABLE IF NOT EXISTS product_recalls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  manufacturer text NOT NULL,
  model_pattern text,
  recall_title text NOT NULL,
  recall_description text,
  recall_date date NOT NULL,
  severity text NOT NULL CHECK (severity IN ('low','medium','high','critical')),
  source_url text,
  affected_serial_range text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE warranty_outreach_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE warranty_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_recalls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wol_select" ON warranty_outreach_log FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "wol_insert" ON warranty_outreach_log FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "wol_update" ON warranty_outreach_log FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "wc_select" ON warranty_claims FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "wc_insert" ON warranty_claims FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "wc_update" ON warranty_claims FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

-- Product recalls are public read (any authenticated user can see recalls)
CREATE POLICY "pr_select" ON product_recalls FOR SELECT USING (true);
CREATE POLICY "pr_insert" ON product_recalls FOR INSERT WITH CHECK ((auth.jwt()->'app_metadata'->>'role') IN ('owner','admin','super_admin'));

-- Indexes
CREATE INDEX idx_wol_company ON warranty_outreach_log(company_id);
CREATE INDEX idx_wol_equipment ON warranty_outreach_log(equipment_id);
CREATE INDEX idx_wol_customer ON warranty_outreach_log(customer_id);
CREATE INDEX idx_wc_company ON warranty_claims(company_id);
CREATE INDEX idx_wc_equipment ON warranty_claims(equipment_id);
CREATE INDEX idx_wc_status ON warranty_claims(claim_status);
CREATE INDEX idx_pr_manufacturer ON product_recalls(manufacturer);
CREATE INDEX idx_pr_severity ON product_recalls(severity) WHERE is_active = true;
CREATE INDEX idx_he_warranty_end ON home_equipment(warranty_end_date) WHERE warranty_end_date IS NOT NULL;
CREATE INDEX idx_he_serial ON home_equipment(serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX idx_he_manufacturer ON home_equipment(manufacturer) WHERE manufacturer IS NOT NULL;

-- Triggers
CREATE TRIGGER set_updated_at BEFORE UPDATE ON warranty_outreach_log FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON warranty_claims FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER audit_warranty_claims AFTER INSERT OR UPDATE OR DELETE ON warranty_claims FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
