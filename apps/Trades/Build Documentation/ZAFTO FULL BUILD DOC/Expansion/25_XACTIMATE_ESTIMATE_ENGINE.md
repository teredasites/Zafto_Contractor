# 25 — ZAFTO Xactimate Estimates

## Expansion Spec — Phase E5
### Created: Session 75 (Feb 7, 2026)
### Status: SPEC COMPLETE — Blocked on ESX decryption tool + legal review + Phase E readiness

---

## 1. PROBLEM STATEMENT

### The Xactimate Monopoly
Xactimate (owned by Verisk Analytics, NASDAQ: VRSK, ~$30B market cap) controls 75-80% of insurance property claims estimating. 22 of the top 25 P&C insurers use Xactware tools. For restoration and insurance contractors, Xactimate is a de facto requirement — carriers won't accept estimates in other formats.

### Why This Matters to Contractors

**Cost:** $250-315/month per seat. For a 5-person crew, that's $15,000-19,000/year just to write estimates that insurance companies will accept.

**Suppressed Pricing:** Xactimate pricing consistently runs 30-50% below actual construction costs. Verisk's own EULA admits prices are "historical, with no warranty for accuracy" and "already 30 days old when published." Contractors must fight line-by-line to get paid what the work actually costs.

**Conflict of Interest:** Verisk was literally founded by insurance companies. At their 2009 IPO, the primary sellers were P&C insurance companies (Liberty Mutual, Travelers, ACE Group). The entity providing "independent" pricing data has deep insurance industry ownership ties. The insurance industry owns the tool that determines how much contractors get paid.

**Lock-in:** The 27,000+ item code system, while industry-standard vocabulary, creates massive switching costs. Adjusters who don't know Xactimate are unemployable in property claims. Contractors who can't produce Xactimate-format estimates can't get paid.

**Technical Quality:** Frequent crashes, photo upload failures, LiDAR inconsistencies. "Crashes daily losing valuable work." The software quality doesn't match the price tag.

### The ZAFTO Opportunity
ZAFTO replaces the $300/mo Xactimate subscription with a built-in estimate engine that:
1. Uses **real pricing from real ZAFTO jobs** instead of Verisk's surveyed/suppressed data
2. Is **included in the ZAFTO subscription** (no additional cost)
3. Is **AI-powered** — Claude suggests line items, catches missed scope, generates estimates from photos
4. Has **no conflict of interest** — ZAFTO works for contractors, not insurance companies
5. Produces **professional output** that adjusters accept (PDF format matching Xactimate layout)

This is THE killer feature for the insurance restoration vertical. The feature that makes a contractor say "I'm switching to ZAFTO and never looking back."

---

## 2. PRODUCT ARCHITECTURE

### Four Engines

```
+-------------------------------------------------------------------+
|                    ZAFTO ESTIMATE ENGINE                           |
+-------------------------------------------------------------------+
|                                                                   |
|  +------------------+    +------------------+                     |
|  | 1. ESTIMATE      |    | 2. PRICING       |                     |
|  |    WRITER        |    |    DATABASE       |                     |
|  |                  |    |                  |                     |
|  | Line item editor |    | 27,000+ codes   |                     |
|  | Category browser |    | Regional prices  |                     |
|  | MAT/LAB/EQU      |    | Crowd-sourced    |                     |
|  | O&P markup       |    | Monthly updates  |                     |
|  | Coverage groups   |    | User overrides   |                     |
|  +--------+---------+    +--------+---------+                     |
|           |                       |                               |
|           +----------++-----------+                               |
|                      ||                                           |
|  +------------------+||+------------------+                       |
|  | 3. ESX           |||| 4. PDF           |                       |
|  |    IMPORT/EXPORT  |||| OUTPUT           |                       |
|  |                  ||||                  |                       |
|  | Parse .esx files ||||  Xactimate-style |                       |
|  | Extract line     |||| layout           |                       |
|  |   items + pricing|||| Cover sheet      |                       |
|  | Generate .esx    |||| Line items       |                       |
|  | (post-legal)     |||| Summary totals   |                       |
|  +------------------+||+------------------+                       |
|                      ||                                           |
|              +-------++-------+                                   |
|              | Z INTELLIGENCE |                                   |
|              | (Claude API)   |                                   |
|              |                |                                   |
|              | PDF parsing    |                                   |
|              | Photo analysis |                                   |
|              | Scope suggest  |                                   |
|              | Code lookup    |                                   |
|              +----------------+                                   |
+-------------------------------------------------------------------+
```

### Engine 1: Estimate Writer
The core UI for creating, editing, and managing insurance estimates. Available in:
- **Web CRM** (primary — full-featured editor)
- **Flutter mobile** (field entry — simplified, photo-driven)
- **Client Portal** (read-only — view estimate details)
- **Team Portal** (read-only — view assigned work scope)

### Engine 2: Pricing Database
Independent pricing data built from real ZAFTO contractor jobs, NOT from Verisk:
- Crowd-sourced from actual invoiced work across ZAFTO users
- Regional pricing (ZIP code level)
- Monthly aggregation and updates
- User can override any price with their actual cost
- Transparent methodology — no "black box" pricing

### Engine 3: ESX Import/Export
Parse and generate Xactimate's native .esx file format:
- **Import:** Contractor receives ESX from adjuster → ZAFTO parses it → populates estimate with line items
- **Export:** Contractor writes estimate in ZAFTO → exports as ESX for import into XactAnalysis/Xactimate
- **Blocked on:** Legal counsel review + ESX decryption tool for encrypted variants

### Engine 4: PDF Output
Generate professional estimate PDFs that mirror the Xactimate layout:
- Cover sheet with claim/contact/policy info
- Categorized line items with MAT/LAB/EQU breakdown
- Room-by-room or category grouping
- Summary totals (ACV, RCV, depreciation, O&P)
- Professional enough that adjusters accept without question

---

## 3. DATA ARCHITECTURE

### Existing Tables (Already Deployed — D2a migration)

**`insurance_claims`** — Full claim lifecycle (13 statuses)
- `xactimate_claim_id` — Reference to Xactimate/XactAnalysis claim number
- `xactimate_file_url` — URL to stored ESX/PDF file

**`xactimate_estimate_lines`** — Imported/created line items
```sql
CREATE TABLE xactimate_estimate_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID NOT NULL REFERENCES insurance_claims(id),
  category TEXT NOT NULL,        -- e.g., 'demolition', 'framing', 'drywall'
  item_code TEXT,                -- Xactimate price code (e.g., 'DRY HANG12')
  description TEXT NOT NULL,
  quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
  unit TEXT NOT NULL DEFAULT 'EA', -- EA, LF, SF, SY, HR, etc.
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_supplement BOOLEAN DEFAULT false,
  supplement_id UUID REFERENCES claim_supplements(id),
  depreciation_rate NUMERIC(5,2) DEFAULT 0,
  acv_amount NUMERIC(12,2),
  rcv_amount NUMERIC(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**`claim_supplements`** — Supplement requests with line_items JSONB + approval workflow

**Related tables:** `insurance_inspections`, `moisture_readings`, `drying_logs`, `drying_equipment_tracking`, `insurance_communications`, `tpi_inspections`

### New Tables (Phase E5 — Deploy when building)

**`xactimate_codes`** — Master code registry
```sql
CREATE TABLE xactimate_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_code TEXT NOT NULL,         -- 2-3 letter code (RFG, DRY, ELE, etc.)
  category_name TEXT NOT NULL,         -- Full name (Roofing, Drywall, Electrical)
  selector_code TEXT NOT NULL,         -- 3-4+ letter code (SHGL, HANG12, etc.)
  full_code TEXT NOT NULL,             -- Combined: 'RFG SHGL'
  description TEXT NOT NULL,           -- Human-readable description
  unit TEXT NOT NULL DEFAULT 'EA',     -- Measurement unit
  coverage_group TEXT NOT NULL DEFAULT 'structural'
    CHECK (coverage_group IN ('structural', 'contents', 'other')),
  has_material BOOLEAN DEFAULT true,
  has_labor BOOLEAN DEFAULT true,
  has_equipment BOOLEAN DEFAULT false,
  is_system BOOLEAN DEFAULT true,      -- ZAFTO-maintained vs user-added
  deprecated BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(full_code)
);
-- Seed with all 27,000+ codes (from published Xactimate documentation)
-- RLS: readable by all authenticated users (reference data)
```

**`pricing_entries`** — Regional pricing data
```sql
CREATE TABLE pricing_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES xactimate_codes(id),
  region_code TEXT NOT NULL,           -- ZIP code or region identifier
  material_cost NUMERIC(12,2) DEFAULT 0,
  labor_cost NUMERIC(12,2) DEFAULT 0,
  equipment_cost NUMERIC(12,2) DEFAULT 0,
  total_cost NUMERIC(12,2) GENERATED ALWAYS AS (material_cost + labor_cost + equipment_cost) STORED,
  source TEXT NOT NULL DEFAULT 'crowd'
    CHECK (source IN ('crowd', 'manual', 'import', 'ai_extracted')),
  source_count INTEGER DEFAULT 1,      -- How many data points this is based on
  confidence TEXT DEFAULT 'low'
    CHECK (confidence IN ('low', 'medium', 'high', 'verified')),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  expires_date DATE,                   -- NULL = no expiry
  company_id UUID REFERENCES companies(id), -- NULL = global, set = company override
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(code_id, region_code, company_id, effective_date)
);
-- RLS: global entries readable by all, company entries scoped
CREATE INDEX idx_pricing_code_region ON pricing_entries(code_id, region_code)
  WHERE expires_date IS NULL OR expires_date > CURRENT_DATE;
CREATE INDEX idx_pricing_company ON pricing_entries(company_id)
  WHERE company_id IS NOT NULL;
```

**`estimate_templates`** — Reusable estimate templates
```sql
CREATE TABLE estimate_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  description TEXT,
  trade_type TEXT,                     -- 'electrical', 'plumbing', 'hvac', 'roofing', etc.
  loss_type TEXT,                      -- 'water', 'fire', 'wind', 'mold', etc.
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Each item: { code, description, qty, unit, notes }
  is_system BOOLEAN DEFAULT false,     -- ZAFTO-provided vs user-created
  usage_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped (is_system readable by all)
```

**`pricing_contributions`** — Anonymized pricing data from user jobs
```sql
CREATE TABLE pricing_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code_id UUID NOT NULL REFERENCES xactimate_codes(id),
  region_code TEXT NOT NULL,           -- ZIP from job address
  material_cost NUMERIC(12,2),
  labor_cost NUMERIC(12,2),
  equipment_cost NUMERIC(12,2),
  source_type TEXT NOT NULL DEFAULT 'invoice'
    CHECK (source_type IN ('invoice', 'bid', 'manual', 'estimate')),
  -- Anonymized — NO company_id or job_id stored
  contributed_at TIMESTAMPTZ DEFAULT now()
);
-- No RLS needed — anonymized aggregate data
-- Trigger: aggregate into pricing_entries monthly
```

**`esx_imports`** — Track imported ESX files
```sql
CREATE TABLE esx_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  claim_id UUID REFERENCES insurance_claims(id),
  file_name TEXT NOT NULL,
  file_size INTEGER,
  storage_path TEXT,                   -- Supabase Storage path
  parse_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (parse_status IN ('pending', 'parsing', 'complete', 'failed')),
  parse_errors JSONB DEFAULT '[]'::jsonb,
  extracted_lines INTEGER DEFAULT 0,
  xactdoc_version TEXT,               -- Xactimate version detected
  metadata JSONB DEFAULT '{}'::jsonb,  -- Carrier, adjuster, dates, etc.
  created_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped
```

### Table Relationships

```
insurance_claims
  |-- xactimate_estimate_lines (1:many)
  |-- claim_supplements (1:many)
  |     |-- xactimate_estimate_lines (1:many, via supplement_id)
  |-- esx_imports (1:many)

xactimate_codes (reference table)
  |-- pricing_entries (1:many per region)
  |-- pricing_contributions (1:many, anonymized)
  |-- xactimate_estimate_lines (via item_code match)

estimate_templates (company-scoped)
  |-- line_items JSONB references xactimate_codes
```

### ALTER to Existing Table
```sql
-- Add code_id FK to xactimate_estimate_lines for validated code references
ALTER TABLE xactimate_estimate_lines
  ADD COLUMN code_id UUID REFERENCES xactimate_codes(id),
  ADD COLUMN material_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN labor_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN equipment_cost NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN room_name TEXT,           -- Room/area grouping
  ADD COLUMN line_number INTEGER,      -- Display order within estimate
  ADD COLUMN coverage_group TEXT DEFAULT 'structural'
    CHECK (coverage_group IN ('structural', 'contents', 'other'));
```

---

## 4. XACTIMATE CODE SYSTEM

### Code Structure
Every Xactimate line item uses a two-part code:
- **Category Code** (2-3 uppercase letters) — identifies the trade or discipline
- **Selector Code** (3-4+ characters) — identifies the specific item within that category
- **Combined:** `CATEGORY SELECTOR` (space-separated), e.g., `DRY HANG12` = Drywall > Hang 1/2" drywall

### Complete Category Codes (70+)

| Code | Category | Trade |
|------|----------|-------|
| ACC | Mobile Home Accessories | Specialty |
| ACT | Acoustical | Ceilings |
| APP | Appliances | General |
| AWN | Awnings | Exterior |
| CAB | Cabinetry | Finish |
| CLN | Cleaning | General |
| CNC | Concrete | Structural |
| CON | Content Manipulation | Contents |
| DMO | Demolition | General |
| DOR | Doors | Finish |
| DRY | Drywall | General |
| ELE | Electrical | Electrical |
| ELS | Electrical Special | Electrical |
| EQU | Heavy Equipment | Equipment |
| EXC | Excavation | Sitework |
| FCC | Floor — Carpet | Flooring |
| FCR | Floor — Resilient | Flooring |
| FCS | Floor — Stone | Flooring |
| FCT | Floor — Ceramic Tile | Flooring |
| FCV | Floor — Vinyl | Flooring |
| FCW | Floor — Wood | Flooring |
| FEE | Permits/Fees | Admin |
| FEN | Fencing | Exterior |
| FNC | Finish Carpentry | Finish |
| FNH | Finish Hardware | Finish |
| FPL | Fireplaces | Specialty |
| FPS | Fire Protection Systems | Fire/Safety |
| FRM | Framing | Structural |
| FRP | Fireproofing | Fire/Safety |
| GLS | Glass/Glazing | Specialty |
| HMR | Hazmat Remediation | Remediation |
| HVC | HVAC | Mechanical |
| INM | Insulation — Mechanical | Mechanical |
| INS | Insulation | General |
| LAB | Labor Only | General |
| LIT | Light Fixtures | Electrical |
| LND | Landscaping | Exterior |
| MAS | Masonry | Structural |
| MBL | Marble | Finish |
| MPR | Moisture Protection | Remediation |
| MSD | Mirrors/Shower Doors | Bath |
| MSK | Mobile Home Skirting | Specialty |
| MTL | Metal Structures | Structural |
| ORI | Ornamental Iron | Specialty |
| PLA | Interior Plaster | General |
| PLM | Plumbing | Plumbing |
| PNL | Paneling | Finish |
| PNT | Painting | General |
| POL | Pools/Spas | Exterior |
| PRM | Property Repair/Misc | General |
| PTG | Painting — Low VOC | General |
| RFG | Roofing | Roofing |
| SCF | Scaffolding | Equipment |
| SDG | Siding | Exterior |
| SFG | Soffit/Fascia/Gutter | Exterior |
| SPE | Specialty Items | Specialty |
| SPR | Sprinklers | Fire/Safety |
| STL | Steel | Structural |
| STR | Stairs | Structural |
| STU | Stucco | Exterior |
| TBA | Bath Accessories | Bath |
| TCR | Trauma/Crime Remediation | Remediation |
| TIL | Tile | Finish |
| TMB | Timber Framing | Structural |
| TMP | Temporary Repairs | Emergency |
| USR | User Defined | Custom |
| WDA | Windows — Aluminum | Windows |
| WDP | Windows — Patio Doors | Windows |
| WDR | Windows — Reglaze | Windows |
| WDS | Skylights | Windows |
| WDT | Window Treatments | Windows |
| WDV | Windows — Vinyl | Windows |
| WDW | Windows — Wood | Windows |
| WPR | Wallpaper | Finish |
| WTR | Water Extraction/Remediation | Remediation |
| XST | Exterior Structures | Exterior |

### Line Item Components (MAT/LAB/EQU)

Every line item breaks down into three cost components:

| Component | Abbreviation | Description |
|-----------|-------------|-------------|
| Materials | MAT | Raw materials, parts, supplies |
| Labor | LAB | Installation labor (per unit) |
| Equipment | EQU | Equipment rental/usage costs |

**Not all items have all three.** Examples:
- `DMO DRYWALL` (demo drywall) = LAB only (no materials, no equipment)
- `DRY HANG12` (hang 1/2" drywall) = MAT + LAB
- `EXC DIG` (excavation) = LAB + EQU
- `RFG SHGL` (install shingles) = MAT + LAB

### Coverage Groups

Each line item belongs to one of three coverage groups, which map to insurance policy sections:
- **Structural** — Building structure, systems, finishes (Dwelling / Coverage A)
- **Contents** — Personal property, appliances, furniture (Coverage C)
- **Other** — Temporary housing, debris removal, tree service

### Unit Types

| Unit | Description | Example |
|------|-------------|---------|
| EA | Each (single item) | Outlets, fixtures, appliances |
| LF | Linear Foot | Baseboard, crown molding, pipe |
| SF | Square Foot | Drywall, flooring, painting |
| SY | Square Yard | Carpet, excavation |
| HR | Hour | Labor-only items |
| DA | Day | Equipment rental, drying |
| LS | Lump Sum | Permits, mobilization |
| CF | Cubic Foot | Concrete, fill |
| CY | Cubic Yard | Excavation, hauling |

### O&P (Overhead & Profit) Markup

Standard industry markup applied on top of line item totals:
- **Overhead:** 10% (covers office, insurance, vehicles, admin)
- **Profit:** 10% (contractor margin)
- **Combined:** 20% O&P on net estimate total
- Applied per-trade or on total (varies by carrier)
- Some carriers dispute O&P on "non-complex" claims — a major negotiation point

---

## 5. ESX FILE FORMAT

### Overview
ESX is Xactimate's native project file format. It is the standard exchange format between adjusters, carriers, and contractors in the insurance restoration industry.

### Structure
- **ESX = ZIP-compressed archive** (rename .esx to .zip to inspect contents)
- Contains: JPG images + `XACTDOC.ZIPXML` file
- File sizes: avg 330KB, range 28KB-8MB
- 90% use ZIP compression; 2% use XML-only format
- **No encryption, no DRM** on the file format itself (though some carrier-specific variants may add encryption)

### Contents When Unzipped
```
estimate.esx (renamed to .zip)
  |-- XACTDOC.ZIPXML        -- Main estimate data (XML, possibly further zipped)
  |-- FIF/                   -- Floor plan / sketch data
  |     |-- sketch.xml       -- TruePlans/Sketch floor plan XML
  |-- Images/                -- Photo attachments
  |     |-- photo_001.jpg
  |     |-- photo_002.jpg
  |     |-- ...
```

### XACTDOC.ZIPXML
The core data file. Contains the full estimate in XML format.

**Root Element:** `<XACTDOC>`

### Key XML Elements

**XACTNET_INFO** — Carrier/assignment routing
```xml
<XACTNET_INFO>
  <carrierId>STATE_FARM</carrierId>         <!-- Required -->
  <recipientsXNAddress>adjuster@xn.com</recipientsXNAddress>
  <sendersXNAddress>contractor@xn.com</sendersXNAddress>
  <senderId>12345</senderId>
  <federalTIN>XX-XXXXXXX</federalTIN>
  <profileCode>US-FL-MIAMI</profileCode>    <!-- Regional pricing profile -->
  <rotation>true</rotation>                 <!-- Auto-assign by ZIP -->
</XACTNET_INFO>
```

**CONTACTS** — People involved in the claim
```xml
<CONTACTS>
  <CONTACT type="insured" name="John Smith">
    <ADDRESSES>
      <ADDRESS type="loss" country="US" city="Miami" street="123 Main St"
               state="FL" postal="33101" />
    </ADDRESSES>
    <CONTACTMETHODS>
      <PHONE type="home" number="305-555-1234" />
      <EMAIL address="john@example.com" />
    </CONTACTMETHODS>
    <MORTGAGES>
      <MORTGAGE mortgagee="Wells Fargo" loanNum="123456789" />
    </MORTGAGES>
  </CONTACT>
</CONTACTS>
```

**PROJECT_INFO** — Project/loss details
```xml
<PROJECT_INFO>
  <NOTES><![CDATA[Water damage from burst pipe in kitchen.
    Affected kitchen, dining room, and hallway.
    Category 2 water loss.]]></NOTES>
</PROJECT_INFO>
```

**ADM** — Administration / claim details
```xml
<ADM>
  <dateReceived>2026-01-15</dateReceived>
  <dateOfLoss>2026-01-10</dateOfLoss>
  <COVERAGE_LOSS>
    <policyNumber>HO-12345678</policyNumber>
    <claimNumber>CLM-2026-00042</claimNumber>
    <catastrophe>CAT-2026-001</catastrophe>
    <isCommercial>false</isCommercial>
    <COVERAGES>
      <COVERAGE id="1" covType="dwelling" covName="Coverage A"
                deductible="1000" policyLimit="350000" reserveAmt="25000" />
      <COVERAGE id="2" covType="contents" covName="Coverage C"
                deductible="500" policyLimit="175000" reserveAmt="5000" />
    </COVERAGES>
    <TOL>
      <COL causeOfLoss="water_damage" />
    </TOL>
    <FORMS>
      <FORM name="HO-3" editionDate="2020-01-01" />
    </FORMS>
  </COVERAGE_LOSS>
</ADM>
```

**ESTIMATE** — The actual line items (structure varies by version)
```xml
<ESTIMATE>
  <ROOM name="Kitchen" level="1st">
    <LINE category="DMO" selector="DRYWALL" description="Remove drywall"
          qty="120" unit="SF" unitPrice="1.25" total="150.00"
          material="0" labor="150.00" equipment="0"
          coverage="structural" depreciation="0" />
    <LINE category="DRY" selector="HANG12" description="Hang 1/2 in drywall"
          qty="120" unit="SF" unitPrice="2.85" total="342.00"
          material="180.00" labor="162.00" equipment="0"
          coverage="structural" depreciation="5.0" />
    <!-- ... more lines ... -->
  </ROOM>
  <ROOM name="Dining Room" level="1st">
    <!-- ... -->
  </ROOM>
</ESTIMATE>
```

### Version Compatibility

| Version | ESX Support | Status |
|---------|-------------|--------|
| Xactimate 25+ | XACTDOC XML introduced | Legacy |
| Xactimate 27 | Full ESX | Discontinued |
| Xactimate 28 | Full ESX | Discontinued |
| Xactimate X1 | Full ESX | Current desktop |
| Xactimate Online | Full ESX import/export | Current cloud |

### Related File Formats
- **ESX** — Full estimate (ZIP + XML + images)
- **SKX** — Sketch/floor plan files (TruePlans)
- **CHX** — Alternate project file format
- **XCX** — Older exchange format

### What We Know vs. What We Need

| Aspect | Status |
|--------|--------|
| ZIP structure | Known — documented, verified |
| XACTDOC XML schema | Partially known — import guide publicly available |
| Contact/claim elements | Known — standard XML elements |
| Line item format | Partially known — varies by Xactimate version |
| Sketch/FIF format | Unknown — need sample files |
| Image handling | Known — standard JPG attachments |
| Encrypted ESX variants | Unknown — need decryption tool |
| Version-specific differences | Partially known — need more samples |

---

## 6. PRICING STRATEGY

### Philosophy: Real Data > Surveyed Data

Verisk surveys contractors for pricing data, then publishes it as the "market rate." This data is:
- Already 30 days old when published
- Based on self-reported surveys (subject to selection bias)
- Updated monthly at best
- Widely believed to be systematically suppressed (30-50% below actual costs)
- Published by a company whose largest customers are insurance companies who benefit from lower prices

**ZAFTO's approach:** Aggregate pricing from real invoiced work.

### Crowd-Sourced Pricing Pipeline

```
Contractor completes a job
  |
  v
Invoice line items contain Xactimate codes + actual amounts
  |
  v
On invoice finalization, extract: code + MAT/LAB/EQU + ZIP code
  |
  v
Anonymize (strip company_id, job_id, customer info)
  |
  v
INSERT into pricing_contributions (code_id, region_code, costs)
  |
  v
Monthly aggregation job:
  - Group by (code_id, region_code)
  - Calculate median, mean, P25, P75
  - Require minimum 3 data points for "medium" confidence
  - Require minimum 10 data points for "high" confidence
  - UPSERT into pricing_entries
  |
  v
Pricing available to all ZAFTO users in that region
```

### Pricing Confidence Levels

| Level | Minimum Data Points | Display |
|-------|-------------------|---------|
| Low | 1-2 | Gray text, "Limited data" badge |
| Medium | 3-9 | Normal text, "Regional average" badge |
| High | 10-49 | Bold text, "Market rate" badge |
| Verified | 50+ | Green text, "Verified market rate" badge |

### User Override System
- Any contractor can set their own price for any code
- Company-specific overrides stored in `pricing_entries` with `company_id` set
- Override takes precedence over crowd-sourced data
- "Reset to market" button restores crowd-sourced price

### Regional Pricing
- Primary: 5-digit ZIP code
- Fallback: 3-digit ZIP prefix (broader region)
- Fallback: State-level average
- Fallback: National average
- Display which level is being used

### Privacy
- **Pricing contributions are fully anonymized** — no company_id, no job reference
- Contractors opt in to pricing sharing (default: on, can disable in settings)
- Only the aggregate (median) is published, never individual data points
- Minimum threshold prevents re-identification from small regions

---

## 7. AI INTEGRATION (Z Intelligence)

### Phase E5 AI Features

**7a. PDF Estimate Parsing**
When a contractor receives a Xactimate estimate as a PDF:
1. Upload PDF to ZAFTO
2. Claude Vision extracts:
   - Contact information (insured, adjuster, carrier)
   - Policy/claim numbers
   - All line items with codes, quantities, units, prices
   - Room/area groupings
   - Summary totals (ACV, RCV, depreciation, O&P)
3. Auto-populate `insurance_claims` + `xactimate_estimate_lines`
4. Flag discrepancies vs ZAFTO pricing database
5. Suggest missing line items based on loss type + scope

**7b. Photo-Based Estimate Generation**
1. Contractor uploads photos of damage
2. Claude Vision identifies:
   - Type of damage (water, fire, wind, impact, mold)
   - Affected materials (drywall, flooring, framing, etc.)
   - Approximate affected area
   - Severity assessment
3. Claude generates suggested line items:
   - Demo + replacement for each affected material
   - Equipment needs (dehumidifiers, air movers for water)
   - Ancillary items (containment, cleaning, disposal)
4. Contractor reviews, adjusts quantities, submits

**7c. Scope Gap Detection**
After an estimate is written (by contractor or parsed from PDF):
1. Claude analyzes the scope against the loss type
2. Flags commonly missed items:
   - "Water loss in kitchen but no base cabinet removal?"
   - "Fire damage but no smoke/odor treatment?"
   - "No temporary repairs or emergency service charges?"
   - "Demo includes drywall but no baseboard removal?"
3. Suggests line items to add with one-click insert

**7d. Supplement Generator**
When a contractor needs to request additional scope:
1. Contractor describes what was found vs. what's in the original estimate
2. Claude generates supplement document:
   - New line items not in original scope
   - Quantity adjustments for existing items
   - Photo evidence references
   - Justification narrative for each addition
3. Output as professional PDF or ESX supplement file

**7e. Pricing Dispute Support**
When Xactimate pricing is below actual cost:
1. Contractor flags a line item as underpaid
2. Claude generates a pricing justification:
   - ZAFTO crowd-sourced data for that code/region
   - Local supplier quotes (if available)
   - Industry standard references
   - Historical pricing trends
3. Output as professional letter to adjuster/carrier

---

## 8. BUILD PHASES

### Prerequisites (Must be done BEFORE Phase E5)

| Prerequisite | Status | Notes |
|-------------|--------|-------|
| Phase E1-E4 (AI infra) | NOT STARTED | Z Intelligence architecture must exist first |
| D5 (Property Mgmt) | IN PROGRESS | D5h remaining |
| Legal counsel review | NOT STARTED | Interoperability defense memo needed before ESX output |
| ESX sample files | PENDING | User to source from real jobs → `C:\Users\Developer LLC\Desktop\ESX\` |
| ESX decryption tool | NOT AVAILABLE | Needed only for encrypted ESX variants |

### Phase E5a: Pricing Database Foundation (~8 hrs)
- [ ] Deploy `xactimate_codes` table + seed with published codes
- [ ] Deploy `pricing_entries` table + seed with initial data (from public sources)
- [ ] Deploy `pricing_contributions` table
- [ ] Deploy `estimate_templates` table
- [ ] ALTER `xactimate_estimate_lines` (add code_id, MAT/LAB/EQU, room_name, etc.)
- [ ] Build pricing aggregation Edge Function (monthly cron)
- [ ] Build code search/browse API (full-text search on description)

### Phase E5b: Estimate Writer UI — Web CRM (~12 hrs)
- [ ] Estimate editor page: room-by-room line item entry
- [ ] Code browser sidebar: search/filter all 70+ categories
- [ ] Auto-price lookup: select code → populate MAT/LAB/EQU from pricing DB
- [ ] O&P calculator: configurable markup per trade or total
- [ ] Coverage group assignment: structural/contents/other
- [ ] Summary view: ACV, RCV, depreciation, O&P totals
- [ ] Estimate templates: save/load common scopes
- [ ] Hook: `use-estimate-engine.ts` with full CRUD + calculations

### Phase E5c: PDF Output (~6 hrs)
- [ ] PDF template matching Xactimate layout (React PDF or server-side)
- [ ] Cover sheet: company logo, claim info, contacts, policy
- [ ] Line items: categorized with MAT/LAB/EQU columns
- [ ] Summary: totals by coverage group, depreciation, O&P
- [ ] Download + email + attach to claim record
- [ ] Edge Function for server-side PDF generation

### Phase E5d: AI PDF Parsing (~8 hrs)
- [ ] Upload handler: accept Xactimate PDF exports
- [ ] Claude Vision extraction prompt (structured output)
- [ ] Mapping engine: extracted text → xactimate_codes lookup
- [ ] Auto-populate claim + estimate lines from parsed data
- [ ] Review UI: show parsed results for contractor confirmation
- [ ] Discrepancy highlighting: ZAFTO price vs parsed price

### Phase E5e: AI Scope Assistant (~6 hrs)
- [ ] Gap detection engine: loss type → expected scope → missing items
- [ ] Photo analysis: damage type → suggested line items
- [ ] Supplement generator: new scope + justification narrative
- [ ] Integration with Dashboard: "/estimate" slash command
- [ ] Pricing dispute letter generator

### Phase E5f: Flutter Estimate Entry (~8 hrs)
- [ ] Simplified estimate screen (mobile-optimized)
- [ ] Photo capture → AI scope suggestion
- [ ] Code search with autocomplete
- [ ] Quick-add from templates
- [ ] Sync with web CRM estimate (same DB tables)
- [ ] Model + repository + service layer

### Phase E5g: ESX Import (~6 hrs) — BLOCKED ON LEGAL
- [ ] Legal counsel review COMPLETE (prerequisite)
- [ ] ESX upload handler + ZIP extraction
- [ ] XACTDOC XML parser (contacts, claim, line items)
- [ ] Image extraction and storage
- [ ] Auto-populate claim + estimate from parsed ESX
- [ ] Error handling for unknown XML elements

### Phase E5h: ESX Export (~6 hrs) — BLOCKED ON LEGAL
- [ ] Legal counsel review COMPLETE (prerequisite)
- [ ] ESX file generator (XML + images → ZIP)
- [ ] XACTDOC XML writer (valid schema)
- [ ] Download as .esx for import into Xactimate/XactAnalysis
- [ ] Verification: round-trip test (export → import into Xactimate trial)

### Phase E5i: Crowd-Sourced Pricing Pipeline (~4 hrs)
- [ ] Invoice finalization hook: extract codes + pricing + ZIP
- [ ] Anonymization pipeline: strip PII before contribution
- [ ] Monthly aggregation Edge Function (cron)
- [ ] Pricing confidence calculation
- [ ] Admin dashboard: pricing data coverage by region/trade

### Phase E5j: Testing + Verification (~4 hrs)
- [ ] Unit tests: code search, price lookup, O&P calculation
- [ ] Integration tests: PDF parse → claim creation flow
- [ ] Template round-trip: create → save → load → verify
- [ ] All 5 apps build clean
- [ ] Commit: `[E5] Xactimate Estimates — full estimate writing platform`

**Total estimated: ~68 hours across 10 sub-steps**

---

## 9. COMPETITIVE ANALYSIS

### Xactimate (Verisk Analytics)
| Aspect | Rating | Details |
|--------|--------|---------|
| Market share | Dominant | 75-80% of property claims |
| Pricing accuracy | Poor | 30-50% below actual costs |
| Cost | Expensive | $250-315/month per seat |
| Learning curve | Steep | 27,000+ codes, 10+ hr training |
| UX | Dated | Frequent crashes, slow |
| Pricing source | Conflicted | Insurance-company-owned |
| ESX ecosystem | Strong | Industry standard format |
| AI features | Growing | XactAI (2025-2026) |

### Symbility (CoreLogic)
| Aspect | Rating | Details |
|--------|--------|---------|
| Market share | Minor | <20% |
| Pricing accuracy | Better | 15-20% higher than Xactimate |
| Cost | Similar | Enterprise pricing |
| Adoption | Stalled | Farmers tried 2010-2014, came back |
| ESX support | No | Different format |

### iScope (Independent)
| Aspect | Rating | Details |
|--------|--------|---------|
| Market share | Niche | Texas-based, growing |
| Pricing accuracy | Good | Independent data compilation |
| Cost | Cheap | Free app, $40 pricing DB license |
| Code coverage | Good | 11,000+ construction items |
| Proof of concept | YES | Proves independent pricing DB is legal and viable |

### ZAFTO Estimates (Planned)
| Aspect | Target | Details |
|--------|--------|---------|
| Market share | Growing | Start with ZAFTO user base |
| Pricing accuracy | Best | Real invoiced data from real jobs |
| Cost | Included | No additional charge |
| Learning curve | Easy | AI-assisted, photo-driven |
| UX | Modern | Built into existing workflow |
| Pricing source | Transparent | Crowd-sourced, no conflicts |
| ESX support | Phase E5g/h | Import first, export after legal |
| AI features | Native | Claude-powered from day one |
| Moat | Platform | Estimating is one feature of many |

### Key Competitive Advantages

1. **Pricing Truth:** ZAFTO pricing comes from actual invoiced work, not insurance-company-influenced surveys. Over time, this becomes the most accurate pricing database in the industry.

2. **Zero Marginal Cost:** Estimating is included in the ZAFTO subscription. No separate $300/mo Xactimate license needed.

3. **AI-Native:** Photo-to-estimate, scope gap detection, supplement generation. Xactimate is retrofitting AI (XactAI); ZAFTO is building with it from day one.

4. **Full Platform:** Estimating integrates with invoicing, scheduling, materials tracking, Ledger. One system, not 12 tools.

5. **Network Effects:** Every ZAFTO user's invoiced work makes the pricing database better for all users. More users = more accurate data = stronger product.

---

## 10. LEGAL FRAMEWORK

### DMCA Section 1201(f) — Interoperability Exception
The Digital Millennium Copyright Act explicitly allows reverse engineering for interoperability when:
1. The person lawfully obtained the program
2. The sole purpose is identifying elements needed for interoperability
3. Findings are disclosed in good faith without promoting infringement
4. The resulting program is non-infringing

### Key Precedent Cases

| Case | Holding | Relevance |
|------|---------|-----------|
| **Sega v. Accolade** (9th Cir. 1992) | RE for interop is **fair use as a matter of law** | THE foundation case for file format interop |
| **Sony v. Connectix** (9th Cir. 2000) | Intermediate copying during RE is fair use; final product had none of Sony's code | Validates clean-room implementation |
| **Google v. Oracle** (SCOTUS 2021) | 11,500 lines of API code = fair use; "reimplementation of user interface" | APIs and interfaces are fair game |
| **Lotus v. Borland** (1st Cir. 1995) | Menu hierarchy is uncopyrightable "method of operation" | File format structure is functional, not creative |

### Caution Case
| Case | Holding | Distinguishing Factors |
|------|---------|----------------------|
| **Blizzard v. BnetD** (8th Cir. 2004) | EULA prohibition enforced; DMCA exception didn't apply | BnetD worked *with* same software (not interop with different software). ZAFTO is a different product creating interoperable files — much stronger case. |

### ESX-Specific Legal Analysis

ESX files are **highly favorable** for interoperability defense:
1. **No encryption/DRM** — ESX is ZIP + XML + JPG. No technological protection measure to "circumvent."
2. **DMCA 1201 may not even apply** — No access control to bypass.
3. **Market precedent** — magicplan, HOVER, Encircle, DocuSketch all produce ESX files commercially.
4. **Discoverable without decompilation** — Rename .esx to .zip, inspect with any text editor.
5. **Strong case law** — Sega + Sony + Google all favor this exact scenario.
6. **EULA enforceability uncertain** — Courts split on whether EULA restrictions can override federal interop exceptions.

### Verisk's Litigation History on RE
**Zero documented cases** of Verisk suing anyone for reverse engineering ESX files. They have litigated patents (EagleView, $375M loss), antitrust (Vedder, dismissed), and acquisitions (FTC blocks), but never file format interoperability.

### Recommended Legal Protocol

**Before shipping ESX export (Phase E5h):**
1. Legal counsel drafts interoperability defense memo
2. Document clean-room implementation protocol
3. Verify no Xactimate code is copied (only format structure)
4. Review magicplan/HOVER/Encircle precedent (how they handle ESX legally)
5. Prepare response template for potential Verisk C&D letter

**Clean Room Protocol:**
- Team A documents ESX structure from examination of customer-provided ESX files (customers provide their own claim files — no EULA acceptance needed to receive a file someone sends you)
- Team B implements parser/generator purely from Team A's documentation
- No Xactimate source code, decompiled binaries, or proprietary tools used
- All development documented with timestamps for audit trail

### What We CAN Ship Without Legal Review
- **PDF parsing** (Claude reads publicly shared PDF documents — no format reverse engineering)
- **Code database** (Xactimate codes are published in training materials, textbooks, PDFs)
- **Pricing database** (independent data from ZAFTO user invoices)
- **Estimate writer** (our own UI, our own data model)
- **ESX import** (parsing files that customers voluntarily provide to us)

### What NEEDS Legal Review Before Shipping
- **ESX export** (generating files in Xactimate's format)
- Any claims about "Xactimate compatible" in marketing

---

## 11. RISK REGISTER

### R1: Verisk Sends C&D Letter
| Field | Value |
|-------|-------|
| Probability | Medium (30-40%) |
| Impact | Medium — delays ESX export feature, does NOT affect estimate writer or pricing DB |
| Mitigation | Legal defense memo prepared in advance. Strong precedent case law. Multiple companies already do this. |
| Response | Forward to counsel. Point to DMCA 1201(f), Sega, Sony, Google precedents. Note magicplan/HOVER/Encircle market precedent. |
| Fallback | Ship PDF output only (no ESX). Adjusters accept well-formatted PDFs. |

### R2: Verisk Changes ESX Format
| Field | Value |
|-------|-------|
| Probability | Low-Medium (20-30%) |
| Impact | Medium — ESX import/export breaks until updated |
| Mitigation | Version detection in parser. Modular XML schema handling. Automated tests against sample files. |
| Response | Update parser for new version. Monitor Xactimate release notes. |

### R3: Carrier Rejects Non-Xactimate Estimates
| Field | Value |
|-------|-------|
| Probability | Medium (40-50% for some carriers) |
| Impact | High for affected contractors |
| Mitigation | PDF output matches Xactimate layout exactly. ESX export enables direct import. Use same codes and format. |
| Response | Provide ESX export. Offer PDF that is visually identical. Gradually build carrier acceptance. |

### R4: Pricing Database Has Insufficient Data
| Field | Value |
|-------|-------|
| Probability | High initially (first 6-12 months) |
| Impact | Low — users can still enter manual prices |
| Mitigation | Seed with public data sources. Allow manual entry. Show confidence levels. Focus on high-volume codes first. |
| Response | Grow user base. More users = more data = more accuracy. Network effect solves this over time. |

### R5: AI Parsing Accuracy
| Field | Value |
|-------|-------|
| Probability | Medium (Claude Vision quality varies) |
| Impact | Low — always requires contractor review/confirmation |
| Mitigation | Never auto-submit parsed data. Always show review screen. Contractor confirms/edits before saving. |
| Response | Improve prompts. Add few-shot examples. Build validation rules for known code patterns. |

### R6: Antitrust Attention
| Field | Value |
|-------|-------|
| Probability | Very Low (for ZAFTO specifically) |
| Impact | Positive — ZAFTO increases competition in a market the FTC already scrutinizes |
| Mitigation | None needed. ZAFTO is pro-competitive. FTC has already blocked Verisk acquisitions. |
| Response | Welcome regulatory attention. ZAFTO's existence supports a competitive market. |

---

## 12. FUTURE CONSIDERATIONS (Post-Launch)

### Sketch/Floor Plan Integration
- Import FIF/SKX sketch files from ESX
- Integrate with AR scanning (phone camera → floor plan)
- Calculate square footage automatically from room dimensions

### Carrier Direct Integration
- XactAnalysis API (if Verisk partnership obtained)
- Direct assignment receipt from carriers
- Automated status updates back to carrier

### Multi-Language Support
- Spanish estimates (large market in Texas, Florida, California)
- Bilingual output (English estimate + Spanish explanation for homeowner)

### Historical Pricing Analytics
- Track pricing trends over time by code/region
- Predict seasonal price fluctuations
- Alert contractors to pricing increases in their market

### Contractor Training
- In-app Xactimate code training (learn the system within ZAFTO)
- AI-guided estimate review ("did you miss anything?")
- Certification prep for IICRC, RIA, etc.

---

## APPENDIX A: Existing Infrastructure Inventory

### Flutter (Mobile App)
| Component | Path | Purpose |
|-----------|------|---------|
| InsuranceClaim model | `lib/models/insurance/` | Full claim model with hasXactimate getter |
| InsuranceClaimRepository | `lib/repositories/insurance/` | CRUD for claims |
| InsuranceClaimService | `lib/services/insurance/` | Auth-enriched claim operations |
| ClaimHubScreen | `lib/screens/insurance/` | Main claim management UI |
| ClaimDetailScreen | `lib/screens/insurance/` | Single claim with tabs |
| XactimateLinesScreen | `lib/screens/insurance/` | View/edit estimate lines |

### Web CRM
| Component | Path | Purpose |
|-----------|------|---------|
| use-insurance.ts | `web-portal/src/lib/hooks/` | 309 lines, full insurance CRUD |
| Insurance pages | `web-portal/src/app/dashboard/insurance/` | Claims management |
| mappers.ts | `web-portal/src/lib/hooks/` | InsuranceClaim mapper |

### Client Portal
| Component | Path | Purpose |
|-----------|------|---------|
| use-insurance.ts | `client-portal/src/lib/hooks/` | 130 lines, client-facing claim view |
| Insurance pages | `client-portal/src/app/dashboard/insurance/` | Read-only claim tracking |

### Database (Deployed)
| Table | Migration | Purpose |
|-------|-----------|---------|
| insurance_claims | D2a | Full claim lifecycle |
| xactimate_estimate_lines | D2a | Line items (existing, will be ALTERed) |
| claim_supplements | D2a | Supplement requests |
| insurance_inspections | D2a | Inspection scheduling |
| moisture_readings | D2a | Daily moisture tracking |
| drying_logs | D2a | Drying progress |
| drying_equipment_tracking | D2a | Equipment deployment |
| insurance_communications | D2a | Carrier/adjuster comms |
| tpi_inspections | D2a | Third-party inspections |

---

## APPENDIX B: ESX Sample File Sources

| Source | Method | Cost | Notes |
|--------|--------|------|-------|
| Xactimate 30-day trial | Create + export your own | Free | Best for controlled testing |
| magicplan PRO | Generate from 360 photos | Subscription | ESX export feature |
| DocuSketch | Submit scan, receive ESX | Per-project | 2 business day turnaround |
| Encircle | Field documentation app | Subscription | ESX/FML output |
| iGUIDE | Property scanning service | Per-scan | ESX within 24 hours |
| Customer-provided | Contractors receive from adjusters | Free | Most realistic test data |

**Sample file location:** `C:\Users\Developer LLC\Desktop\ESX\` (NOT in source code)

---

## APPENDIX C: Third-Party ESX Producers (Market Precedent)

These companies already commercially produce ESX files, establishing market precedent:

| Company | Method | Partnership? |
|---------|--------|-------------|
| magicplan | ESX file export | Verisk partner |
| HOVER | ESX + Direct API | Verisk partner |
| Encircle | ESX + Direct | Verisk partner |
| Matterport | Direct integration | Verisk partner |
| DocuSketch | Integration | Verisk partner |
| Polycam | Floor plan export | Independent |

Note: Most operate through Verisk partnership agreements. ZAFTO's approach (clean-room interoperability without partnership) is legally supported but unprecedented among major players. iScope is the closest precedent for independent operation.

---

**END OF SPEC**

**Next action:** Return to D5h (Team Portal — Property Maintenance View) in build sequence.
**ESX work begins:** Phase E5, after E1-E4 AI infrastructure is built.
**Legal review required before:** E5g (ESX import), E5h (ESX export).
