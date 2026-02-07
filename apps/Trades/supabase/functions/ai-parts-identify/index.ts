// Supabase Edge Function: ai-parts-identify
// Part identification via text description and/or photo. Uses Claude Vision when photo provided.
// POST { description: string, photo_url?: string, trade?: string }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PartsIdentifyRequest {
  description: string
  photo_url?: string
  trade?: string
}

interface PartAlternative {
  name: string
  part_number?: string
  notes: string
}

interface PartsIdentifyResult {
  part_name: string
  manufacturer: string
  part_number: string
  description: string
  alternatives: PartAlternative[]
  common_suppliers: string[]
  estimated_price_range: string
  compatibility_notes: string
  trade_category: string
}

function buildSystemPrompt(trade?: string): string {
  const tradeContext = trade
    ? `You specialize in ${trade} parts and components, with deep knowledge of manufacturer catalogs, part numbering systems, and cross-reference databases for ${trade} equipment.`
    : 'You have broad expertise across all construction trades and their associated parts, components, and materials.'

  return `You are an expert parts specialist with 20+ years of experience in construction, HVAC, electrical, plumbing, and general contracting supply chains. ${tradeContext}

YOUR EXPERTISE:
- Manufacturer part numbering systems and cross-references
- OEM vs aftermarket part compatibility
- Common failure parts by equipment model and age
- Supply chain knowledge (where to source parts)
- Pricing knowledge across wholesale and retail channels
- Backward compatibility and superseded part numbers

IDENTIFICATION APPROACH:
- If a photo is provided, identify the part visually (markings, shape, size, color, material, connectors)
- If text description only, use contextual clues to narrow down the part
- Always provide the most specific identification possible
- If uncertain, state confidence level and provide the best candidates
- Include common alternative names/terms for the part (regional variations)

IMPORTANT:
- For common_suppliers, list generic supplier types (e.g., "Electrical supply house", "HVAC distributor", "Home improvement store") — NOT affiliate links or specific store locations
- Part numbers should be industry-standard or manufacturer-specific when identifiable
- Price ranges should reflect current US market rates

Return ONLY valid JSON matching this exact structure:
{
  "part_name": "Full, specific part name",
  "manufacturer": "Manufacturer name if identifiable, or 'Unknown/Generic' if not",
  "part_number": "Specific part number if identifiable, or 'N/A' if not",
  "description": "Detailed description of the part including material, size, rating, and function",
  "alternatives": [
    {
      "name": "Alternative part name or compatible replacement",
      "part_number": "Part number if known",
      "notes": "Compatibility notes or differences from the identified part"
    }
  ],
  "common_suppliers": ["Supplier type 1", "Supplier type 2"],
  "estimated_price_range": "$XX - $XX (for the primary identified part)",
  "compatibility_notes": "Important compatibility information, required accessories, or installation notes",
  "trade_category": "The trade this part belongs to (electrical, plumbing, hvac, etc.)"
}`
}

async function fetchImageAsBase64(url: string): Promise<{ data: string; media_type: string }> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status} ${response.statusText}`)
  }

  const arrayBuffer = await response.arrayBuffer()
  const bytes = new Uint8Array(arrayBuffer)

  let binary = ''
  const chunkSize = 8192
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize)
    binary += String.fromCharCode(...chunk)
  }
  const base64 = btoa(binary)

  let mediaType = response.headers.get('content-type') || 'image/jpeg'
  if (!mediaType.startsWith('image/')) {
    const urlLower = url.toLowerCase()
    if (urlLower.includes('.png')) mediaType = 'image/png'
    else if (urlLower.includes('.webp')) mediaType = 'image/webp'
    else if (urlLower.includes('.gif')) mediaType = 'image/gif'
    else mediaType = 'image/jpeg'
  }

  return { data: base64, media_type: mediaType }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Verify authorization
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

  // Verify Anthropic API key
  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!anthropicKey) {
    return new Response(JSON.stringify({ error: 'AI service not configured' }), {
      status: 503,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body: PartsIdentifyRequest = await req.json()
    const { description, photo_url, trade } = body

    // Validate: at least description is required
    if (!description || typeof description !== 'string') {
      return new Response(JSON.stringify({ error: 'description is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (description.length > 3000) {
      return new Response(JSON.stringify({ error: 'description must be under 3000 characters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Build message content (text-only or vision)
    const messageContent: Array<Record<string, unknown>> = []

    // If photo URL provided, fetch and include as vision input
    if (photo_url && typeof photo_url === 'string') {
      try {
        new URL(photo_url)
      } catch {
        return new Response(JSON.stringify({ error: 'photo_url must be a valid URL' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      try {
        const imageData = await fetchImageAsBase64(photo_url)

        if (imageData.data.length > 20_000_000) {
          return new Response(JSON.stringify({ error: 'Image is too large. Maximum size is approximately 15MB.' }), {
            status: 413,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        messageContent.push({
          type: 'image',
          source: {
            type: 'base64',
            media_type: imageData.media_type,
            data: imageData.data,
          },
        })
      } catch (fetchErr) {
        console.error('Image fetch error:', fetchErr)
        // Continue without image — fall back to text-only identification
        messageContent.push({
          type: 'text',
          text: '[Note: A photo was provided but could not be retrieved. Identifying based on text description only.]',
        })
      }
    }

    // Build user prompt
    const tradeLine = trade ? `Trade: ${trade}` : ''
    const userPrompt = `Identify this part:

Description: ${description}
${tradeLine}
${photo_url ? 'A photo of the part has been provided above.' : 'No photo available — identify based on the text description.'}

Provide the most specific identification possible, including part number, manufacturer, alternatives, and sourcing information.`

    messageContent.push({ type: 'text', text: userPrompt })

    // Call Claude API
    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 3072,
        system: buildSystemPrompt(trade),
        messages: [{
          role: 'user',
          content: messageContent,
        }],
      }),
    })

    if (!claudeResponse.ok) {
      const errText = await claudeResponse.text()
      console.error('Claude API error:', errText)
      return new Response(JSON.stringify({ error: 'AI service temporarily unavailable' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const claudeResult = await claudeResponse.json()
    const responseText = claudeResult.content?.[0]?.text || ''

    // Parse Claude's JSON response
    let identification: PartsIdentifyResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      identification = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      identification = {
        part_name: 'Identification inconclusive',
        manufacturer: 'Unknown',
        part_number: 'N/A',
        description: responseText.substring(0, 1000),
        alternatives: [],
        common_suppliers: ['Local hardware store', 'Trade-specific supply house'],
        estimated_price_range: 'Unable to estimate',
        compatibility_notes: 'Manual identification recommended. Bring the part to a supply house for positive ID.',
        trade_category: trade || 'general',
      }
    }

    // Token usage
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      has_photo: !!photo_url,
      ...identification,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-parts-identify error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
