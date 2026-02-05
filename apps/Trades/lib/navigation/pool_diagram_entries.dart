import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// POOL/SPA DIAGRAM IMPORTS (7 screens)
// ============================================================================
import '../screens/diagrams/pool_spa/pool_circulation_screen.dart';
import '../screens/diagrams/pool_spa/water_chemistry_screen.dart';
import '../screens/diagrams/pool_spa/pump_filter_systems_screen.dart';
import '../screens/diagrams/pool_spa/heater_systems_screen.dart';
import '../screens/diagrams/pool_spa/spa_equipment_screen.dart';
import '../screens/diagrams/pool_spa/pool_electrical_screen.dart';
import '../screens/diagrams/pool_spa/maintenance_schedule_screen.dart';

// ============================================================================
// POOL/SPA DIAGRAM ENTRIES (7)
// ============================================================================
class PoolDiagramEntries {
  PoolDiagramEntries._();

  static final List<ScreenEntry> poolDiagrams = [
    ScreenEntry(
      id: 'pool_circulation',
      name: 'Pool Circulation',
      subtitle: 'Plumbing flow & pipe sizing',
      icon: LucideIcons.refreshCw,
      category: ScreenCategory.diagrams,
      searchTags: ['pool', 'circulation', 'plumbing', 'pipe', 'flow', 'gpm'],
      builder: () => const PoolCirculationScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'water_chemistry',
      name: 'Water Chemistry',
      subtitle: 'Chemical balance & sanitizers',
      icon: LucideIcons.flaskConical,
      category: ScreenCategory.diagrams,
      searchTags: ['chemistry', 'chlorine', 'ph', 'alkalinity', 'sanitizer'],
      builder: () => const WaterChemistryScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pump_filter_systems',
      name: 'Pump & Filter',
      subtitle: 'Pump types & filter comparison',
      icon: LucideIcons.filter,
      category: ScreenCategory.diagrams,
      searchTags: ['pump', 'filter', 'sand', 'cartridge', 'de', 'variable speed'],
      builder: () => const PumpFilterSystemsScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'heater_systems',
      name: 'Heater Systems',
      subtitle: 'Gas, heat pump & solar heaters',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.diagrams,
      searchTags: ['heater', 'gas', 'heat pump', 'solar', 'btu'],
      builder: () => const HeaterSystemsScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'spa_equipment',
      name: 'Spa Equipment',
      subtitle: 'Spa components, jets & controls',
      icon: LucideIcons.waves,
      category: ScreenCategory.diagrams,
      searchTags: ['spa', 'hot tub', 'jet', 'blower', 'pack', 'control'],
      builder: () => const SpaEquipmentScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_electrical',
      name: 'Pool Electrical',
      subtitle: 'NEC 680 bonding & GFCI',
      icon: LucideIcons.zap,
      category: ScreenCategory.diagrams,
      searchTags: ['electrical', 'bonding', 'gfci', 'nec', '680', 'grounding'],
      builder: () => const PoolElectricalScreen(),
      trade: 'pool',
    ),
    ScreenEntry(
      id: 'pool_maintenance_schedule',
      name: 'Maintenance Schedule',
      subtitle: 'Daily, weekly & seasonal tasks',
      icon: LucideIcons.clipboardList,
      category: ScreenCategory.diagrams,
      searchTags: ['maintenance', 'schedule', 'daily', 'weekly', 'seasonal'],
      builder: () => const MaintenanceScheduleScreen(),
      trade: 'pool',
    ),
  ];
}
