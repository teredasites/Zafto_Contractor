'use client';

import { useState, useEffect, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import {
  DollarSign,
  MapPin,
  RefreshCw,
  Database,
  TrendingUp,
  AlertCircle,
  CheckCircle2,
  Search,
} from 'lucide-react';

interface CoverageStats {
  totalItems: number;
  pricedItems: number;
  coveragePct: number;
  regions: number;
  latestDate: string | null;
  msaCoverage: MsaCoverage[];
}

interface MsaCoverage {
  cbsa_code: string;
  name: string;
  cost_index: number;
  itemCount: number;
}

interface PricingRow {
  id: string;
  item_id: string;
  region_code: string;
  labor_rate: number;
  material_cost: number;
  equipment_cost: number;
  effective_date: string;
  source: string;
  confidence: string;
  sample_count: number;
  item?: { zafto_code: string; description: string; trade: string; unit_code: string };
}

export default function PricingEnginePage() {
  const [stats, setStats] = useState<CoverageStats | null>(null);
  const [pricing, setPricing] = useState<PricingRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [ingesting, setIngesting] = useState<string | null>(null);
  const [selectedRegion, setSelectedRegion] = useState('NATIONAL');
  const [searchTerm, setSearchTerm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [lookupZip, setLookupZip] = useState('');
  const [lookupResult, setLookupResult] = useState<{ region: { cbsa_code: string; region_name: string; cost_index: number } } | null>(null);

  const supabase = getSupabase();

  const fetchStats = useCallback(async () => {
    try {
      const { data: session } = await supabase.auth.getSession();
      const token = session?.session?.access_token;
      if (!token) return;

      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/pricing-ingest?action=stats`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
          },
        }
      );
      const data = await resp.json();
      if (data.error) throw new Error(data.error);
      setStats(data);
    } catch (e) {
      setError((e as Error).message);
    }
  }, [supabase]);

  const fetchPricing = useCallback(async () => {
    try {
      let query = supabase
        .from('estimate_pricing')
        .select('*, item:estimate_items(zafto_code, description, trade, unit_code)')
        .eq('region_code', selectedRegion)
        .is('company_id', null)
        .order('created_at', { ascending: false })
        .limit(100);

      if (searchTerm) {
        query = query.ilike('item.description', `%${searchTerm}%`);
      }

      const { data, error: queryError } = await query;
      if (queryError) throw queryError;
      setPricing((data || []) as unknown as PricingRow[]);
    } catch (e) {
      setError((e as Error).message);
    }
  }, [supabase, selectedRegion, searchTerm]);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      await Promise.all([fetchStats(), fetchPricing()]);
      setLoading(false);
    };
    load();
  }, [fetchStats, fetchPricing]);

  const triggerIngest = async (action: string) => {
    setIngesting(action);
    setError(null);
    try {
      const { data: session } = await supabase.auth.getSession();
      const token = session?.session?.access_token;
      if (!token) throw new Error('Not authenticated');

      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/pricing-ingest`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ action }),
        }
      );
      const data = await resp.json();
      if (data.error) throw new Error(data.error);
      await fetchStats();
      await fetchPricing();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setIngesting(null);
    }
  };

  const lookupZipCode = async () => {
    if (!lookupZip || lookupZip.length < 3) return;
    try {
      const { data: session } = await supabase.auth.getSession();
      const token = session?.session?.access_token;
      if (!token) return;

      const resp = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/pricing-ingest?action=lookup&zip=${lookupZip}&item_id=00000000-0000-0000-0000-000000000000`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
          },
        }
      );
      const data = await resp.json();
      setLookupResult(data);
    } catch {
      // ignore
    }
  };

  const confidenceColor = (c: string) => {
    switch (c) {
      case 'verified': return 'text-emerald-600 bg-emerald-50';
      case 'high': return 'text-blue-600 bg-blue-50';
      case 'medium': return 'text-amber-600 bg-amber-50';
      case 'low': return 'text-red-600 bg-red-50';
      default: return 'text-gray-600 bg-gray-50';
    }
  };

  if (loading) {
    return (
      <div className="p-8 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 max-w-7xl">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Pricing Engine</h1>
          <p className="text-sm text-gray-500 mt-1">
            BLS labor rates + FEMA equipment rates + regional pricing coverage
          </p>
        </div>
        <button
          onClick={() => { fetchStats(); fetchPricing(); }}
          className="flex items-center gap-2 px-3 py-2 text-sm border rounded-lg hover:bg-gray-50"
        >
          <RefreshCw size={14} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
          <AlertCircle size={16} />
          {error}
          <button onClick={() => setError(null)} className="ml-auto text-red-500 hover:text-red-700">Dismiss</button>
        </div>
      )}

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <div className="bg-white border rounded-xl p-4">
          <div className="flex items-center gap-2 text-gray-500 text-xs font-medium mb-2">
            <Database size={14} />
            TOTAL ITEMS
          </div>
          <div className="text-2xl font-bold">{stats?.totalItems || 0}</div>
        </div>
        <div className="bg-white border rounded-xl p-4">
          <div className="flex items-center gap-2 text-gray-500 text-xs font-medium mb-2">
            <DollarSign size={14} />
            PRICED (NATIONAL)
          </div>
          <div className="text-2xl font-bold">{stats?.pricedItems || 0}</div>
          <div className="text-xs text-gray-400">{stats?.coveragePct || 0}% coverage</div>
        </div>
        <div className="bg-white border rounded-xl p-4">
          <div className="flex items-center gap-2 text-gray-500 text-xs font-medium mb-2">
            <MapPin size={14} />
            REGIONS
          </div>
          <div className="text-2xl font-bold">{stats?.regions || 0}</div>
        </div>
        <div className="bg-white border rounded-xl p-4">
          <div className="flex items-center gap-2 text-gray-500 text-xs font-medium mb-2">
            <TrendingUp size={14} />
            DATA FRESHNESS
          </div>
          <div className="text-lg font-bold">{stats?.latestDate || 'No data'}</div>
        </div>
        <div className="bg-white border rounded-xl p-4">
          <div className="flex items-center gap-2 text-gray-500 text-xs font-medium mb-2">
            <CheckCircle2 size={14} />
            MSA COVERAGE
          </div>
          <div className="text-2xl font-bold">{stats?.msaCoverage?.length || 0}</div>
          <div className="text-xs text-gray-400">metro areas</div>
        </div>
      </div>

      {/* Ingestion Controls */}
      <div className="bg-white border rounded-xl p-4">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Data Ingestion</h3>
        <div className="flex items-center gap-3 flex-wrap">
          <button
            onClick={() => triggerIngest('ingest-bls')}
            disabled={!!ingesting}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {ingesting === 'ingest-bls' ? <RefreshCw size={14} className="animate-spin" /> : <Database size={14} />}
            Fetch BLS Labor Rates
          </button>
          <button
            onClick={() => triggerIngest('ingest-ppi')}
            disabled={!!ingesting}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50"
          >
            {ingesting === 'ingest-ppi' ? <RefreshCw size={14} className="animate-spin" /> : <TrendingUp size={14} />}
            Fetch PPI Material Indices
          </button>
          <div className="flex items-center gap-2 ml-4 border-l pl-4">
            <input
              type="text"
              value={lookupZip}
              onChange={(e) => setLookupZip(e.target.value.replace(/\D/g, '').slice(0, 5))}
              placeholder="ZIP code"
              className="w-24 px-3 py-2 text-sm border rounded-lg"
            />
            <button
              onClick={lookupZipCode}
              className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium border rounded-lg hover:bg-gray-50"
            >
              <MapPin size={14} />
              Lookup MSA
            </button>
            {lookupResult?.region && (
              <span className="text-sm text-gray-600">
                {lookupResult.region.region_name} ({lookupResult.region.cbsa_code}) — {lookupResult.region.cost_index}x
              </span>
            )}
          </div>
        </div>
      </div>

      {/* MSA Coverage Table */}
      <div className="bg-white border rounded-xl p-4">
        <h3 className="text-sm font-semibold text-gray-700 mb-3">MSA Coverage</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-gray-500">
                <th className="pb-2 pr-4">CBSA</th>
                <th className="pb-2 pr-4">Metro Area</th>
                <th className="pb-2 pr-4">Cost Index</th>
                <th className="pb-2 pr-4">Items Priced</th>
                <th className="pb-2">Status</th>
              </tr>
            </thead>
            <tbody>
              {stats?.msaCoverage?.map((msa) => (
                <tr key={msa.cbsa_code} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="py-2 pr-4 font-mono text-xs">{msa.cbsa_code}</td>
                  <td className="py-2 pr-4">{msa.name}</td>
                  <td className="py-2 pr-4">{msa.cost_index}x</td>
                  <td className="py-2 pr-4">{msa.itemCount}</td>
                  <td className="py-2">
                    {msa.itemCount > 0 ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-emerald-50 text-emerald-700 rounded-full text-xs font-medium">
                        <CheckCircle2 size={12} /> Active
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-500 rounded-full text-xs font-medium">
                        No data
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pricing Browser */}
      <div className="bg-white border rounded-xl p-4">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-semibold text-gray-700">Pricing Browser</h3>
          <div className="flex items-center gap-2">
            <select
              value={selectedRegion}
              onChange={(e) => setSelectedRegion(e.target.value)}
              className="text-sm border rounded-lg px-3 py-1.5"
            >
              <option value="NATIONAL">National Average</option>
              {stats?.msaCoverage?.map((msa) => (
                <option key={msa.cbsa_code} value={msa.cbsa_code}>
                  {msa.name} ({msa.cost_index}x)
                </option>
              ))}
            </select>
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search items..."
                className="text-sm border rounded-lg pl-9 pr-3 py-1.5 w-48"
              />
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-gray-500 text-xs">
                <th className="pb-2 pr-3">CODE</th>
                <th className="pb-2 pr-3">DESCRIPTION</th>
                <th className="pb-2 pr-3">TRADE</th>
                <th className="pb-2 pr-3">UNIT</th>
                <th className="pb-2 pr-3 text-right">LABOR</th>
                <th className="pb-2 pr-3 text-right">MATERIAL</th>
                <th className="pb-2 pr-3 text-right">EQUIP</th>
                <th className="pb-2 pr-3 text-right">TOTAL</th>
                <th className="pb-2 pr-3">SOURCE</th>
                <th className="pb-2">CONFIDENCE</th>
              </tr>
            </thead>
            <tbody>
              {pricing.map((row) => {
                const total = (row.labor_rate || 0) + (row.material_cost || 0) + (row.equipment_cost || 0);
                return (
                  <tr key={row.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="py-2 pr-3 font-mono text-xs text-blue-600">{row.item?.zafto_code}</td>
                    <td className="py-2 pr-3 max-w-xs truncate">{row.item?.description}</td>
                    <td className="py-2 pr-3 font-mono text-xs">{row.item?.trade}</td>
                    <td className="py-2 pr-3 text-xs">{row.item?.unit_code}</td>
                    <td className="py-2 pr-3 text-right font-mono">${row.labor_rate?.toFixed(2)}</td>
                    <td className="py-2 pr-3 text-right font-mono">${row.material_cost?.toFixed(2)}</td>
                    <td className="py-2 pr-3 text-right font-mono">${row.equipment_cost?.toFixed(2)}</td>
                    <td className="py-2 pr-3 text-right font-mono font-medium">${total.toFixed(2)}</td>
                    <td className="py-2 pr-3 text-xs uppercase">{row.source}</td>
                    <td className="py-2">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${confidenceColor(row.confidence)}`}>
                        {row.confidence}
                      </span>
                    </td>
                  </tr>
                );
              })}
              {pricing.length === 0 && (
                <tr>
                  <td colSpan={10} className="py-8 text-center text-gray-400">
                    No pricing data for this region
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
