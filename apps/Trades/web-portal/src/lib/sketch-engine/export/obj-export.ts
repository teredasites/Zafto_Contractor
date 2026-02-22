// ZAFTO OBJ Export — Wavefront .OBJ 3D format (DEPTH43)
// Exports FloorPlanData as extruded wall geometry.
// Opens in Blender, SketchUp, 3ds Max, Rhino, and most 3D software.
// No external dependencies.

import type { FloorPlanData, Wall, Point } from '../types';
import { wallLength, positionOnWall } from '../geometry';

interface ObjVertex {
  x: number;
  y: number;
  z: number;
}

/**
 * Generate Wavefront .OBJ content from FloorPlanData.
 * Walls are extruded into 3D boxes. Floor plane is generated from rooms.
 * Returns { obj, mtl } — OBJ content and MTL material library content.
 */
export function generateObj(
  plan: FloorPlanData,
  options?: { projectTitle?: string },
): { obj: string; mtl: string } {
  const objBuf: string[] = [];
  const mtlBuf: string[] = [];
  let vertexIndex = 1; // OBJ vertices are 1-indexed

  // Header
  objBuf.push(`# ZAFTO Sketch Engine — OBJ Export`);
  objBuf.push(`# ${options?.projectTitle ?? 'Floor Plan'}`);
  objBuf.push(`# Generated: ${new Date().toISOString()}`);
  objBuf.push(`mtllib floor_plan.mtl`);
  objBuf.push('');

  // Materials
  mtlBuf.push('# ZAFTO Floor Plan Materials');
  mtlBuf.push('');
  mtlBuf.push('newmtl wall');
  mtlBuf.push('Kd 0.95 0.95 0.95'); // light gray
  mtlBuf.push('Ka 0.2 0.2 0.2');
  mtlBuf.push('Ks 0.1 0.1 0.1');
  mtlBuf.push('Ns 10');
  mtlBuf.push('');
  mtlBuf.push('newmtl floor');
  mtlBuf.push('Kd 0.91 0.86 0.78'); // light wood
  mtlBuf.push('Ka 0.2 0.18 0.15');
  mtlBuf.push('Ks 0.05 0.05 0.05');
  mtlBuf.push('Ns 5');
  mtlBuf.push('');
  mtlBuf.push('newmtl door');
  mtlBuf.push('Kd 0.55 0.41 0.08'); // wood brown
  mtlBuf.push('Ka 0.15 0.1 0.02');
  mtlBuf.push('Ks 0.1 0.1 0.1');
  mtlBuf.push('Ns 20');
  mtlBuf.push('');
  mtlBuf.push('newmtl window');
  mtlBuf.push('Kd 0.53 0.8 0.93'); // light blue glass
  mtlBuf.push('Ka 0.1 0.15 0.2');
  mtlBuf.push('Ks 0.5 0.5 0.5');
  mtlBuf.push('Ns 80');
  mtlBuf.push('d 0.5'); // transparent

  // Group: Walls
  objBuf.push('g walls');
  objBuf.push('usemtl wall');

  for (const wall of plan.walls) {
    const startIdx = vertexIndex;
    const verts = wallToVertices(wall);
    for (const v of verts) {
      objBuf.push(`v ${v.x.toFixed(4)} ${v.y.toFixed(4)} ${v.z.toFixed(4)}`);
    }
    vertexIndex += verts.length;

    // 8 vertices = box. Build 6 faces (quads)
    const s = startIdx;
    // Front face (start-side)
    objBuf.push(`f ${s} ${s + 1} ${s + 5} ${s + 4}`);
    // Back face (end-side)
    objBuf.push(`f ${s + 2} ${s + 3} ${s + 7} ${s + 6}`);
    // Top face
    objBuf.push(`f ${s + 4} ${s + 5} ${s + 6} ${s + 7}`);
    // Bottom face
    objBuf.push(`f ${s} ${s + 3} ${s + 2} ${s + 1}`);
    // Left side
    objBuf.push(`f ${s} ${s + 4} ${s + 7} ${s + 3}`);
    // Right side
    objBuf.push(`f ${s + 1} ${s + 2} ${s + 6} ${s + 5}`);
  }

  // Group: Floor
  if (plan.rooms.length > 0) {
    objBuf.push('');
    objBuf.push('g floor');
    objBuf.push('usemtl floor');

    for (const room of plan.rooms) {
      const roomWalls = room.wallIds
        .map((wid) => plan.walls.find((w) => w.id === wid))
        .filter(Boolean) as Wall[];

      if (roomWalls.length < 3) continue;

      // Collect unique endpoints
      const pts = collectRoomOutline(roomWalls);
      if (pts.length < 3) continue;

      const startIdx = vertexIndex;
      for (const pt of pts) {
        objBuf.push(`v ${pt.x.toFixed(4)} 0.0000 ${pt.y.toFixed(4)}`); // floor at y=0
      }
      vertexIndex += pts.length;

      // Fan triangulation from centroid approach — simple convex polygon fan
      const face = pts.map((_, i) => startIdx + i).join(' ');
      objBuf.push(`f ${face}`);
    }
  }

  // Group: Doors (simplified as planes)
  if (plan.doors.length > 0) {
    objBuf.push('');
    objBuf.push('g doors');
    objBuf.push('usemtl door');

    for (const door of plan.doors) {
      const wall = plan.walls.find((w) => w.id === door.wallId);
      if (!wall) continue;
      const pos = positionOnWall(wall, door.position);
      const len = wallLength(wall);
      if (len < 0.01) continue;
      const dx = (wall.end.x - wall.start.x) / len;
      const dy = (wall.end.y - wall.start.y) / len;
      const halfW = door.width / 2;
      const doorHeight = 80; // 6'8" standard door

      const startIdx = vertexIndex;
      // 4 vertices for door plane
      objBuf.push(`v ${(pos.x - dx * halfW).toFixed(4)} 0.0000 ${(pos.y - dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x + dx * halfW).toFixed(4)} 0.0000 ${(pos.y + dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x + dx * halfW).toFixed(4)} ${doorHeight.toFixed(4)} ${(pos.y + dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x - dx * halfW).toFixed(4)} ${doorHeight.toFixed(4)} ${(pos.y - dy * halfW).toFixed(4)}`);
      vertexIndex += 4;
      objBuf.push(`f ${startIdx} ${startIdx + 1} ${startIdx + 2} ${startIdx + 3}`);
    }
  }

  // Group: Windows (simplified as planes)
  if (plan.windows.length > 0) {
    objBuf.push('');
    objBuf.push('g windows');
    objBuf.push('usemtl window');

    for (const win of plan.windows) {
      const wall = plan.walls.find((w) => w.id === win.wallId);
      if (!wall) continue;
      const pos = positionOnWall(wall, win.position);
      const len = wallLength(wall);
      if (len < 0.01) continue;
      const dx = (wall.end.x - wall.start.x) / len;
      const dy = (wall.end.y - wall.start.y) / len;
      const halfW = win.width / 2;
      const sill = win.sillHeight ?? 36; // 3ft sill height default
      const windowTop = sill + 48; // 4ft window height

      const startIdx = vertexIndex;
      objBuf.push(`v ${(pos.x - dx * halfW).toFixed(4)} ${sill.toFixed(4)} ${(pos.y - dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x + dx * halfW).toFixed(4)} ${sill.toFixed(4)} ${(pos.y + dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x + dx * halfW).toFixed(4)} ${windowTop.toFixed(4)} ${(pos.y + dy * halfW).toFixed(4)}`);
      objBuf.push(`v ${(pos.x - dx * halfW).toFixed(4)} ${windowTop.toFixed(4)} ${(pos.y - dy * halfW).toFixed(4)}`);
      vertexIndex += 4;
      objBuf.push(`f ${startIdx} ${startIdx + 1} ${startIdx + 2} ${startIdx + 3}`);
    }
  }

  return {
    obj: objBuf.join('\n'),
    mtl: mtlBuf.join('\n'),
  };
}

// --- Helpers ---

function wallToVertices(wall: Wall): ObjVertex[] {
  // Extrude wall line into a 3D box
  const len = Math.sqrt(
    (wall.end.x - wall.start.x) ** 2 + (wall.end.y - wall.start.y) ** 2,
  );
  if (len < 0.01) return [];

  const dx = (wall.end.x - wall.start.x) / len;
  const dy = (wall.end.y - wall.start.y) / len;
  // Perpendicular for wall thickness
  const nx = -dy * (wall.thickness / 2);
  const ny = dx * (wall.thickness / 2);

  const h = wall.height;

  // 8 vertices of the wall box
  // Bottom face (y=0)
  return [
    { x: wall.start.x + nx, y: 0, z: wall.start.y + ny },   // 0: start-left-bottom
    { x: wall.start.x - nx, y: 0, z: wall.start.y - ny },   // 1: start-right-bottom
    { x: wall.end.x - nx,   y: 0, z: wall.end.y - ny },     // 2: end-right-bottom
    { x: wall.end.x + nx,   y: 0, z: wall.end.y + ny },     // 3: end-left-bottom
    // Top face (y=h)
    { x: wall.start.x + nx, y: h, z: wall.start.y + ny },   // 4: start-left-top
    { x: wall.start.x - nx, y: h, z: wall.start.y - ny },   // 5: start-right-top
    { x: wall.end.x - nx,   y: h, z: wall.end.y - ny },     // 6: end-right-top
    { x: wall.end.x + nx,   y: h, z: wall.end.y + ny },     // 7: end-left-top
  ];
}

function collectRoomOutline(walls: Wall[]): Point[] {
  const pts: Point[] = [];
  for (const wall of walls) {
    pts.push(wall.start);
  }
  return pts;
}
