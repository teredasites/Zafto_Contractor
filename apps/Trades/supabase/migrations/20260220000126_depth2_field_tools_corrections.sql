-- DEPTH2: Field Tools Depth Corrections
-- Fix: daily_logs missing soft delete (Critical Rule #14 violation)
-- Fix: mileage_trips missing trip_type (IRS compliance)
-- Fix: mileage_trips missing GPS start/end columns
-- Fix: punch_list_items missing soft delete filter in RLS
-- Fix: voice_notes missing updated_at trigger

----------------------------------------------------------------------
-- 1. daily_logs — add soft delete + DELETE policy
----------------------------------------------------------------------
ALTER TABLE daily_logs ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Update RLS to filter deleted records
DROP POLICY IF EXISTS "daily_logs_select" ON daily_logs;
CREATE POLICY "daily_logs_select" ON daily_logs FOR SELECT
  USING (company_id = requesting_company_id() AND deleted_at IS NULL);

-- Add DELETE policy (soft delete only — hooks use .update({deleted_at}))
DROP POLICY IF EXISTS "daily_logs_delete" ON daily_logs;
CREATE POLICY "daily_logs_delete" ON daily_logs FOR DELETE
  USING (company_id = requesting_company_id());

----------------------------------------------------------------------
-- 2. mileage_trips — add trip_type for IRS categorization
----------------------------------------------------------------------
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS trip_type text
  NOT NULL DEFAULT 'business'
  CHECK (trip_type IN ('business', 'personal', 'commute', 'medical', 'charity'));

ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS start_latitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS start_longitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS end_latitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS end_longitude double precision;
ALTER TABLE mileage_trips ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- updated_at trigger
DROP TRIGGER IF EXISTS mileage_trips_updated_at ON mileage_trips;
CREATE TRIGGER mileage_trips_updated_at BEFORE UPDATE ON mileage_trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Index for date-range queries
CREATE INDEX IF NOT EXISTS idx_mileage_trips_user_date
  ON mileage_trips (user_id, trip_date DESC);

----------------------------------------------------------------------
-- 3. punch_list_items — ensure soft delete filter in SELECT policy
----------------------------------------------------------------------
-- Check if deleted_at column exists; add if not
ALTER TABLE punch_list_items ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Recreate SELECT policy with soft delete filter
DROP POLICY IF EXISTS "punch_list_select" ON punch_list_items;
CREATE POLICY "punch_list_select" ON punch_list_items FOR SELECT
  USING (company_id = requesting_company_id() AND deleted_at IS NULL);

-- Ensure UPDATE policy exists
DROP POLICY IF EXISTS "punch_list_update" ON punch_list_items;
CREATE POLICY "punch_list_update" ON punch_list_items FOR UPDATE
  USING (company_id = requesting_company_id());

-- Ensure DELETE policy exists (for soft delete via update)
DROP POLICY IF EXISTS "punch_list_delete" ON punch_list_items;
CREATE POLICY "punch_list_delete" ON punch_list_items FOR DELETE
  USING (company_id = requesting_company_id());

----------------------------------------------------------------------
-- 4. voice_notes — add updated_at + trigger if missing
----------------------------------------------------------------------
ALTER TABLE voice_notes ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DROP TRIGGER IF EXISTS voice_notes_updated_at ON voice_notes;
CREATE TRIGGER voice_notes_updated_at BEFORE UPDATE ON voice_notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

----------------------------------------------------------------------
-- 5. daily_logs — add trade_data JSONB for trade-specific fields
----------------------------------------------------------------------
ALTER TABLE daily_logs ADD COLUMN IF NOT EXISTS trade_data jsonb DEFAULT '{}';

----------------------------------------------------------------------
-- 6. Company-scoped indexes where missing
----------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_daily_logs_company ON daily_logs (company_id);
CREATE INDEX IF NOT EXISTS idx_voice_notes_company ON voice_notes (company_id);
CREATE INDEX IF NOT EXISTS idx_voice_notes_job ON voice_notes (job_id);
CREATE INDEX IF NOT EXISTS idx_punch_list_company ON punch_list_items (company_id);
CREATE INDEX IF NOT EXISTS idx_receipts_company ON receipts (company_id);
