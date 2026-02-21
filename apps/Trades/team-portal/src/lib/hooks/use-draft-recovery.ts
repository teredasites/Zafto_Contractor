'use client';

// DEPTH27: useDraftRecovery — drop-in hook for any page with form/editor state
// Provides: auto-save to IndexedDB (3s debounce), cloud sync to Supabase (60s),
// crash recovery on mount, checksum validation, pin support

import { useState, useEffect, useCallback, useRef } from 'react';
import { getSupabase } from '@/lib/supabase';
import {
  saveDraft,
  loadDraft,
  deleteDraft,
  pinDraft as pinDraftLocal,
  listDrafts,
  replayWAL,
  evictStale,
  type DraftRecord,
} from '@/lib/draft-manager';

interface UseDraftRecoveryOptions {
  /** Feature category: sketch, bid, invoice, estimate, etc. */
  feature: string;
  /** Unique key within the feature (e.g., sketch ID, bid ID, 'new') */
  key: string;
  /** Current screen route for display in recovery UI */
  screenRoute: string;
  /** Local save debounce in ms (default 3000) */
  localDebounceMs?: number;
  /** Cloud sync interval in ms (default 60000) */
  cloudSyncMs?: number;
  /** Whether to auto-save (default true) */
  enabled?: boolean;
}

interface UseDraftRecoveryReturn {
  /** The recovered draft data, if any was found on mount */
  draft: DraftRecord | null;
  /** Whether a draft was found on mount */
  hasDraft: boolean;
  /** Loading state while checking for drafts */
  checking: boolean;
  /** Restore the draft (returns parsed state) */
  restoreDraft: () => unknown | null;
  /** Discard the recovered draft permanently */
  discardDraft: () => Promise<void>;
  /** Save current state as draft (called automatically on debounce, or manually) */
  saveDraft: (state: unknown) => void;
  /** Whether this draft is pinned */
  isPinned: boolean;
  /** Toggle pin status */
  togglePin: () => Promise<void>;
  /** Force immediate cloud sync */
  forceSync: () => Promise<void>;
  /** Mark draft as recovered (clears it from recovery list) */
  markRecovered: () => Promise<void>;
}

export function useDraftRecovery(opts: UseDraftRecoveryOptions): UseDraftRecoveryReturn {
  const {
    feature,
    key,
    screenRoute,
    localDebounceMs = 3000,
    cloudSyncMs = 60000,
    enabled = true,
  } = opts;

  const [draft, setDraft] = useState<DraftRecord | null>(null);
  const [hasDraft, setHasDraft] = useState(false);
  const [checking, setChecking] = useState(true);
  const [isPinned, setIsPinned] = useState(false);

  const pendingStateRef = useRef<unknown>(null);
  const localTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const cloudTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastSyncedVersionRef = useRef<number>(0);
  const metaRef = useRef({ companyId: '', userId: '' });

  // On mount: replay WAL, check for local draft, check cloud
  useEffect(() => {
    if (!enabled) {
      setChecking(false);
      return;
    }

    let cancelled = false;

    async function init() {
      try {
        // Replay any unapplied WAL entries from previous crash
        await replayWAL();

        // Evict stale drafts (30+ days, non-pinned)
        await evictStale();

        // Get user info for meta
        const supabase = getSupabase();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user || cancelled) { setChecking(false); return; }

        const companyId = user.app_metadata?.company_id || '';
        metaRef.current = { companyId, userId: user.id };

        // Check local first (faster)
        const local = await loadDraft(feature, key);

        // Check cloud for potentially newer draft
        let cloudDraft: DraftRecord | null = null;
        try {
          const { data } = await supabase
            .from('draft_recovery')
            .select('*')
            .eq('user_id', user.id)
            .eq('feature', feature)
            .eq('is_active', true)
            .is('deleted_at', null)
            .is('recovered_at', null)
            .order('updated_at', { ascending: false })
            .limit(1)
            .maybeSingle();

          if (data) {
            cloudDraft = {
              id: `${feature}::${key}`,
              feature: data.feature,
              key,
              screenRoute: data.screen_route,
              companyId: data.company_id,
              userId: data.user_id,
              stateJson: JSON.stringify(data.state_json),
              checksum: data.checksum,
              version: data.version,
              isPinned: data.is_pinned,
              createdAt: data.created_at,
              updatedAt: data.updated_at,
            };
          }
        } catch {
          // Cloud check failed — use local only
        }

        if (cancelled) return;

        // Pick the newer one
        let best: DraftRecord | null = null;
        if (local && cloudDraft) {
          best = local.updatedAt >= cloudDraft.updatedAt ? local : cloudDraft;
        } else {
          best = local || cloudDraft;
        }

        if (best) {
          setDraft(best);
          setHasDraft(true);
          setIsPinned(best.isPinned);
          lastSyncedVersionRef.current = best.version;
        }
      } catch {
        // Silently fail — draft recovery is best-effort
      } finally {
        if (!cancelled) setChecking(false);
      }
    }

    init();
    return () => { cancelled = true; };
  }, [feature, key, enabled]);

  // Cloud sync interval
  useEffect(() => {
    if (!enabled || cloudSyncMs <= 0) return;

    cloudTimerRef.current = setInterval(() => {
      syncToCloud();
    }, cloudSyncMs);

    return () => {
      if (cloudTimerRef.current) clearInterval(cloudTimerRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, cloudSyncMs]);

  // Lifecycle hooks: beforeunload + visibilitychange
  useEffect(() => {
    if (!enabled) return;

    const handleBeforeUnload = () => {
      // Synchronous local save — fire-and-forget cloud
      if (pendingStateRef.current !== null) {
        // Can't await in beforeunload — use sendBeacon for cloud
        const meta = metaRef.current;
        if (meta.userId) {
          saveDraft(feature, key, pendingStateRef.current, {
            screenRoute,
            companyId: meta.companyId,
            userId: meta.userId,
          }).catch(() => {});

          // sendBeacon for cloud sync as last resort
          try {
            const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
            const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
            if (supabaseUrl && supabaseKey) {
              const payload = JSON.stringify({
                feature,
                screen_route: screenRoute,
                state_json: pendingStateRef.current,
                device_type: 'web',
                is_active: true,
              });
              navigator.sendBeacon(
                `${supabaseUrl}/rest/v1/draft_recovery`,
                new Blob([payload], { type: 'application/json' })
              );
            }
          } catch {
            // Best effort
          }
        }
      }
    };

    const handleVisibilityChange = () => {
      if (document.hidden) {
        // Tab hidden — save immediately
        if (pendingStateRef.current !== null) {
          flushLocal();
        }
      }
    };

    window.addEventListener('beforeunload', handleBeforeUnload);
    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      window.removeEventListener('beforeunload', handleBeforeUnload);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, feature, key, screenRoute]);

  const flushLocal = useCallback(async () => {
    const state = pendingStateRef.current;
    if (state === null) return;

    const meta = metaRef.current;
    if (!meta.userId) return;

    try {
      await saveDraft(feature, key, state, {
        screenRoute,
        companyId: meta.companyId,
        userId: meta.userId,
      });
    } catch {
      // Local save failed — will retry next debounce
    }
  }, [feature, key, screenRoute]);

  const syncToCloud = useCallback(async () => {
    try {
      const local = await loadDraft(feature, key);
      if (!local || local.version <= lastSyncedVersionRef.current) return;

      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const deviceId = getDeviceId();

      const { error } = await supabase
        .from('draft_recovery')
        .upsert({
          id: undefined, // Let Supabase generate
          company_id: local.companyId,
          user_id: local.userId,
          feature: local.feature,
          screen_route: local.screenRoute,
          state_json: JSON.parse(local.stateJson),
          state_size_bytes: new Blob([local.stateJson]).size,
          device_id: deviceId,
          device_type: 'web',
          version: local.version,
          is_active: true,
          is_pinned: local.isPinned,
          checksum: local.checksum,
          updated_at: local.updatedAt,
        }, {
          onConflict: 'user_id,feature,screen_route',
          ignoreDuplicates: false,
        })
        .select()
        .single();

      if (!error) {
        lastSyncedVersionRef.current = local.version;
      }
    } catch {
      // Cloud sync failed — retry next interval
    }
  }, [feature, key]);

  // Save state (debounced)
  const saveState = useCallback((state: unknown) => {
    pendingStateRef.current = state;

    if (localTimerRef.current) {
      clearTimeout(localTimerRef.current);
    }

    localTimerRef.current = setTimeout(() => {
      flushLocal();
    }, localDebounceMs);
  }, [flushLocal, localDebounceMs]);

  const restoreDraftFn = useCallback(() => {
    if (!draft) return null;
    try {
      return JSON.parse(draft.stateJson);
    } catch {
      return null;
    }
  }, [draft]);

  const discardDraftFn = useCallback(async () => {
    await deleteDraft(feature, key);
    setDraft(null);
    setHasDraft(false);

    // Also mark as recovered in cloud
    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase
          .from('draft_recovery')
          .update({ recovered_at: new Date().toISOString(), is_active: false })
          .eq('user_id', user.id)
          .eq('feature', feature)
          .is('deleted_at', null);
      }
    } catch {
      // Best effort
    }
  }, [feature, key]);

  const togglePinFn = useCallback(async () => {
    const newPinned = !isPinned;
    await pinDraftLocal(feature, key, newPinned);
    setIsPinned(newPinned);
  }, [feature, key, isPinned]);

  const forceSyncFn = useCallback(async () => {
    await flushLocal();
    await syncToCloud();
  }, [flushLocal, syncToCloud]);

  const markRecoveredFn = useCallback(async () => {
    setDraft(null);
    setHasDraft(false);

    try {
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        await supabase
          .from('draft_recovery')
          .update({ recovered_at: new Date().toISOString(), is_active: false })
          .eq('user_id', user.id)
          .eq('feature', feature)
          .is('deleted_at', null);
      }
    } catch {
      // Best effort
    }
  }, [feature]);

  return {
    draft,
    hasDraft,
    checking,
    restoreDraft: restoreDraftFn,
    discardDraft: discardDraftFn,
    saveDraft: saveState,
    isPinned,
    togglePin: togglePinFn,
    forceSync: forceSyncFn,
    markRecovered: markRecoveredFn,
  };
}

/** List all active drafts for the current user (for recovery pill UI) */
export function useAllDrafts() {
  const [drafts, setDrafts] = useState<DraftRecord[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      try {
        const supabase = getSupabase();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user || cancelled) { setLoading(false); return; }

        const all = await listDrafts({ userId: user.id });
        if (!cancelled) setDrafts(all);
      } catch {
        // Silently fail
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();
    return () => { cancelled = true; };
  }, []);

  return { drafts, loading };
}

// Stable device ID — persisted in localStorage
function getDeviceId(): string {
  if (typeof window === 'undefined') return 'server';
  const key = 'zafto-device-id';
  let id = localStorage.getItem(key);
  if (!id) {
    id = `web-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
    localStorage.setItem(key, id);
  }
  return id;
}
