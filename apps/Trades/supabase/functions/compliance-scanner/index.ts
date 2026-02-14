// Supabase Edge Function: compliance-scanner
// CRON weekly: check all certs for approaching expiry, CE credits remaining,
// job assignments vs compliance requirements. Creates notifications for issues found.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const EXPIRY_THRESHOLDS = [90, 60, 30, 14, 7]

interface ScanResult {
  company_id: string
  issue_type: 'cert_expiring' | 'cert_expired' | 'ce_credits_low' | 'renewal_overdue' | 'compliance_gap'
  severity: 'critical' | 'warning' | 'info'
  user_id: string | null
  certification_id: string | null
  message: string
  details: Record<string, unknown>
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const results: ScanResult[] = []
    const now = new Date()
    const todayStr = now.toISOString().split('T')[0]

    // ── 1. Check certifications approaching expiry ─────────
    const { data: certs, error: certErr } = await supabase
      .from('certifications')
      .select('id, company_id, user_id, certification_name, certification_type, expiration_date, status, renewal_required')
      .in('status', ['active', 'pending_renewal'])
      .not('expiration_date', 'is', null)

    if (certErr) throw certErr

    for (const cert of certs || []) {
      const expDate = new Date(cert.expiration_date)
      const daysUntil = Math.ceil((expDate.getTime() - now.getTime()) / 86400000)

      if (daysUntil < 0) {
        // Already expired — mark it
        results.push({
          company_id: cert.company_id,
          issue_type: 'cert_expired',
          severity: 'critical',
          user_id: cert.user_id,
          certification_id: cert.id,
          message: `${cert.certification_name} expired ${Math.abs(daysUntil)} days ago`,
          details: { expiration_date: cert.expiration_date, days_overdue: Math.abs(daysUntil) },
        })

        // Auto-update status to expired
        await supabase
          .from('certifications')
          .update({ status: 'expired' })
          .eq('id', cert.id)
          .eq('status', 'active')
      } else {
        // Check threshold alerts
        for (const threshold of EXPIRY_THRESHOLDS) {
          if (daysUntil <= threshold) {
            results.push({
              company_id: cert.company_id,
              issue_type: 'cert_expiring',
              severity: daysUntil <= 14 ? 'critical' : daysUntil <= 30 ? 'warning' : 'info',
              user_id: cert.user_id,
              certification_id: cert.id,
              message: `${cert.certification_name} expires in ${daysUntil} days`,
              details: { expiration_date: cert.expiration_date, days_remaining: daysUntil, threshold },
            })
            break // Only one alert per cert
          }
        }
      }
    }

    // ── 2. Check CE credits remaining ──────────────────────
    const { data: renewals, error: renewalErr } = await supabase
      .from('license_renewals')
      .select('id, company_id, user_id, certification_id, renewal_due_date, ce_credits_required, ce_credits_completed, ce_credits_remaining, status')
      .in('status', ['upcoming', 'in_progress'])

    if (renewalErr) throw renewalErr

    for (const renewal of renewals || []) {
      const dueDate = new Date(renewal.renewal_due_date)
      const daysUntilDue = Math.ceil((dueDate.getTime() - now.getTime()) / 86400000)
      const creditsRemaining = renewal.ce_credits_remaining || 0
      const creditsRequired = renewal.ce_credits_required || 0

      if (daysUntilDue < 0 && creditsRemaining > 0) {
        results.push({
          company_id: renewal.company_id,
          issue_type: 'renewal_overdue',
          severity: 'critical',
          user_id: renewal.user_id,
          certification_id: renewal.certification_id,
          message: `License renewal overdue by ${Math.abs(daysUntilDue)} days — ${creditsRemaining} CE credits still needed`,
          details: { renewal_due_date: renewal.renewal_due_date, credits_remaining: creditsRemaining },
        })

        // Auto-update to overdue
        await supabase
          .from('license_renewals')
          .update({ status: 'overdue' })
          .eq('id', renewal.id)
          .in('status', ['upcoming', 'in_progress'])
      } else if (creditsRequired > 0 && creditsRemaining > 0) {
        const completionRate = (renewal.ce_credits_completed || 0) / creditsRequired
        const timeRate = daysUntilDue > 0 ? 1 - (daysUntilDue / 365) : 1

        // Alert if behind pace (less than expected completion for time elapsed)
        if (timeRate > completionRate + 0.2 && daysUntilDue <= 90) {
          results.push({
            company_id: renewal.company_id,
            issue_type: 'ce_credits_low',
            severity: daysUntilDue <= 30 ? 'critical' : 'warning',
            user_id: renewal.user_id,
            certification_id: renewal.certification_id,
            message: `Behind on CE credits — ${creditsRemaining} of ${creditsRequired} remaining, due in ${daysUntilDue} days`,
            details: {
              credits_remaining: creditsRemaining,
              credits_required: creditsRequired,
              days_until_due: daysUntilDue,
              completion_rate: Math.round(completionRate * 100),
            },
          })
        }
      }
    }

    // ── 3. Check job assignments vs compliance ─────────────
    const { data: requirements, error: reqErr } = await supabase
      .from('compliance_requirements')
      .select('*')

    if (reqErr) throw reqErr

    // Get active jobs with assigned users
    const { data: jobs, error: jobErr } = await supabase
      .from('jobs')
      .select('id, company_id, trade_type, assigned_users')
      .in('status', ['active', 'in_progress', 'scheduled'])
      .not('assigned_users', 'is', null)

    if (!jobErr && jobs) {
      for (const job of jobs) {
        if (!job.trade_type || !job.assigned_users?.length) continue

        const tradeReqs = (requirements || []).filter(
          (r: { trade_type: string }) => r.trade_type === job.trade_type
        )
        if (!tradeReqs.length) continue

        for (const userId of job.assigned_users) {
          // Get user's active certifications
          const { data: userCerts } = await supabase
            .from('certifications')
            .select('compliance_category, status')
            .eq('user_id', userId)
            .eq('company_id', job.company_id)
            .eq('status', 'active')

          const activeCategories = new Set(
            (userCerts || []).map((c: { compliance_category: string }) => c.compliance_category)
          )

          for (const req of tradeReqs) {
            if (req.is_required && !activeCategories.has(req.required_compliance_category)) {
              results.push({
                company_id: job.company_id,
                issue_type: 'compliance_gap',
                severity: 'warning',
                user_id: userId,
                certification_id: null,
                message: `Missing required ${req.required_compliance_category} for ${job.trade_type} job`,
                details: {
                  job_id: job.id,
                  trade_type: job.trade_type,
                  missing_category: req.required_compliance_category,
                  requirement_name: req.requirement_name,
                },
              })
            }
          }
        }
      }
    }

    // ── 4. Write scan results as notifications ─────────────
    if (results.length > 0) {
      const notifications = results.map(r => ({
        company_id: r.company_id,
        user_id: r.user_id,
        type: 'compliance_alert',
        title: r.issue_type === 'cert_expired' ? 'Certification Expired'
          : r.issue_type === 'cert_expiring' ? 'Certification Expiring Soon'
          : r.issue_type === 'ce_credits_low' ? 'CE Credits Behind Schedule'
          : r.issue_type === 'renewal_overdue' ? 'Renewal Overdue'
          : 'Compliance Gap Found',
        message: r.message,
        severity: r.severity,
        metadata: r.details,
        read: false,
      }))

      // Insert in batches of 100
      for (let i = 0; i < notifications.length; i += 100) {
        const batch = notifications.slice(i, i + 100)
        await supabase.from('notifications').insert(batch)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        scan_date: todayStr,
        issues_found: results.length,
        breakdown: {
          cert_expired: results.filter(r => r.issue_type === 'cert_expired').length,
          cert_expiring: results.filter(r => r.issue_type === 'cert_expiring').length,
          ce_credits_low: results.filter(r => r.issue_type === 'ce_credits_low').length,
          renewal_overdue: results.filter(r => r.issue_type === 'renewal_overdue').length,
          compliance_gap: results.filter(r => r.issue_type === 'compliance_gap').length,
        },
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
