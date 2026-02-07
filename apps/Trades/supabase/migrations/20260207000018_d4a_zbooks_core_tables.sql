-- ============================================================
-- D4a: ZBooks Core Financial Tables
-- Migration 000018
-- Tables: chart_of_accounts, fiscal_periods, journal_entries,
--         journal_entry_lines, tax_categories, zbooks_audit_log
-- ============================================================

-- ============================================================
-- 1. TAX CATEGORIES (referenced by chart_of_accounts)
-- ============================================================
CREATE TABLE tax_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    category_name TEXT NOT NULL,
    tax_form TEXT NOT NULL CHECK (tax_form IN ('schedule_c', '1099_nec', 'sales_tax', 'payroll')),
    tax_line TEXT,
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(company_id, category_name)
);

ALTER TABLE tax_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "tax_categories_select" ON tax_categories
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "tax_categories_insert" ON tax_categories
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "tax_categories_update" ON tax_categories
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- No delete policy — soft deactivation only

CREATE INDEX idx_tax_categories_company ON tax_categories(company_id);


-- ============================================================
-- 2. CHART OF ACCOUNTS
-- ============================================================
CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    account_number TEXT NOT NULL,
    account_name TEXT NOT NULL,
    account_type TEXT NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'revenue', 'cogs', 'expense')),
    parent_account_id UUID REFERENCES chart_of_accounts(id),
    description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    normal_balance TEXT NOT NULL CHECK (normal_balance IN ('debit', 'credit')),
    tax_category_id UUID REFERENCES tax_categories(id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(company_id, account_number)
);

ALTER TABLE chart_of_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "coa_select" ON chart_of_accounts
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "coa_insert" ON chart_of_accounts
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "coa_update" ON chart_of_accounts
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- No delete policy — deactivate via is_active flag

CREATE INDEX idx_coa_company_number ON chart_of_accounts(company_id, account_number);
CREATE INDEX idx_coa_company_type ON chart_of_accounts(company_id, account_type);
CREATE INDEX idx_coa_parent ON chart_of_accounts(parent_account_id);

-- Auto-update updated_at
CREATE TRIGGER set_coa_updated_at
    BEFORE UPDATE ON chart_of_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 3. FISCAL PERIODS
-- ============================================================
CREATE TABLE fiscal_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    period_name TEXT NOT NULL,
    period_type TEXT NOT NULL CHECK (period_type IN ('month', 'quarter', 'year')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN NOT NULL DEFAULT false,
    closed_at TIMESTAMPTZ,
    closed_by_user_id UUID REFERENCES auth.users(id),
    retained_earnings_posted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(company_id, period_name),
    CHECK (end_date >= start_date)
);

ALTER TABLE fiscal_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fiscal_periods_select" ON fiscal_periods
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "fiscal_periods_insert" ON fiscal_periods
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "fiscal_periods_update" ON fiscal_periods
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

CREATE INDEX idx_fiscal_periods_company ON fiscal_periods(company_id);
CREATE INDEX idx_fiscal_periods_dates ON fiscal_periods(company_id, start_date, end_date);


-- ============================================================
-- 4. JOURNAL ENTRIES
-- ============================================================
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    entry_number TEXT NOT NULL,
    entry_date DATE NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'posted', 'voided')),
    source_type TEXT CHECK (source_type IN ('invoice', 'payment', 'expense', 'vendor_payment', 'payroll', 'manual', 'adjustment', 'closing')),
    source_id UUID,
    posted_at TIMESTAMPTZ,
    posted_by_user_id UUID REFERENCES auth.users(id),
    voided_at TIMESTAMPTZ,
    voided_by_user_id UUID REFERENCES auth.users(id),
    void_reason TEXT,
    reversing_entry_id UUID REFERENCES journal_entries(id),
    fiscal_period_id UUID REFERENCES fiscal_periods(id),
    memo TEXT,
    created_by_user_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(company_id, entry_number)
);

ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "journal_entries_select" ON journal_entries
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

CREATE POLICY "journal_entries_insert" ON journal_entries
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

CREATE POLICY "journal_entries_update" ON journal_entries
    FOR UPDATE TO authenticated
    USING (company_id = requesting_company_id());

-- No delete policy — journal entries are immutable once posted. Void only.

CREATE INDEX idx_journal_entries_company_date ON journal_entries(company_id, entry_date);
CREATE INDEX idx_journal_entries_source ON journal_entries(company_id, source_type, source_id);
CREATE INDEX idx_journal_entries_status ON journal_entries(company_id, status);
CREATE INDEX idx_journal_entries_period ON journal_entries(fiscal_period_id);

-- Auto-update updated_at
CREATE TRIGGER set_journal_entries_updated_at
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 5. JOURNAL ENTRY LINES
-- ============================================================
CREATE TABLE journal_entry_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES chart_of_accounts(id),
    debit_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    credit_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    description TEXT,
    job_id UUID REFERENCES jobs(id),
    branch_id UUID REFERENCES branches(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- At least one side must be positive
    CHECK (debit_amount >= 0),
    CHECK (credit_amount >= 0),
    CHECK (debit_amount > 0 OR credit_amount > 0),
    -- Cannot have both debit and credit on same line
    CHECK (NOT (debit_amount > 0 AND credit_amount > 0))
);

ALTER TABLE journal_entry_lines ENABLE ROW LEVEL SECURITY;

-- Lines inherit access from parent journal_entry via join check
CREATE POLICY "jel_select" ON journal_entry_lines
    FOR SELECT TO authenticated
    USING (EXISTS (
        SELECT 1 FROM journal_entries
        WHERE journal_entries.id = journal_entry_lines.journal_entry_id
        AND journal_entries.company_id = requesting_company_id()
    ));

CREATE POLICY "jel_insert" ON journal_entry_lines
    FOR INSERT TO authenticated
    WITH CHECK (EXISTS (
        SELECT 1 FROM journal_entries
        WHERE journal_entries.id = journal_entry_lines.journal_entry_id
        AND journal_entries.company_id = requesting_company_id()
    ));

CREATE POLICY "jel_update" ON journal_entry_lines
    FOR UPDATE TO authenticated
    USING (EXISTS (
        SELECT 1 FROM journal_entries
        WHERE journal_entries.id = journal_entry_lines.journal_entry_id
        AND journal_entries.company_id = requesting_company_id()
    ));

-- No delete policy — lines are immutable with their parent entry

CREATE INDEX idx_jel_entry ON journal_entry_lines(journal_entry_id);
CREATE INDEX idx_jel_account ON journal_entry_lines(account_id);
CREATE INDEX idx_jel_job ON journal_entry_lines(job_id);
CREATE INDEX idx_jel_branch ON journal_entry_lines(branch_id);


-- ============================================================
-- 6. ZBOOKS AUDIT LOG (INSERT-ONLY — IMMUTABLE)
-- ============================================================
CREATE TABLE zbooks_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    action TEXT NOT NULL CHECK (action IN (
        'created', 'posted', 'voided', 'reconciled',
        'period_closed', 'period_reopened', 'export_generated',
        'cpa_access', 'account_deactivated', 'account_created'
    )),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    previous_values JSONB,
    new_values JSONB,
    change_summary TEXT,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE zbooks_audit_log ENABLE ROW LEVEL SECURITY;

-- SELECT: company members can read audit log
CREATE POLICY "zbooks_audit_select" ON zbooks_audit_log
    FOR SELECT TO authenticated
    USING (company_id = requesting_company_id());

-- INSERT: company members can write audit entries
CREATE POLICY "zbooks_audit_insert" ON zbooks_audit_log
    FOR INSERT TO authenticated
    WITH CHECK (company_id = requesting_company_id());

-- NO UPDATE POLICY — immutable
-- NO DELETE POLICY — immutable

CREATE INDEX idx_zbooks_audit_company ON zbooks_audit_log(company_id, created_at DESC);
CREATE INDEX idx_zbooks_audit_record ON zbooks_audit_log(table_name, record_id);


-- ============================================================
-- 7. SEED DATA: DEFAULT CHART OF ACCOUNTS
-- ============================================================
-- Seeded per-company via a function that can be called when a company is created.
-- For existing companies, we seed for the test company.

-- Function to seed default COA for a company
CREATE OR REPLACE FUNCTION seed_default_chart_of_accounts(p_company_id UUID)
RETURNS void AS $$
BEGIN
    -- Skip if company already has accounts
    IF EXISTS (SELECT 1 FROM chart_of_accounts WHERE company_id = p_company_id) THEN
        RETURN;
    END IF;

    INSERT INTO chart_of_accounts (company_id, account_number, account_name, account_type, normal_balance, is_system, sort_order, description) VALUES
    -- Assets (1000-1999)
    (p_company_id, '1000', 'Cash', 'asset', 'debit', true, 100, 'Cash on hand'),
    (p_company_id, '1010', 'Checking Account', 'asset', 'debit', true, 110, 'Primary business checking'),
    (p_company_id, '1020', 'Savings Account', 'asset', 'debit', true, 120, 'Business savings'),
    (p_company_id, '1100', 'Accounts Receivable', 'asset', 'debit', true, 130, 'Money owed by customers'),
    (p_company_id, '1200', 'Materials Inventory', 'asset', 'debit', true, 140, 'Materials and supplies on hand'),
    (p_company_id, '1300', 'Prepaid Expenses', 'asset', 'debit', true, 150, 'Expenses paid in advance'),
    (p_company_id, '1400', 'Tools & Equipment', 'asset', 'debit', true, 160, 'Tools and equipment owned'),
    (p_company_id, '1410', 'Accum. Depreciation - Equipment', 'asset', 'credit', true, 161, 'Accumulated depreciation on equipment'),
    (p_company_id, '1500', 'Vehicles', 'asset', 'debit', true, 170, 'Company vehicles'),
    (p_company_id, '1510', 'Accum. Depreciation - Vehicles', 'asset', 'credit', true, 171, 'Accumulated depreciation on vehicles'),

    -- Liabilities (2000-2999)
    (p_company_id, '2000', 'Accounts Payable', 'liability', 'credit', true, 200, 'Money owed to vendors'),
    (p_company_id, '2100', 'Credit Card Payable', 'liability', 'credit', true, 210, 'Credit card balances'),
    (p_company_id, '2200', 'Sales Tax Payable', 'liability', 'credit', true, 220, 'Sales tax collected but not remitted'),
    (p_company_id, '2300', 'Payroll Liabilities', 'liability', 'credit', true, 230, 'Payroll taxes and withholdings'),
    (p_company_id, '2310', 'Federal Tax Withholding', 'liability', 'credit', true, 231, 'Federal income tax withheld'),
    (p_company_id, '2320', 'State Tax Withholding', 'liability', 'credit', true, 232, 'State income tax withheld'),
    (p_company_id, '2330', 'FICA Payable', 'liability', 'credit', true, 233, 'Social Security and Medicare taxes'),
    (p_company_id, '2340', 'Workers Comp Payable', 'liability', 'credit', true, 234, 'Workers compensation premiums'),
    (p_company_id, '2400', 'Vehicle Loans', 'liability', 'credit', true, 240, 'Vehicle loan balances'),
    (p_company_id, '2500', 'Equipment Loans', 'liability', 'credit', true, 250, 'Equipment financing balances'),
    (p_company_id, '2600', 'Retention Payable', 'liability', 'credit', true, 260, 'Retention held on contracts'),
    (p_company_id, '2700', 'Unearned Revenue', 'liability', 'credit', true, 270, 'Deposits and prepayments received'),

    -- Equity (3000-3999)
    (p_company_id, '3000', 'Owner''s Equity', 'equity', 'credit', true, 300, 'Owner investment in business'),
    (p_company_id, '3100', 'Owner''s Draw', 'equity', 'debit', true, 310, 'Owner withdrawals'),
    (p_company_id, '3200', 'Retained Earnings', 'equity', 'credit', true, 320, 'Accumulated net income'),

    -- Revenue (4000-4999)
    (p_company_id, '4000', 'Service Revenue - Retail', 'revenue', 'credit', true, 400, 'Revenue from standard service jobs'),
    (p_company_id, '4010', 'Service Revenue - Insurance', 'revenue', 'credit', true, 410, 'Revenue from insurance claim jobs'),
    (p_company_id, '4020', 'Service Revenue - Warranty', 'revenue', 'credit', true, 420, 'Revenue from warranty dispatch jobs'),
    (p_company_id, '4030', 'Service Revenue - Maintenance', 'revenue', 'credit', true, 430, 'Revenue from maintenance contracts'),
    (p_company_id, '4100', 'Material Sales Revenue', 'revenue', 'credit', true, 440, 'Revenue from materials sold to customers'),
    (p_company_id, '4200', 'Change Order Revenue', 'revenue', 'credit', true, 450, 'Revenue from approved change orders'),
    (p_company_id, '4900', 'Other Income', 'revenue', 'credit', true, 490, 'Miscellaneous income'),

    -- Cost of Goods Sold (5000-5999)
    (p_company_id, '5000', 'Materials Cost', 'cogs', 'debit', true, 500, 'Cost of materials used on jobs'),
    (p_company_id, '5100', 'Direct Labor', 'cogs', 'debit', true, 510, 'Wages for field technicians'),
    (p_company_id, '5200', 'Subcontractor Costs', 'cogs', 'debit', true, 520, 'Payments to subcontractors'),
    (p_company_id, '5300', 'Equipment Rental', 'cogs', 'debit', true, 530, 'Rented equipment for jobs'),
    (p_company_id, '5400', 'Permits & Inspections', 'cogs', 'debit', true, 540, 'Permit fees and inspection costs'),
    (p_company_id, '5500', 'Disposal Fees', 'cogs', 'debit', true, 550, 'Waste disposal and dumpster fees'),

    -- Operating Expenses (6000-6999)
    (p_company_id, '6000', 'Advertising & Marketing', 'expense', 'debit', true, 600, 'Marketing and advertising costs'),
    (p_company_id, '6100', 'Business Insurance', 'expense', 'debit', true, 610, 'General liability, E&O, umbrella'),
    (p_company_id, '6200', 'Office Supplies', 'expense', 'debit', true, 620, 'Office supplies and materials'),
    (p_company_id, '6300', 'Rent', 'expense', 'debit', true, 630, 'Office or shop rent'),
    (p_company_id, '6400', 'Utilities', 'expense', 'debit', true, 640, 'Electric, water, gas for office/shop'),
    (p_company_id, '6500', 'Vehicle - Fuel', 'expense', 'debit', true, 650, 'Fuel for company vehicles'),
    (p_company_id, '6510', 'Vehicle - Maintenance', 'expense', 'debit', true, 651, 'Vehicle repairs and maintenance'),
    (p_company_id, '6520', 'Vehicle - Insurance', 'expense', 'debit', true, 652, 'Commercial auto insurance'),
    (p_company_id, '6600', 'Tools & Small Equipment', 'expense', 'debit', true, 660, 'Tools under capitalization threshold'),
    (p_company_id, '6700', 'Accounting & Legal Fees', 'expense', 'debit', true, 670, 'CPA, attorney, professional services'),
    (p_company_id, '6800', 'Phone & Internet', 'expense', 'debit', true, 680, 'Phone plans and internet service'),
    (p_company_id, '6900', 'Software & Subscriptions', 'expense', 'debit', true, 690, 'Software licenses and subscriptions'),
    (p_company_id, '6950', 'Travel & Meals', 'expense', 'debit', true, 695, 'Business travel and meals'),

    -- Other Expenses (7000-7999)
    (p_company_id, '7000', 'Interest Expense', 'expense', 'debit', true, 700, 'Loan and credit card interest'),
    (p_company_id, '7100', 'Depreciation Expense', 'expense', 'debit', true, 710, 'Annual depreciation charges'),
    (p_company_id, '7200', 'Bank Fees', 'expense', 'debit', true, 720, 'Bank service charges and fees'),
    (p_company_id, '7300', 'Penalties & Fines', 'expense', 'debit', true, 730, 'Regulatory penalties and late fees');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 8. SEED DATA: DEFAULT TAX CATEGORIES
-- ============================================================
CREATE OR REPLACE FUNCTION seed_default_tax_categories(p_company_id UUID)
RETURNS void AS $$
BEGIN
    -- Skip if company already has tax categories
    IF EXISTS (SELECT 1 FROM tax_categories WHERE company_id = p_company_id) THEN
        RETURN;
    END IF;

    INSERT INTO tax_categories (company_id, category_name, tax_form, tax_line, description, is_system, sort_order) VALUES
    -- Schedule C line items
    (p_company_id, 'Gross Receipts', 'schedule_c', 'Line 1', 'Total revenue from all sources', true, 1),
    (p_company_id, 'Returns & Allowances', 'schedule_c', 'Line 2', 'Refunds and discounts given', true, 2),
    (p_company_id, 'Cost of Goods Sold', 'schedule_c', 'Line 4', 'Direct costs of materials and labor', true, 4),
    (p_company_id, 'Advertising', 'schedule_c', 'Line 8', 'Advertising and marketing expenses', true, 8),
    (p_company_id, 'Car & Truck Expenses', 'schedule_c', 'Line 9', 'Vehicle fuel, maintenance, insurance', true, 9),
    (p_company_id, 'Commissions & Fees', 'schedule_c', 'Line 10', 'Commissions paid to others', true, 10),
    (p_company_id, 'Contract Labor', 'schedule_c', 'Line 11', 'Payments to independent contractors', true, 11),
    (p_company_id, 'Depreciation', 'schedule_c', 'Line 13', 'Depreciation of business assets', true, 13),
    (p_company_id, 'Insurance (non-health)', 'schedule_c', 'Line 15', 'Business insurance premiums', true, 15),
    (p_company_id, 'Interest (Mortgage)', 'schedule_c', 'Line 16a', 'Mortgage interest on business property', true, 16),
    (p_company_id, 'Interest (Other)', 'schedule_c', 'Line 16b', 'Other business interest expense', true, 17),
    (p_company_id, 'Legal & Professional', 'schedule_c', 'Line 17', 'Accounting, legal, consulting fees', true, 18),
    (p_company_id, 'Office Expense', 'schedule_c', 'Line 18', 'Office supplies and postage', true, 19),
    (p_company_id, 'Rent - Vehicles/Equipment', 'schedule_c', 'Line 20a', 'Rented vehicles and equipment', true, 20),
    (p_company_id, 'Rent - Other', 'schedule_c', 'Line 20b', 'Office/shop rent', true, 21),
    (p_company_id, 'Repairs & Maintenance', 'schedule_c', 'Line 21', 'Repairs to business property', true, 22),
    (p_company_id, 'Supplies', 'schedule_c', 'Line 22', 'Materials and supplies consumed', true, 23),
    (p_company_id, 'Taxes & Licenses', 'schedule_c', 'Line 23', 'Business taxes and license fees', true, 24),
    (p_company_id, 'Travel', 'schedule_c', 'Line 24a', 'Business travel expenses', true, 25),
    (p_company_id, 'Meals (50%)', 'schedule_c', 'Line 24b', 'Business meals (50% deductible)', true, 26),
    (p_company_id, 'Utilities', 'schedule_c', 'Line 25', 'Phone, internet, electric, water', true, 27),
    (p_company_id, 'Wages', 'schedule_c', 'Line 26', 'Employee wages and salaries', true, 28),
    (p_company_id, 'Other Expenses', 'schedule_c', 'Line 27a', 'Miscellaneous business expenses', true, 29),

    -- 1099-NEC
    (p_company_id, '1099-NEC Compensation', '1099_nec', 'Box 1', 'Non-employee compensation >= $600', true, 100),

    -- Sales Tax
    (p_company_id, 'Sales Tax Collected', 'sales_tax', 'Collected', 'Sales tax collected from customers', true, 200),
    (p_company_id, 'Sales Tax Remitted', 'sales_tax', 'Remitted', 'Sales tax paid to state/local', true, 201);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- 9. SEED FOR EXISTING TEST COMPANY
-- ============================================================
DO $$
DECLARE
    v_company_id UUID;
BEGIN
    -- Get the test company (Tereda Electrical)
    SELECT id INTO v_company_id FROM companies LIMIT 1;

    IF v_company_id IS NOT NULL THEN
        PERFORM seed_default_chart_of_accounts(v_company_id);
        PERFORM seed_default_tax_categories(v_company_id);
    END IF;
END;
$$;


-- ============================================================
-- 10. TRIGGER: Auto-seed COA + tax categories for new companies
-- ============================================================
CREATE OR REPLACE FUNCTION handle_new_company_zbooks()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM seed_default_chart_of_accounts(NEW.id);
    PERFORM seed_default_tax_categories(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_company_created_seed_zbooks
    AFTER INSERT ON companies
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_company_zbooks();
