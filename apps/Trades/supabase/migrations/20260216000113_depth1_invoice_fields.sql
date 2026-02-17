-- DEPTH1: Add missing invoice fields (po_number, retainage, late_fee)
-- These fields are collected in the CRM invoice creation form but were never persisted to DB.

ALTER TABLE invoices ADD COLUMN IF NOT EXISTS po_number text;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS retainage_percent numeric(5,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS retainage_amount numeric(12,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS late_fee_per_day numeric(12,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2) DEFAULT 0;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS payment_terms text DEFAULT 'net_30';
