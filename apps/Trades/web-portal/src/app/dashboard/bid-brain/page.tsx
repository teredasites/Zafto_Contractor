'use client';

// Phase E — AI-powered bid analytics. Deferred until all core phases complete.

import { Brain, TrendingUp, Target, BarChart3, Zap } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { CommandPalette } from '@/components/command-palette';

const features = [
  { icon: TrendingUp, label: 'Win/Loss Pattern Analysis', desc: 'AI identifies what makes your bids win or lose based on historical data' },
  { icon: Target, label: 'Pricing Intelligence', desc: 'Know exactly how your pricing compares by zip code and trade' },
  { icon: BarChart3, label: 'Trade Performance', desc: 'Detailed breakdown of win rates, margins, and deal sizes per trade' },
  { icon: Zap, label: 'Actionable Recommendations', desc: 'AI-generated suggestions to improve close rates and revenue' },
];

export default function BidBrainPage() {
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
      </div>

      {/* Coming Soon */}
      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto text-center py-16">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-amber-500/20 to-orange-600/20 flex items-center justify-center mx-auto mb-6">
            <Brain className="w-8 h-8 text-amber-500" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Coming Soon</h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Bid Brain uses AI to analyze your bid history and surface actionable insights to improve your win rate. This feature is in development.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-left">
            {features.map(f => (
              <Card key={f.label}>
                <CardContent className="p-4">
                  <div className="flex items-start gap-3">
                    <div className="p-2 rounded-lg bg-muted/50">
                      <f.icon className="w-4 h-4 text-muted-foreground" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-foreground">{f.label}</p>
                      <p className="text-xs text-muted-foreground mt-0.5">{f.desc}</p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
