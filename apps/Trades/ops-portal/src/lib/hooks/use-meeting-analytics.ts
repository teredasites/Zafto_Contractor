'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface MeetingStatusBreakdown {
  status: string;
  count: number;
}

export interface MeetingTypeBreakdown {
  meeting_type: string;
  count: number;
}

export interface CompanyMeetingVolume {
  company_id: string;
  company_name: string;
  meeting_count: number;
  avg_duration: number;
}

export interface MeetingAnalyticsData {
  totalMeetings: number;
  activeMeetings: number;
  completedMeetings: number;
  avgDuration: number;
  byStatus: MeetingStatusBreakdown[];
  byType: MeetingTypeBreakdown[];
  topCompanies: CompanyMeetingVolume[];
}

export interface UseMeetingAnalyticsReturn {
  data: MeetingAnalyticsData;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

const emptyData: MeetingAnalyticsData = {
  totalMeetings: 0,
  activeMeetings: 0,
  completedMeetings: 0,
  avgDuration: 0,
  byStatus: [],
  byType: [],
  topCompanies: [],
};

export function useMeetingAnalytics(): UseMeetingAnalyticsReturn {
  const [data, setData] = useState<MeetingAnalyticsData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();

      // Fetch all meetings with company name join
      const { data: meetings, error: meetingsErr } = await supabase
        .from('meetings')
        .select('id, status, meeting_type, company_id, actual_duration_minutes, duration_minutes, companies(name)');

      if (meetingsErr) throw meetingsErr;

      const rows = (meetings || []) as Array<{
        id: string;
        status: string;
        meeting_type: string;
        company_id: string;
        actual_duration_minutes: number | null;
        duration_minutes: number | null;
        companies: { name: string } | null;
      }>;

      const totalMeetings = rows.length;

      // Count active (in_progress)
      const activeMeetings = rows.filter((r) => r.status === 'in_progress').length;

      // Count completed
      const completedMeetings = rows.filter((r) => r.status === 'completed').length;

      // Average duration — prefer actual_duration_minutes, fall back to duration_minutes
      const durationsWithValue = rows
        .map((r) => r.actual_duration_minutes ?? r.duration_minutes)
        .filter((d): d is number => d !== null && d > 0);
      const avgDuration =
        durationsWithValue.length > 0
          ? Math.round(durationsWithValue.reduce((sum, d) => sum + d, 0) / durationsWithValue.length)
          : 0;

      // Status breakdown
      const statusCounts: Record<string, number> = {};
      for (const row of rows) {
        statusCounts[row.status] = (statusCounts[row.status] || 0) + 1;
      }
      const byStatus: MeetingStatusBreakdown[] = Object.entries(statusCounts)
        .map(([status, count]) => ({ status, count }))
        .sort((a, b) => b.count - a.count);

      // Type breakdown
      const typeCounts: Record<string, number> = {};
      for (const row of rows) {
        typeCounts[row.meeting_type] = (typeCounts[row.meeting_type] || 0) + 1;
      }
      const byType: MeetingTypeBreakdown[] = Object.entries(typeCounts)
        .map(([meeting_type, count]) => ({ meeting_type, count }))
        .sort((a, b) => b.count - a.count);

      // Top companies by meeting count + avg duration
      const companyAgg: Record<string, { name: string; count: number; totalDur: number; durCount: number }> = {};
      for (const row of rows) {
        const cid = row.company_id;
        if (!companyAgg[cid]) {
          const companyName = row.companies?.name || 'Unknown';
          companyAgg[cid] = { name: companyName, count: 0, totalDur: 0, durCount: 0 };
        }
        companyAgg[cid].count += 1;
        const dur = row.actual_duration_minutes ?? row.duration_minutes;
        if (dur && dur > 0) {
          companyAgg[cid].totalDur += dur;
          companyAgg[cid].durCount += 1;
        }
      }
      const topCompanies: CompanyMeetingVolume[] = Object.entries(companyAgg)
        .map(([company_id, agg]) => ({
          company_id,
          company_name: agg.name,
          meeting_count: agg.count,
          avg_duration: agg.durCount > 0 ? Math.round(agg.totalDur / agg.durCount) : 0,
        }))
        .sort((a, b) => b.meeting_count - a.meeting_count)
        .slice(0, 10);

      setData({
        totalMeetings,
        activeMeetings,
        completedMeetings,
        avgDuration,
        byStatus,
        byType,
        topCompanies,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch meeting analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}
