'use client';

import Link from 'next/link';
import { ArrowLeft, Mic, Radio } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export default function VoiceNotesPage() {
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
        <h1 className="text-xl font-bold text-main">Voice Notes</h1>
        <p className="text-sm text-muted mt-1">
          Record audio memos for quick job documentation
        </p>
      </div>

      <Card>
        <CardContent className="py-12 sm:py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-violet-500/10 flex items-center justify-center">
              <Mic size={32} className="text-violet-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Record voice memos for job documentation
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Capture quick audio notes while on-site. Recordings are saved to
                your job record and can be transcribed by AI in Phase E.
              </p>
            </div>

            <div className="w-20 h-20 mt-2 rounded-full border-2 border-dashed border-main flex items-center justify-center">
              <Radio size={28} className="text-muted" />
            </div>

            <div className="flex items-center gap-2 mt-4 px-4 py-2.5 rounded-lg bg-secondary border border-main">
              <Mic size={14} className="text-muted flex-shrink-0" />
              <p className="text-xs text-muted">
                Web audio recording requires MediaRecorder API -- full
                implementation deferred to Phase E with transcription
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
