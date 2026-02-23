'use client';

import { useState } from 'react';
import {
  Plus,
  Search,
  Package,
  AlertTriangle,
  TrendingDown,
  TrendingUp,
  MoreHorizontal,
  Edit,
  Trash2,
  History,
  X,
  ArrowUpRight,
  ArrowDownRight,
  Filter,
  BarChart3,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SearchInput, Select, Input } from '@/components/ui/input';
import { CommandPalette } from '@/components/command-palette';
import { formatCurrency, formatDate, cn } from '@/lib/utils';
import { useTranslation } from '@/lib/translations';

interface InventoryItem {
  id: string;
  name: string;
  sku: string;
  category: string;
  quantity: number;
  minQuantity: number;
  unitCost: number;
  location: string;
  vendor?: string;
  lastRestocked?: Date;
  lastUsed?: Date;
}

interface InventoryTransaction {
  id: string;
  itemId: string;
  type: 'in' | 'out' | 'adjustment';
  quantity: number;
  reason: string;
  jobId?: string;
  jobName?: string;
  date: Date;
  user: string;
}

// Inventory Management — Future phase. No inventory table yet. Empty until wired.
const inventoryItems: InventoryItem[] = [];
const inventoryTransactions: InventoryTransaction[] = [];

export default function InventoryPage() {
  const { t } = useTranslation();
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [showLowStock, setShowLowStock] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showAdjustModal, setShowAdjustModal] = useState<InventoryItem | null>(null);
  const [showHistoryModal, setShowHistoryModal] = useState<InventoryItem | null>(null);

  const filteredItems = inventoryItems.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.sku.toLowerCase().includes(search.toLowerCase());
    const matchesCategory = categoryFilter === 'all' || item.category === categoryFilter;
    const matchesLowStock = !showLowStock || item.quantity <= item.minQuantity;
    return matchesSearch && matchesCategory && matchesLowStock;
  });

  const categoryOptions = [
    { value: 'all', label: 'All Categories' },
    { value: 'Electrical', label: 'Electrical' },
    { value: 'Plumbing', label: 'Plumbing' },
    { value: 'HVAC', label: 'HVAC' },
    { value: 'General', label: 'General' },
  ];

  // Stats
  const totalItems = inventoryItems.length;
  const totalValue = inventoryItems.reduce((sum, item) => sum + item.quantity * item.unitCost, 0);
  const lowStockItems = inventoryItems.filter((item) => item.quantity <= item.minQuantity);
  const outOfStock = inventoryItems.filter((item) => item.quantity === 0);

  return (
    <div className="space-y-6">
      <CommandPalette />

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-main">{t('inventory.title')}</h1>
          <p className="text-muted mt-1">Track materials and supplies</p>
        </div>
        <Button onClick={() => setShowAddModal(true)}>
          <Plus size={16} />
          Add Item
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                <Package size={20} className="text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{totalItems}</p>
                <p className="text-sm text-muted">Total Items</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg">
                <BarChart3 size={20} className="text-emerald-600 dark:text-emerald-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{formatCurrency(totalValue)}</p>
                <p className="text-sm text-muted">{t('common.totalValue')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className={lowStockItems.length > 0 ? 'border-amber-500' : ''}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-lg">
                <TrendingDown size={20} className="text-amber-600 dark:text-amber-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{lowStockItems.length}</p>
                <p className="text-sm text-muted">{t('common.lowStock')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className={outOfStock.length > 0 ? 'border-red-500' : ''}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 dark:bg-red-900/30 rounded-lg">
                <AlertTriangle size={20} className="text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-2xl font-semibold text-main">{outOfStock.length}</p>
                <p className="text-sm text-muted">{t('common.outOfStock')}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search items..."
          className="sm:w-80"
        />
        <Select
          options={categoryOptions}
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
          className="sm:w-48"
        />
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={showLowStock}
            onChange={(e) => setShowLowStock(e.target.checked)}
            className="w-4 h-4 rounded border-main text-accent focus:ring-accent"
          />
          <span className="text-sm text-main">Show low stock only</span>
        </label>
      </div>

      {/* Inventory Table */}
      <Card>
        <CardContent className="p-0">
          <table className="w-full">
            <thead>
              <tr className="border-b border-main">
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.item')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">SKU</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.category')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3">{t('common.location')}</th>
                <th className="text-right text-sm font-medium text-muted px-6 py-3">{t('common.qty')}</th>
                <th className="text-right text-sm font-medium text-muted px-6 py-3">Min</th>
                <th className="text-right text-sm font-medium text-muted px-6 py-3">Unit Cost</th>
                <th className="text-right text-sm font-medium text-muted px-6 py-3">{t('common.value')}</th>
                <th className="text-left text-sm font-medium text-muted px-6 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 && (
                <tr><td colSpan={7} className="px-6 py-16 text-center">
                  <p className="text-sm font-medium text-main">No inventory items found</p>
                  <p className="text-xs text-muted mt-1">Add materials and supplies to track your inventory</p>
                </td></tr>
              )}
              {filteredItems.map((item) => {
                const isLowStock = item.quantity <= item.minQuantity;
                const isOutOfStock = item.quantity === 0;
                return (
                  <tr key={item.id} className="border-b border-main/50 hover:bg-surface-hover">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-main">{item.name}</span>
                        {isOutOfStock && (
                          <Badge variant="error" size="sm">Out</Badge>
                        )}
                        {isLowStock && !isOutOfStock && (
                          <Badge variant="warning" size="sm">Low</Badge>
                        )}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-muted font-mono">{item.sku}</td>
                    <td className="px-6 py-4 text-sm text-muted">{item.category}</td>
                    <td className="px-6 py-4 text-sm text-muted">{item.location}</td>
                    <td className={cn(
                      'px-6 py-4 text-right font-semibold',
                      isOutOfStock ? 'text-red-600' : isLowStock ? 'text-amber-600' : 'text-main'
                    )}>
                      {item.quantity}
                    </td>
                    <td className="px-6 py-4 text-right text-muted">{item.minQuantity}</td>
                    <td className="px-6 py-4 text-right text-muted">{formatCurrency(item.unitCost)}</td>
                    <td className="px-6 py-4 text-right font-medium text-main">
                      {formatCurrency(item.quantity * item.unitCost)}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1 justify-end">
                        <button
                          onClick={() => setShowAdjustModal(item)}
                          className="p-1.5 hover:bg-surface-hover rounded-lg text-muted hover:text-main"
                          title="Adjust quantity"
                        >
                          <Edit size={16} />
                        </button>
                        <button
                          onClick={() => setShowHistoryModal(item)}
                          className="p-1.5 hover:bg-surface-hover rounded-lg text-muted hover:text-main"
                          title="View history"
                        >
                          <History size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </CardContent>
      </Card>

      {/* Add Item Modal */}
      {showAddModal && (
        <AddItemModal onClose={() => setShowAddModal(false)} />
      )}

      {/* Adjust Quantity Modal */}
      {showAdjustModal && (
        <AdjustQuantityModal item={showAdjustModal} onClose={() => setShowAdjustModal(null)} />
      )}

      {/* History Modal */}
      {showHistoryModal && (
        <HistoryModal item={showHistoryModal} onClose={() => setShowHistoryModal(null)} />
      )}
    </div>
  );
}

function AddItemModal({ onClose }: { onClose: () => void }) {
  const { t } = useTranslation();
  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Add Inventory Item</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Input label="Item Name *" placeholder="20A Single Pole Breaker" />
          <div className="grid grid-cols-2 gap-4">
            <Input label="SKU" placeholder="SPB-20" />
            <Select
              label="Category"
              options={[
                { value: 'Electrical', label: 'Electrical' },
                { value: 'Plumbing', label: 'Plumbing' },
                { value: 'HVAC', label: 'HVAC' },
                { value: 'General', label: 'General' },
              ]}
            />
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Input label="Quantity" type="number" placeholder="0" />
            <Input label="Min Quantity" type="number" placeholder="10" />
            <Input label="Unit Cost" type="number" placeholder="0.00" />
          </div>
          <Input label="Location" placeholder="Shelf A1" />
          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1"><Plus size={16} />Add Item</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function AdjustQuantityModal({ item, onClose }: { item: InventoryItem; onClose: () => void }) {
  const { t } = useTranslation();
  const [adjustType, setAdjustType] = useState<'in' | 'out' | 'set'>('in');
  const [quantity, setQuantity] = useState('');
  const [reason, setReason] = useState('');

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Adjust Quantity</CardTitle>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="p-3 bg-secondary rounded-lg">
            <p className="font-medium text-main">{item.name}</p>
            <p className="text-sm text-muted">Current: {item.quantity} units</p>
          </div>

          <div className="flex gap-2">
            {(['in', 'out', 'set'] as const).map((type) => (
              <button
                key={type}
                onClick={() => setAdjustType(type)}
                className={cn(
                  'flex-1 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                  adjustType === type
                    ? 'bg-accent text-white'
                    : 'bg-secondary text-muted hover:text-main'
                )}
              >
                {type === 'in' && <ArrowUpRight size={14} className="inline mr-1" />}
                {type === 'out' && <ArrowDownRight size={14} className="inline mr-1" />}
                {type === 'in' ? 'Add' : type === 'out' ? 'Remove' : 'Set To'}
              </button>
            ))}
          </div>

          <Input
            label="Quantity"
            type="number"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            placeholder="Enter quantity"
          />

          <div>
            <label className="block text-sm font-medium text-main mb-1.5">Reason</label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full px-4 py-2.5 bg-main border border-main rounded-lg text-main focus:border-accent focus:ring-1 focus:ring-accent"
            >
              <option value="">Select reason...</option>
              <option value="job">Used on job</option>
              <option value="restock">Restocked</option>
              <option value="damaged">Damaged/Lost</option>
              <option value="count">Inventory count</option>
              <option value="return">Returned to vendor</option>
              <option value="other">Other</option>
            </select>
          </div>

          <div className="flex items-center gap-3 pt-4">
            <Button variant="secondary" className="flex-1" onClick={onClose}>{t('common.cancel')}</Button>
            <Button className="flex-1">Save Adjustment</Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function HistoryModal({ item, onClose }: { item: InventoryItem; onClose: () => void }) {
  const itemTransactions = inventoryTransactions.filter((t) => t.itemId === item.id);

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle>Inventory History</CardTitle>
              <p className="text-sm text-muted mt-1">{item.name}</p>
            </div>
            <button onClick={onClose} className="p-1.5 hover:bg-surface-hover rounded-lg">
              <X size={18} className="text-muted" />
            </button>
          </div>
        </CardHeader>
        <CardContent>
          {itemTransactions.length === 0 ? (
            <p className="text-center text-muted py-8">No history available</p>
          ) : (
            <div className="space-y-3">
              {itemTransactions.map((tx) => (
                <div key={tx.id} className="flex items-start gap-3 p-3 bg-secondary rounded-lg">
                  <div className={cn(
                    'p-1.5 rounded-full',
                    tx.type === 'in' ? 'bg-emerald-100 dark:bg-emerald-900/30' :
                    tx.type === 'out' ? 'bg-red-100 dark:bg-red-900/30' :
                    'bg-blue-100 dark:bg-blue-900/30'
                  )}>
                    {tx.type === 'in' ? (
                      <ArrowUpRight size={14} className="text-emerald-600" />
                    ) : tx.type === 'out' ? (
                      <ArrowDownRight size={14} className="text-red-600" />
                    ) : (
                      <Edit size={14} className="text-blue-600" />
                    )}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <span className={cn(
                        'font-semibold',
                        tx.type === 'in' ? 'text-emerald-600' :
                        tx.type === 'out' ? 'text-red-600' :
                        'text-blue-600'
                      )}>
                        {tx.type === 'in' ? '+' : tx.type === 'out' ? '-' : ''}{Math.abs(tx.quantity)}
                      </span>
                      <span className="text-xs text-muted">{formatDate(tx.date)}</span>
                    </div>
                    <p className="text-sm text-main">{tx.reason}</p>
                    {tx.jobName && (
                      <p className="text-xs text-muted">{tx.jobName}</p>
                    )}
                    <p className="text-xs text-muted">by {tx.user}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
