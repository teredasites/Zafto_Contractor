import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// WELDING CALCULATOR IMPORTS (53 screens)
// ============================================================================
import '../screens/calculators/welding/electrode_screen.dart';
import '../screens/calculators/welding/filler_wire_screen.dart';
import '../screens/calculators/welding/mig_settings_screen.dart';
import '../screens/calculators/welding/heat_input_screen.dart';
import '../screens/calculators/welding/shielding_gas_screen.dart';
import '../screens/calculators/welding/fillet_weld_size_screen.dart';
import '../screens/calculators/welding/stick_electrode_count_screen.dart';
import '../screens/calculators/welding/wire_spool_usage_screen.dart';
import '../screens/calculators/welding/flux_core_wire_screen.dart';
import '../screens/calculators/welding/deposition_rate_screen.dart';
import '../screens/calculators/welding/electrode_efficiency_screen.dart';
import '../screens/calculators/welding/filler_metal_cost_screen.dart';
import '../screens/calculators/welding/stick_amperage_screen.dart';
import '../screens/calculators/welding/tig_amperage_screen.dart';
import '../screens/calculators/welding/pulse_settings_screen.dart';
import '../screens/calculators/welding/preheat_screen.dart';
import '../screens/calculators/welding/interpass_temp_screen.dart';
import '../screens/calculators/welding/pwht_screen.dart';
import '../screens/calculators/welding/arc_length_screen.dart';
import '../screens/calculators/welding/gas_mix_screen.dart';
import '../screens/calculators/welding/tank_duration_screen.dart';
import '../screens/calculators/welding/back_purge_screen.dart';
import '../screens/calculators/welding/flux_usage_screen.dart';
import '../screens/calculators/welding/contact_tip_life_screen.dart';
import '../screens/calculators/welding/nozzle_usage_screen.dart';
import '../screens/calculators/welding/tungsten_usage_screen.dart';
import '../screens/calculators/welding/weld_volume_screen.dart';
import '../screens/calculators/welding/groove_weld_area_screen.dart';
import '../screens/calculators/welding/bevel_angle_screen.dart';
import '../screens/calculators/welding/root_opening_screen.dart';
import '../screens/calculators/welding/weld_length_screen.dart';
import '../screens/calculators/welding/multi_pass_screen.dart';
import '../screens/calculators/welding/weld_throat_screen.dart';
import '../screens/calculators/welding/cooling_rate_screen.dart';
import '../screens/calculators/welding/carbon_equivalent_screen.dart';
import '../screens/calculators/welding/hardness_estimator_screen.dart';
import '../screens/calculators/welding/dilution_screen.dart';
import '../screens/calculators/welding/travel_speed_screen.dart';
import '../screens/calculators/welding/welding_time_screen.dart';
import '../screens/calculators/welding/arc_time_screen.dart';
import '../screens/calculators/welding/duty_cycle_screen.dart';
import '../screens/calculators/welding/operator_factor_screen.dart';
import '../screens/calculators/welding/fit_up_time_screen.dart';
import '../screens/calculators/welding/grinding_time_screen.dart';
import '../screens/calculators/welding/pipe_circumference_screen.dart';
import '../screens/calculators/welding/pipe_fit_up_screen.dart';
import '../screens/calculators/welding/beveling_time_screen.dart';
import '../screens/calculators/welding/purge_volume_screen.dart';
import '../screens/calculators/welding/weld_strength_screen.dart';
import '../screens/calculators/welding/effective_throat_screen.dart';
import '../screens/calculators/welding/weld_symbol_decoder_screen.dart';
import '../screens/calculators/welding/aws_preheat_lookup_screen.dart';

// ============================================================================
// WELDING CALCULATOR ENTRIES (53)
// ============================================================================
class WeldingCalculatorEntries {
  WeldingCalculatorEntries._();

  static final List<ScreenEntry> weldingCalculators = [
    // -------------------------------------------------------------------------
    // CONSUMABLES & MATERIALS
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_electrode',
      name: 'Electrode Calculator',
      subtitle: 'Lbs of rod for weld length',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['electrode', 'rod', 'stick', 'e7018', 'e6010', 'smaw', 'consumable'],
      builder: () => const ElectrodeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_filler_wire',
      name: 'Filler Wire',
      subtitle: 'Wire weight for MIG/TIG',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['filler', 'wire', 'mig', 'tig', 'gmaw', 'gtaw', 'er70s'],
      builder: () => const FillerWireScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_stick_electrode_count',
      name: 'Stick Electrode Count',
      subtitle: 'Number of electrodes needed',
      icon: LucideIcons.hash,
      category: ScreenCategory.calculators,
      searchTags: ['stick', 'electrode', 'count', 'quantity', 'rods', 'smaw'],
      builder: () => const StickElectrodeCountScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_wire_spool_usage',
      name: 'Wire Spool Usage',
      subtitle: 'Estimate wire consumption',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['wire', 'spool', 'usage', 'consumption', 'mig', 'roll'],
      builder: () => const WireSpoolUsageScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_flux_core_wire',
      name: 'Flux Core Wire',
      subtitle: 'FCAW wire consumption',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['flux', 'core', 'fcaw', 'wire', 'self-shielded', 'dual-shield'],
      builder: () => const FluxCoreWireScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_deposition_rate',
      name: 'Deposition Rate',
      subtitle: 'lbs/hr weld metal deposited',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['deposition', 'rate', 'pounds', 'hour', 'productivity'],
      builder: () => const DepositionRateScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_electrode_efficiency',
      name: 'Electrode Efficiency',
      subtitle: 'Compare consumable efficiency',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['electrode', 'efficiency', 'stub', 'loss', 'waste'],
      builder: () => const ElectrodeEfficiencyScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_filler_metal_cost',
      name: 'Filler Metal Cost',
      subtitle: 'Cost per foot of weld',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['filler', 'cost', 'metal', 'price', 'estimating', 'budget'],
      builder: () => const FillerMetalCostScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_flux_usage',
      name: 'Flux Usage',
      subtitle: 'SAW and SMAW flux consumption',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['flux', 'usage', 'saw', 'submerged', 'arc', 'consumption'],
      builder: () => const FluxUsageScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // MACHINE SETTINGS
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_mig_settings',
      name: 'MIG Settings',
      subtitle: 'Wire speed/voltage by thickness',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['mig', 'gmaw', 'settings', 'wire', 'speed', 'voltage', 'amperage'],
      builder: () => const MigSettingsScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_stick_amperage',
      name: 'Stick Amperage',
      subtitle: 'SMAW amperage settings',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['stick', 'amperage', 'smaw', 'amps', 'settings', 'electrode'],
      builder: () => const StickAmperageScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_tig_amperage',
      name: 'TIG Amperage',
      subtitle: 'GTAW amperage settings',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['tig', 'amperage', 'gtaw', 'amps', 'settings', 'tungsten'],
      builder: () => const TigAmperageScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_pulse_settings',
      name: 'Pulse Settings',
      subtitle: 'Pulse MIG/TIG parameters',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['pulse', 'settings', 'mig', 'tig', 'frequency', 'peak', 'background'],
      builder: () => const PulseSettingsScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_arc_length',
      name: 'Arc Length',
      subtitle: 'Optimal arc length for process',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['arc', 'length', 'distance', 'stick', 'mig', 'tig'],
      builder: () => const ArcLengthScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_duty_cycle',
      name: 'Duty Cycle',
      subtitle: 'Welder duty cycle calculations',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['duty', 'cycle', 'welder', 'machine', 'capacity', 'overheating'],
      builder: () => const DutyCycleScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // HEAT & TEMPERATURE
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_heat_input',
      name: 'Heat Input',
      subtitle: 'Joules per inch',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'input', 'joules', 'kj', 'energy', 'temperature'],
      builder: () => const HeatInputScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_preheat',
      name: 'Preheat',
      subtitle: 'Minimum preheat temperature',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['preheat', 'temperature', 'minimum', 'd1.1', 'carbon', 'steel'],
      builder: () => const PreheatScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_interpass_temp',
      name: 'Interpass Temperature',
      subtitle: 'Max interpass temp control',
      icon: LucideIcons.thermometerSun,
      category: ScreenCategory.calculators,
      searchTags: ['interpass', 'temperature', 'max', 'between', 'passes', 'cooling'],
      builder: () => const InterpassTempScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_pwht',
      name: 'PWHT',
      subtitle: 'Post Weld Heat Treatment',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['pwht', 'post', 'weld', 'heat', 'treatment', 'stress', 'relief'],
      builder: () => const PwhtScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_cooling_rate',
      name: 'Cooling Rate',
      subtitle: 'Weld cooling rate estimation',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'rate', 't8/5', 'temperature', 'haz'],
      builder: () => const CoolingRateScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_aws_preheat_lookup',
      name: 'AWS Preheat Lookup',
      subtitle: 'D1.1 Table 3.2 reference',
      icon: LucideIcons.bookOpen,
      category: ScreenCategory.calculators,
      searchTags: ['aws', 'preheat', 'd1.1', 'table', 'lookup', 'reference'],
      builder: () => const AwsPreheatLookupScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // SHIELDING GAS
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_shielding_gas',
      name: 'Shielding Gas',
      subtitle: 'CFH and tank duration',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['shielding', 'gas', 'cfh', 'flow', 'argon', 'co2', 'c25'],
      builder: () => const ShieldingGasScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_gas_mix',
      name: 'Gas Mix',
      subtitle: 'Shielding gas selection',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'mix', 'blend', 'argon', 'co2', 'helium', 'trimix'],
      builder: () => const GasMixScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_tank_duration',
      name: 'Tank Duration',
      subtitle: 'Gas cylinder usage time',
      icon: LucideIcons.database,
      category: ScreenCategory.calculators,
      searchTags: ['tank', 'duration', 'cylinder', 'gas', 'time', 'hours'],
      builder: () => const TankDurationScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_back_purge',
      name: 'Back Purge',
      subtitle: 'Inert gas purge for pipe',
      icon: LucideIcons.refreshCcw,
      category: ScreenCategory.calculators,
      searchTags: ['back', 'purge', 'pipe', 'argon', 'stainless', 'titanium'],
      builder: () => const BackPurgeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_purge_volume',
      name: 'Purge Volume',
      subtitle: 'Gas volume for pipe purging',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['purge', 'volume', 'pipe', 'gas', 'cubic', 'feet'],
      builder: () => const PurgeVolumeScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // EQUIPMENT & CONSUMABLES
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_contact_tip_life',
      name: 'Contact Tip Life',
      subtitle: 'MIG contact tip replacement',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['contact', 'tip', 'life', 'mig', 'replacement', 'wear'],
      builder: () => const ContactTipLifeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_nozzle_usage',
      name: 'Nozzle Usage',
      subtitle: 'MIG nozzle replacement planning',
      icon: LucideIcons.target,
      category: ScreenCategory.calculators,
      searchTags: ['nozzle', 'usage', 'mig', 'replacement', 'spatter'],
      builder: () => const NozzleUsageScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_tungsten_usage',
      name: 'Tungsten Usage',
      subtitle: 'TIG tungsten consumption',
      icon: LucideIcons.penTool,
      category: ScreenCategory.calculators,
      searchTags: ['tungsten', 'usage', 'tig', 'gtaw', 'electrode', 'grinding'],
      builder: () => const TungstenUsageScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // WELD GEOMETRY & JOINT DESIGN
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_fillet_weld_size',
      name: 'Fillet Weld Size',
      subtitle: 'Leg size from material thickness',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['fillet', 'weld', 'size', 'leg', 'thickness', 'minimum'],
      builder: () => const FilletWeldSizeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_weld_volume',
      name: 'Weld Volume',
      subtitle: 'Cross-sectional area and volume',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['weld', 'volume', 'area', 'cross', 'section', 'filler'],
      builder: () => const WeldVolumeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_groove_weld_area',
      name: 'Groove Weld Area',
      subtitle: 'Cross-sectional area for grooves',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['groove', 'weld', 'area', 'v-groove', 'bevel', 'butt'],
      builder: () => const GrooveWeldAreaScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_bevel_angle',
      name: 'Bevel Angle',
      subtitle: 'Groove angle calculations',
      icon: LucideIcons.cornerUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['bevel', 'angle', 'groove', 'chamfer', 'included', 'degree'],
      builder: () => const BevelAngleScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_root_opening',
      name: 'Root Opening',
      subtitle: 'Recommended root gaps',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['root', 'opening', 'gap', 'spacing', 'joint', 'penetration'],
      builder: () => const RootOpeningScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_weld_length',
      name: 'Weld Length',
      subtitle: 'Calculate weld lengths for shapes',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['weld', 'length', 'linear', 'feet', 'inches', 'total'],
      builder: () => const WeldLengthScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_multi_pass',
      name: 'Multi-Pass',
      subtitle: 'Number of passes for thick welds',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['multi', 'pass', 'passes', 'thick', 'buildup', 'layers'],
      builder: () => const MultiPassScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_weld_throat',
      name: 'Weld Throat',
      subtitle: 'Effective throat dimensions',
      icon: LucideIcons.minimize2,
      category: ScreenCategory.calculators,
      searchTags: ['weld', 'throat', 'effective', 'theoretical', 'fillet'],
      builder: () => const WeldThroatScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_effective_throat',
      name: 'Effective Throat',
      subtitle: 'Groove weld effective throat',
      icon: LucideIcons.shrink,
      category: ScreenCategory.calculators,
      searchTags: ['effective', 'throat', 'groove', 'penetration', 'joint'],
      builder: () => const EffectiveThroatScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // METALLURGY & MATERIAL PROPERTIES
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_carbon_equivalent',
      name: 'Carbon Equivalent',
      subtitle: 'CE for weldability assessment',
      icon: LucideIcons.atom,
      category: ScreenCategory.calculators,
      searchTags: ['carbon', 'equivalent', 'ce', 'weldability', 'pcm', 'iiw'],
      builder: () => const CarbonEquivalentScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_hardness_estimator',
      name: 'Hardness Estimator',
      subtitle: 'HAZ hardness prediction',
      icon: LucideIcons.diamond,
      category: ScreenCategory.calculators,
      searchTags: ['hardness', 'haz', 'hrc', 'hvn', 'brinell', 'estimator'],
      builder: () => const HardnessEstimatorScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_dilution',
      name: 'Dilution',
      subtitle: 'Weld metal dilution percentage',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['dilution', 'base', 'metal', 'filler', 'percentage', 'mixing'],
      builder: () => const DilutionScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // STRENGTH & STRUCTURAL
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_weld_strength',
      name: 'Weld Strength',
      subtitle: 'Fillet weld capacity',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['weld', 'strength', 'capacity', 'load', 'kips', 'shear'],
      builder: () => const WeldStrengthScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // TIME & PRODUCTIVITY
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_travel_speed',
      name: 'Travel Speed',
      subtitle: 'Calculate travel speed from parameters',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['travel', 'speed', 'ipm', 'inches', 'minute', 'velocity'],
      builder: () => const TravelSpeedScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_welding_time',
      name: 'Welding Time',
      subtitle: 'Estimate total job time',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['welding', 'time', 'estimate', 'hours', 'job', 'duration'],
      builder: () => const WeldingTimeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_arc_time',
      name: 'Arc Time',
      subtitle: 'Arc-on time calculation',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['arc', 'time', 'on', 'actual', 'welding', 'hours'],
      builder: () => const ArcTimeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_operator_factor',
      name: 'Operator Factor',
      subtitle: 'Arc-on time percentage',
      icon: LucideIcons.user,
      category: ScreenCategory.calculators,
      searchTags: ['operator', 'factor', 'efficiency', 'arc', 'on', 'percentage'],
      builder: () => const OperatorFactorScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_fit_up_time',
      name: 'Fit-Up Time',
      subtitle: 'Estimate joint preparation time',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['fit', 'up', 'time', 'preparation', 'joint', 'assembly'],
      builder: () => const FitUpTimeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_grinding_time',
      name: 'Grinding Time',
      subtitle: 'Estimate grinding/cleaning time',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['grinding', 'time', 'cleaning', 'preparation', 'finish'],
      builder: () => const GrindingTimeScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_beveling_time',
      name: 'Beveling Time',
      subtitle: 'Estimate pipe/plate beveling time',
      icon: LucideIcons.scissors,
      category: ScreenCategory.calculators,
      searchTags: ['beveling', 'time', 'pipe', 'plate', 'prep', 'cutting'],
      builder: () => const BevelingTimeScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // PIPE WELDING
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_pipe_circumference',
      name: 'Pipe Circumference',
      subtitle: 'Pipe weld length calculations',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'circumference', 'weld', 'length', 'diameter'],
      builder: () => const PipeCircumferenceScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_pipe_fit_up',
      name: 'Pipe Fit-Up',
      subtitle: 'Pipe joint preparation',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'fit', 'up', 'joint', 'alignment', 'gap'],
      builder: () => const PipeFitUpScreen(),
      trade: 'welding',
    ),

    // -------------------------------------------------------------------------
    // REFERENCE & SYMBOLS
    // -------------------------------------------------------------------------
    ScreenEntry(
      id: 'welding_weld_symbol_decoder',
      name: 'Weld Symbol Decoder',
      subtitle: 'AWS weld symbol reference',
      icon: LucideIcons.fileText,
      category: ScreenCategory.calculators,
      searchTags: ['weld', 'symbol', 'decoder', 'aws', 'a2.4', 'blueprint'],
      builder: () => const WeldSymbolDecoderScreen(),
      trade: 'welding',
    ),
  ];
}
