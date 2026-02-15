# 44 — ZAFTO Bid Walkthrough Engine

## Expansion Spec — Phase E6
### Created: Session 75 (Feb 7, 2026)
### Status: SPEC COMPLETE — Blocked on Phase E readiness + Flutter app modernization

---

## 1. VISION

A contractor walks into a property, opens ZAFTO, and walks room by room through the entire structure. Every photo, every measurement, every note, every dimension — captured in one guided flow. LiDAR scans the room. The contractor annotates photos, draws a sketch, corrects any dimensions that are off. When they're done, everything auto-uploads to the CRM — organized, labeled, and filed. Z Intelligence takes all of it and writes a complete, format-perfect bid. The contractor reviews it in the truck, makes edits if needed, and sends it before they leave the driveway.

No switching between apps. No emailing photos to yourself. No going back to the office to "write it up." No magicplan + CompanyCam + Xactimate + Excel. One app. One walkthrough. One bid.

**This is the reason a contractor downloads ZAFTO.**

---

## 2. THE WALKTHROUGH FLOW

### 2a. Start a Walkthrough

The contractor taps "New Walkthrough" from the home screen or from within a job/bid.

**Prompt screen:**
- Project name (required) — "Smith Kitchen Remodel", "423 Oak St Water Damage"
- Link to existing customer (optional — search or create new)
- Link to existing job (optional)
- Walkthrough type (determines bid format defaults):
  - **General Contracting** — kitchen/bath remodel, addition, renovation
  - **Trade-Specific** — electrical, plumbing, HVAC, roofing, etc.
  - **Insurance Restoration** — water, fire, wind, mold, storm damage
  - **Property Inspection** — pre-purchase, annual, move-in/move-out
  - **Commercial** — tenant improvement, buildout, retrofit
  - **Custom** — user-defined workflow
- Property type: residential / commercial / industrial / multi-family
- Address (auto-fill from customer if linked, or enter new — used for LiDAR geo-tagging and regional pricing)

**The walkthrough type determines:**
- Default room list suggestions
- Which bid format to generate
- What AI prompts to use for scope analysis
- What code categories to suggest (Xactimate codes for insurance, standard line items for general)

### 2b. Room-by-Room Capture

After starting, the app enters **Walkthrough Mode** — a dedicated full-screen experience optimized for field capture.

**Room flow:**
```
Add Room → Name it → Capture (Photos + LiDAR + Notes) → Next Room → ... → Finish
```

**Per room, the contractor can:**

1. **Name the room** — preset list (Kitchen, Master Bedroom, Bathroom, Garage, etc.) + custom entry
2. **Set the floor level** — Basement, 1st Floor, 2nd Floor, Attic, Exterior
3. **Take photos** — unlimited per room, auto-numbered (Kitchen-01, Kitchen-02...)
4. **LiDAR scan** — capture room dimensions automatically via iOS ARKit
5. **Annotate photos** — draw on photos, add text callouts, circle problem areas, arrow to defects
6. **Add voice notes** — tap and talk, auto-transcribed, attached to the room
7. **Add text notes** — free-form per room ("Water stain on ceiling, approx 4x6 ft, drywall soft")
8. **Tag conditions** — quick-tag chips: "Damage", "Replace", "Repair", "Demo", "New Install", "Upgrade", "Code Violation"
9. **Tag materials** — what's in the room: drywall, hardwood, tile, carpet, etc.
10. **Pin assets** — identify equipment in the room: HVAC unit, water heater, panel, etc.

**Photo capture is smart:**
- Auto-detects if photo is blurry → re-take prompt
- Embeds GPS + compass heading + timestamp in EXIF
- Groups photos by room automatically
- Supports burst mode for documentation speed
- Front-facing for selfie-with-damage (proof contractor was on site)

**LiDAR capture per room:**
- Scans walls, floor, ceiling automatically
- Measures room dimensions (L x W x H)
- Detects openings (doors, windows) with dimensions
- Detects obstructions (cabinets, counters, fixtures)
- All measurements editable after capture (see Section 4)
- Falls back to manual entry on non-LiDAR devices (tape measure + type dimensions)

### 2c. Exterior Capture

Same flow but for exterior elements:
- **Roof** — LiDAR pitch measurement, photo of each slope/section, material identification
- **Siding** — material, condition, dimensions
- **Windows/Doors** — count, type, dimensions, condition
- **Landscaping** — trees, hardscape, fencing, drainage
- **Utilities** — meter locations, service entries, disconnects
- **Foundation** — visible cracks, settling, moisture

### 2d. Sketch Mode

At any point during the walkthrough, the contractor can switch to **Sketch Mode** to draw the property layout.

**Sketch capabilities:**
- Draw walls by dragging (snap to grid, snap to LiDAR dimensions if scanned)
- Auto-populate rooms from LiDAR scans (contractor adjusts/corrects)
- Add doors, windows, stairs, fixtures from a symbol library
- Dimension labels auto-placed (editable)
- Multi-floor support (tabs per floor level)
- Pinch to zoom, two-finger to pan
- Undo/redo stack (unlimited)
- Save as structured JSON (not just an image — every wall, door, dimension is data)

**Symbol library (trade-specific):**
- **General:** Doors, windows, stairs, walls, counters, cabinets, fixtures
- **Electrical:** Outlets, switches, panels, junction boxes, light fixtures, conduit runs
- **Plumbing:** Fixtures, supply lines, drain lines, cleanouts, water heater, valves
- **HVAC:** Supply/return vents, ductwork, units (indoor/outdoor), thermostats
- **Fire:** Smoke detectors, sprinkler heads, pull stations, extinguishers
- **Structural:** Beams, columns, load-bearing walls (marked differently), footings

### 2e. Finish & Upload

When the contractor taps "Finish Walkthrough":

1. **Upload begins immediately** — all photos, scans, sketches, voice notes upload to Supabase Storage in background
2. **Storage organization:**
   ```
   company/{company_id}/walkthroughs/{walkthrough_id}/
     |-- metadata.json          -- Walkthrough config, room list, timestamps
     |-- rooms/
     |     |-- kitchen/
     |     |     |-- photos/
     |     |     |     |-- kitchen-01.jpg
     |     |     |     |-- kitchen-02.jpg
     |     |     |-- annotations/
     |     |     |     |-- kitchen-01-annotated.png
     |     |     |-- lidar/
     |     |     |     |-- kitchen-scan.json    -- Structured dimension data
     |     |     |-- voice/
     |     |           |-- kitchen-note-01.m4a
     |     |-- master-bedroom/
     |     |-- ...
     |-- exterior/
     |     |-- roof/
     |     |-- siding/
     |     |-- ...
     |-- sketches/
     |     |-- floor-1.json     -- Structured floor plan data
     |     |-- floor-2.json
     |     |-- floor-1-render.png  -- Pre-rendered image for quick display
     |-- summary/
           |-- bid-draft.pdf    -- AI-generated bid
           |-- bid-data.json    -- Structured bid data for editing
   ```
3. **CRM project created** — appears in Web CRM under the customer/job with all files organized
4. **Z Intelligence triggered** — AI analyzes everything and generates the bid (see Section 6)
5. **Push notification** to office: "New walkthrough uploaded: Smith Kitchen Remodel — bid ready for review"

### 2f. Offline Support

**Critical:** Walkthroughs happen on job sites. Cell signal is unreliable.

- **Full offline capture** — everything saves to device (PowerSync SQLite + local file storage)
- **Upload queues when connection returns** — background upload, resume on interruption
- **Progress indicator** — "23 of 47 files uploaded" with retry on failure
- **AI bid generation waits for upload** — can't run until data reaches server
- **Walkthrough is never lost** — even if app crashes mid-walkthrough, all captured data persists locally

---

## 3. CUSTOMIZABLE WORKFLOWS

### Philosophy: Every Company Is Different

A roofing contractor's walkthrough looks nothing like an electrician's. A water damage restoration company needs moisture readings in every room. A general contractor doing kitchen remodels needs cabinet measurements and appliance specs. A commercial contractor needs ADA compliance checks.

**ZAFTO doesn't prescribe the workflow. The company does.**

### 3a. Workflow Templates

Company Owner/Admin configures workflow templates in the Web CRM (Settings > Walkthrough Workflows).

**Template structure:**
```json
{
  "name": "Water Damage Restoration",
  "type": "insurance_restoration",
  "bidFormat": "xactimate",
  "defaultRooms": ["Kitchen", "Bathroom", "Laundry", "Utility"],
  "requiredPerRoom": {
    "photos": { "min": 3, "max": null },
    "lidar": true,
    "moistureReading": true,
    "conditionTags": true,
    "materialTags": true
  },
  "requiredOverall": {
    "exteriorPhotos": true,
    "sketch": true,
    "voiceNote": false
  },
  "customFields": [
    { "key": "category_of_loss", "label": "Category of Loss", "type": "select", "options": ["Cat 1 - Clean", "Cat 2 - Gray", "Cat 3 - Black"] },
    { "key": "source_of_loss", "label": "Source of Loss", "type": "text" },
    { "key": "affected_areas_count", "label": "# Affected Areas", "type": "number" }
  ],
  "perRoomFields": [
    { "key": "moisture_level", "label": "Moisture Reading", "type": "number", "unit": "%" },
    { "key": "material_affected", "label": "Material Affected", "type": "multi_select", "options": ["Drywall", "Baseboard", "Flooring", "Subfloor", "Insulation", "Cabinet"] },
    { "key": "ceiling_affected", "label": "Ceiling Affected?", "type": "boolean" }
  ],
  "checklistItems": [
    "Source of loss identified and documented",
    "All affected materials tagged",
    "Moisture readings in all affected areas",
    "Containment setup documented",
    "Equipment placement planned"
  ],
  "aiInstructions": "Generate Xactimate-format estimate. Include demo, dry-out, and rebuild for all affected materials. Add WTR codes for water extraction and equipment. Include CLN codes for cleaning."
}
```

### 3b. System-Provided Templates

ZAFTO ships with built-in templates that companies can use as-is or clone + customize:

| Template | Type | Bid Format | Key Features |
|----------|------|-----------|--------------|
| Water Damage Restoration | Insurance | Xactimate | Moisture readings, category of loss, equipment tracking |
| Fire Damage Restoration | Insurance | Xactimate | Smoke/soot assessment, structural inspection, contents inventory |
| Wind/Storm Damage | Insurance | Xactimate | Roof inspection, exterior photos, temporary repairs |
| Mold Remediation | Insurance | Xactimate | Air sampling locations, containment plan, clearance testing |
| Kitchen Remodel | General | Standard | Cabinet measurements, appliance specs, material selections |
| Bathroom Remodel | General | Standard | Fixture specs, tile layout, plumbing notes |
| Whole House Renovation | General | Standard | All rooms, structural assessment, mechanical systems |
| Electrical Service Upgrade | Trade | Trade-specific | Panel location, service size, circuit inventory, code violations |
| HVAC Replacement | Trade | Trade-specific | Equipment specs, ductwork measurements, load calculation notes |
| Roof Replacement | Trade | Trade-specific | Roof sections, pitch, material, ventilation, flashing |
| Plumbing Repipe | Trade | Trade-specific | Pipe routing, fixture count, access points, material selection |
| Commercial Buildout | Commercial | AIA/standard | Tenant improvement, ADA compliance, fire code, mechanical |
| Pre-Purchase Inspection | Inspection | Report | Condition assessment, deficiency list, repair estimates |
| Move-In/Move-Out | Inspection | Report | Unit condition, damage documentation, comparison photos |

### 3c. Per-Company Customization

Companies can customize:
- **Room presets** — add/remove/rename default rooms
- **Required fields per room** — which data is mandatory before moving to next room
- **Custom fields** — add any data point they need (dropdowns, text, numbers, checkboxes)
- **Checklist items** — completion checklist before walkthrough can be "finished"
- **Photo requirements** — minimum photos per room, required angles (close-up, wide, detail)
- **AI instructions** — custom prompt additions that guide bid generation ("Always include 20% waste factor on materials", "Use premium fixtures in all bids", "Include 3-tier pricing: good/better/best")
- **Bid format** — which output format to use (standard, Xactimate, AIA, custom)
- **Approval workflow** — walkthrough → auto-generate bid → send to office for review → approved → send to customer. Or: walkthrough → bid → auto-send (for trusted techs).
- **Field assignments** — which techs can do walkthroughs, which can only do photos

### 3d. Workflow Storage

```sql
CREATE TABLE walkthrough_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  walkthrough_type TEXT NOT NULL DEFAULT 'general'
    CHECK (walkthrough_type IN ('general','trade_specific','insurance_restoration',
      'inspection','commercial','custom')),
  bid_format TEXT NOT NULL DEFAULT 'standard'
    CHECK (bid_format IN ('standard','xactimate','aia','trade_specific','report','custom')),
  config JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- config contains: defaultRooms, requiredPerRoom, requiredOverall,
  -- customFields, perRoomFields, checklistItems, aiInstructions,
  -- photoRequirements, approvalWorkflow
  is_system BOOLEAN DEFAULT false,
  is_default BOOLEAN DEFAULT false,   -- Company's default template
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped, is_system readable by all
-- Seed with ~14 system templates
```

---

## 4. PROPERTY SKETCH EDITOR + ASSET VIEWER

### Philosophy: Create It, Edit It, View It — One Surface

The sketch tool, the floor plan viewer, and the asset map are the same thing. When a contractor draws a floor plan during a walkthrough, that drawing becomes a living, editable, interactive document. When LiDAR captures dimensions, those dimensions are editable. When assets are pinned, they're draggable. When the plan needs a correction, it's instant.

This isn't a static image. It's structured data rendered as an interactive floor plan.

### 4a. Data Model

The floor plan is stored as structured JSON, not as a bitmap. Every wall, door, window, fixture, and dimension is a data object that can be queried, edited, and rendered.

```sql
CREATE TABLE property_floor_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  property_id UUID REFERENCES properties(id),  -- Link to property management
  walkthrough_id UUID REFERENCES walkthroughs(id),
  job_id UUID REFERENCES jobs(id),
  customer_id UUID REFERENCES customers(id),
  name TEXT NOT NULL DEFAULT 'Floor Plan',
  floor_count INTEGER NOT NULL DEFAULT 1,
  plan_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- plan_data structure: see below
  thumbnail_url TEXT,             -- Pre-rendered PNG for list views
  lidar_source BOOLEAN DEFAULT false,  -- Was this generated from LiDAR?
  version INTEGER NOT NULL DEFAULT 1,
  version_history JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped
```

**plan_data JSON structure:**
```json
{
  "units": "imperial",
  "floors": [
    {
      "level": "1st",
      "name": "First Floor",
      "origin": { "x": 0, "y": 0 },
      "walls": [
        {
          "id": "w1",
          "start": { "x": 0, "y": 0 },
          "end": { "x": 144, "y": 0 },
          "thickness": 4.5,
          "height": 96,
          "type": "exterior",
          "loadBearing": true,
          "material": "wood_frame"
        }
      ],
      "rooms": [
        {
          "id": "r1",
          "name": "Kitchen",
          "wallIds": ["w1", "w2", "w3", "w4"],
          "area": 180,
          "perimeter": 54,
          "ceilingHeight": 96,
          "floorMaterial": "tile",
          "wallMaterial": "drywall",
          "photos": ["kitchen-01.jpg", "kitchen-02.jpg"],
          "notes": "Water damage on north wall, baseboards swollen",
          "tags": ["damage", "demo", "replace"],
          "customFields": {
            "moisture_level": 45,
            "material_affected": ["Drywall", "Baseboard", "Flooring"]
          }
        }
      ],
      "openings": [
        {
          "id": "o1",
          "wallId": "w1",
          "type": "door",
          "subtype": "interior_single",
          "width": 36,
          "height": 80,
          "position": 48,
          "swing": "left_in"
        },
        {
          "id": "o2",
          "wallId": "w2",
          "type": "window",
          "subtype": "double_hung",
          "width": 36,
          "height": 48,
          "position": 36,
          "sillHeight": 36
        }
      ],
      "fixtures": [
        {
          "id": "f1",
          "type": "sink",
          "subtype": "kitchen_double",
          "roomId": "r1",
          "position": { "x": 72, "y": 4 },
          "rotation": 0,
          "width": 33,
          "depth": 22
        }
      ],
      "assets": [
        {
          "id": "a1",
          "type": "electrical_panel",
          "label": "Main Panel - 200A",
          "roomId": "r3",
          "position": { "x": 12, "y": 48 },
          "assetRecordId": "uuid-to-property-assets-table",
          "details": {
            "brand": "Square D",
            "model": "QO140M200P",
            "amperage": 200,
            "installDate": "2018-06-15"
          }
        }
      ],
      "dimensions": [
        {
          "id": "d1",
          "start": { "x": 0, "y": 0 },
          "end": { "x": 144, "y": 0 },
          "value": 144,
          "displayValue": "12'-0\"",
          "source": "lidar",
          "manualOverride": false
        }
      ],
      "annotations": [
        {
          "id": "an1",
          "type": "text",
          "position": { "x": 72, "y": 48 },
          "text": "Water stain - 4x6 ft",
          "color": "#FF4444",
          "fontSize": 12
        },
        {
          "id": "an2",
          "type": "area_highlight",
          "points": [{"x":60,"y":30},{"x":108,"y":30},{"x":108,"y":78},{"x":60,"y":78}],
          "color": "#FF444440",
          "label": "Affected area"
        }
      ]
    }
  ]
}
```

### 4b. Sketch Editor (Flutter — CustomPainter)

**Implementation:** Flutter `CustomPainter` with gesture detection for drawing, editing, and navigation.

**Editor tools (toolbar):**

| Tool | Function | Gesture |
|------|----------|---------|
| **Select** | Select/move/resize elements | Tap to select, drag to move, handles to resize |
| **Wall** | Draw walls | Tap start + tap end, auto-snap to grid/angles |
| **Room** | Create enclosed room | Tap 4+ corners or auto-detect from walls |
| **Door** | Place door on wall | Tap wall → door appears, drag to position |
| **Window** | Place window on wall | Tap wall → window appears, drag to position |
| **Fixture** | Place fixture from library | Select from palette → tap to place |
| **Asset** | Pin equipment/asset | Select type → tap location → enter details |
| **Dimension** | Add/edit dimension line | Tap two points → dimension appears |
| **Annotate** | Text label or area highlight | Tap for text, draw polygon for area |
| **Measure** | Quick measurement between any two points | Tap + tap → distance shown |
| **Eraser** | Delete elements | Tap to remove |
| **Pan** | Navigate the canvas | Two-finger drag |
| **Zoom** | Scale the view | Pinch |

**Smart features:**
- **Wall snapping** — walls snap to 90-degree angles, to other wall endpoints, and to grid
- **LiDAR auto-populate** — if room was LiDAR-scanned, walls and dimensions pre-drawn (editable)
- **Dimension editing** — tap any dimension label → type new value → walls adjust to match
- **Room auto-detection** — enclosed walls automatically create a room
- **Area calculation** — room square footage calculated live as walls are drawn/edited
- **Material estimation** — change a room's floor material → instant SF calculation for that material
- **Multi-floor** — tab between floors, stairs link floors visually
- **Undo/redo** — full history stack, swipe gestures or buttons

**Editing existing plans:**
- Any element can be selected, moved, resized, or deleted at any time
- Dimensions are always editable — override LiDAR measurements when needed
- Version history — every save creates a version, can revert to any previous state
- "Show LiDAR overlay" toggle — see original scan dimensions vs current plan

### 4c. 2D Floor Plan Renderer (All Apps)

The same floor plan data renders across all ZAFTO apps:

| App | Capability | Technology |
|-----|-----------|-----------|
| **Flutter (mobile)** | Full editor + viewer | CustomPainter + gesture detection |
| **Web CRM** | Viewer + light editing (move assets, add annotations) | Canvas API / SVG |
| **Client Portal** | Read-only viewer (see their property) | Canvas API / SVG (simplified) |
| **Team Portal** | Viewer + mark progress (color rooms by completion) | Canvas API / SVG |

**Rendering features (all platforms):**
- Zoom + pan navigation
- Room labels with dimensions
- Color-coding by status: not started (gray), in progress (blue), complete (green), damaged (red)
- Tap room → expand detail panel (photos, notes, measurements, assets)
- Asset pins with icons (tap for detail)
- Photo pins (tap to view photo taken at that spot)
- Annotation overlay toggle
- Print-friendly view (clean black-and-white for documents)
- Export as PNG/PDF

### 4d. 3D Property Viewer (Phase 2)

**LiDAR 3D scan data** from iOS ARKit can be rendered as an interactive 3D model.

**Implementation options:**
- **Flutter:** `arkit_plugin` for iOS ARKit integration during capture; `flutter_gl` or `three_dart` for 3D rendering of stored meshes
- **Web:** Three.js for browser-based 3D rendering of exported mesh/point cloud data

**3D capabilities:**
- Orbit, zoom, pan the 3D model
- Tap surfaces → see room info, photos, measurements
- Pin assets to 3D locations
- Overlay damage areas in 3D space
- Toggle between wireframe, solid, and textured views
- Measurement tool: tap two points in 3D space → distance
- Cross-section view: slice the model to see wall interiors

**3D editing:**
- Adjust wall positions by dragging in 3D space
- Correct ceiling heights
- Move fixture positions
- Re-scan individual rooms to update the 3D model

**Data flow:**
```
LiDAR scan (on device) → ARKit mesh data → compressed + stored locally
  → upload to Supabase Storage (mesh file)
  → 3D renderer loads mesh for viewing
  → edits save back to structured plan_data JSON
  → 2D floor plan auto-updates from 3D changes (and vice versa)
```

**Important:** 2D and 3D are synced. Edit a wall dimension in 2D → 3D model updates. Move a wall in 3D → 2D plan updates. They're two views of the same data.

### 4e. Asset Map (Living Document)

The floor plan becomes a permanent asset map for the property's lifetime:

- Every piece of equipment plotted on the plan
- Tap an asset → see full history: install date, warranty, brand, model, last service, next service due
- Links to `property_assets` table (Property Management D5)
- Links to `asset_service_records` for maintenance history
- Color-coding: green (good), yellow (service due), red (warranty expired / needs replacement)
- Filter by asset type: show only electrical, only HVAC, only plumbing
- For property managers: see all units in a building, each with their own asset map

**Asset lifecycle on the plan:**
1. **Installation:** Contractor installs new equipment → pins it on the floor plan with specs
2. **Service:** Contractor services equipment → updates service record, asset stays on plan
3. **Replacement:** Old asset grayed out, new asset pinned in same spot with updated specs
4. **History:** Tap any spot → see timeline of what was there and when

---

## 5. PHOTO SYSTEM

### 5a. Smart Photo Capture

Not just a camera — an intelligent documentation system.

**During walkthrough capture:**
- **Auto-numbering:** Kitchen-01, Kitchen-02, Kitchen-03...
- **EXIF embedding:** GPS, compass heading, timestamp, room name, floor level
- **Blur detection:** warns if photo is blurry, prompts re-take
- **Lighting detection:** warns if too dark, suggests flash
- **Duplicate detection:** warns if photo looks very similar to previous (accidental double-tap)
- **Coverage tracking:** "You've taken 3 photos of the kitchen. Recommended: at least 4 angles (N, S, E, W)"

### 5b. Photo Annotations

In-app annotation editor (during or after walkthrough):

**Tools:**
- **Draw** — freehand drawing (finger or stylus) in multiple colors/thicknesses
- **Arrow** — directional pointer to specific areas
- **Circle/Rectangle** — highlight regions
- **Text** — typed callouts positioned on the photo
- **Measurement** — draw a line → enter real-world dimension (e.g., "4'-6\"")
- **Stamp** — quick stamps: damage, repair, replace, new, code violation, approved

**Technical:**
- Annotations stored as structured data overlaid on original photo (original never modified)
- Render annotated version as separate PNG for sharing/printing
- Toggle annotations on/off when viewing
- Multiple annotation layers (e.g., "damage assessment" layer vs "scope of work" layer)

### 5c. Before/After

Link photos taken at different times for the same spot:
- Pin "before" photo to a room location
- Later, pin "after" photo to the same location
- Side-by-side comparison view
- Slider comparison (drag divider left/right)
- Auto-match by GPS + compass heading when possible
- Include in bid/report output as comparison strips

### 5d. Photo Organization in CRM

When photos upload to the CRM, they're automatically organized:

**Storage structure:** (see Section 2e)

**Web CRM display:**
- Gallery view per room (grid of thumbnails)
- Map view (photos plotted on floor plan at capture location)
- Timeline view (photos in capture order)
- Filter by: room, tag, date, annotation status
- Bulk operations: download all, share set, attach to document

**Client Portal display:**
- Curated photo sets (contractor selects which photos the client sees)
- Before/after comparisons
- Progress photos by date
- No raw damage photos unless explicitly shared (privacy-conscious)

---

## 6. AI BID GENERATION (Z Intelligence)

### 6a. The Generation Pipeline

After a walkthrough uploads, Z Intelligence processes everything:

```
1. ANALYZE PHOTOS
   - Claude Vision examines every photo
   - Identifies: materials, conditions, damage type/severity, equipment, fixtures
   - Extracts: dimensions from measurement annotations, material types, quantities

2. ANALYZE LIDAR DATA
   - Room dimensions → square footage calculations
   - Opening dimensions → door/window specs
   - Ceiling heights → volume calculations (for HVAC, painting)

3. ANALYZE VOICE NOTES
   - Transcribe audio → text
   - Extract: scope items, customer preferences, special conditions, access notes

4. ANALYZE TEXT NOTES + TAGS
   - Condition tags → scope items (damage → demo + replace)
   - Material tags → material specifications
   - Custom fields → specialized data (moisture readings → drying scope)

5. READ FLOOR PLAN
   - Room count, layout, total SF
   - Asset locations → equipment specs
   - Access paths → staging considerations

6. READ WORKFLOW TEMPLATE
   - Bid format (standard, Xactimate, AIA, trade-specific)
   - Custom AI instructions from company settings
   - Required sections and formatting

7. GENERATE BID
   - Select line items from code database (Xactimate codes for insurance, standard for general)
   - Apply regional pricing from ZAFTO pricing database
   - Calculate quantities from dimensions
   - Apply company markups (O&P, waste factor, difficulty adjustments)
   - Format per bid type
   - Generate professional PDF

8. REVIEW + DELIVER
   - Push notification: "Bid ready for review"
   - Bid appears in both mobile app and Web CRM
   - Contractor reviews, edits, approves, sends
```

### 6b. Supported Bid Formats

**Standard Contracting Bid:**
```
ZAFTO
[Company Name] [Logo]

BID PROPOSAL

Customer: [Name]                    Date: [Date]
Property: [Address]                 Bid #: [BID-2026-XXXX]

SCOPE OF WORK
[Detailed description of work to be performed, room by room]

LINE ITEMS
| Item | Description | Qty | Unit | Unit Price | Total |
|------|------------|-----|------|-----------|-------|
| 1    | Demo existing kitchen cabinets | 1 | LS | $850.00 | $850.00 |
| 2    | Install new shaker cabinets | 14 | LF | $325.00 | $4,550.00 |
| ...  | ... | ... | ... | ... | ... |

SUBTOTAL: $XX,XXX.XX
TAX: $X,XXX.XX
TOTAL: $XX,XXX.XX

PAYMENT TERMS: [Company default or custom]
WARRANTY: [Company default or custom]
TIMELINE: [Estimated based on scope]

[Signature lines]
```

**Good/Better/Best (3-Tier) Bid:**
```
Option A — Essential (Good)
[Minimum scope, builder-grade materials]
Total: $XX,XXX

Option B — Premium (Better) *** RECOMMENDED ***
[Full scope, mid-grade materials, additional features]
Total: $XX,XXX

Option C — Luxury (Best)
[Full scope, premium materials, all upgrades]
Total: $XX,XXX
```

**Insurance / Xactimate Format:**
(See `25_XACTIMATE_ESTIMATE_ENGINE.md` for full detail)
- Xactimate line item codes (category + selector)
- MAT/LAB/EQU breakdown
- Coverage groups (structural/contents/other)
- Depreciation rates
- ACV/RCV calculations
- O&P markup
- Room-by-room grouping

**AIA Format (Commercial):**
```
AIA Document G702 — Application and Certificate for Payment
AIA Document G703 — Continuation Sheet

Schedule of Values with:
- CSI division codes
- Original contract sum
- Change orders
- Completed to date
- Stored materials
- Retainage
- Balance to finish
```

**Trade-Specific Formats:**
Each trade has expected bid sections:

| Trade | Specific Sections |
|-------|------------------|
| Electrical | Panel schedule, circuit inventory, wire sizing, permit requirements |
| Plumbing | Fixture schedule, pipe sizing, DWV layout, water heater specs |
| HVAC | Load calculation summary, equipment specs, ductwork sizing, zoning |
| Roofing | Roof sections by slope/material, ventilation calculation, flashing detail |
| Painting | Surface prep scope, coating spec (primer + coats), SF breakdown by surface type |

**Inspection Report Format:**
```
PROPERTY INSPECTION REPORT

Property: [Address]
Date: [Date]
Inspector: [Name]

SUMMARY
Overall Condition: [Good/Fair/Poor]
Critical Items: [Count]
Recommended Repairs: [Count]
Estimated Repair Cost: $XX,XXX

[Room-by-room findings with photos, ratings, repair recommendations]
```

### 6c. Bid Accuracy

**"Dead accurate on bid formats"** means:

- **Insurance bids** match Xactimate output line-for-line. Same codes, same format, same groupings. An adjuster can compare it directly.
- **AIA bids** follow G702/G703 format exactly. A GC or architect accepts it without question.
- **Standard bids** are professional enough for any residential customer. Clean layout, clear pricing, proper terms.
- **Trade bids** include the technical sections that trade-specific customers expect. An electrical inspector sees a proper panel schedule. A plumbing inspector sees a proper fixture schedule.

**How we achieve this:**
- Template library with pixel-perfect format definitions per bid type
- AI instructions specific to each format ("Include CSI codes", "Break out MAT/LAB/EQU", "Show depreciation schedule")
- Contractor review before send — AI generates, human approves
- Feedback loop: contractor edits → AI learns their preferences over time

---

## 7. DATA ARCHITECTURE

### New Tables

**`walkthroughs`** — Master record for each walkthrough session
```sql
CREATE TABLE walkthroughs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  created_by UUID NOT NULL REFERENCES auth.users(id),
  -- Links
  customer_id UUID REFERENCES customers(id),
  job_id UUID REFERENCES jobs(id),
  bid_id UUID REFERENCES bids(id),        -- Generated bid
  property_id UUID REFERENCES properties(id),
  floor_plan_id UUID REFERENCES property_floor_plans(id),
  -- Config
  name TEXT NOT NULL,
  walkthrough_type TEXT NOT NULL DEFAULT 'general',
  template_id UUID REFERENCES walkthrough_templates(id),
  address TEXT,
  address_lat NUMERIC(10,7),
  address_lng NUMERIC(10,7),
  property_type TEXT DEFAULT 'residential'
    CHECK (property_type IN ('residential','commercial','industrial','multi_family')),
  -- Status
  status TEXT NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('in_progress','uploading','processing','bid_ready',
      'bid_reviewed','bid_sent','completed','cancelled')),
  -- Storage
  storage_path TEXT,                      -- Base path in Supabase Storage
  total_photos INTEGER DEFAULT 0,
  total_rooms INTEGER DEFAULT 0,
  total_file_size_bytes BIGINT DEFAULT 0,
  -- AI
  ai_bid_status TEXT DEFAULT 'pending'
    CHECK (ai_bid_status IN ('pending','generating','complete','failed','skipped')),
  ai_bid_thread_id UUID,                  -- Z Intelligence thread
  -- Timestamps
  started_at TIMESTAMPTZ DEFAULT now(),
  finished_at TIMESTAMPTZ,               -- When contractor tapped "Finish"
  uploaded_at TIMESTAMPTZ,               -- When all files finished uploading
  bid_generated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS: company-scoped
CREATE INDEX idx_walkthroughs_company ON walkthroughs(company_id) WHERE status != 'cancelled';
CREATE INDEX idx_walkthroughs_customer ON walkthroughs(customer_id);
CREATE INDEX idx_walkthroughs_job ON walkthroughs(job_id);
```

**`walkthrough_rooms`** — Per-room data captured during walkthrough
```sql
CREATE TABLE walkthrough_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  walkthrough_id UUID NOT NULL REFERENCES walkthroughs(id) ON DELETE CASCADE,
  -- Room info
  name TEXT NOT NULL,
  floor_level TEXT DEFAULT '1st',
  room_order INTEGER NOT NULL DEFAULT 0,  -- Display/capture order
  -- Dimensions (from LiDAR or manual)
  length_inches NUMERIC(8,1),
  width_inches NUMERIC(8,1),
  height_inches NUMERIC(8,1) DEFAULT 96,
  area_sf NUMERIC(10,2),                  -- Calculated or overridden
  perimeter_lf NUMERIC(10,2),
  dimension_source TEXT DEFAULT 'manual'
    CHECK (dimension_source IN ('lidar','manual','estimated')),
  -- Content
  photo_count INTEGER DEFAULT 0,
  voice_note_count INTEGER DEFAULT 0,
  condition_tags TEXT[] DEFAULT '{}',      -- {'damage','replace','demo'}
  material_tags TEXT[] DEFAULT '{}',       -- {'drywall','hardwood','tile'}
  notes TEXT,
  custom_fields JSONB DEFAULT '{}'::jsonb, -- Workflow-defined fields
  -- LiDAR
  lidar_scan_path TEXT,                   -- Storage path to raw scan data
  lidar_confidence NUMERIC(3,2),          -- 0.00-1.00 scan quality
  -- Checklist
  checklist_items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);
-- No separate RLS needed — accessed via walkthrough join
CREATE INDEX idx_walkthrough_rooms ON walkthrough_rooms(walkthrough_id);
```

**`walkthrough_photos`** — Individual photos with metadata
```sql
CREATE TABLE walkthrough_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  walkthrough_id UUID NOT NULL REFERENCES walkthroughs(id) ON DELETE CASCADE,
  room_id UUID REFERENCES walkthrough_rooms(id),
  -- File
  storage_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INTEGER,
  -- Metadata
  capture_order INTEGER NOT NULL DEFAULT 0,
  photo_type TEXT DEFAULT 'standard'
    CHECK (photo_type IN ('standard','wide','detail','before','after',
      'exterior','roof','damage','equipment','selfie_proof')),
  -- EXIF
  gps_lat NUMERIC(10,7),
  gps_lng NUMERIC(10,7),
  compass_heading NUMERIC(5,1),
  captured_at TIMESTAMPTZ DEFAULT now(),
  -- Annotations
  has_annotations BOOLEAN DEFAULT false,
  annotations_data JSONB DEFAULT '[]'::jsonb,
  annotated_path TEXT,                    -- Storage path to annotated version
  -- AI analysis
  ai_analysis JSONB,                      -- Claude Vision output
  ai_analyzed_at TIMESTAMPTZ,
  -- Before/After linking
  linked_photo_id UUID REFERENCES walkthrough_photos(id),
  link_type TEXT CHECK (link_type IN ('before_after','comparison','detail_of')),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_walkthrough_photos ON walkthrough_photos(walkthrough_id);
CREATE INDEX idx_walkthrough_photos_room ON walkthrough_photos(room_id);
```

**`property_floor_plans`** — see Section 4a above

**`walkthrough_templates`** — see Section 3d above

### Summary of New Tables

| Table | Purpose |
|-------|---------|
| `walkthroughs` | Master walkthrough record |
| `walkthrough_rooms` | Per-room data |
| `walkthrough_photos` | Individual photos + annotations + AI analysis |
| `property_floor_plans` | Structured floor plan data (sketch editor) |
| `walkthrough_templates` | Customizable workflow configs |

**Total: 5 new tables + ALTERs to link existing tables**

### ALTER to Existing Tables

```sql
-- Link bids to walkthroughs
ALTER TABLE bids ADD COLUMN walkthrough_id UUID REFERENCES walkthroughs(id);

-- Link jobs to walkthroughs
ALTER TABLE jobs ADD COLUMN walkthrough_id UUID REFERENCES walkthroughs(id);

-- Link property_assets to floor plan positions
ALTER TABLE property_assets ADD COLUMN floor_plan_position JSONB;
-- { "floorPlanId": "uuid", "x": 72, "y": 48 }
```

---

## 8. FLUTTER APP MODERNIZATION NOTES

### Current State
The Flutter app (see screenshot) has the original design from early build sessions:
- Dark theme with orange accent
- "ZAFTO TRADES" branding with red Z card
- Toolbox section (calculators, code reference, exam prep, tables & data) — **all scrapped, replaced by Z Intelligence**
- Bottom nav: Home, Tools, Jobs, Invoices, More
- Static content that no longer applies

### What Needs to Change
The app shell needs to evolve to match the premium, modern feel of the Web CRM and portals. However, this is a **separate sprint** — not part of the Bid Walkthrough Engine spec. The walkthrough feature works within whatever app shell exists.

**Key items for a Flutter modernization sprint (future):**
- Remove dead Toolbox section (calculators, code reference, exam prep)
- Replace with Z Intelligence entry point (conversational AI replaces static tools)
- Update navigation structure to reflect actual feature set
- Ensure role-based navigation (Owner sees everything, Tech sees field tools)
- Design system alignment with web apps
- Walkthrough as a primary action (prominent "New Walkthrough" button)
- The app feel should be **cutting edge** — smooth animations, haptic feedback, gesture-driven, fast

**Note:** The walkthrough feature should be designed to work in BOTH the current app shell AND a future modernized shell. It's a full-screen experience once entered, so the surrounding app chrome doesn't matter during active use.

---

## 9. CROSS-APP INTEGRATION

### How Each App Uses Walkthrough Data

| App | Role | Capabilities |
|-----|------|-------------|
| **Flutter (mobile)** | Creator | Full walkthrough capture, sketch editor, photo annotation, offline support, bid review/send |
| **Web CRM** | Manager | View all walkthroughs, review/edit bids, manage templates, view floor plans, organize photos, re-generate bids, send to customers |
| **Client Portal** | Viewer | See their property's floor plan, view shared photos, review bid, approve/reject, request changes |
| **Team Portal** | Field worker | View assigned walkthrough data, see scope per room, mark rooms complete, update photos |

### Workflow: Field to Office to Customer

```
FIELD (Flutter)                    OFFICE (Web CRM)                  CUSTOMER (Client Portal)

1. Contractor starts
   walkthrough on site

2. Room-by-room capture:
   photos, LiDAR, notes,
   sketches, voice notes

3. Taps "Finish" → uploads
                                   4. Office gets notification:
                                      "New walkthrough uploaded"

                                   5. Z Intelligence generates bid

                                   6. Office reviews bid in CRM:
                                      - View floor plan
                                      - Check photos per room
                                      - Review/edit line items
                                      - Adjust pricing if needed

                                   7. Approves bid → sends to customer

                                                                     8. Customer receives bid
                                                                        via email + portal link

                                                                     9. Customer views:
                                                                        - Floor plan of their property
                                                                        - Scope by room (optional)
                                                                        - Total pricing
                                                                        - Payment terms

                                                                     10. Customer approves/
                                                                         requests changes

                                   11. If changes: edit bid, re-send

12. Contractor gets notification:
    "Bid approved — job created"
```

---

## 10. BUILD PHASES

### Prerequisites

| Prerequisite | Status | Notes |
|-------------|--------|-------|
| Phase E1 (AI infra) | NOT STARTED | Z Intelligence architecture for bid generation |
| E5 (Xactimate Engine) | NOT STARTED | For insurance bid format + pricing DB |
| D5 (Property Mgmt) | IN PROGRESS | Floor plan links to properties table |
| LiDAR package evaluation | NOT STARTED | Evaluate `arkit_plugin`, `ar_flutter_plugin`, etc. |
| Flutter app modernization | NOT STARTED | Separate sprint, but walkthrough works regardless |

### Phase E6a: Walkthrough Data Model + Templates (~6 hrs)
- [ ] Deploy `walkthroughs` table + RLS
- [ ] Deploy `walkthrough_rooms` table
- [ ] Deploy `walkthrough_photos` table
- [ ] Deploy `walkthrough_templates` table + seed ~14 system templates
- [ ] Deploy `property_floor_plans` table
- [ ] ALTER bids, jobs, property_assets (add walkthrough/floor plan links)
- [ ] Commit: `[E6a] Walkthrough engine — data model + templates`

### Phase E6b: Flutter Walkthrough Capture Flow (~16 hrs)
- [ ] Walkthrough start screen (name, customer link, type, template selection)
- [ ] Room capture screen (photo, notes, tags, custom fields per template)
- [ ] Multi-photo per room with auto-numbering
- [ ] Voice note recording per room (reuse existing `record` package pattern)
- [ ] Room list with progress indicators
- [ ] Exterior capture flow (roof, siding, windows, landscaping)
- [ ] Walkthrough finish screen (summary, upload trigger)
- [ ] Offline persistence (PowerSync + local file storage)
- [ ] Background upload with progress tracking
- [ ] Model + Repository + Service layer (walkthrough, room, photo)
- [ ] Commit: `[E6b] Flutter walkthrough capture flow`

### Phase E6c: Photo Annotation System (~8 hrs)
- [ ] Annotation editor (CustomPainter overlay on photo)
- [ ] Tools: draw, arrow, circle, rectangle, text, measurement, stamp
- [ ] Color/thickness selection
- [ ] Save annotations as JSON overlay (original photo untouched)
- [ ] Render annotated version as PNG for export
- [ ] Before/after photo linking + comparison view
- [ ] Commit: `[E6c] Photo annotation system`

### Phase E6d: Sketch Editor + Floor Plan Engine (~16 hrs)
- [ ] Floor plan canvas (CustomPainter + GestureDetector)
- [ ] Wall drawing tool with angle snapping
- [ ] Door/window/fixture placement from symbol library
- [ ] Room auto-detection from enclosed walls
- [ ] Dimension labels (auto-calculated, manually editable)
- [ ] Asset pins (link to property_assets table)
- [ ] Annotation overlay (text, area highlights)
- [ ] Multi-floor support (tabs)
- [ ] Undo/redo stack
- [ ] Save as structured JSON (not bitmap)
- [ ] Export as PNG/PDF
- [ ] Commit: `[E6d] Sketch editor + floor plan engine`

### Phase E6e: LiDAR Integration (~10 hrs)
- [ ] Evaluate and integrate ARKit plugin for iOS
- [ ] Room dimension capture from LiDAR scan
- [ ] Auto-populate sketch from LiDAR data
- [ ] Dimension editing (override LiDAR with manual values)
- [ ] LiDAR data storage (compressed mesh/point cloud)
- [ ] Fallback to manual dimension entry on non-LiDAR devices
- [ ] LiDAR confidence indicator
- [ ] Commit: `[E6e] LiDAR integration — room scanning + auto-sketch`

### Phase E6f: 2D Floor Plan Viewer — All Apps (~8 hrs)
- [ ] Web CRM: Canvas/SVG floor plan renderer
- [ ] Web CRM: Interactive room selection (tap → detail panel)
- [ ] Web CRM: Asset pins with detail popups
- [ ] Web CRM: Photo pins (tap → view photo at that location)
- [ ] Web CRM: Color-coding by status (not started / in progress / complete / damaged)
- [ ] Client Portal: Simplified read-only viewer
- [ ] Team Portal: Viewer with progress marking
- [ ] Print-friendly export (clean black-and-white)
- [ ] Commit: `[E6f] 2D floor plan viewer — all apps`

### Phase E6g: AI Bid Generation Pipeline (~10 hrs)
- [ ] Edge Function: process walkthrough → analyze photos (Claude Vision)
- [ ] Edge Function: analyze voice notes (transcription + extraction)
- [ ] Edge Function: combine all data → generate bid per format
- [ ] Standard bid template + generation
- [ ] 3-tier (good/better/best) bid template + generation
- [ ] Insurance/Xactimate bid template (depends on E5)
- [ ] Trade-specific bid templates (electrical, plumbing, HVAC, roofing)
- [ ] AIA format template (commercial)
- [ ] Inspection report template
- [ ] Bid review screen (Flutter + Web CRM)
- [ ] Bid edit capabilities (line items, pricing, descriptions)
- [ ] Bid send (email + client portal)
- [ ] Commit: `[E6g] AI bid generation pipeline — all formats`

### Phase E6h: Workflow Customization UI (~6 hrs)
- [ ] Web CRM: Settings > Walkthrough Workflows page
- [ ] Template editor: room presets, required fields, custom fields
- [ ] Per-room field configuration (custom data points)
- [ ] Checklist builder
- [ ] AI instruction customization
- [ ] Photo requirement settings
- [ ] Approval workflow configuration
- [ ] Clone system template → customize
- [ ] Commit: `[E6h] Walkthrough workflow customization`

### Phase E6i: 3D Property Viewer (~12 hrs) — PHASE 2
- [ ] LiDAR mesh capture + storage
- [ ] 3D renderer (Flutter: flutter_gl/three_dart, Web: Three.js)
- [ ] Orbit/zoom/pan controls
- [ ] Tap surfaces → room info + photos
- [ ] Asset pins in 3D space
- [ ] Measurement tool in 3D
- [ ] 2D ↔ 3D sync (edits in either view update both)
- [ ] Cross-section view
- [ ] Commit: `[E6i] 3D property viewer + editor`

### Phase E6j: Testing + Verification (~4 hrs)
- [ ] Walkthrough creation → room capture → photo upload → bid generation end-to-end
- [ ] Offline walkthrough → reconnect → upload completes
- [ ] Floor plan create → edit → view across all apps
- [ ] Template customization → applied in walkthrough
- [ ] All 5 apps build clean
- [ ] Commit: `[E6j] Bid walkthrough engine — testing complete`

**Total estimated: ~96 hours across 10 sub-steps**
**New tables: 5 (walkthroughs, walkthrough_rooms, walkthrough_photos, property_floor_plans, walkthrough_templates) + 3 ALTERs**

---

## 11. COMPETITIVE LANDSCAPE

### What Exists Today

| Product | What It Does | Price | Limitation |
|---------|-------------|-------|-----------|
| **CompanyCam** | Photo documentation | $19-29/user/mo | Photos only. No bids, no dimensions, no sketches. |
| **magicplan** | LiDAR floor plans + estimates | $10-40/mo | Floor plans + basic estimates. No full bid. No CRM. |
| **Hover** | 3D property model from photos | Enterprise pricing | Exterior only. No interior. Verisk partnership. |
| **Encircle** | Field documentation for restoration | Per-project | Insurance-focused. No bid generation. |
| **Matterport** | 3D property scans | $10-70/mo | Requires special camera or iPhone Pro. View-only. |
| **iScope** | Insurance estimating app | Free + $40 DB | Estimates only. No photos, no floor plans, no CRM. |
| **Xactimate** | Insurance estimates | $250-315/mo | Estimates only. Dated UX. No field capture flow. |

### What ZAFTO Does That Nobody Else Does

**All of the above, in one flow, for zero additional cost:**
- Photo capture with annotations (CompanyCam)
- LiDAR floor plans with editing (magicplan + Matterport)
- Property 3D scans (Matterport + Hover)
- Insurance estimates (Xactimate + iScope)
- Standard bids in every format (no competitor does this)
- AI that writes the bid from photos + dimensions (nobody does this)
- Customizable workflows per company (nobody does this)
- Everything flows to CRM + client portal + team portal automatically (nobody does this)

**The "nobody else does this" list is the moat.**

---

## APPENDIX A: LiDAR Device Support

| Device | LiDAR | Capability |
|--------|-------|-----------|
| iPhone 12 Pro / Pro Max | Yes | Room scanning, mesh capture |
| iPhone 13 Pro / Pro Max | Yes | Improved accuracy |
| iPhone 14 Pro / Pro Max | Yes | Further improved |
| iPhone 15 Pro / Pro Max | Yes | Best accuracy |
| iPhone 16 Pro / Pro Max | Yes | Current generation |
| iPad Pro (2020+) | Yes | Larger screen for sketching |
| All other iPhones/iPads | No | Manual dimension entry fallback |
| Android (future) | Varies | ToF sensors on some flagships |

**Minimum viable:** Manual dimension entry works on ALL devices. LiDAR is a premium enhancement, not a requirement.

---

## APPENDIX B: Symbol Library (Sketch Editor)

### General
Wall (exterior, interior, load-bearing), Door (single, double, sliding, pocket, bi-fold, garage), Window (single hung, double hung, casement, sliding, fixed, bay), Stairs (straight, L-shaped, U-shaped, spiral), Counter, Island, Cabinet (base, upper, tall), Closet, Shelf

### Electrical
Outlet (standard, GFCI, 240V, floor), Switch (single, 3-way, 4-way, dimmer), Panel (main, sub), Junction box, Light (recessed, surface, pendant, chandelier, sconce, under-cabinet), Fan (ceiling, exhaust), Smoke detector, CO detector, Doorbell, Thermostat, EV charger

### Plumbing
Sink (kitchen, bath, utility), Toilet, Bathtub, Shower, Water heater (tank, tankless), Washing machine, Dishwasher, Hose bib, Cleanout, Sump pump, Water softener, Water main shutoff, Gas shutoff

### HVAC
Furnace, Air handler, Condenser (outdoor), Supply vent, Return vent, Thermostat, Ductwork (supply, return), Mini-split (indoor, outdoor), Boiler, Radiator, Baseboard heater

### Fire/Safety
Sprinkler head, Pull station, Fire extinguisher, Exit sign, Emergency light, Fire damper, Smoke detector, CO detector

---

**END OF SPEC**

**Next action:** Return to D5h (Team Portal — Property Maintenance View) in build sequence.
**Walkthrough engine builds during:** Phase E6, after E1-E5 infrastructure.
**LiDAR requires:** iOS ARKit plugin evaluation + iPhone Pro device for testing.
**Flutter modernization:** Separate sprint, spec TBD, not blocking walkthrough feature.
