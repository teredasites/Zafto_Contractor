'use client';

interface ZPulseProps {
  onClick: () => void;
  hasUnread: boolean;
}

export function ZPulse({ onClick, hasUnread }: ZPulseProps) {
  return (
    <button
      onClick={onClick}
      className="fixed bottom-6 right-6 z-40 group"
      aria-label="Open Z Intelligence"
    >
      {/* Outer glow ring */}
      <span className="absolute inset-0 rounded-2xl bg-emerald-500/20 z-pulse-glow" />

      {/* Main button */}
      <span className="relative flex items-center justify-center w-14 h-14 rounded-2xl
        bg-gradient-to-br from-emerald-600 to-emerald-700
        shadow-[0_4px_24px_rgba(16,185,129,0.3)]
        group-hover:shadow-[0_4px_32px_rgba(16,185,129,0.45)]
        group-hover:from-emerald-500 group-hover:to-emerald-600
        transition-all duration-200"
      >
        <span className="text-white font-black italic text-[22px] leading-none select-none"
          style={{ fontFamily: 'system-ui, -apple-system, sans-serif' }}
        >
          Z
        </span>
      </span>

      {/* Unread indicator */}
      {hasUnread && (
        <span className="absolute -top-0.5 -right-0.5 w-3.5 h-3.5 rounded-full bg-red-500 border-2 border-white z-10" />
      )}
    </button>
  );
}
