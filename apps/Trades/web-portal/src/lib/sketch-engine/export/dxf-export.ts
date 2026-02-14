// ZAFTO DXF Export — AutoCAD-compatible ASCII DXF (R2000/AC1015)
// TypeScript port of lib/services/dxf_writer.dart (SK9)
// Opens in AutoCAD, LibreCAD, DraftSight, BricsCAD.

import type { FloorPlanData, Wall, TradeLayer, Point } from '../types';
import { wallLength, positionOnWall } from '../geometry';

const ACAD_VERSION = 'AC1015';

interface DxfLayer {
  name: string;
  color: number; // AutoCAD ACI color index
}

const BASE_LAYERS: DxfLayer[] = [
  { name: 'WALLS', color: 7 },      // white
  { name: 'DOORS', color: 6 },      // magenta
  { name: 'WINDOWS', color: 4 },    // cyan
  { name: 'FIXTURES', color: 3 },   // green
  { name: 'ROOMS', color: 5 },      // blue
  { name: 'DIMENSIONS', color: 1 }, // red
  { name: 'LABELS', color: 7 },     // white
];

const TRADE_LAYERS: Record<string, DxfLayer> = {
  electrical: { name: 'ELECTRICAL', color: 5 },
  plumbing: { name: 'PLUMBING', color: 1 },
  hvac: { name: 'HVAC', color: 3 },
  damage: { name: 'DAMAGE', color: 30 },
};

let handleCounter = 100;
function nextHandle(): string {
  return (handleCounter++).toString(16).toUpperCase();
}

export function generateDxf(
  plan: FloorPlanData,
  options?: { projectTitle?: string; companyName?: string; tradeLayers?: TradeLayer[] },
): string {
  handleCounter = 100;
  const buf: string[] = [];
  const tradeLayers = options?.tradeLayers ?? plan.tradeLayers;

  // Collect all layers
  const allLayers = [...BASE_LAYERS];
  for (const tl of tradeLayers) {
    const def = TRADE_LAYERS[tl.type];
    if (def && !allLayers.find((l) => l.name === def.name)) {
      allLayers.push(def);
    }
  }

  // --- HEADER ---
  writeHeader(buf);

  // --- TABLES (layers) ---
  writeTables(buf, allLayers);

  // --- ENTITIES ---
  buf.push('0', 'SECTION', '2', 'ENTITIES');

  // Title block text
  if (options?.companyName) {
    writeText(buf, 'LABELS', 0, -20, options.companyName, 10);
  }
  if (options?.projectTitle) {
    writeText(buf, 'LABELS', 0, -35, options.projectTitle, 6);
  }

  // Walls
  for (const wall of plan.walls) {
    writeLine(buf, 'WALLS', wall.start.x, wall.start.y, wall.end.x, wall.end.y);
  }

  // Rooms — polygon from wall endpoints + label
  for (const room of plan.rooms) {
    const pts = roomWallPoints(room.wallIds, plan.walls);
    if (pts.length >= 3) {
      writeLwPolyline(buf, 'ROOMS', pts, true);
    }
    writeText(buf, 'ROOMS', room.center.x, room.center.y, room.name, 6);
  }

  // Doors
  for (const door of plan.doors) {
    const wall = plan.walls.find((w) => w.id === door.wallId);
    if (!wall) continue;
    const pos = positionOnWall(wall, door.position);
    const len = wallLength(wall);
    const dx = (wall.end.x - wall.start.x) / len;
    const dy = (wall.end.y - wall.start.y) / len;
    const halfW = door.width / 2;
    writeLine(
      buf, 'DOORS',
      pos.x - dx * halfW, pos.y - dy * halfW,
      pos.x + dx * halfW, pos.y + dy * halfW,
    );
    // Swing arc
    writeArc(buf, 'DOORS', pos.x, pos.y, door.width * 0.4, 0, 90);
  }

  // Windows
  for (const win of plan.windows) {
    const wall = plan.walls.find((w) => w.id === win.wallId);
    if (!wall) continue;
    const pos = positionOnWall(wall, win.position);
    const len = wallLength(wall);
    const dx = (wall.end.x - wall.start.x) / len;
    const dy = (wall.end.y - wall.start.y) / len;
    const halfW = win.width / 2;
    writeLine(
      buf, 'WINDOWS',
      pos.x - dx * halfW, pos.y - dy * halfW,
      pos.x + dx * halfW, pos.y + dy * halfW,
    );
  }

  // Fixtures
  for (const fix of plan.fixtures) {
    writePoint(buf, 'FIXTURES', fix.position.x, fix.position.y);
    const label = fix.type;
    writeText(buf, 'FIXTURES', fix.position.x + 3, fix.position.y + 3, label, 3);
  }

  // Dimensions
  for (const dim of plan.dimensions) {
    writeLine(buf, 'DIMENSIONS', dim.start.x, dim.start.y, dim.end.x, dim.end.y);
    const mx = (dim.start.x + dim.end.x) / 2;
    const my = (dim.start.y + dim.end.y) / 2;
    const dist = Math.sqrt(
      (dim.end.x - dim.start.x) ** 2 + (dim.end.y - dim.start.y) ** 2,
    );
    const ft = Math.floor(dist / 12);
    const inches = Math.round(dist % 12);
    writeText(buf, 'DIMENSIONS', mx, my + 3, `${ft}'-${inches}"`, 3);
  }

  // Labels
  for (const lbl of plan.labels) {
    writeText(buf, 'LABELS', lbl.position.x, lbl.position.y, lbl.text, lbl.fontSize / plan.scale);
  }

  // Trade layers
  for (const tl of tradeLayers) {
    if (!tl.visible) continue;
    const layerName = TRADE_LAYERS[tl.type]?.name ?? tl.type.toUpperCase();

    if (tl.tradeData) {
      for (const elem of tl.tradeData.elements) {
        writePoint(buf, layerName, elem.position.x, elem.position.y);
        writeText(buf, layerName, elem.position.x + 3, elem.position.y + 3, elem.label ?? elem.type, 3);
      }
      for (const path of tl.tradeData.paths) {
        if (path.points.length >= 2) {
          writeLwPolyline(buf, layerName, path.points);
        }
      }
    }

    if (tl.damageData && tl.damageData.zones.length > 0) {
      for (const zone of tl.damageData.zones) {
        if (zone.points.length >= 3) {
          writeLwPolyline(buf, layerName, zone.points, true);
          const cx = zone.points.reduce((s, p) => s + p.x, 0) / zone.points.length;
          const cy = zone.points.reduce((s, p) => s + p.y, 0) / zone.points.length;
          writeText(buf, layerName, cx, cy, zone.label ?? `Class ${zone.damageClass}`, 3);
        }
      }
    }
  }

  buf.push('0', 'ENDSEC');

  // --- EOF ---
  buf.push('0', 'EOF');

  return buf.join('\n');
}

// --- Helpers ---

function roomWallPoints(wallIds: string[], walls: Wall[]): Point[] {
  const pts: Point[] = [];
  for (const wid of wallIds) {
    const wall = walls.find((w) => w.id === wid);
    if (wall) {
      pts.push(wall.start, wall.end);
    }
  }
  return pts;
}

function writeHeader(buf: string[]) {
  buf.push(
    '0', 'SECTION', '2', 'HEADER',
    '9', '$ACADVER', '1', ACAD_VERSION,
    '9', '$INSUNITS', '70', '1', // inches
    '0', 'ENDSEC',
  );
}

function writeTables(buf: string[], layers: DxfLayer[]) {
  buf.push('0', 'SECTION', '2', 'TABLES');
  buf.push('0', 'TABLE', '2', 'LAYER', '70', String(layers.length));
  for (const layer of layers) {
    buf.push(
      '0', 'LAYER',
      '5', nextHandle(),
      '100', 'AcDbSymbolTableRecord',
      '100', 'AcDbLayerTableRecord',
      '2', layer.name,
      '70', '0',
      '62', String(layer.color),
      '6', 'Continuous',
    );
  }
  buf.push('0', 'ENDTAB');
  buf.push('0', 'ENDSEC');
}

function writeLine(buf: string[], layer: string, x1: number, y1: number, x2: number, y2: number) {
  buf.push(
    '0', 'LINE', '5', nextHandle(), '8', layer,
    '10', x1.toFixed(4), '20', y1.toFixed(4), '30', '0',
    '11', x2.toFixed(4), '21', y2.toFixed(4), '31', '0',
  );
}

function writeLwPolyline(buf: string[], layer: string, points: Point[], closed = false) {
  buf.push(
    '0', 'LWPOLYLINE', '5', nextHandle(), '8', layer,
    '100', 'AcDbPolyline',
    '90', String(points.length),
    '70', closed ? '1' : '0',
  );
  for (const pt of points) {
    buf.push('10', pt.x.toFixed(4), '20', pt.y.toFixed(4));
  }
}

function writeText(buf: string[], layer: string, x: number, y: number, text: string, height: number) {
  buf.push(
    '0', 'TEXT', '5', nextHandle(), '8', layer,
    '10', x.toFixed(4), '20', y.toFixed(4), '30', '0',
    '40', height.toFixed(2),
    '1', text,
  );
}

function writePoint(buf: string[], layer: string, x: number, y: number) {
  buf.push(
    '0', 'POINT', '5', nextHandle(), '8', layer,
    '10', x.toFixed(4), '20', y.toFixed(4), '30', '0',
  );
}

function writeArc(buf: string[], layer: string, cx: number, cy: number, r: number, startDeg: number, endDeg: number) {
  buf.push(
    '0', 'ARC', '5', nextHandle(), '8', layer,
    '10', cx.toFixed(4), '20', cy.toFixed(4), '30', '0',
    '40', r.toFixed(4),
    '50', startDeg.toFixed(2), '51', endDeg.toFixed(2),
  );
}
