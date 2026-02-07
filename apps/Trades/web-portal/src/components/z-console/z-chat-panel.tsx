'use client';

import { useState } from 'react';
import { X, History, Eye } from 'lucide-react';
import { ZMark } from './z-mark';
import type { ZMessage, ZThread, ZContextChip as ChipType, ZQuickAction } from '@/lib/z-intelligence/types';
import { ZChatMessages } from './z-chat-messages';
import { ZChatInput } from './z-chat-input';
import { ZContextChip } from './z-context-chip';
import { ZQuickActions } from './z-quick-actions';
import { ZThreadHistory } from './z-thread-history';

interface ZChatPanelProps {
  messages: ZMessage[];
  threads: ZThread[];
  currentThreadId: string | null;
  isThinking: boolean;
  contextChip: ChipType;
  quickActions: ZQuickAction[];
  onSend: (message: string) => void;
  onClose: () => void;
  onSelectThread: (threadId: string) => void;
  onNewThread: () => void;
  onQuickAction: (action: ZQuickAction) => void;
  onShowDemo: () => void;
}

export function ZChatPanel({
  messages,
  threads,
  currentThreadId,
  isThinking,
  contextChip,
  quickActions,
  onSend,
  onClose,
  onSelectThread,
  onNewThread,
  onQuickAction,
  onShowDemo,
}: ZChatPanelProps) {
  const [showHistory, setShowHistory] = useState(false);

  return (
    <div className="fixed top-0 right-0 h-full w-[420px] z-50 z-glass border-l flex flex-col z-panel-enter z-panel-active"
      style={{ borderColor: '#e4e7ec' }}
    >
      {showHistory ? (
        <ZThreadHistory
          threads={threads}
          currentThreadId={currentThreadId}
          onSelectThread={(id) => {
            onSelectThread(id);
            setShowHistory(false);
          }}
          onNewThread={() => {
            onNewThread();
            setShowHistory(false);
          }}
          onClose={() => setShowHistory(false)}
        />
      ) : (
        <>
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b flex-shrink-0"
            style={{ borderColor: '#e4e7ec' }}
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-full bg-accent/15 flex items-center justify-center">
                <ZMark size={14} className="text-accent" />
              </div>
              <div>
                <div className="text-[14px] font-semibold text-main">Z Intelligence</div>
                <ZContextChip chip={contextChip} />
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={onShowDemo}
                className="p-1.5 rounded-md hover:bg-surface-hover transition-colors"
                title="Preview artifact system"
              >
                <Eye size={16} className="text-muted" />
              </button>
              <button
                onClick={() => setShowHistory(true)}
                className="p-1.5 rounded-md hover:bg-surface-hover transition-colors"
                title="Conversation history"
              >
                <History size={16} className="text-muted" />
              </button>
              <button
                onClick={onClose}
                className="p-1.5 rounded-md hover:bg-surface-hover transition-colors"
              >
                <X size={16} className="text-muted" />
              </button>
            </div>
          </div>

          {/* Messages */}
          <ZChatMessages messages={messages} isThinking={isThinking} />

          {/* Quick actions (only when no messages) */}
          {messages.length === 0 && !isThinking && (
            <ZQuickActions actions={quickActions} onSelect={onQuickAction} />
          )}

          {/* Input */}
          <ZChatInput onSend={onSend} disabled={isThinking} />
        </>
      )}
    </div>
  );
}
