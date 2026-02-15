// Supabase Edge Function: generate-inspection-report
// Generates branded HTML inspection report with checklist results,
// deficiency findings, code citations, and signature blocks.
// GET ?inspection_id=UUID&format=summary|detailed|compliance
// Returns HTML page ready for print/PDF.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
}

function fmtDate(d: string | null): string {
  if (!d) return 'N/A'
  return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
}

function fmtDateTime(d: string | null): string {
  if (!d) return 'N/A'
  const dt = new Date(d)
  return `${dt.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })} at ${dt.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}`
}

function conditionLabel(c: string): string {
  const map: Record<string, string> = {
    excellent: 'Excellent', good: 'Pass', fair: 'Conditional',
    poor: 'Fail', damaged: 'Fail', missing: 'N/A',
  }
  return map[c] || c
}

function conditionColor(c: string): string {
  const map: Record<string, string> = {
    excellent: '#16a34a', good: '#16a34a', fair: '#d97706',
    poor: '#dc2626', damaged: '#dc2626', missing: '#9ca3af',
  }
  return map[c] || '#6b7280'
}

function severityColor(s: string): string {
  const map: Record<string, string> = {
    critical: '#dc2626', major: '#ea580c', minor: '#d97706', info: '#2563eb',
  }
  return map[s] || '#6b7280'
}

function typeLabel(t: string): string {
  return t.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
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

  try {
    const url = new URL(req.url)
    const inspectionId = url.searchParams.get('inspection_id')
    const format = url.searchParams.get('format') || 'detailed'

    if (!inspectionId) {
      return new Response(JSON.stringify({ error: 'inspection_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch inspection
    const { data: inspection, error: inspError } = await supabase
      .from('pm_inspections')
      .select('*')
      .eq('id', inspectionId)
      .single()

    if (inspError || !inspection) {
      return new Response(JSON.stringify({ error: 'Inspection not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch items
    const { data: items } = await supabase
      .from('pm_inspection_items')
      .select('*')
      .eq('inspection_id', inspectionId)
      .order('sort_order', { ascending: true })

    // Fetch deficiencies
    const { data: deficiencies } = await supabase
      .from('inspection_deficiencies')
      .select('*')
      .eq('inspection_id', inspectionId)
      .order('created_at', { ascending: true })

    // Fetch company info
    const companyId = user.app_metadata?.company_id || inspection.company_id
    const { data: company } = await supabase
      .from('companies')
      .select('name, logo_url, phone, email, address_line1, address_line2, city, state, zip')
      .eq('id', companyId)
      .single()

    // Fetch inspector name
    const { data: inspector } = await supabase
      .from('users')
      .select('first_name, last_name')
      .eq('id', inspection.inspector_id || user.id)
      .single()

    const inspectorName = inspector
      ? `${inspector.first_name || ''} ${inspector.last_name || ''}`.trim()
      : 'Inspector'

    // Build HTML based on format
    const html = buildReport(inspection, items || [], deficiencies || [], company, inspectorName, format)

    return new Response(html, {
      headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

function buildReport(
  inspection: any,
  items: any[],
  deficiencies: any[],
  company: any,
  inspectorName: string,
  format: string,
): string {
  const passed = (inspection.score || 0) >= 70
  const scoreColor = passed ? '#16a34a' : '#dc2626'
  const resultLabel = passed ? 'PASS' : 'FAIL'

  // Group items by area (section)
  const sections: Record<string, any[]> = {}
  for (const item of items) {
    const area = item.area || 'General'
    if (!sections[area]) sections[area] = []
    sections[area].push(item)
  }

  const isSummary = format === 'summary'
  const isCompliance = format === 'compliance'

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Inspection Report — ${escapeHtml(typeLabel(inspection.inspection_type))}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Inter', 'Segoe UI', sans-serif; color: #1a1a2e; line-height: 1.5; background: #fff; }
  .page { max-width: 800px; margin: 0 auto; padding: 40px 32px; }
  @media print { .page { padding: 20px; } .no-print { display: none !important; } }

  /* Header */
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #e2e8f0; padding-bottom: 20px; margin-bottom: 24px; }
  .company-info h1 { font-size: 20px; font-weight: 700; }
  .company-info p { font-size: 12px; color: #64748b; }
  .report-badge { text-align: right; }
  .report-badge .type { font-size: 14px; font-weight: 600; color: #475569; }
  .report-badge .date { font-size: 12px; color: #94a3b8; }

  /* Score block */
  .score-block { display: flex; align-items: center; gap: 20px; padding: 20px; background: #f8fafc; border-radius: 12px; margin-bottom: 24px; }
  .score-circle { width: 80px; height: 80px; border-radius: 50%; display: flex; flex-direction: column; align-items: center; justify-content: center; color: white; font-weight: 700; }
  .score-circle .num { font-size: 28px; line-height: 1; }
  .score-circle .label { font-size: 11px; letter-spacing: 1px; margin-top: 2px; }
  .score-details { flex: 1; }
  .score-details .row { display: flex; gap: 24px; margin-top: 8px; }
  .score-details .stat { font-size: 13px; color: #475569; }
  .score-details .stat strong { font-weight: 600; }

  /* Section */
  .section { margin-bottom: 24px; }
  .section-title { font-size: 13px; font-weight: 700; color: #64748b; letter-spacing: 1px; text-transform: uppercase; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #e2e8f0; }

  /* Item row */
  .item-row { display: flex; align-items: center; padding: 8px 0; border-bottom: 1px solid #f1f5f9; }
  .item-row:last-child { border-bottom: none; }
  .item-dot { width: 8px; height: 8px; border-radius: 50%; margin-right: 10px; flex-shrink: 0; }
  .item-name { flex: 1; font-size: 13px; }
  .item-result { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 4px; }
  .item-notes { font-size: 12px; color: #64748b; margin-left: 18px; margin-top: 2px; padding-bottom: 4px; }

  /* Deficiency */
  .deficiency { padding: 14px; background: #fef2f2; border-radius: 10px; border-left: 3px solid #dc2626; margin-bottom: 10px; }
  .deficiency.major { background: #fff7ed; border-left-color: #ea580c; }
  .deficiency.minor { background: #fffbeb; border-left-color: #d97706; }
  .deficiency.info { background: #eff6ff; border-left-color: #2563eb; }
  .def-header { display: flex; gap: 8px; margin-bottom: 6px; }
  .def-badge { font-size: 9px; font-weight: 700; letter-spacing: 0.5px; padding: 2px 6px; border-radius: 3px; }
  .def-desc { font-size: 13px; font-weight: 500; }
  .def-meta { font-size: 12px; color: #64748b; margin-top: 4px; }

  /* Signatures */
  .signatures { display: flex; gap: 40px; margin-top: 32px; padding-top: 20px; border-top: 2px solid #e2e8f0; }
  .sig-block { flex: 1; }
  .sig-label { font-size: 11px; color: #94a3b8; font-weight: 600; letter-spacing: 0.5px; text-transform: uppercase; margin-bottom: 8px; }
  .sig-line { border-bottom: 1px solid #cbd5e1; height: 50px; margin-bottom: 4px; }
  .sig-name { font-size: 12px; color: #475569; }

  /* Footer */
  .footer { text-align: center; padding-top: 20px; margin-top: 32px; border-top: 1px solid #e2e8f0; font-size: 11px; color: #94a3b8; }
</style>
</head>
<body>
<div class="page">

  <!-- HEADER -->
  <div class="header">
    <div class="company-info">
      <h1>${escapeHtml(company?.name || 'Company')}</h1>
      ${company?.phone ? `<p>${escapeHtml(company.phone)}</p>` : ''}
      ${company?.email ? `<p>${escapeHtml(company.email)}</p>` : ''}
      ${company?.address_line1 ? `<p>${escapeHtml(company.address_line1)}${company.city ? `, ${escapeHtml(company.city)}` : ''}${company.state ? ` ${escapeHtml(company.state)}` : ''} ${escapeHtml(company.zip || '')}</p>` : ''}
    </div>
    <div class="report-badge">
      <div class="type">${escapeHtml(typeLabel(inspection.inspection_type))} Inspection</div>
      <div class="date">${fmtDate(inspection.completed_date || inspection.created_at)}</div>
      ${isCompliance ? '<div class="type" style="margin-top:4px;color:#2563eb;">COMPLIANCE REPORT</div>' : ''}
    </div>
  </div>

  <!-- SCORE -->
  <div class="score-block">
    <div class="score-circle" style="background:${scoreColor}">
      <div class="num">${inspection.score || 0}</div>
      <div class="label">${resultLabel}</div>
    </div>
    <div class="score-details">
      <div style="font-size:15px;font-weight:600;">${escapeHtml(typeLabel(inspection.inspection_type))}</div>
      <div class="row">
        <div class="stat">Inspector: <strong>${escapeHtml(inspectorName)}</strong></div>
        <div class="stat">Items: <strong>${items.length}</strong></div>
        <div class="stat">Deficiencies: <strong>${deficiencies.length}</strong></div>
      </div>
      <div class="row">
        <div class="stat">Started: <strong>${fmtDateTime(inspection.created_at)}</strong></div>
        ${inspection.completed_date ? `<div class="stat">Completed: <strong>${fmtDateTime(inspection.completed_date)}</strong></div>` : ''}
      </div>
      ${inspection.trade ? `<div class="row"><div class="stat">Trade: <strong>${escapeHtml(typeLabel(inspection.trade))}</strong></div></div>` : ''}
    </div>
  </div>

  ${inspection.notes ? `
  <div class="section">
    <div class="section-title">Inspector Notes</div>
    <p style="font-size:13px;color:#475569;">${escapeHtml(inspection.notes)}</p>
  </div>
  ` : ''}

  <!-- CHECKLIST RESULTS -->
  ${!isSummary ? Object.entries(sections).map(([area, sectionItems]: [string, any[]]) => `
  <div class="section">
    <div class="section-title">${escapeHtml(area)}</div>
    ${sectionItems.map((item: any) => `
      <div class="item-row">
        <div class="item-dot" style="background:${conditionColor(item.condition)}"></div>
        <div class="item-name">${escapeHtml(item.item_name)}</div>
        <div class="item-result" style="background:${conditionColor(item.condition)}20;color:${conditionColor(item.condition)}">${conditionLabel(item.condition)}</div>
      </div>
      ${item.notes ? `<div class="item-notes">${escapeHtml(item.notes)}</div>` : ''}
    `).join('')}
  </div>
  `).join('') : `
  <div class="section">
    <div class="section-title">Summary</div>
    <p style="font-size:13px;color:#475569;">
      ${items.filter((i: any) => i.condition === 'good' || i.condition === 'excellent').length} items passed,
      ${items.filter((i: any) => i.condition === 'damaged' || i.condition === 'poor').length} items failed,
      ${items.filter((i: any) => i.condition === 'fair').length} conditional,
      ${items.filter((i: any) => i.condition === 'missing').length} N/A
      out of ${items.length} total items.
    </p>
  </div>
  `}

  <!-- DEFICIENCIES -->
  ${deficiencies.length > 0 ? `
  <div class="section">
    <div class="section-title">Deficiencies (${deficiencies.length})</div>
    ${deficiencies.map((d: any) => `
    <div class="deficiency ${d.severity}">
      <div class="def-header">
        <span class="def-badge" style="background:${severityColor(d.severity)}20;color:${severityColor(d.severity)}">${(d.severity || 'major').toUpperCase()}</span>
        <span class="def-badge" style="background:#e2e8f0;color:#475569">${(d.status || 'open').toUpperCase()}</span>
      </div>
      <div class="def-desc">${escapeHtml(d.description)}</div>
      ${d.code_section ? `<div class="def-meta">Code: ${escapeHtml(d.code_section)}${d.code_title ? ` — ${escapeHtml(d.code_title)}` : ''}</div>` : ''}
      ${d.remediation ? `<div class="def-meta">Remediation: ${escapeHtml(d.remediation)}</div>` : ''}
      ${d.deadline ? `<div class="def-meta">Deadline: ${fmtDate(d.deadline)}</div>` : ''}
    </div>
    `).join('')}
  </div>
  ` : ''}

  ${isCompliance ? `
  <div class="section">
    <div class="section-title">Compliance Statement</div>
    <p style="font-size:13px;color:#475569;">
      This inspection was conducted in accordance with applicable building codes, safety regulations, and industry standards.
      All findings documented herein represent the professional opinion of the inspector at the time of inspection.
      ${deficiencies.length > 0
        ? `${deficiencies.filter((d: any) => d.severity === 'critical').length} critical and ${deficiencies.filter((d: any) => d.severity === 'major').length} major deficiencies require correction before approval.`
        : 'No deficiencies were identified during this inspection.'}
    </p>
  </div>
  ` : ''}

  <!-- SIGNATURES -->
  <div class="signatures">
    <div class="sig-block">
      <div class="sig-label">Inspector Signature</div>
      <div class="sig-line"></div>
      <div class="sig-name">${escapeHtml(inspectorName)}</div>
    </div>
    <div class="sig-block">
      <div class="sig-label">Site Contact / Acknowledgment</div>
      <div class="sig-line"></div>
      <div class="sig-name">&nbsp;</div>
    </div>
  </div>

  <!-- FOOTER -->
  <div class="footer">
    Generated by Zafto &mdash; ${fmtDateTime(new Date().toISOString())}
    ${isCompliance ? ' &mdash; COMPLIANCE DOCUMENT' : ''}
  </div>

</div>
</body>
</html>`
}
