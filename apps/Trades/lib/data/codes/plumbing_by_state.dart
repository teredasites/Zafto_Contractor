// State Plumbing Code Adoption Data - VERIFIED RESEARCH
// Maps US states to their adopted plumbing code (IPC vs UPC vs State-specific)
//
// Sources:
//   - ICC (iccsafe.org) - IPC adoption
//   - IAPMO (iapmo.org) - UPC adoption
//   - garynsmith.net, greendrains.com - Cross-referenced
//   - Last verified: January 2026
//
// NOTE: Always verify with local AHJ - adoptions change

/// Plumbing Code types
enum PlumbingCodeType {
  ipc('IPC', 'International Plumbing Code'),
  upc('UPC', 'Uniform Plumbing Code'),
  nspc('NSPC', 'National Standard Plumbing Code'),
  stateSpecific('STATE', 'State-Specific Code'),
  local('LOCAL', 'Local Adoption Only');

  final String abbreviation;
  final String fullName;
  const PlumbingCodeType(this.abbreviation, this.fullName);

  String get displayName => fullName;
}

/// State plumbing code data
class StatePlumbingData {
  final String name;
  final String code;
  final PlumbingCodeType codeType;
  final String edition;
  final String effectiveDate;
  final String notes;
  final bool hasLocalVariations;

  const StatePlumbingData({
    required this.name,
    required this.code,
    required this.codeType,
    required this.edition,
    required this.effectiveDate,
    required this.notes,
    this.hasLocalVariations = false,
  });
}

/// All US states + DC with plumbing code adoption data
class StatePlumbingDatabase {
  static const List<StatePlumbingData> states = [
    // ===== IPC STATES (International Plumbing Code) ~35 states =====

    StatePlumbingData(
      name: 'Alabama', code: 'AL',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Arkansas', code: 'AR',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Colorado', code: 'CO',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2023-01-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Connecticut', code: 'CT',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'State Building Code incorporates IPC',
    ),
    StatePlumbingData(
      name: 'Delaware', code: 'DE',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-12-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Florida', code: 'FL',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2023-12-31',
      notes: 'Florida Building Code 8th Edition',
    ),
    StatePlumbingData(
      name: 'Georgia', code: 'GA',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2023-01-01',
      notes: 'Georgia State Minimum Standard Codes',
    ),
    StatePlumbingData(
      name: 'Indiana', code: 'IN',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Indiana Plumbing Code based on IPC with amendments',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Kansas', code: 'KS',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Local adoption of IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Maryland', code: 'MD',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Maryland Building Performance Standards',
    ),
    StatePlumbingData(
      name: 'Michigan', code: 'MI',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2021-09-15',
      notes: 'Michigan Plumbing Code based on IPC',
    ),
    StatePlumbingData(
      name: 'Mississippi', code: 'MS',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Local adoption varies',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Nebraska', code: 'NE',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'Local municipalities adopt IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Nevada', code: 'NV',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Some jurisdictions use UPC; verify locally',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'New Hampshire', code: 'NH',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'New York', code: 'NY',
      codeType: PlumbingCodeType.ipc,
      edition: '2020',
      effectiveDate: '2020-05-12',
      notes: 'NYS Plumbing Code; NYC has separate code',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'North Carolina', code: 'NC',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-01-01',
      notes: 'NC State Plumbing Code',
    ),
    StatePlumbingData(
      name: 'North Dakota', code: 'ND',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Ohio', code: 'OH',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2023-07-01',
      notes: 'Ohio Plumbing Code based on IPC',
    ),
    StatePlumbingData(
      name: 'Oklahoma', code: 'OK',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Pennsylvania', code: 'PA',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-02-14',
      notes: 'UCC incorporates IPC',
    ),
    StatePlumbingData(
      name: 'Rhode Island', code: 'RI',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'State Building Code',
    ),
    StatePlumbingData(
      name: 'South Carolina', code: 'SC',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2020-01-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Tennessee', code: 'TN',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-03-01',
      notes: 'Local adoption of IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Texas', code: 'TX',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-09-01',
      notes: 'Texas State Plumbing Code based on IPC',
    ),
    StatePlumbingData(
      name: 'Utah', code: 'UT',
      codeType: PlumbingCodeType.ipc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Vermont', code: 'VT',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'State Plumbing Code',
    ),
    StatePlumbingData(
      name: 'Virginia', code: 'VA',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2021-07-01',
      notes: 'Virginia Construction Code',
    ),
    StatePlumbingData(
      name: 'West Virginia', code: 'WV',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-09-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Wyoming', code: 'WY',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Statewide IPC adoption',
    ),
    StatePlumbingData(
      name: 'Washington DC', code: 'DC',
      codeType: PlumbingCodeType.ipc,
      edition: '2018',
      effectiveDate: '2020-05-29',
      notes: 'DC Construction Code',
    ),

    // ===== UPC STATES (Uniform Plumbing Code) ~15 states =====

    StatePlumbingData(
      name: 'Alaska', code: 'AK',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Statewide UPC; some local use IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Arizona', code: 'AZ',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide UPC; some local use IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'California', code: 'CA',
      codeType: PlumbingCodeType.upc,
      edition: '2022',
      effectiveDate: '2023-01-01',
      notes: 'California Plumbing Code (CPC) based on UPC with amendments',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Hawaii', code: 'HI',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-01-01',
      notes: 'Statewide UPC adoption',
    ),
    StatePlumbingData(
      name: 'Idaho', code: 'ID',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide UPC adoption',
    ),
    StatePlumbingData(
      name: 'Iowa', code: 'IA',
      codeType: PlumbingCodeType.upc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'UPC statewide; some local use IPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Missouri', code: 'MO',
      codeType: PlumbingCodeType.upc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Local adoption of UPC',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Montana', code: 'MT',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Statewide UPC adoption',
    ),
    StatePlumbingData(
      name: 'New Mexico', code: 'NM',
      codeType: PlumbingCodeType.upc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'NM Plumbing Code based on UPC',
    ),
    StatePlumbingData(
      name: 'Oregon', code: 'OR',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-10-01',
      notes: 'Oregon Specialty Plumbing Code based on UPC',
    ),
    StatePlumbingData(
      name: 'South Dakota', code: 'SD',
      codeType: PlumbingCodeType.upc,
      edition: '2018',
      effectiveDate: '2019-07-01',
      notes: 'Statewide UPC adoption',
    ),
    StatePlumbingData(
      name: 'Washington', code: 'WA',
      codeType: PlumbingCodeType.upc,
      edition: '2021',
      effectiveDate: '2022-07-01',
      notes: 'Washington State Plumbing Code based on UPC',
    ),

    // ===== STATE-SPECIFIC CODES =====

    StatePlumbingData(
      name: 'Illinois', code: 'IL',
      codeType: PlumbingCodeType.stateSpecific,
      edition: '2014',
      effectiveDate: '2014-01-01',
      notes: 'Illinois Plumbing Code (state-specific)',
    ),
    StatePlumbingData(
      name: 'Kentucky', code: 'KY',
      codeType: PlumbingCodeType.stateSpecific,
      edition: '2017',
      effectiveDate: '2017-07-01',
      notes: 'Kentucky State Plumbing Code',
    ),
    StatePlumbingData(
      name: 'Louisiana', code: 'LA',
      codeType: PlumbingCodeType.ipc,
      edition: '2012',
      effectiveDate: '2013-01-01',
      notes: 'Louisiana State Plumbing Code based on IPC 2012',
    ),
    StatePlumbingData(
      name: 'Maine', code: 'ME',
      codeType: PlumbingCodeType.stateSpecific,
      edition: '2020',
      effectiveDate: '2020-07-01',
      notes: 'Maine Internal Plumbing Code',
    ),
    StatePlumbingData(
      name: 'Massachusetts', code: 'MA',
      codeType: PlumbingCodeType.stateSpecific,
      edition: '2020',
      effectiveDate: '2020-10-01',
      notes: '248 CMR - Uniform State Plumbing Code',
    ),
    StatePlumbingData(
      name: 'Minnesota', code: 'MN',
      codeType: PlumbingCodeType.upc,
      edition: '2020',
      effectiveDate: '2020-03-31',
      notes: 'Minnesota Plumbing Code based on UPC 2012 with amendments',
      hasLocalVariations: true,
    ),
    StatePlumbingData(
      name: 'Wisconsin', code: 'WI',
      codeType: PlumbingCodeType.stateSpecific,
      edition: '2020',
      effectiveDate: '2020-07-01',
      notes: 'Wisconsin Statutes Comm 81-87',
    ),

    // ===== NSPC STATE =====

    StatePlumbingData(
      name: 'New Jersey', code: 'NJ',
      codeType: PlumbingCodeType.nspc,
      edition: '2018',
      effectiveDate: '2019-09-05',
      notes: 'National Standard Plumbing Code (NSPC)',
    ),
  ];

  /// Get state by code (e.g., 'TX')
  static StatePlumbingData? getByCode(String code) {
    final upperCode = code.toUpperCase();
    try {
      return states.firstWhere((s) => s.code == upperCode);
    } catch (_) {
      return null;
    }
  }

  /// Get state by name
  static StatePlumbingData? getByName(String name) {
    final lowerName = name.toLowerCase();
    try {
      return states.firstWhere((s) => s.name.toLowerCase() == lowerName);
    } catch (_) {
      return null;
    }
  }

  /// Get all states using a specific code type
  static List<StatePlumbingData> getByCodeType(PlumbingCodeType codeType) {
    return states.where((s) => s.codeType == codeType).toList();
  }

  /// Get IPC states
  static List<StatePlumbingData> get ipcStates =>
      getByCodeType(PlumbingCodeType.ipc);

  /// Get UPC states
  static List<StatePlumbingData> get upcStates =>
      getByCodeType(PlumbingCodeType.upc);

  /// Get states sorted alphabetically
  static List<StatePlumbingData> get sortedByName {
    final sorted = List<StatePlumbingData>.from(states);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get count by code type for stats
  static Map<PlumbingCodeType, int> get codeTypeCounts {
    final counts = <PlumbingCodeType, int>{};
    for (final state in states) {
      counts[state.codeType] = (counts[state.codeType] ?? 0) + 1;
    }
    return counts;
  }
}
