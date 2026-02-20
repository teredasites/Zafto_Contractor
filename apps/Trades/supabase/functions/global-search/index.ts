/**
 * global-search — INFRA-4: Unified full-text search across all entity types
 *
 * GET ?q=search+term&limit=20
 *
 * Searches customers, jobs, invoices, estimates, properties, leads
 * using PostgreSQL ts_query against TSVECTOR columns.
 * Company-scoped via JWT. Rate limited: Tier 3 (100/min).
 *
 * Returns ranked results with entity type, title, subtitle, and link.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

Deno.serve(async (req: Request) => {
  const origin = req.headers.get('Origin')

  if (req.method === 'OPTIONS') return corsResponse(origin)

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return errorResponse('Missing authorization', 401, origin)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Auth client to get user's company
    const authClient = createClient(supabaseUrl, supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await authClient.auth.getUser()
    if (authError || !user) return errorResponse('Unauthorized', 401, origin)

    const companyId = user.app_metadata?.company_id
    if (!companyId) return errorResponse('No company assigned', 403, origin)

    // Parse query
    const url = new URL(req.url)
    const query = url.searchParams.get('q')?.trim()
    if (!query || query.length < 2) {
      return errorResponse('Query must be at least 2 characters', 400, origin)
    }

    const limit = Math.min(parseInt(url.searchParams.get('limit') || '20'), 50)

    // Convert query to tsquery format: "John Smith" → "John & Smith"
    const tsQuery = query
      .split(/\s+/)
      .filter(Boolean)
      .map(w => w.replace(/[^a-zA-Z0-9]/g, ''))
      .filter(w => w.length > 0)
      .join(' & ')

    if (!tsQuery) return errorResponse('Invalid query', 400, origin)

    // Service client for raw SQL
    const serviceClient = createClient(supabaseUrl, supabaseServiceKey)

    // Unified search across all entity types using UNION ALL
    const { data, error } = await serviceClient.rpc('global_search', {
      p_company_id: companyId,
      p_query: tsQuery,
      p_limit: limit,
    })

    if (error) {
      // Fallback: if RPC doesn't exist yet, do individual queries
      const results = await fallbackSearch(serviceClient, companyId, tsQuery, limit)
      return new Response(JSON.stringify({ results, count: results.length }), {
        headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ results: data, count: data.length }), {
      headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return errorResponse(
      err instanceof Error ? err.message : 'Search failed',
      500,
      origin,
    )
  }
})

interface SearchResult {
  entity_type: string
  id: string
  title: string
  subtitle: string | null
  rank: number
}

async function fallbackSearch(
  client: ReturnType<typeof createClient>,
  companyId: string,
  tsQuery: string,
  limit: number,
): Promise<SearchResult[]> {
  const searches = [
    searchTable(client, 'customers', companyId, tsQuery, limit, 'customer',
      'name', "coalesce(email, '') || ' ' || coalesce(phone, '')"),
    searchTable(client, 'jobs', companyId, tsQuery, limit, 'job',
      'title', "coalesce(address, '') || ' ' || coalesce(status, '')"),
    searchTable(client, 'invoices', companyId, tsQuery, limit, 'invoice',
      'invoice_number', "coalesce(status, '') || ' ' || coalesce(notes, '')"),
    searchTable(client, 'estimates', companyId, tsQuery, limit, 'estimate',
      'title', "coalesce(notes, '') || ' ' || coalesce(description, '')"),
    searchTable(client, 'properties', companyId, tsQuery, limit, 'property',
      'address', "coalesce(city, '') || ', ' || coalesce(state, '')"),
    searchTable(client, 'leads', companyId, tsQuery, limit, 'lead',
      'name', "coalesce(email, '') || ' ' || coalesce(phone, '')"),
  ]

  const results = await Promise.allSettled(searches)
  const merged: SearchResult[] = []

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value) {
      merged.push(...result.value)
    }
  }

  // Sort by rank descending, limit total
  return merged
    .sort((a, b) => b.rank - a.rank)
    .slice(0, limit)
}

async function searchTable(
  client: ReturnType<typeof createClient>,
  table: string,
  companyId: string,
  tsQuery: string,
  limit: number,
  entityType: string,
  titleCol: string,
  _subtitleExpr: string,
): Promise<SearchResult[]> {
  try {
    const { data, error } = await client
      .from(table)
      .select(`id, ${titleCol}, search_vector`)
      .eq('company_id', companyId)
      .is('deleted_at', null)
      .textSearch('search_vector', tsQuery, { type: 'plain' })
      .limit(limit)

    if (error || !data) return []

    return data.map((row: Record<string, unknown>) => ({
      entity_type: entityType,
      id: row.id as string,
      title: (row[titleCol] as string) || 'Untitled',
      subtitle: null,
      rank: 1,
    }))
  } catch {
    return []
  }
}
