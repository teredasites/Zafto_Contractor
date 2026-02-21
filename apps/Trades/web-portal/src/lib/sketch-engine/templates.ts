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
  | 'solar'
  // Commercial
  | 'commercialOffice'
  | 'commercialRetail'
  | 'commercialWarehouse'
  | 'commercialRestaurant'
  | 'commercialMedical'
  | 'commercialSchool'
  | 'commercialChurch'
  | 'commercialApartment'
  | 'commercialHotel'
  | 'commercialGasStation'
  | 'commercialAutoRepair'
  | 'commercialSelfStorage'
  | 'commercialGym'
  | 'commercialBank'
  | 'commercialDataCenter'
  | 'commercialIndustrial';

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

// ── Commercial Building Templates ──

const OFFICE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-office',
  name: 'Office Building',
  description: 'Open plan office with private offices, conference room, break room, and reception. Typical tenant improvement layout.',
  category: 'commercialOffice',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1300, y: 300 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1300, y: 300 }, end: { x: 1300, y: 900 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1300, y: 900 }, end: { x: 300, y: 900 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 300, y: 600 }, end: { x: 600, y: 600 }, thickness: 4, height: 120 },
      { id: 'w6', start: { x: 600, y: 300 }, end: { x: 600, y: 600 }, thickness: 4, height: 120 },
      { id: 'w7', start: { x: 1000, y: 300 }, end: { x: 1000, y: 600 }, thickness: 4, height: 120 },
      { id: 'w8', start: { x: 1000, y: 600 }, end: { x: 1300, y: 600 }, thickness: 4, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w3', position: 0.5, width: 72, type: 'double' },
      { id: 'd2', wallId: 'w5', position: 0.5, width: 36, type: 'single' },
      { id: 'd3', wallId: 'w7', position: 0.5, width: 36, type: 'single' },
    ],
    rooms: [
      { id: 'r1', name: 'Reception', wallIds: ['w1', 'w6', 'w5', 'w4'], center: { x: 450, y: 450 }, area: 300 },
      { id: 'r2', name: 'Open Office', wallIds: ['w1', 'w7', 'w8', 'w2', 'w3', 'w5', 'w6'], center: { x: 800, y: 600 }, area: 600 },
      { id: 'r3', name: 'Conference Room', wallIds: ['w7', 'w1', 'w2', 'w8'], center: { x: 1150, y: 450 }, area: 300 },
      { id: 'r4', name: 'Break Room', wallIds: ['w5', 'w4', 'w3'], center: { x: 450, y: 750 }, area: 300 },
    ],
  },
  estimateCategories: ['Tenant Improvement - Framing', 'Drywall', 'Flooring - Commercial', 'Ceiling Grid', 'Electrical - Commercial', 'HVAC - Commercial', 'Painting - Commercial', 'Fire Protection'],
};

const STRIP_MALL_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-strip-mall',
  name: 'Strip Mall / Retail Center',
  description: 'Multi-tenant retail with 4 units, shared corridor, common restrooms, and rear loading.',
  category: 'commercialRetail',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 400 }, end: { x: 1400, y: 400 }, thickness: 8, height: 144 },
      { id: 'w2', start: { x: 1400, y: 400 }, end: { x: 1400, y: 900 }, thickness: 8, height: 144 },
      { id: 'w3', start: { x: 1400, y: 900 }, end: { x: 200, y: 900 }, thickness: 8, height: 144 },
      { id: 'w4', start: { x: 200, y: 900 }, end: { x: 200, y: 400 }, thickness: 8, height: 144 },
      { id: 'w5', start: { x: 500, y: 400 }, end: { x: 500, y: 900 }, thickness: 6, height: 144 },
      { id: 'w6', start: { x: 800, y: 400 }, end: { x: 800, y: 900 }, thickness: 6, height: 144 },
      { id: 'w7', start: { x: 1100, y: 400 }, end: { x: 1100, y: 900 }, thickness: 6, height: 144 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.11, width: 72, type: 'storefrontGlass' },
      { id: 'd2', wallId: 'w1', position: 0.36, width: 72, type: 'storefrontGlass' },
      { id: 'd3', wallId: 'w1', position: 0.61, width: 72, type: 'storefrontGlass' },
      { id: 'd4', wallId: 'w1', position: 0.86, width: 72, type: 'storefrontGlass' },
    ],
    rooms: [
      { id: 'r1', name: 'Unit A', wallIds: ['w1', 'w5', 'w3', 'w4'], center: { x: 350, y: 650 }, area: 750 },
      { id: 'r2', name: 'Unit B', wallIds: ['w1', 'w6', 'w3', 'w5'], center: { x: 650, y: 650 }, area: 750 },
      { id: 'r3', name: 'Unit C', wallIds: ['w1', 'w7', 'w3', 'w6'], center: { x: 950, y: 650 }, area: 750 },
      { id: 'r4', name: 'Unit D', wallIds: ['w1', 'w2', 'w3', 'w7'], center: { x: 1250, y: 650 }, area: 750 },
    ],
  },
  estimateCategories: ['Demising Walls', 'Storefront Glass', 'Flooring - Commercial', 'Ceiling Grid', 'HVAC - RTU', 'Electrical - Commercial', 'Signage', 'Fire Protection'],
};

const WAREHOUSE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-warehouse',
  name: 'Warehouse / Distribution',
  description: 'Clear-span warehouse with dock doors, office area, and loading bays.',
  category: 'commercialWarehouse',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 200 }, end: { x: 1400, y: 200 }, thickness: 12, height: 240 },
      { id: 'w2', start: { x: 1400, y: 200 }, end: { x: 1400, y: 1000 }, thickness: 12, height: 240 },
      { id: 'w3', start: { x: 1400, y: 1000 }, end: { x: 200, y: 1000 }, thickness: 12, height: 240 },
      { id: 'w4', start: { x: 200, y: 1000 }, end: { x: 200, y: 200 }, thickness: 12, height: 240 },
      { id: 'w5', start: { x: 200, y: 400 }, end: { x: 500, y: 400 }, thickness: 6, height: 120 },
      { id: 'w6', start: { x: 500, y: 200 }, end: { x: 500, y: 400 }, thickness: 6, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w2', position: 0.2, width: 120, type: 'rollUp' },
      { id: 'd2', wallId: 'w2', position: 0.5, width: 120, type: 'rollUp' },
      { id: 'd3', wallId: 'w2', position: 0.8, width: 120, type: 'rollUp' },
      { id: 'd4', wallId: 'w5', position: 0.5, width: 36, type: 'single' },
    ],
    rooms: [
      { id: 'r1', name: 'Office', wallIds: ['w1', 'w6', 'w5', 'w4'], center: { x: 350, y: 300 }, area: 300 },
      { id: 'r2', name: 'Warehouse Floor', wallIds: ['w1', 'w2', 'w3', 'w4', 'w6', 'w5'], center: { x: 900, y: 600 }, area: 4800 },
    ],
  },
  estimateCategories: ['Concrete - Warehouse Slab', 'Steel Structure', 'Dock Doors', 'Dock Levelers', 'HVAC - Unit Heaters', 'Electrical - Industrial', 'Fire Protection - Sprinkler', 'Insulation'],
};

const RESTAURANT_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-restaurant',
  name: 'Restaurant / Food Service',
  description: 'Full restaurant with commercial kitchen, dining room, bar area, and restrooms.',
  category: 'commercialRestaurant',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1200, y: 300 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1200, y: 300 }, end: { x: 1200, y: 900 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1200, y: 900 }, end: { x: 300, y: 900 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 800, y: 300 }, end: { x: 800, y: 900 }, thickness: 6, height: 120 },
      { id: 'w6', start: { x: 300, y: 700 }, end: { x: 500, y: 700 }, thickness: 4, height: 120 },
      { id: 'w7', start: { x: 500, y: 700 }, end: { x: 500, y: 900 }, thickness: 4, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.3, width: 72, type: 'double' },
      { id: 'd2', wallId: 'w5', position: 0.5, width: 42, type: 'double' },
    ],
    fixtures: [
      { id: 'fx1', position: { x: 900, y: 400 }, type: 'commercialOven', rotation: 0 },
      { id: 'fx2', position: { x: 1000, y: 400 }, type: 'commercialFryer', rotation: 0 },
      { id: 'fx3', position: { x: 1100, y: 400 }, type: 'commercialHood', rotation: 0 },
      { id: 'fx4', position: { x: 900, y: 600 }, type: 'threeCompSink', rotation: 0 },
      { id: 'fx5', position: { x: 1100, y: 700 }, type: 'walkInCooler', rotation: 0 },
      { id: 'fx6', position: { x: 1100, y: 850 }, type: 'walkInFreezer', rotation: 0 },
    ],
    rooms: [
      { id: 'r1', name: 'Dining Room', wallIds: ['w1', 'w5', 'w6', 'w4'], center: { x: 550, y: 500 }, area: 800 },
      { id: 'r2', name: 'Kitchen', wallIds: ['w1', 'w2', 'w3', 'w5'], center: { x: 1000, y: 600 }, area: 600 },
      { id: 'r3', name: 'Restrooms', wallIds: ['w6', 'w7', 'w3', 'w4'], center: { x: 400, y: 800 }, area: 200 },
    ],
  },
  estimateCategories: ['Kitchen Equipment', 'Grease Trap', 'Hood/Exhaust System', 'Walk-In Cooler/Freezer', 'Plumbing - Restaurant', 'Electrical - Restaurant', 'Fire Suppression - Kitchen', 'Flooring - Commercial Kitchen'],
};

const MEDICAL_OFFICE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-medical',
  name: 'Medical Office / Clinic',
  description: 'Medical office with exam rooms, waiting room, nurse station, and ADA-compliant restrooms.',
  category: 'commercialMedical',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1200, y: 300 }, thickness: 6, height: 108 },
      { id: 'w2', start: { x: 1200, y: 300 }, end: { x: 1200, y: 900 }, thickness: 6, height: 108 },
      { id: 'w3', start: { x: 1200, y: 900 }, end: { x: 300, y: 900 }, thickness: 6, height: 108 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 6, height: 108 },
      { id: 'w5', start: { x: 600, y: 300 }, end: { x: 600, y: 600 }, thickness: 4, height: 108 },
      { id: 'w6', start: { x: 600, y: 600 }, end: { x: 300, y: 600 }, thickness: 4, height: 108 },
      { id: 'w7', start: { x: 600, y: 600 }, end: { x: 900, y: 600 }, thickness: 4, height: 108 },
      { id: 'w8', start: { x: 900, y: 300 }, end: { x: 900, y: 600 }, thickness: 4, height: 108 },
      { id: 'w9', start: { x: 900, y: 600 }, end: { x: 1200, y: 600 }, thickness: 4, height: 108 },
    ],
    doors: [
      { id: 'd1', wallId: 'w3', position: 0.3, width: 42, type: 'single' },
      { id: 'd2', wallId: 'w6', position: 0.5, width: 36, type: 'single' },
      { id: 'd3', wallId: 'w7', position: 0.5, width: 36, type: 'single' },
      { id: 'd4', wallId: 'w9', position: 0.5, width: 36, type: 'single' },
    ],
    rooms: [
      { id: 'r1', name: 'Waiting Room', wallIds: ['w3', 'w4', 'w6'], center: { x: 450, y: 750 }, area: 300 },
      { id: 'r2', name: 'Exam Room 1', wallIds: ['w1', 'w5', 'w6', 'w4'], center: { x: 450, y: 450 }, area: 200 },
      { id: 'r3', name: 'Exam Room 2', wallIds: ['w1', 'w8', 'w7', 'w5'], center: { x: 750, y: 450 }, area: 200 },
      { id: 'r4', name: 'Nurse Station', wallIds: ['w7', 'w9', 'w3'], center: { x: 750, y: 750 }, area: 300 },
      { id: 'r5', name: 'Exam Room 3', wallIds: ['w1', 'w2', 'w9', 'w8'], center: { x: 1050, y: 450 }, area: 200 },
    ],
  },
  estimateCategories: ['Medical Gas', 'Plumbing - Medical', 'Electrical - Medical', 'HVAC - Medical', 'Flooring - Medical', 'ADA Compliance', 'Fire Protection'],
};

const SCHOOL_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-school',
  name: 'School / University',
  description: 'School wing with classrooms, corridor, office, and ADA restrooms.',
  category: 'commercialSchool',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 300 }, end: { x: 1400, y: 300 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1400, y: 300 }, end: { x: 1400, y: 900 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1400, y: 900 }, end: { x: 200, y: 900 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 200, y: 900 }, end: { x: 200, y: 300 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 200, y: 550 }, end: { x: 1400, y: 550 }, thickness: 6, height: 120 },
      { id: 'w6', start: { x: 200, y: 650 }, end: { x: 1400, y: 650 }, thickness: 6, height: 120 },
      { id: 'w7', start: { x: 500, y: 300 }, end: { x: 500, y: 550 }, thickness: 4, height: 120 },
      { id: 'w8', start: { x: 800, y: 300 }, end: { x: 800, y: 550 }, thickness: 4, height: 120 },
      { id: 'w9', start: { x: 1100, y: 300 }, end: { x: 1100, y: 550 }, thickness: 4, height: 120 },
      { id: 'w10', start: { x: 500, y: 650 }, end: { x: 500, y: 900 }, thickness: 4, height: 120 },
      { id: 'w11', start: { x: 800, y: 650 }, end: { x: 800, y: 900 }, thickness: 4, height: 120 },
      { id: 'w12', start: { x: 1100, y: 650 }, end: { x: 1100, y: 900 }, thickness: 4, height: 120 },
    ],
    rooms: [
      { id: 'r1', name: 'Classroom 1', wallIds: ['w1', 'w7', 'w5', 'w4'], center: { x: 350, y: 425 }, area: 375 },
      { id: 'r2', name: 'Classroom 2', wallIds: ['w1', 'w8', 'w5', 'w7'], center: { x: 650, y: 425 }, area: 375 },
      { id: 'r3', name: 'Classroom 3', wallIds: ['w1', 'w9', 'w5', 'w8'], center: { x: 950, y: 425 }, area: 375 },
      { id: 'r4', name: 'Classroom 4', wallIds: ['w1', 'w2', 'w5', 'w9'], center: { x: 1250, y: 425 }, area: 375 },
      { id: 'r5', name: 'Corridor', wallIds: ['w5', 'w6'], center: { x: 800, y: 600 }, area: 1200 },
      { id: 'r6', name: 'Classroom 5', wallIds: ['w6', 'w10', 'w3', 'w4'], center: { x: 350, y: 775 }, area: 375 },
      { id: 'r7', name: 'Classroom 6', wallIds: ['w6', 'w11', 'w3', 'w10'], center: { x: 650, y: 775 }, area: 375 },
      { id: 'r8', name: 'Office', wallIds: ['w6', 'w12', 'w3', 'w11'], center: { x: 950, y: 775 }, area: 375 },
      { id: 'r9', name: 'Restrooms', wallIds: ['w6', 'w2', 'w3', 'w12'], center: { x: 1250, y: 775 }, area: 375 },
    ],
  },
  estimateCategories: ['Flooring - VCT', 'Ceiling Grid', 'Drywall', 'Painting - Commercial', 'Electrical - School', 'HVAC - Classroom', 'Fire Protection', 'ADA Compliance'],
};

const CHURCH_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-church',
  name: 'Church / Worship Center',
  description: 'Sanctuary with fellowship hall, offices, and restrooms.',
  category: 'commercialChurch',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 200 }, end: { x: 1100, y: 200 }, thickness: 8, height: 180 },
      { id: 'w2', start: { x: 1100, y: 200 }, end: { x: 1100, y: 700 }, thickness: 8, height: 180 },
      { id: 'w3', start: { x: 1100, y: 700 }, end: { x: 1100, y: 1000 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 1100, y: 1000 }, end: { x: 300, y: 1000 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 300, y: 1000 }, end: { x: 300, y: 700 }, thickness: 8, height: 120 },
      { id: 'w6', start: { x: 300, y: 700 }, end: { x: 300, y: 200 }, thickness: 8, height: 180 },
      { id: 'w7', start: { x: 300, y: 700 }, end: { x: 1100, y: 700 }, thickness: 6, height: 120 },
      { id: 'w8', start: { x: 700, y: 700 }, end: { x: 700, y: 1000 }, thickness: 4, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w4', position: 0.3, width: 72, type: 'double' },
      { id: 'd2', wallId: 'w7', position: 0.5, width: 72, type: 'double' },
    ],
    rooms: [
      { id: 'r1', name: 'Sanctuary', wallIds: ['w1', 'w2', 'w7', 'w6'], center: { x: 700, y: 450 }, area: 2000 },
      { id: 'r2', name: 'Fellowship Hall', wallIds: ['w7', 'w8', 'w4', 'w5'], center: { x: 500, y: 850 }, area: 600 },
      { id: 'r3', name: 'Offices & Restrooms', wallIds: ['w7', 'w3', 'w4', 'w8'], center: { x: 900, y: 850 }, area: 600 },
    ],
  },
  estimateCategories: ['Flooring - Carpet', 'Ceiling - Acoustical', 'Sound System', 'Lighting - Sanctuary', 'HVAC - Large Space', 'Electrical - Church', 'Fire Protection', 'ADA Compliance'],
};

const APARTMENT_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-apartment',
  name: 'Apartment / Condo Building',
  description: 'Multi-family unit floor with 4 apartments, central corridor, elevator, and stairs.',
  category: 'commercialApartment',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 300 }, end: { x: 1400, y: 300 }, thickness: 8, height: 108 },
      { id: 'w2', start: { x: 1400, y: 300 }, end: { x: 1400, y: 900 }, thickness: 8, height: 108 },
      { id: 'w3', start: { x: 1400, y: 900 }, end: { x: 200, y: 900 }, thickness: 8, height: 108 },
      { id: 'w4', start: { x: 200, y: 900 }, end: { x: 200, y: 300 }, thickness: 8, height: 108 },
      { id: 'w5', start: { x: 200, y: 550 }, end: { x: 1400, y: 550 }, thickness: 6, height: 108 },
      { id: 'w6', start: { x: 200, y: 650 }, end: { x: 1400, y: 650 }, thickness: 6, height: 108 },
      { id: 'w7', start: { x: 800, y: 300 }, end: { x: 800, y: 550 }, thickness: 6, height: 108 },
      { id: 'w8', start: { x: 800, y: 650 }, end: { x: 800, y: 900 }, thickness: 6, height: 108 },
    ],
    rooms: [
      { id: 'r1', name: 'Unit A', wallIds: ['w1', 'w7', 'w5', 'w4'], center: { x: 500, y: 425 }, area: 625 },
      { id: 'r2', name: 'Unit B', wallIds: ['w1', 'w2', 'w5', 'w7'], center: { x: 1100, y: 425 }, area: 625 },
      { id: 'r3', name: 'Corridor', wallIds: ['w5', 'w6'], center: { x: 800, y: 600 }, area: 1200 },
      { id: 'r4', name: 'Unit C', wallIds: ['w6', 'w8', 'w3', 'w4'], center: { x: 500, y: 775 }, area: 625 },
      { id: 'r5', name: 'Unit D', wallIds: ['w6', 'w2', 'w3', 'w8'], center: { x: 1100, y: 775 }, area: 625 },
    ],
  },
  estimateCategories: ['Demising Walls', 'Flooring - Multi-Family', 'Plumbing - Multi-Family', 'Electrical - Multi-Family', 'HVAC - Multi-Family', 'Fire Protection - Sprinkler', 'Fire-Rated Assemblies', 'ADA - Common Areas'],
};

const HOTEL_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-hotel',
  name: 'Hotel / Motel',
  description: 'Hotel floor with guest rooms, corridor, elevator lobby, and ice/vending alcove.',
  category: 'commercialHotel',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 300 }, end: { x: 1400, y: 300 }, thickness: 8, height: 108 },
      { id: 'w2', start: { x: 1400, y: 300 }, end: { x: 1400, y: 900 }, thickness: 8, height: 108 },
      { id: 'w3', start: { x: 1400, y: 900 }, end: { x: 200, y: 900 }, thickness: 8, height: 108 },
      { id: 'w4', start: { x: 200, y: 900 }, end: { x: 200, y: 300 }, thickness: 8, height: 108 },
      { id: 'w5', start: { x: 200, y: 550 }, end: { x: 1400, y: 550 }, thickness: 6, height: 108 },
      { id: 'w6', start: { x: 200, y: 650 }, end: { x: 1400, y: 650 }, thickness: 6, height: 108 },
      { id: 'w7', start: { x: 440, y: 300 }, end: { x: 440, y: 550 }, thickness: 4, height: 108 },
      { id: 'w8', start: { x: 680, y: 300 }, end: { x: 680, y: 550 }, thickness: 4, height: 108 },
      { id: 'w9', start: { x: 920, y: 300 }, end: { x: 920, y: 550 }, thickness: 4, height: 108 },
      { id: 'w10', start: { x: 1160, y: 300 }, end: { x: 1160, y: 550 }, thickness: 4, height: 108 },
    ],
    rooms: [
      { id: 'r1', name: 'Room 101', wallIds: ['w1', 'w7', 'w5', 'w4'], center: { x: 320, y: 425 }, area: 300 },
      { id: 'r2', name: 'Room 102', wallIds: ['w1', 'w8', 'w5', 'w7'], center: { x: 560, y: 425 }, area: 300 },
      { id: 'r3', name: 'Room 103', wallIds: ['w1', 'w9', 'w5', 'w8'], center: { x: 800, y: 425 }, area: 300 },
      { id: 'r4', name: 'Room 104', wallIds: ['w1', 'w10', 'w5', 'w9'], center: { x: 1040, y: 425 }, area: 300 },
      { id: 'r5', name: 'Room 105', wallIds: ['w1', 'w2', 'w5', 'w10'], center: { x: 1280, y: 425 }, area: 300 },
      { id: 'r6', name: 'Corridor', wallIds: ['w5', 'w6'], center: { x: 800, y: 600 }, area: 1200 },
    ],
  },
  estimateCategories: ['Flooring - Hospitality', 'Plumbing - Hotel', 'Electrical - Hotel', 'HVAC - PTAC', 'Fire Protection - Sprinkler', 'Sound Insulation', 'Painting - Commercial'],
};

const GAS_STATION_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-gas-station',
  name: 'Gas Station / Convenience Store',
  description: 'Convenience store with fuel island, canopy, and site layout.',
  category: 'commercialGasStation',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 500, y: 400 }, end: { x: 1000, y: 400 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1000, y: 400 }, end: { x: 1000, y: 750 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1000, y: 750 }, end: { x: 500, y: 750 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 500, y: 750 }, end: { x: 500, y: 400 }, thickness: 8, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.5, width: 72, type: 'storefrontGlass' },
    ],
    rooms: [
      { id: 'r1', name: 'Convenience Store', wallIds: ['w1', 'w2', 'w3', 'w4'], center: { x: 750, y: 575 }, area: 875 },
    ],
  },
  sitePlan: {
    ...createEmptySitePlan(),
    symbols: [
      { id: 'sym1', type: 'fuelDispenser', position: { x: 750, y: 250 }, rotation: 0 },
      { id: 'sym2', type: 'fuelCanopy', position: { x: 750, y: 200 }, rotation: 0 },
    ],
    areaFeatures: [
      { id: 'af1', type: 'fuelIsland', points: [{ x: 600, y: 150 }, { x: 900, y: 150 }, { x: 900, y: 350 }, { x: 600, y: 350 }] },
    ],
  },
  estimateCategories: ['Fuel System', 'Canopy - Steel', 'Concrete - Site', 'Plumbing - Convenience', 'Electrical - Gas Station', 'Fire Suppression', 'Signage'],
};

const AUTO_REPAIR_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-auto-repair',
  name: 'Auto Repair / Car Wash',
  description: 'Auto repair with service bays, office, and waiting area.',
  category: 'commercialAutoRepair',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1200, y: 300 }, thickness: 8, height: 168 },
      { id: 'w2', start: { x: 1200, y: 300 }, end: { x: 1200, y: 900 }, thickness: 8, height: 168 },
      { id: 'w3', start: { x: 1200, y: 900 }, end: { x: 300, y: 900 }, thickness: 8, height: 168 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 8, height: 168 },
      { id: 'w5', start: { x: 300, y: 600 }, end: { x: 600, y: 600 }, thickness: 6, height: 108 },
      { id: 'w6', start: { x: 600, y: 300 }, end: { x: 600, y: 600 }, thickness: 6, height: 108 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.5, width: 144, type: 'overhead' },
      { id: 'd2', wallId: 'w1', position: 0.85, width: 144, type: 'overhead' },
      { id: 'd3', wallId: 'w5', position: 0.5, width: 36, type: 'single' },
    ],
    rooms: [
      { id: 'r1', name: 'Office/Waiting', wallIds: ['w1', 'w6', 'w5', 'w4'], center: { x: 450, y: 450 }, area: 450 },
      { id: 'r2', name: 'Service Bays', wallIds: ['w1', 'w2', 'w3', 'w4', 'w6', 'w5'], center: { x: 900, y: 600 }, area: 1800 },
    ],
  },
  estimateCategories: ['Overhead Doors', 'Concrete - Trench Drain', 'Plumbing - Auto Shop', 'Electrical - Auto Shop', 'HVAC - Exhaust', 'Compressed Air System', 'Lifts/Equipment'],
};

const SELF_STORAGE_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-self-storage',
  name: 'Self-Storage Facility',
  description: 'Self-storage building with rows of units, corridor, and office.',
  category: 'commercialSelfStorage',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 300 }, end: { x: 1400, y: 300 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1400, y: 300 }, end: { x: 1400, y: 900 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1400, y: 900 }, end: { x: 200, y: 900 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 200, y: 900 }, end: { x: 200, y: 300 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 200, y: 550 }, end: { x: 1400, y: 550 }, thickness: 4, height: 120 },
      { id: 'w6', start: { x: 200, y: 650 }, end: { x: 1400, y: 650 }, thickness: 4, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.1, width: 60, type: 'rollUp' },
      { id: 'd2', wallId: 'w1', position: 0.25, width: 60, type: 'rollUp' },
      { id: 'd3', wallId: 'w1', position: 0.4, width: 60, type: 'rollUp' },
      { id: 'd4', wallId: 'w1', position: 0.55, width: 60, type: 'rollUp' },
      { id: 'd5', wallId: 'w1', position: 0.7, width: 60, type: 'rollUp' },
      { id: 'd6', wallId: 'w1', position: 0.85, width: 60, type: 'rollUp' },
      { id: 'd7', wallId: 'w3', position: 0.1, width: 60, type: 'rollUp' },
      { id: 'd8', wallId: 'w3', position: 0.25, width: 60, type: 'rollUp' },
      { id: 'd9', wallId: 'w3', position: 0.4, width: 60, type: 'rollUp' },
      { id: 'd10', wallId: 'w3', position: 0.55, width: 60, type: 'rollUp' },
      { id: 'd11', wallId: 'w3', position: 0.7, width: 60, type: 'rollUp' },
      { id: 'd12', wallId: 'w3', position: 0.85, width: 60, type: 'rollUp' },
    ],
    rooms: [
      { id: 'r1', name: 'Units Row A (5x10)', wallIds: ['w1', 'w5'], center: { x: 800, y: 425 }, area: 3000 },
      { id: 'r2', name: 'Drive Aisle', wallIds: ['w5', 'w6'], center: { x: 800, y: 600 }, area: 1200 },
      { id: 'r3', name: 'Units Row B (5x10)', wallIds: ['w6', 'w3'], center: { x: 800, y: 775 }, area: 3000 },
    ],
  },
  estimateCategories: ['Roll-Up Doors', 'Metal Building', 'Concrete Slab', 'Electrical - Storage', 'Security System', 'Climate Control'],
};

const GYM_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-gym',
  name: 'Gym / Fitness Center',
  description: 'Fitness center with equipment floor, locker rooms, studios, and front desk.',
  category: 'commercialGym',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1300, y: 300 }, thickness: 8, height: 144 },
      { id: 'w2', start: { x: 1300, y: 300 }, end: { x: 1300, y: 900 }, thickness: 8, height: 144 },
      { id: 'w3', start: { x: 1300, y: 900 }, end: { x: 300, y: 900 }, thickness: 8, height: 144 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 8, height: 144 },
      { id: 'w5', start: { x: 900, y: 300 }, end: { x: 900, y: 600 }, thickness: 6, height: 144 },
      { id: 'w6', start: { x: 900, y: 600 }, end: { x: 1300, y: 600 }, thickness: 6, height: 144 },
      { id: 'w7', start: { x: 300, y: 700 }, end: { x: 600, y: 700 }, thickness: 4, height: 144 },
      { id: 'w8', start: { x: 600, y: 700 }, end: { x: 600, y: 900 }, thickness: 4, height: 144 },
    ],
    rooms: [
      { id: 'r1', name: 'Equipment Floor', wallIds: ['w1', 'w5', 'w6', 'w2', 'w3', 'w7', 'w4'], center: { x: 600, y: 500 }, area: 2400 },
      { id: 'r2', name: 'Studio', wallIds: ['w1', 'w2', 'w6', 'w5'], center: { x: 1100, y: 450 }, area: 600 },
      { id: 'r3', name: 'Locker Room - M', wallIds: ['w7', 'w8', 'w3', 'w4'], center: { x: 450, y: 800 }, area: 300 },
      { id: 'r4', name: 'Locker Room - F', wallIds: ['w8', 'w3'], center: { x: 750, y: 800 }, area: 300 },
    ],
  },
  estimateCategories: ['Flooring - Rubber', 'Mirrors', 'Plumbing - Locker Room', 'HVAC - Large Space', 'Electrical - Gym', 'Sound System', 'Fire Protection'],
};

const BANK_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-bank',
  name: 'Bank / Credit Union',
  description: 'Bank branch with teller line, vault, offices, and drive-through.',
  category: 'commercialBank',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 400, y: 400 }, end: { x: 1100, y: 400 }, thickness: 8, height: 120 },
      { id: 'w2', start: { x: 1100, y: 400 }, end: { x: 1100, y: 850 }, thickness: 8, height: 120 },
      { id: 'w3', start: { x: 1100, y: 850 }, end: { x: 400, y: 850 }, thickness: 8, height: 120 },
      { id: 'w4', start: { x: 400, y: 850 }, end: { x: 400, y: 400 }, thickness: 8, height: 120 },
      { id: 'w5', start: { x: 400, y: 630 }, end: { x: 800, y: 630 }, thickness: 4, height: 48 },
      { id: 'w6', start: { x: 900, y: 400 }, end: { x: 900, y: 630 }, thickness: 12, height: 120 },
      { id: 'w7', start: { x: 900, y: 630 }, end: { x: 1100, y: 630 }, thickness: 12, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w1', position: 0.35, width: 72, type: 'storefrontGlass' },
      { id: 'd2', wallId: 'w7', position: 0.5, width: 36, type: 'single' },
    ],
    fixtures: [
      { id: 'fx1', position: { x: 500, y: 660 }, type: 'tellerWindow', rotation: 0 },
      { id: 'fx2', position: { x: 600, y: 660 }, type: 'tellerWindow', rotation: 0 },
      { id: 'fx3', position: { x: 700, y: 660 }, type: 'tellerWindow', rotation: 0 },
    ],
    rooms: [
      { id: 'r1', name: 'Lobby', wallIds: ['w1', 'w5', 'w3', 'w4'], center: { x: 600, y: 500 }, area: 500 },
      { id: 'r2', name: 'Teller Area', wallIds: ['w5', 'w6', 'w7', 'w2', 'w3'], center: { x: 700, y: 740 }, area: 400 },
      { id: 'r3', name: 'Vault', wallIds: ['w6', 'w1', 'w2', 'w7'], center: { x: 1000, y: 515 }, area: 230 },
    ],
  },
  estimateCategories: ['Vault Construction', 'Bullet-Resistant Glass', 'Teller Counters', 'Security System', 'Electrical - Bank', 'HVAC - Commercial', 'Fire Protection'],
};

const DATA_CENTER_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-data-center',
  name: 'Data Center / Server Room',
  description: 'Data center with server rows, cooling, electrical room, and UPS room.',
  category: 'commercialDataCenter',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 300, y: 300 }, end: { x: 1300, y: 300 }, thickness: 8, height: 144 },
      { id: 'w2', start: { x: 1300, y: 300 }, end: { x: 1300, y: 900 }, thickness: 8, height: 144 },
      { id: 'w3', start: { x: 1300, y: 900 }, end: { x: 300, y: 900 }, thickness: 8, height: 144 },
      { id: 'w4', start: { x: 300, y: 900 }, end: { x: 300, y: 300 }, thickness: 8, height: 144 },
      { id: 'w5', start: { x: 300, y: 700 }, end: { x: 600, y: 700 }, thickness: 6, height: 144 },
      { id: 'w6', start: { x: 600, y: 700 }, end: { x: 600, y: 900 }, thickness: 6, height: 144 },
      { id: 'w7', start: { x: 1000, y: 700 }, end: { x: 1300, y: 700 }, thickness: 6, height: 144 },
      { id: 'w8', start: { x: 1000, y: 700 }, end: { x: 1000, y: 900 }, thickness: 6, height: 144 },
    ],
    fixtures: [
      { id: 'fx1', position: { x: 500, y: 400 }, type: 'serverRack', rotation: 0 },
      { id: 'fx2', position: { x: 650, y: 400 }, type: 'serverRack', rotation: 0 },
      { id: 'fx3', position: { x: 800, y: 400 }, type: 'serverRack', rotation: 0 },
      { id: 'fx4', position: { x: 950, y: 400 }, type: 'serverRack', rotation: 0 },
      { id: 'fx5', position: { x: 500, y: 550 }, type: 'serverRack', rotation: 0 },
      { id: 'fx6', position: { x: 650, y: 550 }, type: 'serverRack', rotation: 0 },
      { id: 'fx7', position: { x: 800, y: 550 }, type: 'serverRack', rotation: 0 },
      { id: 'fx8', position: { x: 950, y: 550 }, type: 'serverRack', rotation: 0 },
      { id: 'fx9', position: { x: 1200, y: 400 }, type: 'raisedFloorTile', rotation: 0 },
    ],
    rooms: [
      { id: 'r1', name: 'Server Hall', wallIds: ['w1', 'w2', 'w7', 'w8', 'w3', 'w6', 'w5', 'w4'], center: { x: 800, y: 500 }, area: 3000 },
      { id: 'r2', name: 'Electrical/UPS Room', wallIds: ['w5', 'w6', 'w3', 'w4'], center: { x: 450, y: 800 }, area: 300 },
      { id: 'r3', name: 'Cooling Plant', wallIds: ['w7', 'w2', 'w3', 'w8'], center: { x: 1150, y: 800 }, area: 300 },
    ],
  },
  estimateCategories: ['Raised Floor', 'Cooling - Precision', 'Electrical - Data Center', 'UPS System', 'Generator', 'Fire Suppression - Clean Agent', 'Cable Tray', 'Security - Biometric'],
};

const INDUSTRIAL_TEMPLATE: SketchTemplate = {
  id: 'tmpl-commercial-industrial',
  name: 'Industrial / Manufacturing',
  description: 'Industrial building with production floor, offices, loading dock, and break room.',
  category: 'commercialIndustrial',
  thumbnail: '',
  floorPlan: {
    ...createEmptyFloorPlan(),
    walls: [
      { id: 'w1', start: { x: 200, y: 200 }, end: { x: 1400, y: 200 }, thickness: 12, height: 240 },
      { id: 'w2', start: { x: 1400, y: 200 }, end: { x: 1400, y: 1000 }, thickness: 12, height: 240 },
      { id: 'w3', start: { x: 1400, y: 1000 }, end: { x: 200, y: 1000 }, thickness: 12, height: 240 },
      { id: 'w4', start: { x: 200, y: 1000 }, end: { x: 200, y: 200 }, thickness: 12, height: 240 },
      { id: 'w5', start: { x: 200, y: 400 }, end: { x: 500, y: 400 }, thickness: 6, height: 120 },
      { id: 'w6', start: { x: 500, y: 200 }, end: { x: 500, y: 400 }, thickness: 6, height: 120 },
      { id: 'w7', start: { x: 200, y: 800 }, end: { x: 500, y: 800 }, thickness: 6, height: 120 },
      { id: 'w8', start: { x: 500, y: 800 }, end: { x: 500, y: 1000 }, thickness: 6, height: 120 },
    ],
    doors: [
      { id: 'd1', wallId: 'w2', position: 0.2, width: 144, type: 'rollUp' },
      { id: 'd2', wallId: 'w2', position: 0.5, width: 144, type: 'rollUp' },
      { id: 'd3', wallId: 'w2', position: 0.8, width: 144, type: 'rollUp' },
      { id: 'd4', wallId: 'w5', position: 0.5, width: 36, type: 'single' },
      { id: 'd5', wallId: 'w7', position: 0.5, width: 36, type: 'single' },
    ],
    rooms: [
      { id: 'r1', name: 'Offices', wallIds: ['w1', 'w6', 'w5', 'w4'], center: { x: 350, y: 300 }, area: 300 },
      { id: 'r2', name: 'Production Floor', wallIds: ['w1', 'w2', 'w3', 'w4'], center: { x: 950, y: 600 }, area: 7200 },
      { id: 'r3', name: 'Break Room', wallIds: ['w7', 'w8', 'w3', 'w4'], center: { x: 350, y: 900 }, area: 300 },
    ],
  },
  estimateCategories: ['Concrete - Industrial Slab', 'Steel Structure', 'Overhead Crane', 'Dock Doors', 'HVAC - Industrial', 'Electrical - Industrial', 'Compressed Air', 'Fire Protection - Industrial'],
};

// ── Public API ──

export const BUILT_IN_TEMPLATES: SketchTemplate[] = [
  // Residential
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
  // Commercial
  OFFICE_TEMPLATE,
  STRIP_MALL_TEMPLATE,
  WAREHOUSE_TEMPLATE,
  RESTAURANT_TEMPLATE,
  MEDICAL_OFFICE_TEMPLATE,
  SCHOOL_TEMPLATE,
  CHURCH_TEMPLATE,
  APARTMENT_TEMPLATE,
  HOTEL_TEMPLATE,
  GAS_STATION_TEMPLATE,
  AUTO_REPAIR_TEMPLATE,
  SELF_STORAGE_TEMPLATE,
  GYM_TEMPLATE,
  BANK_TEMPLATE,
  DATA_CENTER_TEMPLATE,
  INDUSTRIAL_TEMPLATE,
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
