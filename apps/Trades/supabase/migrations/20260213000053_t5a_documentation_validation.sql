-- T5a: Documentation Validation, Certificate of Completion, Documentation Checklists
-- Phase T (Programs/TPA Module) — Sprint T5
-- Pre-submission documentation completeness checking, COC generation

-- ============================================================================
-- TABLE 1: CERTIFICATES OF COMPLETION
-- ============================================================================

CREATE TABLE certificates_of_completion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  -- Scope summary
  scope_summary TEXT NOT NULL,
  work_performed TEXT NOT NULL,
  start_date DATE NOT NULL,
  completion_date DATE NOT NULL,
  -- IICRC drying verification
  all_areas_dry BOOLEAN DEFAULT false,
  final_moisture_readings_verified BOOLEAN DEFAULT false,
  drying_goal_met BOOLEAN DEFAULT false,
  -- Financial
  total_invoiced NUMERIC(12,2),
  total_paid NUMERIC(12,2),
  lien_waiver_signed BOOLEAN DEFAULT false,
  lien_waiver_storage_path TEXT,
  -- Signatures
  technician_signature_path TEXT,
  technician_signed_at TIMESTAMPTZ,
  technician_user_id UUID REFERENCES auth.users(id),
  customer_signature_path TEXT,
  customer_signed_at TIMESTAMPTZ,
  customer_name TEXT,
  customer_email TEXT,
  -- Satisfaction survey
  satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
  satisfaction_feedback TEXT,
  would_recommend BOOLEAN,
  -- PDF
  pdf_storage_path TEXT,
  pdf_generated_at TIMESTAMPTZ,
  -- Status
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_customer', 'signed', 'submitted', 'accepted')),
  submitted_to_tpa_at TIMESTAMPTZ,
  accepted_by_tpa_at TIMESTAMPTZ,
  -- Metadata
  created_by_user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE 2: DOCUMENTATION CHECKLIST TEMPLATES
-- ============================================================================

CREATE TABLE doc_checklist_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID,  -- NULL = system default template
  -- Template identity
  name TEXT NOT NULL,
  description TEXT,
  job_type TEXT NOT NULL CHECK (job_type IN (
    'water_mitigation', 'fire_restoration', 'mold_remediation',
    'roofing_claim', 'general_restoration', 'contents_packout', 'other'
  )),
  -- Structure
  is_system_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE 3: DOCUMENTATION CHECKLIST ITEMS (within a template)
-- ============================================================================

CREATE TABLE doc_checklist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES doc_checklist_templates(id) ON DELETE CASCADE,
  -- Item definition
  phase TEXT NOT NULL CHECK (phase IN (
    'initial_inspection', 'during_work', 'daily_monitoring', 'completion', 'closeout'
  )),
  item_name TEXT NOT NULL,
  description TEXT,
  is_required BOOLEAN DEFAULT true,
  -- Evidence type expected
  evidence_type TEXT NOT NULL DEFAULT 'photo' CHECK (evidence_type IN (
    'photo', 'document', 'signature', 'reading', 'form', 'any'
  )),
  min_count INTEGER DEFAULT 1,  -- minimum number of items required
  -- Ordering
  sort_order INTEGER DEFAULT 0,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- TABLE 4: JOB DOCUMENTATION PROGRESS (per-job tracking against checklist)
-- ============================================================================

CREATE TABLE job_doc_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID NOT NULL REFERENCES jobs(id),
  tpa_assignment_id UUID REFERENCES tpa_assignments(id),
  checklist_item_id UUID NOT NULL REFERENCES doc_checklist_items(id),
  -- Completion tracking
  is_complete BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  completed_by_user_id UUID REFERENCES auth.users(id),
  -- Evidence references (can link to multiple sources)
  evidence_count INTEGER DEFAULT 0,
  evidence_notes TEXT,
  -- Photo phase tagging
  photo_phase TEXT CHECK (photo_phase IN (
    'before', 'during', 'after', 'equipment', 'moisture',
    'source', 'exterior', 'contents', 'pre_existing'
  )),
  -- Storage references (JSON array of paths)
  evidence_paths JSONB DEFAULT '[]'::jsonb,
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE certificates_of_completion ENABLE ROW LEVEL SECURITY;
ALTER TABLE doc_checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE doc_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_doc_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY coc_company ON certificates_of_completion
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Templates: company-owned + system defaults visible to all
CREATE POLICY doc_template_read ON doc_checklist_templates
  FOR SELECT USING (
    company_id IS NULL  -- system defaults
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY doc_template_write ON doc_checklist_templates
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Items inherit template access (no company_id column, cascade through template)
CREATE POLICY doc_items_read ON doc_checklist_items
  FOR SELECT USING (
    template_id IN (
      SELECT id FROM doc_checklist_templates
      WHERE company_id IS NULL
        OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

CREATE POLICY doc_items_write ON doc_checklist_items
  FOR ALL USING (
    template_id IN (
      SELECT id FROM doc_checklist_templates
      WHERE company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    )
  );

CREATE POLICY job_doc_progress_company ON job_doc_progress
  FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX idx_coc_company ON certificates_of_completion(company_id);
CREATE INDEX idx_coc_job ON certificates_of_completion(job_id);
CREATE INDEX idx_coc_tpa ON certificates_of_completion(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_coc_status ON certificates_of_completion(status);

CREATE INDEX idx_doc_template_company ON doc_checklist_templates(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX idx_doc_template_type ON doc_checklist_templates(job_type);
CREATE INDEX idx_doc_template_default ON doc_checklist_templates(is_system_default) WHERE is_system_default = true;

CREATE INDEX idx_doc_items_template ON doc_checklist_items(template_id);
CREATE INDEX idx_doc_items_phase ON doc_checklist_items(template_id, phase);

CREATE INDEX idx_job_doc_company ON job_doc_progress(company_id);
CREATE INDEX idx_job_doc_job ON job_doc_progress(job_id);
CREATE INDEX idx_job_doc_tpa ON job_doc_progress(tpa_assignment_id) WHERE tpa_assignment_id IS NOT NULL;
CREATE INDEX idx_job_doc_item ON job_doc_progress(checklist_item_id);
CREATE INDEX idx_job_doc_complete ON job_doc_progress(job_id, is_complete);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER coc_updated BEFORE UPDATE ON certificates_of_completion FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER doc_template_updated BEFORE UPDATE ON doc_checklist_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER job_doc_progress_updated BEFORE UPDATE ON job_doc_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit
CREATE TRIGGER coc_audit AFTER INSERT OR UPDATE OR DELETE ON certificates_of_completion FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER doc_template_audit AFTER INSERT OR UPDATE OR DELETE ON doc_checklist_templates FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER job_doc_progress_audit AFTER INSERT OR UPDATE OR DELETE ON job_doc_progress FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
