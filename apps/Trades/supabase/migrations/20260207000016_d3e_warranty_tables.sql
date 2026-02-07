-- ============================================================
-- D3e: Warranty Tables + Seed Data
-- Sprint D3 — Insurance Verticals
-- Creates warranty_companies (shared directory),
-- company_warranty_relationships (per-company),
-- warranty_dispatches (per-job)
-- Seeds 15 major home warranty providers
-- ============================================================

-- Warranty company directory (shared across all companies — no company_id)
CREATE TABLE warranty_companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  short_name TEXT,
  type TEXT DEFAULT 'home_warranty' CHECK (type IN ('home_warranty', 'appliance_warranty', 'builder_warranty')),
  phone TEXT,
  email TEXT,
  website TEXT,
  contractor_portal_url TEXT,
  payment_terms_days INTEGER DEFAULT 14,
  service_fee_default DECIMAL(8,2),
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company-specific warranty relationships
CREATE TABLE company_warranty_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  warranty_company_id UUID NOT NULL REFERENCES warranty_companies(id),
  contractor_id_with_warranty TEXT,
  trades_registered TEXT[],
  service_area_zips TEXT[],
  avg_response_hours DECIMAL(5,1),
  avg_completion_days DECIMAL(5,1),
  total_dispatches_completed INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  satisfaction_score DECIMAL(3,2),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending_approval')),
  approved_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, warranty_company_id)
);

-- Warranty dispatches (linked to jobs — ONE dispatch per job)
CREATE TABLE warranty_dispatches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  warranty_company_id UUID REFERENCES warranty_companies(id),
  dispatch_number TEXT,
  claim_number TEXT,
  authorization_number TEXT,
  warranty_holder_name TEXT,
  warranty_holder_phone TEXT,
  warranty_holder_email TEXT,
  contract_number TEXT,
  contract_type TEXT,
  property_type TEXT,
  property_age_years INTEGER,
  issue_type TEXT,
  issue_description TEXT,
  equipment_brand TEXT,
  equipment_model TEXT,
  equipment_serial TEXT,
  equipment_age_years INTEGER,
  authorization_limit DECIMAL(10,2),
  requires_pre_auth BOOLEAN DEFAULT FALSE,
  pre_auth_threshold DECIMAL(10,2),
  diagnosis TEXT,
  diagnosis_date TIMESTAMPTZ,
  repair_or_replace TEXT CHECK (repair_or_replace IN ('repair', 'replace', 'denied', 'not_covered')),
  denial_reason TEXT,
  service_fee DECIMAL(8,2),
  service_fee_collected BOOLEAN DEFAULT FALSE,
  service_fee_collected_date TIMESTAMPTZ,
  parts_cost DECIMAL(10,2),
  labor_cost DECIMAL(10,2),
  total_invoice DECIMAL(10,2),
  warranty_company_paid DECIMAL(10,2) DEFAULT 0,
  payment_date TIMESTAMPTZ,
  oop_amount DECIMAL(10,2) DEFAULT 0,
  oop_collected BOOLEAN DEFAULT FALSE,
  oop_description TEXT,
  status TEXT NOT NULL DEFAULT 'dispatched' CHECK (status IN (
    'dispatched', 'scheduled', 'diagnosed', 'authorized', 'in_progress',
    'complete', 'invoiced', 'paid', 'closed', 'denied', 'recalled', 'cancelled'
  )),
  dispatched_date TIMESTAMPTZ,
  scheduled_date TIMESTAMPTZ,
  diagnosed_date TIMESTAMPTZ,
  authorized_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  invoiced_date TIMESTAMPTZ,
  paid_date TIMESTAMPTZ,
  is_recall BOOLEAN DEFAULT FALSE,
  original_dispatch_id UUID REFERENCES warranty_dispatches(id),
  recall_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),
  UNIQUE(company_id, job_id)
);

-- RLS
ALTER TABLE warranty_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_warranty_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE warranty_dispatches ENABLE ROW LEVEL SECURITY;

-- warranty_companies: readable by all authenticated users (shared directory)
CREATE POLICY warranty_companies_read ON warranty_companies FOR SELECT USING (auth.role() = 'authenticated');
-- Only super_admin can insert/update/delete warranty companies
CREATE POLICY warranty_companies_admin ON warranty_companies FOR ALL USING (
  (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
);

-- company_warranty_relationships: company-scoped
CREATE POLICY warranty_rel_company ON company_warranty_relationships FOR ALL USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);

-- warranty_dispatches: company-scoped
CREATE POLICY warranty_dispatch_company ON warranty_dispatches FOR ALL USING (
  company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
);

-- Indexes
CREATE INDEX idx_warranty_companies_active ON warranty_companies(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_warranty_rel_company ON company_warranty_relationships(company_id);
CREATE INDEX idx_warranty_dispatches_company ON warranty_dispatches(company_id);
CREATE INDEX idx_warranty_dispatches_job ON warranty_dispatches(job_id);
CREATE INDEX idx_warranty_dispatches_status ON warranty_dispatches(status);
CREATE INDEX idx_warranty_dispatches_warranty_co ON warranty_dispatches(warranty_company_id);

-- Audit triggers
CREATE TRIGGER warranty_companies_updated BEFORE UPDATE ON warranty_companies FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER warranty_dispatches_updated BEFORE UPDATE ON warranty_dispatches FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- Seed 15 major home warranty companies
-- ============================================================
INSERT INTO warranty_companies (name, short_name, type, service_fee_default, website, contractor_portal_url) VALUES
('American Home Shield', 'AHS', 'home_warranty', 100.00, 'https://www.ahs.com', 'https://contractor.ahs.com'),
('Frontdoor (HSA/OneGuard)', 'Frontdoor', 'home_warranty', 75.00, 'https://www.frontdoorhome.com', 'https://pro.frontdoorhome.com'),
('Choice Home Warranty', 'CHW', 'home_warranty', 85.00, 'https://www.choicehomewarranty.com', NULL),
('Select Home Warranty', 'SHW', 'home_warranty', 75.00, 'https://www.selecthomewarranty.com', NULL),
('First American Home Warranty', 'FAHW', 'home_warranty', 75.00, 'https://homewarranty.firstam.com', NULL),
('Fidelity National Home Warranty', 'FNHW', 'home_warranty', 75.00, 'https://www.fidelityhomewarranty.com', NULL),
('Old Republic Home Protection', 'ORHP', 'home_warranty', 85.00, 'https://www.orhp.com', NULL),
('2-10 Home Buyers Warranty', '2-10', 'home_warranty', 75.00, 'https://www.2-10.com', NULL),
('HMS Home Warranty', 'HMS', 'home_warranty', 100.00, 'https://www.hmsnational.com', NULL),
('Landmark Home Warranty', 'LHW', 'home_warranty', 70.00, 'https://www.landmarkhw.com', NULL),
('Liberty Home Guard', 'LHG', 'home_warranty', 80.00, 'https://www.libertyhomeguard.com', NULL),
('Cinch Home Services', 'Cinch', 'home_warranty', 75.00, 'https://www.cinchhomeservices.com', NULL),
('ServicePlus Home Warranty', 'SP', 'home_warranty', 75.00, 'https://www.serviceplus.com', NULL),
('Total Home Protection', 'THP', 'home_warranty', 75.00, 'https://www.totalhomeprotection.com', NULL),
('America''s Preferred Home Warranty', 'APHW', 'home_warranty', 75.00, 'https://www.aphw.com', NULL);
