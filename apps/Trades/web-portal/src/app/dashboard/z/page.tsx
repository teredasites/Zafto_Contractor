'use client';

import { useState, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Send,
  Sparkles,
  User,
  Loader2,
  ArrowLeft,
  History,
  Plus,
  FileText,
  Briefcase,
  Receipt,
  Calendar,
  Calculator,
  BarChart3,
  Search,
  Zap,
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatRelativeTime } from '@/lib/utils';
import { mockAIThreads } from '@/lib/mock-data';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  tools?: { name: string; status: 'pending' | 'complete' }[];
}

const quickActions = [
  { icon: FileText, label: 'Create a bid', prompt: 'Help me create a bid for' },
  { icon: Receipt, label: 'Create an invoice', prompt: 'Create an invoice for' },
  { icon: Calendar, label: "Check today's schedule", prompt: "What's on my schedule today?" },
  { icon: BarChart3, label: 'Revenue report', prompt: "How much revenue did I make this month?" },
  { icon: Calculator, label: 'Calculate materials', prompt: 'Calculate the materials needed for' },
  { icon: Search, label: 'Find a customer', prompt: 'Find customer' },
];

export default function ZAIPage() {
  const router = useRouter();
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  const handleSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
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

    // Simulate AI response
    setTimeout(() => {
      const responses: Record<string, { content: string; tools?: { name: string; status: 'complete' }[] }> = {
        bid: {
          content: "I'll help you create a bid. I need a few details:\n\n1. **Customer name** - Who is this bid for?\n2. **Job description** - What work needs to be done?\n3. **Location** - Where is the job site?\n\nOnce you provide these, I can generate Good, Better, and Best options with accurate pricing from your price book.",
          tools: [{ name: 'searchPriceBook', status: 'complete' }],
        },
        invoice: {
          content: "Let's create an invoice. Which job should I base this on?\n\nI found 3 completed jobs without invoices:\n- **Ceiling Fan Installation** - John Mitchell - $1,106.04\n- **Parking Lot Light Repair** - Emily Thompson - $2,605.58\n- **GFCI Outlet Installation** - Park Restaurants - $627.47\n\nJust tell me which one, or describe a new invoice.",
          tools: [{ name: 'searchJobs', status: 'complete' }],
        },
        schedule: {
          content: "Here's your schedule for today:\n\n**Now - 4:00 PM**\nEmergency - No Power Unit 4B\nEmily Thompson | 1200 Chapel Street, Unit 4B\nAssigned: Mike Johnson\n\n**6:00 PM - 11:00 PM**\nOffice Lighting Retrofit - Day 2\nSarah Chen | 500 Main Street\nAssigned: Mike Johnson, Carlos Rivera\n\nYou have 2 jobs scheduled. Want me to add anything to your calendar?",
          tools: [{ name: 'getSchedule', status: 'complete' }],
        },
        revenue: {
          content: "Here's your revenue breakdown for this month:\n\n**Total Revenue:** $12,485.50\n**Total Expenses:** $4,892.30\n**Net Profit:** $7,593.20 (60.8% margin)\n\n**Compared to last month:**\n- Revenue is down 33.4% ($18,742.30 last month)\n- But profit margin improved from 52% to 61%\n\n**Top revenue sources:**\n1. Commercial jobs: $8,240 (66%)\n2. Residential: $3,450 (28%)\n3. Service calls: $795 (6%)\n\nWant me to dig deeper into any of these numbers?",
          tools: [{ name: 'getFinancials', status: 'complete' }, { name: 'calculateMetrics', status: 'complete' }],
        },
        customer: {
          content: "I found these customers matching your search:\n\n**Sarah Chen** - TechCorp\n$24,750 total revenue | 7 jobs\nEmail: sarah.chen@techcorp.com\n\n**Emily Thompson** - Property Manager\n$45,200 total revenue | 18 jobs\nEmail: emily.t@propmanage.com\n\nClick a name to view their full profile, or tell me what you need to do with their account.",
          tools: [{ name: 'searchCustomers', status: 'complete' }],
        },
        calculate: {
          content: "I can help calculate materials. What type of project are we estimating?\n\n**Common calculations I can do:**\n- Electrical load calculations\n- Wire sizing and lengths\n- Conduit fill\n- Lighting layouts\n- Panel schedules\n\nJust describe the job and I'll pull the right formulas.",
        },
      };

      const lowerInput = userMessage.content.toLowerCase();
      let response: { content: string; tools?: { name: string; status: 'complete' }[] } = {
        content: "I understand you need help with that. Could you give me a bit more detail about what you're looking for? I can help with:\n\n- Creating bids and invoices\n- Checking your schedule\n- Revenue and financial reports\n- Customer lookups\n- Material calculations\n- Code references\n\nWhat would you like to do?",
      };

      for (const [key, value] of Object.entries(responses)) {
        if (lowerInput.includes(key)) {
          response = value;
          break;
        }
      }

      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: response.content,
        timestamp: new Date(),
        tools: response.tools,
      };

      setMessages((prev) => [...prev, aiMessage]);
      setIsLoading(false);
    }, 1500);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit();
    }
  };

  const startNewChat = () => {
    setMessages([]);
    setShowHistory(false);
    inputRef.current?.focus();
  };

  const handleQuickAction = (prompt: string) => {
    setInput(prompt + ' ');
    inputRef.current?.focus();
  };

  return (
    <div className="h-[calc(100vh-8rem)] flex">
      <CommandPalette />

      {/* History Sidebar */}
      <div
        className={cn(
          'w-80 border-r border-main bg-surface flex-shrink-0 flex flex-col transition-all',
          showHistory ? 'translate-x-0' : '-ml-80 lg:ml-0 lg:translate-x-0'
        )}
      >
        <div className="p-4 border-b border-main">
          <Button onClick={startNewChat} className="w-full">
            <Plus size={16} />
            New Chat
          </Button>
        </div>
        <div className="flex-1 overflow-y-auto p-2">
          <p className="px-3 py-2 text-xs font-medium text-muted uppercase">Recent Chats</p>
          {mockAIThreads.map((thread) => (
            <button
              key={thread.id}
              className="w-full text-left px-3 py-2.5 rounded-lg hover:bg-surface-hover transition-colors"
            >
              <p className="text-sm font-medium text-main truncate">{thread.title}</p>
              <p className="text-xs text-muted mt-0.5">{formatRelativeTime(thread.lastMessageAt)}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Main Chat Area */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-main">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowHistory(!showHistory)}
              className="lg:hidden p-2 hover:bg-surface-hover rounded-lg transition-colors"
            >
              <History size={20} className="text-muted" />
            </button>
            <div className="flex items-center gap-2">
              <div className="p-2 bg-accent rounded-lg">
                <Sparkles size={20} className="text-white" />
              </div>
              <div>
                <h1 className="font-semibold text-main">Z</h1>
                <p className="text-xs text-muted">Your business assistant</p>
              </div>
            </div>
          </div>
          <Button variant="ghost" size="sm" onClick={() => router.back()}>
            <ArrowLeft size={16} />
            Back
          </Button>
        </div>

        {/* Messages Area */}
        <div className="flex-1 overflow-y-auto">
          {messages.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center p-8">
              <div className="p-4 bg-accent/10 rounded-2xl mb-6">
                <Sparkles size={48} className="text-accent" />
              </div>
              <h2 className="text-2xl font-semibold text-main mb-2">Hey, I'm Z</h2>
              <p className="text-muted text-center max-w-md mb-8">
                Your business assistant. I can help you create bids, invoices, check schedules,
                run reports, and answer questions about your business.
              </p>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-3 max-w-2xl">
                {quickActions.map((action, index) => (
                  <button
                    key={index}
                    onClick={() => handleQuickAction(action.prompt)}
                    className="flex items-center gap-3 p-4 bg-secondary hover:bg-surface-hover rounded-xl text-left transition-colors"
                  >
                    <div className="p-2 bg-accent-light rounded-lg">
                      <action.icon size={18} className="text-accent" />
                    </div>
                    <span className="text-sm font-medium text-main">{action.label}</span>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="max-w-3xl mx-auto p-6 space-y-6">
              {messages.map((message) => (
                <div
                  key={message.id}
                  className={cn(
                    'flex gap-4',
                    message.role === 'user' ? 'flex-row-reverse' : ''
                  )}
                >
                  <div
                    className={cn(
                      'w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0',
                      message.role === 'assistant'
                        ? 'bg-accent text-white'
                        : 'bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
                    )}
                  >
                    {message.role === 'assistant' ? (
                      <Sparkles size={18} />
                    ) : (
                      <User size={18} />
                    )}
                  </div>
                  <div
                    className={cn(
                      'rounded-2xl px-5 py-3.5 max-w-[80%]',
                      message.role === 'assistant'
                        ? 'bg-secondary'
                        : 'bg-accent text-white'
                    )}
                  >
                    {message.tools && message.tools.length > 0 && (
                      <div className="flex items-center gap-2 mb-2 text-xs text-muted">
                        <Zap size={12} />
                        {message.tools.map((tool, i) => (
                          <span key={i} className="px-2 py-0.5 bg-main rounded-full">
                            {tool.name}
                          </span>
                        ))}
                      </div>
                    )}
                    <div className={cn(
                      'text-sm whitespace-pre-wrap',
                      message.role === 'assistant' ? 'text-main prose prose-sm max-w-none dark:prose-invert' : ''
                    )}>
                      {message.content}
                    </div>
                  </div>
                </div>
              ))}
              {isLoading && (
                <div className="flex gap-4">
                  <div className="w-10 h-10 rounded-xl bg-accent text-white flex items-center justify-center">
                    <Sparkles size={18} />
                  </div>
                  <div className="bg-secondary rounded-2xl px-5 py-3.5">
                    <div className="flex items-center gap-2">
                      <Loader2 size={16} className="animate-spin text-muted" />
                      <span className="text-sm text-muted">Thinking...</span>
                    </div>
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}
        </div>

        {/* Input Area */}
        <div className="border-t border-main p-4">
          <form onSubmit={handleSubmit} className="max-w-3xl mx-auto">
            <div className="relative">
              <textarea
                ref={inputRef}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Ask Z anything..."
                rows={1}
                className="w-full px-5 py-4 pr-14 bg-secondary border border-main rounded-2xl text-main placeholder:text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent resize-none"
                style={{ minHeight: '56px', maxHeight: '200px' }}
                disabled={isLoading}
              />
              <button
                type="submit"
                disabled={!input.trim() || isLoading}
                className="absolute right-3 top-1/2 -translate-y-1/2 p-2.5 bg-accent text-white rounded-xl hover:bg-accent-hover disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                <Send size={18} />
              </button>
            </div>
            <p className="text-xs text-muted text-center mt-2">
              Z can make mistakes. Always verify important information.
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}
