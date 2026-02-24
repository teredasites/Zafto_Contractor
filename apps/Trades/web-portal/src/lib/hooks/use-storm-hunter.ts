'use client';

// DEPTH28 S130: Storm Hunter Hook
// Real-time severe weather alerts, hail swath data, storm scoring
// for storm contractors. All from free NWS/NOAA/FEMA APIs.

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// ============================================================================
// TYPES
// ============================================================================

export interface WeatherAlert {
  id: string;
  event: string;
  severity: string;
  certainty: string;
  urgency: string;
  headline: string;
  description: string;
  instruction: string;
  effective: string;
  expires: string;
  areas: string;
  senderName: string;
  maxHail: string | null;
  maxWind: string | null;
  tornadoDetection: string | null;
}

export interface RecentStorm {
  id: string;
  type: string;
  title: string;
  state: string;
  county: string;
  date: string;
  incidentBegin: string;
  incidentEnd: string;
  programsActive: {
    ihp: boolean;
    ia: boolean;
    pa: boolean;
    hm: boolean;
  };
}

export interface StormScore {
  overallScore: number;
  hailScore: number;
  windScore: number;
  propertyDensityScore: number;
  revenueEstimate: 'low' | 'medium' | 'high' | 'very_high';
  factors: Record<string, unknown>;
}

export interface HailReport {
  date: string;
  time: string;
  size_inches: number;
  location: string;
  county: string;
  state: string;
  latitude: number;
  longitude: number;
}

// ============================================================================
// HOOK: useStormHunter
// ============================================================================

export function useStormHunter() {
  const [alerts, setAlerts] = useState<WeatherAlert[]>([]);
  const [storms, setStorms] = useState<RecentStorm[]>([]);
  const [score, setScore] = useState<StormScore | null>(null);
  const [hailReports, setHailReports] = useState<HailReport[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const callStormHunter = useCallback(async (action: string, params: Record<string, unknown>) => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-storm-hunter`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ action, ...params }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Storm hunter failed');
      return data;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Storm hunter failed';
      setError(msg);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchActiveAlerts = useCallback(async (params: { state?: string; latitude?: number; longitude?: number }) => {
    const data = await callStormHunter('active_alerts', params);
    if (data) setAlerts(data.alerts || []);
    return data;
  }, [callStormHunter]);

  const fetchRecentStorms = useCallback(async (params: { state?: string; days_back?: number }) => {
    const data = await callStormHunter('recent_storms', params);
    if (data) setStorms(data.storms || []);
    return data;
  }, [callStormHunter]);

  const fetchStormScore = useCallback(async (params: { latitude: number; longitude: number }) => {
    const data = await callStormHunter('storm_score', params);
    if (data?.score) setScore(data.score);
    return data;
  }, [callStormHunter]);

  const fetchHailSwath = useCallback(async (params: { state?: string; days_back?: number }) => {
    const data = await callStormHunter('hail_swath', params);
    if (data) setHailReports(data.hail_reports || []);
    return data;
  }, [callStormHunter]);

  return {
    alerts,
    storms,
    score,
    hailReports,
    loading,
    error,
    fetchActiveAlerts,
    fetchRecentStorms,
    fetchStormScore,
    fetchHailSwath,
  };
}
