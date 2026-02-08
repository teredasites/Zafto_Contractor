'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowLeft, FileText, Download, Search, Upload, Shield, BookOpen, Receipt,
  ClipboardCheck, File, Loader2, X, ChevronDown, Trash2, Link2,
} from 'lucide-react';
import { useHomeDocuments, type DocumentType } from '@/lib/hooks/use-home-documents';
import { useHome } from '@/lib/hooks/use-home';

const typeConfig: Record<DocumentType, { label: string; icon: typeof FileText; color: string; bg: string }> = {
  warranty:   { label: 'Warranty',    icon: Shield,         color: 'text-amber-700',  bg: 'bg-amber-50' },
  manual:     { label: 'Manual',      icon: BookOpen,       color: 'text-blue-700',   bg: 'bg-blue-50' },
  permit:     { label: 'Permit',      icon: ClipboardCheck, color: 'text-green-700',  bg: 'bg-green-50' },
  receipt:    { label: 'Receipt',     icon: Receipt,        color: 'text-purple-700', bg: 'bg-purple-50' },
  inspection: { label: 'Inspection',  icon: ClipboardCheck, color: 'text-cyan-700',   bg: 'bg-cyan-50' },
  other:      { label: 'Other',       icon: File,           color: 'text-gray-700',   bg: 'bg-gray-100' },
};

const ALL_DOC_TYPES: DocumentType[] = ['warranty', 'manual', 'permit', 'receipt', 'inspection', 'other'];

export default function HomeDocumentsPage() {
  const { documents, equipmentOptions, loading, uploading, uploadDocument, deleteDocument, formatFileSize } = useHomeDocuments();
  const { primaryProperty } = useHome();
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<'all' | DocumentType>('all');
  const [showUpload, setShowUpload] = useState(false);
  const [deleting, setDeleting] = useState<string | null>(null);

  // Upload form state
  const [uploadName, setUploadName] = useState('');
  const [uploadType, setUploadType] = useState<DocumentType>('other');
  const [uploadEquipmentId, setUploadEquipmentId] = useState('');
  const [uploadDescription, setUploadDescription] = useState('');
  const [uploadExpiry, setUploadExpiry] = useState('');
  const [uploadFile, setUploadFile] = useState<File | null>(null);

  const filtered = documents.filter(d => {
    if (filterType !== 'all' && d.documentType !== filterType) return false;
    if (search && !d.name.toLowerCase().includes(search.toLowerCase()) &&
        !(d.description && d.description.toLowerCase().includes(search.toLowerCase()))) return false;
    return true;
  });

  const handleUpload = async () => {
    if (!uploadFile || !uploadName || !primaryProperty) return;
    try {
      await uploadDocument({
        propertyId: primaryProperty.id,
        equipmentId: uploadEquipmentId || undefined,
        name: uploadName,
        documentType: uploadType,
        description: uploadDescription || undefined,
        expiryDate: uploadExpiry || undefined,
        file: uploadFile,
      });
      // Reset form
      setUploadName('');
      setUploadType('other');
      setUploadEquipmentId('');
      setUploadDescription('');
      setUploadExpiry('');
      setUploadFile(null);
      setShowUpload(false);
    } catch {
      // Error handled by hook
    }
  };

  const handleDelete = async (id: string) => {
    setDeleting(id);
    try {
      await deleteDocument(id);
    } catch {
      // Error handled by hook
    } finally {
      setDeleting(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 size={24} className="animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Header */}
      <div>
        <Link href="/my-home" className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-3">
          <ArrowLeft size={16} /> Back to My Home
        </Link>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">Home Documents</h1>
            <p className="text-sm text-gray-500 mt-0.5">{documents.length} files stored</p>
          </div>
          <button
            onClick={() => setShowUpload(!showUpload)}
            className="flex items-center gap-1.5 px-3 py-2 bg-orange-500 text-white rounded-lg text-sm font-medium hover:bg-orange-600 transition-colors"
          >
            <Upload size={16} /> Upload
          </button>
        </div>
      </div>

      {/* Upload Form */}
      {showUpload && (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-bold text-sm text-gray-900">Upload Document</h3>
            <button onClick={() => setShowUpload(false)} className="p-1 text-gray-400 hover:text-gray-600">
              <X size={16} />
            </button>
          </div>

          <div className="space-y-3">
            {/* Title */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Document Title *</label>
              <input
                value={uploadName}
                onChange={e => setUploadName(e.target.value)}
                placeholder="e.g. HVAC Warranty Certificate"
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm"
              />
            </div>

            {/* Type */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Document Type</label>
              <div className="relative">
                <select
                  value={uploadType}
                  onChange={e => setUploadType(e.target.value as DocumentType)}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm bg-white appearance-none"
                >
                  {ALL_DOC_TYPES.map(t => (
                    <option key={t} value={t}>{typeConfig[t].label}</option>
                  ))}
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>

            {/* Link to Equipment */}
            {equipmentOptions.length > 0 && (
              <div>
                <label className="block text-xs text-gray-500 mb-1">
                  <Link2 size={10} className="inline mr-1" />
                  Link to Equipment (optional)
                </label>
                <div className="relative">
                  <select
                    value={uploadEquipmentId}
                    onChange={e => setUploadEquipmentId(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm bg-white appearance-none"
                  >
                    <option value="">None</option>
                    {equipmentOptions.map(eq => (
                      <option key={eq.id} value={eq.id}>{eq.name} ({eq.category})</option>
                    ))}
                  </select>
                  <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                </div>
              </div>
            )}

            {/* Description */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">Description (optional)</label>
              <textarea
                value={uploadDescription}
                onChange={e => setUploadDescription(e.target.value)}
                placeholder="Brief description of this document..."
                rows={2}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm resize-none"
              />
            </div>

            {/* Expiry Date */}
            {(uploadType === 'warranty' || uploadType === 'permit') && (
              <div>
                <label className="block text-xs text-gray-500 mb-1">Expiry Date (optional)</label>
                <input
                  type="date"
                  value={uploadExpiry}
                  onChange={e => setUploadExpiry(e.target.value)}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 outline-none text-sm"
                />
              </div>
            )}

            {/* File */}
            <div>
              <label className="block text-xs text-gray-500 mb-1">File *</label>
              {uploadFile ? (
                <div className="flex items-center gap-2 px-3 py-2.5 bg-gray-50 rounded-xl border border-gray-200">
                  <File size={14} className="text-gray-400" />
                  <span className="text-sm text-gray-700 flex-1 truncate">{uploadFile.name}</span>
                  <span className="text-xs text-gray-400">{formatFileSize(uploadFile.size)}</span>
                  <button onClick={() => setUploadFile(null)} className="p-0.5 text-gray-400 hover:text-gray-600">
                    <X size={12} />
                  </button>
                </div>
              ) : (
                <label className="flex flex-col items-center justify-center py-6 border-2 border-dashed border-gray-200 rounded-xl cursor-pointer hover:border-orange-300 transition-colors">
                  <Upload size={20} className="text-gray-400 mb-1" />
                  <span className="text-xs text-gray-500">Tap to select file</span>
                  <input
                    type="file"
                    className="hidden"
                    accept=".pdf,.jpg,.jpeg,.png,.doc,.docx,.xls,.xlsx,.txt"
                    onChange={e => setUploadFile(e.target.files?.[0] || null)}
                  />
                </label>
              )}
            </div>

            {/* Submit */}
            <button
              onClick={handleUpload}
              disabled={!uploadFile || !uploadName || uploading}
              className="w-full py-3 bg-orange-500 text-white rounded-xl text-sm font-bold hover:bg-orange-600 transition-colors disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {uploading ? <><Loader2 size={16} className="animate-spin" /> Uploading...</> : 'Upload Document'}
            </button>
          </div>
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Search documents..."
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm"
        />
      </div>

      {/* Type Filters */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {(['all', ...ALL_DOC_TYPES] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilterType(f)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${
              filterType === f ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'
            }`}
          >
            {f === 'all' ? 'All' : typeConfig[f].label}
          </button>
        ))}
      </div>

      {/* Document List */}
      {filtered.length === 0 ? (
        <div className="bg-white rounded-xl border border-gray-100 shadow-sm p-8 text-center">
          <FileText size={32} className="mx-auto text-gray-300 mb-2" />
          <p className="text-sm text-gray-500">
            {documents.length === 0 ? 'No documents uploaded yet' : 'No documents match your filters'}
          </p>
          {documents.length === 0 && (
            <button
              onClick={() => setShowUpload(true)}
              className="mt-3 text-sm text-orange-500 font-medium hover:text-orange-600"
            >
              Upload your first document
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map(doc => {
            const config = typeConfig[doc.documentType] || typeConfig.other;
            const Icon = config.icon;
            const equipment = equipmentOptions.find(e => e.id === doc.equipmentId);
            const isExpired = doc.expiryDate && new Date(doc.expiryDate) < new Date();
            const isExpiringSoon = doc.expiryDate && !isExpired &&
              new Date(doc.expiryDate) < new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);

            return (
              <div key={doc.id} className="bg-white rounded-xl border border-gray-100 shadow-sm p-3 hover:shadow-md transition-all">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${config.bg}`}>
                    <Icon size={16} className={config.color} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">{doc.name}</p>
                    <div className="flex items-center gap-1.5 mt-0.5 flex-wrap">
                      <span className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${config.bg} ${config.color}`}>
                        {config.label}
                      </span>
                      <span className="text-xs text-gray-400">
                        {formatFileSize(doc.fileSizeBytes)} · {new Date(doc.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}
                      </span>
                      {equipment && (
                        <span className="text-[10px] text-gray-400">
                          · {equipment.name}
                        </span>
                      )}
                    </div>
                    {doc.description && (
                      <p className="text-xs text-gray-400 mt-1 truncate">{doc.description}</p>
                    )}
                    {isExpired && (
                      <p className="text-[10px] text-red-600 font-medium mt-1">Expired {new Date(doc.expiryDate!).toLocaleDateString()}</p>
                    )}
                    {isExpiringSoon && (
                      <p className="text-[10px] text-amber-600 font-medium mt-1">Expires {new Date(doc.expiryDate!).toLocaleDateString()}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-1">
                    {doc.signedUrl && (
                      <a
                        href={doc.signedUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-2 text-gray-300 hover:text-orange-500 transition-colors"
                        title="Download"
                      >
                        <Download size={16} />
                      </a>
                    )}
                    <button
                      onClick={() => handleDelete(doc.id)}
                      disabled={deleting === doc.id}
                      className="p-2 text-gray-300 hover:text-red-500 transition-colors"
                      title="Delete"
                    >
                      {deleting === doc.id ? <Loader2 size={14} className="animate-spin" /> : <Trash2 size={14} />}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
