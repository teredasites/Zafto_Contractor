import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// LANDSCAPING DIAGRAM IMPORTS (7 screens)
// ============================================================================
import '../screens/diagrams/landscaping/irrigation_systems_screen.dart';
import '../screens/diagrams/landscaping/hardscape_basics_screen.dart';
import '../screens/diagrams/landscaping/retaining_walls_screen.dart';
import '../screens/diagrams/landscaping/grading_drainage_screen.dart';
import '../screens/diagrams/landscaping/lawn_installation_screen.dart';
import '../screens/diagrams/landscaping/landscape_lighting_screen.dart';
import '../screens/diagrams/landscaping/planting_guidelines_screen.dart';

// ============================================================================
// LANDSCAPING DIAGRAM ENTRIES (7)
// ============================================================================
class LandscapingDiagramEntries {
  LandscapingDiagramEntries._();

  static final List<ScreenEntry> landscapingDiagrams = [
    ScreenEntry(
      id: 'irrigation_systems',
      name: 'Irrigation Systems',
      subtitle: 'Sprinkler, drip & zones',
      icon: LucideIcons.droplets,
      category: ScreenCategory.diagrams,
      searchTags: ['irrigation', 'sprinkler', 'drip', 'zone', 'valve', 'head'],
      builder: () => const IrrigationSystemsScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'hardscape_basics',
      name: 'Hardscape Basics',
      subtitle: 'Pavers, patios & base prep',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.diagrams,
      searchTags: ['hardscape', 'paver', 'patio', 'base', 'gravel', 'sand'],
      builder: () => const HardscapeBasicsScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'retaining_walls',
      name: 'Retaining Walls',
      subtitle: 'Block, timber & drainage',
      icon: LucideIcons.layers,
      category: ScreenCategory.diagrams,
      searchTags: ['retaining', 'wall', 'block', 'drainage', 'geogrid'],
      builder: () => const RetainingWallsScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'grading_drainage',
      name: 'Grading & Drainage',
      subtitle: 'Slope, swales & French drain',
      icon: LucideIcons.moveDown,
      category: ScreenCategory.diagrams,
      searchTags: ['grading', 'drainage', 'slope', 'swale', 'french drain'],
      builder: () => const GradingDrainageScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'lawn_installation',
      name: 'Lawn Installation',
      subtitle: 'Sod, seed & soil prep',
      icon: LucideIcons.leaf,
      category: ScreenCategory.diagrams,
      searchTags: ['lawn', 'sod', 'seed', 'grass', 'soil', 'topdress'],
      builder: () => const LawnInstallationScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'landscape_lighting',
      name: 'Landscape Lighting',
      subtitle: 'Low voltage design & install',
      icon: LucideIcons.lightbulb,
      category: ScreenCategory.diagrams,
      searchTags: ['lighting', 'low voltage', 'path', 'uplight', 'transformer'],
      builder: () => const LandscapeLightingScreen(),
      trade: 'landscaping',
    ),
    ScreenEntry(
      id: 'planting_guidelines',
      name: 'Planting Guidelines',
      subtitle: 'Trees, shrubs & spacing',
      icon: LucideIcons.treePine,
      category: ScreenCategory.diagrams,
      searchTags: ['planting', 'tree', 'shrub', 'spacing', 'mulch', 'root'],
      builder: () => const PlantingGuidelinesScreen(),
      trade: 'landscaping',
    ),
  ];
}
