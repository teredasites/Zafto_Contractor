'use client';

import { useEffect, useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

export interface CallStatusBreakdown {
  status: string;
  count: number;
}

export interface CompanyCallVolume {
  company_id: string;
  company_name: string;
  call_count: number;
  sms_count: number;
  fax_count: number;
}

export interface PhoneAnalyticsData {
  totalCalls: number;
  totalSMS: number;
  totalFaxes: number;
  activeLines: number;
  callsByStatus: CallStatusBreakdown[];
  topCompanies: CompanyCallVolume[];
}

export interface UsePhoneAnalyticsReturn {
  data: PhoneAnalyticsData;
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

const emptyData: PhoneAnalyticsData = {
  totalCalls: 0,
  totalSMS: 0,
  totalFaxes: 0,
  activeLines: 0,
  callsByStatus: [],
  topCompanies: [],
};

export function usePhoneAnalytics(): UsePhoneAnalyticsReturn {
  const [data, setData] = useState<PhoneAnalyticsData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();

      // Run all queries in parallel
      const [
        callsRes,
        messagesRes,
        faxesRes,
        linesRes,
        callStatusRes,
      ] = await Promise.all([
        // Total calls
        supabase
          .from('phone_calls')
          .select('id', { count: 'exact', head: true }),
        // Total SMS
        supabase
          .from('phone_messages')
          .select('id', { count: 'exact', head: true }),
        // Total faxes
        supabase
          .from('phone_faxes')
          .select('id', { count: 'exact', head: true }),
        // Active phone lines
        supabase
          .from('phone_lines')
          .select('id', { count: 'exact', head: true })
          .eq('is_active', true),
        // All calls with status + company_id for breakdown
        supabase
          .from('phone_calls')
          .select('status, company_id'),
      ]);

      // Get companies for name lookup
      const companyIds = new Set<string>();
      const callsByCompany: Record<string, number> = {};
      const statusCounts: Record<string, number> = {};

      if (callStatusRes.data) {
        for (const call of callStatusRes.data) {
          const row = call as { status: string; company_id: string };
          // Status breakdown
          statusCounts[row.status] = (statusCounts[row.status] || 0) + 1;
          // Company volume
          companyIds.add(row.company_id);
          callsByCompany[row.company_id] = (callsByCompany[row.company_id] || 0) + 1;
        }
      }

      // SMS counts by company
      const smsByCompany: Record<string, number> = {};
      const smsAllRes = await supabase
        .from('phone_messages')
        .select('company_id');
      if (smsAllRes.data) {
        for (const msg of smsAllRes.data) {
          const row = msg as { company_id: string };
          companyIds.add(row.company_id);
          smsByCompany[row.company_id] = (smsByCompany[row.company_id] || 0) + 1;
        }
      }

      // Fax counts by company
      const faxByCompany: Record<string, number> = {};
      const faxAllRes = await supabase
        .from('phone_faxes')
        .select('company_id');
      if (faxAllRes.data) {
        for (const fax of faxAllRes.data) {
          const row = fax as { company_id: string };
          companyIds.add(row.company_id);
          faxByCompany[row.company_id] = (faxByCompany[row.company_id] || 0) + 1;
        }
      }

      // Fetch company names
      const companyNames: Record<string, string> = {};
      if (companyIds.size > 0) {
        const { data: companies } = await supabase
          .from('companies')
          .select('id, name')
          .in('id', Array.from(companyIds));
        if (companies) {
          for (const c of companies) {
            const row = c as { id: string; name: string };
            companyNames[row.id] = row.name;
          }
        }
      }

      // Build call status breakdown
      const callsByStatus: CallStatusBreakdown[] = Object.entries(statusCounts)
        .map(([status, count]) => ({ status, count }))
        .sort((a, b) => b.count - a.count);

      // Build top companies by total volume (calls + sms + fax)
      const allCompanyIds = new Set([
        ...Object.keys(callsByCompany),
        ...Object.keys(smsByCompany),
        ...Object.keys(faxByCompany),
      ]);

      const topCompanies: CompanyCallVolume[] = Array.from(allCompanyIds)
        .map((cid) => ({
          company_id: cid,
          company_name: companyNames[cid] || 'Unknown',
          call_count: callsByCompany[cid] || 0,
          sms_count: smsByCompany[cid] || 0,
          fax_count: faxByCompany[cid] || 0,
        }))
        .sort((a, b) =>
          (b.call_count + b.sms_count + b.fax_count) -
          (a.call_count + a.sms_count + a.fax_count)
        )
        .slice(0, 10);

      setData({
        totalCalls: callsRes.count ?? 0,
        totalSMS: messagesRes.count ?? 0,
        totalFaxes: faxesRes.count ?? 0,
        activeLines: linesRes.count ?? 0,
        callsByStatus,
        topCompanies,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch phone analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}
