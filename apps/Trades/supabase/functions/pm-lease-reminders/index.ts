// Supabase Edge Function: pm-lease-reminders
// Daily cron job that sends notifications for expiring leases.
// Notifies owner/admin users at 90, 60, and 30 day milestones.
// Runs with service role key — no user auth required.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface Lease {
  id: string
  company_id: string
  property_id: string
  unit_id: string | null
  tenant_id: string
  tenant_name: string | null
  end_date: string
  status: string
  deleted_at: string | null
  properties?: { name: string } | null
  units?: { unit_number: string } | null
  tenants?: { name: string } | null
}

interface AdminUser {
  id: string
  company_id: string
  role: string
}

const REMINDER_MILESTONES = [90, 60, 30]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const now = new Date()
    const today = now.toISOString().split('T')[0]

    // Query active leases with an end_date, joining property/unit/tenant for message context
    const { data: activeLeases, error: leaseErr } = await supabase
      .from('leases')
      .select('id, company_id, property_id, unit_id, tenant_id, end_date, properties(name), units(unit_number), tenants(name)')
      .eq('status', 'active')
      .not('end_date', 'is', null)
      .is('deleted_at', null)

    if (leaseErr) {
      console.error('Failed to fetch active leases:', leaseErr)
      return new Response(JSON.stringify({ error: 'Failed to fetch leases' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const leases = (activeLeases || []) as Lease[]
    let remindersSent = 0

    // Cache of company_id -> admin/owner user IDs to avoid repeated queries
    const adminCache: Record<string, string[]> = {}

    for (const lease of leases) {
      try {
        // Calculate days until expiry
        const endDate = new Date(lease.end_date + 'T00:00:00Z')
        const todayDate = new Date(today + 'T00:00:00Z')
        const diffMs = endDate.getTime() - todayDate.getTime()
        const daysUntilExpiry = Math.round(diffMs / (1000 * 60 * 60 * 24))

        // Only send notifications at exact milestones
        if (!REMINDER_MILESTONES.includes(daysUntilExpiry)) {
          continue
        }

        // Get owner/admin users for this company (use cache)
        if (!adminCache[lease.company_id]) {
          const { data: admins, error: adminErr } = await supabase
            .from('users')
            .select('id, company_id, role')
            .eq('company_id', lease.company_id)
            .in('role', ['owner', 'admin'])

          if (adminErr) {
            console.error(`Failed to fetch admins for company ${lease.company_id}:`, adminErr)
            continue
          }

          adminCache[lease.company_id] = ((admins || []) as AdminUser[]).map((u) => u.id)
        }

        const adminUserIds = adminCache[lease.company_id]
        if (adminUserIds.length === 0) {
          console.error(`No owner/admin users found for company ${lease.company_id}`)
          continue
        }

        // Build notification message
        const tenantName = (lease.tenants as { name: string } | null)?.name || 'Unknown tenant'
        const propertyName = (lease.properties as { name: string } | null)?.name || 'Unknown property'
        const unitNumber = (lease.units as { unit_number: string } | null)?.unit_number || ''
        const unitStr = unitNumber ? ` Unit ${unitNumber}` : ''

        const message = `${tenantName} lease at ${propertyName}${unitStr} expires in ${daysUntilExpiry} days`

        // Insert a notification for each admin/owner user
        for (const userId of adminUserIds) {
          const { error: notifErr } = await supabase
            .from('notifications')
            .insert({
              company_id: lease.company_id,
              user_id: userId,
              type: 'lease_expiring',
              title: 'Lease Expiring Soon',
              message,
              data: {
                lease_id: lease.id,
                tenant_id: lease.tenant_id,
                property_id: lease.property_id,
                unit_id: lease.unit_id,
                days_until_expiry: daysUntilExpiry,
              },
            })

          if (notifErr) {
            console.error(`Failed to insert notification for user ${userId}, lease ${lease.id}:`, notifErr)
            continue
          }

          remindersSent++
        }
      } catch (leaseProcessErr) {
        console.error(`Error processing lease ${lease.id}:`, leaseProcessErr)
        continue
      }
    }

    console.log(`Lease reminders complete: ${remindersSent} reminders sent across ${leases.length} active leases`)

    return new Response(JSON.stringify({
      success: true,
      reminders_sent: remindersSent,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('Error:', err)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
