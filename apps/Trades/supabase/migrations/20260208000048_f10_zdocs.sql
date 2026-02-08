-- F10: ZDocs — PDF-first document suite
-- Render tracking, template sections, and signature requests

-- ZDocs Renders — tracks each generated document from a template
CREATE TABLE zdocs_renders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  template_id UUID NOT NULL REFERENCES document_templates(id),
  -- What entity this was rendered for
  entity_type TEXT NOT NULL CHECK (entity_type IN (
    'job','customer','estimate','invoice','bid','change_order',
    'property','lease','claim','general'
  )),
  entity_id UUID,
  -- Render output
  title TEXT NOT NULL,
  rendered_html TEXT,  -- final HTML after variable substitution
  pdf_storage_path TEXT,  -- Supabase Storage path to generated PDF
  pdf_size_bytes BIGINT,
  -- Data snapshot (all CRM data used to fill template, for audit)
  data_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  variables_used JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft','rendered','signed','sent','archived')),
  -- Signature
  requires_signature BOOLEAN DEFAULT false,
  signature_status TEXT CHECK (signature_status IN ('pending','sent','viewed','signed','declined','expired')),
  signature_requested_at TIMESTAMPTZ,
  signed_at TIMESTAMPTZ,
  signed_by_name TEXT,
  signed_by_email TEXT,
  signature_ip TEXT,
  signature_image_path TEXT,  -- Storage path to signature image
  -- Delivery
  sent_to_email TEXT,
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  downloaded_at TIMESTAMPTZ,
  -- Metadata
  rendered_by_user_id UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ZDocs Template Sections — structured sections within a template for drag-and-drop editing
CREATE TABLE zdocs_template_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES document_templates(id) ON DELETE CASCADE,
  section_type TEXT NOT NULL CHECK (section_type IN (
    'header','paragraph','table','signature_block','line_items',
    'terms','scope','images','page_break','divider','custom_html'
  )),
  title TEXT,
  content_html TEXT,  -- section-level HTML
  config JSONB NOT NULL DEFAULT '{}'::jsonb,  -- section-specific config (table columns, image sizes, etc.)
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_required BOOLEAN DEFAULT false,
  is_conditional BOOLEAN DEFAULT false,
  condition_field TEXT,  -- variable name that controls visibility
  condition_value TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ZDocs Signature Requests — manage signature collection
CREATE TABLE zdocs_signature_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  render_id UUID NOT NULL REFERENCES zdocs_renders(id) ON DELETE CASCADE,
  -- Signer info
  signer_name TEXT NOT NULL,
  signer_email TEXT NOT NULL,
  signer_role TEXT DEFAULT 'signer' CHECK (signer_role IN ('signer','approver','cc')),
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','sent','viewed','signed','declined','expired')),
  sent_at TIMESTAMPTZ,
  viewed_at TIMESTAMPTZ,
  signed_at TIMESTAMPTZ,
  declined_at TIMESTAMPTZ,
  decline_reason TEXT,
  -- Token for public signing link
  access_token UUID DEFAULT gen_random_uuid(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '30 days'),
  -- Signature data
  signature_image_path TEXT,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE zdocs_renders ENABLE ROW LEVEL SECURITY;
ALTER TABLE zdocs_template_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE zdocs_signature_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY zdocs_renders_company ON zdocs_renders FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
-- Template sections: accessible if you can access the template (join through document_templates)
CREATE POLICY zdocs_sections_via_template ON zdocs_template_sections FOR ALL USING (
  EXISTS (SELECT 1 FROM document_templates dt WHERE dt.id = template_id AND dt.company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid)
);
CREATE POLICY zdocs_sigs_company ON zdocs_signature_requests FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_zdocs_renders_company ON zdocs_renders(company_id);
CREATE INDEX idx_zdocs_renders_template ON zdocs_renders(template_id);
CREATE INDEX idx_zdocs_renders_entity ON zdocs_renders(entity_type, entity_id) WHERE entity_id IS NOT NULL;
CREATE INDEX idx_zdocs_renders_status ON zdocs_renders(status);
CREATE INDEX idx_zdocs_sections_template ON zdocs_template_sections(template_id);
CREATE INDEX idx_zdocs_sections_sort ON zdocs_template_sections(template_id, sort_order);
CREATE INDEX idx_zdocs_sigs_render ON zdocs_signature_requests(render_id);
CREATE INDEX idx_zdocs_sigs_token ON zdocs_signature_requests(access_token);
CREATE INDEX idx_zdocs_sigs_status ON zdocs_signature_requests(status);

-- Triggers
CREATE TRIGGER zdocs_renders_updated BEFORE UPDATE ON zdocs_renders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER zdocs_sections_updated BEFORE UPDATE ON zdocs_template_sections FOR EACH ROW EXECUTE FUNCTION update_updated_at();
