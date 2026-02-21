// ZAFTO Property Intelligence Models
// Created: DEPTH28 — Property Recon Mega-Expansion
//
// Immutable models for:
// PropertyProfile, WeatherIntelligence, PermitRecord,
// TradeAutoScope, ScopeItem, CodeRequirement, CrossTradeDependency

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// PROPERTY PROFILE
// ════════════════════════════════════════════════════════════════

class PropertyProfile extends Equatable {
  final String id;
  final String scanId;
  // Construction
  final int? yearBuilt;
  final double? livingSqft;
  final double? lotSqft;
  final int? stories;
  final int? bedrooms;
  final int? bathroomsFull;
  final int? bathroomsHalf;
  final String? constructionType;
  final String? foundationType;
  final String? roofStyle;
  final String? exteriorMaterial;
  // Ownership
  final String? ownerName;
  final double? assessedValue;
  final double? marketValueEst;
  final double? lastSalePrice;
  final String? lastSaleDate;
  final int? ownershipYears;
  // Utilities
  final String? heatingType;
  final String? coolingType;
  final String? electricUtility;
  final String? gasUtility;
  final int? serviceAmperage;
  final String? servicePhase;
  // Environmental
  final String? leadPaintProbability;
  final String? asbestosProbability;
  final String? radonZone;
  final String? termiteZone;
  final String? floodZone;
  final String? floodRiskLevel;
  final double? wildfireRiskScore;
  final String? seismicZone;
  final String? expansiveSoilRisk;
  // HOA
  final String? hoaName;
  final bool hoaArchitecturalReview;
  // Codes
  final String? jurisdiction;
  final String? ibcIrcYear;
  final String? necYear;
  final String? ieccYear;
  final double? windSpeedMph;
  final double? snowLoadPsf;
  final double? frostLineDepthInches;
  final String? climateZone;
  // Meta
  final int confidenceScore;
  final List<String> dataSources;
  final DateTime createdAt;

  const PropertyProfile({
    required this.id,
    required this.scanId,
    this.yearBuilt,
    this.livingSqft,
    this.lotSqft,
    this.stories,
    this.bedrooms,
    this.bathroomsFull,
    this.bathroomsHalf,
    this.constructionType,
    this.foundationType,
    this.roofStyle,
    this.exteriorMaterial,
    this.ownerName,
    this.assessedValue,
    this.marketValueEst,
    this.lastSalePrice,
    this.lastSaleDate,
    this.ownershipYears,
    this.heatingType,
    this.coolingType,
    this.electricUtility,
    this.gasUtility,
    this.serviceAmperage,
    this.servicePhase,
    this.leadPaintProbability,
    this.asbestosProbability,
    this.radonZone,
    this.termiteZone,
    this.floodZone,
    this.floodRiskLevel,
    this.wildfireRiskScore,
    this.seismicZone,
    this.expansiveSoilRisk,
    this.hoaName,
    this.hoaArchitecturalReview = false,
    this.jurisdiction,
    this.ibcIrcYear,
    this.necYear,
    this.ieccYear,
    this.windSpeedMph,
    this.snowLoadPsf,
    this.frostLineDepthInches,
    this.climateZone,
    this.confidenceScore = 0,
    this.dataSources = const [],
    required this.createdAt,
  });

  factory PropertyProfile.fromJson(Map<String, dynamic> json) {
    return PropertyProfile(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      yearBuilt: _parseInt(json['year_built']),
      livingSqft: _parseDouble(json['living_area_sqft']),
      lotSqft: _parseDouble(json['lot_area_sqft']),
      stories: _parseInt(json['stories']),
      bedrooms: _parseInt(json['bedrooms']),
      bathroomsFull: _parseInt(json['bathrooms_full']),
      bathroomsHalf: _parseInt(json['bathrooms_half']),
      constructionType: json['construction_type'] as String?,
      foundationType: json['foundation_type'] as String?,
      roofStyle: json['roof_style'] as String?,
      exteriorMaterial: json['exterior_material'] as String?,
      ownerName: json['owner_name'] as String?,
      assessedValue: _parseDouble(json['assessed_value']),
      marketValueEst: _parseDouble(json['market_value_est']),
      lastSalePrice: _parseDouble(json['last_sale_price']),
      lastSaleDate: json['last_sale_date'] as String?,
      ownershipYears: _parseInt(json['ownership_years']),
      heatingType: json['heating_type'] as String?,
      coolingType: json['cooling_type'] as String?,
      electricUtility: json['electric_utility'] as String?,
      gasUtility: json['gas_utility'] as String?,
      serviceAmperage: _parseInt(json['service_amperage']),
      servicePhase: json['service_phase'] as String?,
      leadPaintProbability: json['lead_paint_probability'] as String?,
      asbestosProbability: json['asbestos_probability'] as String?,
      radonZone: json['radon_zone'] as String?,
      termiteZone: json['termite_zone'] as String?,
      floodZone: json['flood_zone'] as String?,
      floodRiskLevel: json['flood_risk_level'] as String?,
      wildfireRiskScore: _parseDouble(json['wildfire_risk_score']),
      seismicZone: json['seismic_zone'] as String?,
      expansiveSoilRisk: json['expansive_soil_risk'] as String?,
      hoaName: json['hoa_name'] as String?,
      hoaArchitecturalReview: json['hoa_architectural_review'] == true,
      jurisdiction: json['jurisdiction'] as String?,
      ibcIrcYear: json['ibc_irc_year'] as String?,
      necYear: json['nec_year'] as String?,
      ieccYear: json['iecc_year'] as String?,
      windSpeedMph: _parseDouble(json['wind_speed_mph']),
      snowLoadPsf: _parseDouble(json['snow_load_psf']),
      frostLineDepthInches: _parseDouble(json['frost_line_depth_inches']),
      climateZone: json['climate_zone'] as String?,
      confidenceScore: _parseIntSafe(json['confidence_score']),
      dataSources: _parseStringList(json['data_sources']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scan_id': scanId,
    'year_built': yearBuilt,
    'living_area_sqft': livingSqft,
    'lot_area_sqft': lotSqft,
    'stories': stories,
    'bedrooms': bedrooms,
    'bathrooms_full': bathroomsFull,
    'bathrooms_half': bathroomsHalf,
    'construction_type': constructionType,
    'foundation_type': foundationType,
    'roof_style': roofStyle,
    'exterior_material': exteriorMaterial,
    'owner_name': ownerName,
    'assessed_value': assessedValue,
    'market_value_est': marketValueEst,
    'last_sale_price': lastSalePrice,
    'last_sale_date': lastSaleDate,
    'ownership_years': ownershipYears,
    'heating_type': heatingType,
    'cooling_type': coolingType,
    'electric_utility': electricUtility,
    'gas_utility': gasUtility,
    'service_amperage': serviceAmperage,
    'service_phase': servicePhase,
    'lead_paint_probability': leadPaintProbability,
    'asbestos_probability': asbestosProbability,
    'radon_zone': radonZone,
    'termite_zone': termiteZone,
    'flood_zone': floodZone,
    'flood_risk_level': floodRiskLevel,
    'wildfire_risk_score': wildfireRiskScore,
    'seismic_zone': seismicZone,
    'expansive_soil_risk': expansiveSoilRisk,
    'hoa_name': hoaName,
    'hoa_architectural_review': hoaArchitecturalReview,
    'jurisdiction': jurisdiction,
    'ibc_irc_year': ibcIrcYear,
    'nec_year': necYear,
    'iecc_year': ieccYear,
    'wind_speed_mph': windSpeedMph,
    'snow_load_psf': snowLoadPsf,
    'frost_line_depth_inches': frostLineDepthInches,
    'climate_zone': climateZone,
    'confidence_score': confidenceScore,
    'data_sources': dataSources,
  };

  @override
  List<Object?> get props => [id, scanId];

  // Computed helpers
  bool get hasEnvironmentalRisks =>
    leadPaintProbability == 'high' ||
    asbestosProbability == 'high' ||
    radonZone == '1' ||
    floodRiskLevel == 'high' ||
    (wildfireRiskScore != null && wildfireRiskScore! >= 70);

  String get propertyAge {
    if (yearBuilt == null) return 'Unknown';
    final age = DateTime.now().year - yearBuilt!;
    return '$age years';
  }

  String get formattedValue {
    if (marketValueEst != null) return '\$${_formatNumber(marketValueEst!)}';
    if (assessedValue != null) return '\$${_formatNumber(assessedValue!)}';
    return 'Unknown';
  }
}

// ════════════════════════════════════════════════════════════════
// WEATHER INTELLIGENCE
// ════════════════════════════════════════════════════════════════

class WeatherIntelligence extends Equatable {
  final String id;
  final String scanId;
  // Current
  final double? currentTempF;
  final double? currentWindMph;
  final double? currentPrecipMm;
  final int? currentUvIndex;
  final String? currentConditions;
  final DateTime? weatherFetchedAt;
  // Storm history
  final String? lastHailEventDate;
  final double? lastHailSizeInches;
  final String? lastTornadoDate;
  final String? lastFloodEventDate;
  final int totalStormEvents5yr;
  final int totalStormEvents10yr;
  // Climate
  final int? freezeThawCyclesYr;
  final double? annualPrecipInches;
  final int? heatingDegreeDays;
  final int? coolingDegreeDays;
  // Storm damage score
  final int stormDamageScore;
  final Map<String, dynamic> stormScoreFactors;
  final DateTime createdAt;

  const WeatherIntelligence({
    required this.id,
    required this.scanId,
    this.currentTempF,
    this.currentWindMph,
    this.currentPrecipMm,
    this.currentUvIndex,
    this.currentConditions,
    this.weatherFetchedAt,
    this.lastHailEventDate,
    this.lastHailSizeInches,
    this.lastTornadoDate,
    this.lastFloodEventDate,
    this.totalStormEvents5yr = 0,
    this.totalStormEvents10yr = 0,
    this.freezeThawCyclesYr,
    this.annualPrecipInches,
    this.heatingDegreeDays,
    this.coolingDegreeDays,
    this.stormDamageScore = 0,
    this.stormScoreFactors = const {},
    required this.createdAt,
  });

  factory WeatherIntelligence.fromJson(Map<String, dynamic> json) {
    return WeatherIntelligence(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      currentTempF: _parseDouble(json['current_temp_f']),
      currentWindMph: _parseDouble(json['current_wind_mph']),
      currentPrecipMm: _parseDouble(json['current_precip_mm']),
      currentUvIndex: _parseInt(json['current_uv_index']),
      currentConditions: json['current_conditions'] as String?,
      weatherFetchedAt: _parseDate(json['weather_fetched_at']),
      lastHailEventDate: json['last_hail_event_date'] as String?,
      lastHailSizeInches: _parseDouble(json['last_hail_size_inches']),
      lastTornadoDate: json['last_tornado_date'] as String?,
      lastFloodEventDate: json['last_flood_event_date'] as String?,
      totalStormEvents5yr: _parseIntSafe(json['total_storm_events_5yr']),
      totalStormEvents10yr: _parseIntSafe(json['total_storm_events_10yr']),
      freezeThawCyclesYr: _parseInt(json['freeze_thaw_cycles_yr']),
      annualPrecipInches: _parseDouble(json['annual_precip_inches']),
      heatingDegreeDays: _parseInt(json['heating_degree_days']),
      coolingDegreeDays: _parseInt(json['cooling_degree_days']),
      stormDamageScore: _parseIntSafe(json['storm_damage_score']),
      stormScoreFactors: (json['storm_score_factors'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scan_id': scanId,
    'current_temp_f': currentTempF,
    'current_wind_mph': currentWindMph,
    'current_precip_mm': currentPrecipMm,
    'current_uv_index': currentUvIndex,
    'current_conditions': currentConditions,
    'weather_fetched_at': weatherFetchedAt?.toIso8601String(),
    'last_hail_event_date': lastHailEventDate,
    'last_hail_size_inches': lastHailSizeInches,
    'last_tornado_date': lastTornadoDate,
    'last_flood_event_date': lastFloodEventDate,
    'total_storm_events_5yr': totalStormEvents5yr,
    'total_storm_events_10yr': totalStormEvents10yr,
    'freeze_thaw_cycles_yr': freezeThawCyclesYr,
    'annual_precip_inches': annualPrecipInches,
    'heating_degree_days': heatingDegreeDays,
    'cooling_degree_days': coolingDegreeDays,
    'storm_damage_score': stormDamageScore,
    'storm_score_factors': stormScoreFactors,
  };

  @override
  List<Object?> get props => [id, scanId];

  // Computed
  String get stormDamageLabel {
    if (stormDamageScore >= 80) return 'Very High';
    if (stormDamageScore >= 60) return 'High';
    if (stormDamageScore >= 40) return 'Moderate';
    if (stormDamageScore >= 20) return 'Low';
    return 'Minimal';
  }

  bool get hasRecentStormDamage =>
    lastHailEventDate != null || lastTornadoDate != null || lastFloodEventDate != null;
}

// ════════════════════════════════════════════════════════════════
// PERMIT RECORD
// ════════════════════════════════════════════════════════════════

class PermitRecord extends Equatable {
  final String id;
  final String scanId;
  final String? permitNumber;
  final String? permitType;
  final String? description;
  final String? contractorName;
  final String? filedDate;
  final String? issuedDate;
  final String? finalDate;
  final String status;
  final double? estimatedCost;
  final bool isRedFlag;
  final String? redFlagReason;
  final DateTime createdAt;

  const PermitRecord({
    required this.id,
    required this.scanId,
    this.permitNumber,
    this.permitType,
    this.description,
    this.contractorName,
    this.filedDate,
    this.issuedDate,
    this.finalDate,
    this.status = 'unknown',
    this.estimatedCost,
    this.isRedFlag = false,
    this.redFlagReason,
    required this.createdAt,
  });

  factory PermitRecord.fromJson(Map<String, dynamic> json) {
    return PermitRecord(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      permitNumber: json['permit_number'] as String?,
      permitType: json['permit_type'] as String?,
      description: json['description'] as String?,
      contractorName: json['contractor_name'] as String?,
      filedDate: json['filed_date'] as String?,
      issuedDate: json['issued_date'] as String?,
      finalDate: json['final_date'] as String?,
      status: (json['status'] as String?) ?? 'unknown',
      estimatedCost: _parseDouble(json['estimated_cost']),
      isRedFlag: json['is_red_flag'] == true,
      redFlagReason: json['red_flag_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scan_id': scanId,
    'permit_number': permitNumber,
    'permit_type': permitType,
    'description': description,
    'contractor_name': contractorName,
    'filed_date': filedDate,
    'issued_date': issuedDate,
    'final_date': finalDate,
    'status': status,
    'estimated_cost': estimatedCost,
    'is_red_flag': isRedFlag,
    'red_flag_reason': redFlagReason,
  };

  @override
  List<Object?> get props => [id, scanId, permitNumber];

  bool get isOpen => status != 'closed' && status != 'final' && status != 'expired';
}

// ════════════════════════════════════════════════════════════════
// TRADE AUTO-SCOPE
// ════════════════════════════════════════════════════════════════

class ScopeItem extends Equatable {
  final String category;
  final String item;
  final String label;
  final String value;
  final String unit;
  final String source;
  final int confidence;

  const ScopeItem({
    required this.category,
    required this.item,
    required this.label,
    required this.value,
    this.unit = '',
    this.source = '',
    this.confidence = 0,
  });

  factory ScopeItem.fromJson(Map<String, dynamic> json) {
    return ScopeItem(
      category: (json['category'] as String?) ?? '',
      item: (json['item'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
      unit: (json['unit'] as String?) ?? '',
      source: (json['source'] as String?) ?? '',
      confidence: _parseIntSafe(json['confidence']),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'item': item,
    'label': label,
    'value': value,
    'unit': unit,
    'source': source,
    'confidence': confidence,
  };

  @override
  List<Object?> get props => [category, item];
}

class CodeRequirement extends Equatable {
  final String codeType;
  final String year;
  final String requirement;
  final String? section;

  const CodeRequirement({
    required this.codeType,
    required this.year,
    required this.requirement,
    this.section,
  });

  factory CodeRequirement.fromJson(Map<String, dynamic> json) {
    return CodeRequirement(
      codeType: (json['code_type'] as String?) ?? '',
      year: (json['year'] as String?) ?? '',
      requirement: (json['requirement'] as String?) ?? '',
      section: json['section'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code_type': codeType,
    'year': year,
    'requirement': requirement,
    'section': section,
  };

  @override
  List<Object?> get props => [codeType, requirement];
}

enum DependencyPriority { before, after, concurrent }

class CrossTradeDependency extends Equatable {
  final String trade;
  final String reason;
  final DependencyPriority priority;

  const CrossTradeDependency({
    required this.trade,
    required this.reason,
    this.priority = DependencyPriority.before,
  });

  factory CrossTradeDependency.fromJson(Map<String, dynamic> json) {
    return CrossTradeDependency(
      trade: (json['trade'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      priority: _parseDependencyPriority(json['priority'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'trade': trade,
    'reason': reason,
    'priority': priority.name,
  };

  @override
  List<Object?> get props => [trade, reason];
}

class TradeAutoScope extends Equatable {
  final String id;
  final String scanId;
  final String trade;
  final String scopeSummary;
  final List<ScopeItem> scopeItems;
  final List<CodeRequirement> codeRequirements;
  final bool permitsRequired;
  final List<String> permitTypes;
  final List<CrossTradeDependency> dependencies;
  final int confidenceScore;
  final List<String> dataSources;
  final DateTime createdAt;

  const TradeAutoScope({
    required this.id,
    required this.scanId,
    required this.trade,
    this.scopeSummary = '',
    this.scopeItems = const [],
    this.codeRequirements = const [],
    this.permitsRequired = false,
    this.permitTypes = const [],
    this.dependencies = const [],
    this.confidenceScore = 0,
    this.dataSources = const [],
    required this.createdAt,
  });

  factory TradeAutoScope.fromJson(Map<String, dynamic> json) {
    return TradeAutoScope(
      id: json['id'] as String,
      scanId: json['scan_id'] as String,
      trade: (json['trade'] as String?) ?? '',
      scopeSummary: (json['scope_summary'] as String?) ?? '',
      scopeItems: _parseList<ScopeItem>(json['scope_items'], ScopeItem.fromJson),
      codeRequirements: _parseList<CodeRequirement>(json['code_requirements'], CodeRequirement.fromJson),
      permitsRequired: json['permits_required'] == true,
      permitTypes: _parseStringList(json['permit_types']),
      dependencies: _parseList<CrossTradeDependency>(json['dependencies'], CrossTradeDependency.fromJson),
      confidenceScore: _parseIntSafe(json['confidence_score']),
      dataSources: _parseStringList(json['data_sources']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scan_id': scanId,
    'trade': trade,
    'scope_summary': scopeSummary,
    'scope_items': scopeItems.map((e) => e.toJson()).toList(),
    'code_requirements': codeRequirements.map((e) => e.toJson()).toList(),
    'permits_required': permitsRequired,
    'permit_types': permitTypes,
    'dependencies': dependencies.map((e) => e.toJson()).toList(),
    'confidence_score': confidenceScore,
    'data_sources': dataSources,
  };

  @override
  List<Object?> get props => [id, scanId, trade];

  // Computed
  List<ScopeItem> get measurements => scopeItems.where((i) => i.category == 'measurements').toList();
  List<ScopeItem> get materials => scopeItems.where((i) => i.category == 'materials').toList();
  List<ScopeItem> get codeItems => scopeItems.where((i) => i.category == 'code').toList();
  List<ScopeItem> get environmentalItems => scopeItems.where((i) => i.category == 'environmental').toList();
}

// ════════════════════════════════════════════════════════════════
// HELPERS (local to this file)
// ════════════════════════════════════════════════════════════════

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

int _parseIntSafe(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
  return [];
}

DependencyPriority _parseDependencyPriority(String? value) {
  switch (value) {
    case 'before': return DependencyPriority.before;
    case 'after': return DependencyPriority.after;
    case 'concurrent': return DependencyPriority.concurrent;
    default: return DependencyPriority.before;
  }
}

String _formatNumber(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}
