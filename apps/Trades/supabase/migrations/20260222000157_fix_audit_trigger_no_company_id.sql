-- Fix: audit_trigger_fn crashes on tables without company_id column
-- Root cause: INSERT/UPDATE/DELETE on child tables (roof_measurements, roof_facets,
-- property_structures, property_features, parcel_boundaries, wall_measurements,
-- trade_bid_data, etc.) fail with:
--   "record 'new' has no field 'company_id'" (error 42703)
-- These tables inherit company scoping through FK joins to parent tables.
--
-- Fix: Use dynamic column check — if company_id exists, use it; otherwise NULL.

CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
  _company_id UUID;
  _record JSONB;
BEGIN
  IF TG_OP = 'DELETE' THEN
    _record := to_jsonb(OLD);
    _company_id := _record->>'company_id';
    INSERT INTO audit_log (table_name, record_id, action, old_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, OLD.id, TG_OP, _record, auth.uid(), _company_id::uuid);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    _record := to_jsonb(NEW);
    _company_id := _record->>'company_id';
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, to_jsonb(OLD), _record, auth.uid(), _company_id::uuid);
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    _record := to_jsonb(NEW);
    _company_id := _record->>'company_id';
    INSERT INTO audit_log (table_name, record_id, action, new_data, user_id, company_id)
    VALUES (TG_TABLE_NAME, NEW.id, TG_OP, _record, auth.uid(), _company_id::uuid);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
