'use client';

import { useState, useEffect, useCallback, useMemo, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  ArrowLeft, Plus, Trash2, Search, X, ChevronDown, ChevronRight, Save,
  DollarSign, Package, Wrench, Zap, FileText, Home, BookOpen,
  Calculator, Copy, Download, Layers, AlertCircle, Check, Loader2,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { getSupabase } from '@/lib/supabase';
import {
  useEstimateLines, useXactCodes, usePricingLookup, useEstimateTemplates,
  type EstimateLine, type XactimateCode, type EstimateSummary, type EstimateTemplate,
} from '@/lib/hooks/use-estimate-engine';

// ── Claim header info ──

interface ClaimInfo {
  id: string;
  claimNumber: string;
  customerName: string;
  lossType: string;
  propertyAddress: string;
  claimStatus: string;
}

// ── Coverage group config ──

const COVERAGE_GROUPS = [
  { id: 'structural' as const, label: 'Structural', color: 'blue' },
  { id: 'contents' as const, label: 'Contents', color: 'purple' },
  { id: 'other' as const, label: 'Other', color: 'amber' },
];

const COVERAGE_COLORS: Record<string, string> = {
  structural: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
  contents: 'bg-purple-500/10 text-purple-400 border-purple-500/20',
  other: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
};

const CONFIDENCE_COLORS: Record<string, string> = {
  low: 'text-red-400',
  medium: 'text-amber-400',
  high: 'text-green-400',
  verified: 'text-emerald-400',
};

const fmt = (n: number) => n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

export default function EstimateEditorPage() {
  const params = useParams();
  const router = useRouter();
  const claimId = params.id as string;

  // ── Claim info ──
  const [claim, setClaim] = useState<ClaimInfo | null>(null);
  const [claimLoading, setClaimLoading] = useState(true);

  // ── Hooks ──
  const { lines, loading: linesLoading, addLine, updateLine, deleteLine, calculateSummary } = useEstimateLines(claimId);
  const { codes, loading: codesLoading, searchCodes, getCategories } = useXactCodes();
  const { lookupPrice } = usePricingLookup();
  const { templates, loading: templatesLoading, saveTemplate } = useEstimateTemplates();

  // ── UI state ──
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarTab, setSidebarTab] = useState<'codes' | 'templates'>('codes');
  const [codeSearch, setCodeSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');
  const [categories, setCategories] = useState<Array<{ code: string; name: string }>>([]);
  const [overheadRate, setOverheadRate] = useState(10);
  const [profitRate, setProfitRate] = useState(10);
  const [editingLine, setEditingLine] = useState<string | null>(null);
  const [addingRoom, setAddingRoom] = useState(false);
  const [newRoomName, setNewRoomName] = useState('');
  const [savingTemplate, setSavingTemplate] = useState(false);
  const [templateName, setTemplateName] = useState('');
  const [regionCode, setRegionCode] = useState('');
  const searchTimer = useRef<ReturnType<typeof setTimeout>>(null);

  // ── Fetch claim info ──
  useEffect(() => {
    async function fetchClaim() {
      const supabase = getSupabase();
      const { data } = await supabase
        .from('insurance_claims')
        .select('id, claim_number, customer_name, loss_type, property_address, claim_status')
        .eq('id', claimId)
        .single();

      if (data) {
        setClaim({
          id: data.id,
          claimNumber: data.claim_number || '',
          customerName: data.customer_name || '',
          lossType: data.loss_type || '',
          propertyAddress: data.property_address || '',
          claimStatus: data.claim_status || '',
        });
      }
      setClaimLoading(false);
    }
    fetchClaim();
  }, [claimId]);

  // ── Fetch categories on mount ──
  useEffect(() => {
    getCategories().then(setCategories);
  }, [getCategories]);

  // ── Debounced code search ──
  const handleCodeSearch = useCallback((query: string) => {
    setCodeSearch(query);
    if (searchTimer.current) clearTimeout(searchTimer.current);
    searchTimer.current = setTimeout(() => {
      searchCodes(query, selectedCategory);
    }, 300);
  }, [searchCodes, selectedCategory]);

  useEffect(() => {
    if (sidebarOpen && sidebarTab === 'codes') {
      searchCodes(codeSearch, selectedCategory);
    }
  }, [selectedCategory, sidebarOpen, sidebarTab]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Group lines by room ──
  const roomGroups = useMemo(() => {
    const groups = new Map<string, EstimateLine[]>();
    for (const line of lines) {
      const room = line.roomName || 'Unassigned';
      const existing = groups.get(room) || [];
      existing.push(line);
      groups.set(room, existing);
    }
    return groups;
  }, [lines]);

  // ── Summary ──
  const summary = useMemo(() => calculateSummary(lines, overheadRate, profitRate), [lines, overheadRate, profitRate, calculateSummary]);

  // ── Add code to estimate ──
  const handleAddCode = useCallback(async (code: XactimateCode, room: string) => {
    let unitPrice = 0;
    let materialCost = 0;
    let laborCost = 0;
    let equipmentCost = 0;

    // Auto-lookup pricing if region is set
    if (regionCode) {
      const pricing = await lookupPrice(code.id, regionCode);
      if (pricing) {
        materialCost = pricing.materialCost;
        laborCost = pricing.laborCost;
        equipmentCost = pricing.equipmentCost;
        unitPrice = pricing.totalCost;
      }
    }

    const nextLineNumber = lines.filter(l => l.roomName === room).length + 1;

    await addLine({
      claimId,
      codeId: code.id,
      category: code.categoryCode,
      itemCode: code.fullCode,
      description: code.description,
      quantity: 1,
      unit: code.unit,
      unitPrice,
      total: unitPrice,
      materialCost,
      laborCost,
      equipmentCost,
      roomName: room,
      lineNumber: nextLineNumber,
      coverageGroup: code.coverageGroup,
      isSupplement: false,
      supplementId: null,
      depreciationRate: 0,
      acvAmount: null,
      rcvAmount: null,
      notes: '',
    });
  }, [claimId, lines, regionCode, lookupPrice, addLine]);

  // ── Apply template ──
  const handleApplyTemplate = useCallback(async (template: EstimateTemplate) => {
    const room = Array.from(roomGroups.keys())[0] || 'Main';
    for (const item of template.lineItems) {
      // Try to find the code in the database
      const supabase = getSupabase();
      const { data: codeRow } = await supabase
        .from('xactimate_codes')
        .select('*')
        .eq('full_code', item.code)
        .single();

      if (codeRow) {
        const code: XactimateCode = {
          id: codeRow.id,
          categoryCode: codeRow.category_code,
          categoryName: codeRow.category_name,
          selectorCode: codeRow.selector_code,
          fullCode: codeRow.full_code,
          description: item.description || codeRow.description,
          unit: item.unit || codeRow.unit,
          coverageGroup: codeRow.coverage_group,
          hasMaterial: codeRow.has_material,
          hasLabor: codeRow.has_labor,
          hasEquipment: codeRow.has_equipment,
        };
        await handleAddCode(code, room);
      } else {
        // Custom line (no matching code)
        const nextLineNumber = lines.length + 1;
        await addLine({
          claimId,
          codeId: null,
          category: '',
          itemCode: item.code,
          description: item.description,
          quantity: item.qty,
          unit: item.unit,
          unitPrice: 0,
          total: 0,
          materialCost: 0,
          laborCost: 0,
          equipmentCost: 0,
          roomName: room,
          lineNumber: nextLineNumber,
          coverageGroup: 'structural',
          isSupplement: false,
          supplementId: null,
          depreciationRate: 0,
          acvAmount: null,
          rcvAmount: null,
          notes: item.notes || '',
        });
      }
    }
  }, [roomGroups, handleAddCode, lines, addLine, claimId]);

  // ── Save as template ──
  const handleSaveTemplate = useCallback(async () => {
    if (!templateName.trim()) return;
    await saveTemplate({
      name: templateName.trim(),
      description: `Template from claim ${claim?.claimNumber || claimId}`,
      tradeType: '',
      lossType: claim?.lossType || '',
      lineItems: lines.map(l => ({
        code: l.itemCode,
        description: l.description,
        qty: l.quantity,
        unit: l.unit,
        notes: l.notes,
      })),
    });
    setSavingTemplate(false);
    setTemplateName('');
  }, [templateName, saveTemplate, claim, claimId, lines]);

  // ── Inline line editing ──
  const handleLineUpdate = useCallback(async (lineId: string, field: string, value: string | number) => {
    const line = lines.find(l => l.id === lineId);
    if (!line) return;

    const updates: Partial<EstimateLine> = {};
    if (field === 'quantity') {
      const qty = Number(value) || 0;
      updates.quantity = qty;
      updates.total = qty * line.unitPrice;
    } else if (field === 'unitPrice') {
      const price = Number(value) || 0;
      updates.unitPrice = price;
      updates.total = line.quantity * price;
    } else if (field === 'depreciationRate') {
      updates.depreciationRate = Number(value) || 0;
    } else if (field === 'coverageGroup') {
      updates.coverageGroup = value as EstimateLine['coverageGroup'];
    } else if (field === 'notes') {
      updates.notes = value as string;
    }

    await updateLine(lineId, updates);
  }, [lines, updateLine]);

  // ── Loading state ──
  if (claimLoading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-6 h-6 text-zinc-500 animate-spin" />
      </div>
    );
  }

  if (!claim) {
    return (
      <div className="text-center py-16 text-zinc-500">
        <AlertCircle className="w-12 h-12 mx-auto mb-3 opacity-50" />
        <p className="text-lg font-medium">Claim not found</p>
        <button onClick={() => router.push('/dashboard/estimates')} className="text-sm text-blue-400 hover:underline mt-2">
          Back to estimates
        </button>
      </div>
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
                <h1 className="text-lg font-semibold text-zinc-100">
                  {claim.claimNumber || 'Untitled Estimate'}
                </h1>
                <p className="text-xs text-zinc-500">
                  {claim.customerName} &middot; {claim.lossType.replace(/_/g, ' ')} &middot; {claim.propertyAddress || 'No address'}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              {/* Region Code */}
              <div className="flex items-center gap-1.5">
                <label className="text-xs text-zinc-500">Region:</label>
                <input
                  type="text"
                  value={regionCode}
                  onChange={(e) => setRegionCode(e.target.value.toUpperCase())}
                  placeholder="e.g. TX-HOU"
                  className="w-24 px-2 py-1 text-xs bg-zinc-800/50 border border-zinc-700/50 rounded text-zinc-200 placeholder:text-zinc-600"
                />
              </div>
              {/* Template actions */}
              <button
                onClick={() => setSavingTemplate(true)}
                className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800"
              >
                <Save className="w-3.5 h-3.5" />
                Save Template
              </button>
              {/* Code Browser Toggle */}
              <button
                onClick={() => setSidebarOpen(!sidebarOpen)}
                className={cn(
                  'flex items-center gap-1.5 px-3 py-1.5 text-xs rounded-lg border transition-colors',
                  sidebarOpen
                    ? 'text-blue-400 bg-blue-500/10 border-blue-500/20'
                    : 'text-zinc-300 bg-zinc-800/50 border-zinc-700/50 hover:bg-zinc-800'
                )}
              >
                <BookOpen className="w-3.5 h-3.5" />
                Code Browser
              </button>
            </div>
          </div>
        </div>

        {/* Save Template Modal */}
        {savingTemplate && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <div className="bg-zinc-900 border border-zinc-700 rounded-xl p-6 w-96">
              <h3 className="text-sm font-medium text-zinc-100 mb-4">Save as Template</h3>
              <input
                type="text"
                value={templateName}
                onChange={(e) => setTemplateName(e.target.value)}
                placeholder="Template name..."
                className="w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500 mb-4"
                autoFocus
              />
              <p className="text-xs text-zinc-500 mb-4">{lines.length} line items will be saved</p>
              <div className="flex justify-end gap-2">
                <button onClick={() => setSavingTemplate(false)} className="px-3 py-1.5 text-xs text-zinc-400 hover:text-zinc-200">Cancel</button>
                <button onClick={handleSaveTemplate} className="px-3 py-1.5 text-xs text-white bg-blue-600 rounded-lg hover:bg-blue-500">Save</button>
              </div>
            </div>
          </div>
        )}

        {/* Room sections */}
        <div className="p-6 space-y-6">
          {/* Add Room */}
          <div className="flex items-center gap-2">
            {addingRoom ? (
              <div className="flex items-center gap-2">
                <Home className="w-4 h-4 text-zinc-500" />
                <input
                  type="text"
                  value={newRoomName}
                  onChange={(e) => setNewRoomName(e.target.value)}
                  placeholder="Room name (e.g. Kitchen, Master Bedroom)"
                  className="px-3 py-1.5 bg-zinc-800 border border-zinc-700 rounded-lg text-sm text-zinc-100 placeholder:text-zinc-500 w-64"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && newRoomName.trim()) {
                      setAddingRoom(false);
                      setNewRoomName('');
                      // Room is auto-created when a line is added to it
                    }
                    if (e.key === 'Escape') {
                      setAddingRoom(false);
                      setNewRoomName('');
                    }
                  }}
                />
                <button
                  onClick={() => { setAddingRoom(false); setNewRoomName(''); }}
                  className="p-1 text-zinc-500 hover:text-zinc-300"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <button
                onClick={() => setAddingRoom(true)}
                className="flex items-center gap-1.5 text-xs text-zinc-400 hover:text-zinc-200"
              >
                <Plus className="w-3.5 h-3.5" />
                Add Room
              </button>
            )}
          </div>

          {/* Lines loading */}
          {linesLoading ? (
            <div className="space-y-3">
              {[1, 2, 3].map((i) => (
                <div key={i} className="h-16 bg-zinc-800/50 rounded-lg animate-pulse" />
              ))}
            </div>
          ) : lines.length === 0 ? (
            <div className="text-center py-16 text-zinc-500">
              <Calculator className="w-12 h-12 mx-auto mb-3 opacity-50" />
              <p className="text-lg font-medium">No line items yet</p>
              <p className="text-sm mt-1">Open the Code Browser to add Xactimate codes, or apply a template</p>
              <div className="flex items-center justify-center gap-3 mt-4">
                <button
                  onClick={() => { setSidebarOpen(true); setSidebarTab('codes'); }}
                  className="flex items-center gap-1.5 px-4 py-2 text-sm text-blue-400 bg-blue-500/10 border border-blue-500/20 rounded-lg hover:bg-blue-500/20"
                >
                  <BookOpen className="w-4 h-4" />
                  Browse Codes
                </button>
                <button
                  onClick={() => { setSidebarOpen(true); setSidebarTab('templates'); }}
                  className="flex items-center gap-1.5 px-4 py-2 text-sm text-zinc-300 bg-zinc-800/50 border border-zinc-700/50 rounded-lg hover:bg-zinc-800"
                >
                  <Copy className="w-4 h-4" />
                  Use Template
                </button>
              </div>
            </div>
          ) : (
            <>
              {/* Room groups */}
              {Array.from(roomGroups.entries()).map(([room, roomLines]) => (
                <RoomSection
                  key={room}
                  room={room}
                  lines={roomLines}
                  editingLine={editingLine}
                  onEdit={setEditingLine}
                  onUpdate={handleLineUpdate}
                  onDelete={deleteLine}
                  onAddCode={(code) => handleAddCode(code, room)}
                  onOpenBrowser={() => { setSidebarOpen(true); setSidebarTab('codes'); }}
                />
              ))}

              {/* ── Summary Panel ── */}
              <SummaryPanel
                summary={summary}
                overheadRate={overheadRate}
                profitRate={profitRate}
                onOverheadChange={setOverheadRate}
                onProfitChange={setProfitRate}
                lineCount={lines.length}
              />
            </>
          )}
        </div>
      </div>

      {/* ── Sidebar: Code Browser / Templates ── */}
      {sidebarOpen && (
        <div className="fixed right-0 top-16 bottom-0 w-[380px] bg-zinc-900 border-l border-zinc-800 flex flex-col z-20">
          {/* Sidebar Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-zinc-800">
            <div className="flex items-center gap-1">
              <button
                onClick={() => setSidebarTab('codes')}
                className={cn(
                  'px-3 py-1.5 text-xs rounded-lg transition-colors',
                  sidebarTab === 'codes' ? 'text-blue-400 bg-blue-500/10' : 'text-zinc-400 hover:text-zinc-200'
                )}
              >
                Codes
              </button>
              <button
                onClick={() => setSidebarTab('templates')}
                className={cn(
                  'px-3 py-1.5 text-xs rounded-lg transition-colors',
                  sidebarTab === 'templates' ? 'text-blue-400 bg-blue-500/10' : 'text-zinc-400 hover:text-zinc-200'
                )}
              >
                Templates
              </button>
            </div>
            <button onClick={() => setSidebarOpen(false)} className="p-1 text-zinc-500 hover:text-zinc-300">
              <X className="w-4 h-4" />
            </button>
          </div>

          {sidebarTab === 'codes' ? (
            <CodeBrowserPanel
              codes={codes}
              loading={codesLoading}
              categories={categories}
              selectedCategory={selectedCategory}
              onCategoryChange={setSelectedCategory}
              codeSearch={codeSearch}
              onSearch={handleCodeSearch}
              rooms={Array.from(roomGroups.keys())}
              newRoomName={newRoomName}
              onAddCode={handleAddCode}
            />
          ) : (
            <TemplateBrowserPanel
              templates={templates}
              loading={templatesLoading}
              onApply={handleApplyTemplate}
            />
          )}
        </div>
      )}
    </div>
  );
}

// ── Room Section Component ──

function RoomSection({
  room, lines, editingLine, onEdit, onUpdate, onDelete, onAddCode, onOpenBrowser,
}: {
  room: string;
  lines: EstimateLine[];
  editingLine: string | null;
  onEdit: (id: string | null) => void;
  onUpdate: (id: string, field: string, value: string | number) => void;
  onDelete: (id: string) => void;
  onAddCode: (code: XactimateCode) => void;
  onOpenBrowser: () => void;
}) {
  const [collapsed, setCollapsed] = useState(false);
  const roomTotal = lines.reduce((sum, l) => sum + l.total, 0);

  return (
    <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl overflow-hidden">
      {/* Room Header */}
      <button
        onClick={() => setCollapsed(!collapsed)}
        className="w-full flex items-center justify-between px-4 py-3 hover:bg-zinc-800/40 transition-colors"
      >
        <div className="flex items-center gap-2">
          {collapsed ? <ChevronRight className="w-4 h-4 text-zinc-500" /> : <ChevronDown className="w-4 h-4 text-zinc-500" />}
          <Home className="w-4 h-4 text-zinc-400" />
          <span className="text-sm font-medium text-zinc-200">{room}</span>
          <span className="text-xs text-zinc-500">{lines.length} items</span>
        </div>
        <span className="text-sm font-medium text-zinc-200">${fmt(roomTotal)}</span>
      </button>

      {!collapsed && (
        <div className="border-t border-zinc-700/30">
          {/* Column headers */}
          <div className="grid grid-cols-[1fr_60px_80px_80px_100px_36px] gap-2 px-4 py-2 text-[10px] uppercase tracking-wider text-zinc-600 border-b border-zinc-800/50">
            <span>Item</span>
            <span className="text-right">Qty</span>
            <span className="text-right">Unit Price</span>
            <span className="text-right">Total</span>
            <span className="text-center">Coverage</span>
            <span />
          </div>

          {/* Line items */}
          {lines.map((line) => (
            <LineItemRow
              key={line.id}
              line={line}
              isEditing={editingLine === line.id}
              onEdit={() => onEdit(editingLine === line.id ? null : line.id)}
              onUpdate={onUpdate}
              onDelete={() => onDelete(line.id)}
            />
          ))}

          {/* Add from browser */}
          <div className="px-4 py-2 border-t border-zinc-800/50">
            <button
              onClick={onOpenBrowser}
              className="flex items-center gap-1.5 text-xs text-zinc-500 hover:text-zinc-300"
            >
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
  line: EstimateLine;
  isEditing: boolean;
  onEdit: () => void;
  onUpdate: (id: string, field: string, value: string | number) => void;
  onDelete: () => void;
}) {
  return (
    <div className="group">
      <div
        className={cn(
          'grid grid-cols-[1fr_60px_80px_80px_100px_36px] gap-2 px-4 py-2.5 items-center transition-colors cursor-pointer',
          isEditing ? 'bg-zinc-800/60' : 'hover:bg-zinc-800/30'
        )}
        onClick={onEdit}
      >
        {/* Item info */}
        <div className="min-w-0">
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] font-mono text-zinc-500">{line.itemCode}</span>
          </div>
          <p className="text-xs text-zinc-300 truncate">{line.description}</p>
          {line.notes && <p className="text-[10px] text-zinc-600 truncate mt-0.5">{line.notes}</p>}
        </div>

        {/* Qty */}
        <div className="text-right">
          {isEditing ? (
            <input
              type="number"
              value={line.quantity}
              onChange={(e) => onUpdate(line.id, 'quantity', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()}
            />
          ) : (
            <span className="text-xs text-zinc-300">{line.quantity} {line.unit}</span>
          )}
        </div>

        {/* Unit price */}
        <div className="text-right">
          {isEditing ? (
            <input
              type="number"
              step="0.01"
              value={line.unitPrice}
              onChange={(e) => onUpdate(line.id, 'unitPrice', e.target.value)}
              className="w-full px-1 py-0.5 text-xs text-right bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()}
            />
          ) : (
            <span className="text-xs text-zinc-300">${fmt(line.unitPrice)}</span>
          )}
        </div>

        {/* Total */}
        <span className="text-xs text-right font-medium text-zinc-200">${fmt(line.total)}</span>

        {/* Coverage */}
        <div className="flex justify-center">
          {isEditing ? (
            <select
              value={line.coverageGroup}
              onChange={(e) => { onUpdate(line.id, 'coverageGroup', e.target.value); e.stopPropagation(); }}
              className="text-[10px] px-1 py-0.5 bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
              onClick={(e) => e.stopPropagation()}
            >
              {COVERAGE_GROUPS.map(g => (
                <option key={g.id} value={g.id}>{g.label}</option>
              ))}
            </select>
          ) : (
            <span className={cn('text-[10px] px-1.5 py-0.5 rounded border', COVERAGE_COLORS[line.coverageGroup])}>
              {line.coverageGroup}
            </span>
          )}
        </div>

        {/* Delete */}
        <div className="flex justify-center">
          <button
            onClick={(e) => { e.stopPropagation(); onDelete(); }}
            className="p-1 text-zinc-600 hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity"
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Expanded edit row */}
      {isEditing && (
        <div className="px-4 py-2 bg-zinc-800/40 border-t border-zinc-800/50 grid grid-cols-3 gap-3">
          {/* MAT / LAB / EQU breakdown */}
          <div className="flex items-center gap-2">
            <Package className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">MAT:</span>
            <span className="text-xs text-zinc-300">${fmt(line.materialCost)}</span>
          </div>
          <div className="flex items-center gap-2">
            <Wrench className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">LAB:</span>
            <span className="text-xs text-zinc-300">${fmt(line.laborCost)}</span>
          </div>
          <div className="flex items-center gap-2">
            <Zap className="w-3 h-3 text-zinc-500" />
            <span className="text-[10px] text-zinc-500">EQU:</span>
            <span className="text-xs text-zinc-300">${fmt(line.equipmentCost)}</span>
          </div>
          {/* Depreciation */}
          <div className="col-span-2 flex items-center gap-2">
            <span className="text-[10px] text-zinc-500">Depreciation %:</span>
            <input
              type="number"
              min="0"
              max="100"
              value={line.depreciationRate}
              onChange={(e) => onUpdate(line.id, 'depreciationRate', e.target.value)}
              className="w-16 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-600 rounded text-zinc-200"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-zinc-500">ACV:</span>
            <span className="text-xs text-zinc-300">${fmt(line.total * (1 - line.depreciationRate / 100))}</span>
          </div>
          {/* Notes */}
          <div className="col-span-3">
            <input
              type="text"
              value={line.notes}
              onChange={(e) => onUpdate(line.id, 'notes', e.target.value)}
              placeholder="Notes..."
              className="w-full px-2 py-1 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 placeholder:text-zinc-600"
            />
          </div>
        </div>
      )}
    </div>
  );
}

// ── Code Browser Panel ──

function CodeBrowserPanel({
  codes, loading, categories, selectedCategory, onCategoryChange,
  codeSearch, onSearch, rooms, newRoomName, onAddCode,
}: {
  codes: XactimateCode[];
  loading: boolean;
  categories: Array<{ code: string; name: string }>;
  selectedCategory: string;
  onCategoryChange: (c: string) => void;
  codeSearch: string;
  onSearch: (q: string) => void;
  rooms: string[];
  newRoomName: string;
  onAddCode: (code: XactimateCode, room: string) => void;
}) {
  const [addingToRoom, setAddingToRoom] = useState<{ codeId: string; room: string } | null>(null);
  const targetRooms = rooms.length > 0 ? rooms : [newRoomName || 'Main'];

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* Search */}
      <div className="p-3 space-y-2 border-b border-zinc-800">
        <div className="relative">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-zinc-500" />
          <input
            type="text"
            value={codeSearch}
            onChange={(e) => onSearch(e.target.value)}
            placeholder="Search codes or descriptions..."
            className="w-full pl-8 pr-3 py-1.5 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-xs text-zinc-100 placeholder:text-zinc-500"
          />
        </div>
        {/* Category filter */}
        <select
          value={selectedCategory}
          onChange={(e) => onCategoryChange(e.target.value)}
          className="w-full px-2 py-1.5 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-xs text-zinc-200"
        >
          <option value="">All categories</option>
          {categories.map(c => (
            <option key={c.code} value={c.code}>{c.code} — {c.name}</option>
          ))}
        </select>
      </div>

      {/* Code list */}
      <div className="flex-1 overflow-y-auto">
        {loading ? (
          <div className="p-4 space-y-2">
            {[1, 2, 3, 4, 5].map(i => (
              <div key={i} className="h-12 bg-zinc-800/50 rounded animate-pulse" />
            ))}
          </div>
        ) : codes.length === 0 ? (
          <div className="p-6 text-center text-zinc-500 text-xs">
            {codeSearch ? 'No codes found' : 'Search or select a category'}
          </div>
        ) : (
          <div className="divide-y divide-zinc-800/50">
            {codes.map(code => (
              <div key={code.id} className="px-3 py-2.5 hover:bg-zinc-800/30 transition-colors">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-1.5">
                      <span className="text-[10px] font-mono font-medium text-blue-400">{code.fullCode}</span>
                      <span className={cn('text-[10px] px-1 py-0.5 rounded border', COVERAGE_COLORS[code.coverageGroup])}>
                        {code.coverageGroup.charAt(0).toUpperCase()}
                      </span>
                    </div>
                    <p className="text-xs text-zinc-300 mt-0.5 line-clamp-2">{code.description}</p>
                    <div className="flex items-center gap-2 mt-1">
                      <span className="text-[10px] text-zinc-600">{code.unit}</span>
                      <div className="flex items-center gap-1">
                        {code.hasMaterial && <Package className="w-2.5 h-2.5 text-zinc-600" />}
                        {code.hasLabor && <Wrench className="w-2.5 h-2.5 text-zinc-600" />}
                        {code.hasEquipment && <Zap className="w-2.5 h-2.5 text-zinc-600" />}
                      </div>
                    </div>
                  </div>
                  {/* Add button with room picker */}
                  <div className="relative flex-shrink-0">
                    {addingToRoom?.codeId === code.id ? (
                      <div className="absolute right-0 top-0 bg-zinc-800 border border-zinc-700 rounded-lg shadow-xl p-1.5 min-w-[140px] z-10">
                        {targetRooms.map(room => (
                          <button
                            key={room}
                            onClick={() => { onAddCode(code, room); setAddingToRoom(null); }}
                            className="w-full text-left px-2 py-1.5 text-xs text-zinc-300 hover:bg-zinc-700 rounded"
                          >
                            {room}
                          </button>
                        ))}
                        <button
                          onClick={() => setAddingToRoom(null)}
                          className="w-full text-left px-2 py-1 text-[10px] text-zinc-500 hover:text-zinc-300 mt-1 border-t border-zinc-700 pt-1"
                        >
                          Cancel
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => {
                          if (targetRooms.length === 1) {
                            onAddCode(code, targetRooms[0]);
                          } else {
                            setAddingToRoom({ codeId: code.id, room: '' });
                          }
                        }}
                        className="p-1.5 text-zinc-500 hover:text-blue-400 hover:bg-blue-500/10 rounded-lg transition-colors"
                        title="Add to estimate"
                      >
                        <Plus className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Template Browser Panel ──

function TemplateBrowserPanel({
  templates, loading, onApply,
}: {
  templates: EstimateTemplate[];
  loading: boolean;
  onApply: (t: EstimateTemplate) => void;
}) {
  if (loading) {
    return (
      <div className="p-4 space-y-2">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-16 bg-zinc-800/50 rounded animate-pulse" />
        ))}
      </div>
    );
  }

  if (templates.length === 0) {
    return (
      <div className="p-6 text-center text-zinc-500 text-xs">
        <FileText className="w-8 h-8 mx-auto mb-2 opacity-50" />
        <p>No templates yet</p>
        <p className="mt-1 text-zinc-600">Save your first estimate as a template</p>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto divide-y divide-zinc-800/50">
      {templates.map(template => (
        <div key={template.id} className="px-3 py-3 hover:bg-zinc-800/30 transition-colors">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <p className="text-xs font-medium text-zinc-200">{template.name}</p>
              {template.description && <p className="text-[10px] text-zinc-500 mt-0.5">{template.description}</p>}
              <div className="flex items-center gap-2 mt-1">
                <span className="text-[10px] text-zinc-600">{template.lineItems.length} items</span>
                {template.lossType && (
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-zinc-800 text-zinc-400">{template.lossType.replace(/_/g, ' ')}</span>
                )}
                {template.isSystem && (
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400">System</span>
                )}
              </div>
            </div>
            <button
              onClick={() => onApply(template)}
              className="flex items-center gap-1 px-2 py-1 text-[10px] text-blue-400 bg-blue-500/10 border border-blue-500/20 rounded hover:bg-blue-500/20 flex-shrink-0"
            >
              <Copy className="w-3 h-3" />
              Apply
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Summary Panel ──

function SummaryPanel({
  summary, overheadRate, profitRate, onOverheadChange, onProfitChange, lineCount,
}: {
  summary: EstimateSummary;
  overheadRate: number;
  profitRate: number;
  onOverheadChange: (r: number) => void;
  onProfitChange: (r: number) => void;
  lineCount: number;
}) {
  return (
    <div className="bg-zinc-800/30 border border-zinc-700/30 rounded-xl p-5">
      <h3 className="text-sm font-medium text-zinc-200 mb-4 flex items-center gap-2">
        <Layers className="w-4 h-4 text-zinc-400" />
        Estimate Summary
        <span className="text-xs text-zinc-500 font-normal ml-auto">{lineCount} line items</span>
      </h3>

      {/* Coverage group breakdown */}
      <div className="space-y-3 mb-5">
        {COVERAGE_GROUPS.map(group => {
          const data = summary[group.id];
          if (data.rcv === 0) return null;
          return (
            <div key={group.id} className="grid grid-cols-4 gap-4 text-xs">
              <div className="flex items-center gap-2">
                <span className={cn('px-1.5 py-0.5 rounded border text-[10px]', COVERAGE_COLORS[group.id])}>
                  {group.label}
                </span>
              </div>
              <div className="text-right">
                <span className="text-zinc-500 text-[10px] block">RCV</span>
                <span className="text-zinc-200 font-medium">${fmt(data.rcv)}</span>
              </div>
              <div className="text-right">
                <span className="text-zinc-500 text-[10px] block">Depreciation</span>
                <span className="text-red-400">(${fmt(data.depreciation)})</span>
              </div>
              <div className="text-right">
                <span className="text-zinc-500 text-[10px] block">ACV</span>
                <span className="text-zinc-200 font-medium">${fmt(data.acv)}</span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Subtotal + O&P */}
      <div className="border-t border-zinc-700/50 pt-4 space-y-2.5">
        <div className="flex items-center justify-between text-xs">
          <span className="text-zinc-400">Subtotal (RCV)</span>
          <span className="text-zinc-200 font-medium">${fmt(summary.subtotal)}</span>
        </div>

        {/* Overhead */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-zinc-400">Overhead</span>
            <input
              type="number"
              min="0"
              max="100"
              value={overheadRate}
              onChange={(e) => onOverheadChange(Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 text-right"
            />
            <span className="text-zinc-600">%</span>
          </div>
          <span className="text-zinc-200">${fmt(summary.overhead)}</span>
        </div>

        {/* Profit */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            <span className="text-zinc-400">Profit</span>
            <input
              type="number"
              min="0"
              max="100"
              value={profitRate}
              onChange={(e) => onProfitChange(Number(e.target.value) || 0)}
              className="w-14 px-1.5 py-0.5 text-xs bg-zinc-800 border border-zinc-700 rounded text-zinc-200 text-right"
            />
            <span className="text-zinc-600">%</span>
          </div>
          <span className="text-zinc-200">${fmt(summary.profit)}</span>
        </div>

        {/* Grand Total */}
        <div className="flex items-center justify-between text-sm pt-2.5 border-t border-zinc-700/50">
          <span className="text-zinc-100 font-semibold">Grand Total</span>
          <span className="text-zinc-100 font-semibold text-lg">${fmt(summary.grandTotal)}</span>
        </div>
      </div>
    </div>
  );
}
