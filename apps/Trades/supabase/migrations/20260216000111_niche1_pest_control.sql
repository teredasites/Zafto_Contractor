-- NICHE1: Pest Control Module
-- Treatment logs, bait stations, WDI/NPMA-33 reports
-- Tables: treatment_logs, bait_stations, wdi_reports

-- ============================================================
-- TREATMENT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS treatment_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id),
    job_id UUID REFERENCES jobs(id),
    property_id UUID REFERENCES properties(id),

    -- Service info
    service_type TEXT NOT NULL DEFAULT 'general_pest'
        CHECK (service_type IN ('general_pest','termite','mosquito','bed_bug','wildlife','fumigation','rodent','ant','cockroach','tick_flea','spider','wasp_bee','bird','exclusion')),
    treatment_type TEXT NOT NULL DEFAULT 'spray'
        CHECK (treatment_type IN ('spray','bait','trap','fog','dust','granular','heat','fumigation','exclusion','monitoring')),
    target_pests TEXT[] DEFAULT '{}',

    -- Chemical application
    chemical_name TEXT,
    epa_registration_number TEXT,
    active_ingredient TEXT,
    application_rate TEXT,
    dilution_ratio TEXT,
    amount_used TEXT,
    concentration TEXT,
    application_method TEXT,

    -- Treatment area
    areas_treated JSONB DEFAULT '[]',
    target_area_sqft NUMERIC,

    -- Weather / conditions
    weather_conditions JSONB DEFAULT '{}',
    temperature_f NUMERIC,
    wind_mph NUMERIC,

    -- Applicator
    applicator_id UUID REFERENCES auth.users(id),
    applicator_name TEXT,
    license_number TEXT,

    -- Timing
    re_entry_time_hours NUMERIC,
    next_service_date DATE,
    service_frequency TEXT CHECK (service_frequency IN ('one_time','monthly','bi_monthly','quarterly','semi_annual','annual')),

    -- Documentation
    photos JSONB DEFAULT '[]',
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ============================================================
-- BAIT STATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS bait_stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id),
    property_id UUID REFERENCES properties(id),
    floor_plan_id UUID,

    -- Station info
    station_number TEXT NOT NULL,
    station_type TEXT NOT NULL DEFAULT 'rodent'
        CHECK (station_type IN ('rodent','ant','cockroach','termite','fly','multi_pest')),
    station_brand TEXT,
    station_model TEXT,

    -- Location
    location_description TEXT,
    x_coordinate NUMERIC,
    y_coordinate NUMERIC,
    placement_zone TEXT CHECK (placement_zone IN ('interior','exterior','perimeter','attic','crawlspace','garage','basement','roof')),

    -- Status
    bait_type TEXT,
    activity_level TEXT DEFAULT 'none'
        CHECK (activity_level IN ('none','low','moderate','high','critical')),
    last_serviced_at TIMESTAMPTZ,
    last_serviced_by UUID REFERENCES auth.users(id),
    next_service_date DATE,

    -- Tracking
    install_date DATE,
    replacement_schedule_days INTEGER,
    bait_consumption_pct NUMERIC,
    photos JSONB DEFAULT '[]',
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ============================================================
-- WDI REPORTS (NPMA-33)
-- ============================================================
CREATE TABLE IF NOT EXISTS wdi_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id),
    job_id UUID REFERENCES jobs(id),
    property_id UUID REFERENCES properties(id),

    -- Report info
    report_type TEXT NOT NULL DEFAULT 'npma_33'
        CHECK (report_type IN ('npma_33','state_specific','va','fha')),
    report_number TEXT,

    -- Property
    property_address TEXT,
    property_city TEXT,
    property_state TEXT,
    property_zip TEXT,

    -- Inspector
    inspector_name TEXT,
    inspector_license TEXT,
    inspector_company TEXT,
    inspection_date DATE,

    -- Findings
    findings JSONB DEFAULT '[]',
    diagrams JSONB DEFAULT '[]',
    infestation_found BOOLEAN DEFAULT false,
    damage_found BOOLEAN DEFAULT false,
    treatment_recommended BOOLEAN DEFAULT false,

    -- Evidence types
    live_insects_found BOOLEAN DEFAULT false,
    dead_insects_found BOOLEAN DEFAULT false,
    damage_visible BOOLEAN DEFAULT false,
    frass_found BOOLEAN DEFAULT false,
    shelter_tubes_found BOOLEAN DEFAULT false,
    exit_holes_found BOOLEAN DEFAULT false,
    moisture_damage BOOLEAN DEFAULT false,

    -- Insects identified
    insects_identified TEXT[] DEFAULT '{}',

    -- Recommendations
    recommendations TEXT,
    treatment_plan TEXT,
    estimated_cost NUMERIC,

    -- Report
    report_pdf_url TEXT,

    -- Status
    report_status TEXT DEFAULT 'draft'
        CHECK (report_status IN ('draft','complete','submitted','accepted','rejected')),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE treatment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bait_stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE wdi_reports ENABLE ROW LEVEL SECURITY;

-- treatment_logs
CREATE POLICY treatment_logs_select ON treatment_logs FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY treatment_logs_insert ON treatment_logs FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY treatment_logs_update ON treatment_logs FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY treatment_logs_delete ON treatment_logs FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- bait_stations
CREATE POLICY bait_stations_select ON bait_stations FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY bait_stations_insert ON bait_stations FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY bait_stations_update ON bait_stations FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY bait_stations_delete ON bait_stations FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- wdi_reports
CREATE POLICY wdi_reports_select ON wdi_reports FOR SELECT USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY wdi_reports_insert ON wdi_reports FOR INSERT WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY wdi_reports_update ON wdi_reports FOR UPDATE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY wdi_reports_delete ON wdi_reports FOR DELETE USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_treatment_logs_company ON treatment_logs(company_id);
CREATE INDEX idx_treatment_logs_job ON treatment_logs(job_id);
CREATE INDEX idx_treatment_logs_property ON treatment_logs(property_id);
CREATE INDEX idx_treatment_logs_next_service ON treatment_logs(next_service_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_bait_stations_company ON bait_stations(company_id);
CREATE INDEX idx_bait_stations_property ON bait_stations(property_id);
CREATE INDEX idx_wdi_reports_company ON wdi_reports(company_id);
CREATE INDEX idx_wdi_reports_job ON wdi_reports(job_id);

-- ============================================================
-- AUDIT TRIGGERS
-- ============================================================
CREATE TRIGGER treatment_logs_updated_at BEFORE UPDATE ON treatment_logs FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER bait_stations_updated_at BEFORE UPDATE ON bait_stations FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER wdi_reports_updated_at BEFORE UPDATE ON wdi_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER treatment_logs_audit AFTER INSERT OR UPDATE OR DELETE ON treatment_logs FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER bait_stations_audit AFTER INSERT OR UPDATE OR DELETE ON bait_stations FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
CREATE TRIGGER wdi_reports_audit AFTER INSERT OR UPDATE OR DELETE ON wdi_reports FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- SEED DATA: Common pest control chemicals
-- ============================================================
INSERT INTO line_items (company_id, name, description, category, unit, unit_cost, trade) VALUES
    ('00000000-0000-0000-0000-000000000000', 'General Pest Treatment — Interior', 'Interior spray treatment for general pests (ants, roaches, spiders)', 'pest_control', 'per_visit', 85.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'General Pest Treatment — Exterior', 'Exterior perimeter spray treatment', 'pest_control', 'per_visit', 65.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Termite Treatment — Liquid', 'Liquid termiticide treatment per linear foot', 'pest_control', 'lf', 8.50, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Termite Treatment — Bait System', 'Sentricon/Advance bait station per station', 'pest_control', 'each', 35.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Bed Bug Treatment — Chemical', 'Chemical treatment per room', 'pest_control', 'each', 250.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Bed Bug Treatment — Heat', 'Heat treatment per room (140°F)', 'pest_control', 'each', 750.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Mosquito Treatment — Yard', 'Yard spray/mist treatment', 'pest_control', 'per_visit', 75.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Rodent Exclusion', 'Seal entry points per opening', 'pest_control', 'each', 45.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Rodent Bait Station — Install', 'Exterior tamper-resistant bait station', 'pest_control', 'each', 55.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Rodent Bait Station — Service', 'Monthly bait station inspection/refill', 'pest_control', 'each', 15.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Wildlife Removal — Trapping', 'Live trap set per animal', 'pest_control', 'each', 125.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Wildlife Exclusion — Attic', 'Seal attic entry points after removal', 'pest_control', 'per_job', 350.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Fumigation — Tent', 'Structural fumigation per 1000 sqft', 'pest_control', 'per_1000sf', 1200.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'WDI Inspection — NPMA-33', 'Wood Destroying Insect inspection report', 'pest_control', 'each', 150.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Crawlspace Treatment', 'Crawlspace pest treatment and moisture barrier', 'pest_control', 'per_job', 225.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Ant Treatment — Fire Ant Mound', 'Individual fire ant mound treatment', 'pest_control', 'each', 25.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Wasp/Bee Nest Removal', 'Nest removal and treatment', 'pest_control', 'each', 175.00, 'pest_control'),
    ('00000000-0000-0000-0000-000000000000', 'Tick/Flea Yard Treatment', 'Yard broadcast spray for ticks and fleas', 'pest_control', 'per_visit', 95.00, 'pest_control')
ON CONFLICT DO NOTHING;
