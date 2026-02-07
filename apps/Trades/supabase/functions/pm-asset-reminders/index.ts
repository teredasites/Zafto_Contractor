// Supabase Edge Function: pm-asset-reminders
// Daily cron job that sends notifications for property assets needing service.
// 2-week lookahead with duplicate notification prevention.
// Runs with service role key — no user auth required.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PropertyAsset {
  id: string
  company_id: string
  property_id: string
  asset_type: string
  next_service_date: string
  deleted_at: string | null
  properties?: { name: string } | null
}

interface AdminUser {
  id: string
  company_id: string
  role: string
}

const LOOKAHEAD_DAYS = 14

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

    // Calculate the lookahead cutoff date (today + 14 days)
    const lookaheadDate = new Date(now)
    lookaheadDate.setUTCDate(lookaheadDate.getUTCDate() + LOOKAHEAD_DAYS)
    const lookaheadStr = lookaheadDate.toISOString().split('T')[0]

    // Calculate 14 days ago for duplicate notification check
    const duplicateCheckDate = new Date(now)
    duplicateCheckDate.setUTCDate(duplicateCheckDate.getUTCDate() - LOOKAHEAD_DAYS)
    const duplicateCheckStr = duplicateCheckDate.toISOString().split('T')[0]

    // Query assets due for service within the lookahead window
    const { data: dueAssets, error: assetErr } = await supabase
      .from('property_assets')
      .select('id, company_id, property_id, asset_type, next_service_date, properties(name)')
      .not('next_service_date', 'is', null)
      .lte('next_service_date', lookaheadStr)
      .is('deleted_at', null)

    if (assetErr) {
      console.error('Failed to fetch due assets:', assetErr)
      return new Response(JSON.stringify({ error: 'Failed to fetch assets' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const assets = (dueAssets || []) as PropertyAsset[]
    let remindersSent = 0

    // Cache of company_id -> admin/owner user IDs
    const adminCache: Record<string, string[]> = {}

    for (const asset of assets) {
      try {
        // Check if a notification already exists for this asset in the last 14 days
        // We look for notifications with type 'asset_service_due' that contain this asset_id in the data
        const { data: existingNotifs, error: notifCheckErr } = await supabase
          .from('notifications')
          .select('id')
          .eq('type', 'asset_service_due')
          .eq('company_id', asset.company_id)
          .gte('created_at', duplicateCheckStr + 'T00:00:00Z')
          .contains('data', { asset_id: asset.id })

        if (notifCheckErr) {
          console.error(`Failed to check existing notifications for asset ${asset.id}:`, notifCheckErr)
          continue
        }

        if (existingNotifs && existingNotifs.length > 0) {
          // Notification already sent recently, skip
          continue
        }

        // Get owner/admin users for this company (use cache)
        if (!adminCache[asset.company_id]) {
          const { data: admins, error: adminErr } = await supabase
            .from('users')
            .select('id, company_id, role')
            .eq('company_id', asset.company_id)
            .in('role', ['owner', 'admin'])

          if (adminErr) {
            console.error(`Failed to fetch admins for company ${asset.company_id}:`, adminErr)
            continue
          }

          adminCache[asset.company_id] = ((admins || []) as AdminUser[]).map((u) => u.id)
        }

        const adminUserIds = adminCache[asset.company_id]
        if (adminUserIds.length === 0) {
          console.error(`No owner/admin users found for company ${asset.company_id}`)
          continue
        }

        // Build notification message
        const propertyName = (asset.properties as { name: string } | null)?.name || 'Unknown property'
        const serviceDate = asset.next_service_date

        const message = `${asset.asset_type} at ${propertyName} due for service on ${serviceDate}`

        // Insert a notification for each admin/owner user
        for (const userId of adminUserIds) {
          const { error: notifErr } = await supabase
            .from('notifications')
            .insert({
              company_id: asset.company_id,
              user_id: userId,
              type: 'asset_service_due',
              title: 'Asset Service Due',
              message,
              data: {
                asset_id: asset.id,
                property_id: asset.property_id,
                next_service_date: serviceDate,
              },
            })

          if (notifErr) {
            console.error(`Failed to insert notification for user ${userId}, asset ${asset.id}:`, notifErr)
            continue
          }

          remindersSent++
        }
      } catch (assetProcessErr) {
        console.error(`Error processing asset ${asset.id}:`, assetProcessErr)
        continue
      }
    }

    console.log(`Asset reminders complete: ${remindersSent} reminders sent across ${assets.length} due assets`)

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
