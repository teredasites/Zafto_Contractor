-- FIELD5: BYOC Phone — Bring Your Own Carrier
-- Sprint FIELD5 (Session 131)
--
-- Lets contractors keep their existing business phone number
-- while using Zafto's full phone system (call recording, IVR,
-- voicemail transcription, analytics).
--
-- Three integration methods:
-- 1. SIP Trunk — contractor's VoIP provider points to SignalWire
-- 2. Call Forwarding — simple *72 forwarding for cell/landline
-- 3. Number Porting — full LNP transfer to SignalWire

-- ═══════════════════════════════════════════════════════════════════
-- TABLE
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS company_phone_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id),

    -- Phone number (E.164 format: +1XXXXXXXXXX)
    phone_number TEXT NOT NULL,
    display_label TEXT, -- e.g., "Main Office", "After Hours"

    -- Verification
    verification_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (verification_status IN ('pending', 'code_sent', 'verified', 'failed', 'expired')),
    verification_code TEXT,
    verification_sent_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    verified_by_user_id UUID REFERENCES auth.users(id),

    -- Integration method
    forwarding_type TEXT NOT NULL DEFAULT 'call_forward'
        CHECK (forwarding_type IN ('sip_trunk', 'call_forward', 'port_in')),

    -- SIP trunk credentials (encrypted in app layer)
    sip_credentials JSONB DEFAULT '{}'::jsonb,
    -- Expected shape: { "sip_endpoint": "...", "username": "...", "password": "...", "realm": "..." }

    -- Call forwarding details
    forwarding_target TEXT, -- SignalWire number to forward to
    carrier_detected TEXT, -- Verizon, AT&T, T-Mobile, etc.
    forwarding_instructions TEXT, -- Carrier-specific instructions (*72, etc.)

    -- Number porting
    port_status TEXT DEFAULT 'none'
        CHECK (port_status IN ('none', 'requested', 'foc_received', 'porting', 'complete', 'rejected', 'cancelled')),
    port_request_id TEXT, -- SignalWire LNP request ID
    port_foc_date DATE, -- Firm Order Commitment date
    port_completion_date TIMESTAMPTZ,

    -- Caller ID
    caller_id_name TEXT, -- CNAM registration name (15 chars max)
    caller_id_registered BOOLEAN NOT NULL DEFAULT false,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT false, -- Only true after verification
    is_primary BOOLEAN NOT NULL DEFAULT false, -- Primary business number

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_company_phone_numbers_company ON company_phone_numbers(company_id);
CREATE INDEX idx_company_phone_numbers_phone ON company_phone_numbers(phone_number);
CREATE INDEX idx_company_phone_numbers_status ON company_phone_numbers(verification_status);
CREATE INDEX idx_company_phone_numbers_port ON company_phone_numbers(port_status)
    WHERE port_status != 'none';

-- Ensure only one primary number per company
CREATE UNIQUE INDEX idx_company_phone_numbers_primary
    ON company_phone_numbers(company_id)
    WHERE is_primary = true AND deleted_at IS NULL;

-- Updated_at trigger
CREATE TRIGGER update_company_phone_numbers_updated_at
    BEFORE UPDATE ON company_phone_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit trigger
CREATE TRIGGER audit_company_phone_numbers
    AFTER INSERT OR UPDATE OR DELETE ON company_phone_numbers
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ═══════════════════════════════════════════════════════════════════
-- RLS
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE company_phone_numbers ENABLE ROW LEVEL SECURITY;

-- Owner/admin can manage phone numbers
CREATE POLICY company_phone_numbers_select ON company_phone_numbers
    FOR SELECT TO authenticated
    USING (
        company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    );

CREATE POLICY company_phone_numbers_insert ON company_phone_numbers
    FOR INSERT TO authenticated
    WITH CHECK (
        company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin')
    );

CREATE POLICY company_phone_numbers_update ON company_phone_numbers
    FOR UPDATE TO authenticated
    USING (
        company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin')
    );

CREATE POLICY company_phone_numbers_delete ON company_phone_numbers
    FOR DELETE TO authenticated
    USING (
        company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('owner', 'admin')
    );

-- Super admin reads all
CREATE POLICY company_phone_numbers_super ON company_phone_numbers
    FOR ALL TO authenticated
    USING (
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
    );

-- ═══════════════════════════════════════════════════════════════════
-- CARRIER DETECTION HELPER
-- ═══════════════════════════════════════════════════════════════════

-- Carrier-specific call forwarding instructions (seed data)
COMMENT ON TABLE company_phone_numbers IS
    'BYOC phone numbers. Forwarding codes by carrier:
     Verizon: *72 to forward, *73 to cancel
     AT&T: *72 to forward, *73 to cancel
     T-Mobile: **21*[number]# to forward, ##21# to cancel
     Spectrum: *72 to forward, *73 to cancel
     Comcast: *72 to forward, *73 to cancel
     Most CLEC: *72 to forward, *73 to cancel
     SIP trunk: No forwarding needed — point SIP to endpoint';
