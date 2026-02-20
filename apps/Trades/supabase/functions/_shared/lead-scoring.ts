/**
 * Shared Lead Scoring Engine
 * Single source of truth for property lead qualification scoring.
 *
 * Used by:
 * - recon-lead-score (single property HTTP endpoint)
 * - recon-area-scan (batch inline scoring)
 *
 * Scoring weights:
 * - FREE signals (always available): roof area, complexity, building size, elevation, condition
 * - ATTOM-enhanced (paid): roof age, property value, owner tenure
 * - Free-only scores are scaled by 1.4x to compensate for missing ATTOM data
 *
 * Grades: >= 70 = "hot", >= 40 = "warm", < 40 = "cold"
 */

export interface ScoreFactors {
  roof_area_score: number
  roof_complexity_score: number
  building_size_score: number
  storm_proximity_score: number
  elevation_score: number
  roof_age_score: number
  property_value_score: number
  owner_tenure_score: number
  condition_score: number
  data_confidence: string
  sources_used: string[]
}

export interface LeadScoreResult {
  score: number
  grade: string
  factors: ScoreFactors
}

/**
 * Compute lead qualification score (0-100) and grade (hot/warm/cold).
 *
 * @param roofAreaSqft - Total roof area in square feet
 * @param facetCount - Number of roof facets
 * @param footprintSqft - Building footprint in square feet
 * @param elevationFt - Elevation in feet (null if unavailable)
 * @param yearBuilt - Year the property was built (null if no ATTOM)
 * @param assessedValue - Assessed property value in dollars (null if no ATTOM)
 * @param lastSaleDate - ISO date string of last sale (null if no ATTOM)
 * @param stories - Number of stories
 * @param sources - Array of data source names (e.g., ['google_solar', 'attom'])
 */
export function computeLeadScore(
  roofAreaSqft: number,
  facetCount: number,
  footprintSqft: number,
  elevationFt: number | null,
  yearBuilt: number | null,
  assessedValue: number | null,
  lastSaleDate: string | null,
  stories: number,
  sources: string[],
): LeadScoreResult {
  const currentYear = new Date().getFullYear()

  // ── FREE SIGNALS ──

  // Roof area: larger roof = larger job value (0-20)
  let roofAreaScore = 0
  if (roofAreaSqft > 5000) roofAreaScore = 20
  else if (roofAreaSqft > 3000) roofAreaScore = 15
  else if (roofAreaSqft > 2000) roofAreaScore = 12
  else if (roofAreaSqft > 1000) roofAreaScore = 8
  else if (roofAreaSqft > 0) roofAreaScore = 5

  // Roof complexity: more facets = higher price per square (0-10)
  let roofComplexityScore = 0
  if (facetCount > 12) roofComplexityScore = 10
  else if (facetCount > 8) roofComplexityScore = 8
  else if (facetCount > 4) roofComplexityScore = 5
  else if (facetCount > 0) roofComplexityScore = 3

  // Building size: larger building = more exterior work (0-10)
  let buildingSizeScore = 0
  if (footprintSqft > 3000) buildingSizeScore = 10
  else if (footprintSqft > 2000) buildingSizeScore = 8
  else if (footprintSqft > 1000) buildingSizeScore = 5
  else if (footprintSqft > 0) buildingSizeScore = 3

  // Elevation/slope: steep terrain adds complexity (0-3)
  const elevationScore = elevationFt != null && elevationFt > 2000 ? 3 : 0

  // Storm proximity placeholder: 0 (cross-referenced via recon-storm-assess)
  const stormProximityScore = 0

  // ── ATTOM-ENHANCED SIGNALS ──

  // Roof age: older roof = more likely needs replacement (0-25)
  let roofAgeScore = 0
  if (yearBuilt) {
    const age = currentYear - yearBuilt
    if (age > 25) roofAgeScore = 25
    else if (age > 20) roofAgeScore = 20
    else if (age > 15) roofAgeScore = 15
    else if (age > 10) roofAgeScore = 8
    else roofAgeScore = 3
  }

  // Property value: higher value = larger budget (0-15)
  let propertyValueScore = 0
  if (assessedValue) {
    if (assessedValue > 500000) propertyValueScore = 15
    else if (assessedValue > 300000) propertyValueScore = 12
    else if (assessedValue > 200000) propertyValueScore = 10
    else if (assessedValue > 100000) propertyValueScore = 7
    else propertyValueScore = 4
  }

  // Owner tenure: longer tenure = more equity, invest-ready (0-10)
  let ownerTenureScore = 0
  if (lastSaleDate) {
    const saleYear = new Date(lastSaleDate).getFullYear()
    const tenure = currentYear - saleYear
    if (tenure > 15) ownerTenureScore = 10
    else if (tenure > 10) ownerTenureScore = 8
    else if (tenure > 5) ownerTenureScore = 5
    else ownerTenureScore = 2
  }

  // Condition score from stories (multi-story = larger exterior)
  const conditionScore = stories > 2 ? 5 : stories > 1 ? 3 : 0

  // ── OVERALL CALCULATION ──

  // Weights depend on which data sources are available
  const hasAttom = sources.includes('attom')

  let totalScore = 0
  if (hasAttom) {
    // Full score with all data
    totalScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
      stormProximityScore + elevationScore + roofAgeScore +
      propertyValueScore + ownerTenureScore + conditionScore
  } else {
    // Basic score with free data only — scale up proportionally
    const freeScore = roofAreaScore + roofComplexityScore + buildingSizeScore +
      stormProximityScore + elevationScore + conditionScore
    // Free signals max ~48 points, scale to ~65 max (basic score ceiling)
    totalScore = Math.round(freeScore * 1.4)
  }

  totalScore = Math.min(100, Math.max(0, totalScore))

  const grade = totalScore >= 70 ? 'hot' : totalScore >= 40 ? 'warm' : 'cold'

  return {
    score: totalScore,
    grade,
    factors: {
      roof_area_score: roofAreaScore,
      roof_complexity_score: roofComplexityScore,
      building_size_score: buildingSizeScore,
      storm_proximity_score: stormProximityScore,
      elevation_score: elevationScore,
      roof_age_score: roofAgeScore,
      property_value_score: propertyValueScore,
      owner_tenure_score: ownerTenureScore,
      condition_score: conditionScore,
      data_confidence: hasAttom ? 'full' : 'basic',
      sources_used: sources,
    },
  }
}
