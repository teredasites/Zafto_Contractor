'use client';

import { useState, useRef, useEffect, useCallback } from 'react';
import { X, Minus, Send, Loader2, Trash2, MessageCircle } from 'lucide-react';
import { useAiAssistant } from '@/lib/hooks/use-ai-assistant';
import { useAuth } from '@/components/auth-provider';

// ==================== TYPES ====================

interface AiChatWidgetProps {
  context?: {
    projectId?: string;
    invoiceId?: string;
    page?: string;
  };
}

type WidgetState = 'collapsed' | 'open';

// ==================== Z ICON ====================

function ZIcon({ size = 20, className = '' }: { size?: number; className?: string }) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 100 100"
      width={size}
      height={size}
      className={className}
    >
      <g transform="translate(50, 50)">
        <path
          d="M-22,-22 L22,-22 L-22,22 L22,22"
          fill="none"
          stroke="currentColor"
          strokeWidth="4"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </g>
    </svg>
  );
}

// ==================== TYPING INDICATOR ====================

function TypingIndicator() {
  return (
    <div className="flex items-start gap-2 mb-3">
      <div className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
        style={{ backgroundColor: '#635bff' }}>
        <ZIcon size={14} className="text-white" />
      </div>
      <div className="bg-gray-100 rounded-2xl rounded-tl-sm px-4 py-3">
        <div className="flex items-center gap-1">
          <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
          <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
          <span className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
        </div>
      </div>
    </div>
  );
}

// ==================== SUGGESTED QUESTIONS ====================

function getSuggestedQuestions(context?: AiChatWidgetProps['context']): string[] {
  const base = [
    'What\'s the status of my project?',
    'When is my next appointment?',
  ];

  if (context?.page === 'invoices' || context?.invoiceId) {
    return [
      'Explain my latest invoice',
      'What do I owe right now?',
      'When is my next payment due?',
    ];
  }

  if (context?.page === 'projects' || context?.projectId) {
    return [
      'Summarize my project progress',
      'What work is scheduled next?',
      'Are there any delays?',
    ];
  }

  if (context?.page === 'my-home') {
    return [
      'What maintenance is recommended?',
      'When was my last inspection?',
      ...base,
    ];
  }

  return [
    ...base,
    'Explain my latest invoice',
    'What work is coming up?',
  ];
}

// ==================== WIDGET COMPONENT ====================

export default function AiChatWidget({ context }: AiChatWidgetProps) {
  const { user } = useAuth();
  const { messages, loading, error, askQuestion, clearChat } = useAiAssistant();
  const [widgetState, setWidgetState] = useState<WidgetState>('collapsed');
  const [input, setInput] = useState('');
  const [hasUnread, setHasUnread] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // Auto-scroll to latest message
  useEffect(() => {
    if (widgetState === 'open') {
      messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages, loading, widgetState]);

  // Focus input when panel opens
  useEffect(() => {
    if (widgetState === 'open') {
      setTimeout(() => inputRef.current?.focus(), 100);
    }
  }, [widgetState]);

  // Track unread messages
  useEffect(() => {
    if (widgetState === 'collapsed' && messages.length > 0) {
      const lastMsg = messages[messages.length - 1];
      if (lastMsg.role === 'assistant') {
        setHasUnread(true);
      }
    }
  }, [messages, widgetState]);

  const handleOpen = useCallback(() => {
    setWidgetState('open');
    setHasUnread(false);
  }, []);

  const handleClose = useCallback(() => {
    setWidgetState('collapsed');
  }, []);

  const handleSend = useCallback(async () => {
    const trimmed = input.trim();
    if (!trimmed || loading) return;
    setInput('');
    await askQuestion(trimmed);
  }, [input, loading, askQuestion]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }, [handleSend]);

  const handleSuggestionClick = useCallback(async (question: string) => {
    if (loading) return;
    await askQuestion(question);
  }, [loading, askQuestion]);

  const handleClear = useCallback(() => {
    clearChat();
    setInput('');
  }, [clearChat]);

  // Don't render if not authenticated
  if (!user) return null;

  const suggestions = getSuggestedQuestions(context);

  // ---- COLLAPSED STATE: Floating Z button ----
  if (widgetState === 'collapsed') {
    return (
      <button
        onClick={handleOpen}
        className="fixed bottom-20 right-4 md:bottom-6 md:right-6 z-50 w-14 h-14 rounded-full shadow-lg hover:shadow-xl transition-all flex items-center justify-center group"
        style={{ backgroundColor: '#635bff' }}
        aria-label="Open Z Assistant"
      >
        <ZIcon size={24} className="text-white group-hover:scale-110 transition-transform" />
        {hasUnread && (
          <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full border-2 border-white" />
        )}
      </button>
    );
  }

  // ---- OPEN STATE: Chat panel ----
  return (
    <>
      {/* Mobile backdrop */}
      <div
        className="fixed inset-0 bg-black/20 z-40 md:hidden"
        onClick={handleClose}
        aria-hidden="true"
      />

      <div
        className="fixed z-50 bottom-0 right-0 w-full md:bottom-6 md:right-6 md:w-[400px] md:rounded-2xl bg-white md:shadow-2xl flex flex-col overflow-hidden border border-gray-100"
        style={{ height: 'min(500px, calc(100vh - 80px))' }}
        role="dialog"
        aria-label="Z Assistant chat"
      >
        {/* Header */}
        <div
          className="flex items-center justify-between px-4 py-3 flex-shrink-0"
          style={{ backgroundColor: '#635bff' }}
        >
          <div className="flex items-center gap-2.5">
            <ZIcon size={20} className="text-white" />
            <div>
              <h3 className="text-sm font-semibold text-white">Z Assistant</h3>
              <p className="text-[10px] text-white/70">Powered by ZAFTO AI</p>
            </div>
          </div>
          <div className="flex items-center gap-1">
            {messages.length > 0 && (
              <button
                onClick={handleClear}
                className="p-1.5 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
                aria-label="Clear chat"
                title="Clear chat"
              >
                <Trash2 size={16} />
              </button>
            )}
            <button
              onClick={handleClose}
              className="p-1.5 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
              aria-label="Minimize"
              title="Minimize"
            >
              <Minus size={16} />
            </button>
            <button
              onClick={handleClose}
              className="p-1.5 text-white/70 hover:text-white hover:bg-white/10 rounded-lg transition-colors"
              aria-label="Close"
              title="Close"
            >
              <X size={16} />
            </button>
          </div>
        </div>

        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto px-4 py-3 space-y-1">
          {/* Welcome message when empty */}
          {messages.length === 0 && !loading && (
            <div className="flex flex-col items-center justify-center h-full text-center px-4">
              <div
                className="w-12 h-12 rounded-full flex items-center justify-center mb-3"
                style={{ backgroundColor: 'rgba(99, 91, 255, 0.1)' }}
              >
                <MessageCircle size={22} style={{ color: '#635bff' }} />
              </div>
              <h4 className="text-sm font-semibold text-gray-900 mb-1">
                Hi there! How can I help?
              </h4>
              <p className="text-xs text-gray-500 mb-5 leading-relaxed max-w-[260px]">
                Ask me anything about your projects, invoices, appointments, or home.
              </p>

              {/* Suggested Questions */}
              <div className="flex flex-col gap-2 w-full">
                {suggestions.map((q) => (
                  <button
                    key={q}
                    onClick={() => handleSuggestionClick(q)}
                    className="text-left text-xs px-3 py-2.5 rounded-xl border border-gray-100 text-gray-700 hover:bg-gray-50 hover:border-gray-200 transition-colors"
                  >
                    {q}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Message bubbles */}
          {messages.map((msg) => (
            <div key={msg.id} className={`flex items-start gap-2 mb-3 ${msg.role === 'user' ? 'flex-row-reverse' : ''}`}>
              {msg.role === 'assistant' && (
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                  style={{ backgroundColor: '#635bff' }}
                >
                  <ZIcon size={14} className="text-white" />
                </div>
              )}
              <div
                className={`max-w-[80%] rounded-2xl px-3.5 py-2.5 text-sm leading-relaxed ${
                  msg.role === 'user'
                    ? 'rounded-tr-sm text-white'
                    : 'rounded-tl-sm bg-gray-100 text-gray-800'
                }`}
                style={msg.role === 'user' ? { backgroundColor: '#635bff' } : undefined}
              >
                {msg.content}
              </div>
            </div>
          ))}

          {/* Typing indicator */}
          {loading && <TypingIndicator />}

          {/* Error message */}
          {error && (
            <div className="flex items-start gap-2 mb-3">
              <div
                className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: '#635bff' }}
              >
                <ZIcon size={14} className="text-white" />
              </div>
              <div className="max-w-[80%] rounded-2xl rounded-tl-sm bg-red-50 text-red-700 px-3.5 py-2.5 text-sm">
                {error}
              </div>
            </div>
          )}

          {/* Scroll anchor */}
          <div ref={messagesEndRef} />
        </div>

        {/* Quick suggestions when there are messages */}
        {messages.length > 0 && messages.length < 6 && !loading && (
          <div className="px-4 pb-2 flex gap-1.5 overflow-x-auto flex-shrink-0">
            {suggestions.slice(0, 2).map((q) => (
              <button
                key={q}
                onClick={() => handleSuggestionClick(q)}
                className="text-[11px] px-2.5 py-1.5 rounded-full border border-gray-100 text-gray-500 hover:bg-gray-50 hover:text-gray-700 transition-colors whitespace-nowrap flex-shrink-0"
              >
                {q}
              </button>
            ))}
          </div>
        )}

        {/* Input Area */}
        <div className="border-t border-gray-100 px-3 py-3 flex-shrink-0">
          <div className="flex items-center gap-2">
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask a question..."
              disabled={loading}
              className="flex-1 text-sm bg-gray-50 border border-gray-100 rounded-xl px-3.5 py-2.5 outline-none focus:border-gray-300 focus:ring-1 focus:ring-gray-200 transition-colors placeholder:text-gray-400 disabled:opacity-50"
              aria-label="Type your message"
            />
            <button
              onClick={handleSend}
              disabled={!input.trim() || loading}
              className="w-10 h-10 rounded-xl flex items-center justify-center transition-all disabled:opacity-40 disabled:cursor-not-allowed text-white"
              style={{ backgroundColor: '#635bff' }}
              aria-label="Send message"
            >
              {loading ? (
                <Loader2 size={18} className="animate-spin" />
              ) : (
                <Send size={18} />
              )}
            </button>
          </div>
        </div>
      </div>
    </>
  );
}
