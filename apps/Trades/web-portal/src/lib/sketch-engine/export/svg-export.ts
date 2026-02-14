// ZAFTO SVG Export — Scalable Vector Graphics from FloorPlanData
// SK9+S101: Full vector export with layers, dimensions, trade overlays.
// Opens in browser, Inkscape, Illustrator. No external package needed.

import type { FloorPlanData, TradeLayer, Wall, Point } from '../types';
import { positionOnWall, wallLength } from '../geometry';

function escSvg(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const TRADE_COLORS: Record<string, string> = {
  electrical: '#0000FF',
  plumbing: '#FF0000',
  hvac: '#00AA00',
  damage: '#FF8800',
};

export function generateSvg(
  plan: FloorPlanData,
  options?: { width?: number; tradeLayers?: TradeLayer[] },
): string {
  const width = options?.width ?? 1200;
  const tradeLayers = options?.tradeLayers ?? plan.tradeLayers;

  // Calculate bounds
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const wall of plan.walls) {
    for (const pt of [wall.start, wall.end]) {
      if (pt.x < minX) minX = pt.x;
      if (pt.y < minY) minY = pt.y;
      if (pt.x > maxX) maxX = pt.x;
      if (pt.y > maxY) maxY = pt.y;
    }
  }
  if (minX === Infinity) return '<svg xmlns="http://www.w3.org/2000/svg"></svg>';

  const pad = 24;
  minX -= pad;
  minY -= pad;
  maxX += pad;
  maxY += pad;
  const planW = maxX - minX;
  const planH = maxY - minY;
  const height = width * planH / planW;

  const buf: string[] = [];
  buf.push('<?xml version="1.0" encoding="UTF-8"?>');
  buf.push(
    `<svg xmlns="http://www.w3.org/2000/svg" ` +
    `width="${width}" height="${height.toFixed(0)}" ` +
    `viewBox="${minX.toFixed(2)} ${minY.toFixed(2)} ${planW.toFixed(2)} ${planH.toFixed(2)}">`,
  );

  // Room fills — polygon from wall endpoints
  buf.push('  <g id="rooms" opacity="0.3">');
  for (const room of plan.rooms) {
    const pts = roomWallPointsSvg(room.wallIds, plan.walls);
    if (pts.length >= 3) {
      buf.push(`    <polygon points="${pts}" fill="#D9E8FF" stroke="none" />`);
    }
  }
  buf.push('  </g>');

  // Walls
  buf.push('  <g id="walls" stroke="#333" stroke-width="6" stroke-linecap="round">');
  for (const wall of plan.walls) {
    buf.push(
      `    <line x1="${wall.start.x.toFixed(2)}" y1="${wall.start.y.toFixed(2)}" ` +
      `x2="${wall.end.x.toFixed(2)}" y2="${wall.end.y.toFixed(2)}" />`,
    );
  }
  buf.push('  </g>');

  // Doors
  buf.push('  <g id="doors" stroke="#9933CC" stroke-width="2" fill="none">');
  for (const door of plan.doors) {
    const wall = plan.walls.find((w) => w.id === door.wallId);
    if (!wall) continue;
    const pos = positionOnWall(wall, door.position);
    const len = wallLength(wall);
    const dx = (wall.end.x - wall.start.x) / len;
    const dy = (wall.end.y - wall.start.y) / len;
    const halfW = door.width / 2;
    buf.push(
      `    <line x1="${(pos.x - dx * halfW).toFixed(2)}" y1="${(pos.y - dy * halfW).toFixed(2)}" ` +
      `x2="${(pos.x + dx * halfW).toFixed(2)}" y2="${(pos.y + dy * halfW).toFixed(2)}" />`,
    );
  }
  buf.push('  </g>');

  // Windows
  buf.push('  <g id="windows" stroke="#00CCCC" stroke-width="3">');
  for (const win of plan.windows) {
    const wall = plan.walls.find((w) => w.id === win.wallId);
    if (!wall) continue;
    const pos = positionOnWall(wall, win.position);
    const len = wallLength(wall);
    const dx = (wall.end.x - wall.start.x) / len;
    const dy = (wall.end.y - wall.start.y) / len;
    const halfW = win.width / 2;
    buf.push(
      `    <line x1="${(pos.x - dx * halfW).toFixed(2)}" y1="${(pos.y - dy * halfW).toFixed(2)}" ` +
      `x2="${(pos.x + dx * halfW).toFixed(2)}" y2="${(pos.y + dy * halfW).toFixed(2)}" />`,
    );
  }
  buf.push('  </g>');

  // Fixtures
  buf.push('  <g id="fixtures" fill="#4CAF50">');
  for (const fix of plan.fixtures) {
    buf.push(`    <circle cx="${fix.position.x.toFixed(2)}" cy="${fix.position.y.toFixed(2)}" r="4" />`);
    buf.push(
      `    <text x="${(fix.position.x + 6).toFixed(2)}" y="${(fix.position.y + 3).toFixed(2)}" ` +
      `font-size="5" fill="#333">${escSvg(fix.type)}</text>`,
    );
  }
  buf.push('  </g>');

  // Dimensions
  buf.push('  <g id="dimensions" stroke="#FF0000" stroke-width="0.5">');
  for (const dim of plan.dimensions) {
    buf.push(
      `    <line x1="${dim.start.x.toFixed(2)}" y1="${dim.start.y.toFixed(2)}" ` +
      `x2="${dim.end.x.toFixed(2)}" y2="${dim.end.y.toFixed(2)}" />`,
    );
    const mx = (dim.start.x + dim.end.x) / 2;
    const my = (dim.start.y + dim.end.y) / 2;
    const dist = Math.sqrt((dim.end.x - dim.start.x) ** 2 + (dim.end.y - dim.start.y) ** 2);
    const ft = Math.floor(dist / 12);
    const inches = Math.round(dist % 12);
    buf.push(
      `    <text x="${mx.toFixed(2)}" y="${(my - 3).toFixed(2)}" ` +
      `font-size="4" fill="#FF0000" text-anchor="middle">${escSvg(`${ft}'-${inches}"`)}</text>`,
    );
  }
  buf.push('  </g>');

  // Room labels
  buf.push('  <g id="room-labels">');
  for (const room of plan.rooms) {
    buf.push(
      `    <text x="${room.center.x.toFixed(2)}" y="${room.center.y.toFixed(2)}" ` +
      `font-size="8" font-weight="bold" fill="#333" text-anchor="middle" ` +
      `dominant-baseline="middle">${escSvg(room.name)}</text>`,
    );
    buf.push(
      `    <text x="${room.center.x.toFixed(2)}" y="${(room.center.y + 10).toFixed(2)}" ` +
      `font-size="5" fill="#666" text-anchor="middle">${room.area.toFixed(0)} SF</text>`,
    );
  }
  buf.push('  </g>');

  // Labels
  if (plan.labels.length > 0) {
    buf.push('  <g id="labels">');
    for (const lbl of plan.labels) {
      buf.push(
        `    <text x="${lbl.position.x.toFixed(2)}" y="${lbl.position.y.toFixed(2)}" ` +
        `font-size="${(lbl.fontSize / plan.scale).toFixed(1)}">${escSvg(lbl.text)}</text>`,
      );
    }
    buf.push('  </g>');
  }

  // Trade layers
  for (const tl of tradeLayers) {
    if (!tl.visible) continue;
    const color = TRADE_COLORS[tl.type] ?? '#666';
    buf.push(`  <g id="${tl.type}" opacity="${tl.opacity}">`);

    if (tl.tradeData) {
      for (const elem of tl.tradeData.elements) {
        buf.push(
          `    <circle cx="${elem.position.x.toFixed(2)}" cy="${elem.position.y.toFixed(2)}" r="3" fill="${color}" />`,
        );
        buf.push(
          `    <text x="${(elem.position.x + 5).toFixed(2)}" y="${(elem.position.y + 2).toFixed(2)}" ` +
          `font-size="4" fill="${color}">${escSvg(elem.label ?? elem.type)}</text>`,
        );
      }
      for (const path of tl.tradeData.paths) {
        if (path.points.length >= 2) {
          const pts = path.points.map((p) => `${p.x.toFixed(2)},${p.y.toFixed(2)}`).join(' ');
          buf.push(
            `    <polyline points="${pts}" fill="none" stroke="${color}" stroke-width="1.5" />`,
          );
        }
      }
    }

    if (tl.damageData && tl.damageData.zones.length > 0) {
      for (const zone of tl.damageData.zones) {
        if (zone.points.length >= 3) {
          const pts = zone.points.map((p) => `${p.x.toFixed(2)},${p.y.toFixed(2)}`).join(' ');
          buf.push(
            `    <polygon points="${pts}" fill="${color}" fill-opacity="0.2" ` +
            `stroke="${color}" stroke-width="1" />`,
          );
        }
      }
    }

    buf.push('  </g>');
  }

  buf.push('</svg>');
  return buf.join('\n');
}

function roomWallPointsSvg(wallIds: string[], walls: Wall[]): string {
  const coords: string[] = [];
  for (const wid of wallIds) {
    const wall = walls.find((w) => w.id === wid);
    if (wall) {
      coords.push(`${wall.start.x.toFixed(2)},${wall.start.y.toFixed(2)}`);
      coords.push(`${wall.end.x.toFixed(2)},${wall.end.y.toFixed(2)}`);
    }
  }
  return coords.join(' ');
}
