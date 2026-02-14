'use client';

// J4: Estimate Adjustment Suggestions — accept/dismiss pricing corrections

import Link from 'next/link';
import {
  ArrowLeft,
  Lightbulb,
  Check,
  X,
  PlayCircle,
  AlertTriangle,
  TrendingUp,
} from 'lucide-react';
import { useJobIntelligence } from '@/lib/hooks/use-job-intelligence';

export default function AdjustmentsPage() {
  const { adjustments, updateAdjustmentStatus, loading, error } = useJobIntelligence();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin h-8 w-8 border-2 border-blue-500 border-t-transparent rounded-full" />
      </div>
    );
  }

  const pending = adjustments.filter((a) => a.status === 'pending');
  const accepted = adjustments.filter((a) => a.status === 'accepted');
  const applied = adjustments.filter((a) => a.status === 'applied');
  const dismissed = adjustments.filter((a) => a.status === 'dismissed');

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <Link
        href="/dashboard/job-intelligence"
        className="inline-flex items-center gap-2 text-sm text-zinc-400 hover:text-zinc-200 mb-6"
      >
        <ArrowLeft className="h-4 w-4" /> Back to Intelligence
      </Link>

      <div className="flex items-center gap-3 mb-6">
        <Lightbulb className="h-6 w-6 text-amber-400" />
        <div>
          <h1 className="text-2xl font-semibold text-white">Pricing Adjustments</h1>
          <p className="text-sm text-zinc-500">
            Smart suggestions based on job cost analysis
          </p>
        </div>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-4 mb-6 flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-red-400" />
          <p className="text-sm text-red-300">{error}</p>
        </div>
      )}

      {adjustments.length === 0 ? (
        <div className="bg-zinc-800/50 border border-zinc-700/50 rounded-xl p-12 text-center">
          <TrendingUp className="h-12 w-12 text-zinc-600 mx-auto mb-4" />
          <p className="text-zinc-400">No pricing adjustments yet</p>
          <p className="text-zinc-600 text-sm mt-2">
            Complete 5+ jobs of the same type with consistent variance to trigger suggestions
          </p>
        </div>
      ) : (
        <div className="space-y-8">
          {pending.length > 0 && (
            <Section title={`Pending (${pending.length})`}>
              {pending.map((adj) => (
                <AdjustmentCard
                  key={adj.id}
                  adjustment={adj}
                  onAccept={() => updateAdjustmentStatus(adj.id, 'accepted')}
                  onDismiss={() => updateAdjustmentStatus(adj.id, 'dismissed')}
                  onApply={() => updateAdjustmentStatus(adj.id, 'applied')}
                  showActions
                />
              ))}
            </Section>
          )}

          {accepted.length > 0 && (
            <Section title={`Accepted (${accepted.length})`}>
              {accepted.map((adj) => (
                <AdjustmentCard
                  key={adj.id}
                  adjustment={adj}
                  onApply={() => updateAdjustmentStatus(adj.id, 'applied')}
                  showApply
                />
              ))}
            </Section>
          )}

          {applied.length > 0 && (
            <Section title={`Applied (${applied.length})`}>
              {applied.map((adj) => (
                <AdjustmentCard key={adj.id} adjustment={adj} />
              ))}
            </Section>
          )}

          {dismissed.length > 0 && (
            <Section title={`Dismissed (${dismissed.length})`}>
              {dismissed.map((adj) => (
                <AdjustmentCard key={adj.id} adjustment={adj} />
              ))}
            </Section>
          )}
        </div>
      )}
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="text-sm font-medium text-zinc-400 mb-3">{title}</h3>
      <div className="space-y-3">{children}</div>
    </div>
  );
}

function AdjustmentCard({
  adjustment,
  onAccept,
  onDismiss,
  onApply,
  showActions = false,
  showApply = false,
}: {
  adjustment: {
    id: string;
    job_type: string;
    trade_type: string | null;
    adjustment_type: string;
    suggested_multiplier: number | null;
    suggested_flat_amount: number | null;
    based_on_jobs: number;
    avg_variance_pct: number | null;
    status: string;
    applied_at: string | null;
    created_at: string;
  };
  onAccept?: () => void;
  onDismiss?: () => void;
  onApply?: () => void;
  showActions?: boolean;
  showApply?: boolean;
}) {
  const statusColors: Record<string, string> = {
    pending: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
    accepted: 'bg-blue-500/15 text-blue-400 border-blue-500/30',
    applied: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
    dismissed: 'bg-zinc-700/50 text-zinc-500 border-zinc-600/30',
  };

  const typeLabels: Record<string, string> = {
    labor_hours_multiplier: 'Labor Hours Multiplier',
    material_cost_multiplier: 'Material Cost Multiplier',
    total_cost_multiplier: 'Total Cost Multiplier',
    flat_add_labor: 'Flat Labor Add',
    flat_add_material: 'Flat Material Add',
    drive_time_add: 'Drive Time Add',
  };

  const description = (() => {
    if (adjustment.suggested_multiplier && ['labor_hours_multiplier', 'material_cost_multiplier', 'total_cost_multiplier'].includes(adjustment.adjustment_type)) {
      const pct = ((adjustment.suggested_multiplier - 1) * 100).toFixed(0);
      return `${Number(pct) >= 0 ? '+' : ''}${pct}% ${(typeLabels[adjustment.adjustment_type] || adjustment.adjustment_type).toLowerCase()}`;
    }
    if (adjustment.suggested_flat_amount) {
      return `+$${adjustment.suggested_flat_amount.toFixed(2)} ${(typeLabels[adjustment.adjustment_type] || adjustment.adjustment_type).toLowerCase()}`;
    }
    return typeLabels[adjustment.adjustment_type] || adjustment.adjustment_type;
  })();

  return (
    <div
      className={`rounded-xl p-5 border ${statusColors[adjustment.status] || 'border-zinc-700/50 bg-zinc-800/50'}`}
      style={{ backgroundColor: 'rgb(24 24 27 / 0.5)' }}
    >
      <div className="flex items-start justify-between mb-3">
        <div>
          <p className="text-sm font-semibold text-zinc-200 uppercase tracking-wide">
            {adjustment.job_type.replace(/_/g, ' ')}
          </p>
          {adjustment.trade_type && (
            <p className="text-xs text-zinc-500 mt-0.5">{adjustment.trade_type}</p>
          )}
        </div>
        <span
          className={`text-xs px-2 py-0.5 rounded-full border ${
            statusColors[adjustment.status] || ''
          }`}
        >
          {adjustment.status.charAt(0).toUpperCase() + adjustment.status.slice(1)}
        </span>
      </div>

      <p className="text-base font-medium text-white mb-2">{description}</p>

      <div className="flex items-center gap-4 text-xs text-zinc-500 mb-4">
        <span>Based on {adjustment.based_on_jobs} jobs</span>
        {adjustment.avg_variance_pct != null && (
          <span>Avg variance: {adjustment.avg_variance_pct.toFixed(1)}%</span>
        )}
        <span>
          {new Date(adjustment.created_at).toLocaleDateString()}
        </span>
      </div>

      {(showActions || showApply) && (
        <div className="flex items-center gap-2">
          {showActions && onAccept && (
            <button
              onClick={onAccept}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-500/10 border border-emerald-500/30 rounded-lg text-sm text-emerald-400 hover:bg-emerald-500/20 transition-colors"
            >
              <Check className="h-3.5 w-3.5" /> Accept
            </button>
          )}
          {showActions && onDismiss && (
            <button
              onClick={onDismiss}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-700/30 border border-zinc-600/30 rounded-lg text-sm text-zinc-400 hover:bg-zinc-700/50 transition-colors"
            >
              <X className="h-3.5 w-3.5" /> Dismiss
            </button>
          )}
          {(showApply || showActions) && onApply && (
            <button
              onClick={onApply}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-500/10 border border-blue-500/30 rounded-lg text-sm text-blue-400 hover:bg-blue-500/20 transition-colors"
            >
              <PlayCircle className="h-3.5 w-3.5" /> Apply to Future Estimates
            </button>
          )}
        </div>
      )}

      {adjustment.applied_at && (
        <p className="text-xs text-zinc-600 mt-2">
          Applied on {new Date(adjustment.applied_at).toLocaleDateString()}
        </p>
      )}
    </div>
  );
}
