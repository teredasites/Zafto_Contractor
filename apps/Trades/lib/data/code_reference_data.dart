// ============================================================
// Code Reference Seed Data
//
// Searchable building code sections for field inspectors.
// Covers: NEC (electrical), IBC (building), IRC (residential),
// OSHA (safety, 29 CFR 1926), NFPA (fire/life safety).
//
// Offline-capable — all data is local Dart constants.
// ============================================================

enum CodeBody {
  nec,
  ibc,
  irc,
  osha,
  nfpa;

  String get label {
    switch (this) {
      case CodeBody.nec:
        return 'NEC';
      case CodeBody.ibc:
        return 'IBC';
      case CodeBody.irc:
        return 'IRC';
      case CodeBody.osha:
        return 'OSHA';
      case CodeBody.nfpa:
        return 'NFPA';
    }
  }

  String get fullName {
    switch (this) {
      case CodeBody.nec:
        return 'National Electrical Code (NFPA 70)';
      case CodeBody.ibc:
        return 'International Building Code';
      case CodeBody.irc:
        return 'International Residential Code';
      case CodeBody.osha:
        return 'OSHA Construction Standards (29 CFR 1926)';
      case CodeBody.nfpa:
        return 'National Fire Protection Association';
    }
  }
}

class CodeSection {
  final CodeBody body;
  final String article;
  final String title;
  final String summary;
  final String chapter;
  final List<String> keywords;
  final String? tradeRelevance; // which trades this matters to

  const CodeSection({
    required this.body,
    required this.article,
    required this.title,
    required this.summary,
    required this.chapter,
    this.keywords = const [],
    this.tradeRelevance,
  });

  String get searchText =>
      '${body.label} $article $title $summary ${keywords.join(' ')} ${tradeRelevance ?? ''}'
          .toLowerCase();
}

// ── NEC (National Electrical Code) ─────────────────────────
const _necSections = <CodeSection>[
  CodeSection(
    body: CodeBody.nec,
    article: '110.12',
    title: 'Mechanical Execution of Work',
    summary:
        'Electrical equipment shall be installed in a neat and workmanlike manner. Unused openings must be effectively closed.',
    chapter: 'Chapter 1 — General',
    keywords: ['workmanship', 'installation', 'quality', 'openings'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '110.14',
    title: 'Electrical Connections',
    summary:
        'Conductors shall be spliced or joined with devices identified for the use. Connections by solder, connectors, or pressure devices.',
    chapter: 'Chapter 1 — General',
    keywords: ['splicing', 'connections', 'wire nuts', 'terminals'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '110.26',
    title: 'Spaces About Electrical Equipment',
    summary:
        'Working space for equipment likely to require examination, adjustment, servicing, or maintenance. Minimum 36" depth for 0-150V, 42" for 151-600V.',
    chapter: 'Chapter 1 — General',
    keywords: ['clearance', 'working space', 'panel access', '36 inches'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '200.6',
    title: 'Means of Identifying Grounded Conductors',
    summary:
        'Grounded conductor 6 AWG or smaller: white or gray insulation, or 3 continuous white/gray stripes. Larger: white marking at terminations.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['neutral', 'grounded', 'white wire', 'identification'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '210.8',
    title: 'GFCI Protection',
    summary:
        'Ground-fault circuit-interrupter protection required for: bathrooms, kitchens (within 6 ft of sink), outdoors, garages, basements, crawl spaces, laundry areas, boathouses.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['GFCI', 'ground fault', 'bathroom', 'kitchen', 'outdoor'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '210.12',
    title: 'Arc-Fault Circuit-Interrupter Protection',
    summary:
        'AFCI protection required for: kitchens, family rooms, dining rooms, living rooms, parlors, libraries, dens, bedrooms, sunrooms, recreation rooms, closets, hallways, laundry areas.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['AFCI', 'arc fault', 'bedroom', 'living room'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '210.52',
    title: 'Dwelling Unit Receptacle Outlets',
    summary:
        'Receptacle outlets required so no point along floor line is more than 6 ft from an outlet. Kitchen countertop: every 4 ft. Bathroom: at least one within 3 ft of sink.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['receptacles', 'outlets', 'spacing', '6 foot rule', 'countertop'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '230.70',
    title: 'Service Disconnecting Means',
    summary:
        'Each service shall have a readily accessible means of disconnecting all conductors from the service entrance. Maximum 6 switches or circuit breakers.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['main disconnect', 'service entrance', 'panel', 'breaker'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '250.50',
    title: 'Grounding Electrode System',
    summary:
        'All grounding electrodes present at each building shall be bonded together: metal underground water pipe, metal building frame, concrete-encased electrode (Ufer ground), ground ring.',
    chapter: 'Chapter 2 — Wiring and Protection',
    keywords: ['grounding', 'electrode', 'bonding', 'Ufer', 'ground rod'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '300.4',
    title: 'Protection Against Physical Damage',
    summary:
        'Where NM cable passes through studs, joists, or rafters, the edge of the bored hole must be at least 1-1/4" from the nearest edge, or steel nail plate required.',
    chapter: 'Chapter 3 — Wiring Methods and Materials',
    keywords: ['nail plate', 'protection', 'boring', 'NM cable', 'Romex'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '314.16',
    title: 'Box Fill Calculations',
    summary:
        'Number of conductors permitted in a box based on box volume. Each 14 AWG = 2 cu in, 12 AWG = 2.25 cu in, 10 AWG = 2.5 cu in. Deductions for clamps, devices, grounding.',
    chapter: 'Chapter 3 — Wiring Methods and Materials',
    keywords: ['box fill', 'volume', 'conductor count', 'junction box'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '334.10',
    title: 'NM Cable Uses Permitted',
    summary:
        'Type NM cable permitted in one- and two-family dwellings, multifamily dwellings (Types III, IV, V construction). Not permitted in commercial buildings over 3 stories.',
    chapter: 'Chapter 3 — Wiring Methods and Materials',
    keywords: ['NM cable', 'Romex', 'residential', 'permitted uses'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '408.4',
    title: 'Circuit Directory or Circuit Identification',
    summary:
        'Every circuit and circuit modification shall be legibly identified as to its clear, evident, and specific purpose or use. Directory must be located at each panel.',
    chapter: 'Chapter 4 — Equipment for General Use',
    keywords: ['panel schedule', 'circuit directory', 'labeling', 'identification'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '422.16',
    title: 'Flexible Cords for Appliances',
    summary:
        'Specific appliances may use flexible cord: ranges, dryers, dishwashers, trash compactors, kitchen waste disposers. Cord must be 3-4 ft for ranges/dryers.',
    chapter: 'Chapter 4 — Equipment for General Use',
    keywords: ['appliance cord', 'range', 'dryer', 'flexible cord'],
    tradeRelevance: 'Electrical',
  ),
  CodeSection(
    body: CodeBody.nec,
    article: '680.21',
    title: 'Swimming Pool Motors',
    summary:
        'Pool pump motors shall be connected to GFCI-protected circuits. Bonding required for all metal within 5 ft of pool edge.',
    chapter: 'Chapter 6 — Special Equipment',
    keywords: ['swimming pool', 'bonding', 'GFCI', 'pump motor'],
    tradeRelevance: 'Electrical',
  ),
];

// ── IBC (International Building Code) ──────────────────────
const _ibcSections = <CodeSection>[
  CodeSection(
    body: CodeBody.ibc,
    article: '202',
    title: 'Definitions',
    summary:
        'Key definitions: Story, Building Height, Area, Fire Resistance Rating, Means of Egress, Occupancy Classification.',
    chapter: 'Chapter 2 — Definitions',
    keywords: ['definitions', 'occupancy', 'story', 'height'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '302.1',
    title: 'Occupancy Classification',
    summary:
        'Buildings classified by use: A (Assembly), B (Business), E (Educational), F (Factory), H (Hazardous), I (Institutional), M (Mercantile), R (Residential), S (Storage), U (Utility).',
    chapter: 'Chapter 3 — Use and Occupancy Classification',
    keywords: ['occupancy', 'classification', 'use group', 'assembly'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '504.3',
    title: 'Building Height in Stories',
    summary:
        'Maximum building height in stories based on construction type and occupancy. Type IA = unlimited (with sprinklers), Type VB = most restricted.',
    chapter: 'Chapter 5 — General Building Heights and Areas',
    keywords: ['height', 'stories', 'construction type', 'sprinkler increase'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '602.1',
    title: 'Construction Classification',
    summary:
        'Five construction types: Type I (noncombustible, fire-resistive), II (noncombustible), III (exterior noncombustible), IV (heavy timber), V (wood frame). A = protected, B = unprotected.',
    chapter: 'Chapter 6 — Types of Construction',
    keywords: ['construction type', 'fire resistive', 'noncombustible', 'wood frame'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '903.2',
    title: 'Automatic Sprinkler Systems — Where Required',
    summary:
        'Sprinklers required in: Group A (assembly >300 occupant load), Group E (educational), Group H (hazardous), Group I (institutional), Group R (residential) stories >2, Group S-1 >12,000 sq ft.',
    chapter: 'Chapter 9 — Fire Protection and Life Safety',
    keywords: ['sprinkler', 'fire suppression', 'required', 'occupant load'],
    tradeRelevance: 'Fire Protection, General Contractor',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1003.1',
    title: 'Applicability — Means of Egress',
    summary:
        'Buildings or structures shall be provided with a means of egress system. Egress = exit access + exit + exit discharge. All 3 components required.',
    chapter: 'Chapter 10 — Means of Egress',
    keywords: ['egress', 'exit', 'evacuation', 'escape route'],
    tradeRelevance: 'General Contractor, Inspector, Fire Protection',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1005.1',
    title: 'Egress Width',
    summary:
        'Minimum egress width: 0.3 inches per occupant for stairways, 0.2 inches per occupant for other egress components. With sprinklers: 0.2 and 0.15 inches respectively.',
    chapter: 'Chapter 10 — Means of Egress',
    keywords: ['egress width', 'occupant load', 'stairway width'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1010.1',
    title: 'Doors',
    summary:
        'Egress doors: minimum 32" clear width, 80" height. Side-hinged swinging doors required for occupant loads of 50 or more. Hardware operable without key, special knowledge, or effort.',
    chapter: 'Chapter 10 — Means of Egress',
    keywords: ['door', 'egress door', 'panic hardware', 'width'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1011.5',
    title: 'Stairway Width and Capacity',
    summary:
        'Stairways: minimum 44" wide when serving occupant load of 50 or more, 36" otherwise. Handrails may project 4.5" each side. Risers: max 7", treads: min 11".',
    chapter: 'Chapter 10 — Means of Egress',
    keywords: ['stairway', 'riser', 'tread', 'handrail', 'width'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1013.1',
    title: 'Guards',
    summary:
        'Guards required along open-sided walking surfaces, including mezzanines, stairs, ramps, and landings located more than 30 inches above the floor below. Minimum 42" height.',
    chapter: 'Chapter 10 — Means of Egress',
    keywords: ['guard', 'guardrail', 'railing', '42 inches', 'fall protection'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1705.3',
    title: 'Statement of Special Inspections',
    summary:
        'The registered design professional shall prepare a statement of special inspections listing: special inspections required, type and extent, identity of special inspectors.',
    chapter: 'Chapter 17 — Special Inspections and Tests',
    keywords: ['special inspection', 'structural', 'testing', 'third party'],
    tradeRelevance: 'Inspector, Structural',
  ),
  CodeSection(
    body: CodeBody.ibc,
    article: '1809.1',
    title: 'Foundation Design',
    summary:
        'Footings and foundations shall be designed and constructed in accordance with Sections 1809 through 1810. Minimum depth: 12" below undisturbed ground surface.',
    chapter: 'Chapter 18 — Soils and Foundations',
    keywords: ['foundation', 'footing', 'depth', 'bearing capacity'],
    tradeRelevance: 'General Contractor, Concrete, Inspector',
  ),
];

// ── IRC (International Residential Code) ───────────────────
const _ircSections = <CodeSection>[
  CodeSection(
    body: CodeBody.irc,
    article: 'R301.2',
    title: 'Climatic and Geographic Design Criteria',
    summary:
        'Building design criteria based on local conditions: ground snow load, wind speed, seismic design category, frost line depth, termite probability.',
    chapter: 'Chapter 3 — Building Planning',
    keywords: ['wind speed', 'snow load', 'seismic', 'frost line'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R311.7',
    title: 'Stairways',
    summary:
        'Residential stairways: minimum 36" width, max riser 7-3/4", min tread 10", max variation 3/8" between largest and smallest riser/tread. Headroom: 6\'-8" minimum.',
    chapter: 'Chapter 3 — Building Planning',
    keywords: ['stairs', 'riser', 'tread', 'headroom', 'residential'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R312.1',
    title: 'Guards — Where Required',
    summary:
        'Guards required on open sides of walking surfaces > 30" above grade. Guard height: 36" min at residential stairs and landings, 42" elsewhere.',
    chapter: 'Chapter 3 — Building Planning',
    keywords: ['guard', 'railing', 'deck', 'balcony', '36 inches'],
    tradeRelevance: 'General Contractor, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R403.1',
    title: 'Footings — General',
    summary:
        'Footings shall be minimum 12" wide for 1-story, 15" for 2-story, 18" for 3-story (conventional wood frame). Thickness min 6". Placed on undisturbed soil below frost line.',
    chapter: 'Chapter 4 — Foundations',
    keywords: ['footing', 'width', 'depth', 'frost line', 'foundation'],
    tradeRelevance: 'General Contractor, Concrete, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R404.1',
    title: 'Foundation Walls — Concrete',
    summary:
        'Concrete foundation walls: min 6" thick for 1-story, 8" for 2 or 3-story. Reinforcement per design tables. Minimum 2500 psi concrete. Damp-proofing required.',
    chapter: 'Chapter 4 — Foundations',
    keywords: ['foundation wall', 'concrete', 'thickness', 'reinforcement'],
    tradeRelevance: 'General Contractor, Concrete, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R502.3',
    title: 'Floor Joist Allowable Spans',
    summary:
        'Floor joist spans determined by species, grade, spacing, and dead/live loads. Span tables in R502.3.1 for sleeping areas (30 psf) and living areas (40 psf).',
    chapter: 'Chapter 5 — Floors',
    keywords: ['joist', 'span', 'floor', 'lumber', 'spacing'],
    tradeRelevance: 'General Contractor, Framing, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R602.3',
    title: 'Design and Construction of Wall Framing',
    summary:
        'Studs: 2x4 min for 1-story bearing walls, 2x6 for 3-story. Max spacing: 24" OC for nonbearing, 16" OC for bearing. Headers required at all openings.',
    chapter: 'Chapter 6 — Wall Construction',
    keywords: ['stud', 'framing', 'header', 'bearing wall', 'spacing'],
    tradeRelevance: 'General Contractor, Framing, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R703.2',
    title: 'Weather-Resistive Barrier',
    summary:
        'One layer of No. 15 felt or equivalent WRB required behind exterior veneer. Properly lapped: upper over lower, min 2" horizontal, 6" vertical.',
    chapter: 'Chapter 7 — Wall Covering',
    keywords: ['house wrap', 'weather barrier', 'felt', 'Tyvek', 'moisture'],
    tradeRelevance: 'General Contractor, Siding, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R802.4',
    title: 'Allowable Rafter Spans',
    summary:
        'Rafter spans determined by species, grade, spacing, roof live load, and duration factor. Collar ties or ridge straps required in upper third of attic space.',
    chapter: 'Chapter 8 — Roof-Ceiling Construction',
    keywords: ['rafter', 'span', 'roof', 'collar tie', 'ridge'],
    tradeRelevance: 'General Contractor, Framing, Roofing, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'R905.2',
    title: 'Asphalt Shingles',
    summary:
        'Asphalt shingles: min slope 2:12 (with double underlayment for 2:12 to 4:12). Ice barrier required in areas with average daily January temp of 25F or less, from eave to 24" inside exterior wall line.',
    chapter: 'Chapter 9 — Roof Assemblies',
    keywords: ['shingles', 'roof slope', 'ice barrier', 'underlayment'],
    tradeRelevance: 'Roofing, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'N1102.4',
    title: 'Air Leakage',
    summary:
        'Building thermal envelope shall be tested with blower door test. Max 3 ACH50 for Climate Zones 3-8, max 5 ACH50 for Climate Zones 1-2.',
    chapter: 'Chapter 11 — Energy Efficiency',
    keywords: ['blower door', 'air leakage', 'ACH50', 'energy', 'insulation'],
    tradeRelevance: 'HVAC, Insulation, Inspector',
  ),
  CodeSection(
    body: CodeBody.irc,
    article: 'P2603.6',
    title: 'Freezing Protection',
    summary:
        'Water, soil, and waste pipes shall not be installed outside of a building, in exterior walls, attics, or crawl spaces where subject to freezing unless protected.',
    chapter: 'Chapter 26 — General Plumbing Requirements',
    keywords: ['pipe freezing', 'insulation', 'exterior wall', 'plumbing protection'],
    tradeRelevance: 'Plumbing, Inspector',
  ),
];

// ── OSHA (29 CFR 1926 — Construction Standards) ────────────
const _oshaSections = <CodeSection>[
  CodeSection(
    body: CodeBody.osha,
    article: '1926.20',
    title: 'General Safety and Health Provisions',
    summary:
        'Employers shall initiate and maintain programs for frequent and regular inspection of job sites, materials, and equipment. Accident prevention program required.',
    chapter: 'Subpart C — General Safety and Health',
    keywords: ['safety program', 'inspection', 'accident prevention'],
    tradeRelevance: 'All Trades',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.28',
    title: 'Personal Protective Equipment',
    summary:
        'Employer responsible for requiring the wearing of appropriate PPE in all operations where there is an exposure to hazardous conditions.',
    chapter: 'Subpart C — General Safety and Health',
    keywords: ['PPE', 'hard hat', 'safety glasses', 'protection'],
    tradeRelevance: 'All Trades',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.100',
    title: 'Head Protection',
    summary:
        'Employees working in areas where there is danger of head injury from impact, falling objects, or electrical shock shall be protected by protective helmets.',
    chapter: 'Subpart E — Personal Protective and Life Saving Equipment',
    keywords: ['hard hat', 'helmet', 'head protection', 'impact'],
    tradeRelevance: 'All Trades',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.451',
    title: 'Scaffolding — General Requirements',
    summary:
        'Each scaffold and scaffold component shall support its own weight plus 4x the maximum intended load without failure. Planking: min 2x10 scaffold grade. Guardrails required at 10 ft or more.',
    chapter: 'Subpart L — Scaffolds',
    keywords: ['scaffold', 'guardrail', 'planking', 'fall protection'],
    tradeRelevance: 'General Contractor, Painter, Mason, Inspector',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.501',
    title: 'Fall Protection — Duty to Have Fall Protection',
    summary:
        'Each employee on a walking/working surface with an unprotected side or edge 6 ft or more above a lower level shall be protected by guardrails, safety nets, or personal fall arrest systems.',
    chapter: 'Subpart M — Fall Protection',
    keywords: ['fall protection', '6 feet', 'guardrail', 'harness', 'safety net'],
    tradeRelevance: 'All Trades, Roofing, Steel',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.502',
    title: 'Fall Protection Systems Criteria',
    summary:
        'Guardrail systems: top rail 42" ± 3". Midrail at 21". Personal fall arrest: max arresting force 1,800 lbs. Max deceleration distance 3.5 ft. Total fall distance + deceleration must not contact lower level.',
    chapter: 'Subpart M — Fall Protection',
    keywords: ['guardrail height', 'harness', 'lanyard', 'deceleration'],
    tradeRelevance: 'All Trades, Roofing, Steel',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.550',
    title: 'Cranes and Derricks',
    summary:
        'Annual inspection by competent person required. Load charts must be posted. No hoisting of personnel except in approved personnel platforms. Outriggers fully extended.',
    chapter: 'Subpart N — Cranes, Derricks, Hoists, Elevators, and Conveyors',
    keywords: ['crane', 'derrick', 'hoist', 'load chart', 'inspection'],
    tradeRelevance: 'General Contractor, Steel, Inspector',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.602',
    title: 'Material Handling Equipment',
    summary:
        'Earthmoving equipment: ROPS required, seatbelts required when ROPS installed. Vehicles with obstructed rear view: backup alarm audible above surrounding noise level.',
    chapter: 'Subpart O — Motor Vehicles',
    keywords: ['ROPS', 'seatbelt', 'backup alarm', 'earthmoving'],
    tradeRelevance: 'General Contractor, Excavation',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.651',
    title: 'Excavations — Specific Requirements',
    summary:
        'Excavations 5 ft or deeper require protective system (sloping, shoring, or shielding) unless excavation is entirely in stable rock. Competent person required. Spoil piles 2 ft from edge.',
    chapter: 'Subpart P — Excavations',
    keywords: ['excavation', 'trench', 'shoring', 'sloping', 'cave-in'],
    tradeRelevance: 'General Contractor, Excavation, Plumbing, Inspector',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.652',
    title: 'Protective Systems for Excavations',
    summary:
        'Soil classifications: Type A (cohesive, 1.5 tsf), Type B (medium, 0.5 tsf), Type C (granular, 0.5 tsf). Sloping angles: Type A = 3/4:1, Type B = 1:1, Type C = 1-1/2:1.',
    chapter: 'Subpart P — Excavations',
    keywords: ['soil type', 'sloping', 'benching', 'shielding', 'trench box'],
    tradeRelevance: 'General Contractor, Excavation, Inspector',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.1053',
    title: 'Ladders',
    summary:
        'Portable ladders: extend 3 ft above landing surface. Non-self-supporting ladders at 75.5° angle (4:1 ratio). Max load per manufacturer rating. Inspect before each use.',
    chapter: 'Subpart X — Stairways and Ladders',
    keywords: ['ladder', '3 foot extension', '4 to 1 ratio', 'angle'],
    tradeRelevance: 'All Trades',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.1101',
    title: 'Asbestos',
    summary:
        'PEL: 0.1 f/cc as 8-hour TWA. Building/facility owner shall notify employers of known or presumed ACM/PACM locations before work begins. Abatement by licensed contractors only.',
    chapter: 'Subpart Z — Toxic and Hazardous Substances',
    keywords: ['asbestos', 'ACM', 'abatement', 'PEL', 'exposure'],
    tradeRelevance: 'General Contractor, Demolition, Inspector',
  ),
  CodeSection(
    body: CodeBody.osha,
    article: '1926.1153',
    title: 'Respirable Crystalline Silica',
    summary:
        'PEL: 50 µg/m³ as 8-hour TWA. Table 1 provides exposure control methods for 18 common construction tasks (cutting, grinding, drilling concrete/stone). Respirator required above action level.',
    chapter: 'Subpart Z — Toxic and Hazardous Substances',
    keywords: ['silica', 'dust', 'concrete cutting', 'respirator', 'Table 1'],
    tradeRelevance: 'General Contractor, Concrete, Mason, Inspector',
  ),
];

// ── NFPA (National Fire Protection Association) ────────────
const _nfpaSections = <CodeSection>[
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 1 — 1.1',
    title: 'Fire Code — Scope',
    summary:
        'Prescribes minimum requirements for fire prevention safeguards. Applies to existing and new buildings, structures, and premises. Covers fire protection systems, means of egress, hazardous materials.',
    chapter: 'NFPA 1 — Fire Code',
    keywords: ['fire code', 'prevention', 'safeguard', 'existing building'],
    tradeRelevance: 'Fire Protection, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 13 — 8.15',
    title: 'Sprinkler System Spacing',
    summary:
        'Standard spray sprinklers: max coverage area 225 sq ft for light hazard, 130 sq ft for ordinary hazard. Max spacing 15 ft between heads (light hazard). Min 6 ft between heads.',
    chapter: 'NFPA 13 — Standard for Sprinkler Systems',
    keywords: ['sprinkler', 'spacing', 'coverage', 'light hazard', 'ordinary hazard'],
    tradeRelevance: 'Fire Protection, Plumbing, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 13D — 8.1',
    title: 'Residential Sprinkler Systems',
    summary:
        'Sprinklers required in: all habitable rooms. Not required in: bathrooms <55 sq ft, closets where walls/ceilings are noncombustible, garages, open attached porches, attics.',
    chapter: 'NFPA 13D — Sprinkler Systems for 1- and 2-Family Dwellings',
    keywords: ['residential sprinkler', 'dwelling', 'coverage', 'exemption'],
    tradeRelevance: 'Fire Protection, Plumbing, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 25 — 5.1',
    title: 'Inspection, Testing, and Maintenance of Sprinkler Systems',
    summary:
        'Sprinkler systems: visual inspection weekly/monthly/quarterly/annually. Flow test annually. Internal pipe inspection every 5 years. 50-year sprinkler head replacement.',
    chapter: 'NFPA 25 — Inspection, Testing, and Maintenance',
    keywords: ['ITM', 'inspection', 'testing', 'maintenance', 'sprinkler'],
    tradeRelevance: 'Fire Protection, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 72 — 17.6',
    title: 'Fire Alarm Notification Appliance Placement',
    summary:
        'Visual (strobe) notification: candela rating per room size. Max mounting height: 96" AFF for wall-mounted. Audible: min 15 dBA above ambient or 5 dBA above max sound level (whichever is greater).',
    chapter: 'NFPA 72 — National Fire Alarm and Signaling Code',
    keywords: ['fire alarm', 'strobe', 'notification', 'candela', 'horn'],
    tradeRelevance: 'Fire Protection, Electrical, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 72 — 29.8',
    title: 'Smoke Alarm Placement',
    summary:
        'Smoke alarms required: each bedroom, outside each sleeping area, each story. Wall-mounted: 4-12" from ceiling. Ceiling-mounted: min 4" from wall. Interconnected.',
    chapter: 'NFPA 72 — National Fire Alarm and Signaling Code',
    keywords: ['smoke alarm', 'detector', 'bedroom', 'placement', 'interconnected'],
    tradeRelevance: 'Electrical, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 101 — 7.1',
    title: 'Life Safety Code — Means of Egress',
    summary:
        'Means of egress: continuous and unobstructed path of travel from any occupied point to a public way. Three components: exit access, exit, exit discharge.',
    chapter: 'NFPA 101 — Life Safety Code',
    keywords: ['egress', 'exit', 'life safety', 'evacuation', 'path of travel'],
    tradeRelevance: 'General Contractor, Fire Protection, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 101 — 7.7',
    title: 'Exit Signs and Emergency Lighting',
    summary:
        'Exit signs at each exit and exit access door. Letters min 6" high, 3/4" stroke. Emergency lighting: min 1 foot-candle average, 0.1 foot-candle minimum, 90-minute battery backup.',
    chapter: 'NFPA 101 — Life Safety Code',
    keywords: ['exit sign', 'emergency lighting', 'battery backup', 'illumination'],
    tradeRelevance: 'Electrical, Fire Protection, Inspector',
  ),
  CodeSection(
    body: CodeBody.nfpa,
    article: 'NFPA 110 — 8.3',
    title: 'Emergency Generator Testing',
    summary:
        'Emergency generators: monthly test under load for min 30 minutes. Annual 4-hour load test at 100% rated load. Transfer switch exercised monthly.',
    chapter: 'NFPA 110 — Emergency and Standby Power Systems',
    keywords: ['generator', 'emergency power', 'load test', 'transfer switch'],
    tradeRelevance: 'Electrical, Inspector',
  ),
];

/// All code sections combined — the complete searchable database.
final allCodeSections = <CodeSection>[
  ..._necSections,
  ..._ibcSections,
  ..._ircSections,
  ..._oshaSections,
  ..._nfpaSections,
];

/// Get sections filtered by code body.
List<CodeSection> sectionsByBody(CodeBody body) =>
    allCodeSections.where((s) => s.body == body).toList();

/// Search across all code sections.
List<CodeSection> searchCodeSections(String query) {
  if (query.trim().isEmpty) return allCodeSections;
  final q = query.toLowerCase();
  final terms = q.split(RegExp(r'\s+'));
  return allCodeSections.where((s) {
    final text = s.searchText;
    return terms.every((term) => text.contains(term));
  }).toList();
}
