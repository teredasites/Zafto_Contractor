'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Keyboard, ArrowLeft } from 'lucide-react';
import { useTranslation } from '@/lib/translations';

interface ShortcutGroup {
  title: string;
  shortcuts: { keys: string[]; description: string }[];
}

const shortcutGroups: ShortcutGroup[] = [
  {
    title: 'Navigation',
    shortcuts: [
      { keys: ['Ctrl', 'K'], description: 'Open command palette / search' },
      { keys: ['Ctrl', 'J'], description: 'Toggle Z Intelligence' },
      { keys: ['?'], description: 'Open keyboard shortcuts' },
      { keys: ['Esc'], description: 'Close modal / dropdown / panel' },
    ],
  },
  {
    title: 'Quick Actions',
    shortcuts: [
      { keys: ['Ctrl', 'N'], description: 'New job' },
      { keys: ['Ctrl', 'B'], description: 'New bid' },
      { keys: ['Ctrl', 'I'], description: 'New invoice' },
      { keys: ['Ctrl', 'E'], description: 'New estimate' },
    ],
  },
  {
    title: 'Views',
    shortcuts: [
      { keys: ['G', 'D'], description: 'Go to Dashboard' },
      { keys: ['G', 'J'], description: 'Go to Jobs' },
      { keys: ['G', 'C'], description: 'Go to Customers' },
      { keys: ['G', 'B'], description: 'Go to Bids' },
      { keys: ['G', 'I'], description: 'Go to Invoices' },
      { keys: ['G', 'S'], description: 'Go to Settings' },
    ],
  },
  {
    title: 'Accessibility',
    shortcuts: [
      { keys: ['Tab'], description: 'Move to next focusable element' },
      { keys: ['Shift', 'Tab'], description: 'Move to previous focusable element' },
      { keys: ['Enter'], description: 'Activate focused button / link' },
      { keys: ['Space'], description: 'Toggle checkbox / switch' },
      { keys: ['Arrow keys'], description: 'Navigate within menus / dropdowns' },
    ],
  },
];

export default function KeyboardShortcutsPage() {
  const { t } = useTranslation();
  const router = useRouter();

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        router.back();
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [router]);

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center gap-3 mb-8">
        <button
          onClick={() => router.back()}
          className="p-2 rounded-lg text-muted hover:text-main hover:bg-surface-hover transition-colors"
          aria-label={t('common.goBack')}
        >
          <ArrowLeft size={20} />
        </button>
        <div className="flex items-center gap-2">
          <Keyboard size={20} className="text-muted" />
          <h1 className="text-xl font-semibold text-main">{t('keyboardShortcuts.title')}</h1>
        </div>
      </div>

      <p className="text-sm text-muted mb-6">
        Press <kbd className="px-1.5 py-0.5 text-xs bg-secondary border border-main rounded">?</kbd> anywhere to open this page.
        Press <kbd className="px-1.5 py-0.5 text-xs bg-secondary border border-main rounded">{t('keyboardShortcuts.esc')}</kbd> to go back.
      </p>

      <div className="space-y-8">
        {shortcutGroups.map((group) => (
          <section key={group.title} aria-labelledby={`group-${group.title.toLowerCase()}`}>
            <h2
              id={`group-${group.title.toLowerCase()}`}
              className="text-[11px] font-semibold uppercase tracking-[0.08em] text-muted mb-3"
            >
              {group.title}
            </h2>
            <div className="bg-surface border border-main rounded-xl overflow-hidden divide-y divide-main">
              {group.shortcuts.map((shortcut, i) => (
                <div key={i} className="flex items-center justify-between px-4 py-3">
                  <span className="text-sm text-main">{shortcut.description}</span>
                  <div className="flex items-center gap-1">
                    {shortcut.keys.map((key, ki) => (
                      <span key={ki}>
                        <kbd className="inline-flex items-center justify-center min-w-[28px] h-7 px-2 text-xs font-medium text-muted bg-main border border-main rounded-md shadow-sm">
                          {key}
                        </kbd>
                        {ki < shortcut.keys.length - 1 && (
                          <span className="text-xs text-muted mx-0.5">+</span>
                        )}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </section>
        ))}
      </div>

      <p className="text-xs text-muted mt-8 text-center">
        Not all shortcuts may be available on every page. Some shortcuts require the command palette to be closed.
      </p>
    </div>
  );
}
