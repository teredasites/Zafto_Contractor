'use client';

import { useState } from 'react';
import {
  Search,
  FileText,
  Image,
  File,
  Folder,
  Upload,
  Download,
  Trash2,
  MoreHorizontal,
  Plus,
  X,
  Eye,
  Grid,
  List,
  Filter,
  Link,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';

type DocType = 'pdf' | 'image' | 'document' | 'spreadsheet' | 'other';

interface Document {
  id: string;
  name: string;
  type: DocType;
  size: number; // in bytes
  category: string;
  customerId?: string;
  customerName?: string;
  jobId?: string;
  jobName?: string;
  uploadedBy: string;
  uploadedAt: Date;
  url: string;
}

const mockDocuments: Document[] = [
  { id: '1', name: 'Estimate_Martinez_2024.pdf', type: 'pdf', size: 245000, category: 'Estimates', customerId: 'c1', customerName: 'Sarah Martinez', jobId: 'j1', jobName: 'Panel Upgrade', uploadedBy: 'John Smith', uploadedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '2', name: 'Contract_Thompson_Signed.pdf', type: 'pdf', size: 512000, category: 'Contracts', customerId: 'c2', customerName: 'Mike Thompson', jobId: 'j2', jobName: 'Commercial Wiring', uploadedBy: 'John Smith', uploadedAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '3', name: 'Site_Photo_Kitchen_01.jpg', type: 'image', size: 2400000, category: 'Photos', customerId: 'c3', customerName: 'Jennifer Davis', jobId: 'j3', jobName: 'Kitchen Remodel', uploadedBy: 'Mike Johnson', uploadedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '4', name: 'Site_Photo_Kitchen_02.jpg', type: 'image', size: 2100000, category: 'Photos', customerId: 'c3', customerName: 'Jennifer Davis', jobId: 'j3', jobName: 'Kitchen Remodel', uploadedBy: 'Mike Johnson', uploadedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '5', name: 'Permit_Electrical_2024.pdf', type: 'pdf', size: 180000, category: 'Permits', customerId: 'c1', customerName: 'Sarah Martinez', jobId: 'j1', jobName: 'Panel Upgrade', uploadedBy: 'John Smith', uploadedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '6', name: 'Invoice_2024_089.pdf', type: 'pdf', size: 125000, category: 'Invoices', customerId: 'c4', customerName: 'Robert Chen', uploadedBy: 'Admin', uploadedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '7', name: 'Floor_Plan_Chen.pdf', type: 'pdf', size: 890000, category: 'Plans', customerId: 'c4', customerName: 'Robert Chen', jobId: 'j4', jobName: 'Home Rewire', uploadedBy: 'John Smith', uploadedAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '8', name: 'Material_List.xlsx', type: 'spreadsheet', size: 45000, category: 'Other', jobId: 'j2', jobName: 'Commercial Wiring', uploadedBy: 'John Smith', uploadedAt: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '9', name: 'Insurance_Certificate_2024.pdf', type: 'pdf', size: 320000, category: 'Certificates', uploadedBy: 'Admin', uploadedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), url: '#' },
  { id: '10', name: 'W9_ABC_Electric.pdf', type: 'pdf', size: 95000, category: 'Certificates', uploadedBy: 'Admin', uploadedAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), url: '#' },
];

const categoryOptions = [
  { value: 'all', label: 'All Categories' },
  { value: 'Estimates', label: 'Estimates' },
  { value: 'Contracts', label: 'Contracts' },
  { value: 'Invoices', label: 'Invoices' },
  { value: 'Photos', label: 'Photos' },
  { value: 'Permits', label: 'Permits' },
  { value: 'Plans', label: 'Plans' },
  { value: 'Certificates', label: 'Certificates' },
  { value: 'Other', label: 'Other' },
];

export default function DocumentsPage() {
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [showUploadModal, setShowUploadModal] = useState(false);

  const filteredDocs = mockDocuments.filter((doc) => {
    const matchesSearch =
      doc.name.toLowerCase().includes(search.toLowerCase()) ||
      doc.customerName?.toLowerCase().includes(search.toLowerCase()) ||
      doc.jobName?.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || doc.category === categoryFilter;
    return matchesSearch && matchesCategory;
  });

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  };

  const getFileIcon = (type: DocType) => {
    switch (type) {
      case 'pdf': return <FileText size={24} className="text-red-500" />;
      case 'image': return <Image size={24} className="text-blue-500" />;
      case 'spreadsheet': return <File size={24} className="text-emerald-500" />;
      default: return <File size={24} className="text-muted" />;
    }
  };

  // Stats
  const totalDocs = mockDocuments.length;
  const totalSize = mockDocuments.reduce((sum, d) => sum + d.size, 0);
  const recentDocs = mockDocuments.filter((d) => Date.now() - d.uploadedAt.getTime() < 7 * 24 * 60 * 60 * 1000).length;

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Documents</h1>
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
                <p className="text-2xl font-semibold text-main">{totalDocs}</p>
                <p className="text-sm text-muted">Total Files</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <Folder size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatSize(totalSize)}</p>
                <p className="text-sm text-muted">Storage Used</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Upload size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{recentDocs}</p>
                <p className="text-sm text-muted">This Week</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Image size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{mockDocuments.filter((d) => d.type === 'image').length}</p>
                <p className="text-sm text-muted">Photos</p>
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
            placeholder="Search files..."
            className="sm:w-80"
          />
          <Select
            options={categoryOptions}
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="sm:w-48"
          />
        </div>
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

      {/* Documents */}
      {viewMode === 'grid' ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {filteredDocs.map((doc) => (
            <Card key={doc.id} className="hover:shadow-md transition-shadow cursor-pointer group">
              <CardContent className="p-4">
                <div className="flex flex-col items-center text-center">
                  <div className="p-4 bg-secondary rounded-lg mb-3 group-hover:bg-surface-hover transition-colors">
                    {getFileIcon(doc.type)}
                  </div>
                  <p className="font-medium text-main text-sm truncate w-full" title={doc.name}>
                    {doc.name}
                  </p>
                  <p className="text-xs text-muted mt-1">{formatSize(doc.size)}</p>
                  {doc.customerName && (
                    <p className="text-xs text-muted truncate w-full">{doc.customerName}</p>
                  )}
                </div>
                <div className="flex items-center justify-center gap-1 mt-3 pt-3 border-t border-main opacity-0 group-hover:opacity-100 transition-opacity">
                  <button className="p-1.5 hover:bg-surface-hover rounded-lg">
                    <Eye size={14} className="text-muted" />
                  </button>
                  <button className="p-1.5 hover:bg-surface-hover rounded-lg">
                    <Download size={14} className="text-muted" />
                  </button>
                  <button className="p-1.5 hover:bg-red-100 dark:hover:bg-red-900/30 rounded-lg">
                    <Trash2 size={14} className="text-red-500" />
                  </button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <Card>
          <CardContent className="p-0">
            <table className="w-full">
              <thead>
                <tr className="border-b border-main">
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Name</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Category</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Customer/Job</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Size</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3">Uploaded</th>
                  <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {filteredDocs.map((doc) => (
                  <tr key={doc.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-3">
                        {getFileIcon(doc.type)}
                        <span className="font-medium text-main">{doc.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-3">
                      <Badge variant="default" size="sm">{doc.category}</Badge>
                    </td>
                    <td className="px-6 py-3 text-sm text-muted">
                      {doc.customerName && <div>{doc.customerName}</div>}
                      {doc.jobName && <div className="text-xs">{doc.jobName}</div>}
                    </td>
                    <td className="px-6 py-3 text-sm text-muted">{formatSize(doc.size)}</td>
                    <td className="px-6 py-3 text-sm text-muted">{formatDate(doc.uploadedAt)}</td>
                    <td className="px-6 py-3">
                      <div className="flex items-center gap-1">
                        <button className="p-1.5 hover:bg-surface-hover rounded-lg">
                          <Download size={16} className="text-muted" />
                        </button>
                        <button className="p-1.5 hover:bg-surface-hover rounded-lg">
                          <MoreHorizontal size={16} className="text-muted" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      )}

      {/* Upload Modal */}
      {showUploadModal && (
        <UploadModal onClose={() => setShowUploadModal(false)} />
      )}
    </div>
  );
}

function UploadModal({ onClose }: { onClose: () => void }) {
  const [isDragging, setIsDragging] = useState(false);

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Upload Files</CardTitle>
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

          {/* Category */}
          <Select
            label="Category"
            options={categoryOptions.filter((c) => c.value !== 'all')}
          />

          {/* Link to */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Link to Customer</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">None</option>
                <option value="c1">Sarah Martinez</option>
                <option value="c2">Mike Thompson</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Link to Job</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">None</option>
                <option value="j1">Panel Upgrade</option>
                <option value="j2">Commercial Wiring</option>
              </select>
            </div>
          </div>

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
