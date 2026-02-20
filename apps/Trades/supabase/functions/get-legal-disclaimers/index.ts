import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

/**
 * get-legal-disclaimers — Returns legal disclaimers by category or key.
 * LEGAL-1: Foundation layer for all legal defense text across the platform.
 *
 * GET ?category=calculator — returns all disclaimers for a category
 * GET ?key=nec_code_ref — returns a single disclaimer by key
 * GET (no params) — returns all disclaimers
 *
 * Response is Cache-Control: public, max-age=3600 (disclaimers change rarely).
 */

serve(async (req: Request) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') {
    return corsResponse(origin)
  }

  if (req.method !== 'GET') {
    return errorResponse('Method not allowed', 405, origin)
  }

  try {
    const url = new URL(req.url)
    const category = url.searchParams.get('category')
    const key = url.searchParams.get('key')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    let query = supabase
      .from('legal_disclaimers')
      .select('id, key, category, short_text, long_text, display_context')

    if (key) {
      query = query.eq('key', key).single()
    } else if (category) {
      query = query.eq('category', category)
    }

    const { data, error } = await query

    if (error) {
      return errorResponse(error.message, 400, origin)
    }

    return new Response(
      JSON.stringify({ data }),
      {
        status: 200,
        headers: {
          ...getCorsHeaders(origin),
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600',
        },
      }
    )
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Internal server error'
    return errorResponse(message, 500, origin)
  }
})
