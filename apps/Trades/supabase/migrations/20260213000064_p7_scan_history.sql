-- P7: Scan History / Audit Trail
-- Phase P (Recon) — Sprint P7
-- Table: scan_history — logs all scan, verification, and adjustment actions

CREATE TABLE scan_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (
    action IN ('created', 'updated', 'verified', 'adjusted', 're_scanned')
  ),
  field_changed TEXT,
  old_value TEXT,
  new_value TEXT,
  performed_by UUID REFERENCES auth.users(id),
  performed_at TIMESTAMPTZ DEFAULT now(),
  device TEXT,  -- 'mobile', 'web', 'api'
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY sh_company ON scan_history
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_sh_scan ON scan_history(scan_id);
CREATE INDEX idx_sh_company ON scan_history(company_id);
CREATE INDEX idx_sh_action ON scan_history(action);
CREATE INDEX idx_sh_performed_at ON scan_history(performed_at DESC);

-- Trigger
CREATE TRIGGER sh_audit AFTER INSERT OR UPDATE OR DELETE ON scan_history
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Add verification columns to property_scans
ALTER TABLE property_scans
  ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'unverified'
    CHECK (verification_status IN ('unverified', 'verified', 'adjusted')),
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;
