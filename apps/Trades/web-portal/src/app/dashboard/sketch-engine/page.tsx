'use client';

// ZAFTO Sketch Engine — SK8 Canvas Editor + Listing
// Full Konva.js canvas editor backed by property_floor_plans table.
// SK7: History panel, multi-floor tabs, photo pin integration.
// SK8: Generate Estimate modal (room measurements → D8 estimate areas + line items).

import { useState, useCallback, useRef, useEffect, type RefObject } from 'react';
import { createPortal } from 'react-dom';
import dynamic from 'next/dynamic';
import {
  Plus,
  PenTool,
  Loader2,
  ArrowLeft,
  Save,
  Ruler as RulerIcon,
  History,
  Camera,
  Calculator,
  Download,
  LayoutTemplate,
  Layers,
  Box,
  RefreshCw,
  Map,
  Maximize2,
  Grid3X3,
  ChevronRight,
  Clock,
  MoreHorizontal,
  FolderOpen,
  Sparkles,
  Activity,
  Trash2,
  Copy,
  Link,
  Pencil,
  MousePointer,
} from 'lucide-react';
import type Konva from 'konva';
import {
  useFloorPlan,
  useFloorPlanList,
  type FloorPlanListItem,
} from '@/lib/hooks/use-floor-plan';
import { useFloorPlanSnapshots } from '@/lib/hooks/use-floor-plan-snapshots';
import { useFloorPlanPhotoPins } from '@/lib/hooks/use-floor-plan-photo-pins';
import {
  createEmptyFloorPlan,
  createEmptySelection,
  createDefaultEditorState,
  createEmptySitePlan,
  createDefaultSiteEditorState,
} from '@/lib/sketch-engine/types';
import type {
  FloorPlanData,
  SelectionState,
  EditorState,
  SketchTool,
  TradeLayerType,
  TradeLayer,
  Point,
  SitePlanData,
  SiteEditorState,
  SitePlanTool,
  SiteSymbolType,
} from '@/lib/sketch-engine/types';
import {
  UndoRedoManager,
  RemoveAnyElementCommand,
} from '@/lib/sketch-engine/commands';
import { formatDate } from '@/lib/utils';
import { useDraftRecovery } from '@/lib/hooks/use-draft-recovery';
import type { ContextMenuEvent } from '@/components/sketch-editor/SketchCanvas';

// Dynamic import for Konva (SSR incompatible)
const SketchCanvas = dynamic(
  () => import('@/components/sketch-editor/SketchCanvas'),
  { ssr: false, loading: () => <CanvasLoadingPlaceholder /> },
);
import Toolbar from '@/components/sketch-editor/Toolbar';
import LayerPanel from '@/components/sketch-editor/LayerPanel';
import TradeSymbolPalette from '@/components/sketch-editor/TradeSymbolPalette';
import PropertyInspector from '@/components/sketch-editor/PropertyInspector';
import MiniMap from '@/components/sketch-editor/MiniMap';
import HistoryPanel from '@/components/sketch-editor/HistoryPanel';
import GenerateEstimateModal from '@/components/sketch-editor/GenerateEstimateModal';
import ExportModal from '@/components/sketch-editor/ExportModal';
import ViewToggle from '@/components/sketch-editor/ViewToggle';
import PlanModeToggle, { type PlanMode } from '@/components/sketch-editor/PlanModeToggle';
import SitePlanToolbar from '@/components/sketch-editor/SitePlanToolbar';
import SitePlanLayerPanel from '@/components/sketch-editor/SitePlanLayerPanel';
import SitePropertyInspector from '@/components/sketch-editor/SitePropertyInspector';
import SiteBackgroundImport from '@/components/sketch-editor/SiteBackgroundImport';
import PropertyLookupPanel from '@/components/sketch-editor/PropertyLookupPanel';
import TemplatePicker from '@/components/sketch-editor/TemplatePicker';
import {
  applyFloorPlanTemplate,
  applySitePlanTemplate,
  type SketchTemplate,
} from '@/lib/sketch-engine/templates';

// Dynamic import for Three.js (SSR incompatible, heavy bundle)
const ThreeDView = dynamic(
  () => import('@/components/sketch-editor/ThreeDView'),
  { ssr: false, loading: () => <CanvasLoadingPlaceholder /> },
);
// Dynamic import for Site Plan Canvas (Konva, SSR incompatible)
const SitePlanCanvas = dynamic(
  () => import('@/components/sketch-editor/SitePlanCanvas'),
  { ssr: false, loading: () => <CanvasLoadingPlaceholder /> },
);
import {
  HorizontalRuler,
  VerticalRuler,
  RulerCorner,
  RULER_THICKNESS,
} from '@/components/sketch-editor/Ruler';

function CanvasLoadingPlaceholder() {
  return (
    <div className="flex-1 flex items-center justify-center bg-gray-50">
      <div className="text-center">
        <Loader2 className="h-6 w-6 animate-spin text-gray-400 mx-auto" />
        <p className="text-xs text-gray-400 mt-2">Loading canvas...</p>
      </div>
    </div>
  );
}

// =============================================================================
// STATUS CONFIG
// =============================================================================

const statusConfig: Record<
  string,
  { label: string; color: string; bgColor: string }
> = {
  draft: {
    label: 'Draft',
    color: 'text-zinc-400',
    bgColor: 'bg-zinc-800',
  },
  in_progress: {
    label: 'In Progress',
    color: 'text-amber-400',
    bgColor: 'bg-amber-900/30',
  },
  completed: {
    label: 'Completed',
    color: 'text-emerald-400',
    bgColor: 'bg-emerald-900/30',
  },
  submitted: {
    label: 'Submitted',
    color: 'text-blue-400',
    bgColor: 'bg-blue-900/30',
  },
};

const SK_FEATURES = [
  { icon: PenTool, label: 'Draw Tools', detail: 'Walls, doors, windows, rooms', color: '#10B981' },
  { icon: RulerIcon, label: 'Measurements', detail: 'Live sqft & perimeter', color: '#3B82F6' },
  { icon: Layers, label: 'Trade Layers', detail: '18 trade overlays', color: '#8B5CF6' },
  { icon: Box, label: '3D Preview', detail: 'Instant walkthrough', color: '#F59E0B' },
  { icon: Camera, label: 'Photo Pins', detail: 'Geolocated photos', color: '#EC4899' },
  { icon: Map, label: 'Site Plans', detail: 'Structures & landscaping', color: '#14B8A6' },
  { icon: LayoutTemplate, label: 'Templates', detail: 'Pre-built layouts', color: '#D97706' },
  { icon: Calculator, label: 'Auto Estimates', detail: 'Room → line items', color: '#06B6D4' },
  { icon: Maximize2, label: 'Rulers & Grid', detail: 'Imperial or metric', color: '#6366F1' },
  { icon: History, label: 'Version History', detail: 'Named snapshots', color: '#F43F5E' },
  { icon: Grid3X3, label: 'Multi-Floor', detail: 'Floor tabs', color: '#84CC16' },
  { icon: Download, label: 'Export', detail: 'PDF, PNG, JSON', color: '#0EA5E9' },
];

// =============================================================================
// MAIN PAGE
// =============================================================================

export default function SketchEnginePage() {
  const [activeView, setActiveView] = useState<'list' | 'editor'>('list');
  const [activePlanId, setActivePlanId] = useState<string | null>(null);
  const [portalTarget, setPortalTarget] = useState<HTMLElement | null>(null);

  // Resolve portal target on mount (document.body)
  useEffect(() => {
    setPortalTarget(document.body);
  }, []);

  const openEditor = (planId: string) => {
    setActivePlanId(planId);
    setActiveView('editor');
  };

  const closeEditor = () => {
    setActiveView('list');
    setActivePlanId(null);
  };

  // Render editor via portal to escape dashboard layout CSS containment
  if (activeView === 'editor' && activePlanId && portalTarget) {
    return createPortal(
      <EditorView planId={activePlanId} onClose={closeEditor} />,
      portalTarget,
    );
  }

  return <ListView onOpenEditor={openEditor} />;
}

// =============================================================================
// LIST VIEW — Reads from property_floor_plans
// =============================================================================

function ListView({
  onOpenEditor,
}: {
  onOpenEditor: (planId: string) => void;
}) {
  const { plans, loading, error, refetch } = useFloorPlanList();
  const { createPlan, deletePlan, duplicatePlan } = useFloorPlan(null);
  const [creating, setCreating] = useState(false);
  const [showCapabilities, setShowCapabilities] = useState(false);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [menuOpenId, setMenuOpenId] = useState<string | null>(null);

  const handleCreate = async () => {
    setCreating(true);
    try {
      const planId = await createPlan({ name: 'New Floor Plan' });
      if (planId) {
        onOpenEditor(planId);
      }
    } finally {
      setCreating(false);
    }
  };

  const handleDelete = async (id: string) => {
    const success = await deletePlan(id);
    if (success) {
      setDeleteConfirmId(null);
      refetch();
    }
  };

  const handleDuplicate = async (id: string) => {
    setMenuOpenId(null);
    const newId = await duplicatePlan(id);
    if (newId) {
      refetch();
    }
  };

  const totalWalls = plans.reduce((sum, p) => sum + p.wallCount, 0);
  const totalRooms = plans.reduce((sum, p) => sum + p.roomCount, 0);
  const inProgress = plans.filter((p) => p.status === 'in_progress').length;

  return (
    <div className="space-y-6 max-w-[1400px] mx-auto">
      {/* ── Hero Header ── */}
      <div className="relative overflow-hidden rounded-2xl border border-[var(--border)] bg-gradient-to-br from-[#0c1f1a] via-[#0f1a24] to-[#111318]">
        {/* Mesh gradient orbs */}
        <div className="absolute -top-24 -right-24 w-64 h-64 rounded-full bg-emerald-500/[0.07] blur-3xl" />
        <div className="absolute -bottom-16 left-1/4 w-48 h-48 rounded-full bg-blue-500/[0.05] blur-3xl" />
        <div className="absolute top-1/2 right-1/3 w-32 h-32 rounded-full bg-purple-500/[0.04] blur-2xl" />

        <div className="relative z-10 p-8">
          <div className="flex items-start justify-between gap-6">
            <div className="flex items-start gap-4">
              <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center flex-shrink-0">
                <PenTool size={22} className="text-emerald-400" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-white tracking-tight">Sketch Engine</h1>
                <p className="text-sm text-zinc-400 mt-1 max-w-lg">
                  Professional floor plans, trade layer overlays, 3D visualization, and auto-generated estimates — all in one canvas.
                </p>
              </div>
            </div>

            <button
              onClick={handleCreate}
              disabled={creating}
              className="flex items-center gap-2 px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-semibold rounded-xl transition-all shadow-lg shadow-emerald-900/30 hover:shadow-emerald-800/40 disabled:opacity-50 flex-shrink-0"
            >
              {creating ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Plus className="h-4 w-4" />
              )}
              New Floor Plan
            </button>
          </div>

          {/* Quick stats */}
          {plans.length > 0 && (
            <div className="flex items-center gap-6 mt-6 pt-5 border-t border-white/[0.06]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center">
                  <FolderOpen size={14} className="text-zinc-400" />
                </div>
                <div>
                  <p className="text-lg font-bold text-white leading-none">{plans.length}</p>
                  <p className="text-[11px] text-zinc-500 mt-0.5">Floor Plans</p>
                </div>
              </div>
              <div className="w-px h-8 bg-white/[0.06]" />
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center">
                  <RulerIcon size={14} className="text-zinc-400" />
                </div>
                <div>
                  <p className="text-lg font-bold text-white leading-none">{totalWalls}</p>
                  <p className="text-[11px] text-zinc-500 mt-0.5">Total Walls</p>
                </div>
              </div>
              <div className="w-px h-8 bg-white/[0.06]" />
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center">
                  <Grid3X3 size={14} className="text-zinc-400" />
                </div>
                <div>
                  <p className="text-lg font-bold text-white leading-none">{totalRooms}</p>
                  <p className="text-[11px] text-zinc-500 mt-0.5">Total Rooms</p>
                </div>
              </div>
              {inProgress > 0 && (
                <>
                  <div className="w-px h-8 bg-white/[0.06]" />
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center">
                      <Activity size={14} className="text-amber-400" />
                    </div>
                    <div>
                      <p className="text-lg font-bold text-amber-400 leading-none">{inProgress}</p>
                      <p className="text-[11px] text-zinc-500 mt-0.5">In Progress</p>
                    </div>
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Error Banner */}
      {error && (
        <div className="flex items-center justify-between bg-red-900/15 border border-red-500/20 rounded-xl px-4 py-3">
          <p className="text-sm text-red-400">{error}</p>
          <button
            onClick={refetch}
            className="flex items-center gap-1.5 text-xs font-medium text-red-400 hover:text-red-300 transition-colors"
          >
            <RefreshCw size={12} />
            Retry
          </button>
        </div>
      )}

      {/* ── Capabilities Strip (collapsible) ── */}
      <div className="rounded-xl border border-[var(--border)] bg-[var(--bg-secondary)] overflow-hidden">
        <button
          onClick={() => setShowCapabilities(!showCapabilities)}
          className="w-full flex items-center justify-between px-5 py-3 hover:bg-white/[0.02] transition-colors"
        >
          <div className="flex items-center gap-2.5">
            <Sparkles size={14} className="text-emerald-400" />
            <span className="text-xs font-semibold text-zinc-300 uppercase tracking-wider">Engine Capabilities</span>
            <span className="text-[10px] text-zinc-500 bg-zinc-800 px-2 py-0.5 rounded-full">{SK_FEATURES.length} tools</span>
          </div>
          <ChevronRight
            size={14}
            className={`text-zinc-500 transition-transform duration-200 ${showCapabilities ? 'rotate-90' : ''}`}
          />
        </button>

        {showCapabilities && (
          <div className="px-5 pb-4 pt-1">
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-2">
              {SK_FEATURES.map((feat) => {
                const Icon = feat.icon;
                return (
                  <div
                    key={feat.label}
                    className="flex items-center gap-2.5 px-3 py-2.5 rounded-lg bg-white/[0.02] border border-white/[0.04] hover:border-white/[0.08] transition-colors group"
                  >
                    <div
                      className="w-7 h-7 rounded-md flex items-center justify-center flex-shrink-0"
                      style={{ backgroundColor: `${feat.color}15` }}
                    >
                      <Icon size={14} style={{ color: feat.color }} />
                    </div>
                    <div className="min-w-0">
                      <p className="text-[11px] font-semibold text-zinc-200 leading-tight truncate">{feat.label}</p>
                      <p className="text-[10px] text-zinc-500 leading-tight truncate">{feat.detail}</p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* ── Loading ── */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="flex items-center gap-3">
            <Loader2 className="h-5 w-5 animate-spin text-emerald-400" />
            <span className="text-sm text-zinc-400">Loading floor plans...</span>
          </div>
        </div>
      )}

      {/* ── Floor Plans Grid ── */}
      {!loading && plans.length > 0 && (
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-semibold text-zinc-300 uppercase tracking-wider">
              Your Floor Plans
            </h2>
            <span className="text-xs text-zinc-500">{plans.length} plan{plans.length !== 1 ? 's' : ''}</span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {plans.map((plan) => (
              <PlanCard
                key={plan.id}
                plan={plan}
                onOpen={() => onOpenEditor(plan.id)}
                menuOpen={menuOpenId === plan.id}
                onMenuToggle={() => setMenuOpenId(menuOpenId === plan.id ? null : plan.id)}
                onMenuClose={() => setMenuOpenId(null)}
                onDelete={() => setDeleteConfirmId(plan.id)}
                onDuplicate={() => handleDuplicate(plan.id)}
              />
            ))}

            {/* Create new card */}
            <button
              onClick={handleCreate}
              disabled={creating}
              className="group rounded-xl border-2 border-dashed border-zinc-800 hover:border-emerald-500/30 bg-transparent hover:bg-emerald-500/[0.03] transition-all flex flex-col items-center justify-center py-12 min-h-[180px] disabled:opacity-50"
            >
              <div className="w-12 h-12 rounded-xl bg-zinc-800/60 group-hover:bg-emerald-500/10 flex items-center justify-center transition-colors mb-3">
                {creating ? (
                  <Loader2 size={20} className="text-zinc-400 animate-spin" />
                ) : (
                  <Plus size={20} className="text-zinc-500 group-hover:text-emerald-400 transition-colors" />
                )}
              </div>
              <p className="text-sm font-medium text-zinc-500 group-hover:text-zinc-300 transition-colors">New Floor Plan</p>
            </button>
          </div>
        </div>
      )}

      {/* ── Empty State ── */}
      {!loading && !error && plans.length === 0 && (
        <div className="rounded-2xl border border-[var(--border)] bg-gradient-to-b from-[var(--bg-secondary)] to-transparent p-12">
          <div className="max-w-md mx-auto text-center">
            <div className="w-16 h-16 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center mx-auto mb-5">
              <PenTool size={28} className="text-emerald-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Create Your First Floor Plan</h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-6">
              Draw walls, place doors and windows, define rooms with auto-measurements,
              add trade layers, and generate estimates — all from one canvas.
            </p>
            <div className="flex items-center justify-center gap-3">
              <button
                onClick={handleCreate}
                disabled={creating}
                className="flex items-center gap-2 px-6 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-semibold rounded-xl transition-all shadow-lg shadow-emerald-900/30 disabled:opacity-50"
              >
                {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                Start Drawing
              </button>
            </div>

            {/* Mini feature highlights */}
            <div className="flex items-center justify-center gap-4 mt-8 pt-6 border-t border-white/[0.06]">
              {[
                { icon: Layers, label: '18 Trade Layers' },
                { icon: Box, label: '3D Preview' },
                { icon: Calculator, label: 'Auto Estimates' },
              ].map((f) => (
                <div key={f.label} className="flex items-center gap-1.5 text-[11px] text-zinc-500">
                  <f.icon size={12} className="text-zinc-600" />
                  {f.label}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deleteConfirmId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
          <div className="bg-[#1a1a2e] border border-[#2a2a4a] rounded-xl p-6 max-w-sm w-full mx-4 shadow-2xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-red-500/10 flex items-center justify-center">
                <Trash2 size={18} className="text-red-400" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white">Delete Floor Plan</h3>
                <p className="text-xs text-zinc-400">This action cannot be undone.</p>
              </div>
            </div>
            <p className="text-sm text-zinc-300 mb-6">
              Are you sure you want to delete &ldquo;{plans.find(p => p.id === deleteConfirmId)?.name || 'this plan'}&rdquo;?
            </p>
            <div className="flex items-center gap-3 justify-end">
              <button
                onClick={() => setDeleteConfirmId(null)}
                className="px-4 py-2 text-sm font-medium text-zinc-400 hover:text-zinc-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDelete(deleteConfirmId)}
                className="px-4 py-2 text-sm font-semibold text-white bg-red-600 hover:bg-red-500 rounded-lg transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function PlanCard({
  plan,
  onOpen,
  menuOpen,
  onMenuToggle,
  onMenuClose,
  onDelete,
  onDuplicate,
}: {
  plan: FloorPlanListItem;
  onOpen: () => void;
  menuOpen: boolean;
  onMenuToggle: () => void;
  onMenuClose: () => void;
  onDelete: () => void;
  onDuplicate: () => void;
}) {
  const status = statusConfig[plan.status] || statusConfig.draft;

  return (
    <div
      onClick={onOpen}
      className="group rounded-xl border border-[var(--border)] bg-[var(--bg-secondary)] hover:border-emerald-500/30 transition-all cursor-pointer overflow-hidden"
    >
      {/* Plan preview area */}
      <div className="relative h-32 bg-gradient-to-br from-zinc-900 to-zinc-800/50 border-b border-[var(--border)] flex items-center justify-center overflow-hidden">
        {/* Grid pattern */}
        <div
          className="absolute inset-0 opacity-[0.05]"
          style={{
            backgroundImage: 'linear-gradient(rgba(255,255,255,.3) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.3) 1px, transparent 1px)',
            backgroundSize: '20px 20px',
          }}
        />
        {/* Floor plan icon */}
        <div className="relative flex items-center gap-3 text-zinc-600">
          <PenTool size={28} className="opacity-30" />
          <div className="text-left">
            <p className="text-xs font-medium text-zinc-500">
              {plan.wallCount}W / {plan.roomCount}R
            </p>
            <p className="text-[10px] text-zinc-600">Floor {plan.floorLevel}</p>
          </div>
        </div>

        {/* Status pill — top right */}
        <div className={`absolute top-2.5 right-2.5 flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${status.bgColor} ${status.color}`}>
          <span className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: 'currentColor' }} />
          {status.label}
        </div>

        {/* Hover overlay */}
        <div className="absolute inset-0 bg-emerald-500/0 group-hover:bg-emerald-500/[0.04] transition-colors flex items-center justify-center">
          <div className="opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1.5 px-3 py-1.5 bg-white/10 backdrop-blur rounded-lg text-xs font-medium text-white">
            Open Editor
            <ChevronRight size={12} />
          </div>
        </div>
      </div>

      {/* Plan details */}
      <div className="px-4 py-3">
        <div className="flex items-start justify-between gap-2">
          <h3 className="text-sm font-semibold text-zinc-100 truncate group-hover:text-emerald-300 transition-colors">
            {plan.name}
          </h3>
          <div className="relative flex-shrink-0">
            <button
              onClick={(e) => { e.stopPropagation(); onMenuToggle(); }}
              className="p-1 rounded-md text-zinc-600 hover:text-zinc-400 hover:bg-zinc-800 transition-colors opacity-0 group-hover:opacity-100"
            >
              <MoreHorizontal size={14} />
            </button>
            {menuOpen && (
              <>
                <div className="fixed inset-0 z-40" onClick={(e) => { e.stopPropagation(); onMenuClose(); }} />
                <div className="absolute right-0 top-full mt-1 z-50 w-40 bg-[#1a1a2e] border border-[#2a2a4a] rounded-lg shadow-2xl py-1 overflow-hidden">
                  <button
                    onClick={(e) => { e.stopPropagation(); onMenuClose(); onOpen(); }}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs text-zinc-300 hover:bg-white/[0.06] transition-colors"
                  >
                    <Pencil size={12} />
                    Open Editor
                  </button>
                  <button
                    onClick={(e) => { e.stopPropagation(); onDuplicate(); }}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs text-zinc-300 hover:bg-white/[0.06] transition-colors"
                  >
                    <Copy size={12} />
                    Duplicate
                  </button>
                  <div className="mx-2 my-1 h-px bg-[#2a2a4a]" />
                  <button
                    onClick={(e) => { e.stopPropagation(); onMenuClose(); onDelete(); }}
                    className="w-full flex items-center gap-2 px-3 py-2 text-xs text-red-400 hover:bg-red-500/10 transition-colors"
                  >
                    <Trash2 size={12} />
                    Delete
                  </button>
                </div>
              </>
            )}
          </div>
        </div>

        <div className="flex items-center gap-3 mt-2 text-[11px] text-zinc-500">
          <span className="flex items-center gap-1">
            <RulerIcon size={10} />
            {plan.wallCount} walls
          </span>
          <span className="flex items-center gap-1">
            <Grid3X3 size={10} />
            {plan.roomCount} rooms
          </span>
          {plan.jobId && (
            <span className="flex items-center gap-1 text-emerald-500/70">
              <Link size={10} />
              Linked
            </span>
          )}
          <span className="flex items-center gap-1 ml-auto">
            <Clock size={10} />
            {formatDate(plan.updatedAt)}
          </span>
        </div>
      </div>
    </div>
  );
}

// =============================================================================
// EDITOR VIEW — Full canvas editor backed by property_floor_plans
// =============================================================================

function EditorView({
  planId,
  onClose,
}: {
  planId: string;
  onClose: () => void;
}) {
  const { plan, loading, error, saving, savePlanData } =
    useFloorPlan(planId);

  // SK7: Snapshots
  const {
    snapshots,
    loading: snapshotsLoading,
    createSnapshot,
    restoreSnapshot,
    deleteSnapshot,
  } = useFloorPlanSnapshots(planId);

  // SK7: Photo pins
  const {
    pins: photoPins,
    createPin,
    uploadPhotoToPin,
    getPhotoUrl,
  } = useFloorPlanPhotoPins(planId);

  const [planData, setPlanData] = useState<FloorPlanData>(
    createEmptyFloorPlan(),
  );
  const [selection, setSelection] = useState<SelectionState>(
    createEmptySelection(),
  );
  const [editorState, setEditorState] = useState<EditorState>(
    createDefaultEditorState(),
  );
  const [showLayers, setShowLayers] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [pinMode, setPinMode] = useState(false);
  const [showEstimateModal, setShowEstimateModal] = useState(false);
  const [showExportModal, setShowExportModal] = useState(false);
  const [is3DView, setIs3DView] = useState(false);
  const [planMode, setPlanMode] = useState<PlanMode>('floor');
  const [sitePlanData, setSitePlanData] = useState<SitePlanData>(createEmptySitePlan());
  const [siteEditorState, setSiteEditorState] = useState<SiteEditorState>(createDefaultSiteEditorState());
  const [siteSelectedId, setSiteSelectedId] = useState<string | null>(null);
  const [siteSelectedType, setSiteSelectedType] = useState<string | null>(null);
  const [showSiteLayers, setShowSiteLayers] = useState(false);
  const [showTemplatePicker, setShowTemplatePicker] = useState(false);
  const [reconScanId, setReconScanId] = useState<string | null>(null);
  const [contextMenu, setContextMenu] = useState<ContextMenuEvent | null>(null);
  const [canvasSize, setCanvasSize] = useState({ width: 800, height: 600 });

  const undoManagerRef = useRef(new UndoRedoManager());
  const containerRef = useRef<HTMLDivElement>(null);
  const stageRef = useRef<Konva.Stage>(null) as RefObject<Konva.Stage | null>;

  // DEPTH27: Draft recovery — auto-save sketch state every 3s locally, 60s to cloud
  const draftRecovery = useDraftRecovery({
    feature: 'sketch',
    key: planId,
    screenRoute: `/dashboard/sketch-engine?plan=${planId}`,
  });

  // Restore draft on mount (only if no server data loaded yet)
  const draftRestoredRef = useRef(false);
  useEffect(() => {
    if (draftRestoredRef.current) return;
    if (draftRecovery.hasDraft && !draftRecovery.checking && !loading && !plan?.planData) {
      const r = draftRecovery.restoreDraft() as Record<string, unknown> | null;
      if (r?.planData) {
        setPlanData(r.planData as typeof planData);
        if (r.sitePlanData) setSitePlanData(r.sitePlanData as typeof sitePlanData);
        if (r.planMode) setPlanMode(r.planMode as typeof planMode);
      }
      draftRecovery.markRecovered();
      draftRestoredRef.current = true;
    }
  }, [draftRecovery.hasDraft, draftRecovery.checking, loading]); // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-save on planData or sitePlanData changes
  useEffect(() => {
    if (!loading && planData) {
      draftRecovery.saveDraft({ planData, sitePlanData, editorState, planMode });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [planData, sitePlanData, planMode]);

  // Load plan data when fetched (with validation for corrupt data)
  useEffect(() => {
    if (plan?.planData) {
      try {
        const d = plan.planData;
        if (d && Array.isArray(d.walls) && Array.isArray(d.rooms)) {
          setPlanData(d);
        } else {
          console.error('[SketchEngine] Invalid plan data structure, using empty plan');
          setPlanData(createEmptyFloorPlan());
        }
      } catch {
        console.error('[SketchEngine] Failed to load plan data, using empty plan');
        setPlanData(createEmptyFloorPlan());
      }
    }
  }, [plan]);

  // Track container size — compute from window since editor is a full-screen overlay.
  // Top bar = 48px (h-12), ruler = 22px (RULER_THICKNESS), vertical ruler = 22px.
  useEffect(() => {
    const updateSize = () => {
      // Primary: measure from container if available and has real dimensions
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        if (rect.width > 100 && rect.height > 100) {
          setCanvasSize({ width: rect.width, height: rect.height });
          return;
        }
      }
      // Fallback: compute from window (full-screen overlay layout)
      setCanvasSize({
        width: Math.max(window.innerWidth - RULER_THICKNESS, 400),
        height: Math.max(window.innerHeight - 48 - RULER_THICKNESS, 300),
      });
    };

    updateSize();
    // Re-measure after a frame to catch portal layout completion
    const raf = requestAnimationFrame(updateSize);
    window.addEventListener('resize', updateSize);

    // ResizeObserver for robust tracking
    let observer: ResizeObserver | null = null;
    if (containerRef.current) {
      observer = new ResizeObserver(updateSize);
      observer.observe(containerRef.current);
    }

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener('resize', updateSize);
      observer?.disconnect();
    };
  }, []);

  // Save on plan data change
  const handlePlanDataChange = useCallback(
    (data: FloorPlanData) => {
      setPlanData(data);
      savePlanData(data);
    },
    [savePlanData],
  );

  const handleEditorStateChange = useCallback(
    (updates: Partial<EditorState>) => {
      setEditorState((prev) => ({ ...prev, ...updates }));
    },
    [],
  );

  const handleToolChange = useCallback((tool: SketchTool) => {
    setEditorState((prev) => ({ ...prev, activeTool: tool }));
    setSelection(createEmptySelection());
    setPinMode(false);
  }, []);

  const handleUndo = useCallback(() => {
    const result = undoManagerRef.current.undo(planData);
    handlePlanDataChange(result);
  }, [planData, handlePlanDataChange]);

  const handleRedo = useCallback(() => {
    const result = undoManagerRef.current.redo(planData);
    handlePlanDataChange(result);
  }, [planData, handlePlanDataChange]);

  // MiniMap navigation — pan viewport to clicked point
  const handleMiniMapNavigate = useCallback(
    (point: Point) => {
      const newPanOffset = {
        x: -(point.x * editorState.zoom - canvasSize.width / 2),
        y: -(point.y * editorState.zoom - canvasSize.height / 2),
      };
      handleEditorStateChange({ panOffset: newPanOffset });
    },
    [editorState.zoom, canvasSize, handleEditorStateChange],
  );

  // SK7: Handle snapshot restore — updates local planData
  const handleRestoreSnapshot = useCallback(
    async (snapshot: Parameters<typeof restoreSnapshot>[0]) => {
      const restored = await restoreSnapshot(snapshot);
      if (restored) {
        setPlanData(restored);
      }
      return restored;
    },
    [restoreSnapshot],
  );

  // SK7: Photo pin placement via canvas click
  const handleCanvasClickForPin = useCallback(
    async (canvasX: number, canvasY: number) => {
      if (!pinMode) return;
      await createPin({
        positionX: canvasX,
        positionY: canvasY,
        pinType: 'photo',
      });
      setPinMode(false);
    },
    [pinMode, createPin],
  );

  // Layer management
  const handleAddLayer = useCallback(
    (type: TradeLayerType) => {
      const layer: TradeLayer = {
        id: `layer_${Date.now()}`,
        type,
        name: `${type.charAt(0).toUpperCase() + type.slice(1)} Layer`,
        visible: true,
        locked: false,
        opacity: 1.0,
        tradeData:
          type !== 'damage'
            ? { elements: [], paths: [] }
            : undefined,
        damageData:
          type === 'damage'
            ? {
                zones: [],
                moistureReadings: [],
                containmentLines: [],
                barriers: [],
              }
            : undefined,
      };
      handlePlanDataChange({
        ...planData,
        tradeLayers: [...planData.tradeLayers, layer],
      });
    },
    [planData, handlePlanDataChange],
  );

  const handleToggleVisibility = useCallback(
    (layerId: string) => {
      handlePlanDataChange({
        ...planData,
        tradeLayers: planData.tradeLayers.map((l) =>
          l.id === layerId ? { ...l, visible: !l.visible } : l,
        ),
      });
    },
    [planData, handlePlanDataChange],
  );

  const handleToggleLock = useCallback(
    (layerId: string) => {
      handlePlanDataChange({
        ...planData,
        tradeLayers: planData.tradeLayers.map((l) =>
          l.id === layerId ? { ...l, locked: !l.locked } : l,
        ),
      });
    },
    [planData, handlePlanDataChange],
  );

  const handleOpacityChange = useCallback(
    (layerId: string, opacity: number) => {
      handlePlanDataChange({
        ...planData,
        tradeLayers: planData.tradeLayers.map((l) =>
          l.id === layerId ? { ...l, opacity } : l,
        ),
      });
    },
    [planData, handlePlanDataChange],
  );

  const handleRemoveLayer = useCallback(
    (layerId: string) => {
      handlePlanDataChange({
        ...planData,
        tradeLayers: planData.tradeLayers.filter((l) => l.id !== layerId),
      });
      if (editorState.activeLayerId === layerId) {
        setEditorState((prev) => ({ ...prev, activeLayerId: null }));
      }
    },
    [planData, editorState.activeLayerId, handlePlanDataChange],
  );

  // ── Template handler (SK13) ──
  const handleApplyTemplate = useCallback(
    (template: SketchTemplate) => {
      const fp = applyFloorPlanTemplate(template);
      if (fp) {
        handlePlanDataChange(fp);
        setPlanMode('floor');
      }
      const sp = applySitePlanTemplate(template);
      if (sp) {
        setSitePlanData(sp);
        if (!fp) setPlanMode('site');
      }
      setShowTemplatePicker(false);
    },
    [handlePlanDataChange],
  );

  // ── Site plan handlers (SK12) ──
  const handleSitePlanChange = useCallback(
    (data: SitePlanData) => {
      setSitePlanData(data);
      // Auto-save alongside floor plan
      savePlanData({ ...planData, sitePlan: data } as FloorPlanData & { sitePlan: SitePlanData });
    },
    [planData, savePlanData],
  );

  const handleSiteEditorStateChange = useCallback(
    (partial: Partial<SiteEditorState>) => {
      setSiteEditorState((prev) => ({ ...prev, ...partial }));
    },
    [],
  );

  const handleSiteSelectElement = useCallback(
    (id: string | null, type: string | null) => {
      setSiteSelectedId(id);
      setSiteSelectedType(type);
    },
    [],
  );

  const handleSiteToolChange = useCallback(
    (tool: SitePlanTool) => {
      setSiteEditorState((prev) => ({
        ...prev,
        activeTool: tool,
        ghostPoints: [],
        pendingSymbolType: tool === 'symbol' ? prev.pendingSymbolType : null,
      }));
    },
    [],
  );

  const handleSiteSymbolTypeChange = useCallback(
    (type: SiteSymbolType) => {
      setSiteEditorState((prev) => ({ ...prev, pendingSymbolType: type }));
    },
    [],
  );

  const handleSiteToggleVisibility = useCallback(
    (layerId: string) => {
      setSitePlanData((prev) => ({
        ...prev,
        layers: prev.layers.map((l) =>
          l.id === layerId ? { ...l, visible: !l.visible } : l,
        ),
      }));
    },
    [],
  );

  const handleSiteToggleLock = useCallback(
    (layerId: string) => {
      setSitePlanData((prev) => ({
        ...prev,
        layers: prev.layers.map((l) =>
          l.id === layerId ? { ...l, locked: !l.locked } : l,
        ),
      }));
    },
    [],
  );

  const handleSiteOpacityChange = useCallback(
    (layerId: string, opacity: number) => {
      setSitePlanData((prev) => ({
        ...prev,
        layers: prev.layers.map((l) =>
          l.id === layerId ? { ...l, opacity } : l,
        ),
      }));
    },
    [],
  );

  // DEPTH26: Property lookup → auto-generate site plan
  const handlePropertyLookupGenerated = useCallback(
    (generatedSitePlan: SitePlanData, scanId: string) => {
      handleSitePlanChange(generatedSitePlan);
      setReconScanId(scanId);
      setPlanMode('site');
    },
    [handleSitePlanChange],
  );

  // ── Context Menu Handlers ──
  const handleContextMenu = useCallback((event: ContextMenuEvent) => {
    setContextMenu(event);
  }, []);

  const handleContextMenuClose = useCallback(() => {
    setContextMenu(null);
  }, []);

  const handleContextMenuDelete = useCallback(() => {
    if (!contextMenu?.elementId || !contextMenu?.elementType) return;
    const cmd = new RemoveAnyElementCommand(contextMenu.elementId);
    const result = undoManagerRef.current.execute(cmd, planData);
    handlePlanDataChange(result);
    setSelection(createEmptySelection());
    setContextMenu(null);
  }, [contextMenu, planData, handlePlanDataChange]);

  const handleContextMenuDuplicate = useCallback(() => {
    if (!contextMenu?.elementId || !contextMenu?.elementType) return;
    const id = contextMenu.elementId;
    const offset = 20;
    let updated = { ...planData };

    if (contextMenu.elementType === 'wall') {
      const wall = planData.walls.find(w => w.id === id);
      if (wall) {
        const newWall = { ...wall, id: `wall_${Date.now()}`, start: { x: wall.start.x + offset, y: wall.start.y + offset }, end: { x: wall.end.x + offset, y: wall.end.y + offset } };
        updated = { ...updated, walls: [...updated.walls, newWall] };
      }
    } else if (contextMenu.elementType === 'door') {
      const door = planData.doors.find(d => d.id === id);
      if (door) {
        // position is a 0-1 parametric number along the wall — offset slightly
        const newDoor = { ...door, id: `door_${Date.now()}`, position: Math.min(door.position + 0.1, 0.95) };
        updated = { ...updated, doors: [...updated.doors, newDoor] };
      }
    } else if (contextMenu.elementType === 'window') {
      const win = planData.windows.find(w => w.id === id);
      if (win) {
        const newWin = { ...win, id: `window_${Date.now()}`, position: Math.min(win.position + 0.1, 0.95) };
        updated = { ...updated, windows: [...updated.windows, newWin] };
      }
    } else if (contextMenu.elementType === 'fixture') {
      const fix = planData.fixtures?.find(f => f.id === id);
      if (fix) {
        const newFix = { ...fix, id: `fixture_${Date.now()}`, position: { x: fix.position.x + offset, y: fix.position.y + offset } };
        updated = { ...updated, fixtures: [...(updated.fixtures || []), newFix] };
      }
    } else if (contextMenu.elementType === 'label') {
      const label = planData.labels?.find(l => l.id === id);
      if (label) {
        const newLabel = { ...label, id: `label_${Date.now()}`, position: { x: label.position.x + offset, y: label.position.y + offset } };
        updated = { ...updated, labels: [...(updated.labels || []), newLabel] };
      }
    }

    handlePlanDataChange(updated);
    setContextMenu(null);
  }, [contextMenu, planData, handlePlanDataChange]);

  const handleContextMenuSelect = useCallback(() => {
    if (!contextMenu?.elementId) return;
    setSelection({
      ...createEmptySelection(),
      selectedId: contextMenu.elementId,
      selectedType: contextMenu.elementType,
    });
    setEditorState(prev => ({ ...prev, activeTool: 'select' }));
    setContextMenu(null);
  }, [contextMenu]);

  // Close context menu on any click outside
  useEffect(() => {
    if (!contextMenu) return;
    const handleClick = () => setContextMenu(null);
    const handleKeyDown = (e: KeyboardEvent) => { if (e.key === 'Escape') setContextMenu(null); };
    window.addEventListener('click', handleClick);
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('click', handleClick);
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [contextMenu]);

  if (loading) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-gray-50" style={{ width: '100vw', height: '100vh' }}>
        <div className="text-center">
          <Loader2 className="h-6 w-6 animate-spin text-gray-400 mx-auto" />
          <p className="text-xs text-gray-400 mt-2">
            Loading floor plan...
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-gray-50" style={{ width: '100vw', height: '100vh' }}>
        <div className="text-center">
          <p className="text-sm text-red-500">{error}</p>
          <button
            onClick={onClose}
            className="text-sm text-blue-500 mt-2 underline"
          >
            Go back
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-[9999] flex flex-col bg-white" style={{ width: '100vw', height: '100vh' }}>
      {/* Editor top bar */}
      <div className="h-12 border-b border-gray-200 flex items-center px-3 gap-3 bg-white/95 backdrop-blur">
        <button
          onClick={onClose}
          className="p-1.5 rounded hover:bg-gray-100 text-gray-500"
        >
          <ArrowLeft size={16} />
        </button>
        <div className="flex-1 min-w-0">
          <h2 className="text-sm font-semibold text-gray-800 truncate">
            {plan?.name || 'Floor Plan'}
          </h2>
        </div>
        <div className="flex items-center gap-2 text-xs text-gray-400">
          {saving && (
            <>
              <Loader2 className="h-3 w-3 animate-spin" />
              <span>Saving...</span>
            </>
          )}
          {!saving && plan && (
            <>
              <Save className="h-3 w-3" />
              <span>Saved</span>
            </>
          )}
        </div>

        {/* SK13: Template picker */}
        <button
          onClick={() => setShowTemplatePicker(true)}
          className="p-1.5 rounded transition-colors hover:bg-gray-100 text-gray-400"
          title="Start from template"
        >
          <LayoutTemplate size={14} />
        </button>

        {/* SK8: Generate Estimate */}
        <button
          onClick={() => setShowEstimateModal(true)}
          disabled={planData.rooms.length === 0}
          className="p-1.5 rounded transition-colors hover:bg-gray-100 text-gray-400 disabled:opacity-30 disabled:cursor-not-allowed"
          title={planData.rooms.length === 0 ? 'Draw rooms first' : 'Generate estimate from rooms'}
        >
          <Calculator size={14} />
        </button>

        {/* SK9: Export */}
        <button
          onClick={() => setShowExportModal(true)}
          disabled={planData.walls.length === 0}
          className="p-1.5 rounded transition-colors hover:bg-gray-100 text-gray-400 disabled:opacity-30 disabled:cursor-not-allowed"
          title={planData.walls.length === 0 ? 'Draw a floor plan first' : 'Export floor plan'}
        >
          <Download size={14} />
        </button>

        {/* SK7: Photo pin toggle */}
        <button
          onClick={() => setPinMode(!pinMode)}
          className={`p-1.5 rounded transition-colors ${
            pinMode
              ? 'bg-emerald-100 text-emerald-600 border border-emerald-300'
              : 'hover:bg-gray-100 text-gray-400'
          }`}
          title={pinMode ? 'Cancel pin placement' : 'Place photo pin'}
        >
          <Camera size={14} />
        </button>

        {/* SK7: History toggle */}
        <button
          onClick={() => setShowHistory(!showHistory)}
          className={`p-1.5 rounded transition-colors ${
            showHistory
              ? 'bg-blue-100 text-blue-600 border border-blue-300'
              : 'hover:bg-gray-100 text-gray-400'
          }`}
          title="Version history"
        >
          <History size={14} />
        </button>

        {/* SK12: Floor/Site plan mode toggle */}
        <PlanModeToggle
          mode={planMode}
          onModeChange={(mode) => { setPlanMode(mode); setIs3DView(false); }}
        />

        {/* SK10: 2D/3D view toggle (floor plan only) */}
        {planMode === 'floor' && (
          <ViewToggle
            is3D={is3DView}
            onToggle={() => setIs3DView(!is3DView)}
          />
        )}

        {/* Unit toggle */}
        <button
          onClick={() =>
            handleEditorStateChange({
              units:
                editorState.units === 'imperial'
                  ? 'metric'
                  : 'imperial',
            })
          }
          className="px-2 py-0.5 text-xs font-medium text-blue-600 bg-blue-50 rounded border border-blue-200"
        >
          {editorState.units === 'imperial' ? 'ft/in' : 'm/cm'}
        </button>
        {/* Stats */}
        <div className="text-xs text-gray-400">
          {planMode === 'floor' ? (
            <>
              {planData.walls.length}W {planData.doors.length}D{' '}
              {planData.windows.length}Wi {planData.rooms.length}R
              {photoPins.length > 0 && <> {photoPins.length}P</>}
            </>
          ) : (
            <>
              {sitePlanData.structures.length}S {sitePlanData.linearFeatures.length}LF{' '}
              {sitePlanData.areaFeatures.length}AF {sitePlanData.symbols.length}Sym
            </>
          )}
        </div>
      </div>

      {/* Pin mode indicator */}
      {pinMode && (
        <div className="bg-emerald-50 border-b border-emerald-200 px-3 py-1.5 text-xs text-emerald-700 flex items-center gap-2">
          <Camera size={12} />
          Click on the canvas to place a photo pin. Press Escape to cancel.
        </div>
      )}

      {/* Canvas area with rulers */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top row: corner piece + horizontal ruler */}
        <div className="flex flex-shrink-0" style={{ height: RULER_THICKNESS }}>
          <RulerCorner />
          <div className="flex-1 overflow-hidden">
            <HorizontalRuler
              width={canvasSize.width}
              zoom={editorState.zoom}
              panOffsetX={editorState.panOffset.x}
              units={editorState.units}
            />
          </div>
        </div>

        {/* Bottom row: vertical ruler + canvas */}
        <div className="flex-1 flex overflow-hidden">
          <div className="flex-shrink-0" style={{ width: RULER_THICKNESS }}>
            <VerticalRuler
              height={canvasSize.height}
              zoom={editorState.zoom}
              panOffsetY={editorState.panOffset.y}
              units={editorState.units}
            />
          </div>

          {/* Canvas container */}
          <div className="flex-1 relative overflow-hidden" ref={containerRef}>
            {planMode === 'floor' ? (
              <>
                {/* Floor plan 2D overlays — hidden in 3D mode */}
                {!is3DView && (<>
                <div className="absolute top-3 left-3 z-10">
                  <Toolbar
                    editorState={editorState}
                    canUndo={undoManagerRef.current.canUndo}
                    canRedo={undoManagerRef.current.canRedo}
                    onToolChange={handleToolChange}
                    onUndo={handleUndo}
                    onRedo={handleRedo}
                    onZoomIn={() =>
                      handleEditorStateChange({
                        zoom: Math.min(editorState.zoom * 1.2, 5),
                      })
                    }
                    onZoomOut={() =>
                      handleEditorStateChange({
                        zoom: Math.max(editorState.zoom / 1.2, 0.1),
                      })
                    }
                    onToggleGrid={() =>
                      handleEditorStateChange({
                        showGrid: !editorState.showGrid,
                      })
                    }
                    onToggleLayers={() => setShowLayers(!showLayers)}
                  />
                </div>

                {showLayers && (
                  <div className="absolute top-3 left-16 z-10 flex flex-col gap-2">
                    <LayerPanel
                      layers={planData.tradeLayers}
                      activeLayerId={editorState.activeLayerId}
                      onActiveLayerChange={(id) =>
                        handleEditorStateChange({ activeLayerId: id })
                      }
                      onToggleVisibility={handleToggleVisibility}
                      onToggleLock={handleToggleLock}
                      onOpacityChange={handleOpacityChange}
                      onAddLayer={handleAddLayer}
                      onRemoveLayer={handleRemoveLayer}
                    />
                    <TradeSymbolPalette
                      activeLayerType={
                        editorState.activeLayerId
                          ? planData.tradeLayers.find(l => l.id === editorState.activeLayerId)?.type ?? null
                          : null
                      }
                      onPlaceSymbol={(symbolType) => {
                        handleEditorStateChange({
                          activeTool: 'tradeSymbol' as SketchTool,
                          pendingTradeSymbol: symbolType,
                        });
                      }}
                    />
                  </div>
                )}

                {showHistory && (
                  <div
                    className="absolute right-3 z-10"
                    style={{ top: showLayers ? 280 : 12 }}
                  >
                    <HistoryPanel
                      snapshots={snapshots}
                      loading={snapshotsLoading}
                      currentPlanData={planData}
                      onCreateSnapshot={createSnapshot}
                      onRestoreSnapshot={handleRestoreSnapshot}
                      onDeleteSnapshot={deleteSnapshot}
                      onClose={() => setShowHistory(false)}
                    />
                  </div>
                )}

                {selection.selectedId && !showHistory && (
                  <div className="absolute top-3 right-3 z-10" style={{ top: showLayers ? 280 : 12 }}>
                    <PropertyInspector
                      planData={planData}
                      selection={selection}
                      units={editorState.units}
                      undoManager={undoManagerRef.current}
                      onPlanDataChange={handlePlanDataChange}
                      onClose={() =>
                        setSelection({
                          ...selection,
                          selectedId: null,
                          selectedType: null,
                        })
                      }
                    />
                  </div>
                )}

                <div className="absolute bottom-3 right-3 z-10">
                  <MiniMap
                    planData={planData}
                    viewportOffset={editorState.panOffset}
                    viewportSize={canvasSize}
                    zoom={editorState.zoom}
                    canvasSize={4000}
                    onNavigate={handleMiniMapNavigate}
                  />
                </div>

                {photoPins.length > 0 && (
                  <div className="absolute bottom-3 left-3 z-10 bg-white/90 backdrop-blur border border-gray-200 rounded-lg px-2.5 py-1.5 shadow-sm">
                    <div className="flex items-center gap-1.5 text-xs text-gray-500">
                      <Camera size={12} className="text-emerald-500" />
                      <span>{photoPins.length} photo pin{photoPins.length !== 1 ? 's' : ''}</span>
                    </div>
                  </div>
                )}
                </>)}

                {/* Floor plan canvas: 3D or 2D */}
                {is3DView ? (
                  <ThreeDView
                    planData={planData}
                    width={canvasSize.width}
                    height={canvasSize.height}
                  />
                ) : (
                  <>
                  {planData.walls.length === 0 && (
                    <div className="absolute inset-0 flex items-center justify-center z-[5] pointer-events-none">
                      <div className="pointer-events-auto bg-white/95 backdrop-blur border border-gray-200 rounded-xl p-6 max-w-sm text-center shadow-lg">
                        <PenTool className="h-8 w-8 text-emerald-500 mx-auto mb-3" />
                        <h3 className="font-semibold text-gray-800 mb-2">Start Drawing</h3>
                        <p className="text-sm text-gray-500 mb-4">
                          Select the Wall tool from the toolbar on the left, then click on the canvas to draw walls. Close rooms to auto-calculate measurements.
                        </p>
                        <div className="flex gap-2 justify-center">
                          <button
                            onClick={() => handleToolChange('wall' as SketchTool)}
                            className="px-3 py-1.5 bg-emerald-600 text-white text-sm rounded-md hover:bg-emerald-500 transition-colors"
                          >
                            Select Wall Tool
                          </button>
                          <button
                            onClick={() => setShowTemplatePicker(true)}
                            className="px-3 py-1.5 border border-gray-300 text-gray-700 text-sm rounded-md hover:bg-gray-50 transition-colors"
                          >
                            Use Template
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                  <SketchCanvas
                    planData={planData}
                    editorState={editorState}
                    selection={selection}
                    onPlanDataChange={handlePlanDataChange}
                    onSelectionChange={setSelection}
                    onEditorStateChange={handleEditorStateChange}
                    undoManager={undoManagerRef.current}
                    width={canvasSize.width}
                    height={canvasSize.height}
                    externalStageRef={stageRef}
                    onContextMenu={handleContextMenu}
                  />
                  </>
                )}
              </>
            ) : (
              <>
                {/* SK12: Site plan overlays */}
                <div className="absolute top-3 left-3 z-10">
                  <SitePlanToolbar
                    activeTool={siteEditorState.activeTool}
                    canUndo={false}
                    canRedo={false}
                    onToolChange={handleSiteToolChange}
                    onSymbolTypeChange={handleSiteSymbolTypeChange}
                    onUndo={() => {}}
                    onRedo={() => {}}
                    onZoomIn={() =>
                      handleSiteEditorStateChange({
                        zoom: Math.min(siteEditorState.zoom * 1.2, 5),
                      })
                    }
                    onZoomOut={() =>
                      handleSiteEditorStateChange({
                        zoom: Math.max(siteEditorState.zoom / 1.2, 0.1),
                      })
                    }
                    onToggleGrid={() =>
                      handleSiteEditorStateChange({
                        showGrid: !siteEditorState.showGrid,
                      })
                    }
                  />
                </div>

                {/* DEPTH26: Property lookup panel (bottom-left, above background import) */}
                <div className="absolute bottom-32 left-3 z-10 w-64">
                  <PropertyLookupPanel
                    onSitePlanGenerated={handlePropertyLookupGenerated}
                  />
                </div>

                {/* Site background import (bottom-left) */}
                <div className="absolute bottom-3 left-3 z-10">
                  <SiteBackgroundImport
                    backgroundImageUrl={sitePlanData.backgroundImageUrl}
                    backgroundOpacity={sitePlanData.backgroundOpacity}
                    onImageChange={(url) =>
                      handleSitePlanChange({ ...sitePlanData, backgroundImageUrl: url })
                    }
                    onOpacityChange={(opacity) =>
                      handleSitePlanChange({ ...sitePlanData, backgroundOpacity: opacity })
                    }
                  />
                </div>

                {/* Site layer panel (right) */}
                <div className="absolute top-3 right-3 z-10">
                  <SitePlanLayerPanel
                    layers={sitePlanData.layers}
                    activeLayerId={siteEditorState.activeLayerId}
                    onActiveLayerChange={(id) =>
                      handleSiteEditorStateChange({ activeLayerId: id })
                    }
                    onToggleVisibility={handleSiteToggleVisibility}
                    onToggleLock={handleSiteToggleLock}
                    onOpacityChange={handleSiteOpacityChange}
                  />
                </div>

                {/* Site property inspector */}
                {siteSelectedId && (
                  <div className="absolute top-3 right-60 z-10">
                    <SitePropertyInspector
                      sitePlan={sitePlanData}
                      selectedId={siteSelectedId}
                      selectedType={siteSelectedType}
                      onSitePlanChange={handleSitePlanChange}
                      onClose={() => handleSiteSelectElement(null, null)}
                    />
                  </div>
                )}

                {/* Site plan canvas */}
                <SitePlanCanvas
                  sitePlan={sitePlanData}
                  editorState={siteEditorState}
                  selectedId={siteSelectedId}
                  canvasWidth={canvasSize.width}
                  canvasHeight={canvasSize.height}
                  onSitePlanChange={handleSitePlanChange}
                  onSelectElement={handleSiteSelectElement}
                  onEditorStateChange={handleSiteEditorStateChange}
                />
              </>
            )}
          </div>
        </div>
      </div>

      {/* SK8: Generate Estimate Modal */}
      {showEstimateModal && (
        <GenerateEstimateModal
          planData={planData}
          floorPlanId={planId}
          onClose={() => setShowEstimateModal(false)}
          onGenerated={(estimateId) => {
            setShowEstimateModal(false);
            // Navigate to estimate editor
            window.location.href = `/dashboard/estimates/${estimateId}`;
          }}
        />
      )}

      {/* SK9: Export Modal */}
      {showExportModal && (
        <ExportModal
          planData={planData}
          stageRef={stageRef}
          floorNumber={1}
          onClose={() => setShowExportModal(false)}
        />
      )}

      {/* SK13: Template Picker */}
      {showTemplatePicker && (
        <TemplatePicker
          onSelect={handleApplyTemplate}
          onClose={() => setShowTemplatePicker(false)}
        />
      )}

      {/* Right-Click Context Menu */}
      {contextMenu && (
        <div
          className="fixed z-[10001] min-w-[180px] bg-zinc-900 border border-zinc-700 rounded-lg shadow-2xl py-1 text-sm"
          style={{ left: contextMenu.x, top: contextMenu.y }}
          onClick={(e) => e.stopPropagation()}
        >
          {contextMenu.elementId ? (
            <>
              <div className="px-3 py-1.5 text-[10px] font-semibold text-zinc-500 uppercase tracking-wider">
                {contextMenu.elementType}
              </div>
              <button
                onClick={handleContextMenuSelect}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <MousePointer className="h-3.5 w-3.5" />
                Select
              </button>
              <button
                onClick={handleContextMenuDuplicate}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Copy className="h-3.5 w-3.5" />
                Duplicate
              </button>
              <div className="border-t border-zinc-700 my-1" />
              <button
                onClick={handleContextMenuDelete}
                className="w-full flex items-center gap-2 px-3 py-2 text-red-400 hover:bg-red-900/30 hover:text-red-300 transition-colors"
              >
                <Trash2 className="h-3.5 w-3.5" />
                Delete
              </button>
            </>
          ) : (
            <>
              <div className="px-3 py-1.5 text-[10px] font-semibold text-zinc-500 uppercase tracking-wider">
                Canvas
              </div>
              <button
                onClick={() => { handleToolChange('wall' as SketchTool); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <PenTool className="h-3.5 w-3.5" />
                Draw Wall Here
              </button>
              <button
                onClick={() => { handleToolChange('door' as SketchTool); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Maximize2 className="h-3.5 w-3.5" />
                Place Door
              </button>
              <button
                onClick={() => { handleToolChange('window' as SketchTool); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Grid3X3 className="h-3.5 w-3.5" />
                Place Window
              </button>
              <button
                onClick={() => { handleToolChange('fixture' as SketchTool); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Box className="h-3.5 w-3.5" />
                Place Fixture
              </button>
              <button
                onClick={() => { handleToolChange('label' as SketchTool); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Pencil className="h-3.5 w-3.5" />
                Add Label
              </button>
              <div className="border-t border-zinc-700 my-1" />
              <button
                onClick={() => { setEditorState(prev => ({ ...prev, showGrid: !prev.showGrid })); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Grid3X3 className="h-3.5 w-3.5" />
                {editorState.showGrid ? 'Hide Grid' : 'Show Grid'}
              </button>
              <button
                onClick={() => { setShowLayers(prev => !prev); setContextMenu(null); }}
                className="w-full flex items-center gap-2 px-3 py-2 text-zinc-300 hover:bg-zinc-800 hover:text-white transition-colors"
              >
                <Layers className="h-3.5 w-3.5" />
                {showLayers ? 'Hide Layers' : 'Show Layers'}
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}
