'use client';

// ZAFTO — Property Blueprint Lookup Hook (DEPTH26)
// Bridges recon-property-lookup EF → Sketch Engine SitePlanData.
// Address → geocode → footprint → parcel → satellite → roof → trees → flood → utilities
// Converts all data into canvas-ready SitePlanData format.

import { useState, useCallback, useRef } from 'react';
import { createClient } from '@/lib/supabase';
import type {
  SitePlanData,
  StructureOutline,
  RoofPlane,
  SitePlanLayer,
  Point,
} from '@/lib/sketch-engine/types';
import { createEmptySitePlan } from '@/lib/sketch-engine/types';

// ============================================================================
// TYPES
// ============================================================================

export interface PropertyLookupResult {
  scanId: string;
  address: string;
  latitude: number;
  longitude: number;
  sitePlan: SitePlanData;
  propertyInfo: PropertyInfo;
  floodZone: FloodZoneData | null;
  dataSources: string[];
  confidenceScore: number;
  isCommercial: boolean;
}

export interface PropertyInfo {
  yearBuilt: number | null;
  stories: number | null;
  livingSqft: number | null;
  lotSqft: number | null;
  beds: number | null;
  bathsFull: number | null;
  bathsHalf: number | null;
  constructionType: string | null;
  roofType: string | null;
  heatingType: string | null;
  coolingType: string | null;
  propertyType: string | null;
  assessedValue: number | null;
  lastSalePrice: number | null;
  lastSaleDate: string | null;
}

export interface FloodZoneData {
  zone: string; // 'A', 'AE', 'X', 'X500', etc.
  riskLevel: 'high' | 'moderate' | 'minimal' | 'unknown';
  panelNumber: string | null;
  effectiveDate: string | null;
  inFloodplain: boolean;
}

export type LookupStage =
  | 'idle'
  | 'geocoding'
  | 'fetching_footprint'
  | 'fetching_property_data'
  | 'fetching_roof'
  | 'fetching_satellite'
  | 'fetching_flood'
  | 'building_sketch'
  | 'complete'
  | 'error';

// ============================================================================
// GEO UTILITIES
// ============================================================================

const FEET_PER_DEGREE_LAT = 364_000; // ~1 degree lat = 364,000 ft
const SCALE_PX_PER_FT = 4; // matches default site plan scale

/** Convert lat/lng offset to canvas x/y pixels relative to center */
function geoToCanvas(
  lat: number,
  lng: number,
  centerLat: number,
  centerLng: number,
  canvasCenterX: number,
  canvasCenterY: number
): Point {
  const feetPerDegreeLng = FEET_PER_DEGREE_LAT * Math.cos((centerLat * Math.PI) / 180);
  const dx = (lng - centerLng) * feetPerDegreeLng * SCALE_PX_PER_FT;
  const dy = -(lat - centerLat) * FEET_PER_DEGREE_LAT * SCALE_PX_PER_FT; // flip Y
  return { x: canvasCenterX + dx, y: canvasCenterY + dy };
}

/** Convert GeoJSON polygon coordinates to canvas points */
function geojsonToCanvasPoints(
  geojson: GeoJSON.Geometry | null,
  centerLat: number,
  centerLng: number,
  canvasCenterX: number,
  canvasCenterY: number
): Point[] {
  if (!geojson) return [];

  let coords: number[][] = [];
  if (geojson.type === 'Polygon' && geojson.coordinates?.[0]) {
    coords = geojson.coordinates[0] as number[][];
  } else if (geojson.type === 'MultiPolygon' && geojson.coordinates?.[0]?.[0]) {
    coords = geojson.coordinates[0][0] as number[][];
  }

  return coords.map(([lng, lat]) =>
    geoToCanvas(lat, lng, centerLat, centerLng, canvasCenterX, canvasCenterY)
  );
}

/** Calculate polygon area from points using shoelace formula */
function polygonAreaSqFt(points: Point[]): number {
  if (points.length < 3) return 0;
  let area = 0;
  for (let i = 0; i < points.length; i++) {
    const j = (i + 1) % points.length;
    area += points[i].x * points[j].y;
    area -= points[j].x * points[i].y;
  }
  return Math.abs(area / 2) / (SCALE_PX_PER_FT * SCALE_PX_PER_FT);
}

/** Generate Mapbox Static API satellite tile URL */
function getSatelliteUrl(lat: number, lng: number, zoom = 18, width = 1280, height = 1280): string {
  const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN;
  if (!token) return '';
  return `https://api.mapbox.com/styles/v1/mapbox/satellite-v9/static/${lng},${lat},${zoom},0/${width}x${height}@2x?access_token=${token}`;
}

/** Map FEMA flood zone code to risk level */
function floodZoneRisk(zone: string): FloodZoneData['riskLevel'] {
  if (!zone) return 'unknown';
  const upper = zone.toUpperCase();
  // Zone A, AE, AH, AO, AR, V, VE = high risk (1% annual chance)
  if (/^(A[EHO0-9R]?|V[E]?)$/.test(upper)) return 'high';
  // Zone B, X (shaded/500) = moderate (0.2% annual chance)
  if (upper === 'B' || upper === 'X500' || upper === 'X_SHADED') return 'moderate';
  // Zone C, X (unshaded) = minimal
  if (upper === 'C' || upper === 'X') return 'minimal';
  return 'unknown';
}

// ============================================================================
// HOOK: usePropertyLookup
// ============================================================================

export function usePropertyLookup() {
  const [result, setResult] = useState<PropertyLookupResult | null>(null);
  const [stage, setStage] = useState<LookupStage>('idle');
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const abortRef = useRef<AbortController | null>(null);

  const CANVAS_CENTER = 2000; // canvas center in pixels

  /**
   * Main lookup: address → full site plan data.
   * Calls the existing recon-property-lookup EF, then fetches all
   * related tables and converts to SitePlanData.
   */
  const lookupAddress = useCallback(async (address: string, jobId?: string): Promise<PropertyLookupResult | null> => {
    if (!address.trim()) {
      setError('Please enter an address');
      return null;
    }

    // Cancel any in-flight request
    abortRef.current?.abort();
    const controller = new AbortController();
    abortRef.current = controller;

    setError(null);
    setProgress(0);
    setStage('geocoding');

    try {
      const supabase = createClient();
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      // ====================================================================
      // STEP 1: Trigger recon scan (geocode + footprint + solar + property data)
      // ====================================================================
      setProgress(10);
      setStage('geocoding');

      const scanRes = await fetch(
        `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/recon-property-lookup`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({ address, job_id: jobId }),
          signal: controller.signal,
        }
      );

      const scanData = await scanRes.json();
      if (!scanRes.ok) throw new Error(scanData.error || 'Property lookup failed');

      const scanId = scanData.scan_id as string;
      if (!scanId) throw new Error('No scan ID returned');

      if (controller.signal.aborted) return null;

      // ====================================================================
      // STEP 2: Fetch all scan data from DB
      // ====================================================================
      setProgress(40);
      setStage('fetching_footprint');

      // Parallel fetch: scan + structures + parcel + features + roof + facets
      const [scanRow, structRows, parcelRows, featureRow, roofRow] = await Promise.all([
        supabase.from('property_scans').select('*').eq('id', scanId).is('deleted_at', null).single(),
        supabase.from('property_structures').select('*').eq('property_scan_id', scanId),
        supabase.from('parcel_boundaries').select('*').eq('scan_id', scanId),
        supabase.from('property_features').select('*').eq('scan_id', scanId).maybeSingle(),
        supabase.from('roof_measurements').select('*').eq('scan_id', scanId).maybeSingle(),
      ]);

      if (controller.signal.aborted) return null;

      const scan = scanRow.data;
      if (!scan) throw new Error('Scan record not found');

      const lat = Number(scan.latitude) || 0;
      const lng = Number(scan.longitude) || 0;

      if (lat === 0 && lng === 0) throw new Error('Geocoding failed — could not locate address');

      setProgress(55);
      setStage('fetching_roof');

      // Get facets if roof measurement exists
      let facetRows: { data: Record<string, unknown>[] | null } = { data: null };
      if (roofRow.data?.id) {
        facetRows = await supabase
          .from('roof_facets')
          .select('*')
          .eq('roof_measurement_id', roofRow.data.id)
          .order('facet_number');
      }

      if (controller.signal.aborted) return null;

      // ====================================================================
      // STEP 3: Fetch FEMA flood zone data (free API)
      // ====================================================================
      setProgress(65);
      setStage('fetching_flood');

      let floodZone: FloodZoneData | null = null;
      try {
        const femaRes = await fetch(
          `https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/28/query?geometry=${lng},${lat}&geometryType=esriGeometryPoint&spatialRel=esriSpatialRelContains&outFields=FLD_ZONE,DFIRM_ID,EFF_DATE&f=json`,
          { signal: controller.signal }
        );
        if (femaRes.ok) {
          const femaData = await femaRes.json();
          const feature = femaData?.features?.[0];
          if (feature?.attributes) {
            const zone = (feature.attributes.FLD_ZONE as string) || '';
            floodZone = {
              zone,
              riskLevel: floodZoneRisk(zone),
              panelNumber: feature.attributes.DFIRM_ID || null,
              effectiveDate: feature.attributes.EFF_DATE || null,
              inFloodplain: floodZoneRisk(zone) !== 'minimal' && floodZoneRisk(zone) !== 'unknown',
            };
          }
        }
      } catch {
        // FEMA API failure is non-critical
      }

      if (controller.signal.aborted) return null;

      // ====================================================================
      // STEP 3b: Tree canopy detection via NLCD (free ArcGIS service)
      // ====================================================================
      let treeCanopyPct = 0;
      try {
        // NLCD Tree Canopy Cover — 30m resolution, nationwide
        // Query a small bounding box around the property (~100m)
        const offset = 0.001; // ~111m at equator
        const bbox = `${lng - offset},${lat - offset},${lng + offset},${lat + offset}`;
        const nlcdRes = await fetch(
          `https://www.mrlc.gov/geoserver/mrlc_display/NLCD_2021_Tree_Canopy_L48/ows?service=WMS&version=1.1.1&request=GetFeatureInfo&layers=NLCD_2021_Tree_Canopy_L48&query_layers=NLCD_2021_Tree_Canopy_L48&info_format=application/json&x=50&y=50&width=100&height=100&srs=EPSG:4326&bbox=${bbox}`,
          { signal: controller.signal }
        );
        if (nlcdRes.ok) {
          const nlcdData = await nlcdRes.json();
          const val = nlcdData?.features?.[0]?.properties?.GRAY_INDEX;
          if (val != null && Number(val) > 0) {
            treeCanopyPct = Number(val); // 0-100 percent canopy cover
          }
        }
      } catch {
        // NLCD API failure is non-critical
      }

      if (controller.signal.aborted) return null;

      // ====================================================================
      // STEP 4: Build SitePlanData from all collected data
      // ====================================================================
      setProgress(80);
      setStage('building_sketch');

      const sitePlan = createEmptySitePlan();
      const structures = structRows.data || [];
      const parcels = parcelRows.data || [];
      const features = featureRow.data;
      const roof = roofRow.data;
      const facets = facetRows.data || [];
      const dataSources: string[] = (scan.scan_sources as string[]) || [];

      // --- Satellite background ---
      const satelliteUrl = getSatelliteUrl(lat, lng);
      if (satelliteUrl) {
        sitePlan.backgroundImageUrl = satelliteUrl;
        sitePlan.backgroundOpacity = 0.4;
        dataSources.push('mapbox_satellite');
      }

      // --- Parcel boundary ---
      if (parcels.length > 0) {
        const parcel = parcels[0];
        const boundaryGeojson = parcel.boundary_geojson as GeoJSON.Geometry | null;
        const points = geojsonToCanvasPoints(boundaryGeojson, lat, lng, CANVAS_CENTER, CANVAS_CENTER);
        if (points.length >= 3) {
          const totalArea = (parcel.lot_area_sqft as number) || polygonAreaSqFt(points);
          sitePlan.boundary = {
            id: `boundary-${parcel.id}`,
            points,
            totalArea,
          };
        }
      }

      // --- Structure outlines (building footprints) ---
      const structureOutlines: StructureOutline[] = [];
      for (const s of structures) {
        const geojson = s.footprint_geojson as GeoJSON.Geometry | null;
        const points = geojsonToCanvasPoints(geojson, lat, lng, CANVAS_CENTER, CANVAS_CENTER);
        if (points.length >= 3) {
          const footprintSqft = (s.footprint_sqft as number) || polygonAreaSqFt(points);
          const stories = (s.estimated_stories as number) || 1;
          const label = (s.label as string) || 'Structure';
          const isCommercialSize = footprintSqft > 5000;

          structureOutlines.push({
            id: `struct-${s.id || structureOutlines.length}`,
            points,
            label,
            roofPitch: roof ? Number(roof.pitch_degrees) || 0 : undefined,
            stories,
            buildingType: isCommercialSize ? 'office' : undefined,
          });
        }
      }
      sitePlan.structures = structureOutlines;

      // --- Roof planes from solar facets ---
      const roofPlanes: RoofPlane[] = [];
      if (facets.length > 0 && structureOutlines.length > 0) {
        const primaryStruct = structureOutlines[0];
        for (const f of facets) {
          const pitchDeg = Number(f.pitch_degrees) || 0;
          const areaSqft = Number(f.area_sqft) || 0;
          const azimuth = Number(f.azimuth_degrees) || 0;
          const facetNum = Number(f.facet_number) || 0;

          // Approximate roof plane points from structure centroid + azimuth
          const centroid = getCentroid(primaryStruct.points);
          const roofPoints = generateRoofFacetPoints(centroid, areaSqft, azimuth, primaryStruct.points);

          // Convert pitch degrees to rise/12
          const pitchRise = Math.round(Math.tan((pitchDeg * Math.PI) / 180) * 12);

          roofPlanes.push({
            id: `roof-${facetNum}`,
            structureId: primaryStruct.id,
            points: roofPoints,
            pitch: pitchRise,
            type: pitchDeg === 0 ? 'flat' : pitchDeg < 15 ? 'hip' : 'gable',
            wasteFactor: 0.10,
          });
        }
      }
      sitePlan.roofPlanes = roofPlanes;

      // --- Flood zone overlay ---
      if (floodZone && floodZone.inFloodplain) {
        const boundaryPoints = sitePlan.boundary?.points || [
          { x: CANVAS_CENTER - 400, y: CANVAS_CENTER - 400 },
          { x: CANVAS_CENTER + 400, y: CANVAS_CENTER - 400 },
          { x: CANVAS_CENTER + 400, y: CANVAS_CENTER + 400 },
          { x: CANVAS_CENTER - 400, y: CANVAS_CENTER + 400 },
        ];

        sitePlan.areaFeatures.push({
          id: 'flood-zone-overlay',
          type: 'floodZone',
          points: boundaryPoints,
          material: `Flood Zone ${floodZone.zone} (${floodZone.riskLevel} risk)`,
        });

        // Add warning label
        sitePlan.labels.push({
          id: 'flood-zone-label',
          position: { x: CANVAS_CENTER, y: CANVAS_CENTER - 350 },
          text: `FLOOD ZONE ${floodZone.zone} — ${floodZone.riskLevel.toUpperCase()} RISK`,
          fontSize: 14,
          rotation: 0,
        });
      }

      // --- Utility placement (standard rules when no GIS data) ---
      if (structureOutlines.length > 0) {
        const mainStruct = structureOutlines[0];
        const bbox = getBoundingBox(mainStruct.points);

        // Gas meter — typically left side of building
        sitePlan.symbols.push({
          id: 'util-gas-meter',
          type: 'gasMeter',
          position: { x: bbox.minX - 20, y: (bbox.minY + bbox.maxY) / 2 },
          rotation: 0,
          label: 'Gas Meter (approx.)',
        });

        // Water shutoff — from street (bottom)
        sitePlan.symbols.push({
          id: 'util-water-shutoff',
          type: 'waterShutoff',
          position: { x: (bbox.minX + bbox.maxX) / 2, y: bbox.maxY + 80 },
          rotation: 0,
          label: 'Water Shutoff (approx.)',
        });

        // Electrical meter — typically right side
        sitePlan.symbols.push({
          id: 'util-elec-meter',
          type: 'electricMeter',
          position: { x: bbox.maxX + 20, y: (bbox.minY + bbox.maxY) / 2 },
          rotation: 0,
          label: 'Electric Meter (approx.)',
        });

        // AC unit — typically back-right
        sitePlan.symbols.push({
          id: 'util-ac',
          type: 'acUnit',
          position: { x: bbox.maxX - 40, y: bbox.minY - 30 },
          rotation: 0,
          label: 'A/C Unit (approx.)',
        });

        // Water line from street to building
        sitePlan.linearFeatures.push({
          id: 'util-water-line',
          type: 'waterLine',
          points: [
            { x: (bbox.minX + bbox.maxX) / 2, y: bbox.maxY + 80 },
            { x: (bbox.minX + bbox.maxX) / 2, y: bbox.maxY },
          ],
        });

        // Gas line from street to meter
        sitePlan.linearFeatures.push({
          id: 'util-gas-line',
          type: 'gasLine',
          points: [
            { x: bbox.minX - 20, y: bbox.maxY + 80 },
            { x: bbox.minX - 20, y: (bbox.minY + bbox.maxY) / 2 },
          ],
        });

        // Sewer line — lowest point to street
        sitePlan.linearFeatures.push({
          id: 'util-sewer-line',
          type: 'sewerLine',
          points: [
            { x: (bbox.minX + bbox.maxX) / 2 + 40, y: bbox.maxY },
            { x: (bbox.minX + bbox.maxX) / 2 + 40, y: bbox.maxY + 80 },
          ],
        });
      }

      // --- Tree canopy auto-placement (NLCD data) ---
      if (treeCanopyPct > 20 && structureOutlines.length > 0) {
        const mainBbox = getBoundingBox(structureOutlines[0].points);
        const lotBbox = sitePlan.boundary
          ? getBoundingBox(sitePlan.boundary.points)
          : { minX: mainBbox.minX - 200, minY: mainBbox.minY - 200, maxX: mainBbox.maxX + 200, maxY: mainBbox.maxY + 200 };

        // Place trees proportionally to canopy coverage
        // More coverage = more trees. Avoid building footprint area.
        const treeCount = Math.min(12, Math.max(2, Math.round(treeCanopyPct / 10)));
        const rng = seedRandom(lat * 1000 + lng * 1000); // deterministic placement
        let placed = 0;

        for (let attempt = 0; attempt < treeCount * 4 && placed < treeCount; attempt++) {
          const tx = lotBbox.minX + rng() * (lotBbox.maxX - lotBbox.minX);
          const ty = lotBbox.minY + rng() * (lotBbox.maxY - lotBbox.minY);

          // Skip if inside any structure footprint (with buffer)
          const insideStructure = structureOutlines.some(s => {
            const sb = getBoundingBox(s.points);
            return tx >= sb.minX - 30 && tx <= sb.maxX + 30 && ty >= sb.minY - 30 && ty <= sb.maxY + 30;
          });
          if (insideStructure) continue;

          const treeTypes: Array<'treeDeciduous' | 'treeEvergreen'> = ['treeDeciduous', 'treeEvergreen'];
          sitePlan.symbols.push({
            id: `tree-${placed}`,
            type: treeTypes[placed % treeTypes.length],
            position: { x: tx, y: ty },
            rotation: 0,
            canopyRadius: 8 + rng() * 12, // 8-20 ft canopy radius
            label: `Tree (auto-placed, ${treeCanopyPct}% canopy)`,
          });
          placed++;
        }

        if (placed > 0) dataSources.push('nlcd_tree_canopy');
      }

      // --- Dimension lines for structure ---
      if (structureOutlines.length > 0) {
        const mainStruct = structureOutlines[0];
        const bbox = getBoundingBox(mainStruct.points);

        sitePlan.dimensions.push({
          id: 'dim-width',
          start: { x: bbox.minX, y: bbox.maxY + 30 },
          end: { x: bbox.maxX, y: bbox.maxY + 30 },
          offset: 15,
          isAuto: true,
        });

        sitePlan.dimensions.push({
          id: 'dim-depth',
          start: { x: bbox.maxX + 30, y: bbox.minY },
          end: { x: bbox.maxX + 30, y: bbox.maxY },
          offset: 15,
          isAuto: true,
        });
      }

      // --- Add commercial layers if needed ---
      const isCommercial = structureOutlines.some(s => {
        const area = polygonAreaSqFt(s.points);
        return area > 5000 || s.buildingType != null;
      });

      if (isCommercial) {
        const existingLayerIds = new Set(sitePlan.layers.map(l => l.id));
        const commercialLayers: SitePlanLayer[] = [
          { id: 'l-parking', type: 'parking', name: 'Parking', visible: true, locked: false, opacity: 1 },
          { id: 'l-fire', type: 'fireProtection', name: 'Fire Protection', visible: true, locked: false, opacity: 1 },
          { id: 'l-ada', type: 'ada', name: 'ADA Compliance', visible: true, locked: false, opacity: 1 },
          { id: 'l-signage', type: 'signage', name: 'Signage', visible: true, locked: false, opacity: 1 },
        ];
        for (const cl of commercialLayers) {
          if (!existingLayerIds.has(cl.id)) {
            sitePlan.layers.push(cl);
          }
        }
      }

      // --- Property info ---
      const propertyInfo: PropertyInfo = {
        yearBuilt: features?.year_built != null ? Number(features.year_built) : null,
        stories: features?.stories != null ? Number(features.stories) : null,
        livingSqft: features?.living_sqft != null ? Number(features.living_sqft) : null,
        lotSqft: features?.lot_sqft != null ? Number(features.lot_sqft) : null,
        beds: features?.beds != null ? Number(features.beds) : null,
        bathsFull: features?.baths_full != null ? Number(features.baths_full) : null,
        bathsHalf: features?.baths_half != null ? Number(features.baths_half) : null,
        constructionType: (features?.construction_type as string) || null,
        roofType: (features?.roof_type_record as string) || null,
        heatingType: (features?.heating_type as string) || null,
        coolingType: (features?.cooling_type as string) || null,
        propertyType: (features?.property_type as string) || null,
        assessedValue: features?.assessed_total != null ? Number(features.assessed_total) : null,
        lastSalePrice: features?.last_sale_price != null ? Number(features.last_sale_price) : null,
        lastSaleDate: (features?.last_sale_date as string) || null,
      };

      // ====================================================================
      // STEP 5: Build result
      // ====================================================================
      setProgress(100);
      setStage('complete');

      const lookupResult: PropertyLookupResult = {
        scanId,
        address: address.trim(),
        latitude: lat,
        longitude: lng,
        sitePlan,
        propertyInfo,
        floodZone,
        dataSources,
        confidenceScore: Number(scan.confidence_score) || 0,
        isCommercial,
      };

      setResult(lookupResult);
      return lookupResult;
    } catch (e) {
      if ((e as Error).name === 'AbortError') return null;
      const msg = e instanceof Error ? e.message : 'Property lookup failed';
      setError(msg);
      setStage('error');
      return null;
    }
  }, []);

  /** Cancel any in-flight lookup */
  const cancel = useCallback(() => {
    abortRef.current?.abort();
    setStage('idle');
    setProgress(0);
  }, []);

  /** Reset state */
  const reset = useCallback(() => {
    abortRef.current?.abort();
    setResult(null);
    setStage('idle');
    setProgress(0);
    setError(null);
  }, []);

  /**
   * Sync sketch measurements back to recon scan data.
   * When a contractor measures a wall or room in the sketch engine,
   * update the corresponding property_structures/roof_measurements.
   */
  const syncSketchToRecon = useCallback(async (
    scanId: string,
    updates: {
      totalRoofAreaSqft?: number;
      primaryPitch?: string;
      structureFootprintSqft?: number;
      stories?: number;
      wallAreaSqft?: number;
    }
  ) => {
    try {
      const supabase = createClient();

      if (updates.totalRoofAreaSqft != null || updates.primaryPitch != null) {
        const roofUpdate: Record<string, unknown> = {};
        if (updates.totalRoofAreaSqft != null) {
          roofUpdate.total_area_sqft = updates.totalRoofAreaSqft;
          roofUpdate.total_area_squares = updates.totalRoofAreaSqft / 100;
        }
        if (updates.primaryPitch != null) {
          roofUpdate.pitch_primary = updates.primaryPitch;
        }
        roofUpdate.data_source = 'sketch_engine';

        await supabase
          .from('roof_measurements')
          .update(roofUpdate)
          .eq('scan_id', scanId);
      }

      if (updates.structureFootprintSqft != null || updates.stories != null || updates.wallAreaSqft != null) {
        const structUpdate: Record<string, unknown> = {};
        if (updates.structureFootprintSqft != null) structUpdate.footprint_sqft = updates.structureFootprintSqft;
        if (updates.stories != null) structUpdate.estimated_stories = updates.stories;
        if (updates.wallAreaSqft != null) structUpdate.estimated_wall_area_sqft = updates.wallAreaSqft;

        await supabase
          .from('property_structures')
          .update(structUpdate)
          .eq('property_scan_id', scanId)
          .eq('structure_type', 'primary');
      }
    } catch (e) {
      console.error('[property-lookup] sync sketch→recon failed:', e);
    }
  }, []);

  return {
    result,
    stage,
    error,
    progress,
    lookupAddress,
    cancel,
    reset,
    syncSketchToRecon,
  };
}

// ============================================================================
// GEOMETRY HELPERS
// ============================================================================

function getCentroid(points: Point[]): Point {
  if (points.length === 0) return { x: 0, y: 0 };
  let sumX = 0, sumY = 0;
  for (const p of points) { sumX += p.x; sumY += p.y; }
  return { x: sumX / points.length, y: sumY / points.length };
}

function getBoundingBox(points: Point[]) {
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
  for (const p of points) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return { minX, minY, maxX, maxY };
}

/**
 * Generate approximate roof facet polygon from centroid, area, and azimuth.
 * This creates a reasonable facet shape oriented by azimuth within the structure bounds.
 */
function generateRoofFacetPoints(
  centroid: Point,
  areaSqft: number,
  azimuthDeg: number,
  structPoints: Point[]
): Point[] {
  const areaPx = areaSqft * SCALE_PX_PER_FT * SCALE_PX_PER_FT;
  const side = Math.sqrt(areaPx);
  const halfW = side / 2;
  const halfH = side / 2;

  // Azimuth rotation (0=south, 90=west, 180=north, 270=east in Google Solar)
  const rad = ((azimuthDeg - 180) * Math.PI) / 180;

  // Generate rectangle rotated by azimuth
  const corners: Point[] = [
    { x: -halfW, y: -halfH },
    { x: halfW, y: -halfH },
    { x: halfW, y: halfH },
    { x: -halfW, y: halfH },
  ];

  const cos = Math.cos(rad);
  const sin = Math.sin(rad);

  return corners.map(c => ({
    x: centroid.x + c.x * cos - c.y * sin,
    y: centroid.y + c.x * sin + c.y * cos,
  }));
}

/** Simple seeded PRNG for deterministic tree placement (Mulberry32) */
function seedRandom(seed: number): () => number {
  let s = seed | 0;
  return () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
