-- U4b: Expand approval entity types for bid & change order approval workflows
-- Sprint U4, Session 110

-- Expand approval_records entity_type constraint
ALTER TABLE approval_records
  DROP CONSTRAINT IF EXISTS approval_records_entity_type_check;

ALTER TABLE approval_records
  ADD CONSTRAINT approval_records_entity_type_check
  CHECK (entity_type IN (
    'maintenance_request', 'vendor_invoice', 'lease',
    'tenant_application', 'expense', 'rent_waiver',
    'bid', 'change_order'
  ));

-- Expand approval_thresholds entity_type constraint
ALTER TABLE approval_thresholds
  DROP CONSTRAINT IF EXISTS approval_thresholds_entity_type_check;

ALTER TABLE approval_thresholds
  ADD CONSTRAINT approval_thresholds_entity_type_check
  CHECK (entity_type IN (
    'maintenance_request', 'vendor_invoice', 'expense',
    'bid', 'change_order'
  ));
