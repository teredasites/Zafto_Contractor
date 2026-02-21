// ZAFTO Trade-Specific Measurement Formulas (SK13)
// Roofing, fencing, concrete, landscaping, siding, solar, gutter, painting,
// and interior trade upgrades. All measurements in imperial (ft/in/sq ft).

// ── Roofing ──

export interface RoofingCalc {
  roofSquares: number; // area / 100
  ridgeCaps: number; // ridge length / 12" coverage = linear ft
  starterStrip: number; // eave length (linear ft)
  iceWaterShield: number; // (eave length × 3ft + valley length × 3ft) sq ft
  dripEdge: number; // eave + rake length (linear ft)
  stepFlashing: number; // wall intersection length (linear ft)
  pipeBoots: number;
  ventCount: number; // attic sq ft / 150
}

export function calcRoofing(
  totalRoofSqFt: number,
  eaveLengthFt: number,
  rakeLengthFt: number,
  ridgeLengthFt: number,
  valleyLengthFt: number,
  wallIntersectionFt: number,
  pipeBootCount: number,
  atticSqFt: number,
): RoofingCalc {
  return {
    roofSquares: totalRoofSqFt / 100,
    ridgeCaps: ridgeLengthFt,
    starterStrip: eaveLengthFt,
    iceWaterShield: (eaveLengthFt * 3) + (valleyLengthFt * 3),
    dripEdge: eaveLengthFt + rakeLengthFt,
    stepFlashing: wallIntersectionFt,
    pipeBoots: pipeBootCount,
    ventCount: Math.ceil(atticSqFt / 150),
  };
}

// ── Fencing ──

export interface FencingCalc {
  totalLinearFt: number;
  postCount: number;
  railCount: number;
  picketCount: number;
  gateCount: number;
  concretePerPost: number; // bags (60lb)
}

export function calcFencing(
  lengthFt: number,
  postSpacingFt: number,
  railsPerSection: number,
  picketWidthIn: number,
  gateCount: number,
  heightFt: number,
  holeDiameterIn: number = 10,
  holeDepthIn: number = 36,
): FencingCalc {
  const postCount = Math.ceil(lengthFt / postSpacingFt) + 1;
  // Concrete per post: hole volume in cu ft / 0.45 cu ft per 60lb bag
  const holeVolumeCuFt = (Math.PI * (holeDiameterIn / 24) ** 2 * (holeDepthIn / 12));
  const bagsPerPost = Math.ceil(holeVolumeCuFt / 0.45);

  return {
    totalLinearFt: lengthFt,
    postCount,
    railCount: Math.max(0, postCount - 1) * railsPerSection,
    picketCount: picketWidthIn > 0 ? Math.ceil((lengthFt * 12) / picketWidthIn) : 0,
    gateCount,
    concretePerPost: bagsPerPost,
  };
}

// ── Concrete ──

export interface ConcreteCalc {
  cubicYards: number;
  rebarLinearFt: number; // at grid spacing
  wireMeshSqFt: number;
  expansionJoints: number; // every 10ft of linear pour
  formLinearFt: number;
  vaporBarrierSqFt: number; // area + 6" overlap
}

export function calcConcrete(
  areaSqFt: number,
  depthIn: number,
  perimeterFt: number,
  rebarSpacingIn: number = 18,
  wastePct: number = 0.05,
): ConcreteCalc {
  const depthFt = depthIn / 12;
  const cubicYards = (areaSqFt * depthFt / 27) * (1 + wastePct);

  // Rebar grid: (length / spacing + 1) * width + (width / spacing + 1) * length
  const side = Math.sqrt(areaSqFt);
  const barsPerDir = Math.ceil((side * 12) / rebarSpacingIn) + 1;
  const rebarLinearFt = barsPerDir * side * 2; // both directions

  return {
    cubicYards,
    rebarLinearFt,
    wireMeshSqFt: areaSqFt,
    expansionJoints: Math.max(1, Math.ceil(perimeterFt / 20)), // every 10ft of pour = perimeter/20
    formLinearFt: perimeterFt,
    vaporBarrierSqFt: areaSqFt * 1.1, // +10% for overlap
  };
}

// ── Landscaping ──

export interface LandscapingCalc {
  mulchCuYd: number;
  topsoilCuYd: number;
  sodPallets: number; // 450 sf per pallet
  seedBags: number; // area / coverage per bag
  plantCount: number; // area / spacing²
  edgingLinearFt: number;
  irrigationZones: number; // area / zone coverage
  sprinklerHeadsPerZone: number;
}

export function calcLandscaping(
  areaSqFt: number,
  perimeterFt: number,
  mulchDepthIn: number = 3,
  topsoilDepthIn: number = 0,
  plantSpacingFt: number = 3,
  seedCoverageSqFt: number = 5000, // per bag
  zoneCoverageSqFt: number = 1500,
  headsPerZone: number = 8,
): LandscapingCalc {
  return {
    mulchCuYd: (areaSqFt * mulchDepthIn) / (12 * 27),
    topsoilCuYd: topsoilDepthIn > 0 ? (areaSqFt * topsoilDepthIn) / (12 * 27) : 0,
    sodPallets: Math.ceil(areaSqFt / 450),
    seedBags: seedCoverageSqFt > 0 ? Math.ceil(areaSqFt / seedCoverageSqFt) : 0,
    plantCount: plantSpacingFt > 0 ? Math.ceil(areaSqFt / (plantSpacingFt * plantSpacingFt)) : 0,
    edgingLinearFt: perimeterFt,
    irrigationZones: zoneCoverageSqFt > 0 ? Math.ceil(areaSqFt / zoneCoverageSqFt) : 0,
    sprinklerHeadsPerZone: headsPerZone,
  };
}

// ── Siding ──

export interface SidingCalc {
  sidingSquares: number; // (wall area - openings) / 100
  starterStrip: number; // perimeter linear ft
  jChannel: number; // window/door perimeter linear ft
  cornerPosts: number;
  soffitSqFt: number; // overhang area
  fasciaLinearFt: number; // eave + rake
  houseWrapSqFt: number; // wall area + 6" overlap
}

export function calcSiding(
  wallAreaSqFt: number,
  openingsSqFt: number,
  perimeterFt: number,
  windowDoorPerimeterFt: number,
  cornerCount: number,
  wallHeightFt: number,
  overhangWidthFt: number,
  eaveRakeLengthFt: number,
): SidingCalc {
  const netArea = wallAreaSqFt - openingsSqFt;
  return {
    sidingSquares: netArea / 100,
    starterStrip: perimeterFt,
    jChannel: windowDoorPerimeterFt,
    cornerPosts: cornerCount,
    soffitSqFt: perimeterFt * overhangWidthFt,
    fasciaLinearFt: eaveRakeLengthFt,
    houseWrapSqFt: wallAreaSqFt * 1.1,
  };
}

// ── Solar ──

export interface SolarCalc {
  panelCount: number;
  arrayKw: number;
  rackingLinearFt: number;
  conduitRunFt: number;
  inverterSizeKw: number;
  estimatedAnnualKwh: number;
}

export function calcSolar(
  availableRoofSqFt: number,
  panelWidthFt: number = 3.3,
  panelHeightFt: number = 5.4,
  panelWatts: number = 400,
  roofToInverterFt: number = 30,
  sunHoursPerDay: number = 5,
): SolarCalc {
  const panelArea = panelWidthFt * panelHeightFt;
  const panelCount = Math.floor(availableRoofSqFt / panelArea);
  const arrayKw = (panelCount * panelWatts) / 1000;

  return {
    panelCount,
    arrayKw,
    rackingLinearFt: panelCount * panelWidthFt,
    conduitRunFt: roofToInverterFt,
    inverterSizeKw: arrayKw * 1.2,
    estimatedAnnualKwh: Math.round(arrayKw * sunHoursPerDay * 365 * 0.8),
  };
}

// ── Gutters ──

export interface GutterCalc {
  gutterLinearFt: number;
  downspoutCount: number;
  downspoutExtensions: number;
  insideCorners: number;
  outsideCorners: number;
  endCaps: number;
  hangers: number; // 1 per 2ft
  splashBlocks: number;
}

export function calcGutters(
  gutterLengthFt: number,
  insideCorners: number = 0,
  outsideCorners: number = 0,
  downspoutSpacingFt: number = 35,
): GutterCalc {
  const downspoutCount = Math.max(1, Math.ceil(gutterLengthFt / downspoutSpacingFt));
  return {
    gutterLinearFt: gutterLengthFt,
    downspoutCount,
    downspoutExtensions: downspoutCount,
    insideCorners,
    outsideCorners,
    endCaps: 2 + (insideCorners + outsideCorners),
    hangers: Math.ceil(gutterLengthFt / 2),
    splashBlocks: downspoutCount,
  };
}

// ── Painting ──

export interface PaintingCalc {
  wallSqFt: number; // perimeter × height − openings
  ceilingSqFt: number;
  gallons: number; // sq ft / 350 per gallon × coats
  trimLinearFt: number;
  primerGallons: number;
  caulkTubes: number; // linear ft / 30ft per tube
}

export function calcPainting(
  perimeterFt: number,
  wallHeightFt: number,
  openingsSqFt: number,
  ceilingSqFt: number,
  trimLinearFt: number,
  coats: number = 2,
): PaintingCalc {
  const wallSqFt = (perimeterFt * wallHeightFt) - openingsSqFt;
  const totalSqFt = wallSqFt + ceilingSqFt;
  return {
    wallSqFt,
    ceilingSqFt,
    gallons: Math.ceil((totalSqFt / 350) * coats),
    trimLinearFt,
    primerGallons: Math.ceil(totalSqFt / 400),
    caulkTubes: Math.ceil(trimLinearFt / 30),
  };
}

// ── Interior Trade Upgrades ──

/** Electrical: circuit count by room load (NEC simplified) */
export function calcCircuitsByLoad(totalWatts: number, voltAmps: number = 1920): number {
  // 1920 VA per 15A circuit at 80% derating
  return Math.ceil(totalWatts / voltAmps);
}

/** Plumbing: fixture units to DFU drain sizing */
export function calcDrainSize(totalDfu: number): string {
  if (totalDfu <= 3) return '1.5"';
  if (totalDfu <= 6) return '2"';
  if (totalDfu <= 12) return '2.5"';
  if (totalDfu <= 32) return '3"';
  if (totalDfu <= 160) return '4"';
  return '6"';
}

/** HVAC: simplified BTU per room */
export function calcBtuPerRoom(areaSqFt: number, btuPerSqFt: number = 25): number {
  return areaSqFt * btuPerSqFt;
}

/** Drywall: sheets for given wall/ceiling area */
export function calcDrywallSheets(areaSqFt: number, sheetSqFt: number = 32, wastePct: number = 0.10): number {
  return Math.ceil((areaSqFt / sheetSqFt) * (1 + wastePct));
}

/** Tape/mud: 1 box per 7-8 sheets */
export function calcTapeMudBoxes(sheetCount: number, sheetsPerBox: number = 7): number {
  return Math.ceil(sheetCount / sheetsPerBox);
}

// =============================================================================
// COMMERCIAL FORMULAS (DEPTH25)
// =============================================================================

// ── Commercial Roofing (Flat / Low-Slope) ──

export interface CommercialRoofingCalc {
  membraneSqFt: number; // total membrane area + waste
  insulationSqFt: number;
  insulationBoardCount: number; // 4x8 sheets
  parapetFlashingLf: number;
  roofDrainCount: number;
  overflowDrainCount: number;
  walkPadSqFt: number;
  copingCapLf: number;
  roofCricketCount: number;
  screwsPerSqFt: number; // mechanical attachment
  adhesiveBuckets: number; // for fully adhered
}

export function calcCommercialRoofing(
  roofAreaSqFt: number,
  parapetPerimeterLf: number,
  drainSpacingFt: number = 80,
  walkPadPathLf: number = 0,
  roofCricketCount: number = 0,
  wastePct: number = 0.08,
  isFullyAdhered: boolean = true,
): CommercialRoofingCalc {
  const membraneSqFt = roofAreaSqFt * (1 + wastePct);
  const insulationSqFt = roofAreaSqFt * (1 + 0.05);
  const drainCount = Math.max(2, Math.ceil(roofAreaSqFt / (drainSpacingFt * drainSpacingFt)));
  return {
    membraneSqFt,
    insulationSqFt,
    insulationBoardCount: Math.ceil(insulationSqFt / 32), // 4x8 = 32 sqft
    parapetFlashingLf: parapetPerimeterLf,
    roofDrainCount: drainCount,
    overflowDrainCount: drainCount, // 1:1 ratio per code
    walkPadSqFt: walkPadPathLf * 2.5, // 30" wide walk pads
    copingCapLf: parapetPerimeterLf,
    roofCricketCount,
    screwsPerSqFt: isFullyAdhered ? 0 : 1.2,
    adhesiveBuckets: isFullyAdhered ? Math.ceil(membraneSqFt / 200) : 0, // ~200 sqft per 5-gal bucket
  };
}

// ── Fire Sprinkler System ──

export interface SprinklerCalc {
  sprinklerHeadCount: number;
  sprinklerMainLf: number;
  branchLineLf: number;
  riserCount: number;
  fireDeptConnectionCount: number;
  fireAlarmPanelCount: number;
  pullStationCount: number; // per exit
  smokeDetectorCount: number;
  hornStrobeCount: number;
  fireExtinguisherCount: number;
}

export function calcSprinklerSystem(
  floorAreaSqFt: number,
  exitCount: number,
  floorCount: number = 1,
  coveragePerHead: number = 130, // light hazard: 130 sqft, ordinary: 130, extra: 100
  maxTravelDistanceFt: number = 75, // extinguisher travel
): SprinklerCalc {
  const headsPerFloor = Math.ceil(floorAreaSqFt / coveragePerHead);
  const totalHeads = headsPerFloor * floorCount;
  const branchesPerFloor = Math.ceil(Math.sqrt(headsPerFloor));
  return {
    sprinklerHeadCount: totalHeads,
    sprinklerMainLf: Math.ceil(Math.sqrt(floorAreaSqFt)) * floorCount,
    branchLineLf: branchesPerFloor * Math.ceil(Math.sqrt(floorAreaSqFt)) * floorCount,
    riserCount: Math.max(1, floorCount),
    fireDeptConnectionCount: 1,
    fireAlarmPanelCount: 1,
    pullStationCount: exitCount * floorCount,
    smokeDetectorCount: Math.ceil(floorAreaSqFt / 900) * floorCount, // ~30ft spacing = 900sqft
    hornStrobeCount: Math.ceil(floorAreaSqFt / 2500) * floorCount, // per NFPA 72
    fireExtinguisherCount: Math.ceil(floorAreaSqFt / (Math.PI * maxTravelDistanceFt * maxTravelDistanceFt)) * floorCount,
  };
}

// ── Parking Lot ──

export interface ParkingLotCalc {
  stallCount: number;
  handicapStallCount: number;
  vanAccessibleCount: number;
  stripingLf: number; // total striping
  sealcoatSqFt: number;
  asphaltTons: number;
  bumpStops: number;
  lightPoleCount: number;
}

export function calcParkingLot(
  lotAreaSqFt: number,
  stallWidth: number = 9, // feet
  stallDepth: number = 18, // feet
  aisleWidth: number = 24, // feet (two-way)
  totalSpacePct: number = 0.60, // 60% usable after aisles/landscaping
  asphaltDepthIn: number = 3,
): ParkingLotCalc {
  const usableArea = lotAreaSqFt * totalSpacePct;
  const stallArea = stallWidth * stallDepth;
  const stallCount = Math.floor(usableArea / stallArea);
  // ADA: up to 25 spaces = 1 accessible, 26-50 = 2, etc.
  const handicapCount = stallCount <= 25 ? 1 :
    stallCount <= 50 ? 2 :
    stallCount <= 75 ? 3 :
    stallCount <= 100 ? 4 :
    Math.ceil(stallCount * 0.04); // 4% above 100
  const vanAccessible = Math.max(1, Math.ceil(handicapCount / 6)); // 1 per 6 accessible
  return {
    stallCount,
    handicapStallCount: handicapCount,
    vanAccessibleCount: vanAccessible,
    stripingLf: stallCount * (stallWidth + stallDepth) * 2,
    sealcoatSqFt: lotAreaSqFt,
    asphaltTons: (lotAreaSqFt * (asphaltDepthIn / 12) * 145) / 2000, // 145 lbs/cuft density
    bumpStops: stallCount,
    lightPoleCount: Math.max(2, Math.ceil(lotAreaSqFt / 10000)), // ~1 per 10,000 sqft
  };
}

// ── ADA Compliance Calcs ──

export interface AdaComplianceCalc {
  accessibleRouteWidthMin: number; // 36" min, 44" preferred
  restroomClearanceCircle: number; // 60" turning radius
  doorClearanceWidth: number; // 32" min clear
  rampLengthFt: number; // for given rise
  rampLandings: number;
  grabBarSets: number;
  adaSignageCount: number;
}

export function calcAdaCompliance(
  riseInches: number = 0,
  restroomCount: number = 1,
  doorCount: number = 1,
): AdaComplianceCalc {
  // Ramp: max 1:12 slope (1" rise per 12" run), landing every 30" of rise
  const rampLengthFt = (riseInches * 12) / 12; // 1:12 ratio in feet
  const rampLandings = Math.ceil(riseInches / 30) + 1; // top + bottom + intermediate
  return {
    accessibleRouteWidthMin: 44, // inches
    restroomClearanceCircle: 60, // inches
    doorClearanceWidth: 32, // inches min
    rampLengthFt,
    rampLandings,
    grabBarSets: restroomCount * 2, // side wall + rear
    adaSignageCount: restroomCount + doorCount,
  };
}

// ── Commercial Roof Material Specs (physical properties only — NO pricing) ──
// Pricing comes from estimate_pricing table (Rule #24: ZERO hardcoded pricing).

export const COMMERCIAL_ROOF_MATERIAL_SPECS: Record<string, { rValue: number; warrantyRange: string; weightPerSqFt: number }> = {
  tpoWhite60: { rValue: 0, warrantyRange: '15-30 years', weightPerSqFt: 0.29 },
  tpoWhite80: { rValue: 0, warrantyRange: '20-30 years', weightPerSqFt: 0.38 },
  epdmBlack60: { rValue: 0, warrantyRange: '15-25 years', weightPerSqFt: 0.33 },
  epdmBlack90: { rValue: 0, warrantyRange: '20-30 years', weightPerSqFt: 0.50 },
  modBitSBS3Ply: { rValue: 0, warrantyRange: '15-20 years', weightPerSqFt: 1.50 },
  bur4Ply: { rValue: 0, warrantyRange: '15-25 years', weightPerSqFt: 3.00 },
  pvcMembrane: { rValue: 0, warrantyRange: '20-30 years', weightPerSqFt: 0.35 },
  spf: { rValue: 6.5, warrantyRange: '15-25 years', weightPerSqFt: 0.30 },
  metalStandingSeamCommercial: { rValue: 0, warrantyRange: '30-50 years', weightPerSqFt: 1.50 },
  greenRoofExtensive: { rValue: 2.0, warrantyRange: '30-50 years', weightPerSqFt: 15.00 },
};
