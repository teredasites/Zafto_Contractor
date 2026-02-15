-- Migration: Fix RLS policies that use broken subquery pattern
-- The users table has its own RLS, so subquerying into it from other
-- RLS policies causes recursion/permission issues.
-- Fix: use requesting_company_id() which reads directly from JWT.

BEGIN;

-- =========================================================================
-- 1. property_floor_plans — Fix from users subquery to JWT-based
-- =========================================================================
DROP POLICY IF EXISTS floor_plans_company ON property_floor_plans;

CREATE POLICY floor_plans_select ON property_floor_plans
  FOR SELECT USING (company_id = requesting_company_id());

CREATE POLICY floor_plans_insert ON property_floor_plans
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE POLICY floor_plans_update ON property_floor_plans
  FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY floor_plans_delete ON property_floor_plans
  FOR DELETE USING (company_id = requesting_company_id());

-- =========================================================================
-- 2. walkthroughs — Fix from users subquery to JWT-based
-- =========================================================================
DROP POLICY IF EXISTS walkthroughs_company ON walkthroughs;

CREATE POLICY walkthroughs_select ON walkthroughs
  FOR SELECT USING (company_id = requesting_company_id());

CREATE POLICY walkthroughs_insert ON walkthroughs
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE POLICY walkthroughs_update ON walkthroughs
  FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY walkthroughs_delete ON walkthroughs
  FOR DELETE USING (company_id = requesting_company_id());

-- =========================================================================
-- 3. walkthrough_rooms — Fix nested subquery (walkthroughs → users)
--    Replace users subquery with requesting_company_id() on walkthroughs
-- =========================================================================
DROP POLICY IF EXISTS walkthrough_rooms_via_walkthrough ON walkthrough_rooms;

CREATE POLICY walkthrough_rooms_via_walkthrough ON walkthrough_rooms
  FOR ALL USING (
    walkthrough_id IN (
      SELECT id FROM walkthroughs WHERE company_id = requesting_company_id()
    )
  );

-- =========================================================================
-- 4. walkthrough_photos — Fix nested subquery (walkthroughs → users)
-- =========================================================================
DROP POLICY IF EXISTS walkthrough_photos_via_walkthrough ON walkthrough_photos;

CREATE POLICY walkthrough_photos_via_walkthrough ON walkthrough_photos
  FOR ALL USING (
    walkthrough_id IN (
      SELECT id FROM walkthroughs WHERE company_id = requesting_company_id()
    )
  );

-- =========================================================================
-- 5. walkthrough_templates — Fix subquery, preserve is_system access
-- =========================================================================
DROP POLICY IF EXISTS walkthrough_templates_access ON walkthrough_templates;

CREATE POLICY walkthrough_templates_access ON walkthrough_templates
  FOR ALL USING (
    is_system = true OR company_id = requesting_company_id()
  );

COMMIT;
