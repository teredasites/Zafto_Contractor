import 'nec_version.dart';

/// NEC Changes Log - Documents significant changes between editions
/// This file tracks what changed and when, for reference screens and UI badges

/// A single NEC change entry
class NecChange {
  final String id;
  final NecVersion introducedIn;
  final String article;
  final String title;
  final String description;
  final String? previousRequirement;
  final String newRequirement;
  final List<String> affectedCalculators;
  final List<String> tags;

  const NecChange({
    required this.id,
    required this.introducedIn,
    required this.article,
    required this.title,
    required this.description,
    this.previousRequirement,
    required this.newRequirement,
    this.affectedCalculators = const [],
    this.tags = const [],
  });

  /// Check if this change is relevant for given version
  bool isRelevantFor(NecVersion version) => version.hasFeature(introducedIn);
}

/// Complete changelog for NEC editions
class NecChangesLog {
  NecChangesLog._();

  /// Get all changes introduced in a specific version
  static List<NecChange> getChangesForVersion(NecVersion version) {
    return allChanges.where((c) => c.introducedIn == version).toList();
  }

  /// Get changes relevant to a specific article
  static List<NecChange> getChangesForArticle(String article) {
    return allChanges.where((c) => c.article == article).toList();
  }

  /// Get changes affecting a specific calculator
  static List<NecChange> getChangesForCalculator(String calculatorId) {
    return allChanges
        .where((c) => c.affectedCalculators.contains(calculatorId))
        .toList();
  }

  /// All documented NEC changes
  static const List<NecChange> allChanges = [
    // ==================== NEC 2026 CHANGES ====================
    NecChange(
      id: 'nec2026_gfci_250v',
      introducedIn: NecVersion.nec2026,
      article: '210.8',
      title: 'GFCI Protection for 250V Receptacles',
      description:
          'Expanded GFCI requirements to include certain 250V receptacles up to 50A in specific locations.',
      previousRequirement: 'GFCI only required for 125V 15/20A receptacles',
      newRequirement:
          'GFCI now required for 250V receptacles 50A or less in kitchens, bathrooms, laundry, and outdoors',
      affectedCalculators: ['evCharger', 'dryerCircuit', 'electricRange'],
      tags: ['gfci', 'safety', '250v'],
    ),
    NecChange(
      id: 'nec2026_gfci_6ma',
      introducedIn: NecVersion.nec2026,
      article: '210.8',
      title: '6mA GFCI Trip Level',
      description:
          'Clarified that Class A GFCIs (6mA trip threshold) are required for personnel protection.',
      previousRequirement: 'GFCI trip level not explicitly specified in some cases',
      newRequirement: '6mA maximum trip level for personnel protection GFCIs',
      tags: ['gfci', 'safety'],
    ),
    NecChange(
      id: 'nec2026_ev_bidirectional',
      introducedIn: NecVersion.nec2026,
      article: '625',
      title: 'Bidirectional EV Charging',
      description:
          'New requirements for vehicle-to-grid (V2G) and vehicle-to-home (V2H) bidirectional charging systems.',
      previousRequirement: 'Not addressed',
      newRequirement:
          'Specific installation requirements for bidirectional EVSE including interconnection rules',
      affectedCalculators: ['evCharger'],
      tags: ['ev', 'solar', 'grid'],
    ),
    NecChange(
      id: 'nec2026_ess_labeling',
      introducedIn: NecVersion.nec2026,
      article: '706',
      title: 'Energy Storage System Labeling',
      description: 'Enhanced labeling requirements for battery energy storage systems.',
      previousRequirement: 'Basic labeling required',
      newRequirement:
          'Detailed labeling including energy capacity, voltage, chemistry type, and emergency procedures',
      tags: ['battery', 'solar', 'labeling'],
    ),

    // ==================== NEC 2023 CHANGES ====================
    NecChange(
      id: 'nec2023_outdoor_gfci',
      introducedIn: NecVersion.nec2023,
      article: '210.8(A)(3)',
      title: 'Outdoor GFCI Expansion',
      description:
          'All outdoor receptacles at dwelling units now require GFCI protection, not just those readily accessible from grade.',
      previousRequirement: 'GFCI for outdoor receptacles accessible from grade level',
      newRequirement: 'GFCI for ALL outdoor receptacles at dwelling units',
      tags: ['gfci', 'outdoor', 'dwelling'],
    ),
    NecChange(
      id: 'nec2023_ev_ready',
      introducedIn: NecVersion.nec2023,
      article: '210.17',
      title: 'EV Ready Outlet Requirement',
      description:
          'New construction dwelling units with attached garages must have at least one EV-ready outlet.',
      previousRequirement: 'Not required',
      newRequirement: '40A, 240V circuit and outlet for EV charging in new garages',
      affectedCalculators: ['evCharger'],
      tags: ['ev', 'new-construction'],
    ),
    NecChange(
      id: 'nec2023_service_disconnect',
      introducedIn: NecVersion.nec2023,
      article: '230.85',
      title: 'Emergency Service Disconnect',
      description:
          'One- and two-family dwellings must have an emergency disconnect at a readily accessible outdoor location.',
      previousRequirement: 'Service disconnect could be inside',
      newRequirement:
          'Emergency disconnect required outside, readily accessible, marked as SERVICE DISCONNECT',
      affectedCalculators: ['serviceEntrance'],
      tags: ['service', 'safety', 'disconnect'],
    ),
    NecChange(
      id: 'nec2023_surge_marking',
      introducedIn: NecVersion.nec2023,
      article: '230.67',
      title: 'Surge Protection Marking',
      description: 'Surge protective devices must be marked as such.',
      previousRequirement: 'Surge protection required, marking optional',
      newRequirement: 'SPDs must be marked SURGE PROTECTIVE DEVICE',
      tags: ['surge', 'labeling'],
    ),

    // ==================== NEC 2020 CHANGES ====================
    NecChange(
      id: 'nec2020_gfci_basement',
      introducedIn: NecVersion.nec2020,
      article: '210.8(A)(4)',
      title: 'Basement GFCI Expansion',
      description:
          'All 125V 15/20A receptacles in basements now require GFCI, not just unfinished areas.',
      previousRequirement: 'GFCI only in unfinished basements',
      newRequirement: 'GFCI for ALL basement 125V 15/20A receptacles',
      tags: ['gfci', 'basement'],
    ),
    NecChange(
      id: 'nec2020_gfci_laundry',
      introducedIn: NecVersion.nec2020,
      article: '210.8(A)(10)',
      title: 'Laundry Area GFCI',
      description: 'GFCI protection now required for laundry area receptacles.',
      previousRequirement: 'Not required',
      newRequirement: 'GFCI required for laundry area receptacles in dwelling units',
      affectedCalculators: ['dryerCircuit'],
      tags: ['gfci', 'laundry'],
    ),
    NecChange(
      id: 'nec2020_gfci_dishwasher',
      introducedIn: NecVersion.nec2020,
      article: '210.8(D)',
      title: 'Kitchen Dishwasher GFCI',
      description: 'Dishwasher outlets now require GFCI protection.',
      previousRequirement: 'Not specifically required',
      newRequirement: 'GFCI required for dishwasher outlet in dwelling units',
      tags: ['gfci', 'kitchen', 'appliance'],
    ),
    NecChange(
      id: 'nec2020_surge_protection',
      introducedIn: NecVersion.nec2020,
      article: '230.67',
      title: 'Dwelling Unit Surge Protection',
      description:
          'Surge protective devices (SPDs) now required at service equipment for dwelling units.',
      previousRequirement: 'Not required',
      newRequirement: 'Type 1 or Type 2 SPD required at dwelling unit services',
      affectedCalculators: ['serviceEntrance'],
      tags: ['surge', 'service', 'dwelling'],
    ),
    NecChange(
      id: 'nec2020_solar_rapid_shutdown',
      introducedIn: NecVersion.nec2020,
      article: '690.12',
      title: 'Module-Level Rapid Shutdown',
      description:
          'Solar PV systems must have rapid shutdown at the module level, not just array level.',
      previousRequirement: 'Array-level rapid shutdown',
      newRequirement:
          'Module-level rapid shutdown: conductors more than 1ft from array must be reduced to 80V within 30 seconds',
      affectedCalculators: ['solarPv'],
      tags: ['solar', 'safety', 'rapid-shutdown'],
    ),
    NecChange(
      id: 'nec2020_afci_expansion',
      introducedIn: NecVersion.nec2020,
      article: '210.12',
      title: 'AFCI for All Living Areas',
      description:
          'AFCI protection expanded to essentially all 120V 15/20A circuits in dwelling unit living areas.',
      previousRequirement: 'AFCI for specific rooms',
      newRequirement: 'AFCI for all 120V 15/20A circuits serving dwelling unit living areas',
      tags: ['afci', 'dwelling'],
    ),

    // ==================== NEC 2017 CHANGES ====================
    NecChange(
      id: 'nec2017_gfci_garage',
      introducedIn: NecVersion.nec2017,
      article: '210.8(A)(2)',
      title: 'Garage GFCI - All Receptacles',
      description: 'GFCI protection now required for ALL receptacles in garages.',
      previousRequirement: 'GFCI only for receptacles readily accessible',
      newRequirement: 'GFCI for all 125V 15/20A receptacles in garages',
      tags: ['gfci', 'garage'],
    ),
    NecChange(
      id: 'nec2017_afci_kitchen',
      introducedIn: NecVersion.nec2017,
      article: '210.12(A)',
      title: 'AFCI Expanded to Kitchen/Laundry',
      description:
          'AFCI protection expanded to include kitchens, laundry areas, and additional living spaces.',
      previousRequirement: 'AFCI only for bedrooms',
      newRequirement:
          'AFCI for kitchens, family rooms, dining rooms, living rooms, parlors, libraries, dens, bedrooms, recreation rooms, closets, hallways, laundry areas',
      tags: ['afci'],
    ),
    NecChange(
      id: 'nec2017_available_fault_current',
      introducedIn: NecVersion.nec2017,
      article: '110.24',
      title: 'Available Fault Current Labeling',
      description:
          'Service equipment must be field-marked with available fault current and date of calculation.',
      previousRequirement: 'Not required',
      newRequirement:
          'Field marking required showing available fault current, date calculated, and who did calculation',
      affectedCalculators: ['faultCurrent', 'serviceEntrance'],
      tags: ['fault-current', 'labeling', 'service'],
    ),
  ];
}

/// Helper for UI to show "New in NEC 2026" badges etc.
class NecVersionBadge {
  NecVersionBadge._();

  /// Get badge text for changes new in user's selected version
  static String? getBadgeText(NecVersion userVersion, NecVersion featureVersion) {
    if (!userVersion.hasFeature(featureVersion)) {
      return null; // Feature not available in user's version
    }
    if (featureVersion == userVersion) {
      return 'New in ${featureVersion.displayName}';
    }
    return null;
  }

  /// Check if feature is new in current version (for highlighting)
  static bool isNewInCurrentVersion(NecVersion featureVersion) {
    return featureVersion == NecVersion.nec2026;
  }
}

/// Quick reference for requirement lookups
class NecQuickReference {
  NecQuickReference._();

  /// Check if GFCI is required for a location given NEC version
  static bool isGfciRequired(String location, NecVersion version) {
    final locations = GfciRequirements.getRequiredLocations(version);
    return locations.any(
      (l) => l.toLowerCase().contains(location.toLowerCase()),
    );
  }

  /// Check if AFCI is required for a location given NEC version
  static bool isAfciRequired(String location, NecVersion version) {
    final locations = AfciRequirements.getRequiredLocations(version);
    return locations.any(
      (l) => l.toLowerCase().contains(location.toLowerCase()),
    );
  }

  /// Get all changes that affect a specific calculator
  static List<String> getCalculatorNotes(String calculatorId, NecVersion version) {
    final changes = NecChangesLog.getChangesForCalculator(calculatorId);
    return changes
        .where((c) => c.isRelevantFor(version))
        .map((c) => '${c.title}: ${c.newRequirement}')
        .toList();
  }
}
