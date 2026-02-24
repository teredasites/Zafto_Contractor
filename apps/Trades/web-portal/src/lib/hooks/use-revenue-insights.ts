'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';

// === Types ===

export type Period = 'month' | 'quarter' | 'year';

export interface ChartDataPoint {
  label: string;
  revenue: number;
  expenses: number;
  profit: number;
}

export interface ServiceRevenue {
  service: string;
  revenue: number;
  margin: number;
  jobCount: number;
}

export interface CustomerInsight {
  id: string;
  name: string;
  totalSpend: number;
  jobCount: number;
  clvScore: number; // 0-100
  lastJobDate: string | null;
}

export interface AIRecommendation {
  id: string;
  type: 'pricing' | 'growth' | 'seasonal' | 'efficiency' | 'risk';
  title: string;
  description: string;
  impact: 'high' | 'medium' | 'low';
}

export interface KPIData {
  totalRevenue: number;
  prevTotalRevenue: number;
  avgJobSize: number;
  prevAvgJobSize: number;
  profitMargin: number;
  prevProfitMargin: number;
  activeCustomers: number;
  prevActiveCustomers: number;
}

export interface RevenueInsightsData {
  kpis: KPIData;
  chartData: ChartDataPoint[];
  services: ServiceRevenue[];
  topCustomers: CustomerInsight[];
  aiRecommendations: AIRecommendation[];
}

// === Helpers ===

function getPeriodRange(period: Period): { current: { start: Date; end: Date }; previous: { start: Date; end: Date } } {
  const now = new Date();
  let currentStart: Date;
  let previousStart: Date;
  let previousEnd: Date;

  if (period === 'month') {
    currentStart = new Date(now.getFullYear(), now.getMonth(), 1);
    previousStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    previousEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
  } else if (period === 'quarter') {
    const currentQ = Math.floor(now.getMonth() / 3);
    currentStart = new Date(now.getFullYear(), currentQ * 3, 1);
    previousStart = new Date(now.getFullYear(), (currentQ - 1) * 3, 1);
    previousEnd = new Date(now.getFullYear(), currentQ * 3, 0, 23, 59, 59);
  } else {
    currentStart = new Date(now.getFullYear(), 0, 1);
    previousStart = new Date(now.getFullYear() - 1, 0, 1);
    previousEnd = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59);
  }

  return {
    current: { start: currentStart, end: now },
    previous: { start: previousStart, end: previousEnd },
  };
}

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function generateAIRecommendations(
  kpis: KPIData,
  services: ServiceRevenue[],
  chartData: ChartDataPoint[]
): AIRecommendation[] {
  const recs: AIRecommendation[] = [];

  // Revenue trend analysis
  if (chartData.length >= 2) {
    const recent = chartData.slice(-3);
    const avgRecent = recent.reduce((s, d) => s + d.revenue, 0) / recent.length;
    const older = chartData.slice(0, Math.max(chartData.length - 3, 1));
    const avgOlder = older.reduce((s, d) => s + d.revenue, 0) / older.length;

    if (avgRecent > avgOlder * 1.1) {
      recs.push({
        id: 'growth-trend',
        type: 'growth',
        title: 'Revenue trending upward',
        description: `Recent periods show ${Math.round(((avgRecent - avgOlder) / (avgOlder || 1)) * 100)}% growth compared to earlier periods. Consider scaling operations to maintain momentum.`,
        impact: 'high',
      });
    } else if (avgRecent < avgOlder * 0.9) {
      recs.push({
        id: 'decline-trend',
        type: 'risk',
        title: 'Revenue declining',
        description: `Recent periods show a ${Math.round(((avgOlder - avgRecent) / (avgOlder || 1)) * 100)}% decline. Review pricing strategy and lead generation efforts.`,
        impact: 'high',
      });
    }
  }

  // Margin analysis
  if (kpis.profitMargin < 30) {
    recs.push({
      id: 'low-margin',
      type: 'pricing',
      title: 'Profit margin below target',
      description: `Current margin of ${kpis.profitMargin.toFixed(1)}% is below the 30% industry target. Review material costs and pricing on lower-margin services.`,
      impact: 'high',
    });
  } else if (kpis.profitMargin > 50) {
    recs.push({
      id: 'strong-margin',
      type: 'efficiency',
      title: 'Strong profit margins',
      description: `Margins at ${kpis.profitMargin.toFixed(1)}% are well above industry average. You have room to invest in growth or offer competitive pricing on bids.`,
      impact: 'medium',
    });
  }

  // Service diversification
  if (services.length > 0) {
    const topService = services[0];
    const totalRev = services.reduce((s, sv) => s + sv.revenue, 0);
    const topPct = totalRev > 0 ? (topService.revenue / totalRev) * 100 : 0;

    if (topPct > 60) {
      recs.push({
        id: 'concentration-risk',
        type: 'risk',
        title: 'Revenue concentration risk',
        description: `${topService.service} accounts for ${topPct.toFixed(0)}% of revenue. Diversifying service offerings will reduce business risk.`,
        impact: 'medium',
      });
    }
  }

  // Low-margin services
  const lowMarginServices = services.filter((s) => s.margin < 20 && s.revenue > 0);
  if (lowMarginServices.length > 0) {
    recs.push({
      id: 'pricing-review',
      type: 'pricing',
      title: `${lowMarginServices.length} service${lowMarginServices.length > 1 ? 's' : ''} with margins under 20%`,
      description: `Consider price adjustments for: ${lowMarginServices.map((s) => s.service).join(', ')}. Small price increases compound significantly over time.`,
      impact: 'medium',
    });
  }

  // Seasonal insight (Q4 typically slow for trades)
  const now = new Date();
  if (now.getMonth() >= 9) {
    recs.push({
      id: 'seasonal-q4',
      type: 'seasonal',
      title: 'Q4 seasonal planning',
      description: 'Late-year demand typically shifts to indoor work and emergency repairs. Adjust marketing spend toward service agreements and maintenance plans.',
      impact: 'low',
    });
  } else if (now.getMonth() >= 3 && now.getMonth() <= 5) {
    recs.push({
      id: 'seasonal-spring',
      type: 'seasonal',
      title: 'Spring demand surge',
      description: 'Peak season is approaching. Ensure crew capacity and material inventory are ready to handle increased job volume.',
      impact: 'medium',
    });
  }

  // Customer retention
  const revChange = kpis.prevTotalRevenue > 0
    ? ((kpis.totalRevenue - kpis.prevTotalRevenue) / kpis.prevTotalRevenue) * 100
    : 0;
  if (kpis.activeCustomers < kpis.prevActiveCustomers && kpis.prevActiveCustomers > 0) {
    recs.push({
      id: 'customer-retention',
      type: 'growth',
      title: 'Customer count declining',
      description: `Active customers dropped from ${kpis.prevActiveCustomers} to ${kpis.activeCustomers}. Focus on retention through service agreements and follow-up communications.`,
      impact: 'high',
    });
  }

  // Fallback: always provide at least one insight
  if (recs.length === 0) {
    recs.push({
      id: 'baseline',
      type: 'growth',
      title: 'Building your revenue baseline',
      description: 'Continue logging jobs and invoices consistently. Revenue intelligence improves with more data points to analyze trends and opportunities.',
      impact: 'low',
    });
  }

  return recs;
}

// === Hook ===

export function useRevenueInsights(period: Period = 'month') {
  const [data, setData] = useState<RevenueInsightsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchInsights = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const supabase = getSupabase();
      const ranges = getPeriodRange(period);

      // Parallel queries
      const [invoicesRes, jobsRes, materialsRes, customersRes] = await Promise.all([
        supabase.from('invoices').select('id, status, total, amount_paid, amount_due, paid_at, created_at, customer_id'),
        supabase.from('jobs').select('id, status, title, estimated_amount, actual_amount, tags, customer_name, customer_id, completed_at, created_at').is('deleted_at', null),
        supabase.from('job_materials').select('id, job_id, total_cost, created_at').is('deleted_at', null),
        supabase.from('customers').select('id, name, created_at').is('deleted_at', null),
      ]);

      const invoices: Record<string, unknown>[] = invoicesRes.data || [];
      const jobs: Record<string, unknown>[] = jobsRes.data || [];
      const materials: Record<string, unknown>[] = materialsRes.data || [];
      const customers: Record<string, unknown>[] = customersRes.data || [];

      // === Filter by period ===
      const inRange = (dateStr: unknown, start: Date, end: Date): boolean => {
        if (!dateStr) return false;
        const d = new Date(dateStr as string);
        return d >= start && d <= end;
      };

      const currentInvoices = invoices.filter((inv) => inRange(inv.paid_at || inv.created_at, ranges.current.start, ranges.current.end));
      const prevInvoices = invoices.filter((inv) => inRange(inv.paid_at || inv.created_at, ranges.previous.start, ranges.previous.end));
      const currentJobs = jobs.filter((j) => inRange(j.created_at, ranges.current.start, ranges.current.end));
      const prevJobs = jobs.filter((j) => inRange(j.created_at, ranges.previous.start, ranges.previous.end));
      const currentMaterials = materials.filter((m) => inRange(m.created_at, ranges.current.start, ranges.current.end));
      const prevMaterials = materials.filter((m) => inRange(m.created_at, ranges.previous.start, ranges.previous.end));

      // === KPIs ===
      const totalRevenue = currentInvoices.reduce((s, inv) => s + Number(inv.total || 0), 0);
      const prevTotalRevenue = prevInvoices.reduce((s, inv) => s + Number(inv.total || 0), 0);

      const currentJobValues = currentJobs.map((j) => Number(j.actual_amount || j.estimated_amount || 0));
      const prevJobValues = prevJobs.map((j) => Number(j.actual_amount || j.estimated_amount || 0));
      const avgJobSize = currentJobValues.length > 0 ? currentJobValues.reduce((a, b) => a + b, 0) / currentJobValues.length : 0;
      const prevAvgJobSize = prevJobValues.length > 0 ? prevJobValues.reduce((a, b) => a + b, 0) / prevJobValues.length : 0;

      const totalExpenses = currentMaterials.reduce((s, m) => s + Number(m.total_cost || 0), 0);
      const prevExpenses = prevMaterials.reduce((s, m) => s + Number(m.total_cost || 0), 0);
      const profitMargin = totalRevenue > 0 ? ((totalRevenue - totalExpenses) / totalRevenue) * 100 : 0;
      const prevProfitMargin = prevTotalRevenue > 0 ? ((prevTotalRevenue - prevExpenses) / prevTotalRevenue) * 100 : 0;

      const currentCustomerIds = new Set(currentInvoices.map((inv) => inv.customer_id as string).filter(Boolean));
      const prevCustomerIds = new Set(prevInvoices.map((inv) => inv.customer_id as string).filter(Boolean));
      const activeCustomers = currentCustomerIds.size;
      const prevActiveCustomers = prevCustomerIds.size;

      const kpis: KPIData = {
        totalRevenue,
        prevTotalRevenue,
        avgJobSize,
        prevAvgJobSize,
        profitMargin,
        prevProfitMargin,
        activeCustomers,
        prevActiveCustomers,
      };

      // === Chart Data (monthly revenue for last 12 months) ===
      const now = new Date();
      const chartData: ChartDataPoint[] = [];
      const monthCount = period === 'month' ? 6 : period === 'quarter' ? 12 : 12;

      for (let i = monthCount - 1; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthStart = d;
        const monthEnd = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59);

        const monthInvoices = invoices.filter((inv) => {
          const paidAt = inv.paid_at ? new Date(inv.paid_at as string) : null;
          const created = new Date(inv.created_at as string);
          const refDate = paidAt || created;
          return refDate >= monthStart && refDate <= monthEnd;
        });
        const revenue = monthInvoices.reduce((s, inv) => s + Number(inv.total || 0), 0);

        const monthMats = materials.filter((m) => {
          const created = new Date(m.created_at as string);
          return created >= monthStart && created <= monthEnd;
        });
        const expenses = monthMats.reduce((s, m) => s + Number(m.total_cost || 0), 0);

        chartData.push({
          label: `${MONTH_NAMES[d.getMonth()]} ${String(d.getFullYear()).slice(2)}`,
          revenue,
          expenses,
          profit: revenue - expenses,
        });
      }

      // === Services by Revenue (from job tags) ===
      const serviceMap: Record<string, { revenue: number; expenses: number; jobCount: number }> = {};
      for (const job of jobs) {
        const tags = (job.tags as string[]) || [];
        const service = tags[0] || 'General';
        const amount = Number(job.actual_amount || job.estimated_amount || 0);
        if (!serviceMap[service]) {
          serviceMap[service] = { revenue: 0, expenses: 0, jobCount: 0 };
        }
        serviceMap[service].revenue += amount;
        serviceMap[service].jobCount += 1;
      }

      // Attribute material costs to services via job_id
      const jobServiceMap: Record<string, string> = {};
      for (const job of jobs) {
        const tags = (job.tags as string[]) || [];
        jobServiceMap[job.id as string] = tags[0] || 'General';
      }
      for (const mat of materials) {
        const service = jobServiceMap[mat.job_id as string] || 'General';
        if (serviceMap[service]) {
          serviceMap[service].expenses += Number(mat.total_cost || 0);
        }
      }

      const services: ServiceRevenue[] = Object.entries(serviceMap)
        .map(([service, data]) => ({
          service: service.charAt(0).toUpperCase() + service.slice(1),
          revenue: data.revenue,
          margin: data.revenue > 0 ? ((data.revenue - data.expenses) / data.revenue) * 100 : 0,
          jobCount: data.jobCount,
        }))
        .sort((a, b) => b.revenue - a.revenue)
        .slice(0, 8);

      // === Top Customers ===
      const customerSpend: Record<string, { spend: number; jobCount: number; lastJob: string | null }> = {};
      for (const inv of invoices) {
        const custId = inv.customer_id as string;
        if (!custId) continue;
        if (!customerSpend[custId]) {
          customerSpend[custId] = { spend: 0, jobCount: 0, lastJob: null };
        }
        customerSpend[custId].spend += Number(inv.total || 0);
      }
      for (const job of jobs) {
        const custId = job.customer_id as string;
        if (!custId || !customerSpend[custId]) continue;
        customerSpend[custId].jobCount += 1;
        const completedAt = job.completed_at as string | null;
        if (completedAt && (!customerSpend[custId].lastJob || completedAt > customerSpend[custId].lastJob!)) {
          customerSpend[custId].lastJob = completedAt;
        }
      }

      const customerNameMap: Record<string, string> = {};
      for (const c of customers) {
        customerNameMap[c.id as string] = (c.name as string) || 'Unknown';
      }
      // Also check job customer_name as fallback
      for (const job of jobs) {
        const custId = job.customer_id as string;
        if (custId && !customerNameMap[custId] && job.customer_name) {
          customerNameMap[custId] = job.customer_name as string;
        }
      }

      const maxSpend = Math.max(...Object.values(customerSpend).map((c) => c.spend), 1);
      const topCustomers: CustomerInsight[] = Object.entries(customerSpend)
        .sort(([, a], [, b]) => b.spend - a.spend)
        .slice(0, 10)
        .map(([id, data]) => ({
          id,
          name: customerNameMap[id] || 'Unknown Customer',
          totalSpend: data.spend,
          jobCount: data.jobCount,
          clvScore: Math.min(Math.round((data.spend / maxSpend) * 80 + data.jobCount * 4), 100),
          lastJobDate: data.lastJob,
        }));

      // === AI Recommendations ===
      const aiRecommendations = generateAIRecommendations(kpis, services, chartData);

      setData({
        kpis,
        chartData,
        services,
        topCustomers,
        aiRecommendations,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load revenue insights');
    } finally {
      setLoading(false);
    }
  }, [period]);

  useEffect(() => {
    fetchInsights();
  }, [fetchInsights]);

  return { data, loading, error, refresh: fetchInsights };
}
