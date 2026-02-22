// ZAFTO IFC Export — Industry Foundation Classes (DEPTH43)
// Generates IFC 2x3 (ISO 10303-21 STEP format) for BIM interoperability.
// Opens in Revit, ArchiCAD, Navisworks, BIMcollab, and open-source IFC viewers.
// No external dependencies — generates STEP format directly.

import type { FloorPlanData, Wall, Point } from '../types';
import { wallLength, positionOnWall } from '../geometry';

// IFC entity counter
let entityId = 0;
function nextId(): number { return ++entityId; }

/**
 * Generate IFC 2x3 content from FloorPlanData.
 * Exports walls, doors, windows, rooms as IfcWall, IfcDoor, IfcWindow, IfcSpace.
 */
export function generateIfc(
  plan: FloorPlanData,
  options?: {
    projectTitle?: string;
    companyName?: string;
    buildingName?: string;
    floorName?: string;
  },
): string {
  entityId = 0;
  const buf: string[] = [];

  const projectTitle = options?.projectTitle ?? 'Floor Plan';
  const company = options?.companyName ?? 'Zafto';
  const buildingName = options?.buildingName ?? 'Building';
  const floorName = options?.floorName ?? 'Ground Floor';
  const timestamp = new Date().toISOString().replace(/[-:]/g, '').split('.')[0];

  // IFC STEP header
  buf.push('ISO-10303-21;');
  buf.push('HEADER;');
  buf.push(`FILE_DESCRIPTION(('ViewDefinition [CoordinationView_V2.0]'),'2;1');`);
  buf.push(`FILE_NAME('${escIfc(projectTitle)}.ifc','${timestamp}',('${escIfc(company)}'),('Zafto Sketch Engine'),'DEPTH43','Zafto','');`);
  buf.push(`FILE_SCHEMA(('IFC2X3'));`);
  buf.push('ENDSEC;');
  buf.push('DATA;');

  // Core IFC structure
  const personId = nextId();
  buf.push(`#${personId}=IFCPERSON($,$,'${escIfc(company)}',$,$,$,$,$);`);

  const orgId = nextId();
  buf.push(`#${orgId}=IFCORGANIZATION($,'${escIfc(company)}',$,$,$);`);

  const personOrgId = nextId();
  buf.push(`#${personOrgId}=IFCPERSONANDORGANIZATION(#${personId},#${orgId},$);`);

  const appId = nextId();
  buf.push(`#${appId}=IFCAPPLICATION(#${orgId},'1.0','Zafto Sketch Engine','ZaftoSE');`);

  const ownerHistoryId = nextId();
  buf.push(`#${ownerHistoryId}=IFCOWNERHISTORY(#${personOrgId},#${appId},$,.NOCHANGE.,$,#${personOrgId},#${appId},${Math.floor(Date.now() / 1000)});`);

  // Geometric context
  const originId = nextId();
  buf.push(`#${originId}=IFCCARTESIANPOINT((0.,0.,0.));`);

  const dirZId = nextId();
  buf.push(`#${dirZId}=IFCDIRECTION((0.,0.,1.));`);

  const dirXId = nextId();
  buf.push(`#${dirXId}=IFCDIRECTION((1.,0.,0.));`);

  const axis2d3dId = nextId();
  buf.push(`#${axis2d3dId}=IFCAXIS2PLACEMENT3D(#${originId},#${dirZId},#${dirXId});`);

  const contextId = nextId();
  buf.push(`#${contextId}=IFCGEOMETRICREPRESENTATIONCONTEXT($,'Model',3,1.0E-05,#${axis2d3dId},$);`);

  const subContextId = nextId();
  buf.push(`#${subContextId}=IFCGEOMETRICREPRESENTATIONSUBCONTEXT('Body','Model',*,*,*,*,#${contextId},$,.MODEL_VIEW.,$);`);

  // Unit assignment (imperial — inches)
  const siLengthId = nextId();
  buf.push(`#${siLengthId}=IFCSIUNIT(*,.LENGTHUNIT.,.MILLI.,.METRE.);`);

  const convFactorId = nextId();
  buf.push(`#${convFactorId}=IFCMEASUREWITHUNIT(IFCLENGTHMEASURE(25.4),#${siLengthId});`);

  const dimExpId = nextId();
  buf.push(`#${dimExpId}=IFCDIMENSIONALEXPONENTS(1,0,0,0,0,0,0);`);

  const inchUnitId = nextId();
  buf.push(`#${inchUnitId}=IFCCONVERSIONBASEDUNIT(#${dimExpId},.LENGTHUNIT.,'inch',#${convFactorId});`);

  const siAreaId = nextId();
  buf.push(`#${siAreaId}=IFCSIUNIT(*,.AREAUNIT.,$,.SQUARE_METRE.);`);

  const siAngleId = nextId();
  buf.push(`#${siAngleId}=IFCSIUNIT(*,.PLANEANGLEUNIT.,$,.RADIAN.);`);

  const unitAssignId = nextId();
  buf.push(`#${unitAssignId}=IFCUNITASSIGNMENT((#${inchUnitId},#${siAreaId},#${siAngleId}));`);

  // Project
  const projectId = nextId();
  buf.push(`#${projectId}=IFCPROJECT('${generateGuid()}',#${ownerHistoryId},'${escIfc(projectTitle)}',$,$,$,$,(#${contextId}),#${unitAssignId});`);

  // Site
  const sitePlacementId = nextId();
  buf.push(`#${sitePlacementId}=IFCLOCALPLACEMENT($,#${axis2d3dId});`);

  const siteId = nextId();
  buf.push(`#${siteId}=IFCSITE('${generateGuid()}',#${ownerHistoryId},'Site',$,$,#${sitePlacementId},$,$,.ELEMENT.,$,$,$,$,$);`);

  // Building
  const bldgPlacementId = nextId();
  buf.push(`#${bldgPlacementId}=IFCLOCALPLACEMENT(#${sitePlacementId},#${axis2d3dId});`);

  const bldgId = nextId();
  buf.push(`#${bldgId}=IFCBUILDING('${generateGuid()}',#${ownerHistoryId},'${escIfc(buildingName)}',$,$,#${bldgPlacementId},$,$,.ELEMENT.,$,$,$);`);

  // Building storey
  const storeyPlacementId = nextId();
  buf.push(`#${storeyPlacementId}=IFCLOCALPLACEMENT(#${bldgPlacementId},#${axis2d3dId});`);

  const storeyId = nextId();
  buf.push(`#${storeyId}=IFCBUILDINGSTOREY('${generateGuid()}',#${ownerHistoryId},'${escIfc(floorName)}',$,$,#${storeyPlacementId},$,$,.ELEMENT.,0.);`);

  // Spatial structure
  const relSiteId = nextId();
  buf.push(`#${relSiteId}=IFCRELAGGREGATES('${generateGuid()}',#${ownerHistoryId},$,$,#${projectId},(#${siteId}));`);

  const relBldgId = nextId();
  buf.push(`#${relBldgId}=IFCRELAGGREGATES('${generateGuid()}',#${ownerHistoryId},$,$,#${siteId},(#${bldgId}));`);

  const relStoreyId = nextId();
  buf.push(`#${relStoreyId}=IFCRELAGGREGATES('${generateGuid()}',#${ownerHistoryId},$,$,#${bldgId},(#${storeyId}));`);

  // Collect product IDs for spatial containment
  const productIds: number[] = [];

  // --- WALLS ---
  for (const wall of plan.walls) {
    const wallEntityId = writeIfcWall(buf, wall, ownerHistoryId, storeyPlacementId, subContextId);
    productIds.push(wallEntityId);
  }

  // --- DOORS ---
  for (const door of plan.doors) {
    const parentWall = plan.walls.find((w) => w.id === door.wallId);
    if (!parentWall) continue;
    const pos = positionOnWall(parentWall, door.position);
    const doorEntityId = writeIfcDoor(buf, pos, door.width, 80, ownerHistoryId, storeyPlacementId, subContextId);
    productIds.push(doorEntityId);
  }

  // --- WINDOWS ---
  for (const win of plan.windows) {
    const parentWall = plan.walls.find((w) => w.id === win.wallId);
    if (!parentWall) continue;
    const pos = positionOnWall(parentWall, win.position);
    const winEntityId = writeIfcWindow(buf, pos, win.width, 48, win.sillHeight ?? 36, ownerHistoryId, storeyPlacementId, subContextId);
    productIds.push(winEntityId);
  }

  // --- ROOMS → IfcSpace ---
  for (const room of plan.rooms) {
    const spaceId = writeIfcSpace(buf, room.name, room.center, room.area, ownerHistoryId, storeyPlacementId, subContextId);
    productIds.push(spaceId);
  }

  // Spatial containment — all products in the storey
  if (productIds.length > 0) {
    const containId = nextId();
    const refs = productIds.map((id) => `#${id}`).join(',');
    buf.push(`#${containId}=IFCRELCONTAINEDINSPATIALSTRUCTURE('${generateGuid()}',#${ownerHistoryId},$,$,(${refs}),#${storeyId});`);
  }

  buf.push('ENDSEC;');
  buf.push('END-ISO-10303-21;');

  return buf.join('\n');
}

// --- IFC Entity Writers ---

function writeIfcWall(
  buf: string[], wall: Wall,
  ownerHistoryId: number, parentPlacementId: number, subContextId: number,
): number {
  const len = wallLength(wall);
  if (len < 0.01) return 0;

  // Wall placement
  const originId = nextId();
  buf.push(`#${originId}=IFCCARTESIANPOINT((${wall.start.x.toFixed(4)},${wall.start.y.toFixed(4)},0.));`);

  const angle = Math.atan2(wall.end.y - wall.start.y, wall.end.x - wall.start.x);
  const dirId = nextId();
  buf.push(`#${dirId}=IFCDIRECTION((${Math.cos(angle).toFixed(6)},${Math.sin(angle).toFixed(6)},0.));`);

  const axisId = nextId();
  buf.push(`#${axisId}=IFCAXIS2PLACEMENT3D(#${originId},$,#${dirId});`);

  const placementId = nextId();
  buf.push(`#${placementId}=IFCLOCALPLACEMENT(#${parentPlacementId},#${axisId});`);

  // Extruded profile — rectangular cross section
  const profileOriginId = nextId();
  buf.push(`#${profileOriginId}=IFCCARTESIANPOINT((0.,0.));`);

  const profileAxisId = nextId();
  buf.push(`#${profileAxisId}=IFCAXIS2PLACEMENT2D(#${profileOriginId},$);`);

  const profileId = nextId();
  buf.push(`#${profileId}=IFCRECTANGLEPROFILEDEF(.AREA.,$,#${profileAxisId},${len.toFixed(4)},${wall.thickness.toFixed(4)});`);

  const extDirId = nextId();
  buf.push(`#${extDirId}=IFCDIRECTION((0.,0.,1.));`);

  const solidId = nextId();
  buf.push(`#${solidId}=IFCEXTRUDEDAREASOLID(#${profileId},#${axisId},#${extDirId},${wall.height.toFixed(4)});`);

  const repId = nextId();
  buf.push(`#${repId}=IFCSHAPEREPRESENTATION(#${subContextId},'Body','SweptSolid',(#${solidId}));`);

  const prodRepId = nextId();
  buf.push(`#${prodRepId}=IFCPRODUCTDEFINITIONSHAPE($,$,(#${repId}));`);

  const wallId = nextId();
  buf.push(`#${wallId}=IFCWALLSTANDARDCASE('${generateGuid()}',${ownerHistoryId},'Wall',$,$,#${placementId},#${prodRepId},$);`);

  return wallId;
}

function writeIfcDoor(
  buf: string[], pos: Point, width: number, height: number,
  ownerHistoryId: number, parentPlacementId: number, subContextId: number,
): number {
  const originId = nextId();
  buf.push(`#${originId}=IFCCARTESIANPOINT((${pos.x.toFixed(4)},${pos.y.toFixed(4)},0.));`);

  const axisId = nextId();
  buf.push(`#${axisId}=IFCAXIS2PLACEMENT3D(#${originId},$,$);`);

  const placementId = nextId();
  buf.push(`#${placementId}=IFCLOCALPLACEMENT(#${parentPlacementId},#${axisId});`);

  const doorId = nextId();
  buf.push(`#${doorId}=IFCDOOR('${generateGuid()}',${ownerHistoryId},'Door',$,$,#${placementId},$,$,${height.toFixed(4)},${width.toFixed(4)});`);

  return doorId;
}

function writeIfcWindow(
  buf: string[], pos: Point, width: number, height: number, sillHeight: number,
  ownerHistoryId: number, parentPlacementId: number, subContextId: number,
): number {
  const originId = nextId();
  buf.push(`#${originId}=IFCCARTESIANPOINT((${pos.x.toFixed(4)},${pos.y.toFixed(4)},${sillHeight.toFixed(4)}));`);

  const axisId = nextId();
  buf.push(`#${axisId}=IFCAXIS2PLACEMENT3D(#${originId},$,$);`);

  const placementId = nextId();
  buf.push(`#${placementId}=IFCLOCALPLACEMENT(#${parentPlacementId},#${axisId});`);

  const windowId = nextId();
  buf.push(`#${windowId}=IFCWINDOW('${generateGuid()}',${ownerHistoryId},'Window',$,$,#${placementId},$,$,${height.toFixed(4)},${width.toFixed(4)});`);

  return windowId;
}

function writeIfcSpace(
  buf: string[], name: string, center: Point, area: number,
  ownerHistoryId: number, parentPlacementId: number, subContextId: number,
): number {
  const originId = nextId();
  buf.push(`#${originId}=IFCCARTESIANPOINT((${center.x.toFixed(4)},${center.y.toFixed(4)},0.));`);

  const axisId = nextId();
  buf.push(`#${axisId}=IFCAXIS2PLACEMENT3D(#${originId},$,$);`);

  const placementId = nextId();
  buf.push(`#${placementId}=IFCLOCALPLACEMENT(#${parentPlacementId},#${axisId});`);

  const spaceId = nextId();
  buf.push(`#${spaceId}=IFCSPACE('${generateGuid()}',${ownerHistoryId},'${escIfc(name)}',$,$,#${placementId},$,$,.ELEMENT.,.INTERNAL.,$);`);

  return spaceId;
}

// --- Helpers ---

function escIfc(s: string): string {
  return s.replace(/'/g, "''").replace(/\\/g, '\\\\');
}

/**
 * Generate a pseudo-GUID for IFC (22-char base64-encoded).
 * IFC uses a compressed GUID format (22 chars, base64-like).
 */
function generateGuid(): string {
  const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_$';
  let guid = '';
  for (let i = 0; i < 22; i++) {
    guid += chars[Math.floor(Math.random() * 64)];
  }
  return guid;
}
