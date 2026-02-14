-- U7f: Automation Engine — DB triggers + default automations
-- Uses pg_net to call automation-engine Edge Function asynchronously on table changes

-- ══════════════════════════════════════════════
-- HELPER: Fire automation engine via pg_net
-- ══════════════════════════════════════════════
CREATE OR REPLACE FUNCTION fire_automation_trigger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _supabase_url text;
  _service_key text;
  _trigger_type text;
  _company_id uuid;
  _event_data jsonb;
BEGIN
  -- Get Supabase URL from current_setting (set by Supabase automatically)
  _supabase_url := current_setting('app.settings.supabase_url', true);
  _service_key := current_setting('app.settings.service_role_key', true);

  -- Skip if pg_net config not available (local dev without pg_net)
  IF _supabase_url IS NULL OR _service_key IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Determine trigger type and build event data based on table
  CASE TG_TABLE_NAME
    WHEN 'jobs' THEN
      _trigger_type := 'job_status';
      _company_id := COALESCE(NEW.company_id, OLD.company_id);
      _event_data := jsonb_build_object(
        'table', 'jobs',
        'record_id', COALESCE(NEW.id, OLD.id),
        'old_status', OLD.status,
        'new_status', NEW.status,
        'job_title', NEW.title,
        'customer_id', NEW.customer_id,
        'customer_name', NEW.customer_name
      );
      -- Only fire on status change
      IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    WHEN 'invoices' THEN
      _trigger_type := 'invoice_overdue';
      _company_id := COALESCE(NEW.company_id, OLD.company_id);
      _event_data := jsonb_build_object(
        'table', 'invoices',
        'record_id', COALESCE(NEW.id, OLD.id),
        'old_status', OLD.status,
        'new_status', NEW.status,
        'invoice_number', NEW.invoice_number,
        'customer_id', NEW.customer_id,
        'amount', NEW.total
      );
      -- Only fire on status change
      IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    WHEN 'bids' THEN
      _trigger_type := 'bid_event';
      _company_id := COALESCE(NEW.company_id, OLD.company_id);
      _event_data := jsonb_build_object(
        'table', 'bids',
        'record_id', COALESCE(NEW.id, OLD.id),
        'old_status', OLD.status,
        'new_status', NEW.status,
        'bid_number', NEW.bid_number,
        'customer_id', NEW.customer_id,
        'amount', NEW.total
      );
      -- Only fire on status change
      IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    WHEN 'leads' THEN
      _trigger_type := 'lead_idle';
      _company_id := COALESCE(NEW.company_id, OLD.company_id);
      _event_data := jsonb_build_object(
        'table', 'leads',
        'record_id', COALESCE(NEW.id, OLD.id),
        'old_status', OLD.status,
        'new_status', NEW.status,
        'customer_name', COALESCE(NEW.first_name || ' ' || NEW.last_name, '')
      );
      IF OLD.status = NEW.status THEN RETURN NEW; END IF;

    WHEN 'customers' THEN
      -- Only fire on INSERT (new customer)
      IF TG_OP != 'INSERT' THEN RETURN COALESCE(NEW, OLD); END IF;
      _trigger_type := 'customer_event';
      _company_id := NEW.company_id;
      _event_data := jsonb_build_object(
        'table', 'customers',
        'record_id', NEW.id,
        'customer_id', NEW.id,
        'customer_name', COALESCE(NEW.first_name || ' ' || NEW.last_name, ''),
        'new_status', 'created'
      );

    ELSE
      RETURN COALESCE(NEW, OLD);
  END CASE;

  -- Call automation-engine EF via pg_net (async HTTP POST)
  -- pg_net must be enabled in Supabase dashboard
  PERFORM net.http_post(
    url := _supabase_url || '/functions/v1/automation-engine',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || _service_key
    ),
    body := jsonb_build_object(
      'trigger_type', _trigger_type,
      'company_id', _company_id,
      'event_data', _event_data
    )
  );

  RETURN COALESCE(NEW, OLD);
EXCEPTION
  WHEN OTHERS THEN
    -- Never block the original operation — log and continue
    RAISE WARNING 'automation trigger failed: %', SQLERRM;
    RETURN COALESCE(NEW, OLD);
END;
$$;

-- ══════════════════════════════════════════════
-- TRIGGERS on business tables
-- ══════════════════════════════════════════════
-- Jobs: fire on status change
DROP TRIGGER IF EXISTS jobs_automation_trigger ON jobs;
CREATE TRIGGER jobs_automation_trigger
  AFTER UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION fire_automation_trigger();

-- Invoices: fire on status change
DROP TRIGGER IF EXISTS invoices_automation_trigger ON invoices;
CREATE TRIGGER invoices_automation_trigger
  AFTER UPDATE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION fire_automation_trigger();

-- Bids: fire on status change
DROP TRIGGER IF EXISTS bids_automation_trigger ON bids;
CREATE TRIGGER bids_automation_trigger
  AFTER UPDATE ON bids
  FOR EACH ROW
  EXECUTE FUNCTION fire_automation_trigger();

-- Leads: fire on status change
DROP TRIGGER IF EXISTS leads_automation_trigger ON leads;
CREATE TRIGGER leads_automation_trigger
  AFTER UPDATE ON leads
  FOR EACH ROW
  EXECUTE FUNCTION fire_automation_trigger();

-- Customers: fire on new customer
DROP TRIGGER IF EXISTS customers_automation_trigger ON customers;
CREATE TRIGGER customers_automation_trigger
  AFTER INSERT ON customers
  FOR EACH ROW
  EXECUTE FUNCTION fire_automation_trigger();
