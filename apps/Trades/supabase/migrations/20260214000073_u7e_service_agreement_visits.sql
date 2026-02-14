-- U7e: Service Agreement Visits — tracks actual service visits against agreements

CREATE TABLE IF NOT EXISTS service_agreement_visits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  agreement_id uuid NOT NULL REFERENCES service_agreements(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  scheduled_date date NOT NULL,
  completed_date date,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'missed', 'rescheduled', 'cancelled')),
  visit_number integer NOT NULL DEFAULT 1,
  notes text,
  technician_id uuid REFERENCES auth.users(id),
  deleted_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE service_agreement_visits ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_sav_company ON service_agreement_visits (company_id);
CREATE INDEX idx_sav_agreement ON service_agreement_visits (agreement_id);
CREATE INDEX idx_sav_scheduled ON service_agreement_visits (company_id, scheduled_date);
CREATE INDEX idx_sav_status ON service_agreement_visits (company_id, status);
CREATE TRIGGER sav_updated_at BEFORE UPDATE ON service_agreement_visits FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER sav_audit AFTER INSERT OR UPDATE OR DELETE ON service_agreement_visits FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "sav_select" ON service_agreement_visits FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "sav_insert" ON service_agreement_visits FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "sav_update" ON service_agreement_visits FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "sav_delete" ON service_agreement_visits FOR DELETE USING (company_id = requesting_company_id());
