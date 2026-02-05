import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// GENERAL CONTRACTOR DIAGRAM IMPORTS (6 screens)
// ============================================================================
import '../screens/diagrams/gc/construction_sequence_screen.dart';
import '../screens/diagrams/gc/foundation_types_screen.dart';
import '../screens/diagrams/gc/framing_basics_screen.dart';
import '../screens/diagrams/gc/concrete_basics_screen.dart';
import '../screens/diagrams/gc/blueprint_symbols_screen.dart';
import '../screens/diagrams/gc/permits_inspections_screen.dart';

// ============================================================================
// GENERAL CONTRACTOR DIAGRAM ENTRIES (6)
// ============================================================================
class GcDiagramEntries {
  GcDiagramEntries._();

  static final List<ScreenEntry> gcDiagrams = [
    ScreenEntry(
      id: 'construction_sequence',
      name: 'Construction Sequence',
      subtitle: 'Build phases & scheduling',
      icon: LucideIcons.listOrdered,
      category: ScreenCategory.diagrams,
      searchTags: ['construction', 'sequence', 'phase', 'schedule', 'timeline'],
      builder: () => const ConstructionSequenceScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'foundation_types',
      name: 'Foundation Types',
      subtitle: 'Slab, crawl, basement & pier',
      icon: LucideIcons.layers,
      category: ScreenCategory.diagrams,
      searchTags: ['foundation', 'slab', 'crawl', 'basement', 'pier', 'footing'],
      builder: () => const FoundationTypesScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'framing_basics',
      name: 'Framing Basics',
      subtitle: 'Wall, floor & roof framing',
      icon: LucideIcons.home,
      category: ScreenCategory.diagrams,
      searchTags: ['framing', 'stud', 'joist', 'rafter', 'header', 'wall'],
      builder: () => const FramingBasicsScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'concrete_basics',
      name: 'Concrete Basics',
      subtitle: 'Mix design, placement & curing',
      icon: LucideIcons.square,
      category: ScreenCategory.diagrams,
      searchTags: ['concrete', 'mix', 'psi', 'rebar', 'curing', 'placement'],
      builder: () => const ConcreteBasicsScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'gc_blueprint_symbols',
      name: 'Blueprint Symbols',
      subtitle: 'Common construction symbols',
      icon: LucideIcons.fileText,
      category: ScreenCategory.diagrams,
      searchTags: ['blueprint', 'symbol', 'plan', 'drawing', 'legend'],
      builder: () => const BlueprintSymbolsScreen(),
      trade: 'gc',
    ),
    ScreenEntry(
      id: 'permits_inspections',
      name: 'Permits & Inspections',
      subtitle: 'Permit process & inspection stages',
      icon: LucideIcons.clipboardCheck,
      category: ScreenCategory.diagrams,
      searchTags: ['permit', 'inspection', 'code', 'compliance', 'certificate'],
      builder: () => const PermitsInspectionsScreen(),
      trade: 'gc',
    ),
  ];
}
