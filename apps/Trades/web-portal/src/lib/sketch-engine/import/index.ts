// ZAFTO Sketch Engine Import — barrel export (DEPTH43)
// Unified import system for DXF, SVG, OBJ, glTF/GLB, IFC.

export { importDxf, type DxfImportResult } from './dxf-import';
export { importSvg, type SvgImportResult } from './svg-import';
export { importObj, type ObjImportResult } from './obj-import';
export { importGltf, type GltfImportResult } from './gltf-import';
export { importIfc, type IfcImportResult } from './ifc-import';
export { detectFormat, type DetectedFormat, type FormatDetectionResult } from './format-detection';
export {
  type CompatibilityReport,
  type ImportReportItem,
  type ImportSeverity,
  createEmptyReport,
  finalizeReport,
} from './compatibility-report';

import type { FloorPlanData } from '../types';
import type { CompatibilityReport } from './compatibility-report';
import { detectFormat } from './format-detection';
import { importDxf } from './dxf-import';
import { importSvg } from './svg-import';
import { importObj } from './obj-import';
import { importGltf } from './gltf-import';
import { importIfc } from './ifc-import';
import { createEmptyReport, finalizeReport } from './compatibility-report';

export interface ImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

/**
 * Auto-detect format and import a file into FloorPlanData.
 * Accepts text content or ArrayBuffer (for binary formats like GLB).
 */
export async function autoImport(
  content: string | ArrayBuffer,
  fileName: string,
): Promise<ImportResult> {
  const detection = detectFormat(content, fileName);

  if (!detection.canImport) {
    const report = createEmptyReport(detection.format, fileName);
    report.items.push({
      severity: 'error',
      category: 'metadata',
      message: `Unsupported file format: ${detection.description}`,
    });
    const { createEmptyFloorPlan } = await import('../types');
    return { plan: createEmptyFloorPlan(), report: finalizeReport(report) };
  }

  // Text content required for text-based formats
  const text = typeof content === 'string'
    ? content
    : new TextDecoder().decode(content);

  switch (detection.format) {
    case 'dxf':
      return importDxf(text, fileName);
    case 'svg':
      return importSvg(text, fileName);
    case 'obj':
      return importObj(text, fileName);
    case 'gltf':
      return importGltf(text, fileName);
    case 'glb':
      return importGltf(content instanceof ArrayBuffer ? content : new TextEncoder().encode(text).buffer, fileName);
    case 'ifc':
      return importIfc(text, fileName);
    case 'fml':
      // FML import reuses our own format — round trip
      return importFml(text, fileName);
    default: {
      const report = createEmptyReport('unknown', fileName);
      report.items.push({
        severity: 'error',
        category: 'metadata',
        message: `Cannot import format: ${detection.format}`,
      });
      const { createEmptyFloorPlan } = await import('../types');
      return { plan: createEmptyFloorPlan(), report: finalizeReport(report) };
    }
  }
}

/**
 * Import our own FML format back (round-trip).
 */
function importFml(fmlContent: string, fileName: string): ImportResult {
  const report = createEmptyReport('FML', fileName);
  const { createEmptyFloorPlan } = require('../types');
  const plan = createEmptyFloorPlan();

  const parser = new DOMParser();
  const doc = parser.parseFromString(fmlContent, 'text/xml');
  const root = doc.querySelector('floor-plan');

  if (!root) {
    report.items.push({
      severity: 'error',
      category: 'metadata',
      message: 'No <floor-plan> root element found',
    });
    return { plan, report: finalizeReport(report) };
  }

  // Scale
  const scale = parseFloat(root.getAttribute('scale') || '4');
  plan.scale = scale;

  // Units
  const units = root.querySelector('metadata > units')?.textContent;
  if (units === 'metric' || units === 'imperial') plan.units = units;

  // Walls
  const wallEls = root.querySelectorAll('walls > wall');
  for (const el of Array.from(wallEls)) {
    plan.walls.push({
      id: el.getAttribute('id') || `fml-w-${plan.walls.length}`,
      start: {
        x: parseFloat(el.getAttribute('x1') || '0'),
        y: parseFloat(el.getAttribute('y1') || '0'),
      },
      end: {
        x: parseFloat(el.getAttribute('x2') || '0'),
        y: parseFloat(el.getAttribute('y2') || '0'),
      },
      thickness: parseFloat(el.getAttribute('thickness') || '6'),
      height: parseFloat(el.getAttribute('height') || '96'),
    });
    report.converted.walls++;
  }

  // Rooms
  const roomEls = root.querySelectorAll('rooms > room');
  for (const el of Array.from(roomEls)) {
    const wallRefs = Array.from(el.querySelectorAll('wall-ref')).map(
      (ref) => ref.getAttribute('id') || '',
    );
    plan.rooms.push({
      id: el.getAttribute('id') || `fml-r-${plan.rooms.length}`,
      name: el.getAttribute('name') || 'Room',
      wallIds: wallRefs,
      center: {
        x: parseFloat(el.getAttribute('cx') || '0'),
        y: parseFloat(el.getAttribute('cy') || '0'),
      },
      area: parseFloat(el.getAttribute('area-sf') || '0'),
    });
    report.converted.rooms++;
  }

  // Openings (doors + windows)
  const openingEls = root.querySelectorAll('openings > opening');
  for (const el of Array.from(openingEls)) {
    const type = el.getAttribute('type');
    if (type === 'door') {
      plan.doors.push({
        id: el.getAttribute('id') || `fml-d-${plan.doors.length}`,
        wallId: el.getAttribute('wall-id') || '',
        position: parseFloat(el.getAttribute('position') || '0.5'),
        width: parseFloat(el.getAttribute('width') || '36'),
        type: (el.getAttribute('door-type') as any) || 'single',
      });
      report.converted.doors++;
    } else if (type === 'window') {
      plan.windows.push({
        id: el.getAttribute('id') || `fml-win-${plan.windows.length}`,
        wallId: el.getAttribute('wall-id') || '',
        position: parseFloat(el.getAttribute('position') || '0.5'),
        width: parseFloat(el.getAttribute('width') || '36'),
        type: (el.getAttribute('window-type') as any) || 'standard',
      });
      report.converted.windows++;
    }
  }

  // Fixtures
  const fixtureEls = root.querySelectorAll('fixtures > fixture');
  for (const el of Array.from(fixtureEls)) {
    plan.fixtures.push({
      id: el.getAttribute('id') || `fml-f-${plan.fixtures.length}`,
      position: {
        x: parseFloat(el.getAttribute('x') || '0'),
        y: parseFloat(el.getAttribute('y') || '0'),
      },
      type: (el.getAttribute('type') as any) || 'column',
      rotation: parseFloat(el.getAttribute('rotation') || '0'),
    });
    report.converted.fixtures++;
  }

  // Dimensions
  const dimEls = root.querySelectorAll('dimensions > dimension');
  for (const el of Array.from(dimEls)) {
    plan.dimensions.push({
      id: el.getAttribute('id') || `fml-dim-${plan.dimensions.length}`,
      start: {
        x: parseFloat(el.getAttribute('x1') || '0'),
        y: parseFloat(el.getAttribute('y1') || '0'),
      },
      end: {
        x: parseFloat(el.getAttribute('x2') || '0'),
        y: parseFloat(el.getAttribute('y2') || '0'),
      },
      offset: 12,
      isAuto: el.getAttribute('auto') === 'true',
    });
    report.converted.dimensions++;
  }

  // Labels
  const labelEls = root.querySelectorAll('labels > label');
  for (const el of Array.from(labelEls)) {
    plan.labels.push({
      id: el.getAttribute('id') || `fml-l-${plan.labels.length}`,
      position: {
        x: parseFloat(el.getAttribute('x') || '0'),
        y: parseFloat(el.getAttribute('y') || '0'),
      },
      text: el.textContent || '',
      fontSize: parseFloat(el.getAttribute('font-size') || '14'),
      rotation: parseFloat(el.getAttribute('rotation') || '0'),
    });
    report.converted.labels++;
  }

  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `FML round-trip import: ${plan.walls.length} walls, ${plan.rooms.length} rooms, ${plan.doors.length} doors, ${plan.windows.length} windows.`,
  });

  return { plan, report: finalizeReport(report) };
}
