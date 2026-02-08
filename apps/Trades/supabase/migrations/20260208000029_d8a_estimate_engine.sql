-- ============================================================
-- D8a: Estimate Engine Core Tables
-- Migration 000029
-- Tables: estimate_categories, estimate_units, estimate_items,
--         estimate_pricing, estimate_labor_components,
--         code_contributions, estimates, estimate_areas,
--         estimate_line_items, estimate_photos
-- Architecture: Two-mode engine (Regular Bids + Insurance ESX)
-- Clean-room design — independent code database, own pricing
-- NOTE: IF NOT EXISTS used throughout for idempotency
-- ============================================================


-- ============================================================
-- 1. ESTIMATE CATEGORIES (reference table — shared across all companies)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE,
    industry_code VARCHAR(10),
    name VARCHAR(100) NOT NULL,
    labor_pct INTEGER NOT NULL DEFAULT 50 CHECK (labor_pct >= 0 AND labor_pct <= 100),
    material_pct INTEGER NOT NULL DEFAULT 40 CHECK (material_pct >= 0 AND material_pct <= 100),
    equipment_pct INTEGER NOT NULL DEFAULT 10 CHECK (equipment_pct >= 0 AND equipment_pct <= 100),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_categories ENABLE ROW LEVEL SECURITY;

-- Reference data: all authenticated users can read
DROP POLICY IF EXISTS "estimate_categories_select" ON estimate_categories;
CREATE POLICY "estimate_categories_select" ON estimate_categories
    FOR SELECT TO authenticated
    USING (true);

CREATE INDEX IF NOT EXISTS idx_estimate_categories_code ON estimate_categories(code);


-- ============================================================
-- 2. ESTIMATE UNITS (reference table — shared)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(50) NOT NULL,
    abbreviation VARCHAR(10) NOT NULL
);

ALTER TABLE estimate_units ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_units_select" ON estimate_units;
CREATE POLICY "estimate_units_select" ON estimate_units
    FOR SELECT TO authenticated
    USING (true);


-- ============================================================
-- 3. ESTIMATE ITEMS (ZAFTO's code database)
-- Dual RLS: ZAFTO-seeded readable by all, company items scoped
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES estimate_categories(id),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    zafto_code VARCHAR(20) NOT NULL,
    industry_code VARCHAR(20),
    industry_selector VARCHAR(20),
    description TEXT NOT NULL,
    unit_code VARCHAR(10) NOT NULL,
    action_types TEXT[] NOT NULL DEFAULT '{add}',
    trade VARCHAR(50) NOT NULL,
    subtrade VARCHAR(100),
    tags TEXT[],
    is_common BOOLEAN NOT NULL DEFAULT false,
    source VARCHAR(50) NOT NULL DEFAULT 'zafto' CHECK (source IN ('zafto', 'contributed', 'company', 'bls', 'fema')),
    life_expectancy_years INTEGER,
    depreciation_max_pct INTEGER CHECK (depreciation_max_pct >= 0 AND depreciation_max_pct <= 100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Functional unique: same zafto_code can't be duplicated per company (or globally if company_id IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_estimate_items_unique_code
    ON estimate_items(zafto_code, COALESCE(company_id, '00000000-0000-0000-0000-000000000000'::uuid));

ALTER TABLE estimate_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_items_select" ON estimate_items;
CREATE POLICY "estimate_items_select" ON estimate_items
    FOR SELECT TO authenticated
    USING (
        company_id IS NULL
        OR company_id = requesting_company_id()
    );

DROP POLICY IF EXISTS "estimate_items_insert" ON estimate_items;
CREATE POLICY "estimate_items_insert" ON estimate_items
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "estimate_items_update" ON estimate_items;
CREATE POLICY "estimate_items_update" ON estimate_items
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_estimate_items_category ON estimate_items(category_id);
CREATE INDEX IF NOT EXISTS idx_estimate_items_trade ON estimate_items(trade);
CREATE INDEX IF NOT EXISTS idx_estimate_items_code ON estimate_items(zafto_code);
CREATE INDEX IF NOT EXISTS idx_estimate_items_company ON estimate_items(company_id) WHERE company_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_estimate_items_tags ON estimate_items USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_estimate_items_common ON estimate_items(trade, is_common) WHERE is_common = true;
CREATE INDEX IF NOT EXISTS idx_estimate_items_search ON estimate_items USING GIN(to_tsvector('english', description));


-- ============================================================
-- 4. ESTIMATE PRICING (regional pricing per item)
-- Public data (BLS, FEMA) readable by all
-- Company overrides scoped
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_pricing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES estimate_items(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    region_code VARCHAR(20) NOT NULL,
    labor_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
    material_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    equipment_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    effective_date DATE NOT NULL,
    source VARCHAR(50) NOT NULL CHECK (source IN ('bls', 'fema', 'crowdsource', 'company', 'manual')),
    confidence VARCHAR(20) DEFAULT 'medium' CHECK (confidence IN ('low', 'medium', 'high', 'verified')),
    sample_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Functional unique: one price per item+region+date per company (or globally)
CREATE UNIQUE INDEX IF NOT EXISTS idx_estimate_pricing_unique
    ON estimate_pricing(item_id, region_code, effective_date, COALESCE(company_id, '00000000-0000-0000-0000-000000000000'::uuid));

ALTER TABLE estimate_pricing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_pricing_select" ON estimate_pricing;
CREATE POLICY "estimate_pricing_select" ON estimate_pricing
    FOR SELECT TO authenticated
    USING (
        company_id IS NULL
        OR company_id = requesting_company_id()
    );

DROP POLICY IF EXISTS "estimate_pricing_insert" ON estimate_pricing;
CREATE POLICY "estimate_pricing_insert" ON estimate_pricing
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "estimate_pricing_update" ON estimate_pricing;
CREATE POLICY "estimate_pricing_update" ON estimate_pricing
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_estimate_pricing_item ON estimate_pricing(item_id);
CREATE INDEX IF NOT EXISTS idx_estimate_pricing_region ON estimate_pricing(region_code);
CREATE INDEX IF NOT EXISTS idx_estimate_pricing_lookup ON estimate_pricing(item_id, region_code, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_estimate_pricing_company ON estimate_pricing(company_id) WHERE company_id IS NOT NULL;


-- ============================================================
-- 5. ESTIMATE LABOR COMPONENTS (trade-specific labor rates)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_labor_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    code VARCHAR(20) NOT NULL,
    trade VARCHAR(50) NOT NULL,
    description VARCHAR(200),
    base_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
    markup DECIMAL(10,2) NOT NULL DEFAULT 0,
    burden_pct DECIMAL(5,4) NOT NULL DEFAULT 0,
    region_code VARCHAR(20),
    effective_date DATE,
    source VARCHAR(50) NOT NULL DEFAULT 'public' CHECK (source IN ('public', 'bls', 'company', 'manual')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_labor_components ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_labor_select" ON estimate_labor_components;
CREATE POLICY "estimate_labor_select" ON estimate_labor_components
    FOR SELECT TO authenticated
    USING (
        company_id IS NULL
        OR company_id = requesting_company_id()
    );

DROP POLICY IF EXISTS "estimate_labor_insert" ON estimate_labor_components;
CREATE POLICY "estimate_labor_insert" ON estimate_labor_components
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "estimate_labor_update" ON estimate_labor_components;
CREATE POLICY "estimate_labor_update" ON estimate_labor_components
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX IF NOT EXISTS idx_labor_components_trade ON estimate_labor_components(trade);
CREATE INDEX IF NOT EXISTS idx_labor_components_company ON estimate_labor_components(company_id) WHERE company_id IS NOT NULL;


-- ============================================================
-- 6. CODE CONTRIBUTIONS (crowdsource verification pipeline)
-- Users submit, verified ones promote to estimate_items
-- ============================================================
CREATE TABLE IF NOT EXISTS code_contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    industry_code VARCHAR(10) NOT NULL,
    industry_selector VARCHAR(20) NOT NULL,
    description TEXT NOT NULL,
    unit_code VARCHAR(10),
    action_type VARCHAR(10),
    trade VARCHAR(50),
    verified BOOLEAN NOT NULL DEFAULT false,
    verification_count INTEGER NOT NULL DEFAULT 1,
    promoted_item_id UUID REFERENCES estimate_items(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE code_contributions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "contributions_select" ON code_contributions;
CREATE POLICY "contributions_select" ON code_contributions
    FOR SELECT TO authenticated
    USING (
        verified = true
        OR company_id = requesting_company_id()
    );

DROP POLICY IF EXISTS "contributions_insert" ON code_contributions;
CREATE POLICY "contributions_insert" ON code_contributions
    FOR INSERT TO authenticated
    WITH CHECK (
        company_id = requesting_company_id()
        AND user_id = auth.uid()
    );

CREATE INDEX IF NOT EXISTS idx_code_contributions_company ON code_contributions(company_id);
-- Renamed from idx_contributions_code to avoid collision with e5a pricing_contributions index
CREATE INDEX IF NOT EXISTS idx_code_contributions_industry ON code_contributions(industry_code, industry_selector);
CREATE INDEX IF NOT EXISTS idx_code_contributions_verified ON code_contributions(verified) WHERE verified = true;


-- ============================================================
-- 7. ESTIMATES (parent record — dual mode)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id),
    customer_id UUID REFERENCES customers(id),
    created_by UUID NOT NULL REFERENCES auth.users(id),
    estimate_number VARCHAR(20) NOT NULL,
    title VARCHAR(200),
    property_address TEXT,
    property_city VARCHAR(100),
    property_state VARCHAR(2),
    property_zip VARCHAR(10),
    estimate_type VARCHAR(20) NOT NULL DEFAULT 'regular' CHECK (estimate_type IN ('regular', 'insurance')),
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'approved', 'rejected', 'expired', 'converted')),
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    overhead_pct DECIMAL(5,2) NOT NULL DEFAULT 10,
    profit_pct DECIMAL(5,2) NOT NULL DEFAULT 10,
    tax_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    overhead_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    profit_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    grand_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    -- Insurance-specific fields (NULL for regular estimates)
    deductible DECIMAL(10,2),
    claim_number VARCHAR(50),
    policy_number VARCHAR(50),
    date_of_loss DATE,
    insurance_carrier VARCHAR(200),
    adjuster_name VARCHAR(200),
    adjuster_email VARCHAR(200),
    adjuster_phone VARCHAR(20),
    -- Lifecycle
    notes TEXT,
    internal_notes TEXT,
    sent_at TIMESTAMPTZ,
    viewed_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    expired_at TIMESTAMPTZ,
    converted_job_id UUID REFERENCES jobs(id),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(company_id, estimate_number)
);

ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimates_select" ON estimates;
CREATE POLICY "estimates_select" ON estimates
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id() AND deleted_at IS NULL);

DROP POLICY IF EXISTS "estimates_insert" ON estimates;
CREATE POLICY "estimates_insert" ON estimates
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

DROP POLICY IF EXISTS "estimates_update" ON estimates;
CREATE POLICY "estimates_update" ON estimates
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- Soft delete only — no hard delete policy

CREATE INDEX IF NOT EXISTS idx_estimates_company ON estimates(company_id);
CREATE INDEX IF NOT EXISTS idx_estimates_status ON estimates(company_id, status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_estimates_job ON estimates(job_id) WHERE job_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_estimates_customer ON estimates(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_estimates_type ON estimates(company_id, estimate_type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_estimates_number ON estimates(estimate_number);
CREATE INDEX IF NOT EXISTS idx_estimates_created ON estimates(company_id, created_at DESC) WHERE deleted_at IS NULL;

-- Audit trigger: log status changes
CREATE OR REPLACE FUNCTION log_estimate_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_log (company_id, user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            NEW.company_id,
            auth.uid(),
            'status_change',
            'estimates',
            NEW.id,
            jsonb_build_object('status', OLD.status),
            jsonb_build_object('status', NEW.status)
        );
    END IF;
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_estimate_status_change ON estimates;
CREATE TRIGGER trg_estimate_status_change
    BEFORE UPDATE ON estimates
    FOR EACH ROW
    EXECUTE FUNCTION log_estimate_status_change();


-- ============================================================
-- 8. ESTIMATE AREAS (room-by-room)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    floor_number INTEGER NOT NULL DEFAULT 1,
    length_ft DECIMAL(8,2),
    width_ft DECIMAL(8,2),
    height_ft DECIMAL(8,2) DEFAULT 8,
    perimeter_ft DECIMAL(8,2),
    area_sf DECIMAL(10,2),
    window_count INTEGER DEFAULT 0,
    door_count INTEGER DEFAULT 0,
    notes TEXT,
    lidar_data JSONB,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_areas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_areas_select" ON estimate_areas;
CREATE POLICY "estimate_areas_select" ON estimate_areas
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_areas.estimate_id
            AND e.company_id = requesting_company_id()
            AND e.deleted_at IS NULL
        )
    );

DROP POLICY IF EXISTS "estimate_areas_insert" ON estimate_areas;
CREATE POLICY "estimate_areas_insert" ON estimate_areas
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_areas.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_areas_update" ON estimate_areas;
CREATE POLICY "estimate_areas_update" ON estimate_areas
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_areas.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_areas_delete" ON estimate_areas;
CREATE POLICY "estimate_areas_delete" ON estimate_areas
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_areas.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

CREATE INDEX IF NOT EXISTS idx_estimate_areas_estimate ON estimate_areas(estimate_id);


-- ============================================================
-- 9. ESTIMATE LINE ITEMS (scope items per area)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    area_id UUID REFERENCES estimate_areas(id) ON DELETE SET NULL,
    item_id UUID REFERENCES estimate_items(id),
    industry_code VARCHAR(10),
    industry_selector VARCHAR(20),
    description TEXT NOT NULL,
    action_type VARCHAR(20) NOT NULL DEFAULT 'add' CHECK (action_type IN ('add', 'remove', 'replace', 'repair', 'clean', 'detach_reset', 'minimum_charge')),
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1,
    unit_code VARCHAR(10) NOT NULL,
    labor_rate DECIMAL(10,2) NOT NULL DEFAULT 0,
    material_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    equipment_cost DECIMAL(10,2) NOT NULL DEFAULT 0,
    line_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    -- Insurance-specific
    depreciation_pct DECIMAL(5,2) NOT NULL DEFAULT 0,
    rcv DECIMAL(10,2) NOT NULL DEFAULT 0,
    acv DECIMAL(10,2) NOT NULL DEFAULT 0,
    coverage_group VARCHAR(20) DEFAULT 'structural' CHECK (coverage_group IN ('structural', 'contents', 'other')),
    phase INTEGER NOT NULL DEFAULT 1,
    is_supplement BOOLEAN NOT NULL DEFAULT false,
    -- Metadata
    notes TEXT,
    ai_suggested BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_line_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_line_items_select" ON estimate_line_items;
CREATE POLICY "estimate_line_items_select" ON estimate_line_items
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_line_items.estimate_id
            AND e.company_id = requesting_company_id()
            AND e.deleted_at IS NULL
        )
    );

DROP POLICY IF EXISTS "estimate_line_items_insert" ON estimate_line_items;
CREATE POLICY "estimate_line_items_insert" ON estimate_line_items
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_line_items.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_line_items_update" ON estimate_line_items;
CREATE POLICY "estimate_line_items_update" ON estimate_line_items
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_line_items.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_line_items_delete" ON estimate_line_items;
CREATE POLICY "estimate_line_items_delete" ON estimate_line_items
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_line_items.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

CREATE INDEX IF NOT EXISTS idx_line_items_estimate ON estimate_line_items(estimate_id);
CREATE INDEX IF NOT EXISTS idx_line_items_area ON estimate_line_items(area_id) WHERE area_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_line_items_item ON estimate_line_items(item_id) WHERE item_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_line_items_sort ON estimate_line_items(estimate_id, area_id, sort_order);


-- ============================================================
-- 10. ESTIMATE PHOTOS (evidence linked to estimates/areas/items)
-- ============================================================
CREATE TABLE IF NOT EXISTS estimate_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE,
    area_id UUID REFERENCES estimate_areas(id) ON DELETE SET NULL,
    line_item_id UUID REFERENCES estimate_line_items(id) ON DELETE SET NULL,
    storage_path VARCHAR(500) NOT NULL,
    caption TEXT,
    ai_analysis JSONB,
    taken_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE estimate_photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "estimate_photos_select" ON estimate_photos;
CREATE POLICY "estimate_photos_select" ON estimate_photos
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_photos.estimate_id
            AND e.company_id = requesting_company_id()
            AND e.deleted_at IS NULL
        )
    );

DROP POLICY IF EXISTS "estimate_photos_insert" ON estimate_photos;
CREATE POLICY "estimate_photos_insert" ON estimate_photos
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_photos.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

DROP POLICY IF EXISTS "estimate_photos_delete" ON estimate_photos;
CREATE POLICY "estimate_photos_delete" ON estimate_photos
    FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM estimates e
            WHERE e.id = estimate_photos.estimate_id
            AND e.company_id = requesting_company_id()
        )
    );

CREATE INDEX IF NOT EXISTS idx_estimate_photos_estimate ON estimate_photos(estimate_id);
CREATE INDEX IF NOT EXISTS idx_estimate_photos_area ON estimate_photos(area_id) WHERE area_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_estimate_photos_item ON estimate_photos(line_item_id) WHERE line_item_id IS NOT NULL;


-- ============================================================
-- Storage bucket for estimate photos
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('estimate-photos', 'estimate-photos', false)
ON CONFLICT DO NOTHING;
