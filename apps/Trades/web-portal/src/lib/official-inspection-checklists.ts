/**
 * OFFICIAL BUILDING CODE INSPECTION CHECKLISTS
 * ==============================================
 * Based on the International Residential Code (IRC R109),
 * International Building Code (IBC), National Electrical Code (NEC/NFPA 70),
 * Uniform Plumbing Code (UPC), and International Mechanical Code (IMC).
 *
 * Sources:
 *   - 2024 IRC Section R109 — Required Inspections
 *   - InterNACHI — Understanding Types of Code Inspections (nachi.org)
 *   - mybuildingpermit.com — Residential Framing/Foundation Checklists
 *   - City of Phoenix Residential Inspection Checklist
 *   - City of San Antonio Residential Inspection Guide
 *   - Minnesota BOLAS Residential Inspection Checklist
 *   - NEC 2023 (NFPA 70) — Electrical Installation Standards
 *   - IMC 2021 — Mechanical Installation Standards
 *
 * These checklists follow the inspection sequence required by IRC R109:
 * Foundation → Underground/Rough-In → Framing → Insulation → Final
 */

// ─────────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────────

export interface InspectionPhase {
  id: string;
  name: string;
  codeReference: string;
  description: string;
  sequence: number;
  prerequisitePhases: string[];
  applicablePermitTypes: string[];
  sections: InspectionSection[];
}

export interface InspectionSection {
  id: string;
  title: string;
  trade: string;
  items: InspectionItem[];
}

export interface InspectionItem {
  id: string;
  requirement: string;
  codeReference: string;
  criticality: 'critical' | 'major' | 'minor';
  commonDeficiencies: string[];
}

// ─────────────────────────────────────────────────────────────────────
// INSPECTION PHASES (per IRC R109 sequence)
// ─────────────────────────────────────────────────────────────────────

export const INSPECTION_PHASES: InspectionPhase[] = [
  // ── PHASE 1: FOUNDATION ──────────────────────────────────────────
  {
    id: 'foundation',
    name: 'Foundation Inspection',
    codeReference: 'IRC R109.1.1',
    description:
      'Verifies foundation location matches approved plans. Inspected after excavation, with forms in place and reinforcing steel positioned, but BEFORE concrete placement.',
    sequence: 1,
    prerequisitePhases: [],
    applicablePermitTypes: ['new_construction', 'addition', 'foundation_repair'],
    sections: [
      {
        id: 'found-general',
        title: 'Foundation General',
        trade: 'general',
        items: [
          { id: 'f-01', requirement: 'Foundation location matches approved site plan — setbacks, easements, and lot lines verified', codeReference: 'IRC R109.1.1', criticality: 'critical', commonDeficiencies: ['Foundation placed too close to property line', 'Setback violation', 'Encroachment into easement'] },
          { id: 'f-02', requirement: 'Footing depth meets minimum frost line requirements for jurisdiction', codeReference: 'IRC R403.1.4', criticality: 'critical', commonDeficiencies: ['Footings not deep enough for frost line', 'Footing on undisturbed or compacted soil not verified'] },
          { id: 'f-03', requirement: 'Footing width and thickness per approved plans (minimum 12" wide, 6" thick for standard residential)', codeReference: 'IRC R403.1 / Table R403.1(1)', criticality: 'critical', commonDeficiencies: ['Footings undersized', 'Irregular footing dimensions'] },
          { id: 'f-04', requirement: 'Reinforcing steel (rebar) placed per plans — size, spacing, and cover correct', codeReference: 'IRC R403.1.3 / R404.1.2', criticality: 'critical', commonDeficiencies: ['Rebar not placed or wrong size', 'Inadequate concrete cover (min 3" against earth)', 'Rebar not tied or supported properly'] },
          { id: 'f-05', requirement: 'Foundation drain tile / perimeter drainage installed (if required)', codeReference: 'IRC R405.1', criticality: 'major', commonDeficiencies: ['Drain tile missing', 'Drain tile not sloped to daylight or sump', 'Filter fabric not installed'] },
          { id: 'f-06', requirement: 'Damp-proofing or waterproofing applied to below-grade walls (if required)', codeReference: 'IRC R406.1', criticality: 'major', commonDeficiencies: ['Damp-proofing not applied', 'Incomplete coverage'] },
          { id: 'f-07', requirement: 'Anchor bolts placed per code — 1/2" diameter, 7" min embedment, within 12" of corners and at max 6\' spacing', codeReference: 'IRC R403.1.6', criticality: 'critical', commonDeficiencies: ['Anchor bolts missing or wrong spacing', 'Bolts not within 12 inches of corners', 'Insufficient embedment depth'] },
          { id: 'f-08', requirement: 'Foundation walls — minimum thickness and height per code for soil conditions', codeReference: 'IRC R404.1', criticality: 'critical', commonDeficiencies: ['Wall thickness does not meet code', 'Reinforcing not per table requirements'] },
        ],
      },
      {
        id: 'found-slab',
        title: 'Slab-on-Grade (if applicable)',
        trade: 'general',
        items: [
          { id: 'f-09', requirement: 'Vapor retarder (6-mil minimum polyethylene) installed under slab', codeReference: 'IRC R506.2.3', criticality: 'major', commonDeficiencies: ['Vapor retarder missing', 'Punctured or torn vapor retarder not repaired'] },
          { id: 'f-10', requirement: 'Slab thickness per plans (minimum 3.5" residential)', codeReference: 'IRC R506.1', criticality: 'critical', commonDeficiencies: ['Slab too thin', 'Uneven grade beneath slab'] },
          { id: 'f-11', requirement: 'Compacted fill/gravel base per plans', codeReference: 'IRC R506.2.1', criticality: 'major', commonDeficiencies: ['Fill not compacted', 'Organic material not removed'] },
          { id: 'f-12', requirement: 'Under-slab plumbing and conduit in place and inspected before pour', codeReference: 'IRC R109.1.2', criticality: 'critical', commonDeficiencies: ['Plumbing not pressure tested before pour', 'Conduit not in place'] },
        ],
      },
    ],
  },

  // ── PHASE 2: UNDERGROUND / ROUGH-IN (Plumbing, Mechanical, Electrical, Gas) ──
  {
    id: 'rough-in',
    name: 'Plumbing, Mechanical, Gas & Electrical Rough-In',
    codeReference: 'IRC R109.1.2',
    description:
      'All rough-in inspections must be completed and approved BEFORE the framing inspection. Piping, ductwork, wiring, and gas lines verified before walls/ceilings are covered.',
    sequence: 2,
    prerequisitePhases: ['foundation'],
    applicablePermitTypes: ['new_construction', 'addition', 'remodel', 'plumbing', 'electrical', 'mechanical', 'gas'],
    sections: [
      {
        id: 'plumb-rough',
        title: 'Plumbing Rough-In',
        trade: 'plumbing',
        items: [
          { id: 'pr-01', requirement: 'All drain, waste, and vent (DWV) piping installed per plans with proper slope (1/4" per foot for 3" and larger, 1/8" per foot for 4"+)', codeReference: 'UPC 708.0 / IRC P3005.3', criticality: 'critical', commonDeficiencies: ['Insufficient slope on drain lines', 'Wrong pipe size', 'Missing cleanouts'] },
          { id: 'pr-02', requirement: 'DWV system tested — water test or air test per code (5-foot head for water, 5 PSI for 15 min for air)', codeReference: 'IRC P2503.5', criticality: 'critical', commonDeficiencies: ['System not tested before cover', 'Leaks at joints', 'Test not witnessed by inspector'] },
          { id: 'pr-03', requirement: 'Vent piping properly terminated — minimum 6 inches above roof, 10 feet from openable windows/doors', codeReference: 'IRC P3103.1', criticality: 'major', commonDeficiencies: ['Vent too short above roof', 'Too close to window/air intake'] },
          { id: 'pr-04', requirement: 'Water supply piping installed with proper support and protection (nail plates on studs where pipe is within 1.5" of edge)', codeReference: 'IRC P2603.2', criticality: 'major', commonDeficiencies: ['Missing nail plates', 'Piping not supported at proper intervals', 'Dissimilar metals in contact without dielectric union'] },
          { id: 'pr-05', requirement: 'Water supply pressure test — 40 PSI minimum for residential, held for duration of inspection', codeReference: 'IRC P2503.7', criticality: 'critical', commonDeficiencies: ['System not pressurized', 'Leaks at connections'] },
          { id: 'pr-06', requirement: 'Cleanouts installed per code — at base of each stack, at changes of direction >45°, and accessible', codeReference: 'IRC P3005.2', criticality: 'major', commonDeficiencies: ['Missing cleanouts', 'Cleanouts not accessible'] },
          { id: 'pr-07', requirement: 'Trap installed for each fixture — P-trap with proper seal depth (2"–4")', codeReference: 'IRC P3201.2', criticality: 'critical', commonDeficiencies: ['Missing traps', 'S-traps installed (not allowed)', 'Trap seal depth incorrect'] },
        ],
      },
      {
        id: 'elec-rough',
        title: 'Electrical Rough-In',
        trade: 'electrical',
        items: [
          { id: 'er-01', requirement: 'Panel size, location, and clearances per plans — minimum 36" clear in front, 30" wide, 78" headroom', codeReference: 'NEC 110.26', criticality: 'critical', commonDeficiencies: ['Insufficient clearance in front of panel', 'Panel in prohibited location (bathroom, clothes closet)'] },
          { id: 'er-02', requirement: 'All wiring methods approved — NM cable (Romex) used only in dry locations, properly supported every 4.5 feet and within 12" of boxes', codeReference: 'NEC 334.30', criticality: 'major', commonDeficiencies: ['Cable not secured properly', 'NM cable used in wet location', 'Cables running through notches without protection'] },
          { id: 'er-03', requirement: 'Wire gauge matches circuit breaker rating — 14 AWG for 15A, 12 AWG for 20A, 10 AWG for 30A', codeReference: 'NEC 240.4(D)', criticality: 'critical', commonDeficiencies: ['14 AWG on 20A breaker', 'Wire gauge insufficient for load'] },
          { id: 'er-04', requirement: 'GFCI protection required: bathrooms, kitchens (within 6 feet of sink), garages, outdoors, laundry, crawl spaces, unfinished basements', codeReference: 'NEC 210.8(A)', criticality: 'critical', commonDeficiencies: ['GFCI missing in required locations', 'GFCI protection not on first outlet in circuit'] },
          { id: 'er-05', requirement: 'AFCI protection required on all 120V, 15A and 20A branch circuits supplying outlets/devices in dwelling unit bedrooms (and all habitable rooms per 2023 NEC)', codeReference: 'NEC 210.12(A)', criticality: 'critical', commonDeficiencies: ['AFCI breakers missing', 'AFCI not installed in required locations'] },
          { id: 'er-06', requirement: 'Boxes properly sized for number of conductors — box fill calculation per Table 314.16(A)', codeReference: 'NEC 314.16', criticality: 'major', commonDeficiencies: ['Box overfilled', 'Too many conductors for box size'] },
          { id: 'er-07', requirement: 'Nail plates installed where wiring passes through studs within 1.25 inches of the edge', codeReference: 'NEC 300.4(A)(1)', criticality: 'critical', commonDeficiencies: ['Missing nail plates', 'Cables not protected from nail/screw penetration'] },
          { id: 'er-08', requirement: 'Smoke detector circuits — interconnected, on dedicated or shared circuit, locations per code', codeReference: 'IRC R314.4 / NEC 760', criticality: 'critical', commonDeficiencies: ['Smoke detectors not interconnected', 'Missing from required locations (each bedroom, outside sleeping areas, each story)'] },
          { id: 'er-09', requirement: 'Kitchen — minimum two 20A small appliance branch circuits, separate from lighting', codeReference: 'NEC 210.11(C)(1)', criticality: 'major', commonDeficiencies: ['Only one kitchen counter circuit', 'Kitchen counter outlets on lighting circuit'] },
          { id: 'er-10', requirement: 'Bathroom — dedicated 20A circuit(s), GFCI protected', codeReference: 'NEC 210.11(C)(3)', criticality: 'major', commonDeficiencies: ['Bathroom outlet on shared circuit', 'Missing GFCI protection'] },
        ],
      },
      {
        id: 'mech-rough',
        title: 'Mechanical / HVAC Rough-In',
        trade: 'hvac',
        items: [
          { id: 'mr-01', requirement: 'Ductwork installed per plans — proper sizing, sealed joints, supported per code (sheet metal straps at max 10\' intervals)', codeReference: 'IMC 603.0 / IRC M1601', criticality: 'major', commonDeficiencies: ['Ducts undersized', 'Joints not sealed with mastic or tape', 'Flex duct kinked or compressed'] },
          { id: 'mr-02', requirement: 'Combustion air supply provided for fuel-burning appliances — sized per appliance BTU input', codeReference: 'IMC 701.0 / IRC G2407', criticality: 'critical', commonDeficiencies: ['Combustion air openings missing or undersized', 'Combustion air blocked by insulation'] },
          { id: 'mr-03', requirement: 'Exhaust ventilation — bathroom fans vented to outdoors (not to attic), kitchen range hood ducted per plans', codeReference: 'IMC 501.0 / IRC M1501', criticality: 'major', commonDeficiencies: ['Bathroom fan vented into attic', 'Exhaust duct terminated in soffit (recirculates into attic)'] },
          { id: 'mr-04', requirement: 'Gas piping tested — air test at 3 PSI for 10 minutes (or per local requirements) before gas is turned on', codeReference: 'IRC G2417.4 / IFGC 406.4', criticality: 'critical', commonDeficiencies: ['Gas piping not tested', 'Leaks at threaded connections', 'Test not documented'] },
          { id: 'mr-05', requirement: 'Refrigerant lines properly sized and insulated (suction line must be insulated)', codeReference: 'IMC 1105.0 / IRC M1411', criticality: 'major', commonDeficiencies: ['Suction line not insulated', 'Lines undersized for run length'] },
          { id: 'mr-06', requirement: 'Dryer exhaust duct — rigid metal, maximum 35 feet (minus deductions for elbows), terminates to outdoors', codeReference: 'IRC M1502', criticality: 'major', commonDeficiencies: ['Flexible vinyl duct used (fire hazard)', 'Duct too long', 'Terminated in crawlspace or attic'] },
        ],
      },
      {
        id: 'gas-rough',
        title: 'Gas Piping',
        trade: 'plumbing',
        items: [
          { id: 'gr-01', requirement: 'Gas piping material approved — black steel, CSST (with bonding), or approved flexible connector', codeReference: 'IRC G2414 / IFGC 403', criticality: 'critical', commonDeficiencies: ['Unapproved piping material', 'CSST not bonded to grounding electrode system'] },
          { id: 'gr-02', requirement: 'Gas piping sized per BTU demand — longest run method or branch length method', codeReference: 'IRC G2413 / IFGC 402.4', criticality: 'critical', commonDeficiencies: ['Piping undersized for BTU load', 'Pressure drop too high at appliance'] },
          { id: 'gr-03', requirement: 'Shutoff valve installed within 6 feet of each gas appliance — accessible and in same room', codeReference: 'IRC G2420 / IFGC 409.1', criticality: 'critical', commonDeficiencies: ['Shutoff valve missing', 'Valve not accessible', 'Valve in different room from appliance'] },
          { id: 'gr-04', requirement: 'Gas piping properly supported — every 6 feet for steel pipe, every 4 feet for copper/CSST', codeReference: 'IRC G2418 / IFGC 407', criticality: 'major', commonDeficiencies: ['Piping unsupported or sagging', 'Support intervals too wide'] },
          { id: 'gr-05', requirement: 'CSST (Corrugated Stainless Steel Tubing) bonded to the electrical grounding electrode system per manufacturer instructions', codeReference: 'IRC G2411.1.1 / IFGC 310.1.1', criticality: 'critical', commonDeficiencies: ['CSST bonding missing — lightning strike risk', 'Bonding wire undersized or improperly connected'] },
        ],
      },
    ],
  },

  // ── PHASE 3: FRAMING ─────────────────────────────────────────────
  {
    id: 'framing',
    name: 'Frame and Masonry Inspection',
    codeReference: 'IRC R109.1.4',
    description:
      'Final opportunity to inspect structural items before concealment. ALL rough-in inspections (electrical, mechanical, plumbing, gas, fire sprinkler) must be approved BEFORE framing inspection.',
    sequence: 3,
    prerequisitePhases: ['foundation', 'rough-in'],
    applicablePermitTypes: ['new_construction', 'addition', 'remodel'],
    sections: [
      {
        id: 'frame-struct',
        title: 'Structural Framing',
        trade: 'general',
        items: [
          { id: 'fr-01', requirement: 'Lumber grade and species match approved plans — stamp visible on framing members', codeReference: 'IRC R502.1 / R602.1 / R802.1', criticality: 'critical', commonDeficiencies: ['Unstamped lumber', 'Lower grade than specified', 'Treated lumber not used where required (sill plates, ground contact)'] },
          { id: 'fr-02', requirement: 'Sill plate fastened with anchor bolts per foundation inspection — washer and nut tight, sill plate pressure-treated or naturally durable', codeReference: 'IRC R403.1.6 / R317.1', criticality: 'critical', commonDeficiencies: ['Sill plate not treated', 'Nuts not tightened', 'Anchor bolts missing washers'] },
          { id: 'fr-03', requirement: 'Wall framing — stud size, spacing, and height per plans (typically 2x4 @ 16" OC, max 10\' height for standard residential)', codeReference: 'IRC R602.3 / Table R602.3(5)', criticality: 'critical', commonDeficiencies: ['Stud spacing too wide', 'Studs undersized for wall height', 'Jack/king studs missing at openings'] },
          { id: 'fr-04', requirement: 'Headers sized per span and load — per Table R602.7(1) or engineered', codeReference: 'IRC R602.7', criticality: 'critical', commonDeficiencies: ['Headers undersized for span', 'Missing headers at openings in bearing walls'] },
          { id: 'fr-05', requirement: 'Floor framing — joist size, spacing, and span per tables or engineering', codeReference: 'IRC R502.3 / Table R502.3.1(1)', criticality: 'critical', commonDeficiencies: ['Joists span exceeds table allowance', 'Notches or holes in joists exceed limits'] },
          { id: 'fr-06', requirement: 'Joist notches/holes within limits — notch max 1/3 depth in outer 1/3 of span; holes max 1/3 depth, min 2" from edges', codeReference: 'IRC R502.8', criticality: 'critical', commonDeficiencies: ['Oversized notches in joists', 'Holes too close to edge', 'Notches in center 1/3 of span'] },
          { id: 'fr-07', requirement: 'Roof framing — rafter/truss size, spacing, and connections per plans', codeReference: 'IRC R802.3 / R802.10', criticality: 'critical', commonDeficiencies: ['Rafters undersized', 'Truss modifications without engineer approval', 'Ridge board missing or undersized'] },
          { id: 'fr-08', requirement: 'Bracing/shear walls installed per plans — approved materials (structural sheathing, let-in bracing, or engineered)', codeReference: 'IRC R602.10', criticality: 'critical', commonDeficiencies: ['Bracing missing', 'Wrong nailing pattern on shear panels', 'Insufficient shear wall length'] },
          { id: 'fr-09', requirement: 'Fireblocking installed at all required locations — stud cavities at floor/ceiling, soffits, stairways, drop ceilings', codeReference: 'IRC R302.11', criticality: 'critical', commonDeficiencies: ['Fireblocking missing at floor levels', 'Gaps around pipes/wires through fireblocking', 'Missing in furred spaces and soffits'] },
          { id: 'fr-10', requirement: 'Draftstopping installed in floor/ceiling assemblies over 1,000 sq ft of concealed space', codeReference: 'IRC R302.12', criticality: 'major', commonDeficiencies: ['Draftstopping missing in large floor assemblies', 'Gaps not sealed'] },
          { id: 'fr-11', requirement: 'Nailing schedule followed — correct nail size and spacing for each connection per Table R602.3(1)', codeReference: 'IRC R602.3(1)', criticality: 'critical', commonDeficiencies: ['Wrong nail size', 'Nails too far apart', 'Over-driven nails in sheathing'] },
        ],
      },
      {
        id: 'frame-connections',
        title: 'Connections and Hold-Downs',
        trade: 'general',
        items: [
          { id: 'fc-01', requirement: 'Hurricane/seismic straps and hold-downs installed per plans and manufacturer specifications', codeReference: 'IRC R602.10 / R802.11', criticality: 'critical', commonDeficiencies: ['Straps missing', 'Wrong strap model for connection', 'Insufficient fasteners in strap'] },
          { id: 'fc-02', requirement: 'Simpson (or approved) hangers at all beam-to-post, joist-to-beam, and joist-to-ledger connections', codeReference: 'IRC R502.6', criticality: 'critical', commonDeficiencies: ['Missing hangers', 'Wrong hanger for member size', 'Hanger nails vs structural screws — must match specs'] },
          { id: 'fc-03', requirement: 'Continuous load path from roof to foundation verified — all connections in the chain present', codeReference: 'IRC R301.1', criticality: 'critical', commonDeficiencies: ['Break in load path at floor level', 'Hold-down bolts not tightened', 'Missing hardware at critical connections'] },
        ],
      },
    ],
  },

  // ── PHASE 4: INSULATION / ENERGY ─────────────────────────────────
  {
    id: 'insulation',
    name: 'Insulation and Energy Inspection',
    codeReference: 'IRC R109.1.5 / IRC N1102',
    description:
      'Insulation inspection occurs after framing is approved and before drywall. Verifies thermal envelope, air sealing, and energy code compliance.',
    sequence: 4,
    prerequisitePhases: ['framing'],
    applicablePermitTypes: ['new_construction', 'addition', 'remodel'],
    sections: [
      {
        id: 'insul-general',
        title: 'Insulation and Air Sealing',
        trade: 'insulation',
        items: [
          { id: 'in-01', requirement: 'Wall insulation R-value meets or exceeds code for climate zone (e.g., R-20 or R-13+5ci for Zone 4)', codeReference: 'IRC N1102.1.2 / Table N1102.1.2', criticality: 'critical', commonDeficiencies: ['R-value too low for climate zone', 'Insulation compressed (reduces effective R-value)', 'Gaps and voids in cavity insulation'] },
          { id: 'in-02', requirement: 'Ceiling/attic insulation R-value meets code (e.g., R-38 to R-60 depending on zone)', codeReference: 'IRC N1102.1.2 / Table N1102.1.2', criticality: 'critical', commonDeficiencies: ['Insufficient depth', 'Insulation missing at eaves/soffits', 'Insulation blocking soffit vents'] },
          { id: 'in-03', requirement: 'Floor insulation R-value meets code where floors are over unconditioned spaces', codeReference: 'IRC N1102.1.2', criticality: 'major', commonDeficiencies: ['Insulation falling away from subfloor', 'Missing support (tiger teeth or wire)', 'Gaps at band/rim joist'] },
          { id: 'in-04', requirement: 'Air sealing completed — all penetrations (wiring, plumbing, ductwork) through thermal envelope sealed with caulk, foam, or approved materials', codeReference: 'IRC N1102.4', criticality: 'critical', commonDeficiencies: ['Unsealed penetrations at top plates', 'Gaps around electrical boxes in exterior walls', 'Rim joist not sealed'] },
          { id: 'in-05', requirement: 'Vapor retarder installed on warm-in-winter side where required by climate zone', codeReference: 'IRC R702.7', criticality: 'major', commonDeficiencies: ['Vapor retarder on wrong side', 'Vapor retarder missing in cold climates', 'Conflicting vapor retarders (double vapor barrier)'] },
          { id: 'in-06', requirement: 'Recessed lights — IC-rated if in contact with insulation, sealed to air barrier', codeReference: 'IRC N1102.4', criticality: 'major', commonDeficiencies: ['Non-IC rated lights in insulation contact', 'Air leakage around recessed lights'] },
          { id: 'in-07', requirement: 'Duct insulation — supply ducts in unconditioned spaces insulated to minimum R-8; return ducts R-6', codeReference: 'IRC N1103.3', criticality: 'major', commonDeficiencies: ['Uninsulated ducts in attic/crawlspace', 'Insulation not covering full duct', 'Duct joints not sealed before insulating'] },
        ],
      },
    ],
  },

  // ── PHASE 5: FIRE-RESISTANCE-RATED CONSTRUCTION ──────────────────
  {
    id: 'fire-resistance',
    name: 'Fire-Resistance-Rated Construction Inspection',
    codeReference: 'IRC R109.1.5.1',
    description:
      'Required where dwelling units are separated or exterior walls are within 3 feet of property lines. Inspected when covering materials are in place but fasteners remain exposed.',
    sequence: 5,
    prerequisitePhases: ['framing', 'insulation'],
    applicablePermitTypes: ['new_construction', 'addition', 'duplex', 'townhouse'],
    sections: [
      {
        id: 'fire-rated',
        title: 'Fire-Rated Assemblies',
        trade: 'general',
        items: [
          { id: 'fir-01', requirement: 'Separation walls between dwelling units — 1-hour fire-resistance rated from foundation to underside of roof sheathing', codeReference: 'IRC R302.1 / R302.2', criticality: 'critical', commonDeficiencies: ['Gaps in fire-rated assembly', 'Wrong drywall type (must be Type X 5/8")', 'Penetrations not fire-caulked'] },
          { id: 'fir-02', requirement: 'Exterior walls within 3 feet of property line — 1-hour fire-resistance rated on interior side', codeReference: 'IRC R302.1 Table R302.1(1)', criticality: 'critical', commonDeficiencies: ['Missing fire-rated covering', 'Openings (windows/doors) not compliant at <3 feet'] },
          { id: 'fir-03', requirement: 'All penetrations through fire-rated assemblies sealed with listed fire-stop materials', codeReference: 'IRC R302.4', criticality: 'critical', commonDeficiencies: ['Unsealed pipe/wire penetrations', 'Wrong sealant type (must be fire-rated)'] },
          { id: 'fir-04', requirement: 'Garage separation — 1/2" drywall on garage side of shared walls/ceilings (5/8" Type X if garage is below habitable rooms)', codeReference: 'IRC R302.6', criticality: 'critical', commonDeficiencies: ['Drywall missing in garage', 'Wrong thickness', 'Gaps/openings not sealed'] },
        ],
      },
    ],
  },

  // ── PHASE 6: FINAL INSPECTION ────────────────────────────────────
  {
    id: 'final',
    name: 'Final Inspection',
    codeReference: 'IRC R109.1.6',
    description:
      'Occurs after ALL permitted work is complete but BEFORE occupancy. Covers fire safety, life safety, structural safety, and all trades. Must be approved before Certificate of Occupancy is issued.',
    sequence: 6,
    prerequisitePhases: ['foundation', 'rough-in', 'framing', 'insulation'],
    applicablePermitTypes: ['new_construction', 'addition', 'remodel', 'plumbing', 'electrical', 'mechanical'],
    sections: [
      {
        id: 'final-general',
        title: 'General / Life Safety',
        trade: 'general',
        items: [
          { id: 'fin-01', requirement: 'All work matches approved plans — any changes have approved revision or field modification approval', codeReference: 'IRC R109.1.6', criticality: 'critical', commonDeficiencies: ['Work does not match plans', 'Unapproved changes to layout'] },
          { id: 'fin-02', requirement: 'Smoke alarms installed — each bedroom, outside each sleeping area, each story, interconnected', codeReference: 'IRC R314.3', criticality: 'critical', commonDeficiencies: ['Missing smoke alarms', 'Not interconnected', 'Wrong locations'] },
          { id: 'fin-03', requirement: 'Carbon monoxide alarms installed — outside each sleeping area on every level with fuel-burning appliances or attached garage', codeReference: 'IRC R315.1', criticality: 'critical', commonDeficiencies: ['CO alarms missing', 'Not on every required level'] },
          { id: 'fin-04', requirement: 'Egress windows in all sleeping rooms — min 5.7 sq ft opening (5.0 sq ft at grade), min 24" high, min 20" wide, max 44" sill height', codeReference: 'IRC R310.1', criticality: 'critical', commonDeficiencies: ['Window too small', 'Sill too high', 'Window blocked or inoperable'] },
          { id: 'fin-05', requirement: 'Stairways — min 36" wide, max 7-3/4" riser, min 10" tread, handrail 34"–38" height, graspable (1.25"–2" diameter)', codeReference: 'IRC R311.7', criticality: 'critical', commonDeficiencies: ['Risers too high', 'Treads too narrow', 'Handrail missing or wrong height', 'Riser/tread variation >3/8"'] },
          { id: 'fin-06', requirement: 'Guards (guardrails) — required where walking surface is >30" above grade, min 36" high (42" for decks >30" above grade in some jurisdictions), balusters max 4" apart', codeReference: 'IRC R312.1', criticality: 'critical', commonDeficiencies: ['Guards too short', 'Baluster spacing >4"', 'Guards missing at elevated areas'] },
          { id: 'fin-07', requirement: 'Address numbers visible from street — min 4" high, contrasting color', codeReference: 'IRC R319.1', criticality: 'minor', commonDeficiencies: ['Numbers not posted', 'Too small to see from street'] },
        ],
      },
      {
        id: 'final-plumb',
        title: 'Plumbing Final',
        trade: 'plumbing',
        items: [
          { id: 'fin-p01', requirement: 'All fixtures installed, functional, and connected — toilets, sinks, tubs/showers, hose bibbs', codeReference: 'IRC P2701', criticality: 'critical', commonDeficiencies: ['Fixtures not secured', 'Connections leaking', 'Missing fixtures from plans'] },
          { id: 'fin-p02', requirement: 'Water heater — T&P relief valve installed with discharge pipe to within 6" of floor or to outdoors, no reduction in pipe size', codeReference: 'IRC P2803.6', criticality: 'critical', commonDeficiencies: ['T&P valve missing', 'Discharge pipe missing/terminated wrong', 'Discharge pipe reduced in size'] },
          { id: 'fin-p03', requirement: 'Hot water temperature — max 120°F at fixtures (anti-scald valves in showers set to max 120°F)', codeReference: 'IRC P2802.2', criticality: 'major', commonDeficiencies: ['Water heater set too high', 'Anti-scald valve not set'] },
          { id: 'fin-p04', requirement: 'Backflow prevention — hose bibbs have vacuum breaker, no cross-connections', codeReference: 'IRC P2902', criticality: 'major', commonDeficiencies: ['Vacuum breaker missing on hose bib', 'Cross-connection between potable and non-potable'] },
        ],
      },
      {
        id: 'final-elec',
        title: 'Electrical Final',
        trade: 'electrical',
        items: [
          { id: 'fin-e01', requirement: 'All outlets, switches, and cover plates installed — no open boxes, no exposed wiring', codeReference: 'NEC 314.25 / 406.6', criticality: 'critical', commonDeficiencies: ['Missing cover plates', 'Open junction boxes', 'Exposed wiring'] },
          { id: 'fin-e02', requirement: 'Panel labeled — all circuits identified on panel schedule', codeReference: 'NEC 408.4', criticality: 'major', commonDeficiencies: ['Panel not labeled', 'Labels incomplete or illegible'] },
          { id: 'fin-e03', requirement: 'Outdoor outlets and fixtures — weatherproof covers (in-use covers for outlets likely to have cords plugged in)', codeReference: 'NEC 406.9 / 410.10', criticality: 'major', commonDeficiencies: ['Non-weatherproof covers on outdoor outlets', 'Missing in-use covers'] },
          { id: 'fin-e04', requirement: 'Receptacle spacing — no point along wall line more than 6 feet from an outlet (12-foot max between outlets on any wall ≥2 feet wide)', codeReference: 'NEC 210.52(A)', criticality: 'major', commonDeficiencies: ['Outlets too far apart', 'Missing outlets on required walls'] },
          { id: 'fin-e05', requirement: 'Kitchen counter outlets — within 4 feet of start of countertop, max 4 feet apart, GFCI protected', codeReference: 'NEC 210.52(C)', criticality: 'major', commonDeficiencies: ['Counter space >4 feet without outlet', 'Missing GFCI protection on counter outlets'] },
          { id: 'fin-e06', requirement: 'Exterior lighting — at all exterior doors, deck, patio areas per plans', codeReference: 'IRC N1104 / NEC 210.70', criticality: 'minor', commonDeficiencies: ['Missing exterior light at entry', 'Missing switch at required location'] },
        ],
      },
      {
        id: 'final-mech',
        title: 'Mechanical / HVAC Final',
        trade: 'hvac',
        items: [
          { id: 'fin-m01', requirement: 'HVAC system operational — heating and cooling functional, thermostat controlling properly', codeReference: 'IMC 304.0 / IRC M1401', criticality: 'critical', commonDeficiencies: ['System not operational', 'Thermostat not controlling', 'Refrigerant not charged'] },
          { id: 'fin-m02', requirement: 'Condensate drain from A/C — properly piped to approved location (not to sanitary sewer), secondary drain or float switch on systems in attics', codeReference: 'IRC M1411.3', criticality: 'major', commonDeficiencies: ['Condensate drain missing', 'No secondary drain/float switch on attic unit', 'Drain not trapped'] },
          { id: 'fin-m03', requirement: 'Combustion appliance clearances — proper distances from combustible materials maintained per manufacturer specs', codeReference: 'IMC 306.0 / IRC M1306', criticality: 'critical', commonDeficiencies: ['Furnace/water heater too close to combustibles', 'Storage items blocking clearances'] },
          { id: 'fin-m04', requirement: 'Ventilation — whole-house ventilation system operational (if required), bathroom and kitchen exhaust fans functional', codeReference: 'IRC M1505 / N1104', criticality: 'major', commonDeficiencies: ['Exhaust fans not connected', 'Whole-house ventilation not installed'] },
        ],
      },
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────

/** Get an inspection phase by ID */
export function getInspectionPhase(phaseId: string): InspectionPhase | undefined {
  return INSPECTION_PHASES.find(p => p.id === phaseId);
}

/** Get all inspection phases in sequence order */
export function getInspectionPhasesInOrder(): InspectionPhase[] {
  return [...INSPECTION_PHASES].sort((a, b) => a.sequence - b.sequence);
}

/** Get all items for a specific trade across all phases */
export function getInspectionItemsByTrade(trade: string): { phase: string; section: string; item: InspectionItem }[] {
  const results: { phase: string; section: string; item: InspectionItem }[] = [];
  for (const phase of INSPECTION_PHASES) {
    for (const section of phase.sections) {
      if (section.trade === trade) {
        for (const item of section.items) {
          results.push({ phase: phase.name, section: section.title, item });
        }
      }
    }
  }
  return results;
}

/** Get all critical items across all phases */
export function getCriticalInspectionItems(): { phase: string; section: string; item: InspectionItem }[] {
  const results: { phase: string; section: string; item: InspectionItem }[] = [];
  for (const phase of INSPECTION_PHASES) {
    for (const section of phase.sections) {
      for (const item of section.items) {
        if (item.criticality === 'critical') {
          results.push({ phase: phase.name, section: section.title, item });
        }
      }
    }
  }
  return results;
}

/** Get inspection phases applicable to a specific permit type */
export function getInspectionPhasesForPermit(permitType: string): InspectionPhase[] {
  return INSPECTION_PHASES
    .filter(p => p.applicablePermitTypes.includes(permitType))
    .sort((a, b) => a.sequence - b.sequence);
}

/** Get total count of inspection items */
export function getTotalInspectionItemCount(): number {
  return INSPECTION_PHASES.reduce(
    (sum, phase) =>
      sum + phase.sections.reduce((sSum, section) => sSum + section.items.length, 0),
    0
  );
}

/** Get phases with their completion status (for checklist UI) */
export function getPhaseChecklistSummary(): {
  id: string;
  name: string;
  sequence: number;
  totalItems: number;
  criticalItems: number;
}[] {
  return INSPECTION_PHASES.map(phase => {
    let totalItems = 0;
    let criticalItems = 0;
    for (const section of phase.sections) {
      totalItems += section.items.length;
      criticalItems += section.items.filter(i => i.criticality === 'critical').length;
    }
    return {
      id: phase.id,
      name: phase.name,
      sequence: phase.sequence,
      totalItems,
      criticalItems,
    };
  });
}
