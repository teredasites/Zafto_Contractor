'use client';

import { useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import {
  ArrowLeft,
  Brain,
  Target,
  TrendingUp,
  AlertTriangle,
  Lightbulb,
  DollarSign,
  RefreshCw,
  Sparkles,
  CheckCircle2,
  ShieldAlert,
  BarChart3,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatCurrency, cn } from '@/lib/utils';
import { useBid } from '@/lib/hooks/use-bids';
import {
  useBidOptimizer,
  type ScopeSuggestion,
  type PricingAdjustment,
  type RiskFactor,
} from '@/lib/hooks/use-bid-optimizer';
import { useTranslation } from '@/lib/translations';

// ==================== WIN PROBABILITY CIRCLE ====================

function WinProbabilityCircle({ probability }: { probability: number }) {
  const { t } = useTranslation();
  const radius = 70;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (probability / 100) * circumference;

  const getColor = (p: number) => {
    if (p < 30) return { stroke: '#ef4444', bg: 'bg-red-500/10', text: 'text-red-500', label: 'Low' };
    if (p < 60) return { stroke: '#f59e0b', bg: 'bg-amber-500/10', text: 'text-amber-500', label: 'Moderate' };
    return { stroke: '#22c55e', bg: 'bg-emerald-500/10', text: 'text-emerald-500', label: 'Strong' };
  };

  const color = getColor(probability);

  return (
    <div className="flex flex-col items-center gap-3">
      <div className="relative">
        <svg width="180" height="180" className="-rotate-90">
          <circle
            cx="90"
            cy="90"
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth="10"
            className="text-[var(--border-main)]"
          />
          <circle
            cx="90"
            cy="90"
            r={radius}
            fill="none"
            stroke={color.stroke}
            strokeWidth="10"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            strokeLinecap="round"
            className="transition-all duration-1000 ease-out"
          />
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className={cn('text-4xl font-bold', color.text)}>
            {probability}%
          </span>
          <span className="text-sm text-muted mt-0.5">{t('marketplace.winRate')}</span>
        </div>
      </div>
      <Badge variant={probability < 30 ? 'error' : probability < 60 ? 'warning' : 'success'} size="md">
        {color.label} Probability
      </Badge>
    </div>
  );
}

// ==================== PRICING ANALYSIS BAR ====================

function PricingAnalysisBar({
  currentPrice,
  low,
  optimal,
  high,
}: {
  currentPrice: number;
  low: number;
  optimal: number;
  high: number;
}) {
  // Calculate positions as percentages of the range
  const rangeMin = Math.min(low, currentPrice) * 0.9;
  const rangeMax = Math.max(high, currentPrice) * 1.1;
  const range = rangeMax - rangeMin;

  const getPosition = (value: number) => ((value - rangeMin) / range) * 100;

  const lowPos = getPosition(low);
  const optimalPos = getPosition(optimal);
  const highPos = getPosition(high);
  const currentPos = getPosition(currentPrice);

  return (
    <div className="space-y-6">
      {/* Price labels */}
      <div className="grid grid-cols-4 gap-4">
        <PriceLabel
          label="Current"
          amount={currentPrice}
          color="text-blue-500"
          bgColor="bg-blue-500/10"
          icon={<DollarSign size={14} />}
        />
        <PriceLabel
          label="Low"
          amount={low}
          color="text-amber-500"
          bgColor="bg-amber-500/10"
          icon={<TrendingUp size={14} />}
        />
        <PriceLabel
          label="Optimal"
          amount={optimal}
          color="text-emerald-500"
          bgColor="bg-emerald-500/10"
          icon={<Target size={14} />}
        />
        <PriceLabel
          label="High"
          amount={high}
          color="text-purple-500"
          bgColor="bg-purple-500/10"
          icon={<BarChart3 size={14} />}
        />
      </div>

      {/* Visual bar */}
      <div className="relative h-12 mt-4">
        {/* Track background */}
        <div className="absolute inset-x-0 top-5 h-2 bg-[var(--bg-secondary)] rounded-full" />

        {/* Recommended range */}
        <div
          className="absolute top-5 h-2 bg-emerald-500/20 rounded-full"
          style={{
            left: `${lowPos}%`,
            width: `${highPos - lowPos}%`,
          }}
        />

        {/* Optimal zone */}
        <div
          className="absolute top-4 h-4 bg-emerald-500/30 rounded-full"
          style={{
            left: `${Math.max(optimalPos - 2, 0)}%`,
            width: '4%',
          }}
        />

        {/* Low marker */}
        <div
          className="absolute top-3 w-0.5 h-6 bg-amber-500"
          style={{ left: `${lowPos}%` }}
        />

        {/* Optimal marker */}
        <div
          className="absolute top-2 w-1 h-8 bg-emerald-500 rounded-full"
          style={{ left: `${optimalPos}%` }}
        />

        {/* High marker */}
        <div
          className="absolute top-3 w-0.5 h-6 bg-purple-500"
          style={{ left: `${highPos}%` }}
        />

        {/* Current price indicator */}
        <div
          className="absolute -top-1 flex flex-col items-center"
          style={{ left: `${currentPos}%`, transform: 'translateX(-50%)' }}
        >
          <div className="w-4 h-4 rounded-full bg-blue-500 border-2 border-[var(--bg-surface)] shadow-md" />
        </div>
      </div>

      {/* Delta from optimal */}
      {currentPrice > 0 && optimal > 0 && (
        <div className="flex items-center gap-2 text-sm">
          <span className="text-muted">Difference from optimal:</span>
          <span className={cn(
            'font-medium',
            currentPrice > optimal ? 'text-amber-500' : currentPrice < optimal ? 'text-blue-500' : 'text-emerald-500'
          )}>
            {currentPrice > optimal
              ? `${formatCurrency(currentPrice - optimal)} above`
              : currentPrice < optimal
                ? `${formatCurrency(optimal - currentPrice)} below`
                : 'At optimal price'}
          </span>
        </div>
      )}
    </div>
  );
}

function PriceLabel({
  label,
  amount,
  color,
  bgColor,
  icon,
}: {
  label: string;
  amount: number;
  color: string;
  bgColor: string;
  icon: React.ReactNode;
}) {
  return (
    <div className={cn('p-3 rounded-lg', bgColor)}>
      <div className={cn('flex items-center gap-1.5 text-xs font-medium mb-1', color)}>
        {icon}
        {label}
      </div>
      <div className="text-sm font-semibold text-main">
        {formatCurrency(amount)}
      </div>
    </div>
  );
}

// ==================== SCOPE SUGGESTION CARD ====================

function ScopeSuggestionCard({ suggestion }: { suggestion: ScopeSuggestion }) {
  const priorityConfig = {
    high: { variant: 'error' as const, label: 'High Priority' },
    medium: { variant: 'warning' as const, label: 'Medium' },
    low: { variant: 'default' as const, label: 'Low' },
  };

  const config = priorityConfig[suggestion.priority];

  return (
    <div className="p-4 rounded-lg border border-main bg-surface hover:border-[var(--accent)]/30 transition-colors">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1.5">
            <Lightbulb size={16} className="text-amber-500 shrink-0" />
            <h4 className="text-sm font-semibold text-main">{suggestion.title}</h4>
          </div>
          <p className="text-sm text-muted leading-relaxed">{suggestion.description}</p>
          <p className="text-xs text-muted mt-2 italic">{suggestion.rationale}</p>
        </div>
        <div className="flex flex-col items-end gap-2 shrink-0">
          <Badge variant={config.variant} size="sm">
            {config.label}
          </Badge>
          <span className="text-sm font-semibold text-emerald-500">
            +{formatCurrency(suggestion.estimated_value)}
          </span>
        </div>
      </div>
    </div>
  );
}

// ==================== PRICING ADJUSTMENT ROW ====================

function PricingAdjustmentRow({ adjustment }: { adjustment: PricingAdjustment }) {
  const delta = adjustment.suggested_price - adjustment.current_price;
  const pctChange = adjustment.current_price > 0
    ? Math.round((delta / adjustment.current_price) * 100)
    : 0;

  return (
    <div className="flex items-center gap-4 p-3 rounded-lg bg-secondary/50">
      <div className="flex-1">
        <span className="text-sm font-medium text-main">{adjustment.item}</span>
        <p className="text-xs text-muted mt-0.5">{adjustment.reason}</p>
      </div>
      <div className="text-right shrink-0">
        <div className="flex items-center gap-2">
          <span className="text-sm text-muted line-through">
            {formatCurrency(adjustment.current_price)}
          </span>
          <span className="text-sm font-semibold text-main">
            {formatCurrency(adjustment.suggested_price)}
          </span>
        </div>
        <span className={cn(
          'text-xs font-medium',
          delta > 0 ? 'text-emerald-500' : delta < 0 ? 'text-red-500' : 'text-muted'
        )}>
          {delta > 0 ? '+' : ''}{pctChange}%
        </span>
      </div>
    </div>
  );
}

// ==================== RISK FACTOR CARD ====================

function RiskFactorCard({ risk }: { risk: RiskFactor }) {
  const severityConfig = {
    high: { variant: 'error' as const, icon: <ShieldAlert size={16} className="text-red-500" /> },
    medium: { variant: 'warning' as const, icon: <AlertTriangle size={16} className="text-amber-500" /> },
    low: { variant: 'default' as const, icon: <AlertTriangle size={16} className="text-muted" /> },
  };

  const config = severityConfig[risk.severity];

  return (
    <div className="p-4 rounded-lg border border-main bg-surface">
      <div className="flex items-start gap-3">
        <div className="mt-0.5 shrink-0">{config.icon}</div>
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-sm font-semibold text-main">{risk.category}</span>
            <Badge variant={config.variant} size="sm">
              {risk.severity}
            </Badge>
          </div>
          <p className="text-sm text-muted leading-relaxed">{risk.description}</p>
          <div className="flex items-start gap-1.5 mt-2 text-xs text-muted">
            <CheckCircle2 size={12} className="text-emerald-500 mt-0.5 shrink-0" />
            <span>{risk.mitigation}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// ==================== MAIN PAGE ====================

export default function BidOptimizePage() {
  const { t } = useTranslation();
  const router = useRouter();
  const params = useParams();
  const bidId = params.id as string;

  const { bid, loading: bidLoading } = useBid(bidId);
  const { optimize, result, loading, error } = useBidOptimizer();

  // Auto-optimize on mount
  useEffect(() => {
    if (bidId && !result && !loading) {
      optimize(bidId);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bidId]);

  if (bidLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.push(`/dashboard/bids/${bidId}`)}
          >
            <ArrowLeft size={20} />
          </Button>
          <div>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-2">
                <Brain size={24} className="text-[var(--accent)]" />
                <h1 className="text-2xl font-bold text-main">{t('bidsOptimize.title')}</h1>
              </div>
              {bid && (
                <Badge variant="secondary" size="md">{bid.bidNumber}</Badge>
              )}
            </div>
            <div className="flex items-center gap-1.5 mt-1">
              <Sparkles size={14} className="text-purple-500" />
              <span className="text-sm text-muted">{t('common.poweredByZ')}</span>
            </div>
          </div>
        </div>
        <Button
          variant="secondary"
          onClick={() => optimize(bidId)}
          loading={loading}
        >
          <RefreshCw size={16} />
          Regenerate Analysis
        </Button>
      </div>

      {/* Loading State */}
      {loading && (
        <Card>
          <CardContent className="py-16">
            <div className="flex flex-col items-center gap-4">
              <div className="relative">
                <div className="animate-spin rounded-full h-16 w-16 border-4 border-[var(--accent)]/20 border-t-[var(--accent)]" />
                <Brain size={24} className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-[var(--accent)]" />
              </div>
              <div className="text-center">
                <h3 className="text-lg font-semibold text-main">{t('bidsOptimize.analyzingBid')}</h3>
                <p className="text-sm text-muted mt-1">
                  Reviewing historical data, pricing patterns, and competitive factors...
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Error State */}
      {error && !loading && (
        <Card>
          <CardContent className="py-12">
            <div className="flex flex-col items-center gap-4">
              <ShieldAlert size={48} className="text-red-500" />
              <div className="text-center">
                <h3 className="text-lg font-semibold text-main">{t('bidsOptimize.analysisFailed')}</h3>
                <p className="text-sm text-muted mt-1">{error}</p>
              </div>
              <Button variant="primary" onClick={() => optimize(bidId)}>
                Try Again
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Results */}
      {result && !loading && (
        <div className="space-y-6">
          {/* Top Row: Win Probability + Pricing */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Win Probability */}
            <Card>
              <CardHeader>
                <CardTitle>
                  <div className="flex items-center gap-2">
                    <Target size={16} className="text-[var(--accent)]" />
                    Win Probability
                  </div>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex justify-center py-4">
                  <WinProbabilityCircle probability={result.win_probability} />
                </div>
                {/* Historical context */}
                <div className="grid grid-cols-2 gap-3 mt-6 pt-4 border-t border-main">
                  <div className="text-center">
                    <div className="text-lg font-bold text-main">
                      {result.historical_stats.win_rate}%
                    </div>
                    <div className="text-xs text-muted">{t('bidsOptimize.historicalWinRate')}</div>
                  </div>
                  <div className="text-center">
                    <div className="text-lg font-bold text-main">
                      {result.historical_stats.total_bids}
                    </div>
                    <div className="text-xs text-muted">{t('marketplace.totalBids')}</div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Pricing Analysis */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader>
                  <CardTitle>
                    <div className="flex items-center gap-2">
                      <DollarSign size={16} className="text-[var(--accent)]" />
                      Pricing Analysis
                    </div>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <PricingAnalysisBar
                    currentPrice={bid?.total || 0}
                    low={result.recommended_price_range.low}
                    optimal={result.recommended_price_range.optimal}
                    high={result.recommended_price_range.high}
                  />
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Competitive Analysis */}
          <Card>
            <CardHeader>
              <CardTitle>
                <div className="flex items-center gap-2">
                  <BarChart3 size={16} className="text-[var(--accent)]" />
                  Competitive Analysis
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted leading-relaxed whitespace-pre-wrap">
                {result.competitive_analysis}
              </p>
            </CardContent>
          </Card>

          {/* Scope Suggestions */}
          {result.scope_suggestions.length > 0 && (
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>
                    <div className="flex items-center gap-2">
                      <Lightbulb size={16} className="text-[var(--accent)]" />
                      Scope Suggestions
                    </div>
                  </CardTitle>
                  <Badge variant="purple" size="sm">
                    {result.scope_suggestions.length} suggestions
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {result.scope_suggestions.map((suggestion, i) => (
                    <ScopeSuggestionCard key={i} suggestion={suggestion} />
                  ))}
                </div>
                {/* Total potential value */}
                <div className="flex items-center justify-between mt-4 pt-4 border-t border-main">
                  <span className="text-sm text-muted">{t('bidsOptimize.totalPotentialValueFromSuggestions')}</span>
                  <span className="text-lg font-bold text-emerald-500">
                    +{formatCurrency(
                      result.scope_suggestions.reduce((sum, s) => sum + s.estimated_value, 0)
                    )}
                  </span>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Pricing Adjustments */}
          {result.pricing_adjustments.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle>
                  <div className="flex items-center gap-2">
                    <Zap size={16} className="text-[var(--accent)]" />
                    Pricing Adjustments
                  </div>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {result.pricing_adjustments.map((adjustment, i) => (
                    <PricingAdjustmentRow key={i} adjustment={adjustment} />
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Risk Factors */}
          {result.risk_factors.length > 0 && (
            <Card>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>
                    <div className="flex items-center gap-2">
                      <AlertTriangle size={16} className="text-[var(--accent)]" />
                      Risk Factors
                    </div>
                  </CardTitle>
                  <Badge
                    variant={
                      result.risk_factors.some(r => r.severity === 'high')
                        ? 'error'
                        : result.risk_factors.some(r => r.severity === 'medium')
                          ? 'warning'
                          : 'default'
                    }
                    size="sm"
                  >
                    {result.risk_factors.length} identified
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {result.risk_factors.map((risk, i) => (
                    <RiskFactorCard key={i} risk={risk} />
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Action Buttons */}
          <Card>
            <CardContent className="py-5">
              <div className="flex items-center justify-between">
                <div className="text-sm text-muted">
                  Analysis generated by {result.model} ({result.token_usage.input + result.token_usage.output} tokens)
                </div>
                <div className="flex items-center gap-3">
                  <Button
                    variant="secondary"
                    onClick={() => router.push(`/dashboard/bids/${bidId}`)}
                  >
                    Back to Bid
                  </Button>
                  <Button
                    variant="primary"
                    disabled
                    title="Coming soon"
                  >
                    <CheckCircle2 size={16} />
                    Apply Suggestions
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}
