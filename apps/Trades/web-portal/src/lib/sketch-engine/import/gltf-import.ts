// ZAFTO glTF/GLB Import — Parse glTF 2.0 3D files (DEPTH43)
// Uses Three.js GLTFLoader to parse, then projects geometry to 2D floor plan.
// Handles glTF JSON (.gltf) and binary (.glb).

import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import type { FloorPlanData, Point } from '../types';
import { createEmptyFloorPlan } from '../types';
import {
  createEmptyReport,
  finalizeReport,
  type CompatibilityReport,
} from './compatibility-report';

export interface GltfImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

/**
 * Import a glTF/GLB file into FloorPlanData.
 * Accepts a data URL, blob URL, or ArrayBuffer.
 */
export async function importGltf(
  source: string | ArrayBuffer,
  fileName: string,
): Promise<GltfImportResult> {
  const report = createEmptyReport(fileName.endsWith('.glb') ? 'GLB' : 'glTF', fileName);
  const plan = createEmptyFloorPlan();

  const loader = new GLTFLoader();

  try {
    const gltf = await new Promise<{ scene: THREE.Group }>((resolve, reject) => {
      if (source instanceof ArrayBuffer) {
        loader.parse(source, '', resolve, reject);
      } else {
        loader.load(source, resolve, undefined, reject);
      }
    });

    // Report scene info
    let meshCount = 0;
    let materialCount = 0;
    let lightCount = 0;
    let cameraCount = 0;

    gltf.scene.traverse((obj) => {
      if (obj instanceof THREE.Mesh) meshCount++;
      if (obj instanceof THREE.Light) lightCount++;
      if (obj instanceof THREE.Camera) cameraCount++;
    });

    report.items.push({
      severity: 'info',
      category: 'metadata',
      message: `glTF scene: ${meshCount} meshes, ${lightCount} lights, ${cameraCount} cameras.`,
    });

    // Extract edges from meshes and project to 2D
    const edges = new Set<string>();
    let wallId = 0;

    gltf.scene.traverse((obj) => {
      if (!(obj instanceof THREE.Mesh)) return;

      const geometry = obj.geometry;
      if (!geometry) return;

      // Get world matrix
      obj.updateWorldMatrix(true, false);
      const worldMatrix = obj.matrixWorld;

      // Get position attribute
      const posAttr = geometry.getAttribute('position');
      if (!posAttr) return;

      const index = geometry.getIndex();
      const v1 = new THREE.Vector3();
      const v2 = new THREE.Vector3();
      const v3 = new THREE.Vector3();

      if (index) {
        // Indexed geometry — extract face edges
        for (let i = 0; i < index.count; i += 3) {
          v1.fromBufferAttribute(posAttr, index.getX(i)).applyMatrix4(worldMatrix);
          v2.fromBufferAttribute(posAttr, index.getX(i + 1)).applyMatrix4(worldMatrix);
          v3.fromBufferAttribute(posAttr, index.getX(i + 2)).applyMatrix4(worldMatrix);

          // Project to XZ plane (top-down view)
          addEdge(plan, edges, { x: v1.x, y: v1.z }, { x: v2.x, y: v2.z }, wallId);
          wallId++;
          addEdge(plan, edges, { x: v2.x, y: v2.z }, { x: v3.x, y: v3.z }, wallId);
          wallId++;
          addEdge(plan, edges, { x: v3.x, y: v3.z }, { x: v1.x, y: v1.z }, wallId);
          wallId++;
        }
      } else {
        // Non-indexed — every 3 vertices is a face
        for (let i = 0; i < posAttr.count; i += 3) {
          v1.fromBufferAttribute(posAttr, i).applyMatrix4(worldMatrix);
          v2.fromBufferAttribute(posAttr, i + 1).applyMatrix4(worldMatrix);
          v3.fromBufferAttribute(posAttr, i + 2).applyMatrix4(worldMatrix);

          addEdge(plan, edges, { x: v1.x, y: v1.z }, { x: v2.x, y: v2.z }, wallId);
          wallId++;
          addEdge(plan, edges, { x: v2.x, y: v2.z }, { x: v3.x, y: v3.z }, wallId);
          wallId++;
          addEdge(plan, edges, { x: v3.x, y: v3.z }, { x: v1.x, y: v1.z }, wallId);
          wallId++;
        }
      }

      // Count materials
      const mat = obj.material;
      if (Array.isArray(mat)) materialCount += mat.length;
      else if (mat) materialCount++;
    });

    if (materialCount > 0) {
      report.skipped.materials = materialCount;
      report.items.push({
        severity: 'warning',
        category: 'materials',
        message: `${materialCount} material(s) skipped (materials not imported to floor plan).`,
        entityCount: materialCount,
      });
    }

    if (lightCount > 0) {
      report.skipped.other += lightCount;
      report.items.push({
        severity: 'info',
        category: 'metadata',
        message: `${lightCount} light(s) skipped.`,
      });
    }

    report.converted.walls = plan.walls.length;
    report.items.push({
      severity: 'info',
      category: 'metadata',
      message: `Import complete: ${plan.walls.length} wall edges projected from 3D scene.`,
    });

  } catch (err) {
    report.items.push({
      severity: 'error',
      category: 'metadata',
      message: `Failed to parse glTF: ${err instanceof Error ? err.message : String(err)}`,
    });
  }

  return { plan, report: finalizeReport(report) };
}

function addEdge(plan: FloorPlanData, edges: Set<string>, p1: Point, p2: Point, wallId: number): void {
  const dx = p2.x - p1.x;
  const dy = p2.y - p1.y;
  if (Math.sqrt(dx * dx + dy * dy) < 0.5) return; // skip tiny edges

  const key = edgeKey(p1, p2);
  if (edges.has(key)) return;
  edges.add(key);

  plan.walls.push({
    id: `gltf-w-${wallId}`,
    start: p1,
    end: p2,
    thickness: 6,
    height: 96,
  });
}

function edgeKey(p1: Point, p2: Point): string {
  const k1 = `${p1.x.toFixed(1)},${p1.y.toFixed(1)}`;
  const k2 = `${p2.x.toFixed(1)},${p2.y.toFixed(1)}`;
  return k1 < k2 ? `${k1}-${k2}` : `${k2}-${k1}`;
}
