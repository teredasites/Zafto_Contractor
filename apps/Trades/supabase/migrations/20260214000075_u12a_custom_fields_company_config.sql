-- ============================================================
-- U12a: Custom Fields + Company Config + Template Enhancements
-- ============================================================

-- ============================================================
-- 1. ALTER document_templates — add default/trade/usage tracking
-- ============================================================
ALTER TABLE document_templates
  ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS trade_type TEXT,           -- null = all trades
  ADD COLUMN IF NOT EXISTS usage_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Expand template_type CHECK to include bid, estimate, agreement
ALTER TABLE document_templates DROP CONSTRAINT IF EXISTS document_templates_template_type_check;
ALTER TABLE document_templates ADD CONSTRAINT document_templates_template_type_check
  CHECK (template_type IN (
    'contract','proposal','lien_waiver','change_order','invoice',
    'warranty','scope_of_work','safety_plan','daily_report','other',
    'bid','estimate','agreement','warranty_card','safety_form'
  ));

-- Only one default per template_type + trade_type per company
CREATE UNIQUE INDEX IF NOT EXISTS idx_document_templates_default
  ON document_templates (company_id, template_type, trade_type)
  WHERE is_default = true AND deleted_at IS NULL;

-- ============================================================
-- 2. custom_fields TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS custom_fields (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  entity_type TEXT NOT NULL CHECK (entity_type IN (
    'customer','job','bid','invoice','expense','employee'
  )),
  field_name TEXT NOT NULL,        -- machine key (snake_case)
  field_label TEXT NOT NULL,       -- display label
  field_type TEXT NOT NULL CHECK (field_type IN (
    'text','number','date','boolean','select','multi_select','file','email','phone','url','textarea'
  )),
  options JSONB,                   -- for select/multi_select: ["opt1","opt2"]
  required BOOLEAN DEFAULT false,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE custom_fields ENABLE ROW LEVEL SECURITY;

CREATE POLICY "custom_fields_select" ON custom_fields
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "custom_fields_insert" ON custom_fields
  FOR INSERT WITH CHECK (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner','admin','office_manager')
  );
CREATE POLICY "custom_fields_update" ON custom_fields
  FOR UPDATE USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner','admin','office_manager')
  );
CREATE POLICY "custom_fields_delete" ON custom_fields
  FOR DELETE USING (
    company_id = requesting_company_id()
    AND requesting_user_role() IN ('owner','admin')
  );

CREATE TRIGGER custom_fields_updated_at
  BEFORE UPDATE ON custom_fields
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Unique field name per entity type per company
CREATE UNIQUE INDEX IF NOT EXISTS idx_custom_fields_unique_name
  ON custom_fields (company_id, entity_type, field_name)
  WHERE deleted_at IS NULL;

-- ============================================================
-- 3. company_config — dedicated columns on companies.settings JSONB
--    (No new table — use existing companies.settings)
--    Document the expected schema here for reference:
-- ============================================================
-- companies.settings JSONB schema:
-- {
--   "custom_job_statuses": ["status1","status2",...] | null (use defaults),
--   "custom_lead_sources": ["source1","source2",...] | null,
--   "custom_bid_statuses": ["status1","status2",...] | null,
--   "custom_invoice_statuses": ["status1","status2",...] | null,
--   "custom_priority_levels": ["level1","level2",...] | null,
--   "default_tax_rate": 6.35,
--   "tax_rates": [{"name":"CT Sales Tax","rate":6.35,"applies_to":"materials"},...],
--   "default_payment_terms": "net_30",
--   "invoice_number_format": "INV-{YYYY}-{NNNN}",
--   "bid_number_format": "BID-{YYMMDD}-{NNN}",
--   "bid_validity_days": 30,
--   "late_fee_rate": 1.5,
--   "early_payment_discount": 2,
--   "line_item_units": ["ea","lf","sf","hr","day",...],
--   "line_item_categories": ["materials","labor","equipment","subcontractor",...],
--   "currency": "USD"
-- }

-- ============================================================
-- 4. Seed 10+ starter templates (system templates, company_id scoped)
-- ============================================================
-- These are inserted per-company on demand (or as system templates).
-- We use a function that companies can call to seed defaults.

CREATE OR REPLACE FUNCTION seed_default_templates(p_company_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only seed if company has no templates yet
  IF EXISTS (SELECT 1 FROM document_templates WHERE company_id = p_company_id AND deleted_at IS NULL LIMIT 1) THEN
    RETURN;
  END IF;

  INSERT INTO document_templates (company_id, name, description, template_type, content_html, variables, is_system, is_default, trade_type) VALUES
  -- Bid templates
  (p_company_id, 'Standard Bid', 'General-purpose bid template for any trade', 'bid',
   '<h1>{{company_name}}</h1><h2>Bid Proposal</h2><p>Prepared for: {{customer_name}}</p><p>Project: {{project_address}}</p><hr/><h3>Scope of Work</h3><p>{{scope_description}}</p><h3>Line Items</h3>{{line_items_table}}<h3>Total: {{total}}</h3><hr/><h3>Terms & Conditions</h3><p>This bid is valid for {{validity_days}} days from the date of issue.</p><p>Payment terms: {{payment_terms}}</p><hr/><p>{{company_name}} | {{company_phone}} | {{company_email}}</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"scope_description","label":"Scope of Work","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"validity_days","label":"Validity (Days)","type":"number","defaultValue":"30"},{"name":"payment_terms","label":"Payment Terms","type":"text","defaultValue":"Net 30"}]'::jsonb,
   true, true, NULL),

  -- Electrical bid
  (p_company_id, 'Electrical Panel Upgrade Bid', 'Panel upgrade / service change bid template', 'bid',
   '<h1>{{company_name}}</h1><h2>Electrical Panel Upgrade Proposal</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Scope of Work</h3><p>Remove existing {{existing_panel}} panel and install new {{new_panel}} panel.</p><ul><li>Disconnect and reconnect all existing circuits</li><li>Install new main breaker</li><li>Label all circuits per NEC requirements</li><li>Obtain required permits and schedule inspections</li></ul>{{line_items_table}}<h3>Total: {{total}}</h3><p>Permit fees included: {{permit_included}}</p><hr/><p>This bid is valid for 30 days. 50% deposit required to schedule work.</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"existing_panel","label":"Existing Panel","type":"text","defaultValue":"100A"},{"name":"new_panel","label":"New Panel","type":"text","defaultValue":"200A"},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"permit_included","label":"Permits Included","type":"text","defaultValue":"Yes"}]'::jsonb,
   true, false, 'electrical'),

  -- Plumbing estimate
  (p_company_id, 'Plumbing Repair Estimate', 'Standard plumbing repair estimate', 'estimate',
   '<h1>{{company_name}}</h1><h2>Plumbing Repair Estimate</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Issue Description</h3><p>{{issue_description}}</p><h3>Recommended Repairs</h3><p>{{repair_description}}</p>{{line_items_table}}<h3>Estimated Total: {{total}}</h3><p><em>Note: This is an estimate. Final cost may vary based on conditions found during repair.</em></p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"issue_description","label":"Issue Description","type":"textarea","defaultValue":""},{"name":"repair_description","label":"Repair Description","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"}]'::jsonb,
   true, false, 'plumbing'),

  -- HVAC proposal
  (p_company_id, 'HVAC Install Proposal', 'HVAC system installation proposal', 'proposal',
   '<h1>{{company_name}}</h1><h2>HVAC System Proposal</h2><p>Prepared for: {{customer_name}}</p><p>Property: {{project_address}}</p><hr/><h3>System Specifications</h3><p>Unit: {{unit_model}} ({{tonnage}} ton)</p><p>SEER Rating: {{seer_rating}}</p><p>Warranty: {{warranty_years}} years parts & labor</p><h3>Scope of Work</h3><p>{{scope_description}}</p>{{line_items_table}}<h3>Investment: {{total}}</h3><hr/><h3>Financing Available</h3><p>{{financing_details}}</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"unit_model","label":"Unit Model","type":"text","defaultValue":""},{"name":"tonnage","label":"Tonnage","type":"number","defaultValue":"3"},{"name":"seer_rating","label":"SEER Rating","type":"number","defaultValue":"16"},{"name":"warranty_years","label":"Warranty Years","type":"number","defaultValue":"10"},{"name":"scope_description","label":"Scope","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"financing_details","label":"Financing","type":"text","defaultValue":"Ask about our financing options"}]'::jsonb,
   true, false, 'hvac'),

  -- Roofing bid
  (p_company_id, 'Roofing Bid', 'Roof replacement / repair bid', 'bid',
   '<h1>{{company_name}}</h1><h2>Roofing Proposal</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Roof Details</h3><p>Roof Type: {{roof_type}}</p><p>Approximate Area: {{roof_area}} sq ft</p><p>Material: {{material}}</p><h3>Scope of Work</h3><p>{{scope_description}}</p>{{line_items_table}}<h3>Total: {{total}}</h3><hr/><p>Includes cleanup, haul-off, and final inspection. Manufacturer warranty: {{warranty}}.</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"roof_type","label":"Roof Type","type":"text","defaultValue":"Asphalt Shingle"},{"name":"roof_area","label":"Roof Area (sq ft)","type":"number","defaultValue":"2000"},{"name":"material","label":"Material","type":"text","defaultValue":"GAF Timberline HDZ"},{"name":"scope_description","label":"Scope","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"warranty","label":"Warranty","type":"text","defaultValue":"25-year limited lifetime"}]'::jsonb,
   true, false, 'roofing'),

  -- General remodel bid
  (p_company_id, 'General Remodel Bid', 'Residential / commercial remodel proposal', 'bid',
   '<h1>{{company_name}}</h1><h2>Remodel Proposal</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Project Description</h3><p>{{project_description}}</p><h3>Phases</h3><p>{{phases}}</p>{{line_items_table}}<h3>Total: {{total}}</h3><h3>Timeline</h3><p>Estimated duration: {{duration}}</p><p>Start date: {{start_date}}</p><hr/><p>Payment schedule: {{payment_schedule}}</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"project_description","label":"Project Description","type":"textarea","defaultValue":""},{"name":"phases","label":"Phases","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"duration","label":"Duration","type":"text","defaultValue":""},{"name":"start_date","label":"Start Date","type":"date","defaultValue":""},{"name":"payment_schedule","label":"Payment Schedule","type":"text","defaultValue":"1/3 deposit, 1/3 at rough-in, 1/3 at completion"}]'::jsonb,
   true, false, NULL),

  -- Painting estimate
  (p_company_id, 'Painting Estimate', 'Interior / exterior painting estimate', 'estimate',
   '<h1>{{company_name}}</h1><h2>Painting Estimate</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Scope</h3><p>Type: {{paint_type}}</p><p>Area: {{area}} sq ft</p><p>Coats: {{coats}}</p><p>Paint Brand: {{paint_brand}}</p><h3>Preparation</h3><p>{{prep_description}}</p>{{line_items_table}}<h3>Estimated Total: {{total}}</h3>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"paint_type","label":"Interior/Exterior","type":"text","defaultValue":"Interior"},{"name":"area","label":"Area (sq ft)","type":"number","defaultValue":""},{"name":"coats","label":"Number of Coats","type":"number","defaultValue":"2"},{"name":"paint_brand","label":"Paint Brand","type":"text","defaultValue":"Sherwin-Williams"},{"name":"prep_description","label":"Prep Work","type":"textarea","defaultValue":""},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"}]'::jsonb,
   true, false, 'painting'),

  -- Concrete/paving bid
  (p_company_id, 'Concrete & Paving Bid', 'Flatwork, driveways, foundations', 'bid',
   '<h1>{{company_name}}</h1><h2>Concrete / Paving Proposal</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Project Scope</h3><p>Type: {{concrete_type}}</p><p>Area: {{area}} sq ft</p><p>Thickness: {{thickness}}"</p><p>Finish: {{finish}}</p>{{line_items_table}}<h3>Total: {{total}}</h3><hr/><p>Weather-dependent scheduling. Cure time: {{cure_time}}.</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"concrete_type","label":"Type","type":"text","defaultValue":"Driveway"},{"name":"area","label":"Area (sq ft)","type":"number","defaultValue":""},{"name":"thickness","label":"Thickness (inches)","type":"number","defaultValue":"4"},{"name":"finish","label":"Finish","type":"text","defaultValue":"Broom finish"},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"cure_time","label":"Cure Time","type":"text","defaultValue":"28 days"}]'::jsonb,
   true, false, 'concrete'),

  -- Fencing estimate
  (p_company_id, 'Fencing Estimate', 'Residential / commercial fencing', 'estimate',
   '<h1>{{company_name}}</h1><h2>Fencing Estimate</h2><p>Customer: {{customer_name}}</p><p>Address: {{project_address}}</p><hr/><h3>Fence Details</h3><p>Type: {{fence_type}}</p><p>Height: {{height}} ft</p><p>Linear Feet: {{linear_feet}}</p><p>Gates: {{gates}}</p>{{line_items_table}}<h3>Total: {{total}}</h3>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Project Address","type":"text","defaultValue":""},{"name":"fence_type","label":"Fence Type","type":"text","defaultValue":"Wood Privacy"},{"name":"height","label":"Height (ft)","type":"number","defaultValue":"6"},{"name":"linear_feet","label":"Linear Feet","type":"number","defaultValue":""},{"name":"gates","label":"Number of Gates","type":"number","defaultValue":"1"},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"}]'::jsonb,
   true, false, 'fencing'),

  -- Standard Invoice
  (p_company_id, 'Standard Invoice', 'Default invoice template', 'invoice',
   '<h1>{{company_name}}</h1><h2>INVOICE #{{invoice_number}}</h2><p>Date: {{invoice_date}}</p><p>Due: {{due_date}}</p><hr/><p><strong>Bill To:</strong></p><p>{{customer_name}}</p><p>{{customer_address}}</p><hr/>{{line_items_table}}<table><tr><td>Subtotal</td><td>{{subtotal}}</td></tr><tr><td>Tax ({{tax_rate}}%)</td><td>{{tax_amount}}</td></tr><tr><td><strong>Total</strong></td><td><strong>{{total}}</strong></td></tr></table><hr/><p>Payment Terms: {{payment_terms}}</p><p>Make checks payable to: {{company_name}}</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"invoice_number","label":"Invoice #","type":"text","defaultValue":""},{"name":"invoice_date","label":"Date","type":"date","defaultValue":""},{"name":"due_date","label":"Due Date","type":"date","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"customer_address","label":"Customer Address","type":"text","defaultValue":""},{"name":"subtotal","label":"Subtotal","type":"currency","defaultValue":"0.00"},{"name":"tax_rate","label":"Tax Rate","type":"number","defaultValue":"6.35"},{"name":"tax_amount","label":"Tax Amount","type":"currency","defaultValue":"0.00"},{"name":"total","label":"Total","type":"currency","defaultValue":"0.00"},{"name":"payment_terms","label":"Payment Terms","type":"text","defaultValue":"Net 30"}]'::jsonb,
   true, true, NULL),

  -- Service Agreement
  (p_company_id, 'Service Agreement', 'Recurring service / maintenance agreement', 'agreement',
   '<h1>{{company_name}}</h1><h2>Service Agreement</h2><p>Agreement Date: {{agreement_date}}</p><hr/><h3>Parties</h3><p><strong>Service Provider:</strong> {{company_name}}</p><p><strong>Client:</strong> {{customer_name}}</p><p><strong>Property:</strong> {{project_address}}</p><hr/><h3>Services Included</h3><p>{{services_description}}</p><h3>Service Schedule</h3><p>{{schedule}}</p><h3>Term</h3><p>{{term_length}}, auto-renewing unless cancelled with 30 days notice.</p><h3>Pricing</h3><p>{{pricing}}</p><hr/><h3>Signatures</h3><p>Provider: _________________________ Date: ________</p><p>Client: _________________________ Date: ________</p>',
   '[{"name":"company_name","label":"Company Name","type":"text","defaultValue":""},{"name":"agreement_date","label":"Agreement Date","type":"date","defaultValue":""},{"name":"customer_name","label":"Customer Name","type":"text","defaultValue":""},{"name":"project_address","label":"Property Address","type":"text","defaultValue":""},{"name":"services_description","label":"Services","type":"textarea","defaultValue":""},{"name":"schedule","label":"Schedule","type":"text","defaultValue":"Quarterly"},{"name":"term_length","label":"Term","type":"text","defaultValue":"12 months"},{"name":"pricing","label":"Pricing","type":"text","defaultValue":""}]'::jsonb,
   true, false, NULL);
END;
$$;

-- Audit trigger on custom_fields
CREATE TRIGGER audit_custom_fields
  AFTER INSERT OR UPDATE OR DELETE ON custom_fields
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
