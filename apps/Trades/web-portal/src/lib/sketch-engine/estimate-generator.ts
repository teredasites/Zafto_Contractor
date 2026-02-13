// ZAFTO Estimate Generator — SK8 (TypeScript Port)
// Creates estimates from room measurements + trade layer data.
// Generates estimate_areas and suggests line items.

import { getSupabase } from '@/lib/supabase';
import type { FloorPlanData, TradeLayer } from './types';
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
    const lineItems = suggestLineItems(m, input.planData, input.selectedTrade);

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
