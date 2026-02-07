'use client';

import { User, Wrench, CheckCircle2, Loader2, AlertCircle } from 'lucide-react';
import { ZMark } from './z-mark';
import type { ZMessage } from '@/lib/z-intelligence/types';
import { ZMarkdown } from './z-markdown';
import { cn } from '@/lib/utils';

function ToolCallBadge({ name, status, description }: { name: string; status: string; description: string }) {
  return (
    <span className={cn(
      'inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium',
      status === 'running' ? 'bg-accent-light text-accent' :
      status === 'error' ? 'bg-red-50 text-red-600 dark:bg-red-950 dark:text-red-400' :
      'bg-secondary text-muted',
    )}>
      {status === 'running' ? <Loader2 size={10} className="animate-spin" /> :
       status === 'error' ? <AlertCircle size={10} /> :
       <CheckCircle2 size={10} />}
      {description || name}
    </span>
  );
}

function formatTime(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);

  if (diffMin < 1) return 'just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  return date.toLocaleDateString();
}

export function ZChatMessage({ message }: { message: ZMessage }) {
  const isUser = message.role === 'user';

  return (
    <div className={cn('z-message-in px-4 py-1.5', isUser ? 'flex justify-end' : '')}>
      <div className={cn('max-w-[90%]', isUser ? 'max-w-[80%]' : '')}>
        {/* Tool calls above assistant message */}
        {!isUser && message.toolCalls && message.toolCalls.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-2">
            {message.toolCalls.map((tc) => (
              <ToolCallBadge key={tc.id} name={tc.name} status={tc.status} description={tc.description} />
            ))}
          </div>
        )}

        <div className={cn(
          'rounded-2xl px-3.5 py-2.5 text-[14px] leading-relaxed',
          isUser
            ? 'bg-accent text-white rounded-br-md'
            : 'bg-secondary rounded-bl-md',
        )}>
          {/* Avatar + content */}
          <div className="flex items-start gap-2">
            {!isUser && (
              <div className="w-5 h-5 rounded-full bg-accent/15 flex items-center justify-center flex-shrink-0 mt-0.5">
                <ZMark size={10} className="text-accent" />
              </div>
            )}
            <div className="min-w-0 flex-1">
              {isUser ? (
                <span>{message.content}</span>
              ) : (
                <ZMarkdown content={message.content} />
              )}
            </div>
            {isUser && (
              <div className="w-5 h-5 rounded-full bg-white/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                <User size={11} />
              </div>
            )}
          </div>
        </div>

        {/* Timestamp */}
        <div className={cn('text-[10px] text-muted mt-1 px-1', isUser ? 'text-right' : '')}>
          {formatTime(message.timestamp)}
        </div>
      </div>
    </div>
  );
}
