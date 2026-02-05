import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// ROOFING DIAGRAM IMPORTS (8 screens)
// ============================================================================
import '../screens/diagrams/roofing/roof_anatomy_screen.dart';
import '../screens/diagrams/roofing/shingle_installation_screen.dart';
import '../screens/diagrams/roofing/flashing_details_screen.dart';
import '../screens/diagrams/roofing/roof_ventilation_screen.dart';
import '../screens/diagrams/roofing/metal_roofing_screen.dart';
import '../screens/diagrams/roofing/flat_roofing_screen.dart';
import '../screens/diagrams/roofing/ice_water_shield_screen.dart';
import '../screens/diagrams/roofing/gutter_systems_screen.dart';

// ============================================================================
// ROOFING DIAGRAM ENTRIES (8)
// ============================================================================
class RoofingDiagramEntries {
  RoofingDiagramEntries._();

  static final List<ScreenEntry> roofingDiagrams = [
    ScreenEntry(
      id: 'roof_anatomy',
      name: 'Roof Anatomy',
      subtitle: 'Components & terminology',
      icon: LucideIcons.home,
      category: ScreenCategory.diagrams,
      searchTags: ['roof', 'anatomy', 'ridge', 'valley', 'eave', 'rake'],
      builder: () => const RoofAnatomyScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'shingle_installation',
      name: 'Shingle Installation',
      subtitle: 'Asphalt shingle layout & nailing',
      icon: LucideIcons.layers,
      category: ScreenCategory.diagrams,
      searchTags: ['shingle', 'asphalt', 'install', 'nail', 'pattern', 'starter'],
      builder: () => const ShingleInstallationScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'flashing_details',
      name: 'Flashing Details',
      subtitle: 'Valley, step & chimney flashing',
      icon: LucideIcons.shield,
      category: ScreenCategory.diagrams,
      searchTags: ['flashing', 'valley', 'step', 'chimney', 'drip edge'],
      builder: () => const FlashingDetailsScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'roof_ventilation',
      name: 'Roof Ventilation',
      subtitle: 'Intake, exhaust & NFA calculations',
      icon: LucideIcons.wind,
      category: ScreenCategory.diagrams,
      searchTags: ['ventilation', 'vent', 'ridge', 'soffit', 'nfa', 'attic'],
      builder: () => const RoofVentilationScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'metal_roofing',
      name: 'Metal Roofing',
      subtitle: 'Standing seam & panel types',
      icon: LucideIcons.square,
      category: ScreenCategory.diagrams,
      searchTags: ['metal', 'standing seam', 'panel', 'screw', 'clip'],
      builder: () => const MetalRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'flat_roofing',
      name: 'Flat Roofing',
      subtitle: 'TPO, EPDM & built-up systems',
      icon: LucideIcons.minus,
      category: ScreenCategory.diagrams,
      searchTags: ['flat', 'tpo', 'epdm', 'built-up', 'membrane', 'low slope'],
      builder: () => const FlatRoofingScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'ice_water_shield',
      name: 'Ice & Water Shield',
      subtitle: 'Underlayment requirements',
      icon: LucideIcons.snowflake,
      category: ScreenCategory.diagrams,
      searchTags: ['ice', 'water', 'shield', 'underlayment', 'felt', 'synthetic'],
      builder: () => const IceWaterShieldScreen(),
      trade: 'roofing',
    ),
    ScreenEntry(
      id: 'gutter_systems',
      name: 'Gutter Systems',
      subtitle: 'Sizing, slope & downspouts',
      icon: LucideIcons.arrowDownToLine,
      category: ScreenCategory.diagrams,
      searchTags: ['gutter', 'downspout', 'drainage', 'k-style', 'half-round'],
      builder: () => const GutterSystemsScreen(),
      trade: 'roofing',
    ),
  ];
}
