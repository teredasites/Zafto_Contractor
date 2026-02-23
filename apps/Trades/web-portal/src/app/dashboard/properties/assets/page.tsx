'use client';

import { useState, useEffect } from 'react';
import {
  Plus,
  Package,
  Wrench,
  Shield,
  Clock,
  ThermometerSun,
  Droplet,
  Zap,
  Home,
  Loader2,
  XCircle,
  ChevronDown,
  ChevronRight,
  Calendar,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useAssets } from '@/lib/hooks/use-assets';
import type { PropertyAssetData, AssetServiceRecordData } from '@/lib/hooks/pm-mappers';
import { useTranslation } from '@/lib/translations';

type AssetType = PropertyAssetData['assetType'];
type Condition = PropertyAssetData['condition'];

const conditionConfig: Record<Condition, { label: string; color: string; bgColor: string }> = {
  new: { label: 'New', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  excellent: { label: 'Excellent', color: 'text-emerald-700 dark:text-emerald-300', bgColor: 'bg-emerald-100 dark:bg-emerald-900/30' },
  good: { label: 'Good', color: 'text-blue-700 dark:text-blue-300', bgColor: 'bg-blue-100 dark:bg-blue-900/30' },
  fair: { label: 'Fair', color: 'text-yellow-700 dark:text-yellow-300', bgColor: 'bg-yellow-100 dark:bg-yellow-900/30' },
  poor: { label: 'Poor', color: 'text-orange-700 dark:text-orange-300', bgColor: 'bg-orange-100 dark:bg-orange-900/30' },
  replace_soon: { label: 'Replace Soon', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
  failed: { label: 'Failed', color: 'text-red-700 dark:text-red-300', bgColor: 'bg-red-100 dark:bg-red-900/30' },
};

const assetTypeLabels: Record<AssetType, string> = {
  hvac: 'HVAC',
  water_heater: 'Water Heater',
  appliance: 'Appliance',
  roof: 'Roof',
  plumbing: 'Plumbing',
  electrical_panel: 'Electrical Panel',
  flooring: 'Flooring',
  windows: 'Windows',
  doors: 'Doors',
  garage: 'Garage',
  other: 'Other',
};

function getAssetIcon(type: AssetType) {
  switch (type) {
    case 'hvac': return <ThermometerSun size={20} />;
    case 'water_heater': return <Droplet size={20} />;
    case 'electrical_panel': return <Zap size={20} />;
    case 'plumbing': return <Droplet size={20} />;
    case 'appliance': return <Package size={20} />;
    case 'roof':
    case 'windows':
    case 'doors':
    case 'garage':
      return <Home size={20} />;
    default: return <Wrench size={20} />;
  }
}

function isUnderWarranty(asset: PropertyAssetData): boolean {
  if (!asset.warrantyExpiry) return false;
  return new Date(asset.warrantyExpiry) > new Date();
}

function getAssetAge(asset: PropertyAssetData): string {
  if (!asset.installDate) return 'Unknown';
  const install = new Date(asset.installDate);
  const now = new Date();
  const years = Math.floor((now.getTime() - install.getTime()) / (365.25 * 24 * 60 * 60 * 1000));
  if (years === 0) return '< 1 year';
  return `${years} year${years !== 1 ? 's' : ''}`;
}

export default function AssetsPage() {
  const { t } = useTranslation();
  const { assets, loading, error, createAsset, getServiceRecords } = useAssets();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [conditionFilter, setConditionFilter] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [serviceRecords, setServiceRecords] = useState<AssetServiceRecordData[]>([]);
  const [recordsLoading, setRecordsLoading] = useState(false);
  const [showNewModal, setShowNewModal] = useState(false);

  useEffect(() => {
    if (!expandedId) {
      setServiceRecords([]);
      return;
    }

    let ignore = false;
    setRecordsLoading(true);

    const loadRecords = async () => {
      try {
        const records = await getServiceRecords(expandedId);
        if (!ignore) setServiceRecords(records);
      } catch {
        // silent
      } finally {
        if (!ignore) setRecordsLoading(false);
      }
    };

    loadRecords();
    return () => { ignore = true; };
  }, [expandedId, getServiceRecords]);

  if (loading && assets.length === 0) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-56" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" /></div>)}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {[...Array(6)].map((_, i) => <div key={i} className="bg-surface border border-main rounded-xl p-5"><div className="skeleton h-5 w-28 mb-3" /><div className="skeleton h-3 w-40 mb-2" /><div className="skeleton h-3 w-32" /></div>)}
        </div>
      </div>
    );
  }

  const filteredAssets = assets.filter((asset) => {
    const matchesSearch =
      (asset.manufacturer || '').toLowerCase().includes(search.toLowerCase()) ||
      (asset.model || '').toLowerCase().includes(search.toLowerCase()) ||
      (asset.propertyAddress || '').toLowerCase().includes(search.toLowerCase()) ||
      assetTypeLabels[asset.assetType].toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'all' || asset.assetType === typeFilter;
    const matchesCondition = conditionFilter === 'all' || asset.condition === conditionFilter;
    return matchesSearch && matchesType && matchesCondition;
  });

  const totalAssets = assets.length;
  const needsServiceCount = assets.filter((a) => {
    if (!a.nextServiceDue) return false;
    return new Date(a.nextServiceDue) <= new Date();
  }).length;
  const underWarrantyCount = assets.filter((a) => isUnderWarranty(a)).length;
  const avgAge = (() => {
    const withDates = assets.filter((a) => a.installDate);
    if (withDates.length === 0) return 'N/A';
    const totalYears = withDates.reduce((sum, a) => {
      const install = new Date(a.installDate!);
      const years = (new Date().getTime() - install.getTime()) / (365.25 * 24 * 60 * 60 * 1000);
      return sum + years;
    }, 0);
    const avg = totalYears / withDates.length;
    return avg < 1 ? '< 1 year' : `${avg.toFixed(1)} years`;
  })();

  const typeOptions = [
    { value: 'all', label: 'All Types' },
    ...Object.entries(assetTypeLabels).map(([k, v]) => ({ value: k, label: v })),
  ];

  const conditionOptions = [
    { value: 'all', label: 'All Conditions' },
    ...Object.entries(conditionConfig).map(([k, v]) => ({ value: k, label: v.label })),
  ];

  const serviceTypeLabels: Record<AssetServiceRecordData['serviceType'], string> = {
    preventive: 'Preventive',
    repair: 'Repair',
    replacement: 'Replacement',
    inspection: 'Inspection',
    emergency: 'Emergency',
  };

  return (
    <div className="space-y-8 animate-fade-in">
      <CommandPalette />

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3 text-sm text-red-700 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">Asset Health Dashboard</h1>
          <p className="text-muted mt-1">Track property assets, service schedules, and warranties</p>
        </div>
        <Button onClick={() => setShowNewModal(true)}>
          <Plus size={16} />
          Add Asset
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg"><Package size={20} className="text-blue-600 dark:text-blue-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{totalAssets}</p><p className="text-sm text-muted">Total Assets</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg"><Wrench size={20} className="text-red-600 dark:text-red-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{needsServiceCount}</p><p className="text-sm text-muted">Needing Service</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg"><Shield size={20} className="text-emerald-600 dark:text-emerald-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{underWarrantyCount}</p><p className="text-sm text-muted">Under Warranty</p></div>
        </div></CardContent></Card>
        <Card><CardContent className="p-4"><div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 dark:bg-purple-900/30 rounded-lg"><Clock size={20} className="text-purple-600 dark:text-purple-400" /></div>
          <div><p className="text-2xl font-semibold text-main">{avgAge}</p><p className="text-sm text-muted">Average Age</p></div>
        </div></CardContent></Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <SearchInput value={search} onChange={setSearch} placeholder="Search assets..." className="sm:w-80" />
        <Select options={typeOptions} value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)} className="sm:w-48" />
        <Select options={conditionOptions} value={conditionFilter} onChange={(e) => setConditionFilter(e.target.value)} className="sm:w-48" />
      </div>

      {/* Asset Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredAssets.map((asset) => {
          const cConfig = conditionConfig[asset.condition];
          const warranty = isUnderWarranty(asset);
          const needsService = asset.nextServiceDue && new Date(asset.nextServiceDue) <= new Date();
          const isExpanded = expandedId === asset.id;

          return (
            <Card
              key={asset.id}
              className={cn(
                'hover:border-accent/30 transition-colors cursor-pointer',
                needsService && 'border-red-200 dark:border-red-800/40'
              )}
              onClick={() => setExpandedId(isExpanded ? null : asset.id)}
            >
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className={cn('p-2 rounded-lg', cConfig.bgColor)}>
                      <span className={cConfig.color}>{getAssetIcon(asset.assetType)}</span>
                    </div>
                    <div>
                      <h3 className="font-medium text-main text-sm">{assetTypeLabels[asset.assetType]}</h3>
                      {(asset.manufacturer || asset.model) && (
                        <p className="text-xs text-muted">
                          {[asset.manufacturer, asset.model].filter(Boolean).join(' ')}
                        </p>
                      )}
                    </div>
                  </div>
                  <span className={cn('px-2 py-0.5 rounded-full text-[10px] font-semibold', cConfig.bgColor, cConfig.color)}>
                    {cConfig.label}
                  </span>
                </div>

                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-1.5 text-muted">
                    <Home size={13} />
                    <span className="truncate">{asset.propertyAddress || 'N/A'}</span>
                    {asset.unitNumber && <span className="text-xs">- Unit {asset.unitNumber}</span>}
                  </div>

                  {asset.lastServiceDate && (
                    <div className="flex items-center gap-1.5 text-muted">
                      <Wrench size={13} />
                      <span>Last service: {formatDate(asset.lastServiceDate)}</span>
                    </div>
                  )}

                  {asset.nextServiceDue && (
                    <div className={cn('flex items-center gap-1.5', needsService ? 'text-red-600 dark:text-red-400 font-medium' : 'text-muted')}>
                      <Calendar size={13} />
                      <span>Next service: {formatDate(asset.nextServiceDue)}</span>
                    </div>
                  )}

                  <div className="flex items-center justify-between pt-2 border-t border-main/50">
                    <div className="flex items-center gap-1.5">
                      <Clock size={13} className="text-muted" />
                      <span className="text-xs text-muted">Age: {getAssetAge(asset)}</span>
                    </div>
                    {warranty ? (
                      <span className="text-[10px] font-medium text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
                        <Shield size={11} />
                        Under Warranty
                      </span>
                    ) : asset.warrantyExpiry ? (
                      <span className="text-[10px] text-muted">Warranty Expired</span>
                    ) : null}
                  </div>
                </div>

                {/* Expanded: Service History */}
                {isExpanded && (
                  <div className="mt-4 pt-3 border-t border-main" onClick={(e) => e.stopPropagation()}>
                    <p className="text-xs text-muted uppercase tracking-wider mb-2">Service History</p>
                    {recordsLoading ? (
                      <div className="flex items-center justify-center py-4">
                        <Loader2 size={16} className="animate-spin text-muted" />
                      </div>
                    ) : serviceRecords.length === 0 ? (
                      <p className="text-xs text-muted text-center py-3">No service records</p>
                    ) : (
                      <div className="space-y-2">
                        {serviceRecords.slice(0, 5).map((record) => (
                          <div key={record.id} className="flex items-center justify-between p-2 bg-secondary rounded-lg text-xs">
                            <div>
                              <p className="font-medium text-main">{serviceTypeLabels[record.serviceType]}</p>
                              <p className="text-muted">{formatDate(record.serviceDate)}</p>
                            </div>
                            <div className="text-right">
                              {record.cost && <p className="font-medium text-main">{formatCurrency(record.cost)}</p>}
                              {record.performedByName && <p className="text-muted">{record.performedByName}</p>}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {asset.serialNumber && (
                      <div className="mt-2 pt-2 border-t border-main/50">
                        <p className="text-xs text-muted">S/N: {asset.serialNumber}</p>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filteredAssets.length === 0 && (
        <Card>
          <CardContent className="p-12 text-center">
            <Package size={48} className="mx-auto text-muted mb-4" />
            <h3 className="text-lg font-medium text-main mb-2">No assets found</h3>
            <p className="text-muted mb-4">Start tracking your property assets like HVAC systems, water heaters, and appliances.</p>
            <Button onClick={() => setShowNewModal(true)}>
              <Plus size={16} />
              Add Asset
            </Button>
          </CardContent>
        </Card>
      )}

      {/* New Asset Modal */}
      {showNewModal && (
        <NewAssetModal
          onClose={() => setShowNewModal(false)}
          onCreate={createAsset}
        />
      )}
    </div>
  );
}

function NewAssetModal({ onClose, onCreate }: {
  onClose: () => void;
  onCreate: (data: {
    propertyId: string;
    unitId?: string;
    assetType: PropertyAssetData['assetType'];
    manufacturer?: string;
    model?: string;
    serialNumber?: string;
    installDate?: string;
    purchasePrice?: number;
    warrantyExpiry?: string;
    expectedLifespanYears?: number;
    condition: PropertyAssetData['condition'];
    notes?: string;
  }) => Promise<string>;
}) {
  const [propertyId, setPropertyId] = useState('');
  const [unitId, setUnitId] = useState('');
  const [assetType, setAssetType] = useState<PropertyAssetData['assetType']>('hvac');
  const [manufacturer, setManufacturer] = useState('');
  const [model, setModel] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [installDate, setInstallDate] = useState('');
  const [purchasePrice, setPurchasePrice] = useState('');
  const [warrantyExpiry, setWarrantyExpiry] = useState('');
  const [expectedLifespan, setExpectedLifespan] = useState('');
  const [condition, setCondition] = useState<PropertyAssetData['condition']>('good');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);

  const handleSubmit = async () => {
    if (!propertyId.trim()) return;
    setSaving(true);
    try {
      await onCreate({
        propertyId: propertyId.trim(),
        unitId: unitId.trim() || undefined,
        assetType,
        manufacturer: manufacturer.trim() || undefined,
        model: model.trim() || undefined,
        serialNumber: serialNumber.trim() || undefined,
        installDate: installDate || undefined,
        purchasePrice: purchasePrice ? parseFloat(purchasePrice) : undefined,
        warrantyExpiry: warrantyExpiry || undefined,
        expectedLifespanYears: expectedLifespan ? parseInt(expectedLifespan) : undefined,
        condition,
        notes: notes.trim() || undefined,
      });
      onClose();
    } catch (e) {
      alert(e instanceof Error ? e.message : 'Failed to create asset');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Add Property Asset</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose}>
            <XCircle size={18} />
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Property ID *</label>
              <input
                type="text"
                value={propertyId}
                onChange={(e) => setPropertyId(e.target.value)}
                placeholder="Property ID"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Unit ID</label>
              <input
                type="text"
                value={unitId}
                onChange={(e) => setUnitId(e.target.value)}
                placeholder="Optional"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Asset Type *</label>
              <select
                value={assetType}
                onChange={(e) => setAssetType(e.target.value as PropertyAssetData['assetType'])}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              >
                {Object.entries(assetTypeLabels).map(([k, v]) => (
                  <option key={k} value={k}>{v}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Condition *</label>
              <select
                value={condition}
                onChange={(e) => setCondition(e.target.value as PropertyAssetData['condition'])}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              >
                {Object.entries(conditionConfig).map(([k, v]) => (
                  <option key={k} value={k}>{v.label}</option>
                ))}
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Manufacturer</label>
              <input
                type="text"
                value={manufacturer}
                onChange={(e) => setManufacturer(e.target.value)}
                placeholder="e.g. Carrier"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Model</label>
              <input
                type="text"
                value={model}
                onChange={(e) => setModel(e.target.value)}
                placeholder="Model number"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Serial Number</label>
            <input
              type="text"
              value={serialNumber}
              onChange={(e) => setSerialNumber(e.target.value)}
              placeholder="Serial number"
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Install Date</label>
              <input
                type="date"
                value={installDate}
                onChange={(e) => setInstallDate(e.target.value)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Purchase Price</label>
              <input
                type="number"
                value={purchasePrice}
                onChange={(e) => setPurchasePrice(e.target.value)}
                placeholder="0.00"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Warranty Expiry</label>
              <input
                type="date"
                value={warrantyExpiry}
                onChange={(e) => setWarrantyExpiry(e.target.value)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Expected Lifespan (years)</label>
              <input
                type="number"
                value={expectedLifespan}
                onChange={(e) => setExpectedLifespan(e.target.value)}
                placeholder="15"
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted focus:border-accent focus:ring-1 focus:ring-accent"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Additional notes..."
              rows={2}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none focus:border-accent focus:ring-1 focus:ring-accent"
            />
          </div>
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button className="flex-1" onClick={handleSubmit} disabled={saving || !propertyId.trim()}>
              {saving ? <Loader2 size={16} className="animate-spin" /> : <Plus size={16} />}
              {saving ? 'Adding...' : 'Add Asset'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
