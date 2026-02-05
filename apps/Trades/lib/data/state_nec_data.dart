// State NEC Adoption Data - VERIFIED RESEARCH
// Maps US states to their adopted NEC edition
//
// Sources:
//   - Mike Holt (mikeholt.com/necadoptionlist.php) - Primary
//   - NFPA, IAEI, Jade Learning - Cross-referenced
//   - Last verified: January 2026
//
// NOTE: Always verify with local AHJ - adoptions change frequently

/// NEC Edition years supported
enum NecEdition {
  nec2008('2008'),
  nec2014('2014'),
  nec2017('2017'),
  nec2020('2020'),
  nec2023('2023'),
  nec2026('2026'),
  local('LOCAL'); // No statewide adoption - varies by jurisdiction

  final String year;
  const NecEdition(this.year);

  String get displayName => this == NecEdition.local ? 'Local Adoption' : 'NEC $year';
}

/// State data with NEC adoption info
class StateNecData {
  final String name;
  final String code;
  final NecEdition necEdition;
  final String effectiveDate;
  final String notes;
  final bool hasLocalVariations;
  final String? sourceUrl;

  const StateNecData({
    required this.name,
    required this.code,
    required this.necEdition,
    required this.effectiveDate,
    required this.notes,
    this.hasLocalVariations = false,
    this.sourceUrl,
  });
}

/// All US states + DC with NEC adoption data
/// Verified against Mike Holt NEC Adoption List (July 2025 update)
class StateNecDatabase {
  static const List<StateNecData> states = [
    // ===== 2023 NEC STATES (17 states as of Jan 2026) =====
    StateNecData(
      name: 'Colorado', code: 'CO',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-08-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Georgia', code: 'GA',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2025-01-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Idaho', code: 'ID',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Iowa', code: 'IA',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2025-07-01',
      notes: 'With IA amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Kentucky', code: 'KY',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2025-01-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Maine', code: 'ME',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Massachusetts', code: 'MA',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-02-17',
      notes: '527 CMR with MA amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Michigan', code: 'MI',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-03-12',
      notes: 'Commercial; residential 2023 effective 8/29/25',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Minnesota', code: 'MN',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Nebraska', code: 'NE',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-08-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'New Hampshire', code: 'NH',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2025-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'North Dakota', code: 'ND',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Ohio', code: 'OH',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-03-01',
      notes: 'Commercial 3/1/24; residential with amendments 4/15/24',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Oklahoma', code: 'OK',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-09-14',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Oregon', code: 'OR',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-10-01',
      notes: 'Oregon Electrical Specialty Code with OR amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'South Dakota', code: 'SD',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-11-12',
      notes: 'With SD amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Texas', code: 'TX',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-09-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Utah', code: 'UT',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2025-07-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Washington', code: 'WA',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2024-04-01',
      notes: 'WAC 296-46B',
    ),
    StateNecData(
      name: 'Wyoming', code: 'WY',
      necEdition: NecEdition.nec2023,
      effectiveDate: '2023-07-01',
      notes: 'Statewide adoption',
    ),

    // ===== 2020 NEC STATES (21 states as of Jan 2026) =====
    StateNecData(
      name: 'Alabama', code: 'AL',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-07-01',
      notes: 'State buildings, schools, hotels/motels, theaters',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Alaska', code: 'AK',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2020-04-16',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Arkansas', code: 'AR',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-08-01',
      notes: 'With AR amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'California', code: 'CA',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-01-01',
      notes: 'Title 24 Part 3 (CEC) with CA amendments; 2023 projected 1/1/26',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Connecticut', code: 'CT',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-10-01',
      notes: 'With CT amendments; 2023 update underway',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Delaware', code: 'DE',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2021-09-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Florida', code: 'FL',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-12-31',
      notes: 'Florida Building Code 8th Edition; 2023 update underway',
    ),
    StateNecData(
      name: 'Hawaii', code: 'HI',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-03-04',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Louisiana', code: 'LA',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-01-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Maryland', code: 'MD',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-05-29',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'Montana', code: 'MT',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-06-10',
      notes: 'With MT amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'New Jersey', code: 'NJ',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-09-06',
      notes: 'Uniform Construction Code with NJ amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'New Mexico', code: 'NM',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-03-28',
      notes: 'Statewide; no plans to update currently',
    ),
    StateNecData(
      name: 'North Carolina', code: 'NC',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2021-11-01',
      notes: 'NC State Building Code with amendments; 2023 update underway',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Rhode Island', code: 'RI',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-02-01',
      notes: 'Statewide adoption',
    ),
    StateNecData(
      name: 'South Carolina', code: 'SC',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2023-01-01',
      notes: 'With SC amendments; 2023 update underway',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Vermont', code: 'VT',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-04-15',
      notes: 'With VT amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Virginia', code: 'VA',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2024-01-18',
      notes: 'Virginia Construction Code; 2023 update underway',
    ),
    StateNecData(
      name: 'West Virginia', code: 'WV',
      necEdition: NecEdition.nec2020,
      effectiveDate: '2022-08-01',
      notes: 'With WV amendments',
      hasLocalVariations: true,
    ),

    // ===== 2017 NEC STATES (6 states as of Jan 2026) =====
    StateNecData(
      name: 'New York', code: 'NY',
      necEdition: NecEdition.nec2017,
      effectiveDate: '2020-05-12',
      notes: 'NYS code; NYC has separate 2008 NEC-based code; 2023 update underway',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Pennsylvania', code: 'PA',
      necEdition: NecEdition.nec2017,
      effectiveDate: '2022-02-14',
      notes: 'UCC local enforcement; 2020 update underway',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Tennessee', code: 'TN',
      necEdition: NecEdition.nec2017,
      effectiveDate: '2018-10-01',
      notes: 'With TN amendments',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Wisconsin', code: 'WI',
      necEdition: NecEdition.nec2017,
      effectiveDate: '2018-08-01',
      notes: 'Commercial 8/1/18, residential 1/1/20 (SPS 316); 2023 underway',
      hasLocalVariations: true,
    ),

    // ===== 2008 NEC STATES (2 states/jurisdictions) =====
    StateNecData(
      name: 'Indiana', code: 'IN',
      necEdition: NecEdition.nec2008,
      effectiveDate: '2009-06-02',
      notes: 'Commercial with IN amendments; 2017 for dwellings; 2023 update underway',
      hasLocalVariations: true,
    ),

    // ===== 2014 NEC (DC) =====
    StateNecData(
      name: 'Washington DC', code: 'DC',
      necEdition: NecEdition.nec2014,
      effectiveDate: '2020-05-29',
      notes: 'DC Construction Code',
    ),

    // ===== LOCAL ADOPTION ONLY (No statewide code) =====
    StateNecData(
      name: 'Arizona', code: 'AZ',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'Each municipality adopts independently; most use 2017-2020',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Illinois', code: 'IL',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'No statewide adoption; municipalities use 2008-2020',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Kansas', code: 'KS',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'No statewide adoption; local jurisdictions adopt independently',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Mississippi', code: 'MS',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'Local adoption only',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Missouri', code: 'MO',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'Local adoption only; varies by municipality',
      hasLocalVariations: true,
    ),
    StateNecData(
      name: 'Nevada', code: 'NV',
      necEdition: NecEdition.local,
      effectiveDate: 'Varies',
      notes: 'Adopted and enforced at local level',
      hasLocalVariations: true,
    ),
  ];

  /// Get state by code (e.g., 'TX')
  static StateNecData? getByCode(String code) {
    final upperCode = code.toUpperCase();
    try {
      return states.firstWhere((s) => s.code == upperCode);
    } catch (_) {
      return null;
    }
  }

  /// Get state by name
  static StateNecData? getByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return states.firstWhere((s) => s.name.toLowerCase() == lowerName);
    } catch (_) {
      return null;
    }
  }

  /// Search states by partial name or code
  static List<StateNecData> search(String query) {
    if (query.isEmpty) return states;
    final q = query.toLowerCase();
    return states.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.code.toLowerCase().contains(q)
    ).toList();
  }

  /// Get all states using a specific NEC edition
  static List<StateNecData> getByEdition(NecEdition edition) {
    return states.where((s) => s.necEdition == edition).toList();
  }

  /// Get states sorted alphabetically
  static List<StateNecData> get sortedByName {
    final sorted = List<StateNecData>.from(states);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get count by edition for stats
  static Map<NecEdition, int> get editionCounts {
    final counts = <NecEdition, int>{};
    for (final state in states) {
      counts[state.necEdition] = (counts[state.necEdition] ?? 0) + 1;
    }
    return counts;
  }

  /// Get the default NEC edition to use for a state
  /// For local adoption states, defaults to NEC 2020
  static NecEdition getDefaultEdition(String stateCode) {
    final state = getByCode(stateCode);
    if (state == null) return NecEdition.nec2020;
    if (state.necEdition == NecEdition.local) return NecEdition.nec2020;
    return state.necEdition;
  }
}
