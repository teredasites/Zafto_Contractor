-- ============================================================
-- DEPTH29: Estimate Engine Overhaul
-- Migration 000131
-- Tables: material_catalog, labor_units, price_book_items,
--         estimate_versions, estimate_change_orders
-- Columns added: estimates (tier, version_number, template_id,
--   validity_days, exclusions, inclusions, payment_terms)
-- Columns added: estimate_line_items (material_catalog_id,
--   tier_override, labor_hours, labor_difficulty, waste_factor_pct)
-- ============================================================


-- ============================================================
-- 1. MATERIAL CATALOG (trade materials with tier/pricing/labor)
-- ============================================================
CREATE TABLE IF NOT EXISTS material_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    trade VARCHAR(50) NOT NULL,
    category VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    sku VARCHAR(50),
    tier VARCHAR(20) NOT NULL DEFAULT 'standard'
        CHECK (tier IN ('economy', 'standard', 'premium', 'elite', 'luxury')),
    unit VARCHAR(20) NOT NULL,
    cost_per_unit DECIMAL(10,2) NOT NULL DEFAULT 0,
    waste_factor_pct DECIMAL(5,2) NOT NULL DEFAULT 10,
    labor_hours_per_unit DECIMAL(8,4) NOT NULL DEFAULT 0,
    labor_difficulty_multiplier DECIMAL(4,2) NOT NULL DEFAULT 1.0
        CHECK (labor_difficulty_multiplier >= 0.5 AND labor_difficulty_multiplier <= 3.0),
    warranty_years INTEGER,
    description TEXT,
    specs_json JSONB DEFAULT '{}',
    photo_url TEXT,
    supplier_urls JSONB DEFAULT '[]',
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    is_disabled BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE material_catalog ENABLE ROW LEVEL SECURITY;

-- System defaults (company_id IS NULL) readable by all, company-specific scoped
DROP POLICY IF EXISTS "material_catalog_select" ON material_catalog;
CREATE POLICY "material_catalog_select" ON material_catalog
    FOR SELECT TO authenticated
    USING (
        (company_id IS NULL OR company_id = requesting_company_id())
        AND deleted_at IS NULL
    );

DROP POLICY IF EXISTS "material_catalog_insert" ON material_catalog;
CREATE POLICY "material_catalog_insert" ON material_catalog
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "material_catalog_update" ON material_catalog;
CREATE POLICY "material_catalog_update" ON material_catalog
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_material_catalog_company ON material_catalog(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_material_catalog_trade ON material_catalog(trade);
CREATE INDEX IF NOT EXISTS idx_material_catalog_trade_tier ON material_catalog(trade, tier);
CREATE INDEX IF NOT EXISTS idx_material_catalog_category ON material_catalog(trade, category);
CREATE INDEX IF NOT EXISTS idx_material_catalog_search ON material_catalog USING GIN(to_tsvector('english', name || ' ' || COALESCE(brand, '') || ' ' || COALESCE(description, '')));

DROP TRIGGER IF EXISTS trg_material_catalog_updated ON material_catalog;
CREATE TRIGGER trg_material_catalog_updated
    BEFORE UPDATE ON material_catalog
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 2. LABOR UNITS (trade-specific labor hour database)
-- ============================================================
CREATE TABLE IF NOT EXISTS labor_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    trade VARCHAR(50) NOT NULL,
    category VARCHAR(100) NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    description TEXT,
    unit VARCHAR(20) NOT NULL,
    hours_normal DECIMAL(8,4) NOT NULL DEFAULT 0,
    hours_difficult DECIMAL(8,4) NOT NULL DEFAULT 0,
    hours_very_difficult DECIMAL(8,4) NOT NULL DEFAULT 0,
    crew_size_default INTEGER NOT NULL DEFAULT 1,
    notes TEXT,
    source VARCHAR(20) NOT NULL DEFAULT 'system' CHECK (source IN ('system', 'company')),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE labor_units ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "labor_units_select" ON labor_units;
CREATE POLICY "labor_units_select" ON labor_units
    FOR SELECT TO authenticated
    USING (
        (company_id IS NULL OR company_id = requesting_company_id())
        AND deleted_at IS NULL
    );

DROP POLICY IF EXISTS "labor_units_insert" ON labor_units;
CREATE POLICY "labor_units_insert" ON labor_units
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "labor_units_update" ON labor_units;
CREATE POLICY "labor_units_update" ON labor_units
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_labor_units_company ON labor_units(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_labor_units_trade ON labor_units(trade);
CREATE INDEX IF NOT EXISTS idx_labor_units_trade_cat ON labor_units(trade, category);

DROP TRIGGER IF EXISTS trg_labor_units_updated ON labor_units;
CREATE TRIGGER trg_labor_units_updated
    BEFORE UPDATE ON labor_units
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 3. PRICE BOOK ITEMS (company-specific known prices)
-- S130 Owner Directive
-- ============================================================
CREATE TABLE IF NOT EXISTS price_book_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    trade VARCHAR(50),
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    unit_of_measure VARCHAR(20) NOT NULL DEFAULT 'each',
    description TEXT,
    sku VARCHAR(50),
    supplier VARCHAR(200),
    is_active BOOLEAN NOT NULL DEFAULT true,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE price_book_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "price_book_items_select" ON price_book_items;
CREATE POLICY "price_book_items_select" ON price_book_items
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id() AND deleted_at IS NULL);

DROP POLICY IF EXISTS "price_book_items_insert" ON price_book_items;
CREATE POLICY "price_book_items_insert" ON price_book_items
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "price_book_items_update" ON price_book_items;
CREATE POLICY "price_book_items_update" ON price_book_items
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_price_book_company ON price_book_items(company_id);
CREATE INDEX IF NOT EXISTS idx_price_book_trade ON price_book_items(company_id, trade);
CREATE INDEX IF NOT EXISTS idx_price_book_search ON price_book_items USING GIN(to_tsvector('english', name || ' ' || COALESCE(category, '') || ' ' || COALESCE(description, '')));

DROP TRIGGER IF EXISTS trg_price_book_updated ON price_book_items;
CREATE TRIGGER trg_price_book_updated
    BEFORE UPDATE ON price_book_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 4. ESTIMATE VERSIONS (snapshot history)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    label VARCHAR(200),
    snapshot_data JSONB NOT NULL DEFAULT '{}',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_versions_select" ON estimate_versions;
CREATE POLICY "estimate_versions_select" ON estimate_versions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_versions.estimate_id
            AND e.company_id = requesting_company_id()
            AND e.deleted_at IS NULL
        )
    );

DROP POLICY IF EXISTS "estimate_versions_insert" ON estimate_versions;
CREATE POLICY "estimate_versions_insert" ON estimate_versions
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_versions.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

CREATE UNIQUE INDEX IF NOT EXISTS idx_estimate_versions_unique ON estimate_versions(estimate_id, version_number);
CREATE INDEX IF NOT EXISTS idx_estimate_versions_estimate ON estimate_versions(estimate_id);


-- ============================================================
-- 5. ESTIMATE CHANGE ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_change_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    change_order_number INTEGER NOT NULL DEFAULT 1,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'approved', 'rejected')),
    items_added JSONB DEFAULT '[]',
    items_modified JSONB DEFAULT '[]',
    items_removed JSONB DEFAULT '[]',
    subtotal_change DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_change DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_change DECIMAL(12,2) NOT NULL DEFAULT 0,
    new_estimate_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES auth.users(id),
    signed_at TIMESTAMPTZ,
    signature_data TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_change_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_change_orders_select" ON estimate_change_orders;
CREATE POLICY "estimate_change_orders_select" ON estimate_change_orders
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_change_orders.estimate_id
            AND e.company_id = requesting_company_id()
            AND e.deleted_at IS NULL
        )
        AND deleted_at IS NULL
    );

DROP POLICY IF EXISTS "estimate_change_orders_insert" ON estimate_change_orders;
CREATE POLICY "estimate_change_orders_insert" ON estimate_change_orders
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_change_orders.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_change_orders_update" ON estimate_change_orders;
CREATE POLICY "estimate_change_orders_update" ON estimate_change_orders
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_change_orders.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

CREATE UNIQUE INDEX IF NOT EXISTS idx_change_orders_unique ON estimate_change_orders(estimate_id, change_order_number);
CREATE INDEX IF NOT EXISTS idx_change_orders_estimate ON estimate_change_orders(estimate_id);
CREATE INDEX IF NOT EXISTS idx_change_orders_status ON estimate_change_orders(estimate_id, status) WHERE deleted_at IS NULL;

DROP TRIGGER IF EXISTS trg_change_orders_updated ON estimate_change_orders;
CREATE TRIGGER trg_change_orders_updated
    BEFORE UPDATE ON estimate_change_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 6. ALTER estimates — add tier, version, template, validity
-- ============================================================
ALTER TABLE estimates
    ADD COLUMN IF NOT EXISTS tier VARCHAR(20) DEFAULT 'standard'
        CHECK (tier IN ('economy', 'standard', 'premium', 'elite', 'luxury')),
    ADD COLUMN IF NOT EXISTS version_number INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS template_id UUID,
    ADD COLUMN IF NOT EXISTS validity_days INTEGER DEFAULT 30,
    ADD COLUMN IF NOT EXISTS exclusions TEXT,
    ADD COLUMN IF NOT EXISTS inclusions TEXT,
    ADD COLUMN IF NOT EXISTS payment_terms TEXT,
    ADD COLUMN IF NOT EXISTS total_labor_hours DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS crew_size INTEGER DEFAULT 1,
    ADD COLUMN IF NOT EXISTS estimated_days DECIMAL(6,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS material_cost_total DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS labor_cost_total DECIMAL(12,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS change_order_total DECIMAL(12,2) DEFAULT 0;


-- ============================================================
-- 7. ALTER estimate_line_items — add material catalog link,
--    tier override, labor hours, waste factor
-- ============================================================
ALTER TABLE estimate_line_items
    ADD COLUMN IF NOT EXISTS material_catalog_id UUID REFERENCES material_catalog(id),
    ADD COLUMN IF NOT EXISTS tier_override VARCHAR(20)
        CHECK (tier_override IS NULL OR tier_override IN ('economy', 'standard', 'premium', 'elite', 'luxury')),
    ADD COLUMN IF NOT EXISTS labor_hours DECIMAL(8,4) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS labor_difficulty VARCHAR(20) DEFAULT 'normal'
        CHECK (labor_difficulty IN ('normal', 'difficult', 'very_difficult')),
    ADD COLUMN IF NOT EXISTS waste_factor_pct DECIMAL(5,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS material_with_waste DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS labor_hours_total DECIMAL(8,4) DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_line_items_material ON estimate_line_items(material_catalog_id) WHERE material_catalog_id IS NOT NULL;


-- ============================================================
-- 8. CREW PERFORMANCE TRACKING (learning from completed jobs)
-- ============================================================
CREATE TABLE IF NOT EXISTS crew_performance_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    labor_unit_id UUID REFERENCES labor_units(id),
    task_name VARCHAR(200) NOT NULL,
    trade VARCHAR(50) NOT NULL,
    estimated_hours DECIMAL(8,4) NOT NULL,
    actual_hours DECIMAL(8,4) NOT NULL,
    crew_size INTEGER NOT NULL DEFAULT 1,
    difficulty VARCHAR(20) NOT NULL DEFAULT 'normal',
    job_id UUID REFERENCES jobs(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE crew_performance_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "crew_perf_select" ON crew_performance_log;
CREATE POLICY "crew_perf_select" ON crew_performance_log
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

DROP POLICY IF EXISTS "crew_perf_insert" ON crew_performance_log;
CREATE POLICY "crew_perf_insert" ON crew_performance_log
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_crew_perf_company ON crew_performance_log(company_id);
CREATE INDEX IF NOT EXISTS idx_crew_perf_trade ON crew_performance_log(company_id, trade);
CREATE INDEX IF NOT EXISTS idx_crew_perf_task ON crew_performance_log(company_id, task_name);


-- ============================================================
-- 9. SEED DATA — Material Catalog (system defaults)
-- Note: Prices are national averages from BLS/public data.
-- Rule #24: These are DATABASE seed data, not hardcoded.
-- Company override → MSA regional → these national defaults.
-- ============================================================

-- Roofing Shingles
INSERT INTO material_catalog (trade, category, name, brand, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('roofing', 'shingles', '3-Tab Shingles', 'Tamko Heritage', 'economy', 'SQ', 90, 10, 0.60, 25, '3-tab asphalt shingles, basic wind resistance'),
('roofing', 'shingles', 'Architectural Shingles', 'GAF Timberline HDZ', 'standard', 'SQ', 110, 10, 0.75, 30, 'Architectural dimensional shingles, 130mph wind rating'),
('roofing', 'shingles', 'Premium Architectural Shingles', 'CertainTeed Landmark Pro', 'premium', 'SQ', 130, 10, 0.80, 50, 'Max Def color technology, 110mph wind warranty'),
('roofing', 'shingles', 'Designer Shingles', 'DaVinci Bellaforte Shake', 'luxury', 'SQ', 400, 10, 1.50, 50, 'Synthetic polymer shake, Class 4 impact resistant'),
('roofing', 'shingles', 'Metal Standing Seam 24ga Steel', NULL, 'premium', 'SQ', 350, 5, 2.00, 40, '24-gauge steel standing seam panels'),
('roofing', 'shingles', 'Metal Standing Seam Copper', NULL, 'luxury', 'SQ', 1200, 5, 2.50, 75, 'Copper standing seam panels'),
('roofing', 'shingles', 'Clay Tile', NULL, 'luxury', 'SQ', 800, 10, 3.00, 50, 'Clay barrel tile roofing'),
('roofing', 'shingles', 'Concrete Tile', NULL, 'elite', 'SQ', 400, 10, 2.50, 50, 'Concrete flat/S-tile roofing'),
('roofing', 'shingles', 'Synthetic Slate', NULL, 'elite', 'SQ', 500, 10, 2.00, 50, 'Engineered polymer slate look'),
('roofing', 'shingles', 'TPO 60mil', NULL, 'standard', 'SQFT', 5.50, 5, 0.005, 20, 'Single-ply TPO membrane, commercial/flat roof'),
('roofing', 'shingles', 'EPDM 60mil', NULL, 'economy', 'SQFT', 4.50, 5, 0.005, 15, 'Rubber EPDM membrane, flat roof'),
('roofing', 'shingles', 'Modified Bitumen SBS', NULL, 'standard', 'SQFT', 5.00, 5, 0.006, 20, 'SBS modified bitumen torch-down/peel-stick');

-- Roofing Underlayment
INSERT INTO material_catalog (trade, category, name, brand, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('roofing', 'underlayment', 'Synthetic Underlayment', 'GAF FeltBuster', 'standard', 'ROLL', 60, 5, 0.15, '10-sq roll synthetic underlayment'),
('roofing', 'underlayment', 'Ice & Water Shield', 'Grace Ice & Water Shield', 'premium', 'ROLL', 120, 5, 0.25, '2-sq self-adhering ice dam protection'),
('roofing', 'underlayment', 'Self-Adhering Underlayment', 'CertainTeed WinterGuard', 'premium', 'ROLL', 100, 5, 0.20, 'Self-adhering waterproof underlayment'),
('roofing', 'underlayment', '#15 Felt Paper', NULL, 'economy', 'ROLL', 20, 5, 0.10, 'Traditional #15 asphalt felt'),
('roofing', 'underlayment', '#30 Felt Paper', NULL, 'economy', 'ROLL', 35, 5, 0.12, 'Heavy-duty #30 asphalt felt');

-- Electrical Wire
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('electrical', 'wire', '14/2 NM-B (Romex)', 'standard', 'FT', 0.35, 10, 0.0035, '14AWG 2-conductor with ground, 15A circuits'),
('electrical', 'wire', '12/2 NM-B (Romex)', 'standard', 'FT', 0.50, 10, 0.0043, '12AWG 2-conductor with ground, 20A circuits'),
('electrical', 'wire', '10/2 NM-B', 'standard', 'FT', 0.85, 10, 0.0050, '10AWG 2-conductor with ground, 30A circuits'),
('electrical', 'wire', '10/3 NM-B', 'standard', 'FT', 1.20, 10, 0.0055, '10AWG 3-conductor with ground'),
('electrical', 'wire', '6/3 NM-B', 'standard', 'FT', 2.50, 10, 0.0070, '6AWG 3-conductor with ground, ranges/dryers'),
('electrical', 'wire', '12 THHN', 'standard', 'FT', 0.25, 10, 0.0025, '12AWG THHN individual conductor for conduit'),
('electrical', 'wire', '10 THHN', 'standard', 'FT', 0.40, 10, 0.0030, '10AWG THHN individual conductor'),
('electrical', 'wire', '8 THHN', 'standard', 'FT', 0.65, 10, 0.0040, '8AWG THHN individual conductor'),
('electrical', 'wire', '6 THHN', 'standard', 'FT', 1.00, 10, 0.0045, '6AWG THHN individual conductor'),
('electrical', 'wire', '4 THHN', 'standard', 'FT', 1.50, 10, 0.0050, '4AWG THHN individual conductor'),
('electrical', 'wire', '2 THHN', 'standard', 'FT', 2.50, 10, 0.0060, '2AWG THHN individual conductor'),
('electrical', 'wire', '1/0 THHN', 'standard', 'FT', 4.00, 10, 0.0070, '1/0 AWG THHN, service entrance feeds'),
('electrical', 'wire', '4/0 SER Cable', 'standard', 'FT', 6.00, 10, 0.0080, '4/0 service entrance cable'),
('electrical', 'wire', '#6 Bare Copper Ground', 'standard', 'FT', 1.80, 5, 0.0030, 'Bare copper grounding conductor'),
('electrical', 'wire', '12/2 MC Cable', 'premium', 'FT', 0.95, 10, 0.0040, 'Metal-clad armored cable');

-- Electrical Devices
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('electrical', 'devices', 'Duplex Receptacle 15A', 'economy', 'EA', 1.00, 0, 0.18, 'Standard residential grade duplex outlet'),
('electrical', 'devices', 'Spec-Grade Receptacle 20A', 'standard', 'EA', 5.00, 0, 0.18, 'Commercial spec-grade tamper-resistant'),
('electrical', 'devices', 'GFCI Receptacle', 'standard', 'EA', 18.00, 0, 0.25, 'Ground fault circuit interrupter outlet'),
('electrical', 'devices', 'AFCI Receptacle', 'premium', 'EA', 35.00, 0, 0.25, 'Arc fault circuit interrupter outlet'),
('electrical', 'devices', 'USB Combo Receptacle', 'premium', 'EA', 25.00, 0, 0.20, 'Duplex outlet with USB-A/C charging'),
('electrical', 'devices', 'Single Pole Switch 15A', 'economy', 'EA', 1.00, 0, 0.15, 'Standard toggle switch'),
('electrical', 'devices', 'Dimmer Switch', 'standard', 'EA', 20.00, 0, 0.22, 'Rotary or slide dimmer'),
('electrical', 'devices', 'Smart Switch (WiFi)', 'premium', 'EA', 45.00, 0, 0.30, 'WiFi-enabled smart switch'),
('electrical', 'devices', '200A Main Panel', 'standard', 'EA', 250.00, 0, 8.00, '200A 40-space main breaker panel'),
('electrical', 'devices', '100A Sub-Panel', 'standard', 'EA', 150.00, 0, 4.00, '100A sub-panel with main breaker'),
('electrical', 'devices', '200A Meter Main Combo', 'standard', 'EA', 400.00, 0, 6.00, '200A outdoor meter main combo'),
('electrical', 'devices', 'Weatherproof GFCI', 'standard', 'EA', 22.00, 0, 0.30, 'Outdoor weather-resistant GFCI'),
('electrical', 'devices', '50A Range Receptacle', 'standard', 'EA', 12.00, 0, 0.50, 'NEMA 14-50 range outlet'),
('electrical', 'devices', '30A Dryer Receptacle', 'standard', 'EA', 10.00, 0, 0.50, 'NEMA 14-30 dryer outlet'),
('electrical', 'devices', 'Smoke Detector (hardwired)', 'standard', 'EA', 25.00, 0, 0.20, 'Hardwired smoke alarm with battery backup'),
('electrical', 'devices', 'CO Detector (hardwired)', 'standard', 'EA', 30.00, 0, 0.20, 'Hardwired carbon monoxide detector'),
('electrical', 'devices', 'Combo Smoke/CO Detector', 'premium', 'EA', 40.00, 0, 0.20, 'Combination smoke and CO alarm'),
('electrical', 'devices', 'Recessed Light (LED)', 'standard', 'EA', 15.00, 0, 0.35, '6-inch LED recessed light retrofit kit'),
('electrical', 'devices', 'Ceiling Fan', 'standard', 'EA', 80.00, 0, 0.50, '52-inch ceiling fan with light kit'),
('electrical', 'devices', 'EV Charger Outlet (NEMA 14-50)', 'standard', 'EA', 12.00, 0, 2.00, 'EV charging outlet installation');

-- Plumbing Pipe
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('plumbing', 'pipe', '1/2" Copper Type L', 'premium', 'FT', 4.00, 10, 0.08, 'Copper supply line, soldered joints'),
('plumbing', 'pipe', '3/4" Copper Type L', 'premium', 'FT', 7.00, 10, 0.10, 'Copper main supply line'),
('plumbing', 'pipe', '1/2" PEX-A', 'standard', 'FT', 0.70, 10, 0.02, 'Cross-linked polyethylene supply'),
('plumbing', 'pipe', '3/4" PEX-A', 'standard', 'FT', 1.20, 10, 0.03, 'PEX main supply line'),
('plumbing', 'pipe', '1/2" CPVC', 'economy', 'FT', 0.50, 10, 0.03, 'Chlorinated PVC supply pipe'),
('plumbing', 'pipe', '2" PVC DWV', 'standard', 'FT', 1.50, 10, 0.10, 'PVC drain/waste/vent pipe'),
('plumbing', 'pipe', '3" PVC DWV', 'standard', 'FT', 2.50, 10, 0.12, 'PVC main drain line'),
('plumbing', 'pipe', '4" PVC DWV', 'standard', 'FT', 4.00, 10, 0.15, 'PVC main sewer line'),
('plumbing', 'pipe', '3" Cast Iron', 'premium', 'FT', 12.00, 5, 0.20, 'Cast iron drain pipe, noise reduction'),
('plumbing', 'pipe', '4" Cast Iron', 'premium', 'FT', 18.00, 5, 0.25, 'Cast iron main sewer drain');

-- Plumbing Fixtures
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('plumbing', 'fixtures', 'Standard Toilet', NULL, 'economy', 'EA', 200, 0, 1.50, 1, 'Round bowl, standard height'),
('plumbing', 'fixtures', 'Comfort Height Toilet', NULL, 'standard', 'EA', 350, 0, 1.50, 5, 'Elongated bowl, ADA height'),
('plumbing', 'fixtures', 'Wall-Mount Toilet', NULL, 'premium', 'EA', 600, 0, 3.00, 5, 'Concealed tank, wall-hung'),
('plumbing', 'fixtures', 'Bidet Seat', NULL, 'elite', 'EA', 400, 0, 1.00, 2, 'Electronic bidet toilet seat'),
('plumbing', 'fixtures', 'Standard Faucet', NULL, 'economy', 'EA', 80, 0, 0.75, 1, 'Chrome single-handle faucet'),
('plumbing', 'fixtures', 'Pull-Down Kitchen Faucet', NULL, 'standard', 'EA', 200, 0, 1.00, 5, 'Pull-down spray kitchen faucet'),
('plumbing', 'fixtures', 'Touchless Faucet', NULL, 'premium', 'EA', 350, 0, 1.50, 5, 'Motion-sensor hands-free faucet'),
('plumbing', 'fixtures', '40gal Gas Water Heater', NULL, 'economy', 'EA', 600, 0, 3.00, 6, 'Standard tank gas water heater'),
('plumbing', 'fixtures', '50gal Electric Water Heater', NULL, 'standard', 'EA', 500, 0, 3.00, 6, 'Standard tank electric water heater'),
('plumbing', 'fixtures', 'Tankless Gas Water Heater', NULL, 'premium', 'EA', 1500, 0, 6.00, 12, 'On-demand gas water heater'),
('plumbing', 'fixtures', 'Tankless Electric Water Heater', NULL, 'standard', 'EA', 800, 0, 4.00, 10, 'On-demand electric water heater');

-- HVAC Equipment
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('hvac', 'equipment', '80% AFUE Gas Furnace', NULL, 'economy', 'EA', 1200, 0, 5.00, 10, '80% efficient gas furnace'),
('hvac', 'equipment', '96% AFUE Gas Furnace', NULL, 'premium', 'EA', 2500, 0, 6.00, 10, 'High-efficiency condensing furnace'),
('hvac', 'equipment', '14 SEER AC Condenser', NULL, 'economy', 'EA', 2000, 0, 4.00, 10, 'Standard efficiency AC unit'),
('hvac', 'equipment', '18 SEER AC Condenser', NULL, 'premium', 'EA', 4000, 0, 5.00, 10, 'High-efficiency variable speed AC'),
('hvac', 'equipment', 'Heat Pump 16 SEER', NULL, 'standard', 'EA', 3500, 0, 6.00, 10, 'All-electric heat pump system'),
('hvac', 'equipment', 'Mini-Split Single Zone', NULL, 'standard', 'EA', 1500, 0, 6.00, 7, 'Ductless mini-split, 1 head'),
('hvac', 'equipment', 'Mini-Split Multi-Zone 3-Head', NULL, 'premium', 'EA', 5000, 0, 12.00, 7, 'Multi-zone ductless, 3 indoor heads'),
('hvac', 'equipment', 'Thermostat Standard', NULL, 'economy', 'EA', 30, 0, 0.50, 1, 'Basic non-programmable thermostat'),
('hvac', 'equipment', 'Programmable Thermostat', NULL, 'standard', 'EA', 60, 0, 0.50, 2, '7-day programmable thermostat'),
('hvac', 'equipment', 'Smart Thermostat', NULL, 'premium', 'EA', 200, 0, 0.75, 3, 'WiFi smart thermostat (Ecobee/Nest)'),
('hvac', 'equipment', 'Humidifier Bypass', NULL, 'standard', 'EA', 200, 0, 2.00, 5, 'Whole-house bypass humidifier'),
('hvac', 'equipment', 'ERV (Energy Recovery Ventilator)', NULL, 'premium', 'EA', 1200, 0, 4.00, 5, 'Whole-house energy recovery ventilator'),
('hvac', 'equipment', 'UV-C Air Purifier', NULL, 'premium', 'EA', 600, 0, 1.00, 3, 'In-duct UV-C germicidal light');

-- Painting
INSERT INTO material_catalog (trade, category, name, brand, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('painting', 'paint', 'Interior Flat', 'Behr Ultra', 'economy', 'GAL', 35, 10, 0.30, 'Interior flat latex paint, ~400sqft/gal'),
('painting', 'paint', 'Interior Eggshell', 'SW ProMar 200', 'standard', 'GAL', 40, 10, 0.30, 'Interior eggshell, washable'),
('painting', 'paint', 'Interior Semi-Gloss', 'BM Regal Select', 'premium', 'GAL', 55, 10, 0.30, 'Premium semi-gloss for trim/doors'),
('painting', 'paint', 'Exterior Flat', 'SW Duration', 'standard', 'GAL', 65, 10, 0.40, 'Exterior flat latex, UV resistant'),
('painting', 'paint', 'Exterior Satin', 'BM Aura', 'premium', 'GAL', 75, 10, 0.40, 'Premium exterior satin finish'),
('painting', 'paint', 'Primer (Stain Block)', 'Zinsser BIN', 'standard', 'GAL', 45, 10, 0.25, 'Shellac-based stain blocking primer'),
('painting', 'paint', 'Primer (Standard)', NULL, 'economy', 'GAL', 30, 10, 0.25, 'Standard latex primer'),
('painting', 'paint', 'Cabinet Paint', NULL, 'premium', 'GAL', 50, 10, 0.50, 'Self-leveling cabinet/trim paint'),
('painting', 'paint', 'Deck Stain', NULL, 'standard', 'GAL', 40, 10, 0.35, 'Exterior deck stain/sealer'),
('painting', 'paint', 'Concrete Stain', NULL, 'standard', 'GAL', 35, 10, 0.30, 'Concrete/masonry stain');

-- Concrete
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('concrete', 'mix', '4000 PSI Concrete', 'standard', 'CY', 130, 5, 1.00, 'Standard 4000 PSI ready-mix'),
('concrete', 'mix', '5000 PSI High-Strength', 'premium', 'CY', 150, 5, 1.00, 'High-strength structural concrete'),
('concrete', 'mix', 'Fiber-Reinforced Concrete', 'premium', 'CY', 155, 5, 1.00, 'Concrete with polypropylene fiber'),
('concrete', 'mix', 'Rapid-Set Concrete', 'premium', 'CY', 170, 5, 0.80, 'Quick-cure concrete, 1-hr set'),
('concrete', 'reinforcement', 'Rebar #4', 'standard', 'FT', 0.80, 5, 0.015, '1/2" diameter rebar'),
('concrete', 'reinforcement', 'Welded Wire Mesh 6x6', 'standard', 'SQFT', 0.15, 5, 0.003, '6x6 W1.4/W1.4 welded wire'),
('concrete', 'accessories', 'Expansion Joint Material', 'standard', 'LF', 0.50, 5, 0.025, 'Asphalt-impregnated fiber expansion joint'),
('concrete', 'accessories', 'Concrete Sealer', 'standard', 'SQFT', 0.20, 5, 0.002, 'Penetrating concrete sealer'),
('concrete', 'accessories', 'Stamped Color Hardener', 'premium', 'SQFT', 0.50, 10, 0.020, 'Color hardener for decorative stamped concrete'),
('concrete', 'accessories', 'Exposed Aggregate Finish', 'premium', 'SQFT', 0.75, 0, 0.015, 'Exposed aggregate retarder finish');

-- Insulation
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('insulation', 'batt', 'Fiberglass Batt R-13', 'economy', 'SQFT', 0.50, 5, 0.005, 'R-13 fiberglass batt, 2x4 walls'),
('insulation', 'batt', 'Fiberglass Batt R-19', 'standard', 'SQFT', 0.70, 5, 0.005, 'R-19 fiberglass batt, 2x6 walls'),
('insulation', 'batt', 'Fiberglass Batt R-30', 'standard', 'SQFT', 1.00, 5, 0.006, 'R-30 fiberglass batt, attic floors'),
('insulation', 'batt', 'Mineral Wool Batt R-15', 'premium', 'SQFT', 1.20, 5, 0.006, 'Roxul/Rockwool mineral wool, fire resistant'),
('insulation', 'blown', 'Blown Fiberglass R-38', 'standard', 'SQFT', 1.20, 0, 0.003, 'Machine-blown fiberglass attic insulation'),
('insulation', 'blown', 'Blown Cellulose R-38', 'economy', 'SQFT', 1.00, 0, 0.003, 'Recycled cellulose blown insulation'),
('insulation', 'foam', 'Spray Foam Open-Cell', 'standard', 'SQFT', 1.50, 0, 0.004, 'Open-cell spray polyurethane foam'),
('insulation', 'foam', 'Spray Foam Closed-Cell (per inch)', 'premium', 'SQFT', 2.50, 0, 0.004, 'Closed-cell spray foam, vapor barrier'),
('insulation', 'board', 'Rigid Foam XPS 2"', 'premium', 'SQFT', 1.50, 5, 0.008, 'Extruded polystyrene rigid board'),
('insulation', 'radiant', 'Radiant Barrier', 'standard', 'SQFT', 0.50, 5, 0.003, 'Attic radiant barrier foil');

-- Drywall
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('drywall', 'board', '1/2" Regular Drywall', 'economy', 'SQFT', 0.40, 10, 0.006, 'Standard 1/2" gypsum board'),
('drywall', 'board', '5/8" Regular Drywall', 'standard', 'SQFT', 0.50, 10, 0.007, 'Thicker 5/8" for better soundproofing'),
('drywall', 'board', '5/8" Type X Fire-Rated', 'standard', 'SQFT', 0.55, 10, 0.007, '1-hr fire rated gypsum board'),
('drywall', 'board', '1/2" Moisture-Resistant', 'standard', 'SQFT', 0.55, 10, 0.006, 'Green board for humid areas'),
('drywall', 'board', '5/8" Moisture-Resistant', 'premium', 'SQFT', 0.65, 10, 0.007, 'Moisture-resistant 5/8" for bathrooms'),
('drywall', 'board', '1/2" Mold-Resistant', 'premium', 'SQFT', 0.60, 10, 0.006, 'Paperless mold-resistant drywall'),
('drywall', 'board', 'Soundproof Drywall (QuietRock)', 'elite', 'SQFT', 2.50, 10, 0.008, 'Constrained-layer damped drywall, STC 50+'),
('drywall', 'board', 'Cement Board 1/2"', 'premium', 'SQFT', 1.20, 10, 0.010, 'Cement backer board for tile installations');

-- Flooring
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('flooring', 'lvp', 'LVP Waterproof Standard', NULL, 'standard', 'SQFT', 3.50, 10, 0.020, 15, 'Luxury vinyl plank, waterproof core'),
('flooring', 'lvp', 'LVP Premium', NULL, 'premium', 'SQFT', 6.00, 10, 0.020, 25, 'Premium LVP with rigid SPC core'),
('flooring', 'hardwood', 'Hardwood Oak', NULL, 'premium', 'SQFT', 6.00, 10, 0.030, 25, 'Solid oak hardwood, 3/4" thick'),
('flooring', 'hardwood', 'Hardwood Walnut', NULL, 'luxury', 'SQFT', 10.00, 10, 0.035, 25, 'Solid walnut hardwood'),
('flooring', 'laminate', 'Laminate Standard', NULL, 'economy', 'SQFT', 2.00, 10, 0.015, 10, 'Basic laminate plank flooring'),
('flooring', 'laminate', 'Laminate Premium', NULL, 'standard', 'SQFT', 4.00, 10, 0.015, 20, 'Premium laminate with attached pad'),
('flooring', 'tile', 'Ceramic Tile 12x12', NULL, 'economy', 'SQFT', 3.00, 15, 0.040, 20, 'Standard ceramic floor tile'),
('flooring', 'tile', 'Porcelain Tile', NULL, 'standard', 'SQFT', 5.00, 15, 0.045, 25, 'Porcelain floor tile'),
('flooring', 'carpet', 'Carpet Standard', NULL, 'economy', 'SQFT', 2.00, 5, 0.010, 5, 'Standard residential carpet with pad'),
('flooring', 'carpet', 'Carpet Premium', NULL, 'standard', 'SQFT', 5.00, 5, 0.010, 10, 'Premium plush carpet with upgraded pad'),
('flooring', 'specialty', 'Vinyl Sheet', NULL, 'economy', 'SQFT', 1.50, 5, 0.008, 10, 'Sheet vinyl flooring'),
('flooring', 'specialty', 'Epoxy Garage Floor', NULL, 'standard', 'SQFT', 3.00, 5, 0.015, 10, 'Epoxy floor coating system'),
('flooring', 'specialty', 'Polished Concrete', NULL, 'premium', 'SQFT', 4.00, 0, 0.020, 20, 'Polished concrete floor finish');

-- Siding
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('siding', 'panel', 'Vinyl Siding Standard', NULL, 'economy', 'SQFT', 4.00, 10, 0.020, 25, 'Standard vinyl lap siding'),
('siding', 'panel', 'Vinyl Siding Premium', NULL, 'standard', 'SQFT', 7.00, 10, 0.020, 50, 'Insulated premium vinyl siding'),
('siding', 'panel', 'Fiber Cement (Hardie)', 'James Hardie', 'premium', 'SQFT', 10.00, 10, 0.035, 30, 'HardiePlank fiber cement siding'),
('siding', 'panel', 'Engineered Wood (LP SmartSide)', 'LP', 'standard', 'SQFT', 8.00, 10, 0.030, 50, 'LP SmartSide engineered wood siding'),
('siding', 'panel', 'Cedar Lap Siding', NULL, 'elite', 'SQFT', 12.00, 10, 0.040, 25, 'Natural western red cedar siding'),
('siding', 'panel', 'Aluminum Siding', NULL, 'economy', 'SQFT', 6.00, 10, 0.025, 30, 'Aluminum lap siding'),
('siding', 'panel', 'Stone Veneer', NULL, 'luxury', 'SQFT', 25.00, 10, 0.060, 50, 'Manufactured stone veneer panels'),
('siding', 'panel', 'Brick Veneer', NULL, 'elite', 'SQFT', 15.00, 10, 0.050, 100, 'Thin brick veneer siding'),
('siding', 'panel', 'Stucco', NULL, 'standard', 'SQFT', 8.00, 5, 0.040, 25, '3-coat stucco system'),
('siding', 'panel', 'Board & Batten', NULL, 'premium', 'SQFT', 9.00, 10, 0.035, 25, 'Board and batten style siding');

-- Gutters
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('gutters', 'gutter', '5" K-Style Aluminum', 'standard', 'LF', 6.00, 5, 0.030, 'Standard 5-inch K-style seamless aluminum'),
('gutters', 'gutter', '6" K-Style Aluminum', 'standard', 'LF', 8.00, 5, 0.035, 'Oversized 6-inch K-style for high-flow'),
('gutters', 'gutter', '5" Copper K-Style', 'luxury', 'LF', 25.00, 5, 0.040, 'Copper K-style gutter'),
('gutters', 'gutter', 'Half-Round Aluminum', 'premium', 'LF', 10.00, 5, 0.035, 'Half-round decorative aluminum gutter'),
('gutters', 'gutter', 'Half-Round Copper', 'luxury', 'LF', 35.00, 5, 0.045, 'Half-round copper gutter'),
('gutters', 'gutter', '5" Steel Gutter', 'premium', 'LF', 9.00, 5, 0.035, 'Galvalume steel gutter'),
('gutters', 'accessories', 'Gutter Guard (Mesh)', 'economy', 'LF', 4.00, 5, 0.020, 'Aluminum mesh gutter guard'),
('gutters', 'accessories', 'Gutter Guard (Micro-Mesh)', 'premium', 'LF', 8.00, 5, 0.025, 'Stainless steel micro-mesh guard'),
('gutters', 'accessories', 'Gutter Guard (Reverse-Curve)', 'elite', 'LF', 12.00, 5, 0.030, 'Reverse-curve helmet-style guard'),
('gutters', 'accessories', 'Downspout', 'standard', 'LF', 5.00, 5, 0.025, 'Aluminum downspout');

-- Fencing
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, description) VALUES
('fencing', 'wood', '6ft Wood Privacy (Dog-Ear)', 'economy', 'LF', 15.00, 10, 0.063, 'Standard dog-ear cedar/pine privacy fence'),
('fencing', 'wood', '6ft Wood Privacy (Board-on-Board)', 'standard', 'LF', 22.00, 10, 0.070, 'Board-on-board privacy, no gaps'),
('fencing', 'wood', '6ft Wood Privacy (Shadow Box)', 'standard', 'LF', 20.00, 10, 0.065, 'Shadow box alternating board fence'),
('fencing', 'chain_link', '4ft Chain Link', 'economy', 'LF', 10.00, 5, 0.040, '4-foot galvanized chain link'),
('fencing', 'chain_link', '6ft Chain Link', 'economy', 'LF', 15.00, 5, 0.050, '6-foot galvanized chain link'),
('fencing', 'vinyl', '6ft Vinyl Privacy', 'standard', 'LF', 25.00, 5, 0.056, 'PVC vinyl privacy fence panel'),
('fencing', 'vinyl', '4ft Vinyl Picket', 'standard', 'LF', 18.00, 5, 0.045, 'PVC vinyl picket fence'),
('fencing', 'metal', '4ft Aluminum Ornamental', 'premium', 'LF', 25.00, 5, 0.035, 'Decorative aluminum ornamental fence'),
('fencing', 'metal', 'Wrought Iron', 'luxury', 'LF', 45.00, 5, 0.080, 'Custom wrought iron fencing'),
('fencing', 'wood', '3-Rail Split Rail', 'economy', 'LF', 12.00, 5, 0.040, 'Rustic split-rail post and rail'),
('fencing', 'composite', '6ft Composite Privacy', 'premium', 'LF', 35.00, 5, 0.060, 'Wood-plastic composite fence panel');

-- Windows & Doors
INSERT INTO material_catalog (trade, category, name, tier, unit, cost_per_unit, waste_factor_pct, labor_hours_per_unit, warranty_years, description) VALUES
('windows_doors', 'windows', 'Vinyl Window (Insert)', NULL, 'economy', 'EA', 250, 0, 0.75, 20, 'Vinyl replacement insert window'),
('windows_doors', 'windows', 'Vinyl Window (Full-Frame)', NULL, 'standard', 'EA', 400, 0, 2.00, 25, 'Full-frame vinyl window replacement'),
('windows_doors', 'windows', 'Fiberglass Window', NULL, 'premium', 'EA', 600, 0, 2.00, 30, 'Fiberglass frame, superior insulation'),
('windows_doors', 'windows', 'Wood Window (Clad)', NULL, 'elite', 'EA', 900, 0, 2.50, 20, 'Wood interior, aluminum-clad exterior'),
('windows_doors', 'doors', 'Interior Pre-Hung Door', NULL, 'standard', 'EA', 150, 0, 1.00, 5, 'Interior 6-panel or flat slab pre-hung'),
('windows_doors', 'doors', 'Exterior Steel Door', NULL, 'standard', 'EA', 350, 0, 3.00, 10, 'Insulated steel entry door with frame'),
('windows_doors', 'doors', 'Exterior Fiberglass Door', NULL, 'premium', 'EA', 600, 0, 3.00, 20, 'Fiberglass entry door, wood-grain'),
('windows_doors', 'doors', 'Sliding Glass Door', NULL, 'standard', 'EA', 800, 0, 4.00, 10, 'Vinyl sliding patio door'),
('windows_doors', 'doors', 'Storm Door', NULL, 'standard', 'EA', 200, 0, 1.50, 5, 'Full-view storm/screen door'),
('windows_doors', 'trim', 'Window Trim/Casing', NULL, 'standard', 'EA', 15, 5, 0.50, NULL, 'Per-window interior trim package');


-- ============================================================
-- 10. SEED DATA — Labor Units (system defaults)
-- ============================================================

-- Electrical
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('electrical', 'devices', 'Duplex receptacle rough-in + trim', 'EA', 0.18, 0.23, 0.29, 1, 'NECA MLU standard'),
('electrical', 'devices', 'GFCI receptacle install', 'EA', 0.25, 0.33, 0.40, 1, 'Includes testing'),
('electrical', 'devices', 'Single pole switch install', 'EA', 0.15, 0.20, 0.24, 1, 'Standard toggle or decora'),
('electrical', 'devices', '3-way switch install', 'EA', 0.20, 0.26, 0.32, 1, 'Paired 3-way switches'),
('electrical', 'devices', 'Dimmer switch install', 'EA', 0.22, 0.29, 0.35, 1, 'Single or multi-location'),
('electrical', 'wire', '14/2 NM-B wire pull per 1000ft', 'PER1000', 3.50, 4.55, 5.60, 1, 'Through wood framing'),
('electrical', 'wire', '12/2 NM-B wire pull per 1000ft', 'PER1000', 4.25, 5.53, 6.80, 1, 'Through wood framing'),
('electrical', 'wire', '10/2 NM-B wire pull per 1000ft', 'PER1000', 5.00, 6.50, 8.00, 1, 'Stiffer wire, larger bends'),
('electrical', 'panels', '200A main panel install', 'EA', 8.00, 10.40, 12.80, 1, 'Panel + main breaker + grounding'),
('electrical', 'panels', '100A sub-panel install', 'EA', 4.00, 5.20, 6.40, 1, 'Sub-panel + feeder'),
('electrical', 'panels', 'Circuit breaker install', 'EA', 0.25, 0.33, 0.40, 1, 'Standard single-pole breaker'),
('electrical', 'lighting', 'Recessed light rough-in', 'EA', 0.35, 0.46, 0.56, 1, 'New construction or remodel can'),
('electrical', 'lighting', 'Ceiling fan install', 'EA', 0.50, 0.65, 0.80, 1, 'Fan-rated box + assembly + wire'),
('electrical', 'safety', 'Smoke detector install', 'EA', 0.20, 0.26, 0.32, 1, 'Hardwired with interconnect'),
('electrical', 'outdoor', 'Weatherproof outlet install', 'EA', 0.30, 0.39, 0.48, 1, 'In-use cover + WR receptacle'),
('electrical', 'outdoor', 'EV charger outlet (NEMA 14-50)', 'EA', 2.00, 2.60, 3.20, 1, 'Dedicated 50A circuit from panel'),
('electrical', 'misc', 'Whole-house surge protector', 'EA', 1.00, 1.30, 1.60, 1, 'Panel-mount SPD'),
('electrical', 'misc', 'Ground rod + clamp', 'EA', 1.50, 1.95, 2.40, 1, '8ft copper ground rod installation'),
('electrical', 'admin', 'Panel schedule documentation', 'EA', 1.00, 1.00, 1.00, 1, 'Labeling + as-built documentation'),
('electrical', 'admin', 'Permit acquisition', 'EA', 2.00, 2.00, 2.00, 1, 'Application + inspections');

-- Plumbing
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('plumbing', 'fixtures', 'Toilet set (flange + wax + toilet + supply)', 'EA', 1.50, 1.95, 2.40, 1, 'Complete toilet installation'),
('plumbing', 'fixtures', 'Kitchen faucet replacement', 'EA', 1.00, 1.30, 1.60, 1, 'Disconnect old + install new'),
('plumbing', 'fixtures', 'Bathroom faucet replacement', 'EA', 0.75, 0.98, 1.20, 1, 'Simpler access than kitchen'),
('plumbing', 'fixtures', 'Water heater replacement (40-50gal tank)', 'EA', 3.00, 3.90, 4.80, 1, 'Remove old + connect new + test'),
('plumbing', 'fixtures', 'Tankless water heater install (new)', 'EA', 6.00, 7.80, 9.60, 1, 'New gas line + venting + connections'),
('plumbing', 'pipe', '1/2" copper solder joint', 'EA', 0.08, 0.10, 0.13, 1, 'Cut + clean + flux + solder'),
('plumbing', 'pipe', '1/2" PEX crimp connection', 'EA', 0.03, 0.04, 0.05, 1, 'Cut + insert + crimp'),
('plumbing', 'pipe', '3/4" copper solder joint', 'EA', 0.10, 0.13, 0.16, 1, 'Larger joint, more heat'),
('plumbing', 'fixtures', 'Hose bib install', 'EA', 0.75, 0.98, 1.20, 1, 'Frost-proof outdoor faucet'),
('plumbing', 'fixtures', 'Garbage disposal install', 'EA', 1.00, 1.30, 1.60, 1, 'Mount + plumb + wire'),
('plumbing', 'fixtures', 'Dishwasher hookup', 'EA', 1.50, 1.95, 2.40, 1, 'Supply + drain + secure'),
('plumbing', 'fixtures', 'Washing machine box install', 'EA', 1.50, 1.95, 2.40, 1, 'Supply valves + drain + box'),
('plumbing', 'drain', 'P-trap replacement', 'EA', 0.50, 0.65, 0.80, 1, 'Remove old + install new'),
('plumbing', 'drain', 'Drain cleanout install', 'EA', 1.00, 1.30, 1.60, 1, 'Tee fitting + cleanout plug'),
('plumbing', 'fixtures', 'Sump pump install', 'EA', 3.00, 3.90, 4.80, 1, 'Basin + pump + discharge line + check valve'),
('plumbing', 'pipe', 'Water line (1/2" PEX per 100ft)', 'PER100', 2.50, 3.25, 4.00, 1, 'Run + support + connections'),
('plumbing', 'pipe', 'Drain line (2" PVC per 10ft)', 'PER10', 1.00, 1.30, 1.60, 1, 'Cut + prime + cement + support');

-- HVAC
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('hvac', 'equipment', 'Furnace replacement (like-for-like)', 'EA', 5.00, 6.50, 8.00, 2, 'Remove old + set new + reconnect'),
('hvac', 'equipment', 'Furnace new install (with ductwork mods)', 'EA', 8.00, 10.40, 12.80, 2, 'New location or major duct changes'),
('hvac', 'equipment', 'AC condenser replacement', 'EA', 4.00, 5.20, 6.40, 2, 'Disconnect + remove + set + connect + charge'),
('hvac', 'equipment', 'Full system install (furnace + AC)', 'EA', 8.00, 10.40, 12.80, 2, 'Complete system changeover'),
('hvac', 'equipment', 'Mini-split single zone install', 'EA', 6.00, 7.80, 9.60, 1, 'Indoor head + outdoor unit + lineset'),
('hvac', 'equipment', 'Mini-split additional head', 'EA', 3.00, 3.90, 4.80, 1, 'Additional indoor head + branch lineset'),
('hvac', 'controls', 'Thermostat replacement', 'EA', 0.50, 0.65, 0.80, 1, 'Remove old + wire new + configure'),
('hvac', 'controls', 'Smart thermostat install', 'EA', 0.75, 0.98, 1.20, 1, 'May need C-wire adapter'),
('hvac', 'ductwork', 'Flex duct run (per 10ft)', 'PER10', 0.50, 0.65, 0.80, 1, 'Flexible duct with insulation'),
('hvac', 'ductwork', 'Rigid duct run (per 10ft)', 'PER10', 1.50, 1.95, 2.40, 1, 'Sheet metal fabrication + install'),
('hvac', 'ductwork', 'Register/grille install', 'EA', 0.15, 0.20, 0.24, 1, 'Supply register or return grille'),
('hvac', 'ductwork', 'Return air grille (large)', 'EA', 0.25, 0.33, 0.40, 1, 'Central return with filter rack'),
('hvac', 'accessories', 'Humidifier (bypass) install', 'EA', 2.00, 2.60, 3.20, 1, 'Mount + plumb + wire + duct connection'),
('hvac', 'accessories', 'UV light install', 'EA', 1.00, 1.30, 1.60, 1, 'In-duct UV germicidal install'),
('hvac', 'accessories', 'Filter cabinet install', 'EA', 1.50, 1.95, 2.40, 1, 'External media filter cabinet'),
('hvac', 'service', 'Refrigerant charge per lb', 'LB', 0.25, 0.33, 0.40, 1, 'Recovery + charge + verify'),
('hvac', 'drain', 'Condensate drain install', 'EA', 0.50, 0.65, 0.80, 1, 'PVC condensate drain line + trap');

-- Roofing
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('roofing', 'tear-off', 'Tear-off 1 layer asphalt shingles', 'SQ', 0.50, 0.65, 0.80, 3, 'Per square, 3-person crew'),
('roofing', 'tear-off', 'Tear-off 2 layers asphalt shingles', 'SQ', 0.75, 0.98, 1.20, 3, 'Double layer, heavier debris'),
('roofing', 'install', 'Install architectural shingles', 'SQ', 0.75, 0.98, 1.20, 3, 'Per square with starter + hip/ridge'),
('roofing', 'install', 'Install 3-tab shingles', 'SQ', 0.60, 0.78, 0.96, 3, 'Standard 3-tab installation'),
('roofing', 'install', 'Install metal standing seam', 'SQ', 2.00, 2.60, 3.20, 2, 'Panel fabrication + install'),
('roofing', 'install', 'Install flat TPO/EPDM', 'SQ', 0.50, 0.65, 0.80, 2, 'Single-ply membrane application'),
('roofing', 'trim', 'Ridge cap (per LF)', 'LF', 0.02, 0.03, 0.03, 3, 'Hip and ridge cap shingles'),
('roofing', 'trim', 'Starter strip (per LF)', 'LF', 0.01, 0.01, 0.02, 3, 'Eave starter strip'),
('roofing', 'trim', 'Drip edge (per LF)', 'LF', 0.01, 0.01, 0.02, 3, 'Metal drip edge at eaves/rakes'),
('roofing', 'prep', 'Ice & water shield (per roll)', 'ROLL', 0.25, 0.33, 0.40, 3, '2-square self-adhering membrane'),
('roofing', 'flashing', 'Pipe boot install', 'EA', 0.15, 0.20, 0.24, 1, 'Plumbing vent boot'),
('roofing', 'flashing', 'Step flashing (per piece)', 'EA', 0.10, 0.13, 0.16, 1, 'Wall-to-roof step flashing'),
('roofing', 'flashing', 'Chimney flashing (complete)', 'EA', 2.00, 2.60, 3.20, 1, 'Step + counter + cricket flashing'),
('roofing', 'flashing', 'Skylight flashing', 'EA', 1.50, 1.95, 2.40, 1, 'Complete skylight reflashing'),
('roofing', 'ventilation', 'Roof vent install', 'EA', 0.25, 0.33, 0.40, 1, 'Box vent or turbine install'),
('roofing', 'repair', 'Plywood sheathing replacement (per sheet)', 'EA', 0.50, 0.65, 0.80, 2, '4x8 sheet replacement in place');

-- Painting
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('painting', 'prep', 'Exterior wall prep (per 100sqft)', 'PER100', 0.50, 0.65, 0.80, 1, 'Scrape + sand + caulk'),
('painting', 'prime', 'Exterior prime (per 100sqft)', 'PER100', 0.30, 0.39, 0.48, 1, 'Roller/spray primer application'),
('painting', 'exterior', 'Exterior paint 2 coats (per 100sqft)', 'PER100', 0.75, 0.98, 1.20, 1, 'Two coats latex, brush & roll'),
('painting', 'interior', 'Interior wall paint (per 100sqft)', 'PER100', 0.40, 0.52, 0.64, 1, 'Cut-in + roll, 2 coats'),
('painting', 'interior', 'Ceiling paint (per 100sqft)', 'PER100', 0.50, 0.65, 0.80, 1, 'Overhead rolling, 2 coats'),
('painting', 'trim', 'Trim paint (per 100 LF)', 'PER100', 1.50, 1.95, 2.40, 1, 'Baseboard/crown, brush only'),
('painting', 'doors', 'Door paint (per door)', 'EA', 0.75, 0.98, 1.20, 1, 'Both sides + edges + jamb'),
('painting', 'windows', 'Window paint (per window)', 'EA', 0.50, 0.65, 0.80, 1, 'Frame + sash + muntins'),
('painting', 'cabinets', 'Cabinet paint (per LF)', 'LF', 1.00, 1.30, 1.60, 1, 'Doors off, sand, prime, 2 coats'),
('painting', 'deck', 'Deck stain (per 100sqft)', 'PER100', 0.60, 0.78, 0.96, 1, 'Stain application, brush/roll'),
('painting', 'prep', 'Pressure wash (per 100sqft)', 'PER100', 0.15, 0.20, 0.24, 1, 'Surface cleaning'),
('painting', 'prep', 'Caulking (per 100 LF)', 'PER100', 0.50, 0.65, 0.80, 1, 'Joint/seam caulking'),
('painting', 'removal', 'Wallpaper removal (per 100sqft)', 'PER100', 1.50, 1.95, 2.40, 1, 'Score + wet + strip + clean');

-- Concrete
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('concrete', 'formwork', 'Form setting (per 10 LF, 4")', 'PER10', 0.75, 0.98, 1.20, 2, 'Stake + level + brace'),
('concrete', 'formwork', 'Form setting (per 10 LF, 6")', 'PER10', 1.00, 1.30, 1.60, 2, 'Deeper form, more bracing'),
('concrete', 'reinforcement', 'Rebar placement (per 100 LF #4)', 'PER100', 1.50, 1.95, 2.40, 2, 'Cut + bend + tie + chair'),
('concrete', 'reinforcement', 'Wire mesh (per 100sqft)', 'PER100', 0.30, 0.39, 0.48, 2, 'Roll out + overlap + chair'),
('concrete', 'pour', 'Pour and finish (per yard)', 'CY', 1.00, 1.30, 1.60, 3, 'Spread + screed + bull float + trowel'),
('concrete', 'finish', 'Stamp concrete (per 100sqft)', 'PER100', 2.00, 2.60, 3.20, 3, 'Timing-critical, color + stamp'),
('concrete', 'finish', 'Broom finish (per 100sqft)', 'PER100', 0.30, 0.39, 0.48, 2, 'Standard non-slip broom finish'),
('concrete', 'accessories', 'Expansion joint (per 10 LF)', 'PER10', 0.25, 0.33, 0.40, 1, 'Place + secure joint material'),
('concrete', 'demo', 'Demolition (per 100sqft, 4")', 'PER100', 2.00, 2.60, 3.20, 2, 'Break + load + haul'),
('concrete', 'prep', 'Grading/prep (per 100sqft)', 'PER100', 0.50, 0.65, 0.80, 2, 'Grade + compact + gravel base'),
('concrete', 'finish', 'Sealer application (per 100sqft)', 'PER100', 0.20, 0.26, 0.32, 1, 'Spray or roll sealer'),
('concrete', 'stairs', 'Concrete steps (per step)', 'EA', 1.50, 1.95, 2.40, 2, 'Form + pour + finish per riser');

-- Drywall
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('drywall', 'hang', 'Hang 1/2" drywall (per sheet)', 'EA', 0.25, 0.33, 0.40, 2, '4x8 or 4x12 sheet'),
('drywall', 'hang', 'Hang 5/8" drywall (per sheet)', 'EA', 0.30, 0.39, 0.48, 2, 'Heavier, code-required areas'),
('drywall', 'finish', 'Tape and first coat (per sheet)', 'EA', 0.15, 0.20, 0.24, 1, 'Bed tape + first mud coat'),
('drywall', 'finish', 'Second coat (per sheet)', 'EA', 0.10, 0.13, 0.16, 1, 'Second mud coat, wider knife'),
('drywall', 'finish', 'Third coat (per sheet)', 'EA', 0.10, 0.13, 0.16, 1, 'Final coat, skim'),
('drywall', 'finish', 'Sand (per sheet)', 'EA', 0.08, 0.10, 0.13, 1, 'Pole sander, dust containment'),
('drywall', 'finish', 'Texture (per 100sqft)', 'PER100', 0.50, 0.65, 0.80, 1, 'Knockdown, orange peel, or skip trowel'),
('drywall', 'repair', 'Patch (small, per patch)', 'EA', 0.25, 0.33, 0.40, 1, 'Under 6" — mesh + mud + sand'),
('drywall', 'repair', 'Patch (large, per patch)', 'EA', 0.75, 0.98, 1.20, 1, 'Over 6" — cut-in + backer + mud'),
('drywall', 'demo', 'Demolition (per sheet)', 'EA', 0.15, 0.20, 0.24, 1, 'Remove + clean + haul');

-- Insulation
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('insulation', 'batt', 'Batt install (per 100sqft)', 'PER100', 0.50, 0.65, 0.80, 1, 'Cut + fit + staple vapor barrier'),
('insulation', 'blown', 'Blown install (per 100sqft)', 'PER100', 0.30, 0.39, 0.48, 2, 'Machine blown attic fill'),
('insulation', 'foam', 'Spray foam (per 100sqft per inch)', 'PER100', 0.40, 0.52, 0.64, 2, 'Spray rig required'),
('insulation', 'board', 'Rigid foam board (per 100sqft)', 'PER100', 0.75, 0.98, 1.20, 1, 'Cut + glue/fasten + tape seams'),
('insulation', 'prep', 'Vapor barrier install (per 100sqft)', 'PER100', 0.20, 0.26, 0.32, 1, 'Poly sheeting + seal'),
('insulation', 'seal', 'Air sealing (per can)', 'EA', 0.10, 0.13, 0.16, 1, 'Great Stuff foam sealant'),
('insulation', 'seal', 'Rim joist spray foam (per LF)', 'LF', 0.05, 0.07, 0.08, 1, 'Spray foam each joist bay');

-- Flooring
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('flooring', 'lvp', 'LVP install (per 100sqft)', 'PER100', 2.00, 2.60, 3.20, 1, 'Click-lock, stagger, undercut jambs'),
('flooring', 'hardwood', 'Hardwood install (per 100sqft)', 'PER100', 3.00, 3.90, 4.80, 1, 'Nail-down or glue-down'),
('flooring', 'tile', 'Tile install (per 100sqft)', 'PER100', 4.00, 5.20, 6.40, 1, 'Mortar + tile + spacers + grout'),
('flooring', 'carpet', 'Carpet install (per 100sqft)', 'PER100', 1.00, 1.30, 1.60, 2, 'Tack strip + pad + stretch + seam'),
('flooring', 'laminate', 'Laminate install (per 100sqft)', 'PER100', 1.50, 1.95, 2.40, 1, 'Floating click, expansion gaps'),
('flooring', 'demo', 'Demo existing flooring (per 100sqft)', 'PER100', 1.00, 1.30, 1.60, 1, 'Remove + clean + haul'),
('flooring', 'prep', 'Subfloor prep/level (per 100sqft)', 'PER100', 1.00, 1.30, 1.60, 1, 'Level compound or repair'),
('flooring', 'trim', 'Baseboard install (per 100 LF)', 'PER100', 2.00, 2.60, 3.20, 1, 'Measure + cut + cope + nail + fill'),
('flooring', 'trim', 'Transition strip install', 'EA', 0.25, 0.33, 0.40, 1, 'T-mold, reducer, or threshold');

-- Fencing
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('fencing', 'wood', 'Wood privacy 6ft (per 8ft section)', 'EA', 0.50, 0.65, 0.80, 2, 'Post + rails + pickets'),
('fencing', 'chain_link', 'Chain-link 4ft (per 10ft)', 'PER10', 0.40, 0.52, 0.64, 2, 'Post + top rail + fabric + ties'),
('fencing', 'chain_link', 'Chain-link 6ft (per 10ft)', 'PER10', 0.50, 0.65, 0.80, 2, 'Taller, more fabric'),
('fencing', 'vinyl', 'Vinyl privacy (per 8ft section)', 'EA', 0.45, 0.59, 0.72, 2, 'Pre-assembled panel install'),
('fencing', 'metal', 'Aluminum ornamental (per 6ft section)', 'EA', 0.35, 0.46, 0.56, 2, 'Panel + brackets'),
('fencing', 'post', 'Post hole (per hole)', 'EA', 0.25, 0.33, 0.40, 2, 'Dig + set + plumb'),
('fencing', 'post', 'Concrete per post', 'EA', 0.15, 0.20, 0.24, 1, 'Mix + pour + level'),
('fencing', 'gates', 'Gate install (walk gate)', 'EA', 1.00, 1.30, 1.60, 2, 'Hang + hardware + latch'),
('fencing', 'gates', 'Gate install (double drive gate)', 'EA', 2.50, 3.25, 4.00, 2, 'Double swing + drop rod + hardware'),
('fencing', 'demo', 'Fence demolition/removal (per 10 LF)', 'PER10', 0.30, 0.39, 0.48, 2, 'Remove + dig posts + haul');

-- Siding
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('siding', 'vinyl', 'Vinyl siding install (per 100sqft)', 'PER100', 2.00, 2.60, 3.20, 2, 'Starter + panels + J-channel'),
('siding', 'fiber_cement', 'Fiber cement install (per 100sqft)', 'PER100', 3.50, 4.55, 5.60, 2, 'Heavier, requires pre-drill'),
('siding', 'wood', 'Wood lap siding (per 100sqft)', 'PER100', 4.00, 5.20, 6.40, 2, 'Traditional cedar/pine lap'),
('siding', 'engineered', 'LP SmartSide install (per 100sqft)', 'PER100', 3.00, 3.90, 4.80, 2, 'Engineered wood panels'),
('siding', 'aluminum', 'Aluminum siding (per 100sqft)', 'PER100', 2.50, 3.25, 4.00, 2, 'Lightweight aluminum panels'),
('siding', 'trim', 'J-channel (per 100LF)', 'PER100', 0.75, 0.98, 1.20, 1, 'Window/door/soffit trim channel'),
('siding', 'trim', 'Corner post install', 'EA', 0.25, 0.33, 0.40, 1, 'Inside or outside corner post'),
('siding', 'trim', 'Starter strip (per 100LF)', 'PER100', 0.50, 0.65, 0.80, 1, 'Base starter strip'),
('siding', 'soffit', 'Soffit install (per 100sqft)', 'PER100', 2.00, 2.60, 3.20, 2, 'Vented or solid soffit panels'),
('siding', 'fascia', 'Fascia install (per 100LF)', 'PER100', 2.50, 3.25, 4.00, 1, 'Aluminum or wood fascia wrap'),
('siding', 'demo', 'Siding demolition (per 100sqft)', 'PER100', 1.50, 1.95, 2.40, 2, 'Remove + haul old siding');

-- Gutters
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('gutters', 'install', '5" K-style install (per 10 LF)', 'PER10', 0.30, 0.39, 0.48, 2, 'Machine-formed seamless aluminum'),
('gutters', 'install', '6" K-style install (per 10 LF)', 'PER10', 0.35, 0.46, 0.56, 2, 'Oversized, heavier gauge'),
('gutters', 'install', 'Downspout install (per 10 LF)', 'PER10', 0.25, 0.33, 0.40, 1, 'Cut + rivet + strap + elbow'),
('gutters', 'accessories', 'Inside miter', 'EA', 0.15, 0.20, 0.24, 1, 'Inside corner fabrication + seal'),
('gutters', 'accessories', 'Outside miter', 'EA', 0.15, 0.20, 0.24, 1, 'Outside corner fabrication + seal'),
('gutters', 'accessories', 'End cap', 'EA', 0.05, 0.07, 0.08, 1, 'Crimp + seal end cap'),
('gutters', 'accessories', 'Outlet tube', 'EA', 0.10, 0.13, 0.16, 1, 'Downspout drop outlet'),
('gutters', 'guards', 'Gutter guard install (per 10 LF)', 'PER10', 0.20, 0.26, 0.32, 1, 'Leaf guard system'),
('gutters', 'demo', 'Gutter demolition (per 10 LF)', 'PER10', 0.10, 0.13, 0.16, 1, 'Remove + haul old gutters'),
('gutters', 'repair', 'Fascia repair (per 10 LF)', 'PER10', 0.50, 0.65, 0.80, 1, 'Replace rotted fascia board');

-- Windows & Doors
INSERT INTO labor_units (trade, category, task_name, unit, hours_normal, hours_difficult, hours_very_difficult, crew_size_default, notes) VALUES
('windows_doors', 'windows', 'Window replacement (standard insert)', 'EA', 0.75, 0.98, 1.20, 1, 'Remove sash + insert new + trim'),
('windows_doors', 'windows', 'Window replacement (full-frame)', 'EA', 2.00, 2.60, 3.20, 2, 'Remove frame + flash + install + trim'),
('windows_doors', 'windows', 'Window new construction install', 'EA', 1.50, 1.95, 2.40, 2, 'New rough opening or new build'),
('windows_doors', 'doors', 'Interior door (pre-hung)', 'EA', 1.00, 1.30, 1.60, 1, 'Set + shim + screw + trim'),
('windows_doors', 'doors', 'Exterior door replacement', 'EA', 3.00, 3.90, 4.80, 2, 'Remove + flash + set + seal + hardware'),
('windows_doors', 'doors', 'Sliding glass door install', 'EA', 4.00, 5.20, 6.40, 2, 'Heavy, requires precise level'),
('windows_doors', 'doors', 'Storm door install', 'EA', 1.50, 1.95, 2.40, 1, 'Mount frame + hang door + hardware'),
('windows_doors', 'trim', 'Window trim/casing (per window)', 'EA', 0.50, 0.65, 0.80, 1, 'Measure + cut + cope + nail'),
('windows_doors', 'trim', 'Door trim/casing (per door)', 'EA', 0.75, 0.98, 1.20, 1, 'Head + side casing + stops');


-- ============================================================
-- 11. RPC: Get company crew multiplier for a task
-- ============================================================
CREATE OR REPLACE FUNCTION fn_crew_performance_multiplier(
    p_company_id UUID,
    p_trade VARCHAR,
    p_task_name VARCHAR
)
RETURNS DECIMAL(4,2)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_count INTEGER;
    v_avg_ratio DECIMAL(6,4);
BEGIN
    SELECT COUNT(*), AVG(actual_hours / NULLIF(estimated_hours, 0))
    INTO v_count, v_avg_ratio
    FROM crew_performance_log
    WHERE company_id = p_company_id
      AND trade = p_trade
      AND task_name = p_task_name;

    -- Minimum 5 data points before suggesting adjustment
    IF v_count < 5 OR v_avg_ratio IS NULL THEN
        RETURN 1.0;
    END IF;

    -- Clamp between 0.5 and 2.0
    RETURN GREATEST(0.5, LEAST(2.0, v_avg_ratio));
END;
$$;


-- ============================================================
-- 12. Audit triggers on new business tables
-- ============================================================
CREATE OR REPLACE FUNCTION log_material_catalog_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (company_id, user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            COALESCE(NEW.company_id, OLD.company_id),
            auth.uid(),
            'update',
            'material_catalog',
            NEW.id,
            jsonb_build_object('cost_per_unit', OLD.cost_per_unit, 'name', OLD.name),
            jsonb_build_object('cost_per_unit', NEW.cost_per_unit, 'name', NEW.name)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_material_catalog_audit ON material_catalog;
CREATE TRIGGER trg_material_catalog_audit
    AFTER UPDATE ON material_catalog
    FOR EACH ROW
    EXECUTE FUNCTION log_material_catalog_changes();
