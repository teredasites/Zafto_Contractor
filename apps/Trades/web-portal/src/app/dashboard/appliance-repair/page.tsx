'use client';

import { useState } from 'react';
import { useTranslation } from '@/lib/translations';
import { useApplianceRepairLogs, APPLIANCE_TYPE_LABELS, REPAIR_VS_REPLACE_LABELS } from '@/lib/hooks/use-appliance-repair';
import { SearchInput } from '@/components/ui/input';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

const TYPE_COLORS: Record<string, string> = {
  refrigerator: 'bg-cyan-500/15 text-cyan-400', washer: 'bg-blue-500/15 text-blue-400',
  dryer: 'bg-orange-500/15 text-orange-400', dishwasher: 'bg-teal-500/15 text-teal-400',
  oven: 'bg-red-500/15 text-red-400', range: 'bg-red-500/15 text-red-400',
  microwave: 'bg-yellow-500/15 text-yellow-400',
};

export default function ApplianceRepairPage() {
  const { t, formatDate } = useTranslation();
  const { logs, loading } = useApplianceRepairLogs();
  const [search, setSearch] = useState('');

  const filtered = logs.filter((l) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      (l.brand ?? '').toLowerCase().includes(q) ||
      (l.appliance_type ?? '').toLowerCase().includes(q) ||
      (l.error_code ?? '').toLowerCase().includes(q) ||
      (l.diagnosis ?? '').toLowerCase().includes(q)
    );
  });

  const repairCount = logs.filter((l) => l.repair_vs_replace === 'repair').length;
  const replaceCount = logs.filter((l) => l.repair_vs_replace === 'replace' || l.repair_vs_replace === 'not_economical').length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">{t('applianceRepair.title')}</h1>
          <p className="text-sm text-muted mt-1">Service logs, error codes, repair vs replace analysis</p>
        </div>
        <div className="max-w-xs">
          <SearchInput placeholder="Search appliances..." value={search} onChange={(v) => setSearch(v)} />
        </div>
      </div>

      <div className="grid grid-cols-4 gap-4">
        <div className="bg-surface border border-main rounded-xl p-4">
          <p className="text-xs text-muted mb-1">{t('common.totalServices')}</p>
          <p className="text-2xl font-bold text-white">{logs.length}</p>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4">
          <p className="text-xs text-muted mb-1">{t('common.repaired')}</p>
          <p className="text-2xl font-bold text-green-400">{repairCount}</p>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4">
          <p className="text-xs text-muted mb-1">{t('common.replaced')}</p>
          <p className="text-2xl font-bold text-red-400">{replaceCount}</p>
        </div>
        <div className="bg-surface border border-main rounded-xl p-4">
          <p className="text-xs text-muted mb-1">{t('common.revenue')}</p>
          <p className="text-2xl font-bold text-purple-400">
            {formatCurrency(logs.reduce((s, l) => s + (l.total_cost ?? 0), 0))}
          </p>
        </div>
      </div>

      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="text-center py-12 text-muted"><p>{t('applianceRepair.noRecords')}</p></div>
        ) : (
          filtered.map((l) => (
            <div key={l.id} className="bg-surface border border-main rounded-xl p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded ${TYPE_COLORS[l.appliance_type] ?? 'bg-secondary text-main'}`}>
                    {APPLIANCE_TYPE_LABELS[l.appliance_type] ?? l.appliance_type}
                  </span>
                  {l.brand && <span className="text-xs text-muted">{l.brand}</span>}
                  {l.model_number && <span className="text-xs text-muted">#{l.model_number}</span>}
                </div>
                <span className="text-xs text-muted">{formatDate(l.created_at)}</span>
              </div>
              {l.error_code && (
                <div className="flex items-center gap-1 mb-1">
                  <span className="text-xs font-semibold px-1.5 py-0.5 rounded bg-red-500/15 text-red-400">
                    Error: {l.error_code}
                  </span>
                  {l.error_description && <span className="text-xs text-muted">{l.error_description}</span>}
                </div>
              )}
              {l.diagnosis && <p className="text-xs text-muted">{l.diagnosis}</p>}
              <div className="flex items-center gap-3 mt-2">
                {l.repair_vs_replace && (
                  <span className={`text-xs font-semibold px-2 py-0.5 rounded ${
                    l.repair_vs_replace === 'repair' ? 'bg-green-500/15 text-green-400' :
                    l.repair_vs_replace === 'replace' || l.repair_vs_replace === 'not_economical' ? 'bg-red-500/15 text-red-400' :
                    'bg-secondary text-main'
                  }`}>
                    {REPAIR_VS_REPLACE_LABELS[l.repair_vs_replace] ?? l.repair_vs_replace}
                  </span>
                )}
                {l.estimated_repair_cost && l.estimated_replace_cost && (
                  <span className="text-[10px] text-muted">
                    Repair ${l.estimated_repair_cost} vs Replace ${l.estimated_replace_cost}
                    ({Math.round((l.estimated_repair_cost / l.estimated_replace_cost) * 100)}%)
                  </span>
                )}
                {l.warranty_status && l.warranty_status !== 'unknown' && (
                  <span className={`text-[10px] px-1.5 py-0.5 rounded ${
                    l.warranty_status === 'in_warranty' || l.warranty_status === 'extended_warranty'
                      ? 'bg-green-500/15 text-green-400'
                      : 'bg-secondary text-muted'
                  }`}>
                    {l.warranty_status.replace('_', ' ')}
                  </span>
                )}
              </div>
              {l.total_cost && <p className="text-sm font-bold text-white mt-1">{formatCurrency(Number(l.total_cost))}</p>}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
