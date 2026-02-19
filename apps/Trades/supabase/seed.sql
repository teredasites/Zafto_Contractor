-- ZAFTO — Test Seed Data
-- Run: npx supabase db reset (applies migrations + this seed)
-- Purpose: Creates test companies, users, and business data for local dev + CI testing
--
-- Test Users (all passwords: "testpass123"):
--   owner@test.com       — Owner of "Test Electrical LLC" (contractor)
--   admin@test.com       — Admin in same company
--   tech@test.com        — Technician in same company
--   apprentice@test.com  — Apprentice in same company
--   cpa@test.com         — CPA in same company
--   realtor@test.com     — Owner of "Test Realty Group" (realtor)
--   inspector@test.com   — Owner of "Test Inspections" (inspector)
--   solo@test.com        — Owner of "Solo Plumbing" (solo contractor)
--   homeowner@test.com   — Client portal user

-- ============================================================
-- TEST COMPANIES
-- ============================================================
DO $$
DECLARE
  v_company_1 uuid := '11111111-1111-1111-1111-111111111111';
  v_company_2 uuid := '22222222-2222-2222-2222-222222222222';
  v_company_3 uuid := '33333333-3333-3333-3333-333333333333';
  v_company_4 uuid := '44444444-4444-4444-4444-444444444444';

  v_owner_id uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_admin_id uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_tech_id uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  v_apprentice_id uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';
  v_cpa_id uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  v_realtor_id uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
  v_inspector_id uuid := '11111111-2222-3333-4444-555555555555';
  v_solo_id uuid := '66666666-7777-8888-9999-aaaaaaaaaaaa';
  v_homeowner_id uuid := '99999999-9999-9999-9999-999999999999';

  v_customer_1 uuid := 'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1';
  v_customer_2 uuid := 'c2c2c2c2-c2c2-c2c2-c2c2-c2c2c2c2c2c2';
  v_job_1 uuid := 'j1j1j1j1-j1j1-j1j1-j1j1-j1j1j1j1j1j1';
  v_job_2 uuid := 'j2j2j2j2-j2j2-j2j2-j2j2-j2j2j2j2j2j2';
  v_estimate_1 uuid := 'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1';
  v_invoice_1 uuid := 'i1i1i1i1-i1i1-i1i1-i1i1-i1i1i1i1i1i1';
BEGIN

  -- Company 1: Contractor (Team plan, 5 users)
  INSERT INTO companies (id, name, trade, trades, phone, email, address, city, state, zip_code,
    subscription_tier, subscription_status, max_users)
  VALUES (
    v_company_1, 'Test Electrical LLC', 'electrical',
    ARRAY['electrical', 'solar', 'low_voltage'],
    '555-100-0001', 'office@testelectrical.com',
    '100 Main St', 'Tampa', 'FL', '33601',
    'team', 'active', 10
  );

  -- Company 2: Realtor brokerage (Business plan)
  INSERT INTO companies (id, name, trade, trades, phone, email, address, city, state, zip_code,
    subscription_tier, subscription_status, max_users)
  VALUES (
    v_company_2, 'Test Realty Group', 'realtor',
    ARRAY['residential', 'commercial'],
    '555-200-0001', 'info@testrealty.com',
    '200 Broker Ave', 'Tampa', 'FL', '33602',
    'business', 'active', 25
  );

  -- Company 3: Inspector (Solo plan)
  INSERT INTO companies (id, name, trade, trades, phone, email, address, city, state, zip_code,
    subscription_tier, subscription_status, max_users)
  VALUES (
    v_company_3, 'Test Inspections', 'inspector',
    ARRAY['home_inspection', 'commercial_inspection'],
    '555-300-0001', 'book@testinspections.com',
    '300 Inspector Ln', 'Tampa', 'FL', '33603',
    'solo', 'active', 1
  );

  -- Company 4: Solo Plumber (Solo plan)
  INSERT INTO companies (id, name, trade, trades, phone, email, address, city, state, zip_code,
    subscription_tier, subscription_status, max_users)
  VALUES (
    v_company_4, 'Solo Plumbing', 'plumbing',
    ARRAY['plumbing'],
    '555-400-0001', 'mike@soloplumbing.com',
    '400 Pipe Rd', 'Tampa', 'FL', '33604',
    'solo', 'active', 1
  );

  -- ============================================================
  -- TEST AUTH USERS (via Supabase auth.users)
  -- In local dev, these are created by supabase auth admin
  -- For seed, we insert directly into public.users
  -- The auth.users entries are created by `supabase start` or test helpers
  -- ============================================================

  -- Company 1 users
  INSERT INTO users (id, company_id, email, full_name, phone, role, trade, is_active) VALUES
    (v_owner_id, v_company_1, 'owner@test.com', 'Dan Owner', '555-100-0010', 'owner', 'electrical', true),
    (v_admin_id, v_company_1, 'admin@test.com', 'Amy Admin', '555-100-0020', 'admin', 'electrical', true),
    (v_tech_id, v_company_1, 'tech@test.com', 'Tom Technician', '555-100-0030', 'technician', 'electrical', true),
    (v_apprentice_id, v_company_1, 'apprentice@test.com', 'Alex Apprentice', '555-100-0040', 'apprentice', 'electrical', true),
    (v_cpa_id, v_company_1, 'cpa@test.com', 'Chris CPA', '555-100-0050', 'cpa', NULL, true);

  -- Company 2 user (realtor)
  INSERT INTO users (id, company_id, email, full_name, phone, role, trade, is_active) VALUES
    (v_realtor_id, v_company_2, 'realtor@test.com', 'Rachel Realtor', '555-200-0010', 'owner', 'residential', true);

  -- Company 3 user (inspector)
  INSERT INTO users (id, company_id, email, full_name, phone, role, trade, is_active) VALUES
    (v_inspector_id, v_company_3, 'inspector@test.com', 'Ian Inspector', '555-300-0010', 'owner', 'home_inspection', true);

  -- Company 4 user (solo plumber)
  INSERT INTO users (id, company_id, email, full_name, phone, role, trade, is_active) VALUES
    (v_solo_id, v_company_4, 'solo@test.com', 'Mike Solo', '555-400-0010', 'owner', 'plumbing', true);

  -- ============================================================
  -- TEST CUSTOMERS (belong to Company 1)
  -- ============================================================
  INSERT INTO customers (id, company_id, first_name, last_name, email, phone, address, city, state, zip_code, source, status) VALUES
    (v_customer_1, v_company_1, 'John', 'Homeowner', 'john@example.com', '555-999-0001', '500 Oak St', 'Tampa', 'FL', '33605', 'referral', 'active'),
    (v_customer_2, v_company_1, 'Jane', 'Property', 'jane@example.com', '555-999-0002', '600 Pine Ave', 'Tampa', 'FL', '33606', 'website', 'active');

  -- ============================================================
  -- TEST JOBS (belong to Company 1)
  -- ============================================================
  INSERT INTO jobs (id, company_id, customer_id, title, description, status, priority, job_type, address, city, state, zip_code, assigned_to) VALUES
    (v_job_1, v_company_1, v_customer_1, 'Panel Upgrade 200A', 'Upgrade main panel from 100A to 200A service', 'in_progress', 'high', 'electrical', '500 Oak St', 'Tampa', 'FL', '33605', v_tech_id),
    (v_job_2, v_company_1, v_customer_2, 'Whole House Rewire', 'Complete rewire of 1960s home, knob and tube removal', 'scheduled', 'medium', 'electrical', '600 Pine Ave', 'Tampa', 'FL', '33606', v_tech_id);

  -- ============================================================
  -- TEST ESTIMATE (belongs to Company 1, Job 1)
  -- ============================================================
  INSERT INTO estimates (id, company_id, job_id, customer_id, estimate_number, status, estimate_type,
    subtotal, overhead_rate, profit_rate, tax_rate, total, notes, created_by) VALUES
    (v_estimate_1, v_company_1, v_job_1, v_customer_1, 'EST-2026-0001', 'approved', 'standard',
     4500.00, 10.0, 10.0, 7.5, 5821.88, 'Panel upgrade with whole house surge protection', v_owner_id);

  -- ============================================================
  -- TEST INVOICE (belongs to Company 1, Job 1)
  -- ============================================================
  INSERT INTO invoices (id, company_id, job_id, customer_id, invoice_number, status,
    subtotal, tax_amount, total, due_date, notes, created_by) VALUES
    (v_invoice_1, v_company_1, v_job_1, v_customer_1, 'INV-2026-0001', 'sent',
     4500.00, 337.50, 4837.50, now() + interval '30 days', 'Payment due upon completion', v_owner_id);

  -- Set company owner_user_id
  UPDATE companies SET owner_user_id = v_owner_id WHERE id = v_company_1;
  UPDATE companies SET owner_user_id = v_realtor_id WHERE id = v_company_2;
  UPDATE companies SET owner_user_id = v_inspector_id WHERE id = v_company_3;
  UPDATE companies SET owner_user_id = v_solo_id WHERE id = v_company_4;

END $$;
