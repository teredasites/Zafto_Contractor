-- Customer Financing — applications, providers, and analytics
-- Tracks financing offers sent to customers and their lifecycle.

-- ── Financing Providers (connected integrations) ──
CREATE TABLE IF NOT EXISTS financing_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  provider_name TEXT NOT NULL,                          -- e.g. 'Wisetack', 'GreenSky', 'Hearth'
  provider_slug TEXT NOT NULL,                          -- lowercase key
  connected BOOLEAN NOT NULL DEFAULT false,
  api_key_configured BOOLEAN NOT NULL DEFAULT false,
  merchant_fee_pct NUMERIC(5,2) DEFAULT 0,
  min_amount NUMERIC(12,2) DEFAULT 500,
  max_amount NUMERIC(12,2) DEFAULT 100000,
  available_terms INTEGER[] DEFAULT '{12,24,36,48,60}', -- months
  settings JSONB DEFAULT '{}',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_financing_providers_company ON financing_providers(company_id) WHERE deleted_at IS NULL;

ALTER TABLE financing_providers ENABLE ROW LEVEL SECURITY;

CREATE POLICY financing_providers_select ON financing_providers FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_providers_insert ON financing_providers FOR INSERT
  WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_providers_update ON financing_providers FOR UPDATE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_providers_delete ON financing_providers FOR DELETE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE TRIGGER set_updated_at_financing_providers BEFORE UPDATE ON financing_providers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Financing Applications ──
CREATE TABLE IF NOT EXISTS financing_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  provider_id UUID REFERENCES financing_providers(id),
  customer_name TEXT NOT NULL,
  job_name TEXT,
  amount NUMERIC(12,2) NOT NULL,
  monthly_payment NUMERIC(10,2),
  term_months INTEGER,
  interest_rate NUMERIC(5,2),
  provider_name TEXT,                                     -- denormalized for display
  status TEXT NOT NULL DEFAULT 'offered' CHECK (status IN ('offered','applied','approved','denied','funded','expired','cancelled')),
  external_application_id TEXT,                           -- provider's reference
  funded_at TIMESTAMPTZ,
  date_applied TIMESTAMPTZ,
  notes TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_financing_applications_company ON financing_applications(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_financing_applications_customer ON financing_applications(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_financing_applications_job ON financing_applications(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_financing_applications_status ON financing_applications(company_id, status) WHERE deleted_at IS NULL;

ALTER TABLE financing_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY financing_applications_select ON financing_applications FOR SELECT
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_applications_insert ON financing_applications FOR INSERT
  WITH CHECK (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_applications_update ON financing_applications FOR UPDATE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);
CREATE POLICY financing_applications_delete ON financing_applications FOR DELETE
  USING (company_id = (auth.jwt()->'app_metadata'->>'company_id')::uuid);

CREATE TRIGGER set_updated_at_financing_applications BEFORE UPDATE ON financing_applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
