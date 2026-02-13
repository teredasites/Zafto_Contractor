// Supabase Edge Function: recon-trade-estimator
// Accepts scan_id + optional trade filter
// 1. Read property_scans + roof_measurements + property_features + property_structures
// 2. Derive wall measurements from building footprint
// 3. Calculate trade-specific bid data for all 10 trades
// 4. Generate material lists with waste factors
// 5. Insert wall_measurements + trade_bid_data records

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

const round = (n: number, d = 2) => Math.round(n * Math.pow(10, d)) / Math.pow(10, d)

// ============================================================================
// WASTE FACTOR ENGINE
// ============================================================================

interface WasteFactors {
  basePct: number
  complexityAdder: number
  totalPct: number
}

function roofingWaste(shape: string, facetCount: number): WasteFactors {
  let basePct = 12
  let complexityAdder = 0

  if (shape === 'gable' && facetCount <= 4) { basePct = 10; complexityAdder = 0 }
  else if (shape === 'gable') { basePct = 12; complexityAdder = 2 }
  else if (shape === 'hip') { basePct = 15; complexityAdder = 2 }
  else if (shape === 'flat') { basePct = 5; complexityAdder = 0 }
  else if (shape === 'gambrel') { basePct = 12; complexityAdder = 3 }
  else if (shape === 'mansard') { basePct = 15; complexityAdder = 3 }
  else { basePct = 15; complexityAdder = facetCount > 10 ? 10 : 5 }

  return { basePct, complexityAdder, totalPct: basePct + complexityAdder }
}

function sidingWaste(): WasteFactors {
  return { basePct: 10, complexityAdder: 2, totalPct: 12 }
}

function paintWaste(): WasteFactors {
  return { basePct: 5, complexityAdder: 5, totalPct: 10 }
}

function concreteWaste(): WasteFactors {
  return { basePct: 5, complexityAdder: 5, totalPct: 10 }
}

function fencingWaste(): WasteFactors {
  return { basePct: 5, complexityAdder: 0, totalPct: 5 }
}

// ============================================================================
// WALL DERIVATION
// ============================================================================

interface WallResult {
  totalWallArea: number
  totalSidingArea: number
  perFace: Array<{
    direction: string
    width_ft: number
    height_ft: number
    area_sqft: number
    window_count_est: number
    door_count_est: number
    net_area_sqft: number
  }>
  stories: number
  avgWallHeight: number
  windowAreaEst: number
  doorAreaEst: number
  trimLinearFt: number
  fasciaLinearFt: number
  soffitSqft: number
}

function deriveWallMeasurements(
  footprintSqft: number,
  stories: number,
  yearBuilt: number | null,
  roofEaveLf: number,
): WallResult {
  const side = Math.sqrt(footprintSqft)
  // 9ft ceiling if post-2000, 8ft otherwise
  const wallHeight = yearBuilt && yearBuilt > 2000 ? 9 : 8
  const totalHeight = wallHeight * stories
  const perimeter = side * 4

  // Standard estimates: 15% windows, 2 doors (21 sqft each) per story
  const totalWallArea = perimeter * totalHeight
  const windowArea = totalWallArea * 0.15
  const doorArea = stories * 2 * 21 // 2 doors per story
  const totalSidingArea = totalWallArea - windowArea - doorArea

  // Per-face breakdown (assume roughly rectangular)
  const directions = ['north', 'east', 'south', 'west']
  const widths = [side * 1.2, side * 0.8, side * 1.2, side * 0.8] // slightly rectangular
  const perFace = directions.map((dir, i) => {
    const width = widths[i]
    const area = width * totalHeight
    const windowCount = Math.round((width * totalHeight * 0.15) / 12) // ~12 sqft per window
    const doorCount = i === 0 ? 1 : i === 2 ? 1 : 0 // front + back doors
    const winArea = windowCount * 12
    const drArea = doorCount * 21
    return {
      direction: dir,
      width_ft: round(width),
      height_ft: round(totalHeight),
      area_sqft: round(area),
      window_count_est: windowCount,
      door_count_est: doorCount,
      net_area_sqft: round(area - winArea - drArea),
    }
  })

  // Trim = perimeter of all windows + doors
  const totalWindows = perFace.reduce((s, f) => s + f.window_count_est, 0)
  const totalDoors = perFace.reduce((s, f) => s + f.door_count_est, 0)
  const trimLf = totalWindows * 14 + totalDoors * 17 // window ~14 LF trim, door ~17 LF

  // Fascia = eave length (from roof) or approximate with perimeter
  const fasciaLf = roofEaveLf > 0 ? roofEaveLf : perimeter

  // Soffit = fascia * ~1.5ft depth
  const soffitSqft = fasciaLf * 1.5

  return {
    totalWallArea: round(totalWallArea),
    totalSidingArea: round(totalSidingArea),
    perFace,
    stories,
    avgWallHeight: round(totalHeight),
    windowAreaEst: round(windowArea),
    doorAreaEst: round(doorArea),
    trimLinearFt: round(trimLf),
    fasciaLinearFt: round(fasciaLf),
    soffitSqft: round(soffitSqft),
  }
}

// ============================================================================
// TRADE PIPELINE CALCULATORS
// ============================================================================

interface MaterialItem {
  item: string
  quantity: number
  unit: string
  waste_pct: number
  total_with_waste: number
}

interface TradeResult {
  measurements: Record<string, unknown>
  material_list: MaterialItem[]
  waste_factor_pct: number
  complexity_score: number
  recommended_crew_size: number
  estimated_labor_hours: number
}

function roofingPipeline(
  totalAreaSqft: number,
  totalSquares: number,
  shape: string,
  facetCount: number,
  ridgeLf: number,
  hipLf: number,
  valleyLf: number,
  eaveLf: number,
  rakeLf: number,
): TradeResult {
  const waste = roofingWaste(shape, facetCount)
  const squaresWithWaste = round(totalSquares * (1 + waste.totalPct / 100))
  const bundlesPerSquare = 3

  const materials: MaterialItem[] = [
    { item: 'Architectural Shingles', quantity: squaresWithWaste, unit: 'SQ', waste_pct: waste.totalPct, total_with_waste: squaresWithWaste },
    { item: 'Shingle Bundles', quantity: round(squaresWithWaste * bundlesPerSquare), unit: 'bundles', waste_pct: 0, total_with_waste: round(squaresWithWaste * bundlesPerSquare) },
    { item: 'Synthetic Underlayment', quantity: Math.ceil(totalAreaSqft / 1000), unit: 'rolls', waste_pct: 5, total_with_waste: Math.ceil(totalAreaSqft / 1000 * 1.05) },
    { item: 'Ridge Cap', quantity: round(ridgeLf + hipLf), unit: 'LF', waste_pct: 5, total_with_waste: round((ridgeLf + hipLf) * 1.05) },
    { item: 'Starter Strip', quantity: round(eaveLf + rakeLf), unit: 'LF', waste_pct: 5, total_with_waste: round((eaveLf + rakeLf) * 1.05) },
    { item: 'Drip Edge', quantity: round(eaveLf + rakeLf), unit: 'LF', waste_pct: 5, total_with_waste: round((eaveLf + rakeLf) * 1.05) },
    { item: 'Ice & Water Shield', quantity: Math.ceil((eaveLf * 3 + valleyLf * 3) / 67), unit: 'rolls', waste_pct: 0, total_with_waste: Math.ceil((eaveLf * 3 + valleyLf * 3) / 67) },
    { item: 'Step Flashing', quantity: 50, unit: 'pcs', waste_pct: 0, total_with_waste: 50 },
    { item: 'Roofing Nails', quantity: Math.ceil(squaresWithWaste * 2.5), unit: 'lbs', waste_pct: 0, total_with_waste: Math.ceil(squaresWithWaste * 2.5) },
  ]

  // Labor: ~1.5 hrs per square for standard, +20% for complex
  const complexityMult = facetCount > 8 ? 1.3 : facetCount > 4 ? 1.15 : 1
  const laborHrs = round(totalSquares * 1.5 * complexityMult)
  const crewSize = totalSquares > 30 ? 4 : totalSquares > 15 ? 3 : 2

  return {
    measurements: {
      total_area_sqft: round(totalAreaSqft),
      total_squares: round(totalSquares),
      squares_with_waste: squaresWithWaste,
      ridge_lf: round(ridgeLf),
      hip_lf: round(hipLf),
      valley_lf: round(valleyLf),
      eave_lf: round(eaveLf),
      rake_lf: round(rakeLf),
      pitch: shape,
      facet_count: facetCount,
    },
    material_list: materials,
    waste_factor_pct: waste.totalPct,
    complexity_score: round(Math.min(10, facetCount * 0.8)),
    recommended_crew_size: crewSize,
    estimated_labor_hours: laborHrs,
  }
}

function sidingPipeline(wall: WallResult): TradeResult {
  const waste = sidingWaste()
  const sidingSquares = round(wall.totalSidingArea / 100)
  const sidingWithWaste = round(sidingSquares * (1 + waste.totalPct / 100))
  const perimeter = wall.perFace.reduce((s, f) => s + f.width_ft, 0)
  const cornerCount = 4 * wall.stories

  const materials: MaterialItem[] = [
    { item: 'Siding', quantity: sidingWithWaste, unit: 'SQ', waste_pct: waste.totalPct, total_with_waste: sidingWithWaste },
    { item: 'J-Channel', quantity: round(wall.trimLinearFt + perimeter), unit: 'LF', waste_pct: 5, total_with_waste: round((wall.trimLinearFt + perimeter) * 1.05) },
    { item: 'Corner Posts', quantity: cornerCount, unit: 'pcs', waste_pct: 0, total_with_waste: cornerCount },
    { item: 'Starter Strip', quantity: round(perimeter), unit: 'LF', waste_pct: 5, total_with_waste: round(perimeter * 1.05) },
    { item: 'Utility Trim', quantity: round(wall.trimLinearFt * 0.5), unit: 'LF', waste_pct: 5, total_with_waste: round(wall.trimLinearFt * 0.5 * 1.05) },
    { item: 'Siding Nails', quantity: Math.ceil(sidingWithWaste * 2), unit: 'lbs', waste_pct: 0, total_with_waste: Math.ceil(sidingWithWaste * 2) },
    { item: 'Housewrap', quantity: Math.ceil(wall.totalWallArea / 900), unit: 'rolls', waste_pct: 5, total_with_waste: Math.ceil(wall.totalWallArea / 900 * 1.05) },
  ]

  return {
    measurements: {
      total_wall_area_sqft: wall.totalWallArea,
      siding_area_sqft: wall.totalSidingArea,
      siding_squares: sidingSquares,
      corner_count: cornerCount,
      window_count: wall.perFace.reduce((s, f) => s + f.window_count_est, 0),
      door_count: wall.perFace.reduce((s, f) => s + f.door_count_est, 0),
      trim_lf: wall.trimLinearFt,
    },
    material_list: materials,
    waste_factor_pct: waste.totalPct,
    complexity_score: round(Math.min(10, wall.stories * 2 + (cornerCount > 8 ? 2 : 0))),
    recommended_crew_size: wall.totalSidingArea > 2000 ? 3 : 2,
    estimated_labor_hours: round(wall.totalSidingArea / 200), // ~200 sqft/hr
  }
}

function guttersPipeline(eaveLf: number, rakeLf: number, facetCount: number): TradeResult {
  const gutterLf = round(eaveLf)
  const downspoutCount = Math.max(2, Math.ceil(gutterLf / 35))
  const downspoutLf = downspoutCount * 12 // ~12 ft per downspout (avg 1.5 stories)
  const cornerCount = Math.max(2, Math.ceil(facetCount / 2))

  const materials: MaterialItem[] = [
    { item: 'Gutter (5" K-Style)', quantity: gutterLf, unit: 'LF', waste_pct: 5, total_with_waste: round(gutterLf * 1.05) },
    { item: 'Downspout (3x4)', quantity: round(downspoutLf), unit: 'LF', waste_pct: 5, total_with_waste: round(downspoutLf * 1.05) },
    { item: 'Downspout Elbows', quantity: downspoutCount * 3, unit: 'pcs', waste_pct: 0, total_with_waste: downspoutCount * 3 },
    { item: 'End Caps', quantity: downspoutCount * 2, unit: 'pcs', waste_pct: 0, total_with_waste: downspoutCount * 2 },
    { item: 'Gutter Hangers', quantity: Math.ceil(gutterLf / 2), unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(gutterLf / 2 * 1.05) },
    { item: 'Outlet Drops', quantity: downspoutCount, unit: 'pcs', waste_pct: 0, total_with_waste: downspoutCount },
    { item: 'Inside/Outside Corners', quantity: cornerCount, unit: 'pcs', waste_pct: 0, total_with_waste: cornerCount },
  ]

  return {
    measurements: {
      gutter_lf: gutterLf,
      downspout_count: downspoutCount,
      downspout_lf: round(downspoutLf),
      corner_count: cornerCount,
      hanger_count: Math.ceil(gutterLf / 2),
    },
    material_list: materials,
    waste_factor_pct: 5,
    complexity_score: round(Math.min(10, cornerCount * 0.8 + (gutterLf > 200 ? 2 : 0))),
    recommended_crew_size: 2,
    estimated_labor_hours: round(gutterLf / 30), // ~30 LF/hr
  }
}

function solarPipeline(
  facets: Array<{ area_sqft: number; azimuth_degrees: number; annual_sun_hours: number | null; shade_factor: number | null }>,
  maxSunHours: number,
): TradeResult {
  // Usable facets: south-facing (135-225°) or west-facing (225-315°) with good sun
  const usable = facets.filter(f => {
    const az = f.azimuth_degrees
    return (az >= 90 && az <= 315) && (f.annual_sun_hours || 0) > maxSunHours * 0.5
  })

  const usableArea = usable.reduce((s, f) => s + f.area_sqft, 0)
  const panelSqft = 17.5 // ~17.5 sqft per standard panel
  const maxPanels = Math.floor(usableArea * 0.8 / panelSqft) // 80% usable
  const kw = round(maxPanels * 0.4) // ~400W per panel
  const annualKwh = round(kw * 1200) // ~1200 kWh/kW avg US

  const materials: MaterialItem[] = [
    { item: 'Solar Panels (400W)', quantity: maxPanels, unit: 'panels', waste_pct: 0, total_with_waste: maxPanels },
    { item: 'Micro Inverters', quantity: maxPanels, unit: 'pcs', waste_pct: 0, total_with_waste: maxPanels },
    { item: 'Racking/Rails', quantity: round(maxPanels * 5.5), unit: 'LF', waste_pct: 10, total_with_waste: round(maxPanels * 5.5 * 1.1) },
    { item: 'Roof Attachments', quantity: Math.ceil(maxPanels * 1.5), unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(maxPanels * 1.5 * 1.05) },
    { item: 'Wire (10 AWG)', quantity: round(maxPanels * 15), unit: 'ft', waste_pct: 10, total_with_waste: round(maxPanels * 15 * 1.1) },
    { item: 'Combiner Box', quantity: 1, unit: 'pcs', waste_pct: 0, total_with_waste: 1 },
  ]

  return {
    measurements: {
      usable_roof_area_sqft: round(usableArea),
      max_panel_count: maxPanels,
      system_size_kw: kw,
      estimated_annual_kwh: annualKwh,
      usable_facets: usable.length,
      total_facets: facets.length,
    },
    material_list: materials,
    waste_factor_pct: 5,
    complexity_score: round(Math.min(10, usable.length * 1.5 + (kw > 10 ? 2 : 0))),
    recommended_crew_size: maxPanels > 20 ? 3 : 2,
    estimated_labor_hours: round(maxPanels * 1.2), // ~1.2 hrs per panel
  }
}

function paintingPipeline(wall: WallResult, livingSqft: number): TradeResult {
  const waste = paintWaste()
  const exteriorSqft = wall.totalWallArea + wall.trimLinearFt * 0.5 + wall.fasciaLinearFt * 0.75 + wall.soffitSqft
  // Interior: living sqft × 3.5 wall factor (walls + ceiling)
  const interiorSqft = livingSqft > 0 ? livingSqft * 3.5 : 0
  const extGallons = Math.ceil(exteriorSqft / 350) // ~350 sqft/gallon
  const intGallons = Math.ceil(interiorSqft / 400) // ~400 sqft/gallon
  const primerGallons = Math.ceil((exteriorSqft + interiorSqft) / 400)

  const materials: MaterialItem[] = [
    { item: 'Exterior Paint', quantity: extGallons, unit: 'gallons', waste_pct: waste.totalPct, total_with_waste: Math.ceil(extGallons * (1 + waste.totalPct / 100)) },
    { item: 'Interior Paint', quantity: intGallons, unit: 'gallons', waste_pct: waste.totalPct, total_with_waste: Math.ceil(intGallons * (1 + waste.totalPct / 100)) },
    { item: 'Primer', quantity: primerGallons, unit: 'gallons', waste_pct: 5, total_with_waste: Math.ceil(primerGallons * 1.05) },
    { item: 'Trim Paint', quantity: Math.ceil(wall.trimLinearFt / 150), unit: 'quarts', waste_pct: 10, total_with_waste: Math.ceil(wall.trimLinearFt / 150 * 1.1) },
    { item: 'Caulk', quantity: Math.ceil((wall.perFace.reduce((s, f) => s + f.window_count_est, 0) + wall.perFace.reduce((s, f) => s + f.door_count_est, 0)) * 0.5), unit: 'tubes', waste_pct: 0, total_with_waste: Math.ceil((wall.perFace.reduce((s, f) => s + f.window_count_est, 0) + wall.perFace.reduce((s, f) => s + f.door_count_est, 0)) * 0.5) },
    { item: 'Painter\'s Tape', quantity: Math.ceil(wall.trimLinearFt / 60), unit: 'rolls', waste_pct: 0, total_with_waste: Math.ceil(wall.trimLinearFt / 60) },
  ]

  return {
    measurements: {
      exterior_wall_sqft: wall.totalWallArea,
      exterior_paint_sqft: round(exteriorSqft),
      interior_paint_sqft: round(interiorSqft),
      trim_lf: wall.trimLinearFt,
      fascia_lf: wall.fasciaLinearFt,
      soffit_sqft: wall.soffitSqft,
    },
    material_list: materials,
    waste_factor_pct: waste.totalPct,
    complexity_score: round(Math.min(10, wall.stories * 2 + (exteriorSqft > 3000 ? 2 : 0))),
    recommended_crew_size: exteriorSqft > 3000 ? 3 : 2,
    estimated_labor_hours: round((exteriorSqft + interiorSqft) / 150), // ~150 sqft/hr
  }
}

function landscapingPipeline(
  lotSqft: number,
  footprintSqft: number,
  perimeter: number,
): TradeResult {
  const hardscapeEst = lotSqft * 0.1 // ~10% driveways/walkways
  const softscapeArea = Math.max(0, lotSqft - footprintSqft - hardscapeEst)
  const lawnArea = softscapeArea * 0.7
  const bedArea = softscapeArea * 0.3
  const fencePerimeterFt = Math.max(0, perimeter - Math.sqrt(footprintSqft))
  const mulchYards = round(bedArea / 100) // 1 yard per ~100 sqft at 3" depth

  const materials: MaterialItem[] = [
    { item: 'Sod/Seed', quantity: round(lawnArea), unit: 'sqft', waste_pct: 5, total_with_waste: round(lawnArea * 1.05) },
    { item: 'Mulch', quantity: mulchYards, unit: 'cubic yards', waste_pct: 10, total_with_waste: round(mulchYards * 1.1) },
    { item: 'Topsoil', quantity: round(bedArea / 200), unit: 'cubic yards', waste_pct: 10, total_with_waste: round(bedArea / 200 * 1.1) },
    { item: 'Edging', quantity: round(bedArea > 0 ? Math.sqrt(bedArea) * 4 : 0), unit: 'LF', waste_pct: 5, total_with_waste: round((bedArea > 0 ? Math.sqrt(bedArea) * 4 : 0) * 1.05) },
  ]

  return {
    measurements: {
      lot_sqft: round(lotSqft),
      building_footprint_sqft: round(footprintSqft),
      softscape_area_sqft: round(softscapeArea),
      lawn_area_sqft: round(lawnArea),
      landscape_bed_sqft: round(bedArea),
      hardscape_est_sqft: round(hardscapeEst),
      fence_perimeter_ft: round(fencePerimeterFt),
    },
    material_list: materials,
    waste_factor_pct: 8,
    complexity_score: round(Math.min(10, lotSqft / 5000 + (bedArea > 1000 ? 2 : 0))),
    recommended_crew_size: lotSqft > 10000 ? 4 : 2,
    estimated_labor_hours: round(softscapeArea / 500 + bedArea / 200),
  }
}

function fencingPipeline(lotPerimeterFt: number, footprintFrontage: number): TradeResult {
  const waste = fencingWaste()
  const fenceLf = Math.max(0, lotPerimeterFt - footprintFrontage)
  const postCount = Math.ceil(fenceLf / 8) + 1
  const railCount = postCount * 2 // top + bottom
  const panelCount = Math.ceil(fenceLf / 8)
  const gateCount = 2 // front + side
  const concreteBags = postCount // 1 bag per post

  const materials: MaterialItem[] = [
    { item: 'Fence Posts (4x4x8)', quantity: postCount, unit: 'pcs', waste_pct: waste.totalPct, total_with_waste: Math.ceil(postCount * (1 + waste.totalPct / 100)) },
    { item: 'Rails (2x4x8)', quantity: railCount, unit: 'pcs', waste_pct: waste.totalPct, total_with_waste: Math.ceil(railCount * (1 + waste.totalPct / 100)) },
    { item: 'Fence Panels (8ft)', quantity: panelCount, unit: 'panels', waste_pct: waste.totalPct, total_with_waste: Math.ceil(panelCount * (1 + waste.totalPct / 100)) },
    { item: 'Gate Kit', quantity: gateCount, unit: 'pcs', waste_pct: 0, total_with_waste: gateCount },
    { item: 'Concrete (Post Set)', quantity: concreteBags, unit: 'bags (50lb)', waste_pct: 5, total_with_waste: Math.ceil(concreteBags * 1.05) },
    { item: 'Fence Screws', quantity: panelCount * 20, unit: 'pcs', waste_pct: 10, total_with_waste: Math.ceil(panelCount * 20 * 1.1) },
  ]

  return {
    measurements: {
      fence_lf: round(fenceLf),
      post_count: postCount,
      panel_count: panelCount,
      gate_count: gateCount,
    },
    material_list: materials,
    waste_factor_pct: waste.totalPct,
    complexity_score: round(Math.min(10, fenceLf / 100 + gateCount)),
    recommended_crew_size: fenceLf > 200 ? 3 : 2,
    estimated_labor_hours: round(fenceLf / 20), // ~20 LF/hr
  }
}

function concretePipeline(lotSqft: number): TradeResult {
  const waste = concreteWaste()
  // Estimate: driveway ~15%, walkway ~3%, patio ~5% of lot
  const drivewaySqft = round(lotSqft * 0.08)
  const walkwaySqft = round(lotSqft * 0.02)
  const patioSqft = round(lotSqft * 0.04)
  const totalSqft = drivewaySqft + walkwaySqft + patioSqft
  // 4" thick: sqft × 0.33ft / 27 = cubic yards
  const cubicYards = round(totalSqft * (4 / 12) / 27)
  const cubicWithWaste = round(cubicYards * (1 + waste.totalPct / 100))
  const rebarSheets = Math.ceil(totalSqft / 50) // 5x10 sheets
  const formLumberFt = round(Math.sqrt(totalSqft) * 6)

  const materials: MaterialItem[] = [
    { item: 'Ready-Mix Concrete', quantity: cubicWithWaste, unit: 'cubic yards', waste_pct: waste.totalPct, total_with_waste: cubicWithWaste },
    { item: 'Rebar (#4, 20ft)', quantity: rebarSheets, unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(rebarSheets * 1.05) },
    { item: 'Form Lumber (2x4)', quantity: round(formLumberFt / 8), unit: 'pcs (8ft)', waste_pct: 10, total_with_waste: Math.ceil(formLumberFt / 8 * 1.1) },
    { item: 'Wire Mesh', quantity: Math.ceil(totalSqft / 50), unit: 'sheets', waste_pct: 5, total_with_waste: Math.ceil(totalSqft / 50 * 1.05) },
    { item: 'Expansion Joint', quantity: round(formLumberFt * 0.3), unit: 'LF', waste_pct: 5, total_with_waste: round(formLumberFt * 0.3 * 1.05) },
    { item: 'Gravel Base', quantity: round(totalSqft * (4 / 12) / 27), unit: 'cubic yards', waste_pct: 10, total_with_waste: round(totalSqft * (4 / 12) / 27 * 1.1) },
  ]

  return {
    measurements: {
      driveway_sqft: drivewaySqft,
      walkway_sqft: walkwaySqft,
      patio_sqft: patioSqft,
      total_sqft: totalSqft,
      cubic_yards: cubicYards,
      form_lf: round(formLumberFt),
    },
    material_list: materials,
    waste_factor_pct: waste.totalPct,
    complexity_score: round(Math.min(10, cubicYards * 0.5 + (totalSqft > 1000 ? 2 : 0))),
    recommended_crew_size: cubicYards > 10 ? 4 : 3,
    estimated_labor_hours: round(totalSqft / 50), // ~50 sqft/hr
  }
}

function hvacPipeline(livingSqft: number, stories: number, yearBuilt: number | null): TradeResult {
  // Tonnage: sqft / 500 (warm climate) to sqft / 600 (cool climate), use 550 avg
  const tonnage = round(livingSqft / 550)
  const ductLf = round(livingSqft * 0.15) // ~0.15 LF per sqft
  const returnCount = Math.max(1, Math.ceil(livingSqft / 600))
  const supplyVents = Math.ceil(livingSqft / 150)

  const materials: MaterialItem[] = [
    { item: 'HVAC System (Condenser + Air Handler)', quantity: Math.ceil(tonnage / 5), unit: 'systems', waste_pct: 0, total_with_waste: Math.ceil(tonnage / 5) },
    { item: `${round(tonnage)} Ton Condenser`, quantity: 1, unit: 'unit', waste_pct: 0, total_with_waste: 1 },
    { item: 'Ductwork', quantity: round(ductLf), unit: 'LF', waste_pct: 10, total_with_waste: round(ductLf * 1.1) },
    { item: 'Supply Registers', quantity: supplyVents, unit: 'pcs', waste_pct: 0, total_with_waste: supplyVents },
    { item: 'Return Grilles', quantity: returnCount, unit: 'pcs', waste_pct: 0, total_with_waste: returnCount },
    { item: 'Thermostat', quantity: stories > 1 ? stories : 1, unit: 'pcs', waste_pct: 0, total_with_waste: stories > 1 ? stories : 1 },
    { item: 'Refrigerant Line Set', quantity: 1, unit: 'set', waste_pct: 0, total_with_waste: 1 },
  ]

  const needsUpgrade = yearBuilt && yearBuilt < 2000

  return {
    measurements: {
      living_sqft: livingSqft,
      tonnage_estimate: round(tonnage),
      duct_linear_ft: round(ductLf),
      return_count: returnCount,
      supply_vent_count: supplyVents,
      stories,
      year_built: yearBuilt,
      likely_needs_upgrade: needsUpgrade,
    },
    material_list: materials,
    waste_factor_pct: 5,
    complexity_score: round(Math.min(10, stories * 2 + (tonnage > 4 ? 2 : 0) + (needsUpgrade ? 2 : 0))),
    recommended_crew_size: 2,
    estimated_labor_hours: round(tonnage * 8 + ductLf / 20), // ~8 hrs/ton + duct install
  }
}

function electricalPipeline(livingSqft: number, stories: number, yearBuilt: number | null): TradeResult {
  // Circuit count: ~1 per 600 sqft + dedicated circuits (kitchen, laundry, etc.)
  const generalCircuits = Math.ceil(livingSqft / 600)
  const dedicatedCircuits = 6 // kitchen (2), laundry, bath, garage, outdoor
  const totalCircuits = generalCircuits + dedicatedCircuits
  const panelAmp = totalCircuits > 30 ? 200 : totalCircuits > 20 ? 150 : 100
  const outletCount = Math.ceil(livingSqft / 80) // NEC: 1 per 12ft wall, rough ~80 sqft
  const switchCount = Math.ceil(outletCount * 0.4)

  const materials: MaterialItem[] = [
    { item: `Panel (${panelAmp}A)`, quantity: 1, unit: 'panel', waste_pct: 0, total_with_waste: 1 },
    { item: 'Wire (14/2 NM-B)', quantity: Math.ceil(livingSqft * 0.5), unit: 'ft', waste_pct: 15, total_with_waste: Math.ceil(livingSqft * 0.5 * 1.15) },
    { item: 'Wire (12/2 NM-B)', quantity: Math.ceil(dedicatedCircuits * 50), unit: 'ft', waste_pct: 15, total_with_waste: Math.ceil(dedicatedCircuits * 50 * 1.15) },
    { item: 'Outlets (Duplex)', quantity: outletCount, unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(outletCount * 1.05) },
    { item: 'GFCI Outlets', quantity: Math.ceil(outletCount * 0.15), unit: 'pcs', waste_pct: 0, total_with_waste: Math.ceil(outletCount * 0.15) },
    { item: 'Switches', quantity: switchCount, unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(switchCount * 1.05) },
    { item: 'Breakers (20A)', quantity: totalCircuits, unit: 'pcs', waste_pct: 5, total_with_waste: Math.ceil(totalCircuits * 1.05) },
  ]

  const needsUpgrade = yearBuilt && yearBuilt < 1970

  return {
    measurements: {
      living_sqft: livingSqft,
      circuit_count: totalCircuits,
      panel_amp: panelAmp,
      outlet_count: outletCount,
      switch_count: switchCount,
      stories,
      year_built: yearBuilt,
      likely_needs_panel_upgrade: needsUpgrade,
    },
    material_list: materials,
    waste_factor_pct: 10,
    complexity_score: round(Math.min(10, stories * 2 + (needsUpgrade ? 3 : 0) + (panelAmp >= 200 ? 1 : 0))),
    recommended_crew_size: 2,
    estimated_labor_hours: round(totalCircuits * 2 + outletCount * 0.5),
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return jsonResponse({ error: 'Missing authorization' }, 401)
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return jsonResponse({ error: 'Unauthorized' }, 401)
  }

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return jsonResponse({ error: 'No company' }, 403)
  }

  try {
    const body = await req.json()
    const { scan_id, trades } = body as {
      scan_id: string
      trades?: string[] // optional filter: ['roofing', 'siding'] — default all 10
    }

    if (!scan_id) {
      return jsonResponse({ error: 'scan_id required' }, 400)
    }

    // ========================================================================
    // LOAD ALL PROPERTY DATA
    // ========================================================================
    const { data: scan, error: scanErr } = await supabase
      .from('property_scans')
      .select('*')
      .eq('id', scan_id)
      .eq('company_id', companyId)
      .single()

    if (scanErr || !scan) {
      return jsonResponse({ error: 'Scan not found' }, 404)
    }

    // Roof measurements
    const { data: roofRow } = await supabase
      .from('roof_measurements')
      .select('*')
      .eq('scan_id', scan_id)
      .limit(1)
      .maybeSingle()

    // Roof facets
    const { data: facetRows } = await supabase
      .from('roof_facets')
      .select('*')
      .eq('roof_measurement_id', roofRow?.id || '00000000-0000-0000-0000-000000000000')
      .order('facet_number')

    // Property features
    const { data: featureRow } = await supabase
      .from('property_features')
      .select('*')
      .eq('scan_id', scan_id)
      .limit(1)
      .maybeSingle()

    // Structures
    const { data: structureRows } = await supabase
      .from('property_structures')
      .select('*')
      .eq('property_scan_id', scan_id)
      .order('footprint_sqft', { ascending: false })

    const primaryStructure = (structureRows || []).find(
      (s: Record<string, unknown>) => s.structure_type === 'primary'
    )

    // ========================================================================
    // DERIVE WALL MEASUREMENTS
    // ========================================================================
    const footprintSqft = (primaryStructure?.footprint_sqft as number) || 0
    const stories = (featureRow?.stories as number) || (primaryStructure?.estimated_stories as number) || 1
    const yearBuilt = (featureRow?.year_built as number) || null
    const eaveLf = (roofRow?.eave_length_ft as number) || 0

    let wallData: WallResult | null = null

    if (footprintSqft > 0) {
      wallData = deriveWallMeasurements(footprintSqft, stories, yearBuilt, eaveLf)

      // Check if wall_measurement already exists for this scan
      const { data: existingWall } = await supabase
        .from('wall_measurements')
        .select('id')
        .eq('scan_id', scan_id)
        .limit(1)
        .maybeSingle()

      if (existingWall) {
        await supabase
          .from('wall_measurements')
          .update({
            structure_id: primaryStructure?.id || null,
            total_wall_area_sqft: wallData.totalWallArea,
            total_siding_area_sqft: wallData.totalSidingArea,
            per_face: wallData.perFace,
            stories: wallData.stories,
            avg_wall_height_ft: wallData.avgWallHeight,
            window_area_est_sqft: wallData.windowAreaEst,
            door_area_est_sqft: wallData.doorAreaEst,
            trim_linear_ft: wallData.trimLinearFt,
            fascia_linear_ft: wallData.fasciaLinearFt,
            soffit_sqft: wallData.soffitSqft,
          })
          .eq('id', existingWall.id)
      } else {
        await supabase
          .from('wall_measurements')
          .insert({
            scan_id,
            structure_id: primaryStructure?.id || null,
            total_wall_area_sqft: wallData.totalWallArea,
            total_siding_area_sqft: wallData.totalSidingArea,
            per_face: wallData.perFace,
            stories: wallData.stories,
            avg_wall_height_ft: wallData.avgWallHeight,
            window_area_est_sqft: wallData.windowAreaEst,
            door_area_est_sqft: wallData.doorAreaEst,
            trim_linear_ft: wallData.trimLinearFt,
            fascia_linear_ft: wallData.fasciaLinearFt,
            soffit_sqft: wallData.soffitSqft,
          })
      }
    }

    // ========================================================================
    // CALCULATE ALL 10 TRADE PIPELINES
    // ========================================================================
    const allTrades = ['roofing', 'siding', 'gutters', 'solar', 'painting', 'landscaping', 'fencing', 'concrete', 'hvac', 'electrical']
    const activeTrades = trades && trades.length > 0 ? trades.filter(t => allTrades.includes(t)) : allTrades

    const roofArea = (roofRow?.total_area_sqft as number) || 0
    const roofSquares = (roofRow?.total_area_squares as number) || 0
    const shape = (roofRow?.predominant_shape as string) || 'mixed'
    const facetCount = (roofRow?.facet_count as number) || 0
    const ridgeLf = (roofRow?.ridge_length_ft as number) || 0
    const hipLf = (roofRow?.hip_length_ft as number) || 0
    const valleyLf = (roofRow?.valley_length_ft as number) || 0
    const rakeLf = (roofRow?.rake_length_ft as number) || 0
    const livingSqft = (featureRow?.living_sqft as number) || footprintSqft * stories
    const lotSqft = (featureRow?.lot_sqft as number) || 0
    const lotPerimeter = lotSqft > 0 ? Math.sqrt(lotSqft) * 4 : 0
    const maxSunHours = 1800 // default

    const results: Record<string, TradeResult> = {}

    for (const trade of activeTrades) {
      let result: TradeResult | null = null

      switch (trade) {
        case 'roofing':
          if (roofArea > 0) {
            result = roofingPipeline(roofArea, roofSquares, shape, facetCount, ridgeLf, hipLf, valleyLf, eaveLf, rakeLf)
          }
          break

        case 'siding':
          if (wallData) {
            result = sidingPipeline(wallData)
          }
          break

        case 'gutters':
          if (eaveLf > 0) {
            result = guttersPipeline(eaveLf, rakeLf, facetCount)
          }
          break

        case 'solar':
          if (facetRows && facetRows.length > 0) {
            result = solarPipeline(
              facetRows.map((f: Record<string, unknown>) => ({
                area_sqft: Number(f.area_sqft) || 0,
                azimuth_degrees: Number(f.azimuth_degrees) || 0,
                annual_sun_hours: f.annual_sun_hours != null ? Number(f.annual_sun_hours) : null,
                shade_factor: f.shade_factor != null ? Number(f.shade_factor) : null,
              })),
              maxSunHours
            )
          }
          break

        case 'painting':
          if (wallData) {
            result = paintingPipeline(wallData, livingSqft)
          }
          break

        case 'landscaping':
          if (lotSqft > 0) {
            result = landscapingPipeline(lotSqft, footprintSqft, lotPerimeter)
          }
          break

        case 'fencing':
          if (lotPerimeter > 0) {
            result = fencingPipeline(lotPerimeter, Math.sqrt(footprintSqft))
          }
          break

        case 'concrete':
          if (lotSqft > 0) {
            result = concretePipeline(lotSqft)
          }
          break

        case 'hvac':
          if (livingSqft > 0) {
            result = hvacPipeline(livingSqft, stories, yearBuilt)
          }
          break

        case 'electrical':
          if (livingSqft > 0) {
            result = electricalPipeline(livingSqft, stories, yearBuilt)
          }
          break
      }

      if (result) {
        results[trade] = result
      }
    }

    // ========================================================================
    // UPSERT TRADE BID DATA
    // ========================================================================
    for (const [trade, result] of Object.entries(results)) {
      const { data: existing } = await supabase
        .from('trade_bid_data')
        .select('id')
        .eq('scan_id', scan_id)
        .eq('trade', trade)
        .limit(1)
        .maybeSingle()

      const row = {
        scan_id,
        trade,
        measurements: result.measurements,
        material_list: result.material_list,
        waste_factor_pct: result.waste_factor_pct,
        complexity_score: result.complexity_score,
        recommended_crew_size: result.recommended_crew_size,
        estimated_labor_hours: result.estimated_labor_hours,
        data_sources: ['google_solar', 'derived'],
      }

      if (existing) {
        await supabase
          .from('trade_bid_data')
          .update(row)
          .eq('id', existing.id)
      } else {
        await supabase
          .from('trade_bid_data')
          .insert(row)
      }
    }

    return jsonResponse({
      scan_id,
      wall_measurements: wallData ? {
        total_wall_area_sqft: wallData.totalWallArea,
        total_siding_area_sqft: wallData.totalSidingArea,
        stories: wallData.stories,
      } : null,
      trades_calculated: Object.keys(results),
      trade_count: Object.keys(results).length,
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return jsonResponse({ error: message }, 500)
  }
})
