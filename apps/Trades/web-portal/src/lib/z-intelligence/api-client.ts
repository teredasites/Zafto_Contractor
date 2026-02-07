// Z Intelligence API Client — SSE streaming to Edge Function
// Replaces mock-responses.ts for real Claude API integration

import { getSupabase } from '@/lib/supabase';
import type { ZArtifact, ZToolCall } from './types';

export interface ZIntelligenceRequest {
  threadId: string; // existing UUID or 'new'
  message: string;
  pageContext: string;
  artifactContext?: {
    id: string;
    type: string;
    content: string;
    data: Record<string, unknown>;
    currentVersion: number;
  };
}

export interface ZStreamCallbacks {
  onThinking: (toolCalls: Array<{ name: string; status: string }>) => void;
  onToolResult: (name: string, status: string, result: unknown) => void;
  onContent: (delta: string) => void;
  onArtifact: (artifact: ZArtifact) => void;
  onDone: (meta: { tokenCount: number; threadId: string }) => void;
  onError: (error: string) => void;
}

export async function sendToZ(
  request: ZIntelligenceRequest,
  callbacks: ZStreamCallbacks
): Promise<void> {
  const supabase = getSupabase();
  const { data: { session } } = await supabase.auth.getSession();

  if (!session?.access_token) {
    callbacks.onError('Not authenticated');
    return;
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) {
    callbacks.onError('Supabase URL not configured');
    return;
  }

  try {
    const response = await fetch(`${supabaseUrl}/functions/v1/z-intelligence`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
      },
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      const errText = await response.text();
      let msg = `API error: ${response.status}`;
      try {
        const parsed = JSON.parse(errText);
        msg = parsed.error || msg;
      } catch {
        // use default msg
      }
      callbacks.onError(msg);
      return;
    }

    if (!response.body) {
      callbacks.onError('No response body');
      return;
    }

    // Parse SSE stream
    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // Process complete SSE events
      const lines = buffer.split('\n');
      buffer = lines.pop() || ''; // Keep incomplete line in buffer

      let currentEvent = '';
      for (const line of lines) {
        if (line.startsWith('event: ')) {
          currentEvent = line.slice(7).trim();
        } else if (line.startsWith('data: ') && currentEvent) {
          const dataStr = line.slice(6);
          try {
            const data = JSON.parse(dataStr);
            handleSSEEvent(currentEvent, data, callbacks);
          } catch {
            // Skip malformed JSON
          }
          currentEvent = '';
        } else if (line === '') {
          currentEvent = '';
        }
      }
    }
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Connection failed';
    callbacks.onError(msg);
  }
}

function handleSSEEvent(event: string, data: Record<string, unknown>, callbacks: ZStreamCallbacks) {
  switch (event) {
    case 'thinking':
      callbacks.onThinking(data.toolCalls as Array<{ name: string; status: string }>);
      break;

    case 'tool_result':
      callbacks.onToolResult(
        data.name as string,
        data.status as string,
        data.result
      );
      break;

    case 'content':
      callbacks.onContent(data.delta as string);
      break;

    case 'artifact':
      callbacks.onArtifact({
        id: data.id as string,
        type: data.type as ZArtifact['type'],
        title: data.title as string,
        content: data.content as string,
        data: (data.data as Record<string, unknown>) || {},
        versions: [{ version: 1, content: data.content as string, data: (data.data as Record<string, unknown>) || {}, editDescription: '', createdAt: new Date().toISOString() }],
        currentVersion: 1,
        status: 'ready',
        createdAt: new Date().toISOString(),
      });
      break;

    case 'done':
      callbacks.onDone({
        tokenCount: (data.tokenCount as number) || 0,
        threadId: data.threadId as string,
      });
      break;

    case 'error':
      callbacks.onError((data.message as string) || 'Unknown error');
      break;
  }
}

// Re-export simulateResponse for backwards compatibility during transition
// Remove once all mock references are eliminated
export { simulateResponse } from './mock-responses';
