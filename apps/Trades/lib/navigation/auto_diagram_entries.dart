import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// AUTO MECHANIC DIAGRAM IMPORTS (7 screens)
// ============================================================================
import '../screens/diagrams/auto_mechanic/engine_basics_screen.dart';
import '../screens/diagrams/auto_mechanic/brake_systems_screen.dart';
import '../screens/diagrams/auto_mechanic/electrical_systems_screen.dart';
import '../screens/diagrams/auto_mechanic/cooling_system_screen.dart';
import '../screens/diagrams/auto_mechanic/suspension_components_screen.dart';
import '../screens/diagrams/auto_mechanic/obd_diagnostics_screen.dart';
import '../screens/diagrams/auto_mechanic/tire_specs_screen.dart';

// ============================================================================
// AUTO MECHANIC DIAGRAM ENTRIES (7)
// ============================================================================
class AutoDiagramEntries {
  AutoDiagramEntries._();

  static final List<ScreenEntry> autoDiagrams = [
    ScreenEntry(
      id: 'engine_basics',
      name: 'Engine Basics',
      subtitle: '4-stroke cycle & engine types',
      icon: LucideIcons.settings,
      category: ScreenCategory.diagrams,
      searchTags: ['engine', 'cylinder', 'piston', 'stroke', 'firing order'],
      builder: () => const EngineBasicsScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'brake_systems',
      name: 'Brake Systems',
      subtitle: 'Disc, drum & ABS systems',
      icon: LucideIcons.octagon,
      category: ScreenCategory.diagrams,
      searchTags: ['brake', 'disc', 'drum', 'abs', 'caliper', 'rotor', 'pad'],
      builder: () => const BrakeSystemsScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'auto_electrical',
      name: 'Electrical Systems',
      subtitle: 'Starting, charging & wiring',
      icon: LucideIcons.battery,
      category: ScreenCategory.diagrams,
      searchTags: ['electrical', 'battery', 'alternator', 'starter', 'wiring'],
      builder: () => const ElectricalSystemsScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'cooling_system',
      name: 'Cooling System',
      subtitle: 'Radiator, thermostat & flow',
      icon: LucideIcons.thermometerSnowflake,
      category: ScreenCategory.diagrams,
      searchTags: ['cooling', 'radiator', 'thermostat', 'water pump', 'coolant'],
      builder: () => const CoolingSystemScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'suspension_components',
      name: 'Suspension',
      subtitle: 'Struts, shocks & alignment',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.diagrams,
      searchTags: ['suspension', 'strut', 'shock', 'spring', 'alignment', 'camber'],
      builder: () => const SuspensionComponentsScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'obd_diagnostics',
      name: 'OBD Diagnostics',
      subtitle: 'OBD-II codes & monitors',
      icon: LucideIcons.scan,
      category: ScreenCategory.diagrams,
      searchTags: ['obd', 'diagnostic', 'code', 'dtc', 'check engine', 'monitor'],
      builder: () => const ObdDiagnosticsScreen(),
      trade: 'auto',
    ),
    ScreenEntry(
      id: 'tire_specs',
      name: 'Tire Specifications',
      subtitle: 'Size codes, pressure & wear',
      icon: LucideIcons.circle,
      category: ScreenCategory.diagrams,
      searchTags: ['tire', 'size', 'pressure', 'tread', 'rotation', 'wear'],
      builder: () => const TireSpecsScreen(),
      trade: 'auto',
    ),
  ];
}
