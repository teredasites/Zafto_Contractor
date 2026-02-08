'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  Truck,
  Wrench,
  Fuel,
  Building2,
  BarChart3,
  Inbox,
  RefreshCw,
  CheckCircle2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { getSupabase } from '@/lib/supabase';
import { formatNumber, formatCurrency } from '@/lib/utils';

interface CompanyFleet {
  company_id: string;
  company_name: string;
  vehicle_count: number;
  maintenance_count: number;
  fuel_spend: number;
}

interface FleetData {
  totalVehicles: number;
  activeVehicles: number;
  maintenanceThisMonth: number;
  fuelCostThisMonth: number;
  fleetByCompany: CompanyFleet[];
}

const emptyData: FleetData = {
  totalVehicles: 0,
  activeVehicles: 0,
  maintenanceThisMonth: 0,
  fuelCostThisMonth: 0,
  fleetByCompany: [],
};

function useFleetAnalytics() {
  const [data, setData] = useState<FleetData>(emptyData);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const supabase = getSupabase();
      const now = new Date();
      const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

      const [
        totalVehiclesRes,
        activeVehiclesRes,
        maintenanceMonthRes,
        fuelMonthRes,
        vehiclesByCompanyRes,
        maintenanceByCompanyRes,
        fuelByCompanyRes,
      ] = await Promise.all([
        // Total vehicles
        supabase
          .from('vehicles')
          .select('id', { count: 'exact', head: true }),
        // Active vehicles
        supabase
          .from('vehicles')
          .select('id', { count: 'exact', head: true })
          .eq('status', 'active'),
        // Maintenance this month
        supabase
          .from('vehicle_maintenance')
          .select('id', { count: 'exact', head: true })
          .gte('created_at', monthStart),
        // Fuel logs this month
        supabase
          .from('fuel_logs')
          .select('cost')
          .gte('created_at', monthStart),
        // Vehicles by company
        supabase
          .from('vehicles')
          .select('company_id'),
        // Maintenance by company
        supabase
          .from('vehicle_maintenance')
          .select('company_id'),
        // Fuel by company
        supabase
          .from('fuel_logs')
          .select('company_id, cost'),
      ]);

      // Fuel cost this month
      let fuelCostThisMonth = 0;
      if (fuelMonthRes.data) {
        for (const log of fuelMonthRes.data) {
          const row = log as { cost: number };
          fuelCostThisMonth += row.cost || 0;
        }
      }

      // Aggregate by company
      const companyIds = new Set<string>();
      const vehicleCountByCompany: Record<string, number> = {};
      const maintenanceCountByCompany: Record<string, number> = {};
      const fuelSpendByCompany: Record<string, number> = {};

      if (vehiclesByCompanyRes.data) {
        for (const v of vehiclesByCompanyRes.data) {
          const row = v as { company_id: string };
          companyIds.add(row.company_id);
          vehicleCountByCompany[row.company_id] = (vehicleCountByCompany[row.company_id] || 0) + 1;
        }
      }

      if (maintenanceByCompanyRes.data) {
        for (const m of maintenanceByCompanyRes.data) {
          const row = m as { company_id: string };
          companyIds.add(row.company_id);
          maintenanceCountByCompany[row.company_id] = (maintenanceCountByCompany[row.company_id] || 0) + 1;
        }
      }

      if (fuelByCompanyRes.data) {
        for (const f of fuelByCompanyRes.data) {
          const row = f as { company_id: string; cost: number };
          companyIds.add(row.company_id);
          fuelSpendByCompany[row.company_id] = (fuelSpendByCompany[row.company_id] || 0) + (row.cost || 0);
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

      // Build fleet by company
      const fleetByCompany: CompanyFleet[] = Array.from(companyIds)
        .map((cid) => ({
          company_id: cid,
          company_name: companyNames[cid] || 'Unknown',
          vehicle_count: vehicleCountByCompany[cid] || 0,
          maintenance_count: maintenanceCountByCompany[cid] || 0,
          fuel_spend: fuelSpendByCompany[cid] || 0,
        }))
        .sort((a, b) => b.vehicle_count - a.vehicle_count)
        .slice(0, 15);

      setData({
        totalVehicles: totalVehiclesRes.count ?? 0,
        activeVehicles: activeVehiclesRes.count ?? 0,
        maintenanceThisMonth: maintenanceMonthRes.count ?? 0,
        fuelCostThisMonth,
        fleetByCompany,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch fleet analytics');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}

export default function FleetAnalyticsPage() {
  const { data, loading, error, refetch } = useFleetAnalytics();

  const metrics = [
    {
      label: 'Total Vehicles',
      value: formatNumber(data.totalVehicles),
      icon: <Truck className="h-5 w-5" />,
      subtext: 'All companies',
    },
    {
      label: 'Active Vehicles',
      value: formatNumber(data.activeVehicles),
      icon: <CheckCircle2 className="h-5 w-5" />,
      subtext: 'Currently active',
    },
    {
      label: 'Maintenance This Month',
      value: formatNumber(data.maintenanceThisMonth),
      icon: <Wrench className="h-5 w-5" />,
      subtext: 'Service records',
    },
    {
      label: 'Fuel Cost This Month',
      value: formatCurrency(data.fuelCostThisMonth),
      icon: <Fuel className="h-5 w-5" />,
      subtext: 'Platform-wide',
    },
  ];

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Fleet Analytics
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Cross-company vehicle fleet, maintenance, and fuel metrics
          </p>
        </div>
        <button
          onClick={refetch}
          disabled={loading}
          className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium border border-[var(--border)] bg-[var(--bg-card)] text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] hover:text-[var(--text-primary)] transition-colors disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="p-4 rounded-lg border border-red-200 bg-red-50 dark:border-red-800 dark:bg-red-950/30">
          <p className="text-sm text-red-700 dark:text-red-400">{error}</p>
        </div>
      )}

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {metrics.map((metric) => (
          <Card key={metric.label}>
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-[var(--text-secondary)]">
                  {metric.label}
                </p>
                {loading ? (
                  <div className="h-8 w-16 mt-1 rounded skeleton-shimmer" />
                ) : (
                  <p className="text-2xl font-bold text-[var(--text-primary)] mt-1">
                    {metric.value}
                  </p>
                )}
                <p className="text-xs text-[var(--text-secondary)] mt-1">
                  {metric.subtext}
                </p>
              </div>
              <div className="p-2 rounded-lg bg-[var(--accent)]/10 text-[var(--accent)]">
                {metric.icon}
              </div>
            </div>
          </Card>
        ))}
      </div>

      {/* Fleet by Company */}
      <Card>
        <CardHeader>
          <CardTitle>Fleet by Company</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-4">
              {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4 py-3">
                  <div className="h-4 w-40 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-16 rounded skeleton-shimmer" />
                  <div className="h-4 w-20 rounded skeleton-shimmer ml-auto" />
                </div>
              ))}
            </div>
          ) : data.fleetByCompany.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-[var(--text-secondary)]">
              <Inbox className="h-8 w-8 mb-2 opacity-40" />
              <p className="text-sm font-medium">No fleet data yet</p>
              <p className="text-xs mt-1 opacity-60">
                Fleet data will appear when vehicles are registered
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-[var(--border)]">
                    <th className="text-left py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Company
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Vehicles
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Maintenance
                    </th>
                    <th className="text-right py-3 px-2 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">
                      Fuel Spend
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.fleetByCompany.map((company) => (
                    <tr
                      key={company.company_id}
                      className="border-b border-[var(--border)] last:border-0 hover:bg-[var(--bg-elevated)] transition-colors"
                    >
                      <td className="py-3 px-2">
                        <div className="flex items-center gap-2">
                          <Building2 className="h-4 w-4 text-[var(--text-secondary)]" />
                          <span className="text-sm font-medium text-[var(--text-primary)]">
                            {company.company_name}
                          </span>
                        </div>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatNumber(company.vehicle_count)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm text-[var(--text-secondary)]">
                          {formatNumber(company.maintenance_count)}
                        </span>
                      </td>
                      <td className="py-3 px-2 text-right">
                        <span className="text-sm font-semibold text-[var(--text-primary)]">
                          {formatCurrency(company.fuel_spend)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
