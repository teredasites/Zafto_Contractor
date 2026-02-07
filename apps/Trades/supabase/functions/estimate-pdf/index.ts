// Supabase Edge Function: estimate-pdf
// Generates a printable HTML estimate document matching Xactimate layout.
// GET ?claim_id=UUID → returns HTML page ready for print/PDF.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function fmt(n: number): string {
  return n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
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

  // Verify user token
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
    const claimId = url.searchParams.get('claim_id')
    const overheadRate = Number(url.searchParams.get('overhead') || 10)
    const profitRate = Number(url.searchParams.get('profit') || 10)

    if (!claimId) {
      return new Response(JSON.stringify({ error: 'claim_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch claim
    const { data: claim, error: claimErr } = await supabase
      .from('insurance_claims')
      .select('*')
      .eq('id', claimId)
      .single()

    if (claimErr || !claim) {
      return new Response(JSON.stringify({ error: 'Claim not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch company info
    const { data: profile } = await supabase
      .from('users')
      .select('company_id, name')
      .eq('id', user.id)
      .single()

    let companyName = 'ZAFTO Contractor'
    let companyPhone = ''
    let companyAddress = ''
    if (profile?.company_id) {
      const { data: company } = await supabase
        .from('companies')
        .select('name, phone, address_line1, address_city, address_state, address_zip')
        .eq('id', profile.company_id)
        .single()

      if (company) {
        companyName = company.name || companyName
        companyPhone = company.phone || ''
        companyAddress = [company.address_line1, company.address_city, company.address_state, company.address_zip].filter(Boolean).join(', ')
      }
    }

    // Fetch estimate lines
    const { data: lines } = await supabase
      .from('xactimate_estimate_lines')
      .select('*')
      .eq('claim_id', claimId)
      .order('room_name')
      .order('line_number')

    const estimateLines = lines || []

    // Group by room
    const roomGroups = new Map<string, typeof estimateLines>()
    for (const line of estimateLines) {
      const room = line.room_name || 'Unassigned'
      const existing = roomGroups.get(room) || []
      existing.push(line)
      roomGroups.set(room, existing)
    }

    // Calculate summary
    const groups = {
      structural: { rcv: 0, depreciation: 0, acv: 0 },
      contents: { rcv: 0, depreciation: 0, acv: 0 },
      other: { rcv: 0, depreciation: 0, acv: 0 },
    }

    for (const line of estimateLines) {
      const group = groups[line.coverage_group as keyof typeof groups] || groups.structural
      const rcv = Number(line.total || 0)
      const dep = rcv * (Number(line.depreciation_rate || 0) / 100)
      group.rcv += rcv
      group.depreciation += dep
      group.acv += rcv - dep
    }

    const subtotal = groups.structural.rcv + groups.contents.rcv + groups.other.rcv
    const overhead = subtotal * (overheadRate / 100)
    const profit = subtotal * (profitRate / 100)
    const grandTotal = subtotal + overhead + profit

    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })

    // Build HTML
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Estimate — ${escapeHtml(claim.claim_number || 'Draft')}</title>
<style>
  @page { size: letter; margin: 0.5in 0.6in; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', -apple-system, Arial, sans-serif; font-size: 9pt; color: #1a1a1a; line-height: 1.4; }
  .page-break { page-break-before: always; }

  /* Header */
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #2563eb; padding-bottom: 12px; margin-bottom: 16px; }
  .company-name { font-size: 18pt; font-weight: 700; color: #18181b; letter-spacing: -0.5px; }
  .company-detail { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .estimate-label { text-align: right; }
  .estimate-label h2 { font-size: 14pt; font-weight: 600; color: #2563eb; text-transform: uppercase; letter-spacing: 1px; }
  .estimate-label .date { font-size: 8pt; color: #71717a; margin-top: 2px; }

  /* Info grid */
  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
  .info-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px 12px; }
  .info-box h3 { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.8px; color: #a1a1aa; font-weight: 600; margin-bottom: 6px; }
  .info-row { display: flex; justify-content: space-between; font-size: 8.5pt; padding: 1px 0; }
  .info-label { color: #71717a; }
  .info-value { font-weight: 500; color: #18181b; }

  /* Room section */
  .room-section { margin-bottom: 16px; }
  .room-header { background: #18181b; color: white; padding: 6px 10px; font-size: 9pt; font-weight: 600; border-radius: 3px 3px 0 0; display: flex; justify-content: space-between; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #f4f4f5; font-size: 7pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; font-weight: 600; text-align: left; padding: 5px 8px; border-bottom: 1px solid #e4e4e7; }
  th.right, td.right { text-align: right; }
  td { font-size: 8.5pt; padding: 4px 8px; border-bottom: 1px solid #f4f4f5; }
  td.code { font-family: 'Courier New', monospace; font-size: 8pt; color: #2563eb; }
  tr:hover { background: #fafafa; }
  .room-total td { font-weight: 600; border-top: 1px solid #d4d4d8; background: #fafafa; }

  /* Summary */
  .summary { margin-top: 24px; border: 2px solid #18181b; border-radius: 6px; overflow: hidden; }
  .summary-title { background: #18181b; color: white; padding: 8px 12px; font-size: 11pt; font-weight: 600; }
  .summary-body { padding: 12px; }
  .summary-row { display: flex; justify-content: space-between; padding: 4px 0; font-size: 9pt; }
  .summary-row.coverage { padding-left: 16px; }
  .summary-row.group-header { font-weight: 600; font-size: 9.5pt; margin-top: 6px; border-bottom: 1px solid #e4e4e7; padding-bottom: 3px; }
  .summary-divider { border-top: 1px solid #d4d4d8; margin: 8px 0; }
  .summary-row.total { font-size: 13pt; font-weight: 700; margin-top: 4px; padding-top: 8px; border-top: 2px solid #18181b; }
  .label { color: #52525b; }
  .value { font-weight: 500; }
  .negative { color: #ef4444; }

  /* Coverage badges */
  .badge { display: inline-block; font-size: 7pt; padding: 1px 5px; border-radius: 3px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px; }
  .badge-structural { background: #dbeafe; color: #2563eb; }
  .badge-contents { background: #ede9fe; color: #7c3aed; }
  .badge-other { background: #fef3c7; color: #d97706; }

  /* Footer */
  .footer { margin-top: 32px; padding-top: 12px; border-top: 1px solid #e4e4e7; font-size: 7.5pt; color: #a1a1aa; text-align: center; }

  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }
</style>
</head>
<body>

<!-- Cover / Header -->
<div class="header">
  <div>
    <div class="company-name">${escapeHtml(companyName)}</div>
    ${companyPhone ? `<div class="company-detail">${escapeHtml(companyPhone)}</div>` : ''}
    ${companyAddress ? `<div class="company-detail">${escapeHtml(companyAddress)}</div>` : ''}
  </div>
  <div class="estimate-label">
    <h2>Estimate</h2>
    <div class="date">${today}</div>
  </div>
</div>

<!-- Claim Info -->
<div class="info-grid">
  <div class="info-box">
    <h3>Claim Information</h3>
    <div class="info-row"><span class="info-label">Claim #</span><span class="info-value">${escapeHtml(claim.claim_number || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Policy #</span><span class="info-value">${escapeHtml(claim.policy_number || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Loss Type</span><span class="info-value">${escapeHtml((claim.loss_type || '').replace(/_/g, ' '))}</span></div>
    <div class="info-row"><span class="info-label">Date of Loss</span><span class="info-value">${claim.date_of_loss ? new Date(claim.date_of_loss).toLocaleDateString('en-US') : 'N/A'}</span></div>
    <div class="info-row"><span class="info-label">Status</span><span class="info-value">${escapeHtml((claim.claim_status || '').replace(/_/g, ' '))}</span></div>
  </div>
  <div class="info-box">
    <h3>Property / Insured</h3>
    <div class="info-row"><span class="info-label">Customer</span><span class="info-value">${escapeHtml(claim.customer_name || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Address</span><span class="info-value">${escapeHtml(claim.property_address || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Carrier</span><span class="info-value">${escapeHtml(claim.insurance_carrier || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Adjuster</span><span class="info-value">${escapeHtml(claim.adjuster_name || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Adjuster Phone</span><span class="info-value">${escapeHtml(claim.adjuster_phone || 'N/A')}</span></div>
  </div>
</div>

<!-- Line Items by Room -->
${Array.from(roomGroups.entries()).map(([room, roomLines]) => {
  const roomTotal = roomLines.reduce((s: number, l: { total: number }) => s + Number(l.total || 0), 0)
  return `
<div class="room-section">
  <div class="room-header">
    <span>${escapeHtml(room)}</span>
    <span>${roomLines.length} items — $${fmt(roomTotal)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:80px">Code</th>
        <th>Description</th>
        <th class="right" style="width:40px">Qty</th>
        <th style="width:30px">Unit</th>
        <th class="right" style="width:60px">MAT</th>
        <th class="right" style="width:60px">LAB</th>
        <th class="right" style="width:60px">EQU</th>
        <th class="right" style="width:70px">Total</th>
        <th style="width:60px">Coverage</th>
      </tr>
    </thead>
    <tbody>
      ${roomLines.map((line: Record<string, unknown>) => `
      <tr>
        <td class="code">${escapeHtml(String(line.item_code || ''))}</td>
        <td>${escapeHtml(String(line.description || ''))}</td>
        <td class="right">${Number(line.quantity || 0)}</td>
        <td>${escapeHtml(String(line.unit || ''))}</td>
        <td class="right">$${fmt(Number(line.material_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.labor_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.equipment_cost || 0))}</td>
        <td class="right"><strong>$${fmt(Number(line.total || 0))}</strong></td>
        <td><span class="badge badge-${String(line.coverage_group || 'structural')}">${String(line.coverage_group || 'structural')}</span></td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="7" style="text-align:right">Room Total:</td>
        <td class="right">$${fmt(roomTotal)}</td>
        <td></td>
      </tr>
    </tbody>
  </table>
</div>`
}).join('')}

<!-- Summary -->
<div class="summary">
  <div class="summary-title">Estimate Summary</div>
  <div class="summary-body">
    ${groups.structural.rcv > 0 ? `
    <div class="summary-row group-header"><span>Structural</span></div>
    <div class="summary-row coverage"><span class="label">RCV</span><span class="value">$${fmt(groups.structural.rcv)}</span></div>
    <div class="summary-row coverage"><span class="label">Depreciation</span><span class="value negative">($${fmt(groups.structural.depreciation)})</span></div>
    <div class="summary-row coverage"><span class="label">ACV</span><span class="value">$${fmt(groups.structural.acv)}</span></div>
    ` : ''}
    ${groups.contents.rcv > 0 ? `
    <div class="summary-row group-header"><span>Contents</span></div>
    <div class="summary-row coverage"><span class="label">RCV</span><span class="value">$${fmt(groups.contents.rcv)}</span></div>
    <div class="summary-row coverage"><span class="label">Depreciation</span><span class="value negative">($${fmt(groups.contents.depreciation)})</span></div>
    <div class="summary-row coverage"><span class="label">ACV</span><span class="value">$${fmt(groups.contents.acv)}</span></div>
    ` : ''}
    ${groups.other.rcv > 0 ? `
    <div class="summary-row group-header"><span>Other</span></div>
    <div class="summary-row coverage"><span class="label">RCV</span><span class="value">$${fmt(groups.other.rcv)}</span></div>
    <div class="summary-row coverage"><span class="label">Depreciation</span><span class="value negative">($${fmt(groups.other.depreciation)})</span></div>
    <div class="summary-row coverage"><span class="label">ACV</span><span class="value">$${fmt(groups.other.acv)}</span></div>
    ` : ''}

    <div class="summary-divider"></div>
    <div class="summary-row"><span class="label">Subtotal (RCV)</span><span class="value">$${fmt(subtotal)}</span></div>
    <div class="summary-row"><span class="label">Overhead (${overheadRate}%)</span><span class="value">$${fmt(overhead)}</span></div>
    <div class="summary-row"><span class="label">Profit (${profitRate}%)</span><span class="value">$${fmt(profit)}</span></div>
    <div class="summary-row total"><span>Grand Total</span><span>$${fmt(grandTotal)}</span></div>
  </div>
</div>

<div class="footer">
  Generated by ${escapeHtml(companyName)} via ZAFTO &middot; ${today} &middot; ${estimateLines.length} line items
</div>

</body>
</html>`

    return new Response(html, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-cache',
      },
    })
  } catch (err) {
    console.error('PDF generation error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
