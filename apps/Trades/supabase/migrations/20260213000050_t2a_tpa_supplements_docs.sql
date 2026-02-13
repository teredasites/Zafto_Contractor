-- T2a: TPA Supplements + Documentation Tables
-- Phase T (Programs/TPA Module) — Sprint T2
-- Supplement tracking, documentation requirements, photo compliance

-- ============================================================================
-- TABLES
-- ============================================================================

-- TPA Supplements — tracks supplement requests (S1, S2, S3...) per assignment
CREATE TABLE tpa_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_assignment_id UUID NOT NULL REFERENCES tpa_assignments(id),
  created_by_user_id UUID REFERENCES auth.users(id),
  -- Supplement identity
  supplement_number INTEGER NOT NULL,  -- S1, S2, S3...
  title TEXT NOT NULL,
  description TEXT,
  -- Reason for supplement
  reason TEXT NOT NULL CHECK (reason IN (
    'hidden_damage','scope_change','category_escalation',
    'additional_areas','code_upgrade','emergency_services',
    'contents','additional_equipment','extended_drying',
    'mold_discovered','structural','other'
  )),
  reason_detail TEXT,  -- free-form elaboration
  -- Financial
  original_amount NUMERIC(12,2) DEFAULT 0,  -- amount before supplement
  supplement_amount NUMERIC(12,2) DEFAULT 0,  -- requested additional amount
  approved_amount NUMERIC(12,2),  -- what was approved
  -- Status workflow
  status TEXT DEFAULT 'draft' CHECK (status IN (
    'draft','submitted','under_review',
    'approved','partially_approved','denied',
    'resubmitted','withdrawn'
  )),
  submitted_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  reviewer_name TEXT,
  reviewer_notes TEXT,
  denial_reason TEXT,
  -- Supporting documentation
  photo_ids UUID[] DEFAULT '{}',  -- references to photos/storage
  line_item_ids UUID[] DEFAULT '{}',  -- references to estimate_line_items
  supporting_docs JSONB DEFAULT '[]'::jsonb,  -- [{name, path, type}]
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- TPA Documentation Requirements — configurable checklists per TPA program
CREATE TABLE tpa_doc_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_program_id UUID NOT NULL REFERENCES tpa_programs(id),
  -- Requirement details
  name TEXT NOT NULL,  -- e.g., "Source photo", "Affected area overview"
  description TEXT,
  -- Categorization
  phase TEXT NOT NULL CHECK (phase IN (
    'initial_inspection','during_work','daily_monitoring',
    'completion','closeout','equipment','contents'
  )),
  category TEXT DEFAULT 'photo' CHECK (category IN (
    'photo','form','signature','measurement','report','certificate','other'
  )),
  -- Requirements
  is_required BOOLEAN DEFAULT true,
  quantity_required INTEGER DEFAULT 1,  -- e.g., "minimum 4 before photos"
  -- Loss type applicability (empty = all loss types)
  applicable_loss_types TEXT[] DEFAULT '{}',
  -- Ordering
  sort_order INTEGER DEFAULT 0,
  -- Status
  is_active BOOLEAN DEFAULT true,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- TPA Photo Compliance — links photos to documentation requirements
CREATE TABLE tpa_photo_compliance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  tpa_assignment_id UUID NOT NULL REFERENCES tpa_assignments(id),
  doc_requirement_id UUID REFERENCES tpa_doc_requirements(id),
  -- Photo reference
  photo_storage_path TEXT NOT NULL,  -- Supabase Storage path
  thumbnail_path TEXT,
  -- Phase tagging
  phase_tag TEXT NOT NULL CHECK (phase_tag IN (
    'before','during','after','equipment','moisture',
    'source','exterior','contents','pre_existing',
    'thermal','closeout','other'
  )),
  -- Context
  room_name TEXT,  -- e.g., "Kitchen", "Master Bathroom"
  description TEXT,
  -- Location on floor plan (optional, for SK integration later)
  floor_plan_x NUMERIC(8,2),
  floor_plan_y NUMERIC(8,2),
  -- Uploader
  uploaded_by_user_id UUID REFERENCES auth.users(id),
  -- Metadata
  taken_at TIMESTAMPTZ,  -- photo EXIF timestamp if available
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE tpa_supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpa_doc_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE tpa_photo_compliance ENABLE ROW LEVEL SECURITY;

CREATE POLICY tpa_supplements_company ON tpa_supplements
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY tpa_doc_requirements_company ON tpa_doc_requirements
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY tpa_photo_compliance_company ON tpa_photo_compliance
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- tpa_supplements
CREATE INDEX idx_tpa_supplements_company ON tpa_supplements(company_id);
CREATE INDEX idx_tpa_supplements_assignment ON tpa_supplements(tpa_assignment_id);
CREATE INDEX idx_tpa_supplements_status ON tpa_supplements(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_tpa_supplements_number ON tpa_supplements(tpa_assignment_id, supplement_number);

-- tpa_doc_requirements
CREATE INDEX idx_tpa_doc_req_company ON tpa_doc_requirements(company_id);
CREATE INDEX idx_tpa_doc_req_program ON tpa_doc_requirements(tpa_program_id);
CREATE INDEX idx_tpa_doc_req_phase ON tpa_doc_requirements(phase) WHERE is_active = true;

-- tpa_photo_compliance
CREATE INDEX idx_tpa_photos_company ON tpa_photo_compliance(company_id);
CREATE INDEX idx_tpa_photos_assignment ON tpa_photo_compliance(tpa_assignment_id);
CREATE INDEX idx_tpa_photos_requirement ON tpa_photo_compliance(doc_requirement_id) WHERE doc_requirement_id IS NOT NULL;
CREATE INDEX idx_tpa_photos_phase ON tpa_photo_compliance(phase_tag);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER tpa_supplements_updated BEFORE UPDATE ON tpa_supplements FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER tpa_doc_requirements_updated BEFORE UPDATE ON tpa_doc_requirements FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trail
CREATE TRIGGER tpa_supplements_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_supplements FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tpa_doc_requirements_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_doc_requirements FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tpa_photo_compliance_audit AFTER INSERT OR UPDATE OR DELETE ON tpa_photo_compliance FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
