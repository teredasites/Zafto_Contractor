// Supabase Edge Function: plaid-sync-transactions
// Fetches new transactions from Plaid and upserts to bank_transactions.
// Maps Plaid categories to ZAFTO's 16 TransactionCategory values.
// Attempts invoice matching by amount + date proximity.

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

// Map Plaid categories to ZAFTO categories
const PLAID_CATEGORY_MAP: Record<string, string> = {
  'TRANSPORTATION': 'vehicle',
  'TRAVEL': 'vehicle',
  'GAS_STATIONS': 'fuel',
  'FUEL_AND_CNVNCE': 'fuel',
  'RENT_AND_UTILITIES': 'utilities',
  'UTILITIES': 'utilities',
  'INSURANCE': 'insurance',
  'GOVERNMENT_AND_NON_PROFIT': 'permits',
  'GENERAL_MERCHANDISE': 'materials',
  'HOME_IMPROVEMENT': 'materials',
  'BUILDING_MATERIALS': 'materials',
  'HARDWARE_STORE': 'tools',
  'GENERAL_SERVICES': 'subcontractor',
  'PROFESSIONAL_SERVICES': 'subcontractor',
  'ADVERTISING': 'advertising',
  'OFFICE_SUPPLIES': 'office',
  'INCOME': 'income',
  'TRANSFER_IN': 'transfer',
  'TRANSFER_OUT': 'transfer',
  'REFUND': 'refund',
  'PAYROLL': 'labor',
}

function mapPlaidCategory(plaidCategories: string[]): { category: string; confidence: number } {
  if (!plaidCategories || plaidCategories.length === 0) {
    return { category: 'uncategorized', confidence: 0 }
  }

  // Check from most specific to least specific
  for (let i = plaidCategories.length - 1; i >= 0; i--) {
    const upper = plaidCategories[i].toUpperCase().replace(/\s+/g, '_')
    if (PLAID_CATEGORY_MAP[upper]) {
      return {
        category: PLAID_CATEGORY_MAP[upper],
        confidence: i === plaidCategories.length - 1 ? 0.85 : 0.65,
      }
    }
  }

  return { category: 'uncategorized', confidence: 0 }
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
    const { data: creds, error: credsErr } = await supabaseAdmin
      .from('bank_credentials')
      .select('plaid_access_token')
      .eq('bank_account_id', bank_account_id)
      .eq('company_id', companyId)
      .single()

    // Fallback to bank_accounts for backward compat (until old column removed)
    let accessToken = creds?.plaid_access_token
    if (!accessToken) {
      const { data: bankAcct } = await supabaseAdmin
        .from('bank_accounts')
        .select('plaid_access_token')
        .eq('id', bank_account_id)
        .eq('company_id', companyId)
        .single()
      accessToken = bankAcct?.plaid_access_token
    }

    if (!accessToken) {
      return new Response(JSON.stringify({ error: 'Bank account not found or not linked' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Keep bankAcct reference for later use
    const bankAcct = { plaid_access_token: accessToken, company_id: companyId }

    const baseUrl = PLAID_BASE_URL[PLAID_ENV] || PLAID_BASE_URL.sandbox

    // Sync transactions using Plaid's /transactions/sync endpoint
    // This uses a cursor to get incremental updates
    const { data: lastSync } = await supabaseAdmin
      .from('bank_transactions')
      .select('created_at')
      .eq('bank_account_id', bank_account_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    // Use /transactions/get with date range
    const now = new Date()
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
    const startDate = lastSync
      ? new Date(new Date(lastSync.created_at).getTime() - 2 * 24 * 60 * 60 * 1000) // 2-day overlap
      : thirtyDaysAgo

    const txnRes = await fetch(`${baseUrl}/transactions/get`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: PLAID_CLIENT_ID,
        secret: PLAID_SECRET,
        access_token: bankAcct.plaid_access_token,
        start_date: startDate.toISOString().split('T')[0],
        end_date: now.toISOString().split('T')[0],
        options: { count: 500, offset: 0 },
      }),
    })

    const txnData = await txnRes.json()
    if (!txnRes.ok) {
      console.error('Plaid transactions error:', txnData)
      return new Response(JSON.stringify({ error: 'Failed to fetch transactions' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Fetch recent invoices for matching
    const { data: recentInvoices } = await supabaseAdmin
      .from('invoices')
      .select('id, total, due_date')
      .eq('company_id', companyId)
      .in('status', ['sent', 'overdue'])
      .gte('due_date', startDate.toISOString().split('T')[0])

    let synced = 0
    let matched = 0

    for (const txn of txnData.transactions || []) {
      const { category, confidence } = mapPlaidCategory(txn.category || [])
      const isIncome = txn.amount < 0 // Plaid: negative = money in

      // Invoice matching: look for income that matches an invoice amount + date within 5 days
      let matchedInvoiceId: string | null = null
      if (isIncome && recentInvoices) {
        const absAmount = Math.abs(txn.amount)
        const txnDate = new Date(txn.date)
        const match = recentInvoices.find((inv) => {
          const invAmount = Number(inv.total)
          const invDate = new Date(inv.due_date)
          const daysDiff = Math.abs(txnDate.getTime() - invDate.getTime()) / (1000 * 60 * 60 * 24)
          return Math.abs(absAmount - invAmount) < 0.01 && daysDiff <= 5
        })
        if (match) {
          matchedInvoiceId = match.id
          matched++
        }
      }

      const { error: upsertErr } = await supabaseAdmin
        .from('bank_transactions')
        .upsert({
          company_id: companyId,
          bank_account_id,
          plaid_transaction_id: txn.transaction_id,
          transaction_date: txn.date,
          posted_date: txn.authorized_date || null,
          description: txn.name || txn.merchant_name || 'Unknown',
          merchant_name: txn.merchant_name || null,
          amount: Math.abs(txn.amount),
          category: isIncome ? 'income' : category,
          category_confidence: confidence,
          is_income: isIncome,
          matched_invoice_id: matchedInvoiceId,
          is_reviewed: false,
          is_reconciled: false,
        }, { onConflict: 'plaid_transaction_id' })

      if (!upsertErr) synced++
    }

    // Update last_synced_at
    await supabaseAdmin
      .from('bank_accounts')
      .update({ last_synced_at: new Date().toISOString() })
      .eq('id', bank_account_id)

    return new Response(JSON.stringify({
      success: true,
      transactions_synced: synced,
      invoices_matched: matched,
      total_fetched: txnData.transactions?.length || 0,
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
