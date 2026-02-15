# ZAFTO Expansion Spec #40: Property Intelligence Engine (Recon)
## Created: February 9, 2026 (Session 93)

---

## OVERVIEW

Satellite-powered property measurement and intelligence tool built into ZAFTO. Contractor enters an address → ZAFTO instantly returns roof measurements, wall areas, property dimensions, material type detection, and trade-specific bid data — all without a site visit. Measurements flow directly into the estimate engine (D8), material ordering (Unwrangle/ABC Supply), and job creation.

**Product name:** Recon
**Target market:** Every contractor on ZAFTO. This is a platform-wide feature, not a module.
**Value prop:** Replace $18-$100+ EagleView reports with instant, unlimited property intelligence included in ZAFTO subscription. Measurements feed directly into estimates and material orders — no PDF middleman, no per-report fees.

**What EagleView charges:**
- Bid Perfect (basic): $18/report
- Premium Roof: $24.25/report
- Walls: $40/report
- Walls, Windows & Doors: $67.50/report
- Full House (everything): $91/report
- Insurance adjusters pay $100+/report

**What ZAFTO charges:** $0 per scan. Unlimited. Included in subscription. This alone justifies the monthly fee for roofing, siding, solar, and painting contractors.

---

## ARCHITECTURE: PLATFORM FEATURE, NOT A MODULE

Unlike TPA (optional module), Recon is a **core platform feature** available to all contractors. No feature flag needed. Every contractor benefits from property intelligence regardless of trade.

Recon runs as a server-side pipeline:
1. **Input:** Street address (or lat/long from job record)
2. **Data Aggregation:** Parallel API calls to multiple providers
3. **AI Enhancement:** Computer vision analysis on satellite imagery (Phase E)
4. **Output:** Structured property report stored in database, linked to job
5. **Integration:** Measurements auto-populate estimates, material calculators, and supply orders

---

## DATA SOURCES (Layered Architecture — No Single Point of Failure)

### Tier 1: FREE Sources (Day 1 — $0/month launch stack)

**STANDING RULE: Launch with $0/month APIs. Paid sources are post-revenue additions only. Every feature MUST have a free-tier fallback.**

| Source | What It Provides | Cost | Coverage |
|--------|-----------------|------|----------|
| **Google Solar API** | Roof segments, pitch (degrees), azimuth, area (m²), shade analysis, sun hours, solar potential | FREE (10K calls/month free tier) | 99%+ US residential |
| **Microsoft Building Footprints** | 1.4B building polygons, ground-level footprint area | FREE (open data, ODbL license) | All 50 US states |
| **USGS 3D Elevation Program** | LIDAR elevation data, terrain slope, building height derivation | FREE (public data) | Expanding US coverage |
| **NOAA Storm Events + NEXRAD** | Historical storms, hail size, wind speed, GPS, radar | FREE (public data) | US nationwide |
| **OpenStreetMap** | Building footprints, road access, nearby structures | FREE (open data) | Global |
| **Mapbox Satellite** | High-res satellite tiles (7.5cm+ at zoom 21), 15cm metro areas | Already integrated (existing ZAFTO account, 200K tiles/mo free) | Global |
| **Google Maps Geocoding** | Address → lat/lng conversion | FREE (10K calls/month free tier) | Global |

### Tier 2: Paid Sources (Post-Revenue — enable when MRR justifies cost)

| Source | What It Provides | Cost | When to Add |
|--------|-----------------|------|-------------|
| **ATTOM Property API** | Year built, lot size, stories, sq footage, beds/baths, pool, construction type, heating/cooling, roof type (from tax records), assessed value, owner info | ~$500/month minimum | When lead scoring ROI is proven — enriches scores from "Basic" to "Full" |
| **Regrid** | 159M parcel boundaries, lot dimensions, zoning, owner info | Volume-based (~$80K/yr enterprise) | When batch area scanning demand justifies — replaces manual parcel draw |
| **Regrid Building Footprints** | 187M building footprints matched to parcels | Premium add-on to Regrid | Bundle with Regrid if added |

**Free fallbacks when Tier 2 not enabled:**
- Without ATTOM → Lead scoring uses free signals (roof area, complexity, storm proximity, building size). Shows "Basic Score" badge.
- Without Regrid → Users draw property boundary on Mapbox map (draw tools free). System calculates lot area from drawn polygon.

### KILLED — Not on roadmap (enterprise-priced, no API, or not viable)

| Source | Why Killed |
|--------|-----------|
| **Nearmap AI** | Enterprise-only pricing, annual contract. No free tier. 130+ AI features are impressive but cost-prohibitive at launch. Re-evaluate post-$50K MRR. |
| **Beam AI** | No public API. Paving-only tool. Can't integrate. |
| **SiteRecon** | No clear public API. Landscaping-only. Custom pricing. |
| **Hover** | $25/job or $999/yr minimum. 3D from photos is cool but not essential when satellite + footprints cover 80% of use cases. |
| **EagleView** | $18-91/report (competitor, not partner). Free developer trial launched Nov 2025 — monitor but don't depend on. |

### Tier 3: AI/CV Enhancement (Phase E)

| Capability | How | Accuracy |
|-----------|-----|----------|
| Roof segmentation from satellite | MaskFormer / U-Net on Mapbox tiles | ~80% IoU (improving) |
| Roof material classification | CNN on satellite imagery | Shingle/tile/metal/other |
| Building height estimation | Shadow analysis + LIDAR fusion | ±1 story |
| Tree canopy coverage | Semantic segmentation | ±5% area |
| Hardscape vs softscape | Land cover classification | ~85% accuracy |
| Fence line detection | Object detection on satellite tiles | ~75% accuracy |
| Vehicle/equipment detection | YOLO-family models | ~80% accuracy |

### Tier 4: Contractor's Own Data (Drone — Future)

| Capability | Technology | Notes |
|-----------|-----------|-------|
| High-res roof photos | DJI SDK integration | Requires physical drone hardware |
| Precise roof measurements | Photogrammetry from drone photos | Sub-inch accuracy possible |
| 3D model generation | Structure from Motion (SfM) | Full property 3D model |
| Thermal imaging | DJI thermal camera | Insulation/moisture detection |

**Drone integration is Phase E+ / post-launch.** Requires physical hardware testing, not software-only.

---

## ACCURACY TARGETS

| Measurement | Day 1 (API-only) | With AI/CV (Phase E) | EagleView Benchmark |
|------------|-------------------|---------------------|-------------------|
| Roof total area | ±3-5% | ±1-2% | 98.77% (±1.23%) |
| Roof pitch | ±1 pitch unit (e.g., 8/12 vs 9/12) | ±0.5 pitch units | 98%+ |
| Roof facet count | ±1-2 facets | ±1 facet | 98%+ |
| Building footprint | ±2-3% | ±1% | N/A |
| Lot dimensions | ±1-2% (from GIS) | Same | N/A |
| Wall area (derived) | ±10-15% (footprint × stories × avg height) | ±5% (with LIDAR) | 95%+ |
| Window/door count | NOT available Day 1 | ±1-2 (from street view AI) | 95%+ |

**Day 1 honest limitations:**
- Wall measurements are DERIVED (footprint × estimated height), not directly measured from imagery
- Window/door counts require street-level imagery analysis (Phase E AI)
- Roof pitch from Google Solar API may not distinguish between similar pitches (8/12 vs 9/12)
- Tree-covered portions of roof reduce accuracy
- Flat commercial roofs are more accurate than complex residential roofs

**We do NOT claim to match EagleView Day 1.** We claim: instant, free, accurate enough to bid, with measurements flowing directly into estimates and material orders. EagleView accuracy comes at $18-91 per report. Ours is $0.

---

## DATABASE SCHEMA

### New Tables (~8 tables)

```sql
-- ============================================================
-- PROPERTY INTELLIGENCE (RECON) TABLES
-- ============================================================

-- PI1: Property Scans (one per address lookup)
CREATE TABLE property_scans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id),
  job_id uuid REFERENCES jobs(id), -- optional link to job
  -- Address
  address_line1 text NOT NULL,
  address_line2 text,
  city text NOT NULL,
  state text NOT NULL,
  zip text NOT NULL,
  latitude numeric(10,7),
  longitude numeric(10,7),
  -- Scan metadata
  scan_status text NOT NULL DEFAULT 'pending',
  -- CHECK (scan_status IN ('pending', 'processing', 'complete', 'partial', 'failed'))
  scanned_at timestamptz,
  data_sources text[] DEFAULT '{}', -- ['google_solar', 'attom', 'regrid', 'microsoft_footprint', 'nearmap']
  scan_version integer DEFAULT 1, -- increment when re-scanned
  -- Property basics (from ATTOM / tax records)
  year_built integer,
  stories numeric(3,1), -- 1, 1.5, 2, 2.5, 3
  total_sqft numeric(10,2),
  lot_sqft numeric(12,2),
  lot_acres numeric(8,4),
  property_type text, -- 'single_family', 'multi_family', 'commercial', 'townhouse', 'condo'
  construction_type text, -- 'wood_frame', 'masonry', 'steel', 'concrete'
  -- Exterior (from ATTOM + AI)
  roof_type_tax text, -- from tax records: 'composition_shingle', 'tile', 'metal', 'wood_shake', 'slate', 'flat'
  roof_type_detected text, -- from AI/Nearmap: 'shingle', 'tile', 'metal', 'other'
  exterior_wall_type text, -- 'vinyl_siding', 'brick', 'stucco', 'wood', 'stone', 'hardie_board'
  pool_present boolean DEFAULT false,
  fence_present boolean DEFAULT false,
  solar_panels_present boolean DEFAULT false,
  -- HVAC (from ATTOM)
  heating_type text,
  heating_fuel text,
  cooling_type text,
  -- Financial context
  assessed_value numeric(14,2),
  last_sale_price numeric(14,2),
  last_sale_date date,
  -- Nearmap AI scores (Tier 2, null until Nearmap integrated)
  roof_condition_score numeric(5,2), -- 0-100
  tree_overhang_percent numeric(5,2),
  -- Raw API responses (JSONB for future-proofing)
  google_solar_data jsonb DEFAULT '{}',
  attom_data jsonb DEFAULT '{}',
  regrid_data jsonb DEFAULT '{}',
  nearmap_data jsonb DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- PI2: Roof Measurements (from Google Solar API + AI)
CREATE TABLE roof_measurements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  -- Totals
  total_roof_area_sqft numeric(10,2) NOT NULL, -- sum of all facets, accounting for pitch
  total_ground_area_sqft numeric(10,2), -- flat/plan view footprint
  total_facets integer,
  predominant_pitch text, -- "6/12", "8/12", etc.
  predominant_pitch_degrees numeric(5,2),
  -- Linear measurements
  total_ridge_lf numeric(8,2),
  total_hip_lf numeric(8,2),
  total_valley_lf numeric(8,2),
  total_rake_lf numeric(8,2),
  total_eave_lf numeric(8,2),
  total_drip_edge_lf numeric(8,2),
  total_flashing_lf numeric(8,2),
  total_step_flashing_lf numeric(8,2),
  total_gutter_lf numeric(8,2), -- same as eave for gutter contractors
  -- Penetrations
  chimney_count integer DEFAULT 0,
  skylight_count integer DEFAULT 0,
  vent_count integer DEFAULT 0,
  satellite_dish_count integer DEFAULT 0,
  total_penetration_count integer DEFAULT 0,
  -- Waste factor (calculated from roof complexity)
  complexity_rating text, -- 'simple', 'moderate', 'complex', 'very_complex'
  recommended_waste_percent numeric(5,2), -- 10-25% based on complexity
  -- Material estimates
  total_squares numeric(8,2), -- total_roof_area / 100
  total_squares_with_waste numeric(8,2), -- squares * (1 + waste%)
  -- Data quality
  confidence_score numeric(5,2), -- 0-100, how confident we are in measurements
  tree_obstruction_percent numeric(5,2), -- % of roof obscured by trees
  measurement_source text, -- 'google_solar', 'ai_cv', 'drone', 'manual'
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- PI3: Roof Facets (individual roof planes)
CREATE TABLE roof_facets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  roof_measurement_id uuid NOT NULL REFERENCES roof_measurements(id) ON DELETE CASCADE,
  facet_number integer NOT NULL,
  -- Dimensions
  area_sqft numeric(8,2) NOT NULL,
  pitch text, -- "6/12"
  pitch_degrees numeric(5,2),
  azimuth_degrees numeric(5,2), -- compass direction the facet faces (0=N, 90=E, 180=S, 270=W)
  -- Solar data (from Google Solar API)
  annual_sun_hours numeric(8,1),
  shade_percent numeric(5,2), -- % shaded annually
  solar_potential_kwh numeric(10,2), -- annual kWh if fully paneled
  -- Edge types (what borders this facet)
  edge_types jsonb DEFAULT '[]', -- [{type: "ridge", length_ft: 12.5}, {type: "eave", length_ft: 20.0}]
  -- Penetrations on this facet
  penetrations jsonb DEFAULT '[]', -- [{type: "chimney", width_ft: 3, height_ft: 4}]
  created_at timestamptz NOT NULL DEFAULT now()
);

-- PI4: Wall Measurements (derived from footprint + stories + LIDAR)
CREATE TABLE wall_measurements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  -- Totals
  total_wall_area_sqft numeric(10,2),
  total_siding_area_sqft numeric(10,2), -- wall area minus openings
  total_window_count integer,
  total_door_count integer,
  total_window_area_sqft numeric(8,2),
  total_door_area_sqft numeric(8,2),
  -- Per-face measurements (JSONB for flexibility)
  wall_faces jsonb DEFAULT '[]',
  -- Each: {face: "north", area_sqft: 450, height_ft: 18, length_ft: 25, windows: 3, doors: 1, window_area_sqft: 36, door_area_sqft: 21}
  -- Trim/accessories
  total_soffit_lf numeric(8,2), -- perimeter of building at eave line
  total_fascia_lf numeric(8,2), -- same as soffit typically
  total_corner_posts integer, -- number of exterior corners
  total_trim_lf numeric(8,2), -- window + door trim
  -- Data quality
  confidence_score numeric(5,2),
  measurement_source text, -- 'derived', 'nearmap', 'ai_cv', 'manual'
  is_estimated boolean DEFAULT true, -- true = derived from footprint, false = measured from imagery
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- PI5: Property Exterior Features (from AI + APIs)
CREATE TABLE property_features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  -- Lot measurements
  lot_perimeter_lf numeric(10,2), -- fence contractors need this
  lot_frontage_lf numeric(8,2),
  lot_depth_lf numeric(8,2),
  -- Ground cover
  driveway_area_sqft numeric(10,2),
  walkway_area_sqft numeric(8,2),
  patio_area_sqft numeric(8,2),
  total_hardscape_sqft numeric(10,2),
  total_lawn_sqft numeric(10,2),
  total_landscape_bed_sqft numeric(10,2),
  -- Trees and vegetation
  tree_count integer,
  tree_canopy_sqft numeric(10,2),
  tree_canopy_percent numeric(5,2), -- % of lot covered by tree canopy
  -- Structures
  garage_sqft numeric(8,2),
  shed_count integer DEFAULT 0,
  deck_sqft numeric(8,2),
  fence_lf numeric(8,2),
  fence_type text, -- 'wood', 'chain_link', 'vinyl', 'wrought_iron', 'unknown'
  -- Access
  distance_to_road_ft numeric(8,2),
  driveway_access text, -- 'front', 'side', 'rear', 'alley'
  -- Elevation/grade
  elevation_ft numeric(8,2), -- from USGS
  avg_slope_percent numeric(5,2), -- lot slope
  -- Neighboring context
  neighboring_structures_within_10ft integer, -- for scaffolding/access assessment
  -- Data quality
  confidence_score numeric(5,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- PI6: Trade-Specific Bid Data (pre-calculated per trade)
CREATE TABLE trade_bid_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES companies(id),
  trade text NOT NULL,
  -- CHECK (trade IN ('roofing', 'siding', 'gutters', 'solar', 'painting', 'landscaping', 'fencing', 'concrete', 'hvac', 'electrical', 'plumbing', 'general'))
  -- Pre-calculated measurements for this trade
  measurements jsonb NOT NULL DEFAULT '{}',
  -- Roofing: {total_squares, waste_percent, squares_with_waste, ridge_cap_lf, starter_strip_lf, ice_water_shield_sqft, underlayment_sqft, drip_edge_lf, flashing_lf}
  -- Siding: {siding_area_sqft, soffit_lf, fascia_lf, corner_posts, j_channel_lf, trim_lf, window_trim_lf}
  -- Gutters: {gutter_lf, downspout_count, downspout_lf, end_caps, inside_corners, outside_corners, outlets}
  -- Solar: {usable_roof_sqft, annual_sun_hours, estimated_kwh, optimal_facets, panel_count_estimate, shade_percent}
  -- Painting: {wall_area_sqft, trim_lf, gallons_primer, gallons_paint, ladder_needed, scaffolding_needed}
  -- Landscaping: {lawn_sqft, bed_sqft, hardscape_sqft, tree_count, irrigation_zones_estimate}
  -- Fencing: {perimeter_lf, gate_count_estimate, corner_post_count, grade_changes}
  -- Concrete: {driveway_sqft, walkway_sqft, patio_sqft, total_concrete_sqft, estimated_yards}
  -- HVAC: {building_sqft, stories, window_count, orientation, existing_equipment_location}
  -- Material estimates
  material_list jsonb DEFAULT '[]',
  -- [{item: "Architectural Shingles", quantity: 35, unit: "SQ", waste_included: true}, ...]
  -- Cost reference (from Unwrangle/supply chain pricing, if available)
  estimated_material_cost numeric(12,2),
  material_cost_source text, -- 'unwrangle', 'abc_supply', 'manual', 'none'
  -- Waste factors applied
  waste_factors jsonb DEFAULT '{}',
  -- {material_waste: 15, cut_waste: 5, complexity_adder: 3}
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- PI7: Scan History (audit trail of all scans for a property)
CREATE TABLE scan_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id),
  company_id uuid NOT NULL REFERENCES companies(id),
  scanned_by uuid REFERENCES users(id),
  scan_trigger text NOT NULL, -- 'manual', 'job_creation', 'estimate_start', 'scheduled_refresh'
  apis_called text[] DEFAULT '{}',
  apis_succeeded text[] DEFAULT '{}',
  apis_failed text[] DEFAULT '{}',
  processing_time_ms integer,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- PI8: Parcel Boundaries (GeoJSON from Regrid)
CREATE TABLE parcel_boundaries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_scan_id uuid NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
  -- Parcel data
  parcel_id text, -- Regrid/county parcel ID
  apn text, -- Assessor's Parcel Number
  fips text, -- county FIPS code
  -- Boundary (GeoJSON polygon)
  boundary_geojson jsonb NOT NULL,
  -- Dimensions
  lot_area_sqft numeric(12,2),
  lot_perimeter_ft numeric(10,2),
  frontage_ft numeric(8,2),
  depth_ft numeric(8,2),
  -- Zoning
  zoning_code text,
  zoning_description text,
  land_use text,
  -- Owner (from public records)
  owner_name text,
  owner_mailing_address text,
  -- Source
  data_source text DEFAULT 'regrid',
  source_date date,
  created_at timestamptz NOT NULL DEFAULT now()
);
```

### Modifications to Existing Tables

```sql
-- Link jobs to property scans
ALTER TABLE jobs ADD COLUMN property_scan_id uuid REFERENCES property_scans(id);

-- Link estimates to property scans (measurements auto-populate line items)
ALTER TABLE estimates ADD COLUMN property_scan_id uuid REFERENCES property_scans(id);
```

---

## WASTE FACTOR ENGINE (Industry-Standard Calculations)

Waste factors are NOT random percentages. They're calculated from actual roof/surface complexity:

### Roofing Waste Factors
| Roof Type | Base Waste | Complexity Adder | Total Range |
|-----------|-----------|-----------------|-------------|
| Simple gable (2-4 facets) | 10% | 0% | 10% |
| Cross gable (5-8 facets) | 12% | 2% | 14% |
| Hip roof | 15% | 2% | 17% |
| Complex (10+ facets, dormers, valleys) | 15% | 5-10% | 20-25% |
| Metal roofing | 5% | 2-5% | 7-10% |
| Clay/concrete tile | 12% | 3% | 15% |

### Other Trade Waste Factors
| Trade | Material | Standard Waste |
|-------|---------|---------------|
| Siding (vinyl/hardie) | Per square | 10-12% |
| Drywall | Per sheet | 12-20% |
| Flooring (straight) | Per sqft | 5-7% |
| Flooring (diagonal) | Per sqft | 15% |
| Paint | Per gallon | 5-10% (coverage overage) |
| Concrete | Per yard | 5-10% |
| Fencing | Per section | 5% |

The system calculates waste from actual measured geometry (number of facets, angles, penetrations) — not guesses.

---

## TRADE-SPECIFIC MEASUREMENT PIPELINES

### Roofing Pipeline
**Input:** Address
**API calls:** Google Solar (roof segments) + ATTOM (roof type from tax) + Microsoft (footprint)
**Output:**
- Total roof area (squares)
- Pitch per facet
- Ridge, hip, valley, rake, eave linear feet
- Drip edge, flashing, step flashing linear feet
- Penetration count and dimensions (chimneys, skylights, vents)
- Starter strip linear feet (= eave + rake LF)
- Ice & water shield area (= eave line × 3ft + valleys × 3ft)
- Underlayment area (= total roof area)
- Calculated waste factor from complexity
- Recommended material quantities with waste
- **Material list ready for Unwrangle/ABC Supply ordering**

### Siding/Exterior Pipeline
**Input:** Address
**API calls:** Microsoft (footprint) + ATTOM (stories, sqft) + USGS (elevation for height) + Mapbox (satellite tile for wall analysis)
**Output:**
- Total wall area per face (N/S/E/W)
- Siding area (wall minus window/door deductions)
- Soffit/fascia linear feet
- Corner post count
- J-channel linear feet
- Trim linear feet (window + door surrounds)
- Window count and area estimate
- Door count and area estimate
- **Material list with squares, accessories, trim pieces**

### Gutter Pipeline
**Input:** Address (uses roof measurement data)
**Dependency:** Roof measurement must exist
**Output:**
- Gutter linear feet per section (from eave measurements)
- Downspout count (1 per 30-40 LF of gutter)
- Downspout linear feet (stories × 10ft per downspout)
- Inside/outside corners
- End caps
- Outlets
- **Complete gutter material order**

### Solar Pipeline
**Input:** Address
**API calls:** Google Solar (primary — designed exactly for this)
**Output:**
- Usable roof area by facet (south/southwest/west facing preferred)
- Annual sun hours per facet
- Shade percentage per facet
- Estimated annual kWh production
- Optimal panel count and layout
- Estimated system size (kW)
- Azimuth and pitch per viable facet
- **Pre-configured for IRA rebate documentation**

### Painting (Exterior) Pipeline
**Input:** Address
**API calls:** Microsoft (footprint) + ATTOM (stories) + USGS (height)
**Output:**
- Total wall area by face
- Trim linear feet
- Window/door count (for masking/prep calculation)
- Height assessment (ladder vs scaffolding determination)
  - 1 story: ladder
  - 2+ stories or >20ft eave height: scaffolding
- Gallons of primer (wall area ÷ 350 sqft/gallon)
- Gallons of paint (wall area ÷ 350 sqft/gallon × 2 coats)
- Trim gallons (trim LF × 0.5ft width ÷ 350)

### Landscaping Pipeline
**Input:** Address
**API calls:** Microsoft (footprint) + Regrid (lot boundary) + Mapbox (satellite for land cover) + USGS (slope)
**Output:**
- Total lawn area (lot - building - hardscape - beds)
- Landscape bed area
- Hardscape area (driveway, walkway, patio)
- Tree count and canopy coverage
- Estimated irrigation zones (1 zone per 1,500 sqft typical)
- Lot slope assessment
- **Yard area breakdown for maintenance pricing or install quotes**

### Fencing Pipeline
**Input:** Address
**API calls:** Regrid (parcel boundary — THE key data source)
**Output:**
- Total lot perimeter in linear feet
- Per-side measurements (front, back, left, right)
- Estimated gate count (1 per accessible side, typically 1-2)
- Corner post count (= number of lot corners)
- Grade change assessment (from USGS elevation)
- **Line post count (perimeter ÷ 8ft spacing)**
- **Total sections (perimeter ÷ section width)**

### Concrete/Paving Pipeline
**Input:** Address
**API calls:** Mapbox (satellite tile for surface detection) + USGS (slope)
**Output:**
- Driveway area (detected from satellite)
- Walkway area
- Patio area
- Total concrete area
- Estimated cubic yards (area × 4in depth ÷ 27)
- Grade/slope assessment for drainage planning

### HVAC Pipeline
**Input:** Address
**API calls:** ATTOM (sqft, stories, year built, heating/cooling type) + Google Solar (orientation)
**Output:**
- Building square footage
- Number of stories
- Year built (age of likely existing equipment)
- Current heating type and fuel
- Current cooling type
- Window orientation (from Google Solar facet azimuths — heat load factor)
- Estimated tonnage needed (sqft ÷ 500-600 = tons, adjusted for climate zone)
- **Existing system age estimate (year built + typical replacement cycles)**

### Electrical Pipeline
**Input:** Address
**API calls:** ATTOM (sqft, year built, stories)
**Output:**
- Building square footage (load calculation input)
- Year built (wiring age assessment — pre-1970 = likely needs upgrade)
- Stories (conduit run estimation)
- Existing panel age estimate
- **NEC code considerations based on building age**

---

## MATERIAL ORDER INTEGRATION

Recon measurements connect directly to ZAFTO's supply chain integrations (Phase F):

### Unwrangle Integration (F1 — already built)
- Measurements → material list → search HD/Lowe's/50+ retailers
- Real-time pricing comparison
- One-click order to nearest branch with job-site delivery

### ABC Supply Integration (Future — API available)
- ABC Supply has open API for real-time branch pricing and ordering
- Roofr, AccuLynx, JobNimbus, Leap, Contractor+ already integrated
- ZAFTO measurements → ABC Supply material order → delivery tracking
- **This is the #1 integration roofing contractors want**

### HD Pro Xtra / Lowe's Pro (F1 — via Unwrangle)
- Unwrangle normalizes ordering across both
- Pro pricing tiers applied automatically
- Job-site delivery scheduling

**The killer flow:** Contractor creates job → Recon runs → measurements populate estimate → estimate approved → material list auto-generated → one-click order to ABC Supply/HD/Lowe's → delivery scheduled to job site. **Zero manual measurement, zero manual material calculation, zero phone calls to suppliers.**

---

## INTEGRATION WITH EXISTING FEATURES

### Jobs (existing)
- "Scan Property" button on job creation and job detail
- If job has address, auto-trigger scan on creation (configurable)
- Property scan card on job detail showing key measurements
- Link to full property report

### Estimates (D8, existing)
- "Import from Recon" button auto-populates estimate line items from measurements
- Trade-specific: roofing estimate gets squares + linear feet, siding estimate gets wall areas, etc.
- Material quantities pre-calculated with waste factors
- Contractor reviews and adjusts before finalizing — Recon is the starting point, not the final word

### Sketch/Bid Tool (F4, existing)
- Property scan provides initial dimensions
- Contractor can overlay/adjust measurements on interactive map
- Parcel boundary displayed from Regrid data

### Bids/Proposals (existing)
- "Property Intelligence" section in bid PDF — shows satellite image + key measurements
- Professional presentation: "This bid is based on Recon property analysis — [measurements shown]"
- Builds customer confidence — contractor has data before arriving on site

### CRM (existing)
- Property intelligence card on customer detail (if customer has address)
- Pre-scan properties for leads before the first call
- "We already know your roof is 35 squares with a 6/12 pitch" — impressive on first contact

### Client Portal (existing)
- Customer can see property overview with satellite image
- Measurements shown on their project page
- Transparency builds trust

### Mobile App (existing)
- On-site verification: contractor sees Recon measurements and can confirm/adjust from the field
- "Confirm measurements" workflow: verify key dimensions, flag any discrepancies
- Photo capture overlaid on property map

---

## WORKFLOWS

### Workflow 1: New Job with Auto-Scan

**Step 1:** Contractor creates new job, enters customer address
**Step 2:** System auto-triggers Recon (if enabled in company settings)
**Step 3:** Parallel API calls fire:
  - Google Solar API → roof segments, pitch, area, sun hours
  - ATTOM Property API → year built, stories, sqft, roof type, heating
  - Regrid API → parcel boundary, lot dimensions, zoning
  - Microsoft Footprints → building outline polygon
  - USGS 3DEP → elevation, slope
**Step 4:** Edge Function processes responses:
  - Merge data from all sources into unified property_scan record
  - Calculate roof measurements (facets, edges, waste factor)
  - Derive wall measurements from footprint + stories
  - Compute trade-specific bid data
  - Generate material lists with waste factors
**Step 5:** Results appear on job detail within 5-15 seconds
**Step 6:** Contractor clicks "Create Estimate from Scan" → line items auto-populated

### Workflow 2: Pre-Bid Property Research

**Step 1:** Contractor gets a lead (phone call, website, Angi, etc.)
**Step 2:** Before calling back, enters address in Recon
**Step 3:** Within seconds: roof size, condition hints, property details, estimated material needs
**Step 4:** Contractor calls customer: "I see you have approximately a 35-square hip roof with a 7/12 pitch. Based on that, I'd estimate [range]."
**Step 5:** Customer impressed → books appointment
**Step 6:** If customer books: convert scan into job with one click

### Workflow 3: Estimate to Material Order

**Step 1:** Recon measurements on job
**Step 2:** Contractor creates estimate → "Import from Recon" → line items populated
**Step 3:** Contractor adjusts quantities, adds labor, sets pricing
**Step 4:** Customer approves estimate
**Step 5:** Contractor clicks "Order Materials" → material list from bid data auto-fills
**Step 6:** System queries Unwrangle for pricing across suppliers
**Step 7:** Contractor selects supplier → order placed → delivery scheduled
**Step 8:** Materials arrive at job site → work begins

### Workflow 4: Insurance Claim with Property Intelligence (TPA Integration)

**Step 1:** TPA assignment received → job created → Recon auto-runs
**Step 2:** Contractor has property measurements BEFORE arriving on site
**Step 3:** On-site inspection confirms/adjusts Recon measurements
**Step 4:** Estimate created with Recon baseline → Xactimate codes mapped
**Step 5:** Supplement uses Recon measurements as documentation backing

---

## EDGE FUNCTIONS (4 new)

### 1. recon-property-lookup
**Trigger:** New job creation or manual scan request
**Process:**
1. Geocode address → lat/long
2. Parallel API calls (Google Solar, ATTOM, Regrid, Microsoft Footprints)
3. Merge responses into normalized property_scan record
4. Calculate derived measurements (wall area, gutter LF, etc.)
5. Store all raw API responses in JSONB for future reprocessing
6. Return structured property report

**Rate limiting:** Queue-based processing, max 600 Google Solar requests/minute
**Error handling:** Partial results OK — if one API fails, others still populate
**Caching:** Same address within 30 days returns cached scan (unless force-refresh)

### 2. recon-roof-calculator
**Trigger:** Google Solar data received
**Process:**
1. Parse roof segments (pitch, azimuth, area per facet)
2. Calculate edge types (ridges, hips, valleys, rakes, eaves)
3. Estimate penetrations from satellite analysis
4. Compute waste factor from complexity metrics
5. Generate material quantities per trade
6. Return structured roof_measurements + roof_facets records

### 3. recon-trade-estimator
**Trigger:** Property scan complete
**Process:**
1. Read property_scan + roof_measurements + wall_measurements + property_features
2. For each active trade (company's trades), calculate trade-specific bid data
3. Generate material lists with waste factors
4. Optionally query supply pricing (Unwrangle) for cost estimates
5. Store in trade_bid_data

### 4. recon-material-order
**Trigger:** Contractor clicks "Order Materials" from estimate
**Process:**
1. Read trade_bid_data material list for job
2. Map ZAFTO material items to supplier SKUs (via Unwrangle)
3. Query real-time pricing from HD/Lowe's/ABC Supply
4. Present supplier comparison to contractor
5. On selection: place order via Unwrangle API
6. Track delivery status

---

## UI SPECS

### CRM: Property Intelligence Card (on Job Detail)
- Satellite image thumbnail
- Key stats: roof area (squares), pitch, stories, lot size, year built
- "Full Report" link → detailed property page
- "Create Estimate" button → auto-populate from scan
- "Re-scan" button (force refresh)
- Data source badges: "Google Solar ✓" "ATTOM ✓" "Regrid ✓"
- Confidence indicator: "High confidence" / "Moderate — tree obstruction" / "Low — verify on site"

### CRM: Full Property Report Page
- **Header:** Address, satellite image (large), property type, year built
- **Roof tab:** Interactive roof diagram with facets, pitch labels, area per facet, edge measurements, penetrations. Waste calculator with adjustable complexity.
- **Walls tab:** Per-face wall measurements, window/door counts, siding area, trim measurements
- **Lot tab:** Parcel boundary on map, lot dimensions, hardscape/softscape breakdown, tree coverage, fence line, grade
- **Solar tab:** Sun hours per facet, shade analysis, panel layout suggestion, estimated kWh
- **Trade Data tab:** Pre-calculated bid data per trade, material lists, waste factors
- **History tab:** Previous scans, changes over time
- **Export:** PDF property report (professional format for customer presentation)

### Mobile: Property Scan Screen
- Address search bar (or "Use current location")
- Scan button → loading animation → results
- Swipeable cards: Roof → Walls → Lot → Solar → Trade Data
- "Verify on site" mode: overlay measurements on live camera view (Phase E AR)
- Quick actions: "Create Job" / "Create Estimate" / "Share Report"

### Mobile: On-Site Verification
- Checklist of key measurements from Recon
- Contractor taps each to confirm or adjust
- "Roof area: 35.2 SQ" → [Confirm] [Adjust: ___]
- Adjusted measurements update the scan record
- Verification badge: "Measurements verified on site by [tech name] on [date]"

---

## LEGAL CONSIDERATIONS

### API Terms of Service
- **Google Solar API:** Commercial use permitted under Google Maps Platform ToS. Must show Google attribution.
- **ATTOM:** Standard commercial API license. No redistribution of raw data to third parties.
- **Regrid:** Commercial license required for API access. Attribution required.
- **Microsoft Building Footprints:** Open Data Commons Open Database License (ODbL). Free commercial use.
- **USGS 3DEP:** Public domain. No restrictions.
- **Nearmap:** Enterprise license. Strict terms on data storage and redistribution.

### Attribution Requirements
- Google Maps attribution on any map display
- Regrid attribution on parcel boundary displays
- Microsoft attribution on building footprint displays
- "Property data sourced from public records and satellite imagery. Measurements are estimates — verify on site before ordering materials."

### Liability Disclaimer
- **CRITICAL:** Recon measurements are ESTIMATES, not guarantees
- Contractor is responsible for verifying measurements before material ordering
- ZAFTO is not liable for measurement errors that lead to material over/under ordering
- Disclaimer on every report: "These measurements are derived from satellite imagery and public records. They are intended as starting points for estimating. Always verify critical measurements on site before placing material orders."

---

## LEAD SCORING & PRE-QUALIFICATION ENGINE

Contractors waste **40+ hours/month** chasing unqualified leads. Recon solves this by scoring every property before the first phone call.

### Lead Quality Score (Hot / Warm / Cold)

**Two-tier scoring: works at $0/month, improves with paid APIs.**

**Tier 1 — FREE Signals (Day 1, "Basic Score"):**

| Signal | Source | Weight | Logic |
|--------|--------|--------|-------|
| Roof area | Google Solar API (free) | High | Larger roof = larger job value |
| Roof complexity | Google Solar facet count (free) | Medium | More facets = higher complexity = higher price per square |
| Building footprint | Microsoft Footprints (free) | Medium | Larger building = more exterior work |
| Storm proximity | NOAA Storm Events (free) | High | Recent hail/wind event within 5mi = hot restoration lead |
| Elevation/slope | USGS 3DEP (free) | Low | Steep terrain = scaffolding/access complexity |
| Multi-structure | Microsoft Footprints (free) | Low | Multiple buildings = multiple jobs per property |

**Tier 2 — ATTOM-Enhanced Signals (post-revenue, "Full Score"):**

| Signal | Source | Weight | Logic |
|--------|--------|--------|-------|
| Roof age | ATTOM `year_built` + avg 20yr roof lifecycle | High | `currentYear - yearBuilt > 18` = likely needs roof |
| Property value | ATTOM `assessed_value` | Medium | Higher value = larger budget = larger job |
| Owner tenure | ATTOM `last_sale_date` | Medium | Longer tenure = more equity = more likely to invest |
| Permit history | Local permit API (where available) | Medium | No recent roof permit + old roof = hot lead |
| Construction type | ATTOM `construction_type` | Low | Wood frame = more siding/paint work |
| Stories | ATTOM `stories` | Low | Multi-story = larger exterior area = bigger job |

**REMOVED: Nearmap roof condition score** — enterprise-priced, not on roadmap. Re-evaluate post-$50K MRR.

### Output

```
Lead Score: HOT (87/100)
  Roof age: ~22 years (installed ~2004) — LIKELY NEEDS REPLACEMENT
  Property value: $385,000 — SUPPORTS $12-18K ROOF JOB
  Owner: John Smith, owned since 2003 (23 years) — LONG TENURE, HIGH EQUITY
  Last roof permit: NONE FOUND — NO RECENT REPLACEMENT
  Roof condition: 42/100 (Nearmap) — POOR CONDITION DETECTED
  Recommendation: HIGH PRIORITY — contact immediately
```

### Pre-Scan for Leads (CRM Integration)

- Scan a property WITHOUT creating a job first
- Contractor enters address in Leads section → Recon runs → lead score computed
- "This lead is HOT — roof is 22 years old, no recent permits, assessed at $385K"
- One-click: Convert to Job → schedule appointment → measurements already attached

---

## BATCH AREA SCANNING

Storm restoration contractors and canvassers need to assess **entire neighborhoods**, not one address at a time.

### Polygon Area Scan

1. Contractor draws polygon on map (Mapbox draw tools)
2. System identifies all parcels within polygon (Regrid parcel API)
3. Batch-scan all properties (queued, rate-limited, background processing)
4. Results: ranked list of properties by lead quality score
5. Export: CSV with address, lead score, roof age, property value, owner name

### Storm Assessment Mode

After a documented weather event (hail, wind, tornado):

1. Contractor selects area on map
2. System cross-references NOAA storm data (hail size, wind speed by location)
3. Properties ranked by damage probability: `roof_age × storm_severity × roof_type_vulnerability`
4. Heat map visualization: color-coded parcels (red = high damage probability, yellow = moderate, green = low)
5. Door-knock list generated with optimal driving route

### Database Additions

```sql
-- Area scan tracking
CREATE TABLE area_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    scan_type TEXT NOT NULL DEFAULT 'general' CHECK (scan_type IN ('general', 'storm', 'canvass')),
    polygon_geojson JSONB NOT NULL,
    storm_event_id TEXT,
    storm_date DATE,
    storm_type TEXT,
    total_parcels INTEGER,
    scanned_parcels INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scanning', 'complete', 'failed')),
    created_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Lead scoring per property
CREATE TABLE property_lead_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    area_scan_id UUID REFERENCES area_scans(id) ON DELETE SET NULL,
    overall_score INTEGER NOT NULL CHECK (overall_score BETWEEN 0 AND 100),
    grade TEXT NOT NULL CHECK (grade IN ('hot', 'warm', 'cold')),
    roof_age_years INTEGER,
    roof_age_score INTEGER,
    property_value_score INTEGER,
    owner_tenure_score INTEGER,
    condition_score INTEGER,
    permit_score INTEGER,
    storm_damage_probability NUMERIC(5,2),
    scoring_factors JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Edge Function: `recon-area-scan`

**Input:** `{ polygon_geojson, scan_type, storm_event_id? }`
**Process:**
1. Query Regrid for all parcels within polygon
2. Queue individual property scans (rate-limited: 10/second for Google Solar, 5/second for ATTOM)
3. As each scan completes, compute lead quality score
4. If storm mode: cross-reference NOAA storm data, compute damage probability
5. Update area_scan progress (scanned_parcels / total_parcels)
6. On complete: rank all properties, generate summary stats

**Output:** `{ area_scan_id, total_parcels, hot_leads, warm_leads, cold_leads }`

---

## CONFIDENCE SCORING & IMAGERY DATE TRANSPARENCY

Every measurement needs a trust signal. Contractors need to know how reliable the data is before ordering $15K in materials.

### Confidence Score Calculation

```
confidence_score = base_score
  - tree_obstruction_penalty
  - imagery_age_penalty
  - complexity_penalty
  + verification_bonus

Where:
  base_score = 95 (Google Solar available) or 70 (footprint-only)
  tree_obstruction_penalty = tree_overhang_percent × 0.5 (max -25)
  imagery_age_penalty = months_since_capture × 1.5 (max -20)
  complexity_penalty = (facet_count > 12 ? 5 : 0) + (stories > 2 ? 5 : 0)
  verification_bonus = +10 if on-site verified by contractor
```

### Imagery Date Display

Every property report prominently shows:
- **"Satellite imagery captured: March 2025"** — from Mapbox/Google metadata
- **"Property records updated: January 2026"** — from ATTOM last update date
- **Confidence badge:** "High Confidence (92/100)" / "Moderate — verify on site (68/100)" / "Low — significant tree coverage (45/100)"
- **Warning if imagery > 18 months old:** "Imagery may not reflect recent changes. Verify on site."

### Change Detection (Future — Phase E AI)

When a property is re-scanned and imagery date has changed:
- Compare building footprint area (current vs previous)
- Flag: "This property appears to have changed — footprint area increased by 12% since last scan"
- Possible causes: addition, new structure, demolished structure

---

## MULTI-STRUCTURE DETECTION

Microsoft Building Footprints returns **ALL** structures on a parcel, not just the primary residence. Critical for:
- Insurance adjusters assessing all structures (house + detached garage + shed)
- Roofers who need to bid ALL roofs on the property
- Fencing contractors who need to know about outbuildings inside the fence line

### How It Works

1. Regrid returns parcel boundary polygon
2. Microsoft Building Footprints returns all building polygons
3. Spatial intersection: identify all buildings within parcel
4. Classify: primary (largest footprint), secondary (garage/workshop), accessory (shed/gazebo)
5. Measure each structure independently
6. Report: total structures found, measurements per structure, aggregate totals

### Database: `property_structures` table

```sql
CREATE TABLE property_structures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_scan_id UUID NOT NULL REFERENCES property_scans(id) ON DELETE CASCADE,
    structure_type TEXT NOT NULL DEFAULT 'primary' CHECK (structure_type IN ('primary', 'secondary', 'accessory', 'other')),
    label TEXT, -- "Main House", "Detached Garage", "Shed", etc.
    footprint_sqft NUMERIC(10,2),
    footprint_geojson JSONB,
    estimated_stories NUMERIC(3,1) DEFAULT 1,
    estimated_roof_area_sqft NUMERIC(10,2),
    estimated_wall_area_sqft NUMERIC(10,2),
    has_roof_measurement BOOLEAN DEFAULT false,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### UI: Structure Selector

On the property report page, contractor sees:
- Map with all structures outlined and labeled
- Toggle per structure: include/exclude from measurements and estimates
- "Bid all structures" vs "Primary only" mode
- Material lists and estimates generated per-structure or combined

---

## INSURANCE SUPPLEMENT CHECKLIST

Insurance adjusters consistently miss the same items. Restoration contractors spend hours identifying what was left off. Recon auto-generates a supplement checklist based on measurements.

### Commonly Missed Items (Auto-Detected from Measurements)

| Item | Detection Logic | How Often Missed |
|------|----------------|-----------------|
| Starter shingles | `eave_lf + rake_lf > 0` → starter required | 60%+ |
| Ridge cap | `ridge_lf > 0` → ridge cap required | 40%+ |
| Gable returns | `facets with rake edges adjacent to wall` → gable returns | 50%+ |
| Wall flashing | `wall-adjacent roof edges` → step/wall flashing needed | 55%+ |
| Drip edge | `eave_lf + rake_lf` → drip edge required on all edges | 35%+ |
| Ice & water shield | `eave_lf × 3ft + valley_lf × 3ft` → I&W shield area | 45%+ |
| Pipe collar/boot | `vent_count > 0` → pipe boots needed | 30%+ |
| O&P (overhead & profit) | `total_cost > threshold` → O&P should be included | 70%+ |
| Satellite dish reset | `satellite_dish_count > 0` → R&R satellite dish | 50%+ |
| Step flashing | `chimney_count > 0 OR wall_adjacencies > 0` → step flashing | 55%+ |

### Output: Supplement Checklist

```
SUPPLEMENT REVIEW — 123 Main St
Based on Recon measurements, the following items may be missing from the adjuster's estimate:

✅ Starter shingles — 185 LF (eave + rake)
✅ Ridge cap — 42 LF
✅ Drip edge — 185 LF
✅ Ice & water shield — 210 SF (eaves 3' + valleys 3')
⚠️  Step flashing — 2 chimneys detected, verify step flashing included
⚠️  Pipe boots — 4 vents detected, verify pipe collar replacement
⚠️  Satellite dish R&R — 1 dish detected
⚠️  O&P — Total exceeds $10K threshold, verify O&P included

Estimated supplement value: $2,400 - $3,800
```

### Integration with Programs

When a TPA claim is created and Recon data exists:
- Auto-generate supplement checklist
- Compare Recon measurements vs adjuster's scope
- Flag discrepancies: "Adjuster: 32 squares. Recon: 35.2 squares (±3-5%)"
- Attach supplement checklist to claim documentation

---

## STORM INTELLIGENCE & AREA ASSESSMENT

### NOAA Weather Data Integration

| Data Source | What It Provides | Cost |
|------------|-----------------|------|
| NOAA Storm Events Database | Historical storm events by county, hail size, wind speed | FREE (public) |
| NOAA NEXRAD Radar | Real-time and historical radar data for hail detection | FREE (public) |
| SPC Storm Reports | Severe weather reports with GPS coordinates | FREE (public) |

### Storm Assessment Workflow

1. **Storm event detected** — contractor enters storm date + area, or system auto-detects from NOAA data
2. **Damage probability model:**
   - `P(damage) = f(hail_size, wind_speed, roof_age, roof_type, roof_condition)`
   - Hail ≥ 1" + roof age > 15 years + shingle roof = HIGH probability
   - Hail < 0.75" + roof age < 10 years + metal roof = LOW probability
3. **Area heat map** — parcels colored by damage probability
4. **Canvass optimization** — optimal driving route through high-probability properties
5. **Lead list export** — CSV/PDF with ranked properties, owner info, contact data

### Restoration Contractor Competitive Advantage

No tool currently offers:
- Draw polygon → get damage probability for every roof in the area
- Pre-qualified lead list with property intelligence BEFORE knocking doors
- Storm date + location → instant assessment of which properties to target
- Integration with TPA claim workflow (Recon scan → TPA claim → supplement)

---

## BUILD ORDER (within Phase P — Property Intelligence)

### Sprint P1: Foundation + Google Solar + Confidence Engine (~12 hours)
- [ ] Migration: property_scans, roof_measurements, roof_facets tables + RLS
- [ ] Edge Function: recon-property-lookup (Google Solar API integration)
- [ ] Edge Function: recon-roof-calculator (facet processing, edge calculation)
- [ ] Google Cloud: Enable Solar API, configure API key in Supabase secrets
- [ ] Confidence score calculation: `base_score - tree_penalty - imagery_age_penalty - complexity_penalty`
- [ ] Imagery date extraction: parse capture date from Google Solar response + Mapbox tile metadata
- [ ] Confidence badge rendering: High (80-100) / Moderate (50-79) / Low (0-49) with explanation
- [ ] Imagery age warning: flag if satellite imagery > 18 months old
- [ ] CRM: Property scan trigger on job creation (fire-and-forget, non-blocking)
- [ ] CRM: Property intelligence card on job detail — satellite thumbnail, roof area, pitch, confidence badge, imagery date

### Sprint P2: Property Data + Parcel + Multi-Structure (~10 hours)
- [ ] Migration: parcel_boundaries, property_features, property_structures tables + RLS
- [ ] ATTOM API integration in recon-property-lookup (year built, stories, sqft, roof type, assessed value, last sale, owner info)
- [ ] Regrid API integration (parcel boundary, lot dimensions, zoning, owner name/address)
- [ ] Microsoft Building Footprints integration — fetch ALL building polygons within parcel boundary
- [ ] Multi-structure detection: spatial intersection of building footprints vs parcel polygon → classify primary/secondary/accessory
- [ ] Per-structure measurements: roof area estimate per building footprint, wall area per structure
- [ ] USGS 3DEP elevation lookup (terrain slope, building height estimation)
- [ ] CRM: Full property report page (Roof tab, Lot tab) with structure selector (toggle per structure)

### Sprint P3: Wall Measurements + Trade Data (~10 hours)
- [ ] Migration: wall_measurements, trade_bid_data tables + RLS
- [ ] Wall derivation logic (footprint × stories × avg wall height - openings)
- [ ] Edge Function: recon-trade-estimator (all 10 trade pipelines)
- [ ] Waste factor engine (complexity-based calculation from actual geometry)
- [ ] CRM: Walls tab on property report
- [ ] CRM: Trade Data tab with material lists per trade
- [ ] CRM hook: use-property-scan.ts (CRUD + real-time subscription for scan status)

### Sprint P4: Estimate Integration + Supplement Checklist (~10 hours)
- [ ] "Import from Recon" button on estimate create/edit
- [ ] Auto-populate estimate line items from trade_bid_data
- [ ] Material list generation from measurements with waste factors
- [ ] CRM: Solar tab on property report (Google Solar data)
- [ ] CRM: "Create Estimate from Scan" workflow
- [ ] Link property_scan_id on jobs and estimates tables (migration: ALTER TABLE)
- [ ] Insurance supplement checklist: auto-detect commonly missed items from measurements (starter, ridge cap, drip edge, I&W shield, step flashing, pipe boots, satellite dish R&R, O&P)
- [ ] Supplement checklist UI: checklist view with detected items, quantities, estimated supplement value
- [ ] TPA integration: when claim has Recon data, auto-attach supplement checklist to claim documentation

### Sprint P5: Lead Scoring + Batch Area Scanning (~10 hours)
- [ ] Migration: property_lead_scores, area_scans tables + RLS
- [ ] Lead scoring engine: compute overall_score (0-100) and grade (hot/warm/cold) from ATTOM data — roof age, property value, owner tenure, permit history, condition indicators
- [ ] Edge Function: recon-lead-score — accepts property_scan_id → compute and store lead score
- [ ] CRM: Lead score badge on property intelligence card (Hot/Warm/Cold with score)
- [ ] CRM: Pre-scan for leads — scan address in Leads section without creating job → lead score displayed → one-click convert to Job
- [ ] Edge Function: recon-area-scan — accepts polygon GeoJSON → query Regrid for parcels → queue batch scans → compute lead scores → rank results
- [ ] CRM: Area scan page — Mapbox draw polygon tool → scan area → progress bar → ranked lead list
- [ ] Area scan results: sortable table (address, lead score, roof age, property value, owner name) + map view with color-coded markers
- [ ] Export: CSV download of area scan results with all property data

### Sprint P6: Material Ordering Pipeline (~8 hours)
- [ ] Edge Function: recon-material-order (Unwrangle integration)
- [ ] Material list → supplier SKU mapping
- [ ] Real-time pricing comparison UI (side-by-side supplier prices)
- [ ] "Order Materials" button on estimate
- [ ] Supplier selection + order placement via Unwrangle API
- [ ] Delivery tracking integration

### Sprint P7: Mobile + On-Site Verification (~10 hours)
- [ ] Mobile: Property scan screen (address search with Mapbox autocomplete + "Use Current Location" + "Scan")
- [ ] Mobile: Swipeable result cards (Roof/Walls/Lot/Solar/Trade/Lead Score)
- [ ] Mobile: On-site verification workflow (confirm/adjust key measurements → verification badge)
- [ ] Migration: scan_history table + RLS
- [ ] Scan audit trail logging (who scanned, when, which APIs succeeded/failed, processing time)
- [ ] Mobile: "Share Report" (PDF generation — professional format for customer presentation)
- [ ] Mobile Dart models: property_scan.dart, roof_measurement.dart, property_lead_score.dart
- [ ] Mobile repository: property_scan_repository.dart
- [ ] Mobile Riverpod providers: property_scan_provider (AsyncNotifier)

### Sprint P8: Portal Integration (~8 hours)
- [ ] Team Portal: Property scan view on assigned jobs (read-only measurements + lead score)
- [ ] Team Portal: On-site verification (same confirm/adjust workflow as mobile)
- [ ] Client Portal: Property overview on project page (satellite image + key measurements, no lead score)
- [ ] CRM: Property intelligence in bid/proposal PDF (satellite image + measurements section)
- [ ] CRM sidebar: "Recon" section under Operations (Property Scans list, Area Scans list)
- [ ] Ops Portal: Recon analytics (total scans, lead conversion rate, accuracy feedback)

### Sprint P9: Storm Assessment + Area Intelligence (~10 hours)
- [ ] NOAA Storm Events Database integration: fetch historical storm events by county/date (hail size, wind speed, GPS coordinates)
- [ ] Storm damage probability model: `P(damage) = f(hail_size, wind_speed, roof_age, roof_type, roof_condition)`
- [ ] Edge Function: recon-storm-assess — accepts area polygon + storm date → cross-reference NOAA data → compute per-parcel damage probability
- [ ] CRM: Storm assessment mode on area scan page — enter storm date + draw area → heat map with damage probability per parcel
- [ ] Heat map visualization: Mapbox fill-extrusion layer with red (high) / yellow (moderate) / green (low) damage probability
- [ ] Canvass optimization: door-knock list sorted by damage probability → optimal driving route (Mapbox Directions API)
- [ ] Storm history on property reports: "This property has been in the path of 3 documented hail events since 2020"
- [ ] Integration: storm assessment → area scan → lead scores → TPA claim creation pipeline

### Sprint P10: Polish + Build Verification + Accuracy Benchmarking (~8 hours)
- [ ] All portals build clean: `npm run build` passes for web-portal, team-portal, client-portal, ops-portal
- [ ] Mobile: `dart analyze` passes (0 errors)
- [ ] Google Solar API error handling (address not found, no coverage, rate limit)
- [ ] Partial scan handling (some APIs succeed, others fail — show partial results with warnings)
- [ ] Caching: 30-day cache per address per company (re-scan only on explicit request or cache expiry)
- [ ] Rate limiting: queue system for API calls (10/s Google Solar, 5/s ATTOM, 5/s Regrid)
- [ ] Attribution compliance on all displays (Google Maps, Regrid, Microsoft)
- [ ] Disclaimer text on all reports
- [ ] Accuracy benchmarking: scan 20+ properties with known measurements (from EagleView reports or manual measurement) → document accuracy per metric → publish accuracy guarantee target (95%+ roof area)
- [ ] Lead scoring validation: verify scoring correlates with actual close rates (backtest against existing job data if available)
- [ ] Commit: `[P1-P10] ZAFTO Recon — property intelligence engine, 10 trade pipelines, lead scoring, area scanning, storm assessment`

---

## ESTIMATED TOTALS

- **~11 new tables** (8 original + area_scans, property_lead_scores, property_structures)
- **6 Edge Functions** (recon-property-lookup, recon-roof-calculator, recon-trade-estimator, recon-material-order, recon-area-scan, recon-storm-assess + recon-lead-score as sub-function)
- **~8 CRM pages/routes** (property report, area scan, storm assessment, lead scan, plus tabs)
- **~5 mobile screens** (scan, results, verification, lead score, share)
- **~3 team portal pages** (scan view, verification, job attachment)
- **~2 client portal additions** (property overview, milestone)
- **~7 hooks** (use-property-scan, use-lead-scores, use-area-scan, use-storm-assess, use-recon-resources, use-supplement-checklist, use-property-structures)
- **~96 hours total** (10 sprints)
- **API costs at launch:** $0/month (free tier stack: Google Solar 10K/mo + Microsoft Footprints + USGS + NOAA + Mapbox). **Post-revenue with ATTOM+Regrid:** ~$500-800/month for enriched data at 10K-50K scans

---

## LEGAL DISCLAIMERS TO INCLUDE IN UI

1. **Every property report:**
   "Property measurements are derived from satellite imagery, public records, and AI analysis. They are estimates intended as starting points for bidding and estimating. Always verify critical measurements on site before placing material orders. ZAFTO is not responsible for measurement inaccuracies."

2. **Material ordering:**
   "Material quantities are calculated from estimated property measurements with industry-standard waste factors. Verify measurements on site before ordering. ZAFTO is not responsible for material over-orders or under-orders resulting from measurement estimates."

3. **Google attribution:**
   "Roof analysis powered by Google Solar API" + Google Maps attribution per ToS

4. **Property data:**
   "Property records sourced from public tax assessor data and parcel records. Data accuracy depends on local government record quality."

---

## COMPETITIVE POSITION

| Feature | EagleView | Roofr | HOVER | GAF QuickMeasure | ZAFTO Recon |
|---------|-----------|-------|-------|-------------------|-------------|
| Roof measurements | ✅ 98.77% accuracy | ✅ Instant | ❌ | ✅ Instant | ✅ Day 1 |
| Wall measurements | ✅ Premium | ❌ | ✅ 3D model | ❌ | ✅ Derived Day 1, AI Phase E |
| Window/door count | ✅ Premium | ❌ | ✅ | ❌ | ⚠️ Phase E AI |
| Per-report cost | $18-$91 | $13-$39 | Free (with sub) | Free (with GAF) | **$0 (included)** |
| Estimate integration | ❌ Separate PDF | ✅ In-app | ❌ | ❌ | ✅ Direct to D8 engine |
| Material ordering | ❌ | ✅ ABC Supply | ❌ | ❌ | ✅ Unwrangle + ABC |
| Multi-trade (10 pipelines) | Roof + walls only | Roof only | Exterior only | Roof only | **✅ ALL 10 trades** |
| Job management | ❌ | Basic CRM | ❌ | ❌ | ✅ Full ZAFTO platform |
| Solar analysis | ❌ | ❌ | ❌ | ❌ | ✅ Google Solar API |
| Lot/parcel data | ❌ | ❌ | ❌ | ❌ | ✅ Regrid |
| Insurance claim support | ✅ (Verisk owned) | ❌ | ❌ | ❌ | ✅ TPA module |
| **Lead scoring / pre-qual** | ❌ | ❌ | ❌ | ❌ | **✅ 0-100 score + Hot/Warm/Cold** |
| **Batch area scanning** | ❌ | ❌ | ❌ | ❌ | **✅ Draw polygon → scan all parcels** |
| **Confidence scoring** | ❌ | ❌ | ❌ | ❌ | **✅ Imagery date + trust signal** |
| **Multi-structure detection** | ✅ Premium | ❌ | ❌ | ❌ | **✅ All buildings on parcel** |
| **Supplement checklist** | ❌ | ❌ | ❌ | ❌ | **✅ Auto-detect missed items** |
| **Storm intelligence** | ❌ | ❌ | ❌ | ❌ | **✅ NOAA + damage probability** |
| API/data lock-in | ✅ Proprietary | ✅ Walled garden | ✅ Walled garden | ✅ GAF locked | ❌ Open export |

**ZAFTO's unfair advantage:** We're not a measurement company bolting on CRM. We're a full contractor platform bolting on measurements. The measurements feed into everything — estimates, material orders, job management, client presentations, insurance claims, lead scoring, storm canvassing, supplement documentation. No one else has this end-to-end pipeline. Six features that NO competitor offers: lead pre-qualification from property data, batch area scanning, confidence scoring with imagery transparency, auto-generated supplement checklists, storm intelligence with damage probability, and canvass optimization with ranked door-knock routes.
