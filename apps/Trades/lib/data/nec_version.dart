import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// NEC Edition Years
/// The NEC is published every 3 years
enum NecVersion {
  nec2026(2026, 'NEC 2026', 'Released September 2025'),
  nec2023(2023, 'NEC 2023', 'Released September 2022'),
  nec2020(2020, 'NEC 2020', 'Released September 2019'),
  nec2017(2017, 'NEC 2017', 'Released September 2016'),
  nec2014(2014, 'NEC 2014', 'Released September 2013');

  const NecVersion(this.year, this.displayName, this.releaseInfo);

  final int year;
  final String displayName;
  final String releaseInfo;

  /// Check if this version is the current/latest
  bool get isCurrent => this == NecVersion.nec2026;

  /// Check if a feature introduced in [sinceVersion] is available
  bool hasFeature(NecVersion sinceVersion) => year >= sinceVersion.year;
}

/// Provider for current NEC version selection
final necVersionProvider = StateNotifierProvider<NecVersionNotifier, NecVersion>((ref) {
  return NecVersionNotifier();
});

/// NEC Version state notifier with Hive persistence
class NecVersionNotifier extends StateNotifier<NecVersion> {
  static const String _boxName = 'app_settings';
  static const String _key = 'nec_version';

  NecVersionNotifier() : super(NecVersion.nec2026) {
    _loadSavedVersion();
  }

  Future<void> _loadSavedVersion() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final savedYear = box.get(_key);
      if (savedYear != null) {
        final year = int.tryParse(savedYear);
        if (year != null) {
          state = NecVersion.values.firstWhere(
            (v) => v.year == year,
            orElse: () => NecVersion.nec2026,
          );
        }
      }
    } catch (e) {
      // Keep default
    }
  }

  Future<void> setVersion(NecVersion version) async {
    state = version;
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(_key, version.year.toString());
    } catch (e) {
      // Ignore persistence errors
    }
  }
}

/// ============================================
/// NEC TABLE VERSION DOCUMENTATION
/// ============================================
///
/// The following tables are STABLE across NEC editions (2014-2026):
/// - Table 310.16 (Conductor Ampacity) - NO CHANGES
/// - Table 430.248 (Single Phase Motor FLA) - NO CHANGES
/// - Table 430.250 (Three Phase Motor FLA) - NO CHANGES
/// - Table 250.66 (Grounding Electrode Conductor) - NO CHANGES
/// - Table 250.122 (Equipment Grounding Conductor) - NO CHANGES
/// - Table 314.16 (Box Fill) - NO CHANGES
/// - Table 240.6 (Standard Breaker Sizes) - NO CHANGES
/// - Chapter 9 Tables (Conduit Fill) - NO CHANGES
///
/// What DOES change between NEC editions:
/// - GFCI requirements (expanded locations)
/// - AFCI requirements (expanded locations)
/// - Arc-fault disconnect requirements
/// - Rapid shutdown requirements for solar
/// - EV charger requirements
/// - Specific installation requirements (code text, not tables)
///
/// The table DATA in this app is validated against NEC 2023/2026
/// and is accurate for all supported NEC editions.

/// Table stability documentation
class NecTableStability {
  NecTableStability._();

  /// Tables that are identical across all supported NEC versions
  static const List<String> stableTables = [
    'Table 310.16 - Conductor Ampacity (60°C, 75°C, 90°C)',
    'Table 310.17 - Single Conductor Ampacity',
    'Table 430.248 - Single Phase Motor FLA',
    'Table 430.250 - Three Phase Motor FLA',
    'Table 250.66 - Grounding Electrode Conductor',
    'Table 250.122 - Equipment Grounding Conductor',
    'Table 314.16(A) - Metal Box Volumes',
    'Table 314.16(B) - Volume per Conductor',
    'Table 240.6(A) - Standard Ampere Ratings',
    'Chapter 9 Table 1 - Conduit Fill Percentage',
    'Chapter 9 Table 4 - Conduit Dimensions',
    'Chapter 9 Table 5 - Wire Dimensions',
  ];

  /// Requirements that vary by NEC edition
  static const Map<String, NecVersion> versionSpecificRequirements = {
    'Outdoor outlets GFCI (dwelling)': NecVersion.nec2023,
    'Kitchen dishwasher GFCI': NecVersion.nec2020,
    'Laundry area GFCI': NecVersion.nec2020,
    'Basement GFCI (all 125V 15/20A)': NecVersion.nec2020,
    'Garage GFCI (all outlets)': NecVersion.nec2017,
    'Bathroom GFCI': NecVersion.nec2014,
    'Kitchen countertop GFCI': NecVersion.nec2014,
    'AFCI bedroom circuits': NecVersion.nec2014,
    'AFCI kitchen/laundry/family room': NecVersion.nec2017,
    'AFCI all dwelling living areas': NecVersion.nec2020,
    'Rapid shutdown solar (module level)': NecVersion.nec2020,
    'EV ready outlet in new garages': NecVersion.nec2023,
    '6 mA GFCI for personnel protection': NecVersion.nec2026,
    'Surge protection at service': NecVersion.nec2020,
  };

  /// Check if a requirement applies for given NEC version
  static bool requirementApplies(String requirement, NecVersion version) {
    final sinceVersion = versionSpecificRequirements[requirement];
    if (sinceVersion == null) return true; // Assume always required
    return version.hasFeature(sinceVersion);
  }
}

/// GFCI Requirements by NEC Version
class GfciRequirements {
  GfciRequirements._();

  /// Get GFCI-required locations for a given NEC version
  static List<String> getRequiredLocations(NecVersion version) {
    final locations = <String>[];

    // NEC 2014 and later
    if (version.hasFeature(NecVersion.nec2014)) {
      locations.addAll([
        'Bathrooms',
        'Kitchens (countertop receptacles)',
        'Outdoors (dwelling units)',
        'Crawl spaces (at or below grade)',
        'Unfinished basements',
        'Garages (some)',
        'Boat houses',
        'Bathtub/shower stall areas',
        'Rooftops',
        'Sinks (within 6 ft)',
      ]);
    }

    // NEC 2017 additions
    if (version.hasFeature(NecVersion.nec2017)) {
      locations.addAll([
        'Garages (all receptacles)',
        'Accessory buildings with floor at grade',
      ]);
    }

    // NEC 2020 additions
    if (version.hasFeature(NecVersion.nec2020)) {
      locations.addAll([
        'Basements (all 125V 15/20A receptacles)',
        'Laundry areas',
        'Kitchen dishwasher outlet',
        'Indoor damp/wet locations',
      ]);
    }

    // NEC 2023 additions
    if (version.hasFeature(NecVersion.nec2023)) {
      locations.addAll([
        'Outdoor outlets (all dwelling locations)',
        'Indoor wet locations (all)',
      ]);
    }

    // NEC 2026 additions
    if (version.hasFeature(NecVersion.nec2026)) {
      locations.addAll([
        '250V receptacles (50A or less, specific locations)',
        'Electric vehicle charging equipment (specific cases)',
      ]);
    }

    return locations;
  }
}

/// AFCI Requirements by NEC Version
class AfciRequirements {
  AfciRequirements._();

  /// Get AFCI-required locations for a given NEC version
  static List<String> getRequiredLocations(NecVersion version) {
    final locations = <String>[];

    // NEC 2014
    if (version.hasFeature(NecVersion.nec2014)) {
      locations.addAll([
        'Bedrooms',
      ]);
    }

    // NEC 2017
    if (version.hasFeature(NecVersion.nec2017)) {
      locations.addAll([
        'Kitchens',
        'Family rooms',
        'Dining rooms',
        'Living rooms',
        'Parlors',
        'Libraries',
        'Dens',
        'Recreation rooms',
        'Closets',
        'Hallways',
        'Laundry areas',
        'Similar rooms or areas',
      ]);
    }

    // NEC 2020 - essentially all habitable rooms
    if (version.hasFeature(NecVersion.nec2020)) {
      locations.addAll([
        'All 120V 15/20A branch circuits in dwelling unit living areas',
      ]);
    }

    return locations;
  }
}
