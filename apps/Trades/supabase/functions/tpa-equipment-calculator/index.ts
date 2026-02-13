// Supabase Edge Function: tpa-equipment-calculator
// IICRC S500 equipment calculation formulas for restoration jobs.
// POST: Calculate required dehumidifiers, air movers, air scrubbers per room.
// Returns formula breakdown for adjuster justification + saves to equipment_calculations.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// IICRC S500 chart factors by water class
const DEHU_CHART_FACTORS: Record<number, number> = {
  1: 40,
  2: 40,
  3: 30,
  4: 25,
}

// Air mover floor divisor by class
const AM_FLOOR_DIVISORS: Record<number, number> = {
  1: 70,  // Less aggressive
  2: 50,  // Standard
  3: 50,  // Standard
  4: 50,  // Specialty, still aggressive
}

// Air mover ceiling divisor by class
const AM_CEILING_DIVISORS: Record<number, number> = {
  1: 150,
  2: 150,
  3: 100,  // Class 3 has wet ceiling
  4: 100,
}

// Default target ACH (air changes per hour)
const DEFAULT_SCRUBBER_ACH = 6

interface RoomInput {
  room_name: string
  length_ft: number
  width_ft: number
  height_ft: number
  water_class: 1 | 2 | 3 | 4
  // Optional overrides
  dehu_unit_ppd?: number        // PPD rating of available dehu (default: 70)
  scrubber_unit_cfm?: number    // CFM of available scrubber (default: 500)
  scrubber_target_ach?: number  // Target ACH (default: 6)
  am_inset_count?: number       // Additional closets/toe kicks (default: 0)
  wet_ceiling?: boolean         // Override ceiling calculation
}

interface RoomResult {
  room_name: string
  dimensions: {
    length_ft: number
    width_ft: number
    height_ft: number
    floor_sqft: number
    wall_lf: number
    cubic_ft: number
    ceiling_sqft: number
  }
  water_class: number
  dehumidifier: {
    chart_factor: number
    ppd_needed: number
    unit_ppd: number
    units_required: number
    formula: string
  }
  air_mover: {
    wall_units: number
    floor_units: number
    ceiling_units: number
    inset_count: number
    floor_divisor: number
    ceiling_divisor: number
    units_required: number
    formula: string
  }
  air_scrubber: {
    target_ach: number
    unit_cfm: number
    units_required: number
    formula: string
  }
  total_equipment: {
    dehumidifiers: number
    air_movers: number
    air_scrubbers: number
  }
}

function calculateRoom(room: RoomInput): RoomResult {
  const { length_ft, width_ft, height_ft, water_class } = room

  // Computed dimensions
  const floor_sqft = length_ft * width_ft
  const wall_lf = 2 * (length_ft + width_ft)
  const cubic_ft = floor_sqft * height_ft
  const ceiling_sqft = floor_sqft

  // --- DEHUMIDIFIER ---
  const chart_factor = DEHU_CHART_FACTORS[water_class] || 40
  const ppd_needed = cubic_ft / chart_factor
  const unit_ppd = room.dehu_unit_ppd || 70
  const dehu_units = Math.ceil(ppd_needed / unit_ppd)

  // --- AIR MOVERS ---
  const am_floor_divisor = AM_FLOOR_DIVISORS[water_class] || 50
  const am_ceiling_divisor = AM_CEILING_DIVISORS[water_class] || 100
  const am_wall = wall_lf / 14
  const am_floor = floor_sqft / am_floor_divisor
  // Ceiling only for Class 3+ or if explicitly wet
  const am_ceiling = (water_class >= 3 || room.wet_ceiling) ? ceiling_sqft / am_ceiling_divisor : 0
  const am_insets = room.am_inset_count || 0
  const am_total = am_wall + am_floor + am_ceiling + am_insets
  const am_units = Math.ceil(am_total)

  // --- AIR SCRUBBER ---
  const target_ach = room.scrubber_target_ach || DEFAULT_SCRUBBER_ACH
  const scrubber_cfm = room.scrubber_unit_cfm || 500
  const scrubber_cfm_needed = (cubic_ft * target_ach) / 60
  const scrubber_units = Math.ceil(scrubber_cfm_needed / scrubber_cfm)

  return {
    room_name: room.room_name,
    dimensions: {
      length_ft,
      width_ft,
      height_ft,
      floor_sqft: Math.round(floor_sqft * 100) / 100,
      wall_lf: Math.round(wall_lf * 100) / 100,
      cubic_ft: Math.round(cubic_ft * 100) / 100,
      ceiling_sqft: Math.round(ceiling_sqft * 100) / 100,
    },
    water_class,
    dehumidifier: {
      chart_factor,
      ppd_needed: Math.round(ppd_needed * 100) / 100,
      unit_ppd,
      units_required: dehu_units,
      formula: `${cubic_ft.toFixed(0)} cu ft / ${chart_factor} (Class ${water_class} factor) = ${ppd_needed.toFixed(1)} PPD needed / ${unit_ppd} PPD per unit = ${dehu_units} unit(s)`,
    },
    air_mover: {
      wall_units: Math.round(am_wall * 10) / 10,
      floor_units: Math.round(am_floor * 10) / 10,
      ceiling_units: Math.round(am_ceiling * 10) / 10,
      inset_count: am_insets,
      floor_divisor: am_floor_divisor,
      ceiling_divisor: am_ceiling_divisor,
      units_required: am_units,
      formula: `Wall: ${wall_lf.toFixed(0)} LF / 14 = ${am_wall.toFixed(1)} + Floor: ${floor_sqft.toFixed(0)} SF / ${am_floor_divisor} = ${am_floor.toFixed(1)}${am_ceiling > 0 ? ` + Ceiling: ${ceiling_sqft.toFixed(0)} SF / ${am_ceiling_divisor} = ${am_ceiling.toFixed(1)}` : ''}${am_insets > 0 ? ` + ${am_insets} insets` : ''} = ${am_total.toFixed(1)} → ${am_units} unit(s)`,
    },
    air_scrubber: {
      target_ach,
      unit_cfm: scrubber_cfm,
      units_required: scrubber_units,
      formula: `${cubic_ft.toFixed(0)} cu ft × ${target_ach} ACH / 60 = ${scrubber_cfm_needed.toFixed(0)} CFM needed / ${scrubber_cfm} CFM per unit = ${scrubber_units} unit(s)`,
    },
    total_equipment: {
      dehumidifiers: dehu_units,
      air_movers: am_units,
      air_scrubbers: scrubber_units,
    },
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const {
      job_id,
      tpa_assignment_id,
      water_damage_assessment_id,
      rooms,
      save_results,
    } = body as {
      job_id: string
      tpa_assignment_id?: string
      water_damage_assessment_id?: string
      rooms: RoomInput[]
      save_results?: boolean  // If true, saves to equipment_calculations table
    }

    if (!job_id || !rooms || !Array.isArray(rooms) || rooms.length === 0) {
      return new Response(JSON.stringify({ error: 'job_id and rooms[] required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate each room
    for (const room of rooms) {
      if (!room.room_name || !room.length_ft || !room.width_ft || !room.height_ft || !room.water_class) {
        return new Response(JSON.stringify({
          error: `Room "${room.room_name || 'unnamed'}": room_name, length_ft, width_ft, height_ft, water_class required`,
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
      if (room.water_class < 1 || room.water_class > 4) {
        return new Response(JSON.stringify({
          error: `Room "${room.room_name}": water_class must be 1-4`,
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // Calculate all rooms
    const results = rooms.map(calculateRoom)

    // Aggregate totals
    const totals = {
      dehumidifiers: results.reduce((sum, r) => sum + r.total_equipment.dehumidifiers, 0),
      air_movers: results.reduce((sum, r) => sum + r.total_equipment.air_movers, 0),
      air_scrubbers: results.reduce((sum, r) => sum + r.total_equipment.air_scrubbers, 0),
      total_sqft: results.reduce((sum, r) => sum + r.dimensions.floor_sqft, 0),
      total_cubic_ft: results.reduce((sum, r) => sum + r.dimensions.cubic_ft, 0),
      room_count: results.length,
    }

    // Optionally save to database
    let saved_ids: string[] = []
    if (save_results) {
      const inserts = results.map((r) => ({
        company_id: companyId,
        job_id,
        tpa_assignment_id: tpa_assignment_id || null,
        water_damage_assessment_id: water_damage_assessment_id || null,
        created_by_user_id: user.id,
        room_name: r.room_name,
        room_length_ft: r.dimensions.length_ft,
        room_width_ft: r.dimensions.width_ft,
        room_height_ft: r.dimensions.height_ft,
        water_class: r.water_class,
        dehu_chart_factor: r.dehumidifier.chart_factor,
        dehu_ppd_needed: r.dehumidifier.ppd_needed,
        dehu_unit_ppd: r.dehumidifier.unit_ppd,
        dehu_units_required: r.dehumidifier.units_required,
        am_wall_units: r.air_mover.wall_units,
        am_floor_units: r.air_mover.floor_units,
        am_ceiling_units: r.air_mover.ceiling_units,
        am_floor_divisor: r.air_mover.floor_divisor,
        am_ceiling_divisor: r.air_mover.ceiling_divisor,
        am_inset_count: r.air_mover.inset_count,
        am_units_required: r.air_mover.units_required,
        scrubber_target_ach: r.air_scrubber.target_ach,
        scrubber_unit_cfm: r.air_scrubber.unit_cfm,
        scrubber_units_required: r.air_scrubber.units_required,
      }))

      const { data: savedData, error: saveError } = await supabase
        .from('equipment_calculations')
        .insert(inserts)
        .select('id')

      if (saveError) throw saveError
      saved_ids = (savedData || []).map((r: { id: string }) => r.id)
    }

    return new Response(JSON.stringify({
      rooms: results,
      totals,
      saved: save_results ? { count: saved_ids.length, ids: saved_ids } : null,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
