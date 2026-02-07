'use client';

import { useEffect } from 'react';
import { ZMark } from '@/components/z-console/z-mark';
import { useZConsole } from '@/components/z-console';
import { CommandPalette } from '@/components/command-palette';

export default function ZAIPage() {
  const { setConsoleState, consoleState } = useZConsole();

  // Auto-open the persistent console when visiting this page
  useEffect(() => {
    if (consoleState === 'collapsed') {
      setConsoleState('open');
    }
  }, [consoleState, setConsoleState]);

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
        <div className="w-16 h-16 rounded-2xl bg-accent/10 flex items-center justify-center mb-6">
          <ZMark size={32} className="text-accent" />
        </div>
        <h1 className="text-2xl font-semibold text-main mb-2">Z Intelligence</h1>
        <p className="text-muted max-w-md text-[14px] leading-relaxed">
          Z is always available from any page. Use the chat panel on the right, or press{' '}
          <kbd className="px-1.5 py-0.5 bg-secondary border border-main rounded text-[12px] font-mono">
            Ctrl+J
          </kbd>{' '}
          to toggle it from anywhere.
        </p>
      </div>
    </div>
  );
}
