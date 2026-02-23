'use client';

import { useState, useCallback, useMemo } from 'react';
import {
  Plus,
  Wrench,
  AlertTriangle,
  CheckCircle,
  X,
  Package,
  Clock,
  ArrowRightLeft,
  Search,
  RotateCcw,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { cn } from '@/lib/utils';
import {
  useEquipmentItems,
  useActiveCheckouts,
  createEquipmentItem,
  checkoutEquipment,
  checkinEquipment,
  updateEquipmentItem,
  deleteEquipmentItem,
  CATEGORY_LABELS,
  CONDITION_LABELS,
} from '@/lib/hooks/use-equipment-checkout';
import type {
  EquipmentItemData,
  EquipmentCheckoutData,
  EquipmentCategory,
  EquipmentCondition,
} from '@/lib/hooks/use-equipment-checkout';
import { useTranslation } from '@/lib/translations';

// ════════════════════════════════════════════════════════════════
// CONSTANTS
// ════════════════════════════════════════════════════════════════

type ViewTab = 'inventory' | 'active' | 'overdue';

const categoryOptions = [
  { value: 'all', label: 'All Categories' },
  ...Object.entries(CATEGORY_LABELS).map(([v, l]) => ({ value: v, label: l })),
];

const conditionOptions = [
  { value: 'all', label: 'All Conditions' },
  ...Object.entries(CONDITION_LABELS).map(([v, l]) => ({ value: v, label: l })),
];

function conditionColor(c: EquipmentCondition): string {
  switch (c) {
    case 'new': case 'good': return 'text-emerald-600 dark:text-emerald-400';
    case 'fair': return 'text-amber-600 dark:text-amber-400';
    case 'poor': case 'damaged': return 'text-red-600 dark:text-red-400';
    case 'retired': return 'text-zinc-500';
  }
}

function conditionBg(c: EquipmentCondition): string {
  switch (c) {
    case 'new': case 'good': return 'bg-emerald-100 dark:bg-emerald-900/30';
    case 'fair': return 'bg-amber-100 dark:bg-amber-900/30';
    case 'poor': case 'damaged': return 'bg-red-100 dark:bg-red-900/30';
    case 'retired': return 'bg-zinc-100 dark:bg-zinc-800/30';
  }
}

function categoryIcon(cat: EquipmentCategory) {
  switch (cat) {
    case 'hand_tool': return <Wrench size={16} />;
    case 'power_tool': return <Wrench size={16} />;
    case 'testing_equipment': return <Search size={16} />;
    case 'safety_equipment': return <AlertTriangle size={16} />;
    case 'vehicle_mounted': return <Package size={16} />;
    case 'specialty': return <Package size={16} />;
  }
}

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

export default function ToolCheckoutPage() {
  const { t } = useTranslation();
  const { items, loading: itemsLoading, error: itemsError, refetch: refetchItems } = useEquipmentItems();
  const { checkouts, overdueCheckouts, loading: checkoutsLoading, error: checkoutsError, refetch: refetchCheckouts } = useActiveCheckouts();

  const [tab, setTab] = useState<ViewTab>('inventory');
  const [search, setSearch] = useState('');
  const [catFilter, setCatFilter] = useState('all');
  const [condFilter, setCondFilter] = useState('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [checkoutItem, setCheckoutItem] = useState<EquipmentItemData | null>(null);
  const [checkinCheckout, setCheckinCheckout] = useState<EquipmentCheckoutData | null>(null);
  const [detailItem, setDetailItem] = useState<EquipmentItemData | null>(null);

  const loading = itemsLoading || checkoutsLoading;

  // Filtered inventory
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      const q = search.toLowerCase();
      const matchSearch = !search ||
        item.name.toLowerCase().includes(q) ||
        (item.serialNumber || '').toLowerCase().includes(q) ||
        (item.barcode || '').toLowerCase().includes(q) ||
        (item.manufacturer || '').toLowerCase().includes(q);
      const matchCat = catFilter === 'all' || item.category === catFilter;
      const matchCond = condFilter === 'all' || item.condition === condFilter;
      return matchSearch && matchCat && matchCond;
    });
  }, [items, search, catFilter, condFilter]);

  // Stats
  const availableCount = items.filter((i) => !i.currentHolderId).length;
  const checkedOutCount = items.filter((i) => i.currentHolderId).length;
  const overdueCount = overdueCheckouts.length;
  const totalItems = items.length;

  const refetchAll = useCallback(() => {
    refetchItems();
    refetchCheckouts();
  }, [refetchItems, refetchCheckouts]);

  if (loading) {
    return (
      <div className="space-y-8 animate-fade-in">
        <div><div className="skeleton h-7 w-48 mb-2" /><div className="skeleton h-4 w-64" /></div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-3 w-20 mb-2" /><div className="skeleton h-7 w-10" />
            </div>
          ))}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="bg-surface border border-main rounded-xl p-5">
              <div className="skeleton h-5 w-32 mb-3" /><div className="skeleton h-3 w-24 mb-2" /><div className="skeleton h-3 w-20" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (itemsError || checkoutsError) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center">
        <AlertTriangle size={48} className="text-red-400 mb-4" />
        <h2 className="text-lg font-semibold text-main mb-2">{t('common.failedToLoadEquipment')}</h2>
        <p className="text-muted mb-4">{itemsError || checkoutsError}</p>
        <Button onClick={refetchAll}><RotateCcw size={16} /> {t('common.retry')}</Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('toolCheckout.title')}</h1>
          <p className="text-muted mt-1">Track company tools & equipment — checkout, return, condition history</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} /> Add Tool
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard icon={<Package size={20} />} label="Total Tools" value={totalItems} color="blue" />
        <StatCard icon={<CheckCircle size={20} />} label="Available" value={availableCount} color="emerald" />
        <StatCard icon={<ArrowRightLeft size={20} />} label="Checked Out" value={checkedOutCount} color="amber" />
        <StatCard
          icon={<AlertTriangle size={20} />}
          label="Overdue"
          value={overdueCount}
          color="red"
          highlight={overdueCount > 0}
        />
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 bg-secondary rounded-lg p-1 w-fit">
        {([
          { key: 'inventory' as ViewTab, label: 'Inventory', count: totalItems },
          { key: 'active' as ViewTab, label: 'Checked Out', count: checkouts.length },
          { key: 'overdue' as ViewTab, label: 'Overdue', count: overdueCount },
        ]).map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={cn(
              'px-4 py-2 text-sm rounded-md transition-colors',
              tab === t.key ? 'bg-main text-main font-medium shadow-sm' : 'text-muted hover:text-main'
            )}
          >
            {t.label}
            {t.count > 0 && (
              <span className={cn(
                'ml-2 px-1.5 py-0.5 text-xs rounded-full',
                tab === t.key ? 'bg-[var(--accent)] text-white' : 'bg-surface text-muted'
              )}>
                {t.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Content per tab */}
      {tab === 'inventory' && (
        <>
          {/* Filters */}
          <div className="flex flex-col sm:flex-row gap-4">
            <SearchInput value={search} onChange={setSearch} placeholder="Search tools..." className="sm:w-80" />
            <Select options={categoryOptions} value={catFilter} onChange={(e) => setCatFilter(e.target.value)} className="sm:w-48" />
            <Select options={conditionOptions} value={condFilter} onChange={(e) => setCondFilter(e.target.value)} className="sm:w-40" />
          </div>

          {/* Grid */}
          {filteredItems.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <Package size={48} className="mx-auto text-muted mb-4" />
                <h3 className="text-lg font-medium text-main mb-2">No tools found</h3>
                <p className="text-muted mb-4">Add tools and equipment to track checkout/return across your team.</p>
                <Button onClick={() => setShowAddModal(true)}><Plus size={16} /> Add Tool</Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredItems.map((item) => (
                <ToolCard
                  key={item.id}
                  item={item}
                  onCheckout={() => setCheckoutItem(item)}
                  onClick={() => setDetailItem(item)}
                />
              ))}
            </div>
          )}
        </>
      )}

      {tab === 'active' && (
        <CheckoutList
          checkouts={checkouts}
          items={items}
          onCheckin={(co) => setCheckinCheckout(co)}
        />
      )}

      {tab === 'overdue' && (
        <CheckoutList
          checkouts={overdueCheckouts}
          items={items}
          onCheckin={(co) => setCheckinCheckout(co)}
          overdue
        />
      )}

      {/* Modals */}
      {showAddModal && <AddToolModal onClose={() => setShowAddModal(false)} onSuccess={refetchAll} />}
      {checkoutItem && <CheckoutModal item={checkoutItem} onClose={() => setCheckoutItem(null)} onSuccess={refetchAll} />}
      {checkinCheckout && <CheckinModal checkout={checkinCheckout} onClose={() => setCheckinCheckout(null)} onSuccess={refetchAll} />}
      {detailItem && <ToolDetailModal item={detailItem} checkouts={checkouts} onClose={() => setDetailItem(null)} onCheckout={() => { setDetailItem(null); setCheckoutItem(detailItem); }} />}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// STAT CARD
// ════════════════════════════════════════════════════════════════

function StatCard({ icon, label, value, color, highlight }: {
  icon: React.ReactNode; label: string; value: number; color: string; highlight?: boolean;
}) {
  return (
    <Card className={highlight ? 'border-red-500' : ''}>
      <CardContent className="p-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 bg-${color}-100 dark:bg-${color}-900/30 rounded-lg`}>
            <div className={`text-${color}-600 dark:text-${color}-400`}>{icon}</div>
          </div>
          <div>
            <p className="text-2xl font-semibold text-main">{value}</p>
            <p className="text-sm text-muted">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════
// TOOL CARD
// ════════════════════════════════════════════════════════════════

function ToolCard({ item, onCheckout, onClick }: {
  item: EquipmentItemData; onCheckout: () => void; onClick: () => void;
}) {
  const isOut = !!item.currentHolderId;

  return (
    <Card className="hover:shadow-md transition-shadow cursor-pointer" onClick={onClick}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-secondary rounded-lg">
              {categoryIcon(item.category)}
            </div>
            <div>
              <h3 className="font-medium text-main">{item.name}</h3>
              <p className="text-xs text-muted">{CATEGORY_LABELS[item.category]}</p>
            </div>
          </div>
          <span className={cn(
            'px-2 py-1 rounded-full text-xs font-medium',
            isOut
              ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
              : 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300',
          )}>
            {isOut ? 'Checked Out' : 'Available'}
          </span>
        </div>

        {/* Details */}
        {item.manufacturer && (
          <p className="text-sm text-muted mb-1">{item.manufacturer}{item.modelNumber ? ` ${item.modelNumber}` : ''}</p>
        )}
        {item.serialNumber && (
          <p className="text-xs text-muted font-mono mb-1">S/N: {item.serialNumber}</p>
        )}
        {item.storageLocation && (
          <p className="text-xs text-muted mb-1">Location: {item.storageLocation}</p>
        )}

        <div className="mt-3 pt-3 border-t border-main flex items-center justify-between">
          <span className={cn('px-2 py-0.5 rounded text-xs font-medium', conditionBg(item.condition), conditionColor(item.condition))}>
            {CONDITION_LABELS[item.condition]}
          </span>
          {!isOut && (
            <Button
              size="sm"
              onClick={(e) => { e.stopPropagation(); onCheckout(); }}
            >
              <ArrowRightLeft size={14} /> Checkout
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════
// CHECKOUT LIST (Active + Overdue tabs)
// ════════════════════════════════════════════════════════════════

function CheckoutList({ checkouts, items, onCheckin, overdue }: {
  checkouts: EquipmentCheckoutData[];
  items: EquipmentItemData[];
  onCheckin: (co: EquipmentCheckoutData) => void;
  overdue?: boolean;
}) {
  if (checkouts.length === 0) {
    return (
      <Card>
        <CardContent className="p-12 text-center">
          <CheckCircle size={48} className="mx-auto text-emerald-400 mb-4" />
          <h3 className="text-lg font-medium text-main mb-2">
            {overdue ? 'No overdue checkouts' : 'No active checkouts'}
          </h3>
          <p className="text-muted">
            {overdue ? 'All tools have been returned on time.' : 'No tools are currently checked out.'}
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-3">
      {checkouts.map((co) => {
        const item = items.find((i) => i.id === co.equipmentItemId);
        const isOverdue = co.expectedReturnDate && new Date(co.expectedReturnDate) < new Date();

        return (
          <Card key={co.id} className={isOverdue ? 'border-red-500/50' : ''}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className={cn(
                    'p-2 rounded-lg',
                    isOverdue ? 'bg-red-100 dark:bg-red-900/30' : 'bg-amber-100 dark:bg-amber-900/30',
                  )}>
                    <Clock size={16} className={isOverdue ? 'text-red-600 dark:text-red-400' : 'text-amber-600 dark:text-amber-400'} />
                  </div>
                  <div>
                    <h4 className="font-medium text-main">{co.equipmentName || item?.name || 'Unknown'}</h4>
                    <div className="flex items-center gap-3 text-xs text-muted mt-1">
                      <span>Out: {new Date(co.checkedOutAt).toLocaleDateString()}</span>
                      <span className={cn('px-1.5 py-0.5 rounded', conditionBg(co.checkoutCondition), conditionColor(co.checkoutCondition))}>
                        {CONDITION_LABELS[co.checkoutCondition]}
                      </span>
                      {co.expectedReturnDate && (
                        <span className={isOverdue ? 'text-red-500 font-medium' : ''}>
                          Due: {new Date(co.expectedReturnDate).toLocaleDateString()}
                        </span>
                      )}
                    </div>
                    {co.notes && <p className="text-xs text-muted mt-1 italic">{co.notes}</p>}
                  </div>
                </div>
                <Button size="sm" onClick={() => onCheckin(co)}>
                  <RotateCcw size={14} /> Return
                </Button>
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// ADD TOOL MODAL
// ════════════════════════════════════════════════════════════════

function AddToolModal({ onClose, onSuccess }: { onClose: () => void; onSuccess: () => void }) {
  const [name, setName] = useState('');
  const [category, setCategory] = useState<EquipmentCategory>('hand_tool');
  const [serialNumber, setSerialNumber] = useState('');
  const [barcode, setBarcode] = useState('');
  const [manufacturer, setManufacturer] = useState('');
  const [modelNumber, setModelNumber] = useState('');
  const [purchaseCost, setPurchaseCost] = useState('');
  const [condition, setCondition] = useState<EquipmentCondition>('new');
  const [storageLocation, setStorageLocation] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await createEquipmentItem({
        name: name.trim(),
        category,
        serialNumber: serialNumber.trim() || undefined,
        barcode: barcode.trim() || undefined,
        manufacturer: manufacturer.trim() || undefined,
        modelNumber: modelNumber.trim() || undefined,
        purchaseCost: purchaseCost ? parseFloat(purchaseCost) : undefined,
        condition,
        storageLocation: storageLocation.trim() || undefined,
        notes: notes.trim() || undefined,
      });
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add tool');
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Tool / Equipment</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <Input label="Tool Name *" placeholder="Milwaukee M18 Drill" value={name} onChange={(e) => setName(e.target.value)} required />

            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Category *</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value as EquipmentCategory)}
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main"
              >
                {Object.entries(CATEGORY_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Input label="Manufacturer" placeholder="Milwaukee" value={manufacturer} onChange={(e) => setManufacturer(e.target.value)} />
              <Input label="Model Number" placeholder="2804-20" value={modelNumber} onChange={(e) => setModelNumber(e.target.value)} />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Input label="Serial Number" placeholder="Optional" value={serialNumber} onChange={(e) => setSerialNumber(e.target.value)} />
              <Input label="Barcode" placeholder="Optional" value={barcode} onChange={(e) => setBarcode(e.target.value)} />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Input label="Purchase Cost ($)" type="number" placeholder="0.00" value={purchaseCost} onChange={(e) => setPurchaseCost(e.target.value)} />
              <Input label="Storage Location" placeholder="Truck 1, Bay 3" value={storageLocation} onChange={(e) => setStorageLocation(e.target.value)} />
            </div>

            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Condition</label>
              <div className="flex flex-wrap gap-2">
                {(Object.entries(CONDITION_LABELS) as [EquipmentCondition, string][])
                  .filter(([k]) => k !== 'retired')
                  .map(([k, l]) => (
                    <button
                      key={k}
                      type="button"
                      onClick={() => setCondition(k)}
                      className={cn(
                        'px-3 py-1.5 rounded-lg text-sm border transition-colors',
                        condition === k
                          ? 'border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]'
                          : 'border-main text-muted hover:text-main',
                      )}
                    >
                      {l}
                    </button>
                  ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={2}
                placeholder="Additional notes..."
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
              />
            </div>

            {error && <p className="text-sm text-red-500">{error}</p>}

            <div className="flex items-center gap-3 pt-2">
              <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
              <Button type="submit" className="flex-1" disabled={saving || !name.trim()}>
                {saving ? 'Adding...' : <><Plus size={16} /> Add Tool</>}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// CHECKOUT MODAL
// ════════════════════════════════════════════════════════════════

function CheckoutModal({ item, onClose, onSuccess }: {
  item: EquipmentItemData; onClose: () => void; onSuccess: () => void;
}) {
  const [condition, setCondition] = useState<EquipmentCondition>(item.condition);
  const [expectedReturn, setExpectedReturn] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await checkoutEquipment({
        equipmentItemId: item.id,
        condition,
        expectedReturnDate: expectedReturn || undefined,
        notes: notes.trim() || undefined,
      });
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Checkout failed');
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Checkout Tool</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Tool info */}
            <div className="p-3 bg-secondary rounded-lg">
              <p className="font-medium text-main">{item.name}</p>
              <p className="text-sm text-muted">{CATEGORY_LABELS[item.category]}</p>
              {item.serialNumber && <p className="text-xs text-muted font-mono mt-1">S/N: {item.serialNumber}</p>}
            </div>

            {/* Condition at checkout */}
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Condition at Checkout</label>
              <div className="flex flex-wrap gap-2">
                {(Object.entries(CONDITION_LABELS) as [EquipmentCondition, string][])
                  .filter(([k]) => k !== 'retired')
                  .map(([k, l]) => (
                    <button
                      key={k}
                      type="button"
                      onClick={() => setCondition(k)}
                      className={cn(
                        'px-3 py-1.5 rounded-lg text-sm border transition-colors',
                        condition === k
                          ? 'border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]'
                          : 'border-main text-muted hover:text-main',
                      )}
                    >
                      {l}
                    </button>
                  ))}
              </div>
            </div>

            <Input
              label="Expected Return Date"
              type="date"
              value={expectedReturn}
              onChange={(e) => setExpectedReturn(e.target.value)}
            />

            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={2}
                placeholder="Optional checkout notes..."
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
              />
            </div>

            {error && <p className="text-sm text-red-500">{error}</p>}

            <div className="flex items-center gap-3 pt-2">
              <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
              <Button type="submit" className="flex-1" disabled={saving}>
                {saving ? 'Checking out...' : <><ArrowRightLeft size={16} /> Checkout</>}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// CHECKIN (RETURN) MODAL
// ════════════════════════════════════════════════════════════════

function CheckinModal({ checkout, onClose, onSuccess }: {
  checkout: EquipmentCheckoutData; onClose: () => void; onSuccess: () => void;
}) {
  const [condition, setCondition] = useState<EquipmentCondition>('good');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await checkinEquipment({
        checkoutId: checkout.id,
        condition,
        notes: notes.trim() || undefined,
      });
      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Return failed');
      setSaving(false);
    }
  }

  const isOverdue = checkout.expectedReturnDate && new Date(checkout.expectedReturnDate) < new Date();

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Return Tool</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Checkout info */}
            <div className="p-3 bg-secondary rounded-lg space-y-1">
              <p className="font-medium text-main">{checkout.equipmentName || 'Tool'}</p>
              <p className="text-sm text-muted">
                Checked out: {new Date(checkout.checkedOutAt).toLocaleDateString()}
              </p>
              <p className="text-sm text-muted">
                Condition at checkout: {CONDITION_LABELS[checkout.checkoutCondition]}
              </p>
              {isOverdue && (
                <p className="text-sm text-red-500 font-medium">
                  OVERDUE — was due {new Date(checkout.expectedReturnDate!).toLocaleDateString()}
                </p>
              )}
            </div>

            {/* Return condition */}
            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Condition at Return</label>
              <div className="flex flex-wrap gap-2">
                {(Object.entries(CONDITION_LABELS) as [EquipmentCondition, string][])
                  .filter(([k]) => k !== 'retired')
                  .map(([k, l]) => (
                    <button
                      key={k}
                      type="button"
                      onClick={() => setCondition(k)}
                      className={cn(
                        'px-3 py-1.5 rounded-lg text-sm border transition-colors',
                        condition === k
                          ? 'border-[var(--accent)] bg-[var(--accent)]/10 text-[var(--accent)]'
                          : 'border-main text-muted hover:text-main',
                      )}
                    >
                      {l}
                    </button>
                  ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-main mb-1.5">Return Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={2}
                placeholder="Any damage or notes..."
                className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main placeholder:text-muted resize-none"
              />
            </div>

            {error && <p className="text-sm text-red-500">{error}</p>}

            <div className="flex items-center gap-3 pt-2">
              <Button type="button" variant="secondary" className="flex-1" onClick={onClose}>Cancel</Button>
              <Button type="submit" className="flex-1" disabled={saving}>
                {saving ? 'Returning...' : <><RotateCcw size={16} /> Confirm Return</>}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// TOOL DETAIL MODAL
// ════════════════════════════════════════════════════════════════

function ToolDetailModal({ item, checkouts, onClose, onCheckout }: {
  item: EquipmentItemData;
  checkouts: EquipmentCheckoutData[];
  onClose: () => void;
  onCheckout: () => void;
}) {
  const itemCheckouts = checkouts.filter((co) => co.equipmentItemId === item.id);
  const isOut = !!item.currentHolderId;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-semibold text-main">{item.name}</h2>
                <span className={cn(
                  'px-2 py-1 rounded-full text-xs font-medium',
                  isOut
                    ? 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
                    : 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-300',
                )}>
                  {isOut ? 'Checked Out' : 'Available'}
                </span>
                <span className={cn('px-2 py-1 rounded-full text-xs font-medium', conditionBg(item.condition), conditionColor(item.condition))}>
                  {CONDITION_LABELS[item.condition]}
                </span>
              </div>
              <p className="text-muted mt-1">{CATEGORY_LABELS[item.category]}</p>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Details */}
          <div className="grid grid-cols-2 gap-4">
            {item.manufacturer && (
              <div>
                <p className="text-sm text-muted mb-1">Manufacturer</p>
                <p className="text-main">{item.manufacturer}</p>
              </div>
            )}
            {item.modelNumber && (
              <div>
                <p className="text-sm text-muted mb-1">Model</p>
                <p className="text-main">{item.modelNumber}</p>
              </div>
            )}
            {item.serialNumber && (
              <div>
                <p className="text-sm text-muted mb-1">Serial Number</p>
                <p className="font-mono text-main">{item.serialNumber}</p>
              </div>
            )}
            {item.barcode && (
              <div>
                <p className="text-sm text-muted mb-1">Barcode</p>
                <p className="font-mono text-main">{item.barcode}</p>
              </div>
            )}
            {item.storageLocation && (
              <div>
                <p className="text-sm text-muted mb-1">Storage Location</p>
                <p className="text-main">{item.storageLocation}</p>
              </div>
            )}
            {item.purchaseCost != null && (
              <div>
                <p className="text-sm text-muted mb-1">Purchase Cost</p>
                <p className="text-main">${item.purchaseCost.toFixed(2)}</p>
              </div>
            )}
            {item.warrantyExpiry && (
              <div>
                <p className="text-sm text-muted mb-1">Warranty Expiry</p>
                <p className="text-main">{new Date(item.warrantyExpiry).toLocaleDateString()}</p>
              </div>
            )}
            {item.nextCalibrationDate && (
              <div>
                <p className="text-sm text-muted mb-1">Next Calibration</p>
                <p className="text-main">{new Date(item.nextCalibrationDate).toLocaleDateString()}</p>
              </div>
            )}
          </div>

          {item.notes && (
            <div>
              <p className="text-sm text-muted mb-1">Notes</p>
              <p className="text-main">{item.notes}</p>
            </div>
          )}

          {/* Active checkouts for this item */}
          {itemCheckouts.length > 0 && (
            <div>
              <h3 className="font-medium text-main mb-3">Active Checkout</h3>
              {itemCheckouts.map((co) => (
                <div key={co.id} className="p-3 bg-secondary rounded-lg text-sm space-y-1">
                  <p className="text-main">Checked out: {new Date(co.checkedOutAt).toLocaleDateString()}</p>
                  <p className="text-muted">Condition: {CONDITION_LABELS[co.checkoutCondition]}</p>
                  {co.expectedReturnDate && (
                    <p className={new Date(co.expectedReturnDate) < new Date() ? 'text-red-500 font-medium' : 'text-muted'}>
                      Due: {new Date(co.expectedReturnDate).toLocaleDateString()}
                    </p>
                  )}
                  {co.notes && <p className="text-muted italic">{co.notes}</p>}
                </div>
              ))}
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 pt-4 border-t border-main">
            {!isOut && (
              <Button className="flex-1" onClick={onCheckout}>
                <ArrowRightLeft size={16} /> Checkout
              </Button>
            )}
            <Button variant="ghost" onClick={onClose}>Close</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
