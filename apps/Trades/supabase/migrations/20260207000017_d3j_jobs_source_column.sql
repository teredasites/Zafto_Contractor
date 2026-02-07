-- D3j: Add source column to jobs table for lead source tracking
-- Tracks how job/lead was acquired (canvass, referral, website, etc.)
-- Canvass-specific metadata (canvasser_id, doors_knocked) goes in type_metadata JSONB

ALTER TABLE jobs ADD COLUMN IF NOT EXISTS source text DEFAULT 'direct'
  CHECK (source IN ('direct', 'referral', 'canvass', 'website', 'social_media', 'phone', 'email', 'home_show', 'other'));

CREATE INDEX IF NOT EXISTS idx_jobs_source ON jobs (company_id, source);
