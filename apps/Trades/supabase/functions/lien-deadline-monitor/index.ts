// Supabase Edge Function: lien-deadline-monitor
// CRON daily: check all active lien records, alert at 30/14/7/3/1 days before each deadline.
// Calculates deadline dates from lien_rules_by_state + lien_tracking dates.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const ALERT_THRESHOLDS = [30, 14, 7, 3, 1]

interface LienRecord {
  id: string
  company_id: string
  job_id: string
  property_address: string
  state_code: string
  first_work_date: string | null
  last_work_date: string | null
  completion_date: string | null
  preliminary_notice_sent: boolean
  lien_filed: boolean
  lien_released: boolean
  status: string
}

interface LienRule {
  state_code: string
  preliminary_notice_required: boolean
  preliminary_notice_deadline_days: number | null
  preliminary_notice_from: string | null
  lien_filing_deadline_days: number
  lien_filing_from: string
  lien_enforcement_deadline_days: number | null
  notice_of_intent_required: boolean
}

interface DeadlineAlert {
  lien_id: string
  company_id: string
  job_id: string
  property_address: string
  state_code: string
  deadline_type: string
  deadline_date: string
  days_remaining: number
  urgency: 'critical' | 'warning' | 'info'
}

function getReferenceDate(lien: LienRecord, from: string): Date | null {
  switch (from) {
    case 'start_work':
    case 'first_work':
      return lien.first_work_date ? new Date(lien.first_work_date) : null
    case 'last_work':
      return lien.last_work_date ? new Date(lien.last_work_date) : null
    case 'completion':
      return lien.completion_date || lien.last_work_date
        ? new Date((lien.completion_date || lien.last_work_date)!)
        : null
    case 'contract_date':
    case 'each_month':
      // For contract_date/each_month, fall back to first_work_date
      return lien.first_work_date ? new Date(lien.first_work_date) : null
    default:
      return lien.last_work_date ? new Date(lien.last_work_date) : null
  }
}

function daysBetween(a: Date, b: Date): number {
  return Math.ceil((b.getTime() - a.getTime()) / 86400000)
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Load all active lien records
    const { data: liens, error: liensErr } = await supabase
      .from('lien_tracking')
      .select('*')
      .in('status', ['monitoring', 'notice_due', 'notice_sent', 'lien_eligible', 'lien_filed', 'enforcement'])
      .is('deleted_at', null)

    if (liensErr) throw liensErr
    if (!liens || !liens.length) {
      return new Response(JSON.stringify({ message: 'No active liens to monitor', alerts: 0 }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Load all rules
    const { data: rules, error: rulesErr } = await supabase
      .from('lien_rules_by_state')
      .select('*')

    if (rulesErr) throw rulesErr

    const rulesMap = new Map<string, LienRule>()
    for (const rule of (rules || [])) {
      rulesMap.set(rule.state_code, rule)
    }

    const now = new Date()
    const alerts: DeadlineAlert[] = []
    const statusUpdates: { id: string; status: string }[] = []

    for (const lien of liens as LienRecord[]) {
      const rule = rulesMap.get(lien.state_code)
      if (!rule) continue

      // 1. Check preliminary notice deadline
      if (rule.preliminary_notice_required && !lien.preliminary_notice_sent && rule.preliminary_notice_deadline_days) {
        const refDate = getReferenceDate(lien, rule.preliminary_notice_from || 'start_work')
        if (refDate) {
          const deadline = new Date(refDate)
          deadline.setDate(deadline.getDate() + rule.preliminary_notice_deadline_days)
          const daysLeft = daysBetween(now, deadline)

          if (daysLeft <= 0) {
            // Deadline passed — update status
            statusUpdates.push({ id: lien.id, status: 'expired' })
          } else if (ALERT_THRESHOLDS.some(t => daysLeft <= t)) {
            alerts.push({
              lien_id: lien.id,
              company_id: lien.company_id,
              job_id: lien.job_id,
              property_address: lien.property_address,
              state_code: lien.state_code,
              deadline_type: 'preliminary_notice',
              deadline_date: deadline.toISOString().split('T')[0],
              days_remaining: daysLeft,
              urgency: daysLeft <= 3 ? 'critical' : daysLeft <= 7 ? 'warning' : 'info',
            })

            if (lien.status === 'monitoring') {
              statusUpdates.push({ id: lien.id, status: 'notice_due' })
            }
          }
        }
      }

      // 2. Check lien filing deadline
      if (!lien.lien_filed) {
        const refDate = getReferenceDate(lien, rule.lien_filing_from)
        if (refDate) {
          const deadline = new Date(refDate)
          deadline.setDate(deadline.getDate() + rule.lien_filing_deadline_days)
          const daysLeft = daysBetween(now, deadline)

          if (daysLeft <= 0 && !lien.lien_released) {
            statusUpdates.push({ id: lien.id, status: 'expired' })
          } else if (ALERT_THRESHOLDS.some(t => daysLeft <= t)) {
            alerts.push({
              lien_id: lien.id,
              company_id: lien.company_id,
              job_id: lien.job_id,
              property_address: lien.property_address,
              state_code: lien.state_code,
              deadline_type: 'lien_filing',
              deadline_date: deadline.toISOString().split('T')[0],
              days_remaining: daysLeft,
              urgency: daysLeft <= 3 ? 'critical' : daysLeft <= 7 ? 'warning' : 'info',
            })

            if (lien.status === 'notice_sent' || lien.status === 'monitoring') {
              statusUpdates.push({ id: lien.id, status: 'lien_eligible' })
            }
          }
        }
      }

      // 3. Check lien enforcement deadline (if lien is filed)
      if (lien.lien_filed && !lien.lien_released && rule.lien_enforcement_deadline_days) {
        // Enforcement deadline from lien filing date
        const lienDate = (lien as Record<string, unknown>).lien_filing_date as string | null
        if (lienDate) {
          const deadline = new Date(lienDate)
          deadline.setDate(deadline.getDate() + rule.lien_enforcement_deadline_days)
          const daysLeft = daysBetween(now, deadline)

          if (ALERT_THRESHOLDS.some(t => daysLeft <= t) && daysLeft > 0) {
            alerts.push({
              lien_id: lien.id,
              company_id: lien.company_id,
              job_id: lien.job_id,
              property_address: lien.property_address,
              state_code: lien.state_code,
              deadline_type: 'lien_enforcement',
              deadline_date: deadline.toISOString().split('T')[0],
              days_remaining: daysLeft,
              urgency: daysLeft <= 3 ? 'critical' : daysLeft <= 7 ? 'warning' : 'info',
            })
          }
        }
      }
    }

    // Apply status updates
    for (const update of statusUpdates) {
      await supabase
        .from('lien_tracking')
        .update({ status: update.status })
        .eq('id', update.id)
    }

    // Insert alerts as notifications (using existing notifications table if available)
    // For now, just log and return the alerts
    const criticalCount = alerts.filter(a => a.urgency === 'critical').length
    const warningCount = alerts.filter(a => a.urgency === 'warning').length

    return new Response(JSON.stringify({
      message: `Lien monitor complete. ${alerts.length} alerts, ${statusUpdates.length} status updates.`,
      alerts: alerts.length,
      critical: criticalCount,
      warnings: warningCount,
      statusUpdates: statusUpdates.length,
      details: alerts,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
