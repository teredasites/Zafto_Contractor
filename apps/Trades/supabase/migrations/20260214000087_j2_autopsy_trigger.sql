-- J2: Job Cost Autopsy — DB trigger + CRON scheduling
-- Fires autopsy generator Edge Function when job status changes to 'completed'
-- Monthly CRON for insight aggregation + estimate adjustment generation

-- ══════════════════════════════════════════════════════════
-- TRIGGER: Fire autopsy generator on job completion
-- Uses pg_net (same pattern as automation-engine triggers)
-- ══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION fn_trigger_autopsy_on_job_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _supabase_url text;
  _service_key text;
BEGIN
  -- Only fire when status changes TO 'completed'
  IF NEW.status != 'completed' OR OLD.status = 'completed' THEN
    RETURN NEW;
  END IF;

  -- Get Supabase URL from current_setting (set by Supabase automatically)
  _supabase_url := current_setting('app.settings.supabase_url', true);
  _service_key := current_setting('app.settings.service_role_key', true);

  -- Skip if pg_net config not available (local dev)
  IF _supabase_url IS NULL OR _service_key IS NULL THEN
    RETURN NEW;
  END IF;

  -- Async HTTP POST to Edge Function via pg_net
  PERFORM net.http_post(
    url := _supabase_url || '/functions/v1/job-cost-autopsy-generator',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || _service_key
    ),
    body := jsonb_build_object(
      'job_id', NEW.id::text,
      'company_id', NEW.company_id::text
    )
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Never block the job update — log warning and continue
    RAISE WARNING 'autopsy trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Attach trigger to jobs table (AFTER UPDATE so the status change is committed)
DROP TRIGGER IF EXISTS trg_autopsy_on_job_complete ON jobs;
CREATE TRIGGER trg_autopsy_on_job_complete
  AFTER UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION fn_trigger_autopsy_on_job_complete();

-- ══════════════════════════════════════════════════════════
-- CRON: Monthly intelligence aggregation
-- Requires pg_cron extension (enabled in Supabase dashboard)
-- ══════════════════════════════════════════════════════════

-- Schedule: 1st of every month at 3am UTC
-- SELECT cron.schedule(
--   'job-intelligence-monthly',
--   '0 3 1 * *',
--   $$SELECT net.http_post(
--     url := current_setting('app.settings.supabase_url') || '/functions/v1/job-intelligence-cron',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
--     ),
--     body := '{}'::jsonb
--   )$$
-- );

-- NOTE: pg_cron scheduling is best configured via Supabase Dashboard > Database > Extensions > pg_cron
-- The SQL above is provided as reference. Enable via dashboard for production.
