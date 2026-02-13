// ZAFTO Room Measurement Calculator — SK8 (TypeScript Port)
// Computes per-room measurements from FloorPlanData geometry.
// Used by GenerateEstimateModal to preview measurements before creating estimate.

import type { FloorPlanData, DetectedRoom, Wall, Point } from './types';

// =============================================================================
// TYPES
// =============================================================================

export interface WallMeasurement {
  wallId: string;
  lengthInches: number;
  heightInches: number;
  grossSf: number;
  netSf: number;
  doorsOnWall: number;
  windowsOnWall: number;
}

export interface RoomMeasurements {
  roomId: string;
  roomName: string;
  floorSf: number;
  wallSf: number;
  ceilingSf: number;
  baseboardLf: number;
  perimeterLf: number;
  doorCount: number;
  windowCount: number;
  paintSfWallsOnly: number;
  paintSfCeilingOnly: number;
  paintSfBoth: number;
  wallHeight: number; // inches
  wallDetails: WallMeasurement[];
}

// =============================================================================
// CONSTANTS
// =============================================================================

const DEFAULT_DOOR_HEIGHT = 80; // 6'8"
const DEFAULT_WINDOW_HEIGHT = 48; // 4'0"
const SNAP_THRESHOLD = 6; // pixels/inches

// =============================================================================
// CALCULATOR
// =============================================================================

export function calculateAllRooms(planData: FloorPlanData): RoomMeasurements[] {
  return planData.rooms
    .map((room) => calculateRoom(room, planData))
    .filter((m): m is RoomMeasurements => m !== null);
}

export function calculateRoom(
  room: DetectedRoom,
  planData: FloorPlanData,
): RoomMeasurements | null {
  // Get boundary walls
  const boundaryWalls = room.wallIds
    .map((id) => planData.walls.find((w) => w.id === id))
    .filter((w): w is Wall => w !== undefined);

  if (boundaryWalls.length < 3) return null;

  // Build ordered polygon
  const polygon = buildOrderedPolygon(boundaryWalls);
  if (polygon.length < 3) return null;

  // Floor area (sq inches → sq ft)
  const floorSqInches = shoelaceArea(polygon);
  const floorSf = floorSqInches / 144;

  // Get doors/windows on boundary walls
  const roomDoors = planData.doors.filter((d) =>
    room.wallIds.includes(d.wallId),
  );
  const roomWindows = planData.windows.filter((w) =>
    room.wallIds.includes(w.wallId),
  );

  // Per-wall measurements
  const wallDetails: WallMeasurement[] = [];
  let totalWallSf = 0;
  let totalPerimeter = 0;
  let totalDoorWidth = 0;

  for (const wall of boundaryWalls) {
    const lengthInches = wallLength(wall);
    const heightInches = wall.height;

    const grossSf = (lengthInches * heightInches) / 144;

    // Door openings
    const doorsOnWall = roomDoors.filter((d) => d.wallId === wall.id);
    let doorOpeningSf = 0;
    for (const door of doorsOnWall) {
      doorOpeningSf += (door.width * DEFAULT_DOOR_HEIGHT) / 144;
      totalDoorWidth += door.width;
    }

    // Window openings
    const windowsOnWall = roomWindows.filter((w) => w.wallId === wall.id);
    let windowOpeningSf = 0;
    for (const win of windowsOnWall) {
      windowOpeningSf += (win.width * DEFAULT_WINDOW_HEIGHT) / 144;
    }

    const netSf = Math.max(0, grossSf - doorOpeningSf - windowOpeningSf);

    wallDetails.push({
      wallId: wall.id,
      lengthInches,
      heightInches,
      grossSf,
      netSf,
      doorsOnWall: doorsOnWall.length,
      windowsOnWall: windowsOnWall.length,
    });

    totalWallSf += netSf;
    totalPerimeter += lengthInches;
  }

  const ceilingSf = floorSf;
  const perimeterLf = totalPerimeter / 12;
  const baseboardLf = Math.max(0, (totalPerimeter - totalDoorWidth) / 12);

  const avgHeight =
    boundaryWalls.length > 0
      ? boundaryWalls.reduce((sum, w) => sum + w.height, 0) /
        boundaryWalls.length
      : 96;

  return {
    roomId: room.id,
    roomName: room.name,
    floorSf: round2(floorSf),
    wallSf: round2(totalWallSf),
    ceilingSf: round2(ceilingSf),
    baseboardLf: round2(baseboardLf),
    perimeterLf: round2(perimeterLf),
    doorCount: roomDoors.length,
    windowCount: roomWindows.length,
    paintSfWallsOnly: round2(totalWallSf),
    paintSfCeilingOnly: round2(ceilingSf),
    paintSfBoth: round2(totalWallSf + ceilingSf),
    wallHeight: avgHeight,
    wallDetails,
  };
}

// =============================================================================
// GEOMETRY HELPERS
// =============================================================================

function buildOrderedPolygon(walls: Wall[]): Point[] {
  if (walls.length === 0) return [];

  const ordered: Point[] = [];
  const used = new Set<number>();

  ordered.push(walls[0].start);
  used.add(0);
  let nextPoint = walls[0].end;

  for (let i = 0; i < walls.length - 1; i++) {
    ordered.push(nextPoint);

    let nextIdx: number | null = null;
    let newNext: Point | null = null;

    for (let j = 0; j < walls.length; j++) {
      if (used.has(j)) continue;
      if (closeEnough(walls[j].start, nextPoint)) {
        nextIdx = j;
        newNext = walls[j].end;
        break;
      }
      if (closeEnough(walls[j].end, nextPoint)) {
        nextIdx = j;
        newNext = walls[j].start;
        break;
      }
    }

    if (nextIdx === null || newNext === null) break;
    used.add(nextIdx);
    nextPoint = newNext;
  }

  return ordered;
}

function shoelaceArea(points: Point[]): number {
  if (points.length < 3) return 0;
  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }
  return Math.abs(area / 2);
}

function wallLength(wall: Wall): number {
  const dx = wall.end.x - wall.start.x;
  const dy = wall.end.y - wall.start.y;
  return Math.sqrt(dx * dx + dy * dy);
}

function closeEnough(a: Point, b: Point): boolean {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return dx * dx + dy * dy <= SNAP_THRESHOLD * SNAP_THRESHOLD;
}

function round2(v: number): number {
  return Math.round(v * 100) / 100;
}

// =============================================================================
// FORMAT HELPERS
// =============================================================================

export function formatSf(sf: number): string {
  return `${sf.toFixed(1)} SF`;
}

export function formatLf(lf: number): string {
  return `${lf.toFixed(1)} LF`;
}

export function formatDimension(inches: number, units: 'imperial' | 'metric'): string {
  if (units === 'metric') {
    const cm = inches * 2.54;
    if (cm >= 100) return `${(cm / 100).toFixed(2)}m`;
    return `${cm.toFixed(1)}cm`;
  }
  const ft = Math.floor(inches / 12);
  const remainInches = Math.round(inches % 12);
  if (ft === 0) return `${remainInches}"`;
  if (remainInches === 0) return `${ft}'`;
  return `${ft}'${remainInches}"`;
}
