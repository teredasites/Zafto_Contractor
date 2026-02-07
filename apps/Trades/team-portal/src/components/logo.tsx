'use client';

export function Logo({ className }: { className?: string }) {
  return (
    <span className={className || 'text-xl font-bold tracking-tight text-main'}>
      ZAFTO<span className="text-accent">.</span>team
    </span>
  );
}
