-- D5e: Property allocation for expenses (Schedule E support)
-- Allows allocating expenses to specific properties for IRS Schedule E reporting

ALTER TABLE expense_records ADD COLUMN property_id UUID REFERENCES properties(id);
ALTER TABLE expense_records ADD COLUMN schedule_e_category TEXT CHECK (schedule_e_category IN (
    'advertising', 'auto_and_travel', 'cleaning_maintenance', 'commissions',
    'insurance', 'legal_professional', 'management_fees', 'mortgage_interest',
    'other_interest', 'repairs', 'supplies', 'taxes', 'utilities',
    'depreciation', 'other'
));
ALTER TABLE expense_records ADD COLUMN property_allocation_pct NUMERIC(5,2) DEFAULT 100 CHECK (property_allocation_pct >= 0 AND property_allocation_pct <= 100);

CREATE INDEX idx_expense_records_property ON expense_records(property_id) WHERE property_id IS NOT NULL;
