// Supabase Edge Function: walkthrough-analyze
// Analyzes walkthrough photos using Claude Vision and generates room assessments.
// POST { walkthrough_id: string } → returns room assessments + overall property assessment.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RoomAssessment {
  roomId: string
  roomName: string
  roomType: string
  analysis: string
  issues: string[]
  materials: string[]
  conditionRating: number | null
  dimensions: Record<string, unknown> | null
  photoCount: number
}

interface AnalyzeResult {
  roomAssessments: RoomAssessment[]
  overallAssessment: string
  estimatedScope: string[]
  tokenUsage: { input: number; output: number }
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
    const { walkthrough_id } = body

    if (!walkthrough_id) {
      return new Response(JSON.stringify({ error: 'walkthrough_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch walkthrough
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

    // Fetch all rooms for this walkthrough
    const { data: rooms } = await supabase
      .from('walkthrough_rooms')
      .select('*')
      .eq('walkthrough_id', walkthrough_id)
      .order('sort_order')

    const walkthroughRooms = rooms || []

    // Fetch all photos for this walkthrough
    const { data: photos } = await supabase
      .from('walkthrough_photos')
      .select('*')
      .eq('walkthrough_id', walkthrough_id)
      .order('created_at')

    const walkthroughPhotos = photos || []

    // Group photos by room
    const photosByRoom = new Map<string, typeof walkthroughPhotos>()
    for (const photo of walkthroughPhotos) {
      const roomId = photo.room_id || '__unassigned__'
      const existing = photosByRoom.get(roomId) || []
      existing.push(photo)
      photosByRoom.set(roomId, existing)
    }

    let totalInputTokens = 0
    let totalOutputTokens = 0
    const roomAssessments: RoomAssessment[] = []

    // Process each room with photos
    for (const room of walkthroughRooms) {
      const roomPhotos = photosByRoom.get(room.id) || []

      if (roomPhotos.length === 0) {
        // No photos for this room — add basic assessment from metadata only
        roomAssessments.push({
          roomId: room.id,
          roomName: room.name,
          roomType: room.type || 'unknown',
          analysis: 'No photos available for analysis. Assessment based on metadata only.',
          issues: [],
          materials: [],
          conditionRating: room.condition_rating || null,
          dimensions: room.dimensions || null,
          photoCount: 0,
        })
        continue
      }

      // Get signed URLs for room photos (10 min expiry)
      const imageContents: Array<{ type: string; source: { type: string; media_type: string; data: string } }> = []

      for (const photo of roomPhotos.slice(0, 8)) {
        // Limit to 8 photos per room to stay within token limits
        try {
          const { data: signedData } = await supabase.storage
            .from('walkthrough-photos')
            .createSignedUrl(photo.storage_path, 600)

          if (signedData?.signedUrl) {
            // Fetch the image and convert to base64
            const imgResponse = await fetch(signedData.signedUrl)
            if (imgResponse.ok) {
              const arrayBuffer = await imgResponse.arrayBuffer()
              const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
              const contentType = imgResponse.headers.get('content-type') || 'image/jpeg'

              imageContents.push({
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: contentType,
                  data: base64,
                },
              })
            }
          }
        } catch (imgErr) {
          console.error(`Failed to fetch photo ${photo.id}:`, imgErr)
        }
      }

      if (imageContents.length === 0) {
        roomAssessments.push({
          roomId: room.id,
          roomName: room.name,
          roomType: room.type || 'unknown',
          analysis: 'Photos exist but could not be retrieved for analysis.',
          issues: [],
          materials: [],
          conditionRating: room.condition_rating || null,
          dimensions: room.dimensions || null,
          photoCount: roomPhotos.length,
        })
        continue
      }

      // Build room context
      const roomContext = [
        `Room: ${room.name}`,
        `Type: ${room.type || 'unknown'}`,
        room.dimensions ? `Dimensions: ${JSON.stringify(room.dimensions)}` : null,
        room.condition_rating ? `Condition Rating: ${room.condition_rating}/5` : null,
        room.notes ? `Notes: ${room.notes}` : null,
        room.tags && room.tags.length > 0 ? `Tags: ${room.tags.join(', ')}` : null,
      ].filter(Boolean).join('\n')

      const prompt = `Analyze these ${imageContents.length} photos of a ${room.type || 'general'} room from a property walkthrough.

ROOM CONTEXT:
${roomContext}

WALKTHROUGH CONTEXT:
Property: ${walkthrough.address || 'Unknown address'}
Type: ${walkthrough.type || 'general'}
${walkthrough.notes ? `Notes: ${walkthrough.notes}` : ''}

Identify the following with specificity and quantitative detail:
1. Materials visible (flooring type, wall finish, fixtures, etc.)
2. Condition issues (wear, damage, age-related deterioration)
3. Damage if any (water stains, cracks, mold, structural concerns)
4. Notable features (upgrades, custom work, special installations)
5. Approximate scope of work needed

Return ONLY valid JSON:
{
  "analysis": "Detailed multi-sentence assessment of the room condition and features",
  "issues": ["Issue 1 with specific detail", "Issue 2"],
  "materials": ["Material 1 (e.g., Hardwood flooring - oak, good condition)", "Material 2"],
  "features": ["Notable feature 1", "Notable feature 2"],
  "estimatedCondition": 3,
  "scopeItems": ["Scope item 1 (e.g., Replace damaged drywall section - approx 4x8 ft)", "Scope item 2"]
}`

      // Call Claude Vision
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
              ...imageContents,
              { type: 'text', text: prompt },
            ],
          }],
        }),
      })

      if (!claudeResponse.ok) {
        const errText = await claudeResponse.text()
        console.error(`Claude API error for room ${room.id}:`, errText)
        roomAssessments.push({
          roomId: room.id,
          roomName: room.name,
          roomType: room.type || 'unknown',
          analysis: 'AI analysis failed for this room.',
          issues: [],
          materials: [],
          conditionRating: room.condition_rating || null,
          dimensions: room.dimensions || null,
          photoCount: roomPhotos.length,
        })
        continue
      }

      const claudeResult = await claudeResponse.json()
      totalInputTokens += claudeResult.usage?.input_tokens || 0
      totalOutputTokens += claudeResult.usage?.output_tokens || 0

      const responseText = claudeResult.content?.[0]?.text || ''

      // Parse Claude's JSON response
      let roomAnalysis: Record<string, unknown> = {}
      try {
        const jsonMatch = responseText.match(/\{[\s\S]*\}/)
        if (!jsonMatch) throw new Error('No JSON in response')
        roomAnalysis = JSON.parse(jsonMatch[0])
      } catch {
        roomAnalysis = {
          analysis: responseText.substring(0, 1000),
          issues: [],
          materials: [],
          scopeItems: [],
        }
      }

      // Save AI analysis to each photo record
      const aiAnalysisData = {
        roomAnalysis: roomAnalysis,
        analyzedAt: new Date().toISOString(),
        model: 'claude-sonnet-4-5-20250929',
      }

      for (const photo of roomPhotos.slice(0, 8)) {
        await supabase
          .from('walkthrough_photos')
          .update({ ai_analysis: aiAnalysisData })
          .eq('id', photo.id)
      }

      roomAssessments.push({
        roomId: room.id,
        roomName: room.name,
        roomType: room.type || 'unknown',
        analysis: String(roomAnalysis.analysis || ''),
        issues: (roomAnalysis.issues as string[]) || [],
        materials: (roomAnalysis.materials as string[]) || [],
        conditionRating: (roomAnalysis.estimatedCondition as number) || room.condition_rating || null,
        dimensions: room.dimensions || null,
        photoCount: roomPhotos.length,
      })
    }

    // Generate overall property assessment using all room analyses
    const allIssues = roomAssessments.flatMap(r => r.issues)
    const allMaterials = roomAssessments.flatMap(r => r.materials)
    const allScopes = roomAssessments.flatMap(r => {
      // Collect scope items from raw analysis data
      return r.issues // fallback — real scope items come from the overall prompt below
    })

    const overallPrompt = `You are a professional property assessor. Based on the following room-by-room analysis of a property walkthrough, provide:
1. A concise overall property assessment (2-3 sentences)
2. A prioritized list of estimated scope items for the entire property

PROPERTY: ${walkthrough.address || 'Unknown'}
TYPE: ${walkthrough.type || 'general'}
WEATHER CONDITIONS: ${walkthrough.weather || 'Not noted'}
NOTES: ${walkthrough.notes || 'None'}

ROOM ASSESSMENTS:
${roomAssessments.map(r => `
--- ${r.roomName} (${r.roomType}) ---
Analysis: ${r.analysis}
Issues: ${r.issues.join('; ') || 'None'}
Materials: ${r.materials.join('; ') || 'Not identified'}
Condition: ${r.conditionRating || 'Not rated'}/5
`).join('\n')}

Return ONLY valid JSON:
{
  "overallAssessment": "Concise 2-3 sentence property assessment",
  "estimatedScope": ["Prioritized scope item 1", "Scope item 2", "..."],
  "priorityLevel": "low|medium|high|urgent",
  "estimatedComplexity": "simple|moderate|complex"
}`

    const overallResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 2048,
        messages: [{ role: 'user', content: overallPrompt }],
      }),
    })

    let overallAssessment = 'Unable to generate overall assessment.'
    let estimatedScope: string[] = []

    if (overallResponse.ok) {
      const overallResult = await overallResponse.json()
      totalInputTokens += overallResult.usage?.input_tokens || 0
      totalOutputTokens += overallResult.usage?.output_tokens || 0

      const overallText = overallResult.content?.[0]?.text || ''
      try {
        const jsonMatch = overallText.match(/\{[\s\S]*\}/)
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0])
          overallAssessment = parsed.overallAssessment || overallAssessment
          estimatedScope = parsed.estimatedScope || []
        }
      } catch {
        overallAssessment = overallText.substring(0, 1000)
      }
    }

    // Update walkthrough status
    await supabase
      .from('walkthroughs')
      .update({ status: 'analyzed' })
      .eq('id', walkthrough_id)

    const result: AnalyzeResult = {
      roomAssessments,
      overallAssessment,
      estimatedScope,
      tokenUsage: {
        input: totalInputTokens,
        output: totalOutputTokens,
      },
    }

    return new Response(JSON.stringify({ success: true, ...result }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Walkthrough analyze error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
