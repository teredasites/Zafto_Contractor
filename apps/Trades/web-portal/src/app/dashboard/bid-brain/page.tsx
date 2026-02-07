'use client';

import { useState } from 'react';
import {
  Brain,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Target,
  BarChart3,
  PieChart,
  ArrowUpRight,
  ArrowDownRight,
  AlertTriangle,
  CheckCircle,
  ChevronRight,
  Lightbulb,
  MapPin,
  Calendar,
  User,
  Briefcase,
  Layers,
  Zap,
  Eye,
  Filter,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';

interface BidInsight {
  id: string;
  type: 'win_pattern' | 'loss_pattern' | 'pricing' | 'timing' | 'opportunity';
  title: string;
  description: string;
  impact: 'high' | 'medium' | 'low';
  metric: string;
  metricLabel: string;
  recommendation: string;
  confidence: number;
  dataPoints: number;
}

interface TradePerformance {
  trade: string;
  totalBids: number;
  won: number;
  lost: number;
  ghosted: number;
  winRate: number;
  avgMargin: number;
  avgDealSize: number;
  avgDaysToClose: number;
  trend: 'up' | 'down' | 'flat';
}

interface PricingHeatmapEntry {
  zipCode: string;
  area: string;
  avgBid: number;
  winRate: number;
  margin: number;
  volume: number;
}

const mockInsights: BidInsight[] = [
  {
    id: 'i1', type: 'win_pattern', title: 'Good/Better/Best triples close rate',
    description: 'Bids with 3-tier pricing close at 62% vs 21% for single-price bids. Customers choose the middle option 58% of the time.',
    impact: 'high', metric: '62%', metricLabel: 'Close rate with tiers', recommendation: 'Always include Good/Better/Best options. Your middle tier is your real price.',
    confidence: 0.94, dataPoints: 187,
  },
  {
    id: 'i2', type: 'loss_pattern', title: 'Bids over $12K have a drop-off cliff',
    description: 'Your close rate drops from 54% to 18% on residential jobs exceeding $12,000. Customers get sticker shock and ghost.',
    impact: 'high', metric: '-67%', metricLabel: 'Close rate drop above $12K', recommendation: 'For $12K+ residential jobs, offer phased installation options or financing. Break into stages.',
    confidence: 0.91, dataPoints: 94,
  },
  {
    id: 'i3', type: 'timing', title: 'Tuesday bids close fastest',
    description: 'Bids sent on Tuesdays close 3.2 days faster than average. Friday bids take 40% longer — they get buried over the weekend.',
    impact: 'medium', metric: '3.2 days', metricLabel: 'Faster close on Tuesdays', recommendation: 'Queue bid sends for Tuesday mornings. Avoid sending Friday afternoon.',
    confidence: 0.87, dataPoints: 312,
  },
  {
    id: 'i4', type: 'pricing', title: 'HVAC installs underpriced in 06010',
    description: 'Your HVAC install bids in the 06010 zip code average $8,200 but competitors are winning at $9,800-$11,400. You are leaving $1,600-$3,200 on the table per job.',
    impact: 'high', metric: '+$2,400', metricLabel: 'Potential revenue per bid', recommendation: 'Raise HVAC install pricing in 06010 by 20-30%. Market supports it.',
    confidence: 0.82, dataPoints: 23,
  },
  {
    id: 'i5', type: 'opportunity', title: 'Referral customers close at 78%',
    description: 'Customers who came from referrals close at 78% compared to 34% from web leads. But only 12% of your leads are referrals.',
    impact: 'medium', metric: '78%', metricLabel: 'Referral close rate', recommendation: 'Launch a referral incentive program. Even $50 per referral would dramatically increase your best lead source.',
    confidence: 0.96, dataPoints: 156,
  },
  {
    id: 'i6', type: 'loss_pattern', title: 'Slow follow-up kills deals',
    description: 'Bids with follow-up within 48 hours close at 47%. After 5 days with no follow-up, close rate drops to 8%.',
    impact: 'high', metric: '48hrs', metricLabel: 'Critical follow-up window', recommendation: 'Set up automatic 48-hour follow-up reminders. Consider Z Automations for this.',
    confidence: 0.93, dataPoints: 278,
  },
];

const mockTradePerformance: TradePerformance[] = [
  { trade: 'Electrical', totalBids: 145, won: 78, lost: 42, ghosted: 25, winRate: 53.8, avgMargin: 32.4, avgDealSize: 6800, avgDaysToClose: 8.2, trend: 'up' },
  { trade: 'HVAC', totalBids: 89, won: 41, lost: 31, ghosted: 17, winRate: 46.1, avgMargin: 28.7, avgDealSize: 9200, avgDaysToClose: 11.4, trend: 'flat' },
  { trade: 'Plumbing', totalBids: 112, won: 62, lost: 28, ghosted: 22, winRate: 55.4, avgMargin: 35.1, avgDealSize: 4200, avgDaysToClose: 5.8, trend: 'up' },
  { trade: 'Solar', totalBids: 34, won: 11, lost: 15, ghosted: 8, winRate: 32.4, avgMargin: 22.8, avgDealSize: 18500, avgDaysToClose: 24.6, trend: 'down' },
  { trade: 'Roofing', totalBids: 67, won: 38, lost: 18, ghosted: 11, winRate: 56.7, avgMargin: 26.3, avgDealSize: 11400, avgDaysToClose: 9.1, trend: 'up' },
  { trade: 'General Contractor', totalBids: 28, won: 12, lost: 10, ghosted: 6, winRate: 42.9, avgMargin: 18.5, avgDealSize: 34000, avgDaysToClose: 18.3, trend: 'flat' },
];

const mockHeatmap: PricingHeatmapEntry[] = [
  { zipCode: '06010', area: 'Bristol', avgBid: 8200, winRate: 52, margin: 28, volume: 24 },
  { zipCode: '06051', area: 'New Britain', avgBid: 7100, winRate: 61, margin: 34, volume: 31 },
  { zipCode: '06002', area: 'Bloomfield', avgBid: 11400, winRate: 44, margin: 22, volume: 12 },
  { zipCode: '06108', area: 'East Hartford', avgBid: 6800, winRate: 58, margin: 31, volume: 28 },
  { zipCode: '06032', area: 'Farmington', avgBid: 14200, winRate: 38, margin: 25, volume: 8 },
  { zipCode: '06095', area: 'Windsor', avgBid: 9600, winRate: 49, margin: 29, volume: 18 },
];

const overallStats = {
  totalBids: 475,
  overallWinRate: 50.9,
  avgMargin: 28.8,
  revenueWon: 1842000,
  revenueLost: 986000,
  avgDaysToClose: 9.7,
};

export default function BidBrainPage() {
  const [selectedInsight, setSelectedInsight] = useState<BidInsight | null>(null);
  const [activeTab, setActiveTab] = useState<'insights' | 'trades' | 'geography'>('insights');

  const impactColors = { high: 'text-red-600 bg-red-50 dark:bg-red-950/30 dark:text-red-400', medium: 'text-amber-600 bg-amber-50 dark:bg-amber-950/30 dark:text-amber-400', low: 'text-blue-600 bg-blue-50 dark:bg-blue-950/30 dark:text-blue-400' };
  const typeIcons = { win_pattern: TrendingUp, loss_pattern: TrendingDown, pricing: DollarSign, timing: Calendar, opportunity: Lightbulb };

  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      {/* Header */}
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center">
              <Brain className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Bid Brain</h1>
              <p className="text-sm text-muted-foreground">Win/loss pattern intelligence — learn what closes and what doesn&apos;t</p>
            </div>
          </div>
        </div>
        {/* Tabs */}
        <div className="px-6 flex items-center gap-1">
          {(['insights', 'trades', 'geography'] as const).map(tab => (
            <button key={tab} onClick={() => setActiveTab(tab)}
              className={cn('px-4 py-2 text-sm font-medium border-b-2 transition-colors capitalize',
                activeTab === tab ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'
              )}>
              {tab === 'geography' ? 'Pricing by Area' : tab === 'trades' ? 'By Trade' : 'AI Insights'}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6 space-y-6">
        {/* Stats */}
        <div className="grid grid-cols-6 gap-3">
          {[
            { label: 'Total Bids', value: overallStats.totalBids.toString(), sub: 'Last 12 months' },
            { label: 'Win Rate', value: `${overallStats.overallWinRate}%`, sub: '+3.2% vs last quarter' },
            { label: 'Avg Margin', value: `${overallStats.avgMargin}%`, sub: 'Across all trades' },
            { label: 'Revenue Won', value: formatCurrency(overallStats.revenueWon), sub: 'Accepted bids' },
            { label: 'Revenue Lost', value: formatCurrency(overallStats.revenueLost), sub: 'Declined / ghosted' },
            { label: 'Avg Days to Close', value: overallStats.avgDaysToClose.toString(), sub: 'From sent to accepted' },
          ].map(s => (
            <Card key={s.label}>
              <CardContent className="p-3">
                <p className="text-xs text-muted-foreground">{s.label}</p>
                <p className="text-xl font-semibold mt-0.5">{s.value}</p>
                <p className="text-[10px] text-muted-foreground mt-0.5">{s.sub}</p>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Insights Tab */}
        {activeTab === 'insights' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {mockInsights.map(insight => {
              const TypeIcon = typeIcons[insight.type];
              return (
                <Card key={insight.id} className={cn('cursor-pointer transition-all hover:shadow-md', selectedInsight?.id === insight.id && 'ring-2 ring-primary')} onClick={() => setSelectedInsight(insight)}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-2">
                      <div className="flex items-center gap-2">
                        <div className={cn('w-8 h-8 rounded-lg flex items-center justify-center', impactColors[insight.impact])}>
                          <TypeIcon className="w-4 h-4" />
                        </div>
                        <div>
                          <p className="text-sm font-medium">{insight.title}</p>
                          <p className="text-xs text-muted-foreground">{insight.dataPoints} data points &middot; {Math.round(insight.confidence * 100)}% confidence</p>
                        </div>
                      </div>
                      <Badge className={cn('text-xs', impactColors[insight.impact])}>{insight.impact}</Badge>
                    </div>
                    <p className="text-sm text-muted-foreground leading-relaxed mb-3">{insight.description}</p>
                    <div className="flex items-center justify-between p-2.5 rounded-lg bg-muted/40">
                      <div>
                        <p className="text-lg font-bold">{insight.metric}</p>
                        <p className="text-[10px] text-muted-foreground">{insight.metricLabel}</p>
                      </div>
                      <div className="text-right max-w-[60%]">
                        <div className="flex items-center gap-1 text-xs text-emerald-600 dark:text-emerald-400">
                          <Lightbulb className="w-3 h-3 shrink-0" />
                          <span className="line-clamp-2">{insight.recommendation}</span>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}

        {/* Trades Tab */}
        {activeTab === 'trades' && (
          <Card>
            <CardContent className="p-0">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-border/60">
                    {['Trade', 'Total Bids', 'Won', 'Lost', 'Ghosted', 'Win Rate', 'Avg Margin', 'Avg Deal Size', 'Days to Close', 'Trend'].map(h => (
                      <th key={h} className="text-left text-xs font-medium text-muted-foreground px-4 py-3">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {mockTradePerformance.map(tp => (
                    <tr key={tp.trade} className="border-b border-border/30 hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3 text-sm font-medium">{tp.trade}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">{tp.totalBids}</td>
                      <td className="px-4 py-3 text-sm text-emerald-600 font-medium">{tp.won}</td>
                      <td className="px-4 py-3 text-sm text-red-600">{tp.lost}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">{tp.ghosted}</td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <div className="w-16 h-1.5 rounded-full bg-muted overflow-hidden">
                            <div className="h-full rounded-full bg-primary" style={{ width: `${tp.winRate}%` }} />
                          </div>
                          <span className="text-sm font-medium">{tp.winRate}%</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm">{tp.avgMargin}%</td>
                      <td className="px-4 py-3 text-sm">{formatCurrency(tp.avgDealSize)}</td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">{tp.avgDaysToClose}d</td>
                      <td className="px-4 py-3">
                        {tp.trend === 'up' && <ArrowUpRight className="w-4 h-4 text-emerald-500" />}
                        {tp.trend === 'down' && <ArrowDownRight className="w-4 h-4 text-red-500" />}
                        {tp.trend === 'flat' && <span className="text-xs text-muted-foreground">—</span>}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </CardContent>
          </Card>
        )}

        {/* Geography Tab */}
        {activeTab === 'geography' && (
          <div className="space-y-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Pricing Performance by Area</CardTitle>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-border/60">
                      {['Zip Code', 'Area', 'Avg Bid', 'Win Rate', 'Margin', 'Volume', 'Signal'].map(h => (
                        <th key={h} className="text-left text-xs font-medium text-muted-foreground px-4 py-3">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {mockHeatmap.map(entry => (
                      <tr key={entry.zipCode} className="border-b border-border/30 hover:bg-muted/30 transition-colors">
                        <td className="px-4 py-3 text-sm font-mono font-medium">{entry.zipCode}</td>
                        <td className="px-4 py-3 text-sm">{entry.area}</td>
                        <td className="px-4 py-3 text-sm font-medium">{formatCurrency(entry.avgBid)}</td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <div className="w-12 h-1.5 rounded-full bg-muted overflow-hidden">
                              <div className={cn('h-full rounded-full', entry.winRate >= 55 ? 'bg-emerald-500' : entry.winRate >= 45 ? 'bg-amber-500' : 'bg-red-500')} style={{ width: `${entry.winRate}%` }} />
                            </div>
                            <span className="text-sm">{entry.winRate}%</span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-sm">{entry.margin}%</td>
                        <td className="px-4 py-3 text-sm text-muted-foreground">{entry.volume} bids</td>
                        <td className="px-4 py-3">
                          {entry.winRate >= 55 && entry.margin >= 30 ? (
                            <Badge className="text-xs bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300">Strong market</Badge>
                          ) : entry.winRate < 45 ? (
                            <Badge className="text-xs bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">Raise prices</Badge>
                          ) : (
                            <Badge variant="default" className="text-xs">Healthy</Badge>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
