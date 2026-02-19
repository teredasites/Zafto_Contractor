// Supabase Edge Function: automation-engine
// Receives trigger events (from DB triggers via pg_net or direct calls),
// matches against enabled automations, executes actions, logs results.
//
// POST { trigger_type, company_id, event_data }
// Called by: DB triggers (pg_net), pg_cron, or direct API call

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface TriggerEvent {
  trigger_type: string
  company_id: string
  event_data: Record<string, unknown>
}

interface AutomationAction {
  type: string
  label?: string
  config: Record<string, string>
}

interface Automation {
  id: string
  company_id: string
  name: string
  trigger_type: string
  trigger_config: Record<string, unknown>
  delay_minutes: number
  actions: AutomationAction[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
  const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  const AUTOMATION_SERVICE_SECRET = Deno.env.get('AUTOMATION_SERVICE_SECRET') ?? ''
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

  // SEC-AUDIT-1: Require authentication — JWT OR shared service secret
  let companyIdFromAuth: string | null = null

  const authHeader = req.headers.get('Authorization')
  const serviceSecret = req.headers.get('x-service-secret')

  if (serviceSecret && AUTOMATION_SERVICE_SECRET && serviceSecret === AUTOMATION_SERVICE_SECRET) {
    // Internal service call (pg_net, pg_cron) — trusted, company_id from body
    companyIdFromAuth = null // will use body.company_id
  } else if (authHeader) {
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    companyIdFromAuth = user.app_metadata?.company_id || null
    if (!companyIdFromAuth) {
      return new Response(JSON.stringify({ error: 'No company associated' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
  } else {
    return new Response(JSON.stringify({ error: 'Authentication required' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body: TriggerEvent = await req.json()
    const { trigger_type, event_data } = body

    // SEC-AUDIT-1: Use JWT company_id if available, otherwise trust body (service calls only)
    const company_id = companyIdFromAuth || body.company_id

    if (!trigger_type || !company_id) {
      return new Response(JSON.stringify({ error: 'trigger_type and company_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Find matching enabled automations for this company + trigger type
    const { data: automations, error: fetchErr } = await supabase
      .from('automations')
      .select('*')
      .eq('company_id', company_id)
      .eq('trigger_type', trigger_type)
      .eq('status', 'active')
      .is('deleted_at', null)

    if (fetchErr) {
      console.error('Error fetching automations:', fetchErr)
      return new Response(JSON.stringify({ error: 'Failed to fetch automations' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    if (!automations || automations.length === 0) {
      return new Response(JSON.stringify({ matched: 0, message: 'No matching automations' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Filter automations by trigger_config conditions
    const matched = automations.filter((a: Automation) => matchesTriggerConfig(a, event_data))

    const results: { automation_id: string; status: string; actions_count: number }[] = []

    for (const automation of matched) {
      const result = await executeAutomation(supabase, automation as Automation, event_data, company_id)
      results.push(result)
    }

    return new Response(JSON.stringify({
      matched: matched.length,
      results,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('automation-engine error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

// ============================================================================
// TRIGGER MATCHING
// ============================================================================
function matchesTriggerConfig(automation: Automation, eventData: Record<string, unknown>): boolean {
  const config = automation.trigger_config || {}

  switch (automation.trigger_type) {
    case 'job_status': {
      const fromStatus = config.from_status as string | undefined
      const toStatus = config.to_status as string | undefined
      if (toStatus && eventData.new_status !== toStatus) return false
      if (fromStatus && eventData.old_status !== fromStatus) return false
      return true
    }
    case 'invoice_overdue': {
      const daysOverdue = config.days_overdue as number | undefined
      if (daysOverdue && (eventData.days_overdue as number) < daysOverdue) return false
      return true
    }
    case 'lead_idle': {
      const idleHours = config.idle_hours as number | undefined
      if (idleHours && (eventData.idle_hours as number) < idleHours) return false
      return true
    }
    case 'bid_event': {
      const toStatus = config.to_status as string | undefined
      if (toStatus && eventData.new_status !== toStatus) return false
      return true
    }
    case 'customer_event':
    case 'time_based':
      return true
    default:
      return true
  }
}

// ============================================================================
// EXECUTE AUTOMATION
// ============================================================================
async function executeAutomation(
  supabase: ReturnType<typeof createClient>,
  automation: Automation,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<{ automation_id: string; status: string; actions_count: number }> {
  const actionsExecuted: { type: string; status: string; error?: string }[] = []
  let overallStatus = 'success'

  for (const action of automation.actions) {
    try {
      await executeAction(supabase, action, eventData, companyId)
      actionsExecuted.push({ type: action.type, status: 'success' })
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Unknown error'
      actionsExecuted.push({ type: action.type, status: 'failed', error: errorMsg })
      overallStatus = 'partial'
    }
  }

  if (actionsExecuted.every(a => a.status === 'failed')) {
    overallStatus = 'failed'
  }

  // Log execution
  await supabase.from('automation_executions').insert({
    company_id: companyId,
    automation_id: automation.id,
    trigger_event: eventData,
    actions_executed: actionsExecuted,
    status: overallStatus,
    error_message: overallStatus !== 'success'
      ? actionsExecuted.filter(a => a.error).map(a => a.error).join('; ')
      : null,
  })

  // Update automation run count
  await supabase
    .from('automations')
    .update({
      last_run_at: new Date().toISOString(),
      run_count: (automation as Record<string, unknown>).run_count
        ? Number((automation as Record<string, unknown>).run_count) + 1
        : 1,
    })
    .eq('id', automation.id)

  return {
    automation_id: automation.id,
    status: overallStatus,
    actions_count: actionsExecuted.length,
  }
}

// ============================================================================
// ACTION EXECUTORS
// ============================================================================
async function executeAction(
  supabase: ReturnType<typeof createClient>,
  action: AutomationAction,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  switch (action.type) {
    case 'send_email':
      await executeSendEmail(supabase, action.config, eventData, companyId)
      break
    case 'send_sms':
      await executeSendSms(action.config, eventData, companyId)
      break
    case 'create_task':
      await executeCreateTask(supabase, action.config, eventData, companyId)
      break
    case 'notify_team':
      await executeNotifyTeam(supabase, action.config, eventData, companyId)
      break
    case 'update_status':
      await executeUpdateStatus(supabase, action.config, eventData, companyId)
      break
    case 'create_followup':
      await executeCreateFollowup(supabase, action.config, eventData, companyId)
      break
    default:
      console.warn(`Unknown action type: ${action.type}`)
  }
}

async function executeSendEmail(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')
  if (!SENDGRID_API_KEY) throw new Error('SendGrid not configured')

  // Get recipient email
  let toEmail = config.to_email || ''
  const toType = config.to || 'customer'

  if (toType === 'customer' && eventData.customer_id) {
    const { data: customer } = await supabase
      .from('customers')
      .select('email, first_name, last_name')
      .eq('id', eventData.customer_id)
      .single()
    if (customer?.email) toEmail = customer.email
  } else if (toType === 'owner') {
    const { data: owner } = await supabase
      .from('users')
      .select('email')
      .eq('company_id', companyId)
      .eq('role', 'owner')
      .limit(1)
      .single()
    if (owner?.email) toEmail = owner.email
  }

  if (!toEmail) throw new Error('No recipient email found')

  // Get company name for from address
  const { data: company } = await supabase
    .from('companies')
    .select('name')
    .eq('id', companyId)
    .single()

  const companyName = company?.name || 'Zafto'
  const subject = replaceTemplateVars(config.subject || 'Notification from {company_name}', eventData, companyName)
  const body = replaceTemplateVars(config.template || config.body || '', eventData, companyName)

  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: toEmail }] }],
      from: { email: `notifications@zafto.cloud`, name: companyName },
      subject,
      content: [{ type: 'text/plain', value: body }],
    }),
  })

  if (!response.ok && response.status !== 202) {
    throw new Error(`SendGrid error: ${response.status}`)
  }
}

async function executeSendSms(
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  _companyId: string,
): Promise<void> {
  const SW_SPACE = Deno.env.get('SIGNALWIRE_SPACE_NAME') ?? ''
  const SW_PROJECT = Deno.env.get('SIGNALWIRE_PROJECT_KEY') ?? ''
  const SW_TOKEN = Deno.env.get('SIGNALWIRE_API_TOKEN') ?? ''

  if (!SW_SPACE || !SW_PROJECT || !SW_TOKEN) throw new Error('SignalWire not configured')

  const toNumber = config.to_number || eventData.customer_phone as string
  if (!toNumber) throw new Error('No phone number')

  const message = replaceTemplateVars(config.template || config.message || '', eventData, '')
  const swBase = `https://${SW_SPACE}.signalwire.com/api/laml/2010-04-01/Accounts/${SW_PROJECT}`
  const swAuth = btoa(`${SW_PROJECT}:${SW_TOKEN}`)

  const smsParams = new URLSearchParams({
    From: config.from_number || '',
    To: toNumber,
    Body: message,
  })

  const response = await fetch(`${swBase}/Messages.json`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${swAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: smsParams.toString(),
  })

  if (!response.ok) throw new Error(`SignalWire error: ${response.status}`)
}

async function executeCreateTask(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  const title = replaceTemplateVars(config.title || 'Follow up', eventData, '')

  await supabase.from('tasks').insert({
    company_id: companyId,
    title,
    description: config.description || null,
    status: 'pending',
    priority: config.priority || 'normal',
    assigned_to: config.assign_to || null,
    job_id: eventData.job_id || null,
    customer_id: eventData.customer_id || null,
  })
}

async function executeNotifyTeam(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  const message = replaceTemplateVars(config.message || 'Automation notification', eventData, '')
  const role = config.role || 'owner'

  // Get users with matching role
  const { data: users } = await supabase
    .from('users')
    .select('id')
    .eq('company_id', companyId)
    .eq('role', role)

  if (!users || users.length === 0) return

  // Insert notifications for each user
  const notifications = users.map((u: { id: string }) => ({
    company_id: companyId,
    user_id: u.id,
    title: 'Automation Alert',
    message,
    type: 'automation',
    read: false,
  }))

  await supabase.from('notifications').insert(notifications)
}

async function executeUpdateStatus(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  const table = config.table
  const newStatus = config.status
  const recordId = eventData.record_id || eventData.id

  if (!table || !newStatus || !recordId) throw new Error('Missing table, status, or record_id')

  // Only allow updates to known business tables
  const allowedTables = ['jobs', 'invoices', 'bids', 'leads', 'estimates']
  if (!allowedTables.includes(table)) throw new Error(`Cannot update table: ${table}`)

  // SEC-AUDIT-1: Scope update to company to prevent cross-company status manipulation
  await supabase.from(table).update({ status: newStatus }).eq('id', recordId).eq('company_id', companyId)
}


async function executeCreateFollowup(
  supabase: ReturnType<typeof createClient>,
  config: Record<string, string>,
  eventData: Record<string, unknown>,
  companyId: string,
): Promise<void> {
  // Create a follow-up job from a bid or estimate
  const fromType = config.from // 'bid' or 'estimate'
  const sourceId = eventData.record_id || eventData.id

  if (fromType === 'bid' && sourceId) {
    const { data: bid } = await supabase
      .from('bids')
      .select('*, customers(first_name, last_name, email, phone, address)')
      .eq('id', sourceId)
      .single()

    if (bid) {
      const customer = bid.customers as Record<string, unknown> | null
      await supabase.from('jobs').insert({
        company_id: companyId,
        created_by_user_id: bid.created_by_user_id,
        customer_id: bid.customer_id,
        customer_name: customer ? `${customer.first_name} ${customer.last_name}` : 'Unknown',
        address: customer?.address || '',
        title: `Job from Bid ${bid.bid_number || ''}`.trim(),
        description: bid.notes || '',
        status: 'scheduled',
        trade_type: bid.trade_type || 'general',
      })
    }
  }
}

// ============================================================================
// TEMPLATE HELPERS
// ============================================================================
function replaceTemplateVars(
  template: string,
  eventData: Record<string, unknown>,
  companyName: string,
): string {
  return template
    .replace(/\{company_name\}/g, companyName)
    .replace(/\{customer_name\}/g, String(eventData.customer_name || ''))
    .replace(/\{job_title\}/g, String(eventData.job_title || ''))
    .replace(/\{bid_number\}/g, String(eventData.bid_number || ''))
    .replace(/\{invoice_number\}/g, String(eventData.invoice_number || ''))
    .replace(/\{status\}/g, String(eventData.new_status || eventData.status || ''))
    .replace(/\{amount\}/g, String(eventData.amount || ''))
}
