'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Sparkles, X, Minimize2, Maximize2, Loader2, User } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ZAIChatProps {
  isOpen: boolean;
  onClose: () => void;
  isMinimized?: boolean;
  onToggleMinimize?: () => void;
}

export function ZAIChat({ isOpen, onClose, isMinimized = false, onToggleMinimize }: ZAIChatProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      role: 'assistant',
      content: "Hey! I'm Z, your business assistant. I can help you with bids, jobs, invoices, scheduling, and more. What do you need?",
      timestamp: new Date(),
    },
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    if (isOpen && !isMinimized) {
      inputRef.current?.focus();
    }
  }, [isOpen, isMinimized]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;

    const userMessage: Message = {
      id: Date.now().toString(),
      role: 'user',
      content: input.trim(),
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    // Simulate AI response - Replace with actual API call
    setTimeout(() => {
      const responses: Record<string, string> = {
        bid: "I can help you create a bid. What type of work is it for and who's the customer?",
        invoice: "Let's create an invoice. Which job or customer is this for?",
        schedule: "I'll check your schedule. What dates are you looking at?",
        customer: "I can look up customer info. What's the customer's name or company?",
        revenue: "This month you've brought in $12,485.50 in revenue. That's down 33.4% from last month ($18,742.30). Want me to break it down by job type?",
        overdue: "You have 1 overdue invoice: INV-2026-0038 for $627.47 from Park Restaurants. It's 10 days overdue. Want me to send a reminder?",
      };

      const lowerInput = userMessage.content.toLowerCase();
      let response = "I can help with that. Could you tell me more about what you need?";

      for (const [key, value] of Object.entries(responses)) {
        if (lowerInput.includes(key)) {
          response = value;
          break;
        }
      }

      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: new Date(),
      };

      setMessages((prev) => [...prev, aiMessage]);
      setIsLoading(false);
    }, 1000);
  };

  if (!isOpen) return null;

  if (isMinimized) {
    return (
      <div className="fixed bottom-4 right-4 z-40">
        <button
          onClick={onToggleMinimize}
          className="flex items-center gap-2 px-4 py-3 bg-accent text-white rounded-full shadow-lg hover:bg-accent-hover transition-colors"
        >
          <Sparkles size={18} />
          <span className="font-medium">Z</span>
          {messages.length > 1 && (
            <span className="w-5 h-5 bg-white/20 rounded-full text-xs flex items-center justify-center">
              {messages.length}
            </span>
          )}
        </button>
      </div>
    );
  }

  return (
    <div className="fixed bottom-4 right-4 z-40 w-96">
      <div className="bg-surface border border-main rounded-xl shadow-2xl overflow-hidden flex flex-col max-h-[600px]">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-main bg-accent text-white">
          <div className="flex items-center gap-2">
            <Sparkles size={18} />
            <span className="font-semibold">Z</span>
          </div>
          <div className="flex items-center gap-1">
            {onToggleMinimize && (
              <button
                onClick={onToggleMinimize}
                className="p-1.5 hover:bg-white/10 rounded transition-colors"
              >
                <Minimize2 size={16} />
              </button>
            )}
            <button
              onClick={onClose}
              className="p-1.5 hover:bg-white/10 rounded transition-colors"
            >
              <X size={16} />
            </button>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 min-h-[300px] max-h-[400px]">
          {messages.map((message) => (
            <div
              key={message.id}
              className={cn(
                'flex gap-3',
                message.role === 'user' ? 'flex-row-reverse' : ''
              )}
            >
              <div
                className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0',
                  message.role === 'assistant'
                    ? 'bg-accent text-white'
                    : 'bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                )}
              >
                {message.role === 'assistant' ? (
                  <Sparkles size={14} />
                ) : (
                  <User size={14} />
                )}
              </div>
              <div
                className={cn(
                  'rounded-xl px-4 py-2.5 max-w-[80%]',
                  message.role === 'assistant'
                    ? 'bg-secondary text-main'
                    : 'bg-accent text-white'
                )}
              >
                <p className="text-sm whitespace-pre-wrap">{message.content}</p>
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex gap-3">
              <div className="w-8 h-8 rounded-full bg-accent text-white flex items-center justify-center">
                <Sparkles size={14} />
              </div>
              <div className="bg-secondary rounded-xl px-4 py-2.5">
                <Loader2 size={16} className="animate-spin text-muted" />
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Quick Actions */}
        <div className="px-4 py-2 border-t border-main">
          <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
            {['Create bid', 'Check schedule', 'Revenue report', 'Overdue invoices'].map(
              (action) => (
                <button
                  key={action}
                  onClick={() => setInput(action)}
                  className="px-3 py-1.5 bg-secondary hover:bg-surface-hover text-sm text-main rounded-full whitespace-nowrap transition-colors"
                >
                  {action}
                </button>
              )
            )}
          </div>
        </div>

        {/* Input */}
        <form onSubmit={handleSubmit} className="p-4 border-t border-main">
          <div className="flex items-center gap-2">
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Ask Z anything..."
              className="flex-1 px-4 py-2.5 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted focus:outline-none focus:border-accent"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={!input.trim() || isLoading}
              className="p-2.5 bg-accent text-white rounded-lg hover:bg-accent-hover disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <Send size={18} />
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// Floating trigger button for Z AI
export function ZAITrigger({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="fixed bottom-4 right-4 z-30 flex items-center gap-2 px-4 py-3 bg-accent text-white rounded-full shadow-lg hover:bg-accent-hover transition-all hover:scale-105"
    >
      <Sparkles size={18} />
      <span className="font-medium">Ask Z</span>
    </button>
  );
}
