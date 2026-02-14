'use client';

// ZAFTO Site Plan Canvas — Konva renderer for exterior property drawing (SK12)
// Renders: property boundary, structures, roof planes, linear features,
// area features, elevation markers, site symbols, background image.

import React, { useRef, useCallback, useMemo, type RefObject } from 'react';
import { Stage, Layer, Line, Circle, Text, Group, Rect, Arrow, Image as KonvaImage } from 'react-konva';
import type Konva from 'konva';
import type {
  Point,
  SitePlanData,
  SiteEditorState,
  SitePlanTool,
  SiteSymbolType,
  LinearFeatureType,
  AreaFeatureType,
} from '@/lib/sketch-engine/types';
import {
  polygonAreaSqFt,
  polygonPerimeterFt,
  polygonCentroid,
  polylineLengthFt,
  calcFencePostCount,
  calcConcreteCuYd,
  calcSlopePct,
  distance,
} from '@/lib/sketch-engine/site-geometry';

const CANVAS_SIZE = 4000;
const SELECTED_COLOR = '#3B82F6';
const BOUNDARY_COLOR = '#EF4444';
const STRUCTURE_COLOR = '#6366F1';
const ROOF_COLOR = '#F59E0B';
const GRID_COLOR = '#E5E7EB';
const GRID_COLOR_MAJOR = '#D1D5DB';

// ── Layer colors ──
const FEATURE_COLORS: Record<string, string> = {
  fence: '#8B5CF6',
  retainingWall: '#78716C',
  gutter: '#0EA5E9',
  dripEdge: '#0EA5E9',
  solarRow: '#F59E0B',
  edging: '#84CC16',
  downspout: '#0EA5E9',
  concrete: '#9CA3AF',
  lawn: '#22C55E',
  paver: '#D97706',
  landscape: '#16A34A',
  gravel: '#A8A29E',
  pool: '#06B6D4',
  deck: '#92400E',
  driveway: '#6B7280',
};

const SYMBOL_LABELS: Record<SiteSymbolType, string> = {
  treeDeciduous: 'Tree',
  treeEvergreen: 'Pine',
  treePalm: 'Palm',
  shrub: 'Shrub',
  utilityBox: 'Util',
  acUnit: 'A/C',
  mailbox: 'Mail',
  lightPole: 'Light',
  irrigationHead: 'Irrig',
  downspoutSymbol: 'DS',
  cleanoutSite: 'CO',
  hoseBib: 'Hose',
  gasMeter: 'Gas',
  electricMeter: 'Elec',
  waterShutoff: 'H2O',
};

interface SitePlanCanvasProps {
  sitePlan: SitePlanData;
  editorState: SiteEditorState;
  selectedId: string | null;
  canvasWidth: number;
  canvasHeight: number;
  onSitePlanChange: (data: SitePlanData) => void;
  onSelectElement: (id: string | null, type: string | null) => void;
  onEditorStateChange: (partial: Partial<SiteEditorState>) => void;
  externalStageRef?: RefObject<Konva.Stage | null>;
}

export default function SitePlanCanvas({
  sitePlan,
  editorState,
  selectedId,
  canvasWidth,
  canvasHeight,
  onSitePlanChange,
  onSelectElement,
  onEditorStateChange,
  externalStageRef,
}: SitePlanCanvasProps) {
  const internalStageRef = useRef<Konva.Stage>(null);
  const stageRef = externalStageRef ?? internalStageRef;
  const { zoom, panOffset, showGrid, gridSize } = editorState;

  const scale = sitePlan.scale;

  // ── Helpers ──

  const generateId = useCallback(() => {
    return `sp_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
  }, []);

  const canvasToWorld = useCallback(
    (x: number, y: number): Point => ({
      x: (x - panOffset.x) / zoom,
      y: (y - panOffset.y) / zoom,
    }),
    [zoom, panOffset],
  );

  const isLayerVisible = useCallback(
    (layerType: string): boolean => {
      const layer = sitePlan.layers.find((l) => l.type === layerType);
      return layer ? layer.visible : true;
    },
    [sitePlan.layers],
  );

  const isLayerLocked = useCallback(
    (layerType: string): boolean => {
      const layer = sitePlan.layers.find((l) => l.type === layerType);
      return layer ? layer.locked : false;
    },
    [sitePlan.layers],
  );

  // ── Format helpers ──

  const fmtFt = (ft: number) => `${ft.toFixed(1)}'`;
  const fmtSqFt = (sf: number) => `${sf.toFixed(0)} sf`;
  const fmtAcres = (sf: number) => sf >= 43560 ? `${(sf / 43560).toFixed(2)} ac` : fmtSqFt(sf);

  // ── Edge length labels for polygon ──

  const edgeLabels = useCallback(
    (pts: Point[]) => {
      const labels: { x: number; y: number; text: string; rotation: number }[] = [];
      for (let i = 0; i < pts.length; i++) {
        const j = (i + 1) % pts.length;
        const mid = { x: (pts[i].x + pts[j].x) / 2, y: (pts[i].y + pts[j].y) / 2 };
        const lenFt = distance(pts[i], pts[j]) / scale;
        const angle = Math.atan2(pts[j].y - pts[i].y, pts[j].x - pts[i].x) * (180 / Math.PI);
        labels.push({ x: mid.x, y: mid.y - 8, text: fmtFt(lenFt), rotation: 0 });
      }
      return labels;
    },
    [scale],
  );

  // ── Stage events ──

  const handleClick = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      const stage = e.target.getStage();
      if (!stage) return;
      const pos = stage.getPointerPosition();
      if (!pos) return;
      const worldPt = canvasToWorld(pos.x, pos.y);
      const tool = editorState.activeTool;

      if (tool === 'select') {
        // Check if clicked on an element — delegated to shape event handlers
        if (e.target === stage) {
          onSelectElement(null, null);
        }
        return;
      }

      if (tool === 'boundary' && !isLayerLocked('boundary')) {
        // Add point to boundary polygon
        const current = sitePlan.boundary?.points ?? [];
        const newPts = [...current, worldPt];
        onSitePlanChange({
          ...sitePlan,
          boundary: {
            id: sitePlan.boundary?.id ?? generateId(),
            points: newPts,
            totalArea: polygonAreaSqFt(newPts, scale),
          },
        });
        return;
      }

      if (tool === 'structure' && !isLayerLocked('structures')) {
        const ghost = editorState.ghostPoints;
        onEditorStateChange({ ghostPoints: [...ghost, worldPt] });
        return;
      }

      if (tool === 'roofPlane' && !isLayerLocked('roof')) {
        const ghost = editorState.ghostPoints;
        onEditorStateChange({ ghostPoints: [...ghost, worldPt] });
        return;
      }

      if (
        (tool === 'fence' || tool === 'retainingWall' || tool === 'gutter' || tool === 'solarRow') &&
        !isLayerLocked('fencing') && !isLayerLocked('hardscape')
      ) {
        const ghost = editorState.ghostPoints;
        onEditorStateChange({ ghostPoints: [...ghost, worldPt] });
        return;
      }

      if (
        (tool === 'concrete' || tool === 'lawn' || tool === 'paver' ||
         tool === 'landscape' || tool === 'gravel') &&
        !isLayerLocked('hardscape') && !isLayerLocked('landscape')
      ) {
        const ghost = editorState.ghostPoints;
        onEditorStateChange({ ghostPoints: [...ghost, worldPt] });
        return;
      }

      if (tool === 'elevation' && !isLayerLocked('grading')) {
        const marker = {
          id: generateId(),
          position: worldPt,
          elevation: 0,
        };
        onSitePlanChange({
          ...sitePlan,
          elevationMarkers: [...sitePlan.elevationMarkers, marker],
        });
        onSelectElement(marker.id, 'elevation');
        return;
      }

      if (tool === 'symbol' && editorState.pendingSymbolType && !isLayerLocked('utilities')) {
        const sym = {
          id: generateId(),
          type: editorState.pendingSymbolType,
          position: worldPt,
          rotation: 0,
        };
        onSitePlanChange({
          ...sitePlan,
          symbols: [...sitePlan.symbols, sym],
        });
        return;
      }
    },
    [editorState, sitePlan, canvasToWorld, generateId, isLayerLocked, onSitePlanChange, onSelectElement, onEditorStateChange, scale],
  );

  const handleDoubleClick = useCallback(() => {
    const ghost = editorState.ghostPoints;
    if (ghost.length < 2) return;
    const tool = editorState.activeTool;

    // Finalize polygon/polyline from ghost points
    if (tool === 'structure' && ghost.length >= 3) {
      const structure = {
        id: generateId(),
        points: ghost,
        label: `Structure ${sitePlan.structures.length + 1}`,
      };
      onSitePlanChange({
        ...sitePlan,
        structures: [...sitePlan.structures, structure],
      });
      onEditorStateChange({ ghostPoints: [] });
      return;
    }

    if (tool === 'roofPlane' && ghost.length >= 3) {
      const rp = {
        id: generateId(),
        structureId: '',
        points: ghost,
        pitch: 6,
        type: 'gable' as const,
        wasteFactor: 0.1,
      };
      onSitePlanChange({
        ...sitePlan,
        roofPlanes: [...sitePlan.roofPlanes, rp],
      });
      onEditorStateChange({ ghostPoints: [] });
      return;
    }

    if ((tool === 'fence' || tool === 'retainingWall' || tool === 'gutter' || tool === 'solarRow') && ghost.length >= 2) {
      const typeMap: Record<string, LinearFeatureType> = {
        fence: 'fence', retainingWall: 'retainingWall', gutter: 'gutter', solarRow: 'solarRow',
      };
      const feature = {
        id: generateId(),
        type: typeMap[tool] ?? 'fence',
        points: ghost,
        height: tool === 'fence' ? 6 : undefined,
        postSpacing: tool === 'fence' ? 8 : undefined,
      };
      onSitePlanChange({
        ...sitePlan,
        linearFeatures: [...sitePlan.linearFeatures, feature],
      });
      onEditorStateChange({ ghostPoints: [] });
      return;
    }

    if (
      (tool === 'concrete' || tool === 'lawn' || tool === 'paver' ||
       tool === 'landscape' || tool === 'gravel') &&
      ghost.length >= 3
    ) {
      const typeMap: Record<string, AreaFeatureType> = {
        concrete: 'concrete', lawn: 'lawn', paver: 'paver', landscape: 'landscape', gravel: 'gravel',
      };
      const feature = {
        id: generateId(),
        type: typeMap[tool] ?? 'concrete',
        points: ghost,
        depth: tool === 'concrete' ? 4 : tool === 'gravel' ? 3 : undefined,
      };
      onSitePlanChange({
        ...sitePlan,
        areaFeatures: [...sitePlan.areaFeatures, feature],
      });
      onEditorStateChange({ ghostPoints: [] });
      return;
    }
  }, [editorState, sitePlan, generateId, onSitePlanChange, onEditorStateChange]);

  // ── Render functions ──

  const renderGrid = useMemo(() => {
    if (!showGrid) return null;
    const lines: React.ReactNode[] = [];
    const step = gridSize;
    const majorStep = step * 10;
    for (let i = 0; i <= CANVAS_SIZE; i += step) {
      const isMajor = i % majorStep === 0;
      const color = isMajor ? GRID_COLOR_MAJOR : GRID_COLOR;
      const sw = isMajor ? 0.5 : 0.25;
      lines.push(
        <Line key={`gv${i}`} points={[i, 0, i, CANVAS_SIZE]} stroke={color} strokeWidth={sw} listening={false} />,
        <Line key={`gh${i}`} points={[0, i, CANVAS_SIZE, i]} stroke={color} strokeWidth={sw} listening={false} />,
      );
    }
    return lines;
  }, [showGrid, gridSize]);

  const renderBoundary = useCallback(() => {
    if (!sitePlan.boundary || !isLayerVisible('boundary')) return null;
    const b = sitePlan.boundary;
    if (b.points.length < 2) return null;
    const flat = b.points.flatMap((p) => [p.x, p.y]);
    const isSel = selectedId === b.id;
    const center = polygonCentroid(b.points);
    const areaSqFt = polygonAreaSqFt(b.points, scale);

    return (
      <Group key="boundary">
        {/* Boundary fill */}
        {b.points.length >= 3 && (
          <Line
            points={flat}
            closed
            fill="rgba(239, 68, 68, 0.08)"
            stroke={isSel ? SELECTED_COLOR : BOUNDARY_COLOR}
            strokeWidth={isSel ? 3 : 2}
            dash={[12, 6]}
            listening={false}
          />
        )}
        {/* Vertices */}
        {b.points.map((p, i) => (
          <Circle
            key={`bv${i}`}
            x={p.x}
            y={p.y}
            radius={4}
            fill="#FFF"
            stroke={BOUNDARY_COLOR}
            strokeWidth={2}
            onClick={() => onSelectElement(b.id, 'boundary')}
          />
        ))}
        {/* Edge dimension labels */}
        {edgeLabels(b.points).map((lbl, i) => (
          <Text
            key={`bl${i}`}
            x={lbl.x}
            y={lbl.y}
            text={lbl.text}
            fontSize={10}
            fill={BOUNDARY_COLOR}
            fontFamily="Inter, sans-serif"
            listening={false}
          />
        ))}
        {/* Area label */}
        {b.points.length >= 3 && (
          <Group x={center.x} y={center.y} listening={false}>
            <Rect x={-50} y={-12} width={100} height={24} fill="rgba(255,255,255,0.9)" cornerRadius={4} />
            <Text
              x={-48}
              y={-8}
              text={fmtAcres(areaSqFt)}
              fontSize={12}
              fill={BOUNDARY_COLOR}
              fontStyle="bold"
              fontFamily="Inter, sans-serif"
            />
          </Group>
        )}
      </Group>
    );
  }, [sitePlan.boundary, selectedId, isLayerVisible, edgeLabels, scale, onSelectElement]);

  const renderStructures = useCallback(() => {
    if (!isLayerVisible('structures')) return null;
    return sitePlan.structures.map((s) => {
      if (s.points.length < 3) return null;
      const flat = s.points.flatMap((p) => [p.x, p.y]);
      const isSel = selectedId === s.id;
      const center = polygonCentroid(s.points);
      const footprint = polygonAreaSqFt(s.points, scale);

      return (
        <Group key={s.id}>
          <Line
            points={flat}
            closed
            fill="rgba(99, 102, 241, 0.12)"
            stroke={isSel ? SELECTED_COLOR : STRUCTURE_COLOR}
            strokeWidth={isSel ? 3 : 2}
            onClick={() => onSelectElement(s.id, 'structure')}
            hitStrokeWidth={12}
          />
          {/* Label */}
          <Group x={center.x} y={center.y} listening={false}>
            <Rect x={-45} y={-18} width={90} height={36} fill="rgba(255,255,255,0.9)" cornerRadius={4} />
            <Text x={-42} y={-14} text={s.label} fontSize={11} fill={STRUCTURE_COLOR} fontStyle="bold" fontFamily="Inter, sans-serif" />
            <Text x={-42} y={0} text={fmtSqFt(footprint)} fontSize={10} fill="#6B7280" fontFamily="Inter, sans-serif" />
          </Group>
        </Group>
      );
    });
  }, [sitePlan.structures, selectedId, isLayerVisible, scale, onSelectElement]);

  const renderRoofPlanes = useCallback(() => {
    if (!isLayerVisible('roof')) return null;
    return sitePlan.roofPlanes.map((rp) => {
      if (rp.points.length < 3) return null;
      const flat = rp.points.flatMap((p) => [p.x, p.y]);
      const isSel = selectedId === rp.id;
      const center = polygonCentroid(rp.points);

      return (
        <Group key={rp.id}>
          <Line
            points={flat}
            closed
            fill="rgba(245, 158, 11, 0.15)"
            stroke={isSel ? SELECTED_COLOR : ROOF_COLOR}
            strokeWidth={isSel ? 3 : 1.5}
            dash={[8, 4]}
            onClick={() => onSelectElement(rp.id, 'roofPlane')}
            hitStrokeWidth={12}
          />
          <Text
            x={center.x - 20}
            y={center.y - 6}
            text={`${rp.pitch}/12`}
            fontSize={10}
            fill={ROOF_COLOR}
            fontStyle="bold"
            fontFamily="Inter, sans-serif"
            listening={false}
          />
        </Group>
      );
    });
  }, [sitePlan.roofPlanes, selectedId, isLayerVisible, onSelectElement]);

  const renderLinearFeatures = useCallback(() => {
    if (!isLayerVisible('fencing') && !isLayerVisible('hardscape')) return null;
    return sitePlan.linearFeatures.map((f) => {
      if (f.points.length < 2) return null;
      const flat = f.points.flatMap((p) => [p.x, p.y]);
      const isSel = selectedId === f.id;
      const color = FEATURE_COLORS[f.type] ?? '#666';
      const lenFt = polylineLengthFt(f.points, scale);

      // Posts for fences
      const posts: React.ReactNode[] = [];
      if (f.type === 'fence' && f.postSpacing && f.postSpacing > 0) {
        const spacingCanvas = f.postSpacing * scale;
        for (let i = 0; i < f.points.length - 1; i++) {
          const a = f.points[i];
          const b = f.points[i + 1];
          const segLen = distance(a, b);
          const count = Math.floor(segLen / spacingCanvas);
          for (let j = 0; j <= count; j++) {
            const t = segLen > 0 ? (j * spacingCanvas) / segLen : 0;
            if (t > 1) break;
            posts.push(
              <Rect
                key={`post-${f.id}-${i}-${j}`}
                x={a.x + (b.x - a.x) * t - 2}
                y={a.y + (b.y - a.y) * t - 2}
                width={4}
                height={4}
                fill={color}
                listening={false}
              />,
            );
          }
        }
      }

      // Midpoint label
      const midIdx = Math.floor(f.points.length / 2);
      const mid = midIdx > 0
        ? { x: (f.points[midIdx - 1].x + f.points[midIdx].x) / 2, y: (f.points[midIdx - 1].y + f.points[midIdx].y) / 2 }
        : f.points[0];

      return (
        <Group key={f.id}>
          <Line
            points={flat}
            stroke={isSel ? SELECTED_COLOR : color}
            strokeWidth={isSel ? 4 : 2.5}
            lineCap="round"
            lineJoin="round"
            onClick={() => onSelectElement(f.id, 'linearFeature')}
            hitStrokeWidth={12}
          />
          {posts}
          <Text
            x={mid.x + 5}
            y={mid.y - 16}
            text={`${f.type.replace(/([A-Z])/g, ' $1').trim()} ${fmtFt(lenFt)}`}
            fontSize={9}
            fill={color}
            fontFamily="Inter, sans-serif"
            listening={false}
          />
        </Group>
      );
    });
  }, [sitePlan.linearFeatures, selectedId, isLayerVisible, scale, onSelectElement]);

  const renderAreaFeatures = useCallback(() => {
    if (!isLayerVisible('hardscape') && !isLayerVisible('landscape')) return null;
    return sitePlan.areaFeatures.map((f) => {
      if (f.points.length < 3) return null;
      const flat = f.points.flatMap((p) => [p.x, p.y]);
      const isSel = selectedId === f.id;
      const color = FEATURE_COLORS[f.type] ?? '#888';
      const center = polygonCentroid(f.points);
      const area = polygonAreaSqFt(f.points, scale);

      return (
        <Group key={f.id}>
          <Line
            points={flat}
            closed
            fill={`${color}20`}
            stroke={isSel ? SELECTED_COLOR : color}
            strokeWidth={isSel ? 3 : 1.5}
            onClick={() => onSelectElement(f.id, 'areaFeature')}
            hitStrokeWidth={10}
          />
          <Group x={center.x} y={center.y} listening={false}>
            <Text
              x={-30}
              y={-12}
              text={f.type}
              fontSize={9}
              fill={color}
              fontStyle="bold"
              fontFamily="Inter, sans-serif"
            />
            <Text
              x={-30}
              y={0}
              text={fmtSqFt(area)}
              fontSize={9}
              fill="#6B7280"
              fontFamily="Inter, sans-serif"
            />
          </Group>
        </Group>
      );
    });
  }, [sitePlan.areaFeatures, selectedId, isLayerVisible, scale, onSelectElement]);

  const renderElevationMarkers = useCallback(() => {
    if (!isLayerVisible('grading')) return null;
    return sitePlan.elevationMarkers.map((m) => {
      const isSel = selectedId === m.id;
      return (
        <Group key={m.id} x={m.position.x} y={m.position.y}>
          <Circle
            radius={8}
            fill={isSel ? SELECTED_COLOR : '#059669'}
            stroke="#FFF"
            strokeWidth={2}
            onClick={() => onSelectElement(m.id, 'elevation')}
          />
          <Text
            x={12}
            y={-6}
            text={`${m.elevation.toFixed(1)}'`}
            fontSize={10}
            fill="#059669"
            fontStyle="bold"
            fontFamily="Inter, sans-serif"
            listening={false}
          />
        </Group>
      );
    });

    // Slope lines between adjacent markers (auto)
  }, [sitePlan.elevationMarkers, selectedId, isLayerVisible, onSelectElement]);

  const renderSymbols = useCallback(() => {
    if (!isLayerVisible('utilities')) return null;
    return sitePlan.symbols.map((s) => {
      const isSel = selectedId === s.id;
      const label = SYMBOL_LABELS[s.type] ?? s.type;
      const isTree = s.type.startsWith('tree');
      const r = isTree ? (s.canopyRadius ?? 6) * scale : 10;

      return (
        <Group key={s.id} x={s.position.x} y={s.position.y} rotation={s.rotation}>
          {isTree ? (
            <>
              <Circle
                radius={r}
                fill="rgba(34,197,94,0.25)"
                stroke={isSel ? SELECTED_COLOR : '#16A34A'}
                strokeWidth={isSel ? 2 : 1}
                onClick={() => onSelectElement(s.id, 'symbol')}
              />
              <Circle radius={3} fill="#15803D" listening={false} />
            </>
          ) : s.type === 'shrub' ? (
            <Circle
              radius={8}
              fill="rgba(34,197,94,0.35)"
              stroke={isSel ? SELECTED_COLOR : '#16A34A'}
              strokeWidth={1}
              onClick={() => onSelectElement(s.id, 'symbol')}
            />
          ) : (
            <Rect
              x={-8}
              y={-8}
              width={16}
              height={16}
              fill={isSel ? '#DBEAFE' : '#F3F4F6'}
              stroke={isSel ? SELECTED_COLOR : '#6B7280'}
              strokeWidth={1}
              cornerRadius={2}
              onClick={() => onSelectElement(s.id, 'symbol')}
            />
          )}
          <Text
            x={isTree ? -r : -12}
            y={isTree ? r + 2 : 12}
            text={s.label ?? label}
            fontSize={8}
            fill="#374151"
            fontFamily="Inter, sans-serif"
            listening={false}
          />
        </Group>
      );
    });
  }, [sitePlan.symbols, selectedId, isLayerVisible, scale, onSelectElement]);

  const renderGhost = useCallback(() => {
    const ghost = editorState.ghostPoints;
    if (ghost.length === 0) return null;
    const flat = ghost.flatMap((p) => [p.x, p.y]);
    const tool = editorState.activeTool;
    const isPolygon = tool === 'structure' || tool === 'roofPlane' || tool === 'concrete' ||
      tool === 'lawn' || tool === 'paver' || tool === 'landscape' || tool === 'gravel';

    return (
      <Group>
        <Line
          points={flat}
          closed={isPolygon && ghost.length >= 3}
          stroke="#3B82F6"
          strokeWidth={2}
          dash={[8, 4]}
          fill={isPolygon && ghost.length >= 3 ? 'rgba(59,130,246,0.08)' : undefined}
          listening={false}
        />
        {ghost.map((p, i) => (
          <Circle
            key={`gp${i}`}
            x={p.x}
            y={p.y}
            radius={4}
            fill="#FFF"
            stroke="#3B82F6"
            strokeWidth={2}
            listening={false}
          />
        ))}
      </Group>
    );
  }, [editorState.ghostPoints, editorState.activeTool]);

  const isPanning = editorState.activeTool === 'pan';

  return (
    <Stage
      ref={stageRef as RefObject<Konva.Stage>}
      width={canvasWidth}
      height={canvasHeight}
      scaleX={zoom}
      scaleY={zoom}
      x={panOffset.x}
      y={panOffset.y}
      onClick={handleClick}
      onDblClick={handleDoubleClick}
      draggable={isPanning}
      style={{ cursor: isPanning ? 'grab' : 'crosshair' }}
    >
      {/* Grid */}
      <Layer listening={false} perfectDrawEnabled={false}>
        {renderGrid}
      </Layer>

      {/* Site elements */}
      <Layer>
        {renderBoundary()}
        {renderStructures()}
        {renderRoofPlanes()}
        {renderLinearFeatures()}
        {renderAreaFeatures()}
        {renderElevationMarkers()}
        {renderSymbols()}
      </Layer>

      {/* UI Overlay */}
      <Layer listening={false} perfectDrawEnabled={false}>
        {renderGhost()}
      </Layer>
    </Stage>
  );
}
