'use client';

import { MessageSquarePlus, Clock, ChevronRight } from 'lucide-react';
import type { ZThread } from '@/lib/z-intelligence/types';
import { cn } from '@/lib/utils';

interface ZThreadHistoryProps {
  threads: ZThread[];
  currentThreadId: string | null;
  onSelectThread: (threadId: string) => void;
  onNewThread: () => void;
  onClose: () => void;
}

function formatThreadTime(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffHr = Math.floor(diffMin / 60);
  const diffDay = Math.floor(diffHr / 24);

  if (diffMin < 1) return 'Just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  if (diffHr < 24) return `${diffHr}h ago`;
  if (diffDay < 7) return `${diffDay}d ago`;
  return date.toLocaleDateString();
}

export function ZThreadHistory({
  threads,
  currentThreadId,
  onSelectThread,
  onNewThread,
  onClose,
}: ZThreadHistoryProps) {
  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b" style={{ borderColor: '#e4e7ec' }}>
        <span className="text-[14px] font-semibold text-main">Conversations</span>
        <button
          onClick={onClose}
          className="p-1 rounded-md hover:bg-surface-hover transition-colors"
        >
          <ChevronRight size={16} className="text-muted" />
        </button>
      </div>

      {/* New thread button */}
      <div className="px-3 py-2">
        <button
          onClick={onNewThread}
          className="flex items-center gap-2 w-full px-3 py-2 rounded-lg text-[13px] font-medium
            text-accent hover:bg-accent-light transition-colors"
        >
          <MessageSquarePlus size={15} />
          New conversation
        </button>
      </div>

      {/* Thread list */}
      <div className="flex-1 overflow-y-auto px-2" style={{ scrollbarWidth: 'thin' }}>
        {threads.length === 0 && (
          <div className="text-center text-[12px] text-muted py-8">
            No conversations yet
          </div>
        )}

        {threads.map((thread) => (
          <button
            key={thread.id}
            onClick={() => onSelectThread(thread.id)}
            className={cn(
              'w-full text-left px-3 py-2.5 rounded-lg mb-0.5 transition-colors',
              thread.id === currentThreadId
                ? 'bg-accent-light'
                : 'hover:bg-surface-hover',
            )}
          >
            <div className="text-[13px] font-medium text-main truncate">
              {thread.title}
            </div>
            <div className="flex items-center gap-2 mt-0.5">
              <span className="text-[11px] text-muted flex items-center gap-1">
                <Clock size={10} />
                {formatThreadTime(thread.updatedAt)}
              </span>
              <span className="text-[11px] text-muted">
                {thread.messages.length} msg{thread.messages.length !== 1 ? 's' : ''}
              </span>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}
