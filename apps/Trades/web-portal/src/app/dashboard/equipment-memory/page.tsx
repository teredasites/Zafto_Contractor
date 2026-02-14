'use client';

// Phase E — AI equipment lifecycle intelligence. Deferred until all core phases complete.

import { Cpu, Bell, Shield, RefreshCcw } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { CommandPalette } from '@/components/command-palette';

const features = [
  { icon: Cpu, label: 'Equipment Lifecycle Tracking', desc: 'Track every piece of equipment you install — model, serial, warranty, install date — with automatic age monitoring' },
  { icon: Bell, label: 'Proactive Alerts', desc: 'Get notified before warranties expire and when equipment reaches end-of-life so you can proactively reach out to customers' },
  { icon: Shield, label: 'Recall Detection', desc: 'Automatic monitoring for manufacturer recalls on installed equipment — protect your customers and your reputation' },
  { icon: RefreshCcw, label: 'Replacement Revenue', desc: 'AI identifies aging equipment ready for replacement and generates outreach opportunities with estimated revenue' },
];

export default function EquipmentMemoryPage() {
  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-teal-600 flex items-center justify-center">
              <Cpu className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Equipment Memory</h1>
              <p className="text-sm text-muted-foreground">Installed equipment lifecycle intelligence</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto text-center py-16">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-cyan-500/20 to-teal-600/20 flex items-center justify-center mx-auto mb-6">
            <Cpu className="w-8 h-8 text-cyan-500" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Coming Soon</h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Equipment Memory tracks every piece of equipment you install and uses AI to identify replacement opportunities, warranty expirations, and manufacturer recalls. This feature is in development.
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
