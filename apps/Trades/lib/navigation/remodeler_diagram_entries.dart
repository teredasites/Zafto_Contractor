import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// REMODELER DIAGRAM IMPORTS (10 screens)
// ============================================================================
import '../screens/diagrams/remodeler/kitchen_remodel_screen.dart';
import '../screens/diagrams/remodeler/bathroom_remodel_screen.dart';
import '../screens/diagrams/remodeler/load_bearing_walls_screen.dart';
import '../screens/diagrams/remodeler/drywall_basics_screen.dart';
import '../screens/diagrams/remodeler/flooring_installation_screen.dart';
import '../screens/diagrams/remodeler/cabinet_installation_screen.dart';
import '../screens/diagrams/remodeler/trim_molding_screen.dart';
import '../screens/diagrams/remodeler/window_door_replacement_screen.dart';
import '../screens/diagrams/remodeler/countertop_installation_screen.dart';
import '../screens/diagrams/remodeler/paint_preparation_screen.dart';

// ============================================================================
// REMODELER DIAGRAM ENTRIES (10)
// ============================================================================
class RemodelerDiagramEntries {
  RemodelerDiagramEntries._();

  static final List<ScreenEntry> remodelerDiagrams = [
    ScreenEntry(
      id: 'kitchen_remodel',
      name: 'Kitchen Remodel',
      subtitle: 'Layout, workflow & dimensions',
      icon: LucideIcons.chefHat,
      category: ScreenCategory.diagrams,
      searchTags: ['kitchen', 'remodel', 'layout', 'triangle', 'cabinet'],
      builder: () => const KitchenRemodelScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'bathroom_remodel',
      name: 'Bathroom Remodel',
      subtitle: 'Clearances, ventilation & waterproofing',
      icon: LucideIcons.bath,
      category: ScreenCategory.diagrams,
      searchTags: ['bathroom', 'remodel', 'shower', 'waterproof', 'vent'],
      builder: () => const BathroomRemodelScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'load_bearing_walls',
      name: 'Load Bearing Walls',
      subtitle: 'Identification & header sizing',
      icon: LucideIcons.building,
      category: ScreenCategory.diagrams,
      searchTags: ['load bearing', 'wall', 'header', 'structural', 'support'],
      builder: () => const LoadBearingWallsScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'drywall_basics',
      name: 'Drywall Basics',
      subtitle: 'Hanging, taping & finishing',
      icon: LucideIcons.square,
      category: ScreenCategory.diagrams,
      searchTags: ['drywall', 'sheetrock', 'tape', 'mud', 'finish', 'texture'],
      builder: () => const DrywallBasicsScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'flooring_installation',
      name: 'Flooring Installation',
      subtitle: 'Hardwood, LVP, tile & subfloor',
      icon: LucideIcons.layoutGrid,
      category: ScreenCategory.diagrams,
      searchTags: ['flooring', 'hardwood', 'lvp', 'tile', 'subfloor', 'underlayment'],
      builder: () => const FlooringInstallationScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'cabinet_installation',
      name: 'Cabinet Installation',
      subtitle: 'Wall & base cabinet mounting',
      icon: LucideIcons.doorOpen,
      category: ScreenCategory.diagrams,
      searchTags: ['cabinet', 'install', 'wall', 'base', 'level', 'shim'],
      builder: () => const CabinetInstallationScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'trim_molding',
      name: 'Trim & Molding',
      subtitle: 'Crown, base & casing cuts',
      icon: LucideIcons.minus,
      category: ScreenCategory.diagrams,
      searchTags: ['trim', 'molding', 'crown', 'baseboard', 'casing', 'miter'],
      builder: () => const TrimMoldingScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'window_door_replacement',
      name: 'Window & Door',
      subtitle: 'Rough opening & installation',
      icon: LucideIcons.doorClosed,
      category: ScreenCategory.diagrams,
      searchTags: ['window', 'door', 'rough opening', 'flashing', 'install'],
      builder: () => const WindowDoorReplacementScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'countertop_installation',
      name: 'Countertop Install',
      subtitle: 'Material comparison & methods',
      icon: LucideIcons.table,
      category: ScreenCategory.diagrams,
      searchTags: ['countertop', 'granite', 'quartz', 'laminate', 'install'],
      builder: () => const CountertopInstallationScreen(),
      trade: 'remodeler',
    ),
    ScreenEntry(
      id: 'paint_preparation',
      name: 'Paint Preparation',
      subtitle: 'Surface prep, primer & finish',
      icon: LucideIcons.paintbrush,
      category: ScreenCategory.diagrams,
      searchTags: ['paint', 'prep', 'primer', 'surface', 'finish', 'coating'],
      builder: () => const PaintPreparationScreen(),
      trade: 'remodeler',
    ),
  ];
}
