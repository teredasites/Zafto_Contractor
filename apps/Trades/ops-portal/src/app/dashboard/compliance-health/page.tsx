'use client';

import { useState } from 'react';
import {
  Shield, CheckCircle2, AlertTriangle, XCircle, Clock,
  ExternalLink, ChevronDown, ChevronRight, RefreshCw,
} from 'lucide-react';
import { useComplianceHealth } from '@/lib/hooks/use-compliance-health';

const STATUS_COLORS: Record<string, { bg: string; text: string; icon: typeof CheckCircle2 }> = {
  current: { bg: 'rgba(16,185,129,0.1)', text: '#10b981', icon: CheckCircle2 },
  review_due: { bg: 'rgba(234,179,8,0.1)', text: '#eab308', icon: AlertTriangle },
  outdated: { bg: 'rgba(239,68,68,0.1)', text: '#ef4444', icon: XCircle },
  superseded: { bg: 'rgba(107,114,128,0.1)', text: '#6b7280', icon: Clock },
};

const ENTITY_LABELS: Record<string, string> = {
  contractor: 'Contractor',
  realtor: 'Realtor',
  adjuster: 'Adjuster',
  inspector: 'Inspector',
  homeowner: 'Homeowner',
  preservation: 'Preservation',
};

const CATEGORY_LABELS: Record<string, string> = {
  code_standard: 'Code Standards',
  state_law: 'State Laws',
  federal_regulation: 'Federal Regulations',
  form_template: 'Form Templates',
  seed_data: 'Seed Data',
  api_data: 'API Data',
};

type ViewMode = 'overview' | 'entity' | 'category' | 'stale' | 'history';

export default function ComplianceHealthPage() {
  const health = useComplianceHealth();
  const [view, setView] = useState<ViewMode>('overview');
  const [entityFilter, setEntityFilter] = useState<string | null>(null);
  const [expandedRef, setExpandedRef] = useState<string | null>(null);

  if (health.loading) {
    return (
      <div className="flex items-center justify-center h-64" aria-busy="true">
        <div className="w-6 h-6 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
      </div>
    );
  }

  if (health.error) {
    return (
      <div className="p-6 rounded-xl border border-red-500/20 bg-red-500/5">
        <p className="text-sm text-red-400">{health.error}</p>
      </div>
    );
  }

  const staleItems = health.references
    .filter(r => r.status === 'review_due' || r.status === 'outdated')
    .sort((a, b) => {
      if (a.status === 'outdated' && b.status !== 'outdated') return -1;
      if (b.status === 'outdated' && a.status !== 'outdated') return 1;
      return new Date(a.last_verified_at).getTime() - new Date(b.last_verified_at).getTime();
    });

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Shield size={20} className="text-accent" />
          <h1 className="text-xl font-semibold text-main">Compliance Health</h1>
        </div>
        <button
          onClick={health.refresh}
          className="flex items-center gap-2 px-3 py-1.5 text-xs text-muted hover:text-main border border-[var(--border)] rounded-lg transition-colors"
        >
          <RefreshCw size={12} />
          Refresh
        </button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-6">
        {[
          { label: 'Total', count: health.totalCount, color: '#94a3b8' },
          { label: 'Current', count: health.currentCount, color: '#10b981' },
          { label: 'Review Due', count: health.reviewDueCount, color: '#eab308' },
          { label: 'Outdated', count: health.outdatedCount, color: '#ef4444' },
          { label: 'Superseded', count: health.supersededCount, color: '#6b7280' },
        ].map((card) => (
          <div
            key={card.label}
            className="p-4 rounded-xl border"
            style={{ borderColor: 'var(--border-light)', background: 'var(--surface)' }}
          >
            <p className="text-[11px] text-muted uppercase tracking-wider mb-1">{card.label}</p>
            <p className="text-2xl font-bold" style={{ color: card.color }}>{card.count}</p>
          </div>
        ))}
      </div>

      {/* Tab Navigation */}
      <div className="flex gap-1 mb-6 border-b border-[var(--border-light)]">
        {[
          { key: 'overview', label: 'All References' },
          { key: 'entity', label: 'By Entity' },
          { key: 'category', label: 'By Category' },
          { key: 'stale', label: `Stale (${staleItems.length})` },
          { key: 'history', label: 'History' },
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setView(tab.key as ViewMode)}
            className="px-4 py-2 text-xs font-medium transition-colors -mb-px"
            style={{
              color: view === tab.key ? 'var(--accent)' : 'var(--text-muted)',
              borderBottom: view === tab.key ? '2px solid var(--accent)' : '2px solid transparent',
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Content */}
      {view === 'overview' && (
        <div className="space-y-2">
          {health.references.map((ref) => (
            <ReferenceRow
              key={ref.id}
              reference={ref}
              expanded={expandedRef === ref.id}
              onToggle={() => setExpandedRef(expandedRef === ref.id ? null : ref.id)}
              onMarkVerified={() => health.markVerified(ref.id)}
              onFlagUpdate={() => health.flagForUpdate(ref.id)}
            />
          ))}
        </div>
      )}

      {view === 'entity' && (
        <div className="space-y-6">
          <div className="flex gap-2 flex-wrap">
            {Object.keys(ENTITY_LABELS).map((entity) => (
              <button
                key={entity}
                onClick={() => setEntityFilter(entityFilter === entity ? null : entity)}
                className="px-3 py-1.5 text-xs font-medium rounded-lg border transition-colors"
                style={{
                  borderColor: entityFilter === entity ? 'var(--accent)' : 'var(--border)',
                  color: entityFilter === entity ? 'var(--accent)' : 'var(--text-muted)',
                  background: entityFilter === entity ? 'rgba(16,185,129,0.05)' : 'transparent',
                }}
              >
                {ENTITY_LABELS[entity]} ({(health.byEntityType[entity] || []).length})
              </button>
            ))}
          </div>
          {entityFilter && (
            <div className="space-y-2">
              {(health.byEntityType[entityFilter] || []).map((ref) => (
                <ReferenceRow
                  key={ref.id}
                  reference={ref}
                  expanded={expandedRef === ref.id}
                  onToggle={() => setExpandedRef(expandedRef === ref.id ? null : ref.id)}
                  onMarkVerified={() => health.markVerified(ref.id)}
                  onFlagUpdate={() => health.flagForUpdate(ref.id)}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {view === 'category' && (
        <div className="space-y-6">
          {Object.entries(health.byCategory).map(([category, refs]) => (
            <div key={category}>
              <h2 className="text-[11px] font-semibold uppercase tracking-wider text-muted mb-3">
                {CATEGORY_LABELS[category] || category} ({refs.length})
              </h2>
              <div className="space-y-2">
                {refs.map((ref) => (
                  <ReferenceRow
                    key={ref.id}
                    reference={ref}
                    expanded={expandedRef === ref.id}
                    onToggle={() => setExpandedRef(expandedRef === ref.id ? null : ref.id)}
                    onMarkVerified={() => health.markVerified(ref.id)}
                    onFlagUpdate={() => health.flagForUpdate(ref.id)}
                  />
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {view === 'stale' && (
        <div className="space-y-2">
          {staleItems.length === 0 ? (
            <div className="text-center py-12">
              <CheckCircle2 size={32} className="mx-auto mb-3 text-emerald-500" />
              <p className="text-sm text-main font-medium">All references are current</p>
              <p className="text-xs text-muted mt-1">No items need review</p>
            </div>
          ) : (
            staleItems.map((ref) => (
              <ReferenceRow
                key={ref.id}
                reference={ref}
                expanded={expandedRef === ref.id}
                onToggle={() => setExpandedRef(expandedRef === ref.id ? null : ref.id)}
                onMarkVerified={() => health.markVerified(ref.id)}
                onFlagUpdate={() => health.flagForUpdate(ref.id)}
              />
            ))
          )}
        </div>
      )}

      {view === 'history' && (
        <div className="space-y-2">
          {health.checkLogs.length === 0 ? (
            <p className="text-sm text-muted text-center py-8">No verification checks logged yet</p>
          ) : (
            health.checkLogs.map((log) => {
              const ref = health.references.find(r => r.id === log.reference_id);
              return (
                <div
                  key={log.id}
                  className="flex items-center justify-between px-4 py-3 rounded-lg border"
                  style={{ borderColor: 'var(--border-light)', background: 'var(--surface)' }}
                >
                  <div>
                    <p className="text-sm text-main">{ref?.display_name || 'Unknown reference'}</p>
                    <p className="text-xs text-muted">
                      {log.checked_by} — {log.result.replace(/_/g, ' ')}
                      {log.notes && ` — ${log.notes}`}
                    </p>
                  </div>
                  <p className="text-xs text-muted">
                    {new Date(log.checked_at).toLocaleDateString('en-US', {
                      month: 'short', day: 'numeric', year: 'numeric',
                    })}
                  </p>
                </div>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}

interface ReferenceRowProps {
  reference: {
    id: string;
    display_name: string;
    current_edition: string | null;
    status: string;
    last_verified_at: string;
    source_url: string | null;
    affects_entities: string[];
    notes: string | null;
    reference_type: string;
  };
  expanded: boolean;
  onToggle: () => void;
  onMarkVerified: () => void;
  onFlagUpdate: () => void;
}

function ReferenceRow({ reference, expanded, onToggle, onMarkVerified, onFlagUpdate }: ReferenceRowProps) {
  const statusConfig = STATUS_COLORS[reference.status] || STATUS_COLORS.current;
  const Icon = statusConfig.icon;
  const daysSinceVerified = Math.floor(
    (Date.now() - new Date(reference.last_verified_at).getTime()) / (1000 * 60 * 60 * 24)
  );

  return (
    <div
      className="rounded-lg border overflow-hidden"
      style={{ borderColor: 'var(--border-light)', background: 'var(--surface)' }}
    >
      <button
        onClick={onToggle}
        className="w-full flex items-center gap-3 px-4 py-3 text-left"
      >
        <div
          className="w-6 h-6 rounded-full flex items-center justify-center shrink-0"
          style={{ background: statusConfig.bg }}
        >
          <Icon size={12} style={{ color: statusConfig.text }} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm text-main truncate">{reference.display_name}</p>
          <p className="text-[11px] text-muted">
            {reference.current_edition && `${reference.current_edition} · `}
            Verified {daysSinceVerified}d ago
          </p>
        </div>
        <div className="flex items-center gap-2">
          {reference.source_url && (
            <a
              href={reference.source_url}
              target="_blank"
              rel="noopener noreferrer"
              onClick={(e) => e.stopPropagation()}
              className="text-muted hover:text-accent transition-colors"
            >
              <ExternalLink size={12} />
            </a>
          )}
          {expanded ? <ChevronDown size={14} className="text-muted" /> : <ChevronRight size={14} className="text-muted" />}
        </div>
      </button>

      {expanded && (
        <div className="px-4 pb-3 pt-0 border-t border-[var(--border-light)]">
          {reference.notes && (
            <p className="text-xs text-muted mt-2 mb-3">{reference.notes}</p>
          )}
          <div className="flex items-center gap-3 flex-wrap mt-2">
            {(reference.affects_entities || []).map((entity) => (
              <span
                key={entity}
                className="px-2 py-0.5 text-[10px] rounded-full"
                style={{ background: 'rgba(255,255,255,0.05)', color: 'var(--text-muted)' }}
              >
                {ENTITY_LABELS[entity] || entity}
              </span>
            ))}
          </div>
          <div className="flex gap-2 mt-3">
            <button
              onClick={onMarkVerified}
              className="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors"
              style={{ background: 'rgba(16,185,129,0.1)', color: '#10b981' }}
            >
              Mark Verified
            </button>
            <button
              onClick={onFlagUpdate}
              className="px-3 py-1.5 text-[11px] font-medium rounded-lg transition-colors"
              style={{ background: 'rgba(234,179,8,0.1)', color: '#eab308' }}
            >
              Needs Update
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
