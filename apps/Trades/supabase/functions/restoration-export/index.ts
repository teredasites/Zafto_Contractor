// Supabase Edge Function: restoration-export
// Exports restoration job data in multiple formats:
// - FML (JSON-based floor plan, Symbility/Cotality compatible)
// - DXF (universal CAD format for floor plans)
// - PDF documentation package (photos + readings + equipment + estimate)
// POST: { job_id, format: 'fml' | 'dxf' | 'pdf' }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type ExportFormat = 'fml' | 'dxf' | 'pdf'

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
    const { job_id, format } = body as { job_id: string; format: ExportFormat }

    if (!job_id || !format) {
      return new Response(JSON.stringify({ error: 'job_id and format required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!['fml', 'dxf', 'pdf'].includes(format)) {
      return new Response(JSON.stringify({ error: 'Invalid format. Use: fml, dxf, pdf' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify job belongs to company
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('id, title, address, status, job_type, created_at')
      .eq('id', job_id)
      .eq('company_id', companyId)
      .single()

    if (jobError || !job) {
      return new Response(JSON.stringify({ error: 'Job not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (format === 'fml') {
      return generateFML(supabase, job, companyId)
    } else if (format === 'dxf') {
      return generateDXF(supabase, job, companyId)
    } else {
      return generatePDFPackage(supabase, job, companyId)
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// FML EXPORT — JSON-based floor plan (open format)
// ============================================================================

async function generateFML(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  companyId: string
) {
  // Get rooms/areas from sketch data
  const { data: sketches } = await supabase
    .from('sketch_rooms')
    .select('*')
    .eq('job_id', job.id)
    .eq('company_id', companyId)
    .order('floor_number', { ascending: true })

  // Get moisture readings
  const { data: readings } = await supabase
    .from('moisture_readings')
    .select('*')
    .eq('job_id', job.id)
    .eq('company_id', companyId)

  // Get equipment deployments
  const { data: equipment } = await supabase
    .from('restoration_equipment')
    .select('*')
    .eq('job_id', job.id)

  const fml = {
    version: '1.0',
    format: 'zafto-fml',
    exported_at: new Date().toISOString(),
    project: {
      name: job.title,
      address: job.address,
      job_type: job.job_type,
      created_at: job.created_at,
    },
    floors: groupByFloor(sketches || []),
    moisture_data: (readings || []).map((r: Record<string, unknown>) => ({
      location: r.location,
      material: r.material_type,
      value: r.reading_value,
      unit: r.reading_unit,
      timestamp: r.reading_date,
      area: r.area_name,
    })),
    equipment: (equipment || []).map((e: Record<string, unknown>) => ({
      type: e.equipment_type,
      name: e.equipment_name,
      area: e.area_deployed,
      deployed_at: e.deployed_at,
      removed_at: e.removed_at,
      daily_rate: e.daily_rate,
    })),
  }

  return new Response(JSON.stringify(fml, null, 2), {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="${job.title}-floorplan.fml.json"`,
    },
  })
}

function groupByFloor(rooms: Record<string, unknown>[]) {
  const floors: Record<number, Record<string, unknown>[]> = {}
  for (const room of rooms) {
    const floor = (room.floor_number as number) || 1
    if (!floors[floor]) floors[floor] = []
    floors[floor].push({
      name: room.room_name,
      length: room.length_ft,
      width: room.width_ft,
      height: room.height_ft,
      area_sf: room.area_sf,
      perimeter_lf: room.perimeter_lf,
      room_type: room.room_type,
      affected: room.is_affected,
      water_class: room.water_class,
      water_category: room.water_category,
    })
  }
  return Object.entries(floors).map(([floor, rooms]) => ({
    floor_number: parseInt(floor),
    rooms,
  }))
}

// ============================================================================
// DXF EXPORT — Universal CAD format
// ============================================================================

async function generateDXF(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  companyId: string
) {
  const { data: sketches } = await supabase
    .from('sketch_rooms')
    .select('*')
    .eq('job_id', job.id)
    .eq('company_id', companyId)

  const rooms = sketches || []

  // Generate minimal DXF (AutoCAD compatible)
  let dxf = ''
  dxf += '0\nSECTION\n2\nHEADER\n'
  dxf += '9\n$ACADVER\n1\nAC1014\n'  // AutoCAD R14 compatible
  dxf += '0\nENDSEC\n'

  // Tables section
  dxf += '0\nSECTION\n2\nTABLES\n'
  dxf += '0\nTABLE\n2\nLAYER\n70\n3\n'
  dxf += '0\nLAYER\n2\nWALLS\n70\n0\n62\n7\n6\nCONTINUOUS\n'
  dxf += '0\nLAYER\n2\nROOM_LABELS\n70\n0\n62\n3\n6\nCONTINUOUS\n'
  dxf += '0\nLAYER\n2\nAFFECTED\n70\n0\n62\n1\n6\nCONTINUOUS\n'
  dxf += '0\nENDTAB\n'
  dxf += '0\nENDSEC\n'

  // Entities section — draw rooms as rectangles
  dxf += '0\nSECTION\n2\nENTITIES\n'

  let xOffset = 0
  const scale = 12  // 1 ft = 12 DXF units
  const gap = 5 * scale

  for (const room of rooms) {
    const w = ((room.length_ft as number) || 10) * scale
    const h = ((room.width_ft as number) || 10) * scale
    const layer = room.is_affected ? 'AFFECTED' : 'WALLS'

    // Draw rectangle (4 lines)
    const x1 = xOffset, y1 = 0
    const x2 = xOffset + w, y2 = h

    // Bottom
    dxf += `0\nLINE\n8\n${layer}\n10\n${x1}\n20\n${y1}\n30\n0\n11\n${x2}\n21\n${y1}\n31\n0\n`
    // Right
    dxf += `0\nLINE\n8\n${layer}\n10\n${x2}\n20\n${y1}\n30\n0\n11\n${x2}\n21\n${y2}\n31\n0\n`
    // Top
    dxf += `0\nLINE\n8\n${layer}\n10\n${x2}\n20\n${y2}\n30\n0\n11\n${x1}\n21\n${y2}\n31\n0\n`
    // Left
    dxf += `0\nLINE\n8\n${layer}\n10\n${x1}\n20\n${y2}\n30\n0\n11\n${x1}\n21\n${y1}\n31\n0\n`

    // Room label
    const labelX = xOffset + w / 2
    const labelY = h / 2
    dxf += `0\nTEXT\n8\nROOM_LABELS\n10\n${labelX}\n20\n${labelY}\n30\n0\n40\n${scale * 0.8}\n1\n${room.room_name || 'Room'}\n72\n1\n11\n${labelX}\n21\n${labelY}\n31\n0\n`

    xOffset += w + gap
  }

  dxf += '0\nENDSEC\n'
  dxf += '0\nEOF\n'

  return new Response(dxf, {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/dxf',
      'Content-Disposition': `attachment; filename="${job.title}-floorplan.dxf"`,
    },
  })
}

// ============================================================================
// PDF PACKAGE — Documentation package metadata (client generates actual PDF)
// ============================================================================

async function generatePDFPackage(
  supabase: ReturnType<typeof createClient>,
  job: Record<string, unknown>,
  companyId: string
) {
  // Collect all documentation for the job
  const [
    { data: photos },
    { data: readings },
    { data: equipment },
    { data: estimates },
    { data: assignment },
    { data: docProgress },
  ] = await Promise.all([
    supabase.from('job_photos').select('*').eq('job_id', job.id).eq('company_id', companyId).order('created_at'),
    supabase.from('moisture_readings').select('*').eq('job_id', job.id).eq('company_id', companyId).order('reading_date'),
    supabase.from('restoration_equipment').select('*').eq('job_id', job.id).order('deployed_at'),
    supabase.from('estimates').select('id, title, total, status').eq('job_id', job.id).eq('company_id', companyId),
    supabase.from('tpa_assignments').select('*, tpa_programs(name)').eq('job_id', job.id).eq('company_id', companyId).limit(1).maybeSingle(),
    supabase.from('job_doc_progress').select('*, doc_checklist_items(item_name, phase, is_required)').eq('job_id', job.id).eq('company_id', companyId),
  ])

  // Build structured PDF data package
  const pdfData = {
    meta: {
      format: 'zafto-pdf-package',
      generated_at: new Date().toISOString(),
      job_title: job.title,
      job_address: job.address,
      job_type: job.job_type,
    },
    tpa: assignment ? {
      program_name: (assignment.tpa_programs as Record<string, unknown>)?.name,
      claim_number: assignment.claim_number,
      insured_name: assignment.insured_name,
      loss_date: assignment.loss_date,
      loss_type: assignment.loss_type,
    } : null,
    sections: {
      photos: {
        count: (photos || []).length,
        items: (photos || []).map((p: Record<string, unknown>) => ({
          url: p.photo_url,
          caption: p.caption,
          phase: p.phase,
          taken_at: p.created_at,
        })),
      },
      moisture_readings: {
        count: (readings || []).length,
        items: (readings || []).map((r: Record<string, unknown>) => ({
          location: r.location,
          material: r.material_type,
          value: r.reading_value,
          unit: r.reading_unit,
          date: r.reading_date,
        })),
      },
      equipment: {
        count: (equipment || []).length,
        items: (equipment || []).map((e: Record<string, unknown>) => ({
          type: e.equipment_type,
          name: e.equipment_name,
          area: e.area_deployed,
          deployed: e.deployed_at,
          removed: e.removed_at,
          daily_rate: e.daily_rate,
        })),
      },
      estimates: {
        count: (estimates || []).length,
        items: (estimates || []).map((e: Record<string, unknown>) => ({
          title: e.title,
          total: e.total,
          status: e.status,
        })),
      },
      documentation_compliance: {
        total_items: (docProgress || []).length,
        completed: (docProgress || []).filter((d: Record<string, unknown>) => d.completed_at != null).length,
      },
    },
  }

  return new Response(JSON.stringify(pdfData, null, 2), {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="${job.title}-documentation-package.json"`,
    },
  })
}
