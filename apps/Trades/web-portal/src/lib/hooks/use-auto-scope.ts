'use client';

// DEPTH28 Part D: Auto-Scope Generation Hook
// Calls recon-auto-scope EF and displays trade-specific scope data.

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface ScopeItem {
  category: string;    // measurements, materials, code, permits, environmental, notes
  item: string;
  label: string;
  value: string;
  unit: string;
  source: string;
  confidence: number;
}

export interface CodeRequirement {
  code_type: string;
  year: string;
  requirement: string;
  section?: string;
}

export interface CrossTradeDependency {
  trade: string;
  reason: string;
  priority: 'before' | 'after' | 'concurrent';
}

export interface TradeAutoScope {
  id: string;
  scanId: string;
  trade: string;
  scopeSummary: string;
  scopeItems: ScopeItem[];
  codeRequirements: CodeRequirement[];
  permitsRequired: boolean;
  permitTypes: string[];
  dependencies: CrossTradeDependency[];
  confidenceScore: number;
  dataSources: string[];
  createdAt: string;
}

// ============================================================================
// MAPPER
// ============================================================================

function mapScope(row: Record<string, unknown>): TradeAutoScope {
  return {
    id: row.id as string,
    scanId: row.scan_id as string,
    trade: row.trade as string,
    scopeSummary: (row.scope_summary as string) || '',
    scopeItems: (row.scope_items as ScopeItem[]) || [],
    codeRequirements: (row.code_requirements as CodeRequirement[]) || [],
    permitsRequired: row.permits_required === true,
    permitTypes: (row.permit_types as string[]) || [],
    dependencies: (row.dependencies as CrossTradeDependency[]) || [],
    confidenceScore: Number(row.confidence_score) || 0,
    dataSources: (row.data_sources as string[]) || [],
    createdAt: row.created_at as string,
  };
}

// ============================================================================
// HOOK: useAutoScope
// ============================================================================

export function useAutoScope(scanId: string) {
  const [scopes, setScopes] = useState<TradeAutoScope[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchScopes = useCallback(async () => {
    if (!scanId) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data, error: err } = await supabase
        .from('trade_auto_scopes')
        .select('*')
        .eq('scan_id', scanId)
        .order('trade');

      if (err) throw err;
      setScopes((data || []).map(mapScope));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load scopes');
    } finally {
      setLoading(false);
    }
  }, [scanId]);

  useEffect(() => { fetchScopes(); }, [fetchScopes]);

  // Generate scope for selected trades
  const generateScope = useCallback(async (trades: string[]) => {
    if (!scanId || !trades.length) return null;
    setGenerating(true);
    setError(null);
    try {
      const supabase = getSupabase();
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
      if (!res.ok) throw new Error(data.error || 'Scope generation failed');

      await fetchScopes();
      return data;
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Scope generation failed');
      return null;
    } finally {
      setGenerating(false);
    }
  }, [scanId, fetchScopes]);

  return { scopes, loading, generating, error, refetch: fetchScopes, generateScope };
}
