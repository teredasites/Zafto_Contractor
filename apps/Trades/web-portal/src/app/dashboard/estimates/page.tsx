'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  FileText, Search, Plus, DollarSign, ChevronRight, Calculator,
  Shield, Briefcase, Loader2, Upload,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import {
  useEstimates, fmtCurrency,
  type Estimate, type EstimateStatus, type EstimateType,
} from '@/lib/hooks/use-estimates';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale } from '@/lib/format-locale';

const STATUS_CONFIG: Record<EstimateStatus, { label: string; color: string }> = {
  draft: { label: 'Draft', color: 'bg-zinc-700/50 text-zinc-400' },
  sent: { label: 'Sent', color: 'bg-blue-500/10 text-blue-400' },
  approved: { label: 'Approved', color: 'bg-green-500/10 text-green-400' },
  declined: { label: 'Declined', color: 'bg-red-500/10 text-red-400' },
  revised: { label: 'Revised', color: 'bg-amber-500/10 text-amber-400' },
  completed: { label: 'Completed', color: 'bg-emerald-500/10 text-emerald-400' },
};

export default function EstimatesPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const { estimates, loading, createEstimate } = useEstimates();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<EstimateStatus | 'all'>('all');
  const [typeFilter, setTypeFilter] = useState<EstimateType | 'all'>('all');
  const [showCreate, setShowCreate] = useState(false);
  const [importing, setImporting] = useState(false);

  const handleImportEsx = async () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.esx,.zip,.xml';
    input.onchange = async () => {
      const file = input.files?.[0];
      if (!file) return;
      setImporting(true);
      try {
        const supabase = getSupabase();
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) return;
        const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
        const formData = new FormData();
        formData.append('esx_file', file);
        const res = await fetch(`${baseUrl}/functions/v1/import-esx`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${session.access_token}`,
            'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
          },
          body: formData,
        });
        const json = await res.json();
        if (json.success && json.estimate_id) {
          router.push(`/dashboard/estimates/${json.estimate_id}`);
        }
      } catch {
        // silent
      } finally {
        setImporting(false);
      }
    };
    input.click();
  };

  const filtered = useMemo(() => {
    return estimates.filter((e) => {
      if (statusFilter !== 'all' && e.status !== statusFilter) return false;
      if (typeFilter !== 'all' && e.estimateType !== typeFilter) return false;
      if (search) {
        const q = search.toLowerCase();
        return (
          e.estimateNumber.toLowerCase().includes(q) ||
          e.title.toLowerCase().includes(q) ||
          e.customerName.toLowerCase().includes(q) ||
          e.propertyAddress.toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [estimates, search, statusFilter, typeFilter]);

  const stats = useMemo(() => {
    const drafts = estimates.filter(e => e.status === 'draft').length;
    const sent = estimates.filter(e => e.status === 'sent').length;
    const approved = estimates.filter(e => e.status === 'approved').length;
    const approvedTotal = estimates
      .filter(e => e.status === 'approved')
      .reduce((sum, e) => sum + e.grandTotal, 0);
    return { drafts, sent, approved, approvedTotal };
  }, [estimates]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-zinc-100">{t('estimates.title')}</h1>
          <p className="text-sm text-zinc-400 mt-1">{t('estimates.manageDesc')}</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleImportEsx}
            disabled={importing}
            className="flex items-center gap-1.5 px-4 py-2 text-sm text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800 transition-colors disabled:opacity-50"
          >
            {importing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
            {importing ? t('estimates.importing') : t('estimates.importEsx')}
          </button>
          <button
            onClick={() => setShowCreate(true)}
            className="flex items-center gap-1.5 px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-500 transition-colors"
          >
            <Plus className="w-4 h-4" />
            {t('estimates.new')}
          </button>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Drafts', value: String(stats.drafts), icon: FileText, color: 'text-zinc-400' },
          { label: 'Sent', value: String(stats.sent), icon: DollarSign, color: 'text-blue-400' },
          { label: 'Approved', value: String(stats.approved), icon: Calculator, color: 'text-green-400' },
          { label: 'Approved Value', value: fmtCurrency(stats.approvedTotal), icon: DollarSign, color: 'text-emerald-400' },
        ].map((stat) => (
          <div key={stat.label} className="bg-zinc-800/40 border border-zinc-700/30 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-1">
              <stat.icon className={cn('w-4 h-4', stat.color)} />
              <span className="text-xs text-zinc-500">{stat.label}</span>
            </div>
            <p className="text-lg font-semibold text-zinc-100">{stat.value}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-500" />
          <input
            type="text"
            placeholder={t('estimates.searchEstimates')}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500 focus:outline-none focus:ring-1 focus:ring-blue-500/50"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as EstimateStatus | 'all')}
          className="px-3 py-2 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-sm text-zinc-200"
        >
          <option value="all">{t('common.allStatus')}</option>
          {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
            <option key={key} value={key}>{cfg.label}</option>
          ))}
        </select>
        <div className="flex items-center border border-zinc-700/50 rounded-lg overflow-hidden">
          {(['all', 'regular', 'insurance'] as const).map((type) => (
            <button
              key={type}
              onClick={() => setTypeFilter(type)}
              className={cn(
                'px-3 py-2 text-xs transition-colors',
                typeFilter === type
                  ? 'bg-blue-500/10 text-blue-400'
                  : 'text-zinc-400 hover:text-zinc-200 bg-zinc-800/50'
              )}
            >
              {type === 'all' ? 'All' : type === 'regular' ? 'Regular' : 'Insurance'}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      {loading ? (
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-20 bg-zinc-800/50 rounded-lg animate-pulse" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center py-16 text-zinc-500">
          <Calculator className="w-12 h-12 mx-auto mb-3 opacity-50" />
          <p className="text-lg font-medium">{t('estimates.noEstimates')}</p>
          <p className="text-sm mt-1">{t('estimates.noEstimatesDesc')}</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((est) => (
            <EstimateRow
              key={est.id}
              estimate={est}
              onClick={() => router.push(`/dashboard/estimates/${est.id}`)}
            />
          ))}
        </div>
      )}

      {/* Create Modal */}
      {showCreate && (
        <CreateEstimateModal
          onClose={() => setShowCreate(false)}
          onCreate={createEstimate}
          onCreated={(id) => router.push(`/dashboard/estimates/${id}`)}
        />
      )}
    </div>
  );
}

// ── Estimate Row ──

function EstimateRow({ estimate, onClick }: { estimate: Estimate; onClick: () => void }) {
  const statusCfg = STATUS_CONFIG[estimate.status];
  return (
    <button
      onClick={onClick}
      className="w-full flex items-center gap-4 p-4 bg-zinc-800/40 border border-zinc-700/30 rounded-lg hover:bg-zinc-800/60 transition-colors text-left"
    >
      <div className="w-10 h-10 rounded-lg bg-blue-500/10 flex items-center justify-center flex-shrink-0">
        {estimate.estimateType === 'insurance' ? (
          <Shield className="w-5 h-5 text-blue-400" />
        ) : (
          <FileText className="w-5 h-5 text-blue-400" />
        )}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-zinc-100 truncate">
            {estimate.estimateNumber}
          </span>
          <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', statusCfg.color)}>
            {statusCfg.label}
          </span>
          {estimate.estimateType === 'insurance' && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-purple-500/10 text-purple-400">
              Insurance
            </span>
          )}
        </div>
        <p className="text-xs text-zinc-400 mt-0.5 truncate">
          {estimate.title || 'Untitled'} &middot; {estimate.customerName || 'No customer'}
        </p>
      </div>
      <div className="text-right flex-shrink-0">
        <div className="flex items-center gap-1 text-sm font-medium text-zinc-200">
          <DollarSign className="w-3.5 h-3.5" />
          {fmtCurrency(estimate.grandTotal)}
        </div>
        <p className="text-xs text-zinc-500 mt-0.5">
          {formatDateLocale(estimate.createdAt)}
        </p>
      </div>
      <ChevronRight className="w-4 h-4 text-zinc-600 flex-shrink-0" />
    </button>
  );
}

// ── Create Estimate Modal ──

function CreateEstimateModal({
  onClose,
  onCreate,
  onCreated,
}: {
  onClose: () => void;
  onCreate: (data: { title: string; estimateType: EstimateType; customerName?: string; propertyAddress?: string }) => Promise<string | null>;
  onCreated: (id: string) => void;
}) {
  const { t } = useTranslation();
  const [title, setTitle] = useState('');
  const [estimateType, setEstimateType] = useState<EstimateType>('regular');
  const [customerName, setCustomerName] = useState('');
  const [propertyAddress, setPropertyAddress] = useState('');
  const [creating, setCreating] = useState(false);

  const handleCreate = async () => {
    if (!title.trim()) return;
    setCreating(true);
    const id = await onCreate({
      title: title.trim(),
      estimateType,
      customerName: customerName.trim() || undefined,
      propertyAddress: propertyAddress.trim() || undefined,
    });
    if (id) onCreated(id);
    setCreating(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-6 w-[480px]">
        <h3 className="text-lg font-medium text-zinc-100 mb-4">{t('estimates.new')}</h3>

        {/* Type selector */}
        <div className="flex items-center gap-2 mb-4">
          {(['regular', 'insurance'] as const).map((type) => (
            <button
              key={type}
              onClick={() => setEstimateType(type)}
              className={cn(
                'flex-1 flex items-center justify-center gap-2 px-4 py-3 rounded-lg border transition-colors',
                estimateType === type
                  ? 'bg-blue-500/10 border-blue-500/30 text-blue-400'
                  : 'bg-zinc-800/50 border-zinc-700/50 text-zinc-400 hover:text-zinc-200'
              )}
            >
              {type === 'regular' ? <Briefcase className="w-4 h-4" /> : <Shield className="w-4 h-4" />}
              <span className="text-sm font-medium capitalize">{type}</span>
            </button>
          ))}
        </div>

        <div className="space-y-3">
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Estimate title..."
            className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500"
            autoFocus
          />
          <input
            type="text"
            value={customerName}
            onChange={(e) => setCustomerName(e.target.value)}
            placeholder="Customer name..."
            className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500"
          />
          <input
            type="text"
            value={propertyAddress}
            onChange={(e) => setPropertyAddress(e.target.value)}
            placeholder="Property address..."
            className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500"
          />
        </div>

        <div className="flex justify-end gap-2 mt-6">
          <button onClick={onClose} className="px-4 py-2 text-sm text-zinc-400 hover:text-zinc-200">
            Cancel
          </button>
          <button
            onClick={handleCreate}
            disabled={!title.trim() || creating}
            className="flex items-center gap-1.5 px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-500 disabled:opacity-50"
          >
            {creating && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
            {creating ? 'Creating...' : 'Create Estimate'}
          </button>
        </div>
      </div>
    </div>
  );
}
