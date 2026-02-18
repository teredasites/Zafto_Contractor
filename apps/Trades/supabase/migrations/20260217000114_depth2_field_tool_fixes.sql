-- DEPTH2: Field tool schema fixes
-- 1. Mileage trips: add missing GPS + duration columns
-- 2. Receipts: add file_name, file_size, mime_type for team-portal upload
-- 3. Voice notes: add UPDATE + DELETE RLS policies
-- 4. Compliance records: add UPDATE + DELETE RLS policies
-- 5. Mileage trips: add UPDATE policy for soft delete

-- ============================================================
-- 1. MILEAGE TRIPS — missing GPS columns (Dart model writes these)
-- ============================================================
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS start_latitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS start_longitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS end_latitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS end_longitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS duration_seconds integer;

-- ============================================================
-- 2. RECEIPTS — add columns team-portal insert needs
-- ============================================================
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS file_name text;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS file_size integer;
ALTER TABLE receipts ADD COLUMN IF NOT EXISTS mime_type text;

-- ============================================================
-- 3. VOICE NOTES — missing UPDATE + DELETE RLS policies
-- ============================================================
CREATE POLICY "voice_notes_update" ON voice_notes FOR UPDATE
  USING (company_id = requesting_company_id());
CREATE POLICY "voice_notes_delete" ON voice_notes FOR DELETE
  USING (company_id = requesting_company_id());

-- ============================================================
-- 4. COMPLIANCE RECORDS — missing UPDATE + DELETE RLS policies
-- ============================================================
CREATE POLICY "compliance_update" ON compliance_records FOR UPDATE
  USING (company_id = requesting_company_id());
CREATE POLICY "compliance_delete" ON compliance_records FOR DELETE
  USING (company_id = requesting_company_id());

-- ============================================================
-- 5. MILEAGE TRIPS — missing UPDATE + DELETE RLS policies
-- ============================================================
CREATE POLICY "mileage_update" ON mileage_trips FOR UPDATE
  USING (company_id = requesting_company_id());
CREATE POLICY "mileage_delete" ON mileage_trips FOR DELETE
  USING (company_id = requesting_company_id());
