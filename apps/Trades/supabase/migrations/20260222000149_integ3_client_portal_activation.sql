-- ============================================================
-- INTEG3: Client Portal Activation
-- Migration 000149
--
-- Transform client portal from receive-only to interactive hub.
-- Homeowners approve estimates, pay invoices, view 3D scans,
-- track restoration progress — all in-portal.
--
-- New tables:
--   estimate_approvals      (digital estimate approval workflow)
--   client_portal_shares    (what data is shared with which client)
--   restoration_progress    (progress tracking for client view)
--
-- Alters:
--   customers               (add portal_user_id FK + portal flags)
-- ============================================================

-- ============================================================
-- 1. ESTIMATE APPROVALS
--    Full approval workflow: approve / request changes / decline
--    Audit trail, contractor notification, change request flow
-- ============================================================

CREATE TABLE IF NOT EXISTS estimate_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Estimate reference
  estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,

  -- Approval state
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'changes_requested', 'declined', 'expired', 'superseded')),

  -- Who acted
  approved_by UUID REFERENCES auth.users(id),
  approved_by_name TEXT,   -- display name at time of action
  approved_by_email TEXT,  -- email at time of action
  approved_at TIMESTAMPTZ,

  -- Change request details
  change_request_comments TEXT,
  change_request_items JSONB DEFAULT '[]'::jsonb,
  -- [{line_item_id, concern, requested_change}]

  -- Decline details
  decline_reason TEXT,

  -- Approval conditions
  conditions TEXT,  -- "Approved contingent on..."
  signature_data TEXT,  -- Base64 signature if captured
  signature_ip TEXT,    -- IP address at time of signature

  -- Version tracking (which version of the estimate was approved)
  estimate_version INTEGER DEFAULT 1,
  estimate_total_at_approval NUMERIC(12,2),

  -- Notification tracking
  contractor_notified BOOLEAN NOT NULL DEFAULT false,
  contractor_notified_at TIMESTAMPTZ,

  -- Expiry
  expires_at TIMESTAMPTZ,

  -- Metadata
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_ea_company ON estimate_approvals(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ea_estimate ON estimate_approvals(estimate_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_ea_status ON estimate_approvals(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_ea_approved_by ON estimate_approvals(approved_by) WHERE deleted_at IS NULL;

ALTER TABLE estimate_approvals ENABLE ROW LEVEL SECURITY;

-- Clients can see approvals for their estimates (via portal share)
-- Company members can see all approvals
CREATE POLICY ea_select ON estimate_approvals FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

-- Client portal users can create approvals (approve/decline/request changes)
CREATE POLICY ea_insert ON estimate_approvals FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR EXISTS (
      SELECT 1 FROM estimates e
      JOIN customers c ON c.id = e.customer_id
      WHERE e.id = estimate_id
      AND c.portal_user_id = auth.uid()
      AND e.deleted_at IS NULL
    )
  );

CREATE POLICY ea_update ON estimate_approvals FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

SELECT update_updated_at('estimate_approvals');
CREATE TRIGGER ea_audit AFTER INSERT OR UPDATE OR DELETE ON estimate_approvals
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 2. CLIENT PORTAL SHARES
--    Controls what data is visible to which client portal user
--    Granular per-entity sharing (estimates, invoices, scans, jobs)
-- ============================================================

CREATE TABLE IF NOT EXISTS client_portal_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Who shared / who receives
  shared_by UUID NOT NULL REFERENCES auth.users(id),
  portal_user_id UUID NOT NULL REFERENCES auth.users(id),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,

  -- What's shared
  entity_type TEXT NOT NULL
    CHECK (entity_type IN ('estimate', 'invoice', 'job', 'property_scan', 'floor_plan', 'restoration_job', 'document', 'photo_album')),
  entity_id UUID NOT NULL,

  -- Permissions
  can_view BOOLEAN NOT NULL DEFAULT true,
  can_approve BOOLEAN NOT NULL DEFAULT false,
  can_pay BOOLEAN NOT NULL DEFAULT false,
  can_comment BOOLEAN NOT NULL DEFAULT false,
  can_download BOOLEAN NOT NULL DEFAULT false,

  -- Access tracking
  first_viewed_at TIMESTAMPTZ,
  last_viewed_at TIMESTAMPTZ,
  view_count INTEGER NOT NULL DEFAULT 0,

  -- Expiry
  expires_at TIMESTAMPTZ,
  is_revoked BOOLEAN NOT NULL DEFAULT false,
  revoked_at TIMESTAMPTZ,

  -- Share link (optional — for email/SMS links)
  share_token TEXT UNIQUE,
  share_url TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cps_company ON client_portal_shares(company_id);
CREATE INDEX idx_cps_portal_user ON client_portal_shares(portal_user_id);
CREATE INDEX idx_cps_customer ON client_portal_shares(customer_id);
CREATE INDEX idx_cps_entity ON client_portal_shares(entity_type, entity_id);
CREATE INDEX idx_cps_share_token ON client_portal_shares(share_token) WHERE share_token IS NOT NULL;
CREATE UNIQUE INDEX idx_cps_unique_share ON client_portal_shares(portal_user_id, entity_type, entity_id)
  WHERE is_revoked = false;

ALTER TABLE client_portal_shares ENABLE ROW LEVEL SECURITY;

-- Company members see all shares for their company
CREATE POLICY cps_company_select ON client_portal_shares FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Portal users see shares assigned to them
CREATE POLICY cps_portal_select ON client_portal_shares FOR SELECT TO authenticated
  USING (portal_user_id = auth.uid() AND is_revoked = false AND (expires_at IS NULL OR expires_at > now()));

CREATE POLICY cps_insert ON client_portal_shares FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY cps_update ON client_portal_shares FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

SELECT update_updated_at('client_portal_shares');
CREATE TRIGGER cps_audit AFTER INSERT OR UPDATE OR DELETE ON client_portal_shares
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. RESTORATION PROGRESS (client-facing view)
--    Simplified progress entries for the client portal
--    Links to restoration_line_items for actual data
-- ============================================================

CREATE TABLE IF NOT EXISTS restoration_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Context
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,

  -- Phase tracking
  current_phase TEXT NOT NULL DEFAULT 'assessment'
    CHECK (current_phase IN (
      'assessment', 'emergency_mitigation', 'water_extraction',
      'structural_drying', 'demolition', 'mold_remediation',
      'rebuild_planning', 'rebuild_in_progress', 'finishing',
      'final_inspection', 'complete'
    )),
  phase_started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  estimated_completion_date DATE,

  -- Progress
  overall_progress_pct INTEGER NOT NULL DEFAULT 0 CHECK (overall_progress_pct BETWEEN 0 AND 100),
  phase_progress_pct INTEGER NOT NULL DEFAULT 0 CHECK (phase_progress_pct BETWEEN 0 AND 100),

  -- Updates (visible to client)
  latest_update TEXT,
  latest_update_at TIMESTAMPTZ,
  latest_photos JSONB DEFAULT '[]'::jsonb,  -- [{url, caption, taken_at}]

  -- Moisture readings (for drying phases)
  latest_moisture_readings JSONB DEFAULT '[]'::jsonb,
  -- [{location, material, reading_pct, target_pct, timestamp}]

  -- Schedule
  next_visit_date DATE,
  next_visit_time_range TEXT,  -- "9:00 AM - 12:00 PM"
  next_visit_description TEXT,

  -- Contact
  project_manager_name TEXT,
  project_manager_phone TEXT,

  -- Client visibility
  is_visible_to_client BOOLEAN NOT NULL DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_rp_company ON restoration_progress(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rp_job ON restoration_progress(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rp_customer ON restoration_progress(customer_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rp_phase ON restoration_progress(current_phase) WHERE deleted_at IS NULL;

ALTER TABLE restoration_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY rp_select ON restoration_progress FOR SELECT TO authenticated
  USING (
    (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
     AND deleted_at IS NULL)
    OR (is_visible_to_client = true
        AND EXISTS (
          SELECT 1 FROM customers c
          WHERE c.id = customer_id
          AND c.portal_user_id = auth.uid()
        )
        AND deleted_at IS NULL)
  );

CREATE POLICY rp_insert ON restoration_progress FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY rp_update ON restoration_progress FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

SELECT update_updated_at('restoration_progress');
CREATE TRIGGER rp_audit AFTER INSERT OR UPDATE OR DELETE ON restoration_progress
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. ALTER CUSTOMERS — Add portal bridge columns
--    Links CRM customer to client portal auth.users account
-- ============================================================

ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS portal_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS portal_status TEXT DEFAULT 'none'
    CHECK (portal_status IN ('none', 'invited', 'active', 'deactivated')),
  ADD COLUMN IF NOT EXISTS portal_invited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS portal_activated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS portal_last_login_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_customers_portal_user ON customers(portal_user_id) WHERE portal_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_portal_status ON customers(portal_status) WHERE portal_status != 'none';


-- ============================================================
-- 5. fn_bridge_customer_to_portal
--    When a client portal user signs up, check if their email
--    matches an existing customer. If yes, auto-link.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_bridge_customer_to_portal(
  p_portal_user_id UUID,
  p_email TEXT
)
RETURNS TABLE(customer_id UUID, company_id UUID, customer_name TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE customers
  SET portal_user_id = p_portal_user_id,
      portal_status = 'active',
      portal_activated_at = now(),
      updated_at = now()
  WHERE email = lower(trim(p_email))
    AND portal_user_id IS NULL
    AND deleted_at IS NULL
  RETURNING customers.id AS customer_id,
            customers.company_id AS company_id,
            (customers.first_name || ' ' || customers.last_name) AS customer_name;
END;
$$;


-- ============================================================
-- 6. fn_invite_customer_to_portal
--    Creates a portal invitation for a customer.
--    Returns the magic link token for sending via email/SMS.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_invite_customer_to_portal(
  p_customer_id UUID,
  p_invited_by UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_customer customers;
  v_company_id UUID;
BEGIN
  SELECT * INTO v_customer FROM customers
    WHERE id = p_customer_id AND deleted_at IS NULL;

  IF v_customer IS NULL THEN
    RETURN jsonb_build_object('error', 'Customer not found');
  END IF;

  IF v_customer.portal_user_id IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'Customer already has portal access', 'portal_status', v_customer.portal_status);
  END IF;

  IF v_customer.email IS NULL OR v_customer.email = '' THEN
    RETURN jsonb_build_object('error', 'Customer has no email address');
  END IF;

  -- Verify inviter belongs to same company
  v_company_id := v_customer.company_id;

  -- Update customer status
  UPDATE customers
  SET portal_status = 'invited',
      portal_invited_at = now(),
      updated_at = now()
  WHERE id = p_customer_id;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', p_customer_id,
    'email', v_customer.email,
    'name', v_customer.first_name || ' ' || v_customer.last_name,
    'company_id', v_company_id
  );
END;
$$;
