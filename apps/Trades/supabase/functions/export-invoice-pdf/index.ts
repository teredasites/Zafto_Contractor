// Supabase Edge Function: export-invoice-pdf
// Generates a professional branded HTML invoice document.
// GET ?invoice_id=UUID -> returns HTML page ready for print/PDF.

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

  // Rate limit: 10 requests per minute per user
  const rateCheck = await checkRateLimit(supabase, {
    key: `user:${user.id}:export-invoice-pdf`,
    maxRequests: 10,
    windowSeconds: 60,
  })
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)

  try {
    const url = new URL(req.url)
    const invoiceId = url.searchParams.get('invoice_id')

    if (!invoiceId) {
      return new Response(JSON.stringify({ error: 'invoice_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch invoice
    const { data: invoice, error: invError } = await supabase
      .from('invoices')
      .select('*')
      .eq('id', invoiceId)
      .single()

    if (invError || !invoice) {
      return new Response(JSON.stringify({ error: 'Invoice not found' }), {
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

    // Fetch customer
    let customerName = ''
    let customerEmail = ''
    let customerPhone = ''
    let customerAddress = ''

    if (invoice.customer_id) {
      const { data: customer } = await supabase
        .from('customers')
        .select('first_name, last_name, email, phone, address_line1, address_city, address_state, address_zip')
        .eq('id', invoice.customer_id)
        .single()
      if (customer) {
        customerName = `${customer.first_name || ''} ${customer.last_name || ''}`.trim()
        customerEmail = customer.email || ''
        customerPhone = customer.phone || ''
        customerAddress = [customer.address_line1, customer.address_city, customer.address_state, customer.address_zip].filter(Boolean).join(', ')
      }
    }

    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })

    // Parse line items from JSONB
    const lineItems: Array<Record<string, unknown>> = Array.isArray(invoice.line_items) ? invoice.line_items : []

    // Calculate totals
    const subtotal = Number(invoice.subtotal || lineItems.reduce((s: number, i: Record<string, unknown>) => s + Number(i.total || i.amount || 0), 0))
    const taxRate = Number(invoice.tax_rate || 0)
    const tax = Number(invoice.tax || subtotal * (taxRate / 100))
    const total = Number(invoice.total || subtotal + tax)
    const amountPaid = Number(invoice.amount_paid || 0)
    const amountDue = Number(invoice.amount_due || total - amountPaid)

    // Status color
    const statusColors: Record<string, { bg: string; color: string; border: string }> = {
      draft: { bg: '#f4f4f5', color: '#71717a', border: '#d4d4d8' },
      sent: { bg: '#eff6ff', color: '#2563eb', border: '#bfdbfe' },
      viewed: { bg: '#faf5ff', color: '#9333ea', border: '#e9d5ff' },
      partial: { bg: '#fffbeb', color: '#d97706', border: '#fde68a' },
      paid: { bg: '#ecfdf5', color: '#059669', border: '#a7f3d0' },
      overdue: { bg: '#fef2f2', color: '#dc2626', border: '#fecaca' },
      void: { bg: '#f4f4f5', color: '#71717a', border: '#d4d4d8' },
    }
    const sc = statusColors[invoice.status || 'draft'] || statusColors.draft

    // Line items table
    const lineItemsHtml = lineItems.length > 0 ? `
<div class="section">
  <div class="section-title">Line Items</div>
  <table>
    <thead>
      <tr>
        <th style="width:50%">Description</th>
        <th class="right" style="width:12%">Qty</th>
        <th class="right" style="width:18%">Unit Price</th>
        <th class="right" style="width:20%">Amount</th>
      </tr>
    </thead>
    <tbody>
      ${lineItems.map((item: Record<string, unknown>) => `
      <tr>
        <td>${escapeHtml(String(item.description || item.name || ''))}</td>
        <td class="right">${Number(item.quantity || 1)}</td>
        <td class="right">$${fmt(Number(item.unit_price || item.unitPrice || item.rate || 0))}</td>
        <td class="right"><strong>$${fmt(Number(item.total || item.amount || 0))}</strong></td>
      </tr>`).join('')}
    </tbody>
  </table>
</div>` : ''

    // Payment history
    let paymentsHtml = ''
    if (amountPaid > 0) {
      // Try to fetch payment records
      const { data: payments } = await supabase
        .from('payment_records')
        .select('*')
        .eq('invoice_id', invoiceId)
        .order('created_at', { ascending: true })

      if (payments && payments.length > 0) {
        paymentsHtml = `
<div class="payments-section">
  <h4>Payment History</h4>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Method</th>
        <th>Reference</th>
        <th class="right">Amount</th>
      </tr>
    </thead>
    <tbody>
      ${payments.map((p: Record<string, unknown>) => `
      <tr>
        <td>${fmtDate(String(p.created_at || ''))}</td>
        <td style="text-transform:capitalize;">${escapeHtml(String(p.method || p.payment_method || ''))}</td>
        <td>${escapeHtml(String(p.reference_number || p.transaction_id || '—'))}</td>
        <td class="right">$${fmt(Number(p.amount || 0))}</td>
      </tr>`).join('')}
    </tbody>
  </table>
</div>`
      }
    }

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Invoice ${escapeHtml(invoice.invoice_number || '')} — ${escapeHtml(customerName || 'Customer')}</title>
<style>
  @page { size: letter; margin: 0.5in 0.6in; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', -apple-system, Arial, sans-serif; font-size: 9pt; color: #1a1a1a; line-height: 1.4; }

  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #18181b; padding-bottom: 12px; margin-bottom: 16px; }
  .company-name { font-size: 18pt; font-weight: 700; color: #18181b; letter-spacing: -0.5px; }
  .company-detail { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .invoice-label { text-align: right; }
  .invoice-label h2 { font-size: 14pt; font-weight: 600; color: #18181b; text-transform: uppercase; letter-spacing: 1px; }
  .invoice-label .meta { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .status-badge { display: inline-block; font-size: 7pt; padding: 2px 8px; border-radius: 3px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-top: 4px; }

  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
  .info-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px 12px; }
  .info-box h3 { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.8px; color: #a1a1aa; font-weight: 600; margin-bottom: 6px; }
  .info-row { display: flex; justify-content: space-between; font-size: 8.5pt; padding: 1px 0; }
  .info-label { color: #71717a; }
  .info-value { font-weight: 500; color: #18181b; }

  .section { margin-bottom: 16px; }
  .section-title { background: #18181b; color: white; padding: 6px 10px; font-size: 9pt; font-weight: 600; border-radius: 3px 3px 0 0; }

  table { width: 100%; border-collapse: collapse; }
  th { background: #f4f4f5; font-size: 7pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; font-weight: 600; text-align: left; padding: 5px 8px; border-bottom: 1px solid #e4e4e7; }
  th.right, td.right { text-align: right; }
  td { font-size: 8.5pt; padding: 4px 8px; border-bottom: 1px solid #f4f4f5; }

  .summary { margin-top: 24px; border: 2px solid #18181b; border-radius: 6px; overflow: hidden; }
  .summary-title { background: #18181b; color: white; padding: 8px 12px; font-size: 11pt; font-weight: 600; }
  .summary-body { padding: 12px; }
  .summary-row { display: flex; justify-content: space-between; padding: 4px 0; font-size: 9pt; }
  .summary-divider { border-top: 1px solid #d4d4d8; margin: 8px 0; }
  .summary-row.total { font-size: 13pt; font-weight: 700; margin-top: 4px; padding-top: 8px; border-top: 2px solid #18181b; }
  .label { color: #52525b; }
  .value { font-weight: 500; }

  .amount-due-box { margin-top: 16px; padding: 12px 16px; border-radius: 6px; text-align: center; }
  .amount-due-label { font-size: 9pt; color: #52525b; text-transform: uppercase; letter-spacing: 1px; }
  .amount-due-value { font-size: 20pt; font-weight: 700; color: #18181b; margin-top: 4px; }

  .payments-section { margin-top: 16px; }
  .payments-section h4 { font-size: 8pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; margin-bottom: 6px; }

  .notes-section { margin-top: 20px; padding: 12px; background: #fafafa; border: 1px solid #e4e4e7; border-radius: 4px; }
  .notes-section h4 { font-size: 8pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; margin-bottom: 6px; }
  .notes-section p { font-size: 8.5pt; color: #3f3f46; white-space: pre-wrap; }

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
  <div class="invoice-label">
    <h2>Invoice</h2>
    <div class="meta">${escapeHtml(invoice.invoice_number || '')}</div>
    <div class="meta">${today}</div>
    <div class="status-badge" style="background:${sc.bg};color:${sc.color};border:1px solid ${sc.border};">${escapeHtml(invoice.status || 'draft')}</div>
  </div>
</div>

<!-- Info Grid -->
<div class="info-grid">
  <div class="info-box">
    <h3>Bill To</h3>
    <div class="info-row"><span class="info-label">Name</span><span class="info-value">${escapeHtml(customerName || 'N/A')}</span></div>
    ${customerEmail ? `<div class="info-row"><span class="info-label">Email</span><span class="info-value">${escapeHtml(customerEmail)}</span></div>` : ''}
    ${customerPhone ? `<div class="info-row"><span class="info-label">Phone</span><span class="info-value">${escapeHtml(customerPhone)}</span></div>` : ''}
    ${customerAddress ? `<div class="info-row"><span class="info-label">Address</span><span class="info-value">${escapeHtml(customerAddress)}</span></div>` : ''}
  </div>
  <div class="info-box">
    <h3>Invoice Details</h3>
    <div class="info-row"><span class="info-label">Invoice #</span><span class="info-value">${escapeHtml(invoice.invoice_number || '')}</span></div>
    <div class="info-row"><span class="info-label">Date Issued</span><span class="info-value">${fmtDate(invoice.created_at)}</span></div>
    <div class="info-row"><span class="info-label">Due Date</span><span class="info-value" style="${invoice.status === 'overdue' ? 'color:#dc2626;font-weight:700;' : ''}">${fmtDate(invoice.due_date)}</span></div>
    ${invoice.payment_method ? `<div class="info-row"><span class="info-label">Payment</span><span class="info-value" style="text-transform:capitalize;">${escapeHtml(invoice.payment_method)}</span></div>` : ''}
  </div>
</div>

<!-- Line Items -->
${lineItemsHtml}

<!-- Summary -->
<div class="summary">
  <div class="summary-title">Invoice Summary</div>
  <div class="summary-body">
    <div class="summary-row"><span class="label">Subtotal</span><span class="value">$${fmt(subtotal)}</span></div>
    ${taxRate > 0 ? `<div class="summary-row"><span class="label">Tax (${taxRate}%)</span><span class="value">$${fmt(tax)}</span></div>` : ''}
    <div class="summary-row total"><span>Total</span><span>$${fmt(total)}</span></div>
    ${amountPaid > 0 ? `
    <div class="summary-divider"></div>
    <div class="summary-row"><span class="label">Amount Paid</span><span class="value" style="color:#059669;">-$${fmt(amountPaid)}</span></div>
    <div class="summary-row" style="font-size:11pt;font-weight:700;"><span>Balance Due</span><span${amountDue > 0 ? ' style="color:#dc2626;"' : ''}>$${fmt(amountDue)}</span></div>` : ''}
  </div>
</div>

<!-- Amount Due Callout -->
${amountDue > 0 ? `
<div class="amount-due-box" style="background:${amountDue > 0 && invoice.status === 'overdue' ? '#fef2f2;border:2px solid #fecaca' : '#f4f4f5;border:2px solid #e4e4e7'};">
  <div class="amount-due-label">${invoice.status === 'overdue' ? 'Past Due' : 'Amount Due'}</div>
  <div class="amount-due-value" style="${invoice.status === 'overdue' ? 'color:#dc2626;' : ''}">$${fmt(amountDue)}</div>
  ${invoice.due_date ? `<div style="font-size:8pt;color:#71717a;margin-top:4px;">Due by ${fmtDate(invoice.due_date)}</div>` : ''}
</div>` : `
<div class="amount-due-box" style="background:#ecfdf5;border:2px solid #a7f3d0;">
  <div class="amount-due-label" style="color:#059669;">Paid in Full</div>
  <div class="amount-due-value" style="color:#059669;">$${fmt(total)}</div>
</div>`}

<!-- Payment History -->
${paymentsHtml}

<!-- Notes -->
${invoice.notes ? `
<div class="notes-section">
  <h4>Notes</h4>
  <p>${escapeHtml(invoice.notes)}</p>
</div>` : ''}

<!-- Footer -->
<div class="footer">
  Generated by ${escapeHtml(companyName)} via ZAFTO &middot; ${today} &middot; ${escapeHtml(invoice.invoice_number || '')} &middot; ${lineItems.length} line items
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
    console.error('Invoice PDF export error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
