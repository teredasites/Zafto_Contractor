-- ============================================================
-- DEPTH42 — Storage Tiering & Usage Metering
-- 5GB free, paid 50GB blocks ($5/mo), usage breakdown by
-- category, upload gating, R2 overflow, ops analytics.
-- ============================================================

-- ── storage_usage — per-company storage tracking ──
CREATE TABLE storage_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Usage breakdown (bytes)
  total_bytes bigint NOT NULL DEFAULT 0,
  photo_bytes bigint NOT NULL DEFAULT 0,
  document_bytes bigint NOT NULL DEFAULT 0,
  video_bytes bigint NOT NULL DEFAULT 0,
  blueprint_bytes bigint NOT NULL DEFAULT 0,
  voice_note_bytes bigint NOT NULL DEFAULT 0,
  signature_bytes bigint NOT NULL DEFAULT 0,
  receipt_bytes bigint NOT NULL DEFAULT 0,
  other_bytes bigint NOT NULL DEFAULT 0,

  -- File counts
  total_files int NOT NULL DEFAULT 0,
  photo_count int NOT NULL DEFAULT 0,
  document_count int NOT NULL DEFAULT 0,
  video_count int NOT NULL DEFAULT 0,
  blueprint_count int NOT NULL DEFAULT 0,

  -- Tier info
  tier text NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'paid', 'enterprise')),
  base_limit_bytes bigint NOT NULL DEFAULT 5368709120, -- 5 GB
  addon_limit_bytes bigint NOT NULL DEFAULT 0, -- purchased add-on storage
  total_limit_bytes bigint GENERATED ALWAYS AS (base_limit_bytes + addon_limit_bytes) STORED,

  -- Add-on purchases
  addon_blocks int NOT NULL DEFAULT 0, -- number of 50GB blocks purchased
  addon_monthly_cost_cents int NOT NULL DEFAULT 0, -- total monthly cost for add-ons

  -- Overflow storage (Cloudflare R2)
  r2_overflow_bytes bigint NOT NULL DEFAULT 0,
  r2_overflow_enabled boolean NOT NULL DEFAULT false,

  -- Usage percentage thresholds
  warning_sent_at timestamptz, -- 80% warning sent
  limit_reached_at timestamptz, -- 100% limit reached
  last_calculated_at timestamptz NOT NULL DEFAULT now(),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  UNIQUE (company_id)
);

ALTER TABLE storage_usage ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_storage_usage_company ON storage_usage (company_id);
CREATE INDEX idx_storage_usage_tier ON storage_usage (tier);

CREATE TRIGGER storage_usage_updated
  BEFORE UPDATE ON storage_usage
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE POLICY "storage_usage_select" ON storage_usage
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "storage_usage_update" ON storage_usage
  FOR UPDATE USING (company_id = requesting_company_id());

-- ── storage_upload_log — individual upload tracking ──
CREATE TABLE storage_upload_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id),

  -- File info
  bucket_name text NOT NULL, -- 'photos', 'documents', 'voice-notes', etc.
  storage_path text NOT NULL, -- path in Supabase storage
  file_name text NOT NULL,
  file_type text, -- MIME type
  file_size_bytes bigint NOT NULL,
  file_category text NOT NULL CHECK (file_category IN (
    'photo', 'document', 'video', 'blueprint', 'voice_note',
    'signature', 'receipt', 'other'
  )),

  -- Storage location
  storage_location text NOT NULL DEFAULT 'supabase' CHECK (storage_location IN (
    'supabase', 'cloudflare_r2'
  )),

  -- Status
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deleted', 'archived')),
  deleted_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE storage_upload_log ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_storage_uploads_company ON storage_upload_log (company_id);
CREATE INDEX idx_storage_uploads_user ON storage_upload_log (company_id, user_id);
CREATE INDEX idx_storage_uploads_category ON storage_upload_log (company_id, file_category);
CREATE INDEX idx_storage_uploads_deleted ON storage_upload_log (deleted_at) WHERE deleted_at IS NULL;

CREATE TRIGGER storage_upload_audit
  AFTER INSERT OR UPDATE OR DELETE ON storage_upload_log
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "storage_upload_select" ON storage_upload_log
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "storage_upload_insert" ON storage_upload_log
  FOR INSERT WITH CHECK (company_id = requesting_company_id());
CREATE POLICY "storage_upload_update" ON storage_upload_log
  FOR UPDATE USING (company_id = requesting_company_id());

-- ── storage_addon_purchases — RevenueCat purchase records ──
CREATE TABLE storage_addon_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id), -- who purchased

  -- Purchase details
  blocks_purchased int NOT NULL DEFAULT 1, -- number of 50GB blocks
  bytes_added bigint NOT NULL, -- total bytes added
  cost_cents_monthly int NOT NULL, -- monthly cost in cents

  -- RevenueCat details
  revenuecat_transaction_id text,
  revenuecat_product_id text,
  revenuecat_entitlement text,

  -- Status
  status text NOT NULL DEFAULT 'active' CHECK (status IN (
    'active', 'cancelled', 'expired', 'refunded'
  )),
  purchased_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  expires_at timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE storage_addon_purchases ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_storage_addons_company ON storage_addon_purchases (company_id);
CREATE INDEX idx_storage_addons_status ON storage_addon_purchases (status) WHERE status = 'active';

CREATE TRIGGER storage_addon_updated
  BEFORE UPDATE ON storage_addon_purchases
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER storage_addon_audit
  AFTER INSERT OR UPDATE OR DELETE ON storage_addon_purchases
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

CREATE POLICY "storage_addon_select" ON storage_addon_purchases
  FOR SELECT USING (company_id = requesting_company_id());
CREATE POLICY "storage_addon_insert" ON storage_addon_purchases
  FOR INSERT WITH CHECK (company_id = requesting_company_id());

-- ── storage_platform_metrics — ops-level aggregate metrics ──
CREATE TABLE storage_platform_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_date date NOT NULL UNIQUE,

  -- Platform totals
  total_companies int NOT NULL DEFAULT 0,
  total_storage_bytes bigint NOT NULL DEFAULT 0,
  total_files int NOT NULL DEFAULT 0,

  -- Tier breakdown
  free_tier_companies int NOT NULL DEFAULT 0,
  paid_tier_companies int NOT NULL DEFAULT 0,
  free_tier_bytes bigint NOT NULL DEFAULT 0,
  paid_tier_bytes bigint NOT NULL DEFAULT 0,

  -- Revenue
  storage_addon_revenue_cents int NOT NULL DEFAULT 0, -- monthly revenue from add-ons
  total_addon_blocks int NOT NULL DEFAULT 0,

  -- Growth
  uploads_today int NOT NULL DEFAULT 0,
  bytes_uploaded_today bigint NOT NULL DEFAULT 0,
  deletions_today int NOT NULL DEFAULT 0,

  -- Overflow
  r2_overflow_bytes bigint NOT NULL DEFAULT 0,
  r2_overflow_companies int NOT NULL DEFAULT 0,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_storage_platform_date ON storage_platform_metrics (metric_date DESC);
