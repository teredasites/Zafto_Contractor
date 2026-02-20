-- SEC-AUDIT-3 | Session 139 — RLS Hardening
-- Replace subquery-based RLS (SELECT company_id FROM users WHERE id = auth.uid())
-- with requesting_company_id() for JWT-direct performance + security.
-- Add company_id to walkthrough child tables. Granular policy splits.

-- ============================================================
-- PART 1: Replace subquery RLS on phone system tables (9 tables)
-- Source: 20260208000033_f1a_phone_system.sql
-- ============================================================

-- phone_config
DROP POLICY IF EXISTS "phone_config_select" ON phone_config;
DROP POLICY IF EXISTS "phone_config_insert" ON phone_config;
DROP POLICY IF EXISTS "phone_config_update" ON phone_config;
CREATE POLICY "phone_config_select" ON phone_config FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_config_insert" ON phone_config FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_config_update" ON phone_config FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- phone_lines
DROP POLICY IF EXISTS "phone_lines_select" ON phone_lines;
DROP POLICY IF EXISTS "phone_lines_insert" ON phone_lines;
DROP POLICY IF EXISTS "phone_lines_update" ON phone_lines;
DROP POLICY IF EXISTS "phone_lines_delete" ON phone_lines;
CREATE POLICY "phone_lines_select" ON phone_lines FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_lines_insert" ON phone_lines FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_lines_update" ON phone_lines FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_lines_delete" ON phone_lines FOR DELETE
  USING (company_id = requesting_company_id());

-- phone_ring_groups
DROP POLICY IF EXISTS "phone_ring_groups_select" ON phone_ring_groups;
DROP POLICY IF EXISTS "phone_ring_groups_insert" ON phone_ring_groups;
DROP POLICY IF EXISTS "phone_ring_groups_update" ON phone_ring_groups;
DROP POLICY IF EXISTS "phone_ring_groups_delete" ON phone_ring_groups;
CREATE POLICY "phone_ring_groups_select" ON phone_ring_groups FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_ring_groups_insert" ON phone_ring_groups FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_ring_groups_update" ON phone_ring_groups FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_ring_groups_delete" ON phone_ring_groups FOR DELETE
  USING (company_id = requesting_company_id());

-- phone_on_call_schedule
DROP POLICY IF EXISTS "phone_on_call_select" ON phone_on_call_schedule;
DROP POLICY IF EXISTS "phone_on_call_insert" ON phone_on_call_schedule;
DROP POLICY IF EXISTS "phone_on_call_update" ON phone_on_call_schedule;
DROP POLICY IF EXISTS "phone_on_call_delete" ON phone_on_call_schedule;
CREATE POLICY "phone_on_call_select" ON phone_on_call_schedule FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_on_call_insert" ON phone_on_call_schedule FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_on_call_update" ON phone_on_call_schedule FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_on_call_delete" ON phone_on_call_schedule FOR DELETE
  USING (company_id = requesting_company_id());

-- phone_calls
DROP POLICY IF EXISTS "phone_calls_select" ON phone_calls;
DROP POLICY IF EXISTS "phone_calls_insert" ON phone_calls;
DROP POLICY IF EXISTS "phone_calls_update" ON phone_calls;
CREATE POLICY "phone_calls_select" ON phone_calls FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_calls_insert" ON phone_calls FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_calls_update" ON phone_calls FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- phone_voicemails
DROP POLICY IF EXISTS "phone_voicemails_select" ON phone_voicemails;
DROP POLICY IF EXISTS "phone_voicemails_insert" ON phone_voicemails;
DROP POLICY IF EXISTS "phone_voicemails_update" ON phone_voicemails;
CREATE POLICY "phone_voicemails_select" ON phone_voicemails FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_voicemails_insert" ON phone_voicemails FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_voicemails_update" ON phone_voicemails FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- phone_messages
DROP POLICY IF EXISTS "phone_messages_select" ON phone_messages;
DROP POLICY IF EXISTS "phone_messages_insert" ON phone_messages;
CREATE POLICY "phone_messages_select" ON phone_messages FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_messages_insert" ON phone_messages FOR INSERT
  WITH CHECK (company_id = requesting_company_id());

-- phone_message_templates
DROP POLICY IF EXISTS "phone_templates_select" ON phone_message_templates;
DROP POLICY IF EXISTS "phone_templates_insert" ON phone_message_templates;
DROP POLICY IF EXISTS "phone_templates_update" ON phone_message_templates;
DROP POLICY IF EXISTS "phone_templates_delete" ON phone_message_templates;
CREATE POLICY "phone_templates_select" ON phone_message_templates FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_templates_insert" ON phone_message_templates FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_templates_update" ON phone_message_templates FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_templates_delete" ON phone_message_templates FOR DELETE
  USING (company_id = requesting_company_id());

-- phone_faxes
DROP POLICY IF EXISTS "phone_faxes_select" ON phone_faxes;
DROP POLICY IF EXISTS "phone_faxes_insert" ON phone_faxes;
DROP POLICY IF EXISTS "phone_faxes_update" ON phone_faxes;
CREATE POLICY "phone_faxes_select" ON phone_faxes FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "phone_faxes_insert" ON phone_faxes FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "phone_faxes_update" ON phone_faxes FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- ============================================================
-- PART 2: Replace subquery RLS on meeting tables (5 tables)
-- Source: 20260208000034_f3a_meeting_rooms.sql
-- ============================================================

-- meeting_booking_types
DROP POLICY IF EXISTS "booking_types_select" ON meeting_booking_types;
DROP POLICY IF EXISTS "booking_types_insert" ON meeting_booking_types;
DROP POLICY IF EXISTS "booking_types_update" ON meeting_booking_types;
DROP POLICY IF EXISTS "booking_types_delete" ON meeting_booking_types;
CREATE POLICY "booking_types_select" ON meeting_booking_types FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "booking_types_insert" ON meeting_booking_types FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "booking_types_update" ON meeting_booking_types FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "booking_types_delete" ON meeting_booking_types FOR DELETE
  USING (company_id = requesting_company_id());

-- meetings
DROP POLICY IF EXISTS "meetings_select" ON meetings;
DROP POLICY IF EXISTS "meetings_insert" ON meetings;
DROP POLICY IF EXISTS "meetings_update" ON meetings;
CREATE POLICY "meetings_select" ON meetings FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "meetings_insert" ON meetings FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "meetings_update" ON meetings FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- meeting_participants
DROP POLICY IF EXISTS "participants_select" ON meeting_participants;
DROP POLICY IF EXISTS "participants_insert" ON meeting_participants;
DROP POLICY IF EXISTS "participants_update" ON meeting_participants;
CREATE POLICY "participants_select" ON meeting_participants FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "participants_insert" ON meeting_participants FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "participants_update" ON meeting_participants FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- meeting_captures
DROP POLICY IF EXISTS "captures_select" ON meeting_captures;
DROP POLICY IF EXISTS "captures_insert" ON meeting_captures;
CREATE POLICY "captures_select" ON meeting_captures FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "captures_insert" ON meeting_captures FOR INSERT
  WITH CHECK (company_id = requesting_company_id());

-- async_videos
DROP POLICY IF EXISTS "async_videos_select" ON async_videos;
DROP POLICY IF EXISTS "async_videos_insert" ON async_videos;
DROP POLICY IF EXISTS "async_videos_update" ON async_videos;
CREATE POLICY "async_videos_select" ON async_videos FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "async_videos_insert" ON async_videos FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "async_videos_update" ON async_videos FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- ============================================================
-- PART 3: Replace subquery RLS on field toolkit tables (5 tables)
-- Source: 20260208000035_f4a_field_toolkit.sql
-- Note: team_message_reads uses user_id = auth.uid() — CORRECT, skip.
-- ============================================================

-- walkie_talkie_channels
DROP POLICY IF EXISTS "walkie_channels_select" ON walkie_talkie_channels;
DROP POLICY IF EXISTS "walkie_channels_insert" ON walkie_talkie_channels;
DROP POLICY IF EXISTS "walkie_channels_update" ON walkie_talkie_channels;
CREATE POLICY "walkie_channels_select" ON walkie_talkie_channels FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "walkie_channels_insert" ON walkie_talkie_channels FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "walkie_channels_update" ON walkie_talkie_channels FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- walkie_talkie_messages
DROP POLICY IF EXISTS "walkie_messages_select" ON walkie_talkie_messages;
DROP POLICY IF EXISTS "walkie_messages_insert" ON walkie_talkie_messages;
CREATE POLICY "walkie_messages_select" ON walkie_talkie_messages FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "walkie_messages_insert" ON walkie_talkie_messages FOR INSERT
  WITH CHECK (company_id = requesting_company_id());

-- team_messages
DROP POLICY IF EXISTS "team_messages_select" ON team_messages;
DROP POLICY IF EXISTS "team_messages_insert" ON team_messages;
DROP POLICY IF EXISTS "team_messages_update" ON team_messages;
CREATE POLICY "team_messages_select" ON team_messages FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "team_messages_insert" ON team_messages FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "team_messages_update" ON team_messages FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- inspection_templates (preserve is_system = true for SELECT)
DROP POLICY IF EXISTS "inspection_templates_select" ON inspection_templates;
DROP POLICY IF EXISTS "inspection_templates_insert" ON inspection_templates;
DROP POLICY IF EXISTS "inspection_templates_update" ON inspection_templates;
CREATE POLICY "inspection_templates_select" ON inspection_templates FOR SELECT
  USING (is_system = true OR company_id = requesting_company_id());
CREATE POLICY "inspection_templates_insert" ON inspection_templates FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "inspection_templates_update" ON inspection_templates FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- inspection_results
DROP POLICY IF EXISTS "inspection_results_select" ON inspection_results;
DROP POLICY IF EXISTS "inspection_results_insert" ON inspection_results;
DROP POLICY IF EXISTS "inspection_results_update" ON inspection_results;
CREATE POLICY "inspection_results_select" ON inspection_results FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "inspection_results_insert" ON inspection_results FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "inspection_results_update" ON inspection_results FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- ============================================================
-- PART 4: Fix payment tables
-- payment_intents SELECT still uses subquery. INSERT fixed in SEC-AUDIT-1.
-- payments SELECT uses subquery.
-- ============================================================

DROP POLICY IF EXISTS "Company members can view payment intents" ON payment_intents;
CREATE POLICY "Company members can view payment intents" ON payment_intents FOR SELECT
  USING (company_id = requesting_company_id());

DROP POLICY IF EXISTS "Company members can view payments" ON payments;
CREATE POLICY "Company members can view payments" ON payments FOR SELECT
  USING (company_id = requesting_company_id());

-- ============================================================
-- PART 5: Add company_id to walkthrough_rooms + walkthrough_photos
-- Expand-contract: add nullable → backfill → NOT NULL → new policies
-- ============================================================

-- Step 1: Add nullable company_id
ALTER TABLE walkthrough_rooms ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);
ALTER TABLE walkthrough_photos ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

-- Step 2: Backfill from parent walkthroughs
UPDATE walkthrough_rooms wr
SET company_id = w.company_id
FROM walkthroughs w
WHERE wr.walkthrough_id = w.id AND wr.company_id IS NULL;

UPDATE walkthrough_photos wp
SET company_id = w.company_id
FROM walkthroughs w
WHERE wp.walkthrough_id = w.id AND wp.company_id IS NULL;

-- Step 3: Set NOT NULL (safe — all rows backfilled, no real users yet)
ALTER TABLE walkthrough_rooms ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE walkthrough_photos ALTER COLUMN company_id SET NOT NULL;

-- Step 4: Add B-tree indexes
CREATE INDEX IF NOT EXISTS idx_walkthrough_rooms_company ON walkthrough_rooms(company_id);
CREATE INDEX IF NOT EXISTS idx_walkthrough_photos_company ON walkthrough_photos(company_id);

-- Step 5: Replace join-based policies with direct company_id policies
-- Drop existing policies from 20260214000101_fix_rls_floor_plans_walkthroughs.sql
DROP POLICY IF EXISTS "walkthrough_rooms_select" ON walkthrough_rooms;
DROP POLICY IF EXISTS "walkthrough_rooms_insert" ON walkthrough_rooms;
DROP POLICY IF EXISTS "walkthrough_rooms_update" ON walkthrough_rooms;
DROP POLICY IF EXISTS "walkthrough_rooms_delete" ON walkthrough_rooms;

CREATE POLICY "walkthrough_rooms_select" ON walkthrough_rooms FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "walkthrough_rooms_insert" ON walkthrough_rooms FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "walkthrough_rooms_update" ON walkthrough_rooms FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "walkthrough_rooms_delete" ON walkthrough_rooms FOR DELETE
  USING (company_id = requesting_company_id());

DROP POLICY IF EXISTS "walkthrough_photos_select" ON walkthrough_photos;
DROP POLICY IF EXISTS "walkthrough_photos_insert" ON walkthrough_photos;
DROP POLICY IF EXISTS "walkthrough_photos_update" ON walkthrough_photos;
DROP POLICY IF EXISTS "walkthrough_photos_delete" ON walkthrough_photos;

CREATE POLICY "walkthrough_photos_select" ON walkthrough_photos FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "walkthrough_photos_insert" ON walkthrough_photos FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "walkthrough_photos_update" ON walkthrough_photos FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "walkthrough_photos_delete" ON walkthrough_photos FOR DELETE
  USING (company_id = requesting_company_id());

-- ============================================================
-- PART 6: Add company_id to journal_entry_lines
-- Currently uses join-based RLS via journal_entries.company_id
-- ============================================================

ALTER TABLE journal_entry_lines ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

UPDATE journal_entry_lines jel
SET company_id = je.company_id
FROM journal_entries je
WHERE jel.journal_entry_id = je.id AND jel.company_id IS NULL;

ALTER TABLE journal_entry_lines ALTER COLUMN company_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_jel_company ON journal_entry_lines(company_id);

-- Replace join-based policies with direct company_id
DROP POLICY IF EXISTS "jel_select" ON journal_entry_lines;
DROP POLICY IF EXISTS "jel_insert" ON journal_entry_lines;
DROP POLICY IF EXISTS "jel_update" ON journal_entry_lines;

CREATE POLICY "jel_select" ON journal_entry_lines FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "jel_insert" ON journal_entry_lines FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "jel_update" ON journal_entry_lines FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());

-- ============================================================
-- PART 7: Add company_id to support_messages
-- support_tickets.company_id is nullable (ops portal table).
-- Add company_id for company-scoped access alongside super_admin.
-- ============================================================

ALTER TABLE support_messages ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);

UPDATE support_messages sm
SET company_id = st.company_id
FROM support_tickets st
WHERE sm.ticket_id = st.id AND sm.company_id IS NULL;

-- Keep nullable (parent is nullable)
CREATE INDEX IF NOT EXISTS idx_support_messages_company ON support_messages(company_id);

-- Add company-scoped SELECT policy (users can read messages on their own tickets)
-- Keep existing super_admin FOR ALL policy intact.
CREATE POLICY "support_messages_company_read" ON support_messages FOR SELECT
  USING (
    company_id = requesting_company_id()
    OR sender_id = auth.uid()
  );

-- Company members can INSERT messages on their own tickets
CREATE POLICY "support_messages_company_insert" ON support_messages FOR INSERT
  WITH CHECK (
    ticket_id IN (
      SELECT id FROM support_tickets
      WHERE company_id = requesting_company_id()
        OR user_id = auth.uid()
    )
  );

-- ============================================================
-- PART 8: Add RLS policies to pricing_contributions
-- Anonymized aggregate data — no company_id by design.
-- Allow authenticated users to INSERT (contribute prices) and SELECT.
-- ============================================================

CREATE POLICY "pricing_contributions_select" ON pricing_contributions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "pricing_contributions_insert" ON pricing_contributions FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================
-- PART 9: Replace FOR ALL with granular SELECT/INSERT/UPDATE/DELETE
-- Restrict DELETE to owner/admin roles only.
-- ============================================================

-- insurance_claims
DROP POLICY IF EXISTS "insurance_claims_company" ON insurance_claims;
CREATE POLICY "insurance_claims_select" ON insurance_claims FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "insurance_claims_insert" ON insurance_claims FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "insurance_claims_update" ON insurance_claims FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "insurance_claims_delete" ON insurance_claims FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- claim_supplements
DROP POLICY IF EXISTS "claim_supplements_company" ON claim_supplements;
CREATE POLICY "claim_supplements_select" ON claim_supplements FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "claim_supplements_insert" ON claim_supplements FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "claim_supplements_update" ON claim_supplements FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "claim_supplements_delete" ON claim_supplements FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- employee_records
DROP POLICY IF EXISTS "employee_records_company" ON employee_records;
CREATE POLICY "employee_records_select" ON employee_records FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "employee_records_insert" ON employee_records FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "employee_records_update" ON employee_records FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "employee_records_delete" ON employee_records FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- vehicles
DROP POLICY IF EXISTS "vehicles_company" ON vehicles;
CREATE POLICY "vehicles_select" ON vehicles FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "vehicles_insert" ON vehicles FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "vehicles_update" ON vehicles FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "vehicles_delete" ON vehicles FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- fuel_logs
DROP POLICY IF EXISTS "fuel_logs_company" ON fuel_logs;
CREATE POLICY "fuel_logs_select" ON fuel_logs FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "fuel_logs_insert" ON fuel_logs FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "fuel_logs_update" ON fuel_logs FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "fuel_logs_delete" ON fuel_logs FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- email_campaigns
DROP POLICY IF EXISTS "email_campaigns_company" ON email_campaigns;
CREATE POLICY "email_campaigns_select" ON email_campaigns FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "email_campaigns_insert" ON email_campaigns FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "email_campaigns_update" ON email_campaigns FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "email_campaigns_delete" ON email_campaigns FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- pay_periods
DROP POLICY IF EXISTS "pay_periods_company" ON pay_periods;
CREATE POLICY "pay_periods_select" ON pay_periods FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "pay_periods_insert" ON pay_periods FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "pay_periods_update" ON pay_periods FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "pay_periods_delete" ON pay_periods FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- payroll_tax_configs
DROP POLICY IF EXISTS "payroll_tax_company" ON payroll_tax_configs;
CREATE POLICY "payroll_tax_select" ON payroll_tax_configs FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "payroll_tax_insert" ON payroll_tax_configs FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "payroll_tax_update" ON payroll_tax_configs FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "payroll_tax_delete" ON payroll_tax_configs FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- marketplace_leads — already has separate SELECT/INSERT policies
-- Add UPDATE + DELETE (restrict to owner/admin)
DROP POLICY IF EXISTS "leads_public" ON marketplace_leads;
DROP POLICY IF EXISTS "leads_insert" ON marketplace_leads;
CREATE POLICY "leads_select" ON marketplace_leads FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "leads_insert" ON marketplace_leads FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "leads_update" ON marketplace_leads FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "leads_delete" ON marketplace_leads FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- marketplace_bids
DROP POLICY IF EXISTS "bids_company" ON marketplace_bids;
DROP POLICY IF EXISTS "bids_lead_owner" ON marketplace_bids;
CREATE POLICY "bids_select" ON marketplace_bids FOR SELECT
  USING (company_id = requesting_company_id());
CREATE POLICY "bids_select_lead_owner" ON marketplace_bids FOR SELECT
  USING (
    lead_id IN (
      SELECT id FROM marketplace_leads WHERE company_id = requesting_company_id()
    )
  );
CREATE POLICY "bids_insert" ON marketplace_bids FOR INSERT
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "bids_update" ON marketplace_bids FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "bids_delete" ON marketplace_bids FOR DELETE
  USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

-- ============================================================
-- PART 10: Verify auth helper function stability
-- requesting_company_id() already STABLE in 20260206000001_a3a_core_tables.sql
-- requesting_user_role() already STABLE in same file
-- Re-assert STABLE for safety (idempotent)
-- ============================================================

CREATE OR REPLACE FUNCTION public.requesting_company_id() RETURNS uuid AS $$
  SELECT (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION public.requesting_user_role() RETURNS text AS $$
  SELECT auth.jwt() -> 'app_metadata' ->> 'role';
$$ LANGUAGE sql STABLE;
