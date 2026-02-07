'use client';

import Link from 'next/link';
import { ArrowLeft, Ruler } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export default function LevelToolPage() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div>
        <Link
          href="/dashboard/field-tools"
          className="inline-flex items-center gap-1.5 text-sm text-muted hover:text-main transition-colors mb-3"
        >
          <ArrowLeft size={16} />
          <span>Field Tools</span>
        </Link>
        <h1 className="text-xl font-bold text-main">Level & Plumb</h1>
        <p className="text-sm text-muted mt-1">
          Digital level and plumb measurements using device sensors
        </p>
      </div>

      <Card>
        <CardContent className="py-12 sm:py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-cyan-500/10 flex items-center justify-center">
              <Ruler size={32} className="text-cyan-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Digital level tool using device sensors.
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Uses the accelerometer and gyroscope to provide real-time level
                and plumb readings. Readings are saved to the job record for
                compliance documentation.
              </p>
            </div>
            <div className="flex items-center gap-2 mt-4 px-4 py-2.5 rounded-lg bg-secondary border border-main">
              <Ruler size={14} className="text-muted flex-shrink-0" />
              <p className="text-xs text-muted">
                Sensor-based level tool requires native device APIs -- full implementation
                available in the mobile app. Web adapter coming in Phase E.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
