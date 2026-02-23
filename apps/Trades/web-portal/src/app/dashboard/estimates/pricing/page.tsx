'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { ArrowLeft, Database, BarChart3, Globe, AlertCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

interface CoverageRow {
  categoryCode: string;
  categoryName: string;
  regionCode: string | null;
  entryCount: number;
  avgPrice: number | null;
  minConfidence: string | null;
  maxSources: number;
  lastUpdated: string | null;
}

const CONFIDENCE_COLORS: Record<string, string> = {
  low: 'text-red-400 bg-red-500/10',
  medium: 'text-amber-400 bg-amber-500/10',
  high: 'text-green-400 bg-green-500/10',
  verified: 'text-emerald-400 bg-emerald-500/10',
};

export default function PricingCoveragePage() {
  const { t, formatCurrency, formatDate } = useTranslation();
  const router = useRouter();
  const [rows, setRows] = useState<CoverageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterRegion, setFilterRegion] = useState('');
  const [regions, setRegions] = useState<string[]>([]);

  useEffect(() => {
    async function fetchCoverage() {
      const supabase = getSupabase();

      // Fetch pricing coverage view
      const { data } = await supabase
        .from('v_pricing_coverage')
        .select('*')
        .order('category_code');

      if (data) {
        const mapped: CoverageRow[] = (data as Array<{
          category_code: string;
          category_name: string;
          region_code: string | null;
          entry_count: number;
          avg_price: number | null;
          min_confidence: string | null;
          max_sources: number;
          last_updated: string | null;
        }>).map(r => ({
          categoryCode: r.category_code,
          categoryName: r.category_name,
          regionCode: r.region_code,
          entryCount: Number(r.entry_count || 0),
          avgPrice: r.avg_price !== null ? Number(r.avg_price) : null,
          minConfidence: r.min_confidence,
          maxSources: Number(r.max_sources || 0),
          lastUpdated: r.last_updated,
        }));
        setRows(mapped);

        // Extract unique regions
        const uniqueRegions = [...new Set(mapped.map(r => r.regionCode).filter(Boolean))] as string[];
        setRegions(uniqueRegions.sort());
      }
      setLoading(false);
    }
    fetchCoverage();
  }, []);

  const filtered = rows.filter(r => {
    if (!filterRegion) return true;
    return r.regionCode === filterRegion;
  });

  // Aggregate stats
  const totalCategories = new Set(filtered.map(r => r.categoryCode)).size;
  const totalEntries = filtered.reduce((s, r) => s + r.entryCount, 0);
  const withPricing = filtered.filter(r => r.entryCount > 0).length;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <button onClick={() => router.push('/dashboard/estimates')} className="p-1.5 rounded-lg hover:bg-zinc-800 text-zinc-400">
          <ArrowLeft className="w-4 h-4" />
        </button>
        <div>
          <h1 className="text-xl font-semibold text-zinc-100">{t('estimatesPricing.title')}</h1>
          <p className="text-sm text-zinc-500">Crowd-sourced pricing data by region and trade category</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Categories', value: totalCategories, icon: Database },
          { label: 'Pricing Entries', value: totalEntries, icon: BarChart3 },
          { label: 'With Data', value: withPricing, icon: Globe },
          { label: 'Regions', value: regions.length, icon: Globe },
        ].map(stat => (
          <div key={stat.label} className="bg-zinc-800/40 border border-zinc-700/30 rounded-lg p-4">
            <div className="flex items-center gap-2 text-zinc-500 text-xs mb-1">
              <stat.icon className="w-3.5 h-3.5" />
              {stat.label}
            </div>
            <p className="text-2xl font-semibold text-zinc-100">{stat.value}</p>
          </div>
        ))}
      </div>

      {/* Region filter */}
      <div className="flex items-center gap-3">
        <select
          value={filterRegion}
          onChange={(e) => setFilterRegion(e.target.value)}
          className="px-3 py-1.5 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-sm text-zinc-200"
        >
          <option value="">All regions</option>
          {regions.map(r => <option key={r} value={r}>{r}</option>)}
        </select>
      </div>

      {/* Coverage table */}
      {loading ? (
        <div className="space-y-2">
          {[1, 2, 3, 4, 5].map(i => (
            <div key={i} className="h-12 bg-zinc-800/50 rounded animate-pulse" />
          ))}
        </div>
      ) : (
        <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="text-[10px] uppercase tracking-wider text-zinc-600 border-b border-zinc-800">
                <th className="px-4 py-2.5 text-left">{t('common.category')}</th>
                <th className="px-4 py-2.5 text-left">{t('common.region')}</th>
                <th className="px-4 py-2.5 text-right">Entries</th>
                <th className="px-4 py-2.5 text-right">Avg Price</th>
                <th className="px-4 py-2.5 text-center">{t('common.confidence')}</th>
                <th className="px-4 py-2.5 text-right">{t('recon.sources')}</th>
                <th className="px-4 py-2.5 text-right">{t('common.lastUpdated')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-800/50">
              {filtered.map((row, i) => (
                <tr key={i} className="hover:bg-zinc-800/30 transition-colors">
                  <td className="px-4 py-2.5">
                    <span className="text-xs font-mono text-blue-400">{row.categoryCode}</span>
                    <span className="text-xs text-zinc-400 ml-2">{row.categoryName}</span>
                  </td>
                  <td className="px-4 py-2.5 text-xs text-zinc-400">{row.regionCode || '—'}</td>
                  <td className="px-4 py-2.5 text-xs text-right text-zinc-200">{row.entryCount}</td>
                  <td className="px-4 py-2.5 text-xs text-right text-zinc-200">
                    {row.avgPrice !== null ? formatCurrency(row.avgPrice) : '—'}
                  </td>
                  <td className="px-4 py-2.5 text-center">
                    {row.minConfidence ? (
                      <span className={cn('text-[10px] px-1.5 py-0.5 rounded', CONFIDENCE_COLORS[row.minConfidence] || '')}>
                        {row.minConfidence}
                      </span>
                    ) : '—'}
                  </td>
                  <td className="px-4 py-2.5 text-xs text-right text-zinc-400">{row.maxSources}</td>
                  <td className="px-4 py-2.5 text-xs text-right text-zinc-500">
                    {row.lastUpdated ? formatDate(row.lastUpdated) : '—'}
                  </td>
                </tr>
              ))}
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-zinc-500 text-sm">
                    <AlertCircle className="w-8 h-8 mx-auto mb-2 opacity-30" />
                    No pricing data yet. Data populates as invoices are finalized.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
