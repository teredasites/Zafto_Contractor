import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// HVAC DIAGRAM IMPORTS (12 screens)
// ============================================================================
import '../screens/diagrams/hvac/forced_air_system_screen.dart';
import '../screens/diagrams/hvac/refrigeration_cycle_screen.dart';
import '../screens/diagrams/hvac/heat_pump_screen.dart';
import '../screens/diagrams/hvac/ductwork_sizing_screen.dart';
import '../screens/diagrams/hvac/thermostat_wiring_screen.dart' as hvac_thermo;
import '../screens/diagrams/hvac/combustion_air_screen.dart';
import '../screens/diagrams/hvac/condensate_drainage_screen.dart';
import '../screens/diagrams/hvac/mini_split_screen.dart';
import '../screens/diagrams/hvac/furnace_venting_screen.dart';
import '../screens/diagrams/hvac/ventilation_hrv_erv_screen.dart';
import '../screens/diagrams/hvac/load_calculation_screen.dart';
import '../screens/diagrams/hvac/zoning_systems_screen.dart';

// ============================================================================
// HVAC DIAGRAM ENTRIES (12)
// ============================================================================
class HvacDiagramEntries {
  HvacDiagramEntries._();

  static final List<ScreenEntry> hvacDiagrams = [
    ScreenEntry(
      id: 'forced_air_system',
      name: 'Forced Air System',
      subtitle: 'Heating & cooling airflow',
      icon: LucideIcons.wind,
      category: ScreenCategory.diagrams,
      searchTags: ['forced air', 'furnace', 'ac', 'ductwork', 'airflow'],
      builder: () => const ForcedAirSystemScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'refrigeration_cycle',
      name: 'Refrigeration Cycle',
      subtitle: 'AC & heat pump cycle',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.diagrams,
      searchTags: ['refrigeration', 'cycle', 'compressor', 'evaporator', 'condenser'],
      builder: () => const RefrigerationCycleScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'hvac_heat_pump',
      name: 'Heat Pump',
      subtitle: 'Heating & cooling modes',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.diagrams,
      searchTags: ['heat pump', 'reversing', 'defrost', 'auxiliary', 'cop'],
      builder: () => const HeatPumpScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'ductwork_sizing',
      name: 'Ductwork Sizing',
      subtitle: 'CFM, velocity & friction',
      icon: LucideIcons.ruler,
      category: ScreenCategory.diagrams,
      searchTags: ['duct', 'sizing', 'cfm', 'velocity', 'friction', 'supply'],
      builder: () => const DuctworkSizingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'hvac_thermostat_wiring',
      name: 'Thermostat Wiring',
      subtitle: 'Wire colors & terminals',
      icon: LucideIcons.cpu,
      category: ScreenCategory.diagrams,
      searchTags: ['thermostat', 'wire', 'color', 'terminal', 'r', 'c', 'y', 'g', 'w'],
      builder: () => const hvac_thermo.ThermostatWiringScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'combustion_air',
      name: 'Combustion Air',
      subtitle: 'Requirements for gas appliances',
      icon: LucideIcons.flame,
      category: ScreenCategory.diagrams,
      searchTags: ['combustion', 'air', 'louver', 'opening', 'makeup'],
      builder: () => const CombustionAirScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'condensate_drainage',
      name: 'Condensate Drainage',
      subtitle: 'Drain lines & traps',
      icon: LucideIcons.droplet,
      category: ScreenCategory.diagrams,
      searchTags: ['condensate', 'drain', 'trap', 'pump', 'overflow'],
      builder: () => const CondensateDrainageScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'mini_split',
      name: 'Mini Split',
      subtitle: 'Ductless system installation',
      icon: LucideIcons.airVent,
      category: ScreenCategory.diagrams,
      searchTags: ['mini split', 'ductless', 'lineset', 'indoor', 'outdoor'],
      builder: () => const MiniSplitScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'furnace_venting',
      name: 'Furnace Venting',
      subtitle: 'Category I-IV venting',
      icon: LucideIcons.arrowUp,
      category: ScreenCategory.diagrams,
      searchTags: ['furnace', 'vent', 'category', 'pvc', 'b-vent', 'concentric'],
      builder: () => const FurnaceVentingScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'ventilation_hrv_erv',
      name: 'HRV / ERV',
      subtitle: 'Heat & energy recovery',
      icon: LucideIcons.repeat,
      category: ScreenCategory.diagrams,
      searchTags: ['hrv', 'erv', 'ventilation', 'recovery', 'fresh air'],
      builder: () => const VentilationHrvErvScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'hvac_load_calculation',
      name: 'Load Calculation',
      subtitle: 'Manual J basics',
      icon: LucideIcons.calculator,
      category: ScreenCategory.diagrams,
      searchTags: ['load', 'calculation', 'manual j', 'btu', 'tonnage'],
      builder: () => const LoadCalculationScreen(),
      trade: 'hvac',
    ),
    ScreenEntry(
      id: 'zoning_systems',
      name: 'Zoning Systems',
      subtitle: 'Dampers & zone controls',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.diagrams,
      searchTags: ['zone', 'damper', 'bypass', 'control', 'multi-zone'],
      builder: () => const ZoningSystemsScreen(),
      trade: 'hvac',
    ),
  ];
}
