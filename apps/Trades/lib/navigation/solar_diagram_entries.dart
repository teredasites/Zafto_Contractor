import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// SOLAR DIAGRAM IMPORTS (11 screens)
// ============================================================================
import '../screens/diagrams/solar/grid_tied_system_screen.dart';
import '../screens/diagrams/solar/off_grid_system_screen.dart';
import '../screens/diagrams/solar/string_inverter_screen.dart';
import '../screens/diagrams/solar/microinverter_screen.dart';
import '../screens/diagrams/solar/rapid_shutdown_screen.dart';
import '../screens/diagrams/solar/grounding_bonding_screen.dart';
import '../screens/diagrams/solar/combiner_box_screen.dart';
import '../screens/diagrams/solar/pv_wire_sizing_screen.dart';
import '../screens/diagrams/solar/charge_controller_screen.dart';
import '../screens/diagrams/solar/panel_mounting_screen.dart';
import '../screens/diagrams/solar/nec_690_reference_screen.dart';

// ============================================================================
// SOLAR DIAGRAM ENTRIES (11)
// ============================================================================
class SolarDiagramEntries {
  SolarDiagramEntries._();

  static final List<ScreenEntry> solarDiagrams = [
    ScreenEntry(
      id: 'grid_tied_system',
      name: 'Grid-Tied System',
      subtitle: 'Standard grid-connected layout',
      icon: LucideIcons.plug,
      category: ScreenCategory.diagrams,
      searchTags: ['grid', 'tied', 'connected', 'solar', 'net metering'],
      builder: () => const GridTiedSystemScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'off_grid_system',
      name: 'Off-Grid System',
      subtitle: 'Battery-based standalone system',
      icon: LucideIcons.battery,
      category: ScreenCategory.diagrams,
      searchTags: ['off grid', 'battery', 'standalone', 'island'],
      builder: () => const OffGridSystemScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'string_inverter',
      name: 'String Inverter',
      subtitle: 'Central inverter configuration',
      icon: LucideIcons.gitBranch,
      category: ScreenCategory.diagrams,
      searchTags: ['string', 'inverter', 'central', 'dc', 'ac'],
      builder: () => const StringInverterScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'microinverter',
      name: 'Microinverter',
      subtitle: 'Module-level power electronics',
      icon: LucideIcons.cpu,
      category: ScreenCategory.diagrams,
      searchTags: ['microinverter', 'mlpe', 'module', 'enphase'],
      builder: () => const MicroinverterScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'rapid_shutdown',
      name: 'Rapid Shutdown',
      subtitle: 'NEC 690.12 requirements',
      icon: LucideIcons.powerOff,
      category: ScreenCategory.diagrams,
      searchTags: ['rapid', 'shutdown', 'rsd', 'safety', '690.12'],
      builder: () => const RapidShutdownScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'solar_grounding',
      name: 'Grounding & Bonding',
      subtitle: 'Equipment grounding for PV',
      icon: LucideIcons.anchor,
      category: ScreenCategory.diagrams,
      searchTags: ['grounding', 'bonding', 'egc', 'gec', 'solar'],
      builder: () => const GroundingBondingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'combiner_box',
      name: 'Combiner Box',
      subtitle: 'String combining & protection',
      icon: LucideIcons.box,
      category: ScreenCategory.diagrams,
      searchTags: ['combiner', 'box', 'fuse', 'string', 'ocpd'],
      builder: () => const CombinerBoxScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'pv_wire_sizing',
      name: 'PV Wire Sizing',
      subtitle: 'DC & AC conductor sizing',
      icon: LucideIcons.plug,
      category: ScreenCategory.diagrams,
      searchTags: ['wire', 'sizing', 'pv', 'use-2', 'conductor'],
      builder: () => const PvWireSizingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'charge_controller',
      name: 'Charge Controller',
      subtitle: 'PWM vs MPPT comparison',
      icon: LucideIcons.gauge,
      category: ScreenCategory.diagrams,
      searchTags: ['charge', 'controller', 'mppt', 'pwm', 'battery'],
      builder: () => const ChargeControllerScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'panel_mounting',
      name: 'Panel Mounting',
      subtitle: 'Roof & ground mount systems',
      icon: LucideIcons.mountainSnow,
      category: ScreenCategory.diagrams,
      searchTags: ['mounting', 'roof', 'ground', 'rack', 'rail', 'tilt'],
      builder: () => const PanelMountingScreen(),
      trade: 'solar',
    ),
    ScreenEntry(
      id: 'nec_690_reference',
      name: 'NEC 690 Reference',
      subtitle: 'Key code requirements',
      icon: LucideIcons.book,
      category: ScreenCategory.diagrams,
      searchTags: ['nec', '690', 'code', 'article', 'requirement'],
      builder: () => const Nec690ReferenceScreen(),
      trade: 'solar',
    ),
  ];
}
