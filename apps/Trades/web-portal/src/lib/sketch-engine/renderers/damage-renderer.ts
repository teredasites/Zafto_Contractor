// ZAFTO Damage Renderer — Konva shapes for damage zones, moisture, barriers (SK6)
// IICRC classification colors, containment lines, equipment markers.

import Konva from 'konva';
import type {
  DamageZone,
  MoistureReading,
  ContainmentLine,
  TradeElement,
  BarrierType,
} from '../types';

// IICRC Category colors
const CATEGORY_COLORS: Record<string, string> = {
  '1': '#3B82F6', // Clean water
  '2': '#F59E0B', // Gray water
  '3': '#EF4444', // Black water
};

// Damage class outline colors
const CLASS_COLORS: Record<string, string> = {
  '1': '#10B981', // Minor
  '2': '#F59E0B', // Significant
  '3': '#EF4444', // Extensive
  '4': '#7C3AED', // Specialty
};

// Moisture severity colors
function moistureColor(value: number): string {
  if (value < 15) return '#10B981'; // normal
  if (value < 30) return '#F59E0B'; // elevated
  if (value < 50) return '#F97316'; // high
  return '#EF4444'; // critical
}

export function createDamageZoneShape(
  zone: DamageZone,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({ id: zone.id });

  const flatPoints = zone.points.flatMap((p) => [p.x, p.y]);
  const fillColor = CATEGORY_COLORS[zone.iicrcCategory] ?? '#6B7280';
  const strokeColor = CLASS_COLORS[zone.damageClass] ?? '#6B7280';

  // Fill polygon
  group.add(
    new Konva.Line({
      points: flatPoints,
      fill: fillColor,
      opacity: 0.15,
      closed: true,
      listening: false,
    }),
  );

  // Stroke outline
  group.add(
    new Konva.Line({
      points: flatPoints,
      stroke: selected ? '#3B82F6' : strokeColor,
      strokeWidth: selected ? 3 : 2,
      closed: true,
      dash: [6, 4],
    }),
  );

  // Label
  if (zone.label || zone.damageClass) {
    const cx =
      zone.points.reduce((s, p) => s + p.x, 0) / zone.points.length;
    const cy =
      zone.points.reduce((s, p) => s + p.y, 0) / zone.points.length;

    group.add(
      new Konva.Text({
        x: cx - 20,
        y: cy - 6,
        text: zone.label ?? `C${zone.damageClass}/Cat${zone.iicrcCategory}`,
        fontSize: 10,
        fill: strokeColor,
        fontFamily: 'Inter',
        fontStyle: 'bold',
        width: 40,
        align: 'center',
      }),
    );
  }

  return group;
}

export function createMoistureReadingShape(
  reading: MoistureReading,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({
    id: reading.id,
    x: reading.position.x,
    y: reading.position.y,
  });

  const color = moistureColor(reading.value);
  const radius = 8 + Math.min(reading.value / 10, 6);

  // Outer glow
  group.add(
    new Konva.Circle({
      radius: radius + 4,
      fill: color,
      opacity: 0.15,
      listening: false,
    }),
  );

  // Main circle
  group.add(
    new Konva.Circle({
      radius,
      fill: color,
      opacity: 0.4,
      stroke: selected ? '#3B82F6' : color,
      strokeWidth: selected ? 2 : 1,
    }),
  );

  // Value text
  group.add(
    new Konva.Text({
      text: `${reading.value}%`,
      x: -10,
      y: -5,
      fontSize: 9,
      fill: '#FFFFFF',
      fontFamily: 'Inter',
      fontStyle: 'bold',
      width: 20,
      align: 'center',
    }),
  );

  // Material label
  group.add(
    new Konva.Text({
      text: reading.material,
      x: -15,
      y: radius + 4,
      fontSize: 8,
      fill: color,
      fontFamily: 'Inter',
      width: 30,
      align: 'center',
    }),
  );

  return group;
}

export function createContainmentLineShape(
  line: ContainmentLine,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({ id: line.id });

  // Dashed containment line
  group.add(
    new Konva.Line({
      points: [line.start.x, line.start.y, line.end.x, line.end.y],
      stroke: selected ? '#3B82F6' : '#EF4444',
      strokeWidth: 2,
      dash: [10, 5],
      lineCap: 'round',
    }),
  );

  // Barrier icon at midpoint
  const mx = (line.start.x + line.end.x) / 2;
  const my = (line.start.y + line.end.y) / 2;

  group.add(
    new Konva.Circle({
      x: mx,
      y: my,
      radius: 6,
      fill: '#EF4444',
      opacity: 0.3,
    }),
  );

  group.add(
    new Konva.Text({
      x: mx - 8,
      y: my - 4,
      text: barrierAbbrev(line.barrierType),
      fontSize: 7,
      fill: '#EF4444',
      fontFamily: 'Inter',
      fontStyle: 'bold',
      width: 16,
      align: 'center',
    }),
  );

  return group;
}

export function createBarrierMarkerShape(
  element: TradeElement,
  selected: boolean,
): Konva.Group {
  const group = new Konva.Group({
    id: element.id,
    x: element.position.x,
    y: element.position.y,
    rotation: element.rotation,
  });

  const color = selected ? '#3B82F6' : '#EF4444';
  const s = 14;

  // Equipment icon (rectangle with label)
  group.add(
    new Konva.Rect({
      x: -s,
      y: -s * 0.6,
      width: s * 2,
      height: s * 1.2,
      stroke: color,
      strokeWidth: 1.5,
      cornerRadius: 3,
      fill: color,
      opacity: 0.1,
    }),
  );

  group.add(
    new Konva.Text({
      text: barrierAbbrev(element.type as unknown as BarrierType),
      x: -s,
      y: -4,
      fontSize: 8,
      fill: color,
      fontFamily: 'Inter',
      fontStyle: 'bold',
      width: s * 2,
      align: 'center',
    }),
  );

  return group;
}

function barrierAbbrev(type: BarrierType): string {
  switch (type) {
    case 'dehumidifier':
      return 'DH';
    case 'airMover':
      return 'AM';
    case 'airScrubber':
      return 'AS';
    case 'heater':
      return 'HT';
    case 'containmentPole':
      return 'CP';
    case 'negativePressure':
      return 'NP';
    case 'moistureTrap':
      return 'MT';
    case 'thermometer':
      return 'TH';
    default:
      return '??';
  }
}
