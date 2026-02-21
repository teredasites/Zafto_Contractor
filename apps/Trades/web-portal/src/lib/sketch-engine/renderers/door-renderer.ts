// ZAFTO Door Renderer — Konva shapes for 7 door types (SK6)
// Renders doors at parametric position along parent wall with swing arcs.

import Konva from 'konva';
import type { DoorPlacement, Wall, DoorType, Point } from '../types';
import { lerp, wallAngle } from '../geometry';

const DOOR_COLOR = '#8B5CF6';
const DOOR_SELECTED = '#3B82F6';

export function createDoorShape(
  door: DoorPlacement,
  wall: Wall,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({ id: door.id });
  const color = selected ? DOOR_SELECTED : DOOR_COLOR;
  const pos = lerp(wall.start, wall.end, door.position);
  const angle = wallAngle(wall);
  const halfWidth = door.width / 2;

  // Gap in wall (break indicator)
  group.add(
    new Konva.Line({
      points: [
        pos.x - halfWidth * Math.cos(angle),
        pos.y - halfWidth * Math.sin(angle),
        pos.x + halfWidth * Math.cos(angle),
        pos.y + halfWidth * Math.sin(angle),
      ],
      stroke: '#FFFFFF',
      strokeWidth: wall.thickness + 2,
      listening: false,
    }),
  );

  switch (door.type) {
    case 'single':
      addSingleDoor(group, pos, angle, door.width, color, door.flipSide);
      break;
    case 'double':
      addDoubleDoor(group, pos, angle, door.width, color);
      break;
    case 'sliding':
      addSlidingDoor(group, pos, angle, door.width, color);
      break;
    case 'pocket':
      addPocketDoor(group, pos, angle, door.width, color);
      break;
    case 'bifold':
      addBifoldDoor(group, pos, angle, door.width, color);
      break;
    case 'barn':
      addBarnDoor(group, pos, angle, door.width, color);
      break;
    case 'french':
      addDoubleDoor(group, pos, angle, door.width, color); // French = double with panes
      break;
    // Commercial door types
    case 'rollUp':
    case 'overhead':
      addRollUpDoor(group, pos, angle, door.width, color);
      break;
    case 'storefrontGlass':
    case 'curtainWall':
      addStorefrontDoor(group, pos, angle, door.width, color);
      break;
    case 'revolvingDoor':
      addRevolvingDoor(group, pos, angle, door.width, color);
      break;
    case 'rollDownSecurity':
      addRollUpDoor(group, pos, angle, door.width, color); // same visual as roll-up
      break;
    case 'driveThruWindow':
    case 'bulletResistantWindow':
      addSlidingDoor(group, pos, angle, door.width, color); // sliding panel visual
      break;
  }

  return group;
}

function addSingleDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
  flipSide?: boolean,
): void {
  const swingSide = flipSide ? -1 : 1;
  const perpAngle = angle + (swingSide * Math.PI) / 2;
  const halfWidth = width / 2;

  // Hinge point
  const hinge: Point = {
    x: pos.x - halfWidth * Math.cos(angle),
    y: pos.y - halfWidth * Math.sin(angle),
  };

  // Door panel (line from hinge perpendicular)
  const doorEnd: Point = {
    x: hinge.x + width * Math.cos(perpAngle),
    y: hinge.y + width * Math.sin(perpAngle),
  };

  group.add(
    new Konva.Line({
      points: [hinge.x, hinge.y, doorEnd.x, doorEnd.y],
      stroke: color,
      strokeWidth: 2,
    }),
  );

  // Swing arc
  group.add(
    new Konva.Arc({
      x: hinge.x,
      y: hinge.y,
      innerRadius: width,
      outerRadius: width,
      angle: 90,
      rotation: (perpAngle * 180) / Math.PI - 90,
      stroke: color,
      strokeWidth: 1,
      dash: [4, 4],
    }),
  );
}

function addDoubleDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  addSingleDoor(group, pos, angle, width / 2, color, false);
  addSingleDoor(group, pos, angle, width / 2, color, true);
}

function addSlidingDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;
  // Two parallel lines (sliding panels)
  const perpOff = 3;
  const perpAngle = angle + Math.PI / 2;

  for (const offset of [-perpOff, perpOff]) {
    const ox = offset * Math.cos(perpAngle);
    const oy = offset * Math.sin(perpAngle);

    group.add(
      new Konva.Line({
        points: [
          pos.x - halfWidth * Math.cos(angle) + ox,
          pos.y - halfWidth * Math.sin(angle) + oy,
          pos.x + halfWidth * Math.cos(angle) + ox,
          pos.y + halfWidth * Math.sin(angle) + oy,
        ],
        stroke: color,
        strokeWidth: 2,
      }),
    );
  }

  // Arrow indicator
  group.add(
    new Konva.Arrow({
      points: [
        pos.x - halfWidth * 0.3 * Math.cos(angle),
        pos.y - halfWidth * 0.3 * Math.sin(angle),
        pos.x + halfWidth * 0.3 * Math.cos(angle),
        pos.y + halfWidth * 0.3 * Math.sin(angle),
      ],
      pointerLength: 4,
      pointerWidth: 4,
      fill: color,
      stroke: color,
      strokeWidth: 1,
    }),
  );
}

function addPocketDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;
  // Pocket (dashed line showing door recess)
  group.add(
    new Konva.Line({
      points: [
        pos.x - halfWidth * Math.cos(angle),
        pos.y - halfWidth * Math.sin(angle),
        pos.x + halfWidth * Math.cos(angle),
        pos.y + halfWidth * Math.sin(angle),
      ],
      stroke: color,
      strokeWidth: 2,
      dash: [6, 3],
    }),
  );
}

function addBifoldDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;
  const mid: Point = { x: pos.x, y: pos.y };
  const perpAngle = angle + Math.PI / 2;

  // Two zigzag panels
  const panelEnd: Point = {
    x: mid.x + (halfWidth * 0.6) * Math.cos(perpAngle),
    y: mid.y + (halfWidth * 0.6) * Math.sin(perpAngle),
  };

  group.add(
    new Konva.Line({
      points: [
        pos.x - halfWidth * Math.cos(angle),
        pos.y - halfWidth * Math.sin(angle),
        panelEnd.x,
        panelEnd.y,
        pos.x + halfWidth * Math.cos(angle),
        pos.y + halfWidth * Math.sin(angle),
      ],
      stroke: color,
      strokeWidth: 2,
    }),
  );
}

function addBarnDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;

  // Track line (above door)
  const perpAngle = angle + Math.PI / 2;
  const trackOffset = 8;

  group.add(
    new Konva.Line({
      points: [
        pos.x - width * Math.cos(angle) + trackOffset * Math.cos(perpAngle),
        pos.y - width * Math.sin(angle) + trackOffset * Math.sin(perpAngle),
        pos.x + width * Math.cos(angle) + trackOffset * Math.cos(perpAngle),
        pos.y + width * Math.sin(angle) + trackOffset * Math.sin(perpAngle),
      ],
      stroke: color,
      strokeWidth: 1,
      dash: [2, 2],
    }),
  );

  // Door panel
  group.add(
    new Konva.Rect({
      x: pos.x - halfWidth * Math.cos(angle),
      y: pos.y - halfWidth * Math.sin(angle),
      width,
      height: 4,
      fill: color,
      rotation: (angle * 180) / Math.PI,
      opacity: 0.5,
    }),
  );
}

// === Commercial Door Types ===

function addRollUpDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;

  // Wide opening with horizontal lines (coils)
  group.add(
    new Konva.Line({
      points: [
        pos.x - halfWidth * Math.cos(angle),
        pos.y - halfWidth * Math.sin(angle),
        pos.x + halfWidth * Math.cos(angle),
        pos.y + halfWidth * Math.sin(angle),
      ],
      stroke: color,
      strokeWidth: 3,
    }),
  );

  // Coil indicator (3 parallel lines at top)
  const perpAngle = angle + Math.PI / 2;
  for (let i = 1; i <= 3; i++) {
    const off = i * 3;
    group.add(
      new Konva.Line({
        points: [
          pos.x - halfWidth * 0.8 * Math.cos(angle) + off * Math.cos(perpAngle),
          pos.y - halfWidth * 0.8 * Math.sin(angle) + off * Math.sin(perpAngle),
          pos.x + halfWidth * 0.8 * Math.cos(angle) + off * Math.cos(perpAngle),
          pos.y + halfWidth * 0.8 * Math.sin(angle) + off * Math.sin(perpAngle),
        ],
        stroke: color,
        strokeWidth: 1,
        opacity: 0.5,
      }),
    );
  }
}

function addStorefrontDoor(
  group: Konva.Group,
  pos: Point,
  angle: number,
  width: number,
  color: string,
): void {
  const halfWidth = width / 2;
  const perpAngle = angle + Math.PI / 2;
  const glassDepth = 4;

  // Glass panel (thick filled rectangle)
  const p1 = {
    x: pos.x - halfWidth * Math.cos(angle) - glassDepth * Math.cos(perpAngle),
    y: pos.y - halfWidth * Math.sin(angle) - glassDepth * Math.sin(perpAngle),
  };

  group.add(
    new Konva.Rect({
      x: p1.x,
      y: p1.y,
      width,
      height: glassDepth * 2,
      fill: color,
      opacity: 0.15,
      stroke: color,
      strokeWidth: 1.5,
      rotation: (angle * 180) / Math.PI,
    }),
  );

  // Vertical mullion lines
  for (let i = 1; i < 3; i++) {
    const t = i / 3;
    const mx = pos.x + (t - 0.5) * width * Math.cos(angle);
    const my = pos.y + (t - 0.5) * width * Math.sin(angle);
    group.add(
      new Konva.Line({
        points: [
          mx - glassDepth * Math.cos(perpAngle),
          my - glassDepth * Math.sin(perpAngle),
          mx + glassDepth * Math.cos(perpAngle),
          my + glassDepth * Math.sin(perpAngle),
        ],
        stroke: color,
        strokeWidth: 1,
      }),
    );
  }
}

function addRevolvingDoor(
  group: Konva.Group,
  pos: Point,
  _angle: number,
  width: number,
  color: string,
): void {
  const radius = width / 2;

  // Outer circle
  group.add(new Konva.Circle({ x: pos.x, y: pos.y, radius, stroke: color, strokeWidth: 1.5 }));

  // 4 wing panels (cross pattern)
  for (let i = 0; i < 4; i++) {
    const a = (i * Math.PI) / 2 + Math.PI / 4; // 45° offset
    group.add(
      new Konva.Line({
        points: [pos.x, pos.y, pos.x + radius * 0.9 * Math.cos(a), pos.y + radius * 0.9 * Math.sin(a)],
        stroke: color,
        strokeWidth: 1.5,
      }),
    );
  }
}
