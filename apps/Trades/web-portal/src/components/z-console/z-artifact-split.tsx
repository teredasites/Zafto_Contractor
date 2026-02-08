'use client';

import { useCallback } from 'react';
import type { ZArtifact } from '@/lib/z-intelligence/types';
import { ZArtifactViewer } from './z-artifact-viewer';

interface ZArtifactSplitProps {
  artifact: ZArtifact;
  onApprove: () => void;
  onReject: () => void;
  onSaveDraft: () => void;
  onVersionSelect: (version: number) => void;
  onCloseArtifact: () => void;
  width: number;
  onWidthChange: (width: number) => void;
}

export function ZArtifactSplit({
  artifact,
  onApprove,
  onReject,
  onSaveDraft,
  onVersionSelect,
  onCloseArtifact,
  width,
  onWidthChange,
}: ZArtifactSplitProps) {
  const handleResizeStart = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    const startX = e.clientX;
    const startWidth = width;

    const onMouseMove = (ev: MouseEvent) => {
      const delta = startX - ev.clientX;
      onWidthChange(startWidth + delta);
    };

    const onMouseUp = () => {
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };

    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
  }, [width, onWidthChange]);

  return (
    <div
      className="fixed top-0 right-0 h-full z-[49] flex flex-col border-l shadow-2xl z-artifact-enter"
      style={{
        width: `${width}px`,
        borderColor: '#e4e7ec',
      }}
    >
      {/* Resize handle */}
      <div
        className="absolute left-0 top-0 bottom-0 w-1 cursor-col-resize hover:bg-accent/30 active:bg-accent/40 transition-colors z-50"
        onMouseDown={handleResizeStart}
      />

      {/* Full-height artifact viewer */}
      <div className="flex-1 min-h-0 overflow-hidden">
        <ZArtifactViewer
          artifact={artifact}
          onApprove={onApprove}
          onReject={onReject}
          onSaveDraft={onSaveDraft}
          onVersionSelect={onVersionSelect}
          onClose={onCloseArtifact}
        />
      </div>
    </div>
  );
}
