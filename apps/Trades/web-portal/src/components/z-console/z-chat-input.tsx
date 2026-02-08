'use client';

import { useState, useRef, useCallback, useEffect } from 'react';
import { Send, Paperclip, X, File, Image, FileText } from 'lucide-react';
import type { ZSlashCommand } from '@/lib/z-intelligence/types';
import { ZSlashCommandMenu } from './z-slash-command-menu';
import { cn } from '@/lib/utils';

interface AttachedFile {
  file: File;
  preview?: string; // data URL for images
}

interface ZChatInputProps {
  onSend: (message: string, files?: File[]) => void;
  disabled?: boolean;
  compact?: boolean;
  placeholder?: string;
}

export function ZChatInput({ onSend, disabled = false, compact = false, placeholder }: ZChatInputProps) {
  const [value, setValue] = useState('');
  const [slashMenuVisible, setSlashMenuVisible] = useState(false);
  const [slashQuery, setSlashQuery] = useState('');
  const [attachedFiles, setAttachedFiles] = useState<AttachedFile[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const dragCountRef = useRef(0);

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

  const addFiles = useCallback((files: FileList | File[]) => {
    const newFiles: AttachedFile[] = [];
    for (const file of Array.from(files)) {
      const attached: AttachedFile = { file };

      // Generate preview for images
      if (file.type.startsWith('image/') && file.size < 5 * 1024 * 1024) {
        const reader = new FileReader();
        reader.onload = (e) => {
          setAttachedFiles(prev => prev.map(f =>
            f.file === file ? { ...f, preview: e.target?.result as string } : f
          ));
        };
        reader.readAsDataURL(file);
      }

      newFiles.push(attached);
    }
    setAttachedFiles(prev => [...prev, ...newFiles]);
  }, []);

  const removeFile = useCallback((index: number) => {
    setAttachedFiles(prev => prev.filter((_, i) => i !== index));
  }, []);

  const handleSend = useCallback(() => {
    const trimmed = value.trim();
    const hasFiles = attachedFiles.length > 0;
    if ((!trimmed && !hasFiles) || disabled) return;

    const message = trimmed || (hasFiles ? `[Attached ${attachedFiles.length} file(s)]` : '');
    onSend(message, hasFiles ? attachedFiles.map(f => f.file) : undefined);
    setValue('');
    setAttachedFiles([]);
    setSlashMenuVisible(false);
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  }, [value, disabled, onSend, attachedFiles]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (slashMenuVisible) return;
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

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      addFiles(e.target.files);
      e.target.value = '';
    }
  };

  // Drag & drop
  const handleDragEnter = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current++;
    if (dragCountRef.current === 1) setIsDragging(true);
  }, []);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current--;
    if (dragCountRef.current === 0) setIsDragging(false);
  }, []);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    dragCountRef.current = 0;
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      addFiles(e.dataTransfer.files);
    }
  }, [addFiles]);

  const getFileIcon = (file: File) => {
    if (file.type.startsWith('image/')) return Image;
    if (file.type.includes('pdf')) return FileText;
    return File;
  };

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  return (
    <div
      className={cn(
        'relative border-t transition-colors',
        compact ? 'px-3 py-2' : 'px-4 py-3',
        isDragging && 'bg-emerald-50/50',
      )}
      style={{ borderColor: '#e4e7ec' }}
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
    >
      <input
        ref={fileInputRef}
        type="file"
        multiple
        className="hidden"
        onChange={handleFileInput}
      />

      <ZSlashCommandMenu
        query={slashQuery}
        visible={slashMenuVisible}
        onSelect={handleSlashSelect}
        onClose={() => setSlashMenuVisible(false)}
      />

      {/* Drag overlay indicator */}
      {isDragging && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-emerald-50/80 border-2 border-dashed border-emerald-400 rounded-lg pointer-events-none">
          <span className="text-[13px] font-medium text-emerald-700">Drop files to attach</span>
        </div>
      )}

      {/* Attached files preview */}
      {attachedFiles.length > 0 && (
        <div className="flex flex-wrap gap-1.5 mb-2">
          {attachedFiles.map((af, i) => {
            const Icon = getFileIcon(af.file);
            return (
              <div
                key={`${af.file.name}-${i}`}
                className="flex items-center gap-1.5 px-2 py-1 rounded-md bg-gray-100 text-[11px] text-gray-700 max-w-[180px] group"
              >
                {af.preview ? (
                  <img src={af.preview} alt="" className="w-5 h-5 rounded object-cover flex-shrink-0" />
                ) : (
                  <Icon size={12} className="text-gray-400 flex-shrink-0" />
                )}
                <span className="truncate flex-1">{af.file.name}</span>
                <span className="text-gray-400">{formatSize(af.file.size)}</span>
                <button
                  onClick={() => removeFile(i)}
                  className="p-0.5 rounded hover:bg-gray-200 transition-colors opacity-60 hover:opacity-100"
                >
                  <X size={10} />
                </button>
              </div>
            );
          })}
        </div>
      )}

      <div className="flex items-end gap-2">
        {/* Attach button */}
        <button
          onClick={() => fileInputRef.current?.click()}
          className="flex-shrink-0 p-2 rounded-lg text-muted hover:text-main hover:bg-surface-hover transition-colors"
          title="Attach file"
        >
          <Paperclip size={compact ? 14 : 16} />
        </button>

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
          disabled={disabled || (!value.trim() && attachedFiles.length === 0)}
          className={cn(
            'flex-shrink-0 rounded-lg p-2 transition-colors',
            (value.trim() || attachedFiles.length > 0)
              ? 'bg-accent text-white hover:bg-accent/90'
              : 'bg-secondary text-muted cursor-not-allowed',
          )}
        >
          <Send size={compact ? 14 : 16} />
        </button>
      </div>

      {!compact && (
        <div className="flex items-center justify-between mt-1.5">
          <span className="text-[10px] text-muted">/ for commands  |  Drop files to attach</span>
          <span className="text-[10px] text-muted">Enter to send</span>
        </div>
      )}
    </div>
  );
}
