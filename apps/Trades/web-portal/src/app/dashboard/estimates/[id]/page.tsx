'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, Plus, Trash2, Search, X, ChevronDown, ChevronRight, Save,
  DollarSign, Package, Wrench, Zap, FileText, Home,
  Calculator, Layers, AlertCircle, Loader2, Shield, Send, Eye,
  Ruler, Pencil, Check, Download, Satellite, ShoppingCart,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import {
  useEstimate, useEstimateItems, fmtCurrency,
  type EstimateArea, type EstimateLineItem, type EstimateItem,
} from '@/lib/hooks/use-estimates';

const ACTION_TYPES = [
  { value: 'remove', label: 'Remove' },
  { value: 'replace', label: 'Replace' },
  { value: 'install', label: 'Install' },
  { value: 'repair', label: 'Repair' },
  { value: 'clean', label: 'Clean' },
  { value: 'treat', label: 'Treat' },
  { value: 'other', label: 'Other' },
];

const TRADES = ['RFG', 'DRY', 'PLM', 'ELE', 'PNT', 'DMO', 'WTR', 'FRM', 'INS', 'SDG', 'HVC'];

const ROOM_PRESETS = [
  'Kitchen', 'Living Room', 'Dining Room', 'Master Bedroom', 'Bedroom 2', 'Bedroom 3',
  'Bathroom', 'Master Bath', 'Laundry', 'Garage', 'Hallway', 'Foyer',
  'Basement', 'Attic', 'Office', 'Exterior - Front', 'Exterior - Back', 'Exterior - Sides', 'Roof',
];

export default function EstimateEditorPage() {
  const params = useParams();
  const router = useRouter();
  const estimateId = params.id as string;

  const {
    estimate, areas, lineItems, loading, error,
    updateEstimate, addArea, updateArea, deleteArea,
    addLineItem, updateLineItem, deleteLineItem, recalculateTotals, importFromRecon,
  } = useEstimate(estimateId);

  const { items: codeItems, loading: itemsLoading, searchItems } = useEstimateItems();

  // UI State
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [itemSearch, setItemSearch] = useState('');
  const [tradeFilter, setTradeFilter] = useState('');
  const [commonOnly, setCommonOnly] = useState(false);
  const [editingLine, setEditingLine] = useState<string | null>(null);
  const [addingRoom, setAddingRoom] = useState(false);
  const [newRoomName, setNewRoomName] = useState('');
  const [editingHeader, setEditingHeader] = useState(false);
  const [editingInsurance, setEditingInsurance] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [showReconImport, setShowReconImport] = useState(false);
  const [reconImporting, setReconImporting] = useState(false);
  const [showMaterialOrder, setShowMaterialOrder] = useState(false);
  const searchTimer = useRef<ReturnType<typeof setTimeout>>(null);

  // Group line items by area
  const areaLineItems = useMemo(() => {
    const map = new Map<string | null, EstimateLineItem[]>();
    for (const li of lineItems) {
      const key = li.areaId;
      const existing = map.get(key) || [];
      existing.push(li);
      map.set(key, existing);
    }
    return map;
  }, [lineItems]);

  // Computed totals
  const totals = useMemo(() => {
    if (!estimate) return { subtotal: 0, overhead: 0, profit: 0, tax: 0, grand: 0 };
    const subtotal = lineItems.reduce((sum, li) => sum + li.lineTotal, 0);
    const overhead = subtotal * (estimate.overheadPercent / 100);
    const profit = subtotal * (estimate.profitPercent / 100);
    const taxable = subtotal + overhead + profit;
    const tax = taxable * (estimate.taxPercent / 100);
    const grand = taxable + tax;
    return { subtotal, overhead, profit, tax, grand };
  }, [estimate, lineItems]);

  // Debounced item search
  const handleItemSearch = useCallback((query: string) => {
    setItemSearch(query);
    if (searchTimer.current) clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      searchItems(query, tradeFilter || undefined, commonOnly);
    }, 300);
  }, [searchItems, tradeFilter, commonOnly]);

  useEffect(() => {
    if (sidebarOpen) {
      searchItems(itemSearch, tradeFilter || undefined, commonOnly);
    }
  }, [tradeFilter, commonOnly, sidebarOpen]); // eslint-disable-line react-hooks/exhaustive-deps

  // Add code item to estimate
  const handleAddItem = useCallback(async (item: EstimateItem, areaId?: string) => {
    await addLineItem({
      areaId,
      itemId: item.id,
      zaftoCode: item.zaftoCode,
      description: item.name,
      actionType: 'replace',
      quantity: 1,
      unitCode: item.defaultUnit,
      materialCost: item.materialCost,
      laborCost: item.laborCost,
      equipmentCost: item.equipmentCost,
      unitPrice: item.basePrice,
    });
    await recalculateTotals();
  }, [addLineItem, recalculateTotals]);

  // Add room
  const handleAddRoom = useCallback(async (name: string) => {
    await addArea(name);
    setAddingRoom(false);
    setNewRoomName('');
  }, [addArea]);

  // Line item field update
  const handleLineFieldUpdate = useCallback(async (lineId: string, field: string, value: string | number) => {
    const line = lineItems.find(l => l.id === lineId);
    if (!line) return;

    const updates: Record<string, unknown> = {};
    if (field === 'quantity') {
      const qty = Number(value) || 0;
      updates.quantity = qty;
      updates.line_total = qty * line.unitPrice;
    } else if (field === 'unit_price') {
      const price = Number(value) || 0;
      updates.unit_price = price;
      updates.line_total = line.quantity * price;
    } else if (field === 'action_type') {
      updates.action_type = value;
    } else if (field === 'notes') {
      updates.notes = value;
    } else if (field === 'description') {
      updates.description = value;
    }

    await updateLineItem(lineId, updates);
    await recalculateTotals();
  }, [lineItems, updateLineItem, recalculateTotals]);

  // Delete line with recalc
  const handleDeleteLine = useCallback(async (lineId: string) => {
    await deleteLineItem(lineId);
    await recalculateTotals();
  }, [deleteLineItem, recalculateTotals]);

  // Update O&P rates
  const handleRateChange = useCallback(async (field: string, value: number) => {
    await updateEstimate({ [field]: value });
  }, [updateEstimate]);

  // Export ESX via Edge Function (downloads .esx file)
  const handleExportEsx = useCallback(async () => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;
    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const url = `${baseUrl}/functions/v1/export-esx?estimate_id=${estimateId}`;
    const res = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
      },
    });
    if (!res.ok) return;
    const blob = await res.blob();
    const blobUrl = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = blobUrl;
    a.download = `${estimate?.estimateNumber || 'estimate'}.esx`;
    a.click();
    URL.revokeObjectURL(blobUrl);
  }, [estimateId, estimate?.estimateNumber]);

  // Download PDF via Edge Function (fetches HTML, opens in new tab for print)
  const handleDownloadPdf = useCallback(async (template: 'standard' | 'detailed' | 'summary' = 'standard') => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;
    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const url = `${baseUrl}/functions/v1/export-estimate-pdf?estimate_id=${estimateId}&template=${template}`;
    const res = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
      },
    });
    if (!res.ok) return;
    const html = await res.text();
    const blob = new Blob([html], { type: 'text/html' });
    const blobUrl = URL.createObjectURL(blob);
    window.open(blobUrl, '_blank');
  }, [estimateId]);

  // Send estimate
  const handleSend = useCallback(async () => {
    await recalculateTotals();
    await updateEstimate({ status: 'sent', sent_at: new Date().toISOString() });
  }, [recalculateTotals, updateEstimate]);

  // ── Loading ──
  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-6 h-6 text-zinc-500 animate-spin" />
      </div>
    );
  }

  if (!estimate) {
    return (
      <div className="text-center py-16 text-zinc-500">
        <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
        <p className="text-lg font-medium">Estimate not found</p>
        <button onClick={() => router.push('/dashboard/estimates')} className="text-sm text-blue-400 hover:underline mt-2">
          Back to estimates
        </button>
      </div>
    );
  }

  if (showPreview) {
    return (
      <EstimatePreview
        estimate={estimate}
        areas={areas}
        lineItems={lineItems}
        areaLineItems={areaLineItems}
        totals={totals}
        onBack={() => setShowPreview(false)}
      />
    );
  }

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      {/* ── Main Content ── */}
      <div className={cn('flex-1 overflow-y-auto', sidebarOpen && 'mr-[380px]')}>
        {/* Header */}
        <div className="sticky top-0 z-10 bg-zinc-900/95 backdrop-blur border-b border-zinc-800 px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button onClick={() => router.push('/dashboard/estimates')} className="p-1.5 rounded-lg hover:bg-zinc-800 text-zinc-400">
                <ArrowLeft className="w-4 h-4" />
              </button>
              <div>
                <div className="flex items-center gap-2">
                  <h1 className="text-lg font-semibold text-zinc-100">{estimate.estimateNumber}</h1>
                  <span className={cn(
                    'text-[10px] px-1.5 py-0.5 rounded-full capitalize',
                    estimate.status === 'draft' ? 'bg-zinc-700/50 text-zinc-400' :
                    estimate.status === 'approved' ? 'bg-green-500/10 text-green-400' :
                    estimate.status === 'sent' ? 'bg-blue-500/10 text-blue-400' :
                    'bg-zinc-700/50 text-zinc-400'
                  )}>
                    {estimate.status}
                  </span>
                  {estimate.estimateType === 'insurance' && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-purple-500/10 text-purple-400">Insurance</span>
                  )}
                </div>
                <p className="text-xs text-zinc-500">
                  {estimate.title} &middot; {estimate.customerName || 'No customer'}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button onClick={() => setShowPreview(true)} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800">
                <Eye className="w-3.5 h-3.5" />
                Preview
              </button>
              <button onClick={() => handleDownloadPdf('standard')} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800">
                <Download className="w-3.5 h-3.5" />
                PDF
              </button>
              {estimate.estimateType === 'insurance' && (
                <button onClick={handleExportEsx} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800">
                  <FileText className="w-3.5 h-3.5" />
                  .esx
                </button>
              )}
              {estimate.status === 'draft' && (
                <button onClick={handleSend} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-white bg-blue-600 rounded-lg hover:bg-blue-500">
                  <Send className="w-3.5 h-3.5" />
                  Send
                </button>
              )}
              <button
                onClick={() => setShowReconImport(!showReconImport)}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-emerald-300 bg-emerald-500/10 border border-emerald-500/20 rounded-lg hover:bg-emerald-500/20"
              >
                <Satellite className="w-3.5 h-3.5" />
                Import from Recon
              </button>
              {estimate.propertyScanId && (
                <button
                  onClick={() => setShowMaterialOrder(!showMaterialOrder)}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-orange-300 bg-orange-500/10 border border-orange-500/20 rounded-lg hover:bg-orange-500/20"
                >
                  <ShoppingCart className="w-3.5 h-3.5" />
                  Order Materials
                </button>
              )}
              <button
                onClick={() => setSidebarOpen(!sidebarOpen)}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border transition-colors',
                  sidebarOpen
                    ? 'text-blue-400 bg-blue-500/10 border-blue-500/20'
                    : 'text-zinc-300 bg-zinc-800/50 border-zinc-700/50 hover:bg-zinc-800'
                )}
              >
                <Search className="w-3.5 h-3.5" />
                Item Browser
              </button>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* ── Estimate Header Card ── */}
          <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-zinc-200 flex items-center gap-2">
                <FileText className="w-4 h-4 text-zinc-400" />
                Estimate Details
              </h3>
              <button onClick={() => setEditingHeader(!editingHeader)} className="text-xs text-blue-400 hover:underline">
                {editingHeader ? 'Done' : 'Edit'}
              </button>
            </div>
            {editingHeader ? (
              <EstimateHeaderForm estimate={estimate} onUpdate={updateEstimate} />
            ) : (
              <div className="grid grid-cols-2 gap-x-8 gap-y-2 text-xs">
                <div><span className="text-zinc-500">Title:</span> <span className="text-zinc-200 ml-2">{estimate.title || '—'}</span></div>
                <div><span className="text-zinc-500">Customer:</span> <span className="text-zinc-200 ml-2">{estimate.customerName || '—'}</span></div>
                <div><span className="text-zinc-500">Address:</span> <span className="text-zinc-200 ml-2">{estimate.propertyAddress || '—'}</span></div>
                <div><span className="text-zinc-500">City/State/Zip:</span> <span className="text-zinc-200 ml-2">{[estimate.propertyCity, estimate.propertyState, estimate.propertyZip].filter(Boolean).join(', ') || '—'}</span></div>
              </div>
            )}
          </div>

          {/* ── Insurance Details Card ── */}
          {estimate.estimateType === 'insurance' && (
            <div className="bg-purple-500/5 border border-purple-500/10 rounded-xl p-5">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-medium text-purple-300 flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  Insurance Details
                </h3>
                <button onClick={() => setEditingInsurance(!editingInsurance)} className="text-xs text-purple-400 hover:underline">
                  {editingInsurance ? 'Done' : 'Edit'}
                </button>
              </div>
              {editingInsurance ? (
                <InsuranceForm estimate={estimate} onUpdate={updateEstimate} />
              ) : (
                <div className="grid grid-cols-2 gap-x-8 gap-y-2 text-xs">
                  <div><span className="text-zinc-500">Claim #:</span> <span className="text-zinc-200 ml-2">{estimate.claimNumber || '—'}</span></div>
                  <div><span className="text-zinc-500">Policy #:</span> <span className="text-zinc-200 ml-2">{estimate.policyNumber || '—'}</span></div>
                  <div><span className="text-zinc-500">Carrier:</span> <span className="text-zinc-200 ml-2">{estimate.carrierName || '—'}</span></div>
                  <div><span className="text-zinc-500">Adjuster:</span> <span className="text-zinc-200 ml-2">{estimate.adjusterName || '—'}</span></div>
                  <div><span className="text-zinc-500">Deductible:</span> <span className="text-zinc-200 ml-2">${fmtCurrency(estimate.deductible)}</span></div>
                  <div><span className="text-zinc-500">Date of Loss:</span> <span className="text-zinc-200 ml-2">{estimate.dateOfLoss ? new Date(estimate.dateOfLoss).toLocaleDateString() : '—'}</span></div>
                </div>
              )}
            </div>
          )}

          {/* ── Add Room ── */}
          <div className="flex items-center gap-2">
            {addingRoom ? (
              <div className="flex items-center gap-2 flex-wrap">
                <Home className="w-4 h-4 text-zinc-500" />
                <input
                  type="text"
                  value={newRoomName}
                  onChange={(e) => setNewRoomName(e.target.value)}
                  placeholder="Room name..."
                  className="px-3 py-1.5 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500 w-48"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && newRoomName.trim()) handleAddRoom(newRoomName.trim());
                    if (e.key === 'Escape') { setAddingRoom(false); setNewRoomName(''); }
                  }}
                />
                <button onClick={() => { setAddingRoom(false); setNewRoomName(''); }} className="p-1 text-zinc-500 hover:text-zinc-300">
                  <X className="w-4 h-4" />
                </button>
                <div className="w-full flex flex-wrap gap-1 mt-1">
                  {ROOM_PRESETS.filter(r => !areas.some(a => a.name === r)).slice(0, 12).map((preset) => (
                    <button
                      key={preset}
                      onClick={() => handleAddRoom(preset)}
                      className="px-2 py-1 text-[10px] text-zinc-400 bg-zinc-800/50 border border-zinc-700/50 rounded hover:text-zinc-200 hover:border-zinc-600"
                    >
                      {preset}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <button onClick={() => setAddingRoom(true)} className="flex items-center gap-1.5 text-xs text-zinc-400 hover:text-zinc-200">
                <Plus className="w-3.5 h-3.5" />
                Add Room / Area
              </button>
            )}
          </div>

          {/* ── Area Sections ── */}
          {areas.length === 0 && lineItems.length === 0 ? (
            <div className="text-center py-16 text-zinc-500">
              <Calculator className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p className="text-lg font-medium">No rooms or line items yet</p>
              <p className="text-sm mt-1">Add a room above, then use the Item Browser to add line items</p>
              <button
                onClick={() => setSidebarOpen(true)}
                className="mt-4 flex items-center gap-1.5 mx-auto px-4 py-2 text-sm text-blue-400 bg-blue-500/10 border border-blue-500/20 rounded-lg hover:bg-blue-500/20"
              >
                <Search className="w-4 h-4" />
                Open Item Browser
              </button>
            </div>
          ) : (
            <>
              {areas.map((area) => (
                <AreaSection
                  key={area.id}
                  area={area}
                  lines={areaLineItems.get(area.id) || []}
                  editingLine={editingLine}
                  onEditLine={setEditingLine}
                  onUpdateLine={handleLineFieldUpdate}
                  onDeleteLine={handleDeleteLine}
                  onDeleteArea={deleteArea}
                  onUpdateArea={updateArea}
                  onOpenBrowser={() => setSidebarOpen(true)}
                />
              ))}

              {/* Unassigned line items */}
              {(areaLineItems.get(null) || []).length > 0 && (
                <AreaSection
                  area={null}
                  lines={areaLineItems.get(null) || []}
                  editingLine={editingLine}
                  onEditLine={setEditingLine}
                  onUpdateLine={handleLineFieldUpdate}
                  onDeleteLine={handleDeleteLine}
                  onDeleteArea={() => {}}
                  onUpdateArea={() => {}}
                  onOpenBrowser={() => setSidebarOpen(true)}
                />
              )}

              {/* ── Totals Panel ── */}
              <TotalsPanel
                estimate={estimate}
                totals={totals}
                lineCount={lineItems.length}
                onRateChange={handleRateChange}
              />
            </>
          )}
        </div>
      </div>

      {/* ── Sidebar: Item Browser ── */}
      {sidebarOpen && (
        <div className="fixed right-0 top-16 bottom-0 w-[380px] bg-zinc-900 border-l border-zinc-800 flex flex-col z-20">
          <div className="flex items-center justify-between px-4 py-3 border-b border-zinc-800">
            <span className="text-sm font-medium text-zinc-200">ZAFTO Code Database</span>
            <button onClick={() => setSidebarOpen(false)} className="p-1 text-zinc-500 hover:text-zinc-300">
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Search + Filters */}
          <div className="p-3 space-y-2 border-b border-zinc-800">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-zinc-500" />
              <input
                type="text"
                value={itemSearch}
                onChange={(e) => handleItemSearch(e.target.value)}
                placeholder="Search codes or descriptions..."
                className="w-full pl-8 pr-3 py-1.5 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-xs text-zinc-100 placeholder:text-zinc-500"
              />
            </div>
            {/* Trade chips */}
            <div className="flex flex-wrap gap-1">
              <button
                onClick={() => setTradeFilter('')}
                className={cn(
                  'px-2 py-1 text-[10px] rounded transition-colors',
                  !tradeFilter ? 'bg-blue-500/10 text-blue-400' : 'text-zinc-500 hover:text-zinc-300'
                )}
              >
                All
              </button>
              {TRADES.map((t) => (
                <button
                  key={t}
                  onClick={() => setTradeFilter(tradeFilter === t ? '' : t)}
                  className={cn(
                    'px-2 py-1 text-[10px] rounded transition-colors',
                    tradeFilter === t ? 'bg-blue-500/10 text-blue-400' : 'text-zinc-500 hover:text-zinc-300'
                  )}
                >
                  {t}
                </button>
              ))}
            </div>
            <label className="flex items-center gap-2 text-xs text-zinc-400">
              <input
                type="checkbox"
                checked={commonOnly}
                onChange={(e) => setCommonOnly(e.target.checked)}
                className="rounded border-zinc-600"
              />
              Common items only
            </label>
          </div>

          {/* Item list */}
          <div className="flex-1 overflow-y-auto">
            {itemsLoading ? (
              <div className="p-4 space-y-2">
                {[1, 2, 3, 4, 5].map(i => (
                  <div key={i} className="h-12 bg-zinc-800/50 rounded animate-pulse" />
                ))}
              </div>
            ) : codeItems.length === 0 ? (
              <div className="p-6 text-center text-zinc-500 text-xs">
                {itemSearch ? 'No items found' : 'Search or filter by trade to browse items'}
              </div>
            ) : (
              <div className="divide-y divide-zinc-800/50">
                {codeItems.map(item => (
                  <ItemRow
                    key={item.id}
                    item={item}
                    areas={areas}
                    onAdd={handleAddItem}
                  />
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ── Recon Import Panel ── */}
      {showReconImport && estimate && (
        <ReconImportPanel
          jobId={estimate.jobId}
          onImport={async (scanId: string, trade: string) => {
            setReconImporting(true);
            const count = await importFromRecon(scanId, trade);
            setReconImporting(false);
            if (count > 0) {
              await recalculateTotals();
              setShowReconImport(false);
            }
          }}
          importing={reconImporting}
          onClose={() => setShowReconImport(false)}
        />
      )}

      {/* ── Material Order Panel ── */}
      {showMaterialOrder && estimate?.propertyScanId && (
        <MaterialOrderPanel
          scanId={estimate.propertyScanId}
          onClose={() => setShowMaterialOrder(false)}
        />
      )}
    </div>
  );
}

// ── Recon Import Panel ──

function ReconImportPanel({
  jobId,
  onImport,
  importing,
  onClose,
}: {
  jobId: string | null;
  onImport: (scanId: string, trade: string) => void;
  importing: boolean;
  onClose: () => void;
}) {
  const [scans, setScans] = useState<Array<{ id: string; address: string; status: string; confidence_score: number }>>([]);
  const [trades, setTrades] = useState<Array<{ trade: string; material_count: number }>>([]);
  const [selectedScan, setSelectedScan] = useState<string | null>(null);
  const [loadingScans, setLoadingScans] = useState(true);

  useEffect(() => {
    const load = async () => {
      const supabase = getSupabase();

      // If job-linked, get that scan first
      if (jobId) {
        const { data } = await supabase
          .from('property_scans')
          .select('id, address, status, confidence_score')
          .eq('job_id', jobId)
          .is('deleted_at', null)
          .order('created_at', { ascending: false })
          .limit(1);

        if (data && data.length > 0) {
          setScans(data);
          setSelectedScan(data[0].id);
          setLoadingScans(false);
          return;
        }
      }

      // Otherwise, show all company scans
      const { data } = await supabase
        .from('property_scans')
        .select('id, address, status, confidence_score')
        .is('deleted_at', null)
        .in('status', ['complete', 'partial'])
        .order('created_at', { ascending: false })
        .limit(20);

      setScans(data || []);
      if (data && data.length > 0) setSelectedScan(data[0].id);
      setLoadingScans(false);
    };
    load();
  }, [jobId]);

  // Load trades when scan is selected
  useEffect(() => {
    if (!selectedScan) return;
    const load = async () => {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('trade_bid_data')
        .select('trade, material_list')
        .eq('scan_id', selectedScan);

      setTrades((data || []).map((d: Record<string, unknown>) => ({
        trade: d.trade as string,
        material_count: ((d.material_list as unknown[]) || []).length,
      })));
    };
    load();
  }, [selectedScan]);

  const TRADE_NAMES: Record<string, string> = {
    roofing: 'Roofing', siding: 'Siding', gutters: 'Gutters', solar: 'Solar',
    painting: 'Painting', landscaping: 'Landscaping', fencing: 'Fencing',
    concrete: 'Concrete', hvac: 'HVAC', electrical: 'Electrical',
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-zinc-900 border border-zinc-700 rounded-xl w-[480px] max-h-[80vh] overflow-y-auto">
        <div className="flex items-center justify-between px-5 py-4 border-b border-zinc-800">
          <div className="flex items-center gap-2">
            <Satellite className="w-4 h-4 text-emerald-400" />
            <span className="text-sm font-semibold text-zinc-100">Import from Recon</span>
          </div>
          <button onClick={onClose} className="p-1 text-zinc-500 hover:text-zinc-300">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {loadingScans ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="w-5 h-5 animate-spin text-zinc-500" />
            </div>
          ) : scans.length === 0 ? (
            <p className="text-sm text-zinc-500 text-center py-8">
              No property scans available. Create a job and run a scan first.
            </p>
          ) : (
            <>
              {/* Scan selector */}
              <div>
                <label className="text-xs text-zinc-400 mb-1.5 block">Property Scan</label>
                <select
                  value={selectedScan || ''}
                  onChange={e => setSelectedScan(e.target.value)}
                  className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100"
                >
                  {scans.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.address} ({s.confidence_score}% confidence)
                    </option>
                  ))}
                </select>
              </div>

              {/* Trade buttons */}
              {trades.length > 0 ? (
                <div>
                  <label className="text-xs text-zinc-400 mb-1.5 block">Select trade to import materials</label>
                  <div className="grid grid-cols-2 gap-2">
                    {trades.map(t => (
                      <button
                        key={t.trade}
                        onClick={() => selectedScan && onImport(selectedScan, t.trade)}
                        disabled={importing}
                        className="flex items-center justify-between px-3 py-2.5 bg-zinc-800 border border-zinc-700 rounded-lg hover:border-emerald-500/50 hover:bg-emerald-500/5 transition-colors text-left"
                      >
                        <span className="text-sm text-zinc-200">{TRADE_NAMES[t.trade] || t.trade}</span>
                        <span className="text-[10px] text-zinc-500">{t.material_count} items</span>
                      </button>
                    ))}
                  </div>
                </div>
              ) : selectedScan ? (
                <p className="text-sm text-zinc-500 text-center py-4">
                  No trade data generated for this scan. Run trade estimation first.
                </p>
              ) : null}

              {importing && (
                <div className="flex items-center gap-2 text-sm text-emerald-400">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Importing materials...
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Estimate Header Form ──

function EstimateHeaderForm({
  estimate,
  onUpdate,
}: {
  estimate: { title: string; customerName: string; customerEmail: string; customerPhone: string; propertyAddress: string; propertyCity: string; propertyState: string; propertyZip: string; notes: string };
  onUpdate: (u: Record<string, unknown>) => Promise<void>;
}) {
  return (
    <div className="grid grid-cols-2 gap-3">
      <input type="text" defaultValue={estimate.title} onBlur={(e) => onUpdate({ title: e.target.value })}
        placeholder="Title" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.customerName} onBlur={(e) => onUpdate({ customer_name: e.target.value })}
        placeholder="Customer name" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="email" defaultValue={estimate.customerEmail} onBlur={(e) => onUpdate({ customer_email: e.target.value })}
        placeholder="Customer email" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="tel" defaultValue={estimate.customerPhone} onBlur={(e) => onUpdate({ customer_phone: e.target.value })}
        placeholder="Customer phone" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.propertyAddress} onBlur={(e) => onUpdate({ property_address: e.target.value })}
        placeholder="Address" className="col-span-2 px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.propertyCity} onBlur={(e) => onUpdate({ property_city: e.target.value })}
        placeholder="City" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <div className="flex gap-2">
        <input type="text" defaultValue={estimate.propertyState} onBlur={(e) => onUpdate({ property_state: e.target.value })}
          placeholder="State" className="w-20 px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
        <input type="text" defaultValue={estimate.propertyZip} onBlur={(e) => onUpdate({ property_zip: e.target.value })}
          placeholder="ZIP" className="flex-1 px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      </div>
      <textarea defaultValue={estimate.notes} onBlur={(e) => onUpdate({ notes: e.target.value })}
        placeholder="Notes..." rows={2} className="col-span-2 px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500 resize-none" />
    </div>
  );
}

// ── Insurance Form ──

function InsuranceForm({
  estimate,
  onUpdate,
}: {
  estimate: { claimNumber: string; policyNumber: string; carrierName: string; adjusterName: string; adjusterEmail: string; adjusterPhone: string; deductible: number; dateOfLoss: string | null };
  onUpdate: (u: Record<string, unknown>) => Promise<void>;
}) {
  return (
    <div className="grid grid-cols-2 gap-3">
      <input type="text" defaultValue={estimate.claimNumber} onBlur={(e) => onUpdate({ claim_number: e.target.value })}
        placeholder="Claim #" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.policyNumber} onBlur={(e) => onUpdate({ policy_number: e.target.value })}
        placeholder="Policy #" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.carrierName} onBlur={(e) => onUpdate({ carrier_name: e.target.value })}
        placeholder="Carrier name" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="text" defaultValue={estimate.adjusterName} onBlur={(e) => onUpdate({ adjuster_name: e.target.value })}
        placeholder="Adjuster name" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="email" defaultValue={estimate.adjusterEmail} onBlur={(e) => onUpdate({ adjuster_email: e.target.value })}
        placeholder="Adjuster email" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="tel" defaultValue={estimate.adjusterPhone} onBlur={(e) => onUpdate({ adjuster_phone: e.target.value })}
        placeholder="Adjuster phone" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="number" step="0.01" defaultValue={estimate.deductible} onBlur={(e) => onUpdate({ deductible: Number(e.target.value) || 0 })}
        placeholder="Deductible" className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100 placeholder:text-zinc-500" />
      <input type="date" defaultValue={estimate.dateOfLoss || ''} onBlur={(e) => onUpdate({ date_of_loss: e.target.value || null })}
        className="px-2 py-1.5 bg-zinc-800 border border-zinc-700 rounded text-xs text-zinc-100" />
    </div>
  );
}

// ── Area Section ──

function AreaSection({
  area,
  lines,
  editingLine,
  onEditLine,
  onUpdateLine,
  onDeleteLine,
  onDeleteArea,
  onUpdateArea,
  onOpenBrowser,
}: {
  area: EstimateArea | null;
  lines: EstimateLineItem[];
  editingLine: string | null;
  onEditLine: (id: string | null) => void;
  onUpdateLine: (id: string, field: string, value: string | number) => void;
  onDeleteLine: (id: string) => void;
  onDeleteArea: (id: string) => void;
  onUpdateArea: (id: string, updates: Record<string, unknown>) => void;
  onOpenBrowser: () => void;
}) {
  const [collapsed, setCollapsed] = useState(false);
  const [showDimensions, setShowDimensions] = useState(false);
  const areaTotal = lines.reduce((sum, l) => sum + l.lineTotal, 0);

  return (
    <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl overflow-hidden">
      {/* Area Header */}
      <div className="flex items-center justify-between px-4 py-3 hover:bg-zinc-800/40 transition-colors">
        <button onClick={() => setCollapsed(!collapsed)} className="flex items-center gap-2 flex-1">
          {collapsed ? <ChevronRight className="w-4 h-4 text-zinc-500" /> : <ChevronDown className="w-4 h-4 text-zinc-500" />}
          <Home className="w-4 h-4 text-zinc-400" />
          <span className="text-sm font-medium text-zinc-200">{area?.name || 'Unassigned'}</span>
          <span className="text-xs text-zinc-500">{lines.length} items</span>
        </button>
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-zinc-200">${fmtCurrency(areaTotal)}</span>
          {area && (
            <>
              <button onClick={() => setShowDimensions(!showDimensions)} className="p-1 text-zinc-500 hover:text-zinc-300" title="Dimensions">
                <Ruler className="w-3.5 h-3.5" />
              </button>
              <button onClick={() => onDeleteArea(area.id)} className="p-1 text-zinc-600 hover:text-red-400">
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </>
          )}
        </div>
      </div>

      {/* Dimensions */}
      {showDimensions && area && (
        <div className="px-4 py-3 bg-zinc-800/20 border-t border-zinc-800/50">
          <div className="grid grid-cols-4 gap-2">
            {[
              { label: 'Length (ft)', field: 'length_ft', value: area.lengthFt },
              { label: 'Width (ft)', field: 'width_ft', value: area.widthFt },
              { label: 'Height (ft)', field: 'height_ft', value: area.heightFt },
              { label: 'Windows', field: 'window_count', value: area.windowCount },
            ].map((dim) => (
              <div key={dim.field}>
                <label className="text-[10px] text-zinc-500 block mb-1">{dim.label}</label>
                <input
                  type="number"
                  step="0.1"
                  defaultValue={dim.value}
                  onBlur={(e) => {
                    const val = Number(e.target.value) || 0;
                    onUpdateArea(area.id, { [dim.field]: val });
                  }}
                  className="w-full px-2 py-1 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200"
                />
              </div>
            ))}
          </div>
          {area.lengthFt > 0 && area.widthFt > 0 && (
            <div className="flex items-center gap-4 mt-2 text-[10px] text-zinc-500">
              <span>Floor: {(area.lengthFt * area.widthFt).toFixed(1)} SF</span>
              <span>Perimeter: {((area.lengthFt + area.widthFt) * 2).toFixed(1)} LF</span>
              <span>Wall: {(((area.lengthFt + area.widthFt) * 2) * area.heightFt).toFixed(1)} SF</span>
            </div>
          )}
        </div>
      )}

      {!collapsed && (
        <div className="border-t border-zinc-700/30">
          {/* Column headers */}
          <div className="grid grid-cols-[1fr_70px_70px_80px_90px_36px] gap-2 px-4 py-2 text-[10px] uppercase tracking-wider text-zinc-600 border-b border-zinc-800/50">
            <span>Item</span>
            <span className="text-right">Qty</span>
            <span className="text-right">Unit $</span>
            <span className="text-right">Total</span>
            <span className="text-center">Action</span>
            <span />
          </div>

          {/* Line items */}
          {lines.map((line) => (
            <LineItemRow
              key={line.id}
              line={line}
              isEditing={editingLine === line.id}
              onEdit={() => onEditLine(editingLine === line.id ? null : line.id)}
              onUpdate={onUpdateLine}
              onDelete={() => onDeleteLine(line.id)}
            />
          ))}

          {/* Add line button */}
          <div className="px-4 py-2 border-t border-zinc-800/50">
            <button onClick={onOpenBrowser} className="flex items-center gap-1.5 text-xs text-zinc-500 hover:text-zinc-300">
              <Plus className="w-3.5 h-3.5" />
              Add line item
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Line Item Row ──

function LineItemRow({
  line, isEditing, onEdit, onUpdate, onDelete,
}: {
  line: EstimateLineItem;
  isEditing: boolean;
  onEdit: () => void;
  onUpdate: (id: string, field: string, value: string | number) => void;
  onDelete: () => void;
}) {
  return (
    <div className="group">
      <div
        className={cn(
          'grid grid-cols-[1fr_70px_70px_80px_90px_36px] gap-2 px-4 py-2.5 items-center transition-colors cursor-pointer',
          isEditing ? 'bg-zinc-800/60' : 'hover:bg-zinc-800/30'
        )}
        onClick={onEdit}
      >
        <div className="min-w-0">
          <div className="flex items-center gap-1.5">
            {line.zaftoCode && <span className="text-[10px] font-mono text-blue-400">{line.zaftoCode}</span>}
          </div>
          <p className="text-xs text-zinc-300 truncate">{line.description}</p>
          {line.notes && <p className="text-[10px] text-zinc-600 truncate mt-0.5">{line.notes}</p>}
        </div>

        <div className="text-right">
          {isEditing ? (
            <input type="number" value={line.quantity}
              onChange={(e) => onUpdate(line.id, 'quantity', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()} />
          ) : (
            <span className="text-xs text-zinc-300">{line.quantity} {line.unitCode}</span>
          )}
        </div>

        <div className="text-right">
          {isEditing ? (
            <input type="number" step="0.01" value={line.unitPrice}
              onChange={(e) => onUpdate(line.id, 'unit_price', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()} />
          ) : (
            <span className="text-xs text-zinc-300">${fmtCurrency(line.unitPrice)}</span>
          )}
        </div>

        <span className="text-xs text-right font-medium text-zinc-200">${fmtCurrency(line.lineTotal)}</span>

        <div className="flex justify-center">
          {isEditing ? (
            <select value={line.actionType}
              onChange={(e) => { onUpdate(line.id, 'action_type', e.target.value); e.stopPropagation(); }}
              className="text-[10px] px-1 py-0.5 bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()}>
              {ACTION_TYPES.map(a => <option key={a.value} value={a.value}>{a.label}</option>)}
            </select>
          ) : (
            <span className="text-[10px] px-1.5 py-0.5 rounded bg-zinc-700/50 text-zinc-400 capitalize">{line.actionType}</span>
          )}
        </div>

        <div className="flex justify-center">
          <button onClick={(e) => { e.stopPropagation(); onDelete(); }}
            className="p-1 text-zinc-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity">
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Expanded edit row */}
      {isEditing && (
        <div className="px-4 py-2 bg-zinc-800/40 border-t border-zinc-800/50 grid grid-cols-3 gap-3">
          <div className="flex items-center gap-2">
            <Package className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">MAT:</span>
            <span className="text-xs text-zinc-300">${fmtCurrency(line.materialCost)}</span>
          </div>
          <div className="flex items-center gap-2">
            <Wrench className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">LAB:</span>
            <span className="text-xs text-zinc-300">${fmtCurrency(line.laborCost)}</span>
          </div>
          <div className="flex items-center gap-2">
            <Zap className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">EQU:</span>
            <span className="text-xs text-zinc-300">${fmtCurrency(line.equipmentCost)}</span>
          </div>
          <div className="col-span-3">
            <input type="text" value={line.notes}
              onChange={(e) => onUpdate(line.id, 'notes', e.target.value)}
              placeholder="Notes..."
              className="w-full px-2 py-1 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 placeholder:text-zinc-600"
              onClick={(e) => e.stopPropagation()} />
          </div>
        </div>
      )}
    </div>
  );
}

// ── Item Row (Sidebar) ──

function ItemRow({
  item, areas, onAdd,
}: {
  item: EstimateItem;
  areas: EstimateArea[];
  onAdd: (item: EstimateItem, areaId?: string) => void;
}) {
  const [showPicker, setShowPicker] = useState(false);

  return (
    <div className="px-3 py-2.5 hover:bg-zinc-800/30 transition-colors">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] font-mono font-medium text-blue-400">{item.zaftoCode}</span>
            <span className="text-[10px] px-1 py-0.5 rounded bg-zinc-700/50 text-zinc-500">{item.trade}</span>
          </div>
          <p className="text-xs text-zinc-300 mt-0.5 line-clamp-2">{item.name}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-[10px] text-zinc-600">{item.defaultUnit}</span>
            <span className="text-[10px] text-zinc-500">${fmtCurrency(item.basePrice)}</span>
            <div className="flex items-center gap-1">
              {item.materialCost > 0 && <Package className="w-2.5 h-2.5 text-zinc-600" />}
              {item.laborCost > 0 && <Wrench className="w-2.5 h-2.5 text-zinc-600" />}
              {item.equipmentCost > 0 && <Zap className="w-2.5 h-2.5 text-zinc-600" />}
            </div>
          </div>
        </div>
        <div className="relative flex-shrink-0">
          {showPicker && areas.length > 0 ? (
            <div className="absolute right-0 top-0 bg-zinc-800 border border-zinc-700 rounded-lg shadow-xl p-1.5 min-w-[140px] z-10">
              {areas.map(area => (
                <button key={area.id}
                  onClick={() => { onAdd(item, area.id); setShowPicker(false); }}
                  className="w-full text-left px-2 py-1.5 text-xs text-zinc-300 hover:bg-zinc-700 rounded">
                  {area.name}
                </button>
              ))}
              <button onClick={() => { onAdd(item); setShowPicker(false); }}
                className="w-full text-left px-2 py-1.5 text-xs text-zinc-500 hover:bg-zinc-700 rounded border-t border-zinc-700 mt-1 pt-1.5">
                No room
              </button>
              <button onClick={() => setShowPicker(false)}
                className="w-full text-left px-2 py-1 text-[10px] text-zinc-600 hover:text-zinc-300 mt-1 border-t border-zinc-700 pt-1">
                Cancel
              </button>
            </div>
          ) : (
            <button
              onClick={() => {
                if (areas.length === 0) { onAdd(item); }
                else if (areas.length === 1) { onAdd(item, areas[0].id); }
                else { setShowPicker(true); }
              }}
              className="p-1.5 text-zinc-500 hover:text-blue-400 hover:bg-blue-500/10 rounded-lg transition-colors"
              title="Add to estimate">
              <Plus className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Totals Panel ──

function TotalsPanel({
  estimate, totals, lineCount, onRateChange,
}: {
  estimate: { overheadPercent: number; profitPercent: number; taxPercent: number; estimateType: string; deductible: number };
  totals: { subtotal: number; overhead: number; profit: number; tax: number; grand: number };
  lineCount: number;
  onRateChange: (field: string, value: number) => void;
}) {
  return (
    <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl p-5">
      <h3 className="text-sm font-medium text-zinc-200 mb-4 flex items-center gap-2">
        <Layers className="w-4 h-4 text-zinc-400" />
        Estimate Totals
        <span className="text-xs text-zinc-500 font-normal ml-auto">{lineCount} line items</span>
      </h3>

      <div className="space-y-2.5">
        <div className="flex items-center justify-between text-xs">
          <span className="text-zinc-400">Subtotal</span>
          <span className="text-zinc-200 font-medium">${fmtCurrency(totals.subtotal)}</span>
        </div>

        {/* Overhead */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-zinc-400">Overhead</span>
            <input type="number" min="0" max="100" value={estimate.overheadPercent}
              onChange={(e) => onRateChange('overhead_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 text-right" />
            <span className="text-zinc-600">%</span>
          </div>
          <span className="text-zinc-200">${fmtCurrency(totals.overhead)}</span>
        </div>

        {/* Profit */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-zinc-400">Profit</span>
            <input type="number" min="0" max="100" value={estimate.profitPercent}
              onChange={(e) => onRateChange('profit_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 text-right" />
            <span className="text-zinc-600">%</span>
          </div>
          <span className="text-zinc-200">${fmtCurrency(totals.profit)}</span>
        </div>

        {/* Tax */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-zinc-400">Tax</span>
            <input type="number" min="0" max="100" step="0.01" value={estimate.taxPercent}
              onChange={(e) => onRateChange('tax_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 text-right" />
            <span className="text-zinc-600">%</span>
          </div>
          <span className="text-zinc-200">${fmtCurrency(totals.tax)}</span>
        </div>

        {/* Grand Total */}
        <div className="flex items-center justify-between text-sm pt-2.5 border-t border-zinc-700/50">
          <span className="text-zinc-100 font-semibold">Grand Total</span>
          <span className="text-zinc-100 font-semibold text-lg">${fmtCurrency(totals.grand)}</span>
        </div>

        {/* Insurance net claim */}
        {estimate.estimateType === 'insurance' && estimate.deductible > 0 && (
          <div className="flex items-center justify-between text-xs pt-2 border-t border-zinc-700/50">
            <span className="text-purple-400">Net Claim (after deductible)</span>
            <span className="text-purple-300 font-medium">${fmtCurrency(Math.max(0, totals.grand - estimate.deductible))}</span>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Estimate Preview ──

function EstimatePreview({
  estimate, areas, lineItems, areaLineItems, totals, onBack,
}: {
  estimate: NonNullable<ReturnType<typeof useEstimate>['estimate']>;
  areas: EstimateArea[];
  lineItems: EstimateLineItem[];
  areaLineItems: Map<string | null, EstimateLineItem[]>;
  totals: { subtotal: number; overhead: number; profit: number; tax: number; grand: number };
  onBack: () => void;
}) {
  const handlePdf = async (template: 'standard' | 'detailed' | 'summary') => {
    const supabase = getSupabase();
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) return;
    const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
    const url = `${baseUrl}/functions/v1/export-estimate-pdf?estimate_id=${estimate.id}&template=${template}`;
    const res = await fetch(url, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '',
      },
    });
    if (!res.ok) return;
    const html = await res.text();
    const blob = new Blob([html], { type: 'text/html' });
    const blobUrl = URL.createObjectURL(blob);
    window.open(blobUrl, '_blank');
  };

  return (
    <div className="max-w-3xl mx-auto p-8">
      <div className="flex items-center justify-between mb-6">
        <button onClick={onBack} className="flex items-center gap-1.5 text-xs text-zinc-400 hover:text-zinc-200">
          <ArrowLeft className="w-3.5 h-3.5" />
          Back to editor
        </button>
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-zinc-500 uppercase tracking-wider mr-1">Download PDF</span>
          {(['standard', 'detailed', 'summary'] as const).map((t) => (
            <button key={t} onClick={() => handlePdf(t)}
              className="flex items-center gap-1 px-2.5 py-1.5 text-[11px] text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800 capitalize">
              <Download className="w-3 h-3" />
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Header */}
      <div className="border-b border-zinc-700 pb-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-zinc-100">{estimate.title || 'Estimate'}</h1>
            <p className="text-sm text-zinc-400 mt-1">{estimate.estimateNumber}</p>
          </div>
          <div className="text-right">
            <p className="text-3xl font-bold text-zinc-100">${fmtCurrency(totals.grand)}</p>
            <p className="text-xs text-zinc-500 mt-1 capitalize">{estimate.status}</p>
          </div>
        </div>
      </div>

      {/* Customer + Property */}
      <div className="grid grid-cols-2 gap-8 mb-8">
        <div>
          <h3 className="text-xs uppercase tracking-wider text-zinc-500 mb-2">Customer</h3>
          <p className="text-sm text-zinc-200">{estimate.customerName || '—'}</p>
          {estimate.customerEmail && <p className="text-xs text-zinc-400">{estimate.customerEmail}</p>}
          {estimate.customerPhone && <p className="text-xs text-zinc-400">{estimate.customerPhone}</p>}
        </div>
        <div>
          <h3 className="text-xs uppercase tracking-wider text-zinc-500 mb-2">Property</h3>
          <p className="text-sm text-zinc-200">{estimate.propertyAddress || '—'}</p>
          <p className="text-xs text-zinc-400">{[estimate.propertyCity, estimate.propertyState, estimate.propertyZip].filter(Boolean).join(', ')}</p>
        </div>
      </div>

      {/* Insurance */}
      {estimate.estimateType === 'insurance' && (
        <div className="bg-purple-500/5 border border-purple-500/10 rounded-xl p-5 mb-8">
          <h3 className="text-xs uppercase tracking-wider text-purple-400 mb-3">Insurance Details</h3>
          <div className="grid grid-cols-3 gap-4 text-xs">
            <div><span className="text-zinc-500">Claim:</span> <span className="text-zinc-200 ml-1">{estimate.claimNumber || '—'}</span></div>
            <div><span className="text-zinc-500">Policy:</span> <span className="text-zinc-200 ml-1">{estimate.policyNumber || '—'}</span></div>
            <div><span className="text-zinc-500">Carrier:</span> <span className="text-zinc-200 ml-1">{estimate.carrierName || '—'}</span></div>
            <div><span className="text-zinc-500">Adjuster:</span> <span className="text-zinc-200 ml-1">{estimate.adjusterName || '—'}</span></div>
            <div><span className="text-zinc-500">Deductible:</span> <span className="text-zinc-200 ml-1">${fmtCurrency(estimate.deductible)}</span></div>
            <div><span className="text-zinc-500">Date of Loss:</span> <span className="text-zinc-200 ml-1">{estimate.dateOfLoss ? new Date(estimate.dateOfLoss).toLocaleDateString() : '—'}</span></div>
          </div>
        </div>
      )}

      {/* Line Items by Area */}
      {areas.map((area) => {
        const areaLines = areaLineItems.get(area.id) || [];
        if (areaLines.length === 0) return null;
        const areaTotal = areaLines.reduce((sum, l) => sum + l.lineTotal, 0);
        return (
          <div key={area.id} className="mb-6">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-zinc-200">{area.name}</h3>
              <span className="text-sm text-zinc-400">${fmtCurrency(areaTotal)}</span>
            </div>
            <table className="w-full text-xs">
              <thead>
                <tr className="text-zinc-500 border-b border-zinc-800">
                  <th className="text-left py-1.5 font-medium">Code</th>
                  <th className="text-left py-1.5 font-medium">Description</th>
                  <th className="text-center py-1.5 font-medium">Action</th>
                  <th className="text-right py-1.5 font-medium">Qty</th>
                  <th className="text-right py-1.5 font-medium">Unit $</th>
                  <th className="text-right py-1.5 font-medium">Total</th>
                </tr>
              </thead>
              <tbody>
                {areaLines.map((line) => (
                  <tr key={line.id} className="border-b border-zinc-800/50">
                    <td className="py-1.5 font-mono text-blue-400">{line.zaftoCode || '—'}</td>
                    <td className="py-1.5 text-zinc-300">{line.description}</td>
                    <td className="py-1.5 text-center text-zinc-500 capitalize">{line.actionType}</td>
                    <td className="py-1.5 text-right text-zinc-300">{line.quantity} {line.unitCode}</td>
                    <td className="py-1.5 text-right text-zinc-300">${fmtCurrency(line.unitPrice)}</td>
                    <td className="py-1.5 text-right text-zinc-200 font-medium">${fmtCurrency(line.lineTotal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );
      })}

      {/* Totals */}
      <div className="border-t border-zinc-700 pt-4 mt-8 space-y-2">
        <div className="flex justify-between text-sm"><span className="text-zinc-400">Subtotal</span><span className="text-zinc-200">${fmtCurrency(totals.subtotal)}</span></div>
        <div className="flex justify-between text-sm"><span className="text-zinc-400">Overhead ({estimate.overheadPercent}%)</span><span className="text-zinc-200">${fmtCurrency(totals.overhead)}</span></div>
        <div className="flex justify-between text-sm"><span className="text-zinc-400">Profit ({estimate.profitPercent}%)</span><span className="text-zinc-200">${fmtCurrency(totals.profit)}</span></div>
        {totals.tax > 0 && (
          <div className="flex justify-between text-sm"><span className="text-zinc-400">Tax ({estimate.taxPercent}%)</span><span className="text-zinc-200">${fmtCurrency(totals.tax)}</span></div>
        )}
        <div className="flex justify-between text-lg font-bold pt-2 border-t border-zinc-700">
          <span className="text-zinc-100">Grand Total</span>
          <span className="text-zinc-100">${fmtCurrency(totals.grand)}</span>
        </div>
        {estimate.estimateType === 'insurance' && estimate.deductible > 0 && (
          <div className="flex justify-between text-sm pt-2 border-t border-zinc-700/50">
            <span className="text-purple-400">Net Claim (after ${fmtCurrency(estimate.deductible)} deductible)</span>
            <span className="text-purple-300 font-medium">${fmtCurrency(Math.max(0, totals.grand - estimate.deductible))}</span>
          </div>
        )}
      </div>

      {/* Notes */}
      {estimate.notes && (
        <div className="mt-8">
          <h3 className="text-xs uppercase tracking-wider text-zinc-500 mb-2">Notes</h3>
          <p className="text-sm text-zinc-300 whitespace-pre-wrap">{estimate.notes}</p>
        </div>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// Material Order Panel — pricing comparison from Recon data
// ════════════════════════════════════════════════════════════════

interface PricedMaterial {
  item: string;
  quantity: number;
  unit: string;
  total_with_waste: number;
  suppliers: Array<{
    supplier: string;
    sku: string | null;
    product_name: string | null;
    unit_price: number | null;
    total_price: number | null;
    in_stock: boolean | null;
    url: string | null;
  }>;
  best_price: number | null;
  best_supplier: string | null;
}

function MaterialOrderPanel({ scanId, onClose }: { scanId: string; onClose: () => void }) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pricingAvailable, setPricingAvailable] = useState(false);
  const [trades, setTrades] = useState<Record<string, PricedMaterial[]>>({});
  const [selectedTrade, setSelectedTrade] = useState<string | null>(null);

  const fetchPricing = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const res = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-material-order`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ scan_id: scanId }),
        }
      );

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to load pricing');

      setPricingAvailable(data.pricing_available);
      setTrades(data.trades || {});

      const tradeKeys = Object.keys(data.trades || {});
      if (tradeKeys.length > 0 && !selectedTrade) {
        setSelectedTrade(tradeKeys[0]);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Failed to load material pricing');
    } finally {
      setLoading(false);
    }
  }, [scanId, selectedTrade]);

  useEffect(() => { fetchPricing(); }, [fetchPricing]);

  const tradeKeys = Object.keys(trades);
  const currentMaterials = selectedTrade ? trades[selectedTrade] || [] : [];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-zinc-900 border border-zinc-700/50 rounded-xl w-full max-w-4xl max-h-[85vh] flex flex-col shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-zinc-700/50">
          <div className="flex items-center gap-2">
            <ShoppingCart size={18} className="text-orange-400" />
            <span className="text-sm font-semibold text-zinc-100">Material Pricing</span>
            {!pricingAvailable && !loading && (
              <span className="text-[10px] text-yellow-400 bg-yellow-500/10 border border-yellow-500/20 px-2 py-0.5 rounded">
                Manual pricing mode
              </span>
            )}
          </div>
          <button onClick={onClose} className="p-1 text-zinc-400 hover:text-zinc-200">
            <X size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <Loader2 size={20} className="animate-spin text-zinc-400" />
              <span className="ml-2 text-sm text-zinc-400">Loading material data...</span>
            </div>
          ) : error ? (
            <div className="flex items-center justify-center py-16 text-red-400 gap-2">
              <AlertCircle size={16} />
              <span className="text-sm">{error}</span>
            </div>
          ) : tradeKeys.length === 0 ? (
            <div className="text-center py-16">
              <Package size={32} className="mx-auto text-zinc-600 mb-2" />
              <p className="text-sm text-zinc-400">No trade data found for this property scan.</p>
              <p className="text-xs text-zinc-500 mt-1">Run a property scan with trade estimation first.</p>
            </div>
          ) : (
            <>
              {/* Trade selector */}
              <div className="flex gap-1 mb-4 overflow-x-auto pb-1">
                {tradeKeys.map(trade => (
                  <button
                    key={trade}
                    onClick={() => setSelectedTrade(trade)}
                    className={cn(
                      'px-3 py-1.5 rounded-md text-xs font-medium whitespace-nowrap transition-colors',
                      selectedTrade === trade
                        ? 'bg-orange-500/20 text-orange-300 border border-orange-500/30'
                        : 'text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800 border border-transparent'
                    )}
                  >
                    {trade.charAt(0).toUpperCase() + trade.slice(1)}
                  </button>
                ))}
              </div>

              {!pricingAvailable && (
                <div className="flex items-start gap-2 p-3 rounded-lg bg-yellow-500/5 border border-yellow-500/20 text-yellow-400 text-xs mb-4">
                  <AlertCircle size={14} className="mt-0.5 shrink-0" />
                  <div>
                    <p className="font-medium">Supplier pricing not configured</p>
                    <p className="text-yellow-500/70 mt-0.5">
                      Material quantities are from Recon measurements. Configure supplier API keys in Settings to see real-time pricing from Home Depot and Lowe&apos;s.
                    </p>
                  </div>
                </div>
              )}

              {/* Material list table */}
              <div className="border border-zinc-700/50 rounded-lg overflow-hidden">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="bg-zinc-800/50 text-zinc-400">
                      <th className="text-left px-3 py-2 font-medium">Material</th>
                      <th className="text-right px-3 py-2 font-medium">Qty</th>
                      <th className="text-right px-3 py-2 font-medium">Unit</th>
                      <th className="text-right px-3 py-2 font-medium">W/ Waste</th>
                      {pricingAvailable && (
                        <>
                          <th className="text-right px-3 py-2 font-medium">HD Price</th>
                          <th className="text-right px-3 py-2 font-medium">Lowe&apos;s</th>
                          <th className="text-right px-3 py-2 font-medium">Best</th>
                        </>
                      )}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-zinc-800/50">
                    {currentMaterials.map((mat, i) => {
                      const hd = mat.suppliers.find(s => s.supplier === 'homedepot');
                      const lowes = mat.suppliers.find(s => s.supplier === 'lowes');
                      return (
                        <tr key={i} className="hover:bg-zinc-800/30">
                          <td className="px-3 py-2 text-zinc-200">{mat.item}</td>
                          <td className="px-3 py-2 text-right text-zinc-300">{mat.quantity}</td>
                          <td className="px-3 py-2 text-right text-zinc-400">{mat.unit}</td>
                          <td className="px-3 py-2 text-right text-zinc-300">{mat.total_with_waste}</td>
                          {pricingAvailable && (
                            <>
                              <td className={cn(
                                'px-3 py-2 text-right',
                                mat.best_supplier === 'homedepot' ? 'text-green-400 font-medium' : 'text-zinc-300'
                              )}>
                                {hd?.total_price != null ? `$${hd.total_price.toFixed(2)}` : '-'}
                              </td>
                              <td className={cn(
                                'px-3 py-2 text-right',
                                mat.best_supplier === 'lowes' ? 'text-green-400 font-medium' : 'text-zinc-300'
                              )}>
                                {lowes?.total_price != null ? `$${lowes.total_price.toFixed(2)}` : '-'}
                              </td>
                              <td className="px-3 py-2 text-right text-green-400 font-medium">
                                {mat.best_price != null ? `$${mat.best_price.toFixed(2)}` : '-'}
                              </td>
                            </>
                          )}
                        </tr>
                      );
                    })}
                  </tbody>
                  {pricingAvailable && currentMaterials.length > 0 && (
                    <tfoot>
                      <tr className="bg-zinc-800/30 border-t border-zinc-700/50">
                        <td colSpan={4} className="px-3 py-2 text-right text-zinc-400 font-medium">Total</td>
                        <td className="px-3 py-2 text-right text-zinc-200 font-medium">
                          ${currentMaterials.reduce((sum, m) => {
                            const hd = m.suppliers.find(s => s.supplier === 'homedepot');
                            return sum + (hd?.total_price || 0);
                          }, 0).toFixed(2)}
                        </td>
                        <td className="px-3 py-2 text-right text-zinc-200 font-medium">
                          ${currentMaterials.reduce((sum, m) => {
                            const lowes = m.suppliers.find(s => s.supplier === 'lowes');
                            return sum + (lowes?.total_price || 0);
                          }, 0).toFixed(2)}
                        </td>
                        <td className="px-3 py-2 text-right text-green-400 font-semibold">
                          ${currentMaterials.reduce((sum, m) => sum + (m.best_price || 0), 0).toFixed(2)}
                        </td>
                      </tr>
                    </tfoot>
                  )}
                </table>
              </div>

              {/* Disclaimer */}
              <p className="text-[10px] text-zinc-500 mt-3">
                Quantities calculated from satellite-estimated measurements. Verify before ordering. Prices shown are retail and may vary by location.
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
