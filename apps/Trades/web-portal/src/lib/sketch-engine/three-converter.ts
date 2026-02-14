// ZAFTO 3D Scene Converter — FloorPlanData → Three.js geometry (SK10)
// Converts 2D floor plan data into 3D extruded wall meshes, floor plane,
// door/window openings, trade element sprites, and room labels.

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
const DOOR_COLOR = 0x9966cc;
const WINDOW_COLOR = 0x88ddee;

interface SceneData {
  walls: THREE.Mesh[];
  floor: THREE.Mesh | null;
  doors: THREE.Mesh[];
  windows: THREE.Mesh[];
  roomLabels: THREE.Sprite[];
  tradeElements: THREE.Sprite[];
  fixtures: THREE.Mesh[];
}

/**
 * Convert a 2D FloorPlanData into Three.js meshes ready to add to a scene.
 * Y-axis is up (height). X/Z map to the 2D x/y coordinates.
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

  // --- Walls ---
  for (const wall of plan.walls) {
    const mesh = createWallMesh(wall);
    result.walls.push(mesh);
  }

  // --- Door openings (visual indicators — not CSG subtraction for performance) ---
  for (const door of plan.doors) {
    const wall = plan.walls.find((w) => w.id === door.wallId);
    if (!wall) continue;
    const mesh = createDoorMesh(door, wall);
    if (mesh) result.doors.push(mesh);
  }

  // --- Window openings ---
  for (const win of plan.windows) {
    const wall = plan.walls.find((w) => w.id === win.wallId);
    if (!wall) continue;
    const mesh = createWindowMesh(win, wall);
    if (mesh) result.windows.push(mesh);
  }

  // --- Floor plane ---
  result.floor = createFloorPlane(plan);

  // --- Room labels ---
  for (const room of plan.rooms) {
    const sprite = createRoomLabel(room);
    result.roomLabels.push(sprite);
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
      const sprite = createTradeSprite(elem.position.x, elem.position.y, tl.type, elem.label ?? elem.type);
      result.tradeElements.push(sprite);
    }
  }

  return result;
}

function createWallMesh(wall: Wall): THREE.Mesh {
  const dx = wall.end.x - wall.start.x;
  const dy = wall.end.y - wall.start.y;
  const len = Math.sqrt(dx * dx + dy * dy);
  const height = wall.height || 96; // default 8 feet
  const thickness = wall.thickness || 6;

  // Wall as a box: length × height × thickness
  const geometry = new THREE.BoxGeometry(len, height, thickness);
  const material = new THREE.MeshStandardMaterial({
    color: WALL_COLOR_INTERIOR,
    roughness: 0.9,
    metalness: 0.0,
  });

  const mesh = new THREE.Mesh(geometry, material);

  // Position at midpoint, rotated to match wall angle
  const mx = (wall.start.x + wall.end.x) / 2;
  const my = (wall.start.y + wall.end.y) / 2;
  const angle = Math.atan2(dy, dx);

  mesh.position.set(mx, height / 2, my);
  mesh.rotation.y = -angle;
  mesh.userData = { type: 'wall', id: wall.id };

  return mesh;
}

function createDoorMesh(door: DoorPlacement, wall: Wall): THREE.Mesh | null {
  const pos = positionOnWall(wall, door.position);
  const height = wall.height || 96;
  const doorHeight = Math.min(80, height - 4); // 80" standard door
  const len = wallLength(wall);
  const dx = (wall.end.x - wall.start.x) / len;
  const dy = (wall.end.y - wall.start.y) / len;
  const angle = Math.atan2(dy, dx);

  // Door represented as a thin colored box at the opening
  const geometry = new THREE.BoxGeometry(door.width, doorHeight, 2);
  const material = new THREE.MeshStandardMaterial({
    color: DOOR_COLOR,
    transparent: true,
    opacity: 0.6,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(pos.x, doorHeight / 2, pos.y);
  mesh.rotation.y = -angle;
  mesh.userData = { type: 'door', id: door.id };

  return mesh;
}

function createWindowMesh(win: WindowPlacement, wall: Wall): THREE.Mesh | null {
  const pos = positionOnWall(wall, win.position);
  const wallH = wall.height || 96;
  const sillHeight = win.sillHeight ?? 36; // 3 feet default sill
  const windowHeight = Math.min(48, wallH - sillHeight - 4);
  const len = wallLength(wall);
  const dx = (wall.end.x - wall.start.x) / len;
  const dy = (wall.end.y - wall.start.y) / len;
  const angle = Math.atan2(dy, dx);

  const geometry = new THREE.BoxGeometry(win.width, windowHeight, 2);
  const material = new THREE.MeshStandardMaterial({
    color: WINDOW_COLOR,
    transparent: true,
    opacity: 0.5,
  });

  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(pos.x, sillHeight + windowHeight / 2, pos.y);
  mesh.rotation.y = -angle;
  mesh.userData = { type: 'window', id: win.id };

  return mesh;
}

function createFloorPlane(plan: FloorPlanData): THREE.Mesh | null {
  // Calculate bounds from walls
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
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
  const material = new THREE.SpriteMaterial({ map: texture, depthTest: false });
  const sprite = new THREE.Sprite(material);
  sprite.position.set(room.center.x, 50, room.center.y); // float above floor
  sprite.scale.set(80, 20, 1);
  sprite.userData = { type: 'roomLabel', id: room.id };

  return sprite;
}

function createTradeSprite(x: number, y: number, layerType: string, label: string): THREE.Sprite {
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
  const material = new THREE.SpriteMaterial({ map: texture, depthTest: false });
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
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
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
