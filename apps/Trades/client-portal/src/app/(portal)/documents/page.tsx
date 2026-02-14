'use client';

import { useState } from 'react';
import { FileText, Download, Search, Image, AlertTriangle } from 'lucide-react';
import { useClientDocuments, type ClientDocument } from '@/lib/hooks/use-documents';

type DocType = 'estimate' | 'agreement' | 'invoice' | 'permit' | 'inspection' | 'warranty' | 'photo' | 'general' | 'contract' | 'receipt' | 'other';

const typeConfig: Record<string, { label: string; color: string; bg: string }> = {
  estimate: { label: 'Estimate', color: 'text-orange-700', bg: 'bg-orange-50' },
  proposal: { label: 'Proposal', color: 'text-orange-700', bg: 'bg-orange-50' },
  agreement: { label: 'Agreement', color: 'text-purple-700', bg: 'bg-purple-50' },
  contract: { label: 'Contract', color: 'text-purple-700', bg: 'bg-purple-50' },
  invoice: { label: 'Invoice', color: 'text-blue-700', bg: 'bg-blue-50' },
  permit: { label: 'Permit', color: 'text-green-700', bg: 'bg-green-50' },
  inspection: { label: 'Inspection', color: 'text-cyan-700', bg: 'bg-cyan-50' },
  warranty: { label: 'Warranty', color: 'text-amber-700', bg: 'bg-amber-50' },
  photo: { label: 'Photo', color: 'text-pink-700', bg: 'bg-pink-50' },
  receipt: { label: 'Receipt', color: 'text-emerald-700', bg: 'bg-emerald-50' },
  report: { label: 'Report', color: 'text-indigo-700', bg: 'bg-indigo-50' },
  general: { label: 'Document', color: 'text-gray-700', bg: 'bg-gray-50' },
  other: { label: 'Other', color: 'text-gray-700', bg: 'bg-gray-50' },
};

function getConfig(docType: string) {
  return typeConfig[docType] || typeConfig.general;
}

export default function DocumentsPage() {
  const { documents, loading, error, formatFileSize } = useClientDocuments();
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<string>('all');

  const filtered = documents.filter((d: ClientDocument) => {
    if (filterType !== 'all' && d.documentType !== filterType) return false;
    if (search && !d.name.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  // Get unique document types for filter buttons
  const docTypes = Array.from(new Set(documents.map(d => d.documentType)));

  if (loading) {
    return (
      <div className="space-y-4 animate-pulse">
        <div className="h-8 bg-gray-100 rounded w-32" />
        <div className="h-10 bg-gray-100 rounded-xl" />
        {[1, 2, 3].map(i => (
          <div key={i} className="h-16 bg-gray-100 rounded-xl" />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-xl border border-red-200 p-8 text-center">
        <AlertTriangle className="h-8 w-8 text-red-500 mx-auto mb-2" />
        <p className="text-red-600">{error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Documents</h1>
        <p className="text-sm text-gray-500 mt-0.5">{documents.length} file{documents.length !== 1 ? 's' : ''}</p>
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search documents..."
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
      </div>

      {docTypes.length > 1 && (
        <div className="flex gap-2 overflow-x-auto pb-1">
          <button onClick={() => setFilterType('all')}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filterType === 'all' ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
            All
          </button>
          {docTypes.map(t => (
            <button key={t} onClick={() => setFilterType(t)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filterType === t ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
              {getConfig(t).label}
            </button>
          ))}
        </div>
      )}

      {filtered.length === 0 ? (
        <div className="rounded-xl border border-gray-200 p-12 text-center">
          <FileText className="h-12 w-12 text-gray-300 mx-auto mb-3" />
          <p className="text-gray-500">{documents.length === 0 ? 'No documents yet' : 'No documents match your filters'}</p>
          <p className="text-sm text-gray-400 mt-1">
            {documents.length === 0 ? 'Documents from your contractor will appear here' : 'Try adjusting your search or filter'}
          </p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((doc: ClientDocument) => {
            const config = getConfig(doc.documentType);
            const isImage = doc.fileType === 'image' || doc.documentType === 'photo';
            return (
              <div key={doc.id} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-3 hover:shadow-md transition-all">
                <div className={`p-2 rounded-lg ${config.bg}`}>
                  {isImage ? <Image size={16} className={config.color} /> : <FileText size={16} className={config.color} />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">{doc.name}</p>
                  <p className="text-xs text-gray-400 mt-0.5">
                    {doc.jobName && <>{doc.jobName} &middot; </>}
                    {new Date(doc.createdAt).toLocaleDateString()} &middot; {formatFileSize(doc.fileSizeBytes)}
                  </p>
                </div>
                {doc.storagePath && (
                  <button className="p-2 text-gray-300 hover:text-orange-500 transition-colors">
                    <Download size={16} />
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
