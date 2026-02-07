'use client';

import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import {
  Wrench, Camera, BookOpen, Cpu, FileSearch,
  Sparkles, ArrowRight,
} from 'lucide-react';

const featureCards = [
  {
    icon: Camera,
    title: 'Photo Diagnosis',
    description: 'Upload a photo of any issue and get AI-powered analysis with suggested fixes, part numbers, and repair steps.',
  },
  {
    icon: BookOpen,
    title: 'Code Lookup',
    description: 'Instant lookup for NEC, IPC, IRC, and local building codes. Get interpretations and compliance guidance.',
  },
  {
    icon: Cpu,
    title: 'Parts ID',
    description: 'Identify unknown parts from photos. Get manufacturer info, specs, compatible replacements, and supplier links.',
  },
  {
    icon: FileSearch,
    title: 'Repair Guides',
    description: 'Step-by-step repair procedures for equipment across all trades. Backed by manufacturer documentation and field experience.',
  },
];

export default function TroubleshootPage() {
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Page header */}
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-accent-light">
          <Wrench size={20} className="text-accent" />
        </div>
        <div>
          <h1 className="text-xl font-semibold text-main">AI Troubleshooting Center</h1>
          <p className="text-sm text-muted">Multi-trade diagnostics powered by Z Intelligence</p>
        </div>
      </div>

      {/* Placeholder hero */}
      <Card>
        <CardContent className="py-12">
          <div className="flex flex-col items-center text-center max-w-md mx-auto space-y-4">
            <div className="w-16 h-16 rounded-2xl bg-accent-light flex items-center justify-center">
              <Wrench size={28} className="text-accent" />
            </div>
            <h2 className="text-lg font-semibold text-main">
              AI-powered multi-trade diagnostics coming in Phase E
            </h2>
            <p className="text-sm text-muted leading-relaxed">
              The Troubleshooting Center will provide instant diagnostics, code lookups, parts identification,
              and repair guides across all trades -- electrical, plumbing, HVAC, and more.
            </p>
            <div className="flex items-center gap-2 text-xs font-medium text-accent pt-2">
              <Sparkles size={14} />
              <span>Powered by Z Intelligence</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Feature preview cards */}
      <div>
        <h2 className="text-sm font-semibold text-muted uppercase tracking-wider mb-4">Feature Preview</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {featureCards.map((feature) => (
            <Card key={feature.title} className="group hover:border-[var(--accent)] transition-colors">
              <CardContent className="py-5">
                <div className="flex items-start gap-4">
                  <div className="p-2.5 rounded-lg bg-accent-light flex-shrink-0 group-hover:bg-[var(--accent)] transition-colors">
                    <feature.icon
                      size={20}
                      className="text-accent group-hover:text-white transition-colors"
                    />
                  </div>
                  <div className="flex-1 min-w-0 space-y-1.5">
                    <div className="flex items-center gap-2">
                      <h3 className="text-[15px] font-semibold text-main">{feature.title}</h3>
                      <ArrowRight
                        size={14}
                        className="text-muted opacity-0 group-hover:opacity-100 group-hover:text-accent transition-all -translate-x-1 group-hover:translate-x-0"
                      />
                    </div>
                    <p className="text-sm text-muted leading-relaxed">{feature.description}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Bottom note */}
      <div className="flex items-center justify-center gap-2 py-4">
        <div className="h-px flex-1 bg-[var(--border-light)]" />
        <p className="text-xs text-muted px-3">
          This feature will be powered by Z Intelligence
        </p>
        <div className="h-px flex-1 bg-[var(--border-light)]" />
      </div>
    </div>
  );
}
