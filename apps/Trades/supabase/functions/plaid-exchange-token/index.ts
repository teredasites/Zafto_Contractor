// Supabase Edge Function: plaid-exchange-token
// Exchanges a Plaid public_token for an access_token after Link flow.
// Stores access_token securely in bank_accounts (never exposed to frontend).

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

    const { public_token, institution } = await req.json()
    if (!public_token) {
      return new Response(JSON.stringify({ error: 'Missing public_token' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Auth user
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

    const baseUrl = PLAID_BASE_URL[PLAID_ENV] || PLAID_BASE_URL.sandbox

    // Exchange public_token for access_token
    const exchangeRes = await fetch(`${baseUrl}/item/public_token/exchange`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: PLAID_CLIENT_ID,
        secret: PLAID_SECRET,
        public_token,
      }),
    })

    const exchangeData = await exchangeRes.json()
    if (!exchangeRes.ok) {
      console.error('Plaid exchange error:', exchangeData)
      return new Response(JSON.stringify({ error: 'Token exchange failed' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const accessToken = exchangeData.access_token
    const itemId = exchangeData.item_id

    // Fetch accounts from Plaid
    const accountsRes = await fetch(`${baseUrl}/accounts/get`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: PLAID_CLIENT_ID,
        secret: PLAID_SECRET,
        access_token: accessToken,
      }),
    })

    const accountsData = await accountsRes.json()
    if (!accountsRes.ok) {
      console.error('Plaid accounts error:', accountsData)
      return new Response(JSON.stringify({ error: 'Failed to fetch accounts' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Use service role to write access_token (bypasses RLS for secure column)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const institutionName = institution?.name || accountsData.item?.institution_id || 'Unknown'
    const inserted: string[] = []

    for (const acct of accountsData.accounts) {
      const accountType = acct.type === 'credit' ? 'credit_card'
        : acct.subtype === 'savings' ? 'savings'
        : 'checking'

      const { data: row, error: insertErr } = await supabaseAdmin
        .from('bank_accounts')
        .upsert({
          company_id: companyId,
          plaid_item_id: itemId,
          plaid_account_id: acct.account_id,
          account_name: acct.official_name || acct.name,
          institution_name: institutionName,
          account_type: accountType,
          mask: acct.mask,
          current_balance: acct.balances?.current ?? 0,
          available_balance: acct.balances?.available ?? null,
          plaid_access_token: accessToken,
          last_synced_at: new Date().toISOString(),
          is_active: true,
        }, { onConflict: 'plaid_account_id' })
        .select('id')
        .single()

      if (!insertErr && row) {
        inserted.push(row.id)
      }
    }

    return new Response(JSON.stringify({
      success: true,
      accounts_linked: inserted.length,
      item_id: itemId,
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
