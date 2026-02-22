'use client';

import { useState, useEffect, useCallback } from 'react';
import { createClient } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type ScanStatus = 'pending' | 'scanning' | 'complete' | 'partial' | 'failed';
export type ConfidenceGrade = 'high' | 'moderate' | 'low';
export type RoofShape = 'gable' | 'hip' | 'flat' | 'gambrel' | 'mansard' | 'mixed';

export interface PropertyScanData {
  id: string;
  companyId: string;
  jobId: string | null;
  address: string;
  city: string | null;
  state: string | null;
  zip: string | null;
  latitude: number | null;
  longitude: number | null;
  status: ScanStatus;
  scanSources: string[];
  confidenceScore: number;
  confidenceGrade: ConfidenceGrade;
  confidenceFactors: Record<string, unknown>;
  imageryDate: string | null;
  imagerySource: string | null;
  imageryAgeMonths: number | null;
  createdAt: string;
  // Enhanced recon data
  storageFolder: string | null;
  streetViewUrl: string | null;
  externalLinks: Record<string, string>;
  propertyType: string | null;
  floodZone: string | null;
  floodRisk: string | null;
}

export interface RoofMeasurementData {
  id: string;
  scanId: string;
  totalAreaSqft: number;
  totalAreaSquares: number;
  pitchPrimary: string | null;
  pitchDegrees: number;
  ridgeLengthFt: number;
  hipLengthFt: number;
  valleyLengthFt: number;
  eaveLengthFt: number;
  rakeLengthFt: number;
  facetCount: number;
  complexityScore: number;
  predominantShape: RoofShape | null;
  predominantMaterial: string | null;
  penetrationCount: number;
}

export interface RoofFacetData {
  id: string;
  facetNumber: number;
  areaSqft: number;
  pitchDegrees: number;
  azimuthDegrees: number;
  annualSunHours: number | null;
  shadeFactor: number | null;
}

export interface WallMeasurementData {
  id: string;
  scanId: string;
  structureId: string | null;
  totalWallAreaSqft: number;
  totalSidingAreaSqft: number;
  perFace: Array<{
    direction: string;
    width_ft: number;
    height_ft: number;
    area_sqft: number;
    window_count_est: number;
    door_count_est: number;
    net_area_sqft: number;
  }>;
  stories: number;
  avgWallHeightFt: number;
  windowAreaEstSqft: number;
  doorAreaEstSqft: number;
  trimLinearFt: number;
  fasciaLinearFt: number;
  soffitSqft: number;
  dataSource: string;
  confidence: number;
  isEstimated: boolean;
}

export interface MaterialItem {
  item: string;
  quantity: number;
  unit: string;
  waste_pct: number;
  total_with_waste: number;
}

export type TradeType =
  | 'roofing' | 'siding' | 'gutters' | 'solar' | 'painting' | 'landscaping'
  | 'fencing' | 'concrete' | 'hvac' | 'electrical' | 'plumbing' | 'insulation'
  | 'windows_doors' | 'flooring' | 'drywall' | 'framing' | 'masonry'
  | 'waterproofing' | 'demolition' | 'tree_service' | 'pool' | 'garage_door'
  | 'fire_protection' | 'elevator' | 'fire_alarm' | 'low_voltage'
  | 'irrigation' | 'paving' | 'metal_fabrication' | 'glass_glazing';

export interface TradeBidData {
  id: string;
  scanId: string;
  trade: TradeType;
  measurements: Record<string, unknown>;
  materialList: MaterialItem[];
  wasteFactorPct: number;
  complexityScore: number;
  recommendedCrewSize: number;
  estimatedLaborHours: number | null;
  dataSources: string[];
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapScan(row: Record<string, unknown>): PropertyScanData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    jobId: row.job_id as string | null,
    address: row.address as string,
    city: row.city as string | null,
    state: row.state as string | null,
    zip: row.zip as string | null,
    latitude: row.latitude != null ? Number(row.latitude) : null,
    longitude: row.longitude != null ? Number(row.longitude) : null,
    status: row.status as ScanStatus,
    scanSources: (row.scan_sources as string[]) || [],
    confidenceScore: Number(row.confidence_score) || 0,
    confidenceGrade: (row.confidence_grade as ConfidenceGrade) || 'low',
    confidenceFactors: (row.confidence_factors as Record<string, unknown>) || {},
    imageryDate: row.imagery_date as string | null,
    imagerySource: row.imagery_source as string | null,
    imageryAgeMonths: row.imagery_age_months != null ? Number(row.imagery_age_months) : null,
    createdAt: row.created_at as string,
    // Enhanced recon data
    storageFolder: row.storage_folder as string | null,
    streetViewUrl: row.street_view_url as string | null,
    externalLinks: (row.external_links as Record<string, string>) || {},
    propertyType: row.property_type as string | null,
    floodZone: row.flood_zone as string | null,
    floodRisk: row.flood_risk as string | null,
  };
}

function mapRoofMeasurement(row: Record<string, unknown>): RoofMeasurementData {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    totalAreaSqft: Number(row.total_area_sqft) || 0,
    totalAreaSquares: Number(row.total_area_squares) || 0,
    pitchPrimary: row.pitch_primary as string | null,
    pitchDegrees: Number(row.pitch_degrees) || 0,
    ridgeLengthFt: Number(row.ridge_length_ft) || 0,
    hipLengthFt: Number(row.hip_length_ft) || 0,
    valleyLengthFt: Number(row.valley_length_ft) || 0,
    eaveLengthFt: Number(row.eave_length_ft) || 0,
    rakeLengthFt: Number(row.rake_length_ft) || 0,
    facetCount: Number(row.facet_count) || 0,
    complexityScore: Number(row.complexity_score) || 0,
    predominantShape: row.predominant_shape as RoofShape | null,
    predominantMaterial: row.predominant_material as string | null,
    penetrationCount: Number(row.penetration_count) || 0,
  };
}

function mapFacet(row: Record<string, unknown>): RoofFacetData {
  return {
    id: row.id as string,
    facetNumber: Number(row.facet_number),
    areaSqft: Number(row.area_sqft) || 0,
    pitchDegrees: Number(row.pitch_degrees) || 0,
    azimuthDegrees: Number(row.azimuth_degrees) || 0,
    annualSunHours: row.annual_sun_hours != null ? Number(row.annual_sun_hours) : null,
    shadeFactor: row.shade_factor != null ? Number(row.shade_factor) : null,
  };
}

function mapWallMeasurement(row: Record<string, unknown>): WallMeasurementData {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    structureId: row.structure_id as string | null,
    totalWallAreaSqft: Number(row.total_wall_area_sqft) || 0,
    totalSidingAreaSqft: Number(row.total_siding_area_sqft) || 0,
    perFace: (row.per_face as WallMeasurementData['perFace']) || [],
    stories: Number(row.stories) || 1,
    avgWallHeightFt: Number(row.avg_wall_height_ft) || 9,
    windowAreaEstSqft: Number(row.window_area_est_sqft) || 0,
    doorAreaEstSqft: Number(row.door_area_est_sqft) || 0,
    trimLinearFt: Number(row.trim_linear_ft) || 0,
    fasciaLinearFt: Number(row.fascia_linear_ft) || 0,
    soffitSqft: Number(row.soffit_sqft) || 0,
    dataSource: (row.data_source as string) || 'derived',
    confidence: Number(row.confidence) || 50,
    isEstimated: row.is_estimated !== false,
  };
}

function mapTradeBid(row: Record<string, unknown>): TradeBidData {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    trade: row.trade as TradeType,
    measurements: (row.measurements as Record<string, unknown>) || {},
    materialList: (row.material_list as MaterialItem[]) || [],
    wasteFactorPct: Number(row.waste_factor_pct) || 0,
    complexityScore: Number(row.complexity_score) || 0,
    recommendedCrewSize: Number(row.recommended_crew_size) || 2,
    estimatedLaborHours: row.estimated_labor_hours != null ? Number(row.estimated_labor_hours) : null,
    dataSources: (row.data_sources as string[]) || [],
  };
}

// ============================================================================
// HOOK: usePropertyScan
// ============================================================================

export function usePropertyScan(scanIdOrJobId: string, mode: 'scan' | 'job' = 'job') {
  const [scan, setScan] = useState<PropertyScanData | null>(null);
  const [roof, setRoof] = useState<RoofMeasurementData | null>(null);
  const [facets, setFacets] = useState<RoofFacetData[]>([]);
  const [walls, setWalls] = useState<WallMeasurementData | null>(null);
  const [tradeBids, setTradeBids] = useState<TradeBidData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    if (!scanIdOrJobId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();

      // Find scan
      let scanRow: Record<string, unknown> | null = null;

      if (mode === 'scan') {
        const { data } = await supabase
          .from('property_scans')
          .select('*')
          .eq('id', scanIdOrJobId)
          .single();
        scanRow = data;
      } else {
        const { data } = await supabase
          .from('property_scans')
          .select('*')
          .eq('job_id', scanIdOrJobId)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();
        scanRow = data;
      }

      if (!scanRow) {
        setScan(null);
        setRoof(null);
        setFacets([]);
        setWalls(null);
        setTradeBids([]);
        return;
      }

      const scanId = scanRow.id as string;
      setScan(mapScan(scanRow));

      // Get roof measurement
      const { data: roofRow } = await supabase
        .from('roof_measurements')
        .select('*')
        .eq('scan_id', scanId)
        .limit(1)
        .maybeSingle();

      if (roofRow) {
        setRoof(mapRoofMeasurement(roofRow));

        // Get facets
        const { data: facetRows } = await supabase
          .from('roof_facets')
          .select('*')
          .eq('roof_measurement_id', roofRow.id)
          .order('facet_number');

        setFacets((facetRows || []).map(mapFacet));
      } else {
        setRoof(null);
        setFacets([]);
      }

      // Get wall measurements
      const { data: wallRow } = await supabase
        .from('wall_measurements')
        .select('*')
        .eq('scan_id', scanId)
        .limit(1)
        .maybeSingle();

      setWalls(wallRow ? mapWallMeasurement(wallRow) : null);

      // Get trade bid data
      const { data: tradeRows } = await supabase
        .from('trade_bid_data')
        .select('*')
        .eq('scan_id', scanId)
        .order('trade');

      setTradeBids((tradeRows || []).map(mapTradeBid));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load scan');
    } finally {
      setLoading(false);
    }
  }, [scanIdOrJobId, mode]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  // Real-time subscription on scan status
  useEffect(() => {
    if (!scanIdOrJobId) return;
    const supabase = createClient();
    const filter = mode === 'scan'
      ? `id=eq.${scanIdOrJobId}`
      : `job_id=eq.${scanIdOrJobId}`;

    const channel = supabase
      .channel(`scan-${scanIdOrJobId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'property_scans', filter }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [scanIdOrJobId, mode, fetchData]);

  // Trigger new scan
  const triggerScan = useCallback(async (address: string, jobId?: string) => {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-lookup`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ address, job_id: jobId }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Scan failed');

      await fetchData();
      return data.scan_id as string;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Scan failed');
      return null;
    }
  }, [fetchData]);

  // Trigger trade estimation
  const triggerTradeEstimate = useCallback(async (scanId: string, selectedTrades?: string[]) => {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-trade-estimator`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ scan_id: scanId, trades: selectedTrades }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Trade estimation failed');

      await fetchData();
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Trade estimation failed');
      return null;
    }
  }, [fetchData]);

  // Trigger property intelligence gathering after scan
  const triggerIntelligence = useCallback(async (scanId: string) => {
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
      if (!res.ok) throw new Error(data.error || 'Intelligence gathering failed');
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Intelligence gathering failed');
      return null;
    }
  }, []);

  // Trigger auto-scope generation for selected trades
  const triggerAutoScope = useCallback(async (scanId: string, trades: string[]) => {
    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-auto-scope`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ scan_id: scanId, trades }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Auto-scope generation failed');

      await fetchData();
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Auto-scope generation failed');
      return null;
    }
  }, [fetchData]);

  return {
    scan,
    roof,
    facets,
    walls,
    tradeBids,
    loading,
    error,
    refetch: fetchData,
    triggerScan,
    triggerTradeEstimate,
    triggerIntelligence,
    triggerAutoScope,
  };
}

// ============================================================================
// HOOK: usePropertyScans (list for CRM)
// ============================================================================

export function usePropertyScans() {
  const [scans, setScans] = useState<PropertyScanData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchScans = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      const { data, error: err } = await supabase
        .from('property_scans')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(100);

      if (err) throw err;
      setScans((data || []).map(mapScan));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load scans');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchScans();
  }, [fetchScans]);

  return { scans, loading, error, refetch: fetchScans };
}
