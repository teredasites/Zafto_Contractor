'use client';

import type { ZMessage, ZArtifact } from '@/lib/z-intelligence/types';
import { ZArtifactViewer } from './z-artifact-viewer';
import { ZChatMessages } from './z-chat-messages';
import { ZChatInput } from './z-chat-input';

interface ZArtifactSplitProps {
  artifact: ZArtifact;
  messages: ZMessage[];
  isThinking: boolean;
  onSend: (message: string) => void;
  onApprove: () => void;
  onReject: () => void;
  onSaveDraft: () => void;
  onVersionSelect: (version: number) => void;
  onCloseArtifact: () => void;
}

export function ZArtifactSplit({
  artifact,
  messages,
  isThinking,
  onSend,
  onApprove,
  onReject,
  onSaveDraft,
  onVersionSelect,
  onCloseArtifact,
}: ZArtifactSplitProps) {
  return (
    <div className="fixed top-0 right-0 h-full z-45 flex flex-col border-l shadow-2xl"
      style={{
        width: 'min(60vw, 800px)',
        borderColor: '#e4e7ec',
      }}
    >
      {/* Top: Artifact viewer (~70%) */}
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

      {/* Bottom: Compact chat (~30%) */}
      <div className="h-[30%] min-h-[180px] max-h-[280px] flex flex-col border-t bg-surface"
        style={{ borderColor: '#e4e7ec' }}
      >
        <ZChatMessages messages={messages} isThinking={isThinking} compact />
        <ZChatInput
          onSend={onSend}
          disabled={isThinking}
          compact
          placeholder="Describe changes..."
        />
      </div>
    </div>
  );
}
