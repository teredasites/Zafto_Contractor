-- D2 Financial Depth: ACV/RCV/depreciation tracking for insurance claims + supplements
-- Adds payment waterfall columns for real-world insurance money flow

-- Insurance Claims: add depreciation recovery tracking + amount collected
ALTER TABLE insurance_claims
  ADD COLUMN IF NOT EXISTS depreciation_recovered BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS amount_collected NUMERIC(12,2) DEFAULT 0;

-- Claim Supplements: add RCV/ACV/depreciation split per supplement
ALTER TABLE claim_supplements
  ADD COLUMN IF NOT EXISTS rcv_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS acv_amount NUMERIC(12,2),
  ADD COLUMN IF NOT EXISTS depreciation_amount NUMERIC(12,2) DEFAULT 0;
