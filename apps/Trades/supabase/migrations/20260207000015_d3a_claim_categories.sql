-- D3a: Claim Categories for Insurance Verticals
-- Adds claim_category column to insurance_claims table
-- Categories: restoration (default, water/mold mitigation), storm (weather damage),
-- reconstruction (full rebuild), commercial (business properties)

ALTER TABLE insurance_claims
ADD COLUMN claim_category TEXT NOT NULL DEFAULT 'restoration'
CHECK (claim_category IN ('restoration', 'storm', 'reconstruction', 'commercial'));

-- The JSONB `data` column already exists and stores vertical-specific fields:
-- Storm: { weatherEventDate, stormSeverity, aerialAssessmentNeeded, batchEventId, emergencyTarped, temporaryRepairs }
-- Reconstruction: { currentPhase, phases[], drawSchedule[], multiContractor, expectedDurationMonths, permitsRequired }
-- Commercial: { propertyType, businessName, tenantName, tenantContact, businessIncomeLoss, businessInterruptionDays, emergencyAuthAmount }

-- Index for filtering by category
CREATE INDEX idx_insurance_claims_category ON insurance_claims(claim_category);

-- RLS policies already cover this column (existing row-level policies on insurance_claims)
