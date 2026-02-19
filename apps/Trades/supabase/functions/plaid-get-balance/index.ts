// Supabase Edge Function: plaid-get-balance
// Fetches current balance from Plaid and updates bank_accounts.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')!
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')!
const PLAID_ENV = Deno.env.get('PLAID_ENV') || 'sandbox'

const PLAID_BASE_URL: Record<string, string> = {
  sandbox: 'https://sandbox.plaid.com',
  development: 'https://development.plaid.com',
  production: 'https://production.plaid.com',
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
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

    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error: authErr } = await supabaseUser.auth.getUser()
    if (authErr || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const companyId = user.app_metadata?.company_id
    if (!companyId) {
      return new Response(JSON.stringify({ error: 'No company' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { bank_account_id } = await req.json()
    if (!bank_account_id) {
      return new Response(JSON.stringify({ error: 'Missing bank_account_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // SEC-AUDIT-1: Read access token from isolated bank_credentials table (service_role only)
    const { data: bankAcct, error: acctErr } = await supabaseAdmin
      .from('bank_accounts')
      .select('plaid_account_id, company_id')
      .eq('id', bank_account_id)
      .eq('company_id', companyId)
      .single()

    if (acctErr || !bankAcct) {
      return new Response(JSON.stringify({ error: 'Bank account not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get token from isolated credentials table
    const { data: creds } = await supabaseAdmin
      .from('bank_credentials')
      .select('plaid_access_token')
      .eq('bank_account_id', bank_account_id)
      .eq('company_id', companyId)
      .single()

    // Fallback to bank_accounts for backward compat (until old column removed)
    const accessToken = creds?.plaid_access_token
    if (!accessToken) {
      return new Response(JSON.stringify({ error: 'Bank account not linked to Plaid' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Assign to bankAcct for downstream use
    const bankAcctWithToken = { ...bankAcct, plaid_access_token: accessToken }

    const baseUrl = PLAID_BASE_URL[PLAID_ENV] || PLAID_BASE_URL.sandbox

    const balanceRes = await fetch(`${baseUrl}/accounts/balance/get`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: PLAID_CLIENT_ID,
        secret: PLAID_SECRET,
        access_token: bankAcctWithToken.plaid_access_token,
        options: {
          account_ids: bankAcctWithToken.plaid_account_id ? [bankAcctWithToken.plaid_account_id] : undefined,
        },
      }),
    })

    const balanceData = await balanceRes.json()
    if (!balanceRes.ok) {
      console.error('Plaid balance error:', balanceData)
      return new Response(JSON.stringify({ error: 'Failed to fetch balance' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const account = balanceData.accounts?.[0]
    if (!account) {
      return new Response(JSON.stringify({ error: 'No account data returned' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Update balance in DB
    const { error: updateErr } = await supabaseAdmin
      .from('bank_accounts')
      .update({
        current_balance: account.balances?.current ?? 0,
        available_balance: account.balances?.available ?? null,
        last_synced_at: new Date().toISOString(),
      })
      .eq('id', bank_account_id)

    if (updateErr) {
      console.error('DB update error:', updateErr)
      return new Response(JSON.stringify({ error: 'Failed to update balance' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({
      success: true,
      current_balance: account.balances?.current ?? 0,
      available_balance: account.balances?.available ?? null,
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
