-- ============================================================
-- U17: Data Flow Triggers — automated downstream propagation
-- ============================================================

-- 1. Estimate Approved → Auto-Create Job
-- When an estimate is approved, automatically create a job linked to it.
CREATE OR REPLACE FUNCTION fn_auto_create_job_from_estimate()
RETURNS TRIGGER AS $$
DECLARE
  new_job_id UUID;
  est_title TEXT;
  est_customer_id UUID;
  est_customer_name TEXT;
  est_property_id UUID;
  est_total NUMERIC;
  est_company_id UUID;
  est_lead_id UUID;
BEGIN
  -- Only fire when status changes TO approved
  IF NEW.status != 'approved' OR OLD.status = 'approved' THEN
    RETURN NEW;
  END IF;

  -- Check if a job already exists for this estimate
  IF EXISTS (SELECT 1 FROM jobs WHERE estimate_id = NEW.id AND deleted_at IS NULL) THEN
    RETURN NEW;
  END IF;

  est_title := COALESCE(NEW.title, 'Untitled Job');
  est_customer_id := NEW.customer_id;
  est_property_id := NEW.property_id;
  est_total := COALESCE(NEW.grand_total, 0);
  est_company_id := NEW.company_id;
  est_lead_id := NEW.lead_id;

  -- Get customer name
  SELECT CONCAT(first_name, ' ', last_name) INTO est_customer_name
  FROM customers WHERE id = est_customer_id;

  INSERT INTO jobs (
    company_id, customer_id, customer_name, property_id,
    title, description, status, estimated_amount, source,
    estimate_id, lead_id, created_at, updated_at
  ) VALUES (
    est_company_id, est_customer_id, COALESCE(est_customer_name, 'Unknown'),
    est_property_id, est_title, COALESCE(NEW.notes, ''),
    'scheduled', est_total, 'estimate',
    NEW.id, est_lead_id, now(), now()
  ) RETURNING id INTO new_job_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_estimate_approved_auto_job ON estimates;
CREATE TRIGGER trg_estimate_approved_auto_job
  AFTER UPDATE ON estimates
  FOR EACH ROW
  WHEN (NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved')
  EXECUTE FUNCTION fn_auto_create_job_from_estimate();


-- 2. Lead Won → Auto-Create Customer
-- When a lead's stage changes to 'won', create a customer if none exists.
CREATE OR REPLACE FUNCTION fn_auto_convert_lead_to_customer()
RETURNS TRIGGER AS $$
DECLARE
  existing_customer_id UUID;
  new_customer_id UUID;
  lead_email TEXT;
  lead_phone TEXT;
  lead_first TEXT;
  lead_last TEXT;
BEGIN
  IF NEW.stage != 'won' OR OLD.stage = 'won' THEN
    RETURN NEW;
  END IF;

  -- Already converted?
  IF NEW.converted_to_customer_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  lead_email := LOWER(TRIM(NEW.email));
  lead_phone := NEW.phone;

  -- Split contact_name into first/last
  lead_first := SPLIT_PART(COALESCE(NEW.contact_name, ''), ' ', 1);
  lead_last := NULLIF(TRIM(SUBSTRING(COALESCE(NEW.contact_name, '') FROM POSITION(' ' IN COALESCE(NEW.contact_name, '')) + 1)), '');

  -- Check for existing customer by email or phone
  SELECT id INTO existing_customer_id
  FROM customers
  WHERE company_id = NEW.company_id
    AND deleted_at IS NULL
    AND (
      (lead_email IS NOT NULL AND lead_email != '' AND LOWER(email) = lead_email)
      OR
      (lead_phone IS NOT NULL AND lead_phone != '' AND phone = lead_phone)
    )
  LIMIT 1;

  IF existing_customer_id IS NOT NULL THEN
    -- Link lead to existing customer
    UPDATE leads SET converted_to_customer_id = existing_customer_id WHERE id = NEW.id;
    RETURN NEW;
  END IF;

  -- Create new customer
  INSERT INTO customers (
    company_id, first_name, last_name, email, phone, source, created_at, updated_at
  ) VALUES (
    NEW.company_id,
    COALESCE(NULLIF(lead_first, ''), 'Unknown'),
    COALESCE(lead_last, ''),
    NULLIF(lead_email, ''),
    lead_phone,
    COALESCE(NEW.source, 'lead'),
    now(), now()
  ) RETURNING id INTO new_customer_id;

  UPDATE leads SET converted_to_customer_id = new_customer_id WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_lead_won_auto_customer ON leads;
CREATE TRIGGER trg_lead_won_auto_customer
  AFTER UPDATE ON leads
  FOR EACH ROW
  WHEN (NEW.stage = 'won' AND OLD.stage IS DISTINCT FROM 'won')
  EXECUTE FUNCTION fn_auto_convert_lead_to_customer();


-- 3. Signature (job_completion) → Update Job Status
CREATE OR REPLACE FUNCTION fn_complete_job_on_signature()
RETURNS TRIGGER AS $$
BEGIN
  -- Job completion signature
  IF NEW.signature_type = 'job_completion' AND NEW.job_id IS NOT NULL THEN
    UPDATE jobs
    SET status = 'completed', completed_at = now(), updated_at = now()
    WHERE id = NEW.job_id AND status != 'completed';
  END IF;

  -- Invoice approval signature
  IF NEW.signature_type = 'invoice_approval' AND NEW.invoice_id IS NOT NULL THEN
    UPDATE invoices
    SET signed_at = now(), updated_at = now()
    WHERE id = NEW.invoice_id AND signed_at IS NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_signature_status_update ON signatures;
CREATE TRIGGER trg_signature_status_update
  AFTER INSERT ON signatures
  FOR EACH ROW
  EXECUTE FUNCTION fn_complete_job_on_signature();


-- 4. Change Order Approved → Update Job Budget
CREATE OR REPLACE FUNCTION fn_apply_change_order_to_job()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status != 'approved' OR OLD.status = 'approved' THEN
    RETURN NEW;
  END IF;

  -- Add CO amount to job's estimated_amount
  UPDATE jobs
  SET estimated_amount = COALESCE(estimated_amount, 0) + COALESCE(NEW.amount, 0),
      updated_at = now()
  WHERE id = NEW.job_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_change_order_approved_update_budget ON change_orders;
CREATE TRIGGER trg_change_order_approved_update_budget
  AFTER UPDATE ON change_orders
  FOR EACH ROW
  WHEN (NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved')
  EXECUTE FUNCTION fn_apply_change_order_to_job();


-- 5. Add invoice_id to signatures for invoice_approval linking (if missing)
ALTER TABLE signatures ADD COLUMN IF NOT EXISTS invoice_id UUID REFERENCES invoices(id);
CREATE INDEX IF NOT EXISTS idx_signatures_invoice_id ON signatures (invoice_id) WHERE invoice_id IS NOT NULL;

-- 6. Add completed_at to jobs (if missing)
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
