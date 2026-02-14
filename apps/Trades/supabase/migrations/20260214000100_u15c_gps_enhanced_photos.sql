-- U15c: GPS-Enhanced Sketch Data Collection
-- Adds altitude + accuracy to walkthrough photos, walkthrough_path to walkthroughs,
-- and a GPS-proximity clustering function.

-- ── Add missing GPS columns to walkthrough_photos ──
ALTER TABLE walkthrough_photos
  ADD COLUMN IF NOT EXISTS altitude double precision,
  ADD COLUMN IF NOT EXISTS accuracy double precision,
  ADD COLUMN IF NOT EXISTS floor_level text;

-- ── Add walkthrough path tracking to walkthroughs ──
-- Stores an array of GPS breadcrumbs: [{lat, lng, heading, altitude, accuracy, ts, floor_level}]
ALTER TABLE walkthroughs
  ADD COLUMN IF NOT EXISTS walkthrough_path jsonb DEFAULT '[]'::jsonb;

-- ── Create index for GPS-based photo queries ──
CREATE INDEX IF NOT EXISTS idx_wkph_gps
  ON walkthrough_photos(gps_latitude, gps_longitude)
  WHERE gps_latitude IS NOT NULL AND gps_longitude IS NOT NULL;

-- ── Photo clustering function ──
-- Groups photos from a walkthrough by GPS proximity (radius in meters).
-- Returns clusters: [{cluster_id, center_lat, center_lng, photo_ids, avg_heading, floor_level}]
CREATE OR REPLACE FUNCTION cluster_walkthrough_photos(
  p_walkthrough_id uuid,
  p_radius_meters double precision DEFAULT 3.0
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_photos jsonb;
  v_clusters jsonb := '[]'::jsonb;
  v_assigned uuid[] := '{}';
  v_photo record;
  v_compare record;
  v_cluster_photos uuid[];
  v_cluster_id int := 0;
  v_center_lat double precision;
  v_center_lng double precision;
  v_avg_heading double precision;
  v_floor text;
  v_dist double precision;
BEGIN
  -- Simple greedy clustering: iterate photos, assign unassigned neighbors within radius
  FOR v_photo IN
    SELECT id, gps_latitude AS lat, gps_longitude AS lng, compass_heading, floor_level
    FROM walkthrough_photos
    WHERE walkthrough_id = p_walkthrough_id
      AND gps_latitude IS NOT NULL
      AND gps_longitude IS NOT NULL
    ORDER BY created_at
  LOOP
    IF v_photo.id = ANY(v_assigned) THEN
      CONTINUE;
    END IF;

    v_cluster_id := v_cluster_id + 1;
    v_cluster_photos := ARRAY[v_photo.id];
    v_assigned := v_assigned || v_photo.id;
    v_center_lat := v_photo.lat;
    v_center_lng := v_photo.lng;
    v_avg_heading := COALESCE(v_photo.compass_heading, 0);
    v_floor := v_photo.floor_level;

    -- Find neighbors within radius
    FOR v_compare IN
      SELECT id, gps_latitude AS lat, gps_longitude AS lng, compass_heading, floor_level
      FROM walkthrough_photos
      WHERE walkthrough_id = p_walkthrough_id
        AND gps_latitude IS NOT NULL
        AND gps_longitude IS NOT NULL
        AND id != v_photo.id
        AND NOT (id = ANY(v_assigned))
      ORDER BY created_at
    LOOP
      -- Haversine-lite: approximate distance in meters using equirectangular projection
      v_dist := 111320.0 * sqrt(
        power(v_compare.lat - v_photo.lat, 2) +
        power((v_compare.lng - v_photo.lng) * cos(radians((v_photo.lat + v_compare.lat) / 2.0)), 2)
      );

      IF v_dist <= p_radius_meters THEN
        v_cluster_photos := v_cluster_photos || v_compare.id;
        v_assigned := v_assigned || v_compare.id;
      END IF;
    END LOOP;

    -- Build cluster entry
    v_clusters := v_clusters || jsonb_build_object(
      'cluster_id', v_cluster_id,
      'center_lat', v_center_lat,
      'center_lng', v_center_lng,
      'avg_heading', v_avg_heading,
      'floor_level', v_floor,
      'photo_count', array_length(v_cluster_photos, 1),
      'photo_ids', to_jsonb(v_cluster_photos)
    );
  END LOOP;

  RETURN v_clusters;
END;
$$;
