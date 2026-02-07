-- D5j Seed Data: Property Management
-- Run manually via Supabase SQL editor or supabase db execute

-- Use first company and user from existing seed data
DO $$
DECLARE
  v_company_id uuid;
  v_user_id uuid;
  v_prop1_id uuid := gen_random_uuid();
  v_prop2_id uuid := gen_random_uuid();
  v_unit1_id uuid := gen_random_uuid();
  v_unit2_id uuid := gen_random_uuid();
  v_unit3_id uuid := gen_random_uuid();
  v_tenant1_id uuid := gen_random_uuid();
  v_tenant2_id uuid := gen_random_uuid();
  v_tenant3_id uuid := gen_random_uuid();
  v_lease1_id uuid := gen_random_uuid();
  v_lease2_id uuid := gen_random_uuid();
  v_lease3_id uuid := gen_random_uuid();
  v_maint1_id uuid := gen_random_uuid();
  v_maint2_id uuid := gen_random_uuid();
  v_maint3_id uuid := gen_random_uuid();
  v_maint4_id uuid := gen_random_uuid();
  v_maint5_id uuid := gen_random_uuid();
  v_insp1_id uuid := gen_random_uuid();
  v_insp2_id uuid := gen_random_uuid();
  v_asset1_id uuid := gen_random_uuid();
  v_asset2_id uuid := gen_random_uuid();
  v_asset3_id uuid := gen_random_uuid();
  v_asset4_id uuid := gen_random_uuid();
  v_asset5_id uuid := gen_random_uuid();
  v_asset6_id uuid := gen_random_uuid();
  v_charge1_id uuid := gen_random_uuid();
  v_charge2_id uuid := gen_random_uuid();
  v_charge3_id uuid := gen_random_uuid();
BEGIN
  SELECT id INTO v_company_id FROM public.companies LIMIT 1;
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  IF v_company_id IS NULL THEN
    RAISE NOTICE 'No company found — skipping PM seed data';
    RETURN;
  END IF;

  -- 2 Properties: duplex + single-family
  INSERT INTO properties (id, company_id, name, address, city, state, zip_code, property_type, created_by_user_id) VALUES
    (v_prop1_id, v_company_id, 'Oak Street Duplex', '456 Oak Street', 'Austin', 'TX', '78702', 'multi_family', v_user_id),
    (v_prop2_id, v_company_id, 'Elm House', '789 Elm Avenue', 'Austin', 'TX', '78703', 'single_family', v_user_id);

  -- 3 Units (2 in duplex, 1 in single-family)
  INSERT INTO units (id, property_id, company_id, unit_number, bedrooms, bathrooms, square_feet, status) VALUES
    (v_unit1_id, v_prop1_id, v_company_id, 'A', 2, 1, 850, 'occupied'),
    (v_unit2_id, v_prop1_id, v_company_id, 'B', 2, 1, 900, 'occupied'),
    (v_unit3_id, v_prop2_id, v_company_id, '1', 3, 2, 1400, 'occupied');

  -- 3 Tenants
  INSERT INTO tenants (id, company_id, name, email, phone, emergency_contact_name, emergency_contact_phone) VALUES
    (v_tenant1_id, v_company_id, 'Maria Garcia', 'maria@example.com', '512-555-0101', 'Carlos Garcia', '512-555-0102'),
    (v_tenant2_id, v_company_id, 'James Wilson', 'james@example.com', '512-555-0201', 'Sarah Wilson', '512-555-0202'),
    (v_tenant3_id, v_company_id, 'Emily Chen', 'emily@example.com', '512-555-0301', 'David Chen', '512-555-0302');

  -- 3 Active Leases
  INSERT INTO leases (id, company_id, property_id, unit_id, tenant_id, lease_type, start_date, end_date, monthly_rent, security_deposit, rent_due_day, grace_period_days, late_fee_amount, status) VALUES
    (v_lease1_id, v_company_id, v_prop1_id, v_unit1_id, v_tenant1_id, 'fixed', '2025-09-01', '2026-08-31', 1200, 1200, 1, 5, 50, 'active'),
    (v_lease2_id, v_company_id, v_prop1_id, v_unit2_id, v_tenant2_id, 'fixed', '2025-06-01', '2026-05-31', 1300, 1300, 1, 5, 75, 'active'),
    (v_lease3_id, v_company_id, v_prop2_id, v_unit3_id, v_tenant3_id, 'month_to_month', '2025-01-01', NULL, 1800, 1800, 1, 3, 100, 'active');

  -- 5 Maintenance Requests (various statuses)
  INSERT INTO maintenance_requests (id, company_id, property_id, unit_id, tenant_id, title, description, category, urgency, status, assigned_user_ids) VALUES
    (v_maint1_id, v_company_id, v_prop1_id, v_unit1_id, v_tenant1_id, 'Leaky kitchen faucet', 'Kitchen faucet drips constantly', 'plumbing', 'normal', 'new', ARRAY[v_user_id]),
    (v_maint2_id, v_company_id, v_prop1_id, v_unit2_id, v_tenant2_id, 'AC not cooling', 'Central AC blowing warm air since yesterday', 'hvac', 'high', 'in_progress', ARRAY[v_user_id]),
    (v_maint3_id, v_company_id, v_prop2_id, v_unit3_id, v_tenant3_id, 'Garage door stuck', 'Garage door won''t open past halfway', 'general', 'normal', 'assigned', ARRAY[v_user_id]),
    (v_maint4_id, v_company_id, v_prop1_id, v_unit1_id, v_tenant1_id, 'Replace smoke detector batteries', 'Annual battery replacement needed', 'safety', 'low', 'completed', ARRAY[v_user_id]),
    (v_maint5_id, v_company_id, v_prop2_id, v_unit3_id, v_tenant3_id, 'Water heater making noise', 'Banging sound from water heater', 'plumbing', 'emergency', 'new', ARRAY[v_user_id]);

  -- 2 Inspections
  INSERT INTO pm_inspections (id, company_id, property_id, unit_id, inspection_type, status, scheduled_date, inspector_user_id) VALUES
    (v_insp1_id, v_company_id, v_prop1_id, v_unit1_id, 'move_in', 'completed', '2025-08-28', v_user_id),
    (v_insp2_id, v_company_id, v_prop2_id, v_unit3_id, 'annual', 'scheduled', '2026-03-15', v_user_id);

  -- 6 Assets (HVAC + water heater per unit)
  INSERT INTO property_assets (id, company_id, property_id, unit_id, asset_type, brand, model, serial_number, install_date, condition, last_service_date, next_service_date) VALUES
    (v_asset1_id, v_company_id, v_prop1_id, v_unit1_id, 'hvac', 'Carrier', 'Comfort 24ACC636', 'CR-2021-4456', '2021-06-15', 'good', '2025-06-15', '2026-06-15'),
    (v_asset2_id, v_company_id, v_prop1_id, v_unit1_id, 'water_heater', 'Rheem', 'Performance Plus 50', 'RH-2020-7891', '2020-03-10', 'fair', '2025-03-10', '2026-03-10'),
    (v_asset3_id, v_company_id, v_prop1_id, v_unit2_id, 'hvac', 'Trane', 'XR15', 'TR-2022-1234', '2022-04-20', 'good', '2025-10-01', '2026-10-01'),
    (v_asset4_id, v_company_id, v_prop1_id, v_unit2_id, 'water_heater', 'AO Smith', 'Signature 40', 'AO-2019-5678', '2019-11-05', 'fair', '2025-05-05', '2026-05-05'),
    (v_asset5_id, v_company_id, v_prop2_id, v_unit3_id, 'hvac', 'Lennox', 'Elite XC21', 'LN-2023-9012', '2023-01-15', 'excellent', '2025-07-15', '2026-07-15'),
    (v_asset6_id, v_company_id, v_prop2_id, v_unit3_id, 'water_heater', 'Bradford White', 'Defender 50', 'BW-2021-3456', '2021-08-22', 'good', '2025-08-22', '2026-08-22');

  -- 3 Asset Service Records
  INSERT INTO asset_service_records (asset_id, company_id, service_type, service_date, description, cost, performed_by) VALUES
    (v_asset1_id, v_company_id, 'maintenance', '2025-06-15', 'Annual HVAC tune-up and filter replacement', 150.00, 'Owner'),
    (v_asset2_id, v_company_id, 'repair', '2025-03-10', 'Replaced anode rod and flushed tank', 275.00, 'ABC Plumbing'),
    (v_asset5_id, v_company_id, 'maintenance', '2025-07-15', 'Summer HVAC inspection and coolant check', 175.00, 'Owner');

  -- Rent charges for current month
  INSERT INTO rent_charges (id, company_id, property_id, unit_id, tenant_id, lease_id, charge_type, amount, due_date, status, billing_period_start, billing_period_end) VALUES
    (v_charge1_id, v_company_id, v_prop1_id, v_unit1_id, v_tenant1_id, v_lease1_id, 'rent', 1200, '2026-02-01', 'paid', '2026-02-01', '2026-02-28'),
    (v_charge2_id, v_company_id, v_prop1_id, v_unit2_id, v_tenant2_id, v_lease2_id, 'rent', 1300, '2026-02-01', 'pending', '2026-02-01', '2026-02-28'),
    (v_charge3_id, v_company_id, v_prop2_id, v_unit3_id, v_tenant3_id, v_lease3_id, 'rent', 1800, '2026-01-01', 'overdue', '2026-01-01', '2026-01-31');

  -- 1 Rent payment (for charge 1)
  INSERT INTO rent_payments (company_id, rent_charge_id, tenant_id, amount, payment_method, status, paid_at) VALUES
    (v_company_id, v_charge1_id, v_tenant1_id, 1200, 'bank_transfer', 'completed', '2026-02-01T10:00:00Z');

  -- Update charge1 as paid
  UPDATE rent_charges SET paid_amount = 1200, paid_at = '2026-02-01T10:00:00Z' WHERE id = v_charge1_id;

  RAISE NOTICE 'PM seed data inserted: 2 properties, 3 units, 3 tenants, 3 leases, 5 maintenance requests, 2 inspections, 6 assets, 3 service records, 3 rent charges, 1 payment';
END $$;
