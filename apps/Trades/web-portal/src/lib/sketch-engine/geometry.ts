// ZAFTO Sketch Geometry Engine — SK6
// Port of SketchGeometry from floor_plan_elements.dart
// Angle snapping, endpoint snapping, point-to-segment distance,
// line intersection, room detection (DFS cycle + shoelace area).

import type { Point, Wall, ArcWall, DetectedRoom } from './types';

// =============================================================================
// CONSTANTS
// =============================================================================

const SNAP_THRESHOLD = 12; // pixels
const ANGLE_SNAP_DEGREES = 15;
const PI = Math.PI;

// =============================================================================
// VECTOR MATH
// =============================================================================

export function distance(a: Point, b: Point): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  return Math.sqrt(dx * dx + dy * dy);
}

export function midpoint(a: Point, b: Point): Point {
  return { x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 };
}

export function lerp(a: Point, b: Point, t: number): Point {
  return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t };
}

export function wallLength(wall: Wall): number {
  return distance(wall.start, wall.end);
}

export function wallAngle(wall: Wall): number {
  return Math.atan2(wall.end.y - wall.start.y, wall.end.x - wall.start.x);
}

// =============================================================================
// ANGLE SNAPPING
// =============================================================================

/** Snap an angle to the nearest multiple of ANGLE_SNAP_DEGREES */
export function snapAngle(startPt: Point, endPt: Point): Point {
  const dx = endPt.x - startPt.x;
  const dy = endPt.y - startPt.y;
  const len = Math.sqrt(dx * dx + dy * dy);
  if (len < 1) return endPt;

  const rawAngle = Math.atan2(dy, dx);
  const snapRadians = (ANGLE_SNAP_DEGREES * PI) / 180;
  const snappedAngle = Math.round(rawAngle / snapRadians) * snapRadians;

  return {
    x: startPt.x + len * Math.cos(snappedAngle),
    y: startPt.y + len * Math.sin(snappedAngle),
  };
}

// =============================================================================
// ENDPOINT SNAPPING
// =============================================================================

/** Find nearest wall endpoint within threshold */
export function snapToEndpoint(
  pt: Point,
  walls: Wall[],
  arcWalls: ArcWall[],
  threshold: number = SNAP_THRESHOLD,
): Point | null {
  let bestDist = threshold;
  let best: Point | null = null;

  for (const wall of walls) {
    const dStart = distance(pt, wall.start);
    if (dStart < bestDist) {
      bestDist = dStart;
      best = wall.start;
    }
    const dEnd = distance(pt, wall.end);
    if (dEnd < bestDist) {
      bestDist = dEnd;
      best = wall.end;
    }
  }

  for (const arc of arcWalls) {
    const dStart = distance(pt, arc.start);
    if (dStart < bestDist) {
      bestDist = dStart;
      best = arc.start;
    }
    const dEnd = distance(pt, arc.end);
    if (dEnd < bestDist) {
      bestDist = dEnd;
      best = arc.end;
    }
  }

  return best;
}

/** Snap to grid */
export function snapToGrid(pt: Point, gridSize: number): Point {
  return {
    x: Math.round(pt.x / gridSize) * gridSize,
    y: Math.round(pt.y / gridSize) * gridSize,
  };
}

// =============================================================================
// POINT-TO-SEGMENT DISTANCE
// =============================================================================

/** Minimum distance from point to line segment */
export function pointToSegmentDistance(
  p: Point,
  a: Point,
  b: Point,
): number {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq < 0.001) return distance(p, a);

  let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const proj: Point = { x: a.x + t * dx, y: a.y + t * dy };
  return distance(p, proj);
}

/** Project point onto wall, returning parametric t (0-1) */
export function projectOntoWall(pt: Point, wall: Wall): number {
  const dx = wall.end.x - wall.start.x;
  const dy = wall.end.y - wall.start.y;
  const lenSq = dx * dx + dy * dy;
  if (lenSq < 0.001) return 0.5;

  const t =
    ((pt.x - wall.start.x) * dx + (pt.y - wall.start.y) * dy) / lenSq;
  return Math.max(0, Math.min(1, t));
}

// =============================================================================
// LINE INTERSECTION
// =============================================================================

/** Find intersection of two line segments, returns null if parallel/no intersection */
export function segmentIntersection(
  a1: Point,
  a2: Point,
  b1: Point,
  b2: Point,
): Point | null {
  const d1x = a2.x - a1.x;
  const d1y = a2.y - a1.y;
  const d2x = b2.x - b1.x;
  const d2y = b2.y - b1.y;

  const denom = d1x * d2y - d1y * d2x;
  if (Math.abs(denom) < 0.001) return null;

  const t = ((b1.x - a1.x) * d2y - (b1.y - a1.y) * d2x) / denom;
  const u = ((b1.x - a1.x) * d1y - (b1.y - a1.y) * d1x) / denom;

  if (t < 0 || t > 1 || u < 0 || u > 1) return null;

  return {
    x: a1.x + t * d1x,
    y: a1.y + t * d1y,
  };
}

// =============================================================================
// WALL SPLITTING
// =============================================================================

/** Get position on a wall at parametric t */
export function positionOnWall(wall: Wall, t: number): Point {
  return lerp(wall.start, wall.end, t);
}

// =============================================================================
// HIT TESTING
// =============================================================================

/** Find wall nearest to point within threshold */
export function findNearestWall(
  pt: Point,
  walls: Wall[],
  threshold: number = 12,
): Wall | null {
  let best: Wall | null = null;
  let bestDist = threshold;

  for (const wall of walls) {
    const d = pointToSegmentDistance(pt, wall.start, wall.end);
    if (d < bestDist) {
      bestDist = d;
      best = wall;
    }
  }

  return best;
}

/** Check if point is inside polygon (ray casting) */
export function pointInPolygon(pt: Point, polygon: Point[]): boolean {
  let inside = false;
  const n = polygon.length;

  for (let i = 0, j = n - 1; i < n; j = i++) {
    const xi = polygon[i].x;
    const yi = polygon[i].y;
    const xj = polygon[j].x;
    const yj = polygon[j].y;

    if (
      yi > pt.y !== yj > pt.y &&
      pt.x < ((xj - xi) * (pt.y - yi)) / (yj - yi) + xi
    ) {
      inside = !inside;
    }
  }

  return inside;
}

// =============================================================================
// ROOM DETECTION (DFS cycle detection + Shoelace area)
// =============================================================================

interface AdjEntry {
  wallId: string;
  otherEndpoint: string;
}

function ptKey(p: Point): string {
  return `${Math.round(p.x * 10) / 10},${Math.round(p.y * 10) / 10}`;
}

/** Detect rooms from connected walls using DFS cycle detection */
export function detectRooms(walls: Wall[]): DetectedRoom[] {
  if (walls.length < 3) return [];

  // Build adjacency graph: endpoint → list of (wallId, otherEndpoint)
  const adj = new Map<string, AdjEntry[]>();

  for (const wall of walls) {
    const sKey = ptKey(wall.start);
    const eKey = ptKey(wall.end);

    if (!adj.has(sKey)) adj.set(sKey, []);
    if (!adj.has(eKey)) adj.set(eKey, []);

    adj.get(sKey)!.push({ wallId: wall.id, otherEndpoint: eKey });
    adj.get(eKey)!.push({ wallId: wall.id, otherEndpoint: sKey });
  }

  const usedWalls = new Set<string>();
  const rooms: DetectedRoom[] = [];
  let roomIndex = 1;

  // For each wall, try to trace a cycle
  for (const wall of walls) {
    if (usedWalls.has(wall.id)) continue;

    const cycleWalls = traceCycle(wall, walls, adj, usedWalls);
    if (cycleWalls && cycleWalls.length >= 3) {
      for (const cw of cycleWalls) usedWalls.add(cw.id);

      // Compute room center and area
      const endpoints = cycleWalls.map((w) => w.start);
      const area = shoelaceArea(endpoints) / 144; // sq inches → sq feet

      if (area > 1) {
        // Skip tiny degenerate rooms
        const cx =
          endpoints.reduce((sum, p) => sum + p.x, 0) / endpoints.length;
        const cy =
          endpoints.reduce((sum, p) => sum + p.y, 0) / endpoints.length;

        rooms.push({
          id: `room_${roomIndex}`,
          name: `Room ${roomIndex}`,
          wallIds: cycleWalls.map((w) => w.id),
          center: { x: cx, y: cy },
          area: Math.abs(area),
        });
        roomIndex++;
      }
    }
  }

  return rooms;
}

function traceCycle(
  startWall: Wall,
  allWalls: Wall[],
  adj: Map<string, AdjEntry[]>,
  usedInRoom: Set<string>,
): Wall[] | null {
  const path: Wall[] = [startWall];
  const visited = new Set<string>([startWall.id]);
  let currentKey = ptKey(startWall.end);
  const targetKey = ptKey(startWall.start);

  for (let step = 0; step < 20; step++) {
    // Max 20 walls per room
    if (currentKey === targetKey && path.length >= 3) {
      return path;
    }

    const neighbors = adj.get(currentKey) ?? [];
    let found = false;

    for (const neighbor of neighbors) {
      if (visited.has(neighbor.wallId)) continue;
      if (usedInRoom.has(neighbor.wallId)) continue;

      const nWall = allWalls.find((w) => w.id === neighbor.wallId);
      if (!nWall) continue;

      path.push(nWall);
      visited.add(nWall.id);
      currentKey = neighbor.otherEndpoint;
      found = true;
      break;
    }

    if (!found) return null;
  }

  return null;
}

/** Shoelace formula for polygon area (in square units) */
export function shoelaceArea(points: Point[]): number {
  let area = 0;
  const n = points.length;

  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }

  return Math.abs(area / 2);
}

// =============================================================================
// MEASUREMENT HELPERS
// =============================================================================

/** Convert inches to display string based on unit */
export function formatLength(
  inches: number,
  unit: 'imperial' | 'metric',
): string {
  if (unit === 'metric') {
    const cm = inches * 2.54;
    if (cm >= 100) {
      return `${(cm / 100).toFixed(2)} m`;
    }
    return `${cm.toFixed(1)} cm`;
  }

  const feet = Math.floor(inches / 12);
  const remainInches = Math.round(inches % 12);
  if (feet === 0) return `${remainInches}"`;
  if (remainInches === 0) return `${feet}'`;
  return `${feet}' ${remainInches}"`;
}

/** Format area in sq ft or sq m */
export function formatArea(
  sqft: number,
  unit: 'imperial' | 'metric',
): string {
  if (unit === 'metric') {
    return `${(sqft * 0.0929).toFixed(1)} m\u00B2`;
  }
  return `${sqft.toFixed(0)} sq ft`;
}
