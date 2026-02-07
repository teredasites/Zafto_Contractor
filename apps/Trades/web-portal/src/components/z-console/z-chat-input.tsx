'use client';

import { useState, useRef, useCallback, useEffect } from 'react';
import { Send } from 'lucide-react';
import type { ZSlashCommand } from '@/lib/z-intelligence/types';
import { ZSlashCommandMenu } from './z-slash-command-menu';
import { cn } from '@/lib/utils';

interface ZChatInputProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  compact?: boolean;
  placeholder?: string;
}

export function ZChatInput({ onSend, disabled = false, compact = false, placeholder }: ZChatInputProps) {
  const [value, setValue] = useState('');
  const [slashMenuVisible, setSlashMenuVisible] = useState(false);
  const [slashQuery, setSlashQuery] = useState('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const adjustHeight = useCallback(() => {
    const el = textareaRef.current;
    if (!el) return;
    el.style.height = 'auto';
    const maxRows = compact ? 3 : 5;
    const lineHeight = 22;
    const maxHeight = maxRows * lineHeight;
    el.style.height = `${Math.min(el.scrollHeight, maxHeight)}px`;
  }, [compact]);

  useEffect(() => {
    adjustHeight();
  }, [value, adjustHeight]);

  const handleSend = useCallback(() => {
    const trimmed = value.trim();
    if (!trimmed || disabled) return;
    onSend(trimmed);
    setValue('');
    setSlashMenuVisible(false);
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  }, [value, disabled, onSend]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (slashMenuVisible) return; // let slash menu handle it
    if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      handleSend();
    }
    if (e.key === 'Enter' && !e.shiftKey && !e.metaKey && !e.ctrlKey) {
      e.preventDefault();
      handleSend();
    }
  }, [handleSend, slashMenuVisible]);

  const handleChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const val = e.target.value;
    setValue(val);

    // Slash command detection
    if (val.startsWith('/')) {
      setSlashQuery(val);
      setSlashMenuVisible(true);
    } else {
      setSlashMenuVisible(false);
      setSlashQuery('');
    }
  }, []);

  const handleSlashSelect = useCallback((cmd: ZSlashCommand) => {
    setValue('');
    setSlashMenuVisible(false);
    setSlashQuery('');
    onSend(cmd.command);
  }, [onSend]);

  return (
    <div className={cn('relative border-t', compact ? 'px-3 py-2' : 'px-4 py-3')} style={{ borderColor: '#e4e7ec' }}>
      <ZSlashCommandMenu
        query={slashQuery}
        visible={slashMenuVisible}
        onSelect={handleSlashSelect}
        onClose={() => setSlashMenuVisible(false)}
      />

      <div className="flex items-end gap-2">
        <textarea
          ref={textareaRef}
          value={value}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          placeholder={placeholder || 'Ask Z anything... (/ for commands)'}
          disabled={disabled}
          rows={1}
          className={cn(
            'flex-1 resize-none bg-transparent text-main placeholder:text-muted outline-none',
            compact ? 'text-[13px]' : 'text-[14px]',
          )}
          style={{ lineHeight: '22px' }}
        />
        <button
          onClick={handleSend}
          disabled={disabled || !value.trim()}
          className={cn(
            'flex-shrink-0 rounded-lg p-2 transition-colors',
            value.trim()
              ? 'bg-accent text-white hover:bg-accent/90'
              : 'bg-secondary text-muted cursor-not-allowed',
          )}
        >
          <Send size={compact ? 14 : 16} />
        </button>
      </div>

      {!compact && (
        <div className="flex items-center justify-between mt-1.5">
          <span className="text-[10px] text-muted">/ for commands</span>
          <span className="text-[10px] text-muted">Enter to send</span>
        </div>
      )}
    </div>
  );
}
