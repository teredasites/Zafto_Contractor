'use client';

export function ZThinkingIndicator() {
  return (
    <div className="flex items-center gap-1.5 px-4 py-3 z-message-in">
      <div className="flex items-center gap-1">
        <span className="z-thinking-dot w-1.5 h-1.5 rounded-full bg-accent" />
        <span className="z-thinking-dot w-1.5 h-1.5 rounded-full bg-accent" />
        <span className="z-thinking-dot w-1.5 h-1.5 rounded-full bg-accent" />
      </div>
      <span className="text-[12px] text-muted ml-1">Z is thinking...</span>
    </div>
  );
}
