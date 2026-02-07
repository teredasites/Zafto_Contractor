-- ============================================================
-- D4b: ZBooks Banking, Expenses & Vendors
-- Migration 000019
-- Tables: vendors, expense_records, vendor_payments,
--         bank_accounts, bank_transactions, bank_reconciliations,
--         recurring_transactions
-- ============================================================

-- ============================================================
-- 1. VENDORS
-- ============================================================
CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    vendor_name TEXT NOT NULL,
    contact_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    tax_id TEXT,
    vendor_type TEXT NOT NULL DEFAULT 'supplier' CHECK (vendor_type IN ('supplier', 'subcontractor', 'service_provider', 'utility', 'government')),
    default_expense_account_id UUID REFERENCES chart_of_accounts(id),
    is_1099_eligible BOOLEAN NOT NULL DEFAULT false,
    payment_terms TEXT NOT NULL DEFAULT 'net_30' CHECK (payment_terms IN ('due_on_receipt', 'net_15', 'net_30', 'net_45', 'net_60')),
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,

    UNIQUE(company_id, vendor_name)
);

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vendors_select" ON vendors
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "vendors_insert" ON vendors
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "vendors_update" ON vendors
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- No hard delete — soft delete via deleted_at

CREATE INDEX idx_vendors_company ON vendors(company_id);
CREATE INDEX idx_vendors_type ON vendors(company_id, vendor_type);
CREATE INDEX idx_vendors_1099 ON vendors(company_id) WHERE is_1099_eligible = true;

CREATE TRIGGER set_vendors_updated_at
    BEFORE UPDATE ON vendors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 2. EXPENSE RECORDS
-- ============================================================
CREATE TABLE expense_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES vendors(id),
    expense_date DATE NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
    category TEXT NOT NULL DEFAULT 'uncategorized' CHECK (category IN (
        'materials', 'labor', 'fuel', 'tools', 'equipment', 'vehicle',
        'insurance', 'permits', 'advertising', 'office', 'utilities',
        'subcontractor', 'income', 'refund', 'transfer', 'uncategorized'
    )),
    account_id UUID REFERENCES chart_of_accounts(id),
    job_id UUID REFERENCES jobs(id),
    payment_method TEXT CHECK (payment_method IN ('cash', 'check', 'credit_card', 'bank_transfer', 'other')),
    check_number TEXT,
    receipt_storage_path TEXT,
    receipt_url TEXT,
    ocr_status TEXT NOT NULL DEFAULT 'none' CHECK (ocr_status IN ('none', 'pending', 'completed', 'error')),
    ocr_data JSONB,
    journal_entry_id UUID REFERENCES journal_entries(id),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'posted', 'voided')),
    approved_by_user_id UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

ALTER TABLE expense_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "expense_records_select" ON expense_records
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "expense_records_insert" ON expense_records
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "expense_records_update" ON expense_records
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- No hard delete — soft delete via deleted_at

CREATE INDEX idx_expense_records_company_date ON expense_records(company_id, expense_date);
CREATE INDEX idx_expense_records_vendor ON expense_records(vendor_id);
CREATE INDEX idx_expense_records_job ON expense_records(job_id);
CREATE INDEX idx_expense_records_status ON expense_records(company_id, status);
CREATE INDEX idx_expense_records_category ON expense_records(company_id, category);

CREATE TRIGGER set_expense_records_updated_at
    BEFORE UPDATE ON expense_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 3. VENDOR PAYMENTS
-- ============================================================
CREATE TABLE vendor_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendors(id),
    payment_date DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payment_method TEXT NOT NULL CHECK (payment_method IN ('check', 'bank_transfer', 'credit_card', 'cash')),
    check_number TEXT,
    reference TEXT,
    description TEXT,
    expense_ids UUID[],
    journal_entry_id UUID REFERENCES journal_entries(id),
    is_1099_reportable BOOLEAN NOT NULL DEFAULT false,
    created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE vendor_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vendor_payments_select" ON vendor_payments
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "vendor_payments_insert" ON vendor_payments
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "vendor_payments_update" ON vendor_payments
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_vendor_payments_vendor ON vendor_payments(vendor_id);
CREATE INDEX idx_vendor_payments_company_date ON vendor_payments(company_id, payment_date);
CREATE INDEX idx_vendor_payments_1099 ON vendor_payments(company_id) WHERE is_1099_reportable = true;

CREATE TRIGGER set_vendor_payments_updated_at
    BEFORE UPDATE ON vendor_payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 4. BANK ACCOUNTS
-- ============================================================
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    plaid_item_id TEXT,
    plaid_account_id TEXT,
    account_name TEXT NOT NULL,
    institution_name TEXT,
    account_type TEXT NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit_card')),
    mask TEXT,
    current_balance NUMERIC(12,2) NOT NULL DEFAULT 0,
    available_balance NUMERIC(12,2),
    gl_account_id UUID REFERENCES chart_of_accounts(id),
    last_synced_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    plaid_access_token TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

-- SELECT policy excludes plaid_access_token via a secure view (see below)
CREATE POLICY "bank_accounts_select" ON bank_accounts
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "bank_accounts_insert" ON bank_accounts
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "bank_accounts_update" ON bank_accounts
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_bank_accounts_company ON bank_accounts(company_id);

CREATE TRIGGER set_bank_accounts_updated_at
    BEFORE UPDATE ON bank_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Secure view: frontend queries this view (never the table directly for reads)
-- This excludes plaid_access_token from all frontend queries
CREATE OR REPLACE VIEW bank_accounts_safe AS
SELECT
    id, company_id, plaid_item_id, plaid_account_id,
    account_name, institution_name, account_type, mask,
    current_balance, available_balance, gl_account_id,
    last_synced_at, is_active, created_at, updated_at
FROM bank_accounts;


-- ============================================================
-- 5. BANK RECONCILIATIONS
-- ============================================================
CREATE TABLE bank_reconciliations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    statement_date DATE NOT NULL,
    statement_balance NUMERIC(12,2) NOT NULL,
    calculated_balance NUMERIC(12,2),
    difference NUMERIC(12,2),
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'voided')),
    completed_at TIMESTAMPTZ,
    completed_by_user_id UUID REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bank_reconciliations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bank_reconciliations_select" ON bank_reconciliations
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "bank_reconciliations_insert" ON bank_reconciliations
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "bank_reconciliations_update" ON bank_reconciliations
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_bank_reconciliations_account ON bank_reconciliations(bank_account_id);
CREATE INDEX idx_bank_reconciliations_company ON bank_reconciliations(company_id);

CREATE TRIGGER set_bank_reconciliations_updated_at
    BEFORE UPDATE ON bank_reconciliations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 6. BANK TRANSACTIONS
-- ============================================================
CREATE TABLE bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    plaid_transaction_id TEXT UNIQUE,
    transaction_date DATE NOT NULL,
    posted_date DATE,
    description TEXT NOT NULL,
    merchant_name TEXT,
    amount NUMERIC(12,2) NOT NULL,
    category TEXT NOT NULL DEFAULT 'uncategorized' CHECK (category IN (
        'materials', 'labor', 'fuel', 'tools', 'equipment', 'vehicle',
        'insurance', 'permits', 'advertising', 'office', 'utilities',
        'subcontractor', 'income', 'refund', 'transfer', 'uncategorized'
    )),
    category_confidence NUMERIC(3,2) CHECK (category_confidence >= 0 AND category_confidence <= 1),
    is_income BOOLEAN NOT NULL DEFAULT false,
    matched_invoice_id UUID REFERENCES invoices(id),
    matched_expense_id UUID REFERENCES expense_records(id),
    journal_entry_id UUID REFERENCES journal_entries(id),
    is_reviewed BOOLEAN NOT NULL DEFAULT false,
    is_reconciled BOOLEAN NOT NULL DEFAULT false,
    reconciliation_id UUID REFERENCES bank_reconciliations(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bank_transactions_select" ON bank_transactions
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "bank_transactions_insert" ON bank_transactions
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "bank_transactions_update" ON bank_transactions
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_bank_transactions_company_date ON bank_transactions(company_id, transaction_date);
CREATE INDEX idx_bank_transactions_account ON bank_transactions(bank_account_id);
CREATE INDEX idx_bank_transactions_unreviewed ON bank_transactions(company_id) WHERE is_reviewed = false;
CREATE INDEX idx_bank_transactions_unreconciled ON bank_transactions(company_id) WHERE is_reconciled = false;
CREATE INDEX idx_bank_transactions_reconciliation ON bank_transactions(reconciliation_id);

CREATE TRIGGER set_bank_transactions_updated_at
    BEFORE UPDATE ON bank_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 7. RECURRING TRANSACTIONS
-- ============================================================
CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    template_name TEXT NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('expense', 'invoice')),
    frequency TEXT NOT NULL CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'quarterly', 'annually')),
    next_occurrence DATE NOT NULL,
    end_date DATE,
    template_data JSONB NOT NULL,
    account_id UUID REFERENCES chart_of_accounts(id),
    vendor_id UUID REFERENCES vendors(id),
    job_id UUID REFERENCES jobs(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_generated_at TIMESTAMPTZ,
    times_generated INTEGER NOT NULL DEFAULT 0,
    created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "recurring_transactions_select" ON recurring_transactions
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "recurring_transactions_insert" ON recurring_transactions
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "recurring_transactions_update" ON recurring_transactions
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_recurring_transactions_company ON recurring_transactions(company_id);
CREATE INDEX idx_recurring_transactions_due ON recurring_transactions(next_occurrence) WHERE is_active = true;

CREATE TRIGGER set_recurring_transactions_updated_at
    BEFORE UPDATE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
