'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft,
  Wrench,
  Plus,
  X,
  Wind,
  Droplets,
  Thermometer,
  Fan,
  Eye,
  ScanLine,
  Calculator,
  CheckCircle,
  AlertTriangle,
  MapPin,
  DollarSign,
  Calendar,
  Package,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input, Select } from '@/components/ui/input';
import { cn, formatCurrency, formatDate, formatDateTime } from '@/lib/utils';
import {
  useEquipmentDeployments,
  type EquipmentDeploymentData,
  type EquipmentCalculationData,
  type EquipmentType,
} from '@/lib/hooks/use-equipment-deployments';
import { useEquipmentInventory } from '@/lib/hooks/use-equipment-inventory';
import { useTranslation } from '@/lib/translations';

// ============================================================================
// CONSTANTS
// ============================================================================

const EQUIPMENT_LABELS: Record<string, string> = {
  dehumidifier: 'Dehumidifier',
  air_mover: 'Air Mover',
  air_scrubber: 'Air Scrubber',
  heater: 'Heater',
  moisture_meter: 'Moisture Meter',
  thermal_camera: 'Thermal Camera',
  hydroxyl_generator: 'Hydroxyl Generator',
  negative_air_machine: 'Negative Air Machine',
  injectidry: 'Injectidry',
  other: 'Other',
};

const STATUS_CONFIG: Record<string, { label: string; variant: 'success' | 'info' | 'warning' | 'error' }> = {
  deployed: { label: 'Deployed', variant: 'success' },
  removed: { label: 'Removed', variant: 'info' },
  maintenance: { label: 'Maintenance', variant: 'warning' },
  lost: { label: 'Lost', variant: 'error' },
};

function getEquipmentIcon(type: string, size = 16) {
  switch (type) {
    case 'dehumidifier': return <Droplets size={size} />;
    case 'air_mover': return <Wind size={size} />;
    case 'air_scrubber': return <Fan size={size} />;
    case 'heater': return <Thermometer size={size} />;
    case 'thermal_camera': return <Eye size={size} />;
    case 'negative_air_machine': return <ScanLine size={size} />;
    default: return <Wrench size={size} />;
  }
}

// ============================================================================
// PAGE
// ============================================================================

export default function JobEquipmentPage() {
  const { t } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const jobId = params.id as string;

  const { deployments, calculations, summary, loading, error, deployEquipment, removeEquipment } = useEquipmentDeployments(jobId);
  const { items: inventoryItems } = useEquipmentInventory();

  const [activeTab, setActiveTab] = useState<'deployed' | 'calculator' | 'history'>('deployed');
  const [showDeployModal, setShowDeployModal] = useState(false);
  const [showCalcModal, setShowCalcModal] = useState(false);

  if (loading) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="skeleton h-8 w-8 rounded" />
          <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="space-y-6">
        <button onClick={() => router.back()} className="flex items-center gap-2 text-muted hover:text-main transition-colors">
          <ArrowLeft size={18} /><span>{t('common.backToJob')}</span>
        </button>
        <Card>
          <CardContent className="p-12 text-center">
            <AlertTriangle size={48} className="mx-auto text-red-500 mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">{t('common.failedToLoadEquipment')}</h3>
            <p className="text-muted">{error}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  const deployed = deployments.filter(d => d.status === 'deployed');
  const removed = deployments.filter(d => d.status === 'removed');
  const availableInventory = inventoryItems.filter(i => i.status === 'available');

  const tabs = [
    { key: 'deployed' as const, label: 'Deployed', count: deployed.length },
    { key: 'calculator' as const, label: 'IICRC Calculator', count: calculations.length },
    { key: 'history' as const, label: 'History', count: removed.length },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="p-2 hover:bg-surface-hover rounded-lg transition-colors">
            <ArrowLeft size={18} className="text-muted" />
          </button>
          <div>
            <h1 className="text-2xl font-semibold text-main">{t('jobsEquipment.title')}</h1>
            <p className="text-muted mt-0.5">IICRC-compliant deployment tracking and billing</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={() => setShowCalcModal(true)}>
            <Calculator size={16} />
            Run Calculator
          </Button>
          <Button onClick={() => setShowDeployModal(true)}>
            <Plus size={16} />
            Deploy Equipment
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <CheckCircle size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{summary.totalDeployed}</p>
                <p className="text-sm text-muted">{t('common.active')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Wind size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">
                  {summary.dehumidifiers}D / {summary.airMovers}AM / {summary.airScrubbers}AS
                </p>
                <p className="text-sm text-muted">Dehu / Movers / Scrubbers</p>
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
                <p className="text-2xl font-semibold text-main">{formatCurrency(summary.dailyRateTotal)}</p>
                <p className="text-sm text-muted">Daily Rate</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <Calendar size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(summary.totalBillableAmount)}</p>
                <p className="text-sm text-muted">Total Billable</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-main">
        {tabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={cn(
              'px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors',
              activeTab === tab.key
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-muted hover:text-main'
            )}
          >
            {tab.label}
            {tab.count > 0 && (
              <span className="ml-2 text-xs bg-surface-hover px-1.5 py-0.5 rounded-full">{tab.count}</span>
            )}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeTab === 'deployed' && (
        <DeployedTab
          deployments={deployed}
          onRemove={async (id) => { await removeEquipment(id); }}
        />
      )}
      {activeTab === 'calculator' && (
        <CalculatorTab calculations={calculations} />
      )}
      {activeTab === 'history' && (
        <HistoryTab deployments={removed} />
      )}

      {/* Deploy Modal */}
      {showDeployModal && (
        <DeployEquipmentModal
          availableInventory={availableInventory}
          onClose={() => setShowDeployModal(false)}
          onDeploy={async (input) => {
            await deployEquipment(input);
            setShowDeployModal(false);
          }}
        />
      )}

      {/* Calculator Modal */}
      {showCalcModal && (
        <RunCalculatorModal
          jobId={jobId}
          onClose={() => setShowCalcModal(false)}
        />
      )}
    </div>
  );
}

// ============================================================================
// DEPLOYED TAB
// ============================================================================

function DeployedTab({
  deployments,
  onRemove,
}: {
  deployments: EquipmentDeploymentData[];
  onRemove: (id: string) => Promise<void>;
}) {
  const [removing, setRemoving] = useState<string | null>(null);

  if (deployments.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <Wrench size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">No equipment deployed</h3>
          <p className="text-muted">Deploy dehumidifiers, air movers, and other equipment to this job.</p>
        </CardContent>
      </Card>
    );
  }

  // Group by area
  const byArea = deployments.reduce<Record<string, EquipmentDeploymentData[]>>((acc, d) => {
    const area = d.areaDeployed || 'Unassigned';
    if (!acc[area]) acc[area] = [];
    acc[area].push(d);
    return acc;
  }, {});

  return (
    <div className="space-y-4">
      {Object.entries(byArea).map(([area, items]) => (
        <Card key={area}>
          <CardHeader className="pb-3">
            <div className="flex items-center gap-2">
              <MapPin size={16} className="text-muted" />
              <CardTitle className="text-base">{area}</CardTitle>
              <Badge variant="secondary">{items.length} items</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <div className="divide-y divide-main">
              {items.map((d) => {
                const config = STATUS_CONFIG[d.status] || STATUS_CONFIG.deployed;
                return (
                  <div key={d.id} className="py-3 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-secondary rounded-lg">
                        {getEquipmentIcon(d.equipmentType)}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-main">
                            {EQUIPMENT_LABELS[d.equipmentType] || d.equipmentType}
                          </span>
                          <Badge variant={config.variant}>{config.label}</Badge>
                          {d.calculatedByFormula && (
                            <Badge variant="purple">IICRC</Badge>
                          )}
                        </div>
                        <div className="flex items-center gap-3 text-sm text-muted mt-0.5">
                          {d.make && d.model && <span>{d.make} {d.model}</span>}
                          {d.serialNumber && <span className="font-mono">S/N: {d.serialNumber}</span>}
                          {d.roomName && <span>{d.roomName}</span>}
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <p className="font-semibold text-main">{formatCurrency(d.dailyRate)}/day</p>
                        <p className="text-xs text-muted">{d.billableDays}d = {formatCurrency(d.billableAmount)}</p>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={removing === d.id}
                        onClick={async () => {
                          setRemoving(d.id);
                          try { await onRemove(d.id); } finally { setRemoving(null); }
                        }}
                      >
                        <X size={14} />
                        Remove
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

// ============================================================================
// CALCULATOR TAB
// ============================================================================

function CalculatorTab({ calculations }: { calculations: EquipmentCalculationData[] }) {
  const [expandedRoom, setExpandedRoom] = useState<string | null>(null);

  if (calculations.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <Calculator size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">No calculations yet</h3>
          <p className="text-muted">Run the IICRC S500 calculator to determine equipment requirements per room.</p>
        </CardContent>
      </Card>
    );
  }

  const totals = {
    dehu: calculations.reduce((s, c) => s + c.dehuUnitsRequired, 0),
    am: calculations.reduce((s, c) => s + c.amUnitsRequired, 0),
    scrubber: calculations.reduce((s, c) => s + c.scrubberUnitsRequired, 0),
    sqft: calculations.reduce((s, c) => s + c.floorSqft, 0),
  };

  return (
    <div className="space-y-4">
      {/* Totals Summary */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3 text-center">
          <p className="text-2xl font-bold text-blue-700 dark:text-blue-300">{totals.dehu}</p>
          <p className="text-xs text-blue-600 dark:text-blue-400">Dehumidifiers</p>
        </div>
        <div className="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-lg p-3 text-center">
          <p className="text-2xl font-bold text-emerald-700 dark:text-emerald-300">{totals.am}</p>
          <p className="text-xs text-emerald-600 dark:text-emerald-400">Air Movers</p>
        </div>
        <div className="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-3 text-center">
          <p className="text-2xl font-bold text-purple-700 dark:text-purple-300">{totals.scrubber}</p>
          <p className="text-xs text-purple-600 dark:text-purple-400">Air Scrubbers</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-900/20 border border-gray-200 dark:border-gray-700 rounded-lg p-3 text-center">
          <p className="text-2xl font-bold text-main">{totals.sqft.toFixed(0)}</p>
          <p className="text-xs text-muted">Total Sq Ft</p>
        </div>
      </div>

      {/* Room Breakdown */}
      {calculations.map((calc) => (
        <Card key={calc.id}>
          <button
            className="w-full p-4 flex items-center justify-between text-left"
            onClick={() => setExpandedRoom(expandedRoom === calc.id ? null : calc.id)}
          >
            <div className="flex items-center gap-3">
              {expandedRoom === calc.id ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              <div>
                <span className="font-medium text-main">{calc.roomName}</span>
                <span className="text-sm text-muted ml-3">
                  Class {calc.waterClass} | {calc.floorSqft.toFixed(0)} SF | {calc.cubicFt.toFixed(0)} CF
                </span>
              </div>
            </div>
            <div className="flex items-center gap-4 text-sm">
              <span className="text-blue-600 dark:text-blue-400">{calc.dehuUnitsRequired}D</span>
              <span className="text-emerald-600 dark:text-emerald-400">{calc.amUnitsRequired}AM</span>
              <span className="text-purple-600 dark:text-purple-400">{calc.scrubberUnitsRequired}AS</span>
            </div>
          </button>
          {expandedRoom === calc.id && (
            <CardContent className="pt-0 pb-4 px-4">
              <div className="border-t border-main pt-4 space-y-3">
                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <p className="text-muted mb-1">Dimensions</p>
                    <p className="text-main">{calc.roomLengthFt}&apos; x {calc.roomWidthFt}&apos; x {calc.roomHeightFt}&apos;</p>
                  </div>
                  <div>
                    <p className="text-muted mb-1">Floor / Walls</p>
                    <p className="text-main">{calc.floorSqft.toFixed(0)} SF / {calc.wallLinearFt.toFixed(0)} LF</p>
                  </div>
                  <div>
                    <p className="text-muted mb-1">Volume</p>
                    <p className="text-main">{calc.cubicFt.toFixed(0)} CF</p>
                  </div>
                </div>

                {/* Actual vs Required */}
                <div className="bg-secondary rounded-lg p-3">
                  <p className="text-xs font-medium text-muted mb-2">ACTUAL vs REQUIRED</p>
                  <div className="grid grid-cols-3 gap-4 text-sm">
                    <div>
                      <p className="text-muted">Dehu</p>
                      <p className={cn('font-medium', calc.actualDehuPlaced >= calc.dehuUnitsRequired ? 'text-emerald-600' : 'text-red-600')}>
                        {calc.actualDehuPlaced} / {calc.dehuUnitsRequired}
                      </p>
                    </div>
                    <div>
                      <p className="text-muted">Air Movers</p>
                      <p className={cn('font-medium', calc.actualAmPlaced >= calc.amUnitsRequired ? 'text-emerald-600' : 'text-red-600')}>
                        {calc.actualAmPlaced} / {calc.amUnitsRequired}
                      </p>
                    </div>
                    <div>
                      <p className="text-muted">Scrubbers</p>
                      <p className={cn('font-medium', calc.actualScrubberPlaced >= calc.scrubberUnitsRequired ? 'text-emerald-600' : 'text-red-600')}>
                        {calc.actualScrubberPlaced} / {calc.scrubberUnitsRequired}
                      </p>
                    </div>
                  </div>
                  {calc.varianceNotes && (
                    <p className="text-xs text-muted mt-2 italic">{calc.varianceNotes}</p>
                  )}
                </div>
              </div>
            </CardContent>
          )}
        </Card>
      ))}
    </div>
  );
}

// ============================================================================
// HISTORY TAB
// ============================================================================

function HistoryTab({ deployments }: { deployments: EquipmentDeploymentData[] }) {
  const { t } = useTranslation();
  if (deployments.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <Package size={48} className="mx-auto text-muted mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">No removed equipment</h3>
          <p className="text-muted">Equipment removed from this job will appear here with billing history.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardContent className="p-0">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-main">
              <th className="text-left p-3 text-muted font-medium">{t('common.equipment')}</th>
              <th className="text-left p-3 text-muted font-medium">{t('common.area')}</th>
              <th className="text-left p-3 text-muted font-medium">Deployed</th>
              <th className="text-left p-3 text-muted font-medium">Removed</th>
              <th className="text-right p-3 text-muted font-medium">Days</th>
              <th className="text-right p-3 text-muted font-medium">{t('common.rate')}</th>
              <th className="text-right p-3 text-muted font-medium">{t('common.total')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-main">
            {deployments.map((d) => (
              <tr key={d.id} className="hover:bg-surface-hover transition-colors">
                <td className="p-3">
                  <div className="flex items-center gap-2">
                    {getEquipmentIcon(d.equipmentType, 14)}
                    <span className="text-main">{EQUIPMENT_LABELS[d.equipmentType]}</span>
                  </div>
                  {d.serialNumber && <p className="text-xs text-muted font-mono mt-0.5">S/N: {d.serialNumber}</p>}
                </td>
                <td className="p-3 text-muted">{d.areaDeployed}</td>
                <td className="p-3 text-muted">{formatDate(d.deployedAt)}</td>
                <td className="p-3 text-muted">{d.removedAt ? formatDate(d.removedAt) : '-'}</td>
                <td className="p-3 text-right text-main">{d.billableDays}</td>
                <td className="p-3 text-right text-muted">{formatCurrency(d.dailyRate)}</td>
                <td className="p-3 text-right font-medium text-main">{formatCurrency(d.billableAmount)}</td>
              </tr>
            ))}
          </tbody>
          <tfoot>
            <tr className="border-t-2 border-main font-medium">
              <td colSpan={4} className="p-3 text-main">Totals</td>
              <td className="p-3 text-right text-main">{deployments.reduce((s, d) => s + d.billableDays, 0)}</td>
              <td className="p-3 text-right"></td>
              <td className="p-3 text-right text-main">{formatCurrency(deployments.reduce((s, d) => s + d.billableAmount, 0))}</td>
            </tr>
          </tfoot>
        </table>
      </CardContent>
    </Card>
  );
}

// ============================================================================
// DEPLOY EQUIPMENT MODAL
// ============================================================================

function DeployEquipmentModal({
  availableInventory,
  onClose,
  onDeploy,
}: {
  availableInventory: { id: string; name: string; equipmentType: string; ahamPpd: number | null; ahamCfm: number | null; dailyRentalRate: number; serialNumber: string | null; assetTag: string | null; make: string | null; model: string | null }[];
  onClose: () => void;
  onDeploy: (input: {
    equipmentType: EquipmentType;
    areaDeployed: string;
    roomName?: string;
    placementLocation?: string;
    dailyRate: number;
    make?: string;
    model?: string;
    serialNumber?: string;
    assetTag?: string;
    ahamPpd?: number;
    ahamCfm?: number;
    equipmentInventoryId?: string;
  }) => Promise<void>;
}) {
  const { t } = useTranslation();
  const [source, setSource] = useState<'manual' | 'inventory'>('manual');
  const [inventoryId, setInventoryId] = useState('');
  const [equipmentType, setEquipmentType] = useState<EquipmentType>('dehumidifier');
  const [areaDeployed, setAreaDeployed] = useState('');
  const [roomName, setRoomName] = useState('');
  const [placementLocation, setPlacementLocation] = useState('');
  const [dailyRate, setDailyRate] = useState('');
  const [make, setMake] = useState('');
  const [model, setModel] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [assetTag, setAssetTag] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const selectedInventoryItem = availableInventory.find(i => i.id === inventoryId);

  const handleInventorySelect = (id: string) => {
    setInventoryId(id);
    const item = availableInventory.find(i => i.id === id);
    if (item) {
      setEquipmentType(item.equipmentType as EquipmentType);
      setDailyRate(String(item.dailyRentalRate));
      setMake(item.make || '');
      setModel(item.model || '');
      setSerialNumber(item.serialNumber || '');
      setAssetTag(item.assetTag || '');
    }
  };

  const handleSubmit = async () => {
    if (!areaDeployed.trim()) { setErr('Area deployed is required'); return; }
    if (!dailyRate || parseFloat(dailyRate) < 0) { setErr('Valid daily rate is required'); return; }
    setSubmitting(true);
    setErr(null);
    try {
      await onDeploy({
        equipmentType,
        areaDeployed: areaDeployed.trim(),
        roomName: roomName.trim() || undefined,
        placementLocation: placementLocation.trim() || undefined,
        dailyRate: parseFloat(dailyRate),
        make: make.trim() || undefined,
        model: model.trim() || undefined,
        serialNumber: serialNumber.trim() || undefined,
        assetTag: assetTag.trim() || undefined,
        ahamPpd: selectedInventoryItem?.ahamPpd ?? undefined,
        ahamCfm: selectedInventoryItem?.ahamCfm ?? undefined,
        equipmentInventoryId: inventoryId || undefined,
      });
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to deploy equipment');
    } finally {
      setSubmitting(false);
    }
  };

  const typeOptions = Object.entries(EQUIPMENT_LABELS).map(([value, label]) => ({ value, label }));
  const inventoryOptions = [
    { value: '', label: 'Select from inventory...' },
    ...availableInventory.map(i => ({ value: i.id, label: `${i.name}${i.assetTag ? ` (${i.assetTag})` : ''}` })),
  ];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Deploy Equipment</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Source Toggle */}
          <div className="flex gap-2">
            <button
              onClick={() => setSource('manual')}
              className={cn('flex-1 py-2 px-3 rounded-lg text-sm font-medium border transition-colors',
                source === 'manual' ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300' : 'border-main text-muted hover:text-main'
              )}
            >
              Manual Entry
            </button>
            <button
              onClick={() => setSource('inventory')}
              className={cn('flex-1 py-2 px-3 rounded-lg text-sm font-medium border transition-colors',
                source === 'inventory' ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300' : 'border-main text-muted hover:text-main'
              )}
            >
              From Inventory ({availableInventory.length})
            </button>
          </div>

          {source === 'inventory' && (
            <Select
              options={inventoryOptions}
              value={inventoryId}
              onChange={(e) => handleInventorySelect(e.target.value)}
              label="Select Equipment"
            />
          )}

          <Select
            options={typeOptions}
            value={equipmentType}
            onChange={(e) => setEquipmentType(e.target.value as EquipmentType)}
            label="Equipment Type"
            disabled={source === 'inventory' && !!inventoryId}
          />

          <Input label="Area Deployed *" value={areaDeployed} onChange={(e) => setAreaDeployed(e.target.value)} placeholder="Living Room" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="Room Name" value={roomName} onChange={(e) => setRoomName(e.target.value)} placeholder="Room 1" />
            <Input label="Placement" value={placementLocation} onChange={(e) => setPlacementLocation(e.target.value)} placeholder="Center of room" />
          </div>

          <Input label="Daily Rate ($) *" type="number" value={dailyRate} onChange={(e) => setDailyRate(e.target.value)} placeholder="0.00" />

          {source === 'manual' && (
            <>
              <div className="grid grid-cols-2 gap-4">
                <Input label="Make" value={make} onChange={(e) => setMake(e.target.value)} placeholder="Dri-Eaz" />
                <Input label="Model" value={model} onChange={(e) => setModel(e.target.value)} placeholder="LGR 3500i" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <Input label="Serial Number" value={serialNumber} onChange={(e) => setSerialNumber(e.target.value)} placeholder="Optional" />
                <Input label="Asset Tag" value={assetTag} onChange={(e) => setAssetTag(e.target.value)} placeholder="Optional" />
              </div>
            </>
          )}

          {err && (
            <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-700 dark:text-red-300">
              {err}
            </div>
          )}

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={submitting}>
              {submitting ? 'Deploying...' : 'Deploy'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// ============================================================================
// IICRC CALCULATOR MODAL
// ============================================================================

interface RoomCalcInput {
  roomName: string;
  lengthFt: string;
  widthFt: string;
  heightFt: string;
  waterClass: string;
}

function RunCalculatorModal({ jobId, onClose }: { jobId: string; onClose: () => void }) {
  const { t } = useTranslation();
  const [rooms, setRooms] = useState<RoomCalcInput[]>([
    { roomName: '', lengthFt: '', widthFt: '', heightFt: '8', waterClass: '2' },
  ]);
  const [results, setResults] = useState<CalculatorResult[] | null>(null);
  const [calculating, setCalculating] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const addRoom = () => {
    setRooms([...rooms, { roomName: '', lengthFt: '', widthFt: '', heightFt: '8', waterClass: '2' }]);
  };

  const updateRoom = (idx: number, field: keyof RoomCalcInput, value: string) => {
    const updated = [...rooms];
    updated[idx] = { ...updated[idx], [field]: value };
    setRooms(updated);
  };

  const removeRoom = (idx: number) => {
    if (rooms.length <= 1) return;
    setRooms(rooms.filter((_, i) => i !== idx));
  };

  const calculate = () => {
    setErr(null);
    const computed: CalculatorResult[] = [];
    for (const room of rooms) {
      if (!room.roomName.trim()) { setErr('All rooms need a name'); return; }
      const l = parseFloat(room.lengthFt);
      const w = parseFloat(room.widthFt);
      const h = parseFloat(room.heightFt);
      const wc = parseInt(room.waterClass);
      if (!l || !w || !h || l <= 0 || w <= 0 || h <= 0) { setErr(`Room "${room.roomName}": valid dimensions required`); return; }
      if (wc < 1 || wc > 4) { setErr(`Room "${room.roomName}": water class must be 1-4`); return; }

      const floorSqft = l * w;
      const wallLf = 2 * (l + w);
      const cubicFt = floorSqft * h;
      const ceilingSqft = floorSqft;

      // Dehumidifier
      const dehuFactor: Record<number, number> = { 1: 40, 2: 40, 3: 30, 4: 25 };
      const chartFactor = dehuFactor[wc] || 40;
      const ppdNeeded = cubicFt / chartFactor;
      const unitPpd = 70;
      const dehuUnits = Math.ceil(ppdNeeded / unitPpd);

      // Air Movers
      const amFloorDiv: Record<number, number> = { 1: 70, 2: 50, 3: 50, 4: 50 };
      const amCeilDiv: Record<number, number> = { 1: 150, 2: 150, 3: 100, 4: 100 };
      const amWall = wallLf / 14;
      const amFloor = floorSqft / (amFloorDiv[wc] || 50);
      const amCeiling = wc >= 3 ? ceilingSqft / (amCeilDiv[wc] || 100) : 0;
      const amUnits = Math.ceil(amWall + amFloor + amCeiling);

      // Air Scrubber
      const targetAch = 6;
      const scrubberCfm = 500;
      const cfmNeeded = (cubicFt * targetAch) / 60;
      const scrubberUnits = Math.ceil(cfmNeeded / scrubberCfm);

      computed.push({
        roomName: room.roomName,
        waterClass: wc,
        floorSqft,
        wallLf,
        cubicFt,
        dehuUnits,
        amUnits,
        scrubberUnits,
        dehuFormula: `${cubicFt.toFixed(0)} CF / ${chartFactor} = ${ppdNeeded.toFixed(1)} PPD / ${unitPpd} = ${dehuUnits}`,
        amFormula: `Wall: ${amWall.toFixed(1)} + Floor: ${amFloor.toFixed(1)}${amCeiling > 0 ? ` + Ceil: ${amCeiling.toFixed(1)}` : ''} = ${amUnits}`,
        scrubberFormula: `${cubicFt.toFixed(0)} CF x ${targetAch} ACH / 60 = ${cfmNeeded.toFixed(0)} CFM / ${scrubberCfm} = ${scrubberUnits}`,
      });
    }
    setResults(computed);
  };

  const saveResults = async () => {
    if (!results) return;
    setCalculating(true);
    setErr(null);
    try {
      const supabase = (await import('@/lib/supabase')).createClient();
      const token = (await supabase.auth.getSession()).data.session?.access_token;
      if (!token) throw new Error('Not authenticated');

      const resp = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/tpa-equipment-calculator`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          job_id: jobId,
          rooms: rooms.map(r => ({
            room_name: r.roomName,
            length_ft: parseFloat(r.lengthFt),
            width_ft: parseFloat(r.widthFt),
            height_ft: parseFloat(r.heightFt),
            water_class: parseInt(r.waterClass),
          })),
          save_results: true,
        }),
      });

      if (!resp.ok) {
        const body = await resp.json();
        throw new Error(body.error || 'Calculation failed');
      }

      onClose();
    } catch (e: unknown) {
      setErr(e instanceof Error ? e.message : 'Failed to save calculations');
    } finally {
      setCalculating(false);
    }
  };

  const waterClassOptions = [
    { value: '1', label: 'Class 1 — Least affected' },
    { value: '2', label: 'Class 2 — Significant' },
    { value: '3', label: 'Class 3 — Most severe' },
    { value: '4', label: 'Class 4 — Specialty' },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-3xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>IICRC S500 Equipment Calculator</CardTitle>
              <p className="text-sm text-muted mt-1">Enter room dimensions and water class to calculate required equipment</p>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {!results ? (
            <>
              {rooms.map((room, idx) => (
                <div key={idx} className="p-4 border border-main rounded-lg space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-muted">Room {idx + 1}</span>
                    {rooms.length > 1 && (
                      <button onClick={() => removeRoom(idx)} className="text-red-500 hover:text-red-700 text-sm">{t('common.remove')}</button>
                    )}
                  </div>
                  <Input label="Room Name" value={room.roomName} onChange={(e) => updateRoom(idx, 'roomName', e.target.value)} placeholder="Living Room" />
                  <div className="grid grid-cols-3 gap-3">
                    <Input label="Length (ft)" type="number" value={room.lengthFt} onChange={(e) => updateRoom(idx, 'lengthFt', e.target.value)} placeholder="0" />
                    <Input label="Width (ft)" type="number" value={room.widthFt} onChange={(e) => updateRoom(idx, 'widthFt', e.target.value)} placeholder="0" />
                    <Input label="Height (ft)" type="number" value={room.heightFt} onChange={(e) => updateRoom(idx, 'heightFt', e.target.value)} placeholder="8" />
                  </div>
                  <Select
                    options={waterClassOptions}
                    value={room.waterClass}
                    onChange={(e) => updateRoom(idx, 'waterClass', e.target.value)}
                    label="Water Class (IICRC S500)"
                  />
                </div>
              ))}

              <Button variant="secondary" onClick={addRoom} className="w-full">
                <Plus size={16} />Add Room
              </Button>

              {err && (
                <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-700 dark:text-red-300">
                  {err}
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
                <Button className="flex-1" onClick={calculate}>
                  <Calculator size={16} />Calculate
                </Button>
              </div>
            </>
          ) : (
            <>
              {/* Results View */}
              <div className="grid grid-cols-3 gap-3">
                <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-3 text-center">
                  <p className="text-2xl font-bold text-blue-700 dark:text-blue-300">
                    {results.reduce((s, r) => s + r.dehuUnits, 0)}
                  </p>
                  <p className="text-xs text-blue-600 dark:text-blue-400">Dehumidifiers</p>
                </div>
                <div className="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-lg p-3 text-center">
                  <p className="text-2xl font-bold text-emerald-700 dark:text-emerald-300">
                    {results.reduce((s, r) => s + r.amUnits, 0)}
                  </p>
                  <p className="text-xs text-emerald-600 dark:text-emerald-400">Air Movers</p>
                </div>
                <div className="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-3 text-center">
                  <p className="text-2xl font-bold text-purple-700 dark:text-purple-300">
                    {results.reduce((s, r) => s + r.scrubberUnits, 0)}
                  </p>
                  <p className="text-xs text-purple-600 dark:text-purple-400">Air Scrubbers</p>
                </div>
              </div>

              {results.map((r, idx) => (
                <div key={idx} className="p-4 border border-main rounded-lg space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-main">{r.roomName}</span>
                    <Badge variant="secondary">Class {r.waterClass}</Badge>
                  </div>
                  <p className="text-xs text-muted">{r.floorSqft.toFixed(0)} SF | {r.wallLf.toFixed(0)} LF | {r.cubicFt.toFixed(0)} CF</p>
                  <div className="space-y-1 text-sm">
                    <p><span className="text-muted">Dehu:</span> <span className="font-mono text-main">{r.dehuFormula}</span></p>
                    <p><span className="text-muted">Air Movers:</span> <span className="font-mono text-main">{r.amFormula}</span></p>
                    <p><span className="text-muted">Scrubbers:</span> <span className="font-mono text-main">{r.scrubberFormula}</span></p>
                  </div>
                </div>
              ))}

              {err && (
                <div className="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-sm text-red-700 dark:text-red-300">
                  {err}
                </div>
              )}

              <div className="flex items-center gap-3 pt-2">
                <Button variant="secondary" className="flex-1" onClick={() => setResults(null)}>
                  Edit Rooms
                </Button>
                <Button className="flex-1" onClick={saveResults} disabled={calculating}>
                  {calculating ? 'Saving...' : 'Save to Job'}
                </Button>
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

interface CalculatorResult {
  roomName: string;
  waterClass: number;
  floorSqft: number;
  wallLf: number;
  cubicFt: number;
  dehuUnits: number;
  amUnits: number;
  scrubberUnits: number;
  dehuFormula: string;
  amFormula: string;
  scrubberFormula: string;
}
