-- LEGAL-3: Data freshness infrastructure + system settings
-- S143: Legal defense process layer

-- ============================================================
-- system_settings — Platform-level configuration (NOT per-company)
-- Only super_admin can read/write. Stores data freshness timestamps,
-- feature toggles, and other platform-wide config.
-- ============================================================
CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER system_settings_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER system_settings_audit AFTER INSERT OR UPDATE OR DELETE ON system_settings FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Super admin only
CREATE POLICY "system_settings_select" ON system_settings FOR SELECT USING (
  requesting_user_role() = 'super_admin'
);
CREATE POLICY "system_settings_modify" ON system_settings FOR ALL USING (
  requesting_user_role() = 'super_admin'
);

-- Also allow authenticated users to read data_freshness specifically
-- (so disclaimers can show "as of [date]" on any portal)
CREATE POLICY "system_settings_public_freshness" ON system_settings FOR SELECT USING (
  key = 'data_freshness'
);

-- ============================================================
-- Seed data_freshness tracking
-- ============================================================
INSERT INTO system_settings (key, value, description) VALUES
('data_freshness', '{
  "nec_codes": "2025-12-01",
  "ibc_codes": "2025-12-01",
  "irc_codes": "2025-12-01",
  "osha_standards": "2026-01-01",
  "nfpa_codes": "2025-12-01",
  "bls_labor_rates": "2026-01-15",
  "material_pricing": "2026-02-01",
  "google_solar_api": "2026-02-01",
  "public_records": "2026-01-01",
  "weather_data": "2026-02-19",
  "iicrc_standards": "2025-06-01",
  "tax_tables": "2026-01-01",
  "state_licensing": "2025-12-01"
}'::jsonb, 'Tracks when each data source was last updated. Used by disclaimers to show "as of [date]".');

-- ============================================================
-- Add legal_acknowledged to companies.settings pattern
-- (No migration needed — just a convention for the JSONB field)
-- companies.settings.legal_acknowledged = true after first-time setup
-- ============================================================
