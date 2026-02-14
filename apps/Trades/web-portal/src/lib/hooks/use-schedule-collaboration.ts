'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';

// ══════════════════════════════════════════════════════════════
// TYPES
// ══════════════════════════════════════════════════════════════

interface ConnectedUser {
  user_id: string;
  user_name: string;
  avatar_url?: string;
  color: string;
  joined_at: string;
}

interface TaskLock {
  task_id: string;
  user_id: string;
  user_name: string;
  expires_at: string;
}

interface TaskConflict {
  task_id: string;
  task_name: string;
  field: string;
  your_value: string;
  their_value: string;
  their_user: string;
}

// ══════════════════════════════════════════════════════════════
// PRESENCE + LOCKS HOOK
// ══════════════════════════════════════════════════════════════

const USER_COLORS = [
  '#3b82f6', '#ef4444', '#22c55e', '#f59e0b', '#8b5cf6',
  '#ec4899', '#14b8a6', '#f97316', '#06b6d4', '#6366f1',
];

export function useScheduleCollaboration(projectId: string | undefined) {
  const [connectedUsers, setConnectedUsers] = useState<ConnectedUser[]>([]);
  const [taskLocks, setTaskLocks] = useState<TaskLock[]>([]);
  const [conflicts, setConflicts] = useState<TaskConflict[]>([]);

  const channelRef = useRef<ReturnType<ReturnType<typeof getSupabase>['channel']> | null>(null);
  const lockExtendIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const currentLockRef = useRef<string | null>(null);

  // ── Join channel ──
  useEffect(() => {
    if (!projectId) return;

    const supabase = getSupabase();
    let channelInstance: ReturnType<typeof supabase.channel> | null = null;

    const setup = async () => {
      const { data: { user: u } } = await supabase.auth.getUser();
      if (!u) return;

      const userId = u.id;
      const userName = (u.user_metadata?.full_name as string) || u.email || 'Unknown';
      const colorIdx = userId.charCodeAt(0) % USER_COLORS.length;
      const color = USER_COLORS[colorIdx];

      const channel = supabase.channel(`schedule:${projectId}`, {
        config: {
          presence: { key: userId },
        },
      });

      // Presence tracking
      channel.on('presence', { event: 'sync' }, () => {
        const state = channel.presenceState();
        const users: ConnectedUser[] = [];
        for (const [, presences] of Object.entries(state)) {
          const presence = (presences as Record<string, unknown>[])[0];
          if (presence) {
            users.push({
              user_id: presence.user_id as string,
              user_name: presence.user_name as string,
              avatar_url: presence.avatar_url as string | undefined,
              color: presence.color as string,
              joined_at: presence.joined_at as string,
            });
          }
        }
        setConnectedUsers(users.filter(cu => cu.user_id !== userId));
      });

      // Task lock events
      channel.on('broadcast', { event: 'task_lock' }, (msg: { payload: unknown }) => {
        const lock = msg.payload as TaskLock;
        setTaskLocks(prev => {
          const filtered = prev.filter(l => l.task_id !== lock.task_id);
          return [...filtered, lock];
        });
      });

      channel.on('broadcast', { event: 'task_unlock' }, (msg: { payload: unknown }) => {
        const { task_id } = msg.payload as { task_id: string };
        setTaskLocks(prev => prev.filter(l => l.task_id !== task_id));
      });

      // Task update events (for conflict detection)
      channel.on('broadcast', { event: 'task_update' }, (msg: { payload: unknown }) => {
        const update = msg.payload as {
          task_id: string;
          task_name: string;
          field: string;
          value: string;
          user_id: string;
          user_name: string;
        };

        // If another user updated a task we're currently editing, flag conflict
        if (currentLockRef.current === update.task_id && update.user_id !== userId) {
          setConflicts(prev => [
            ...prev,
            {
              task_id: update.task_id,
              task_name: update.task_name,
              field: update.field,
              your_value: '', // Caller fills this
              their_value: update.value,
              their_user: update.user_name,
            },
          ]);
        }
      });

      channel.subscribe(async (status: string) => {
        if (status === 'SUBSCRIBED') {
          await channel.track({
            user_id: userId,
            user_name: userName,
            avatar_url: u.user_metadata?.avatar_url,
            color,
            joined_at: new Date().toISOString(),
          });
        }
      });

      channelRef.current = channel;
      channelInstance = channel;
    };

    setup();

    return () => {
      if (channelRef.current) {
        const sb = getSupabase();
        sb.removeChannel(channelRef.current);
        channelRef.current = null;
      }
      if (channelInstance) {
        const sb = getSupabase();
        sb.removeChannel(channelInstance);
      }
      if (lockExtendIntervalRef.current) {
        clearInterval(lockExtendIntervalRef.current);
        lockExtendIntervalRef.current = null;
      }
    };
  }, [projectId]);

  // ── Acquire lock ──
  const acquireLock = useCallback(async (taskId: string): Promise<boolean> => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    const userId = user.id;
    const userName = user.user_metadata?.full_name || user.email || 'Unknown';

    // Check existing lock
    const existing = taskLocks.find(l => l.task_id === taskId);
    if (existing && existing.user_id !== userId) {
      return false; // Locked by another user
    }

    const expiresAt = new Date(Date.now() + 30000).toISOString(); // 30s

    // Insert/upsert lock in DB
    const { error } = await supabase
      .from('schedule_task_locks')
      .upsert({
        task_id: taskId,
        user_id: userId,
        user_name: userName,
        expires_at: expiresAt,
      }, { onConflict: 'task_id' });

    if (error) return false;

    // Broadcast lock
    channelRef.current?.send({
      type: 'broadcast',
      event: 'task_lock',
      payload: { task_id: taskId, user_id: userId, user_name: userName, expires_at: expiresAt },
    });

    currentLockRef.current = taskId;

    // Auto-extend every 15s
    if (lockExtendIntervalRef.current) clearInterval(lockExtendIntervalRef.current);
    lockExtendIntervalRef.current = setInterval(async () => {
      const newExpiry = new Date(Date.now() + 30000).toISOString();
      await supabase
        .from('schedule_task_locks')
        .update({ expires_at: newExpiry })
        .eq('task_id', taskId)
        .eq('user_id', userId);
    }, 15000);

    return true;
  }, [taskLocks]);

  // ── Release lock ──
  const releaseLock = useCallback(async (taskId: string) => {
    const supabase = getSupabase();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return;

    await supabase
      .from('schedule_task_locks')
      .delete()
      .eq('task_id', taskId)
      .eq('user_id', user.id);

    channelRef.current?.send({
      type: 'broadcast',
      event: 'task_unlock',
      payload: { task_id: taskId },
    });

    if (lockExtendIntervalRef.current) {
      clearInterval(lockExtendIntervalRef.current);
      lockExtendIntervalRef.current = null;
    }
    currentLockRef.current = null;
  }, []);

  // ── Broadcast task update ──
  const broadcastTaskUpdate = useCallback(async (taskId: string, taskName: string, field: string, value: string) => {
    const supabase = getSupabase();
    const { data: { user: currentUser } } = await supabase.auth.getUser();
    if (!currentUser) return;
    channelRef.current?.send({
      type: 'broadcast',
      event: 'task_update',
      payload: {
        task_id: taskId,
        task_name: taskName,
        field,
        value,
        user_id: currentUser.id,
        user_name: (currentUser.user_metadata?.full_name as string) || currentUser.email || 'Unknown',
      },
    });
  }, []);

  // ── Check if task is locked by another user ──
  const isLockedByOther = useCallback((taskId: string): TaskLock | null => {
    const lock = taskLocks.find(l => l.task_id === taskId);
    if (!lock) return null;

    // Check if expired
    if (new Date(lock.expires_at) < new Date()) return null;

    return lock;
  }, [taskLocks]);

  // ── Dismiss conflict ──
  const dismissConflict = useCallback((taskId: string) => {
    setConflicts(prev => prev.filter(c => c.task_id !== taskId));
  }, []);

  return {
    connectedUsers,
    taskLocks,
    conflicts,
    acquireLock,
    releaseLock,
    broadcastTaskUpdate,
    isLockedByOther,
    dismissConflict,
  };
}
