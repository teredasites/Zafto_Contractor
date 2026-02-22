// ZAFTO SVG Import — Parse SVG floor plans into FloorPlanData (DEPTH43)
// Handles: line, polyline, polygon, rect, path (L/M/H/V commands), text.
// Uses native DOMParser (browser API). No external dependencies.

import type { FloorPlanData, Point } from '../types';
import { createEmptyFloorPlan } from '../types';
import {
  createEmptyReport,
  finalizeReport,
  type CompatibilityReport,
} from './compatibility-report';

export interface SvgImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

let wallId = 0;
let labelId = 0;

function nextWallId(): string { return `svg-w-${++wallId}`; }
function nextLabelId(): string { return `svg-l-${++labelId}`; }

/**
 * Import SVG content into FloorPlanData.
 * Parses lines, polylines, polygons, rects, simple paths, and text elements.
 */
export function importSvg(svgContent: string, fileName: string): SvgImportResult {
  wallId = 0;
  labelId = 0;

  const report = createEmptyReport('SVG', fileName);
  const plan = createEmptyFloorPlan();

  // Parse SVG using DOMParser
  const parser = new DOMParser();
  const doc = parser.parseFromString(svgContent, 'image/svg+xml');

  // Check for parse errors
  const parseError = doc.querySelector('parsererror');
  if (parseError) {
    report.items.push({
      severity: 'error',
      category: 'metadata',
      message: `SVG parse error: ${parseError.textContent?.substring(0, 200)}`,
    });
    return { plan, report: finalizeReport(report) };
  }

  const svg = doc.querySelector('svg');
  if (!svg) {
    report.items.push({
      severity: 'error',
      category: 'metadata',
      message: 'No <svg> root element found',
    });
    return { plan, report: finalizeReport(report) };
  }

  // Extract viewBox for coordinate mapping
  const viewBox = svg.getAttribute('viewBox');
  if (viewBox) {
    report.items.push({
      severity: 'info',
      category: 'metadata',
      message: `SVG viewBox: ${viewBox}`,
    });
  }

  // Process all elements recursively
  processElement(svg, plan, report);

  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `Import complete: ${plan.walls.length} walls, ${plan.labels.length} labels created from SVG.`,
  });

  return { plan, report: finalizeReport(report) };
}

function processElement(element: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  // Process children
  for (const child of Array.from(element.children)) {
    const tag = child.tagName.toLowerCase();

    switch (tag) {
      case 'line':
        processLine(child, plan, report);
        break;
      case 'polyline':
        processPolyline(child, plan, report, false);
        break;
      case 'polygon':
        processPolyline(child, plan, report, true);
        break;
      case 'rect':
        processRect(child, plan, report);
        break;
      case 'path':
        processPath(child, plan, report);
        break;
      case 'text':
        processText(child, plan, report);
        break;
      case 'circle':
      case 'ellipse':
        processCircle(child, plan, report);
        break;
      case 'g':
      case 'svg':
      case 'defs':
      case 'clipPath':
        // Recurse into groups
        processElement(child, plan, report);
        break;
      case 'style':
      case 'title':
      case 'desc':
      case 'metadata':
        // Informational — skip
        break;
      case 'image':
        report.skipped.other++;
        report.items.push({
          severity: 'warning',
          category: 'materials',
          message: 'Embedded image element skipped (raster images not importable as geometry)',
        });
        break;
      case 'use':
        report.skipped.blocks++;
        report.items.push({
          severity: 'warning',
          category: 'blocks',
          message: '<use> reference skipped (symbol reuse not resolved in v1)',
        });
        break;
      default:
        // Unknown elements — recurse in case they contain geometry
        if (child.children.length > 0) {
          processElement(child, plan, report);
        }
        break;
    }
  }
}

function processLine(el: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  const x1 = parseFloat(el.getAttribute('x1') || '0');
  const y1 = parseFloat(el.getAttribute('y1') || '0');
  const x2 = parseFloat(el.getAttribute('x2') || '0');
  const y2 = parseFloat(el.getAttribute('y2') || '0');

  if (isNaN(x1) || isNaN(y1) || isNaN(x2) || isNaN(y2)) return;

  plan.walls.push({
    id: nextWallId(),
    start: { x: x1, y: y1 },
    end: { x: x2, y: y2 },
    thickness: 6,
    height: 96,
  });
  report.converted.walls++;
}

function processPolyline(el: Element, plan: FloorPlanData, report: CompatibilityReport, closed: boolean): void {
  const pointsStr = el.getAttribute('points');
  if (!pointsStr) return;

  const points = parsePointsList(pointsStr);
  if (points.length < 2) return;

  // Convert to wall segments
  for (let i = 0; i < points.length - 1; i++) {
    plan.walls.push({
      id: nextWallId(),
      start: points[i],
      end: points[i + 1],
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }

  // Close polygon
  if (closed && points.length >= 3) {
    plan.walls.push({
      id: nextWallId(),
      start: points[points.length - 1],
      end: points[0],
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processRect(el: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  const x = parseFloat(el.getAttribute('x') || '0');
  const y = parseFloat(el.getAttribute('y') || '0');
  const w = parseFloat(el.getAttribute('width') || '0');
  const h = parseFloat(el.getAttribute('height') || '0');

  if (w <= 0 || h <= 0) return;

  // Convert rect to 4 wall segments
  const corners: Point[] = [
    { x, y },
    { x: x + w, y },
    { x: x + w, y: y + h },
    { x, y: y + h },
  ];

  for (let i = 0; i < 4; i++) {
    plan.walls.push({
      id: nextWallId(),
      start: corners[i],
      end: corners[(i + 1) % 4],
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processPath(el: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  const d = el.getAttribute('d');
  if (!d) return;

  // Parse SVG path data — support M, L, H, V, Z commands (absolute and relative)
  const points = parsePathToPoints(d);

  if (points.length < 2) {
    report.skipped.other++;
    return;
  }

  for (let i = 0; i < points.length - 1; i++) {
    plan.walls.push({
      id: nextWallId(),
      start: points[i],
      end: points[i + 1],
      thickness: 6,
      height: 96,
    });
    report.converted.walls++;
  }
}

function processText(el: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  const text = el.textContent?.trim();
  if (!text) return;

  const x = parseFloat(el.getAttribute('x') || '0');
  const y = parseFloat(el.getAttribute('y') || '0');
  const fontSize = parseFloat(el.getAttribute('font-size') || '14');

  plan.labels.push({
    id: nextLabelId(),
    position: { x, y },
    text,
    fontSize: isNaN(fontSize) ? 14 : fontSize * 4,
    rotation: 0,
  });
  report.converted.labels++;
}

function processCircle(el: Element, plan: FloorPlanData, report: CompatibilityReport): void {
  const tag = el.tagName.toLowerCase();
  let cx: number, cy: number, rx: number, ry: number;

  if (tag === 'circle') {
    cx = parseFloat(el.getAttribute('cx') || '0');
    cy = parseFloat(el.getAttribute('cy') || '0');
    rx = ry = parseFloat(el.getAttribute('r') || '0');
  } else {
    cx = parseFloat(el.getAttribute('cx') || '0');
    cy = parseFloat(el.getAttribute('cy') || '0');
    rx = parseFloat(el.getAttribute('rx') || '0');
    ry = parseFloat(el.getAttribute('ry') || '0');
  }

  if (rx <= 0 && ry <= 0) return;

  // Approximate circle/ellipse as polygon
  const segments = 12;
  for (let i = 0; i < segments; i++) {
    const a1 = (2 * Math.PI * i) / segments;
    const a2 = (2 * Math.PI * (i + 1)) / segments;
    plan.walls.push({
      id: nextWallId(),
      start: { x: cx + rx * Math.cos(a1), y: cy + ry * Math.sin(a1) },
      end: { x: cx + rx * Math.cos(a2), y: cy + ry * Math.sin(a2) },
      thickness: 4,
      height: 96,
    });
    report.converted.walls++;
  }
}

// --- Helpers ---

function parsePointsList(str: string): Point[] {
  const points: Point[] = [];
  // Points can be "x1,y1 x2,y2" or "x1 y1 x2 y2"
  const nums = str.trim().split(/[\s,]+/).map(Number);
  for (let i = 0; i < nums.length - 1; i += 2) {
    if (!isNaN(nums[i]) && !isNaN(nums[i + 1])) {
      points.push({ x: nums[i], y: nums[i + 1] });
    }
  }
  return points;
}

function parsePathToPoints(d: string): Point[] {
  const points: Point[] = [];
  let currentX = 0;
  let currentY = 0;
  let startX = 0;
  let startY = 0;

  // Tokenize: split into commands and their numeric arguments
  const tokens = d.match(/[MmLlHhVvZzCcSsQqTtAa]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?/g);
  if (!tokens) return points;

  let cmd = '';
  let i = 0;

  while (i < tokens.length) {
    const token = tokens[i];

    if (/^[MmLlHhVvZzCcSsQqTtAa]$/.test(token)) {
      cmd = token;
      i++;
      continue;
    }

    const val = parseFloat(token);
    if (isNaN(val)) { i++; continue; }

    switch (cmd) {
      case 'M': {
        currentX = val;
        const y = parseFloat(tokens[++i] || '0');
        currentY = y;
        startX = currentX;
        startY = currentY;
        points.push({ x: currentX, y: currentY });
        cmd = 'L'; // subsequent coords are implicit L
        break;
      }
      case 'm': {
        currentX += val;
        const y = parseFloat(tokens[++i] || '0');
        currentY += y;
        startX = currentX;
        startY = currentY;
        points.push({ x: currentX, y: currentY });
        cmd = 'l';
        break;
      }
      case 'L': {
        currentX = val;
        const y = parseFloat(tokens[++i] || '0');
        currentY = y;
        points.push({ x: currentX, y: currentY });
        break;
      }
      case 'l': {
        currentX += val;
        const y = parseFloat(tokens[++i] || '0');
        currentY += y;
        points.push({ x: currentX, y: currentY });
        break;
      }
      case 'H':
        currentX = val;
        points.push({ x: currentX, y: currentY });
        break;
      case 'h':
        currentX += val;
        points.push({ x: currentX, y: currentY });
        break;
      case 'V':
        currentY = val;
        points.push({ x: currentX, y: currentY });
        break;
      case 'v':
        currentY += val;
        points.push({ x: currentX, y: currentY });
        break;
      case 'Z':
      case 'z':
        // Close path — add wall back to start
        if (Math.abs(currentX - startX) > 0.01 || Math.abs(currentY - startY) > 0.01) {
          points.push({ x: startX, y: startY });
        }
        currentX = startX;
        currentY = startY;
        break;
      case 'C':
      case 'c':
      case 'S':
      case 's':
      case 'Q':
      case 'q':
      case 'T':
      case 't':
      case 'A':
      case 'a': {
        // Bezier curves and arcs — approximate by skipping to endpoint
        // C: 6 params, S: 4, Q: 4, T: 2, A: 7
        const paramCount: Record<string, number> = {
          C: 6, c: 6, S: 4, s: 4, Q: 4, q: 4, T: 2, t: 2, A: 7, a: 7,
        };
        const skip = (paramCount[cmd] ?? 2) - 1; // already consumed first
        for (let j = 0; j < skip; j++) { i++; }
        // The last two params are the endpoint (except A which is different)
        if (cmd === 'C' || cmd === 'S' || cmd === 'Q') {
          currentX = parseFloat(tokens[i - 1] || '0');
          currentY = parseFloat(tokens[i] || '0');
        } else if (cmd === 'c' || cmd === 's' || cmd === 'q') {
          currentX += parseFloat(tokens[i - 1] || '0');
          currentY += parseFloat(tokens[i] || '0');
        } else if (cmd === 'T') {
          currentX = val;
          currentY = parseFloat(tokens[i] || '0');
        } else if (cmd === 't') {
          currentX += val;
          currentY += parseFloat(tokens[i] || '0');
        } else if (cmd === 'A' || cmd === 'a') {
          // A: rx ry rotation large-arc sweep x y
          const ex = parseFloat(tokens[i - 1] || '0');
          const ey = parseFloat(tokens[i] || '0');
          if (cmd === 'A') { currentX = ex; currentY = ey; }
          else { currentX += ex; currentY += ey; }
        }
        points.push({ x: currentX, y: currentY });
        break;
      }
      default:
        break;
    }
    i++;
  }

  return points;
}
