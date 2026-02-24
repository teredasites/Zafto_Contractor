/**
 * OFFICIAL OSHA 29 CFR 1926 CONSTRUCTION SAFETY CHECKLISTS
 * =========================================================
 * Based on OSHA Standards for the Construction Industry (29 CFR Part 1926).
 *
 * Sources:
 *   - osha.gov/laws-regs/regulations/standardnumber/1926
 *   - OSHA Top 10 Most Cited Standards (osha.gov/top10citedstandards)
 *   - 29 CFR 1926.501–503 (Fall Protection)
 *   - 29 CFR 1926.451–454 (Scaffolds)
 *   - 29 CFR 1926.650–652 (Excavations)
 *   - 29 CFR 1926.400–449 (Electrical)
 *   - 29 CFR 1926.1053 (Ladders)
 *   - 29 CFR 1926.1200–1213 (Confined Spaces)
 *   - 29 CFR 1926.20–35 (General Safety Provisions)
 *   - 29 CFR 1926.62 (Lead), 29 CFR 1926.1101 (Asbestos)
 *
 * NOTE: This is a practical implementation for a contractor CRM.
 * Checklists reflect the key requirements from each subpart.
 * Full regulatory text is available at osha.gov.
 *
 * 2025 Penalties: $16,550 per serious violation; $165,514 per willful/repeated.
 */

// ─────────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────────

export interface OshaSubpart {
  subpartLetter: string;
  title: string;
  cfr: string;
  description: string;
  applicableTrades: string[];
}

export interface OshaChecklistSection {
  id: string;
  subpart: string;
  cfrSection: string;
  title: string;
  description: string;
  applicableTrades: string[];
  items: OshaChecklistItem[];
}

export interface OshaChecklistItem {
  id: string;
  requirement: string;
  cfrReference: string;
  criticality: 'critical' | 'high' | 'medium';
  frequency: 'daily' | 'per-shift' | 'weekly' | 'per-job' | 'as-needed';
  notes: string | null;
}

export interface OshaViolationStats {
  rank: number;
  standard: string;
  cfrSection: string;
  citations2024: number;
  penaltyPerViolation: string;
  penaltyWillful: string;
}

// ─────────────────────────────────────────────────────────────────────
// OSHA 1926 SUBPARTS
// ─────────────────────────────────────────────────────────────────────

export const OSHA_SUBPARTS: OshaSubpart[] = [
  { subpartLetter: 'A', title: 'General', cfr: '1926.1–1926.7', description: 'Purpose, scope, and definitions', applicableTrades: ['all'] },
  { subpartLetter: 'B', title: 'General Interpretations', cfr: '1926.10–1926.16', description: 'State standards, federal-state relationship', applicableTrades: ['all'] },
  { subpartLetter: 'C', title: 'General Safety and Health Provisions', cfr: '1926.20–1926.35', description: 'Employer responsibilities, safety training, first aid', applicableTrades: ['all'] },
  { subpartLetter: 'D', title: 'Occupational Health and Environmental Controls', cfr: '1926.50–1926.66', description: 'Medical services, sanitation, noise, radiation, lead exposure', applicableTrades: ['all'] },
  { subpartLetter: 'E', title: 'Personal Protective and Life Saving Equipment', cfr: '1926.95–1926.107', description: 'PPE selection, hard hats, eye protection, respiratory protection', applicableTrades: ['all'] },
  { subpartLetter: 'F', title: 'Fire Protection and Prevention', cfr: '1926.150–1926.159', description: 'Fire extinguishers, flammable liquids, LPG', applicableTrades: ['all', 'plumbing', 'hvac', 'welding'] },
  { subpartLetter: 'G', title: 'Signs, Signals, and Barricades', cfr: '1926.200–1926.203', description: 'Danger signs, caution signs, accident prevention tags', applicableTrades: ['all'] },
  { subpartLetter: 'H', title: 'Materials Handling, Storage, Use, and Disposal', cfr: '1926.250–1926.252', description: 'General storage, rigging, disposal of waste', applicableTrades: ['general', 'framing', 'roofing', 'demolition'] },
  { subpartLetter: 'I', title: 'Tools — Hand and Power', cfr: '1926.300–1926.307', description: 'Tool guarding, pneumatic tools, powder-actuated tools', applicableTrades: ['all'] },
  { subpartLetter: 'J', title: 'Welding and Cutting', cfr: '1926.350–1926.354', description: 'Gas welding, arc welding, fire prevention', applicableTrades: ['welding', 'plumbing', 'hvac', 'ironwork'] },
  { subpartLetter: 'K', title: 'Electrical', cfr: '1926.400–1926.449', description: 'Wiring, GFCI, assured grounding, de-energization', applicableTrades: ['electrical', 'general', 'all'] },
  { subpartLetter: 'L', title: 'Scaffolds', cfr: '1926.450–1926.454', description: 'Scaffold capacity, access, training, fall protection', applicableTrades: ['general', 'masonry', 'painting', 'siding', 'stucco', 'drywall'] },
  { subpartLetter: 'M', title: 'Fall Protection', cfr: '1926.500–1926.503', description: 'Duty to protect at 6 feet, guardrails, PFAS, safety nets, training', applicableTrades: ['all'] },
  { subpartLetter: 'N', title: 'Helicopters, Hoists, Elevators, and Conveyors', cfr: '1926.550–1926.556', description: 'Cranes, material hoists, personnel hoists', applicableTrades: ['general', 'steel_erection'] },
  { subpartLetter: 'O', title: 'Motor Vehicles, Mechanized Equipment, and Marine Operations', cfr: '1926.600–1926.606', description: 'Equipment operation, pile driving, site clearing', applicableTrades: ['general', 'excavation', 'demolition'] },
  { subpartLetter: 'P', title: 'Excavations', cfr: '1926.650–1926.652', description: 'Soil classification, protective systems, access/egress', applicableTrades: ['excavation', 'plumbing', 'general', 'utility'] },
  { subpartLetter: 'Q', title: 'Concrete and Masonry Construction', cfr: '1926.700–1926.706', description: 'Formwork, shoring, precast concrete, masonry construction', applicableTrades: ['concrete', 'masonry', 'general'] },
  { subpartLetter: 'R', title: 'Steel Erection', cfr: '1926.750–1926.761', description: 'Structural steel assembly, column anchorage, beams/columns', applicableTrades: ['steel_erection', 'ironwork'] },
  { subpartLetter: 'S', title: 'Underground Construction, Caissons, Cofferdams', cfr: '1926.800–1926.803', description: 'Tunnels, shafts, caissons, cofferdams, compressed air', applicableTrades: ['excavation', 'utility', 'general'] },
  { subpartLetter: 'T', title: 'Demolition', cfr: '1926.850–1926.860', description: 'Preparatory operations, floor/wall removal, mechanical demolition', applicableTrades: ['demolition', 'general'] },
  { subpartLetter: 'U', title: 'Blasting and the Use of Explosives', cfr: '1926.900–1926.914', description: 'Blaster qualifications, storage, firing procedures', applicableTrades: ['demolition', 'excavation'] },
  { subpartLetter: 'V', title: 'Electric Power Transmission and Distribution', cfr: '1926.950–1926.968', description: 'Line clearance, grounding, de-energized lines', applicableTrades: ['electrical', 'utility'] },
  { subpartLetter: 'W', title: 'Rollover Protective Structures; Overhead Protection', cfr: '1926.1000–1926.1003', description: 'ROPS requirements for equipment', applicableTrades: ['general', 'excavation'] },
  { subpartLetter: 'X', title: 'Stairways and Ladders', cfr: '1926.1050–1926.1060', description: 'Ladder use, stairway requirements, training', applicableTrades: ['all'] },
  { subpartLetter: 'Z', title: 'Toxic and Hazardous Substances', cfr: '1926.1100–1926.1153', description: 'Asbestos, lead, crystalline silica, cadmium, benzene', applicableTrades: ['all', 'demolition', 'restoration', 'painting', 'abatement'] },
  { subpartLetter: 'AA', title: 'Confined Spaces in Construction', cfr: '1926.1200–1926.1213', description: 'Entry permits, atmospheric testing, rescue plans', applicableTrades: ['plumbing', 'hvac', 'electrical', 'general', 'utility'] },
  { subpartLetter: 'CC', title: 'Cranes and Derricks in Construction', cfr: '1926.1400–1926.1442', description: 'Assembly/disassembly, inspections, operator qualification', applicableTrades: ['general', 'steel_erection', 'roofing'] },
];

// ─────────────────────────────────────────────────────────────────────
// TOP 10 MOST CITED VIOLATIONS (FY 2024)
// ─────────────────────────────────────────────────────────────────────

export const TOP_CITED_VIOLATIONS: OshaViolationStats[] = [
  { rank: 1, standard: 'Fall Protection — General Requirements', cfrSection: '1926.501', citations2024: 6307, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 2, standard: 'Hazard Communication', cfrSection: '1910.1200', citations2024: 2888, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 3, standard: 'Ladders', cfrSection: '1926.1053', citations2024: 2573, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 4, standard: 'Respiratory Protection', cfrSection: '1910.134', citations2024: 2470, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 5, standard: 'Scaffolding', cfrSection: '1926.451', citations2024: 2060, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 6, standard: 'Fall Protection — Training', cfrSection: '1926.503', citations2024: 1979, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 7, standard: 'Eye and Face Protection', cfrSection: '1926.102', citations2024: 1814, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 8, standard: 'Lockout/Tagout', cfrSection: '1910.147', citations2024: 1673, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 9, standard: 'Machine Guarding', cfrSection: '1910.212', citations2024: 1541, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
  { rank: 10, standard: 'Powered Industrial Trucks', cfrSection: '1910.178', citations2024: 1462, penaltyPerViolation: '$16,550', penaltyWillful: '$165,514' },
];

// ─────────────────────────────────────────────────────────────────────
// SAFETY CHECKLISTS BY SUBPART
// ─────────────────────────────────────────────────────────────────────

export const OSHA_CHECKLISTS: OshaChecklistSection[] = [
  // ── FALL PROTECTION (Subpart M) ──────────────────────────────────
  {
    id: 'fall-protection-general',
    subpart: 'M',
    cfrSection: '1926.501',
    title: 'Fall Protection — General Requirements',
    description: 'Duty to have fall protection for employees on walking/working surfaces 6 feet or more above a lower level.',
    applicableTrades: ['all'],
    items: [
      { id: 'fp-01', requirement: 'Employees on walking/working surfaces with unprotected sides or edges 6+ feet above lower level are protected by guardrail, safety net, or personal fall arrest system (PFAS)', cfrReference: '1926.501(b)(1)', criticality: 'critical', frequency: 'daily', notes: 'Most cited OSHA violation — #1 for 14 consecutive years' },
      { id: 'fp-02', requirement: 'Employees constructing leading edges 6+ feet above lower level have fall protection', cfrReference: '1926.501(b)(2)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fp-03', requirement: 'Employees in hoist areas protected from falling 6+ feet by guardrail or PFAS', cfrReference: '1926.501(b)(3)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fp-04', requirement: 'Each hole (including skylights) where employees can fall 6+ feet is covered or guarded', cfrReference: '1926.501(b)(4)', criticality: 'critical', frequency: 'daily', notes: 'Covers must support 2x weight of workers/equipment, be secured, and marked "HOLE" or "COVER"' },
      { id: 'fp-05', requirement: 'Employees on formwork/reinforcing steel 6+ feet above lower level have fall protection', cfrReference: '1926.501(b)(5)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fp-06', requirement: 'Employees on ramps, runways, and walkways 6+ feet above lower level protected by guardrails', cfrReference: '1926.501(b)(6)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fp-07', requirement: 'Employees doing overhand bricklaying reaching more than 10 inches below work surface have fall protection', cfrReference: '1926.501(b)(9)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'fp-08', requirement: 'Low-slope roof work (≤50 ft wide): safety monitoring system in place', cfrReference: '1926.501(b)(10)', criticality: 'high', frequency: 'daily', notes: 'Only applies to roofs 50 feet or less in width' },
      { id: 'fp-09', requirement: 'Steep roof work (>4:12 pitch) on 6+ feet above lower level: fall protection provided', cfrReference: '1926.501(b)(11)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fp-10', requirement: 'Wall openings with bottom edge less than 39 inches above surface and 6+ feet to lower level are guarded', cfrReference: '1926.501(b)(14)', criticality: 'high', frequency: 'daily', notes: null },
    ],
  },
  {
    id: 'fall-protection-systems',
    subpart: 'M',
    cfrSection: '1926.502',
    title: 'Fall Protection Systems Criteria and Practices',
    description: 'Specifications for guardrails, safety nets, PFAS, positioning systems, and warning lines.',
    applicableTrades: ['all'],
    items: [
      { id: 'fps-01', requirement: 'Top edge of guardrail is 42 inches (±3 inches) above walking/working surface', cfrReference: '1926.502(b)(1)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'fps-02', requirement: 'Midrails installed at height midway between top edge and working surface', cfrReference: '1926.502(b)(2)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'fps-03', requirement: 'Guardrail system withstands 200 lbs of force applied in any outward or downward direction at top edge', cfrReference: '1926.502(b)(3)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'fps-04', requirement: 'Toeboards installed when objects could fall from platform — minimum 3.5 inches tall', cfrReference: '1926.502(b)(5)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'fps-05', requirement: 'PFAS anchorage points capable of supporting 5,000 lbs per attached employee or designed with safety factor of 2 under qualified person supervision', cfrReference: '1926.502(d)(15)', criticality: 'critical', frequency: 'per-job', notes: 'Must be independent from structures supporting guardrails or scaffolds' },
      { id: 'fps-06', requirement: 'Personal fall arrest systems stop freefall at 6 feet or less', cfrReference: '1926.502(d)(16)(iii)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'fps-07', requirement: 'Total fall distance plus deceleration distance does not contact any lower level', cfrReference: '1926.502(d)(16)(iii)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'fps-08', requirement: 'Personal fall arrest system components inspected prior to each use — damaged components removed from service', cfrReference: '1926.502(d)(21)', criticality: 'critical', frequency: 'per-shift', notes: 'After a fall event, the entire system must be removed from service and not reused' },
      { id: 'fps-09', requirement: 'Safety nets installed no more than 30 feet below work surface and extend at least 8 feet beyond edge at 30-foot fall height', cfrReference: '1926.502(c)(1)-(2)', criticality: 'high', frequency: 'per-job', notes: null },
    ],
  },
  {
    id: 'fall-protection-training',
    subpart: 'M',
    cfrSection: '1926.503',
    title: 'Fall Protection — Training Requirements',
    description: 'Training program for each employee exposed to fall hazards.',
    applicableTrades: ['all'],
    items: [
      { id: 'fpt-01', requirement: 'Each employee trained to recognize fall hazards and procedures to minimize them', cfrReference: '1926.503(a)(1)', criticality: 'critical', frequency: 'per-job', notes: '#6 most cited OSHA violation in 2024' },
      { id: 'fpt-02', requirement: 'Training conducted by a competent person', cfrReference: '1926.503(a)(2)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'fpt-03', requirement: 'Written certification of training maintained (employee name, date, trainer signature)', cfrReference: '1926.503(b)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'fpt-04', requirement: 'Retraining provided when changes in workplace or fall protection systems render previous training obsolete', cfrReference: '1926.503(c)', criticality: 'medium', frequency: 'as-needed', notes: null },
    ],
  },

  // ── SCAFFOLDING (Subpart L) ──────────────────────────────────────
  {
    id: 'scaffolds-general',
    subpart: 'L',
    cfrSection: '1926.451',
    title: 'Scaffolds — General Requirements',
    description: 'Capacity, platform construction, supported scaffold requirements, and access.',
    applicableTrades: ['general', 'masonry', 'painting', 'siding', 'stucco', 'drywall', 'roofing'],
    items: [
      { id: 'sc-01', requirement: 'Scaffold designed to support its own weight plus 4 times the maximum intended load without failure', cfrReference: '1926.451(a)(1)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'sc-02', requirement: 'Scaffold platform fully planked or decked between front uprights and guardrail supports', cfrReference: '1926.451(b)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'sc-03', requirement: 'Platform planks extend over centerline of support at least 6 inches and not more than 12 inches', cfrReference: '1926.451(b)(4)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'sc-04', requirement: 'Gap between adjacent planks does not exceed 1 inch', cfrReference: '1926.451(b)(1)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'sc-05', requirement: 'Scaffold platform no more than 14 inches from face of work (18 inches for certain trades)', cfrReference: '1926.451(b)(3)', criticality: 'medium', frequency: 'daily', notes: null },
      { id: 'sc-06', requirement: 'Cross braces are not used as a means of access', cfrReference: '1926.451(e)(1)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'sc-07', requirement: 'Access provided when scaffold platform is more than 2 feet above/below access point (ladder, stair, ramp)', cfrReference: '1926.451(e)(1)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'sc-08', requirement: 'Scaffold not erected, moved, dismantled, or altered except under direction of competent person', cfrReference: '1926.451(f)(7)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'sc-09', requirement: 'No scaffold part loaded in excess of manufacturer maximum rated load', cfrReference: '1926.451(f)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'sc-10', requirement: 'Scaffold at least 10 feet from energized power lines', cfrReference: '1926.451(f)(6)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'sc-11', requirement: 'Competent person inspects scaffold before each work shift and after any occurrence that could affect structural integrity', cfrReference: '1926.451(f)(3)', criticality: 'critical', frequency: 'per-shift', notes: null },
      { id: 'sc-12', requirement: 'Fall protection provided for employees on scaffolds more than 10 feet above lower level', cfrReference: '1926.451(g)(1)', criticality: 'critical', frequency: 'daily', notes: null },
    ],
  },

  // ── LADDERS (Subpart X) ──────────────────────────────────────────
  {
    id: 'ladders',
    subpart: 'X',
    cfrSection: '1926.1053',
    title: 'Ladders',
    description: 'Ladder use, inspection, and safety requirements.',
    applicableTrades: ['all'],
    items: [
      { id: 'ld-01', requirement: 'Ladders used only for the purpose for which they were designed', cfrReference: '1926.1053(b)(1)', criticality: 'high', frequency: 'daily', notes: '#3 most cited OSHA violation in 2024' },
      { id: 'ld-02', requirement: 'Side rails extend at least 3 feet above upper landing surface (or grab rails provided)', cfrReference: '1926.1053(b)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ld-03', requirement: 'Non-self-supporting ladders set at 4:1 ratio (base 1 foot out for every 4 feet of height)', cfrReference: '1926.1053(b)(5)(i)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ld-04', requirement: 'Ladder rungs/cleats/steps uniformly spaced 10–14 inches apart (center to center)', cfrReference: '1926.1053(a)(3)(i)', criticality: 'medium', frequency: 'per-job', notes: null },
      { id: 'ld-05', requirement: 'Metal ladders not used near exposed energized electrical equipment', cfrReference: '1926.1053(b)(12)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ld-06', requirement: 'Ladders inspected by competent person — defective ladders withdrawn from service', cfrReference: '1926.1053(b)(15)-(16)', criticality: 'high', frequency: 'per-shift', notes: null },
      { id: 'ld-07', requirement: 'Employee faces ladder when ascending or descending; maintains 3 points of contact', cfrReference: '1926.1053(b)(20)-(21)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ld-08', requirement: 'Ladders not loaded beyond maximum intended load (consider weight of worker plus tools/materials)', cfrReference: '1926.1053(b)(2)', criticality: 'high', frequency: 'daily', notes: null },
    ],
  },

  // ── EXCAVATIONS (Subpart P) ──────────────────────────────────────
  {
    id: 'excavations',
    subpart: 'P',
    cfrSection: '1926.650–652',
    title: 'Excavations',
    description: 'Soil classification, protective systems, and access requirements for trenches and excavations.',
    applicableTrades: ['excavation', 'plumbing', 'general', 'utility', 'landscaping'],
    items: [
      { id: 'ex-01', requirement: 'Competent person inspects excavation, adjacent areas, and protective systems daily before work and as conditions change', cfrReference: '1926.651(k)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ex-02', requirement: 'Underground utility installations located (call 811) before excavation starts', cfrReference: '1926.651(b)(1)', criticality: 'critical', frequency: 'per-job', notes: 'Must contact utility companies at least 48 hours before digging in most states' },
      { id: 'ex-03', requirement: 'Protective systems (sloping, shoring, or trench boxes) used in trenches 5 feet or deeper', cfrReference: '1926.652(a)(1)', criticality: 'critical', frequency: 'per-job', notes: 'Exception: competent person examines ground and finds no indication of cave-in potential for trenches <20 ft in stable rock' },
      { id: 'ex-04', requirement: 'Means of egress (ladder, ramp, stairway) within 25 feet of lateral travel for trenches 4+ feet deep', cfrReference: '1926.651(c)(2)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ex-05', requirement: 'Spoil piles kept at least 2 feet from edge of excavation', cfrReference: '1926.651(j)(2)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ex-06', requirement: 'Soil classified by competent person (Type A, B, C, or stable rock) using at least one visual and one manual test', cfrReference: '1926.652(b)–Appendix A', criticality: 'critical', frequency: 'per-job', notes: 'Type A: most stable (cohesive, unconfined compressive strength ≥1.5 tsf). Type C: least stable (granular soils, submerged soil)' },
      { id: 'ex-07', requirement: 'Employees protected from falling into excavations by guardrails, fences, barricades, or covers', cfrReference: '1926.651(k)(1)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ex-08', requirement: 'Water controlled and removed before workers enter excavation', cfrReference: '1926.651(h)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ex-09', requirement: 'Atmosphere tested in excavations >4 feet deep where oxygen deficiency or hazardous atmosphere exists or could reasonably exist', cfrReference: '1926.651(g)(1)', criticality: 'critical', frequency: 'daily', notes: null },
    ],
  },

  // ── ELECTRICAL (Subpart K) ───────────────────────────────────────
  {
    id: 'electrical',
    subpart: 'K',
    cfrSection: '1926.400–449',
    title: 'Electrical Safety',
    description: 'GFCI, assured grounding, wiring, and electrical hazard prevention.',
    applicableTrades: ['electrical', 'general', 'all'],
    items: [
      { id: 'el-01', requirement: 'GFCI protection on all 120V, 15A and 20A receptacle outlets on construction sites not part of permanent wiring', cfrReference: '1926.405(a)(2)(ii)(A)', criticality: 'critical', frequency: 'daily', notes: 'Alternative: assured equipment grounding conductor program' },
      { id: 'el-02', requirement: 'All electrical equipment and tools properly grounded or double insulated', cfrReference: '1926.404(f)(6)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'el-03', requirement: 'Flexible cords used only in continuous lengths without splices (except molded or vulcanized)', cfrReference: '1926.405(a)(2)(ii)(J)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'el-04', requirement: 'Electrical circuits de-energized before work (lockout/tagout) unless infeasible', cfrReference: '1926.417(a)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'el-05', requirement: 'Temporary wiring removed immediately upon completion of construction', cfrReference: '1926.405(a)(2)(ii)(A)', criticality: 'medium', frequency: 'per-job', notes: null },
      { id: 'el-06', requirement: 'Electrical panels accessible — 36-inch clearance maintained in front of panels', cfrReference: '1926.403(j)(2)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'el-07', requirement: 'No exposed live parts on electrical equipment operating at 50V or more', cfrReference: '1926.403(i)(2)(i)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'el-08', requirement: 'Assured equipment grounding conductor program (if used instead of GFCI): visual inspection before daily use, tests every 3 months', cfrReference: '1926.404(b)(1)(iii)', criticality: 'high', frequency: 'daily', notes: null },
    ],
  },

  // ── GENERAL SAFETY & HEALTH (Subpart C) ──────────────────────────
  {
    id: 'general-safety',
    subpart: 'C',
    cfrSection: '1926.20–35',
    title: 'General Safety and Health Provisions',
    description: 'Employer programs, competent persons, first aid, fire protection, housekeeping.',
    applicableTrades: ['all'],
    items: [
      { id: 'gs-01', requirement: 'Safety and health program in place covering all aspects of construction work', cfrReference: '1926.20(b)(1)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'gs-02', requirement: 'Competent person designated for frequent and regular inspections of job sites, materials, and equipment', cfrReference: '1926.20(b)(2)', criticality: 'critical', frequency: 'per-job', notes: 'Competent person = one who can identify hazards AND has authority to correct them' },
      { id: 'gs-03', requirement: 'First aid supplies available on site; person trained in first aid on site when no medical facility is reasonably accessible', cfrReference: '1926.23', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'gs-04', requirement: 'Emergency phone numbers posted on site', cfrReference: '1926.50(f)', criticality: 'high', frequency: 'per-job', notes: null },
      { id: 'gs-05', requirement: 'Good housekeeping maintained — work areas, passageways, and stairways clean and orderly', cfrReference: '1926.25(a)', criticality: 'medium', frequency: 'daily', notes: null },
      { id: 'gs-06', requirement: 'Employees informed of hazardous chemicals on site per Hazard Communication standard', cfrReference: '1926.59', criticality: 'critical', frequency: 'per-job', notes: '#2 most cited OSHA violation overall' },
      { id: 'gs-07', requirement: 'Safety Data Sheets (SDS) accessible for all hazardous chemicals on site', cfrReference: '1926.59(g)', criticality: 'critical', frequency: 'per-job', notes: null },
    ],
  },

  // ── PPE (Subpart E) ──────────────────────────────────────────────
  {
    id: 'ppe',
    subpart: 'E',
    cfrSection: '1926.95–107',
    title: 'Personal Protective Equipment',
    description: 'Head, eye, face, foot, and hand protection requirements.',
    applicableTrades: ['all'],
    items: [
      { id: 'ppe-01', requirement: 'Hard hats worn where danger of head injury from falling objects or fixed low-clearance objects', cfrReference: '1926.100(a)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'ppe-02', requirement: 'Eye and face protection provided where exposure to eye/face hazards (flying particles, chemicals, light radiation)', cfrReference: '1926.102(a)(1)', criticality: 'critical', frequency: 'daily', notes: '#7 most cited in 2024' },
      { id: 'ppe-03', requirement: 'Hearing protection provided when noise exposure exceeds 85 dBA TWA (8-hour time-weighted average)', cfrReference: '1926.52 / 1926.101', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ppe-04', requirement: 'Foot protection (safety-toe footwear) worn where danger of foot injuries from falling/rolling objects or piercing soles', cfrReference: '1926.96', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ppe-05', requirement: 'Hand protection (gloves) selected based on hazards present — chemical, thermal, sharp edges, etc.', cfrReference: '1926.95(a)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'ppe-06', requirement: 'High-visibility vests/clothing worn where vehicle/equipment traffic hazards exist', cfrReference: '1926.201', criticality: 'high', frequency: 'daily', notes: 'ANSI/ISEA 107 Class 2 or 3 based on exposure' },
      { id: 'ppe-07', requirement: 'Respiratory protection program in place where employees exposed to harmful dust, fumes, mists, gases, or vapors', cfrReference: '1910.134', criticality: 'critical', frequency: 'per-job', notes: '#4 most cited in 2024. Requires medical evaluation before fit testing' },
    ],
  },

  // ── FIRE PROTECTION (Subpart F) ──────────────────────────────────
  {
    id: 'fire-protection',
    subpart: 'F',
    cfrSection: '1926.150–159',
    title: 'Fire Protection and Prevention',
    description: 'Fire extinguishers, prevention plans, flammable liquids.',
    applicableTrades: ['all', 'welding', 'plumbing', 'hvac', 'roofing'],
    items: [
      { id: 'fire-01', requirement: 'Fire extinguisher within 100 feet travel distance of each employee; within 50 feet where flammable liquids are used', cfrReference: '1926.150(c)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fire-02', requirement: 'Fire extinguishers inspected monthly and maintained annually', cfrReference: '1926.150(c)(1)(viii)', criticality: 'high', frequency: 'weekly', notes: null },
      { id: 'fire-03', requirement: 'Hot work (welding, cutting, brazing) areas cleared of combustibles for 35-foot radius, or protected by fire-resistant covers/shields', cfrReference: '1926.352(a)-(c)', criticality: 'critical', frequency: 'daily', notes: 'Fire watch required for 30 minutes after hot work ceases' },
      { id: 'fire-04', requirement: 'Flammable/combustible liquids stored in approved containers and kept away from ignition sources', cfrReference: '1926.152(a)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'fire-05', requirement: 'No smoking signs posted in areas where flammable materials are stored or used', cfrReference: '1926.151(a)(3)', criticality: 'medium', frequency: 'per-job', notes: null },
    ],
  },

  // ── CONFINED SPACES (Subpart AA) ─────────────────────────────────
  {
    id: 'confined-spaces',
    subpart: 'AA',
    cfrSection: '1926.1200–1213',
    title: 'Confined Spaces in Construction',
    description: 'Permit-required confined space entry, atmospheric testing, rescue.',
    applicableTrades: ['plumbing', 'hvac', 'electrical', 'general', 'utility'],
    items: [
      { id: 'cs-01', requirement: 'All confined spaces on site identified and evaluated for hazards before entry', cfrReference: '1926.1203(a)', criticality: 'critical', frequency: 'per-job', notes: 'Confined space: large enough for employee to enter, limited means of entry/exit, not designed for continuous occupancy' },
      { id: 'cs-02', requirement: 'Entry permit completed and posted at entry point before permit-required confined space entry', cfrReference: '1926.1206', criticality: 'critical', frequency: 'per-shift', notes: null },
      { id: 'cs-03', requirement: 'Atmospheric testing conducted before entry: oxygen (19.5–23.5%), flammable gases (<10% LEL), toxic gases (below PEL)', cfrReference: '1926.1204(e)', criticality: 'critical', frequency: 'per-shift', notes: 'Test in this order: oxygen, combustibility, toxicity' },
      { id: 'cs-04', requirement: 'Continuous atmospheric monitoring during occupancy of permit space', cfrReference: '1926.1204(e)(1)', criticality: 'critical', frequency: 'per-shift', notes: null },
      { id: 'cs-05', requirement: 'Attendant stationed outside each permit space during entry — never enters the space', cfrReference: '1926.1209', criticality: 'critical', frequency: 'per-shift', notes: null },
      { id: 'cs-06', requirement: 'Rescue plan in place (self-rescue, non-entry rescue, or entry rescue by trained team) before entry', cfrReference: '1926.1211', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'cs-07', requirement: 'Ventilation provided to maintain safe atmosphere when hazardous atmosphere exists or could develop', cfrReference: '1926.1204(c)', criticality: 'critical', frequency: 'per-shift', notes: null },
    ],
  },

  // ── HAZARDOUS SUBSTANCES: LEAD (Subpart Z) ──────────────────────
  {
    id: 'lead-exposure',
    subpart: 'Z',
    cfrSection: '1926.62',
    title: 'Lead Exposure in Construction',
    description: 'Lead exposure assessment, action level, PEL, medical surveillance, abatement procedures.',
    applicableTrades: ['painting', 'demolition', 'renovation', 'restoration', 'abatement', 'plumbing'],
    items: [
      { id: 'lead-01', requirement: 'Initial exposure assessment performed for all tasks that may generate lead exposure (demolition, scraping, sanding painted surfaces in pre-1978 buildings)', cfrReference: '1926.62(d)(2)', criticality: 'critical', frequency: 'per-job', notes: 'Action Level: 30 μg/m³ (8-hr TWA). PEL: 50 μg/m³ (8-hr TWA)' },
      { id: 'lead-02', requirement: 'Respiratory protection provided when exposure exceeds PEL of 50 μg/m³', cfrReference: '1926.62(f)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'lead-03', requirement: 'Medical surveillance provided for employees exposed above action level (30 μg/m³) for more than 30 days/year', cfrReference: '1926.62(j)', criticality: 'high', frequency: 'per-job', notes: 'Includes blood lead level monitoring' },
      { id: 'lead-04', requirement: 'Employees removed from lead exposure when blood lead level reaches 50 μg/dL', cfrReference: '1926.62(k)(1)(i)', criticality: 'critical', frequency: 'as-needed', notes: 'Medical removal protection: maintain earnings/seniority' },
      { id: 'lead-05', requirement: 'Hygiene facilities (wash stations, changing areas) provided; no eating, drinking, or smoking in lead-contaminated areas', cfrReference: '1926.62(i)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'lead-06', requirement: 'Written compliance program developed and implemented for each job with lead exposure', cfrReference: '1926.62(e)(2)', criticality: 'high', frequency: 'per-job', notes: null },
    ],
  },

  // ── HAZARDOUS SUBSTANCES: SILICA (Subpart Z) ────────────────────
  {
    id: 'silica-exposure',
    subpart: 'Z',
    cfrSection: '1926.1153',
    title: 'Respirable Crystalline Silica',
    description: 'Silica dust control during cutting, grinding, drilling concrete, masonry, stone.',
    applicableTrades: ['concrete', 'masonry', 'general', 'demolition', 'restoration', 'tile'],
    items: [
      { id: 'sil-01', requirement: 'Table 1 engineering controls implemented for listed tasks (wet cutting, vacuum dust collection, enclosed cabs) OR exposure assessment conducted', cfrReference: '1926.1153(c)–(d)', criticality: 'critical', frequency: 'daily', notes: 'PEL: 50 μg/m³ (8-hr TWA). Action Level: 25 μg/m³' },
      { id: 'sil-02', requirement: 'Water used as dust suppressant when cutting concrete, masonry, stone, or tile with power saws', cfrReference: '1926.1153(c) Table 1', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'sil-03', requirement: 'HEPA vacuum dust collection system used on grinders, drills, and saws when water method not feasible', cfrReference: '1926.1153(c) Table 1', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'sil-04', requirement: 'Respiratory protection provided when engineering controls do not reduce exposure below PEL', cfrReference: '1926.1153(e)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'sil-05', requirement: 'Medical surveillance offered to employees exposed above action level for 30+ days/year', cfrReference: '1926.1153(h)', criticality: 'high', frequency: 'per-job', notes: 'Initial exam within 30 days of initial assignment, then every 3 years' },
    ],
  },

  // ── TOOLS (Subpart I) ────────────────────────────────────────────
  {
    id: 'tools',
    subpart: 'I',
    cfrSection: '1926.300–307',
    title: 'Tools — Hand and Power',
    description: 'Tool guards, pneumatic tools, powder-actuated tools, woodworking tools.',
    applicableTrades: ['all'],
    items: [
      { id: 'tool-01', requirement: 'All hand and power tools maintained in safe condition — no cracked handles, mushroomed heads, or damaged guards', cfrReference: '1926.300(a)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'tool-02', requirement: 'Guards in place on all power tools (belts, gears, shafts, moving parts)', cfrReference: '1926.300(b)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'tool-03', requirement: 'Powder-actuated tools operated only by trained/certified employees', cfrReference: '1926.302(e)(1)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'tool-04', requirement: 'Pneumatic tools secured to hose by positive means (clip/retainer) to prevent disconnection', cfrReference: '1926.302(b)(1)', criticality: 'high', frequency: 'daily', notes: null },
      { id: 'tool-05', requirement: 'Abrasive wheel tools: ring test before mounting; guard covers spindle and nut; max RPM not exceeded', cfrReference: '1926.303(b)–(c)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'tool-06', requirement: 'Circular saws equipped with guards that automatically return to cover blade when not cutting', cfrReference: '1926.304(d)', criticality: 'critical', frequency: 'daily', notes: null },
    ],
  },

  // ── CONCRETE & MASONRY (Subpart Q) ───────────────────────────────
  {
    id: 'concrete-masonry',
    subpart: 'Q',
    cfrSection: '1926.700–706',
    title: 'Concrete and Masonry Construction',
    description: 'Formwork, shoring, jacking, precast concrete, lift-slab, masonry wall bracing.',
    applicableTrades: ['concrete', 'masonry', 'general'],
    items: [
      { id: 'cm-01', requirement: 'No one permitted to ride concrete buckets', cfrReference: '1926.701(a)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'cm-02', requirement: 'Protruding reinforcing steel capped or guarded to eliminate impalement hazard', cfrReference: '1926.701(b)', criticality: 'critical', frequency: 'daily', notes: 'Mushroom caps, troughs, or bending of rebar' },
      { id: 'cm-03', requirement: 'Formwork designed, fabricated, erected, supported, braced, and maintained to support all loads without failure', cfrReference: '1926.703(a)(1)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'cm-04', requirement: 'Shoring not removed until employer determines concrete has gained sufficient strength to support its own weight and imposed loads', cfrReference: '1926.703(e)(1)', criticality: 'critical', frequency: 'per-job', notes: null },
      { id: 'cm-05', requirement: 'Masonry walls over 8 feet tall braced to prevent overturning during construction', cfrReference: '1926.706(a)', criticality: 'critical', frequency: 'daily', notes: null },
      { id: 'cm-06', requirement: 'Limited access zone established on unscaffolded side of masonry wall under construction', cfrReference: '1926.706(b)', criticality: 'high', frequency: 'daily', notes: 'Zone = wall height + 4 feet, running entire length of wall' },
    ],
  },
];

// ─────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────

/** Get all checklists applicable to a specific trade */
export function getChecklistsForTrade(trade: string): OshaChecklistSection[] {
  const tradeLower = trade.toLowerCase();
  return OSHA_CHECKLISTS.filter(
    section =>
      section.applicableTrades.includes('all') ||
      section.applicableTrades.some(t => t.toLowerCase() === tradeLower)
  );
}

/** Get all critical items across all checklists */
export function getCriticalItems(): OshaChecklistItem[] {
  return OSHA_CHECKLISTS.flatMap(section =>
    section.items.filter(item => item.criticality === 'critical')
  );
}

/** Get a specific checklist section by ID */
export function getChecklistSection(id: string): OshaChecklistSection | undefined {
  return OSHA_CHECKLISTS.find(s => s.id === id);
}

/** Get subpart info by letter */
export function getSubpart(letter: string): OshaSubpart | undefined {
  return OSHA_SUBPARTS.find(s => s.subpartLetter === letter.toUpperCase());
}

/** Get daily checklist items for a trade */
export function getDailyChecklistForTrade(trade: string): OshaChecklistItem[] {
  const sections = getChecklistsForTrade(trade);
  return sections.flatMap(section =>
    section.items.filter(item => item.frequency === 'daily' || item.frequency === 'per-shift')
  );
}

/** Get total checklist item count */
export function getTotalChecklistItemCount(): number {
  return OSHA_CHECKLISTS.reduce((sum, section) => sum + section.items.length, 0);
}
