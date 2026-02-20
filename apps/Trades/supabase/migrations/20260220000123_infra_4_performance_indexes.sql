-- INFRA-4: Database performance foundation
-- S143: Missing company_id indexes, BRIN indexes, partial indexes, GIN indexes, materialized views

-- ============================================================
-- 1. Missing company_id B-tree indexes (30 tables)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_approval_thresholds_company ON approval_thresholds (company_id);
CREATE INDEX IF NOT EXISTS idx_asset_service_records_company ON asset_service_records (company_id);
CREATE INDEX IF NOT EXISTS idx_bids_company ON bids (company_id);
CREATE INDEX IF NOT EXISTS idx_change_orders_company ON change_orders (company_id);
CREATE INDEX IF NOT EXISTS idx_client_portal_users_company ON client_portal_users (company_id);
CREATE INDEX IF NOT EXISTS idx_customer_communications_company ON customer_communications (company_id);
CREATE INDEX IF NOT EXISTS idx_customers_company ON customers (company_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_company ON daily_logs (company_id);
CREATE INDEX IF NOT EXISTS idx_home_equipment_company ON home_equipment (company_id);
CREATE INDEX IF NOT EXISTS idx_inspection_deficiencies_company ON inspection_deficiencies (company_id);
CREATE INDEX IF NOT EXISTS idx_job_materials_company ON job_materials (company_id);
CREATE INDEX IF NOT EXISTS idx_job_subcontractors_company ON job_subcontractors (company_id);
CREATE INDEX IF NOT EXISTS idx_lease_documents_company ON lease_documents (company_id);
CREATE INDEX IF NOT EXISTS idx_leases_company ON leases (company_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_requests_company ON maintenance_requests (company_id);
CREATE INDEX IF NOT EXISTS idx_mileage_trips_company ON mileage_trips (company_id);
CREATE INDEX IF NOT EXISTS idx_pm_inspections_company ON pm_inspections (company_id);
CREATE INDEX IF NOT EXISTS idx_property_assets_company ON property_assets (company_id);
CREATE INDEX IF NOT EXISTS idx_property_floor_plans_company ON property_floor_plans (company_id);
CREATE INDEX IF NOT EXISTS idx_punch_list_items_company ON punch_list_items (company_id);
CREATE INDEX IF NOT EXISTS idx_receipts_company ON receipts (company_id);
CREATE INDEX IF NOT EXISTS idx_rent_charges_company ON rent_charges (company_id);
CREATE INDEX IF NOT EXISTS idx_schedule_task_locks_company ON schedule_task_locks (company_id);
CREATE INDEX IF NOT EXISTS idx_signatures_company ON signatures (company_id);
CREATE INDEX IF NOT EXISTS idx_unit_turns_company ON unit_turns (company_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_company ON user_sessions (company_id);
CREATE INDEX IF NOT EXISTS idx_users_company ON users (company_id);
CREATE INDEX IF NOT EXISTS idx_voice_notes_company ON voice_notes (company_id);
CREATE INDEX IF NOT EXISTS idx_walkthrough_templates_company ON walkthrough_templates (company_id);
CREATE INDEX IF NOT EXISTS idx_work_order_actions_company ON work_order_actions (company_id);

-- ============================================================
-- 2. BRIN indexes on append-only time-series tables
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_audit_log_created_brin ON audit_log USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_brin ON admin_audit_log USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_zbooks_audit_log_created_brin ON zbooks_audit_log USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_notification_log_created_brin ON notification_log USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_created_brin ON login_attempts USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_created_brin ON user_sessions USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_lead_analytics_events_created_brin ON lead_analytics_events USING BRIN (created_at);
CREATE INDEX IF NOT EXISTS idx_api_cost_log_created_brin ON api_cost_log USING BRIN (created_at);

-- ============================================================
-- 3. Partial indexes on hot tables (active records only)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_jobs_active ON jobs (company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_invoices_active ON invoices (company_id, status, due_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_estimates_active ON estimates (company_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_customers_active ON customers (company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_leads_active ON leads (company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_properties_active ON properties (company_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_bids_active ON bids (company_id, status) WHERE deleted_at IS NULL;

-- ============================================================
-- 4. GIN indexes on frequently queried JSONB columns
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_companies_settings_gin ON companies USING GIN (settings);
CREATE INDEX IF NOT EXISTS idx_custom_roles_permissions_gin ON custom_roles USING GIN (permissions);
CREATE INDEX IF NOT EXISTS idx_automations_config_gin ON automations USING GIN (config);
CREATE INDEX IF NOT EXISTS idx_form_templates_fields_gin ON form_templates USING GIN (fields);
CREATE INDEX IF NOT EXISTS idx_inspection_templates_sections_gin ON inspection_templates USING GIN (sections);

-- ============================================================
-- 5. Verify auth helper functions are STABLE
-- ============================================================

-- Mark as STABLE to enable initPlan caching for RLS policies
-- This lets PostgreSQL evaluate the function once per statement instead of per-row
CREATE OR REPLACE FUNCTION requesting_user_id()
RETURNS UUID
LANGUAGE SQL
STABLE
AS $$
  SELECT (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::uuid
$$;

CREATE OR REPLACE FUNCTION requesting_user_role()
RETURNS TEXT
LANGUAGE SQL
STABLE
AS $$
  SELECT current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'role'
$$;

CREATE OR REPLACE FUNCTION requesting_company_id()
RETURNS UUID
LANGUAGE SQL
STABLE
AS $$
  SELECT (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'company_id')::uuid
$$;

-- ============================================================
-- 6. Materialized views for dashboard aggregates
-- ============================================================

-- Revenue summary per company per month
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_company_revenue_summary AS
SELECT
  company_id,
  date_trunc('month', created_at) AS month,
  COUNT(*) AS invoice_count,
  COUNT(*) FILTER (WHERE status = 'paid') AS paid_count,
  COALESCE(SUM(total) FILTER (WHERE status = 'paid'), 0) AS paid_total,
  COALESCE(SUM(total) FILTER (WHERE status = 'sent' OR status = 'viewed'), 0) AS outstanding_total,
  COALESCE(SUM(total) FILTER (WHERE status = 'overdue'), 0) AS overdue_total,
  COALESCE(SUM(total), 0) AS gross_total
FROM invoices
WHERE deleted_at IS NULL
GROUP BY company_id, date_trunc('month', created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_revenue_company_month ON mv_company_revenue_summary (company_id, month);

-- Job pipeline per company
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_job_pipeline AS
SELECT
  company_id,
  status,
  COUNT(*) AS job_count,
  COALESCE(SUM(total_price), 0) AS total_value,
  COALESCE(AVG(total_price), 0) AS avg_value
FROM jobs
WHERE deleted_at IS NULL
GROUP BY company_id, status;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_pipeline_company_status ON mv_job_pipeline (company_id, status);
