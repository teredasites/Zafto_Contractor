'use client';

// ZAFTO History Panel — SK7
// Shows version history snapshots with preview and restore.
// Timeline view: date, label, reason. Restore with confirmation.

import { useState, useCallback } from 'react';
import { History, RotateCcw, Trash2, X, Clock, Tag, Plus } from 'lucide-react';
import type { FloorPlanSnapshot } from '@/lib/hooks/use-floor-plan-snapshots';
import type { FloorPlanData } from '@/lib/sketch-engine/types';

interface HistoryPanelProps {
  snapshots: FloorPlanSnapshot[];
  loading: boolean;
  currentPlanData: FloorPlanData;
  onCreateSnapshot: (planData: FloorPlanData, reason: string, label?: string) => Promise<FloorPlanSnapshot | null>;
  onRestoreSnapshot: (snapshot: FloorPlanSnapshot) => Promise<FloorPlanData | null>;
  onDeleteSnapshot: (snapshotId: string) => Promise<void>;
  onClose: () => void;
}

export default function HistoryPanel({
  snapshots,
  loading,
  currentPlanData,
  onCreateSnapshot,
  onRestoreSnapshot,
  onDeleteSnapshot,
  onClose,
}: HistoryPanelProps) {
  const [restoring, setRestoring] = useState<string | null>(null);
  const [confirmRestore, setConfirmRestore] = useState<string | null>(null);
  const [saveLabel, setSaveLabel] = useState('');
  const [showSaveInput, setShowSaveInput] = useState(false);

  const handleSaveVersion = useCallback(async () => {
    const label = saveLabel.trim() || undefined;
    await onCreateSnapshot(currentPlanData, 'manual', label);
    setSaveLabel('');
    setShowSaveInput(false);
  }, [currentPlanData, onCreateSnapshot, saveLabel]);

  const handleRestore = useCallback(async (snapshot: FloorPlanSnapshot) => {
    setRestoring(snapshot.id);
    try {
      // Create safety snapshot of current state before restoring
      await onCreateSnapshot(currentPlanData, 'before_restore', 'Before restore');
      await onRestoreSnapshot(snapshot);
    } finally {
      setRestoring(null);
      setConfirmRestore(null);
    }
  }, [currentPlanData, onCreateSnapshot, onRestoreSnapshot]);

  const formatTime = (dateStr: string) => {
    const d = new Date(dateStr);
    return d.toLocaleString(undefined, {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const reasonLabel = (reason: string) => {
    switch (reason) {
      case 'session_start': return 'Session Start';
      case 'auto': return 'Auto-save';
      case 'manual': return 'Manual Save';
      case 'before_change_order': return 'Pre-Change Order';
      case 'before_restore': return 'Pre-Restore';
      default: return reason;
    }
  };

  const reasonColor = (reason: string) => {
    switch (reason) {
      case 'manual': return 'text-emerald-400 bg-emerald-900/30';
      case 'session_start': return 'text-blue-400 bg-blue-900/30';
      case 'before_change_order': return 'text-amber-400 bg-amber-900/30';
      case 'before_restore': return 'text-purple-400 bg-purple-900/30';
      default: return 'text-muted bg-secondary';
    }
  };

  return (
    <div className="w-72 bg-surface border border-main rounded-lg shadow-xl overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-main">
        <div className="flex items-center gap-2">
          <History className="h-4 w-4 text-muted" />
          <span className="text-xs font-semibold text-main">Version History</span>
          <span className="text-[10px] text-muted">({snapshots.length})</span>
        </div>
        <button onClick={onClose} className="p-1 rounded hover:bg-surface-hover text-muted">
          <X size={14} />
        </button>
      </div>

      {/* Save Version */}
      <div className="px-3 py-2 border-b border-main">
        {showSaveInput ? (
          <div className="flex gap-1.5">
            <input
              type="text"
              value={saveLabel}
              onChange={(e) => setSaveLabel(e.target.value)}
              placeholder="Version label..."
              className="flex-1 px-2 py-1 text-xs bg-secondary border border-muted rounded text-main placeholder:text-muted focus:outline-none focus:border-emerald-500"
              autoFocus
              onKeyDown={(e) => { if (e.key === 'Enter') handleSaveVersion(); if (e.key === 'Escape') setShowSaveInput(false); }}
            />
            <button
              onClick={handleSaveVersion}
              className="px-2 py-1 text-xs bg-emerald-600 hover:bg-emerald-500 text-white rounded"
            >
              Save
            </button>
          </div>
        ) : (
          <button
            onClick={() => setShowSaveInput(true)}
            className="flex items-center gap-1.5 w-full px-2 py-1.5 text-xs text-main hover:bg-secondary rounded transition-colors"
          >
            <Plus size={12} />
            Save Version
          </button>
        )}
      </div>

      {/* Snapshot list */}
      <div className="max-h-80 overflow-y-auto">
        {loading && (
          <div className="px-3 py-6 text-center text-xs text-muted">
            Loading history...
          </div>
        )}

        {!loading && snapshots.length === 0 && (
          <div className="px-3 py-6 text-center text-xs text-muted">
            No snapshots yet
          </div>
        )}

        {snapshots.map((snap) => (
          <div
            key={snap.id}
            className="px-3 py-2 border-b border-main hover:bg-surface-hover transition-colors group"
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <Clock className="h-3 w-3 text-muted flex-shrink-0" />
                  <span className="text-[11px] text-main">{formatTime(snap.createdAt)}</span>
                </div>
                {snap.snapshotLabel && (
                  <div className="flex items-center gap-1 mt-0.5">
                    <Tag className="h-2.5 w-2.5 text-muted" />
                    <span className="text-[10px] text-muted truncate">{snap.snapshotLabel}</span>
                  </div>
                )}
                <span className={`inline-block mt-1 px-1.5 py-0.5 text-[9px] rounded ${reasonColor(snap.snapshotReason)}`}>
                  {reasonLabel(snap.snapshotReason)}
                </span>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                {confirmRestore === snap.id ? (
                  <button
                    onClick={() => handleRestore(snap)}
                    disabled={restoring === snap.id}
                    className="px-1.5 py-0.5 text-[10px] bg-amber-600 hover:bg-amber-500 text-white rounded"
                  >
                    {restoring === snap.id ? '...' : 'Confirm'}
                  </button>
                ) : (
                  <button
                    onClick={() => setConfirmRestore(snap.id)}
                    className="p-1 rounded hover:bg-surface-hover text-muted hover:text-amber-400"
                    title="Restore this version"
                  >
                    <RotateCcw size={12} />
                  </button>
                )}
                <button
                  onClick={() => onDeleteSnapshot(snap.id)}
                  className="p-1 rounded hover:bg-surface-hover text-muted hover:text-red-400"
                  title="Delete snapshot"
                >
                  <Trash2 size={12} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
