/**
 * DEPTH28 Part D: Trade-Specific Auto-Scope Generation
 * Takes a scan_id + selected trades, generates preliminary scope of work
 * from all collected property intelligence + measurement data.
 * NOT an estimate — a SCOPE (what needs to be done, what code applies, what permits needed).
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

const EF_NAME = 'recon-auto-scope'

interface ScopeItem {
  category: string   // measurements, materials, code, permits, environmental, notes
  item: string       // e.g., "roof_area"
  label: string      // human-readable label
  value: string      // e.g., "2400"
  unit: string       // e.g., "sqft"
  source: string     // which data source
  confidence: number // 0-100
}

interface CrossTradeDep {
  trade: string
  reason: string
  priority: 'before' | 'after' | 'concurrent'
}

Deno.serve(async (req) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)
  if (req.method !== 'POST') return errorResponse('Method not allowed', 405, origin)

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return errorResponse('Missing authorization', 401, origin)

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authErr } = await supabase.auth.getUser(token)
  if (authErr || !user) return errorResponse('Unauthorized', 401, origin)

  const companyId = user.app_metadata?.company_id
  if (!companyId) return errorResponse('No company', 403, origin)

  try {
    const { scan_id, trades } = await req.json() as { scan_id: string; trades: string[] }
    if (!scan_id) return errorResponse('scan_id required', 400, origin)
    if (!trades?.length) return errorResponse('trades[] required', 400, origin)

    // Fetch all scan data in parallel
    const [scanRes, roofRes, wallRes, profileRes, weatherRes] = await Promise.all([
      supabase.from('property_scans').select('*').eq('id', scan_id).eq('company_id', companyId).single(),
      supabase.from('roof_measurements').select('*').eq('scan_id', scan_id).maybeSingle(),
      supabase.from('wall_measurements').select('*').eq('scan_id', scan_id).maybeSingle(),
      supabase.from('property_profiles').select('*').eq('scan_id', scan_id).maybeSingle(),
      supabase.from('weather_intelligence').select('*').eq('scan_id', scan_id).maybeSingle(),
    ])

    if (scanRes.error || !scanRes.data) return errorResponse('Scan not found', 404, origin)

    const scan = scanRes.data
    const roof = roofRes.data
    const walls = wallRes.data
    const profile = profileRes.data
    const weather = weatherRes.data

    const results: Array<{ trade: string; scope_id: string }> = []

    for (const trade of trades) {
      const { items, summary, codeReqs, permits, dependencies } = generateTradeScope(
        trade, scan, roof, walls, profile, weather
      )

      const { data: scope } = await supabase
        .from('trade_auto_scopes')
        .insert({
          scan_id,
          company_id: companyId,
          trade,
          scope_summary: summary,
          scope_items: items,
          code_requirements: codeReqs,
          permits_required: permits.length > 0,
          permit_types: permits,
          dependencies,
          confidence_score: Math.round(items.reduce((s, i) => s + i.confidence, 0) / Math.max(items.length, 1)),
          data_sources: [...new Set(items.map(i => i.source))],
        })
        .select('id')
        .single()

      if (scope) results.push({ trade, scope_id: scope.id })
    }

    return new Response(
      JSON.stringify({ ok: true, scan_id, scopes: results }),
      { status: 200, headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' } }
    )
  } catch (e) {
    console.error(`[${EF_NAME}] Error:`, e)
    return errorResponse(e instanceof Error ? e.message : 'Scope generation failed', 500, origin)
  }
})

// ============================================================================
// SCOPE GENERATORS PER TRADE
// ============================================================================

function generateTradeScope(
  trade: string,
  scan: Record<string, unknown>,
  roof: Record<string, unknown> | null,
  walls: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
): {
  items: ScopeItem[]
  summary: string
  codeReqs: Array<{ code_type: string; year: string; requirement: string; section?: string }>
  permits: string[]
  dependencies: CrossTradeDep[]
} {
  switch (trade) {
    case 'roofing': return roofingScope(scan, roof, profile, weather)
    case 'siding': return sidingScope(scan, walls, profile, weather)
    case 'painting': return paintingScope(scan, walls, profile)
    case 'fencing': return fencingScope(scan, profile, weather)
    case 'concrete': return concreteScope(scan, profile, weather)
    case 'gutters': return gutterScope(scan, roof, profile)
    case 'electrical': return electricalScope(scan, profile)
    case 'plumbing': return plumbingScope(scan, profile)
    case 'hvac': return hvacScope(scan, profile, weather)
    case 'insulation': return insulationScope(scan, profile, weather)
    case 'windows_doors': return windowDoorScope(scan, walls, profile)
    case 'solar': return solarScope(scan, roof, profile, weather)
    case 'landscaping': return landscapingScope(scan, profile, weather)
    default: return genericScope(trade, scan, profile)
  }
}

function roofingScope(
  scan: Record<string, unknown>,
  roof: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const codeReqs: Array<{ code_type: string; year: string; requirement: string; section?: string }> = []
  const permits: string[] = []
  const deps: CrossTradeDep[] = []

  if (roof) {
    items.push(
      { category: 'measurements', item: 'roof_area_squares', label: 'Roof Area', value: String(roof.total_area_squares || 0), unit: 'squares', source: 'google_solar', confidence: 85 },
      { category: 'measurements', item: 'roof_area_sqft', label: 'Roof Area (sqft)', value: String(roof.total_area_sqft || 0), unit: 'sqft', source: 'google_solar', confidence: 85 },
      { category: 'measurements', item: 'pitch', label: 'Primary Pitch', value: String(roof.pitch_primary || 'Unknown'), unit: '', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'ridge_length', label: 'Ridge Length', value: String(roof.ridge_length_ft || 0), unit: 'LF', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'hip_length', label: 'Hip Length', value: String(roof.hip_length_ft || 0), unit: 'LF', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'valley_length', label: 'Valley Length', value: String(roof.valley_length_ft || 0), unit: 'LF', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'eave_length', label: 'Eave Length', value: String(roof.eave_length_ft || 0), unit: 'LF', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'penetrations', label: 'Penetrations', value: String(roof.penetration_count || 0), unit: 'count', source: 'google_solar', confidence: 75 },
      { category: 'measurements', item: 'facets', label: 'Facet Count', value: String(roof.facet_count || 0), unit: 'count', source: 'google_solar', confidence: 90 },
      { category: 'measurements', item: 'complexity', label: 'Complexity Score', value: String(roof.complexity_score || 0), unit: '/10', source: 'derived', confidence: 70 },
    )

    // Waste factor based on roof shape
    const shape = roof.predominant_shape as string || 'gable'
    const waste = shape === 'hip' ? '12-15%' : shape === 'flat' ? '3-5%' : '10-12%'
    items.push({ category: 'materials', item: 'waste_factor', label: 'Waste Factor', value: waste, unit: '', source: 'derived', confidence: 75 })
  }

  // Environmental flags
  if (profile) {
    const yearBuilt = profile.year_built as number
    if (yearBuilt && yearBuilt < 2000) {
      items.push({ category: 'notes', item: 'layer_probability', label: 'Multiple Layer Risk', value: yearBuilt < 1990 ? 'HIGH — likely 2+ layers' : 'MODERATE — check for tear-off', unit: '', source: 'derived', confidence: 60 })
    }

    if (profile.lead_paint_probability === 'high' || profile.lead_paint_probability === 'moderate') {
      items.push({ category: 'environmental', item: 'lead_paint', label: 'Lead Paint Warning', value: 'EPA RRP Rule applies — certified renovator required', unit: '', source: 'epa', confidence: 90 })
    }

    // Wind speed for code
    if (profile.wind_speed_mph) {
      codeReqs.push({ code_type: 'IBC', year: profile.ibc_irc_year as string || '2021', requirement: `Wind speed design: ${profile.wind_speed_mph} mph`, section: 'R905.1' })
    }
    if (profile.climate_zone) {
      codeReqs.push({ code_type: 'IECC', year: profile.iecc_year as string || '2021', requirement: `Climate Zone ${profile.climate_zone} — ice & water shield may be required in cold zones` })
    }
  }

  // Ice dam risk from weather
  if (weather && (weather.freeze_thaw_cycles_yr as number) > 30) {
    items.push({ category: 'environmental', item: 'ice_dam_risk', label: 'Ice Dam Risk', value: 'HIGH — north-facing facets need extra ice & water shield', unit: '', source: 'open_meteo', confidence: 70 })
  }

  permits.push('roofing')
  const summary = `Roofing scope: ${roof?.total_area_squares || '?'} squares, ${roof?.pitch_primary || '?'} pitch, ${roof?.facet_count || '?'} facets, ${roof?.penetration_count || 0} penetrations. Shape: ${roof?.predominant_shape || 'unknown'}. Waste: ${items.find(i => i.item === 'waste_factor')?.value || '10-12%'}.`

  return { items, summary, codeReqs, permits, dependencies: deps }
}

function sidingScope(
  scan: Record<string, unknown>,
  walls: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
  _weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const permits: string[] = []
  const codeReqs: Array<{ code_type: string; year: string; requirement: string }> = []

  if (walls) {
    items.push(
      { category: 'measurements', item: 'wall_area', label: 'Total Wall Area', value: String(walls.total_wall_area_sqft || 0), unit: 'sqft', source: 'derived', confidence: 70 },
      { category: 'measurements', item: 'siding_area', label: 'Siding Area (net)', value: String(walls.total_siding_area_sqft || 0), unit: 'sqft', source: 'derived', confidence: 70 },
      { category: 'measurements', item: 'stories', label: 'Stories', value: String(walls.stories || 1), unit: '', source: 'derived', confidence: 80 },
      { category: 'measurements', item: 'trim_lf', label: 'Trim Linear Ft', value: String(walls.trim_linear_ft || 0), unit: 'LF', source: 'derived', confidence: 60 },
      { category: 'measurements', item: 'fascia_lf', label: 'Fascia Linear Ft', value: String(walls.fascia_linear_ft || 0), unit: 'LF', source: 'derived', confidence: 60 },
      { category: 'measurements', item: 'soffit_sqft', label: 'Soffit Area', value: String(walls.soffit_sqft || 0), unit: 'sqft', source: 'derived', confidence: 55 },
    )
  }

  if (profile) {
    if (profile.year_built) {
      const yr = profile.year_built as number
      const sidingType = yr < 1960 ? 'wood' : yr < 1980 ? 'aluminum' : yr < 2000 ? 'vinyl' : 'fiber_cement/vinyl'
      items.push({ category: 'notes', item: 'probable_material', label: 'Probable Current Material', value: sidingType, unit: '', source: 'derived', confidence: 55 })
    }
    if (profile.lead_paint_probability === 'high' || profile.lead_paint_probability === 'moderate') {
      items.push({ category: 'environmental', item: 'lead_paint', label: 'Lead Paint Warning', value: 'EPA RRP Rule — certified renovator required for pre-1978 homes', unit: '', source: 'epa', confidence: 90 })
    }
  }

  permits.push('building')
  const summary = `Siding scope: ${walls?.total_siding_area_sqft || '?'} sqft net siding area, ${walls?.stories || '?'} stories, ${walls?.trim_linear_ft || '?'} LF trim, ${walls?.soffit_sqft || '?'} sqft soffit.`

  return { items, summary, codeReqs, permits, dependencies: [] }
}

function paintingScope(
  _scan: Record<string, unknown>,
  walls: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (walls) {
    items.push(
      { category: 'measurements', item: 'exterior_wall_sqft', label: 'Exterior Walls', value: String(walls.total_wall_area_sqft || 0), unit: 'sqft', source: 'derived', confidence: 70 },
      { category: 'measurements', item: 'trim_lf', label: 'Trim LF', value: String(walls.trim_linear_ft || 0), unit: 'LF', source: 'derived', confidence: 60 },
    )
  }

  if (profile) {
    const yr = profile.year_built as number || 0
    if (yr > 0 && yr < 1978) {
      items.push({ category: 'environmental', item: 'lead_paint', label: 'Lead Paint', value: 'CONFIRMED RISK — EPA RRP Rule required. Test before scraping/sanding.', unit: '', source: 'epa', confidence: 95 })
    }
    if (yr > 0) {
      const paintType = yr < 1978 ? 'Oil-based likely (pre-1978)' : 'Latex probable'
      items.push({ category: 'notes', item: 'paint_type', label: 'Previous Paint Type', value: paintType, unit: '', source: 'derived', confidence: 50 })
    }
    const stories = walls?.stories as number || 1
    if (stories >= 2) {
      items.push({ category: 'notes', item: 'scaffolding', label: 'Scaffolding/Lift', value: `Required — ${stories} stories`, unit: '', source: 'derived', confidence: 85 })
    }
  }

  const summary = `Painting scope: ${walls?.total_wall_area_sqft || '?'} sqft exterior walls, ${walls?.trim_linear_ft || '?'} LF trim.`
  return { items, summary, codeReqs: [], permits: [], dependencies: [] }
}

function fencingScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
  _weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const deps: CrossTradeDep[] = []

  // Fence always needs 811 reminder
  items.push({ category: 'notes', item: 'call_811', label: 'Underground Utilities', value: 'CALL 811 before digging — required by law in all 50 states', unit: '', source: 'regulation', confidence: 100 })

  if (profile) {
    if (profile.frost_line_depth_inches) {
      items.push({ category: 'code', item: 'frost_line', label: 'Frost Line Depth', value: String(profile.frost_line_depth_inches), unit: 'inches', source: 'derived', confidence: 75 })
      items.push({ category: 'notes', item: 'post_depth', label: 'Min Post Depth', value: String((profile.frost_line_depth_inches as number) + 6), unit: 'inches', source: 'derived', confidence: 75 })
    }
    if (profile.hoa_architectural_review) {
      items.push({ category: 'notes', item: 'hoa_review', label: 'HOA Approval', value: 'Required — submit architectural review before starting', unit: '', source: 'user_data', confidence: 60 })
    }
    if (profile.expansive_soil_risk === 'high') {
      items.push({ category: 'environmental', item: 'soil_warning', label: 'Expansive Soil', value: 'HIGH risk — consider deeper footings or bell-bottom post holes', unit: '', source: 'usda_soil', confidence: 65 })
    }
  }

  const summary = `Fencing scope: Property boundary measurement needed (parcel data). Call 811 required. Frost line: ${profile?.frost_line_depth_inches || '?'}" — post depth min ${((profile?.frost_line_depth_inches as number) || 0) + 6}".`
  return { items, summary, codeReqs: [], permits: ['building'], dependencies: deps }
}

function concreteScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (profile) {
    if (profile.frost_line_depth_inches) {
      items.push({ category: 'code', item: 'frost_line', label: 'Frost Line', value: String(profile.frost_line_depth_inches), unit: 'inches', source: 'derived', confidence: 75 })
    }
    if (profile.expansive_soil_risk) {
      items.push({ category: 'environmental', item: 'soil_type', label: 'Soil Risk', value: String(profile.expansive_soil_risk), unit: '', source: 'usda_soil', confidence: 65 })
    }
  }

  if (weather) {
    const ft = weather.freeze_thaw_cycles_yr as number || 0
    if (ft > 30) {
      items.push({ category: 'notes', item: 'freeze_thaw', label: 'Freeze-Thaw Warning', value: `${ft} cycles/year — use air-entrained concrete (6% ± 1%)`, unit: '', source: 'open_meteo', confidence: 70 })
    }
  }

  // Standard PSI guidance
  items.push(
    { category: 'notes', item: 'psi_driveway', label: 'Driveway PSI', value: '4000', unit: 'PSI', source: 'standard', confidence: 85 },
    { category: 'notes', item: 'psi_sidewalk', label: 'Sidewalk PSI', value: '3000', unit: 'PSI', source: 'standard', confidence: 85 },
    { category: 'notes', item: 'thickness_drive', label: 'Driveway Thickness', value: '4-6', unit: 'inches', source: 'standard', confidence: 85 },
  )

  items.push({ category: 'notes', item: 'call_811', label: 'Call 811', value: 'Required before excavation', unit: '', source: 'regulation', confidence: 100 })

  const summary = `Concrete scope: Frost line ${profile?.frost_line_depth_inches || '?'}". Soil: ${profile?.expansive_soil_risk || 'unknown'} expansion risk. Standard: 4000 PSI driveway, 3000 PSI walks.`
  return { items, summary, codeReqs: [], permits: ['building'], dependencies: [] }
}

function gutterScope(
  _scan: Record<string, unknown>,
  roof: Record<string, unknown> | null,
  _profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (roof) {
    const eaveLf = Number(roof.eave_length_ft) || 0
    items.push(
      { category: 'measurements', item: 'gutter_lf', label: 'Gutter Length', value: String(eaveLf), unit: 'LF', source: 'google_solar', confidence: 80 },
      { category: 'measurements', item: 'downspouts', label: 'Downspouts Recommended', value: String(Math.max(Math.ceil(eaveLf / 40), 2)), unit: 'count', source: 'derived', confidence: 70 },
      { category: 'measurements', item: 'valleys', label: 'High-Flow Valley Points', value: String(roof.valley_length_ft ? 'Yes — size up collector' : 'None'), unit: '', source: 'google_solar', confidence: 75 },
    )
  }

  const summary = `Gutter scope: ${roof?.eave_length_ft || '?'} LF eave, ${Math.max(Math.ceil((Number(roof?.eave_length_ft) || 0) / 40), 2)} downspouts recommended.`
  return { items, summary, codeReqs: [], permits: [], dependencies: [] }
}

function electricalScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const codeReqs: Array<{ code_type: string; year: string; requirement: string; section?: string }> = []

  if (profile) {
    if (profile.service_amperage) {
      items.push({ category: 'measurements', item: 'service_amps', label: 'Current Service', value: `${profile.service_amperage}A`, unit: '', source: 'derived', confidence: 60 })
    }
    if (profile.year_built) {
      const yr = profile.year_built as number
      const wireType = yr < 1945 ? 'Knob & tube probable' : yr < 1972 ? 'Aluminum wiring possible — HAZARD' : yr < 1985 ? 'Copper NM (non-grounded possible)' : 'Copper NM-B'
      items.push({ category: 'notes', item: 'wiring_type', label: 'Probable Wiring', value: wireType, unit: '', source: 'derived', confidence: 55 })

      // FPE/Zinsco panel warning
      if (yr >= 1960 && yr <= 1985) {
        items.push({ category: 'environmental', item: 'panel_warning', label: 'Panel Safety Check', value: 'Federal Pacific (FPE) or Zinsco panels common in this era — FIRE HAZARD, recommend replacement', unit: '', source: 'derived', confidence: 50 })
      }
    }
    if (profile.nec_year) {
      codeReqs.push({ code_type: 'NEC', year: profile.nec_year as string, requirement: 'National Electrical Code applies' })
    }
  }

  const summary = `Electrical scope: ${profile?.service_amperage || '?'}A service. NEC ${profile?.nec_year || '?'}. Wiring age-based assessment included.`
  return { items, summary, codeReqs, permits: ['electrical'], dependencies: [] }
}

function plumbingScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (profile) {
    if (profile.year_built) {
      const yr = profile.year_built as number
      const pipeType = yr < 1960 ? 'Cast iron/galvanized steel likely' : yr < 1975 ? 'Copper/galvanized mix' : yr < 1995 ? 'Copper' : 'PEX/copper'
      items.push({ category: 'notes', item: 'pipe_material', label: 'Probable Pipe', value: pipeType, unit: '', source: 'derived', confidence: 50 })

      if (yr < 1986) {
        items.push({ category: 'environmental', item: 'lead_solder', label: 'Lead Solder Risk', value: 'Pre-1986 — lead solder probable on copper joints', unit: '', source: 'regulation', confidence: 75 })
      }
    }
    if (profile.ipc_upc_year) {
      items.push({ category: 'code', item: 'plumbing_code', label: 'Plumbing Code', value: `IPC/UPC ${profile.ipc_upc_year}`, unit: '', source: 'jurisdiction', confidence: 80 })
    }
  }

  const summary = `Plumbing scope: Code ${profile?.ipc_upc_year || '?'}. Pipe material age-based estimate included.`
  return { items, summary, codeReqs: [], permits: ['plumbing'], dependencies: [] }
}

function hvacScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const deps: CrossTradeDep[] = []

  if (weather) {
    if (weather.heating_degree_days) {
      items.push({ category: 'measurements', item: 'hdd', label: 'Heating Degree Days', value: String(weather.heating_degree_days), unit: 'HDD', source: 'open_meteo', confidence: 80 })
    }
    if (weather.cooling_degree_days) {
      items.push({ category: 'measurements', item: 'cdd', label: 'Cooling Degree Days', value: String(weather.cooling_degree_days), unit: 'CDD', source: 'open_meteo', confidence: 80 })
    }
  }

  if (profile) {
    if (profile.climate_zone) {
      items.push({ category: 'code', item: 'climate_zone', label: 'Climate Zone', value: String(profile.climate_zone), unit: '', source: 'derived', confidence: 75 })
    }
    if (profile.service_amperage && (profile.service_amperage as number) < 200) {
      items.push({ category: 'notes', item: 'panel_upgrade', label: 'Panel Upgrade May Be Needed', value: `Current: ${profile.service_amperage}A — heat pump requires 200A+`, unit: '', source: 'derived', confidence: 60 })
      deps.push({ trade: 'electrical', reason: 'Panel upgrade needed for heat pump conversion', priority: 'before' })
    }
  }

  const summary = `HVAC scope: Climate Zone ${profile?.climate_zone || '?'}. HDD: ${weather?.heating_degree_days || '?'}, CDD: ${weather?.cooling_degree_days || '?'}. Manual J pre-load from property data.`
  return { items, summary, codeReqs: [], permits: ['mechanical'], dependencies: deps }
}

function insulationScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (profile) {
    const yr = profile.year_built as number || 0
    const estRvalue = yr < 1970 ? 'R-11 or less' : yr < 1990 ? 'R-19' : yr < 2010 ? 'R-30' : 'R-38+'
    items.push({ category: 'notes', item: 'current_r_value', label: 'Est. Current R-Value', value: estRvalue, unit: '', source: 'derived', confidence: 45 })

    if (profile.climate_zone) {
      const zone = Number(profile.climate_zone)
      const reqRvalue = zone >= 5 ? 'R-49 attic, R-20 walls' : zone >= 4 ? 'R-38 attic, R-15 walls' : 'R-30 attic, R-13 walls'
      items.push({ category: 'code', item: 'required_r_value', label: 'Code-Required R-Value', value: reqRvalue, unit: '', source: 'IECC', confidence: 80 })
    }
  }

  const summary = `Insulation scope: Current est. R-value based on ${profile?.year_built || 'unknown'} year built. Climate zone ${profile?.climate_zone || '?'}.`
  return { items, summary, codeReqs: [], permits: [], dependencies: [] }
}

function windowDoorScope(
  _scan: Record<string, unknown>,
  walls: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (walls) {
    const perFace = walls.per_face as Array<{ window_count_est: number; door_count_est: number }> || []
    const totalWindows = perFace.reduce((s, f) => s + (f.window_count_est || 0), 0)
    const totalDoors = perFace.reduce((s, f) => s + (f.door_count_est || 0), 0)
    items.push(
      { category: 'measurements', item: 'window_count', label: 'Windows (est)', value: String(totalWindows), unit: 'count', source: 'derived', confidence: 55 },
      { category: 'measurements', item: 'door_count', label: 'Doors (est)', value: String(totalDoors), unit: 'count', source: 'derived', confidence: 55 },
    )
  }

  if (profile) {
    if (profile.year_built) {
      const yr = profile.year_built as number
      const frameType = yr < 1960 ? 'Wood (likely single-pane)' : yr < 1990 ? 'Aluminum (likely single-pane)' : yr < 2005 ? 'Vinyl (double-pane)' : 'Vinyl/fiberglass (Low-E)'
      items.push({ category: 'notes', item: 'frame_type', label: 'Probable Frame Type', value: frameType, unit: '', source: 'derived', confidence: 50 })
    }
    if (profile.lead_paint_probability === 'high') {
      items.push({ category: 'environmental', item: 'lead_warning', label: 'Lead Paint', value: 'EPA RRP applies to window replacement in pre-1978 homes', unit: '', source: 'epa', confidence: 90 })
    }
    if (profile.climate_zone) {
      const zone = Number(profile.climate_zone)
      const uFactor = zone >= 5 ? '0.30' : zone >= 4 ? '0.32' : zone >= 3 ? '0.35' : '0.40'
      items.push({ category: 'code', item: 'u_factor', label: 'Max U-Factor (IECC)', value: uFactor, unit: '', source: 'IECC', confidence: 80 })
    }
  }

  const summary = `Window/Door scope: Est. ${walls ? 'from wall data' : 'TBD'}. Frame type age-based. Energy code U-factor included.`
  return { items, summary, codeReqs: [], permits: ['building'], dependencies: [] }
}

function solarScope(
  _scan: Record<string, unknown>,
  roof: Record<string, unknown> | null,
  profile: Record<string, unknown> | null,
  _weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []
  const deps: CrossTradeDep[] = []

  if (roof) {
    items.push(
      { category: 'measurements', item: 'roof_area', label: 'Available Roof Area', value: String(roof.total_area_sqft || 0), unit: 'sqft', source: 'google_solar', confidence: 85 },
      { category: 'measurements', item: 'pitch', label: 'Roof Pitch', value: String(roof.pitch_primary || 'Unknown'), unit: '', source: 'google_solar', confidence: 80 },
    )

    // Roof age check
    const roofAge = profile?.year_built ? new Date().getFullYear() - (profile.year_built as number) : null
    if (roofAge && roofAge > 15) {
      items.push({ category: 'notes', item: 'roof_age_warning', label: 'Roof Replacement First?', value: `Roof est. ${roofAge} years old — consider replacement before panel install`, unit: '', source: 'derived', confidence: 55 })
      deps.push({ trade: 'roofing', reason: 'Roof replacement should happen before solar install', priority: 'before' })
    }
  }

  if (profile && profile.service_amperage && (profile.service_amperage as number) < 200) {
    deps.push({ trade: 'electrical', reason: 'Panel upgrade may be needed for solar', priority: 'before' })
  }

  const summary = `Solar scope: ${roof?.total_area_sqft || '?'} sqft roof, pitch ${roof?.pitch_primary || '?'}. Check roof condition first.`
  return { items, summary, codeReqs: [], permits: ['electrical', 'building'], dependencies: deps }
}

function landscapingScope(
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
  weather: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (profile?.climate_zone) {
    items.push({ category: 'notes', item: 'climate_zone', label: 'Climate Zone', value: String(profile.climate_zone), unit: '', source: 'derived', confidence: 75 })
  }

  if (weather?.annual_precip_inches) {
    items.push({ category: 'notes', item: 'annual_rain', label: 'Annual Precipitation', value: String(weather.annual_precip_inches), unit: 'inches', source: 'open_meteo', confidence: 80 })

    const precip = weather.annual_precip_inches as number
    if (precip < 20) {
      items.push({ category: 'notes', item: 'irrigation', label: 'Irrigation', value: 'REQUIRED — low rainfall area', unit: '', source: 'derived', confidence: 75 })
    }
  }

  const summary = `Landscaping scope: Climate zone ${profile?.climate_zone || '?'}. Annual precipitation: ${weather?.annual_precip_inches || '?'}".`
  return { items, summary, codeReqs: [], permits: [], dependencies: [] }
}

function genericScope(
  trade: string,
  _scan: Record<string, unknown>,
  profile: Record<string, unknown> | null,
) {
  const items: ScopeItem[] = []

  if (profile?.year_built) {
    items.push({ category: 'notes', item: 'year_built', label: 'Year Built', value: String(profile.year_built), unit: '', source: 'property_data', confidence: 75 })
  }

  const summary = `${trade} scope: Property-level data available. Trade-specific measurements require on-site verification.`
  return { items, summary, codeReqs: [], permits: [], dependencies: [] }
}
