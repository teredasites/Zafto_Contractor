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
  Target,
  Satellite,
  PenTool,
  BarChart3,
  Truck,
  Shield,
  Building2,
  Wrench,
  MessageSquare,
  Clock,
  Umbrella,
  Loader2,
  Home,
  FolderOpen,
} from 'lucide-react';
import { ZMark } from '@/components/z-console/z-mark';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';

interface Command {
  id: string;
  title: string;
  subtitle?: string;
  icon: React.ReactNode;
  shortcut?: string[];
  action: () => void;
  category: 'navigation' | 'actions' | 'ai' | 'results';
  badge?: string;
}

// Entity search across all major tables
async function searchEntities(query: string): Promise<Command[]> {
  if (!query || query.length < 2) return [];
  const supabase = getSupabase();
  const q = `%${query}%`;
  const results: Command[] = [];

  const [jobs, customers, estimates, invoices, properties, leads, docs] = await Promise.allSettled([
    supabase.from('jobs').select('id, title, customer_name, status').ilike('title', q).is('deleted_at', null).limit(3),
    supabase.from('customers').select('id, first_name, last_name, email, company_name').or(`first_name.ilike.${q},last_name.ilike.${q},email.ilike.${q},company_name.ilike.${q}`).is('deleted_at', null).limit(3),
    supabase.from('estimates').select('id, title, customer_name, status').ilike('title', q).is('deleted_at', null).limit(3),
    supabase.from('invoices').select('id, invoice_number, customer_name, status').or(`invoice_number.ilike.${q},customer_name.ilike.${q}`).is('deleted_at', null).limit(3),
    supabase.from('properties').select('id, name, address').or(`name.ilike.${q},address.ilike.${q}`).is('deleted_at', null).limit(3),
    supabase.from('leads').select('id, name, email, stage').or(`name.ilike.${q},email.ilike.${q}`).is('deleted_at', null).limit(3),
    supabase.from('documents').select('id, name, document_type').ilike('name', q).is('deleted_at', null).limit(3),
  ]);

  if (jobs.status === 'fulfilled' && jobs.value.data) {
    for (const j of jobs.value.data) {
      results.push({ id: `search-job-${j.id}`, title: j.title || 'Untitled Job', subtitle: j.customer_name || j.status, icon: <Briefcase size={18} />, action: () => {}, category: 'results', badge: 'Job' });
    }
  }
  if (customers.status === 'fulfilled' && customers.value.data) {
    for (const c of customers.value.data) {
      results.push({ id: `search-cust-${c.id}`, title: `${c.first_name || ''} ${c.last_name || ''}`.trim() || c.company_name || 'Customer', subtitle: c.email || c.company_name || '', icon: <Users size={18} />, action: () => {}, category: 'results', badge: 'Customer' });
    }
  }
  if (estimates.status === 'fulfilled' && estimates.value.data) {
    for (const e of estimates.value.data) {
      results.push({ id: `search-est-${e.id}`, title: e.title || 'Untitled Estimate', subtitle: e.customer_name || e.status, icon: <FileText size={18} />, action: () => {}, category: 'results', badge: 'Estimate' });
    }
  }
  if (invoices.status === 'fulfilled' && invoices.value.data) {
    for (const inv of invoices.value.data) {
      results.push({ id: `search-inv-${inv.id}`, title: inv.invoice_number || 'Invoice', subtitle: inv.customer_name || inv.status, icon: <Receipt size={18} />, action: () => {}, category: 'results', badge: 'Invoice' });
    }
  }
  if (properties.status === 'fulfilled' && properties.value.data) {
    for (const p of properties.value.data) {
      results.push({ id: `search-prop-${p.id}`, title: p.name || p.address || 'Property', subtitle: p.address || '', icon: <Home size={18} />, action: () => {}, category: 'results', badge: 'Property' });
    }
  }
  if (leads.status === 'fulfilled' && leads.value.data) {
    for (const l of leads.value.data) {
      results.push({ id: `search-lead-${l.id}`, title: l.name || 'Lead', subtitle: l.email || l.stage, icon: <Target size={18} />, action: () => {}, category: 'results', badge: 'Lead' });
    }
  }
  if (docs.status === 'fulfilled' && docs.value.data) {
    for (const d of docs.value.data) {
      results.push({ id: `search-doc-${d.id}`, title: d.name || 'Document', subtitle: d.document_type || '', icon: <FolderOpen size={18} />, action: () => {}, category: 'results', badge: 'Document' });
    }
  }
  return results;
}

export function CommandPalette() {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [searchResults, setSearchResults] = useState<Command[]>([]);
  const [searching, setSearching] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  const searchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
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
    {
      id: 'nav-leads',
      title: 'Leads',
      subtitle: 'Manage leads',
      icon: <Target size={18} />,
      action: () => router.push('/dashboard/leads'),
      category: 'navigation',
    },
    {
      id: 'nav-estimates',
      title: 'Estimates',
      subtitle: 'Manage estimates',
      icon: <FileText size={18} />,
      action: () => router.push('/dashboard/estimates'),
      category: 'navigation',
    },
    {
      id: 'nav-recon',
      title: 'Property Recon',
      subtitle: 'Scan properties for measurements',
      icon: <Satellite size={18} />,
      shortcut: ['G', 'R'],
      action: () => router.push('/dashboard/recon'),
      category: 'navigation',
    },
    {
      id: 'nav-sketch',
      title: 'Sketch Engine',
      subtitle: 'CAD floor plans and estimates',
      icon: <PenTool size={18} />,
      shortcut: ['G', 'K'],
      action: () => router.push('/dashboard/sketch-engine'),
      category: 'navigation',
    },
    {
      id: 'nav-reports',
      title: 'Reports',
      subtitle: 'View reports',
      icon: <BarChart3 size={18} />,
      action: () => router.push('/dashboard/reports'),
      category: 'navigation',
    },
    {
      id: 'nav-dispatch',
      title: 'Dispatch',
      subtitle: 'Dispatch technicians',
      icon: <Truck size={18} />,
      action: () => router.push('/dashboard/dispatch'),
      category: 'navigation',
    },
    {
      id: 'nav-permits',
      title: 'Permits',
      subtitle: 'Track permits and inspections',
      icon: <Shield size={18} />,
      action: () => router.push('/dashboard/permits'),
      category: 'navigation',
    },
    {
      id: 'nav-insurance',
      title: 'Insurance Claims',
      subtitle: 'Manage insurance claims',
      icon: <Umbrella size={18} />,
      action: () => router.push('/dashboard/insurance'),
      category: 'navigation',
    },
    {
      id: 'nav-properties',
      title: 'Properties',
      subtitle: 'Manage rental properties',
      icon: <Building2 size={18} />,
      action: () => router.push('/dashboard/properties'),
      category: 'navigation',
    },
    {
      id: 'nav-equipment',
      title: 'Equipment',
      subtitle: 'Track equipment and tools',
      icon: <Wrench size={18} />,
      action: () => router.push('/dashboard/equipment'),
      category: 'navigation',
    },
    {
      id: 'nav-communications',
      title: 'Communications',
      subtitle: 'Messages, calls, and emails',
      icon: <MessageSquare size={18} />,
      action: () => router.push('/dashboard/communications'),
      category: 'navigation',
    },
    {
      id: 'nav-timeclock',
      title: 'Time Clock',
      subtitle: 'Employee time tracking',
      icon: <Clock size={18} />,
      action: () => router.push('/dashboard/time-clock'),
      category: 'navigation',
    },
    {
      id: 'nav-documents',
      title: 'Documents',
      subtitle: 'File management',
      icon: <FileText size={18} />,
      action: () => router.push('/dashboard/documents'),
      category: 'navigation',
    },
    {
      id: 'nav-subcontractors',
      title: 'Subcontractors',
      subtitle: 'Manage subcontractors',
      icon: <Users size={18} />,
      action: () => router.push('/dashboard/subcontractors'),
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
    {
      id: 'action-new-lead',
      title: 'Add Lead',
      subtitle: 'Create a new lead',
      icon: <Plus size={18} />,
      shortcut: ['N', 'L'],
      action: () => router.push('/dashboard/leads/new'),
      category: 'actions',
    },
    {
      id: 'action-scan-property',
      title: 'Scan Property',
      subtitle: 'Run a property recon scan',
      icon: <Satellite size={18} />,
      action: () => router.push('/dashboard/recon'),
      category: 'actions',
    },
    {
      id: 'action-new-floorplan',
      title: 'New Floor Plan',
      subtitle: 'Start a new sketch',
      icon: <PenTool size={18} />,
      action: () => router.push('/dashboard/sketch-engine'),
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

  // Debounced entity search
  useEffect(() => {
    if (!isOpen || search.length < 2) {
      setSearchResults([]);
      setSearching(false);
      return;
    }
    setSearching(true);
    if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    searchTimerRef.current = setTimeout(async () => {
      try {
        const raw = await searchEntities(search);
        // Patch in router actions now that we have access
        const patched = raw.map(r => {
          const id = r.id.split('-').slice(2).join('-');
          const type = r.id.split('-')[1]; // job, cust, est, inv, prop, lead, doc
          const routes: Record<string, string> = {
            job: `/dashboard/jobs/${id}`,
            cust: `/dashboard/customers/${id}`,
            est: `/dashboard/estimates/${id}`,
            inv: `/dashboard/invoices/${id}`,
            prop: `/dashboard/properties/${id}`,
            lead: `/dashboard/leads`,
            doc: `/dashboard/documents`,
          };
          return { ...r, action: () => router.push(routes[type] || '/dashboard') };
        });
        setSearchResults(patched);
      } catch {
        setSearchResults([]);
      } finally {
        setSearching(false);
      }
    }, 300);
    return () => { if (searchTimerRef.current) clearTimeout(searchTimerRef.current); };
  }, [search, isOpen, router]);

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
    results: searchResults,
  };

  const flatFilteredCommands = [
    ...groupedCommands.results,
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
                {/* Search Results Section */}
                {searching && (
                  <div className="flex items-center gap-2 px-4 py-3 text-muted text-sm">
                    <Loader2 size={14} className="animate-spin" /> Searching...
                  </div>
                )}
                {groupedCommands.results.length > 0 && (
                  <CommandGroup
                    title="Search Results"
                    commands={groupedCommands.results}
                    selectedIndex={selectedIndex}
                    onSelect={(cmd) => {
                      cmd.action();
                      setIsOpen(false);
                      setSearch('');
                    }}
                    startIndex={0}
                  />
                )}

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
                    startIndex={groupedCommands.results.length}
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
                    startIndex={groupedCommands.results.length + groupedCommands.ai.length}
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
                    startIndex={groupedCommands.results.length + groupedCommands.ai.length + groupedCommands.actions.length}
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
              <div className="flex items-center gap-2">
                <span className="font-medium">{cmd.title}</span>
                {cmd.badge && (
                  <span className="px-1.5 py-0.5 text-[10px] font-medium rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">
                    {cmd.badge}
                  </span>
                )}
              </div>
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
