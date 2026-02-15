# 51 — Trade-Specific Workflows & Compliance Tools

> **Created**: Session 102 (2026-02-13)
> **Status**: SPEC'D — Not yet scheduled
> **Total New Tables**: ~10
> **Total Estimated Hours**: ~120
> **API Cost at Launch**: $0/month
> **Phase Assignment**: Phase U (Unification) — trade depth layer

---

## Overview

These are NOT calculators — Zafto already has 1,194 calculator files across 16+ trades. These are **compliance logs, document generators, and structured workflows** specific to each trade. Things contractors currently do on paper, in Excel, or don't do at all (and get fined for it).

### Design Principle
Each tool is a **screen + structured form** that generates a **document** (PDF) and stores data in a **trade-specific JSONB column** on the job or equipment record. This avoids creating dozens of narrow tables — instead, we use a `trade_tool_records` table with type discrimination.

### Xactimate Warning
**NEVER generate .ESX files.** Verisk owns the format. See Spec 50 legal notes.
Safe approach: Generate PDF/CSV scope reports with Xactimate-compatible line item codes (already stored in `xactimate_estimate_lines` table). CoreLogic/Symbility API integration being researched separately.

---

## Shared Infrastructure

### Universal Table: Trade Tool Records
```sql
-- Single table for all trade-specific tool data (JSONB discrimination)
CREATE TABLE trade_tool_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  property_id UUID REFERENCES properties(id),
  customer_id UUID REFERENCES customers(id),
  tool_type TEXT NOT NULL, -- discriminator (see tool list below)
  trade_type TEXT NOT NULL, -- 'electrical', 'plumbing', 'hvac', 'roofing', etc.
  record_data JSONB NOT NULL, -- tool-specific structured data
  document_path TEXT, -- generated PDF path in documents bucket
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'signed', 'submitted')),
  signed_by UUID REFERENCES users(id),
  signature_path TEXT,
  signed_at TIMESTAMPTZ,
  submitted_to TEXT, -- 'inspector', 'customer', 'insurance', 'utility'
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company_id = auth.company_id()
-- INDEX: company_id, tool_type, trade_type, job_id, created_at

-- Tool type values (discriminator):
-- HVAC: 'refrigerant_log', 'equipment_match', 'manual_j_worksheet'
-- Plumbing: 'backflow_test', 'water_heater_sizing', 'gas_pressure_test'
-- Electrical: 'panel_schedule', 'arc_flash_label', 'service_upgrade_worksheet'
-- Roofing: 'ventilation_calc', 'waste_factor_calc'
-- GC: 'aia_billing', 'rfi_log', 'punch_list', 'bid_leveling', 'schedule_of_values'
-- Restoration: 'air_mover_placement', 'category_class_doc', 'scope_report'
-- Painting: 'surface_area_calc', 'voc_compliance'
-- Landscaping: 'irrigation_zone_design', 'grade_drainage_calc'
```

### PDF Generation
All tools generate professional PDFs using `pdf-lib` (MIT, $0):
- Company logo + branding from company settings
- Job/property info auto-populated
- Digital signature field
- Professional formatting matching trade industry standards
- Stored in `documents` bucket: `{company_id}/trade-tools/{tool_type}/{record_id}.pdf`

---

## HVAC TOOLS

### Tool 1: Refrigerant Tracking Log
**Why**: EPA Section 608 REQUIRES tracking of all refrigerant charges and recoveries. Fine: up to $44,539 PER VIOLATION PER DAY. Most HVAC contractors track this on paper (or don't track it at all).

```jsonc
// record_data schema for tool_type = 'refrigerant_log'
{
  "equipment_id": "uuid", // links to home_equipment if exists
  "equipment_type": "split_system", // split_system, package_unit, chiller, etc.
  "equipment_make": "Carrier",
  "equipment_model": "24ACC636A003",
  "equipment_serial": "xxx",
  "refrigerant_type": "R-410A", // R-22, R-410A, R-32, R-454B
  "action": "charge", // charge, recover, leak_check, reclaim
  "amount_lbs": 3.5,
  "amount_oz": 0,
  "reason": "low_charge", // low_charge, new_install, repair, annual_service
  "leak_detected": false,
  "leak_location": null,
  "leak_rate_lbs_per_year": null,
  "cylinder_serial": "CYL-12345", // recovery cylinder ID for recoveries
  "epa_608_cert_number": "12345678", // tech's EPA certification
  "tech_name": "Mike Johnson",
  "service_date": "2026-02-13",
  "notes": ""
}
```

**Flutter screen**: Form with equipment selector (or manual entry), refrigerant type dropdown, action type, amount, leak detection fields. Auto-fills tech EPA cert from their certification record.

**PDF output**: EPA-compliant refrigerant log entry. Matches standard format inspectors expect.

**Estimate**: 6 hours (screen + form + PDF template)

---

### Tool 2: Equipment Matching Tool
**Why**: Wrong equipment matching voids manufacturer warranties. Techs frequently pair incompatible condensers with air handlers. This tool validates compatibility.

```jsonc
// record_data schema for tool_type = 'equipment_match'
{
  "condenser_make": "Carrier",
  "condenser_model": "24ACC636A003",
  "condenser_tonnage": 3.0,
  "condenser_seer": 16,
  "air_handler_make": "Carrier",
  "air_handler_model": "FE4ANF003L00",
  "air_handler_cfm": 1200,
  "thermostat_make": "Ecobee",
  "thermostat_model": "SmartThermostat Premium",
  "thermostat_compatible": true,
  "matched": true, // validated by AHRI lookup
  "ahri_reference_number": "12345678",
  "efficiency_rating": { "seer2": 15.2, "eer2": 12.0, "hspf2": 8.5 },
  "notes": ""
}
```

**Note**: AHRI (Air-Conditioning, Heating, and Refrigeration Institute) has a FREE public directory at ahridirectory.org. No API needed — can be linked as reference. Future: scrape AHRI data for local matching.

**Estimate**: 6 hours

---

### Tool 3: Manual J Worksheet
**Why**: Required for permit in most jurisdictions. Room-by-room heat gain/loss calculation with structured results. Currently done in expensive separate software (Cool Calc $200+/yr, Wrightsoft $1,500+).

```jsonc
// record_data schema for tool_type = 'manual_j_worksheet'
{
  "project_type": "new_construction", // new_construction, replacement, addition
  "design_conditions": {
    "outdoor_summer_db": 95, // from ACCA Manual J Table 1
    "outdoor_winter_db": 15,
    "indoor_summer": 75,
    "indoor_winter": 70,
    "latitude": 42.36
  },
  "rooms": [
    {
      "name": "Living Room",
      "floor_area_sqft": 320,
      "ceiling_height_ft": 9,
      "windows": [{ "orientation": "south", "sqft": 24, "type": "double_low_e" }],
      "exterior_walls": [{ "orientation": "south", "sqft": 120, "insulation": "R-13" }],
      "cooling_btuh": 4800,
      "heating_btuh": 6200
    }
  ],
  "total_cooling_btuh": 36000,
  "total_heating_btuh": 42000,
  "recommended_tonnage": 3.0,
  "duct_loss_factor": 1.15, // 15% duct loss
  "adjusted_cooling_btuh": 41400,
  "adjusted_heating_btuh": 48300
}
```

**Note**: This is a SIMPLIFIED Manual J for permit compliance (residential). Full ACCA-certified calculations require paid software. Zafto's version covers 80%+ of residential permits. Add disclaimer: "For reference — verify with ACCA-approved software for complex designs."

**Estimate**: 10 hours (complex calculation engine)

---

## PLUMBING TOOLS

### Tool 4: Backflow Prevention Test Tracker
**Why**: Annual testing REQUIRED by water authority for all backflow devices. Miss a test = water shutoff notice. Currently tracked on paper or not at all.

```jsonc
// record_data schema for tool_type = 'backflow_test'
{
  "device_location": "123 Main St - mechanical room",
  "device_type": "RPZ", // RPZ, DCVA, PVB, RPDA, DCDA
  "device_make": "Watts",
  "device_model": "909",
  "device_serial": "xxx",
  "device_size_inches": 1.0,
  "installation_date": "2020-05-15",
  "test_date": "2026-02-13",
  "next_test_due": "2027-02-13", // auto-calculated +12 months
  "tester_name": "John Smith",
  "tester_cert_number": "BF-12345",
  "tester_cert_expiry": "2027-06-30",
  "test_results": {
    "check_valve_1": { "closed_tight": true, "psi_reading": 5.2 },
    "check_valve_2": { "closed_tight": true, "psi_reading": 3.8 },
    "relief_valve": { "opened_at_psi": 2.0, "did_not_open": false },
    "differential_pressure": 1.4
  },
  "overall_result": "pass", // pass, fail, repair_and_retest
  "repair_notes": null,
  "submitted_to_water_authority": false,
  "water_authority_name": "Boston Water and Sewer Commission"
}
```

**Auto-schedule**: Creates recurring annual reminder per device per property.

**Estimate**: 6 hours

---

### Tool 5: Gas Pressure Test Log
**Why**: Required for inspection on any gas line work. Inspector wants to see documented pressure test with initial/final PSI, duration, and tech signature.

```jsonc
// record_data schema for tool_type = 'gas_pressure_test'
{
  "test_type": "new_install", // new_install, repair, remodel
  "pipe_material": "black_iron", // black_iron, csst, copper
  "test_medium": "air", // air, nitrogen, gas (final)
  "test_pressure_psi": 30,
  "initial_reading_psi": 30.0,
  "final_reading_psi": 30.0,
  "test_duration_minutes": 15, // min 10 min per code
  "pressure_drop_psi": 0,
  "result": "pass", // pass, fail
  "failure_notes": null,
  "gauge_calibration_date": "2025-12-01",
  "ambient_temp_f": 68,
  "notes": "All joints soap-tested, no leaks detected"
}
```

**Estimate**: 4 hours

---

### Tool 6: Water Heater Sizing Worksheet
**Why**: #1 callback reason is wrong-sized water heater. This standardizes the sizing calculation and documents it for the customer.

```jsonc
// record_data schema for tool_type = 'water_heater_sizing'
{
  "household_size": 4,
  "bathrooms": 2.5,
  "fixtures": {
    "shower_heads": 2,
    "bathtubs": 1,
    "dishwashers": 1,
    "clothes_washers": 1,
    "kitchen_sinks": 1,
    "bathroom_sinks": 3
  },
  "peak_demand_gallons": 68, // calculated
  "first_hour_rating_needed": 68,
  "fuel_type": "gas", // gas, electric, heat_pump, tankless_gas, tankless_electric
  "incoming_water_temp_f": 50,
  "desired_temp_f": 120,
  "temperature_rise_f": 70,
  "recommended_capacity_gallons": 50,
  "recommended_btu": 40000,
  "recommendation": "50-gallon gas water heater, 40,000 BTU, FHR >= 68 GPH"
}
```

**Estimate**: 4 hours

---

## ELECTRICAL TOOLS

### Tool 7: Panel Schedule Generator
**Why**: Required for every panel install/upgrade. Currently done by hand or in Excel. This auto-generates a professional panel schedule document.

```jsonc
// record_data schema for tool_type = 'panel_schedule'
{
  "panel_location": "Garage - east wall",
  "panel_make": "Square D",
  "panel_model": "QO130L200PG",
  "main_breaker_amps": 200,
  "bus_rating_amps": 200,
  "voltage": "120/240V",
  "phase": "1-phase",
  "total_spaces": 30,
  "circuits": [
    { "position": 1, "breaker_amps": 20, "poles": 1, "description": "Kitchen countertop receps (GFCI)", "wire_size": "12 AWG", "wire_type": "NM-B" },
    { "position": 2, "breaker_amps": 20, "poles": 1, "description": "Dishwasher", "wire_size": "12 AWG", "wire_type": "NM-B" },
    { "position": 3, "breaker_amps": 40, "poles": 2, "description": "Range/Oven", "wire_size": "8 AWG", "wire_type": "NM-B" },
    { "position": 5, "breaker_amps": 30, "poles": 2, "description": "Dryer", "wire_size": "10 AWG", "wire_type": "NM-B" },
    { "position": 7, "breaker_amps": 20, "poles": 2, "description": "HVAC Condenser", "wire_size": "12 AWG", "wire_type": "THWN" }
  ],
  "total_load_amps": 142,
  "load_percentage": 71, // % of bus rating
  "spare_spaces": 8,
  "notes": "AFCI required on all bedroom circuits per NEC 210.12"
}
```

**PDF output**: Standard panel schedule format that inspectors and other electricians expect. Two-column layout (odd positions left, even positions right), matching physical panel layout.

**Estimate**: 8 hours (complex PDF layout)

---

### Tool 8: Service Upgrade Worksheet
**Why**: 100A→200A service upgrade is the most common residential electrical job. This standardizes the process: load calculation, utility requirements, permit checklist.

```jsonc
// record_data schema for tool_type = 'service_upgrade_worksheet'
{
  "existing_service": { "amps": 100, "phase": "1-phase", "voltage": "120/240V" },
  "proposed_service": { "amps": 200, "phase": "1-phase", "voltage": "120/240V" },
  "reason": "EV charger addition + panel full",
  "load_calculation": {
    "general_lighting_va": 4800,
    "small_appliance_va": 3000,
    "laundry_va": 1500,
    "fixed_appliances_va": [
      { "name": "Range", "va": 8000 },
      { "name": "Dryer", "va": 5000 },
      { "name": "Water Heater", "va": 4500 },
      { "name": "HVAC", "va": 6000 },
      { "name": "EV Charger", "va": 9600 }
    ],
    "total_computed_load_va": 36900,
    "total_amps_at_240v": 154
  },
  "utility_requirements": {
    "utility_name": "National Grid",
    "utility_contacted": true,
    "utility_reference": "SR-2026-12345",
    "meter_upgrade_needed": true,
    "transformer_adequate": true,
    "utility_timeline_days": 14
  },
  "permit_checklist": {
    "electrical_permit_filed": true,
    "permit_number": "E-2026-1234",
    "inspection_scheduled": false
  },
  "materials_needed": [
    "200A main breaker panel",
    "200A meter socket",
    "2/0 AWG aluminum SE cable (or 4/0 copper)",
    "Ground rod + clamp",
    "#4 copper grounding electrode conductor"
  ]
}
```

**Estimate**: 6 hours

---

## ROOFING TOOLS

> **Note**: Satellite roof measurement is handled by Phase P (Recon) — aerial scanning with Google Solar API. These tools EXTEND that, not duplicate it.

### Tool 9: Ventilation Calculator Worksheet
**Why**: Failed inspections for inadequate ventilation are the #2 roofing callback. This calculates required Net Free Ventilation Area and intake/exhaust balance.

```jsonc
// record_data schema for tool_type = 'ventilation_calc'
{
  "attic_sqft": 1200,
  "ventilation_ratio": "1:150", // 1:150 without vapor barrier, 1:300 with
  "has_vapor_barrier": true,
  "nfva_required_sqin": 576, // 1200/300 * 144
  "intake_type": "soffit_vents",
  "intake_nfva_sqin": 288, // 50% of total
  "exhaust_type": "ridge_vent",
  "exhaust_nfva_sqin": 288, // 50% of total
  "balanced": true, // intake ~= exhaust
  "existing_ventilation": { "type": "gable_vents", "nfva_sqin": 200 },
  "additional_needed_sqin": 376,
  "recommendation": "Add continuous ridge vent (12 LF x 18 NFVA/ft = 216 sq in) + 4 additional soffit vents (4 x 40 = 160 sq in)"
}
```

**Estimate**: 4 hours

---

### Tool 10: Shingle Waste Factor Calculator
**Why**: Ordering wrong amounts = return trips to supplier or wasted material. Waste factor varies by roof complexity.

```jsonc
// record_data schema for tool_type = 'waste_factor_calc'
{
  "roof_type": "hip", // gable, hip, cut_up, flat, gambrel, mansard
  "total_sqft": 2400,
  "squares": 24,
  "base_waste_pct": 15, // hip roofs: 15%, gable: 10%, cut-up: 18-22%
  "valleys_count": 4,
  "valley_waste_pct": 2, // 0.5% per valley
  "dormers_count": 2,
  "dormer_waste_pct": 1,
  "total_waste_pct": 18,
  "total_squares_with_waste": 28.32,
  "bundles_needed": 85, // 3 bundles per square
  "starter_strips_lf": 180,
  "ridge_cap_lf": 65,
  "ice_water_shield_sqft": 400, // eaves + valleys
  "underlayment_rolls": 8
}
```

**Estimate**: 4 hours

---

## GC / REMODELER TOOLS

### Tool 11: AIA Billing (G702/G703)
**Why**: Standard format for progress billing on commercial contracts. Every GC needs this. Currently done in Excel or expensive software.

```jsonc
// record_data schema for tool_type = 'aia_billing'
{
  "project_name": "Smith Kitchen Remodel",
  "contract_number": "2026-001",
  "application_number": 3, // this is billing #3
  "period_from": "2026-02-01",
  "period_to": "2026-02-28",
  "architect_name": "N/A", // for residential
  "schedule_of_values": [
    {
      "item": 1,
      "description": "Demolition",
      "scheduled_value": 3500,
      "previous_applications": 3500,
      "this_period": 0,
      "materials_stored": 0,
      "total_completed": 3500,
      "pct_complete": 100,
      "balance_to_finish": 0,
      "retainage": 350
    },
    {
      "item": 2,
      "description": "Framing",
      "scheduled_value": 5000,
      "previous_applications": 2500,
      "this_period": 2500,
      "materials_stored": 0,
      "total_completed": 5000,
      "pct_complete": 100,
      "balance_to_finish": 0,
      "retainage": 500
    },
    {
      "item": 3,
      "description": "Electrical rough-in",
      "scheduled_value": 4200,
      "previous_applications": 0,
      "this_period": 2100,
      "materials_stored": 800,
      "total_completed": 2900,
      "pct_complete": 69,
      "balance_to_finish": 1300,
      "retainage": 290
    }
  ],
  "total_contract_sum": 42000,
  "total_completed_to_date": 28400,
  "total_retainage": 2840,
  "total_earned_less_retainage": 25560,
  "less_previous_payments": 18000,
  "current_payment_due": 7560
}
```

**PDF output**: Standard AIA G702 (Application for Payment) + G703 (Continuation Sheet) format.

**Estimate**: 10 hours (complex PDF layout matching AIA standards)

---

### Tool 12: Punch List Manager
**Why**: Every job ends with a punch list. Currently done on sticky notes or a text message thread. This is a structured, room-by-room deficiency list with photos and assignees.

```jsonc
// record_data schema for tool_type = 'punch_list'
{
  "walkthrough_date": "2026-03-15",
  "attendees": ["Contractor", "Homeowner", "Designer"],
  "items": [
    {
      "id": 1,
      "room": "Kitchen",
      "description": "Cabinet door #3 has scratch on face",
      "priority": "minor", // critical, major, minor, cosmetic
      "assigned_to": "Cabinet sub",
      "photos": ["path/to/photo1.jpg"],
      "status": "open", // open, in_progress, completed, disputed
      "completed_date": null,
      "completion_photo": null,
      "notes": ""
    },
    {
      "id": 2,
      "room": "Master Bath",
      "description": "Grout missing between tile rows 3-4 near shower door",
      "priority": "major",
      "assigned_to": "Tile sub",
      "photos": ["path/to/photo2.jpg"],
      "status": "completed",
      "completed_date": "2026-03-17",
      "completion_photo": "path/to/photo3.jpg",
      "notes": "Re-grouted and sealed"
    }
  ],
  "total_items": 12,
  "completed_items": 8,
  "remaining_items": 4,
  "target_completion_date": "2026-03-22"
}
```

**Estimate**: 6 hours

---

### Tool 13: RFI Tracker
**Why**: Request for Information — standard on any multi-sub or commercial job. Tracks questions from field to architect/engineer/owner and back.

```jsonc
// record_data schema for tool_type = 'rfi_log'
{
  "rfis": [
    {
      "rfi_number": 1,
      "date_submitted": "2026-02-10",
      "submitted_by": "Electrician",
      "question": "Drawing A3.2 shows outlet on wall that has been removed per ASI #4. Where should outlet be relocated?",
      "priority": "high",
      "directed_to": "Architect",
      "response": "Relocate to adjacent wall, 48\" AFF, same circuit.",
      "response_date": "2026-02-12",
      "response_by": "John Smith, AIA",
      "status": "closed",
      "cost_impact": false,
      "schedule_impact": false,
      "attachments": []
    }
  ],
  "total_rfis": 8,
  "open_rfis": 2,
  "avg_response_days": 3.5
}
```

**Estimate**: 4 hours

---

### Tool 14: Bid Leveling Sheet
**Why**: GCs compare 3+ sub bids side-by-side, adjusting for scope differences. Currently done in Excel.

```jsonc
// record_data schema for tool_type = 'bid_leveling'
{
  "trade": "Plumbing",
  "scope_description": "Kitchen/bath remodel — rough-in + finish",
  "bidders": [
    {
      "company": "ABC Plumbing",
      "bid_amount": 8500,
      "includes_fixtures": true,
      "includes_permit": true,
      "timeline_days": 5,
      "warranty_months": 12,
      "exclusions": ["Water heater replacement"],
      "adjusted_amount": 8500,
      "notes": "Best price, good reviews"
    },
    {
      "company": "XYZ Plumbing",
      "bid_amount": 7800,
      "includes_fixtures": false,
      "includes_permit": true,
      "timeline_days": 7,
      "warranty_months": 6,
      "exclusions": ["Fixtures", "Water heater"],
      "adjusted_amount": 9400,
      "notes": "Add $1,600 for fixtures they excluded"
    },
    {
      "company": "Best Plumbing",
      "bid_amount": 9200,
      "includes_fixtures": true,
      "includes_permit": true,
      "timeline_days": 4,
      "warranty_months": 24,
      "exclusions": [],
      "adjusted_amount": 9200,
      "notes": "Most expensive but best warranty and fastest"
    }
  ],
  "selected_bidder": "ABC Plumbing",
  "selection_reason": "Best value — complete scope at lowest adjusted price"
}
```

**Estimate**: 4 hours

---

## RESTORATION / IICRC TOOLS

### Tool 15: Air Mover / Dehumidifier Placement Calculator
**Why**: IICRC S500 standard requires specific equipment density. Wrong placement = mold liability. Currently calculated by experienced techs "by feel."

```jsonc
// record_data schema for tool_type = 'air_mover_placement'
{
  "rooms": [
    {
      "name": "Living Room",
      "length_ft": 20,
      "width_ft": 16,
      "ceiling_height_ft": 9,
      "volume_cuft": 2880,
      "affected_materials": ["carpet", "drywall_2ft", "baseboard"],
      "class_of_water": 2, // 1-4 per IICRC
      "category_of_water": 1, // 1-3 per IICRC
      "air_movers_required": 4, // 1 per 10-16 LF of wall
      "dehumidifier_pints_per_day": 30,
      "air_scrubbers": 0, // needed for Cat 3 or mold
      "placement_notes": "2 aimed at affected walls, 2 aimed at carpet, angled 15-20 degrees"
    }
  ],
  "total_air_movers": 12,
  "total_dehumidifiers": 3,
  "total_air_scrubbers": 0,
  "estimated_drying_days": 3,
  "equipment_billing_rate_per_day": 185,
  "total_equipment_charge": 555
}
```

**Estimate**: 6 hours

---

### Tool 16: Water Damage Category/Class Documentation
**Why**: Insurance carriers require structured documentation of water damage classification. Category (1-3) determines contamination level. Class (1-4) determines evaporation rate. Wrong classification = denied claim.

```jsonc
// record_data schema for tool_type = 'category_class_doc'
{
  "date_of_loss": "2026-02-10",
  "date_of_inspection": "2026-02-11",
  "source_of_water": "Supply line break under kitchen sink",
  "category": 1, // 1=Clean, 2=Gray, 3=Black
  "category_justification": "Clean water from pressurized supply line, contained within 24 hours",
  "class": 2, // 1=Minor, 2=Significant, 3=Extensive, 4=Specialty
  "class_justification": "Water wicked up drywall to 24 inches, carpet and pad saturated, subfloor wet",
  "affected_rooms": [
    {
      "room": "Kitchen",
      "materials_affected": ["vinyl_flooring", "drywall", "baseboard", "cabinet_toe_kick"],
      "area_sqft": 120,
      "moisture_readings": [
        { "material": "drywall", "location": "north_wall_12in", "reading": 42, "unit": "pct", "meter": "Protimeter" },
        { "material": "drywall", "location": "north_wall_24in", "reading": 28, "unit": "pct", "meter": "Protimeter" },
        { "material": "subfloor", "location": "center", "reading": 35, "unit": "pct", "meter": "Protimeter" }
      ],
      "photos": ["path/to/photo1.jpg", "path/to/photo2.jpg"]
    }
  ],
  "recommended_protocol": "IICRC S500 Category 1, Class 2 — extract standing water, remove carpet pad, set equipment per placement calc, monitor daily until dry standard met",
  "dry_standard": "Less than 16% moisture content on all affected materials"
}
```

**Estimate**: 6 hours

---

## PAINTING TOOLS

### Tool 17: Surface Area Calculator (Professional)
**Why**: Every painter calculates wall/ceiling/trim area. But most just eyeball it. This produces a documented takeoff that justifies the estimate.

```jsonc
// record_data schema for tool_type = 'surface_area_calc'
{
  "rooms": [
    {
      "name": "Master Bedroom",
      "length_ft": 14,
      "width_ft": 12,
      "ceiling_height_ft": 9,
      "wall_sqft": 468, // perimeter * height
      "ceiling_sqft": 168,
      "deductions": [
        { "type": "window", "count": 2, "sqft_each": 15, "total": 30 },
        { "type": "door", "count": 2, "sqft_each": 21, "total": 42 },
        { "type": "closet_opening", "count": 1, "sqft_each": 21, "total": 21 }
      ],
      "net_wall_sqft": 375,
      "trim_lf": { "baseboard": 52, "crown": 52, "door_casing": 68, "window_casing": 28 },
      "doors": 2,
      "condition": "good", // good, fair, poor (affects prep time)
      "coats_needed": 2,
      "paint_type": "interior_latex_eggshell"
    }
  ],
  "totals": {
    "total_wall_sqft": 2840,
    "total_ceiling_sqft": 1200,
    "total_trim_lf": 480,
    "total_doors": 12,
    "wall_gallons": 8.1, // 350 sqft/gallon * 2 coats
    "ceiling_gallons": 3.4,
    "trim_gallons": 2.0,
    "primer_gallons": 4.0
  }
}
```

**Estimate**: 4 hours

---

### Tool 18: VOC Compliance Checker
**Why**: California (SCAQMD), New York, and other jurisdictions have strict VOC limits. Using non-compliant paint = fines.

```jsonc
// record_data schema for tool_type = 'voc_compliance'
{
  "jurisdiction": "California - SCAQMD Rule 1113",
  "products": [
    {
      "product_name": "Benjamin Moore Regal Select",
      "product_type": "interior_flat",
      "voc_grams_per_liter": 45,
      "jurisdiction_limit": 50,
      "compliant": true
    },
    {
      "product_name": "Generic Oil-Based Primer",
      "product_type": "primer",
      "voc_grams_per_liter": 340,
      "jurisdiction_limit": 100,
      "compliant": false
    }
  ],
  "all_compliant": false,
  "non_compliant_products": ["Generic Oil-Based Primer"],
  "recommendation": "Replace oil-based primer with low-VOC alternative (Zinsser BIN Zero VOC)"
}
```

**Estimate**: 3 hours

---

## LANDSCAPING TOOLS

### Tool 19: Irrigation Zone Designer
**Why**: Most complex landscape calculation. Zone layout, heads per zone, GPM per zone, pipe sizing. Currently done on graph paper.

```jsonc
// record_data schema for tool_type = 'irrigation_zone_design'
{
  "water_supply": {
    "source": "city_water", // city_water, well, reclaimed
    "pressure_psi": 55,
    "available_gpm": 12,
    "meter_size_inches": 0.75,
    "backflow_type": "PVB" // PVB, RPZ, DCA
  },
  "zones": [
    {
      "zone_number": 1,
      "area_name": "Front lawn",
      "area_sqft": 800,
      "head_type": "rotary", // rotary, spray, drip, bubbler
      "head_count": 4,
      "head_model": "Hunter PGP-ADJ",
      "gpm_per_head": 2.5,
      "total_gpm": 10.0,
      "run_time_minutes": 30,
      "precipitation_rate_in_per_hr": 0.75,
      "pipe_size_inches": 1.0,
      "pipe_type": "SCH40_PVC"
    }
  ],
  "controller": {
    "model": "Rachio 3",
    "zones_capacity": 8,
    "zones_used": 5,
    "wifi_connected": true
  },
  "total_zones": 5,
  "total_heads": 22,
  "pipe_total_lf": 340,
  "estimated_monthly_water_gallons": 15000
}
```

**Estimate**: 8 hours

---

## SPRINT SUMMARY

| # | Tool | Trade | Hours |
|---|------|-------|-------|
| 1 | Refrigerant Tracking Log | HVAC | 6 |
| 2 | Equipment Matching Tool | HVAC | 6 |
| 3 | Manual J Worksheet | HVAC | 10 |
| 4 | Backflow Test Tracker | Plumbing | 6 |
| 5 | Gas Pressure Test Log | Plumbing | 4 |
| 6 | Water Heater Sizing Worksheet | Plumbing | 4 |
| 7 | Panel Schedule Generator | Electrical | 8 |
| 8 | Service Upgrade Worksheet | Electrical | 6 |
| 9 | Ventilation Calculator | Roofing | 4 |
| 10 | Waste Factor Calculator | Roofing | 4 |
| 11 | AIA Billing (G702/G703) | GC | 10 |
| 12 | Punch List Manager | GC | 6 |
| 13 | RFI Tracker | GC | 4 |
| 14 | Bid Leveling Sheet | GC | 4 |
| 15 | Air Mover Placement Calc | Restoration | 6 |
| 16 | Category/Class Documentation | Restoration | 6 |
| 17 | Surface Area Calculator | Painting | 4 |
| 18 | VOC Compliance Checker | Painting | 3 |
| 19 | Irrigation Zone Designer | Landscaping | 8 |
| **TOTAL** | | **7 trades, 19 tools** | **~109 hours** |

### Phase Assignment
These tools are built during **Phase U (Unification)** as the "trade depth layer" — ensuring each supported trade has professional-grade workflows beyond just calculators. Sprint block: **U-TT1 through U-TT6** (TT = Trade Tools).

| Sprint | Tools | Hours |
|--------|-------|-------|
| U-TT1 | Shared infrastructure (trade_tool_records table, PDF engine, Flutter base screen) | 12 |
| U-TT2 | HVAC tools (#1-3) | 22 |
| U-TT3 | Plumbing (#4-6) + Electrical (#7-8) | 28 |
| U-TT4 | Roofing (#9-10) + GC (#11-14) | 28 |
| U-TT5 | Restoration (#15-16) + Painting (#17-18) + Landscaping (#19) | 27 |
| U-TT6 | Integration testing + PDF template polish | 8 |
