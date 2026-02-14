// ZAFTO Pre-Built Templates (SK13)
// Starter templates for common trade jobs. Each includes pre-drawn layouts,
// measurement callouts, and linked estimate category references.

import type { FloorPlanData, SitePlanData } from './types';
import { createEmptyFloorPlan, createEmptySitePlan } from './types';

export type TemplateCategory =
  | 'roofing'
  | 'fencing'
  | 'concrete'
  | 'kitchen'
  | 'bathroom'
  | 'basement'
  | 'deck'
  | 'addition'
  | 'landscape'
  | 'solar';

export interface SketchTemplate {
  id: string;
  name: string;
  description: string;
  category: TemplateCategory;
  thumbnail: string; // SVG data URL or placeholder
  floorPlan?: FloorPlanData;
  sitePlan?: SitePlanData;
  estimateCategories: string[]; // linked D8 estimate area names
}

// ── Template factory helpers ──

function makeId(): string {
  return `tmpl_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`;
}

// ── Built-in templates ──

const ROOFING_TEMPLATE: SketchTemplate = {
  id: 'tmpl-roofing-reshingle',
  name: 'Basic Shingle Re-Roof',
  description: 'Standard residential shingle replacement. Structure outline with roof plan overlay, ridge/eave measurements.',
  category: 'roofing',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    structures: [
      {
        id: 's1',
        points: [
          { x: 600, y: 600 },
          { x: 1000, y: 600 },
          { x: 1000, y: 900 },
          { x: 600, y: 900 },
        ],
        label: 'Main House',
        roofPitch: 6,
      },
    ],
    roofPlanes: [
      {
        id: 'rp1',
        structureId: 's1',
        points: [
          { x: 580, y: 580 },
          { x: 800, y: 500 },
          { x: 1020, y: 580 },
          { x: 1020, y: 920 },
          { x: 800, y: 1000 },
          { x: 580, y: 920 },
        ],
        pitch: 6,
        type: 'gable',
        wasteFactor: 0.10,
      },
    ],
  },
  estimateCategories: ['Roofing - Shingles', 'Roofing - Underlayment', 'Roofing - Flashing', 'Roofing - Ridge Vents'],
};

const FENCING_TEMPLATE: SketchTemplate = {
  id: 'tmpl-fencing-privacy',
  name: 'Standard 6ft Privacy Fence',
  description: '6ft wood privacy fence with gates. Auto-calculates posts, rails, pickets, and concrete.',
  category: 'fencing',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    boundary: {
      id: 'b1',
      points: [
        { x: 400, y: 400 },
        { x: 1200, y: 400 },
        { x: 1200, y: 1000 },
        { x: 400, y: 1000 },
      ],
      totalArea: 0,
    },
    linearFeatures: [
      {
        id: 'f1',
        type: 'fence',
        points: [
          { x: 400, y: 400 },
          { x: 1200, y: 400 },
          { x: 1200, y: 1000 },
          { x: 400, y: 1000 },
          { x: 400, y: 400 },
        ],
        height: 6,
        postSpacing: 8,
      },
    ],
  },
  estimateCategories: ['Fencing - Posts', 'Fencing - Rails', 'Fencing - Pickets', 'Fencing - Gates', 'Fencing - Concrete'],
};

const CONCRETE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-concrete-driveway',
  name: 'Standard Driveway',
  description: '4" concrete driveway with rebar, forms, and expansion joints.',
  category: 'concrete',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    areaFeatures: [
      {
        id: 'af1',
        type: 'driveway',
        points: [
          { x: 500, y: 600 },
          { x: 700, y: 600 },
          { x: 700, y: 1100 },
          { x: 500, y: 1100 },
        ],
        depth: 4,
      },
    ],
  },
  estimateCategories: ['Concrete - Flatwork', 'Concrete - Rebar', 'Concrete - Forms', 'Concrete - Finishing'],
};

const KITCHEN_TEMPLATE: SketchTemplate = {
  id: 'tmpl-kitchen-remodel',
  name: 'Kitchen Remodel',
  description: 'L-shaped kitchen with island. Cabinets, countertops, sink, stove, refrigerator pre-placed.',
  category: 'kitchen',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 500, y: 500 }, end: { x: 1100, y: 500 }, thickness: 6, height: 96 },
      { id: 'w2', start: { x: 1100, y: 500 }, end: { x: 1100, y: 900 }, thickness: 6, height: 96 },
      { id: 'w3', start: { x: 1100, y: 900 }, end: { x: 500, y: 900 }, thickness: 6, height: 96 },
      { id: 'w4', start: { x: 500, y: 900 }, end: { x: 500, y: 500 }, thickness: 6, height: 96 },
    ],
    doors: [
      { id: 'd1', wallId: 'w3', position: 0.3, width: 36, type: 'single' },
    ],
    fixtures: [
      { id: 'fx1', position: { x: 550, y: 550 }, type: 'sink', rotation: 0 },
      { id: 'fx2', position: { x: 750, y: 550 }, type: 'stove', rotation: 0 },
      { id: 'fx3', position: { x: 1050, y: 700 }, type: 'refrigerator', rotation: 270 },
      { id: 'fx4', position: { x: 800, y: 700 }, type: 'island', rotation: 0 },
    ],
    rooms: [
      { id: 'r1', name: 'Kitchen', wallIds: ['w1', 'w2', 'w3', 'w4'], center: { x: 800, y: 700 }, area: 200 },
    ],
  },
  estimateCategories: ['Cabinets', 'Countertops', 'Plumbing - Fixtures', 'Electrical - Kitchen', 'Flooring', 'Painting'],
};

const BATHROOM_TEMPLATE: SketchTemplate = {
  id: 'tmpl-bathroom-remodel',
  name: 'Bathroom Remodel',
  description: 'Full bathroom with tub/shower combo, toilet, vanity sink.',
  category: 'bathroom',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 600, y: 600 }, end: { x: 900, y: 600 }, thickness: 6, height: 96 },
      { id: 'w2', start: { x: 900, y: 600 }, end: { x: 900, y: 840 }, thickness: 6, height: 96 },
      { id: 'w3', start: { x: 900, y: 840 }, end: { x: 600, y: 840 }, thickness: 6, height: 96 },
      { id: 'w4', start: { x: 600, y: 840 }, end: { x: 600, y: 600 }, thickness: 6, height: 96 },
    ],
    doors: [
      { id: 'd1', wallId: 'w3', position: 0.5, width: 30, type: 'single' },
    ],
    fixtures: [
      { id: 'fx1', position: { x: 650, y: 650 }, type: 'toilet', rotation: 0 },
      { id: 'fx2', position: { x: 850, y: 650 }, type: 'sink', rotation: 0 },
      { id: 'fx3', position: { x: 750, y: 800 }, type: 'bathtub', rotation: 0 },
    ],
    rooms: [
      { id: 'r1', name: 'Bathroom', wallIds: ['w1', 'w2', 'w3', 'w4'], center: { x: 750, y: 720 }, area: 60 },
    ],
  },
  estimateCategories: ['Plumbing - Fixtures', 'Tile - Floor', 'Tile - Walls', 'Vanity', 'Painting', 'Electrical'],
};

const BASEMENT_TEMPLATE: SketchTemplate = {
  id: 'tmpl-basement-finish',
  name: 'Basement Finish',
  description: 'Open concept basement with bedroom, bathroom, and living area.',
  category: 'basement',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 400, y: 400 }, end: { x: 1200, y: 400 }, thickness: 6, height: 96 },
      { id: 'w2', start: { x: 1200, y: 400 }, end: { x: 1200, y: 900 }, thickness: 6, height: 96 },
      { id: 'w3', start: { x: 1200, y: 900 }, end: { x: 400, y: 900 }, thickness: 6, height: 96 },
      { id: 'w4', start: { x: 400, y: 900 }, end: { x: 400, y: 400 }, thickness: 6, height: 96 },
      // Interior partition
      { id: 'w5', start: { x: 800, y: 400 }, end: { x: 800, y: 700 }, thickness: 4, height: 96 },
      { id: 'w6', start: { x: 800, y: 700 }, end: { x: 1000, y: 700 }, thickness: 4, height: 96 },
    ],
    rooms: [
      { id: 'r1', name: 'Living Area', wallIds: ['w1', 'w5', 'w6', 'w2', 'w3', 'w4'], center: { x: 600, y: 650 }, area: 400 },
      { id: 'r2', name: 'Bedroom', wallIds: ['w1', 'w2', 'w5'], center: { x: 1000, y: 550 }, area: 200 },
    ],
  },
  estimateCategories: ['Framing', 'Drywall', 'Electrical', 'Plumbing', 'HVAC', 'Flooring', 'Painting', 'Egress Window'],
};

const DECK_TEMPLATE: SketchTemplate = {
  id: 'tmpl-deck-build',
  name: 'Deck Build',
  description: 'Rectangular deck with stairs. Auto-calculates decking, joists, posts, railing.',
  category: 'deck',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    areaFeatures: [
      {
        id: 'af1',
        type: 'deck',
        points: [
          { x: 600, y: 700 },
          { x: 1000, y: 700 },
          { x: 1000, y: 900 },
          { x: 600, y: 900 },
        ],
      },
    ],
  },
  estimateCategories: ['Decking - Boards', 'Decking - Framing', 'Decking - Posts/Footings', 'Decking - Railing', 'Decking - Stairs'],
};

const LANDSCAPE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-landscape-design',
  name: 'Landscape Design',
  description: 'Front yard landscape with beds, lawn, trees, irrigation layout.',
  category: 'landscape',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    areaFeatures: [
      {
        id: 'af1',
        type: 'lawn',
        points: [
          { x: 400, y: 500 },
          { x: 1200, y: 500 },
          { x: 1200, y: 900 },
          { x: 400, y: 900 },
        ],
      },
      {
        id: 'af2',
        type: 'landscape',
        points: [
          { x: 400, y: 400 },
          { x: 700, y: 400 },
          { x: 700, y: 500 },
          { x: 400, y: 500 },
        ],
        depth: 3,
      },
    ],
    symbols: [
      { id: 'sym1', type: 'treeDeciduous', position: { x: 550, y: 450 }, rotation: 0, canopyRadius: 8 },
      { id: 'sym2', type: 'shrub', position: { x: 450, y: 450 }, rotation: 0 },
      { id: 'sym3', type: 'shrub', position: { x: 650, y: 450 }, rotation: 0 },
    ],
  },
  estimateCategories: ['Landscaping - Sod', 'Landscaping - Mulch', 'Landscaping - Plants', 'Landscaping - Irrigation', 'Landscaping - Edging'],
};

const SOLAR_TEMPLATE: SketchTemplate = {
  id: 'tmpl-solar-install',
  name: 'Solar Installation',
  description: 'Roof-mounted solar panel array. Calculates panel count, kW, conduit, and inverter.',
  category: 'solar',
  thumbnail: '',
  sitePlan: {
    ...createEmptySitePlan(),
    structures: [
      {
        id: 's1',
        points: [
          { x: 500, y: 500 },
          { x: 1100, y: 500 },
          { x: 1100, y: 900 },
          { x: 500, y: 900 },
        ],
        label: 'House',
        roofPitch: 5,
      },
    ],
    linearFeatures: [
      {
        id: 'sr1',
        type: 'solarRow',
        points: [
          { x: 550, y: 550 },
          { x: 1050, y: 550 },
        ],
      },
      {
        id: 'sr2',
        type: 'solarRow',
        points: [
          { x: 550, y: 620 },
          { x: 1050, y: 620 },
        ],
      },
      {
        id: 'sr3',
        type: 'solarRow',
        points: [
          { x: 550, y: 690 },
          { x: 1050, y: 690 },
        ],
      },
    ],
  },
  estimateCategories: ['Solar - Panels', 'Solar - Racking', 'Solar - Inverter', 'Solar - Conduit', 'Electrical - Service Upgrade'],
};

const ADDITION_TEMPLATE: SketchTemplate = {
  id: 'tmpl-room-addition',
  name: 'Room Addition',
  description: 'Single-room addition with door connection to existing structure.',
  category: 'addition',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 600, y: 600 }, end: { x: 1000, y: 600 }, thickness: 6, height: 96 },
      { id: 'w2', start: { x: 1000, y: 600 }, end: { x: 1000, y: 900 }, thickness: 6, height: 96 },
      { id: 'w3', start: { x: 1000, y: 900 }, end: { x: 600, y: 900 }, thickness: 6, height: 96 },
      { id: 'w4', start: { x: 600, y: 900 }, end: { x: 600, y: 600 }, thickness: 6, height: 96 },
    ],
    windows: [
      { id: 'win1', wallId: 'w1', position: 0.5, width: 48, type: 'standard' },
      { id: 'win2', wallId: 'w2', position: 0.5, width: 36, type: 'standard' },
    ],
    rooms: [
      { id: 'r1', name: 'Addition', wallIds: ['w1', 'w2', 'w3', 'w4'], center: { x: 800, y: 750 }, area: 300 },
    ],
  },
  estimateCategories: ['Foundation', 'Framing', 'Roofing', 'Windows', 'Siding', 'Electrical', 'HVAC', 'Drywall', 'Flooring', 'Painting'],
};

// ── Public API ──

export const BUILT_IN_TEMPLATES: SketchTemplate[] = [
  ROOFING_TEMPLATE,
  FENCING_TEMPLATE,
  CONCRETE_TEMPLATE,
  KITCHEN_TEMPLATE,
  BATHROOM_TEMPLATE,
  BASEMENT_TEMPLATE,
  DECK_TEMPLATE,
  LANDSCAPE_TEMPLATE,
  SOLAR_TEMPLATE,
  ADDITION_TEMPLATE,
];

export function getTemplatesByCategory(category: TemplateCategory): SketchTemplate[] {
  return BUILT_IN_TEMPLATES.filter((t) => t.category === category);
}

export function getTemplateById(id: string): SketchTemplate | undefined {
  return BUILT_IN_TEMPLATES.find((t) => t.id === id);
}

/** Apply a template — returns new plan data with unique IDs */
export function applyFloorPlanTemplate(template: SketchTemplate): FloorPlanData | null {
  if (!template.floorPlan) return null;
  // Deep clone and regenerate IDs to prevent conflicts
  const plan = JSON.parse(JSON.stringify(template.floorPlan)) as FloorPlanData;
  const idMap = new Map<string, string>();

  const regen = (old: string): string => {
    const nw = `${old}_${Date.now()}_${Math.random().toString(36).slice(2, 5)}`;
    idMap.set(old, nw);
    return nw;
  };

  plan.walls.forEach((w) => { w.id = regen(w.id); });
  plan.doors.forEach((d) => {
    d.id = regen(d.id);
    d.wallId = idMap.get(d.wallId) ?? d.wallId;
  });
  plan.windows.forEach((w) => {
    w.id = regen(w.id);
    w.wallId = idMap.get(w.wallId) ?? w.wallId;
  });
  plan.fixtures.forEach((f) => { f.id = regen(f.id); });
  plan.rooms.forEach((r) => {
    r.id = regen(r.id);
    r.wallIds = r.wallIds.map((wid) => idMap.get(wid) ?? wid);
  });

  return plan;
}

export function applySitePlanTemplate(template: SketchTemplate): SitePlanData | null {
  if (!template.sitePlan) return null;
  const plan = JSON.parse(JSON.stringify(template.sitePlan)) as SitePlanData;
  // Regenerate IDs
  const ts = Date.now();
  const r = () => Math.random().toString(36).slice(2, 5);
  if (plan.boundary) plan.boundary.id = `b_${ts}_${r()}`;
  plan.structures.forEach((s, i) => { s.id = `s_${ts}_${i}_${r()}`; });
  plan.roofPlanes.forEach((rp, i) => { rp.id = `rp_${ts}_${i}_${r()}`; });
  plan.linearFeatures.forEach((f, i) => { f.id = `lf_${ts}_${i}_${r()}`; });
  plan.areaFeatures.forEach((f, i) => { f.id = `af_${ts}_${i}_${r()}`; });
  plan.symbols.forEach((s, i) => { s.id = `sym_${ts}_${i}_${r()}`; });
  return plan;
}
