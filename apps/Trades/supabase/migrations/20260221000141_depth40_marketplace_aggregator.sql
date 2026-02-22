-- ============================================================
-- DEPTH40 — Universal Marketplace Aggregator (Non-AI Layer)
-- One place to browse tools, trucks, equipment across marketplaces.
-- CPSC recall checking, save/watch, trade-relevant search.
-- AI deep research layer = Phase E (built later).
-- ============================================================

-- ── marketplace_sources — supported marketplace platforms ──
CREATE TABLE marketplace_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  slug text NOT NULL UNIQUE,
  source_type text NOT NULL CHECK (source_type IN (
    'rss', 'api', 'paste_link', 'affiliate', 'scrape'
  )),
  base_url text,
  api_config jsonb DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  icon_name text, -- lucide icon name
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Seed marketplace sources
INSERT INTO marketplace_sources (name, slug, source_type, base_url, icon_name) VALUES
  ('Craigslist', 'craigslist', 'rss', 'https://craigslist.org', 'Newspaper'),
  ('Facebook Marketplace', 'facebook', 'paste_link', 'https://facebook.com/marketplace', 'Facebook'),
  ('OfferUp', 'offerup', 'paste_link', 'https://offerup.com', 'ShoppingBag'),
  ('Home Depot', 'homedepot', 'affiliate', 'https://homedepot.com', 'Store'),
  ('Lowes', 'lowes', 'affiliate', 'https://lowes.com', 'Store'),
  ('Amazon', 'amazon', 'affiliate', 'https://amazon.com', 'Package'),
  ('eBay', 'ebay', 'api', 'https://ebay.com', 'Gavel'),
  ('Acme Tools', 'acmetools', 'affiliate', 'https://acmetools.com', 'Wrench'),
  ('Tool Nut', 'toolnut', 'affiliate', 'https://toolnut.com', 'Hammer'),
  ('CPO Outlets', 'cpooutlets', 'affiliate', 'https://cpooutlets.com', 'Tag'),
  ('Northern Tool', 'northerntool', 'affiliate', 'https://northerntool.com', 'Tractor'),
  ('Grainger', 'grainger', 'affiliate', 'https://grainger.com', 'Building2'),
  ('Surplus Record', 'surplusrecord', 'paste_link', 'https://surplusrecord.com', 'Archive'),
  ('GovPlanet', 'govplanet', 'paste_link', 'https://govplanet.com', 'Landmark'),
  ('Machinery Trader', 'machinerytrader', 'paste_link', 'https://machinerytrader.com', 'Truck')
ON CONFLICT (slug) DO NOTHING;

-- ── marketplace_listings — normalized listings from all sources ──
CREATE TABLE marketplace_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  source_id uuid NOT NULL REFERENCES marketplace_sources(id),

  -- Listing info
  external_id text, -- ID from source marketplace
  external_url text NOT NULL,
  title text NOT NULL,
  description text,
  price_cents int, -- null = "contact for pricing"
  currency text NOT NULL DEFAULT 'USD',
  condition text CHECK (condition IN ('new', 'like_new', 'good', 'fair', 'poor', 'for_parts', 'unknown')),

  -- Seller
  seller_name text,
  seller_location text,
  seller_rating numeric(3,2),

  -- Location
  latitude numeric(10,7),
  longitude numeric(10,7),
  city text,
  state text,
  zip_code text,
  distance_miles numeric(8,2), -- from user's location

  -- Photos
  photos jsonb DEFAULT '[]'::jsonb, -- [{url, thumbnail_url}]
  photo_count int NOT NULL DEFAULT 0,

  -- Categorization
  trade_category text, -- 'hvac', 'electrical', 'plumbing', 'general', etc.
  item_category text, -- 'power_tools', 'hand_tools', 'vehicles', 'equipment', 'materials', 'safety'
  brand text,
  model text,
  year int,

  -- CPSC recall check
  recall_checked boolean NOT NULL DEFAULT false,
  recall_found boolean NOT NULL DEFAULT false,
  recall_id text,
  recall_description text,

  -- Status
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'sold', 'expired', 'flagged', 'archived')),
  imported_at timestamptz NOT NULL DEFAULT now(),

  -- Metadata
  raw_data jsonb, -- original listing data
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_mktplace_listings_company ON marketplace_listings (company_id);
CREATE INDEX idx_mktplace_listings_source ON marketplace_listings (source_id);
CREATE INDEX idx_mktplace_listings_trade ON marketplace_listings (company_id, trade_category);
CREATE INDEX idx_mktplace_listings_status ON marketplace_listings (status) WHERE status = 'active';
CREATE INDEX idx_mktplace_listings_price ON marketplace_listings (price_cents) WHERE status = 'active';
CREATE INDEX idx_mktplace_listings_deleted ON marketplace_listings (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_mktplace_listings_location ON marketplace_listings (state, city) WHERE status = 'active';

CREATE TRIGGER marketplace_listings_updated
  BEFORE UPDATE ON marketplace_listings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER marketplace_listings_audit
  AFTER INSERT OR UPDATE OR DELETE ON marketplace_listings
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "mktplace_listings_select" ON marketplace_listings
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "mktplace_listings_insert" ON marketplace_listings
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "mktplace_listings_update" ON marketplace_listings
  FOR UPDATE USING (company_id = requesting_company_id());

-- ── marketplace_saved_listings — watch/favorite list ──
CREATE TABLE marketplace_saved_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),
  listing_id uuid NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,

  saved_type text NOT NULL DEFAULT 'favorite' CHECK (saved_type IN ('favorite', 'watch', 'compare')),
  notes text,

  -- Price tracking for watches
  price_at_save int, -- price when saved
  price_alert_threshold int, -- notify if price drops below this

  created_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (user_id, listing_id)
);

ALTER TABLE marketplace_saved_listings ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_mktplace_saved_company ON marketplace_saved_listings (company_id, user_id);
CREATE INDEX idx_mktplace_saved_listing ON marketplace_saved_listings (listing_id);

CREATE TRIGGER marketplace_saved_audit
  AFTER INSERT OR UPDATE OR DELETE ON marketplace_saved_listings
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "mktplace_saved_select" ON marketplace_saved_listings
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "mktplace_saved_insert" ON marketplace_saved_listings
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "mktplace_saved_delete" ON marketplace_saved_listings
  FOR DELETE USING (company_id = requesting_company_id() AND user_id = auth.uid());

-- ── marketplace_searches — saved search criteria for alerts ──
CREATE TABLE marketplace_searches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),

  name text NOT NULL,
  query text,
  trade_category text,
  item_category text,
  min_price_cents int,
  max_price_cents int,
  condition_filter jsonb, -- ['new', 'like_new', 'good']
  max_distance_miles int,
  source_filter jsonb, -- ['craigslist', 'facebook'] or null for all
  brand_filter jsonb, -- ['DeWalt', 'Milwaukee'] or null for all

  -- Notifications
  alert_enabled boolean NOT NULL DEFAULT true,
  alert_frequency text NOT NULL DEFAULT 'daily' CHECK (alert_frequency IN ('instant', 'daily', 'weekly')),
  last_alert_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE marketplace_searches ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_mktplace_searches_company ON marketplace_searches (company_id, user_id);
CREATE INDEX idx_mktplace_searches_deleted ON marketplace_searches (deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER marketplace_searches_updated
  BEFORE UPDATE ON marketplace_searches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER marketplace_searches_audit
  AFTER INSERT OR UPDATE OR DELETE ON marketplace_searches
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "mktplace_searches_select" ON marketplace_searches
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "mktplace_searches_insert" ON marketplace_searches
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "mktplace_searches_update" ON marketplace_searches
  FOR UPDATE USING (company_id = requesting_company_id() AND user_id = auth.uid());

-- ── cpsc_recall_cache — cached CPSC recall data ──
CREATE TABLE cpsc_recall_cache (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recall_number text NOT NULL UNIQUE,
  product_name text NOT NULL,
  description text,
  hazard text,
  remedy text,
  manufacturer text,
  product_type text,
  categories jsonb DEFAULT '[]'::jsonb,
  images jsonb DEFAULT '[]'::jsonb,
  recall_date date,
  last_fetched_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cpsc_recall_product ON cpsc_recall_cache USING gin (to_tsvector('english', product_name || ' ' || COALESCE(manufacturer, '')));
CREATE INDEX idx_cpsc_recall_number ON cpsc_recall_cache (recall_number);
CREATE INDEX idx_cpsc_recall_type ON cpsc_recall_cache (product_type);

-- Trade-to-category mapping for smart filtering
CREATE TABLE marketplace_trade_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trade text NOT NULL,
  item_categories jsonb NOT NULL DEFAULT '[]'::jsonb, -- relevant categories for this trade
  keywords jsonb NOT NULL DEFAULT '[]'::jsonb, -- search keywords to auto-match
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO marketplace_trade_categories (trade, item_categories, keywords) VALUES
  ('hvac', '["equipment","power_tools","hand_tools","materials","vehicles"]', '["furnace","ac unit","compressor","refrigerant","ductwork","mini split","heat pump","thermostat","recovery machine","manifold gauge","vacuum pump","brazing","copper tubing"]'),
  ('electrical', '["power_tools","hand_tools","materials","safety","test_equipment"]', '["wire","conduit","panel","breaker","meter","multimeter","fish tape","bender","transformer","generator","cable","receptacle","switch"]'),
  ('plumbing', '["power_tools","hand_tools","materials","vehicles"]', '["pipe","fitting","valve","water heater","drain","sewer","camera","jetter","press tool","copper","pex","threading","soldering"]'),
  ('roofing', '["power_tools","materials","safety","equipment"]', '["shingles","underlayment","flashing","nailer","nail gun","ladder","harness","tear-off","dumpster","felt","ice shield","drip edge","ridge vent"]'),
  ('painting', '["power_tools","hand_tools","materials","equipment"]', '["sprayer","roller","brush","paint","primer","caulk","tape","sander","scaffold","ladder","pressure washer","drop cloth","stain"]'),
  ('concrete', '["power_tools","equipment","materials","vehicles"]', '["mixer","trowel","float","saw","grinder","rebar","form","stamp","stain","sealer","vibrator","bull float","edger","finishing"]'),
  ('landscaping', '["power_tools","equipment","vehicles","materials"]', '["mower","trimmer","blower","chainsaw","skid steer","trailer","mulch","stone","pavers","irrigation","sod","fertilizer","edger"]'),
  ('general', '["power_tools","hand_tools","equipment","vehicles","materials","safety"]', '["tool","drill","saw","impact","level","tape measure","truck","van","trailer","compressor","generator","ladder","scaffold"]'),
  ('fire_restoration', '["equipment","materials","safety"]', '["air scrubber","dehumidifier","blower","containment","hepa","ozone","thermal imaging","moisture meter","desiccant","ppe","respirator"]'),
  ('water_restoration', '["equipment","materials"]', '["dehumidifier","air mover","moisture meter","thermal camera","injectidry","desiccant","extraction","pump","hose","containment"]'),
  ('mold_remediation', '["equipment","materials","safety"]', '["air scrubber","hepa","containment","ppe","respirator","negative air","moisture meter","dehumidifier","antimicrobial","encapsulant"]'),
  ('solar', '["equipment","materials","power_tools"]', '["panel","inverter","racking","conduit","wire","optimizer","battery","disconnect","meter","mc4","string"]'),
  ('fencing', '["power_tools","materials","equipment"]', '["post","rail","picket","chain link","auger","stretcher","gate","concrete","bracket","cap","tension"]')
ON CONFLICT DO NOTHING;
