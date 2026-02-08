-- F5b: CPA Portal tables
-- Read-only access for accountants to ZBooks data

-- CPA Access Tokens — invite accountants with limited access
CREATE TABLE cpa_access_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  cpa_name TEXT NOT NULL,
  cpa_email TEXT NOT NULL,
  cpa_firm TEXT,
  access_level TEXT NOT NULL DEFAULT 'read_only' CHECK (access_level IN ('read_only','export','full')),
  is_active BOOLEAN DEFAULT true,
  token_hash TEXT NOT NULL,  -- hashed access token for portal login
  permissions JSONB NOT NULL DEFAULT '["gl","pnl","balance_sheet","cash_flow","1099","bank_recon"]'::jsonb,
  last_accessed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_by_user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- CPA Activity Log — audit trail for CPA access
CREATE TABLE cpa_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  cpa_token_id UUID NOT NULL REFERENCES cpa_access_tokens(id),
  action TEXT NOT NULL,  -- viewed_gl, exported_pnl, etc.
  resource_type TEXT,
  resource_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE cpa_access_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE cpa_activity_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY cpa_tokens_company ON cpa_access_tokens FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY cpa_log_company ON cpa_activity_log FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_cpa_tokens_company ON cpa_access_tokens(company_id);
CREATE INDEX idx_cpa_tokens_email ON cpa_access_tokens(cpa_email);
CREATE INDEX idx_cpa_log_token ON cpa_activity_log(cpa_token_id);

-- Triggers
CREATE TRIGGER cpa_tokens_updated BEFORE UPDATE ON cpa_access_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at();
