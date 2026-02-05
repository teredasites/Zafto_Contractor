import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'screen_registry.dart';

// ============================================================================
// PLUMBING DIAGRAM IMPORTS (15 screens)
// ============================================================================
import '../screens/diagrams/plumbing/dwv_system_screen.dart';
import '../screens/diagrams/plumbing/venting_types_screen.dart';
import '../screens/diagrams/plumbing/trap_requirements_screen.dart';
import '../screens/diagrams/plumbing/water_supply_screen.dart';
import '../screens/diagrams/plumbing/water_heater_install_screen.dart';
import '../screens/diagrams/plumbing/gas_piping_screen.dart';
import '../screens/diagrams/plumbing/backflow_prevention_screen.dart';
import '../screens/diagrams/plumbing/fixture_rough_in_screen.dart';
import '../screens/diagrams/plumbing/pex_manifold_screen.dart';
import '../screens/diagrams/plumbing/cleanout_locations_screen.dart';
import '../screens/diagrams/plumbing/pipe_fittings_screen.dart';
import '../screens/diagrams/plumbing/sewer_line_screen.dart';
import '../screens/diagrams/plumbing/well_pump_screen.dart';
import '../screens/diagrams/plumbing/septic_system_screen.dart';
import '../screens/diagrams/plumbing/sump_pump_screen.dart';

// ============================================================================
// PLUMBING DIAGRAM ENTRIES (15)
// ============================================================================
class PlumbingDiagramEntries {
  PlumbingDiagramEntries._();

  static final List<ScreenEntry> plumbingDiagrams = [
    ScreenEntry(
      id: 'dwv_system',
      name: 'DWV System',
      subtitle: 'Drain-waste-vent basics',
      icon: LucideIcons.arrowDownUp,
      category: ScreenCategory.diagrams,
      searchTags: ['dwv', 'drain', 'waste', 'vent', 'stack', 'sanitary'],
      builder: () => const DWVSystemScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'venting_types',
      name: 'Venting Types',
      subtitle: 'Wet, dry, loop & AAV',
      icon: LucideIcons.wind,
      category: ScreenCategory.diagrams,
      searchTags: ['vent', 'wet', 'dry', 'loop', 'aav', 'studor'],
      builder: () => const VentingTypesScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'trap_requirements',
      name: 'Trap Requirements',
      subtitle: 'P-trap sizing & installation',
      icon: LucideIcons.gitPullRequestDraft,
      category: ScreenCategory.diagrams,
      searchTags: ['trap', 'p-trap', 'seal', 'weir', 'arm'],
      builder: () => const TrapRequirementsScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_supply',
      name: 'Water Supply',
      subtitle: 'Hot & cold distribution',
      icon: LucideIcons.droplets,
      category: ScreenCategory.diagrams,
      searchTags: ['water', 'supply', 'hot', 'cold', 'distribution', 'main'],
      builder: () => const WaterSupplyScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'water_heater_install',
      name: 'Water Heater Install',
      subtitle: 'Tank & tankless setup',
      icon: LucideIcons.thermometer,
      category: ScreenCategory.diagrams,
      searchTags: ['water heater', 'tank', 'tankless', 'expansion', 'relief'],
      builder: () => const WaterHeaterInstallScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'gas_piping',
      name: 'Gas Piping',
      subtitle: 'Black iron & CSST sizing',
      icon: LucideIcons.flame,
      category: ScreenCategory.diagrams,
      searchTags: ['gas', 'pipe', 'black iron', 'csst', 'btu', 'sizing'],
      builder: () => const GasPipingScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'backflow_prevention',
      name: 'Backflow Prevention',
      subtitle: 'Device types & requirements',
      icon: LucideIcons.shieldCheck,
      category: ScreenCategory.diagrams,
      searchTags: ['backflow', 'prevention', 'rpz', 'pvb', 'dcva', 'air gap'],
      builder: () => const BackflowPreventionScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'fixture_rough_in',
      name: 'Fixture Rough-In',
      subtitle: 'Standard dimensions',
      icon: LucideIcons.ruler,
      category: ScreenCategory.diagrams,
      searchTags: ['rough in', 'fixture', 'toilet', 'sink', 'dimension'],
      builder: () => const FixtureRoughInScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pex_manifold',
      name: 'PEX Manifold',
      subtitle: 'Home-run vs trunk & branch',
      icon: LucideIcons.gitFork,
      category: ScreenCategory.diagrams,
      searchTags: ['pex', 'manifold', 'home run', 'trunk', 'branch'],
      builder: () => const PexManifoldScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'cleanout_locations',
      name: 'Cleanout Locations',
      subtitle: 'Code requirements & access',
      icon: LucideIcons.circleDot,
      category: ScreenCategory.diagrams,
      searchTags: ['cleanout', 'access', 'location', 'two-way', 'code'],
      builder: () => const CleanoutLocationsScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'pipe_fittings',
      name: 'Pipe Fittings',
      subtitle: 'Common fittings guide',
      icon: LucideIcons.puzzle,
      category: ScreenCategory.diagrams,
      searchTags: ['fitting', 'elbow', 'tee', 'coupling', 'adapter', 'union'],
      builder: () => const PipeFittingsScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'sewer_line',
      name: 'Sewer Line',
      subtitle: 'Building drain & sewer connection',
      icon: LucideIcons.arrowRight,
      category: ScreenCategory.diagrams,
      searchTags: ['sewer', 'building drain', 'cleanout', 'slope', 'connection'],
      builder: () => const SewerLineScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'well_pump',
      name: 'Well Pump',
      subtitle: 'Submersible & jet pump systems',
      icon: LucideIcons.arrowUpFromLine,
      category: ScreenCategory.diagrams,
      searchTags: ['well', 'pump', 'submersible', 'jet', 'pressure tank'],
      builder: () => const WellPumpScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'septic_system',
      name: 'Septic System',
      subtitle: 'Tank & drain field layout',
      icon: LucideIcons.box,
      category: ScreenCategory.diagrams,
      searchTags: ['septic', 'tank', 'drain field', 'leach', 'effluent'],
      builder: () => const SepticSystemScreen(),
      trade: 'plumbing',
    ),
    ScreenEntry(
      id: 'sump_pump',
      name: 'Sump Pump',
      subtitle: 'Installation & check valve',
      icon: LucideIcons.arrowBigUp,
      category: ScreenCategory.diagrams,
      searchTags: ['sump', 'pump', 'basin', 'check valve', 'discharge'],
      builder: () => const SumpPumpScreen(),
      trade: 'plumbing',
    ),
  ];
}
