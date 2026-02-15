# ZAFTO Plan Review — Full Feature Spec

**Created:** Session 97 | February 2026
**Phase:** E (AI Layer) — builds after T + P + SK + U + G
**Sprints:** BA1–BA8 (~128 hours)
**Research:** 3 deep research agents — 12 competitors analyzed, 25+ forum/review sources, full CV/AI technical architecture

---

## 1. What It Is

**Plan Review** is ZAFTO's AI-powered plan reading and automated takeoff engine. Upload a blueprint PDF (or photograph plans at a job site), and it:

1. **Reads** — identifies rooms, walls, doors, windows, fixtures, and trade symbols
2. **Measures** — calculates areas (SF), linear footage (LF), counts (EA) for every element
3. **Maps to trades** — understands what an outlet is, what a toilet is, what a supply duct is
4. **Generates estimates** — feeds measurements directly into D8 Estimates with CSI-coded line items
5. **Creates floor plans** — outputs a FloorPlanDataV2 for the Sketch Engine (SK)
6. **Orders materials** — generates purchase orders with live supplier pricing (Unwrangle/HD Pro Xtra)
7. **Compares revisions** — highlights every change between drawing versions automatically

All inside ZAFTO. No separate software. No re-entering data. No $2,000/year standalone tool.

---

## 2. Why It Matters

### The $31 Billion Problem
- 52% of construction rework comes from missed drawing revisions
- US contractors waste $31B/year on rework from version confusion
- Estimators spend 50%+ of bid cycle on manual takeoff — nights, weekends, unpaid
- 88% of manual takeoff spreadsheets contain formula errors → 16% average budget overruns

### What Contractors Pay Today
| Tool | Annual Cost | What It Does |
|------|-----------|--------------|
| PlanSwift | $2,000/yr | Now cloud+AI in 2026 (previously desktop-only). Still crashes. Per-seat. |
| STACK | $1,899-5,499/yr | Cloud takeoff. Auto-count misses 15-20% of devices. |
| Bluebeam | $240-400/yr | PDF markup with basic measurement. 58% cite learning curve. |
| Bluebeam Max | $TBD (2026) | New AI tier launching early 2026 with Anthropic Claude integration. |
| On-Screen Takeoff | $995/yr | Desktop dinosaur. "Clunky, non-intuitive, terrible UI." |
| Togal.AI | $2,700-3,588/yr | AI takeoff. "Highly-priced basic area measurement tool." |
| Xactimate | $315-500/yr | Insurance-required. Monopoly. 3.5/5 ease of use. |
| **Total typical stack** | **$3,000-5,000/yr** | **3-4 separate tools that don't talk to each other** |

### What Contractors Hate (From Forums, Reddit, Reviews)
1. **Crashes and data loss** — PlanSwift corrupts files, OST databases crash, Bluebeam freezes on large PDFs
2. **Subscription fatigue** — $85/user/month average, per-seat licensing kills small shops
3. **The scaling problem** — PDFs "scaled to fit" destroy measurement accuracy (2.8% errors)
4. **Revision tracking failures** — miss one detail in a 200-page set → catastrophic
5. **Auto-count inaccuracy** — STACK misses 15-20%, OST ~80% accurate, Togal doesn't understand trade logic
6. **Learning curve** — 58% of Bluebeam negative reviews cite this. Many try and go back to paper.
7. **No integration** — takeoff → estimating → accounting → PM all manual re-entry
8. **Not trade-specific** — generic tools don't understand circuits, DFUs, duct sizing, or damage categories

### What No One Does
| Gap | Status |
|-----|--------|
| Multi-trade takeoff integrated into full contractor platform | **Nobody** |
| Mobile-first takeoff (not desktop afterthought) | **Nobody** |
| AI that understands trade logic (circuits, DFUs, duct CFM) | **Nobody** |
| Affordable for 1-person shops (< $50/mo) | **Nobody** |
| Revision comparison built into takeoff workflow | **Nobody** |
| Restoration takeoff that isn't Xactimate | **Nobody** |
| Takeoff with live supplier pricing | **Nobody** |
| Blueprint → floor plan → estimate → material order → job in one app | **NOBODY** |

**ZAFTO does ALL of these.**

---

## 3. Competitive Positioning

### vs. PlanSwift / STACK / OST (Legacy Click-to-Measure)
- PlanSwift 2026 added cloud+AI, but still per-seat licensing and frequent crashes. STACK expanded pricing tiers ($1,899-5,499/yr).
- They're adding AI features, but as bolt-ons to legacy architectures. ZAFTO is AI-native from the ground up.
- They don't connect to anything. ZAFTO feeds directly into estimates, jobs, invoices, material orders.
- They cost $1,000-5,500/year as standalone tools. ZAFTO includes it in the platform.

### vs. Togal.AI (AI Takeoff)
- Togal: $199-299/user/month ($2,400-3,600/year). ZAFTO: included in platform subscription.
- Togal: "Essentially a basic area and linear measurement tool with AI." No trade-specific logic.
- Togal: Standalone — no CRM, no job management, no invoicing, no material ordering.
- ZAFTO: Blueprint → floor plan → trade layers → estimate → job → invoice → payment. End to end.

### vs. Bluebeam / Bluebeam Max (PDF Markup + AI)
- Bluebeam is a PDF tool with some measurement. Not a takeoff tool.
- Bluebeam Max launching early 2026 with Anthropic Claude integration — AI-powered markup/measurement. But still a standalone PDF tool, no CRM/estimate/job integration.
- Bluebeam doesn't generate estimates, create jobs, or connect to contractor workflows.

### vs. New AI Entrants (Bild AI, Kreo Caddie, Beam AI)
- YC-backed Bild AI and other startups entering the space. Mostly focused on GC/commercial, not trade contractors.
- None offer multi-trade intelligence (circuits, DFUs, duct sizing). None integrate into a full contractor platform.
- ConX (acquired by Houzz 2024) proved the market but pivoted to homeowner remodeling. Contractor takeoff gap remains.

### vs. Xactimate (Restoration)
- Xactimate is insurance-required but universally hated (3.5/5 ease of use, buggy, crashes).
- ZAFTO's TPA module + Plan Review = better UX + FML export + own pricing DB.
- ZAFTO's damage layer mapping → auto-estimate is something Xactimate can't do from blueprints.

### ZAFTO's Unique Value
**No competitor does:** Upload blueprint → AI reads it → floor plan generated → trade layers overlaid → estimate auto-created with CSI line items → material order generated with live supplier pricing → job created in CRM → invoice sent → payment collected. **All in one platform.**

---

## 4. Technical Architecture

### The Hybrid Pipeline (CV + LLM)

Pure LLM vision achieves ~60% accuracy on blueprints. Specialized CV achieves 97%+. The answer is hybrid.

```
Blueprint PDF / Photo
        |
        v
[File Ingestion Layer]
  - PyMuPDF: extract vector geometry from PDF
  - ezdxf: parse DXF/DWG files
  - IfcOpenShell: parse IFC/BIM files
  - Rasterizer: 300 DPI for image-based analysis
        |
        v
[Computer Vision Pipeline] (Edge Function or dedicated service)
  - U-Net segmentation: walls, rooms, corridors (pixel classification)
  - YOLOv8 detection: doors, windows, fixtures, trade symbols (object detection)
  - Construction OCR: dimension text, room labels, annotations, scale bars
  - Scale detector: scale bar + dimension cross-verification
        |
        v
[Post-Processing Engine]
  - Wall vectorization: pixel masks → line segments with thickness
  - Room polygon formation: closed boundaries via wall topology
  - Measurement engine: lengths (LF), areas (SF), counts (EA)
  - Assembly expansion: wall type → material breakdown (studs + drywall + insulation)
  - CSI MasterFormat classification: auto-assign division codes
        |
        v
[Structured Data Store] (Supabase tables)
  - blueprint_analyses: per-blueprint analysis results
  - blueprint_rooms: detected rooms with measurements
  - blueprint_elements: detected elements (doors, windows, fixtures, symbols)
  - blueprint_trade_items: trade-specific items with quantities + units
  - blueprint_revisions: revision comparison data
        |
        v
[LLM Intelligence Layer] (Claude / Phase E)
  - Contextual validation: "Does this 2,400 SF room make sense for a bathroom?"
  - Trade logic: "5 outlets on 1 circuit exceeds NEC recommendations"
  - Natural language queries: "What's the total conduit run for floor 2?"
  - Report generation: takeoff summaries, scope narratives, bid descriptions
  - Estimate review: cross-check quantities against industry benchmarks
        |
        v
[ZAFTO Integration]
  - FloorPlanDataV2: feeds Sketch Engine (SK)
  - D8 Estimates: auto-creates estimate with line items
  - Material ordering: generates POs via Unwrangle/HD Pro Xtra
  - Job creation: creates job record in CRM
  - Programs: damage areas → IICRC-coded line items
```

### Model Selection

| Task | Model | Why |
|------|-------|-----|
| Wall/room segmentation | MitUNet (PyTorch) | 87.84% mIoU on CubiCasa5K — outperforms U-Net++ on floor plan segmentation. Multi-scale feature aggregation. Fallback: U-Net++ if MitUNet proves harder to fine-tune on construction plans. |
| Object detection | YOLO11 (primary) / YOLOv12 (evaluate) | YOLO11: 22% fewer params than v8, higher mAP, best Ultralytics ecosystem support. Production-proven. YOLOv12: attention-centric design, better accuracy but early stability concerns. Evaluate v12 as drop-in replacement once ecosystem matures. Fine-tune on construction symbol dataset (62+ types). |
| Symbol classification | Fine-tuned Inception-v3 | 97% accuracy on furnishing/fixture classification. Transfer learning from ImageNet. |
| Text/OCR | CRAFT (detection) + PARSEq (recognition) | Handles rotated, curved, overlapping text. Construction-specific post-processing. |
| Scale detection | Custom module | Multi-method: scale bar + dimension cross-verification + title block parsing. |
| Intelligence layer | Claude (Anthropic API) | Contextual understanding, validation, NLP queries, report generation. |

### Training Data Strategy
- **CUbiCasa5K**: 5,000 annotated floor plans (open dataset) — primary benchmark
- **RPLAN**: 80,000 annotated residential floor plans
- **ResPlan**: 17,000 vector-based floor plans with room connectivity graphs (Aug 2025, GitHub + Kaggle)
- **MLSTRUCT-FP**: Multi-unit floor plan dataset
- **Custom annotation**: Contractor-submitted plans annotated in-house (trade symbols, MEP, damage). Budget 500-1000 sheets minimum per trade. No public trade symbol dataset exists at scale.
- **Synthetic generation**: Augment training data by programmatically generating plans with known measurements
- **Active learning**: Run inference → human reviewers correct → retrain. Critical for trade symbol accuracy.

### Open-Source Starting Points
| Project | Use |
|---------|-----|
| DeepFloorplan (ICCV 2019) | Base architecture for room/boundary detection |
| TF2DeepFloorplan | TensorFlow 2 port with API, Docker, TFLite |
| YOLOv8 floor plan detector | Object detection for doors/windows/columns |
| ezdxf | DXF file parsing (Python) |
| IfcOpenShell | IFC/BIM parsing with quantity extraction |
| PyMuPDF | PDF vector geometry extraction |

### Deployment Architecture
- **CV Pipeline**: Runs as a dedicated service (not in Supabase Edge Functions — too heavy for serverless)
- **Recommended: RunPod Serverless** ($1.89-2.49/hr A100 40GB, 40-50% cheaper than Modal/Replicate). Pay-per-inference, auto-scales to zero, cold start ~5-15s with pre-warmed workers.
- **Alternatives**:
  - Modal.com (better DX, more expensive — ~$3.70/hr A100, worth it if RunPod proves too complex)
  - Self-hosted GPU server (most control, ~$200/mo for A10G — only if volume justifies dedicated)
  - AWS SageMaker endpoint (enterprise path, highest cost)
- **Processing flow**: Upload PDF → queue job → RunPod serverless endpoint processes → results stored in Supabase → client notified via real-time subscription
- **Processing time target**: < 30 seconds per sheet for AI analysis
- **Cost estimate at scale**: ~$0.02-0.05 per sheet (30s inference × $2.50/hr GPU). At 1,000 sheets/month = ~$20-50/month GPU cost.

---

## 5. Feature Set

### 5.1 Blueprint Upload & Ingestion
- **Formats**: PDF (vector + raster), DXF, DWG, DWF, TIFF, JPEG, PNG, IFC
- **Multi-sheet support**: Upload entire plan set (50-200+ sheets). Auto-classify by discipline (A, S, E, P, M, FP).
- **Mobile capture**: Photograph blueprints at job site. AI corrects perspective, enhances, and processes.
- **Drag-and-drop**: Web CRM upload area. Mobile camera + file picker.
- **Scale detection**: Automatic via scale bar, dimensions, and title block. Manual override available.
- **Sheet organization**: Auto-generated table of contents. Discipline tags. Bookmark navigation.

### 5.2 AI Auto-Detection
- **Rooms**: Detect enclosed spaces, classify type (bedroom, bathroom, kitchen, hallway, mechanical, etc.), calculate area + perimeter.
- **Walls**: Detect wall lines, classify type (interior, exterior, fire-rated, moisture-resistant), measure length + infer thickness.
- **Openings**: Detect doors (type, width, swing direction) and windows (type, width, height, sill height).
- **Fixtures**: Count and classify all trade symbols:

| Trade | Symbols Detected |
|-------|-----------------|
| **Electrical** | Receptacle (standard, GFCI, 240V, floor), switch (single, 3-way, dimmer), light (ceiling, recessed, pendant, track, can), panel, junction box, smoke/CO detector, fan |
| **Plumbing** | Toilet, sink (kitchen, bath, utility), shower, tub, washer box, water heater, hose bib, floor drain, cleanout |
| **HVAC** | Supply diffuser, return grille, thermostat, condenser, air handler, mini-split, ERV, duct runs |
| **Fire Protection** | Sprinkler heads, pull stations, horn/strobe, FDC, standpipe |
| **General** | Cabinets, appliances, stairs, elevators, ramps |

- **Dimensions**: Read and associate dimension text with geometric elements.
- **Labels**: Read room names, wall tags, section markers, detail references.
- **Accuracy target**: Walls/rooms: 93-96% F1 on vector PDFs, 85-90% on raster. Trade symbols: 80-85% mAP initially (no public training dataset exists — improves with active learning + proprietary data). Dimension OCR: 88-94% recall.
- **Review mode**: Every AI detection shown with confidence score. User clicks to confirm, correct, or remove. AI learns from corrections.

### 5.3 Trade-Specific Intelligence
Not just counting shapes — understanding what they mean.

**Electrical:**
- Auto-count by circuit: group outlets/switches/lights by circuit designation
- Wire run estimation: calculate LF of wire from panel to each device based on routing
- Panel schedule generation: map detected devices to panel, calculate load
- NEC validation: flag if circuit count per breaker exceeds recommendations
- Conduit routing: estimate conduit LF based on detected device locations + routing rules

**Plumbing:**
- Fixture schedule generation: list all detected fixtures with DFU ratings
- Pipe run estimation: calculate LF of supply/drain based on fixture locations
- Fitting count: estimate elbows, tees, couplings based on routing
- Water heater sizing: based on fixture count + type
- Drain sizing: based on total DFU per branch/main

**HVAC:**
- Diffuser/grille counting with CFM assignment based on room size
- Duct run estimation from equipment to diffusers
- Tonnage verification: cross-check equipment capacity vs room SF
- Filter sizing: based on return grille count

**Restoration/Damage:**
- Damage area mapping: overlay affected zones on floor plan
- IICRC classification: assign Cat 1/2/3, Class 1-4 based on mapped zones
- Auto-generate Xactimate-compatible line items (demo, dry, replace)
- Moisture reading overlay: place readings on plan with severity color coding

**Painting:**
- Net wall area: gross wall SF minus door/window openings
- Ceiling SF per room
- Baseboard/crown LF per room
- Surface prep estimation based on wall condition notes

**Flooring:**
- Room area with waste factor by material type (tile 10%, hardwood 7%, carpet 5%)
- Transition strip LF between rooms
- Pattern-aware waste calculation for directional materials
- Base molding LF per room

**Roofing (from plan or satellite):**
- Pitch-adjusted area calculation
- Ridge, hip, valley, rake, eave LF
- Waste factor by roof type (gable 10%, hip 17%)
- Material-specific calculations (shingle bundles, metal panels, fastener count)

### 5.4 Measurement Engine
All measurements auto-calculated from detected geometry:

| Measurement | Unit | Source |
|-------------|------|--------|
| Room floor area | SF | Room boundary polygon (shoelace formula) |
| Room wall area | SF | Wall length × height, minus openings |
| Room ceiling area | SF | Same as floor (flat ceiling assumption, adjustable) |
| Room perimeter | LF | Sum of boundary wall lengths |
| Wall length | LF | Wall segment start-to-end |
| Baseboard/crown | LF | Perimeter minus door widths |
| Door/window count | EA | Detected from boundary walls |
| Paint area | SF | Wall + ceiling SF (configurable) |
| Fixture count | EA | Per-type detection |
| Conduit/pipe run | LF | Estimated routing between detected elements |

### 5.5 Revision Comparison
The #1 feature contractors dream about. The $31B/year problem.

- **Upload V1 and V2** of the same sheet
- **AI pixel-diff + semantic diff**: not just "pixels changed" but "what changed"
- **Change categories**: Added elements, removed elements, moved elements, dimension changes, note changes
- **Visual overlay**: side-by-side view with changes highlighted in red/green
- **Change log**: structured list of every change with location, category, and severity
- **Notification**: "3 walls moved, 2 outlets added, 1 door removed on Sheet A-201 Rev 2"
- **Scope impact**: auto-recalculate affected takeoff quantities and estimate adjustments
- **Works even when architects don't cloud changes** — catches everything

### 5.6 Auto-Estimate Generation
Blueprint → estimate in seconds.

1. AI detects all rooms, elements, fixtures
2. Measurements auto-calculated (SF, LF, EA)
3. CSI division codes auto-assigned
4. Assembly expansion: "Type A partition, 500 LF" → studs, drywall, insulation, tape, screws, labor
5. Live pricing lookup via Unwrangle API (HD, Lowe's, 50+ retailers) + HD Pro Xtra
6. D8 Estimates creates estimate with all line items
7. User reviews, adjusts, and finalizes
8. Estimate links to blueprint and floor plan for full traceability

### 5.7 Material Order Generation
From takeoff to purchase order:

1. Estimate line items aggregated into material list
2. Quantities rounded up with waste factor
3. Live pricing pulled from Unwrangle (HD/Lowe's/50 retailers)
4. Generate purchase order with:
   - Item descriptions matching supplier catalog
   - Quantities with units
   - Current pricing
   - Delivery address (from job record)
5. One-click order via HD Pro Xtra integration
6. PO attached to job record in CRM

### 5.8 Floor Plan Generation
Blueprint → Sketch Engine integration:

1. Detected walls, doors, windows → FloorPlanDataV2 schema
2. Trade symbols → trade layer elements (electrical, plumbing, HVAC, damage)
3. Room labels and measurements preserved
4. Full editability in Sketch Engine (mobile Flutter editor + web Konva canvas)
5. LiDAR scan data can be overlaid for field verification

### 5.9 Export
- **PDF Report**: Floor plan + room schedule + takeoff quantities + estimate summary
- **Excel/CSV**: Full takeoff data for external use
- **DXF**: CAD-compatible drawing export
- **FML**: Floor Markup Language (open format, Symbility/Cotality compatible)
- **ESX Import**: Read Xactimate estimates for comparison (export pending Verisk partnership)

### 5.10 Mobile Experience (Flutter)
- **Photograph blueprints**: Camera capture with perspective correction
- **Field verification**: Walk the job with AI-detected plan overlaid. Tap rooms to see measurements.
- **LiDAR comparison**: Scan room with LiDAR → compare against blueprint measurements → flag discrepancies
- **Offline processing**: Queue blueprints for analysis when back online. View cached results offline.
- **Voice annotation**: Narrate notes while walking the job. Notes attached to specific plan locations.

### 5.11 Web CRM Experience
- **Drag-and-drop upload**: Blueprint upload area in job record
- **Full-screen plan viewer**: Pan/zoom with measurement overlay
- **Split view**: Blueprint on left, takeoff quantities on right
- **Interactive**: Click any detected element to see details, adjust, or remove
- **Keyboard shortcuts**: Ctrl+Z undo, Delete remove, Tab next element
- **Multi-sheet navigation**: Tab bar for discipline sheets

---

## 6. Database Schema

### New Tables

```sql
-- Blueprint analysis job
CREATE TABLE blueprint_analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  job_id UUID REFERENCES jobs(id),
  created_by UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'uploading' CHECK (status IN (
    'uploading', 'queued', 'processing', 'review', 'complete', 'failed'
  )),
  file_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size_bytes BIGINT,
  sheet_count INTEGER DEFAULT 1,
  scale_detected NUMERIC,
  scale_unit TEXT DEFAULT 'imperial' CHECK (scale_unit IN ('imperial', 'metric')),
  processing_started_at TIMESTAMPTZ,
  processing_completed_at TIMESTAMPTZ,
  ai_model_version TEXT,
  confidence_score NUMERIC,
  floor_plan_id UUID REFERENCES property_floor_plans(id),
  estimate_id UUID REFERENCES estimates(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Detected sheets within a multi-page blueprint
CREATE TABLE blueprint_sheets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES blueprint_analyses(id) ON DELETE CASCADE,
  page_number INTEGER NOT NULL,
  discipline TEXT CHECK (discipline IN (
    'general', 'civil', 'architectural', 'structural',
    'mechanical', 'electrical', 'plumbing', 'fire_protection'
  )),
  sheet_name TEXT,
  scale NUMERIC,
  thumbnail_path TEXT,
  detection_data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Detected rooms
CREATE TABLE blueprint_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES blueprint_analyses(id) ON DELETE CASCADE,
  sheet_id UUID NOT NULL REFERENCES blueprint_sheets(id) ON DELETE CASCADE,
  name TEXT,
  room_type TEXT,
  boundary_points JSONB NOT NULL,
  floor_area_sf NUMERIC,
  wall_area_sf NUMERIC,
  ceiling_area_sf NUMERIC,
  perimeter_lf NUMERIC,
  ceiling_height_inches INTEGER DEFAULT 96,
  confidence NUMERIC,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Detected elements (doors, windows, fixtures, symbols)
CREATE TABLE blueprint_elements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES blueprint_analyses(id) ON DELETE CASCADE,
  sheet_id UUID NOT NULL REFERENCES blueprint_sheets(id) ON DELETE CASCADE,
  room_id UUID REFERENCES blueprint_rooms(id),
  element_type TEXT NOT NULL,
  element_subtype TEXT,
  trade TEXT CHECK (trade IN (
    'general', 'electrical', 'plumbing', 'hvac',
    'fire_protection', 'finish', 'structural'
  )),
  position JSONB NOT NULL,
  dimensions JSONB,
  quantity INTEGER DEFAULT 1,
  csi_code TEXT,
  confidence NUMERIC,
  verified BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Trade-specific takeoff items (aggregated from elements)
CREATE TABLE blueprint_takeoff_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID NOT NULL REFERENCES blueprint_analyses(id) ON DELETE CASCADE,
  csi_division TEXT,
  csi_code TEXT,
  description TEXT NOT NULL,
  quantity NUMERIC NOT NULL,
  unit TEXT NOT NULL CHECK (unit IN (
    'SF', 'LF', 'EA', 'CY', 'SY', 'SQ',
    'BF', 'LB', 'TON', 'GAL', 'HR', 'LS'
  )),
  unit_material_cost NUMERIC,
  unit_labor_cost NUMERIC,
  extended_cost NUMERIC,
  trade TEXT,
  room_id UUID REFERENCES blueprint_rooms(id),
  source TEXT DEFAULT 'ai' CHECK (source IN ('ai', 'manual', 'adjusted')),
  waste_factor NUMERIC DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Revision comparisons
CREATE TABLE blueprint_revisions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  analysis_v1_id UUID NOT NULL REFERENCES blueprint_analyses(id),
  analysis_v2_id UUID NOT NULL REFERENCES blueprint_analyses(id),
  sheet_page INTEGER,
  changes JSONB NOT NULL DEFAULT '[]',
  change_summary TEXT,
  scope_impact JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### Indexes
```sql
CREATE INDEX idx_blueprint_analyses_company ON blueprint_analyses(company_id);
CREATE INDEX idx_blueprint_analyses_job ON blueprint_analyses(job_id);
CREATE INDEX idx_blueprint_sheets_analysis ON blueprint_sheets(analysis_id);
CREATE INDEX idx_blueprint_rooms_analysis ON blueprint_rooms(analysis_id);
CREATE INDEX idx_blueprint_elements_analysis ON blueprint_elements(analysis_id);
CREATE INDEX idx_blueprint_elements_trade ON blueprint_elements(trade);
CREATE INDEX idx_blueprint_takeoff_items_analysis ON blueprint_takeoff_items(analysis_id);
CREATE INDEX idx_blueprint_takeoff_items_csi ON blueprint_takeoff_items(csi_division);
```

### Edge Functions (3)
1. **`blueprint-upload`** — Handle file upload, validate format, create analysis record, queue processing job
2. **`blueprint-process`** — Orchestrate CV pipeline: call inference service, store results, generate floor plan, trigger estimate
3. **`blueprint-compare`** — Compare two blueprint versions, generate change report

---

## 7. Sprint Breakdown

### BA1: Data Model + File Ingestion (16h)
- Create migration with all 6 tables + indexes
- File upload endpoint (Edge Function)
- Support PDF, DXF, DWG, TIFF, JPEG, PNG
- Multi-sheet PDF page splitting
- Scale detection from title block OCR
- Storage: blueprints bucket in Supabase Storage
- Flutter: camera capture with perspective correction
- Web: drag-and-drop upload component
- Tests: upload → record created → file stored → pages split

### BA2: CV Pipeline Setup + Wall/Room Detection (20h)
- Deploy inference service (RunPod Serverless — A100 40GB, ~$2/hr)
- MitUNet model for wall/room segmentation (87.84% mIoU CubiCasa5K). Fallback: U-Net++ if MitUNet fine-tuning proves unstable.
- Train on CUbiCasa5K + RPLAN datasets
- Room boundary extraction (wall topology → closed polygons)
- Room type classification (bedroom, bathroom, kitchen, etc.)
- Measurement engine: shoelace formula for area, perimeter sum for LF
- Wall vectorization: pixel masks → line segments
- Scale application: pixel measurements → real-world dimensions
- Results stored in blueprint_rooms table
- Processing status updates via Supabase real-time

### BA3: Object Detection — Doors, Windows, Fixtures (16h)
- YOLO11 model for object/symbol detection (22% fewer params than v8, higher mAP, best Ultralytics ecosystem). Evaluate YOLOv12 as drop-in once stable.
- Fine-tune on construction symbol dataset (62+ symbol types)
- Door detection: type, width, swing direction
- Window detection: type, width, height
- General fixture detection: cabinets, appliances, stairs
- Dimension text OCR: CRAFT detection + PARSEq recognition
- Room label OCR and association
- Results stored in blueprint_elements table
- Confidence scores on every detection

### BA4: Trade Symbol Detection — MEP (20h)
- Electrical symbol detection (15 types): receptacles, switches, lights, panels, J-boxes, detectors
- Plumbing symbol detection (12 types): toilets, sinks, showers, tubs, water heaters, drains
- HVAC symbol detection (10 types): diffusers, grilles, thermostats, equipment, ducts
- Fire protection symbol detection (5 types): sprinklers, pull stations, horn/strobes
- Symbol-to-CSI mapping: each detected symbol auto-assigned CSI code
- Trade-specific quantity aggregation
- Results stored in blueprint_elements with trade field
- Train on custom MEP plan dataset

### BA5: Trade Intelligence + Assembly Expansion (16h)
- **Electrical**: circuit grouping, wire run estimation, panel schedule generation, NEC validation
- **Plumbing**: fixture schedule, DFU calculation, pipe run estimation, fitting count
- **HVAC**: CFM assignment by room, duct run estimation, tonnage verification
- **Painting**: net wall area (minus openings), ceiling SF, baseboard LF
- **Flooring**: waste factor by material type, transition LF, base molding LF
- **Roofing**: pitch-adjusted area, ridge/hip/valley LF, material-specific calculations
- Assembly expansion engine: wall type → full material breakdown (studs + board + insulation + tape + screws + labor)
- CSI MasterFormat line item generation
- Results stored in blueprint_takeoff_items table

### BA6: Estimate + Material Order Generation (12h)
- Connect to D8 Estimates: auto-create estimate from takeoff items
- Live pricing via Unwrangle API for material costs
- Assembly pricing: material + labor per unit
- Waste factor application per trade
- Purchase order generation from aggregated materials
- HD Pro Xtra integration for direct ordering
- Estimate ↔ blueprint linkage (full traceability)
- "Generate Estimate" button on blueprint viewer (mobile + web)
- "Generate Material Order" button on estimate page

### BA7: Revision Comparison + Floor Plan Generation (16h)
- Side-by-side sheet comparison (V1 vs V2)
- Pixel-level diff with AI semantic understanding
- Change categorization: added, removed, moved, dimension changed
- Visual overlay with red/green highlighting
- Structured change log with location + severity
- Scope impact calculation: auto-adjust takeoff quantities
- Floor plan generation: detected geometry → FloorPlanDataV2
- Trade layers populated from detected MEP symbols
- Links to Sketch Engine for editing
- Push detected rooms to floor_plan_rooms table

### BA8: UI Polish + Review Mode + Testing (12h)
- **Review mode**: every AI detection shown with confidence badge. Click to confirm/correct/remove.
- **Learning feedback loop**: corrections stored for model retraining
- **Web CRM viewer**: full-screen plan with measurement overlay, split-view takeoff panel
- **Mobile viewer**: pan/zoom/tap with measurement popup, offline cached results
- **Multi-sheet navigation**: discipline tabs, thumbnail sidebar
- **Export**: PDF report, Excel/CSV, DXF
- **Performance**: target < 30 seconds per sheet
- **Accuracy audit**: test against 50 real contractor blueprints across all trades
- **Button audit**: every button clicks, every export works, every flow completes

---

## 8. Integration Map

```
Plan Review
    |
    ├── Sketch Engine (SK) → FloorPlanDataV2 + trade layers
    ├── D8 Estimates → auto-generated estimates with CSI line items
    ├── Programs (T) → damage area mapping + IICRC line items
    ├── Material Ordering → Unwrangle API + HD Pro Xtra POs
    ├── Job Management → blueprint attached to job record
    ├── Client Portal → share takeoff visuals with customers
    ├── Ledger → estimate costs flow to financial tracking
    └── Z Intelligence (Phase E) → Claude validates, queries, reports
```

---

## 9. Pricing Strategy

Plan Review is included in all ZAFTO tiers — no per-scan pricing, no credit packs, no separate AI purchases.

**AI MONETIZATION MODEL (standing rule):** All AI features (Z Intelligence, Blueprint Analyzer, Recon, AI Scanner) are governed by a single **tier-based usage meter**. No visible counts, no scan limits, no credits. Each tier has an internal cost threshold — when exceeded, user is prompted to upgrade. Business/Enterprise = unlimited. User never sees numbers, just a clean usage bar in Settings.

| ZAFTO Tier | AI Access | Competitor Equivalent Cost |
|-----------|--------------------------|---------------------------|
| Solo ($49.99/mo) | All AI features, tier-appropriate usage | $0 (manual only) |
| Team ($99.99/mo) | All AI features, higher usage threshold | PlanSwift $167/mo + Bluebeam $33/mo = $200/mo |
| Business ($199.99/mo) | Unlimited AI, all features, priority processing | Togal $299/mo + OST $83/mo + Bluebeam $33/mo = $415/mo |
| Enterprise (custom) | Unlimited AI + API access + dedicated support | $415+/mo |

**Need more?** Users who exceed their tier's AI usage can buy more in clean dollar amounts ($10/$25/$50/$100/$500/$1,000) — meter refills, AI turns back on. Never forced to upgrade. No credits, no tokens, no scan counts.

**Key pricing insight from research:** Small 1-3 person shops can't justify $2,000/year for standalone takeoff. They bid 5-10 jobs/year. ZAFTO's Solo tier gives them AI takeoff bundled into the platform they already use for everything else — at a fraction of the cost. Need more? Buy $25 of AI usage, keep working. No games.

---

## 10. Success Metrics

| Metric | Target | Current Industry |
|--------|--------|-----------------|
| Takeoff time per sheet | < 30 seconds (AI) + 5 min review | 2-3 hours manual |
| Detection accuracy (rooms/walls) | 95%+ | Togal claims 98% |
| Detection accuracy (trade symbols) | 90%+ | STACK: 80-85% |
| Revision change detection | 99%+ | Manual: ~70% (misses happen) |
| Estimate generation time | < 2 minutes from blueprint upload | 20+ hours manual |
| User satisfaction vs. current tools | > 4.5/5 | PlanSwift 4.3, OST 4.3, Xactimate 4.0 |
| Time to proficiency | < 30 minutes | Bluebeam: days-weeks |

---

## 11. Legal Considerations

- **Blueprint copyright**: Contractors have licensed use of blueprints for their projects. AI analysis for estimation purposes falls under normal construction use.
- **Xactimate/ESX**: Plan Review generates its own line items with ZAFTO's own pricing DB. ESX import (reading) is low risk. ESX export deferred pending Verisk partnership.
- **FML export**: Open format, safe to generate.
- **Training data**: Use open datasets (CUbiCasa5K, RPLAN) + contractor-submitted plans with permission. No scraping.
- **Accuracy disclaimer**: "AI-generated measurements should be verified. ZAFTO is not liable for estimate accuracy."

---

## 12. Build Dependencies

```
Phase E (AI Layer) must be active — Plan Review IS an AI feature.
Prerequisites:
  - SK (Sketch Engine) → FloorPlanDataV2 schema exists
  - D8 (Estimates) → estimate tables + line item structure exists
  - T (Programs) → IICRC damage classification exists
  - F3 (Supply Chain) → Unwrangle API integration exists
  - Phase U → unified portal for web CRM viewer exists

Build order within Phase E:
  E-review → BA1 → BA2 → BA3 → BA4 → BA5 → BA6 → BA7 → BA8
```

---

*This spec was built from 3 parallel deep research agents analyzing 12 competitors, 25+ contractor forums/review sites, and complete technical architecture for CV + LLM hybrid blueprint analysis. Every pain point, every gap, every technical decision is research-backed.*

*Research validated (S97): MitUNet confirmed 87.84% mIoU on CubiCasa5K (outperforms U-Net++, 50% less VRAM). YOLO11 recommended as production model (22% fewer params than v8, higher mAP, best Ultralytics ecosystem). YOLOv12 flagged for evaluation once ecosystem matures. ResPlan dataset (17K plans, Aug 2025) added to training data strategy. RunPod Serverless validated as cheapest GPU option ($1.89-2.49/hr A100, 40-50% cheaper than Modal). PlanSwift 2026 now cloud+AI (updated from desktop-only). Bluebeam Max launching early 2026 with Anthropic Claude. New entrants: Bild AI (YC), Kreo Caddie, ConX (Houzz acquisition). XactAI confirmed NOT a takeoff competitor (claims workflow only). Togal pricing confirmed $2,700-3,588/yr. $3,000-5,000/yr competitor floor validated. Trade symbol accuracy realistically 80-85% initially (no public dataset exists at scale), not 95% — plan for active learning + proprietary dataset creation.*
