// ZAFTO OBJ Import — Parse Wavefront .OBJ 3D models (DEPTH43)
// Converts OBJ faces/edges into FloorPlanData walls (projected to 2D).
// Handles: vertices, faces, groups, basic materials.
// No external dependencies.

import type { FloorPlanData, Point } from '../types';
import { createEmptyFloorPlan } from '../types';
import {
  createEmptyReport,
  finalizeReport,
  type CompatibilityReport,
} from './compatibility-report';

export interface ObjImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

interface ObjVertex {
  x: number;
  y: number;
  z: number;
}

/**
 * Import Wavefront OBJ content into FloorPlanData.
 * Projects 3D geometry to 2D (top-down XZ plane → XY floor plan).
 * Face edges become wall segments.
 */
export function importObj(objContent: string, fileName: string): ObjImportResult {
  const report = createEmptyReport('OBJ', fileName);
  const plan = createEmptyFloorPlan();

  const vertices: ObjVertex[] = [];
  const edges = new Set<string>(); // dedup "x1,y1-x2,y2"
  let wallId = 0;
  let groupCount = 0;
  let faceCount = 0;
  let materialCount = 0;

  const lines = objContent.split('\n');

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (line.length === 0 || line.startsWith('#')) continue;

    const parts = line.split(/\s+/);
    const cmd = parts[0];

    switch (cmd) {
      case 'v': {
        // Vertex: v x y z
        const x = parseFloat(parts[1] || '0');
        const y = parseFloat(parts[2] || '0');
        const z = parseFloat(parts[3] || '0');
        if (!isNaN(x) && !isNaN(y) && !isNaN(z)) {
          vertices.push({ x, y, z });
        }
        break;
      }
      case 'f': {
        // Face: f v1 v2 v3 ... or f v1/vt1/vn1 v2/vt2/vn2 ...
        faceCount++;
        const faceVerts: number[] = [];
        for (let i = 1; i < parts.length; i++) {
          const idx = parseInt(parts[i].split('/')[0], 10);
          if (!isNaN(idx)) {
            // OBJ is 1-indexed, negative means relative
            faceVerts.push(idx > 0 ? idx - 1 : vertices.length + idx);
          }
        }

        // Extract edges from face — project to XZ plane (top-down)
        for (let i = 0; i < faceVerts.length; i++) {
          const v1Idx = faceVerts[i];
          const v2Idx = faceVerts[(i + 1) % faceVerts.length];

          if (v1Idx < 0 || v1Idx >= vertices.length || v2Idx < 0 || v2Idx >= vertices.length) continue;

          const v1 = vertices[v1Idx];
          const v2 = vertices[v2Idx];

          // Project 3D to 2D: use XZ plane (x stays x, z becomes y in floor plan)
          const p1: Point = { x: v1.x, y: v1.z };
          const p2: Point = { x: v2.x, y: v2.z };

          // Skip near-zero length edges
          const dx = p2.x - p1.x;
          const dy = p2.y - p1.y;
          if (Math.sqrt(dx * dx + dy * dy) < 0.01) continue;

          // Dedup edges
          const key = edgeKey(p1, p2);
          if (edges.has(key)) continue;
          edges.add(key);

          plan.walls.push({
            id: `obj-w-${++wallId}`,
            start: p1,
            end: p2,
            thickness: 6,
            height: 96,
          });
          report.converted.walls++;
        }
        break;
      }
      case 'g':
      case 'o':
        groupCount++;
        break;
      case 'mtllib':
      case 'usemtl':
        materialCount++;
        break;
      case 'vt':
      case 'vn':
        // Texture coords and normals — not needed for floor plan
        break;
      case 's':
        // Smoothing group — skip
        break;
      default:
        break;
    }
  }

  // Report summary
  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `OBJ file: ${vertices.length} vertices, ${faceCount} faces, ${groupCount} groups.`,
  });

  if (materialCount > 0) {
    report.skipped.materials = materialCount;
    report.items.push({
      severity: 'warning',
      category: 'materials',
      message: `${materialCount} material reference(s) skipped (materials not imported as geometry).`,
      entityCount: materialCount,
    });
  }

  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `Import complete: ${plan.walls.length} unique wall edges projected from 3D to 2D floor plan.`,
  });

  return { plan, report: finalizeReport(report) };
}

function edgeKey(p1: Point, p2: Point): string {
  // Canonical key — always start with the "lesser" point
  const k1 = `${p1.x.toFixed(2)},${p1.y.toFixed(2)}`;
  const k2 = `${p2.x.toFixed(2)},${p2.y.toFixed(2)}`;
  return k1 < k2 ? `${k1}-${k2}` : `${k2}-${k1}`;
}
