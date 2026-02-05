// State Building Code Adoption Data - VERIFIED RESEARCH
// Maps US states to their adopted building code (IRC/IBC)
//
// Sources:
//   - ICC (iccsafe.org) - IBC/IRC adoption maps
//   - IBHS Building Code Progress tracker
//   - NAHB 2024 I-Codes Adoption Kit
//   - Last verified: January 2026
//
// NOTE: IBC/IRC adopted in all 50 states at some level
// IRC = Residential (1-2 family + townhouses)
// IBC = Commercial + multi-family
// Always verify with local AHJ

/// Building Code types
enum BuildingCodeType {
  ibc('IBC', 'International Building Code'),
  irc('IRC', 'International Residential Code'),
  stateSpecific('STATE', 'State-Specific Building Code');

  final String abbreviation;
  final String fullName;
  const BuildingCodeType(this.abbreviation, this.fullName);

  String get displayName => fullName;
}

/// State building code data
class StateBuildingData {
  final String name;
  final String code;
  final String ircEdition;       // For residential
  final String ibcEdition;       // For commercial
  final String effectiveDate;
  final String notes;
  final bool hasLocalVariations;

  const StateBuildingData({
    required this.name,
    required this.code,
    required this.ircEdition,
    required this.ibcEdition,
    required this.effectiveDate,
    required this.notes,
    this.hasLocalVariations = false,
  });
}

/// All US states + DC with building code adoption data
class StateBuildingDatabase {
  static const List<StateBuildingData> states = [
    StateBuildingData(
      name: 'Alabama', code: 'AL',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Alaska', code: 'AK',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Arizona', code: 'AZ',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Local adoption varies',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Arkansas', code: 'AR',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Arkansas Building Code',
    ),
    StateBuildingData(
      name: 'California', code: 'CA',
      ircEdition: '2022',
      ibcEdition: '2024',
      effectiveDate: '2025-01-01',
      notes: 'California Building Code (CBC) Title 24 with amendments',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Colorado', code: 'CO',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2023-01-01',
      notes: 'Local adoption; Denver uses 2024',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Connecticut', code: 'CT',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'State Building Code',
    ),
    StateBuildingData(
      name: 'Delaware', code: 'DE',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-12-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Florida', code: 'FL',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2023-12-31',
      notes: 'Florida Building Code 8th Edition',
    ),
    StateBuildingData(
      name: 'Georgia', code: 'GA',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2023-01-01',
      notes: 'Georgia State Minimum Standard Codes',
    ),
    StateBuildingData(
      name: 'Hawaii', code: 'HI',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Idaho', code: 'ID',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2020-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Illinois', code: 'IL',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Local adoption; Chicago has separate code',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Indiana', code: 'IN',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Indiana Building Code',
    ),
    StateBuildingData(
      name: 'Iowa', code: 'IA',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Kansas', code: 'KS',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Local adoption only',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Kentucky', code: 'KY',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Kentucky Building Code',
    ),
    StateBuildingData(
      name: 'Louisiana', code: 'LA',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Louisiana State Uniform Construction Code',
    ),
    StateBuildingData(
      name: 'Maine', code: 'ME',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Maine Uniform Building and Energy Code',
    ),
    StateBuildingData(
      name: 'Maryland', code: 'MD',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Maryland Building Performance Standards',
    ),
    StateBuildingData(
      name: 'Massachusetts', code: 'MA',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2024-10-11',
      notes: '780 CMR 10th Edition; based on IBC 2021',
    ),
    StateBuildingData(
      name: 'Michigan', code: 'MI',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2024-02-09',
      notes: 'Michigan Building Code',
    ),
    StateBuildingData(
      name: 'Minnesota', code: 'MN',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2020-03-31',
      notes: 'Minnesota State Building Code',
    ),
    StateBuildingData(
      name: 'Mississippi', code: 'MS',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Missouri', code: 'MO',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Local adoption only',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Montana', code: 'MT',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Nebraska', code: 'NE',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'Local adoption',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Nevada', code: 'NV',
      ircEdition: '2021',
      ibcEdition: '2024',
      effectiveDate: '2024-07-01',
      notes: 'Las Vegas/Clark County use 2024',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'New Hampshire', code: 'NH',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'State Building Code',
    ),
    StateBuildingData(
      name: 'New Jersey', code: 'NJ',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2024-03-01',
      notes: 'Uniform Construction Code',
    ),
    StateBuildingData(
      name: 'New Mexico', code: 'NM',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'New Mexico Building Code',
    ),
    StateBuildingData(
      name: 'New York', code: 'NY',
      ircEdition: '2020',
      ibcEdition: '2020',
      effectiveDate: '2020-05-12',
      notes: 'NYS Building Code; NYC has separate code',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'North Carolina', code: 'NC',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-01-01',
      notes: 'NC State Building Code',
    ),
    StateBuildingData(
      name: 'North Dakota', code: 'ND',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Ohio', code: 'OH',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2023-07-01',
      notes: 'Ohio Building Code',
    ),
    StateBuildingData(
      name: 'Oklahoma', code: 'OK',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Local adoption',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Oregon', code: 'OR',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Oregon Structural Specialty Code',
    ),
    StateBuildingData(
      name: 'Pennsylvania', code: 'PA',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-02-14',
      notes: 'Uniform Construction Code',
    ),
    StateBuildingData(
      name: 'Rhode Island', code: 'RI',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'State Building Code',
    ),
    StateBuildingData(
      name: 'South Carolina', code: 'SC',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'South Dakota', code: 'SD',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Local adoption',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Tennessee', code: 'TN',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-03-01',
      notes: 'Local adoption; Nashville uses 2024',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Texas', code: 'TX',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-09-01',
      notes: 'Local adoption; no state code',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Utah', code: 'UT',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Vermont', code: 'VT',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Commercial mandatory; residential voluntary',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Virginia', code: 'VA',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2021-07-01',
      notes: 'Virginia Construction Code',
    ),
    StateBuildingData(
      name: 'Washington', code: 'WA',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2023-07-01',
      notes: 'Washington State Building Code',
    ),
    StateBuildingData(
      name: 'West Virginia', code: 'WV',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'Statewide adoption',
    ),
    StateBuildingData(
      name: 'Wisconsin', code: 'WI',
      ircEdition: '2018',
      ibcEdition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Wisconsin Comm 62',
    ),
    StateBuildingData(
      name: 'Wyoming', code: 'WY',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Local adoption',
      hasLocalVariations: true,
    ),
    StateBuildingData(
      name: 'Washington DC', code: 'DC',
      ircEdition: '2021',
      ibcEdition: '2021',
      effectiveDate: '2022-06-01',
      notes: 'DC Construction Code',
    ),
  ];

  /// Get state by code (e.g., 'TX')
  static StateBuildingData? getByCode(String code) {
    final upperCode = code.toUpperCase();
    try {
      return states.firstWhere((s) => s.code == upperCode);
    } catch (_) {
      return null;
    }
  }

  /// Get state by name
  static StateBuildingData? getByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return states.firstWhere((s) => s.name.toLowerCase() == lowerName);
    } catch (_) {
      return null;
    }
  }

  /// Get all states using a specific IRC edition
  static List<StateBuildingData> getByIrcEdition(String edition) {
    return states.where((s) => s.ircEdition == edition).toList();
  }

  /// Get all states using a specific IBC edition
  static List<StateBuildingData> getByIbcEdition(String edition) {
    return states.where((s) => s.ibcEdition == edition).toList();
  }

  /// Get states sorted alphabetically
  static List<StateBuildingData> get sortedByName {
    final sorted = List<StateBuildingData>.from(states);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get count by IRC edition for stats
  static Map<String, int> get ircEditionCounts {
    final counts = <String, int>{};
    for (final state in states) {
      counts[state.ircEdition] = (counts[state.ircEdition] ?? 0) + 1;
    }
    return counts;
  }

  /// Get count by IBC edition for stats
  static Map<String, int> get ibcEditionCounts {
    final counts = <String, int>{};
    for (final state in states) {
      counts[state.ibcEdition] = (counts[state.ibcEdition] ?? 0) + 1;
    }
    return counts;
  }
}
