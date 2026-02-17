'use client';

// ZAFTO — Client Portal: Content Pack-out Viewer
// Homeowner view of their belongings — item list, condition, estimated return date
// Sprint REST1 — Read-only

import { useState, useEffect, useCallback } from 'react';
import { PackageOpen, AlertTriangle, CheckCircle, Clock, Search } from 'lucide-react';

interface PackoutItem {
  id: string;
  itemDescription: string;
  roomOfOrigin: string;
  category: string;
  condition: string;
  boxNumber: string | null;
  storageLocation: string | null;
  packedAt: string | null;
  returnedAt: string | null;
  estimatedValue: number | null;
}

const conditionLabels: Record<string, string> = {
  salvageable: 'Salvageable',
  non_salvageable: 'Non-Salvageable',
  needs_cleaning: 'Needs Cleaning',
  needs_restoration: 'Needs Restoration',
  questionable: 'Under Review',
};

const conditionColors: Record<string, string> = {
  salvageable: 'text-green-500 bg-green-500/10',
  non_salvageable: 'text-red-500 bg-red-500/10',
  needs_cleaning: 'text-yellow-500 bg-yellow-500/10',
  needs_restoration: 'text-orange-500 bg-orange-500/10',
  questionable: 'text-gray-400 bg-gray-500/10',
};

const categoryLabels: Record<string, string> = {
  electronics: 'Electronics',
  soft_goods: 'Soft Goods',
  hard_goods: 'Hard Goods',
  documents: 'Documents',
  artwork: 'Artwork',
  furniture: 'Furniture',
  clothing: 'Clothing',
  appliances: 'Appliances',
  kitchenware: 'Kitchenware',
  personal: 'Personal',
  tools: 'Tools',
  sporting: 'Sporting Goods',
  other: 'Other',
};

export default function ContentPackoutPage() {
  const [items, setItems] = useState<PackoutItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const fetchItems = useCallback(async () => {
    try {
      setError(null);
      const { getSupabase } = await import('@/lib/supabase');
      const supabase = getSupabase();
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Client portal: fetch via job linkage (client sees their job's content)
      const { data, error: err } = await supabase
        .from('content_packout_items')
        .select('id, item_description, room_of_origin, category, condition, box_number, storage_location, packed_at, returned_at, estimated_value')
        .is('deleted_at', null)
        .order('room_of_origin')
        .order('created_at', { ascending: false })
        .limit(200);

      if (err) throw err;

      setItems(
        (data || []).map((row: Record<string, unknown>) => ({
          id: row.id as string,
          itemDescription: row.item_description as string,
          roomOfOrigin: row.room_of_origin as string,
          category: (row.category as string) || 'other',
          condition: (row.condition as string) || 'needs_cleaning',
          boxNumber: (row.box_number as string) || null,
          storageLocation: (row.storage_location as string) || null,
          packedAt: (row.packed_at as string) || null,
          returnedAt: (row.returned_at as string) || null,
          estimatedValue: (row.estimated_value as number) || null,
        }))
      );
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchItems(); }, [fetchItems]);

  const filtered = items.filter((item) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      item.itemDescription.toLowerCase().includes(q) ||
      item.roomOfOrigin.toLowerCase().includes(q) ||
      (categoryLabels[item.category] || '').toLowerCase().includes(q)
    );
  });

  const totalItems = items.length;
  const returned = items.filter((i) => i.returnedAt).length;
  const inStorage = items.filter((i) => i.packedAt && !i.returnedAt).length;

  return (
    <div className="flex flex-col gap-4 p-4 pb-20">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold">Your Belongings</h1>
        <p className="text-sm text-muted-foreground">
          Track the status of items removed from your home during fire restoration
        </p>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-lg border bg-card p-3 text-center">
          <p className="text-lg font-bold">{totalItems}</p>
          <p className="text-[10px] text-muted-foreground">Total Items</p>
        </div>
        <div className="rounded-lg border bg-card p-3 text-center">
          <p className="text-lg font-bold">{inStorage}</p>
          <p className="text-[10px] text-muted-foreground">In Storage</p>
        </div>
        <div className="rounded-lg border bg-card p-3 text-center">
          <p className="text-lg font-bold text-green-500">{returned}</p>
          <p className="text-[10px] text-muted-foreground">Returned</p>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          placeholder="Search items..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full rounded-lg border bg-card py-2 pl-9 pr-3 text-sm outline-none focus:ring-2 focus:ring-primary"
        />
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : error ? (
        <div className="rounded-lg border border-red-500/30 bg-red-500/5 p-6 text-center">
          <AlertTriangle className="mx-auto mb-2 h-6 w-6 text-red-500" />
          <p className="text-sm text-red-400">{error}</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="rounded-lg border border-dashed p-12 text-center">
          <PackageOpen className="mx-auto mb-3 h-10 w-10 text-muted-foreground/30" />
          <p className="text-sm text-muted-foreground">No items found</p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((item) => (
            <div
              key={item.id}
              className="rounded-lg border bg-card p-3"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="text-sm font-medium">{item.itemDescription}</p>
                  <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{item.roomOfOrigin}</span>
                    <span>|</span>
                    <span>{categoryLabels[item.category] || item.category}</span>
                    {item.boxNumber && (
                      <>
                        <span>|</span>
                        <span>Box {item.boxNumber}</span>
                      </>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {item.returnedAt ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : item.packedAt ? (
                    <Clock className="h-4 w-4 text-yellow-500" />
                  ) : null}
                </div>
              </div>
              <div className="mt-2 flex items-center gap-2">
                <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${conditionColors[item.condition] || conditionColors.questionable}`}>
                  {conditionLabels[item.condition] || item.condition}
                </span>
                {item.returnedAt && (
                  <span className="text-[10px] text-green-500">Returned</span>
                )}
                {item.packedAt && !item.returnedAt && (
                  <span className="text-[10px] text-yellow-500">In Storage</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
