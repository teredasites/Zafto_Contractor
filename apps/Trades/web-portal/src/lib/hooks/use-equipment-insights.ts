'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface MaintenanceItem {
  task: string;
  interval_months: number;
  next_due: string;
  priority: 'high' | 'medium' | 'low';
  estimated_cost: number;
  notes: string;
}

export interface PartSuggestion {
  name: string;
  part_number: string;
  reason: string;
  estimated_cost: number;
  urgency: 'immediate' | 'soon' | 'stock';
}

export interface ReplacementTimeline {
  equipment_id: string;
  equipment_name: string;
  expected_replacement_year: number;
  estimated_replacement_cost: number;
  risk_level: 'high' | 'medium' | 'low';
  recommendation: string;
}

export interface EquipmentInsight {
  equipment_health: number;
  next_service_date: string | null;
  maintenance_schedule: MaintenanceItem[];
  parts_to_stock: PartSuggestion[];
  replacement_timeline: ReplacementTimeline[];
  estimated_annual_cost: number;
  equipment_count: number;
  summary: string;
}

export function useEquipmentInsights(propertyId?: string) {
  const [insights, setInsights] = useState<EquipmentInsight | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchInsights = useCallback(async (equipmentId?: string) => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Get company_id from user metadata or profile
      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', session.user.id)
        .single();

      const companyId = profile?.company_id;
      if (!companyId) throw new Error('No company associated with user');

      const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
      const response = await fetch(`${baseUrl}/functions/v1/ai-equipment-insights`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({
          company_id: companyId,
          property_id: propertyId,
          equipment_id: equipmentId,
        }),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(errData.error || `HTTP ${response.status}`);
      }

      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Analysis failed');

      const result: EquipmentInsight = {
        equipment_health: data.equipment_health,
        next_service_date: data.next_service_date,
        maintenance_schedule: data.maintenance_schedule || [],
        parts_to_stock: data.parts_to_stock || [],
        replacement_timeline: data.replacement_timeline || [],
        estimated_annual_cost: data.estimated_annual_cost || 0,
        equipment_count: data.equipment_count || 0,
        summary: data.summary || '',
      };

      setInsights(result);
      return result;
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to load equipment insights';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, [propertyId]);

  return { insights, loading, error, fetchInsights };
}
