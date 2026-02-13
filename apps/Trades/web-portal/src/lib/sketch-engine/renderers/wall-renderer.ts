// ZAFTO Wall Renderer — Konva shapes for walls (SK6)
// Renders straight walls as thick lines and arc walls as quadratic curves.

import Konva from 'konva';
import type { Wall, ArcWall, Point } from '../types';
import { wallLength, wallAngle, formatLength } from '../geometry';

const SELECTED_COLOR = '#3B82F6';
const WALL_COLOR = '#1E293B';
const GHOST_COLOR = '#94A3B8';

export function createWallShape(
  wall: Wall,
  selected: boolean,
): Konva.Line {
  return new Konva.Line({
    id: wall.id,
    points: [wall.start.x, wall.start.y, wall.end.x, wall.end.y],
    stroke: selected ? SELECTED_COLOR : WALL_COLOR,
    strokeWidth: wall.thickness,
    lineCap: 'round',
    hitStrokeWidth: Math.max(wall.thickness, 12),
  });
}

export function createArcWallShape(
  arc: ArcWall,
  selected: boolean,
): Konva.Shape {
  return new Konva.Shape({
    id: arc.id,
    sceneFunc: (context, shape) => {
      context.beginPath();
      context.moveTo(arc.start.x, arc.start.y);
      context.quadraticCurveTo(
        arc.controlPoint.x,
        arc.controlPoint.y,
        arc.end.x,
        arc.end.y,
      );
      context.setAttr('strokeStyle', selected ? SELECTED_COLOR : WALL_COLOR);
      context.setAttr('lineWidth', arc.thickness);
      context.setAttr('lineCap', 'round');
      context.stroke();
      context.fillStrokeShape(shape);
    },
    hitFunc: (context, shape) => {
      context.beginPath();
      context.moveTo(arc.start.x, arc.start.y);
      context.quadraticCurveTo(
        arc.controlPoint.x,
        arc.controlPoint.y,
        arc.end.x,
        arc.end.y,
      );
      context.setAttr('lineWidth', Math.max(arc.thickness, 12));
      context.stroke();
      context.fillStrokeShape(shape);
    },
  });
}

export function createGhostWall(start: Point, end: Point): Konva.Line {
  return new Konva.Line({
    points: [start.x, start.y, end.x, end.y],
    stroke: GHOST_COLOR,
    strokeWidth: 6,
    dash: [8, 4],
    lineCap: 'round',
    listening: false,
  });
}

export function createWallDimension(
  wall: Wall,
  unit: 'imperial' | 'metric',
): Konva.Group {
  const group = new Konva.Group();
  const len = wallLength(wall);
  const angle = wallAngle(wall);
  const mid: Point = {
    x: (wall.start.x + wall.end.x) / 2,
    y: (wall.start.y + wall.end.y) / 2,
  };

  // Offset perpendicular to wall
  const offsetDist = wall.thickness / 2 + 14;
  const perpX = -Math.sin(angle) * offsetDist;
  const perpY = Math.cos(angle) * offsetDist;

  const text = new Konva.Text({
    x: mid.x + perpX,
    y: mid.y + perpY,
    text: formatLength(len, unit),
    fontSize: 11,
    fontFamily: 'Inter, sans-serif',
    fill: '#64748B',
    align: 'center',
    offsetX: 20,
    rotation: (angle * 180) / Math.PI,
  });

  group.add(text);
  return group;
}

export function createSnapIndicator(point: Point): Konva.Circle {
  return new Konva.Circle({
    x: point.x,
    y: point.y,
    radius: 6,
    fill: SELECTED_COLOR,
    opacity: 0.6,
    listening: false,
  });
}

export function createEndpointHandle(
  point: Point,
  wallId: string,
  which: 'start' | 'end',
): Konva.Circle {
  return new Konva.Circle({
    x: point.x,
    y: point.y,
    radius: 5,
    fill: '#FFFFFF',
    stroke: SELECTED_COLOR,
    strokeWidth: 2,
    draggable: true,
    name: `endpoint_${wallId}_${which}`,
  });
}
