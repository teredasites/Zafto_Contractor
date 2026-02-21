'use client';

// DEPTH27: DraftRecoveryBanner — global toast + recovery pill
// Place once in app shell. Shows recovered draft notifications.

import { useState, useEffect, useCallback } from 'react';
import { useAllDrafts } from '@/lib/hooks/use-draft-recovery';
import { deleteDraft, type DraftRecord } from '@/lib/draft-manager';
import { FileText, X, Pin, Trash2, ChevronUp, ChevronDown, Clock } from 'lucide-react';

const FEATURE_ICONS: Record<string, string> = {
  sketch: 'Sketch',
  bid: 'Bid',
  invoice: 'Invoice',
  estimate: 'Estimate',
  walkthrough: 'Walkthrough',
  inspection: 'Inspection',
  form: 'Form',
  settings: 'Settings',
  calendar: 'Schedule',
  ledger: 'Journal Entry',
  customer: 'Customer',
  job: 'Job',
  property: 'Property',
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

export function DraftRecoveryBanner() {
  const { drafts, loading } = useAllDrafts();
  const [dismissed, setDismissed] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [localDrafts, setLocalDrafts] = useState<DraftRecord[]>([]);
  const [toastVisible, setToastVisible] = useState(false);

  useEffect(() => {
    if (!loading && drafts.length > 0) {
      setLocalDrafts(drafts);
      setToastVisible(true);
      // Auto-hide toast after 30s, show pill
      const timer = setTimeout(() => setToastVisible(false), 30000);
      return () => clearTimeout(timer);
    }
  }, [drafts, loading]);

  const handleDiscard = useCallback(async (draft: DraftRecord) => {
    await deleteDraft(draft.feature, draft.key);
    setLocalDrafts(prev => prev.filter(d => d.id !== draft.id));
  }, []);

  const handleNavigate = useCallback((draft: DraftRecord) => {
    // Navigate to the screen where the draft was created
    if (draft.screenRoute) {
      window.location.href = draft.screenRoute;
    }
  }, []);

  if (loading || localDrafts.length === 0 || dismissed) return null;

  // Toast mode (first 30 seconds)
  if (toastVisible) {
    return (
      <div className="fixed bottom-4 right-4 z-50 max-w-sm animate-in slide-in-from-bottom-4">
        <div className="bg-surface border border-border rounded-lg shadow-lg p-4">
          <div className="flex items-start gap-3">
            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500/10 flex items-center justify-center">
              <FileText size={16} className="text-blue-500" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium" style={{ color: 'var(--text)' }}>
                Recovered {localDrafts.length} unsaved {localDrafts.length === 1 ? 'draft' : 'drafts'}
              </p>
              <p className="text-xs mt-0.5" style={{ color: 'var(--text-muted)' }}>
                {localDrafts[0] && (
                  <>
                    {FEATURE_ICONS[localDrafts[0].feature] || localDrafts[0].feature} from {timeAgo(localDrafts[0].updatedAt)}
                    {localDrafts.length > 1 && ` + ${localDrafts.length - 1} more`}
                  </>
                )}
              </p>
              <button
                onClick={() => { setToastVisible(false); setExpanded(true); }}
                className="text-xs text-blue-500 hover:text-blue-400 mt-1.5 font-medium"
              >
                View all
              </button>
            </div>
            <button
              onClick={() => { setToastVisible(false); }}
              className="flex-shrink-0 p-1 rounded hover:bg-surface-hover"
            >
              <X size={14} style={{ color: 'var(--text-muted)' }} />
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Pill mode (after toast auto-hides)
  return (
    <div className="fixed bottom-4 right-4 z-50">
      {/* Expanded draft list */}
      {expanded && (
        <div className="mb-2 bg-surface border border-border rounded-lg shadow-lg w-80 max-h-96 overflow-y-auto">
          <div className="p-3 border-b border-border flex items-center justify-between">
            <span className="text-sm font-medium" style={{ color: 'var(--text)' }}>
              Unsaved Drafts ({localDrafts.length})
            </span>
            <button onClick={() => setDismissed(true)} className="text-xs" style={{ color: 'var(--text-muted)' }}>
              Dismiss all
            </button>
          </div>
          <div className="divide-y divide-border">
            {localDrafts.map((d) => (
              <div key={d.id} className="p-3 hover:bg-surface-hover transition-colors">
                <div className="flex items-center gap-2">
                  <FileText size={14} className="text-blue-500 flex-shrink-0" />
                  <span className="text-sm font-medium truncate" style={{ color: 'var(--text)' }}>
                    {FEATURE_ICONS[d.feature] || d.feature}
                  </span>
                  {d.isPinned && <Pin size={12} className="text-amber-500 flex-shrink-0" />}
                  <span className="text-xs ml-auto flex-shrink-0 flex items-center gap-1" style={{ color: 'var(--text-muted)' }}>
                    <Clock size={10} /> {timeAgo(d.updatedAt)}
                  </span>
                </div>
                <p className="text-xs mt-1 truncate" style={{ color: 'var(--text-muted)' }}>
                  {d.screenRoute}
                </p>
                <div className="flex items-center gap-2 mt-2">
                  <button
                    onClick={() => handleNavigate(d)}
                    className="text-xs px-2 py-1 rounded bg-blue-600 text-white hover:bg-blue-500"
                  >
                    Resume
                  </button>
                  <button
                    onClick={() => handleDiscard(d)}
                    className="text-xs px-2 py-1 rounded border border-border hover:bg-surface-hover flex items-center gap-1"
                    style={{ color: 'var(--text-muted)' }}
                  >
                    <Trash2 size={10} /> Discard
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Pill button */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="flex items-center gap-2 px-3 py-2 rounded-full bg-surface border border-border shadow-lg hover:bg-surface-hover transition-colors"
      >
        <FileText size={14} className="text-blue-500" />
        <span className="text-xs font-medium" style={{ color: 'var(--text)' }}>
          {localDrafts.length} unsaved {localDrafts.length === 1 ? 'draft' : 'drafts'}
        </span>
        {expanded ? <ChevronDown size={12} /> : <ChevronUp size={12} />}
      </button>
    </div>
  );
}
