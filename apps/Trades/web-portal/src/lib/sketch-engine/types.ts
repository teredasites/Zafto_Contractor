// ZAFTO Sketch Engine — TypeScript Types (SK6)
// Ported from lib/models/floor_plan_elements.dart + trade_layer.dart
// Full type parity with Flutter V2 data model.

// =============================================================================
// POINT / OFFSET
// =============================================================================

export interface Point {
  x: number;
  y: number;
}

// =============================================================================
// ENUMS
// =============================================================================

export type DoorType =
  | 'single'
  | 'double'
  | 'sliding'
  | 'pocket'
  | 'bifold'
  | 'barn'
  | 'french';

export type WindowType = 'standard' | 'bay' | 'skylight';

export type FixtureType =
  | 'toilet'
  | 'sink'
  | 'bathtub'
  | 'shower'
  | 'stove'
  | 'refrigerator'
  | 'dishwasher'
  | 'washer'
  | 'dryer'
  | 'waterHeater'
  | 'furnace'
  | 'hvacUnit'
  | 'electricPanel'
  | 'sofa'
  | 'table'
  | 'bed'
  | 'desk'
  | 'fireplace'
  | 'stairs'
  | 'column'
  | 'closetRod'
  | 'shelvingUnit'
  | 'island'
  | 'builtInBookshelf'
  | 'laundryTub';

export type MeasurementUnit = 'imperial' | 'metric';

export type SketchTool =
  | 'select'
  | 'wall'
  | 'arcWall'
  | 'door'
  | 'window'
  | 'fixture'
  | 'label'
  | 'dimension'
  | 'lasso'
  | 'erase'
  | 'pan';

// =============================================================================
// CORE ELEMENTS
// =============================================================================

export interface Wall {
  id: string;
  start: Point;
  end: Point;
  thickness: number; // inches
  height: number; // inches
}

export interface ArcWall {
  id: string;
  start: Point;
  end: Point;
  controlPoint: Point;
  thickness: number;
  height: number;
}

export interface DoorPlacement {
  id: string;
  wallId: string;
  position: number; // 0-1 parametric position along wall
  width: number; // inches
  type: DoorType;
  swingAngle?: number;
  flipSide?: boolean;
}

export interface WindowPlacement {
  id: string;
  wallId: string;
  position: number; // 0-1 parametric position
  width: number; // inches
  type: WindowType;
  sillHeight?: number;
}

export interface FixturePlacement {
  id: string;
  position: Point;
  type: FixtureType;
  rotation: number; // degrees
  width?: number;
  depth?: number;
}

export interface FloorLabel {
  id: string;
  position: Point;
  text: string;
  fontSize: number;
  rotation: number;
}

export interface DimensionLine {
  id: string;
  start: Point;
  end: Point;
  offset: number;
  isAuto: boolean;
}

export interface DetectedRoom {
  id: string;
  name: string;
  wallIds: string[];
  center: Point;
  area: number; // sq ft
}

// =============================================================================
// TRADE LAYER TYPES
// =============================================================================

export type TradeLayerType = 'electrical' | 'plumbing' | 'hvac' | 'damage';

export type TradeSymbolType =
  // Electrical
  | 'outlet' | 'outletGFCI' | 'outletDedicated' | 'outletFloor'
  | 'switchSingle' | 'switchThreeWay' | 'switchDimmer'
  | 'lightCeiling' | 'lightRecessed' | 'lightWall' | 'lightFluorescent' | 'lightEmergency'
  | 'panelMain' | 'panelSub' | 'junction' | 'meter' | 'disconnect' | 'transformer'
  | 'smokeDetector' | 'coDetector' | 'thermostat' | 'doorbell' | 'cameraLocation'
  | 'fan' | 'fanExhaust' | 'generator'
  // Plumbing
  | 'valve' | 'valveShutoff' | 'valveCheck' | 'cleanout' | 'backflow'
  | 'floorDrain' | 'vent' | 'hosebibb' | 'waterMeter' | 'pressureReducer'
  | 'expansion' | 'trap' | 'tee'
  // HVAC
  | 'supplyRegister' | 'returnRegister' | 'diffuser' | 'damper' | 'thermostatHvac'
  | 'condenser' | 'airHandler' | 'heatPump' | 'exhaust' | 'minisplit'
  | 'ductSplit' | 'ductElbow';

export type TradePathType =
  | 'wire' | 'pipe_hot' | 'pipe_cold' | 'drain' | 'gas'
  | 'duct_supply' | 'duct_return';

export interface TradeElement {
  id: string;
  type: TradeSymbolType;
  position: Point;
  rotation: number;
  label?: string;
}

export interface TradePath {
  id: string;
  type: TradePathType;
  points: Point[];
  strokeWidth: number;
}

export interface DamageZone {
  id: string;
  points: Point[];
  damageClass: string; // '1'-'4'
  iicrcCategory: string; // '1'-'3'
  label?: string;
}

export interface MoistureReading {
  id: string;
  position: Point;
  value: number; // percentage
  material: string;
  timestamp: string;
}

export type BarrierType =
  | 'dehumidifier' | 'airMover' | 'airScrubber' | 'heater'
  | 'containmentPole' | 'negativePressure' | 'moistureTrap' | 'thermometer';

export interface ContainmentLine {
  id: string;
  start: Point;
  end: Point;
  barrierType: BarrierType;
}

export interface TradeLayerData {
  elements: TradeElement[];
  paths: TradePath[];
}

export interface DamageLayerData {
  zones: DamageZone[];
  moistureReadings: MoistureReading[];
  containmentLines: ContainmentLine[];
  barriers: TradeElement[];
}

export interface TradeLayer {
  id: string;
  type: TradeLayerType;
  name: string;
  visible: boolean;
  locked: boolean;
  opacity: number;
  tradeData?: TradeLayerData;
  damageData?: DamageLayerData;
}

// =============================================================================
// FLOOR PLAN DATA — Top-level container
// =============================================================================

export interface FloorPlanData {
  walls: Wall[];
  arcWalls: ArcWall[];
  doors: DoorPlacement[];
  windows: WindowPlacement[];
  fixtures: FixturePlacement[];
  labels: FloorLabel[];
  dimensions: DimensionLine[];
  rooms: DetectedRoom[];
  tradeLayers: TradeLayer[];
  scale: number;
  units: MeasurementUnit;
}

export function createEmptyFloorPlan(): FloorPlanData {
  return {
    walls: [],
    arcWalls: [],
    doors: [],
    windows: [],
    fixtures: [],
    labels: [],
    dimensions: [],
    rooms: [],
    tradeLayers: [],
    scale: 4.0,
    units: 'imperial',
  };
}

// =============================================================================
// SELECTION STATE
// =============================================================================

export interface SelectionState {
  selectedId: string | null;
  selectedType: string | null;
  multiSelectedIds: Set<string>;
  multiSelectedTypes: Map<string, string>;
}

export function createEmptySelection(): SelectionState {
  return {
    selectedId: null,
    selectedType: null,
    multiSelectedIds: new Set(),
    multiSelectedTypes: new Map(),
  };
}

// =============================================================================
// EDITOR STATE
// =============================================================================

export interface EditorState {
  activeTool: SketchTool;
  activeLayerId: string | null; // null = base layer
  isDrawing: boolean;
  ghostStart: Point | null;
  ghostEnd: Point | null;
  snapIndicator: Point | null;
  zoom: number;
  panOffset: Point;
  showGrid: boolean;
  gridSize: number;
  wallThickness: number;
  doorType: DoorType;
  doorWidth: number;
  windowType: WindowType;
  windowWidth: number;
  pendingFixtureType: FixtureType | null;
  units: MeasurementUnit;
}

export function createDefaultEditorState(): EditorState {
  return {
    activeTool: 'wall',
    activeLayerId: null,
    isDrawing: false,
    ghostStart: null,
    ghostEnd: null,
    snapIndicator: null,
    zoom: 1.0,
    panOffset: { x: 0, y: 0 },
    showGrid: true,
    gridSize: 12, // 1 foot
    wallThickness: 6,
    doorType: 'single',
    doorWidth: 36,
    windowType: 'standard',
    windowWidth: 36,
    pendingFixtureType: null,
    units: 'imperial',
  };
}
