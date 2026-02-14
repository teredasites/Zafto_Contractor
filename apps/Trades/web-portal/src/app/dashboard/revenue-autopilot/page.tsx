'use client';

// Phase E — AI revenue opportunity engine. Deferred until all core phases complete.

import { Rocket, DollarSign, TrendingUp, Target } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { CommandPalette } from '@/components/command-palette';

const features = [
  { icon: DollarSign, label: 'Opportunity Detection', desc: 'AI scans your customer base and job history to find revenue opportunities you are missing — upsells, follow-ups, and seasonal services' },
  { icon: TrendingUp, label: 'Revenue Pipeline', desc: 'Visualize your opportunity pipeline with estimated values, conversion rates, and priority scoring' },
  { icon: Target, label: 'Smart Outreach', desc: 'AI drafts personalized messages for each opportunity — email, SMS, or call scripts tailored to the customer and service type' },
  { icon: Rocket, label: 'Automated Campaigns', desc: 'Set it and forget it — Revenue Autopilot runs campaigns on your behalf with your approval' },
];

export default function RevenueAutopilotPage() {
  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-green-600 flex items-center justify-center">
              <Rocket className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Revenue Autopilot</h1>
              <p className="text-sm text-muted-foreground">AI-powered revenue opportunity engine</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto text-center py-16">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-green-600/20 flex items-center justify-center mx-auto mb-6">
            <Rocket className="w-8 h-8 text-emerald-500" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Coming Soon</h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Revenue Autopilot uses AI to scan your customer base and identify revenue opportunities — warranty upsells, seasonal maintenance, equipment replacements, and follow-up campaigns. This feature is in development.
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
