// ZAFTO Snap-to-Guide System (SK14)
// Smart guides for wall alignment, perpendicular snap, equal spacing,
// centerline snap, and configurable grid snap.

import type { Point, Wall, FixturePlacement } from './types';

export type SnapGridSize = 1 | 6 | 12 | 24; // inches

export interface SnapResult {
  snapped: Point;
  guide: SnapGuide | null;
}

export interface SnapGuide {
  type: 'horizontal' | 'vertical' | 'perpendicular' | 'centerline' | 'equalSpacing';
  from: Point;
  to: Point;
  label?: string;
}

/** Snap a point to the nearest grid intersection */
export function snapToGrid(pt: Point, gridSize: number): Point {
  return {
    x: Math.round(pt.x / gridSize) * gridSize,
    y: Math.round(pt.y / gridSize) * gridSize,
  };
}

/** Find alignment guides from existing walls */
export function findAlignmentGuides(
  pt: Point,
  walls: Wall[],
  threshold: number = 8,
): SnapGuide[] {
  const guides: SnapGuide[] = [];

  for (const wall of walls) {
    // Horizontal alignment with wall endpoints
    for (const endpoint of [wall.start, wall.end]) {
      if (Math.abs(pt.y - endpoint.y) < threshold) {
        guides.push({
          type: 'horizontal',
          from: { x: Math.min(pt.x, endpoint.x) - 50, y: endpoint.y },
          to: { x: Math.max(pt.x, endpoint.x) + 50, y: endpoint.y },
        });
      }
      if (Math.abs(pt.x - endpoint.x) < threshold) {
        guides.push({
          type: 'vertical',
          from: { x: endpoint.x, y: Math.min(pt.y, endpoint.y) - 50 },
          to: { x: endpoint.x, y: Math.max(pt.y, endpoint.y) + 50 },
        });
      }
    }

    // Perpendicular snap (90 degree angle) to wall midpoint
    const mid = {
      x: (wall.start.x + wall.end.x) / 2,
      y: (wall.start.y + wall.end.y) / 2,
    };
    const dx = wall.end.x - wall.start.x;
    const dy = wall.end.y - wall.start.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len > 0) {
      // Normal direction
      const nx = -dy / len;
      const ny = dx / len;
      // Project point onto perpendicular from midpoint
      const dot = (pt.x - mid.x) * nx + (pt.y - mid.y) * ny;
      const projX = mid.x + dot * nx;
      const projY = mid.y + dot * ny;
      const dist = Math.sqrt((pt.x - projX) ** 2 + (pt.y - projY) ** 2);
      if (dist < threshold) {
        guides.push({
          type: 'perpendicular',
          from: mid,
          to: { x: projX, y: projY },
          label: '90°',
        });
      }
    }
  }

  return guides;
}

/** Find centerline snap for walls */
export function findCenterlineSnap(
  pt: Point,
  walls: Wall[],
  threshold: number = 8,
): SnapGuide | null {
  for (const wall of walls) {
    const midX = (wall.start.x + wall.end.x) / 2;
    const midY = (wall.start.y + wall.end.y) / 2;

    // Snap to wall midpoint
    const dist = Math.sqrt((pt.x - midX) ** 2 + (pt.y - midY) ** 2);
    if (dist < threshold) {
      return {
        type: 'centerline',
        from: wall.start,
        to: wall.end,
        label: 'center',
      };
    }
  }
  return null;
}

/** Find equal spacing guides between fixtures */
export function findEqualSpacingGuide(
  pt: Point,
  fixtures: FixturePlacement[],
  threshold: number = 8,
): SnapGuide | null {
  if (fixtures.length < 2) return null;

  // Check pairs for equal spacing opportunity
  for (let i = 0; i < fixtures.length; i++) {
    for (let j = i + 1; j < fixtures.length; j++) {
      const a = fixtures[i].position;
      const b = fixtures[j].position;
      const spacing = Math.sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2);

      // Check if pt is at equal spacing from fixture b
      const expectedX = b.x + (b.x - a.x);
      const expectedY = b.y + (b.y - a.y);
      const dist = Math.sqrt((pt.x - expectedX) ** 2 + (pt.y - expectedY) ** 2);

      if (dist < threshold) {
        return {
          type: 'equalSpacing',
          from: b,
          to: { x: expectedX, y: expectedY },
          label: `=${Math.round(spacing)}`,
        };
      }
    }
  }
  return null;
}

/** Apply all snaps and return the best result */
export function applySmartSnap(
  pt: Point,
  walls: Wall[],
  fixtures: FixturePlacement[],
  gridSize: number,
  useGrid: boolean,
  threshold: number = 8,
): SnapResult {
  // Priority: 1. Alignment guides, 2. Centerline, 3. Equal spacing, 4. Grid
  const alignGuides = findAlignmentGuides(pt, walls, threshold);
  if (alignGuides.length > 0) {
    const guide = alignGuides[0];
    const snapped = guide.type === 'horizontal'
      ? { x: pt.x, y: guide.from.y }
      : guide.type === 'vertical'
      ? { x: guide.from.x, y: pt.y }
      : guide.to;
    return { snapped, guide };
  }

  const center = findCenterlineSnap(pt, walls, threshold);
  if (center) {
    const midX = (center.from.x + center.to.x) / 2;
    const midY = (center.from.y + center.to.y) / 2;
    return { snapped: { x: midX, y: midY }, guide: center };
  }

  const equal = findEqualSpacingGuide(pt, fixtures, threshold);
  if (equal) {
    return { snapped: equal.to, guide: equal };
  }

  if (useGrid) {
    return { snapped: snapToGrid(pt, gridSize), guide: null };
  }

  return { snapped: pt, guide: null };
}
