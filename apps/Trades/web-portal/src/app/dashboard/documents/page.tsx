'use client';

import { useState, useMemo } from 'react';
import {
  FileText,
  Image,
  File,
  Folder,
  FolderOpen,
  Upload,
  Download,
  Trash2,
  X,
  Eye,
  Grid,
  List,
  ChevronRight,
  ChevronDown,
  PenTool,
  Clock,
  FileSpreadsheet,
  FileImage,
  FilePlus,
  LayoutTemplate,
  Plus,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import {
  useDocuments,
  DOCUMENT_TYPES,
  DOCUMENT_TYPE_LABELS,
  TEMPLATE_TYPE_LABELS,
  type DocumentFolder,
  type DocumentData,
} from '@/lib/hooks/use-documents';
import { useTranslation } from '@/lib/translations';

const typeFilterOptions = [
  { value: 'all', label: 'All Types' },
  ...DOCUMENT_TYPES.map((t) => ({ value: t, label: DOCUMENT_TYPE_LABELS[t] || t })),
];

const signatureVariant: Record<string, 'warning' | 'info' | 'success' | 'error' | 'default'> = {
  pending: 'warning',
  sent: 'info',
  signed: 'success',
  declined: 'error',
  expired: 'default',
};

function formatSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function getFileIcon(fileType: string, size = 24) {
  switch (fileType) {
    case 'pdf': return <FileText size={size} className="text-red-500" />;
    case 'image': return <FileImage size={size} className="text-blue-500" />;
    case 'xlsx':
    case 'xls':
    case 'csv': return <FileSpreadsheet size={size} className="text-emerald-500" />;
    case 'docx':
    case 'doc': return <FileText size={size} className="text-blue-600" />;
    default: return <File size={size} className="text-muted" />;
  }
}

function getDocTypeBadgeVariant(docType: string): 'default' | 'info' | 'success' | 'warning' | 'purple' | 'error' | 'secondary' {
  const map: Record<string, 'default' | 'info' | 'success' | 'warning' | 'purple' | 'error' | 'secondary'> = {
    contract: 'purple',
    proposal: 'info',
    permit: 'warning',
    insurance_cert: 'success',
    lien_waiver: 'error',
    invoice: 'info',
    photo: 'default',
    plan: 'purple',
  };
  return map[docType] || 'secondary';
}

// Build folder tree from flat list
function buildFolderTree(folders: DocumentFolder[]): (DocumentFolder & { children: DocumentFolder[] })[] {
  const map = new Map<string, DocumentFolder & { children: DocumentFolder[] }>();
  const roots: (DocumentFolder & { children: DocumentFolder[] })[] = [];

  for (const f of folders) {
    map.set(f.id, { ...f, children: [] });
  }

  for (const f of folders) {
    const node = map.get(f.id)!;
    if (f.parentId && map.has(f.parentId)) {
      map.get(f.parentId)!.children.push(node);
    } else {
      roots.push(node);
    }
  }

  return roots;
}

export default function DocumentsPage() {
  const { t } = useTranslation();
  const {
    documents,
    folders,
    templates,
    loading,
    error,
    totalDocuments,
    recentlyUploaded,
    pendingSignatures,
    archiveDocument,
  } = useDocuments();

  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('list');
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedFolderId, setSelectedFolderId] = useState<string | null>(null);
  const [showSidebar, setShowSidebar] = useState(true);
  const [showTemplates, setShowTemplates] = useState(false);

  const folderTree = useMemo(() => buildFolderTree(folders), [folders]);

  const filteredDocs = useMemo(() => {
    return documents.filter((doc) => {
      const matchesSearch =
        doc.name.toLowerCase().includes(search.toLowerCase()) ||
        doc.jobTitle?.toLowerCase().includes(search.toLowerCase()) ||
        doc.customerName?.toLowerCase().includes(search.toLowerCase()) ||
        doc.description?.toLowerCase().includes(search.toLowerCase());
      const matchesType = typeFilter === 'all' || doc.documentType === typeFilter;
      const matchesFolder = !selectedFolderId || doc.folderId === selectedFolderId;
      return matchesSearch && matchesType && matchesFolder;
    });
  }, [documents, search, typeFilter, selectedFolderId]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-8 text-center">
        <p className="text-red-500 mb-4">{error}</p>
        <Button variant="secondary" onClick={() => window.location.reload()}>{t('common.retry')}</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('documents.title')}</h1>
          <p className="text-muted mt-1">Manage files, contracts, and attachments</p>
        </div>
        <Button onClick={() => setShowUploadModal(true)}>
          <Upload size={16} />
          Upload
        </Button>
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
                <p className="text-2xl font-semibold text-main">{totalDocuments}</p>
                <p className="text-sm text-muted">Total Documents</p>
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
                <p className="text-sm text-muted">Pending Signatures</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Clock size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{recentlyUploaded.length}</p>
                <p className="text-sm text-muted">Uploaded (7d)</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <LayoutTemplate size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{templates.length}</p>
                <p className="text-sm text-muted">Templates</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div className="flex flex-col sm:flex-row gap-4">
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Search documents..."
            className="sm:w-80"
          />
          <Select
            options={typeFilterOptions}
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="sm:w-48"
          />
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant={showSidebar ? 'secondary' : 'ghost'}
            size="sm"
            onClick={() => setShowSidebar(!showSidebar)}
          >
            <Folder size={16} />
            Folders
          </Button>
          <div className="flex items-center p-1 bg-secondary rounded-lg">
            <button
              onClick={() => setViewMode('grid')}
              className={cn(
                'p-2 rounded-md transition-colors',
                viewMode === 'grid' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <Grid size={18} />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={cn(
                'p-2 rounded-md transition-colors',
                viewMode === 'list' ? 'bg-surface shadow-sm text-main' : 'text-muted hover:text-main'
              )}
            >
              <List size={18} />
            </button>
          </div>
        </div>
      </div>

      {/* Main content area with sidebar */}
      <div className="flex gap-6">
        {/* Folder Sidebar */}
        {showSidebar && (
          <div className="w-64 flex-shrink-0">
            <Card>
              <CardHeader>
                <CardTitle>Folders</CardTitle>
              </CardHeader>
              <CardContent className="p-2">
                <button
                  onClick={() => setSelectedFolderId(null)}
                  className={cn(
                    'w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-colors',
                    !selectedFolderId
                      ? 'bg-accent-light text-accent font-medium'
                      : 'text-muted hover:text-main hover:bg-surface-hover'
                  )}
                >
                  <Folder size={16} />
                  All Documents
                </button>
                {folderTree.map((folder) => (
                  <FolderTreeItem
                    key={folder.id}
                    folder={folder}
                    selectedId={selectedFolderId}
                    onSelect={setSelectedFolderId}
                    depth={0}
                  />
                ))}
                {folders.length === 0 && (
                  <p className="text-xs text-muted px-3 py-4 text-center">No folders yet</p>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {/* Documents View */}
        <div className="flex-1 min-w-0">
          {filteredDocs.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <FileText size={40} className="mx-auto mb-2 opacity-50 text-muted" />
                <p className="text-muted">{t('documents.noRecords')}</p>
                <Button variant="secondary" className="mt-4" onClick={() => setShowUploadModal(true)}>
                  <Upload size={16} />
                  Upload First Document
                </Button>
              </CardContent>
            </Card>
          ) : viewMode === 'grid' ? (
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {filteredDocs.map((doc) => (
                <DocumentGridCard key={doc.id} doc={doc} onArchive={archiveDocument} />
              ))}
            </div>
          ) : (
            <Card>
              <CardContent className="p-0">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-main">
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.name')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.job')}</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">Size</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">Uploaded</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3">Signature</th>
                      <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredDocs.map((doc) => (
                      <DocumentListRow key={doc.id} doc={doc} onArchive={archiveDocument} />
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Templates Section */}
      <Card>
        <CardHeader
          onClick={() => setShowTemplates(!showTemplates)}
          className="cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <LayoutTemplate size={18} className="text-muted" />
              <CardTitle>Document Templates</CardTitle>
              <Badge variant="secondary" size="sm">{templates.length}</Badge>
            </div>
            {showTemplates ? <ChevronDown size={18} className="text-muted" /> : <ChevronRight size={18} className="text-muted" />}
          </div>
        </CardHeader>
        {showTemplates && (
          <CardContent>
            {templates.length === 0 ? (
              <p className="text-muted text-sm text-center py-4">No templates created yet</p>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {templates.map((tmpl) => (
                  <div
                    key={tmpl.id}
                    className="p-4 border border-main rounded-lg hover:bg-surface-hover transition-colors"
                  >
                    <div className="flex items-start gap-3">
                      <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                        <LayoutTemplate size={18} className="text-purple-600 dark:text-purple-400" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-main truncate">{tmpl.name}</p>
                        <p className="text-xs text-muted mt-0.5">
                          {TEMPLATE_TYPE_LABELS[tmpl.templateType] || tmpl.templateType}
                        </p>
                        {tmpl.description && (
                          <p className="text-xs text-muted mt-1 line-clamp-2">{tmpl.description}</p>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-2 mt-3">
                      {tmpl.requiresSignature && (
                        <Badge variant="warning" size="sm">
                          <PenTool size={10} />
                          Signature
                        </Badge>
                      )}
                      {tmpl.isSystem && (
                        <Badge variant="info" size="sm">System</Badge>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        )}
      </Card>

      {/* Upload Modal */}
      {showUploadModal && (
        <UploadModal
          folders={folders}
          onClose={() => setShowUploadModal(false)}
        />
      )}
    </div>
  );
}

// Folder tree item component
function FolderTreeItem({
  folder,
  selectedId,
  onSelect,
  depth,
}: {
  folder: DocumentFolder & { children: DocumentFolder[] };
  selectedId: string | null;
  onSelect: (id: string | null) => void;
  depth: number;
}) {
  const [isOpen, setIsOpen] = useState(false);
  const hasChildren = (folder as DocumentFolder & { children: DocumentFolder[] }).children?.length > 0;
  const isSelected = selectedId === folder.id;

  return (
    <div>
      <button
        onClick={() => {
          onSelect(folder.id);
          if (hasChildren) setIsOpen(!isOpen);
        }}
        className={cn(
          'w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition-colors',
          isSelected
            ? 'bg-accent-light text-accent font-medium'
            : 'text-muted hover:text-main hover:bg-surface-hover'
        )}
        style={{ paddingLeft: `${12 + depth * 16}px` }}
      >
        {hasChildren ? (
          isOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />
        ) : (
          <span className="w-3.5" />
        )}
        {isOpen ? <FolderOpen size={16} /> : <Folder size={16} />}
        <span className="truncate">{folder.name}</span>
      </button>
      {isOpen && hasChildren && (
        <div>
          {(folder as DocumentFolder & { children: DocumentFolder[] }).children.map((child) => (
            <FolderTreeItem
              key={child.id}
              folder={child as DocumentFolder & { children: DocumentFolder[] }}
              selectedId={selectedId}
              onSelect={onSelect}
              depth={depth + 1}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// Document grid card
function DocumentGridCard({ doc, onArchive }: { doc: DocumentData; onArchive: (id: string) => void }) {
  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer group">
      <CardContent className="p-4">
        <div className="flex flex-col items-center text-center">
          <div className="p-4 bg-secondary rounded-lg mb-3 group-hover:bg-surface-hover transition-colors">
            {getFileIcon(doc.fileType)}
          </div>
          <p className="font-medium text-main text-sm truncate w-full" title={doc.name}>
            {doc.name}
          </p>
          <p className="text-xs text-muted mt-0.5">{formatSize(doc.fileSizeBytes)}</p>
          <Badge variant={getDocTypeBadgeVariant(doc.documentType)} size="sm" className="mt-1.5">
            {DOCUMENT_TYPE_LABELS[doc.documentType] || doc.documentType}
          </Badge>
          {doc.requiresSignature && doc.signatureStatus && (
            <Badge variant={signatureVariant[doc.signatureStatus] || 'default'} size="sm" className="mt-1">
              <PenTool size={10} />
              {doc.signatureStatus}
            </Badge>
          )}
          {doc.jobTitle && (
            <p className="text-xs text-muted truncate w-full mt-1">{doc.jobTitle}</p>
          )}
        </div>
        <div className="flex items-center justify-center gap-1 mt-3 pt-3 border-t border-main opacity-0 group-hover:opacity-100 transition-opacity">
          <button className="p-1.5 hover:bg-surface-hover rounded-lg">
            <Eye size={14} className="text-muted" />
          </button>
          <button className="p-1.5 hover:bg-surface-hover rounded-lg">
            <Download size={14} className="text-muted" />
          </button>
          <button
            className="p-1.5 hover:bg-red-100 dark:hover:bg-red-900/30 rounded-lg"
            onClick={(e) => { e.stopPropagation(); onArchive(doc.id); }}
          >
            <Trash2 size={14} className="text-red-500" />
          </button>
        </div>
      </CardContent>
    </Card>
  );
}

// Document list row
function DocumentListRow({ doc, onArchive }: { doc: DocumentData; onArchive: (id: string) => void }) {
  return (
    <tr className="border-b border-main/50 hover:bg-surface-hover">
      <td className="px-6 py-3">
        <div className="flex items-center gap-3">
          {getFileIcon(doc.fileType, 20)}
          <div className="min-w-0">
            <span className="font-medium text-main block truncate">{doc.name}</span>
            {doc.customerName && (
              <span className="text-xs text-muted">{doc.customerName}</span>
            )}
          </div>
        </div>
      </td>
      <td className="px-6 py-3">
        <Badge variant={getDocTypeBadgeVariant(doc.documentType)} size="sm">
          {DOCUMENT_TYPE_LABELS[doc.documentType] || doc.documentType}
        </Badge>
      </td>
      <td className="px-6 py-3 text-sm text-muted">
        {doc.jobTitle || '-'}
      </td>
      <td className="px-6 py-3 text-sm text-muted">{formatSize(doc.fileSizeBytes)}</td>
      <td className="px-6 py-3 text-sm text-muted">{formatDate(doc.createdAt)}</td>
      <td className="px-6 py-3">
        {doc.requiresSignature && doc.signatureStatus ? (
          <Badge variant={signatureVariant[doc.signatureStatus] || 'default'} size="sm">
            <PenTool size={10} />
            {doc.signatureStatus}
          </Badge>
        ) : (
          <span className="text-sm text-muted">-</span>
        )}
      </td>
      <td className="px-6 py-3">
        <div className="flex items-center gap-1">
          <button className="p-1.5 hover:bg-surface-hover rounded-lg">
            <Download size={16} className="text-muted" />
          </button>
          <button
            className="p-1.5 hover:bg-red-100 dark:hover:bg-red-900/30 rounded-lg"
            onClick={() => onArchive(doc.id)}
          >
            <Trash2 size={16} className="text-red-500" />
          </button>
        </div>
      </td>
    </tr>
  );
}

// Upload modal
function UploadModal({
  folders,
  onClose,
}: {
  folders: DocumentFolder[];
  onClose: () => void;
}) {
  const [isDragging, setIsDragging] = useState(false);
  const [docName, setDocName] = useState('');
  const [docType, setDocType] = useState('general');
  const [folderId, setFolderId] = useState('');

  const folderOptions = [
    { value: '', label: 'No Folder' },
    ...folders.map((f) => ({ value: f.id, label: f.name })),
  ];

  const docTypeOptions = DOCUMENT_TYPES.map((t) => ({
    value: t,
    label: DOCUMENT_TYPE_LABELS[t] || t,
  }));

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Upload Document</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Drop Zone */}
          <div
            onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
            onDragLeave={() => setIsDragging(false)}
            onDrop={(e) => { e.preventDefault(); setIsDragging(false); }}
            className={cn(
              'border-2 border-dashed rounded-xl p-8 text-center transition-all cursor-pointer',
              isDragging ? 'border-accent bg-accent-light' : 'border-main hover:border-accent'
            )}
          >
            <Upload size={40} className={cn('mx-auto mb-3', isDragging ? 'text-accent' : 'text-muted')} />
            <p className="font-medium text-main mb-1">Drop files here or click to browse</p>
            <p className="text-sm text-muted">PDF, Images, Documents up to 25MB</p>
          </div>

          <Input
            label="Document Name"
            placeholder="e.g. Service Agreement - Martinez"
            value={docName}
            onChange={(e) => setDocName(e.target.value)}
          />

          <Select
            label="Document Type"
            options={docTypeOptions}
            value={docType}
            onChange={(e) => setDocType(e.target.value)}
          />

          <Select
            label="Folder"
            options={folderOptions}
            value={folderId}
            onChange={(e) => setFolderId(e.target.value)}
          />

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1">
              <Upload size={16} />
              Upload
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
