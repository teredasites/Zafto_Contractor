-- FIELD4: Laser Meter Bug Reports
-- Sprint FIELD4 (Session 131)
--
-- Bug report table for beta laser meter adapters.
-- Users submit device info, BLE logs, and descriptions when
-- a non-Bosch laser meter misbehaves.

-- ═══════════════════════════════════════════════════════════════════
-- TABLE
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS laser_meter_bug_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id),
    user_id UUID NOT NULL REFERENCES auth.users(id),

    -- Device identification
    device_brand TEXT NOT NULL,
    device_model TEXT,
    firmware_version TEXT,

    -- Environment
    os_version TEXT,
    app_version TEXT,
    platform TEXT, -- 'ios', 'android', 'web'

    -- Report content
    description TEXT NOT NULL,
    ble_logs JSONB DEFAULT '[]'::jsonb,
    screenshot_url TEXT,

    -- Triage
    status TEXT NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'investigating', 'resolved', 'wontfix')),
    resolution_notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_laser_bug_reports_company ON laser_meter_bug_reports(company_id);
CREATE INDEX idx_laser_bug_reports_status ON laser_meter_bug_reports(status);
CREATE INDEX idx_laser_bug_reports_brand ON laser_meter_bug_reports(device_brand);

-- Updated_at trigger
CREATE TRIGGER update_laser_meter_bug_reports_updated_at
    BEFORE UPDATE ON laser_meter_bug_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trigger
CREATE TRIGGER audit_laser_meter_bug_reports
    AFTER INSERT OR UPDATE OR DELETE ON laser_meter_bug_reports
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ═══════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE laser_meter_bug_reports ENABLE ROW LEVEL SECURITY;

-- Users can insert their own reports
CREATE POLICY laser_bug_reports_insert ON laser_meter_bug_reports
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid()
        AND company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    );

-- Users can read their own reports
CREATE POLICY laser_bug_reports_select_own ON laser_meter_bug_reports
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Admins/owners can read all reports for their company
CREATE POLICY laser_bug_reports_select_admin ON laser_meter_bug_reports
    FOR SELECT TO authenticated
    USING (
        company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin', 'super_admin')
    );

-- Super admin reads all
CREATE POLICY laser_bug_reports_select_super ON laser_meter_bug_reports
    FOR SELECT TO authenticated
    USING (
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
    );
