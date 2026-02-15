# ZAFTO CAD-Grade Sketch Engine — Expansion Spec
## Professional Floor Plan System: LiDAR Scan → Multi-Trade Layers → Auto-Estimate → Export
### Created: February 9, 2026 (Session 94)

---

## WHAT THIS IS

A professional CAD-grade sketch engine that replaces every contractor sketch tool on the market. LiDAR scanning on iPhone (Apple RoomPlan), full multi-trade layer overlays, auto-estimate generation bridging to D8, web CRM canvas editor (Konva.js), 3D visualization (three.js), and export to PDF/PNG/DXF/FML.

**No competitor does:** LiDAR scan → floor plan → multi-trade overlays → auto-estimate → export → job management → invoice — all in one platform with real-time mobile-to-web sync.

---

## WHY THIS MATTERS

The current sketch editor (`sketch_editor_screen.dart`, 1,329 lines) is genuinely functional — wall drawing, chain mode, angle/endpoint snapping, 7 door types, 6 window types, 25 fixture types, undo/redo, multi-floor. But it has critical gaps that prevent it from replacing dedicated sketch tools:

- No wall editing after drawing (can't drag endpoints)
- No arc walls
- Hardcoded 6" wall thickness
- No fixture rotation UI
- No trade-specific layers (electrical, plumbing, HVAC, damage)
- No LiDAR scanning integration
- No export (PDF, DXF, or any format)
- No auto-estimate generation from sketch measurements
- Web CRM has zero canvas — just a CRUD form for rooms with dimensions
- No mobile-to-web sync of floor plans

---

## COMPETITIVE LANDSCAPE

| Feature | magicplan | Xactimate Sketch | HOVER | ArcSite | **ZAFTO** |
|---------|-----------|-------------------|-------|---------|-----------|
| LiDAR scan | Yes | No | Photo AI | No | **Yes (RoomPlan)** |
| Multi-trade layers | No | Damage only | No | No | **Yes (4 trades)** |
| Auto-estimate | No | Yes (locked ecosystem) | Yes ($) | No | **Yes (open)** |
| Web editor | No | Desktop only | No | iPad only | **Yes (Konva)** |
| 3D view | Yes ($) | No | Yes | No | **Yes (three.js)** |
| Offline-first | Yes | Yes | No | Partial | **Yes (Hive)** |
| DXF export | No | No | No | Yes | **Yes** |
| Job management integration | No | No | No | Partial | **Yes (full CRM)** |
| Mobile-to-Web sync | No | No | No | No | **Yes (real-time)** |
| IICRC damage mapping | No | Partial | No | No | **Yes (full)** |

**Key competitor weaknesses:**
- **magicplan**: No trade layers, no estimate generation, no web editor, subscription wall for 3D
- **Xactimate Sketch**: Desktop only, locked to Verisk ecosystem, no LiDAR, no web
- **HOVER**: Photo-based (no manual editing), expensive per-job pricing ($25+), no trade layers
- **ArcSite**: iPad only, no LiDAR, no damage mapping, limited export

---

## PROBLEM: TWO DISCONNECTED TABLE SYSTEMS

Currently two separate table systems exist with no connection between them or to the D8 estimate engine:

1. **`property_floor_plans`** (from E6a walkthrough engine migration)
   - Geometric data: plan_data JSONB, source, thumbnail
   - Linked to walkthroughs and properties

2. **`bid_sketches` + `sketch_rooms`** (from F4f sketch-bid migration)
   - Business data: rooms with dimensions, damage assessment, IICRC classification
   - Linked to jobs
   - `bid_sketches.sketch_data` JSONB column exists but unused

3. **D8 Estimates** — completely independent, no auto-sync from sketches

**Solution:** Unify around `property_floor_plans` as the single geometric source of truth. `bid_sketches` gets a FK to link to floor plans. New bridge table connects rooms to estimate areas.

---

## UNIFIED DATA MODEL

### ALTER `property_floor_plans`
Add columns:
- `job_id UUID REFERENCES jobs(id)` — link plan to a job
- `estimate_id UUID REFERENCES estimates(id)` — link plan to D8 estimate
- `status TEXT CHECK (status IN ('draft','scanning','processing','complete','archived'))` DEFAULT 'draft'
- `sync_version INTEGER DEFAULT 1` — offline conflict resolution
- `last_synced_at TIMESTAMPTZ`

### New Table: `floor_plan_layers`
Trade layers per plan (electrical, plumbing, HVAC, damage, custom).
```
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE
company_id UUID NOT NULL REFERENCES companies(id)
layer_type TEXT NOT NULL CHECK (layer_type IN ('electrical','plumbing','hvac','damage','custom'))
layer_name TEXT
layer_data JSONB NOT NULL DEFAULT '{}'
visible BOOLEAN DEFAULT true
locked BOOLEAN DEFAULT false
opacity NUMERIC DEFAULT 1.0 CHECK (opacity >= 0 AND opacity <= 1)
sort_order INTEGER DEFAULT 0
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

### New Table: `floor_plan_rooms`
Detected/drawn rooms with computed measurements.
```
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE
company_id UUID NOT NULL REFERENCES companies(id)
name TEXT NOT NULL
boundary_points JSONB NOT NULL — [{x, y}, ...]
boundary_wall_ids JSONB — [wall_id, ...]
floor_area_sf NUMERIC
wall_area_sf NUMERIC
perimeter_lf NUMERIC
ceiling_height_inches INTEGER DEFAULT 96
floor_material TEXT
damage_class TEXT CHECK (damage_class IN ('class_1','class_2','class_3','class_4'))
iicrc_category TEXT CHECK (iicrc_category IN ('cat_1','cat_2','cat_3'))
room_type TEXT CHECK (room_type IN ('bedroom','bathroom','kitchen','living_room','dining_room','garage','basement','attic','hallway','closet','laundry','office','utility','other'))
metadata JSONB DEFAULT '{}'
created_at TIMESTAMPTZ DEFAULT now()
updated_at TIMESTAMPTZ DEFAULT now()
```

### New Table: `floor_plan_estimate_links`
Bridge table connecting rooms to estimate areas for auto-estimate pipeline.
```
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
floor_plan_id UUID NOT NULL REFERENCES property_floor_plans(id) ON DELETE CASCADE
room_id UUID NOT NULL REFERENCES floor_plan_rooms(id) ON DELETE CASCADE
estimate_id UUID NOT NULL REFERENCES estimates(id) ON DELETE CASCADE
estimate_area_id UUID NOT NULL REFERENCES estimate_areas(id) ON DELETE CASCADE
auto_generated BOOLEAN DEFAULT true
company_id UUID NOT NULL REFERENCES companies(id)
created_at TIMESTAMPTZ DEFAULT now()
```

### ALTER `bid_sketches`
Add column:
- `floor_plan_id UUID REFERENCES property_floor_plans(id)` — link to unified floor plan

### FloorPlanDataV2 Schema (JSONB in plan_data)
```json
{
  "version": 2,
  "units": "imperial",
  "scale": { "pixelsPerFoot": 20 },
  "walls": [{
    "id": "uuid",
    "start": { "x": 0, "y": 0 },
    "end": { "x": 120, "y": 0 },
    "thickness": 6,
    "height": 96,
    "type": "straight",
    "arcControlPoint": null,
    "material": "drywall"
  }],
  "doors": [{
    "id": "uuid",
    "wallId": "wall-uuid",
    "position": 0.5,
    "type": "standard",
    "width": 36,
    "swing": "left",
    "hingePoint": "start"
  }],
  "windows": [{
    "id": "uuid",
    "wallId": "wall-uuid",
    "position": 0.3,
    "width": 36,
    "height": 48,
    "sillHeight": 36
  }],
  "fixtures": [{
    "id": "uuid",
    "position": { "x": 60, "y": 60 },
    "rotation": 0,
    "type": "receptacle_standard",
    "symbol": "electrical",
    "layerId": "electrical-layer-uuid",
    "scale": 1.0
  }],
  "rooms": [{
    "id": "uuid",
    "name": "Living Room",
    "boundaryWallIds": ["wall-1", "wall-2", "wall-3", "wall-4"],
    "floorMaterial": "hardwood",
    "ceilingHeight": 96
  }],
  "labels": [{
    "id": "uuid",
    "position": { "x": 60, "y": 30 },
    "text": "Living Room\n180 SF",
    "fontSize": 12,
    "rotation": 0
  }],
  "dimensions": [{
    "id": "uuid",
    "start": { "x": 0, "y": 0 },
    "end": { "x": 120, "y": 0 },
    "value": 120,
    "offset": 20
  }],
  "tradeLayers": {
    "electrical": {
      "elements": [],
      "paths": [],
      "groups": []
    },
    "plumbing": {
      "elements": [],
      "paths": [],
      "groups": []
    },
    "hvac": {
      "elements": [],
      "paths": [],
      "groups": []
    },
    "damage": {
      "zones": [],
      "barriers": [],
      "readings": []
    }
  },
  "lidarMetadata": null
}
```

**Backward compatibility:** V1 plans (no `version` field) still parse — treat as V2 with empty tradeLayers and `units: "imperial"`.

---

## TRADE LAYER SYSTEM

### Electrical Layer (15 symbols)
- **Receptacles:** Standard, GFCI, 240V, Floor
- **Switches:** Single-pole, 3-way, Dimmer, Smart
- **Lights:** Ceiling, Recessed, Pendant, Track, Under-cabinet
- **Equipment:** Panel, Junction Box
- **Wire Paths:** Draw circuit runs between elements, auto-route along walls
- **Circuit Grouping:** Assign elements to circuits, color-coded

### Plumbing Layer (12 symbols)
- **Fixtures:** Sink, Toilet, Shower, Tub, Washer, Water Heater, Hose Bib
- **Pipes:** Hot (red), Cold (blue), Drain (gray), Gas (yellow)
- **Supply/drain routing** with diameter labels

### HVAC Layer (10 symbols)
- **Equipment:** Furnace, Condenser, Air Handler, Mini-Split, ERV
- **Distribution:** Supply Duct, Return Duct, Register, Thermostat, Damper
- **Duct routing** with CFM labels

### Damage Layer (4 tools)
- **Affected Area Zone:** Polygon fill with opacity — Class 1-4 color coding
- **Moisture Reading Points:** Value + location, color-coded by severity
- **Containment Barrier Lines:** Dashed red
- **Source Arrow:** Points to origin of damage
- **IICRC Category Overlay:** Cat 1 blue, Cat 2 yellow, Cat 3 red

### Layer Controls
- Collapsible layer panel: visibility toggle, lock toggle, opacity slider
- Active layer selector — drawing tools change based on active layer
- Layer-specific toolbars appear when layer is selected

---

## LIDAR SCANNING — APPLE ROOMPLAN INTEGRATION

### Architecture
```
Swift RoomPlanService (native iOS)
  → MethodChannel 'com.zafto.roomplan'
    → Dart RoomPlanBridge
      → RoomPlanConverter (CapturedRoom → FloorPlanDataV2)
        → Save to Supabase + Hive cache
```

### Requirements
- iOS 16+, iPhone/iPad with LiDAR sensor (iPhone 12 Pro and later)
- Apple RoomPlan framework — auto-detects walls, doors, windows, furniture

### 3D→2D Projection
RoomPlan provides 3D data (4x4 transform matrices). Conversion:
- Extract X and Z from each wall's transform matrix (Y is vertical/height)
- Scale: meters → inches (multiply by 39.3701)
- Wall endpoints: center ± (length/2) along wall's orientation vector
- Height preserved in Wall.height for 3D visualization later
- Door/window positions: parametric position along parent wall

### Guided Scanning UX
1. User taps "LiDAR Scan" in sketch toolbar
2. Check device capability: `ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)`
3. If no LiDAR → show "Manual Entry" fallback with room-by-room dimension input
4. Instructions overlay: "Slowly walk through the room. Point at all walls, doors, and windows."
5. Real-time preview shows detected walls/openings
6. "Done" → processing spinner → FloorPlanDataV2 generated → editor opens with scanned plan
7. User can edit/correct anything (walls snap to scanned positions but are fully editable)

### Multi-Room Scanning
- Scan one room → save → scan next room → merge
- Or walk through multiple rooms in one session (RoomPlan handles this natively)
- Room boundaries auto-detected from wall topology

### Fallback (Non-LiDAR Devices)
- Manual room entry: name, width, length, height
- Generates rectangular rooms arranged in grid layout
- User can then edit walls, add doors/windows manually
- Also works on Android (no RoomPlan equivalent)

---

## WEB CRM CANVAS EDITOR — KONVA.JS

### Why Konva.js (over alternatives)
- **vs tldraw:** Whiteboard-focused, wrong primitives for architectural drawing
- **vs raw Canvas2D:** Too much reinvention (hit detection, transform handles, scene graph)
- **vs fabric.js:** Less React-friendly, slower for large shape counts
- **Konva.js:** Scene graph with per-shape hit detection, react-konva for React integration, handles 1000+ shapes at 60fps, built-in drag/transform/snap-to-grid, actively maintained (10k+ GitHub stars)

### Architecture
```
FloorPlanDataV2 (from Supabase)
  → TypeScript geometry engine (ported from Dart)
    → Konva Stage
      → Base Layer (walls, doors, windows, rooms)
      → Trade Layers (electrical, plumbing, HVAC, damage)
      → UI Layer (selection, handles, dimensions, cursor)
```

### TypeScript Port
Port core geometry and command pattern from Dart to TypeScript:
- `floor_plan_elements.dart` → `lib/sketch-engine/types.ts` (interfaces)
- `SketchGeometry` class → `lib/sketch-engine/geometry.ts` (snap, intersect, room detection)
- `UndoRedoManager` + Commands → `lib/sketch-engine/commands.ts`
- `sketch_painter.dart` rendering → Konva shape factories in `lib/sketch-engine/renderers/`

### Web Editor Features (parity with Flutter + extras)
- All drawing tools: wall, arc wall, door, window, fixture, label, dimension
- All trade layer tools
- Pan (middle-click or space+drag) and zoom (scroll wheel)
- Property inspector panel (right sidebar)
- Keyboard shortcuts: Ctrl+Z/Y, Ctrl+C/V, Delete, Escape
- Snap to grid, snap to wall endpoints, angle snap (15-degree increments)
- Mini-map in corner for large plans
- Ruler along top and left edges
- Real-time sync with Supabase (debounced 500ms save, conflict detection via sync_version)

---

## AUTO-ESTIMATE PIPELINE

### Geometry → Measurements
From FloorPlanDataV2, auto-calculate per room:
- **Floor SF:** Shoelace formula on room boundary polygon
- **Wall SF:** sum(wall_length * wall_height) for boundary walls, minus door/window openings
- **Ceiling SF:** Same as floor SF (flat ceiling assumption, adjustable)
- **Baseboard LF:** Perimeter minus door widths
- **Door/Window Count:** From room boundary walls
- **Paint SF:** Wall SF + ceiling SF (configurable)

### Pipeline
```
FloorPlanDataV2
  → RoomMeasurementCalculator (per room)
    → EstimateAreaGenerator (creates estimate_areas rows)
      → LineItemSuggester (maps to estimate_items via trade + room type)
        → D8 Estimates (pricing lookup, totals)
```

### Line Item Suggestion Logic
- Room type + trade: e.g., bathroom + plumbing → toilet, sink, shower rough-in
- Damage layer data: e.g., Class 3 water damage → demo drywall, dry structure, replace drywall
- Trade layer elements: e.g., 5 receptacles → 5x receptacle rough-in line items
- User reviews and adjusts before finalizing

---

## EXPORT PIPELINE

### PDF Export
- Title block (company name, project address, date, scale)
- Floor plan drawing (all visible layers)
- Room schedule table (room name, dimensions, area, perimeter)
- Legend for trade symbols
- Uses existing `pdf` + `printing` packages (Flutter), jsPDF (web)

### PNG Export
- High-resolution raster (2x, 4x scale options)
- Flutter: `RepaintBoundary.toImage()`, Web: Konva `stage.toDataURL()`

### DXF Export (AutoCAD Interop)
- Well-documented ASCII format — custom writer, no third-party dependency
- Walls → LINE/LWPOLYLINE entities
- Rooms → HATCH fills
- Doors/windows → INSERT block references
- Trade elements → separate DXF layers

### FML Export (Floor Markup Language — Open Format)
- XML-based open format — safe for Symbility/Cotality integration
- No Verisk partnership needed (FML is not Xactimate)
- NOT accepted by Xactimate (ESX export deferred pending IP attorney)
- Rooms, walls, openings, dimensions

---

## 3D VISUALIZATION — THREE.JS (Web CRM Only)

- Toggle between 2D (Konva) and 3D (three.js) views
- Wall extrusion: 2D wall → 3D rectangular prism at wall height
- Door/window openings: boolean subtraction from wall geometry
- Floor plane with material texture
- Trade elements as 3D icons
- Orbit controls: rotate, pan, zoom
- `three` + `@react-three/fiber` + `@react-three/drei` for React integration

---

## SYNC PIPELINE — OFFLINE-FIRST + REAL-TIME

### Mobile (Flutter)
- Existing Hive boxes for local cache
- New box: `floor_plans_cache` — stores FloorPlanDataV2 JSON per plan ID
- Every edit saves to Hive immediately (zero-latency UX)
- Background sync via `ConnectivityService` when online

### Sync Protocol
1. Edit on mobile → save to Hive + increment local version
2. When online → POST to Supabase with `sync_version` check
3. Supabase: if incoming version <= current → reject (409 conflict)
4. If accepted → broadcast via real-time channel
5. Web CRM receives update → re-render canvas
6. Thumbnail auto-generated: render to 512x512 PNG → upload to storage bucket

### Conflict Resolution
- Server `sync_version` wins if higher
- User prompted to merge or overwrite when conflict detected

---

## LEGAL NOTES

- **ESX Import:** LOW risk — reading ESX files is OK (S83/S92 legal research confirmed)
- **ESX Export:** MEDIUM risk — deferred pending Verisk Strategic Alliances partnership or IP attorney opinion letter (S89 owner directive: defer to revenue stage)
- **FML Export:** SAFE — open format, no Verisk ownership
- **DXF Export:** SAFE — open standard (AutoCAD interop)
- **Apple RoomPlan:** Public framework, no licensing issues, standard Apple developer terms
- **Konva.js:** MIT license
- **three.js:** MIT license

---

## FILE INVENTORY

### New Files — Flutter (Mobile)
| File | Purpose |
|------|---------|
| `lib/models/floor_plan_layer.dart` | FloorPlanLayer model |
| `lib/models/floor_plan_room.dart` | FloorPlanRoom model |
| `lib/models/trade_layer.dart` | TradeElement, TradePath, TradeGroup, DamageZone, MoistureReading, ContainmentBarrier |
| `lib/widgets/sketch/trade_toolbar.dart` | Per-trade toolbars |
| `lib/widgets/sketch/layer_panel.dart` | Layer management UI |
| `lib/widgets/sketch/lidar_scan_screen.dart` | LiDAR scanning overlay UX |
| `lib/widgets/sketch/manual_room_entry.dart` | Fallback for non-LiDAR devices |
| `lib/painters/trade_layer_painter.dart` | Trade layer overlay rendering |
| `lib/services/roomplan_bridge.dart` | MethodChannel Dart side for RoomPlan |
| `lib/services/roomplan_converter.dart` | CapturedRoom JSON → FloorPlanDataV2 |
| `lib/services/floor_plan_sync_service.dart` | Offline-first sync with Supabase |
| `lib/services/floor_plan_thumbnail_service.dart` | Thumbnail generation |
| `lib/services/room_measurement_calculator.dart` | Geometry → measurements |
| `lib/services/estimate_area_generator.dart` | Measurements → estimate areas |
| `lib/services/line_item_suggester.dart` | Trade-based line item suggestions |
| `lib/services/sketch_export_service.dart` | PDF, PNG, DXF, FML export |
| `lib/services/dxf_writer.dart` | DXF format generator |
| `lib/services/fml_writer.dart` | FML format generator |
| `lib/repositories/floor_plan_repository.dart` | Supabase CRUD for floor plans |
| `ios/Runner/RoomPlanService.swift` | Native RoomPlan integration |
| SVG assets (62 trade symbols) | Electrical (15), Plumbing (12), HVAC (10), Damage icons |

### New Files — Web CRM
| File | Purpose |
|------|---------|
| `src/lib/sketch-engine/types.ts` | TypeScript interfaces (ported from Dart) |
| `src/lib/sketch-engine/geometry.ts` | Geometry utilities (snap, intersect, room detection) |
| `src/lib/sketch-engine/commands.ts` | Command pattern + undo/redo |
| `src/lib/sketch-engine/renderers/wall-renderer.ts` | Konva wall shapes |
| `src/lib/sketch-engine/renderers/door-renderer.ts` | Konva door shapes |
| `src/lib/sketch-engine/renderers/window-renderer.ts` | Konva window shapes |
| `src/lib/sketch-engine/renderers/fixture-renderer.ts` | Konva fixture shapes |
| `src/lib/sketch-engine/renderers/trade-renderer.ts` | Konva trade layer shapes |
| `src/lib/sketch-engine/renderers/damage-renderer.ts` | Konva damage layer shapes |
| `src/lib/sketch-engine/measurement-calculator.ts` | Room measurement calculator |
| `src/lib/sketch-engine/estimate-generator.ts` | Auto-estimate from measurements |
| `src/lib/sketch-engine/three-converter.ts` | FloorPlanData → three.js scene |
| `src/lib/sketch-engine/export/pdf-export.ts` | PDF export |
| `src/lib/sketch-engine/export/png-export.ts` | PNG export |
| `src/lib/sketch-engine/export/dxf-export.ts` | DXF export |
| `src/lib/sketch-engine/export/fml-export.ts` | FML export |
| `src/components/sketch-editor/SketchCanvas.tsx` | Main Konva Stage component |
| `src/components/sketch-editor/Toolbar.tsx` | Drawing tools toolbar |
| `src/components/sketch-editor/LayerPanel.tsx` | Layer management panel |
| `src/components/sketch-editor/PropertyInspector.tsx` | Selected element properties |
| `src/components/sketch-editor/MiniMap.tsx` | Mini-map for navigation |
| `src/components/sketch-editor/ThreeDView.tsx` | three.js 3D visualization |
| `src/components/sketch-editor/ViewToggle.tsx` | 2D/3D view toggle |
| `src/components/sketch-editor/ExportModal.tsx` | Export format selection |
| `src/components/sketch-editor/GenerateEstimateModal.tsx` | Auto-estimate generation |
| `src/lib/hooks/use-floor-plan.ts` | Supabase CRUD + real-time for floor plans |

### Modified Files
| File | Changes |
|------|---------|
| `lib/models/floor_plan_elements.dart` | V2 types: ArcWall, TradeElement, TradeGroup, TradePath, DamageZone, DamageBarrier, FloorPlanDataV2 |
| `lib/models/floor_plan.dart` | New columns: job_id, estimate_id, status, sync_version, last_synced_at |
| `lib/screens/walkthrough/sketch_editor_screen.dart` | Wall editing, thickness, rotation, arc walls, layers, LiDAR, export, estimate |
| `lib/screens/walkthrough/sketch_painter.dart` | Thick walls, arc walls, selection handles, rotation handles, trade layers, auto-dimensions |
| `web-portal/src/app/dashboard/sketch-bid/page.tsx` | Replace form UI with full Konva canvas editor |
| `web-portal/package.json` | Add konva, react-konva, three, @react-three/fiber, @react-three/drei, jspdf |
| `pubspec.yaml` | No new packages (platform channels built-in, pdf/printing already present) |

### New Migrations
| Migration | Tables/Changes |
|-----------|---------------|
| `sk1_unified_sketch_model.sql` | ALTER property_floor_plans + CREATE floor_plan_layers + floor_plan_rooms + floor_plan_estimate_links + ALTER bid_sketches |

---

## SPRINT SUMMARY

| Sprint | Focus | Hours |
|--------|-------|:-----:|
| SK1 | Unified Data Model + Migration | ~16 |
| SK2 | Flutter Editor Upgrades Part 1 (wall editing, thickness, rotation, units) | ~16 |
| SK3 | Flutter Editor Upgrades Part 2 (arc walls, copy/paste, multi-select, smart dims) | ~12 |
| SK4 | Trade Layers System (electrical 15, plumbing 12, HVAC 10, damage 4) | ~20 |
| SK5 | LiDAR Scanning — Apple RoomPlan (Swift platform channel, converter, fallback) | ~20 |
| SK6 | Web CRM Canvas Editor — Konva.js (TypeScript port, full editor, real-time sync) | ~24 |
| SK7 | Sync Pipeline — Offline-First + Real-Time (Hive cache, Supabase sync, thumbnails) | ~12 |
| SK8 | Auto-Estimate Pipeline (geometry→measurements→estimate areas→D8 line items) | ~16 |
| SK9 | Export Pipeline (PDF, PNG, DXF, FML) | ~12 |
| SK10 | 3D Visualization — three.js (wall extrusion, orbit controls, 2D/3D toggle) | ~16 |
| SK11 | Polish + Testing + Button Audit | ~12 |
| **Total** | | **~176** |

**Build order:** SK1 → SK2 → SK3 → SK4 → SK5 → SK7 → SK6 → SK8 → SK9 → SK10 → SK11

**Dependencies:**
- SK1 is foundation for everything
- SK2+SK3 must complete before SK4 (trade layers build on editing)
- SK4 before SK5 (LiDAR imports into layer system)
- SK1+SK4 before SK8 (auto-estimate needs rooms + trade data)
- SK6 before SK10 (3D needs web canvas data)
- SK8+SK9 before SK11 (testing needs all features)

---

## PACKAGES ADDED

### Flutter (pubspec.yaml)
None — platform channels are built-in, `pdf` + `printing` already present.

### Web CRM (package.json)
- `konva` — Canvas scene graph library
- `react-konva` — React bindings for Konva
- `three` — 3D visualization
- `@react-three/fiber` — React renderer for three.js
- `@react-three/drei` — Useful helpers for React Three Fiber
- `jspdf` — PDF generation (if needed — may use Konva toDataURL + server-side)
