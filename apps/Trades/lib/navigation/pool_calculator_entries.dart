import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// POOL/SPA CALCULATOR IMPORTS (51 screens)
// ============================================================================
import '../screens/calculators/pool/rectangular_pool_volume_screen.dart';
import '../screens/calculators/pool/circular_pool_volume_screen.dart';
import '../screens/calculators/pool/oval_pool_volume_screen.dart';
import '../screens/calculators/pool/spa_volume_screen.dart';
import '../screens/calculators/pool/chlorine_dose_screen.dart';
import '../screens/calculators/pool/ph_adjustment_screen.dart';
import '../screens/calculators/pool/pump_sizing_screen.dart';
import '../screens/calculators/pool/heater_btu_screen.dart';
import '../screens/calculators/pool/salt_calculator_screen.dart';
import '../screens/calculators/pool/filter_size_screen.dart';
import '../screens/calculators/pool/turnover_time_screen.dart';
import '../screens/calculators/pool/alkalinity_adjustment_screen.dart';
import '../screens/calculators/pool/calcium_hardness_screen.dart';
import '../screens/calculators/pool/stabilizer_cya_screen.dart';
import '../screens/calculators/pool/shock_treatment_screen.dart';
import '../screens/calculators/pool/heat_pump_sizing_screen.dart';
import '../screens/calculators/pool/solar_heater_sizing_screen.dart';
import '../screens/calculators/pool/saturation_index_screen.dart';
import '../screens/calculators/pool/waterfall_flow_screen.dart';
import '../screens/calculators/pool/head_loss_screen.dart';
import '../screens/calculators/pool/gunite_calculator_screen.dart';
import '../screens/calculators/pool/plaster_calculator_screen.dart';
import '../screens/calculators/pool/tile_calculator_screen.dart';
import '../screens/calculators/pool/coping_calculator_screen.dart';
import '../screens/calculators/pool/excavation_calculator_screen.dart';
import '../screens/calculators/pool/deck_area_screen.dart';
import '../screens/calculators/pool/liner_size_screen.dart';
import '../screens/calculators/pool/evaporation_loss_screen.dart';
import '../screens/calculators/pool/bromine_calculator_screen.dart';
import '../screens/calculators/pool/skimmer_calculator_screen.dart';
import '../screens/calculators/pool/return_inlet_screen.dart';
import '../screens/calculators/pool/gallons_to_liters_screen.dart';
import '../screens/calculators/pool/pipe_size_pool_screen.dart';
import '../screens/calculators/pool/algaecide_dosing_screen.dart';
import '../screens/calculators/pool/rebar_calculator_screen.dart';
import '../screens/calculators/pool/time_to_heat_screen.dart';
import '../screens/calculators/pool/kidney_pool_volume_screen.dart';
import '../screens/calculators/pool/variable_depth_screen.dart';
import '../screens/calculators/pool/fountain_pump_screen.dart';
import '../screens/calculators/pool/spillover_spa_screen.dart';
import '../screens/calculators/pool/phosphate_remover_screen.dart';
import '../screens/calculators/pool/metal_sequestrant_screen.dart';
import '../screens/calculators/pool/cover_savings_screen.dart';
import '../screens/calculators/pool/gas_cost_screen.dart';
import '../screens/calculators/pool/main_drain_screen.dart';
import '../screens/calculators/pool/heat_loss_pool_screen.dart';
import '../screens/calculators/pool/electrical_load_pool_screen.dart';
import '../screens/calculators/pool/backwash_calculator_screen.dart';
import '../screens/calculators/pool/automation_panel_screen.dart';
import '../screens/calculators/pool/led_pool_lighting_screen.dart';

// ============================================================================
// POOL/SPA CALCULATOR ENTRIES (51 screens)
// ============================================================================

class PoolCalculatorEntries {
  PoolCalculatorEntries._();

  static final List<ScreenEntry> poolCalculators = [
    // =========================================================================
    // VOLUME CALCULATORS
    // =========================================================================
    ScreenEntry(
      id: 'pool_rectangular_volume',
      name: 'Rectangular Pool Volume',
      subtitle: 'Calculate gallons for rectangular pools',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'volume', 'gallons', 'rectangular', 'capacity'],
      builder: () => const RectangularPoolVolumeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_circular_volume',
      name: 'Circular Pool Volume',
      subtitle: 'Calculate gallons for round pools',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'volume', 'gallons', 'circular', 'round', 'capacity'],
      builder: () => const CircularPoolVolumeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_oval_volume',
      name: 'Oval Pool Volume',
      subtitle: 'Calculate gallons for oval pools',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'volume', 'gallons', 'oval', 'ellipse', 'capacity'],
      builder: () => const OvalPoolVolumeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_kidney_volume',
      name: 'Kidney Pool Volume',
      subtitle: 'Calculate gallons for kidney-shaped pools',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'volume', 'gallons', 'kidney', 'freeform', 'capacity'],
      builder: () => const KidneyPoolVolumeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_variable_depth',
      name: 'Variable Depth Volume',
      subtitle: 'Calculate volume with varying depths',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'volume', 'depth', 'slope', 'variable', 'deep end'],
      builder: () => const VariableDepthScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_spa_volume',
      name: 'Spa/Hot Tub Volume',
      subtitle: 'Calculate gallons for spas and hot tubs',
      icon: LucideIcons.sparkles,
      category: ScreenCategory.calculators,
      searchTags: ['spa', 'hot tub', 'volume', 'gallons', 'jacuzzi', 'capacity'],
      builder: () => const SpaVolumeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_spillover_spa',
      name: 'Spillover Spa Volume',
      subtitle: 'Calculate combined pool and spillover spa volume',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['spa', 'spillover', 'volume', 'overflow', 'combined'],
      builder: () => const SpilloverSpaScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_gallons_to_liters',
      name: 'Gallons to Liters',
      subtitle: 'Convert pool volume between units',
      icon: LucideIcons.arrowRightLeft,
      category: ScreenCategory.calculators,
      searchTags: ['gallons', 'liters', 'convert', 'volume', 'metric'],
      builder: () => const GallonsToLitersScreen(),
      trade: 'pool',
    ),

    // =========================================================================
    // WATER CHEMISTRY
    // =========================================================================
    ScreenEntry(
      id: 'pool_chlorine_dose',
      name: 'Chlorine Dosing',
      subtitle: 'Calculate chlorine needed for sanitization',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['chlorine', 'dose', 'sanitizer', 'ppm', 'shock', 'cal-hypo'],
      builder: () => const ChlorineDoseScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_ph_adjustment',
      name: 'pH Adjustment',
      subtitle: 'Calculate acid or base to adjust pH',
      icon: LucideIcons.testTube,
      category: ScreenCategory.calculators,
      searchTags: ['ph', 'acid', 'base', 'muriatic', 'soda ash', 'balance'],
      builder: () => const PhAdjustmentScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_alkalinity_adjustment',
      name: 'Alkalinity Adjustment',
      subtitle: 'Calculate chemicals to adjust total alkalinity',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['alkalinity', 'ta', 'buffer', 'bicarbonate', 'acid'],
      builder: () => const AlkalinityAdjustmentScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_calcium_hardness',
      name: 'Calcium Hardness',
      subtitle: 'Calculate calcium chloride for hardness adjustment',
      icon: LucideIcons.gem,
      category: ScreenCategory.calculators,
      searchTags: ['calcium', 'hardness', 'ch', 'calcium chloride', 'scale'],
      builder: () => const CalciumHardnessScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_stabilizer_cya',
      name: 'Stabilizer (CYA)',
      subtitle: 'Calculate cyanuric acid dosing',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['stabilizer', 'cya', 'cyanuric', 'conditioner', 'sunscreen'],
      builder: () => const StabilizerCyaScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_shock_treatment',
      name: 'Shock Treatment',
      subtitle: 'Calculate shock dose for pool sanitation',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['shock', 'superchlorinate', 'breakpoint', 'algae', 'sanitize'],
      builder: () => const ShockTreatmentScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_salt_calculator',
      name: 'Salt Calculator',
      subtitle: 'Calculate salt for saltwater pools',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['salt', 'saltwater', 'swg', 'chlorine generator', 'ppm'],
      builder: () => const SaltCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_bromine_calculator',
      name: 'Bromine Calculator',
      subtitle: 'Calculate bromine dosing for spas',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['bromine', 'spa', 'sanitizer', 'hot tub', 'tablets'],
      builder: () => const BromineCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_saturation_index',
      name: 'Saturation Index (LSI)',
      subtitle: 'Calculate Langelier Saturation Index',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['lsi', 'saturation', 'langelier', 'balance', 'corrosive', 'scaling'],
      builder: () => const SaturationIndexScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_algaecide_dosing',
      name: 'Algaecide Dosing',
      subtitle: 'Calculate algaecide for prevention and treatment',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['algaecide', 'algae', 'prevention', 'treatment', 'green'],
      builder: () => const AlgaecideDosingScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_phosphate_remover',
      name: 'Phosphate Remover',
      subtitle: 'Calculate phosphate removal dosing',
      icon: LucideIcons.trash2,
      category: ScreenCategory.calculators,
      searchTags: ['phosphate', 'remover', 'algae', 'nutrients', 'phosfree'],
      builder: () => const PhosphateRemoverScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_metal_sequestrant',
      name: 'Metal Sequestrant',
      subtitle: 'Calculate sequestrant for metal staining prevention',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['metal', 'sequestrant', 'stain', 'iron', 'copper', 'prevention'],
      builder: () => const MetalSequestrantScreen(),
      trade: 'pool',
    ),

    // =========================================================================
    // EQUIPMENT SIZING
    // =========================================================================
    ScreenEntry(
      id: 'pool_pump_sizing',
      name: 'Pump Sizing',
      subtitle: 'Calculate pump GPM and HP requirements',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['pump', 'sizing', 'gpm', 'horsepower', 'flow', 'variable speed'],
      builder: () => const PumpSizingScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_filter_size',
      name: 'Filter Sizing',
      subtitle: 'Calculate filter size for pool volume',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['filter', 'sizing', 'sand', 'cartridge', 'de', 'square feet'],
      builder: () => const FilterSizeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_heater_btu',
      name: 'Heater BTU Sizing',
      subtitle: 'Calculate BTU requirements for pool heating',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heater', 'btu', 'gas', 'natural gas', 'propane', 'sizing'],
      builder: () => const HeaterBtuScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_heat_pump_sizing',
      name: 'Heat Pump Sizing',
      subtitle: 'Calculate heat pump BTU requirements',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['heat pump', 'sizing', 'btu', 'electric', 'efficiency', 'cop'],
      builder: () => const HeatPumpSizingScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_solar_heater_sizing',
      name: 'Solar Heater Sizing',
      subtitle: 'Calculate solar panel area for pool heating',
      icon: LucideIcons.sunDim,
      category: ScreenCategory.calculators,
      searchTags: ['solar', 'heater', 'panels', 'sizing', 'collectors', 'area'],
      builder: () => const SolarHeaterSizingScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_pipe_size',
      name: 'Pipe Sizing',
      subtitle: 'Calculate pipe diameter for flow requirements',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'sizing', 'diameter', 'pvc', 'flow', 'velocity'],
      builder: () => const PipeSizePoolScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_skimmer_calculator',
      name: 'Skimmer Calculator',
      subtitle: 'Calculate number of skimmers needed',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['skimmer', 'surface', 'debris', 'circulation', 'count'],
      builder: () => const SkimmerCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_return_inlet',
      name: 'Return Inlet Calculator',
      subtitle: 'Calculate return inlet placement and count',
      icon: LucideIcons.arrowUpFromLine,
      category: ScreenCategory.calculators,
      searchTags: ['return', 'inlet', 'jets', 'circulation', 'eyeball'],
      builder: () => const ReturnInletScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_main_drain',
      name: 'Main Drain Sizing',
      subtitle: 'Calculate drain sizing and VGBA compliance',
      icon: LucideIcons.arrowDownToLine,
      category: ScreenCategory.calculators,
      searchTags: ['main drain', 'vgba', 'suction', 'entrapment', 'safety'],
      builder: () => const MainDrainScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_fountain_pump',
      name: 'Fountain Pump Sizing',
      subtitle: 'Calculate pump for water features',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['fountain', 'pump', 'water feature', 'gph', 'head'],
      builder: () => const FountainPumpScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_automation_panel',
      name: 'Automation Panel Sizing',
      subtitle: 'Calculate automation system requirements',
      icon: LucideIcons.cpu,
      category: ScreenCategory.calculators,
      searchTags: ['automation', 'panel', 'control', 'relay', 'smart', 'actuator'],
      builder: () => const AutomationPanelScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_led_lighting',
      name: 'LED Pool Lighting',
      subtitle: 'Calculate LED light requirements',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['led', 'lighting', 'underwater', 'lumens', 'watts', 'color'],
      builder: () => const LedPoolLightingScreen(),
      trade: 'pool',
    ),

    // =========================================================================
    // HYDRAULICS & FLOW
    // =========================================================================
    ScreenEntry(
      id: 'pool_turnover_time',
      name: 'Turnover Time',
      subtitle: 'Calculate pool water turnover rate',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['turnover', 'time', 'hours', 'circulation', 'flow rate'],
      builder: () => const TurnoverTimeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_head_loss',
      name: 'Head Loss Calculator',
      subtitle: 'Calculate friction head loss in piping',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['head loss', 'friction', 'tdh', 'pressure', 'feet of head'],
      builder: () => const HeadLossScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_waterfall_flow',
      name: 'Waterfall Flow Rate',
      subtitle: 'Calculate GPM for waterfall effects',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['waterfall', 'flow', 'gpm', 'cascade', 'sheer descent'],
      builder: () => const WaterfallFlowScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_backwash_calculator',
      name: 'Backwash Calculator',
      subtitle: 'Calculate backwash time and water usage',
      icon: LucideIcons.rotateCcw,
      category: ScreenCategory.calculators,
      searchTags: ['backwash', 'filter', 'cleaning', 'water waste', 'time'],
      builder: () => const BackwashCalculatorScreen(),
      trade: 'pool',
    ),

    // =========================================================================
    // HEATING & ENERGY
    // =========================================================================
    ScreenEntry(
      id: 'pool_time_to_heat',
      name: 'Time to Heat',
      subtitle: 'Calculate heating time for temperature rise',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'time', 'temperature', 'rise', 'hours', 'btu'],
      builder: () => const TimeToHeatScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_heat_loss',
      name: 'Heat Loss Calculator',
      subtitle: 'Calculate BTU heat loss from pool surface',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.calculators,
      searchTags: ['heat loss', 'btu', 'evaporation', 'radiation', 'convection'],
      builder: () => const HeatLossPoolScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_evaporation_loss',
      name: 'Evaporation Loss',
      subtitle: 'Calculate water loss from evaporation',
      icon: LucideIcons.cloudRain,
      category: ScreenCategory.calculators,
      searchTags: ['evaporation', 'water loss', 'humidity', 'wind', 'gallons'],
      builder: () => const EvaporationLossScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_cover_savings',
      name: 'Pool Cover Savings',
      subtitle: 'Calculate energy savings with pool cover',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['cover', 'savings', 'energy', 'evaporation', 'cost'],
      builder: () => const CoverSavingsScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_gas_cost',
      name: 'Gas Heating Cost',
      subtitle: 'Calculate cost to heat pool with gas',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'cost', 'heating', 'natural gas', 'propane', 'therm'],
      builder: () => const GasCostScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_electrical_load',
      name: 'Electrical Load',
      subtitle: 'Calculate total electrical load for pool equipment',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['electrical', 'load', 'amps', 'watts', 'circuit', 'breaker'],
      builder: () => const ElectricalLoadPoolScreen(),
      trade: 'pool',
    ),

    // =========================================================================
    // CONSTRUCTION & MATERIALS
    // =========================================================================
    ScreenEntry(
      id: 'pool_gunite_calculator',
      name: 'Gunite/Shotcrete Calculator',
      subtitle: 'Calculate cubic yards of gunite needed',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['gunite', 'shotcrete', 'concrete', 'cubic yards', 'shell'],
      builder: () => const GuniteCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_plaster_calculator',
      name: 'Plaster Calculator',
      subtitle: 'Calculate plaster material for pool finish',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.calculators,
      searchTags: ['plaster', 'finish', 'pebble', 'aggregate', 'quartz'],
      builder: () => const PlasterCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_tile_calculator',
      name: 'Tile Calculator',
      subtitle: 'Calculate waterline tile and coping tile',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['tile', 'waterline', 'linear feet', 'mosaic', 'glass'],
      builder: () => const TileCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_coping_calculator',
      name: 'Coping Calculator',
      subtitle: 'Calculate coping stones for pool edge',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['coping', 'stones', 'bullnose', 'edge', 'perimeter'],
      builder: () => const CopingCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_excavation_calculator',
      name: 'Excavation Calculator',
      subtitle: 'Calculate dig volume and spoils removal',
      icon: LucideIcons.shovel,
      category: ScreenCategory.calculators,
      searchTags: ['excavation', 'dig', 'spoils', 'cubic yards', 'haul'],
      builder: () => const ExcavationCalculatorScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_deck_area',
      name: 'Deck Area Calculator',
      subtitle: 'Calculate pool deck square footage',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'area', 'patio', 'pavers', 'square feet', 'concrete'],
      builder: () => const DeckAreaScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_liner_size',
      name: 'Liner Size Calculator',
      subtitle: 'Calculate vinyl liner dimensions',
      icon: LucideIcons.scroll,
      category: ScreenCategory.calculators,
      searchTags: ['liner', 'vinyl', 'size', 'measurement', 'overlap'],
      builder: () => const LinerSizeScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_rebar_calculator',
      name: 'Rebar Calculator',
      subtitle: 'Calculate rebar for pool shell construction',
      icon: LucideIcons.construction,
      category: ScreenCategory.calculators,
      searchTags: ['rebar', 'steel', 'reinforcement', 'grid', 'pounds'],
      builder: () => const RebarCalculatorScreen(),
      trade: 'pool',
    ),
  ];
}
