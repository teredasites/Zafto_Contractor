// ZAFTO Sketch Collaboration — Realtime cursors & presence (SK14)
// Uses Supabase Realtime channels for multi-user editing awareness.
// Broadcasts cursor position, active tool, and presence.

import type { Point, SketchTool } from './types';

export interface CollaboratorCursor {
  userId: string;
  userName: string;
  color: string;
  position: Point;
  activeTool: SketchTool;
  lastSeen: number; // timestamp
}

export interface PresenceState {
  userId: string;
  userName: string;
  color: string;
  isEditing: boolean;
  editingElementId: string | null;
}

// Cursor colors for up to 8 collaborators
const CURSOR_COLORS = [
  '#EF4444', '#3B82F6', '#10B981', '#F59E0B',
  '#8B5CF6', '#EC4899', '#06B6D4', '#F97316',
];

export function getCursorColor(index: number): string {
  return CURSOR_COLORS[index % CURSOR_COLORS.length];
}

// Channel name for a specific floor plan
export function getChannelName(planId: string): string {
  return `sketch:${planId}`;
}

// Presence timeout — remove cursors not updated in 10s
const PRESENCE_TIMEOUT = 10_000;

export function isPresenceStale(cursor: CollaboratorCursor): boolean {
  return Date.now() - cursor.lastSeen > PRESENCE_TIMEOUT;
}

// ── Cursor message types ──

export interface CursorMoveMessage {
  type: 'cursor_move';
  userId: string;
  userName: string;
  color: string;
  position: Point;
  activeTool: SketchTool;
}

export interface ElementLockMessage {
  type: 'element_lock';
  userId: string;
  userName: string;
  elementId: string;
  locked: boolean;
}

export type CollaborationMessage = CursorMoveMessage | ElementLockMessage;

// ── Lock tracker ──

export class ElementLockTracker {
  private locks = new Map<string, { userId: string; userName: string }>();

  lock(elementId: string, userId: string, userName: string): boolean {
    const existing = this.locks.get(elementId);
    if (existing && existing.userId !== userId) {
      return false; // already locked by someone else
    }
    this.locks.set(elementId, { userId, userName });
    return true;
  }

  unlock(elementId: string, userId: string): boolean {
    const existing = this.locks.get(elementId);
    if (!existing || existing.userId !== userId) return false;
    this.locks.delete(elementId);
    return true;
  }

  isLocked(elementId: string): boolean {
    return this.locks.has(elementId);
  }

  getLocker(elementId: string): { userId: string; userName: string } | null {
    return this.locks.get(elementId) ?? null;
  }

  unlockAll(userId: string): void {
    for (const [key, val] of this.locks) {
      if (val.userId === userId) this.locks.delete(key);
    }
  }
}
