// Supabase Edge Function: export-bid-pdf
// Generates a professional branded HTML bid document.
// GET ?bid_id=UUID -> returns HTML page ready for print/PDF.

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

function fmtDate(d: string | null): string {
  if (!d) return 'N/A'
  return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
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

  // SEC-AUDIT-1: Extract company_id from JWT for cross-tenant protection
  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const url = new URL(req.url)
    const bidId = url.searchParams.get('bid_id')

    if (!bidId) {
      return new Response(JSON.stringify({ error: 'bid_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // SEC-AUDIT-1: Scope bid fetch to user's company to prevent cross-tenant export
    const { data: bid, error: bidError } = await supabase
      .from('bids')
      .select('*')
      .eq('id', bidId)
      .eq('company_id', companyId)
      .single()

    if (bidError || !bid) {
      return new Response(JSON.stringify({ error: 'Bid not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

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

    // Fetch customer if customer_id exists
    let customerName = bid.customer_name || ''
    let customerEmail = bid.customer_email || ''
    let customerPhone = bid.customer_phone || ''
    let customerAddress = bid.customer_address || ''

    if (bid.customer_id && !customerName) {
      const { data: customer } = await supabase
        .from('customers')
        .select('first_name, last_name, email, phone, address_line1, address_city, address_state, address_zip')
        .eq('id', bid.customer_id)
        .single()
      if (customer) {
        customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim()
        customerEmail = customer.email || customerEmail
        customerPhone = customer.phone || customerPhone
        customerAddress = [customer.address_line1, customer.address_city, customer.address_state, customer.address_zip].filter(Boolean).join(', ')
      }
    }

    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    const jobSiteAddress = bid.job_site_same_as_customer ? customerAddress : (bid.job_site_address || customerAddress)

    // Parse options and add-ons from JSONB
    const options: Array<Record<string, unknown>> = Array.isArray(bid.options) ? bid.options : []
    const addOns: Array<Record<string, unknown>> = Array.isArray(bid.add_ons) ? bid.add_ons : []

    // Build options HTML
    let optionsHtml = ''
    if (options.length > 0) {
      optionsHtml = `
<div class="section">
  <div class="section-title">Pricing Options</div>
  ${options.map((opt: Record<string, unknown>, idx: number) => {
    const items = Array.isArray(opt.items) ? opt.items as Array<Record<string, unknown>> : []
    const optTotal = Number(opt.total || items.reduce((s: number, i: Record<string, unknown>) => s + Number(i.total || 0), 0))
    const isSelected = bid.selected_option_id === opt.id
    return `
  <div class="option-block ${isSelected ? 'selected' : ''}">
    <div class="option-header">
      <span class="option-name">${isSelected ? '&#10003; ' : ''}Option ${idx + 1}: ${escapeHtml(String(opt.name || opt.label || `Option ${idx + 1}`))}</span>
      <span class="option-total">$${fmt(optTotal)}</span>
    </div>
    ${items.length > 0 ? `
    <table>
      <thead>
        <tr>
          <th>Description</th>
          <th class="right" style="width:60px">Qty</th>
          <th class="right" style="width:80px">Unit Price</th>
          <th class="right" style="width:80px">Total</th>
        </tr>
      </thead>
      <tbody>
        ${items.map((item: Record<string, unknown>) => `
        <tr>
          <td>${escapeHtml(String(item.description || item.name || ''))}</td>
          <td class="right">${Number(item.quantity || 1)}</td>
          <td class="right">$${fmt(Number(item.unit_price || item.unitPrice || 0))}</td>
          <td class="right">$${fmt(Number(item.total || item.lineTotal || 0))}</td>
        </tr>`).join('')}
      </tbody>
    </table>` : ''}
  </div>`
  }).join('')}
</div>`
    }

    // Add-ons section
    let addOnsHtml = ''
    if (addOns.length > 0) {
      addOnsHtml = `
<div class="section">
  <div class="section-title">Available Add-Ons</div>
  <table>
    <thead>
      <tr>
        <th>Add-On</th>
        <th>Description</th>
        <th class="right" style="width:80px">Price</th>
      </tr>
    </thead>
    <tbody>
      ${addOns.map((addon: Record<string, unknown>) => {
        const isSelected = Array.isArray(bid.selected_add_on_ids) && bid.selected_add_on_ids.includes(addon.id)
        return `
      <tr${isSelected ? ' class="selected-row"' : ''}>
        <td>${isSelected ? '&#10003; ' : ''}${escapeHtml(String(addon.name || addon.label || ''))}</td>
        <td>${escapeHtml(String(addon.description || ''))}</td>
        <td class="right">$${fmt(Number(addon.price || addon.total || 0))}</td>
      </tr>`
      }).join('')}
    </tbody>
  </table>
</div>`
    }

    // Summary
    const subtotal = Number(bid.subtotal || bid.total || 0)
    const taxRate = Number(bid.tax_rate || 0)
    const tax = Number(bid.tax || subtotal * (taxRate / 100))
    const discountAmount = Number(bid.discount_amount || 0)
    const total = Number(bid.total || subtotal + tax - discountAmount)
    const depositPercent = Number(bid.deposit_percent || 0)
    const depositAmount = Number(bid.deposit_amount || (depositPercent > 0 ? total * (depositPercent / 100) : 0))

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Bid ${escapeHtml(bid.bid_number || '')} — ${escapeHtml(bid.title || 'Draft')}</title>
<style>
  @page { size: letter; margin: 0.5in 0.6in; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', -apple-system, Arial, sans-serif; font-size: 9pt; color: #1a1a1a; line-height: 1.4; }

  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #18181b; padding-bottom: 12px; margin-bottom: 16px; }
  .company-name { font-size: 18pt; font-weight: 700; color: #18181b; letter-spacing: -0.5px; }
  .company-detail { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .bid-label { text-align: right; }
  .bid-label h2 { font-size: 14pt; font-weight: 600; color: #18181b; text-transform: uppercase; letter-spacing: 1px; }
  .bid-label .meta { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .status-badge { display: inline-block; font-size: 7pt; padding: 2px 8px; border-radius: 3px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-top: 4px; background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; }

  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
  .info-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px 12px; }
  .info-box h3 { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.8px; color: #a1a1aa; font-weight: 600; margin-bottom: 6px; }
  .info-row { display: flex; justify-content: space-between; font-size: 8.5pt; padding: 1px 0; }
  .info-label { color: #71717a; }
  .info-value { font-weight: 500; color: #18181b; }

  .section { margin-bottom: 16px; }
  .section-title { background: #18181b; color: white; padding: 6px 10px; font-size: 9pt; font-weight: 600; border-radius: 3px 3px 0 0; }

  .option-block { border: 1px solid #e4e4e7; border-top: none; padding: 0; margin-bottom: 8px; }
  .option-block.selected { border-color: #2563eb; background: #f0f7ff; }
  .option-header { display: flex; justify-content: space-between; padding: 8px 10px; background: #fafafa; border-bottom: 1px solid #e4e4e7; }
  .option-block.selected .option-header { background: #eff6ff; }
  .option-name { font-weight: 600; font-size: 9pt; }
  .option-total { font-weight: 700; font-size: 10pt; color: #18181b; }

  table { width: 100%; border-collapse: collapse; }
  th { background: #f4f4f5; font-size: 7pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; font-weight: 600; text-align: left; padding: 5px 8px; border-bottom: 1px solid #e4e4e7; }
  th.right, td.right { text-align: right; }
  td { font-size: 8.5pt; padding: 4px 8px; border-bottom: 1px solid #f4f4f5; }
  .selected-row { background: #eff6ff; }

  .summary { margin-top: 24px; border: 2px solid #18181b; border-radius: 6px; overflow: hidden; }
  .summary-title { background: #18181b; color: white; padding: 8px 12px; font-size: 11pt; font-weight: 600; }
  .summary-body { padding: 12px; }
  .summary-row { display: flex; justify-content: space-between; padding: 4px 0; font-size: 9pt; }
  .summary-divider { border-top: 1px solid #d4d4d8; margin: 8px 0; }
  .summary-row.total { font-size: 13pt; font-weight: 700; margin-top: 4px; padding-top: 8px; border-top: 2px solid #18181b; }
  .label { color: #52525b; }
  .value { font-weight: 500; }
  .deposit-note { font-size: 8pt; color: #2563eb; font-weight: 600; margin-top: 8px; padding: 6px 10px; background: #eff6ff; border-radius: 3px; }

  .terms-section { margin-top: 20px; padding: 12px; background: #fafafa; border: 1px solid #e4e4e7; border-radius: 4px; }
  .terms-section h4 { font-size: 8pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; margin-bottom: 6px; }
  .terms-section p { font-size: 8.5pt; color: #3f3f46; white-space: pre-wrap; }

  .timeline-section { margin-top: 16px; display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 12px; }
  .timeline-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 8px 10px; text-align: center; }
  .timeline-box .tl-label { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.5px; color: #a1a1aa; }
  .timeline-box .tl-value { font-size: 10pt; font-weight: 600; color: #18181b; margin-top: 2px; }

  .signature-section { margin-top: 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
  .sig-line { border-top: 1px solid #18181b; padding-top: 6px; margin-top: 40px; }
  .sig-label { font-size: 8pt; color: #71717a; }
  .sig-name { font-size: 9pt; font-weight: 500; color: #18181b; }

  .footer { margin-top: 32px; padding-top: 12px; border-top: 1px solid #e4e4e7; font-size: 7.5pt; color: #a1a1aa; text-align: center; }

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
  <div class="bid-label">
    <h2>Bid / Proposal</h2>
    <div class="meta">${escapeHtml(bid.bid_number || '')}</div>
    <div class="meta">${today}</div>
    <div class="status-badge">${escapeHtml(bid.status || 'draft')}</div>
  </div>
</div>

<!-- Info Grid -->
<div class="info-grid">
  <div class="info-box">
    <h3>Customer</h3>
    <div class="info-row"><span class="info-label">Name</span><span class="info-value">${escapeHtml(customerName || 'N/A')}</span></div>
    ${customerEmail ? `<div class="info-row"><span class="info-label">Email</span><span class="info-value">${escapeHtml(customerEmail)}</span></div>` : ''}
    ${customerPhone ? `<div class="info-row"><span class="info-label">Phone</span><span class="info-value">${escapeHtml(customerPhone)}</span></div>` : ''}
    ${customerAddress ? `<div class="info-row"><span class="info-label">Address</span><span class="info-value">${escapeHtml(customerAddress)}</span></div>` : ''}
  </div>
  <div class="info-box">
    <h3>Bid Details</h3>
    <div class="info-row"><span class="info-label">Bid #</span><span class="info-value">${escapeHtml(bid.bid_number || '')}</span></div>
    <div class="info-row"><span class="info-label">Title</span><span class="info-value">${escapeHtml(bid.title || '')}</span></div>
    <div class="info-row"><span class="info-label">Date</span><span class="info-value">${today}</span></div>
    ${bid.valid_until ? `<div class="info-row"><span class="info-label">Valid Until</span><span class="info-value">${fmtDate(bid.valid_until)}</span></div>` : ''}
    ${jobSiteAddress && jobSiteAddress !== customerAddress ? `<div class="info-row"><span class="info-label">Job Site</span><span class="info-value">${escapeHtml(jobSiteAddress)}</span></div>` : ''}
  </div>
</div>

<!-- Scope / Title -->
${bid.title ? `
<div class="section">
  <div class="section-title">Scope of Work: ${escapeHtml(bid.title)}</div>
</div>` : ''}

<!-- Options -->
${optionsHtml}

<!-- Add-Ons -->
${addOnsHtml}

<!-- Summary -->
<div class="summary">
  <div class="summary-title">Bid Summary</div>
  <div class="summary-body">
    <div class="summary-row"><span class="label">Subtotal</span><span class="value">$${fmt(subtotal)}</span></div>
    ${discountAmount > 0 ? `<div class="summary-row"><span class="label">Discount</span><span class="value" style="color:#ef4444;">-$${fmt(discountAmount)}</span></div>` : ''}
    ${taxRate > 0 ? `<div class="summary-row"><span class="label">Tax (${taxRate}%)</span><span class="value">$${fmt(tax)}</span></div>` : ''}
    <div class="summary-row total"><span>Total</span><span>$${fmt(total)}</span></div>
    ${depositPercent > 0 || depositAmount > 0 ? `<div class="deposit-note">Deposit Required: $${fmt(depositAmount)}${depositPercent > 0 ? ` (${depositPercent}%)` : ''} due upon acceptance</div>` : ''}
  </div>
</div>

<!-- Timeline -->
${bid.estimated_start_date || bid.estimated_duration || bid.valid_until ? `
<div class="timeline-section">
  ${bid.estimated_start_date ? `<div class="timeline-box"><div class="tl-label">Est. Start Date</div><div class="tl-value">${fmtDate(bid.estimated_start_date)}</div></div>` : ''}
  ${bid.estimated_duration ? `<div class="timeline-box"><div class="tl-label">Est. Duration</div><div class="tl-value">${escapeHtml(String(bid.estimated_duration))}</div></div>` : ''}
  ${bid.valid_until ? `<div class="timeline-box"><div class="tl-label">Bid Valid Until</div><div class="tl-value">${fmtDate(bid.valid_until)}</div></div>` : ''}
</div>` : ''}

<!-- Terms & Conditions -->
${bid.terms_and_conditions ? `
<div class="terms-section">
  <h4>Terms &amp; Conditions</h4>
  <p>${escapeHtml(bid.terms_and_conditions)}</p>
</div>` : ''}

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
      <div class="sig-name">${escapeHtml(customerName || 'Customer')}</div>
    </div>
    <div style="font-size: 8pt; color: #71717a; margin-top: 4px;">Date: ____________________</div>
  </div>
</div>

<!-- Footer -->
<div class="footer">
  Generated by ${escapeHtml(companyName)} via ZAFTO &middot; ${today} &middot; ${escapeHtml(bid.bid_number || '')}
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
    console.error('Bid PDF export error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
