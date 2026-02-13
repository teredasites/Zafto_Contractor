'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES (read-only for team portal)
// ============================================================================

export interface PropertyScanData {
  id: string;
  address: string;
  city: string | null;
  state: string | null;
  status: string;
  confidenceScore: number;
  confidenceGrade: string;
  imageryDate: string | null;
  verificationStatus: string;
  createdAt: string;
}

export interface RoofMeasurementData {
  totalAreaSqft: number;
  totalAreaSquares: number;
  pitchPrimary: string | null;
  facetCount: number;
  complexityScore: number;
  predominantShape: string | null;
  ridgeLengthFt: number;
  hipLengthFt: number;
  valleyLengthFt: number;
  eaveLengthFt: number;
  rakeLengthFt: number;
}

export interface LeadScoreData {
  overallScore: number;
  grade: string;
}

// ============================================================================
// MAPPERS
// ============================================================================

function mapScan(row: Record<string, unknown>): PropertyScanData {
  return {
    id: row.id as string,
    address: row.address as string,
    city: row.city as string | null,
    state: row.state as string | null,
    status: row.status as string,
    confidenceScore: Number(row.confidence_score) || 0,
    confidenceGrade: (row.confidence_grade as string) || 'low',
    imageryDate: row.imagery_date as string | null,
    verificationStatus: (row.verification_status as string) || 'unverified',
    createdAt: row.created_at as string,
  };
}

function mapRoof(row: Record<string, unknown>): RoofMeasurementData {
  return {
    totalAreaSqft: Number(row.total_area_sqft) || 0,
    totalAreaSquares: Number(row.total_area_squares) || 0,
    pitchPrimary: row.pitch_primary as string | null,
    facetCount: Number(row.facet_count) || 0,
    complexityScore: Number(row.complexity_score) || 0,
    predominantShape: row.predominant_shape as string | null,
    ridgeLengthFt: Number(row.ridge_length_ft) || 0,
    hipLengthFt: Number(row.hip_length_ft) || 0,
    valleyLengthFt: Number(row.valley_length_ft) || 0,
    eaveLengthFt: Number(row.eave_length_ft) || 0,
    rakeLengthFt: Number(row.rake_length_ft) || 0,
  };
}

// ============================================================================
// HOOK: useJobPropertyScan (team portal — read-only scan for assigned job)
// ============================================================================

export function useJobPropertyScan(jobId: string) {
  const [scan, setScan] = useState<PropertyScanData | null>(null);
  const [roof, setRoof] = useState<RoofMeasurementData | null>(null);
  const [leadScore, setLeadScore] = useState<LeadScoreData | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    if (!jobId) { setLoading(false); return; }
    try {
      const supabase = getSupabase();

      // Get most recent scan for this job
      const { data: scanRow } = await supabase
        .from('property_scans')
        .select('*')
        .eq('job_id', jobId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!scanRow) {
        setScan(null);
        setRoof(null);
        setLeadScore(null);
        setLoading(false);
        return;
      }

      setScan(mapScan(scanRow));
      const scanId = scanRow.id as string;

      // Get roof measurement
      const { data: roofRow } = await supabase
        .from('roof_measurements')
        .select('*')
        .eq('scan_id', scanId)
        .limit(1)
        .maybeSingle();

      setRoof(roofRow ? mapRoof(roofRow) : null);

      // Get lead score
      const { data: scoreRow } = await supabase
        .from('property_lead_scores')
        .select('overall_score, grade')
        .eq('property_scan_id', scanId)
        .limit(1)
        .maybeSingle();

      setLeadScore(scoreRow ? {
        overallScore: Number(scoreRow.overall_score) || 0,
        grade: (scoreRow.grade as string) || 'cold',
      } : null);
    } catch {
      // Non-critical — don't show errors for scan data
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  useEffect(() => { fetchData(); }, [fetchData]);

  // Verify a measurement (team can verify on-site)
  const verifyMeasurement = useCallback(async (
    scanId: string,
    field: string,
    oldValue: string,
    newValue: string,
    isAdjustment: boolean,
  ) => {
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const companyId = user.app_metadata?.company_id;
      if (!companyId) return;

      // Log history
      await supabase.from('scan_history').insert({
        company_id: companyId,
        scan_id: scanId,
        action: isAdjustment ? 'adjusted' : 'verified',
        field_changed: field,
        old_value: oldValue,
        new_value: newValue,
        performed_by: user.id,
        device: 'team_portal',
      });

      // Update verification status
      await supabase.from('property_scans').update({
        verification_status: isAdjustment ? 'adjusted' : 'verified',
        verified_by: user.id,
        verified_at: new Date().toISOString(),
      }).eq('id', scanId);

      await fetchData();
    } catch {
      // Non-critical
    }
  }, [fetchData]);

  return { scan, roof, leadScore, loading, verifyMeasurement, refetch: fetchData };
}
