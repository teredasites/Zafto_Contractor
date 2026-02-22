-- ============================================================
-- DEPTH39 — Signature System: Project Linking + DocuSign Replacement
-- Enhances existing signatures + zdocs_signature_requests tables.
-- Adds multi-party workflows, full audit trail, document hashing.
-- ============================================================

-- ── Enhance signatures table with additional entity links ──
DO $$
BEGIN
  -- Add bid_id link
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'signatures' AND column_name = 'bid_id') THEN
    ALTER TABLE signatures ADD COLUMN bid_id uuid REFERENCES bids(id);
    CREATE INDEX idx_signatures_bid ON signatures (bid_id) WHERE bid_id IS NOT NULL;
  END IF;

  -- Add change_order_id link
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'signatures' AND column_name = 'change_order_id') THEN
    ALTER TABLE signatures ADD COLUMN change_order_id uuid REFERENCES change_orders(id);
    CREATE INDEX idx_signatures_change_order ON signatures (change_order_id) WHERE change_order_id IS NOT NULL;
  END IF;

  -- Add contract/document reference
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'signatures' AND column_name = 'document_id') THEN
    ALTER TABLE signatures ADD COLUMN document_id uuid REFERENCES documents(id);
    CREATE INDEX idx_signatures_document ON signatures (document_id) WHERE document_id IS NOT NULL;
  END IF;

  -- Add render reference (ties to zdocs_renders)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'signatures' AND column_name = 'render_id') THEN
    ALTER TABLE signatures ADD COLUMN render_id uuid REFERENCES zdocs_renders(id);
    CREATE INDEX idx_signatures_render ON signatures (render_id) WHERE render_id IS NOT NULL;
  END IF;

  -- Add enhanced audit fields
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'signatures' AND column_name = 'device_info') THEN
    ALTER TABLE signatures ADD COLUMN device_info text;
    ALTER TABLE signatures ADD COLUMN user_agent text;
    ALTER TABLE signatures ADD COLUMN geolocation jsonb;
    ALTER TABLE signatures ADD COLUMN document_hash text; -- SHA-256 of signed document
    ALTER TABLE signatures ADD COLUMN signer_email text;
    ALTER TABLE signatures ADD COLUMN deleted_at timestamptz;
    CREATE INDEX idx_signatures_deleted ON signatures (deleted_at) WHERE deleted_at IS NULL;
  END IF;

  -- Add company_id index if missing
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'signatures' AND indexname = 'idx_signatures_company') THEN
    CREATE INDEX idx_signatures_company ON signatures (company_id);
  END IF;

  -- Add job_id index if missing
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'signatures' AND indexname = 'idx_signatures_job') THEN
    CREATE INDEX idx_signatures_job ON signatures (job_id) WHERE job_id IS NOT NULL;
  END IF;
END $$;

-- ── Enhance zdocs_signature_requests with multi-party workflow ──
DO $$
BEGIN
  -- Signing order for sequential signing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'signing_order') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN signing_order int NOT NULL DEFAULT 1;
  END IF;

  -- Geolocation of signer
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'geolocation') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN geolocation jsonb;
  END IF;

  -- Device info
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'device_info') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN device_info text;
  END IF;

  -- Document hash at time of signing (tamper evidence)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'document_hash') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN document_hash text;
  END IF;

  -- Reminder tracking
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'reminder_count') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN reminder_count int NOT NULL DEFAULT 0;
    ALTER TABLE zdocs_signature_requests ADD COLUMN last_reminder_at timestamptz;
  END IF;

  -- Signer phone (for SMS if needed later)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'signer_phone') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN signer_phone text;
  END IF;

  -- Deleted at for soft delete
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'deleted_at') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN deleted_at timestamptz;
  END IF;
END $$;

-- ── signature_audit_events — detailed audit log per signature action ──
CREATE TABLE signature_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- What entity was acted on
  signature_request_id uuid REFERENCES zdocs_signature_requests(id),
  signature_id uuid REFERENCES signatures(id),
  render_id uuid REFERENCES zdocs_renders(id),

  -- Event details
  event_type text NOT NULL CHECK (event_type IN (
    'created', 'sent', 'viewed', 'signed', 'declined', 'expired',
    'reminder_sent', 'downloaded', 'voided', 'resent',
    'document_generated', 'document_hashed'
  )),
  actor_type text NOT NULL DEFAULT 'user' CHECK (actor_type IN ('user', 'system', 'signer')),
  actor_id uuid, -- user id if internal user
  actor_name text,
  actor_email text,

  -- Audit metadata
  ip_address text,
  user_agent text,
  device_info text,
  geolocation jsonb,
  document_hash text,

  -- Extra context
  metadata jsonb DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE signature_audit_events ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_sig_audit_company ON signature_audit_events (company_id);
CREATE INDEX idx_sig_audit_request ON signature_audit_events (signature_request_id) WHERE signature_request_id IS NOT NULL;
CREATE INDEX idx_sig_audit_signature ON signature_audit_events (signature_id) WHERE signature_id IS NOT NULL;
CREATE INDEX idx_sig_audit_render ON signature_audit_events (render_id) WHERE render_id IS NOT NULL;
CREATE INDEX idx_sig_audit_type ON signature_audit_events (event_type);
CREATE INDEX idx_sig_audit_created ON signature_audit_events (created_at DESC);

CREATE TRIGGER sig_audit_events_audit
  AFTER INSERT OR UPDATE OR DELETE ON signature_audit_events
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "sig_audit_select" ON signature_audit_events
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "sig_audit_insert" ON signature_audit_events
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

-- ── signing_workflows — define multi-party signing rules ──
CREATE TABLE signing_workflows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  render_id uuid NOT NULL REFERENCES zdocs_renders(id) ON DELETE CASCADE,

  -- Workflow config
  name text NOT NULL,
  signing_mode text NOT NULL DEFAULT 'sequential'
    CHECK (signing_mode IN ('sequential', 'parallel', 'any_one')),
  -- sequential = signer 1 must finish before signer 2 starts
  -- parallel = all signers can sign simultaneously
  -- any_one = first signer completes the workflow

  -- Status
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'completed', 'voided', 'expired')),
  completed_at timestamptz,
  voided_at timestamptz,
  voided_by uuid REFERENCES auth.users(id),
  voided_reason text,

  -- Expiry
  expires_at timestamptz DEFAULT (now() + interval '30 days'),

  -- Notification preferences
  send_reminders boolean NOT NULL DEFAULT true,
  reminder_interval_hours int NOT NULL DEFAULT 48,
  max_reminders int NOT NULL DEFAULT 3,

  -- Completion action
  on_complete_notify jsonb DEFAULT '[]'::jsonb, -- [{email, name}] to notify when all signed
  on_complete_webhook text, -- optional webhook URL

  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE signing_workflows ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_signing_wf_company ON signing_workflows (company_id);
CREATE INDEX idx_signing_wf_render ON signing_workflows (render_id);
CREATE INDEX idx_signing_wf_status ON signing_workflows (status);
CREATE INDEX idx_signing_wf_deleted ON signing_workflows (deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER signing_workflows_updated
  BEFORE UPDATE ON signing_workflows
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER signing_workflows_audit
  AFTER INSERT OR UPDATE OR DELETE ON signing_workflows
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "signing_wf_select" ON signing_workflows
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "signing_wf_insert" ON signing_workflows
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "signing_wf_update" ON signing_workflows
  FOR UPDATE USING (company_id = requesting_company_id());

-- ── Add workflow_id to zdocs_signature_requests ──
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_signature_requests' AND column_name = 'workflow_id') THEN
    ALTER TABLE zdocs_signature_requests ADD COLUMN workflow_id uuid REFERENCES signing_workflows(id);
    CREATE INDEX idx_zdocs_sigs_workflow ON zdocs_signature_requests (workflow_id) WHERE workflow_id IS NOT NULL;
  END IF;
END $$;

-- ── Enhance zdocs_renders with signature field positions ──
DO $$
BEGIN
  -- Signature field placement data (for drag-and-drop signature fields on rendered document)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_renders' AND column_name = 'signature_fields') THEN
    ALTER TABLE zdocs_renders ADD COLUMN signature_fields jsonb DEFAULT '[]'::jsonb;
    -- [{id, type: 'signature'|'initials'|'date'|'text', page, x, y, width, height, assignedTo: signerEmail, required: true}]
  END IF;

  -- Document hash for tamper evidence
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_renders' AND column_name = 'document_hash') THEN
    ALTER TABLE zdocs_renders ADD COLUMN document_hash text;
  END IF;

  -- Signed PDF path (separate from unsigned)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_renders' AND column_name = 'signed_pdf_storage_path') THEN
    ALTER TABLE zdocs_renders ADD COLUMN signed_pdf_storage_path text;
  END IF;

  -- Certificate of completion
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'zdocs_renders' AND column_name = 'certificate_html') THEN
    ALTER TABLE zdocs_renders ADD COLUMN certificate_html text;
  END IF;
END $$;
