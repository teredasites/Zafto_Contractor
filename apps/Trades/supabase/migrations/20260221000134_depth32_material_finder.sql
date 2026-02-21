-- DEPTH32: Material Finder — Contractor's Search Engine for Every Supplier
-- Supplier product catalog, affiliate link tracking, product favorites,
-- recently viewed products, expanded supplier directory seed (200+).

-- ============================================================================
-- SUPPLIER PRODUCTS (system-wide product catalog — NO company_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplier_products (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id         uuid NOT NULL REFERENCES supplier_directory(id),
  external_product_id text,
  name                text NOT NULL,
  description         text,
  brand               text,
  model_number        text,
  sku                 text,
  upc                 text,
  category_path       text,
  trade               text,
  material_category   text,
  price               numeric(12,4),
  sale_price          numeric(12,4),
  sale_end_date       date,
  in_stock            boolean DEFAULT true,
  image_url           text,
  product_url         text,
  affiliate_network   text
    CHECK (affiliate_network IS NULL OR affiliate_network IN ('impact_radius','cj_affiliate','amazon','direct','none')),
  commission_rate     numeric(5,2),
  last_feed_update    timestamptz,
  price_history       jsonb DEFAULT '[]',
  specs               jsonb DEFAULT '{}',
  rating              numeric(3,2),
  review_count        integer DEFAULT 0,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  deleted_at          timestamptz
);

-- Full-text search index
CREATE INDEX idx_supplier_products_search ON supplier_products
  USING gin (to_tsvector('english', coalesce(name, '') || ' ' || coalesce(brand, '') || ' ' || coalesce(description, '') || ' ' || coalesce(sku, '')))
  WHERE deleted_at IS NULL;

CREATE INDEX idx_supplier_products_supplier ON supplier_products (supplier_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_supplier_products_trade ON supplier_products (trade, material_category) WHERE deleted_at IS NULL;
CREATE INDEX idx_supplier_products_price ON supplier_products (price) WHERE deleted_at IS NULL AND price IS NOT NULL;
CREATE INDEX idx_supplier_products_upc ON supplier_products (upc) WHERE upc IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_supplier_products_sku ON supplier_products (sku) WHERE sku IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_supplier_products_brand ON supplier_products (brand) WHERE deleted_at IS NULL;
-- Trigram index for fuzzy name search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_supplier_products_name_trgm ON supplier_products USING gin (name gin_trgm_ops) WHERE deleted_at IS NULL;

ALTER TABLE supplier_products ENABLE ROW LEVEL SECURITY;

-- Product catalog is readable by all authenticated users
CREATE POLICY "supplier_products_select" ON supplier_products
  FOR SELECT TO authenticated USING (deleted_at IS NULL);

-- Only service_role can write (nightly feed ingestion)
CREATE POLICY "supplier_products_system" ON supplier_products
  FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('supplier_products');

-- ============================================================================
-- AFFILIATE CLICKS (revenue tracking — company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS affiliate_clicks (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id       uuid NOT NULL REFERENCES companies(id),
  user_id          uuid NOT NULL REFERENCES auth.users(id),
  product_id       uuid REFERENCES supplier_products(id),
  supplier_id      uuid REFERENCES supplier_directory(id),
  product_name     text,
  supplier_name    text,
  price_at_click   numeric(12,4),
  affiliate_network text,
  click_url        text,
  converted        boolean DEFAULT false,
  conversion_amount numeric(12,4),
  commission_earned numeric(12,4),
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_affiliate_clicks_company ON affiliate_clicks (company_id, created_at DESC);
CREATE INDEX idx_affiliate_clicks_product ON affiliate_clicks (product_id) WHERE product_id IS NOT NULL;
CREATE INDEX idx_affiliate_clicks_converted ON affiliate_clicks (converted) WHERE converted = true;

ALTER TABLE affiliate_clicks ENABLE ROW LEVEL SECURITY;

-- Companies can see their own clicks
CREATE POLICY "affiliate_clicks_select" ON affiliate_clicks
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "affiliate_clicks_insert" ON affiliate_clicks
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- Service role for reconciliation updates
CREATE POLICY "affiliate_clicks_system" ON affiliate_clicks
  FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- PRODUCT FAVORITES (company-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_favorites (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid NOT NULL REFERENCES companies(id),
  user_id     uuid NOT NULL REFERENCES auth.users(id),
  product_id  uuid NOT NULL REFERENCES supplier_products(id),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX idx_product_favorites_user ON product_favorites (user_id, created_at DESC);
CREATE INDEX idx_product_favorites_company ON product_favorites (company_id);

ALTER TABLE product_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_favorites_select" ON product_favorites
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "product_favorites_insert" ON product_favorites
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "product_favorites_delete" ON product_favorites
  FOR DELETE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- RECENTLY VIEWED PRODUCTS (user-scoped)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_views (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid NOT NULL REFERENCES companies(id),
  user_id     uuid NOT NULL REFERENCES auth.users(id),
  product_id  uuid NOT NULL REFERENCES supplier_products(id),
  viewed_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_product_views_user ON product_views (user_id, viewed_at DESC);

ALTER TABLE product_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "product_views_select" ON product_views
  FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE POLICY "product_views_insert" ON product_views
  FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

-- ============================================================================
-- EXPANDED SUPPLIER DIRECTORY SEED (additional suppliers for DEPTH32)
-- Adding suppliers NOT already in DEPTH31 seed (avoid duplicates)
-- ============================================================================

INSERT INTO supplier_directory (name, name_normalized, aliases, supplier_type, trades_served, website, pricing_tier, is_verified) VALUES
-- Additional Electrical
('Kirby Risk', 'kirby risk', ARRAY['Kirby Risk Corporation'], 'specialty_distributor', ARRAY['electrical','automation'], 'kirbyrisk.com', 'wholesale', true),
('Werner Electric', 'werner electric', ARRAY['Werner Electric Supply'], 'specialty_distributor', ARRAY['electrical'], 'wernerelectric.com', 'wholesale', true),
('Dealers Electrical Supply', 'dealers electrical supply', ARRAY['DES'], 'specialty_distributor', ARRAY['electrical'], 'dealerselectrical.com', 'wholesale', true),
('Kendall Electric', 'kendall electric', ARRAY['Kendall Electric Inc'], 'specialty_distributor', ARRAY['electrical'], 'kendallelectric.com', 'wholesale', true),
('Van Meter', 'van meter', ARRAY['Van Meter Inc'], 'specialty_distributor', ARRAY['electrical'], 'vanmeterinc.com', 'wholesale', true),
('Galco Industrial Electronics', 'galco industrial electronics', ARRAY['Galco'], 'online', ARRAY['electrical','automation'], 'galco.com', 'retail', true),
('Wire & Cable Your Way', 'wire and cable your way', ARRAY['WCYW'], 'online', ARRAY['electrical'], 'wirecableyourway.com', 'retail', true),

-- Additional Plumbing
('Barnett Pipe & Supply', 'barnett pipe and supply', ARRAY['Barnett Pipe'], 'specialty_distributor', ARRAY['plumbing'], 'barnettps.com', 'wholesale', true),
('Plimpton & Hills', 'plimpton and hills', ARRAY['Plimpton Hills','P&H'], 'specialty_distributor', ARRAY['plumbing','hvac','waterworks'], 'plimptonhills.com', 'wholesale', true),
('First Supply', 'first supply', ARRAY['First Supply LLC'], 'specialty_distributor', ARRAY['plumbing','hvac'], 'firstsupply.com', 'wholesale', true),
('QualityPlumbingSupply', 'qualityplumbingsupply', ARRAY['Quality Plumbing Supply'], 'online', ARRAY['plumbing'], 'qualityplumbingsupply.com', 'retail', true),
('FaucetDirect', 'faucetdirect', ARRAY['Faucet Direct'], 'online', ARRAY['plumbing'], 'faucetdirect.com', 'retail', true),

-- Additional HVAC
('Daikin Comfort Technologies', 'daikin comfort technologies', ARRAY['Daikin Applied'], 'specialty_distributor', ARRAY['hvac'], 'daikincomfort.com', 'wholesale', true),
('AC Wholesalers', 'ac wholesalers', ARRAY['AC Wholesalers Direct'], 'online', ARRAY['hvac'], 'acwholesalers.com', 'retail', true),
('Alpine Home Air', 'alpine home air', ARRAY['Alpine HA'], 'online', ARRAY['hvac'], 'alpinehomeair.com', 'retail', true),

-- Additional Roofing
('Midwest Roofing Supply', 'midwest roofing supply', ARRAY['MRS'], 'specialty_distributor', ARRAY['roofing'], 'midwestroofingsupply.com', 'wholesale', true),
('Roofing Supply Group', 'roofing supply group', ARRAY['RSG'], 'specialty_distributor', ARRAY['roofing'], 'roofingsupplygroup.com', 'wholesale', true),
('RoofingSupplyDirect', 'roofingsupplydirect', ARRAY['Roofing Supply Direct'], 'online', ARRAY['roofing'], 'roofingsupplydirect.com', 'retail', true),
('BestBuyMetals', 'bestbuymetals', ARRAY['Best Buy Metals'], 'online', ARRAY['roofing','metal'], 'bestbuymetals.com', 'retail', true),

-- Concrete/Masonry additions
('Sika', 'sika', ARRAY['Sika Corporation','Sika AG'], 'manufacturer_direct', ARRAY['concrete','waterproofing'], 'usa.sika.com', 'wholesale', true),
('LaHabra', 'lahabra', ARRAY['LaHabra Corporation'], 'manufacturer_direct', ARRAY['stucco','masonry'], 'lahabra.com', 'wholesale', true),
('Harris Rebar', 'harris rebar', ARRAY['Harris Rebar Inc'], 'specialty_distributor', ARRAY['concrete','rebar'], 'harrisrebar.com', 'wholesale', true),
('Commercial Metals Company', 'commercial metals company', ARRAY['CMC'], 'manufacturer_direct', ARRAY['steel','rebar'], 'cmc.com', 'wholesale', true),

-- Flooring additions
('Daltile', 'daltile', ARRAY['Dal-Tile','Dal Tile'], 'specialty_distributor', ARRAY['flooring','tile'], 'daltile.com', 'wholesale', true),
('Armstrong Flooring', 'armstrong flooring', ARRAY['Armstrong'], 'manufacturer_direct', ARRAY['flooring'], 'armstrongflooring.com', 'mixed', true),
('Mannington', 'mannington', ARRAY['Mannington Mills'], 'manufacturer_direct', ARRAY['flooring'], 'mannington.com', 'mixed', true),
('Karndean', 'karndean', ARRAY['Karndean Designflooring'], 'manufacturer_direct', ARRAY['flooring'], 'karndean.com', 'mixed', true),
('BuildDirect', 'builddirect', ARRAY['Build Direct'], 'online', ARRAY['flooring'], 'builddirect.com', 'retail', true),

-- Cabinets/Countertops
('CabinetParts', 'cabinetparts', ARRAY['CabinetParts.com'], 'online', ARRAY['cabinets'], 'cabinetparts.com', 'retail', true),
('RTA Store', 'rta store', ARRAY['RTA Cabinet Store'], 'online', ARRAY['cabinets'], '?"?"rtacabinetstore.com', 'retail', true),
('CliqStudios', 'cliqstudios', ARRAY['Cliq Studios'], 'online', ARRAY['cabinets'], 'cliqstudios.com', 'retail', true),
('Cambria', 'cambria', ARRAY['Cambria USA'], 'manufacturer_direct', ARRAY['countertops'], '?"?"cambriausa.com', 'wholesale', true),
('Caesarstone', 'caesarstone', ARRAY['Caesarstone US'], 'manufacturer_direct', ARRAY['countertops'], 'caesarstoneus.com', 'wholesale', true),

-- Tile/Stone
('Bedrosians', 'bedrosians', ARRAY['Bedrosians Tile & Stone'], 'specialty_distributor', ARRAY['tile'], 'bedrosians.com', 'mixed', true),
('Arizona Tile', 'arizona tile', ARRAY['Arizona Tile LLC'], 'specialty_distributor', ARRAY['tile','stone'], 'arizonatile.com', 'mixed', true),
('Emser Tile', 'emser tile', ARRAY['Emser Tile LLC'], 'specialty_distributor', ARRAY['tile'], '?"?"emsertile.com', 'wholesale', true),
('Florida Tile', 'florida tile', ARRAY['Florida Tile Industries'], 'manufacturer_direct', ARRAY['tile'], 'floridatile.com', 'wholesale', true),
('TileBar', 'tilebar', ARRAY['TileBar.com'], 'online', ARRAY['tile'], 'tilebar.com', 'retail', true),

-- Drywall/Insulation
('L&W Supply', 'lw supply', ARRAY['L&W Supply Corporation','USG Distribution'], 'specialty_distributor', ARRAY['drywall','insulation'], 'lwsupply.com', 'wholesale', true),
('Interior Supply', 'interior supply', ARRAY['Interior Supply Inc'], 'specialty_distributor', ARRAY['drywall','ceilings'], 'interiorsupplyinc.com', 'wholesale', true),
('Foundation Building Materials', 'foundation building materials', ARRAY['FBM'], 'specialty_distributor', ARRAY['drywall','stucco'], 'fbmsales.com', 'wholesale', true),
('Owens Corning', 'owens corning', ARRAY['OC','Owens-Corning'], 'manufacturer_direct', ARRAY['insulation','roofing'], 'owenscorning.com', 'mixed', true),
('Johns Manville', 'johns manville', ARRAY['JM','Johns-Manville'], 'manufacturer_direct', ARRAY['insulation','roofing'], 'jm.com', 'mixed', true),
('CertainTeed', 'certainteed', ARRAY['CertainTeed Corporation'], 'manufacturer_direct', ARRAY['insulation','siding','roofing'], 'certainteed.com', 'mixed', true),

-- Fencing
('Master Halco', 'master halco', ARRAY['Master Halco Inc'], 'specialty_distributor', ARRAY['fencing'], 'masterhalco.com', 'wholesale', true),
('Merchants Metals', 'merchants metals', ARRAY['Merchants Metals LLC'], 'specialty_distributor', ARRAY['fencing'], 'merchantsmetals.com', 'wholesale', true),
('Fortress Building Products', 'fortress building products', ARRAY['Fortress Iron','Fortress Railing'], 'manufacturer_direct', ARRAY['fencing','decking'], 'fortressbp.com', 'mixed', true),
('FenceSupplyOnline', 'fencesupplyonline', ARRAY['Fence Supply Online'], 'online', ARRAY['fencing'], 'fencesupplyonline.com', 'retail', true),
('HooverFence', 'hooverfence', ARRAY['Hoover Fence Co'], 'online', ARRAY['fencing'], 'hooverfence.com', 'retail', true),

-- Landscaping additions
('Oldcastle APG', 'oldcastle apg', ARRAY['Oldcastle','APG'], 'manufacturer_direct', ARRAY['landscaping','hardscape'], 'oldcastleapg.com', 'wholesale', true),
('Belgard', 'belgard', ARRAY['Belgard Pavers'], 'manufacturer_direct', ARRAY['landscaping','hardscape'], 'belgard.com', 'mixed', true),
('Tremron', 'tremron', ARRAY['Tremron LLC'], 'manufacturer_direct', ARRAY['landscaping','hardscape'], 'tremron.com', 'mixed', true),
('Unilock', 'unilock', ARRAY['Unilock Ltd'], 'manufacturer_direct', ARRAY['landscaping','hardscape'], 'unilock.com', 'mixed', true),

-- Pest Control
('DoMyOwn', 'domyown', ARRAY['DoMyOwn.com','Do My Own'], 'online', ARRAY['pest_control'], 'domyown.com', 'retail', true),
('Solutions Pest & Lawn', 'solutions pest and lawn', ARRAY['Solutions Stores'], 'online', ARRAY['pest_control','landscaping'], 'solutionsstores.com', 'retail', true),
('Univar Solutions', 'univar solutions', ARRAY['Univar Environmental Sciences'], 'specialty_distributor', ARRAY['pest_control'], 'univarsolutions.com', 'wholesale', true),

-- Pool/Spa
('POOLCORP', 'poolcorp', ARRAY['SCP Distributors','Pool Corporation'], 'specialty_distributor', ARRAY['pool'], 'poolcorp.com', 'wholesale', true),
('Leslies Pool Supplies', 'leslies pool supplies', ARRAY['Leslie''s','Leslies'], 'big_box', ARRAY['pool'], 'lesliespool.com', 'mixed', true),
('Pentair', 'pentair', ARRAY['Pentair Water'], 'manufacturer_direct', ARRAY['pool','water_treatment'], 'pentair.com', 'mixed', true),
('Hayward', 'hayward', ARRAY['Hayward Pool Products'], 'manufacturer_direct', ARRAY['pool'], 'hayward.com', 'mixed', true),

-- Tools/Safety additions
('MSC Industrial', 'msc industrial', ARRAY['MSC Industrial Direct','MSCDirect'], 'online', ARRAY['tools','industrial'], 'mscdirect.com', 'mixed', true),
('Northern Tool', 'northern tool', ARRAY['Northern Tool + Equipment'], 'big_box', ARRAY['tools','equipment'], 'northerntool.com', 'retail', true),
('Acme Tools', 'acme tools', ARRAY['Acme Tools Inc'], 'online', ARRAY['tools'], 'acmetools.com', 'retail', true),

-- Equipment Rental additions
('BlueLine Rental', 'blueline rental', ARRAY['BlueLine','Blue Line Rental'], 'equipment_rental', ARRAY['all'], 'bluelinerental.com', 'mixed', true),
('EquipmentShare', 'equipmentshare', ARRAY['Equipment Share'], 'equipment_rental', ARRAY['all'], 'equipmentshare.com', 'mixed', true),

-- Windows/Doors
('Andersen Windows', 'andersen windows', ARRAY['Andersen Corporation','Andersen'], 'manufacturer_direct', ARRAY['windows'], 'andersenwindows.com', 'mixed', true),
('Pella', 'pella', ARRAY['Pella Corporation','Pella Windows'], 'manufacturer_direct', ARRAY['windows','doors'], 'pella.com', 'mixed', true),
('Marvin', 'marvin', ARRAY['Marvin Windows','Marvin Windows and Doors'], 'manufacturer_direct', ARRAY['windows','doors'], 'marvin.com', 'mixed', true),
('JELD-WEN', 'jeld-wen', ARRAY['JELD WEN','Jeld-Wen Inc'], 'manufacturer_direct', ARRAY['windows','doors'], 'jeld-wen.com', 'mixed', true),
('Milgard', 'milgard', ARRAY['Milgard Windows & Doors'], 'manufacturer_direct', ARRAY['windows','doors'], 'milgard.com', 'mixed', true),
('Therma-Tru', 'therma-tru', ARRAY['Therma Tru Doors'], 'manufacturer_direct', ARRAY['doors'], 'thermatru.com', 'mixed', true),

-- Solar
('CED Greentech', 'ced greentech', ARRAY['CED Greentech Solar'], 'specialty_distributor', ARRAY['solar'], 'cedgreentech.com', 'wholesale', true),
('BayWa r.e.', 'baywa re', ARRAY['BayWa r.e. Solar','BayWa renewable energy'], 'specialty_distributor', ARRAY['solar'], 'baywa-re.us', 'wholesale', true),
('Soligent', 'soligent', ARRAY['Soligent Distribution'], 'specialty_distributor', ARRAY['solar'], 'soligent.net', 'wholesale', true),
('Renogy', 'renogy', ARRAY['Renogy Solar'], 'online', ARRAY['solar'], 'renogy.com', 'retail', true),

-- Fire Protection
('Viking Group', 'viking group', ARRAY['Viking Corporation'], 'manufacturer_direct', ARRAY['fire_protection'], 'vikinggroupinc.com', 'wholesale', true),
('Reliable Automatic Sprinkler', 'reliable automatic sprinkler', ARRAY['Reliable Sprinkler'], 'manufacturer_direct', ARRAY['fire_protection'], 'reliablesprinkler.com', 'wholesale', true),
('Victaulic', 'victaulic', ARRAY['Victaulic Company'], 'manufacturer_direct', ARRAY['fire_protection','plumbing'], 'victaulic.com', 'wholesale', true),

-- Waterproofing
('CETCO', 'cetco', ARRAY['CETCO Building Materials'], 'manufacturer_direct', ARRAY['waterproofing'], 'cetco.com', 'wholesale', true),
('Henry Company', 'henry company', ARRAY['Henry','Henry Building Envelope'], 'manufacturer_direct', ARRAY['waterproofing','roofing'], 'henry.com', 'wholesale', true),
('Tremco', 'tremco', ARRAY['Tremco Inc','Tremco Roofing'], 'manufacturer_direct', ARRAY['waterproofing','roofing'], 'tremcoinc.com', 'wholesale', true),

-- Welding
('Airgas', 'airgas', ARRAY['Airgas Inc','Airgas USA'], 'specialty_distributor', ARRAY['welding','industrial'], 'airgas.com', 'mixed', true),
('Lincoln Electric', 'lincoln electric', ARRAY['Lincoln Electric Holdings'], 'manufacturer_direct', ARRAY['welding'], 'lincolnelectric.com', 'mixed', true),
('WeldingSupply', 'weldingsupply', ARRAY['WeldingSupply.com'], 'online', ARRAY['welding'], 'weldingsupply.com', 'retail', true),

-- Menards (regional big box)
('Menards', 'menards', ARRAY['Menards Inc'], 'big_box', ARRAY['all'], 'menards.com', 'retail', true)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- AUDIT TRIGGERS
-- ============================================================================

SELECT audit_trigger_fn('affiliate_clicks');
SELECT audit_trigger_fn('product_favorites');
