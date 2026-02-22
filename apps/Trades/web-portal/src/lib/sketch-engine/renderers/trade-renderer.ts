// ZAFTO Trade Renderer — Konva shapes for trade layer elements (SK6)
// Renders 62 trade symbols, paths (wire/pipe/duct), and overlays.

import Konva from 'konva';
import type {
  TradeElement,
  TradePath,
  TradeLayerType,
  TradePathType,
  Point,
} from '../types';

// Color mapping for trade path types
const PATH_COLORS: Record<TradePathType, string> = {
  wire: '#F59E0B',
  pipe_hot: '#EF4444',
  pipe_cold: '#3B82F6',
  drain: '#6B7280',
  gas: '#EAB308',
  duct_supply: '#60A5FA',
  duct_return: '#F87171',
  // Commercial
  duct_exhaust: '#9CA3AF',
  conduit_rigid: '#D97706',
  conduit_emt: '#F59E0B',
  conduit_pvc: '#A3A3A3',
  grease_waste: '#92400E',
  acid_waste: '#7C3AED',
  compressed_air: '#06B6D4',
  sprinkler_main: '#DC2626',
  sprinkler_branch: '#EF4444',
  standpipe: '#B91C1C',
  cable_tray: '#CA8A04',
  bus_duct: '#EA580C',
  refrigerant_line: '#2DD4BF',
};

// Layer accent colors
const LAYER_COLORS: Record<TradeLayerType, string> = {
  electrical: '#F59E0B',
  plumbing: '#3B82F6',
  hvac: '#10B981',
  damage: '#EF4444',
  fire: '#DC2626',
  roofing: '#8B5CF6',
  siding: '#06B6D4',
  insulation: '#EC4899',
  framing: '#D97706',
  drywall: '#6B7280',
  flooring: '#14B8A6',
  painting: '#F472B6',
  concrete: '#78716C',
  demolition: '#F97316',
  solar: '#FBBF24',
  low_voltage: '#818CF8',
  gas: '#EAB308',
  irrigation: '#22C55E',
};

const SYMBOL_SIZE = 16;

export function createTradeElementShape(
  element: TradeElement,
  layerType: TradeLayerType,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({
    id: element.id,
    x: element.position.x,
    y: element.position.y,
    rotation: element.rotation,
  });

  const color = selected ? '#3B82F6' : LAYER_COLORS[layerType];
  const s = SYMBOL_SIZE;

  // Draw symbol based on type
  switch (element.type) {
    // === ELECTRICAL ===
    case 'outlet':
      group.add(new Konva.Circle({ radius: s * 0.5, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-3, -3, -3, 3], stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [3, -3, 3, 3], stroke: color, strokeWidth: 1.5 }));
      break;
    case 'outletGFCI':
      group.add(new Konva.Circle({ radius: s * 0.5, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'GF', x: -6, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'outletDedicated':
      group.add(new Konva.Circle({ radius: s * 0.5, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-5, 0, 5, 0], stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Circle({ radius: 2, fill: color }));
      break;
    case 'switchSingle':
    case 'switchThreeWay':
    case 'switchDimmer':
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'S', x: -3, y: -5, fontSize: 10, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'lightCeiling':
    case 'lightRecessed':
      // Circle with rays
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      for (let i = 0; i < 4; i++) {
        const a = (i * Math.PI) / 2;
        const r1 = s * 0.5;
        const r2 = s * 0.7;
        group.add(new Konva.Line({ points: [r1 * Math.cos(a), r1 * Math.sin(a), r2 * Math.cos(a), r2 * Math.sin(a)], stroke: color, strokeWidth: 1 }));
      }
      break;
    case 'lightWall':
      group.add(new Konva.Rect({ x: -s * 0.3, y: -s * 0.2, width: s * 0.6, height: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      break;
    case 'panelMain':
    case 'panelSub':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.6, width: s, height: s * 1.2, stroke: color, strokeWidth: 2 }));
      group.add(new Konva.Line({ points: [-s * 0.5, 0, s * 0.5, 0], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Text({ text: element.type === 'panelMain' ? 'MP' : 'SP', x: -6, y: -s * 0.4, fontSize: 8, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'smokeDetector':
    case 'coDetector':
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5, dash: [3, 2] }));
      group.add(new Konva.Text({ text: element.type === 'smokeDetector' ? 'SD' : 'CO', x: -6, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'thermostat':
    case 'thermostatHvac':
      group.add(new Konva.Rect({ x: -s * 0.3, y: -s * 0.4, width: s * 0.6, height: s * 0.8, stroke: color, strokeWidth: 1.5, cornerRadius: 2 }));
      group.add(new Konva.Text({ text: 'T', x: -3, y: -5, fontSize: 10, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'fan':
    case 'fanExhaust':
      group.add(new Konva.Circle({ radius: s * 0.5, stroke: color, strokeWidth: 1.5 }));
      // Fan blades
      for (let i = 0; i < 3; i++) {
        const a = (i * 2 * Math.PI) / 3;
        group.add(new Konva.Line({ points: [0, 0, s * 0.4 * Math.cos(a), s * 0.4 * Math.sin(a)], stroke: color, strokeWidth: 1.5 }));
      }
      break;

    // === PLUMBING ===
    case 'valve':
    case 'valveShutoff':
    case 'valveCheck':
      // Diamond shape
      group.add(new Konva.Line({
        points: [0, -s * 0.4, s * 0.4, 0, 0, s * 0.4, -s * 0.4, 0],
        stroke: color, strokeWidth: 1.5, closed: true,
      }));
      break;
    case 'cleanout':
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'CO', x: -6, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
    case 'floorDrain':
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Line({ points: [-s * 0.3, -s * 0.3, s * 0.3, s * 0.3], stroke: color, strokeWidth: 1 }));
      group.add(new Konva.Line({ points: [s * 0.3, -s * 0.3, -s * 0.3, s * 0.3], stroke: color, strokeWidth: 1 }));
      break;
    case 'hosebibb':
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: 'HB', x: -6, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;

    // === HVAC ===
    case 'supplyRegister':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.3, width: s, height: s * 0.6, stroke: color, strokeWidth: 1.5 }));
      // Louvers
      for (let i = -2; i <= 2; i++) {
        const x = i * s * 0.18;
        group.add(new Konva.Line({ points: [x, -s * 0.2, x, s * 0.2], stroke: color, strokeWidth: 0.5 }));
      }
      break;
    case 'returnRegister':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.3, width: s, height: s * 0.6, stroke: color, strokeWidth: 1.5 }));
      // Cross-hatch
      group.add(new Konva.Line({ points: [-s * 0.4, -s * 0.2, s * 0.4, s * 0.2], stroke: color, strokeWidth: 0.5 }));
      group.add(new Konva.Line({ points: [s * 0.4, -s * 0.2, -s * 0.4, s * 0.2], stroke: color, strokeWidth: 0.5 }));
      break;
    case 'condenser':
    case 'airHandler':
    case 'heatPump':
      group.add(new Konva.Rect({ x: -s * 0.5, y: -s * 0.5, width: s, height: s, stroke: color, strokeWidth: 1.5 }));
      const label = element.type === 'condenser' ? 'CU' : element.type === 'airHandler' ? 'AH' : 'HP';
      group.add(new Konva.Text({ text: label, x: -6, y: -5, fontSize: 9, fill: color, fontFamily: 'Inter', fontStyle: 'bold' }));
      break;
    case 'minisplit':
      group.add(new Konva.Rect({ x: -s * 0.6, y: -s * 0.2, width: s * 1.2, height: s * 0.4, stroke: color, strokeWidth: 1.5, cornerRadius: 3 }));
      break;

    default:
      // Generic circle with type abbreviation
      group.add(new Konva.Circle({ radius: s * 0.4, stroke: color, strokeWidth: 1.5 }));
      group.add(new Konva.Text({ text: element.type.slice(0, 2).toUpperCase(), x: -6, y: -5, fontSize: 8, fill: color, fontFamily: 'Inter' }));
      break;
  }

  // Label
  if (element.label) {
    group.add(new Konva.Text({
      text: element.label,
      x: -20,
      y: s * 0.6,
      fontSize: 9,
      fill: color,
      fontFamily: 'Inter',
      width: 40,
      align: 'center',
    }));
  }

  return group;
}

export function createTradePathShape(
  path: TradePath,
  selected: boolean,
): Konva.Line {
  const flatPoints = path.points.flatMap((p) => [p.x, p.y]);
  const color = selected ? '#3B82F6' : PATH_COLORS[path.type] ?? '#6B7280';

  return new Konva.Line({
    id: path.id,
    points: flatPoints,
    stroke: color,
    strokeWidth: path.strokeWidth,
    lineCap: 'round',
    lineJoin: 'round',
    dash: (path.type === 'gas' || path.type === 'compressed_air') ? [8, 4]
      : (path.type === 'sprinkler_main' || path.type === 'sprinkler_branch' || path.type === 'standpipe') ? [12, 4]
      : (path.type === 'acid_waste') ? [6, 3, 2, 3]
      : undefined,
    hitStrokeWidth: Math.max(path.strokeWidth, 8),
  });
}
