-- E1a: Z Intelligence tables (z_threads + z_artifacts)
-- Phase E: AI Layer — Universal AI Architecture

-- Z Intelligence threads (replaces localStorage persistence)
CREATE TABLE z_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL DEFAULT 'New conversation',
  page_context TEXT, -- pathname where thread was started
  messages JSONB NOT NULL DEFAULT '[]'::jsonb, -- ZMessage[]
  artifact_id UUID, -- FK to z_artifacts if thread has active artifact
  token_count INTEGER DEFAULT 0, -- total tokens used in this thread
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ -- soft delete
);

-- Z Intelligence artifacts (bids, invoices, reports, etc.)
CREATE TABLE z_artifacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  thread_id UUID REFERENCES z_threads(id),
  type TEXT NOT NULL CHECK (type IN ('bid','invoice','report','job_summary','email','change_order','scope','generic')),
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '', -- markdown
  data JSONB NOT NULL DEFAULT '{}'::jsonb, -- structured fields (customer, options, totals, etc.)
  versions JSONB NOT NULL DEFAULT '[]'::jsonb, -- ZArtifactVersion[]
  current_version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'generating' CHECK (status IN ('generating','ready','approved','rejected','draft')),
  -- Approval tracking
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMPTZ,
  -- Source tracking (what data was used to generate)
  source_job_id UUID REFERENCES jobs(id),
  source_customer_id UUID REFERENCES customers(id),
  source_bid_id UUID REFERENCES bids(id),
  source_invoice_id UUID REFERENCES invoices(id),
  -- Conversion tracking (artifact → real record)
  converted_to_bid_id UUID REFERENCES bids(id),
  converted_to_invoice_id UUID REFERENCES invoices(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- Add FK from z_threads.artifact_id to z_artifacts (deferred to avoid circular dependency)
ALTER TABLE z_threads ADD CONSTRAINT z_threads_artifact_fk FOREIGN KEY (artifact_id) REFERENCES z_artifacts(id);

-- RLS: company-scoped
ALTER TABLE z_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE z_artifacts ENABLE ROW LEVEL SECURITY;
CREATE POLICY z_threads_company ON z_threads USING (company_id = requesting_company_id());
CREATE POLICY z_artifacts_company ON z_artifacts USING (company_id = requesting_company_id());

-- Indexes
CREATE INDEX idx_z_threads_user ON z_threads(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_threads_company ON z_threads(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_artifacts_thread ON z_artifacts(thread_id);
CREATE INDEX idx_z_artifacts_company ON z_artifacts(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_z_artifacts_status ON z_artifacts(status) WHERE deleted_at IS NULL;

-- Audit triggers
CREATE TRIGGER z_threads_updated BEFORE UPDATE ON z_threads FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER z_artifacts_updated BEFORE UPDATE ON z_artifacts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
