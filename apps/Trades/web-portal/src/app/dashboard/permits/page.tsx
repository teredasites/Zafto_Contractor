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

const mockPermits: Permit[] = [
  {
    id: 'p1', permitNumber: 'EP-2026-4421', type: 'electrical', status: 'inspection_scheduled',
    description: 'Electrical permit - Full home rewire, 200A panel upgrade',
    jobId: 'j1', jobName: 'Full Home Rewire - 123 Oak Ave', customerId: 'c1', customerName: 'Robert Chen',
    address: '123 Oak Ave, Hartford, CT 06101', jurisdiction: 'City of Hartford',
    appliedDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), approvedDate: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
    expirationDate: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000), fee: 350,
    inspections: [
      { id: 'i1', date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), inspector: 'Tom Harris', result: 'pass', notes: 'Rough-in inspection passed' },
      { id: 'i2', date: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), result: 'scheduled', notes: 'Final inspection' },
    ],
    documents: [
      { name: 'permit_application.pdf', type: 'application', uploadedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
      { name: 'electrical_plans.pdf', type: 'plans', uploadedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) },
    ],
  },
  {
    id: 'p2', permitNumber: 'PP-2026-3287', type: 'plumbing', status: 'approved',
    description: 'Plumbing permit - Water heater replacement, gas line',
    jobId: 'j3', jobName: 'Water Heater Replacement - 789 Industrial', customerId: 'c3', customerName: 'Mike Thompson',
    address: '789 Industrial Blvd, Manchester, CT 06040', jurisdiction: 'Town of Manchester',
    appliedDate: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), approvedDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
    expirationDate: new Date(Date.now() + 173 * 24 * 60 * 60 * 1000), fee: 200,
    inspections: [], documents: [{ name: 'plumbing_permit.pdf', type: 'permit', uploadedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }],
  },
  {
    id: 'p3', type: 'roofing', status: 'applied',
    description: 'Roofing permit - Full tear-off and re-roof, architectural shingles',
    jobId: 'j5', jobName: 'Full Roof Replacement - 555 Birch Ln', customerId: 'c5', customerName: 'David Wilson',
    address: '555 Birch Ln, Glastonbury, CT 06033', jurisdiction: 'Town of Glastonbury',
    appliedDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), fee: 275,
    inspections: [], documents: [{ name: 'roof_plans.pdf', type: 'plans', uploadedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000) }],
  },
  {
    id: 'p4', permitNumber: 'MP-2025-9912', type: 'mechanical', status: 'failed',
    description: 'Mechanical permit - HVAC system replacement, ductwork modification',
    jobId: 'j2', jobName: 'HVAC Install - 456 Elm St', customerId: 'c2', customerName: 'Sarah Martinez',
    address: '456 Elm St, West Hartford, CT 06107', jurisdiction: 'Town of West Hartford',
    appliedDate: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000), approvedDate: new Date(Date.now() - 35 * 24 * 60 * 60 * 1000),
    expirationDate: new Date(Date.now() + 140 * 24 * 60 * 60 * 1000), fee: 325,
    inspections: [
      { id: 'i3', date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), inspector: 'Jim Wallace', result: 'fail',
        notes: 'Ductwork not properly sealed', corrections: ['Seal all duct joints with mastic', 'Re-insulate supply plenum'] },
    ],
    documents: [],
  },
  {
    id: 'p5', permitNumber: 'BP-2025-7789', type: 'building', status: 'passed',
    description: 'Building permit - Commercial build-out, new walls and electrical',
    jobId: 'j7', jobName: 'Store Buildout - 100 Main St', customerId: 'c5', customerName: 'David Wilson',
    address: '100 Main St, Hartford, CT 06103', jurisdiction: 'City of Hartford',
    appliedDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), approvedDate: new Date(Date.now() - 75 * 24 * 60 * 60 * 1000),
    expirationDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), fee: 850,
    inspections: [
      { id: 'i4', date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), inspector: 'Tom Harris', result: 'pass', notes: 'Framing inspection' },
      { id: 'i5', date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), inspector: 'Jim Wallace', result: 'pass', notes: 'Final inspection - all passed' },
    ],
    documents: [
      { name: 'building_plans.pdf', type: 'plans', uploadedAt: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000) },
      { name: 'certificate_of_occupancy.pdf', type: 'certificate', uploadedAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000) },
    ],
  },
];

export default function PermitsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedPermit, setSelectedPermit] = useState<Permit | null>(null);

  const filteredPermits = mockPermits.filter((p) => {
    const matchesSearch =
      p.description.toLowerCase().includes(search.toLowerCase()) ||
      p.customerName.toLowerCase().includes(search.toLowerCase()) ||
      p.permitNumber?.toLowerCase().includes(search.toLowerCase()) ||
      p.address.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
    const matchesType = typeFilter === 'all' || p.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const pendingCount = mockPermits.filter((p) => ['applied', 'in_review'].includes(p.status)).length;
  const activeCount = mockPermits.filter((p) => ['approved', 'inspection_scheduled'].includes(p.status)).length;
  const failedCount = mockPermits.filter((p) => p.status === 'failed').length;
  const upcomingInspections = mockPermits.flatMap((p) => p.inspections.filter((i) => i.result === 'scheduled')).length;

  return (
    <div className="space-y-6">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Permits</h1>
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
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Type</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Status</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Job / Customer</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Jurisdiction</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">Inspections</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
              </tr>
            </thead>
            <tbody>
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
      {showNewModal && <NewPermitModal onClose={() => setShowNewModal(false)} />}
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

function NewPermitModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>New Permit Application</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Permit Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
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
            <input type="text" placeholder="200A panel upgrade, new circuits for kitchen" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">Select job</option><option value="j1">Full Home Rewire</option><option value="j2">HVAC Install</option><option value="j3">Water Heater Replacement</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Jurisdiction *</label>
              <input type="text" placeholder="City of Hartford" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Job Site Address</label>
            <input type="text" placeholder="123 Oak Ave, Hartford, CT 06101" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Permit Fee</label>
              <input type="number" placeholder="350" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Application Date</label>
              <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={3} placeholder="Additional details, special requirements..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Create Permit</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
