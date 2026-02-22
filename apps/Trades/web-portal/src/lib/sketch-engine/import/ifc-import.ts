// ZAFTO IFC Import — Parse Industry Foundation Classes (DEPTH43)
// Parses IFC 2x3/4 STEP files and extracts wall, door, window, space entities.
// Uses regex-based STEP parser (no web-ifc dependency for v1 — keeps bundle small).
// Full web-ifc integration deferred to future iteration for complex BIM models.

import type { FloorPlanData, Point } from '../types';
import { createEmptyFloorPlan } from '../types';
import {
  createEmptyReport,
  finalizeReport,
  type CompatibilityReport,
} from './compatibility-report';

export interface IfcImportResult {
  plan: FloorPlanData;
  report: CompatibilityReport;
}

interface IfcEntity {
  id: number;
  type: string;
  args: string;
}

/**
 * Import IFC STEP file into FloorPlanData.
 * Extracts IfcWall, IfcDoor, IfcWindow, IfcSpace entities.
 * Cartesian points are resolved to extract positions.
 */
export function importIfc(ifcContent: string, fileName: string): IfcImportResult {
  const report = createEmptyReport('IFC', fileName);
  const plan = createEmptyFloorPlan();

  // Detect version
  const schemaMatch = ifcContent.match(/FILE_SCHEMA\s*\(\s*\(\s*'(IFC\w+)'/);
  if (schemaMatch) {
    report.sourceVersion = schemaMatch[1];
    report.items.push({
      severity: 'info',
      category: 'metadata',
      message: `IFC schema: ${schemaMatch[1]}`,
    });
  }

  // Parse all entities
  const entities = parseStepEntities(ifcContent);
  const entityMap = new Map<number, IfcEntity>();
  for (const entity of entities) {
    entityMap.set(entity.id, entity);
  }

  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `Parsed ${entities.length} IFC entities total.`,
  });

  // Extract Cartesian points for coordinate lookup
  const points = new Map<number, Point>();
  for (const entity of entities) {
    if (entity.type === 'IFCCARTESIANPOINT') {
      const coords = parseCoordList(entity.args);
      if (coords.length >= 2) {
        points.set(entity.id, { x: coords[0], y: coords[1] });
      }
    }
  }

  // Count entity types for reporting
  const typeCounts: Record<string, number> = {};
  for (const entity of entities) {
    typeCounts[entity.type] = (typeCounts[entity.type] || 0) + 1;
  }

  let wallId = 0;
  let labelId = 0;

  // Process walls — IFCWALL, IFCWALLSTANDARDCASE
  const wallEntities = entities.filter((e) =>
    e.type === 'IFCWALL' || e.type === 'IFCWALLSTANDARDCASE',
  );
  for (const wallEntity of wallEntities) {
    const placement = resolveLocalPlacement(wallEntity, entityMap, points);
    if (placement) {
      // Extract wall name from args
      const name = extractStringArg(wallEntity.args, 2); // 3rd arg is Name

      // Get extruded solid dimensions if available
      const repId = extractRefArg(wallEntity.args, 6); // ProductDefinitionShape
      const dims = repId ? resolveExtrudedDimensions(repId, entityMap) : null;

      const length = dims?.length ?? 120; // default 10ft
      const thickness = dims?.width ?? 6;
      const height = dims?.height ?? 96;

      // Create wall from placement + length
      const angle = placement.angle ?? 0;
      plan.walls.push({
        id: `ifc-w-${++wallId}`,
        start: { x: placement.x, y: placement.y },
        end: {
          x: placement.x + length * Math.cos(angle),
          y: placement.y + length * Math.sin(angle),
        },
        thickness,
        height,
      });
      report.converted.walls++;

      // Add label if wall has a name
      if (name && name !== 'Wall') {
        plan.labels.push({
          id: `ifc-l-${++labelId}`,
          position: {
            x: placement.x + (length / 2) * Math.cos(angle),
            y: placement.y + (length / 2) * Math.sin(angle),
          },
          text: name,
          fontSize: 12,
          rotation: 0,
        });
        report.converted.labels++;
      }
    }
  }

  // Process doors — IFCDOOR
  const doorEntities = entities.filter((e) => e.type === 'IFCDOOR');
  for (const doorEntity of doorEntities) {
    const placement = resolveLocalPlacement(doorEntity, entityMap, points);
    if (placement) {
      plan.labels.push({
        id: `ifc-l-${++labelId}`,
        position: { x: placement.x, y: placement.y },
        text: extractStringArg(doorEntity.args, 2) || 'Door',
        fontSize: 10,
        rotation: 0,
      });
      report.converted.labels++;
    }
  }

  // Process windows — IFCWINDOW
  const windowEntities = entities.filter((e) => e.type === 'IFCWINDOW');
  for (const windowEntity of windowEntities) {
    const placement = resolveLocalPlacement(windowEntity, entityMap, points);
    if (placement) {
      plan.labels.push({
        id: `ifc-l-${++labelId}`,
        position: { x: placement.x, y: placement.y },
        text: extractStringArg(windowEntity.args, 2) || 'Window',
        fontSize: 10,
        rotation: 0,
      });
      report.converted.labels++;
    }
  }

  // Process spaces — IFCSPACE → rooms
  const spaceEntities = entities.filter((e) => e.type === 'IFCSPACE');
  for (const spaceEntity of spaceEntities) {
    const placement = resolveLocalPlacement(spaceEntity, entityMap, points);
    const name = extractStringArg(spaceEntity.args, 2) || 'Room';
    if (placement) {
      plan.rooms.push({
        id: `ifc-r-${plan.rooms.length + 1}`,
        name,
        wallIds: [],
        center: { x: placement.x, y: placement.y },
        area: 0, // Can't determine without boundary geometry
      });
      report.converted.rooms++;
    }
  }

  // Report skipped types
  const importedTypes = new Set([
    'IFCWALL', 'IFCWALLSTANDARDCASE', 'IFCDOOR', 'IFCWINDOW', 'IFCSPACE',
    'IFCCARTESIANPOINT', 'IFCLOCALPLACEMENT', 'IFCAXIS2PLACEMENT3D',
    'IFCAXIS2PLACEMENT2D', 'IFCDIRECTION', 'IFCOWNERHISTORY', 'IFCPROJECT',
    'IFCSITE', 'IFCBUILDING', 'IFCBUILDINGSTOREY', 'IFCRELAGGREGATES',
    'IFCRELCONTAINEDINSPATIALSTRUCTURE', 'IFCPERSON', 'IFCORGANIZATION',
    'IFCPERSONANDORGANIZATION', 'IFCAPPLICATION', 'IFCGEOMETRICREPRESENTATIONCONTEXT',
    'IFCGEOMETRICREPRESENTATIONSUBCONTEXT', 'IFCUNITASSIGNMENT', 'IFCSIUNIT',
    'IFCCONVERSIONBASEDUNIT', 'IFCDIMENSIONALEXPONENTS', 'IFCMEASUREWITHUNIT',
    'IFCEXTRUDEDAREASOLID', 'IFCRECTANGLEPROFILEDEF', 'IFCSHAPEREPRESENTATION',
    'IFCPRODUCTDEFINITIONSHAPE',
  ]);

  for (const [type, count] of Object.entries(typeCounts)) {
    if (!importedTypes.has(type)) {
      if (type.includes('MATERIAL') || type.includes('SURFACESTYLE')) {
        report.skipped.materials += count;
      } else if (type.includes('SLAB') || type.includes('STAIR') || type.includes('RAMP') || type.includes('ROOF')) {
        report.skipped.threeDSolids += count;
        report.items.push({
          severity: 'warning',
          category: 'geometry',
          message: `${count} ${type} entity/entities skipped (3D elements not yet supported in 2D import).`,
          entityCount: count,
        });
      } else {
        report.skipped.other += count;
      }
    }
  }

  report.items.push({
    severity: 'info',
    category: 'metadata',
    message: `Import complete: ${plan.walls.length} walls, ${plan.rooms.length} rooms, ${plan.labels.length} labels from IFC.`,
  });

  return { plan, report: finalizeReport(report) };
}

// --- STEP Parser ---

function parseStepEntities(content: string): IfcEntity[] {
  const entities: IfcEntity[] = [];
  // Match: #123=IFCTYPE(args);
  const regex = /#(\d+)\s*=\s*(\w+)\s*\(([^;]*)\)\s*;/g;
  let match;
  while ((match = regex.exec(content)) !== null) {
    entities.push({
      id: parseInt(match[1], 10),
      type: match[2].toUpperCase(),
      args: match[3],
    });
  }
  return entities;
}

function parseCoordList(args: string): number[] {
  // Parse (x,y) or (x,y,z) from IFCCARTESIANPOINT args
  const match = args.match(/\(([^)]+)\)/);
  if (!match) return [];
  return match[1].split(',').map((s) => parseFloat(s.trim())).filter((n) => !isNaN(n));
}

function extractStringArg(args: string, index: number): string | null {
  // Split by comma, respecting parentheses depth
  const parts = splitArgs(args);
  if (index >= parts.length) return null;
  const val = parts[index].trim();
  if (val === '$' || val === '*') return null;
  // Remove quotes
  const match = val.match(/^'(.*)'$/);
  return match ? match[1].replace(/''/g, "'") : null;
}

function extractRefArg(args: string, index: number): number | null {
  const parts = splitArgs(args);
  if (index >= parts.length) return null;
  const val = parts[index].trim();
  const match = val.match(/^#(\d+)$/);
  return match ? parseInt(match[1], 10) : null;
}

function splitArgs(args: string): string[] {
  const result: string[] = [];
  let depth = 0;
  let current = '';
  for (const ch of args) {
    if (ch === '(' || ch === '[') depth++;
    else if (ch === ')' || ch === ']') depth--;
    else if (ch === ',' && depth === 0) {
      result.push(current);
      current = '';
      continue;
    }
    current += ch;
  }
  if (current) result.push(current);
  return result;
}

function resolveLocalPlacement(
  entity: IfcEntity,
  entityMap: Map<number, IfcEntity>,
  points: Map<number, Point>,
): { x: number; y: number; angle?: number } | null {
  // Find the LocalPlacement reference in the entity args
  const parts = splitArgs(entity.args);

  // Product entities: guid, ownerHistory, name, description, objectType, placement, ...
  // Placement is typically at index 5
  for (let i = 4; i < Math.min(parts.length, 7); i++) {
    const refMatch = parts[i]?.trim().match(/^#(\d+)$/);
    if (!refMatch) continue;
    const refEntity = entityMap.get(parseInt(refMatch[1], 10));
    if (!refEntity || refEntity.type !== 'IFCLOCALPLACEMENT') continue;

    // IFCLOCALPLACEMENT(relativePlacement, axis2placement)
    const lpParts = splitArgs(refEntity.args);
    for (const lpPart of lpParts) {
      const axisRef = lpPart.trim().match(/^#(\d+)$/);
      if (!axisRef) continue;
      const axisEntity = entityMap.get(parseInt(axisRef[1], 10));
      if (!axisEntity) continue;

      if (axisEntity.type === 'IFCAXIS2PLACEMENT3D' || axisEntity.type === 'IFCAXIS2PLACEMENT2D') {
        const axisParts = splitArgs(axisEntity.args);
        // First arg is CartesianPoint reference
        const ptRef = axisParts[0]?.trim().match(/^#(\d+)$/);
        if (ptRef) {
          const pt = points.get(parseInt(ptRef[1], 10));
          if (pt) {
            // Check for direction (optional 3rd arg for RefDirection)
            let angle: number | undefined;
            if (axisParts.length >= 3) {
              const dirRef = axisParts[2]?.trim().match(/^#(\d+)$/);
              if (dirRef) {
                const dirEntity = entityMap.get(parseInt(dirRef[1], 10));
                if (dirEntity && dirEntity.type === 'IFCDIRECTION') {
                  const dirCoords = parseCoordList(dirEntity.args);
                  if (dirCoords.length >= 2) {
                    angle = Math.atan2(dirCoords[1], dirCoords[0]);
                  }
                }
              }
            }
            return { x: pt.x, y: pt.y, angle };
          }
        }
      }
    }
  }

  return null;
}

function resolveExtrudedDimensions(
  repRefId: number,
  entityMap: Map<number, IfcEntity>,
): { length: number; width: number; height: number } | null {
  // Walk: ProductDefinitionShape → ShapeRepresentation → ExtrudedAreaSolid → RectangleProfileDef
  const repEntity = entityMap.get(repRefId);
  if (!repEntity) return null;

  // Find ShapeRepresentation refs in ProductDefinitionShape args
  const repParts = splitArgs(repEntity.args);
  for (const part of repParts) {
    const refs = part.match(/#(\d+)/g);
    if (!refs) continue;
    for (const ref of refs) {
      const refId = parseInt(ref.substring(1), 10);
      const shapeRep = entityMap.get(refId);
      if (!shapeRep || shapeRep.type !== 'IFCSHAPEREPRESENTATION') continue;

      // Find ExtrudedAreaSolid in ShapeRepresentation
      const shapeParts = splitArgs(shapeRep.args);
      for (const sp of shapeParts) {
        const solidRefs = sp.match(/#(\d+)/g);
        if (!solidRefs) continue;
        for (const solidRef of solidRefs) {
          const solidId = parseInt(solidRef.substring(1), 10);
          const solid = entityMap.get(solidId);
          if (!solid || solid.type !== 'IFCEXTRUDEDAREASOLID') continue;

          const solidParts = splitArgs(solid.args);
          // Args: profile, position, direction, depth
          const depth = parseFloat(solidParts[3] || '96');

          // Get profile (RectangleProfileDef)
          const profileRef = solidParts[0]?.trim().match(/^#(\d+)$/);
          if (profileRef) {
            const profile = entityMap.get(parseInt(profileRef[1], 10));
            if (profile && profile.type === 'IFCRECTANGLEPROFILEDEF') {
              const profParts = splitArgs(profile.args);
              // Args: profileType, name, position, xDim, yDim
              const xDim = parseFloat(profParts[3] || '120');
              const yDim = parseFloat(profParts[4] || '6');
              return { length: xDim, width: yDim, height: depth };
            }
          }
        }
      }
    }
  }

  return null;
}
