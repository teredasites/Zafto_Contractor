'use client';

import { useState, useEffect } from 'react';
import {
  Plus,
  Wrench,
  AlertTriangle,
  MapPin,
  CheckCircle,
  X,
  FileText,
  DollarSign,
  Wind,
  Thermometer,
  Droplets,
  Zap,
  Eye,
  ScanLine,
  Fan,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, formatDateTime, cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import { useRestorationTools } from '@/lib/hooks/use-restoration-tools';
import { useTranslation } from '@/lib/translations';
import type { RestorationEquipmentWithJob } from '@/lib/hooks/use-restoration-tools';
import { EQUIPMENT_TYPE_LABELS } from '@/lib/hooks/mappers';
import type { EquipmentStatus, EquipmentType } from '@/types';

type RestorationStatus = 'deployed' | 'removed' | 'maintenance' | 'lost';

const statusConfig: Record<RestorationStatus, { label: string; color: string; bgColor: string }> = {
  deployed: { label: 'Deployed', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  removed: { label: 'Removed', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  maintenance: { label: 'Maintenance', color: 'text-amber-700 dark:text-amber-300', bgColor: 'bg-amber-100 dark:bg-amber-900/30' },
  lost: { label: 'Lost', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const typeOptions = [
  { value: 'all', label: 'All Types' },
  ...Object.entries(EQUIPMENT_TYPE_LABELS).map(([value, label]) => ({ value, label })),
];

const statusOptions = [
  { value: 'all', label: 'All Statuses' },
  { value: 'deployed', label: 'Deployed' },
  { value: 'removed', label: 'Removed' },
  { value: 'maintenance', label: 'Maintenance' },
  { value: 'lost', label: 'Lost' },
];

function getEquipmentIcon(type: string) {
  switch (type) {
    case 'dehumidifier': return <Droplets size={20} />;
    case 'air_mover': return <Wind size={20} />;
    case 'air_scrubber': return <Fan size={20} />;
    case 'heater': return <Thermometer size={20} />;
    case 'moisture_meter': return <Zap size={20} />;
    case 'thermal_camera': return <Eye size={20} />;
    case 'hydroxyl_generator': return <Wind size={20} />;
    case 'negative_air_machine': return <ScanLine size={20} />;
    default: return <Wrench size={20} />;
  }
}

export default function EquipmentPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedEquipment, setSelectedEquipment] = useState<RestorationEquipmentWithJob | null>(null);
  const { equipment, activeEquipment, stats, loading, updateEquipment, addEquipment } = useRestorationTools();

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-5 w-32 mb-3" /><div className="skeleton h-3 w-24 mb-2" /><div className="skeleton h-3 w-20" /></div>)}
        </div>
      </div>
    );
  }

  const filteredEquipment = equipment.filter((eq) => {
    const matchesSearch =
      (EQUIPMENT_TYPE_LABELS[eq.equipmentType] || eq.equipmentType).toLowerCase().includes(search.toLowerCase()) ||
      (eq.make || '').toLowerCase().includes(search.toLowerCase()) ||
      (eq.model || '').toLowerCase().includes(search.toLowerCase()) ||
      eq.areaDeployed.toLowerCase().includes(search.toLowerCase()) ||
      eq.jobName.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || eq.equipmentType === typeFilter;
    const matchesStatus = statusFilter === 'all' || eq.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  // Stats
  const totalEquipment = equipment.length;
  const deployedCount = activeEquipment.length;
  const maintenanceCount = equipment.filter((e) => e.status === 'maintenance').length;
  const totalDailyRate = activeEquipment.reduce((sum, e) => sum + e.dailyRate, 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('equipment.title')}</h1>
          <p className="text-muted mt-1">{t('equipment.manageDesc')}</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          {t('equipment.addEquipment')}
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Wrench size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalEquipment}</p>
                <p className="text-sm text-muted">{t('equipment.totalItems')}</p>
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
                <p className="text-2xl font-semibold text-main">{deployedCount}</p>
                <p className="text-sm text-muted">{t('equipment.deployed')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className={maintenanceCount > 0 ? 'border-amber-500' : ''}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <AlertTriangle size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{maintenanceCount}</p>
                <p className="text-sm text-muted">{t('equipment.maintenance')}</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalDailyRate)}</p>
                <p className="text-sm text-muted">{t('equipment.dailyRate')}</p>
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
          placeholder={t('equipment.searchEquipment')}
          className="sm:w-80"
        />
        <Select
          options={typeOptions}
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="sm:w-48"
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

      {filteredEquipment.length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <Wrench size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('equipment.noEquipment')}</h3>
            <p className="text-muted mb-4">{t('equipment.noEquipmentDesc')}</p>
            <Button onClick={() => setShowAddModal(true)}>
              <Plus size={16} />{t('equipment.addEquipment')}
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Add Modal */}
      {showAddModal && (
        <AddEquipmentModal onClose={() => setShowAddModal(false)} onAdd={addEquipment} />
      )}

      {/* Detail Modal */}
      {selectedEquipment && (
        <EquipmentDetailModal
          equipment={selectedEquipment}
          onClose={() => setSelectedEquipment(null)}
          onUpdateStatus={async (id, status) => {
            await updateEquipment(id, {
              status: status as EquipmentStatus,
              removedAt: status === 'removed' ? new Date().toISOString() : undefined,
            });
            setSelectedEquipment(null);
          }}
        />
      )}
    </div>
  );
}

function EquipmentCard({ equipment, onClick }: { equipment: RestorationEquipmentWithJob; onClick: () => void }) {
  const { t } = useTranslation();
  const config = statusConfig[equipment.status as RestorationStatus] || statusConfig.deployed;

  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onClick}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-secondary rounded-lg">
              {getEquipmentIcon(equipment.equipmentType)}
            </div>
            <div>
              <h3 className="font-medium text-main">
                {EQUIPMENT_TYPE_LABELS[equipment.equipmentType] || equipment.equipmentType}
              </h3>
              {equipment.make && equipment.model && (
                <p className="text-sm text-muted">{equipment.make} {equipment.model}</p>
              )}
            </div>
          </div>
          <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
            {config.label}
          </span>
        </div>

        {equipment.jobName && (
          <div className="flex items-center gap-2 mb-2 text-sm">
            <FileText size={14} className="text-muted" />
            <span className="text-main truncate">{equipment.jobName}</span>
          </div>
        )}

        {equipment.areaDeployed && (
          <div className="flex items-center gap-2 mb-2 text-sm">
            <MapPin size={14} className="text-muted" />
            <span className="text-muted truncate">{equipment.areaDeployed}</span>
          </div>
        )}

        {equipment.serialNumber && (
          <div className="text-xs text-muted font-mono mb-2">
            S/N: {equipment.serialNumber}
          </div>
        )}

        <div className="mt-3 pt-3 border-t border-main flex items-center justify-between">
          <div>
            <p className="text-lg font-semibold text-main">{formatCurrency(equipment.dailyRate)}</p>
            <p className="text-xs text-muted">per day</p>
          </div>
          <div className="text-right">
            <p className="text-xs text-muted">{t('equipment.deployed')}</p>
            <p className="text-sm text-main">{formatDate(equipment.deployedAt)}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function EquipmentDetailModal({
  equipment,
  onClose,
  onUpdateStatus,
}: {
  equipment: RestorationEquipmentWithJob;
  onClose: () => void;
  onUpdateStatus: (id: string, status: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const config = statusConfig[equipment.status as RestorationStatus] || statusConfig.deployed;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-semibold text-main">
                  {EQUIPMENT_TYPE_LABELS[equipment.equipmentType] || equipment.equipmentType}
                </h2>
                <span className={cn('px-2 py-1 rounded-full text-xs font-medium', config.bgColor, config.color)}>
                  {config.label}
                </span>
              </div>
              {equipment.make && equipment.model && (
                <p className="text-muted">{equipment.make} {equipment.model}</p>
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
                <p className="text-sm text-muted mb-1">{t('common.serialNumber')}</p>
                <p className="font-mono text-main">{equipment.serialNumber}</p>
              </div>
            )}
            {equipment.assetTag && (
              <div>
                <p className="text-sm text-muted mb-1">{t('common.assetTag')}</p>
                <p className="font-mono text-main">{equipment.assetTag}</p>
              </div>
            )}
            {equipment.jobName && (
              <div>
                <p className="text-sm text-muted mb-1">{t('common.job')}</p>
                <p className="text-main">{equipment.jobName}</p>
              </div>
            )}
            {equipment.areaDeployed && (
              <div>
                <p className="text-sm text-muted mb-1">{t('common.areaDeployed')}</p>
                <p className="text-main">{equipment.areaDeployed}</p>
              </div>
            )}
          </div>

          {/* Deployment Info */}
          <div className="p-4 bg-secondary rounded-lg">
            <h3 className="font-medium text-main mb-3">{t('common.deployment')}</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted mb-1">{t('common.deployedAt')}</p>
                <p className="text-main">{formatDateTime(equipment.deployedAt)}</p>
              </div>
              <div>
                <p className="text-sm text-muted mb-1">{t('common.removedAt')}</p>
                <p className={cn(equipment.removedAt ? 'text-main' : 'text-muted')}>
                  {equipment.removedAt ? formatDateTime(equipment.removedAt) : 'Still deployed'}
                </p>
              </div>
            </div>
          </div>

          {/* Financial */}
          <div className="grid grid-cols-2 gap-4">
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">{formatCurrency(equipment.dailyRate)}</p>
              <p className="text-sm text-muted">{t('common.dailyRate')}</p>
            </div>
            <div className="text-center p-4 bg-secondary rounded-lg">
              <p className="text-2xl font-semibold text-main">
                {equipment.totalDays != null ? equipment.totalDays : '--'}
              </p>
              <p className="text-sm text-muted">{t('common.daysDeployed')}</p>
            </div>
          </div>

          {equipment.notes && (
            <div>
              <p className="text-sm text-muted mb-1">{t('common.notes')}</p>
              <p className="text-main">{equipment.notes}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            {equipment.status === 'deployed' && (
              <Button className="flex-1" onClick={() => onUpdateStatus(equipment.id, 'removed')}>
                <X size={16} />
                Remove Equipment
              </Button>
            )}
            {equipment.status === 'removed' && (
              <Button className="flex-1" onClick={() => onUpdateStatus(equipment.id, 'deployed')}>
                <CheckCircle size={16} />
                Re-Deploy
              </Button>
            )}
            <Button
              variant="secondary"
              onClick={() => onUpdateStatus(equipment.id, 'maintenance')}
              disabled={equipment.status === 'maintenance'}
            >
              <Wrench size={16} />
              Maintenance
            </Button>
            <Button variant="ghost" onClick={onClose}>
              Close
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function AddEquipmentModal({ onClose, onAdd }: {
  onClose: () => void;
  onAdd: (input: {
    jobId: string;
    claimId?: string;
    equipmentType: EquipmentType;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    areaDeployed: string;
    dailyRate: number;
    notes?: string;
  }) => Promise<string>;
}) {
  const { t } = useTranslation();
  const [equipmentType, setEquipmentType] = useState<string>('dehumidifier');
  const [make, setMake] = useState('');
  const [model, setModel] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [assetTag, setAssetTag] = useState('');
  const [areaDeployed, setAreaDeployed] = useState('');
  const [dailyRate, setDailyRate] = useState('');
  const [notes, setNotes] = useState('');
  const [jobId, setJobId] = useState('');
  const [jobs, setJobs] = useState<Array<{ id: string; title: string }>>([]);
  const [jobsLoading, setJobsLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Fetch active jobs for the selector
  useEffect(() => {
    const fetchJobs = async () => {
      try {
        const supabase = getSupabase();
        const { data, error: err } = await supabase
          .from('jobs')
          .select('id, title')
          .is('deleted_at', null)
          .not('status', 'in', '("cancelled","completed")')
          .order('created_at', { ascending: false })
          .limit(200);
        if (!err && data) {
          setJobs(data.map((j: Record<string, unknown>) => ({ id: j.id as string, title: (j.title as string) || 'Untitled Job' })));
        }
      } catch {
        // Non-critical
      } finally {
        setJobsLoading(false);
      }
    };
    fetchJobs();
  }, []);

  const handleSubmit = async () => {
    setFormError(null);

    // Validation
    if (!jobId) { setFormError('Please select a job.'); return; }
    if (!areaDeployed.trim()) { setFormError('Area Deployed is required.'); return; }
    const rate = parseFloat(dailyRate);
    if (isNaN(rate) || rate < 0) { setFormError('Please enter a valid daily rate.'); return; }

    try {
      setSaving(true);
      await onAdd({
        jobId,
        equipmentType: equipmentType as EquipmentType,
        make: make.trim() || undefined,
        model: model.trim() || undefined,
        serialNumber: serialNumber.trim() || undefined,
        assetTag: assetTag.trim() || undefined,
        areaDeployed: areaDeployed.trim(),
        dailyRate: rate,
        notes: notes.trim() || undefined,
      });
      onClose();
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Failed to add equipment';
      setFormError(msg);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{t('common.addEquipment')}</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Job Selector */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Assign to Job *</label>
            <select
              value={jobId}
              onChange={(e) => setJobId(e.target.value)}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
            >
              <option value="">{jobsLoading ? 'Loading jobs...' : 'Select a job...'}</option>
              {jobs.map((j) => (
                <option key={j.id} value={j.id}>{j.title}</option>
              ))}
            </select>
          </div>

          {/* Equipment Type */}
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Equipment Type *</label>
            <select
              value={equipmentType}
              onChange={(e) => setEquipmentType(e.target.value)}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
            >
              {Object.entries(EQUIPMENT_TYPE_LABELS).map(([value, label]) => (
                <option key={value} value={value}>{label}</option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Input label={t('fleet.make')} placeholder="Dri-Eaz" value={make} onChange={(e) => setMake(e.target.value)} />
            <Input label={t('fleet.model')} placeholder="LGR 3500i" value={model} onChange={(e) => setModel(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label={t('common.serialNumber')} placeholder={t('common.optional')} value={serialNumber} onChange={(e) => setSerialNumber(e.target.value)} />
            <Input label="Asset Tag" placeholder={t('common.optional')} value={assetTag} onChange={(e) => setAssetTag(e.target.value)} />
          </div>
          <Input label="Area Deployed *" placeholder="Living Room - East Wall" value={areaDeployed} onChange={(e) => setAreaDeployed(e.target.value)} />
          <Input label="Daily Rate ($)" type="number" placeholder="0.00" value={dailyRate} onChange={(e) => setDailyRate(e.target.value)} />
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">{t('common.notes')}</label>
            <textarea
              rows={2}
              placeholder="Additional notes..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
            />
          </div>

          {formError && (
            <div className="flex items-center gap-2 p-3 rounded-lg bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800">
              <AlertTriangle size={16} className="text-red-500 flex-shrink-0" />
              <p className="text-sm text-red-700 dark:text-red-300">{formError}</p>
            </div>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving}>
              {saving ? (
                <span className="flex items-center gap-2">
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Saving...
                </span>
              ) : (
                <><Plus size={16} />{t('common.addEquipment')}</>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
