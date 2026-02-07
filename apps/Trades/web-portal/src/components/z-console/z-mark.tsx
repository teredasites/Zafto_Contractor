'use client';

import { cn } from '@/lib/utils';

interface ZMarkProps {
  size?: number;
  className?: string;
}

/**
 * Z lettermark — used everywhere AI/Z Intelligence appears.
 * Bold geometric Z, no sparkles, no toy icons.
 */
export function ZMark({ size = 14, className }: ZMarkProps) {
  return (
    <span
      className={cn('font-black italic select-none leading-none', className)}
      style={{ fontSize: size, fontFamily: 'system-ui, -apple-system, sans-serif' }}
      aria-hidden="true"
    >
      Z
    </span>
  );
}
