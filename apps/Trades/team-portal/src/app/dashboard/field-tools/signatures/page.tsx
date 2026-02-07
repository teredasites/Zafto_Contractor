'use client';

import Link from 'next/link';
import { ArrowLeft, PenTool, FileSignature } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';

export default function SignaturesPage() {
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
        <h1 className="text-xl font-bold text-main">Client Signatures</h1>
        <p className="text-sm text-muted mt-1">
          Capture digital signatures from clients on-site
        </p>
      </div>

      <Card>
        <CardContent className="py-12 sm:py-16">
          <div className="flex flex-col items-center text-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 flex items-center justify-center">
              <PenTool size={32} className="text-emerald-500" />
            </div>
            <div className="space-y-1.5 max-w-xs">
              <p className="text-[15px] font-semibold text-main">
                Capture digital signatures from clients on-site
              </p>
              <p className="text-sm text-muted leading-relaxed">
                Have clients sign directly on your device for work approvals,
                change orders, and completion confirmations. Signatures are
                stored securely and linked to the relevant job record.
              </p>
            </div>

            <div className="w-full max-w-sm mt-2 h-32 rounded-xl border-2 border-dashed border-main flex items-center justify-center">
              <div className="flex flex-col items-center gap-2 text-muted">
                <FileSignature size={24} />
                <span className="text-xs">Signature canvas area</span>
              </div>
            </div>

            <div className="flex items-center gap-2 mt-4 px-4 py-2.5 rounded-lg bg-secondary border border-main">
              <PenTool size={14} className="text-muted flex-shrink-0" />
              <p className="text-xs text-muted">
                Needs HTML5 canvas drawing implementation -- full signature
                capture deferred to a future sprint
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
