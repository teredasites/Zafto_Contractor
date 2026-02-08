// Supabase Edge Function: export-esx
// Generates industry-compatible .esx files (ZIP+XML) from D8 estimates.
// GET ?estimate_id=UUID → returns ZIP binary with .esx content type.
// Standard ZIP archive containing XACTDOC.XML + photo attachments.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { zipSync, strToU8 } from 'https://esm.sh/fflate@0.8.2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function escapeXml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

function fmt(n: number): string {
  return n.toFixed(2)
}

function formatDate(d: string | null): string {
  if (!d) return ''
  try {
    return new Date(d).toISOString().split('T')[0]
  } catch {
    return ''
  }
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
    const estimateId = url.searchParams.get('estimate_id')

    if (!estimateId) {
      return new Response(JSON.stringify({ error: 'estimate_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch estimate + areas + line items + photos in parallel
    const [estRes, areasRes, linesRes, photosRes] = await Promise.all([
      supabase.from('estimates').select('*').eq('id', estimateId).single(),
      supabase.from('estimate_areas').select('*').eq('estimate_id', estimateId).order('sort_order'),
      supabase.from('estimate_line_items').select('*').eq('estimate_id', estimateId).order('sort_order'),
      supabase.from('estimate_photos').select('*').eq('estimate_id', estimateId),
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
    const photos = photosRes.data || []

    // Fetch company info for contractor contact
    const { data: profile } = await supabase
      .from('users')
      .select('company_id, name')
      .eq('id', user.id)
      .single()

    let companyName = ''
    let companyPhone = ''
    let companyEmail = ''
    let companyAddress = ''
    let companyCity = ''
    let companyState = ''
    let companyZip = ''

    if (profile?.company_id) {
      const { data: company } = await supabase
        .from('companies')
        .select('name, phone, email, address_line1, address_city, address_state, address_zip')
        .eq('id', profile.company_id)
        .single()

      if (company) {
        companyName = company.name || ''
        companyPhone = company.phone || ''
        companyEmail = company.email || ''
        companyAddress = company.address_line1 || ''
        companyCity = company.address_city || ''
        companyState = company.address_state || ''
        companyZip = company.address_zip || ''
      }
    }

    // Group line items by area
    const linesByArea = new Map<string, Array<Record<string, unknown>>>()
    const unassigned: Array<Record<string, unknown>> = []
    for (const line of lineItems) {
      if (line.area_id) {
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

    // ── Build XACTDOC XML ──
    let xml = `<?xml version="1.0" encoding="UTF-8"?>\n`
    xml += `<XACTDOC lastCalcGrandTotal="${fmt(grandTotal)}" totalLineItems="${lineItems.length}" usesRulesEngine="false">\n`

    // XACTNET_INFO
    xml += `  <XACTNET_INFO>\n`
    xml += `    <carrierId>${escapeXml(estimate.carrier_name || '')}</carrierId>\n`
    xml += `    <profileCode>US-${escapeXml(estimate.property_state || 'XX')}</profileCode>\n`
    xml += `  </XACTNET_INFO>\n`

    // ADM
    xml += `  <ADM>\n`
    xml += `    <dateReceived>${formatDate(estimate.created_at)}</dateReceived>\n`
    xml += `    <dateOfLoss>${formatDate(estimate.date_of_loss)}</dateOfLoss>\n`
    xml += `    <COVERAGE_LOSS>\n`
    xml += `      <policyNumber>${escapeXml(estimate.policy_number || '')}</policyNumber>\n`
    xml += `      <claimNumber>${escapeXml(estimate.claim_number || '')}</claimNumber>\n`
    xml += `      <isCommercial>false</isCommercial>\n`
    xml += `      <COVERAGES>\n`
    xml += `        <COVERAGE id="1" covType="dwelling" covName="Coverage A" deductible="${fmt(Number(estimate.deductible || 0))}" reserveAmt="${fmt(grandTotal)}" />\n`
    xml += `      </COVERAGES>\n`
    xml += `    </COVERAGE_LOSS>\n`
    xml += `  </ADM>\n`

    // CONTACTS
    xml += `  <CONTACTS>\n`

    // Insured (customer)
    if (estimate.customer_name) {
      xml += `    <CONTACT type="insured" name="${escapeXml(estimate.customer_name)}">\n`
      xml += `      <ADDRESSES>\n`
      xml += `        <ADDRESS type="loss" country="US" street="${escapeXml(estimate.property_address || '')}" city="${escapeXml(estimate.property_city || '')}" state="${escapeXml(estimate.property_state || '')}" postal="${escapeXml(estimate.property_zip || '')}" />\n`
      xml += `      </ADDRESSES>\n`
      xml += `      <CONTACTMETHODS>\n`
      if (estimate.customer_phone) {
        xml += `        <PHONE type="home" number="${escapeXml(estimate.customer_phone)}" />\n`
      }
      if (estimate.customer_email) {
        xml += `        <EMAIL address="${escapeXml(estimate.customer_email)}" />\n`
      }
      xml += `      </CONTACTMETHODS>\n`
      xml += `    </CONTACT>\n`
    }

    // Adjuster
    if (estimate.adjuster_name) {
      xml += `    <CONTACT type="adjuster" name="${escapeXml(estimate.adjuster_name)}">\n`
      xml += `      <CONTACTMETHODS>\n`
      if (estimate.adjuster_phone) {
        xml += `        <PHONE type="work" number="${escapeXml(estimate.adjuster_phone)}" />\n`
      }
      if (estimate.adjuster_email) {
        xml += `        <EMAIL address="${escapeXml(estimate.adjuster_email)}" />\n`
      }
      xml += `      </CONTACTMETHODS>\n`
      xml += `    </CONTACT>\n`
    }

    // Contractor
    xml += `    <CONTACT type="contractor" name="${escapeXml(companyName || profile?.name || '')}">\n`
    xml += `      <ADDRESSES>\n`
    xml += `        <ADDRESS type="billing" country="US" street="${escapeXml(companyAddress)}" city="${escapeXml(companyCity)}" state="${escapeXml(companyState)}" postal="${escapeXml(companyZip)}" />\n`
    xml += `      </ADDRESSES>\n`
    xml += `      <CONTACTMETHODS>\n`
    if (companyPhone) {
      xml += `        <PHONE type="work" number="${escapeXml(companyPhone)}" />\n`
    }
    if (companyEmail) {
      xml += `        <EMAIL address="${escapeXml(companyEmail)}" />\n`
    }
    xml += `      </CONTACTMETHODS>\n`
    xml += `    </CONTACT>\n`

    xml += `  </CONTACTS>\n`

    // PROJECT_INFO
    if (estimate.notes) {
      xml += `  <PROJECT_INFO>\n`
      xml += `    <NOTES><![CDATA[${estimate.notes}]]></NOTES>\n`
      xml += `  </PROJECT_INFO>\n`
    }

    // ESTIMATE (Rooms + Line Items)
    xml += `  <ESTIMATE>\n`

    for (const area of areas) {
      const areaLines = linesByArea.get(area.id) || []
      xml += `    <ROOM name="${escapeXml(area.name || 'Room')}" level="${escapeXml(area.level || '1st')}">\n`

      for (const line of areaLines) {
        const code = String(line.zafto_code || '').split('-')
        const category = code[0] || ''
        const selector = code.slice(1).join('-') || ''

        xml += `      <LINE category="${escapeXml(category)}" selector="${escapeXml(selector)}" description="${escapeXml(String(line.description || ''))}" qty="${fmt(Number(line.quantity || 0))}" unit="${escapeXml(String(line.unit_code || 'EA'))}" unitPrice="${fmt(Number(line.unit_price || 0))}" total="${fmt(Number(line.line_total || 0))}" material="${fmt(Number(line.material_cost || 0))}" labor="${fmt(Number(line.labor_cost || 0))}" equipment="${fmt(Number(line.equipment_cost || 0))}" coverage="structural" depreciation="0" />\n`
      }

      xml += `    </ROOM>\n`
    }

    // Unassigned items
    if (unassigned.length > 0) {
      xml += `    <ROOM name="General" level="1st">\n`
      for (const line of unassigned) {
        const code = String(line.zafto_code || '').split('-')
        const category = code[0] || ''
        const selector = code.slice(1).join('-') || ''

        xml += `      <LINE category="${escapeXml(category)}" selector="${escapeXml(selector)}" description="${escapeXml(String(line.description || ''))}" qty="${fmt(Number(line.quantity || 0))}" unit="${escapeXml(String(line.unit_code || 'EA'))}" unitPrice="${fmt(Number(line.unit_price || 0))}" total="${fmt(Number(line.line_total || 0))}" material="${fmt(Number(line.material_cost || 0))}" labor="${fmt(Number(line.labor_cost || 0))}" equipment="${fmt(Number(line.equipment_cost || 0))}" coverage="structural" depreciation="0" />\n`
      }
      xml += `    </ROOM>\n`
    }

    xml += `  </ESTIMATE>\n`
    xml += `</XACTDOC>\n`

    // ── Build ZIP archive ──
    const zipFiles: Record<string, Uint8Array> = {
      'XACTDOC.XML': strToU8(xml),
    }

    // Add photos if available
    for (let i = 0; i < photos.length; i++) {
      const photo = photos[i]
      if (photo.storage_path) {
        try {
          const { data: signedUrl } = await supabase.storage
            .from('estimate-photos')
            .createSignedUrl(photo.storage_path, 60)

          if (signedUrl?.signedUrl) {
            const photoRes = await fetch(signedUrl.signedUrl)
            if (photoRes.ok) {
              const photoBytes = new Uint8Array(await photoRes.arrayBuffer())
              const ext = photo.storage_path.split('.').pop() || 'jpg'
              zipFiles[`Images/photo_${String(i + 1).padStart(3, '0')}.${ext}`] = photoBytes
            }
          }
        } catch {
          // Skip photos that fail to download
        }
      }
    }

    const zipped = zipSync(zipFiles, { level: 6 })

    const fileName = `${estimate.estimate_number || 'estimate'}.esx`

    return new Response(zipped, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${fileName}"`,
        'Cache-Control': 'no-cache',
      },
    })
  } catch (err) {
    console.error('ESX export error:', err)
    return new Response(JSON.stringify({ error: 'Export failed', detail: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
