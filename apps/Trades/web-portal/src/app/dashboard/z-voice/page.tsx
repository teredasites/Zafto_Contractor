'use client';

// Phase E — AI voice-to-action. Deferred until all core phases complete.

import { Mic, FileText, Clock, Zap } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { CommandPalette } from '@/components/command-palette';

const features = [
  { icon: Mic, label: 'Voice-to-Action', desc: 'Speak naturally and Z Voice creates time entries, material logs, purchase orders, and job notes automatically' },
  { icon: FileText, label: 'Smart Transcription', desc: 'Field-optimized speech recognition that understands trade terminology and project context' },
  { icon: Clock, label: 'Hands-Free Logging', desc: 'Log time, materials, and status updates without putting down your tools' },
  { icon: Zap, label: 'Multi-Action Parsing', desc: 'One voice memo can create multiple actions — time entry + material log + job note simultaneously' },
];

export default function ZVoicePage() {
  return (
    <div className="flex-1 flex flex-col min-h-0">
      <CommandPalette />
      <div className="shrink-0 border-b border-border/60 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-purple-600 flex items-center justify-center">
              <Mic className="w-4 h-4 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-semibold text-foreground">Z Voice</h1>
              <p className="text-sm text-muted-foreground">Voice-to-action — speak it, Z does it</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="max-w-2xl mx-auto text-center py-16">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-violet-500/20 to-purple-600/20 flex items-center justify-center mx-auto mb-6">
            <Mic className="w-8 h-8 text-violet-500" />
          </div>
          <h2 className="text-2xl font-bold text-foreground mb-2">Coming Soon</h2>
          <p className="text-muted-foreground max-w-md mx-auto mb-8">
            Z Voice uses AI to convert your spoken field notes into structured actions — time entries, material logs, purchase orders, and more. This feature is in development.
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
