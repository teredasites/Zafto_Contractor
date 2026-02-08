'use client';

import {
  createContext,
  useContext,
  useReducer,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  type ReactNode,
} from 'react';
import { usePathname } from 'next/navigation';
import type {
  ZConsoleState,
  ZConsoleContextType,
  ZThread,
  ZMessage,
  ZArtifact,
} from '@/lib/z-intelligence/types';
import { getPageContext } from '@/lib/z-intelligence/context-map';
import { simulateResponse } from '@/lib/z-intelligence/mock-responses';
import { sendToZ } from '@/lib/z-intelligence/api-client';
import { MOCK_BID_ARTIFACT, STORAGE_BROWSER_ARTIFACT } from '@/lib/z-intelligence/artifact-templates';

// ── Feature flag: set to true to use real Claude API ──
const USE_LIVE_API = typeof window !== 'undefined' &&
  Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL) &&
  Boolean(process.env.NEXT_PUBLIC_Z_INTELLIGENCE_ENABLED);

// ── State ────────────────────────────────────────────
interface ProviderState {
  consoleState: ZConsoleState;
  threads: ZThread[];
  currentThreadId: string | null;
  isThinking: boolean;
  streamingContent: string; // partial content for streaming display
  tokenCount: number; // usage tracking
  chatWidth: number;
  artifactWidth: number;
}

type Action =
  | { type: 'SET_STATE'; state: ZConsoleState }
  | { type: 'TOGGLE' }
  | { type: 'ADD_MESSAGE'; threadId: string; message: ZMessage }
  | { type: 'SET_THINKING'; value: boolean }
  | { type: 'SET_ARTIFACT'; threadId: string; artifact: ZArtifact }
  | { type: 'UPDATE_ARTIFACT_STATUS'; threadId: string; status: ZArtifact['status'] }
  | { type: 'UPDATE_ARTIFACT_VERSION'; threadId: string; artifact: ZArtifact }
  | { type: 'SELECT_ARTIFACT_VERSION'; threadId: string; version: number }
  | { type: 'CLEAR_ARTIFACT'; threadId: string }
  | { type: 'NEW_THREAD'; thread: ZThread }
  | { type: 'SELECT_THREAD'; threadId: string }
  | { type: 'RESTORE'; threads: ZThread[]; currentThreadId: string | null }
  | { type: 'ADD_PARTIAL_CONTENT'; delta: string }
  | { type: 'CLEAR_PARTIAL_CONTENT' }
  | { type: 'UPDATE_TOOL_CALLS'; threadId: string; toolCalls: ZMessage['toolCalls'] }
  | { type: 'SET_TOKEN_COUNT'; count: number }
  | { type: 'UPDATE_THREAD_ID'; oldId: string; newId: string }
  | { type: 'SET_CHAT_WIDTH'; width: number }
  | { type: 'SET_ARTIFACT_WIDTH'; width: number };

function reducer(state: ProviderState, action: Action): ProviderState {
  switch (action.type) {
    case 'SET_STATE':
      return { ...state, consoleState: action.state };

    case 'TOGGLE':
      return {
        ...state,
        consoleState: state.consoleState === 'collapsed' ? 'open' : 'collapsed',
      };

    case 'ADD_MESSAGE': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId
          ? {
              ...t,
              messages: [...t.messages, action.message],
              title: t.messages.length === 0 && action.message.role === 'user'
                ? action.message.content.slice(0, 50) + (action.message.content.length > 50 ? '...' : '')
                : t.title,
              updatedAt: new Date().toISOString(),
            }
          : t,
      );
      return { ...state, threads };
    }

    case 'SET_THINKING':
      return { ...state, isThinking: action.value };

    case 'SET_ARTIFACT': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId ? { ...t, artifact: action.artifact } : t,
      );
      return { ...state, threads, consoleState: 'artifact' };
    }

    case 'UPDATE_ARTIFACT_STATUS': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId && t.artifact
          ? { ...t, artifact: { ...t.artifact, status: action.status } }
          : t,
      );
      return { ...state, threads };
    }

    case 'UPDATE_ARTIFACT_VERSION': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId ? { ...t, artifact: action.artifact } : t,
      );
      return { ...state, threads };
    }

    case 'SELECT_ARTIFACT_VERSION': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId && t.artifact
          ? { ...t, artifact: { ...t.artifact, currentVersion: action.version } }
          : t,
      );
      return { ...state, threads };
    }

    case 'CLEAR_ARTIFACT': {
      const threads = state.threads.map((t) =>
        t.id === action.threadId ? { ...t, artifact: undefined } : t,
      );
      return { ...state, threads, consoleState: 'open' };
    }

    case 'NEW_THREAD':
      return {
        ...state,
        threads: [action.thread, ...state.threads].slice(0, 50),
        currentThreadId: action.thread.id,
      };

    case 'SELECT_THREAD':
      return {
        ...state,
        currentThreadId: action.threadId,
        consoleState: state.threads.find((t) => t.id === action.threadId)?.artifact
          ? 'artifact'
          : 'open',
      };

    case 'RESTORE':
      return { ...state, threads: action.threads, currentThreadId: action.currentThreadId };

    // Streaming actions
    case 'ADD_PARTIAL_CONTENT':
      return { ...state, streamingContent: state.streamingContent + action.delta };

    case 'CLEAR_PARTIAL_CONTENT':
      return { ...state, streamingContent: '' };

    case 'UPDATE_TOOL_CALLS': {
      const threads = state.threads.map((t) => {
        if (t.id !== action.threadId) return t;
        const msgs = [...t.messages];
        // Update last assistant message's tool calls
        for (let i = msgs.length - 1; i >= 0; i--) {
          if (msgs[i].role === 'assistant') {
            msgs[i] = { ...msgs[i], toolCalls: action.toolCalls };
            break;
          }
        }
        return { ...t, messages: msgs };
      });
      return { ...state, threads };
    }

    case 'SET_TOKEN_COUNT':
      return { ...state, tokenCount: state.tokenCount + action.count };

    case 'UPDATE_THREAD_ID': {
      const threads = state.threads.map((t) =>
        t.id === action.oldId ? { ...t, id: action.newId } : t,
      );
      const currentThreadId = state.currentThreadId === action.oldId
        ? action.newId
        : state.currentThreadId;
      return { ...state, threads, currentThreadId };
    }

    case 'SET_CHAT_WIDTH':
      return { ...state, chatWidth: action.width };

    case 'SET_ARTIFACT_WIDTH':
      return { ...state, artifactWidth: action.width };

    default:
      return state;
  }
}

// ── Helpers ──────────────────────────────────────────
function uid(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function createThread(pathname: string): ZThread {
  const { chip } = getPageContext(pathname);
  return {
    id: uid(),
    title: 'New conversation',
    messages: [],
    pageContext: chip.label,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

// ── Storage (localStorage fallback for mock mode) ────
const STORAGE_KEY = 'zafto_z_threads';
const THREAD_ID_KEY = 'zafto_z_current_thread';

function loadThreads(): { threads: ZThread[]; currentThreadId: string | null } {
  if (typeof window === 'undefined') return { threads: [], currentThreadId: null };
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const threads: ZThread[] = raw ? JSON.parse(raw) : [];
    const currentThreadId = localStorage.getItem(THREAD_ID_KEY);
    return { threads: threads.slice(0, 50), currentThreadId };
  } catch {
    return { threads: [], currentThreadId: null };
  }
}

function saveThreads(threads: ZThread[], currentThreadId: string | null) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(threads.slice(0, 50)));
    if (currentThreadId) {
      localStorage.setItem(THREAD_ID_KEY, currentThreadId);
    }
  } catch {
    // localStorage full — silently skip
  }
}

// ── Context ──────────────────────────────────────────
const ZConsoleContext = createContext<ZConsoleContextType | null>(null);

export function useZConsole(): ZConsoleContextType {
  const ctx = useContext(ZConsoleContext);
  if (!ctx) throw new Error('useZConsole must be used within ZConsoleProvider');
  return ctx;
}

// ── Provider ─────────────────────────────────────────
export function ZConsoleProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const streamingRef = useRef<string>('');

  const [state, dispatch] = useReducer(reducer, {
    consoleState: 'collapsed',
    threads: [],
    currentThreadId: null,
    isThinking: false,
    streamingContent: '',
    tokenCount: 0,
    chatWidth: 420,
    artifactWidth: 600,
  });

  // Restore from localStorage on mount
  useEffect(() => {
    const { threads, currentThreadId } = loadThreads();
    if (threads.length > 0) {
      dispatch({ type: 'RESTORE', threads, currentThreadId });
    }
  }, []);

  // Persist to localStorage on thread changes
  useEffect(() => {
    if (state.threads.length > 0 || state.currentThreadId) {
      saveThreads(state.threads, state.currentThreadId);
    }
  }, [state.threads, state.currentThreadId]);

  // Restore panel widths from localStorage
  useEffect(() => {
    const cw = localStorage.getItem('zafto_z_chat_width');
    const aw = localStorage.getItem('zafto_z_artifact_width');
    if (cw) dispatch({ type: 'SET_CHAT_WIDTH', width: parseInt(cw, 10) });
    if (aw) dispatch({ type: 'SET_ARTIFACT_WIDTH', width: parseInt(aw, 10) });
  }, []);

  // Persist panel widths
  useEffect(() => {
    localStorage.setItem('zafto_z_chat_width', String(state.chatWidth));
    localStorage.setItem('zafto_z_artifact_width', String(state.artifactWidth));
  }, [state.chatWidth, state.artifactWidth]);

  // Update context chip + quick actions when pathname changes
  const { chip: contextChip, actions: quickActions } = useMemo(
    () => getPageContext(pathname),
    [pathname],
  );

  // Keyboard shortcut: Cmd+J / Ctrl+J
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'j') {
        e.preventDefault();
        dispatch({ type: 'TOGGLE' });
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Window event for external integration (command palette, etc.)
  useEffect(() => {
    const handleToggle = () => dispatch({ type: 'TOGGLE' });
    window.addEventListener('zConsoleToggle', handleToggle);
    return () => window.removeEventListener('zConsoleToggle', handleToggle);
  }, []);

  // ── Current thread ──
  const currentThread = useMemo(
    () => state.threads.find((t) => t.id === state.currentThreadId) || null,
    [state.threads, state.currentThreadId],
  );

  // ── Actions ──
  const setConsoleState = useCallback((s: ZConsoleState) => {
    dispatch({ type: 'SET_STATE', state: s });
  }, []);

  const toggleConsole = useCallback(() => {
    dispatch({ type: 'TOGGLE' });
  }, []);

  const startNewThread = useCallback(() => {
    const thread = createThread(pathname);
    dispatch({ type: 'NEW_THREAD', thread });
  }, [pathname]);

  const selectThread = useCallback((threadId: string) => {
    dispatch({ type: 'SELECT_THREAD', threadId });
  }, []);

  const setChatWidth = useCallback((width: number) => {
    dispatch({ type: 'SET_CHAT_WIDTH', width: Math.min(Math.max(width, 320), 700) });
  }, []);

  const setArtifactWidth = useCallback((width: number) => {
    dispatch({ type: 'SET_ARTIFACT_WIDTH', width: Math.min(Math.max(width, 400), 900) });
  }, []);

  // ── Send Message (dual-mode: live API or mock) ──
  const sendMessage = useCallback(async (content: string) => {
    let threadId = state.currentThreadId;

    // Auto-create thread if none
    if (!threadId) {
      const thread = createThread(pathname);
      dispatch({ type: 'NEW_THREAD', thread });
      threadId = thread.id;
    }

    // Add user message
    const userMsg: ZMessage = {
      id: uid(),
      threadId,
      role: 'user',
      content,
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId, message: userMsg });

    // Start thinking
    dispatch({ type: 'SET_THINKING', value: true });

    if (USE_LIVE_API) {
      // ── Live Claude API mode ──
      dispatch({ type: 'CLEAR_PARTIAL_CONTENT' });
      streamingRef.current = '';

      const thread = state.threads.find((t) => t.id === threadId);
      const currentArtifact = thread?.artifact;

      // Add placeholder assistant message for streaming
      const streamMsgId = uid();
      const streamMsg: ZMessage = {
        id: streamMsgId,
        threadId: threadId!,
        role: 'assistant',
        content: '',
        timestamp: new Date().toISOString(),
      };
      dispatch({ type: 'ADD_MESSAGE', threadId: threadId!, message: streamMsg });

      await sendToZ(
        {
          threadId: threadId!,
          message: content,
          pageContext: pathname,
          artifactContext: currentArtifact ? {
            id: currentArtifact.id,
            type: currentArtifact.type,
            content: currentArtifact.content,
            data: currentArtifact.data,
            currentVersion: currentArtifact.currentVersion,
          } : undefined,
        },
        {
          onThinking: (toolCalls) => {
            dispatch({
              type: 'UPDATE_TOOL_CALLS',
              threadId: threadId!,
              toolCalls: toolCalls.map((tc) => ({
                id: uid(),
                name: tc.name,
                description: tc.name,
                status: tc.status as 'running' | 'complete' | 'error',
              })),
            });
          },
          onToolResult: (name, status) => {
            dispatch({
              type: 'UPDATE_TOOL_CALLS',
              threadId: threadId!,
              toolCalls: [{ id: uid(), name, description: name, status: status as 'complete' }],
            });
          },
          onContent: (delta) => {
            streamingRef.current += delta;
            dispatch({ type: 'ADD_PARTIAL_CONTENT', delta });
          },
          onArtifact: (artifact) => {
            if (currentArtifact) {
              dispatch({ type: 'UPDATE_ARTIFACT_VERSION', threadId: threadId!, artifact });
            } else {
              dispatch({ type: 'SET_ARTIFACT', threadId: threadId!, artifact });
            }
          },
          onDone: (meta) => {
            // Finalize: replace streaming message with complete content
            const finalMsg: ZMessage = {
              id: uid(),
              threadId: threadId!,
              role: 'assistant',
              content: streamingRef.current,
              timestamp: new Date().toISOString(),
            };
            dispatch({ type: 'ADD_MESSAGE', threadId: threadId!, message: finalMsg });
            dispatch({ type: 'SET_THINKING', value: false });
            dispatch({ type: 'CLEAR_PARTIAL_CONTENT' });
            dispatch({ type: 'SET_TOKEN_COUNT', count: meta.tokenCount });

            // Update thread ID if server assigned a new one
            if (meta.threadId && meta.threadId !== threadId) {
              dispatch({ type: 'UPDATE_THREAD_ID', oldId: threadId!, newId: meta.threadId });
            }
          },
          onError: (error) => {
            dispatch({ type: 'SET_THINKING', value: false });
            dispatch({ type: 'CLEAR_PARTIAL_CONTENT' });
            const errorMsg: ZMessage = {
              id: uid(),
              threadId: threadId!,
              role: 'assistant',
              content: `Error: ${error}`,
              timestamp: new Date().toISOString(),
            };
            dispatch({ type: 'ADD_MESSAGE', threadId: threadId!, message: errorMsg });
          },
        }
      );
    } else {
      // ── Mock mode (demo/development) ──
      try {
        const thread = state.threads.find((t) => t.id === threadId);
        const currentArtifact = thread?.artifact;

        const response = await simulateResponse(content, threadId!, currentArtifact);

        dispatch({ type: 'SET_THINKING', value: false });

        for (const msg of response.messages) {
          const assistantMsg: ZMessage = {
            id: uid(),
            threadId: threadId!,
            role: msg.role,
            content: msg.content,
            toolCalls: msg.toolCalls,
            artifactId: msg.artifactId,
            timestamp: new Date().toISOString(),
          };
          dispatch({ type: 'ADD_MESSAGE', threadId: threadId!, message: assistantMsg });
        }

        if (response.artifact) {
          if (currentArtifact) {
            dispatch({ type: 'UPDATE_ARTIFACT_VERSION', threadId: threadId!, artifact: response.artifact });
          } else {
            dispatch({ type: 'SET_ARTIFACT', threadId: threadId!, artifact: response.artifact });
          }
        }
      } catch {
        dispatch({ type: 'SET_THINKING', value: false });
        const errorMsg: ZMessage = {
          id: uid(),
          threadId: threadId!,
          role: 'assistant',
          content: 'Something went wrong. Please try again.',
          timestamp: new Date().toISOString(),
        };
        dispatch({ type: 'ADD_MESSAGE', threadId: threadId!, message: errorMsg });
      }
    }
  }, [state.currentThreadId, state.threads, pathname]);

  const approveArtifact = useCallback(() => {
    if (!state.currentThreadId) return;
    dispatch({ type: 'UPDATE_ARTIFACT_STATUS', threadId: state.currentThreadId, status: 'approved' });

    const msg: ZMessage = {
      id: uid(),
      threadId: state.currentThreadId,
      role: 'assistant',
      content: 'Approved. In production, this would be sent to the customer.',
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId: state.currentThreadId, message: msg });
  }, [state.currentThreadId]);

  const rejectArtifact = useCallback(() => {
    if (!state.currentThreadId) return;
    dispatch({ type: 'UPDATE_ARTIFACT_STATUS', threadId: state.currentThreadId, status: 'rejected' });

    const msg: ZMessage = {
      id: uid(),
      threadId: state.currentThreadId,
      role: 'assistant',
      content: 'Rejected. Tell me what changes you need and I\'ll create a new version.',
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId: state.currentThreadId, message: msg });
  }, [state.currentThreadId]);

  const saveDraftArtifact = useCallback(() => {
    if (!state.currentThreadId) return;
    dispatch({ type: 'UPDATE_ARTIFACT_STATUS', threadId: state.currentThreadId, status: 'draft' });

    const msg: ZMessage = {
      id: uid(),
      threadId: state.currentThreadId,
      role: 'assistant',
      content: 'Saved as draft. You can come back to this anytime.',
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId: state.currentThreadId, message: msg });
  }, [state.currentThreadId]);

  const selectArtifactVersion = useCallback((version: number) => {
    if (!state.currentThreadId) return;
    dispatch({ type: 'SELECT_ARTIFACT_VERSION', threadId: state.currentThreadId, version });
  }, [state.currentThreadId]);

  const closeArtifact = useCallback(() => {
    if (!state.currentThreadId) return;
    dispatch({ type: 'CLEAR_ARTIFACT', threadId: state.currentThreadId });
  }, [state.currentThreadId]);

  const showDemoArtifact = useCallback(() => {
    let threadId = state.currentThreadId;

    if (!threadId) {
      const thread = createThread(pathname);
      dispatch({ type: 'NEW_THREAD', thread });
      threadId = thread.id;
    }

    const userMsg: ZMessage = {
      id: uid(),
      threadId,
      role: 'user',
      content: 'Show me a demo bid',
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId, message: userMsg });

    const assistantMsg: ZMessage = {
      id: uid(),
      threadId,
      role: 'assistant',
      content: "Here's a 3-tier bid with Good, Better, and Best options. Review the document and approve when ready.",
      toolCalls: [
        { id: `tc-${Date.now()}-1`, name: 'searchPriceBook', description: 'Price book lookup', status: 'complete' },
        { id: `tc-${Date.now()}-2`, name: 'calculateLabor', description: 'Labor cost calculation', status: 'complete' },
        { id: `tc-${Date.now()}-3`, name: 'generateBid', description: 'Building bid document', status: 'complete' },
      ],
      artifactId: 'mock-bid-1',
      timestamp: new Date().toISOString(),
    };
    dispatch({ type: 'ADD_MESSAGE', threadId, message: assistantMsg });
    dispatch({ type: 'SET_ARTIFACT', threadId, artifact: { ...MOCK_BID_ARTIFACT } });
  }, [state.currentThreadId, pathname]);

  const showStorageArtifact = useCallback(() => {
    let threadId = state.currentThreadId;

    if (!threadId) {
      const thread = createThread(pathname);
      dispatch({ type: 'NEW_THREAD', thread });
      threadId = thread.id;
    }

    dispatch({ type: 'SET_ARTIFACT', threadId, artifact: { ...STORAGE_BROWSER_ARTIFACT } });
  }, [state.currentThreadId, pathname]);

  // ── Context value ──
  const value: ZConsoleContextType = useMemo(() => ({
    consoleState: state.consoleState,
    currentThread,
    threads: state.threads,
    isThinking: state.isThinking,
    contextChip,
    quickActions,
    setConsoleState,
    toggleConsole,
    sendMessage,
    startNewThread,
    selectThread,
    approveArtifact,
    rejectArtifact,
    saveDraftArtifact,
    selectArtifactVersion,
    closeArtifact,
    showDemoArtifact,
    showStorageArtifact,
    chatWidth: state.chatWidth,
    artifactWidth: state.artifactWidth,
    setChatWidth,
    setArtifactWidth,
  }), [
    state.consoleState,
    currentThread,
    state.threads,
    state.isThinking,
    contextChip,
    quickActions,
    setConsoleState,
    toggleConsole,
    sendMessage,
    startNewThread,
    selectThread,
    approveArtifact,
    rejectArtifact,
    saveDraftArtifact,
    selectArtifactVersion,
    closeArtifact,
    showDemoArtifact,
    showStorageArtifact,
    state.chatWidth,
    state.artifactWidth,
    setChatWidth,
    setArtifactWidth,
  ]);

  return (
    <ZConsoleContext.Provider value={value}>
      {children}
    </ZConsoleContext.Provider>
  );
}
