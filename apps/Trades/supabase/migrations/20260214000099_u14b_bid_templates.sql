-- ============================================================
-- U14b: Bid Template Library — Table + 20 Trade Seed Templates
-- ============================================================

-- ============================================================
-- 1. Bid Templates Table
-- ============================================================
CREATE TABLE IF NOT EXISTS bid_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),  -- NULL = system template
  trade_type TEXT NOT NULL,
  category TEXT,  -- 'residential', 'commercial', 'service_call'
  name TEXT NOT NULL,
  description TEXT,
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{id, description, unit, defaultQuantity, defaultUnitPrice, category, tags, sortOrder}]
  add_ons JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- [{id, name, description, defaultPrice, sortOrder}]
  default_scope_of_work TEXT,
  default_terms TEXT,
  default_tax_rate NUMERIC(5,2) DEFAULT 0,
  default_deposit_percent NUMERIC(5,2) DEFAULT 0,
  default_validity_days INT DEFAULT 30,
  has_good_better_best BOOLEAN DEFAULT false,
  good_description TEXT,
  better_description TEXT,
  best_description TEXT,
  better_multiplier NUMERIC(3,2) DEFAULT 1.30,
  best_multiplier NUMERIC(3,2) DEFAULT 1.60,
  is_system BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  use_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE bid_templates ENABLE ROW LEVEL SECURITY;

-- System templates (company_id IS NULL) visible to all
CREATE POLICY "bid_templates_select" ON bid_templates
  FOR SELECT USING (
    company_id IS NULL
    OR company_id = requesting_company_id()
  );
CREATE POLICY "bid_templates_insert" ON bid_templates
  FOR INSERT WITH CHECK (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin','office_manager'));
CREATE POLICY "bid_templates_update" ON bid_templates
  FOR UPDATE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin','office_manager'));
CREATE POLICY "bid_templates_delete" ON bid_templates
  FOR DELETE USING (company_id = requesting_company_id() AND requesting_user_role() IN ('owner','admin'));

CREATE TRIGGER bid_templates_updated_at
  BEFORE UPDATE ON bid_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER audit_bid_templates
  AFTER INSERT OR UPDATE OR DELETE ON bid_templates
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- 2. Seed System Templates (20 trades)
-- ============================================================
INSERT INTO bid_templates (company_id, trade_type, category, name, description, line_items, default_scope_of_work, default_terms, default_deposit_percent, default_validity_days, has_good_better_best, good_description, better_description, best_description, is_system) VALUES

-- 1. Electrical
(NULL, 'electrical', 'residential', 'Electrical — Residential',
 'Standard residential electrical template with common items',
 '[
   {"id":"e1","description":"Duplex Outlet Install","unit":"each","defaultQuantity":1,"defaultUnitPrice":125,"category":"labor","sortOrder":1},
   {"id":"e2","description":"GFCI Outlet Install","unit":"each","defaultQuantity":1,"defaultUnitPrice":165,"category":"labor","sortOrder":2},
   {"id":"e3","description":"Light Switch — Single Pole","unit":"each","defaultQuantity":1,"defaultUnitPrice":95,"category":"labor","sortOrder":3},
   {"id":"e4","description":"Recessed Light Install","unit":"each","defaultQuantity":1,"defaultUnitPrice":185,"category":"labor","sortOrder":4},
   {"id":"e5","description":"Panel Upgrade — 200A","unit":"each","defaultQuantity":1,"defaultUnitPrice":2800,"category":"labor","sortOrder":5},
   {"id":"e6","description":"Circuit Addition — 20A","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"labor","sortOrder":6},
   {"id":"e7","description":"Ceiling Fan Install","unit":"each","defaultQuantity":1,"defaultUnitPrice":225,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Electrical work per attached scope. All work to meet current NEC code. Permit and inspection included.',
 'Payment due upon completion. Warranty: 1 year on labor. Manufacturer warranty on materials. Customer responsible for permit access.',
 25, 30, true, 'Standard grade fixtures', 'Mid-grade fixtures + smart switches', 'Premium fixtures + whole-home smart wiring', true),

-- 2. Plumbing
(NULL, 'plumbing', 'residential', 'Plumbing — Residential',
 'Standard residential plumbing template',
 '[
   {"id":"p1","description":"Toilet Install/Replace","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"labor","sortOrder":1},
   {"id":"p2","description":"Faucet Install — Kitchen","unit":"each","defaultQuantity":1,"defaultUnitPrice":275,"category":"labor","sortOrder":2},
   {"id":"p3","description":"Faucet Install — Bathroom","unit":"each","defaultQuantity":1,"defaultUnitPrice":225,"category":"labor","sortOrder":3},
   {"id":"p4","description":"Water Heater — 50gal Gas","unit":"each","defaultQuantity":1,"defaultUnitPrice":1800,"category":"labor","sortOrder":4},
   {"id":"p5","description":"Drain Clearing — Main Line","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"labor","sortOrder":5},
   {"id":"p6","description":"PEX Repipe — Per Fixture","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"labor","sortOrder":6}
 ]'::jsonb,
 'Plumbing work per attached scope. All materials meet local code. Permit and inspection included where required.',
 'Payment due upon completion. Warranty: 1 year on labor, manufacturer warranty on fixtures. Emergency call-backs within 24 hours.',
 0, 30, false, NULL, NULL, NULL, true),

-- 3. HVAC
(NULL, 'hvac', 'residential', 'HVAC — Residential',
 'HVAC installation and service template',
 '[
   {"id":"h1","description":"AC System — 3 Ton 16 SEER","unit":"each","defaultQuantity":1,"defaultUnitPrice":5500,"category":"materials","sortOrder":1},
   {"id":"h2","description":"Furnace — 80K BTU 95%+ AFUE","unit":"each","defaultQuantity":1,"defaultUnitPrice":3500,"category":"materials","sortOrder":2},
   {"id":"h3","description":"Thermostat — Smart WiFi","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"materials","sortOrder":3},
   {"id":"h4","description":"Ductwork — Flex Duct","unit":"foot","defaultQuantity":1,"defaultUnitPrice":18,"category":"materials","sortOrder":4},
   {"id":"h5","description":"Installation Labor","unit":"hour","defaultQuantity":16,"defaultUnitPrice":95,"category":"labor","sortOrder":5},
   {"id":"h6","description":"Refrigerant Charge","unit":"each","defaultQuantity":1,"defaultUnitPrice":250,"category":"materials","sortOrder":6}
 ]'::jsonb,
 'HVAC installation per specifications. Includes equipment, labor, refrigerant, startup, and cleanup. Permit and inspection included.',
 'Payment: 50% deposit, balance on completion. Equipment warranty per manufacturer (5-10 years). Labor warranty: 2 years.',
 50, 30, true, 'Standard efficiency (14 SEER)', 'High efficiency (16 SEER) + smart thermostat', 'Premium efficiency (18+ SEER) + zoning + air purifier', true),

-- 4. Roofing
(NULL, 'roofing', 'residential', 'Roofing — Residential',
 'Residential roof replacement template',
 '[
   {"id":"r1","description":"Tear-Off Existing Roof","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"labor","sortOrder":1},
   {"id":"r2","description":"Architectural Shingles","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":4.50,"category":"materials","sortOrder":2},
   {"id":"r3","description":"Synthetic Underlayment","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":0.65,"category":"materials","sortOrder":3},
   {"id":"r4","description":"Ice & Water Shield","unit":"foot","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"materials","sortOrder":4},
   {"id":"r5","description":"Ridge Vent","unit":"foot","defaultQuantity":1,"defaultUnitPrice":8.50,"category":"materials","sortOrder":5},
   {"id":"r6","description":"Drip Edge","unit":"foot","defaultQuantity":1,"defaultUnitPrice":3.00,"category":"materials","sortOrder":6},
   {"id":"r7","description":"Pipe Boots/Penetration Sealing","unit":"each","defaultQuantity":1,"defaultUnitPrice":45,"category":"materials","sortOrder":7},
   {"id":"r8","description":"Dumpster & Haul-Off","unit":"each","defaultQuantity":1,"defaultUnitPrice":500,"category":"equipment","sortOrder":8}
 ]'::jsonb,
 'Complete roof tear-off and replacement per specifications. Includes all materials, labor, cleanup, and magnetic nail sweep. Permit and inspection included.',
 'Payment: 1/3 deposit, 1/3 at material delivery, 1/3 on completion. Warranty: manufacturer shingle warranty + 5-year workmanship warranty.',
 33, 30, true, '3-tab shingles (25-year)', 'Architectural shingles (30-year lifetime)', 'Premium designer shingles + copper flashing', true),

-- 5. Painting
(NULL, 'painting', 'residential', 'Painting — Interior/Exterior',
 'Residential painting template',
 '[
   {"id":"pt1","description":"Interior Walls — 2 Coats","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"labor","sortOrder":1},
   {"id":"pt2","description":"Ceiling — 2 Coats","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.75,"category":"labor","sortOrder":2},
   {"id":"pt3","description":"Trim/Baseboard — 2 Coats","unit":"foot","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":3},
   {"id":"pt4","description":"Door — Both Sides","unit":"each","defaultQuantity":1,"defaultUnitPrice":125,"category":"labor","sortOrder":4},
   {"id":"pt5","description":"Exterior Siding — 2 Coats","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.00,"category":"labor","sortOrder":5},
   {"id":"pt6","description":"Prep — Scrape/Sand/Prime","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"labor","sortOrder":6},
   {"id":"pt7","description":"Cabinet Refinishing — Per Face","unit":"each","defaultQuantity":1,"defaultUnitPrice":85,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Painting per attached scope. Includes surface preparation, priming where needed, and two finish coats. Premium low-VOC paint.',
 'Payment due upon completion. Colors selected by customer before start. Warranty: 2 years on peeling/blistering from workmanship.',
 0, 30, true, 'Standard paint (PPG/Behr)', 'Premium paint (Sherwin-Williams Duration)', 'Ultra-premium (Benjamin Moore Aura) + accent walls', true),

-- 6. Concrete
(NULL, 'concrete', 'residential', 'Concrete — Residential',
 'Concrete flatwork and foundation template',
 '[
   {"id":"c1","description":"Concrete Slab — 4\" 3000 PSI","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":8.50,"category":"materials","sortOrder":1},
   {"id":"c2","description":"Rebar — #4 Grid 24\" OC","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"materials","sortOrder":2},
   {"id":"c3","description":"Excavation & Grade","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"labor","sortOrder":3},
   {"id":"c4","description":"Gravel Base — 4\"","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.25,"category":"materials","sortOrder":4},
   {"id":"c5","description":"Broom Finish","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":0.50,"category":"labor","sortOrder":5},
   {"id":"c6","description":"Stamped Concrete Finish","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":6.00,"category":"labor","sortOrder":6},
   {"id":"c7","description":"Expansion Joint — Sawcut","unit":"foot","defaultQuantity":1,"defaultUnitPrice":3.00,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Concrete work per specifications. Includes excavation, forming, pouring, finishing, and cleanup. Weather-dependent scheduling.',
 'Payment: 50% deposit, balance on completion. Concrete must cure 28 days before heavy use. Hairline cracks are normal and not a defect.',
 50, 30, true, 'Broom finish', 'Exposed aggregate or colored concrete', 'Stamped decorative with color hardener + sealer', true),

-- 7. Fencing
(NULL, 'fencing', 'residential', 'Fencing — Residential',
 'Fence installation template — all material types',
 '[
   {"id":"f1","description":"Cedar Privacy Fence — 6ft","unit":"foot","defaultQuantity":1,"defaultUnitPrice":38,"category":"materials","sortOrder":1},
   {"id":"f2","description":"Vinyl Privacy Fence — 6ft","unit":"foot","defaultQuantity":1,"defaultUnitPrice":42,"category":"materials","sortOrder":2},
   {"id":"f3","description":"Chain Link — 4ft Galvanized","unit":"foot","defaultQuantity":1,"defaultUnitPrice":18,"category":"materials","sortOrder":3},
   {"id":"f4","description":"Post — Set in Concrete","unit":"each","defaultQuantity":1,"defaultUnitPrice":45,"category":"labor","sortOrder":4},
   {"id":"f5","description":"Walk Gate","unit":"each","defaultQuantity":1,"defaultUnitPrice":175,"category":"materials","sortOrder":5},
   {"id":"f6","description":"Double Drive Gate","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"materials","sortOrder":6},
   {"id":"f7","description":"Old Fence Removal","unit":"foot","defaultQuantity":1,"defaultUnitPrice":5,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Fence installation per specifications. All posts set in concrete minimum 24\" deep. Property line verification is customer''s responsibility.',
 'Payment: 50% deposit at material order, balance on completion. Warranty: 1 year workmanship. Material warranty per manufacturer.',
 50, 30, true, 'Pressure-treated pine', 'Western red cedar', 'Premium cedar or vinyl with aluminum gate', true),

-- 8. Landscaping
(NULL, 'landscaping', 'residential', 'Landscaping — Residential',
 'Landscaping and hardscape template',
 '[
   {"id":"l1","description":"Sod Installation","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"materials","sortOrder":1},
   {"id":"l2","description":"Mulch — 3\" Depth","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.25,"category":"materials","sortOrder":2},
   {"id":"l3","description":"Shrub/Plant — 3-5gal","unit":"each","defaultQuantity":1,"defaultUnitPrice":65,"category":"materials","sortOrder":3},
   {"id":"l4","description":"Tree — 2\" Caliper","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"materials","sortOrder":4},
   {"id":"l5","description":"Retaining Wall — Block","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":35,"category":"materials","sortOrder":5},
   {"id":"l6","description":"Paver Patio","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":18,"category":"materials","sortOrder":6},
   {"id":"l7","description":"Irrigation — Per Zone","unit":"each","defaultQuantity":1,"defaultUnitPrice":650,"category":"materials","sortOrder":7},
   {"id":"l8","description":"Grading & Prep","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"labor","sortOrder":8}
 ]'::jsonb,
 'Landscaping per attached design. Includes all plants, materials, labor, and cleanup. Plant health warranty: 1 year with proper watering.',
 'Payment: 1/3 deposit, 1/3 at material delivery, 1/3 on completion. Plant warranty requires customer follow watering schedule provided.',
 33, 30, true, 'Standard plants + basic mulch', 'Premium plants + decorative stone + landscape lighting', 'Designer plants + hardscape + irrigation + lighting', true),

-- 9. Flooring
(NULL, 'flooring', 'residential', 'Flooring — Residential',
 'Flooring installation template — all material types',
 '[
   {"id":"fl1","description":"LVP — Luxury Vinyl Plank","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":6.50,"category":"materials","sortOrder":1},
   {"id":"fl2","description":"Hardwood — Engineered","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":9.00,"category":"materials","sortOrder":2},
   {"id":"fl3","description":"Tile — Porcelain","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":12.00,"category":"materials","sortOrder":3},
   {"id":"fl4","description":"Carpet — Mid Grade","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":5.50,"category":"materials","sortOrder":4},
   {"id":"fl5","description":"Subfloor Prep/Leveling","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.00,"category":"labor","sortOrder":5},
   {"id":"fl6","description":"Existing Floor Removal","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"labor","sortOrder":6},
   {"id":"fl7","description":"Transition Strips","unit":"each","defaultQuantity":1,"defaultUnitPrice":25,"category":"materials","sortOrder":7},
   {"id":"fl8","description":"Quarter Round/Baseboard","unit":"foot","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"materials","sortOrder":8}
 ]'::jsonb,
 'Flooring installation per specifications. Includes material, labor, transitions, and cleanup. Subfloor must be dry and level; additional prep billed if needed.',
 'Payment: material deposit at order, balance on completion. Warranty: 1 year workmanship. Material warranty per manufacturer.',
 30, 30, true, 'LVP or basic carpet', 'Engineered hardwood or premium LVP', 'Solid hardwood or natural stone', true),

-- 10. Drywall
(NULL, 'drywall', 'residential', 'Drywall — Residential',
 'Drywall hang, tape, and finish template',
 '[
   {"id":"d1","description":"Drywall Hang — 1/2\" Standard","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.25,"category":"materials","sortOrder":1},
   {"id":"d2","description":"Drywall Hang — 5/8\" Fire Rated","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.75,"category":"materials","sortOrder":2},
   {"id":"d3","description":"Tape & Float — Level 4","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.75,"category":"labor","sortOrder":3},
   {"id":"d4","description":"Tape & Float — Level 5","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"labor","sortOrder":4},
   {"id":"d5","description":"Texture — Knockdown","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.25,"category":"labor","sortOrder":5},
   {"id":"d6","description":"Texture — Orange Peel","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.00,"category":"labor","sortOrder":6},
   {"id":"d7","description":"Patch — Large (>2sqft)","unit":"each","defaultQuantity":1,"defaultUnitPrice":150,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Drywall installation and finishing per specifications. Includes materials, labor, and cleanup. Customer to select finish level before start.',
 'Payment due upon completion. Warranty: 1 year on cracking from workmanship (not structural settling).',
 0, 30, false, NULL, NULL, NULL, true),

-- 11. Solar
(NULL, 'solar', 'residential', 'Solar — Residential',
 'Solar panel installation template',
 '[
   {"id":"s1","description":"Solar Panel — 400W Mono","unit":"each","defaultQuantity":20,"defaultUnitPrice":350,"category":"materials","sortOrder":1},
   {"id":"s2","description":"Racking System","unit":"each","defaultQuantity":1,"defaultUnitPrice":2500,"category":"materials","sortOrder":2},
   {"id":"s3","description":"Inverter — String 7.6kW","unit":"each","defaultQuantity":1,"defaultUnitPrice":2200,"category":"materials","sortOrder":3},
   {"id":"s4","description":"Battery — 10kWh","unit":"each","defaultQuantity":1,"defaultUnitPrice":8500,"category":"materials","sortOrder":4},
   {"id":"s5","description":"Electrical/Wiring","unit":"each","defaultQuantity":1,"defaultUnitPrice":1500,"category":"labor","sortOrder":5},
   {"id":"s6","description":"Permit + Utility Interconnection","unit":"each","defaultQuantity":1,"defaultUnitPrice":800,"category":"permits","sortOrder":6},
   {"id":"s7","description":"Installation Labor","unit":"each","defaultQuantity":1,"defaultUnitPrice":3000,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Solar panel installation per design. Includes panels, racking, inverter, wiring, permit, utility interconnection, and monitoring setup.',
 'Payment: 30% deposit, 40% at equipment delivery, 30% on PTO (Permission to Operate). 25-year panel warranty. 10-year inverter warranty. 10-year workmanship warranty.',
 30, 45, true, 'Standard panels + string inverter', 'Premium panels + microinverters + monitoring', 'Premium panels + microinverters + battery storage', true),

-- 12. Siding
(NULL, 'siding', 'residential', 'Siding — Residential',
 'Siding replacement template',
 '[
   {"id":"sd1","description":"Vinyl Siding","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":5.50,"category":"materials","sortOrder":1},
   {"id":"sd2","description":"Fiber Cement (HardiePlank)","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":9.50,"category":"materials","sortOrder":2},
   {"id":"sd3","description":"House Wrap (Tyvek)","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":0.75,"category":"materials","sortOrder":3},
   {"id":"sd4","description":"Soffit","unit":"foot","defaultQuantity":1,"defaultUnitPrice":8.00,"category":"materials","sortOrder":4},
   {"id":"sd5","description":"Fascia","unit":"foot","defaultQuantity":1,"defaultUnitPrice":7.00,"category":"materials","sortOrder":5},
   {"id":"sd6","description":"Old Siding Removal","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.25,"category":"labor","sortOrder":6}
 ]'::jsonb,
 'Siding replacement per specifications. Includes removal of existing, house wrap, new siding, trim, and cleanup.',
 'Payment: 1/3 deposit at material order, 1/3 mid-project, 1/3 on completion. Manufacturer warranty on materials. 5-year workmanship warranty.',
 33, 30, true, 'Vinyl siding', 'Fiber cement (HardiePlank)', 'Engineered wood or premium fiber cement + custom trim', true),

-- 13. Gutters
(NULL, 'gutters', 'residential', 'Gutters — Residential',
 'Gutter installation and repair template',
 '[
   {"id":"g1","description":"Seamless Aluminum Gutter — 5\"","unit":"foot","defaultQuantity":1,"defaultUnitPrice":12,"category":"materials","sortOrder":1},
   {"id":"g2","description":"Seamless Aluminum Gutter — 6\"","unit":"foot","defaultQuantity":1,"defaultUnitPrice":15,"category":"materials","sortOrder":2},
   {"id":"g3","description":"Downspout — 3x4","unit":"foot","defaultQuantity":1,"defaultUnitPrice":8,"category":"materials","sortOrder":3},
   {"id":"g4","description":"Gutter Guard — Mesh","unit":"foot","defaultQuantity":1,"defaultUnitPrice":10,"category":"materials","sortOrder":4},
   {"id":"g5","description":"Existing Gutter Removal","unit":"foot","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"labor","sortOrder":5}
 ]'::jsonb,
 'Gutter installation per specifications. Seamless gutters fabricated on-site. Includes hangers, outlets, end caps, and downspout extensions.',
 'Payment due upon completion. Warranty: 5 years on leaks at seams. Material warranty per manufacturer.',
 0, 30, true, '5\" aluminum K-style', '6\" aluminum with gutter guards', 'Copper half-round with custom downspouts', true),

-- 14. Insulation
(NULL, 'insulation', 'residential', 'Insulation — Residential',
 'Insulation installation template',
 '[
   {"id":"i1","description":"Batt Insulation — R-13 Wall","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"materials","sortOrder":1},
   {"id":"i2","description":"Batt Insulation — R-30 Attic","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.25,"category":"materials","sortOrder":2},
   {"id":"i3","description":"Blown Insulation — Attic","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.75,"category":"materials","sortOrder":3},
   {"id":"i4","description":"Spray Foam — Open Cell","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"materials","sortOrder":4},
   {"id":"i5","description":"Spray Foam — Closed Cell","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":6.00,"category":"materials","sortOrder":5},
   {"id":"i6","description":"Rigid Foam Board — 2\"","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"materials","sortOrder":6},
   {"id":"i7","description":"Vapor Barrier","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":0.50,"category":"materials","sortOrder":7}
 ]'::jsonb,
 'Insulation installation per specifications. R-value meets or exceeds local energy code requirements. Includes labor, materials, and cleanup.',
 'Payment due upon completion. Warranty: manufacturer warranty on materials. Workmanship warranty: 1 year.',
 0, 30, true, 'Fiberglass batt (standard)', 'Blown-in cellulose + air sealing', 'Closed-cell spray foam + vapor barrier', true),

-- 15. Demolition
(NULL, 'demolition', 'residential', 'Demolition — Interior/Exterior',
 'Demolition and haul-off template',
 '[
   {"id":"dm1","description":"Drywall Demo","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.00,"category":"labor","sortOrder":1},
   {"id":"dm2","description":"Flooring Demo","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.75,"category":"labor","sortOrder":2},
   {"id":"dm3","description":"Cabinet Removal","unit":"foot","defaultQuantity":1,"defaultUnitPrice":12.00,"category":"labor","sortOrder":3},
   {"id":"dm4","description":"Tile Demo","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":4},
   {"id":"dm5","description":"Fixture Removal","unit":"each","defaultQuantity":1,"defaultUnitPrice":75,"category":"labor","sortOrder":5},
   {"id":"dm6","description":"Dumpster — 20yd","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"equipment","sortOrder":6},
   {"id":"dm7","description":"Haul-Off — Truckload","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"equipment","sortOrder":7}
 ]'::jsonb,
 'Demolition per scope. Includes protective measures for adjacent areas. Customer to verify no hazardous materials (asbestos/lead).',
 'Payment: 50% at start, 50% on completion. Price assumes no hazardous materials. Hazmat abatement billed separately if discovered.',
 50, 30, false, NULL, NULL, NULL, true),

-- 16. Water Restoration
(NULL, 'water_restoration', 'residential', 'Water Damage — Restoration',
 'Water damage mitigation and restoration template',
 '[
   {"id":"w1","description":"Water Extraction","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":1},
   {"id":"w2","description":"Structural Drying — Per Day","unit":"each","defaultQuantity":3,"defaultUnitPrice":350,"category":"equipment","sortOrder":2},
   {"id":"w3","description":"Dehumidifier — Per Day","unit":"each","defaultQuantity":3,"defaultUnitPrice":75,"category":"equipment","sortOrder":3},
   {"id":"w4","description":"Air Mover — Per Day","unit":"each","defaultQuantity":3,"defaultUnitPrice":50,"category":"equipment","sortOrder":4},
   {"id":"w5","description":"Antimicrobial Treatment","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":2.50,"category":"materials","sortOrder":5},
   {"id":"w6","description":"Moisture Testing/Monitoring","unit":"each","defaultQuantity":3,"defaultUnitPrice":150,"category":"labor","sortOrder":6},
   {"id":"w7","description":"Content Manipulation","unit":"each","defaultQuantity":1,"defaultUnitPrice":500,"category":"labor","sortOrder":7}
 ]'::jsonb,
 'Water damage mitigation per IICRC S500 standards. Includes extraction, drying, monitoring, and antimicrobial treatment. Rebuild scope quoted separately.',
 'Emergency response. Insurance billing available. Payment: insurance proceeds or customer payment within 30 days of completion.',
 0, 14, false, NULL, NULL, NULL, true),

-- 17. Fire/Smoke Restoration
(NULL, 'fire_restoration', 'residential', 'Fire/Smoke Damage — Restoration',
 'Fire and smoke damage restoration template',
 '[
   {"id":"fr1","description":"Board-Up Service","unit":"each","defaultQuantity":1,"defaultUnitPrice":500,"category":"labor","sortOrder":1},
   {"id":"fr2","description":"Smoke/Soot Cleaning — Walls","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":2},
   {"id":"fr3","description":"Smoke/Soot Cleaning — Ceiling","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":4.00,"category":"labor","sortOrder":3},
   {"id":"fr4","description":"Thermal Fogging","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.50,"category":"equipment","sortOrder":4},
   {"id":"fr5","description":"Ozone Treatment — Per Room","unit":"each","defaultQuantity":1,"defaultUnitPrice":350,"category":"equipment","sortOrder":5},
   {"id":"fr6","description":"Contents Pack-Out","unit":"each","defaultQuantity":1,"defaultUnitPrice":2500,"category":"labor","sortOrder":6},
   {"id":"fr7","description":"HEPA Air Scrubber — Per Day","unit":"each","defaultQuantity":3,"defaultUnitPrice":75,"category":"equipment","sortOrder":7}
 ]'::jsonb,
 'Fire/smoke damage restoration per IICRC S540 standards. Includes cleaning, deodorization, and contents handling. Rebuild scope quoted separately.',
 'Emergency response. Insurance billing available. Payment: insurance proceeds or customer payment within 30 days.',
 0, 14, false, NULL, NULL, NULL, true),

-- 18. General Remodel
(NULL, 'general_remodel', 'residential', 'General Remodel — Residential',
 'Multi-trade home remodel template',
 '[
   {"id":"gr1","description":"Project Management — Weekly","unit":"each","defaultQuantity":1,"defaultUnitPrice":1500,"category":"labor","sortOrder":1},
   {"id":"gr2","description":"Demolition","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.00,"category":"labor","sortOrder":2},
   {"id":"gr3","description":"Framing Modifications","unit":"foot","defaultQuantity":1,"defaultUnitPrice":12.00,"category":"labor","sortOrder":3},
   {"id":"gr4","description":"Electrical Rough-In","unit":"each","defaultQuantity":1,"defaultUnitPrice":250,"category":"labor","sortOrder":4},
   {"id":"gr5","description":"Plumbing Rough-In","unit":"each","defaultQuantity":1,"defaultUnitPrice":300,"category":"labor","sortOrder":5},
   {"id":"gr6","description":"Drywall — Complete","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":4.50,"category":"materials","sortOrder":6},
   {"id":"gr7","description":"Finish Work — Trim/Paint","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":7},
   {"id":"gr8","description":"Permit + Inspections","unit":"each","defaultQuantity":1,"defaultUnitPrice":500,"category":"permits","sortOrder":8}
 ]'::jsonb,
 'Home remodel per attached scope and plans. Multi-trade project managed by general contractor. All sub-trades included. Permit and inspections included.',
 'Payment: draw schedule based on milestones. Typical: 10% deposit, then draws at framing, rough-in, drywall, finish. 10% holdback until final inspection.',
 10, 45, true, 'Builder-grade finishes', 'Mid-range finishes + upgraded fixtures', 'Premium finishes + custom millwork + designer fixtures', true),

-- 19. Paving
(NULL, 'paving', 'residential', 'Paving — Driveways & Patios',
 'Asphalt and paver installation template',
 '[
   {"id":"pv1","description":"Asphalt — Driveway","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":5.50,"category":"materials","sortOrder":1},
   {"id":"pv2","description":"Concrete Pavers — Standard","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":14.00,"category":"materials","sortOrder":2},
   {"id":"pv3","description":"Brick Pavers","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":18.00,"category":"materials","sortOrder":3},
   {"id":"pv4","description":"Base Prep — Gravel + Sand","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":3.50,"category":"labor","sortOrder":4},
   {"id":"pv5","description":"Edging/Restraints","unit":"foot","defaultQuantity":1,"defaultUnitPrice":4.00,"category":"materials","sortOrder":5},
   {"id":"pv6","description":"Polymeric Sand","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":1.20,"category":"materials","sortOrder":6},
   {"id":"pv7","description":"Seal Coat","unit":"sqft","defaultQuantity":1,"defaultUnitPrice":0.85,"category":"materials","sortOrder":7}
 ]'::jsonb,
 'Paving per specifications. Includes excavation, base preparation, material, installation, and cleanup. Weather-dependent scheduling.',
 'Payment: 50% deposit at material order, balance on completion. Warranty: 2 years on workmanship. Asphalt seal coat recommended annually.',
 50, 30, true, 'Standard asphalt', 'Concrete pavers + edge restraints', 'Natural stone or premium brick + lighting + sealer', true),

-- 20. Windows & Doors
(NULL, 'windows_doors', 'residential', 'Windows & Doors — Replacement',
 'Window and door replacement template',
 '[
   {"id":"wd1","description":"Vinyl Window — Double Hung","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"materials","sortOrder":1},
   {"id":"wd2","description":"Vinyl Window — Sliding","unit":"each","defaultQuantity":1,"defaultUnitPrice":400,"category":"materials","sortOrder":2},
   {"id":"wd3","description":"Entry Door — Fiberglass","unit":"each","defaultQuantity":1,"defaultUnitPrice":1200,"category":"materials","sortOrder":3},
   {"id":"wd4","description":"Sliding Patio Door","unit":"each","defaultQuantity":1,"defaultUnitPrice":1500,"category":"materials","sortOrder":4},
   {"id":"wd5","description":"Interior Trim — Per Window","unit":"each","defaultQuantity":1,"defaultUnitPrice":85,"category":"labor","sortOrder":5},
   {"id":"wd6","description":"Exterior Trim/Capping","unit":"each","defaultQuantity":1,"defaultUnitPrice":120,"category":"labor","sortOrder":6},
   {"id":"wd7","description":"Storm Door","unit":"each","defaultQuantity":1,"defaultUnitPrice":450,"category":"materials","sortOrder":7}
 ]'::jsonb,
 'Window/door replacement per specifications. Full frame or insert installation. Includes trim, caulking, insulation, and cleanup.',
 'Payment: 50% deposit at material order, balance on installation. Manufacturer warranty on products. 2-year installation warranty.',
 50, 30, true, 'Standard vinyl', 'Premium vinyl + Low-E glass', 'Fiberglass or wood-clad + triple-pane', true);
