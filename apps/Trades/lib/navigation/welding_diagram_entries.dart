import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// WELDING DIAGRAM IMPORTS (5 screens)
// ============================================================================
import '../screens/diagrams/welding/welding_processes_screen.dart';
import '../screens/diagrams/welding/joint_types_screen.dart';
import '../screens/diagrams/welding/welding_symbols_screen.dart';
import '../screens/diagrams/welding/electrode_selection_screen.dart';
import '../screens/diagrams/welding/weld_defects_screen.dart';

// ============================================================================
// WELDING DIAGRAM ENTRIES (5)
// ============================================================================
class WeldingDiagramEntries {
  WeldingDiagramEntries._();

  static final List<ScreenEntry> weldingDiagrams = [
    ScreenEntry(
      id: 'welding_processes',
      name: 'Welding Processes',
      subtitle: 'MIG, TIG, Stick comparison',
      icon: LucideIcons.zap,
      category: ScreenCategory.diagrams,
      searchTags: ['welding', 'process', 'mig', 'tig', 'stick', 'gmaw', 'gtaw', 'smaw'],
      builder: () => const WeldingProcessesScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'joint_types',
      name: 'Joint Types',
      subtitle: '5 basic joint types & weld positions',
      icon: LucideIcons.link,
      category: ScreenCategory.diagrams,
      searchTags: ['joint', 'butt', 'lap', 'tee', 'corner', 'edge', 'position'],
      builder: () => const JointTypesScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'welding_symbols',
      name: 'Welding Symbols',
      subtitle: 'AWS welding symbol anatomy',
      icon: LucideIcons.fileText,
      category: ScreenCategory.diagrams,
      searchTags: ['symbol', 'aws', 'blueprint', 'arrow', 'reference'],
      builder: () => const WeldingSymbolsScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'electrode_selection',
      name: 'Electrode Selection',
      subtitle: 'Stick, MIG wire, TIG tungsten guide',
      icon: LucideIcons.minus,
      category: ScreenCategory.diagrams,
      searchTags: ['electrode', 'rod', 'wire', 'tungsten', 'e7018', 'er70s'],
      builder: () => const ElectrodeSelectionScreen(),
      trade: 'welding',
    ),
    ScreenEntry(
      id: 'weld_defects',
      name: 'Weld Defects',
      subtitle: 'Common defects, causes & fixes',
      icon: LucideIcons.alertTriangle,
      category: ScreenCategory.diagrams,
      searchTags: ['defect', 'porosity', 'undercut', 'crack', 'spatter', 'inspection'],
      builder: () => const WeldDefectsScreen(),
      trade: 'welding',
    ),
  ];
}
