'use client';

import { useState, useCallback } from 'react';
import { getSupabase } from '@/lib/supabase';
import { useAuth } from '@/components/auth-provider';

// ==================== TYPES ====================

export interface AiMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

interface AiAssistantState {
  messages: AiMessage[];
  loading: boolean;
  error: string | null;
}

interface AiRequestPayload {
  action: string;
  message?: string;
  context?: Record<string, unknown>;
  history?: Array<{ role: string; content: string }>;
}

// ==================== HELPERS ====================

function createMessage(role: 'user' | 'assistant', content: string): AiMessage {
  return {
    id: `${role}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    role,
    content,
    timestamp: Date.now(),
  };
}

async function callZIntelligence(
  payload: AiRequestPayload,
  accessToken: string | null,
): Promise<string> {
  const supabase = getSupabase();

  const { data, error } = await supabase.functions.invoke('z-intelligence', {
    body: payload,
    headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : undefined,
  });

  if (error) {
    throw new Error(error.message || 'Something went wrong. Please try again.');
  }

  const response = data?.response || data?.message || data?.content;
  if (!response || typeof response !== 'string') {
    throw new Error('No response received. Please try again.');
  }

  return response;
}

// ==================== HOOK ====================

export function useAiAssistant() {
  const { user } = useAuth();
  const [state, setState] = useState<AiAssistantState>({
    messages: [],
    loading: false,
    error: null,
  });

  const getAccessToken = useCallback(async (): Promise<string | null> => {
    const supabase = getSupabase();
    const { data } = await supabase.auth.getSession();
    return data?.session?.access_token || null;
  }, []);

  const addMessages = useCallback((userMsg: AiMessage, assistantMsg: AiMessage) => {
    setState((prev) => ({
      ...prev,
      messages: [...prev.messages, userMsg, assistantMsg],
      loading: false,
      error: null,
    }));
  }, []);

  const setError = useCallback((errorMsg: string) => {
    setState((prev) => ({ ...prev, loading: false, error: errorMsg }));
  }, []);

  const askQuestion = useCallback(async (question: string) => {
    if (!question.trim() || !user) return;

    const userMsg = createMessage('user', question.trim());
    setState((prev) => ({
      ...prev,
      messages: [...prev.messages, userMsg],
      loading: true,
      error: null,
    }));

    try {
      const token = await getAccessToken();
      const history = state.messages.slice(-10).map((m) => ({
        role: m.role,
        content: m.content,
      }));

      const response = await callZIntelligence(
        {
          action: 'client_chat',
          message: question.trim(),
          context: { source: 'client_portal' },
          history,
        },
        token,
      );

      const assistantMsg = createMessage('assistant', response);
      setState((prev) => ({
        ...prev,
        messages: [...prev.messages, assistantMsg],
        loading: false,
        error: null,
      }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong. Please try again.');
    }
  }, [user, state.messages, getAccessToken, setError]);

  const getProjectSummary = useCallback(async (projectId: string) => {
    if (!user) return;

    const userMsg = createMessage('user', 'Can you summarize this project for me?');
    setState((prev) => ({
      ...prev,
      messages: [...prev.messages, userMsg],
      loading: true,
      error: null,
    }));

    try {
      const token = await getAccessToken();
      const response = await callZIntelligence(
        {
          action: 'project_summary',
          context: { projectId, source: 'client_portal' },
        },
        token,
      );

      const assistantMsg = createMessage('assistant', response);
      addMessages(userMsg, assistantMsg);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to load project summary right now.');
    }
  }, [user, getAccessToken, addMessages, setError]);

  const explainInvoice = useCallback(async (invoiceId: string) => {
    if (!user) return;

    const userMsg = createMessage('user', 'Can you explain this invoice?');
    setState((prev) => ({
      ...prev,
      messages: [...prev.messages, userMsg],
      loading: true,
      error: null,
    }));

    try {
      const token = await getAccessToken();
      const response = await callZIntelligence(
        {
          action: 'explain_invoice',
          context: { invoiceId, source: 'client_portal' },
        },
        token,
      );

      const assistantMsg = createMessage('assistant', response);
      addMessages(userMsg, assistantMsg);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to explain this invoice right now.');
    }
  }, [user, getAccessToken, addMessages, setError]);

  const clearChat = useCallback(() => {
    setState({ messages: [], loading: false, error: null });
  }, []);

  return {
    messages: state.messages,
    loading: state.loading,
    error: state.error,
    askQuestion,
    getProjectSummary,
    explainInvoice,
    clearChat,
  };
}
