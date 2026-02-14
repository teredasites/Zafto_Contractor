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
    chatWidth,
    artifactWidth,
    setChatWidth,
    setArtifactWidth,
  } = useZConsole();

  const messages = currentThread?.messages || [];
  const artifact = currentThread?.artifact;
  const isArtifactOpen = consoleState === 'artifact';

  const handleQuickAction = (action: ZQuickAction) => {
    sendMessage(action.prompt);
  };

  return (
    <>
      {/* No floating FAB — Z is accessed via top bar button or dashboard widget */}

      {/* Chat panel — when open OR when artifact is active (stays visible, slides left) */}
      {(consoleState === 'open' || consoleState === 'artifact') && (
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
          width={chatWidth}
          onWidthChange={setChatWidth}
          rightOffset={isArtifactOpen ? artifactWidth : 0}
        />
      )}

      {/* Artifact panel — slides in at right:0, pushes chat left */}
      {consoleState === 'artifact' && artifact && (
        <ZArtifactSplit
          artifact={artifact}
          onApprove={approveArtifact}
          onReject={rejectArtifact}
          onSaveDraft={saveDraftArtifact}
          onVersionSelect={selectArtifactVersion}
          onCloseArtifact={closeArtifact}
          width={artifactWidth}
          onWidthChange={setArtifactWidth}
        />
      )}
    </>
  );
}
