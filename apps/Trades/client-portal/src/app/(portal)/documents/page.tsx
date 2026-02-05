'use client';
import { useState } from 'react';
import { FileText, Download, Search, Filter, File, Image, ChevronRight } from 'lucide-react';

type DocType = 'estimate' | 'agreement' | 'invoice' | 'permit' | 'inspection' | 'warranty' | 'photo';
interface Document { id: string; name: string; type: DocType; project: string; date: string; size: string; }

const typeConfig: Record<DocType, { label: string; color: string; bg: string }> = {
  estimate: { label: 'Estimate', color: 'text-orange-700', bg: 'bg-orange-50' },
  agreement: { label: 'Agreement', color: 'text-purple-700', bg: 'bg-purple-50' },
  invoice: { label: 'Invoice', color: 'text-blue-700', bg: 'bg-blue-50' },
  permit: { label: 'Permit', color: 'text-green-700', bg: 'bg-green-50' },
  inspection: { label: 'Inspection', color: 'text-cyan-700', bg: 'bg-cyan-50' },
  warranty: { label: 'Warranty', color: 'text-amber-700', bg: 'bg-amber-50' },
  photo: { label: 'Photo', color: 'text-pink-700', bg: 'bg-pink-50' },
};

const mockDocs: Document[] = [
  { id: 'd1', name: 'Estimate — HVAC Replacement.pdf', type: 'estimate', project: 'HVAC System Replacement', date: 'Jan 28, 2026', size: '245 KB' },
  { id: 'd2', name: 'Service Agreement — HVAC Maintenance.pdf', type: 'agreement', project: 'Annual HVAC Maintenance', date: 'Jan 28, 2026', size: '180 KB' },
  { id: 'd3', name: 'Invoice #1042 — Panel Upgrade.pdf', type: 'invoice', project: '200A Panel Upgrade', date: 'Jan 25, 2026', size: '120 KB' },
  { id: 'd4', name: 'Electrical Permit #EP-2026-0142.pdf', type: 'permit', project: '200A Panel Upgrade', date: 'Jan 14, 2026', size: '95 KB' },
  { id: 'd5', name: 'Meter Base Inspection Report.pdf', type: 'inspection', project: '200A Panel Upgrade', date: 'Jan 19, 2026', size: '310 KB' },
  { id: 'd6', name: 'Rheem Water Heater Warranty.pdf', type: 'warranty', project: 'Water Heater Install', date: 'Jan 10, 2026', size: '88 KB' },
  { id: 'd7', name: 'Panel Install — Progress Photos.zip', type: 'photo', project: '200A Panel Upgrade', date: 'Jan 22, 2026', size: '4.2 MB' },
  { id: 'd8', name: 'Estimate — Panel Upgrade.pdf', type: 'estimate', project: '200A Panel Upgrade', date: 'Jan 10, 2026', size: '198 KB' },
  { id: 'd9', name: 'Service Agreement — Signed.pdf', type: 'agreement', project: '200A Panel Upgrade', date: 'Jan 12, 2026', size: '210 KB' },
  { id: 'd10', name: 'Roof Repair Invoice #1030.pdf', type: 'invoice', project: 'Roof Repair', date: 'Dec 18, 2025', size: '105 KB' },
];

export default function DocumentsPage() {
  const [search, setSearch] = useState('');
  const [filterType, setFilterType] = useState<'all' | DocType>('all');
  const filtered = mockDocs.filter(d => {
    if (filterType !== 'all' && d.type !== filterType) return false;
    if (search && !d.name.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Documents</h1>
        <p className="text-sm text-gray-500 mt-0.5">{mockDocs.length} files</p>
      </div>

      <div className="relative">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search documents..."
          className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20 outline-none text-sm" />
      </div>

      <div className="flex gap-2 overflow-x-auto pb-1">
        {(['all', 'estimate', 'agreement', 'invoice', 'permit', 'inspection', 'warranty'] as const).map(f => (
          <button key={f} onClick={() => setFilterType(f)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all ${filterType === f ? 'bg-orange-500 text-white' : 'bg-white text-gray-600 border border-gray-200'}`}>
            {f === 'all' ? 'All' : typeConfig[f].label}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {filtered.map(doc => {
          const config = typeConfig[doc.type];
          return (
            <div key={doc.id} className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 shadow-sm p-3 hover:shadow-md transition-all cursor-pointer">
              <div className={`p-2 rounded-lg ${config.bg}`}>
                {doc.type === 'photo' ? <Image size={16} className={config.color} /> : <FileText size={16} className={config.color} />}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">{doc.name}</p>
                <p className="text-xs text-gray-400 mt-0.5">{doc.project} · {doc.date} · {doc.size}</p>
              </div>
              <button className="p-2 text-gray-300 hover:text-orange-500 transition-colors"><Download size={16} /></button>
            </div>
          );
        })}
      </div>
    </div>
  );
}
