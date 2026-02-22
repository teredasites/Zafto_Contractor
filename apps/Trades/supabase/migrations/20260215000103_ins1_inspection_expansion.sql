-- INS1: Inspector Deep Buildout — Schema Expansion
-- Adds: inspection_deficiencies, inspection_templates tables
-- Alters: pm_inspections with new fields (GPS, signatures, permits, templates, etc.)

-- ============================================================
-- ALTER pm_inspections — add new columns
-- ============================================================

ALTER TABLE pm_inspections
  ADD COLUMN IF NOT EXISTS permit_id uuid REFERENCES permits(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS parent_inspection_id uuid REFERENCES pm_inspections(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS gps_lat double precision,
  ADD COLUMN IF NOT EXISTS gps_lng double precision,
  ADD COLUMN IF NOT EXISTS gps_checkout_lat double precision,
  ADD COLUMN IF NOT EXISTS gps_checkout_lng double precision,
  ADD COLUMN IF NOT EXISTS checkin_at timestamptz,
  ADD COLUMN IF NOT EXISTS checkout_at timestamptz,
  ADD COLUMN IF NOT EXISTS signature_inspector text,
  ADD COLUMN IF NOT EXISTS signature_contact text,
  ADD COLUMN IF NOT EXISTS code_citations jsonb DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS deficiency_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS report_url text,
  ADD COLUMN IF NOT EXISTS template_id uuid,
  ADD COLUMN IF NOT EXISTS trade text,
  ADD COLUMN IF NOT EXISTS severity text CHECK (severity IN ('critical', 'major', 'minor', 'info')),
  ADD COLUMN IF NOT EXISTS weather_conditions text,
  ADD COLUMN IF NOT EXISTS storm_event boolean DEFAULT false;

-- Index for re-inspection chains
CREATE INDEX IF NOT EXISTS idx_pm_inspections_parent
  ON pm_inspections(parent_inspection_id)
  WHERE parent_inspection_id IS NOT NULL;

-- Index for permit lookups
CREATE INDEX IF NOT EXISTS idx_pm_inspections_permit
  ON pm_inspections(permit_id)
  WHERE permit_id IS NOT NULL;

-- Index for template lookups
CREATE INDEX IF NOT EXISTS idx_pm_inspections_template
  ON pm_inspections(template_id)
  WHERE template_id IS NOT NULL;

-- Index for trade filtering
CREATE INDEX IF NOT EXISTS idx_pm_inspections_trade
  ON pm_inspections(trade)
  WHERE trade IS NOT NULL;

-- ============================================================
-- inspection_deficiencies table
-- ============================================================

CREATE TABLE IF NOT EXISTS inspection_deficiencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  inspection_id uuid NOT NULL REFERENCES pm_inspections(id) ON DELETE CASCADE,
  item_id uuid REFERENCES pm_inspection_items(id) ON DELETE SET NULL,
  code_section text,
  code_title text,
  severity text NOT NULL DEFAULT 'major' CHECK (severity IN ('critical', 'major', 'minor', 'info')),
  description text NOT NULL,
  remediation text,
  deadline timestamptz,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'assigned', 'in_progress', 'corrected', 'verified', 'closed')),
  photos jsonb DEFAULT '[]'::jsonb,
  assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_deficiencies_inspection
  ON inspection_deficiencies(inspection_id);
CREATE INDEX IF NOT EXISTS idx_deficiencies_company
  ON inspection_deficiencies(company_id);
CREATE INDEX IF NOT EXISTS idx_deficiencies_status
  ON inspection_deficiencies(status)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_deficiencies_severity
  ON inspection_deficiencies(severity)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_deficiencies_assigned
  ON inspection_deficiencies(assigned_to)
  WHERE assigned_to IS NOT NULL AND deleted_at IS NULL;

-- Updated_at trigger (skip if already exists)
DO $$ BEGIN
  CREATE TRIGGER update_inspection_deficiencies_updated_at
    BEFORE UPDATE ON inspection_deficiencies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Audit trigger (skip if already exists)
DO $$ BEGIN
  CREATE TRIGGER inspection_deficiencies_audit
    AFTER INSERT OR UPDATE OR DELETE ON inspection_deficiencies
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- RLS
ALTER TABLE inspection_deficiencies ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "deficiencies_select" ON inspection_deficiencies
    FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "deficiencies_insert" ON inspection_deficiencies
    FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "deficiencies_update" ON inspection_deficiencies
    FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "deficiencies_delete" ON inspection_deficiencies
    FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- inspection_templates table
-- ============================================================

CREATE TABLE IF NOT EXISTS inspection_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  trade text,
  inspection_type text NOT NULL DEFAULT 'routine',
  sections jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_system boolean NOT NULL DEFAULT false,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

-- Ensure columns exist (table may have been created by earlier migration without all columns)
ALTER TABLE inspection_templates ADD COLUMN IF NOT EXISTS trade text;
ALTER TABLE inspection_templates ADD COLUMN IF NOT EXISTS inspection_type text NOT NULL DEFAULT 'routine';
ALTER TABLE inspection_templates ADD COLUMN IF NOT EXISTS is_system boolean NOT NULL DEFAULT false;
ALTER TABLE inspection_templates ADD COLUMN IF NOT EXISTS version integer NOT NULL DEFAULT 1;
ALTER TABLE inspection_templates ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_templates_company
  ON inspection_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_templates_trade
  ON inspection_templates(trade)
  WHERE trade IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_templates_type
  ON inspection_templates(inspection_type);
CREATE INDEX IF NOT EXISTS idx_templates_system
  ON inspection_templates(is_system)
  WHERE is_system = true;

-- Updated_at trigger (skip if already exists)
DO $$ BEGIN
  CREATE TRIGGER update_inspection_templates_updated_at
    BEFORE UPDATE ON inspection_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Audit trigger (skip if already exists)
DO $$ BEGIN
  CREATE TRIGGER inspection_templates_audit
    AFTER INSERT OR UPDATE OR DELETE ON inspection_templates
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- RLS — company members see own + system templates
ALTER TABLE inspection_templates ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "templates_select" ON inspection_templates
    FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid OR is_system = true);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "templates_insert" ON inspection_templates
    FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "templates_update" ON inspection_templates
    FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND is_system = false);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "templates_delete" ON inspection_templates
    FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND is_system = false);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- FK: pm_inspections.template_id → inspection_templates
-- ============================================================

DO $$ BEGIN
  ALTER TABLE pm_inspections
    ADD CONSTRAINT fk_pm_inspections_template
    FOREIGN KEY (template_id) REFERENCES inspection_templates(id)
    ON DELETE SET NULL;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- Deficiency count trigger (auto-update pm_inspections.deficiency_count)
-- ============================================================

CREATE OR REPLACE FUNCTION update_inspection_deficiency_count()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE pm_inspections
    SET deficiency_count = (
      SELECT count(*) FROM inspection_deficiencies
      WHERE inspection_id = OLD.inspection_id AND deleted_at IS NULL
    )
    WHERE id = OLD.inspection_id;
    RETURN OLD;
  ELSE
    UPDATE pm_inspections
    SET deficiency_count = (
      SELECT count(*) FROM inspection_deficiencies
      WHERE inspection_id = NEW.inspection_id AND deleted_at IS NULL
    )
    WHERE id = NEW.inspection_id;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_deficiency_count
  AFTER INSERT OR UPDATE OR DELETE ON inspection_deficiencies
  FOR EACH ROW EXECUTE FUNCTION update_inspection_deficiency_count();
