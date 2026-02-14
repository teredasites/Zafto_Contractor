-- L2: PostGIS setup for jurisdiction polygon matching
-- Enable PostGIS extension (already available in Supabase, just needs activation).
-- Add geometry columns to permit_jurisdictions for geographic boundary matching.
-- Start with state-level bounding boxes; extend to city/county polygons over time.

-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Add geometry column for jurisdiction boundaries
ALTER TABLE permit_jurisdictions
  ADD COLUMN IF NOT EXISTS boundary geometry(Polygon, 4326),
  ADD COLUMN IF NOT EXISTS center_point geometry(Point, 4326),
  ADD COLUMN IF NOT EXISTS contributed_by uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS contribution_count int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_verified_at timestamptz;

-- Spatial index for fast geographic lookups
CREATE INDEX IF NOT EXISTS idx_permit_jurisdictions_boundary
  ON permit_jurisdictions USING GIST (boundary);

CREATE INDEX IF NOT EXISTS idx_permit_jurisdictions_center
  ON permit_jurisdictions USING GIST (center_point);

-- Update center points for seeded cities (approximate lat/lng from known coordinates)
-- These are approximate centers for the top 50 cities already seeded in L1
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-73.9857, 40.7484), 4326) WHERE city_name = 'New York' AND state_code = 'NY';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-118.2437, 34.0522), 4326) WHERE city_name = 'Los Angeles' AND state_code = 'CA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-87.6298, 41.8781), 4326) WHERE city_name = 'Chicago' AND state_code = 'IL';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-95.3698, 29.7604), 4326) WHERE city_name = 'Houston' AND state_code = 'TX';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-112.0740, 33.4484), 4326) WHERE city_name = 'Phoenix' AND state_code = 'AZ';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-75.1652, 39.9526), 4326) WHERE city_name = 'Philadelphia' AND state_code = 'PA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-98.4936, 29.4241), 4326) WHERE city_name = 'San Antonio' AND state_code = 'TX';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-117.1611, 32.7157), 4326) WHERE city_name = 'San Diego' AND state_code = 'CA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-96.7970, 32.7767), 4326) WHERE city_name = 'Dallas' AND state_code = 'TX';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326) WHERE city_name = 'San Francisco' AND state_code = 'CA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-97.7431, 30.2672), 4326) WHERE city_name = 'Austin' AND state_code = 'TX';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-82.9988, 39.9612), 4326) WHERE city_name = 'Columbus' AND state_code = 'OH';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-86.1581, 39.7684), 4326) WHERE city_name = 'Indianapolis' AND state_code = 'IN';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-80.1918, 25.7617), 4326) WHERE city_name = 'Miami' AND state_code = 'FL';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-122.3321, 47.6062), 4326) WHERE city_name = 'Seattle' AND state_code = 'WA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-104.9903, 39.7392), 4326) WHERE city_name = 'Denver' AND state_code = 'CO';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-77.0369, 38.9072), 4326) WHERE city_name = 'Washington' AND state_code = 'DC';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-86.7816, 36.1627), 4326) WHERE city_name = 'Nashville' AND state_code = 'TN';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-81.6944, 41.4993), 4326) WHERE city_name = 'Cleveland' AND state_code = 'OH';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-84.3880, 33.7490), 4326) WHERE city_name = 'Atlanta' AND state_code = 'GA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-122.6765, 45.5152), 4326) WHERE city_name = 'Portland' AND state_code = 'OR';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-115.1398, 36.1699), 4326) WHERE city_name = 'Las Vegas' AND state_code = 'NV';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-90.0490, 35.1495), 4326) WHERE city_name = 'Memphis' AND state_code = 'TN';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-85.7585, 38.2527), 4326) WHERE city_name = 'Louisville' AND state_code = 'KY';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-76.6122, 39.2904), 4326) WHERE city_name = 'Baltimore' AND state_code = 'MD';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-87.9065, 43.0389), 4326) WHERE city_name = 'Milwaukee' AND state_code = 'WI';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-106.6504, 35.0844), 4326) WHERE city_name = 'Albuquerque' AND state_code = 'NM';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-80.8431, 35.2271), 4326) WHERE city_name = 'Charlotte' AND state_code = 'NC';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-78.6382, 35.7796), 4326) WHERE city_name = 'Raleigh' AND state_code = 'NC';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-93.2650, 44.9778), 4326) WHERE city_name = 'Minneapolis' AND state_code = 'MN';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-94.5786, 39.0997), 4326) WHERE city_name = 'Kansas City' AND state_code = 'MO';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-90.1994, 38.6270), 4326) WHERE city_name = 'St. Louis' AND state_code = 'MO';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-82.4572, 27.9506), 4326) WHERE city_name = 'Tampa' AND state_code = 'FL';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-81.3789, 28.5383), 4326) WHERE city_name = 'Orlando' AND state_code = 'FL';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-79.9311, 32.7765), 4326) WHERE city_name = 'Charleston' AND state_code = 'SC';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-71.0589, 42.3601), 4326) WHERE city_name = 'Boston' AND state_code = 'MA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-83.0458, 42.3314), 4326) WHERE city_name = 'Detroit' AND state_code = 'MI';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-79.9959, 40.4406), 4326) WHERE city_name = 'Pittsburgh' AND state_code = 'PA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-111.8910, 40.7608), 4326) WHERE city_name = 'Salt Lake City' AND state_code = 'UT';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-121.4944, 38.5816), 4326) WHERE city_name = 'Sacramento' AND state_code = 'CA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-81.6557, 30.3322), 4326) WHERE city_name = 'Jacksonville' AND state_code = 'FL';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-84.5120, 39.1031), 4326) WHERE city_name = 'Cincinnati' AND state_code = 'OH';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-95.9928, 36.1540), 4326) WHERE city_name = 'Tulsa' AND state_code = 'OK';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-97.5164, 35.4676), 4326) WHERE city_name = 'Oklahoma City' AND state_code = 'OK';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-90.0715, 29.9511), 4326) WHERE city_name = 'New Orleans' AND state_code = 'LA';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-96.7369, 43.5446), 4326) WHERE city_name = 'Sioux Falls' AND state_code = 'SD';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-155.0868, 19.7297), 4326) WHERE city_name = 'Honolulu' AND state_code = 'HI';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-149.9003, 61.2181), 4326) WHERE city_name = 'Anchorage' AND state_code = 'AK';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-116.2023, 43.6150), 4326) WHERE city_name = 'Boise' AND state_code = 'ID';
UPDATE permit_jurisdictions SET center_point = ST_SetSRID(ST_MakePoint(-96.0419, 41.2565), 4326) WHERE city_name = 'Omaha' AND state_code = 'NE';

-- Function for proximity-based jurisdiction lookup using PostGIS
CREATE OR REPLACE FUNCTION find_nearest_jurisdiction(
  p_lat double precision,
  p_lng double precision,
  p_radius_miles double precision DEFAULT 25
)
RETURNS TABLE (
  id uuid,
  jurisdiction_name text,
  jurisdiction_type text,
  state_code text,
  city_name text,
  distance_miles double precision
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pj.id,
    pj.jurisdiction_name,
    pj.jurisdiction_type,
    pj.state_code,
    pj.city_name,
    (ST_Distance(
      pj.center_point::geography,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) / 1609.344)::double precision AS distance_miles
  FROM permit_jurisdictions pj
  WHERE pj.center_point IS NOT NULL
    AND ST_DWithin(
      pj.center_point::geography,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_miles * 1609.344  -- convert miles to meters
    )
  ORDER BY distance_miles ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION find_nearest_jurisdiction TO authenticated;

-- RLS update: allow authenticated users to insert/update jurisdictions (community contribution)
CREATE POLICY permit_jurisdictions_contribute ON permit_jurisdictions
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY permit_jurisdictions_update_contributed ON permit_jurisdictions
  FOR UPDATE TO authenticated
  USING (contributed_by = auth.uid() OR verified = false);

-- Track contributions
CREATE OR REPLACE FUNCTION fn_increment_jurisdiction_contribution()
RETURNS trigger AS $$
BEGIN
  NEW.contribution_count := COALESCE(OLD.contribution_count, 0) + 1;
  NEW.contributed_by := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_jurisdiction_contribution
  BEFORE UPDATE ON permit_jurisdictions
  FOR EACH ROW
  WHEN (OLD.building_dept_phone IS DISTINCT FROM NEW.building_dept_phone
     OR OLD.building_dept_url IS DISTINCT FROM NEW.building_dept_url
     OR OLD.online_submission_url IS DISTINCT FROM NEW.online_submission_url
     OR OLD.avg_turnaround_days IS DISTINCT FROM NEW.avg_turnaround_days)
  EXECUTE FUNCTION fn_increment_jurisdiction_contribution();
