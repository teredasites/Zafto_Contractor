-- E5i: Crowd-Sourced Pricing Pipeline
-- Invoice finalization trigger → anonymized pricing contributions

-- Function: extract pricing contributions from finalized estimate lines
CREATE OR REPLACE FUNCTION fn_extract_pricing_contributions()
RETURNS trigger AS $$
DECLARE
  v_claim_id uuid;
  v_zip_code text;
  v_region_code text;
BEGIN
  -- Only trigger on status change to 'paid' or 'finalized'
  IF NEW.status NOT IN ('paid', 'finalized') THEN
    RETURN NEW;
  END IF;
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get claim_id from the invoice's job
  SELECT ic.id INTO v_claim_id
  FROM insurance_claims ic
  JOIN jobs j ON j.id = NEW.job_id
  WHERE ic.job_id = j.id
  LIMIT 1;

  IF v_claim_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get ZIP code from claim's property address for region
  SELECT
    COALESCE(ic.property_zip, '') INTO v_zip_code
  FROM insurance_claims ic
  WHERE ic.id = v_claim_id;

  -- Map ZIP to region code (simplified: first 3 digits of ZIP)
  v_region_code := CASE
    WHEN LENGTH(v_zip_code) >= 3 THEN 'US-' || LEFT(v_zip_code, 3)
    ELSE 'US-UNK'
  END;

  -- Insert anonymized pricing contributions from estimate lines
  -- Strips all PII: no company_id, no claim_id, no customer info
  INSERT INTO pricing_contributions (code_id, region_code, material_cost, labor_cost, equipment_cost)
  SELECT
    xel.code_id,
    v_region_code,
    xel.material_cost,
    xel.labor_cost,
    xel.equipment_cost
  FROM xactimate_estimate_lines xel
  WHERE xel.claim_id = v_claim_id
    AND xel.code_id IS NOT NULL
    AND xel.total > 0;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on invoices table when status changes to paid/finalized
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_extract_pricing_contributions'
  ) THEN
    CREATE TRIGGER trg_extract_pricing_contributions
      AFTER UPDATE ON invoices
      FOR EACH ROW
      EXECUTE FUNCTION fn_extract_pricing_contributions();
  END IF;
END $$;

-- Add property_zip column to insurance_claims if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'insurance_claims' AND column_name = 'property_zip'
  ) THEN
    ALTER TABLE insurance_claims ADD COLUMN property_zip text;
  END IF;
END $$;

-- Index for pricing contributions queries
CREATE INDEX IF NOT EXISTS idx_pricing_contributions_code_region
  ON pricing_contributions (code_id, region_code);

-- Pricing coverage view for admin dashboard
CREATE OR REPLACE VIEW v_pricing_coverage AS
SELECT
  xc.category_code,
  xc.category_name,
  pe.region_code,
  COUNT(pe.id) AS entry_count,
  AVG(pe.total_cost) AS avg_price,
  MIN(pe.confidence) AS min_confidence,
  MAX(pe.source_count) AS max_sources,
  MAX(pe.effective_date) AS last_updated
FROM xactimate_codes xc
LEFT JOIN pricing_entries pe ON pe.code_id = xc.id AND pe.company_id IS NULL
WHERE xc.deprecated = false
GROUP BY xc.category_code, xc.category_name, pe.region_code
ORDER BY xc.category_code, pe.region_code;
