/**
 * Shared CORS headers for Edge Functions.
 * SEC-AUDIT-4: Origin allowlist replaces wildcard '*'.
 * Uses ALLOWED_ORIGINS env var or defaults to Zafto domains + localhost.
 */

const DEFAULT_ORIGINS = 'https://zafto.cloud,https://team.zafto.cloud,https://client.zafto.cloud,https://ops.zafto.cloud,https://realtor.zafto.cloud,http://localhost:3000,http://localhost:3001,http://localhost:3002,http://localhost:3003,http://localhost:3004'

function getAllowedOrigins(): string[] {
  const envOrigins = Deno.env.get('ALLOWED_ORIGINS')
  return (envOrigins || DEFAULT_ORIGINS).split(',').map(s => s.trim()).filter(Boolean)
}

/**
 * Get CORS headers with origin validation.
 * Reflects the request origin if it's in the allowlist.
 * If no origin header (server-to-server), allows the first listed origin.
 */
export function getCorsHeaders(origin?: string | null): Record<string, string> {
  const allowed = getAllowedOrigins()
  const effectiveOrigin = origin && allowed.includes(origin) ? origin : allowed[0]

  return {
    'Access-Control-Allow-Origin': effectiveOrigin,
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Vary': 'Origin',
  }
}

/**
 * Backward-compatible static export.
 * Uses first allowed origin instead of wildcard.
 * For proper per-request CORS, use getCorsHeaders(req.headers.get('Origin')).
 */
export const corsHeaders = getCorsHeaders()

/**
 * Handle CORS preflight request. Use at the top of every Edge Function:
 * ```ts
 * if (req.method === 'OPTIONS') return corsResponse(req.headers.get('Origin'))
 * ```
 */
export function corsResponse(origin?: string | null): Response {
  return new Response('ok', { headers: getCorsHeaders(origin) })
}

/**
 * Create a JSON error response with CORS headers.
 */
export function errorResponse(message: string, status: number, origin?: string | null): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
    }
  )
}
