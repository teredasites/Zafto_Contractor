'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import { getSupabase } from '@/lib/supabase';
import {
  FileText,
  Download,
  Plus,
  PenTool,
  Clock,
  ChevronRight,
  Loader2,
  ArrowRight,
  Eye,
  X,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { formatDate } from '@/lib/utils';
import DOMPurify from 'dompurify';

// ============================================================
// EntityDocumentsPanel — Reusable document list for any entity
// Embed in job detail, customer detail, estimate detail, etc.
// Shows: linked ZDocs renders, quick generate button, doc chain
// ============================================================

type BadgeVariant = 'default' | 'secondary' | 'success' | 'warning' | 'error' | 'info' | 'purple';

const STATUS_CONFIG: Record<string, { label: string; variant: BadgeVariant }> = {
  draft: { label: 'Draft', variant: 'default' },
  rendered: { label: 'Rendered', variant: 'info' },
  sent: { label: 'Sent', variant: 'purple' },
  signed: { label: 'Signed', variant: 'success' },
};

const TYPE_LABELS: Record<string, string> = {
  contract: 'Contract',
  proposal: 'Proposal',
  lien_waiver: 'Lien Waiver',
  change_order: 'Change Order',
  invoice: 'Invoice',
  warranty: 'Warranty',
  scope_of_work: 'Scope of Work',
  safety_plan: 'Safety Plan',
  notice: 'Notice',
  insurance: 'Insurance',
  letter: 'Letter',
  completion_cert: 'Completion Certificate',
  other: 'Other',
};

interface EntityDocument {
  id: string;
  title: string;
  templateName: string | null;
  templateType: string | null;
  status: string;
  signatureStatus: string | null;
  pdfStoragePath: string | null;
  renderedHtml: string | null;
  createdAt: string;
}

// Chain order for visual document chain
const DOC_CHAIN_ORDER = [
  'proposal', 'contract', 'scope_of_work', 'change_order',
  'invoice', 'lien_waiver', 'warranty', 'completion_cert',
];

interface EntityDocumentsPanelProps {
  entityType: string; // 'job' | 'customer' | 'estimate' | 'invoice' | 'bid' | 'property'
  entityId: string;
  onGenerateDocument?: () => void; // Callback to open generate document modal
  compact?: boolean; // Compact mode for sidebars
}

export function EntityDocumentsPanel({
  entityType,
  entityId,
  onGenerateDocument,
  compact = false,
}: EntityDocumentsPanelProps) {
  const [documents, setDocuments] = useState<EntityDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [previewId, setPreviewId] = useState<string | null>(null);

  const fetchDocuments = useCallback(async () => {
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase
        .from('zdocs_renders')
        .select('id, title, status, signature_status, pdf_storage_path, rendered_html, created_at, document_templates(name, template_type)')
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setDocuments((data || []).map((row: Record<string, unknown>) => {
        const tpl = row.document_templates as Record<string, unknown> | null;
        return {
          id: row.id as string,
          title: (row.title as string) || '',
          templateName: tpl ? (tpl.name as string) : null,
          templateType: tpl ? (tpl.template_type as string) : null,
          status: (row.status as string) || 'draft',
          signatureStatus: row.signature_status as string | null,
          pdfStoragePath: row.pdf_storage_path as string | null,
          renderedHtml: row.rendered_html as string | null,
          createdAt: row.created_at as string,
        };
      }));
    } catch {
      // Silent fail — documents are supplementary
    } finally {
      setLoading(false);
    }
  }, [entityType, entityId]);

  useEffect(() => {
    fetchDocuments();
  }, [fetchDocuments]);

  const handleDownload = async (doc: EntityDocument) => {
    if (!doc.pdfStoragePath) return;
    try {
      const supabase = getSupabase();
      const { data, error } = await supabase.storage
        .from('documents')
        .createSignedUrl(doc.pdfStoragePath, 60 * 60);
      if (error || !data?.signedUrl) throw error;
      const a = document.createElement('a');
      a.href = data.signedUrl;
      a.download = `${doc.title.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    } catch {
      alert('Failed to download PDF');
    }
  };

  // Build document chain — sorted by template type in logical order
  const chainDocs = useMemo(() => {
    const sorted = [...documents].sort((a, b) => {
      const aIdx = DOC_CHAIN_ORDER.indexOf(a.templateType || '');
      const bIdx = DOC_CHAIN_ORDER.indexOf(b.templateType || '');
      return (aIdx === -1 ? 99 : aIdx) - (bIdx === -1 ? 99 : bIdx);
    });
    return sorted;
  }, [documents]);

  const previewDoc = previewId ? documents.find(d => d.id === previewId) : null;

  if (loading) {
    return (
      <Card>
        <CardContent className="p-6 flex items-center justify-center">
          <Loader2 className="h-5 w-5 animate-spin text-muted" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <FileText size={18} className="text-muted" />
            <CardTitle className={compact ? 'text-sm' : ''}>
              Documents ({documents.length})
            </CardTitle>
          </div>
          {onGenerateDocument && (
            <Button variant="secondary" size="sm" onClick={onGenerateDocument}>
              <Plus size={14} />
              Generate
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent className="p-0">
        {documents.length === 0 ? (
          <div className="text-center py-8 text-muted text-sm">
            <FileText size={32} className="mx-auto mb-2 opacity-30" />
            <p>No documents linked to this {entityType}</p>
            {onGenerateDocument && (
              <Button variant="secondary" size="sm" className="mt-3" onClick={onGenerateDocument}>
                <Plus size={14} />
                Generate First Document
              </Button>
            )}
          </div>
        ) : (
          <>
            {/* Document chain visualization */}
            {chainDocs.length > 1 && !compact && (
              <div className="px-5 py-3 border-b border-main/50">
                <p className="text-xs font-medium text-muted mb-2">Document Chain</p>
                <div className="flex items-center gap-1 flex-wrap">
                  {chainDocs.map((doc, idx) => {
                    const statusConf = STATUS_CONFIG[doc.status] || STATUS_CONFIG.draft;
                    return (
                      <div key={doc.id} className="flex items-center gap-1">
                        <Badge variant={statusConf.variant} className="text-[10px] px-1.5 py-0.5">
                          {TYPE_LABELS[doc.templateType || ''] || doc.title}
                        </Badge>
                        {idx < chainDocs.length - 1 && (
                          <ArrowRight size={12} className="text-muted shrink-0" />
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Document list */}
            <div className="divide-y divide-main/50">
              {documents.map((doc) => {
                const statusConf = STATUS_CONFIG[doc.status] || STATUS_CONFIG.draft;
                return (
                  <div key={doc.id} className="px-5 py-3 flex items-center justify-between hover:bg-surface-hover transition-colors">
                    <div className="flex items-center gap-3 min-w-0 flex-1">
                      <FileText size={16} className="text-muted shrink-0" />
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-main truncate">{doc.title}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          {doc.templateType && (
                            <span className="text-xs text-muted">{TYPE_LABELS[doc.templateType] || doc.templateType}</span>
                          )}
                          <Badge variant={statusConf.variant} className="text-[10px]">{statusConf.label}</Badge>
                          {doc.signatureStatus === 'signed' && (
                            <span className="flex items-center gap-0.5 text-[10px] text-emerald-600">
                              <PenTool size={10} />
                              Signed
                            </span>
                          )}
                          {doc.pdfStoragePath && (
                            <Badge variant="success" className="text-[10px]">PDF</Badge>
                          )}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0 ml-2">
                      <span className="text-xs text-muted flex items-center gap-1">
                        <Clock size={10} />
                        {formatDate(doc.createdAt)}
                      </span>
                      {doc.renderedHtml && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setPreviewId(previewId === doc.id ? null : doc.id)}
                          title="Preview"
                        >
                          <Eye size={14} />
                        </Button>
                      )}
                      {doc.pdfStoragePath && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDownload(doc)}
                          title="Download PDF"
                        >
                          <Download size={14} />
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Inline preview */}
            {previewDoc?.renderedHtml && (
              <div className="border-t border-main">
                <div className="flex items-center justify-between px-5 py-2 bg-secondary">
                  <span className="text-xs font-medium text-muted">Preview: {previewDoc.title}</span>
                  <button onClick={() => setPreviewId(null)} className="text-muted hover:text-main">
                    <X size={14} />
                  </button>
                </div>
                <div
                  className="p-5 bg-white text-black text-sm max-h-64 overflow-y-auto"
                  dangerouslySetInnerHTML={{
                    __html: DOMPurify.sanitize(previewDoc.renderedHtml, {
                      ALLOWED_TAGS: ['p', 'br', 'b', 'i', 'u', 'strong', 'em', 'h1', 'h2', 'h3', 'h4',
                        'ul', 'ol', 'li', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'div', 'span', 'hr'],
                      ALLOWED_ATTR: ['class', 'style'],
                    }),
                  }}
                />
              </div>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}
