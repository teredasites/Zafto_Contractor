// Supabase Edge Function: z-intelligence
// Proxy between browser and Claude API for Z Intelligence.
// Handles auth, rate limiting, tool use, streaming, artifact detection.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ---------- Types ----------

interface ZIntelligenceRequest {
  threadId: string // existing UUID or 'new'
  message: string
  pageContext: string
  artifactContext?: {
    id: string
    type: string
    content: string
    data: Record<string, unknown>
    currentVersion: number
  }
}

interface UserContext {
  userId: string
  companyId: string
  userName: string
  role: string
  companyName: string
  trade: string
}

// ---------- Tool Definitions (Claude API format) ----------

const TOOLS = [
  {
    name: 'searchCustomers',
    description: 'Search customers by name, email, or phone. Returns matching customer records.',
    input_schema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search term (name, email, or phone)' },
      },
      required: ['query'],
    },
  },
  {
    name: 'getCustomer',
    description: 'Get full details for a specific customer by ID.',
    input_schema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Customer UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'searchJobs',
    description: 'Search jobs by title, status, or customer name. Returns matching job records with customer info.',
    input_schema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search term' },
        status: { type: 'string', description: 'Filter by status (draft, scheduled, in_progress, completed, cancelled)' },
      },
      required: [],
    },
  },
  {
    name: 'getJob',
    description: 'Get full job details including customer, change orders, and invoices.',
    input_schema: {
      type: 'object',
      properties: {
        id: { type: 'string', description: 'Job UUID' },
      },
      required: ['id'],
    },
  },
  {
    name: 'getInvoices',
    description: 'List invoices with optional filters. Returns invoices with job titles.',
    input_schema: {
      type: 'object',
      properties: {
        status: { type: 'string', description: 'Filter by status (draft, sent, paid, overdue, cancelled)' },
        customerId: { type: 'string', description: 'Filter by customer UUID' },
        limit: { type: 'number', description: 'Max results (default 25)' },
      },
      required: [],
    },
  },
  {
    name: 'getBids',
    description: 'List bids with optional filters. Returns bids with customer names.',
    input_schema: {
      type: 'object',
      properties: {
        status: { type: 'string', description: 'Filter by status (draft, sent, accepted, rejected, expired)' },
        customerId: { type: 'string', description: 'Filter by customer UUID' },
        limit: { type: 'number', description: 'Max results (default 25)' },
      },
      required: [],
    },
  },
  {
    name: 'getSchedule',
    description: 'Get jobs scheduled within a date range.',
    input_schema: {
      type: 'object',
      properties: {
        from: { type: 'string', description: 'Start date (YYYY-MM-DD)' },
        to: { type: 'string', description: 'End date (YYYY-MM-DD)' },
      },
      required: ['from', 'to'],
    },
  },
  {
    name: 'getMaterials',
    description: 'Get materials/parts for a specific job.',
    input_schema: {
      type: 'object',
      properties: {
        jobId: { type: 'string', description: 'Job UUID' },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'getTimeEntries',
    description: 'Get time entries for a specific job or user.',
    input_schema: {
      type: 'object',
      properties: {
        jobId: { type: 'string', description: 'Job UUID' },
        userId: { type: 'string', description: 'User UUID (optional)' },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'getPunchList',
    description: 'Get punch list items for a specific job.',
    input_schema: {
      type: 'object',
      properties: {
        jobId: { type: 'string', description: 'Job UUID' },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'getChangeOrders',
    description: 'Get change orders for a specific job.',
    input_schema: {
      type: 'object',
      properties: {
        jobId: { type: 'string', description: 'Job UUID' },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'calculateMargin',
    description: 'Calculate profit margin for a job from invoices, materials, and labor costs.',
    input_schema: {
      type: 'object',
      properties: {
        jobId: { type: 'string', description: 'Job UUID' },
      },
      required: ['jobId'],
    },
  },
  {
    name: 'getLeads',
    description: 'List leads with optional stage filter.',
    input_schema: {
      type: 'object',
      properties: {
        stage: { type: 'string', description: 'Filter by stage (new, contacted, qualified, proposal, negotiation, won)' },
        limit: { type: 'number', description: 'Max results (default 25)' },
      },
      required: [],
    },
  },
  {
    name: 'getTeam',
    description: 'List team members for the company.',
    input_schema: {
      type: 'object',
      properties: {},
      required: [],
    },
  },
]

// ---------- Tool Executor ----------

async function executeTool(
  toolName: string,
  input: Record<string, unknown>,
  supabase: ReturnType<typeof createClient>,
  companyId: string
): Promise<unknown> {
  switch (toolName) {
    case 'searchCustomers': {
      const q = String(input.query || '')
      const { data, error } = await supabase
        .from('customers')
        .select('id, name, email, phone, address, status, created_at')
        .eq('company_id', companyId)
        .or(`name.ilike.%${q}%,email.ilike.%${q}%,phone.ilike.%${q}%`)
        .limit(10)
      if (error) return { error: error.message }
      return data
    }

    case 'getCustomer': {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .eq('id', input.id)
        .eq('company_id', companyId)
        .single()
      if (error) return { error: error.message }
      return data
    }

    case 'searchJobs': {
      let query = supabase
        .from('jobs')
        .select('id, title, status, scheduled_start, scheduled_end, customer_name, address, priority, created_at, customers(name)')
        .eq('company_id', companyId)

      if (input.query) {
        query = query.or(`title.ilike.%${input.query}%,customer_name.ilike.%${input.query}%`)
      }
      if (input.status) {
        query = query.eq('status', input.status)
      }
      const { data, error } = await query.order('created_at', { ascending: false }).limit(15)
      if (error) return { error: error.message }
      return data
    }

    case 'getJob': {
      const { data, error } = await supabase
        .from('jobs')
        .select('*, customers(*), change_orders(*), invoices(*)')
        .eq('id', input.id)
        .eq('company_id', companyId)
        .single()
      if (error) return { error: error.message }
      return data
    }

    case 'getInvoices': {
      let query = supabase
        .from('invoices')
        .select('id, invoice_number, customer_name, total, amount_paid, amount_due, status, due_date, created_at, jobs(title)')
        .eq('company_id', companyId)

      if (input.status) query = query.eq('status', input.status)
      if (input.customerId) query = query.eq('customer_id', input.customerId)
      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(Number(input.limit) || 25)
      if (error) return { error: error.message }
      return data
    }

    case 'getBids': {
      let query = supabase
        .from('bids')
        .select('id, bid_number, title, customer_name, total, status, valid_until, created_at, customers(name)')
        .eq('company_id', companyId)

      if (input.status) query = query.eq('status', input.status)
      if (input.customerId) query = query.eq('customer_id', input.customerId)
      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(Number(input.limit) || 25)
      if (error) return { error: error.message }
      return data
    }

    case 'getSchedule': {
      const { data, error } = await supabase
        .from('jobs')
        .select('id, title, status, scheduled_start, scheduled_end, customer_name, address, assigned_to')
        .eq('company_id', companyId)
        .gte('scheduled_start', input.from)
        .lte('scheduled_start', input.to)
        .order('scheduled_start', { ascending: true })
      if (error) return { error: error.message }
      return data
    }

    case 'getMaterials': {
      const { data, error } = await supabase
        .from('job_materials')
        .select('*')
        .eq('job_id', input.jobId)
      if (error) return { error: error.message }
      return data
    }

    case 'getTimeEntries': {
      let query = supabase
        .from('time_entries')
        .select('*')
        .eq('job_id', input.jobId)
      if (input.userId) query = query.eq('user_id', input.userId)
      const { data, error } = await query.order('clock_in', { ascending: false })
      if (error) return { error: error.message }
      return data
    }

    case 'getPunchList': {
      const { data, error } = await supabase
        .from('punch_list_items')
        .select('*')
        .eq('job_id', input.jobId)
        .order('created_at', { ascending: true })
      if (error) return { error: error.message }
      return data
    }

    case 'getChangeOrders': {
      const { data, error } = await supabase
        .from('change_orders')
        .select('*')
        .eq('job_id', input.jobId)
        .order('order_number', { ascending: true })
      if (error) return { error: error.message }
      return data
    }

    case 'calculateMargin': {
      // Revenue from invoices
      const { data: invoices } = await supabase
        .from('invoices')
        .select('total, amount_paid')
        .eq('job_id', input.jobId)
      const revenue = (invoices || []).reduce((sum: number, i: { total: number }) => sum + Number(i.total || 0), 0)

      // Material costs
      const { data: materials } = await supabase
        .from('job_materials')
        .select('total_cost')
        .eq('job_id', input.jobId)
      const materialCost = (materials || []).reduce((sum: number, m: { total_cost: number }) => sum + Number(m.total_cost || 0), 0)

      // Labor costs from time entries
      const { data: timeEntries } = await supabase
        .from('time_entries')
        .select('total_hours, hourly_rate')
        .eq('job_id', input.jobId)
      const laborCost = (timeEntries || []).reduce(
        (sum: number, t: { total_hours: number; hourly_rate: number }) =>
          sum + Number(t.total_hours || 0) * Number(t.hourly_rate || 0),
        0
      )

      const totalCost = materialCost + laborCost
      const margin = revenue > 0 ? ((revenue - totalCost) / revenue) * 100 : 0

      return {
        revenue,
        materialCost,
        laborCost,
        totalCost,
        profit: revenue - totalCost,
        marginPercent: Math.round(margin * 100) / 100,
      }
    }

    case 'getLeads': {
      let query = supabase
        .from('leads')
        .select('id, name, email, phone, source, stage, estimated_value, notes, next_follow_up, created_at')
        .eq('company_id', companyId)

      if (input.stage) query = query.eq('stage', input.stage)
      const { data, error } = await query
        .order('created_at', { ascending: false })
        .limit(Number(input.limit) || 25)
      if (error) return { error: error.message }
      return data
    }

    case 'getTeam': {
      const { data, error } = await supabase
        .from('users')
        .select('id, name, email, role, phone, status, created_at')
        .eq('company_id', companyId)
      if (error) return { error: error.message }
      return data
    }

    default:
      return { error: `Unknown tool: ${toolName}` }
  }
}

// ---------- System Prompt Builder ----------

function buildSystemPrompt(ctx: UserContext, pageContext: string, artifactContext?: ZIntelligenceRequest['artifactContext']): string {
  let prompt = `You are Z, the AI assistant for ${ctx.companyName} — a ${ctx.trade} contractor using ZAFTO.
Current user: ${ctx.userName} (${ctx.role})
Current page: ${pageContext}
Company data available: customers, jobs, invoices, bids, leads, materials, time_entries, punch_list_items, change_orders, team

You can:
1. Query business data (customers, jobs, invoices, bids, materials, time entries)
2. Generate professional documents (bids, invoices, reports, change orders, scopes of work)
3. Analyze financial data (margins, costs, revenue trends)
4. Schedule and calendar management

When generating a document, output it as a ZAFTO artifact using this exact format:

<artifact type="bid" title="Title here">
<data>
{"customer":{"name":"..."},"lineItems":[...],"total":0}
</data>
<content>
# Document Title
...full markdown content...
</content>
</artifact>

Valid artifact types: bid, invoice, report, job_summary, email, change_order, scope, generic

Important rules:
- Be concise and professional. This is a contractor's work tool, not a chatbot.
- When unsure about data, use tools to look it up rather than guessing.
- Format currency as $X,XXX.XX
- Dates should use the format: Mon DD, YYYY`

  if (artifactContext) {
    prompt += `

ACTIVE ARTIFACT (user is editing this):
Type: ${artifactContext.type}
Content:
${artifactContext.content}

Data:
${JSON.stringify(artifactContext.data, null, 2)}

The user wants to edit this artifact. Generate an updated version with the same format.`
  }

  return prompt
}

// ---------- Artifact Parser ----------

function parseArtifacts(text: string): Array<{ type: string; title: string; content: string; data: Record<string, unknown> }> {
  const artifacts: Array<{ type: string; title: string; content: string; data: Record<string, unknown> }> = []
  const regex = /<artifact\s+type="([^"]+)"\s+title="([^"]+)">\s*<data>\s*([\s\S]*?)\s*<\/data>\s*<content>\s*([\s\S]*?)\s*<\/content>\s*<\/artifact>/g

  let match
  while ((match = regex.exec(text)) !== null) {
    let data: Record<string, unknown> = {}
    try {
      data = JSON.parse(match[3].trim())
    } catch {
      data = {}
    }
    artifacts.push({
      type: match[1],
      title: match[2],
      content: match[4].trim(),
      data,
    })
  }

  return artifacts
}

// ---------- Rate Limiting ----------

async function checkRateLimit(
  supabase: ReturnType<typeof createClient>,
  companyId: string,
  userId: string
): Promise<{ allowed: boolean; reason?: string }> {
  const today = new Date().toISOString().split('T')[0]

  // Count today's threads/messages for this company
  const { count: companyCount } = await supabase
    .from('z_threads')
    .select('*', { count: 'exact', head: true })
    .eq('company_id', companyId)
    .gte('updated_at', today + 'T00:00:00Z')

  if ((companyCount || 0) > 5000) {
    return { allowed: false, reason: 'Company daily message limit reached (5000/day)' }
  }

  // Count today's threads for this user
  const { count: userCount } = await supabase
    .from('z_threads')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .gte('updated_at', today + 'T00:00:00Z')

  if ((userCount || 0) > 200) {
    return { allowed: false, reason: 'User daily message limit reached (200/day)' }
  }

  return { allowed: true }
}

// ---------- SSE Helpers ----------

function sseEvent(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`
}

// ---------- Main Handler ----------

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')
  if (!ANTHROPIC_API_KEY) {
    return new Response(JSON.stringify({ error: 'ANTHROPIC_API_KEY not configured' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Auth: Extract user from Supabase JWT
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const supabaseAuth = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data: { user }, error: authError } = await supabaseAuth.auth.getUser()
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Invalid auth token' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Service role client for data queries
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Get user profile for context
  const { data: userProfile } = await supabase
    .from('users')
    .select('name, role, company_id, companies(name, trade)')
    .eq('id', user.id)
    .single()

  if (!userProfile || !userProfile.company_id) {
    return new Response(JSON.stringify({ error: 'User profile not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const companyData = userProfile.companies as unknown as { name: string; trade: string } | null
  const userCtx: UserContext = {
    userId: user.id,
    companyId: userProfile.company_id,
    userName: userProfile.name || user.email || 'Unknown',
    role: userProfile.role || 'tech',
    companyName: companyData?.name || 'Unknown Company',
    trade: companyData?.trade || 'general contractor',
  }

  // Rate limiting
  const rateCheck = await checkRateLimit(supabase, userCtx.companyId, userCtx.userId)
  if (!rateCheck.allowed) {
    return new Response(JSON.stringify({ error: rateCheck.reason }), {
      status: 429,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Parse request
  let body: ZIntelligenceRequest
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  if (!body.message?.trim()) {
    return new Response(JSON.stringify({ error: 'Message is required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Thread management
  let threadId = body.threadId
  let existingMessages: Array<{ role: string; content: string }> = []

  if (threadId && threadId !== 'new') {
    // Load existing thread
    const { data: thread } = await supabase
      .from('z_threads')
      .select('messages')
      .eq('id', threadId)
      .eq('company_id', userCtx.companyId)
      .single()

    if (thread?.messages) {
      existingMessages = thread.messages as Array<{ role: string; content: string }>
    }
  } else {
    // Create new thread
    const { data: newThread, error: createErr } = await supabase
      .from('z_threads')
      .insert({
        company_id: userCtx.companyId,
        user_id: userCtx.userId,
        title: body.message.substring(0, 100),
        page_context: body.pageContext,
        messages: [],
      })
      .select('id')
      .single()

    if (createErr || !newThread) {
      return new Response(JSON.stringify({ error: 'Failed to create thread' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    threadId = newThread.id
  }

  // Build messages array for Claude
  const systemPrompt = buildSystemPrompt(userCtx, body.pageContext, body.artifactContext)

  // Reconstruct conversation history (only last 20 messages for context window)
  const historyMessages = existingMessages.slice(-20).map((m) => ({
    role: m.role as 'user' | 'assistant',
    content: m.content,
  }))

  const messages = [
    ...historyMessages,
    { role: 'user' as const, content: body.message },
  ]

  // SSE streaming response
  const encoder = new TextEncoder()
  const stream = new ReadableStream({
    async start(controller) {
      try {
        let totalTokens = 0
        let fullAssistantResponse = ''

        // Call Claude API with tool use loop
        let continueLoop = true
        let currentMessages = [...messages]

        while (continueLoop) {
          const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': ANTHROPIC_API_KEY,
              'anthropic-version': '2023-06-01',
            },
            body: JSON.stringify({
              model: 'claude-sonnet-4-5-20250929',
              max_tokens: 4096,
              system: systemPrompt,
              tools: TOOLS,
              messages: currentMessages,
            }),
          })

          if (!claudeResponse.ok) {
            const errText = await claudeResponse.text()
            controller.enqueue(encoder.encode(sseEvent('error', { message: `Claude API error: ${claudeResponse.status}` })))
            controller.enqueue(encoder.encode(sseEvent('done', { tokenCount: totalTokens, threadId, error: errText })))
            controller.close()
            return
          }

          const result = await claudeResponse.json()
          totalTokens += (result.usage?.input_tokens || 0) + (result.usage?.output_tokens || 0)

          // Process content blocks
          const toolUseBlocks: Array<{ id: string; name: string; input: Record<string, unknown> }> = []
          let textContent = ''

          for (const block of result.content) {
            if (block.type === 'text') {
              textContent += block.text
              // Stream text content
              controller.enqueue(encoder.encode(sseEvent('content', { delta: block.text })))
            } else if (block.type === 'tool_use') {
              toolUseBlocks.push({ id: block.id, name: block.name, input: block.input })
              controller.enqueue(encoder.encode(sseEvent('thinking', {
                toolCalls: [{ name: block.name, status: 'running' }],
              })))
            }
          }

          fullAssistantResponse += textContent

          // Check for artifacts in text
          const artifacts = parseArtifacts(textContent)
          for (const artifact of artifacts) {
            // Save artifact to DB
            const { data: savedArtifact } = await supabase
              .from('z_artifacts')
              .insert({
                company_id: userCtx.companyId,
                thread_id: threadId,
                type: artifact.type,
                title: artifact.title,
                content: artifact.content,
                data: artifact.data,
                versions: [{ version: 1, content: artifact.content, data: artifact.data, createdAt: new Date().toISOString() }],
                current_version: 1,
                status: 'ready',
              })
              .select('id')
              .single()

            if (savedArtifact) {
              // Link artifact to thread
              await supabase
                .from('z_threads')
                .update({ artifact_id: savedArtifact.id })
                .eq('id', threadId)

              controller.enqueue(encoder.encode(sseEvent('artifact', {
                id: savedArtifact.id,
                type: artifact.type,
                title: artifact.title,
                content: artifact.content,
                data: artifact.data,
              })))
            }
          }

          // If tool use, execute tools and continue loop
          if (toolUseBlocks.length > 0 && result.stop_reason === 'tool_use') {
            const toolResults: Array<{ type: 'tool_result'; tool_use_id: string; content: string }> = []

            for (const tool of toolUseBlocks) {
              const toolResult = await executeTool(tool.name, tool.input, supabase, userCtx.companyId)
              controller.enqueue(encoder.encode(sseEvent('tool_result', {
                name: tool.name,
                status: 'complete',
                result: toolResult,
              })))
              toolResults.push({
                type: 'tool_result',
                tool_use_id: tool.id,
                content: JSON.stringify(toolResult),
              })
            }

            // Add assistant message with tool use + tool results for next iteration
            currentMessages = [
              ...currentMessages,
              { role: 'assistant' as const, content: result.content },
              ...toolResults.map((tr) => ({ role: 'user' as const, ...tr })),
            ]
          } else {
            // No more tool calls, we're done
            continueLoop = false
          }
        }

        // Persist messages to thread
        const updatedMessages = [
          ...existingMessages,
          { role: 'user', content: body.message },
          { role: 'assistant', content: fullAssistantResponse },
        ]

        await supabase
          .from('z_threads')
          .update({
            messages: updatedMessages,
            token_count: totalTokens,
          })
          .eq('id', threadId)

        // Done event
        controller.enqueue(encoder.encode(sseEvent('done', { tokenCount: totalTokens, threadId })))
        controller.close()
      } catch (err) {
        console.error('Stream error:', err)
        controller.enqueue(encoder.encode(sseEvent('error', { message: 'Internal stream error' })))
        controller.close()
      }
    },
  })

  return new Response(stream, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  })
})
