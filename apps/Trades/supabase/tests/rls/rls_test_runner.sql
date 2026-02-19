-- ZAFTO — RLS Test Runner
-- Tests cross-company data isolation and role-based access control
-- Run against local Supabase: psql -h localhost -p 54322 -U postgres -d postgres -f rls_test_runner.sql
--
-- Prerequisites: seed.sql must have been applied (npx supabase db reset)
--
-- Test companies:
--   Company 1 (11111111-...) — 5 users (owner, admin, tech, apprentice, cpa)
--   Company 2 (22222222-...) — 1 user (realtor owner)
--   Company 3 (33333333-...) — 1 user (inspector owner)
--   Company 4 (44444444-...) — 1 user (solo plumber owner)

-- ============================================================
-- HELPER: Set JWT claims to simulate a specific user
-- ============================================================
CREATE OR REPLACE FUNCTION test_set_claims(p_user_id uuid, p_company_id uuid, p_role text)
RETURNS void AS $$
BEGIN
  -- Set the JWT claims that RLS policies read
  PERFORM set_config('request.jwt.claims', json_build_object(
    'sub', p_user_id::text,
    'app_metadata', json_build_object(
      'company_id', p_company_id::text,
      'role', p_role
    )
  )::text, true);
  -- Also set auth.uid() for policies that use it
  PERFORM set_config('request.jwt.claim.sub', p_user_id::text, true);
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TEST RESULTS TABLE (temporary)
-- ============================================================
DROP TABLE IF EXISTS _rls_test_results;
CREATE TEMP TABLE _rls_test_results (
  test_name text NOT NULL,
  passed boolean NOT NULL,
  details text,
  tested_at timestamptz DEFAULT now()
);

-- ============================================================
-- HELPER: Record test result
-- ============================================================
CREATE OR REPLACE FUNCTION test_assert(p_name text, p_condition boolean, p_details text DEFAULT NULL)
RETURNS void AS $$
BEGIN
  INSERT INTO _rls_test_results (test_name, passed, details)
  VALUES (p_name, p_condition, COALESCE(p_details, CASE WHEN p_condition THEN 'OK' ELSE 'FAILED' END));
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TEST 1: Company isolation — Company 1 owner cannot see Company 2 data
-- ============================================================
DO $$
DECLARE
  v_count int;
BEGIN
  -- Set claims to Company 1 owner
  PERFORM test_set_claims(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'owner'
  );

  -- Should see own company
  SELECT count(*) INTO v_count FROM companies;
  PERFORM test_assert('Company 1 owner sees own company', v_count = 1, 'Found ' || v_count || ' companies');

  -- Should see own users (5 in company 1)
  SELECT count(*) INTO v_count FROM users;
  PERFORM test_assert('Company 1 owner sees own users', v_count = 5, 'Found ' || v_count || ' users');

  -- Should see own customers
  SELECT count(*) INTO v_count FROM customers WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 1 owner sees own customers', v_count = 2, 'Found ' || v_count || ' customers');

  -- Should see own jobs
  SELECT count(*) INTO v_count FROM jobs WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 1 owner sees own jobs', v_count = 2, 'Found ' || v_count || ' jobs');

  -- Should see own estimates
  SELECT count(*) INTO v_count FROM estimates WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 1 owner sees own estimates', v_count >= 1, 'Found ' || v_count || ' estimates');

  -- Should see own invoices
  SELECT count(*) INTO v_count FROM invoices WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 1 owner sees own invoices', v_count >= 1, 'Found ' || v_count || ' invoices');
END $$;

-- ============================================================
-- TEST 2: Company 2 (realtor) cannot see Company 1 data
-- ============================================================
DO $$
DECLARE
  v_count int;
BEGIN
  PERFORM test_set_claims(
    'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'owner'
  );

  -- Should see ONLY Company 2
  SELECT count(*) INTO v_count FROM companies;
  PERFORM test_assert('Company 2 owner sees only own company', v_count = 1, 'Found ' || v_count);

  -- Should NOT see Company 1's users
  SELECT count(*) INTO v_count FROM users;
  PERFORM test_assert('Company 2 cannot see Company 1 users', v_count = 1, 'Found ' || v_count || ' (should be 1, the realtor)');

  -- Should NOT see Company 1's customers
  SELECT count(*) INTO v_count FROM customers WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 2 cannot see Company 1 customers', v_count = 0, 'Found ' || v_count);

  -- Should NOT see Company 1's jobs
  SELECT count(*) INTO v_count FROM jobs WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 2 cannot see Company 1 jobs', v_count = 0, 'Found ' || v_count);

  -- Should NOT see Company 1's estimates
  SELECT count(*) INTO v_count FROM estimates WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 2 cannot see Company 1 estimates', v_count = 0, 'Found ' || v_count);

  -- Should NOT see Company 1's invoices
  SELECT count(*) INTO v_count FROM invoices WHERE deleted_at IS NULL;
  PERFORM test_assert('Company 2 cannot see Company 1 invoices', v_count = 0, 'Found ' || v_count);
END $$;

-- ============================================================
-- TEST 3: Solo plumber (Company 4) total isolation
-- ============================================================
DO $$
DECLARE
  v_count int;
BEGIN
  PERFORM test_set_claims(
    '66666666-7777-8888-9999-aaaaaaaaaaaa'::uuid,
    '44444444-4444-4444-4444-444444444444'::uuid,
    'owner'
  );

  SELECT count(*) INTO v_count FROM companies;
  PERFORM test_assert('Solo plumber sees only own company', v_count = 1, 'Found ' || v_count);

  SELECT count(*) INTO v_count FROM users;
  PERFORM test_assert('Solo plumber sees only self', v_count = 1, 'Found ' || v_count);

  SELECT count(*) INTO v_count FROM customers WHERE deleted_at IS NULL;
  PERFORM test_assert('Solo plumber has no cross-company customer leaks', v_count = 0, 'Found ' || v_count);

  SELECT count(*) INTO v_count FROM jobs WHERE deleted_at IS NULL;
  PERFORM test_assert('Solo plumber has no cross-company job leaks', v_count = 0, 'Found ' || v_count);
END $$;

-- ============================================================
-- TEST 4: Role restrictions — technician cannot delete customers
-- ============================================================
DO $$
DECLARE
  v_count int;
BEGIN
  PERFORM test_set_claims(
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'technician'
  );

  -- Technician CAN see customers (SELECT allowed for all company roles)
  SELECT count(*) INTO v_count FROM customers WHERE deleted_at IS NULL;
  PERFORM test_assert('Technician can read customers', v_count = 2, 'Found ' || v_count);

  -- Technician CANNOT delete customers (DELETE restricted to owner/admin)
  BEGIN
    DELETE FROM customers WHERE id = 'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1';
    -- If we got here, the delete was allowed (unexpected)
    PERFORM test_assert('Technician blocked from deleting customers', false, 'DELETE was allowed — RLS gap!');
    -- Rollback the delete
    RAISE EXCEPTION 'rollback_test';
  EXCEPTION
    WHEN insufficient_privilege THEN
      PERFORM test_assert('Technician blocked from deleting customers', true, 'RLS correctly blocked DELETE');
    WHEN OTHERS THEN
      IF SQLERRM = 'rollback_test' THEN
        NULL; -- test already recorded
      ELSE
        PERFORM test_assert('Technician blocked from deleting customers', false, 'Unexpected error: ' || SQLERRM);
      END IF;
  END;
END $$;

-- ============================================================
-- TEST 5: Audit log isolation
-- ============================================================
DO $$
DECLARE
  v_count_c1 int;
  v_count_c2 int;
BEGIN
  -- Company 1 audit
  PERFORM test_set_claims(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'owner'
  );
  SELECT count(*) INTO v_count_c1 FROM audit_log;

  -- Company 2 audit
  PERFORM test_set_claims(
    'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'owner'
  );
  SELECT count(*) INTO v_count_c2 FROM audit_log;

  -- Company 2 should NOT see Company 1's audit entries
  PERFORM test_assert('Audit log isolated between companies',
    v_count_c2 = 0 OR v_count_c1 != v_count_c2,
    'C1 audit: ' || v_count_c1 || ', C2 audit: ' || v_count_c2
  );
END $$;

-- ============================================================
-- RESULTS REPORT
-- ============================================================
SELECT
  CASE WHEN passed THEN 'PASS' ELSE '** FAIL **' END AS status,
  test_name,
  details
FROM _rls_test_results
ORDER BY tested_at;

-- Summary
SELECT
  count(*) FILTER (WHERE passed) AS passed,
  count(*) FILTER (WHERE NOT passed) AS failed,
  count(*) AS total,
  CASE WHEN count(*) FILTER (WHERE NOT passed) = 0
    THEN 'ALL TESTS PASSED'
    ELSE count(*) FILTER (WHERE NOT passed) || ' TESTS FAILED'
  END AS summary
FROM _rls_test_results;

-- Cleanup
DROP FUNCTION IF EXISTS test_set_claims(uuid, uuid, text);
DROP FUNCTION IF EXISTS test_assert(text, boolean, text);
