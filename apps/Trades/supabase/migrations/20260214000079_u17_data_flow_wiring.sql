-- ============================================================
-- U17: Data Flow Wiring — lead_id FK, auto-job triggers
-- ============================================================

-- Add lead_id to estimates, bids, and jobs for full attribution
ALTER TABLE estimates ADD COLUMN IF NOT EXISTS lead_id UUID REFERENCES leads(id);
ALTER TABLE bids ADD COLUMN IF NOT EXISTS lead_id UUID REFERENCES leads(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS lead_id UUID REFERENCES leads(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS estimate_id UUID REFERENCES estimates(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS source TEXT;

-- Index for attribution queries
CREATE INDEX IF NOT EXISTS idx_estimates_lead_id ON estimates (lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bids_lead_id ON bids (lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_lead_id ON jobs (lead_id) WHERE lead_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_jobs_estimate_id ON jobs (estimate_id) WHERE estimate_id IS NOT NULL;

-- Add converted_to_customer_id on leads for customer conversion tracking
ALTER TABLE leads ADD COLUMN IF NOT EXISTS converted_to_customer_id UUID REFERENCES customers(id);
