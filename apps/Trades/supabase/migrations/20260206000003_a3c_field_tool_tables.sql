-- ============================================================
-- ZAFTO CORE SCHEMA — A3c: Field Tool Tables
-- Sprint A3c | Session 39
--
-- Run against: dev first, then staging, then prod
-- Tables: photos, signatures, voice_notes, receipts, compliance_records, mileage_trips
-- Depends on: A3a (companies, users), A3b (jobs, invoices)
-- ============================================================

-- PHOTOS (job site, before/after, defect markup, general)
CREATE TABLE photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  uploaded_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  thumbnail_path text,
  file_name text,
  file_size int,
  mime_type text,
  width int,
  height int,
  category text NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'before', 'after', 'defect', 'markup', 'receipt', 'inspection', 'completion')),
  caption text,
  tags text[] DEFAULT '{}',
  metadata jsonb DEFAULT '{}',
  is_client_visible boolean DEFAULT false,
  taken_at timestamptz,
  latitude double precision,
  longitude double precision,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE photos ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_photos_job ON photos (job_id);
CREATE INDEX idx_photos_company ON photos (company_id, created_at DESC);
CREATE TRIGGER photos_audit AFTER INSERT OR UPDATE OR DELETE ON photos FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "photos_select" ON photos FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "photos_insert" ON photos FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "photos_update" ON photos FOR UPDATE USING (company_id = auth.company_id());
CREATE POLICY "photos_delete" ON photos FOR DELETE USING (company_id = auth.company_id());

-- SIGNATURES
CREATE TABLE signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  invoice_id uuid REFERENCES invoices(id),
  captured_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  signer_name text NOT NULL,
  signer_role text, -- 'customer', 'technician', 'inspector'
  signature_data text NOT NULL, -- base64 PNG
  storage_path text,
  purpose text NOT NULL DEFAULT 'job_completion' CHECK (purpose IN ('job_completion', 'invoice_approval', 'change_order', 'inspection', 'safety_briefing')),
  ip_address inet,
  signed_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE signatures ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER signatures_audit AFTER INSERT OR UPDATE OR DELETE ON signatures FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "signatures_select" ON signatures FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "signatures_insert" ON signatures FOR INSERT WITH CHECK (company_id = auth.company_id());

-- VOICE NOTES
CREATE TABLE voice_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  recorded_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  duration_seconds int,
  file_size int,
  transcription text,
  transcription_status text DEFAULT 'pending' CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed')),
  tags text[] DEFAULT '{}',
  recorded_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE voice_notes ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER voice_notes_audit AFTER INSERT OR UPDATE OR DELETE ON voice_notes FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "voice_notes_select" ON voice_notes FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "voice_notes_insert" ON voice_notes FOR INSERT WITH CHECK (company_id = auth.company_id());

-- RECEIPTS
CREATE TABLE receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  scanned_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  storage_path text NOT NULL,
  vendor_name text,
  amount numeric(12,2),
  category text,
  description text,
  receipt_date date,
  ocr_data jsonb DEFAULT '{}',
  ocr_status text DEFAULT 'pending' CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed')),
  is_reimbursable boolean DEFAULT false,
  reimbursement_status text DEFAULT 'none' CHECK (reimbursement_status IN ('none', 'pending', 'approved', 'denied', 'paid')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER receipts_updated_at BEFORE UPDATE ON receipts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER receipts_audit AFTER INSERT OR UPDATE OR DELETE ON receipts FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "receipts_select" ON receipts FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "receipts_insert" ON receipts FOR INSERT WITH CHECK (company_id = auth.company_id());
CREATE POLICY "receipts_update" ON receipts FOR UPDATE USING (company_id = auth.company_id());

-- SAFETY / COMPLIANCE RECORDS
CREATE TABLE compliance_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  record_type text NOT NULL CHECK (record_type IN ('safety_briefing', 'incident_report', 'loto', 'confined_space', 'dead_man_switch', 'inspection')),
  data jsonb NOT NULL DEFAULT '{}',
  attachments jsonb DEFAULT '[]', -- [{storage_path, file_name, type}]
  crew_members uuid[] DEFAULT '{}',
  status text DEFAULT 'active',
  severity text, -- for incidents: 'minor', 'major', 'critical'
  location_latitude double precision,
  location_longitude double precision,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE compliance_records ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_compliance_records_company_type ON compliance_records (company_id, record_type);
CREATE TRIGGER compliance_records_audit AFTER INSERT OR UPDATE OR DELETE ON compliance_records FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "compliance_select" ON compliance_records FOR SELECT USING (company_id = auth.company_id());
CREATE POLICY "compliance_insert" ON compliance_records FOR INSERT WITH CHECK (company_id = auth.company_id());

-- MILEAGE TRIPS
CREATE TABLE mileage_trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  job_id uuid REFERENCES jobs(id),
  start_address text,
  end_address text,
  distance_miles numeric(8,2),
  start_odometer numeric(10,1),
  end_odometer numeric(10,1),
  purpose text,
  route_data jsonb DEFAULT '{}',
  trip_date date NOT NULL DEFAULT CURRENT_DATE,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE mileage_trips ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER mileage_trips_audit AFTER INSERT OR UPDATE OR DELETE ON mileage_trips FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "mileage_select" ON mileage_trips FOR SELECT USING (company_id = auth.company_id() AND deleted_at IS NULL);
CREATE POLICY "mileage_insert" ON mileage_trips FOR INSERT WITH CHECK (company_id = auth.company_id());
