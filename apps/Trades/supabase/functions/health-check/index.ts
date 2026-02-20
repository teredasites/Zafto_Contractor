/**
 * health-check — INFRA-5: System health endpoint
 *
 * GET — No auth required. Used by uptime monitors.
 * Returns: { status: 'ok'|'degraded', db: 'ok'|'error', timestamp }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse } from '../_shared/cors.ts'

Deno.serve(async (req: Request) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') return corsResponse(origin)

  const timestamp = new Date().toISOString()
  let dbStatus: 'ok' | 'error' = 'error'

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const client = createClient(supabaseUrl, supabaseServiceKey)

    // Simple DB connectivity check
    const { error } = await client.from('companies').select('id').limit(1)
    dbStatus = error ? 'error' : 'ok'
  } catch {
    dbStatus = 'error'
  }

  const status = dbStatus === 'ok' ? 'ok' : 'degraded'

  return new Response(
    JSON.stringify({ status, db: dbStatus, timestamp }),
    {
      status: status === 'ok' ? 200 : 503,
      headers: {
        ...getCorsHeaders(origin),
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store',
      },
    },
  )
})
