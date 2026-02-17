/**
 * Shared CORS headers for Edge Functions.
 * Centralized to prevent inconsistencies across functions.
 */

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Handle CORS preflight request. Use at the top of every Edge Function:
 * ```ts
 * if (req.method === 'OPTIONS') return corsResponse()
 * ```
 */
export function corsResponse(): Response {
  return new Response('ok', { headers: corsHeaders })
}

/**
 * Create a JSON error response with CORS headers.
 */
export function errorResponse(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  )
}
