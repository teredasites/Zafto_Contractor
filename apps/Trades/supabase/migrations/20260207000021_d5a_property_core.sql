-- D5a: Core Property Management Tables (Migration 1 of 3)
-- Tables: properties, units, tenants, leases, lease_documents, rent_charges, rent_payments
-- + ALTER companies (features JSONB)

-- 1. Properties
CREATE TABLE properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  address_line1 text NOT NULL,
  address_line2 text,
  city text NOT NULL,
  state text NOT NULL,
  zip text NOT NULL,
  country text NOT NULL DEFAULT 'US',
  property_type text NOT NULL CHECK (property_type IN ('single_family', 'duplex', 'triplex', 'quadplex', 'multi_unit', 'commercial', 'mixed_use')),
  unit_count integer NOT NULL DEFAULT 1,
  year_built integer,
  square_footage integer,
  lot_size text,
  purchase_date date,
  purchase_price numeric(12,2),
  current_value numeric(12,2),
  mortgage_lender text,
  mortgage_rate numeric(5,3),
  mortgage_payment numeric(10,2),
  mortgage_escrow numeric(10,2),
  mortgage_principal_balance numeric(12,2),
  insurance_carrier text,
  insurance_policy_number text,
  insurance_premium numeric(10,2),
  insurance_expiry date,
  property_tax_annual numeric(10,2),
  notes text,
  photos jsonb DEFAULT '[]',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'sold', 'rehab')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_properties_company ON properties(company_id) WHERE deleted_at IS NULL;

-- 2. Units
CREATE TABLE units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_number text NOT NULL,
  bedrooms integer NOT NULL DEFAULT 1,
  bathrooms numeric(3,1) NOT NULL DEFAULT 1,
  square_footage integer,
  floor_level integer,
  amenities jsonb DEFAULT '[]',
  market_rent numeric(10,2),
  photos jsonb DEFAULT '[]',
  notes text,
  status text NOT NULL DEFAULT 'vacant' CHECK (status IN ('vacant', 'occupied', 'maintenance', 'listed', 'unit_turn', 'rehab')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE UNIQUE INDEX idx_units_property_number ON units(property_id, unit_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_units_company ON units(company_id) WHERE deleted_at IS NULL;

-- 3. Tenants
CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  auth_user_id uuid REFERENCES auth.users(id),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text,
  phone text,
  date_of_birth date,
  emergency_contact_name text,
  emergency_contact_phone text,
  employer text,
  monthly_income numeric(10,2),
  vehicle_info jsonb,
  pet_info jsonb,
  notes text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('applicant', 'active', 'past', 'evicted')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_tenants_company ON tenants(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tenants_email ON tenants(email) WHERE email IS NOT NULL AND deleted_at IS NULL;

-- 4. Leases
CREATE TABLE leases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  lease_type text NOT NULL DEFAULT 'fixed' CHECK (lease_type IN ('fixed', 'month_to_month')),
  start_date date NOT NULL,
  end_date date,
  rent_amount numeric(10,2) NOT NULL,
  rent_due_day integer NOT NULL DEFAULT 1 CHECK (rent_due_day BETWEEN 1 AND 28),
  deposit_amount numeric(10,2) DEFAULT 0,
  deposit_held boolean DEFAULT true,
  grace_period_days integer NOT NULL DEFAULT 5,
  late_fee_type text NOT NULL DEFAULT 'flat' CHECK (late_fee_type IN ('flat', 'percentage', 'daily_flat', 'daily_percentage')),
  late_fee_amount numeric(10,2) DEFAULT 0,
  auto_renew boolean DEFAULT false,
  payment_processor_fee text NOT NULL DEFAULT 'landlord_absorbs' CHECK (payment_processor_fee IN ('landlord_absorbs', 'tenant_pays')),
  partial_payments_allowed boolean DEFAULT false,
  auto_pay_required boolean DEFAULT false,
  terms_notes text,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_signature', 'active', 'month_to_month', 'expiring', 'expired', 'terminated', 'renewed')),
  signed_at timestamptz,
  terminated_at timestamptz,
  termination_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_leases_unit ON leases(unit_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_leases_tenant ON leases(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_leases_expiring ON leases(end_date) WHERE status IN ('active', 'expiring') AND deleted_at IS NULL;

-- 5. Lease Documents (signed leases, addendums, notices)
CREATE TABLE lease_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  lease_id uuid NOT NULL REFERENCES leases(id),
  document_type text NOT NULL CHECK (document_type IN ('lease', 'addendum', 'notice', 'renewal', 'termination', 'move_in_checklist', 'move_out_checklist', 'other')),
  title text NOT NULL,
  storage_path text,
  signed_by_tenant boolean DEFAULT false,
  signed_by_landlord boolean DEFAULT false,
  signed_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_lease_docs ON lease_documents(lease_id);

-- 6. Rent Charges (auto-generated monthly)
CREATE TABLE rent_charges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  lease_id uuid NOT NULL REFERENCES leases(id),
  unit_id uuid NOT NULL REFERENCES units(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  property_id uuid NOT NULL REFERENCES properties(id),
  charge_type text NOT NULL DEFAULT 'rent' CHECK (charge_type IN ('rent', 'late_fee', 'utility', 'pet_fee', 'parking', 'other')),
  description text,
  amount numeric(10,2) NOT NULL,
  due_date date NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'paid', 'overdue', 'waived', 'void')),
  paid_amount numeric(10,2) DEFAULT 0,
  paid_at timestamptz,
  journal_entry_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rent_charges_tenant ON rent_charges(tenant_id, due_date DESC);
CREATE INDEX idx_rent_charges_property ON rent_charges(property_id, due_date DESC);
CREATE INDEX idx_rent_charges_overdue ON rent_charges(due_date) WHERE status IN ('pending', 'overdue');

-- 7. Rent Payments
CREATE TABLE rent_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  rent_charge_id uuid NOT NULL REFERENCES rent_charges(id),
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  amount numeric(10,2) NOT NULL,
  payment_method text NOT NULL CHECK (payment_method IN ('ach', 'credit_card', 'debit_card', 'cash', 'check', 'money_order', 'other')),
  stripe_payment_intent_id text,
  processing_fee numeric(10,2) DEFAULT 0,
  fee_paid_by text DEFAULT 'landlord' CHECK (fee_paid_by IN ('landlord', 'tenant')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),
  journal_entry_id uuid,
  paid_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_rent_payments_tenant ON rent_payments(tenant_id, created_at DESC);
CREATE INDEX idx_rent_payments_stripe ON rent_payments(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;

-- 8. Company features flag (ALTER existing table)
ALTER TABLE companies ADD COLUMN IF NOT EXISTS features jsonb NOT NULL DEFAULT '{"contracting": true, "property_management": false}';

-- RLS on all tables
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE lease_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE rent_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE rent_payments ENABLE ROW LEVEL SECURITY;

-- Standard RLS: users can only access their company's data (via JWT app_metadata)
CREATE POLICY "properties_select" ON properties FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "properties_insert" ON properties FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "properties_update" ON properties FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "properties_delete" ON properties FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

CREATE POLICY "units_select" ON units FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "units_insert" ON units FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "units_update" ON units FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "units_delete" ON units FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

CREATE POLICY "tenants_select" ON tenants FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "tenants_insert" ON tenants FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "tenants_update" ON tenants FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "tenants_delete" ON tenants FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

CREATE POLICY "leases_select" ON leases FOR SELECT USING (company_id = requesting_company_id() AND deleted_at IS NULL);
CREATE POLICY "leases_insert" ON leases FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "leases_update" ON leases FOR UPDATE USING (company_id = requesting_company_id());
CREATE POLICY "leases_delete" ON leases FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner', 'admin'));

CREATE POLICY "lease_docs_select" ON lease_documents FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "lease_docs_insert" ON lease_documents FOR INSERT WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "rent_charges_select" ON rent_charges FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "rent_charges_insert" ON rent_charges FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "rent_charges_update" ON rent_charges FOR UPDATE USING (company_id = requesting_company_id());

CREATE POLICY "rent_payments_select" ON rent_payments FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "rent_payments_insert" ON rent_payments FOR INSERT WITH CHECK (company_id = requesting_company_id());

-- Tenant portal RLS: tenants see only their own data
CREATE POLICY "tenants_self" ON tenants FOR SELECT USING (auth_user_id = auth.uid());
CREATE POLICY "leases_tenant" ON leases FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_charges_tenant" ON rent_charges FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));
CREATE POLICY "rent_payments_tenant" ON rent_payments FOR SELECT USING (tenant_id IN (SELECT id FROM tenants WHERE auth_user_id = auth.uid()));

-- Audit triggers
CREATE TRIGGER properties_audit AFTER INSERT OR UPDATE OR DELETE ON properties FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER units_audit AFTER INSERT OR UPDATE OR DELETE ON units FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER tenants_audit AFTER INSERT OR UPDATE OR DELETE ON tenants FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER leases_audit AFTER INSERT OR UPDATE OR DELETE ON leases FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER rent_charges_audit AFTER INSERT OR UPDATE OR DELETE ON rent_charges FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER rent_payments_audit AFTER INSERT OR UPDATE OR DELETE ON rent_payments FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
