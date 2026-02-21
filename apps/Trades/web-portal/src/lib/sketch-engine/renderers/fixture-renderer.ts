// ZAFTO Fixture Renderer — Konva shapes for 25 fixture types (SK6)
// Simple geometric representations for each fixture type.

import Konva from 'konva';
import type { FixturePlacement, FixtureType } from '../types';

const FIXTURE_COLOR = '#059669';
const FIXTURE_SELECTED = '#3B82F6';
const FIXTURE_SIZE = 24; // base size in canvas units

export function createFixtureShape(
  fixture: FixturePlacement,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({
    id: fixture.id,
    x: fixture.position.x,
    y: fixture.position.y,
    rotation: fixture.rotation,
  });

  const color = selected ? FIXTURE_SELECTED : FIXTURE_COLOR;
  const s = FIXTURE_SIZE;

  switch (fixture.type) {
    case 'toilet':
      // Oval bowl + tank rectangle
      group.add(new Konva.Ellipse({ x: 0, y: 4, radiusX: s * 0.4, radiusY: s * 0.5, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Rect({ x: -s * 0.35, y: -s * 0.6, width: s * 0.7, height: s * 0.3, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      break;

    case 'sink':
      // Rectangle with oval basin
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.3, width: s * 0.8, height: s * 0.6, stroke: color, strokeWidth: 1.5, cornerRadius: 3 }));
      group.add(new Konva.Ellipse({ x: 0, y: 0, radiusX: s * 0.25, radiusY: s * 0.18, stroke: color, strokeWidth: 1 }));
      break;

    case 'bathtub':
      // Large rounded rectangle
      group.add(new Konva.Rect({ x: -s, y: -s * 0.4, width: s * 2, height: s * 0.8, stroke: color, strokeWidth: 1.5, cornerRadius: 8 }));
      group.add(new Konva.Circle({ x: -s * 0.6, y: 0, radius: 3, fill: color })); // drain
      break;

    case 'shower':
      // Square with X
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-s * 0.4, -s * 0.4, s * 0.4, s * 0.4], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Line({ points: [s * 0.4, -s * 0.4, -s * 0.4, s * 0.4], stroke: color, strokeWidth: 1 }));
      break;

    case 'stove':
      // Square with 4 circles (burners)
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 1.5 }));
      for (const [ox, oy] of [[-0.2, -0.2], [0.2, -0.2], [-0.2, 0.2], [0.2, 0.2]]) {
        group.add(new Konva.Circle({ x: ox * s, y: oy * s, radius: s * 0.12, stroke: color, strokeWidth: 1 }));
      }
      break;

    case 'refrigerator':
      // Tall rectangle with horizontal divider
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.6, width: s * 0.8, height: s * 1.2, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      group.add(new Konva.Line({ points: [-s * 0.4, -s * 0.1, s * 0.4, -s * 0.1], stroke: color, strokeWidth: 1 }));
      break;

    case 'dishwasher':
      // Square with horizontal lines
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.4, width: s * 0.8, height: s * 0.8, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-s * 0.3, -s * 0.1, s * 0.3, -s * 0.1], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Line({ points: [-s * 0.3, s * 0.1, s * 0.3, s * 0.1], stroke: color, strokeWidth: 1 }));
      break;

    case 'washer':
    case 'dryer':
      // Square with large circle
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.4, width: s * 0.8, height: s * 0.8, stroke: color, strokeWidth: 1.5, cornerRadius: 3 }));
      group.add(new Konva.Circle({ x: 0, y: 0, radius: s * 0.25, stroke: color, strokeWidth: 1 }));
      break;

    case 'waterHeater':
      // Circle (tank)
      group.add(new Konva.Circle({ x: 0, y: 0, radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'WH', x: -8, y: -6, fontSize: 10, fill: color, fontFamily: 'Inter' }));
      break;

    case 'furnace':
      // Rectangle with flame symbol
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.4, width: s, height: s * 0.8, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'F', x: -4, y: -6, fontSize: 12, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;

    case 'hvacUnit':
      // Rectangle with fan symbol
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'AC', x: -8, y: -6, fontSize: 10, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;

    case 'electricPanel':
      // Rectangle with lightning bolt indicator
      group.add(new Konva.Rect({ x: -s * 0.3, y: -s * 0.5, width: s * 0.6, height: s, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: '\u26A1', x: -6, y: -8, fontSize: 14, fill: color }));
      break;

    case 'sofa':
      // Long rounded rectangle with back
      group.add(new Konva.Rect({ x: -s * 0.8, y: -s * 0.3, width: s * 1.6, height: s * 0.6, stroke: color, strokeWidth: 1.5, cornerRadius: 4 }));
      group.add(new Konva.Rect({ x: -s * 0.8, y: -s * 0.3, width: s * 1.6, height: s * 0.15, fill: color, opacity: 0.2 }));
      break;

    case 'table':
      // Rectangle
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.4, width: s * 1.2, height: s * 0.8, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      break;

    case 'bed':
      // Rectangle with pillow area
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.8, width: s * 1.2, height: s * 1.6, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.7, width: s, height: s * 0.2, fill: color, opacity: 0.2, cornerRadius: 2 }));
      break;

    case 'desk':
      // Rectangle
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.3, width: s * 1.2, height: s * 0.6, stroke: color, strokeWidth: 1.5 }));
      break;

    case 'fireplace':
      // Arch shape (rectangle + arch top)
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.2, width: s, height: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Arc({ x: 0, y: -s * 0.2, innerRadius: s * 0.5, outerRadius: s * 0.5, angle: 180, rotation: 180, stroke: color, strokeWidth: 1.5 }));
      break;

    case 'stairs':
      // Rectangle with parallel lines (treads)
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.8, width: s * 0.8, height: s * 1.6, stroke: color, strokeWidth: 1.5 }));
      for (let i = -3; i <= 3; i++) {
        const y = i * s * 0.2;
        group.add(new Konva.Line({ points: [-s * 0.4, y, s * 0.4, y], stroke: color, strokeWidth: 1 }));
      }
      // Arrow
      group.add(new Konva.Arrow({ points: [0, s * 0.6, 0, -s * 0.6], pointerLength: 4, pointerWidth: 4, fill: color, stroke: color, strokeWidth: 1 }));
      break;

    // === COMMERCIAL STRUCTURAL ===
    case 'demisingWall':
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.05, width: s * 1.2, height: s * 0.1, fill: color, opacity: 0.4 }));
      group.add(new Konva.Text({ text: 'DW', x: -7, y: -s * 0.4, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'elevatorShaft':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 2 }));
      group.add(new Konva.Line({ points: [-s * 0.5, -s * 0.5, s * 0.5, s * 0.5], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Line({ points: [s * 0.5, -s * 0.5, -s * 0.5, s * 0.5], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Text({ text: 'EL', x: -6, y: -6, fontSize: 10, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'stairwellFireRated':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.8, width: s, height: s * 1.6, stroke: color, strokeWidth: 2 }));
      for (let i = -3; i <= 3; i++) {
        group.add(new Konva.Line({ points: [-s * 0.4, i * s * 0.2, s * 0.4, i * s * 0.2], stroke: color, strokeWidth: 1 }));
      }
      group.add(new Konva.Text({ text: 'FR', x: -6, y: -s * 0.95, fontSize: 8, fill: '#DC2626', fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'columnGrid':
      // Column with gridlines indicated
      group.add(new Konva.Circle({ radius: s * 0.3, fill: color, opacity: 0.3 }));
      group.add(new Konva.Circle({ radius: s * 0.3, stroke: color, strokeWidth: 2 }));
      break;
    case 'vestibule':
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.4, width: s * 1.2, height: s * 0.8, stroke: color, strokeWidth: 1.5, dash: [4, 4] }));
      group.add(new Konva.Text({ text: 'VES', x: -9, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'roofHatch':
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.4, width: s * 0.8, height: s * 0.8, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'RH', x: -6, y: -5, fontSize: 9, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    // === COMMERCIAL KITCHEN ===
    case 'commercialOven':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      group.add(new Konva.Text({ text: 'OVN', x: -9, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'commercialFryer':
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.5, width: s * 0.8, height: s, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'FRY', x: -9, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'commercialHood':
      group.add(new Konva.Rect({ x: -s * 0.8, y: -s * 0.2, width: s * 1.6, height: s * 0.4, stroke: color, strokeWidth: 2 }));
      group.add(new Konva.Text({ text: 'HOOD', x: -12, y: -6, fontSize: 8, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'walkInCooler':
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.6, width: s * 1.2, height: s * 1.2, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'WIC', x: -9, y: -5, fontSize: 9, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'walkInFreezer':
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.6, width: s * 1.2, height: s * 1.2, stroke: '#3B82F6', strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'WIF', x: -9, y: -5, fontSize: 9, fill: '#3B82F6', fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'threeCompSink':
      group.add(new Konva.Rect({ x: -s * 0.9, y: -s * 0.3, width: s * 1.8, height: s * 0.6, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-s * 0.3, -s * 0.3, -s * 0.3, s * 0.3], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Line({ points: [s * 0.3, -s * 0.3, s * 0.3, s * 0.3], stroke: color, strokeWidth: 1 }));
      break;
    // === COMMERCIAL DATA CENTER / BANK ===
    case 'serverRack':
      group.add(new Konva.Rect({ x: -s * 0.3, y: -s * 0.5, width: s * 0.6, height: s, stroke: color, strokeWidth: 1.5 }));
      for (let i = -3; i <= 3; i++) {
        group.add(new Konva.Line({ points: [-s * 0.2, i * s * 0.12, s * 0.2, i * s * 0.12], stroke: color, strokeWidth: 0.5 }));
      }
      group.add(new Konva.Circle({ x: s * 0.15, y: -s * 0.35, radius: 2, fill: '#10B981' }));
      break;
    case 'tellerWindow':
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.3, width: s * 0.8, height: s * 0.6, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-s * 0.3, 0, s * 0.3, 0], stroke: color, strokeWidth: 1, dash: [3, 2] }));
      group.add(new Konva.Text({ text: 'TW', x: -6, y: -s * 0.5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'vaultDoor':
      group.add(new Konva.Circle({ radius: s * 0.5, stroke: color, strokeWidth: 2 }));
      group.add(new Konva.Circle({ radius: s * 0.25, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'V', x: -3, y: -5, fontSize: 10, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;

    default:
      // Generic square with label
      group.add(new Konva.Rect({ x: -s * 0.4, y: -s * 0.4, width: s * 0.8, height: s * 0.8, stroke: color, strokeWidth: 1.5, dash: [4, 4] }));
      group.add(new Konva.Text({ text: fixture.type.slice(0, 3).toUpperCase(), x: -10, y: -6, fontSize: 10, fill: color, fontFamily: 'Inter' }));
      break;
  }

  // Selection indicator
  if (selected) {
    group.add(
      new Konva.Rect({
        x: -s * 0.6,
        y: -s * 0.6,
        width: s * 1.2,
        height: s * 1.2,
        stroke: FIXTURE_SELECTED,
        strokeWidth: 1,
        dash: [4, 4],
        listening: false,
      }),
    );
  }

  return group;
}
