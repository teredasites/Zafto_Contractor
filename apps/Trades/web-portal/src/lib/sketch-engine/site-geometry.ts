// ZAFTO Site Plan Geometry Utilities (SK12)
// Polygon area, perimeter, slope calc, material quantity formulas

import type {
  Point,
  PropertyBoundary,
  StructureOutline,
  RoofPlane,
  LinearFeature,
  AreaFeature,
  ElevationMarker,
} from './types';

// ── Polygon math ──

/** Shoelace formula — signed area of polygon in canvas units² */
function signedPolygonArea(pts: Point[]): number {
  let area = 0;
  for (let i = 0; i < pts.length; i++) {
    const j = (i + 1) % pts.length;
    area += pts[i].x * pts[j].y;
    area -= pts[j].x * pts[i].y;
  }
  return area / 2;
}

/** Polygon area in sq ft (canvas units ÷ scale) */
export function polygonAreaSqFt(pts: Point[], scale: number): number {
  const canvasArea = Math.abs(signedPolygonArea(pts));
  return canvasArea / (scale * scale);
}

/** Polygon perimeter in feet */
export function polygonPerimeterFt(pts: Point[], scale: number): number {
  let perim = 0;
  for (let i = 0; i < pts.length; i++) {
    const j = (i + 1) % pts.length;
    perim += distance(pts[i], pts[j]);
  }
  return perim / scale;
}

/** Centroid of polygon */
export function polygonCentroid(pts: Point[]): Point {
  let cx = 0, cy = 0;
  const a = signedPolygonArea(pts);
  if (Math.abs(a) < 0.001) {
    // Degenerate — average all points
    const sx = pts.reduce((s, p) => s + p.x, 0);
    const sy = pts.reduce((s, p) => s + p.y, 0);
    return { x: sx / pts.length, y: sy / pts.length };
  }
  for (let i = 0; i < pts.length; i++) {
    const j = (i + 1) % pts.length;
    const f = pts[i].x * pts[j].y - pts[j].x * pts[i].y;
    cx += (pts[i].x + pts[j].x) * f;
    cy += (pts[i].y + pts[j].y) * f;
  }
  const d = 6 * a;
  return { x: cx / d, y: cy / d };
}

/** Distance between two points in canvas units */
export function distance(a: Point, b: Point): number {
  return Math.sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2);
}

/** Polyline total length in feet */
export function polylineLengthFt(pts: Point[], scale: number): number {
  let len = 0;
  for (let i = 0; i < pts.length - 1; i++) {
    len += distance(pts[i], pts[i + 1]);
  }
  return len / scale;
}

// ── Boundary calculations ──

export function calcBoundaryArea(b: PropertyBoundary, scale: number): number {
  return polygonAreaSqFt(b.points, scale);
}

export function calcBoundaryPerimeter(b: PropertyBoundary, scale: number): number {
  return polygonPerimeterFt(b.points, scale);
}

/** Boundary area in acres */
export function calcBoundaryAcres(b: PropertyBoundary, scale: number): number {
  return calcBoundaryArea(b, scale) / 43560;
}

// ── Structure calculations ──

export function calcStructureFootprint(s: StructureOutline, scale: number): number {
  return polygonAreaSqFt(s.points, scale);
}

/** Estimated roof area from footprint + pitch */
export function calcRoofAreaFromFootprint(footprintSqFt: number, pitch: number): number {
  // roof factor = sqrt(1 + (pitch/12)^2)
  const factor = Math.sqrt(1 + (pitch / 12) ** 2);
  return footprintSqFt * factor;
}

// ── Roof plane calculations ──

export function calcRoofPlaneArea(rp: RoofPlane, scale: number): number {
  const flatArea = polygonAreaSqFt(rp.points, scale);
  const factor = Math.sqrt(1 + (rp.pitch / 12) ** 2);
  return flatArea * factor;
}

export function calcRoofPlaneWithWaste(rp: RoofPlane, scale: number): number {
  return calcRoofPlaneArea(rp, scale) * (1 + rp.wasteFactor);
}

/** Roof squares = area / 100 */
export function calcRoofSquares(areaSqFt: number): number {
  return areaSqFt / 100;
}

/** Edge lengths of a roof plane polygon in feet */
export function calcRoofEdgeLengths(rp: RoofPlane, scale: number): number[] {
  const lengths: number[] = [];
  for (let i = 0; i < rp.points.length; i++) {
    const j = (i + 1) % rp.points.length;
    lengths.push(distance(rp.points[i], rp.points[j]) / scale);
  }
  return lengths;
}

// ── Linear feature calculations ──

export function calcLinearLength(f: LinearFeature, scale: number): number {
  return polylineLengthFt(f.points, scale);
}

/** Fence: post count = total length / spacing + 1 */
export function calcFencePostCount(lengthFt: number, spacingFt: number): number {
  if (spacingFt <= 0) return 0;
  return Math.ceil(lengthFt / spacingFt) + 1;
}

/** Fence: rail count = (posts - 1) * rails per section */
export function calcFenceRailCount(postCount: number, railsPerSection: number): number {
  return Math.max(0, postCount - 1) * railsPerSection;
}

/** Fence: picket count = total length (inches) / picket width (inches) */
export function calcPicketCount(lengthFt: number, picketWidthInches: number): number {
  if (picketWidthInches <= 0) return 0;
  return Math.ceil((lengthFt * 12) / picketWidthInches);
}

/** Retaining wall: cubic yards = length × height × depth / 27 */
export function calcRetainingWallCuYd(lengthFt: number, heightFt: number, depthFt: number): number {
  return (lengthFt * heightFt * depthFt) / 27;
}

/** Gutter: downspout count = 1 per 30-40 ft */
export function calcDownspoutCount(gutterLengthFt: number, spacingFt: number = 35): number {
  return Math.max(1, Math.ceil(gutterLengthFt / spacingFt));
}

/** Gutter: hanger count = 1 per 2 ft */
export function calcGutterHangers(gutterLengthFt: number): number {
  return Math.ceil(gutterLengthFt / 2);
}

// ── Area feature calculations ──

export function calcAreaSqFt(f: AreaFeature, scale: number): number {
  return polygonAreaSqFt(f.points, scale);
}

/** Concrete: cubic yards = area × depth / 27 (depth in inches → convert) */
export function calcConcreteCuYd(areaSqFt: number, depthInches: number, wastePct: number = 0.05): number {
  const depthFt = depthInches / 12;
  return (areaSqFt * depthFt / 27) * (1 + wastePct);
}

/** Paver count = area / paver_area + waste */
export function calcPaverCount(areaSqFt: number, paverSqFt: number, wastePct: number = 0.10): number {
  if (paverSqFt <= 0) return 0;
  return Math.ceil((areaSqFt / paverSqFt) * (1 + wastePct));
}

/** Mulch/topsoil cubic yards = area × depth (inches) / (12 × 27) */
export function calcMulchCuYd(areaSqFt: number, depthInches: number): number {
  return (areaSqFt * depthInches) / (12 * 27);
}

/** Gravel tons = cubic yards × 1.4 */
export function calcGravelTons(cuYd: number): number {
  return cuYd * 1.4;
}

/** Sod pallets = area / 450 sq ft per pallet */
export function calcSodPallets(areaSqFt: number): number {
  return Math.ceil(areaSqFt / 450);
}

// ── Elevation / grading ──

/** Slope between two elevation markers as percentage */
export function calcSlopePct(
  a: ElevationMarker,
  b: ElevationMarker,
  scale: number,
): number {
  const run = distance(a.position, b.position) / scale;
  if (run < 0.01) return 0;
  const rise = Math.abs(b.elevation - a.elevation);
  return (rise / run) * 100;
}

/** Grade direction from higher to lower point */
export function gradeDirection(a: ElevationMarker, b: ElevationMarker): number {
  const higher = a.elevation >= b.elevation ? a : b;
  const lower = a.elevation >= b.elevation ? b : a;
  return Math.atan2(
    lower.position.y - higher.position.y,
    lower.position.x - higher.position.x,
  );
}

// ── Snap helpers ──

/** Find closest point on polygon edges */
export function snapToPolygonEdge(
  pt: Point,
  polygon: Point[],
  threshold: number,
): Point | null {
  let best: Point | null = null;
  let bestDist = threshold;
  for (let i = 0; i < polygon.length; i++) {
    const j = (i + 1) % polygon.length;
    const proj = projectOntoSegment(pt, polygon[i], polygon[j]);
    const d = distance(pt, proj);
    if (d < bestDist) {
      bestDist = d;
      best = proj;
    }
  }
  return best;
}

/** Project point onto line segment */
function projectOntoSegment(p: Point, a: Point, b: Point): Point {
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const len2 = dx * dx + dy * dy;
  if (len2 < 0.001) return a;
  let t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
  t = Math.max(0, Math.min(1, t));
  return { x: a.x + t * dx, y: a.y + t * dy };
}

/** Snap to nearest vertex of polygon */
export function snapToPolygonVertex(
  pt: Point,
  polygon: Point[],
  threshold: number,
): Point | null {
  let best: Point | null = null;
  let bestDist = threshold;
  for (const v of polygon) {
    const d = distance(pt, v);
    if (d < bestDist) {
      bestDist = d;
      best = v;
    }
  }
  return best;
}
