-- ============================================================
-- INTEG4: Weather Engine Activation
-- Migration 000150
--
-- Activates NOAA/NWS weather data ($0/mo) across scheduling,
-- dispatch, field tools. Single weather pipeline feeds all.
--
-- New tables:
--   weather_forecasts       (cached NOAA forecast by location/date)
--   schedule_weather_flags  (adverse weather alerts on tasks)
--   field_weather_snapshots (auto-captured weather for field entries)
--
-- Uses storm_events + storm_event_impacts from INTEG6 (migration 147)
-- ============================================================

-- ============================================================
-- 1. WEATHER FORECASTS CACHE
--    Caches NOAA Weather API (api.weather.gov) responses
--    Free, no API key needed. Forecast by lat/lng grid point.
-- ============================================================

CREATE TABLE IF NOT EXISTS weather_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Location (grid-based for NOAA, ZIP for quick lookup)
  zip TEXT,
  latitude NUMERIC(10,7) NOT NULL,
  longitude NUMERIC(10,7) NOT NULL,
  grid_office TEXT,      -- e.g. 'MLB' (NOAA grid office)
  grid_x INTEGER,
  grid_y INTEGER,

  -- Forecast data
  forecast_date DATE NOT NULL,
  period_name TEXT,          -- 'Today', 'Tonight', 'Wednesday', etc.
  temperature_high_f INTEGER,
  temperature_low_f INTEGER,
  temperature_unit TEXT DEFAULT 'F',
  wind_speed_mph INTEGER,
  wind_direction TEXT,       -- 'NW', 'SE', etc.
  precipitation_pct INTEGER DEFAULT 0 CHECK (precipitation_pct BETWEEN 0 AND 100),
  weather_condition TEXT,    -- 'Sunny', 'Partly Cloudy', 'Rain', 'Snow', etc.
  short_forecast TEXT,       -- 'Mostly sunny with a high near 78'
  detailed_forecast TEXT,
  humidity_pct INTEGER CHECK (humidity_pct IS NULL OR (humidity_pct BETWEEN 0 AND 100)),
  uv_index INTEGER,
  icon_url TEXT,

  -- Severity flags
  is_adverse BOOLEAN NOT NULL DEFAULT false,
  adverse_reasons JSONB DEFAULT '[]'::jsonb,
  -- ['high_wind', 'heavy_rain', 'extreme_cold', 'extreme_heat', 'snow', 'ice', 'thunderstorm']

  -- NWS alerts active for this location/date
  active_alerts JSONB DEFAULT '[]'::jsonb,
  -- [{alert_id, event, severity, headline, expires}]

  -- Cache management
  raw_response JSONB,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '6 hours'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for quick lookup by location + date
CREATE INDEX idx_wf_zip_date ON weather_forecasts(zip, forecast_date) WHERE zip IS NOT NULL;
CREATE INDEX idx_wf_coords_date ON weather_forecasts(latitude, longitude, forecast_date);
CREATE INDEX idx_wf_grid ON weather_forecasts(grid_office, grid_x, grid_y, forecast_date)
  WHERE grid_office IS NOT NULL;
CREATE INDEX idx_wf_adverse ON weather_forecasts(forecast_date, is_adverse) WHERE is_adverse = true;
CREATE INDEX idx_wf_expires ON weather_forecasts(expires_at);

-- Weather forecasts are public reference data — no company_id
ALTER TABLE weather_forecasts ENABLE ROW LEVEL SECURITY;
CREATE POLICY wf_select ON weather_forecasts FOR SELECT TO authenticated USING (true);
-- Only service role / EFs can insert/update
CREATE POLICY wf_service ON weather_forecasts FOR ALL TO service_role USING (true) WITH CHECK (true);

SELECT update_updated_at('weather_forecasts');


-- ============================================================
-- 2. SCHEDULE WEATHER FLAGS
--    Flags tasks on the Gantt chart when weather is adverse
--    Auto-flagged by weather-forecast-fetch EF
-- ============================================================

CREATE TABLE IF NOT EXISTS schedule_weather_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- Schedule context
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  task_id UUID,  -- references schedule tasks (may be JSONB task_id in gantt)
  task_name TEXT NOT NULL,
  scheduled_date DATE NOT NULL,

  -- Location
  job_site_zip TEXT,
  job_site_latitude NUMERIC(10,7),
  job_site_longitude NUMERIC(10,7),

  -- Weather data
  weather_forecast_id UUID REFERENCES weather_forecasts(id) ON DELETE SET NULL,
  weather_condition TEXT NOT NULL,
  temperature_f INTEGER,
  wind_speed_mph INTEGER,
  precipitation_pct INTEGER,

  -- Flag details
  flag_type TEXT NOT NULL DEFAULT 'warning'
    CHECK (flag_type IN ('info', 'warning', 'severe', 'extreme')),
  flag_reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- ['rain_above_50pct', 'wind_above_25mph', 'temp_below_20f', 'nws_alert_active']

  is_outdoor_task BOOLEAN NOT NULL DEFAULT true,

  -- Action taken
  action_taken TEXT DEFAULT 'none'
    CHECK (action_taken IN ('none', 'acknowledged', 'rescheduled', 'proceeded', 'cancelled')),
  action_taken_by UUID REFERENCES auth.users(id),
  action_taken_at TIMESTAMPTZ,
  rescheduled_to DATE,
  action_notes TEXT,

  -- Auto-generated
  auto_flagged BOOLEAN NOT NULL DEFAULT true,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_swf_company ON schedule_weather_flags(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_swf_job ON schedule_weather_flags(job_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_swf_date ON schedule_weather_flags(scheduled_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_swf_flag_type ON schedule_weather_flags(flag_type) WHERE deleted_at IS NULL AND action_taken = 'none';

ALTER TABLE schedule_weather_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY swf_select ON schedule_weather_flags FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);
CREATE POLICY swf_insert ON schedule_weather_flags FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY swf_update ON schedule_weather_flags FOR UPDATE TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid AND deleted_at IS NULL);

SELECT update_updated_at('schedule_weather_flags');
CREATE TRIGGER swf_audit AFTER INSERT OR UPDATE OR DELETE ON schedule_weather_flags
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 3. FIELD WEATHER SNAPSHOTS
--    Auto-captured weather context for field tool entries
--    (daily logs, photos, voice notes, time entries)
-- ============================================================

CREATE TABLE IF NOT EXISTS field_weather_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,

  -- What this snapshot is attached to
  entity_type TEXT NOT NULL
    CHECK (entity_type IN ('daily_log', 'photo', 'voice_note', 'time_entry', 'inspection', 'quality_check')),
  entity_id UUID NOT NULL,

  -- Weather at capture time
  captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  zip TEXT,

  -- Conditions
  temperature_f INTEGER,
  feels_like_f INTEGER,
  humidity_pct INTEGER,
  wind_speed_mph INTEGER,
  wind_direction TEXT,
  weather_condition TEXT,  -- 'Clear', 'Partly Cloudy', 'Rain', etc.
  precipitation_pct INTEGER,
  visibility_miles NUMERIC(5,1),
  pressure_mb NUMERIC(6,1),
  dew_point_f INTEGER,

  -- Source
  source TEXT NOT NULL DEFAULT 'noaa'
    CHECK (source IN ('noaa', 'manual', 'device_sensor')),
  is_manual_override BOOLEAN NOT NULL DEFAULT false,

  -- Cache reference
  weather_forecast_id UUID REFERENCES weather_forecasts(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_fws_company ON field_weather_snapshots(company_id);
CREATE INDEX idx_fws_entity ON field_weather_snapshots(entity_type, entity_id);
CREATE INDEX idx_fws_captured ON field_weather_snapshots(captured_at);

ALTER TABLE field_weather_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY fws_select ON field_weather_snapshots FOR SELECT TO authenticated
  USING (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);
CREATE POLICY fws_insert ON field_weather_snapshots FOR INSERT TO authenticated
  WITH CHECK (company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid);

CREATE TRIGGER fws_audit AFTER INSERT OR UPDATE OR DELETE ON field_weather_snapshots
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();


-- ============================================================
-- 4. fn_check_weather_adverse
--    Given a forecast, returns whether it's adverse for outdoor work
--    Thresholds: >50% precip, >25mph wind, <20°F, >105°F, active alerts
-- ============================================================

CREATE OR REPLACE FUNCTION fn_check_weather_adverse(
  p_precip_pct INTEGER DEFAULT 0,
  p_wind_mph INTEGER DEFAULT 0,
  p_temp_high_f INTEGER DEFAULT 70,
  p_temp_low_f INTEGER DEFAULT 50,
  p_has_alerts BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_reasons JSONB := '[]'::jsonb;
  v_is_adverse BOOLEAN := false;
  v_severity TEXT := 'info';
BEGIN
  IF p_precip_pct > 50 THEN
    v_reasons := v_reasons || '"rain_above_50pct"'::jsonb;
    v_is_adverse := true;
    v_severity := 'warning';
  END IF;

  IF p_wind_mph > 25 THEN
    v_reasons := v_reasons || '"wind_above_25mph"'::jsonb;
    v_is_adverse := true;
    IF p_wind_mph > 40 THEN v_severity := 'severe'; END IF;
  END IF;

  IF p_temp_low_f < 20 THEN
    v_reasons := v_reasons || '"temp_below_20f"'::jsonb;
    v_is_adverse := true;
    v_severity := CASE WHEN v_severity = 'severe' THEN 'severe' ELSE 'warning' END;
  END IF;

  IF p_temp_high_f > 105 THEN
    v_reasons := v_reasons || '"extreme_heat"'::jsonb;
    v_is_adverse := true;
    v_severity := 'severe';
  END IF;

  IF p_has_alerts THEN
    v_reasons := v_reasons || '"nws_alert_active"'::jsonb;
    v_is_adverse := true;
    v_severity := 'extreme';
  END IF;

  RETURN jsonb_build_object(
    'is_adverse', v_is_adverse,
    'severity', v_severity,
    'reasons', v_reasons
  );
END;
$$;


-- ============================================================
-- 5. fn_get_weather_for_location
--    Returns cached weather forecast for a given ZIP/date,
--    or NULL if cache expired (caller should fetch fresh)
-- ============================================================

CREATE OR REPLACE FUNCTION fn_get_weather_for_location(
  p_zip TEXT,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS SETOF weather_forecasts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM weather_forecasts
  WHERE zip = p_zip
    AND forecast_date = p_date
    AND expires_at > now()
  ORDER BY fetched_at DESC
  LIMIT 1;
END;
$$;
