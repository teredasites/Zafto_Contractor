// ZAFTO Import Compatibility Report — DEPTH43
// Tracks what imported successfully and what was lost during file conversion.
// Honest transparency — never silently drop data.

export type ImportSeverity = 'info' | 'warning' | 'error';

export interface ImportReportItem {
  severity: ImportSeverity;
  category: string; // 'geometry' | 'layers' | 'text' | 'blocks' | 'materials' | 'dimensions' | 'metadata'
  message: string;
  entityCount?: number; // how many items affected
}

export interface CompatibilityReport {
  sourceFormat: string; // 'DXF' | 'SVG' | 'glTF' | 'OBJ' | 'IFC'
  sourceVersion?: string; // e.g. 'AC1015' for DXF R2000
  fileName: string;
  importedAt: string; // ISO 8601
  // What converted successfully
  converted: {
    walls: number;
    rooms: number;
    doors: number;
    windows: number;
    fixtures: number;
    labels: number;
    dimensions: number;
    tradeLayers: number;
  };
  // What was lost or unsupported
  skipped: {
    blocks: number;
    hatches: number;
    threeDSolids: number;
    customLayers: number;
    materials: number;
    annotations: number;
    other: number;
  };
  items: ImportReportItem[];
  // Summary
  totalEntitiesInSource: number;
  totalConverted: number;
  totalSkipped: number;
  conversionRate: number; // 0-100 percentage
}

export function createEmptyReport(format: string, fileName: string): CompatibilityReport {
  return {
    sourceFormat: format,
    fileName,
    importedAt: new Date().toISOString(),
    converted: { walls: 0, rooms: 0, doors: 0, windows: 0, fixtures: 0, labels: 0, dimensions: 0, tradeLayers: 0 },
    skipped: { blocks: 0, hatches: 0, threeDSolids: 0, customLayers: 0, materials: 0, annotations: 0, other: 0 },
    items: [],
    totalEntitiesInSource: 0,
    totalConverted: 0,
    totalSkipped: 0,
    conversionRate: 0,
  };
}

export function finalizeReport(report: CompatibilityReport): CompatibilityReport {
  const c = report.converted;
  report.totalConverted = c.walls + c.rooms + c.doors + c.windows + c.fixtures + c.labels + c.dimensions + c.tradeLayers;
  const s = report.skipped;
  report.totalSkipped = s.blocks + s.hatches + s.threeDSolids + s.customLayers + s.materials + s.annotations + s.other;
  report.totalEntitiesInSource = report.totalConverted + report.totalSkipped;
  report.conversionRate = report.totalEntitiesInSource > 0
    ? Math.round((report.totalConverted / report.totalEntitiesInSource) * 100)
    : 100;
  return report;
}
