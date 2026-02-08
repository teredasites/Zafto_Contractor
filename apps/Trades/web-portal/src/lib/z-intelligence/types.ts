// Z Console + Artifact System — Core Types

export type ZConsoleState = 'collapsed' | 'open' | 'artifact';

export type ZArtifactType = 'bid' | 'invoice' | 'report' | 'job_summary' | 'email' | 'change_order' | 'scope' | 'generic';

export type ZArtifactStatus = 'generating' | 'ready' | 'approved' | 'rejected' | 'draft';

export interface ZArtifactVersion {
  version: number;
  content: string;
  data: Record<string, unknown>;
  editDescription: string;
  createdAt: string;
}

export interface ZArtifact {
  id: string;
  type: ZArtifactType;
  title: string;
  content: string;
  data: Record<string, unknown>;
  versions: ZArtifactVersion[];
  currentVersion: number;
  status: ZArtifactStatus;
  createdAt: string;
}

export interface ZToolCall {
  id: string;
  name: string;
  status: 'running' | 'complete' | 'error';
  description: string;
}

export interface ZMessage {
  id: string;
  threadId: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  toolCalls?: ZToolCall[];
  artifactId?: string;
  timestamp: string;
}

export interface ZThread {
  id: string;
  title: string;
  messages: ZMessage[];
  artifact?: ZArtifact;
  pageContext: string;
  createdAt: string;
  updatedAt: string;
}

export interface ZContextChip {
  label: string;
  pathname: string;
}

export interface ZQuickAction {
  id: string;
  icon: string;
  label: string;
  prompt: string;
}

export interface ZSlashCommand {
  command: string;
  label: string;
  description: string;
  icon: string;
}

// Provider context shape
export interface ZConsoleContextType {
  consoleState: ZConsoleState;
  currentThread: ZThread | null;
  threads: ZThread[];
  isThinking: boolean;
  contextChip: ZContextChip;
  quickActions: ZQuickAction[];
  setConsoleState: (state: ZConsoleState) => void;
  toggleConsole: () => void;
  sendMessage: (content: string) => void;
  startNewThread: () => void;
  selectThread: (threadId: string) => void;
  approveArtifact: () => void;
  rejectArtifact: () => void;
  saveDraftArtifact: () => void;
  selectArtifactVersion: (version: number) => void;
  closeArtifact: () => void;
  showDemoArtifact: () => void;
  showStorageArtifact: () => void;
  chatWidth: number;
  artifactWidth: number;
  setChatWidth: (width: number) => void;
  setArtifactWidth: (width: number) => void;
}
