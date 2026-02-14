'use client';

// ZAFTO Sketch & Bid Page — SK8 Canvas Editor + Listing
// Full Konva.js canvas editor backed by property_floor_plans table.
// SK7: History panel, multi-floor tabs, photo pin integration.
// SK8: Generate Estimate modal (room measurements → D8 estimate areas + line items).

import { useState, useCallback, useRef, useEffect, type RefObject } from 'react';
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
} from 'lucide-react';
import type Konva from 'konva';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { CommandPalette } from '@/components/command-palette';
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

// =============================================================================
// MAIN PAGE
// =============================================================================

export default function SketchBidPage() {
  const [activeView, setActiveView] = useState<'list' | 'editor'>('list');
  const [activePlanId, setActivePlanId] = useState<string | null>(null);

  const openEditor = (planId: string) => {
    setActivePlanId(planId);
    setActiveView('editor');
  };

  const closeEditor = () => {
    setActiveView('list');
    setActivePlanId(null);
  };

  if (activeView === 'editor' && activePlanId) {
    return <EditorView planId={activePlanId} onClose={closeEditor} />;
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
  const { plans, loading, error } = useFloorPlanList();
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
      <CommandPalette />
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-zinc-100">
            Sketch & Bid
          </h1>
          <p className="text-sm text-zinc-400 mt-1">
            Floor plans, room measurements, and bid estimates
          </p>
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

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-6 w-6 animate-spin text-zinc-400" />
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="bg-red-900/20 border border-red-800 rounded-lg p-4 text-sm text-red-400">
          {error}
        </div>
      )}

      {/* Floor plan list */}
      {!loading && !error && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {plans.map((plan) => (
            <PlanCard
              key={plan.id}
              plan={plan}
              onOpen={() => onOpenEditor(plan.id)}
            />
          ))}
          {plans.length === 0 && (
            <div className="col-span-full text-center py-12">
              <PenTool className="h-8 w-8 text-zinc-600 mx-auto mb-3" />
              <p className="text-sm text-zinc-400">
                No floor plans yet. Create one to get started.
              </p>
            </div>
          )}
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
          console.error('[SketchBid] Invalid plan data structure, using empty plan');
          setPlanData(createEmptyFloorPlan());
        }
      } catch {
        console.error('[SketchBid] Failed to load plan data, using empty plan');
        setPlanData(createEmptyFloorPlan());
      }
    }
  }, [plan]);

  // Track container size
  useEffect(() => {
    const updateSize = () => {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        setCanvasSize({
          width: Math.max(rect.width, 400),
          height: Math.max(rect.height, 300),
        });
      }
    };

    updateSize();
    window.addEventListener('resize', updateSize);
    return () => window.removeEventListener('resize', updateSize);
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
      <div className="h-screen flex items-center justify-center bg-gray-50">
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
      <div className="h-screen flex items-center justify-center bg-gray-50">
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
    <div className="h-screen flex flex-col bg-white">
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
