-- T6c: Auto-calculate referral fee on job close
-- When a tpa_assignment is marked 'completed' or 'paid', calculate referral fee
-- from the TPA program's referral_fee_percent and insert into Ledger (ledger_entries).

-- ============================================================================
-- FUNCTION: Calculate and record referral fee
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_tpa_referral_fee()
RETURNS TRIGGER AS $$
DECLARE
  v_program RECORD;
  v_job_total NUMERIC(12,2);
  v_fee_amount NUMERIC(12,2);
  v_existing_fee UUID;
BEGIN
  -- Only fire on status change to completed or paid
  IF NEW.status NOT IN ('completed', 'paid') THEN
    RETURN NEW;
  END IF;

  -- Skip if status didn't change
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Skip if no job linked
  IF NEW.job_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get the TPA program's referral fee config
  SELECT referral_fee_percent, referral_fee_type, referral_fee_flat, name
    INTO v_program
    FROM tpa_programs
   WHERE id = NEW.tpa_program_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Calculate fee based on type
  IF v_program.referral_fee_type = 'none' THEN
    RETURN NEW;
  END IF;

  IF v_program.referral_fee_type = 'flat' THEN
    v_fee_amount := COALESCE(v_program.referral_fee_flat, 0);
  ELSE
    -- percentage (default) or tiered (simplified to percentage for now)
    -- Get total invoiced amount for the job
    SELECT COALESCE(SUM(total), 0) INTO v_job_total
      FROM invoices
     WHERE job_id = NEW.job_id
       AND company_id = NEW.company_id
       AND status != 'voided';

    v_fee_amount := v_job_total * (COALESCE(v_program.referral_fee_percent, 0) / 100.0);
  END IF;

  -- Skip if zero
  IF v_fee_amount <= 0 THEN
    RETURN NEW;
  END IF;

  -- Check if we already recorded a referral fee for this assignment (idempotent)
  SELECT id INTO v_existing_fee
    FROM ledger_entries
   WHERE company_id = NEW.company_id
     AND reference_type = 'tpa_referral_fee'
     AND reference_id = NEW.id::text
   LIMIT 1;

  IF v_existing_fee IS NOT NULL THEN
    -- Update existing entry
    UPDATE ledger_entries
       SET amount = v_fee_amount,
           description = 'TPA referral fee: ' || v_program.name,
           updated_at = now()
     WHERE id = v_existing_fee;
  ELSE
    -- Insert new ledger entry
    INSERT INTO ledger_entries (
      company_id, job_id, entry_type, category,
      amount, description, reference_type, reference_id,
      entry_date
    ) VALUES (
      NEW.company_id, NEW.job_id, 'expense', 'referral_fee',
      v_fee_amount,
      'TPA referral fee: ' || v_program.name,
      'tpa_referral_fee', NEW.id::text,
      now()::date
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGER: Fire on tpa_assignments status update
-- ============================================================================

CREATE TRIGGER tpa_referral_fee_on_close
  AFTER UPDATE OF status ON tpa_assignments
  FOR EACH ROW
  WHEN (NEW.status IN ('completed', 'paid') AND OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION calculate_tpa_referral_fee();
