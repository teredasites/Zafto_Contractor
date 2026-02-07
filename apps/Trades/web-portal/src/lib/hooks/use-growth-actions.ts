'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export type ActionType = 'follow_up' | 'upsell' | 'campaign' | 'review';
export type ActionPriority = 'high' | 'medium' | 'low';

export interface GrowthAction {
  type: ActionType;
  customer_id: string | null;
  customer_name: string | null;
  title: string;
  description: string;
  priority: ActionPriority;
  suggested_date: string;
  draft_message: string | null;
  estimated_value: number | null;
  confidence: number;
}

export interface GrowthActionsData {
  actions: GrowthAction[];
  summary: string;
  total_estimated_value: number;
}

export function useGrowthActions() {
  const [actions, setActions] = useState<GrowthAction[]>([]);
  const [summary, setSummary] = useState<string>('');
  const [totalValue, setTotalValue] = useState<number>(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchActions = useCallback(async (actionType?: ActionType) => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // Get company_id from user profile
      const { data: profile } = await supabase
        .from('users')
        .select('company_id')
        .eq('id', session.user.id)
        .single();

      const companyId = profile?.company_id;
      if (!companyId) throw new Error('No company associated with user');

      const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
      const response = await fetch(`${baseUrl}/functions/v1/ai-growth-actions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({
          company_id: companyId,
          action_type: actionType,
        }),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({ error: 'Request failed' }));
        throw new Error(errData.error || `HTTP ${response.status}`);
      }

      const data = await response.json();
      if (!data.success) throw new Error(data.error || 'Analysis failed');

      const result: GrowthActionsData = {
        actions: data.actions || [],
        summary: data.summary || '',
        total_estimated_value: data.total_estimated_value || 0,
      };

      setActions(result.actions);
      setSummary(result.summary);
      setTotalValue(result.total_estimated_value);
      return result;
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to load growth actions';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const refresh = useCallback(() => fetchActions(), [fetchActions]);

  return { actions, summary, totalValue, loading, error, fetchActions, refresh };
}
