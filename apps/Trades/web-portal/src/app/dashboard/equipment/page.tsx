'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  Truck,
  Wrench,
  AlertTriangle,
  Calendar,
  MapPin,
  MoreHorizontal,
  CheckCircle,
  Clock,
  X,
  FileText,
  DollarSign,
  User,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { Avatar } from '@/components/ui/avatar';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';

type EquipmentStatus = 'available' | 'in_use' | 'maintenance' | 'out_of_service';
type EquipmentType = 'vehicle' | 'tool' | 'equipment';

interface Equipment {
  id: string;
  name: string;
  type: EquipmentType;
  make?: string;
  model?: string;
  year?: number;
  serialNumber?: string;
  licensePlate?: string;
  status: EquipmentStatus;
  assignedTo?: string;
  currentJob?: string;
  lastMaintenanceDate?: Date;
  nextMaintenanceDate?: Date;
  purchaseDate?: Date;
  purchasePrice?: number;
  currentValue?: number;
  notes?: string;
}

interface MaintenanceRecord {
  id: string;
  equipmentId: string;
  type: string;
  description: string;
  cost: number;
  date: Date;
  vendor?: string;
  mileage?: number;
}

const statusConfig: Record<EquipmentStatus, { label: string; color: string; bgColor: string }> = {
  available: { label: 'Available', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  in_use: { label: 'In Use', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  maintenance: { label: 'Maintenance', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  out_of_service: { label: 'Out of Service', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const mockEquipment: Equipment[] = [
  {
    id: 'e1',
    name: 'Work Van #1',
    type: 'vehicle',
    make: 'Ford',
    model: 'Transit 250',
    year: 2022,
    licensePlate: 'CT-123-ABC',
    status: 'in_use',
    assignedTo: 'John Smith',
    currentJob: 'Panel Upgrade - Martinez',
    lastMaintenanceDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    nextMaintenanceDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    purchaseDate: new Date('2022-03-15'),
    purchasePrice: 45000,
    currentValue: 38000,
  },
  {
    id: 'e2',
    name: 'Work Van #2',
    type: 'vehicle',
    make: 'Chevrolet',
    model: 'Express 2500',
    year: 2021,
    licensePlate: 'CT-456-DEF',
    status: 'available',
    lastMaintenanceDate: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000),
    nextMaintenanceDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
    purchaseDate: new Date('2021-06-20'),
    purchasePrice: 42000,
    currentValue: 32000,
  },
  {
    id: 'e3',
    name: 'Scissor Lift',
    type: 'equipment',
    make: 'Genie',
    model: 'GS-1930',
    serialNumber: 'GS1930-78542',
    status: 'available',
    lastMaintenanceDate: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
    nextMaintenanceDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // Overdue
    purchaseDate: new Date('2020-01-10'),
    purchasePrice: 12000,
    currentValue: 8000,
    notes: 'Annual inspection required',
  },
  {
    id: 'e4',
    name: 'Wire Puller',
    type: 'tool',
    make: 'Greenlee',
    model: '6001',
    serialNumber: 'GL6001-12345',
    status: 'in_use',
    assignedTo: 'Mike Johnson',
    currentJob: 'Commercial Wiring - Thompson',
    purchaseDate: new Date('2019-08-05'),
    purchasePrice: 2500,
    currentValue: 1500,
  },
  {
    id: 'e5',
    name: 'Pipe Threader',
    type: 'tool',
    make: 'Ridgid',
    model: '300 Compact',
    serialNumber: 'RG300-98765',
    status: 'maintenance',
    lastMaintenanceDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    notes: 'Motor repair in progress',
    purchaseDate: new Date('2018-11-20'),
    purchasePrice: 3500,
    currentValue: 2000,
  },
  {
    id: 'e6',
    name: 'Trailer',
    type: 'vehicle',
    make: 'Big Tex',
    model: '70PI-16',
    year: 2020,
    licensePlate: 'CT-TRL-789',
    status: 'available',
    purchaseDate: new Date('2020-04-01'),
    purchasePrice: 5500,
    currentValue: 4000,
  },
];

export default function EquipmentPage() {
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedEquipment, setSelectedEquipment] = useState<Equipment | null>(null);

  const filteredEquipment = mockEquipment.filter((eq) => {
    const matchesSearch =
      eq.name.toLowerCase().includes(search.toLowerCase()) ||
      eq.make?.toLowerCase().includes(search.toLowerCase()) ||
      eq.model?.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || eq.type === typeFilter;
    const matchesStatus = statusFilter === 'all' || eq.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    { value: 'vehicle', label: 'Vehicles' },
    { value: 'tool', label: 'Tools' },
    { value: 'equipment', label: 'Equipment' },
  ];

  const statusOptions = [
    { value: 'all', label: 'All Statuses' },
    { value: 'available', label: 'Available' },
    { value: 'in_use', label: 'In Use' },
    { value: 'maintenance', label: 'Maintenance' },
    { value: 'out_of_service', label: 'Out of Service' },
  ];

  // Stats
  const totalEquipment = mockEquipment.length;
  const inUseCount = mockEquipment.filter((e) => e.status === 'in_use').length;
  const maintenanceDue = mockEquipment.filter((e) => e.nextMaintenanceDate && new Date(e.nextMaintenanceDate) < new Date()).length;
  const totalValue = mockEquipment.reduce((sum, e) => sum + (e.currentValue || 0), 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Equipment</h1>
          <p className="text-muted mt-1">Manage vehicles, tools, and equipment</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Equipment
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Truck size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalEquipment}</p>
                <p className="text-sm text-muted">Total Items</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{inUseCount}</p>
                <p className="text-sm text-muted">In Use</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className={maintenanceDue > 0 ? 'border-amber-500' : ''}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Wrench size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{maintenanceDue}</p>
                <p className="text-sm text-muted">Maintenance Due</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg">
                <DollarSign size={20} className="text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalValue)}</p>
                <p className="text-sm text-muted">Total Value</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search equipment..."
          className="sm:w-80"
        />
        <Select
          options={typeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-40"
        />
        <Select
          options={statusOptions}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="sm:w-40"
        />
      </div>

      {/* Equipment Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredEquipment.map((eq) => (
          <EquipmentCard
            key={eq.id}
            equipment={eq}
            onClick={() => setSelectedEquipment(eq)}
          />
        ))}
      </div>

      {/* Add Modal */}
      {showAddModal && (
        <AddEquipmentModal onClose={() => setShowAddModal(false)} />
      )}

      {/* Detail Modal */}
      {selectedEquipment && (
        <EquipmentDetailModal
          equipment={selectedEquipment}
          onClose={() => setSelectedEquipment(null)}
        />
      )}
    </div>
  );
}

function EquipmentCard({ equipment, onClick }: { equipment: Equipment; onClick: () => void }) {
  const config = statusConfig[equipment.status];
  const maintenanceOverdue = equipment.nextMaintenanceDate && new Date(equipment.nextMaintenanceDate) < new Date();

  const getIcon = () => {
    switch (equipment.type) {
      case 'vehicle': return <Truck size={20} />;
      case 'tool': return <Wrench size={20} />;
      default: return <Wrench size={20} />;
    }
  };

  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onClick}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-secondary rounded-lg">
              {getIcon()}
            </div>
            <div>
              <h3 className="font-medium text-main">{equipment.name}</h3>
              {equipment.make && equipment.model && (
                <p className="text-sm text-muted">{equipment.make} {equipment.model}</p>
              )}
            </div>
          </div>
          <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
            {config.label}
          </span>
        </div>

        {equipment.assignedTo && (
          <div className="flex items-center gap-2 mb-2 text-sm">
            <User size={14} className="text-muted" />
            <span className="text-main">{equipment.assignedTo}</span>
          </div>
        )}

        {equipment.currentJob && (
          <div className="flex items-center gap-2 mb-2 text-sm">
            <MapPin size={14} className="text-muted" />
            <span className="text-muted truncate">{equipment.currentJob}</span>
          </div>
        )}

        {equipment.nextMaintenanceDate && (
          <div className={cn(
            'flex items-center gap-2 text-sm',
            maintenanceOverdue ? 'text-red-600' : 'text-muted'
          )}>
            <Wrench size={14} />
            <span>
              {maintenanceOverdue ? 'Maintenance overdue' : `Next: ${formatDate(equipment.nextMaintenanceDate)}`}
            </span>
            {maintenanceOverdue && <AlertTriangle size={14} />}
          </div>
        )}

        {equipment.currentValue && (
          <div className="mt-3 pt-3 border-t border-main">
            <p className="text-lg font-semibold text-main">{formatCurrency(equipment.currentValue)}</p>
            <p className="text-xs text-muted">Current value</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function EquipmentDetailModal({ equipment, onClose }: { equipment: Equipment; onClose: () => void }) {
  const config = statusConfig[equipment.status];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-semibold text-main">{equipment.name}</h2>
                <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                  {config.label}
                </span>
              </div>
              {equipment.make && equipment.model && (
                <p className="text-muted">{equipment.year} {equipment.make} {equipment.model}</p>
              )}
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Details Grid */}
          <div className="grid grid-cols-2 gap-4">
            {equipment.serialNumber && (
              <div>
                <p className="text-sm text-muted mb-1">Serial Number</p>
                <p className="font-mono text-main">{equipment.serialNumber}</p>
              </div>
            )}
            {equipment.licensePlate && (
              <div>
                <p className="text-sm text-muted mb-1">License Plate</p>
                <p className="font-mono text-main">{equipment.licensePlate}</p>
              </div>
            )}
            {equipment.assignedTo && (
              <div>
                <p className="text-sm text-muted mb-1">Assigned To</p>
                <p className="text-main">{equipment.assignedTo}</p>
              </div>
            )}
            {equipment.currentJob && (
              <div>
                <p className="text-sm text-muted mb-1">Current Job</p>
                <p className="text-main">{equipment.currentJob}</p>
              </div>
            )}
          </div>

          {/* Maintenance */}
          <div className="p-4 bg-secondary rounded-lg">
            <h3 className="font-medium text-main mb-3">Maintenance</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted mb-1">Last Service</p>
                <p className="text-main">{equipment.lastMaintenanceDate ? formatDate(equipment.lastMaintenanceDate) : 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-muted mb-1">Next Service</p>
                <p className={cn(
                  equipment.nextMaintenanceDate && new Date(equipment.nextMaintenanceDate) < new Date() ? 'text-red-600 font-medium' : 'text-main'
                )}>
                  {equipment.nextMaintenanceDate ? formatDate(equipment.nextMaintenanceDate) : 'N/A'}
                </p>
              </div>
            </div>
          </div>

          {/* Financial */}
          <div className="grid grid-cols-3 gap-4">
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">{formatCurrency(equipment.purchasePrice || 0)}</p>
              <p className="text-sm text-muted">Purchase Price</p>
            </div>
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">{formatCurrency(equipment.currentValue || 0)}</p>
              <p className="text-sm text-muted">Current Value</p>
            </div>
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">
                {equipment.purchaseDate ? formatDate(equipment.purchaseDate) : 'N/A'}
              </p>
              <p className="text-sm text-muted">Purchase Date</p>
            </div>
          </div>

          {equipment.notes && (
            <div>
              <p className="text-sm text-muted mb-1">Notes</p>
              <p className="text-main">{equipment.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            <Button className="flex-1">
              <Wrench size={16} />
              Log Maintenance
            </Button>
            <Button variant="secondary">
              <User size={16} />
              Assign
            </Button>
            <Button variant="ghost">
              <FileText size={16} />
              History
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function AddEquipmentModal({ onClose }: { onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Equipment</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Name *" placeholder="Work Van #1" />
          <Select
            label="Type"
            options={[
              { value: 'vehicle', label: 'Vehicle' },
              { value: 'tool', label: 'Tool' },
              { value: 'equipment', label: 'Equipment' },
            ]}
          />
          <div className="grid grid-cols-3 gap-4">
            <Input label="Make" placeholder="Ford" />
            <Input label="Model" placeholder="Transit" />
            <Input label="Year" type="number" placeholder="2022" />
          </div>
          <Input label="Serial Number / VIN" placeholder="Optional" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Purchase Price" type="number" placeholder="0.00" />
            <Input label="Current Value" type="number" placeholder="0.00" />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
            <Button className="flex-1"><Plus size={16} />Add Equipment</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
