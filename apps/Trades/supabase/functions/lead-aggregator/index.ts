// Supabase Edge Function: lead-aggregator
// Unified lead ingestion from multiple sources
// Actions: ingest, sync_source, list_sources, configure_source, get_analytics, auto_assign

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limiter.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // Auth check — lead aggregator requires authenticated company user
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
  const companyId = user.app_metadata?.company_id

  // Rate limit: 10 requests per minute per company
  if (companyId) {
    const rateCheck = await checkRateLimit(supabase, {
      key: `company:${companyId}:lead-aggregator`,
      maxRequests: 10,
      windowSeconds: 60,
    })
    if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)
  }

  try {
    const body = await req.json()
    const { action } = body

    switch (action) {
      case 'ingest':
        return await handleIngest(supabase, body)
      case 'sync_source':
        return await handleSyncSource(supabase, body)
      case 'list_sources':
        return await handleListSources(supabase, body)
      case 'configure_source':
        return await handleConfigureSource(supabase, body)
      case 'get_analytics':
        return await handleGetAnalytics(supabase, body)
      case 'auto_assign':
        return await handleAutoAssign(supabase, body)
      case 'webhook':
        return await handleWebhook(supabase, body)
      default:
        return new Response(JSON.stringify({ error: 'Invalid action' }), {
          status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
    }
  } catch (err) {
    console.error('lead-aggregator error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// Ingest a lead from any source into the normalized leads table
async function handleIngest(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const {
    companyId, source, name, email, phone, companyName,
    address, city, state, zipCode, trade, urgency, value,
    notes, externalId, externalSourceData, createdByUserId,
  } = body as {
    companyId: string; source: string; name: string;
    email?: string; phone?: string; companyName?: string;
    address?: string; city?: string; state?: string; zipCode?: string;
    trade?: string; urgency?: string; value?: number;
    notes?: string; externalId?: string; externalSourceData?: Record<string, unknown>;
    createdByUserId: string;
  }

  if (!companyId || !source || !name || !createdByUserId) {
    return new Response(JSON.stringify({ error: 'companyId, source, name, createdByUserId required' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Check for duplicate via external_id
  if (externalId) {
    const { data: existing } = await supabase
      .from('leads')
      .select('id')
      .eq('company_id', companyId)
      .eq('external_id', externalId)
      .maybeSingle()

    if (existing) {
      return new Response(JSON.stringify({ lead: existing, duplicate: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  }

  // Insert lead
  const { data: lead, error } = await supabase
    .from('leads')
    .insert({
      company_id: companyId,
      created_by_user_id: createdByUserId,
      source,
      name,
      email: email || null,
      phone: phone || null,
      company_name: companyName || null,
      address: address || null,
      city: city || null,
      state: state || null,
      zip_code: zipCode || null,
      trade: trade || null,
      urgency: urgency || 'normal',
      value: value || 0,
      notes: notes || null,
      external_id: externalId || null,
      external_source_data: externalSourceData || {},
      stage: 'new',
    })
    .select()
    .single()

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Log analytics event
  await supabase.from('lead_analytics_events').insert({
    company_id: companyId,
    lead_id: lead.id,
    event_type: 'received',
    source,
    metadata: { external_id: externalId, trade, urgency },
  })

  // Try auto-assign
  await tryAutoAssign(supabase, companyId, lead)

  return new Response(JSON.stringify({ lead, duplicate: false }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Auto-assign lead based on rules
async function tryAutoAssign(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  lead: Record<string, unknown>,
) {
  const { data: rules } = await supabase
    .from('lead_assignment_rules')
    .select('*')
    .eq('company_id', companyId)
    .eq('is_active', true)
    .order('priority', { ascending: false })

  if (!rules || rules.length === 0) return

  for (const rule of rules) {
    if (!matchesRule(rule, lead)) continue

    let assignTo: string | null = null

    if (rule.assign_to_user_id) {
      assignTo = rule.assign_to_user_id
    } else if (rule.assign_to_round_robin && rule.round_robin_user_ids?.length > 0) {
      // Simple round robin — pick next user
      const userIds = rule.round_robin_user_ids as string[]
      const { count } = await supabase
        .from('leads')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', companyId)
        .eq('auto_assigned', true)

      const idx = ((count || 0) % userIds.length)
      assignTo = userIds[idx]
    }

    if (assignTo) {
      await supabase
        .from('leads')
        .update({
          assigned_to_user_id: assignTo,
          auto_assigned: true,
          stage: rule.set_stage || 'new',
        })
        .eq('id', lead.id as string)

      // Send notification if configured
      if (rule.send_notification) {
        const channels = (rule.notification_channels as string[]) || ['push', 'email']
        for (const channel of channels) {
          await supabase.from('lead_notifications').insert({
            company_id: companyId,
            lead_id: lead.id as string,
            user_id: assignTo,
            channel,
            status: 'sent',
          })
        }
      }

      // Speed-to-Lead Auto-Response
      if (rule.auto_respond) {
        const contactName = (lead.contact_name as string) || 'there'
        const firstName = contactName.split(' ')[0]

        // Fetch company name for the auto-response template
        const { data: company } = await supabase
          .from('companies')
          .select('company_name')
          .eq('id', companyId)
          .single()
        const companyName = company?.company_name || 'our team'

        const autoMessage = `Hi ${firstName}, thanks for contacting ${companyName}! We received your request and will reach out within 15 minutes.`

        // Record auto-response SMS (actual sending via SignalWire when configured)
        if (lead.phone) {
          await supabase.from('phone_messages').insert({
            company_id: companyId,
            customer_id: null,
            lead_id: lead.id as string,
            direction: 'outbound',
            from_number: 'auto',
            to_number: lead.phone as string,
            body: autoMessage,
            status: 'queued',
          }).then(() => {}).catch(() => {})
        }

        // Record auto-response email (actual sending via SendGrid when configured)
        if (lead.email) {
          await supabase.from('emails').insert({
            company_id: companyId,
            customer_id: null,
            lead_id: lead.id as string,
            direction: 'outbound',
            to_address: lead.email as string,
            subject: `Thanks for reaching out to ${companyName}`,
            body: autoMessage,
            status: 'queued',
          }).then(() => {}).catch(() => {})
        }

        // Mark instant response time
        await supabase
          .from('leads')
          .update({ response_time_minutes: 0 })
          .eq('id', lead.id as string)
      }

      break // First matching rule wins
    }
  }
}

function matchesRule(rule: Record<string, unknown>, lead: Record<string, unknown>): boolean {
  // Source filter
  if (rule.condition_source && (rule.condition_source as string[]).length > 0) {
    if (!(rule.condition_source as string[]).includes(lead.source as string)) return false
  }
  // Trade filter
  if (rule.condition_trade && (rule.condition_trade as string[]).length > 0) {
    if (!lead.trade || !(rule.condition_trade as string[]).includes(lead.trade as string)) return false
  }
  // Zip code filter
  if (rule.condition_zip_codes && (rule.condition_zip_codes as string[]).length > 0) {
    if (!lead.zip_code || !(rule.condition_zip_codes as string[]).includes(lead.zip_code as string)) return false
  }
  // Value range
  if (rule.condition_value_min != null && (lead.value as number) < (rule.condition_value_min as number)) return false
  if (rule.condition_value_max != null && (lead.value as number) > (rule.condition_value_max as number)) return false

  return true
}

// Sync a specific lead source
async function handleSyncSource(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, source } = body as { companyId: string; source: string }

  // Get source config
  const { data: config, error: configError } = await supabase
    .from('lead_source_configs')
    .select('*')
    .eq('company_id', companyId)
    .eq('source', source)
    .single()

  if (configError || !config) {
    return new Response(JSON.stringify({ error: 'Source not configured' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Source-specific sync logic
  let syncResult: { leads: number; errors: number } = { leads: 0, errors: 0 }

  switch (source) {
    case 'google_business':
      syncResult = await syncGoogleBusiness(supabase, companyId, config)
      break
    case 'yelp':
      syncResult = await syncYelp(supabase, companyId, config)
      break
    case 'google_lsa':
      syncResult = await syncGoogleLSA(supabase, companyId, config)
      break
    default:
      // Generic webhook-based sources don't need active sync
      syncResult = { leads: 0, errors: 0 }
  }

  // Update last synced
  await supabase
    .from('lead_source_configs')
    .update({ last_synced_at: new Date().toISOString() })
    .eq('id', config.id)

  return new Response(JSON.stringify({ success: true, ...syncResult }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Google Business Profile leads sync
async function syncGoogleBusiness(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  config: Record<string, unknown>,
): Promise<{ leads: number; errors: number }> {
  // Google Business Profile API requires OAuth2 — would use stored refresh token
  // For now, return placeholder. Actual implementation requires:
  // 1. accounts/{accountId}/locations/{locationId}/reviews (for review-based leads)
  // 2. accounts/{accountId}/locations/{locationId}/localPosts (for messaging leads)
  // The API is free but requires Business Profile API access
  console.log('Google Business sync for company:', companyId, 'config:', config.config)
  return { leads: 0, errors: 0 }
}

// Yelp Fusion API sync
async function syncYelp(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  config: Record<string, unknown>,
): Promise<{ leads: number; errors: number }> {
  // Yelp Fusion API — pull leads from Yelp Request a Quote
  // Requires Yelp Fusion API key (free tier: 5000 calls/day)
  const apiKey = config.api_key_encrypted as string
  if (!apiKey) return { leads: 0, errors: 0 }

  try {
    // Yelp doesn't have a direct "leads" endpoint in public API
    // Leads come via webhooks from Yelp for Business
    // This sync checks for new reviews (which indicate potential leads)
    const businessId = (config.config as Record<string, unknown>)?.business_id as string
    if (!businessId) return { leads: 0, errors: 0 }

    const res = await fetch(`https://api.yelp.com/v3/businesses/${businessId}/reviews?sort_by=newest&limit=10`, {
      headers: { 'Authorization': `Bearer ${apiKey}` },
    })

    if (!res.ok) return { leads: 0, errors: 1 }
    const data = await res.json()
    console.log('Yelp reviews fetched:', (data.reviews || []).length, 'for company:', companyId)

    // Reviews don't directly map to leads but high-rated reviews indicate engagement
    return { leads: 0, errors: 0 }
  } catch {
    return { leads: 0, errors: 1 }
  }
}

// Google LSA (Local Service Ads) sync
async function syncGoogleLSA(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  config: Record<string, unknown>,
): Promise<{ leads: number; errors: number }> {
  // Google LSA API requires Google Ads API access
  // Leads come through the Local Services API
  console.log('Google LSA sync for company:', companyId, 'config:', config.config)
  return { leads: 0, errors: 0 }
}

// Handle webhook-based lead sources (Facebook, Nextdoor, etc.)
async function handleWebhook(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, source, webhookData } = body as {
    companyId: string; source: string; webhookData: Record<string, unknown>
  }

  // Normalize webhook data into lead format based on source
  let normalized: Record<string, unknown> | null = null

  switch (source) {
    case 'meta_business':
      normalized = normalizeMetaLead(webhookData)
      break
    case 'angi':
      normalized = normalizeAngiLead(webhookData)
      break
    case 'thumbtack':
      normalized = normalizeThumbTackLead(webhookData)
      break
    case 'nextdoor':
      normalized = normalizeNextdoorLead(webhookData)
      break
    default:
      normalized = normalizeGenericLead(webhookData)
  }

  if (!normalized) {
    return new Response(JSON.stringify({ error: 'Could not normalize webhook data' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Get a system user for the company to use as creator
  const { data: admin } = await supabase
    .from('users')
    .select('id')
    .eq('company_id', companyId)
    .eq('role', 'owner')
    .limit(1)
    .single()

  const createdByUserId = admin?.id || companyId // fallback

  // Ingest through normal flow
  const ingestBody = {
    action: 'ingest',
    companyId,
    source,
    createdByUserId,
    ...normalized,
    externalSourceData: webhookData,
  }

  return await handleIngest(supabase, ingestBody)
}

// Meta Business (Facebook/Instagram) lead normalization
function normalizeMetaLead(data: Record<string, unknown>): Record<string, unknown> | null {
  // Facebook Lead Ads webhook format
  const leadData = data.lead_data as Record<string, unknown> || data
  return {
    name: leadData.full_name || leadData.name || 'Facebook Lead',
    email: leadData.email,
    phone: leadData.phone_number || leadData.phone,
    notes: leadData.ad_name ? `From ad: ${leadData.ad_name}` : undefined,
    externalId: `meta_${leadData.lead_id || leadData.id || Date.now()}`,
  }
}

// Angi (Angie's List) lead normalization
function normalizeAngiLead(data: Record<string, unknown>): Record<string, unknown> | null {
  return {
    name: data.customer_name || data.name || 'Angi Lead',
    email: data.customer_email || data.email,
    phone: data.customer_phone || data.phone,
    address: data.address,
    city: data.city,
    state: data.state,
    zipCode: data.zip_code || data.zipCode,
    trade: data.category || data.service_type,
    notes: data.description || data.project_description,
    externalId: `angi_${data.lead_id || data.id || Date.now()}`,
  }
}

// Thumbtack lead normalization
function normalizeThumbTackLead(data: Record<string, unknown>): Record<string, unknown> | null {
  return {
    name: data.customer_name || data.name || 'Thumbtack Lead',
    email: data.customer_email || data.email,
    phone: data.customer_phone || data.phone,
    address: data.location?.toString(),
    zipCode: data.zip_code || data.zipCode,
    trade: data.category || data.request_type,
    notes: data.details || data.description,
    urgency: data.urgency === 'asap' ? 'high' : 'normal',
    externalId: `tt_${data.request_id || data.id || Date.now()}`,
  }
}

// Nextdoor lead normalization
function normalizeNextdoorLead(data: Record<string, unknown>): Record<string, unknown> | null {
  return {
    name: data.name || data.author_name || 'Nextdoor Lead',
    notes: data.body || data.message || data.content,
    externalId: `nd_${data.post_id || data.id || Date.now()}`,
  }
}

// Generic webhook normalization
function normalizeGenericLead(data: Record<string, unknown>): Record<string, unknown> | null {
  return {
    name: (data.name || data.customer_name || data.full_name || 'Unknown Lead') as string,
    email: data.email || data.customer_email,
    phone: data.phone || data.customer_phone || data.phone_number,
    address: data.address,
    city: data.city,
    state: data.state,
    zipCode: data.zip_code || data.zipCode || data.zip,
    notes: data.notes || data.description || data.message,
    externalId: `gen_${data.id || Date.now()}`,
  }
}

// List configured sources for a company
async function handleListSources(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId } = body as { companyId: string }

  const { data, error } = await supabase
    .from('lead_source_configs')
    .select('id, source, display_name, is_active, last_synced_at, stats')
    .eq('company_id', companyId)
    .order('display_name')

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ sources: data || [] }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Configure a lead source
async function handleConfigureSource(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, source, displayName, apiKey, apiSecret, config: sourceConfig, isActive } = body as {
    companyId: string; source: string; displayName: string;
    apiKey?: string; apiSecret?: string; config?: Record<string, unknown>;
    isActive?: boolean;
  }

  const { data, error } = await supabase
    .from('lead_source_configs')
    .upsert({
      company_id: companyId,
      source,
      display_name: displayName,
      api_key_encrypted: apiKey || null,
      api_secret_encrypted: apiSecret || null,
      config: sourceConfig || {},
      is_active: isActive ?? true,
    }, { onConflict: 'company_id,source' })
    .select()
    .single()

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  return new Response(JSON.stringify({ source: data }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Get lead analytics for a company
async function handleGetAnalytics(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, days = 30 } = body as { companyId: string; days?: number }

  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString()

  // Get events breakdown
  const { data: events } = await supabase
    .from('lead_analytics_events')
    .select('event_type, source')
    .eq('company_id', companyId)
    .gte('created_at', since)

  // Get leads by source
  const { data: leadsBySource } = await supabase
    .from('leads')
    .select('source, stage')
    .eq('company_id', companyId)
    .gte('created_at', since)

  // Compute analytics
  const sourceStats: Record<string, { total: number; won: number; lost: number; active: number }> = {}
  for (const lead of (leadsBySource || [])) {
    const src = lead.source || 'unknown'
    if (!sourceStats[src]) sourceStats[src] = { total: 0, won: 0, lost: 0, active: 0 }
    sourceStats[src].total++
    if (lead.stage === 'won') sourceStats[src].won++
    else if (lead.stage === 'lost') sourceStats[src].lost++
    else sourceStats[src].active++
  }

  const eventBreakdown: Record<string, number> = {}
  for (const evt of (events || [])) {
    eventBreakdown[evt.event_type] = (eventBreakdown[evt.event_type] || 0) + 1
  }

  return new Response(JSON.stringify({
    period: { days, since },
    sourceStats,
    eventBreakdown,
    totalLeads: (leadsBySource || []).length,
    conversionRate: (() => {
      const total = (leadsBySource || []).length
      const won = (leadsBySource || []).filter(l => l.stage === 'won').length
      return total > 0 ? Math.round((won / total) * 100) : 0
    })(),
  }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// Manual auto-assign trigger
async function handleAutoAssign(
  supabase: ReturnType<typeof createClient>,
  body: Record<string, unknown>,
) {
  const { companyId, leadId } = body as { companyId: string; leadId: string }

  const { data: lead, error } = await supabase
    .from('leads')
    .select('*')
    .eq('id', leadId)
    .eq('company_id', companyId)
    .single()

  if (error || !lead) {
    return new Response(JSON.stringify({ error: 'Lead not found' }), {
      status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  await tryAutoAssign(supabase, companyId, lead)

  // Re-fetch to get updated assignment
  const { data: updated } = await supabase
    .from('leads')
    .select('*')
    .eq('id', leadId)
    .single()

  return new Response(JSON.stringify({ lead: updated }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
