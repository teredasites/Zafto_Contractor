// Supabase Edge Function: ai-photo-diagnose
// Photo-based defect detection using Claude Vision. Analyzes construction/trade photos
// for defects, code violations, and recommended repairs.
// POST { photo_url: string, trade?: string, context?: string }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PhotoDiagnoseRequest {
  photo_url: string
  trade?: string
  context?: string
}

interface IssueFound {
  severity: 'critical' | 'major' | 'minor' | 'cosmetic'
  description: string
  location_in_image: string
  recommended_action: string
}

interface CodeViolation {
  code: string
  section: string
  violation: string
  severity: 'critical' | 'major' | 'minor'
}

interface PhotoDiagnoseResult {
  issues_found: IssueFound[]
  overall_condition: number
  priority_repairs: string[]
  estimated_cost_range: string
  code_violations: CodeViolation[]
}

function buildSystemPrompt(trade?: string): string {
  const tradeSpecific = trade
    ? `You specialize in ${trade} inspections and are deeply familiar with ${trade}-specific code requirements, common defects, and failure patterns.`
    : 'You are proficient across all construction trades and can identify cross-trade issues.'

  return `You are an expert construction inspector and defect analyst with 20+ years of field inspection experience. ${tradeSpecific}

YOUR INSPECTION CAPABILITIES:
- Visual defect detection (cracks, water damage, corrosion, wear, improper installations)
- Building code violation identification (NEC, IRC, IPC, IMC, IBC as applicable)
- Safety hazard recognition (electrical, structural, fire, health)
- Material condition assessment (age, degradation, remaining lifespan)
- Workmanship quality evaluation (proper techniques, manufacturer specs)

INSPECTION STANDARDS:
- Rate overall condition on a 1-5 scale: 1=Critical/Unsafe, 2=Poor, 3=Fair, 4=Good, 5=Excellent
- Severity levels: critical (immediate safety hazard), major (significant defect, needs prompt repair), minor (should be addressed, not urgent), cosmetic (appearance only)
- Be specific about WHERE in the image each issue is located (use cardinal directions, quadrants, or descriptive positions)
- Provide realistic cost ranges based on current market rates
- Only flag code violations you can reasonably identify from the photo

Return ONLY valid JSON matching this exact structure:
{
  "issues_found": [
    {
      "severity": "critical|major|minor|cosmetic",
      "description": "Detailed description of the issue observed",
      "location_in_image": "Where in the photo this issue is visible (e.g., upper-left corner, center, along the bottom edge)",
      "recommended_action": "Specific repair recommendation"
    }
  ],
  "overall_condition": 3,
  "priority_repairs": ["Most urgent repair first", "Second priority"],
  "estimated_cost_range": "$X,XXX - $X,XXX total for all identified repairs",
  "code_violations": [
    {
      "code": "Code name (e.g., NEC, IRC)",
      "section": "Specific section if identifiable",
      "violation": "Description of the violation",
      "severity": "critical|major|minor"
    }
  ]
}

If the image does not appear to be construction/trade related, still analyze it but note that it may not be a construction photo. If the image is too blurry or dark to analyze, state that clearly in your response.`
}

async function fetchImageAsBase64(url: string): Promise<{ data: string; media_type: string }> {
  const response = await fetch(url)
  if (!response.ok) {
    throw new Error(`Failed to fetch image: ${response.status} ${response.statusText}`)
  }

  const arrayBuffer = await response.arrayBuffer()
  const bytes = new Uint8Array(arrayBuffer)

  // Convert to base64
  let binary = ''
  const chunkSize = 8192
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize)
    binary += String.fromCharCode(...chunk)
  }
  const base64 = btoa(binary)

  // Determine media type from response headers or URL
  let mediaType = response.headers.get('content-type') || 'image/jpeg'
  // Ensure it's a valid image media type
  if (!mediaType.startsWith('image/')) {
    // Try to infer from URL
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
    const body: PhotoDiagnoseRequest = await req.json()
    const { photo_url, trade, context } = body

    // Validate required fields
    if (!photo_url || typeof photo_url !== 'string') {
      return new Response(JSON.stringify({ error: 'photo_url is required and must be a string' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Basic URL validation
    try {
      new URL(photo_url)
    } catch {
      return new Response(JSON.stringify({ error: 'photo_url must be a valid URL' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch and convert image to base64
    let imageData: { data: string; media_type: string }
    try {
      imageData = await fetchImageAsBase64(photo_url)
    } catch (fetchErr) {
      console.error('Image fetch error:', fetchErr)
      return new Response(JSON.stringify({ error: 'Failed to retrieve image from provided URL' }), {
        status: 422,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Validate image size (base64 adds ~33% overhead, Claude limit is ~20MB)
    if (imageData.data.length > 20_000_000) {
      return new Response(JSON.stringify({ error: 'Image is too large. Maximum size is approximately 15MB.' }), {
        status: 413,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Build user message
    const contextParts: string[] = []
    if (trade) contextParts.push(`Trade Focus: ${trade}`)
    if (context) contextParts.push(`Additional Context: ${context}`)

    const userMessage = `Inspect this photo and identify all defects, issues, code violations, and areas of concern.
${contextParts.length > 0 ? `\n${contextParts.join('\n')}` : ''}

Provide a thorough inspection report with prioritized findings.`

    // Call Claude Vision API
    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 4096,
        system: buildSystemPrompt(trade),
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: imageData.media_type,
                data: imageData.data,
              },
            },
            {
              type: 'text',
              text: userMessage,
            },
          ],
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
    let diagnosis: PhotoDiagnoseResult
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (!jsonMatch) throw new Error('No JSON found in response')
      diagnosis = JSON.parse(jsonMatch[0])
    } catch (parseErr) {
      console.error('Failed to parse Claude response:', parseErr)
      diagnosis = {
        issues_found: [{
          severity: 'minor',
          description: 'Analysis completed but structured parsing failed. Raw analysis available.',
          location_in_image: 'N/A',
          recommended_action: 'Review raw analysis text.',
        }],
        overall_condition: 3,
        priority_repairs: [],
        estimated_cost_range: 'Unable to estimate',
        code_violations: [],
      }
    }

    // Validate and clamp overall_condition to 1-5
    if (typeof diagnosis.overall_condition !== 'number' || diagnosis.overall_condition < 1) {
      diagnosis.overall_condition = 1
    } else if (diagnosis.overall_condition > 5) {
      diagnosis.overall_condition = 5
    }
    diagnosis.overall_condition = Math.round(diagnosis.overall_condition)

    // Token usage
    const tokenUsage = {
      input: claudeResult.usage?.input_tokens || 0,
      output: claudeResult.usage?.output_tokens || 0,
    }

    return new Response(JSON.stringify({
      success: true,
      trade: trade || 'general',
      ...diagnosis,
      token_usage: tokenUsage,
      model: 'claude-sonnet-4-5-20250929',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('ai-photo-diagnose error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
