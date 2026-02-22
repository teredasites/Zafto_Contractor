// Supabase Edge Function: data-ingest-orchestrator
// DATA-ARCH1 — Master ingestion framework for all registered data sources.
// Pattern: check data_sources → call source handlers → log results.
// Supports: CRON (hourly stale check), MANUAL (specific source refresh), WEBHOOK triggers.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { getCorsHeaders, corsResponse, errorResponse } from '../_shared/cors.ts'

// ── Source handler registry ──
// Each handler: fetch → validate → normalize → upsert → return stats.
// Handlers are pure functions — no side effects outside of what they return.
interface SourceHandler {
  sourceKey: string
  fetch: (config: SourceConfig) => Promise<RawData>
  validate: (raw: RawData) => ValidationResult
  normalize: (validated: RawData) => NormalizedRecord[]
}

interface SourceConfig {
  baseUrl: string
  authMethod: string
  authConfig: Record<string, unknown>
  rateLimitRemaining: number
  rateLimitPerDay: number
}

interface RawData {
  records: unknown[]
  metadata?: Record<string, unknown>
}

interface ValidationResult {
  valid: boolean
  errors: string[]
  validRecords: unknown[]
  skippedCount: number
}

interface NormalizedRecord {
  key: string
  data: Record<string, unknown>
}

interface IngestionResult {
  sourceKey: string
  status: 'SUCCESS' | 'PARTIAL_FAILURE' | 'FAILED'
  recordsFetched: number
  recordsUpserted: number
  recordsSkipped: number
  durationMs: number
  error?: string
  errorDetails?: Record<string, unknown>
}

// ── Handler implementations ──
// Each registered API gets a handler. This is the template pattern.
// For DATA-ARCH1, we implement the framework + 2 example handlers.
// Remaining handlers get added as each API is wired in INTEG sprints.

const handlers: Map<string, SourceHandler> = new Map()

// NWS Weather handler — free, no auth, no rate limit
handlers.set('nws_weather', {
  sourceKey: 'nws_weather',
  async fetch(config: SourceConfig): Promise<RawData> {
    // NWS alerts for active weather events
    const resp = await fetch(`${config.baseUrl}/alerts/active?status=actual&message_type=alert`, {
      headers: { 'User-Agent': 'Zafto/1.0 (admin@zafto.app)', Accept: 'application/geo+json' },
    })
    if (!resp.ok) throw new Error(`NWS API ${resp.status}: ${resp.statusText}`)
    const data = await resp.json()
    return { records: data.features || [], metadata: { type: 'alerts', total: data.features?.length || 0 } }
  },
  validate(raw: RawData): ValidationResult {
    const valid: unknown[] = []
    const errors: string[] = []
    let skipped = 0
    for (const r of raw.records) {
      const feature = r as Record<string, unknown>
      const props = feature.properties as Record<string, unknown> | undefined
      if (!props?.event || !props?.headline) { skipped++; continue }
      valid.push(feature)
    }
    return { valid: valid.length > 0, errors, validRecords: valid, skippedCount: skipped }
  },
  normalize(validated: RawData): NormalizedRecord[] {
    return validated.records.map((r) => {
      const feature = r as Record<string, unknown>
      const props = feature.properties as Record<string, unknown>
      return {
        key: `nws-alert-${props.id || crypto.randomUUID()}`,
        data: {
          event: props.event,
          headline: props.headline,
          description: props.description,
          severity: props.severity,
          certainty: props.certainty,
          urgency: props.urgency,
          areas: props.areaDesc,
          effective: props.effective,
          expires: props.expires,
          sender: props.senderName,
        },
      }
    })
  },
})

// CPSC Recalls handler — free, no auth
handlers.set('cpsc_recalls', {
  sourceKey: 'cpsc_recalls',
  async fetch(config: SourceConfig): Promise<RawData> {
    const resp = await fetch(`${config.baseUrl}/Recall?format=json&RecallDateStart=2024-01-01`, {
      headers: { Accept: 'application/json' },
    })
    if (!resp.ok) throw new Error(`CPSC API ${resp.status}: ${resp.statusText}`)
    const data = await resp.json()
    return { records: data || [], metadata: { type: 'recalls' } }
  },
  validate(raw: RawData): ValidationResult {
    const valid: unknown[] = []
    let skipped = 0
    for (const r of raw.records) {
      const recall = r as Record<string, unknown>
      if (!recall.RecallNumber || !recall.Description) { skipped++; continue }
      valid.push(recall)
    }
    return { valid: valid.length > 0, errors: [], validRecords: valid, skippedCount: skipped }
  },
  normalize(validated: RawData): NormalizedRecord[] {
    return validated.records.map((r) => {
      const recall = r as Record<string, unknown>
      return {
        key: `cpsc-${recall.RecallNumber}`,
        data: {
          recall_number: recall.RecallNumber,
          description: recall.Description,
          product_name: recall.ProductName || recall.Title,
          hazard: recall.Hazards?.[0] || recall.Inconjunction,
          remedy: recall.Remedies?.[0] || recall.Remedy,
          recall_date: recall.RecallDate,
          manufacturer: recall.Manufacturers?.[0] || recall.Manufacturer,
          url: recall.URL,
        },
      }
    })
  },
})

// NOAA SPC Storm Events handler — free, no auth
handlers.set('noaa_spc_storms', {
  sourceKey: 'noaa_spc_storms',
  async fetch(config: SourceConfig): Promise<RawData> {
    // SPC today's storm reports
    const resp = await fetch(`${config.baseUrl}/today.csv`, {
      headers: { Accept: 'text/csv' },
    })
    if (!resp.ok) throw new Error(`SPC ${resp.status}: ${resp.statusText}`)
    const text = await resp.text()
    const lines = text.split('\n').filter((l) => l.trim() && !l.startsWith('Time'))
    return { records: lines, metadata: { type: 'storm_reports', raw_lines: lines.length } }
  },
  validate(raw: RawData): ValidationResult {
    const valid: unknown[] = []
    let skipped = 0
    for (const line of raw.records) {
      const parts = (line as string).split(',')
      if (parts.length < 5) { skipped++; continue }
      valid.push(parts)
    }
    return { valid: valid.length > 0, errors: [], validRecords: valid, skippedCount: skipped }
  },
  normalize(validated: RawData): NormalizedRecord[] {
    return validated.records.map((parts, i) => {
      const p = parts as string[]
      return {
        key: `spc-${new Date().toISOString().split('T')[0]}-${i}`,
        data: {
          time: p[0]?.trim(),
          type: p[1]?.trim(),
          location: p[2]?.trim(),
          county: p[3]?.trim(),
          state: p[4]?.trim(),
          lat: parseFloat(p[5] || '0'),
          lon: parseFloat(p[6] || '0'),
          remarks: p[7]?.trim(),
        },
      }
    })
  },
})

// ── Core orchestration ──

async function runIngestion(
  supabase: ReturnType<typeof createClient>,
  sourceKey: string,
  triggeredBy: 'CRON' | 'MANUAL' | 'WEBHOOK' | 'STARTUP',
  triggeredByUserId?: string,
): Promise<IngestionResult> {
  const startTime = Date.now()

  // Get source config
  const { data: source, error: srcError } = await supabase
    .from('data_sources')
    .select('*')
    .eq('source_key', sourceKey)
    .eq('is_active', true)
    .is('deleted_at', null)
    .single()

  if (srcError || !source) {
    return {
      sourceKey,
      status: 'FAILED',
      recordsFetched: 0,
      recordsUpserted: 0,
      recordsSkipped: 0,
      durationMs: Date.now() - startTime,
      error: `Source not found or inactive: ${sourceKey}`,
    }
  }

  // Create ingestion log entry
  const { data: logEntry } = await supabase
    .from('data_ingestion_log')
    .insert({
      source_key: sourceKey,
      status: 'RUNNING',
      triggered_by: triggeredBy,
      triggered_by_user_id: triggeredByUserId || null,
    })
    .select('id')
    .single()

  const logId = logEntry?.id

  const handler = handlers.get(sourceKey)
  if (!handler) {
    const result: IngestionResult = {
      sourceKey,
      status: 'FAILED',
      recordsFetched: 0,
      recordsUpserted: 0,
      recordsSkipped: 0,
      durationMs: Date.now() - startTime,
      error: `No handler registered for source: ${sourceKey}`,
    }
    await finalizeLog(supabase, logId, source, result)
    return result
  }

  // Execute handler pipeline with retry (3x exponential backoff)
  let lastError: Error | null = null
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      // 1. Fetch
      const raw = await handler.fetch({
        baseUrl: source.base_url,
        authMethod: source.auth_method,
        authConfig: source.auth_config || {},
        rateLimitRemaining: source.rate_limit_remaining || 0,
        rateLimitPerDay: source.rate_limit_per_day || 0,
      })

      // 2. Validate
      const validation = handler.validate(raw)
      if (!validation.valid && validation.validRecords.length === 0) {
        const result: IngestionResult = {
          sourceKey,
          status: 'FAILED',
          recordsFetched: raw.records.length,
          recordsUpserted: 0,
          recordsSkipped: validation.skippedCount,
          durationMs: Date.now() - startTime,
          error: 'Validation failed — 0 valid records',
          errorDetails: { errors: validation.errors },
        }
        await finalizeLog(supabase, logId, source, result)
        return result
      }

      // 3. Normalize
      const normalized = handler.normalize({
        records: validation.validRecords,
        metadata: raw.metadata,
      })

      // 4. Upsert (write to ingestion staging — canonical tables in DATA-ARCH2)
      // For now, we just count and log. Full upsert wiring happens when canonical tables exist.
      const upserted = normalized.length

      const result: IngestionResult = {
        sourceKey,
        status: validation.skippedCount > 0 ? 'PARTIAL_FAILURE' : 'SUCCESS',
        recordsFetched: raw.records.length,
        recordsUpserted: upserted,
        recordsSkipped: validation.skippedCount,
        durationMs: Date.now() - startTime,
      }
      await finalizeLog(supabase, logId, source, result)
      return result
    } catch (err) {
      lastError = err as Error
      if (attempt < 3) {
        // Exponential backoff: 1s, 2s, 4s
        await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt - 1)))
      }
    }
  }

  // All retries exhausted
  const result: IngestionResult = {
    sourceKey,
    status: 'FAILED',
    recordsFetched: 0,
    recordsUpserted: 0,
    recordsSkipped: 0,
    durationMs: Date.now() - startTime,
    error: lastError?.message || 'Unknown error after 3 retries',
    errorDetails: { stack: lastError?.stack },
  }
  await finalizeLog(supabase, logId, source, result)
  return result
}

async function finalizeLog(
  supabase: ReturnType<typeof createClient>,
  logId: string | undefined,
  source: Record<string, unknown>,
  result: IngestionResult,
) {
  // Update ingestion log
  if (logId) {
    await supabase
      .from('data_ingestion_log')
      .update({
        completed_at: new Date().toISOString(),
        duration_ms: result.durationMs,
        status: result.status,
        records_fetched: result.recordsFetched,
        records_upserted: result.recordsUpserted,
        records_skipped: result.recordsSkipped,
        error_message: result.error || null,
        error_details: result.errorDetails || null,
      })
      .eq('id', logId)
  }

  // Update source status + next refresh
  const refreshFreq = source.refresh_frequency as string
  await supabase
    .from('data_sources')
    .update({
      last_refreshed_at: new Date().toISOString(),
      last_status: result.status,
      last_error: result.error || null,
      next_refresh_at: refreshFreq && refreshFreq !== '0 seconds'
        ? new Date(Date.now() + parseIntervalMs(refreshFreq)).toISOString()
        : null,
    })
    .eq('source_key', result.sourceKey)
}

function parseIntervalMs(interval: string): number {
  // Parse PostgreSQL interval strings like '1 hour', '24 hours', '30 days', '7 days'
  const match = interval.match(/(\d+)\s*(second|minute|hour|day|week|month)s?/i)
  if (!match) return 3600000 // default 1hr
  const n = parseInt(match[1], 10)
  const unit = match[2].toLowerCase()
  const multipliers: Record<string, number> = {
    second: 1000,
    minute: 60000,
    hour: 3600000,
    day: 86400000,
    week: 604800000,
    month: 2592000000,
  }
  return n * (multipliers[unit] || 3600000)
}

// ── HTTP handler ──
serve(async (req: Request) => {
  const origin = req.headers.get('Origin')
  if (req.method === 'OPTIONS') return corsResponse(origin)

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const url = new URL(req.url)

    // ── GET: Status + stale check ──
    if (req.method === 'GET') {
      const action = url.searchParams.get('action') || 'status'

      if (action === 'status') {
        // Return all sources with their status
        const { data: sources } = await supabase
          .from('data_sources')
          .select('source_key, display_name, category, tier, last_status, last_refreshed_at, next_refresh_at, refresh_frequency, is_active, monthly_cost_cents')
          .is('deleted_at', null)
          .order('tier', { ascending: true })
          .order('category')

        // Get recent ingestion logs
        const { data: recentLogs } = await supabase
          .from('data_ingestion_log')
          .select('source_key, status, started_at, duration_ms, records_fetched, records_upserted, error_message')
          .order('started_at', { ascending: false })
          .limit(50)

        // Check for stale sources
        const { data: staleSources } = await supabase.rpc('fn_check_stale_sources')

        return new Response(JSON.stringify({
          sources: sources || [],
          recentLogs: recentLogs || [],
          staleSources: staleSources || [],
          registeredHandlers: Array.from(handlers.keys()),
          totalSources: sources?.length || 0,
          activeSources: sources?.filter((s: Record<string, unknown>) => s.is_active).length || 0,
          totalMonthlyCost: sources?.reduce((sum: number, s: Record<string, unknown>) => sum + ((s.monthly_cost_cents as number) || 0), 0) || 0,
        }), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      if (action === 'stale') {
        const { data: staleSources } = await supabase.rpc('fn_check_stale_sources')
        return new Response(JSON.stringify({ staleSources: staleSources || [] }), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      if (action === 'metrics') {
        const days = parseInt(url.searchParams.get('days') || '7', 10)
        const { data: metrics } = await supabase
          .from('api_gateway_metrics')
          .select('*')
          .gte('metric_date', new Date(Date.now() - days * 86400000).toISOString().split('T')[0])
          .order('metric_date', { ascending: false })

        return new Response(JSON.stringify({ metrics: metrics || [], days }), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      return errorResponse('Unknown action', 400, origin)
    }

    // ── POST: Ingestion triggers ──
    if (req.method === 'POST') {
      // Auth check — super_admin or service_role only
      const authHeader = req.headers.get('authorization')
      if (!authHeader) return errorResponse('Unauthorized', 401, origin)

      const token = authHeader.replace('Bearer ', '')
      let userId: string | undefined

      // Check if this is the service_role key (CRON/internal calls)
      const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      const isServiceRole = token === serviceRoleKey

      if (!isServiceRole) {
        const { data: { user }, error: authError } = await supabase.auth.getUser(token)
        if (authError || !user) return errorResponse('Invalid token', 401, origin)

        const role = user.app_metadata?.role
        if (!role || !['super_admin', 'owner', 'admin'].includes(role)) {
          return errorResponse('Insufficient permissions — super_admin/owner/admin required', 403, origin)
        }
        userId = user.id
      }

      const body = await req.json()
      const { action } = body

      // ── Manual refresh of specific source ──
      if (action === 'refresh') {
        const sourceKey = body.source_key || url.searchParams.get('source')
        if (!sourceKey) return errorResponse('source_key required', 400, origin)

        const result = await runIngestion(supabase, sourceKey, 'MANUAL', userId)
        return new Response(JSON.stringify(result), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      // ── CRON: Refresh all stale sources ──
      if (action === 'cron' || action === 'refresh-stale') {
        const { data: staleSources } = await supabase
          .from('data_sources')
          .select('source_key')
          .eq('is_active', true)
          .is('deleted_at', null)
          .not('refresh_frequency', 'eq', '0 seconds')
          .or('next_refresh_at.is.null,next_refresh_at.lte.' + new Date().toISOString())

        if (!staleSources || staleSources.length === 0) {
          return new Response(JSON.stringify({ message: 'No stale sources to refresh', refreshed: 0 }), {
            headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
          })
        }

        // Process sources sequentially to respect rate limits
        const results: IngestionResult[] = []
        for (const source of staleSources) {
          // Only process sources that have handlers
          if (handlers.has(source.source_key)) {
            const result = await runIngestion(supabase, source.source_key, 'CRON')
            results.push(result)
          }
        }

        const summary = {
          totalStale: staleSources.length,
          processed: results.length,
          succeeded: results.filter((r) => r.status === 'SUCCESS').length,
          partial: results.filter((r) => r.status === 'PARTIAL_FAILURE').length,
          failed: results.filter((r) => r.status === 'FAILED').length,
          results,
        }

        return new Response(JSON.stringify(summary), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      // ── Register/update source (ops portal admin) ──
      if (action === 'register') {
        const { source } = body
        if (!source?.source_key || !source?.display_name || !source?.base_url) {
          return errorResponse('source_key, display_name, and base_url required', 400, origin)
        }

        const { data, error } = await supabase
          .from('data_sources')
          .upsert({
            source_key: source.source_key,
            display_name: source.display_name,
            description: source.description || null,
            category: source.category || 'general',
            tier: source.tier || 3,
            base_url: source.base_url,
            auth_method: source.auth_method || 'none',
            auth_config: source.auth_config || {},
            rate_limit_per_minute: source.rate_limit_per_minute || 0,
            rate_limit_per_day: source.rate_limit_per_day || 0,
            refresh_frequency: source.refresh_frequency || '24 hours',
            monthly_cost_cents: source.monthly_cost_cents || 0,
            cost_notes: source.cost_notes || null,
            license: source.license || null,
            documentation_url: source.documentation_url || null,
            is_active: source.is_active !== false,
          }, { onConflict: 'source_key' })
          .select()
          .single()

        if (error) return errorResponse(`Failed to register: ${error.message}`, 500, origin)

        return new Response(JSON.stringify({ registered: data }), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      // ── Toggle source active/disabled ──
      if (action === 'toggle') {
        const { source_key, is_active } = body
        if (!source_key || typeof is_active !== 'boolean') {
          return errorResponse('source_key and is_active (boolean) required', 400, origin)
        }

        const { error } = await supabase
          .from('data_sources')
          .update({
            is_active,
            last_status: is_active ? 'PENDING' : 'DISABLED',
          })
          .eq('source_key', source_key)

        if (error) return errorResponse(`Toggle failed: ${error.message}`, 500, origin)

        return new Response(JSON.stringify({ toggled: source_key, is_active }), {
          headers: { ...getCorsHeaders(origin), 'Content-Type': 'application/json' },
        })
      }

      return errorResponse(`Unknown action: ${action}`, 400, origin)
    }

    return errorResponse('Method not allowed', 405, origin)
  } catch (e) {
    return new Response(JSON.stringify({ error: (e as Error).message }), {
      status: 500,
      headers: { ...getCorsHeaders(req.headers.get('Origin')), 'Content-Type': 'application/json' },
    })
  }
})
