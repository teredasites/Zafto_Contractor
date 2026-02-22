-- INS9: Add code_refs column to pm_inspection_items
-- Stores building code references (NEC, IRC, IBC, OSHA, NFPA) attached to inspection items.
-- JSONB array of strings, e.g. ["NEC 210.12", "IRC R314.3"]

ALTER TABLE pm_inspection_items
  ADD COLUMN IF NOT EXISTS code_refs jsonb DEFAULT '[]'::jsonb;

-- Index for queries filtering by code reference
CREATE INDEX IF NOT EXISTS idx_pm_inspection_items_code_refs
  ON pm_inspection_items USING gin (code_refs);
