import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// AUTO MECHANIC CALCULATOR IMPORTS (195 screens)
// ============================================================================
import '../screens/calculators/auto/abs_troubleshoot_screen.dart';
import '../screens/calculators/auto/ac_charge_screen.dart';
import '../screens/calculators/auto/ac_clutch_gap_screen.dart';
import '../screens/calculators/auto/ac_diagnostic_screen.dart';
import '../screens/calculators/auto/ac_pressure_screen.dart';
import '../screens/calculators/auto/ac_pressure_temp_screen.dart';
import '../screens/calculators/auto/ac_vent_temp_screen.dart';
import '../screens/calculators/auto/ackermann_angle_screen.dart';
import '../screens/calculators/auto/afr_screen.dart';
import '../screens/calculators/auto/alignment_spec_screen.dart';
import '../screens/calculators/auto/alternator_sizing_screen.dart';
import '../screens/calculators/auto/anti_squat_screen.dart';
import '../screens/calculators/auto/axle_shaft_strength_screen.dart';
import '../screens/calculators/auto/backpressure_screen.dart';
import '../screens/calculators/auto/band_adjustment_screen.dart';
import '../screens/calculators/auto/battery_cca_screen.dart';
import '../screens/calculators/auto/battery_load_test_screen.dart';
import '../screens/calculators/auto/bearing_preload_screen.dart';
import '../screens/calculators/auto/blend_door_screen.dart';
import '../screens/calculators/auto/body_filler_screen.dart';
import '../screens/calculators/auto/boil_point_screen.dart';
import '../screens/calculators/auto/bolt_pattern_screen.dart';
import '../screens/calculators/auto/boost_by_gear_screen.dart';
import '../screens/calculators/auto/boost_calculator_screen.dart';
import '../screens/calculators/auto/boost_pressure_screen.dart';
import '../screens/calculators/auto/bore_stroke_ratio_screen.dart';
import '../screens/calculators/auto/bov_screen.dart';
import '../screens/calculators/auto/brake_bias_screen.dart';
import '../screens/calculators/auto/brake_caliper_screen.dart';
import '../screens/calculators/auto/brake_fluid_boiling_screen.dart';
import '../screens/calculators/auto/brake_fluid_service_screen.dart';
import '../screens/calculators/auto/brake_line_pressure_screen.dart';
import '../screens/calculators/auto/brake_pad_life_screen.dart';
import '../screens/calculators/auto/brake_proportioning_screen.dart';
import '../screens/calculators/auto/brake_rotor_spec_screen.dart';
import '../screens/calculators/auto/bsfc_screen.dart';
import '../screens/calculators/auto/bump_steer_screen.dart';
import '../screens/calculators/auto/cam_timing_screen.dart';
import '../screens/calculators/auto/camber_screen.dart';
import '../screens/calculators/auto/caster_screen.dart';
import '../screens/calculators/auto/cat_converter_screen.dart';
import '../screens/calculators/auto/cc_converter_screen.dart';
import '../screens/calculators/auto/cca_to_ah_screen.dart';
import '../screens/calculators/auto/center_bearing_screen.dart';
import '../screens/calculators/auto/charge_air_temp_screen.dart';
import '../screens/calculators/auto/charging_system_screen.dart';
import '../screens/calculators/auto/clutch_sizing_screen.dart';
import '../screens/calculators/auto/coil_on_plug_screen.dart';
import '../screens/calculators/auto/collector_size_screen.dart';
import '../screens/calculators/auto/compression_ratio_screen.dart';
import '../screens/calculators/auto/compression_test_screen.dart';
import '../screens/calculators/auto/compressor_map_screen.dart';
import '../screens/calculators/auto/compressor_oil_screen.dart';
import '../screens/calculators/auto/coolant_capacity_screen.dart';
import '../screens/calculators/auto/coolant_mix_screen.dart';
import '../screens/calculators/auto/cooling_capacity_screen.dart';
import '../screens/calculators/auto/cooling_system_pressure_screen.dart';
import '../screens/calculators/auto/corner_weight_screen.dart';
import '../screens/calculators/auto/cost_per_mile_screen.dart';
import '../screens/calculators/auto/crawl_ratio_screen.dart';
import '../screens/calculators/auto/cv_joint_angle_screen.dart';
import '../screens/calculators/auto/cylinder_leakdown_screen.dart';
import '../screens/calculators/auto/deck_height_screen.dart';
import '../screens/calculators/auto/detonation_screen.dart';
import '../screens/calculators/auto/diff_fluid_screen.dart';
import '../screens/calculators/auto/diff_ratio_finder_screen.dart';
import '../screens/calculators/auto/driveshaft_angle_screen.dart';
import '../screens/calculators/auto/drivetrain_loss_screen.dart';
import '../screens/calculators/auto/dwell_angle_screen.dart';
import '../screens/calculators/auto/dynamic_compression_screen.dart';
import '../screens/calculators/auto/e85_fuel_screen.dart';
import '../screens/calculators/auto/electric_fan_screen.dart';
import '../screens/calculators/auto/emission_test_screen.dart';
import '../screens/calculators/auto/engine_cfm_screen.dart';
import '../screens/calculators/auto/engine_displacement_screen.dart';
import '../screens/calculators/auto/ev_range_screen.dart';
import '../screens/calculators/auto/evaporator_temp_screen.dart';
import '../screens/calculators/auto/exhaust_pipe_size_screen.dart';
import '../screens/calculators/auto/exhaust_wrap_screen.dart';
import '../screens/calculators/auto/expansion_tank_screen.dart';
import '../screens/calculators/auto/fan_cfm_screen.dart';
import '../screens/calculators/auto/firing_order_screen.dart';
import '../screens/calculators/auto/fluid_capacity_screen.dart';
import '../screens/calculators/auto/flywheel_weight_screen.dart';
import '../screens/calculators/auto/freeze_point_screen.dart';
import '../screens/calculators/auto/fuel_economy_screen.dart';
import '../screens/calculators/auto/fuel_injector_screen.dart';
import '../screens/calculators/auto/fuel_line_screen.dart';
import '../screens/calculators/auto/fuel_pump_screen.dart';
import '../screens/calculators/auto/fuse_sizing_screen.dart';
import '../screens/calculators/auto/gear_ratio_screen.dart';
import '../screens/calculators/auto/gear_ratio_tire_screen.dart';
import '../screens/calculators/auto/halfshaft_length_screen.dart';
import '../screens/calculators/auto/header_primary_size_screen.dart';
import '../screens/calculators/auto/headlight_aim_screen.dart';
import '../screens/calculators/auto/heat_rejection_screen.dart';
import '../screens/calculators/auto/heater_core_flow_screen.dart';
import '../screens/calculators/auto/horsepower_screen.dart';
import '../screens/calculators/auto/idle_speed_screen.dart';
import '../screens/calculators/auto/ignition_timing_screen.dart';
import '../screens/calculators/auto/injector_duty_screen.dart';
import '../screens/calculators/auto/intercooler_efficiency_screen.dart';
import '../screens/calculators/auto/intercooler_screen.dart';
import '../screens/calculators/auto/kingpin_angle_screen.dart';
import '../screens/calculators/auto/labor_time_screen.dart';
import '../screens/calculators/auto/lambda_screen.dart';
import '../screens/calculators/auto/launch_rpm_screen.dart';
import '../screens/calculators/auto/led_resistor_screen.dart';
import '../screens/calculators/auto/line_pressure_screen.dart';
import '../screens/calculators/auto/load_range_screen.dart';
import '../screens/calculators/auto/master_cylinder_screen.dart';
import '../screens/calculators/auto/misfire_analysis_screen.dart';
import '../screens/calculators/auto/motion_ratio_screen.dart';
import '../screens/calculators/auto/muffler_sizing_screen.dart';
import '../screens/calculators/auto/nitrous_sizing_screen.dart';
import '../screens/calculators/auto/obd2_lookup_screen.dart';
import '../screens/calculators/auto/ohms_law_12v_screen.dart';
import '../screens/calculators/auto/oil_capacity_screen.dart';
import '../screens/calculators/auto/oil_change_interval_screen.dart';
import '../screens/calculators/auto/orifice_tube_screen.dart';
import '../screens/calculators/auto/overall_gear_ratio_screen.dart';
import '../screens/calculators/auto/paint_coverage_screen.dart';
import '../screens/calculators/auto/parasitic_draw_screen.dart';
import '../screens/calculators/auto/pedal_ratio_screen.dart';
import '../screens/calculators/auto/pinion_angle_screen.dart';
import '../screens/calculators/auto/piston_speed_screen.dart';
import '../screens/calculators/auto/plus_size_screen.dart';
import '../screens/calculators/auto/power_steering_fluid_screen.dart';
import '../screens/calculators/auto/power_steering_pressure_screen.dart';
import '../screens/calculators/auto/power_to_weight_screen.dart';
import '../screens/calculators/auto/pulley_ratio_screen.dart';
import '../screens/calculators/auto/quarter_mile_screen.dart';
import '../screens/calculators/auto/quench_distance_screen.dart';
import '../screens/calculators/auto/rack_travel_screen.dart';
import '../screens/calculators/auto/radiator_size_screen.dart';
import '../screens/calculators/auto/radiator_sizing_screen.dart';
import '../screens/calculators/auto/refrigerant_charge_screen.dart';
import '../screens/calculators/auto/relay_sizing_screen.dart';
import '../screens/calculators/auto/ride_height_screen.dart';
import '../screens/calculators/auto/rod_ratio_screen.dart';
import '../screens/calculators/auto/rotor_min_thickness_screen.dart';
import '../screens/calculators/auto/rotor_swept_area_screen.dart';
import '../screens/calculators/auto/rpm_from_speed_screen.dart';
import '../screens/calculators/auto/scavenging_effect_screen.dart';
import '../screens/calculators/auto/scrub_radius_screen.dart';
import '../screens/calculators/auto/serpentine_belt_screen.dart';
import '../screens/calculators/auto/shift_point_screen.dart';
import '../screens/calculators/auto/shock_sizing_screen.dart';
import '../screens/calculators/auto/sixty_foot_screen.dart';
import '../screens/calculators/auto/spark_plug_gap_screen.dart';
import '../screens/calculators/auto/speed_from_rpm_screen.dart';
import '../screens/calculators/auto/speedometer_correction_screen.dart';
import '../screens/calculators/auto/spring_rate_screen.dart';
import '../screens/calculators/auto/stall_speed_screen.dart';
import '../screens/calculators/auto/steering_column_angle_screen.dart';
import '../screens/calculators/auto/steering_ratio_screen.dart';
import '../screens/calculators/auto/strut_mount_screen.dart';
import '../screens/calculators/auto/subcool_screen.dart';
import '../screens/calculators/auto/supercharger_drive_screen.dart';
import '../screens/calculators/auto/superheat_screen.dart';
import '../screens/calculators/auto/superheat_subcool_screen.dart';
import '../screens/calculators/auto/thermostat_screen.dart';
import '../screens/calculators/auto/thermostat_temp_screen.dart';
import '../screens/calculators/auto/tie_rod_length_screen.dart';
import '../screens/calculators/auto/timing_advance_screen.dart';
import '../screens/calculators/auto/timing_belt_interval_screen.dart';
import '../screens/calculators/auto/tire_comparison_screen.dart';
import '../screens/calculators/auto/tire_pressure_screen.dart';
import '../screens/calculators/auto/tire_rotation_screen.dart';
import '../screens/calculators/auto/tire_size_screen.dart';
import '../screens/calculators/auto/tire_wear_screen.dart';
import '../screens/calculators/auto/toe_screen.dart';
import '../screens/calculators/auto/torque_multiplication_screen.dart';
import '../screens/calculators/auto/torque_screen.dart';
import '../screens/calculators/auto/trans_cooler_screen.dart';
import '../screens/calculators/auto/trans_fluid_screen.dart';
import '../screens/calculators/auto/trans_gear_spread_screen.dart';
import '../screens/calculators/auto/trap_speed_screen.dart';
import '../screens/calculators/auto/trip_fuel_cost_screen.dart';
import '../screens/calculators/auto/turbo_lag_screen.dart';
import '../screens/calculators/auto/turbo_sizing_screen.dart';
import '../screens/calculators/auto/u_joint_phasing_screen.dart';
import '../screens/calculators/auto/vacuum_test_screen.dart';
import '../screens/calculators/auto/valve_timing_screen.dart';
import '../screens/calculators/auto/voltage_drop_12v_screen.dart';
import '../screens/calculators/auto/wastegate_screen.dart';
import '../screens/calculators/auto/water_pump_flow_screen.dart';
import '../screens/calculators/auto/weight_distribution_screen.dart';
import '../screens/calculators/auto/weight_transfer_screen.dart';
import '../screens/calculators/auto/wheel_bearing_load_screen.dart';
import '../screens/calculators/auto/wheel_fitment_screen.dart';
import '../screens/calculators/auto/wheel_offset_screen.dart';
import '../screens/calculators/auto/wheel_torque_spec_screen.dart';
import '../screens/calculators/auto/wiper_blade_size_screen.dart';
import '../screens/calculators/auto/wire_gauge_screen.dart';

// ============================================================================
// ADDITIONAL AUTO MECHANIC CALCULATOR IMPORTS (54 screens)
// ============================================================================
import '../screens/calculators/auto/battery_capacity_screen.dart';
import '../screens/calculators/auto/battery_degradation_screen.dart';
import '../screens/calculators/auto/battery_finder_screen.dart';
import '../screens/calculators/auto/belt_length_screen.dart';
import '../screens/calculators/auto/brake_fluid_capacity_screen.dart';
import '../screens/calculators/auto/break_even_mileage_screen.dart';
import '../screens/calculators/auto/catalytic_converter_screen.dart';
import '../screens/calculators/auto/charging_cost_screen.dart';
import '../screens/calculators/auto/charging_time_screen.dart';
import '../screens/calculators/auto/collector_screen.dart';
import '../screens/calculators/auto/dc_fast_charge_screen.dart';
import '../screens/calculators/auto/depreciation_screen.dart';
import '../screens/calculators/auto/dyno_correction_screen.dart';
import '../screens/calculators/auto/eighth_to_quarter_screen.dart';
import '../screens/calculators/auto/emissions_prep_screen.dart';
import '../screens/calculators/auto/ev_efficiency_screen.dart';
import '../screens/calculators/auto/exhaust_pipe_screen.dart';
import '../screens/calculators/auto/fastener_torque_screen.dart';
import '../screens/calculators/auto/filter_cross_ref_screen.dart';
import '../screens/calculators/auto/fluid_dilution_screen.dart';
import '../screens/calculators/auto/fuel_pressure_reg_screen.dart';
import '../screens/calculators/auto/head_bolt_torque_screen.dart';
import '../screens/calculators/auto/header_primary_screen.dart';
import '../screens/calculators/auto/hp_from_et_screen.dart';
import '../screens/calculators/auto/hp_from_trap_screen.dart';
import '../screens/calculators/auto/hybrid_mpg_screen.dart';
import '../screens/calculators/auto/job_estimate_screen.dart';
import '../screens/calculators/auto/light_bulb_screen.dart';
import '../screens/calculators/auto/maintenance_schedule_screen.dart';
import '../screens/calculators/auto/metric_sae_screen.dart';
import '../screens/calculators/auto/muffler_screen.dart';
import '../screens/calculators/auto/o2_sensor_screen.dart';
import '../screens/calculators/auto/oil_viscosity_screen.dart';
import '../screens/calculators/auto/paint_code_screen.dart';
import '../screens/calculators/auto/parts_markup_screen.dart';
import '../screens/calculators/auto/payload_screen.dart';
import '../screens/calculators/auto/pulley_size_screen.dart';
import '../screens/calculators/auto/reaction_time_screen.dart';
import '../screens/calculators/auto/regen_braking_screen.dart';
import '../screens/calculators/auto/roll_race_screen.dart';
import '../screens/calculators/auto/sensor_range_screen.dart';
import '../screens/calculators/auto/shop_rate_screen.dart';
import '../screens/calculators/auto/thread_pitch_screen.dart';
import '../screens/calculators/auto/timing_light_screen.dart';
import '../screens/calculators/auto/trailer_towing_screen.dart';
import '../screens/calculators/auto/vin_decoder_screen.dart';
import '../screens/calculators/auto/warranty_expiration_screen.dart';
import '../screens/calculators/auto/wheel_torque_screen.dart';
import '../screens/calculators/auto/wiper_blade_screen.dart';
import '../screens/calculators/auto/zero_to_sixty_screen.dart';

// ============================================================================
// AUTO MECHANIC CALCULATOR ENTRIES (195 entries)
// ============================================================================
class AutoCalculatorEntries {
  AutoCalculatorEntries._();

  static final List<ScreenEntry> autoCalculators = [
    // =========================================================================
    // ENGINE - FUNDAMENTALS
    // =========================================================================
    ScreenEntry(
      id: 'auto_engine_displacement',
      name: 'Engine Displacement',
      subtitle: 'Calculate cubic inches/liters',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['engine', 'displacement', 'cubic inch', 'liter', 'bore', 'stroke', 'cc', 'ci'],
      builder: () => const EngineDisplacementScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_compression_ratio',
      name: 'Compression Ratio',
      subtitle: 'Calculate static compression ratio',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.calculators,
      searchTags: ['compression', 'ratio', 'cr', 'cylinder', 'volume', 'head', 'gasket'],
      builder: () => const CompressionRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_dynamic_compression',
      name: 'Dynamic Compression',
      subtitle: 'Calculate effective compression ratio',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['dynamic', 'compression', 'effective', 'cam', 'timing', 'intake'],
      builder: () => const DynamicCompressionScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_horsepower',
      name: 'Horsepower',
      subtitle: 'Calculate HP from torque/dyno',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['horsepower', 'hp', 'power', 'torque', 'rpm', 'dyno', 'bhp', 'whp'],
      builder: () => const HorsepowerScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_torque',
      name: 'Torque',
      subtitle: 'Calculate torque from HP/specs',
      icon: LucideIcons.rotateCw,
      category: ScreenCategory.calculators,
      searchTags: ['torque', 'lb-ft', 'nm', 'newton', 'meter', 'power'],
      builder: () => const TorqueScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_engine_cfm',
      name: 'Engine CFM',
      subtitle: 'Calculate airflow requirements',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['cfm', 'airflow', 'engine', 'cubic feet', 'minute', 'intake', 'throttle body'],
      builder: () => const EngineCfmScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bore_stroke_ratio',
      name: 'Bore/Stroke Ratio',
      subtitle: 'Analyze engine geometry',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['bore', 'stroke', 'ratio', 'oversquare', 'undersquare', 'square'],
      builder: () => const BoreStrokeRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_rod_ratio',
      name: 'Rod Ratio',
      subtitle: 'Calculate connecting rod ratio',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['rod', 'ratio', 'connecting', 'length', 'stroke', 'piston'],
      builder: () => const RodRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_piston_speed',
      name: 'Piston Speed',
      subtitle: 'Calculate mean piston speed',
      icon: LucideIcons.moveVertical,
      category: ScreenCategory.calculators,
      searchTags: ['piston', 'speed', 'mean', 'feet', 'minute', 'rpm', 'stroke'],
      builder: () => const PistonSpeedScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_deck_height',
      name: 'Deck Height',
      subtitle: 'Calculate piston deck clearance',
      icon: LucideIcons.alignVerticalJustifyEnd,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'height', 'piston', 'clearance', 'block', 'surface'],
      builder: () => const DeckHeightScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_quench_distance',
      name: 'Quench Distance',
      subtitle: 'Calculate squish clearance',
      icon: LucideIcons.minimize2,
      category: ScreenCategory.calculators,
      searchTags: ['quench', 'squish', 'distance', 'clearance', 'head', 'piston'],
      builder: () => const QuenchDistanceScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cc_converter',
      name: 'CC Converter',
      subtitle: 'Convert displacement units',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['cc', 'cubic', 'centimeter', 'inch', 'liter', 'convert', 'displacement'],
      builder: () => const CcConverterScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ENGINE - DIAGNOSTICS
    // =========================================================================
    ScreenEntry(
      id: 'auto_compression_test',
      name: 'Compression Test',
      subtitle: 'Analyze compression readings',
      icon: LucideIcons.barChart2,
      category: ScreenCategory.calculators,
      searchTags: ['compression', 'test', 'cylinder', 'psi', 'readings', 'diagnosis'],
      builder: () => const CompressionTestScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cylinder_leakdown',
      name: 'Cylinder Leakdown',
      subtitle: 'Analyze leakdown test results',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['leakdown', 'cylinder', 'test', 'leak', 'percent', 'rings', 'valves'],
      builder: () => const CylinderLeakdownScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_vacuum_test',
      name: 'Vacuum Test',
      subtitle: 'Interpret vacuum gauge readings',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['vacuum', 'test', 'gauge', 'inhg', 'manifold', 'diagnosis'],
      builder: () => const VacuumTestScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_misfire_analysis',
      name: 'Misfire Analysis',
      subtitle: 'Diagnose engine misfires',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['misfire', 'analysis', 'cylinder', 'ignition', 'fuel', 'diagnosis'],
      builder: () => const MisfireAnalysisScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_detonation',
      name: 'Detonation Analysis',
      subtitle: 'Diagnose knock/ping issues',
      icon: LucideIcons.alertOctagon,
      category: ScreenCategory.calculators,
      searchTags: ['detonation', 'knock', 'ping', 'pre-ignition', 'octane', 'timing'],
      builder: () => const DetonationScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ENGINE - IGNITION
    // =========================================================================
    ScreenEntry(
      id: 'auto_spark_plug_gap',
      name: 'Spark Plug Gap',
      subtitle: 'Determine correct plug gap',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['spark', 'plug', 'gap', 'ignition', 'electrode', 'mm', 'inch'],
      builder: () => const SparkPlugGapScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ignition_timing',
      name: 'Ignition Timing',
      subtitle: 'Calculate timing settings',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['ignition', 'timing', 'btdc', 'advance', 'retard', 'degrees'],
      builder: () => const IgnitionTimingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_timing_advance',
      name: 'Timing Advance',
      subtitle: 'Calculate total timing advance',
      icon: LucideIcons.fastForward,
      category: ScreenCategory.calculators,
      searchTags: ['timing', 'advance', 'initial', 'mechanical', 'vacuum', 'total'],
      builder: () => const TimingAdvanceScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_dwell_angle',
      name: 'Dwell Angle',
      subtitle: 'Calculate ignition dwell',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['dwell', 'angle', 'ignition', 'points', 'degrees', 'coil'],
      builder: () => const DwellAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_coil_on_plug',
      name: 'Coil-On-Plug',
      subtitle: 'COP system diagnostics',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['coil', 'plug', 'cop', 'ignition', 'diagnostics', 'resistance'],
      builder: () => const CoilOnPlugScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_firing_order',
      name: 'Firing Order',
      subtitle: 'Reference firing order patterns',
      icon: LucideIcons.listOrdered,
      category: ScreenCategory.calculators,
      searchTags: ['firing', 'order', 'cylinder', 'sequence', 'v8', 'v6', 'inline'],
      builder: () => const FiringOrderScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ENGINE - CAMSHAFT & VALVETRAIN
    // =========================================================================
    ScreenEntry(
      id: 'auto_cam_timing',
      name: 'Cam Timing',
      subtitle: 'Calculate camshaft timing',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['cam', 'timing', 'camshaft', 'lobe', 'centerline', 'advance', 'retard'],
      builder: () => const CamTimingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_valve_timing',
      name: 'Valve Timing',
      subtitle: 'Calculate valve events',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['valve', 'timing', 'duration', 'lift', 'overlap', 'lsa'],
      builder: () => const ValveTimingScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // TIRES & WHEELS
    // =========================================================================
    ScreenEntry(
      id: 'auto_tire_size',
      name: 'Tire Size',
      subtitle: 'Calculate tire dimensions',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'size', 'diameter', 'width', 'aspect', 'ratio', 'sidewall'],
      builder: () => const TireSizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_tire_comparison',
      name: 'Tire Comparison',
      subtitle: 'Compare tire sizes',
      icon: LucideIcons.gitCompare,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'comparison', 'compare', 'size', 'difference', 'speedometer'],
      builder: () => const TireComparisonScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_tire_pressure',
      name: 'Tire Pressure',
      subtitle: 'Calculate optimal pressure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'pressure', 'psi', 'kpa', 'bar', 'inflation'],
      builder: () => const TirePressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_tire_rotation',
      name: 'Tire Rotation',
      subtitle: 'Rotation patterns guide',
      icon: LucideIcons.rotateCcw,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'rotation', 'pattern', 'cross', 'front', 'rear', 'directional'],
      builder: () => const TireRotationScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_tire_wear',
      name: 'Tire Wear',
      subtitle: 'Analyze tire wear patterns',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'wear', 'pattern', 'cupping', 'feathering', 'alignment'],
      builder: () => const TireWearScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_load_range',
      name: 'Tire Load Range',
      subtitle: 'Load capacity ratings',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['tire', 'load', 'range', 'capacity', 'ply', 'rating', 'weight'],
      builder: () => const LoadRangeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_plus_size',
      name: 'Plus Size Tires',
      subtitle: 'Calculate plus-size fitment',
      icon: LucideIcons.plusCircle,
      category: ScreenCategory.calculators,
      searchTags: ['plus', 'size', 'tire', 'wheel', 'upgrade', 'fitment'],
      builder: () => const PlusSizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wheel_offset',
      name: 'Wheel Offset',
      subtitle: 'Calculate wheel offset/backspacing',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['wheel', 'offset', 'backspacing', 'et', 'mm', 'fitment'],
      builder: () => const WheelOffsetScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wheel_fitment',
      name: 'Wheel Fitment',
      subtitle: 'Check wheel/tire fitment',
      icon: LucideIcons.checkCircle,
      category: ScreenCategory.calculators,
      searchTags: ['wheel', 'fitment', 'clearance', 'fender', 'rub', 'spacing'],
      builder: () => const WheelFitmentScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bolt_pattern',
      name: 'Bolt Pattern',
      subtitle: 'Measure/convert bolt patterns',
      icon: LucideIcons.target,
      category: ScreenCategory.calculators,
      searchTags: ['bolt', 'pattern', 'lug', 'pcd', 'circle', '5x114', '4x100'],
      builder: () => const BoltPatternScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_speedometer_correction',
      name: 'Speedometer Correction',
      subtitle: 'Calculate speedo error from tire change',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['speedometer', 'correction', 'error', 'tire', 'size', 'calibration'],
      builder: () => const SpeedometerCorrectionScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wheel_torque_spec',
      name: 'Wheel Torque Specs',
      subtitle: 'Lug nut torque reference',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['wheel', 'torque', 'spec', 'lug', 'nut', 'ft-lb', 'nm'],
      builder: () => const WheelTorqueSpecScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wheel_bearing_load',
      name: 'Wheel Bearing Load',
      subtitle: 'Calculate bearing loads',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['wheel', 'bearing', 'load', 'force', 'weight', 'stress'],
      builder: () => const WheelBearingLoadScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // DRIVETRAIN - GEARING
    // =========================================================================
    ScreenEntry(
      id: 'auto_gear_ratio',
      name: 'Gear Ratio',
      subtitle: 'Calculate gear ratios',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['gear', 'ratio', 'transmission', 'teeth', 'driven', 'drive'],
      builder: () => const GearRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_overall_gear_ratio',
      name: 'Overall Gear Ratio',
      subtitle: 'Calculate total drive ratio',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['overall', 'gear', 'ratio', 'final', 'drive', 'transmission', 'differential'],
      builder: () => const OverallGearRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_gear_ratio_tire',
      name: 'Gear Ratio from Tire Size',
      subtitle: 'Calculate ratio for tire change',
      icon: LucideIcons.settings2,
      category: ScreenCategory.calculators,
      searchTags: ['gear', 'ratio', 'tire', 'size', 'correction', 'rpm'],
      builder: () => const GearRatioTireScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_speed_from_rpm',
      name: 'Speed from RPM',
      subtitle: 'Calculate vehicle speed',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['speed', 'rpm', 'gear', 'ratio', 'tire', 'mph', 'kmh'],
      builder: () => const SpeedFromRpmScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_rpm_from_speed',
      name: 'RPM from Speed',
      subtitle: 'Calculate engine RPM',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['rpm', 'speed', 'gear', 'ratio', 'tire', 'engine'],
      builder: () => const RpmFromSpeedScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_crawl_ratio',
      name: 'Crawl Ratio',
      subtitle: 'Calculate off-road crawl ratio',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['crawl', 'ratio', 'off-road', 'transfer', 'case', '4x4', 'low'],
      builder: () => const CrawlRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_diff_ratio_finder',
      name: 'Diff Ratio Finder',
      subtitle: 'Determine differential ratio',
      icon: LucideIcons.search,
      category: ScreenCategory.calculators,
      searchTags: ['differential', 'ratio', 'finder', 'rear', 'end', 'axle'],
      builder: () => const DiffRatioFinderScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trans_gear_spread',
      name: 'Trans Gear Spread',
      subtitle: 'Analyze transmission spread',
      icon: LucideIcons.barChart,
      category: ScreenCategory.calculators,
      searchTags: ['transmission', 'gear', 'spread', 'ratio', 'close', 'wide'],
      builder: () => const TransGearSpreadScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_drivetrain_loss',
      name: 'Drivetrain Loss',
      subtitle: 'Calculate parasitic losses',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['drivetrain', 'loss', 'parasitic', 'whp', 'bhp', 'efficiency'],
      builder: () => const DrivetrainLossScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_torque_multiplication',
      name: 'Torque Multiplication',
      subtitle: 'Calculate torque at wheels',
      icon: LucideIcons.maximize,
      category: ScreenCategory.calculators,
      searchTags: ['torque', 'multiplication', 'wheel', 'gear', 'ratio', 'force'],
      builder: () => const TorqueMultiplicationScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // DRIVETRAIN - DRIVELINE
    // =========================================================================
    ScreenEntry(
      id: 'auto_driveshaft_angle',
      name: 'Driveshaft Angle',
      subtitle: 'Calculate operating angles',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['driveshaft', 'angle', 'u-joint', 'operating', 'pinion', 'transmission'],
      builder: () => const DriveshaftAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_pinion_angle',
      name: 'Pinion Angle',
      subtitle: 'Calculate pinion angle',
      icon: LucideIcons.cornerDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['pinion', 'angle', 'differential', 'driveshaft', 'vibration'],
      builder: () => const PinionAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_u_joint_phasing',
      name: 'U-Joint Phasing',
      subtitle: 'Calculate proper phasing',
      icon: LucideIcons.link2,
      category: ScreenCategory.calculators,
      searchTags: ['u-joint', 'phasing', 'driveshaft', 'vibration', 'angle'],
      builder: () => const UJointPhasingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cv_joint_angle',
      name: 'CV Joint Angle',
      subtitle: 'Calculate CV joint angles',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['cv', 'joint', 'angle', 'axle', 'halfshaft', 'constant', 'velocity'],
      builder: () => const CvJointAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_halfshaft_length',
      name: 'Halfshaft Length',
      subtitle: 'Calculate axle length',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['halfshaft', 'axle', 'length', 'cv', 'measurement'],
      builder: () => const HalfshaftLengthScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_axle_shaft_strength',
      name: 'Axle Shaft Strength',
      subtitle: 'Calculate axle strength',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['axle', 'shaft', 'strength', 'spline', 'diameter', 'torque'],
      builder: () => const AxleShaftStrengthScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_center_bearing',
      name: 'Center Bearing',
      subtitle: 'Two-piece driveshaft specs',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['center', 'bearing', 'driveshaft', 'carrier', 'support'],
      builder: () => const CenterBearingScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // DRIVETRAIN - CLUTCH & TRANSMISSION
    // =========================================================================
    ScreenEntry(
      id: 'auto_clutch_sizing',
      name: 'Clutch Sizing',
      subtitle: 'Calculate clutch requirements',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['clutch', 'sizing', 'torque', 'capacity', 'diameter', 'pressure'],
      builder: () => const ClutchSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_flywheel_weight',
      name: 'Flywheel Weight',
      subtitle: 'Effects of flywheel mass',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['flywheel', 'weight', 'mass', 'lightened', 'inertia', 'rpm'],
      builder: () => const FlywheelWeightScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_stall_speed',
      name: 'Stall Speed',
      subtitle: 'Torque converter stall speed',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['stall', 'speed', 'torque', 'converter', 'automatic', 'rpm'],
      builder: () => const StallSpeedScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_shift_point',
      name: 'Shift Point',
      subtitle: 'Calculate optimal shift points',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['shift', 'point', 'rpm', 'powerband', 'redline', 'optimal'],
      builder: () => const ShiftPointScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_launch_rpm',
      name: 'Launch RPM',
      subtitle: 'Calculate optimal launch RPM',
      icon: LucideIcons.rocket,
      category: ScreenCategory.calculators,
      searchTags: ['launch', 'rpm', 'start', 'drag', 'racing', 'clutch'],
      builder: () => const LaunchRpmScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_line_pressure',
      name: 'Line Pressure',
      subtitle: 'Auto trans line pressure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['line', 'pressure', 'transmission', 'automatic', 'valve', 'body'],
      builder: () => const LinePressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_band_adjustment',
      name: 'Band Adjustment',
      subtitle: 'Auto trans band settings',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['band', 'adjustment', 'transmission', 'automatic', 'servo'],
      builder: () => const BandAdjustmentScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trans_fluid',
      name: 'Trans Fluid',
      subtitle: 'Transmission fluid specs',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['transmission', 'fluid', 'atf', 'type', 'capacity', 'specs'],
      builder: () => const TransFluidScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trans_cooler',
      name: 'Trans Cooler',
      subtitle: 'Size transmission cooler',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['transmission', 'cooler', 'temperature', 'tow', 'gvw'],
      builder: () => const TransCoolerScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_diff_fluid',
      name: 'Differential Fluid',
      subtitle: 'Diff fluid specifications',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['differential', 'fluid', 'gear', 'oil', 'capacity', 'weight'],
      builder: () => const DiffFluidScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // BRAKES
    // =========================================================================
    ScreenEntry(
      id: 'auto_brake_caliper',
      name: 'Brake Caliper',
      subtitle: 'Calculate caliper piston force',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'caliper', 'piston', 'force', 'area', 'pressure'],
      builder: () => const BrakeCaliperScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_master_cylinder',
      name: 'Master Cylinder',
      subtitle: 'Size master cylinder bore',
      icon: LucideIcons.database,
      category: ScreenCategory.calculators,
      searchTags: ['master', 'cylinder', 'bore', 'size', 'pedal', 'ratio'],
      builder: () => const MasterCylinderScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_bias',
      name: 'Brake Bias',
      subtitle: 'Calculate front/rear bias',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'bias', 'front', 'rear', 'balance', 'proportioning'],
      builder: () => const BrakeBiasScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_pedal_ratio',
      name: 'Pedal Ratio',
      subtitle: 'Calculate brake pedal ratio',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['pedal', 'ratio', 'brake', 'leverage', 'effort', 'feel'],
      builder: () => const PedalRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_line_pressure',
      name: 'Brake Line Pressure',
      subtitle: 'Calculate system pressure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'line', 'pressure', 'psi', 'hydraulic', 'force'],
      builder: () => const BrakeLinePressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_rotor_swept_area',
      name: 'Rotor Swept Area',
      subtitle: 'Calculate rotor surface area',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['rotor', 'swept', 'area', 'diameter', 'brake', 'surface'],
      builder: () => const RotorSweptAreaScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_pad_life',
      name: 'Brake Pad Life',
      subtitle: 'Estimate pad wear life',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'pad', 'life', 'wear', 'thickness', 'miles'],
      builder: () => const BrakePadLifeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_rotor_min_thickness',
      name: 'Rotor Min Thickness',
      subtitle: 'Check rotor specifications',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['rotor', 'minimum', 'thickness', 'discard', 'specification'],
      builder: () => const RotorMinThicknessScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_fluid_boiling',
      name: 'Brake Fluid Boiling',
      subtitle: 'Fluid boiling point reference',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'fluid', 'boiling', 'point', 'dot', 'temperature'],
      builder: () => const BrakeFluidBoilingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_proportioning',
      name: 'Brake Proportioning',
      subtitle: 'Calculate proportioning valve',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'proportioning', 'valve', 'rear', 'lockup', 'bias'],
      builder: () => const BrakeProportioningScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_abs_troubleshoot',
      name: 'ABS Troubleshoot',
      subtitle: 'ABS system diagnostics',
      icon: LucideIcons.alertCircle,
      category: ScreenCategory.calculators,
      searchTags: ['abs', 'troubleshoot', 'anti-lock', 'sensor', 'diagnostic'],
      builder: () => const AbsTroubleshootScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_rotor_spec',
      name: 'Brake Rotor Specs',
      subtitle: 'Rotor specifications lookup',
      icon: LucideIcons.fileText,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'rotor', 'spec', 'thickness', 'runout', 'diameter'],
      builder: () => const BrakeRotorSpecScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_brake_fluid_service',
      name: 'Brake Fluid Service',
      subtitle: 'Fluid change intervals',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'fluid', 'service', 'change', 'bleed', 'flush'],
      builder: () => const BrakeFluidServiceScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // SUSPENSION & ALIGNMENT
    // =========================================================================
    ScreenEntry(
      id: 'auto_spring_rate',
      name: 'Spring Rate',
      subtitle: 'Calculate spring rates',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.calculators,
      searchTags: ['spring', 'rate', 'stiffness', 'coil', 'lb/in', 'n/mm'],
      builder: () => const SpringRateScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_corner_weight',
      name: 'Corner Weight',
      subtitle: 'Calculate corner weights',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['corner', 'weight', 'balance', 'cross', 'diagonal', 'scaling'],
      builder: () => const CornerWeightScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_weight_distribution',
      name: 'Weight Distribution',
      subtitle: 'Calculate front/rear balance',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['weight', 'distribution', 'front', 'rear', 'balance', 'percentage'],
      builder: () => const WeightDistributionScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_weight_transfer',
      name: 'Weight Transfer',
      subtitle: 'Calculate dynamic weight transfer',
      icon: LucideIcons.arrowRightLeft,
      category: ScreenCategory.calculators,
      searchTags: ['weight', 'transfer', 'acceleration', 'braking', 'cornering'],
      builder: () => const WeightTransferScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_motion_ratio',
      name: 'Motion Ratio',
      subtitle: 'Calculate suspension motion ratio',
      icon: LucideIcons.move,
      category: ScreenCategory.calculators,
      searchTags: ['motion', 'ratio', 'suspension', 'wheel', 'spring', 'leverage'],
      builder: () => const MotionRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ride_height',
      name: 'Ride Height',
      subtitle: 'Measure and adjust ride height',
      icon: LucideIcons.alignVerticalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['ride', 'height', 'suspension', 'rake', 'level', 'stance'],
      builder: () => const RideHeightScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_camber',
      name: 'Camber',
      subtitle: 'Camber angle calculator',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['camber', 'angle', 'alignment', 'negative', 'positive', 'degrees'],
      builder: () => const CamberScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_caster',
      name: 'Caster',
      subtitle: 'Caster angle calculator',
      icon: LucideIcons.cornerUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['caster', 'angle', 'alignment', 'steering', 'stability'],
      builder: () => const CasterScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_toe',
      name: 'Toe',
      subtitle: 'Toe angle calculator',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['toe', 'angle', 'alignment', 'in', 'out', 'thrust'],
      builder: () => const ToeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_alignment_spec',
      name: 'Alignment Specs',
      subtitle: 'Vehicle alignment specifications',
      icon: LucideIcons.fileText,
      category: ScreenCategory.calculators,
      searchTags: ['alignment', 'spec', 'camber', 'caster', 'toe', 'reference'],
      builder: () => const AlignmentSpecScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bump_steer',
      name: 'Bump Steer',
      subtitle: 'Analyze bump steer geometry',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['bump', 'steer', 'geometry', 'suspension', 'tie', 'rod'],
      builder: () => const BumpSteerScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_anti_squat',
      name: 'Anti-Squat',
      subtitle: 'Calculate anti-squat geometry',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['anti', 'squat', 'geometry', 'suspension', 'acceleration'],
      builder: () => const AntiSquatScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_shock_sizing',
      name: 'Shock Sizing',
      subtitle: 'Calculate shock absorber specs',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.calculators,
      searchTags: ['shock', 'sizing', 'damper', 'length', 'travel', 'valving'],
      builder: () => const ShockSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_strut_mount',
      name: 'Strut Mount',
      subtitle: 'Strut mount specifications',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['strut', 'mount', 'bearing', 'top', 'hat', 'camber'],
      builder: () => const StrutMountScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bearing_preload',
      name: 'Bearing Preload',
      subtitle: 'Calculate bearing preload',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['bearing', 'preload', 'wheel', 'hub', 'torque', 'adjustment'],
      builder: () => const BearingPreloadScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // STEERING
    // =========================================================================
    ScreenEntry(
      id: 'auto_steering_ratio',
      name: 'Steering Ratio',
      subtitle: 'Calculate steering ratio',
      icon: LucideIcons.navigation,
      category: ScreenCategory.calculators,
      searchTags: ['steering', 'ratio', 'turns', 'lock', 'quick', 'rack'],
      builder: () => const SteeringRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ackermann_angle',
      name: 'Ackermann Angle',
      subtitle: 'Calculate steering geometry',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['ackermann', 'angle', 'steering', 'geometry', 'toe', 'out'],
      builder: () => const AckermannAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_power_steering_pressure',
      name: 'Power Steering Pressure',
      subtitle: 'PS system pressure specs',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'steering', 'pressure', 'psi', 'pump', 'test'],
      builder: () => const PowerSteeringPressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_power_steering_fluid',
      name: 'Power Steering Fluid',
      subtitle: 'PS fluid specifications',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'steering', 'fluid', 'type', 'atf', 'specs'],
      builder: () => const PowerSteeringFluidScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_steering_column_angle',
      name: 'Steering Column Angle',
      subtitle: 'Column angle specifications',
      icon: LucideIcons.cornerUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['steering', 'column', 'angle', 'tilt', 'u-joint'],
      builder: () => const SteeringColumnAngleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_tie_rod_length',
      name: 'Tie Rod Length',
      subtitle: 'Calculate tie rod specs',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['tie', 'rod', 'length', 'inner', 'outer', 'adjustment'],
      builder: () => const TieRodLengthScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_rack_travel',
      name: 'Rack Travel',
      subtitle: 'Steering rack travel specs',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['rack', 'travel', 'steering', 'pinion', 'turns'],
      builder: () => const RackTravelScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_scrub_radius',
      name: 'Scrub Radius',
      subtitle: 'Calculate steering scrub radius',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['scrub', 'radius', 'steering', 'kingpin', 'offset'],
      builder: () => const ScrubRadiusScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_kingpin_angle',
      name: 'Kingpin Angle',
      subtitle: 'Kingpin inclination specs',
      icon: LucideIcons.cornerDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['kingpin', 'angle', 'inclination', 'kpi', 'sai', 'steering'],
      builder: () => const KingpinAngleScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ELECTRICAL - 12V SYSTEMS
    // =========================================================================
    ScreenEntry(
      id: 'auto_voltage_drop_12v',
      name: 'Voltage Drop (12V)',
      subtitle: 'Calculate automotive voltage drop',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['voltage', 'drop', '12v', 'wire', 'gauge', 'automotive'],
      builder: () => const VoltageDrop12vScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wire_gauge',
      name: 'Wire Gauge',
      subtitle: 'Select proper wire gauge',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['wire', 'gauge', 'awg', 'ampacity', 'current', 'automotive'],
      builder: () => const WireGaugeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fuse_sizing',
      name: 'Fuse Sizing',
      subtitle: 'Calculate fuse amperage',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['fuse', 'sizing', 'amperage', 'circuit', 'protection'],
      builder: () => const FuseSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_relay_sizing',
      name: 'Relay Sizing',
      subtitle: 'Select proper relay',
      icon: LucideIcons.toggleRight,
      category: ScreenCategory.calculators,
      searchTags: ['relay', 'sizing', 'amperage', 'coil', 'contact', 'spdt'],
      builder: () => const RelaySizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_parasitic_draw',
      name: 'Parasitic Draw',
      subtitle: 'Test battery drain',
      icon: LucideIcons.batteryLow,
      category: ScreenCategory.calculators,
      searchTags: ['parasitic', 'draw', 'battery', 'drain', 'milliamps', 'test'],
      builder: () => const ParasiticDrawScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_battery_cca',
      name: 'Battery CCA',
      subtitle: 'Cold cranking amp requirements',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'cca', 'cold', 'cranking', 'amps', 'starting'],
      builder: () => const BatteryCcaScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cca_to_ah',
      name: 'CCA to Ah',
      subtitle: 'Convert CCA to amp-hours',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['cca', 'ah', 'amp', 'hours', 'convert', 'battery'],
      builder: () => const CcaToAhScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_battery_load_test',
      name: 'Battery Load Test',
      subtitle: 'Battery test procedures',
      icon: LucideIcons.batteryCharging,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'load', 'test', 'voltage', 'capacity', 'health'],
      builder: () => const BatteryLoadTestScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_alternator_sizing',
      name: 'Alternator Sizing',
      subtitle: 'Calculate alternator output',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['alternator', 'sizing', 'output', 'amps', 'charging', 'upgrade'],
      builder: () => const AlternatorSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_pulley_ratio',
      name: 'Pulley Ratio',
      subtitle: 'Calculate alternator pulley ratio',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['pulley', 'ratio', 'alternator', 'underdrive', 'overdrive'],
      builder: () => const PulleyRatioScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ohms_law_12v',
      name: "Ohm's Law (12V)",
      subtitle: 'Automotive electrical calculations',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['ohms', 'law', '12v', 'voltage', 'current', 'resistance'],
      builder: () => const OhmsLaw12vScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_led_resistor',
      name: 'LED Resistor',
      subtitle: 'Calculate LED current limiting',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['led', 'resistor', 'current', 'limiting', 'voltage', 'drop'],
      builder: () => const LedResistorScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_charging_system',
      name: 'Charging System',
      subtitle: 'Charging system diagnostics',
      icon: LucideIcons.batteryCharging,
      category: ScreenCategory.calculators,
      searchTags: ['charging', 'system', 'alternator', 'voltage', 'regulator'],
      builder: () => const ChargingSystemScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_headlight_aim',
      name: 'Headlight Aim',
      subtitle: 'Headlight aiming procedure',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['headlight', 'aim', 'adjustment', 'pattern', 'height'],
      builder: () => const HeadlightAimScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wiper_blade_size',
      name: 'Wiper Blade Size',
      subtitle: 'Wiper blade specifications',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['wiper', 'blade', 'size', 'length', 'driver', 'passenger'],
      builder: () => const WiperBladeSizeScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FUEL SYSTEM
    // =========================================================================
    ScreenEntry(
      id: 'auto_fuel_injector',
      name: 'Fuel Injector',
      subtitle: 'Calculate injector sizing',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'injector', 'sizing', 'cc', 'lb/hr', 'flow'],
      builder: () => const FuelInjectorScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_injector_duty',
      name: 'Injector Duty Cycle',
      subtitle: 'Calculate IDC percentage',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['injector', 'duty', 'cycle', 'idc', 'pulse', 'width'],
      builder: () => const InjectorDutyScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_afr',
      name: 'Air/Fuel Ratio',
      subtitle: 'Calculate AFR/lambda',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['air', 'fuel', 'ratio', 'afr', 'stoich', 'rich', 'lean'],
      builder: () => const AfrScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_lambda',
      name: 'Lambda',
      subtitle: 'Lambda calculations',
      icon: LucideIcons.divide,
      category: ScreenCategory.calculators,
      searchTags: ['lambda', 'afr', 'wideband', 'o2', 'sensor', 'stoich'],
      builder: () => const LambdaScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fuel_pump',
      name: 'Fuel Pump',
      subtitle: 'Calculate pump requirements',
      icon: LucideIcons.fuel,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'pump', 'flow', 'pressure', 'lph', 'gph'],
      builder: () => const FuelPumpScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fuel_line',
      name: 'Fuel Line',
      subtitle: 'Size fuel lines',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'line', 'size', 'diameter', 'an', 'flow'],
      builder: () => const FuelLineScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_e85_fuel',
      name: 'E85 Fuel',
      subtitle: 'E85 conversion calculations',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['e85', 'ethanol', 'fuel', 'flex', 'conversion', 'injector'],
      builder: () => const E85FuelScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bsfc',
      name: 'BSFC',
      subtitle: 'Brake specific fuel consumption',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['bsfc', 'brake', 'specific', 'fuel', 'consumption', 'efficiency'],
      builder: () => const BsfcScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_idle_speed',
      name: 'Idle Speed',
      subtitle: 'Idle speed specifications',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['idle', 'speed', 'rpm', 'iac', 'adjustment', 'specifications'],
      builder: () => const IdleSpeedScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FUEL ECONOMY & COSTS
    // =========================================================================
    ScreenEntry(
      id: 'auto_fuel_economy',
      name: 'Fuel Economy',
      subtitle: 'Calculate MPG/L per 100km',
      icon: LucideIcons.fuel,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'economy', 'mpg', 'mileage', 'consumption', 'efficiency'],
      builder: () => const FuelEconomyScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cost_per_mile',
      name: 'Cost Per Mile',
      subtitle: 'Calculate fuel cost per mile',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['cost', 'mile', 'fuel', 'expense', 'price', 'calculator'],
      builder: () => const CostPerMileScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trip_fuel_cost',
      name: 'Trip Fuel Cost',
      subtitle: 'Calculate trip fuel expenses',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['trip', 'fuel', 'cost', 'travel', 'distance', 'expense'],
      builder: () => const TripFuelCostScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ev_range',
      name: 'EV Range',
      subtitle: 'Calculate electric vehicle range',
      icon: LucideIcons.batteryFull,
      category: ScreenCategory.calculators,
      searchTags: ['ev', 'electric', 'range', 'battery', 'kwh', 'miles'],
      builder: () => const EvRangeScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FORCED INDUCTION - TURBO
    // =========================================================================
    ScreenEntry(
      id: 'auto_turbo_sizing',
      name: 'Turbo Sizing',
      subtitle: 'Calculate turbo requirements',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['turbo', 'sizing', 'compressor', 'cfm', 'horsepower', 'boost'],
      builder: () => const TurboSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_boost_pressure',
      name: 'Boost Pressure',
      subtitle: 'Calculate boost/power relationship',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['boost', 'pressure', 'psi', 'bar', 'turbo', 'power'],
      builder: () => const BoostPressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_boost_calculator',
      name: 'Boost Calculator',
      subtitle: 'Boost pressure calculations',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['boost', 'calculator', 'turbo', 'supercharger', 'psi'],
      builder: () => const BoostCalculatorScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_boost_by_gear',
      name: 'Boost by Gear',
      subtitle: 'Calculate boost per gear',
      icon: LucideIcons.barChart2,
      category: ScreenCategory.calculators,
      searchTags: ['boost', 'gear', 'turbo', 'lag', 'spool', 'rpm'],
      builder: () => const BoostByGearScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_compressor_map',
      name: 'Compressor Map',
      subtitle: 'Read turbo compressor maps',
      icon: LucideIcons.map,
      category: ScreenCategory.calculators,
      searchTags: ['compressor', 'map', 'turbo', 'efficiency', 'surge', 'choke'],
      builder: () => const CompressorMapScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_turbo_lag',
      name: 'Turbo Lag',
      subtitle: 'Analyze turbo response',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['turbo', 'lag', 'spool', 'response', 'a/r', 'housing'],
      builder: () => const TurboLagScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wastegate',
      name: 'Wastegate',
      subtitle: 'Wastegate sizing/setup',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['wastegate', 'boost', 'control', 'spring', 'actuator'],
      builder: () => const WastegateScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_bov',
      name: 'Blow-Off Valve',
      subtitle: 'BOV selection guide',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['bov', 'blow', 'off', 'valve', 'bypass', 'compressor', 'surge'],
      builder: () => const BovScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_intercooler',
      name: 'Intercooler',
      subtitle: 'Size intercooler requirements',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['intercooler', 'charge', 'air', 'cooling', 'fmic', 'tmic'],
      builder: () => const IntercoolerScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_intercooler_efficiency',
      name: 'Intercooler Efficiency',
      subtitle: 'Calculate IC efficiency',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['intercooler', 'efficiency', 'inlet', 'outlet', 'temperature'],
      builder: () => const IntercoolerEfficiencyScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_charge_air_temp',
      name: 'Charge Air Temp',
      subtitle: 'Charge air temperature effects',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['charge', 'air', 'temperature', 'iat', 'density', 'power'],
      builder: () => const ChargeAirTempScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FORCED INDUCTION - SUPERCHARGER & NITROUS
    // =========================================================================
    ScreenEntry(
      id: 'auto_supercharger_drive',
      name: 'Supercharger Drive',
      subtitle: 'Supercharger pulley sizing',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['supercharger', 'pulley', 'drive', 'ratio', 'overdrive', 'boost'],
      builder: () => const SuperchargerDriveScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_nitrous_sizing',
      name: 'Nitrous Sizing',
      subtitle: 'Size nitrous system',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['nitrous', 'sizing', 'jet', 'horsepower', 'shot', 'nos'],
      builder: () => const NitrousSizingScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // EXHAUST
    // =========================================================================
    ScreenEntry(
      id: 'auto_exhaust_pipe_size',
      name: 'Exhaust Pipe Size',
      subtitle: 'Calculate exhaust diameter',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['exhaust', 'pipe', 'size', 'diameter', 'flow', 'inch'],
      builder: () => const ExhaustPipeSizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_header_primary_size',
      name: 'Header Primary Size',
      subtitle: 'Calculate header tube size',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['header', 'primary', 'size', 'tube', 'diameter', 'length'],
      builder: () => const HeaderPrimarySizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_collector_size',
      name: 'Collector Size',
      subtitle: 'Header collector sizing',
      icon: LucideIcons.gitPullRequest,
      category: ScreenCategory.calculators,
      searchTags: ['collector', 'size', 'header', 'merge', 'exhaust'],
      builder: () => const CollectorSizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_muffler_sizing',
      name: 'Muffler Sizing',
      subtitle: 'Select muffler specifications',
      icon: LucideIcons.volumeX,
      category: ScreenCategory.calculators,
      searchTags: ['muffler', 'sizing', 'flow', 'sound', 'cfm', 'exhaust'],
      builder: () => const MufflerSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cat_converter',
      name: 'Catalytic Converter',
      subtitle: 'Cat converter specifications',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['catalytic', 'converter', 'cat', 'emissions', 'high', 'flow'],
      builder: () => const CatConverterScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_backpressure',
      name: 'Backpressure',
      subtitle: 'Calculate exhaust backpressure',
      icon: LucideIcons.arrowLeft,
      category: ScreenCategory.calculators,
      searchTags: ['backpressure', 'exhaust', 'restriction', 'flow', 'test'],
      builder: () => const BackpressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_scavenging_effect',
      name: 'Scavenging Effect',
      subtitle: 'Exhaust scavenging analysis',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['scavenging', 'exhaust', 'pulse', 'tuning', 'reversion'],
      builder: () => const ScavengingEffectScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_exhaust_wrap',
      name: 'Exhaust Wrap',
      subtitle: 'Header wrap calculator',
      icon: LucideIcons.package,
      category: ScreenCategory.calculators,
      searchTags: ['exhaust', 'wrap', 'header', 'heat', 'tape', 'length'],
      builder: () => const ExhaustWrapScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // COOLING SYSTEM
    // =========================================================================
    ScreenEntry(
      id: 'auto_coolant_mix',
      name: 'Coolant Mix',
      subtitle: 'Calculate coolant ratio',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['coolant', 'mix', 'antifreeze', 'ratio', 'water', 'percent'],
      builder: () => const CoolantMixScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_coolant_capacity',
      name: 'Coolant Capacity',
      subtitle: 'System capacity reference',
      icon: LucideIcons.database,
      category: ScreenCategory.calculators,
      searchTags: ['coolant', 'capacity', 'volume', 'quarts', 'liters'],
      builder: () => const CoolantCapacityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_freeze_point',
      name: 'Freeze Point',
      subtitle: 'Calculate freeze protection',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['freeze', 'point', 'coolant', 'antifreeze', 'temperature', 'protection'],
      builder: () => const FreezePointScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_boil_point',
      name: 'Boiling Point',
      subtitle: 'Calculate boil-over protection',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['boiling', 'point', 'coolant', 'temperature', 'pressure', 'cap'],
      builder: () => const BoilPointScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_radiator_sizing',
      name: 'Radiator Sizing',
      subtitle: 'Calculate radiator requirements',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['radiator', 'sizing', 'cooling', 'capacity', 'rows', 'core'],
      builder: () => const RadiatorSizingScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_radiator_size',
      name: 'Radiator Size',
      subtitle: 'Radiator dimensions reference',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['radiator', 'size', 'dimensions', 'width', 'height', 'thickness'],
      builder: () => const RadiatorSizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cooling_capacity',
      name: 'Cooling Capacity',
      subtitle: 'Calculate cooling system capacity',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'capacity', 'btu', 'heat', 'rejection', 'system'],
      builder: () => const CoolingCapacityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_heat_rejection',
      name: 'Heat Rejection',
      subtitle: 'Calculate engine heat output',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'rejection', 'btu', 'cooling', 'horsepower', 'thermal'],
      builder: () => const HeatRejectionScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_water_pump_flow',
      name: 'Water Pump Flow',
      subtitle: 'Calculate pump flow rate',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'pump', 'flow', 'gpm', 'cooling', 'circulation'],
      builder: () => const WaterPumpFlowScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_thermostat',
      name: 'Thermostat',
      subtitle: 'Thermostat specifications',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['thermostat', 'temperature', 'opening', 'rating', 'cooling'],
      builder: () => const ThermostatScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_thermostat_temp',
      name: 'Thermostat Temp',
      subtitle: 'Thermostat temperature selection',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['thermostat', 'temperature', 'degree', 'high', 'low', 'flow'],
      builder: () => const ThermostatTempScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_cooling_system_pressure',
      name: 'Cooling System Pressure',
      subtitle: 'Pressure cap specifications',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'system', 'pressure', 'cap', 'psi', 'radiator'],
      builder: () => const CoolingSystemPressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_electric_fan',
      name: 'Electric Fan',
      subtitle: 'Electric fan sizing',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['electric', 'fan', 'cfm', 'puller', 'pusher', 'cooling'],
      builder: () => const ElectricFanScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fan_cfm',
      name: 'Fan CFM',
      subtitle: 'Calculate fan airflow',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['fan', 'cfm', 'airflow', 'cooling', 'cubic', 'feet'],
      builder: () => const FanCfmScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_expansion_tank',
      name: 'Expansion Tank',
      subtitle: 'Overflow tank sizing',
      icon: LucideIcons.container,
      category: ScreenCategory.calculators,
      searchTags: ['expansion', 'tank', 'overflow', 'coolant', 'reservoir'],
      builder: () => const ExpansionTankScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_heater_core_flow',
      name: 'Heater Core Flow',
      subtitle: 'Heater core diagnostics',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heater', 'core', 'flow', 'heat', 'cabin', 'temperature'],
      builder: () => const HeaterCoreFlowScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_serpentine_belt',
      name: 'Serpentine Belt',
      subtitle: 'Belt length/routing',
      icon: LucideIcons.repeat,
      category: ScreenCategory.calculators,
      searchTags: ['serpentine', 'belt', 'length', 'routing', 'tensioner'],
      builder: () => const SerpentineBeltScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // A/C SYSTEM
    // =========================================================================
    ScreenEntry(
      id: 'auto_ac_pressure',
      name: 'A/C Pressure',
      subtitle: 'A/C system pressure specs',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'pressure', 'high', 'low', 'side', 'psi', 'refrigerant'],
      builder: () => const AcPressureScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ac_pressure_temp',
      name: 'A/C Pressure vs Temp',
      subtitle: 'Pressure/temperature chart',
      icon: LucideIcons.lineChart,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'pressure', 'temperature', 'chart', 'r134a', 'r1234yf'],
      builder: () => const AcPressureTempScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ac_charge',
      name: 'A/C Charge',
      subtitle: 'Refrigerant charge amount',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'charge', 'refrigerant', 'amount', 'ounces', 'grams'],
      builder: () => const AcChargeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_refrigerant_charge',
      name: 'Refrigerant Charge',
      subtitle: 'Calculate refrigerant amount',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'charge', 'r134a', 'r1234yf', 'capacity'],
      builder: () => const RefrigerantChargeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_superheat',
      name: 'Superheat',
      subtitle: 'Calculate A/C superheat',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['superheat', 'ac', 'temperature', 'evaporator', 'charge'],
      builder: () => const SuperheatScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_subcool',
      name: 'Subcooling',
      subtitle: 'Calculate A/C subcooling',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['subcool', 'subcooling', 'ac', 'condenser', 'liquid', 'line'],
      builder: () => const SubcoolScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_superheat_subcool',
      name: 'Superheat/Subcool',
      subtitle: 'Combined SH/SC calculations',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['superheat', 'subcool', 'ac', 'diagnosis', 'charge'],
      builder: () => const SuperheatSubcoolScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ac_vent_temp',
      name: 'A/C Vent Temp',
      subtitle: 'Expected vent temperatures',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'vent', 'temperature', 'outlet', 'performance'],
      builder: () => const AcVentTempScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_evaporator_temp',
      name: 'Evaporator Temp',
      subtitle: 'Evaporator temperature specs',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['evaporator', 'temperature', 'ac', 'freeze', 'icing'],
      builder: () => const EvaporatorTempScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_compressor_oil',
      name: 'Compressor Oil',
      subtitle: 'A/C compressor oil specs',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['compressor', 'oil', 'pag', 'poe', 'ounces', 'ac'],
      builder: () => const CompressorOilScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_orifice_tube',
      name: 'Orifice Tube',
      subtitle: 'Orifice tube color codes',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['orifice', 'tube', 'color', 'code', 'expansion', 'ac'],
      builder: () => const OrificeTubeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ac_clutch_gap',
      name: 'A/C Clutch Gap',
      subtitle: 'Compressor clutch air gap',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'clutch', 'gap', 'air', 'compressor', 'shim'],
      builder: () => const AcClutchGapScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_blend_door',
      name: 'Blend Door',
      subtitle: 'Blend door diagnostics',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['blend', 'door', 'actuator', 'hvac', 'heat', 'ac'],
      builder: () => const BlendDoorScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ac_diagnostic',
      name: 'A/C Diagnostic',
      subtitle: 'A/C system troubleshooting',
      icon: LucideIcons.search,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'diagnostic', 'troubleshoot', 'problem', 'repair'],
      builder: () => const AcDiagnosticScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // MAINTENANCE & SERVICE
    // =========================================================================
    ScreenEntry(
      id: 'auto_oil_capacity',
      name: 'Oil Capacity',
      subtitle: 'Engine oil capacity reference',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['oil', 'capacity', 'quarts', 'liters', 'engine', 'filter'],
      builder: () => const OilCapacityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_oil_change_interval',
      name: 'Oil Change Interval',
      subtitle: 'Service interval calculator',
      icon: LucideIcons.calendar,
      category: ScreenCategory.calculators,
      searchTags: ['oil', 'change', 'interval', 'miles', 'months', 'service'],
      builder: () => const OilChangeIntervalScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_timing_belt_interval',
      name: 'Timing Belt Interval',
      subtitle: 'Timing belt service schedule',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['timing', 'belt', 'interval', 'service', 'miles', 'replacement'],
      builder: () => const TimingBeltIntervalScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fluid_capacity',
      name: 'Fluid Capacity',
      subtitle: 'Vehicle fluid capacities',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['fluid', 'capacity', 'oil', 'coolant', 'transmission', 'differential'],
      builder: () => const FluidCapacityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_labor_time',
      name: 'Labor Time',
      subtitle: 'Estimate repair labor hours',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['labor', 'time', 'hours', 'repair', 'estimate', 'book'],
      builder: () => const LaborTimeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_emission_test',
      name: 'Emission Test',
      subtitle: 'Emission test specifications',
      icon: LucideIcons.cloud,
      category: ScreenCategory.calculators,
      searchTags: ['emission', 'test', 'smog', 'inspection', 'hc', 'co', 'nox'],
      builder: () => const EmissionTestScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // DIAGNOSTICS & OBD
    // =========================================================================
    ScreenEntry(
      id: 'auto_obd2_lookup',
      name: 'OBD-II Lookup',
      subtitle: 'Decode OBD-II trouble codes',
      icon: LucideIcons.search,
      category: ScreenCategory.calculators,
      searchTags: ['obd', 'obd2', 'code', 'dtc', 'diagnostic', 'trouble', 'p0'],
      builder: () => const Obd2LookupScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // PERFORMANCE - DRAG RACING
    // =========================================================================
    ScreenEntry(
      id: 'auto_quarter_mile',
      name: 'Quarter Mile',
      subtitle: 'Calculate 1/4 mile ET',
      icon: LucideIcons.flag,
      category: ScreenCategory.calculators,
      searchTags: ['quarter', 'mile', 'et', 'elapsed', 'time', 'drag', 'racing'],
      builder: () => const QuarterMileScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_sixty_foot',
      name: '60-Foot Time',
      subtitle: 'Analyze launch performance',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['sixty', 'foot', '60', 'launch', 'drag', 'racing', 'et'],
      builder: () => const SixtyFootScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trap_speed',
      name: 'Trap Speed',
      subtitle: 'Calculate trap speed/HP',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['trap', 'speed', 'mph', 'horsepower', 'quarter', 'mile'],
      builder: () => const TrapSpeedScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_power_to_weight',
      name: 'Power to Weight',
      subtitle: 'Calculate power/weight ratio',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'weight', 'ratio', 'hp', 'lb', 'kg', 'performance'],
      builder: () => const PowerToWeightScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // BODY & PAINT
    // =========================================================================
    ScreenEntry(
      id: 'auto_paint_coverage',
      name: 'Paint Coverage',
      subtitle: 'Calculate paint requirements',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.calculators,
      searchTags: ['paint', 'coverage', 'square', 'feet', 'quarts', 'gallons'],
      builder: () => const PaintCoverageScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_body_filler',
      name: 'Body Filler',
      subtitle: 'Calculate filler/hardener mix',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.calculators,
      searchTags: ['body', 'filler', 'bondo', 'hardener', 'ratio', 'mix'],
      builder: () => const BodyFillerScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // EV / HYBRID
    // =========================================================================
    ScreenEntry(
      id: 'auto_battery_capacity',
      name: 'Battery Capacity',
      subtitle: 'EV battery capacity and range',
      icon: LucideIcons.batteryFull,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'capacity', 'ev', 'electric', 'kwh', 'range'],
      builder: () => const BatteryCapacityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_battery_degradation',
      name: 'Battery Degradation',
      subtitle: 'EV battery health estimation',
      icon: LucideIcons.batteryLow,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'degradation', 'ev', 'health', 'capacity', 'aging'],
      builder: () => const BatteryDegradationScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_charging_cost',
      name: 'Charging Cost',
      subtitle: 'EV cost per charge',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['charging', 'cost', 'ev', 'electric', 'kwh', 'price'],
      builder: () => const ChargingCostScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_charging_time',
      name: 'Charging Time',
      subtitle: 'EV time to charge estimation',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['charging', 'time', 'ev', 'electric', 'hours', 'soc'],
      builder: () => const ChargingTimeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_dc_fast_charge',
      name: 'DC Fast Charge',
      subtitle: 'DC fast charging time and cost',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['dc', 'fast', 'charge', 'ev', 'electric', 'dcfc', 'level3'],
      builder: () => const DcFastChargeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_ev_efficiency',
      name: 'EV Efficiency',
      subtitle: 'Miles per kWh',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['ev', 'efficiency', 'kwh', 'miles', 'electric', 'consumption'],
      builder: () => const EvEfficiencyScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_hybrid_mpg',
      name: 'Hybrid MPG',
      subtitle: 'Hybrid vehicle fuel efficiency',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['hybrid', 'mpg', 'fuel', 'efficiency', 'electric', 'gas'],
      builder: () => const HybridMpgScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_break_even_mileage',
      name: 'Break Even Mileage',
      subtitle: 'EV vs gas break-even point',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['break', 'even', 'mileage', 'ev', 'gas', 'savings', 'payback'],
      builder: () => const BreakEvenMileageScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_regen_braking',
      name: 'Regen Braking',
      subtitle: 'Regenerative braking energy recovery',
      icon: LucideIcons.refreshCcw,
      category: ScreenCategory.calculators,
      searchTags: ['regen', 'regenerative', 'braking', 'ev', 'energy', 'recovery'],
      builder: () => const RegenBrakingScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // DRAG RACING / PERFORMANCE
    // =========================================================================
    ScreenEntry(
      id: 'auto_eighth_to_quarter',
      name: '1/8 to 1/4 Mile',
      subtitle: 'Convert 1/8 mile to 1/4 mile',
      icon: LucideIcons.flag,
      category: ScreenCategory.calculators,
      searchTags: ['eighth', 'quarter', 'mile', 'et', 'drag', 'racing', 'convert'],
      builder: () => const EighthToQuarterScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_hp_from_et',
      name: 'HP from ET',
      subtitle: 'Estimate HP from elapsed time',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['hp', 'horsepower', 'et', 'elapsed', 'time', 'drag', 'racing'],
      builder: () => const HpFromEtScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_hp_from_trap',
      name: 'HP from Trap Speed',
      subtitle: 'Estimate HP from trap speed',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['hp', 'horsepower', 'trap', 'speed', 'mph', 'drag', 'racing'],
      builder: () => const HpFromTrapScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_reaction_time',
      name: 'Reaction Time',
      subtitle: 'Bracket racing analysis',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['reaction', 'time', 'drag', 'racing', 'bracket', 'tree', 'rt'],
      builder: () => const ReactionTimeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_roll_race',
      name: 'Roll Race',
      subtitle: 'Roll race times and acceleration',
      icon: LucideIcons.arrowRight,
      category: ScreenCategory.calculators,
      searchTags: ['roll', 'race', 'racing', 'acceleration', 'speed', 'dig'],
      builder: () => const RollRaceScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_zero_to_sixty',
      name: '0-60 Time',
      subtitle: 'Estimate 0-60 times',
      icon: LucideIcons.rocket,
      category: ScreenCategory.calculators,
      searchTags: ['zero', 'sixty', '0-60', 'acceleration', 'time', 'performance'],
      builder: () => const ZeroToSixtyScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_dyno_correction',
      name: 'Dyno Correction',
      subtitle: 'SAE/STD correction factors',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['dyno', 'correction', 'sae', 'std', 'horsepower', 'weather'],
      builder: () => const DynoCorrectionScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // EXHAUST - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_exhaust_pipe',
      name: 'Exhaust Pipe',
      subtitle: 'Size exhaust for horsepower',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['exhaust', 'pipe', 'size', 'diameter', 'horsepower', 'flow'],
      builder: () => const ExhaustPipeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_header_primary',
      name: 'Header Primary',
      subtitle: 'Size primary tubes for headers',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['header', 'primary', 'tube', 'exhaust', 'size', 'length'],
      builder: () => const HeaderPrimaryScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_collector',
      name: 'Collector',
      subtitle: 'Size header collector for flow',
      icon: LucideIcons.gitPullRequest,
      category: ScreenCategory.calculators,
      searchTags: ['collector', 'header', 'exhaust', 'merge', 'size', 'flow'],
      builder: () => const CollectorScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_muffler',
      name: 'Muffler',
      subtitle: 'Size and select muffler',
      icon: LucideIcons.volumeX,
      category: ScreenCategory.calculators,
      searchTags: ['muffler', 'exhaust', 'sound', 'flow', 'size', 'selection'],
      builder: () => const MufflerScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_catalytic_converter',
      name: 'Catalytic Converter Sizing',
      subtitle: 'Size cat converter for engine',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['catalytic', 'converter', 'cat', 'sizing', 'emissions', 'volume'],
      builder: () => const CatalyticConverterScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // EMISSIONS
    // =========================================================================
    ScreenEntry(
      id: 'auto_emissions_prep',
      name: 'Emissions Prep',
      subtitle: 'Prepare vehicle for emissions test',
      icon: LucideIcons.clipboardCheck,
      category: ScreenCategory.calculators,
      searchTags: ['emissions', 'prep', 'smog', 'inspection', 'checklist', 'readiness'],
      builder: () => const EmissionsPrepScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_o2_sensor',
      name: 'O2 Sensor',
      subtitle: 'Diagnose O2 sensor readings',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['o2', 'oxygen', 'sensor', 'voltage', 'afr', 'diagnosis'],
      builder: () => const O2SensorScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ELECTRICAL - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_battery_finder',
      name: 'Battery Finder',
      subtitle: 'Battery group size reference',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'finder', 'group', 'size', 'cca', 'specifications'],
      builder: () => const BatteryFinderScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_light_bulb',
      name: 'Light Bulb',
      subtitle: 'Automotive light bulb reference',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['light', 'bulb', 'headlight', 'taillight', 'brake', 'turn'],
      builder: () => const LightBulbScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_sensor_range',
      name: 'Sensor Range',
      subtitle: 'Automotive sensor specifications',
      icon: LucideIcons.radio,
      category: ScreenCategory.calculators,
      searchTags: ['sensor', 'range', 'map', 'maf', 'tps', 'voltage', 'specs'],
      builder: () => const SensorRangeScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // BRAKES - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_brake_fluid_capacity',
      name: 'Brake Fluid Capacity',
      subtitle: 'Fluid type and capacity',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['brake', 'fluid', 'capacity', 'dot3', 'dot4', 'type'],
      builder: () => const BrakeFluidCapacityScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // ENGINE - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_belt_length',
      name: 'Belt Length',
      subtitle: 'Calculate serpentine/V-belt length',
      icon: LucideIcons.repeat,
      category: ScreenCategory.calculators,
      searchTags: ['belt', 'length', 'serpentine', 'v-belt', 'pulley', 'accessory'],
      builder: () => const BeltLengthScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_pulley_size',
      name: 'Pulley Size',
      subtitle: 'Calculate pulley ratios and speeds',
      icon: LucideIcons.settings,
      category: ScreenCategory.calculators,
      searchTags: ['pulley', 'size', 'ratio', 'speed', 'rpm', 'diameter'],
      builder: () => const PulleySizeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_timing_light',
      name: 'Timing Light',
      subtitle: 'Ignition timing reference',
      icon: LucideIcons.flashlight,
      category: ScreenCategory.calculators,
      searchTags: ['timing', 'light', 'ignition', 'advance', 'btdc', 'procedure'],
      builder: () => const TimingLightScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_head_bolt_torque',
      name: 'Head Bolt Torque',
      subtitle: 'Head bolt torque specifications',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['head', 'bolt', 'torque', 'tty', 'specs', 'sequence'],
      builder: () => const HeadBoltTorqueScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FUEL SYSTEM - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_fuel_pressure_reg',
      name: 'Fuel Pressure Regulator',
      subtitle: 'Fuel pressure diagnostics',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'pressure', 'regulator', 'diagnostics', 'psi', 'vacuum'],
      builder: () => const FuelPressureRegScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // FLUIDS
    // =========================================================================
    ScreenEntry(
      id: 'auto_oil_viscosity',
      name: 'Oil Viscosity',
      subtitle: 'Motor oil viscosity guide',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['oil', 'viscosity', '5w30', '0w20', 'motor', 'weight'],
      builder: () => const OilViscosityScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fluid_dilution',
      name: 'Fluid Dilution',
      subtitle: 'Calculate mixing ratios',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['fluid', 'dilution', 'mix', 'ratio', 'coolant', 'washer'],
      builder: () => const FluidDilutionScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // TOOLS & HARDWARE
    // =========================================================================
    ScreenEntry(
      id: 'auto_metric_sae',
      name: 'Metric/SAE',
      subtitle: 'Socket/wrench size conversion',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['metric', 'sae', 'socket', 'wrench', 'conversion', 'mm', 'inch'],
      builder: () => const MetricSaeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_fastener_torque',
      name: 'Fastener Torque',
      subtitle: 'General fastener torque lookup',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['fastener', 'torque', 'bolt', 'grade', 'specs', 'ft-lb'],
      builder: () => const FastenerTorqueScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_thread_pitch',
      name: 'Thread Pitch',
      subtitle: 'Thread pitch identification',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['thread', 'pitch', 'tpi', 'metric', 'identification', 'bolt'],
      builder: () => const ThreadPitchScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wheel_torque',
      name: 'Wheel Torque',
      subtitle: 'Lug nut torque specifications',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['wheel', 'torque', 'lug', 'nut', 'specifications', 'ft-lb'],
      builder: () => const WheelTorqueScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // REFERENCE & LOOKUP
    // =========================================================================
    ScreenEntry(
      id: 'auto_filter_cross_ref',
      name: 'Filter Cross Reference',
      subtitle: 'Filter size and cross-reference',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['filter', 'cross', 'reference', 'oil', 'air', 'interchange'],
      builder: () => const FilterCrossRefScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_vin_decoder',
      name: 'VIN Decoder',
      subtitle: 'Decode vehicle identification',
      icon: LucideIcons.fileSearch,
      category: ScreenCategory.calculators,
      searchTags: ['vin', 'decoder', 'vehicle', 'identification', 'number', 'lookup'],
      builder: () => const VinDecoderScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_paint_code',
      name: 'Paint Code',
      subtitle: 'Find vehicle paint code',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.calculators,
      searchTags: ['paint', 'code', 'color', 'location', 'touch', 'up'],
      builder: () => const PaintCodeScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_wiper_blade',
      name: 'Wiper Blade',
      subtitle: 'Wiper blade size reference',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['wiper', 'blade', 'size', 'driver', 'passenger', 'rear'],
      builder: () => const WiperBladeScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // MAINTENANCE - ADDITIONAL
    // =========================================================================
    ScreenEntry(
      id: 'auto_maintenance_schedule',
      name: 'Maintenance Schedule',
      subtitle: 'Track maintenance intervals',
      icon: LucideIcons.calendar,
      category: ScreenCategory.calculators,
      searchTags: ['maintenance', 'schedule', 'interval', 'service', 'due', 'mileage'],
      builder: () => const MaintenanceScheduleScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_warranty_expiration',
      name: 'Warranty Expiration',
      subtitle: 'Track vehicle warranty status',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['warranty', 'expiration', 'coverage', 'bumper', 'powertrain'],
      builder: () => const WarrantyExpirationScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // BUSINESS / SHOP
    // =========================================================================
    ScreenEntry(
      id: 'auto_job_estimate',
      name: 'Job Estimate',
      subtitle: 'Total repair cost estimation',
      icon: LucideIcons.fileText,
      category: ScreenCategory.calculators,
      searchTags: ['job', 'estimate', 'repair', 'cost', 'labor', 'parts'],
      builder: () => const JobEstimateScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_shop_rate',
      name: 'Shop Rate',
      subtitle: 'Calculate shop labor rates',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['shop', 'rate', 'labor', 'hourly', 'pricing', 'markup'],
      builder: () => const ShopRateScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_parts_markup',
      name: 'Parts Markup',
      subtitle: 'Calculate retail pricing',
      icon: LucideIcons.tag,
      category: ScreenCategory.calculators,
      searchTags: ['parts', 'markup', 'retail', 'cost', 'pricing', 'margin'],
      builder: () => const PartsMarkupScreen(),
      trade: 'auto',
    ),

    // =========================================================================
    // VEHICLE / TOWING
    // =========================================================================
    ScreenEntry(
      id: 'auto_depreciation',
      name: 'Depreciation',
      subtitle: 'Calculate vehicle depreciation',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['depreciation', 'value', 'resale', 'vehicle', 'worth', 'age'],
      builder: () => const DepreciationScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_payload',
      name: 'Payload',
      subtitle: 'Calculate payload capacity',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['payload', 'capacity', 'gvwr', 'weight', 'load', 'cargo'],
      builder: () => const PayloadScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_trailer_towing',
      name: 'Trailer Towing',
      subtitle: 'Towing capacity and safety',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['trailer', 'towing', 'capacity', 'tongue', 'weight', 'hitch'],
      builder: () => const TrailerTowingScreen(),
      trade: 'auto',
    ),
  ];
}
