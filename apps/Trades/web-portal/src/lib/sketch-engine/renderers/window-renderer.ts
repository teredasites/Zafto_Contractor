// ZAFTO Window Renderer — Konva shapes for windows (SK6)
// 3-line symbol at parametric position along parent wall.

import Konva from 'konva';
import type { WindowPlacement, Wall, Point } from '../types';
import { lerp, wallAngle } from '../geometry';

const WINDOW_COLOR = '#0EA5E9';
const WINDOW_SELECTED = '#3B82F6';

export function createWindowShape(
  win: WindowPlacement,
  wall: Wall,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({ id: win.id });
  const color = selected ? WINDOW_SELECTED : WINDOW_COLOR;
  const pos = lerp(wall.start, wall.end, win.position);
  const angle = wallAngle(wall);
  const halfWidth = win.width / 2;
  const perpAngle = angle + Math.PI / 2;

  // Gap in wall
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

  // Window frame: 3 parallel lines
  const offsets = [-3, 0, 3];
  for (const offset of offsets) {
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
        strokeWidth: offset === 0 ? 2 : 1,
      }),
    );
  }

  return group;
}
