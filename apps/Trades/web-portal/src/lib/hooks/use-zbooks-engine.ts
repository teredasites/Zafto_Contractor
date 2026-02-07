'use client';

import { getSupabase } from '@/lib/supabase';

// ============================================================
// ZBooks GL Engine — Auto-posting journal entries
// This is the heart of ZBooks double-entry bookkeeping.
// Every financial event creates balanced journal entries.
// ============================================================

// Revenue account mapping by job type
const REVENUE_ACCOUNT_MAP: Record<string, string> = {
  standard: '4000',
  insurance_claim: '4010',
  warranty_dispatch: '4020',
  maintenance: '4030',
};

// Category → expense account mapping
const CATEGORY_ACCOUNT_MAP: Record<string, string> = {
  materials: '5000',
  labor: '5100',
  subcontractor: '5200',
  equipment: '5300',
  permits: '5400',
  fuel: '6500',
  tools: '6600',
  vehicle: '6510',
  insurance: '6100',
  advertising: '6000',
  office: '6200',
  utilities: '6400',
  uncategorized: '6900',
  refund: '4900',
  transfer: '1010',
  income: '4900',
};

// Payment method → credit account
const PAYMENT_METHOD_ACCOUNT_MAP: Record<string, string> = {
  cash: '1000',
  check: '1010',
  credit_card: '2100',
  bank_transfer: '1010',
  other: '1010',
};

interface AccountLookup {
  id: string;
  account_number: string;
}

// Resolve a COA account by number for the current company
async function resolveAccount(accountNumber: string): Promise<string> {
  const supabase = getSupabase();
  const { data } = await supabase
    .from('chart_of_accounts')
    .select('id')
    .eq('account_number', accountNumber)
    .eq('is_active', true)
    .single();

  if (!data) throw new Error(`GL account ${accountNumber} not found`);
  return data.id;
}

// Generate next journal entry number: JE-YYYYMMDD-NNN
async function generateEntryNumber(): Promise<string> {
  const supabase = getSupabase();
  const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const prefix = `JE-${today}-`;

  const { count } = await supabase
    .from('journal_entries')
    .select('*', { count: 'exact', head: true })
    .ilike('entry_number', `${prefix}%`);

  const seq = String((count || 0) + 1).padStart(3, '0');
  return `${prefix}${seq}`;
}

// Check if entry date falls in a closed fiscal period
async function checkFiscalPeriodOpen(entryDate: string): Promise<void> {
  const supabase = getSupabase();
  const { data: closedPeriods } = await supabase
    .from('fiscal_periods')
    .select('id, period_name')
    .eq('is_closed', true)
    .lte('start_date', entryDate)
    .gte('end_date', entryDate);

  if (closedPeriods && closedPeriods.length > 0) {
    throw new Error(`Cannot post to closed fiscal period: ${closedPeriods[0].period_name}`);
  }
}

// Write to zbooks_audit_log (fire-and-forget)
async function writeAuditLog(
  action: string,
  tableName: string,
  recordId: string,
  previousValues?: Record<string, unknown>,
  newValues?: Record<string, unknown>,
  changeSummary?: string
): Promise<void> {
  try {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase.from('zbooks_audit_log').insert({
      company_id: user.app_metadata?.company_id,
      user_id: user.id,
      action,
      table_name: tableName,
      record_id: recordId,
      previous_values: previousValues || null,
      new_values: newValues || null,
      change_summary: changeSummary || null,
    });
  } catch (_) {
    // Fire-and-forget — audit failure should not block financial operations
  }
}

// ============================================================
// CORE: Create and post a journal entry with lines
// ============================================================
interface JournalLine {
  accountNumber: string;
  debit: number;
  credit: number;
  description?: string;
  jobId?: string;
}

async function createAndPostJournalEntry(params: {
  description: string;
  sourceType: string;
  sourceId: string;
  entryDate: string;
  lines: JournalLine[];
  memo?: string;
}): Promise<string> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const companyId = user.app_metadata?.company_id;
  if (!companyId) throw new Error('No company associated');

  // Validate debit/credit balance
  const totalDebit = params.lines.reduce((sum, l) => sum + l.debit, 0);
  const totalCredit = params.lines.reduce((sum, l) => sum + l.credit, 0);
  const diff = Math.abs(totalDebit - totalCredit);
  if (diff > 0.005) {
    throw new Error(`Journal entry unbalanced: debits=${totalDebit.toFixed(2)} credits=${totalCredit.toFixed(2)}`);
  }

  // Check fiscal period
  await checkFiscalPeriodOpen(params.entryDate);

  // Generate entry number
  const entryNumber = await generateEntryNumber();

  // Resolve account IDs
  const accountIds = new Map<string, string>();
  for (const line of params.lines) {
    if (!accountIds.has(line.accountNumber)) {
      accountIds.set(line.accountNumber, await resolveAccount(line.accountNumber));
    }
  }

  // Create journal entry
  const { data: entry, error: entryErr } = await supabase
    .from('journal_entries')
    .insert({
      company_id: companyId,
      entry_number: entryNumber,
      entry_date: params.entryDate,
      description: params.description,
      status: 'posted',
      source_type: params.sourceType,
      source_id: params.sourceId,
      posted_at: new Date().toISOString(),
      posted_by_user_id: user.id,
      memo: params.memo || null,
      created_by_user_id: user.id,
    })
    .select('id')
    .single();

  if (entryErr) throw entryErr;

  // Create lines
  const lineInserts = params.lines.map((line) => ({
    journal_entry_id: entry.id,
    account_id: accountIds.get(line.accountNumber)!,
    debit_amount: Number(line.debit.toFixed(2)),
    credit_amount: Number(line.credit.toFixed(2)),
    description: line.description || null,
    job_id: line.jobId || null,
  }));

  const { error: linesErr } = await supabase
    .from('journal_entry_lines')
    .insert(lineInserts);

  if (linesErr) throw linesErr;

  // Audit log
  await writeAuditLog('posted', 'journal_entries', entry.id, undefined, {
    entry_number: entryNumber,
    source_type: params.sourceType,
    total_debit: totalDebit,
    total_credit: totalCredit,
    line_count: params.lines.length,
  }, `Posted ${entryNumber}: ${params.description}`);

  return entry.id;
}

// ============================================================
// AUTO-POSTING: Invoice Sent → AR debit + Revenue credit
// ============================================================
export async function createInvoiceJournal(invoiceId: string): Promise<string | null> {
  try {
    const supabase = getSupabase();

    // Fetch invoice with job type
    const { data: inv } = await supabase
      .from('invoices')
      .select('id, invoice_number, total, tax_amount, job_id')
      .eq('id', invoiceId)
      .single();

    if (!inv || inv.total <= 0) return null;

    // Determine revenue account from job type
    let revenueAccountNumber = '4000'; // default retail
    if (inv.job_id) {
      const { data: job } = await supabase
        .from('jobs')
        .select('job_type')
        .eq('id', inv.job_id)
        .single();
      if (job?.job_type) {
        revenueAccountNumber = REVENUE_ACCOUNT_MAP[job.job_type] || '4000';
      }
    }

    const lines: JournalLine[] = [];
    const netAmount = Number(inv.total) - Number(inv.tax_amount || 0);

    // DR: Accounts Receivable (full total)
    lines.push({
      accountNumber: '1100',
      debit: Number(inv.total),
      credit: 0,
      description: `Invoice ${inv.invoice_number}`,
      jobId: inv.job_id || undefined,
    });

    // CR: Revenue (net of tax)
    if (netAmount > 0) {
      lines.push({
        accountNumber: revenueAccountNumber,
        debit: 0,
        credit: netAmount,
        description: `Revenue - Invoice ${inv.invoice_number}`,
        jobId: inv.job_id || undefined,
      });
    }

    // CR: Sales Tax Payable (if tax exists)
    const taxAmount = Number(inv.tax_amount || 0);
    if (taxAmount > 0) {
      lines.push({
        accountNumber: '2200',
        debit: 0,
        credit: taxAmount,
        description: `Sales tax - Invoice ${inv.invoice_number}`,
      });
    }

    const entryId = await createAndPostJournalEntry({
      description: `Invoice ${inv.invoice_number} sent`,
      sourceType: 'invoice',
      sourceId: invoiceId,
      entryDate: new Date().toISOString().slice(0, 10),
      lines,
    });

    // Link JE back to invoice (for reference, not required)
    return entryId;
  } catch (e) {
    console.error('Failed to create invoice journal entry:', e);
    return null;
  }
}

// ============================================================
// AUTO-POSTING: Payment Received → Cash debit + AR credit
// ============================================================
export async function createPaymentJournal(
  invoiceId: string,
  paymentAmount: number,
  paymentMethod: string
): Promise<string | null> {
  try {
    const supabase = getSupabase();

    const { data: inv } = await supabase
      .from('invoices')
      .select('id, invoice_number, job_id')
      .eq('id', invoiceId)
      .single();

    if (!inv || paymentAmount <= 0) return null;

    // Determine cash account from payment method
    const cashAccountNumber = PAYMENT_METHOD_ACCOUNT_MAP[paymentMethod] || '1010';

    const lines: JournalLine[] = [
      // DR: Cash/Bank
      {
        accountNumber: cashAccountNumber,
        debit: paymentAmount,
        credit: 0,
        description: `Payment received - Invoice ${inv.invoice_number}`,
        jobId: inv.job_id || undefined,
      },
      // CR: Accounts Receivable
      {
        accountNumber: '1100',
        debit: 0,
        credit: paymentAmount,
        description: `AR cleared - Invoice ${inv.invoice_number}`,
        jobId: inv.job_id || undefined,
      },
    ];

    return await createAndPostJournalEntry({
      description: `Payment received for Invoice ${inv.invoice_number}`,
      sourceType: 'payment',
      sourceId: invoiceId,
      entryDate: new Date().toISOString().slice(0, 10),
      lines,
    });
  } catch (e) {
    console.error('Failed to create payment journal entry:', e);
    return null;
  }
}

// ============================================================
// AUTO-POSTING: Expense Posted → Expense debit + Cash/AP credit
// ============================================================
export async function createExpenseJournal(expenseId: string): Promise<string | null> {
  try {
    const supabase = getSupabase();

    const { data: exp } = await supabase
      .from('expense_records')
      .select('id, description, total, category, payment_method, job_id, account_id')
      .eq('id', expenseId)
      .single();

    if (!exp || Number(exp.total) <= 0) return null;

    // Determine expense account: use explicit account_id or map from category
    let expenseAccountNumber: string;
    if (exp.account_id) {
      const { data: acct } = await supabase
        .from('chart_of_accounts')
        .select('account_number')
        .eq('id', exp.account_id)
        .single();
      expenseAccountNumber = acct?.account_number || CATEGORY_ACCOUNT_MAP[exp.category] || '6900';
    } else {
      expenseAccountNumber = CATEGORY_ACCOUNT_MAP[exp.category] || '6900';
    }

    // Determine credit account from payment method
    const creditAccountNumber = exp.payment_method
      ? (PAYMENT_METHOD_ACCOUNT_MAP[exp.payment_method] || '2000')
      : '2000'; // Default to AP if no payment method

    const lines: JournalLine[] = [
      // DR: Expense account
      {
        accountNumber: expenseAccountNumber,
        debit: Number(exp.total),
        credit: 0,
        description: exp.description,
        jobId: exp.job_id || undefined,
      },
      // CR: Cash/AP/CC
      {
        accountNumber: creditAccountNumber,
        debit: 0,
        credit: Number(exp.total),
        description: `Payment - ${exp.description}`,
        jobId: exp.job_id || undefined,
      },
    ];

    const entryId = await createAndPostJournalEntry({
      description: `Expense: ${exp.description}`,
      sourceType: 'expense',
      sourceId: expenseId,
      entryDate: new Date().toISOString().slice(0, 10),
      lines,
    });

    // Link JE back to expense
    await supabase
      .from('expense_records')
      .update({ journal_entry_id: entryId })
      .eq('id', expenseId);

    return entryId;
  } catch (e) {
    console.error('Failed to create expense journal entry:', e);
    return null;
  }
}

// ============================================================
// AUTO-POSTING: Vendor Payment → AP debit + Cash credit
// ============================================================
export async function createVendorPaymentJournal(paymentId: string): Promise<string | null> {
  try {
    const supabase = getSupabase();

    const { data: pmt } = await supabase
      .from('vendor_payments')
      .select('id, vendor_id, amount, payment_method, description, check_number')
      .eq('id', paymentId)
      .single();

    if (!pmt || Number(pmt.amount) <= 0) return null;

    // Get vendor name for description
    const { data: vendor } = await supabase
      .from('vendors')
      .select('vendor_name')
      .eq('id', pmt.vendor_id)
      .single();

    const vendorName = vendor?.vendor_name || 'Unknown vendor';
    const cashAccountNumber = PAYMENT_METHOD_ACCOUNT_MAP[pmt.payment_method] || '1010';
    const checkRef = pmt.check_number ? ` (Check #${pmt.check_number})` : '';

    const lines: JournalLine[] = [
      // DR: Accounts Payable
      {
        accountNumber: '2000',
        debit: Number(pmt.amount),
        credit: 0,
        description: `AP cleared - ${vendorName}${checkRef}`,
      },
      // CR: Cash/Bank
      {
        accountNumber: cashAccountNumber,
        debit: 0,
        credit: Number(pmt.amount),
        description: `Payment to ${vendorName}${checkRef}`,
      },
    ];

    const entryId = await createAndPostJournalEntry({
      description: `Vendor payment: ${vendorName}${checkRef}`,
      sourceType: 'vendor_payment',
      sourceId: paymentId,
      entryDate: new Date().toISOString().slice(0, 10),
      lines,
      memo: pmt.description || undefined,
    });

    // Link JE back to vendor payment
    await supabase
      .from('vendor_payments')
      .update({ journal_entry_id: entryId })
      .eq('id', paymentId);

    return entryId;
  } catch (e) {
    console.error('Failed to create vendor payment journal entry:', e);
    return null;
  }
}

// ============================================================
// VOID: Creates a reversing entry (swaps debits/credits)
// ============================================================
export async function voidJournalEntry(entryId: string, reason: string): Promise<string | null> {
  try {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    // Fetch original entry + lines
    const { data: entry } = await supabase
      .from('journal_entries')
      .select('id, company_id, entry_number, description, source_type, source_id, status')
      .eq('id', entryId)
      .single();

    if (!entry) throw new Error('Journal entry not found');
    if (entry.status === 'voided') throw new Error('Entry is already voided');

    const { data: lines } = await supabase
      .from('journal_entry_lines')
      .select('account_id, debit_amount, credit_amount, description, job_id')
      .eq('journal_entry_id', entryId);

    const typedLines = (lines || []) as { account_id: string; debit_amount: number; credit_amount: number; description: string | null; job_id: string | null }[];
    if (typedLines.length === 0) throw new Error('No lines found for entry');

    // Get account numbers for the reversing entry
    const accountIds = typedLines.map((l) => l.account_id);
    const { data: accounts } = await supabase
      .from('chart_of_accounts')
      .select('id, account_number')
      .in('id', accountIds);

    const accountMap = new Map<string, string>();
    for (const acct of (accounts || []) as AccountLookup[]) {
      accountMap.set(acct.id, acct.account_number);
    }

    // Create reversing lines (swap debit/credit)
    const reversingLines: JournalLine[] = typedLines.map((l) => ({
      accountNumber: accountMap.get(l.account_id) || '1000',
      debit: Number(l.credit_amount),
      credit: Number(l.debit_amount),
      description: `VOID: ${l.description || ''}`,
      jobId: l.job_id || undefined,
    }));

    // Create the reversing entry
    const reversingEntryId = await createAndPostJournalEntry({
      description: `VOID: ${entry.description} — ${reason}`,
      sourceType: 'adjustment',
      sourceId: entry.source_id || entryId,
      entryDate: new Date().toISOString().slice(0, 10),
      lines: reversingLines,
      memo: `Reversal of ${entry.entry_number}. Reason: ${reason}`,
    });

    // Mark original as voided
    await supabase
      .from('journal_entries')
      .update({
        status: 'voided',
        voided_at: new Date().toISOString(),
        voided_by_user_id: user.id,
        void_reason: reason,
        reversing_entry_id: reversingEntryId,
      })
      .eq('id', entryId);

    // Audit log
    await writeAuditLog('voided', 'journal_entries', entryId, {
      entry_number: entry.entry_number,
      status: entry.status,
    }, {
      status: 'voided',
      void_reason: reason,
      reversing_entry_id: reversingEntryId,
    }, `Voided ${entry.entry_number}: ${reason}`);

    return reversingEntryId;
  } catch (e) {
    console.error('Failed to void journal entry:', e);
    return null;
  }
}

// ============================================================
// FISCAL PERIOD: Close period
// ============================================================
export async function closeFiscalPeriod(periodId: string): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data: period } = await supabase
    .from('fiscal_periods')
    .select('*')
    .eq('id', periodId)
    .single();

  if (!period) throw new Error('Fiscal period not found');
  if (period.is_closed) throw new Error('Period is already closed');

  await supabase
    .from('fiscal_periods')
    .update({
      is_closed: true,
      closed_at: new Date().toISOString(),
      closed_by_user_id: user.id,
    })
    .eq('id', periodId);

  await writeAuditLog('period_closed', 'fiscal_periods', periodId, {
    is_closed: false,
  }, {
    is_closed: true,
    closed_by: user.id,
  }, `Closed fiscal period: ${period.period_name}`);
}

// ============================================================
// FISCAL PERIOD: Reopen period (owner only)
// ============================================================
export async function reopenFiscalPeriod(periodId: string, reason: string): Promise<void> {
  const supabase = getSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data: period } = await supabase
    .from('fiscal_periods')
    .select('*')
    .eq('id', periodId)
    .single();

  if (!period) throw new Error('Fiscal period not found');
  if (!period.is_closed) throw new Error('Period is not closed');

  await supabase
    .from('fiscal_periods')
    .update({
      is_closed: false,
      closed_at: null,
      closed_by_user_id: null,
    })
    .eq('id', periodId);

  await writeAuditLog('period_reopened', 'fiscal_periods', periodId, {
    is_closed: true,
  }, {
    is_closed: false,
    reopen_reason: reason,
  }, `Reopened fiscal period: ${period.period_name}. Reason: ${reason}`);
}
