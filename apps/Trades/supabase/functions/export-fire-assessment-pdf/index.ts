// Supabase Edge Function: export-fire-assessment-pdf
// Generates insurance-grade HTML fire assessment report.
// GET ?assessment_id=UUID -> returns HTML page ready for print/PDF.
// Sprint REST1

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function esc(s: string | null | undefined): string {
  if (!s) return ''
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

function fmtDate(d: string | null): string {
  if (!d) return 'N/A'
  return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
}

function fmt(n: number): string {
  return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const sootLabels: Record<string, string> = {
  wet_smoke: 'Wet Smoke',
  dry_smoke: 'Dry Smoke',
  protein: 'Protein',
  fuel_oil: 'Fuel Oil',
  mixed: 'Mixed',
}

const zoneLabels: Record<string, string> = {
  direct_flame: 'Direct Flame',
  smoke: 'Smoke',
  heat: 'Heat',
  water_suppression: 'Water (Suppression)',
}

const conditionLabels: Record<string, string> = {
  salvageable: 'Salvageable',
  non_salvageable: 'Non-Salvageable',
  needs_cleaning: 'Needs Cleaning',
  needs_restoration: 'Needs Restoration',
  questionable: 'Questionable',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
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

  const url = new URL(req.url)
  const assessmentId = url.searchParams.get('assessment_id')
  if (!assessmentId) {
    return new Response(JSON.stringify({ error: 'Missing assessment_id' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch assessment
  const { data: assessment, error: aErr } = await supabase
    .from('fire_assessments')
    .select('*')
    .eq('id', assessmentId)
    .single()

  if (aErr || !assessment) {
    return new Response(JSON.stringify({ error: 'Assessment not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Verify company access
  const companyId = user.app_metadata?.company_id
  if (assessment.company_id !== companyId && user.app_metadata?.role !== 'super_admin') {
    return new Response(JSON.stringify({ error: 'Access denied' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Fetch company
  const { data: company } = await supabase
    .from('companies')
    .select('name, phone, email, address_line1, address_city, address_state, address_zip, logo_url')
    .eq('id', companyId)
    .single()

  // Fetch job
  const { data: job } = await supabase
    .from('jobs')
    .select('title, job_number, address')
    .eq('id', assessment.job_id)
    .single()

  // Fetch content packout items
  const { data: packoutItems } = await supabase
    .from('content_packout_items')
    .select('*')
    .eq('fire_assessment_id', assessmentId)
    .is('deleted_at', null)
    .order('room_of_origin')

  const items = packoutItems || []
  const damageZones = (assessment.damage_zones || []) as Array<Record<string, unknown>>
  const sootAssessments = (assessment.soot_assessments || []) as Array<Record<string, unknown>>
  const odorTreatments = (assessment.odor_treatments || []) as Array<Record<string, unknown>>
  const boardUpEntries = (assessment.board_up_entries || []) as Array<Record<string, unknown>>

  // Build HTML
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Fire Damage Assessment Report</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Helvetica Neue', Arial, sans-serif; font-size: 11px; color: #1a1a2e; line-height: 1.5; }
    .page { max-width: 8.5in; margin: 0 auto; padding: 0.5in; }
    h1 { font-size: 20px; font-weight: 700; color: #e65100; margin-bottom: 4px; }
    h2 { font-size: 14px; font-weight: 600; color: #1a1a2e; border-bottom: 2px solid #e65100; padding-bottom: 4px; margin: 16px 0 8px; }
    h3 { font-size: 12px; font-weight: 600; margin: 8px 0 4px; }
    .header { display: flex; justify-content: space-between; border-bottom: 3px solid #e65100; padding-bottom: 12px; margin-bottom: 16px; }
    .company-name { font-size: 16px; font-weight: 700; }
    .company-info { font-size: 10px; color: #666; }
    table { width: 100%; border-collapse: collapse; margin: 8px 0; }
    th, td { padding: 4px 8px; text-align: left; border: 1px solid #ddd; font-size: 10px; }
    th { background: #f5f5f5; font-weight: 600; }
    .badge { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 9px; font-weight: 600; }
    .badge-red { background: #fee; color: #c62828; }
    .badge-orange { background: #fff3e0; color: #e65100; }
    .badge-green { background: #e8f5e9; color: #2e7d32; }
    .badge-blue { background: #e3f2fd; color: #1565c0; }
    .badge-gray { background: #f5f5f5; color: #666; }
    .warning { background: #fff3e0; border: 1px solid #ffcc80; padding: 8px; border-radius: 4px; margin: 8px 0; }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
    .field-label { font-size: 9px; color: #888; text-transform: uppercase; letter-spacing: 0.5px; }
    .field-value { font-size: 11px; font-weight: 500; }
    .footer { margin-top: 24px; padding-top: 8px; border-top: 1px solid #ddd; font-size: 9px; color: #888; text-align: center; }
    @media print { .page { padding: 0.3in; } }
  </style>
</head>
<body>
<div class="page">
  <!-- HEADER -->
  <div class="header">
    <div>
      <div class="company-name">${esc(company?.name || 'Company')}</div>
      <div class="company-info">${esc(company?.phone || '')} | ${esc(company?.email || '')}</div>
      <div class="company-info">${esc(company?.address_line1 || '')} ${esc(company?.address_city || '')}, ${esc(company?.address_state || '')} ${esc(company?.address_zip || '')}</div>
    </div>
    <div style="text-align: right;">
      <h1>FIRE DAMAGE ASSESSMENT</h1>
      <div class="company-info">Report Date: ${fmtDate(new Date().toISOString())}</div>
      <div class="company-info">Job: ${esc(job?.title || '')} ${job?.job_number ? `(#${esc(job.job_number)})` : ''}</div>
    </div>
  </div>

  <!-- OVERVIEW -->
  <h2>Assessment Overview</h2>
  <div class="grid2">
    <div><span class="field-label">Origin Room</span><br><span class="field-value">${esc(assessment.origin_room) || 'Not specified'}</span></div>
    <div><span class="field-label">Severity</span><br><span class="field-value badge ${assessment.damage_severity === 'total_loss' || assessment.damage_severity === 'major' ? 'badge-red' : 'badge-orange'}">${esc((assessment.damage_severity || '').replace('_', ' ').toUpperCase())}</span></div>
    <div><span class="field-label">Date of Loss</span><br><span class="field-value">${fmtDate(assessment.date_of_loss)}</span></div>
    <div><span class="field-label">FD Report #</span><br><span class="field-value">${esc(assessment.fire_department_report_number) || 'N/A'}</span></div>
    <div><span class="field-label">Fire Department</span><br><span class="field-value">${esc(assessment.fire_department_name) || 'N/A'}</span></div>
    <div><span class="field-label">Status</span><br><span class="field-value badge badge-blue">${esc((assessment.assessment_status || '').replace('_', ' ').toUpperCase())}</span></div>
  </div>
  ${assessment.origin_description ? `<p style="margin-top:8px;"><strong>Description:</strong> ${esc(assessment.origin_description)}</p>` : ''}

  <!-- STRUCTURAL -->
  ${(assessment.structural_compromise || assessment.roof_damage || assessment.foundation_damage || assessment.load_bearing_affected) ? `
  <div class="warning">
    <strong>⚠ STRUCTURAL CONCERNS:</strong>
    ${assessment.structural_compromise ? ' Structural Compromise' : ''}
    ${assessment.roof_damage ? ' | Roof Damage' : ''}
    ${assessment.foundation_damage ? ' | Foundation Damage' : ''}
    ${assessment.load_bearing_affected ? ' | Load-Bearing Affected' : ''}
    ${assessment.structural_notes ? `<br><em>${esc(assessment.structural_notes)}</em>` : ''}
  </div>` : ''}

  <!-- DAMAGE ZONES -->
  ${damageZones.length > 0 ? `
  <h2>Damage Zones (${damageZones.length})</h2>
  <table>
    <thead><tr><th>Room</th><th>Zone Type</th><th>Severity</th><th>Soot Type</th><th>Notes</th></tr></thead>
    <tbody>
      ${damageZones.map((z) => `
        <tr>
          <td>${esc(z.room as string)}</td>
          <td>${zoneLabels[(z.zone_type as string)] || esc(z.zone_type as string)}</td>
          <td>${esc(z.severity as string)}</td>
          <td>${z.soot_type ? sootLabels[(z.soot_type as string)] || esc(z.soot_type as string) : '—'}</td>
          <td>${esc(z.notes as string) || '—'}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>` : ''}

  <!-- SOOT ASSESSMENTS -->
  ${sootAssessments.length > 0 ? `
  <h2>Soot Classification</h2>
  <table>
    <thead><tr><th>Room</th><th>Soot Type</th><th>Surfaces</th><th>Cleaning Method</th></tr></thead>
    <tbody>
      ${sootAssessments.map((s) => `
        <tr>
          <td>${esc(s.room as string)}</td>
          <td>${sootLabels[(s.soot_type as string)] || esc(s.soot_type as string)}</td>
          <td>${Array.isArray(s.surface_types) ? (s.surface_types as string[]).join(', ') : '—'}</td>
          <td>${esc(s.cleaning_method as string) || '—'}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>` : ''}

  <!-- BOARD-UP -->
  ${boardUpEntries.length > 0 ? `
  <h2>Emergency Board-Up (${boardUpEntries.length})</h2>
  <table>
    <thead><tr><th>Type</th><th>Location</th><th>Material</th><th>Dimensions</th><th>Secured</th></tr></thead>
    <tbody>
      ${boardUpEntries.map((b) => `
        <tr>
          <td>${esc(b.opening_type as string)}</td>
          <td>${esc(b.location as string)}</td>
          <td>${esc(b.material as string) || '—'}</td>
          <td>${esc(b.dimensions as string) || '—'}</td>
          <td>${b.secured_at ? fmtDate(b.secured_at as string) : '—'}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>` : ''}

  <!-- ODOR TREATMENT -->
  ${odorTreatments.length > 0 ? `
  <h2>Odor Treatment (${odorTreatments.length})</h2>
  <table>
    <thead><tr><th>Method</th><th>Room</th><th>Status</th><th>Pre-Reading</th><th>Post-Reading</th></tr></thead>
    <tbody>
      ${odorTreatments.map((t) => `
        <tr>
          <td>${esc((t.method as string || '').replace('_', ' '))}</td>
          <td>${esc(t.room as string)}</td>
          <td><span class="badge ${t.end_time ? 'badge-green' : 'badge-blue'}">${t.end_time ? 'COMPLETE' : 'ACTIVE'}</span></td>
          <td>${t.pre_reading != null ? t.pre_reading : '—'}</td>
          <td>${t.post_reading != null ? t.post_reading : '—'}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>` : ''}

  <!-- CONTENT PACK-OUT -->
  ${items.length > 0 ? `
  <h2>Content Pack-out Inventory (${items.length} items)</h2>
  <table>
    <thead><tr><th>Item</th><th>Room</th><th>Category</th><th>Condition</th><th>Box</th><th>Est. Value</th></tr></thead>
    <tbody>
      ${items.map((item: Record<string, unknown>) => `
        <tr>
          <td>${esc(item.item_description as string)}</td>
          <td>${esc(item.room_of_origin as string)}</td>
          <td>${esc((item.category as string || '').replace('_', ' '))}</td>
          <td><span class="badge ${item.condition === 'non_salvageable' ? 'badge-red' : item.condition === 'salvageable' ? 'badge-green' : 'badge-orange'}">${conditionLabels[(item.condition as string)] || esc(item.condition as string)}</span></td>
          <td>${esc(item.box_number as string) || '—'}</td>
          <td>${item.estimated_value != null ? '$' + fmt(item.estimated_value as number) : '—'}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>
  <p style="margin-top:4px;text-align:right;">
    <strong>Total Estimated Value: $${fmt(items.reduce((s: number, i: Record<string, unknown>) => s + ((i.estimated_value as number) || 0), 0))}</strong>
  </p>` : ''}

  ${assessment.water_damage_from_suppression ? `
  <div class="warning">
    <strong>ℹ WATER DAMAGE FROM FIRE SUPPRESSION:</strong> Water damage assessment linked. See separate water damage report.
  </div>` : ''}

  ${assessment.notes ? `
  <h2>Additional Notes</h2>
  <p>${esc(assessment.notes)}</p>` : ''}

  <!-- FOOTER -->
  <div class="footer">
    <p>Generated by Zafto | ${fmtDate(new Date().toISOString())} | Assessment ID: ${assessment.id}</p>
    <p>This report is generated for insurance documentation purposes. Contents should be verified by a licensed adjuster.</p>
  </div>
</div>
</body>
</html>`

  return new Response(html, {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
    },
  })
})
