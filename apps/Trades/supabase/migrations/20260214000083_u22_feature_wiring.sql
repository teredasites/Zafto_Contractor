-- U22: Isolated Feature Wiring
-- FK columns + indexes to connect isolated features

-- Meetings → Jobs link
ALTER TABLE meetings ADD COLUMN IF NOT EXISTS job_id uuid REFERENCES jobs(id);
CREATE INDEX IF NOT EXISTS idx_meetings_job ON meetings(job_id) WHERE job_id IS NOT NULL;

-- Fleet → dispatch: vehicle assignment to user
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS assigned_to_user_id uuid REFERENCES auth.users(id);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS last_gps_lat numeric(10,7);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS last_gps_lng numeric(10,7);
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS last_gps_at timestamptz;
CREATE INDEX IF NOT EXISTS idx_vehicles_assigned ON vehicles(assigned_to_user_id) WHERE assigned_to_user_id IS NOT NULL;

-- Site surveys → estimates link
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS site_survey_id uuid REFERENCES site_surveys(id);
CREATE INDEX IF NOT EXISTS idx_estimates_survey ON estimates(site_survey_id) WHERE site_survey_id IS NOT NULL;

-- Documents auto-attach: entity linking
ALTER TABLE documents ADD COLUMN IF NOT EXISTS entity_type text;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS entity_id uuid;
CREATE INDEX IF NOT EXISTS idx_documents_entity ON documents(entity_type, entity_id) WHERE entity_type IS NOT NULL;

-- Jobs → OSHA safety checklist
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS safety_checklist jsonb;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS safety_acknowledged_at timestamptz;
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS safety_acknowledged_by uuid REFERENCES auth.users(id);

-- Customer communication timeline (call/sms log)
CREATE TABLE IF NOT EXISTS customer_communications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  customer_id uuid REFERENCES customers(id),
  lead_id uuid REFERENCES leads(id),
  direction text NOT NULL CHECK (direction IN ('inbound','outbound')),
  channel text NOT NULL CHECK (channel IN ('call','sms','email','fax')),
  from_number text,
  to_number text,
  duration_seconds int,
  recording_url text,
  message_body text,
  subject text,
  status text,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE customer_communications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cc_select" ON customer_communications FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "cc_insert" ON customer_communications FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE INDEX idx_cc_customer ON customer_communications(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX idx_cc_lead ON customer_communications(lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX idx_cc_created ON customer_communications(created_at DESC);
