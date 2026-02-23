'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Plus,
  HardHat,
  Wrench,
  Package,
  BarChart3,
  AlertTriangle,
  User,
} from 'lucide-react';
import { useScheduleResources, useResourceLeveling } from '@/lib/hooks/use-schedule-resources';
import { useScheduleProject } from '@/lib/hooks/use-schedule';
import { getSupabase } from '@/lib/supabase';
import type { ScheduleResource, ResourceType } from '@/lib/types/scheduling';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

const RESOURCE_TYPE_CONFIG: Record<ResourceType, { label: string; icon: typeof HardHat; color: string; bg: string }> = {
  labor: { label: 'Labor', icon: HardHat, color: 'text-accent', bg: 'bg-accent/10' },
  equipment: { label: 'Equipment', icon: Wrench, color: 'text-warning', bg: 'bg-warning/10' },
  material: { label: 'Material', icon: Package, color: 'text-info', bg: 'bg-info/10' },
};

export default function ResourcesPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;

  const { project } = useScheduleProject(projectId);
  const { resources, loading, createResource, deleteResource } = useScheduleResources();
  const { loading: leveling, result: levelResult, levelResources } = useResourceLeveling(projectId);

  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [showAdd, setShowAdd] = useState(false);
  const [newName, setNewName] = useState('');
  const [newType, setNewType] = useState<ResourceType>('labor');
  const [creating, setCreating] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<string>('');
  const [teamMembers, setTeamMembers] = useState<{ id: string; full_name: string; role: string }[]>([]);

  useEffect(() => {
    const fetchTeam = async () => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('users')
          .select('id, full_name, role')
          .order('full_name');
        if (data) setTeamMembers(data as { id: string; full_name: string; role: string }[]);
      } catch { /* ignore */ }
    };
    fetchTeam();
  }, []);

  const filtered = typeFilter === 'all'
    ? resources
    : resources.filter(r => r.resource_type === typeFilter);

  const handleCreate = async () => {
    if (!newName.trim() || creating) return;
    setCreating(true);
    try {
      await createResource({
        name: newName.trim(),
        resource_type: newType,
        ...(selectedUserId ? { user_id: selectedUserId } : {}),
      });
      setShowAdd(false);
      setNewName('');
      setSelectedUserId('');
    } catch {
      // Error in hook
    } finally {
      setCreating(false);
    }
  };

  const handleLevel = async () => {
    await levelResources({ respect_critical_path: true, leveling_order: 'float' });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin w-8 h-8 border-2 border-accent border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={() => router.push(`/dashboard/scheduling/${projectId}`)} className="p-1.5 hover:bg-surface-alt rounded-md">
            <ArrowLeft className="w-4 h-4 text-secondary" />
          </button>
          <div>
            <h1 className="text-xl font-semibold text-primary">{t('schedulingResources.title')}</h1>
            <p className="text-sm text-secondary">{project?.name || 'Schedule'}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleLevel}
            disabled={leveling}
            className="flex items-center gap-2 px-4 py-2 border border-main rounded-lg text-sm font-medium text-primary hover:bg-surface-alt disabled:opacity-50"
          >
            <BarChart3 className="w-4 h-4" />
            {leveling ? 'Leveling...' : 'Auto Level'}
          </button>
          <button
            onClick={() => setShowAdd(true)}
            className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium"
          >
            <Plus className="w-4 h-4" />
            Add Resource
          </button>
        </div>
      </div>

      {/* Leveling result */}
      {levelResult && levelResult.leveling && (
        <div className={`p-4 rounded-xl border ${levelResult.leveling.remaining > 0 ? 'bg-warning/5 border-warning/20' : 'bg-success/5 border-success/20'}`}>
          <div className="flex items-center gap-2 mb-2">
            {levelResult.leveling.remaining > 0 ? (
              <AlertTriangle className="w-4 h-4 text-warning" />
            ) : (
              <BarChart3 className="w-4 h-4 text-success" />
            )}
            <span className="text-sm font-medium text-primary">
              {levelResult.leveling.remaining > 0 ? 'Partial leveling' : 'Leveling complete'}
            </span>
          </div>
          <p className="text-xs text-secondary">
            {levelResult.leveling.delays.length} tasks delayed, {levelResult.leveling.resolved} conflicts resolved in {levelResult.leveling.iterations} iterations.
            {levelResult.leveling.remaining > 0 && ` ${levelResult.leveling.remaining} conflicts remaining.`}
          </p>
          {levelResult.leveling.warnings.length > 0 && (
            <ul className="mt-2 space-y-1">
              {levelResult.leveling.warnings.map((w, i) => (
                <li key={i} className="text-xs text-warning">{w}</li>
              ))}
            </ul>
          )}
        </div>
      )}

      {/* Over-allocation count */}
      {levelResult && levelResult.over_allocation_count > 0 && (
        <div className="flex items-center gap-2 p-3 bg-error/5 border border-error/20 rounded-lg">
          <AlertTriangle className="w-4 h-4 text-error" />
          <span className="text-sm text-error font-medium">{levelResult.over_allocation_count} over-allocation{levelResult.over_allocation_count !== 1 ? 's' : ''} detected</span>
        </div>
      )}

      {/* Type filter */}
      <div className="flex gap-1 bg-surface border border-main rounded-lg p-1 w-fit">
        {['all', 'labor', 'equipment', 'material'].map((t) => (
          <button
            key={t}
            onClick={() => setTypeFilter(t)}
            className={`px-3 py-1.5 text-xs font-medium rounded-md transition-colors ${
              typeFilter === t ? 'bg-accent text-on-accent' : 'text-secondary hover:text-primary'
            }`}
          >
            {t === 'all' ? 'All' : t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {/* Resource list */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="w-16 h-16 rounded-full bg-surface-alt flex items-center justify-center mb-4">
            <HardHat className="w-8 h-8 text-secondary" />
          </div>
          <h3 className="text-lg font-semibold text-primary mb-1">{t('schedulingResources.noResources')}</h3>
          <p className="text-sm text-secondary mb-4">Add labor, equipment, or materials</p>
          <button onClick={() => setShowAdd(true)} className="flex items-center gap-2 px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium">
            <Plus className="w-4 h-4" /> Add Resource
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((resource) => {
            const config = RESOURCE_TYPE_CONFIG[resource.resource_type];
            const Icon = config.icon;

            return (
              <div key={resource.id} className="bg-surface border border-main rounded-xl p-5 hover:border-accent/30 transition-colors">
                <div className="flex items-start gap-3">
                  <div className={`p-2.5 rounded-lg ${config.bg}`}>
                    <Icon className={`w-5 h-5 ${config.color}`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-sm font-semibold text-primary truncate">{resource.name}</h3>
                    <div className="flex items-center gap-2 mt-1">
                      <span className={`text-xs px-2 py-0.5 rounded ${config.bg} ${config.color}`}>{config.label}</span>
                      {resource.trade && <span className="text-xs text-tertiary">{resource.trade}</span>}
                    </div>
                    <div className="flex items-center gap-3 mt-2 text-xs text-tertiary">
                      <span>Max: {resource.max_units}x</span>
                      <span>{formatCurrency(resource.cost_per_hour)}/hr</span>
                      {resource.overtime_rate_multiplier > 1 && (
                        <span>OT: {resource.overtime_rate_multiplier}x</span>
                      )}
                    </div>
                  </div>
                  {resource.color && (
                    <div className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: resource.color }} />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add resource modal */}
      {showAdd && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowAdd(false)}>
          <div className="bg-surface border border-main rounded-xl p-6 w-full max-w-md" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-lg font-semibold text-primary mb-4">{t('schedulingResources.addResource')}</h2>
            <input
              type="text"
              placeholder="Resource name"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              autoFocus
              className="w-full px-4 py-2.5 bg-base border border-main rounded-lg text-sm text-primary placeholder:text-quaternary focus:outline-none focus:border-accent mb-3"
            />
            <div className="flex gap-2 mb-3">
              {(['labor', 'equipment', 'material'] as ResourceType[]).map((t) => {
                const config = RESOURCE_TYPE_CONFIG[t];
                return (
                  <button
                    key={t}
                    onClick={() => { setNewType(t); if (t !== 'labor') setSelectedUserId(''); }}
                    className={`flex-1 py-2 rounded-lg text-xs font-medium transition-colors ${
                      newType === t ? 'bg-accent text-on-accent' : 'bg-surface-alt text-secondary hover:text-primary'
                    }`}
                  >
                    {config.label}
                  </button>
                );
              })}
            </div>
            {newType === 'labor' && teamMembers.length > 0 && (
              <div className="mb-3">
                <label className="text-xs text-secondary mb-1 block">{t('schedulingResources.linkTeamMember')}</label>
                <select
                  value={selectedUserId}
                  onChange={(e) => {
                    setSelectedUserId(e.target.value);
                    if (e.target.value) {
                      const member = teamMembers.find(m => m.id === e.target.value);
                      if (member && !newName) setNewName(member.full_name || '');
                    }
                  }}
                  className="w-full px-3 py-2 bg-base border border-main rounded-lg text-sm text-primary focus:outline-none focus:border-accent"
                >
                  <option value="">None (manual entry)</option>
                  {teamMembers.map((m) => (
                    <option key={m.id} value={m.id}>{m.full_name} ({m.role?.replace('_', ' ')})</option>
                  ))}
                </select>
              </div>
            )}
            <div className="flex justify-end gap-3">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 text-sm text-secondary">{t('common.cancel')}</button>
              <button onClick={handleCreate} disabled={!newName.trim() || creating} className="px-4 py-2 bg-accent text-on-accent rounded-lg text-sm font-medium disabled:opacity-50">
                {creating ? 'Adding...' : 'Add'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
