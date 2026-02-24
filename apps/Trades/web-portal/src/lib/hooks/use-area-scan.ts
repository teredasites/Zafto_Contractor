'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export type AreaScanType = 'prospecting' | 'storm_response' | 'canvassing';
export type AreaScanStatus = 'pending' | 'scanning' | 'complete' | 'failed';

export interface AreaScanData {
  id: string;
  companyId: string;
  name: string | null;
  scanType: AreaScanType;
  polygonGeojson: { type: string; coordinates: number[][][] } | null;
  stormEventId: string | null;
  stormDate: string | null;
  stormType: string | null;
  totalParcels: number;
  scannedParcels: number;
  hotLeads: number;
  warmLeads: number;
  coldLeads: number;
  status: AreaScanStatus;
  createdBy: string | null;
  createdAt: string;
}

export interface LeadScoreData {
  id: string;
  propertyScanId: string;
  companyId: string;
  areaScanId: string | null;
  overallScore: number;
  grade: 'hot' | 'warm' | 'cold';
  roofAgeScore: number;
  propertyValueScore: number;
  ownerTenureScore: number;
  conditionScore: number;
  permitScore: number;
  stormDamageProbability: number;
  scoringFactors: Record<string, unknown>;
  createdAt: string;
  // Joined fields
  address?: string;
  city?: string | null;
  state?: string | null;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapAreaScan(row: Record<string, unknown>): AreaScanData {
  return {
    id: row.id as string,
    companyId: row.company_id as string,
    name: row.name as string | null,
    scanType: (row.scan_type as AreaScanType) || 'prospecting',
    polygonGeojson: row.polygon_geojson as AreaScanData['polygonGeojson'],
    stormEventId: row.storm_event_id as string | null,
    stormDate: row.storm_date as string | null,
    stormType: row.storm_type as string | null,
    totalParcels: Number(row.total_parcels) || 0,
    scannedParcels: Number(row.scanned_parcels) || 0,
    hotLeads: Number(row.hot_leads) || 0,
    warmLeads: Number(row.warm_leads) || 0,
    coldLeads: Number(row.cold_leads) || 0,
    status: (row.status as AreaScanStatus) || 'pending',
    createdBy: row.created_by as string | null,
    createdAt: row.created_at as string,
  };
}

function mapLeadScore(row: Record<string, unknown>): LeadScoreData {
  const scan = row.property_scans as Record<string, unknown> | undefined;
  return {
    id: row.id as string,
    propertyScanId: row.property_scan_id as string,
    companyId: row.company_id as string,
    areaScanId: row.area_scan_id as string | null,
    overallScore: Number(row.overall_score) || 0,
    grade: (row.grade as 'hot' | 'warm' | 'cold') || 'cold',
    roofAgeScore: Number(row.roof_age_score) || 0,
    propertyValueScore: Number(row.property_value_score) || 0,
    ownerTenureScore: Number(row.owner_tenure_score) || 0,
    conditionScore: Number(row.condition_score) || 0,
    permitScore: Number(row.permit_score) || 0,
    stormDamageProbability: Number(row.storm_damage_probability) || 0,
    scoringFactors: (row.scoring_factors as Record<string, unknown>) || {},
    createdAt: row.created_at as string,
    address: scan?.address as string | undefined,
    city: scan?.city as string | null | undefined,
    state: scan?.state as string | null | undefined,
  };
}

// ============================================================================
// HOOK: useAreaScans (list)
// ============================================================================

export function useAreaScans() {
  const [scans, setScans] = useState<AreaScanData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchScans = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('area_scans')
        .select('*')
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(50);

      if (err) throw err;
      setScans((data || []).map(mapAreaScan));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load area scans');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchScans(); }, [fetchScans]);

  // Real-time subscription for status updates
  useEffect(() => {
    const supabase = getSupabase();
    const channel = supabase
      .channel('area-scans-list')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'area_scans' }, () => fetchScans())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchScans]);

  return { scans, loading, error, refetch: fetchScans };
}

// ============================================================================
// HOOK: useAreaScan (single + leads)
// ============================================================================

export function useAreaScan(areaScanId: string) {
  const [scan, setScan] = useState<AreaScanData | null>(null);
  const [leads, setLeads] = useState<LeadScoreData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    if (!areaScanId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();

      // Fetch area scan
      const { data: scanRow, error: scanErr } = await supabase
        .from('area_scans')
        .select('*')
        .eq('id', areaScanId)
        .is('deleted_at', null)
        .single();

      if (scanErr || !scanRow) {
        setError('Area scan not found');
        return;
      }

      setScan(mapAreaScan(scanRow));

      // Fetch lead scores with property scan address (join)
      const { data: leadRows, error: leadErr } = await supabase
        .from('property_lead_scores')
        .select('*, property_scans(address, city, state)')
        .eq('area_scan_id', areaScanId)
        .order('overall_score', { ascending: false })
        .limit(200);

      if (leadErr) throw leadErr;
      setLeads((leadRows || []).map(mapLeadScore));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load area scan');
    } finally {
      setLoading(false);
    }
  }, [areaScanId]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Real-time subscription for scanning progress
  useEffect(() => {
    if (!areaScanId) return;
    const supabase = getSupabase();
    const channel = supabase
      .channel(`area-scan-${areaScanId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'area_scans',
        filter: `id=eq.${areaScanId}`,
      }, () => fetchData())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [areaScanId, fetchData]);

  // Trigger area scan
  const triggerAreaScan = useCallback(async (params: {
    name?: string;
    scan_type?: AreaScanType;
    polygon_geojson: { type: string; coordinates: number[][][] };
    storm_event_id?: string;
    storm_date?: string;
    storm_type?: string;
  }) => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-area-scan`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify(params),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Area scan failed');

      await fetchData();
      return data.area_scan_id as string;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Area scan failed');
      return null;
    }
  }, [fetchData]);

  // Export leads to CSV
  const exportCsv = useCallback(() => {
    if (leads.length === 0) return;

    const headers = ['Address', 'City', 'State', 'Score', 'Grade', 'Roof Age Score', 'Property Value Score', 'Owner Tenure Score', 'Condition Score'];
    const rows = leads.map(l => [
      l.address || '',
      l.city || '',
      l.state || '',
      String(l.overallScore),
      l.grade,
      String(l.roofAgeScore),
      String(l.propertyValueScore),
      String(l.ownerTenureScore),
      String(l.conditionScore),
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(r => r.map(cell => `"${cell.replace(/"/g, '""')}"`).join(',')),
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `area-scan-${areaScanId}-leads.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }, [leads, areaScanId]);

  return {
    scan,
    leads,
    loading,
    error,
    refetch: fetchData,
    triggerAreaScan,
    exportCsv,
  };
}

// ============================================================================
// HOOK: useLeadScore (single property lead score)
// ============================================================================

export function useLeadScore(propertyScanId: string) {
  const [leadScore, setLeadScore] = useState<LeadScoreData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!propertyScanId) {
      setLoading(false);
      return;
    }

    const fetchScore = async () => {
      setLoading(true);
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('property_lead_scores')
          .select('*')
          .eq('property_scan_id', propertyScanId)
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();

        setLeadScore(data ? mapLeadScore(data) : null);
      } catch {
        setLeadScore(null);
      } finally {
        setLoading(false);
      }
    };

    fetchScore();
  }, [propertyScanId]);

  // Trigger lead score computation
  const computeScore = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-lead-score`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ property_scan_id: propertyScanId }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Scoring failed');

      // Refetch
      const supabase2 = getSupabase();
      const { data: updated } = await supabase2
        .from('property_lead_scores')
        .select('*')
        .eq('property_scan_id', propertyScanId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      setLeadScore(updated ? mapLeadScore(updated) : null);
      return data;
    } catch {
      return null;
    }
  }, [propertyScanId]);

  return { leadScore, loading, computeScore };
}
