'use client';

import { MapPin } from 'lucide-react';
import type { ZContextChip as ChipType } from '@/lib/z-intelligence/types';

export function ZContextChip({ chip }: { chip: ChipType }) {
  return (
    <div className="flex items-center gap-1.5 px-2.5 py-1 bg-secondary rounded-full text-[12px] text-muted w-fit">
      <MapPin size={11} />
      <span>On: {chip.label}</span>
    </div>
  );
}
