/// Entity type for a company — determines portal routing and feature access
enum CompanyType {
  contractor,
  realtorSolo,
  realtorTeam,
  brokerage,
  inspector,
  adjuster,
  preservation,
  homeowner,
  hybrid;

  /// Human-readable label
  String get label {
    switch (this) {
      case CompanyType.contractor:
        return 'Contractor';
      case CompanyType.realtorSolo:
        return 'Solo Realtor';
      case CompanyType.realtorTeam:
        return 'Realtor Team';
      case CompanyType.brokerage:
        return 'Brokerage';
      case CompanyType.inspector:
        return 'Inspector';
      case CompanyType.adjuster:
        return 'Adjuster';
      case CompanyType.preservation:
        return 'Property Preservation';
      case CompanyType.homeowner:
        return 'Homeowner';
      case CompanyType.hybrid:
        return 'Hybrid';
    }
  }

  /// Is this a realtor-type entity?
  bool get isRealtorType =>
      this == realtorSolo || this == realtorTeam || this == brokerage;

  /// Is this a contractor-type entity?
  bool get isContractorType => this == contractor;

  /// Is this an inspector entity?
  bool get isInspectorType => this == inspector;

  /// Is this an adjuster entity?
  bool get isAdjusterType => this == adjuster;

  /// Is this a homeowner entity?
  bool get isHomeownerType => this == homeowner;

  /// Parse from snake_case database string
  static CompanyType fromString(String value) {
    switch (value) {
      case 'contractor':
        return CompanyType.contractor;
      case 'realtor_solo':
        return CompanyType.realtorSolo;
      case 'realtor_team':
        return CompanyType.realtorTeam;
      case 'brokerage':
        return CompanyType.brokerage;
      case 'inspector':
        return CompanyType.inspector;
      case 'adjuster':
        return CompanyType.adjuster;
      case 'preservation':
        return CompanyType.preservation;
      case 'homeowner':
        return CompanyType.homeowner;
      case 'hybrid':
        return CompanyType.hybrid;
      default:
        return CompanyType.contractor;
    }
  }

  /// Convert to snake_case database string
  String toDbString() {
    switch (this) {
      case CompanyType.contractor:
        return 'contractor';
      case CompanyType.realtorSolo:
        return 'realtor_solo';
      case CompanyType.realtorTeam:
        return 'realtor_team';
      case CompanyType.brokerage:
        return 'brokerage';
      case CompanyType.inspector:
        return 'inspector';
      case CompanyType.adjuster:
        return 'adjuster';
      case CompanyType.preservation:
        return 'preservation';
      case CompanyType.homeowner:
        return 'homeowner';
      case CompanyType.hybrid:
        return 'hybrid';
    }
  }
}
