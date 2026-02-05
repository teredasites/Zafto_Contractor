'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  Shield,
  ShieldCheck,
  ShieldAlert,
  Clock,
  Calendar,
  AlertTriangle,
  CheckCircle,
  XCircle,
  MoreHorizontal,
  ChevronRight,
  FileText,
  Wrench,
  Home,
  User,
  Filter,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type WarrantyStatus = 'active' | 'expiring_soon' | 'expired' | 'claimed';
type WarrantyType = 'labor' | 'equipment' | 'manufacturer' | 'extended';

interface Warranty {
  id: string;
  type: WarrantyType;
  status: WarrantyStatus;
  description: string;
  customerName: string;
  customerId: string;
  jobId: string;
  jobName: string;
  equipmentName?: string;
  manufacturer?: string;
  modelNumber?: string;
  serialNumber?: string;
  startDate: Date;
  endDate: Date;
  laborDuration?: string;
  partsDuration?: string;
  notes?: string;
  claimHistory: { date: Date; description: string; cost: number; status: 'approved' | 'denied' | 'pending' }[];
}

const statusConfig: Record<WarrantyStatus, { label: string; color: string; bgColor: string; icon: typeof Shield }> = {
  active: { label: 'Active', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30', icon: ShieldCheck },
  expiring_soon: { label: 'Expiring Soon', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30', icon: ShieldAlert },
  expired: { label: 'Expired', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30', icon: XCircle },
  claimed: { label: 'Claimed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30', icon: FileText },
};

const typeConfig: Record<WarrantyType, { label: string; color: string; bgColor: string }> = {
  labor: { label: 'Labor', color: 'text-purple-700 dark:text-purple-300', bgColor: 'bg-purple-100 dark:bg-purple-900/30' },
  equipment: { label: 'Equipment', color: 'text-cyan-700 dark:text-cyan-300', bgColor: 'bg-cyan-100 dark:bg-cyan-900/30' },
  manufacturer: { label: 'Manufacturer', color: 'text-indigo-700 dark:text-indigo-300', bgColor: 'bg-indigo-100 dark:bg-indigo-900/30' },
  extended: { label: 'Extended', color: 'text-teal-700 dark:text-teal-300', bgColor: 'bg-teal-100 dark:bg-teal-900/30' },
};

const mockWarranties: Warranty[] = [
  {
    id: 'w1',
    type: 'labor',
    status: 'active',
    description: '1-year labor warranty on full home rewire',
    customerName: 'Robert Chen',
    customerId: 'c1',
    jobId: 'j1',
    jobName: 'Full Home Rewire - 123 Oak Ave',
    startDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() + 275 * 24 * 60 * 60 * 1000),
    laborDuration: '1 year',
    notes: 'Covers all wiring, outlets, and panel work',
    claimHistory: [],
  },
  {
    id: 'w2',
    type: 'equipment',
    status: 'active',
    description: 'Carrier 5-ton AC unit - 10 year compressor warranty',
    customerName: 'Sarah Martinez',
    customerId: 'c2',
    jobId: 'j2',
    jobName: 'HVAC Install - 456 Elm St',
    equipmentName: 'Carrier 24ACC636A003',
    manufacturer: 'Carrier',
    modelNumber: '24ACC636A003',
    serialNumber: 'SN-4829174',
    startDate: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() + 3470 * 24 * 60 * 60 * 1000),
    laborDuration: '1 year',
    partsDuration: '10 years',
    claimHistory: [],
  },
  {
    id: 'w3',
    type: 'manufacturer',
    status: 'expiring_soon',
    description: 'Rheem tankless water heater - manufacturer parts warranty',
    customerName: 'Mike Thompson',
    customerId: 'c3',
    jobId: 'j3',
    jobName: 'Water Heater Replacement - 789 Industrial',
    equipmentName: 'Rheem RTGH-95DVLN',
    manufacturer: 'Rheem',
    modelNumber: 'RTGH-95DVLN',
    serialNumber: 'SN-9283746',
    startDate: new Date(Date.now() - 340 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
    partsDuration: '1 year',
    claimHistory: [
      { date: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000), description: 'Flow sensor replacement', cost: 0, status: 'approved' },
    ],
  },
  {
    id: 'w4',
    type: 'labor',
    status: 'expired',
    description: '90-day labor warranty on panel upgrade',
    customerName: 'Jennifer Davis',
    customerId: 'c4',
    jobId: 'j4',
    jobName: 'Panel Upgrade 100A to 200A',
    startDate: new Date(Date.now() - 180 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
    laborDuration: '90 days',
    claimHistory: [],
  },
  {
    id: 'w5',
    type: 'extended',
    status: 'claimed',
    description: 'Extended 5-year warranty on GAF Timberline HDZ roofing',
    customerName: 'David Wilson',
    customerId: 'c5',
    jobId: 'j5',
    jobName: 'Full Roof Replacement - 555 Birch Ln',
    equipmentName: 'GAF Timberline HDZ',
    manufacturer: 'GAF',
    startDate: new Date(Date.now() - 730 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() + 1095 * 24 * 60 * 60 * 1000),
    partsDuration: '5 years',
    laborDuration: '2 years',
    claimHistory: [
      { date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), description: 'Wind damage - 3 shingles replaced', cost: 0, status: 'approved' },
      { date: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), description: 'Flashing repair around chimney', cost: 150, status: 'pending' },
    ],
  },
  {
    id: 'w6',
    type: 'equipment',
    status: 'active',
    description: 'Generac 22kW standby generator - 5 year limited warranty',
    customerName: 'Lisa Brown',
    customerId: 'c6',
    jobId: 'j6',
    jobName: 'Generator Install - 222 Pine St',
    equipmentName: 'Generac Guardian 7043',
    manufacturer: 'Generac',
    modelNumber: '7043',
    serialNumber: 'SN-1029384',
    startDate: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
    endDate: new Date(Date.now() + 1765 * 24 * 60 * 60 * 1000),
    partsDuration: '5 years',
    laborDuration: '2 years',
    claimHistory: [],
  },
];

function getDaysRemaining(endDate: Date): number {
  return Math.ceil((endDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
}

export default function WarrantiesPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [showNewModal, setShowNewModal] = useState(false);
  const [selectedWarranty, setSelectedWarranty] = useState<Warranty | null>(null);

  const filteredWarranties = mockWarranties.filter((w) => {
    const matchesSearch =
      w.description.toLowerCase().includes(search.toLowerCase()) ||
      w.customerName.toLowerCase().includes(search.toLowerCase()) ||
      w.equipmentName?.toLowerCase().includes(search.toLowerCase()) ||
      w.manufacturer?.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === 'all' || w.status === statusFilter;
    const matchesType = typeFilter === 'all' || w.type === typeFilter;
    return matchesSearch && matchesStatus && matchesType;
  });

  const activeCount = mockWarranties.filter((w) => w.status === 'active').length;
  const expiringCount = mockWarranties.filter((w) => w.status === 'expiring_soon').length;
  const claimsCount = mockWarranties.reduce((sum, w) => sum + w.claimHistory.filter((c) => c.status === 'pending').length, 0);
  const totalCovered = mockWarranties.filter((w) => ['active', 'expiring_soon'].includes(w.status)).length;

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Warranties</h1>
          <p className="text-muted mt-1">Track labor and equipment warranties across all jobs</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          Add Warranty
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <ShieldCheck size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{activeCount}</p>
                <p className="text-sm text-muted">Active Warranties</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <ShieldAlert size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{expiringCount}</p>
                <p className="text-sm text-muted">Expiring Soon</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <FileText size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{claimsCount}</p>
                <p className="text-sm text-muted">Pending Claims</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <Shield size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalCovered}</p>
                <p className="text-sm text-muted">Jobs Covered</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search warranties..." className="sm:w-80" />
        <Select
          options={[
            { value: 'all', label: 'All Statuses' },
            { value: 'active', label: 'Active' },
            { value: 'expiring_soon', label: 'Expiring Soon' },
            { value: 'expired', label: 'Expired' },
            { value: 'claimed', label: 'Claimed' },
          ]}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-48"
        />
        <Select
          options={[
            { value: 'all', label: 'All Types' },
            { value: 'labor', label: 'Labor' },
            { value: 'equipment', label: 'Equipment' },
            { value: 'manufacturer', label: 'Manufacturer' },
            { value: 'extended', label: 'Extended' },
          ]}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
        />
      </div>

      {/* Warranties List */}
      <div className="space-y-3">
        {filteredWarranties.map((warranty) => {
          const sConfig = statusConfig[warranty.status];
          const tConfig = typeConfig[warranty.type];
          const daysRemaining = getDaysRemaining(warranty.endDate);
          const StatusIcon = sConfig.icon;

          return (
            <Card key={warranty.id} className="hover:border-accent/30 transition-colors cursor-pointer" onClick={() => setSelectedWarranty(warranty)}>
              <CardContent className="p-5">
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={cn('p-2.5 rounded-lg', sConfig.bgColor)}>
                      <StatusIcon size={22} className={sConfig.color} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-medium text-main">{warranty.description}</h3>
                      </div>
                      <div className="flex items-center gap-4 text-sm text-muted mb-2">
                        <span className="flex items-center gap-1"><User size={14} />{warranty.customerName}</span>
                        <span className="flex items-center gap-1"><Wrench size={14} />{warranty.jobName}</span>
                      </div>
                      {warranty.equipmentName && (
                        <p className="text-sm text-muted">
                          {warranty.manufacturer} {warranty.modelNumber}
                          {warranty.serialNumber && <span className="ml-2 text-xs">S/N: {warranty.serialNumber}</span>}
                        </p>
                      )}
                      <div className="flex items-center gap-4 mt-2">
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
                        <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span>
                        {warranty.laborDuration && <span className="text-xs text-muted">Labor: {warranty.laborDuration}</span>}
                        {warranty.partsDuration && <span className="text-xs text-muted">Parts: {warranty.partsDuration}</span>}
                      </div>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0 ml-4">
                    <div className="flex items-center gap-1 text-sm">
                      <Calendar size={14} className="text-muted" />
                      <span className="text-muted">{formatDate(warranty.startDate)} - {formatDate(warranty.endDate)}</span>
                    </div>
                    {warranty.status !== 'expired' && (
                      <p className={cn('text-sm font-medium mt-1', daysRemaining <= 30 ? 'text-amber-600 dark:text-amber-400' : daysRemaining <= 0 ? 'text-red-600' : 'text-emerald-600 dark:text-emerald-400')}>
                        {daysRemaining > 0 ? `${daysRemaining} days remaining` : 'Expired'}
                      </p>
                    )}
                    {warranty.claimHistory.length > 0 && (
                      <p className="text-xs text-muted mt-1">{warranty.claimHistory.length} claim{warranty.claimHistory.length !== 1 ? 's' : ''}</p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}

        {filteredWarranties.length === 0 && (
          <Card>
            <CardContent className="p-12 text-center">
              <Shield size={48} className="mx-auto text-muted mb-4" />
              <h3 className="text-lg font-medium text-main mb-2">No warranties found</h3>
              <p className="text-muted mb-4">Add warranties to track coverage for your jobs and equipment.</p>
              <Button onClick={() => setShowNewModal(true)}><Plus size={16} />Add Warranty</Button>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Detail Modal */}
      {selectedWarranty && <WarrantyDetailModal warranty={selectedWarranty} onClose={() => setSelectedWarranty(null)} />}
      {showNewModal && <NewWarrantyModal onClose={() => setShowNewModal(false)} />}
    </div>
  );
}

function WarrantyDetailModal({ warranty, onClose }: { warranty: Warranty; onClose: () => void }) {
  const sConfig = statusConfig[warranty.status];
  const tConfig = typeConfig[warranty.type];
  const daysRemaining = getDaysRemaining(warranty.endDate);

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Warranty Details</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}><XCircle size={18} /></Button>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <h3 className="font-medium text-main text-lg">{warranty.description}</h3>
            <div className="flex items-center gap-2 mt-2">
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', sConfig.bgColor, sConfig.color)}>{sConfig.label}</span>
              <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium', tConfig.bgColor, tConfig.color)}>{tConfig.label}</span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-3">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Customer</p>
                <p className="font-medium text-main">{warranty.customerName}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Job</p>
                <p className="font-medium text-main">{warranty.jobName}</p>
              </div>
              {warranty.laborDuration && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Labor Coverage</p>
                  <p className="font-medium text-main">{warranty.laborDuration}</p>
                </div>
              )}
            </div>
            <div className="space-y-3">
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">Start Date</p>
                <p className="font-medium text-main">{formatDate(warranty.startDate)}</p>
              </div>
              <div>
                <p className="text-xs text-muted uppercase tracking-wider">End Date</p>
                <p className="font-medium text-main">{formatDate(warranty.endDate)}</p>
              </div>
              {warranty.partsDuration && (
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Parts Coverage</p>
                  <p className="font-medium text-main">{warranty.partsDuration}</p>
                </div>
              )}
            </div>
          </div>

          {warranty.equipmentName && (
            <div className="p-4 bg-secondary rounded-lg">
              <p className="text-xs text-muted uppercase tracking-wider mb-2">Equipment</p>
              <p className="font-medium text-main">{warranty.equipmentName}</p>
              <div className="flex items-center gap-4 mt-1 text-sm text-muted">
                {warranty.manufacturer && <span>Mfr: {warranty.manufacturer}</span>}
                {warranty.modelNumber && <span>Model: {warranty.modelNumber}</span>}
                {warranty.serialNumber && <span>S/N: {warranty.serialNumber}</span>}
              </div>
            </div>
          )}

          {warranty.notes && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-1">Notes</p>
              <p className="text-sm text-main">{warranty.notes}</p>
            </div>
          )}

          {warranty.claimHistory.length > 0 && (
            <div>
              <p className="text-xs text-muted uppercase tracking-wider mb-3">Claim History</p>
              <div className="space-y-2">
                {warranty.claimHistory.map((claim, i) => (
                  <div key={i} className="flex items-center justify-between p-3 bg-secondary rounded-lg">
                    <div>
                      <p className="text-sm font-medium text-main">{claim.description}</p>
                      <p className="text-xs text-muted">{formatDate(claim.date)}</p>
                    </div>
                    <div className="text-right">
                      {claim.cost > 0 && <p className="text-sm font-medium text-main">{formatCurrency(claim.cost)}</p>}
                      <span className={cn('px-2 py-0.5 rounded-full text-xs font-medium',
                        claim.status === 'approved' ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300' :
                        claim.status === 'denied' ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300' :
                        'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
                      )}>{claim.status}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Close</Button>
            <Button className="flex-1"><FileText size={16} />File Claim</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function NewWarrantyModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>Add Warranty</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Warranty Type *</label>
            <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
              <option value="labor">Labor Warranty</option>
              <option value="equipment">Equipment Warranty</option>
              <option value="manufacturer">Manufacturer Warranty</option>
              <option value="extended">Extended Warranty</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Description *</label>
            <input type="text" placeholder="1-year labor warranty on panel upgrade" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Customer *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">Select customer</option>
                <option value="c1">Robert Chen</option>
                <option value="c2">Sarah Martinez</option>
                <option value="c3">Mike Thompson</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Job *</label>
              <select className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main">
                <option value="">Select job</option>
                <option value="j1">Full Home Rewire</option>
                <option value="j2">HVAC Install</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Start Date</label>
              <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">End Date</label>
              <input type="date" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Labor Duration</label>
              <input type="text" placeholder="1 year" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Parts Duration</label>
              <input type="text" placeholder="5 years" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Equipment (optional)</label>
            <input type="text" placeholder="Model name or number" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Manufacturer</label>
              <input type="text" placeholder="Carrier, Rheem, etc." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Serial Number</label>
              <input type="text" placeholder="SN-123456" className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea rows={3} placeholder="Coverage details, exclusions, etc." className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Add Warranty</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
