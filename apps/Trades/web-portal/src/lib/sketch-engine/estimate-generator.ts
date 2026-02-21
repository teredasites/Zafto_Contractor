// ZAFTO Estimate Generator — SK8 (TypeScript Port)
// Creates estimates from room measurements + trade layer data.
// Generates estimate_areas and suggests line items.

import { getSupabase } from '@/lib/supabase';
import type {
  FloorPlanData,
  TradeLayer,
  SitePlanData,
  SprinklerZone,
} from './types';
import type { RoomMeasurements } from './measurement-calculator';

// =============================================================================
// TYPES
// =============================================================================

export interface SuggestedLineItem {
  description: string;
  actionType: string;
  quantity: number;
  unitCode: string;
  trade: string;
  zaftoCode: string | null;
  materialCost: number;
  laborCost: number;
  equipmentCost: number;
  unitPrice: number;
  lineTotal: number;
}

export interface GeneratedArea {
  areaId: string;
  roomId: string;
  roomName: string;
  measurements: RoomMeasurements;
  lineItems: SuggestedLineItem[];
}

export interface GenerateEstimateResult {
  estimateId: string;
  areas: GeneratedArea[];
  totalAmount: number;
}

// =============================================================================
// GENERATOR
// =============================================================================

export async function generateEstimate(input: {
  floorPlanId: string;
  measurements: RoomMeasurements[];
  planData: FloorPlanData;
  sitePlanData?: SitePlanData;
  selectedTrade?: string;
  title?: string;
  jobId?: string;
  customerId?: string;
  propertyAddress?: string;
}): Promise<GenerateEstimateResult | null> {
  const supabase = getSupabase();

  // Get user context
  const { data: { user } } = await supabase.auth.getUser();
  const companyId = user?.app_metadata?.company_id;
  if (!companyId || !user) return null;

  if (input.measurements.length === 0) return null;

  // 1. Create estimate
  const { data: estimateData, error: estimateError } = await supabase
    .from('estimates')
    .insert({
      company_id: companyId,
      created_by: user.id,
      title: input.title || 'Floor Plan Estimate',
      estimate_type: 'regular',
      status: 'draft',
      job_id: input.jobId || null,
      customer_id: input.customerId || null,
      property_address: input.propertyAddress || null,
      property_floor_plan_id: input.floorPlanId,
    })
    .select('id')
    .single();

  if (estimateError || !estimateData) return null;
  const estimateId = estimateData.id as string;

  // 2. Generate areas and line items
  const areas: GeneratedArea[] = [];
  let totalAmount = 0;

  for (let i = 0; i < input.measurements.length; i++) {
    const m = input.measurements[i];

    // Create estimate_area
    const { data: areaData, error: areaError } = await supabase
      .from('estimate_areas')
      .insert({
        estimate_id: estimateId,
        name: m.roomName,
        floor_number: 1,
        area_sf: m.floorSf,
        wall_sf: m.wallSf,
        ceiling_sf: m.ceilingSf,
        baseboard_lf: m.baseboardLf,
        perimeter_ft: m.perimeterLf,
        height_ft: m.wallHeight / 12,
        window_count: m.windowCount,
        door_count: m.doorCount,
        sort_order: i,
      })
      .select('id')
      .single();

    if (areaError || !areaData) continue;
    const areaId = areaData.id as string;

    // Create bridge link
    await supabase.from('floor_plan_estimate_links').insert({
      floor_plan_id: input.floorPlanId,
      room_id: m.roomId,
      estimate_id: estimateId,
      estimate_area_id: areaId,
      auto_generated: true,
      company_id: companyId,
    });

    // Generate line items
    const lineItems = suggestLineItems(m, input.planData, input.selectedTrade, input.sitePlanData);

    // Save line items
    if (lineItems.length > 0) {
      const rows = lineItems.map((item, idx) => ({
        estimate_id: estimateId,
        area_id: areaId,
        description: item.description,
        action_type: item.actionType,
        quantity: item.quantity,
        unit_code: item.unitCode,
        material_cost: item.materialCost,
        labor_cost: item.laborCost,
        equipment_cost: item.equipmentCost,
        unit_price: item.unitPrice,
        line_total: item.lineTotal,
        sort_order: idx,
        ...(item.zaftoCode ? { zafto_code: item.zaftoCode } : {}),
      }));

      await supabase.from('estimate_line_items').insert(rows);
    }

    const areaTotal = lineItems.reduce((sum, li) => sum + li.lineTotal, 0);
    totalAmount += areaTotal;

    areas.push({
      areaId,
      roomId: m.roomId,
      roomName: m.roomName,
      measurements: m,
      lineItems,
    });
  }

  return { estimateId, areas, totalAmount };
}

// =============================================================================
// LINE ITEM SUGGESTION
// =============================================================================

function suggestLineItems(
  m: RoomMeasurements,
  planData: FloorPlanData,
  selectedTrade?: string,
  sitePlanData?: SitePlanData,
): SuggestedLineItem[] {
  const items: SuggestedLineItem[] = [];

  // Universal items
  if (m.wallSf > 0) {
    items.push(makeItem('Paint walls', m.paintSfWallsOnly, 'SF', 'painting', 'PAINT-WALL', 0.35, 0.85));
  }
  if (m.ceilingSf > 0) {
    items.push(makeItem('Paint ceiling', m.paintSfCeilingOnly, 'SF', 'painting', 'PAINT-CEIL', 0.30, 0.90));
  }
  if (m.baseboardLf > 0) {
    items.push(makeItem('Baseboard', m.baseboardLf, 'LF', 'carpentry', 'TRIM-BASE', 2.50, 3.00));
  }
  if (m.floorSf > 0) {
    items.push(makeItem('Flooring', m.floorSf, 'SF', 'flooring', 'FLOOR-STD', 3.00, 2.50));
  }

  // Trade layer elements
  const room = planData.rooms.find((r) => r.id === m.roomId);
  if (room) {
    for (const layer of planData.tradeLayers) {
      if (selectedTrade && layer.type !== selectedTrade) continue;
      if (!layer.tradeData) continue;

      // Count elements by type in room bounds
      const counts = new Map<string, number>();
      for (const el of layer.tradeData.elements) {
        if (isPointInRoom(el.position, room, planData)) {
          const key = el.type;
          counts.set(key, (counts.get(key) || 0) + 1);
        }
      }

      for (const [symbolType, count] of counts) {
        items.push(
          makeItem(
            `${humanize(symbolType)} rough-in`,
            count,
            'EA',
            layer.type,
            null,
            15,
            45,
          ),
        );
      }
    }

    // Damage layer
    for (const layer of planData.tradeLayers) {
      if (layer.type !== 'damage' || !layer.damageData) continue;

      for (const zone of layer.damageData.zones) {
        const dc = zone.damageClass || '1';
        items.push(makeItem(`Demo drywall (Class ${dc})`, m.wallSf, 'SF', 'restoration', null, 0, 1.25));
        items.push(makeItem(`Structural drying (Class ${dc})`, m.floorSf, 'SF', 'restoration', null, 0, 1.50, 2.50));

        if (dc === '2' || dc === '3') {
          items.push(makeItem(`Replace drywall (Class ${dc})`, m.wallSf, 'SF', 'restoration', null, 2.00, 3.50));
        }
      }
    }

    // Fire protection layer
    for (const layer of planData.tradeLayers) {
      if (layer.type !== 'fire' || !layer.fireData) continue;

      const fd = layer.fireData;
      if (fd.sprinklerZones.length > 0) {
        const totalHeads = fd.sprinklerZones.reduce(
          (sum: number, z: SprinklerZone) => sum + (z.headsPerZone ?? 0),
          0,
        );
        if (totalHeads > 0) {
          items.push(makeItem('Sprinkler head install', totalHeads, 'EA', 'fire', 'FIRE-HEAD', 35, 65));
        }
        items.push(makeItem('Sprinkler zone piping', fd.sprinklerZones.length, 'EA', 'fire', 'FIRE-ZONE', 800, 1200));
      }
      if (fd.standpipeLocations.length > 0) {
        items.push(makeItem('Standpipe riser', fd.standpipeLocations.length, 'EA', 'fire', 'FIRE-STPIPE', 2500, 3500, 500));
      }
      if (fd.fireDeptConnections.length > 0) {
        items.push(makeItem('Fire dept connection (FDC)', fd.fireDeptConnections.length, 'EA', 'fire', 'FIRE-FDC', 1200, 1800));
      }
      if (fd.pullStations.length > 0) {
        items.push(makeItem('Pull station install', fd.pullStations.length, 'EA', 'fire', 'FIRE-PULL', 85, 120));
      }
      if (fd.detectors.length > 0) {
        items.push(makeItem('Fire/smoke detector', fd.detectors.length, 'EA', 'fire', 'FIRE-DET', 45, 75));
      }
      if (fd.notificationDevices.length > 0) {
        items.push(makeItem('Horn/strobe device', fd.notificationDevices.length, 'EA', 'fire', 'FIRE-NOTIFY', 95, 85));
      }
      if (fd.extinguishers.length > 0) {
        items.push(makeItem('Fire extinguisher mount', fd.extinguishers.length, 'EA', 'fire', 'FIRE-EXT', 60, 25));
      }
      if (fd.fireRatedAssemblies.length > 0) {
        items.push(makeItem('Fire-rated assembly', fd.fireRatedAssemblies.length, 'EA', 'fire', 'FIRE-RATED', 0, 150));
      }
    }
  }

  // Commercial building-specific items (site-level)
  if (sitePlanData) {
    addCommercialSiteItems(items, sitePlanData);
  }

  return items;
}

// =============================================================================
// HELPERS
// =============================================================================

function makeItem(
  description: string,
  quantity: number,
  unitCode: string,
  trade: string,
  zaftoCode: string | null,
  materialCost: number,
  laborCost: number,
  equipmentCost = 0,
): SuggestedLineItem {
  const unitPrice = materialCost + laborCost + equipmentCost;
  return {
    description,
    actionType: 'add',
    quantity: Math.round(quantity * 100) / 100,
    unitCode,
    trade,
    zaftoCode,
    materialCost,
    laborCost,
    equipmentCost,
    unitPrice,
    lineTotal: Math.round(quantity * unitPrice * 100) / 100,
  };
}

function isPointInRoom(
  point: { x: number; y: number },
  room: { wallIds: string[] },
  planData: FloorPlanData,
): boolean {
  let minX = Infinity, minY = Infinity;
  let maxX = -Infinity, maxY = -Infinity;

  for (const wallId of room.wallIds) {
    const wall = planData.walls.find((w) => w.id === wallId);
    if (!wall) continue;
    minX = Math.min(minX, wall.start.x, wall.end.x);
    minY = Math.min(minY, wall.start.y, wall.end.y);
    maxX = Math.max(maxX, wall.start.x, wall.end.x);
    maxY = Math.max(maxY, wall.start.y, wall.end.y);
  }

  return point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY;
}

function humanize(s: string): string {
  return s
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function polygonArea(points: { x: number; y: number }[]): number {
  if (points.length < 3) return 0;
  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }
  return Math.abs(area) / 2;
}

// =============================================================================
// COMMERCIAL SITE-LEVEL ITEMS
// =============================================================================

function addCommercialSiteItems(
  items: SuggestedLineItem[],
  sitePlan: SitePlanData,
): void {
  // Parking lot line items
  if (sitePlan.parkingLayouts && sitePlan.parkingLayouts.length > 0) {
    for (const lot of sitePlan.parkingLayouts) {
      items.push(makeItem('Parking stall striping', lot.stallCount * 18, 'LF', 'paving', 'PARK-STRIPE', 0.45, 0.55));
      if (lot.handicapStalls > 0) {
        items.push(makeItem('ADA parking signage & marking', lot.handicapStalls, 'EA', 'paving', 'PARK-ADA', 250, 150));
      }
    }
  }

  // Compliance markers
  if (sitePlan.complianceMarkers && sitePlan.complianceMarkers.length > 0) {
    const markerCounts = new Map<string, number>();
    for (const marker of sitePlan.complianceMarkers) {
      markerCounts.set(marker.type, (markerCounts.get(marker.type) || 0) + 1);
    }

    for (const [markerType, count] of markerCounts) {
      const label = humanize(markerType);
      if (markerType.startsWith('ada')) {
        items.push(makeItem(`${label} compliance`, count, 'EA', 'general', null, 0, 85));
      } else if (markerType.startsWith('fire')) {
        items.push(makeItem(`${label} rating`, count, 'EA', 'fire', null, 0, 120));
      } else if (markerType === 'exitSign' || markerType === 'emergencyLight') {
        items.push(makeItem(label, count, 'EA', 'electrical', null, 45, 65));
      } else {
        items.push(makeItem(`${label} marker`, count, 'EA', 'general', null, 0, 50));
      }
    }
  }

  // Roof drains (commercial flat roof)
  if (sitePlan.roofDrains && sitePlan.roofDrains.length > 0) {
    const internal = sitePlan.roofDrains.filter((d) => d.drainType === 'internal').length;
    const scuppers = sitePlan.roofDrains.filter((d) => d.drainType === 'scupper').length;
    const overflow = sitePlan.roofDrains.filter((d) => d.drainType === 'overflow').length;

    if (internal > 0) {
      items.push(makeItem('Internal roof drain', internal, 'EA', 'plumbing', 'ROOF-DRAIN-INT', 350, 450));
    }
    if (scuppers > 0) {
      items.push(makeItem('Scupper drain', scuppers, 'EA', 'plumbing', 'ROOF-DRAIN-SCUP', 200, 300));
    }
    if (overflow > 0) {
      items.push(makeItem('Overflow drain', overflow, 'EA', 'plumbing', 'ROOF-DRAIN-OVER', 275, 350));
    }
  }

  // Commercial roof planes (flat roof materials)
  if (sitePlan.roofPlanes) {
    for (const plane of sitePlan.roofPlanes) {
      if (plane.membraneMaterial) {
        const matLabel = humanize(plane.membraneMaterial);
        const costPerSf = COMMERCIAL_ROOF_COSTS[plane.membraneMaterial] ?? 8.5;
        const areaSf = polygonArea(plane.points);
        if (areaSf > 0) {
          items.push(makeItem(`${matLabel} membrane`, areaSf, 'SF', 'roofing', 'CROOF-MEM', costPerSf * 0.55, costPerSf * 0.45));
        }
        if (plane.insulationRValue && plane.insulationRValue > 0 && areaSf > 0) {
          items.push(makeItem(`Roof insulation R-${plane.insulationRValue}`, areaSf, 'SF', 'roofing', 'CROOF-INS', 1.80, 1.20));
        }
      }
    }
  }
}

// Commercial roof material cost lookup (total installed $/SF)
const COMMERCIAL_ROOF_COSTS: Record<string, number> = {
  tpoWhite45: 7.50,
  tpoWhite60: 8.50,
  tpoWhite80: 10.00,
  epdm45: 6.50,
  epdm60: 7.50,
  epdm90: 9.00,
  modBitBase: 7.00,
  modBitCap: 8.00,
  bur3Ply: 8.50,
  bur4Ply: 10.00,
  pvcMembrane: 9.50,
  sprayFoam: 7.00,
  standingSeam: 14.00,
  metalRPanel: 8.50,
  greenRoofExtensive: 25.00,
  greenRoofIntensive: 45.00,
  hotMopAsphalt: 6.50,
  coldAppliedAdhesive: 7.00,
  liquidAppliedCoating: 5.50,
  torchDown: 7.50,
  tpoFleeceback: 9.50,
  singlePlyBallast: 6.00,
};
