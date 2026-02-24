/**
 * OFFICIAL 50-STATE CONTRACTOR LICENSING REQUIREMENTS
 * ====================================================
 * Based on research from state licensing boards, Procore, ConstructEstimates,
 * NextInsurance, and individual state regulatory websites.
 *
 * Sources:
 *   - procore.com/library/contractors-license-guide-all-states
 *   - constructestimates.com/contractor-licensing-requirements-in-all-50-states-and-dc
 *   - nextinsurance.com/blog/general-contractor-license-requirements
 *   - Individual state licensing board websites (see boardUrl per state)
 *
 * This database covers general contractor + major specialty trade licensing.
 * Requirements change frequently — users should verify with their state board.
 * Last verified: January 2025
 */

// ─────────────────────────────────────────────────────────────────────
// TYPES
// ─────────────────────────────────────────────────────────────────────

export interface StateLicensingConfig {
  stateCode: string;
  stateName: string;
  requiresStateLicense: boolean;
  /** 'state' = state-level license, 'local' = local/county only, 'registration' = registration (not full license), 'hybrid' = mix of state + local */
  licensingModel: 'state' | 'local' | 'registration' | 'hybrid';
  licensingBoard: string;
  boardUrl: string;
  generalContractor: TradeRequirement;
  electrician: TradeRequirement;
  plumber: TradeRequirement;
  hvac: TradeRequirement;
  roofing: TradeRequirement;
  /** Dollar threshold above which license/registration is required; null = any amount */
  monetaryThreshold: number | null;
  examRequired: boolean;
  bondRequired: boolean;
  insuranceRequired: boolean;
  ceRequired: boolean;
  reciprocityStates: string[];
  specialNotes: string[];
}

export interface TradeRequirement {
  requiresLicense: boolean;
  licenseLevel: 'state' | 'local' | 'none';
  examRequired: boolean;
  experienceYears: number | null;
  educationHours: number | null;
  notes: string | null;
}

// ─────────────────────────────────────────────────────────────────────
// HELPER — default trade requirement
// ─────────────────────────────────────────────────────────────────────

function trade(
  req: boolean,
  level: 'state' | 'local' | 'none',
  exam: boolean,
  expYears: number | null = null,
  eduHours: number | null = null,
  notes: string | null = null
): TradeRequirement {
  return { requiresLicense: req, licenseLevel: level, examRequired: exam, experienceYears: expYears, educationHours: eduHours, notes };
}

// ─────────────────────────────────────────────────────────────────────
// STATE LICENSING DATABASE (all 50 states + DC)
// ─────────────────────────────────────────────────────────────────────

export const STATE_LICENSING_CONFIGS: Record<string, StateLicensingConfig> = {
  AL: {
    stateCode: 'AL', stateName: 'Alabama', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Alabama Licensing Board for General Contractors (LBGC) / Home Builders Licensure Board (HBLB)',
    boardUrl: 'https://genconbd.alabama.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Required for commercial projects >$50,000. Home builders licensed separately by HBLB.'),
    electrician: trade(true, 'state', true, 4, null, 'Licensed through Alabama Electrical Contractors Board'),
    plumber: trade(true, 'state', true, 4, null, 'Licensed through Alabama Plumbers and Gas Fitters Examining Board'),
    hvac: trade(true, 'state', true, null, null, 'Licensed through Alabama Board of Heating, Air Conditioning, and Refrigeration Contractors'),
    roofing: trade(true, 'state', true, null, null, 'Falls under general contractor license or home builder license'),
    monetaryThreshold: 50000, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Pool construction >$5,000 requires separate license', 'Separate residential (HBLB) and commercial (LBGC) boards'],
  },
  AK: {
    stateCode: 'AK', stateName: 'Alaska', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Department of Commerce, Community and Economic Development — Division of Corporations, Business and Professional Licensing',
    boardUrl: 'https://www.commerce.alaska.gov/web/cbpl/',
    generalContractor: trade(true, 'state', true, null, null, 'Required for residential remodeling >25% of home value. Projects <$10,000 require Handyman License.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, 'Mechanical contractor license'),
    roofing: trade(true, 'state', true, null, null, 'Falls under general contractor or specialty contractor'),
    monetaryThreshold: 10000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Handyman License for projects <$10,000'],
  },
  AZ: {
    stateCode: 'AZ', stateName: 'Arizona', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Arizona Registrar of Contractors (ROC)',
    boardUrl: 'https://roc.az.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'All contractors must be licensed for projects >$1,000 or requiring a building permit'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: 1000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Exemption for projects <$1,000 that do not require a building permit'],
  },
  AR: {
    stateCode: 'AR', stateName: 'Arkansas', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Arkansas Contractors Licensing Board (ACLB)',
    boardUrl: 'https://www.aclb.arkansas.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Required for projects >$2,000 residential, >$50,000 commercial'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, 'Specialty contractor license'),
    monetaryThreshold: 2000, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['$2,000 threshold for residential, $50,000 for commercial'],
  },
  CA: {
    stateCode: 'CA', stateName: 'California', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Contractors State License Board (CSLB)',
    boardUrl: 'https://www.cslb.ca.gov/',
    generalContractor: trade(true, 'state', true, 4, null, 'Class A (general engineering), Class B (general building), Class B-2 (residential remodeling)'),
    electrician: trade(true, 'state', true, 4, null, 'C-10 Electrical Contractor'),
    plumber: trade(true, 'state', true, 4, null, 'C-36 Plumbing Contractor'),
    hvac: trade(true, 'state', true, 4, null, 'C-20 HVAC Contractor'),
    roofing: trade(true, 'state', true, 4, null, 'C-39 Roofing Contractor'),
    monetaryThreshold: 500, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: ['FL', 'LA', 'MS', 'NC', 'GA'],
    specialNotes: ['43 specialty contractor classifications (C-classifications)', 'All contractors must pass law & business exam + trade exam', '$500 threshold is very low — virtually all work requires license'],
  },
  CO: {
    stateCode: 'CO', stateName: 'Colorado', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'No statewide GC licensing. Plumbing/Electrical through state. Local municipalities.',
    boardUrl: 'https://dora.colorado.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Many cities/counties require local registration.'),
    electrician: trade(true, 'state', true, 4, null, 'State Electrical Board'),
    plumber: trade(true, 'state', true, 4, null, 'State Plumbing Board'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['All businesses must register with state', 'Denver, Colorado Springs, and other cities have their own licensing'],
  },
  CT: {
    stateCode: 'CT', stateName: 'Connecticut', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Department of Consumer Protection',
    boardUrl: 'https://portal.ct.gov/DCP',
    generalContractor: trade(false, 'none', false, null, null, 'Registration required — major and minor contractor categories. No state license.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, 'Sheet metal workers and HVAC'),
    roofing: trade(false, 'none', false, null, null, 'Falls under contractor registration'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Home improvement contractor registration required'],
  },
  DE: {
    stateCode: 'DE', stateName: 'Delaware', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Division of Revenue (registration) / Department of Professional Regulation (trades)',
    boardUrl: 'https://dpr.delaware.gov/',
    generalContractor: trade(false, 'none', false, null, null, 'Business registration only — no state GC license'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, 'HVAC-refrigeration license'),
    roofing: trade(false, 'none', false, null, null, null),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: [],
  },
  DC: {
    stateCode: 'DC', stateName: 'District of Columbia', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'DC Department of Consumer and Regulatory Affairs (DCRA)',
    boardUrl: 'https://dcra.dc.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Basic Business License with Home Improvement endorsement'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Clean Hands Act compliance required'],
  },
  FL: {
    stateCode: 'FL', stateName: 'Florida', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Construction Industry Licensing Board (CILB)',
    boardUrl: 'https://www.myfloridalicense.com/DBPR/construction-industry-licensing-board/',
    generalContractor: trade(true, 'state', true, 4, null, 'Division I: General, Building, Residential. Division II: Specialty trades.'),
    electrician: trade(true, 'state', true, 4, null, 'Electrical Contractor — state certification or county certification'),
    plumber: trade(true, 'state', true, 4, null, 'Plumbing Contractor — state or county certification'),
    hvac: trade(true, 'state', true, 4, null, 'Mechanical Contractor (includes HVAC)'),
    roofing: trade(true, 'state', true, 4, null, 'Roofing Contractor — Division II specialty'),
    monetaryThreshold: null, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['CA', 'LA', 'MS', 'NC', 'GA'],
    specialNotes: ['State certification = work anywhere in FL. County certification = limited to that county.', 'Handyman exemption for minor repairs'],
  },
  GA: {
    stateCode: 'GA', stateName: 'Georgia', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Georgia State Construction Industry Licensing Board',
    boardUrl: 'https://sos.ga.gov/plb',
    generalContractor: trade(true, 'state', true, null, null, '4 classification levels based on project value'),
    electrician: trade(true, 'state', true, 4, null, 'Low voltage, unrestricted, restricted classes'),
    plumber: trade(true, 'state', true, 4, null, 'Journeyman and Master Plumber'),
    hvac: trade(true, 'state', true, null, null, 'Conditioned air contractor'),
    roofing: trade(true, 'state', true, null, null, 'Falls under general or residential contractor'),
    monetaryThreshold: 2500, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['LA', 'MS', 'NC', 'TN'],
    specialNotes: ['Veterans eligible for preference points on exams', 'Residential reciprocity with MS, SC'],
  },
  HI: {
    stateCode: 'HI', stateName: 'Hawaii', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Department of Commerce and Consumer Affairs — Professional and Vocational Licensing Board',
    boardUrl: 'https://cca.hawaii.gov/pvl/',
    generalContractor: trade(true, 'state', true, 4, null, 'General engineering (A), General building (B), Specialty (C)'),
    electrician: trade(true, 'state', true, 4, null, 'C-13 Electrical'),
    plumber: trade(true, 'state', true, 4, null, 'C-37 Plumbing'),
    hvac: trade(true, 'state', true, 4, null, 'C-16 Warm Air Heating / C-38 Refrigeration'),
    roofing: trade(true, 'state', true, 4, null, 'C-42 Roofing and Waterproofing'),
    monetaryThreshold: 1000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Very low $1,000 threshold', 'Any project requiring a building permit requires a licensed contractor'],
  },
  ID: {
    stateCode: 'ID', stateName: 'Idaho', requiresStateLicense: false,
    licensingModel: 'registration',
    licensingBoard: 'Idaho Contractors Board / Division of Building Safety',
    boardUrl: 'https://dbs.idaho.gov/',
    generalContractor: trade(false, 'none', false, null, null, 'Registration required for projects >$2,000. No license or exam.'),
    electrician: trade(true, 'state', true, 4, null, 'Through Division of Building Safety'),
    plumber: trade(true, 'state', true, 4, null, 'Through Division of Building Safety'),
    hvac: trade(true, 'state', true, null, null, 'Through Division of Building Safety'),
    roofing: trade(false, 'none', false, null, null, 'Registration only'),
    monetaryThreshold: 2000, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Public works projects >$10,000 have additional requirements'],
  },
  IL: {
    stateCode: 'IL', stateName: 'Illinois', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No state licensing board. Local municipalities. Department of Public Health (plumbing).',
    boardUrl: 'https://dph.illinois.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state license. Chicago and many municipalities require local contractor licenses.'),
    electrician: trade(false, 'local', true, 4, null, 'Licensed locally. No state electrical license.'),
    plumber: trade(true, 'state', true, 4, null, 'Licensed through Illinois Department of Public Health'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Some municipalities require roofing licenses'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Chicago has extensive local licensing requirements', 'Business registration with IL Department of Revenue required'],
  },
  IN: {
    stateCode: 'IN', stateName: 'Indiana', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'Professional Licensing Agency (plumbing only). Local municipalities.',
    boardUrl: 'https://www.in.gov/pla/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local county/city licensing varies.'),
    electrician: trade(false, 'local', true, null, null, 'Licensed locally in most jurisdictions'),
    plumber: trade(true, 'state', true, 4, null, 'State license through Professional Licensing Agency'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Indianapolis uses Department of Business and Neighborhood Services'],
  },
  IA: {
    stateCode: 'IA', stateName: 'Iowa', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Iowa Division of Labor — Construction Contractor Registration',
    boardUrl: 'https://www.iowadivisionoflabor.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Construction contractor license mandatory'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Background check and surety bond required', 'Liability, workers comp, and unemployment insurance all required'],
  },
  KS: {
    stateCode: 'KS', stateName: 'Kansas', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No statewide licensing. Kansas Secretary of State (business registration).',
    boardUrl: 'https://www.sos.ks.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state license. Local municipal requirements vary.'),
    electrician: trade(false, 'local', true, null, null, 'Local licensing'),
    plumber: trade(false, 'local', true, null, null, 'Local licensing'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Business registration and bonding/insurance required statewide'],
  },
  KY: {
    stateCode: 'KY', stateName: 'Kentucky', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No statewide GC licensing. Local municipalities handle licensing.',
    boardUrl: 'https://www.sos.ky.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local requirements vary by city/county.'),
    electrician: trade(false, 'local', true, null, null, 'Local licensing'),
    plumber: trade(false, 'local', true, null, null, 'Local licensing'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Workers compensation insurance required for all businesses'],
  },
  LA: {
    stateCode: 'LA', stateName: 'Louisiana', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Louisiana State Licensing Board for Contractors (LSLBC)',
    boardUrl: 'https://lslbc.louisiana.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Commercial ($50k+), Residential ($75k+), Home Improvement ($7.5k–$75k)'),
    electrician: trade(true, 'state', true, 4, null, 'Through LSLBC at $50,000+ or separately at lower threshold'),
    plumber: trade(true, 'state', true, 4, null, 'State Plumbing Board license for work >$10,000'),
    hvac: trade(true, 'state', true, null, null, 'Mechanical work >$10,000 requires license'),
    roofing: trade(true, 'state', true, null, null, 'Specialty contractor under LSLBC'),
    monetaryThreshold: 7500, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['FL', 'CA', 'MS', 'NC', 'GA'],
    specialNotes: ['Three license types based on project value', 'Plumbing and electrical at $10,000 threshold'],
  },
  ME: {
    stateCode: 'ME', stateName: 'Maine', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Office of Professional and Occupational Regulation',
    boardUrl: 'https://www.maine.gov/pfr/professionallicensing/',
    generalContractor: trade(false, 'none', false, null, null, 'No state GC license. Jobs >$3,000 require written contracts.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(false, 'none', false, null, null, 'No state license'),
    roofing: trade(false, 'none', false, null, null, 'No state license'),
    monetaryThreshold: 3000, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Written contract required for jobs >$3,000', 'Some municipalities have additional requirements'],
  },
  MD: {
    stateCode: 'MD', stateName: 'Maryland', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Maryland Home Improvement Commission (MHIC)',
    boardUrl: 'https://www.dllr.state.md.us/license/mhic/',
    generalContractor: trade(true, 'state', true, null, null, 'Home improvement contractors for residential buildings <4 units'),
    electrician: trade(true, 'state', true, 4, null, 'State Board of Master Electricians'),
    plumber: trade(true, 'state', true, 4, null, 'State Board of Plumbing'),
    hvac: trade(true, 'state', true, null, null, 'Board of HVACR Contractors'),
    roofing: trade(true, 'state', true, null, null, 'Falls under home improvement contractor'),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['MHIC license covers residential home improvement work', 'Surety bond and financial responsibility required'],
  },
  MA: {
    stateCode: 'MA', stateName: 'Massachusetts', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Board of Building Regulations and Standards / Home Improvement Contractor Program',
    boardUrl: 'https://www.mass.gov/orgs/board-of-building-regulation-and-standards',
    generalContractor: trade(true, 'state', true, 3, null, 'Construction Supervisor license. Home Improvement Contractors register separately (1–2 units).'),
    electrician: trade(true, 'state', true, 4, null, 'Board of State Examiners of Electricians'),
    plumber: trade(true, 'state', true, 4, null, 'Board of State Examiners of Plumbers and Gas Fitters'),
    hvac: trade(true, 'state', true, null, null, 'Refrigeration Technician license'),
    roofing: trade(true, 'state', true, null, null, 'Falls under Construction Supervisor'),
    monetaryThreshold: null, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['3 years experience required for Construction Supervisor', 'Home Improvement registration for 1–2 family dwellings'],
  },
  MI: {
    stateCode: 'MI', stateName: 'Michigan', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Michigan Department of Licensing and Regulatory Affairs (LARA)',
    boardUrl: 'https://www.michigan.gov/lara/bureau-list/bcc',
    generalContractor: trade(true, 'state', true, null, 60, 'Residential builder or maintenance/alterations contractor. 60-hour pre-license course.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, 'Mechanical contractor license'),
    roofing: trade(true, 'state', true, null, null, 'Falls under residential builder or commercial builder'),
    monetaryThreshold: null, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['60-hour pre-license course required', 'Separate licenses: Residential Builder, Maintenance & Alterations, Commercial Builder'],
  },
  MN: {
    stateCode: 'MN', stateName: 'Minnesota', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Minnesota Department of Labor and Industry',
    boardUrl: 'https://www.dli.mn.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'License required when performing 2+ construction skill areas'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, 'Most plumbers need state license'),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, 'Separate roofing contractor license'),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['License triggers when performing 2+ construction skill areas'],
  },
  MS: {
    stateCode: 'MS', stateName: 'Mississippi', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Mississippi State Board of Contractors',
    boardUrl: 'https://www.msboc.us/',
    generalContractor: trade(true, 'state', true, null, null, 'Residential and commercial license types'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: 10000, examRequired: true, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['FL', 'LA', 'GA', 'NC', 'SC'],
    specialNotes: ['Business law exam required for all contractors'],
  },
  MO: {
    stateCode: 'MO', stateName: 'Missouri', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No statewide licensing. Local municipalities.',
    boardUrl: 'https://www.sos.mo.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state license. Local contractor licenses required where work performed.'),
    electrician: trade(false, 'local', true, null, null, 'No state exam — local licensing'),
    plumber: trade(false, 'local', true, null, null, 'No state exam — local licensing'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Business registration with state required', 'St. Louis and Kansas City have extensive local licensing'],
  },
  MT: {
    stateCode: 'MT', stateName: 'Montana', requiresStateLicense: false,
    licensingModel: 'registration',
    licensingBoard: 'Montana Department of Labor and Industry',
    boardUrl: 'https://erd.dli.mt.gov/',
    generalContractor: trade(false, 'none', false, null, null, 'Registration only — not full licensing'),
    electrician: trade(true, 'state', true, 4, null, 'State exam required'),
    plumber: trade(true, 'state', true, 4, null, 'State exam required'),
    hvac: trade(false, 'none', false, null, null, 'No state license'),
    roofing: trade(false, 'none', false, null, null, 'No state license'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Registration with state, not formal licensing for GC'],
  },
  NE: {
    stateCode: 'NE', stateName: 'Nebraska', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Nebraska Department of Labor',
    boardUrl: 'https://dol.nebraska.gov/',
    generalContractor: trade(false, 'none', false, null, null, 'Business registration only — no state GC license or exam'),
    electrician: trade(true, 'state', true, 4, null, 'State electrical license'),
    plumber: trade(false, 'local', true, null, null, 'Local licensing'),
    hvac: trade(false, 'none', false, null, null, 'No state license'),
    roofing: trade(false, 'none', false, null, null, 'No state license'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Workers compensation and liability insurance required'],
  },
  NV: {
    stateCode: 'NV', stateName: 'Nevada', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Nevada State Contractors Board',
    boardUrl: 'https://www.nvcontractorsboard.com/',
    generalContractor: trade(true, 'state', true, 4, null, 'General engineering (A), General building (B), Specialty (C). Rigorous 4-year experience + exam.'),
    electrician: trade(true, 'state', true, 4, null, 'C-2 Electrical Contracting'),
    plumber: trade(true, 'state', true, 4, null, 'C-1 Plumbing and Heating'),
    hvac: trade(true, 'state', true, 4, null, 'C-21 Refrigeration and Air Conditioning'),
    roofing: trade(true, 'state', true, 4, null, 'C-15 Roofing and Siding'),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['4 years work experience required', 'Background check for all applicants', 'Financial responsibility review'],
  },
  NH: {
    stateCode: 'NH', stateName: 'New Hampshire', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'No statewide GC licensing. Electricians/Plumbers licensed at state level.',
    boardUrl: 'https://www.sos.nh.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Some municipalities have requirements.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(false, 'none', false, null, null, 'No state license'),
    roofing: trade(false, 'none', false, null, null, 'No state license'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Manchester has special local contractor requirements'],
  },
  NJ: {
    stateCode: 'NJ', stateName: 'New Jersey', requiresStateLicense: false,
    licensingModel: 'registration',
    licensingBoard: 'Division of Consumer Affairs — Home Improvement Contractor Registration',
    boardUrl: 'https://www.njconsumeraffairs.gov/',
    generalContractor: trade(false, 'none', false, null, null, 'Registration only for home improvement contractors — no exam'),
    electrician: trade(true, 'state', true, 4, null, 'Board of Examiners of Electrical Contractors'),
    plumber: trade(true, 'state', true, 4, null, 'State Board of Examiners of Master Plumbers'),
    hvac: trade(false, 'none', false, null, null, 'No state license — some local requirements'),
    roofing: trade(false, 'none', false, null, null, 'Falls under home improvement registration'),
    monetaryThreshold: null, examRequired: false, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Home improvement contractor registration (not licensing)', 'Bonding and insurance required'],
  },
  NM: {
    stateCode: 'NM', stateName: 'New Mexico', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'New Mexico Construction Industries Division (CID)',
    boardUrl: 'https://www.rld.nm.gov/construction-industries/',
    generalContractor: trade(true, 'state', true, 2, null, '2–4 years experience depending on specialty'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, 2, null, null),
    roofing: trade(true, 'state', true, 2, null, null),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Surety bond and financial responsibility proof required'],
  },
  NY: {
    stateCode: 'NY', stateName: 'New York', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No statewide GC licensing. NYC Department of Buildings, local municipalities.',
    boardUrl: 'https://www.nyc.gov/site/buildings/index.page',
    generalContractor: trade(false, 'local', false, null, null, 'NYC requires licenses. Most other areas: registration and insurance only.'),
    electrician: trade(false, 'local', true, null, null, 'NYC and many cities require local electrical licenses'),
    plumber: trade(false, 'local', true, null, null, 'NYC and many cities require local plumbing licenses'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['NYC has extensive licensing system', 'Asbestos and crane operators require state licenses', 'Home improvement contractor registration in many counties'],
  },
  NC: {
    stateCode: 'NC', stateName: 'North Carolina', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'North Carolina Licensing Board for General Contractors',
    boardUrl: 'https://nclbgc.org/',
    generalContractor: trade(true, 'state', true, null, null, 'Separate licensing for general contractors and specialty trades'),
    electrician: trade(true, 'state', true, 4, null, 'State Board of Examiners of Electrical Contractors'),
    plumber: trade(true, 'state', true, 4, null, 'State Board of Examiners of Plumbing, Heating and Fire Sprinkler Contractors'),
    hvac: trade(true, 'state', true, 4, null, 'Through Plumbing/Heating Board'),
    roofing: trade(true, 'state', true, null, null, 'Falls under general contractor'),
    monetaryThreshold: 30000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['FL', 'LA', 'MS', 'GA', 'TN'],
    specialNotes: ['$30,000 threshold for general contractor license', 'Financial statements and surety bonds required'],
  },
  ND: {
    stateCode: 'ND', stateName: 'North Dakota', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'North Dakota Secretary of State — Contractor Licensing',
    boardUrl: 'https://sos.nd.gov/',
    generalContractor: trade(true, 'state', false, null, null, 'License classes determined by maximum job value. Projects >$4,000.'),
    electrician: trade(true, 'state', true, 4, null, 'State Electrical Board'),
    plumber: trade(true, 'state', true, 4, null, 'State Plumbing Board'),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', false, null, null, 'Falls under general contractor licensing'),
    monetaryThreshold: 4000, examRequired: false, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['License classes based on maximum job value', 'Letter of good standing with workforce safety required'],
  },
  OH: {
    stateCode: 'OH', stateName: 'Ohio', requiresStateLicense: false,
    licensingModel: 'local',
    licensingBoard: 'No statewide GC licensing. Ohio Construction Industry Licensing Board (OCILB) for specialty trades.',
    boardUrl: 'https://com.ohio.gov/divisions-and-programs/industrial-compliance/construction-industry-licensing-board',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local requirements vary.'),
    electrician: trade(true, 'state', true, 4, null, 'Through OCILB'),
    plumber: trade(true, 'state', true, 4, null, 'Through OCILB'),
    hvac: trade(true, 'state', true, null, null, 'Through OCILB — hydronics and refrigeration'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['OCILB handles electrical, plumbing, HVAC, hydronics, refrigeration licensing'],
  },
  OK: {
    stateCode: 'OK', stateName: 'Oklahoma', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Oklahoma Construction Industries Board (CIB)',
    boardUrl: 'https://oklahoma.gov/cib.html',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Out-of-state contractors need OK business license.'),
    electrician: trade(true, 'state', true, 4, null, 'Through CIB'),
    plumber: trade(true, 'state', true, 4, null, 'Through CIB'),
    hvac: trade(true, 'state', true, null, null, 'Through CIB'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['CIB handles specialty trade licensing', 'Surety bond required'],
  },
  OR: {
    stateCode: 'OR', stateName: 'Oregon', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Oregon Construction Contractors Board (CCB)',
    boardUrl: 'https://www.oregon.gov/ccb/',
    generalContractor: trade(true, 'state', true, null, null, 'Multiple commercial and residential endorsements'),
    electrician: trade(true, 'state', true, 4, null, 'Building Codes Division'),
    plumber: trade(true, 'state', true, 4, null, 'Building Codes Division'),
    hvac: trade(true, 'state', true, null, null, 'Building Codes Division'),
    roofing: trade(true, 'state', true, null, null, 'Endorsement under CCB'),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Class requirement, exam, surety bond, and insurance all mandatory', 'Separate procedures for GC and specialty trades'],
  },
  PA: {
    stateCode: 'PA', stateName: 'Pennsylvania', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Attorney General — Home Improvement Contractor Registration',
    boardUrl: 'https://www.attorneygeneral.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'Registration with Attorney General for projects >$5,000. No state license or exam.'),
    electrician: trade(false, 'local', true, null, null, 'Local licensing in Philadelphia, Pittsburgh, and many municipalities'),
    plumber: trade(false, 'local', true, null, null, 'Local licensing'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: 5000, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Home improvement registration for projects >$5,000', 'Philadelphia has extensive separate licensing system'],
  },
  RI: {
    stateCode: 'RI', stateName: 'Rhode Island', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Rhode Island Contractors Registration Board',
    boardUrl: 'https://crb.ri.gov/',
    generalContractor: trade(true, 'state', false, null, 5, 'State registration. 5-hour pre-registration class required.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, 'Separate roofing contractor registration + exam'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['General contractors: 5-hour class + registration (no exam)', 'Roofing and underground utility: separate exam required'],
  },
  SC: {
    stateCode: 'SC', stateName: 'South Carolina', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'South Carolina Department of Labor, Licensing and Regulation (LLR)',
    boardUrl: 'https://llr.sc.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Three types: General/Mechanical, Residential, Specialty. Projects >$5,000.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, 'Falls under Mechanical contractor'),
    roofing: trade(true, 'state', true, null, null, 'Specialty contractor'),
    monetaryThreshold: 5000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['GA', 'MS'],
    specialNotes: ['General law exam + specialty exam required', 'Background check and surety bond required'],
  },
  SD: {
    stateCode: 'SD', stateName: 'South Dakota', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'South Dakota Secretary of State. Department of Labor (plumbing/electrical).',
    boardUrl: 'https://sdsos.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local requirements only.'),
    electrician: trade(true, 'state', true, 4, null, 'State electrical license'),
    plumber: trade(true, 'state', true, 4, null, 'State plumbing license'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Only plumbing, electrical, and asbestos require state licenses', 'Business registration with Secretary of State required'],
  },
  TN: {
    stateCode: 'TN', stateName: 'Tennessee', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Tennessee Board for Licensing Contractors',
    boardUrl: 'https://www.tn.gov/commerce/regboards/contractor.html',
    generalContractor: trade(true, 'state', true, null, null, 'Residential work at $3,000+. Other work at $25,000+. Prime, subcontractor, and CM licenses.'),
    electrician: trade(true, 'state', true, 4, null, 'Board of Examiners of Electricians'),
    plumber: trade(true, 'state', true, 4, null, 'State Board of Plumbing Examiners'),
    hvac: trade(true, 'state', true, null, null, 'Through contractor board'),
    roofing: trade(true, 'state', true, null, null, 'Falls under contractor board'),
    monetaryThreshold: 3000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: ['GA', 'NC'],
    specialNotes: ['$3,000 threshold for residential', '$25,000 threshold for non-residential', 'General law exam + specialty tests required'],
  },
  TX: {
    stateCode: 'TX', stateName: 'Texas', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'TDLR (electricians, A/C). State Board of Plumbing Examiners. Local municipalities for GC.',
    boardUrl: 'https://www.tdlr.texas.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local licenses in most cities (Houston, Dallas, Austin, San Antonio).'),
    electrician: trade(true, 'state', true, 4, null, 'Through TDLR — Master and Journeyman classes'),
    plumber: trade(true, 'state', true, 4, null, 'Texas State Board of Plumbing Examiners — Journeyman and Master'),
    hvac: trade(true, 'state', true, null, null, 'TDLR — Air Conditioning and Refrigeration Contractor'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Plumbing, electrical, and A/C at state level', 'General contractor licensed locally', 'All businesses register with state and need tax ID'],
  },
  UT: {
    stateCode: 'UT', stateName: 'Utah', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Utah Division of Occupational and Professional Licensing (DOPL)',
    boardUrl: 'https://dopl.utah.gov/',
    generalContractor: trade(true, 'state', true, 2, 25, '23 contractor classifications. 25-hour course + 2 exams (contractor + specialty).'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['23 contractor classifications', '25-hour pre-license course required', '1 year supervisory + 1 year working experience minimum'],
  },
  VT: {
    stateCode: 'VT', stateName: 'Vermont', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Office of Professional Regulation',
    boardUrl: 'https://sos.vermont.gov/opr/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Some municipalities require local registration.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(false, 'none', false, null, null, 'No state license'),
    roofing: trade(false, 'none', false, null, null, 'No state license'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Only plumbing, electrical, asbestos, and lead paint require state licenses'],
  },
  VA: {
    stateCode: 'VA', stateName: 'Virginia', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Virginia Board for Contractors — Department of Professional and Occupational Regulation (DPOR)',
    boardUrl: 'https://www.dpor.virginia.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Three license classes based on business value: A (unlimited), B ($10k–$120k), C ($1k–$10k)'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, 'Falls under contractor classes'),
    monetaryThreshold: 1000, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Class A: unlimited value. Class B: $10k–$120k. Class C: $1k–$10k.', 'Contractor education course required'],
  },
  WA: {
    stateCode: 'WA', stateName: 'Washington', requiresStateLicense: true,
    licensingModel: 'registration',
    licensingBoard: 'Washington Department of Labor and Industries (L&I)',
    boardUrl: 'https://lni.wa.gov/licensing-permits/contractors/',
    generalContractor: trade(true, 'state', false, null, null, 'Registration required — not full licensing. No exam for GC.'),
    electrician: trade(true, 'state', true, 4, null, 'Administered by L&I'),
    plumber: trade(true, 'state', true, 4, null, 'Administered by L&I'),
    hvac: trade(true, 'state', true, null, null, 'Administered by L&I'),
    roofing: trade(true, 'state', false, null, null, 'Registration, not licensing'),
    monetaryThreshold: null, examRequired: false, bondRequired: true, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Registration model, not licensing', 'Bond and insurance required', 'Specialty trades have their own exam requirements'],
  },
  WV: {
    stateCode: 'WV', stateName: 'West Virginia', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'West Virginia Division of Labor — Contractor Licensing Board',
    boardUrl: 'https://labor.wv.gov/',
    generalContractor: trade(true, 'state', true, null, null, 'Business law and general contractor exams required'),
    electrician: trade(true, 'state', true, 4, null, 'State Fire Marshal licensing'),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, null),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Surety bond and wage bond required', 'Workers comp and liability insurance mandatory'],
  },
  WI: {
    stateCode: 'WI', stateName: 'Wisconsin', requiresStateLicense: true,
    licensingModel: 'state',
    licensingBoard: 'Wisconsin Department of Safety and Professional Services (DSPS)',
    boardUrl: 'https://dsps.wi.gov/',
    generalContractor: trade(true, 'state', true, null, 12, 'Dwelling Contractor license. 12-hour pre-license course + exam.'),
    electrician: trade(true, 'state', true, 4, null, null),
    plumber: trade(true, 'state', true, 4, null, null),
    hvac: trade(true, 'state', true, null, null, null),
    roofing: trade(true, 'state', true, null, null, 'Falls under Dwelling Contractor'),
    monetaryThreshold: null, examRequired: true, bondRequired: true, insuranceRequired: true, ceRequired: true,
    reciprocityStates: [],
    specialNotes: ['Dwelling Contractor license required for residential', '12-hour course + exam required', 'Bond and workers comp mandatory'],
  },
  WY: {
    stateCode: 'WY', stateName: 'Wyoming', requiresStateLicense: false,
    licensingModel: 'hybrid',
    licensingBoard: 'Wyoming Department of Fire Prevention and Electrical Safety (electricians only). Local municipalities.',
    boardUrl: 'https://www.sos.wyo.gov/',
    generalContractor: trade(false, 'local', false, null, null, 'No state GC license. Local jurisdictions vary.'),
    electrician: trade(true, 'state', true, 4, null, 'State electrical license'),
    plumber: trade(false, 'local', true, null, null, 'Local licensing'),
    hvac: trade(false, 'local', false, null, null, 'Local requirements only'),
    roofing: trade(false, 'local', false, null, null, 'Local requirements only'),
    monetaryThreshold: null, examRequired: false, bondRequired: false, insuranceRequired: true, ceRequired: false,
    reciprocityStates: [],
    specialNotes: ['Only electricians licensed at state level', 'Other trades licensed or permitted locally', 'Business entity registration and tax compliance required'],
  },
};

// ─────────────────────────────────────────────────────────────────────
// HELPER FUNCTIONS
// ─────────────────────────────────────────────────────────────────────

/** Get licensing config for a state */
export function getStateLicensingConfig(stateCode: string): StateLicensingConfig | undefined {
  return STATE_LICENSING_CONFIGS[stateCode.toUpperCase()];
}

/** Get all states that require state-level licensing */
export function getStatesRequiringStateLicense(): StateLicensingConfig[] {
  return Object.values(STATE_LICENSING_CONFIGS).filter(s => s.requiresStateLicense);
}

/** Get all states where a specific trade requires a state license */
export function getStatesRequiringTradeicense(
  trade: 'electrician' | 'plumber' | 'hvac' | 'roofing' | 'generalContractor'
): StateLicensingConfig[] {
  return Object.values(STATE_LICENSING_CONFIGS).filter(s => s[trade].requiresLicense);
}

/** Get all states sorted alphabetically */
export function getAllStatesSorted(): StateLicensingConfig[] {
  return Object.values(STATE_LICENSING_CONFIGS).sort((a, b) =>
    a.stateName.localeCompare(b.stateName)
  );
}

/** Get states with reciprocity for a given state */
export function getReciprocityStates(stateCode: string): StateLicensingConfig[] {
  const config = STATE_LICENSING_CONFIGS[stateCode.toUpperCase()];
  if (!config) return [];
  return config.reciprocityStates
    .map(code => STATE_LICENSING_CONFIGS[code])
    .filter(Boolean);
}

/** Get licensing summary for a state (for display) */
export function getStateLicensingSummary(stateCode: string): {
  stateName: string;
  model: string;
  requiresGcLicense: boolean;
  requiresElectricalLicense: boolean;
  requiresPlumbingLicense: boolean;
  requiresHvacLicense: boolean;
  requiresRoofingLicense: boolean;
  boardUrl: string;
} | undefined {
  const config = STATE_LICENSING_CONFIGS[stateCode.toUpperCase()];
  if (!config) return undefined;
  return {
    stateName: config.stateName,
    model: config.licensingModel,
    requiresGcLicense: config.generalContractor.requiresLicense,
    requiresElectricalLicense: config.electrician.requiresLicense,
    requiresPlumbingLicense: config.plumber.requiresLicense,
    requiresHvacLicense: config.hvac.requiresLicense,
    requiresRoofingLicense: config.roofing.requiresLicense,
    boardUrl: config.boardUrl,
  };
}

/** Count of states requiring state-level licensing */
export function getStateLicenseStats(): {
  stateLevel: number;
  localOnly: number;
  registration: number;
  hybrid: number;
} {
  const configs = Object.values(STATE_LICENSING_CONFIGS);
  return {
    stateLevel: configs.filter(c => c.licensingModel === 'state').length,
    localOnly: configs.filter(c => c.licensingModel === 'local').length,
    registration: configs.filter(c => c.licensingModel === 'registration').length,
    hybrid: configs.filter(c => c.licensingModel === 'hybrid').length,
  };
}
