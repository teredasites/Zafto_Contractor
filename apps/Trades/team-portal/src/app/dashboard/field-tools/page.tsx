'use client';

import Link from 'next/link';
import {
  Camera,
  Mic,
  PenTool,
  Receipt,
  Ruler,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';

const tools = [
  {
    name: 'Photos',
    description: 'Capture job site photos and before/after documentation',
    href: '/dashboard/field-tools/photos',
    icon: Camera,
    color: 'text-blue-500',
    bgColor: 'bg-blue-500/10',
  },
  {
    name: 'Voice Notes',
    description: 'Record audio memos for quick job documentation',
    href: '/dashboard/field-tools/voice-notes',
    icon: Mic,
    color: 'text-violet-500',
    bgColor: 'bg-violet-500/10',
  },
  {
    name: 'Client Signature',
    description: 'Capture digital signatures from clients on-site',
    href: '/dashboard/field-tools/signatures',
    icon: PenTool,
    color: 'text-emerald-500',
    bgColor: 'bg-emerald-500/10',
  },
  {
    name: 'Receipt Scanner',
    description: 'Photograph receipts for expense tracking and reimbursement',
    href: '/dashboard/field-tools/receipts',
    icon: Receipt,
    color: 'text-amber-500',
    bgColor: 'bg-amber-500/10',
  },
  {
    name: 'Level & Plumb',
    description: 'Digital level and plumb measurements using device sensors',
    href: '/dashboard/field-tools/level',
    icon: Ruler,
    color: 'text-cyan-500',
    bgColor: 'bg-cyan-500/10',
  },
];

export default function FieldToolsPage() {
  return (
    <div className="space-y-8 animate-fade-in">
      <div>
        <h1 className="text-xl font-bold text-main">Field Tools</h1>
        <p className="text-sm text-muted mt-1">
          Quick-access tools for on-site documentation and measurements
        </p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
        {tools.map((tool) => (
          <Link key={tool.href} href={tool.href}>
            <Card className="h-full hover:border-[var(--accent)] transition-colors group">
              <div className="px-4 py-5 sm:px-5 sm:py-6 flex flex-col items-center text-center gap-3 min-h-[112px] justify-center">
                <div
                  className={cn(
                    'w-12 h-12 sm:w-14 sm:h-14 rounded-xl flex items-center justify-center transition-transform group-hover:scale-105',
                    tool.bgColor
                  )}
                >
                  <tool.icon size={24} className={cn('sm:w-7 sm:h-7', tool.color)} />
                </div>
                <div>
                  <p className="text-[15px] font-semibold text-main">{tool.name}</p>
                  <p className="text-xs text-muted mt-0.5 hidden sm:block leading-relaxed">
                    {tool.description}
                  </p>
                </div>
              </div>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
