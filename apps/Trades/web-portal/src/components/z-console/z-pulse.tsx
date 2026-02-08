'use client';

import { Logo } from '@/components/logo';

interface ZPulseProps {
  onClick: () => void;
  hasUnread: boolean;
}

export function ZPulse({ onClick, hasUnread }: ZPulseProps) {
  return (
    <button
      onClick={onClick}
      className="fixed bottom-6 right-6 z-40 group z-ambient-glow"
      aria-label="Open Z Intelligence"
    >
      {/* Ambient glow layers */}
      <span className="absolute inset-[-16px] rounded-full z-ambient-outer pointer-events-none" />
      <span className="absolute inset-[-8px] rounded-full z-ambient-mid pointer-events-none" />

      {/* The Z mark — Logo SVG with emerald color */}
      <span className="relative flex items-center justify-center w-12 h-12
        text-emerald-500 transition-transform duration-300
        group-hover:scale-105"
      >
        <Logo size={40} className="text-emerald-500" animated />
      </span>

      {/* Unread indicator */}
      {hasUnread && (
        <span className="absolute top-0 right-0 w-3 h-3 rounded-full bg-red-500 border-2 border-white dark:border-gray-900 z-10" />
      )}
    </button>
  );
}
