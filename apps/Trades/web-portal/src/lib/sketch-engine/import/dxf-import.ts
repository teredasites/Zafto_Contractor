// ZAFTO DXF Import — Parse AutoCAD DXF into FloorPlanData (DEPTH43)
// V1 scope: lines, arcs, circles, polylines, text, dimensions.
// Blocks, hatches, 3D solids deferred to future iteration.
// Uses dxf-parser (MIT license).

import DxfParser from 'dxf-parser';
import type { IDxf, IEntity } from 'dxf-parser';
import type { IArcEntity } from 'dxf-parser/dist/entities/arc';
import type { ICircleEntity } from 'dxf-parser/dist/entities/circle';
import type { ILineEntity } from 'dxf-parser/dist/entities/line';
import type { ILwpolylineEntity } from 'dxf-parser/dist/entities/lwpolyline';
import type { ITextEntity } from 'dxf-parser/dist/entities/text';
import type { IDimensionEntity } from 'dxf-parser/dist/entities/dimension';
import type {
  FloorPlanData,
  Wall,
  FloorLabel,
  DimensionLine,
  Point,
} from '../types';
import { createEmptyFloorPlan } from '../types';
import {
  createEmptyReport,
  finalizeReport,
  type CompatibilityReport,
} from './compatibility-report';

export interface DxfImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

let wallCounter = 0;
let labelCounter = 0;
let dimCounter = 0;

function nextWallId(): string { return `dxf-w-${++wallCounter}`; }
function nextLabelId(): string { return `dxf-l-${++labelCounter}`; }
function nextDimId(): string { return `dxf-d-${++dimCounter}`; }

/**
 * Import a DXF file string into FloorPlanData.
 * Returns the converted plan and a compatibility report documenting
 * what was imported and what was lost.
 */
export function importDxf(dxfContent: string, fileName: string): DxfImportResult {
  wallCounter = 0;
  labelCounter = 0;
  dimCounter = 0;

  const parser = new DxfParser();
  const dxf = parser.parseSync(dxfContent);

  if (!dxf) {
    const report = createEmptyReport('DXF', fileName);
    report.items.push({ severity: 'error', category: 'metadata', message: 'Failed to parse DXF file. File may be corrupted or use an unsupported version.' });
    return { plan: createEmptyFloorPlan(), report: finalizeReport(report) };
  }

  const report = createEmptyReport('DXF', fileName);

  // Detect version
  const acadVer = dxf.header?.['$ACADVER'];
  if (typeof acadVer === 'string' || (acadVer && typeof acadVer === 'object' && 'x' in acadVer)) {
    report.sourceVersion = typeof acadVer === 'string' ? acadVer : String(acadVer);
  }

  const plan = createEmptyFloorPlan();

  // Report layer info
  if (dxf.tables?.layer?.layers) {
    const layerNames = Object.keys(dxf.tables.layer.layers);
    report.items.push({
      severity: 'info',
      category: 'layers',
      message: `Found ${layerNames.length} layer(s): ${layerNames.slice(0, 10).join(', ')}${layerNames.length > 10 ? '...' : ''}`,
      entityCount: layerNames.length,
    });
  }

  // Report blocks (skipped in v1)
  if (dxf.blocks) {
    const blockCount = Object.keys(dxf.blocks).length;
    if (blockCount > 0) {
      report.skipped.blocks = blockCount;
      report.items.push({
        severity: 'warning',
        category: 'blocks',
        message: `${blockCount} block definition(s) skipped (blocks not supported in v1). Block contents may contain furniture, fixtures, or title block details.`,
        entityCount: blockCount,
      });
    }
  }

  // Process entities
  for (const entity of dxf.entities) {
    processEntity(entity, plan, report);
  }

  // Summary
  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `Import complete: ${plan.walls.length} walls, ${plan.labels.length} labels, ${plan.dimensions.length} dimensions created.`,
  });

  return { plan, report: finalizeReport(report) };
}

function processEntity(entity: IEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  switch (entity.type) {
    case 'LINE':
      processLine(entity as ILineEntity, plan, report);
      break;
    case 'LWPOLYLINE':
      processLwPolyline(entity as ILwpolylineEntity, plan, report);
      break;
    case 'ARC':
      processArc(entity as IArcEntity, plan, report);
      break;
    case 'CIRCLE':
      processCircle(entity as ICircleEntity, plan, report);
      break;
    case 'TEXT':
    case 'MTEXT':
      processText(entity as ITextEntity, plan, report);
      break;
    case 'DIMENSION':
      processDimension(entity as IDimensionEntity, plan, report);
      break;
    case 'POLYLINE':
      processPolylineAsWalls(entity as ILwpolylineEntity, plan, report);
      break;
    case 'POINT':
      // Points are informational markers — skip silently
      report.skipped.other++;
      break;
    case 'INSERT':
      // Block insert — v1 deferred
      report.skipped.blocks++;
      break;
    case 'SOLID':
    case '3DFACE':
      report.skipped.threeDSolids++;
      break;
    case 'HATCH':
      report.skipped.hatches++;
      break;
    case 'SPLINE':
      // Splines could be approximated but not in v1
      report.skipped.other++;
      report.items.push({
        severity: 'warning',
        category: 'geometry',
        message: 'Spline entity skipped (complex curves not supported in v1)',
      });
      break;
    case 'ELLIPSE':
      report.skipped.other++;
      report.items.push({
        severity: 'warning',
        category: 'geometry',
        message: 'Ellipse entity skipped (not supported in v1)',
      });
      break;
    default:
      report.skipped.other++;
      break;
  }
}

function processLine(entity: ILineEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  if (!entity.vertices || entity.vertices.length < 2) return;
  const start = entity.vertices[0];
  const end = entity.vertices[1];

  plan.walls.push({
    id: nextWallId(),
    start: { x: start.x, y: start.y },
    end: { x: end.x, y: end.y },
    thickness: 6,
    height: 96, // 8ft default
  });
  report.converted.walls++;
}

function processLwPolyline(entity: ILwpolylineEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  if (!entity.vertices || entity.vertices.length < 2) return;

  // Convert polyline segments to walls
  for (let i = 0; i < entity.vertices.length - 1; i++) {
    const v1 = entity.vertices[i];
    const v2 = entity.vertices[i + 1];
    plan.walls.push({
      id: nextWallId(),
      start: { x: v1.x, y: v1.y },
      end: { x: v2.x, y: v2.y },
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }

  // Close the polyline if shape flag is set
  if (entity.shape && entity.vertices.length >= 3) {
    const first = entity.vertices[0];
    const last = entity.vertices[entity.vertices.length - 1];
    plan.walls.push({
      id: nextWallId(),
      start: { x: last.x, y: last.y },
      end: { x: first.x, y: first.y },
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processPolylineAsWalls(entity: ILwpolylineEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  // POLYLINE (old-style) — treat same as LWPOLYLINE
  processLwPolyline(entity, plan, report);
}

function processArc(entity: IArcEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  // Approximate arc as a series of line segments (chord approximation)
  const cx = entity.center.x;
  const cy = entity.center.y;
  const r = entity.radius;
  const startAngle = (entity.startAngle * Math.PI) / 180;
  const endAngle = (entity.endAngle * Math.PI) / 180;

  // Calculate sweep, handling the case where end < start
  let sweep = endAngle - startAngle;
  if (sweep <= 0) sweep += 2 * Math.PI;

  // Number of segments based on arc length
  const arcLength = r * Math.abs(sweep);
  const segments = Math.max(4, Math.min(32, Math.round(arcLength / 12)));

  for (let i = 0; i < segments; i++) {
    const a1 = startAngle + (sweep * i) / segments;
    const a2 = startAngle + (sweep * (i + 1)) / segments;

    plan.walls.push({
      id: nextWallId(),
      start: { x: cx + r * Math.cos(a1), y: cy + r * Math.sin(a1) },
      end: { x: cx + r * Math.cos(a2), y: cy + r * Math.sin(a2) },
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processCircle(entity: ICircleEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  // Approximate circle as polygon (e.g. columns, pipes)
  const cx = entity.center.x;
  const cy = entity.center.y;
  const r = entity.radius;
  const segments = r > 24 ? 16 : 8; // larger circles get more segments

  for (let i = 0; i < segments; i++) {
    const a1 = (2 * Math.PI * i) / segments;
    const a2 = (2 * Math.PI * (i + 1)) / segments;

    plan.walls.push({
      id: nextWallId(),
      start: { x: cx + r * Math.cos(a1), y: cy + r * Math.sin(a1) },
      end: { x: cx + r * Math.cos(a2), y: cy + r * Math.sin(a2) },
      thickness: 4,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processText(entity: ITextEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  const text = entity.text;
  if (!text || text.trim().length === 0) return;

  const pos = entity.startPoint ?? entity.endPoint;
  if (!pos) return;

  plan.labels.push({
    id: nextLabelId(),
    position: { x: pos.x, y: pos.y },
    text: text.trim(),
    fontSize: entity.textHeight ? entity.textHeight * 4 : 14, // scale DXF text height to screen
    rotation: entity.rotation ?? 0,
  });
  report.converted.labels++;
}

function processDimension(entity: IDimensionEntity, plan: FloorPlanData, report: CompatibilityReport): void {
  // Linear dimensions have two measurement points
  const p1 = entity.linearOrAngularPoint1;
  const p2 = entity.linearOrAngularPoint2;

  if (p1 && p2) {
    plan.dimensions.push({
      id: nextDimId(),
      start: { x: p1.x, y: p1.y },
      end: { x: p2.x, y: p2.y },
      offset: 12,
      isAuto: false,
    });
    report.converted.dimensions++;
  } else if (entity.anchorPoint && entity.middleOfText) {
    // Fallback — use anchor and text position
    plan.dimensions.push({
      id: nextDimId(),
      start: { x: entity.anchorPoint.x, y: entity.anchorPoint.y },
      end: { x: entity.middleOfText.x, y: entity.middleOfText.y },
      offset: 12,
      isAuto: false,
    });
    report.converted.dimensions++;
  } else {
    report.skipped.annotations++;
    report.items.push({
      severity: 'warning',
      category: 'dimensions',
      message: 'Dimension entity skipped — missing measurement points',
    });
  }
}
