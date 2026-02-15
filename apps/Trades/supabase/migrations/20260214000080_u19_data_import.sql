-- U19: Data Import / Migration Tools
-- import_batches: track each import operation for history + undo
-- import_errors: per-row error log

CREATE TABLE IF NOT EXISTS import_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  import_type text NOT NULL CHECK (import_type IN ('customers','jobs','invoices','contacts','estimates','vendors','chart_of_accounts')),
  file_name text NOT NULL,
  file_format text NOT NULL DEFAULT 'csv' CHECK (file_format IN ('csv','qbo','iif')),
  column_mapping jsonb NOT NULL DEFAULT '{}',
  total_rows int NOT NULL DEFAULT 0,
  success_count int NOT NULL DEFAULT 0,
  error_count int NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','failed','undone')),
  started_at timestamptz,
  completed_at timestamptz,
  undone_at timestamptz,
  undone_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS import_errors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES import_batches(id) ON DELETE CASCADE,
  row_number int NOT NULL,
  row_data jsonb,
  error_message text NOT NULL,
  field_name text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Add import_batch_id to importable tables for undo support
-- Wrapped in DO blocks for tables that may not exist yet
ALTER TABLE customers ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'contacts' AND table_schema = 'public') THEN
    ALTER TABLE contacts ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);
  END IF;
END $$;
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS import_batch_id uuid REFERENCES import_batches(id);

-- RLS
ALTER TABLE import_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_errors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "import_batches_select" ON import_batches FOR SELECT USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "import_batches_insert" ON import_batches FOR INSERT WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY "import_batches_update" ON import_batches FOR UPDATE USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE POLICY "import_errors_select" ON import_errors FOR SELECT USING (
  batch_id IN (SELECT id FROM import_batches WHERE company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid)
);
CREATE POLICY "import_errors_insert" ON import_errors FOR INSERT WITH CHECK (
  batch_id IN (SELECT id FROM import_batches WHERE company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid)
);

-- Indexes
CREATE INDEX idx_import_batches_company ON import_batches(company_id);
CREATE INDEX idx_import_batches_status ON import_batches(status);
CREATE INDEX idx_import_errors_batch ON import_errors(batch_id);
CREATE INDEX idx_customers_import_batch ON customers(import_batch_id) WHERE import_batch_id IS NOT NULL;
CREATE INDEX idx_jobs_import_batch ON jobs(import_batch_id) WHERE import_batch_id IS NOT NULL;
CREATE INDEX idx_invoices_import_batch ON invoices(import_batch_id) WHERE import_batch_id IS NOT NULL;

-- Triggers
CREATE TRIGGER set_updated_at BEFORE UPDATE ON import_batches FOR EACH ROW EXECUTE FUNCTION update_updated_at();
