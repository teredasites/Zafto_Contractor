// Supabase Edge Function: pm-rent-charge
// Daily cron job that auto-generates rent charges for active leases
// and applies late fees for overdue charges.
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
  status: string
  monthly_rent: number
  rent_due_day: number
  grace_period_days: number | null
  late_fee_amount: number | null
  deleted_at: string | null
}

interface RentCharge {
  id: string
  lease_id: string
  charge_type: string
  due_date: string
  status: string
  parent_charge_id: string | null
}

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
    const currentYear = now.getUTCFullYear()
    const currentMonth = now.getUTCMonth() // 0-indexed

    // First day and last day of current month
    const monthStart = new Date(Date.UTC(currentYear, currentMonth, 1)).toISOString().split('T')[0]
    const monthEnd = new Date(Date.UTC(currentYear, currentMonth + 1, 0)).toISOString().split('T')[0]

    // Query all active leases
    const { data: activeLeases, error: leaseErr } = await supabase
      .from('leases')
      .select('*')
      .eq('status', 'active')
      .is('deleted_at', null)

    if (leaseErr) {
      console.error('Failed to fetch active leases:', leaseErr)
      return new Response(JSON.stringify({ error: 'Failed to fetch leases' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const leases = (activeLeases || []) as Lease[]
    let chargesCreated = 0
    let lateFeesApplied = 0

    for (const lease of leases) {
      try {
        // --- RENT CHARGE GENERATION ---

        // Check if a rent charge already exists for this lease in the current month
        const { data: existingCharges, error: checkErr } = await supabase
          .from('rent_charges')
          .select('id')
          .eq('lease_id', lease.id)
          .eq('charge_type', 'rent')
          .gte('due_date', monthStart)
          .lte('due_date', monthEnd)

        if (checkErr) {
          console.error(`Failed to check existing charges for lease ${lease.id}:`, checkErr)
          continue
        }

        if ((!existingCharges || existingCharges.length === 0)) {
          // Calculate the due date for this month
          // Clamp rent_due_day to the last day of the month if needed
          const lastDayOfMonth = new Date(Date.UTC(currentYear, currentMonth + 1, 0)).getUTCDate()
          const clampedDay = Math.min(lease.rent_due_day || 1, lastDayOfMonth)
          const dueDate = new Date(Date.UTC(currentYear, currentMonth, clampedDay)).toISOString().split('T')[0]

          // Only generate if today >= the due day for this month
          if (today >= dueDate) {
            const { error: insertErr } = await supabase
              .from('rent_charges')
              .insert({
                company_id: lease.company_id,
                property_id: lease.property_id,
                unit_id: lease.unit_id,
                tenant_id: lease.tenant_id,
                lease_id: lease.id,
                charge_type: 'rent',
                amount: lease.monthly_rent,
                due_date: dueDate,
                status: 'pending',
                billing_period_start: monthStart,
                billing_period_end: monthEnd,
              })

            if (insertErr) {
              console.error(`Failed to insert rent charge for lease ${lease.id}:`, insertErr)
              continue
            }

            chargesCreated++
          }
        }

        // --- LATE FEE APPLICATION ---

        const gracePeriodDays = lease.grace_period_days ?? 5
        const lateFeeAmount = lease.late_fee_amount ?? 50

        // Calculate the cutoff date: charges due before this date are overdue
        const cutoffDate = new Date(now)
        cutoffDate.setUTCDate(cutoffDate.getUTCDate() - gracePeriodDays)
        const cutoffStr = cutoffDate.toISOString().split('T')[0]

        // Find pending rent charges that are past grace period
        const { data: overdueCharges, error: overdueErr } = await supabase
          .from('rent_charges')
          .select('id, lease_id, due_date, status')
          .eq('lease_id', lease.id)
          .eq('charge_type', 'rent')
          .eq('status', 'pending')
          .lt('due_date', cutoffStr)

        if (overdueErr) {
          console.error(`Failed to check overdue charges for lease ${lease.id}:`, overdueErr)
          continue
        }

        for (const overdueCharge of (overdueCharges || []) as RentCharge[]) {
          // Check if a late fee already exists for this charge
          const { data: existingLateFees, error: lateFeeCheckErr } = await supabase
            .from('rent_charges')
            .select('id')
            .eq('parent_charge_id', overdueCharge.id)
            .eq('charge_type', 'late_fee')

          if (lateFeeCheckErr) {
            console.error(`Failed to check late fee for charge ${overdueCharge.id}:`, lateFeeCheckErr)
            continue
          }

          if (!existingLateFees || existingLateFees.length === 0) {
            const { error: lateFeeInsertErr } = await supabase
              .from('rent_charges')
              .insert({
                company_id: lease.company_id,
                property_id: lease.property_id,
                unit_id: lease.unit_id,
                tenant_id: lease.tenant_id,
                lease_id: lease.id,
                charge_type: 'late_fee',
                amount: lateFeeAmount,
                due_date: today,
                status: 'pending',
                parent_charge_id: overdueCharge.id,
                billing_period_start: monthStart,
                billing_period_end: monthEnd,
              })

            if (lateFeeInsertErr) {
              console.error(`Failed to insert late fee for charge ${overdueCharge.id}:`, lateFeeInsertErr)
              continue
            }

            lateFeesApplied++
          }
        }
      } catch (leaseErr) {
        console.error(`Error processing lease ${lease.id}:`, leaseErr)
        continue
      }
    }

    console.log(`Rent charge generation complete: ${chargesCreated} charges created, ${lateFeesApplied} late fees applied out of ${leases.length} active leases`)

    return new Response(JSON.stringify({
      success: true,
      charges_created: chargesCreated,
      late_fees_applied: lateFeesApplied,
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
