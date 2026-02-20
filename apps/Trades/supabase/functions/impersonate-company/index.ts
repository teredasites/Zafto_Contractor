// Supabase Edge Function: impersonate-company
// Allows super_admin to view any company's data for remote support.
// Creates a temporary JWT scoped to the target company.
//
// POST { company_id, action: 'start' | 'end' }
// Only accessible by super_admin role.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Create admin client for privileged operations
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify the caller is super_admin
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabaseUser.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const userRole = user.app_metadata?.role
    if (userRole !== 'super_admin' && userRole !== 'super_admin_impersonating') {
      return new Response(JSON.stringify({ error: 'Only super_admin can impersonate' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // SEC-AUDIT-4: TTL enforcement — auto-expire impersonation sessions >30 minutes
    const impersonationStartedAt = user.app_metadata?.impersonation_started_at
    if (impersonationStartedAt && userRole === 'super_admin_impersonating') {
      const startedMs = new Date(impersonationStartedAt).getTime()
      const elapsedMs = Date.now() - startedMs
      const TTL_MS = 30 * 60 * 1000 // 30 minutes

      if (elapsedMs > TTL_MS) {
        // Auto-restore original metadata
        const originalCompanyId = user.app_metadata?.original_company_id
        const originalRole = user.app_metadata?.original_role || 'super_admin'

        await supabaseAdmin.auth.admin.updateUserById(user.id, {
          app_metadata: {
            ...user.app_metadata,
            company_id: originalCompanyId,
            role: originalRole,
            original_company_id: null,
            original_role: null,
            impersonation_session_id: null,
            impersonation_started_at: null,
          },
        })

        await supabaseAdmin.from('admin_audit_log').insert({
          admin_user_id: user.id,
          admin_email: user.email || 'unknown',
          action: 'impersonate_auto_expired',
          session_id: user.app_metadata?.impersonation_session_id,
          ip_address: req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || null,
          details: { expired_at: new Date().toISOString(), elapsed_minutes: Math.round(elapsedMs / 60000) },
        })

        return new Response(JSON.stringify({
          error: 'Impersonation session expired (30 minute limit). You have been restored to your original role.',
          expired: true,
        }), {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }
    }

    const body = await req.json()
    const { company_id, action } = body

    if (!action || !['start', 'end'].includes(action)) {
      return new Response(JSON.stringify({ error: 'Invalid action. Use start or end.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const sessionId = crypto.randomUUID()

    if (action === 'start') {
      if (!company_id) {
        return new Response(JSON.stringify({ error: 'company_id required for start' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Verify company exists
      const { data: company, error: companyError } = await supabaseAdmin
        .from('companies')
        .select('id, name')
        .eq('id', company_id)
        .single()

      if (companyError || !company) {
        return new Response(JSON.stringify({ error: 'Company not found' }), {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Update user's app_metadata to impersonate
      const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
        app_metadata: {
          ...user.app_metadata,
          company_id: company_id,
          role: 'super_admin_impersonating',
          original_company_id: user.app_metadata?.company_id,
          original_role: userRole,
          impersonation_session_id: sessionId,
          impersonation_started_at: new Date().toISOString(),
        },
      })

      if (updateError) {
        return new Response(JSON.stringify({ error: 'Failed to start impersonation' }), {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })
      }

      // Log the action
      await supabaseAdmin.from('admin_audit_log').insert({
        admin_user_id: user.id,
        admin_email: user.email || 'unknown',
        action: 'impersonate_start',
        target_company_id: company_id,
        target_company_name: company.name,
        session_id: sessionId,
        ip_address: req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || null,
        user_agent: req.headers.get('user-agent') || null,
        details: { started_at: new Date().toISOString() },
      })

      return new Response(JSON.stringify({
        success: true,
        session_id: sessionId,
        company_name: company.name,
        message: `Now viewing as ${company.name}. Session expires in 30 minutes.`,
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // action === 'end'
    const originalCompanyId = user.app_metadata?.original_company_id
    const originalRole = user.app_metadata?.original_role || 'super_admin'
    const impSessionId = user.app_metadata?.impersonation_session_id

    // Restore original metadata
    const { error: restoreError } = await supabaseAdmin.auth.admin.updateUserById(user.id, {
      app_metadata: {
        ...user.app_metadata,
        company_id: originalCompanyId,
        role: originalRole,
        original_company_id: null,
        original_role: null,
        impersonation_session_id: null,
        impersonation_started_at: null,
      },
    })

    if (restoreError) {
      return new Response(JSON.stringify({ error: 'Failed to end impersonation' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Log the end
    await supabaseAdmin.from('admin_audit_log').insert({
      admin_user_id: user.id,
      admin_email: user.email || 'unknown',
      action: 'impersonate_end',
      target_company_id: user.app_metadata?.company_id,
      session_id: impSessionId || sessionId,
      ip_address: req.headers.get('x-forwarded-for') || req.headers.get('cf-connecting-ip') || null,
      user_agent: req.headers.get('user-agent') || null,
      details: { ended_at: new Date().toISOString() },
    })

    return new Response(JSON.stringify({
      success: true,
      message: 'Impersonation ended. Restored to original role.',
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : 'Internal error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
