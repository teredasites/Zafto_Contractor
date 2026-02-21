-- DEPTH31: Crowdsourced Material Pricing Intelligence
-- Receipt OCR pipeline, supplier directory, pricing engine, distributor APIs,
-- anonymized market data, price trends, contributor incentives.

-- ============================================================================
-- SUPPLIER DIRECTORY (system-wide, no company_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplier_directory (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  name_normalized text NOT NULL,
  aliases        text[] DEFAULT '{}',
  supplier_type  text NOT NULL DEFAULT 'unknown'
    CHECK (supplier_type IN ('big_box','specialty_distributor','supply_house','online','local_yard','manufacturer_direct','equipment_rental','unknown')),
  trades_served  text[] DEFAULT '{}',
  website        text,
  phone          text,
  locations_approximate text[] DEFAULT '{}',
  pricing_tier   text NOT NULL DEFAULT 'retail'
    CHECK (pricing_tier IN ('retail','wholesale','account_only','mixed')),
  avg_discount_from_retail_pct numeric(5,2),
  receipt_count  integer NOT NULL DEFAULT 0,
  has_api        boolean NOT NULL DEFAULT false,
  api_type       text,
  affiliate_network text,
  first_seen_at  timestamptz NOT NULL DEFAULT now(),
  last_seen_at   timestamptz NOT NULL DEFAULT now(),
  is_verified    boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  deleted_at     timestamptz
);

CREATE INDEX idx_supplier_directory_name_norm ON supplier_directory (name_normalized);
CREATE INDEX idx_supplier_directory_type ON supplier_directory (supplier_type) WHERE deleted_at IS NULL;
CREATE INDEX idx_supplier_directory_trades ON supplier_directory USING gin (trades_served) WHERE deleted_at IS NULL;

ALTER TABLE supplier_directory ENABLE ROW LEVEL SECURITY;

-- Supplier directory is readable by all authenticated users
CREATE POLICY "supplier_directory_select" ON supplier_directory
  FOR SELECT TO authenticated USING (deleted_at IS NULL);

-- Only super_admin can modify supplier directory
CREATE POLICY "supplier_directory_admin" ON supplier_directory
  FOR ALL TO authenticated
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'super_admin'
  );

SELECT update_updated_at('supplier_directory');

-- ============================================================================
-- MATERIAL RECEIPTS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS material_receipts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  uploaded_by       uuid NOT NULL REFERENCES auth.users(id),
  supplier_id       uuid REFERENCES supplier_directory(id),
  supplier_name_raw text,
  supplier_address   text,
  receipt_date      date,
  subtotal          numeric(12,2),
  tax               numeric(12,2),
  total             numeric(12,2),
  payment_method    text,
  receipt_image_url text,
  ocr_raw_text      text,
  ocr_confidence    numeric(5,2),
  processing_status text NOT NULL DEFAULT 'pending'
    CHECK (processing_status IN ('pending','processing','processed','needs_review','failed')),
  reviewed_by       uuid REFERENCES auth.users(id),
  reviewed_at       timestamptz,
  linked_job_id     uuid,
  linked_expense_id uuid,
  source            text NOT NULL DEFAULT 'upload'
    CHECK (source IN ('upload','camera','email_forward','zbooks_sync')),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);

CREATE INDEX idx_material_receipts_company ON material_receipts (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_material_receipts_supplier ON material_receipts (supplier_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_material_receipts_status ON material_receipts (processing_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_material_receipts_date ON material_receipts (receipt_date DESC) WHERE deleted_at IS NULL;

ALTER TABLE material_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "material_receipts_select" ON material_receipts
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

CREATE POLICY "material_receipts_insert" ON material_receipts
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "material_receipts_update" ON material_receipts
  FOR UPDATE TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  )
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

SELECT update_updated_at('material_receipts');

-- ============================================================================
-- MATERIAL RECEIPT ITEMS (line items from receipts)
-- ============================================================================

CREATE TABLE IF NOT EXISTS material_receipt_items (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id             uuid NOT NULL REFERENCES material_receipts(id) ON DELETE CASCADE,
  company_id             uuid NOT NULL REFERENCES companies(id),
  description_raw        text,
  description_normalized text,
  sku                    text,
  upc                    text,
  brand                  text,
  product_name_normalized text,
  material_category      text,
  trade                  text,
  quantity               numeric(12,4) NOT NULL DEFAULT 1,
  unit                   text DEFAULT 'each'
    CHECK (unit IN ('each','ft','lf','sqft','sq','bundle','box','roll','bag','gallon','lb','yd','cuyd','sheet','pair','set','case','pallet','ton','other')),
  unit_price             numeric(12,4),
  total                  numeric(12,2),
  ocr_confidence         numeric(5,2),
  manually_corrected     boolean NOT NULL DEFAULT false,
  correction_source      text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now(),
  deleted_at             timestamptz
);

CREATE INDEX idx_receipt_items_receipt ON material_receipt_items (receipt_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipt_items_company ON material_receipt_items (company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipt_items_product ON material_receipt_items (product_name_normalized) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipt_items_category ON material_receipt_items (material_category, trade) WHERE deleted_at IS NULL;
CREATE INDEX idx_receipt_items_upc ON material_receipt_items (upc) WHERE upc IS NOT NULL AND deleted_at IS NULL;

ALTER TABLE material_receipt_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipt_items_select" ON material_receipt_items
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

CREATE POLICY "receipt_items_insert" ON material_receipt_items
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "receipt_items_update" ON material_receipt_items
  FOR UPDATE TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  )
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

SELECT update_updated_at('material_receipt_items');

-- ============================================================================
-- MATERIAL PRICE INDEX (anonymized aggregate — NO company_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS material_price_index (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_name_normalized text NOT NULL,
  material_category      text NOT NULL,
  trade                  text,
  brand                  text,
  sku_common             text,
  upc_common             text,
  unit                   text NOT NULL DEFAULT 'each',
  avg_price_national     numeric(12,4),
  avg_price_by_metro     jsonb DEFAULT '{}',
  price_low              numeric(12,4),
  price_high             numeric(12,4),
  price_median           numeric(12,4),
  sample_count           integer NOT NULL DEFAULT 0,
  min_companies_required integer NOT NULL DEFAULT 5,
  is_published           boolean NOT NULL DEFAULT false,
  last_updated           timestamptz NOT NULL DEFAULT now(),
  trend_30d_pct          numeric(6,2),
  trend_90d_pct          numeric(6,2),
  trend_12m_pct          numeric(6,2),
  price_history          jsonb DEFAULT '[]',
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_price_index_product ON material_price_index (product_name_normalized);
CREATE INDEX idx_price_index_category ON material_price_index (material_category, trade);
CREATE INDEX idx_price_index_published ON material_price_index (is_published) WHERE is_published = true;
CREATE INDEX idx_price_index_upc ON material_price_index (upc_common) WHERE upc_common IS NOT NULL;

ALTER TABLE material_price_index ENABLE ROW LEVEL SECURITY;

-- Published price index is readable by all authenticated users
CREATE POLICY "price_index_select" ON material_price_index
  FOR SELECT TO authenticated USING (is_published = true);

-- Only system (service_role) can write to price index
CREATE POLICY "price_index_system" ON material_price_index
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('material_price_index');

-- ============================================================================
-- MATERIAL PRICE INDICES (BLS/FRED PPI data)
-- ============================================================================

CREATE TABLE IF NOT EXISTS material_price_indices (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id       text NOT NULL,
  category        text NOT NULL,
  region          text,
  date            date NOT NULL,
  value           numeric(12,4) NOT NULL,
  pct_change_1mo  numeric(6,2),
  pct_change_12mo numeric(6,2),
  source          text NOT NULL DEFAULT 'bls',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (series_id, date)
);

CREATE INDEX idx_price_indices_series ON material_price_indices (series_id, date DESC);
CREATE INDEX idx_price_indices_category ON material_price_indices (category, date DESC);

ALTER TABLE material_price_indices ENABLE ROW LEVEL SECURITY;

-- PPI data is readable by all authenticated users
CREATE POLICY "price_indices_select" ON material_price_indices
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "price_indices_system" ON material_price_indices
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('material_price_indices');

-- ============================================================================
-- REGIONAL COST FACTORS
-- ============================================================================

CREATE TABLE IF NOT EXISTS regional_cost_factors (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  state            text NOT NULL,
  metro_area       text,
  trade            text,
  multiplier       numeric(6,4) NOT NULL DEFAULT 1.0000,
  wage_component   numeric(6,4),
  material_component numeric(6,4),
  last_calculated  timestamptz NOT NULL DEFAULT now(),
  source           text NOT NULL DEFAULT 'bls',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now(),
  UNIQUE (state, metro_area, trade)
);

CREATE INDEX idx_regional_cost_state ON regional_cost_factors (state);
CREATE INDEX idx_regional_cost_metro ON regional_cost_factors (metro_area) WHERE metro_area IS NOT NULL;

ALTER TABLE regional_cost_factors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "regional_cost_select" ON regional_cost_factors
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "regional_cost_system" ON regional_cost_factors
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('regional_cost_factors');

-- ============================================================================
-- DISTRIBUTOR ACCOUNTS (company-scoped, encrypted credentials)
-- ============================================================================

CREATE TABLE IF NOT EXISTS distributor_accounts (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id),
  supplier_id       uuid NOT NULL REFERENCES supplier_directory(id),
  account_number    text,
  username_encrypted text,
  api_key_encrypted text,
  connection_status text NOT NULL DEFAULT 'pending'
    CHECK (connection_status IN ('pending','connected','disconnected','error','expired')),
  last_sync_at      timestamptz,
  sync_error        text,
  use_account_pricing boolean NOT NULL DEFAULT true,
  created_by        uuid NOT NULL REFERENCES auth.users(id),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz,
  UNIQUE (company_id, supplier_id)
);

CREATE INDEX idx_distributor_accounts_company ON distributor_accounts (company_id) WHERE deleted_at IS NULL;

ALTER TABLE distributor_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "distributor_accounts_select" ON distributor_accounts
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

CREATE POLICY "distributor_accounts_insert" ON distributor_accounts
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "distributor_accounts_update" ON distributor_accounts
  FOR UPDATE TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  )
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

SELECT update_updated_at('distributor_accounts');

-- ============================================================================
-- PRICE ALERTS (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS price_alerts (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id     uuid NOT NULL REFERENCES companies(id),
  user_id        uuid NOT NULL REFERENCES auth.users(id),
  product_query  text NOT NULL,
  product_name   text,
  material_category text,
  target_price   numeric(12,4),
  current_price  numeric(12,4),
  alert_type     text NOT NULL DEFAULT 'below_price'
    CHECK (alert_type IN ('below_price','price_drop_pct','back_in_stock')),
  drop_pct_threshold numeric(5,2),
  is_active      boolean NOT NULL DEFAULT true,
  triggered_at   timestamptz,
  notified_at    timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  deleted_at     timestamptz
);

CREATE INDEX idx_price_alerts_company ON price_alerts (company_id) WHERE deleted_at IS NULL AND is_active = true;
CREATE INDEX idx_price_alerts_user ON price_alerts (user_id) WHERE deleted_at IS NULL AND is_active = true;

ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "price_alerts_select" ON price_alerts
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  );

CREATE POLICY "price_alerts_insert" ON price_alerts
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "price_alerts_update" ON price_alerts
  FOR UPDATE TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    AND deleted_at IS NULL
  )
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

SELECT update_updated_at('price_alerts');

-- ============================================================================
-- PRICING CONTRIBUTOR STATUS (company-level opt-in/opt-out)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pricing_contributor_status (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id        uuid NOT NULL REFERENCES companies(id) UNIQUE,
  is_contributor    boolean NOT NULL DEFAULT true,
  opted_out_at      timestamptz,
  receipt_count     integer NOT NULL DEFAULT 0,
  items_contributed integer NOT NULL DEFAULT 0,
  badge_level       text NOT NULL DEFAULT 'none'
    CHECK (badge_level IN ('none','bronze','silver','gold','platinum')),
  last_contribution_at timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_contributor_status_company ON pricing_contributor_status (company_id);

ALTER TABLE pricing_contributor_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "contributor_status_select" ON pricing_contributor_status
  FOR SELECT TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "contributor_status_upsert" ON pricing_contributor_status
  FOR INSERT TO authenticated
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY "contributor_status_update" ON pricing_contributor_status
  FOR UPDATE TO authenticated
  USING (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  )
  WITH CHECK (
    company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

SELECT update_updated_at('pricing_contributor_status');

-- ============================================================================
-- SEED: SUPPLIER DIRECTORY (60+ known suppliers)
-- ============================================================================

INSERT INTO supplier_directory (name, name_normalized, aliases, supplier_type, trades_served, website, pricing_tier, has_api, api_type, affiliate_network, is_verified) VALUES
-- Big Box (2)
('Home Depot', 'home depot', ARRAY['The Home Depot','HD','THD'], 'big_box', ARRAY['all'], 'homedepot.com', 'retail', false, NULL, 'impact_radius', true),
('Lowes', 'lowes', ARRAY['Lowe''s','Lowes Home Improvement'], 'big_box', ARRAY['all'], 'lowes.com', 'retail', false, NULL, 'cj_affiliate', true),

-- Electrical Distributors (10)
('Graybar', 'graybar', ARRAY['Graybar Electric','Graybar Electric Company'], 'specialty_distributor', ARRAY['electrical'], 'graybar.com', 'wholesale', false, NULL, NULL, true),
('Rexel', 'rexel', ARRAY['Rexel USA','Platt Electric Supply','Platt','CED'], 'specialty_distributor', ARRAY['electrical','solar'], 'rexelusa.com', 'wholesale', false, NULL, NULL, true),
('WESCO', 'wesco', ARRAY['WESCO International','Anixter','WESCO/Anixter'], 'specialty_distributor', ARRAY['electrical','data_comm'], 'wesco.com', 'wholesale', false, NULL, NULL, true),
('City Electric Supply', 'city electric supply', ARRAY['CES','City Electric'], 'specialty_distributor', ARRAY['electrical'], 'cityelectricsupply.com', 'wholesale', false, NULL, NULL, true),
('Border States Electric', 'border states electric', ARRAY['Border States','BSE'], 'specialty_distributor', ARRAY['electrical'], 'borderstates.com', 'wholesale', false, NULL, NULL, true),
('Crescent Electric', 'crescent electric', ARRAY['Crescent Electric Supply'], 'specialty_distributor', ARRAY['electrical'], 'cesco.com', 'wholesale', false, NULL, NULL, true),
('Elliott Electric Supply', 'elliott electric supply', ARRAY['Elliott Electric'], 'specialty_distributor', ARRAY['electrical'], 'elliottelectric.com', 'wholesale', false, NULL, NULL, true),
('McNaughton-McKay', 'mcnaughton-mckay', ARRAY['McNaughton-McKay Electric','McNaughton McKay','MC-MC'], 'specialty_distributor', ARRAY['electrical','automation'], 'mc-mc.com', 'wholesale', false, NULL, NULL, true),
('Mayer Electric', 'mayer electric', ARRAY['Mayer Electric Supply'], 'specialty_distributor', ARRAY['electrical'], 'mayerelectric.com', 'wholesale', false, NULL, NULL, true),
('Consolidated Electrical Distributors', 'consolidated electrical distributors', ARRAY['CED Greentech','CED'], 'specialty_distributor', ARRAY['electrical','solar'], 'cedgreentech.com', 'wholesale', false, NULL, NULL, true),

-- Plumbing Distributors (8)
('Ferguson', 'ferguson', ARRAY['Ferguson Enterprises','Ferguson Supply','FergusonDERA'], 'specialty_distributor', ARRAY['plumbing','hvac','waterworks'], 'ferguson.com', 'wholesale', true, 'rest_api', 'impact_radius', true),
('Hajoca', 'hajoca', ARRAY['Hajoca Corporation'], 'specialty_distributor', ARRAY['plumbing','hvac','industrial'], 'hajoca.com', 'wholesale', false, NULL, NULL, true),
('Winsupply', 'winsupply', ARRAY['Win Supply','Winsupply Inc'], 'specialty_distributor', ARRAY['plumbing','hvac','waterworks','electrical'], 'winsupply.com', 'wholesale', false, NULL, NULL, true),
('F.W. Webb', 'fw webb', ARRAY['F.W. Webb Company','FW Webb'], 'specialty_distributor', ARRAY['plumbing','hvac','industrial'], 'fwwebb.com', 'wholesale', false, NULL, NULL, true),
('Morrison Supply', 'morrison supply', ARRAY['Morrison Supply Company'], 'specialty_distributor', ARRAY['plumbing','hvac'], 'morrisonsupply.com', 'wholesale', false, NULL, NULL, true),
('Moore Supply', 'moore supply', ARRAY['Moore Supply Co'], 'specialty_distributor', ARRAY['plumbing'], 'mooresupply.com', 'wholesale', false, NULL, NULL, true),
('Standard Supply', 'standard supply', ARRAY['Standard Supply Group'], 'specialty_distributor', ARRAY['plumbing'], 'standardsupply.com', 'wholesale', false, NULL, NULL, true),
('Dakota Supply Group', 'dakota supply group', ARRAY['DSG','Dakota Supply'], 'specialty_distributor', ARRAY['plumbing','hvac','electrical','waterworks'], 'dakotasupplygroup.com', 'wholesale', false, NULL, NULL, true),

-- HVAC Distributors (8)
('Carrier Enterprise', 'carrier enterprise', ARRAY['CE','Carrier Enterprise LLC'], 'specialty_distributor', ARRAY['hvac'], '?"carrierenterprise.com', 'wholesale', false, NULL, NULL, true),
('Johnstone Supply', 'johnstone supply', ARRAY['Johnstone'], 'specialty_distributor', ARRAY['hvac','refrigeration'], '?"johnstonesupply.com', 'wholesale', false, NULL, NULL, true),
('Baker Distributing', 'baker distributing', ARRAY['Baker Distributing Company'], 'specialty_distributor', ARRAY['hvac'], '?"?"bakerdist.com', 'wholesale', false, NULL, NULL, true),
('RE Michel', 're michel', ARRAY['RE Michel Company','R.E. Michel'], 'specialty_distributor', ARRAY['hvac','refrigeration'], 'remichel.com', 'wholesale', false, NULL, NULL, true),
('ACR Group', 'acr group', ARRAY['ACR Supply'], 'specialty_distributor', ARRAY['hvac','refrigeration'], '?"acrgroup.com', 'wholesale', false, NULL, NULL, true),
('Gemaire Distributors', 'gemaire distributors', ARRAY['Gemaire'], 'specialty_distributor', ARRAY['hvac'], 'gemaire.com', 'wholesale', false, NULL, NULL, true),
('US Air Conditioning Distributors', 'us air conditioning distributors', ARRAY['USACD','US AC Distributors'], 'specialty_distributor', ARRAY['hvac'], '?"?"usaircon.com', 'wholesale', false, NULL, NULL, true),
('Trane Supply', 'trane supply', ARRAY['Trane Commercial'], 'specialty_distributor', ARRAY['hvac'], '?"?"?"?"?"?"tranesupply.com', 'wholesale', false, NULL, NULL, true),

-- Roofing/Exterior Distributors (6)
('ABC Supply', 'abc supply', ARRAY['ABC Supply Co','American Builders & Contractors Supply'], 'specialty_distributor', ARRAY['roofing','siding','gutters','windows','doors'], 'abcsupply.com', 'wholesale', true, 'rest_api', NULL, true),
('SRS Distribution', 'srs distribution', ARRAY['SRS','Southern Roofing Supply','Allied Building Products','Heritage Building & Lumber','Roof Depot'], 'specialty_distributor', ARRAY['roofing','siding'], 'srsdistribution.com', 'wholesale', true, 'rest_api', NULL, true),
('Beacon Building Products', 'beacon building products', ARRAY['Beacon','Beacon Roofing Supply'], 'specialty_distributor', ARRAY['roofing','siding','waterproofing'], 'becn.com', 'wholesale', false, NULL, NULL, true),
('Gulfeagle Supply', 'gulfeagle supply', ARRAY['Gulfeagle'], 'specialty_distributor', ARRAY['roofing'], 'gulfeaglesupply.com', 'wholesale', false, NULL, NULL, true),
('MFS Supply', 'mfs supply', ARRAY['MFS','Malvern roofing supply'], 'specialty_distributor', ARRAY['roofing','siding','gutters'], 'mfssupply.com', 'wholesale', false, NULL, NULL, true),
('Bradco Supply', 'bradco supply', ARRAY['Bradco'], 'specialty_distributor', ARRAY['roofing','siding'], 'bradcosupply.com', 'wholesale', false, NULL, NULL, true),

-- Lumber/Building Materials (8)
('84 Lumber', '84 lumber', ARRAY['84 Lumber Company'], 'supply_house', ARRAY['framing','general'], '84lumber.com', 'wholesale', false, NULL, NULL, true),
('Builders FirstSource', 'builders firstsource', ARRAY['BFS','Builders First Source'], 'supply_house', ARRAY['framing','general','windows','doors'], 'bldr.com', 'wholesale', false, NULL, NULL, true),
('US LBM', 'us lbm', ARRAY['US LBM Holdings','BMC'], 'supply_house', ARRAY['framing','general'], 'uslbm.com', 'wholesale', false, NULL, NULL, true),
('Parr Lumber', 'parr lumber', ARRAY['Parr Lumber Company'], 'supply_house', ARRAY['framing','general'], 'parrlumber.com', 'mixed', false, NULL, NULL, true),
('McCoys Building Supply', 'mccoys building supply', ARRAY['McCoy''s','McCoys'], 'supply_house', ARRAY['general'], 'mccoys.com', 'mixed', false, NULL, NULL, true),
('Carter Lumber', 'carter lumber', ARRAY['Carter Lumber Company'], 'supply_house', ARRAY['framing','general'], 'carterlumber.com', 'mixed', false, NULL, NULL, true),
('Sutherland Lumber', 'sutherland lumber', ARRAY['Sutherlands','Sutherland Lumber Company'], 'supply_house', ARRAY['general'], 'sutherlands.com', 'retail', false, NULL, NULL, true),
('BlueLinx', 'bluelinx', ARRAY['BlueLinx Holdings','BlueLinx Corporation'], 'specialty_distributor', ARRAY['framing','siding','general'], 'bluelinxco.com', 'wholesale', false, NULL, NULL, true),

-- Concrete/Masonry (4)
('Quikrete', 'quikrete', ARRAY['The Quikrete Companies'], 'manufacturer_direct', ARRAY['concrete','masonry'], 'quikrete.com', 'retail', false, NULL, NULL, true),
('Sakrete', 'sakrete', ARRAY['Sakrete of North America'], 'manufacturer_direct', ARRAY['concrete','masonry'], 'sakrete.com', 'retail', false, NULL, NULL, true),
('SPEC MIX', 'spec mix', ARRAY['SPEC MIX LLC'], 'manufacturer_direct', ARRAY['concrete','masonry'], 'specmix.com', 'wholesale', false, NULL, NULL, true),
('US Concrete', 'us concrete', ARRAY['U.S. Concrete'], 'manufacturer_direct', ARRAY['concrete'], 'us-concrete.com', 'wholesale', false, NULL, NULL, true),

-- Paint (4)
('Sherwin-Williams', 'sherwin-williams', ARRAY['Sherwin Williams','SW'], 'specialty_distributor', ARRAY['painting'], 'sherwin-williams.com', 'mixed', false, NULL, NULL, true),
('Benjamin Moore', 'benjamin moore', ARRAY['Benjamin Moore & Co'], 'specialty_distributor', ARRAY['painting'], 'benjaminmoore.com', 'mixed', false, NULL, NULL, true),
('PPG', 'ppg', ARRAY['PPG Industries','Glidden','PPG Paints'], 'manufacturer_direct', ARRAY['painting'], 'ppg.com', 'mixed', false, NULL, NULL, true),
('Dunn-Edwards', 'dunn-edwards', ARRAY['Dunn Edwards','Dunn-Edwards Corporation'], 'specialty_distributor', ARRAY['painting'], 'dunnedwards.com', 'mixed', false, NULL, NULL, true),

-- Flooring (4)
('Floor & Decor', 'floor and decor', ARRAY['Floor and Decor','FND'], 'big_box', ARRAY['flooring','tile'], 'flooranddecor.com', 'retail', false, NULL, NULL, true),
('Shaw Direct', 'shaw direct', ARRAY['Shaw Floors','Shaw Industries'], 'manufacturer_direct', ARRAY['flooring'], 'shawfloors.com', 'mixed', false, NULL, NULL, true),
('Mohawk', 'mohawk', ARRAY['Mohawk Industries','Mohawk Flooring'], 'manufacturer_direct', ARRAY['flooring'], 'mohawkflooring.com', 'mixed', false, NULL, NULL, true),
('MSI', 'msi', ARRAY['MS International','MSI Surfaces'], 'specialty_distributor', ARRAY['flooring','tile','countertops'], 'msisurfaces.com', 'wholesale', false, NULL, NULL, true),

-- Online/Bulk (6)
('Amazon', 'amazon', ARRAY['Amazon.com','Amazon Business'], 'online', ARRAY['all'], 'amazon.com', 'retail', true, 'pa_api', 'amazon', true),
('Zoro', 'zoro', ARRAY['Zoro.com','Zoro Tools'], 'online', ARRAY['all'], 'zoro.com', 'retail', false, NULL, NULL, true),
('Grainger', 'grainger', ARRAY['W.W. Grainger','WW Grainger'], 'online', ARRAY['all'], 'grainger.com', 'mixed', false, NULL, NULL, true),
('Fastenal', 'fastenal', ARRAY['Fastenal Company'], 'supply_house', ARRAY['all'], 'fastenal.com', 'mixed', false, NULL, NULL, true),
('McMaster-Carr', 'mcmaster-carr', ARRAY['McMaster','McMaster Carr'], 'online', ARRAY['all'], 'mcmaster.com', 'mixed', true, 'rest_api', NULL, true),
('Global Industrial', 'global industrial', ARRAY['Global Industrial Company'], 'online', ARRAY['all'], 'globalindustrial.com', 'retail', false, NULL, NULL, true),

-- Landscaping (4)
('SiteOne', 'siteone', ARRAY['SiteOne Landscape Supply'], 'specialty_distributor', ARRAY['landscaping','irrigation'], 'siteone.com', 'wholesale', true, 'rest_api', NULL, true),
('Ewing Irrigation', 'ewing irrigation', ARRAY['Ewing Outdoor Supply','Ewing'], 'specialty_distributor', ARRAY['landscaping','irrigation'], 'ewingirrigation.com', 'wholesale', false, NULL, NULL, true),
('Horizon Distributors', 'horizon distributors', ARRAY['Horizon'], 'specialty_distributor', ARRAY['landscaping','irrigation'], 'horizononline.com', 'wholesale', false, NULL, NULL, true),
('SprinklerWarehouse', 'sprinklerwarehouse', ARRAY['Sprinkler Warehouse'], 'online', ARRAY['irrigation','landscaping'], 'sprinklerwarehouse.com', 'retail', false, NULL, NULL, true),

-- Equipment Rental (4)
('United Rentals', 'united rentals', ARRAY['URI','United Rentals Inc'], 'equipment_rental', ARRAY['all'], 'unitedrentals.com', 'mixed', false, NULL, NULL, true),
('Sunbelt Rentals', 'sunbelt rentals', ARRAY['Sunbelt'], 'equipment_rental', ARRAY['all'], 'sunbeltrentals.com', 'mixed', false, NULL, NULL, true),
('Herc Rentals', 'herc rentals', ARRAY['Herc Holdings','Hertz Equipment Rental'], 'equipment_rental', ARRAY['all'], 'hercrentals.com', 'mixed', false, NULL, NULL, true),
('BigRentz', 'bigrentz', ARRAY['Big Rentz'], 'equipment_rental', ARRAY['all'], 'bigrentz.com', 'mixed', false, NULL, NULL, true),

-- Online Plumbing (2)
('SupplyHouse', 'supplyhouse', ARRAY['SupplyHouse.com'], 'online', ARRAY['plumbing','hvac','electrical'], 'supplyhouse.com', 'retail', false, NULL, NULL, true),
('PlumbersStock', 'plumbersstock', ARRAY['PlumbersStock.com'], 'online', ARRAY['plumbing'], 'plumbersstock.com', 'retail', false, NULL, NULL, true),

-- Hardware (2)
('Ace Hardware', 'ace hardware', ARRAY['Ace','Ace Hardware Corporation'], 'big_box', ARRAY['all'], 'acehardware.com', 'retail', false, NULL, 'cj_affiliate', true),
('Harbor Freight', 'harbor freight', ARRAY['Harbor Freight Tools'], 'big_box', ARRAY['tools'], 'harborfreight.com', 'retail', false, NULL, 'cj_affiliate', true)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- AUDIT TRIGGERS
-- ============================================================================

SELECT audit_trigger_fn('material_receipts');
SELECT audit_trigger_fn('material_receipt_items');
SELECT audit_trigger_fn('distributor_accounts');
SELECT audit_trigger_fn('price_alerts');
SELECT audit_trigger_fn('pricing_contributor_status');
