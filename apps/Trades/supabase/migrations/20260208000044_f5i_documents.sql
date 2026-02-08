-- F5i: Document Management tables
-- File storage, templates, e-signatures, version history

-- Document Folders
CREATE TABLE document_folders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  parent_id UUID REFERENCES document_folders(id),
  name TEXT NOT NULL,
  path TEXT NOT NULL,  -- full path like "/contracts/2026"
  folder_type TEXT DEFAULT 'custom' CHECK (folder_type IN ('system','job','customer','property','custom')),
  related_type TEXT,  -- 'job', 'customer', 'property'
  related_id UUID,
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Documents
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  folder_id UUID REFERENCES document_folders(id),
  -- File info
  name TEXT NOT NULL,
  file_type TEXT NOT NULL,  -- 'pdf', 'docx', 'xlsx', 'image', etc.
  mime_type TEXT,
  file_size_bytes BIGINT DEFAULT 0,
  storage_path TEXT NOT NULL,  -- Supabase Storage path
  -- Metadata
  document_type TEXT DEFAULT 'general' CHECK (document_type IN (
    'general','contract','proposal','lien_waiver','permit','insurance_cert',
    'change_order','invoice','receipt','photo','plan','specification',
    'warranty','license','certificate','report','other'
  )),
  -- Associations
  job_id UUID REFERENCES jobs(id),
  customer_id UUID,
  property_id UUID,
  -- Version control
  version INTEGER DEFAULT 1,
  parent_document_id UUID REFERENCES documents(id),  -- links to previous version
  is_latest BOOLEAN DEFAULT true,
  -- Status
  status TEXT DEFAULT 'active' CHECK (status IN ('active','archived','deleted')),
  -- E-signature
  requires_signature BOOLEAN DEFAULT false,
  signature_status TEXT CHECK (signature_status IN ('pending','sent','signed','declined','expired')),
  signed_at TIMESTAMPTZ,
  signed_by TEXT,
  signature_path TEXT,
  docusign_envelope_id TEXT,
  -- Metadata
  tags TEXT[] DEFAULT '{}',
  description TEXT,
  uploaded_by_user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Document Templates — reusable document templates
CREATE TABLE document_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  description TEXT,
  template_type TEXT NOT NULL CHECK (template_type IN (
    'contract','proposal','lien_waiver','change_order','invoice',
    'warranty','scope_of_work','safety_plan','daily_report','other'
  )),
  -- Content
  content_html TEXT,  -- rich text template
  storage_path TEXT,  -- for file-based templates (docx, etc.)
  -- Variables
  variables JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{name, label, type, default_value}]
  -- Settings
  is_active BOOLEAN DEFAULT true,
  is_system BOOLEAN DEFAULT false,  -- system-provided templates
  requires_signature BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Document Access Log — audit trail
CREATE TABLE document_access_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL CHECK (action IN ('viewed','downloaded','printed','shared','signed','edited','deleted','restored')),
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE document_folders ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_access_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY doc_folders_company ON document_folders FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY documents_company ON documents FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY doc_templates_company ON document_templates FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY doc_access_company ON document_access_log FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_doc_folders_company ON document_folders(company_id);
CREATE INDEX idx_doc_folders_parent ON document_folders(parent_id);
CREATE INDEX idx_documents_company ON documents(company_id);
CREATE INDEX idx_documents_folder ON documents(folder_id);
CREATE INDEX idx_documents_job ON documents(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX idx_documents_type ON documents(document_type);
CREATE INDEX idx_documents_version ON documents(parent_document_id) WHERE parent_document_id IS NOT NULL;
CREATE INDEX idx_doc_templates_company ON document_templates(company_id);
CREATE INDEX idx_doc_access_document ON document_access_log(document_id);

-- Triggers
CREATE TRIGGER doc_folders_updated BEFORE UPDATE ON document_folders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER documents_updated BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER doc_templates_updated BEFORE UPDATE ON document_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at();
