'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  MoreHorizontal,
  DollarSign,
  User,
  ArrowRight,
  Clock,
  CheckCircle,
  AlertCircle,
  Loader2,
  TrendingUp,
  Zap,
  Phone,
  Mail,
  MessageSquare,
  MapPin,
  Briefcase,
  XCircle,
  Target,
  BarChart3,
  Copy,
  Activity,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatRelativeTime, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';
import { useLeads } from '@/lib/hooks/use-leads';
import type { LeadData } from '@/lib/hooks/mappers';

type LeadStage = 'new' | 'contacted' | 'qualified' | 'proposal' | 'won' | 'lost';

const stageConfig: Record<LeadStage, { label: string; color: string; bgColor: string }> = {
  new: { label: 'New', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  contacted: { label: 'Contacted', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  qualified: { label: 'Qualified', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  proposal: { label: 'Proposal', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  won: { label: 'Won', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  lost: { label: 'Lost', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const sourceLabels: Record<string, string> = {
  website: 'Website',
  referral: 'Referral',
  google: 'Google',
  google_lsa: 'Google LSA',
  yelp: 'Yelp',
  facebook: 'Facebook',
  instagram: 'Instagram',
  nextdoor: 'Nextdoor',
  homeadvisor: 'HomeAdvisor',
  thumbtack: 'Thumbtack',
  angi: 'Angi',
  door_knock: 'Door Knock',
  storm_chase: 'Storm Chase',
  yard_sign: 'Yard Sign',
  phone_call: 'Phone Call',
  other: 'Other',
};

// Lead scoring — auto-score based on value, urgency, responsiveness, source quality
function computeLeadScore(lead: LeadData): number {
  let score = 0;

  // Value score (0-30 pts) — higher job value = higher score
  if (lead.value >= 50000) score += 30;
  else if (lead.value >= 20000) score += 25;
  else if (lead.value >= 10000) score += 20;
  else if (lead.value >= 5000) score += 15;
  else if (lead.value >= 1000) score += 10;
  else if (lead.value > 0) score += 5;

  // Source quality (0-20 pts) — referrals convert best
  const sourceScores: Record<string, number> = {
    referral: 20, google_lsa: 18, website: 15, google: 14,
    nextdoor: 12, yelp: 10, facebook: 8, instagram: 7,
    homeadvisor: 6, thumbtack: 6, angi: 6, door_knock: 5,
    storm_chase: 4, yard_sign: 3, other: 2,
  };
  score += sourceScores[lead.source] || 5;

  // Urgency (0-20 pts)
  const urgencyTag = lead.tags?.find(t => ['emergency', 'urgent', 'soon'].includes(t));
  if (urgencyTag === 'emergency') score += 20;
  else if (urgencyTag === 'urgent') score += 15;
  else if (urgencyTag === 'soon') score += 10;
  else score += 5;

  // Responsiveness (0-15 pts) — lead has email AND phone = more responsive
  if (lead.email && lead.phone) score += 15;
  else if (lead.email || lead.phone) score += 8;

  // Completeness (0-15 pts) — more info = more serious buyer
  if (lead.address) score += 5;
  if (lead.companyName) score += 3;
  if (lead.notes && lead.notes.length > 20) score += 4;
  if (lead.nextFollowUp) score += 3;

  return Math.min(100, score);
}

function getScoreLabel(score: number): { label: string; color: string } {
  if (score >= 80) return { label: 'Hot', color: 'text-red-600 bg-red-100 dark:bg-red-900/30 dark:text-red-400' };
  if (score >= 60) return { label: 'Warm', color: 'text-amber-600 bg-amber-100 dark:bg-amber-900/30 dark:text-amber-400' };
  if (score >= 40) return { label: 'Cool', color: 'text-blue-600 bg-blue-100 dark:bg-blue-900/30 dark:text-blue-400' };
  return { label: 'Cold', color: 'text-muted bg-secondary' };
}

export default function LeadsPage() {
  const router = useRouter();
  const { t } = useTranslation();
  const { leads, loading, error, createLead, updateLeadStage, convertLeadToJob, markLost, logActivity, deleteLead } = useLeads();
  const [search, setSearch] = useState('');
  const [sourceFilter, setSourceFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'pipeline' | 'list'>('pipeline');
  const [showNewLeadModal, setShowNewLeadModal] = useState(false);
  const [showLostModal, setShowLostModal] = useState<string | null>(null);
  const [showActivityModal, setShowActivityModal] = useState<string | null>(null);
  const [showCaptureForm, setShowCaptureForm] = useState(false);
  const [draggedLead, setDraggedLead] = useState<string | null>(null);
  const [converting, setConverting] = useState<string | null>(null);

  const filteredLeads = leads.filter((lead) => {
    const q = search.toLowerCase();
    const matchesSearch = !q ||
      lead.name.toLowerCase().includes(q) ||
      (lead.email || '').toLowerCase().includes(q) ||
      (lead.phone || '').replace(/\D/g, '').includes(q.replace(/\D/g, '')) ||
      (lead.companyName || '').toLowerCase().includes(q) ||
      (lead.address || '').toLowerCase().includes(q) ||
      (lead.city || '').toLowerCase().includes(q);
    const matchesSource = sourceFilter === 'all' || lead.source === sourceFilter;
    return matchesSearch && matchesSource;
  });

  const sourceOptions = [
    { value: 'all', label: 'All Sources' },
    { value: 'website', label: 'Website' },
    { value: 'referral', label: 'Referral' },
    { value: 'google', label: 'Google' },
    { value: 'yelp', label: 'Yelp' },
    { value: 'facebook', label: 'Facebook' },
    { value: 'instagram', label: 'Instagram' },
    { value: 'nextdoor', label: 'Nextdoor' },
    { value: 'homeadvisor', label: 'HomeAdvisor' },
    { value: 'other', label: 'Other' },
  ];

  // Response time tracking — average time from creation to first contact
  const avgResponseTime = useMemo(() => {
    const contactedLeads = leads.filter(l => l.lastContactedAt && l.createdAt);
    if (contactedLeads.length === 0) return null;
    const totalMs = contactedLeads.reduce((sum, l) => {
      return sum + (l.lastContactedAt!.getTime() - l.createdAt.getTime());
    }, 0);
    const avgMs = totalMs / contactedLeads.length;
    const avgHours = avgMs / (1000 * 60 * 60);
    return avgHours;
  }, [leads]);

  // Stale leads — no follow-up in 48+ hours
  const staleLeads = useMemo(() => {
    const now = new Date();
    const cutoff = new Date(now.getTime() - 48 * 60 * 60 * 1000);
    return leads.filter(l =>
      !['won', 'lost'].includes(l.stage) &&
      (!l.lastContactedAt || l.lastContactedAt < cutoff) &&
      (!l.nextFollowUp || new Date(l.nextFollowUp.getTime ? l.nextFollowUp.getTime() : 0) < now)
    );
  }, [leads]);

  // Conversion rate by source
  const conversionBySource = useMemo(() => {
    const sourceMap: Record<string, { total: number; won: number }> = {};
    leads.forEach(l => {
      if (!sourceMap[l.source]) sourceMap[l.source] = { total: 0, won: 0 };
      sourceMap[l.source].total++;
      if (l.stage === 'won') sourceMap[l.source].won++;
    });
    return sourceMap;
  }, [leads]);

  const activeStages: LeadStage[] = ['new', 'contacted', 'qualified', 'proposal'];

  const getStageLeads = (stage: LeadStage) => filteredLeads.filter((l) => l.stage === stage);

  const handleDragStart = (leadId: string) => {
    setDraggedLead(leadId);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = async (stage: LeadStage) => {
    if (!draggedLead) return;
    if (stage === 'lost') {
      setShowLostModal(draggedLead);
      setDraggedLead(null);
      return;
    }
    try {
      await updateLeadStage(draggedLead, stage);
    } catch {
      // Real-time subscription will refetch
    }
    setDraggedLead(null);
  };

  const handleConvertToJob = async (leadId: string) => {
    setConverting(leadId);
    try {
      const { jobId } = await convertLeadToJob(leadId);
      router.push(`/dashboard/jobs/${jobId}`);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to convert');
    } finally {
      setConverting(null);
    }
  };

  // Stats
  const totalValue = filteredLeads.filter((l) => !['won', 'lost'].includes(l.stage)).reduce((sum, l) => sum + l.value, 0);
  const newCount = getStageLeads('new').length;
  const qualifiedCount = getStageLeads('qualified').length + getStageLeads('proposal').length;
  const wonValue = filteredLeads.filter((l) => l.stage === 'won').reduce((sum, l) => sum + l.value, 0);

  if (loading && leads.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Follow-up Alert */}
      {staleLeads.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3 flex items-center gap-3">
          <AlertCircle size={18} className="text-amber-600 dark:text-amber-400 flex-shrink-0" />
          <div className="flex-1">
            <p className="text-sm font-medium text-amber-800 dark:text-amber-300">
              You have {staleLeads.length} lead{staleLeads.length !== 1 ? 's' : ''} with no follow-up in 48+ hours
            </p>
            <p className="text-xs text-amber-600 dark:text-amber-500 mt-0.5">
              Fast response wins 50% more jobs. Industry benchmark: 5 minutes.
            </p>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('leads.title')}</h1>
          <p className="text-muted mt-1">{t('leads.trackAndManageYourSalesOpportunities')}</p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="secondary" onClick={() => setShowCaptureForm(true)}>
            <Copy size={16} />
            Capture Form
          </Button>
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setViewMode('pipeline')}
              className={cn(
                'px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'pipeline' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              Pipeline
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
                viewMode === 'list' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              List
            </button>
          </div>
          <Button onClick={() => setShowNewLeadModal(true)}>
            <Plus size={16} />
            Add Lead
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <User size={18} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">{newCount}</p>
                <p className="text-xs text-muted">{t('common.newLeads')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Target size={18} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">{qualifiedCount}</p>
                <p className="text-xs text-muted">Qualified</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <DollarSign size={18} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">{formatCurrency(totalValue)}</p>
                <p className="text-xs text-muted">Pipeline</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={18} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">{formatCurrency(wonValue)}</p>
                <p className="text-xs text-muted">Won</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Zap size={18} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">
                  {avgResponseTime !== null
                    ? avgResponseTime < 1 ? `${Math.round(avgResponseTime * 60)}m` : `${avgResponseTime.toFixed(1)}h`
                    : '-'}
                </p>
                <p className="text-xs text-muted">Avg Response</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-rose-100 dark:bg-rose-900/30 rounded-lg">
                <TrendingUp size={18} className="text-rose-600 dark:text-rose-400" />
              </div>
              <div>
                <p className="text-xl font-semibold text-main">
                  {leads.length > 0
                    ? `${Math.round((leads.filter(l => l.stage === 'won').length / leads.length) * 100)}%`
                    : '-'}
                </p>
                <p className="text-xs text-muted">Win Rate</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Conversion by Source */}
      {Object.keys(conversionBySource).length > 0 && (
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2 mb-3">
              <BarChart3 size={16} className="text-muted" />
              <h3 className="text-sm font-medium text-main">Conversion by Source</h3>
            </div>
            <div className="flex flex-wrap gap-3">
              {Object.entries(conversionBySource)
                .sort((a, b) => b[1].total - a[1].total)
                .map(([src, data]) => {
                  const rate = data.total > 0 ? Math.round((data.won / data.total) * 100) : 0;
                  return (
                    <div key={src} className="flex items-center gap-2 px-3 py-1.5 bg-secondary rounded-lg">
                      <span className="text-xs font-medium text-main">{sourceLabels[src] || src}</span>
                      <span className="text-xs text-muted">{data.total} leads</span>
                      <span className={cn(
                        'text-xs font-semibold',
                        rate >= 50 ? 'text-emerald-600' : rate >= 25 ? 'text-amber-600' : 'text-muted'
                      )}>
                        {rate}% won
                      </span>
                    </div>
                  );
                })}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('leadsPage.searchLeads')}
          className="sm:w-80"
        />
        <Select
          options={sourceOptions}
          value={sourceFilter}
          onChange={(e) => setSourceFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {viewMode === 'pipeline' ? (
        /* Pipeline View */
        <div className="flex gap-4 overflow-x-auto pb-4">
          {activeStages.map((stage) => {
            const stageLeads = getStageLeads(stage);
            const stageValue = stageLeads.reduce((sum, l) => sum + l.value, 0);
            const config = stageConfig[stage];

            return (
              <div
                key={stage}
                className="flex-shrink-0 w-80"
                onDragOver={handleDragOver}
                onDrop={() => handleDrop(stage)}
              >
                <div className="bg-secondary rounded-t-xl px-4 py-3 border border-main border-b-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                        {config.label}
                      </span>
                      <span className="text-sm text-muted">{stageLeads.length}</span>
                    </div>
                    <span className="text-sm font-medium text-main">{formatCurrency(stageValue)}</span>
                  </div>
                </div>
                <div className="bg-secondary/50 rounded-b-xl border border-main border-t-0 p-2 min-h-[500px] space-y-2">
                  {stageLeads.map((lead) => (
                    <LeadCard
                      key={lead.id}
                      lead={lead}
                      onDragStart={() => handleDragStart(lead.id)}
                      isDragging={draggedLead === lead.id}
                      onConvert={() => handleConvertToJob(lead.id)}
                      onMarkLost={() => setShowLostModal(lead.id)}
                      onLogActivity={() => setShowActivityModal(lead.id)}
                      converting={converting === lead.id}
                    />
                  ))}
                  {stageLeads.length === 0 && (
                    <div className="text-center py-8 text-muted text-sm">
                      No leads in this stage
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* List View */
        <Card>
          <CardContent className="p-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.lead')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Score</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.source')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.stage')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.value')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.lastContact')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.nextFollowUp')}</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredLeads.length === 0 && (
                  <tr><td colSpan={8} className="px-6 py-16 text-center">
                    <p className="text-sm font-medium text-main">{t('leads.noRecords')}</p>
                    <p className="text-xs text-muted mt-1">{t('leads.addYourFirstLeadOrAdjustYourFilters')}</p>
                  </td></tr>
                )}
                {filteredLeads.map((lead) => {
                  const config = stageConfig[lead.stage as LeadStage] || stageConfig.new;
                  const score = computeLeadScore(lead);
                  const scoreInfo = getScoreLabel(score);
                  return (
                    <tr key={lead.id} className="border-b border-main/50 hover:bg-surface-hover">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <Avatar name={lead.name} size="sm" />
                          <div>
                            <p className="font-medium text-main">{lead.name}</p>
                            <p className="text-sm text-muted">{lead.email || lead.phone || ''}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-semibold', scoreInfo.color)}>
                          {score} {scoreInfo.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-muted">{sourceLabels[lead.source] || lead.source}</td>
                      <td className="px-6 py-4">
                        <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                          {config.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-medium text-main">{formatCurrency(lead.value)}</td>
                      <td className="px-6 py-4 text-sm text-muted">
                        {lead.lastContactedAt ? formatRelativeTime(lead.lastContactedAt) : 'Never'}
                      </td>
                      <td className="px-6 py-4 text-sm">
                        {lead.nextFollowUp ? (
                          <span className={cn(
                            new Date(lead.nextFollowUp) < new Date() ? 'text-red-600' : 'text-muted'
                          )}>
                            {formatDate(lead.nextFollowUp)}
                          </span>
                        ) : (
                          <span className="text-muted">-</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-1">
                          {!['won', 'lost'].includes(lead.stage) && (
                            <>
                              <Button variant="ghost" size="sm" title="Convert to Job" onClick={() => handleConvertToJob(lead.id)} disabled={converting === lead.id}>
                                {converting === lead.id ? <Loader2 size={14} className="animate-spin" /> : <Briefcase size={14} />}
                              </Button>
                              <Button variant="ghost" size="sm" title="Log Activity" onClick={() => setShowActivityModal(lead.id)}>
                                <Activity size={14} />
                              </Button>
                              <Button variant="ghost" size="sm" title="Mark Lost" onClick={() => setShowLostModal(lead.id)}>
                                <XCircle size={14} />
                              </Button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      {/* New Lead Modal */}
      {showNewLeadModal && (
        <NewLeadModal
          onClose={() => setShowNewLeadModal(false)}
          onCreate={createLead}
        />
      )}

      {/* Lost Reason Modal */}
      {showLostModal && (
        <LostReasonModal
          onClose={() => setShowLostModal(null)}
          onSubmit={async (reason) => {
            await markLost(showLostModal, reason);
            setShowLostModal(null);
          }}
        />
      )}

      {/* Activity Log Modal */}
      {showActivityModal && (
        <ActivityLogModal
          onClose={() => setShowActivityModal(null)}
          onSubmit={async (type, note) => {
            await logActivity(showActivityModal, type, note);
            setShowActivityModal(null);
          }}
        />
      )}

      {/* Capture Form Code Modal */}
      {showCaptureForm && (
        <CaptureFormModal onClose={() => setShowCaptureForm(false)} />
      )}
    </div>
  );
}

function LeadCard({ lead, onDragStart, isDragging, onConvert, onMarkLost, onLogActivity, converting }: {
  lead: LeadData; onDragStart: () => void; isDragging: boolean;
  onConvert: () => void; onMarkLost: () => void; onLogActivity: () => void; converting: boolean;
}) {
  const hasOverdueFollowUp = lead.nextFollowUp && new Date(lead.nextFollowUp) < new Date();
  const score = computeLeadScore(lead);
  const scoreInfo = getScoreLabel(score);
  const [showActions, setShowActions] = useState(false);

  return (
    <div
      draggable
      onDragStart={onDragStart}
      className={cn(
        'bg-surface border border-main rounded-lg p-3 cursor-grab active:cursor-grabbing transition-all hover:shadow-md',
        isDragging && 'opacity-50 scale-95'
      )}
    >
      <div className="flex items-start justify-between mb-2">
        <div className="flex items-center gap-2">
          <Avatar name={lead.name} size="sm" />
          <div>
            <p className="font-medium text-main text-sm">{lead.name}</p>
            {lead.companyName && <p className="text-xs text-muted">{lead.companyName}</p>}
          </div>
        </div>
        <div className="flex items-center gap-1">
          <span className={cn('px-1.5 py-0.5 rounded text-[10px] font-bold', scoreInfo.color)}>
            {score}
          </span>
          <div className="relative">
            <button className="p-1 hover:bg-surface-hover rounded" onClick={() => setShowActions(!showActions)}>
              <MoreHorizontal size={14} className="text-muted" />
            </button>
            {showActions && (
              <div className="absolute right-0 top-7 z-20 bg-surface border border-main rounded-lg shadow-lg py-1 w-44">
                <button className="w-full px-3 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2" onClick={() => { onConvert(); setShowActions(false); }} disabled={converting}>
                  {converting ? <Loader2 size={14} className="animate-spin" /> : <Briefcase size={14} />}
                  Convert to Job
                </button>
                <button className="w-full px-3 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2" onClick={() => { onLogActivity(); setShowActions(false); }}>
                  <Activity size={14} />
                  Log Activity
                </button>
                <button className="w-full px-3 py-2 text-left text-sm hover:bg-surface-hover flex items-center gap-2 text-red-600" onClick={() => { onMarkLost(); setShowActions(false); }}>
                  <XCircle size={14} />
                  Mark Lost
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {lead.notes && <p className="text-sm text-muted line-clamp-2 mb-3">{lead.notes}</p>}

      {/* Contact info */}
      <div className="flex items-center gap-2 mb-2 text-xs text-muted">
        {lead.email && (
          <span className="flex items-center gap-1 truncate">
            <Mail size={10} />
            {lead.email}
          </span>
        )}
        {lead.phone && (
          <span className="flex items-center gap-1">
            <Phone size={10} />
            {lead.phone}
          </span>
        )}
      </div>

      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-main">{formatCurrency(lead.value)}</span>
        <div className="flex items-center gap-2">
          {hasOverdueFollowUp && (
            <span className="text-xs text-red-600 flex items-center gap-1">
              <AlertCircle size={12} />
              Overdue
            </span>
          )}
          <span className="text-xs text-muted">{formatRelativeTime(lead.createdAt)}</span>
        </div>
      </div>

      {/* Source badge */}
      <div className="mt-2 flex items-center gap-1.5">
        <Badge variant="default" size="sm">{sourceLabels[lead.source] || lead.source}</Badge>
        {lead.tags?.filter(t => !['urgent', 'emergency', 'soon'].includes(t)).slice(0, 2).map(tag => (
          <Badge key={tag} variant="default" size="sm">{tag}</Badge>
        ))}
      </div>

      {lead.nextFollowUp && !hasOverdueFollowUp && (
        <div className="mt-2 pt-2 border-t border-main/50 flex items-center gap-1 text-xs text-muted">
          <Clock size={12} />
          Follow up {formatDate(lead.nextFollowUp)}
        </div>
      )}
    </div>
  );
}

function NewLeadModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (input: { name: string; email?: string; phone?: string; companyName?: string; source?: string; value?: number; notes?: string; address?: { street: string; city: string; state: string; zip: string }; trade?: string; urgency?: string; tags?: string[]; nextFollowUp?: string }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [source, setSource] = useState('website');
  const [value, setValue] = useState('');
  const [notes, setNotes] = useState('');
  const [street, setStreet] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zip, setZip] = useState('');
  const [trade, setTrade] = useState('');
  const [urgency, setUrgency] = useState('normal');
  const [nextFollowUp, setNextFollowUp] = useState('');
  const [saving, setSaving] = useState(false);

  const [emailError, setEmailError] = useState('');

  const validateEmail = (val: string) => {
    if (!val) return true;
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
  };

  const handleSubmit = async () => {
    if (!name.trim()) return;
    if (email.trim() && !validateEmail(email.trim())) {
      setEmailError('Please enter a valid email address');
      return;
    }
    setSaving(true);
    try {
      await onCreate({
        name: name.trim(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        companyName: companyName.trim() || undefined,
        source,
        value: value ? parseFloat(value) : undefined,
        notes: notes.trim() || undefined,
        address: street.trim() ? { street: street.trim(), city: city.trim(), state: state.trim(), zip: zip.trim() } : undefined,
        trade: trade || undefined,
        urgency: urgency !== 'normal' ? urgency : undefined,
        nextFollowUp: nextFollowUp || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create lead');
    } finally {
      setSaving(false);
    }
  };

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent";

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{t('leads.addNewLead')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Name *</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="John Smith" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('settings.company')}</label>
              <input type="text" value={companyName} onChange={(e) => setCompanyName(e.target.value)} placeholder="ABC Properties" className={inputCls} />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.email')}</label>
              <input
                type="email"
                value={email}
                onChange={(e) => { setEmail(e.target.value); setEmailError(''); }}
                onBlur={() => { if (email.trim() && !validateEmail(email.trim())) setEmailError('Please enter a valid email address'); }}
                placeholder="john@email.com"
                className={`w-full px-4 py-2.5 bg-main border rounded-lg text-main placeholder:text-muted focus:ring-1 ${emailError ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : 'border-main focus:border-accent focus:ring-accent'}`}
              />
              {emailError && <p className="text-xs text-red-500 mt-1">{emailError}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.phone')}</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => {
                  const digits = e.target.value.replace(/\D/g, '').slice(0, 10);
                  const formatted = digits.length > 6 ? `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}` : digits.length > 3 ? `(${digits.slice(0,3)}) ${digits.slice(3)}` : digits;
                  setPhone(formatted);
                }}
                placeholder="(555) 123-4567"
                className={inputCls}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.trade')}</label>
              <select value={trade} onChange={(e) => setTrade(e.target.value)} className={inputCls}>
                <option value="">{t('leads.selectTrade')}</option>
                <option value="electrical">{t('common.electrical')}</option>
                <option value="plumbing">{t('common.plumbing')}</option>
                <option value="hvac">{t('leads.hvac')}</option>
                <option value="roofing">{t('common.roofing')}</option>
                <option value="painting">{t('leads.painting')}</option>
                <option value="carpentry">{t('leads.carpentry')}</option>
                <option value="flooring">{t('leads.flooring')}</option>
                <option value="landscaping">{t('leads.landscaping')}</option>
                <option value="general">{t('leads.generalContracting')}</option>
                <option value="solar">{t('common.solar')}</option>
                <option value="restoration">{t('leads.restoration')}</option>
                <option value="other">{t('common.other')}</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.urgency')}</label>
              <select value={urgency} onChange={(e) => setUrgency(e.target.value)} className={inputCls}>
                <option value="normal">{t('common.normal')}</option>
                <option value="soon">{t('leads.soon')}</option>
                <option value="urgent">{t('common.urgent')}</option>
                <option value="emergency">{t('common.emergency')}</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.source')}</label>
              <select value={source} onChange={(e) => setSource(e.target.value)} className={inputCls}>
                <option value="website">{t('common.website')}</option>
                <option value="referral">{t('common.referral')}</option>
                <option value="google">{t('leads.google')}</option>
                <option value="yelp">{t('leads.yelp')}</option>
                <option value="facebook">{t('leads.sources.facebook')}</option>
                <option value="instagram">{t('leads.instagram')}</option>
                <option value="nextdoor">{t('leads.nextdoor')}</option>
                <option value="homeadvisor">{t('leads.homeadvisor')}</option>
                <option value="thumbtack">{t('leads.sources.thumbtack')}</option>
                <option value="angi">{t('leads.sources.angi')}</option>
                <option value="other">{t('common.other')}</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('common.estimatedValue')}</label>
              <input type="number" value={value} onChange={(e) => setValue(e.target.value)} placeholder="5000" className={inputCls} />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.address')}</label>
            <div className="grid grid-cols-1 gap-2">
              <input type="text" value={street} onChange={(e) => setStreet(e.target.value)} placeholder="123 Main Street" className={inputCls} />
              <div className="grid grid-cols-6 gap-2">
                <input type="text" value={city} onChange={(e) => setCity(e.target.value)} placeholder={t('common.city')} className={`col-span-3 ${inputCls}`} />
                <input type="text" value={state} onChange={(e) => setState(e.target.value)} placeholder="ST" maxLength={2} className={`col-span-1 ${inputCls}`} />
                <input type="text" value={zip} onChange={(e) => setZip(e.target.value.replace(/\D/g, '').slice(0, 5))} placeholder={t('common.zip')} className={`col-span-2 ${inputCls}`} />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.followUpDate')}</label>
            <input type="date" value={nextFollowUp} onChange={(e) => setNextFollowUp(e.target.value)} className={inputCls} />
          </div>

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="What are they looking for?" rows={3} className={`${inputCls} resize-none`} />
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Adding...' : 'Add Lead'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Lost Reason Modal — require reason when marking a lead as lost
function LostReasonModal({ onClose, onSubmit }: { onClose: () => void; onSubmit: (reason: string) => Promise<void> }) {
  const [reason, setReason] = useState('');
  const [customReason, setCustomReason] = useState('');
  const [saving, setSaving] = useState(false);

  const reasons = [
    { value: 'price_too_high', label: 'Price too high' },
    { value: 'chose_competitor', label: 'Chose competitor' },
    { value: 'decided_not_to_proceed', label: 'Decided not to proceed' },
    { value: 'unresponsive', label: 'Unresponsive' },
    { value: 'out_of_service_area', label: 'Out of service area' },
    { value: 'timeline_mismatch', label: 'Timeline mismatch' },
    { value: 'scope_too_small', label: 'Scope too small' },
    { value: 'other', label: 'Other' },
  ];

  const handleSubmit = async () => {
    const finalReason = reason === 'other' ? customReason.trim() : reason;
    if (!finalReason) return;
    setSaving(true);
    try {
      await onSubmit(finalReason);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setSaving(false);
    }
  };

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent";

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <XCircle size={20} className="text-red-500" />
            Mark Lead as Lost
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted">Why was this lead lost? This helps track patterns and improve conversion.</p>
          <div className="space-y-2">
            {reasons.map(r => (
              <label key={r.value} className="flex items-center gap-3 p-2 rounded-lg hover:bg-surface-hover cursor-pointer">
                <input
                  type="radio"
                  name="lostReason"
                  value={r.value}
                  checked={reason === r.value}
                  onChange={() => setReason(r.value)}
                  className="accent-accent"
                />
                <span className="text-sm text-main">{r.label}</span>
              </label>
            ))}
          </div>
          {reason === 'other' && (
            <input type="text" value={customReason} onChange={(e) => setCustomReason(e.target.value)} placeholder="Describe reason..." className={inputCls} autoFocus />
          )}
          <div className="flex items-center gap-3 pt-2">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>Cancel</Button>
            <Button variant="danger" className="flex-1" onClick={handleSubmit} disabled={saving || (!reason || (reason === 'other' && !customReason.trim()))}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <XCircle size={16} />}
              {saving ? 'Saving...' : 'Mark Lost'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Activity Log Modal — log a call, email, text, or visit
function ActivityLogModal({ onClose, onSubmit }: { onClose: () => void; onSubmit: (type: string, note: string) => Promise<void> }) {
  const [type, setType] = useState('call');
  const [note, setNote] = useState('');
  const [saving, setSaving] = useState(false);

  const activityTypes = [
    { value: 'call', label: 'Phone Call', icon: Phone },
    { value: 'email', label: 'Email', icon: Mail },
    { value: 'text', label: 'Text Message', icon: MessageSquare },
    { value: 'visit', label: 'Site Visit', icon: MapPin },
  ];

  const handleSubmit = async () => {
    if (!note.trim()) return;
    setSaving(true);
    try {
      await onSubmit(type, note.trim());
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed');
    } finally {
      setSaving(false);
    }
  };

  const inputCls = "w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent";

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity size={20} className="text-blue-500" />
            Log Activity
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-4 gap-2">
            {activityTypes.map(at => {
              const Icon = at.icon;
              return (
                <button
                  key={at.value}
                  onClick={() => setType(at.value)}
                  className={cn(
                    'flex flex-col items-center gap-1 p-3 rounded-lg border text-sm transition-colors',
                    type === at.value
                      ? 'border-accent bg-accent/10 text-accent'
                      : 'border-main text-muted hover:bg-surface-hover'
                  )}
                >
                  <Icon size={18} />
                  <span className="text-xs">{at.label}</span>
                </button>
              );
            })}
          </div>
          <textarea value={note} onChange={(e) => setNote(e.target.value)} placeholder="What happened?" rows={3} className={`${inputCls} resize-none`} autoFocus />
          <div className="flex items-center gap-3 pt-2">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>Cancel</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !note.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Activity size={16} />}
              {saving ? 'Saving...' : 'Log Activity'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Lead Capture Form — embeddable code for company website
function CaptureFormModal({ onClose }: { onClose: () => void }) {
  const [copied, setCopied] = useState(false);

  const embedCode = `<!-- Zafto Lead Capture Form -->
<form id="zafto-lead-form" action="https://zafto.cloud/api/leads/capture" method="POST">
  <input type="text" name="name" placeholder="Your Name" required />
  <input type="email" name="email" placeholder="Email Address" />
  <input type="tel" name="phone" placeholder="Phone Number" />
  <textarea name="description" placeholder="Describe your project"></textarea>
  <select name="urgency">
    <option value="normal">Not Urgent</option>
    <option value="soon">Within 2 Weeks</option>
    <option value="urgent">This Week</option>
    <option value="emergency">Emergency</option>
  </select>
  <input type="hidden" name="source" value="website" />
  <button type="submit">Request a Quote</button>
</form>
<script>
document.getElementById('zafto-lead-form').addEventListener('submit', function(e) {
  e.preventDefault();
  var fd = new FormData(this);
  var data = {};
  fd.forEach(function(v, k) { data[k] = v; });
  fetch(this.action, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  }).then(function() {
    alert('Thank you! We will be in touch shortly.');
  }).catch(function() {
    alert('Something went wrong. Please call us directly.');
  });
});
</script>`;

  const handleCopy = () => {
    navigator.clipboard.writeText(embedCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[80vh] overflow-y-auto">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Copy size={20} className="text-blue-500" />
            Lead Capture Form
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted">
            Copy this HTML code and paste it into your company website. When visitors submit the form, it creates a new lead in Zafto automatically.
          </p>
          <div className="relative">
            <pre className="bg-secondary rounded-lg p-4 text-xs text-main overflow-x-auto max-h-[400px] overflow-y-auto font-mono whitespace-pre-wrap">
              {embedCode}
            </pre>
            <Button
              size="sm"
              className="absolute top-2 right-2"
              onClick={handleCopy}
            >
              {copied ? <CheckCircle size={14} /> : <Copy size={14} />}
              {copied ? 'Copied!' : 'Copy'}
            </Button>
          </div>
          <div className="flex items-center gap-3 pt-2">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
