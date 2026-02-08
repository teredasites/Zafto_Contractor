// Supabase Edge Function: import-esx
// Imports industry-standard .esx estimate files (ZIP+XML format).
// POST multipart/form-data with file field "esx_file".
// Parses XACTDOC XML, maps codes to ZAFTO items, creates estimate + areas + line_items.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { unzipSync } from 'https://esm.sh/fflate@0.8.2'
import { XMLParser } from 'https://esm.sh/fast-xml-parser@4.3.6'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const MAX_FILE_SIZE = 100 * 1024 * 1024 // 100MB

// Generate estimate number: EST-YYYYMMDD-NNN
function generateEstimateNumber(): string {
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  const rand = String(Math.floor(Math.random() * 999) + 1).padStart(3, '0')
  return `EST-${y}${m}${d}-${rand}`
}

// Extract text content safely from parsed XML node
function txt(node: unknown): string {
  if (node === null || node === undefined) return ''
  if (typeof node === 'string') return node.trim()
  if (typeof node === 'number') return String(node)
  if (typeof node === 'object' && node !== null) {
    // fast-xml-parser may return { '#text': 'value' } for text nodes
    const obj = node as Record<string, unknown>
    if ('#text' in obj) return String(obj['#text']).trim()
    if ('_' in obj) return String(obj['_']).trim()
  }
  return String(node).trim()
}

// Extract attribute value from parsed XML
function attr(node: unknown, key: string): string {
  if (!node || typeof node !== 'object') return ''
  const obj = node as Record<string, unknown>
  // fast-xml-parser with attributeNamePrefix='@_'
  const attrKey = `@_${key}`
  if (attrKey in obj) return String(obj[attrKey]).trim()
  if (key in obj) return String(obj[key]).trim()
  return ''
}

// Ensure value is an array
function toArray<T>(val: T | T[] | undefined | null): T[] {
  if (val === undefined || val === null) return []
  return Array.isArray(val) ? val : [val]
}

interface ParsedContact {
  type: string
  name: string
  street: string
  city: string
  state: string
  zip: string
  phone: string
  email: string
}

interface ParsedLineItem {
  category: string
  selector: string
  description: string
  quantity: number
  unit: string
  unitPrice: number
  total: number
  materialCost: number
  laborCost: number
  equipmentCost: number
  coverage: string
  depreciation: number
}

interface ParsedRoom {
  name: string
  level: string
  lineItems: ParsedLineItem[]
}

interface ParsedEstimate {
  // Claim/Policy
  claimNumber: string
  policyNumber: string
  dateOfLoss: string
  dateReceived: string
  deductible: number
  // Contacts
  insured: ParsedContact | null
  adjuster: ParsedContact | null
  contractor: ParsedContact | null
  // Carrier
  carrierId: string
  // Notes
  notes: string
  // Rooms + Line Items
  rooms: ParsedRoom[]
  // Totals
  grandTotal: number
  totalLineItems: number
  // Photos
  photoFiles: string[]
}

function parseEsxXml(xmlString: string): ParsedEstimate {
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    textNodeName: '#text',
    parseAttributeValue: false,
    trimValues: true,
  })

  const doc = parser.parse(xmlString)
  const xactdoc = doc.XACTDOC || doc

  const result: ParsedEstimate = {
    claimNumber: '',
    policyNumber: '',
    dateOfLoss: '',
    dateReceived: '',
    deductible: 0,
    insured: null,
    adjuster: null,
    contractor: null,
    carrierId: '',
    notes: '',
    rooms: [],
    grandTotal: 0,
    totalLineItems: 0,
    photoFiles: [],
  }

  // Grand total from root attributes
  result.grandTotal = Number(attr(xactdoc, 'lastCalcGrandTotal') || '0')
  result.totalLineItems = Number(attr(xactdoc, 'totalLineItems') || '0')

  // ── XACTNET_INFO ──
  const xnInfo = xactdoc.XACTNET_INFO
  if (xnInfo) {
    result.carrierId = txt(xnInfo.carrierId) || txt(xnInfo.CARRIERID) || ''
  }

  // ── ADM (Administration) ──
  const adm = xactdoc.ADM
  if (adm) {
    result.dateOfLoss = txt(adm.dateOfLoss) || txt(adm.DATEOFLOSS) || ''
    result.dateReceived = txt(adm.dateReceived) || txt(adm.DATERECEIVED) || ''

    const covLoss = adm.COVERAGE_LOSS || adm.coverage_loss
    if (covLoss) {
      result.policyNumber = txt(covLoss.policyNumber) || txt(covLoss.POLICYNUMBER) || ''
      result.claimNumber = txt(covLoss.claimNumber) || txt(covLoss.CLAIMNUMBER) || ''

      // Deductible from coverages
      const coverages = toArray(covLoss.COVERAGES?.COVERAGE || covLoss.coverages?.coverage)
      for (const cov of coverages) {
        const ded = Number(attr(cov, 'deductible') || txt((cov as Record<string, unknown>)?.deductible) || '0')
        if (ded > 0 && result.deductible === 0) {
          result.deductible = ded
        }
      }
    }
  }

  // ── CONTACTS ──
  const contacts = toArray(xactdoc.CONTACTS?.CONTACT || xactdoc.contacts?.contact)
  for (const contact of contacts) {
    const cType = (attr(contact, 'type') || '').toLowerCase()
    const cName = attr(contact, 'name') || ''

    const addresses = toArray((contact as Record<string, unknown>)?.ADDRESSES?.ADDRESS ||
                             (contact as Record<string, unknown>)?.addresses?.address)
    const firstAddr = addresses[0] || {}

    const phoneMethods = toArray((contact as Record<string, unknown>)?.CONTACTMETHODS?.PHONE ||
                                (contact as Record<string, unknown>)?.contactmethods?.phone)
    const emailMethods = toArray((contact as Record<string, unknown>)?.CONTACTMETHODS?.EMAIL ||
                                (contact as Record<string, unknown>)?.contactmethods?.email)

    const parsed: ParsedContact = {
      type: cType,
      name: cName,
      street: attr(firstAddr, 'street') || '',
      city: attr(firstAddr, 'city') || '',
      state: attr(firstAddr, 'state') || '',
      zip: attr(firstAddr, 'postal') || attr(firstAddr, 'zip') || '',
      phone: phoneMethods.length > 0 ? (attr(phoneMethods[0], 'number') || '') : '',
      email: emailMethods.length > 0 ? (attr(emailMethods[0], 'address') || '') : '',
    }

    if (cType === 'insured' || cType === 'policyholder') {
      result.insured = parsed
    } else if (cType === 'adjuster') {
      result.adjuster = parsed
    } else if (cType === 'contractor') {
      result.contractor = parsed
    } else if (!result.insured && cType !== 'adjuster' && cType !== 'contractor') {
      result.insured = parsed
    }
  }

  // ── PROJECT_INFO (Notes) ──
  const projectInfo = xactdoc.PROJECT_INFO || xactdoc.project_info
  if (projectInfo) {
    result.notes = txt(projectInfo.NOTES) || txt(projectInfo.notes) || ''
  }

  // ── ESTIMATE (Rooms + Line Items) ──
  const estimate = xactdoc.ESTIMATE || xactdoc.estimate
  if (estimate) {
    const rooms = toArray(estimate.ROOM || estimate.room)
    for (const room of rooms) {
      const roomName = attr(room, 'name') || 'Unknown Room'
      const roomLevel = attr(room, 'level') || ''

      const lines = toArray((room as Record<string, unknown>).LINE || (room as Record<string, unknown>).line)
      const parsedLines: ParsedLineItem[] = []

      for (const line of lines) {
        parsedLines.push({
          category: attr(line, 'category') || '',
          selector: attr(line, 'selector') || '',
          description: attr(line, 'description') || txt(line) || '',
          quantity: Number(attr(line, 'qty') || attr(line, 'quantity') || '0'),
          unit: attr(line, 'unit') || 'EA',
          unitPrice: Number(attr(line, 'unitPrice') || attr(line, 'unitprice') || '0'),
          total: Number(attr(line, 'total') || '0'),
          materialCost: Number(attr(line, 'material') || attr(line, 'mat') || '0'),
          laborCost: Number(attr(line, 'labor') || attr(line, 'lab') || '0'),
          equipmentCost: Number(attr(line, 'equipment') || attr(line, 'equ') || '0'),
          coverage: attr(line, 'coverage') || '',
          depreciation: Number(attr(line, 'depreciation') || '0'),
        })
      }

      result.rooms.push({ name: roomName, level: roomLevel, lineItems: parsedLines })
    }
  }

  // Also try LINE_ITEMS at root level (flat format, no rooms)
  const lineItemsRoot = xactdoc.LINE_ITEMS || xactdoc.line_items
  if (lineItemsRoot && result.rooms.length === 0) {
    const items = toArray(lineItemsRoot.ESTIMATE_ITEM || lineItemsRoot.estimate_item || lineItemsRoot.LINE || lineItemsRoot.line)
    if (items.length > 0) {
      const parsedLines: ParsedLineItem[] = items.map((item: Record<string, unknown>) => ({
        category: txt(item.category) || attr(item, 'category') || '',
        selector: txt(item.selector) || attr(item, 'selector') || '',
        description: txt(item.description) || attr(item, 'description') || '',
        quantity: Number(txt(item.quantity) || attr(item, 'qty') || '0'),
        unit: txt(item.unit) || attr(item, 'unit') || 'EA',
        unitPrice: Number(txt(item.unitPrice) || attr(item, 'unitPrice') || '0'),
        total: Number(txt(item.total) || attr(item, 'total') || '0'),
        materialCost: Number(txt(item.material) || attr(item, 'material') || '0'),
        laborCost: Number(txt(item.labor) || attr(item, 'labor') || '0'),
        equipmentCost: Number(txt(item.equipment) || attr(item, 'equipment') || '0'),
        coverage: txt(item.coverage) || attr(item, 'coverage') || '',
        depreciation: Number(txt(item.depreciation) || attr(item, 'depreciation') || '0'),
      }))
      result.rooms.push({ name: 'Imported Items', level: '', lineItems: parsedLines })
    }
  }

  return result
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
    // Get user's company_id
    const { data: profile } = await supabase
      .from('users')
      .select('company_id')
      .eq('id', user.id)
      .single()

    if (!profile?.company_id) {
      return new Response(JSON.stringify({ error: 'No company found for user' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Parse multipart form data
    const formData = await req.formData()
    const file = formData.get('esx_file') as File | null

    if (!file) {
      return new Response(JSON.stringify({ error: 'esx_file field required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate file size
    if (file.size > MAX_FILE_SIZE) {
      return new Response(JSON.stringify({ error: `File too large (max ${MAX_FILE_SIZE / 1024 / 1024}MB)` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const arrayBuffer = await file.arrayBuffer()
    const bytes = new Uint8Array(arrayBuffer)

    // ── Detect format: ZIP or plain XML ──
    let xmlString = ''
    const isZip = bytes[0] === 0x50 && bytes[1] === 0x4B // PK header

    if (isZip) {
      // ZIP bomb detection: decompressed size limit (500MB)
      const decompressLimit = 500 * 1024 * 1024
      let totalDecompressed = 0

      const unzipped = unzipSync(bytes)
      const fileNames = Object.keys(unzipped)

      // Check total decompressed size
      for (const name of fileNames) {
        totalDecompressed += unzipped[name].length
        if (totalDecompressed > decompressLimit) {
          return new Response(JSON.stringify({ error: 'File decompression exceeds safety limit' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }
      }

      // Find the XML data file
      const xmlFile = fileNames.find(n =>
        n.toUpperCase().includes('XACTDOC') ||
        n.toLowerCase().endsWith('.xml') ||
        n.toLowerCase().endsWith('.zipxml')
      )

      if (!xmlFile) {
        return new Response(JSON.stringify({
          error: 'No XML data file found in archive',
          files: fileNames.slice(0, 20),
        }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      xmlString = new TextDecoder().decode(unzipped[xmlFile])
    } else {
      // Try as plain XML
      xmlString = new TextDecoder().decode(bytes)
      if (!xmlString.includes('<') || !xmlString.includes('>')) {
        return new Response(JSON.stringify({ error: 'File is not a valid ZIP archive or XML document' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    // ── Parse the XML ──
    const parsed = parseEsxXml(xmlString)

    // ── Create estimate in database ──
    const estimateNumber = generateEstimateNumber()
    const isInsurance = !!(parsed.claimNumber || parsed.policyNumber || parsed.carrierId)

    const insuredAddr = parsed.insured
      ? [parsed.insured.street, parsed.insured.city, parsed.insured.state, parsed.insured.zip].filter(Boolean)
      : []

    const estimateInsert = {
      company_id: profile.company_id,
      created_by: user.id,
      estimate_number: estimateNumber,
      title: parsed.claimNumber
        ? `Insurance Claim ${parsed.claimNumber}`
        : `Imported Estimate ${estimateNumber}`,
      estimate_type: isInsurance ? 'insurance' : 'regular',
      status: 'draft',
      customer_name: parsed.insured?.name || null,
      customer_email: parsed.insured?.email || null,
      customer_phone: parsed.insured?.phone || null,
      property_address: insuredAddr[0] || null,
      property_city: insuredAddr[1] || null,
      property_state: insuredAddr[2] || null,
      property_zip: insuredAddr[3] || null,
      claim_number: parsed.claimNumber || null,
      policy_number: parsed.policyNumber || null,
      carrier_name: parsed.carrierId || null,
      adjuster_name: parsed.adjuster?.name || null,
      adjuster_email: parsed.adjuster?.email || null,
      adjuster_phone: parsed.adjuster?.phone || null,
      deductible: parsed.deductible || 0,
      date_of_loss: parsed.dateOfLoss || null,
      overhead_percent: 10,
      profit_percent: 10,
      tax_percent: 0,
      notes: parsed.notes || null,
      source: 'esx_import',
    }

    const { data: estimate, error: estError } = await supabase
      .from('estimates')
      .insert(estimateInsert)
      .select('id')
      .single()

    if (estError || !estimate) {
      return new Response(JSON.stringify({ error: 'Failed to create estimate', detail: estError?.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const estimateId = estimate.id

    // ── Create areas (rooms) ──
    let totalLineItemsCreated = 0
    const unknownCodes: Array<{ category: string; selector: string; description: string; unit: string }> = []

    for (let areaIdx = 0; areaIdx < parsed.rooms.length; areaIdx++) {
      const room = parsed.rooms[areaIdx]

      const { data: area, error: areaError } = await supabase
        .from('estimate_areas')
        .insert({
          estimate_id: estimateId,
          name: room.name,
          sort_order: areaIdx,
        })
        .select('id')
        .single()

      if (areaError || !area) continue

      // ── Create line items ──
      const lineInserts = []
      for (let lineIdx = 0; lineIdx < room.lineItems.length; lineIdx++) {
        const line = room.lineItems[lineIdx]
        const zaftoCode = line.category && line.selector
          ? `${line.category}-${line.selector}`
          : line.category || null

        // Try to find matching item in ZAFTO code database
        let itemId: string | null = null
        if (line.category) {
          const { data: matchedItem } = await supabase
            .from('estimate_items')
            .select('id')
            .eq('trade', line.category)
            .ilike('name', `%${line.description.substring(0, 30)}%`)
            .limit(1)
            .single()

          if (matchedItem) {
            itemId = matchedItem.id
          } else {
            // Track unknown code for contribution
            unknownCodes.push({
              category: line.category,
              selector: line.selector,
              description: line.description,
              unit: line.unit,
            })
          }
        }

        const lineTotal = line.total || (line.quantity * line.unitPrice) || 0

        lineInserts.push({
          estimate_id: estimateId,
          area_id: area.id,
          item_id: itemId,
          zafto_code: zaftoCode,
          description: line.description,
          action_type: 'replace',
          quantity: line.quantity || 1,
          unit_code: line.unit || 'EA',
          material_cost: line.materialCost,
          labor_cost: line.laborCost,
          equipment_cost: line.equipmentCost,
          unit_price: line.unitPrice || (lineTotal / (line.quantity || 1)),
          line_total: lineTotal,
          sort_order: lineIdx,
          notes: line.coverage ? `Coverage: ${line.coverage}` : null,
        })
      }

      if (lineInserts.length > 0) {
        const { error: linesError } = await supabase
          .from('estimate_line_items')
          .insert(lineInserts)

        if (!linesError) {
          totalLineItemsCreated += lineInserts.length
        }
      }
    }

    // ── Store unknown codes as contributions (with dedup) ──
    if (unknownCodes.length > 0) {
      for (const code of unknownCodes) {
        const industryCode = code.category.substring(0, 10)
        const industrySelector = (code.selector || code.category).substring(0, 20)

        // Check if this code already exists in contributions
        const { data: existing } = await supabase
          .from('code_contributions')
          .select('id, verification_count')
          .eq('industry_code', industryCode)
          .eq('industry_selector', industrySelector)
          .limit(1)
          .maybeSingle()

        if (existing) {
          // Increment verification count (another user submitted the same code)
          await supabase
            .from('code_contributions')
            .update({ verification_count: existing.verification_count + 1 })
            .eq('id', existing.id)
        } else {
          // Insert new contribution
          await supabase.from('code_contributions').insert({
            company_id: profile.company_id,
            user_id: user.id,
            industry_code: industryCode,
            industry_selector: industrySelector,
            description: code.description,
            unit_code: code.unit || 'EA',
            trade: code.category,
          })
        }
      }
    }

    // ── Recalculate totals on the estimate ──
    const { data: allLines } = await supabase
      .from('estimate_line_items')
      .select('line_total')
      .eq('estimate_id', estimateId)

    const subtotal = (allLines || []).reduce((sum: number, l: { line_total: number }) => sum + Number(l.line_total || 0), 0)
    const overhead = subtotal * 0.10
    const profit = subtotal * 0.10
    const grandTotal = subtotal + overhead + profit

    await supabase
      .from('estimates')
      .update({
        subtotal,
        grand_total: grandTotal,
      })
      .eq('id', estimateId)

    return new Response(JSON.stringify({
      success: true,
      estimate_id: estimateId,
      estimate_number: estimateNumber,
      estimate_type: isInsurance ? 'insurance' : 'regular',
      rooms_created: parsed.rooms.length,
      line_items_created: totalLineItemsCreated,
      unknown_codes_contributed: unknownCodes.length,
      import_source: file.name,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ESX import error:', err)
    return new Response(JSON.stringify({ error: 'Import failed', detail: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
