'use client';

// J6: Smart Pricing Analytics — close rate by price point, revenue impact, suggestion acceptance

import { useState, useEffect, useCallback, useMemo } from 'react';
import {
  BarChart3,
  DollarSign,
  TrendingUp,
  Target,
  CheckCircle,
  XCircle,
  Percent,
} from 'lucide-react';
import { createClient } from '@/lib/supabase';
import { useTranslation } from '@/lib/translations';

const supabase = createClient();

interface PricingSuggestion {
  id: string;
  company_id: string;
  estimate_id: string | null;
  job_id: string | null;
  base_price: number;
  suggested_price: number;
  factors_applied: Array<{
    rule_type: string;
    label: string;
    adjustment_pct: number;
    amount: number;
  }>;
  final_price: number | null;
  accepted: boolean | null;
  job_won: boolean | null;
  created_at: string;
}

export default function PricingAnalyticsPage() {
  const { t, formatDate } = useTranslation();
  const [suggestions, setSuggestions] = useState<PricingSuggestion[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    const { data } = await supabase
      .from('pricing_suggestions')
      .select('*')
      .is('deleted_at', null)
      .order('created_at', { ascending: false });
    setSuggestions(data || []);
    setLoading(false);
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  // ── Computed Stats ──

  const stats = useMemo(() => {
    const total = suggestions.length;
    const withDecision = suggestions.filter(s => s.accepted !== null);
    const accepted = withDecision.filter(s => s.accepted === true);
    const declined = withDecision.filter(s => s.accepted === false);
    const withOutcome = suggestions.filter(s => s.job_won !== null);
    const jobsWon = withOutcome.filter(s => s.job_won === true);

    const acceptRate = withDecision.length > 0
      ? (accepted.length / withDecision.length) * 100
      : 0;

    const closeRate = withOutcome.length > 0
      ? (jobsWon.length / withOutcome.length) * 100
      : 0;

    // Revenue impact: difference between suggested and base for accepted suggestions
    const revenueImpact = accepted.reduce((sum, s) => {
      const finalOrSuggested = s.final_price || s.suggested_price;
      return sum + (finalOrSuggested - s.base_price);
    }, 0);

    // Average adjustment
    const avgAdjustmentPct = total > 0
      ? suggestions.reduce((sum, s) => {
          const pct = s.base_price > 0 ? ((s.suggested_price - s.base_price) / s.base_price) * 100 : 0;
          return sum + pct;
        }, 0) / total
      : 0;

    return {
      total,
      accepted: accepted.length,
      declined: declined.length,
      acceptRate,
      closeRate,
      jobsWon: jobsWon.length,
      revenueImpact,
      avgAdjustmentPct,
    };
  }, [suggestions]);

  // ── Factor Frequency Analysis ──

  const factorBreakdown = useMemo(() => {
    const factorCounts: Record<string, { count: number; totalAmount: number; label: string }> = {};

    for (const s of suggestions) {
      for (const f of s.factors_applied) {
        if (!factorCounts[f.rule_type]) {
          factorCounts[f.rule_type] = { count: 0, totalAmount: 0, label: f.label };
        }
        factorCounts[f.rule_type].count++;
        factorCounts[f.rule_type].totalAmount += f.amount;
      }
    }

    return Object.entries(factorCounts)
      .map(([type, data]) => ({
        type,
        label: data.label,
        count: data.count,
        avgAmount: data.count > 0 ? data.totalAmount / data.count : 0,
        totalAmount: data.totalAmount,
      }))
      .sort((a, b) => b.count - a.count);
  }, [suggestions]);

  // ── Close Rate by Price Tier ──

  const closeRateByTier = useMemo(() => {
    const tiers = [
      { label: '<$500', min: 0, max: 500 },
      { label: '$500-$1K', min: 500, max: 1000 },
      { label: '$1K-$5K', min: 1000, max: 5000 },
      { label: '$5K-$10K', min: 5000, max: 10000 },
      { label: '$10K+', min: 10000, max: Infinity },
    ];

    return tiers.map(tier => {
      const inTier = suggestions.filter(s => {
        const price = s.final_price || s.suggested_price;
        return price >= tier.min && price < tier.max;
      });
      const withOutcome = inTier.filter(s => s.job_won !== null);
      const won = withOutcome.filter(s => s.job_won === true);

      return {
        label: tier.label,
        total: inTier.length,
        withOutcome: withOutcome.length,
        won: won.length,
        closeRate: withOutcome.length > 0 ? (won.length / withOutcome.length) * 100 : 0,
      };
    }).filter(t => t.total > 0);
  }, [suggestions]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin h-8 w-8 border-2 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="mb-6">
        <h1 className="text-2xl font-semibold text-white">{t('pricingAnalytics.title')}</h1>
        <p className="text-sm text-zinc-400 mt-1">
          Track how smart pricing impacts close rates and revenue
        </p>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard icon={BarChart3} label="Suggestions Made" value={stats.total.toString()} />
        <StatCard
          icon={Percent}
          label="Accept Rate"
          value={`${stats.acceptRate.toFixed(0)}%`}
          valueColor={stats.acceptRate >= 50 ? 'text-emerald-400' : 'text-amber-400'}
        />
        <StatCard
          icon={Target}
          label="Close Rate"
          value={`${stats.closeRate.toFixed(0)}%`}
          valueColor={stats.closeRate >= 30 ? 'text-emerald-400' : 'text-amber-400'}
        />
        <StatCard
          icon={DollarSign}
          label="Revenue Impact"
          value={fmtMoney(stats.revenueImpact)}
          valueColor={stats.revenueImpact >= 0 ? 'text-emerald-400' : 'text-red-400'}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Close Rate by Price Tier */}
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
          <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('pricingAnalytics.closeRateByPriceTier')}</h3>
          {closeRateByTier.length === 0 ? (
            <p className="text-zinc-600 text-sm">{t('pricingAnalytics.noDataYet')}</p>
          ) : (
            <div className="space-y-3">
              {closeRateByTier.map((tier) => (
                <div key={tier.label} className="flex items-center gap-3">
                  <span className="text-xs text-zinc-500 w-16">{tier.label}</span>
                  <div className="flex-1 h-6 bg-zinc-700/30 rounded relative">
                    <div
                      className={`h-full rounded ${
                        tier.closeRate >= 40 ? 'bg-emerald-500/40' : tier.closeRate >= 20 ? 'bg-amber-500/40' : 'bg-red-500/40'
                      }`}
                      style={{ width: `${Math.min(tier.closeRate, 100)}%` }}
                    />
                    <span className="absolute inset-y-0 left-2 flex items-center text-xs text-zinc-300">
                      {tier.closeRate.toFixed(0)}%
                    </span>
                  </div>
                  <span className="text-xs text-zinc-600 w-20 text-right">
                    {tier.won}/{tier.withOutcome} won
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Factor Breakdown */}
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
          <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('pricingAnalytics.mostAppliedPricingFactors')}</h3>
          {factorBreakdown.length === 0 ? (
            <p className="text-zinc-600 text-sm">{t('pricingAnalytics.noPricingFactorsAppliedYet')}</p>
          ) : (
            <div className="space-y-3">
              {factorBreakdown.map((f) => (
                <div key={f.type} className="flex items-center justify-between py-2 border-b border-zinc-700/30 last:border-0">
                  <div>
                    <p className="text-sm text-zinc-200">{f.label}</p>
                    <p className="text-xs text-zinc-500">{f.count} times applied</p>
                  </div>
                  <div className="text-right">
                    <p className={`text-sm font-medium ${f.avgAmount >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                      {f.avgAmount >= 0 ? '+' : ''}{fmtMoney(f.avgAmount)} avg
                    </p>
                    <p className="text-xs text-zinc-500">
                      {fmtMoney(f.totalAmount)} total
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Acceptance/Decline */}
      <div className="mt-6 bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-5">
        <h3 className="text-sm font-medium text-zinc-300 mb-4">{t('pricingAnalytics.suggestionOutcomes')}</h3>
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2">
            <CheckCircle className="h-5 w-5 text-emerald-400" />
            <div>
              <p className="text-lg font-bold text-emerald-400">{stats.accepted}</p>
              <p className="text-xs text-zinc-500">{t('common.accepted')}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <XCircle className="h-5 w-5 text-red-400" />
            <div>
              <p className="text-lg font-bold text-red-400">{stats.declined}</p>
              <p className="text-xs text-zinc-500">{t('pricingAnalytics.overridden')}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Target className="h-5 w-5 text-blue-400" />
            <div>
              <p className="text-lg font-bold text-blue-400">{stats.jobsWon}</p>
              <p className="text-xs text-zinc-500">{t('pricingAnalytics.jobsWon')}</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-zinc-400" />
            <div>
              <p className="text-lg font-bold text-zinc-300">{stats.avgAdjustmentPct.toFixed(1)}%</p>
              <p className="text-xs text-zinc-500">{t('pricingAnalytics.avgAdjustment')}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Suggestions */}
      {suggestions.length > 0 && (
        <div className="mt-6 bg-zinc-800/50 border border-zinc-700/50 rounded-xl">
          <div className="p-4 border-b border-zinc-700/50">
            <h3 className="text-sm font-medium text-zinc-300">{t('pricingAnalytics.recentSuggestions')}</h3>
          </div>
          <div className="divide-y divide-zinc-700/30">
            {suggestions.slice(0, 20).map((s) => {
              const adjustPct = s.base_price > 0
                ? (((s.suggested_price - s.base_price) / s.base_price) * 100).toFixed(1)
                : '0';

              return (
                <div key={s.id} className="flex items-center justify-between px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className={`w-2 h-2 rounded-full ${
                      s.accepted === true ? 'bg-emerald-400' :
                      s.accepted === false ? 'bg-red-400' :
                      'bg-zinc-600'
                    }`} />
                    <div>
                      <p className="text-sm text-zinc-300">
                        {fmtMoney(s.base_price)} → {fmtMoney(s.suggested_price)}
                        <span className={`ml-2 text-xs ${Number(adjustPct) >= 0 ? 'text-emerald-400' : 'text-red-400'}`}>
                          ({Number(adjustPct) >= 0 ? '+' : ''}{adjustPct}%)
                        </span>
                      </p>
                      <p className="text-xs text-zinc-500">
                        {s.factors_applied.map(f => f.label).join(', ') || 'No factors'}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-zinc-500">
                      {formatDate(s.created_at)}
                    </p>
                    {s.job_won !== null && (
                      <p className={`text-xs ${s.job_won ? 'text-emerald-400' : 'text-red-400'}`}>
                        {s.job_won ? 'Won' : 'Lost'}
                      </p>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

// ── Components ──

function StatCard({
  icon: Icon,
  label,
  value,
  valueColor = 'text-white',
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  value: string;
  valueColor?: string;
}) {
  return (
    <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-4">
      <Icon className="h-5 w-5 text-zinc-500 mb-2" />
      <p className={`text-xl font-bold ${valueColor}`}>{value}</p>
      <p className="text-xs text-zinc-500 mt-1">{label}</p>
    </div>
  );
}

function fmtMoney(v: number): string {
  if (Math.abs(v) >= 1000000) return `$${(v / 1000000).toFixed(1)}M`;
  if (Math.abs(v) >= 1000) return `$${(v / 1000).toFixed(1)}K`;
  return `$${v.toFixed(0)}`;
}
