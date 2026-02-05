import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ============================================================================
// EXTERNAL CALCULATOR ENTRY FILES
// ============================================================================
import 'auto_calculator_entries.dart';
import 'welding_calculator_entries.dart';
import 'pool_calculator_entries.dart';

// ============================================================================
// EXTERNAL DIAGRAM ENTRY FILES
// ============================================================================
import 'plumbing_diagram_entries.dart';
import 'hvac_diagram_entries.dart';
import 'solar_diagram_entries.dart';
import 'roofing_diagram_entries.dart';
import 'gc_diagram_entries.dart';
import 'remodeler_diagram_entries.dart';
import 'landscaping_diagram_entries.dart';
import 'auto_diagram_entries.dart';
import 'welding_diagram_entries.dart';
import 'pool_diagram_entries.dart';

// ============================================================================
// CALCULATORS - ELECTRICAL (55 screens)
// ============================================================================
import '../screens/calculators/ampacity_screen.dart';
import '../screens/calculators/box_fill_screen.dart';
import '../screens/calculators/cable_tray_screen.dart';
import '../screens/calculators/commercial_load_screen.dart';
import '../screens/calculators/conduit_bending_screen.dart';
import '../screens/calculators/conduit_fill_screen.dart';
import '../screens/calculators/continuous_load_screen.dart';
import '../screens/calculators/disconnect_screen.dart';
import '../screens/calculators/dryer_circuit_screen.dart';
import '../screens/calculators/dwelling_load_screen.dart';
import '../screens/calculators/electric_range_screen.dart';
import '../screens/calculators/ev_charger_screen.dart';
import '../screens/calculators/fault_current_screen.dart';
import '../screens/calculators/generator_sizing_screen.dart';
import '../screens/calculators/grounding_screen.dart';
import '../screens/calculators/lighting_sqft_screen.dart';
import '../screens/calculators/lumen_screen.dart';
import '../screens/calculators/motor_circuit_screen.dart';
import '../screens/calculators/motor_fla_screen.dart';
import '../screens/calculators/motor_inrush_screen.dart';
import '../screens/calculators/mwbc_screen.dart';
import '../screens/calculators/ohms_law_screen.dart';
import '../screens/calculators/parallel_conductor_screen.dart';
import '../screens/calculators/power_converter_screen.dart';
import '../screens/calculators/power_factor_screen.dart';
import '../screens/calculators/pull_box_screen.dart';
import '../screens/calculators/raceway_screen.dart';
import '../screens/calculators/service_entrance_screen.dart' as calc_service;
import '../screens/calculators/solar_pv_screen.dart';
import '../screens/calculators/tap_rule_screen.dart';
import '../screens/calculators/transformer_screen.dart';
import '../screens/calculators/unit_converter_screen.dart';
import '../screens/calculators/voltage_drop_screen.dart';
import '../screens/calculators/water_heater_screen.dart';
import '../screens/calculators/wire_sizing_screen.dart';
import '../screens/calculators/wire_pull_tension_screen.dart';
import '../screens/calculators/conductor_weight_screen.dart';
import '../screens/calculators/conduit_bend_radius_screen.dart';
import '../screens/calculators/conduit_support_spacing_screen.dart';
import '../screens/calculators/expansion_fitting_screen.dart';
import '../screens/calculators/working_space_screen.dart';
import '../screens/calculators/junction_box_sizing_screen.dart';
import '../screens/calculators/derating_advanced_screen.dart';
import '../screens/calculators/motor_starter_screen.dart';
import '../screens/calculators/vfd_sizing_screen.dart';
import '../screens/calculators/transformer_protection_screen.dart';
import '../screens/calculators/ground_rod_screen.dart';
import '../screens/calculators/bonding_jumper_screen.dart';
import '../screens/calculators/arc_flash_screen.dart';
import '../screens/calculators/hvac_circuit_screen.dart';
import '../screens/calculators/pool_spa_screen.dart';
import '../screens/calculators/kitchen_circuit_screen.dart';
import '../screens/calculators/bathroom_circuit_screen.dart';
import '../screens/calculators/recessed_light_screen.dart';
import '../screens/calculators/ups_sizing_screen.dart';

// ============================================================================
// CALCULATORS - PLUMBING (107 screens)
// ============================================================================
import '../screens/calculators/plumbing/acid_waste_screen.dart';
import '../screens/calculators/plumbing/air_gap_screen.dart';
import '../screens/calculators/plumbing/backflow_preventer_screen.dart';
import '../screens/calculators/plumbing/bidet_rough_in_screen.dart';
import '../screens/calculators/plumbing/btu_cfh_converter_screen.dart';
import '../screens/calculators/plumbing/building_drain_screen.dart';
import '../screens/calculators/plumbing/building_sewer_screen.dart';
import '../screens/calculators/plumbing/circulator_pump_screen.dart';
import '../screens/calculators/plumbing/cleanout_placement_screen.dart';
import '../screens/calculators/plumbing/cleanout_sizing_screen.dart';
import '../screens/calculators/plumbing/coffee_service_screen.dart';
import '../screens/calculators/plumbing/commercial_kitchen_screen.dart';
import '../screens/calculators/plumbing/compressed_air_screen.dart';
import '../screens/calculators/plumbing/cross_connection_screen.dart';
import '../screens/calculators/plumbing/dental_chair_screen.dart';
import '../screens/calculators/plumbing/dfu_calculator_screen.dart';
import '../screens/calculators/plumbing/dishwasher_commercial_screen.dart';
import '../screens/calculators/plumbing/double_check_valve_screen.dart';
import '../screens/calculators/plumbing/drain_field_screen.dart';
import '../screens/calculators/plumbing/drain_slope_screen.dart';
import '../screens/calculators/plumbing/drinking_fountain_screen.dart';
import '../screens/calculators/plumbing/drip_irrigation_screen.dart';
import '../screens/calculators/plumbing/dwv_pipe_sizing_screen.dart';
import '../screens/calculators/plumbing/ejector_pump_screen.dart';
import '../screens/calculators/plumbing/emergency_shower_screen.dart';
import '../screens/calculators/plumbing/expansion_tank_screen.dart';
import '../screens/calculators/plumbing/eyewash_station_screen.dart';
import '../screens/calculators/plumbing/fire_sprinkler_screen.dart';
import '../screens/calculators/plumbing/firestop_screen.dart';
import '../screens/calculators/plumbing/first_hour_rating_screen.dart';
import '../screens/calculators/plumbing/fixture_count_screen.dart';
import '../screens/calculators/plumbing/floor_drain_screen.dart';
import '../screens/calculators/plumbing/floor_sink_screen.dart';
import '../screens/calculators/plumbing/flow_conversion_screen.dart';
import '../screens/calculators/plumbing/flow_rate_screen.dart';
import '../screens/calculators/plumbing/gas_meter_sizing_screen.dart';
import '../screens/calculators/plumbing/gas_pipe_sizing_screen.dart' as plumbing_gas;
import '../screens/calculators/plumbing/gas_pressure_drop_screen.dart';
import '../screens/calculators/plumbing/glycol_mix_screen.dart';
import '../screens/calculators/plumbing/graywater_screen.dart';
import '../screens/calculators/plumbing/grease_interceptor_screen.dart';
import '../screens/calculators/plumbing/heat_pump_water_heater_screen.dart';
import '../screens/calculators/plumbing/heat_tape_screen.dart';
import '../screens/calculators/plumbing/horizontal_branch_screen.dart';
import '../screens/calculators/plumbing/hose_bib_screen.dart';
import '../screens/calculators/plumbing/ice_maker_screen.dart';
import '../screens/calculators/plumbing/irrigation_sizing_screen.dart';
import '../screens/calculators/plumbing/kitchen_sink_rough_in_screen.dart';
import '../screens/calculators/plumbing/laundry_commercial_screen.dart';
import '../screens/calculators/plumbing/lavatory_rough_in_screen.dart';
import '../screens/calculators/plumbing/medical_gas_screen.dart';
import '../screens/calculators/plumbing/mixing_valve_screen.dart';
import '../screens/calculators/plumbing/mop_sink_screen.dart';
import '../screens/calculators/plumbing/pipe_hanger_screen.dart';
import '../screens/calculators/plumbing/pipe_insulation_screen.dart';
import '../screens/calculators/plumbing/pipe_pressure_drop_screen.dart';
import '../screens/calculators/plumbing/pipe_sleeve_screen.dart';
import '../screens/calculators/plumbing/pipe_support_screen.dart';
import '../screens/calculators/plumbing/pipe_weight_screen.dart';
import '../screens/calculators/plumbing/point_of_use_heater_screen.dart';
import '../screens/calculators/plumbing/pool_plumbing_screen.dart';
import '../screens/calculators/plumbing/pressure_booster_pump_screen.dart';
import '../screens/calculators/plumbing/pressure_conversion_screen.dart';
import '../screens/calculators/plumbing/prv_sizing_screen.dart';
import '../screens/calculators/plumbing/radiant_floor_screen.dart';
import '../screens/calculators/plumbing/rainwater_harvesting_screen.dart';
import '../screens/calculators/plumbing/recirculation_system_screen.dart';
import '../screens/calculators/plumbing/recovery_rate_screen.dart';
import '../screens/calculators/plumbing/reverse_osmosis_screen.dart';
import '../screens/calculators/plumbing/rpz_sizing_screen.dart';
import '../screens/calculators/plumbing/seismic_bracing_screen.dart';
import '../screens/calculators/plumbing/septic_tank_screen.dart';
import '../screens/calculators/plumbing/shower_rough_in_screen.dart';
import '../screens/calculators/plumbing/solar_water_heater_screen.dart';
import '../screens/calculators/plumbing/stack_sizing_screen.dart';
import '../screens/calculators/plumbing/static_pressure_screen.dart' as plumbing_static;
import '../screens/calculators/plumbing/storm_drain_screen.dart';
import '../screens/calculators/plumbing/sump_pump_screen.dart';
import '../screens/calculators/plumbing/tankless_sizing_screen.dart';
import '../screens/calculators/plumbing/temperature_conversion_screen.dart';
import '../screens/calculators/plumbing/thermal_expansion_screen.dart';
import '../screens/calculators/plumbing/thrust_block_screen.dart';
import '../screens/calculators/plumbing/toilet_rough_in_screen.dart';
import '../screens/calculators/plumbing/total_dynamic_head_screen.dart';
import '../screens/calculators/plumbing/trap_arm_screen.dart';
import '../screens/calculators/plumbing/trap_primer_screen.dart';
import '../screens/calculators/plumbing/tub_rough_in_screen.dart';
import '../screens/calculators/plumbing/urinal_rough_in_screen.dart';
import '../screens/calculators/plumbing/utility_sink_rough_in_screen.dart';
import '../screens/calculators/plumbing/uv_treatment_screen.dart';
import '../screens/calculators/plumbing/vacuum_breaker_screen.dart';
import '../screens/calculators/plumbing/vent_sizing_screen.dart';
import '../screens/calculators/plumbing/washing_machine_screen.dart';
import '../screens/calculators/plumbing/water_closet_carrier_screen.dart';
import '../screens/calculators/plumbing/water_demand_screen.dart';
import '../screens/calculators/plumbing/water_distribution_screen.dart';
import '../screens/calculators/plumbing/water_filter_sizing_screen.dart';
import '../screens/calculators/plumbing/water_hammer_screen.dart';
import '../screens/calculators/plumbing/water_heater_sizing_screen.dart';
import '../screens/calculators/plumbing/water_meter_sizing_screen.dart';
import '../screens/calculators/plumbing/water_service_sizing_screen.dart';
import '../screens/calculators/plumbing/water_softener_screen.dart';
import '../screens/calculators/plumbing/water_supply_pipe_screen.dart';
import '../screens/calculators/plumbing/water_test_screen.dart';
import '../screens/calculators/plumbing/water_velocity_screen.dart';
import '../screens/calculators/plumbing/well_pump_screen.dart';
import '../screens/calculators/plumbing/wet_vent_screen.dart';
import '../screens/calculators/plumbing/wsfu_calculator_screen.dart';

// ============================================================================
// CALCULATORS - HVAC (14 screens)
// ============================================================================
import '../screens/calculators/hvac/heat_load_screen.dart';
import '../screens/calculators/hvac/cooling_load_screen.dart';
import '../screens/calculators/hvac/duct_sizing_screen.dart';
import '../screens/calculators/hvac/cfm_room_screen.dart';
import '../screens/calculators/hvac/refrigerant_charge_screen.dart';
import '../screens/calculators/hvac/static_pressure_screen.dart' as hvac_static;
import '../screens/calculators/hvac/blower_door_screen.dart';
import '../screens/calculators/hvac/ventilation_screen.dart';
import '../screens/calculators/hvac/superheat_subcooling_screen.dart';
import '../screens/calculators/hvac/btu_calculator_screen.dart';
import '../screens/calculators/hvac/gas_pipe_sizing_screen.dart' as hvac_gas;
import '../screens/calculators/hvac/humidity_screen.dart';
import '../screens/calculators/hvac/filter_sizing_screen.dart';
import '../screens/calculators/hvac/temperature_rise_screen.dart';

// ============================================================================
// CALCULATORS - HVAC OVERFLOW (100+ screens built in main folder)
// These calculators were built during Session 4 HVAC sprint but placed in
// the main calculators folder instead of hvac/ subfolder.
// ============================================================================
import '../screens/calculators/ac_tonnage_screen.dart';
import '../screens/calculators/ahu_sizing_screen.dart';
import '../screens/calculators/air_balance_screen.dart';
import '../screens/calculators/air_changes_screen.dart';
import '../screens/calculators/air_handler_sizing_screen.dart';
import '../screens/calculators/airflow_balance_screen.dart';
import '../screens/calculators/airflow_hood_screen.dart';
import '../screens/calculators/belt_tension_screen.dart';
import '../screens/calculators/blower_door_screen.dart' as main_blower;
import '../screens/calculators/blower_motor_screen.dart';
import '../screens/calculators/boiler_efficiency_screen.dart';
import '../screens/calculators/boiler_sizing_screen.dart';
import '../screens/calculators/brazing_calc_screen.dart';
import '../screens/calculators/building_pressure_screen.dart';
import '../screens/calculators/chiller_cop_screen.dart';
import '../screens/calculators/chiller_sizing_screen.dart';
import '../screens/calculators/clean_room_screen.dart';
import '../screens/calculators/co2_ventilation_screen.dart';
import '../screens/calculators/coil_bypass_factor_screen.dart';
import '../screens/calculators/coil_selection_screen.dart';
import '../screens/calculators/combustion_air_screen.dart';
import '../screens/calculators/compressor_amp_draw_screen.dart';
import '../screens/calculators/compressor_capacity_screen.dart';
import '../screens/calculators/compressor_oil_screen.dart';
import '../screens/calculators/condensate_drain_screen.dart';
import '../screens/calculators/condenser_split_screen.dart';
import '../screens/calculators/condenser_td_screen.dart';
import '../screens/calculators/control_valve_screen.dart';
import '../screens/calculators/cooling_coil_screen.dart';
import '../screens/calculators/cooling_tower_screen.dart';
import '../screens/calculators/damper_sizing_screen.dart';
import '../screens/calculators/data_center_cooling_screen.dart';
import '../screens/calculators/defrost_cycle_screen.dart';
import '../screens/calculators/dehumidifier_sizing_screen.dart';
import '../screens/calculators/delta_t_screen.dart';
import '../screens/calculators/drain_pan_screen.dart';
import '../screens/calculators/duct_insulation_screen.dart';
import '../screens/calculators/duct_leakage_screen.dart';
import '../screens/calculators/duct_velocity_screen.dart';
import '../screens/calculators/economizer_screen.dart';
import '../screens/calculators/energy_recovery_screen.dart';
import '../screens/calculators/enthalpy_screen.dart';
import '../screens/calculators/erv_hrv_sizing_screen.dart';
import '../screens/calculators/evacuation_time_screen.dart';
import '../screens/calculators/evaporator_split_screen.dart';
import '../screens/calculators/evaporator_td_screen.dart';
import '../screens/calculators/exhaust_fan_screen.dart';
import '../screens/calculators/expansion_tank_screen.dart' as main_expansion;
import '../screens/calculators/fan_affinity_screen.dart';
import '../screens/calculators/fan_coil_screen.dart';
import '../screens/calculators/fan_law_screen.dart';
import '../screens/calculators/filter_pressure_screen.dart';
import '../screens/calculators/filter_sizing_screen.dart' as main_filter;
import '../screens/calculators/flue_sizing_screen.dart';
import '../screens/calculators/friction_rate_screen.dart';
import '../screens/calculators/furnace_sizing_screen.dart';
import '../screens/calculators/gas_pipe_sizing_screen.dart' as main_gas;
import '../screens/calculators/geothermal_loop_screen.dart';
import '../screens/calculators/glycol_freeze_screen.dart';
import '../screens/calculators/glycol_mix_screen.dart' as main_glycol;
import '../screens/calculators/grille_diffuser_screen.dart';
import '../screens/calculators/heat_exchanger_screen.dart';
import '../screens/calculators/heat_pump_balance_point_screen.dart';
import '../screens/calculators/heat_pump_sizing_screen.dart';
import '../screens/calculators/humidifier_sizing_screen.dart';
import '../screens/calculators/hydronic_flow_screen.dart';
import '../screens/calculators/hydronic_pipe_screen.dart';
import '../screens/calculators/infiltration_screen.dart';
import '../screens/calculators/kitchen_exhaust_screen.dart';
import '../screens/calculators/lab_exhaust_screen.dart';
import '../screens/calculators/latent_load_screen.dart';
import '../screens/calculators/makeup_air_screen.dart';
import '../screens/calculators/manual_j_screen.dart';
import '../screens/calculators/mini_split_sizing_screen.dart';
import '../screens/calculators/motor_run_capacitor_screen.dart';
import '../screens/calculators/motor_troubleshoot_screen.dart';
import '../screens/calculators/nitrogen_test_screen.dart';
import '../screens/calculators/pid_tuning_screen.dart';
import '../screens/calculators/pipe_expansion_screen.dart';
import '../screens/calculators/psychrometric_screen.dart';
import '../screens/calculators/ptac_sizing_screen.dart';
import '../screens/calculators/pump_affinity_screen.dart';
import '../screens/calculators/pump_head_screen.dart';
import '../screens/calculators/radiant_floor_screen.dart' as main_radiant;
import '../screens/calculators/radiant_panel_screen.dart';
import '../screens/calculators/refrigerant_charge_screen.dart' as main_refrig;
import '../screens/calculators/refrigerant_leak_rate_screen.dart';
import '../screens/calculators/refrigerant_line_screen.dart';
import '../screens/calculators/refrigerant_pt_chart_screen.dart';
import '../screens/calculators/refrigerant_recovery_screen.dart';
import '../screens/calculators/room_load_screen.dart';
import '../screens/calculators/round_to_rectangular_screen.dart';
import '../screens/calculators/sensible_heat_ratio_screen.dart';
import '../screens/calculators/server_room_cooling_screen.dart';
import '../screens/calculators/setpoint_reset_screen.dart';
import '../screens/calculators/snow_melt_screen.dart';
import '../screens/calculators/sound_attenuation_screen.dart';
import '../screens/calculators/split_system_lineset_screen.dart';
import '../screens/calculators/steam_pipe_screen.dart';
import '../screens/calculators/steam_trap_screen.dart';
import '../screens/calculators/supply_register_screen.dart';
import '../screens/calculators/system_curve_screen.dart';
import '../screens/calculators/thermal_storage_screen.dart';
import '../screens/calculators/txv_sizing_screen.dart';
import '../screens/calculators/unit_heater_screen.dart';
import '../screens/calculators/vav_box_screen.dart';
import '../screens/calculators/vrf_piping_screen.dart';
import '../screens/calculators/walk_in_cooler_screen.dart';

// ============================================================================
// CALCULATORS - ADDITIONAL ELECTRICAL (40+ screens)
// Built during various sessions, need registration
// ============================================================================
import '../screens/calculators/audio_video_wire_screen.dart';
import '../screens/calculators/available_fault_current_screen.dart';
import '../screens/calculators/battery_bank_screen.dart';
import '../screens/calculators/battery_circuit_protection_screen.dart';
import '../screens/calculators/buck_boost_screen.dart';
import '../screens/calculators/capacitor_bank_screen.dart';
import '../screens/calculators/capacitor_sizing_screen.dart';
import '../screens/calculators/conduit_length_estimator_screen.dart';
import '../screens/calculators/dedicated_space_screen.dart';
import '../screens/calculators/demand_factor_screen.dart';
import '../screens/calculators/doorbell_transformer_screen.dart';
import '../screens/calculators/emergency_lighting_screen.dart';
import '../screens/calculators/emergency_standby_load_screen.dart';
import '../screens/calculators/enclosure_sizing_screen.dart';
import '../screens/calculators/exit_sign_placement_screen.dart';
import '../screens/calculators/feeder_calculator_screen.dart';
import '../screens/calculators/fire_alarm_circuit_screen.dart';
import '../screens/calculators/fleet_charging_screen.dart';
import '../screens/calculators/ground_ring_screen.dart';
import '../screens/calculators/harmonics_screen.dart';
import '../screens/calculators/intersystem_bonding_screen.dart';
import '../screens/calculators/inverter_charger_screen.dart';
import '../screens/calculators/lighting_control_screen.dart';
import '../screens/calculators/motor_disconnect_screen.dart';
import '../screens/calculators/motor_feeder_screen.dart';
import '../screens/calculators/multi_charger_load_screen.dart';
import '../screens/calculators/multifamily_screen.dart';
import '../screens/calculators/network_cable_screen.dart';
import '../screens/calculators/optional_calculation_screen.dart';
import '../screens/calculators/parking_lot_lighting_screen.dart';
import '../screens/calculators/restaurant_load_screen.dart';
import '../screens/calculators/security_system_wire_screen.dart';
import '../screens/calculators/selective_coordination_screen.dart';
import '../screens/calculators/series_rating_screen.dart';
import '../screens/calculators/soft_start_screen.dart';
import '../screens/calculators/standalone_ess_screen.dart';
import '../screens/calculators/surge_protector_screen.dart';
import '../screens/calculators/thermostat_wire_screen.dart';
import '../screens/calculators/thermostat_wiring_screen.dart' as main_tstat;
import '../screens/calculators/transformer_impedance_screen.dart';
import '../screens/calculators/transformer_sizing_screen.dart';
import '../screens/calculators/transformer_taps_screen.dart';
import '../screens/calculators/voltage_imbalance_screen.dart';
import '../screens/calculators/wireway_fill_screen.dart';

// ============================================================================
// CALCULATORS - SOLAR (91 screens)
// ============================================================================
import '../screens/calculators/solar/system_size_screen.dart';
import '../screens/calculators/solar/panel_count_screen.dart';
import '../screens/calculators/solar/roof_area_screen.dart';
import '../screens/calculators/solar/production_estimator_screen.dart';
import '../screens/calculators/solar/utility_bill_analyzer_screen.dart';
import '../screens/calculators/solar/solar_fraction_screen.dart';
import '../screens/calculators/solar/capacity_factor_screen.dart';
import '../screens/calculators/solar/specific_yield_screen.dart';
import '../screens/calculators/solar/performance_ratio_screen.dart';
import '../screens/calculators/solar/dc_ac_ratio_screen.dart';
// Solar Geometry
import '../screens/calculators/solar/azimuth_screen.dart';
import '../screens/calculators/solar/tilt_angle_screen.dart';
import '../screens/calculators/solar/sun_path_screen.dart';
import '../screens/calculators/solar/shade_analysis_screen.dart';
import '../screens/calculators/solar/row_spacing_screen.dart';
import '../screens/calculators/solar/inter_row_shading_screen.dart';
import '../screens/calculators/solar/module_orientation_screen.dart';
import '../screens/calculators/solar/effective_irradiance_screen.dart';
// String Sizing
import '../screens/calculators/solar/string_size_screen.dart';
import '../screens/calculators/solar/voc_calculator_screen.dart';
import '../screens/calculators/solar/vmp_calculator_screen.dart';
import '../screens/calculators/solar/isc_calculator_screen.dart';
import '../screens/calculators/solar/imp_calculator_screen.dart';
import '../screens/calculators/solar/temp_coefficient_screen.dart';
import '../screens/calculators/solar/max_system_voltage_screen.dart';
import '../screens/calculators/solar/mppt_window_screen.dart';
import '../screens/calculators/solar/string_combiner_screen.dart';
// Inverter Sizing
import '../screens/calculators/solar/central_inverter_screen.dart';
import '../screens/calculators/solar/microinverter_screen.dart';
import '../screens/calculators/solar/clipping_analysis_screen.dart';
import '../screens/calculators/solar/inverter_efficiency_screen.dart';
// Financial
import '../screens/calculators/solar/simple_payback_screen.dart';
import '../screens/calculators/solar/federal_itc_screen.dart';
// Battery Storage
import '../screens/calculators/solar/battery_size_screen.dart';
// Financial (continued)
import '../screens/calculators/solar/irr_calculator_screen.dart';
import '../screens/calculators/solar/cash_flow_projector_screen.dart';
import '../screens/calculators/solar/state_incentive_lookup_screen.dart';
import '../screens/calculators/solar/srec_value_calculator_screen.dart';
import '../screens/calculators/solar/tou_rate_optimizer_screen.dart';
import '../screens/calculators/solar/demand_charge_reducer_screen.dart';
import '../screens/calculators/solar/lease_vs_ppa_screen.dart';
// Mounting & Structural
import '../screens/calculators/solar/roof_load_calculator_screen.dart';
import '../screens/calculators/solar/wind_load_calculator_screen.dart';
import '../screens/calculators/solar/snow_load_calculator_screen.dart';
import '../screens/calculators/solar/attachment_spacing_screen.dart';
import '../screens/calculators/solar/rail_span_calculator_screen.dart';
import '../screens/calculators/solar/ground_mount_foundation_screen.dart';
import '../screens/calculators/solar/ballasted_system_weight_screen.dart';
import '../screens/calculators/solar/carport_sizing_screen.dart';
import '../screens/calculators/solar/tracker_roi_screen.dart';
// Code Compliance
import '../screens/calculators/solar/fire_setback_screen.dart';
import '../screens/calculators/solar/roof_access_pathways_screen.dart';
import '../screens/calculators/solar/ventilation_setbacks_screen.dart';
import '../screens/calculators/solar/interconnection_calculator_screen.dart';
import '../screens/calculators/solar/main_panel_evaluation_screen.dart';
import '../screens/calculators/solar/load_side_supply_side_screen.dart';
// Inverter Sizing (continued)
import '../screens/calculators/solar/string_inverter_match_screen.dart';
import '../screens/calculators/solar/power_optimizer_match_screen.dart';
import '../screens/calculators/solar/derating_factors_screen.dart';
import '../screens/calculators/solar/three_phase_balance_screen.dart';
// Wiring & Conductors
import '../screens/calculators/solar/dc_wire_sizing_screen.dart';
import '../screens/calculators/solar/ac_wire_sizing_screen.dart';
import '../screens/calculators/solar/dc_voltage_drop_screen.dart';
import '../screens/calculators/solar/ac_voltage_drop_screen.dart';
import '../screens/calculators/solar/conduit_fill_solar_screen.dart';
import '../screens/calculators/solar/home_run_length_screen.dart';
import '../screens/calculators/solar/wire_type_selection_screen.dart';
// Disconnects & Protection
import '../screens/calculators/solar/dc_disconnect_sizing_screen.dart';
import '../screens/calculators/solar/ac_disconnect_sizing_screen.dart';
import '../screens/calculators/solar/ocpd_dc_screen.dart';
import '../screens/calculators/solar/ocpd_ac_screen.dart';
import '../screens/calculators/solar/rapid_shutdown_screen.dart';
import '../screens/calculators/solar/ground_fault_protection_screen.dart';
import '../screens/calculators/solar/arc_fault_detection_screen.dart';
import '../screens/calculators/solar/grounding_electrode_screen.dart' as solar_grounding;
import '../screens/calculators/solar/equipment_grounding_screen.dart';
// Battery Storage (continued)
import '../screens/calculators/solar/backup_duration_screen.dart';
import '../screens/calculators/solar/critical_load_screen.dart';
import '../screens/calculators/solar/depth_of_discharge_screen.dart';
import '../screens/calculators/solar/cycle_life_estimator_screen.dart';
import '../screens/calculators/solar/round_trip_efficiency_screen.dart';
import '../screens/calculators/solar/battery_inverter_sizing_screen.dart';
import '../screens/calculators/solar/charge_controller_sizing_screen.dart';
import '../screens/calculators/solar/battery_bank_screen.dart' as solar_battery_bank;
import '../screens/calculators/solar/generator_battery_screen.dart';
// Financial (more)
import '../screens/calculators/solar/roi_calculator_screen.dart';
import '../screens/calculators/solar/npv_calculator_screen.dart';
import '../screens/calculators/solar/lcoe_calculator_screen.dart';
import '../screens/calculators/solar/utility_bill_savings_screen.dart';
import '../screens/calculators/solar/net_metering_screen.dart';
import '../screens/calculators/solar/loan_vs_cash_screen.dart';

// ============================================================================
// CALCULATORS - ROOFING (80 screens)
// ============================================================================
import '../screens/calculators/roofing/attic_vent_screen.dart';
import '../screens/calculators/roofing/bird_stop_screen.dart';
import '../screens/calculators/roofing/built_up_roof_screen.dart';
import '../screens/calculators/roofing/chimney_flashing_screen.dart';
import '../screens/calculators/roofing/collar_tie_screen.dart';
import '../screens/calculators/roofing/cool_roof_screen.dart';
import '../screens/calculators/roofing/corrugated_panel_screen.dart';
import '../screens/calculators/roofing/counter_flashing_screen.dart';
import '../screens/calculators/roofing/disposal_cost_screen.dart';
import '../screens/calculators/roofing/dormer_area_screen.dart';
import '../screens/calculators/roofing/downspout_screen.dart';
import '../screens/calculators/roofing/drip_edge_screen.dart';
import '../screens/calculators/roofing/dutch_hip_screen.dart';
import '../screens/calculators/roofing/epdm_membrane_screen.dart';
import '../screens/calculators/roofing/fascia_board_screen.dart';
import '../screens/calculators/roofing/felt_underlayment_screen.dart';
import '../screens/calculators/roofing/flat_roof_screen.dart';
import '../screens/calculators/roofing/flashing_screen.dart';
import '../screens/calculators/roofing/gable_roof_screen.dart';
import '../screens/calculators/roofing/gable_vent_screen.dart';
import '../screens/calculators/roofing/gambrel_roof_screen.dart';
import '../screens/calculators/roofing/gutter_hanger_screen.dart';
import '../screens/calculators/roofing/gutter_size_screen.dart';
import '../screens/calculators/roofing/gutter_slope_screen.dart';
import '../screens/calculators/roofing/heat_cable_screen.dart';
import '../screens/calculators/roofing/hip_roof_screen.dart';
import '../screens/calculators/roofing/ice_dam_screen.dart';
import '../screens/calculators/roofing/ice_water_shield_screen.dart';
import '../screens/calculators/roofing/kick_out_flashing_screen.dart';
import '../screens/calculators/roofing/labor_hours_screen.dart';
import '../screens/calculators/roofing/mansard_roof_screen.dart';
import '../screens/calculators/roofing/material_cost_screen.dart';
import '../screens/calculators/roofing/metal_roofing_screen.dart';
import '../screens/calculators/roofing/modified_bitumen_screen.dart';
import '../screens/calculators/roofing/nail_quantity_screen.dart';
import '../screens/calculators/roofing/parapet_cap_screen.dart';
import '../screens/calculators/roofing/pipe_boot_screen.dart';
import '../screens/calculators/roofing/pitch_factor_screen.dart';
import '../screens/calculators/roofing/plywood_deck_screen.dart';
import '../screens/calculators/roofing/power_vent_screen.dart';
import '../screens/calculators/roofing/purlin_spacing_screen.dart';
import '../screens/calculators/roofing/pvc_membrane_screen.dart';
import '../screens/calculators/roofing/r_panel_screen.dart';
import '../screens/calculators/roofing/rafter_length_screen.dart';
import '../screens/calculators/roofing/ridge_cap_screen.dart';
import '../screens/calculators/roofing/ridge_vent_screen.dart';
import '../screens/calculators/roofing/rolled_roofing_screen.dart';
import '../screens/calculators/roofing/roof_area_screen.dart' as roofing_roof_area;
import '../screens/calculators/roofing/roof_coating_screen.dart';
import '../screens/calculators/roofing/roof_cricket_screen.dart';
import '../screens/calculators/roofing/roof_drain_screen.dart';
import '../screens/calculators/roofing/roof_load_screen.dart';
import '../screens/calculators/roofing/roof_penetration_screen.dart';
import '../screens/calculators/roofing/roof_squares_screen.dart';
import '../screens/calculators/roofing/roof_truss_screen.dart';
import '../screens/calculators/roofing/roof_ventilator_screen.dart';
import '../screens/calculators/roofing/scupper_screen.dart';
import '../screens/calculators/roofing/shed_roof_screen.dart';
import '../screens/calculators/roofing/shingle_calculator_screen.dart';
import '../screens/calculators/roofing/skylight_flashing_screen.dart';
import '../screens/calculators/roofing/slate_roofing_screen.dart';
import '../screens/calculators/roofing/slope_conversion_screen.dart';
import '../screens/calculators/roofing/snow_load_screen.dart';
import '../screens/calculators/roofing/soffit_vent_screen.dart';
import '../screens/calculators/roofing/splash_block_screen.dart';
import '../screens/calculators/roofing/standing_seam_screen.dart';
import '../screens/calculators/roofing/starter_strip_screen.dart';
import '../screens/calculators/roofing/step_flashing_screen.dart';
import '../screens/calculators/roofing/synthetic_underlayment_screen.dart';
import '../screens/calculators/roofing/tapered_insulation_screen.dart';
import '../screens/calculators/roofing/tear_off_weight_screen.dart';
import '../screens/calculators/roofing/tile_roofing_screen.dart';
import '../screens/calculators/roofing/total_job_cost_screen.dart';
import '../screens/calculators/roofing/tpo_membrane_screen.dart';
import '../screens/calculators/roofing/turbine_vent_screen.dart';
import '../screens/calculators/roofing/underlayment_screen.dart';
import '../screens/calculators/roofing/valley_length_screen.dart';
import '../screens/calculators/roofing/waste_factor_screen.dart';
import '../screens/calculators/roofing/wind_uplift_screen.dart';
import '../screens/calculators/roofing/wood_shake_screen.dart';

// ============================================================================
// CALCULATORS - GC (101 screens)
// ============================================================================
import '../screens/calculators/gc/anchor_bolt_screen.dart';
import '../screens/calculators/gc/attic_insulation_screen.dart' as gc_attic_insulation;
import '../screens/calculators/gc/batt_insulation_screen.dart';
import '../screens/calculators/gc/beam_span_screen.dart';
import '../screens/calculators/gc/blocking_calculator_screen.dart';
import '../screens/calculators/gc/blown_insulation_screen.dart';
import '../screens/calculators/gc/board_feet_screen.dart';
import '../screens/calculators/gc/caulking_screen.dart';
import '../screens/calculators/gc/ceiling_joist_screen.dart';
import '../screens/calculators/gc/change_order_screen.dart';
import '../screens/calculators/gc/co_detector_screen.dart';
import '../screens/calculators/gc/collar_tie_calculator_screen.dart';
import '../screens/calculators/gc/compaction_factor_screen.dart';
import '../screens/calculators/gc/compaction_screen.dart';
import '../screens/calculators/gc/concrete_mix_screen.dart';
import '../screens/calculators/gc/concrete_volume_screen.dart';
import '../screens/calculators/gc/crew_size_screen.dart';
import '../screens/calculators/gc/cripple_stud_screen.dart';
import '../screens/calculators/gc/critical_path_screen.dart';
import '../screens/calculators/gc/cure_time_screen.dart';
import '../screens/calculators/gc/deck_footing_screen.dart';
import '../screens/calculators/gc/deck_joist_screen.dart';
import '../screens/calculators/gc/deck_post_screen.dart';
import '../screens/calculators/gc/decking_screen.dart';
import '../screens/calculators/gc/demo_waste_screen.dart';
import '../screens/calculators/gc/door_schedule_screen.dart';
import '../screens/calculators/gc/dumpster_sizing_screen.dart';
import '../screens/calculators/gc/egress_path_screen.dart';
import '../screens/calculators/gc/egress_screen.dart';
import '../screens/calculators/gc/excavation_volume_screen.dart';
import '../screens/calculators/gc/exposed_aggregate_screen.dart';
import '../screens/calculators/gc/fascia_screen.dart' as gc_fascia;
import '../screens/calculators/gc/fiber_mesh_screen.dart';
import '../screens/calculators/gc/fill_screen.dart';
import '../screens/calculators/gc/fire_extinguisher_screen.dart';
import '../screens/calculators/gc/flashing_screen.dart' as gc_flashing;
import '../screens/calculators/gc/foam_board_screen.dart';
import '../screens/calculators/gc/footing_calculator_screen.dart';
import '../screens/calculators/gc/form_board_screen.dart';
import '../screens/calculators/gc/foundation_wall_screen.dart';
import '../screens/calculators/gc/french_drain_screen.dart' as gc_french_drain;
import '../screens/calculators/gc/glass_area_screen.dart';
import '../screens/calculators/gc/grading_screen.dart';
import '../screens/calculators/gc/gravel_base_screen.dart';
import '../screens/calculators/gc/guardrail_screen.dart';
import '../screens/calculators/gc/gutter_screen.dart';
import '../screens/calculators/gc/handrail_screen.dart';
import '../screens/calculators/gc/hauling_screen.dart';
import '../screens/calculators/gc/hazmat_screen.dart';
import '../screens/calculators/gc/header_sizing_screen.dart';
import '../screens/calculators/gc/house_wrap_screen.dart';
import '../screens/calculators/gc/i_joist_screen.dart';
import '../screens/calculators/gc/joist_span_screen.dart';
import '../screens/calculators/gc/king_jack_stud_screen.dart';
import '../screens/calculators/gc/labor_hours_screen.dart' as gc_labor_hours;
import '../screens/calculators/gc/landing_screen.dart';
import '../screens/calculators/gc/lot_coverage_screen.dart';
import '../screens/calculators/gc/lumber_quantity_screen.dart';
import '../screens/calculators/gc/lvl_glulam_screen.dart';
import '../screens/calculators/gc/markup_screen.dart';
import '../screens/calculators/gc/permit_cost_screen.dart';
import '../screens/calculators/gc/pier_footing_screen.dart';
import '../screens/calculators/gc/plate_calculator_screen.dart';
import '../screens/calculators/gc/post_sizing_screen.dart';
import '../screens/calculators/gc/profit_margin_screen.dart';
import '../screens/calculators/gc/progress_payment_screen.dart';
import '../screens/calculators/gc/project_duration_screen.dart';
import '../screens/calculators/gc/r_value_screen.dart';
import '../screens/calculators/gc/rafter_calculator_screen.dart';
import '../screens/calculators/gc/rafter_span_screen.dart';
import '../screens/calculators/gc/railing_screen.dart' as gc_railing;
import '../screens/calculators/gc/ramp_screen.dart';
import '../screens/calculators/gc/rebar_calculator_screen.dart';
import '../screens/calculators/gc/retention_screen.dart';
import '../screens/calculators/gc/ridge_board_screen.dart';
import '../screens/calculators/gc/rim_joist_screen.dart';
import '../screens/calculators/gc/roof_sheathing_screen.dart';
import '../screens/calculators/gc/rough_opening_screen.dart';
import '../screens/calculators/gc/slab_calculator_screen.dart';
import '../screens/calculators/gc/slope_screen.dart';
import '../screens/calculators/gc/smoke_detector_screen.dart' as gc_smoke_detector;
import '../screens/calculators/gc/soffit_screen.dart';
import '../screens/calculators/gc/spiral_stair_screen.dart';
import '../screens/calculators/gc/spray_foam_screen.dart';
import '../screens/calculators/gc/sqft_screen.dart';
import '../screens/calculators/gc/stained_concrete_screen.dart';
import '../screens/calculators/gc/stair_calculator_screen.dart';
import '../screens/calculators/gc/stair_stringer_screen.dart';
import '../screens/calculators/gc/stamped_concrete_screen.dart';
import '../screens/calculators/gc/stud_calculator_screen.dart';
import '../screens/calculators/gc/subfloor_screen.dart';
import '../screens/calculators/gc/swell_factor_screen.dart';
import '../screens/calculators/gc/trench_screen.dart';
import '../screens/calculators/gc/trim_lumber_screen.dart';
import '../screens/calculators/gc/truss_count_screen.dart';
import '../screens/calculators/gc/vapor_barrier_screen.dart';
import '../screens/calculators/gc/wall_insulation_screen.dart';
import '../screens/calculators/gc/wall_sheathing_screen.dart';
import '../screens/calculators/gc/waterproofing_screen.dart';
import '../screens/calculators/gc/winder_stair_screen.dart';
import '../screens/calculators/gc/window_schedule_screen.dart';

// ============================================================================
// CALCULATORS - REMODELER (110 screens)
// ============================================================================
import '../screens/calculators/remodeler/accent_wall_screen.dart';
import '../screens/calculators/remodeler/ada_doorway_screen.dart';
import '../screens/calculators/remodeler/adhesive_screen.dart';
import '../screens/calculators/remodeler/appliance_clearance_screen.dart';
import '../screens/calculators/remodeler/arbor_screen.dart';
import '../screens/calculators/remodeler/attic_insulation_screen.dart' as remodeler_attic_insulation;
import '../screens/calculators/remodeler/awning_screen.dart';
import '../screens/calculators/remodeler/backsplash_screen.dart';
import '../screens/calculators/remodeler/baluster_screen.dart';
import '../screens/calculators/remodeler/baseboard_screen.dart';
import '../screens/calculators/remodeler/bathroom_remodel_budget_screen.dart';
import '../screens/calculators/remodeler/bathroom_tile_screen.dart';
import '../screens/calculators/remodeler/bathroom_vent_screen.dart';
import '../screens/calculators/remodeler/bathtub_screen.dart';
import '../screens/calculators/remodeler/blinds_screen.dart';
import '../screens/calculators/remodeler/cabinet_hardware_screen.dart';
import '../screens/calculators/remodeler/caulk_screen.dart';
import '../screens/calculators/remodeler/ceiling_fan_screen.dart' as remodeler_ceiling_fan;
import '../screens/calculators/remodeler/ceiling_paint_screen.dart';
import '../screens/calculators/remodeler/chair_rail_screen.dart';
import '../screens/calculators/remodeler/closet_system_screen.dart';
import '../screens/calculators/remodeler/contingency_screen.dart';
import '../screens/calculators/remodeler/countertop_screen.dart';
import '../screens/calculators/remodeler/crown_molding_screen.dart';
import '../screens/calculators/remodeler/curtain_rod_screen.dart';
import '../screens/calculators/remodeler/deck_stain_screen.dart';
import '../screens/calculators/remodeler/door_casing_screen.dart';
import '../screens/calculators/remodeler/door_hardware_screen.dart';
import '../screens/calculators/remodeler/door_sizing_screen.dart';
import '../screens/calculators/remodeler/doorbell_screen.dart';
import '../screens/calculators/remodeler/downspout_screen.dart' as remodeler_downspout;
import '../screens/calculators/remodeler/drop_cloth_screen.dart';
import '../screens/calculators/remodeler/drywall_patch_screen.dart';
import '../screens/calculators/remodeler/epoxy_flake_screen.dart';
import '../screens/calculators/remodeler/epoxy_flooring_screen.dart';
import '../screens/calculators/remodeler/exterior_lighting_screen.dart';
import '../screens/calculators/remodeler/fascia_screen.dart' as remodeler_fascia;
import '../screens/calculators/remodeler/fence_gate_screen.dart';
import '../screens/calculators/remodeler/fire_pit_screen.dart';
import '../screens/calculators/remodeler/flooring_transition_screen.dart';
import '../screens/calculators/remodeler/french_drain_screen.dart' as remodeler_french_drain;
import '../screens/calculators/remodeler/garage_floor_coating_screen.dart';
import '../screens/calculators/remodeler/gazebo_screen.dart';
import '../screens/calculators/remodeler/gfci_outlet_screen.dart';
import '../screens/calculators/remodeler/grab_bar_screen.dart';
import '../screens/calculators/remodeler/grout_screen.dart';
import '../screens/calculators/remodeler/gutter_sizing_screen.dart';
import '../screens/calculators/remodeler/house_numbers_screen.dart';
import '../screens/calculators/remodeler/kitchen_cabinet_screen.dart';
import '../screens/calculators/remodeler/kitchen_island_screen.dart';
import '../screens/calculators/remodeler/kitchen_remodel_budget_screen.dart';
import '../screens/calculators/remodeler/landscape_edging_screen.dart';
import '../screens/calculators/remodeler/lighting_layout_screen.dart';
import '../screens/calculators/remodeler/lighting_recessed_screen.dart';
import '../screens/calculators/remodeler/mailbox_post_screen.dart';
import '../screens/calculators/remodeler/material_labor_split_screen.dart';
import '../screens/calculators/remodeler/medicine_cabinet_screen.dart';
import '../screens/calculators/remodeler/metallic_epoxy_screen.dart';
import '../screens/calculators/remodeler/mirror_screen.dart';
import '../screens/calculators/remodeler/motion_sensor_screen.dart';
import '../screens/calculators/remodeler/newel_post_screen.dart';
import '../screens/calculators/remodeler/outdoor_kitchen_screen.dart';
import '../screens/calculators/remodeler/outlet_relocation_screen.dart';
import '../screens/calculators/remodeler/paint_coverage_screen.dart';
import '../screens/calculators/remodeler/painter_tape_screen.dart';
import '../screens/calculators/remodeler/patio_paver_screen.dart';
import '../screens/calculators/remodeler/pergola_screen.dart';
import '../screens/calculators/remodeler/picket_fence_screen.dart';
import '../screens/calculators/remodeler/porch_screen_screen.dart';
import '../screens/calculators/remodeler/primer_screen.dart';
import '../screens/calculators/remodeler/privacy_fence_screen.dart';
import '../screens/calculators/remodeler/railing_screen.dart' as remodeler_railing;
import '../screens/calculators/remodeler/raised_bed_screen.dart';
import '../screens/calculators/remodeler/retaining_wall_screen.dart';
import '../screens/calculators/remodeler/ridge_vent_screen.dart' as remodeler_ridge_vent;
import '../screens/calculators/remodeler/sandpaper_screen.dart';
import '../screens/calculators/remodeler/screen_door_screen.dart';
import '../screens/calculators/remodeler/sealer_screen.dart';
import '../screens/calculators/remodeler/shelving_screen.dart';
import '../screens/calculators/remodeler/shower_enclosure_screen.dart';
import '../screens/calculators/remodeler/shutter_screen.dart';
import '../screens/calculators/remodeler/soffit_vent_screen.dart' as remodeler_soffit_vent;
import '../screens/calculators/remodeler/splash_block_screen.dart' as remodeler_splash_block;
import '../screens/calculators/remodeler/stair_carpet_screen.dart';
import '../screens/calculators/remodeler/stair_lift_screen.dart';
import '../screens/calculators/remodeler/stair_tread_screen.dart';
import '../screens/calculators/remodeler/storm_door_screen.dart';
import '../screens/calculators/remodeler/storm_window_screen.dart';
import '../screens/calculators/remodeler/sump_pump_screen.dart' as remodeler_sump_pump;
import '../screens/calculators/remodeler/texture_match_screen.dart';
import '../screens/calculators/remodeler/threshold_ramp_screen.dart';
import '../screens/calculators/remodeler/tile_accent_screen.dart';
import '../screens/calculators/remodeler/toilet_rough_in_screen.dart' as remodeler_toilet_rough_in;
import '../screens/calculators/remodeler/towel_bar_screen.dart';
import '../screens/calculators/remodeler/trellis_screen.dart';
import '../screens/calculators/remodeler/trim_paint_screen.dart';
import '../screens/calculators/remodeler/usb_outlet_screen.dart';
import '../screens/calculators/remodeler/vanity_screen.dart';
import '../screens/calculators/remodeler/wainscoting_screen.dart';
import '../screens/calculators/remodeler/walkin_tub_screen.dart';
import '../screens/calculators/remodeler/walkway_screen.dart';
import '../screens/calculators/remodeler/wallpaper_screen.dart';
import '../screens/calculators/remodeler/weatherstrip_screen.dart';
import '../screens/calculators/remodeler/wheelchair_ramp_screen.dart';
import '../screens/calculators/remodeler/whole_house_estimator_screen.dart';
import '../screens/calculators/remodeler/window_casing_screen.dart';
import '../screens/calculators/remodeler/window_film_screen.dart';
import '../screens/calculators/remodeler/window_replacement_screen.dart';
import '../screens/calculators/remodeler/window_well_screen.dart';
import '../screens/calculators/remodeler/wood_filler_screen.dart';

// ============================================================================
// CALCULATORS - LANDSCAPING (136 screens)
// ============================================================================
import '../screens/calculators/landscaping/annual_bed_screen.dart';
import '../screens/calculators/landscaping/arbor_screen.dart' as landscaping_arbor;
import '../screens/calculators/landscaping/bed_edging_screen.dart';
import '../screens/calculators/landscaping/bed_prep_screen.dart';
import '../screens/calculators/landscaping/berm_screen.dart';
import '../screens/calculators/landscaping/border_stone_screen.dart';
import '../screens/calculators/landscaping/border_wall_screen.dart';
import '../screens/calculators/landscaping/boulder_weight_screen.dart';
import '../screens/calculators/landscaping/brick_edging_screen.dart';
import '../screens/calculators/landscaping/bulk_material_screen.dart';
import '../screens/calculators/landscaping/catch_basin_screen.dart';
import '../screens/calculators/landscaping/channel_drain_screen.dart';
import '../screens/calculators/landscaping/chipper_output_screen.dart';
import '../screens/calculators/landscaping/circle_radius_screen.dart';
import '../screens/calculators/landscaping/cistern_screen.dart';
import '../screens/calculators/landscaping/compost_bin_screen.dart';
import '../screens/calculators/landscaping/compost_screen.dart';
import '../screens/calculators/landscaping/compost_tea_screen.dart';
import '../screens/calculators/landscaping/concrete_curb_screen.dart';
import '../screens/calculators/landscaping/crew_productivity_screen.dart';
import '../screens/calculators/landscaping/deck_board_screen.dart';
import '../screens/calculators/landscaping/decomposed_granite_screen.dart';
import '../screens/calculators/landscaping/dethatching_screen.dart';
import '../screens/calculators/landscaping/downspout_extension_screen.dart';
import '../screens/calculators/landscaping/drainage_pipe_screen.dart';
import '../screens/calculators/landscaping/drip_irrigation_screen.dart' as landscaping_drip;
import '../screens/calculators/landscaping/drip_line_screen.dart';
import '../screens/calculators/landscaping/dry_creek_screen.dart';
import '../screens/calculators/landscaping/dry_well_screen.dart';
import '../screens/calculators/landscaping/edging_screen.dart';
import '../screens/calculators/landscaping/equipment_rental_screen.dart';
import '../screens/calculators/landscaping/erosion_blanket_screen.dart';
import '../screens/calculators/landscaping/fabric_coverage_screen.dart';
import '../screens/calculators/landscaping/fence_material_screen.dart';
import '../screens/calculators/landscaping/fence_post_screen.dart';
import '../screens/calculators/landscaping/fertilizer_screen.dart';
import '../screens/calculators/landscaping/fire_pit_screen.dart' as landscaping_fire_pit;
import '../screens/calculators/landscaping/flagstone_screen.dart';
import '../screens/calculators/landscaping/fountain_pump_screen.dart';
import '../screens/calculators/landscaping/french_drain_screen.dart';
import '../screens/calculators/landscaping/frost_depth_screen.dart';
import '../screens/calculators/landscaping/fuel_usage_screen.dart';
import '../screens/calculators/landscaping/fungicide_screen.dart';
import '../screens/calculators/landscaping/garden_path_screen.dart';
import '../screens/calculators/landscaping/grading_dirt_screen.dart';
import '../screens/calculators/landscaping/gravel_screen.dart';
import '../screens/calculators/landscaping/hedge_spacing_screen.dart';
import '../screens/calculators/landscaping/herbicide_screen.dart';
import '../screens/calculators/landscaping/hydroseeding_screen.dart';
import '../screens/calculators/landscaping/insect_control_screen.dart';
import '../screens/calculators/landscaping/irregular_area_screen.dart';
import '../screens/calculators/landscaping/irrigation_cost_screen.dart';
import '../screens/calculators/landscaping/irrigation_gpm_screen.dart';
import '../screens/calculators/landscaping/irrigation_valve_screen.dart';
import '../screens/calculators/landscaping/job_profit_screen.dart';
import '../screens/calculators/landscaping/labor_hours_screen.dart' as landscaping_labor;
import '../screens/calculators/landscaping/landscape_estimate_screen.dart';
import '../screens/calculators/landscaping/landscape_lighting_screen.dart';
import '../screens/calculators/landscaping/lawn_aeration_screen.dart';
import '../screens/calculators/landscaping/lawn_area_screen.dart';
import '../screens/calculators/landscaping/lawn_renovation_screen.dart';
import '../screens/calculators/landscaping/lawn_striping_screen.dart';
import '../screens/calculators/landscaping/leaf_removal_screen.dart';
import '../screens/calculators/landscaping/lighting_voltage_screen.dart';
import '../screens/calculators/landscaping/lime_screen.dart';
import '../screens/calculators/landscaping/load_weight_screen.dart';
import '../screens/calculators/landscaping/mow_time_screen.dart';
import '../screens/calculators/landscaping/mowing_time_screen.dart';
import '../screens/calculators/landscaping/mulch_ring_screen.dart';
import '../screens/calculators/landscaping/mulch_screen.dart';
import '../screens/calculators/landscaping/native_plants_screen.dart';
import '../screens/calculators/landscaping/outdoor_kitchen_screen.dart' as landscaping_outdoor_kitchen;
import '../screens/calculators/landscaping/patio_layout_screen.dart';
import '../screens/calculators/landscaping/paver_base_screen.dart';
import '../screens/calculators/landscaping/paver_joint_screen.dart';
import '../screens/calculators/landscaping/paver_screen.dart';
import '../screens/calculators/landscaping/pergola_screen.dart' as landscaping_pergola;
import '../screens/calculators/landscaping/perimeter_screen.dart';
import '../screens/calculators/landscaping/ph_amendment_screen.dart';
import '../screens/calculators/landscaping/pillar_column_screen.dart';
import '../screens/calculators/landscaping/plant_count_screen.dart';
import '../screens/calculators/landscaping/plant_spacing_screen.dart';
import '../screens/calculators/landscaping/planter_box_screen.dart';
import '../screens/calculators/landscaping/polymeric_sand_screen.dart';
import '../screens/calculators/landscaping/pond_liner_screen.dart';
import '../screens/calculators/landscaping/pond_pump_screen.dart';
import '../screens/calculators/landscaping/pop_up_drain_screen.dart';
import '../screens/calculators/landscaping/pricing_screen.dart';
import '../screens/calculators/landscaping/rain_barrel_screen.dart';
import '../screens/calculators/landscaping/rain_garden_screen.dart';
import '../screens/calculators/landscaping/raised_bed_screen.dart' as landscaping_raised_bed;
import '../screens/calculators/landscaping/retaining_wall_screen.dart' as landscaping_retaining_wall;
import '../screens/calculators/landscaping/rip_rap_screen.dart';
import '../screens/calculators/landscaping/river_rock_screen.dart';
import '../screens/calculators/landscaping/root_barrier_screen.dart';
import '../screens/calculators/landscaping/route_optimization_screen.dart';
import '../screens/calculators/landscaping/scale_drawing_screen.dart';
import '../screens/calculators/landscaping/seasonal_cleanup_screen.dart';
import '../screens/calculators/landscaping/seat_wall_screen.dart';
import '../screens/calculators/landscaping/seed_rate_screen.dart';
import '../screens/calculators/landscaping/seed_screen.dart';
import '../screens/calculators/landscaping/service_area_screen.dart';
import '../screens/calculators/landscaping/shrub_spacing_screen.dart';
import '../screens/calculators/landscaping/slope_calculator_screen.dart';
import '../screens/calculators/landscaping/slope_grade_screen.dart';
import '../screens/calculators/landscaping/snow_removal_screen.dart';
import '../screens/calculators/landscaping/sod_screen.dart';
import '../screens/calculators/landscaping/soil_test_screen.dart';
import '../screens/calculators/landscaping/sprinkler_head_screen.dart';
import '../screens/calculators/landscaping/sprinkler_runtime_screen.dart';
import '../screens/calculators/landscaping/sprinkler_zone_screen.dart';
import '../screens/calculators/landscaping/stair_step_screen.dart';
import '../screens/calculators/landscaping/stairs_outdoor_screen.dart';
import '../screens/calculators/landscaping/stepping_stone_screen.dart';
import '../screens/calculators/landscaping/sump_pump_screen.dart' as landscaping_sump;
import '../screens/calculators/landscaping/swale_screen.dart';
import '../screens/calculators/landscaping/topsoil_screen.dart';
import '../screens/calculators/landscaping/trailer_capacity_screen.dart';
import '../screens/calculators/landscaping/transformer_sizing_screen.dart' as landscaping_transformer;
import '../screens/calculators/landscaping/tree_diameter_screen.dart';
import '../screens/calculators/landscaping/tree_fertilizer_screen.dart';
import '../screens/calculators/landscaping/tree_planting_screen.dart';
import '../screens/calculators/landscaping/tree_removal_screen.dart';
import '../screens/calculators/landscaping/tree_ring_screen.dart';
import '../screens/calculators/landscaping/tree_staking_screen.dart';
import '../screens/calculators/landscaping/trellis_screen.dart' as landscaping_trellis;
import '../screens/calculators/landscaping/triangle_area_screen.dart';
import '../screens/calculators/landscaping/turf_conversion_screen.dart';
import '../screens/calculators/landscaping/turf_paint_screen.dart';
import '../screens/calculators/landscaping/wall_cap_screen.dart';
import '../screens/calculators/landscaping/water_usage_screen.dart';
import '../screens/calculators/landscaping/weed_barrier_screen.dart';
import '../screens/calculators/landscaping/weed_control_screen.dart';
import '../screens/calculators/landscaping/wheelbarrow_trips_screen.dart';
import '../screens/calculators/landscaping/xeriscape_screen.dart';
import '../screens/calculators/landscaping/yard_waste_screen.dart';

// ============================================================================
// WIRING DIAGRAMS (23 screens)
// ============================================================================
import '../screens/diagrams/ceiling_fan_screen.dart';
import '../screens/diagrams/dimmer_switch_screen.dart';
import '../screens/diagrams/four_way_switch_screen.dart';
import '../screens/diagrams/garage_subpanel_screen.dart';
import '../screens/diagrams/gfci_wiring_screen.dart';
import '../screens/diagrams/grounding_electrode_screen.dart';
import '../screens/diagrams/low_voltage_screen.dart';
import '../screens/diagrams/motor_starter_screen.dart' as diag_motor;
import '../screens/diagrams/outlet_240v_screen.dart';
import '../screens/diagrams/photocell_timer_screen.dart';
import '../screens/diagrams/pool_spa_wiring_screen.dart';
import '../screens/diagrams/recessed_lighting_screen.dart';
import '../screens/diagrams/service_entrance_screen.dart' as diag_service;
import '../screens/diagrams/single_pole_switch_screen.dart';
import '../screens/diagrams/smoke_detector_screen.dart';
import '../screens/diagrams/split_receptacle_screen.dart';
import '../screens/diagrams/sub_panel_screen.dart';
import '../screens/diagrams/thermostat_wiring_screen.dart';
import '../screens/diagrams/three_phase_basics_screen.dart';
import '../screens/diagrams/three_way_switch_screen.dart';
import '../screens/diagrams/transfer_switch_screen.dart';
import '../screens/diagrams/under_cabinet_screen.dart';
import '../screens/diagrams/vfd_wiring_screen.dart';

// ============================================================================
// REFERENCE (21 screens)
// ============================================================================
import '../screens/reference/aluminum_wiring_screen.dart';
import '../screens/reference/ampacity_table_screen.dart';
import '../screens/reference/apprentice_guide_screen.dart';
import '../screens/reference/common_mistakes_screen.dart';
import '../screens/reference/conduit_dimensions_screen.dart';
import '../screens/reference/formulas_screen.dart';
import '../screens/reference/gfci_afci_screen.dart';
import '../screens/reference/grounding_vs_bonding_screen.dart';
import '../screens/reference/hazardous_locations_screen.dart';
import '../screens/reference/knob_tube_screen.dart';
import '../screens/reference/motor_nameplate_screen.dart';
import '../screens/reference/nec_changes_screen.dart';
import '../screens/reference/nec_navigation_screen.dart';
import '../screens/reference/outlet_config_screen.dart';
import '../screens/reference/permit_checklist_screen.dart';
import '../screens/reference/rough_in_checklist_screen.dart';
import '../screens/reference/state_adoption_screen.dart';
import '../screens/reference/tool_list_screen.dart';
import '../screens/reference/troubleshooting_screen.dart';
import '../screens/reference/wire_color_code_screen.dart';
import '../screens/reference/wire_properties_screen.dart';

// ============================================================================
// TABLES (9 screens)
// ============================================================================
import '../screens/tables/awg_reference_screen.dart';
import '../screens/tables/box_fill_table_screen.dart';
import '../screens/tables/breaker_sizing_table_screen.dart';
import '../screens/tables/conduit_bend_multipliers_screen.dart';
import '../screens/tables/derating_table_screen.dart';
import '../screens/tables/grounding_table_screen.dart';
import '../screens/tables/motor_fla_table_screen.dart';
import '../screens/tables/raceway_fill_table_screen.dart';
import '../screens/tables/transformer_fla_table_screen.dart';

// ============================================================================
// OTHER (5 screens)
// ============================================================================
import '../screens/nema/nema_config_screen.dart';
import '../screens/safety/electrical_safety_screen.dart';
import '../screens/symbols/blueprint_symbols_screen.dart';
import '../screens/exam_prep/exam_prep_hub_screen.dart';
import '../screens/ai_scanner/ai_scanner_screen.dart';

/// Screen Registry - Central navigation hub for all screens
enum ScreenCategory {
  calculators,
  diagrams,
  reference,
  tables,
  other,
}

class ScreenEntry {
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final ScreenCategory category;
  final List<String> searchTags;
  final Widget Function() builder;
  final String? trade; // 'electrical', 'plumbing', 'hvac', etc.

  const ScreenEntry({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.searchTags,
    required this.builder,
    this.trade,
  });
}

class ScreenRegistry {
  ScreenRegistry._();

  // =========================================================================
  // ELECTRICAL CALCULATORS (43)
  // =========================================================================
  static final List<ScreenEntry> electricalCalculators = [
    ScreenEntry(
      id: 'ohms_law',
      name: "Ohm's Law",
      subtitle: 'V, I, R, P calculations',
      icon: Icons.functions,
      category: ScreenCategory.calculators,
      searchTags: ['ohm', 'voltage', 'current', 'resistance', 'power', 'watt'],
      builder: () => const OhmsLawScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'voltage_drop',
      name: 'Voltage Drop',
      subtitle: 'NEC 210.19 / 215.2 (3%/5%)',
      icon: Icons.trending_down,
      category: ScreenCategory.calculators,
      searchTags: ['voltage', 'drop', 'vd', 'wire', 'length'],
      builder: () => const VoltageDropScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'wire_sizing',
      name: 'Wire Sizing',
      subtitle: 'Size by ampacity & application',
      icon: Icons.straighten,
      category: ScreenCategory.calculators,
      searchTags: ['wire', 'size', 'gauge', 'awg', 'conductor'],
      builder: () => const WireSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'ampacity',
      name: 'Ampacity Derating',
      subtitle: 'Temperature & conduit fill factors',
      icon: Icons.thermostat_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['ampacity', 'derating', 'temperature', 'conduit'],
      builder: () => const AmpacityScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conduit_fill',
      name: 'Conduit Fill',
      subtitle: 'NEC Chapter 9 fill calculations',
      icon: Icons.pie_chart_outline,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'fill', 'percentage', 'emt', 'pvc'],
      builder: () => const ConduitFillScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'box_fill',
      name: 'Box Fill',
      subtitle: 'NEC 314.16 box volume',
      icon: Icons.check_box_outline_blank,
      category: ScreenCategory.calculators,
      searchTags: ['box', 'fill', 'junction', 'volume', '314.16'],
      builder: () => const BoxFillScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conduit_bending',
      name: 'Conduit Bending',
      subtitle: 'Offset, kick, saddle, 90°',
      icon: Icons.turn_right,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'bend', 'offset', 'kick', 'saddle'],
      builder: () => const ConduitBendingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'dwelling_load',
      name: 'Dwelling Load',
      subtitle: 'NEC 220 residential service sizing',
      icon: Icons.home_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['dwelling', 'residential', 'load', 'service', '220'],
      builder: () => const DwellingLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'commercial_load',
      name: 'Commercial Load',
      subtitle: 'NEC 220 commercial/industrial',
      icon: Icons.business_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['commercial', 'industrial', 'load', 'service'],
      builder: () => const CommercialLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_fla',
      name: 'Motor FLA',
      subtitle: 'NEC Tables 430.248/250',
      icon: Icons.speed,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'fla', 'full load', 'amp', '430'],
      builder: () => const MotorFlaScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_circuit',
      name: 'Motor Circuit',
      subtitle: 'Complete motor branch circuit',
      icon: Icons.engineering_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'circuit', 'branch', 'overload'],
      builder: () => const MotorCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_inrush',
      name: 'Motor Inrush',
      subtitle: 'NEC 430.251 locked rotor current',
      icon: Icons.bolt_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'inrush', 'locked rotor', 'lra'],
      builder: () => const MotorInrushScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'transformer',
      name: 'Transformer Sizing',
      subtitle: 'kVA and current calculations',
      icon: Icons.transform,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'kva', 'sizing', 'primary', 'secondary'],
      builder: () => const TransformerScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'grounding',
      name: 'Grounding & Bonding',
      subtitle: 'EGC, GEC, bonding jumpers',
      icon: Icons.electric_bolt_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['grounding', 'bonding', 'egc', 'gec', '250'],
      builder: () => const GroundingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'power_converter',
      name: 'Power Converter',
      subtitle: 'kW, kVA, amps, HP conversions',
      icon: Icons.swap_horiz,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'convert', 'kw', 'kva', 'hp'],
      builder: () => const PowerConverterScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'power_factor',
      name: 'Power Factor',
      subtitle: 'Capacitor kVAR correction',
      icon: Icons.show_chart,
      category: ScreenCategory.calculators,
      searchTags: ['power factor', 'pf', 'kvar', 'capacitor'],
      builder: () => const PowerFactorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'pull_box',
      name: 'Pull Box Sizing',
      subtitle: 'NEC 314.28 dimensions',
      icon: Icons.aspect_ratio,
      category: ScreenCategory.calculators,
      searchTags: ['pull box', 'junction', 'sizing', '314.28'],
      builder: () => const PullBoxScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'cable_tray',
      name: 'Cable Tray Fill',
      subtitle: 'NEC 392 tray fill limits',
      icon: Icons.view_week_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['cable tray', 'fill', '392', 'ladder'],
      builder: () => const CableTrayScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'raceway',
      name: 'Raceway Sizing',
      subtitle: 'Size conduit by wire count',
      icon: Icons.linear_scale,
      category: ScreenCategory.calculators,
      searchTags: ['raceway', 'conduit', 'size', 'wire count'],
      builder: () => const RacewayScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'fault_current',
      name: 'Fault Current',
      subtitle: 'Short circuit point-to-point',
      icon: Icons.flash_on_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['fault', 'current', 'short circuit', 'aic'],
      builder: () => const FaultCurrentScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'tap_rule',
      name: 'Tap Rules',
      subtitle: 'NEC 240.21 tap conductor sizing',
      icon: Icons.account_tree_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['tap', 'rule', '10 foot', '25 foot', '240.21'],
      builder: () => const TapRuleScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'service_entrance',
      name: 'Service Entrance',
      subtitle: 'Service entrance sizing',
      icon: Icons.electrical_services,
      category: ScreenCategory.calculators,
      searchTags: ['service', 'entrance', 'main', 'panel'],
      builder: () => const calc_service.ServiceEntranceScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'generator_sizing',
      name: 'Generator Sizing',
      subtitle: 'Standby & portable generator loads',
      icon: Icons.power_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['generator', 'sizing', 'standby', 'portable'],
      builder: () => const GeneratorSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'ev_charger',
      name: 'EV Charger Load',
      subtitle: 'NEC 625 charging station sizing',
      icon: Icons.ev_station_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['ev', 'charger', 'electric vehicle', '625'],
      builder: () => const EvChargerScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'solar_pv',
      name: 'Solar / PV System',
      subtitle: 'NEC 690 array & inverter sizing',
      icon: Icons.solar_power_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['solar', 'pv', 'photovoltaic', '690'],
      builder: () => const SolarPvScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'electric_range',
      name: 'Electric Range',
      subtitle: 'NEC 220.55 demand factors',
      icon: Icons.countertops_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['range', 'stove', 'oven', '220.55'],
      builder: () => const ElectricRangeScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'dryer_circuit',
      name: 'Dryer Circuit',
      subtitle: 'NEC 220.54 branch circuit',
      icon: Icons.local_laundry_service_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['dryer', 'circuit', 'laundry', '220.54'],
      builder: () => const DryerCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'water_heater_electrical',
      name: 'Water Heater',
      subtitle: 'NEC 422 tank & tankless',
      icon: Icons.water_drop_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['water heater', 'tankless', '422'],
      builder: () => const WaterHeaterScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'lighting_sqft',
      name: 'Lighting by Sq Ft',
      subtitle: 'NEC 220.12 VA per occupancy',
      icon: Icons.square_foot_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['lighting', 'square foot', 'va', '220.12'],
      builder: () => const LightingSqftScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'lumen',
      name: 'Lighting / Lumen',
      subtitle: 'Fixture count by foot-candles',
      icon: Icons.lightbulb_outline,
      category: ScreenCategory.calculators,
      searchTags: ['lumen', 'lux', 'foot candle', 'fixture'],
      builder: () => const LumenScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'continuous_load',
      name: 'Continuous Load',
      subtitle: 'NEC 210.20 125% sizing',
      icon: Icons.timer_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['continuous', 'load', '125%', '210.20'],
      builder: () => const ContinuousLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'parallel_conductor',
      name: 'Parallel Conductors',
      subtitle: 'NEC 310.10(G) parallel sets',
      icon: Icons.stacked_line_chart,
      category: ScreenCategory.calculators,
      searchTags: ['parallel', 'conductor', 'wire', '310.10'],
      builder: () => const ParallelConductorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'mwbc',
      name: 'Multi-Wire Branch',
      subtitle: 'NEC 210.4 shared neutral sizing',
      icon: Icons.share_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['mwbc', 'multi-wire', 'shared neutral', '210.4'],
      builder: () => const MwbcScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'disconnect',
      name: 'Disconnect Sizing',
      subtitle: 'NEC 430.109/110 requirements',
      icon: Icons.power_off_outlined,
      category: ScreenCategory.calculators,
      searchTags: ['disconnect', 'switch', '430.109'],
      builder: () => const DisconnectScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'unit_converter',
      name: 'Unit Converter',
      subtitle: 'Length, area, temp, wire gauge',
      icon: Icons.sync_alt,
      category: ScreenCategory.calculators,
      searchTags: ['unit', 'convert', 'length', 'area', 'temperature'],
      builder: () => const UnitConverterScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'wire_pull_tension',
      name: 'Wire Pull Tension',
      subtitle: 'Max pulling force per ICEA',
      icon: LucideIcons.move,
      category: ScreenCategory.calculators,
      searchTags: ['wire', 'pull', 'tension', 'pulling', 'force', 'icea'],
      builder: () => const WirePullTensionScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conductor_weight',
      name: 'Conductor Weight',
      subtitle: 'Wire weight for pulls & supports',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['conductor', 'weight', 'wire', 'cable', 'lbs'],
      builder: () => const ConductorWeightScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conduit_bend_radius',
      name: 'Conduit Bend Radius',
      subtitle: 'NEC Chapter 9 Table 2',
      icon: LucideIcons.cornerUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'bend', 'radius', 'minimum', 'emt', 'pvc'],
      builder: () => const ConduitBendRadiusScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conduit_support_spacing',
      name: 'Conduit Support Spacing',
      subtitle: 'NEC support requirements',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'support', 'spacing', 'strap', 'hanger'],
      builder: () => const ConduitSupportSpacingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'expansion_fitting',
      name: 'Expansion Fitting',
      subtitle: 'PVC thermal expansion NEC 352.44',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['expansion', 'fitting', 'pvc', 'thermal', '352.44'],
      builder: () => const ExpansionFittingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'working_space',
      name: 'Working Space',
      subtitle: 'NEC 110.26 clearances',
      icon: LucideIcons.maximize,
      category: ScreenCategory.calculators,
      searchTags: ['working', 'space', 'clearance', '110.26', 'panel'],
      builder: () => const WorkingSpaceScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'junction_box_sizing',
      name: 'Junction Box Sizing',
      subtitle: 'NEC 314.28 pull boxes',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['junction', 'box', 'pull', 'sizing', '314.28'],
      builder: () => const JunctionBoxSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'derating_advanced',
      name: 'Advanced Derating',
      subtitle: 'Combined NEC 310.15 factors',
      icon: LucideIcons.thermometerSun,
      category: ScreenCategory.calculators,
      searchTags: ['derating', 'ampacity', 'temperature', 'conduit', 'fill', 'rooftop'],
      builder: () => const DeratingAdvancedScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_starter',
      name: 'Motor Starter Sizing',
      subtitle: 'NEMA starter selection per NEC 430',
      icon: LucideIcons.cog,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'starter', 'NEMA', 'contactor', 'overload', '430'],
      builder: () => const MotorStarterScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'vfd_sizing',
      name: 'VFD Sizing',
      subtitle: 'Variable frequency drive selection',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['VFD', 'variable', 'frequency', 'drive', 'inverter', 'motor', 'speed'],
      builder: () => const VfdSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'transformer_protection',
      name: 'Transformer Protection',
      subtitle: 'NEC 450.3 OCPD sizing',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'protection', 'OCPD', 'fuse', 'breaker', '450.3'],
      builder: () => const TransformerProtectionScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'ground_rod',
      name: 'Ground Rod Calculator',
      subtitle: 'NEC 250 grounding electrodes',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['ground', 'rod', 'electrode', 'grounding', 'earth', '250', 'resistance'],
      builder: () => const GroundRodScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'bonding_jumper',
      name: 'Bonding Jumper Sizing',
      subtitle: 'NEC 250.102 & 250.122 EBJ/SSBJ',
      icon: LucideIcons.link2,
      category: ScreenCategory.calculators,
      searchTags: ['bonding', 'jumper', 'EBJ', 'SSBJ', 'grounding', '250.102', '250.122'],
      builder: () => const BondingJumperScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'arc_flash',
      name: 'Arc Flash Boundary',
      subtitle: 'IEEE 1584 / NFPA 70E PPE',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['arc', 'flash', 'PPE', 'boundary', 'incident', 'energy', 'NFPA', '70E', 'IEEE', '1584'],
      builder: () => const ArcFlashScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'hvac_circuit',
      name: 'HVAC Circuit',
      subtitle: 'A/C and heat pump per NEC 440',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['HVAC', 'air', 'conditioner', 'heat', 'pump', 'MCA', 'MOPD', '440'],
      builder: () => const HvacCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'pool_spa',
      name: 'Pool/Spa Wiring',
      subtitle: 'NEC 680 requirements',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'spa', 'hot', 'tub', 'bonding', 'GFCI', '680', 'underwater'],
      builder: () => const PoolSpaScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'kitchen_circuit',
      name: 'Kitchen Circuit Planner',
      subtitle: 'Required circuits per NEC 210',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'circuit', 'appliance', 'GFCI', 'small', 'range', '210.52'],
      builder: () => const KitchenCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'bathroom_circuit',
      name: 'Bathroom Circuit Planner',
      subtitle: 'GFCI requirements per NEC 210',
      icon: LucideIcons.bath,
      category: ScreenCategory.calculators,
      searchTags: ['bathroom', 'circuit', 'GFCI', '210.11', 'exhaust', 'heater'],
      builder: () => const BathroomCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'recessed_light',
      name: 'Recessed Light Layout',
      subtitle: 'Spacing and lumen calculations',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['recessed', 'light', 'can', 'downlight', 'spacing', 'lumens', 'layout'],
      builder: () => const RecessedLightScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'ups_sizing',
      name: 'UPS Sizing',
      subtitle: 'Backup power VA calculator',
      icon: LucideIcons.batteryCharging,
      category: ScreenCategory.calculators,
      searchTags: ['UPS', 'backup', 'power', 'VA', 'battery', 'uninterruptible', 'surge'],
      builder: () => const UpsSizingScreen(),
      trade: 'electrical',
    ),
    // =========================================================================
    // ADDITIONAL ELECTRICAL - Session overflow (40+)
    // =========================================================================
    ScreenEntry(
      id: 'audio_video_wire',
      name: 'Audio/Video Wire',
      subtitle: 'A/V cable sizing',
      icon: LucideIcons.speaker,
      category: ScreenCategory.calculators,
      searchTags: ['audio', 'video', 'wire', 'cable', 'hdmi', 'speaker'],
      builder: () => const AudioVideoWireScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'available_fault_current',
      name: 'Available Fault Current',
      subtitle: 'AFC calculation',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['fault', 'current', 'afc', 'aic', 'short', 'circuit'],
      builder: () => const AvailableFaultCurrentScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'battery_bank',
      name: 'Battery Bank',
      subtitle: 'Battery bank sizing',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'bank', 'sizing', 'ah', 'solar', 'backup'],
      builder: () => const BatteryBankScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'battery_circuit_protection',
      name: 'Battery Circuit Protection',
      subtitle: 'BESS overcurrent protection',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'circuit', 'protection', 'bess', 'fuse'],
      builder: () => const BatteryCircuitProtectionScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'buck_boost',
      name: 'Buck-Boost',
      subtitle: 'Voltage correction transformer',
      icon: LucideIcons.arrowUpDown,
      category: ScreenCategory.calculators,
      searchTags: ['buck', 'boost', 'transformer', 'voltage', 'correction'],
      builder: () => const BuckBoostScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'capacitor_bank',
      name: 'Capacitor Bank',
      subtitle: 'Power factor correction',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['capacitor', 'bank', 'power', 'factor', 'kvar'],
      builder: () => const CapacitorBankScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'capacitor_sizing',
      name: 'Capacitor Sizing',
      subtitle: 'Motor capacitor sizing',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['capacitor', 'sizing', 'motor', 'start', 'run', 'mfd'],
      builder: () => const CapacitorSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'conduit_length_estimator',
      name: 'Conduit Length Estimator',
      subtitle: 'Conduit run estimation',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'length', 'estimator', 'run', 'feet'],
      builder: () => const ConduitLengthEstimatorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'dedicated_space',
      name: 'Dedicated Space',
      subtitle: 'NEC 110.26 requirements',
      icon: LucideIcons.move,
      category: ScreenCategory.calculators,
      searchTags: ['dedicated', 'space', 'working', 'clearance', '110.26'],
      builder: () => const DedicatedSpaceScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'demand_factor',
      name: 'Demand Factor',
      subtitle: 'Load demand calculation',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['demand', 'factor', 'load', 'calculation', 'nec'],
      builder: () => const DemandFactorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'doorbell_transformer',
      name: 'Doorbell Transformer',
      subtitle: 'Low voltage transformer',
      icon: LucideIcons.bell,
      category: ScreenCategory.calculators,
      searchTags: ['doorbell', 'transformer', 'low', 'voltage', 'va'],
      builder: () => const DoorbellTransformerScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'emergency_lighting',
      name: 'Emergency Lighting',
      subtitle: 'Egress lighting calc',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['emergency', 'lighting', 'egress', 'exit', 'battery'],
      builder: () => const EmergencyLightingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'emergency_standby_load',
      name: 'Emergency/Standby Load',
      subtitle: 'NEC 700/701/702 loads',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['emergency', 'standby', 'load', 'generator', 'transfer'],
      builder: () => const EmergencyStandbyLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'enclosure_sizing',
      name: 'Enclosure Sizing',
      subtitle: 'NEMA enclosure selection',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['enclosure', 'sizing', 'nema', 'junction', 'box'],
      builder: () => const EnclosureSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'exit_sign_placement',
      name: 'Exit Sign Placement',
      subtitle: 'Exit sign spacing',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['exit', 'sign', 'placement', 'spacing', 'egress'],
      builder: () => const ExitSignPlacementScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'feeder_calculator',
      name: 'Feeder Calculator',
      subtitle: 'Feeder sizing & protection',
      icon: LucideIcons.network,
      category: ScreenCategory.calculators,
      searchTags: ['feeder', 'calculator', 'sizing', 'ampacity', 'protection'],
      builder: () => const FeederCalculatorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'fire_alarm_circuit',
      name: 'Fire Alarm Circuit',
      subtitle: 'FACP circuit sizing',
      icon: LucideIcons.bellRing,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'alarm', 'circuit', 'facp', 'nac', 'slc'],
      builder: () => const FireAlarmCircuitScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'fleet_charging',
      name: 'Fleet Charging',
      subtitle: 'Multi-vehicle EV charging',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['fleet', 'charging', 'ev', 'electric', 'vehicle', 'load'],
      builder: () => const FleetChargingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'ground_ring',
      name: 'Ground Ring',
      subtitle: 'Grounding electrode conductor',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['ground', 'ring', 'electrode', 'conductor', 'gec'],
      builder: () => const GroundRingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'harmonics',
      name: 'Harmonics',
      subtitle: 'Harmonic distortion analysis',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['harmonics', 'thd', 'distortion', 'neutral', 'triplen'],
      builder: () => const HarmonicsScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'intersystem_bonding',
      name: 'Intersystem Bonding',
      subtitle: 'IBT termination',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['intersystem', 'bonding', 'ibt', 'termination', 'telecom'],
      builder: () => const IntersystemBondingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'inverter_charger',
      name: 'Inverter Charger',
      subtitle: 'Battery inverter sizing',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['inverter', 'charger', 'battery', 'sizing', 'watts'],
      builder: () => const InverterChargerScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'lighting_control',
      name: 'Lighting Control',
      subtitle: 'Dimmer & switch loads',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['lighting', 'control', 'dimmer', 'switch', 'load'],
      builder: () => const LightingControlScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_disconnect',
      name: 'Motor Disconnect',
      subtitle: 'Disconnect sizing',
      icon: LucideIcons.powerOff,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'disconnect', 'sizing', 'hp', 'amps'],
      builder: () => const MotorDisconnectScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'motor_feeder',
      name: 'Motor Feeder',
      subtitle: 'Motor feeder sizing',
      icon: LucideIcons.network,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'feeder', 'sizing', 'conductor', 'protection'],
      builder: () => const MotorFeederScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'multi_charger_load',
      name: 'Multi-Charger Load',
      subtitle: 'Multiple EV charger calc',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['multi', 'charger', 'ev', 'load', 'demand'],
      builder: () => const MultiChargerLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'multifamily',
      name: 'Multifamily Load',
      subtitle: 'Apartment building load',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['multifamily', 'apartment', 'load', 'dwelling', 'unit'],
      builder: () => const MultifamilyScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'network_cable',
      name: 'Network Cable',
      subtitle: 'Cat5e/6/6a selection',
      icon: LucideIcons.network,
      category: ScreenCategory.calculators,
      searchTags: ['network', 'cable', 'cat5', 'cat6', 'ethernet', 'data'],
      builder: () => const NetworkCableScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'optional_calculation',
      name: 'Optional Calculation',
      subtitle: 'NEC 220.82/83',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['optional', 'calculation', '220.82', '220.83', 'dwelling'],
      builder: () => const OptionalCalculationScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'parking_lot_lighting',
      name: 'Parking Lot Lighting',
      subtitle: 'Pole light layout',
      icon: LucideIcons.parkingCircle,
      category: ScreenCategory.calculators,
      searchTags: ['parking', 'lot', 'lighting', 'pole', 'footcandle'],
      builder: () => const ParkingLotLightingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'restaurant_load',
      name: 'Restaurant Load',
      subtitle: 'Commercial kitchen load',
      icon: LucideIcons.utensils,
      category: ScreenCategory.calculators,
      searchTags: ['restaurant', 'load', 'kitchen', 'commercial', 'demand'],
      builder: () => const RestaurantLoadScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'security_system_wire',
      name: 'Security System Wire',
      subtitle: 'Alarm wire sizing',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['security', 'system', 'wire', 'alarm', 'sensor'],
      builder: () => const SecuritySystemWireScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'selective_coordination',
      name: 'Selective Coordination',
      subtitle: 'Breaker coordination',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['selective', 'coordination', 'breaker', 'fuse', 'trip'],
      builder: () => const SelectiveCoordinationScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'series_rating',
      name: 'Series Rating',
      subtitle: 'Series rated systems',
      icon: LucideIcons.link2,
      category: ScreenCategory.calculators,
      searchTags: ['series', 'rating', 'aic', 'breaker', 'coordination'],
      builder: () => const SeriesRatingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'soft_start',
      name: 'Soft Start',
      subtitle: 'Soft starter sizing',
      icon: LucideIcons.play,
      category: ScreenCategory.calculators,
      searchTags: ['soft', 'start', 'starter', 'motor', 'inrush'],
      builder: () => const SoftStartScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'standalone_ess',
      name: 'Standalone ESS',
      subtitle: 'Energy storage system',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['standalone', 'ess', 'energy', 'storage', 'battery'],
      builder: () => const StandaloneEssScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'surge_protector',
      name: 'Surge Protector',
      subtitle: 'SPD selection',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['surge', 'protector', 'spd', 'tvss', 'protection'],
      builder: () => const SurgeProtectorScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'thermostat_wire',
      name: 'Thermostat Wire',
      subtitle: 'HVAC control wire',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['thermostat', 'wire', 'hvac', 'control', '18awg'],
      builder: () => const ThermostatWireScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'transformer_impedance',
      name: 'Transformer Impedance',
      subtitle: 'Impedance & fault current',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'impedance', 'fault', 'current', 'z'],
      builder: () => const TransformerImpedanceScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'transformer_sizing',
      name: 'Transformer Sizing',
      subtitle: 'kVA sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'sizing', 'kva', 'load', 'primary'],
      builder: () => const TransformerSizingScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'transformer_taps',
      name: 'Transformer Taps',
      subtitle: 'Tap adjustment',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'taps', 'voltage', 'adjustment', 'fcbn'],
      builder: () => const TransformerTapsScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'voltage_imbalance',
      name: 'Voltage Imbalance',
      subtitle: 'Three-phase balance',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['voltage', 'imbalance', 'three', 'phase', 'unbalance'],
      builder: () => const VoltageImbalanceScreen(),
      trade: 'electrical',
    ),
    ScreenEntry(
      id: 'wireway_fill',
      name: 'Wireway Fill',
      subtitle: 'Wireway conductor fill',
      icon: LucideIcons.layoutList,
      category: ScreenCategory.calculators,
      searchTags: ['wireway', 'fill', 'trough', 'conductor', 'area'],
      builder: () => const WirewayFillScreen(),
      trade: 'electrical',
    ),
  ];

  // =========================================================================
  // PLUMBING CALCULATORS (107)
  // =========================================================================
  static final List<ScreenEntry> plumbingCalculators = [
    ScreenEntry(
      id: 'dfu_calculator',
      name: 'DFU Calculator',
      subtitle: 'Drainage fixture units (IPC 2024)',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['dfu', 'drainage', 'fixture', 'unit', 'plumbing', 'pipe', 'drain', 'waste', 'vent', 'ipc'],
      builder: () => const DfuCalculatorScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'wsfu_calculator',
      name: 'WSFU Calculator',
      subtitle: 'Water supply fixture units',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['wsfu', 'water', 'supply', 'fixture', 'unit', 'plumbing'],
      builder: () => const WsfuCalculatorScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'gas_pipe_sizing_plumbing',
      name: 'Gas Pipe Sizing',
      subtitle: 'IFGC gas pipe sizing',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'pipe', 'sizing', 'btu', 'cfh', 'ifgc'],
      builder: () => const plumbing_gas.GasPipeSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_heater_sizing',
      name: 'Water Heater Sizing',
      subtitle: 'Tank size by fixtures & demand',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'heater', 'sizing', 'tank', 'gallon'],
      builder: () => const WaterHeaterSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'drain_slope',
      name: 'Drain Slope',
      subtitle: 'Calculate drain pipe slope',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['drain', 'slope', 'grade', 'fall', 'pitch'],
      builder: () => const DrainSlopeScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'sump_pump',
      name: 'Sump Pump Sizing',
      subtitle: 'Size sump pump by GPM & head',
      icon: LucideIcons.arrowUpFromLine,
      category: ScreenCategory.calculators,
      searchTags: ['sump', 'pump', 'sizing', 'gpm', 'head'],
      builder: () => const SumpPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'septic_tank',
      name: 'Septic Tank Sizing',
      subtitle: 'Size septic by bedrooms & flow',
      icon: LucideIcons.container,
      category: ScreenCategory.calculators,
      searchTags: ['septic', 'tank', 'sizing', 'bedroom', 'gallon'],
      builder: () => const SepticTankScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'expansion_tank',
      name: 'Expansion Tank',
      subtitle: 'Size thermal expansion tank',
      icon: LucideIcons.maximize,
      category: ScreenCategory.calculators,
      searchTags: ['expansion', 'tank', 'thermal', 'sizing'],
      builder: () => const ExpansionTankScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'vent_sizing',
      name: 'Vent Sizing',
      subtitle: 'Size vent by DFU & length',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['vent', 'sizing', 'dfu', 'pipe'],
      builder: () => const VentSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'trap_arm',
      name: 'Trap Arm Length',
      subtitle: 'Max trap arm by pipe size',
      icon: LucideIcons.cornerDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['trap', 'arm', 'length', 'pipe'],
      builder: () => const TrapArmScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_softener',
      name: 'Water Softener',
      subtitle: 'Size softener by hardness & use',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'softener', 'hardness', 'grain'],
      builder: () => const WaterSoftenerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'flow_rate',
      name: 'Flow Rate',
      subtitle: 'GPM from pressure & pipe',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['flow', 'rate', 'gpm', 'pressure'],
      builder: () => const FlowRateScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'ejector_pump',
      name: 'Ejector Pump',
      subtitle: 'Sewage ejector sizing',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['ejector', 'pump', 'sewage', 'sizing'],
      builder: () => const EjectorPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'drain_field',
      name: 'Drain Field',
      subtitle: 'Leach field sizing',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['drain', 'field', 'leach', 'septic'],
      builder: () => const DrainFieldScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'backflow_preventer',
      name: 'Backflow Preventer',
      subtitle: 'Size by application & flow',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['backflow', 'preventer', 'rpz', 'dcva'],
      builder: () => const BackflowPreventerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_velocity',
      name: 'Water Velocity',
      subtitle: 'Calculate pipe velocity',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'velocity', 'fps', 'pipe'],
      builder: () => const WaterVelocityScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_pressure_drop',
      name: 'Pipe Pressure Drop',
      subtitle: 'Friction loss in pipe',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['pressure', 'drop', 'friction', 'loss'],
      builder: () => const PipePressureDropScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_service_sizing',
      name: 'Water Service',
      subtitle: 'Size water service line',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'service', 'sizing', 'main'],
      builder: () => const WaterServiceSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'building_drain',
      name: 'Building Drain',
      subtitle: 'Size building drain pipe',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['building', 'drain', 'sizing', 'pipe'],
      builder: () => const BuildingDrainScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'first_hour_rating',
      name: 'First Hour Rating',
      subtitle: 'Water heater FHR calculation',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['first', 'hour', 'rating', 'fhr', 'water', 'heater'],
      builder: () => const FirstHourRatingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'total_dynamic_head',
      name: 'Total Dynamic Head',
      subtitle: 'TDH pump calculation',
      icon: LucideIcons.arrowUpDown,
      category: ScreenCategory.calculators,
      searchTags: ['total', 'dynamic', 'head', 'tdh', 'pump'],
      builder: () => const TotalDynamicHeadScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'circulator_pump',
      name: 'Circulator Pump',
      subtitle: 'Recirc pump sizing',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['circulator', 'pump', 'recirc', 'sizing'],
      builder: () => const CirculatorPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_meter_sizing',
      name: 'Water Meter',
      subtitle: 'Size water meter by demand',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'meter', 'sizing', 'demand'],
      builder: () => const WaterMeterSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'prv_sizing',
      name: 'PRV Sizing',
      subtitle: 'Pressure reducing valve',
      icon: LucideIcons.chevronDown,
      category: ScreenCategory.calculators,
      searchTags: ['prv', 'pressure', 'reducing', 'valve'],
      builder: () => const PRVSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'stack_sizing',
      name: 'Stack Sizing',
      subtitle: 'Soil & waste stack sizing',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['stack', 'sizing', 'soil', 'waste'],
      builder: () => const StackSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'well_pump',
      name: 'Well Pump',
      subtitle: 'Well pump sizing',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['well', 'pump', 'sizing', 'submersible'],
      builder: () => const WellPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'recirculation_system',
      name: 'Recirculation System',
      subtitle: 'Hot water recirc design',
      icon: LucideIcons.repeat,
      category: ScreenCategory.calculators,
      searchTags: ['recirculation', 'recirc', 'hot', 'water'],
      builder: () => const RecirculationSystemScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_supply_pipe',
      name: 'Water Supply Pipe',
      subtitle: 'Size supply by WSFU',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'supply', 'pipe', 'sizing'],
      builder: () => const WaterSupplyPipeScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pressure_booster_pump',
      name: 'Pressure Booster',
      subtitle: 'Booster pump sizing',
      icon: LucideIcons.chevronsUp,
      category: ScreenCategory.calculators,
      searchTags: ['pressure', 'booster', 'pump', 'sizing'],
      builder: () => const PressureBoosterPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'static_pressure_plumbing',
      name: 'Static Pressure',
      subtitle: 'Water column pressure',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['static', 'pressure', 'psi', 'head'],
      builder: () => const plumbing_static.StaticPressureScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'dwv_pipe_sizing',
      name: 'DWV Pipe Sizing',
      subtitle: 'Drain waste vent sizing',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['dwv', 'drain', 'waste', 'vent', 'sizing'],
      builder: () => const DwvPipeSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'horizontal_branch',
      name: 'Horizontal Branch',
      subtitle: 'Branch drain sizing',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['horizontal', 'branch', 'drain', 'sizing'],
      builder: () => const HorizontalBranchScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'building_sewer',
      name: 'Building Sewer',
      subtitle: 'Sewer line sizing',
      icon: LucideIcons.arrowRight,
      category: ScreenCategory.calculators,
      searchTags: ['building', 'sewer', 'sizing', 'pipe'],
      builder: () => const BuildingSewerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'cleanout_placement',
      name: 'Cleanout Placement',
      subtitle: 'Cleanout spacing rules',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['cleanout', 'placement', 'spacing'],
      builder: () => const CleanoutPlacementScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'floor_drain',
      name: 'Floor Drain',
      subtitle: 'Floor drain sizing',
      icon: LucideIcons.squareDot,
      category: ScreenCategory.calculators,
      searchTags: ['floor', 'drain', 'sizing'],
      builder: () => const FloorDrainScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'wet_vent',
      name: 'Wet Vent',
      subtitle: 'Wet vent sizing',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['wet', 'vent', 'sizing', 'combination'],
      builder: () => const WetVentScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'grease_interceptor',
      name: 'Grease Interceptor',
      subtitle: 'Grease trap sizing',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['grease', 'interceptor', 'trap', 'sizing'],
      builder: () => const GreaseInterceptorScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'gas_meter_sizing',
      name: 'Gas Meter Sizing',
      subtitle: 'Size gas meter by load',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'meter', 'sizing', 'cfh'],
      builder: () => const GasMeterSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'gas_pressure_drop',
      name: 'Gas Pressure Drop',
      subtitle: 'Gas line pressure loss',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'pressure', 'drop', 'loss'],
      builder: () => const GasPressureDropScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'btu_cfh_converter',
      name: 'BTU/CFH Converter',
      subtitle: 'Convert BTU to CFH',
      icon: LucideIcons.repeat,
      category: ScreenCategory.calculators,
      searchTags: ['btu', 'cfh', 'converter', 'gas'],
      builder: () => const BtuCfhConverterScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'recovery_rate',
      name: 'Recovery Rate',
      subtitle: 'Water heater recovery',
      icon: LucideIcons.timerReset,
      category: ScreenCategory.calculators,
      searchTags: ['recovery', 'rate', 'water', 'heater'],
      builder: () => const RecoveryRateScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'mixing_valve',
      name: 'Mixing Valve',
      subtitle: 'Thermostatic mixing valve',
      icon: LucideIcons.merge,
      category: ScreenCategory.calculators,
      searchTags: ['mixing', 'valve', 'thermostatic', 'tmv'],
      builder: () => const MixingValveScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_hammer',
      name: 'Water Hammer',
      subtitle: 'Water hammer arrestor',
      icon: LucideIcons.hammer,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'hammer', 'arrestor'],
      builder: () => const WaterHammerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_insulation',
      name: 'Pipe Insulation',
      subtitle: 'Insulation thickness',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'insulation', 'thickness'],
      builder: () => const PipeInsulationScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'heat_tape',
      name: 'Heat Tape',
      subtitle: 'Heat trace cable sizing',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'tape', 'trace', 'cable', 'freeze'],
      builder: () => const HeatTapeScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'glycol_mix',
      name: 'Glycol Mix',
      subtitle: 'Antifreeze concentration',
      icon: LucideIcons.testTube2,
      category: ScreenCategory.calculators,
      searchTags: ['glycol', 'mix', 'antifreeze', 'concentration'],
      builder: () => const GlycolMixScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'radiant_floor',
      name: 'Radiant Floor',
      subtitle: 'Radiant heating design',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['radiant', 'floor', 'heating', 'hydronic'],
      builder: () => const RadiantFloorScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'toilet_rough_in',
      name: 'Toilet Rough-In',
      subtitle: 'Toilet rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['toilet', 'rough', 'in', 'dimensions'],
      builder: () => const ToiletRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'shower_rough_in',
      name: 'Shower Rough-In',
      subtitle: 'Shower rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['shower', 'rough', 'in', 'dimensions'],
      builder: () => const ShowerRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'tub_rough_in',
      name: 'Tub Rough-In',
      subtitle: 'Bathtub rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['tub', 'bathtub', 'rough', 'in', 'dimensions'],
      builder: () => const TubRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'lavatory_rough_in',
      name: 'Lavatory Rough-In',
      subtitle: 'Lav rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['lavatory', 'lav', 'sink', 'rough', 'in'],
      builder: () => const LavatoryRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'kitchen_sink_rough_in',
      name: 'Kitchen Sink Rough-In',
      subtitle: 'Kitchen sink dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'sink', 'rough', 'in', 'dimensions'],
      builder: () => const KitchenSinkRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'utility_sink_rough_in',
      name: 'Utility Sink Rough-In',
      subtitle: 'Utility/laundry sink dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['utility', 'laundry', 'sink', 'rough', 'in'],
      builder: () => const UtilitySinkRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'urinal_rough_in',
      name: 'Urinal Rough-In',
      subtitle: 'Urinal rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['urinal', 'rough', 'in', 'dimensions'],
      builder: () => const UrinalRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'bidet_rough_in',
      name: 'Bidet Rough-In',
      subtitle: 'Bidet rough-in dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['bidet', 'rough', 'in', 'dimensions'],
      builder: () => const BidetRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'drinking_fountain',
      name: 'Drinking Fountain',
      subtitle: 'Water cooler sizing',
      icon: LucideIcons.glassWater,
      category: ScreenCategory.calculators,
      searchTags: ['drinking', 'fountain', 'water', 'cooler'],
      builder: () => const DrinkingFountainScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'floor_sink',
      name: 'Floor Sink',
      subtitle: 'Floor sink sizing',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['floor', 'sink', 'sizing', 'commercial'],
      builder: () => const FloorSinkScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'trap_primer',
      name: 'Trap Primer',
      subtitle: 'Trap primer sizing',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['trap', 'primer', 'floor', 'drain'],
      builder: () => const TrapPrimerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'tankless_sizing',
      name: 'Tankless Water Heater',
      subtitle: 'Tankless sizing by GPM',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['tankless', 'water', 'heater', 'sizing', 'gpm'],
      builder: () => const TanklessSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'point_of_use_heater',
      name: 'Point-of-Use Heater',
      subtitle: 'Instant hot water sizing',
      icon: LucideIcons.thermometerSun,
      category: ScreenCategory.calculators,
      searchTags: ['point', 'use', 'heater', 'instant', 'hot'],
      builder: () => const PointOfUseHeaterScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'solar_water_heater',
      name: 'Solar Water Heater',
      subtitle: 'Solar thermal sizing',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['solar', 'water', 'heater', 'thermal'],
      builder: () => const SolarWaterHeaterScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'heat_pump_water_heater',
      name: 'Heat Pump Water Heater',
      subtitle: 'HPWH sizing guide',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'pump', 'water', 'heater', 'hpwh'],
      builder: () => const HeatPumpWaterHeaterScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'fixture_count',
      name: 'Fixture Count',
      subtitle: 'Required fixtures by occupancy',
      icon: LucideIcons.listOrdered,
      category: ScreenCategory.calculators,
      searchTags: ['fixture', 'count', 'occupancy', 'ada'],
      builder: () => const FixtureCountScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_demand',
      name: 'Water Demand',
      subtitle: 'Peak demand calculation',
      icon: LucideIcons.barChart,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'demand', 'peak', 'gpm'],
      builder: () => const WaterDemandScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pool_plumbing',
      name: 'Pool Plumbing',
      subtitle: 'Pool/spa pipe sizing',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['pool', 'spa', 'plumbing', 'pipe'],
      builder: () => const PoolPlumbingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'fire_sprinkler',
      name: 'Fire Sprinkler',
      subtitle: 'Residential sprinkler design',
      icon: LucideIcons.bellRing,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'sprinkler', 'nfpa', '13d'],
      builder: () => const FireSprinklerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'medical_gas',
      name: 'Medical Gas',
      subtitle: 'Medical gas pipe sizing',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['medical', 'gas', 'oxygen', 'vacuum'],
      builder: () => const MedicalGasScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'storm_drain',
      name: 'Storm Drain',
      subtitle: 'Roof drain sizing',
      icon: LucideIcons.cloudRain,
      category: ScreenCategory.calculators,
      searchTags: ['storm', 'drain', 'roof', 'rain'],
      builder: () => const StormDrainScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'rainwater_harvesting',
      name: 'Rainwater Harvesting',
      subtitle: 'Cistern sizing',
      icon: LucideIcons.cloudRainWind,
      category: ScreenCategory.calculators,
      searchTags: ['rainwater', 'harvesting', 'cistern', 'collection'],
      builder: () => const RainwaterHarvestingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'graywater',
      name: 'Graywater System',
      subtitle: 'Graywater reuse design',
      icon: LucideIcons.recycle,
      category: ScreenCategory.calculators,
      searchTags: ['graywater', 'reuse', 'irrigation'],
      builder: () => const GraywaterScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'acid_waste',
      name: 'Acid Waste',
      subtitle: 'Lab acid waste sizing',
      icon: LucideIcons.testTube2,
      category: ScreenCategory.calculators,
      searchTags: ['acid', 'waste', 'lab', 'chemical'],
      builder: () => const AcidWasteScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'compressed_air',
      name: 'Compressed Air',
      subtitle: 'Shop air pipe sizing',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['compressed', 'air', 'shop', 'pipe'],
      builder: () => const CompressedAirScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_filter_sizing',
      name: 'Water Filter',
      subtitle: 'Whole house filter sizing',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'filter', 'whole', 'house'],
      builder: () => const WaterFilterSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'uv_treatment',
      name: 'UV Treatment',
      subtitle: 'UV sterilizer sizing',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['uv', 'treatment', 'sterilizer', 'disinfection'],
      builder: () => const UvTreatmentScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'reverse_osmosis',
      name: 'Reverse Osmosis',
      subtitle: 'RO system sizing',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['reverse', 'osmosis', 'ro', 'filtration'],
      builder: () => const ReverseOsmosisScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'irrigation_sizing',
      name: 'Irrigation Sizing',
      subtitle: 'Sprinkler system design',
      icon: LucideIcons.flower,
      category: ScreenCategory.calculators,
      searchTags: ['irrigation', 'sprinkler', 'landscape'],
      builder: () => const IrrigationSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'commercial_kitchen',
      name: 'Commercial Kitchen',
      subtitle: 'Restaurant plumbing loads',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['commercial', 'kitchen', 'restaurant'],
      builder: () => const CommercialKitchenScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'ice_maker',
      name: 'Ice Maker',
      subtitle: 'Ice machine plumbing',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['ice', 'maker', 'machine', 'plumbing'],
      builder: () => const IceMakerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'vacuum_breaker',
      name: 'Vacuum Breaker',
      subtitle: 'AVB/PVB sizing',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['vacuum', 'breaker', 'avb', 'pvb'],
      builder: () => const VacuumBreakerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_support',
      name: 'Pipe Support',
      subtitle: 'Hanger spacing tables',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'support', 'hanger', 'spacing'],
      builder: () => const PipeSupportScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'thrust_block',
      name: 'Thrust Block',
      subtitle: 'Concrete thrust block sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['thrust', 'block', 'concrete', 'restraint'],
      builder: () => const ThrustBlockScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_sleeve',
      name: 'Pipe Sleeve',
      subtitle: 'Wall/floor penetration sleeves',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'sleeve', 'penetration', 'wall'],
      builder: () => const PipeSleeveScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'seismic_bracing',
      name: 'Seismic Bracing',
      subtitle: 'Pipe seismic restraint',
      icon: LucideIcons.shield,
      category: ScreenCategory.calculators,
      searchTags: ['seismic', 'bracing', 'restraint', 'earthquake'],
      builder: () => const SeismicBracingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'cleanout_sizing',
      name: 'Cleanout Sizing',
      subtitle: 'Cleanout size by pipe',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['cleanout', 'sizing', 'pipe'],
      builder: () => const CleanoutSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_test',
      name: 'Water Test',
      subtitle: 'DWV air/water test',
      icon: LucideIcons.testTube,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'test', 'air', 'dwv', 'pressure'],
      builder: () => const WaterTestScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_weight',
      name: 'Pipe Weight',
      subtitle: 'Calculate pipe weight',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'weight', 'pounds', 'foot'],
      builder: () => const PipeWeightScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'flow_conversion',
      name: 'Flow Conversion',
      subtitle: 'GPM, LPM, CFM converter',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['flow', 'conversion', 'gpm', 'lpm'],
      builder: () => const FlowConversionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pressure_conversion',
      name: 'Pressure Conversion',
      subtitle: 'PSI, kPa, bar converter',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['pressure', 'conversion', 'psi', 'kpa'],
      builder: () => const PressureConversionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'temperature_conversion',
      name: 'Temperature Conversion',
      subtitle: 'F, C, K converter',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['temperature', 'conversion', 'fahrenheit', 'celsius'],
      builder: () => const TemperatureConversionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'dishwasher_commercial',
      name: 'Commercial Dishwasher',
      subtitle: 'Dishwasher plumbing',
      icon: LucideIcons.utensilsCrossed,
      category: ScreenCategory.calculators,
      searchTags: ['dishwasher', 'commercial', 'restaurant'],
      builder: () => const DishwasherCommercialScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'laundry_commercial',
      name: 'Commercial Laundry',
      subtitle: 'Laundromat plumbing',
      icon: LucideIcons.shirt,
      category: ScreenCategory.calculators,
      searchTags: ['laundry', 'commercial', 'washer'],
      builder: () => const LaundryCommercialScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'hose_bib',
      name: 'Hose Bib',
      subtitle: 'Exterior faucet sizing',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['hose', 'bib', 'sillcock', 'exterior'],
      builder: () => const HoseBibScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'drip_irrigation',
      name: 'Drip Irrigation',
      subtitle: 'Drip system design',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['drip', 'irrigation', 'emitter', 'tubing'],
      builder: () => const DripIrrigationScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'mop_sink',
      name: 'Mop Sink',
      subtitle: 'Service sink rough-in',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['mop', 'sink', 'service', 'janitorial'],
      builder: () => const MopSinkScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'washing_machine',
      name: 'Washing Machine',
      subtitle: 'Washer box requirements',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['washing', 'machine', 'washer', 'laundry'],
      builder: () => const WashingMachineScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_closet_carrier',
      name: 'Water Closet Carrier',
      subtitle: 'Wall-hung toilet carrier',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'closet', 'carrier', 'wall', 'hung'],
      builder: () => const WaterClosetCarrierScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'thermal_expansion',
      name: 'Thermal Expansion',
      subtitle: 'Pipe expansion calculation',
      icon: LucideIcons.maximize2,
      category: ScreenCategory.calculators,
      searchTags: ['thermal', 'expansion', 'pipe', 'loop'],
      builder: () => const ThermalExpansionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'cross_connection',
      name: 'Cross Connection',
      subtitle: 'Backflow device selection',
      icon: LucideIcons.gitCompare,
      category: ScreenCategory.calculators,
      searchTags: ['cross', 'connection', 'backflow', 'protection'],
      builder: () => const CrossConnectionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'air_gap',
      name: 'Air Gap',
      subtitle: 'Air gap dimensions',
      icon: LucideIcons.arrowUpDown,
      category: ScreenCategory.calculators,
      searchTags: ['air', 'gap', 'backflow', 'indirect'],
      builder: () => const AirGapScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'rpz_sizing',
      name: 'RPZ Sizing',
      subtitle: 'Reduced pressure zone sizing',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['rpz', 'reduced', 'pressure', 'zone', 'backflow'],
      builder: () => const RpzSizingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'double_check_valve',
      name: 'Double Check Valve',
      subtitle: 'DCVA sizing',
      icon: LucideIcons.checkCheck,
      category: ScreenCategory.calculators,
      searchTags: ['double', 'check', 'valve', 'dcva', 'backflow'],
      builder: () => const DoubleCheckValveScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'eyewash_station',
      name: 'Eyewash Station',
      subtitle: 'Emergency eyewash requirements',
      icon: LucideIcons.eye,
      category: ScreenCategory.calculators,
      searchTags: ['eyewash', 'station', 'emergency', 'ansi'],
      builder: () => const EyewashStationScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'emergency_shower',
      name: 'Emergency Shower',
      subtitle: 'Drench shower sizing',
      icon: LucideIcons.showerHead,
      category: ScreenCategory.calculators,
      searchTags: ['emergency', 'shower', 'drench', 'safety'],
      builder: () => const EmergencyShowerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'firestop',
      name: 'Firestop',
      subtitle: 'Pipe penetration firestop',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['firestop', 'penetration', 'fire', 'rating'],
      builder: () => const FirestopScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'coffee_service',
      name: 'Coffee Service',
      subtitle: 'Commercial beverage plumbing',
      icon: LucideIcons.coffee,
      category: ScreenCategory.calculators,
      searchTags: ['coffee', 'service', 'beverage', 'commercial'],
      builder: () => const CoffeeServiceScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'dental_chair',
      name: 'Dental Chair',
      subtitle: 'Dental operatory plumbing',
      icon: LucideIcons.armchair,
      category: ScreenCategory.calculators,
      searchTags: ['dental', 'chair', 'operatory', 'medical'],
      builder: () => const DentalChairScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_hanger',
      name: 'Pipe Hanger',
      subtitle: 'Hanger spacing by material',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'hanger', 'support', 'spacing'],
      builder: () => const PipeHangerScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_distribution',
      name: 'Water Distribution',
      subtitle: 'Distribution system layout',
      icon: LucideIcons.gitFork,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'distribution', 'manifold', 'trunk'],
      builder: () => const WaterDistributionScreen(),
      trade: 'plumbing',
    ),
  ];

  // =========================================================================
  // HVAC CALCULATORS (14)
  // =========================================================================
  static final List<ScreenEntry> hvacCalculators = [
    ScreenEntry(
      id: 'heat_load',
      name: 'Heat Load',
      subtitle: 'Manual J heating load',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'load', 'manual', 'j', 'btu', 'heating'],
      builder: () => const HeatLoadScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'cooling_load',
      name: 'Cooling Load',
      subtitle: 'Manual J cooling load',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'load', 'manual', 'j', 'btu', 'ac'],
      builder: () => const CoolingLoadScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'duct_sizing',
      name: 'Duct Sizing',
      subtitle: 'Manual D duct sizing',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['duct', 'sizing', 'manual', 'd', 'cfm'],
      builder: () => const DuctSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'cfm_room',
      name: 'Room CFM',
      subtitle: 'CFM per room calculation',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['cfm', 'room', 'airflow', 'sizing'],
      builder: () => const CfmRoomScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigerant_charge',
      name: 'Refrigerant Charge',
      subtitle: 'Line set charge calculation',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'charge', 'line', 'set', 'r410a'],
      builder: () => const RefrigerantChargeScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'static_pressure_hvac',
      name: 'Static Pressure',
      subtitle: 'System static pressure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['static', 'pressure', 'esp', 'tesp', 'duct'],
      builder: () => const hvac_static.StaticPressureScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'blower_door',
      name: 'Blower Door',
      subtitle: 'Building tightness test',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['blower', 'door', 'ach50', 'cfm50', 'air', 'seal'],
      builder: () => const BlowerDoorScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'ventilation',
      name: 'Ventilation',
      subtitle: 'ASHRAE 62.2 ventilation',
      icon: LucideIcons.airVent,
      category: ScreenCategory.calculators,
      searchTags: ['ventilation', 'ashrae', '62.2', 'fresh', 'air'],
      builder: () => const VentilationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'superheat_subcooling',
      name: 'Superheat/Subcooling',
      subtitle: 'Refrigerant charging',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['superheat', 'subcooling', 'charging', 'refrigerant'],
      builder: () => const SuperheatSubcoolingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'btu_calculator',
      name: 'BTU Calculator',
      subtitle: 'Quick BTU estimation',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['btu', 'calculator', 'quick', 'estimate', 'sizing'],
      builder: () => const BtuCalculatorScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'gas_pipe_sizing_hvac',
      name: 'Gas Pipe Sizing',
      subtitle: 'IFGC/NFPA 54 pipe sizing',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['gas', 'pipe', 'sizing', 'ifgc', 'nfpa', 'btu'],
      builder: () => const hvac_gas.GasPipeSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'humidity',
      name: 'Humidity Control',
      subtitle: 'Humidifier/dehumidifier sizing',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['humidity', 'humidifier', 'dehumidifier', 'sizing'],
      builder: () => const HumidityScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'filter_sizing',
      name: 'Filter Sizing',
      subtitle: 'Air filter area & MERV',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['filter', 'sizing', 'merv', 'cfm', 'area'],
      builder: () => const FilterSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'temperature_rise',
      name: 'Temperature Rise',
      subtitle: 'Furnace temp rise test',
      icon: LucideIcons.thermometerSun,
      category: ScreenCategory.calculators,
      searchTags: ['temperature', 'rise', 'furnace', 'test', 'airflow'],
      builder: () => const TemperatureRiseScreen(),
      trade: 'hvac',
    ),
    // =========================================================================
    // HVAC OVERFLOW - Session 4 calculators (100+)
    // =========================================================================
    ScreenEntry(
      id: 'ac_tonnage',
      name: 'AC Tonnage',
      subtitle: 'Air conditioner sizing',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'tonnage', 'sizing', 'air', 'conditioner', 'btu'],
      builder: () => const AcTonnageScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'ahu_sizing',
      name: 'AHU Sizing',
      subtitle: 'Air handler unit sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['ahu', 'air', 'handler', 'unit', 'sizing', 'cfm'],
      builder: () => const AhuSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'air_balance',
      name: 'Air Balance',
      subtitle: 'Supply/return air balance',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['air', 'balance', 'supply', 'return', 'cfm'],
      builder: () => const AirBalanceScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'air_changes',
      name: 'Air Changes',
      subtitle: 'ACH calculation',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['air', 'changes', 'ach', 'hour', 'ventilation'],
      builder: () => const AirChangesScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'air_handler_sizing',
      name: 'Air Handler Sizing',
      subtitle: 'Residential AHU sizing',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['air', 'handler', 'sizing', 'residential'],
      builder: () => const AirHandlerSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'airflow_balance',
      name: 'Airflow Balance',
      subtitle: 'TAB airflow balancing',
      icon: LucideIcons.gitCompare,
      category: ScreenCategory.calculators,
      searchTags: ['airflow', 'balance', 'tab', 'test'],
      builder: () => const AirflowBalanceScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'airflow_hood',
      name: 'Airflow Hood',
      subtitle: 'Capture hood readings',
      icon: LucideIcons.maximize,
      category: ScreenCategory.calculators,
      searchTags: ['airflow', 'hood', 'capture', 'cfm', 'measurement'],
      builder: () => const AirflowHoodScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'belt_tension',
      name: 'Belt Tension',
      subtitle: 'Drive belt tensioning',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['belt', 'tension', 'drive', 'blower', 'motor'],
      builder: () => const BeltTensionScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'blower_motor',
      name: 'Blower Motor',
      subtitle: 'Motor sizing & troubleshooting',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['blower', 'motor', 'ecm', 'psc', 'sizing'],
      builder: () => const BlowerMotorScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'boiler_efficiency',
      name: 'Boiler Efficiency',
      subtitle: 'Combustion efficiency calc',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['boiler', 'efficiency', 'combustion', 'afue'],
      builder: () => const BoilerEfficiencyScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'boiler_sizing',
      name: 'Boiler Sizing',
      subtitle: 'Hydronic boiler sizing',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['boiler', 'sizing', 'btu', 'hydronic', 'heating'],
      builder: () => const BoilerSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'brazing_calc',
      name: 'Brazing Calculator',
      subtitle: 'Brazing rod & gas estimation',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['brazing', 'solder', 'copper', 'refrigerant', 'line'],
      builder: () => const BrazingCalcScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'building_pressure',
      name: 'Building Pressure',
      subtitle: 'Positive/negative pressure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['building', 'pressure', 'positive', 'negative', 'stack'],
      builder: () => const BuildingPressureScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'chiller_cop',
      name: 'Chiller COP',
      subtitle: 'Coefficient of performance',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['chiller', 'cop', 'efficiency', 'kw', 'ton'],
      builder: () => const ChillerCopScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'chiller_sizing',
      name: 'Chiller Sizing',
      subtitle: 'Chilled water system sizing',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['chiller', 'sizing', 'tonnage', 'chilled', 'water'],
      builder: () => const ChillerSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'clean_room',
      name: 'Clean Room',
      subtitle: 'ISO clean room HVAC',
      icon: LucideIcons.sparkles,
      category: ScreenCategory.calculators,
      searchTags: ['clean', 'room', 'iso', 'hepa', 'pressure'],
      builder: () => const CleanRoomScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'co2_ventilation',
      name: 'CO2 Ventilation',
      subtitle: 'Demand control ventilation',
      icon: LucideIcons.cloud,
      category: ScreenCategory.calculators,
      searchTags: ['co2', 'ventilation', 'dcv', 'demand', 'control'],
      builder: () => const Co2VentilationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'coil_bypass_factor',
      name: 'Coil Bypass Factor',
      subtitle: 'Cooling coil BPF',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['coil', 'bypass', 'factor', 'bpf', 'cooling'],
      builder: () => const CoilBypassFactorScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'coil_selection',
      name: 'Coil Selection',
      subtitle: 'Evaporator/condenser coil',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['coil', 'selection', 'evaporator', 'condenser'],
      builder: () => const CoilSelectionScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'combustion_air',
      name: 'Combustion Air',
      subtitle: 'Combustion air requirements',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['combustion', 'air', 'furnace', 'boiler', 'vent'],
      builder: () => const CombustionAirScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'compressor_amp_draw',
      name: 'Compressor Amps',
      subtitle: 'Compressor amp draw analysis',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['compressor', 'amp', 'rla', 'lra', 'current'],
      builder: () => const CompressorAmpDrawScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'compressor_capacity',
      name: 'Compressor Capacity',
      subtitle: 'Capacity vs conditions',
      icon: LucideIcons.barChart2,
      category: ScreenCategory.calculators,
      searchTags: ['compressor', 'capacity', 'btu', 'conditions'],
      builder: () => const CompressorCapacityScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'compressor_oil',
      name: 'Compressor Oil',
      subtitle: 'Oil charge & compatibility',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['compressor', 'oil', 'poe', 'pag', 'charge'],
      builder: () => const CompressorOilScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'condensate_drain',
      name: 'Condensate Drain',
      subtitle: 'Drain line sizing',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['condensate', 'drain', 'line', 'trap', 'pump'],
      builder: () => const CondensateDrainScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'condenser_split',
      name: 'Condenser Split',
      subtitle: 'Condenser temperature split',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['condenser', 'split', 'temperature', 'td'],
      builder: () => const CondenserSplitScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'condenser_td',
      name: 'Condenser TD',
      subtitle: 'Temperature difference calc',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['condenser', 'td', 'temperature', 'difference'],
      builder: () => const CondenserTdScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'control_valve',
      name: 'Control Valve',
      subtitle: 'Valve Cv sizing',
      icon: LucideIcons.disc,
      category: ScreenCategory.calculators,
      searchTags: ['control', 'valve', 'cv', 'sizing', 'hydronic'],
      builder: () => const ControlValveScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'cooling_coil',
      name: 'Cooling Coil',
      subtitle: 'DX & chilled water coils',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'coil', 'dx', 'chilled', 'water'],
      builder: () => const CoolingCoilScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'cooling_tower',
      name: 'Cooling Tower',
      subtitle: 'Tower sizing & performance',
      icon: LucideIcons.building2,
      category: ScreenCategory.calculators,
      searchTags: ['cooling', 'tower', 'tonnage', 'wet', 'bulb'],
      builder: () => const CoolingTowerScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'damper_sizing',
      name: 'Damper Sizing',
      subtitle: 'Control damper sizing',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['damper', 'sizing', 'control', 'cfm', 'pressure'],
      builder: () => const DamperSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'data_center_cooling',
      name: 'Data Center Cooling',
      subtitle: 'Server room HVAC',
      icon: LucideIcons.server,
      category: ScreenCategory.calculators,
      searchTags: ['data', 'center', 'server', 'cooling', 'kw'],
      builder: () => const DataCenterCoolingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'defrost_cycle',
      name: 'Defrost Cycle',
      subtitle: 'Heat pump defrost timing',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['defrost', 'cycle', 'heat', 'pump', 'timing'],
      builder: () => const DefrostCycleScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'dehumidifier_sizing',
      name: 'Dehumidifier Sizing',
      subtitle: 'Pints per day calculation',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['dehumidifier', 'sizing', 'pints', 'humidity'],
      builder: () => const DehumidifierSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'delta_t',
      name: 'Delta T',
      subtitle: 'Temperature differential',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['delta', 't', 'temperature', 'differential', 'split'],
      builder: () => const DeltaTScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'drain_pan',
      name: 'Drain Pan',
      subtitle: 'Secondary pan sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['drain', 'pan', 'secondary', 'overflow'],
      builder: () => const DrainPanScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'duct_insulation',
      name: 'Duct Insulation',
      subtitle: 'R-value & thickness',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['duct', 'insulation', 'r-value', 'thickness'],
      builder: () => const DuctInsulationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'duct_leakage',
      name: 'Duct Leakage',
      subtitle: 'Leakage class calculation',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['duct', 'leakage', 'class', 'seal', 'test'],
      builder: () => const DuctLeakageScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'duct_velocity',
      name: 'Duct Velocity',
      subtitle: 'FPM calculation',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['duct', 'velocity', 'fpm', 'cfm', 'area'],
      builder: () => const DuctVelocityScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'economizer',
      name: 'Economizer',
      subtitle: 'Free cooling calculation',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['economizer', 'free', 'cooling', 'outdoor', 'air'],
      builder: () => const EconomizerScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'energy_recovery',
      name: 'Energy Recovery',
      subtitle: 'ERV/HRV effectiveness',
      icon: LucideIcons.recycle,
      category: ScreenCategory.calculators,
      searchTags: ['energy', 'recovery', 'erv', 'hrv', 'effectiveness'],
      builder: () => const EnergyRecoveryScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'enthalpy',
      name: 'Enthalpy',
      subtitle: 'Air enthalpy calculation',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['enthalpy', 'btu', 'lb', 'psychrometric'],
      builder: () => const EnthalpyScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'erv_hrv_sizing',
      name: 'ERV/HRV Sizing',
      subtitle: 'Ventilator sizing',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['erv', 'hrv', 'sizing', 'ventilator', 'cfm'],
      builder: () => const ErvHrvSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'evacuation_time',
      name: 'Evacuation Time',
      subtitle: 'Vacuum pump time calc',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['evacuation', 'time', 'vacuum', 'pump', 'micron'],
      builder: () => const EvacuationTimeScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'evaporator_split',
      name: 'Evaporator Split',
      subtitle: 'Evaporator temp split',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['evaporator', 'split', 'temperature', 'td'],
      builder: () => const EvaporatorSplitScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'evaporator_td',
      name: 'Evaporator TD',
      subtitle: 'Temperature difference',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['evaporator', 'td', 'temperature', 'difference'],
      builder: () => const EvaporatorTdScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'exhaust_fan',
      name: 'Exhaust Fan',
      subtitle: 'Fan sizing & selection',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['exhaust', 'fan', 'cfm', 'sizing', 'bathroom'],
      builder: () => const ExhaustFanScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'fan_affinity',
      name: 'Fan Laws',
      subtitle: 'Fan affinity laws',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['fan', 'affinity', 'laws', 'rpm', 'cfm', 'hp'],
      builder: () => const FanAffinityScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'fan_coil',
      name: 'Fan Coil Unit',
      subtitle: 'FCU sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['fan', 'coil', 'fcu', 'unit', 'sizing'],
      builder: () => const FanCoilScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'fan_law',
      name: 'Fan Law Calculator',
      subtitle: 'Speed/flow/pressure',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['fan', 'law', 'speed', 'flow', 'pressure'],
      builder: () => const FanLawScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'filter_pressure',
      name: 'Filter Pressure Drop',
      subtitle: 'Dirty filter indication',
      icon: LucideIcons.filter,
      category: ScreenCategory.calculators,
      searchTags: ['filter', 'pressure', 'drop', 'dirty', 'change'],
      builder: () => const FilterPressureScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'flue_sizing',
      name: 'Flue Sizing',
      subtitle: 'Vent pipe sizing',
      icon: LucideIcons.arrowUpCircle,
      category: ScreenCategory.calculators,
      searchTags: ['flue', 'vent', 'sizing', 'category', 'combustion'],
      builder: () => const FlueSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'friction_rate',
      name: 'Friction Rate',
      subtitle: 'Duct friction calculation',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['friction', 'rate', 'duct', 'pressure', 'drop'],
      builder: () => const FrictionRateScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'furnace_sizing',
      name: 'Furnace Sizing',
      subtitle: 'Gas furnace BTU sizing',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['furnace', 'sizing', 'btu', 'gas', 'heating'],
      builder: () => const FurnaceSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'geothermal_loop',
      name: 'Geothermal Loop',
      subtitle: 'Ground loop sizing',
      icon: LucideIcons.globe,
      category: ScreenCategory.calculators,
      searchTags: ['geothermal', 'loop', 'ground', 'source', 'heat', 'pump'],
      builder: () => const GeothermalLoopScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'glycol_freeze',
      name: 'Glycol Freeze Point',
      subtitle: 'Freeze protection calc',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['glycol', 'freeze', 'point', 'protection', 'antifreeze'],
      builder: () => const GlycolFreezeScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'grille_diffuser',
      name: 'Grille & Diffuser',
      subtitle: 'Supply/return sizing',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['grille', 'diffuser', 'register', 'sizing', 'cfm'],
      builder: () => const GrilleDiffuserScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'heat_exchanger',
      name: 'Heat Exchanger',
      subtitle: 'HX sizing & effectiveness',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'exchanger', 'effectiveness', 'ntu'],
      builder: () => const HeatExchangerScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'heat_pump_balance',
      name: 'Heat Pump Balance Point',
      subtitle: 'Auxiliary heat calculation',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'pump', 'balance', 'point', 'auxiliary'],
      builder: () => const HeatPumpBalancePointScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'heat_pump_sizing',
      name: 'Heat Pump Sizing',
      subtitle: 'HP tonnage calculation',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'pump', 'sizing', 'tonnage', 'hspf'],
      builder: () => const HeatPumpSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'humidifier_sizing',
      name: 'Humidifier Sizing',
      subtitle: 'Pounds per hour calc',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['humidifier', 'sizing', 'humidity', 'lbs', 'hour'],
      builder: () => const HumidifierSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'hydronic_flow',
      name: 'Hydronic Flow',
      subtitle: 'GPM calculation',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['hydronic', 'flow', 'gpm', 'btu', 'delta', 't'],
      builder: () => const HydronicFlowScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'hydronic_pipe',
      name: 'Hydronic Pipe Sizing',
      subtitle: 'Pipe diameter selection',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['hydronic', 'pipe', 'sizing', 'gpm', 'velocity'],
      builder: () => const HydronicPipeScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'infiltration',
      name: 'Infiltration Load',
      subtitle: 'Air leakage heat load',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['infiltration', 'load', 'air', 'leakage', 'btu'],
      builder: () => const InfiltrationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'kitchen_exhaust',
      name: 'Kitchen Exhaust',
      subtitle: 'Commercial kitchen CFM',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'exhaust', 'hood', 'cfm', 'commercial'],
      builder: () => const KitchenExhaustScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'lab_exhaust',
      name: 'Lab Exhaust',
      subtitle: 'Fume hood ventilation',
      icon: LucideIcons.flaskConical,
      category: ScreenCategory.calculators,
      searchTags: ['lab', 'exhaust', 'fume', 'hood', 'ach'],
      builder: () => const LabExhaustScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'latent_load',
      name: 'Latent Load',
      subtitle: 'Moisture load calculation',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['latent', 'load', 'moisture', 'humidity', 'btu'],
      builder: () => const LatentLoadScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'makeup_air',
      name: 'Makeup Air',
      subtitle: 'MUA sizing',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['makeup', 'air', 'mua', 'exhaust', 'balance'],
      builder: () => const MakeupAirScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'manual_j',
      name: 'Manual J',
      subtitle: 'Residential load calculation',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['manual', 'j', 'load', 'calculation', 'acca'],
      builder: () => const ManualJScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'mini_split_sizing',
      name: 'Mini Split Sizing',
      subtitle: 'Ductless system sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['mini', 'split', 'ductless', 'sizing', 'btu'],
      builder: () => const MiniSplitSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'motor_run_capacitor',
      name: 'Motor Run Capacitor',
      subtitle: 'Capacitor sizing',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'run', 'capacitor', 'mfd', 'sizing'],
      builder: () => const MotorRunCapacitorScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'motor_troubleshoot',
      name: 'Motor Troubleshoot',
      subtitle: 'Diagnostic guide',
      icon: LucideIcons.wrench,
      category: ScreenCategory.calculators,
      searchTags: ['motor', 'troubleshoot', 'diagnostic', 'fault'],
      builder: () => const MotorTroubleshootScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'nitrogen_test',
      name: 'Nitrogen Test',
      subtitle: 'Pressure test procedure',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['nitrogen', 'test', 'pressure', 'leak', 'psig'],
      builder: () => const NitrogenTestScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'pid_tuning',
      name: 'PID Tuning',
      subtitle: 'Controller tuning',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['pid', 'tuning', 'controller', 'loop', 'hvac'],
      builder: () => const PidTuningScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'pipe_expansion',
      name: 'Pipe Expansion',
      subtitle: 'Thermal expansion calc',
      icon: LucideIcons.arrowUpDown,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'expansion', 'thermal', 'loop', 'length'],
      builder: () => const PipeExpansionScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'psychrometric',
      name: 'Psychrometric',
      subtitle: 'Air properties calculator',
      icon: LucideIcons.cloud,
      category: ScreenCategory.calculators,
      searchTags: ['psychrometric', 'humidity', 'dew', 'point', 'wet', 'bulb'],
      builder: () => const PsychrometricScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'ptac_sizing',
      name: 'PTAC Sizing',
      subtitle: 'Packaged terminal AC',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['ptac', 'sizing', 'packaged', 'terminal', 'hotel'],
      builder: () => const PtacSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'pump_affinity',
      name: 'Pump Laws',
      subtitle: 'Pump affinity laws',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['pump', 'affinity', 'laws', 'rpm', 'gpm', 'head'],
      builder: () => const PumpAffinityScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'pump_head',
      name: 'Pump Head',
      subtitle: 'Total dynamic head',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['pump', 'head', 'tdh', 'feet', 'pressure'],
      builder: () => const PumpHeadScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'radiant_panel',
      name: 'Radiant Panel',
      subtitle: 'Ceiling/wall radiant',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['radiant', 'panel', 'ceiling', 'wall', 'btu'],
      builder: () => const RadiantPanelScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigerant_leak_rate',
      name: 'Refrigerant Leak Rate',
      subtitle: 'EPA leak rate calc',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'leak', 'rate', 'epa', 'pounds'],
      builder: () => const RefrigerantLeakRateScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigerant_line',
      name: 'Refrigerant Line',
      subtitle: 'Line set sizing',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'line', 'sizing', 'suction', 'liquid'],
      builder: () => const RefrigerantLineScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigerant_pt_chart',
      name: 'P-T Chart',
      subtitle: 'Pressure-temperature',
      icon: LucideIcons.lineChart,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'pt', 'chart', 'pressure', 'temperature'],
      builder: () => const RefrigerantPtChartScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigerant_recovery',
      name: 'Refrigerant Recovery',
      subtitle: 'Recovery time estimate',
      icon: LucideIcons.download,
      category: ScreenCategory.calculators,
      searchTags: ['refrigerant', 'recovery', 'time', 'tank', 'pounds'],
      builder: () => const RefrigerantRecoveryScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'room_load',
      name: 'Room Load',
      subtitle: 'Individual room BTU',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['room', 'load', 'btu', 'calculation', 'sizing'],
      builder: () => const RoomLoadScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'round_to_rect',
      name: 'Round to Rectangular',
      subtitle: 'Duct equivalent sizing',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['round', 'rectangular', 'duct', 'equivalent', 'sizing'],
      builder: () => const RoundToRectangularScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'sensible_heat_ratio',
      name: 'Sensible Heat Ratio',
      subtitle: 'SHR calculation',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['sensible', 'heat', 'ratio', 'shr', 'latent'],
      builder: () => const SensibleHeatRatioScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'server_room_cooling',
      name: 'Server Room Cooling',
      subtitle: 'IT load cooling',
      icon: LucideIcons.server,
      category: ScreenCategory.calculators,
      searchTags: ['server', 'room', 'cooling', 'data', 'center', 'kw'],
      builder: () => const ServerRoomCoolingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'setpoint_reset',
      name: 'Setpoint Reset',
      subtitle: 'OAT reset schedule',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['setpoint', 'reset', 'oat', 'schedule', 'energy'],
      builder: () => const SetpointResetScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'snow_melt',
      name: 'Snow Melt',
      subtitle: 'Radiant snow melting',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['snow', 'melt', 'radiant', 'driveway', 'btu'],
      builder: () => const SnowMeltScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'sound_attenuation',
      name: 'Sound Attenuation',
      subtitle: 'Duct silencer sizing',
      icon: LucideIcons.volume2,
      category: ScreenCategory.calculators,
      searchTags: ['sound', 'attenuation', 'silencer', 'noise', 'nc'],
      builder: () => const SoundAttenuationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'split_system_lineset',
      name: 'Split System Lineset',
      subtitle: 'Line set length limits',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['split', 'system', 'lineset', 'length', 'elevation'],
      builder: () => const SplitSystemLinesetScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'steam_pipe',
      name: 'Steam Pipe',
      subtitle: 'Steam pipe sizing',
      icon: LucideIcons.cloud,
      category: ScreenCategory.calculators,
      searchTags: ['steam', 'pipe', 'sizing', 'psi', 'lbs'],
      builder: () => const SteamPipeScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'steam_trap',
      name: 'Steam Trap',
      subtitle: 'Trap selection & sizing',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['steam', 'trap', 'sizing', 'condensate', 'selection'],
      builder: () => const SteamTrapScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'supply_register',
      name: 'Supply Register',
      subtitle: 'Register sizing',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['supply', 'register', 'sizing', 'cfm', 'throw'],
      builder: () => const SupplyRegisterScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'system_curve',
      name: 'System Curve',
      subtitle: 'Fan/pump system curve',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['system', 'curve', 'fan', 'pump', 'operating', 'point'],
      builder: () => const SystemCurveScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'thermal_storage',
      name: 'Thermal Storage',
      subtitle: 'Ice/chilled water storage',
      icon: LucideIcons.database,
      category: ScreenCategory.calculators,
      searchTags: ['thermal', 'storage', 'ice', 'chilled', 'water', 'tank'],
      builder: () => const ThermalStorageScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'txv_sizing',
      name: 'TXV Sizing',
      subtitle: 'Expansion valve sizing',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['txv', 'expansion', 'valve', 'sizing', 'tonnage'],
      builder: () => const TxvSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'unit_heater',
      name: 'Unit Heater',
      subtitle: 'Gas/electric unit heater',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['unit', 'heater', 'gas', 'electric', 'btu'],
      builder: () => const UnitHeaterScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'vav_box',
      name: 'VAV Box',
      subtitle: 'Variable air volume',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['vav', 'box', 'variable', 'air', 'volume', 'cfm'],
      builder: () => const VavBoxScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'vrf_piping',
      name: 'VRF Piping',
      subtitle: 'Variable refrigerant flow',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['vrf', 'piping', 'variable', 'refrigerant', 'flow'],
      builder: () => const VrfPipingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'walk_in_cooler',
      name: 'Walk-In Cooler',
      subtitle: 'Refrigeration sizing',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['walk', 'in', 'cooler', 'freezer', 'refrigeration', 'btu'],
      builder: () => const WalkInCoolerScreen(),
      trade: 'hvac',
    ),
  ];

  // =========================================================================
  // SOLAR CALCULATORS (10 - System Sizing)
  // =========================================================================
  static final List<ScreenEntry> solarCalculators = [
    ScreenEntry(
      id: 'system_size',
      name: 'System Size',
      subtitle: 'kW from annual usage',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['system', 'size', 'kw', 'annual', 'usage', 'solar'],
      builder: () => const SystemSizeScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'panel_count',
      name: 'Panel Count',
      subtitle: 'Modules needed for target kW',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['panel', 'count', 'modules', 'solar'],
      builder: () => const PanelCountScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'roof_area',
      name: 'Roof Area',
      subtitle: 'Sq ft for target system',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'area', 'square', 'feet', 'solar'],
      builder: () => const RoofAreaScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'production_estimator',
      name: 'Production Estimator',
      subtitle: 'kWh/year by location',
      icon: LucideIcons.barChart,
      category: ScreenCategory.calculators,
      searchTags: ['production', 'estimate', 'kwh', 'year', 'solar'],
      builder: () => const ProductionEstimatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'utility_bill_analyzer',
      name: 'Bill Analyzer',
      subtitle: 'kWh from utility bill',
      icon: LucideIcons.receipt,
      category: ScreenCategory.calculators,
      searchTags: ['utility', 'bill', 'analyzer', 'kwh', 'solar'],
      builder: () => const UtilityBillAnalyzerScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'solar_fraction',
      name: 'Solar Fraction',
      subtitle: '% of usage covered',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['solar', 'fraction', 'percent', 'coverage'],
      builder: () => const SolarFractionScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'capacity_factor',
      name: 'Capacity Factor',
      subtitle: 'Actual vs rated output',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['capacity', 'factor', 'actual', 'rated', 'solar'],
      builder: () => const CapacityFactorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'specific_yield',
      name: 'Specific Yield',
      subtitle: 'kWh per kWp',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['specific', 'yield', 'kwh', 'kwp', 'solar'],
      builder: () => const SpecificYieldScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'performance_ratio',
      name: 'Performance Ratio',
      subtitle: 'System efficiency metric',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['performance', 'ratio', 'efficiency', 'solar'],
      builder: () => const PerformanceRatioScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'dc_ac_ratio',
      name: 'DC/AC Ratio',
      subtitle: 'Optimal inverter loading',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['dc', 'ac', 'ratio', 'inverter', 'clipping', 'solar'],
      builder: () => const DcAcRatioScreen(),
      trade: 'solar',
    ),
    // Solar Geometry
    ScreenEntry(
      id: 'azimuth',
      name: 'Azimuth',
      subtitle: 'Optimal panel orientation',
      icon: LucideIcons.compass,
      category: ScreenCategory.calculators,
      searchTags: ['azimuth', 'orientation', 'compass', 'direction', 'solar'],
      builder: () => const AzimuthScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'tilt_angle',
      name: 'Tilt Angle',
      subtitle: 'Optimal panel pitch',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['tilt', 'angle', 'pitch', 'latitude', 'solar'],
      builder: () => const TiltAngleScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'sun_path',
      name: 'Sun Path',
      subtitle: 'Solar altitude & azimuth',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['sun', 'path', 'altitude', 'azimuth', 'position', 'solar'],
      builder: () => const SunPathScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'shade_analysis',
      name: 'Shade Analysis',
      subtitle: 'Production loss estimate',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['shade', 'shading', 'loss', 'obstruction', 'solar'],
      builder: () => const ShadeAnalysisScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'row_spacing',
      name: 'Row Spacing',
      subtitle: 'Ground mount inter-row spacing',
      icon: LucideIcons.alignVerticalSpaceAround,
      category: ScreenCategory.calculators,
      searchTags: ['row', 'spacing', 'ground', 'mount', 'shadow', 'solar'],
      builder: () => const RowSpacingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'inter_row_shading',
      name: 'Inter-Row Shading',
      subtitle: 'Winter solstice shadow analysis',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['inter', 'row', 'shading', 'winter', 'solstice', 'solar'],
      builder: () => const InterRowShadingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'module_orientation',
      name: 'Module Orientation',
      subtitle: 'Portrait vs landscape compare',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['module', 'orientation', 'portrait', 'landscape', 'solar'],
      builder: () => const ModuleOrientationScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'effective_irradiance',
      name: 'Effective Irradiance',
      subtitle: 'POA irradiance calculator',
      icon: LucideIcons.sunDim,
      category: ScreenCategory.calculators,
      searchTags: ['effective', 'irradiance', 'poa', 'ghi', 'solar'],
      builder: () => const EffectiveIrradianceScreen(),
      trade: 'solar',
    ),
    // String Sizing
    ScreenEntry(
      id: 'string_size',
      name: 'String Size',
      subtitle: 'Modules per string',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['string', 'size', 'modules', 'series', 'solar'],
      builder: () => const StringSizeScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'voc_calculator',
      name: 'Voc Calculator',
      subtitle: 'Open circuit voltage',
      icon: LucideIcons.circuitBoard,
      category: ScreenCategory.calculators,
      searchTags: ['voc', 'open', 'circuit', 'voltage', 'solar'],
      builder: () => const VocCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'vmp_calculator',
      name: 'Vmp Calculator',
      subtitle: 'Max power voltage',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['vmp', 'max', 'power', 'voltage', 'solar'],
      builder: () => const VmpCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'isc_calculator',
      name: 'Isc Calculator',
      subtitle: 'Short circuit current',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['isc', 'short', 'circuit', 'current', 'solar'],
      builder: () => const IscCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'imp_calculator',
      name: 'Imp Calculator',
      subtitle: 'Max power current',
      icon: LucideIcons.activity,
      category: ScreenCategory.calculators,
      searchTags: ['imp', 'max', 'power', 'current', 'solar'],
      builder: () => const ImpCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'temp_coefficient',
      name: 'Temp Coefficient',
      subtitle: 'Voltage correction',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['temp', 'coefficient', 'temperature', 'correction', 'solar'],
      builder: () => const TempCoefficientScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'max_system_voltage',
      name: 'Max System Voltage',
      subtitle: 'NEC 690.7 compliance',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['max', 'system', 'voltage', 'nec', '690', 'solar'],
      builder: () => const MaxSystemVoltageScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'mppt_window',
      name: 'MPPT Window',
      subtitle: 'Inverter compatibility',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['mppt', 'window', 'inverter', 'range', 'solar'],
      builder: () => const MpptWindowScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'string_combiner',
      name: 'String Combiner',
      subtitle: 'Parallel string fusing',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['string', 'combiner', 'parallel', 'fuse', 'solar'],
      builder: () => const StringCombinerScreen(),
      trade: 'solar',
    ),
    // Inverter Sizing
    ScreenEntry(
      id: 'central_inverter',
      name: 'Central Inverter',
      subtitle: 'kW AC output sizing',
      icon: LucideIcons.server,
      category: ScreenCategory.calculators,
      searchTags: ['central', 'inverter', 'string', 'sizing', 'solar'],
      builder: () => const CentralInverterScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'microinverter',
      name: 'Microinverter',
      subtitle: 'Per-module sizing',
      icon: LucideIcons.cpu,
      category: ScreenCategory.calculators,
      searchTags: ['microinverter', 'mlpe', 'enphase', 'solar'],
      builder: () => const MicroinverterScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'clipping_analysis',
      name: 'Clipping Analysis',
      subtitle: 'DC vs AC energy loss',
      icon: LucideIcons.scissors,
      category: ScreenCategory.calculators,
      searchTags: ['clipping', 'analysis', 'dc', 'ac', 'ratio', 'solar'],
      builder: () => const ClippingAnalysisScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'inverter_efficiency',
      name: 'Inverter Efficiency',
      subtitle: 'CEC weighted efficiency',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['inverter', 'efficiency', 'cec', 'weighted', 'solar'],
      builder: () => const InverterEfficiencyScreen(),
      trade: 'solar',
    ),
    // Financial
    ScreenEntry(
      id: 'simple_payback',
      name: 'Simple Payback',
      subtitle: 'Years to recover investment',
      icon: LucideIcons.calendarClock,
      category: ScreenCategory.calculators,
      searchTags: ['simple', 'payback', 'roi', 'years', 'solar'],
      builder: () => const SimplePaybackScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'federal_itc',
      name: 'Federal ITC',
      subtitle: 'Tax credit calculator',
      icon: LucideIcons.landmark,
      category: ScreenCategory.calculators,
      searchTags: ['federal', 'itc', 'tax', 'credit', 'solar'],
      builder: () => const FederalItcScreen(),
      trade: 'solar',
    ),
    // Battery Storage
    ScreenEntry(
      id: 'battery_size',
      name: 'Battery Size',
      subtitle: 'kWh storage needed',
      icon: LucideIcons.battery,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'size', 'storage', 'kwh', 'backup', 'solar'],
      builder: () => const BatterySizeScreen(),
      trade: 'solar',
    ),
    // Financial (continued)
    ScreenEntry(
      id: 'irr_calculator',
      name: 'IRR Calculator',
      subtitle: 'Internal rate of return',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['irr', 'internal', 'rate', 'return', 'investment', 'solar'],
      builder: () => const IrrCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'cash_flow_projector',
      name: 'Cash Flow Projector',
      subtitle: 'Year-by-year financial analysis',
      icon: LucideIcons.barChart3,
      category: ScreenCategory.calculators,
      searchTags: ['cash', 'flow', 'projector', 'year', 'financial', 'solar'],
      builder: () => const CashFlowProjectorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'state_incentive_lookup',
      name: 'State Incentives',
      subtitle: 'State-by-state incentive database',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['state', 'incentive', 'rebate', 'credit', 'solar'],
      builder: () => const StateIncentiveLookupScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'srec_value_calculator',
      name: 'SREC Value',
      subtitle: 'Solar renewable energy credits',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['srec', 'renewable', 'energy', 'credit', 'value', 'solar'],
      builder: () => const SrecValueCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'tou_rate_optimizer',
      name: 'TOU Rate Optimizer',
      subtitle: 'Time-of-use rate analysis',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['tou', 'time', 'use', 'rate', 'peak', 'solar'],
      builder: () => const TouRateOptimizerScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'demand_charge_reducer',
      name: 'Demand Charge Reducer',
      subtitle: 'Peak demand reduction analysis',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['demand', 'charge', 'peak', 'reduction', 'solar'],
      builder: () => const DemandChargeReducerScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'lease_vs_ppa',
      name: 'Lease vs PPA',
      subtitle: 'Compare financing options',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['lease', 'ppa', 'power', 'purchase', 'agreement', 'solar'],
      builder: () => const LeaseVsPpaScreen(),
      trade: 'solar',
    ),
    // Mounting & Structural
    ScreenEntry(
      id: 'roof_load_calculator',
      name: 'Roof Load',
      subtitle: 'Structural load analysis',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'load', 'structural', 'weight', 'solar'],
      builder: () => const RoofLoadCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'wind_load_calculator',
      name: 'Wind Load',
      subtitle: 'ASCE 7 wind pressure',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['wind', 'load', 'asce', 'pressure', 'uplift', 'solar'],
      builder: () => const WindLoadCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'snow_load_calculator',
      name: 'Snow Load',
      subtitle: 'ASCE 7 snow load analysis',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['snow', 'load', 'asce', 'ground', 'roof', 'solar'],
      builder: () => const SnowLoadCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'attachment_spacing',
      name: 'Attachment Spacing',
      subtitle: 'Roof attachment layout',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['attachment', 'spacing', 'roof', 'lag', 'bolt', 'solar'],
      builder: () => const AttachmentSpacingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'rail_span_calculator',
      name: 'Rail Span',
      subtitle: 'Maximum rail span calculation',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['rail', 'span', 'maximum', 'deflection', 'solar'],
      builder: () => const RailSpanCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ground_mount_foundation',
      name: 'Ground Mount Foundation',
      subtitle: 'Foundation sizing for ground mounts',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['ground', 'mount', 'foundation', 'pier', 'post', 'solar'],
      builder: () => const GroundMountFoundationScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ballasted_system_weight',
      name: 'Ballasted System Weight',
      subtitle: 'Flat roof ballast requirements',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['ballasted', 'flat', 'roof', 'weight', 'ballast', 'solar'],
      builder: () => const BallastedSystemWeightScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'carport_sizing',
      name: 'Carport Sizing',
      subtitle: 'Solar carport design',
      icon: LucideIcons.car,
      category: ScreenCategory.calculators,
      searchTags: ['carport', 'sizing', 'parking', 'canopy', 'solar'],
      builder: () => const CarportSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'tracker_roi',
      name: 'Tracker ROI',
      subtitle: 'Single vs dual axis tracker analysis',
      icon: LucideIcons.rotateCw,
      category: ScreenCategory.calculators,
      searchTags: ['tracker', 'roi', 'single', 'dual', 'axis', 'solar'],
      builder: () => const TrackerRoiScreen(),
      trade: 'solar',
    ),
    // Code Compliance
    ScreenEntry(
      id: 'fire_setback',
      name: 'Fire Setback',
      subtitle: 'IFC fire access requirements',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'setback', 'ifc', 'access', 'pathway', 'solar'],
      builder: () => const FireSetbackScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'roof_access_pathways',
      name: 'Roof Access Pathways',
      subtitle: 'Fire department pathway design',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'access', 'pathway', 'fire', 'department', 'solar'],
      builder: () => const RoofAccessPathwaysScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ventilation_setbacks',
      name: 'Ventilation Setbacks',
      subtitle: 'HVAC and vent clearances',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['ventilation', 'setback', 'hvac', 'vent', 'clearance', 'solar'],
      builder: () => const VentilationSetbacksScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'interconnection_calculator',
      name: 'Interconnection',
      subtitle: 'NEC 705.12 compliance',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['interconnection', 'nec', '705', 'grid', '120', 'solar'],
      builder: () => const InterconnectionCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'main_panel_evaluation',
      name: 'Panel Evaluation',
      subtitle: 'Panel upgrade assessment',
      icon: LucideIcons.clipboardCheck,
      category: ScreenCategory.calculators,
      searchTags: ['panel', 'evaluation', 'upgrade', 'main', 'breaker', 'solar'],
      builder: () => const MainPanelEvaluationScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'load_side_supply_side',
      name: 'Load vs Supply Side',
      subtitle: 'Connection method selector',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['load', 'supply', 'side', 'tap', 'connection', 'solar'],
      builder: () => const LoadSideSupplySideScreen(),
      trade: 'solar',
    ),
    // Inverter Sizing (continued)
    ScreenEntry(
      id: 'string_inverter_match',
      name: 'String Inverter Match',
      subtitle: 'String-to-inverter compatibility',
      icon: LucideIcons.gitMerge,
      category: ScreenCategory.calculators,
      searchTags: ['string', 'inverter', 'match', 'compatibility', 'solar'],
      builder: () => const StringInverterMatchScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'power_optimizer_match',
      name: 'Power Optimizer Match',
      subtitle: 'Optimizer-to-inverter pairing',
      icon: LucideIcons.cpu,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'optimizer', 'match', 'solaredge', 'solar'],
      builder: () => const PowerOptimizerMatchScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'derating_factors',
      name: 'Derating Factors',
      subtitle: 'Temperature and soiling derates',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['derating', 'factors', 'temperature', 'soiling', 'solar'],
      builder: () => const DeratingFactorsScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'three_phase_balance',
      name: 'Three Phase Balance',
      subtitle: '3-phase load balancing',
      icon: LucideIcons.share2,
      category: ScreenCategory.calculators,
      searchTags: ['three', 'phase', 'balance', '3-phase', 'solar'],
      builder: () => const ThreePhaseBalanceScreen(),
      trade: 'solar',
    ),
    // Wiring & Conductors
    ScreenEntry(
      id: 'dc_wire_sizing',
      name: 'DC Wire Sizing',
      subtitle: 'PV string wire selection',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['dc', 'wire', 'sizing', 'string', 'conductor', 'solar'],
      builder: () => const DcWireSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ac_wire_sizing',
      name: 'AC Wire Sizing',
      subtitle: 'Inverter output wire selection',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'wire', 'sizing', 'inverter', 'conductor', 'solar'],
      builder: () => const AcWireSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'dc_voltage_drop',
      name: 'DC Voltage Drop',
      subtitle: 'String circuit voltage loss',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['dc', 'voltage', 'drop', 'loss', 'string', 'solar'],
      builder: () => const DcVoltageDropScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ac_voltage_drop',
      name: 'AC Voltage Drop',
      subtitle: 'AC circuit voltage loss',
      icon: LucideIcons.trendingDown,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'voltage', 'drop', 'loss', 'inverter', 'solar'],
      builder: () => const AcVoltageDropScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'conduit_fill_solar',
      name: 'Solar Conduit Fill',
      subtitle: 'PV wire conduit sizing',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['conduit', 'fill', 'solar', 'wire', 'emt', 'pvc'],
      builder: () => const ConduitFillSolarScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'home_run_length',
      name: 'Home Run Length',
      subtitle: 'Wire run distance calculator',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['home', 'run', 'length', 'distance', 'wire', 'solar'],
      builder: () => const HomeRunLengthScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'wire_type_selection',
      name: 'Wire Type Selection',
      subtitle: 'USE-2, PV Wire, THWN-2',
      icon: LucideIcons.list,
      category: ScreenCategory.calculators,
      searchTags: ['wire', 'type', 'selection', 'use2', 'pv', 'thwn', 'solar'],
      builder: () => const WireTypeSelectionScreen(),
      trade: 'solar',
    ),
    // Disconnects & Protection
    ScreenEntry(
      id: 'dc_disconnect_sizing',
      name: 'DC Disconnect Sizing',
      subtitle: 'PV disconnect requirements',
      icon: LucideIcons.toggleLeft,
      category: ScreenCategory.calculators,
      searchTags: ['dc', 'disconnect', 'sizing', 'pv', 'switch', 'solar'],
      builder: () => const DcDisconnectSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ac_disconnect_sizing',
      name: 'AC Disconnect Sizing',
      subtitle: 'Inverter disconnect requirements',
      icon: LucideIcons.toggleRight,
      category: ScreenCategory.calculators,
      searchTags: ['ac', 'disconnect', 'sizing', 'inverter', 'switch', 'solar'],
      builder: () => const AcDisconnectSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ocpd_dc',
      name: 'DC OCPD',
      subtitle: 'DC overcurrent protection',
      icon: LucideIcons.shieldAlert,
      category: ScreenCategory.calculators,
      searchTags: ['ocpd', 'dc', 'overcurrent', 'protection', 'fuse', 'solar'],
      builder: () => const OcpdDcScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ocpd_ac',
      name: 'AC OCPD',
      subtitle: 'AC overcurrent protection',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.calculators,
      searchTags: ['ocpd', 'ac', 'overcurrent', 'protection', 'breaker', 'solar'],
      builder: () => const OcpdAcScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'rapid_shutdown',
      name: 'Rapid Shutdown',
      subtitle: 'NEC 690.12 compliance',
      icon: LucideIcons.powerOff,
      category: ScreenCategory.calculators,
      searchTags: ['rapid', 'shutdown', 'nec', '690', 'module', 'solar'],
      builder: () => const RapidShutdownScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'ground_fault_protection',
      name: 'Ground Fault Protection',
      subtitle: 'GFP requirements',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['ground', 'fault', 'protection', 'gfp', 'gfdi', 'solar'],
      builder: () => const GroundFaultProtectionScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'arc_fault_detection',
      name: 'Arc Fault Detection',
      subtitle: 'AFCI requirements for PV',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['arc', 'fault', 'detection', 'afci', 'afdi', 'solar'],
      builder: () => const ArcFaultDetectionScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'grounding_electrode_solar',
      name: 'Grounding Electrode',
      subtitle: 'Array grounding requirements',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['grounding', 'electrode', 'array', 'rod', 'solar'],
      builder: () => const solar_grounding.GroundingElectrodeScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'equipment_grounding',
      name: 'Equipment Grounding',
      subtitle: 'EGC sizing for solar',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['equipment', 'grounding', 'egc', 'conductor', 'solar'],
      builder: () => const EquipmentGroundingScreen(),
      trade: 'solar',
    ),
    // Battery Storage (continued)
    ScreenEntry(
      id: 'backup_duration',
      name: 'Backup Duration',
      subtitle: 'Hours of backup power',
      icon: LucideIcons.timer,
      category: ScreenCategory.calculators,
      searchTags: ['backup', 'duration', 'hours', 'outage', 'solar'],
      builder: () => const BackupDurationScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'critical_load',
      name: 'Critical Load',
      subtitle: 'Essential load calculation',
      icon: LucideIcons.alertCircle,
      category: ScreenCategory.calculators,
      searchTags: ['critical', 'load', 'essential', 'backup', 'solar'],
      builder: () => const CriticalLoadScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'depth_of_discharge',
      name: 'Depth of Discharge',
      subtitle: 'DoD optimization',
      icon: LucideIcons.batteryLow,
      category: ScreenCategory.calculators,
      searchTags: ['depth', 'discharge', 'dod', 'battery', 'solar'],
      builder: () => const DepthOfDischargeScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'cycle_life_estimator',
      name: 'Cycle Life Estimator',
      subtitle: 'Battery lifespan prediction',
      icon: LucideIcons.repeat,
      category: ScreenCategory.calculators,
      searchTags: ['cycle', 'life', 'estimator', 'battery', 'warranty', 'solar'],
      builder: () => const CycleLifeEstimatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'round_trip_efficiency',
      name: 'Round Trip Efficiency',
      subtitle: 'Battery charge/discharge losses',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['round', 'trip', 'efficiency', 'battery', 'loss', 'solar'],
      builder: () => const RoundTripEfficiencyScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'battery_inverter_sizing',
      name: 'Battery Inverter Sizing',
      subtitle: 'Hybrid/battery inverter selection',
      icon: LucideIcons.server,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'inverter', 'sizing', 'hybrid', 'solar'],
      builder: () => const BatteryInverterSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'charge_controller_sizing',
      name: 'Charge Controller Sizing',
      subtitle: 'MPPT/PWM controller selection',
      icon: LucideIcons.sliders,
      category: ScreenCategory.calculators,
      searchTags: ['charge', 'controller', 'sizing', 'mppt', 'pwm', 'solar'],
      builder: () => const ChargeControllerSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'battery_bank',
      name: 'Battery Bank',
      subtitle: 'Series/parallel battery config',
      icon: LucideIcons.batteryCharging,
      category: ScreenCategory.calculators,
      searchTags: ['battery', 'bank', 'series', 'parallel', 'configuration', 'solar'],
      builder: () => const solar_battery_bank.BatteryBankScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'generator_battery',
      name: 'Generator + Battery',
      subtitle: 'Hybrid backup sizing',
      icon: LucideIcons.combine,
      category: ScreenCategory.calculators,
      searchTags: ['generator', 'battery', 'hybrid', 'backup', 'solar'],
      builder: () => const GeneratorBatteryScreen(),
      trade: 'solar',
    ),
    // Financial (more)
    ScreenEntry(
      id: 'roi_calculator',
      name: 'ROI Calculator',
      subtitle: 'Return on investment',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['roi', 'return', 'investment', 'payback', 'solar'],
      builder: () => const RoiCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'npv_calculator',
      name: 'NPV Calculator',
      subtitle: 'Net present value',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['npv', 'net', 'present', 'value', 'discount', 'solar'],
      builder: () => const NpvCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'lcoe_calculator',
      name: 'LCOE Calculator',
      subtitle: 'Levelized cost of energy',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['lcoe', 'levelized', 'cost', 'energy', 'solar'],
      builder: () => const LcoeCalculatorScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'utility_bill_savings',
      name: 'Utility Bill Savings',
      subtitle: 'Monthly savings estimate',
      icon: LucideIcons.piggyBank,
      category: ScreenCategory.calculators,
      searchTags: ['utility', 'bill', 'savings', 'monthly', 'solar'],
      builder: () => const UtilityBillSavingsScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'net_metering',
      name: 'Net Metering',
      subtitle: 'Net metering value analysis',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['net', 'metering', 'value', 'export', 'grid', 'solar'],
      builder: () => const NetMeteringScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'loan_vs_cash',
      name: 'Loan vs Cash',
      subtitle: 'Finance vs purchase comparison',
      icon: LucideIcons.creditCard,
      category: ScreenCategory.calculators,
      searchTags: ['loan', 'cash', 'finance', 'purchase', 'comparison', 'solar'],
      builder: () => const LoanVsCashScreen(),
      trade: 'solar',
    ),
  ];

  // =========================================================================
  // ROOFING CALCULATORS (80)
  // =========================================================================
  static final List<ScreenEntry> roofingCalculators = [
    ScreenEntry(
      id: 'roof_squares',
      name: 'Roof Squares',
      subtitle: 'Calculate roofing squares',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'squares', 'area', 'shingles'],
      builder: () => const RoofSquaresScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'pitch_factor',
      name: 'Pitch Factor',
      subtitle: 'Roof pitch multiplier',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['pitch', 'factor', 'slope', 'multiplier'],
      builder: () => const PitchFactorScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_area',
      name: 'Roof Area',
      subtitle: 'Total roof surface area',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'area', 'surface', 'sqft'],
      builder: () => const roofing_roof_area.RoofAreaScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'hip_roof',
      name: 'Hip Roof',
      subtitle: 'Hip roof area calculation',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['hip', 'roof', 'area', 'pyramid'],
      builder: () => const HipRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gable_roof',
      name: 'Gable Roof',
      subtitle: 'Gable roof area calculation',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['gable', 'roof', 'area', 'peak'],
      builder: () => const GableRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'mansard_roof',
      name: 'Mansard Roof',
      subtitle: 'Mansard roof calculation',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['mansard', 'roof', 'french', 'double'],
      builder: () => const MansardRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gambrel_roof',
      name: 'Gambrel Roof',
      subtitle: 'Barn-style roof calculation',
      icon: LucideIcons.warehouse,
      category: ScreenCategory.calculators,
      searchTags: ['gambrel', 'roof', 'barn', 'dutch'],
      builder: () => const GambrelRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'dutch_hip',
      name: 'Dutch Hip',
      subtitle: 'Dutch hip roof calculation',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['dutch', 'hip', 'roof', 'gable'],
      builder: () => const DutchHipScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'shed_roof',
      name: 'Shed Roof',
      subtitle: 'Single slope roof calculation',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['shed', 'roof', 'slope', 'lean-to'],
      builder: () => const ShedRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'flat_roof',
      name: 'Flat Roof',
      subtitle: 'Low-slope roof calculation',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['flat', 'roof', 'low', 'slope'],
      builder: () => const FlatRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'dormer_area',
      name: 'Dormer Area',
      subtitle: 'Calculate dormer roof area',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['dormer', 'area', 'window', 'roof'],
      builder: () => const DormerAreaScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'valley_length',
      name: 'Valley Length',
      subtitle: 'Calculate valley flashing',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['valley', 'length', 'flashing', 'intersection'],
      builder: () => const ValleyLengthScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'shingle_calculator',
      name: 'Shingle Calculator',
      subtitle: 'Calculate shingle bundles',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['shingle', 'bundles', 'asphalt', 'material'],
      builder: () => const ShingleCalculatorScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'metal_roofing',
      name: 'Metal Roofing',
      subtitle: 'Metal panel calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['metal', 'roofing', 'panel', 'steel'],
      builder: () => const MetalRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'tile_roofing',
      name: 'Tile Roofing',
      subtitle: 'Clay/concrete tile calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['tile', 'roofing', 'clay', 'concrete'],
      builder: () => const TileRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'slate_roofing',
      name: 'Slate Roofing',
      subtitle: 'Natural slate calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['slate', 'roofing', 'natural', 'stone'],
      builder: () => const SlateRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'wood_shake',
      name: 'Wood Shake',
      subtitle: 'Cedar shake calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['wood', 'shake', 'cedar', 'shingle'],
      builder: () => const WoodShakeScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'rolled_roofing',
      name: 'Rolled Roofing',
      subtitle: 'Roll roofing calculator',
      icon: LucideIcons.scroll,
      category: ScreenCategory.calculators,
      searchTags: ['rolled', 'roofing', 'felt', 'mineral'],
      builder: () => const RolledRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'drip_edge',
      name: 'Drip Edge',
      subtitle: 'Calculate drip edge length',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['drip', 'edge', 'eave', 'rake'],
      builder: () => const DripEdgeScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'ridge_cap',
      name: 'Ridge Cap',
      subtitle: 'Ridge cap shingles needed',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['ridge', 'cap', 'shingles', 'hip'],
      builder: () => const RidgeCapScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'underlayment',
      name: 'Underlayment',
      subtitle: 'Calculate underlayment rolls',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['underlayment', 'felt', 'synthetic', 'paper'],
      builder: () => const UnderlaymentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'felt_underlayment',
      name: 'Felt Underlayment',
      subtitle: 'Felt paper calculator',
      icon: LucideIcons.scroll,
      category: ScreenCategory.calculators,
      searchTags: ['felt', 'underlayment', 'paper', '15lb', '30lb'],
      builder: () => const FeltUnderlaymentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'synthetic_underlayment',
      name: 'Synthetic Underlayment',
      subtitle: 'Synthetic underlayment calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['synthetic', 'underlayment', 'rolls'],
      builder: () => const SyntheticUnderlaymentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'ice_water_shield',
      name: 'Ice & Water Shield',
      subtitle: 'Ice barrier calculator',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['ice', 'water', 'shield', 'barrier', 'membrane'],
      builder: () => const IceWaterShieldScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'starter_strip',
      name: 'Starter Strip',
      subtitle: 'Starter shingle calculator',
      icon: LucideIcons.alignStartHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['starter', 'strip', 'shingle', 'eave'],
      builder: () => const StarterStripScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'flashing',
      name: 'Flashing',
      subtitle: 'General flashing calculator',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['flashing', 'metal', 'roof', 'waterproof'],
      builder: () => const FlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'step_flashing',
      name: 'Step Flashing',
      subtitle: 'Wall-to-roof step flashing',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['step', 'flashing', 'wall', 'sidewall'],
      builder: () => const StepFlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'counter_flashing',
      name: 'Counter Flashing',
      subtitle: 'Counter flashing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['counter', 'flashing', 'reglet', 'masonry'],
      builder: () => const CounterFlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'kick_out_flashing',
      name: 'Kick-Out Flashing',
      subtitle: 'Diverter flashing calculator',
      icon: LucideIcons.cornerDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['kick', 'out', 'flashing', 'diverter'],
      builder: () => const KickOutFlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'chimney_flashing',
      name: 'Chimney Flashing',
      subtitle: 'Chimney flashing kit',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['chimney', 'flashing', 'cricket', 'saddle'],
      builder: () => const ChimneyFlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'skylight_flashing',
      name: 'Skylight Flashing',
      subtitle: 'Skylight flashing kit',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['skylight', 'flashing', 'curb', 'deck'],
      builder: () => const SkylightFlashingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'pipe_boot',
      name: 'Pipe Boot',
      subtitle: 'Pipe boot/collar sizing',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['pipe', 'boot', 'collar', 'vent', 'flashing'],
      builder: () => const PipeBootScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_penetration',
      name: 'Roof Penetration',
      subtitle: 'Penetration sealing materials',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['penetration', 'seal', 'boot', 'flashing'],
      builder: () => const RoofPenetrationScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'attic_vent',
      name: 'Attic Vent',
      subtitle: 'Calculate attic ventilation',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['attic', 'vent', 'ventilation', 'nfa'],
      builder: () => const AtticVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'ridge_vent',
      name: 'Ridge Vent',
      subtitle: 'Ridge vent length needed',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['ridge', 'vent', 'exhaust', 'continuous'],
      builder: () => const RidgeVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'soffit_vent',
      name: 'Soffit Vent',
      subtitle: 'Soffit intake ventilation',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['soffit', 'vent', 'intake', 'eave'],
      builder: () => const SoffitVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_ventilator',
      name: 'Roof Ventilator',
      subtitle: 'Box vent calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'ventilator', 'box', 'vent', 'static'],
      builder: () => const RoofVentilatorScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gable_vent',
      name: 'Gable Vent',
      subtitle: 'Gable end vent sizing',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['gable', 'vent', 'louver', 'end'],
      builder: () => const GableVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'power_vent',
      name: 'Power Vent',
      subtitle: 'Powered attic ventilator',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['power', 'vent', 'attic', 'fan', 'pav'],
      builder: () => const PowerVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'turbine_vent',
      name: 'Turbine Vent',
      subtitle: 'Whirlybird vent sizing',
      icon: LucideIcons.rotateCw,
      category: ScreenCategory.calculators,
      searchTags: ['turbine', 'vent', 'whirlybird', 'spinning'],
      builder: () => const TurbineVentScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gutter_size',
      name: 'Gutter Size',
      subtitle: 'Gutter sizing for roof',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['gutter', 'size', 'downspout', 'drainage'],
      builder: () => const GutterSizeScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gutter_slope',
      name: 'Gutter Slope',
      subtitle: 'Gutter pitch calculator',
      icon: LucideIcons.arrowRight,
      category: ScreenCategory.calculators,
      searchTags: ['gutter', 'slope', 'pitch', 'fall'],
      builder: () => const GutterSlopeScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gutter_hanger',
      name: 'Gutter Hanger',
      subtitle: 'Hanger spacing calculator',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['gutter', 'hanger', 'bracket', 'spacing'],
      builder: () => const GutterHangerScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'downspout',
      name: 'Downspout',
      subtitle: 'Downspout sizing & count',
      icon: LucideIcons.arrowDownToLine,
      category: ScreenCategory.calculators,
      searchTags: ['downspout', 'leader', 'drainage', 'sizing'],
      builder: () => const DownspoutScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'splash_block',
      name: 'Splash Block',
      subtitle: 'Splash block requirements',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['splash', 'block', 'downspout', 'drainage'],
      builder: () => const SplashBlockScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_load',
      name: 'Roof Load',
      subtitle: 'Dead & live load calculation',
      icon: LucideIcons.scale,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'load', 'dead', 'live', 'psf'],
      builder: () => const RoofLoadScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'snow_load',
      name: 'Snow Load',
      subtitle: 'Snow load calculation',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['snow', 'load', 'ground', 'roof', 'psf'],
      builder: () => const SnowLoadScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'wind_uplift',
      name: 'Wind Uplift',
      subtitle: 'Wind uplift pressure',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['wind', 'uplift', 'pressure', 'zone'],
      builder: () => const WindUpliftScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'rafter_length',
      name: 'Rafter Length',
      subtitle: 'Rafter length calculator',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['rafter', 'length', 'span', 'run'],
      builder: () => const RafterLengthScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_truss',
      name: 'Roof Truss',
      subtitle: 'Truss count & spacing',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['truss', 'roof', 'spacing', 'count'],
      builder: () => const RoofTrussScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'collar_tie',
      name: 'Collar Tie',
      subtitle: 'Collar tie sizing',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['collar', 'tie', 'rafter', 'brace'],
      builder: () => const CollarTieScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'purlin_spacing',
      name: 'Purlin Spacing',
      subtitle: 'Metal roof purlin layout',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['purlin', 'spacing', 'metal', 'roof'],
      builder: () => const PurlinSpacingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'plywood_deck',
      name: 'Plywood Deck',
      subtitle: 'Roof sheathing calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['plywood', 'deck', 'sheathing', 'osb'],
      builder: () => const PlywoodDeckScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'fascia_board',
      name: 'Fascia Board',
      subtitle: 'Fascia & trim calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['fascia', 'board', 'trim', 'eave'],
      builder: () => const FasciaBoardScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'epdm_membrane',
      name: 'EPDM Membrane',
      subtitle: 'Rubber roofing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['epdm', 'membrane', 'rubber', 'flat'],
      builder: () => const EpdmMembraneScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'tpo_membrane',
      name: 'TPO Membrane',
      subtitle: 'TPO roofing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['tpo', 'membrane', 'single', 'ply'],
      builder: () => const TpoMembraneScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'pvc_membrane',
      name: 'PVC Membrane',
      subtitle: 'PVC roofing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['pvc', 'membrane', 'vinyl', 'flat'],
      builder: () => const PvcMembraneScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'modified_bitumen',
      name: 'Modified Bitumen',
      subtitle: 'Mod-bit roofing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['modified', 'bitumen', 'mod-bit', 'torch'],
      builder: () => const ModifiedBitumenScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'built_up_roof',
      name: 'Built-Up Roof',
      subtitle: 'BUR roofing calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['built', 'up', 'bur', 'tar', 'gravel'],
      builder: () => const BuiltUpRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_coating',
      name: 'Roof Coating',
      subtitle: 'Coating coverage calculator',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'coating', 'sealant', 'elastomeric'],
      builder: () => const RoofCoatingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'cool_roof',
      name: 'Cool Roof',
      subtitle: 'Reflective roofing savings',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['cool', 'roof', 'reflective', 'energy'],
      builder: () => const CoolRoofScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'ice_dam',
      name: 'Ice Dam',
      subtitle: 'Ice dam prevention',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['ice', 'dam', 'prevention', 'heat', 'cable'],
      builder: () => const IceDamScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'heat_cable',
      name: 'Heat Cable',
      subtitle: 'De-icing heat cable length',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['heat', 'cable', 'de-icing', 'roof', 'gutter'],
      builder: () => const HeatCableScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_cricket',
      name: 'Roof Cricket',
      subtitle: 'Cricket/saddle sizing',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['cricket', 'saddle', 'chimney', 'diverter'],
      builder: () => const RoofCricketScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'scupper',
      name: 'Scupper',
      subtitle: 'Flat roof scupper sizing',
      icon: LucideIcons.arrowRightFromLine,
      category: ScreenCategory.calculators,
      searchTags: ['scupper', 'drain', 'parapet', 'overflow'],
      builder: () => const ScupperScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_drain',
      name: 'Roof Drain',
      subtitle: 'Interior drain sizing',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'drain', 'interior', 'flat'],
      builder: () => const RoofDrainScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'tapered_insulation',
      name: 'Tapered Insulation',
      subtitle: 'Tapered system layout',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['tapered', 'insulation', 'slope', 'drain'],
      builder: () => const TaperedInsulationScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'parapet_cap',
      name: 'Parapet Cap',
      subtitle: 'Parapet coping calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['parapet', 'cap', 'coping', 'wall'],
      builder: () => const ParapetCapScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'standing_seam',
      name: 'Standing Seam',
      subtitle: 'Standing seam metal panels',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['standing', 'seam', 'metal', 'panel'],
      builder: () => const StandingSeamScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'corrugated_panel',
      name: 'Corrugated Panel',
      subtitle: 'Corrugated metal roofing',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['corrugated', 'panel', 'metal', 'wave'],
      builder: () => const CorrugatedPanelScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'r_panel',
      name: 'R-Panel',
      subtitle: 'R-panel metal roofing',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['r-panel', 'metal', 'panel', 'pbr'],
      builder: () => const RPanelScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'bird_stop',
      name: 'Bird Stop',
      subtitle: 'Tile roof bird stop',
      icon: LucideIcons.bird,
      category: ScreenCategory.calculators,
      searchTags: ['bird', 'stop', 'tile', 'eave', 'closure'],
      builder: () => const BirdStopScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'slope_conversion',
      name: 'Slope Conversion',
      subtitle: 'Pitch to degree converter',
      icon: LucideIcons.arrowLeftRight,
      category: ScreenCategory.calculators,
      searchTags: ['slope', 'conversion', 'pitch', 'degree'],
      builder: () => const SlopeConversionScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'waste_factor',
      name: 'Waste Factor',
      subtitle: 'Material waste calculator',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['waste', 'factor', 'overage', 'material'],
      builder: () => const WasteFactorScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'nail_quantity',
      name: 'Nail Quantity',
      subtitle: 'Roofing nails needed',
      icon: LucideIcons.pin,
      category: ScreenCategory.calculators,
      searchTags: ['nail', 'quantity', 'fastener', 'coil'],
      builder: () => const NailQuantityScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'material_cost',
      name: 'Material Cost',
      subtitle: 'Roofing material estimator',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['material', 'cost', 'price', 'estimate'],
      builder: () => const MaterialCostScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'labor_hours',
      name: 'Labor Hours',
      subtitle: 'Roofing labor estimate',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['labor', 'hours', 'time', 'crew'],
      builder: () => const LaborHoursScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'tear_off_weight',
      name: 'Tear-Off Weight',
      subtitle: 'Tear-off disposal weight',
      icon: LucideIcons.trash2,
      category: ScreenCategory.calculators,
      searchTags: ['tear', 'off', 'weight', 'disposal', 'dumpster'],
      builder: () => const TearOffWeightScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'disposal_cost',
      name: 'Disposal Cost',
      subtitle: 'Dumpster & disposal costs',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['disposal', 'cost', 'dumpster', 'landfill'],
      builder: () => const DisposalCostScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'total_job_cost',
      name: 'Total Job Cost',
      subtitle: 'Complete job estimator',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['total', 'job', 'cost', 'estimate', 'bid'],
      builder: () => const TotalJobCostScreen(),
      trade: 'roofing',
    ),
  ];

  // =========================================================================
  // GC CALCULATORS (101)
  // =========================================================================
  static final List<ScreenEntry> gcCalculators = [
    ScreenEntry(
      id: 'gc_anchor_bolt',
      name: 'Anchor Bolt',
      subtitle: 'Anchor bolt spacing and sizing',
      icon: LucideIcons.anchor,
      category: ScreenCategory.calculators,
      searchTags: ['anchor', 'bolt', 'concrete', 'fastener', 'embed'],
      builder: () => const AnchorBoltScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_attic_insulation',
      name: 'Attic Insulation',
      subtitle: 'Attic insulation coverage calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['attic', 'insulation', 'r-value', 'coverage', 'fiberglass'],
      builder: () => const gc_attic_insulation.AtticInsulationScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_batt_insulation',
      name: 'Batt Insulation',
      subtitle: 'Batt insulation quantity calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['batt', 'insulation', 'fiberglass', 'r-value', 'wall'],
      builder: () => const BattInsulationScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_beam_span',
      name: 'Beam Span',
      subtitle: 'Calculate beam span and sizing',
      icon: LucideIcons.move,
      category: ScreenCategory.calculators,
      searchTags: ['beam', 'span', 'load', 'structural', 'lumber'],
      builder: () => const BeamSpanScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_blocking',
      name: 'Blocking Calculator',
      subtitle: 'Calculate blocking requirements',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['blocking', 'framing', 'joist', 'support', 'lumber'],
      builder: () => const BlockingCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_blown_insulation',
      name: 'Blown Insulation',
      subtitle: 'Blown-in insulation coverage',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['blown', 'insulation', 'cellulose', 'r-value', 'attic'],
      builder: () => const BlownInsulationScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_board_feet',
      name: 'Board Feet',
      subtitle: 'Calculate lumber board feet',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['board', 'feet', 'lumber', 'wood', 'quantity'],
      builder: () => const BoardFeetScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_caulking',
      name: 'Caulking',
      subtitle: 'Caulk tube quantity calculator',
      icon: LucideIcons.penTool,
      category: ScreenCategory.calculators,
      searchTags: ['caulk', 'caulking', 'sealant', 'tube', 'joint'],
      builder: () => const CaulkingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_ceiling_joist',
      name: 'Ceiling Joist',
      subtitle: 'Ceiling joist spacing and sizing',
      icon: LucideIcons.alignHorizontalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['ceiling', 'joist', 'span', 'spacing', 'framing'],
      builder: () => const CeilingJoistScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_change_order',
      name: 'Change Order',
      subtitle: 'Calculate change order costs',
      icon: LucideIcons.fileEdit,
      category: ScreenCategory.calculators,
      searchTags: ['change', 'order', 'cost', 'markup', 'contract'],
      builder: () => const ChangeOrderScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_co_detector',
      name: 'CO Detector',
      subtitle: 'CO detector placement calculator',
      icon: LucideIcons.alertCircle,
      category: ScreenCategory.calculators,
      searchTags: ['co', 'carbon', 'monoxide', 'detector', 'safety'],
      builder: () => const CoDetectorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_collar_tie',
      name: 'Collar Tie',
      subtitle: 'Collar tie sizing and spacing',
      icon: LucideIcons.link,
      category: ScreenCategory.calculators,
      searchTags: ['collar', 'tie', 'rafter', 'roof', 'framing'],
      builder: () => const CollarTieCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_compaction_factor',
      name: 'Compaction Factor',
      subtitle: 'Soil compaction factor calculator',
      icon: LucideIcons.arrowDownCircle,
      category: ScreenCategory.calculators,
      searchTags: ['compaction', 'factor', 'soil', 'fill', 'density'],
      builder: () => const CompactionFactorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_compaction',
      name: 'Compaction',
      subtitle: 'Calculate soil compaction requirements',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['compaction', 'soil', 'fill', 'grading', 'density'],
      builder: () => const CompactionScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_concrete_mix',
      name: 'Concrete Mix',
      subtitle: 'Concrete mix ratios calculator',
      icon: LucideIcons.beaker,
      category: ScreenCategory.calculators,
      searchTags: ['concrete', 'mix', 'ratio', 'cement', 'aggregate'],
      builder: () => const ConcreteMixScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_concrete_volume',
      name: 'Concrete Volume',
      subtitle: 'Calculate concrete yard volume',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['concrete', 'volume', 'yard', 'cubic', 'slab'],
      builder: () => const ConcreteVolumeScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_crew_size',
      name: 'Crew Size',
      subtitle: 'Optimal crew size calculator',
      icon: LucideIcons.users,
      category: ScreenCategory.calculators,
      searchTags: ['crew', 'size', 'labor', 'workers', 'productivity'],
      builder: () => const CrewSizeScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_cripple_stud',
      name: 'Cripple Stud',
      subtitle: 'Cripple stud calculations',
      icon: LucideIcons.arrowUpDown,
      category: ScreenCategory.calculators,
      searchTags: ['cripple', 'stud', 'framing', 'window', 'header'],
      builder: () => const CrippleStudScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_critical_path',
      name: 'Critical Path',
      subtitle: 'Project critical path analysis',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.calculators,
      searchTags: ['critical', 'path', 'schedule', 'project', 'timeline'],
      builder: () => const CriticalPathScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_cure_time',
      name: 'Cure Time',
      subtitle: 'Concrete cure time calculator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['cure', 'time', 'concrete', 'strength', 'days'],
      builder: () => const CureTimeScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_deck_footing',
      name: 'Deck Footing',
      subtitle: 'Deck footing size calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'footing', 'pier', 'concrete', 'load'],
      builder: () => const DeckFootingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_deck_joist',
      name: 'Deck Joist',
      subtitle: 'Deck joist spacing calculator',
      icon: LucideIcons.alignHorizontalDistributeCenter,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'joist', 'spacing', 'span', 'framing'],
      builder: () => const DeckJoistScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_deck_post',
      name: 'Deck Post',
      subtitle: 'Deck post sizing calculator',
      icon: LucideIcons.pilcrow,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'post', 'sizing', 'load', 'support'],
      builder: () => const DeckPostScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_decking',
      name: 'Decking',
      subtitle: 'Deck board quantity calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'decking', 'board', 'composite', 'lumber'],
      builder: () => const DeckingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_demo_waste',
      name: 'Demo Waste',
      subtitle: 'Demolition waste estimator',
      icon: LucideIcons.trash,
      category: ScreenCategory.calculators,
      searchTags: ['demo', 'demolition', 'waste', 'dumpster', 'debris'],
      builder: () => const DemoWasteScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_door_schedule',
      name: 'Door Schedule',
      subtitle: 'Door schedule calculator',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['door', 'schedule', 'opening', 'frame', 'hardware'],
      builder: () => const DoorScheduleScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_dumpster_sizing',
      name: 'Dumpster Sizing',
      subtitle: 'Dumpster size calculator',
      icon: LucideIcons.container,
      category: ScreenCategory.calculators,
      searchTags: ['dumpster', 'sizing', 'waste', 'yard', 'debris'],
      builder: () => const DumpsterSizingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_egress_path',
      name: 'Egress Path',
      subtitle: 'Egress path requirements',
      icon: LucideIcons.arrowRightCircle,
      category: ScreenCategory.calculators,
      searchTags: ['egress', 'path', 'exit', 'safety', 'code'],
      builder: () => const EgressPathScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_egress',
      name: 'Egress',
      subtitle: 'Egress window calculator',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['egress', 'window', 'opening', 'basement', 'code'],
      builder: () => const EgressScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_excavation_volume',
      name: 'Excavation Volume',
      subtitle: 'Excavation volume calculator',
      icon: LucideIcons.shovel,
      category: ScreenCategory.calculators,
      searchTags: ['excavation', 'volume', 'dig', 'cubic', 'yard'],
      builder: () => const ExcavationVolumeScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_exposed_aggregate',
      name: 'Exposed Aggregate',
      subtitle: 'Exposed aggregate concrete',
      icon: LucideIcons.hexagon,
      category: ScreenCategory.calculators,
      searchTags: ['exposed', 'aggregate', 'concrete', 'decorative', 'finish'],
      builder: () => const ExposedAggregateScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_fascia',
      name: 'Fascia',
      subtitle: 'Fascia board calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['fascia', 'board', 'trim', 'roofline', 'eave'],
      builder: () => const gc_fascia.FasciaScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_fiber_mesh',
      name: 'Fiber Mesh',
      subtitle: 'Fiber mesh concrete additive',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['fiber', 'mesh', 'concrete', 'reinforcement', 'additive'],
      builder: () => const FiberMeshScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_fill',
      name: 'Fill',
      subtitle: 'Fill material calculator',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['fill', 'dirt', 'gravel', 'material', 'volume'],
      builder: () => const FillScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_fire_extinguisher',
      name: 'Fire Extinguisher',
      subtitle: 'Fire extinguisher placement',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'extinguisher', 'safety', 'code', 'placement'],
      builder: () => const FireExtinguisherScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_flashing',
      name: 'Flashing',
      subtitle: 'Flashing material calculator',
      icon: LucideIcons.arrowDownRight,
      category: ScreenCategory.calculators,
      searchTags: ['flashing', 'metal', 'roof', 'wall', 'waterproofing'],
      builder: () => const gc_flashing.FlashingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_foam_board',
      name: 'Foam Board',
      subtitle: 'Foam board insulation calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['foam', 'board', 'insulation', 'rigid', 'r-value'],
      builder: () => const FoamBoardScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_footing',
      name: 'Footing Calculator',
      subtitle: 'Footing size and volume',
      icon: LucideIcons.boxes,
      category: ScreenCategory.calculators,
      searchTags: ['footing', 'foundation', 'concrete', 'size', 'load'],
      builder: () => const FootingCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_form_board',
      name: 'Form Board',
      subtitle: 'Concrete form board calculator',
      icon: LucideIcons.layoutTemplate,
      category: ScreenCategory.calculators,
      searchTags: ['form', 'board', 'concrete', 'lumber', 'forming'],
      builder: () => const FormBoardScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_foundation_wall',
      name: 'Foundation Wall',
      subtitle: 'Foundation wall calculator',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['foundation', 'wall', 'concrete', 'block', 'basement'],
      builder: () => const FoundationWallScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_french_drain',
      name: 'French Drain',
      subtitle: 'French drain material calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['french', 'drain', 'gravel', 'pipe', 'drainage'],
      builder: () => const gc_french_drain.FrenchDrainScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_glass_area',
      name: 'Glass Area',
      subtitle: 'Window glass area calculator',
      icon: LucideIcons.scan,
      category: ScreenCategory.calculators,
      searchTags: ['glass', 'area', 'window', 'glazing', 'square'],
      builder: () => const GlassAreaScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_grading',
      name: 'Grading',
      subtitle: 'Site grading calculator',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['grading', 'slope', 'site', 'drainage', 'elevation'],
      builder: () => const GradingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_gravel_base',
      name: 'Gravel Base',
      subtitle: 'Gravel base layer calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['gravel', 'base', 'aggregate', 'crushed', 'stone'],
      builder: () => const GravelBaseScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_guardrail',
      name: 'Guardrail',
      subtitle: 'Guardrail requirements calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['guardrail', 'railing', 'safety', 'code', 'deck'],
      builder: () => const GuardrailScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_gutter',
      name: 'Gutter',
      subtitle: 'Gutter sizing calculator',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['gutter', 'downspout', 'drainage', 'rain', 'sizing'],
      builder: () => const GutterScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_handrail',
      name: 'Handrail',
      subtitle: 'Handrail requirements calculator',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['handrail', 'stair', 'railing', 'code', 'grip'],
      builder: () => const HandrailScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_hauling',
      name: 'Hauling',
      subtitle: 'Material hauling calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['hauling', 'truck', 'load', 'trips', 'material'],
      builder: () => const HaulingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_hazmat',
      name: 'Hazmat',
      subtitle: 'Hazmat disposal calculator',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.calculators,
      searchTags: ['hazmat', 'hazardous', 'disposal', 'asbestos', 'lead'],
      builder: () => const HazmatScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_header_sizing',
      name: 'Header Sizing',
      subtitle: 'Header beam sizing calculator',
      icon: LucideIcons.alignHorizontalJustifyStart,
      category: ScreenCategory.calculators,
      searchTags: ['header', 'sizing', 'beam', 'span', 'load'],
      builder: () => const HeaderSizingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_house_wrap',
      name: 'House Wrap',
      subtitle: 'House wrap coverage calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['house', 'wrap', 'tyvek', 'vapor', 'barrier'],
      builder: () => const HouseWrapScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_i_joist',
      name: 'I-Joist',
      subtitle: 'I-joist sizing calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['i-joist', 'tji', 'engineered', 'floor', 'span'],
      builder: () => const IJoistScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_joist_span',
      name: 'Joist Span',
      subtitle: 'Floor joist span calculator',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['joist', 'span', 'floor', 'spacing', 'lumber'],
      builder: () => const JoistSpanScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_king_jack_stud',
      name: 'King & Jack Stud',
      subtitle: 'King and jack stud calculator',
      icon: LucideIcons.alignVerticalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['king', 'jack', 'stud', 'framing', 'opening'],
      builder: () => const KingJackStudScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_labor_hours',
      name: 'Labor Hours',
      subtitle: 'Construction labor hours estimator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['labor', 'hours', 'time', 'estimate', 'crew'],
      builder: () => const gc_labor_hours.LaborHoursScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_landing',
      name: 'Landing',
      subtitle: 'Stair landing calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['landing', 'stair', 'platform', 'code', 'dimension'],
      builder: () => const LandingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_lot_coverage',
      name: 'Lot Coverage',
      subtitle: 'Lot coverage percentage',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['lot', 'coverage', 'zoning', 'setback', 'percentage'],
      builder: () => const LotCoverageScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_lumber_quantity',
      name: 'Lumber Quantity',
      subtitle: 'Lumber quantity calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['lumber', 'quantity', 'board', 'framing', 'material'],
      builder: () => const LumberQuantityScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_lvl_glulam',
      name: 'LVL / Glulam',
      subtitle: 'LVL and glulam beam calculator',
      icon: LucideIcons.alignHorizontalDistributeStart,
      category: ScreenCategory.calculators,
      searchTags: ['lvl', 'glulam', 'beam', 'engineered', 'span'],
      builder: () => const LvlGlulamScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_markup',
      name: 'Markup',
      subtitle: 'Markup percentage calculator',
      icon: LucideIcons.percent,
      category: ScreenCategory.calculators,
      searchTags: ['markup', 'profit', 'margin', 'price', 'cost'],
      builder: () => const MarkupScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_permit_cost',
      name: 'Permit Cost',
      subtitle: 'Building permit cost estimator',
      icon: LucideIcons.fileText,
      category: ScreenCategory.calculators,
      searchTags: ['permit', 'cost', 'building', 'fee', 'inspection'],
      builder: () => const PermitCostScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_pier_footing',
      name: 'Pier Footing',
      subtitle: 'Pier footing calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['pier', 'footing', 'concrete', 'post', 'deck'],
      builder: () => const PierFootingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_plate',
      name: 'Plate Calculator',
      subtitle: 'Top and bottom plate calculator',
      icon: LucideIcons.alignHorizontalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['plate', 'top', 'bottom', 'framing', 'wall'],
      builder: () => const PlateCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_post_sizing',
      name: 'Post Sizing',
      subtitle: 'Post sizing for load bearing',
      icon: LucideIcons.pilcrow,
      category: ScreenCategory.calculators,
      searchTags: ['post', 'sizing', 'column', 'load', 'support'],
      builder: () => const PostSizingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_profit_margin',
      name: 'Profit Margin',
      subtitle: 'Profit margin calculator',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['profit', 'margin', 'percentage', 'markup', 'cost'],
      builder: () => const ProfitMarginScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_progress_payment',
      name: 'Progress Payment',
      subtitle: 'Progress payment schedule',
      icon: LucideIcons.calendarCheck,
      category: ScreenCategory.calculators,
      searchTags: ['progress', 'payment', 'schedule', 'draw', 'billing'],
      builder: () => const ProgressPaymentScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_project_duration',
      name: 'Project Duration',
      subtitle: 'Project duration estimator',
      icon: LucideIcons.calendar,
      category: ScreenCategory.calculators,
      searchTags: ['project', 'duration', 'schedule', 'timeline', 'days'],
      builder: () => const ProjectDurationScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_r_value',
      name: 'R-Value',
      subtitle: 'Insulation R-value calculator',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['r-value', 'insulation', 'thermal', 'resistance', 'energy'],
      builder: () => const RValueScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_rafter',
      name: 'Rafter Calculator',
      subtitle: 'Rafter length calculator',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['rafter', 'roof', 'length', 'pitch', 'framing'],
      builder: () => const RafterCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_rafter_span',
      name: 'Rafter Span',
      subtitle: 'Rafter span calculator',
      icon: LucideIcons.moveHorizontal,
      category: ScreenCategory.calculators,
      searchTags: ['rafter', 'span', 'roof', 'pitch', 'lumber'],
      builder: () => const RafterSpanScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_railing',
      name: 'Railing',
      subtitle: 'Railing material calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['railing', 'baluster', 'deck', 'stair', 'code'],
      builder: () => const gc_railing.RailingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_ramp',
      name: 'Ramp',
      subtitle: 'ADA ramp calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['ramp', 'ada', 'slope', 'accessibility', 'wheelchair'],
      builder: () => const RampScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_rebar',
      name: 'Rebar Calculator',
      subtitle: 'Rebar quantity calculator',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['rebar', 'reinforcement', 'concrete', 'steel', 'bar'],
      builder: () => const RebarCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_retention',
      name: 'Retention',
      subtitle: 'Retainage calculation',
      icon: LucideIcons.lock,
      category: ScreenCategory.calculators,
      searchTags: ['retention', 'retainage', 'holdback', 'contract', 'payment'],
      builder: () => const RetentionScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_ridge_board',
      name: 'Ridge Board',
      subtitle: 'Ridge board sizing calculator',
      icon: LucideIcons.alignHorizontalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['ridge', 'board', 'roof', 'framing', 'rafter'],
      builder: () => const RidgeBoardScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_rim_joist',
      name: 'Rim Joist',
      subtitle: 'Rim joist calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['rim', 'joist', 'band', 'floor', 'framing'],
      builder: () => const RimJoistScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_roof_sheathing',
      name: 'Roof Sheathing',
      subtitle: 'Roof sheathing calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['roof', 'sheathing', 'plywood', 'osb', 'decking'],
      builder: () => const RoofSheathingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_rough_opening',
      name: 'Rough Opening',
      subtitle: 'Door and window rough opening',
      icon: LucideIcons.scan,
      category: ScreenCategory.calculators,
      searchTags: ['rough', 'opening', 'door', 'window', 'framing'],
      builder: () => const RoughOpeningScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_slab',
      name: 'Slab Calculator',
      subtitle: 'Concrete slab calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['slab', 'concrete', 'floor', 'patio', 'thickness'],
      builder: () => const SlabCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_slope',
      name: 'Slope',
      subtitle: 'Slope and grade calculator',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['slope', 'grade', 'rise', 'run', 'percentage'],
      builder: () => const SlopeScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_smoke_detector',
      name: 'Smoke Detector',
      subtitle: 'Smoke detector placement',
      icon: LucideIcons.alertCircle,
      category: ScreenCategory.calculators,
      searchTags: ['smoke', 'detector', 'alarm', 'safety', 'code'],
      builder: () => const gc_smoke_detector.SmokeDetectorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_soffit',
      name: 'Soffit',
      subtitle: 'Soffit material calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['soffit', 'eave', 'overhang', 'vent', 'aluminum'],
      builder: () => const SoffitScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_spiral_stair',
      name: 'Spiral Stair',
      subtitle: 'Spiral stair calculator',
      icon: LucideIcons.rotateCw,
      category: ScreenCategory.calculators,
      searchTags: ['spiral', 'stair', 'circular', 'tread', 'rise'],
      builder: () => const SpiralStairScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_spray_foam',
      name: 'Spray Foam',
      subtitle: 'Spray foam insulation calculator',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['spray', 'foam', 'insulation', 'r-value', 'closed'],
      builder: () => const SprayFoamScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_sqft',
      name: 'Square Footage',
      subtitle: 'Square footage calculator',
      icon: LucideIcons.squareStack,
      category: ScreenCategory.calculators,
      searchTags: ['square', 'footage', 'sqft', 'area', 'room'],
      builder: () => const SqftScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_stained_concrete',
      name: 'Stained Concrete',
      subtitle: 'Stained concrete calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['stained', 'concrete', 'acid', 'dye', 'finish'],
      builder: () => const StainedConcreteScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_stair',
      name: 'Stair Calculator',
      subtitle: 'Stair rise and run calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'rise', 'run', 'tread', 'code'],
      builder: () => const StairCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_stair_stringer',
      name: 'Stair Stringer',
      subtitle: 'Stair stringer calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'stringer', 'layout', 'framing', 'cut'],
      builder: () => const StairStringerScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_stamped_concrete',
      name: 'Stamped Concrete',
      subtitle: 'Stamped concrete calculator',
      icon: LucideIcons.stamp,
      category: ScreenCategory.calculators,
      searchTags: ['stamped', 'concrete', 'decorative', 'pattern', 'finish'],
      builder: () => const StampedConcreteScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_stud',
      name: 'Stud Calculator',
      subtitle: 'Wall stud quantity calculator',
      icon: LucideIcons.alignVerticalDistributeCenter,
      category: ScreenCategory.calculators,
      searchTags: ['stud', 'wall', 'framing', 'spacing', 'quantity'],
      builder: () => const StudCalculatorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_subfloor',
      name: 'Subfloor',
      subtitle: 'Subfloor material calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['subfloor', 'plywood', 'osb', 'floor', 'sheathing'],
      builder: () => const SubfloorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_swell_factor',
      name: 'Swell Factor',
      subtitle: 'Soil swell factor calculator',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['swell', 'factor', 'soil', 'excavation', 'volume'],
      builder: () => const SwellFactorScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_trench',
      name: 'Trench',
      subtitle: 'Trench excavation calculator',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['trench', 'excavation', 'dig', 'depth', 'width'],
      builder: () => const TrenchScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_trim_lumber',
      name: 'Trim Lumber',
      subtitle: 'Trim lumber calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['trim', 'lumber', 'molding', 'casing', 'baseboard'],
      builder: () => const TrimLumberScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_truss_count',
      name: 'Truss Count',
      subtitle: 'Roof truss quantity calculator',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['truss', 'count', 'roof', 'framing', 'spacing'],
      builder: () => const TrussCountScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_vapor_barrier',
      name: 'Vapor Barrier',
      subtitle: 'Vapor barrier calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['vapor', 'barrier', 'moisture', 'plastic', 'crawl'],
      builder: () => const VaporBarrierScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_wall_insulation',
      name: 'Wall Insulation',
      subtitle: 'Wall insulation calculator',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.calculators,
      searchTags: ['wall', 'insulation', 'r-value', 'batt', 'fiberglass'],
      builder: () => const WallInsulationScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_wall_sheathing',
      name: 'Wall Sheathing',
      subtitle: 'Wall sheathing calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['wall', 'sheathing', 'plywood', 'osb', 'siding'],
      builder: () => const WallSheathingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_waterproofing',
      name: 'Waterproofing',
      subtitle: 'Waterproofing material calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['waterproofing', 'membrane', 'foundation', 'basement', 'seal'],
      builder: () => const WaterproofingScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_winder_stair',
      name: 'Winder Stair',
      subtitle: 'Winder stair calculator',
      icon: LucideIcons.cornerRightDown,
      category: ScreenCategory.calculators,
      searchTags: ['winder', 'stair', 'turn', 'corner', 'tread'],
      builder: () => const WinderStairScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_window_schedule',
      name: 'Window Schedule',
      subtitle: 'Window schedule calculator',
      icon: LucideIcons.appWindow,
      category: ScreenCategory.calculators,
      searchTags: ['window', 'schedule', 'opening', 'size', 'glass'],
      builder: () => const WindowScheduleScreen(),
      trade: 'gc',
    ),
  ];

  // =========================================================================
  // REMODELER CALCULATORS (110)
  // =========================================================================
  static final List<ScreenEntry> remodelerCalculators = [
    ScreenEntry(
      id: 'remodeler_accent_wall',
      name: 'Accent Wall',
      subtitle: 'Accent wall material calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['accent', 'wall', 'feature', 'paint', 'material'],
      builder: () => const AccentWallScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_ada_doorway',
      name: 'ADA Doorway',
      subtitle: 'ADA doorway requirements',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['ada', 'doorway', 'accessibility', 'wheelchair', 'width'],
      builder: () => const AdaDoorwayScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_adhesive',
      name: 'Adhesive',
      subtitle: 'Adhesive coverage calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['adhesive', 'glue', 'coverage', 'flooring', 'tile'],
      builder: () => const AdhesiveScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_appliance_clearance',
      name: 'Appliance Clearance',
      subtitle: 'Appliance clearance requirements',
      icon: LucideIcons.refrigerator,
      category: ScreenCategory.calculators,
      searchTags: ['appliance', 'clearance', 'kitchen', 'space', 'code'],
      builder: () => const ApplianceClearanceScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_arbor',
      name: 'Arbor',
      subtitle: 'Arbor material calculator',
      icon: LucideIcons.trees,
      category: ScreenCategory.calculators,
      searchTags: ['arbor', 'garden', 'trellis', 'pergola', 'outdoor'],
      builder: () => const ArborScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_attic_insulation',
      name: 'Attic Insulation',
      subtitle: 'Attic insulation calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['attic', 'insulation', 'r-value', 'blown', 'batt'],
      builder: () => const remodeler_attic_insulation.AtticInsulationScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_awning',
      name: 'Awning',
      subtitle: 'Awning size calculator',
      icon: LucideIcons.umbrella,
      category: ScreenCategory.calculators,
      searchTags: ['awning', 'shade', 'patio', 'window', 'cover'],
      builder: () => const AwningScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_backsplash',
      name: 'Backsplash',
      subtitle: 'Backsplash tile calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['backsplash', 'tile', 'kitchen', 'subway', 'square'],
      builder: () => const BacksplashScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_baluster',
      name: 'Baluster',
      subtitle: 'Baluster spacing calculator',
      icon: LucideIcons.alignVerticalDistributeCenter,
      category: ScreenCategory.calculators,
      searchTags: ['baluster', 'spindle', 'railing', 'spacing', 'deck'],
      builder: () => const BalusterScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_baseboard',
      name: 'Baseboard',
      subtitle: 'Baseboard molding calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['baseboard', 'molding', 'trim', 'linear', 'feet'],
      builder: () => const BaseboardScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_bathroom_remodel_budget',
      name: 'Bathroom Remodel Budget',
      subtitle: 'Bathroom remodel cost estimator',
      icon: LucideIcons.bath,
      category: ScreenCategory.calculators,
      searchTags: ['bathroom', 'remodel', 'budget', 'cost', 'renovation'],
      builder: () => const BathroomRemodelBudgetScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_bathroom_tile',
      name: 'Bathroom Tile',
      subtitle: 'Bathroom tile calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['bathroom', 'tile', 'floor', 'wall', 'shower'],
      builder: () => const BathroomTileScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_bathroom_vent',
      name: 'Bathroom Vent',
      subtitle: 'Bathroom vent fan sizing',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['bathroom', 'vent', 'fan', 'exhaust', 'cfm'],
      builder: () => const BathroomVentScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_bathtub',
      name: 'Bathtub',
      subtitle: 'Bathtub installation calculator',
      icon: LucideIcons.bath,
      category: ScreenCategory.calculators,
      searchTags: ['bathtub', 'tub', 'alcove', 'freestanding', 'install'],
      builder: () => const BathtubScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_blinds',
      name: 'Blinds',
      subtitle: 'Window blinds calculator',
      icon: LucideIcons.blinds,
      category: ScreenCategory.calculators,
      searchTags: ['blinds', 'window', 'covering', 'shade', 'measure'],
      builder: () => const BlindsScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_cabinet_hardware',
      name: 'Cabinet Hardware',
      subtitle: 'Cabinet hardware calculator',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['cabinet', 'hardware', 'knob', 'pull', 'handle'],
      builder: () => const CabinetHardwareScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_caulk',
      name: 'Caulk',
      subtitle: 'Caulk tube calculator',
      icon: LucideIcons.penTool,
      category: ScreenCategory.calculators,
      searchTags: ['caulk', 'sealant', 'tube', 'joint', 'silicone'],
      builder: () => const CaulkScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_ceiling_fan',
      name: 'Ceiling Fan',
      subtitle: 'Ceiling fan sizing calculator',
      icon: LucideIcons.fan,
      category: ScreenCategory.calculators,
      searchTags: ['ceiling', 'fan', 'size', 'room', 'blade'],
      builder: () => const remodeler_ceiling_fan.CeilingFanScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_ceiling_paint',
      name: 'Ceiling Paint',
      subtitle: 'Ceiling paint coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['ceiling', 'paint', 'coverage', 'gallon', 'area'],
      builder: () => const CeilingPaintScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_chair_rail',
      name: 'Chair Rail',
      subtitle: 'Chair rail molding calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['chair', 'rail', 'molding', 'trim', 'linear'],
      builder: () => const ChairRailScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_closet_system',
      name: 'Closet System',
      subtitle: 'Closet organization calculator',
      icon: LucideIcons.shirt,
      category: ScreenCategory.calculators,
      searchTags: ['closet', 'system', 'organizer', 'shelf', 'rod'],
      builder: () => const ClosetSystemScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_contingency',
      name: 'Contingency',
      subtitle: 'Project contingency calculator',
      icon: LucideIcons.shieldQuestion,
      category: ScreenCategory.calculators,
      searchTags: ['contingency', 'budget', 'reserve', 'unexpected', 'cost'],
      builder: () => const ContingencyScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_countertop',
      name: 'Countertop',
      subtitle: 'Countertop square footage calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['countertop', 'granite', 'quartz', 'square', 'feet'],
      builder: () => const CountertopScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_crown_molding',
      name: 'Crown Molding',
      subtitle: 'Crown molding calculator',
      icon: LucideIcons.crown,
      category: ScreenCategory.calculators,
      searchTags: ['crown', 'molding', 'trim', 'ceiling', 'linear'],
      builder: () => const CrownMoldingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_curtain_rod',
      name: 'Curtain Rod',
      subtitle: 'Curtain rod sizing calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['curtain', 'rod', 'drapery', 'window', 'hardware'],
      builder: () => const CurtainRodScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_deck_stain',
      name: 'Deck Stain',
      subtitle: 'Deck stain coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'stain', 'sealer', 'coverage', 'gallon'],
      builder: () => const DeckStainScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_door_casing',
      name: 'Door Casing',
      subtitle: 'Door casing material calculator',
      icon: LucideIcons.doorClosed,
      category: ScreenCategory.calculators,
      searchTags: ['door', 'casing', 'trim', 'molding', 'frame'],
      builder: () => const DoorCasingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_door_hardware',
      name: 'Door Hardware',
      subtitle: 'Door hardware calculator',
      icon: LucideIcons.keyRound,
      category: ScreenCategory.calculators,
      searchTags: ['door', 'hardware', 'knob', 'handle', 'hinge'],
      builder: () => const DoorHardwareScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_door_sizing',
      name: 'Door Sizing',
      subtitle: 'Interior door sizing guide',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['door', 'sizing', 'interior', 'width', 'height'],
      builder: () => const DoorSizingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_doorbell',
      name: 'Doorbell',
      subtitle: 'Doorbell installation calculator',
      icon: LucideIcons.bell,
      category: ScreenCategory.calculators,
      searchTags: ['doorbell', 'chime', 'wired', 'wireless', 'install'],
      builder: () => const DoorbellScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_downspout',
      name: 'Downspout',
      subtitle: 'Downspout sizing calculator',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['downspout', 'gutter', 'drainage', 'rain', 'extension'],
      builder: () => const remodeler_downspout.DownspoutScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_drop_cloth',
      name: 'Drop Cloth',
      subtitle: 'Drop cloth coverage calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['drop', 'cloth', 'protection', 'paint', 'floor'],
      builder: () => const DropClothScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_drywall_patch',
      name: 'Drywall Patch',
      subtitle: 'Drywall patch material calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['drywall', 'patch', 'repair', 'hole', 'compound'],
      builder: () => const DrywallPatchScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_epoxy_flake',
      name: 'Epoxy Flake',
      subtitle: 'Epoxy flake coverage calculator',
      icon: LucideIcons.sparkles,
      category: ScreenCategory.calculators,
      searchTags: ['epoxy', 'flake', 'chip', 'garage', 'floor'],
      builder: () => const EpoxyFlakeScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_epoxy_flooring',
      name: 'Epoxy Flooring',
      subtitle: 'Epoxy flooring calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['epoxy', 'flooring', 'garage', 'coating', 'gallon'],
      builder: () => const EpoxyFlooringScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_exterior_lighting',
      name: 'Exterior Lighting',
      subtitle: 'Exterior lighting layout',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['exterior', 'lighting', 'outdoor', 'landscape', 'fixture'],
      builder: () => const ExteriorLightingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_fascia',
      name: 'Fascia',
      subtitle: 'Fascia board calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['fascia', 'board', 'trim', 'roofline', 'eave'],
      builder: () => const remodeler_fascia.FasciaScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_fence_gate',
      name: 'Fence Gate',
      subtitle: 'Fence gate calculator',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['fence', 'gate', 'hardware', 'swing', 'latch'],
      builder: () => const FenceGateScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_fire_pit',
      name: 'Fire Pit',
      subtitle: 'Fire pit material calculator',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'pit', 'patio', 'outdoor', 'stone'],
      builder: () => const FirePitScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_flooring_transition',
      name: 'Flooring Transition',
      subtitle: 'Flooring transition strips',
      icon: LucideIcons.arrowRightLeft,
      category: ScreenCategory.calculators,
      searchTags: ['flooring', 'transition', 'strip', 't-molding', 'reducer'],
      builder: () => const FlooringTransitionScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_french_drain',
      name: 'French Drain',
      subtitle: 'French drain material calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['french', 'drain', 'gravel', 'pipe', 'drainage'],
      builder: () => const remodeler_french_drain.FrenchDrainScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_garage_floor_coating',
      name: 'Garage Floor Coating',
      subtitle: 'Garage floor coating calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['garage', 'floor', 'coating', 'epoxy', 'paint'],
      builder: () => const GarageFloorCoatingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_gazebo',
      name: 'Gazebo',
      subtitle: 'Gazebo material calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['gazebo', 'outdoor', 'structure', 'pergola', 'pavilion'],
      builder: () => const GazeboScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_gfci_outlet',
      name: 'GFCI Outlet',
      subtitle: 'GFCI outlet requirements',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['gfci', 'outlet', 'receptacle', 'code', 'bathroom'],
      builder: () => const GfciOutletScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_grab_bar',
      name: 'Grab Bar',
      subtitle: 'Grab bar placement calculator',
      icon: LucideIcons.grip,
      category: ScreenCategory.calculators,
      searchTags: ['grab', 'bar', 'ada', 'bathroom', 'safety'],
      builder: () => const GrabBarScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_grout',
      name: 'Grout',
      subtitle: 'Grout quantity calculator',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['grout', 'tile', 'joint', 'sanded', 'unsanded'],
      builder: () => const GroutScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_gutter_sizing',
      name: 'Gutter Sizing',
      subtitle: 'Gutter sizing calculator',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['gutter', 'sizing', 'downspout', 'drainage', 'rain'],
      builder: () => const GutterSizingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_house_numbers',
      name: 'House Numbers',
      subtitle: 'House number sizing guide',
      icon: LucideIcons.hash,
      category: ScreenCategory.calculators,
      searchTags: ['house', 'numbers', 'address', 'visibility', 'code'],
      builder: () => const HouseNumbersScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_kitchen_cabinet',
      name: 'Kitchen Cabinet',
      subtitle: 'Kitchen cabinet calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'cabinet', 'base', 'wall', 'layout'],
      builder: () => const KitchenCabinetScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_kitchen_island',
      name: 'Kitchen Island',
      subtitle: 'Kitchen island sizing calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'island', 'clearance', 'size', 'seating'],
      builder: () => const KitchenIslandScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_kitchen_remodel_budget',
      name: 'Kitchen Remodel Budget',
      subtitle: 'Kitchen remodel cost estimator',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['kitchen', 'remodel', 'budget', 'cost', 'renovation'],
      builder: () => const KitchenRemodelBudgetScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_landscape_edging',
      name: 'Landscape Edging',
      subtitle: 'Landscape edging calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['landscape', 'edging', 'border', 'garden', 'bed'],
      builder: () => const LandscapeEdgingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_lighting_layout',
      name: 'Lighting Layout',
      subtitle: 'Room lighting layout calculator',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['lighting', 'layout', 'recessed', 'spacing', 'room'],
      builder: () => const LightingLayoutScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_lighting_recessed',
      name: 'Recessed Lighting',
      subtitle: 'Recessed lighting calculator',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['recessed', 'lighting', 'can', 'spacing', 'layout'],
      builder: () => const LightingRecessedScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_mailbox_post',
      name: 'Mailbox Post',
      subtitle: 'Mailbox post installation',
      icon: LucideIcons.mail,
      category: ScreenCategory.calculators,
      searchTags: ['mailbox', 'post', 'install', 'height', 'usps'],
      builder: () => const MailboxPostScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_material_labor_split',
      name: 'Material Labor Split',
      subtitle: 'Material vs labor cost split',
      icon: LucideIcons.pieChart,
      category: ScreenCategory.calculators,
      searchTags: ['material', 'labor', 'split', 'cost', 'percentage'],
      builder: () => const MaterialLaborSplitScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_medicine_cabinet',
      name: 'Medicine Cabinet',
      subtitle: 'Medicine cabinet sizing',
      icon: LucideIcons.pill,
      category: ScreenCategory.calculators,
      searchTags: ['medicine', 'cabinet', 'bathroom', 'recessed', 'mirror'],
      builder: () => const MedicineCabinetScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_metallic_epoxy',
      name: 'Metallic Epoxy',
      subtitle: 'Metallic epoxy calculator',
      icon: LucideIcons.sparkles,
      category: ScreenCategory.calculators,
      searchTags: ['metallic', 'epoxy', 'floor', 'decorative', 'coating'],
      builder: () => const MetallicEpoxyScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_mirror',
      name: 'Mirror',
      subtitle: 'Mirror sizing calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['mirror', 'bathroom', 'vanity', 'size', 'frame'],
      builder: () => const MirrorScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_motion_sensor',
      name: 'Motion Sensor',
      subtitle: 'Motion sensor coverage calculator',
      icon: LucideIcons.radar,
      category: ScreenCategory.calculators,
      searchTags: ['motion', 'sensor', 'security', 'coverage', 'detector'],
      builder: () => const MotionSensorScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_newel_post',
      name: 'Newel Post',
      subtitle: 'Newel post calculator',
      icon: LucideIcons.pilcrow,
      category: ScreenCategory.calculators,
      searchTags: ['newel', 'post', 'stair', 'railing', 'baluster'],
      builder: () => const NewelPostScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_outdoor_kitchen',
      name: 'Outdoor Kitchen',
      subtitle: 'Outdoor kitchen layout calculator',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['outdoor', 'kitchen', 'grill', 'patio', 'counter'],
      builder: () => const OutdoorKitchenScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_outlet_relocation',
      name: 'Outlet Relocation',
      subtitle: 'Outlet relocation estimator',
      icon: LucideIcons.plug,
      category: ScreenCategory.calculators,
      searchTags: ['outlet', 'relocation', 'move', 'electrical', 'receptacle'],
      builder: () => const OutletRelocationScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_paint_coverage',
      name: 'Paint Coverage',
      subtitle: 'Paint coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['paint', 'coverage', 'gallon', 'wall', 'room'],
      builder: () => const PaintCoverageScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_painter_tape',
      name: 'Painter Tape',
      subtitle: 'Painter tape calculator',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['painter', 'tape', 'masking', 'edge', 'roll'],
      builder: () => const PainterTapeScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_patio_paver',
      name: 'Patio Paver',
      subtitle: 'Patio paver calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['patio', 'paver', 'brick', 'stone', 'square'],
      builder: () => const PatioPaverScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_pergola',
      name: 'Pergola',
      subtitle: 'Pergola material calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['pergola', 'outdoor', 'shade', 'structure', 'patio'],
      builder: () => const PergolaScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_picket_fence',
      name: 'Picket Fence',
      subtitle: 'Picket fence calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['picket', 'fence', 'spacing', 'post', 'board'],
      builder: () => const PicketFenceScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_porch_screen',
      name: 'Porch Screen',
      subtitle: 'Porch screen calculator',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['porch', 'screen', 'mesh', 'enclosure', 'frame'],
      builder: () => const PorchScreenScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_primer',
      name: 'Primer',
      subtitle: 'Primer coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['primer', 'paint', 'coverage', 'gallon', 'prep'],
      builder: () => const PrimerScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_privacy_fence',
      name: 'Privacy Fence',
      subtitle: 'Privacy fence calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['privacy', 'fence', 'board', 'post', 'panel'],
      builder: () => const PrivacyFenceScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_railing',
      name: 'Railing',
      subtitle: 'Railing material calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['railing', 'deck', 'stair', 'baluster', 'post'],
      builder: () => const remodeler_railing.RailingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_raised_bed',
      name: 'Raised Bed',
      subtitle: 'Raised garden bed calculator',
      icon: LucideIcons.flower2,
      category: ScreenCategory.calculators,
      searchTags: ['raised', 'bed', 'garden', 'soil', 'planter'],
      builder: () => const RaisedBedScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_retaining_wall',
      name: 'Retaining Wall',
      subtitle: 'Retaining wall block calculator',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['retaining', 'wall', 'block', 'landscape', 'stone'],
      builder: () => const RetainingWallScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_ridge_vent',
      name: 'Ridge Vent',
      subtitle: 'Ridge vent calculator',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['ridge', 'vent', 'roof', 'attic', 'ventilation'],
      builder: () => const remodeler_ridge_vent.RidgeVentScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_sandpaper',
      name: 'Sandpaper',
      subtitle: 'Sandpaper grit selection guide',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['sandpaper', 'grit', 'sanding', 'prep', 'finish'],
      builder: () => const SandpaperScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_screen_door',
      name: 'Screen Door',
      subtitle: 'Screen door sizing calculator',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.calculators,
      searchTags: ['screen', 'door', 'storm', 'mesh', 'size'],
      builder: () => const ScreenDoorScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_sealer',
      name: 'Sealer',
      subtitle: 'Sealer coverage calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['sealer', 'concrete', 'wood', 'coverage', 'gallon'],
      builder: () => const SealerScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_shelving',
      name: 'Shelving',
      subtitle: 'Shelving layout calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['shelving', 'shelf', 'closet', 'garage', 'bracket'],
      builder: () => const ShelvingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_shower_enclosure',
      name: 'Shower Enclosure',
      subtitle: 'Shower enclosure calculator',
      icon: LucideIcons.squareStack,
      category: ScreenCategory.calculators,
      searchTags: ['shower', 'enclosure', 'glass', 'door', 'frameless'],
      builder: () => const ShowerEnclosureScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_shutter',
      name: 'Shutter',
      subtitle: 'Window shutter sizing',
      icon: LucideIcons.alignHorizontalJustifyCenter,
      category: ScreenCategory.calculators,
      searchTags: ['shutter', 'window', 'exterior', 'decorative', 'size'],
      builder: () => const ShutterScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_soffit_vent',
      name: 'Soffit Vent',
      subtitle: 'Soffit vent calculator',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['soffit', 'vent', 'attic', 'intake', 'ventilation'],
      builder: () => const remodeler_soffit_vent.SoffitVentScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_splash_block',
      name: 'Splash Block',
      subtitle: 'Splash block sizing',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['splash', 'block', 'downspout', 'drainage', 'foundation'],
      builder: () => const remodeler_splash_block.SplashBlockScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_stair_carpet',
      name: 'Stair Carpet',
      subtitle: 'Stair carpet calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'carpet', 'runner', 'tread', 'riser'],
      builder: () => const StairCarpetScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_stair_lift',
      name: 'Stair Lift',
      subtitle: 'Stair lift requirements',
      icon: LucideIcons.accessibility,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'lift', 'accessibility', 'mobility', 'chair'],
      builder: () => const StairLiftScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_stair_tread',
      name: 'Stair Tread',
      subtitle: 'Stair tread calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'tread', 'riser', 'nosing', 'hardwood'],
      builder: () => const StairTreadScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_storm_door',
      name: 'Storm Door',
      subtitle: 'Storm door sizing calculator',
      icon: LucideIcons.doorClosed,
      category: ScreenCategory.calculators,
      searchTags: ['storm', 'door', 'entry', 'screen', 'glass'],
      builder: () => const StormDoorScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_storm_window',
      name: 'Storm Window',
      subtitle: 'Storm window sizing',
      icon: LucideIcons.appWindow,
      category: ScreenCategory.calculators,
      searchTags: ['storm', 'window', 'interior', 'exterior', 'insert'],
      builder: () => const StormWindowScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_sump_pump',
      name: 'Sump Pump',
      subtitle: 'Sump pump sizing calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['sump', 'pump', 'basement', 'drainage', 'gph'],
      builder: () => const remodeler_sump_pump.SumpPumpScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_texture_match',
      name: 'Texture Match',
      subtitle: 'Wall texture matching guide',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['texture', 'match', 'wall', 'drywall', 'knockdown'],
      builder: () => const TextureMatchScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_threshold_ramp',
      name: 'Threshold Ramp',
      subtitle: 'Threshold ramp calculator',
      icon: LucideIcons.arrowUpRight,
      category: ScreenCategory.calculators,
      searchTags: ['threshold', 'ramp', 'ada', 'transition', 'wheelchair'],
      builder: () => const ThresholdRampScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_tile_accent',
      name: 'Tile Accent',
      subtitle: 'Accent tile calculator',
      icon: LucideIcons.sparkles,
      category: ScreenCategory.calculators,
      searchTags: ['tile', 'accent', 'border', 'decorative', 'feature'],
      builder: () => const TileAccentScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_toilet_rough_in',
      name: 'Toilet Rough-In',
      subtitle: 'Toilet rough-in measurement',
      icon: LucideIcons.bath,
      category: ScreenCategory.calculators,
      searchTags: ['toilet', 'rough', 'in', 'measurement', 'distance'],
      builder: () => const remodeler_toilet_rough_in.ToiletRoughInScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_towel_bar',
      name: 'Towel Bar',
      subtitle: 'Towel bar placement guide',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['towel', 'bar', 'bathroom', 'placement', 'height'],
      builder: () => const TowelBarScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_trellis',
      name: 'Trellis',
      subtitle: 'Trellis material calculator',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['trellis', 'garden', 'lattice', 'climbing', 'vine'],
      builder: () => const TrellisScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_trim_paint',
      name: 'Trim Paint',
      subtitle: 'Trim paint coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['trim', 'paint', 'molding', 'coverage', 'quart'],
      builder: () => const TrimPaintScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_usb_outlet',
      name: 'USB Outlet',
      subtitle: 'USB outlet requirements',
      icon: LucideIcons.usb,
      category: ScreenCategory.calculators,
      searchTags: ['usb', 'outlet', 'charging', 'receptacle', 'port'],
      builder: () => const UsbOutletScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_vanity',
      name: 'Vanity',
      subtitle: 'Bathroom vanity sizing',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['vanity', 'bathroom', 'cabinet', 'sink', 'size'],
      builder: () => const VanityScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_wainscoting',
      name: 'Wainscoting',
      subtitle: 'Wainscoting material calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['wainscoting', 'panel', 'beadboard', 'wall', 'trim'],
      builder: () => const WainscotingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_walkin_tub',
      name: 'Walk-In Tub',
      subtitle: 'Walk-in tub requirements',
      icon: LucideIcons.bath,
      category: ScreenCategory.calculators,
      searchTags: ['walkin', 'tub', 'accessibility', 'bathroom', 'ada'],
      builder: () => const WalkinTubScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_walkway',
      name: 'Walkway',
      subtitle: 'Walkway material calculator',
      icon: LucideIcons.footprints,
      category: ScreenCategory.calculators,
      searchTags: ['walkway', 'path', 'paver', 'concrete', 'stone'],
      builder: () => const WalkwayScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_wallpaper',
      name: 'Wallpaper',
      subtitle: 'Wallpaper roll calculator',
      icon: LucideIcons.scroll,
      category: ScreenCategory.calculators,
      searchTags: ['wallpaper', 'roll', 'coverage', 'pattern', 'repeat'],
      builder: () => const WallpaperScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_weatherstrip',
      name: 'Weatherstrip',
      subtitle: 'Weatherstrip calculator',
      icon: LucideIcons.wind,
      category: ScreenCategory.calculators,
      searchTags: ['weatherstrip', 'door', 'window', 'seal', 'draft'],
      builder: () => const WeatherstripScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_wheelchair_ramp',
      name: 'Wheelchair Ramp',
      subtitle: 'ADA wheelchair ramp calculator',
      icon: LucideIcons.accessibility,
      category: ScreenCategory.calculators,
      searchTags: ['wheelchair', 'ramp', 'ada', 'accessibility', 'slope'],
      builder: () => const WheelchairRampScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_whole_house_estimator',
      name: 'Whole House Estimator',
      subtitle: 'Whole house remodel estimator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['whole', 'house', 'estimator', 'remodel', 'budget'],
      builder: () => const WholeHouseEstimatorScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_window_casing',
      name: 'Window Casing',
      subtitle: 'Window casing material calculator',
      icon: LucideIcons.appWindow,
      category: ScreenCategory.calculators,
      searchTags: ['window', 'casing', 'trim', 'molding', 'frame'],
      builder: () => const WindowCasingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_window_film',
      name: 'Window Film',
      subtitle: 'Window film calculator',
      icon: LucideIcons.scan,
      category: ScreenCategory.calculators,
      searchTags: ['window', 'film', 'tint', 'privacy', 'uv'],
      builder: () => const WindowFilmScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_window_replacement',
      name: 'Window Replacement',
      subtitle: 'Window replacement calculator',
      icon: LucideIcons.appWindow,
      category: ScreenCategory.calculators,
      searchTags: ['window', 'replacement', 'insert', 'full', 'frame'],
      builder: () => const WindowReplacementScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_window_well',
      name: 'Window Well',
      subtitle: 'Window well sizing calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['window', 'well', 'egress', 'basement', 'cover'],
      builder: () => const WindowWellScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'remodeler_wood_filler',
      name: 'Wood Filler',
      subtitle: 'Wood filler estimator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['wood', 'filler', 'putty', 'repair', 'hole'],
      builder: () => const WoodFillerScreen(),
      trade: 'remodeler',
    ),
  ];

  // =========================================================================
  // LANDSCAPING CALCULATORS (136)
  // =========================================================================
  static final List<ScreenEntry> landscapingCalculators = [
    ScreenEntry(
      id: 'landscaping_annual_bed',
      name: 'Annual Bed',
      subtitle: 'Annual flower bed calculator',
      icon: LucideIcons.flower2,
      category: ScreenCategory.calculators,
      searchTags: ['annual', 'bed', 'flower', 'planting', 'color'],
      builder: () => const AnnualBedScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_arbor',
      name: 'Arbor',
      subtitle: 'Garden arbor calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['arbor', 'garden', 'structure', 'trellis', 'arch'],
      builder: () => const landscaping_arbor.ArborScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_bed_edging',
      name: 'Bed Edging',
      subtitle: 'Bed edging material calculator',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['bed', 'edging', 'border', 'steel', 'aluminum'],
      builder: () => const BedEdgingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_bed_prep',
      name: 'Bed Prep',
      subtitle: 'Planting bed preparation',
      icon: LucideIcons.shovel,
      category: ScreenCategory.calculators,
      searchTags: ['bed', 'prep', 'soil', 'amendment', 'planting'],
      builder: () => const BedPrepScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_berm',
      name: 'Berm',
      subtitle: 'Landscape berm calculator',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['berm', 'mound', 'soil', 'landscape', 'grade'],
      builder: () => const BermScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_border_stone',
      name: 'Border Stone',
      subtitle: 'Border stone calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['border', 'stone', 'edging', 'landscape', 'bed'],
      builder: () => const BorderStoneScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_border_wall',
      name: 'Border Wall',
      subtitle: 'Low border wall calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['border', 'wall', 'low', 'landscape', 'block'],
      builder: () => const BorderWallScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_boulder_weight',
      name: 'Boulder Weight',
      subtitle: 'Estimate boulder weight',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['boulder', 'weight', 'rock', 'stone', 'landscape'],
      builder: () => const BoulderWeightScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_brick_edging',
      name: 'Brick Edging',
      subtitle: 'Brick edging calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['brick', 'edging', 'border', 'paver', 'landscape'],
      builder: () => const BrickEdgingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_bulk_material',
      name: 'Bulk Material',
      subtitle: 'Bulk material delivery calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['bulk', 'material', 'delivery', 'yard', 'cubic'],
      builder: () => const BulkMaterialScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_catch_basin',
      name: 'Catch Basin',
      subtitle: 'Catch basin sizing',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['catch', 'basin', 'drain', 'storm', 'water'],
      builder: () => const CatchBasinScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_channel_drain',
      name: 'Channel Drain',
      subtitle: 'Channel drain calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['channel', 'drain', 'trench', 'linear', 'driveway'],
      builder: () => const ChannelDrainScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_chipper_output',
      name: 'Chipper Output',
      subtitle: 'Wood chipper output estimate',
      icon: LucideIcons.trees,
      category: ScreenCategory.calculators,
      searchTags: ['chipper', 'output', 'wood', 'mulch', 'branch'],
      builder: () => const ChipperOutputScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_circle_radius',
      name: 'Circle Radius',
      subtitle: 'Circle area from radius',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['circle', 'radius', 'area', 'round', 'diameter'],
      builder: () => const CircleRadiusScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_cistern',
      name: 'Cistern',
      subtitle: 'Cistern sizing calculator',
      icon: LucideIcons.container,
      category: ScreenCategory.calculators,
      searchTags: ['cistern', 'water', 'storage', 'tank', 'rainwater'],
      builder: () => const CisternScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_compost_bin',
      name: 'Compost Bin',
      subtitle: 'Compost bin sizing',
      icon: LucideIcons.recycle,
      category: ScreenCategory.calculators,
      searchTags: ['compost', 'bin', 'organic', 'waste', 'garden'],
      builder: () => const CompostBinScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_compost',
      name: 'Compost',
      subtitle: 'Compost coverage calculator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['compost', 'organic', 'soil', 'amendment', 'garden'],
      builder: () => const CompostScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_compost_tea',
      name: 'Compost Tea',
      subtitle: 'Compost tea brewing calculator',
      icon: LucideIcons.coffee,
      category: ScreenCategory.calculators,
      searchTags: ['compost', 'tea', 'organic', 'fertilizer', 'brew'],
      builder: () => const CompostTeaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_concrete_curb',
      name: 'Concrete Curb',
      subtitle: 'Concrete curb calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['concrete', 'curb', 'edging', 'border', 'mow'],
      builder: () => const ConcreteCurbScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_crew_productivity',
      name: 'Crew Productivity',
      subtitle: 'Crew productivity metrics',
      icon: LucideIcons.users,
      category: ScreenCategory.calculators,
      searchTags: ['crew', 'productivity', 'labor', 'efficiency', 'man'],
      builder: () => const CrewProductivityScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_deck_board',
      name: 'Deck Board',
      subtitle: 'Deck board calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['deck', 'board', 'lumber', 'composite', 'square'],
      builder: () => const DeckBoardScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_decomposed_granite',
      name: 'Decomposed Granite',
      subtitle: 'DG coverage calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['decomposed', 'granite', 'dg', 'path', 'ground'],
      builder: () => const DecomposedGraniteScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_dethatching',
      name: 'Dethatching',
      subtitle: 'Lawn dethatching calculator',
      icon: LucideIcons.shovel,
      category: ScreenCategory.calculators,
      searchTags: ['dethatch', 'lawn', 'thatch', 'rake', 'grass'],
      builder: () => const DethatchingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_downspout_extension',
      name: 'Downspout Extension',
      subtitle: 'Downspout extension calculator',
      icon: LucideIcons.arrowDown,
      category: ScreenCategory.calculators,
      searchTags: ['downspout', 'extension', 'drain', 'gutter', 'water'],
      builder: () => const DownspoutExtensionScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_drainage_pipe',
      name: 'Drainage Pipe',
      subtitle: 'Drainage pipe sizing',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['drainage', 'pipe', 'corrugated', 'french', 'drain'],
      builder: () => const DrainagePipeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_drip_irrigation',
      name: 'Drip Irrigation',
      subtitle: 'Drip system calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['drip', 'irrigation', 'emitter', 'water', 'plant'],
      builder: () => const landscaping_drip.DripIrrigationScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_drip_line',
      name: 'Drip Line',
      subtitle: 'Drip line tubing calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['drip', 'line', 'tubing', 'irrigation', 'emitter'],
      builder: () => const DripLineScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_dry_creek',
      name: 'Dry Creek',
      subtitle: 'Dry creek bed calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['dry', 'creek', 'bed', 'rock', 'drainage'],
      builder: () => const DryCreekScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_dry_well',
      name: 'Dry Well',
      subtitle: 'Dry well sizing calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['dry', 'well', 'drainage', 'infiltration', 'storm'],
      builder: () => const DryWellScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_edging',
      name: 'Edging',
      subtitle: 'Landscape edging calculator',
      icon: LucideIcons.minus,
      category: ScreenCategory.calculators,
      searchTags: ['edging', 'border', 'landscape', 'bed', 'lawn'],
      builder: () => const EdgingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_equipment_rental',
      name: 'Equipment Rental',
      subtitle: 'Equipment rental cost calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['equipment', 'rental', 'skid', 'excavator', 'cost'],
      builder: () => const EquipmentRentalScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_erosion_blanket',
      name: 'Erosion Blanket',
      subtitle: 'Erosion control blanket calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['erosion', 'blanket', 'control', 'slope', 'seed'],
      builder: () => const ErosionBlanketScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fabric_coverage',
      name: 'Fabric Coverage',
      subtitle: 'Landscape fabric calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['fabric', 'landscape', 'weed', 'barrier', 'coverage'],
      builder: () => const FabricCoverageScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fence_material',
      name: 'Fence Material',
      subtitle: 'Fence material calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['fence', 'material', 'wood', 'vinyl', 'post'],
      builder: () => const FenceMaterialScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fence_post',
      name: 'Fence Post',
      subtitle: 'Fence post spacing calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['fence', 'post', 'spacing', 'concrete', 'dig'],
      builder: () => const FencePostScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fertilizer',
      name: 'Fertilizer',
      subtitle: 'Lawn fertilizer calculator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['fertilizer', 'lawn', 'nitrogen', 'npk', 'grass'],
      builder: () => const FertilizerScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fire_pit',
      name: 'Fire Pit',
      subtitle: 'Fire pit material calculator',
      icon: LucideIcons.flame,
      category: ScreenCategory.calculators,
      searchTags: ['fire', 'pit', 'stone', 'block', 'patio'],
      builder: () => const landscaping_fire_pit.FirePitScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_flagstone',
      name: 'Flagstone',
      subtitle: 'Flagstone coverage calculator',
      icon: LucideIcons.hexagon,
      category: ScreenCategory.calculators,
      searchTags: ['flagstone', 'patio', 'path', 'natural', 'stone'],
      builder: () => const FlagstoneScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fountain_pump',
      name: 'Fountain Pump',
      subtitle: 'Fountain pump sizing',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['fountain', 'pump', 'gph', 'water', 'feature'],
      builder: () => const FountainPumpScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_french_drain',
      name: 'French Drain',
      subtitle: 'French drain calculator',
      icon: LucideIcons.pipette,
      category: ScreenCategory.calculators,
      searchTags: ['french', 'drain', 'gravel', 'pipe', 'drainage'],
      builder: () => const FrenchDrainScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_frost_depth',
      name: 'Frost Depth',
      subtitle: 'Frost line depth reference',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.calculators,
      searchTags: ['frost', 'depth', 'line', 'footing', 'freeze'],
      builder: () => const FrostDepthScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fuel_usage',
      name: 'Fuel Usage',
      subtitle: 'Equipment fuel usage calculator',
      icon: LucideIcons.fuel,
      category: ScreenCategory.calculators,
      searchTags: ['fuel', 'usage', 'gas', 'equipment', 'cost'],
      builder: () => const FuelUsageScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_fungicide',
      name: 'Fungicide',
      subtitle: 'Fungicide application calculator',
      icon: LucideIcons.bug,
      category: ScreenCategory.calculators,
      searchTags: ['fungicide', 'disease', 'lawn', 'turf', 'spray'],
      builder: () => const FungicideScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_garden_path',
      name: 'Garden Path',
      subtitle: 'Garden path material calculator',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['garden', 'path', 'walkway', 'stone', 'gravel'],
      builder: () => const GardenPathScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_grading_dirt',
      name: 'Grading Dirt',
      subtitle: 'Fill dirt and grading calculator',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['grading', 'dirt', 'fill', 'cut', 'grade'],
      builder: () => const GradingDirtScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_gravel',
      name: 'Gravel',
      subtitle: 'Gravel coverage calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['gravel', 'stone', 'aggregate', 'driveway', 'path'],
      builder: () => const GravelScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_hedge_spacing',
      name: 'Hedge Spacing',
      subtitle: 'Hedge plant spacing calculator',
      icon: LucideIcons.trees,
      category: ScreenCategory.calculators,
      searchTags: ['hedge', 'spacing', 'shrub', 'privacy', 'screen'],
      builder: () => const HedgeSpacingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_herbicide',
      name: 'Herbicide',
      subtitle: 'Herbicide application calculator',
      icon: LucideIcons.sprayCan,
      category: ScreenCategory.calculators,
      searchTags: ['herbicide', 'weed', 'killer', 'spray', 'lawn'],
      builder: () => const HerbicideScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_hydroseeding',
      name: 'Hydroseeding',
      subtitle: 'Hydroseeding coverage calculator',
      icon: LucideIcons.sprayCan,
      category: ScreenCategory.calculators,
      searchTags: ['hydroseed', 'seed', 'mulch', 'spray', 'lawn'],
      builder: () => const HydroseedingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_insect_control',
      name: 'Insect Control',
      subtitle: 'Insecticide application calculator',
      icon: LucideIcons.bug,
      category: ScreenCategory.calculators,
      searchTags: ['insect', 'control', 'pest', 'grub', 'spray'],
      builder: () => const InsectControlScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_irregular_area',
      name: 'Irregular Area',
      subtitle: 'Calculate irregular shaped areas',
      icon: LucideIcons.penTool,
      category: ScreenCategory.calculators,
      searchTags: ['irregular', 'area', 'shape', 'odd', 'calculate'],
      builder: () => const IrregularAreaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_irrigation_cost',
      name: 'Irrigation Cost',
      subtitle: 'Water cost calculator',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['irrigation', 'cost', 'water', 'bill', 'usage'],
      builder: () => const IrrigationCostScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_irrigation_gpm',
      name: 'Irrigation GPM',
      subtitle: 'Irrigation flow rate calculator',
      icon: LucideIcons.gauge,
      category: ScreenCategory.calculators,
      searchTags: ['irrigation', 'gpm', 'flow', 'rate', 'sprinkler'],
      builder: () => const IrrigationGpmScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_irrigation_valve',
      name: 'Irrigation Valve',
      subtitle: 'Valve zone sizing',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['irrigation', 'valve', 'zone', 'gpm', 'flow'],
      builder: () => const IrrigationValveScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_job_profit',
      name: 'Job Profit',
      subtitle: 'Job profit margin calculator',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['job', 'profit', 'margin', 'cost', 'revenue'],
      builder: () => const JobProfitScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_labor_hours',
      name: 'Labor Hours',
      subtitle: 'Labor hours estimator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['labor', 'hours', 'time', 'estimate', 'crew'],
      builder: () => const landscaping_labor.LaborHoursScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_landscape_estimate',
      name: 'Landscape Estimate',
      subtitle: 'Project estimate calculator',
      icon: LucideIcons.calculator,
      category: ScreenCategory.calculators,
      searchTags: ['landscape', 'estimate', 'quote', 'bid', 'project'],
      builder: () => const LandscapeEstimateScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_landscape_lighting',
      name: 'Landscape Lighting',
      subtitle: 'Low voltage lighting calculator',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.calculators,
      searchTags: ['landscape', 'lighting', 'low', 'voltage', 'path'],
      builder: () => const LandscapeLightingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lawn_aeration',
      name: 'Lawn Aeration',
      subtitle: 'Lawn aeration calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['lawn', 'aeration', 'core', 'plug', 'soil'],
      builder: () => const LawnAerationScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lawn_area',
      name: 'Lawn Area',
      subtitle: 'Lawn square footage calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['lawn', 'area', 'square', 'feet', 'grass'],
      builder: () => const LawnAreaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lawn_renovation',
      name: 'Lawn Renovation',
      subtitle: 'Lawn renovation cost estimate',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['lawn', 'renovation', 'reseed', 'restore', 'grass'],
      builder: () => const LawnRenovationScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lawn_striping',
      name: 'Lawn Striping',
      subtitle: 'Lawn striping pattern calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['lawn', 'striping', 'pattern', 'mow', 'roller'],
      builder: () => const LawnStripingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_leaf_removal',
      name: 'Leaf Removal',
      subtitle: 'Leaf cleanup estimator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['leaf', 'removal', 'fall', 'cleanup', 'bag'],
      builder: () => const LeafRemovalScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lighting_voltage',
      name: 'Lighting Voltage',
      subtitle: 'Voltage drop for landscape lights',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['lighting', 'voltage', 'drop', 'wire', 'low'],
      builder: () => const LightingVoltageScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_lime',
      name: 'Lime',
      subtitle: 'Lawn lime application calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['lime', 'lawn', 'ph', 'soil', 'pelletized'],
      builder: () => const LimeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_load_weight',
      name: 'Load Weight',
      subtitle: 'Trailer load weight calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['load', 'weight', 'trailer', 'truck', 'capacity'],
      builder: () => const LoadWeightScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_mow_time',
      name: 'Mow Time',
      subtitle: 'Mowing time estimator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['mow', 'time', 'mower', 'lawn', 'estimate'],
      builder: () => const MowTimeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_mowing_time',
      name: 'Mowing Time',
      subtitle: 'Mowing time calculator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['mowing', 'time', 'lawn', 'acre', 'speed'],
      builder: () => const MowingTimeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_mulch_ring',
      name: 'Mulch Ring',
      subtitle: 'Tree mulch ring calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['mulch', 'ring', 'tree', 'circle', 'bed'],
      builder: () => const MulchRingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_mulch',
      name: 'Mulch',
      subtitle: 'Mulch coverage calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['mulch', 'bark', 'wood', 'chip', 'bed'],
      builder: () => const MulchScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_native_plants',
      name: 'Native Plants',
      subtitle: 'Native plant spacing calculator',
      icon: LucideIcons.flower2,
      category: ScreenCategory.calculators,
      searchTags: ['native', 'plants', 'spacing', 'pollinator', 'garden'],
      builder: () => const NativePlantsScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_outdoor_kitchen',
      name: 'Outdoor Kitchen',
      subtitle: 'Outdoor kitchen estimator',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.calculators,
      searchTags: ['outdoor', 'kitchen', 'grill', 'patio', 'counter'],
      builder: () => const landscaping_outdoor_kitchen.OutdoorKitchenScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_patio_layout',
      name: 'Patio Layout',
      subtitle: 'Patio design layout calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['patio', 'layout', 'design', 'paver', 'pattern'],
      builder: () => const PatioLayoutScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_paver_base',
      name: 'Paver Base',
      subtitle: 'Paver base material calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['paver', 'base', 'gravel', 'sand', 'compaction'],
      builder: () => const PaverBaseScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_paver_joint',
      name: 'Paver Joint',
      subtitle: 'Paver joint sand calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['paver', 'joint', 'sand', 'polymeric', 'sweep'],
      builder: () => const PaverJointScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_paver',
      name: 'Paver',
      subtitle: 'Paver quantity calculator',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['paver', 'patio', 'brick', 'square', 'coverage'],
      builder: () => const PaverScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pergola',
      name: 'Pergola',
      subtitle: 'Pergola material calculator',
      icon: LucideIcons.home,
      category: ScreenCategory.calculators,
      searchTags: ['pergola', 'shade', 'structure', 'patio', 'lumber'],
      builder: () => const landscaping_pergola.PergolaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_perimeter',
      name: 'Perimeter',
      subtitle: 'Perimeter calculator',
      icon: LucideIcons.square,
      category: ScreenCategory.calculators,
      searchTags: ['perimeter', 'edge', 'border', 'linear', 'feet'],
      builder: () => const PerimeterScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_ph_amendment',
      name: 'pH Amendment',
      subtitle: 'Soil pH adjustment calculator',
      icon: LucideIcons.testTube,
      category: ScreenCategory.calculators,
      searchTags: ['ph', 'amendment', 'soil', 'lime', 'sulfur'],
      builder: () => const PhAmendmentScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pillar_column',
      name: 'Pillar Column',
      subtitle: 'Stone pillar calculator',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['pillar', 'column', 'stone', 'entry', 'gate'],
      builder: () => const PillarColumnScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_plant_count',
      name: 'Plant Count',
      subtitle: 'Plant quantity calculator',
      icon: LucideIcons.flower2,
      category: ScreenCategory.calculators,
      searchTags: ['plant', 'count', 'quantity', 'spacing', 'bed'],
      builder: () => const PlantCountScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_plant_spacing',
      name: 'Plant Spacing',
      subtitle: 'Plant spacing calculator',
      icon: LucideIcons.flower2,
      category: ScreenCategory.calculators,
      searchTags: ['plant', 'spacing', 'distance', 'shrub', 'perennial'],
      builder: () => const PlantSpacingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_planter_box',
      name: 'Planter Box',
      subtitle: 'Planter box soil calculator',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['planter', 'box', 'container', 'soil', 'raised'],
      builder: () => const PlanterBoxScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_polymeric_sand',
      name: 'Polymeric Sand',
      subtitle: 'Polymeric sand calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['polymeric', 'sand', 'paver', 'joint', 'sweep'],
      builder: () => const PolymericSandScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pond_liner',
      name: 'Pond Liner',
      subtitle: 'Pond liner sizing calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['pond', 'liner', 'epdm', 'water', 'feature'],
      builder: () => const PondLinerScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pond_pump',
      name: 'Pond Pump',
      subtitle: 'Pond pump sizing calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['pond', 'pump', 'gph', 'waterfall', 'circulation'],
      builder: () => const PondPumpScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pop_up_drain',
      name: 'Pop Up Drain',
      subtitle: 'Pop up drain emitter sizing',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['pop', 'up', 'drain', 'emitter', 'downspout'],
      builder: () => const PopUpDrainScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_pricing',
      name: 'Pricing',
      subtitle: 'Service pricing calculator',
      icon: LucideIcons.dollarSign,
      category: ScreenCategory.calculators,
      searchTags: ['pricing', 'rate', 'hourly', 'service', 'charge'],
      builder: () => const PricingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_rain_barrel',
      name: 'Rain Barrel',
      subtitle: 'Rain barrel sizing calculator',
      icon: LucideIcons.cloudRain,
      category: ScreenCategory.calculators,
      searchTags: ['rain', 'barrel', 'water', 'harvest', 'collection'],
      builder: () => const RainBarrelScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_rain_garden',
      name: 'Rain Garden',
      subtitle: 'Rain garden sizing calculator',
      icon: LucideIcons.cloudRain,
      category: ScreenCategory.calculators,
      searchTags: ['rain', 'garden', 'bioretention', 'storm', 'water'],
      builder: () => const RainGardenScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_raised_bed',
      name: 'Raised Bed',
      subtitle: 'Raised bed soil calculator',
      icon: LucideIcons.box,
      category: ScreenCategory.calculators,
      searchTags: ['raised', 'bed', 'garden', 'soil', 'planter'],
      builder: () => const landscaping_raised_bed.RaisedBedScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_retaining_wall',
      name: 'Retaining Wall',
      subtitle: 'Retaining wall block calculator',
      icon: LucideIcons.building,
      category: ScreenCategory.calculators,
      searchTags: ['retaining', 'wall', 'block', 'stone', 'slope'],
      builder: () => const landscaping_retaining_wall.RetainingWallScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_rip_rap',
      name: 'Rip Rap',
      subtitle: 'Rip rap stone calculator',
      icon: LucideIcons.mountain,
      category: ScreenCategory.calculators,
      searchTags: ['rip', 'rap', 'stone', 'erosion', 'slope'],
      builder: () => const RipRapScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_river_rock',
      name: 'River Rock',
      subtitle: 'River rock coverage calculator',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.calculators,
      searchTags: ['river', 'rock', 'stone', 'decorative', 'bed'],
      builder: () => const RiverRockScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_root_barrier',
      name: 'Root Barrier',
      subtitle: 'Root barrier material calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['root', 'barrier', 'tree', 'protect', 'foundation'],
      builder: () => const RootBarrierScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_route_optimization',
      name: 'Route Optimization',
      subtitle: 'Daily route efficiency calculator',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['route', 'optimization', 'efficiency', 'stops', 'drive'],
      builder: () => const RouteOptimizationScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_scale_drawing',
      name: 'Scale Drawing',
      subtitle: 'Scale drawing calculator',
      icon: LucideIcons.ruler,
      category: ScreenCategory.calculators,
      searchTags: ['scale', 'drawing', 'plan', 'blueprint', 'measure'],
      builder: () => const ScaleDrawingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_seasonal_cleanup',
      name: 'Seasonal Cleanup',
      subtitle: 'Spring/fall cleanup estimator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['seasonal', 'cleanup', 'spring', 'fall', 'debris'],
      builder: () => const SeasonalCleanupScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_seat_wall',
      name: 'Seat Wall',
      subtitle: 'Seat wall material calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['seat', 'wall', 'patio', 'stone', 'block'],
      builder: () => const SeatWallScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_seed_rate',
      name: 'Seed Rate',
      subtitle: 'Grass seed rate calculator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['seed', 'rate', 'grass', 'lawn', 'overseed'],
      builder: () => const SeedRateScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_seed',
      name: 'Seed',
      subtitle: 'Grass seed calculator',
      icon: LucideIcons.leaf,
      category: ScreenCategory.calculators,
      searchTags: ['seed', 'grass', 'lawn', 'pound', 'coverage'],
      builder: () => const SeedScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_service_area',
      name: 'Service Area',
      subtitle: 'Service area calculation',
      icon: LucideIcons.mapPin,
      category: ScreenCategory.calculators,
      searchTags: ['service', 'area', 'radius', 'miles', 'coverage'],
      builder: () => const ServiceAreaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_shrub_spacing',
      name: 'Shrub Spacing',
      subtitle: 'Shrub spacing calculator',
      icon: LucideIcons.trees,
      category: ScreenCategory.calculators,
      searchTags: ['shrub', 'spacing', 'plant', 'hedge', 'row'],
      builder: () => const ShrubSpacingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_slope_calculator',
      name: 'Slope Calculator',
      subtitle: 'Calculate slope percentage',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['slope', 'grade', 'rise', 'run', 'percent'],
      builder: () => const SlopeCalculatorScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_slope_grade',
      name: 'Slope Grade',
      subtitle: 'Slope grading calculator',
      icon: LucideIcons.trendingUp,
      category: ScreenCategory.calculators,
      searchTags: ['slope', 'grade', 'drainage', 'percent', 'ratio'],
      builder: () => const SlopeGradeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_snow_removal',
      name: 'Snow Removal',
      subtitle: 'Snow removal estimator',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.calculators,
      searchTags: ['snow', 'removal', 'plow', 'salt', 'winter'],
      builder: () => const SnowRemovalScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_sod',
      name: 'Sod',
      subtitle: 'Sod coverage calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['sod', 'turf', 'grass', 'roll', 'pallet'],
      builder: () => const SodScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_soil_test',
      name: 'Soil Test',
      subtitle: 'Soil test interpretation',
      icon: LucideIcons.testTube,
      category: ScreenCategory.calculators,
      searchTags: ['soil', 'test', 'ph', 'nutrient', 'analysis'],
      builder: () => const SoilTestScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_sprinkler_head',
      name: 'Sprinkler Head',
      subtitle: 'Sprinkler head spacing calculator',
      icon: LucideIcons.droplets,
      category: ScreenCategory.calculators,
      searchTags: ['sprinkler', 'head', 'spacing', 'coverage', 'zone'],
      builder: () => const SprinklerHeadScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_sprinkler_runtime',
      name: 'Sprinkler Runtime',
      subtitle: 'Sprinkler run time calculator',
      icon: LucideIcons.clock,
      category: ScreenCategory.calculators,
      searchTags: ['sprinkler', 'runtime', 'water', 'schedule', 'zone'],
      builder: () => const SprinklerRuntimeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_sprinkler_zone',
      name: 'Sprinkler Zone',
      subtitle: 'Sprinkler zone design',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.calculators,
      searchTags: ['sprinkler', 'zone', 'design', 'gpm', 'heads'],
      builder: () => const SprinklerZoneScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_stair_step',
      name: 'Stair Step',
      subtitle: 'Landscape stair calculator',
      icon: LucideIcons.chevronsUp,
      category: ScreenCategory.calculators,
      searchTags: ['stair', 'step', 'rise', 'run', 'landscape'],
      builder: () => const StairStepScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_stairs_outdoor',
      name: 'Stairs Outdoor',
      subtitle: 'Outdoor stair calculator',
      icon: LucideIcons.chevronsUp,
      category: ScreenCategory.calculators,
      searchTags: ['stairs', 'outdoor', 'step', 'stone', 'patio'],
      builder: () => const StairsOutdoorScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_stepping_stone',
      name: 'Stepping Stone',
      subtitle: 'Stepping stone calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['stepping', 'stone', 'path', 'walkway', 'flagstone'],
      builder: () => const SteppingStoneScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_sump_pump',
      name: 'Sump Pump',
      subtitle: 'Sump pump sizing',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.calculators,
      searchTags: ['sump', 'pump', 'basement', 'water', 'gph'],
      builder: () => const landscaping_sump.SumpPumpScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_swale',
      name: 'Swale',
      subtitle: 'Drainage swale calculator',
      icon: LucideIcons.waves,
      category: ScreenCategory.calculators,
      searchTags: ['swale', 'drainage', 'grade', 'water', 'channel'],
      builder: () => const SwaleScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_topsoil',
      name: 'Topsoil',
      subtitle: 'Topsoil coverage calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['topsoil', 'soil', 'yard', 'cubic', 'coverage'],
      builder: () => const TopsoilScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_trailer_capacity',
      name: 'Trailer Capacity',
      subtitle: 'Trailer load capacity calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['trailer', 'capacity', 'load', 'weight', 'volume'],
      builder: () => const TrailerCapacityScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_transformer_sizing',
      name: 'Transformer Sizing',
      subtitle: 'Low voltage transformer sizing',
      icon: LucideIcons.zap,
      category: ScreenCategory.calculators,
      searchTags: ['transformer', 'sizing', 'low', 'voltage', 'lighting'],
      builder: () => const landscaping_transformer.TransformerSizingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_diameter',
      name: 'Tree Diameter',
      subtitle: 'Tree caliper and DBH calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'diameter', 'caliper', 'dbh', 'trunk'],
      builder: () => const TreeDiameterScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_fertilizer',
      name: 'Tree Fertilizer',
      subtitle: 'Tree fertilizer calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'fertilizer', 'spikes', 'feed', 'nitrogen'],
      builder: () => const TreeFertilizerScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_planting',
      name: 'Tree Planting',
      subtitle: 'Tree planting hole calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'planting', 'hole', 'root', 'ball'],
      builder: () => const TreePlantingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_removal',
      name: 'Tree Removal',
      subtitle: 'Tree removal cost estimator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'removal', 'stump', 'cost', 'estimate'],
      builder: () => const TreeRemovalScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_ring',
      name: 'Tree Ring',
      subtitle: 'Tree ring mulch calculator',
      icon: LucideIcons.circle,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'ring', 'mulch', 'circle', 'bed'],
      builder: () => const TreeRingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_tree_staking',
      name: 'Tree Staking',
      subtitle: 'Tree staking material calculator',
      icon: LucideIcons.treePine,
      category: ScreenCategory.calculators,
      searchTags: ['tree', 'staking', 'support', 'stake', 'strap'],
      builder: () => const TreeStakingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_trellis',
      name: 'Trellis',
      subtitle: 'Trellis material calculator',
      icon: LucideIcons.grid,
      category: ScreenCategory.calculators,
      searchTags: ['trellis', 'vine', 'lattice', 'support', 'garden'],
      builder: () => const landscaping_trellis.TrellisScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_triangle_area',
      name: 'Triangle Area',
      subtitle: 'Triangle area calculator',
      icon: LucideIcons.triangle,
      category: ScreenCategory.calculators,
      searchTags: ['triangle', 'area', 'base', 'height', 'shape'],
      builder: () => const TriangleAreaScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_turf_conversion',
      name: 'Turf Conversion',
      subtitle: 'Lawn to landscape conversion',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.calculators,
      searchTags: ['turf', 'conversion', 'lawn', 'xeriscape', 'replace'],
      builder: () => const TurfConversionScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_turf_paint',
      name: 'Turf Paint',
      subtitle: 'Turf paint coverage calculator',
      icon: LucideIcons.paintBucket,
      category: ScreenCategory.calculators,
      searchTags: ['turf', 'paint', 'colorant', 'lawn', 'dye'],
      builder: () => const TurfPaintScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_wall_cap',
      name: 'Wall Cap',
      subtitle: 'Wall cap stone calculator',
      icon: LucideIcons.alignJustify,
      category: ScreenCategory.calculators,
      searchTags: ['wall', 'cap', 'stone', 'retaining', 'finish'],
      builder: () => const WallCapScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_water_usage',
      name: 'Water Usage',
      subtitle: 'Irrigation water usage calculator',
      icon: LucideIcons.droplet,
      category: ScreenCategory.calculators,
      searchTags: ['water', 'usage', 'irrigation', 'gallons', 'lawn'],
      builder: () => const WaterUsageScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_weed_barrier',
      name: 'Weed Barrier',
      subtitle: 'Weed barrier fabric calculator',
      icon: LucideIcons.layers,
      category: ScreenCategory.calculators,
      searchTags: ['weed', 'barrier', 'fabric', 'landscape', 'mulch'],
      builder: () => const WeedBarrierScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_weed_control',
      name: 'Weed Control',
      subtitle: 'Weed control application calculator',
      icon: LucideIcons.sprayCan,
      category: ScreenCategory.calculators,
      searchTags: ['weed', 'control', 'pre', 'emergent', 'spray'],
      builder: () => const WeedControlScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_wheelbarrow_trips',
      name: 'Wheelbarrow Trips',
      subtitle: 'Wheelbarrow load calculator',
      icon: LucideIcons.truck,
      category: ScreenCategory.calculators,
      searchTags: ['wheelbarrow', 'trips', 'load', 'material', 'cubic'],
      builder: () => const WheelbarrowTripsScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_xeriscape',
      name: 'Xeriscape',
      subtitle: 'Xeriscape design calculator',
      icon: LucideIcons.sun,
      category: ScreenCategory.calculators,
      searchTags: ['xeriscape', 'drought', 'tolerant', 'water', 'wise'],
      builder: () => const XeriscapeScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscaping_yard_waste',
      name: 'Yard Waste',
      subtitle: 'Yard waste disposal calculator',
      icon: LucideIcons.trash,
      category: ScreenCategory.calculators,
      searchTags: ['yard', 'waste', 'disposal', 'debris', 'dump'],
      builder: () => const YardWasteScreen(),
      trade: 'landscaping',
    ),
  ];

  // Combined calculators list (all 15 trades)
  static List<ScreenEntry> get calculators => [
    ...electricalCalculators,
    ...plumbingCalculators,
    ...hvacCalculators,
    ...solarCalculators,
    ...roofingCalculators,
    ...gcCalculators,
    ...remodelerCalculators,
    ...landscapingCalculators,
    ...AutoCalculatorEntries.autoCalculators,      // 195 auto mechanic calculators
    ...WeldingCalculatorEntries.weldingCalculators, // 53 welding calculators
    ...PoolCalculatorEntries.poolCalculators,       // 51 pool/spa calculators
  ];

  // ELECTRICAL WIRING DIAGRAMS (23)
  static final List<ScreenEntry> electricalDiagrams = [
    ScreenEntry(
      id: 'single_pole_switch',
      name: 'Single Pole Switch',
      subtitle: 'Basic switch wiring',
      icon: Icons.toggle_on_outlined,
      category: ScreenCategory.diagrams,
      searchTags: ['switch', 'single pole', 'light'],
      builder: () => const SinglePoleSwitchScreen(),
    ),
    ScreenEntry(
      id: 'three_way_switch',
      name: '3-Way Switch',
      subtitle: '3-way switch configurations',
      icon: Icons.compare_arrows,
      category: ScreenCategory.diagrams,
      searchTags: ['3-way', 'three way', 'switch', 'traveler'],
      builder: () => const ThreeWaySwitchScreen(),
    ),
    ScreenEntry(
      id: 'four_way_switch',
      name: '4-Way Switch',
      subtitle: '4-way switch configurations',
      icon: Icons.swap_horiz,
      category: ScreenCategory.diagrams,
      searchTags: ['4-way', 'four way', 'switch'],
      builder: () => const FourWaySwitchScreen(),
    ),
    ScreenEntry(
      id: 'dimmer_switch',
      name: 'Dimmer Switch',
      subtitle: 'Single-pole and 3-way dimmer wiring',
      icon: Icons.brightness_6,
      category: ScreenCategory.diagrams,
      searchTags: ['dimmer', 'switch', 'led'],
      builder: () => const DimmerSwitchScreen(),
    ),
    ScreenEntry(
      id: 'gfci_wiring',
      name: 'GFCI Wiring',
      subtitle: 'GFCI wiring, LINE vs LOAD',
      icon: Icons.electrical_services,
      category: ScreenCategory.diagrams,
      searchTags: ['gfci', 'ground fault', 'line', 'load'],
      builder: () => const GfciWiringScreen(),
    ),
    ScreenEntry(
      id: 'split_receptacle',
      name: 'Split Receptacle',
      subtitle: 'Split (half-hot) receptacle wiring',
      icon: Icons.power,
      category: ScreenCategory.diagrams,
      searchTags: ['split', 'receptacle', 'half hot'],
      builder: () => const SplitReceptacleScreen(),
    ),
    ScreenEntry(
      id: 'outlet_240v',
      name: '240V Outlet',
      subtitle: '240V outlet wiring (dryer, range, welder)',
      icon: Icons.outlet,
      category: ScreenCategory.diagrams,
      searchTags: ['240v', 'outlet', 'dryer', 'range', 'welder'],
      builder: () => const Outlet240VScreen(),
    ),
    ScreenEntry(
      id: 'ceiling_fan',
      name: 'Ceiling Fan',
      subtitle: 'Fan/light combo wiring',
      icon: Icons.air,
      category: ScreenCategory.diagrams,
      searchTags: ['ceiling fan', 'fan', 'light'],
      builder: () => const CeilingFanScreen(),
    ),
    ScreenEntry(
      id: 'recessed_lighting',
      name: 'Recessed Lighting',
      subtitle: 'Daisy chain, IC ratings, spacing',
      icon: Icons.highlight,
      category: ScreenCategory.diagrams,
      searchTags: ['recessed', 'can light', 'ic', 'daisy chain'],
      builder: () => const RecessedLightingScreen(),
    ),
    ScreenEntry(
      id: 'under_cabinet',
      name: 'Under Cabinet',
      subtitle: 'Under-cabinet LED wiring options',
      icon: Icons.countertops,
      category: ScreenCategory.diagrams,
      searchTags: ['under cabinet', 'led', 'kitchen'],
      builder: () => const UnderCabinetScreen(),
    ),
    ScreenEntry(
      id: 'photocell_timer',
      name: 'Photocell & Timer',
      subtitle: 'Photocell and timer switch wiring',
      icon: Icons.wb_twilight,
      category: ScreenCategory.diagrams,
      searchTags: ['photocell', 'timer', 'dusk', 'dawn'],
      builder: () => const PhotocellTimerScreen(),
    ),
    ScreenEntry(
      id: 'smoke_detector',
      name: 'Smoke Detectors',
      subtitle: 'Interconnected smoke/CO detector wiring',
      icon: Icons.smoke_free,
      category: ScreenCategory.diagrams,
      searchTags: ['smoke', 'detector', 'co', 'interconnected'],
      builder: () => const SmokeDetectorScreen(),
    ),
    ScreenEntry(
      id: 'thermostat_wiring',
      name: 'Thermostat Wiring',
      subtitle: 'HVAC thermostat wire colors',
      icon: Icons.thermostat,
      category: ScreenCategory.diagrams,
      searchTags: ['thermostat', 'hvac', 'wire color'],
      builder: () => const ThermostatWiringScreen(),
    ),
    ScreenEntry(
      id: 'low_voltage',
      name: 'Low Voltage',
      subtitle: 'Doorbell, thermostat, landscape, sprinkler',
      icon: Icons.doorbell,
      category: ScreenCategory.diagrams,
      searchTags: ['low voltage', 'doorbell', 'landscape'],
      builder: () => const LowVoltageScreen(),
    ),
    ScreenEntry(
      id: 'sub_panel',
      name: 'Sub-Panel',
      subtitle: 'Sub-panel wiring (N/G separation)',
      icon: Icons.dashboard,
      category: ScreenCategory.diagrams,
      searchTags: ['sub panel', 'subpanel', 'neutral', 'ground'],
      builder: () => const SubPanelScreen(),
    ),
    ScreenEntry(
      id: 'garage_subpanel',
      name: 'Garage Sub-Panel',
      subtitle: 'Detached garage sub-panel (4-wire)',
      icon: Icons.garage,
      category: ScreenCategory.diagrams,
      searchTags: ['garage', 'detached', 'sub panel', '4-wire'],
      builder: () => const GarageSubPanelScreen(),
    ),
    ScreenEntry(
      id: 'service_entrance_diagram',
      name: 'Service Entrance',
      subtitle: 'Overhead/underground service diagrams',
      icon: Icons.power_input,
      category: ScreenCategory.diagrams,
      searchTags: ['service', 'entrance', 'overhead', 'underground'],
      builder: () => const diag_service.ServiceEntranceScreen(),
    ),
    ScreenEntry(
      id: 'grounding_electrode',
      name: 'Grounding Electrode',
      subtitle: 'Grounding electrode system diagram',
      icon: Icons.settings_input_antenna,
      category: ScreenCategory.diagrams,
      searchTags: ['grounding', 'electrode', 'rod', 'ufer'],
      builder: () => const GroundingElectrodeScreen(),
    ),
    ScreenEntry(
      id: 'transfer_switch',
      name: 'Transfer Switch',
      subtitle: 'Manual and automatic transfer switch',
      icon: Icons.swap_vert,
      category: ScreenCategory.diagrams,
      searchTags: ['transfer', 'switch', 'generator', 'ats'],
      builder: () => const TransferSwitchScreen(),
    ),
    ScreenEntry(
      id: 'motor_starter',
      name: 'Motor Starter',
      subtitle: 'Motor starter/contactor wiring',
      icon: Icons.settings,
      category: ScreenCategory.diagrams,
      searchTags: ['motor', 'starter', 'contactor', 'overload'],
      builder: () => const diag_motor.MotorStarterScreen(),
    ),
    ScreenEntry(
      id: 'vfd_wiring',
      name: 'VFD Wiring',
      subtitle: 'Variable frequency drive wiring',
      icon: Icons.speed,
      category: ScreenCategory.diagrams,
      searchTags: ['vfd', 'variable frequency', 'drive'],
      builder: () => const VfdWiringScreen(),
    ),
    ScreenEntry(
      id: 'three_phase_basics',
      name: '3-Phase Basics',
      subtitle: '3Φ Wye/Delta, colors, formulas',
      icon: Icons.change_history,
      category: ScreenCategory.diagrams,
      searchTags: ['3 phase', 'three phase', 'wye', 'delta'],
      builder: () => const ThreePhaseBasicsScreen(),
    ),
    ScreenEntry(
      id: 'pool_spa_wiring',
      name: 'Pool & Spa',
      subtitle: 'NEC 680 pool/spa bonding and wiring',
      icon: Icons.pool,
      category: ScreenCategory.diagrams,
      searchTags: ['pool', 'spa', 'hot tub', 'bonding', '680'],
      builder: () => const PoolSpaWiringScreen(),
    ),
  ];

  // Combined diagrams list (all 11 trades)
  static List<ScreenEntry> get diagrams => [
    ...electricalDiagrams,                              // 23 electrical wiring diagrams
    ...PlumbingDiagramEntries.plumbingDiagrams,         // 15 plumbing diagrams
    ...HvacDiagramEntries.hvacDiagrams,                 // 12 hvac diagrams
    ...SolarDiagramEntries.solarDiagrams,               // 11 solar diagrams
    ...RoofingDiagramEntries.roofingDiagrams,           // 8 roofing diagrams
    ...GcDiagramEntries.gcDiagrams,                     // 6 gc diagrams
    ...RemodelerDiagramEntries.remodelerDiagrams,       // 10 remodeler diagrams
    ...LandscapingDiagramEntries.landscapingDiagrams,   // 7 landscaping diagrams
    ...AutoDiagramEntries.autoDiagrams,                 // 7 auto mechanic diagrams
    ...WeldingDiagramEntries.weldingDiagrams,           // 5 welding diagrams
    ...PoolDiagramEntries.poolDiagrams,                 // 7 pool/spa diagrams
  ];

  // REFERENCE (21)
  static final List<ScreenEntry> reference = [
    ScreenEntry(
      id: 'wire_color_code',
      name: 'Wire Color Codes',
      subtitle: 'US, 480V, DC, IEC standards',
      icon: Icons.palette,
      category: ScreenCategory.reference,
      searchTags: ['wire', 'color', 'code', 'hot', 'neutral'],
      builder: () => const WireColorCodeScreen(),
    ),
    ScreenEntry(
      id: 'ampacity_table',
      name: 'Ampacity Table 310.16',
      subtitle: 'Conductor ampacity by temp rating',
      icon: Icons.table_chart,
      category: ScreenCategory.reference,
      searchTags: ['ampacity', 'table', '310.16', 'conductor'],
      builder: () => const AmpacityTableScreen(),
    ),
    ScreenEntry(
      id: 'conduit_dimensions',
      name: 'Conduit Dimensions',
      subtitle: 'Chapter 9 Table 4 - all types',
      icon: Icons.circle_outlined,
      category: ScreenCategory.reference,
      searchTags: ['conduit', 'dimension', 'size', 'emt', 'pvc'],
      builder: () => const ConduitDimensionsScreen(),
    ),
    ScreenEntry(
      id: 'wire_properties',
      name: 'Wire Properties',
      subtitle: 'Chapter 9 Table 8 - area, resistance',
      icon: Icons.cable,
      category: ScreenCategory.reference,
      searchTags: ['wire', 'properties', 'area', 'resistance'],
      builder: () => const WirePropertiesScreen(),
    ),
    ScreenEntry(
      id: 'formulas',
      name: 'Electrical Formulas',
      subtitle: 'Power, voltage drop, motors',
      icon: Icons.functions,
      category: ScreenCategory.reference,
      searchTags: ['formula', 'equation', 'power', 'ohm'],
      builder: () => const FormulasScreen(),
    ),
    ScreenEntry(
      id: 'gfci_afci',
      name: 'GFCI / AFCI',
      subtitle: 'NEC 210.8 & 210.12 locations',
      icon: Icons.security,
      category: ScreenCategory.reference,
      searchTags: ['gfci', 'afci', '210.8', '210.12'],
      builder: () => const GfciAfciScreen(),
    ),
    ScreenEntry(
      id: 'grounding_vs_bonding',
      name: 'Grounding vs Bonding',
      subtitle: 'Grounding vs bonding explained',
      icon: Icons.compare,
      category: ScreenCategory.reference,
      searchTags: ['grounding', 'bonding', 'difference'],
      builder: () => const GroundingVsBondingScreen(),
    ),
    ScreenEntry(
      id: 'outlet_config',
      name: 'NEMA Configurations',
      subtitle: 'NEMA outlet configurations',
      icon: Icons.outlet,
      category: ScreenCategory.reference,
      searchTags: ['nema', 'outlet', 'configuration', 'plug'],
      builder: () => const OutletConfigScreen(),
    ),
    ScreenEntry(
      id: 'state_adoption',
      name: 'State NEC Adoption',
      subtitle: 'Which code version by state',
      icon: Icons.map_outlined,
      category: ScreenCategory.reference,
      searchTags: ['state', 'nec', 'adoption', 'code', 'version'],
      builder: () => const StateAdoptionScreen(),
    ),
    ScreenEntry(
      id: 'nec_changes',
      name: 'NEC Changes',
      subtitle: 'Recent NEC code changes',
      icon: Icons.new_releases_outlined,
      category: ScreenCategory.reference,
      searchTags: ['nec', 'changes', 'new', '2023', '2020'],
      builder: () => const NecChangesScreen(),
    ),
    ScreenEntry(
      id: 'nec_navigation',
      name: 'NEC Navigation',
      subtitle: 'How to navigate the code book',
      icon: Icons.menu_book,
      category: ScreenCategory.reference,
      searchTags: ['nec', 'navigation', 'code', 'book', 'article'],
      builder: () => const NECNavigationScreen(),
    ),
    ScreenEntry(
      id: 'hazardous_locations',
      name: 'Hazardous Locations',
      subtitle: 'Class/Division/Group/Zone system',
      icon: Icons.warning_amber,
      category: ScreenCategory.reference,
      searchTags: ['hazardous', 'class', 'division', 'group', 'zone'],
      builder: () => const HazardousLocationsScreen(),
    ),
    ScreenEntry(
      id: 'motor_nameplate',
      name: 'Motor Nameplate',
      subtitle: 'Reading motor nameplates',
      icon: Icons.badge,
      category: ScreenCategory.reference,
      searchTags: ['motor', 'nameplate', 'hp', 'fla', 'frame'],
      builder: () => const MotorNameplateScreen(),
    ),
    ScreenEntry(
      id: 'common_mistakes',
      name: 'Common Mistakes',
      subtitle: '15 common code violations',
      icon: Icons.error_outline,
      category: ScreenCategory.reference,
      searchTags: ['mistake', 'violation', 'code', 'common'],
      builder: () => const CommonMistakesScreen(),
    ),
    ScreenEntry(
      id: 'troubleshooting',
      name: 'Troubleshooting',
      subtitle: 'Common problems and solutions',
      icon: Icons.build_outlined,
      category: ScreenCategory.reference,
      searchTags: ['troubleshoot', 'problem', 'solution', 'fix'],
      builder: () => const TroubleshootingScreen(),
    ),
    ScreenEntry(
      id: 'aluminum_wiring',
      name: 'Aluminum Wiring',
      subtitle: 'Aluminum branch circuit hazards',
      icon: Icons.warning,
      category: ScreenCategory.reference,
      searchTags: ['aluminum', 'wiring', 'hazard', 'pigtail'],
      builder: () => const AluminumWiringScreen(),
    ),
    ScreenEntry(
      id: 'knob_tube',
      name: 'Knob & Tube',
      subtitle: 'K&T identification and hazards',
      icon: Icons.history,
      category: ScreenCategory.reference,
      searchTags: ['knob', 'tube', 'old', 'wiring', 'hazard'],
      builder: () => const KnobTubeScreen(),
    ),
    ScreenEntry(
      id: 'permit_checklist',
      name: 'Permit Checklist',
      subtitle: 'Permit process and inspection',
      icon: Icons.fact_check,
      category: ScreenCategory.reference,
      searchTags: ['permit', 'checklist', 'inspection'],
      builder: () => const PermitChecklistScreen(),
    ),
    ScreenEntry(
      id: 'rough_in_checklist',
      name: 'Rough-In Checklist',
      subtitle: 'Rough-in inspection prep',
      icon: Icons.checklist,
      category: ScreenCategory.reference,
      searchTags: ['rough in', 'checklist', 'inspection'],
      builder: () => const RoughInChecklistScreen(),
    ),
    ScreenEntry(
      id: 'tool_list',
      name: 'Tool List',
      subtitle: 'Complete electrician tool list',
      icon: Icons.handyman,
      category: ScreenCategory.reference,
      searchTags: ['tool', 'list', 'equipment'],
      builder: () => const ToolListScreen(),
    ),
    ScreenEntry(
      id: 'apprentice_guide',
      name: 'Apprentice Guide',
      subtitle: 'Career paths, tips, skill progression',
      icon: Icons.school,
      category: ScreenCategory.reference,
      searchTags: ['apprentice', 'guide', 'career', 'journeyman'],
      builder: () => const ApprenticeGuideScreen(),
    ),
  ];

  // TABLES (9)
  static final List<ScreenEntry> tables = [
    ScreenEntry(
      id: 'awg_reference',
      name: 'AWG Reference',
      subtitle: 'AWG sizes, kcmil, diameter, area',
      icon: Icons.straighten,
      category: ScreenCategory.tables,
      searchTags: ['awg', 'gauge', 'kcmil', 'diameter'],
      builder: () => const AWGReferenceScreen(),
    ),
    ScreenEntry(
      id: 'box_fill_table',
      name: 'Box Fill Table',
      subtitle: 'NEC 314.16 box volumes',
      icon: Icons.grid_on,
      category: ScreenCategory.tables,
      searchTags: ['box', 'fill', 'table', 'volume'],
      builder: () => const BoxFillTableScreen(),
    ),
    ScreenEntry(
      id: 'breaker_sizing_table',
      name: 'Breaker Sizing',
      subtitle: 'Common circuits, wire/breaker matching',
      icon: Icons.toggle_on,
      category: ScreenCategory.tables,
      searchTags: ['breaker', 'sizing', 'wire', 'circuit'],
      builder: () => const BreakerSizingTableScreen(),
    ),
    ScreenEntry(
      id: 'conduit_bend_multipliers',
      name: 'Bend Multipliers',
      subtitle: 'Offset multipliers, shrinkage',
      icon: Icons.turn_right,
      category: ScreenCategory.tables,
      searchTags: ['bend', 'multiplier', 'shrinkage', 'offset'],
      builder: () => const ConduitBendMultipliersScreen(),
    ),
    ScreenEntry(
      id: 'derating_table',
      name: 'Derating Table',
      subtitle: 'Conductor derating factors',
      icon: Icons.trending_down,
      category: ScreenCategory.tables,
      searchTags: ['derating', 'factor', 'temperature'],
      builder: () => const DeratingTableScreen(),
    ),
    ScreenEntry(
      id: 'grounding_table',
      name: 'Grounding Table',
      subtitle: 'GEC and EGC sizing tables',
      icon: Icons.table_rows,
      category: ScreenCategory.tables,
      searchTags: ['grounding', 'table', 'gec', 'egc'],
      builder: () => const GroundingTableScreen(),
    ),
    ScreenEntry(
      id: 'motor_fla_table',
      name: 'Motor FLA Table',
      subtitle: '1Φ and 3Φ motor FLA, code letters',
      icon: Icons.table_chart,
      category: ScreenCategory.tables,
      searchTags: ['motor', 'fla', 'table', 'hp'],
      builder: () => const MotorFLATableScreen(),
    ),
    ScreenEntry(
      id: 'raceway_fill_table',
      name: 'Raceway Fill Table',
      subtitle: 'EMT/PVC fill tables, wire areas',
      icon: Icons.view_column,
      category: ScreenCategory.tables,
      searchTags: ['raceway', 'fill', 'emt', 'pvc'],
      builder: () => const RacewayFillTableScreen(),
    ),
    ScreenEntry(
      id: 'transformer_fla_table',
      name: 'Transformer FLA',
      subtitle: 'Transformer FLA by kVA',
      icon: Icons.transform,
      category: ScreenCategory.tables,
      searchTags: ['transformer', 'fla', 'kva'],
      builder: () => const TransformerFlaTableScreen(),
    ),
  ];

  // OTHER (5)
  static final List<ScreenEntry> other = [
    ScreenEntry(
      id: 'exam_prep',
      name: 'Exam Prep',
      subtitle: '1200+ Journeyman & Master questions',
      icon: Icons.school,
      category: ScreenCategory.other,
      searchTags: ['exam', 'test', 'quiz', 'journeyman', 'master', 'license', 'study', 'practice'],
      builder: () => const ExamPrepHubScreen(),
    ),
    ScreenEntry(
      id: 'field_scan',
      name: 'Field Scan',
      subtitle: 'AI-powered equipment analysis',
      icon: Icons.camera_alt,
      category: ScreenCategory.other,
      searchTags: ['ai', 'scan', 'camera', 'panel', 'nameplate', 'wire', 'violation', 'photo'],
      builder: () => const AIScannerScreen(),
    ),
    ScreenEntry(
      id: 'nema_config',
      name: 'NEMA Enclosures',
      subtitle: 'Complete NEMA enclosure chart',
      icon: Icons.inventory_2_outlined,
      category: ScreenCategory.other,
      searchTags: ['nema', 'enclosure', 'rating', 'weatherproof'],
      builder: () => const NemaConfigScreen(),
    ),
    ScreenEntry(
      id: 'electrical_safety',
      name: 'Electrical Safety',
      subtitle: 'Arc flash, LOTO, PPE',
      icon: Icons.health_and_safety,
      category: ScreenCategory.other,
      searchTags: ['safety', 'arc flash', 'loto', 'ppe'],
      builder: () => const ElectricalSafetyScreen(),
    ),
    ScreenEntry(
      id: 'blueprint_symbols',
      name: 'Blueprint Symbols',
      subtitle: 'Electrical blueprint symbols',
      icon: Icons.architecture,
      category: ScreenCategory.other,
      searchTags: ['blueprint', 'symbol', 'drawing', 'schematic'],
      builder: () => const BlueprintSymbolsScreen(),
    ),
  ];

  /// All screens in the app
  static List<ScreenEntry> get all => [
    ...calculators,
    ...diagrams,
    ...reference,
    ...tables,
    ...other,
  ];

  /// Get screens by category
  static List<ScreenEntry> byCategory(ScreenCategory category) {
    switch (category) {
      case ScreenCategory.calculators:
        return calculators;
      case ScreenCategory.diagrams:
        return diagrams;
      case ScreenCategory.reference:
        return reference;
      case ScreenCategory.tables:
        return tables;
      case ScreenCategory.other:
        return other;
    }
  }

  /// Get calculators by trade
  static List<ScreenEntry> calculatorsByTrade(String trade) {
    return calculators.where((c) => c.trade == trade).toList();
  }

  /// Get diagrams by trade
  static List<ScreenEntry> diagramsByTrade(String trade) {
    return diagrams.where((d) => d.trade == trade).toList();
  }

  /// Search screens by query
  static List<ScreenEntry> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase().trim();
    return all.where((screen) {
      if (screen.name.toLowerCase().contains(q)) return true;
      if (screen.subtitle.toLowerCase().contains(q)) return true;
      if (screen.trade?.toLowerCase().contains(q) ?? false) return true;
      for (final tag in screen.searchTags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  /// Get screen by ID
  static ScreenEntry? byId(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Total screen count
  static int get totalCount => all.length;

  /// Calculator counts by trade
  static int get electricalCount => electricalCalculators.length;
  static int get plumbingCount => plumbingCalculators.length;
  static int get hvacCount => hvacCalculators.length;
  static int get solarCount => solarCalculators.length;
}
