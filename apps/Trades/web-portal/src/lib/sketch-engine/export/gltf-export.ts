// ZAFTO glTF Export — Three.js → glTF/GLB (DEPTH43)
// Converts FloorPlanData to Three.js scene (via three-converter.ts)
// then exports as glTF 2.0 JSON or GLB binary.
// Opens in Blender, SketchUp, Unreal, Unity, web viewers.

import * as THREE from 'three';
import { GLTFExporter } from 'three/examples/jsm/exporters/GLTFExporter.js';
import type { FloorPlanData } from '../types';
import { convertToThreeScene } from '../three-converter';

export interface GltfExportOptions {
  binary?: boolean; // true = GLB, false = glTF JSON (default: false)
  projectTitle?: string;
}

/**
 * Export FloorPlanData as glTF 2.0 (JSON) or GLB (binary).
 * Returns the content as a string (glTF) or ArrayBuffer (GLB).
 */
export async function exportGltf(
  plan: FloorPlanData,
  options?: GltfExportOptions,
): Promise<string | ArrayBuffer> {
  const binary = options?.binary ?? false;

  // Convert to Three.js scene
  const sceneData = convertToThreeScene(plan);
  const scene = new THREE.Scene();
  scene.name = options?.projectTitle ?? 'Zafto Floor Plan';

  // Add all meshes to scene
  for (const mesh of sceneData.walls) scene.add(mesh);
  if (sceneData.floor) scene.add(sceneData.floor);
  for (const mesh of sceneData.doors) scene.add(mesh);
  for (const mesh of sceneData.windows) scene.add(mesh);
  for (const mesh of sceneData.fixtures) scene.add(mesh);
  // Sprites (labels, trade elements) don't export well to glTF — skip

  const exporter = new GLTFExporter();

  return new Promise((resolve, reject) => {
    exporter.parse(
      scene,
      (result) => {
        if (binary) {
          resolve(result as ArrayBuffer);
        } else {
          resolve(JSON.stringify(result, null, 2));
        }
      },
      (error) => {
        reject(new Error(`glTF export failed: ${error.message}`));
      },
      { binary },
    );
  });
}

/**
 * Export and trigger browser download.
 */
export async function downloadGltf(
  plan: FloorPlanData,
  options?: GltfExportOptions & { filename?: string },
): Promise<void> {
  const binary = options?.binary ?? false;
  const result = await exportGltf(plan, options);
  const filename = options?.filename ?? (binary ? 'floor_plan.glb' : 'floor_plan.gltf');

  if (binary) {
    const blob = new Blob([result as ArrayBuffer], { type: 'model/gltf-binary' });
    triggerDownload(URL.createObjectURL(blob), filename);
  } else {
    const blob = new Blob([result as string], { type: 'model/gltf+json' });
    triggerDownload(URL.createObjectURL(blob), filename);
  }
}

function triggerDownload(url: string, filename: string): void {
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
