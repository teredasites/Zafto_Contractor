-- FIELD2: Equipment & Tool Checkout System
-- Sprint FIELD2, Session 131
--
-- Company-owned tool/equipment inventory with borrow/return tracking.
-- QR/barcode support for fast checkout. Condition tracking on each transaction.
-- Separate from equipment_database (reference catalog) — this is per-company inventory.

-- ============================================================
-- EQUIPMENT ITEMS (company inventory)
-- ============================================================

CREATE TABLE equipment_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'hand_tool'
    CHECK (category IN ('hand_tool', 'power_tool', 'testing_equipment', 'safety_equipment', 'vehicle_mounted', 'specialty')),
  serial_number TEXT,
  barcode TEXT,
  manufacturer TEXT,
  model_number TEXT,
  purchase_date DATE,
  purchase_cost NUMERIC(10,2),
  condition TEXT NOT NULL DEFAULT 'good'
    CHECK (condition IN ('new', 'good', 'fair', 'poor', 'damaged', 'retired')),
  current_holder_id UUID REFERENCES auth.users(id),
  storage_location TEXT,
  photo_url TEXT,
  last_inspection_date DATE,
  next_calibration_date DATE,
  warranty_expiry DATE,
  notes TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================
-- EQUIPMENT CHECKOUTS (borrow/return log)
-- ============================================================

CREATE TABLE equipment_checkouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  equipment_item_id UUID NOT NULL REFERENCES equipment_items(id),
  checked_out_by UUID NOT NULL REFERENCES auth.users(id),
  checked_out_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expected_return_date DATE,
  checked_in_at TIMESTAMPTZ,
  checked_in_by UUID REFERENCES auth.users(id),
  checkout_condition TEXT NOT NULL DEFAULT 'good'
    CHECK (checkout_condition IN ('new', 'good', 'fair', 'poor', 'damaged')),
  checkin_condition TEXT
    CHECK (checkin_condition IS NULL OR checkin_condition IN ('new', 'good', 'fair', 'poor', 'damaged')),
  job_id UUID REFERENCES jobs(id),
  notes TEXT,
  photo_out_url TEXT,
  photo_in_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE equipment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment_checkouts ENABLE ROW LEVEL SECURITY;

-- Equipment items: company-scoped read for all employees
CREATE POLICY "equip_items_select" ON equipment_items FOR SELECT
  USING (company_id = requesting_company_id());

-- Equipment items: only owner/admin can manage inventory
CREATE POLICY "equip_items_insert" ON equipment_items FOR INSERT
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'office_manager')
  );

CREATE POLICY "equip_items_update" ON equipment_items FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin', 'office_manager')
  );

CREATE POLICY "equip_items_delete" ON equipment_items FOR DELETE
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin')
  );

-- Equipment checkouts: company-scoped read
CREATE POLICY "equip_checkouts_select" ON equipment_checkouts FOR SELECT
  USING (company_id = requesting_company_id());

-- Any employee can checkout
CREATE POLICY "equip_checkouts_insert" ON equipment_checkouts FOR INSERT
  WITH CHECK (
    company_id = requesting_company_id()
    AND checked_out_by = auth.uid()
  );

-- Checkin: the person who checked out or admin can check in
CREATE POLICY "equip_checkouts_update" ON equipment_checkouts FOR UPDATE
  USING (company_id = requesting_company_id())
  WITH CHECK (
    company_id = requesting_company_id()
    AND (
      checked_out_by = auth.uid()
      OR requesting_user_role() IN ('owner', 'admin', 'office_manager')
    )
  );

-- Only admin can delete checkout records
CREATE POLICY "equip_checkouts_delete" ON equipment_checkouts FOR DELETE
  USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner', 'admin')
  );

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_equip_items_company ON equipment_items(company_id);
CREATE INDEX idx_equip_items_category ON equipment_items(company_id, category);
CREATE INDEX idx_equip_items_condition ON equipment_items(company_id, condition);
CREATE INDEX idx_equip_items_holder ON equipment_items(current_holder_id) WHERE current_holder_id IS NOT NULL;
CREATE INDEX idx_equip_items_barcode ON equipment_items(company_id, barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_equip_items_serial ON equipment_items(company_id, serial_number) WHERE serial_number IS NOT NULL;
CREATE INDEX idx_equip_items_calibration ON equipment_items(next_calibration_date) WHERE next_calibration_date IS NOT NULL;

CREATE INDEX idx_equip_checkouts_company ON equipment_checkouts(company_id);
CREATE INDEX idx_equip_checkouts_item ON equipment_checkouts(equipment_item_id);
CREATE INDEX idx_equip_checkouts_user ON equipment_checkouts(checked_out_by);
CREATE INDEX idx_equip_checkouts_active ON equipment_checkouts(company_id, equipment_item_id) WHERE checked_in_at IS NULL;
CREATE INDEX idx_equip_checkouts_overdue ON equipment_checkouts(expected_return_date) WHERE checked_in_at IS NULL AND expected_return_date IS NOT NULL;
CREATE INDEX idx_equip_checkouts_job ON equipment_checkouts(job_id) WHERE job_id IS NOT NULL;

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE TRIGGER equip_items_updated
  BEFORE UPDATE ON equipment_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER equip_checkouts_updated
  BEFORE UPDATE ON equipment_checkouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Audit triggers
CREATE TRIGGER equip_items_audit
  AFTER INSERT OR UPDATE OR DELETE ON equipment_items
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE TRIGGER equip_checkouts_audit
  AFTER INSERT OR UPDATE OR DELETE ON equipment_checkouts
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================================
-- AUTO-UPDATE current_holder_id ON CHECKOUT/CHECKIN
-- ============================================================

CREATE OR REPLACE FUNCTION update_equipment_holder()
RETURNS TRIGGER AS $$
BEGIN
  -- On checkout (new record with no checkin)
  IF TG_OP = 'INSERT' THEN
    UPDATE equipment_items
    SET current_holder_id = NEW.checked_out_by
    WHERE id = NEW.equipment_item_id;
    RETURN NEW;
  END IF;

  -- On checkin (checked_in_at gets set)
  IF TG_OP = 'UPDATE' AND OLD.checked_in_at IS NULL AND NEW.checked_in_at IS NOT NULL THEN
    UPDATE equipment_items
    SET current_holder_id = NULL,
        condition = COALESCE(NEW.checkin_condition, condition)
    WHERE id = NEW.equipment_item_id;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER equip_checkout_holder_sync
  AFTER INSERT OR UPDATE ON equipment_checkouts
  FOR EACH ROW EXECUTE FUNCTION update_equipment_holder();

-- ============================================================
-- HELPER: Check if equipment is currently checked out
-- ============================================================

CREATE OR REPLACE FUNCTION is_equipment_available(p_equipment_item_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM equipment_checkouts
    WHERE equipment_item_id = p_equipment_item_id
      AND checked_in_at IS NULL
      AND deleted_at IS NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
