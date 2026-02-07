'use client';

import { useZConsole } from './z-console-provider';
import { ZPulse } from './z-pulse';
import { ZChatPanel } from './z-chat-panel';
import { ZArtifactSplit } from './z-artifact-split';
import type { ZQuickAction } from '@/lib/z-intelligence/types';

export function ZConsole() {
  const {
    consoleState,
    currentThread,
    threads,
    isThinking,
    contextChip,
    quickActions,
    toggleConsole,
    sendMessage,
    startNewThread,
    selectThread,
    approveArtifact,
    rejectArtifact,
    saveDraftArtifact,
    selectArtifactVersion,
    closeArtifact,
    setConsoleState,
    showDemoArtifact,
  } = useZConsole();

  const messages = currentThread?.messages || [];
  const artifact = currentThread?.artifact;

  const handleQuickAction = (action: ZQuickAction) => {
    sendMessage(action.prompt);
  };

  return (
    <>
      {/* Pulse — always rendered when collapsed */}
      {consoleState === 'collapsed' && (
        <ZPulse onClick={toggleConsole} hasUnread={false} />
      )}

      {/* Chat panel — when open */}
      {consoleState === 'open' && (
        <ZChatPanel
          messages={messages}
          threads={threads}
          currentThreadId={currentThread?.id || null}
          isThinking={isThinking}
          contextChip={contextChip}
          quickActions={quickActions}
          onSend={sendMessage}
          onClose={() => setConsoleState('collapsed')}
          onSelectThread={selectThread}
          onNewThread={startNewThread}
          onQuickAction={handleQuickAction}
          onShowDemo={showDemoArtifact}
        />
      )}

      {/* Artifact split — when artifact is active */}
      {consoleState === 'artifact' && artifact && (
        <ZArtifactSplit
          artifact={artifact}
          messages={messages}
          isThinking={isThinking}
          onSend={sendMessage}
          onApprove={approveArtifact}
          onReject={rejectArtifact}
          onSaveDraft={saveDraftArtifact}
          onVersionSelect={selectArtifactVersion}
          onCloseArtifact={closeArtifact}
        />
      )}
    </>
  );
}
