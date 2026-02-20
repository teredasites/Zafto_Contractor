// Supabase Edge Function: code-verify
// Crowdsource verification pipeline for estimate code contributions.
// GET: returns contribution stats + queue (pending, verified, promoted)
// POST: manually verify/reject a contribution (Ops Portal admin action)
// POST action=promote-all: batch-promote verified codes (3+ verifications) to estimate_items

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limiter.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const VERIFICATION_THRESHOLD = 3

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
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

  // Verify user is super_admin via JWT app_metadata (no DB roundtrip)
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabase.auth.getUser(token)
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // SEC-AUDIT-3: Use app_metadata.role instead of public.users table lookup
  const userRole = user.app_metadata?.role
  if (userRole !== 'super_admin') {
    return new Response(JSON.stringify({ error: 'Requires super_admin role' }), {
      status: 403,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  // Rate limit: 30 requests per minute per user
  const rateCheck = await checkRateLimit(supabase, {
    key: `user:${user.id}:code-verify`,
    maxRequests: 30,
    windowSeconds: 60,
  })
  if (!rateCheck.allowed) return rateLimitResponse(rateCheck.retryAfter!)

  try {
    // ── GET: Return stats + contribution queue ──
    if (req.method === 'GET') {
      const url = new URL(req.url)
      const status = url.searchParams.get('status') || 'all' // all, pending, verified, promoted
      const page = Number(url.searchParams.get('page') || '1')
      const pageSize = Number(url.searchParams.get('page_size') || '50')
      const offset = (page - 1) * pageSize

      // Stats
      const { count: totalCount } = await supabase
        .from('code_contributions')
        .select('*', { count: 'exact', head: true })

      const { count: pendingCount } = await supabase
        .from('code_contributions')
        .select('*', { count: 'exact', head: true })
        .eq('verified', false)
        .is('promoted_item_id', null)

      const { count: verifiedCount } = await supabase
        .from('code_contributions')
        .select('*', { count: 'exact', head: true })
        .eq('verified', true)
        .is('promoted_item_id', null)

      const { count: promotedCount } = await supabase
        .from('code_contributions')
        .select('*', { count: 'exact', head: true })
        .not('promoted_item_id', 'is', null)

      const { count: readyCount } = await supabase
        .from('code_contributions')
        .select('*', { count: 'exact', head: true })
        .gte('verification_count', VERIFICATION_THRESHOLD)
        .eq('verified', false)
        .is('promoted_item_id', null)

      // Build query
      let query = supabase
        .from('code_contributions')
        .select('*')
        .order('verification_count', { ascending: false })
        .order('created_at', { ascending: false })
        .range(offset, offset + pageSize - 1)

      if (status === 'pending') {
        query = query.eq('verified', false).is('promoted_item_id', null)
      } else if (status === 'verified') {
        query = query.eq('verified', true).is('promoted_item_id', null)
      } else if (status === 'promoted') {
        query = query.not('promoted_item_id', 'is', null)
      } else if (status === 'ready') {
        query = query.gte('verification_count', VERIFICATION_THRESHOLD).eq('verified', false).is('promoted_item_id', null)
      }

      const { data: contributions, error: listError } = await query

      if (listError) {
        return new Response(JSON.stringify({ error: 'Failed to fetch contributions', detail: listError.message }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      return new Response(JSON.stringify({
        stats: {
          total: totalCount || 0,
          pending: pendingCount || 0,
          verified: verifiedCount || 0,
          promoted: promotedCount || 0,
          ready_to_promote: readyCount || 0,
          threshold: VERIFICATION_THRESHOLD,
        },
        contributions: contributions || [],
        page,
        page_size: pageSize,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // ── POST: Actions ──
    if (req.method === 'POST') {
      const body = await req.json()
      const action = body.action as string

      // Action: promote-all — batch promote verified codes to estimate_items
      if (action === 'promote-all') {
        const { data: ready } = await supabase
          .from('code_contributions')
          .select('*')
          .gte('verification_count', VERIFICATION_THRESHOLD)
          .is('promoted_item_id', null)

        if (!ready || ready.length === 0) {
          return new Response(JSON.stringify({ success: true, promoted: 0, message: 'No contributions ready for promotion' }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        let promoted = 0
        for (const contrib of ready) {
          // Find or create category
          const { data: category } = await supabase
            .from('estimate_categories')
            .select('id')
            .eq('code', contrib.industry_code)
            .maybeSingle()

          if (!category) continue // Skip if no matching category

          // Generate zafto_code
          const zaftoCode = `${contrib.industry_code}-${contrib.industry_selector}`.toUpperCase()

          // Check if item already exists
          const { data: existingItem } = await supabase
            .from('estimate_items')
            .select('id')
            .eq('zafto_code', zaftoCode)
            .is('company_id', null)
            .maybeSingle()

          if (existingItem) {
            // Already exists — just mark contribution as promoted
            await supabase
              .from('code_contributions')
              .update({ verified: true, promoted_item_id: existingItem.id })
              .eq('id', contrib.id)
            promoted++
            continue
          }

          // Create new estimate_item
          const { data: newItem, error: itemError } = await supabase
            .from('estimate_items')
            .insert({
              category_id: category.id,
              company_id: null, // Global item (not company-specific)
              zafto_code: zaftoCode,
              industry_code: contrib.industry_code,
              industry_selector: contrib.industry_selector,
              description: contrib.description,
              unit_code: contrib.unit_code || 'EA',
              action_types: [contrib.action_type || 'add'],
              trade: contrib.trade || contrib.industry_code,
              source: 'contributed',
              is_common: false,
            })
            .select('id')
            .single()

          if (itemError || !newItem) continue

          // Mark contribution as promoted
          await supabase
            .from('code_contributions')
            .update({ verified: true, promoted_item_id: newItem.id })
            .eq('id', contrib.id)

          promoted++
        }

        return new Response(JSON.stringify({
          success: true,
          promoted,
          total_ready: ready.length,
        }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Action: verify — manually verify a single contribution
      if (action === 'verify') {
        const contributionId = body.contribution_id as string
        if (!contributionId) {
          return new Response(JSON.stringify({ error: 'contribution_id required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const { error: updateError } = await supabase
          .from('code_contributions')
          .update({ verified: true, verification_count: VERIFICATION_THRESHOLD })
          .eq('id', contributionId)

        if (updateError) {
          return new Response(JSON.stringify({ error: 'Failed to verify', detail: updateError.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        return new Response(JSON.stringify({ success: true, action: 'verified', contribution_id: contributionId }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Action: reject — delete a contribution
      if (action === 'reject') {
        const contributionId = body.contribution_id as string
        if (!contributionId) {
          return new Response(JSON.stringify({ error: 'contribution_id required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const { error: deleteError } = await supabase
          .from('code_contributions')
          .delete()
          .eq('id', contributionId)

        if (deleteError) {
          return new Response(JSON.stringify({ error: 'Failed to reject', detail: deleteError.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        return new Response(JSON.stringify({ success: true, action: 'rejected', contribution_id: contributionId }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Action: promote-one — manually promote a single contribution
      if (action === 'promote-one') {
        const contributionId = body.contribution_id as string
        if (!contributionId) {
          return new Response(JSON.stringify({ error: 'contribution_id required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const { data: contrib } = await supabase
          .from('code_contributions')
          .select('*')
          .eq('id', contributionId)
          .single()

        if (!contrib) {
          return new Response(JSON.stringify({ error: 'Contribution not found' }), {
            status: 404,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        // Find category
        const { data: category } = await supabase
          .from('estimate_categories')
          .select('id')
          .eq('code', contrib.industry_code)
          .maybeSingle()

        if (!category) {
          return new Response(JSON.stringify({ error: `No category found for code: ${contrib.industry_code}` }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const zaftoCode = `${contrib.industry_code}-${contrib.industry_selector}`.toUpperCase()

        // Check if item already exists
        const { data: existingItem } = await supabase
          .from('estimate_items')
          .select('id')
          .eq('zafto_code', zaftoCode)
          .is('company_id', null)
          .maybeSingle()

        if (existingItem) {
          await supabase
            .from('code_contributions')
            .update({ verified: true, promoted_item_id: existingItem.id })
            .eq('id', contrib.id)

          return new Response(JSON.stringify({ success: true, action: 'promoted', item_id: existingItem.id, already_existed: true }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        const { data: newItem, error: itemError } = await supabase
          .from('estimate_items')
          .insert({
            category_id: category.id,
            company_id: null,
            zafto_code: zaftoCode,
            industry_code: contrib.industry_code,
            industry_selector: contrib.industry_selector,
            description: contrib.description,
            unit_code: contrib.unit_code || 'EA',
            action_types: [contrib.action_type || 'add'],
            trade: contrib.trade || contrib.industry_code,
            source: 'contributed',
            is_common: false,
          })
          .select('id')
          .single()

        if (itemError || !newItem) {
          return new Response(JSON.stringify({ error: 'Failed to create item', detail: itemError?.message }), {
            status: 500,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          })
        }

        await supabase
          .from('code_contributions')
          .update({ verified: true, promoted_item_id: newItem.id })
          .eq('id', contrib.id)

        return new Response(JSON.stringify({ success: true, action: 'promoted', item_id: newItem.id }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      return new Response(JSON.stringify({ error: `Unknown action: ${action}` }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('code-verify error:', err)
    return new Response(JSON.stringify({ error: 'Internal error', detail: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
