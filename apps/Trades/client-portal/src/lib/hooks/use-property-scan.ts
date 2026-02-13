'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ============================================================================
// TYPES (customer-friendly view — no internal data)
// ============================================================================

export interface PropertyOverview {
  id: string;
  address: string;
  city: string | null;
  state: string | null;
  // Customer-friendly labels
  roofSizeLabel: string | null;     // "~35 squares"
  roofShapeLabel: string | null;    // "Hip roof"
  roofPitchLabel: string | null;    // "6/12 pitch"
  buildingSizeLabel: string | null; // "~2,400 sq ft"
  storiesLabel: string | null;      // "2 stories"
  imageryDateLabel: string | null;  // "Jan 2024"
  status: string;
}

// ============================================================================
// SHAPE LABELS (customer-friendly)
// ============================================================================

const SHAPE_LABELS: Record<string, string> = {
  gable: 'Gable roof',
  hip: 'Hip roof',
  flat: 'Flat roof',
  gambrel: 'Gambrel roof',
  mansard: 'Mansard roof',
  mixed: 'Complex roof',
};

// ============================================================================
// HOOK: usePropertyOverview (client portal — friendly, stripped of internal data)
// ============================================================================

export function usePropertyOverview(projectId: string) {
  const { profile } = useAuth();
  const [property, setProperty] = useState<PropertyOverview | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    if (!projectId || !profile?.customerId) { setLoading(false); return; }

    try {
      const supabase = getSupabase();

      // Get scan linked to the job (project)
      const { data: scanRow } = await supabase
        .from('property_scans')
        .select('id, address, city, state, status')
        .eq('job_id', projectId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!scanRow) {
        setProperty(null);
        setLoading(false);
        return;
      }

      const scanId = scanRow.id as string;

      // Get roof data for friendly labels
      const { data: roofRow } = await supabase
        .from('roof_measurements')
        .select('total_area_squares, predominant_shape, pitch_primary')
        .eq('scan_id', scanId)
        .limit(1)
        .maybeSingle();

      // Get structure data
      const { data: structRow } = await supabase
        .from('property_structures')
        .select('footprint_sqft, estimated_stories')
        .eq('property_scan_id', scanId)
        .eq('structure_type', 'primary')
        .limit(1)
        .maybeSingle();

      const squares = roofRow ? Number(roofRow.total_area_squares) : null;
      const shape = roofRow?.predominant_shape as string | null;
      const pitch = roofRow?.pitch_primary as string | null;
      const footprint = structRow ? Number(structRow.footprint_sqft) : null;
      const stories = structRow ? Number(structRow.estimated_stories) : null;

      // Get imagery date
      const { data: fullScan } = await supabase
        .from('property_scans')
        .select('imagery_date')
        .eq('id', scanId)
        .single();

      const imageryDate = fullScan?.imagery_date as string | null;
      let imageryLabel: string | null = null;
      if (imageryDate) {
        const d = new Date(imageryDate);
        imageryLabel = d.toLocaleDateString(undefined, { month: 'short', year: 'numeric' });
      }

      setProperty({
        id: scanId,
        address: scanRow.address as string,
        city: scanRow.city as string | null,
        state: scanRow.state as string | null,
        roofSizeLabel: squares && squares > 0 ? `~${Math.round(squares)} squares` : null,
        roofShapeLabel: shape ? (SHAPE_LABELS[shape] || shape) : null,
        roofPitchLabel: pitch || null,
        buildingSizeLabel: footprint && footprint > 0
          ? `~${Math.round(footprint).toLocaleString()} sq ft`
          : null,
        storiesLabel: stories && stories > 0 ? `${stories} ${stories === 1 ? 'story' : 'stories'}` : null,
        imageryDateLabel: imageryLabel,
        status: scanRow.status as string,
      });
    } catch {
      // Non-critical
    } finally {
      setLoading(false);
    }
  }, [projectId, profile?.customerId]);

  useEffect(() => { fetchData(); }, [fetchData]);

  return { property, loading };
}
