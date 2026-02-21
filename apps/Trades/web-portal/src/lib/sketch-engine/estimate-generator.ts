// ZAFTO Estimate Generator — SK8 (TypeScript Port)
// Creates estimates from room measurements + trade layer data.
// ALL pricing sourced from estimate_pricing table (BLS-backed) + regional adjustments + company overrides.
// ZERO hardcoded prices — database or user price book only. (Rule #24)

import { getSupabase } from '@/lib/supabase';
import type {
  FloorPlanData,
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
  /** Where the pricing came from: 'database' (BLS/regional), 'company' (user price book), 'unpriced' (no DB entry — user must set) */
  pricingSource: 'database' | 'company' | 'unpriced';
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
  regionCode: string;
  unpricedCount: number;
}

// =============================================================================
// PRICING INFRASTRUCTURE
// =============================================================================

interface PricingEntry {
  laborRate: number;
  materialCost: number;
  equipmentCost: number;
  isCompanyOverride: boolean;
}

type PricingMap = Map<string, PricingEntry>;

/**
 * Maps sketch engine line item descriptions to real Z-codes in estimate_items.
 * This is the bridge between the sketch engine's conceptual items and the
 * BLS-backed pricing database.
 */
const SKETCH_ITEM_CODES: Record<string, string> = {
  // Painting
  'Paint walls': 'Z-PNT-001',
  'Paint ceiling': 'Z-PNT-002',
  // Trim (install, not paint)
  'Baseboard': 'Z-TMB-001',
  // Flooring — defaults to LVP, user overrides via price book
  'Flooring': 'Z-FCV-001',
  // Demolition / Restoration
  'Demo drywall': 'Z-DMO-001',
  'Structural drying': 'Z-WTR-002',
  'Replace drywall': 'Z-DRY-001',
  // Roof drains
  'Internal roof drain': 'Z-PLM-014',
  'Scupper drain': 'Z-PLM-014',
  'Overflow drain': 'Z-PLM-014',
};

/**
 * Loads ALL pricing from the database for the given property region.
 * Cascade: company override > regional (MSA) > national average.
 */
async function loadPricingMap(
  companyId: string,
  propertyZip?: string,
): Promise<{ map: PricingMap; regionCode: string }> {
  const supabase = getSupabase();

  // 1. Resolve region from property ZIP
  let regionCode = 'NATIONAL';
  if (propertyZip && propertyZip.length >= 3) {
    const { data: msaResult } = await supabase.rpc('fn_zip_to_msa', { zip: propertyZip });
    if (msaResult && msaResult.length > 0) {
      regionCode = String(msaResult[0].cbsa_code);
    }
  }

  // 2. Load all estimate items (zafto_code → item_id mapping)
  const { data: items } = await supabase
    .from('estimate_items')
    .select('id, zafto_code')
    .eq('source', 'zafto');

  if (!items?.length) return { map: new Map(), regionCode };

  const idToCode = new Map<string, string>();
  for (const item of items) {
    idToCode.set(item.id as string, item.zafto_code as string);
  }

  // 3. Load public pricing (national + regional) — company_id IS NULL
  const regionCodes = regionCode !== 'NATIONAL' ? [regionCode, 'NATIONAL'] : ['NATIONAL'];
  const { data: publicPricing } = await supabase
    .from('estimate_pricing')
    .select('item_id, labor_rate, material_cost, equipment_cost, region_code')
    .in('region_code', regionCodes)
    .is('company_id', null);

  // 4. Load company-specific pricing overrides
  const { data: companyPricing } = await supabase
    .from('estimate_pricing')
    .select('item_id, labor_rate, material_cost, equipment_cost')
    .eq('company_id', companyId);

  // 5. Build map: national → regional → company override (each overrides previous)
  const map: PricingMap = new Map();

  // Fill national first
  for (const p of publicPricing || []) {
    if ((p.region_code as string) !== 'NATIONAL') continue;
    const code = idToCode.get(p.item_id as string);
    if (code) {
      map.set(code, {
        laborRate: Number(p.labor_rate || 0),
        materialCost: Number(p.material_cost || 0),
        equipmentCost: Number(p.equipment_cost || 0),
        isCompanyOverride: false,
      });
    }
  }

  // Override with regional (more specific)
  if (regionCode !== 'NATIONAL') {
    for (const p of publicPricing || []) {
      if ((p.region_code as string) === 'NATIONAL') continue;
      const code = idToCode.get(p.item_id as string);
      if (code) {
        map.set(code, {
          laborRate: Number(p.labor_rate || 0),
          materialCost: Number(p.material_cost || 0),
          equipmentCost: Number(p.equipment_cost || 0),
          isCompanyOverride: false,
        });
      }
    }
  }

  // Override with company-specific pricing (highest priority)
  for (const p of companyPricing || []) {
    const code = idToCode.get(p.item_id as string);
    if (code) {
      map.set(code, {
        laborRate: Number(p.labor_rate || 0),
        materialCost: Number(p.material_cost || 0),
        equipmentCost: Number(p.equipment_cost || 0),
        isCompanyOverride: true,
      });
    }
  }

  return { map, regionCode };
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
  propertyZip?: string;
}): Promise<GenerateEstimateResult | null> {
  const supabase = getSupabase();

  // Get user context
  const { data: { user } } = await supabase.auth.getUser();
  const companyId = user?.app_metadata?.company_id;
  if (!companyId || !user) return null;

  if (input.measurements.length === 0) return null;

  // Load pricing from database (regional + company overrides)
  const { map: pricingMap, regionCode } = await loadPricingMap(companyId, input.propertyZip);

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
  let unpricedCount = 0;

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

    // Generate line items using DB-backed pricing
    const lineItems = suggestLineItems(m, input.planData, pricingMap, input.selectedTrade, input.sitePlanData);

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
    unpricedCount += lineItems.filter((li) => li.pricingSource === 'unpriced').length;

    areas.push({
      areaId,
      roomId: m.roomId,
      roomName: m.roomName,
      measurements: m,
      lineItems,
    });
  }

  return { estimateId, areas, totalAmount, regionCode, unpricedCount };
}

// =============================================================================
// LINE ITEM SUGGESTION (all pricing from database)
// =============================================================================

function suggestLineItems(
  m: RoomMeasurements,
  planData: FloorPlanData,
  pricing: PricingMap,
  selectedTrade?: string,
  sitePlanData?: SitePlanData,
): SuggestedLineItem[] {
  const items: SuggestedLineItem[] = [];

  // Universal room items
  if (m.wallSf > 0) {
    items.push(makePricedItem('Paint walls', m.paintSfWallsOnly, 'SF', 'painting', pricing));
  }
  if (m.ceilingSf > 0) {
    items.push(makePricedItem('Paint ceiling', m.paintSfCeilingOnly, 'SF', 'painting', pricing));
  }
  if (m.baseboardLf > 0) {
    items.push(makePricedItem('Baseboard', m.baseboardLf, 'LF', 'carpentry', pricing));
  }
  if (m.floorSf > 0) {
    items.push(makePricedItem('Flooring', m.floorSf, 'SF', 'flooring', pricing));
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
        const desc = `${humanize(symbolType)} rough-in`;
        items.push(makePricedItem(desc, count, 'EA', layer.type, pricing));
      }
    }

    // Damage layer
    for (const layer of planData.tradeLayers) {
      if (layer.type !== 'damage' || !layer.damageData) continue;

      for (const zone of layer.damageData.zones) {
        const dc = zone.damageClass || '1';
        items.push(makePricedItem('Demo drywall', m.wallSf, 'SF', 'restoration', pricing, `Demo drywall (Class ${dc})`));
        items.push(makePricedItem('Structural drying', m.floorSf, 'SF', 'restoration', pricing, `Structural drying (Class ${dc})`));

        if (dc === '2' || dc === '3') {
          items.push(makePricedItem('Replace drywall', m.wallSf, 'SF', 'restoration', pricing, `Replace drywall (Class ${dc})`));
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
          items.push(makePricedItem('Sprinkler head install', totalHeads, 'EA', 'fire', pricing));
        }
        items.push(makePricedItem('Sprinkler zone piping', fd.sprinklerZones.length, 'EA', 'fire', pricing));
      }
      if (fd.standpipeLocations.length > 0) {
        items.push(makePricedItem('Standpipe riser', fd.standpipeLocations.length, 'EA', 'fire', pricing));
      }
      if (fd.fireDeptConnections.length > 0) {
        items.push(makePricedItem('Fire dept connection (FDC)', fd.fireDeptConnections.length, 'EA', 'fire', pricing));
      }
      if (fd.pullStations.length > 0) {
        items.push(makePricedItem('Pull station install', fd.pullStations.length, 'EA', 'fire', pricing));
      }
      if (fd.detectors.length > 0) {
        items.push(makePricedItem('Fire/smoke detector', fd.detectors.length, 'EA', 'fire', pricing));
      }
      if (fd.notificationDevices.length > 0) {
        items.push(makePricedItem('Horn/strobe device', fd.notificationDevices.length, 'EA', 'fire', pricing));
      }
      if (fd.extinguishers.length > 0) {
        items.push(makePricedItem('Fire extinguisher mount', fd.extinguishers.length, 'EA', 'fire', pricing));
      }
      if (fd.fireRatedAssemblies.length > 0) {
        items.push(makePricedItem('Fire-rated assembly', fd.fireRatedAssemblies.length, 'EA', 'fire', pricing));
      }
    }
  }

  // Commercial building-specific items (site-level)
  if (sitePlanData) {
    addCommercialSiteItems(items, sitePlanData, pricing);
  }

  return items;
}

// =============================================================================
// HELPERS
// =============================================================================

/**
 * Creates a line item with pricing from the database.
 * Looks up the description in SKETCH_ITEM_CODES to find the Z-code,
 * then pulls pricing from the pre-loaded map.
 * Items not in the database are marked as 'unpriced' ($0).
 */
function makePricedItem(
  lookupKey: string,
  quantity: number,
  unitCode: string,
  trade: string,
  pricing: PricingMap,
  displayDescription?: string,
): SuggestedLineItem {
  const zaftoCode = SKETCH_ITEM_CODES[lookupKey] ?? null;
  const entry = zaftoCode ? pricing.get(zaftoCode) : undefined;

  const materialCost = entry?.materialCost ?? 0;
  const laborCost = entry?.laborRate ?? 0;
  const equipmentCost = entry?.equipmentCost ?? 0;
  const unitPrice = materialCost + laborCost + equipmentCost;

  let pricingSource: SuggestedLineItem['pricingSource'] = 'unpriced';
  if (entry) {
    pricingSource = entry.isCompanyOverride ? 'company' : 'database';
  }

  return {
    description: displayDescription ?? lookupKey,
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
    pricingSource,
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
// COMMERCIAL SITE-LEVEL ITEMS (all pricing from database)
// =============================================================================

function addCommercialSiteItems(
  items: SuggestedLineItem[],
  sitePlan: SitePlanData,
  pricing: PricingMap,
): void {
  // Parking lot line items
  if (sitePlan.parkingLayouts && sitePlan.parkingLayouts.length > 0) {
    for (const lot of sitePlan.parkingLayouts) {
      items.push(makePricedItem('Parking stall striping', lot.stallCount * 18, 'LF', 'paving', pricing));
      if (lot.handicapStalls > 0) {
        items.push(makePricedItem('ADA parking signage & marking', lot.handicapStalls, 'EA', 'paving', pricing));
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
        items.push(makePricedItem(`${label} compliance`, count, 'EA', 'general', pricing));
      } else if (markerType.startsWith('fire')) {
        items.push(makePricedItem(`${label} rating`, count, 'EA', 'fire', pricing));
      } else if (markerType === 'exitSign' || markerType === 'emergencyLight') {
        items.push(makePricedItem(label, count, 'EA', 'electrical', pricing));
      } else {
        items.push(makePricedItem(`${label} marker`, count, 'EA', 'general', pricing));
      }
    }
  }

  // Roof drains (commercial flat roof)
  if (sitePlan.roofDrains && sitePlan.roofDrains.length > 0) {
    const internal = sitePlan.roofDrains.filter((d) => d.drainType === 'internal').length;
    const scuppers = sitePlan.roofDrains.filter((d) => d.drainType === 'scupper').length;
    const overflow = sitePlan.roofDrains.filter((d) => d.drainType === 'overflow').length;

    if (internal > 0) {
      items.push(makePricedItem('Internal roof drain', internal, 'EA', 'plumbing', pricing));
    }
    if (scuppers > 0) {
      items.push(makePricedItem('Scupper drain', scuppers, 'EA', 'plumbing', pricing));
    }
    if (overflow > 0) {
      items.push(makePricedItem('Overflow drain', overflow, 'EA', 'plumbing', pricing));
    }
  }

  // Commercial roof planes (flat roof materials)
  if (sitePlan.roofPlanes) {
    for (const plane of sitePlan.roofPlanes) {
      if (plane.membraneMaterial) {
        const matLabel = humanize(plane.membraneMaterial);
        const areaSf = polygonArea(plane.points);
        if (areaSf > 0) {
          items.push(makePricedItem(`${matLabel} membrane`, areaSf, 'SF', 'roofing', pricing));
        }
        if (plane.insulationRValue && plane.insulationRValue > 0 && areaSf > 0) {
          items.push(makePricedItem(`Roof insulation R-${plane.insulationRValue}`, areaSf, 'SF', 'roofing', pricing));
        }
      }
    }
  }
}
