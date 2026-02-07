'use client';

import { useEffect, useState, useCallback } from 'react';
import {
  FileText, Receipt, BarChart3, TrendingUp, Calendar, Users,
} from 'lucide-react';
import type { ZSlashCommand } from '@/lib/z-intelligence/types';
import { SLASH_COMMANDS } from '@/lib/z-intelligence/slash-commands';
import { cn } from '@/lib/utils';

const ICON_MAP: Record<string, React.ComponentType<{ size?: number; className?: string }>> = {
  FileText, Receipt, BarChart3, TrendingUp, Calendar, Users,
};

interface ZSlashCommandMenuProps {
  query: string;
  visible: boolean;
  onSelect: (command: ZSlashCommand) => void;
  onClose: () => void;
}

export function ZSlashCommandMenu({ query, visible, onSelect, onClose }: ZSlashCommandMenuProps) {
  const [selectedIndex, setSelectedIndex] = useState(0);

  const filtered = SLASH_COMMANDS.filter(cmd =>
    cmd.command.toLowerCase().startsWith(query.toLowerCase()) ||
    cmd.label.toLowerCase().includes(query.replace('/', '').toLowerCase())
  );

  useEffect(() => {
    setSelectedIndex(0);
  }, [query]);

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (!visible) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex(prev => (prev + 1) % filtered.length);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex(prev => (prev - 1 + filtered.length) % filtered.length);
    } else if (e.key === 'Enter' && filtered.length > 0) {
      e.preventDefault();
      onSelect(filtered[selectedIndex]);
    } else if (e.key === 'Escape') {
      e.preventDefault();
      onClose();
    }
  }, [visible, filtered, selectedIndex, onSelect, onClose]);

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [handleKeyDown]);

  if (!visible || filtered.length === 0) return null;

  return (
    <div className="absolute bottom-full left-0 right-0 mb-1 mx-3 bg-surface border border-main rounded-lg shadow-lg overflow-hidden z-10 animate-fade-in">
      {filtered.map((cmd, i) => {
        const Icon = ICON_MAP[cmd.icon];
        return (
          <button
            key={cmd.command}
            onClick={() => onSelect(cmd)}
            className={cn(
              'flex items-center gap-3 w-full px-3 py-2.5 text-left transition-colors',
              i === selectedIndex ? 'bg-accent-light' : 'hover:bg-surface-hover',
            )}
          >
            <div className="w-8 h-8 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
              {Icon && <Icon size={16} className="text-accent" />}
            </div>
            <div className="min-w-0">
              <div className="text-[13px] font-medium text-main">{cmd.command}</div>
              <div className="text-[11px] text-muted truncate">{cmd.description}</div>
            </div>
          </button>
        );
      })}
    </div>
  );
}
