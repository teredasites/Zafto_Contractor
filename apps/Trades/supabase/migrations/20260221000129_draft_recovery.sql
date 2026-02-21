-- DEPTH27: Bulletproof Crash Recovery & Zero-Loss Auto-Save System
-- draft_recovery table — cloud layer for cross-device state recovery

CREATE TABLE IF NOT EXISTS draft_recovery (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id      uuid NOT NULL REFERENCES companies(id),
  user_id         uuid NOT NULL REFERENCES auth.users(id),
  feature         text NOT NULL CHECK (feature IN (
    'sketch','bid','invoice','estimate','walkthrough','inspection',
    'form','settings','calendar','ledger','customer','job','property'
  )),
  screen_route    text NOT NULL,
  state_json      jsonb NOT NULL DEFAULT '{}',
  state_size_bytes integer NOT NULL DEFAULT 0,
  device_id       text NOT NULL DEFAULT '',
  device_type     text NOT NULL CHECK (device_type IN ('web','ios','android')) DEFAULT 'web',
  app_version     text NOT NULL DEFAULT '1.0.0',
  version         integer NOT NULL DEFAULT 1,
  is_active       boolean NOT NULL DEFAULT true,
  is_pinned       boolean NOT NULL DEFAULT false,
  checksum        text NOT NULL DEFAULT '',
  recovered_at    timestamptz,
  expired_at      timestamptz,
  deleted_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_draft_recovery_company ON draft_recovery(company_id);
CREATE INDEX idx_draft_recovery_user ON draft_recovery(user_id);
CREATE INDEX idx_draft_recovery_user_feature ON draft_recovery(user_id, feature) WHERE deleted_at IS NULL AND is_active = true;
CREATE INDEX idx_draft_recovery_device ON draft_recovery(user_id, device_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_draft_recovery_expired ON draft_recovery(expired_at) WHERE expired_at IS NOT NULL AND deleted_at IS NULL;

-- Updated_at trigger
CREATE TRIGGER update_draft_recovery_updated_at
  BEFORE UPDATE ON draft_recovery
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trigger
CREATE TRIGGER audit_draft_recovery
  AFTER INSERT OR UPDATE OR DELETE ON draft_recovery
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- RLS
ALTER TABLE draft_recovery ENABLE ROW LEVEL SECURITY;

-- Users can see their own drafts
CREATE POLICY "draft_recovery_select_own" ON draft_recovery
  FOR SELECT USING (
    user_id = auth.uid()
    AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

-- Owners/admins can see all company drafts (for support/recovery)
CREATE POLICY "draft_recovery_select_admin" ON draft_recovery
  FOR SELECT USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin', 'super_admin')
    AND deleted_at IS NULL
  );

-- Users can insert their own drafts
CREATE POLICY "draft_recovery_insert_own" ON draft_recovery
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- Users can update their own drafts
CREATE POLICY "draft_recovery_update_own" ON draft_recovery
  FOR UPDATE USING (
    user_id = auth.uid()
    AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

-- Users can soft-delete their own drafts
CREATE POLICY "draft_recovery_delete_own" ON draft_recovery
  FOR DELETE USING (
    user_id = auth.uid()
    AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- Comment
COMMENT ON TABLE draft_recovery IS 'DEPTH27: Cloud-synced draft recovery for cross-device crash protection. 4-layer persistence: memory → IndexedDB/Hive → Supabase → Storage snapshots.';
