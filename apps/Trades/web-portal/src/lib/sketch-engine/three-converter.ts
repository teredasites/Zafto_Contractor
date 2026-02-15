// ZAFTO 3D Scene Converter — FloorPlanData → Three.js geometry (SK10)
// Converts 2D floor plan data into 3D extruded wall meshes, floor plane,
// door/window openings (proper wall segmentation), trade element sprites,
// and room labels.

import * as THREE from 'three';
import type {
  FloorPlanData,
  Wall,
  DoorPlacement,
  WindowPlacement,
  DetectedRoom,
  TradeLayer,
} from './types';
import { positionOnWall, wallLength } from './geometry';

const WALL_COLOR_INTERIOR = 0xf5f5f5;
const WALL_COLOR_EXTERIOR = 0xcccccc;
const FLOOR_COLOR = 0xe8dcc8; // light wood
const DOOR_COLOR = 0x8b6914; // wood brown for door panel
const DOOR_FRAME_COLOR = 0x5c4a1e; // darker frame
const WINDOW_GLASS_COLOR = 0x88ccee; // light blue glass
const WINDOW_FRAME_COLOR = 0xdddddd; // light gray frame

interface SceneData {
  walls: THREE.Mesh[];
  floor: THREE.Mesh | null;
  doors: THREE.Mesh[];
  windows: THREE.Mesh[];
  roomLabels: THREE.Sprite[];
  tradeElements: THREE.Sprite[];
  fixtures: THREE.Mesh[];
}

// Normalized opening info for wall segmentation
interface OpeningInfo {
  type: 'door' | 'window';
  centerDist: number; // inches from wall start
  width: number;
  height: number;
  bottomY: number; // 0 for doors, sillHeight for windows
  id: string;
}

/**
 * Convert a 2D FloorPlanData into Three.js meshes ready to add to a scene.
 * Y-axis is up (height). X/Z map to the 2D x/y coordinates.
 *
 * Walls are segmented around door/window openings so openings appear as
 * actual gaps in the wall geometry (no CSG needed).
 */
export function convertToThreeScene(plan: FloorPlanData): SceneData {
  const result: SceneData = {
    walls: [],
    floor: null,
    doors: [],
    windows: [],
    roomLabels: [],
    tradeElements: [],
    fixtures: [],
  };

  if (plan.walls.length === 0) return result;

  // Build wall → openings lookup
  const wallDoors = new Map<string, DoorPlacement[]>();
  const wallWindows = new Map<string, WindowPlacement[]>();

  for (const door of plan.doors) {
    const list = wallDoors.get(door.wallId) || [];
    list.push(door);
    wallDoors.set(door.wallId, list);
  }
  for (const win of plan.windows) {
    const list = wallWindows.get(win.wallId) || [];
    list.push(win);
    wallWindows.set(win.wallId, list);
  }

  // Create walls with proper openings
  for (const wall of plan.walls) {
    const doors = wallDoors.get(wall.id) || [];
    const windows = wallWindows.get(wall.id) || [];
    const { wallMeshes, doorMeshes, windowMeshes } = createWallWithOpenings(
      wall,
      doors,
      windows,
    );
    result.walls.push(...wallMeshes);
    result.doors.push(...doorMeshes);
    result.windows.push(...windowMeshes);
  }

  // --- Floor plane ---
  result.floor = createFloorPlane(plan);

  // --- Room labels ---
  for (const room of plan.rooms) {
    result.roomLabels.push(createRoomLabel(room));
  }

  // --- Fixtures ---
  for (const fix of plan.fixtures) {
    const geometry = new THREE.CylinderGeometry(3, 3, 2, 8);
    const material = new THREE.MeshStandardMaterial({ color: 0x4caf50 });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(fix.position.x, 1, fix.position.y);
    mesh.userData = { type: 'fixture', id: fix.id, fixtureType: fix.type };
    result.fixtures.push(mesh);
  }

  // --- Trade elements ---
  for (const tl of plan.tradeLayers) {
    if (!tl.visible || !tl.tradeData) continue;
    for (const elem of tl.tradeData.elements) {
      result.tradeElements.push(
        createTradeSprite(
          elem.position.x,
          elem.position.y,
          tl.type,
          elem.label ?? elem.type,
        ),
      );
    }
  }

  return result;
}

// =============================================================================
// WALL SEGMENTATION — proper openings for doors and windows
// =============================================================================

/**
 * Creates wall geometry with proper cutouts for doors and windows.
 *
 * Instead of one solid box per wall, this splits the wall into segments:
 * - Full-height segments between openings
 * - Lintels above doors (wall from door top to ceiling)
 * - Wall below windows (floor to sill height)
 * - Wall above windows (window top to ceiling)
 * - Door panel visuals (semi-transparent wood panel in the opening)
 * - Window glass panes (transparent blue in the opening)
 */
function createWallWithOpenings(
  wall: Wall,
  doors: DoorPlacement[],
  windows: WindowPlacement[],
): {
  wallMeshes: THREE.Mesh[];
  doorMeshes: THREE.Mesh[];
  windowMeshes: THREE.Mesh[];
} {
  const wallH = wall.height || 96;
  const thick = wall.thickness || 6;
  const len = wallLength(wall);
  const angle = Math.atan2(
    wall.end.y - wall.start.y,
    wall.end.x - wall.start.x,
  );

  const wallMeshes: THREE.Mesh[] = [];
  const doorMeshes: THREE.Mesh[] = [];
  const windowMeshes: THREE.Mesh[] = [];

  // Collect all openings into a unified sorted list
  const openings: OpeningInfo[] = [];

  for (const d of doors) {
    openings.push({
      type: 'door',
      centerDist: d.position * len,
      width: d.width || 36,
      height: Math.min(80, wallH - 4),
      bottomY: 0,
      id: d.id,
    });
  }

  for (const w of windows) {
    const sill = w.sillHeight ?? 36;
    openings.push({
      type: 'window',
      centerDist: w.position * len,
      width: w.width || 36,
      height: Math.min(48, wallH - sill - 4),
      bottomY: sill,
      id: w.id,
    });
  }

  // No openings — return simple solid wall
  if (openings.length === 0) {
    wallMeshes.push(
      makeWallSegment(wall, 0, len, 0, wallH, thick, angle),
    );
    return { wallMeshes, doorMeshes, windowMeshes };
  }

  // Sort by position along wall
  openings.sort((a, b) => a.centerDist - b.centerDist);

  // Walk along the wall, creating segments between openings
  let cursor = 0; // current position in inches from wall start

  for (const op of openings) {
    const leftEdge = Math.max(0, op.centerDist - op.width / 2);
    const rightEdge = Math.min(len, op.centerDist + op.width / 2);

    // Full-height wall segment before this opening
    if (leftEdge > cursor + 0.5) {
      wallMeshes.push(
        makeWallSegment(wall, cursor, leftEdge, 0, wallH, thick, angle),
      );
    }

    if (op.type === 'door') {
      // Lintel above the door (from door top to ceiling)
      const lintelH = wallH - op.height;
      if (lintelH > 1) {
        wallMeshes.push(
          makeWallSegment(
            wall,
            leftEdge,
            rightEdge,
            op.height,
            wallH,
            thick,
            angle,
          ),
        );
      }

      // Door panel visual — semi-transparent wood-colored panel in the gap
      const doorPos = positionOnWall(wall, op.centerDist / len);
      const doorGeo = new THREE.BoxGeometry(op.width - 2, op.height - 2, 1.5);
      const doorMat = new THREE.MeshStandardMaterial({
        color: DOOR_COLOR,
        transparent: true,
        opacity: 0.5,
        roughness: 0.7,
        metalness: 0.0,
        side: THREE.DoubleSide,
      });
      const doorMesh = new THREE.Mesh(doorGeo, doorMat);
      doorMesh.position.set(doorPos.x, op.height / 2, doorPos.y);
      doorMesh.rotation.y = -angle;
      doorMesh.userData = { type: 'door', id: op.id };
      doorMeshes.push(doorMesh);

      // Door frame — thin outline around the opening
      const frameThick = 2;
      const frameMat = new THREE.MeshStandardMaterial({
        color: DOOR_FRAME_COLOR,
        roughness: 0.6,
      });

      // Left jamb
      const leftJambGeo = new THREE.BoxGeometry(
        frameThick,
        op.height,
        thick + 2,
      );
      const leftJamb = new THREE.Mesh(leftJambGeo, frameMat);
      const leftJambPos = positionOnWall(wall, leftEdge / len);
      leftJamb.position.set(leftJambPos.x, op.height / 2, leftJambPos.y);
      leftJamb.rotation.y = -angle;
      doorMeshes.push(leftJamb);

      // Right jamb
      const rightJambGeo = new THREE.BoxGeometry(
        frameThick,
        op.height,
        thick + 2,
      );
      const rightJamb = new THREE.Mesh(rightJambGeo, frameMat);
      const rightJambPos = positionOnWall(wall, rightEdge / len);
      rightJamb.position.set(rightJambPos.x, op.height / 2, rightJambPos.y);
      rightJamb.rotation.y = -angle;
      doorMeshes.push(rightJamb);

      // Header
      const headerGeo = new THREE.BoxGeometry(op.width, frameThick, thick + 2);
      const header = new THREE.Mesh(headerGeo, frameMat);
      header.position.set(doorPos.x, op.height, doorPos.y);
      header.rotation.y = -angle;
      doorMeshes.push(header);
    } else {
      // WINDOW — wall below sill + wall above header + glass pane

      // Wall below window sill
      if (op.bottomY > 0.5) {
        wallMeshes.push(
          makeWallSegment(
            wall,
            leftEdge,
            rightEdge,
            0,
            op.bottomY,
            thick,
            angle,
          ),
        );
      }

      // Wall above window header
      const topOfWindow = op.bottomY + op.height;
      if (topOfWindow < wallH - 0.5) {
        wallMeshes.push(
          makeWallSegment(
            wall,
            leftEdge,
            rightEdge,
            topOfWindow,
            wallH,
            thick,
            angle,
          ),
        );
      }

      // Glass pane — transparent blue
      const winPos = positionOnWall(wall, op.centerDist / len);
      const glassGeo = new THREE.BoxGeometry(op.width - 2, op.height - 2, 1);
      const glassMat = new THREE.MeshStandardMaterial({
        color: WINDOW_GLASS_COLOR,
        transparent: true,
        opacity: 0.3,
        roughness: 0.1,
        metalness: 0.3,
        side: THREE.DoubleSide,
      });
      const glassMesh = new THREE.Mesh(glassGeo, glassMat);
      glassMesh.position.set(
        winPos.x,
        op.bottomY + op.height / 2,
        winPos.y,
      );
      glassMesh.rotation.y = -angle;
      glassMesh.userData = { type: 'window', id: op.id };
      windowMeshes.push(glassMesh);

      // Window frame
      const frameMat = new THREE.MeshStandardMaterial({
        color: WINDOW_FRAME_COLOR,
        roughness: 0.5,
      });
      const frameThick = 2;

      // Sill
      const sillGeo = new THREE.BoxGeometry(
        op.width + 2,
        frameThick,
        thick + 3,
      );
      const sill = new THREE.Mesh(sillGeo, frameMat);
      sill.position.set(winPos.x, op.bottomY, winPos.y);
      sill.rotation.y = -angle;
      windowMeshes.push(sill);

      // Header
      const headerGeo = new THREE.BoxGeometry(
        op.width + 2,
        frameThick,
        thick + 1,
      );
      const winHeader = new THREE.Mesh(headerGeo, frameMat);
      winHeader.position.set(winPos.x, op.bottomY + op.height, winPos.y);
      winHeader.rotation.y = -angle;
      windowMeshes.push(winHeader);
    }

    cursor = rightEdge;
  }

  // Wall segment after the last opening
  if (cursor < len - 0.5) {
    wallMeshes.push(
      makeWallSegment(wall, cursor, len, 0, wallH, thick, angle),
    );
  }

  return { wallMeshes, doorMeshes, windowMeshes };
}

/**
 * Create a wall box segment from startDist to endDist (inches along the wall),
 * from bottomY to topY (inches in height).
 */
function makeWallSegment(
  wall: Wall,
  startDist: number,
  endDist: number,
  bottomY: number,
  topY: number,
  thickness: number,
  angle: number,
): THREE.Mesh {
  const len = wallLength(wall);
  const segLen = endDist - startDist;
  const segHeight = topY - bottomY;
  const centerDist = (startDist + endDist) / 2;
  const centerT = len > 0 ? centerDist / len : 0.5;
  const pos = positionOnWall(wall, centerT);

  const geometry = new THREE.BoxGeometry(segLen, segHeight, thickness);
  const material = new THREE.MeshStandardMaterial({
    color: WALL_COLOR_INTERIOR,
    roughness: 0.9,
    metalness: 0.0,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(pos.x, bottomY + segHeight / 2, pos.y);
  mesh.rotation.y = -angle;
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  mesh.userData = { type: 'wall', id: wall.id };

  return mesh;
}

// =============================================================================
// FLOOR, LABELS, TRADE SPRITES (unchanged)
// =============================================================================

function createFloorPlane(plan: FloorPlanData): THREE.Mesh | null {
  // Calculate bounds from walls
  let minX = Infinity,
    minY = Infinity,
    maxX = -Infinity,
    maxY = -Infinity;
  for (const wall of plan.walls) {
    for (const pt of [wall.start, wall.end]) {
      if (pt.x < minX) minX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y > maxY) maxY = pt.y;
    }
  }
  if (minX === Infinity) return null;

  const pad = 24;
  const w = maxX - minX + pad * 2;
  const h = maxY - minY + pad * 2;
  const cx = (minX + maxX) / 2;
  const cy = (minY + maxY) / 2;

  const geometry = new THREE.PlaneGeometry(w, h);
  const material = new THREE.MeshStandardMaterial({
    color: FLOOR_COLOR,
    roughness: 0.95,
    metalness: 0.0,
    side: THREE.DoubleSide,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.rotation.x = -Math.PI / 2; // flat on XZ plane
  mesh.position.set(cx, 0, cy);
  mesh.receiveShadow = true;
  mesh.userData = { type: 'floor' };

  return mesh;
}

function createRoomLabel(room: DetectedRoom): THREE.Sprite {
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 64;
  const ctx = canvas.getContext('2d')!;
  ctx.fillStyle = 'rgba(255,255,255,0.85)';
  ctx.fillRect(0, 0, 256, 64);
  ctx.font = 'bold 24px Inter, sans-serif';
  ctx.fillStyle = '#333';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(room.name, 128, 22);
  ctx.font = '16px Inter, sans-serif';
  ctx.fillStyle = '#666';
  ctx.fillText(`${room.area.toFixed(0)} SF`, 128, 48);

  const texture = new THREE.CanvasTexture(canvas);
  const material = new THREE.SpriteMaterial({
    map: texture,
    depthTest: false,
  });
  const sprite = new THREE.Sprite(material);
  sprite.position.set(room.center.x, 50, room.center.y); // float above floor
  sprite.scale.set(80, 20, 1);
  sprite.userData = { type: 'roomLabel', id: room.id };

  return sprite;
}

function createTradeSprite(
  x: number,
  y: number,
  layerType: string,
  label: string,
): THREE.Sprite {
  const colors: Record<string, string> = {
    electrical: '#3B82F6',
    plumbing: '#EF4444',
    hvac: '#10B981',
    damage: '#F59E0B',
  };

  const canvas = document.createElement('canvas');
  canvas.width = 64;
  canvas.height = 64;
  const ctx = canvas.getContext('2d')!;

  // Circle marker
  ctx.beginPath();
  ctx.arc(32, 32, 24, 0, Math.PI * 2);
  ctx.fillStyle = colors[layerType] ?? '#666';
  ctx.fill();
  ctx.strokeStyle = '#fff';
  ctx.lineWidth = 2;
  ctx.stroke();

  // Symbol initial
  ctx.font = 'bold 20px Inter, sans-serif';
  ctx.fillStyle = '#fff';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(label.charAt(0).toUpperCase(), 32, 32);

  const texture = new THREE.CanvasTexture(canvas);
  const material = new THREE.SpriteMaterial({
    map: texture,
    depthTest: false,
  });
  const sprite = new THREE.Sprite(material);
  sprite.position.set(x, 48, y); // slightly above floor
  sprite.scale.set(12, 12, 1);
  sprite.userData = { type: 'tradeElement', layerType, label };

  return sprite;
}

/**
 * Calculate an optimal camera position for the given plan.
 * Returns { position, target } for OrbitControls.
 */
export function calculateCameraPosition(plan: FloorPlanData): {
  position: [number, number, number];
  target: [number, number, number];
} {
  let minX = Infinity,
    minY = Infinity,
    maxX = -Infinity,
    maxY = -Infinity;
  for (const wall of plan.walls) {
    for (const pt of [wall.start, wall.end]) {
      if (pt.x < minX) minX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y > maxY) maxY = pt.y;
    }
  }

  if (minX === Infinity) {
    return { position: [0, 200, 200], target: [0, 0, 0] };
  }

  const cx = (minX + maxX) / 2;
  const cy = (minY + maxY) / 2;
  const size = Math.max(maxX - minX, maxY - minY);
  const dist = size * 1.2;

  return {
    position: [cx + dist * 0.5, dist * 0.8, cy + dist * 0.5],
    target: [cx, 0, cy],
  };
}
