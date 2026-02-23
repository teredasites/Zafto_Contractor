'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  FileCheck,
  ClipboardCheck,
  Clock,
  Calendar,
  AlertTriangle,
  CheckCircle,
  XCircle,
  MoreHorizontal,
  ExternalLink,
  Upload,
  Eye,
  MapPin,
  User,
  Briefcase,
  Filter,
  ArrowRight,
  FileText,
  Building,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';
import { usePermits, type PermitData } from '@/lib/hooks/use-permits';
import { useTranslation } from '@/lib/translations';

type PermitStatus = 'draft' | 'applied' | 'in_review' | 'approved' | 'inspection_scheduled' | 'passed' | 'failed' | 'expired';
type PermitType = 'electrical' | 'plumbing' | 'mechanical' | 'building' | 'roofing' | 'solar' | 'demolition' | 'other';

interface Inspection {
  id: string;
  date: Date;
  inspector?: string;
  result: 'pass' | 'fail' | 'partial' | 'scheduled';
  notes?: string;
  corrections?: string[];
}

interface Permit {
  id: string;
  permitNumber?: string;
  type: PermitType;
  status: PermitStatus;
  description: string;
  jobId: string;
  jobName: string;
  customerId: string;
  customerName: string;
  address: string;
  jurisdiction: string;
  appliedDate?: Date;
  approvedDate?: Date;
  expirationDate?: Date;
  fee: number;
  inspections: Inspection[];
  documents: { name: string; type: string; uploadedAt: Date }[];
  notes?: string;
}

const statusConfig: Record<PermitStatus, { label: string; color: string; bgColor: string }> = {
  draft: { label: 'Draft', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  applied: { label: 'Applied', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  in_review: { label: 'In Review', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  approved: { label: 'Approved', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  inspection_scheduled: { label: 'Inspection Scheduled', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  passed: { label: 'Passed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  failed: { label: 'Failed', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  expired: { label: 'Expired', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
};

const typeConfig: Record<PermitType, { label: string; color: string; bgColor: string }> = {
  electrical: { label: 'Electrical', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  plumbing: { label: 'Plumbing', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  mechanical: { label: 'Mechanical', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  building: { label: 'Building', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
  roofing: { label: 'Roofing', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  solar: { label: 'Solar', color: 'text-yellow-700 dark:text-yellow-300', bgColor: 'bg-yellow-100 dark:bg-yellow-900/30' },
  demolition: { label: 'Demolition', color: 'text-rose-700 dark:text-rose-300', bgColor: 'bg-rose-100 dark:bg-rose-900/30' },
  other: { label: 'Other', color: 'text-gray-700 dark:text-gray-300', bgColor: 'bg-gray-100 dark:bg-gray-900/30' },
};

function toPermit(d: PermitData): Permit {
  return {
    id: d.id,
    permitNumber: d.permitNumber || undefined,
    type: d.permitType as PermitType,
    status: d.status as PermitStatus,
    description: d.description || '',
    jobId: d.jobId || '',
    jobName: d.jobName || '',
    customerId: d.customerId || '',
    customerName: d.customerName || '',
    address: d.address || '',
    jurisdiction: d.jurisdiction || '',
    appliedDate: d.appliedDate ? new Date(d.appliedDate) : undefined,
    approvedDate: d.approvedDate ? new Date(d.approvedDate) : undefined,
    expirationDate: d.expirationDate ? new Date(d.expirationDate) : undefined,
    fee: d.fee,
    inspections: (d.inspections || []).map(i => ({ ...i, date: new Date(i.date) })),
    documents: (d.documents || []).map(doc => ({ ...doc, uploadedAt: new Date(doc.uploadedAt) })),
    notes: d.notes || undefined,
  };
}

export default function PermitsPage() {
  const { t } = useTranslation();
  const { permits: rawPermits, loading, createPermit } = usePermits();
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedPermit, setSelectedPermit] = useState<Permit | null>(null);

  const allPermits = rawPermits.map(toPermit);

  const filteredPermits = allPermits.filter((p) => {
    const matchesSearch =
      p.description.toLowerCase().includes(search.toLowerCase()) ||
      p.customerName.toLowerCase().includes(search.toLowerCase()) ||
      p.permitNumber?.toLowerCase().includes(search.toLowerCase()) ||
      p.address.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    const matchesType = typeFilter === 'all' || p.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const pendingCount = allPermits.filter((p) => ['applied', 'in_review'].includes(p.status)).length;
  const activeCount = allPermits.filter((p) => ['approved', 'inspection_scheduled'].includes(p.status)).length;
  const failedCount = allPermits.filter((p) => p.status === 'failed').length;
  const upcomingInspections = allPermits.flatMap((p) => p.inspections.filter((i) => i.result === 'scheduled')).length;

  if (loading) {
    return (
      <div className="space-y-6">
        <div><div className="skeleton h-7 w-32 mb-2" /><div className="skeleton h-4 w-52" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-4"><div className="skeleton h-6 w-12 mb-1" /><div className="skeleton h-3 w-24" /></div>)}
        </div>
        <div className="bg-surface border border-main rounded-xl p-6"><div className="skeleton h-4 w-48 mb-4" /><div className="skeleton h-3 w-full mb-2" /><div className="skeleton h-3 w-full mb-2" /><div className="skeleton h-3 w-3/4" /></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('permits.title')}</h1>
          <p className="text-muted mt-1">Track permit applications, inspections, and compliance</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Permit</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Clock size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{pendingCount}</p><p className="text-sm text-muted">Pending Approval</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><FileCheck size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{activeCount}</p><p className="text-sm text-muted">Active Permits</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-cyan-100 dark:bg-cyan-900/30 rounded-lg"><ClipboardCheck size={20} className="text-cyan-600 dark:text-cyan-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{upcomingInspections}</p><p className="text-sm text-muted">Upcoming Inspections</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><AlertTriangle size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{failedCount}</p><p className="text-sm text-muted">Failed / Needs Correction</p></div>
        </div></CardContent></Card>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search permits..." className="sm:w-80" />
        <Select options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
        <Select options={[{ value: 'all', label: 'All Types' }, ...Object.entries(typeConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
      </div>

      <Card>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Permit</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.type')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.status')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Job / Customer</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Jurisdiction</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Inspections</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {filteredPermits.length === 0 && (
                <tr><td colSpan={7} className="px-6 py-12 text-center">
                  <FileCheck size={40} className="mx-auto mb-3 text-muted opacity-40" />
                  <p className="text-sm font-medium text-main">No permits found</p>
                  <p className="text-xs text-muted mt-1">{allPermits.length === 0 ? 'Create your first permit to start tracking applications and inspections' : 'Try adjusting your search or filters'}</p>
                </td></tr>
              )}
              {filteredPermits.map((permit) => {
                const sConfig = statusConfig[permit.status];
                const tConfig = typeConfig[permit.type];
                const nextInspection = permit.inspections.find((i) => i.result === 'scheduled');
                return (
                  <tr key={permit.id} className="border-b border-main/50 hover:bg-surface-hover cursor-pointer" onClick={() => setSelectedPermit(permit)}>
                    <td className="px-6 py-4">
                      <p className="font-medium text-main">{permit.permitNumber || 'Pending #'}</p>
                      <p className="text-sm text-muted line-clamp-1">{permit.description}</p>
                    </td>
                    <td className="px-6 py-4"><span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span></td>
                    <td className="px-6 py-4"><span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span></td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-main">{permit.jobName}</p>
                      <p className="text-xs text-muted">{permit.customerName}</p>
                    </td>
                    <td className="px-6 py-4"><span className="text-sm text-muted">{permit.jurisdiction}</span></td>
                    <td className="px-6 py-4">
                      {nextInspection ? (
                        <div className="flex items-center gap-1 text-sm"><Calendar size={14} className="text-cyan-500" /><span className="text-main">{formatDate(nextInspection.date)}</span></div>
                      ) : (
                        <span className="text-sm text-muted">{permit.inspections.filter((i) => i.result === 'pass').length} passed</span>
                      )}
                    </td>
                    <td className="px-6 py-4"><Button variant="ghost" size="sm"><ArrowRight size={16} /></Button></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>

      {selectedPermit && <PermitDetailModal permit={selectedPermit} onClose={() => setSelectedPermit(null)} />}
      {showNewModal && <NewPermitModal onClose={() => setShowNewModal(false)} onCreate={createPermit} />}
    </div>
  );
}

function PermitDetailModal({ permit, onClose }: { permit: Permit; onClose: () => void }) {
  const sConfig = statusConfig[permit.status];
  const tConfig = typeConfig[permit.type];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Permit Details</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><XCircle size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <div className="flex items-center gap-2 mb-1">
              {permit.permitNumber && <span className="text-lg font-mono font-medium text-main">{permit.permitNumber}</span>}
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span>
            </div>
            <p className="text-muted">{permit.description}</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-3">
              <div><p className="text-xs text-muted uppercase tracking-wider">Job</p><p className="font-medium text-main">{permit.jobName}</p></div>
              <div><p className="text-xs text-muted uppercase tracking-wider">Customer</p><p className="font-medium text-main">{permit.customerName}</p></div>
              <div><p className="text-xs text-muted uppercase tracking-wider">Jurisdiction</p><p className="font-medium text-main">{permit.jurisdiction}</p></div>
            </div>
            <div className="space-y-3">
              <div><p className="text-xs text-muted uppercase tracking-wider">Address</p><p className="font-medium text-main">{permit.address}</p></div>
              <div><p className="text-xs text-muted uppercase tracking-wider">Fee</p><p className="font-medium text-main">${permit.fee}</p></div>
              {permit.expirationDate && <div><p className="text-xs text-muted uppercase tracking-wider">Expires</p><p className="font-medium text-main">{formatDate(permit.expirationDate)}</p></div>}
            </div>
          </div>

          {permit.inspections.length > 0 && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-3">Inspections</p>
              <div className="space-y-2">
                {permit.inspections.map((insp) => (
                  <div key={insp.id} className="p-3 bg-secondary rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {insp.result === 'pass' && <CheckCircle size={16} className="text-emerald-500" />}
                        {insp.result === 'fail' && <XCircle size={16} className="text-red-500" />}
                        {insp.result === 'scheduled' && <Clock size={16} className="text-cyan-500" />}
                        {insp.result === 'partial' && <AlertTriangle size={16} className="text-amber-500" />}
                        <span className="font-medium text-main text-sm">{formatDate(insp.date)}</span>
                      </div>
                      <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium',
                        insp.result === 'pass' ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' :
                        insp.result === 'fail' ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300' :
                        insp.result === 'scheduled' ? 'bg-cyan-100 dark:bg-cyan-900/30 text-cyan-700 dark:text-cyan-300' :
                        'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
                      )}>{insp.result}</span>
                    </div>
                    {insp.inspector && <p className="text-xs text-muted mt-1">Inspector: {insp.inspector}</p>}
                    {insp.notes && <p className="text-sm text-muted mt-1">{insp.notes}</p>}
                    {insp.corrections && insp.corrections.length > 0 && (
                      <div className="mt-2 p-2 bg-red-50 dark:bg-red-900/10 rounded">
                        <p className="text-xs font-medium text-red-700 dark:text-red-300 mb-1">Required Corrections:</p>
                        {insp.corrections.map((c, i) => <p key={i} className="text-xs text-red-600 dark:text-red-400">- {c}</p>)}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {permit.documents.length > 0 && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-3">Documents</p>
              <div className="space-y-1">
                {permit.documents.map((doc, i) => (
                  <div key={i} className="flex items-center justify-between p-2 hover:bg-surface-hover rounded">
                    <div className="flex items-center gap-2"><FileText size={16} className="text-muted" /><span className="text-sm text-main">{doc.name}</span></div>
                    <span className="text-xs text-muted">{formatDate(doc.uploadedAt)}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
            <Button variant="secondary" className="flex-1"><Upload size={16} />Upload Document</Button>
            <Button className="flex-1"><ClipboardCheck size={16} />Schedule Inspection</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewPermitModal({ onClose, onCreate }: { onClose: () => void; onCreate: (data: Record<string, unknown>) => Promise<string> }) {
  const [form, setForm] = useState({ permitType: 'electrical', description: '', jurisdiction: '', address: '', fee: '', appliedDate: '', notes: '' });
  const [saving, setSaving] = useState(false);
  const update = (field: string, value: string) => setForm(prev => ({ ...prev, [field]: value }));
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>New Permit Application</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Permit Type *</label>
            <select value={form.permitType} onChange={e => update('permitType', e.target.value)} className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="electrical">Electrical</option>
              <option value="plumbing">Plumbing</option>
              <option value="mechanical">Mechanical / HVAC</option>
              <option value="building">Building</option>
              <option value="roofing">Roofing</option>
              <option value="solar">Solar</option>
              <option value="demolition">Demolition</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description *</label>
            <input type="text" value={form.description} onChange={e => update('description', e.target.value)} placeholder="200A panel upgrade, new circuits for kitchen" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Jurisdiction *</label>
              <input type="text" value={form.jurisdiction} onChange={e => update('jurisdiction', e.target.value)} placeholder="City of Hartford" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Job Site Address</label>
              <input type="text" value={form.address} onChange={e => update('address', e.target.value)} placeholder="123 Oak Ave, Hartford, CT" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Permit Fee</label>
              <input type="number" value={form.fee} onChange={e => update('fee', e.target.value.replace(/[^0-9.]/g, ''))} min="0" step="0.01" placeholder="350" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Application Date</label>
              <input type="date" value={form.appliedDate} onChange={e => update('appliedDate', e.target.value)} className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={3} value={form.notes} onChange={e => update('notes', e.target.value)} placeholder="Additional details, special requirements..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1" disabled={saving || !form.description || !form.jurisdiction} onClick={async () => {
              setSaving(true);
              try {
                await onCreate({
                  permit_type: form.permitType,
                  description: form.description,
                  jurisdiction: form.jurisdiction,
                  address: form.address || null,
                  fee: form.fee ? parseFloat(form.fee) : 0,
                  applied_date: form.appliedDate || null,
                  notes: form.notes || null,
                  status: 'draft',
                });
                onClose();
              } catch (e) { alert(e instanceof Error ? e.message : 'Failed to create'); }
              setSaving(false);
            }}><Plus size={16} />{saving ? 'Creating...' : 'Create Permit'}</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
