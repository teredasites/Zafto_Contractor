'use client';

import { Check, X, Save, PanelRightClose } from 'lucide-react';
import type { ZArtifact } from '@/lib/z-intelligence/types';
import { cn } from '@/lib/utils';

interface ZArtifactToolbarProps {
  artifact: ZArtifact;
  onApprove: () => void;
  onReject: () => void;
  onSaveDraft: () => void;
  onVersionSelect: (version: number) => void;
  onClose: () => void;
}

const STATUS_LABELS: Record<string, { label: string; className: string }> = {
  generating: { label: 'Generating...', className: 'bg-accent-light text-accent' },
  ready: { label: 'Ready for Review', className: 'bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-400' },
  approved: { label: 'Approved', className: 'bg-emerald-50 text-emerald-700' },
  rejected: { label: 'Rejected', className: 'bg-red-50 text-red-600' },
  draft: { label: 'Draft', className: 'bg-secondary text-muted' },
};

export function ZArtifactToolbar({
  artifact,
  onApprove,
  onReject,
  onSaveDraft,
  onVersionSelect,
  onClose,
}: ZArtifactToolbarProps) {
  const status = STATUS_LABELS[artifact.status] || STATUS_LABELS.draft;

  return (
    <div className="flex items-center justify-between px-4 py-3 border-b" style={{ borderColor: '#e4e7ec' }}>
      {/* Left: close + title + status */}
      <div className="flex items-center gap-3 min-w-0">
        {/* Close button — prominent, filled */}
        <button
          onClick={onClose}
          className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-[12px] font-medium
            border transition-colors flex-shrink-0
            hover:bg-gray-100 dark:hover:bg-gray-800"
          style={{ borderColor: '#d0d5dd', color: '#344054' }}
          title="Close artifact"
        >
          <PanelRightClose size={15} />
          <span>Close</span>
        </button>

        <div className="min-w-0">
          <div className="text-[14px] font-semibold truncate" style={{ color: '#0a1628' }}>
            {artifact.title}
          </div>
          <div className="flex items-center gap-2 mt-0.5">
            <span className={cn('inline-flex px-2 py-0.5 rounded-full text-[11px] font-medium', status.className)}>
              {status.label}
            </span>

            {/* Version tabs */}
            {artifact.versions.length > 1 && (
              <div className="flex items-center gap-0.5">
                {artifact.versions.map((v) => (
                  <button
                    key={v.version}
                    onClick={() => onVersionSelect(v.version)}
                    className={cn(
                      'px-2 py-0.5 rounded text-[11px] font-medium transition-colors',
                      v.version === artifact.currentVersion
                        ? 'bg-gray-200 text-gray-900'
                        : 'text-gray-500 hover:bg-gray-100',
                    )}
                  >
                    v{v.version}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Right: actions */}
      <div className="flex items-center gap-2 flex-shrink-0">
        <button
          onClick={onSaveDraft}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[13px] font-medium
            border transition-colors"
          style={{ borderColor: '#d0d5dd', color: '#344054' }}
        >
          <Save size={14} />
          Save Draft
        </button>

        <button
          onClick={onReject}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[13px] font-medium
            text-red-600 hover:bg-red-50 transition-colors"
        >
          <X size={14} />
          Reject
        </button>

        <button
          onClick={onApprove}
          disabled={artifact.status === 'generating'}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[13px] font-medium
            bg-emerald-600 text-white hover:bg-emerald-700 transition-colors
            disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Check size={14} />
          Approve & Send
        </button>
      </div>
    </div>
  );
}
