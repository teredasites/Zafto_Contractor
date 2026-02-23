'use client';

import { useState } from 'react';
import {
  ClipboardCheck,
  Shield,
  CheckCircle,
  XCircle,
  AlertTriangle,
  FileCheck,
  ChevronDown,
  ChevronRight,
  Plus,
  Settings,
  User,
  Briefcase,
  PenTool,
  Clock,
  LayoutList,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn, formatDate } from '@/lib/utils';
import { useInspectionEngine } from '@/lib/hooks/use-inspection-engine';
import type { InspectionResult, InspectionTemplate } from '@/lib/hooks/use-inspection-engine';
import { useTranslation } from '@/lib/translations';

type TabKey = 'all' | 'in_progress' | 'completed' | 'failed';

const statusConfig: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  in_progress: { label: 'In Progress', variant: 'warning' },
  completed: { label: 'Completed', variant: 'success' },
  signed: { label: 'Signed', variant: 'info' },
};

const resultConfig: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  pass: { label: 'Pass', variant: 'success' },
  fail: { label: 'Fail', variant: 'error' },
  conditional: { label: 'Conditional', variant: 'warning' },
};

function getScoreColor(passed: number, total: number): string {
  if (total === 0) return 'text-muted';
  const pct = (passed / total) * 100;
  if (pct >= 80) return 'text-emerald-500';
  if (pct >= 50) return 'text-amber-500';
  return 'text-red-500';
}

export default function InspectionEnginePage() {
  const { t } = useTranslation();
  const { results, templates, inProgress, completed, failed, loading, error, refetch } = useInspectionEngine();
  const [search, setSearch] = useState('');
  const [activeTab, setActiveTab] = useState<TabKey>('all');
  const [templatesExpanded, setTemplatesExpanded] = useState(false);
  const [expandedTemplateId, setExpandedTemplateId] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div>
          <div className="skeleton h-7 w-56 mb-2" />
          <div className="skeleton h-4 w-72" />
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" />
              <div className="skeleton h-7 w-10" />
            </div>
          ))}
        </div>
        <div className="bg-surface border border-main rounded-xl divide-y divide-main">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="px-6 py-4 flex items-center gap-4">
              <div className="flex-1">
                <div className="skeleton h-4 w-40 mb-2" />
                <div className="skeleton h-3 w-32" />
              </div>
              <div className="skeleton h-5 w-16 rounded-full" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-8 animate-fade-in">
        <CommandPalette />
        <Card>
          <CardContent className="p-12 text-center">
            <XCircle size={48} className="mx-auto text-red-500 mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">Error loading inspections</h3>
            <p className="text-muted mb-4">{error}</p>
            <Button onClick={refetch}>{t('common.retry')}</Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const tabs: { key: TabKey; label: string; count: number }[] = [
    { key: 'all', label: 'All', count: results.length },
    { key: 'in_progress', label: 'In Progress', count: inProgress.length },
    { key: 'completed', label: 'Completed', count: completed.length },
    { key: 'failed', label: 'Failed', count: failed.length },
  ];

  const getFilteredResults = (): InspectionResult[] => {
    let filtered: InspectionResult[];
    switch (activeTab) {
      case 'in_progress':
        filtered = inProgress;
        break;
      case 'completed':
        filtered = completed;
        break;
      case 'failed':
        filtered = failed;
        break;
      default:
        filtered = results;
    }

    if (search) {
      const q = search.toLowerCase();
      filtered = filtered.filter(
        (r) =>
          r.title.toLowerCase().includes(q) ||
          r.inspectorName.toLowerCase().includes(q) ||
          (r.jobTitle && r.jobTitle.toLowerCase().includes(q))
      );
    }

    return filtered;
  };

  const filteredResults = getFilteredResults();

  // Group template items by section
  const getGroupedItems = (template: InspectionTemplate) => {
    const groups: Record<string, Array<{ title: string; description?: string; requiresPhotoOnFail?: boolean }>> = {};
    for (const item of template.items) {
      const section = item.section || 'General';
      if (!groups[section]) groups[section] = [];
      groups[section].push({ title: item.title, description: item.description, requiresPhotoOnFail: item.requiresPhotoOnFail });
    }
    return groups;
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('inspections.title')}</h1>
          <p className="text-muted mt-1">Template-based inspections with pass/fail/conditional items</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary">
            <Settings size={16} />
            Manage Templates
          </Button>
          <Button>
            <Plus size={16} />
            New Inspection
          </Button>
        </div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <ClipboardCheck size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{results.length}</p>
                <p className="text-sm text-muted">{t('common.totalInspections')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Clock size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{inProgress.length}</p>
                <p className="text-sm text-muted">{t('common.inProgress')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{completed.length}</p>
                <p className="text-sm text-muted">{t('common.completed')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <XCircle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{failed.length}</p>
                <p className="text-sm text-muted">{t('common.failed')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs + Search */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div className="flex items-center gap-1 bg-secondary rounded-lg p-1">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={cn(
                'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
                activeTab === tab.key
                  ? 'bg-surface text-main shadow-sm'
                  : 'text-muted hover:text-main'
              )}
            >
              {tab.label}
              <span className={cn(
                'ml-1.5 text-xs',
                activeTab === tab.key ? 'text-main' : 'text-muted'
              )}>
                {tab.count}
              </span>
            </button>
          ))}
        </div>
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search inspections..."
          className="sm:w-80"
        />
      </div>

      {/* Results Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.title')}</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.job')}</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">Inspector</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.status')}</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.score')}</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.result')}</th>
                <th className="text-left px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.date')}</th>
                <th className="text-center px-6 py-3 text-xs font-medium text-muted uppercase tracking-wider">{t('common.signed')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-main">
              {filteredResults.map((result) => {
                const sConfig = statusConfig[result.status] || { label: result.status, variant: 'default' as const };
                const rConfig = result.overallResult ? resultConfig[result.overallResult] || { label: result.overallResult, variant: 'default' as const } : null;
                const scoreColor = getScoreColor(result.passedItems, result.totalItems);

                return (
                  <tr key={result.id} className="hover:bg-surface-hover transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <FileCheck size={16} className="text-muted flex-shrink-0" />
                        <span className="font-medium text-main text-sm">{result.title}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-muted flex items-center gap-1.5">
                        <Briefcase size={14} className="flex-shrink-0" />
                        {result.jobTitle || 'No job'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-muted flex items-center gap-1.5">
                        <User size={14} className="flex-shrink-0" />
                        {result.inspectorName}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={sConfig.variant} dot>{sConfig.label}</Badge>
                    </td>
                    <td className="px-6 py-4">
                      <span className={cn('text-sm font-medium', scoreColor)}>
                        {result.passedItems}/{result.totalItems}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {rConfig ? (
                        <Badge variant={rConfig.variant}>{rConfig.label}</Badge>
                      ) : (
                        <span className="text-xs text-muted">--</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm text-muted">{formatDate(result.createdAt)}</span>
                    </td>
                    <td className="px-6 py-4 text-center">
                      {result.signaturePath ? (
                        <PenTool size={16} className="text-emerald-500 mx-auto" />
                      ) : (
                        <span className="text-xs text-muted">--</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          {filteredResults.length === 0 && (
            <div className="px-6 py-12 text-center">
              <ClipboardCheck size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">{t('common.noInspectionsFound')}</h3>
              <p className="text-muted mb-4">
                {search
                  ? 'No inspections match your search. Try adjusting your filters.'
                  : 'Start a new template-based inspection to track pass/fail results.'}
              </p>
              {!search && (
                <Button>
                  <Plus size={16} />
                  New Inspection
                </Button>
              )}
            </div>
          )}
        </div>
      </Card>

      {/* Templates Section (Collapsible) */}
      <Card>
        <CardHeader
          onClick={() => setTemplatesExpanded(!templatesExpanded)}
          className="flex flex-row items-center justify-between cursor-pointer select-none"
        >
          <div className="flex items-center gap-2">
            <LayoutList size={18} className="text-muted" />
            <CardTitle>Inspection Templates</CardTitle>
            <span className="text-xs text-muted ml-1">({templates.length})</span>
          </div>
          {templatesExpanded ? (
            <ChevronDown size={18} className="text-muted" />
          ) : (
            <ChevronRight size={18} className="text-muted" />
          )}
        </CardHeader>

        {templatesExpanded && (
          <CardContent className="p-0">
            <div className="divide-y divide-main">
              {templates.length === 0 && (
                <div className="px-6 py-8 text-center">
                  <Shield size={36} className="mx-auto text-muted mb-3" />
                  <p className="text-sm text-muted">No active templates found.</p>
                </div>
              )}

              {templates.map((template) => {
                const isExpanded = expandedTemplateId === template.id;
                const grouped = isExpanded ? getGroupedItems(template) : {};

                return (
                  <div key={template.id}>
                    <div
                      className="px-6 py-4 flex items-center justify-between hover:bg-surface-hover transition-colors cursor-pointer"
                      onClick={() => setExpandedTemplateId(isExpanded ? null : template.id)}
                    >
                      <div className="flex items-center gap-3 flex-1 min-w-0">
                        <Shield size={16} className="text-muted flex-shrink-0" />
                        <div className="min-w-0">
                          <p className="font-medium text-main text-sm">{template.name}</p>
                          {template.description && (
                            <p className="text-xs text-muted mt-0.5 truncate">{template.description}</p>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2 ml-4 flex-shrink-0">
                        {template.category && (
                          <Badge variant="secondary">{template.category}</Badge>
                        )}
                        {template.trade && (
                          <Badge variant="info">{template.trade}</Badge>
                        )}
                        <Badge variant="default">{template.items.length} items</Badge>
                        <Badge variant={template.isSystem ? 'purple' : 'success'}>
                          {template.isSystem ? 'System' : 'Custom'}
                        </Badge>
                        {isExpanded ? (
                          <ChevronDown size={16} className="text-muted" />
                        ) : (
                          <ChevronRight size={16} className="text-muted" />
                        )}
                      </div>
                    </div>

                    {isExpanded && (
                      <div className="px-6 pb-4 pl-12">
                        {Object.entries(grouped).map(([section, items]) => (
                          <div key={section} className="mb-3 last:mb-0">
                            <p className="text-xs font-medium text-muted uppercase tracking-wider mb-2">{section}</p>
                            <div className="space-y-1.5">
                              {items.map((item, idx) => (
                                <div key={idx} className="flex items-start gap-2 text-sm">
                                  <CheckCircle size={14} className="text-muted mt-0.5 flex-shrink-0" />
                                  <div>
                                    <span className="text-main">{item.title}</span>
                                    {item.description && (
                                      <span className="text-muted ml-1">- {item.description}</span>
                                    )}
                                    {item.requiresPhotoOnFail && (
                                      <Badge variant="warning" className="ml-2">Photo on fail</Badge>
                                    )}
                                  </div>
                                </div>
                              ))}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </CardContent>
        )}
      </Card>
    </div>
  );
}
