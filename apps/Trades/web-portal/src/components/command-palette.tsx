'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { useRouter } from 'next/navigation';
import {
  Search,
  LayoutDashboard,
  FileText,
  Briefcase,
  Receipt,
  Calendar,
  Users,
  Settings,
  Plus,
  Calculator,
  DollarSign,
  X,
  ArrowRight,
} from 'lucide-react';
import { ZMark } from '@/components/z-console/z-mark';
import { cn } from '@/lib/utils';

interface Command {
  id: string;
  title: string;
  subtitle?: string;
  icon: React.ReactNode;
  shortcut?: string[];
  action: () => void;
  category: 'navigation' | 'actions' | 'ai';
}

export function CommandPalette() {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  const commands: Command[] = [
    // Navigation
    {
      id: 'nav-dashboard',
      title: 'Dashboard',
      subtitle: 'Go to dashboard',
      icon: <LayoutDashboard size={18} />,
      shortcut: ['G', 'D'],
      action: () => router.push('/dashboard'),
      category: 'navigation',
    },
    {
      id: 'nav-bids',
      title: 'Bids',
      subtitle: 'Manage bids',
      icon: <FileText size={18} />,
      shortcut: ['G', 'B'],
      action: () => router.push('/dashboard/bids'),
      category: 'navigation',
    },
    {
      id: 'nav-jobs',
      title: 'Jobs',
      subtitle: 'Manage jobs',
      icon: <Briefcase size={18} />,
      shortcut: ['G', 'J'],
      action: () => router.push('/dashboard/jobs'),
      category: 'navigation',
    },
    {
      id: 'nav-invoices',
      title: 'Invoices',
      subtitle: 'Manage invoices',
      icon: <Receipt size={18} />,
      shortcut: ['G', 'I'],
      action: () => router.push('/dashboard/invoices'),
      category: 'navigation',
    },
    {
      id: 'nav-calendar',
      title: 'Calendar',
      subtitle: 'View schedule',
      icon: <Calendar size={18} />,
      shortcut: ['G', 'C'],
      action: () => router.push('/dashboard/calendar'),
      category: 'navigation',
    },
    {
      id: 'nav-customers',
      title: 'Customers',
      subtitle: 'Manage customers',
      icon: <Users size={18} />,
      shortcut: ['G', 'U'],
      action: () => router.push('/dashboard/customers'),
      category: 'navigation',
    },
    {
      id: 'nav-team',
      title: 'Team',
      subtitle: 'Manage team members',
      icon: <Users size={18} />,
      action: () => router.push('/dashboard/team'),
      category: 'navigation',
    },
    {
      id: 'nav-books',
      title: 'Zafto Books',
      subtitle: 'View finances',
      icon: <DollarSign size={18} />,
      action: () => router.push('/dashboard/books'),
      category: 'navigation',
    },
    {
      id: 'nav-settings',
      title: 'Settings',
      subtitle: 'Configure settings',
      icon: <Settings size={18} />,
      shortcut: ['G', 'S'],
      action: () => router.push('/dashboard/settings'),
      category: 'navigation',
    },

    // Actions
    {
      id: 'action-new-bid',
      title: 'Create Bid',
      subtitle: 'Start a new bid',
      icon: <Plus size={18} />,
      shortcut: ['N', 'B'],
      action: () => router.push('/dashboard/bids/new'),
      category: 'actions',
    },
    {
      id: 'action-new-job',
      title: 'Create Job',
      subtitle: 'Start a new job',
      icon: <Plus size={18} />,
      shortcut: ['N', 'J'],
      action: () => router.push('/dashboard/jobs/new'),
      category: 'actions',
    },
    {
      id: 'action-new-invoice',
      title: 'Create Invoice',
      subtitle: 'Create a new invoice',
      icon: <Plus size={18} />,
      shortcut: ['N', 'I'],
      action: () => router.push('/dashboard/invoices/new'),
      category: 'actions',
    },
    {
      id: 'action-new-customer',
      title: 'Add Customer',
      subtitle: 'Add a new customer',
      icon: <Plus size={18} />,
      shortcut: ['N', 'C'],
      action: () => router.push('/dashboard/customers/new'),
      category: 'actions',
    },
    {
      id: 'action-calculator',
      title: 'Calculator',
      subtitle: 'Open calculator',
      icon: <Calculator size={18} />,
      action: () => router.push('/dashboard/calculator'),
      category: 'actions',
    },

    // AI
    {
      id: 'ai-chat',
      title: 'Z',
      subtitle: 'Ask Z anything',
      icon: <ZMark size={18} />,
      shortcut: ['Z'],
      action: () => window.dispatchEvent(new CustomEvent('zConsoleToggle')),
      category: 'ai',
    },
  ];

  const filteredCommands = search
    ? commands.filter(
        (cmd) =>
          cmd.title.toLowerCase().includes(search.toLowerCase()) ||
          cmd.subtitle?.toLowerCase().includes(search.toLowerCase())
      )
    : commands;

  const groupedCommands = {
    ai: filteredCommands.filter((c) => c.category === 'ai'),
    actions: filteredCommands.filter((c) => c.category === 'actions'),
    navigation: filteredCommands.filter((c) => c.category === 'navigation'),
  };

  const flatFilteredCommands = [
    ...groupedCommands.ai,
    ...groupedCommands.actions,
    ...groupedCommands.navigation,
  ];

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      // Open with Cmd+K or Ctrl+K
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsOpen((prev) => !prev);
        return;
      }

      if (!isOpen) return;

      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          setSelectedIndex((prev) =>
            prev < flatFilteredCommands.length - 1 ? prev + 1 : 0
          );
          break;
        case 'ArrowUp':
          e.preventDefault();
          setSelectedIndex((prev) =>
            prev > 0 ? prev - 1 : flatFilteredCommands.length - 1
          );
          break;
        case 'Enter':
          e.preventDefault();
          if (flatFilteredCommands[selectedIndex]) {
            flatFilteredCommands[selectedIndex].action();
            setIsOpen(false);
            setSearch('');
          }
          break;
        case 'Escape':
          e.preventDefault();
          setIsOpen(false);
          setSearch('');
          break;
      }
    },
    [isOpen, flatFilteredCommands, selectedIndex]
  );

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  useEffect(() => {
    if (isOpen) {
      inputRef.current?.focus();
      setSelectedIndex(0);
    }
  }, [isOpen]);

  useEffect(() => {
    setSelectedIndex(0);
  }, [search]);

  if (!isOpen) return null;

  return (
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 z-50"
        onClick={() => {
          setIsOpen(false);
          setSearch('');
        }}
      />

      {/* Modal */}
      <div className="fixed top-[20%] left-1/2 -translate-x-1/2 w-full max-w-xl z-50">
        <div className="bg-surface border border-main rounded-xl shadow-2xl overflow-hidden">
          {/* Search Input */}
          <div className="flex items-center gap-3 px-4 py-3 border-b border-main">
            <Search size={18} className="text-muted" />
            <input
              ref={inputRef}
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Type a command or search..."
              className="flex-1 bg-transparent text-main placeholder:text-muted outline-none text-sm"
            />
            <button
              onClick={() => {
                setIsOpen(false);
                setSearch('');
              }}
              className="text-muted hover:text-main"
            >
              <X size={18} />
            </button>
          </div>

          {/* Results */}
          <div className="max-h-80 overflow-y-auto py-2">
            {flatFilteredCommands.length === 0 ? (
              <div className="px-4 py-8 text-center text-muted">
                No results found
              </div>
            ) : (
              <>
                {/* AI Section */}
                {groupedCommands.ai.length > 0 && (
                  <CommandGroup
                    title="Z"
                    commands={groupedCommands.ai}
                    selectedIndex={selectedIndex}
                    onSelect={(cmd) => {
                      cmd.action();
                      setIsOpen(false);
                      setSearch('');
                    }}
                    startIndex={0}
                  />
                )}

                {/* Actions Section */}
                {groupedCommands.actions.length > 0 && (
                  <CommandGroup
                    title="Actions"
                    commands={groupedCommands.actions}
                    selectedIndex={selectedIndex}
                    onSelect={(cmd) => {
                      cmd.action();
                      setIsOpen(false);
                      setSearch('');
                    }}
                    startIndex={groupedCommands.ai.length}
                  />
                )}

                {/* Navigation Section */}
                {groupedCommands.navigation.length > 0 && (
                  <CommandGroup
                    title="Navigation"
                    commands={groupedCommands.navigation}
                    selectedIndex={selectedIndex}
                    onSelect={(cmd) => {
                      cmd.action();
                      setIsOpen(false);
                      setSearch('');
                    }}
                    startIndex={groupedCommands.ai.length + groupedCommands.actions.length}
                  />
                )}
              </>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-between px-4 py-2 border-t border-main bg-secondary/50 text-xs text-muted">
            <div className="flex items-center gap-4">
              <span className="flex items-center gap-1">
                <kbd className="px-1.5 py-0.5 bg-main border border-main rounded">↑↓</kbd>
                navigate
              </span>
              <span className="flex items-center gap-1">
                <kbd className="px-1.5 py-0.5 bg-main border border-main rounded">↵</kbd>
                select
              </span>
              <span className="flex items-center gap-1">
                <kbd className="px-1.5 py-0.5 bg-main border border-main rounded">esc</kbd>
                close
              </span>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

interface CommandGroupProps {
  title: string;
  commands: Command[];
  selectedIndex: number;
  onSelect: (cmd: Command) => void;
  startIndex: number;
}

function CommandGroup({ title, commands, selectedIndex, onSelect, startIndex }: CommandGroupProps) {
  return (
    <div>
      <div className="px-4 py-1.5 text-xs font-medium text-muted uppercase tracking-wider">
        {title}
      </div>
      {commands.map((cmd, index) => {
        const globalIndex = startIndex + index;
        const isSelected = globalIndex === selectedIndex;

        return (
          <button
            key={cmd.id}
            onClick={() => onSelect(cmd)}
            className={cn(
              'w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors',
              isSelected
                ? 'bg-accent-light text-accent'
                : 'text-main hover:bg-surface-hover'
            )}
          >
            <span className={isSelected ? 'text-accent' : 'text-muted'}>
              {cmd.icon}
            </span>
            <div className="flex-1 min-w-0">
              <div className="font-medium">{cmd.title}</div>
              {cmd.subtitle && (
                <div className="text-xs text-muted truncate">{cmd.subtitle}</div>
              )}
            </div>
            {cmd.shortcut && (
              <div className="flex items-center gap-1">
                {cmd.shortcut.map((key, i) => (
                  <kbd
                    key={i}
                    className="px-1.5 py-0.5 text-xs bg-main border border-main rounded"
                  >
                    {key}
                  </kbd>
                ))}
              </div>
            )}
            {isSelected && <ArrowRight size={14} className="text-accent" />}
          </button>
        );
      })}
    </div>
  );
}
