// System Inspection Templates — Seed Data
// These are Dart constants used as starting points for companies.
// When a company selects a system template, it gets cloned to their
// inspection_templates table with their company_id.
//
// Covers all 13 inspector types from research.

import '../models/inspection.dart';

final List<InspectionTemplate> systemInspectionTemplates = [
  // ============================================================
  // PROPERTY MANAGEMENT
  // ============================================================

  InspectionTemplate(
    id: 'system-move-in',
    name: 'Move-In Inspection',
    trade: 'property_management',
    inspectionType: InspectionType.moveIn,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Exterior', sortOrder: 0, items: [
        TemplateItem(name: 'Front door condition', sortOrder: 0),
        TemplateItem(name: 'Locks and keys working', sortOrder: 1),
        TemplateItem(name: 'Windows — exterior condition', sortOrder: 2),
        TemplateItem(name: 'Siding / paint condition', sortOrder: 3),
        TemplateItem(name: 'Walkway / driveway condition', sortOrder: 4),
        TemplateItem(name: 'Landscaping / yard', sortOrder: 5),
        TemplateItem(name: 'Mailbox', sortOrder: 6),
      ]),
      TemplateSection(name: 'Kitchen', sortOrder: 1, items: [
        TemplateItem(name: 'Countertops', sortOrder: 0),
        TemplateItem(name: 'Cabinets — doors and drawers', sortOrder: 1),
        TemplateItem(name: 'Sink and faucet', sortOrder: 2),
        TemplateItem(name: 'Garbage disposal', sortOrder: 3),
        TemplateItem(name: 'Dishwasher', sortOrder: 4),
        TemplateItem(name: 'Range / oven', sortOrder: 5),
        TemplateItem(name: 'Refrigerator', sortOrder: 6),
        TemplateItem(name: 'Microwave', sortOrder: 7),
        TemplateItem(name: 'Flooring', sortOrder: 8),
        TemplateItem(name: 'Walls and ceiling', sortOrder: 9),
        TemplateItem(name: 'Light fixtures', sortOrder: 10),
        TemplateItem(name: 'Outlets working', sortOrder: 11),
      ]),
      TemplateSection(name: 'Living Areas', sortOrder: 2, items: [
        TemplateItem(name: 'Flooring / carpet', sortOrder: 0),
        TemplateItem(name: 'Walls — paint / condition', sortOrder: 1),
        TemplateItem(name: 'Ceiling — condition', sortOrder: 2),
        TemplateItem(name: 'Windows — interior', sortOrder: 3),
        TemplateItem(name: 'Window coverings / blinds', sortOrder: 4),
        TemplateItem(name: 'Light fixtures and switches', sortOrder: 5),
        TemplateItem(name: 'Outlets working', sortOrder: 6),
        TemplateItem(name: 'Closets — doors and shelving', sortOrder: 7),
        TemplateItem(name: 'Smoke detectors', sortOrder: 8),
        TemplateItem(name: 'CO detectors', sortOrder: 9),
      ]),
      TemplateSection(name: 'Bathroom(s)', sortOrder: 3, items: [
        TemplateItem(name: 'Toilet — flush and seal', sortOrder: 0),
        TemplateItem(name: 'Sink and faucet', sortOrder: 1),
        TemplateItem(name: 'Bathtub / shower', sortOrder: 2),
        TemplateItem(name: 'Shower head', sortOrder: 3),
        TemplateItem(name: 'Tile / grout condition', sortOrder: 4),
        TemplateItem(name: 'Caulking', sortOrder: 5),
        TemplateItem(name: 'Exhaust fan', sortOrder: 6),
        TemplateItem(name: 'Towel bars / accessories', sortOrder: 7),
        TemplateItem(name: 'Mirror and medicine cabinet', sortOrder: 8),
        TemplateItem(name: 'Flooring', sortOrder: 9),
      ]),
      TemplateSection(name: 'Systems', sortOrder: 4, items: [
        TemplateItem(name: 'HVAC — heating test', sortOrder: 0),
        TemplateItem(name: 'HVAC — cooling test', sortOrder: 1),
        TemplateItem(name: 'Water heater', sortOrder: 2),
        TemplateItem(name: 'Electrical panel', sortOrder: 3),
        TemplateItem(name: 'Plumbing — no leaks', sortOrder: 4),
        TemplateItem(name: 'Garage door opener', sortOrder: 5),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // SAFETY / OSHA
  // ============================================================

  InspectionTemplate(
    id: 'system-osha-safety',
    name: 'OSHA Job Site Safety',
    trade: 'general',
    inspectionType: InspectionType.safety,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Fall Protection', sortOrder: 0, items: [
        TemplateItem(name: 'Guardrails at 6ft+ elevations', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Safety nets where required', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Personal fall arrest systems in use', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Floor holes covered / guarded', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Ladder safety — 3-point contact', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Scaffolding', sortOrder: 1, items: [
        TemplateItem(name: 'Scaffold on stable base', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Guardrails on all open sides', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Planks secured and not overloaded', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Access ladder provided', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Electrical', sortOrder: 2, items: [
        TemplateItem(name: 'GFCI protection for all temporary power', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Cords not damaged / properly rated', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Lockout/tagout procedures followed', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Temporary panels labeled', sortOrder: 3, weight: 1),
      ]),
      TemplateSection(name: 'Excavation', sortOrder: 3, items: [
        TemplateItem(name: 'Trench shoring in place (4ft+)', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Spoil pile 2ft+ from edge', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Means of egress every 25ft', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Utilities located and marked', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'PPE & Housekeeping', sortOrder: 4, items: [
        TemplateItem(name: 'Hard hats worn in active areas', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Eye protection available and used', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Hi-vis vests near traffic', sortOrder: 2, weight: 1),
        TemplateItem(name: 'Work area clean and organized', sortOrder: 3, weight: 1),
        TemplateItem(name: 'Fire extinguisher accessible', sortOrder: 4, weight: 2),
        TemplateItem(name: 'First aid kit stocked', sortOrder: 5, weight: 1),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // ELECTRICAL (NEC)
  // ============================================================

  InspectionTemplate(
    id: 'system-electrical-rough',
    name: 'Electrical Rough-In',
    trade: 'electrical',
    inspectionType: InspectionType.roughIn,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Service & Panel', sortOrder: 0, items: [
        TemplateItem(name: 'Service size adequate per load calc', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Panel accessible (30x36 clear)', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Grounding electrode system', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Main bonding jumper', sortOrder: 3, weight: 3),
      ]),
      TemplateSection(name: 'Branch Circuits', sortOrder: 1, items: [
        TemplateItem(name: 'Wire sizing matches breaker', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Box fill calculations', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Boxes secured and accessible', sortOrder: 2, weight: 2),
        TemplateItem(name: 'NM cable properly stapled (12" / 4.5ft)', sortOrder: 3, weight: 1),
        TemplateItem(name: 'Nail plates where within 1.25" of edge', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'AFCI / GFCI', sortOrder: 2, items: [
        TemplateItem(name: 'AFCI protection — bedrooms (210.12)', sortOrder: 0, weight: 3),
        TemplateItem(name: 'AFCI protection — living areas (210.12)', sortOrder: 1, weight: 3),
        TemplateItem(name: 'GFCI — bathrooms (210.8)', sortOrder: 2, weight: 3),
        TemplateItem(name: 'GFCI — kitchen countertop (210.8)', sortOrder: 3, weight: 3),
        TemplateItem(name: 'GFCI — garage (210.8)', sortOrder: 4, weight: 3),
        TemplateItem(name: 'GFCI — exterior (210.8)', sortOrder: 5, weight: 3),
        TemplateItem(name: 'GFCI — laundry (210.8)', sortOrder: 6, weight: 2),
      ]),
      TemplateSection(name: 'Smoke & CO', sortOrder: 3, items: [
        TemplateItem(name: 'Smoke detectors — each bedroom', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Smoke detectors — hallway outside bedrooms', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Smoke detectors — each level', sortOrder: 2, weight: 3),
        TemplateItem(name: 'CO detectors per local code', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Interconnected (hardwired)', sortOrder: 4, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // ROOFING (DAMAGE ASSESSMENT)
  // ============================================================

  InspectionTemplate(
    id: 'system-roofing-damage',
    name: 'Roofing Damage Assessment',
    trade: 'roofing',
    inspectionType: InspectionType.roofing,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Exterior Overview', sortOrder: 0, items: [
        TemplateItem(name: 'Roof type and material', sortOrder: 0),
        TemplateItem(name: 'Approximate age of roof', sortOrder: 1),
        TemplateItem(name: 'Number of layers', sortOrder: 2),
        TemplateItem(name: 'Overall condition (pre-damage)', sortOrder: 3),
      ]),
      TemplateSection(name: 'Damage Assessment', sortOrder: 1, items: [
        TemplateItem(name: 'Hail damage — shingles', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Wind damage — lifted/missing shingles', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Debris impact damage', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Granule loss pattern', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Cracking / splitting', sortOrder: 4, weight: 2),
        TemplateItem(name: 'Number of damaged shingles per test square', sortOrder: 5, weight: 3),
      ]),
      TemplateSection(name: 'Penetrations & Flashings', sortOrder: 2, items: [
        TemplateItem(name: 'Ridge cap condition', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Pipe boots / jack flashings', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Valley flashings', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Chimney flashing', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Vent caps / turbines', sortOrder: 4, weight: 1),
        TemplateItem(name: 'Skylight seals', sortOrder: 5, weight: 2),
      ]),
      TemplateSection(name: 'Gutters & Drainage', sortOrder: 3, items: [
        TemplateItem(name: 'Gutter damage / dents', sortOrder: 0, weight: 1),
        TemplateItem(name: 'Downspout damage', sortOrder: 1, weight: 1),
        TemplateItem(name: 'Fascia / soffit damage', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Drip edge condition', sortOrder: 3, weight: 1),
      ]),
      TemplateSection(name: 'Interior Evidence', sortOrder: 4, items: [
        TemplateItem(name: 'Water stains on ceiling', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Active leaks', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Attic — daylight visible', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Attic — moisture / mold', sortOrder: 3, weight: 3),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // FIRE / LIFE SAFETY
  // ============================================================

  InspectionTemplate(
    id: 'system-fire-safety',
    name: 'Fire & Life Safety',
    trade: 'fire_protection',
    inspectionType: InspectionType.fireLifeSafety,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Fire Alarm System', sortOrder: 0, items: [
        TemplateItem(name: 'Panel in normal condition', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Pull stations accessible and tested', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Smoke detectors functional', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Horn/strobe devices functional', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Monitoring service active', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Sprinkler System', sortOrder: 1, items: [
        TemplateItem(name: 'Gauges in normal range', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Valve positions correct (open)', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Sprinkler heads — no paint/damage', sortOrder: 2, weight: 2),
        TemplateItem(name: '18" clearance below heads', sortOrder: 3, weight: 2),
        TemplateItem(name: 'FDC accessible and capped', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Means of Egress', sortOrder: 2, items: [
        TemplateItem(name: 'Exit signs illuminated', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Emergency lighting functional', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Exit paths clear / unobstructed', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Fire doors — self-closing, latching', sortOrder: 3, weight: 3),
        TemplateItem(name: 'Stairwell doors not propped open', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Extinguishers', sortOrder: 3, items: [
        TemplateItem(name: 'Proper type for area (A/B/C/K)', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Mounted and accessible', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Current annual inspection tag', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Pressure gauge in green', sortOrder: 3, weight: 1),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // PLUMBING ROUGH-IN
  // ============================================================

  InspectionTemplate(
    id: 'system-plumbing-rough',
    name: 'Plumbing Rough-In',
    trade: 'plumbing',
    inspectionType: InspectionType.roughIn,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Water Supply', sortOrder: 0, items: [
        TemplateItem(name: 'Pipe material approved', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Proper sizing per fixture count', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Pressure test passed (no leaks)', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Shutoff valves accessible', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Hot/cold properly marked', sortOrder: 4, weight: 1),
      ]),
      TemplateSection(name: 'Drain/Waste/Vent (DWV)', sortOrder: 1, items: [
        TemplateItem(name: 'Proper slope (1/4" per foot min)', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Vent termination above roofline', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Cleanouts accessible', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Trap arms within code distance', sortOrder: 3, weight: 2),
        TemplateItem(name: 'DWV test passed (water/air)', sortOrder: 4, weight: 3),
      ]),
      TemplateSection(name: 'Gas Piping', sortOrder: 2, items: [
        TemplateItem(name: 'Gas test passed (no pressure drop)', sortOrder: 0, weight: 3),
        TemplateItem(name: 'CSST properly bonded', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Shutoff valves at each appliance', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Pipe properly supported', sortOrder: 3, weight: 1),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // HVAC
  // ============================================================

  InspectionTemplate(
    id: 'system-hvac-rough',
    name: 'HVAC Rough-In',
    trade: 'hvac',
    inspectionType: InspectionType.hvac,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Ductwork', sortOrder: 0, items: [
        TemplateItem(name: 'Duct sizing per Manual D', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Connections sealed (mastic/tape)', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Duct leakage test passed (IECC)', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Supply/return properly located', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Insulation on unconditioned ducts', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Equipment', sortOrder: 1, items: [
        TemplateItem(name: 'Equipment sized per Manual J/S', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Clearances per manufacturer', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Condensate drain properly routed', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Refrigerant lines insulated', sortOrder: 3, weight: 1),
        TemplateItem(name: 'Disconnect switch at equipment', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Ventilation', sortOrder: 2, items: [
        TemplateItem(name: 'Bath fans vented to exterior', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Range hood vented (if required)', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Fresh air intake per code', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Combustion air provided', sortOrder: 3, weight: 3),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // FOUNDATION
  // ============================================================

  InspectionTemplate(
    id: 'system-foundation',
    name: 'Foundation Inspection',
    trade: 'general',
    inspectionType: InspectionType.foundation,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Excavation & Soil', sortOrder: 0, items: [
        TemplateItem(name: 'Footing depth per plans', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Undisturbed soil / proper bearing', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Drainage provisions', sortOrder: 2, weight: 2),
      ]),
      TemplateSection(name: 'Reinforcement', sortOrder: 1, items: [
        TemplateItem(name: 'Rebar size and spacing per plans', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Rebar clearance (3" from soil)', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Dowels for walls properly placed', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Anchor bolt placement', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Forms & Layout', sortOrder: 2, items: [
        TemplateItem(name: 'Dimensions match plans', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Forms plumb and level', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Footing width per plans', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Step footings properly formed', sortOrder: 3, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // FRAMING
  // ============================================================

  InspectionTemplate(
    id: 'system-framing',
    name: 'Framing Inspection',
    trade: 'general',
    inspectionType: InspectionType.framing,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Structural', sortOrder: 0, items: [
        TemplateItem(name: 'Headers sized per span tables', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Bearing walls properly supported', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Floor joists — size/spacing per plans', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Rafters / trusses per plans', sortOrder: 3, weight: 3),
        TemplateItem(name: 'Sheathing nailing pattern', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Connections', sortOrder: 1, items: [
        TemplateItem(name: 'Hold-downs and straps installed', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Hurricane ties at roof-to-wall', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Anchor bolts — spacing and edge distance', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Joist hangers properly sized and nailed', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Fire Blocking', sortOrder: 2, items: [
        TemplateItem(name: 'Fire blocking at floor/ceiling transitions', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Fire blocking in soffits/chases', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Draft stopping in attic (where required)', sortOrder: 2, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // ENVIRONMENTAL / SWPPP
  // ============================================================

  InspectionTemplate(
    id: 'system-swppp',
    name: 'SWPPP Site Inspection',
    trade: 'general',
    inspectionType: InspectionType.swppp,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Erosion Controls', sortOrder: 0, items: [
        TemplateItem(name: 'Silt fence intact and functional', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Sediment basins/traps functional', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Check dams in place', sortOrder: 2, weight: 1),
        TemplateItem(name: 'Inlet protection devices intact', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Stabilized construction entrance', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Sediment Controls', sortOrder: 1, items: [
        TemplateItem(name: 'No sediment leaving site', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Streets clean of tracked sediment', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Dewatering properly managed', sortOrder: 2, weight: 2),
      ]),
      TemplateSection(name: 'Good Housekeeping', sortOrder: 2, items: [
        TemplateItem(name: 'Waste properly contained', sortOrder: 0, weight: 1),
        TemplateItem(name: 'No fuel/chemical spills', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Material storage covered', sortOrder: 2, weight: 1),
        TemplateItem(name: 'Concrete washout contained', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Portable toilets properly placed', sortOrder: 4, weight: 1),
      ]),
      TemplateSection(name: 'Stabilization', sortOrder: 3, items: [
        TemplateItem(name: 'Disturbed areas stabilized within 14 days', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Permanent seeding/sodding where complete', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Temporary seeding / mulch on idle areas', sortOrder: 2, weight: 1),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // ADA ACCESSIBILITY
  // ============================================================

  InspectionTemplate(
    id: 'system-ada',
    name: 'ADA Accessibility Survey',
    trade: 'general',
    inspectionType: InspectionType.ada,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Parking', sortOrder: 0, items: [
        TemplateItem(name: 'Correct number of accessible spaces', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Van-accessible space with 8ft aisle', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Signage with ISA symbol', sortOrder: 2, weight: 1),
        TemplateItem(name: 'Surface firm and level (max 2% slope)', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Entrance', sortOrder: 1, items: [
        TemplateItem(name: 'Accessible route from parking', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Door clearance (32" min clear)', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Door hardware operable with one hand', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Threshold max 1/2"', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Ramp slope max 1:12', sortOrder: 4, weight: 3),
      ]),
      TemplateSection(name: 'Interior', sortOrder: 2, items: [
        TemplateItem(name: 'Route width 36" minimum', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Protruding objects (max 4" from wall)', sortOrder: 1, weight: 2),
        TemplateItem(name: 'Floor surfaces firm and stable', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Controls and switches 48" max height', sortOrder: 3, weight: 1),
      ]),
      TemplateSection(name: 'Restrooms', sortOrder: 3, items: [
        TemplateItem(name: 'Turning space 60" diameter', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Grab bars — side and rear', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Toilet seat height 17-19"', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Lavatory clearance (27" knee, 34" max rim)', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Mirror max 40" to bottom edge', sortOrder: 4, weight: 1),
        TemplateItem(name: 'Faucet operable with one hand', sortOrder: 5, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // INSURANCE DAMAGE / TPI
  // ============================================================

  InspectionTemplate(
    id: 'system-insurance-damage',
    name: 'Insurance Damage Assessment',
    trade: 'restoration',
    inspectionType: InspectionType.insuranceDamage,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Damage Overview', sortOrder: 0, items: [
        TemplateItem(name: 'Type of loss (water/fire/wind/hail)', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Date of loss', sortOrder: 1),
        TemplateItem(name: 'Affected areas identified', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Category of water damage (1/2/3)', sortOrder: 3, weight: 2),
        TemplateItem(name: 'Class of water damage (1-4)', sortOrder: 4, weight: 2),
      ]),
      TemplateSection(name: 'Documentation', sortOrder: 1, items: [
        TemplateItem(name: 'Wide shots of all affected rooms', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Close-up shots of damage points', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Moisture readings recorded', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Measurements accurate within 2"', sortOrder: 3, weight: 3),
      ]),
      TemplateSection(name: 'Scope Verification', sortOrder: 2, items: [
        TemplateItem(name: 'Scope matches carrier-approved estimate', sortOrder: 0, weight: 3),
        TemplateItem(name: 'No unauthorized work performed', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Materials match specification', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Work quality meets standards', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Completion', sortOrder: 3, items: [
        TemplateItem(name: 'All line items addressed', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Final moisture readings normal', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Homeowner satisfied', sortOrder: 2, weight: 1),
        TemplateItem(name: 'Certificate of completion signed', sortOrder: 3, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),

  // ============================================================
  // QC HOLD POINT
  // ============================================================

  InspectionTemplate(
    id: 'system-qc-holdpoint',
    name: 'QC Hold Point — General',
    trade: 'general',
    inspectionType: InspectionType.qcHoldPoint,
    isSystem: true,
    version: 1,
    sections: [
      TemplateSection(name: 'Pre-Work Verification', sortOrder: 0, items: [
        TemplateItem(name: 'Materials match specification', sortOrder: 0, weight: 2),
        TemplateItem(name: 'Tools and equipment ready', sortOrder: 1, weight: 1),
        TemplateItem(name: 'Previous work stage accepted', sortOrder: 2, weight: 3),
        TemplateItem(name: 'Safety measures in place', sortOrder: 3, weight: 2),
      ]),
      TemplateSection(name: 'Work Quality', sortOrder: 1, items: [
        TemplateItem(name: 'Workmanship meets standards', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Dimensions within tolerance', sortOrder: 1, weight: 2),
        TemplateItem(name: 'No visible defects', sortOrder: 2, weight: 2),
        TemplateItem(name: 'Matches approved drawings', sortOrder: 3, weight: 3),
      ]),
      TemplateSection(name: 'Hold Point Decision', sortOrder: 2, items: [
        TemplateItem(name: 'Cleared to proceed to next stage', sortOrder: 0, weight: 3),
        TemplateItem(name: 'Corrective work required', sortOrder: 1, weight: 3),
        TemplateItem(name: 'Re-inspection needed', sortOrder: 2, weight: 2),
      ]),
    ],
    createdAt: _epoch,
    updatedAt: _epoch,
  ),
];

// Sentinel epoch for system templates (not stored in DB, used as const)
final _epoch = DateTime.utc(2026, 1, 1);
