'use client';

import type { ZArtifact } from '@/lib/z-intelligence/types';
import { ZArtifactToolbar } from './z-artifact-toolbar';
import { ZMarkdown } from './z-markdown';

interface ZArtifactViewerProps {
  artifact: ZArtifact;
  onApprove: () => void;
  onReject: () => void;
  onSaveDraft: () => void;
  onVersionSelect: (version: number) => void;
  onClose: () => void;
}

export function ZArtifactViewer({
  artifact,
  onApprove,
  onReject,
  onSaveDraft,
  onVersionSelect,
  onClose,
}: ZArtifactViewerProps) {
  const isGenerating = artifact.status === 'generating';

  return (
    <div className="z-artifact-pane flex flex-col h-full">
      <ZArtifactToolbar
        artifact={artifact}
        onApprove={onApprove}
        onReject={onReject}
        onSaveDraft={onSaveDraft}
        onVersionSelect={onVersionSelect}
        onClose={onClose}
      />

      <div className="flex-1 overflow-y-auto">
        <div className={`max-w-[720px] mx-auto px-8 py-6 ${isGenerating ? 'z-artifact-reveal' : ''}`}>
          {/* Type-specific header badges */}
          <div className="flex items-center gap-2 mb-6">
            <TypeBadge type={artifact.type} />
            {artifact.currentVersion > 1 && (
              <span className="text-[11px] text-gray-400 font-medium">
                Version {artifact.currentVersion}
              </span>
            )}
          </div>

          {/* Artifact content */}
          <div className="z-prose">
            <ZMarkdown content={artifact.content} />
          </div>
        </div>
      </div>
    </div>
  );
}

function TypeBadge({ type }: { type: string }) {
  const config: Record<string, { label: string; bg: string; text: string }> = {
    bid: { label: 'Bid Proposal', bg: 'bg-blue-50', text: 'text-blue-700' },
    invoice: { label: 'Invoice', bg: 'bg-emerald-50', text: 'text-emerald-700' },
    report: { label: 'Report', bg: 'bg-violet-50', text: 'text-violet-700' },
    job_summary: { label: 'Job Summary', bg: 'bg-amber-50', text: 'text-amber-700' },
    email: { label: 'Email Draft', bg: 'bg-sky-50', text: 'text-sky-700' },
    change_order: { label: 'Change Order', bg: 'bg-orange-50', text: 'text-orange-700' },
    scope: { label: 'Scope of Work', bg: 'bg-indigo-50', text: 'text-indigo-700' },
    generic: { label: 'Document', bg: 'bg-gray-50', text: 'text-gray-600' },
  };
  const c = config[type] || config.generic;

  return (
    <span className={`inline-flex px-2 py-0.5 rounded text-[11px] font-semibold uppercase tracking-wide ${c.bg} ${c.text}`}>
      {c.label}
    </span>
  );
}
