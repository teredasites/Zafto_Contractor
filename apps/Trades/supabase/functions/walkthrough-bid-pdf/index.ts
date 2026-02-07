// Supabase Edge Function: walkthrough-bid-pdf
// Generates a PDF-ready HTML document from a generated bid.
// POST { bid_id, walkthrough_id, include_photos, include_floor_plan } → returns HTML.

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

interface BidLineItem {
  description: string
  quantity: number
  unit: string
  unit_price: number
  total: number
  code?: string
  material_cost?: number
  labor_cost?: number
  equipment_cost?: number
}

interface BidSection {
  name: string
  items: BidLineItem[]
  subtotal: number
}

interface BidData {
  format: string
  title: string
  sections: BidSection[]
  subtotal: number
  overhead: number
  profit: number
  total: number
  notes: string
  terms: string
  valid_days: number
  tiers?: Array<{ name: string; description: string; sections: BidSection[]; total: number; subtotal?: number }>
  schedule_of_values?: Array<{ number: string; description: string; scheduled_value: number }>
  findings?: Array<{ area: string; finding: string; priority: string; recommendation: string; photo_refs?: string[] }>
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
    const body = await req.json()
    const { bid_id, walkthrough_id, include_photos, include_floor_plan } = body

    if (!bid_id) {
      return new Response(JSON.stringify({ error: 'bid_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch bid record
    const { data: bid, error: bidErr } = await supabase
      .from('bids')
      .select('*')
      .eq('id', bid_id)
      .single()

    if (bidErr || !bid) {
      return new Response(JSON.stringify({ error: 'Bid not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Extract generated bid data from metadata
    const metadata = bid.metadata as Record<string, unknown> || {}
    const bidData = (metadata.generated_bid || {}) as BidData

    // Fetch walkthrough data if provided
    let walkthrough: Record<string, unknown> | null = null
    let walkthroughRooms: Array<Record<string, unknown>> = []
    let walkthroughPhotos: Array<Record<string, unknown>> = []

    const wtId = walkthrough_id || metadata.walkthrough_id
    if (wtId) {
      const { data: wt } = await supabase
        .from('walkthroughs')
        .select('*')
        .eq('id', wtId)
        .single()
      walkthrough = wt

      if (walkthrough) {
        const { data: rooms } = await supabase
          .from('walkthrough_rooms')
          .select('*')
          .eq('walkthrough_id', wtId)
          .order('sort_order')
        walkthroughRooms = rooms || []

        if (include_photos) {
          const { data: photos } = await supabase
            .from('walkthrough_photos')
            .select('*')
            .eq('walkthrough_id', wtId)
            .order('created_at')
          walkthroughPhotos = photos || []
        }
      }
    }

    // Fetch company info
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

    // Fetch customer info if available
    let customerName = ''
    let customerAddress = ''
    let customerPhone = ''
    let customerEmail = ''

    if (bid.customer_id) {
      const { data: customer } = await supabase
        .from('customers')
        .select('name, address, phone, email')
        .eq('id', bid.customer_id)
        .single()

      if (customer) {
        customerName = customer.name || ''
        customerAddress = customer.address || ''
        customerPhone = customer.phone || ''
        customerEmail = customer.email || ''
      }
    }

    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
    const validUntil = bid.valid_until
      ? new Date(bid.valid_until).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
      : 'N/A'

    const propertyAddress = (walkthrough?.address as string) || customerAddress || 'Property Address'
    const bidTitle = bidData.title || bid.title || 'Bid'
    const bidFormat = bidData.format || 'standard'

    // Get photo signed URLs if including photos
    const photoUrls: Map<string, string> = new Map()
    if (include_photos && walkthroughPhotos.length > 0) {
      for (const photo of walkthroughPhotos.slice(0, 20)) {
        // Limit to 20 photos in PDF
        try {
          const { data: signedData } = await supabase.storage
            .from('walkthrough-photos')
            .createSignedUrl(photo.storage_path as string, 3600)

          if (signedData?.signedUrl) {
            photoUrls.set(photo.id as string, signedData.signedUrl)
          }
        } catch {
          // Skip failed photo URLs
        }
      }
    }

    // ── Build sections HTML based on format ──

    let sectionsHtml = ''

    if (bidFormat === 'three_tier' && bidData.tiers && bidData.tiers.length > 0) {
      // Three-tier format
      sectionsHtml = bidData.tiers.map((tier, tierIndex) => {
        const tierColorMap: Record<number, { bg: string; border: string; badge: string }> = {
          0: { bg: '#f0fdf4', border: '#16a34a', badge: '#16a34a' },
          1: { bg: '#eff6ff', border: '#2563eb', badge: '#2563eb' },
          2: { bg: '#faf5ff', border: '#9333ea', badge: '#9333ea' },
        }
        const colors = tierColorMap[tierIndex] || tierColorMap[0]

        return `
<div class="tier-section" style="border: 2px solid ${colors.border}; border-radius: 8px; margin-bottom: 20px; overflow: hidden;">
  <div class="tier-header" style="background: ${colors.bg}; padding: 12px 16px; border-bottom: 1px solid ${colors.border};">
    <span style="font-size: 14pt; font-weight: 700; color: ${colors.badge};">${escapeHtml(tier.name)}</span>
    <span style="float: right; font-size: 14pt; font-weight: 700; color: ${colors.badge};">$${fmt(tier.total || 0)}</span>
    ${tier.description ? `<div style="font-size: 9pt; color: #52525b; margin-top: 4px;">${escapeHtml(tier.description)}</div>` : ''}
  </div>
  ${(tier.sections || []).map(section => `
  <div style="padding: 0 12px;">
    <div style="font-size: 9pt; font-weight: 600; color: #18181b; padding: 8px 0 4px; border-bottom: 1px solid #e4e4e7;">${escapeHtml(section.name)}</div>
    <table>
      <thead>
        <tr>
          <th>Description</th>
          <th class="right" style="width:40px">Qty</th>
          <th style="width:35px">Unit</th>
          <th class="right" style="width:70px">Unit Price</th>
          <th class="right" style="width:70px">Total</th>
        </tr>
      </thead>
      <tbody>
        ${section.items.map((item: BidLineItem) => `
        <tr>
          <td>${escapeHtml(item.description)}</td>
          <td class="right">${item.quantity}</td>
          <td>${escapeHtml(item.unit)}</td>
          <td class="right">$${fmt(item.unit_price)}</td>
          <td class="right"><strong>$${fmt(item.total)}</strong></td>
        </tr>`).join('')}
      </tbody>
    </table>
  </div>`).join('')}
  <div style="padding: 8px 16px; background: ${colors.bg}; border-top: 1px solid ${colors.border}; text-align: right; font-weight: 600;">
    Tier Total: $${fmt(tier.total || 0)}
  </div>
</div>`
      }).join('')

    } else if (bidFormat === 'inspection' && bidData.findings && bidData.findings.length > 0) {
      // Inspection format — findings table
      sectionsHtml = `
<div class="findings-section">
  <div class="section-header">Inspection Findings</div>
  <table>
    <thead>
      <tr>
        <th style="width:100px">Area</th>
        <th>Finding</th>
        <th style="width:60px">Priority</th>
        <th>Recommendation</th>
      </tr>
    </thead>
    <tbody>
      ${bidData.findings.map(f => {
        const priorityColors: Record<string, string> = {
          'urgent': '#dc2626',
          'high': '#ea580c',
          'medium': '#d97706',
          'low': '#16a34a',
        }
        const pColor = priorityColors[f.priority] || '#71717a'
        return `
      <tr>
        <td><strong>${escapeHtml(f.area)}</strong></td>
        <td>${escapeHtml(f.finding)}</td>
        <td><span style="color: ${pColor}; font-weight: 600; text-transform: uppercase; font-size: 7pt;">${escapeHtml(f.priority)}</span></td>
        <td>${escapeHtml(f.recommendation)}</td>
      </tr>`
      }).join('')}
    </tbody>
  </table>
</div>

${bidData.sections && bidData.sections.length > 0 ? `
<div style="margin-top: 20px;">
  <div class="section-header">Estimated Repair Costs</div>
  ${buildStandardSections(bidData.sections)}
</div>` : ''}`

    } else if (bidFormat === 'insurance') {
      // Insurance format with MAT/LAB/EQU breakdown
      sectionsHtml = (bidData.sections || []).map(section => `
<div class="room-section">
  <div class="room-header">
    <span>${escapeHtml(section.name)}</span>
    <span>${section.items.length} items &mdash; $${fmt(section.subtotal)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:70px">Code</th>
        <th>Description</th>
        <th class="right" style="width:40px">Qty</th>
        <th style="width:30px">Unit</th>
        <th class="right" style="width:55px">MAT</th>
        <th class="right" style="width:55px">LAB</th>
        <th class="right" style="width:55px">EQU</th>
        <th class="right" style="width:70px">Total</th>
      </tr>
    </thead>
    <tbody>
      ${section.items.map((item: BidLineItem) => `
      <tr>
        <td class="code">${escapeHtml(item.code || '')}</td>
        <td>${escapeHtml(item.description)}</td>
        <td class="right">${item.quantity}</td>
        <td>${escapeHtml(item.unit)}</td>
        <td class="right">$${fmt(item.material_cost || 0)}</td>
        <td class="right">$${fmt(item.labor_cost || 0)}</td>
        <td class="right">$${fmt(item.equipment_cost || 0)}</td>
        <td class="right"><strong>$${fmt(item.total)}</strong></td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="7" style="text-align:right">Section Total:</td>
        <td class="right">$${fmt(section.subtotal)}</td>
      </tr>
    </tbody>
  </table>
</div>`).join('')

    } else if (bidFormat === 'aia' && bidData.schedule_of_values) {
      // AIA format — Schedule of Values
      const sovTotal = bidData.schedule_of_values.reduce((sum, sov) => sum + (Number(sov.scheduled_value) || 0), 0)

      sectionsHtml = `
<div class="room-section">
  <div class="room-header">
    <span>Schedule of Values (AIA G703)</span>
    <span>${bidData.schedule_of_values.length} items</span>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:50px">Item #</th>
        <th>Description of Work</th>
        <th class="right" style="width:100px">Scheduled Value</th>
        <th class="right" style="width:60px">% of Total</th>
      </tr>
    </thead>
    <tbody>
      ${bidData.schedule_of_values.map(sov => `
      <tr>
        <td><strong>${escapeHtml(sov.number)}</strong></td>
        <td>${escapeHtml(sov.description)}</td>
        <td class="right">$${fmt(sov.scheduled_value)}</td>
        <td class="right">${sovTotal > 0 ? ((sov.scheduled_value / sovTotal) * 100).toFixed(1) : '0.0'}%</td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="2" style="text-align:right"><strong>Total Contract Sum:</strong></td>
        <td class="right"><strong>$${fmt(sovTotal)}</strong></td>
        <td class="right"><strong>100.0%</strong></td>
      </tr>
    </tbody>
  </table>
</div>`

    } else {
      // Standard format (and fallback for trade_specific)
      sectionsHtml = buildStandardSections(bidData.sections || [])
    }

    // Build photos HTML
    let photosHtml = ''
    if (include_photos && photoUrls.size > 0) {
      // Group photos by room
      const photosByRoomMap = new Map<string, Array<{ url: string; caption: string }>>()
      for (const photo of walkthroughPhotos) {
        if (!photoUrls.has(photo.id as string)) continue
        const roomId = photo.room_id as string || '__general__'
        const room = walkthroughRooms.find(r => (r.id as string) === roomId)
        const roomName = (room?.name as string) || 'General'
        const existing = photosByRoomMap.get(roomName) || []
        existing.push({
          url: photoUrls.get(photo.id as string)!,
          caption: (photo.caption as string) || '',
        })
        photosByRoomMap.set(roomName, existing)
      }

      photosHtml = `
<div class="page-break"></div>
<div class="section-header" style="margin-bottom: 12px;">Walkthrough Photos</div>
${Array.from(photosByRoomMap.entries()).map(([roomName, photos]) => `
<div style="margin-bottom: 16px;">
  <div style="font-size: 10pt; font-weight: 600; color: #18181b; margin-bottom: 8px;">${escapeHtml(roomName)}</div>
  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
    ${photos.map(p => `
    <div style="border: 1px solid #e4e4e7; border-radius: 4px; overflow: hidden;">
      <img src="${p.url}" style="width: 100%; height: 200px; object-fit: cover;" alt="${escapeHtml(p.caption)}" />
      ${p.caption ? `<div style="padding: 4px 8px; font-size: 8pt; color: #52525b;">${escapeHtml(p.caption)}</div>` : ''}
    </div>`).join('')}
  </div>
</div>`).join('')}
`
    }

    // Build floor plan HTML
    let floorPlanHtml = ''
    if (include_floor_plan && walkthrough) {
      const planData = walkthrough.plan_data
      if (planData) {
        floorPlanHtml = `
<div class="page-break"></div>
<div class="section-header" style="margin-bottom: 12px;">Floor Plan</div>
<div style="border: 1px solid #e4e4e7; border-radius: 4px; padding: 16px; text-align: center;">
  ${typeof planData === 'string' ? planData : '<div style="color: #71717a; font-size: 9pt;">Floor plan data available but cannot be rendered in this format.</div>'}
</div>`
      }
    }

    // ── Build final HTML document ──

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${escapeHtml(bidTitle)}</title>
<style>
  @page { size: letter; margin: 0.5in 0.6in; }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Segoe UI', -apple-system, Arial, sans-serif; font-size: 9pt; color: #1a1a1a; line-height: 1.4; }
  .page-break { page-break-before: always; }

  /* Header */
  .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #18181b; padding-bottom: 12px; margin-bottom: 16px; }
  .company-info { }
  .company-name { font-size: 18pt; font-weight: 700; color: #18181b; letter-spacing: -0.5px; }
  .company-detail { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .bid-label { text-align: right; }
  .bid-label h2 { font-size: 14pt; font-weight: 600; color: #18181b; text-transform: uppercase; letter-spacing: 1px; }
  .bid-label .meta { font-size: 8pt; color: #71717a; margin-top: 2px; }
  .format-badge { display: inline-block; font-size: 7pt; padding: 2px 8px; border-radius: 3px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; background: #f4f4f5; color: #52525b; border: 1px solid #e4e4e7; margin-top: 4px; }

  /* Info grid */
  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
  .info-box { background: #f4f4f5; border: 1px solid #e4e4e7; border-radius: 4px; padding: 10px 12px; }
  .info-box h3 { font-size: 7pt; text-transform: uppercase; letter-spacing: 0.8px; color: #a1a1aa; font-weight: 600; margin-bottom: 6px; }
  .info-row { display: flex; justify-content: space-between; font-size: 8.5pt; padding: 1px 0; }
  .info-label { color: #71717a; }
  .info-value { font-weight: 500; color: #18181b; }

  /* Sections */
  .section-header { background: #18181b; color: white; padding: 8px 12px; font-size: 11pt; font-weight: 600; border-radius: 4px; margin-bottom: 12px; }
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
  .summary-divider { border-top: 1px solid #d4d4d8; margin: 8px 0; }
  .summary-row.total { font-size: 13pt; font-weight: 700; margin-top: 4px; padding-top: 8px; border-top: 2px solid #18181b; }
  .label { color: #52525b; }
  .value { font-weight: 500; }

  /* Notes & Terms */
  .notes-section { margin-top: 20px; padding: 12px; background: #fafafa; border: 1px solid #e4e4e7; border-radius: 4px; }
  .notes-section h4 { font-size: 8pt; text-transform: uppercase; letter-spacing: 0.5px; color: #71717a; margin-bottom: 6px; }
  .notes-section p { font-size: 8.5pt; color: #3f3f46; white-space: pre-wrap; }

  /* Signature */
  .signature-section { margin-top: 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; }
  .sig-line { border-top: 1px solid #18181b; padding-top: 6px; margin-top: 40px; }
  .sig-label { font-size: 8pt; color: #71717a; }
  .sig-name { font-size: 9pt; font-weight: 500; color: #18181b; }

  /* Footer */
  .footer { margin-top: 32px; padding-top: 12px; border-top: 1px solid #e4e4e7; font-size: 7.5pt; color: #a1a1aa; text-align: center; }

  /* Findings table */
  .findings-section { margin-bottom: 20px; }
  .findings-section table td { vertical-align: top; }

  @media print {
    body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  }
</style>
</head>
<body>

<!-- Header -->
<div class="header">
  <div class="company-info">
    ${companyLogoUrl ? `<img src="${companyLogoUrl}" alt="Logo" style="height: 40px; margin-bottom: 4px;" />` : ''}
    <div class="company-name">${escapeHtml(companyName)}</div>
    ${companyPhone ? `<div class="company-detail">${escapeHtml(companyPhone)}</div>` : ''}
    ${companyEmail ? `<div class="company-detail">${escapeHtml(companyEmail)}</div>` : ''}
    ${companyAddress ? `<div class="company-detail">${escapeHtml(companyAddress)}</div>` : ''}
  </div>
  <div class="bid-label">
    <h2>${bidFormat === 'inspection' ? 'Inspection Report' : 'Bid / Estimate'}</h2>
    <div class="meta">${today}</div>
    <div class="meta">Valid until: ${validUntil}</div>
    <div class="format-badge">${escapeHtml(bidFormat.replace(/_/g, ' '))}</div>
  </div>
</div>

<!-- Info Grid -->
<div class="info-grid">
  <div class="info-box">
    <h3>Project Information</h3>
    <div class="info-row"><span class="info-label">Title</span><span class="info-value">${escapeHtml(bidTitle)}</span></div>
    <div class="info-row"><span class="info-label">Property</span><span class="info-value">${escapeHtml(propertyAddress)}</span></div>
    <div class="info-row"><span class="info-label">Bid #</span><span class="info-value">${escapeHtml(bid_id.substring(0, 8).toUpperCase())}</span></div>
    <div class="info-row"><span class="info-label">Date</span><span class="info-value">${today}</span></div>
    ${walkthrough?.type ? `<div class="info-row"><span class="info-label">Type</span><span class="info-value">${escapeHtml(String(walkthrough.type))}</span></div>` : ''}
  </div>
  <div class="info-box">
    <h3>Customer</h3>
    <div class="info-row"><span class="info-label">Name</span><span class="info-value">${escapeHtml(customerName || 'N/A')}</span></div>
    <div class="info-row"><span class="info-label">Address</span><span class="info-value">${escapeHtml(customerAddress || propertyAddress)}</span></div>
    ${customerPhone ? `<div class="info-row"><span class="info-label">Phone</span><span class="info-value">${escapeHtml(customerPhone)}</span></div>` : ''}
    ${customerEmail ? `<div class="info-row"><span class="info-label">Email</span><span class="info-value">${escapeHtml(customerEmail)}</span></div>` : ''}
  </div>
</div>

<!-- Line Items / Sections -->
${sectionsHtml}

<!-- Summary (skip for inspection and three_tier which have their own summaries) -->
${bidFormat !== 'inspection' && bidFormat !== 'three_tier' ? `
<div class="summary">
  <div class="summary-title">${bidFormat === 'aia' ? 'Contract Summary' : 'Bid Summary'}</div>
  <div class="summary-body">
    <div class="summary-row"><span class="label">Subtotal</span><span class="value">$${fmt(bidData.subtotal || 0)}</span></div>
    ${bidData.overhead ? `<div class="summary-row"><span class="label">Overhead</span><span class="value">$${fmt(bidData.overhead)}</span></div>` : ''}
    ${bidData.profit ? `<div class="summary-row"><span class="label">Profit</span><span class="value">$${fmt(bidData.profit)}</span></div>` : ''}
    <div class="summary-row total"><span>Total</span><span>$${fmt(bidData.total || bid.total_amount || 0)}</span></div>
  </div>
</div>` : ''}

<!-- Notes -->
${bidData.notes ? `
<div class="notes-section">
  <h4>Notes &amp; Scope</h4>
  <p>${escapeHtml(bidData.notes)}</p>
</div>` : ''}

<!-- Terms -->
${bidData.terms ? `
<div class="notes-section">
  <h4>Terms &amp; Conditions</h4>
  <p>${escapeHtml(bidData.terms)}</p>
</div>` : ''}

<!-- Photos -->
${photosHtml}

<!-- Floor Plan -->
${floorPlanHtml}

<!-- Signature Lines -->
${bidFormat !== 'inspection' ? `
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
      <div class="sig-name">${escapeHtml(customerName || 'Customer Name')}</div>
    </div>
    <div style="font-size: 8pt; color: #71717a; margin-top: 4px;">Date: ____________________</div>
  </div>
</div>` : ''}

<!-- Footer -->
<div class="footer">
  Generated by ${escapeHtml(companyName)} via ZAFTO &middot; ${today} &middot; Bid #${escapeHtml(bid_id.substring(0, 8).toUpperCase())}
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
    console.error('Walkthrough bid PDF error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ── Helper: Build standard sections HTML ──

function buildStandardSections(sections: BidSection[]): string {
  return sections.map(section => `
<div class="room-section">
  <div class="room-header">
    <span>${escapeHtml(section.name)}</span>
    <span>${section.items.length} items &mdash; $${fmt(section.subtotal)}</span>
  </div>
  <table>
    <thead>
      <tr>
        <th>Description</th>
        <th class="right" style="width:40px">Qty</th>
        <th style="width:35px">Unit</th>
        <th class="right" style="width:70px">Unit Price</th>
        <th class="right" style="width:70px">Total</th>
      </tr>
    </thead>
    <tbody>
      ${section.items.map((item: BidLineItem) => `
      <tr>
        <td>${escapeHtml(item.description)}</td>
        <td class="right">${item.quantity}</td>
        <td>${escapeHtml(item.unit)}</td>
        <td class="right">$${fmt(item.unit_price)}</td>
        <td class="right"><strong>$${fmt(item.total)}</strong></td>
      </tr>`).join('')}
      <tr class="room-total">
        <td colspan="4" style="text-align:right">Section Total:</td>
        <td class="right">$${fmt(section.subtotal)}</td>
      </tr>
    </tbody>
  </table>
</div>`).join('')
}
