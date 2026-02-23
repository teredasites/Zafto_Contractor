'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Plus,
  Play,
  Pause,
  Trash2,
  Edit3,
  ChevronDown,
  ChevronRight,
  RefreshCw,
  Calendar,
  Repeat,
  Clock,
  Zap,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, cn } from '@/lib/utils';
import {
  useRecurring,
  FREQUENCY_LABELS,
  TRANSACTION_TYPE_LABELS,
} from '@/lib/hooks/use-recurring';
import { useVendors } from '@/lib/hooks/use-vendors';
import type {
  RecurringTemplateData,
  GenerationHistoryItem,
  TransactionType,
  Frequency,
} from '@/lib/hooks/use-recurring';
import { useTranslation } from '@/lib/translations';

const zbooksNav = [
  { label: 'Overview', href: '/dashboard/books', active: false },
  { label: 'Banking', href: '/dashboard/books/banking', active: false },
  { label: 'Reports', href: '/dashboard/books/reports', active: false },
  { label: 'Recurring', href: '/dashboard/books/recurring', active: true },
];

type TemplateStatus = 'active' | 'paused' | 'ended';

const statusConfig: Record<TemplateStatus, { label: string; variant: 'success' | 'warning' | 'secondary' }> = {
  active: { label: 'Active', variant: 'success' },
  paused: { label: 'Paused', variant: 'warning' },
  ended: { label: 'Ended', variant: 'secondary' },
};

function getTemplateStatus(t: RecurringTemplateData): TemplateStatus {
  if (!t.isActive && t.endDate && t.nextOccurrence > t.endDate) return 'ended';
  if (!t.isActive) return 'paused';
  return 'active';
}

function isDueThisWeek(dateStr: string): boolean {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const nextWeek = new Date(today);
  nextWeek.setDate(nextWeek.getDate() + 7);
  const d = new Date(dateStr + 'T00:00:00');
  return d >= today && d < nextWeek;
}

// -------------------------------------------------------------------
// Template Row (expandable with generation history)
// -------------------------------------------------------------------
function TemplateRow({
  template,
  onGenerateNow,
  onPause,
  onResume,
  onEdit,
  onDelete,
  getHistory,
}: {
  template: RecurringTemplateData;
  onGenerateNow: (id: string) => Promise<void>;
  onPause: (id: string) => Promise<void>;
  onResume: (id: string) => Promise<void>;
  onEdit: (t: RecurringTemplateData) => void;
  onDelete: (id: string) => Promise<void>;
  getHistory: (id: string) => Promise<GenerationHistoryItem[]>;
}) {
  const [expanded, setExpanded] = useState(false);
  const [history, setHistory] = useState<GenerationHistoryItem[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(false);
  const [generating, setGenerating] = useState(false);

  const status = getTemplateStatus(template);
  const sc = statusConfig[status];
  const amount = Number(template.templateData.amount || 0);

  const handleExpand = async () => {
    if (!expanded) {
      setLoadingHistory(true);
      const items = await getHistory(template.id);
      setHistory(items);
      setLoadingHistory(false);
    }
    setExpanded(!expanded);
  };

  const handleGenerate = async () => {
    setGenerating(true);
    try {
      await onGenerateNow(template.id);
      // Refresh history if expanded
      if (expanded) {
        const items = await getHistory(template.id);
        setHistory(items);
      }
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="border-b border-default last:border-b-0">
      <div className="flex items-center gap-3 px-6 py-4 hover:bg-secondary/50 transition-colors">
        {/* Expand toggle */}
        <button onClick={handleExpand} className="text-muted hover:text-main transition-colors">
          {expanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
        </button>

        {/* Name + Description */}
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-main truncate">{template.templateName}</p>
          <p className="text-xs text-muted truncate">
            {(template.templateData.description as string) || ''}
          </p>
        </div>

        {/* Type */}
        <Badge variant={template.transactionType === 'expense' ? 'error' : 'info'}>
          {TRANSACTION_TYPE_LABELS[template.transactionType]}
        </Badge>

        {/* Frequency */}
        <span className="text-xs text-muted w-20 text-center">
          {FREQUENCY_LABELS[template.frequency]}
        </span>

        {/* Next occurrence */}
        <span className={cn(
          'text-xs tabular-nums w-24 text-center',
          isDueThisWeek(template.nextOccurrence) ? 'text-amber-600 font-medium' : 'text-muted'
        )}>
          {template.nextOccurrence}
        </span>

        {/* Amount */}
        <span className="text-sm font-medium text-main tabular-nums w-24 text-right">
          {formatCurrency(amount)}
        </span>

        {/* Status */}
        <div className="w-20 text-center">
          <Badge variant={sc.variant} size="sm">{sc.label}</Badge>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-1">
          <button
            onClick={handleGenerate}
            disabled={generating || status === 'ended'}
            className={cn(
              'p-1.5 rounded transition-colors',
              generating ? 'text-muted' : 'text-muted hover:text-accent'
            )}
            title="Generate Now"
          >
            {generating ? (
              <RefreshCw size={14} className="animate-spin" />
            ) : (
              <Zap size={14} />
            )}
          </button>
          {status === 'active' ? (
            <button
              onClick={() => onPause(template.id)}
              className="p-1.5 text-muted hover:text-amber-600 rounded transition-colors"
              title="Pause"
            >
              <Pause size={14} />
            </button>
          ) : status === 'paused' ? (
            <button
              onClick={() => onResume(template.id)}
              className="p-1.5 text-muted hover:text-emerald-600 rounded transition-colors"
              title="Resume"
            >
              <Play size={14} />
            </button>
          ) : null}
          <button
            onClick={() => onEdit(template)}
            className="p-1.5 text-muted hover:text-main rounded transition-colors"
            title="Edit"
          >
            <Edit3 size={14} />
          </button>
          <button
            onClick={() => onDelete(template.id)}
            className="p-1.5 text-muted hover:text-red-600 rounded transition-colors"
            title="Delete"
          >
            <Trash2 size={14} />
          </button>
        </div>
      </div>

      {/* Expanded history panel */}
      {expanded && (
        <div className="px-6 pb-4 pl-14 bg-secondary/30">
          <p className="text-xs font-medium text-muted uppercase tracking-wide mb-2">
            Generation History ({template.timesGenerated} total)
          </p>
          {loadingHistory ? (
            <div className="flex items-center gap-2 py-2 text-xs text-muted">
              <RefreshCw size={12} className="animate-spin" />
              Loading...
            </div>
          ) : history.length === 0 ? (
            <p className="text-xs text-muted py-2">No records generated yet.</p>
          ) : (
            <div className="space-y-1">
              {history.map((item) => (
                <div key={item.id} className="flex items-center gap-3 py-1.5 text-xs">
                  <span className="text-muted tabular-nums w-32">
                    {new Date(item.createdAt).toLocaleDateString()}
                  </span>
                  <Badge variant={item.type === 'expense' ? 'error' : 'info'} size="sm">
                    {item.type}
                  </Badge>
                  <span className="text-main truncate flex-1">{item.description}</span>
                  <span className="text-main font-medium tabular-nums">
                    {formatCurrency(item.amount)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// -------------------------------------------------------------------
// Template Modal (create / edit)
// -------------------------------------------------------------------
function TemplateModal({
  existing,
  vendors,
  onSave,
  onClose,
}: {
  existing: RecurringTemplateData | null;
  vendors: { id: string; vendorName: string }[];
  onSave: (data: {
    templateName: string;
    transactionType: TransactionType;
    frequency: Frequency;
    nextOccurrence: string;
    endDate?: string;
    templateData: Record<string, unknown>;
    accountId?: string;
    vendorId?: string;
  }) => Promise<void>;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const [templateName, setTemplateName] = useState(existing?.templateName || '');
  const [transactionType, setTransactionType] = useState<TransactionType>(
    existing?.transactionType || 'expense'
  );
  const [frequency, setFrequency] = useState<Frequency>(existing?.frequency || 'monthly');
  const [nextOccurrence, setNextOccurrence] = useState(
    existing?.nextOccurrence || new Date().toISOString().split('T')[0]
  );
  const [endDate, setEndDate] = useState(existing?.endDate || '');
  const [amount, setAmount] = useState(
    existing?.templateData.amount != null ? String(existing.templateData.amount) : ''
  );
  const [category, setCategory] = useState(
    (existing?.templateData.category as string) || 'materials'
  );
  const [description, setDescription] = useState(
    (existing?.templateData.description as string) || ''
  );
  const [vendorId, setVendorId] = useState(existing?.vendorId || '');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setErr(null);
    try {
      if (!templateName.trim()) throw new Error('Template name is required');
      if (!amount || Number(amount) <= 0) throw new Error('Amount must be positive');
      if (!nextOccurrence) throw new Error('Start date is required');

      await onSave({
        templateName: templateName.trim(),
        transactionType,
        frequency,
        nextOccurrence,
        endDate: endDate || undefined,
        templateData: {
          amount: Number(amount),
          category,
          description: description.trim(),
          vendor_id: vendorId || null,
        },
        vendorId: vendorId || undefined,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Save failed');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4" onClick={onClose}>
      <div
        className="bg-surface rounded-xl shadow-2xl w-full max-w-lg border border-main max-h-[85vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-6 py-4 border-b border-main">
          <h2 className="text-lg font-semibold text-main">
            {existing ? 'Edit Template' : 'New Recurring Template'}
          </h2>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {/* Name */}
          <div>
            <label className="block text-sm font-medium text-main mb-1">Template Name *</label>
            <input
              type="text"
              value={templateName}
              onChange={(e) => setTemplateName(e.target.value)}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              placeholder="e.g., Monthly Office Rent"
              required
            />
          </div>

          {/* Type + Frequency */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Type *</label>
              <select
                value={transactionType}
                onChange={(e) => setTransactionType(e.target.value as TransactionType)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="expense">Expense</option>
                <option value="invoice">{t('common.invoice')}</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">Frequency *</label>
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value as Frequency)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="weekly">{t('common.weekly')}</option>
                <option value="biweekly">Bi-Weekly</option>
                <option value="monthly">{t('common.monthly')}</option>
                <option value="quarterly">{t('common.quarterly')}</option>
                <option value="annually">Annually</option>
              </select>
            </div>
          </div>

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1">Start Date *</label>
              <input
                type="date"
                value={nextOccurrence}
                onChange={(e) => setNextOccurrence(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.endDate')}</label>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              />
            </div>
          </div>

          {/* Amount */}
          <div>
            <label className="block text-sm font-medium text-main mb-1">Amount *</label>
            <input
              type="number"
              step="0.01"
              min="0.01"
              value={amount}
              onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              required
            />
          </div>

          {/* Category (expense only) */}
          {transactionType === 'expense' && (
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.category')}</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="materials">{t('common.materials')}</option>
                <option value="labor">{t('common.labor')}</option>
                <option value="fuel">Fuel</option>
                <option value="tools">Tools</option>
                <option value="equipment">{t('common.equipment')}</option>
                <option value="vehicle">{t('common.vehicle')}</option>
                <option value="insurance">{t('common.insurance')}</option>
                <option value="permits">Permits</option>
                <option value="advertising">{t('common.advertising')}</option>
                <option value="office">Office</option>
                <option value="utilities">{t('common.utilities')}</option>
                <option value="subcontractor">Subcontractor</option>
                <option value="uncategorized">Uncategorized</option>
              </select>
            </div>
          )}

          {/* Vendor (expense only) */}
          {transactionType === 'expense' && (
            <div>
              <label className="block text-sm font-medium text-main mb-1">{t('common.vendor')}</label>
              <select
                value={vendorId}
                onChange={(e) => setVendorId(e.target.value)}
                className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm"
              >
                <option value="">{t('common.none')}</option>
                {vendors.filter((v) => v.vendorName).map((v) => (
                  <option key={v.id} value={v.id}>{v.vendorName}</option>
                ))}
              </select>
            </div>
          )}

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-main mb-1">{t('common.description')}</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={2}
              className="w-full px-3 py-2 rounded-lg border border-main bg-surface text-main text-sm resize-none"
              placeholder="Optional notes about this recurring transaction"
            />
          </div>

          {err && <p className="text-sm text-red-600">{err}</p>}

          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="secondary" onClick={onClose}>
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? 'Saving...' : existing ? 'Save Changes' : 'Create Template'}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

// -------------------------------------------------------------------
// Main Page
// -------------------------------------------------------------------
export default function RecurringPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const {
    templates,
    loading,
    error,
    createTemplate,
    updateTemplate,
    pauseTemplate,
    resumeTemplate,
    deleteTemplate,
    generateNow,
    getGenerationHistory,
  } = useRecurring();
  const { vendors } = useVendors();

  const [modalOpen, setModalOpen] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<RecurringTemplateData | null>(null);

  // Summary counts
  const activeCount = templates.filter((t) => t.isActive).length;
  const dueThisWeek = templates.filter((t) => t.isActive && isDueThisWeek(t.nextOccurrence)).length;
  const totalGenerated = templates.reduce((sum, t) => sum + t.timesGenerated, 0);

  const handleSave = async (data: {
    templateName: string;
    transactionType: TransactionType;
    frequency: Frequency;
    nextOccurrence: string;
    endDate?: string;
    templateData: Record<string, unknown>;
    accountId?: string;
    vendorId?: string;
  }) => {
    if (editingTemplate) {
      await updateTemplate(editingTemplate.id, data);
    } else {
      await createTemplate(data);
    }
    setModalOpen(false);
    setEditingTemplate(null);
  };

  const handleEdit = (t: RecurringTemplateData) => {
    setEditingTemplate(t);
    setModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this recurring template? This cannot be undone.')) return;
    await deleteTemplate(id);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="p-8 space-y-6 max-w-[1400px] mx-auto">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('booksRecurring.title')}</h1>
          <p className="text-muted mt-1">Automate repeating expenses and invoices</p>
        </div>
        <Button onClick={() => { setEditingTemplate(null); setModalOpen(true); }}>
          <Plus size={16} />
          New Template
        </Button>
      </div>

      {/* Ledger Navigation */}
      <div className="flex items-center gap-2">
        {zbooksNav.map((tab) => (
          <button
            key={tab.label}
            onClick={() => { if (!tab.active) router.push(tab.href); }}
            className={cn(
              'px-4 py-2 text-sm font-medium rounded-lg transition-colors',
              tab.active
                ? 'bg-accent text-white'
                : 'bg-secondary text-muted hover:text-main'
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                <Repeat size={20} className="text-emerald-500" />
              </div>
              <div>
                <p className="text-muted text-xs">{t('common.activeTemplates')}</p>
                <p className="text-xl font-bold text-main">{activeCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
                <Calendar size={20} className="text-amber-500" />
              </div>
              <div>
                <p className="text-muted text-xs">Due This Week</p>
                <p className="text-xl font-bold text-main">{dueThisWeek}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-accent/10 flex items-center justify-center">
                <Clock size={20} className="text-accent" />
              </div>
              <div>
                <p className="text-muted text-xs">Total Generated</p>
                <p className="text-xl font-bold text-main">{totalGenerated}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {error && (
        <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-red-700 dark:text-red-300 text-sm">
          {error}
        </div>
      )}

      {/* Templates List */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">{t('common.templates')}</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {/* Table header */}
          <div className="flex items-center gap-3 px-6 py-3 text-xs font-medium text-muted uppercase tracking-wide bg-secondary/50 border-b border-default">
            <div className="w-4" /> {/* expand spacer */}
            <div className="flex-1">{t('common.name')}</div>
            <div className="w-20 text-center">{t('common.type')}</div>
            <div className="w-20 text-center">{t('common.frequency')}</div>
            <div className="w-24 text-center">Next Due</div>
            <div className="w-24 text-right">{t('common.amount')}</div>
            <div className="w-20 text-center">{t('common.status')}</div>
            <div className="w-32" /> {/* actions spacer */}
          </div>

          {templates.length === 0 ? (
            <div className="px-6 py-12 text-center">
              <Repeat size={40} className="mx-auto text-muted mb-3" />
              <h3 className="text-sm font-medium text-main mb-1">No recurring templates</h3>
              <p className="text-xs text-muted mb-4">
                Create a template to automate repeating expenses or invoices.
              </p>
              <Button size="sm" onClick={() => { setEditingTemplate(null); setModalOpen(true); }}>
                <Plus size={14} />
                New Template
              </Button>
            </div>
          ) : (
            templates.map((t) => (
              <TemplateRow
                key={t.id}
                template={t}
                onGenerateNow={generateNow}
                onPause={pauseTemplate}
                onResume={resumeTemplate}
                onEdit={handleEdit}
                onDelete={handleDelete}
                getHistory={getGenerationHistory}
              />
            ))
          )}
        </CardContent>
      </Card>

      {/* Modal */}
      {modalOpen && (
        <TemplateModal
          existing={editingTemplate}
          vendors={vendors}
          onSave={handleSave}
          onClose={() => { setModalOpen(false); setEditingTemplate(null); }}
        />
      )}
    </div>
  );
}
