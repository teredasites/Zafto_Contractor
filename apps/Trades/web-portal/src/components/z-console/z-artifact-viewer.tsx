'use client';

import { useState } from 'react';
import { FileText, Image, Table2, Code2, File, FolderOpen } from 'lucide-react';
import type { ZArtifact } from '@/lib/z-intelligence/types';
import { ZArtifactToolbar } from './z-artifact-toolbar';
import { ZMarkdown } from './z-markdown';
import { ZStorageBrowser } from './z-storage-browser';
import { Logo } from '@/components/logo';
import { cn } from '@/lib/utils';

type ViewTab = 'document' | 'files';

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
  // Default to 'files' for storage artifact, 'document' otherwise
  const [activeTab, setActiveTab] = useState<ViewTab>(
    artifact.type === 'generic' && artifact.id === 'storage-browser' ? 'files' : 'document'
  );

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

      {/* Tab bar */}
      <div className="flex items-center gap-1 px-4 py-1.5 border-b" style={{ borderColor: '#e4e7ec' }}>
        <button
          onClick={() => setActiveTab('document')}
          className={cn(
            'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[12px] font-medium transition-colors',
            activeTab === 'document'
              ? 'bg-gray-100 text-gray-900'
              : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50',
          )}
        >
          <FileText size={13} />
          Document
        </button>
        <button
          onClick={() => setActiveTab('files')}
          className={cn(
            'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[12px] font-medium transition-colors',
            activeTab === 'files'
              ? 'bg-gray-100 text-gray-900'
              : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50',
          )}
        >
          <FolderOpen size={13} />
          Files
        </button>
      </div>

      {/* Tab content */}
      <div className="flex-1 overflow-y-auto relative">
        {/* Generating overlay — dark pulsing Z with emerald glow */}
        {isGenerating && (
          <div className="absolute inset-0 z-10 flex flex-col items-center justify-center z-loading-overlay" style={{ background: '#060d0a' }}>
            {/* Outer ambient ring */}
            <div className="absolute w-[200px] h-[200px] rounded-full z-loading-outer"
              style={{ background: 'radial-gradient(circle, rgba(16, 185, 129, 0.12) 0%, rgba(16, 185, 129, 0.03) 50%, transparent 70%)' }}
            />
            {/* Mid glow ring */}
            <div className="absolute w-[120px] h-[120px] rounded-full z-loading-mid" />
            {/* The Z — large Logo SVG with breathing glow */}
            <div className="relative z-loading-z">
              <Logo size={72} className="text-emerald-500" animated />
            </div>
            {/* Status text */}
            <p className="mt-8 text-[13px] font-medium text-emerald-500/70 tracking-wide">
              Generating...
            </p>
          </div>
        )}

        {activeTab === 'document' ? (
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

            {/* Artifact content — render based on type */}
            <ArtifactContent artifact={artifact} />
          </div>
        ) : (
          <ZStorageBrowser />
        )}
      </div>
    </div>
  );
}

function ArtifactContent({ artifact }: { artifact: ZArtifact }) {
  const { type, content, data } = artifact;

  // PDF rendering
  if (type === 'report' && data?.pdfUrl) {
    return (
      <div className="w-full h-[calc(100vh-200px)] rounded-lg overflow-hidden border" style={{ borderColor: '#e4e7ec' }}>
        <iframe
          src={data.pdfUrl as string}
          className="w-full h-full"
          title={artifact.title}
        />
      </div>
    );
  }

  // Image rendering
  if (data?.imageUrl) {
    return (
      <div className="space-y-4">
        <div className="rounded-lg overflow-hidden border" style={{ borderColor: '#e4e7ec' }}>
          <img
            src={data.imageUrl as string}
            alt={artifact.title}
            className="w-full h-auto"
          />
        </div>
        {content && (
          <div className="z-prose">
            <ZMarkdown content={content} />
          </div>
        )}
      </div>
    );
  }

  // Table / spreadsheet rendering
  if (type === 'report' && data?.tableData) {
    const tableData = data.tableData as { headers: string[]; rows: string[][] };
    return (
      <div className="space-y-4">
        {content && (
          <div className="z-prose mb-4">
            <ZMarkdown content={content} />
          </div>
        )}
        <div className="overflow-x-auto rounded-lg border" style={{ borderColor: '#e4e7ec' }}>
          <table className="w-full text-[13px]">
            <thead>
              <tr>
                {tableData.headers.map((h, i) => (
                  <th key={i} className="px-3 py-2 text-left font-semibold bg-gray-50 border-b" style={{ borderColor: '#e4e7ec' }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {tableData.rows.map((row, i) => (
                <tr key={i} className="border-b last:border-0" style={{ borderColor: '#e4e7ec' }}>
                  {row.map((cell, j) => (
                    <td key={j} className="px-3 py-2">
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    );
  }

  // Code rendering
  if (data?.code) {
    return (
      <div className="space-y-4">
        {content && (
          <div className="z-prose mb-4">
            <ZMarkdown content={content} />
          </div>
        )}
        <div className="rounded-lg overflow-hidden border" style={{ borderColor: '#e4e7ec' }}>
          <div className="flex items-center gap-2 px-4 py-2 bg-gray-50 border-b text-[12px] text-gray-500 font-medium" style={{ borderColor: '#e4e7ec' }}>
            <Code2 size={13} />
            {(data.language as string) || 'Code'}
          </div>
          <pre className="p-4 overflow-x-auto text-[13px] leading-relaxed bg-gray-900 text-gray-100">
            <code>{data.code as string}</code>
          </pre>
        </div>
      </div>
    );
  }

  // Default: markdown content
  return (
    <div className="z-prose">
      <ZMarkdown content={content} />
    </div>
  );
}

function TypeBadge({ type }: { type: string }) {
  const config: Record<string, { label: string; bg: string; text: string; Icon: any }> = {
    bid: { label: 'Bid Proposal', bg: 'bg-blue-50', text: 'text-blue-700', Icon: FileText },
    invoice: { label: 'Invoice', bg: 'bg-emerald-50', text: 'text-emerald-700', Icon: FileText },
    report: { label: 'Report', bg: 'bg-violet-50', text: 'text-violet-700', Icon: Table2 },
    job_summary: { label: 'Job Summary', bg: 'bg-amber-50', text: 'text-amber-700', Icon: FileText },
    email: { label: 'Email Draft', bg: 'bg-sky-50', text: 'text-sky-700', Icon: FileText },
    change_order: { label: 'Change Order', bg: 'bg-orange-50', text: 'text-orange-700', Icon: FileText },
    scope: { label: 'Scope of Work', bg: 'bg-indigo-50', text: 'text-indigo-700', Icon: FileText },
    generic: { label: 'Document', bg: 'bg-gray-50', text: 'text-gray-600', Icon: File },
  };
  const c = config[type] || config.generic;

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-semibold uppercase tracking-wide ${c.bg} ${c.text}`}>
      <c.Icon size={11} />
      {c.label}
    </span>
  );
}
