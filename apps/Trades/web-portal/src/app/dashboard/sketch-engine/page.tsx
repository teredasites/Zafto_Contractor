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
} from 'lucide-react';
import type Konva from 'konva';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
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
import { UndoRedoManager } from '@/lib/sketch-engine/commands';
import { formatDate } from '@/lib/utils';

// Dynamic import for Konva (SSR incompatible)
const SketchCanvas = dynamic(
  () => import('@/components/sketch-editor/SketchCanvas'),
  { ssr: false, loading: () => <CanvasLoadingPlaceholder /> },
);
import Toolbar from '@/components/sketch-editor/Toolbar';
import LayerPanel from '@/components/sketch-editor/LayerPanel';
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
  { icon: <PenTool className="h-5 w-5" />, label: 'Draw Tools', detail: 'Walls, doors, windows, rooms — click-to-draw precision', color: 'text-emerald-400 bg-emerald-500/10' },
  { icon: <RulerIcon className="h-5 w-5" />, label: 'Auto Measurements', detail: 'Live sqft, perimeter, and wall area as you draw', color: 'text-blue-400 bg-blue-500/10' },
  { icon: <Layers className="h-5 w-5" />, label: 'Trade Layers', detail: 'Electrical, plumbing, HVAC, damage overlays per trade', color: 'text-purple-400 bg-purple-500/10' },
  { icon: <Box className="h-5 w-5" />, label: '3D Visualization', detail: 'Instant 3D walkthrough preview from your floor plan', color: 'text-orange-400 bg-orange-500/10' },
  { icon: <Camera className="h-5 w-5" />, label: 'Photo Pins', detail: 'Pin geolocated jobsite photos directly on the plan', color: 'text-pink-400 bg-pink-500/10' },
  { icon: <Map className="h-5 w-5" />, label: 'Site Plans', detail: 'Outdoor structures, fencing, landscaping, driveways', color: 'text-teal-400 bg-teal-500/10' },
  { icon: <LayoutTemplate className="h-5 w-5" />, label: 'Templates', detail: 'Pre-built residential and commercial starting layouts', color: 'text-amber-400 bg-amber-500/10' },
  { icon: <Calculator className="h-5 w-5" />, label: 'Auto Estimates', detail: 'Generate line-item estimates from room measurements', color: 'text-cyan-400 bg-cyan-500/10' },
  { icon: <Maximize2 className="h-5 w-5" />, label: 'Rulers & Grid', detail: 'Imperial/metric rulers with snap-to-grid alignment', color: 'text-indigo-400 bg-indigo-500/10' },
  { icon: <History className="h-5 w-5" />, label: 'Version History', detail: 'Named snapshots — restore any previous version', color: 'text-rose-400 bg-rose-500/10' },
  { icon: <Grid3X3 className="h-5 w-5" />, label: 'Multi-Floor', detail: 'Separate floor tabs for multi-story buildings', color: 'text-lime-400 bg-lime-500/10' },
  { icon: <Download className="h-5 w-5" />, label: 'Export', detail: 'PDF, PNG, and JSON output for clients and records', color: 'text-sky-400 bg-sky-500/10' },
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
  const { createPlan } = useFloorPlan(null);
  const [creating, setCreating] = useState(false);

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

  return (
    <div className="p-6 space-y-6">
      {/* Hero Header */}
      <div className="relative overflow-hidden rounded-xl border border-zinc-800 bg-gradient-to-br from-zinc-900 to-emerald-950/20 p-6">
        <div className="relative z-10">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
                <PenTool size={20} className="text-emerald-400" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-zinc-100">Sketch Engine</h1>
                <p className="text-sm text-zinc-400">Professional floor plans, site plans, and auto-generated estimates</p>
              </div>
            </div>
            <Button
              onClick={handleCreate}
              disabled={creating}
              className="bg-emerald-600 hover:bg-emerald-500 text-white"
            >
              {creating ? (
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
              ) : (
                <Plus className="h-4 w-4 mr-2" />
              )}
              New Floor Plan
            </Button>
          </div>
        </div>
        <div className="absolute -right-8 -top-8 w-36 h-36 rounded-full bg-emerald-500/5" />
        <div className="absolute -right-4 -bottom-10 w-28 h-28 rounded-full bg-emerald-500/5" />
      </div>

      {/* Error Banner (small, doesn't block content) */}
      {error && (
        <div className="flex items-center justify-between bg-red-900/20 border border-red-800/50 rounded-lg px-4 py-2.5">
          <p className="text-sm text-red-400">{error}</p>
          <button
            onClick={refetch}
            className="flex items-center gap-1.5 text-xs text-red-400 hover:text-red-300 transition-colors"
          >
            <RefreshCw size={12} />
            Retry
          </button>
        </div>
      )}

      {/* Capabilities Grid — ALWAYS visible */}
      <div>
        <h2 className="text-sm font-medium text-zinc-400 mb-3 uppercase tracking-wider">Engine Capabilities</h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-3">
          {SK_FEATURES.map((feat) => {
            const [textColor, bgColor] = feat.color.split(' ');
            return (
              <div key={feat.label} className="p-3 rounded-lg border border-zinc-800 bg-zinc-900/50 hover:border-zinc-700 transition-colors group">
                <div className={`w-8 h-8 mx-auto mb-2 rounded-lg ${bgColor} flex items-center justify-center`}>
                  <span className={textColor}>{feat.icon}</span>
                </div>
                <p className="text-xs font-medium text-zinc-200 text-center">{feat.label}</p>
                <p className="text-[10px] text-zinc-500 mt-0.5 text-center leading-tight">{feat.detail}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-8">
          <Loader2 className="h-5 w-5 animate-spin text-zinc-500" />
          <span className="ml-2 text-sm text-zinc-500">Loading floor plans...</span>
        </div>
      )}

      {/* Your Floor Plans — shows when plans exist */}
      {!loading && plans.length > 0 && (
        <div>
          <h2 className="text-sm font-medium text-zinc-400 mb-3 uppercase tracking-wider">
            Your Floor Plans ({plans.length})
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {plans.map((plan) => (
              <PlanCard
                key={plan.id}
                plan={plan}
                onOpen={() => onOpenEditor(plan.id)}
              />
            ))}
          </div>
        </div>
      )}

      {/* Empty State — only when no plans and no error */}
      {!loading && !error && plans.length === 0 && (
        <div className="text-center py-8 rounded-xl border border-dashed border-zinc-700 bg-zinc-900/30">
          <PenTool className="h-10 w-10 text-emerald-500 mx-auto mb-3" />
          <h3 className="text-base font-semibold text-zinc-100 mb-1">No floor plans yet</h3>
          <p className="text-sm text-zinc-400 max-w-md mx-auto">
            Create your first floor plan to start drawing walls, placing doors and windows, defining rooms, and generating estimates.
          </p>
          <button
            onClick={handleCreate}
            disabled={creating}
            className="mt-4 inline-flex items-center gap-2 px-5 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
          >
            {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
            Create Your First Floor Plan
          </button>
        </div>
      )}
    </div>
  );
}

function PlanCard({
  plan,
  onOpen,
}: {
  plan: FloorPlanListItem;
  onOpen: () => void;
}) {
  const status = statusConfig[plan.status] || statusConfig.draft;

  return (
    <Card
      className="bg-zinc-900 border-zinc-800 hover:border-zinc-600 transition-all cursor-pointer group"
      onClick={onOpen}
    >
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <PenTool className="h-4 w-4 text-emerald-400 flex-shrink-0" />
              <h3 className="text-sm font-medium text-zinc-100 truncate">
                {plan.name}
              </h3>
            </div>
            <p className="text-xs text-zinc-500 mt-1">
              Floor {plan.floorLevel}
            </p>
          </div>
          <Badge className={`${status.bgColor} ${status.color} text-xs`}>
            {status.label}
          </Badge>
        </div>
        <div className="flex items-center gap-3 mt-3 text-xs text-zinc-500">
          <span>
            <RulerIcon className="h-3 w-3 inline mr-1" />
            {plan.wallCount} walls
          </span>
          <span>{plan.roomCount} rooms</span>
          <span className="ml-auto">{formatDate(plan.updatedAt)}</span>
        </div>
      </CardContent>
    </Card>
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
  const [canvasSize, setCanvasSize] = useState({ width: 800, height: 600 });

  const undoManagerRef = useRef(new UndoRedoManager());
  const containerRef = useRef<HTMLDivElement>(null);
  const stageRef = useRef<Konva.Stage>(null) as RefObject<Konva.Stage | null>;

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
                  <div className="absolute top-3 right-3 z-10">
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
    </div>
  );
}
