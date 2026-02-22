-- RECON Enhanced Data: Storage folder, Street View, external links, free data sources
-- Adds columns to property_scans for comprehensive property intelligence

-- Add new columns to property_scans
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS storage_folder TEXT;  -- e.g. 'recon/{company_id}/{normalized_address}'
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS street_view_url TEXT;  -- Google Street View Static API URL
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS external_links JSONB DEFAULT '{}'::jsonb;  -- zillow, redfin, realtor, google_maps, county_assessor URLs
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS property_type TEXT;  -- 'single_family', 'multi_family', 'condo', 'townhouse', 'commercial'
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS flood_zone TEXT;  -- FEMA flood zone designation
ALTER TABLE property_scans ADD COLUMN IF NOT EXISTS flood_risk TEXT;  -- 'high', 'moderate', 'low', 'minimal'

-- Add new columns to property_features for free data sources
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS basement_type TEXT;  -- 'full', 'partial', 'crawl_space', 'slab', 'none'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS foundation_type TEXT;  -- 'poured_concrete', 'block', 'slab', 'pier', 'stone'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS exterior_material TEXT;  -- 'vinyl_siding', 'brick', 'stucco', 'wood', 'stone', 'fiber_cement'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS roof_material TEXT;  -- 'asphalt_shingle', 'metal', 'tile', 'slate', 'rubber', 'wood_shake'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS lot_description TEXT;  -- 'flat', 'sloped', 'corner', 'cul_de_sac', 'waterfront'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS neighborhood_type TEXT;  -- 'suburban', 'urban', 'rural', 'exurban'
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS estimated_value NUMERIC(14,2);  -- Our own estimate based on available data
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS county_data JSONB DEFAULT '{}'::jsonb;  -- Raw county assessor data
ALTER TABLE property_features ADD COLUMN IF NOT EXISTS census_data JSONB DEFAULT '{}'::jsonb;  -- Census demographics for the area

-- Storage bucket for recon photos (satellite, street view, saved images)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'recon-photos',
  'recon-photos',
  false,
  10485760,  -- 10MB max
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'application/json']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for recon-photos bucket
DO $$ BEGIN
  CREATE POLICY "recon_photos_select" ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'recon-photos');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "recon_photos_insert" ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'recon-photos');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Index for storage folder lookups
CREATE INDEX IF NOT EXISTS idx_ps_storage_folder ON property_scans(storage_folder)
  WHERE storage_folder IS NOT NULL;
