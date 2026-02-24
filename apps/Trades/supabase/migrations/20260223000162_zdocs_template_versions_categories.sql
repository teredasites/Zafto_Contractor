-- ZDocs Template Engine: versions, expanded categories, sharing
-- Phase 4A: CRM-CONTRACTOR-FULL-DEPTH OVERHAUL

-- 1) Expand template_type CHECK constraint to include new categories
ALTER TABLE document_templates DROP CONSTRAINT IF EXISTS document_templates_template_type_check;
ALTER TABLE document_templates ADD CONSTRAINT document_templates_template_type_check
  CHECK (template_type IN (
    'contract','proposal','lien_waiver','change_order','invoice',
    'warranty','scope_of_work','safety_plan','daily_report',
    'inspection_report','completion_cert','notice','insurance',
    'letter','property_preservation','permit','compliance','other'
  ));

-- 2) Add sharing column (company-wide vs personal)
ALTER TABLE document_templates ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT true;
-- is_shared=true: all company users can see/use. is_shared=false: only creator can see.
ALTER TABLE document_templates ADD COLUMN IF NOT EXISTS created_by_user_id UUID REFERENCES auth.users(id);
-- Category tag for additional organization beyond template_type
ALTER TABLE document_templates ADD COLUMN IF NOT EXISTS category_tag TEXT;
-- Version tracking
ALTER TABLE document_templates ADD COLUMN IF NOT EXISTS current_version INTEGER DEFAULT 1;

-- 3) Template versions table — tracks content history
CREATE TABLE IF NOT EXISTS document_template_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL DEFAULT 1,
  content_html TEXT,
  variables JSONB NOT NULL DEFAULT '[]'::jsonb,
  change_note TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(template_id, version_number)
);

-- RLS
ALTER TABLE document_template_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY doc_template_versions_via_template ON document_template_versions FOR ALL USING (
  EXISTS (SELECT 1 FROM document_templates dt WHERE dt.id = template_id AND dt.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_doc_template_versions_template ON document_template_versions(template_id);
CREATE INDEX IF NOT EXISTS idx_doc_template_versions_number ON document_template_versions(template_id, version_number);
CREATE INDEX IF NOT EXISTS idx_doc_templates_shared ON document_templates(company_id, is_shared);
CREATE INDEX IF NOT EXISTS idx_doc_templates_type ON document_templates(company_id, template_type);
CREATE INDEX IF NOT EXISTS idx_doc_templates_created_by ON document_templates(created_by_user_id) WHERE created_by_user_id IS NOT NULL;

-- Trigger
CREATE TRIGGER doc_template_versions_audit BEFORE UPDATE ON document_template_versions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
