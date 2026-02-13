// Supabase Edge Function: tpa-documentation-validator
// Check all documentation against TPA program requirements.
// Returns missing items, compliance percentage, deadline status per phase.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChecklistItem {
  id: string
  phase: string
  item_name: string
  description: string | null
  is_required: boolean
  evidence_type: string
  min_count: number
  sort_order: number
}

interface ProgressItem {
  checklist_item_id: string
  is_complete: boolean
  evidence_count: number
  completed_at: string | null
}

interface ValidationResult {
  phase: string
  total_items: number
  completed_items: number
  required_items: number
  required_completed: number
  missing_required: {
    item_name: string
    description: string | null
    evidence_type: string
    min_count: number
  }[]
  missing_optional: {
    item_name: string
    description: string | null
  }[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
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

  const companyId = user.app_metadata?.company_id
  if (!companyId) {
    return new Response(JSON.stringify({ error: 'No company associated' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  try {
    const body = await req.json()
    const { job_id, tpa_assignment_id } = body as {
      job_id: string
      tpa_assignment_id?: string
    }

    if (!job_id) {
      return new Response(JSON.stringify({ error: 'job_id required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 1. Get job info to determine job type
    const { data: job, error: jobError } = await supabase
      .from('jobs')
      .select('id, title, job_type, status')
      .eq('id', job_id)
      .single()

    if (jobError || !job) {
      return new Response(JSON.stringify({ error: 'Job not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. Map job_type to checklist job_type
    const jobType = mapJobType(job.job_type)

    // 3. Find applicable checklist template (company-specific first, then system default)
    const { data: templates } = await supabase
      .from('doc_checklist_templates')
      .select('id, name, job_type, is_system_default')
      .eq('job_type', jobType)
      .eq('is_active', true)
      .or(`company_id.eq.${companyId},company_id.is.null`)
      .order('is_system_default', { ascending: true }) // company-specific first

    const template = templates?.[0]
    if (!template) {
      return new Response(JSON.stringify({
        job_id,
        job_type: jobType,
        compliance_percentage: 0,
        message: 'No documentation checklist template found for this job type',
        phases: [],
        overall: { total: 0, completed: 0, required_total: 0, required_completed: 0 },
      }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 4. Get all checklist items for this template
    const { data: checklistItems, error: itemsError } = await supabase
      .from('doc_checklist_items')
      .select('*')
      .eq('template_id', template.id)
      .order('sort_order')

    if (itemsError) throw itemsError
    const items = (checklistItems || []) as ChecklistItem[]

    // 5. Get job progress records
    const { data: progressData, error: progressError } = await supabase
      .from('job_doc_progress')
      .select('checklist_item_id, is_complete, evidence_count, completed_at')
      .eq('job_id', job_id)

    if (progressError) throw progressError
    const progress = (progressData || []) as ProgressItem[]
    const progressMap = new Map(progress.map(p => [p.checklist_item_id, p]))

    // 6. Get TPA assignment deadline if applicable
    let deadline: string | null = null
    let daysRemaining: number | null = null
    if (tpa_assignment_id) {
      const { data: assignment } = await supabase
        .from('tpa_assignments')
        .select('sla_deadline')
        .eq('id', tpa_assignment_id)
        .single()

      if (assignment?.sla_deadline) {
        deadline = assignment.sla_deadline
        const deadlineDate = new Date(assignment.sla_deadline)
        const now = new Date()
        daysRemaining = Math.ceil((deadlineDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
      }
    }

    // 7. Build validation results by phase
    const phases = ['initial_inspection', 'during_work', 'daily_monitoring', 'completion', 'closeout']
    const results: ValidationResult[] = []

    for (const phase of phases) {
      const phaseItems = items.filter(i => i.phase === phase)
      if (phaseItems.length === 0) continue

      const requiredItems = phaseItems.filter(i => i.is_required)
      const missingRequired: ValidationResult['missing_required'] = []
      const missingOptional: ValidationResult['missing_optional'] = []
      let completedCount = 0
      let requiredCompletedCount = 0

      for (const item of phaseItems) {
        const prog = progressMap.get(item.id)
        const isComplete = prog?.is_complete === true && (prog.evidence_count >= item.min_count)

        if (isComplete) {
          completedCount++
          if (item.is_required) requiredCompletedCount++
        } else {
          if (item.is_required) {
            missingRequired.push({
              item_name: item.item_name,
              description: item.description,
              evidence_type: item.evidence_type,
              min_count: item.min_count,
            })
          } else {
            missingOptional.push({
              item_name: item.item_name,
              description: item.description,
            })
          }
        }
      }

      results.push({
        phase,
        total_items: phaseItems.length,
        completed_items: completedCount,
        required_items: requiredItems.length,
        required_completed: requiredCompletedCount,
        missing_required: missingRequired,
        missing_optional: missingOptional,
      })
    }

    // 8. Calculate overall compliance
    const totalItems = results.reduce((s, r) => s + r.total_items, 0)
    const completedItems = results.reduce((s, r) => s + r.completed_items, 0)
    const totalRequired = results.reduce((s, r) => s + r.required_items, 0)
    const completedRequired = results.reduce((s, r) => s + r.required_completed, 0)
    const compliancePercentage = totalRequired > 0
      ? Math.round((completedRequired / totalRequired) * 100)
      : 100

    const isFullyCompliant = completedRequired === totalRequired
    const totalMissingRequired = results.reduce((s, r) => s + r.missing_required.length, 0)

    return new Response(JSON.stringify({
      job_id,
      job_type: jobType,
      template_name: template.name,
      compliance_percentage: compliancePercentage,
      is_fully_compliant: isFullyCompliant,
      deadline: deadline ? {
        date: deadline,
        days_remaining: daysRemaining,
        is_overdue: daysRemaining !== null && daysRemaining < 0,
        is_urgent: daysRemaining !== null && daysRemaining <= 3 && daysRemaining >= 0,
      } : null,
      overall: {
        total: totalItems,
        completed: completedItems,
        required_total: totalRequired,
        required_completed: completedRequired,
        missing_required_count: totalMissingRequired,
      },
      phases: results,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Internal server error'
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

function mapJobType(jobType: string | null): string {
  if (!jobType) return 'general_restoration'
  const type = jobType.toLowerCase()
  if (type.includes('water') || type.includes('flood') || type.includes('mitigation')) return 'water_mitigation'
  if (type.includes('fire') || type.includes('smoke')) return 'fire_restoration'
  if (type.includes('mold')) return 'mold_remediation'
  if (type.includes('roof')) return 'roofing_claim'
  if (type.includes('contents') || type.includes('pack')) return 'contents_packout'
  return 'general_restoration'
}
