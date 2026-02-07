// Supabase Edge Function: recurring-generate
// Daily cron job that auto-generates expenses/invoices from recurring templates.
// Runs with service role key — no user auth required.

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RecurringTemplate {
  id: string
  company_id: string
  template_name: string
  transaction_type: 'expense' | 'invoice'
  frequency: 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'annually'
  next_occurrence: string
  end_date: string | null
  template_data: Record<string, unknown>
  account_id: string | null
  vendor_id: string | null
  job_id: string | null
  is_active: boolean
  times_generated: number
  created_by_user_id: string
}

function calculateNextOccurrence(
  currentDate: string,
  frequency: RecurringTemplate['frequency']
): string {
  const d = new Date(currentDate + 'T00:00:00Z')
  switch (frequency) {
    case 'weekly':
      d.setUTCDate(d.getUTCDate() + 7)
      break
    case 'biweekly':
      d.setUTCDate(d.getUTCDate() + 14)
      break
    case 'monthly':
      d.setUTCMonth(d.getUTCMonth() + 1)
      break
    case 'quarterly':
      d.setUTCMonth(d.getUTCMonth() + 3)
      break
    case 'annually':
      d.setUTCFullYear(d.getUTCFullYear() + 1)
      break
  }
  return d.toISOString().split('T')[0]
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

    const today = new Date().toISOString().split('T')[0]

    // Query all active templates that are due today or overdue
    const { data: dueTemplates, error: fetchErr } = await supabase
      .from('recurring_transactions')
      .select('*')
      .eq('is_active', true)
      .lte('next_occurrence', today)

    if (fetchErr) {
      console.error('Failed to fetch due templates:', fetchErr)
      return new Response(JSON.stringify({ error: 'Failed to fetch templates' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const templates = (dueTemplates || []) as RecurringTemplate[]
    let generated = 0
    let deactivated = 0

    for (const template of templates) {
      try {
        const td = template.template_data

        // Generate based on transaction type
        if (template.transaction_type === 'expense') {
          const amount = Number(td.amount || 0)
          const taxAmount = Number(td.tax_amount || 0)

          const { error: insertErr } = await supabase
            .from('expense_records')
            .insert({
              company_id: template.company_id,
              vendor_id: template.vendor_id || (td.vendor_id as string) || null,
              expense_date: template.next_occurrence,
              description: (td.description as string) || template.template_name,
              amount,
              tax_amount: taxAmount,
              total: amount + taxAmount,
              category: (td.category as string) || 'uncategorized',
              account_id: template.account_id || (td.account_id as string) || null,
              job_id: template.job_id || (td.job_id as string) || null,
              payment_method: (td.payment_method as string) || 'bank_transfer',
              status: 'draft',
              notes: `Auto-generated from recurring template: ${template.template_name} (ID: ${template.id})`,
              created_by_user_id: template.created_by_user_id,
            })

          if (insertErr) {
            console.error(`Failed to generate expense for template ${template.id}:`, insertErr)
            continue
          }
        } else {
          // Invoice
          const amount = Number(td.amount || 0)
          const taxRate = Number(td.tax_rate || 0)
          const taxAmount = amount * (taxRate / 100)
          const total = amount + taxAmount

          // Auto-generate invoice number
          const year = new Date().getFullYear()
          const { count } = await supabase
            .from('invoices')
            .select('*', { count: 'exact', head: true })
            .eq('company_id', template.company_id)
            .ilike('invoice_number', `INV-${year}-%`)

          const seq = String((count || 0) + 1).padStart(4, '0')
          const invoiceNumber = `INV-${year}-${seq}`

          const { error: insertErr } = await supabase
            .from('invoices')
            .insert({
              company_id: template.company_id,
              created_by_user_id: template.created_by_user_id,
              customer_id: (td.customer_id as string) || null,
              job_id: template.job_id || (td.job_id as string) || null,
              invoice_number: invoiceNumber,
              customer_name: (td.customer_name as string) || '',
              customer_email: (td.customer_email as string) || null,
              line_items: (td.line_items as unknown[]) || [
                { description: template.template_name, quantity: 1, unit_price: amount, amount },
              ],
              subtotal: amount,
              tax_rate: taxRate,
              tax_amount: taxAmount,
              total,
              amount_paid: 0,
              amount_due: total,
              status: 'draft',
              due_date: (td.due_date_offset as number)
                ? new Date(Date.now() + (td.due_date_offset as number) * 86400000).toISOString()
                : new Date(Date.now() + 30 * 86400000).toISOString(),
              notes: `Auto-generated from recurring template: ${template.template_name} (ID: ${template.id})`,
            })

          if (insertErr) {
            console.error(`Failed to generate invoice for template ${template.id}:`, insertErr)
            continue
          }
        }

        generated++

        // Calculate next occurrence
        const nextOcc = calculateNextOccurrence(template.next_occurrence, template.frequency)

        // Check if next occurrence exceeds end date
        const shouldDeactivate = template.end_date !== null && nextOcc > template.end_date
        if (shouldDeactivate) {
          deactivated++
        }

        // Update the template
        const { error: updateErr } = await supabase
          .from('recurring_transactions')
          .update({
            next_occurrence: nextOcc,
            last_generated_at: new Date().toISOString(),
            times_generated: template.times_generated + 1,
            is_active: shouldDeactivate ? false : true,
            updated_at: new Date().toISOString(),
          })
          .eq('id', template.id)

        if (updateErr) {
          console.error(`Failed to update template ${template.id} after generation:`, updateErr)
        }
      } catch (templateErr) {
        console.error(`Error processing template ${template.id}:`, templateErr)
        continue
      }
    }

    console.log(`Recurring generation complete: ${generated} generated, ${deactivated} deactivated out of ${templates.length} due`)

    return new Response(JSON.stringify({
      success: true,
      due: templates.length,
      generated,
      deactivated,
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
