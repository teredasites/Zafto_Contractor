/**
 * OFFICIAL IICRC S500 & S520 PROTOCOL DATA
 * ==========================================
 * Based on ANSI/IICRC S500-2021 Standard for Professional Water Damage Restoration
 * and ANSI/IICRC S520-2024 Standard for Professional Mold Remediation (4th Edition).
 *
 * Sources:
 *   - IICRC S500-2021 (iicrc.org/s500)
 *   - IICRC S520-2024 (iicrc.org/s520)
 *   - IICRC Approved Calculation Sheets (iicrc.org/approved-calculations-sheets)
 *   - USDA Wood Handbook (Chapter 13 — Drying & Control of Moisture)
 *
 * NOTE: This file provides the PUBLICLY AVAILABLE framework, classification
 * systems, equipment formulas, and drying standards. The full IICRC standards
 * documents are copyrighted and must be purchased from IICRC for complete text.
 * This data is sufficient for a restoration CRM to guide technicians through
 * proper classification, documentation, and equipment placement.
 */

// ─────────────────────────────────────────────────────────────────────
// S500 — WATER DAMAGE CATEGORIES (contamination level)
// ─────────────────────────────────────────────────────────────────────

export interface WaterCategory {
  category: 1 | 2 | 3;
  name: string;
  description: string;
  sources: string[];
  healthRisk: 'low' | 'moderate' | 'significant';
  ppeRequired: string[];
  specialProcedures: string[];
  timeBasedEscalation: string;
  examplesOfDamage: string[];
}

export const WATER_CATEGORIES: WaterCategory[] = [
  {
    category: 1,
    name: 'Clean Water',
    description:
      'Water originating from a sanitary source that does not pose substantial risk from dermal, ingestion, or inhalation exposure. May deteriorate to Category 2 or 3 if left untreated.',
    sources: [
      'Broken water supply lines',
      'Tub or sink overflows (with no contaminants)',
      'Appliance malfunctions involving water supply lines',
      'Melting ice or snow',
      'Falling rainwater (clean)',
      'Broken toilet tanks (clean water, no urine/feces)',
    ],
    healthRisk: 'low',
    ppeRequired: ['Gloves', 'Eye protection'],
    specialProcedures: [
      'Standard extraction and drying procedures',
      'Antimicrobial application per manufacturer guidelines',
    ],
    timeBasedEscalation:
      'Category 1 can degrade to Category 2 within 24–48 hours if not treated, depending on temperature, time, and organic material present.',
    examplesOfDamage: [
      'Wet carpet and pad in a single room from a supply line break',
      'Overflow from a clean bathtub',
    ],
  },
  {
    category: 2,
    name: 'Gray Water',
    description:
      'Water containing significant contamination that has the potential to cause discomfort or illness if contacted or consumed. Contains microorganisms and/or nutrients for microorganisms. May contain chemical, biological, or physical contaminants.',
    sources: [
      'Discharge from dishwashers or washing machines',
      'Overflow from toilet bowls with urine (no feces)',
      'Sump pump failures',
      'Seepage due to hydrostatic pressure',
      'Aquarium water',
      'Punctured water beds',
      'Broken aquariums',
    ],
    healthRisk: 'moderate',
    ppeRequired: [
      'Gloves (nitrile or rubber)',
      'Eye protection (safety glasses or goggles)',
      'Protective clothing',
      'N95 respirator (if aerosols present)',
    ],
    specialProcedures: [
      'Remove and discard porous materials that cannot be properly cleaned',
      'Clean and treat affected hard surfaces with antimicrobial',
      'Carpet padding/cushion must be removed and discarded',
      'Carpet may be saved if properly cleaned and treated within 24 hours',
    ],
    timeBasedEscalation:
      'Category 2 can escalate to Category 3 within 48–72 hours. Warmer temperatures accelerate degradation.',
    examplesOfDamage: [
      'Washing machine overflow that reaches carpet and walls',
      'Toilet overflow containing urine',
    ],
  },
  {
    category: 3,
    name: 'Black Water',
    description:
      'Water that is grossly contaminated and may contain pathogenic, toxigenic, or other harmful agents. Can cause significant adverse reactions in humans if contacted or consumed. Includes all forms of flooding from seawater, ground surface water, rising water from rivers or streams, and sewage.',
    sources: [
      'Sewage backup',
      'All flooding from rivers, streams, or tidal sources',
      'Ground surface water entering structure',
      'Wind-driven rain from hurricanes or tropical storms',
      'Toilet backflow originating from beyond the trap (with feces)',
      'Category 1 or 2 water that has been untreated for extended periods',
    ],
    healthRisk: 'significant',
    ppeRequired: [
      'Gloves (heavy-duty nitrile or rubber)',
      'Full-face respirator or powered air-purifying respirator (PAPR)',
      'Full body protective suit (Tyvek or equivalent)',
      'Rubber boots',
      'Eye protection (splash goggles)',
    ],
    specialProcedures: [
      'All porous materials contacted by Category 3 water must be removed and discarded',
      'Structural materials must be cleaned, treated, and dried',
      'Antimicrobial treatment is mandatory on all affected surfaces',
      'Air scrubbing with HEPA filtration during demolition/removal',
      'Containment may be required to prevent cross-contamination',
      'Post-remediation clearance testing recommended',
    ],
    timeBasedEscalation:
      'Category 3 requires immediate response. Microbial amplification begins within hours. Every hour of delay increases scope and cost.',
    examplesOfDamage: [
      'Sewage backup flooding a basement',
      'River flooding entering a home',
      'Hurricane storm surge damage',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S500 — WATER DAMAGE CLASSES (evaporation/absorption load)
// ─────────────────────────────────────────────────────────────────────

export interface WaterClass {
  class: 1 | 2 | 3 | 4;
  name: string;
  description: string;
  affectedArea: string;
  typicalMaterials: string[];
  dryingDifficulty: 'least' | 'moderate' | 'significant' | 'specialty';
  equipmentGuidelines: EquipmentGuideline;
  dryingNotes: string[];
}

export interface EquipmentGuideline {
  airMoversPerLinearFt: string;
  airMoversPerSqFt: string;
  dehumidificationFactor: string;
  dehumidificationFormula: string;
  specialNotes: string[];
}

export const WATER_CLASSES: WaterClass[] = [
  {
    class: 1,
    name: 'Least Amount of Water — Slow Evaporation Rate',
    description:
      'Water losses that affect only part of a room or area, or losses with lower permeance/porosity materials where minimal moisture is absorbed. Little or no wet carpet and/or carpet cushion is present.',
    affectedArea: 'Less than 5% of combined surface area (walls, floors, ceiling) in a room',
    typicalMaterials: [
      'Plywood subfloor (small area)',
      'Concrete slab (minimal penetration)',
      'Part of one room affected',
    ],
    dryingDifficulty: 'least',
    equipmentGuidelines: {
      airMoversPerLinearFt: '1 air mover per 10–16 linear feet of affected wall',
      airMoversPerSqFt: '1 air mover per 50–70 sq ft of affected floor area',
      dehumidificationFactor: 'Class 1: higher chart factor (less dehumidification needed)',
      dehumidificationFormula:
        'Cubic footage ÷ chart factor = total PPD needed ÷ dehumidifier AHAM rating = number of units',
      specialNotes: [
        'Minimal equipment typically needed',
        'May dry naturally with good air circulation in some cases',
        'Monitor to ensure drying progresses and no mold growth occurs',
      ],
    },
    dryingNotes: [
      'Least complex drying scenario',
      'Standard air movers and dehumidification sufficient',
      'Typical drying time: 1–3 days depending on materials',
    ],
  },
  {
    class: 2,
    name: 'Large Amount of Water — Fast Evaporation Rate',
    description:
      'Water losses affecting an entire room of carpet and carpet cushion. Water has wicked up walls no more than 24 inches high. Moisture remains in structural materials.',
    affectedArea: '5–40% of combined surface area, or entire room of carpet/cushion with wall wicking up to 24 inches',
    typicalMaterials: [
      'Full room of carpet and cushion',
      'Walls with water wicking up to 24 inches',
      'Plywood subflooring (moderate saturation)',
      'Concrete block walls (partial absorption)',
    ],
    dryingDifficulty: 'moderate',
    equipmentGuidelines: {
      airMoversPerLinearFt: '1 air mover per 10–16 linear feet of affected wall',
      airMoversPerSqFt: '1 air mover per 50–70 sq ft of affected floor area',
      dehumidificationFactor:
        'LGR factor: 50 — e.g., 12,000 cu ft ÷ 50 = 240 pints per day (PPD) at AHAM',
      dehumidificationFormula:
        'Example: 30 ft × 50 ft × 8 ft = 12,000 cf ÷ 50 (LGR/Class 2 factor) = 240 PPD at AHAM. 240 ÷ 140-pint unit = 2 dehumidifiers, or 240 ÷ 65-pint unit = 4 dehumidifiers.',
      specialNotes: [
        'Most common water damage classification',
        'Requires proper containment if adjacent areas are dry',
        'Monitor wall cavity moisture — may need flood cuts at 24 inches',
      ],
    },
    dryingNotes: [
      'Typical drying time: 3–5 days',
      'Wall cavities may require removal of baseboard and drilling weep holes',
      'Carpet cushion is usually removed; carpet may be saved if treated within 24–48 hours',
    ],
  },
  {
    class: 3,
    name: 'Greatest Amount of Water — Fastest Evaporation Rate',
    description:
      'Water may have come from overhead, saturating ceilings, walls, insulation, carpet, cushion, and subflooring in the entire area. Walls are saturated more than 24 inches high.',
    affectedArea: 'More than 40% of combined surface area, including ceiling saturation',
    typicalMaterials: [
      'Fully saturated walls (above 24 inches)',
      'Saturated ceilings and insulation',
      'All flooring materials saturated',
      'Subfloor saturation',
    ],
    dryingDifficulty: 'significant',
    equipmentGuidelines: {
      airMoversPerLinearFt: '1 air mover per 10–16 linear feet of affected wall',
      airMoversPerSqFt:
        '1 air mover per 50–70 sq ft of floor PLUS 1 per 100–150 sq ft of wet ceiling/upper wall',
      dehumidificationFactor: 'Class 3: lower chart factor (more dehumidification needed than Class 2)',
      dehumidificationFormula:
        'Cubic footage ÷ chart factor = total PPD. Use Class 3 factor (lower than 50) for higher moisture load.',
      specialNotes: [
        'Highest volume of water — most equipment needed',
        'Ceiling fans or overhead air movers may be needed',
        'Wall cavities likely require 2-foot flood cuts minimum',
        'Insulation removal usually necessary',
        'May require specialty drying techniques for some materials',
      ],
    },
    dryingNotes: [
      'Typical drying time: 5–7+ days',
      'Ceiling insulation must be removed if wet',
      'Likely requires demolition of wet drywall above 24-inch line',
      'Full room containment and HEPA filtration during demo',
    ],
  },
  {
    class: 4,
    name: 'Specialty Drying Situations',
    description:
      'Involves materials with very low permeance/porosity such as hardwood floors, plaster, brick, concrete, stone, crawlspaces. These materials trap moisture and require longer drying times and specialized methods. Once surface moisture is removed, drying shifts to lower airflow and higher vapor pressure differentials.',
    affectedArea: 'Any amount of deeply absorbed moisture in low-permeance materials',
    typicalMaterials: [
      'Hardwood flooring',
      'Plaster walls',
      'Concrete (deep saturation)',
      'Brick and stone',
      'Crawlspace wood framing',
      'Gypcrete subfloors',
      'Lightweight concrete',
    ],
    dryingDifficulty: 'specialty',
    equipmentGuidelines: {
      airMoversPerLinearFt: 'Reduce airflow after surface moisture removed — avoid case hardening',
      airMoversPerSqFt: 'Standard formulas do NOT apply — use specialty techniques',
      dehumidificationFactor:
        'Standard chart factors do not apply — use desiccant dehumidifiers or heat drying systems',
      dehumidificationFormula:
        'Class 4 requires specialty equipment: desiccant dehumidifiers, heat drying mats, injection drying systems, or controlled demolition approaches.',
      specialNotes: [
        'Standard LGR dehumidifiers may not be sufficient alone',
        'Desiccant dehumidifiers increase vapor pressure differential',
        'Heat drying mats can accelerate hardwood and concrete drying',
        'Injection drying systems may be needed for wall cavities',
        'Risk of case hardening — surface dries while core remains wet',
        'Cupping and crowning risk on hardwood if dried too fast or unevenly',
      ],
    },
    dryingNotes: [
      'Typical drying time: 7–14+ days',
      'Hardwood floors may require tenting with desiccant supply',
      'Concrete slabs may require extended drying with calcium chloride tests',
      'Monitor daily — adjust equipment based on moisture trending',
      'Document with moisture mapping at multiple points',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S500 — DRYING STANDARDS & MOISTURE TARGETS
// ─────────────────────────────────────────────────────────────────────

export interface DryingStandard {
  material: string;
  targetMoistureContent: string;
  maxAcceptable: string;
  measurementMethod: string;
  notes: string[];
  source: string;
}

export const DRYING_STANDARDS: DryingStandard[] = [
  {
    material: 'Softwood Framing (studs, joists, rafters)',
    targetMoistureContent: '15% MC or within 4 percentage points of pre-loss EMC',
    maxAcceptable: '19% MC — must not exceed this threshold',
    measurementMethod:
      'Pin-type moisture meter, pins inserted to full depth (~5/16 inch). Record meter brand, model, and material setting.',
    notes: [
      'At 70°F and 50% RH, softwood EMC is approximately 9.2%',
      'Acceptable dry standard: within 10% of pre-loss EMC of similar unaffected materials',
      'Must be below 16% MC before installing new drywall (per S500-2021)',
      'Wood above 20% MC can support microbial growth',
      'Never leave material at an EMC that supports microbial growth regardless of other targets',
    ],
    source: 'IICRC S500-2021; USDA Wood Handbook Chapter 13',
  },
  {
    material: 'Hardwood Flooring',
    targetMoistureContent: 'Within 2–4 percentage points of pre-loss EMC or adjacent dry areas',
    maxAcceptable: 'Must not exceed 14% MC for most species in conditioned spaces',
    measurementMethod:
      'Pin-type moisture meter with species correction. Measure at multiple points across the floor. Compare to unaffected areas of same flooring.',
    notes: [
      'Drying too fast causes cupping (edges higher than center)',
      'Drying too slow allows crowning (center higher than edges)',
      'Weight systems or tenting with controlled desiccant supply may be needed',
      'Document with moisture mapping grid — minimum 1 reading per 100 sq ft',
      'Allow 30–60 days for final equalization before refinishing',
    ],
    source: 'IICRC S500-2021; National Wood Flooring Association (NWFA)',
  },
  {
    material: 'Drywall / Gypsum Board',
    targetMoistureContent: 'Equivalent to unaffected drywall in the same structure (comparative reading)',
    maxAcceptable: 'No universal numerical standard — use comparative baseline',
    measurementMethod:
      'Non-penetrating (pinless) moisture meter OR pin-type meter. CRITICAL: Most meters are NOT calibrated for drywall — readings are relative, not absolute. Always record meter type, brand, and model.',
    notes: [
      'Compare wet readings to known-dry readings on similar material in the structure',
      'Drywall with paper backing can support mold growth at lower moisture levels than wood',
      'Drywall exposed to Category 3 water must be removed — cannot be dried in place',
      'Drywall with visible mold growth must be removed',
      'Water-resistant (green board) and mold-resistant (purple board) have different thresholds',
    ],
    source: 'IICRC S500-2021',
  },
  {
    material: 'Concrete',
    targetMoistureContent: 'Comparative — match unaffected concrete in same structure',
    maxAcceptable: 'Below 75% RH at slab surface (per ASTM F2170 in-situ probe test) for flooring installation',
    measurementMethod:
      'Calcium chloride test (ASTM F1869) — measures moisture vapor emission rate (MVER). In-situ relative humidity probe test (ASTM F2170) — measures RH% within the slab. Pin meters give surface readings only.',
    notes: [
      'Concrete can hold moisture deep within the slab for weeks or months',
      'Standard drying equipment may not penetrate deep enough — use desiccant systems',
      'Flooring manufacturers require specific MVER or RH% before installation',
      'Typical MVER requirement: 3–5 lbs per 1,000 sq ft per 24 hours',
      'New concrete requires 28–90+ days to cure to acceptable moisture levels',
    ],
    source: 'IICRC S500-2021; ASTM F1869; ASTM F2170',
  },
  {
    material: 'Carpet & Carpet Cushion (Pad)',
    targetMoistureContent: 'Dry to touch and matching ambient conditions',
    maxAcceptable: 'No microbial growth; no odor; visually dry',
    measurementMethod:
      'Pinless moisture meter on surface. Lift carpet to check cushion separately. Check tack strip area and subfloor beneath.',
    notes: [
      'Carpet cushion (pad) must be removed and discarded for Category 2 and 3 water',
      'Carpet itself may be saved for Category 1 if cleaned and dried within 24–48 hours',
      'Category 3: all carpet AND cushion must be removed and discarded',
      'Delamination of carpet backing indicates non-restorable condition',
      'Check subfloor moisture separately — carpet may feel dry while subfloor is still wet',
    ],
    source: 'IICRC S500-2021',
  },
  {
    material: 'Plaster Walls',
    targetMoistureContent: 'Comparative to unaffected plaster in same structure',
    maxAcceptable: 'No universal numerical standard — use comparative baseline',
    measurementMethod:
      'Non-penetrating meter for screening, pin-type for confirmation. Meters NOT calibrated for plaster — readings are comparative only.',
    notes: [
      'Class 4 material — requires specialty drying techniques',
      'Drying too fast can cause cracking',
      'May require extended drying time (7–14+ days)',
      'Heat drying can accelerate but must be carefully controlled',
      'Older plaster may contain asbestos — test before disturbing',
    ],
    source: 'IICRC S500-2021',
  },
];

// ─────────────────────────────────────────────────────────────────────
// S500 — AIR MOVER PLACEMENT FORMULAS (IICRC Approved Calculations)
// ─────────────────────────────────────────────────────────────────────

export interface AirMoverFormula {
  scenario: string;
  formula: string;
  example: string;
  notes: string[];
}

export const AIR_MOVER_FORMULAS: AirMoverFormula[] = [
  {
    scenario: 'Floor coverage (wet flooring)',
    formula: '1 air mover per 50–70 sq ft of affected wet floor area',
    example:
      'A 12×15 ft room (180 sq ft) with fully wet floor: 180 ÷ 50 = 3.6 → 4 air movers (high estimate), or 180 ÷ 70 = 2.6 → 3 air movers (low estimate)',
    notes: [
      'Start with one air mover in each affected room as baseline',
      'Point air movers in the same direction throughout the space',
      'Deliver air at an angle of 5–45 degrees along affected surfaces',
    ],
  },
  {
    scenario: 'Wall coverage (lower wall, up to 2 feet)',
    formula: '1 air mover per 10–16 linear feet of affected wall',
    example:
      'A 12×12 ft room (48 linear feet of wall): 48 ÷ 10 = 4.8 → 5 air movers (high estimate), or 48 ÷ 16 = 3 air movers (low estimate)',
    notes: [
      'Position air movers to deliver air along the lower portion of the wall and edge of floor',
      'Space air movers every 10–15 feet, or at every offset in the wall',
    ],
  },
  {
    scenario: 'Ceiling and upper wall coverage (above 2 feet)',
    formula: '1 air mover per 100–150 sq ft of affected ceiling or upper wall area',
    example:
      'A 20×25 ft room with saturated ceiling (500 sq ft): 500 ÷ 100 = 5 air movers (high estimate), or 500 ÷ 150 = 3.3 → 4 air movers (low estimate)',
    notes: [
      'Axial fans pointed upward or high-velocity air movers aimed at ceiling',
      'Consider ceiling fans to supplement air circulation',
      'Wet ceiling insulation usually must be removed before drying',
    ],
  },
  {
    scenario: 'Wall insets and offsets',
    formula: 'Add 1 additional air mover for each wall inset or offset greater than 18 inches',
    example:
      'Room with 2 closet insets: add 2 additional air movers beyond the base calculation',
    notes: [
      'Insets and offsets disrupt airflow patterns',
      'Position supplemental air mover to direct air into the inset/offset area',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S500 — DEHUMIDIFICATION FORMULA (IICRC Approved Calculations)
// ─────────────────────────────────────────────────────────────────────

export interface DehumidificationFormula {
  step: number;
  description: string;
  formula: string;
  notes: string[];
}

export const DEHUMIDIFICATION_FORMULA: DehumidificationFormula[] = [
  {
    step: 1,
    description: 'Calculate cubic footage of affected space',
    formula: 'Length (ft) × Width (ft) × Height (ft) = Cubic Footage (CF)',
    notes: ['Measure the entire affected area, including adjacent rooms if air flows freely between them'],
  },
  {
    step: 2,
    description: 'Divide by the chart factor for the water damage class',
    formula: 'Cubic Footage ÷ Chart Factor = Total Pints Per Day (PPD) needed at AHAM rating',
    notes: [
      'LGR Chart Factors (approximate): Class 1 = higher factor (less dehu needed), Class 2 = 50, Class 3 = lower factor (more dehu needed)',
      'Conventional dehumidifiers use different chart factors than LGR units',
      'IICRC provides approved calculation worksheets at iicrc.org/approved-calculations-sheets',
    ],
  },
  {
    step: 3,
    description: 'Divide PPD by dehumidifier capacity to get number of units',
    formula: 'Total PPD ÷ Dehumidifier AHAM Rating (pints/day) = Number of Dehumidifiers',
    notes: [
      'Example: 240 PPD ÷ 140-pint unit = 1.7 → 2 dehumidifiers',
      'Example: 240 PPD ÷ 65-pint unit = 3.7 → 4 dehumidifiers',
      'Always round up — under-sizing dehumidification extends drying time significantly',
      'AHAM rating is measured at 80°F/60% RH — real-world performance varies',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S500 — DOCUMENTATION REQUIREMENTS
// ─────────────────────────────────────────────────────────────────────

export interface DocumentationRequirement {
  category: string;
  items: string[];
  frequency: string;
}

export const S500_DOCUMENTATION_REQUIREMENTS: DocumentationRequirement[] = [
  {
    category: 'Initial Assessment',
    items: [
      'Source of water loss (identified and documented)',
      'Water category classification (1, 2, or 3) with justification',
      'Water class determination (1, 2, 3, or 4) with affected area measurements',
      'Scope of affected area (room-by-room measurement)',
      'Photographs of all affected areas before any work begins',
      'Initial moisture readings with meter type, brand, model documented',
      'Pre-loss condition assessment (if determinable)',
      'Existing damage or pre-existing conditions noted',
    ],
    frequency: 'Once — at initial assessment before work begins',
  },
  {
    category: 'Daily Monitoring',
    items: [
      'Moisture readings at all monitoring points (same locations each day)',
      'Temperature and relative humidity readings (ambient and in-chamber if applicable)',
      'Equipment operating status (all units running, any failures noted)',
      'Changes to equipment placement or quantity',
      'Visual inspection for microbial growth',
      'Photographs of drying progress (at minimum first day and last day)',
      'Any changes to water category based on elapsed time',
    ],
    frequency: 'Every 24 hours minimum during active drying',
  },
  {
    category: 'Equipment Log',
    items: [
      'Number and type of air movers deployed with serial numbers or asset IDs',
      'Number and type of dehumidifiers deployed with AHAM ratings',
      'Placement diagram or room sketch showing equipment positions',
      'Any specialty equipment (desiccants, heat mats, injection systems)',
      'Equipment additions, removals, or repositioning with dates/times',
    ],
    frequency: 'Updated each time equipment is changed',
  },
  {
    category: 'Final / Completion',
    items: [
      'Final moisture readings at all monitoring points',
      'Comparison to drying goals (target vs. actual)',
      'Comparison to dry standard (pre-loss EMC or unaffected materials)',
      'Final photographs',
      'Completion certificate or drying report',
      'Any materials removed/discarded (itemized list)',
      'Recommendations for reconstruction',
    ],
    frequency: 'Once — when drying goals are met',
  },
];

// ─────────────────────────────────────────────────────────────────────
// S520 — MOLD REMEDIATION CONTAMINATION LEVELS
// ─────────────────────────────────────────────────────────────────────

export interface MoldContainmentLevel {
  level: 1 | 2 | 3;
  name: string;
  affectedArea: string;
  description: string;
  containmentRequirements: string[];
  ppeRequirements: string[];
  airFiltration: string[];
  workerTraining: string;
  oversightRequired: string;
  postRemediationVerification: string[];
}

export const MOLD_CONTAINMENT_LEVELS: MoldContainmentLevel[] = [
  {
    level: 1,
    name: 'Level I — Small Isolated Areas',
    affectedArea: 'Less than 10 square feet (approximately 1 square meter)',
    description:
      'Small, isolated areas of mold contamination. Typical of limited contamination on ceiling tiles, small wall sections, or bathroom areas. Minimal risk of spore dispersal if properly handled.',
    containmentRequirements: [
      'Mist affected area to suppress dust and spore release',
      'Minimal containment — dust suppression methods sufficient',
      'No full containment barrier required',
      'Work area should be unoccupied during remediation',
      'Clean surrounding areas with damp wiping or HEPA vacuuming',
    ],
    ppeRequirements: [
      'N95 respirator (minimum)',
      'Gloves',
      'Eye protection (safety goggles)',
    ],
    airFiltration: [
      'HEPA vacuum for cleanup',
      'Air scrubber recommended but not mandatory',
    ],
    workerTraining: 'Trained in basic mold remediation principles per S520',
    oversightRequired: 'Remediation worker or supervisor with mold remediation training',
    postRemediationVerification: [
      'Visual inspection — no visible mold remaining',
      'HEPA vacuum all surfaces in work area',
      'Damp wipe containment materials before removal',
    ],
  },
  {
    level: 2,
    name: 'Level II — Mid-Size Areas',
    affectedArea: '10 to 30 square feet (approximately 1 to 3 square meters)',
    description:
      'Moderate contamination involving larger wall sections, multiple ceiling tiles, or sections of flooring. Requires more stringent containment to prevent spore spread to unaffected areas.',
    containmentRequirements: [
      'Limited containment using 6-mil polyethylene sheeting',
      'Seal containment with tape to create a barrier between work area and occupied spaces',
      'Maintain containment under negative air pressure (optional at this level but recommended)',
      'Cover supply and return air vents in work area',
      'Seal doors and openings with polyethylene sheeting',
      'Place decontamination area at containment entrance',
    ],
    ppeRequirements: [
      'N95 respirator (minimum) — half-face respirator with P100 cartridges recommended',
      'Disposable protective clothing (Tyvek suit or equivalent)',
      'Gloves (nitrile or rubber)',
      'Eye protection (safety goggles)',
      'Foot coverings or dedicated work shoes',
    ],
    airFiltration: [
      'HEPA air scrubber — operate continuously during work',
      'HEPA vacuum for cleanup of all surfaces',
      'Exhaust air to outdoors or through HEPA filtration',
    ],
    workerTraining: 'Trained in mold remediation per S520 with specific containment procedures',
    oversightRequired: 'Supervisor trained in mold remediation oversight',
    postRemediationVerification: [
      'Visual inspection — no visible mold remaining',
      'HEPA vacuum all surfaces in containment area',
      'Damp wipe all containment barriers before removal',
      'Third-party air sampling recommended',
    ],
  },
  {
    level: 3,
    name: 'Level III — Large Areas / Extensive Contamination',
    affectedArea: 'Greater than 30 square feet (approximately 3+ square meters)',
    description:
      'Large-scale contamination requiring full containment, negative air pressure, and oversight by an environmental health professional. Applies to HVAC system contamination, extensive wall or ceiling contamination, and any situation where containment failure could expose building occupants.',
    containmentRequirements: [
      'Full containment using 6-mil polyethylene sheeting — double layer recommended',
      'Seal ALL penetrations (pipes, conduit, outlets) with polyethylene and tape',
      'Cover supply and return air vents and shut down HVAC serving the area',
      'Establish and maintain negative air pressure in containment area',
      'Minimum -5 Pa (pascals) pressure differential — verify with manometer',
      'Decontamination chamber with clean room at containment entrance',
      'Controlled entry/exit to prevent spore dispersal',
      'Post warning signs at all containment entry points',
      'If HVAC contaminated: isolate and decontaminate system before restarting',
    ],
    ppeRequirements: [
      'Full-face respirator with P100 cartridges or powered air-purifying respirator (PAPR)',
      'Full body protective suit (disposable Tyvek or equivalent)',
      'Gloves (nitrile or rubber, double-gloved recommended)',
      'Eye protection (full seal goggles if not using full-face respirator)',
      'Foot coverings — dedicated boots that remain in containment',
      'All PPE removed in decontamination chamber before exiting',
    ],
    airFiltration: [
      'HEPA air scrubber — minimum 1 unit per 500 sq ft of containment, operating continuously',
      'Negative air machine exhausting to outdoors through HEPA filtration',
      'HEPA vacuum for all surface cleanup',
      'Air scrubbers must remain running 24/7 during remediation and for 24–48 hours after completion',
      'Verify air changes per hour (ACH) — minimum 4 ACH in containment',
    ],
    workerTraining:
      'All workers must be trained in mold remediation per S520, including containment setup, negative air pressure maintenance, and proper PPE use.',
    oversightRequired:
      'Environmental health and safety professional (industrial hygienist, environmental consultant, or similar qualified individual) must oversee the project. This professional designs the remediation plan, performs pre- and post-remediation assessment, and provides clearance testing.',
    postRemediationVerification: [
      'Visual inspection by environmental professional — no visible mold remaining',
      'HEPA vacuum all surfaces in containment area',
      'Damp wipe all containment barriers',
      'Post-remediation air sampling by independent third party',
      'Air clearance criteria: spore counts in remediated area must be comparable to or lower than outdoor control sample',
      'Surface sampling (tape lift or swab) may be required',
      'Written clearance report from environmental professional',
      'Containment not removed until clearance is achieved',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S520 — MOLD REMEDIATION PROCEDURES
// ─────────────────────────────────────────────────────────────────────

export interface MoldRemediationStep {
  stepNumber: number;
  phase: string;
  description: string;
  procedures: string[];
  commonMistakes: string[];
}

export const MOLD_REMEDIATION_STEPS: MoldRemediationStep[] = [
  {
    stepNumber: 1,
    phase: 'Assessment',
    description: 'Identify the source of moisture, determine the extent of mold contamination, and classify the contamination level.',
    procedures: [
      'Identify and document the moisture source — remediation will fail if the moisture source is not corrected',
      'Determine the extent of visible mold growth (measure affected area in square feet)',
      'Check for hidden mold in wall cavities, behind baseboards, under flooring',
      'Classify contamination level (I, II, or III) based on total affected area',
      'Determine if environmental health professional oversight is needed (Level III)',
      'Document all findings with photographs and moisture readings',
      'Develop a written remediation plan before starting work',
    ],
    commonMistakes: [
      'Starting remediation without fixing the moisture source',
      'Underestimating the extent of contamination (check hidden areas)',
      'Not documenting pre-remediation conditions',
    ],
  },
  {
    stepNumber: 2,
    phase: 'Containment Setup',
    description: 'Establish containment appropriate to the contamination level to prevent cross-contamination.',
    procedures: [
      'Select containment level based on contamination assessment',
      'Shut down HVAC system serving the affected area (Level II and III)',
      'Cover supply and return air vents with 6-mil polyethylene',
      'Erect containment barriers using 6-mil polyethylene sheeting',
      'Seal all penetrations, gaps, and openings',
      'Set up negative air pressure (Level III — verify with manometer)',
      'Establish decontamination chamber (Level III)',
      'Start HEPA air scrubbers before any disturbance of contaminated materials',
    ],
    commonMistakes: [
      'Disturbing contaminated materials before containment is established',
      'Not shutting down HVAC — spreads spores through ductwork',
      'Containment not sealed properly — gaps allow spore escape',
    ],
  },
  {
    stepNumber: 3,
    phase: 'Source Removal',
    description: 'Remove contaminated materials that cannot be cleaned. This is the core of mold remediation.',
    procedures: [
      'Mist contaminated materials with water or surfactant solution to suppress spore release',
      'Remove contaminated porous materials (drywall, insulation, carpet, ceiling tiles)',
      'Cut drywall 12–24 inches beyond visible mold growth',
      'Bag contaminated materials in 6-mil polyethylene bags before removing from containment',
      'Double-bag heavily contaminated materials',
      'Transport bags through decontamination chamber, sealed',
      'Non-porous materials (metal, glass, hard plastic) can be cleaned rather than removed',
      'Semi-porous materials (wood studs, concrete) — clean with HEPA vacuum then antimicrobial treatment',
    ],
    commonMistakes: [
      'Not cutting far enough past visible mold (roots extend beyond visible growth)',
      'Removing contaminated materials through occupied spaces without containment',
      'Using fans that spread spores instead of HEPA-filtered air movement',
    ],
  },
  {
    stepNumber: 4,
    phase: 'Cleaning & Treatment',
    description: 'Clean all remaining surfaces within the containment area.',
    procedures: [
      'HEPA vacuum all surfaces — structural framing, subfloor, remaining drywall edges',
      'Damp wipe surfaces with appropriate antimicrobial cleaning solution',
      'Wire brush wood surfaces if surface mold remains after HEPA vacuuming',
      'Apply antimicrobial treatment per manufacturer instructions',
      'Allow surfaces to dry completely',
      'HEPA vacuum again after drying',
      'Clean all non-contaminated items that were inside containment',
    ],
    commonMistakes: [
      'Using bleach as primary mold treatment (bleach does not kill mold on porous surfaces)',
      'Not HEPA vacuuming before wet cleaning (creates mud of spores)',
      'Applying antimicrobial to wet surfaces (reduces effectiveness)',
    ],
  },
  {
    stepNumber: 5,
    phase: 'Post-Remediation Verification',
    description: 'Verify that remediation was successful before removing containment.',
    procedures: [
      'Visual inspection — no visible mold growth on any surface',
      'Moisture readings confirm all materials are at or below acceptable moisture levels',
      'For Level III: independent third-party air sampling required',
      'Air clearance criteria: indoor spore counts ≤ outdoor control sample',
      'Surface sampling may be required per environmental professional',
      'Written clearance report from qualified environmental professional',
      'Do NOT remove containment until clearance criteria are met',
      'Run air scrubbers for 24–48 hours after remediation work is complete, before testing',
    ],
    commonMistakes: [
      'Removing containment before clearance testing',
      'Self-testing instead of using independent third party (Level III)',
      'Not waiting adequate time after work completion before testing',
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// S520 — MATERIALS DECISION MATRIX
// ─────────────────────────────────────────────────────────────────────

export interface MaterialRemediationDecision {
  material: string;
  porosity: 'porous' | 'semi-porous' | 'non-porous';
  canBeRemediated: boolean;
  remediationMethod: string;
  mustRemoveWhen: string[];
}

export const MATERIAL_REMEDIATION_DECISIONS: MaterialRemediationDecision[] = [
  {
    material: 'Drywall / Gypsum Board',
    porosity: 'porous',
    canBeRemediated: false,
    remediationMethod: 'Remove and replace. Cut 12–24 inches beyond visible mold growth.',
    mustRemoveWhen: ['Any visible mold growth on surface or back side', 'Water damage from Category 2 or 3'],
  },
  {
    material: 'Ceiling Tiles',
    porosity: 'porous',
    canBeRemediated: false,
    remediationMethod: 'Remove and replace.',
    mustRemoveWhen: ['Any visible mold growth', 'Staining from water damage'],
  },
  {
    material: 'Fiberglass Insulation',
    porosity: 'porous',
    canBeRemediated: false,
    remediationMethod: 'Remove and replace. Bag before removing from containment.',
    mustRemoveWhen: ['Any moisture intrusion', 'Adjacent to mold-contaminated surfaces'],
  },
  {
    material: 'Carpet & Carpet Pad',
    porosity: 'porous',
    canBeRemediated: false,
    remediationMethod: 'Remove and replace. Carpet pad must always be discarded. Carpet may be professionally cleaned if mold is surface-only and caught within 24–48 hours.',
    mustRemoveWhen: ['Visible mold growth', 'Category 2 or 3 water damage', 'Musty odor persists after cleaning'],
  },
  {
    material: 'Wood Studs / Framing',
    porosity: 'semi-porous',
    canBeRemediated: true,
    remediationMethod: 'HEPA vacuum, wire brush, HEPA vacuum again, antimicrobial treatment. Heavy staining acceptable if structurally sound.',
    mustRemoveWhen: ['Structural compromise (soft, punky, crumbling)', 'Unable to reduce moisture below acceptable levels'],
  },
  {
    material: 'Plywood / OSB Sheathing',
    porosity: 'semi-porous',
    canBeRemediated: true,
    remediationMethod: 'HEPA vacuum, sand if needed, antimicrobial treatment. Evaluate structural integrity.',
    mustRemoveWhen: ['Delamination', 'Structural compromise', 'Cannot adequately clean (e.g., back side inaccessible)'],
  },
  {
    material: 'Concrete / CMU Block',
    porosity: 'semi-porous',
    canBeRemediated: true,
    remediationMethod: 'HEPA vacuum, wire brush, antimicrobial treatment, optional sealant coating.',
    mustRemoveWhen: ['Deep structural deterioration (rare for mold — more common with long-term water exposure)'],
  },
  {
    material: 'Metal (ducts, studs, flashing)',
    porosity: 'non-porous',
    canBeRemediated: true,
    remediationMethod: 'HEPA vacuum, wipe with antimicrobial solution, dry thoroughly.',
    mustRemoveWhen: ['Corrosion that prevents adequate cleaning'],
  },
  {
    material: 'Glass / Tile / Hard Plastic',
    porosity: 'non-porous',
    canBeRemediated: true,
    remediationMethod: 'Wipe with antimicrobial cleaning solution. Dry thoroughly.',
    mustRemoveWhen: ['Rarely requires removal — clean in place'],
  },
  {
    material: 'HVAC Ductwork (flex duct — fiberglass lined)',
    porosity: 'porous',
    canBeRemediated: false,
    remediationMethod: 'Remove and replace fiberglass-lined flex duct if contaminated. Sheet metal duct can be cleaned.',
    mustRemoveWhen: ['Any visible mold growth inside fiberglass-lined duct', 'Musty odor from duct system'],
  },
  {
    material: 'Hardwood Flooring',
    porosity: 'semi-porous',
    canBeRemediated: true,
    remediationMethod: 'Sand contaminated surface to remove mold, HEPA vacuum, antimicrobial treatment, refinish. Evaluate moisture content and structural integrity.',
    mustRemoveWhen: ['Warping or cupping that cannot be resolved', 'Mold growth on underside with no access to clean', 'Structural softness'],
  },
];

// ─────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────

/** Get water category details by number */
export function getWaterCategory(cat: 1 | 2 | 3): WaterCategory {
  return WATER_CATEGORIES.find(c => c.category === cat)!;
}

/** Get water class details by number */
export function getWaterClass(cls: 1 | 2 | 3 | 4): WaterClass {
  return WATER_CLASSES.find(c => c.class === cls)!;
}

/** Get containment level details */
export function getMoldContainmentLevel(level: 1 | 2 | 3): MoldContainmentLevel {
  return MOLD_CONTAINMENT_LEVELS.find(l => l.level === level)!;
}

/** Get drying standard for a specific material */
export function getDryingStandard(material: string): DryingStandard | undefined {
  return DRYING_STANDARDS.find(d =>
    d.material.toLowerCase().includes(material.toLowerCase())
  );
}

/** Determine containment level from affected square footage */
export function determineContainmentLevel(affectedSqFt: number): MoldContainmentLevel {
  if (affectedSqFt < 10) return MOLD_CONTAINMENT_LEVELS[0]; // Level I
  if (affectedSqFt <= 30) return MOLD_CONTAINMENT_LEVELS[1]; // Level II
  return MOLD_CONTAINMENT_LEVELS[2]; // Level III
}

/** Determine if category may have escalated based on elapsed hours */
export function assessCategoryEscalation(
  originalCategory: 1 | 2 | 3,
  elapsedHours: number
): { currentCategory: 1 | 2 | 3; escalated: boolean; warning: string | null } {
  if (originalCategory === 3) {
    return { currentCategory: 3, escalated: false, warning: null };
  }
  if (originalCategory === 1 && elapsedHours >= 48) {
    return {
      currentCategory: 2,
      escalated: true,
      warning: `Category 1 water untreated for ${elapsedHours}+ hours may have degraded to Category 2. Reassess contamination level.`,
    };
  }
  if (originalCategory === 2 && elapsedHours >= 72) {
    return {
      currentCategory: 3,
      escalated: true,
      warning: `Category 2 water untreated for ${elapsedHours}+ hours may have degraded to Category 3. Reassess contamination level and PPE requirements.`,
    };
  }
  if (originalCategory === 1 && elapsedHours >= 24) {
    return {
      currentCategory: 1,
      escalated: false,
      warning: `Category 1 water has been standing for ${elapsedHours} hours. Monitor closely — may degrade to Category 2 within 24–48 hours total.`,
    };
  }
  return { currentCategory: originalCategory, escalated: false, warning: null };
}

/** Get material remediation decision */
export function getMaterialDecision(material: string): MaterialRemediationDecision | undefined {
  return MATERIAL_REMEDIATION_DECISIONS.find(m =>
    m.material.toLowerCase().includes(material.toLowerCase())
  );
}

/** Calculate approximate air movers needed */
export function calculateAirMovers(params: {
  floorSqFt: number;
  ceilingSqFt?: number;
  linearFtWall: number;
  wallInsetsOver18in: number;
}): { low: number; high: number; notes: string } {
  const floorLow = Math.ceil(params.floorSqFt / 70);
  const floorHigh = Math.ceil(params.floorSqFt / 50);
  const wallLow = Math.ceil(params.linearFtWall / 16);
  const wallHigh = Math.ceil(params.linearFtWall / 10);
  const ceilingLow = params.ceilingSqFt ? Math.ceil(params.ceilingSqFt / 150) : 0;
  const ceilingHigh = params.ceilingSqFt ? Math.ceil(params.ceilingSqFt / 100) : 0;
  const insets = params.wallInsetsOver18in;

  // Use the larger of floor-based or wall-based calculation
  const baseLow = Math.max(floorLow, wallLow) + ceilingLow + insets;
  const baseHigh = Math.max(floorHigh, wallHigh) + ceilingHigh + insets;

  // Minimum 1 per room
  const low = Math.max(1, baseLow);
  const high = Math.max(1, baseHigh);

  return {
    low,
    high,
    notes: `Floor: ${floorLow}–${floorHigh}, Wall: ${wallLow}–${wallHigh}${
      params.ceilingSqFt ? `, Ceiling: ${ceilingLow}–${ceilingHigh}` : ''
    }, Insets: +${insets}`,
  };
}

/** Calculate approximate dehumidifiers needed (LGR, Class 2 factor) */
export function calculateDehumidifiers(params: {
  lengthFt: number;
  widthFt: number;
  heightFt: number;
  dehumidifierAhamPints: number;
  lgrChartFactor?: number;
}): { ppdNeeded: number; unitsNeeded: number; cubicFt: number } {
  const cubicFt = params.lengthFt * params.widthFt * params.heightFt;
  const factor = params.lgrChartFactor ?? 50; // Default to Class 2 LGR factor
  const ppdNeeded = Math.ceil(cubicFt / factor);
  const unitsNeeded = Math.ceil(ppdNeeded / params.dehumidifierAhamPints);

  return { ppdNeeded, unitsNeeded, cubicFt };
}
