-- D5b: Maintenance + Inspections + Assets (Migration 2 of 3)
-- Tables: maintenance_requests, maintenance_request_media, work_order_actions,
--         approval_records, inspections, inspection_items, property_assets, asset_service_records

-- 9. Maintenance Requests (tenant-submitted)
CREATE TABLE maintenance_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  title text NOT NULL,
  description text NOT NULL,
  urgency text NOT NULL DEFAULT 'routine' CHECK (urgency IN ('routine', 'urgent', 'emergency')),
  category text CHECK (category IN ('plumbing', 'electrical', 'hvac', 'appliance', 'structural', 'pest', 'lock_key', 'exterior', 'interior', 'other')),
  preferred_times jsonb,
  job_id uuid REFERENCES jobs(id),
  assigned_to uuid REFERENCES users(id),
  assigned_vendor_id uuid REFERENCES vendors(id),
  status text NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'reviewed', 'approved', 'scheduled', 'in_progress', 'completed', 'cancelled')),
  completed_at timestamptz,
  tenant_rating integer CHECK (tenant_rating BETWEEN 1 AND 5),
  tenant_feedback text,
  estimated_cost numeric(10,2),
  actual_cost numeric(10,2),
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_maint_req_unit ON maintenance_requests(unit_id, status);
CREATE INDEX idx_maint_req_property ON maintenance_requests(property_id, created_at DESC);
CREATE INDEX idx_maint_req_tenant ON maintenance_requests(tenant_id);
CREATE INDEX idx_maint_req_job ON maintenance_requests(job_id) WHERE job_id IS NOT NULL;

-- 10. Maintenance Request Media (photos + videos)
CREATE TABLE maintenance_request_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  maintenance_request_id uuid NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
  media_type text NOT NULL CHECK (media_type IN ('photo', 'video')),
  storage_path text NOT NULL,
  caption text,
  uploaded_by text NOT NULL CHECK (uploaded_by IN ('tenant', 'technician', 'manager')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_maint_media ON maintenance_request_media(maintenance_request_id);

-- 11. Work Order Actions (vendor/tech activity log — immutable)
CREATE TABLE work_order_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid NOT NULL REFERENCES jobs(id),
  maintenance_request_id uuid REFERENCES maintenance_requests(id),
  action_type text NOT NULL CHECK (action_type IN ('created', 'assigned', 'contacted', 'responded', 'scheduled', 'arrived', 'in_progress', 'completed', 'invoiced', 'paid', 'cancelled', 'note')),
  actor_type text NOT NULL CHECK (actor_type IN ('system', 'user', 'vendor', 'tenant')),
  actor_id text,
  actor_name text,
  notes text,
  photos jsonb DEFAULT '[]',
  metadata jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_wo_actions_job ON work_order_actions(job_id, created_at);
CREATE INDEX idx_wo_actions_maint ON work_order_actions(maintenance_request_id) WHERE maintenance_request_id IS NOT NULL;

-- 12. Approval Records (immutable audit trail)
CREATE TABLE approval_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  entity_type text NOT NULL CHECK (entity_type IN ('maintenance_request', 'vendor_invoice', 'lease', 'tenant_application', 'expense', 'rent_waiver')),
  entity_id uuid NOT NULL,
  requested_by uuid NOT NULL REFERENCES users(id),
  requested_at timestamptz NOT NULL DEFAULT now(),
  threshold_amount numeric(10,2),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
  decided_by uuid REFERENCES users(id),
  decided_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_approvals_pending ON approval_records(company_id, status) WHERE status = 'pending';
CREATE INDEX idx_approvals_entity ON approval_records(entity_type, entity_id);

-- 13. Inspections (PM-specific — not compliance_records)
CREATE TABLE pm_inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  lease_id uuid REFERENCES leases(id),
  inspection_type text NOT NULL CHECK (inspection_type IN ('move_in', 'move_out', 'routine', 'quarterly', 'annual', 'drive_by', 'pre_listing')),
  inspected_by uuid REFERENCES users(id),
  inspection_date date NOT NULL,
  overall_condition text CHECK (overall_condition IN ('excellent', 'good', 'fair', 'poor', 'damaged')),
  notes text,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pm_inspections_unit ON pm_inspections(unit_id, inspection_date DESC);

-- 14. Inspection Items (per-room/item condition)
CREATE TABLE pm_inspection_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES pm_inspections(id) ON DELETE CASCADE,
  area text NOT NULL,
  item text NOT NULL,
  condition text NOT NULL CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'damaged', 'missing', 'na')),
  notes text,
  photos jsonb DEFAULT '[]',
  requires_repair boolean DEFAULT false,
  repair_cost_estimate numeric(10,2),
  deposit_deduction numeric(10,2),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_pm_inspection_items ON pm_inspection_items(inspection_id);

-- 15. Property Assets (equipment health records)
CREATE TABLE property_assets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid REFERENCES units(id),
  asset_type text NOT NULL CHECK (asset_type IN ('hvac', 'water_heater', 'furnace', 'ac_unit', 'refrigerator', 'dishwasher', 'washer', 'dryer', 'garage_door', 'roof', 'plumbing_system', 'electrical_panel', 'smoke_detector', 'fire_extinguisher', 'oven_range', 'microwave', 'garbage_disposal', 'sump_pump', 'other')),
  manufacturer text,
  model text,
  serial_number text,
  install_date date,
  purchase_price numeric(10,2),
  warranty_expiry date,
  expected_lifespan_years integer,
  last_service_date date,
  next_service_due date,
  condition text NOT NULL DEFAULT 'good' CHECK (condition IN ('excellent', 'good', 'fair', 'poor', 'critical')),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'needs_service', 'end_of_life', 'replaced', 'decommissioned')),
  notes text,
  photos jsonb DEFAULT '[]',
  recurring_issues jsonb DEFAULT '[]',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_assets_property ON property_assets(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_assets_service_due ON property_assets(next_service_due) WHERE status = 'active' AND deleted_at IS NULL;

-- 16. Asset Service Records
CREATE TABLE asset_service_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  asset_id uuid NOT NULL REFERENCES property_assets(id),
  service_date date NOT NULL,
  service_type text NOT NULL CHECK (service_type IN ('routine_maintenance', 'repair', 'emergency_repair', 'replacement', 'inspection', 'warranty_claim')),
  job_id uuid REFERENCES jobs(id),
  vendor_id uuid REFERENCES vendors(id),
  performed_by_user_id uuid REFERENCES users(id),
  performed_by_name text,
  cost numeric(10,2),
  parts_used jsonb DEFAULT '[]',
  notes text,
  before_photos jsonb DEFAULT '[]',
  after_photos jsonb DEFAULT '[]',
  next_service_recommended date,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_asset_service ON asset_service_records(asset_id, service_date DESC);

-- RLS on all tables
ALTER TABLE maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_request_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_order_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE pm_inspection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_service_records ENABLE ROW LEVEL SECURITY;

-- Company RLS (via JWT app_metadata)
CREATE POLICY "maint_req_select" ON maintenance_requests FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "maint_req_insert" ON maintenance_requests FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "maint_req_update" ON maintenance_requests FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY "maint_media_select" ON maintenance_request_media FOR SELECT USING (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE company_id = requesting_company_id()));
CREATE POLICY "maint_media_insert" ON maintenance_request_media FOR INSERT WITH CHECK (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE company_id = requesting_company_id()));

-- work_order_actions: SELECT for company, INSERT-only (immutable audit trail — no UPDATE/DELETE policies)
CREATE POLICY "wo_actions_select" ON work_order_actions FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "wo_actions_insert" ON work_order_actions FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "approvals_select" ON approval_records FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "approvals_insert" ON approval_records FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "approvals_update" ON approval_records FOR UPDATE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

CREATE POLICY "pm_inspections_select" ON pm_inspections FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "pm_inspections_insert" ON pm_inspections FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "pm_inspections_update" ON pm_inspections FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY "pm_insp_items_select" ON pm_inspection_items FOR SELECT USING (inspection_id IN (SELECT id FROM pm_inspections WHERE company_id = requesting_company_id()));
CREATE POLICY "pm_insp_items_insert" ON pm_inspection_items FOR INSERT WITH CHECK (inspection_id IN (SELECT id FROM pm_inspections WHERE company_id = requesting_company_id()));

CREATE POLICY "assets_select" ON property_assets FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "assets_insert" ON property_assets FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "assets_update" ON property_assets FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY "asset_service_select" ON asset_service_records FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "asset_service_insert" ON asset_service_records FOR INSERT WITH CHECK (company_id = requesting_company_id());

-- Tenant portal: tenants see their own maintenance requests (via tenants.auth_user_id)
CREATE POLICY "maint_req_tenant_select" ON maintenance_requests FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "maint_req_tenant_insert" ON maintenance_requests FOR INSERT WITH CHECK (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "maint_media_tenant_select" ON maintenance_request_media FOR SELECT USING (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid())));
CREATE POLICY "maint_media_tenant_insert" ON maintenance_request_media FOR INSERT WITH CHECK (maintenance_request_id IN (SELECT id FROM maintenance_requests WHERE tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid())));

-- Audit triggers
CREATE TRIGGER maint_req_audit AFTER INSERT OR UPDATE OR DELETE ON maintenance_requests FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER pm_inspections_audit AFTER INSERT OR UPDATE OR DELETE ON pm_inspections FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER assets_audit AFTER INSERT OR UPDATE OR DELETE ON property_assets FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
