'use client';

import { useRef, useEffect } from 'react';
import type { ZMessage } from '@/lib/z-intelligence/types';
import { ZChatMessage } from './z-chat-message';
import { ZThinkingIndicator } from './z-thinking-indicator';

interface ZChatMessagesProps {
  messages: ZMessage[];
  isThinking: boolean;
  compact?: boolean;
}

export function ZChatMessages({ messages, isThinking, compact = false }: ZChatMessagesProps) {
  const bottomRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages.length, isThinking]);

  return (
    <div
      ref={containerRef}
      className={`flex-1 overflow-y-auto ${compact ? 'py-2' : 'py-4'}`}
      style={{ scrollbarWidth: 'thin' }}
    >
      {messages.length === 0 && !isThinking && (
        <div className="flex flex-col items-center justify-center h-full px-6 text-center">
          <div className="w-10 h-10 rounded-full bg-accent/10 flex items-center justify-center mb-3">
            <span className="text-accent text-lg font-bold">Z</span>
          </div>
          <p className="text-[14px] font-medium text-main mb-1">Z Intelligence</p>
          <p className="text-[12px] text-muted max-w-[260px]">
            Your AI assistant. Create bids, invoices, reports, and more. Type / for commands.
          </p>
        </div>
      )}

      {messages.map((msg) => (
        <ZChatMessage key={msg.id} message={msg} />
      ))}

      {isThinking && (
        <div className="px-4 py-2">
          <ZThinkingIndicator />
        </div>
      )}

      <div ref={bottomRef} />
    </div>
  );
}
