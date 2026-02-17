'use client';

// ZAFTO Team Portal — Tool Checkout Page
// Created: Sprint FIELD2 (Session 131)
//
// Mobile-optimized tool checkout/return for field employees.
// Two views: "My Tools" (checked out) and "All Tools" (browse/checkout).

import { useState, useCallback } from 'react';
import {
  ArrowLeft,
  Package,
  ArrowRightLeft,
  RotateCcw,
  AlertTriangle,
  CheckCircle,
  Clock,
  Wrench,
  Search,
  X,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import {
  useToolItems,
  useMyCheckouts,
  checkoutTool,
  returnTool,
  CATEGORY_LABELS,
  CONDITION_LABELS,
} from '@/lib/hooks/use-tool-checkout';
import type {
  ToolItem,
  ToolCheckout,
  EquipmentCondition,
} from '@/lib/hooks/use-tool-checkout';

// ════════════════════════════════════════════════════════════════
// MAIN PAGE
// ════════════════════════════════════════════════════════════════

type ViewMode = 'my_tools' | 'all_tools';

export default function ToolCheckoutPage() {
  const { items, loading: itemsLoading, error: itemsError, refetch: refetchItems } = useToolItems();
  const { checkouts, overdueCheckouts, loading: coLoading, error: coError, userId, refetch: refetchCheckouts } = useMyCheckouts();

  const [view, setView] = useState<ViewMode>('my_tools');
  const [search, setSearch] = useState('');
  const [checkoutItem, setCheckoutItem] = useState<ToolItem | null>(null);
  const [returnCheckout, setReturnCheckout] = useState<ToolCheckout | null>(null);

  const loading = itemsLoading || coLoading;
  const error = itemsError || coError;

  const refetchAll = useCallback(() => {
    refetchItems();
    refetchCheckouts();
  }, [refetchItems, refetchCheckouts]);

  // Filter all tools for browse view
  const filteredItems = items.filter((item) => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      item.name.toLowerCase().includes(q) ||
      (item.serialNumber || '').toLowerCase().includes(q) ||
      (item.barcode || '').toLowerCase().includes(q) ||
      (item.manufacturer || '').toLowerCase().includes(q)
    );
  });

  // Checkout flow modal
  if (checkoutItem) {
    return (
      <CheckoutFlow
        item={checkoutItem}
        onBack={() => setCheckoutItem(null)}
        onSuccess={() => { setCheckoutItem(null); refetchAll(); }}
      />
    );
  }

  // Return flow modal
  if (returnCheckout) {
    return (
      <ReturnFlow
        checkout={returnCheckout}
        onBack={() => setReturnCheckout(null)}
        onSuccess={() => { setReturnCheckout(null); refetchAll(); }}
      />
    );
  }

  if (loading) {
    return (
      <div className="space-y-4 animate-fade-in p-4">
        <div className="skeleton h-6 w-40 mb-2" />
        <div className="skeleton h-4 w-56 mb-6" />
        {[...Array(4)].map((_, i) => (
          <div key={i} className="bg-surface border border-main rounded-xl p-4">
            <div className="skeleton h-5 w-32 mb-2" />
            <div className="skeleton h-3 w-24" />
          </div>
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-24 text-center px-4">
        <AlertTriangle size={40} className="text-red-400 mb-4" />
        <h2 className="text-lg font-semibold text-main mb-2">Failed to load tools</h2>
        <p className="text-sm text-muted mb-4">{error}</p>
        <button onClick={refetchAll} className="px-4 py-2 bg-accent text-white rounded-lg text-sm font-medium">
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-main">Tool Checkout</h1>
        <p className="text-sm text-muted mt-1">Check out and return company tools</p>
      </div>

      {/* Quick stats */}
      <div className="grid grid-cols-3 gap-3">
        <div className="bg-surface border border-main rounded-xl p-3 text-center">
          <p className="text-lg font-bold text-main">{checkouts.length}</p>
          <p className="text-xs text-muted">My Tools</p>
        </div>
        <div className="bg-surface border border-main rounded-xl p-3 text-center">
          <p className="text-lg font-bold text-main">{items.filter((i) => !i.currentHolderId).length}</p>
          <p className="text-xs text-muted">Available</p>
        </div>
        <div className={cn(
          'bg-surface border rounded-xl p-3 text-center',
          overdueCheckouts.length > 0 ? 'border-red-500' : 'border-main',
        )}>
          <p className={cn('text-lg font-bold', overdueCheckouts.length > 0 ? 'text-red-500' : 'text-main')}>
            {overdueCheckouts.length}
          </p>
          <p className="text-xs text-muted">Overdue</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex bg-secondary rounded-lg p-1">
        <button
          onClick={() => setView('my_tools')}
          className={cn(
            'flex-1 py-2 text-sm rounded-md font-medium transition-colors',
            view === 'my_tools' ? 'bg-main text-main shadow-sm' : 'text-muted',
          )}
        >
          My Tools ({checkouts.length})
        </button>
        <button
          onClick={() => setView('all_tools')}
          className={cn(
            'flex-1 py-2 text-sm rounded-md font-medium transition-colors',
            view === 'all_tools' ? 'bg-main text-main shadow-sm' : 'text-muted',
          )}
        >
          All Tools ({items.length})
        </button>
      </div>

      {/* My Tools View */}
      {view === 'my_tools' && (
        <>
          {checkouts.length === 0 ? (
            <div className="text-center py-12">
              <CheckCircle size={40} className="mx-auto text-emerald-400 mb-3" />
              <p className="text-main font-medium">No tools checked out</p>
              <p className="text-sm text-muted mt-1">Browse available tools to check one out</p>
              <button
                onClick={() => setView('all_tools')}
                className="mt-4 px-4 py-2 bg-accent text-white rounded-lg text-sm font-medium"
              >
                Browse Tools
              </button>
            </div>
          ) : (
            <div className="space-y-3">
              {checkouts.map((co) => {
                const item = items.find((i) => i.id === co.equipmentItemId);
                const isOverdue = co.expectedReturnDate && new Date(co.expectedReturnDate) < new Date();

                return (
                  <Card key={co.id} className={cn('p-4', isOverdue && 'border-red-500/50')}>
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <div className={cn(
                          'p-2 rounded-lg',
                          isOverdue ? 'bg-red-500/10' : 'bg-amber-500/10',
                        )}>
                          <Wrench size={18} className={isOverdue ? 'text-red-500' : 'text-amber-500'} />
                        </div>
                        <div>
                          <h3 className="font-medium text-main text-sm">{co.equipmentName || item?.name || 'Tool'}</h3>
                          <p className="text-xs text-muted mt-0.5">
                            Since {new Date(co.checkedOutAt).toLocaleDateString()}
                          </p>
                          {co.expectedReturnDate && (
                            <p className={cn('text-xs mt-0.5', isOverdue ? 'text-red-500 font-medium' : 'text-muted')}>
                              {isOverdue ? 'OVERDUE' : 'Due'}: {new Date(co.expectedReturnDate).toLocaleDateString()}
                            </p>
                          )}
                        </div>
                      </div>
                      <button
                        onClick={() => setReturnCheckout(co)}
                        className="px-3 py-1.5 bg-accent text-white rounded-lg text-xs font-medium flex items-center gap-1"
                      >
                        <RotateCcw size={12} /> Return
                      </button>
                    </div>
                  </Card>
                );
              })}
            </div>
          )}
        </>
      )}

      {/* All Tools View */}
      {view === 'all_tools' && (
        <>
          {/* Search */}
          <div className="relative">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search tools..."
              className="w-full pl-10 pr-10 py-2 bg-secondary border border-main rounded-lg text-main placeholder:text-muted text-sm"
            />
            {search && (
              <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted">
                <X size={16} />
              </button>
            )}
          </div>

          {filteredItems.length === 0 ? (
            <div className="text-center py-12">
              <Package size={40} className="mx-auto text-muted mb-3" />
              <p className="text-main font-medium">No tools found</p>
              <p className="text-sm text-muted mt-1">
                {search ? 'Try a different search term' : 'No tools have been added yet'}
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredItems.map((item) => {
                const isOut = !!item.currentHolderId;
                const isMine = item.currentHolderId === userId;

                return (
                  <Card key={item.id} className="p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="p-2 bg-secondary rounded-lg flex-shrink-0">
                          <Wrench size={16} className="text-muted" />
                        </div>
                        <div className="min-w-0">
                          <h3 className="font-medium text-main text-sm truncate">{item.name}</h3>
                          <p className="text-xs text-muted">{CATEGORY_LABELS[item.category]}</p>
                          {item.serialNumber && (
                            <p className="text-xs text-muted font-mono">S/N: {item.serialNumber}</p>
                          )}
                        </div>
                      </div>
                      <div className="flex-shrink-0 ml-3">
                        {isOut ? (
                          <span className={cn(
                            'px-2 py-1 rounded text-xs font-medium',
                            isMine ? 'bg-blue-500/10 text-blue-500' : 'bg-amber-500/10 text-amber-500',
                          )}>
                            {isMine ? 'Mine' : 'Out'}
                          </span>
                        ) : (
                          <button
                            onClick={() => setCheckoutItem(item)}
                            className="px-3 py-1.5 bg-accent text-white rounded-lg text-xs font-medium flex items-center gap-1"
                          >
                            <ArrowRightLeft size={12} /> Checkout
                          </button>
                        )}
                      </div>
                    </div>
                  </Card>
                );
              })}
            </div>
          )}
        </>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// CHECKOUT FLOW (full-screen mobile form)
// ════════════════════════════════════════════════════════════════

function CheckoutFlow({ item, onBack, onSuccess }: {
  item: ToolItem; onBack: () => void; onSuccess: () => void;
}) {
  const [condition, setCondition] = useState<EquipmentCondition>(item.condition);
  const [expectedReturn, setExpectedReturn] = useState('');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit() {
    setSaving(true);
    setError(null);
    try {
      await checkoutTool({
        equipmentItemId: item.id,
        condition,
        expectedReturnDate: expectedReturn || undefined,
        notes: notes.trim() || undefined,
      });
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Checkout failed');
      setSaving(false);
    }
  }

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={onBack} className="p-2 hover:bg-surface-hover rounded-lg">
          <ArrowLeft size={18} className="text-main" />
        </button>
        <h1 className="text-lg font-bold text-main">Checkout Tool</h1>
      </div>

      {/* Tool info */}
      <Card className="p-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-secondary rounded-lg">
            <Wrench size={18} className="text-muted" />
          </div>
          <div>
            <h3 className="font-medium text-main">{item.name}</h3>
            <p className="text-xs text-muted">{CATEGORY_LABELS[item.category]}</p>
            {item.manufacturer && <p className="text-xs text-muted">{item.manufacturer} {item.modelNumber || ''}</p>}
          </div>
        </div>
      </Card>

      {/* Condition */}
      <div>
        <label className="block text-sm font-medium text-main mb-2">Condition at Checkout</label>
        <div className="flex flex-wrap gap-2">
          {(['new', 'good', 'fair', 'poor', 'damaged'] as EquipmentCondition[]).map((c) => (
            <button
              key={c}
              onClick={() => setCondition(c)}
              className={cn(
                'px-3 py-2 rounded-lg text-sm border transition-colors',
                condition === c
                  ? 'border-accent bg-accent/10 text-accent font-medium'
                  : 'border-main text-muted',
              )}
            >
              {CONDITION_LABELS[c]}
            </button>
          ))}
        </div>
      </div>

      {/* Expected return */}
      <div>
        <label className="block text-sm font-medium text-main mb-2">Expected Return Date</label>
        <input
          type="date"
          value={expectedReturn}
          onChange={(e) => setExpectedReturn(e.target.value)}
          className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main text-sm"
        />
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-main mb-2">Notes</label>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={3}
          placeholder="Optional checkout notes..."
          className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main placeholder:text-muted text-sm resize-none"
        />
      </div>

      {error && <p className="text-sm text-red-500">{error}</p>}

      {/* Submit */}
      <button
        onClick={handleSubmit}
        disabled={saving}
        className={cn(
          'w-full py-3 rounded-lg text-white font-medium text-sm',
          saving ? 'bg-accent/50 cursor-not-allowed' : 'bg-accent',
        )}
      >
        {saving ? 'Checking out...' : 'Confirm Checkout'}
      </button>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// RETURN FLOW (full-screen mobile form)
// ════════════════════════════════════════════════════════════════

function ReturnFlow({ checkout, onBack, onSuccess }: {
  checkout: ToolCheckout; onBack: () => void; onSuccess: () => void;
}) {
  const [condition, setCondition] = useState<EquipmentCondition>('good');
  const [notes, setNotes] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const isOverdue = checkout.expectedReturnDate && new Date(checkout.expectedReturnDate) < new Date();

  async function handleSubmit() {
    setSaving(true);
    setError(null);
    try {
      await returnTool({
        checkoutId: checkout.id,
        condition,
        notes: notes.trim() || undefined,
      });
      onSuccess();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Return failed');
      setSaving(false);
    }
  }

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Header */}
      <div className="flex items-center gap-3">
        <button onClick={onBack} className="p-2 hover:bg-surface-hover rounded-lg">
          <ArrowLeft size={18} className="text-main" />
        </button>
        <h1 className="text-lg font-bold text-main">Return Tool</h1>
      </div>

      {/* Tool info */}
      <Card className="p-4 space-y-2">
        <div className="flex items-center gap-3">
          <div className={cn('p-2 rounded-lg', isOverdue ? 'bg-red-500/10' : 'bg-secondary')}>
            <Wrench size={18} className={isOverdue ? 'text-red-500' : 'text-muted'} />
          </div>
          <div>
            <h3 className="font-medium text-main">{checkout.equipmentName || 'Tool'}</h3>
            <p className="text-xs text-muted">
              Checked out {new Date(checkout.checkedOutAt).toLocaleDateString()}
            </p>
          </div>
        </div>
        <div className="text-xs text-muted">
          Condition at checkout: {CONDITION_LABELS[checkout.checkoutCondition]}
        </div>
        {isOverdue && (
          <div className="text-xs text-red-500 font-medium">
            OVERDUE — was due {new Date(checkout.expectedReturnDate!).toLocaleDateString()}
          </div>
        )}
      </Card>

      {/* Return condition */}
      <div>
        <label className="block text-sm font-medium text-main mb-2">Condition at Return</label>
        <div className="flex flex-wrap gap-2">
          {(['new', 'good', 'fair', 'poor', 'damaged'] as EquipmentCondition[]).map((c) => (
            <button
              key={c}
              onClick={() => setCondition(c)}
              className={cn(
                'px-3 py-2 rounded-lg text-sm border transition-colors',
                condition === c
                  ? 'border-accent bg-accent/10 text-accent font-medium'
                  : 'border-main text-muted',
              )}
            >
              {CONDITION_LABELS[c]}
            </button>
          ))}
        </div>
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-main mb-2">Return Notes</label>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={3}
          placeholder="Any damage or notes..."
          className="w-full px-4 py-2.5 bg-secondary border border-main rounded-lg text-main placeholder:text-muted text-sm resize-none"
        />
      </div>

      {error && <p className="text-sm text-red-500">{error}</p>}

      {/* Submit */}
      <button
        onClick={handleSubmit}
        disabled={saving}
        className={cn(
          'w-full py-3 rounded-lg text-white font-medium text-sm',
          saving ? 'bg-accent/50 cursor-not-allowed' : 'bg-accent',
        )}
      >
        {saving ? 'Returning...' : 'Confirm Return'}
      </button>
    </div>
  );
}
