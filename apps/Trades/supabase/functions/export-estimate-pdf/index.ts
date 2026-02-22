// Supabase Edge Function: export-estimate-pdf
// Generates a professional branded HTML estimate document from D8 estimate tables.
// GET ?estimate_id=UUID&template=standard|detailed|summary → returns HTML page ready for print/PDF.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limiter.ts'

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

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Rate limit: 10 requests per minute per user
  const rateCheck = await checkRateLimit(supabase, {
    key: `user:${user.id}:export-estimate-pdf`,
    maxRequests: 10,
    windowSeconds: 60,
  })
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)

  try {
    const url = new URL(req.url)
    const estimateId = url.searchParams.get('estimate_id')
    const template = url.searchParams.get('template') || 'standard'

    if (!estimateId) {
      return new Response(JSON.stringify({ error: 'estimate_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch estimate + areas + line items in parallel
    const [estRes, areasRes, linesRes] = await Promise.all([
      supabase.from('estimates').select('*').eq('id', estimateId).single(),
      supabase.from('estimate_areas').select('*').eq('estimate_id', estimateId).order('sort_order'),
      supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
    ])

    if (estRes.error || !estRes.data) {
      return new Response(JSON.stringify({ error: 'Estimate not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const estimate = estRes.data
    const areas = areasRes.data || []
    const lineItems = linesRes.data || []

    // Fetch company branding
    const { data: profile } = await supabase
      .from('users')
      .select('company_id, name')
      .eq('id', user.id)
      .single()

    let companyName = 'ZAFTO Contractor'
    let companyPhone = ''
    let companyEmail = ''
    let companyAddress = ''
    let companyLogoUrl = ''

    if (profile?.company_id) {
      const { data: company } = await supabase
        .from('companies')
        .select('name, phone, email, address_line1, address_city, address_state, address_zip, logo_url')
        .eq('id', profile.company_id)
        .single()

      if (company) {
        companyName = company.name || companyName
        companyPhone = company.phone || ''
        companyEmail = company.email || ''
        companyAddress = [company.address_line1, company.address_city, company.address_state, company.address_zip].filter(Boolean).join(', ')
        companyLogoUrl = company.logo_url || ''
      }
    }

    // Fetch material catalog + change orders (for proposal template)
    let catalogItems: Array<Record<string, unknown>> = []
    let changeOrders: Array<Record<string, unknown>> = []

    if (template === 'proposal' || template === 'detailed') {
      const [catalogRes, coRes] = await Promise.all([
        supabase.from('estimate_material_catalog').select('*').eq('estimate_id', estimateId).is('deleted_at', null),
        supabase.from('estimate_change_orders').select('*').eq('estimate_id', estimateId).eq('status', 'approved').is('deleted_at', null),
      ])
      catalogItems = catalogRes.data || []
      changeOrders = coRes.data || []
    }

    const changeOrderTotal = changeOrders.reduce((s: number, co: Record<string, unknown>) => s + Number(co.amount || 0), 0)

    // Group line items by area
    const areaMap = new Map<string, Record<string, unknown>>()
    for (const area of areas) {
      areaMap.set(area.id, area)
    }

    const linesByArea = new Map<string, Array<Record<string, unknown>>>()
    const unassigned: Array<Record<string, unknown>> = []
    for (const line of lineItems) {
      if (line.area_id && areaMap.has(line.area_id)) {
        const existing = linesByArea.get(line.area_id) || []
        existing.push(line)
        linesByArea.set(line.area_id, existing)
      } else {
        unassigned.push(line)
      }
    }

    // Calculate totals
    const subtotal = lineItems.reduce((s: number, l: Record<string, unknown>) => s + Number(l.line_total || 0), 0)
    const overheadPct = Number(estimate.overhead_percent || 0)
    const profitPct = Number(estimate.profit_percent || 0)
    const taxPct = Number(estimate.tax_percent || 0)
    const overhead = subtotal * (overheadPct / 100)
    const profit = subtotal * (profitPct / 100)
    const taxable = subtotal + overhead + profit
    const tax = taxable * (taxPct / 100)
    const grandTotal = taxable + tax

    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    const isInsurance = estimate.estimate_type === 'insurance'
    const propertyLine = [estimate.property_address, estimate.property_city, estimate.property_state, estimate.property_zip].filter(Boolean).join(', ')

    // ── Build HTML sections based on template ──

    let lineItemsHtml = ''

    if (template === 'summary') {
      // Summary: room totals only, no individual line items
      lineItemsHtml = areas.map((area: Record<string, unknown>) => {
        const areaLines = linesByArea.get(area.id as string) || []
        const areaTotal = areaLines.reduce((s: number, l: Record<string, unknown>) => s + Number(l.line_total || 0), 0)
        return `
<div class="summary-area">
  <div class="area-summary-row">
    <span class="area-name">${escapeHtml(String(area.name || ''))}</span>
    <span class="area-items">${areaLines.length} items</span>
    <span class="area-total">$${fmt(areaTotal)}</span>
  </div>
</div>`
      }).join('')

      if (unassigned.length > 0) {
        const unTotal = unassigned.reduce((s: number, l: Record<string, unknown>) => s + Number(l.line_total || 0), 0)
        lineItemsHtml += `
<div class="summary-area">
  <div class="area-summary-row">
    <span class="area-name">Other Items</span>
    <span class="area-items">${unassigned.length} items</span>
    <span class="area-total">$${fmt(unTotal)}</span>
  </div>
</div>`
      }

    } else {
      // Standard and Detailed templates
      const showBreakdown = template === 'detailed'

      for (const area of areas) {
        const areaLines = linesByArea.get(area.id as string) || []
        if (areaLines.length === 0) continue
        const areaTotal = areaLines.reduce((s: number, l: Record<string, unknown>) => s + Number(l.line_total || 0), 0)

        lineItemsHtml += `
<div class="room-section">
  <div class="room-header">
    <span>${escapeHtml(String(area.name || ''))}</span>
    <span>${areaLines.length} items — $${fmt(areaTotal)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:70px">Code</th>
        <th>Description</th>
        <th style="width:60px">Action</th>
        <th class="right" style="width:40px">Qty</th>
        <th style="width:30px">Unit</th>
        ${showBreakdown ? `
        <th class="right" style="width:55px">MAT</th>
        <th class="right" style="width:55px">LAB</th>
        <th class="right" style="width:55px">EQU</th>` : ''}
        <th class="right" style="width:70px">Total</th>
      </tr>
    </thead>
    <tbody>
      ${areaLines.map((line: Record<string, unknown>) => `
      <tr>
        <td class="code">${escapeHtml(String(line.zafto_code || ''))}</td>
        <td>${escapeHtml(String(line.description || ''))}${line.notes ? `<div class="line-note">${escapeHtml(String(line.notes))}</div>` : ''}</td>
        <td class="action-badge">${escapeHtml(String(line.action_type || ''))}</td>
        <td class="right">${Number(line.quantity || 0)} ${escapeHtml(String(line.unit_code || ''))}</td>
        <td>$${fmt(Number(line.unit_price || 0))}</td>
        ${showBreakdown ? `
        <td class="right">$${fmt(Number(line.material_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.labor_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.equipment_cost || 0))}</td>` : ''}
        <td class="right"><strong>$${fmt(Number(line.line_total || 0))}</strong></td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="${showBreakdown ? 8 : 5}" style="text-align:right">Room Total:</td>
        <td class="right">$${fmt(areaTotal)}</td>
      </tr>
    </tbody>
  </table>
</div>`
      }

      // Unassigned items
      if (unassigned.length > 0) {
        const unTotal = unassigned.reduce((s: number, l: Record<string, unknown>) => s + Number(l.line_total || 0), 0)
        lineItemsHtml += `
<div class="room-section">
  <div class="room-header">
    <span>Other Items</span>
    <span>${unassigned.length} items — $${fmt(unTotal)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:70px">Code</th>
        <th>Description</th>
        <th style="width:60px">Action</th>
        <th class="right" style="width:40px">Qty</th>
        <th style="width:30px">Unit</th>
        ${showBreakdown ? `
        <th class="right" style="width:55px">MAT</th>
        <th class="right" style="width:55px">LAB</th>
        <th class="right" style="width:55px">EQU</th>` : ''}
        <th class="right" style="width:70px">Total</th>
      </tr>
    </thead>
    <tbody>
      ${unassigned.map((line: Record<string, unknown>) => `
      <tr>
        <td class="code">${escapeHtml(String(line.zafto_code || ''))}</td>
        <td>${escapeHtml(String(line.description || ''))}</td>
        <td class="action-badge">${escapeHtml(String(line.action_type || ''))}</td>
        <td class="right">${Number(line.quantity || 0)} ${escapeHtml(String(line.unit_code || ''))}</td>
        <td>$${fmt(Number(line.unit_price || 0))}</td>
        ${showBreakdown ? `
        <td class="right">$${fmt(Number(line.material_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.labor_cost || 0))}</td>
        <td class="right">$${fmt(Number(line.equipment_cost || 0))}</td>` : ''}
        <td class="right"><strong>$${fmt(Number(line.line_total || 0))}</strong></td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="${showBreakdown ? 8 : 5}" style="text-align:right">Total:</td>
        <td class="right">$${fmt(unTotal)}</td>
      </tr>
    </tbody>
  </table>
</div>`
      }
    }

    // ── Insurance summary section ──
    let insuranceHtml = ''
    if (isInsurance) {
      const deductible = Number(estimate.deductible || 0)
      const netClaim = Math.max(0, grandTotal - deductible)
      insuranceHtml = `
<div class="insurance-summary">
  <div class="summary-row"><span class="label">Replacement Cost Value (RCV)</span><span class="value">$${fmt(grandTotal)}</span></div>
  <div class="summary-row"><span class="label">Deductible</span><span class="value negative">($${fmt(deductible)})</span></div>
  <div class="summary-divider"></div>
  <div class="summary-row" style="font-weight:700;"><span>Net Claim</span><span>$${fmt(netClaim)}</span></div>
</div>`
    }

    // ── Build proposal-specific sections ──
    let changeOrderHtml = ''
    if (changeOrderTotal > 0) {
      changeOrderHtml = `
<div class="change-order-section">
  <div class="summary-row"><span class="label">Approved Change Orders</span><span class="value">$${fmt(changeOrderTotal)}</span></div>
  <div class="summary-divider"></div>
  <div class="summary-row" style="font-weight:700;"><span>Adjusted Grand Total</span><span>$${fmt(grandTotal + changeOrderTotal)}</span></div>
</div>`
    }

    // G/B/B tier comparison (proposal template only)
    let gbbHtml = ''
    if (template === 'proposal' && catalogItems.length > 0) {
      // Build tier groupings from catalog
      const tierGroups: Record<string, { count: number; total: number }> = { standard: { count: 0, total: 0 }, premium: { count: 0, total: 0 }, elite: { count: 0, total: 0 } }
      for (const item of catalogItems) {
        const t = String(item.tier || 'standard')
        if (tierGroups[t]) {
          tierGroups[t].count++
          tierGroups[t].total += Number(item.unit_price || 0)
        }
      }
      const hasTierData = Object.values(tierGroups).some(g => g.count > 0)
      if (hasTierData) {
        gbbHtml = `
<div class="gbb-section">
  <h3 class="section-title">Material Tier Options</h3>
  <div class="gbb-grid">
    <div class="gbb-col">
      <div class="gbb-label" style="color:#3b82f6;">Good</div>
      <div class="gbb-desc">Standard materials</div>
      <div class="gbb-count">${tierGroups.standard.count} items</div>
    </div>
    <div class="gbb-col">
      <div class="gbb-label" style="color:#10b981;">Better</div>
      <div class="gbb-desc">Premium materials</div>
      <div class="gbb-count">${tierGroups.premium.count} items</div>
    </div>
    <div class="gbb-col">
      <div class="gbb-label" style="color:#f59e0b;">Best</div>
      <div class="gbb-desc">Elite materials</div>
      <div class="gbb-count">${tierGroups.elite.count} items</div>
    </div>
  </div>
</div>`
      }
    }

    // Warranty summary (proposal template)
    let warrantyHtml = ''
    if (template === 'proposal') {
      const withWarranty = catalogItems.filter((m: Record<string, unknown>) => m.warranty_years && Number(m.warranty_years) > 0)
      if (withWarranty.length > 0) {
        const minW = Math.min(...withWarranty.map((m: Record<string, unknown>) => Number(m.warranty_years)))
        const maxW = Math.max(...withWarranty.map((m: Record<string, unknown>) => Number(m.warranty_years)))
        warrantyHtml = `
<div class="warranty-section">
  <h3 class="section-title">Warranty Coverage</h3>
  <p class="warranty-range">${withWarranty.length} materials with manufacturer warranty: ${minW === maxW ? `${minW} years` : `${minW}–${maxW} years`}</p>
  <div class="warranty-list">
    ${withWarranty.slice(0, 8).map((m: Record<string, unknown>) => `
    <div class="warranty-item">
      <span>${escapeHtml(String(m.description || ''))}${m.brand ? ` (${escapeHtml(String(m.brand))})` : ''}</span>
      <span class="warranty-years">${m.warranty_years} yr</span>
    </div>`).join('')}
  </div>
</div>`
      }
    }

    // Terms & conditions (proposal template)
    let termsHtml = ''
    if (template === 'proposal') {
      termsHtml = `
<div class="terms-section">
  <h3 class="section-title">Terms &amp; Conditions</h3>
  <ol class="terms-list">
    <li>This estimate is valid for 30 days from the date of issue unless otherwise noted.</li>
    <li>Payment terms: Due upon completion unless otherwise agreed in writing.</li>
    <li>Any alterations or deviations from the above specifications involving extra costs will be executed only upon written change order.</li>
    <li>All materials are guaranteed to be as specified. All work shall be completed in a workmanlike manner.</li>
    <li>Owner agrees to carry fire and extended coverage insurance. Contractor liability is limited to the value of work performed.</li>
    <li>Prices are based on current material costs and are subject to change if project start is delayed beyond the validity period.</li>
  </ol>
</div>`
    }

    // ── Final HTML ──
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Estimate ${escapeHtml(estimate.estimate_number || '')} — ${escapeHtml(estimate.title || 'Draft')}</title>
<style>
  @page { size: letter; margin: 0.5in 0.6in; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', -apple-system, Arial, sans-serif; font-size: 9pt; color: #1a1a1a; line-height: 1.4; }
  .page-break { page-break-before: always; }

  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #18181b; padding-bottom: 12px; margin-bottom: 16px; }
  .company-name { font-size: 18pt; font-weight: 700; color: #18181b; letter-spacing: -0.5px; }
  .company-detail { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .estimate-label { text-align: right; }
  .estimate-label h2 { font-size: 14pt; font-weight: 600; color: #18181b; text-transform: uppercase; letter-spacing: 1px; }
  .estimate-label .meta { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .type-badge { display: inline-block; font-size: 7pt; padding: 2px 8px; border-radius: 3px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-top: 4px; }
  .type-regular { background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; }
  .type-insurance { background: #faf5ff; color: #9333ea; border: 1px solid #e9d5ff; }

  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
  .info-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px 12px; }
  .info-box h3 { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.8px; color: #a1a1aa; font-weight: 600; margin-bottom: 6px; }
  .info-row { display: flex; justify-content: space-between; font-size: 8.5pt; padding: 1px 0; }
  .info-label { color: #71717a; }
  .info-value { font-weight: 500; color: #18181b; }

  .room-section { margin-bottom: 16px; }
  .room-header { background: #18181b; color: white; padding: 6px 10px; font-size: 9pt; font-weight: 600; border-radius: 3px 3px 0 0; display: flex; justify-content: space-between; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #f4f4f5; font-size: 7pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; font-weight: 600; text-align: left; padding: 5px 8px; border-bottom: 1px solid #e4e4e7; }
  th.right, td.right { text-align: right; }
  td { font-size: 8.5pt; padding: 4px 8px; border-bottom: 1px solid #f4f4f5; }
  td.code { font-family: 'Courier New', monospace; font-size: 8pt; color: #2563eb; }
  td.action-badge { font-size: 7.5pt; text-transform: capitalize; color: #52525b; }
  .line-note { font-size: 7.5pt; color: #a1a1aa; margin-top: 1px; }
  tr:hover { background: #fafafa; }
  .room-total td { font-weight: 600; border-top: 1px solid #d4d4d8; background: #fafafa; }

  .summary-area { padding: 8px 12px; border-bottom: 1px solid #e4e4e7; }
  .area-summary-row { display: flex; align-items: center; gap: 16px; font-size: 9.5pt; }
  .area-name { font-weight: 600; color: #18181b; flex: 1; }
  .area-items { font-size: 8pt; color: #71717a; }
  .area-total { font-weight: 600; color: #18181b; }

  .summary { margin-top: 24px; border: 2px solid #18181b; border-radius: 6px; overflow: hidden; }
  .summary-title { background: #18181b; color: white; padding: 8px 12px; font-size: 11pt; font-weight: 600; }
  .summary-body { padding: 12px; }
  .summary-row { display: flex; justify-content: space-between; padding: 4px 0; font-size: 9pt; }
  .summary-divider { border-top: 1px solid #d4d4d8; margin: 8px 0; }
  .summary-row.total { font-size: 13pt; font-weight: 700; margin-top: 4px; padding-top: 8px; border-top: 2px solid #18181b; }
  .label { color: #52525b; }
  .value { font-weight: 500; }
  .negative { color: #ef4444; }

  .insurance-summary { margin-top: 12px; padding: 12px; background: #faf5ff; border: 1px solid #e9d5ff; border-radius: 4px; }

  .notes-section { margin-top: 20px; padding: 12px; background: #fafafa; border: 1px solid #e4e4e7; border-radius: 4px; }
  .notes-section h4 { font-size: 8pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; margin-bottom: 6px; }
  .notes-section p { font-size: 8.5pt; color: #3f3f46; white-space: pre-wrap; }

  .signature-section { margin-top: 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
  .sig-line { border-top: 1px solid #18181b; padding-top: 6px; margin-top: 40px; }
  .sig-label { font-size: 8pt; color: #71717a; }
  .sig-name { font-size: 9pt; font-weight: 500; color: #18181b; }

  .footer { margin-top: 32px; padding-top: 12px; border-top: 1px solid #e4e4e7; font-size: 7.5pt; color: #a1a1aa; text-align: center; }

  .change-order-section { margin-top: 12px; padding: 10px 12px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 4px; }
  .section-title { font-size: 9pt; font-weight: 600; color: #18181b; margin-bottom: 8px; padding-bottom: 4px; border-bottom: 1px solid #e4e4e7; }
  .gbb-section { margin-top: 20px; }
  .gbb-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 8px; }
  .gbb-col { border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px; text-align: center; }
  .gbb-label { font-size: 10pt; font-weight: 700; }
  .gbb-desc { font-size: 7.5pt; color: #71717a; margin-top: 2px; }
  .gbb-count { font-size: 8pt; color: #52525b; margin-top: 4px; }
  .warranty-section { margin-top: 20px; }
  .warranty-range { font-size: 8.5pt; color: #52525b; margin-bottom: 6px; }
  .warranty-list { }
  .warranty-item { display: flex; justify-content: space-between; font-size: 8pt; padding: 3px 0; border-bottom: 1px solid #f4f4f5; }
  .warranty-years { color: #10b981; font-weight: 600; }
  .terms-section { margin-top: 20px; page-break-inside: avoid; }
  .terms-list { padding-left: 16px; font-size: 8pt; color: #52525b; line-height: 1.6; }
  .terms-list li { margin-bottom: 3px; }

  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }
</style>
</head>
<body>

<!-- Header -->
<div class="header">
  <div>
    ${companyLogoUrl ? `<img src="${companyLogoUrl}" alt="Logo" style="height: 40px; margin-bottom: 4px;" />` : ''}
    <div class="company-name">${escapeHtml(companyName)}</div>
    ${companyPhone ? `<div class="company-detail">${escapeHtml(companyPhone)}</div>` : ''}
    ${companyEmail ? `<div class="company-detail">${escapeHtml(companyEmail)}</div>` : ''}
    ${companyAddress ? `<div class="company-detail">${escapeHtml(companyAddress)}</div>` : ''}
  </div>
  <div class="estimate-label">
    <h2>Estimate</h2>
    <div class="meta">${escapeHtml(estimate.estimate_number || '')}</div>
    <div class="meta">${today}</div>
    <div class="type-badge type-${isInsurance ? 'insurance' : 'regular'}">${isInsurance ? 'Insurance' : 'Regular'}</div>
  </div>
</div>

<!-- Info Grid -->
<div class="info-grid">
  <div class="info-box">
    <h3>${isInsurance ? 'Property / Insured' : 'Project Details'}</h3>
    <div class="info-row"><span class="info-label">Title</span><span class="info-value">${escapeHtml(estimate.title || '')}</span></div>
    <div class="info-row"><span class="info-label">Customer</span><span class="info-value">${escapeHtml(estimate.customer_name || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Address</span><span class="info-value">${escapeHtml(propertyLine || 'N/A')}</span></div>
    ${estimate.customer_phone ? `<div class="info-row"><span class="info-label">Phone</span><span class="info-value">${escapeHtml(estimate.customer_phone)}</span></div>` : ''}
    ${estimate.customer_email ? `<div class="info-row"><span class="info-label">Email</span><span class="info-value">${escapeHtml(estimate.customer_email)}</span></div>` : ''}
  </div>
  ${isInsurance ? `
  <div class="info-box">
    <h3>Insurance Details</h3>
    <div class="info-row"><span class="info-label">Claim #</span><span class="info-value">${escapeHtml(estimate.claim_number || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Policy #</span><span class="info-value">${escapeHtml(estimate.policy_number || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Carrier</span><span class="info-value">${escapeHtml(estimate.carrier_name || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Adjuster</span><span class="info-value">${escapeHtml(estimate.adjuster_name || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Deductible</span><span class="info-value">$${fmt(Number(estimate.deductible || 0))}</span></div>
    <div class="info-row"><span class="info-label">Date of Loss</span><span class="info-value">${estimate.date_of_loss ? new Date(estimate.date_of_loss).toLocaleDateString('en-US') : 'N/A'}</span></div>
  </div>` : `
  <div class="info-box">
    <h3>Estimate Details</h3>
    <div class="info-row"><span class="info-label">Estimate #</span><span class="info-value">${escapeHtml(estimate.estimate_number || '')}</span></div>
    <div class="info-row"><span class="info-label">Date</span><span class="info-value">${today}</span></div>
    <div class="info-row"><span class="info-label">Status</span><span class="info-value" style="text-transform:capitalize;">${escapeHtml(estimate.status || 'draft')}</span></div>
    <div class="info-row"><span class="info-label">Areas</span><span class="info-value">${areas.length}</span></div>
    <div class="info-row"><span class="info-label">Line Items</span><span class="info-value">${lineItems.length}</span></div>
    ${estimate.valid_until ? `<div class="info-row"><span class="info-label">Valid Until</span><span class="info-value">${new Date(estimate.valid_until).toLocaleDateString('en-US')}</span></div>` : ''}
  </div>`}
</div>

<!-- Line Items -->
${lineItemsHtml}

<!-- Summary -->
<div class="summary">
  <div class="summary-title">Estimate Summary</div>
  <div class="summary-body">
    <div class="summary-row"><span class="label">Subtotal</span><span class="value">$${fmt(subtotal)}</span></div>
    ${overheadPct > 0 ? `<div class="summary-row"><span class="label">Overhead (${overheadPct}%)</span><span class="value">$${fmt(overhead)}</span></div>` : ''}
    ${profitPct > 0 ? `<div class="summary-row"><span class="label">Profit (${profitPct}%)</span><span class="value">$${fmt(profit)}</span></div>` : ''}
    ${taxPct > 0 ? `<div class="summary-row"><span class="label">Tax (${taxPct}%)</span><span class="value">$${fmt(tax)}</span></div>` : ''}
    <div class="summary-row total"><span>Grand Total</span><span>$${fmt(grandTotal)}</span></div>
    ${insuranceHtml}
  </div>
</div>

<!-- Change Orders -->
${changeOrderHtml}

<!-- G/B/B Comparison -->
${gbbHtml}

<!-- Warranty -->
${warrantyHtml}

<!-- Notes -->
${estimate.notes ? `
<div class="notes-section">
  <h4>Notes</h4>
  <p>${escapeHtml(estimate.notes)}</p>
</div>` : ''}

<!-- Terms -->
${termsHtml}

<!-- Signature Lines -->
<div class="signature-section">
  <div>
    <div class="sig-line">
      <div class="sig-label">Contractor Signature</div>
      <div class="sig-name">${escapeHtml(companyName)}</div>
    </div>
    <div style="font-size: 8pt; color: #71717a; margin-top: 4px;">Date: ____________________</div>
  </div>
  <div>
    <div class="sig-line">
      <div class="sig-label">Customer Acceptance</div>
      <div class="sig-name">${escapeHtml(estimate.customer_name || 'Customer')}</div>
    </div>
    <div style="font-size: 8pt; color: #71717a; margin-top: 4px;">Date: ____________________</div>
  </div>
</div>

<!-- Footer -->
<div class="footer">
  Generated by ${escapeHtml(companyName)} via ZAFTO &middot; ${today} &middot; ${escapeHtml(estimate.estimate_number || '')} &middot; ${lineItems.length} line items
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
    console.error('Estimate PDF export error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
