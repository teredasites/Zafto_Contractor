// ZAFTO FML Export — Floor Markup Language (XML-based open format)
// TypeScript port of lib/services/fml_writer.dart (SK9)
// Origin: Floorplanner open standard. NOT Verisk/Xactimate proprietary.
// Safe for Symbility/Cotality integration. NOT accepted by Xactimate (ESX deferred).

import type { FloorPlanData, Wall } from '../types';
import { wallLength, positionOnWall } from '../geometry';

function escXml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function generateFml(
  plan: FloorPlanData,
  options?: {
    projectTitle?: string;
    companyName?: string;
    address?: string;
    floorNumber?: number;
  },
): string {
  const floorNumber = options?.floorNumber ?? 1;
  const buf: string[] = [];

  buf.push('<?xml version="1.0" encoding="UTF-8"?>');
  buf.push(
    `<floor-plan version="1.0" format="fml" generator="zafto" ` +
    `floor="${floorNumber}" scale="${plan.scale}">`,
  );

  // Metadata
  buf.push('  <metadata>');
  if (options?.projectTitle) buf.push(`    <title>${escXml(options.projectTitle)}</title>`);
  if (options?.companyName) buf.push(`    <company>${escXml(options.companyName)}</company>`);
  if (options?.address) buf.push(`    <address>${escXml(options.address)}</address>`);
  buf.push(`    <created>${new Date().toISOString()}</created>`);
  buf.push(`    <units>${plan.units}</units>`);
  buf.push('  </metadata>');

  // Walls
  if (plan.walls.length > 0) {
    buf.push('  <walls>');
    for (const wall of plan.walls) {
      buf.push(
        `    <wall id="${escXml(wall.id)}" ` +
        `x1="${wall.start.x.toFixed(2)}" y1="${wall.start.y.toFixed(2)}" ` +
        `x2="${wall.end.x.toFixed(2)}" y2="${wall.end.y.toFixed(2)}" ` +
        `thickness="${wall.thickness}" height="${wall.height}" />`,
      );
    }
    buf.push('  </walls>');
  }

  // Rooms
  if (plan.rooms.length > 0) {
    buf.push('  <rooms>');
    for (const room of plan.rooms) {
      buf.push(
        `    <room id="${escXml(room.id)}" ` +
        `name="${escXml(room.name)}" ` +
        `area-sf="${room.area.toFixed(2)}" ` +
        `cx="${room.center.x.toFixed(2)}" ` +
        `cy="${room.center.y.toFixed(2)}">`,
      );
      if (room.wallIds.length > 0) {
        buf.push('      <wall-refs>');
        for (const wid of room.wallIds) {
          buf.push(`        <wall-ref id="${escXml(wid)}" />`);
        }
        buf.push('      </wall-refs>');
      }
      buf.push('    </room>');
    }
    buf.push('  </rooms>');
  }

  // Openings (doors + windows)
  if (plan.doors.length > 0 || plan.windows.length > 0) {
    buf.push('  <openings>');
    for (const door of plan.doors) {
      const wall = plan.walls.find((w) => w.id === door.wallId);
      if (!wall) continue;
      const pos = positionOnWall(wall, door.position);
      buf.push(
        `    <opening type="door" id="${escXml(door.id)}" ` +
        `wall-id="${escXml(door.wallId)}" ` +
        `position="${door.position.toFixed(4)}" ` +
        `width="${door.width}" ` +
        `door-type="${door.type}" ` +
        `x="${pos.x.toFixed(2)}" y="${pos.y.toFixed(2)}" />`,
      );
    }
    for (const win of plan.windows) {
      const wall = plan.walls.find((w) => w.id === win.wallId);
      if (!wall) continue;
      const pos = positionOnWall(wall, win.position);
      buf.push(
        `    <opening type="window" id="${escXml(win.id)}" ` +
        `wall-id="${escXml(win.wallId)}" ` +
        `position="${win.position.toFixed(4)}" ` +
        `width="${win.width}" ` +
        `window-type="${win.type}" ` +
        `x="${pos.x.toFixed(2)}" y="${pos.y.toFixed(2)}" />`,
      );
    }
    buf.push('  </openings>');
  }

  // Fixtures
  if (plan.fixtures.length > 0) {
    buf.push('  <fixtures>');
    for (const fix of plan.fixtures) {
      buf.push(
        `    <fixture id="${escXml(fix.id)}" ` +
        `type="${fix.type}" ` +
        `x="${fix.position.x.toFixed(2)}" y="${fix.position.y.toFixed(2)}" ` +
        `rotation="${fix.rotation}" />`,
      );
    }
    buf.push('  </fixtures>');
  }

  // Dimensions
  if (plan.dimensions.length > 0) {
    buf.push('  <dimensions>');
    for (const dim of plan.dimensions) {
      const dist = Math.sqrt(
        (dim.end.x - dim.start.x) ** 2 + (dim.end.y - dim.start.y) ** 2,
      );
      const ft = Math.floor(dist / 12);
      const inches = Math.round(dist % 12);
      buf.push(
        `    <dimension id="${escXml(dim.id)}" ` +
        `x1="${dim.start.x.toFixed(2)}" y1="${dim.start.y.toFixed(2)}" ` +
        `x2="${dim.end.x.toFixed(2)}" y2="${dim.end.y.toFixed(2)}" ` +
        `label="${escXml(`${ft}'-${inches}"`)}" ` +
        `auto="${dim.isAuto}" />`,
      );
    }
    buf.push('  </dimensions>');
  }

  // Labels
  if (plan.labels.length > 0) {
    buf.push('  <labels>');
    for (const lbl of plan.labels) {
      buf.push(
        `    <label id="${escXml(lbl.id)}" ` +
        `x="${lbl.position.x.toFixed(2)}" y="${lbl.position.y.toFixed(2)}" ` +
        `font-size="${lbl.fontSize}" ` +
        `rotation="${lbl.rotation}">${escXml(lbl.text)}</label>`,
      );
    }
    buf.push('  </labels>');
  }

  buf.push('</floor-plan>');
  return buf.join('\n');
}
