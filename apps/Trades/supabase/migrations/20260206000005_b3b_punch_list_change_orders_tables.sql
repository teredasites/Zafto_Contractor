-- ============================================================
-- ZAFTO CORE SCHEMA — B3b: Punch List + Change Orders Tables
-- Sprint B3b | Session 48
--
-- Run against: dev first, then staging, then prod
-- Tables: punch_list_items, change_orders
-- Depends on: A3a (companies, users), A3b (jobs, signatures)
-- ============================================================

-- PUNCH LIST / TASK CHECKLIST
CREATE TABLE punch_list_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  assigned_to_user_id uuid REFERENCES auth.users(id),
  title text NOT NULL,
  description text,
  category text,
  priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status text DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'skipped')),
  due_date date,
  completed_at timestamptz,
  completed_by_user_id uuid REFERENCES auth.users(id),
  photo_ids uuid[] DEFAULT '{}',
  sort_order int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE punch_list_items ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_punch_list_job ON punch_list_items (job_id, sort_order);
CREATE INDEX idx_punch_list_status ON punch_list_items (job_id, status);
CREATE TRIGGER punch_list_updated_at BEFORE UPDATE ON punch_list_items FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER punch_list_audit AFTER INSERT OR UPDATE OR DELETE ON punch_list_items FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "punch_list_select" ON punch_list_items FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "punch_list_insert" ON punch_list_items FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "punch_list_update" ON punch_list_items FOR UPDATE USING (company_id = requesting_company_id());

-- CHANGE ORDERS
CREATE TABLE change_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id),
  created_by_user_id uuid NOT NULL REFERENCES auth.users(id),
  change_order_number text NOT NULL,
  title text NOT NULL,
  description text NOT NULL,
  reason text,
  line_items jsonb DEFAULT '[]',
  amount numeric(12,2) NOT NULL DEFAULT 0,
  status text DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'voided')),
  approved_by_name text,
  approved_at timestamptz,
  signature_id uuid REFERENCES signatures(id),
  photo_ids uuid[] DEFAULT '{}',
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE change_orders ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_change_orders_job ON change_orders (job_id);
CREATE INDEX idx_change_orders_status ON change_orders (job_id, status);
CREATE TRIGGER change_orders_updated_at BEFORE UPDATE ON change_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER change_orders_audit AFTER INSERT OR UPDATE OR DELETE ON change_orders FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE POLICY "change_orders_select" ON change_orders FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "change_orders_insert" ON change_orders FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "change_orders_update" ON change_orders FOR UPDATE USING (company_id = requesting_company_id());
