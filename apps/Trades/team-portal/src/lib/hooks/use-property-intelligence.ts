'use client';

// DEPTH28: Property Intelligence Hook
// Fetches property profile, weather intelligence, permit history
// from new recon-property-intelligence EF data.

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface PropertyProfile {
  id: string;
  scanId: string;
  yearBuilt: number | null;
  livingSqft: number | null;
  lotSqft: number | null;
  stories: number | null;
  bedrooms: number | null;
  bathroomsFull: number | null;
  bathroomsHalf: number | null;
  constructionType: string | null;
  foundationType: string | null;
  roofStyle: string | null;
  exteriorMaterial: string | null;
  // Ownership
  ownerName: string | null;
  assessedValue: number | null;
  marketValueEst: number | null;
  lastSalePrice: number | null;
  lastSaleDate: string | null;
  ownershipYears: number | null;
  // Utilities
  heatingType: string | null;
  coolingType: string | null;
  electricUtility: string | null;
  gasUtility: string | null;
  serviceAmperage: number | null;
  servicePhase: string | null;
  // Environmental
  leadPaintProbability: string | null;
  asbestosProbability: string | null;
  radonZone: string | null;
  termiteZone: string | null;
  floodZone: string | null;
  floodRiskLevel: string | null;
  wildfireRiskScore: number | null;
  seismicZone: string | null;
  expansiveSoilRisk: string | null;
  // HOA
  hoaName: string | null;
  hoaArchitecturalReview: boolean;
  // Codes
  jurisdiction: string | null;
  ibcIrcYear: string | null;
  necYear: string | null;
  ieccYear: string | null;
  windSpeedMph: number | null;
  snowLoadPsf: number | null;
  frostLineDepthInches: number | null;
  climateZone: string | null;
  // Meta
  confidenceScore: number;
  dataSources: string[];
}

export interface WeatherIntelligence {
  id: string;
  scanId: string;
  // Current
  currentTempF: number | null;
  currentWindMph: number | null;
  currentPrecipMm: number | null;
  currentUvIndex: number | null;
  currentConditions: string | null;
  weatherFetchedAt: string | null;
  // Historical storm
  lastHailEventDate: string | null;
  lastHailSizeInches: number | null;
  lastTornadoDate: string | null;
  lastFloodEventDate: string | null;
  totalStormEvents5yr: number;
  totalStormEvents10yr: number;
  // Climate
  freezeThawCyclesYr: number | null;
  annualPrecipInches: number | null;
  heatingDegreeDays: number | null;
  coolingDegreeDays: number | null;
  // Storm damage score
  stormDamageScore: number;
  stormScoreFactors: Record<string, unknown>;
}

export interface PermitRecord {
  id: string;
  scanId: string;
  permitNumber: string | null;
  permitType: string | null;
  description: string | null;
  contractorName: string | null;
  filedDate: string | null;
  issuedDate: string | null;
  finalDate: string | null;
  status: string;
  estimatedCost: number | null;
  isRedFlag: boolean;
  redFlagReason: string | null;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapProfile(row: Record<string, unknown>): PropertyProfile {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    yearBuilt: row.year_built != null ? Number(row.year_built) : null,
    livingSqft: row.living_area_sqft != null ? Number(row.living_area_sqft) : null,
    lotSqft: row.lot_area_sqft != null ? Number(row.lot_area_sqft) : null,
    stories: row.stories != null ? Number(row.stories) : null,
    bedrooms: row.bedrooms != null ? Number(row.bedrooms) : null,
    bathroomsFull: row.bathrooms_full != null ? Number(row.bathrooms_full) : null,
    bathroomsHalf: row.bathrooms_half != null ? Number(row.bathrooms_half) : null,
    constructionType: row.construction_type as string | null,
    foundationType: row.foundation_type as string | null,
    roofStyle: row.roof_style as string | null,
    exteriorMaterial: row.exterior_material as string | null,
    ownerName: row.owner_name as string | null,
    assessedValue: row.assessed_value != null ? Number(row.assessed_value) : null,
    marketValueEst: row.market_value_est != null ? Number(row.market_value_est) : null,
    lastSalePrice: row.last_sale_price != null ? Number(row.last_sale_price) : null,
    lastSaleDate: row.last_sale_date as string | null,
    ownershipYears: row.ownership_years != null ? Number(row.ownership_years) : null,
    heatingType: row.heating_type as string | null,
    coolingType: row.cooling_type as string | null,
    electricUtility: row.electric_utility as string | null,
    gasUtility: row.gas_utility as string | null,
    serviceAmperage: row.service_amperage != null ? Number(row.service_amperage) : null,
    servicePhase: row.service_phase as string | null,
    leadPaintProbability: row.lead_paint_probability as string | null,
    asbestosProbability: row.asbestos_probability as string | null,
    radonZone: row.radon_zone as string | null,
    termiteZone: row.termite_zone as string | null,
    floodZone: row.flood_zone as string | null,
    floodRiskLevel: row.flood_risk_level as string | null,
    wildfireRiskScore: row.wildfire_risk_score != null ? Number(row.wildfire_risk_score) : null,
    seismicZone: row.seismic_zone as string | null,
    expansiveSoilRisk: row.expansive_soil_risk as string | null,
    hoaName: row.hoa_name as string | null,
    hoaArchitecturalReview: row.hoa_architectural_review === true,
    jurisdiction: row.jurisdiction as string | null,
    ibcIrcYear: row.ibc_irc_year as string | null,
    necYear: row.nec_year as string | null,
    ieccYear: row.iecc_year as string | null,
    windSpeedMph: row.wind_speed_mph != null ? Number(row.wind_speed_mph) : null,
    snowLoadPsf: row.snow_load_psf != null ? Number(row.snow_load_psf) : null,
    frostLineDepthInches: row.frost_line_depth_inches != null ? Number(row.frost_line_depth_inches) : null,
    climateZone: row.climate_zone as string | null,
    confidenceScore: Number(row.confidence_score) || 0,
    dataSources: (row.data_sources as string[]) || [],
  };
}

function mapWeather(row: Record<string, unknown>): WeatherIntelligence {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    currentTempF: row.current_temp_f != null ? Number(row.current_temp_f) : null,
    currentWindMph: row.current_wind_mph != null ? Number(row.current_wind_mph) : null,
    currentPrecipMm: row.current_precip_mm != null ? Number(row.current_precip_mm) : null,
    currentUvIndex: row.current_uv_index != null ? Number(row.current_uv_index) : null,
    currentConditions: row.current_conditions as string | null,
    weatherFetchedAt: row.weather_fetched_at as string | null,
    lastHailEventDate: row.last_hail_event_date as string | null,
    lastHailSizeInches: row.last_hail_size_inches != null ? Number(row.last_hail_size_inches) : null,
    lastTornadoDate: row.last_tornado_date as string | null,
    lastFloodEventDate: row.last_flood_event_date as string | null,
    totalStormEvents5yr: Number(row.total_storm_events_5yr) || 0,
    totalStormEvents10yr: Number(row.total_storm_events_10yr) || 0,
    freezeThawCyclesYr: row.freeze_thaw_cycles_yr != null ? Number(row.freeze_thaw_cycles_yr) : null,
    annualPrecipInches: row.annual_precip_inches != null ? Number(row.annual_precip_inches) : null,
    heatingDegreeDays: row.heating_degree_days != null ? Number(row.heating_degree_days) : null,
    coolingDegreeDays: row.cooling_degree_days != null ? Number(row.cooling_degree_days) : null,
    stormDamageScore: Number(row.storm_damage_score) || 0,
    stormScoreFactors: (row.storm_score_factors as Record<string, unknown>) || {},
  };
}

function mapPermit(row: Record<string, unknown>): PermitRecord {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    permitNumber: row.permit_number as string | null,
    permitType: row.permit_type as string | null,
    description: row.description as string | null,
    contractorName: row.contractor_name as string | null,
    filedDate: row.filed_date as string | null,
    issuedDate: row.issued_date as string | null,
    finalDate: row.final_date as string | null,
    status: (row.status as string) || 'unknown',
    estimatedCost: row.estimated_cost != null ? Number(row.estimated_cost) : null,
    isRedFlag: row.is_red_flag === true,
    redFlagReason: row.red_flag_reason as string | null,
  };
}

// ============================================================================
// HOOK: usePropertyIntelligence
// ============================================================================

export function usePropertyIntelligence(scanId: string) {
  const [profile, setProfile] = useState<PropertyProfile | null>(null);
  const [weather, setWeather] = useState<WeatherIntelligence | null>(null);
  const [permits, setPermits] = useState<PermitRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    if (!scanId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();

      // Fetch in parallel
      const [profileRes, weatherRes, permitsRes] = await Promise.all([
        supabase.from('property_profiles').select('*').eq('scan_id', scanId).maybeSingle(),
        supabase.from('weather_intelligence').select('*').eq('scan_id', scanId).maybeSingle(),
        supabase.from('permit_history').select('*').eq('scan_id', scanId).order('filed_date', { ascending: false }),
      ]);

      setProfile(profileRes.data ? mapProfile(profileRes.data) : null);
      setWeather(weatherRes.data ? mapWeather(weatherRes.data) : null);
      setPermits((permitsRes.data || []).map(mapPermit));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load intelligence');
    } finally {
      setLoading(false);
    }
  }, [scanId]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Trigger intelligence gathering
  const triggerIntelligence = useCallback(async () => {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-intelligence`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ scan_id: scanId }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Intelligence failed');

      await fetchData();
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Intelligence failed');
      return null;
    }
  }, [scanId, fetchData]);

  return { profile, weather, permits, loading, error, refetch: fetchData, triggerIntelligence };
}
