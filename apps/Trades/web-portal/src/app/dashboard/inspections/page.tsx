'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  ClipboardCheck,
  ClipboardList,
  CheckCircle,
  CheckSquare,
  Square,
  XCircle,
  Clock,
  Calendar,
  AlertTriangle,
  Camera,
  User,
  Briefcase,
  MapPin,
  MoreHorizontal,
  ArrowRight,
  FileText,
  Shield,
  Star,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatDate, cn } from '@/lib/utils';

type InspectionStatus = 'scheduled' | 'in_progress' | 'passed' | 'failed' | 'partial';
type InspectionType = 'quality' | 'safety' | 'punch_list' | 'pre_closeout' | 'compliance' | 'progress';

interface ChecklistItem {
  id: string;
  label: string;
  completed: boolean;
  note?: string;
  photoRequired: boolean;
  hasPhoto: boolean;
}

interface Inspection {
  id: string;
  type: InspectionType;
  status: InspectionStatus;
  title: string;
  jobId: string;
  jobName: string;
  customerId: string;
  customerName: string;
  address: string;
  assignedTo: string;
  scheduledDate: Date;
  completedDate?: Date;
  checklist: ChecklistItem[];
  overallScore?: number;
  notes?: string;
  photos: number;
}

const statusConfig: Record<InspectionStatus, { label: string; color: string; bgColor: string }> = {
  scheduled: { label: 'Scheduled', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  in_progress: { label: 'In Progress', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  passed: { label: 'Passed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  failed: { label: 'Failed', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  partial: { label: 'Partial', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
};

const typeConfig: Record<InspectionType, { label: string; color: string; bgColor: string }> = {
  quality: { label: 'Quality Control', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  safety: { label: 'Safety', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  punch_list: { label: 'Punch List', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  pre_closeout: { label: 'Pre-Closeout', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  compliance: { label: 'Compliance', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  progress: { label: 'Progress', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
};

const mockInspections: Inspection[] = [
  {
    id: 'ins1', type: 'quality', status: 'scheduled',
    title: 'Rough-In Quality Check - Electrical',
    jobId: 'j1', jobName: 'Full Home Rewire - 123 Oak Ave',
    customerId: 'c1', customerName: 'Robert Chen',
    address: '123 Oak Ave, Hartford, CT 06101',
    assignedTo: 'John Smith',
    scheduledDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
    checklist: [
      { id: 'c1', label: 'Wire runs properly supported (every 4.5 ft)', completed: false, photoRequired: true, hasPhoto: false },
      { id: 'c2', label: 'Box fill calculations verified', completed: false, photoRequired: false, hasPhoto: false },
      { id: 'c3', label: 'Proper wire sizing per circuit load', completed: false, photoRequired: false, hasPhoto: false },
      { id: 'c4', label: 'GFCI/AFCI protection where required', completed: false, photoRequired: true, hasPhoto: false },
      { id: 'c5', label: 'Grounding and bonding complete', completed: false, photoRequired: true, hasPhoto: false },
      { id: 'c6', label: 'Panel labeling accurate', completed: false, photoRequired: true, hasPhoto: false },
      { id: 'c7', label: 'No visible code violations', completed: false, photoRequired: false, hasPhoto: false },
    ],
    photos: 0,
  },
  {
    id: 'ins2', type: 'safety', status: 'passed',
    title: 'Job Site Safety Inspection',
    jobId: 'j7', jobName: 'Store Buildout - 100 Main St',
    customerId: 'c5', customerName: 'David Wilson',
    address: '100 Main St, Hartford, CT 06103',
    assignedTo: 'Mike Johnson',
    scheduledDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    completedDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    checklist: [
      { id: 's1', label: 'PPE being worn by all workers', completed: true, photoRequired: false, hasPhoto: false },
      { id: 's2', label: 'Fire extinguisher accessible', completed: true, photoRequired: true, hasPhoto: true },
      { id: 's3', label: 'First aid kit stocked and accessible', completed: true, photoRequired: false, hasPhoto: false },
      { id: 's4', label: 'Lockout/tagout procedures followed', completed: true, photoRequired: true, hasPhoto: true },
      { id: 's5', label: 'Electrical panels accessible (3 ft clearance)', completed: true, photoRequired: true, hasPhoto: true },
      { id: 's6', label: 'Cords and tools in good condition', completed: true, photoRequired: false, hasPhoto: false },
      { id: 's7', label: 'Work area clean and organized', completed: true, photoRequired: false, hasPhoto: false },
      { id: 's8', label: 'OSHA poster displayed', completed: true, photoRequired: true, hasPhoto: true },
    ],
    overallScore: 100, photos: 4,
  },
  {
    id: 'ins3', type: 'punch_list', status: 'in_progress',
    title: 'Final Punch List - HVAC Install',
    jobId: 'j2', jobName: 'HVAC Install - 456 Elm St',
    customerId: 'c2', customerName: 'Sarah Martinez',
    address: '456 Elm St, West Hartford, CT 06107',
    assignedTo: 'Tom Davis',
    scheduledDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
    checklist: [
      { id: 'p1', label: 'Thermostat programmed and tested', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'p2', label: 'All registers installed and adjusted', completed: true, photoRequired: true, hasPhoto: true },
      { id: 'p3', label: 'Condensate drain tested', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'p4', label: 'Refrigerant charge verified', completed: false, photoRequired: false, hasPhoto: false },
      { id: 'p5', label: 'Ductwork sealed and insulated', completed: false, photoRequired: true, hasPhoto: false },
      { id: 'p6', label: 'Customer walkthrough completed', completed: false, photoRequired: false, hasPhoto: false },
      { id: 'p7', label: 'Equipment manuals provided', completed: false, photoRequired: false, hasPhoto: false },
      { id: 'p8', label: 'Warranty registration completed', completed: false, photoRequired: false, hasPhoto: false },
    ],
    overallScore: 38, photos: 1,
    notes: 'Waiting on refrigerant gauges from Van #2',
  },
  {
    id: 'ins4', type: 'pre_closeout', status: 'failed',
    title: 'Pre-Closeout Inspection - Roof',
    jobId: 'j5', jobName: 'Full Roof Replacement - 555 Birch Ln',
    customerId: 'c5', customerName: 'David Wilson',
    address: '555 Birch Ln, Glastonbury, CT 06033',
    assignedTo: 'John Smith',
    scheduledDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    completedDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    checklist: [
      { id: 'r1', label: 'Shingles properly aligned and nailed', completed: true, photoRequired: true, hasPhoto: true },
      { id: 'r2', label: 'Flashing sealed at all penetrations', completed: false, photoRequired: true, hasPhoto: true },
      { id: 'r3', label: 'Ridge cap installed correctly', completed: true, photoRequired: true, hasPhoto: true },
      { id: 'r4', label: 'Gutters clean and reattached', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'r5', label: 'All debris removed from site', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'r6', label: 'Magnetic nail sweep completed', completed: true, photoRequired: false, hasPhoto: false },
    ],
    overallScore: 83, photos: 3,
    notes: 'Chimney flashing needs resealing - scheduled for correction',
  },
  {
    id: 'ins5', type: 'progress', status: 'passed',
    title: '50% Progress Check - Commercial Wiring',
    jobId: 'j7', jobName: 'Store Buildout - 100 Main St',
    customerId: 'c5', customerName: 'David Wilson',
    address: '100 Main St, Hartford, CT 06103',
    assignedTo: 'Mike Johnson',
    scheduledDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
    completedDate: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
    checklist: [
      { id: 'pg1', label: 'Conduit runs per plan', completed: true, photoRequired: true, hasPhoto: true },
      { id: 'pg2', label: 'Panel scheduled correctly', completed: true, photoRequired: true, hasPhoto: true },
      { id: 'pg3', label: 'Wire pulled to all locations', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'pg4', label: 'Data/low voltage rough-in complete', completed: true, photoRequired: false, hasPhoto: false },
      { id: 'pg5', label: 'On schedule per timeline', completed: true, photoRequired: false, hasPhoto: false },
    ],
    overallScore: 100, photos: 2,
  },
];

export default function InspectionsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [selectedInspection, setSelectedInspection] = useState<Inspection | null>(null);
  const [showNewModal, setShowNewModal] = useState(false);

  const filteredInspections = mockInspections.filter((ins) => {
    const matchesSearch =
      ins.title.toLowerCase().includes(search.toLowerCase()) ||
      ins.customerName.toLowerCase().includes(search.toLowerCase()) ||
      ins.jobName.toLowerCase().includes(search.toLowerCase()) ||
      ins.assignedTo.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || ins.status === statusFilter;
    const matchesType = typeFilter === 'all' || ins.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const scheduledCount = mockInspections.filter((i) => i.status === 'scheduled').length;
  const inProgressCount = mockInspections.filter((i) => i.status === 'in_progress').length;
  const passedCount = mockInspections.filter((i) => i.status === 'passed').length;
  const failedCount = mockInspections.filter((i) => i.status === 'failed').length;

  return (
    <div className="space-y-6">
      <CommandPalette />
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Inspections & Checklists</h1>
          <p className="text-muted mt-1">Quality control, safety compliance, and punch lists</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Inspection</Button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Calendar size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{scheduledCount}</p><p className="text-sm text-muted">Scheduled</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg"><ClipboardList size={20} className="text-amber-600 dark:text-amber-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{inProgressCount}</p><p className="text-sm text-muted">In Progress</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{passedCount}</p><p className="text-sm text-muted">Passed</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><XCircle size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{failedCount}</p><p className="text-sm text-muted">Failed</p></div>
        </div></CardContent></Card>
      </div>

      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search inspections..." className="sm:w-80" />
        <Select options={[{ value: 'all', label: 'All Statuses' }, ...Object.entries(statusConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="sm:w-48" />
        <Select options={[{ value: 'all', label: 'All Types' }, ...Object.entries(typeConfig).map(([k, v]) => ({ value: k, label: v.label }))]} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
      </div>

      <div className="space-y-3">
        {filteredInspections.map((ins) => {
          const sConfig = statusConfig[ins.status];
          const tConfig = typeConfig[ins.type];
          const completedItems = ins.checklist.filter((c) => c.completed).length;
          const totalItems = ins.checklist.length;
          const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

          return (
            <Card key={ins.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => setSelectedInspection(ins)}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={cn('p-2.5 rounded-lg', tConfig.bgColor)}>
                      <ClipboardCheck size={22} className={tConfig.color} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-main">{ins.title}</h3>
                      </div>
                      <div className="flex items-center gap-2 mb-2">
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-muted">
                        <span className="flex items-center gap-1"><Briefcase size={14} />{ins.jobName}</span>
                        <span className="flex items-center gap-1"><User size={14} />{ins.assignedTo}</span>
                        <span className="flex items-center gap-1"><Calendar size={14} />{formatDate(ins.scheduledDate)}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 ml-4">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-sm font-medium text-main">{completedItems}/{totalItems}</span>
                      <span className="text-xs text-muted">items</span>
                    </div>
                    <div className="w-24 h-2 bg-secondary rounded-full overflow-hidden">
                      <div className={cn('h-full rounded-full transition-all', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-gray-300')} style={{ width: `${progress}%` }} />
                    </div>
                    {ins.overallScore !== undefined && (
                      <div className="flex items-center gap-1 mt-1 justify-end">
                        <Star size={12} className={ins.overallScore >= 80 ? 'text-emerald-500' : ins.overallScore >= 50 ? 'text-amber-500' : 'text-red-500'} />
                        <span className="text-sm font-medium text-main">{ins.overallScore}%</span>
                      </div>
                    )}
                    {ins.photos > 0 && <p className="text-xs text-muted mt-1 flex items-center gap-1 justify-end"><Camera size={12} />{ins.photos} photos</p>}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}

        {filteredInspections.length === 0 && (
          <Card><CardContent className="p-12 text-center">
            <ClipboardCheck size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No inspections found</h3>
            <p className="text-muted mb-4">Create inspections with configurable checklists for quality control and compliance.</p>
            <Button onClick={() => setShowNewModal(true)}><Plus size={16} />New Inspection</Button>
          </CardContent></Card>
        )}
      </div>

      {selectedInspection && <InspectionDetailModal inspection={selectedInspection} onClose={() => setSelectedInspection(null)} />}
      {showNewModal && <NewInspectionModal onClose={() => setShowNewModal(false)} />}
    </div>
  );
}

function InspectionDetailModal({ inspection, onClose }: { inspection: Inspection; onClose: () => void }) {
  const sConfig = statusConfig[inspection.status];
  const tConfig = typeConfig[inspection.type];
  const completedItems = inspection.checklist.filter((c) => c.completed).length;
  const totalItems = inspection.checklist.length;
  const progress = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span>
            </div>
            <CardTitle className="text-lg">{inspection.title}</CardTitle>
          </div>
          <Button variant="ghost" size="sm" onClick={onClose}><XCircle size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div><p className="text-xs text-muted uppercase tracking-wider">Job</p><p className="font-medium text-main">{inspection.jobName}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Assigned To</p><p className="font-medium text-main">{inspection.assignedTo}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Address</p><p className="font-medium text-main">{inspection.address}</p></div>
            <div><p className="text-xs text-muted uppercase tracking-wider">Date</p><p className="font-medium text-main">{formatDate(inspection.scheduledDate)}</p></div>
          </div>

          <div className="p-4 bg-secondary rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <span className="font-medium text-main">Progress: {completedItems}/{totalItems}</span>
              <span className="text-sm font-medium text-main">{progress}%</span>
            </div>
            <div className="w-full h-3 bg-main rounded-full overflow-hidden">
              <div className={cn('h-full rounded-full transition-all', progress === 100 ? 'bg-emerald-500' : progress > 0 ? 'bg-amber-500' : 'bg-gray-300')} style={{ width: `${progress}%` }} />
            </div>
          </div>

          <div>
            <p className="text-xs text-muted uppercase tracking-wider mb-3">Checklist</p>
            <div className="space-y-2">
              {inspection.checklist.map((item) => (
                <div key={item.id} className={cn('flex items-start gap-3 p-3 rounded-lg border', item.completed ? 'bg-emerald-50/50 dark:bg-emerald-900/5 border-emerald-200 dark:border-emerald-800/30' : 'bg-surface border-main')}>
                  <div className="mt-0.5">{item.completed ? <CheckSquare size={18} className="text-emerald-500" /> : <Square size={18} className="text-muted" />}</div>
                  <div className="flex-1">
                    <p className={cn('text-sm', item.completed ? 'text-main' : 'text-main')}>{item.label}</p>
                    {item.note && <p className="text-xs text-muted mt-1">{item.note}</p>}
                    <div className="flex items-center gap-2 mt-1">
                      {item.photoRequired && (
                        <span className={cn('text-xs flex items-center gap-1', item.hasPhoto ? 'text-emerald-600 dark:text-emerald-400' : 'text-amber-600 dark:text-amber-400')}>
                          <Camera size={12} />{item.hasPhoto ? 'Photo attached' : 'Photo required'}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {inspection.notes && <div><p className="text-xs text-muted uppercase tracking-wider mb-1">Notes</p><p className="text-sm text-main">{inspection.notes}</p></div>}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
            <Button variant="secondary" className="flex-1"><Camera size={16} />Add Photo</Button>
            {inspection.status !== 'passed' && <Button className="flex-1"><CheckCircle size={16} />Mark Passed</Button>}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewInspectionModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader><CardTitle>New Inspection</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Inspection Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="quality">Quality Control</option>
              <option value="safety">Safety</option>
              <option value="punch_list">Punch List</option>
              <option value="pre_closeout">Pre-Closeout</option>
              <option value="compliance">Compliance</option>
              <option value="progress">Progress Check</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Title *</label>
            <input type="text" placeholder="Rough-in quality check" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">Select job</option><option value="j1">Full Home Rewire</option><option value="j2">HVAC Install</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Assigned To *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">Select team member</option><option value="u1">John Smith</option><option value="u2">Mike Johnson</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Scheduled Date</label>
            <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Checklist Template</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="">Start blank</option>
              <option value="electrical_rough">Electrical Rough-In (7 items)</option>
              <option value="safety_standard">Standard Safety (8 items)</option>
              <option value="hvac_closeout">HVAC Closeout (8 items)</option>
              <option value="roofing_final">Roofing Final (6 items)</option>
              <option value="plumbing_rough">Plumbing Rough-In (6 items)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={2} placeholder="Special instructions..." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Create Inspection</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
