'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, Plus, Trash2, Search, X, ChevronDown, ChevronRight, Save,
  DollarSign, Package, Wrench, Zap, FileText, Home, Receipt, Briefcase,
  Calculator, Layers, AlertCircle, Loader2, Shield, Send, Eye,
  Ruler, Pencil, Check, Download, Satellite, ShoppingCart,
  Star, Copy, BarChart3, ShieldCheck, TrendingUp, TrendingDown, Activity,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { CommandPalette } from '@/components/command-palette';
import { getSupabase } from '@/lib/supabase';
import {
  useEstimate, useEstimateItems, fmtCurrency,
  type EstimateArea, type EstimateLineItem, type EstimateItem,
} from '@/lib/hooks/use-estimates';
import { useBids } from '@/lib/hooks/use-bids';
import { useInvoices } from '@/lib/hooks/use-invoices';
import { useMaterialCatalog, type MaterialTier, type MaterialCatalogItem } from '@/lib/hooks/use-material-catalog';
import { useLaborUnits } from '@/lib/hooks/use-labor-units';
import { useEstimateVersions } from '@/lib/hooks/use-estimate-versions';
import { useLaborRates, type LaborRateResult } from '@/lib/hooks/use-labor-rates';
import { useJobs } from '@/lib/hooks/use-jobs';
import { useTranslation } from '@/lib/translations';
import { formatCurrency, formatDateLocale, formatNumber, formatPercent, formatDateTimeLocale, formatRelativeTimeLocale, formatCompactCurrency, formatTimeLocale } from '@/lib/format-locale';

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

const TIER_CONFIG: { value: MaterialTier; label: string; color: string; bgColor: string; borderColor: string }[] = [
  { value: 'economy', label: 'Economy', color: 'text-slate-400', bgColor: 'bg-slate-500/10', borderColor: 'border-slate-500/20' },
  { value: 'standard', label: 'Standard', color: 'text-blue-400', bgColor: 'bg-blue-500/10', borderColor: 'border-blue-500/20' },
  { value: 'premium', label: 'Premium', color: 'text-amber-400', bgColor: 'bg-amber-500/10', borderColor: 'border-amber-500/20' },
  { value: 'elite', label: 'Elite', color: 'text-purple-400', bgColor: 'bg-purple-500/10', borderColor: 'border-purple-500/20' },
  { value: 'luxury', label: 'Luxury', color: 'text-rose-400', bgColor: 'bg-rose-500/10', borderColor: 'border-rose-500/20' },
];

// G/B/B mapping: Good=economy/standard, Better=premium, Best=elite/luxury
const GBB_TIERS: { key: 'good' | 'better' | 'best'; tiers: MaterialTier[]; label: string; color: string }[] = [
  { key: 'good', tiers: ['economy', 'standard'], label: 'Good', color: 'text-blue-400' },
  { key: 'better', tiers: ['premium'], label: 'Better', color: 'text-amber-400' },
  { key: 'best', tiers: ['elite', 'luxury'], label: 'Best', color: 'text-purple-400' },
];

export default function EstimateEditorPage() {
  const { t, formatDate } = useTranslation();
  const params = useParams();
  const router = useRouter();
  const estimateId = params.id as string;

  const {
    estimate, areas, lineItems, loading, error,
    updateEstimate, addArea, updateArea, deleteArea,
    addLineItem, updateLineItem, deleteLineItem, recalculateTotals, importFromRecon,
  } = useEstimate(estimateId);

  const { items: codeItems, loading: itemsLoading, searchItems } = useEstimateItems();
  const { convertEstimateToBid } = useBids();
  const { materials: catalogMaterials, getMaterialsByTier, getTierEquivalents } = useMaterialCatalog();
  const { units: laborUnits } = useLaborUnits();
  const {
    versions, changeOrders, createVersion, createChangeOrder, totalChangeOrderAmount,
  } = useEstimateVersions(estimateId);
  const { rates: laborRates, loading: laborRatesLoading, lookupRates, getRate } = useLaborRates();
  const [convertingToBid, setConvertingToBid] = useState(false);
  const [convertingToInvoice, setConvertingToInvoice] = useState(false);
  const [convertingToJob, setConvertingToJob] = useState(false);
  const { createInvoiceFromEstimate } = useInvoices();
  const { createJob } = useJobs();

  // Auto-lookup labor rates when estimate ZIP is available
  useEffect(() => {
    if (estimate?.propertyZip && estimate.propertyZip.length >= 5) {
      // Extract unique trades from line items
      const trades = [...new Set(lineItems.map(li => {
        const mat = catalogMaterials.find(m => m.name.toLowerCase() === li.description.toLowerCase());
        return mat?.trade || 'general';
      }))];
      if (trades.length > 0) {
        lookupRates(estimate.propertyZip, trades);
      }
    }
  }, [estimate?.propertyZip, lineItems.length]); // eslint-disable-line react-hooks/exhaustive-deps

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
  const [showTierComparison, setShowTierComparison] = useState(false);
  const [showTemplates, setShowTemplates] = useState(false);
  const [showVersionComparison, setShowVersionComparison] = useState(false);
  const [selectedTier, setSelectedTier] = useState<MaterialTier>('standard');
  const [tierOverrides, setTierOverrides] = useState<Record<string, MaterialTier>>({});
  const [tierSwitching, setTierSwitching] = useState(false);
  const searchTimer = useRef<ReturnType<typeof setTimeout>>(null);

  // Get effective tier for an area (override or global)
  const getAreaTier = useCallback((areaId: string | null) => {
    if (areaId && tierOverrides[areaId]) return tierOverrides[areaId];
    return selectedTier;
  }, [selectedTier, tierOverrides]);

  // One-click tier switching — regenerate all line items to match new tier
  const handleTierSwitch = useCallback(async (newTier: MaterialTier) => {
    setTierSwitching(true);
    try {
      // Snapshot current version before switching
      await createVersion(`Before tier switch to ${newTier}`, {
        tier: selectedTier,
        lineItems: lineItems.map(li => ({ id: li.id, description: li.description, unitPrice: li.unitPrice, materialCost: li.materialCost })),
      });

      // For each line item, find the equivalent material in the new tier
      for (const li of lineItems) {
        const currentMat = catalogMaterials.find(
          m => m.name.toLowerCase() === li.description.toLowerCase() || m.id === li.itemId
        );
        if (!currentMat) continue;

        const equivalents = catalogMaterials.filter(
          m => m.trade === currentMat.trade && m.category === currentMat.category && m.tier === newTier
        );
        if (equivalents.length === 0) continue;

        // Use the first match (or closest by name)
        const match = equivalents[0];
        await updateLineItem(li.id, {
          description: match.name,
          material_cost: match.costPerUnit,
          unit_price: match.costPerUnit + (li.laborCost || 0) + (li.equipmentCost || 0),
          line_total: li.quantity * (match.costPerUnit + (li.laborCost || 0) + (li.equipmentCost || 0)),
        });
      }

      setSelectedTier(newTier);
      setTierOverrides({});
      await recalculateTotals();
    } finally {
      setTierSwitching(false);
    }
  }, [selectedTier, lineItems, catalogMaterials, updateLineItem, recalculateTotals, createVersion]);

  // Per-section tier override
  const handleAreaTierOverride = useCallback(async (areaId: string, newTier: MaterialTier) => {
    setTierOverrides(prev => ({ ...prev, [areaId]: newTier }));

    const areaLines = lineItems.filter(li => li.areaId === areaId);
    for (const li of areaLines) {
      const currentMat = catalogMaterials.find(
        m => m.name.toLowerCase() === li.description.toLowerCase() || m.id === li.itemId
      );
      if (!currentMat) continue;

      const equivalents = catalogMaterials.filter(
        m => m.trade === currentMat.trade && m.category === currentMat.category && m.tier === newTier
      );
      if (equivalents.length === 0) continue;

      const match = equivalents[0];
      await updateLineItem(li.id, {
        description: match.name,
        material_cost: match.costPerUnit,
        unit_price: match.costPerUnit + (li.laborCost || 0) + (li.equipmentCost || 0),
        line_total: li.quantity * (match.costPerUnit + (li.laborCost || 0) + (li.equipmentCost || 0)),
      });
    }
    await recalculateTotals();
  }, [lineItems, catalogMaterials, updateLineItem, recalculateTotals]);

  // Build G/B/B comparison data
  const gbbComparison = useMemo(() => {
    if (!estimate || lineItems.length === 0) return null;

    const buildTierEstimate = (tier: MaterialTier) => {
      let total = 0;
      let warrantyMin = Infinity;
      let warrantyMax = 0;
      const items: Array<{ description: string; unitPrice: number; materialName: string; photoUrl: string | null; warrantyYears: number | null }> = [];

      for (const li of lineItems) {
        const currentMat = catalogMaterials.find(
          m => m.name.toLowerCase() === li.description.toLowerCase() || m.id === li.itemId
        );
        if (!currentMat) {
          items.push({ description: li.description, unitPrice: li.unitPrice, materialName: li.description, photoUrl: null, warrantyYears: null });
          total += li.lineTotal;
          continue;
        }

        const equiv = catalogMaterials.filter(
          m => m.trade === currentMat.trade && m.category === currentMat.category && m.tier === tier
        );
        const match = equiv.length > 0 ? equiv[0] : currentMat;
        const price = match.costPerUnit + (li.laborCost || 0) + (li.equipmentCost || 0);
        items.push({
          description: li.description,
          unitPrice: price,
          materialName: match.name,
          photoUrl: match.photoUrl,
          warrantyYears: match.warrantyYears,
        });
        total += li.quantity * price;

        if (match.warrantyYears != null) {
          warrantyMin = Math.min(warrantyMin, match.warrantyYears);
          warrantyMax = Math.max(warrantyMax, match.warrantyYears);
        }
      }

      const overhead = total * (estimate.overheadPercent / 100);
      const profit = total * (estimate.profitPercent / 100);
      const taxable = total + overhead + profit;
      const tax = taxable * (estimate.taxPercent / 100);

      return {
        tier,
        items,
        subtotal: total,
        overhead,
        profit,
        tax,
        grand: taxable + tax,
        warrantyRange: warrantyMin === Infinity ? null : warrantyMin === warrantyMax ? `${warrantyMin} yr` : `${warrantyMin}-${warrantyMax} yr`,
      };
    };

    return {
      good: buildTierEstimate('standard'),
      better: buildTierEstimate('premium'),
      best: buildTierEstimate('elite'),
    };
  }, [estimate, lineItems, catalogMaterials]);

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

  // Send estimate via email (updates status + calls SendGrid EF)
  const handleSend = useCallback(async () => {
    await recalculateTotals();
    await updateEstimate({ status: 'sent', sent_at: new Date().toISOString() });
    // Actually send the email via SendGrid
    try {
      const supabase = getSupabase();
      await supabase.functions.invoke('sendgrid-email', {
        body: { action: 'send_estimate', entityId: estimateId },
      });
    } catch {
      // Best-effort — status already updated
    }
  }, [recalculateTotals, updateEstimate, estimateId]);

  // Convert estimate to bid
  const handleConvertToBid = useCallback(async () => {
    if (convertingToBid) return;
    setConvertingToBid(true);
    try {
      const bidId = await convertEstimateToBid(estimateId);
      if (bidId) {
        router.push(`/dashboard/bids/${bidId}`);
      }
    } catch {
      // Error handled by hook
    } finally {
      setConvertingToBid(false);
    }
  }, [convertEstimateToBid, estimateId, router, convertingToBid]);

  // Convert estimate to invoice
  const handleConvertToInvoice = useCallback(async () => {
    if (convertingToInvoice) return;
    setConvertingToInvoice(true);
    try {
      const invId = await createInvoiceFromEstimate(estimateId);
      if (invId) {
        router.push(`/dashboard/invoices/${invId}`);
      }
    } catch {
      // Error handled by hook
    } finally {
      setConvertingToInvoice(false);
    }
  }, [createInvoiceFromEstimate, estimateId, router, convertingToInvoice]);

  // Convert estimate to job
  const handleConvertToJob = useCallback(async () => {
    if (convertingToJob || !estimate) return;
    setConvertingToJob(true);
    try {
      const jobId = await createJob({
        title: estimate.title || 'Job from Estimate',
        customerId: estimate.customerId || undefined,
        description: `Created from estimate: ${estimate.title}`,
        status: 'lead',
        address: {
          street: estimate.propertyAddress || '',
          city: estimate.propertyCity || '',
          state: estimate.propertyState || '',
          zip: estimate.propertyZip || '',
        },
        customer: {
          firstName: (estimate.customerName || '').split(' ')[0] || '',
          lastName: (estimate.customerName || '').split(' ').slice(1).join(' ') || '',
          email: estimate.customerEmail || '',
          phone: estimate.customerPhone || '',
        },
        estimatedValue: estimate.grandTotal || 0,
      } as any);
      if (jobId) {
        router.push(`/dashboard/jobs/${jobId}`);
      }
    } catch {
      // Error handled by hook
    } finally {
      setConvertingToJob(false);
    }
  }, [createJob, estimate, router, convertingToJob]);

  // ── Loading ──
  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-6 h-6 text-muted animate-spin" />
      </div>
    );
  }

  if (!estimate) {
    return (
      <div className="text-center py-16 text-muted">
        <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
        <p className="text-lg font-medium">{t('estimates.estimateNotFound')}</p>
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
        currentTier={selectedTier}
        gbbComparison={gbbComparison}
        laborRates={laborRates}
        catalogMaterials={catalogMaterials}
        changeOrderTotal={changeOrders.reduce((s, co) => s + (co.status === 'approved' ? co.totalChange : 0), 0)}
      />
    );
  }

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      <CommandPalette />
      {/* ── Main Content ── */}
      <div className={cn('flex-1 overflow-y-auto', sidebarOpen && 'mr-[380px]')}>
        {/* Header */}
        <div className="sticky top-0 z-10 bg-surface/95 backdrop-blur border-b border-main px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button onClick={() => router.push('/dashboard/estimates')} className="p-1.5 rounded-lg hover:bg-surface-hover text-muted">
                <ArrowLeft className="w-4 h-4" />
              </button>
              <div>
                <div className="flex items-center gap-2">
                  <h1 className="text-lg font-semibold text-main">{estimate.estimateNumber}</h1>
                  <span className={cn(
                    'text-[10px] px-1.5 py-0.5 rounded-full capitalize',
                    estimate.status === 'draft' ? 'bg-slate-700/50 text-muted' :
                    estimate.status === 'approved' ? 'bg-green-500/10 text-green-400' :
                    estimate.status === 'sent' ? 'bg-blue-500/10 text-blue-400' :
                    'bg-slate-700/50 text-muted'
                  )}>
                    {estimate.status}
                  </span>
                  {estimate.estimateType === 'insurance' && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-purple-500/10 text-purple-400">{t('common.insurance')}</span>
                  )}
                  {estimate.validUntil && (() => {
                    const dLeft = Math.ceil((new Date(estimate.validUntil).getTime() - Date.now()) / 86400000);
                    if (dLeft <= 0) return <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-red-500/10 text-red-400">Expired</span>;
                    if (dLeft <= 7) return <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-amber-500/10 text-amber-400">Expires in {dLeft}d</span>;
                    if (dLeft <= 30) return <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-yellow-500/10 text-yellow-400">Expires in {dLeft}d</span>;
                    return null;
                  })()}
                </div>
                <p className="text-xs text-muted">
                  {estimate.title} &middot; {estimate.customerName || 'No customer'}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button onClick={() => setShowPreview(true)} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-main bg-secondary/50 border border-main rounded-lg hover:bg-surface-hover">
                <Eye className="w-3.5 h-3.5" />
                Preview
              </button>
              <button onClick={() => handleDownloadPdf('standard')} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-main bg-secondary/50 border border-main rounded-lg hover:bg-surface-hover">
                <Download className="w-3.5 h-3.5" />
                PDF
              </button>
              {estimate.status === 'draft' && (
                <button onClick={handleSend} className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-white bg-blue-600 rounded-lg hover:bg-blue-500">
                  <Send className="w-3.5 h-3.5" />
                  Send
                </button>
              )}
              <button
                onClick={handleConvertToBid}
                disabled={convertingToBid}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-amber-300 bg-amber-500/10 border border-amber-500/20 rounded-lg hover:bg-amber-500/20 disabled:opacity-50"
              >
                {convertingToBid ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <FileText className="w-3.5 h-3.5" />}
                {convertingToBid ? 'Converting...' : 'Convert to Bid'}
              </button>
              <button
                onClick={handleConvertToInvoice}
                disabled={convertingToInvoice}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-blue-300 bg-blue-500/10 border border-blue-500/20 rounded-lg hover:bg-blue-500/20 disabled:opacity-50"
              >
                {convertingToInvoice ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Receipt className="w-3.5 h-3.5" />}
                {convertingToInvoice ? 'Creating...' : 'Convert to Invoice'}
              </button>
              <button
                onClick={handleConvertToJob}
                disabled={convertingToJob}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-emerald-300 bg-emerald-500/10 border border-emerald-500/20 rounded-lg hover:bg-emerald-500/20 disabled:opacity-50"
              >
                {convertingToJob ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Briefcase className="w-3.5 h-3.5" />}
                {convertingToJob ? 'Creating...' : 'Create Job'}
              </button>
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
                onClick={() => setShowTemplates(!showTemplates)}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-main bg-secondary/50 border border-main rounded-lg hover:bg-surface-hover"
              >
                <Copy className="w-3.5 h-3.5" />
                Templates
              </button>
              {versions.length > 0 && (
                <button
                  onClick={() => setShowVersionComparison(true)}
                  className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-main bg-secondary/50 border border-main rounded-lg hover:bg-surface-hover"
                >
                  <BarChart3 className="w-3.5 h-3.5" />
                  Compare ({versions.length})
                </button>
              )}
              <button
                onClick={() => setSidebarOpen(!sidebarOpen)}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border transition-colors',
                  sidebarOpen
                    ? 'text-blue-400 bg-blue-500/10 border-blue-500/20'
                    : 'text-main bg-secondary/50 border-main hover:bg-surface-hover'
                )}
              >
                <Search className="w-3.5 h-3.5" />
                Item Browser
              </button>
            </div>
          </div>

          {/* ── Tier Selector Bar ── */}
          <div className="flex items-center gap-3 px-6 py-2 border-t border-main/50">
            <span className="text-[10px] uppercase tracking-wider text-muted">{t('estimates.materialTier')}</span>
            <div className="flex items-center gap-1">
              {TIER_CONFIG.map((t) => (
                <button
                  key={t.value}
                  onClick={() => handleTierSwitch(t.value)}
                  disabled={tierSwitching}
                  className={cn(
                    'px-2.5 py-1 text-[11px] rounded-md border transition-colors',
                    selectedTier === t.value
                      ? `${t.color} ${t.bgColor} ${t.borderColor} font-medium`
                      : 'text-muted border-transparent hover:text-main hover:bg-surface-hover'
                  )}
                >
                  {t.label}
                </button>
              ))}
            </div>
            {tierSwitching && <Loader2 className="w-3.5 h-3.5 animate-spin text-muted" />}
            <div className="ml-auto flex items-center gap-2">
              <button
                onClick={() => setShowTierComparison(!showTierComparison)}
                className={cn(
                  'flex items-center gap-1.5 px-2.5 py-1 text-[11px] rounded-md border transition-colors',
                  showTierComparison
                    ? 'text-amber-400 bg-amber-500/10 border-amber-500/20'
                    : 'text-muted border-main hover:text-main hover:bg-surface-hover'
                )}
              >
                <BarChart3 className="w-3.5 h-3.5" />
                Good / Better / Best
              </button>
            </div>
          </div>
        </div>

        <div className="p-6 space-y-6">
          {/* ── G/B/B Comparison Panel ── */}
          {showTierComparison && gbbComparison && (
            <TierComparisonPanel
              comparison={gbbComparison}
              onSelectTier={(tier) => { handleTierSwitch(tier); setShowTierComparison(false); }}
              onClose={() => setShowTierComparison(false)}
            />
          )}

          {/* ── Template Panel ── */}
          {showTemplates && (
            <TemplatePanel
              estimateId={estimateId}
              currentAreas={areas}
              currentLineItems={lineItems}
              currentTier={selectedTier}
              onClose={() => setShowTemplates(false)}
              onApplyTemplate={async () => {
                await recalculateTotals();
                setShowTemplates(false);
              }}
            />
          )}

          {/* ── Estimate Header Card ── */}
          <div className="bg-secondary/30 border border-main rounded-xl p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-sm font-medium text-main flex items-center gap-2">
                <FileText className="w-4 h-4 text-muted" />
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
                <div><span className="text-muted">{t('estimates.title')}</span> <span className="text-main ml-2">{estimate.title || '—'}</span></div>
                <div><span className="text-muted">{t('estimates.customer')}</span> <span className="text-main ml-2">{estimate.customerName || '—'}</span></div>
                <div><span className="text-muted">{t('estimates.address')}</span> <span className="text-main ml-2">{estimate.propertyAddress || '—'}</span></div>
                <div><span className="text-muted">{t('estimates.cityStateZip')}</span> <span className="text-main ml-2">{[estimate.propertyCity, estimate.propertyState, estimate.propertyZip].filter(Boolean).join(', ') || '—'}</span></div>
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
                  <div><span className="text-muted">{t('estimates.claimNumber')}</span> <span className="text-main ml-2">{estimate.claimNumber || '—'}</span></div>
                  <div><span className="text-muted">{t('estimates.policyNumber')}</span> <span className="text-main ml-2">{estimate.policyNumber || '—'}</span></div>
                  <div><span className="text-muted">{t('estimates.carrierLabel')}</span> <span className="text-main ml-2">{estimate.carrierName || '—'}</span></div>
                  <div><span className="text-muted">{t('estimates.adjusterLabel')}</span> <span className="text-main ml-2">{estimate.adjusterName || '—'}</span></div>
                  <div><span className="text-muted">{t('estimates.deductibleLabel')}</span> <span className="text-main ml-2">${fmtCurrency(estimate.deductible)}</span></div>
                  <div><span className="text-muted">Date of Loss:</span> <span className="text-main ml-2">{estimate.dateOfLoss ? formatDate(estimate.dateOfLoss) : '—'}</span></div>
                </div>
              )}
            </div>
          )}

          {/* ── Add Room ── */}
          <div className="flex items-center gap-2">
            {addingRoom ? (
              <div className="flex items-center gap-2 flex-wrap">
                <Home className="w-4 h-4 text-muted" />
                <input
                  type="text"
                  value={newRoomName}
                  onChange={(e) => setNewRoomName(e.target.value)}
                  placeholder="Room name..."
                  className="px-3 py-1.5 bg-secondary border border-main rounded-lg text-sm text-main placeholder:text-muted w-48"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && newRoomName.trim()) handleAddRoom(newRoomName.trim());
                    if (e.key === 'Escape') { setAddingRoom(false); setNewRoomName(''); }
                  }}
                />
                <button onClick={() => { setAddingRoom(false); setNewRoomName(''); }} className="p-1 text-muted hover:text-main">
                  <X className="w-4 h-4" />
                </button>
                <div className="w-full flex flex-wrap gap-1 mt-1">
                  {ROOM_PRESETS.filter(r => !areas.some(a => a.name === r)).slice(0, 12).map((preset) => (
                    <button
                      key={preset}
                      onClick={() => handleAddRoom(preset)}
                      className="px-2 py-1 text-[10px] text-muted bg-secondary/50 border border-main rounded hover:text-main hover:border-accent/30"
                    >
                      {preset}
                    </button>
                  ))}
                </div>
              </div>
            ) : (
              <button onClick={() => setAddingRoom(true)} className="flex items-center gap-1.5 text-xs text-muted hover:text-main">
                <Plus className="w-3.5 h-3.5" />
                Add Room / Area
              </button>
            )}
          </div>

          {/* ── Area Sections ── */}
          {areas.length === 0 && lineItems.length === 0 ? (
            <div className="text-center py-16 text-muted">
              <Calculator className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p className="text-lg font-medium">{t('estimates.noRoomsOrLineItems')}</p>
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
                  currentTier={getAreaTier(area.id)}
                  onTierOverride={(tier) => handleAreaTierOverride(area.id, tier)}
                  catalogMaterials={catalogMaterials}
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
                  currentTier={getAreaTier(null)}
                  catalogMaterials={catalogMaterials}
                />
              )}

              {/* ── Geographic Labor Rates ── */}
              {laborRates.length > 0 && (
                <LaborRatesPanel rates={laborRates} loading={laborRatesLoading} />
              )}

              {/* ── Totals Panel ── */}
              <TotalsPanel
                estimate={estimate}
                totals={totals}
                lineCount={lineItems.length}
                onRateChange={handleRateChange}
                currentTier={selectedTier}
                catalogMaterials={catalogMaterials}
                lineItems={lineItems}
                changeOrderTotal={totalChangeOrderAmount}
              />
            </>
          )}
        </div>
      </div>

      {/* ── Sidebar: Item Browser ── */}
      {sidebarOpen && (
        <div className="fixed right-0 top-16 bottom-0 w-[380px] bg-surface border-l border-main flex flex-col z-20">
          <div className="flex items-center justify-between px-4 py-3 border-b border-main">
            <span className="text-sm font-medium text-main">{t('estimates.zaftoCodeDatabase')}</span>
            <button onClick={() => setSidebarOpen(false)} className="p-1 text-muted hover:text-main">
              <X className="w-4 h-4" />
            </button>
          </div>

          {/* Search + Filters */}
          <div className="p-3 space-y-2 border-b border-main">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted" />
              <input
                type="text"
                value={itemSearch}
                onChange={(e) => handleItemSearch(e.target.value)}
                placeholder="Search codes or descriptions..."
                className="w-full pl-8 pr-3 py-1.5 bg-secondary/50 border border-main rounded-lg text-xs text-main placeholder:text-muted"
              />
            </div>
            {/* Trade chips */}
            <div className="flex flex-wrap gap-1">
              <button
                onClick={() => setTradeFilter('')}
                className={cn(
                  'px-2 py-1 text-[10px] rounded transition-colors',
                  !tradeFilter ? 'bg-blue-500/10 text-blue-400' : 'text-muted hover:text-main'
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
                    tradeFilter === t ? 'bg-blue-500/10 text-blue-400' : 'text-muted hover:text-main'
                  )}
                >
                  {t}
                </button>
              ))}
            </div>
            <label className="flex items-center gap-2 text-xs text-muted">
              <input
                type="checkbox"
                checked={commonOnly}
                onChange={(e) => setCommonOnly(e.target.checked)}
                className="rounded border-main"
              />
              Common items only
            </label>
          </div>

          {/* Item list */}
          <div className="flex-1 overflow-y-auto">
            {itemsLoading ? (
              <div className="p-4 space-y-2">
                {[1, 2, 3, 4, 5].map(i => (
                  <div key={i} className="h-12 bg-secondary/50 rounded animate-pulse" />
                ))}
              </div>
            ) : codeItems.length === 0 ? (
              <div className="p-6 text-center text-muted text-xs">
                {itemSearch ? 'No items found' : 'Search or filter by trade to browse items'}
              </div>
            ) : (
              <div className="divide-y divide-main/50">
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

      {/* ── Version Comparison Panel ── */}
      {showVersionComparison && (
        <VersionComparisonPanel
          versions={versions}
          changeOrders={changeOrders}
          onClose={() => setShowVersionComparison(false)}
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
  const { t: tr } = useTranslation();
  const [scans, setScans] = useState<Array<{ id: string; address: string; status: string; confidence_score: number }>>([]);
  const [trades, setTrades] = useState<Array<{ trade: string; material_count: number }>>([]);
  const [selectedScan, setSelectedScan] = useState<string | null>(null);
  const [loadingScans, setLoadingScans] = useState(true);
  const [propertyData, setPropertyData] = useState<Record<string, unknown> | null>(null);
  const [hazardFlags, setHazardFlags] = useState<string[]>([]);

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

  // Load trades + property intel when scan is selected
  useEffect(() => {
    if (!selectedScan) return;
    const load = async () => {
      const supabase = getSupabase();

      // Load trade bid data
      const { data } = await supabase
        .from('trade_bid_data')
        .select('trade, material_list')
        .eq('scan_id', selectedScan);

      setTrades((data || []).map((d: Record<string, unknown>) => ({
        trade: d.trade as string,
        material_count: ((d.material_list as unknown[]) || []).length,
      })));

      // Load property scan details for pre-fill data + hazard flags
      const { data: scanDetail } = await supabase
        .from('property_scans')
        .select('scan_results, hazard_flags, property_type, year_built, total_sqft, stories, roof_area_sqft, lot_sqft')
        .eq('id', selectedScan)
        .maybeSingle();

      if (scanDetail) {
        setPropertyData(scanDetail as Record<string, unknown>);
        // Extract hazard flags
        const flags: string[] = [];
        const hf = scanDetail.hazard_flags as Record<string, boolean> | null;
        if (hf) {
          if (hf.lead_paint) flags.push('Lead paint detected — add lead abatement line item');
          if (hf.asbestos) flags.push('Asbestos risk — add asbestos testing/abatement');
          if (hf.old_electrical_panel) flags.push('Old electrical panel — add panel upgrade line item');
          if (hf.galvanized_plumbing) flags.push('Galvanized plumbing — add re-pipe line item');
          if (hf.mold) flags.push('Mold detected — add mold remediation line item');
          if (hf.radon) flags.push('Radon risk — add radon mitigation');
          if (hf.structural_damage) flags.push('Structural damage — add structural repair line item');
          if (hf.water_damage) flags.push('Water damage — add water mitigation line item');
          if (hf.pest_damage) flags.push('Pest damage — add pest treatment line item');
          if (hf.roof_damage) flags.push('Roof damage detected — prioritize roofing scope');
        }
        // Year-based hazard inference
        const yearBuilt = scanDetail.year_built as number | null;
        if (yearBuilt && yearBuilt < 1978 && !hf?.lead_paint) {
          flags.push('Pre-1978 construction — lead paint testing recommended');
        }
        if (yearBuilt && yearBuilt < 1985 && !hf?.asbestos) {
          flags.push('Pre-1985 construction — asbestos testing recommended');
        }
        setHazardFlags(flags);
      } else {
        setPropertyData(null);
        setHazardFlags([]);
      }
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
      <div className="bg-surface border border-main rounded-xl w-[480px] max-h-[80vh] overflow-y-auto">
        <div className="flex items-center justify-between px-5 py-4 border-b border-main">
          <div className="flex items-center gap-2">
            <Satellite className="w-4 h-4 text-emerald-400" />
            <span className="text-sm font-semibold text-main">{tr('estimates.importFromRecon')}</span>
          </div>
          <button onClick={onClose} className="p-1 text-muted hover:text-main">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {loadingScans ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="w-5 h-5 animate-spin text-muted" />
            </div>
          ) : scans.length === 0 ? (
            <p className="text-sm text-muted text-center py-8">
              No property scans available. Create a job and run a scan first.
            </p>
          ) : (
            <>
              {/* Scan selector */}
              <div>
                <label className="text-xs text-muted mb-1.5 block">{tr('estimates.propertyScan')}</label>
                <select
                  value={selectedScan || ''}
                  onChange={e => setSelectedScan(e.target.value)}
                  className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-sm text-main"
                >
                  {scans.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.address} ({s.confidence_score}% confidence)
                    </option>
                  ))}
                </select>
              </div>

              {/* Property Data Pre-fill */}
              {propertyData && (
                <div className="bg-secondary/50 border border-main rounded-lg p-3 space-y-2">
                  <p className="text-[10px] text-muted uppercase font-semibold tracking-wider">Property Intelligence</p>
                  <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
                    {propertyData.total_sqft != null && <div className="flex justify-between"><span className="text-muted">Total SqFt</span><span className="text-main">{formatNumber(Number(propertyData.total_sqft))}</span></div>}
                    {propertyData.stories != null && <div className="flex justify-between"><span className="text-muted">Stories</span><span className="text-main">{String(propertyData.stories)}</span></div>}
                    {propertyData.roof_area_sqft != null && <div className="flex justify-between"><span className="text-muted">Roof Area</span><span className="text-main">{formatNumber(Number(propertyData.roof_area_sqft))} sqft</span></div>}
                    {propertyData.lot_sqft != null && <div className="flex justify-between"><span className="text-muted">Lot Size</span><span className="text-main">{formatNumber(Number(propertyData.lot_sqft))} sqft</span></div>}
                    {propertyData.year_built != null && <div className="flex justify-between"><span className="text-muted">Year Built</span><span className="text-main">{String(propertyData.year_built)}</span></div>}
                    {propertyData.property_type != null && <div className="flex justify-between"><span className="text-muted">Type</span><span className="text-main capitalize">{String(propertyData.property_type).replace(/_/g, ' ')}</span></div>}
                  </div>
                </div>
              )}

              {/* Hazard Flag Suggestions */}
              {hazardFlags.length > 0 && (
                <div className="bg-amber-500/5 border border-amber-500/20 rounded-lg p-3 space-y-1.5">
                  <p className="text-[10px] text-amber-400 uppercase font-semibold tracking-wider flex items-center gap-1">
                    <AlertCircle className="w-3 h-3" /> Hazard Alerts — Suggested Line Items
                  </p>
                  {hazardFlags.map((flag, i) => (
                    <p key={i} className="text-xs text-amber-300/80 pl-4">
                      &bull; {flag}
                    </p>
                  ))}
                </div>
              )}

              {/* Trade buttons */}
              {trades.length > 0 ? (
                <div>
                  <label className="text-xs text-muted mb-1.5 block">{tr('estimates.selectTradeToImport')}</label>
                  <div className="grid grid-cols-2 gap-2">
                    {trades.map(t => (
                      <button
                        key={t.trade}
                        onClick={() => selectedScan && onImport(selectedScan, t.trade)}
                        disabled={importing}
                        className="flex items-center justify-between px-3 py-2.5 bg-secondary border border-main rounded-lg hover:border-emerald-500/50 hover:bg-emerald-500/5 transition-colors text-left"
                      >
                        <span className="text-sm text-main">{TRADE_NAMES[t.trade] || t.trade}</span>
                        <span className="text-[10px] text-muted">{t.material_count} items</span>
                      </button>
                    ))}
                  </div>
                </div>
              ) : selectedScan ? (
                <p className="text-sm text-muted text-center py-4">
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
  estimate: { title: string; customerName: string; customerEmail: string; customerPhone: string; propertyAddress: string; propertyCity: string; propertyState: string; propertyZip: string; notes: string; validUntil: string | null };
  onUpdate: (u: Record<string, unknown>) => Promise<void>;
}) {
  const daysUntilExpiry = estimate.validUntil
    ? Math.ceil((new Date(estimate.validUntil).getTime() - Date.now()) / 86400000)
    : null;

  return (
    <div className="grid grid-cols-2 gap-3">
      <input type="text" defaultValue={estimate.title} onBlur={(e) => onUpdate({ title: e.target.value })}
        placeholder="Title" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.customerName} onBlur={(e) => onUpdate({ customer_name: e.target.value })}
        placeholder="Customer name" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="email" defaultValue={estimate.customerEmail} onBlur={(e) => onUpdate({ customer_email: e.target.value })}
        placeholder="Customer email" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="tel" defaultValue={estimate.customerPhone} onBlur={(e) => onUpdate({ customer_phone: e.target.value })}
        placeholder="Customer phone" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.propertyAddress} onBlur={(e) => onUpdate({ property_address: e.target.value })}
        placeholder="Address" className="col-span-2 px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.propertyCity} onBlur={(e) => onUpdate({ property_city: e.target.value })}
        placeholder="City" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <div className="flex gap-2">
        <input type="text" defaultValue={estimate.propertyState} onBlur={(e) => onUpdate({ property_state: e.target.value })}
          placeholder="State" className="w-20 px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
        <input type="text" defaultValue={estimate.propertyZip} onBlur={(e) => onUpdate({ property_zip: e.target.value })}
          placeholder="ZIP" className="flex-1 px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      </div>
      {/* Estimate Expiration */}
      <div className="col-span-2">
        <label className="text-[10px] text-muted mb-1 block">Valid Until (Expiration Date)</label>
        <div className="flex items-center gap-2">
          <input
            type="date"
            defaultValue={estimate.validUntil ? estimate.validUntil.split('T')[0] : ''}
            onBlur={(e) => onUpdate({ valid_until: e.target.value ? new Date(e.target.value + 'T23:59:59').toISOString() : null })}
            className="flex-1 px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted"
          />
          {/* Quick-set buttons */}
          <button
            type="button"
            onClick={() => {
              const d = new Date(); d.setDate(d.getDate() + 30);
              onUpdate({ valid_until: d.toISOString() });
            }}
            className="px-2 py-1.5 text-[10px] bg-secondary border border-main rounded text-muted hover:text-main hover:border-accent/30"
          >30d</button>
          <button
            type="button"
            onClick={() => {
              const d = new Date(); d.setDate(d.getDate() + 60);
              onUpdate({ valid_until: d.toISOString() });
            }}
            className="px-2 py-1.5 text-[10px] bg-secondary border border-main rounded text-muted hover:text-main hover:border-accent/30"
          >60d</button>
          <button
            type="button"
            onClick={() => {
              const d = new Date(); d.setDate(d.getDate() + 90);
              onUpdate({ valid_until: d.toISOString() });
            }}
            className="px-2 py-1.5 text-[10px] bg-secondary border border-main rounded text-muted hover:text-main hover:border-accent/30"
          >90d</button>
        </div>
        {daysUntilExpiry !== null && (
          <p className={cn('text-[10px] mt-1', daysUntilExpiry <= 0 ? 'text-red-400' : daysUntilExpiry <= 7 ? 'text-amber-400' : 'text-muted')}>
            {daysUntilExpiry <= 0 ? 'This estimate has expired' : `Expires in ${daysUntilExpiry} day${daysUntilExpiry !== 1 ? 's' : ''}`}
          </p>
        )}
      </div>
      <textarea defaultValue={estimate.notes} onBlur={(e) => onUpdate({ notes: e.target.value })}
        placeholder="Notes..." rows={2} className="col-span-2 px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted resize-none" />
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
        placeholder="Claim #" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.policyNumber} onBlur={(e) => onUpdate({ policy_number: e.target.value })}
        placeholder="Policy #" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.carrierName} onBlur={(e) => onUpdate({ carrier_name: e.target.value })}
        placeholder="Carrier name" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="text" defaultValue={estimate.adjusterName} onBlur={(e) => onUpdate({ adjuster_name: e.target.value })}
        placeholder="Adjuster name" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="email" defaultValue={estimate.adjusterEmail} onBlur={(e) => onUpdate({ adjuster_email: e.target.value })}
        placeholder="Adjuster email" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="tel" defaultValue={estimate.adjusterPhone} onBlur={(e) => onUpdate({ adjuster_phone: e.target.value })}
        placeholder="Adjuster phone" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="number" step="0.01" defaultValue={estimate.deductible} onBlur={(e) => onUpdate({ deductible: Number(e.target.value) || 0 })}
        placeholder="Deductible" className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main placeholder:text-muted" />
      <input type="date" defaultValue={estimate.dateOfLoss || ''} onBlur={(e) => onUpdate({ date_of_loss: e.target.value || null })}
        className="px-2 py-1.5 bg-secondary border border-main rounded text-xs text-main" />
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
  currentTier,
  onTierOverride,
  catalogMaterials,
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
  currentTier?: MaterialTier;
  onTierOverride?: (tier: MaterialTier) => void;
  catalogMaterials?: MaterialCatalogItem[];
}) {
  const { t: tr } = useTranslation();
  const [collapsed, setCollapsed] = useState(false);
  const [showDimensions, setShowDimensions] = useState(false);
  const [showTierPicker, setShowTierPicker] = useState(false);
  const areaTotal = lines.reduce((sum, l) => sum + l.lineTotal, 0);

  const tierConfig = currentTier ? TIER_CONFIG.find(t => t.value === currentTier) : null;

  return (
    <div className="bg-secondary/30 border border-main rounded-xl overflow-hidden">
      {/* Area Header */}
      <div className="flex items-center justify-between px-4 py-3 hover:bg-surface-hover transition-colors">
        <button onClick={() => setCollapsed(!collapsed)} className="flex items-center gap-2 flex-1">
          {collapsed ? <ChevronRight className="w-4 h-4 text-muted" /> : <ChevronDown className="w-4 h-4 text-muted" />}
          <Home className="w-4 h-4 text-muted" />
          <span className="text-sm font-medium text-main">{area?.name || 'Unassigned'}</span>
          <span className="text-xs text-muted">{lines.length} items</span>
          {tierConfig && (
            <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', tierConfig.bgColor, tierConfig.color)}>
              {tierConfig.label}
            </span>
          )}
        </button>
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-main">${fmtCurrency(areaTotal)}</span>
          {area && onTierOverride && (
            <div className="relative">
              <button
                onClick={() => setShowTierPicker(!showTierPicker)}
                className="p-1 text-muted hover:text-main"
                title="Override tier for this section"
              >
                <Star className="w-3.5 h-3.5" />
              </button>
              {showTierPicker && (
                <div className="absolute right-0 top-7 bg-secondary border border-main rounded-lg shadow-xl p-1 z-20 min-w-[120px]">
                  {TIER_CONFIG.map((t) => (
                    <button
                      key={t.value}
                      onClick={() => { onTierOverride(t.value); setShowTierPicker(false); }}
                      className={cn(
                        'w-full text-left px-2.5 py-1.5 text-xs rounded hover:bg-surface-hover flex items-center gap-2',
                        currentTier === t.value ? t.color : 'text-main'
                      )}
                    >
                      {currentTier === t.value && <Check className="w-3 h-3" />}
                      {t.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
          {area && (
            <>
              <button onClick={() => setShowDimensions(!showDimensions)} className="p-1 text-muted hover:text-main" title={tr('common.dimensions')}>
                <Ruler className="w-3.5 h-3.5" />
              </button>
              <button onClick={() => onDeleteArea(area.id)} className="p-1 text-muted hover:text-red-400">
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </>
          )}
        </div>
      </div>

      {/* Dimensions */}
      {showDimensions && area && (
        <div className="px-4 py-3 bg-secondary/20 border-t border-main/50">
          <div className="grid grid-cols-4 gap-2">
            {[
              { label: 'Length (ft)', field: 'length_ft', value: area.lengthFt },
              { label: 'Width (ft)', field: 'width_ft', value: area.widthFt },
              { label: 'Height (ft)', field: 'height_ft', value: area.heightFt },
              { label: 'Windows', field: 'window_count', value: area.windowCount },
            ].map((dim) => (
              <div key={dim.field}>
                <label className="text-[10px] text-muted block mb-1">{dim.label}</label>
                <input
                  type="number"
                  step="0.1"
                  defaultValue={dim.value}
                  onBlur={(e) => {
                    const val = Number(e.target.value) || 0;
                    onUpdateArea(area.id, { [dim.field]: val });
                  }}
                  className="w-full px-2 py-1 text-xs bg-secondary border border-main rounded text-main"
                />
              </div>
            ))}
          </div>
          {area.lengthFt > 0 && area.widthFt > 0 && (
            <div className="flex items-center gap-4 mt-2 text-[10px] text-muted">
              <span>Floor: {(area.lengthFt * area.widthFt).toFixed(1)} SF</span>
              <span>Perimeter: {((area.lengthFt + area.widthFt) * 2).toFixed(1)} LF</span>
              <span>Wall: {(((area.lengthFt + area.widthFt) * 2) * area.heightFt).toFixed(1)} SF</span>
            </div>
          )}
        </div>
      )}

      {!collapsed && (
        <div className="border-t border-main">
          {/* Column headers */}
          <div className="grid grid-cols-[1fr_70px_70px_80px_90px_36px] gap-2 px-4 py-2 text-[10px] uppercase tracking-wider text-muted border-b border-main/50">
            <span>{tr('common.item')}</span>
            <span className="text-right">{tr('common.qty')}</span>
            <span className="text-right">{tr('estimates.unit')}</span>
            <span className="text-right">{tr('common.total')}</span>
            <span className="text-center">{tr('common.action')}</span>
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
              catalogMaterials={catalogMaterials}
            />
          ))}

          {/* Add line button */}
          <div className="px-4 py-2 border-t border-main/50">
            <button onClick={onOpenBrowser} className="flex items-center gap-1.5 text-xs text-muted hover:text-main">
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
  line, isEditing, onEdit, onUpdate, onDelete, catalogMaterials,
}: {
  line: EstimateLineItem;
  isEditing: boolean;
  onEdit: () => void;
  onUpdate: (id: string, field: string, value: string | number) => void;
  onDelete: () => void;
  catalogMaterials?: MaterialCatalogItem[];
}) {
  // Find matching material for photo and warranty info
  const matchedMaterial = useMemo(() => {
    if (!catalogMaterials) return null;
    return catalogMaterials.find(
      m => m.name.toLowerCase() === line.description.toLowerCase() || m.id === line.itemId
    ) || null;
  }, [catalogMaterials, line.description, line.itemId]);

  return (
    <div className="group">
      <div
        className={cn(
          'grid grid-cols-[1fr_70px_70px_80px_90px_36px] gap-2 px-4 py-2.5 items-center transition-colors cursor-pointer',
          isEditing ? 'bg-secondary/60' : 'hover:bg-surface-hover'
        )}
        onClick={onEdit}
      >
        <div className="min-w-0 flex items-center gap-2">
          {/* Material photo thumbnail */}
          {matchedMaterial?.photoUrl && (
            <div className="w-8 h-8 rounded border border-main overflow-hidden flex-shrink-0 bg-secondary">
              <img src={matchedMaterial.photoUrl} alt="" className="w-full h-full object-cover" />
            </div>
          )}
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              {line.zaftoCode && <span className="text-[10px] font-mono text-blue-400">{line.zaftoCode}</span>}
              {matchedMaterial?.warrantyYears && (
                <span className="text-[10px] px-1 py-0.5 rounded bg-green-500/10 text-green-400 flex items-center gap-0.5">
                  <ShieldCheck className="w-2.5 h-2.5" />
                  {matchedMaterial.warrantyYears}yr
                </span>
              )}
            </div>
            <p className="text-xs text-main truncate">{line.description}</p>
            {line.notes && <p className="text-[10px] text-muted truncate mt-0.5">{line.notes}</p>}
          </div>
        </div>

        <div className="text-right">
          {isEditing ? (
            <input type="number" value={line.quantity}
              onChange={(e) => onUpdate(line.id, 'quantity', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-secondary border border-main rounded text-main"
              onClick={(e) => e.stopPropagation()} />
          ) : (
            <span className="text-xs text-main">{line.quantity} {line.unitCode}</span>
          )}
        </div>

        <div className="text-right">
          {isEditing ? (
            <input type="number" step="0.01" value={line.unitPrice}
              onChange={(e) => onUpdate(line.id, 'unit_price', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-secondary border border-main rounded text-main"
              onClick={(e) => e.stopPropagation()} />
          ) : (
            <span className="text-xs text-main">${fmtCurrency(line.unitPrice)}</span>
          )}
        </div>

        <span className="text-xs text-right font-medium text-main">${fmtCurrency(line.lineTotal)}</span>

        <div className="flex justify-center">
          {isEditing ? (
            <select value={line.actionType}
              onChange={(e) => { onUpdate(line.id, 'action_type', e.target.value); e.stopPropagation(); }}
              className="text-[10px] px-1 py-0.5 bg-secondary border border-main rounded text-main"
              onClick={(e) => e.stopPropagation()}>
              {ACTION_TYPES.map(a => <option key={a.value} value={a.value}>{a.label}</option>)}
            </select>
          ) : (
            <span className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700/50 text-muted capitalize">{line.actionType}</span>
          )}
        </div>

        <div className="flex justify-center">
          <button onClick={(e) => { e.stopPropagation(); onDelete(); }}
            className="p-1 text-muted hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity">
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Expanded edit row */}
      {isEditing && (
        <div className="px-4 py-2 bg-secondary/40 border-t border-main/50">
          <div className="flex gap-3">
            {/* Material photo (larger) */}
            {matchedMaterial?.photoUrl && (
              <div className="w-16 h-16 rounded-lg border border-main overflow-hidden flex-shrink-0 bg-secondary">
                <img src={matchedMaterial.photoUrl} alt={matchedMaterial.name} className="w-full h-full object-cover" />
              </div>
            )}
            <div className="flex-1 space-y-2">
              {/* Cost breakdown */}
              <div className="grid grid-cols-3 gap-3">
                <div className="flex items-center gap-2">
                  <Package className="w-3 h-3 text-muted" />
                  <span className="text-[10px] text-muted">MAT:</span>
                  <span className="text-xs text-main">${fmtCurrency(line.materialCost)}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Wrench className="w-3 h-3 text-muted" />
                  <span className="text-[10px] text-muted">LAB:</span>
                  <span className="text-xs text-main">${fmtCurrency(line.laborCost)}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Zap className="w-3 h-3 text-muted" />
                  <span className="text-[10px] text-muted">EQU:</span>
                  <span className="text-xs text-main">${fmtCurrency(line.equipmentCost)}</span>
                </div>
              </div>
              {/* Material details row */}
              {matchedMaterial && (
                <div className="flex items-center gap-3 text-[10px]">
                  {matchedMaterial.brand && (
                    <span className="text-muted">Brand: <span className="text-main">{matchedMaterial.brand}</span></span>
                  )}
                  {matchedMaterial.tier && (
                    <span className={cn('px-1.5 py-0.5 rounded', TIER_CONFIG.find(t => t.value === matchedMaterial.tier)?.bgColor, TIER_CONFIG.find(t => t.value === matchedMaterial.tier)?.color)}>
                      {TIER_CONFIG.find(t => t.value === matchedMaterial.tier)?.label}
                    </span>
                  )}
                  {matchedMaterial.warrantyYears != null && (
                    <span className="text-green-400 flex items-center gap-0.5">
                      <ShieldCheck className="w-2.5 h-2.5" />
                      {matchedMaterial.warrantyYears} yr warranty
                    </span>
                  )}
                  {matchedMaterial.supplierUrls?.length > 0 && (
                    <div className="flex items-center gap-1 ml-auto">
                      {matchedMaterial.supplierUrls.slice(0, 3).map((s, i) => (
                        <a key={i} href={s.url} target="_blank" rel="noopener noreferrer"
                          className="text-blue-400 hover:text-blue-300 underline"
                          onClick={(e) => e.stopPropagation()}>
                          {s.supplier}
                        </a>
                      ))}
                    </div>
                  )}
                </div>
              )}
              {/* Notes */}
              <input type="text" value={line.notes}
                onChange={(e) => onUpdate(line.id, 'notes', e.target.value)}
                placeholder="Notes..."
                className="w-full px-2 py-1 text-xs bg-secondary border border-main rounded text-main placeholder:text-muted"
                onClick={(e) => e.stopPropagation()} />
            </div>
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
    <div className="px-3 py-2.5 hover:bg-surface-hover transition-colors">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] font-mono font-medium text-blue-400">{item.zaftoCode}</span>
            <span className="text-[10px] px-1 py-0.5 rounded bg-slate-700/50 text-muted">{item.trade}</span>
          </div>
          <p className="text-xs text-main mt-0.5 line-clamp-2">{item.name}</p>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-[10px] text-muted">{item.defaultUnit}</span>
            <span className="text-[10px] text-muted">${fmtCurrency(item.basePrice)}</span>
            <div className="flex items-center gap-1">
              {item.materialCost > 0 && <Package className="w-2.5 h-2.5 text-muted" />}
              {item.laborCost > 0 && <Wrench className="w-2.5 h-2.5 text-muted" />}
              {item.equipmentCost > 0 && <Zap className="w-2.5 h-2.5 text-muted" />}
            </div>
          </div>
        </div>
        <div className="relative flex-shrink-0">
          {showPicker && areas.length > 0 ? (
            <div className="absolute right-0 top-0 bg-secondary border border-main rounded-lg shadow-xl p-1.5 min-w-[140px] z-10">
              {areas.map(area => (
                <button key={area.id}
                  onClick={() => { onAdd(item, area.id); setShowPicker(false); }}
                  className="w-full text-left px-2 py-1.5 text-xs text-main hover:bg-surface-hover rounded">
                  {area.name}
                </button>
              ))}
              <button onClick={() => { onAdd(item); setShowPicker(false); }}
                className="w-full text-left px-2 py-1.5 text-xs text-muted hover:bg-surface-hover rounded border-t border-main mt-1 pt-1.5">
                No room
              </button>
              <button onClick={() => setShowPicker(false)}
                className="w-full text-left px-2 py-1 text-[10px] text-muted hover:text-main mt-1 border-t border-main pt-1">
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
              className="p-1.5 text-muted hover:text-blue-400 hover:bg-blue-500/10 rounded-lg transition-colors"
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
  estimate, totals, lineCount, onRateChange, currentTier, catalogMaterials, lineItems: panelLineItems, changeOrderTotal,
}: {
  estimate: { overheadPercent: number; profitPercent: number; taxPercent: number; estimateType: string; deductible: number };
  totals: { subtotal: number; overhead: number; profit: number; tax: number; grand: number };
  lineCount: number;
  onRateChange: (field: string, value: number) => void;
  currentTier?: MaterialTier;
  catalogMaterials?: MaterialCatalogItem[];
  lineItems?: EstimateLineItem[];
  changeOrderTotal?: number;
}) {
  const { t: tr } = useTranslation();
  // Calculate warranty range from matched materials
  const warrantyRange = useMemo(() => {
    if (!catalogMaterials || !panelLineItems) return null;
    let min = Infinity;
    let max = 0;
    for (const li of panelLineItems) {
      const mat = catalogMaterials.find(
        m => m.name.toLowerCase() === li.description.toLowerCase() || m.id === li.itemId
      );
      if (mat?.warrantyYears != null) {
        min = Math.min(min, mat.warrantyYears);
        max = Math.max(max, mat.warrantyYears);
      }
    }
    if (min === Infinity) return null;
    return min === max ? `${min} year` : `${min}-${max} years`;
  }, [catalogMaterials, panelLineItems]);

  const tierConfig = currentTier ? TIER_CONFIG.find(t => t.value === currentTier) : null;

  return (
    <div className="bg-secondary/30 border border-main rounded-xl p-5">
      <h3 className="text-sm font-medium text-main mb-4 flex items-center gap-2">
        <Layers className="w-4 h-4 text-muted" />
        Estimate Totals
        {tierConfig && (
          <span className={cn('text-[10px] px-1.5 py-0.5 rounded-full', tierConfig.bgColor, tierConfig.color)}>
            {tierConfig.label} Tier
          </span>
        )}
        <span className="text-xs text-muted font-normal ml-auto">{lineCount} line items</span>
      </h3>

      <div className="space-y-2.5">
        <div className="flex items-center justify-between text-xs">
          <span className="text-muted">{tr('common.subtotal')}</span>
          <span className="text-main font-medium">${fmtCurrency(totals.subtotal)}</span>
        </div>

        {/* Overhead */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-muted">{tr('common.overhead')}</span>
            <input type="number" min="0" max="100" value={estimate.overheadPercent}
              onChange={(e) => onRateChange('overhead_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-secondary border border-main rounded text-main text-right" />
            <span className="text-muted">%</span>
          </div>
          <span className="text-main">${fmtCurrency(totals.overhead)}</span>
        </div>

        {/* Profit */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-muted">{tr('common.profit')}</span>
            <input type="number" min="0" max="100" value={estimate.profitPercent}
              onChange={(e) => onRateChange('profit_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-secondary border border-main rounded text-main text-right" />
            <span className="text-muted">%</span>
          </div>
          <span className="text-main">${fmtCurrency(totals.profit)}</span>
        </div>

        {/* Tax */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-muted">{tr('common.tax')}</span>
            <input type="number" min="0" max="100" step="0.01" value={estimate.taxPercent}
              onChange={(e) => onRateChange('tax_percent', Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-secondary border border-main rounded text-main text-right" />
            <span className="text-muted">%</span>
          </div>
          <span className="text-main">${fmtCurrency(totals.tax)}</span>
        </div>

        {/* Grand Total */}
        <div className="flex items-center justify-between text-sm pt-2.5 border-t border-main">
          <span className="text-main font-semibold">{tr('estimates.grandTotal')}</span>
          <span className="text-main font-semibold text-lg">${fmtCurrency(totals.grand)}</span>
        </div>

        {/* Insurance net claim */}
        {estimate.estimateType === 'insurance' && estimate.deductible > 0 && (
          <div className="flex items-center justify-between text-xs pt-2 border-t border-main">
            <span className="text-purple-400">Net Claim (after deductible)</span>
            <span className="text-purple-300 font-medium">${fmtCurrency(Math.max(0, totals.grand - estimate.deductible))}</span>
          </div>
        )}

        {/* Change order total */}
        {changeOrderTotal != null && changeOrderTotal !== 0 && (
          <div className="flex items-center justify-between text-xs pt-2 border-t border-main">
            <span className="text-amber-400">{tr('common.approvedChangeOrders')}</span>
            <span className={cn('font-medium', changeOrderTotal > 0 ? 'text-amber-300' : 'text-red-300')}>
              {changeOrderTotal > 0 ? '+' : ''}{fmtCurrency(changeOrderTotal)}
            </span>
          </div>
        )}

        {/* Warranty coverage */}
        {warrantyRange && (
          <div className="flex items-center justify-between text-xs pt-2 border-t border-main">
            <span className="text-green-400 flex items-center gap-1">
              <ShieldCheck className="w-3 h-3" />
              Material Warranty Coverage
            </span>
            <span className="text-green-300 font-medium">{warrantyRange}</span>
          </div>
        )}

        {/* Profit Margin Calculator */}
        {totals.subtotal > 0 && (() => {
          const materialTotal = panelLineItems?.reduce((sum, li) => sum + (li.materialCost * li.quantity), 0) || 0;
          const laborTotal = panelLineItems?.reduce((sum, li) => sum + (li.laborCost * li.quantity), 0) || 0;
          const markupPercent = totals.subtotal > 0 ? ((totals.grand - totals.subtotal) / totals.subtotal) * 100 : 0;
          const grossMarginPct = totals.grand > 0 ? ((totals.grand - materialTotal - laborTotal) / totals.grand) * 100 : 0;
          const netMarginPct = totals.grand > 0 ? (totals.profit / totals.grand) * 100 : 0;

          // Industry average benchmarks (from BLS/IBISWorld contractor data)
          const INDUSTRY_AVG_MARKUP = 35; // 35% average contractor markup
          const INDUSTRY_AVG_GROSS_MARGIN = 28; // 28% average gross margin
          const INDUSTRY_AVG_NET_MARGIN = 8; // 8% average net margin

          return (
            <div className="pt-3 mt-1 border-t border-main space-y-2">
              <p className="text-[10px] text-muted uppercase font-semibold tracking-wider flex items-center gap-1">
                <BarChart3 className="w-3 h-3" />
                Margin Analysis
              </p>
              <div className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-muted">Markup</span>
                  <div className="flex items-center gap-2">
                    <span className={cn('font-medium', markupPercent >= INDUSTRY_AVG_MARKUP ? 'text-emerald-400' : 'text-amber-400')}>
                      {markupPercent.toFixed(1)}%
                    </span>
                    <span className="text-muted text-[10px]">avg {INDUSTRY_AVG_MARKUP}%</span>
                  </div>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-muted">Gross Margin</span>
                  <div className="flex items-center gap-2">
                    <span className={cn('font-medium', grossMarginPct >= INDUSTRY_AVG_GROSS_MARGIN ? 'text-emerald-400' : 'text-amber-400')}>
                      {grossMarginPct.toFixed(1)}%
                    </span>
                    <span className="text-muted text-[10px]">avg {INDUSTRY_AVG_GROSS_MARGIN}%</span>
                  </div>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="text-muted">Net Margin</span>
                  <div className="flex items-center gap-2">
                    <span className={cn('font-medium', netMarginPct >= INDUSTRY_AVG_NET_MARGIN ? 'text-emerald-400' : netMarginPct > 0 ? 'text-amber-400' : 'text-red-400')}>
                      {netMarginPct.toFixed(1)}%
                    </span>
                    <span className="text-muted text-[10px]">avg {INDUSTRY_AVG_NET_MARGIN}%</span>
                  </div>
                </div>
              </div>
              {netMarginPct < INDUSTRY_AVG_NET_MARGIN && netMarginPct >= 0 && (
                <p className="text-[10px] text-amber-400/70 mt-1">Your net margin is below industry average. Consider adjusting profit percentage.</p>
              )}
              {netMarginPct < 0 && (
                <p className="text-[10px] text-red-400/70 mt-1">This estimate is unprofitable at current rates.</p>
              )}
            </div>
          );
        })()}

        {/* Crew Accuracy Insights */}
        <CrewAccuracyPanel />
      </div>
    </div>
  );
}

// ── Crew Accuracy Panel ── (Historical Job Learning)

function CrewAccuracyPanel() {
  const [data, setData] = useState<Array<{
    task_name: string; trade: string; estimated_hours: number; actual_hours: number;
  }>>([]);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    const load = async () => {
      try {
        const supabase = getSupabase();
        const { data: rows } = await supabase
          .from('crew_performance_log')
          .select('task_name, trade, estimated_hours, actual_hours')
          .order('created_at', { ascending: false })
          .limit(50);
        setData(rows || []);
      } catch { /* silent */ }
      setLoaded(true);
    };
    load();
  }, []);

  if (!loaded || data.length === 0) return null;

  // Aggregate by trade
  const byTrade: Record<string, { estimated: number; actual: number; count: number }> = {};
  for (const row of data) {
    const t = row.trade || 'General';
    if (!byTrade[t]) byTrade[t] = { estimated: 0, actual: 0, count: 0 };
    byTrade[t].estimated += row.estimated_hours;
    byTrade[t].actual += row.actual_hours;
    byTrade[t].count++;
  }

  const totalEstimated = data.reduce((s, r) => s + r.estimated_hours, 0);
  const totalActual = data.reduce((s, r) => s + r.actual_hours, 0);
  const overallVariance = totalEstimated > 0 ? ((totalActual - totalEstimated) / totalEstimated) * 100 : 0;

  return (
    <div className="pt-3 mt-1 border-t border-main space-y-2">
      <p className="text-[10px] text-muted uppercase font-semibold tracking-wider flex items-center gap-1">
        <Activity className="w-3 h-3" />
        Crew Accuracy
      </p>
      <div className="flex items-center justify-between text-xs">
        <span className="text-muted">Overall ({data.length} jobs)</span>
        <div className="flex items-center gap-1">
          {overallVariance > 5 ? (
            <TrendingUp className="w-3 h-3 text-amber-400" />
          ) : overallVariance < -5 ? (
            <TrendingDown className="w-3 h-3 text-emerald-400" />
          ) : (
            <Activity className="w-3 h-3 text-emerald-400" />
          )}
          <span className={cn('font-medium', Math.abs(overallVariance) <= 5 ? 'text-emerald-400' : overallVariance > 15 ? 'text-red-400' : 'text-amber-400')}>
            {overallVariance > 0 ? '+' : ''}{overallVariance.toFixed(0)}%
          </span>
        </div>
      </div>
      {Object.entries(byTrade).slice(0, 4).map(([trade, stats]) => {
        const variance = stats.estimated > 0 ? ((stats.actual - stats.estimated) / stats.estimated) * 100 : 0;
        return (
          <div key={trade} className="flex items-center justify-between text-xs">
            <span className="text-muted">{trade} ({stats.count})</span>
            <span className={cn('font-medium', Math.abs(variance) <= 5 ? 'text-emerald-400' : variance > 15 ? 'text-red-400' : 'text-amber-400')}>
              {variance > 0 ? '+' : ''}{variance.toFixed(0)}%
            </span>
          </div>
        );
      })}
      {overallVariance > 10 && (
        <p className="text-[10px] text-amber-400/70 mt-1">
          Your crew averages {overallVariance.toFixed(0)}% more hours than estimated. Consider adjusting labor estimates.
        </p>
      )}
      {overallVariance < -10 && (
        <p className="text-[10px] text-emerald-400/70 mt-1">
          Your crew is {Math.abs(overallVariance).toFixed(0)}% faster than estimates. Your bids may be conservative.
        </p>
      )}
    </div>
  );
}

// ── Estimate Preview ──

function EstimatePreview({
  estimate, areas, lineItems, areaLineItems, totals, onBack,
  currentTier, gbbComparison, laborRates, catalogMaterials, changeOrderTotal,
}: {
  estimate: NonNullable<ReturnType<typeof useEstimate>['estimate']>;
  areas: EstimateArea[];
  lineItems: EstimateLineItem[];
  areaLineItems: Map<string | null, EstimateLineItem[]>;
  totals: { subtotal: number; overhead: number; profit: number; tax: number; grand: number };
  onBack: () => void;
  currentTier?: string;
  gbbComparison?: { good: { grand: number; items: unknown[]; warrantyRange: string | null }; better: { grand: number; items: unknown[]; warrantyRange: string | null }; best: { grand: number; items: unknown[]; warrantyRange: string | null } } | null;
  laborRates?: LaborRateResult[];
  catalogMaterials?: Array<{ description: string | null; photoUrl: string | null; warrantyYears: number | null; brand: string | null; tier: string | null }>;
  changeOrderTotal?: number;
}) {
  const { t } = useTranslation();
  const handlePdf = async (template: 'standard' | 'detailed' | 'summary' | 'proposal') => {
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
        <button onClick={onBack} className="flex items-center gap-1.5 text-xs text-muted hover:text-main">
          <ArrowLeft className="w-3.5 h-3.5" />
          Back to editor
        </button>
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-muted uppercase tracking-wider mr-1">{t('common.downloadPdf')}</span>
          {(['standard', 'detailed', 'summary', 'proposal'] as const).map((t) => (
            <button key={t} onClick={() => handlePdf(t)}
              className="flex items-center gap-1 px-2.5 py-1.5 text-[11px] text-main bg-secondary/50 border border-main rounded-lg hover:bg-surface-hover capitalize">
              <Download className="w-3 h-3" />
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Header */}
      <div className="border-b border-main pb-6 mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-main">{estimate.title || 'Estimate'}</h1>
            <p className="text-sm text-muted mt-1">{estimate.estimateNumber}</p>
          </div>
          <div className="text-right">
            <p className="text-3xl font-bold text-main">${fmtCurrency(totals.grand)}</p>
            <p className="text-xs text-muted mt-1 capitalize">{estimate.status}</p>
          </div>
        </div>
      </div>

      {/* Customer + Property */}
      <div className="grid grid-cols-2 gap-8 mb-8">
        <div>
          <h3 className="text-xs uppercase tracking-wider text-muted mb-2">{t('common.customer')}</h3>
          <p className="text-sm text-main">{estimate.customerName || '—'}</p>
          {estimate.customerEmail && <p className="text-xs text-muted">{estimate.customerEmail}</p>}
          {estimate.customerPhone && <p className="text-xs text-muted">{estimate.customerPhone}</p>}
        </div>
        <div>
          <h3 className="text-xs uppercase tracking-wider text-muted mb-2">{t('common.property')}</h3>
          <p className="text-sm text-main">{estimate.propertyAddress || '—'}</p>
          <p className="text-xs text-muted">{[estimate.propertyCity, estimate.propertyState, estimate.propertyZip].filter(Boolean).join(', ')}</p>
        </div>
      </div>

      {/* Insurance */}
      {estimate.estimateType === 'insurance' && (
        <div className="bg-purple-500/5 border border-purple-500/10 rounded-xl p-5 mb-8">
          <h3 className="text-xs uppercase tracking-wider text-purple-400 mb-3">{t('estimates.insuranceDetails')}</h3>
          <div className="grid grid-cols-3 gap-4 text-xs">
            <div><span className="text-muted">{t('estimates.claimLabel')}</span> <span className="text-main ml-1">{estimate.claimNumber || '—'}</span></div>
            <div><span className="text-muted">{t('estimates.policyLabel')}</span> <span className="text-main ml-1">{estimate.policyNumber || '—'}</span></div>
            <div><span className="text-muted">{t('estimates.carrierLabel')}</span> <span className="text-main ml-1">{estimate.carrierName || '—'}</span></div>
            <div><span className="text-muted">{t('estimates.adjusterLabel')}</span> <span className="text-main ml-1">{estimate.adjusterName || '—'}</span></div>
            <div><span className="text-muted">{t('estimates.deductibleLabel')}</span> <span className="text-main ml-1">${fmtCurrency(estimate.deductible)}</span></div>
            <div><span className="text-muted">Date of Loss:</span> <span className="text-main ml-1">{estimate.dateOfLoss ? formatDateLocale(estimate.dateOfLoss) : '—'}</span></div>
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
              <h3 className="text-sm font-medium text-main">{area.name}</h3>
              <span className="text-sm text-muted">${fmtCurrency(areaTotal)}</span>
            </div>
            <table className="w-full text-xs">
              <thead>
                <tr className="text-muted border-b border-main">
                  <th className="text-left py-1.5 font-medium">{t('common.code')}</th>
                  <th className="text-left py-1.5 font-medium">{t('common.description')}</th>
                  <th className="text-center py-1.5 font-medium">{t('common.action')}</th>
                  <th className="text-right py-1.5 font-medium">{t('common.qty')}</th>
                  <th className="text-right py-1.5 font-medium">{t('estimates.unit')}</th>
                  <th className="text-right py-1.5 font-medium">{t('common.total')}</th>
                </tr>
              </thead>
              <tbody>
                {areaLines.map((line) => (
                  <tr key={line.id} className="border-b border-main/50">
                    <td className="py-1.5 font-mono text-blue-400">{line.zaftoCode || '—'}</td>
                    <td className="py-1.5 text-main">{line.description}</td>
                    <td className="py-1.5 text-center text-muted capitalize">{line.actionType}</td>
                    <td className="py-1.5 text-right text-main">{line.quantity} {line.unitCode}</td>
                    <td className="py-1.5 text-right text-main">${fmtCurrency(line.unitPrice)}</td>
                    <td className="py-1.5 text-right text-main font-medium">${fmtCurrency(line.lineTotal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );
      })}

      {/* Totals */}
      <div className="border-t border-main pt-4 mt-8 space-y-2">
        <div className="flex justify-between text-sm"><span className="text-muted">{t('common.subtotal')}</span><span className="text-main">${fmtCurrency(totals.subtotal)}</span></div>
        <div className="flex justify-between text-sm"><span className="text-muted">Overhead ({estimate.overheadPercent}%)</span><span className="text-main">${fmtCurrency(totals.overhead)}</span></div>
        <div className="flex justify-between text-sm"><span className="text-muted">Profit ({estimate.profitPercent}%)</span><span className="text-main">${fmtCurrency(totals.profit)}</span></div>
        {totals.tax > 0 && (
          <div className="flex justify-between text-sm"><span className="text-muted">Tax ({estimate.taxPercent}%)</span><span className="text-main">${fmtCurrency(totals.tax)}</span></div>
        )}
        <div className="flex justify-between text-lg font-bold pt-2 border-t border-main">
          <span className="text-main">{t('estimates.grandTotal')}</span>
          <span className="text-main">${fmtCurrency(totals.grand)}</span>
        </div>
        {estimate.estimateType === 'insurance' && estimate.deductible > 0 && (
          <div className="flex justify-between text-sm pt-2 border-t border-main">
            <span className="text-purple-400">Net Claim (after ${fmtCurrency(estimate.deductible)} deductible)</span>
            <span className="text-purple-300 font-medium">${fmtCurrency(Math.max(0, totals.grand - estimate.deductible))}</span>
          </div>
        )}
      </div>

      {/* Change Orders */}
      {(changeOrderTotal ?? 0) > 0 && (
        <div className="mt-6 border border-amber-500/20 bg-amber-500/5 rounded-lg p-4">
          <h3 className="text-xs uppercase tracking-wider text-amber-400 mb-2">{t('common.approvedChangeOrders')}</h3>
          <div className="flex justify-between text-sm">
            <span className="text-muted">{t('estimates.changeOrderTotal')}</span>
            <span className="text-amber-300 font-medium">${fmtCurrency(changeOrderTotal ?? 0)}</span>
          </div>
          <div className="flex justify-between text-sm font-bold mt-1 pt-1 border-t border-amber-500/20">
            <span className="text-main">{t('estimates.adjustedGrandTotal')}</span>
            <span className="text-main">${fmtCurrency(totals.grand + (changeOrderTotal ?? 0))}</span>
          </div>
        </div>
      )}

      {/* G/B/B Tier Comparison */}
      {gbbComparison && gbbComparison.good.items.length > 0 && (
        <div className="mt-8">
          <h3 className="text-xs uppercase tracking-wider text-muted mb-3">{t('estimates.materialTierOptions')}</h3>
          <div className="grid grid-cols-3 gap-3">
            {([
              { key: 'good' as const, label: 'Good', desc: 'Standard', color: 'blue' },
              { key: 'better' as const, label: 'Better', desc: 'Premium', color: 'emerald' },
              { key: 'best' as const, label: 'Best', desc: 'Elite', color: 'amber' },
            ]).map(({ key, label, desc, color }) => {
              const tier = gbbComparison[key];
              const isActive = currentTier === (key === 'good' ? 'standard' : key === 'better' ? 'premium' : 'elite');
              return (
                <div key={key} className={`border rounded-lg p-3 ${isActive ? `border-${color}-500/50 bg-${color}-500/5` : 'border-main bg-secondary/30'}`}>
                  <div className="flex items-center gap-2 mb-2">
                    <span className={`text-xs font-bold text-${color}-400`}>{label}</span>
                    <span className="text-[10px] text-muted">{desc}</span>
                    {isActive && <span className="text-[9px] bg-slate-700 text-main px-1.5 py-0.5 rounded">{t('common.current')}</span>}
                  </div>
                  <div className="text-lg font-bold text-main">${fmtCurrency(tier.grand)}</div>
                  <div className="text-[10px] text-muted mt-1">{tier.items.length} items priced</div>
                </div>
              );
            })}
          </div>
          <p className="text-[10px] text-muted mt-2">
            Price range: ${fmtCurrency(gbbComparison.good.grand)} &mdash; ${fmtCurrency(gbbComparison.best.grand)}
          </p>
        </div>
      )}

      {/* Labor Rate Summary */}
      {laborRates && laborRates.length > 0 && (
        <div className="mt-8">
          <h3 className="text-xs uppercase tracking-wider text-muted mb-3">{t('estimates.laborRateSummary')}</h3>
          <div className="border border-main rounded-lg overflow-hidden">
            <table className="w-full text-xs">
              <thead>
                <tr className="text-muted bg-secondary/50">
                  <th className="text-left py-2 px-3 font-medium">{t('common.trade')}</th>
                  <th className="text-right py-2 px-3 font-medium">{t('estimates.baseRate')}</th>
                  <th className="text-right py-2 px-3 font-medium">{t('estimates.burden')}</th>
                  <th className="text-right py-2 px-3 font-medium">{t('estimates.burdenedRate')}</th>
                  <th className="text-left py-2 px-3 font-medium">{t('common.source')}</th>
                </tr>
              </thead>
              <tbody>
                {laborRates.map((rate) => (
                  <tr key={rate.trade} className="border-t border-main/50">
                    <td className="py-1.5 px-3 text-main capitalize">{rate.trade}</td>
                    <td className="py-1.5 px-3 text-right text-main">${fmtCurrency(rate.baseHourlyRate)}/hr</td>
                    <td className="py-1.5 px-3 text-right text-muted">{(rate.burdenMultiplier * 100 - 100).toFixed(1)}%</td>
                    <td className="py-1.5 px-3 text-right text-main font-medium">${fmtCurrency(rate.burdenedRate)}/hr</td>
                    <td className="py-1.5 px-3">
                      <span className={`text-[10px] px-1.5 py-0.5 rounded ${rate.source === 'company' ? 'bg-blue-500/10 text-blue-400' : rate.source === 'msa' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-700 text-muted'}`}>
                        {rate.source === 'msa' ? rate.regionName || 'Regional' : rate.source === 'company' ? 'Company' : 'National'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-[10px] text-muted mt-1">Rates based on BLS Occupational Employment & Wage Statistics. Burden includes FICA, FUTA, SUTA, workers comp, GL insurance, health, and benefits.</p>
        </div>
      )}

      {/* Warranty Summary */}
      {catalogMaterials && catalogMaterials.some(m => m.warrantyYears) && (
        <div className="mt-8">
          <h3 className="text-xs uppercase tracking-wider text-muted mb-3">{t('estimates.warrantyCoverage')}</h3>
          <div className="space-y-1">
            {catalogMaterials.filter(m => m.warrantyYears).slice(0, 10).map((mat, i) => (
              <div key={i} className="flex items-center justify-between text-xs py-1 border-b border-main/50">
                <div className="flex items-center gap-2">
                  <span className="text-main">{mat.description}</span>
                  {mat.brand && <span className="text-[10px] text-muted">({mat.brand})</span>}
                </div>
                <span className="text-emerald-400 font-medium">{mat.warrantyYears} yr</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Notes */}
      {estimate.notes && (
        <div className="mt-8">
          <h3 className="text-xs uppercase tracking-wider text-muted mb-2">{t('common.notes')}</h3>
          <p className="text-sm text-main whitespace-pre-wrap">{estimate.notes}</p>
        </div>
      )}

      {/* Terms & Conditions */}
      <div className="mt-8 border-t border-main pt-6">
        <h3 className="text-xs uppercase tracking-wider text-muted mb-3">{t('common.termsAndConditions')}</h3>
        <div className="text-[11px] text-muted space-y-1.5 leading-relaxed">
          <p>1. This estimate is valid for 30 days from the date of issue unless otherwise noted.</p>
          <p>2. Payment terms: Due upon completion unless otherwise agreed in writing.</p>
          <p>3. Any alterations or deviations from the above specifications involving extra costs will be executed only upon written change order.</p>
          <p>4. All materials are guaranteed to be as specified. All work shall be completed in a workmanlike manner.</p>
          <p>5. Owner agrees to carry fire and extended coverage insurance. Contractor liability is limited to the value of work performed.</p>
          <p>6. Prices are based on current material costs and are subject to change if project start is delayed beyond the validity period.</p>
        </div>
      </div>

      {/* Signature Lines */}
      <div className="mt-10 grid grid-cols-2 gap-12">
        <div>
          <div className="border-t border-main pt-2 mt-12">
            <p className="text-xs text-muted">{t('estimates.contractorSignature')}</p>
            <p className="text-xs text-muted mt-1">Date: _______________</p>
          </div>
        </div>
        <div>
          <div className="border-t border-main pt-2 mt-12">
            <p className="text-xs text-muted">{t('estimates.customerAcceptance')}</p>
            <p className="text-xs text-muted mt-1">Date: _______________</p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="mt-8 pt-4 border-t border-main text-center">
        <p className="text-[10px] text-muted">
          Generated via ZAFTO &middot; {formatDateLocale(new Date())} &middot; {estimate.estimateNumber} &middot; {lineItems.length} line items
        </p>
      </div>
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
  const { t } = useTranslation();
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
      <div className="bg-surface border border-main rounded-xl w-full max-w-4xl max-h-[85vh] flex flex-col shadow-2xl">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-main">
          <div className="flex items-center gap-2">
            <ShoppingCart size={18} className="text-orange-400" />
            <span className="text-sm font-semibold text-main">{t('estimates.materialPricing')}</span>
            {!pricingAvailable && !loading && (
              <span className="text-[10px] text-yellow-400 bg-yellow-500/10 border border-yellow-500/20 px-2 py-0.5 rounded">
                Manual pricing mode
              </span>
            )}
          </div>
          <button onClick={onClose} className="p-1 text-muted hover:text-main">
            <X size={16} />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-5">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <Loader2 size={20} className="animate-spin text-muted" />
              <span className="ml-2 text-sm text-muted">{t('estimates.loadingMaterialData')}</span>
            </div>
          ) : error ? (
            <div className="flex items-center justify-center py-16 text-red-400 gap-2">
              <AlertCircle size={16} />
              <span className="text-sm">{error}</span>
            </div>
          ) : tradeKeys.length === 0 ? (
            <div className="text-center py-16">
              <Package size={32} className="mx-auto text-muted mb-2" />
              <p className="text-sm text-muted">{t('estimates.noTradeDataFoundForThisPropertyScan')}</p>
              <p className="text-xs text-muted mt-1">{t('estimates.runAPropertyScanWithTradeEstimationFirst')}</p>
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
                        : 'text-muted hover:text-main hover:bg-surface-hover border border-transparent'
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
                    <p className="font-medium">{t('estimates.supplierPricingNotConfigured')}</p>
                    <p className="text-yellow-500/70 mt-0.5">
                      Material quantities are from Recon measurements. Configure supplier API keys in Settings to see real-time pricing from Home Depot and Lowe&apos;s.
                    </p>
                  </div>
                </div>
              )}

              {/* Material list table */}
              <div className="border border-main rounded-lg overflow-hidden">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="bg-secondary/50 text-muted">
                      <th className="text-left px-3 py-2 font-medium">{t('common.material')}</th>
                      <th className="text-right px-3 py-2 font-medium">{t('common.qty')}</th>
                      <th className="text-right px-3 py-2 font-medium">{t('common.unit')}</th>
                      <th className="text-right px-3 py-2 font-medium">{t('estimates.wWaste')}</th>
                      {pricingAvailable && (
                        <>
                          <th className="text-right px-3 py-2 font-medium">{t('estimates.hdPrice')}</th>
                          <th className="text-right px-3 py-2 font-medium">Lowe&apos;s</th>
                          <th className="text-right px-3 py-2 font-medium">{t('estimates.bestTier')}</th>
                        </>
                      )}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-main/50">
                    {currentMaterials.map((mat, i) => {
                      const hd = mat.suppliers.find(s => s.supplier === 'homedepot');
                      const lowes = mat.suppliers.find(s => s.supplier === 'lowes');
                      return (
                        <tr key={i} className="hover:bg-surface-hover">
                          <td className="px-3 py-2 text-main">{mat.item}</td>
                          <td className="px-3 py-2 text-right text-main">{mat.quantity}</td>
                          <td className="px-3 py-2 text-right text-muted">{mat.unit}</td>
                          <td className="px-3 py-2 text-right text-main">{mat.total_with_waste}</td>
                          {pricingAvailable && (
                            <>
                              <td className={cn(
                                'px-3 py-2 text-right',
                                mat.best_supplier === 'homedepot' ? 'text-green-400 font-medium' : 'text-main'
                              )}>
                                {hd?.total_price != null ? `${formatCurrency(hd.total_price)}` : '-'}
                              </td>
                              <td className={cn(
                                'px-3 py-2 text-right',
                                mat.best_supplier === 'lowes' ? 'text-green-400 font-medium' : 'text-main'
                              )}>
                                {lowes?.total_price != null ? `${formatCurrency(lowes.total_price)}` : '-'}
                              </td>
                              <td className="px-3 py-2 text-right text-green-400 font-medium">
                                {mat.best_price != null ? `${formatCurrency(mat.best_price)}` : '-'}
                              </td>
                            </>
                          )}
                        </tr>
                      );
                    })}
                  </tbody>
                  {pricingAvailable && currentMaterials.length > 0 && (
                    <tfoot>
                      <tr className="bg-secondary/30 border-t border-main">
                        <td colSpan={4} className="px-3 py-2 text-right text-muted font-medium">{t('common.total')}</td>
                        <td className="px-3 py-2 text-right text-main font-medium">
                          ${currentMaterials.reduce((sum, m) => {
                            const hd = m.suppliers.find(s => s.supplier === 'homedepot');
                            return sum + (hd?.total_price || 0);
                          }, 0).toFixed(2)}
                        </td>
                        <td className="px-3 py-2 text-right text-main font-medium">
                          ${currentMaterials.reduce((sum, m) => {
                            const lowes = m.suppliers.find(s => s.supplier === 'lowes');
                            return sum + (lowes?.total_price || 0);
                          }, 0).toFixed(2)}
                        </td>
                        <td className="px-3 py-2 text-right text-green-400 font-semibold">
                          {formatCurrency(currentMaterials.reduce((sum, m) => sum + (m.best_price || 0), 0))}
                        </td>
                      </tr>
                    </tfoot>
                  )}
                </table>
              </div>

              {/* Disclaimer */}
              <p className="text-[10px] text-muted mt-3">
                Quantities calculated from satellite-estimated measurements. Verify before ordering. Prices shown are retail and may vary by location.
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// Geographic Labor Rates Panel — BLS-backed rates by trade
// ════════════════════════════════════════════════════════════════

function LaborRatesPanel({ rates, loading: ratesLoading }: { rates: LaborRateResult[]; loading: boolean }) {
  const [expanded, setExpanded] = useState(false);

  if (rates.length === 0 && !ratesLoading) return null;

  const regionInfo = rates[0]?.regionName || 'National Average';
  const sourceLabel = rates[0]?.source === 'msa' ? 'MSA Regional' : rates[0]?.source === 'company' ? 'Company Rate' : 'National Avg';

  return (
    <div className="bg-secondary/30 border border-main rounded-xl p-5">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-medium text-main flex items-center gap-2">
          <DollarSign className="w-4 h-4 text-emerald-400" />
          Geographic Labor Rates
          <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            {sourceLabel}
          </span>
        </h3>
        <button onClick={() => setExpanded(!expanded)} className="text-xs text-muted hover:text-main">
          {expanded ? 'Collapse' : 'Show Details'}
        </button>
      </div>

      {ratesLoading ? (
        <div className="flex items-center gap-2 py-2 text-xs text-muted">
          <Loader2 className="w-3 h-3 animate-spin" />
          Looking up BLS rates for this ZIP...
        </div>
      ) : (
        <>
          <p className="text-[10px] text-muted mb-2">Region: {regionInfo}</p>
          <div className="grid grid-cols-2 gap-2">
            {rates.slice(0, expanded ? undefined : 4).map((rate) => (
              <div key={rate.trade} className="flex items-center justify-between px-3 py-1.5 bg-secondary/50 rounded border border-main">
                <span className="text-[11px] text-main capitalize">{rate.trade}</span>
                <div className="text-right">
                  <span className="text-xs text-main font-medium">{formatCurrency(rate.burdenedRate)}/hr</span>
                  <span className="text-[10px] text-muted ml-1">(base {formatCurrency(rate.baseHourlyRate)})</span>
                </div>
              </div>
            ))}
          </div>
          {expanded && rates.length > 0 && (
            <div className="mt-3 text-[10px] text-muted space-y-0.5">
              <p>Burden multiplier includes: FICA (7.65%), FUTA (0.6%), SUTA (~2.5%), workers comp (trade-specific), GL insurance, health benefits</p>
              <p>Rates sourced from BLS OEWS via estimate_pricing table. Company overrides take priority.</p>
            </div>
          )}
        </>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// G/B/B Tier Comparison Panel — side-by-side Good/Better/Best
// ════════════════════════════════════════════════════════════════

interface TierEstimate {
  tier: MaterialTier;
  items: Array<{ description: string; unitPrice: number; materialName: string; photoUrl: string | null; warrantyYears: number | null }>;
  subtotal: number;
  overhead: number;
  profit: number;
  tax: number;
  grand: number;
  warrantyRange: string | null;
}

function TierComparisonPanel({
  comparison,
  onSelectTier,
  onClose,
}: {
  comparison: { good: TierEstimate; better: TierEstimate; best: TierEstimate };
  onSelectTier: (tier: MaterialTier) => void;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const tiers = [
    { key: 'good' as const, data: comparison.good, label: 'Good', sublabel: 'Standard', color: 'text-blue-400', bgColor: 'bg-blue-500/10', borderColor: 'border-blue-500/20', btnColor: 'bg-blue-600 hover:bg-blue-500' },
    { key: 'better' as const, data: comparison.better, label: 'Better', sublabel: 'Premium', color: 'text-amber-400', bgColor: 'bg-amber-500/10', borderColor: 'border-amber-500/20', btnColor: 'bg-amber-600 hover:bg-amber-500' },
    { key: 'best' as const, data: comparison.best, label: 'Best', sublabel: 'Elite', color: 'text-purple-400', bgColor: 'bg-purple-500/10', borderColor: 'border-purple-500/20', btnColor: 'bg-purple-600 hover:bg-purple-500' },
  ];

  return (
    <div className="bg-secondary/30 border border-main rounded-xl overflow-hidden">
      <div className="flex items-center justify-between px-5 py-3 border-b border-main">
        <h3 className="text-sm font-medium text-main flex items-center gap-2">
          <BarChart3 className="w-4 h-4 text-amber-400" />
          Good / Better / Best Comparison
        </h3>
        <button onClick={onClose} className="p-1 text-muted hover:text-main">
          <X className="w-4 h-4" />
        </button>
      </div>

      <div className="grid grid-cols-3 divide-x divide-main">
        {tiers.map(({ key, data, label, sublabel, color, bgColor, borderColor, btnColor }) => (
          <div key={key} className="p-4">
            {/* Tier header */}
            <div className="text-center mb-4">
              <span className={cn('text-lg font-bold', color)}>{label}</span>
              <p className="text-[10px] text-muted">{sublabel} Materials</p>
              <p className="text-2xl font-bold text-main mt-2">${fmtCurrency(data.grand)}</p>
            </div>

            {/* Material summary — show first 5 items */}
            <div className="space-y-2 mb-4">
              {data.items.slice(0, 5).map((item, i) => (
                <div key={i} className="flex items-center gap-2">
                  {item.photoUrl ? (
                    <div className="w-6 h-6 rounded border border-main overflow-hidden flex-shrink-0 bg-secondary">
                      <img src={item.photoUrl} alt="" className="w-full h-full object-cover" />
                    </div>
                  ) : (
                    <div className="w-6 h-6 rounded border border-main bg-secondary flex items-center justify-center flex-shrink-0">
                      <Package className="w-3 h-3 text-muted" />
                    </div>
                  )}
                  <div className="min-w-0 flex-1">
                    <p className="text-[10px] text-main truncate">{item.materialName}</p>
                  </div>
                  <span className="text-[10px] text-muted flex-shrink-0">${fmtCurrency(item.unitPrice)}</span>
                </div>
              ))}
              {data.items.length > 5 && (
                <p className="text-[10px] text-muted text-center">+{data.items.length - 5} more items</p>
              )}
            </div>

            {/* Cost breakdown */}
            <div className="space-y-1.5 text-[11px] border-t border-main pt-3 mb-3">
              <div className="flex justify-between"><span className="text-muted">{t('common.subtotal')}</span><span className="text-main">${fmtCurrency(data.subtotal)}</span></div>
              <div className="flex justify-between"><span className="text-muted">{t('common.oAndP')}</span><span className="text-main">${fmtCurrency(data.overhead + data.profit)}</span></div>
              <div className="flex justify-between"><span className="text-muted">{t('common.tax')}</span><span className="text-main">${fmtCurrency(data.tax)}</span></div>
              <div className="flex justify-between font-medium border-t border-main pt-1.5">
                <span className="text-main">{t('common.total')}</span>
                <span className={color}>${fmtCurrency(data.grand)}</span>
              </div>
            </div>

            {/* Warranty row */}
            {data.warrantyRange && (
              <div className="flex items-center justify-center gap-1 text-[10px] text-green-400 mb-3">
                <ShieldCheck className="w-3 h-3" />
                {data.warrantyRange} warranty
              </div>
            )}

            {/* Select tier button */}
            <button
              onClick={() => onSelectTier(data.tier)}
              className={cn('w-full py-2 text-xs text-white rounded-lg font-medium transition-colors', btnColor)}
            >
              Select {label}
            </button>
          </div>
        ))}
      </div>

      {/* Savings comparison */}
      {comparison.good.grand > 0 && comparison.best.grand > 0 && (
        <div className="px-5 py-3 border-t border-main text-center">
          <p className="text-[10px] text-muted">
            Price range: <span className="text-main font-medium">${fmtCurrency(comparison.good.grand)}</span>
            {' '}&ndash;{' '}
            <span className="text-main font-medium">${fmtCurrency(comparison.best.grand)}</span>
            {comparison.best.grand > comparison.good.grand && (
              <span className="text-muted"> ({((comparison.best.grand - comparison.good.grand) / comparison.good.grand * 100).toFixed(0)}% difference)</span>
            )}
          </p>
        </div>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
// Template Panel — save/load estimate templates
// ════════════════════════════════════════════════════════════════

interface EstimateTemplate {
  id: string;
  name: string;
  description: string | null;
  trade: string | null;
  itemCount: number;
  defaultTier: MaterialTier;
  createdAt: string;
}

function TemplatePanel({
  estimateId,
  currentAreas,
  currentLineItems,
  currentTier,
  onClose,
  onApplyTemplate,
}: {
  estimateId: string;
  currentAreas: EstimateArea[];
  currentLineItems: EstimateLineItem[];
  currentTier: MaterialTier;
  onClose: () => void;
  onApplyTemplate: () => Promise<void>;
}) {
  const { t: tr } = useTranslation();
  const [templates, setTemplates] = useState<EstimateTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [applying, setApplying] = useState(false);
  const [newName, setNewName] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [showSaveForm, setShowSaveForm] = useState(false);

  // Load templates
  useEffect(() => {
    const load = async () => {
      try {
        const supabase = getSupabase();
        const { data } = await supabase
          .from('estimate_templates')
          .select('id, name, description, trade, template_data, default_tier, created_at')
          .is('deleted_at', null)
          .order('name');

        setTemplates((data || []).map((t: Record<string, unknown>) => ({
          id: t.id as string,
          name: t.name as string,
          description: t.description as string | null,
          trade: t.trade as string | null,
          itemCount: ((t.template_data as Record<string, unknown>)?.items as unknown[] || []).length,
          defaultTier: (t.default_tier as MaterialTier) || 'standard',
          createdAt: t.created_at as string,
        })));
      } catch {
        // silently handle
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  // Save current estimate as template
  const handleSave = async () => {
    if (!newName.trim()) return;
    setSaving(true);
    try {
      const supabase = getSupabase();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) return;

      const companyId = session.user.app_metadata?.company_id;

      const templateData = {
        areas: currentAreas.map(a => ({
          name: a.name,
          lengthFt: a.lengthFt,
          widthFt: a.widthFt,
          heightFt: a.heightFt,
        })),
        items: currentLineItems.map(li => ({
          zaftoCode: li.zaftoCode,
          description: li.description,
          actionType: li.actionType,
          quantity: li.quantity,
          unitCode: li.unitCode,
          unitPrice: li.unitPrice,
          materialCost: li.materialCost,
          laborCost: li.laborCost,
          equipmentCost: li.equipmentCost,
          areaName: currentAreas.find(a => a.id === li.areaId)?.name || null,
        })),
      };

      const { data: inserted } = await supabase.from('estimate_templates').insert({
        company_id: companyId,
        name: newName.trim(),
        description: newDescription.trim() || null,
        template_data: templateData,
        default_tier: currentTier,
      }).select('id, name, description, trade, template_data, default_tier, created_at').single();

      if (inserted) {
        setTemplates(prev => [...prev, {
          id: inserted.id as string,
          name: inserted.name as string,
          description: inserted.description as string | null,
          trade: inserted.trade as string | null,
          itemCount: currentLineItems.length,
          defaultTier: currentTier,
          createdAt: inserted.created_at as string,
        }]);
      }

      setNewName('');
      setNewDescription('');
      setShowSaveForm(false);
    } finally {
      setSaving(false);
    }
  };

  // Apply template to current estimate
  const handleApply = async (templateId: string) => {
    setApplying(true);
    try {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('estimate_templates')
        .select('template_data')
        .eq('id', templateId)
        .single();

      if (!data?.template_data) return;
      const tpl = data.template_data as { areas?: Array<{ name: string }>; items?: Array<Record<string, unknown>> };

      // Create areas from template
      if (tpl.areas) {
        for (const area of tpl.areas) {
          await supabase.from('estimate_areas').insert({
            estimate_id: estimateId,
            name: area.name,
          });
        }
      }

      // Reload to get new area IDs, then add items
      const { data: newAreas } = await supabase
        .from('estimate_areas')
        .select('id, name')
        .eq('estimate_id', estimateId)
        .is('deleted_at', null);

      const areaMap = new Map((newAreas || []).map((a: Record<string, unknown>) => [a.name as string, a.id as string]));

      if (tpl.items) {
        for (const item of tpl.items) {
          const areaId = item.areaName ? areaMap.get(item.areaName as string) : null;
          await supabase.from('estimate_line_items').insert({
            estimate_id: estimateId,
            area_id: areaId || null,
            zafto_code: item.zaftoCode || null,
            description: item.description,
            action_type: item.actionType || 'replace',
            quantity: item.quantity || 1,
            unit_code: item.unitCode || 'EA',
            unit_price: item.unitPrice || 0,
            material_cost: item.materialCost || 0,
            labor_cost: item.laborCost || 0,
            equipment_cost: item.equipmentCost || 0,
            line_total: ((item.quantity as number) || 1) * ((item.unitPrice as number) || 0),
          });
        }
      }

      await onApplyTemplate();
    } finally {
      setApplying(false);
    }
  };

  // Delete template (soft)
  const handleDelete = async (templateId: string) => {
    const supabase = getSupabase();
    await supabase.from('estimate_templates').update({ deleted_at: new Date().toISOString() }).eq('id', templateId);
    setTemplates(prev => prev.filter(t => t.id !== templateId));
  };

  return (
    <div className="bg-secondary/30 border border-main rounded-xl overflow-hidden">
      <div className="flex items-center justify-between px-5 py-3 border-b border-main">
        <h3 className="text-sm font-medium text-main flex items-center gap-2">
          <Copy className="w-4 h-4 text-muted" />
          Estimate Templates
        </h3>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowSaveForm(!showSaveForm)}
            className="flex items-center gap-1.5 px-2.5 py-1 text-[11px] text-blue-400 bg-blue-500/10 border border-blue-500/20 rounded-md hover:bg-blue-500/20"
          >
            <Save className="w-3 h-3" />
            Save Current
          </button>
          <button onClick={onClose} className="p-1 text-muted hover:text-main">
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Save form */}
      {showSaveForm && (
        <div className="p-4 border-b border-main space-y-2">
          <input
            type="text"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            placeholder="Template name..."
            className="w-full px-3 py-1.5 bg-secondary border border-main rounded-lg text-xs text-main placeholder:text-muted"
            autoFocus
          />
          <input
            type="text"
            value={newDescription}
            onChange={(e) => setNewDescription(e.target.value)}
            placeholder="Description (optional)..."
            className="w-full px-3 py-1.5 bg-secondary border border-main rounded-lg text-xs text-main placeholder:text-muted"
          />
          <div className="flex items-center gap-2">
            <button
              onClick={handleSave}
              disabled={saving || !newName.trim()}
              className="flex items-center gap-1 px-3 py-1.5 text-xs text-white bg-blue-600 rounded-lg hover:bg-blue-500 disabled:opacity-50"
            >
              {saving ? <Loader2 className="w-3 h-3 animate-spin" /> : <Save className="w-3 h-3" />}
              Save Template
            </button>
            <button onClick={() => setShowSaveForm(false)} className="text-xs text-muted hover:text-main">
              Cancel
            </button>
            <span className="text-[10px] text-muted ml-auto">
              {currentLineItems.length} items, {currentAreas.length} areas
            </span>
          </div>
        </div>
      )}

      {/* Template list */}
      <div className="max-h-[300px] overflow-y-auto">
        {loading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="w-4 h-4 animate-spin text-muted" />
          </div>
        ) : templates.length === 0 ? (
          <div className="text-center py-8 text-muted text-xs">
            <Copy className="w-8 h-8 mx-auto mb-2 opacity-40" />
            <p>{tr('estimates.noTemplatesSavedYet')}</p>
            <p className="text-[10px] mt-1">{tr('estimates.saveYourCurrentEstimateAsAReusableTemplate')}</p>
          </div>
        ) : (
          <div className="divide-y divide-main/50">
            {templates.map(tpl => (
              <div key={tpl.id} className="flex items-center justify-between px-4 py-3 hover:bg-surface-hover">
                <div className="min-w-0">
                  <p className="text-xs text-main font-medium">{tpl.name}</p>
                  {tpl.description && <p className="text-[10px] text-muted truncate mt-0.5">{tpl.description}</p>}
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-[10px] text-muted">{tpl.itemCount} items</span>
                    {tpl.trade && <span className="text-[10px] px-1 py-0.5 rounded bg-slate-700/50 text-muted">{tpl.trade}</span>}
                    <span className={cn(
                      'text-[10px] px-1 py-0.5 rounded',
                      TIER_CONFIG.find(t => t.value === tpl.defaultTier)?.bgColor,
                      TIER_CONFIG.find(t => t.value === tpl.defaultTier)?.color,
                    )}>
                      {TIER_CONFIG.find(t => t.value === tpl.defaultTier)?.label}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <button
                    onClick={() => handleApply(tpl.id)}
                    disabled={applying}
                    className="px-2.5 py-1 text-[10px] text-blue-400 bg-blue-500/10 border border-blue-500/20 rounded hover:bg-blue-500/20"
                  >
                    {applying ? 'Applying...' : 'Apply'}
                  </button>
                  <button
                    onClick={() => handleDelete(tpl.id)}
                    className="p-1 text-muted hover:text-red-400"
                  >
                    <Trash2 className="w-3 h-3" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Estimate Version Comparison ──

function VersionComparisonPanel({
  versions,
  changeOrders,
  onClose,
}: {
  versions: { id: string; versionNumber: number; label: string | null; snapshotData: Record<string, unknown>; createdAt: string }[];
  changeOrders: { id: string; changeOrderNumber: number; title: string; status: string; subtotalChange: number; totalChange: number; itemsAdded: Array<Record<string, unknown>>; itemsModified: Array<Record<string, unknown>>; itemsRemoved: Array<Record<string, unknown>>; createdAt: string }[];
  onClose: () => void;
}) {
  const [selectedA, setSelectedA] = useState<string>(versions.length > 1 ? versions[versions.length - 2].id : '');
  const [selectedB, setSelectedB] = useState<string>(versions.length > 0 ? versions[versions.length - 1].id : '');

  const versionA = versions.find(v => v.id === selectedA);
  const versionB = versions.find(v => v.id === selectedB);

  const getItems = (v: typeof versionA) => {
    if (!v?.snapshotData) return [];
    const items = v.snapshotData.lineItems as Array<{ id?: string; description: string; unitPrice: number; materialCost?: number }> | undefined;
    return items || [];
  };

  const itemsA = getItems(versionA);
  const itemsB = getItems(versionB);

  const totalA = itemsA.reduce((s, i) => s + (i.unitPrice || 0), 0);
  const totalB = itemsB.reduce((s, i) => s + (i.unitPrice || 0), 0);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60">
      <div className="bg-surface border border-main rounded-xl w-[700px] max-h-[80vh] overflow-y-auto">
        <div className="flex items-center justify-between px-5 py-4 border-b border-main">
          <div className="flex items-center gap-2">
            <BarChart3 className="w-4 h-4 text-blue-400" />
            <span className="text-sm font-semibold text-main">Version Comparison</span>
          </div>
          <button onClick={onClose} className="p-1 text-muted hover:text-main">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {versions.length < 2 ? (
            <p className="text-sm text-muted text-center py-8">
              At least 2 versions needed for comparison. Versions are created when you switch tiers or make major changes.
            </p>
          ) : (
            <>
              {/* Version selectors */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-[10px] text-muted block mb-1">Version A (Before)</label>
                  <select value={selectedA} onChange={e => setSelectedA(e.target.value)}
                    className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-xs text-main">
                    {versions.map(v => (
                      <option key={v.id} value={v.id}>
                        v{v.versionNumber} — {v.label || new Date(v.createdAt).toLocaleDateString()}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-[10px] text-muted block mb-1">Version B (After)</label>
                  <select value={selectedB} onChange={e => setSelectedB(e.target.value)}
                    className="w-full px-3 py-2 bg-secondary border border-main rounded-lg text-xs text-main">
                    {versions.map(v => (
                      <option key={v.id} value={v.id}>
                        v{v.versionNumber} — {v.label || new Date(v.createdAt).toLocaleDateString()}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Comparison summary */}
              {versionA && versionB && (
                <div className="grid grid-cols-3 gap-3 text-center">
                  <div className="bg-secondary/50 rounded-lg p-3">
                    <p className="text-[10px] text-muted">Version A Items</p>
                    <p className="text-lg font-semibold text-main">{itemsA.length}</p>
                  </div>
                  <div className="bg-secondary/50 rounded-lg p-3">
                    <p className="text-[10px] text-muted">Version B Items</p>
                    <p className="text-lg font-semibold text-main">{itemsB.length}</p>
                  </div>
                  <div className="bg-secondary/50 rounded-lg p-3">
                    <p className="text-[10px] text-muted">Price Delta</p>
                    <p className={cn('text-lg font-semibold', totalB - totalA > 0 ? 'text-amber-400' : totalB - totalA < 0 ? 'text-emerald-400' : 'text-muted')}>
                      {totalB - totalA > 0 ? '+' : ''}{fmtCurrency(totalB - totalA)}
                    </p>
                  </div>
                </div>
              )}

              {/* Item-level diff */}
              {versionA && versionB && itemsA.length > 0 && (
                <div className="space-y-1.5 max-h-[300px] overflow-y-auto">
                  <p className="text-[10px] text-muted uppercase font-semibold">Item Changes</p>
                  {itemsA.map((itemA, idx) => {
                    const itemBMatch = itemsB[idx];
                    if (!itemBMatch) return (
                      <div key={idx} className="flex items-center justify-between px-3 py-1.5 bg-red-500/5 border border-red-500/10 rounded text-xs">
                        <span className="text-red-400 line-through">{itemA.description}</span>
                        <span className="text-red-400">Removed</span>
                      </div>
                    );
                    const priceChanged = itemA.unitPrice !== itemBMatch.unitPrice;
                    const descChanged = itemA.description !== itemBMatch.description;
                    if (!priceChanged && !descChanged) return null;
                    return (
                      <div key={idx} className="flex items-center justify-between px-3 py-1.5 bg-amber-500/5 border border-amber-500/10 rounded text-xs">
                        <div>
                          {descChanged ? (
                            <span className="text-main">{itemA.description} <span className="text-muted">&rarr;</span> <span className="text-blue-400">{itemBMatch.description}</span></span>
                          ) : (
                            <span className="text-main">{itemA.description}</span>
                          )}
                        </div>
                        {priceChanged && (
                          <span className={cn('font-medium', itemBMatch.unitPrice > itemA.unitPrice ? 'text-amber-400' : 'text-emerald-400')}>
                            ${fmtCurrency(itemA.unitPrice)} &rarr; ${fmtCurrency(itemBMatch.unitPrice)}
                          </span>
                        )}
                      </div>
                    );
                  })}
                  {itemsB.slice(itemsA.length).map((item, idx) => (
                    <div key={`new-${idx}`} className="flex items-center justify-between px-3 py-1.5 bg-emerald-500/5 border border-emerald-500/10 rounded text-xs">
                      <span className="text-emerald-400">{item.description}</span>
                      <span className="text-emerald-400">Added</span>
                    </div>
                  ))}
                </div>
              )}

              {/* Change Orders */}
              {changeOrders.length > 0 && (
                <div className="space-y-2 pt-3 border-t border-main">
                  <p className="text-[10px] text-muted uppercase font-semibold">Change Orders</p>
                  {changeOrders.map(co => (
                    <div key={co.id} className="flex items-center justify-between px-3 py-2 bg-secondary/50 rounded-lg text-xs">
                      <div>
                        <span className="text-main font-medium">CO-{co.changeOrderNumber}: {co.title}</span>
                        <div className="text-[10px] text-muted mt-0.5">
                          {co.itemsAdded.length} added, {co.itemsModified.length} modified, {co.itemsRemoved.length} removed
                        </div>
                      </div>
                      <div className="text-right">
                        <span className={cn('font-medium', co.totalChange > 0 ? 'text-amber-400' : co.totalChange < 0 ? 'text-emerald-400' : 'text-muted')}>
                          {co.totalChange > 0 ? '+' : ''}${fmtCurrency(co.totalChange)}
                        </span>
                        <div className={cn('text-[10px] capitalize', co.status === 'approved' ? 'text-emerald-400' : co.status === 'rejected' ? 'text-red-400' : 'text-muted')}>
                          {co.status}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
