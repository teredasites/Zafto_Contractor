'use client';

import { useState, useMemo } from 'react';
import {
  Plus,
  FileText,
  FileSignature,
  Layout,
  Calendar,
  Copy,
  Trash2,
  Send,
  Eye,
  Download,
  ChevronDown,
  ChevronUp,
  Loader2,
  X,
  PenTool,
  Clock,
  LayoutTemplate,
  Variable,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import DOMPurify from 'dompurify';
import { formatDate, cn } from '@/lib/utils';
import {
  useZDocs,
  type ZDocsTemplate,
  type ZDocsRender,
  type ZDocsSignatureRequest,
  ZDOCS_TEMPLATE_TYPES,
  ZDOCS_TEMPLATE_TYPE_LABELS,
  ZDOCS_ENTITY_TYPES,
  ZDOCS_ENTITY_TYPE_LABELS,
} from '@/lib/hooks/use-zdocs';
import { useTranslation } from '@/lib/translations';

// Sanitize HTML to prevent XSS from rendered templates
function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['p', 'br', 'b', 'i', 'u', 'strong', 'em', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'ul', 'ol', 'li', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'div', 'span', 'hr', 'img', 'a',
      'blockquote', 'pre', 'code', 'sub', 'sup', 'small'],
    ALLOWED_ATTR: ['class', 'style', 'href', 'src', 'alt', 'width', 'height', 'colspan', 'rowspan', 'target'],
    ALLOW_DATA_ATTR: false,
  });
}

// ==================== STATUS CONFIGS ====================

type BadgeVariant = 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple';

const renderStatusConfig: Record<string, { label: string; variant: BadgeVariant }> = {
  draft: { label: 'Draft', variant: 'default' },
  rendered: { label: 'Rendered', variant: 'info' },
  sent: { label: 'Sent', variant: 'purple' },
  signed: { label: 'Signed', variant: 'success' },
};

const signatureStatusConfig: Record<string, { label: string; variant: BadgeVariant }> = {
  pending: { label: 'Pending', variant: 'default' },
  sent: { label: 'Sent', variant: 'info' },
  viewed: { label: 'Viewed', variant: 'purple' },
  signed: { label: 'Signed', variant: 'success' },
  declined: { label: 'Declined', variant: 'error' },
  expired: { label: 'Expired', variant: 'warning' },
};

const templateTypeConfig: Record<string, { variant: BadgeVariant }> = {
  contract: { variant: 'purple' },
  proposal: { variant: 'info' },
  lien_waiver: { variant: 'warning' },
  change_order: { variant: 'warning' },
  invoice: { variant: 'success' },
  warranty: { variant: 'info' },
  scope_of_work: { variant: 'default' },
  safety_plan: { variant: 'error' },
  daily_report: { variant: 'default' },
  inspection_report: { variant: 'info' },
  completion_cert: { variant: 'success' },
  other: { variant: 'secondary' },
};

type TabId = 'templates' | 'documents' | 'signatures';

// ==================== MAIN COMPONENT ====================

export default function ZDocsPage() {
  const { t } = useTranslation();
  const {
    templates,
    renders,
    signatureRequests,
    loading,
    error,
    createTemplate,
    deleteTemplate,
    duplicateTemplate,
    renderDocument,
    sendForSignature,
    deleteRender,
    activeTemplates,
    totalRenders,
    pendingSignatures,
    recentRenders,
  } = useZDocs();

  const [activeTab, setActiveTab] = useState<TabId>('templates');
  const [search, setSearch] = useState('');
  const [showCreateTemplateModal, setShowCreateTemplateModal] = useState(false);
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [showSignatureModal, setShowSignatureModal] = useState<string | null>(null);
  const [preselectedTemplateId, setPreselectedTemplateId] = useState<string | null>(null);

  const tabs: { id: TabId; label: string; count?: number }[] = [
    { id: 'templates', label: 'Templates', count: activeTemplates.length },
    { id: 'documents', label: 'Generated Documents', count: totalRenders },
    { id: 'signatures', label: 'Signatures', count: pendingSignatures.length },
  ];

  const handleUseTemplate = (templateId: string) => {
    setPreselectedTemplateId(templateId);
    setShowGenerateModal(true);
  };

  if (loading && templates.length === 0) {
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

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('zdocs.title')}</h1>
          <p className="text-muted mt-1">PDF-first document authoring, generation, and e-signatures</p>
        </div>
        <div className="flex items-center gap-3">
          {activeTab === 'templates' && (
            <Button onClick={() => setShowCreateTemplateModal(true)}>
              <Plus size={16} />
              Create Template
            </Button>
          )}
          {activeTab === 'documents' && (
            <Button onClick={() => { setPreselectedTemplateId(null); setShowGenerateModal(true); }}>
              <FileText size={16} />
              Generate Document
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
                <LayoutTemplate size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeTemplates.length}</p>
                <p className="text-sm text-muted">{t('common.activeTemplates')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <FileText size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalRenders}</p>
                <p className="text-sm text-muted">{t('zdocs.documentsGenerated')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <PenTool size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{pendingSignatures.length}</p>
                <p className="text-sm text-muted">{t('common.pendingSignatures')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Calendar size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{recentRenders.length}</p>
                <p className="text-sm text-muted">{t('common.thisMonth')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tab Bar */}
      <div className="flex items-center gap-1 p-1 bg-secondary rounded-lg w-fit">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => {
              setActiveTab(tab.id);
              setSearch('');
            }}
            className={cn(
              'px-4 py-2 rounded-md text-sm font-medium transition-colors flex items-center gap-2',
              activeTab === tab.id ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
            )}
          >
            {tab.label}
            {tab.count !== undefined && (
              <span className={cn(
                'text-xs px-1.5 py-0.5 rounded-full',
                activeTab === tab.id ? 'bg-accent/10 text-accent' : 'bg-surface text-muted'
              )}>
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'templates' && (
        <TemplatesTab
          templates={templates}
          search={search}
          setSearch={setSearch}
          onDelete={deleteTemplate}
          onDuplicate={duplicateTemplate}
          onGenerate={handleUseTemplate}
        />
      )}
      {activeTab === 'documents' && (
        <DocumentsTab
          renders={renders}
          search={search}
          setSearch={setSearch}
          onDelete={deleteRender}
          onSendForSignature={(renderId) => setShowSignatureModal(renderId)}
        />
      )}
      {activeTab === 'signatures' && (
        <SignaturesTab
          signatureRequests={signatureRequests}
          renders={renders}
          search={search}
          setSearch={setSearch}
        />
      )}

      {/* Modals */}
      {showCreateTemplateModal && (
        <CreateTemplateModal
          onClose={() => setShowCreateTemplateModal(false)}
          onCreate={createTemplate}
        />
      )}
      {showGenerateModal && (
        <GenerateDocumentModal
          templates={activeTemplates}
          preselectedTemplateId={preselectedTemplateId}
          onClose={() => {
            setShowGenerateModal(false);
            setPreselectedTemplateId(null);
          }}
          onGenerate={renderDocument}
        />
      )}
      {showSignatureModal && (
        <SendForSignatureModal
          renderId={showSignatureModal}
          onClose={() => setShowSignatureModal(null)}
          onSend={sendForSignature}
        />
      )}
    </div>
  );
}

// ==================== TEMPLATES TAB ====================

function TemplatesTab({
  templates,
  search,
  setSearch,
  onDelete,
  onDuplicate,
  onGenerate,
}: {
  templates: ZDocsTemplate[];
  search: string;
  setSearch: (v: string) => void;
  onDelete: (id: string) => Promise<void>;
  onDuplicate: (id: string) => Promise<string>;
  onGenerate: (templateId: string) => void;
}) {
  const { t: tr } = useTranslation();
  const [typeFilter, setTypeFilter] = useState('all');

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...ZDOCS_TEMPLATE_TYPES.map((t) => ({ value: t, label: ZDOCS_TEMPLATE_TYPE_LABELS[t] || t })),
  ];

  const filtered = useMemo(() => {
    return templates.filter((t) => {
      if (!t.isActive) return false;
      const matchesSearch =
        t.name.toLowerCase().includes(search.toLowerCase()) ||
        (t.description || '').toLowerCase().includes(search.toLowerCase());
      const matchesType = typeFilter === 'all' || t.templateType === typeFilter;
      return matchesSearch && matchesType;
    });
  }, [templates, search, typeFilter]);

  const handleDelete = async (id: string) => {
    try {
      await onDelete(id);
    } catch {
      // Real-time will refetch
    }
  };

  const handleDuplicate = async (id: string) => {
    try {
      await onDuplicate(id);
    } catch {
      // Real-time will refetch
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search templates..."
          className="sm:w-80"
        />
        <Select
          options={typeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((template) => {
          const typeConf = templateTypeConfig[template.templateType] || templateTypeConfig.other;
          const typeLabel = ZDOCS_TEMPLATE_TYPE_LABELS[template.templateType] || template.templateType;
          const varCount = template.variables.length;

          return (
            <Card key={template.id} className="group">
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1 min-w-0">
                    <h3 className="text-[15px] font-semibold text-main truncate">{template.name}</h3>
                    <div className="flex items-center gap-2 mt-1.5">
                      <Badge variant={typeConf.variant}>{typeLabel}</Badge>
                      {template.isSystem && <Badge variant="secondary">{tr('common.system')}</Badge>}
                    </div>
                  </div>
                  {template.requiresSignature && (
                    <div className="p-1 text-amber-500 shrink-0 ml-2" title="Requires Signature">
                      <PenTool size={14} />
                    </div>
                  )}
                </div>

                {template.description && (
                  <p className="text-sm text-muted mb-3 line-clamp-2">{template.description}</p>
                )}

                <div className="flex items-center gap-4 text-xs text-muted mb-4">
                  {varCount > 0 && (
                    <span className="flex items-center gap-1">
                      <Variable size={12} />
                      {varCount} variable{varCount !== 1 ? 's' : ''}
                    </span>
                  )}
                  <span className="flex items-center gap-1">
                    <Clock size={12} />
                    {formatDate(template.updatedAt)}
                  </span>
                </div>

                <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <Button
                    variant="primary"
                    size="sm"
                    onClick={() => onGenerate(template.id)}
                  >
                    <FileText size={14} />
                    Use Template
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleDuplicate(template.id)}
                    title={tr('common.duplicate')}
                  >
                    <Copy size={14} />
                  </Button>
                  {!template.isSystem && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDelete(template.id)}
                      title={tr('common.archive')}
                    >
                      <Trash2 size={14} />
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filtered.length === 0 && (
        <div className="text-center py-12 text-muted">
          <Layout size={40} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">{tr('common.noTemplatesFound')}</p>
        </div>
      )}
    </div>
  );
}

// ==================== DOCUMENTS TAB ====================

function DocumentsTab({
  renders,
  search,
  setSearch,
  onDelete,
  onSendForSignature,
}: {
  renders: ZDocsRender[];
  search: string;
  setSearch: (v: string) => void;
  onDelete: (id: string) => Promise<void>;
  onSendForSignature: (renderId: string) => void;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'draft', label: 'Draft' },
    { value: 'rendered', label: 'Rendered' },
    { value: 'sent', label: 'Sent' },
    { value: 'signed', label: 'Signed' },
  ];

  const filtered = useMemo(() => {
    return renders.filter((r) => {
      const matchesSearch =
        r.title.toLowerCase().includes(search.toLowerCase()) ||
        (r.templateName || '').toLowerCase().includes(search.toLowerCase()) ||
        (r.entityType || '').toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || r.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [renders, search, statusFilter]);

  const handleDelete = async (id: string) => {
    try {
      await onDelete(id);
    } catch {
      // Real-time will refetch
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder={t('documents.searchDocuments')}
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <Card>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.title')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.template')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('zdocs.entity')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.signature')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.created')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((render) => {
                const statusConf = renderStatusConfig[render.status] || renderStatusConfig.draft;
                const sigConf = render.signatureStatus ? signatureStatusConfig[render.signatureStatus] : null;
                const isExpanded = expandedId === render.id;

                return (
                  <tr key={render.id} className="border-b border-main/50">
                    <td className="px-6 py-4">
                      <button
                        className="text-left"
                        onClick={() => setExpandedId(isExpanded ? null : render.id)}
                      >
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-medium text-main">{render.title}</span>
                          {render.renderedHtml && (
                            isExpanded ? <ChevronUp size={14} className="text-muted" /> : <ChevronDown size={14} className="text-muted" />
                          )}
                        </div>
                      </button>
                      {isExpanded && render.renderedHtml && (
                        <div className="mt-3 border border-main rounded-lg overflow-hidden">
                          <div
                            className="p-4 bg-white text-black text-sm max-h-64 overflow-y-auto"
                            dangerouslySetInnerHTML={{ __html: sanitizeHtml(render.renderedHtml) }}
                          />
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-muted">{render.templateName || '-'}</td>
                    <td className="px-6 py-4 text-sm text-muted">
                      {render.entityType ? (
                        <Badge variant="secondary">
                          {ZDOCS_ENTITY_TYPE_LABELS[render.entityType] || render.entityType}
                        </Badge>
                      ) : (
                        <span>-</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <Badge variant={statusConf.variant} dot>{statusConf.label}</Badge>
                    </td>
                    <td className="px-6 py-4">
                      {sigConf ? (
                        <Badge variant={sigConf.variant} dot>{sigConf.label}</Badge>
                      ) : (
                        <span className="text-sm text-muted">-</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-muted">{formatDate(render.createdAt)}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setExpandedId(isExpanded ? null : render.id)}
                          title={t('common.preview')}
                        >
                          <Eye size={14} />
                        </Button>
                        {render.pdfStoragePath && (
                          <Button variant="ghost" size="sm" title={t('invoices.downloadPDF')}>
                            <Download size={14} />
                          </Button>
                        )}
                        {render.requiresSignature && render.signatureStatus !== 'signed' && (
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => onSendForSignature(render.id)}
                            title="Send for Signature"
                          >
                            <Send size={14} />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDelete(render.id)}
                          title={t('common.delete')}
                        >
                          <Trash2 size={14} />
                        </Button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          {filtered.length === 0 && (
            <div className="text-center py-12 text-muted">
              <FileText size={40} className="mx-auto mb-3 opacity-30" />
              <p className="text-sm">{t('zdocs.noGeneratedDocumentsFound')}</p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// ==================== SIGNATURES TAB ====================

function SignaturesTab({
  signatureRequests,
  renders,
  search,
  setSearch,
}: {
  signatureRequests: ZDocsSignatureRequest[];
  renders: ZDocsRender[];
  search: string;
  setSearch: (v: string) => void;
}) {
  const { t } = useTranslation();
  const [statusFilter, setStatusFilter] = useState('all');

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'sent', label: 'Sent' },
    { value: 'viewed', label: 'Viewed' },
    { value: 'signed', label: 'Signed' },
    { value: 'declined', label: 'Declined' },
    { value: 'expired', label: 'Expired' },
  ];

  const renderMap = useMemo(() => {
    const map: Record<string, ZDocsRender> = {};
    for (const r of renders) {
      map[r.id] = r;
    }
    return map;
  }, [renders]);

  const filtered = useMemo(() => {
    return signatureRequests.filter((sr) => {
      const render = renderMap[sr.renderId];
      const matchesSearch =
        sr.signerName.toLowerCase().includes(search.toLowerCase()) ||
        sr.signerEmail.toLowerCase().includes(search.toLowerCase()) ||
        (render?.title || '').toLowerCase().includes(search.toLowerCase());
      const matchesStatus = statusFilter === 'all' || sr.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [signatureRequests, search, statusFilter, renderMap]);

  const grouped = useMemo(() => {
    const groups: Record<string, ZDocsSignatureRequest[]> = {};
    for (const sr of filtered) {
      if (!groups[sr.renderId]) groups[sr.renderId] = [];
      groups[sr.renderId].push(sr);
    }
    return groups;
  }, [filtered]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search signatures..."
          className="sm:w-80"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      <div className="space-y-4">
        {Object.entries(grouped).map(([renderId, requests]) => {
          const render = renderMap[renderId];
          return (
            <Card key={renderId}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <FileSignature size={18} className="text-muted" />
                    <CardTitle>{render?.title || 'Unknown Document'}</CardTitle>
                  </div>
                  {render?.templateName && (
                    <Badge variant="secondary">{render.templateName}</Badge>
                  )}
                </div>
              </CardHeader>
              <CardContent className="p-0">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-main">
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('zdocs.signer')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.email')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.role')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.sent')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.signed')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {requests.map((req) => {
                      const sigConf = signatureStatusConfig[req.status] || signatureStatusConfig.pending;
                      return (
                        <tr key={req.id} className="border-b border-main/50 hover:bg-surface-hover">
                          <td className="px-6 py-4 text-sm font-medium text-main">{req.signerName}</td>
                          <td className="px-6 py-4 text-sm text-muted">{req.signerEmail}</td>
                          <td className="px-6 py-4 text-sm text-muted">{req.signerRole || '-'}</td>
                          <td className="px-6 py-4">
                            <Badge variant={sigConf.variant} dot>{sigConf.label}</Badge>
                          </td>
                          <td className="px-6 py-4 text-sm text-muted">
                            {req.sentAt ? formatDate(req.sentAt) : '-'}
                          </td>
                          <td className="px-6 py-4 text-sm text-muted">
                            {req.signedAt ? formatDate(req.signedAt) : '-'}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          );
        })}

        {Object.keys(grouped).length === 0 && (
          <div className="text-center py-12 text-muted">
            <FileSignature size={40} className="mx-auto mb-3 opacity-30" />
            <p className="text-sm">{t('zdocs.noSignatureRequestsFound')}</p>
          </div>
        )}
      </div>
    </div>
  );
}

// ==================== MODALS ====================

function CreateTemplateModal({
  onClose,
  onCreate,
}: {
  onClose: () => void;
  onCreate: (data: {
    name: string;
    description?: string;
    templateType: string;
    requiresSignature?: boolean;
  }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [templateType, setTemplateType] = useState('contract');
  const [requiresSignature, setRequiresSignature] = useState(false);
  const [saving, setSaving] = useState(false);

  const typeOptions = ZDOCS_TEMPLATE_TYPES.map((t) => ({
    value: t,
    label: ZDOCS_TEMPLATE_TYPE_LABELS[t] || t,
  }));

  const handleSubmit = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      await onCreate({
        name: name.trim(),
        description: description.trim() || undefined,
        templateType,
        requiresSignature,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create template');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <CardTitle>{t('common.createTemplate')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Template Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Standard Service Agreement"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
            />
          </div>
          <Select
            label="Template Type"
            options={typeOptions}
            value={templateType}
            onChange={(e) => setTemplateType(e.target.value)}
          />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.description')}</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Brief description of this template..."
              rows={3}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)] resize-none"
            />
          </div>
          <label className="flex items-center gap-3 cursor-pointer">
            <input
              type="checkbox"
              checked={requiresSignature}
              onChange={(e) => setRequiresSignature(e.target.checked)}
              className="w-4 h-4 rounded border-main text-emerald-600 focus:ring-emerald-500"
            />
            <span className="text-sm font-medium text-main">{t('zdocs.requiresSignature')}</span>
          </label>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !name.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Creating...' : 'Create Template'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function GenerateDocumentModal({
  templates,
  preselectedTemplateId,
  onClose,
  onGenerate,
}: {
  templates: ZDocsTemplate[];
  preselectedTemplateId?: string | null;
  onClose: () => void;
  onGenerate: (data: {
    templateId: string;
    entityType?: string;
    entityId?: string;
    title?: string;
    customVariables?: Record<string, unknown>;
  }) => Promise<string>;
}) {
  const { t: tr } = useTranslation();
  const [templateId, setTemplateId] = useState(preselectedTemplateId || templates[0]?.id || '');
  const [title, setTitle] = useState('');
  const [entityType, setEntityType] = useState('');
  const [entityId, setEntityId] = useState('');
  const [saving, setSaving] = useState(false);

  const templateOptions = templates.map((t) => ({
    value: t.id,
    label: `${t.name} (${ZDOCS_TEMPLATE_TYPE_LABELS[t.templateType] || t.templateType})`,
  }));

  const entityTypeOptions = [
    { value: '', label: 'None (standalone)' },
    ...ZDOCS_ENTITY_TYPES.map((t) => ({ value: t, label: ZDOCS_ENTITY_TYPE_LABELS[t] || t })),
  ];

  const selectedTemplate = templates.find((t) => t.id === templateId);

  const handleSubmit = async () => {
    if (!templateId) return;
    setSaving(true);
    try {
      await onGenerate({
        templateId,
        entityType: entityType || undefined,
        entityId: entityId.trim() || undefined,
        title: title.trim() || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to generate document');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{tr('zdocs.generateDocument')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {templateOptions.length > 0 ? (
            <Select
              label="Template *"
              options={templateOptions}
              value={templateId}
              onChange={(e) => setTemplateId(e.target.value)}
            />
          ) : (
            <p className="text-sm text-muted">{tr('zdocs.noActiveTemplatesCreateOneFirst')}</p>
          )}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{tr('zdocs.documentTitle')}</label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={selectedTemplate ? selectedTemplate.name : 'Custom title...'}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Select
              label="Link to Entity"
              options={entityTypeOptions}
              value={entityType}
              onChange={(e) => setEntityType(e.target.value)}
            />
            {entityType && (
              <div>
                <label className="block text-sm font-medium text-main mb-1.5">{tr('zdocs.entityId')}</label>
                <input
                  type="text"
                  value={entityId}
                  onChange={(e) => setEntityId(e.target.value)}
                  placeholder="Paste ID..."
                  className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
                />
              </div>
            )}
          </div>

          {/* Variable preview */}
          {selectedTemplate && selectedTemplate.variables.length > 0 && (
            <div>
              <h4 className="text-sm font-medium text-main mb-2">{tr('zdocs.templateVariables')}</h4>
              <div className="bg-secondary rounded-lg p-3 space-y-1.5">
                {selectedTemplate.variables.map((v) => (
                  <div key={v.name} className="flex items-center justify-between text-sm">
                    <span className="text-muted">{v.label || v.name}</span>
                    <span className="text-main font-mono text-xs">
                      {`{{${v.name}}}`}
                    </span>
                  </div>
                ))}
              </div>
              <p className="text-xs text-muted mt-1.5">{tr('zdocs.variablesWillBePopulatedFromLinkedEntityData')}</p>
            </div>
          )}

          {selectedTemplate?.requiresSignature && (
            <div className="flex items-center gap-2 text-sm text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/20 p-3 rounded-lg">
              <PenTool size={14} />
              <span>{tr('zdocs.thisTemplateRequiresASignatureAfterGeneration')}</span>
            </div>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !templateId}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <FileText size={16} />}
              {saving ? 'Generating...' : 'Generate'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function SendForSignatureModal({
  renderId,
  onClose,
  onSend,
}: {
  renderId: string;
  onClose: () => void;
  onSend: (renderId: string, signers: { name: string; email: string; role?: string }[]) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [signers, setSigners] = useState<{ name: string; email: string; role: string }[]>([
    { name: '', email: '', role: '' },
  ]);
  const [saving, setSaving] = useState(false);

  const addSigner = () => {
    setSigners([...signers, { name: '', email: '', role: '' }]);
  };

  const removeSigner = (index: number) => {
    setSigners(signers.filter((_, i) => i !== index));
  };

  const updateSigner = (index: number, field: 'name' | 'email' | 'role', value: string) => {
    const updated = [...signers];
    updated[index] = { ...updated[index], [field]: value };
    setSigners(updated);
  };

  const validSigners = signers.filter((s) => s.name.trim() && s.email.trim());

  const handleSubmit = async () => {
    if (validSigners.length === 0) return;
    setSaving(true);
    try {
      await onSend(
        renderId,
        validSigners.map((s) => ({
          name: s.name.trim(),
          email: s.email.trim(),
          role: s.role.trim() || undefined,
        }))
      );
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to send for signature');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{t('zdocs.sendForSignature')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted">{t('zdocs.addThePeopleWhoNeedToSignThisDocument')}</p>

          {signers.map((signer, index) => (
            <div key={index} className="bg-secondary rounded-lg p-4 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-main">Signer {index + 1}</span>
                {signers.length > 1 && (
                  <button
                    onClick={() => removeSigner(index)}
                    className="text-muted hover:text-red-500 transition-colors"
                  >
                    <X size={16} />
                  </button>
                )}
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Name *</label>
                  <input
                    type="text"
                    value={signer.name}
                    onChange={(e) => updateSigner(index, 'name', e.target.value)}
                    placeholder="John Smith"
                    className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Email *</label>
                  <input
                    type="email"
                    value={signer.email}
                    onChange={(e) => updateSigner(index, 'email', e.target.value)}
                    placeholder="john@example.com"
                    className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Role (optional)</label>
                <input
                  type="text"
                  value={signer.role}
                  onChange={(e) => updateSigner(index, 'role', e.target.value)}
                  placeholder="e.g. Homeowner, Contractor, Witness"
                  className="w-full px-3 py-2 bg-main border border-main rounded-lg text-main placeholder:text-muted text-sm focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]"
                />
              </div>
            </div>
          ))}

          <Button variant="outline" size="sm" onClick={addSigner}>
            <Plus size={14} />
            Add Another Signer
          </Button>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || validSigners.length === 0}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}
              {saving ? 'Sending...' : `Send to ${validSigners.length} signer${validSigners.length !== 1 ? 's' : ''}`}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
