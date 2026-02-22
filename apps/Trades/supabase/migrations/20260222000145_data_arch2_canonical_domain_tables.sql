-- DATA-ARCH2: Canonical Domain Tables + Normalization Layer (S135)
-- Every API maps into ONE of these canonical tables. The app never reads raw API data.
-- Multiple APIs can feed the same canonical table (redundancy/accuracy).

-- ============================================================================
-- canonical_addresses — Normalized address data from USPS/Nominatim/etc.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.canonical_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type varchar(30) NOT NULL, -- 'CUSTOMER', 'PROPERTY', 'JOB', 'TEAM_MEMBER', 'LEAD', 'VENDOR'
  entity_id uuid NOT NULL,
  raw_address text,
  street_line_1 varchar(200),
  street_line_2 varchar(200),
  city varchar(100),
  state varchar(2),
  zip varchar(10),
  zip_plus_4 varchar(4),
  county varchar(100),
  country varchar(2) NOT NULL DEFAULT 'US',
  lat decimal(10,7),
  lng decimal(10,7),
  geocode_source varchar(50), -- 'nominatim', 'usps', 'google', 'mapbox'
  geocode_confidence varchar(20), -- 'high', 'medium', 'low'
  msa_cbsa varchar(10),
  census_tract varchar(11),
  fips_county varchar(5),
  timezone varchar(50),
  validated boolean DEFAULT false,
  validated_at timestamptz,
  validation_source varchar(50),
  company_id uuid,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_canonical_addresses_entity ON public.canonical_addresses(entity_type, entity_id);
CREATE INDEX idx_canonical_addresses_company ON public.canonical_addresses(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_canonical_addresses_zip ON public.canonical_addresses(zip);
CREATE INDEX idx_canonical_addresses_geo ON public.canonical_addresses(lat, lng) WHERE lat IS NOT NULL AND lng IS NOT NULL;
CREATE INDEX idx_canonical_addresses_msa ON public.canonical_addresses(msa_cbsa) WHERE msa_cbsa IS NOT NULL;

CREATE TRIGGER update_canonical_addresses_updated_at
  BEFORE UPDATE ON public.canonical_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.canonical_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY canonical_addresses_select ON public.canonical_addresses
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR company_id IS NULL
  );

CREATE POLICY canonical_addresses_insert ON public.canonical_addresses
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY canonical_addresses_update ON public.canonical_addresses
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- ============================================================================
-- canonical_weather — Unified weather data from NWS/Open-Meteo/etc.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.canonical_weather (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lat decimal(10,7) NOT NULL,
  lng decimal(10,7) NOT NULL,
  grid_id varchar(20), -- NWS grid point e.g. 'TOP/31,80'
  observation_time timestamptz,
  forecast_time timestamptz,
  temperature_f decimal(5,1),
  feels_like_f decimal(5,1),
  humidity_pct decimal(5,1),
  wind_speed_mph decimal(5,1),
  wind_gust_mph decimal(5,1),
  wind_direction varchar(5),
  precipitation_probability_pct decimal(5,1),
  precipitation_type varchar(20), -- 'none', 'rain', 'snow', 'sleet', 'ice'
  precipitation_amount_in decimal(5,2),
  condition_code varchar(50), -- 'clear', 'cloudy', 'rain', 'thunderstorm', etc.
  condition_text varchar(100),
  uv_index int,
  visibility_miles decimal(5,1),
  dew_point_f decimal(5,1),
  pressure_hpa decimal(7,1),
  cloud_cover_pct decimal(5,1),
  -- Computed workability flag
  is_workable boolean GENERATED ALWAYS AS (
    precipitation_probability_pct < 40
    AND (wind_speed_mph IS NULL OR wind_speed_mph < 25)
    AND (temperature_f IS NULL OR (temperature_f BETWEEN 20 AND 105))
  ) STORED,
  source_api varchar(50) NOT NULL, -- 'nws', 'openmeteo', 'visualcrossing'
  fetched_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_canonical_weather_location ON public.canonical_weather(lat, lng);
CREATE INDEX idx_canonical_weather_forecast ON public.canonical_weather(forecast_time) WHERE forecast_time IS NOT NULL;
CREATE INDEX idx_canonical_weather_expires ON public.canonical_weather(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_canonical_weather_workable ON public.canonical_weather(is_workable, forecast_time) WHERE forecast_time IS NOT NULL;

ALTER TABLE public.canonical_weather ENABLE ROW LEVEL SECURITY;

-- Weather data is public (non-company-scoped) — read access for all authenticated
CREATE POLICY canonical_weather_select ON public.canonical_weather
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR auth.uid() IS NOT NULL
  );

CREATE POLICY canonical_weather_insert ON public.canonical_weather
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY canonical_weather_update ON public.canonical_weather
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- canonical_compliance — Building codes, OSHA, EPA, licensing from all sources
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.canonical_compliance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction_type varchar(20) NOT NULL, -- 'FEDERAL', 'STATE', 'COUNTY', 'CITY'
  jurisdiction_code varchar(20) NOT NULL, -- FIPS code, state abbrev, etc.
  jurisdiction_name varchar(200),
  domain varchar(30) NOT NULL, -- 'BUILDING_CODE', 'ELECTRICAL', 'PLUMBING', 'MECHANICAL', 'FIRE', 'ENVIRONMENTAL', 'LICENSING', 'LABOR', 'SAFETY', 'ZONING'
  reference_code varchar(50), -- e.g. 'IBC-2021-1001', 'OSHA-29CFR1926.451'
  title text NOT NULL,
  description text,
  effective_date date,
  expiration_date date,
  source_url text,
  source_api varchar(50), -- 'osha_standards', 'ecfr_api', 'icc_codes', etc.
  applies_to_trades text[], -- ['ELE', 'PLM', 'HVC']
  applies_to_entity_types text[], -- ['contractor', 'inspector']
  penalty_description text,
  is_active boolean DEFAULT true,
  version varchar(20),
  fetched_at timestamptz DEFAULT now(),
  company_id uuid, -- NULL for public data, set for company-specific compliance
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_canonical_compliance_jurisdiction ON public.canonical_compliance(jurisdiction_type, jurisdiction_code);
CREATE INDEX idx_canonical_compliance_domain ON public.canonical_compliance(domain);
CREATE INDEX idx_canonical_compliance_trades ON public.canonical_compliance USING gin(applies_to_trades);
CREATE INDEX idx_canonical_compliance_active ON public.canonical_compliance(is_active) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_canonical_compliance_ref ON public.canonical_compliance(reference_code) WHERE reference_code IS NOT NULL;

CREATE TRIGGER update_canonical_compliance_updated_at
  BEFORE UPDATE ON public.canonical_compliance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.canonical_compliance ENABLE ROW LEVEL SECURITY;

-- Compliance data: public data readable by all, company-specific scoped
CREATE POLICY canonical_compliance_select ON public.canonical_compliance
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id IS NULL
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY canonical_compliance_insert ON public.canonical_compliance
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin')
  );

CREATE POLICY canonical_compliance_update ON public.canonical_compliance
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR (auth.jwt() -> 'app_metadata' ->> 'role') IN ('super_admin')
  );

-- ============================================================================
-- canonical_property_intel — Unified property intelligence from all sources
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.canonical_property_intel (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid, -- FK to properties/client_properties
  address_hash varchar(64), -- SHA-256 of normalized address, for non-FK lookups
  company_id uuid,
  data_type varchar(30) NOT NULL, -- 'FLOOD_ZONE', 'ENVIRONMENTAL_HAZARD', 'ASSESSOR', 'PERMIT_HISTORY', 'SCHOOL_DISTRICT', 'WALK_SCORE', 'CRIME_RATE', 'ENERGY_SCORE', 'HISTORIC_STATUS', 'WILDFIRE_RISK', 'EARTHQUAKE_RISK', 'RADON_ZONE', 'UTILITY_PROVIDER', 'HOA', 'SOLAR_POTENTIAL'
  data_value jsonb NOT NULL DEFAULT '{}',
  confidence_pct int DEFAULT 0, -- 0-100
  source_api varchar(50) NOT NULL,
  source_url text,
  fetched_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  -- Computed staleness flag
  is_stale boolean GENERATED ALWAYS AS (
    expires_at IS NOT NULL AND expires_at < now()
  ) STORED,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX idx_canonical_property_intel_property ON public.canonical_property_intel(property_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_canonical_property_intel_hash ON public.canonical_property_intel(address_hash) WHERE address_hash IS NOT NULL;
CREATE INDEX idx_canonical_property_intel_type ON public.canonical_property_intel(data_type);
CREATE INDEX idx_canonical_property_intel_company ON public.canonical_property_intel(company_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_canonical_property_intel_stale ON public.canonical_property_intel(is_stale) WHERE is_stale = true AND deleted_at IS NULL;

CREATE TRIGGER update_canonical_property_intel_updated_at
  BEFORE UPDATE ON public.canonical_property_intel
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.canonical_property_intel ENABLE ROW LEVEL SECURITY;

CREATE POLICY canonical_property_intel_select ON public.canonical_property_intel
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
    OR company_id IS NULL
  );

CREATE POLICY canonical_property_intel_insert ON public.canonical_property_intel
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

CREATE POLICY canonical_property_intel_update ON public.canonical_property_intel
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR company_id = (auth.jwt() -> 'app_metadata' ->> 'company_id')::uuid
  );

-- ============================================================================
-- canonical_market_data — Economic/real estate data from FRED/Census/HUD/etc.
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.canonical_market_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  geography_type varchar(20) NOT NULL, -- 'NATIONAL', 'STATE', 'MSA', 'COUNTY', 'ZIP'
  geography_code varchar(20) NOT NULL, -- FIPS, CBSA, state code, ZIP
  geography_name varchar(200),
  metric_type varchar(30) NOT NULL, -- 'MEDIAN_HOME_PRICE', 'MEDIAN_RENT', 'DAYS_ON_MARKET', 'INVENTORY_MONTHS', 'PRICE_PER_SQFT', 'MORTGAGE_RATE', 'UNEMPLOYMENT', 'POPULATION', 'MEDIAN_INCOME', 'HPI_INDEX', 'VACANCY_RATE', 'ABSORPTION_RATE', 'NEW_LISTINGS', 'PRICE_CHANGE_YOY', 'PERMIT_ACTIVITY', 'CONSTRUCTION_SPENDING'
  metric_value decimal(14,4),
  metric_date date NOT NULL,
  source_api varchar(50) NOT NULL, -- 'fred', 'census_acs', 'fhfa_hpi', 'hud_fmr', 'bls'
  source_series_id varchar(100), -- e.g. FRED series ID, BLS series ID
  fetched_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(geography_type, geography_code, metric_type, metric_date, source_api)
);

CREATE INDEX idx_canonical_market_geography ON public.canonical_market_data(geography_type, geography_code);
CREATE INDEX idx_canonical_market_metric ON public.canonical_market_data(metric_type);
CREATE INDEX idx_canonical_market_date ON public.canonical_market_data(metric_date DESC);
CREATE INDEX idx_canonical_market_source ON public.canonical_market_data(source_api);

ALTER TABLE public.canonical_market_data ENABLE ROW LEVEL SECURITY;

-- Market data is public — readable by all authenticated users
CREATE POLICY canonical_market_data_select ON public.canonical_market_data
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
    OR auth.uid() IS NOT NULL
  );

CREATE POLICY canonical_market_data_insert ON public.canonical_market_data
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY canonical_market_data_update ON public.canonical_market_data
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- Normalization Functions — Map raw API schemas → canonical schemas
-- ============================================================================

-- Address normalization: takes raw address components → standardized canonical
CREATE OR REPLACE FUNCTION public.fn_normalize_address(
  p_entity_type varchar,
  p_entity_id uuid,
  p_raw_address text,
  p_street1 varchar DEFAULT NULL,
  p_street2 varchar DEFAULT NULL,
  p_city varchar DEFAULT NULL,
  p_state varchar DEFAULT NULL,
  p_zip varchar DEFAULT NULL,
  p_lat decimal DEFAULT NULL,
  p_lng decimal DEFAULT NULL,
  p_source varchar DEFAULT 'manual',
  p_company_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id uuid;
  v_zip_clean varchar(10);
  v_zip_plus4 varchar(4);
BEGIN
  -- Clean ZIP: extract 5-digit + optional plus-4
  v_zip_clean := regexp_replace(COALESCE(p_zip, ''), '[^0-9-]', '', 'g');
  IF v_zip_clean ~ '^\d{5}-\d{4}$' THEN
    v_zip_plus4 := substring(v_zip_clean from 7 for 4);
    v_zip_clean := substring(v_zip_clean from 1 for 5);
  ELSIF v_zip_clean ~ '^\d{9}$' THEN
    v_zip_plus4 := substring(v_zip_clean from 6 for 4);
    v_zip_clean := substring(v_zip_clean from 1 for 5);
  ELSIF v_zip_clean ~ '^\d{5}$' THEN
    v_zip_plus4 := NULL;
  ELSE
    v_zip_clean := NULL;
    v_zip_plus4 := NULL;
  END IF;

  INSERT INTO public.canonical_addresses (
    entity_type, entity_id, raw_address,
    street_line_1, street_line_2, city, state, zip, zip_plus_4,
    lat, lng, geocode_source, geocode_confidence,
    validated, validation_source, company_id
  ) VALUES (
    upper(p_entity_type), p_entity_id, p_raw_address,
    trim(p_street1), nullif(trim(COALESCE(p_street2, '')), ''),
    trim(p_city), upper(trim(COALESCE(p_state, ''))),
    v_zip_clean, v_zip_plus4,
    p_lat, p_lng, p_source,
    CASE
      WHEN p_lat IS NOT NULL AND p_lng IS NOT NULL THEN 'high'
      WHEN v_zip_clean IS NOT NULL THEN 'medium'
      ELSE 'low'
    END,
    p_lat IS NOT NULL AND p_lng IS NOT NULL AND v_zip_clean IS NOT NULL,
    p_source, p_company_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Weather normalization: NWS API response → canonical
CREATE OR REPLACE FUNCTION public.fn_normalize_weather_nws(
  p_lat decimal,
  p_lng decimal,
  p_nws_data jsonb
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id uuid;
  v_props jsonb;
BEGIN
  v_props := p_nws_data -> 'properties';
  IF v_props IS NULL THEN RETURN NULL; END IF;

  INSERT INTO public.canonical_weather (
    lat, lng, grid_id,
    temperature_f, humidity_pct, wind_speed_mph, wind_gust_mph, wind_direction,
    precipitation_probability_pct, condition_text,
    source_api, fetched_at, expires_at
  ) VALUES (
    p_lat, p_lng,
    (v_props ->> 'gridId') || '/' || (v_props ->> 'gridX') || ',' || (v_props ->> 'gridY'),
    CASE WHEN v_props -> 'temperature' ->> 'unitCode' = 'wmoUnit:degC'
      THEN ((v_props -> 'temperature' ->> 'value')::decimal * 9.0/5.0) + 32
      ELSE (v_props -> 'temperature' ->> 'value')::decimal
    END,
    (v_props -> 'relativeHumidity' ->> 'value')::decimal,
    CASE WHEN v_props -> 'windSpeed' ->> 'unitCode' LIKE '%km%'
      THEN (v_props -> 'windSpeed' ->> 'value')::decimal * 0.621371
      ELSE (v_props -> 'windSpeed' ->> 'value')::decimal
    END,
    CASE WHEN v_props -> 'windGust' ->> 'unitCode' LIKE '%km%'
      THEN (v_props -> 'windGust' ->> 'value')::decimal * 0.621371
      ELSE (v_props -> 'windGust' ->> 'value')::decimal
    END,
    v_props -> 'windDirection' ->> 'value',
    (v_props -> 'probabilityOfPrecipitation' ->> 'value')::decimal,
    v_props ->> 'shortForecast',
    'nws',
    now(),
    now() + interval '1 hour'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Compliance normalization: OSHA standard → canonical
CREATE OR REPLACE FUNCTION public.fn_normalize_compliance_osha(
  p_osha_data jsonb
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.canonical_compliance (
    jurisdiction_type, jurisdiction_code, jurisdiction_name,
    domain, reference_code, title, description,
    source_api, source_url, is_active, fetched_at
  ) VALUES (
    'FEDERAL', 'US', 'United States',
    'SAFETY',
    p_osha_data ->> 'standard_number',
    p_osha_data ->> 'title',
    p_osha_data ->> 'text',
    'osha_standards',
    'https://www.osha.gov/laws-regs/regulations/standardnumber/' || (p_osha_data ->> 'standard_number'),
    true,
    now()
  )
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- Market data normalization: FRED series → canonical
CREATE OR REPLACE FUNCTION public.fn_normalize_market_fred(
  p_geography_type varchar,
  p_geography_code varchar,
  p_geography_name varchar,
  p_metric_type varchar,
  p_series_id varchar,
  p_data jsonb -- array of {date, value}
)
RETURNS int
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_count int := 0;
  v_item jsonb;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_data)
  LOOP
    INSERT INTO public.canonical_market_data (
      geography_type, geography_code, geography_name,
      metric_type, metric_value, metric_date,
      source_api, source_series_id, fetched_at
    ) VALUES (
      upper(p_geography_type), p_geography_code, p_geography_name,
      upper(p_metric_type),
      (v_item ->> 'value')::decimal,
      (v_item ->> 'date')::date,
      'fred', p_series_id, now()
    )
    ON CONFLICT (geography_type, geography_code, metric_type, metric_date, source_api) DO UPDATE
      SET metric_value = EXCLUDED.metric_value,
          fetched_at = now();
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- Property intel upsert helper
CREATE OR REPLACE FUNCTION public.fn_upsert_property_intel(
  p_property_id uuid,
  p_address_hash varchar,
  p_company_id uuid,
  p_data_type varchar,
  p_data_value jsonb,
  p_confidence int,
  p_source_api varchar,
  p_ttl_hours int DEFAULT 168 -- 7 days default
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id uuid;
BEGIN
  -- Check for existing non-stale entry
  SELECT id INTO v_id
  FROM public.canonical_property_intel
  WHERE (property_id = p_property_id OR address_hash = p_address_hash)
    AND data_type = p_data_type
    AND source_api = p_source_api
    AND deleted_at IS NULL
    AND (expires_at IS NULL OR expires_at > now());

  IF v_id IS NOT NULL THEN
    -- Update existing
    UPDATE public.canonical_property_intel
    SET data_value = p_data_value,
        confidence_pct = p_confidence,
        fetched_at = now(),
        expires_at = now() + (p_ttl_hours || ' hours')::interval
    WHERE id = v_id;
    RETURN v_id;
  END IF;

  -- Insert new
  INSERT INTO public.canonical_property_intel (
    property_id, address_hash, company_id,
    data_type, data_value, confidence_pct,
    source_api, fetched_at, expires_at
  ) VALUES (
    p_property_id, p_address_hash, p_company_id,
    upper(p_data_type), p_data_value, p_confidence,
    p_source_api, now(), now() + (p_ttl_hours || ' hours')::interval
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;
