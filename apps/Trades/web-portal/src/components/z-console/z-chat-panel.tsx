'use client';

import { useState, useCallback } from 'react';
import { X, History, FolderOpen, MessageSquarePlus } from 'lucide-react';
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
  width: number;
  onWidthChange: (width: number) => void;
  rightOffset: number;
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
  width,
  onWidthChange,
  rightOffset,
}: ZChatPanelProps) {
  const [showHistory, setShowHistory] = useState(false);

  const handleResizeStart = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.clientX;
    const startWidth = width;

    const onMouseMove = (ev: MouseEvent) => {
      const delta = startX - ev.clientX;
      onWidthChange(startWidth + delta);
    };

    const onMouseUp = () => {
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };

    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
  }, [width, onWidthChange]);

  return (
    <div
      className="fixed top-0 h-full z-50 z-glass border-l flex flex-col"
      style={{
        borderColor: '#e4e7ec',
        width: `${width}px`,
        right: `${rightOffset}px`,
        transition: 'right 280ms cubic-bezier(0.32, 0.72, 0, 1)',
      }}
    >
      {/* Resize handle */}
      <div
        className="absolute left-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-accent/30 active:bg-accent/40 transition-colors z-50"
        onMouseDown={handleResizeStart}
      />
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
          {/* Header — fixed double-Z: show Z icon + "Intelligence" (not "Z Intelligence") */}
          <div className="flex items-center justify-between px-4 py-3 border-b flex-shrink-0"
            style={{ borderColor: '#e4e7ec' }}
          >
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-full bg-accent/15 flex items-center justify-center">
                <ZMark size={14} className="text-accent" />
              </div>
              <div>
                <div className="text-[14px] font-semibold text-main">Intelligence</div>
                <ZContextChip chip={contextChip} />
              </div>
            </div>
            <div className="flex items-center gap-1">
              <button
                onClick={() => {
                  onNewThread();
                }}
                className="p-1.5 rounded-md hover:bg-accent/10 hover:text-accent transition-colors"
                title="New conversation"
              >
                <MessageSquarePlus size={16} className="text-muted" />
              </button>
              <button
                onClick={onShowDemo}
                className="p-1.5 rounded-md hover:bg-surface-hover transition-colors"
                title="Open artifact workspace"
              >
                <FolderOpen size={16} className="text-muted" />
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
