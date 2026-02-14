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
// SITE PLAN TYPES (SK12) — Exterior property drawing
// =============================================================================

export type SitePlanTool =
  | 'select'
  | 'boundary'
  | 'structure'
  | 'roofPlane'
  | 'fence'
  | 'retainingWall'
  | 'gutter'
  | 'solarRow'
  | 'concrete'
  | 'lawn'
  | 'paver'
  | 'landscape'
  | 'gravel'
  | 'elevation'
  | 'symbol'
  | 'measure'
  | 'label'
  | 'pan'
  | 'erase';

export type RoofPlaneType = 'hip' | 'gable' | 'valley' | 'flat' | 'shed' | 'gambrel' | 'mansard';

export type LinearFeatureType =
  | 'fence' | 'retainingWall' | 'gutter' | 'dripEdge'
  | 'solarRow' | 'edging' | 'downspout';

export type AreaFeatureType =
  | 'concrete' | 'lawn' | 'paver' | 'landscape'
  | 'gravel' | 'pool' | 'deck' | 'driveway';

export type SiteSymbolType =
  | 'treeDeciduous' | 'treeEvergreen' | 'treePalm'
  | 'shrub' | 'utilityBox' | 'acUnit' | 'mailbox'
  | 'lightPole' | 'irrigationHead' | 'downspoutSymbol'
  | 'cleanoutSite' | 'hoseBib' | 'gasMeter' | 'electricMeter' | 'waterShutoff';

export type SitePlanLayerType =
  | 'boundary' | 'structures' | 'roof' | 'fencing'
  | 'hardscape' | 'landscape' | 'utilities' | 'grading';

export interface PropertyBoundary {
  id: string;
  points: Point[];
  totalArea: number; // sq ft (auto-calculated from polygon)
}

export interface StructureOutline {
  id: string;
  points: Point[];
  label: string; // 'Main House', 'Garage', 'Shed', etc.
  roofPitch?: number; // e.g. 6 for 6/12
  floorPlanId?: string; // links to interior floor plan (SK12 item 11)
}

export interface RoofPlane {
  id: string;
  structureId: string;
  points: Point[];
  pitch: number; // rise per 12 inches run
  type: RoofPlaneType;
  wasteFactor: number; // 0-1 (default 0.10)
}

export interface LinearFeature {
  id: string;
  type: LinearFeatureType;
  points: Point[];
  height?: number; // feet (fence height, wall height)
  postSpacing?: number; // feet (fences)
  depth?: number; // inches (retaining wall depth)
}

export interface AreaFeature {
  id: string;
  type: AreaFeatureType;
  points: Point[];
  depth?: number; // inches (concrete slab, mulch, gravel)
  material?: string; // specific material name
}

export interface ElevationMarker {
  id: string;
  position: Point;
  elevation: number; // feet above reference datum
}

export interface SiteSymbol {
  id: string;
  type: SiteSymbolType;
  position: Point;
  rotation: number;
  label?: string;
  canopyRadius?: number; // feet (trees only)
}

export interface SitePlanLayer {
  id: string;
  type: SitePlanLayerType;
  name: string;
  visible: boolean;
  locked: boolean;
  opacity: number;
}

export interface SitePlanData {
  boundary: PropertyBoundary | null;
  structures: StructureOutline[];
  roofPlanes: RoofPlane[];
  linearFeatures: LinearFeature[];
  areaFeatures: AreaFeature[];
  elevationMarkers: ElevationMarker[];
  symbols: SiteSymbol[];
  layers: SitePlanLayer[];
  labels: FloorLabel[]; // reuse FloorLabel for site annotations
  dimensions: DimensionLine[]; // reuse DimensionLine for measurements
  backgroundImageUrl?: string;
  backgroundOpacity: number;
  scale: number;
  units: MeasurementUnit;
}

export function createEmptySitePlan(): SitePlanData {
  return {
    boundary: null,
    structures: [],
    roofPlanes: [],
    linearFeatures: [],
    areaFeatures: [],
    elevationMarkers: [],
    symbols: [],
    layers: [
      { id: 'l-bound', type: 'boundary', name: 'Property Boundary', visible: true, locked: false, opacity: 1 },
      { id: 'l-struct', type: 'structures', name: 'Structures', visible: true, locked: false, opacity: 1 },
      { id: 'l-roof', type: 'roof', name: 'Roof Plans', visible: true, locked: false, opacity: 1 },
      { id: 'l-fence', type: 'fencing', name: 'Fencing', visible: true, locked: false, opacity: 1 },
      { id: 'l-hard', type: 'hardscape', name: 'Hardscape', visible: true, locked: false, opacity: 1 },
      { id: 'l-land', type: 'landscape', name: 'Landscape', visible: true, locked: false, opacity: 1 },
      { id: 'l-util', type: 'utilities', name: 'Utilities', visible: true, locked: false, opacity: 1 },
      { id: 'l-grade', type: 'grading', name: 'Grading', visible: true, locked: false, opacity: 1 },
    ],
    labels: [],
    dimensions: [],
    backgroundOpacity: 0.5,
    scale: 4.0,
    units: 'imperial',
  };
}

// Site plan editor state
export interface SiteEditorState {
  activeTool: SitePlanTool;
  activeLayerId: string | null;
  isDrawing: boolean;
  ghostPoints: Point[]; // polygon being drawn
  snapIndicator: Point | null;
  zoom: number;
  panOffset: Point;
  showGrid: boolean;
  gridSize: number; // 12 = 1 foot
  pendingSymbolType: SiteSymbolType | null;
  pendingLinearType: LinearFeatureType | null;
  pendingAreaType: AreaFeatureType | null;
  units: MeasurementUnit;
}

export function createDefaultSiteEditorState(): SiteEditorState {
  return {
    activeTool: 'select',
    activeLayerId: null,
    isDrawing: false,
    ghostPoints: [],
    snapIndicator: null,
    zoom: 1.0,
    panOffset: { x: 0, y: 0 },
    showGrid: true,
    gridSize: 12,
    pendingSymbolType: null,
    pendingLinearType: null,
    pendingAreaType: null,
    units: 'imperial',
  };
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
