'use client';

import { useState } from 'react';
import {
  Mail,
  Send,
  FileText,
  Users,
  Plus,
  Trash2,
  Edit3,
  BarChart3,
  Clock,
  CheckCircle,
  AlertTriangle,
  Eye,
  MousePointerClick,
  Loader2,
  X,
  Calendar,
  UserMinus,
  Megaphone,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, formatRelativeTime, cn } from '@/lib/utils';
import { useEmail } from '@/lib/hooks/use-email';
import type { EmailTemplate, EmailCampaign } from '@/lib/hooks/use-email';
import { useTranslation } from '@/lib/translations';

type Tab = 'templates' | 'sent' | 'campaigns' | 'unsubscribes';

const SEND_STATUS_CONFIG: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  queued: { label: 'Queued', variant: 'secondary' },
  sent: { label: 'Sent', variant: 'info' },
  delivered: { label: 'Delivered', variant: 'success' },
  opened: { label: 'Opened', variant: 'info' },
  clicked: { label: 'Clicked', variant: 'purple' },
  bounced: { label: 'Bounced', variant: 'error' },
  dropped: { label: 'Dropped', variant: 'error' },
  spam: { label: 'Spam', variant: 'warning' },
  unsubscribed: { label: 'Unsubscribed', variant: 'warning' },
  failed: { label: 'Failed', variant: 'error' },
};

const CAMPAIGN_STATUS_CONFIG: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  draft: { label: 'Draft', variant: 'secondary' },
  scheduled: { label: 'Scheduled', variant: 'info' },
  sending: { label: 'Sending', variant: 'warning' },
  sent: { label: 'Sent', variant: 'success' },
  cancelled: { label: 'Cancelled', variant: 'error' },
};

const TEMPLATE_TYPE_CONFIG: Record<string, { label: string; variant: 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple' }> = {
  transactional: { label: 'Transactional', variant: 'info' },
  marketing: { label: 'Marketing', variant: 'purple' },
  system: { label: 'System', variant: 'secondary' },
  custom: { label: 'Custom', variant: 'default' },
};

export default function EmailPage() {
  const { t } = useTranslation();
  const {
    templates,
    sends,
    campaigns,
    unsubscribes,
    loading,
    error,
    activeTemplates,
    totalSent,
    deliveryRate,
    openRate,
    createTemplate,
    updateTemplate,
    deleteTemplate,
    createCampaign,
    updateCampaign,
    scheduleCampaign,
  } = useEmail();

  const [tab, setTab] = useState<Tab>('templates');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<EmailTemplate | null>(null);
  const [showCampaignModal, setShowCampaignModal] = useState(false);
  const [editingCampaign, setEditingCampaign] = useState<EmailCampaign | null>(null);

  const tabs: { key: Tab; label: string; icon: React.ReactNode }[] = [
    { key: 'templates', label: 'Templates', icon: <FileText size={16} /> },
    { key: 'sent', label: 'Sent Emails', icon: <Send size={16} /> },
    { key: 'campaigns', label: 'Campaigns', icon: <Megaphone size={16} /> },
    { key: 'unsubscribes', label: 'Unsubscribes', icon: <UserMinus size={16} /> },
  ];

  // Filtered data
  const filteredSends = sends.filter((s) => {
    const matchesSearch =
      s.toEmail.toLowerCase().includes(search.toLowerCase()) ||
      s.subject.toLowerCase().includes(search.toLowerCase()) ||
      (s.toName || '').toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || s.status === statusFilter;
    const matchesType = typeFilter === 'all' || s.emailType === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const filteredTemplates = templates.filter((t) =>
    t.name.toLowerCase().includes(search.toLowerCase()) ||
    t.subject.toLowerCase().includes(search.toLowerCase())
  );

  const filteredCampaigns = campaigns.filter((c) =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.subject.toLowerCase().includes(search.toLowerCase())
  );

  const filteredUnsubscribes = unsubscribes.filter((u) =>
    u.email.toLowerCase().includes(search.toLowerCase())
  );

  const sendStatusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'queued', label: 'Queued' },
    { value: 'sent', label: 'Sent' },
    { value: 'delivered', label: 'Delivered' },
    { value: 'opened', label: 'Opened' },
    { value: 'clicked', label: 'Clicked' },
    { value: 'bounced', label: 'Bounced' },
    { value: 'failed', label: 'Failed' },
  ];

  const sendTypeOptions = [
    { value: 'all', label: 'All Types' },
    { value: 'transactional', label: 'Transactional' },
    { value: 'marketing', label: 'Marketing' },
    { value: 'system', label: 'System' },
  ];

  const handleDeleteTemplate = async (id: string) => {
    if (!confirm('Delete this template? This action cannot be undone.')) return;
    try {
      await deleteTemplate(id);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to delete template');
    }
  };

  const handleScheduleCampaign = async (campaign: EmailCampaign) => {
    const dateStr = prompt('Enter schedule date and time (YYYY-MM-DD HH:MM):');
    if (!dateStr) return;
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      alert('Invalid date format');
      return;
    }
    try {
      await scheduleCampaign(campaign.id, date);
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to schedule campaign');
    }
  };

  const handleSendCampaign = async (campaign: EmailCampaign) => {
    if (!confirm(`Send campaign "${campaign.name}" now?`)) return;
    try {
      await updateCampaign(campaign.id, { status: 'sending' });
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to send campaign');
    }
  };

  if (loading && templates.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-muted" />
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('email.title')}</h1>
          <p className="text-muted mt-1">Manage templates, campaigns, and email delivery</p>
        </div>
        <div className="flex items-center gap-3">
          {tab === 'templates' && (
            <Button onClick={() => { setEditingTemplate(null); setShowTemplateModal(true); }}>
              <Plus size={16} />
              New Template
            </Button>
          )}
          {tab === 'campaigns' && (
            <Button onClick={() => { setEditingCampaign(null); setShowCampaignModal(true); }}>
              <Plus size={16} />
              New Campaign
            </Button>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <FileText size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {activeTemplates.length}<span className="text-sm font-normal text-muted">/{templates.length}</span>
                </p>
                <p className="text-sm text-muted">Templates (active/total)</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Send size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalSent}</p>
                <p className="text-sm text-muted">{t('email.sentThisMonth')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg">
                <CheckCircle size={20} className="text-cyan-600 dark:text-cyan-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{deliveryRate}%</p>
                <p className="text-sm text-muted">{t('email.deliveryRate')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Eye size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{openRate}%</p>
                <p className="text-sm text-muted">{t('email.avgOpenRate')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => { setTab(t.key); setSearch(''); setStatusFilter('all'); setTypeFilter('all'); }}
            className={cn(
              'flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium transition-colors',
              tab === t.key ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
            )}
          >
            {t.icon}
            {t.label}
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={
            tab === 'templates' ? 'Search templates...' :
            tab === 'sent' ? 'Search sent emails...' :
            tab === 'campaigns' ? 'Search campaigns...' :
            'Search emails...'
          }
          className="sm:w-80"
        />
        {tab === 'sent' && (
          <>
            <Select
              options={sendStatusOptions}
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="sm:w-44"
            />
            <Select
              options={sendTypeOptions}
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="sm:w-44"
            />
          </>
        )}
      </div>

      {/* Tab Content */}
      {tab === 'templates' && (
        <TemplatesTab
          templates={filteredTemplates}
          onEdit={(t) => { setEditingTemplate(t); setShowTemplateModal(true); }}
          onDelete={handleDeleteTemplate}
        />
      )}

      {tab === 'sent' && <SentTab sends={filteredSends} />}

      {tab === 'campaigns' && (
        <CampaignsTab
          campaigns={filteredCampaigns}
          onEdit={(c) => { setEditingCampaign(c); setShowCampaignModal(true); }}
          onSchedule={handleScheduleCampaign}
          onSend={handleSendCampaign}
        />
      )}

      {tab === 'unsubscribes' && <UnsubscribesTab unsubscribes={filteredUnsubscribes} />}

      {/* Template Modal */}
      {showTemplateModal && (
        <TemplateModal
          template={editingTemplate}
          onClose={() => setShowTemplateModal(false)}
          onCreate={createTemplate}
          onUpdate={updateTemplate}
        />
      )}

      {/* Campaign Modal */}
      {showCampaignModal && (
        <CampaignModal
          campaign={editingCampaign}
          templates={activeTemplates}
          onClose={() => setShowCampaignModal(false)}
          onCreate={createCampaign}
          onUpdate={updateCampaign}
        />
      )}
    </div>
  );
}

// --- Templates Tab ---

function TemplatesTab({
  templates,
  onEdit,
  onDelete,
}: {
  templates: EmailTemplate[];
  onEdit: (t: EmailTemplate) => void;
  onDelete: (id: string) => void;
}) {
  const { t } = useTranslation();
  if (templates.length === 0) {
    return (
      <Card>
        <CardContent className="py-16 text-center">
          <FileText size={48} className="mx-auto mb-3 text-muted opacity-50" />
          <p className="text-muted">{t('common.noTemplatesFound')}</p>
          <p className="text-sm text-muted mt-1">{t('email.createYourFirstEmailTemplateToGetStarted')}</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      {templates.map((tmpl) => {
        const typeConfig = TEMPLATE_TYPE_CONFIG[tmpl.templateType] || TEMPLATE_TYPE_CONFIG.custom;
        return (
          <Card key={tmpl.id} hover>
            <CardContent className="p-5">
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1 min-w-0">
                  <h3 className="font-semibold text-main truncate">{tmpl.name}</h3>
                  <p className="text-sm text-muted truncate mt-0.5">{tmpl.subject}</p>
                </div>
                <div className="flex items-center gap-1 ml-2 flex-shrink-0">
                  <button
                    onClick={() => onEdit(tmpl)}
                    className="p-1.5 hover:bg-surface-hover rounded-lg transition-colors"
                  >
                    <Edit3 size={14} className="text-muted" />
                  </button>
                  <button
                    onClick={() => onDelete(tmpl.id)}
                    className="p-1.5 hover:bg-red-100 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                  >
                    <Trash2 size={14} className="text-muted hover:text-red-500" />
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2 mb-3">
                <Badge variant={typeConfig.variant}>{typeConfig.label}</Badge>
                {!tmpl.isActive && <Badge variant="warning">{t('common.inactive')}</Badge>}
              </div>

              {tmpl.triggerEvent && (
                <div className="flex items-center gap-1.5 text-sm text-muted mb-2">
                  <Clock size={12} />
                  <span>Trigger: {tmpl.triggerEvent}</span>
                </div>
              )}

              <div className="flex items-center justify-between text-sm text-muted pt-2 border-t border-main/50">
                <span>{tmpl.variables.length} variable{tmpl.variables.length !== 1 ? 's' : ''}</span>
                <span>{formatRelativeTime(tmpl.createdAt)}</span>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}

// --- Sent Tab ---

function SentTab({ sends }: { sends: ReturnType<typeof useEmail>['sends'] }) {
  const { t } = useTranslation();
  if (sends.length === 0) {
    return (
      <Card>
        <CardContent className="py-16 text-center">
          <Send size={48} className="mx-auto mb-3 text-muted opacity-50" />
          <p className="text-muted">{t('email.noSentEmailsFound')}</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.to')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.subject')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.sent')}</th>
              </tr>
            </thead>
            <tbody>
              {sends.map((send) => {
                const statusConf = SEND_STATUS_CONFIG[send.status] || { label: send.status, variant: 'default' as const };
                return (
                  <tr key={send.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-3">
                      <div>
                        <p className="text-sm font-medium text-main">{send.toName || send.toEmail}</p>
                        {send.toName && <p className="text-xs text-muted">{send.toEmail}</p>}
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <p className="text-sm text-main truncate max-w-[300px]">{send.subject}</p>
                    </td>
                    <td className="px-6 py-3">
                      <span className="text-sm text-muted capitalize">{send.emailType}</span>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant={statusConf.variant} dot>{statusConf.label}</Badge>
                    </td>
                    <td className="px-6 py-3 text-sm text-muted whitespace-nowrap">
                      {send.sentAt ? formatRelativeTime(send.sentAt) : formatRelativeTime(send.createdAt)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}

// --- Campaigns Tab ---

function CampaignsTab({
  campaigns,
  onEdit,
  onSchedule,
  onSend,
}: {
  campaigns: EmailCampaign[];
  onEdit: (c: EmailCampaign) => void;
  onSchedule: (c: EmailCampaign) => void;
  onSend: (c: EmailCampaign) => void;
}) {
  const { t } = useTranslation();
  if (campaigns.length === 0) {
    return (
      <Card>
        <CardContent className="py-16 text-center">
          <Megaphone size={48} className="mx-auto mb-3 text-muted opacity-50" />
          <p className="text-muted">{t('email.noCampaignsFound')}</p>
          <p className="text-sm text-muted mt-1">{t('email.createACampaignToSendBulkEmails')}</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('email.campaign')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('email.recipients')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.sent')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.delivered')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('email.openRate')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('email.clickRate')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.schedule')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {campaigns.map((campaign) => {
                const statusConf = CAMPAIGN_STATUS_CONFIG[campaign.status] || { label: campaign.status, variant: 'default' as const };
                return (
                  <tr key={campaign.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-3">
                      <div>
                        <p className="text-sm font-medium text-main">{campaign.name}</p>
                        <p className="text-xs text-muted truncate max-w-[200px]">{campaign.subject}</p>
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant={statusConf.variant} dot>{statusConf.label}</Badge>
                    </td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-1.5 text-sm text-main">
                        <Users size={14} className="text-muted" />
                        {campaign.recipientCount}
                      </div>
                    </td>
                    <td className="px-6 py-3 text-sm text-main">{campaign.totalSent}</td>
                    <td className="px-6 py-3 text-sm text-main">{campaign.totalDelivered}</td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-1.5 bg-secondary rounded-full overflow-hidden">
                          <div
                            className="h-full bg-blue-500 rounded-full"
                            style={{ width: `${Math.min(campaign.openRate, 100)}%` }}
                          />
                        </div>
                        <span className="text-sm text-main">{campaign.openRate}%</span>
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-2">
                        <div className="w-16 h-1.5 bg-secondary rounded-full overflow-hidden">
                          <div
                            className="h-full bg-purple-500 rounded-full"
                            style={{ width: `${Math.min(campaign.clickRate, 100)}%` }}
                          />
                        </div>
                        <span className="text-sm text-main">{campaign.clickRate}%</span>
                      </div>
                    </td>
                    <td className="px-6 py-3 text-sm text-muted whitespace-nowrap">
                      {campaign.scheduledAt ? formatDate(campaign.scheduledAt) : '-'}
                    </td>
                    <td className="px-6 py-3">
                      {campaign.status === 'draft' && (
                        <div className="flex items-center gap-1">
                          <Button variant="ghost" size="sm" onClick={() => onEdit(campaign)}>
                            <Edit3 size={14} />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => onSchedule(campaign)}>
                            <Calendar size={14} />
                          </Button>
                          <Button variant="ghost" size="sm" onClick={() => onSend(campaign)}>
                            <Send size={14} />
                          </Button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}

// --- Unsubscribes Tab ---

function UnsubscribesTab({ unsubscribes }: { unsubscribes: ReturnType<typeof useEmail>['unsubscribes'] }) {
  const { t } = useTranslation();
  if (unsubscribes.length === 0) {
    return (
      <Card>
        <CardContent className="py-16 text-center">
          <UserMinus size={48} className="mx-auto mb-3 text-muted opacity-50" />
          <p className="text-muted">{t('email.noUnsubscribes')}</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent className="p-0">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.email')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.reason')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.date')}</th>
              </tr>
            </thead>
            <tbody>
              {unsubscribes.map((unsub) => (
                <tr key={unsub.id} className="border-b border-main/50 hover:bg-surface-hover">
                  <td className="px-6 py-3">
                    <div className="flex items-center gap-2">
                      <Mail size={14} className="text-muted" />
                      <span className="text-sm text-main">{unsub.email}</span>
                    </div>
                  </td>
                  <td className="px-6 py-3 text-sm text-muted">{unsub.reason || '-'}</td>
                  <td className="px-6 py-3 text-sm text-muted whitespace-nowrap">
                    {formatDate(unsub.unsubscribedAt)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </CardContent>
    </Card>
  );
}

// --- Template Modal ---

function TemplateModal({
  template,
  onClose,
  onCreate,
  onUpdate,
}: {
  template: EmailTemplate | null;
  onClose: () => void;
  onCreate: (input: {
    name: string;
    subject: string;
    bodyHtml: string;
    bodyText: string;
    templateType: EmailTemplate['templateType'];
    triggerEvent?: string;
    isActive?: boolean;
  }) => Promise<string>;
  onUpdate: (id: string, data: Partial<{
    name: string;
    subject: string;
    bodyHtml: string;
    bodyText: string;
    templateType: EmailTemplate['templateType'];
    triggerEvent: string | null;
    isActive: boolean;
  }>) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [name, setName] = useState(template?.name || '');
  const [subject, setSubject] = useState(template?.subject || '');
  const [bodyHtml, setBodyHtml] = useState(template?.bodyHtml || '');
  const [bodyText, setBodyText] = useState(template?.bodyText || '');
  const [templateType, setTemplateType] = useState<EmailTemplate['templateType']>(template?.templateType || 'custom');
  const [triggerEvent, setTriggerEvent] = useState(template?.triggerEvent || '');
  const [isActive, setIsActive] = useState(template?.isActive ?? true);
  const [saving, setSaving] = useState(false);

  const typeOptions = [
    { value: 'transactional', label: 'Transactional' },
    { value: 'marketing', label: 'Marketing' },
    { value: 'system', label: 'System' },
    { value: 'custom', label: 'Custom' },
  ];

  const handleSubmit = async () => {
    if (!name.trim() || !subject.trim()) return;
    setSaving(true);
    try {
      if (template) {
        await onUpdate(template.id, {
          name: name.trim(),
          subject: subject.trim(),
          bodyHtml,
          bodyText,
          templateType,
          triggerEvent: triggerEvent.trim() || null,
          isActive,
        });
      } else {
        await onCreate({
          name: name.trim(),
          subject: subject.trim(),
          bodyHtml,
          bodyText,
          templateType,
          triggerEvent: triggerEvent.trim() || undefined,
          isActive,
        });
      }
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to save template');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{template ? 'Edit Template' : 'New Template'}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">Template Name *</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Invoice Reminder"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <Select
                label={t('common.type')}
                options={typeOptions}
                value={templateType}
                onChange={(e) => setTemplateType(e.target.value as EmailTemplate['templateType'])}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">{t('email.triggerEvent')}</label>
              <input
                type="text"
                value={triggerEvent}
                onChange={(e) => setTriggerEvent(e.target.value)}
                placeholder="e.g. invoice.created"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">Subject *</label>
              <input
                type="text"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                placeholder="Email subject line"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">{t('email.htmlBody')}</label>
              <textarea
                value={bodyHtml}
                onChange={(e) => setBodyHtml(e.target.value)}
                placeholder="<html>...</html>"
                rows={6}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none font-mono text-sm"
              />
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-main mb-1.5">{t('email.plainTextBody')}</label>
              <textarea
                value={bodyText}
                onChange={(e) => setBodyText(e.target.value)}
                placeholder="Plain text version..."
                rows={4}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent resize-none"
              />
            </div>
            <div className="col-span-2">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                  className="rounded border-main"
                />
                <span className="text-sm font-medium text-main">{t('common.active')}</span>
              </label>
            </div>
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim() || !subject.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : template ? <Edit3 size={16} /> : <Plus size={16} />}
              {saving ? 'Saving...' : template ? 'Update Template' : 'Create Template'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// --- Campaign Modal ---

function CampaignModal({
  campaign,
  templates,
  onClose,
  onCreate,
  onUpdate,
}: {
  campaign: EmailCampaign | null;
  templates: EmailTemplate[];
  onClose: () => void;
  onCreate: (input: {
    name: string;
    templateId?: string;
    subject: string;
    audienceType: EmailCampaign['audienceType'];
    recipientCount?: number;
  }) => Promise<string>;
  onUpdate: (id: string, data: Partial<{
    name: string;
    templateId: string | null;
    subject: string;
    audienceType: EmailCampaign['audienceType'];
    recipientCount: number;
  }>) => Promise<void>;
}) {
  const [name, setName] = useState(campaign?.name || '');
  const [subject, setSubject] = useState(campaign?.subject || '');
  const [templateId, setTemplateId] = useState(campaign?.templateId || '');
  const [audienceType, setAudienceType] = useState<EmailCampaign['audienceType']>(campaign?.audienceType || 'all_customers');
  const [recipientCount, setRecipientCount] = useState(String(campaign?.recipientCount || ''));
  const [saving, setSaving] = useState(false);

  const audienceOptions = [
    { value: 'all_customers', label: 'All Customers' },
    { value: 'segment', label: 'Segment' },
    { value: 'manual', label: 'Manual Selection' },
    { value: 'leads', label: 'Leads' },
  ];

  const templateOptions = [
    { value: '', label: 'No Template' },
    ...templates.map((t) => ({ value: t.id, label: t.name })),
  ];

  const handleSubmit = async () => {
    if (!name.trim() || !subject.trim()) return;
    setSaving(true);
    try {
      if (campaign) {
        await onUpdate(campaign.id, {
          name: name.trim(),
          templateId: templateId || null,
          subject: subject.trim(),
          audienceType,
          recipientCount: recipientCount ? parseInt(recipientCount) : 0,
        });
      } else {
        await onCreate({
          name: name.trim(),
          templateId: templateId || undefined,
          subject: subject.trim(),
          audienceType,
          recipientCount: recipientCount ? parseInt(recipientCount) : 0,
        });
      }
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to save campaign');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{campaign ? 'Edit Campaign' : 'New Campaign'}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Campaign Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Spring Promotion"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Subject *</label>
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              placeholder="Email subject line"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <Select
            label="Template"
            options={templateOptions}
            value={templateId}
            onChange={(e) => setTemplateId(e.target.value)}
          />
          <Select
            label="Audience"
            options={audienceOptions}
            value={audienceType}
            onChange={(e) => setAudienceType(e.target.value as EmailCampaign['audienceType'])}
          />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Estimated Recipients</label>
            <input
              type="number"
              value={recipientCount}
              onChange={(e) => setRecipientCount(e.target.value)}
              placeholder="0"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim() || !subject.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : campaign ? <Edit3 size={16} /> : <Plus size={16} />}
              {saving ? 'Saving...' : campaign ? 'Update Campaign' : 'Create Campaign'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
