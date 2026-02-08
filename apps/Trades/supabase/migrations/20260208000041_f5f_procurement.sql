-- F5f: Procurement tables
-- PO creation, vendor management, receiving + matching

-- Note: vendors table and purchase_orders may already exist — use IF NOT EXISTS

-- Vendor Directory (enhanced)
CREATE TABLE IF NOT EXISTS vendor_directory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  website TEXT,
  -- Terms
  payment_terms TEXT DEFAULT 'net_30' CHECK (payment_terms IN ('cod','net_15','net_30','net_45','net_60','net_90','prepaid')),
  credit_limit NUMERIC(12,2),
  tax_id TEXT,
  -- Categories
  vendor_type TEXT DEFAULT 'supplier' CHECK (vendor_type IN ('supplier','subcontractor','rental','distributor','manufacturer','other')),
  trade_categories TEXT[] DEFAULT '{}',
  -- Rating
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  -- Unwrangle integration
  unwrangle_vendor_id TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Purchase Order Line Items
CREATE TABLE po_line_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  purchase_order_id UUID NOT NULL,  -- References purchase_orders (may exist from earlier migration)
  item_description TEXT NOT NULL,
  quantity NUMERIC(10,3) NOT NULL DEFAULT 1,
  unit TEXT DEFAULT 'ea',
  unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_price NUMERIC(12,2) NOT NULL DEFAULT 0,
  received_quantity NUMERIC(10,3) DEFAULT 0,
  -- Catalog reference
  catalog_item_id TEXT,
  catalog_source TEXT,  -- 'unwrangle', 'manual', 'price_book'
  -- Status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','partial','received','cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Receiving Records — match received goods to PO
CREATE TABLE receiving_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  purchase_order_id UUID NOT NULL,
  received_by_user_id UUID REFERENCES auth.users(id),
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  delivery_method TEXT DEFAULT 'delivery' CHECK (delivery_method IN ('delivery','pickup','shipped')),
  tracking_number TEXT,
  packing_slip_path TEXT,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,  -- [{line_item_id, quantity_received, condition, notes}]
  all_items_received BOOLEAN DEFAULT false,
  discrepancy_notes TEXT,
  photos JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'vendor_directory' AND schemaname = 'public') THEN
    NULL; -- table created above with IF NOT EXISTS
  END IF;
END $$;

ALTER TABLE vendor_directory ENABLE ROW LEVEL SECURITY;
ALTER TABLE po_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE receiving_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY vendor_dir_company ON vendor_directory FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY po_items_company ON po_line_items FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY receiving_company ON receiving_records FOR ALL USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Indexes
CREATE INDEX idx_vendor_dir_company ON vendor_directory(company_id);
CREATE INDEX idx_po_items_po ON po_line_items(purchase_order_id);
CREATE INDEX idx_receiving_po ON receiving_records(purchase_order_id);

-- Triggers
CREATE TRIGGER vendor_dir_updated BEFORE UPDATE ON vendor_directory FOR EACH ROW EXECUTE FUNCTION update_updated_at();
