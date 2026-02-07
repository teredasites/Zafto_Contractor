// Supabase Edge Function: walkthrough-transcribe
// Transcribes voice notes from walkthrough and extracts actionable items.
// POST { walkthrough_id: string, voice_note_urls: string[] } → returns structured transcriptions.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TranscriptionResult {
  storagePath: string
  text: string
  measurements: string[]
  materials: string[]
  issues: string[]
  actionItems: string[]
  customerRequests: string[]
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

  const anthropicKey = Deno.env.get('ANTHROPIC_API_KEY')
  if (!anthropicKey) {
    return new Response(JSON.stringify({ error: 'AI service not configured' }), {
      status: 503,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const { walkthrough_id, voice_note_urls } = body

    if (!walkthrough_id) {
      return new Response(JSON.stringify({ error: 'walkthrough_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!voice_note_urls || !Array.isArray(voice_note_urls) || voice_note_urls.length === 0) {
      return new Response(JSON.stringify({ error: 'voice_note_urls required (array of storage paths)' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch walkthrough for context
    const { data: walkthrough, error: wtErr } = await supabase
      .from('walkthroughs')
      .select('*')
      .eq('id', walkthrough_id)
      .single()

    if (wtErr || !walkthrough) {
      return new Response(JSON.stringify({ error: 'Walkthrough not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    let totalInputTokens = 0
    let totalOutputTokens = 0
    const transcriptions: TranscriptionResult[] = []
    const errors: Array<{ storagePath: string; error: string }> = []

    // Process each voice note
    for (const storagePath of voice_note_urls.slice(0, 10)) {
      // Limit to 10 voice notes per request
      try {
        // Get signed URL for the voice note
        const { data: signedData, error: signErr } = await supabase.storage
          .from('voice-notes')
          .createSignedUrl(storagePath, 600)

        if (signErr || !signedData?.signedUrl) {
          errors.push({ storagePath, error: 'Failed to generate signed URL' })
          continue
        }

        // Fetch the audio file and convert to base64
        const audioResponse = await fetch(signedData.signedUrl)
        if (!audioResponse.ok) {
          errors.push({ storagePath, error: `Failed to fetch audio: ${audioResponse.status}` })
          continue
        }

        const arrayBuffer = await audioResponse.arrayBuffer()
        const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))

        // Determine media type from file extension
        const ext = storagePath.split('.').pop()?.toLowerCase() || 'm4a'
        const mediaTypeMap: Record<string, string> = {
          'm4a': 'audio/mp4',
          'mp3': 'audio/mpeg',
          'wav': 'audio/wav',
          'ogg': 'audio/ogg',
          'webm': 'audio/webm',
          'mp4': 'audio/mp4',
        }
        const mediaType = mediaTypeMap[ext] || 'audio/mp4'

        const prompt = `Transcribe this voice note from a property walkthrough and extract structured information.

WALKTHROUGH CONTEXT:
Property: ${walkthrough.address || 'Unknown address'}
Type: ${walkthrough.type || 'general'}
${walkthrough.notes ? `Notes: ${walkthrough.notes}` : ''}

Transcribe the audio completely and accurately, then extract:
1. Measurements mentioned (e.g., "12 foot by 10 foot room", "3 inch pipe")
2. Materials needed (e.g., "need 20 sheets of drywall", "copper pipe")
3. Issues found (e.g., "water damage on north wall", "cracked foundation")
4. Customer requests (e.g., "customer wants tile instead of vinyl")
5. Action items (e.g., "need to get permit", "schedule plumber for Thursday")

Return ONLY valid JSON:
{
  "text": "Full verbatim transcription of the voice note",
  "measurements": ["12ft x 10ft room", "8ft ceiling height"],
  "materials": ["20 sheets 1/2 inch drywall", "Joint compound"],
  "issues": ["Water damage on north wall - approximately 4x6 ft area"],
  "customerRequests": ["Wants tile backsplash instead of painted wall"],
  "actionItems": ["Get building permit before starting demo", "Order custom vanity - 6 week lead time"]
}`

        // Call Claude with audio content
        const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': anthropicKey,
            'anthropic-version': '2023-06-01',
          },
          body: JSON.stringify({
            model: 'claude-sonnet-4-5-20250929',
            max_tokens: 2048,
            messages: [{
              role: 'user',
              content: [
                {
                  type: 'document',
                  source: {
                    type: 'base64',
                    media_type: mediaType,
                    data: base64,
                  },
                },
                { type: 'text', text: prompt },
              ],
            }],
          }),
        })

        if (!claudeResponse.ok) {
          const errText = await claudeResponse.text()
          console.error(`Claude API error for ${storagePath}:`, errText)
          errors.push({ storagePath, error: 'AI transcription failed' })
          continue
        }

        const claudeResult = await claudeResponse.json()
        totalInputTokens += claudeResult.usage?.input_tokens || 0
        totalOutputTokens += claudeResult.usage?.output_tokens || 0

        const responseText = claudeResult.content?.[0]?.text || ''

        // Parse JSON response
        let parsed: Record<string, unknown> = {}
        try {
          const jsonMatch = responseText.match(/\{[\s\S]*\}/)
          if (!jsonMatch) throw new Error('No JSON in response')
          parsed = JSON.parse(jsonMatch[0])
        } catch {
          // If JSON parsing fails, treat the whole response as transcription text
          parsed = {
            text: responseText.substring(0, 5000),
            measurements: [],
            materials: [],
            issues: [],
            customerRequests: [],
            actionItems: [],
          }
        }

        transcriptions.push({
          storagePath,
          text: String(parsed.text || ''),
          measurements: (parsed.measurements as string[]) || [],
          materials: (parsed.materials as string[]) || [],
          issues: (parsed.issues as string[]) || [],
          actionItems: (parsed.actionItems as string[]) || [],
          customerRequests: (parsed.customerRequests as string[]) || [],
        })
      } catch (noteErr) {
        console.error(`Error processing voice note ${storagePath}:`, noteErr)
        errors.push({ storagePath, error: 'Processing failed' })
      }
    }

    // Aggregate all extracted items across all transcriptions
    const aggregated = {
      allMeasurements: transcriptions.flatMap(t => t.measurements),
      allMaterials: transcriptions.flatMap(t => t.materials),
      allIssues: transcriptions.flatMap(t => t.issues),
      allActionItems: transcriptions.flatMap(t => t.actionItems),
      allCustomerRequests: transcriptions.flatMap(t => t.customerRequests),
    }

    return new Response(JSON.stringify({
      success: true,
      walkthrough_id,
      transcriptions,
      aggregated,
      errors: errors.length > 0 ? errors : undefined,
      summary: {
        processed: transcriptions.length,
        failed: errors.length,
        total: voice_note_urls.length,
      },
      tokenUsage: {
        input: totalInputTokens,
        output: totalOutputTokens,
      },
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Walkthrough transcribe error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
