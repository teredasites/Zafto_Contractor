'use client';

// ZAFTO Sketch Canvas — Main Konva Stage component (SK6)
// All layers rendered: base (walls, arc walls, doors, windows, fixtures, labels,
// dimensions, rooms) + trade layers (elements, paths, damage zones, moisture,
// containment, barriers) + UI overlay (ghost, snap, lasso).
// Pan (space+drag / middle-click), zoom (scroll wheel), grid rendering.

import React, { useRef, useEffect, useCallback, useState } from 'react';
import { Stage, Layer, Line, Rect, Group, Text, Circle, Shape, Arc, Arrow } from 'react-konva';
import Konva from 'konva';
import type {
  FloorPlanData,
  Wall,
  ArcWall,
  DoorPlacement,
  WindowPlacement,
  FixturePlacement,
  FloorLabel,
  DimensionLine,
  TradeLayer,
  SelectionState,
  EditorState,
  Point,
  MeasurementUnit,
} from '@/lib/sketch-engine/types';
import {
  snapAngle,
  snapToEndpoint,
  snapToGrid,
  projectOntoWall,
  findNearestWall,
  distance,
  wallLength,
  wallAngle,
  formatLength,
  formatArea,
  midpoint,
  pointInPolygon,
} from '@/lib/sketch-engine/geometry';
import {
  UndoRedoManager,
  AddWallCommand,
  AddArcWallCommand,
  AddDoorCommand,
  AddWindowCommand,
  AddFixtureCommand,
  AddLabelCommand,
  AddDimensionCommand,
  RemoveAnyElementCommand,
  RemoveMultipleCommand,
} from '@/lib/sketch-engine/commands';

interface SketchCanvasProps {
  planData: FloorPlanData;
  editorState: EditorState;
  selection: SelectionState;
  onPlanDataChange: (data: FloorPlanData) => void;
  onSelectionChange: (sel: SelectionState) => void;
  onEditorStateChange: (state: Partial<EditorState>) => void;
  undoManager: UndoRedoManager;
  width: number;
  height: number;
  externalStageRef?: React.RefObject<Konva.Stage | null>;
}

const CANVAS_SIZE = 4000;
const GRID_COLOR = '#E2E8F0';
const GRID_BOLD_COLOR = '#CBD5E1';
const WALL_COLOR = '#1E293B';
const SELECTED_COLOR = '#3B82F6';
const GHOST_COLOR = '#94A3B8';
const DOOR_COLOR = '#8B5CF6';
const WINDOW_COLOR = '#0EA5E9';
const FIXTURE_COLOR = '#059669';
const LABEL_COLOR = '#475569';

// Trade layer accent colors
const TRADE_COLORS: Record<string, string> = {
  electrical: '#F59E0B',
  plumbing: '#3B82F6',
  hvac: '#10B981',
  damage: '#EF4444',
};

// Trade path colors
const PATH_COLORS: Record<string, string> = {
  wire: '#F59E0B',
  pipe_hot: '#EF4444',
  pipe_cold: '#3B82F6',
  drain: '#6B7280',
  gas: '#EAB308',
  duct_supply: '#60A5FA',
  duct_return: '#F87171',
};

// IICRC damage colors
const DAMAGE_CLASS_COLORS: Record<string, string> = {
  '1': '#10B981', '2': '#F59E0B', '3': '#EF4444', '4': '#7C3AED',
};
const DAMAGE_CAT_COLORS: Record<string, string> = {
  '1': '#3B82F6', '2': '#F59E0B', '3': '#EF4444',
};

let idCounter = 0;
function generateId(prefix: string): string {
  return `${prefix}_${Date.now()}_${++idCounter}`;
}

function moistureSeverityColor(value: number): string {
  if (value < 15) return '#10B981';
  if (value < 30) return '#F59E0B';
  if (value < 50) return '#F97316';
  return '#EF4444';
}

export default function SketchCanvas({
  planData,
  editorState,
  selection,
  onPlanDataChange,
  onSelectionChange,
  onEditorStateChange,
  undoManager,
  width,
  height,
  externalStageRef,
}: SketchCanvasProps) {
  const internalStageRef = useRef<Konva.Stage>(null);
  const stageRef = externalStageRef ?? internalStageRef;
  const [isPanning, setIsPanning] = useState(false);
  const [drawStart, setDrawStart] = useState<Point | null>(null);
  const [ghostEnd, setGhostEnd] = useState<Point | null>(null);
  const [snapPoint, setSnapPoint] = useState<Point | null>(null);
  const [lassoPoints, setLassoPoints] = useState<Point[]>([]);
  const [isLassoing, setIsLassoing] = useState(false);
  // Clipboard for copy/paste
  const clipboardRef = useRef<FloorPlanData | null>(null);

  const units = editorState.units;

  // =========================================================================
  // KEYBOARD SHORTCUTS
  // =========================================================================

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const ctrl = e.ctrlKey || e.metaKey;

      // Ctrl+Z = Undo
      if (ctrl && e.key === 'z' && !e.shiftKey) {
        e.preventDefault();
        if (undoManager.canUndo) onPlanDataChange(undoManager.undo(planData));
      }
      // Ctrl+Y or Ctrl+Shift+Z = Redo
      if ((ctrl && e.key === 'y') || (ctrl && e.shiftKey && e.key === 'z')) {
        e.preventDefault();
        if (undoManager.canRedo) onPlanDataChange(undoManager.redo(planData));
      }
      // Ctrl+C = Copy selected
      if (ctrl && e.key === 'c') {
        const ids = selection.selectedId
          ? new Set([selection.selectedId, ...selection.multiSelectedIds])
          : selection.multiSelectedIds;
        if (ids.size > 0) {
          clipboardRef.current = {
            walls: planData.walls.filter((w) => ids.has(w.id)),
            arcWalls: planData.arcWalls.filter((a) => ids.has(a.id)),
            doors: planData.doors.filter((d) => ids.has(d.id)),
            windows: planData.windows.filter((w) => ids.has(w.id)),
            fixtures: planData.fixtures.filter((f) => ids.has(f.id)),
            labels: planData.labels.filter((l) => ids.has(l.id)),
            dimensions: planData.dimensions.filter((d) => ids.has(d.id)),
            rooms: [],
            tradeLayers: [],
            scale: planData.scale,
            units: planData.units,
          };
        }
      }
      // Ctrl+V = Paste from clipboard
      if (ctrl && e.key === 'v' && clipboardRef.current) {
        const cb = clipboardRef.current;
        const offset = 48; // 4-foot offset
        let result = { ...planData };
        for (const w of cb.walls) {
          const nw: Wall = { ...w, id: generateId('wall'), start: { x: w.start.x + offset, y: w.start.y + offset }, end: { x: w.end.x + offset, y: w.end.y + offset } };
          result = { ...result, walls: [...result.walls, nw] };
        }
        for (const a of cb.arcWalls) {
          const na: ArcWall = { ...a, id: generateId('arc'), start: { x: a.start.x + offset, y: a.start.y + offset }, end: { x: a.end.x + offset, y: a.end.y + offset }, controlPoint: { x: a.controlPoint.x + offset, y: a.controlPoint.y + offset } };
          result = { ...result, arcWalls: [...result.arcWalls, na] };
        }
        for (const f of cb.fixtures) {
          const nf: FixturePlacement = { ...f, id: generateId('fix'), position: { x: f.position.x + offset, y: f.position.y + offset } };
          result = { ...result, fixtures: [...result.fixtures, nf] };
        }
        for (const l of cb.labels) {
          const nl: FloorLabel = { ...l, id: generateId('lbl'), position: { x: l.position.x + offset, y: l.position.y + offset } };
          result = { ...result, labels: [...result.labels, nl] };
        }
        onPlanDataChange(result);
      }
      // Delete / Backspace = Remove selected (smart — any element type)
      if (e.key === 'Delete' || e.key === 'Backspace') {
        if (selection.multiSelectedIds.size > 0) {
          const allIds = new Set(selection.multiSelectedIds);
          if (selection.selectedId) allIds.add(selection.selectedId);
          const cmd = new RemoveMultipleCommand(allIds);
          onPlanDataChange(undoManager.execute(cmd, planData));
          onSelectionChange({ selectedId: null, selectedType: null, multiSelectedIds: new Set(), multiSelectedTypes: new Map() });
        } else if (selection.selectedId) {
          const cmd = new RemoveAnyElementCommand(selection.selectedId);
          onPlanDataChange(undoManager.execute(cmd, planData));
          onSelectionChange({ ...selection, selectedId: null, selectedType: null });
        }
      }
      // Escape = Deselect / cancel drawing
      if (e.key === 'Escape') {
        setDrawStart(null);
        setGhostEnd(null);
        setLassoPoints([]);
        setIsLassoing(false);
        onSelectionChange({ selectedId: null, selectedType: null, multiSelectedIds: new Set(), multiSelectedTypes: new Map() });
        onEditorStateChange({ isDrawing: false });
      }
      // Space = Pan mode
      if (e.key === ' ') {
        e.preventDefault();
        setIsPanning(true);
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      if (e.key === ' ') setIsPanning(false);
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [planData, selection, undoManager, onPlanDataChange, onSelectionChange, onEditorStateChange]);

  // =========================================================================
  // MOUSE HANDLERS
  // =========================================================================

  const getCanvasPoint = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>): Point | null => {
      const stage = stageRef.current;
      if (!stage) return null;
      const pos = stage.getPointerPosition();
      if (!pos) return null;
      const transform = stage.getAbsoluteTransform().copy().invert();
      const pt = transform.point(pos);
      return { x: pt.x, y: pt.y };
    },
    [],
  );

  const handleStageClick = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      const point = getCanvasPoint(e);
      if (!point) return;
      const tool = isPanning ? 'pan' : editorState.activeTool;

      // --- WALL TOOL ---
      if (tool === 'wall') {
        if (!drawStart) {
          const snapped = snapToEndpoint(point, planData.walls, planData.arcWalls) ?? snapToGrid(point, editorState.gridSize);
          setDrawStart(snapped);
          setSnapPoint(snapped);
        } else {
          let endPt = snapToEndpoint(point, planData.walls, planData.arcWalls) ?? snapToGrid(point, editorState.gridSize);
          endPt = snapAngle(drawStart, endPt);
          if (distance(drawStart, endPt) > 6) {
            const wall: Wall = { id: generateId('wall'), start: drawStart, end: endPt, thickness: editorState.wallThickness, height: 96 };
            onPlanDataChange(undoManager.execute(new AddWallCommand(wall), planData));
          }
          setDrawStart(null);
          setGhostEnd(null);
          setSnapPoint(null);
        }
      }
      // --- ARC WALL TOOL ---
      else if (tool === 'arcWall') {
        if (!drawStart) {
          const snapped = snapToEndpoint(point, planData.walls, planData.arcWalls) ?? snapToGrid(point, editorState.gridSize);
          setDrawStart(snapped);
        } else {
          let endPt = snapToEndpoint(point, planData.walls, planData.arcWalls) ?? snapToGrid(point, editorState.gridSize);
          if (distance(drawStart, endPt) > 12) {
            const mid = midpoint(drawStart, endPt);
            const dx = endPt.x - drawStart.x;
            const dy = endPt.y - drawStart.y;
            const controlPoint: Point = { x: mid.x - dy * 0.4, y: mid.y + dx * 0.4 };
            const arc: ArcWall = { id: generateId('arc'), start: drawStart, end: endPt, controlPoint, thickness: editorState.wallThickness, height: 96 };
            onPlanDataChange(undoManager.execute(new AddArcWallCommand(arc), planData));
          }
          setDrawStart(null);
          setGhostEnd(null);
          setSnapPoint(null);
        }
      }
      // --- DOOR / WINDOW TOOL ---
      else if (tool === 'door' || tool === 'window') {
        const wall = findNearestWall(point, planData.walls, 18);
        if (wall) {
          const t = projectOntoWall(point, wall);
          if (tool === 'door') {
            const door: DoorPlacement = { id: generateId('door'), wallId: wall.id, position: t, width: editorState.doorWidth, type: editorState.doorType };
            onPlanDataChange(undoManager.execute(new AddDoorCommand(door), planData));
          } else {
            const win: WindowPlacement = { id: generateId('win'), wallId: wall.id, position: t, width: editorState.windowWidth, type: editorState.windowType };
            onPlanDataChange(undoManager.execute(new AddWindowCommand(win), planData));
          }
        }
      }
      // --- FIXTURE TOOL ---
      else if (tool === 'fixture' && editorState.pendingFixtureType) {
        const fixture: FixturePlacement = { id: generateId('fix'), position: snapToGrid(point, editorState.gridSize), type: editorState.pendingFixtureType, rotation: 0 };
        onPlanDataChange(undoManager.execute(new AddFixtureCommand(fixture), planData));
      }
      // --- LABEL TOOL ---
      else if (tool === 'label') {
        const label: FloorLabel = { id: generateId('lbl'), position: snapToGrid(point, editorState.gridSize), text: 'Label', fontSize: 14, rotation: 0 };
        onPlanDataChange(undoManager.execute(new AddLabelCommand(label), planData));
      }
      // --- DIMENSION TOOL ---
      else if (tool === 'dimension') {
        if (!drawStart) {
          setDrawStart(snapToGrid(point, editorState.gridSize));
        } else {
          const endPt = snapToGrid(point, editorState.gridSize);
          if (distance(drawStart, endPt) > 6) {
            const dim: DimensionLine = { id: generateId('dim'), start: drawStart, end: endPt, offset: 18, isAuto: false };
            onPlanDataChange(undoManager.execute(new AddDimensionCommand(dim), planData));
          }
          setDrawStart(null);
          setGhostEnd(null);
        }
      }
      // --- SELECT TOOL ---
      else if (tool === 'select') {
        const target = e.target;
        if (target && target.id && target.id() !== '') {
          onSelectionChange({ ...selection, selectedId: target.id(), selectedType: target.className });
        } else {
          onSelectionChange({ selectedId: null, selectedType: null, multiSelectedIds: new Set(), multiSelectedTypes: new Map() });
        }
      }
      // --- ERASE TOOL (smart — any element) ---
      else if (tool === 'erase') {
        const target = e.target;
        if (target && target.id && target.id() !== '') {
          const cmd = new RemoveAnyElementCommand(target.id());
          onPlanDataChange(undoManager.execute(cmd, planData));
        }
      }
    },
    [getCanvasPoint, drawStart, editorState, planData, selection, undoManager, onPlanDataChange, onSelectionChange, isPanning],
  );

  const handleMouseMove = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      const point = getCanvasPoint(e);
      if (!point) return;

      // Lasso drawing
      if (isLassoing && editorState.activeTool === 'lasso') {
        setLassoPoints((prev) => [...prev, point]);
        return;
      }

      if (!drawStart) return;
      let endPt = snapToEndpoint(point, planData.walls, planData.arcWalls) ?? snapToGrid(point, editorState.gridSize);
      if (editorState.activeTool === 'wall' || editorState.activeTool === 'arcWall') {
        endPt = snapAngle(drawStart, endPt);
      }
      setGhostEnd(endPt);
      setSnapPoint(snapToEndpoint(point, planData.walls, planData.arcWalls));
    },
    [drawStart, getCanvasPoint, planData, editorState, isLassoing],
  );

  const handleMouseDown = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      // Middle-click pan
      if (e.evt.button === 1) {
        setIsPanning(true);
        return;
      }
      // Lasso start
      if (editorState.activeTool === 'lasso' && e.evt.button === 0) {
        const point = getCanvasPoint(e);
        if (point) {
          setIsLassoing(true);
          setLassoPoints([point]);
        }
      }
    },
    [editorState.activeTool, getCanvasPoint],
  );

  const handleMouseUp = useCallback(
    (e: Konva.KonvaEventObject<MouseEvent>) => {
      if (e.evt.button === 1) {
        setIsPanning(false);
        return;
      }
      // Lasso finish — select elements inside polygon
      if (isLassoing && lassoPoints.length > 2) {
        const ids = new Set<string>();
        const types = new Map<string, string>();
        for (const w of planData.walls) {
          const mid = midpoint(w.start, w.end);
          if (pointInPolygon(mid, lassoPoints)) { ids.add(w.id); types.set(w.id, 'wall'); }
        }
        for (const a of planData.arcWalls) {
          const mid = midpoint(a.start, a.end);
          if (pointInPolygon(mid, lassoPoints)) { ids.add(a.id); types.set(a.id, 'arcWall'); }
        }
        for (const f of planData.fixtures) {
          if (pointInPolygon(f.position, lassoPoints)) { ids.add(f.id); types.set(f.id, 'fixture'); }
        }
        for (const l of planData.labels) {
          if (pointInPolygon(l.position, lassoPoints)) { ids.add(l.id); types.set(l.id, 'label'); }
        }
        if (ids.size > 0) {
          onSelectionChange({ selectedId: null, selectedType: null, multiSelectedIds: ids, multiSelectedTypes: types });
        }
      }
      setIsLassoing(false);
      setLassoPoints([]);
    },
    [isLassoing, lassoPoints, planData, onSelectionChange],
  );

  const handleWheel = useCallback(
    (e: Konva.KonvaEventObject<WheelEvent>) => {
      e.evt.preventDefault();
      const stage = stageRef.current;
      if (!stage) return;

      const oldScale = stage.scaleX();
      const pointer = stage.getPointerPosition();
      if (!pointer) return;

      const scaleBy = 1.08;
      const newScale = e.evt.deltaY < 0 ? oldScale * scaleBy : oldScale / scaleBy;
      const clampedScale = Math.max(0.1, Math.min(5, newScale));

      const mousePointTo = { x: (pointer.x - stage.x()) / oldScale, y: (pointer.y - stage.y()) / oldScale };
      const newPos = { x: pointer.x - mousePointTo.x * clampedScale, y: pointer.y - mousePointTo.y * clampedScale };
      stage.scale({ x: clampedScale, y: clampedScale });
      stage.position(newPos);
      onEditorStateChange({ zoom: clampedScale, panOffset: newPos });
    },
    [onEditorStateChange],
  );

  // =========================================================================
  // GRID RENDERING
  // =========================================================================

  const renderGrid = () => {
    if (!editorState.showGrid) return null;
    const lines: React.ReactElement[] = [];
    const gs = editorState.gridSize;
    const boldEvery = 12;

    for (let i = 0; i <= CANVAS_SIZE; i += gs) {
      const isBold = i % (gs * boldEvery) === 0;
      const color = isBold ? GRID_BOLD_COLOR : GRID_COLOR;
      const sw = isBold ? 0.5 : 0.25;
      lines.push(<Line key={`gv${i}`} points={[i, 0, i, CANVAS_SIZE]} stroke={color} strokeWidth={sw} listening={false} />);
      lines.push(<Line key={`gh${i}`} points={[0, i, CANVAS_SIZE, i]} stroke={color} strokeWidth={sw} listening={false} />);
    }
    return <>{lines}</>;
  };

  // =========================================================================
  // BASE ELEMENT RENDERING
  // =========================================================================

  const isSelected = (id: string) => selection.selectedId === id || selection.multiSelectedIds.has(id);

  const renderWalls = () =>
    planData.walls.map((wall) => {
      const sel = isSelected(wall.id);
      return (
        <Group key={wall.id}>
          <Line
            id={wall.id}
            points={[wall.start.x, wall.start.y, wall.end.x, wall.end.y]}
            stroke={sel ? SELECTED_COLOR : WALL_COLOR}
            strokeWidth={wall.thickness}
            lineCap="round"
            hitStrokeWidth={Math.max(wall.thickness, 12)}
          />
          {/* Wall dimension label */}
          {renderWallDimension(wall)}
          {/* Endpoint handles when selected */}
          {sel && (
            <>
              <Circle x={wall.start.x} y={wall.start.y} radius={5} fill="#FFF" stroke={SELECTED_COLOR} strokeWidth={2} listening={false} />
              <Circle x={wall.end.x} y={wall.end.y} radius={5} fill="#FFF" stroke={SELECTED_COLOR} strokeWidth={2} listening={false} />
            </>
          )}
        </Group>
      );
    });

  const renderWallDimension = (wall: Wall) => {
    const len = wallLength(wall);
    if (len < 12) return null; // Skip labels for tiny walls
    const angle = wallAngle(wall);
    const mid = midpoint(wall.start, wall.end);
    const offsetDist = wall.thickness / 2 + 14;
    const perpX = -Math.sin(angle) * offsetDist;
    const perpY = Math.cos(angle) * offsetDist;

    return (
      <Text
        x={mid.x + perpX - 20}
        y={mid.y + perpY - 6}
        text={formatLength(len, units)}
        fontSize={11}
        fontFamily="Inter, sans-serif"
        fill="#64748B"
        width={40}
        align="center"
        listening={false}
        rotation={(angle * 180) / Math.PI}
      />
    );
  };

  const renderArcWalls = () =>
    planData.arcWalls.map((arc) => {
      const sel = isSelected(arc.id);
      return (
        <Group key={arc.id}>
          <Shape
            id={arc.id}
            sceneFunc={(context, shape) => {
              context.beginPath();
              context.moveTo(arc.start.x, arc.start.y);
              context.quadraticCurveTo(arc.controlPoint.x, arc.controlPoint.y, arc.end.x, arc.end.y);
              context.setAttr('strokeStyle', sel ? SELECTED_COLOR : WALL_COLOR);
              context.setAttr('lineWidth', arc.thickness);
              context.setAttr('lineCap', 'round');
              context.stroke();
              context.fillStrokeShape(shape);
            }}
            hitFunc={(context, shape) => {
              context.beginPath();
              context.moveTo(arc.start.x, arc.start.y);
              context.quadraticCurveTo(arc.controlPoint.x, arc.controlPoint.y, arc.end.x, arc.end.y);
              context.setAttr('lineWidth', Math.max(arc.thickness, 12));
              context.stroke();
              context.fillStrokeShape(shape);
            }}
          />
          {sel && (
            <>
              <Circle x={arc.start.x} y={arc.start.y} radius={5} fill="#FFF" stroke={SELECTED_COLOR} strokeWidth={2} listening={false} />
              <Circle x={arc.end.x} y={arc.end.y} radius={5} fill="#FFF" stroke={SELECTED_COLOR} strokeWidth={2} listening={false} />
              <Circle x={arc.controlPoint.x} y={arc.controlPoint.y} radius={4} fill={SELECTED_COLOR} opacity={0.5} listening={false} />
            </>
          )}
        </Group>
      );
    });

  const renderDoors = () =>
    planData.doors.map((door) => {
      const wall = planData.walls.find((w) => w.id === door.wallId);
      if (!wall) return null;
      const sel = isSelected(door.id);
      const color = sel ? SELECTED_COLOR : DOOR_COLOR;
      const pos = { x: wall.start.x + (wall.end.x - wall.start.x) * door.position, y: wall.start.y + (wall.end.y - wall.start.y) * door.position };
      const angle = Math.atan2(wall.end.y - wall.start.y, wall.end.x - wall.start.x);
      const halfW = door.width / 2;
      const perpAngle = angle + Math.PI / 2;

      // Hinge point
      const hinge = { x: pos.x - halfW * Math.cos(angle), y: pos.y - halfW * Math.sin(angle) };
      const doorEnd = { x: hinge.x + door.width * Math.cos(perpAngle), y: hinge.y + door.width * Math.sin(perpAngle) };

      return (
        <Group key={door.id} id={door.id}>
          {/* Gap in wall */}
          <Line points={[pos.x - halfW * Math.cos(angle), pos.y - halfW * Math.sin(angle), pos.x + halfW * Math.cos(angle), pos.y + halfW * Math.sin(angle)]} stroke="#FFFFFF" strokeWidth={wall.thickness + 2} listening={false} />
          {/* Door panel */}
          <Line points={[hinge.x, hinge.y, doorEnd.x, doorEnd.y]} stroke={color} strokeWidth={2} />
          {/* Swing arc */}
          <Arc x={hinge.x} y={hinge.y} innerRadius={door.width} outerRadius={door.width} angle={90} rotation={(perpAngle * 180) / Math.PI - 90} stroke={color} strokeWidth={1} dash={[4, 4]} listening={false} />
        </Group>
      );
    });

  const renderWindows = () =>
    planData.windows.map((win) => {
      const wall = planData.walls.find((w) => w.id === win.wallId);
      if (!wall) return null;
      const sel = isSelected(win.id);
      const color = sel ? SELECTED_COLOR : WINDOW_COLOR;
      const pos = { x: wall.start.x + (wall.end.x - wall.start.x) * win.position, y: wall.start.y + (wall.end.y - wall.start.y) * win.position };
      const angle = Math.atan2(wall.end.y - wall.start.y, wall.end.x - wall.start.x);
      const halfW = win.width / 2;
      const perpAngle = angle + Math.PI / 2;

      return (
        <Group key={win.id} id={win.id}>
          <Line points={[pos.x - halfW * Math.cos(angle), pos.y - halfW * Math.sin(angle), pos.x + halfW * Math.cos(angle), pos.y + halfW * Math.sin(angle)]} stroke="#FFFFFF" strokeWidth={wall.thickness + 2} listening={false} />
          {[-3, 0, 3].map((offset) => (
            <Line
              key={`${win.id}_${offset}`}
              points={[
                pos.x - halfW * Math.cos(angle) + offset * Math.cos(perpAngle),
                pos.y - halfW * Math.sin(angle) + offset * Math.sin(perpAngle),
                pos.x + halfW * Math.cos(angle) + offset * Math.cos(perpAngle),
                pos.y + halfW * Math.sin(angle) + offset * Math.sin(perpAngle),
              ]}
              stroke={color}
              strokeWidth={offset === 0 ? 2 : 1}
            />
          ))}
        </Group>
      );
    });

  const renderFixtures = () =>
    planData.fixtures.map((fix) => {
      const sel = isSelected(fix.id);
      const color = sel ? SELECTED_COLOR : FIXTURE_COLOR;
      const s = 24;
      return (
        <Group key={fix.id} id={fix.id} x={fix.position.x} y={fix.position.y} rotation={fix.rotation}>
          {renderFixtureSymbol(fix.type, color, s)}
          {sel && <Rect x={-s * 0.6} y={-s * 0.6} width={s * 1.2} height={s * 1.2} stroke={SELECTED_COLOR} strokeWidth={1} dash={[4, 4]} listening={false} />}
        </Group>
      );
    });

  const renderFixtureSymbol = (type: string, color: string, s: number) => {
    switch (type) {
      case 'toilet':
        return (<><Circle radiusX={s * 0.4} radiusY={s * 0.5} stroke={color} strokeWidth={1.5} /><Rect x={-s * 0.35} y={-s * 0.6} width={s * 0.7} height={s * 0.3} stroke={color} strokeWidth={1.5} cornerRadius={2} /></>);
      case 'sink':
        return (<><Rect x={-s * 0.4} y={-s * 0.3} width={s * 0.8} height={s * 0.6} stroke={color} strokeWidth={1.5} cornerRadius={3} /><Circle radius={s * 0.2} stroke={color} strokeWidth={1} /></>);
      case 'bathtub':
        return <Rect x={-s} y={-s * 0.4} width={s * 2} height={s * 0.8} stroke={color} strokeWidth={1.5} cornerRadius={8} />;
      case 'shower':
        return (<><Rect x={-s * 0.5} y={-s * 0.5} width={s} height={s} stroke={color} strokeWidth={1.5} /><Line points={[-s * 0.4, -s * 0.4, s * 0.4, s * 0.4]} stroke={color} strokeWidth={1} /><Line points={[s * 0.4, -s * 0.4, -s * 0.4, s * 0.4]} stroke={color} strokeWidth={1} /></>);
      case 'stove':
        return (<><Rect x={-s * 0.5} y={-s * 0.5} width={s} height={s} stroke={color} strokeWidth={1.5} />{[[-0.2, -0.2], [0.2, -0.2], [-0.2, 0.2], [0.2, 0.2]].map(([ox, oy], i) => <Circle key={i} x={ox * s} y={oy * s} radius={s * 0.12} stroke={color} strokeWidth={1} />)}</>);
      case 'refrigerator':
        return (<><Rect x={-s * 0.4} y={-s * 0.6} width={s * 0.8} height={s * 1.2} stroke={color} strokeWidth={1.5} cornerRadius={2} /><Line points={[-s * 0.4, -s * 0.1, s * 0.4, -s * 0.1]} stroke={color} strokeWidth={1} /></>);
      case 'stairs':
        return (<><Rect x={-s * 0.4} y={-s * 0.8} width={s * 0.8} height={s * 1.6} stroke={color} strokeWidth={1.5} />{[-3, -2, -1, 0, 1, 2, 3].map((i) => <Line key={i} points={[-s * 0.4, i * s * 0.2, s * 0.4, i * s * 0.2]} stroke={color} strokeWidth={1} />)}<Arrow points={[0, s * 0.6, 0, -s * 0.6]} pointerLength={4} pointerWidth={4} fill={color} stroke={color} strokeWidth={1} /></>);
      default:
        return (<><Rect x={-s * 0.4} y={-s * 0.4} width={s * 0.8} height={s * 0.8} stroke={color} strokeWidth={1.5} /><Text text={type.slice(0, 3).toUpperCase()} x={-10} y={-6} fontSize={10} fill={color} fontFamily="Inter" /></>);
    }
  };

  const renderLabels = () =>
    planData.labels.map((label) => {
      const sel = isSelected(label.id);
      return (
        <Group key={label.id} id={label.id} x={label.position.x} y={label.position.y} rotation={label.rotation}>
          <Text text={label.text} fontSize={label.fontSize} fontFamily="Inter, sans-serif" fill={sel ? SELECTED_COLOR : LABEL_COLOR} fontStyle="bold" />
        </Group>
      );
    });

  const renderDimensions = () =>
    planData.dimensions.map((dim) => {
      const sel = isSelected(dim.id);
      const color = sel ? SELECTED_COLOR : '#94A3B8';
      const len = distance(dim.start, dim.end);
      const angle = Math.atan2(dim.end.y - dim.start.y, dim.end.x - dim.start.x);
      const mid = midpoint(dim.start, dim.end);
      const offX = -Math.sin(angle) * dim.offset;
      const offY = Math.cos(angle) * dim.offset;

      return (
        <Group key={dim.id} id={dim.id}>
          {/* Dimension line */}
          <Line points={[dim.start.x + offX, dim.start.y + offY, dim.end.x + offX, dim.end.y + offY]} stroke={color} strokeWidth={1} />
          {/* Extension lines */}
          <Line points={[dim.start.x, dim.start.y, dim.start.x + offX, dim.start.y + offY]} stroke={color} strokeWidth={0.5} />
          <Line points={[dim.end.x, dim.end.y, dim.end.x + offX, dim.end.y + offY]} stroke={color} strokeWidth={0.5} />
          {/* Measurement text */}
          <Text
            x={mid.x + offX - 20}
            y={mid.y + offY - 14}
            text={formatLength(len, units)}
            fontSize={11}
            fontFamily="Inter, sans-serif"
            fill={color}
            width={40}
            align="center"
            listening={false}
          />
        </Group>
      );
    });

  const renderRoomLabels = () =>
    planData.rooms.map((room) => (
      <Group key={room.id} x={room.center.x} y={room.center.y} listening={false}>
        <Rect x={-45} y={-14} width={90} height={28} fill="#FFFFFF" opacity={0.85} cornerRadius={4} />
        <Text x={-45} y={-12} width={90} align="center" text={room.name} fontSize={11} fontFamily="Inter, sans-serif" fill="#1E293B" fontStyle="bold" />
        <Text x={-45} y={1} width={90} align="center" text={formatArea(room.area, units)} fontSize={9} fontFamily="Inter, sans-serif" fill="#64748B" />
      </Group>
    ));

  // =========================================================================
  // TRADE LAYER RENDERING
  // =========================================================================

  const renderTradeLayers = () =>
    planData.tradeLayers.map((layer) => {
      if (!layer.visible) return null;
      return (
        <Group key={layer.id} opacity={layer.opacity}>
          {/* Trade elements */}
          {layer.tradeData?.elements.map((el) => {
            const color = TRADE_COLORS[layer.type] ?? '#6B7280';
            return (
              <Group key={el.id} id={el.id} x={el.position.x} y={el.position.y} rotation={el.rotation}>
                <Circle radius={8} stroke={color} strokeWidth={1.5} />
                <Text text={el.type.slice(0, 2).toUpperCase()} x={-6} y={-5} fontSize={8} fill={color} fontFamily="Inter" fontStyle="bold" />
                {el.label && <Text text={el.label} x={-20} y={12} fontSize={9} fill={color} fontFamily="Inter" width={40} align="center" />}
              </Group>
            );
          })}
          {/* Trade paths */}
          {layer.tradeData?.paths.map((path) => {
            const flatPts = path.points.flatMap((p) => [p.x, p.y]);
            const color = PATH_COLORS[path.type] ?? '#6B7280';
            return (
              <Line
                key={path.id}
                id={path.id}
                points={flatPts}
                stroke={color}
                strokeWidth={path.strokeWidth}
                lineCap="round"
                lineJoin="round"
                dash={path.type === 'gas' ? [8, 4] : undefined}
                hitStrokeWidth={Math.max(path.strokeWidth, 8)}
              />
            );
          })}
          {/* Damage zones */}
          {layer.damageData?.zones.map((zone) => {
            const flatPts = zone.points.flatMap((p) => [p.x, p.y]);
            const fillColor = DAMAGE_CAT_COLORS[zone.iicrcCategory] ?? '#6B7280';
            const strokeColor = DAMAGE_CLASS_COLORS[zone.damageClass] ?? '#6B7280';
            const cx = zone.points.reduce((s, p) => s + p.x, 0) / zone.points.length;
            const cy = zone.points.reduce((s, p) => s + p.y, 0) / zone.points.length;
            return (
              <Group key={zone.id} id={zone.id}>
                <Line points={flatPts} fill={fillColor} opacity={0.15} closed listening={false} />
                <Line points={flatPts} stroke={strokeColor} strokeWidth={2} closed dash={[6, 4]} />
                <Text x={cx - 20} y={cy - 6} text={zone.label ?? `C${zone.damageClass}/Cat${zone.iicrcCategory}`} fontSize={10} fill={strokeColor} fontFamily="Inter" fontStyle="bold" width={40} align="center" listening={false} />
              </Group>
            );
          })}
          {/* Moisture readings */}
          {layer.damageData?.moistureReadings.map((reading) => {
            const color = moistureSeverityColor(reading.value);
            const radius = 8 + Math.min(reading.value / 10, 6);
            return (
              <Group key={reading.id} id={reading.id} x={reading.position.x} y={reading.position.y}>
                <Circle radius={radius + 4} fill={color} opacity={0.15} listening={false} />
                <Circle radius={radius} fill={color} opacity={0.4} stroke={color} strokeWidth={1} />
                <Text text={`${reading.value}%`} x={-10} y={-5} fontSize={9} fill="#FFF" fontFamily="Inter" fontStyle="bold" width={20} align="center" listening={false} />
                <Text text={reading.material} x={-15} y={radius + 4} fontSize={8} fill={color} fontFamily="Inter" width={30} align="center" listening={false} />
              </Group>
            );
          })}
          {/* Containment lines */}
          {layer.damageData?.containmentLines.map((line) => (
            <Group key={line.id} id={line.id}>
              <Line points={[line.start.x, line.start.y, line.end.x, line.end.y]} stroke="#EF4444" strokeWidth={2} dash={[10, 5]} lineCap="round" />
              <Circle x={(line.start.x + line.end.x) / 2} y={(line.start.y + line.end.y) / 2} radius={6} fill="#EF4444" opacity={0.3} listening={false} />
            </Group>
          ))}
          {/* Barrier equipment */}
          {layer.damageData?.barriers.map((barrier) => (
            <Group key={barrier.id} id={barrier.id} x={barrier.position.x} y={barrier.position.y} rotation={barrier.rotation}>
              <Rect x={-14} y={-8} width={28} height={16} stroke="#EF4444" strokeWidth={1.5} cornerRadius={3} fill="#EF4444" opacity={0.1} />
              <Text text={barrier.type.slice(0, 2).toUpperCase()} x={-14} y={-4} fontSize={8} fill="#EF4444" fontFamily="Inter" fontStyle="bold" width={28} align="center" />
            </Group>
          ))}
        </Group>
      );
    });

  // =========================================================================
  // UI OVERLAY
  // =========================================================================

  const renderGhost = () => {
    if (!drawStart || !ghostEnd) return null;
    return (
      <Line
        points={[drawStart.x, drawStart.y, ghostEnd.x, ghostEnd.y]}
        stroke={GHOST_COLOR}
        strokeWidth={editorState.wallThickness}
        dash={[8, 4]}
        lineCap="round"
        listening={false}
      />
    );
  };

  const renderSnapIndicator = () => {
    if (!snapPoint) return null;
    return (
      <Group listening={false}>
        <Line points={[snapPoint.x - 8, snapPoint.y, snapPoint.x + 8, snapPoint.y]} stroke={SELECTED_COLOR} strokeWidth={1} />
        <Line points={[snapPoint.x, snapPoint.y - 8, snapPoint.x, snapPoint.y + 8]} stroke={SELECTED_COLOR} strokeWidth={1} />
      </Group>
    );
  };

  const renderLasso = () => {
    if (lassoPoints.length < 2) return null;
    const flat = lassoPoints.flatMap((p) => [p.x, p.y]);
    return <Line points={flat} stroke={SELECTED_COLOR} strokeWidth={1} dash={[4, 4]} closed={false} listening={false} opacity={0.7} />;
  };

  // =========================================================================
  // STAGE
  // =========================================================================

  return (
    <Stage
      ref={stageRef}
      width={width}
      height={height}
      onClick={handleStageClick}
      onMouseMove={handleMouseMove}
      onMouseDown={handleMouseDown}
      onMouseUp={handleMouseUp}
      onWheel={handleWheel}
      onDragMove={(e) => {
        const stage = e.target as unknown as Konva.Stage;
        if (stage.x !== undefined) {
          onEditorStateChange({ panOffset: { x: stage.x(), y: stage.y() } });
        }
      }}
      draggable={isPanning || editorState.activeTool === 'pan'}
      style={{ cursor: isPanning ? 'grab' : editorState.activeTool === 'erase' ? 'crosshair' : 'default' }}
    >
      {/* Grid Layer */}
      <Layer listening={false} perfectDrawEnabled={false}>{renderGrid()}</Layer>

      {/* Base Elements Layer */}
      <Layer>
        {renderWalls()}
        {renderArcWalls()}
        {renderDoors()}
        {renderWindows()}
        {renderFixtures()}
        {renderLabels()}
        {renderDimensions()}
        {renderRoomLabels()}
      </Layer>

      {/* Trade Overlay Layer */}
      <Layer>{renderTradeLayers()}</Layer>

      {/* UI Overlay Layer */}
      <Layer listening={false} perfectDrawEnabled={false}>
        {renderGhost()}
        {renderSnapIndicator()}
        {renderLasso()}
      </Layer>
    </Stage>
  );
}
