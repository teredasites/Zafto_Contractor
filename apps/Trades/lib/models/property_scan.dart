// ZAFTO Property Scan Model
// Created: Phase P — Sprint P7
//
// Immutable models for Recon property intelligence:
// PropertyScan, RoofMeasurement, RoofFacet, WallMeasurement,
// TradeBidData, PropertyLeadScore, ScanHistoryEntry

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum ScanStatus { pending, scanning, complete, partial, failed }

enum ConfidenceGrade { high, moderate, low }

enum RoofShape { gable, hip, flat, gambrel, mansard, mixed }

enum TradeType {
  roofing,
  siding,
  gutters,
  solar,
  painting,
  landscaping,
  fencing,
  concrete,
  hvac,
  electrical,
}

enum VerificationStatus { unverified, verified, adjusted }

enum ScanAction { created, updated, verified, adjusted, reScanned }

// ════════════════════════════════════════════════════════════════
// PROPERTY SCAN
// ════════════════════════════════════════════════════════════════

class PropertyScan extends Equatable {
  final String id;
  final String companyId;
  final String? jobId;
  final String address;
  final String? city;
  final String? state;
  final String? zip;
  final double? latitude;
  final double? longitude;
  final ScanStatus status;
  final List<String> scanSources;
  final int confidenceScore;
  final ConfidenceGrade confidenceGrade;
  final Map<String, dynamic> confidenceFactors;
  final String? imageryDate;
  final String? imagerySource;
  final int? imageryAgeMonths;
  final VerificationStatus verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;

  const PropertyScan({
    required this.id,
    required this.companyId,
    this.jobId,
    required this.address,
    this.city,
    this.state,
    this.zip,
    this.latitude,
    this.longitude,
    required this.status,
    this.scanSources = const [],
    this.confidenceScore = 0,
    this.confidenceGrade = ConfidenceGrade.low,
    this.confidenceFactors = const {},
    this.imageryDate,
    this.imagerySource,
    this.imageryAgeMonths,
    this.verificationStatus = VerificationStatus.unverified,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
  });

  factory PropertyScan.fromJson(Map<String, dynamic> json) {
    return PropertyScan(
      id: json['id'] as String,
      companyId: (json['company_id'] ?? json['companyId'] ?? '') as String,
      jobId: json['job_id'] as String? ?? json['jobId'] as String?,
      address: (json['address'] ?? '') as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      status: _parseEnum(
        json['status'] as String? ?? 'pending',
        ScanStatus.values,
        ScanStatus.pending,
      ),
      scanSources: _parseStringList(json['scan_sources'] ?? json['scanSources']),
      confidenceScore: _parseInt(json['confidence_score'] ?? json['confidenceScore']),
      confidenceGrade: _parseEnum(
        json['confidence_grade'] as String? ?? json['confidenceGrade'] as String? ?? 'low',
        ConfidenceGrade.values,
        ConfidenceGrade.low,
      ),
      confidenceFactors: (json['confidence_factors'] ?? json['confidenceFactors'] ?? {}) as Map<String, dynamic>,
      imageryDate: json['imagery_date'] as String? ?? json['imageryDate'] as String?,
      imagerySource: json['imagery_source'] as String? ?? json['imagerySource'] as String?,
      imageryAgeMonths: json['imagery_age_months'] != null
          ? _parseInt(json['imagery_age_months'])
          : json['imageryAgeMonths'] != null
              ? _parseInt(json['imageryAgeMonths'])
              : null,
      verificationStatus: _parseEnum(
        json['verification_status'] as String? ?? 'unverified',
        VerificationStatus.values,
        VerificationStatus.unverified,
      ),
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: _parseDate(json['verified_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_id': companyId,
        'job_id': jobId,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'scan_sources': scanSources,
        'confidence_score': confidenceScore,
        'confidence_grade': confidenceGrade.name,
        'confidence_factors': confidenceFactors,
        'imagery_date': imageryDate,
        'imagery_source': imagerySource,
        'imagery_age_months': imageryAgeMonths,
        'verification_status': verificationStatus.name,
        'verified_by': verifiedBy,
        'verified_at': verifiedAt?.toUtc().toIso8601String(),
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  String get fullAddress =>
      [address, city, state, zip].where((s) => s != null && s.isNotEmpty).join(', ');

  bool get isComplete => status == ScanStatus.complete;
  bool get isVerified => verificationStatus != VerificationStatus.unverified;
  bool get isImageryOld => imageryAgeMonths != null && imageryAgeMonths! > 18;

  PropertyScan copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? address,
    String? city,
    String? state,
    String? zip,
    double? latitude,
    double? longitude,
    ScanStatus? status,
    List<String>? scanSources,
    int? confidenceScore,
    ConfidenceGrade? confidenceGrade,
    Map<String, dynamic>? confidenceFactors,
    String? imageryDate,
    String? imagerySource,
    int? imageryAgeMonths,
    VerificationStatus? verificationStatus,
    String? verifiedBy,
    DateTime? verifiedAt,
    DateTime? createdAt,
  }) {
    return PropertyScan(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      scanSources: scanSources ?? this.scanSources,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      confidenceGrade: confidenceGrade ?? this.confidenceGrade,
      confidenceFactors: confidenceFactors ?? this.confidenceFactors,
      imageryDate: imageryDate ?? this.imageryDate,
      imagerySource: imagerySource ?? this.imagerySource,
      imageryAgeMonths: imageryAgeMonths ?? this.imageryAgeMonths,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, status, confidenceScore, verificationStatus];
}

// ════════════════════════════════════════════════════════════════
// ROOF MEASUREMENT
// ════════════════════════════════════════════════════════════════

class RoofMeasurement extends Equatable {
  final String id;
  final String scanId;
  final double totalAreaSqft;
  final double totalAreaSquares;
  final String? pitchPrimary;
  final double pitchDegrees;
  final double ridgeLengthFt;
  final double hipLengthFt;
  final double valleyLengthFt;
  final double eaveLengthFt;
  final double rakeLengthFt;
  final int facetCount;
  final int complexityScore;
  final RoofShape? predominantShape;
  final String? predominantMaterial;
  final int penetrationCount;

  const RoofMeasurement({
    required this.id,
    required this.scanId,
    this.totalAreaSqft = 0,
    this.totalAreaSquares = 0,
    this.pitchPrimary,
    this.pitchDegrees = 0,
    this.ridgeLengthFt = 0,
    this.hipLengthFt = 0,
    this.valleyLengthFt = 0,
    this.eaveLengthFt = 0,
    this.rakeLengthFt = 0,
    this.facetCount = 0,
    this.complexityScore = 0,
    this.predominantShape,
    this.predominantMaterial,
    this.penetrationCount = 0,
  });

  factory RoofMeasurement.fromJson(Map<String, dynamic> json) {
    return RoofMeasurement(
      id: json['id'] as String,
      scanId: (json['scan_id'] ?? json['scanId'] ?? '') as String,
      totalAreaSqft: _parseDouble(json['total_area_sqft'] ?? json['totalAreaSqft']) ?? 0,
      totalAreaSquares: _parseDouble(json['total_area_squares'] ?? json['totalAreaSquares']) ?? 0,
      pitchPrimary: json['pitch_primary'] as String? ?? json['pitchPrimary'] as String?,
      pitchDegrees: _parseDouble(json['pitch_degrees'] ?? json['pitchDegrees']) ?? 0,
      ridgeLengthFt: _parseDouble(json['ridge_length_ft'] ?? json['ridgeLengthFt']) ?? 0,
      hipLengthFt: _parseDouble(json['hip_length_ft'] ?? json['hipLengthFt']) ?? 0,
      valleyLengthFt: _parseDouble(json['valley_length_ft'] ?? json['valleyLengthFt']) ?? 0,
      eaveLengthFt: _parseDouble(json['eave_length_ft'] ?? json['eaveLengthFt']) ?? 0,
      rakeLengthFt: _parseDouble(json['rake_length_ft'] ?? json['rakeLengthFt']) ?? 0,
      facetCount: _parseInt(json['facet_count'] ?? json['facetCount']),
      complexityScore: _parseInt(json['complexity_score'] ?? json['complexityScore']),
      predominantShape: json['predominant_shape'] != null
          ? _parseEnumNullable(json['predominant_shape'] as String, RoofShape.values)
          : null,
      predominantMaterial: json['predominant_material'] as String?,
      penetrationCount: _parseInt(json['penetration_count'] ?? json['penetrationCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scan_id': scanId,
        'total_area_sqft': totalAreaSqft,
        'total_area_squares': totalAreaSquares,
        'pitch_primary': pitchPrimary,
        'pitch_degrees': pitchDegrees,
        'ridge_length_ft': ridgeLengthFt,
        'hip_length_ft': hipLengthFt,
        'valley_length_ft': valleyLengthFt,
        'eave_length_ft': eaveLengthFt,
        'rake_length_ft': rakeLengthFt,
        'facet_count': facetCount,
        'complexity_score': complexityScore,
        'predominant_shape': predominantShape?.name,
        'predominant_material': predominantMaterial,
        'penetration_count': penetrationCount,
      };

  double get totalEdgeLengthFt =>
      ridgeLengthFt + hipLengthFt + valleyLengthFt + eaveLengthFt + rakeLengthFt;

  @override
  List<Object?> get props => [id, scanId, totalAreaSqft, facetCount];
}

// ════════════════════════════════════════════════════════════════
// ROOF FACET
// ════════════════════════════════════════════════════════════════

class RoofFacet extends Equatable {
  final String id;
  final int facetNumber;
  final double areaSqft;
  final double pitchDegrees;
  final double azimuthDegrees;
  final double? annualSunHours;
  final double? shadeFactor;

  const RoofFacet({
    required this.id,
    required this.facetNumber,
    this.areaSqft = 0,
    this.pitchDegrees = 0,
    this.azimuthDegrees = 0,
    this.annualSunHours,
    this.shadeFactor,
  });

  factory RoofFacet.fromJson(Map<String, dynamic> json) {
    return RoofFacet(
      id: json['id'] as String,
      facetNumber: _parseInt(json['facet_number'] ?? json['facetNumber']),
      areaSqft: _parseDouble(json['area_sqft'] ?? json['areaSqft']) ?? 0,
      pitchDegrees: _parseDouble(json['pitch_degrees'] ?? json['pitchDegrees']) ?? 0,
      azimuthDegrees: _parseDouble(json['azimuth_degrees'] ?? json['azimuthDegrees']) ?? 0,
      annualSunHours: _parseDouble(json['annual_sun_hours'] ?? json['annualSunHours']),
      shadeFactor: _parseDouble(json['shade_factor'] ?? json['shadeFactor']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'facet_number': facetNumber,
        'area_sqft': areaSqft,
        'pitch_degrees': pitchDegrees,
        'azimuth_degrees': azimuthDegrees,
        'annual_sun_hours': annualSunHours,
        'shade_factor': shadeFactor,
      };

  String get compassDirection {
    if (azimuthDegrees >= 337.5 || azimuthDegrees < 22.5) return 'N';
    if (azimuthDegrees < 67.5) return 'NE';
    if (azimuthDegrees < 112.5) return 'E';
    if (azimuthDegrees < 157.5) return 'SE';
    if (azimuthDegrees < 202.5) return 'S';
    if (azimuthDegrees < 247.5) return 'SW';
    if (azimuthDegrees < 292.5) return 'W';
    return 'NW';
  }

  @override
  List<Object?> get props => [id, facetNumber, areaSqft];
}

// ════════════════════════════════════════════════════════════════
// WALL MEASUREMENT
// ════════════════════════════════════════════════════════════════

class WallFace {
  final String direction;
  final double widthFt;
  final double heightFt;
  final double areaSqft;
  final int windowCountEst;
  final int doorCountEst;
  final double netAreaSqft;

  const WallFace({
    required this.direction,
    this.widthFt = 0,
    this.heightFt = 0,
    this.areaSqft = 0,
    this.windowCountEst = 0,
    this.doorCountEst = 0,
    this.netAreaSqft = 0,
  });

  factory WallFace.fromJson(Map<String, dynamic> json) {
    return WallFace(
      direction: (json['direction'] ?? '') as String,
      widthFt: _parseDouble(json['width_ft']) ?? 0,
      heightFt: _parseDouble(json['height_ft']) ?? 0,
      areaSqft: _parseDouble(json['area_sqft']) ?? 0,
      windowCountEst: _parseInt(json['window_count_est']),
      doorCountEst: _parseInt(json['door_count_est']),
      netAreaSqft: _parseDouble(json['net_area_sqft']) ?? 0,
    );
  }
}

class WallMeasurement extends Equatable {
  final String id;
  final String scanId;
  final String? structureId;
  final double totalWallAreaSqft;
  final double totalSidingAreaSqft;
  final List<WallFace> perFace;
  final int stories;
  final double avgWallHeightFt;
  final double windowAreaEstSqft;
  final double doorAreaEstSqft;
  final double trimLinearFt;
  final double fasciaLinearFt;
  final double soffitSqft;
  final String dataSource;
  final int confidence;
  final bool isEstimated;

  const WallMeasurement({
    required this.id,
    required this.scanId,
    this.structureId,
    this.totalWallAreaSqft = 0,
    this.totalSidingAreaSqft = 0,
    this.perFace = const [],
    this.stories = 1,
    this.avgWallHeightFt = 9,
    this.windowAreaEstSqft = 0,
    this.doorAreaEstSqft = 0,
    this.trimLinearFt = 0,
    this.fasciaLinearFt = 0,
    this.soffitSqft = 0,
    this.dataSource = 'derived',
    this.confidence = 50,
    this.isEstimated = true,
  });

  factory WallMeasurement.fromJson(Map<String, dynamic> json) {
    final perFaceRaw = json['per_face'] ?? json['perFace'];
    final faces = <WallFace>[];
    if (perFaceRaw is List) {
      for (final f in perFaceRaw) {
        if (f is Map<String, dynamic>) {
          faces.add(WallFace.fromJson(f));
        }
      }
    }

    return WallMeasurement(
      id: json['id'] as String,
      scanId: (json['scan_id'] ?? json['scanId'] ?? '') as String,
      structureId: json['structure_id'] as String? ?? json['structureId'] as String?,
      totalWallAreaSqft: _parseDouble(json['total_wall_area_sqft']) ?? 0,
      totalSidingAreaSqft: _parseDouble(json['total_siding_area_sqft']) ?? 0,
      perFace: faces,
      stories: _parseInt(json['stories']),
      avgWallHeightFt: _parseDouble(json['avg_wall_height_ft']) ?? 9,
      windowAreaEstSqft: _parseDouble(json['window_area_est_sqft']) ?? 0,
      doorAreaEstSqft: _parseDouble(json['door_area_est_sqft']) ?? 0,
      trimLinearFt: _parseDouble(json['trim_linear_ft']) ?? 0,
      fasciaLinearFt: _parseDouble(json['fascia_linear_ft']) ?? 0,
      soffitSqft: _parseDouble(json['soffit_sqft']) ?? 0,
      dataSource: (json['data_source'] ?? 'derived') as String,
      confidence: _parseInt(json['confidence']),
      isEstimated: json['is_estimated'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scan_id': scanId,
        'structure_id': structureId,
        'total_wall_area_sqft': totalWallAreaSqft,
        'total_siding_area_sqft': totalSidingAreaSqft,
        'stories': stories,
        'avg_wall_height_ft': avgWallHeightFt,
        'window_area_est_sqft': windowAreaEstSqft,
        'door_area_est_sqft': doorAreaEstSqft,
        'trim_linear_ft': trimLinearFt,
        'fascia_linear_ft': fasciaLinearFt,
        'soffit_sqft': soffitSqft,
        'data_source': dataSource,
        'confidence': confidence,
        'is_estimated': isEstimated,
      };

  @override
  List<Object?> get props => [id, scanId, totalWallAreaSqft];
}

// ════════════════════════════════════════════════════════════════
// MATERIAL ITEM (embedded in TradeBidData)
// ════════════════════════════════════════════════════════════════

class MaterialItem {
  final String item;
  final double quantity;
  final String unit;
  final double wastePct;
  final double totalWithWaste;

  const MaterialItem({
    required this.item,
    this.quantity = 0,
    this.unit = 'ea',
    this.wastePct = 0,
    this.totalWithWaste = 0,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      item: (json['item'] ?? '') as String,
      quantity: _parseDouble(json['quantity']) ?? 0,
      unit: (json['unit'] ?? 'ea') as String,
      wastePct: _parseDouble(json['waste_pct']) ?? 0,
      totalWithWaste: _parseDouble(json['total_with_waste']) ?? 0,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TRADE BID DATA
// ════════════════════════════════════════════════════════════════

class TradeBidData extends Equatable {
  final String id;
  final String scanId;
  final TradeType trade;
  final Map<String, dynamic> measurements;
  final List<MaterialItem> materialList;
  final double wasteFactorPct;
  final int complexityScore;
  final int recommendedCrewSize;
  final double? estimatedLaborHours;
  final List<String> dataSources;

  const TradeBidData({
    required this.id,
    required this.scanId,
    required this.trade,
    this.measurements = const {},
    this.materialList = const [],
    this.wasteFactorPct = 0,
    this.complexityScore = 0,
    this.recommendedCrewSize = 2,
    this.estimatedLaborHours,
    this.dataSources = const [],
  });

  factory TradeBidData.fromJson(Map<String, dynamic> json) {
    final materialsRaw = json['material_list'] ?? json['materialList'];
    final materials = <MaterialItem>[];
    if (materialsRaw is List) {
      for (final m in materialsRaw) {
        if (m is Map<String, dynamic>) {
          materials.add(MaterialItem.fromJson(m));
        }
      }
    }

    return TradeBidData(
      id: json['id'] as String,
      scanId: (json['scan_id'] ?? json['scanId'] ?? '') as String,
      trade: _parseEnum(
        json['trade'] as String? ?? 'roofing',
        TradeType.values,
        TradeType.roofing,
      ),
      measurements: (json['measurements'] ?? {}) as Map<String, dynamic>,
      materialList: materials,
      wasteFactorPct: _parseDouble(json['waste_factor_pct']) ?? 0,
      complexityScore: _parseInt(json['complexity_score']),
      recommendedCrewSize: _parseInt(json['recommended_crew_size']),
      estimatedLaborHours: _parseDouble(json['estimated_labor_hours']),
      dataSources: _parseStringList(json['data_sources'] ?? json['dataSources']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scan_id': scanId,
        'trade': trade.name,
        'measurements': measurements,
        'waste_factor_pct': wasteFactorPct,
        'complexity_score': complexityScore,
        'recommended_crew_size': recommendedCrewSize,
        'estimated_labor_hours': estimatedLaborHours,
        'data_sources': dataSources,
      };

  @override
  List<Object?> get props => [id, scanId, trade];
}

// ════════════════════════════════════════════════════════════════
// PROPERTY LEAD SCORE
// ════════════════════════════════════════════════════════════════

class PropertyLeadScore extends Equatable {
  final String id;
  final String propertyScanId;
  final String companyId;
  final String? areaScanId;
  final int overallScore;
  final String grade; // hot, warm, cold
  final int roofAgeScore;
  final int propertyValueScore;
  final int ownerTenureScore;
  final int conditionScore;
  final int permitScore;
  final double stormDamageProbability;
  final Map<String, dynamic> scoringFactors;
  final DateTime createdAt;

  const PropertyLeadScore({
    required this.id,
    required this.propertyScanId,
    required this.companyId,
    this.areaScanId,
    this.overallScore = 0,
    this.grade = 'cold',
    this.roofAgeScore = 0,
    this.propertyValueScore = 0,
    this.ownerTenureScore = 0,
    this.conditionScore = 0,
    this.permitScore = 0,
    this.stormDamageProbability = 0,
    this.scoringFactors = const {},
    required this.createdAt,
  });

  factory PropertyLeadScore.fromJson(Map<String, dynamic> json) {
    return PropertyLeadScore(
      id: json['id'] as String,
      propertyScanId: (json['property_scan_id'] ?? '') as String,
      companyId: (json['company_id'] ?? '') as String,
      areaScanId: json['area_scan_id'] as String?,
      overallScore: _parseInt(json['overall_score']),
      grade: (json['grade'] ?? 'cold') as String,
      roofAgeScore: _parseInt(json['roof_age_score']),
      propertyValueScore: _parseInt(json['property_value_score']),
      ownerTenureScore: _parseInt(json['owner_tenure_score']),
      conditionScore: _parseInt(json['condition_score']),
      permitScore: _parseInt(json['permit_score']),
      stormDamageProbability: _parseDouble(json['storm_damage_probability']) ?? 0,
      scoringFactors: (json['scoring_factors'] ?? {}) as Map<String, dynamic>,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  bool get isHot => grade == 'hot';
  bool get isWarm => grade == 'warm';
  bool get isCold => grade == 'cold';

  @override
  List<Object?> get props => [id, propertyScanId, overallScore, grade];
}

// ════════════════════════════════════════════════════════════════
// SCAN HISTORY ENTRY
// ════════════════════════════════════════════════════════════════

class ScanHistoryEntry extends Equatable {
  final String id;
  final String scanId;
  final ScanAction action;
  final String? fieldChanged;
  final String? oldValue;
  final String? newValue;
  final String? performedBy;
  final DateTime performedAt;
  final String? device;
  final String? notes;

  const ScanHistoryEntry({
    required this.id,
    required this.scanId,
    required this.action,
    this.fieldChanged,
    this.oldValue,
    this.newValue,
    this.performedBy,
    required this.performedAt,
    this.device,
    this.notes,
  });

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ScanHistoryEntry(
      id: json['id'] as String,
      scanId: (json['scan_id'] ?? '') as String,
      action: _parseEnum(
        (json['action'] as String? ?? 'created').replaceAll('re_scanned', 'reScanned'),
        ScanAction.values,
        ScanAction.created,
      ),
      fieldChanged: json['field_changed'] as String?,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      performedBy: json['performed_by'] as String?,
      performedAt: _parseDate(json['performed_at']) ?? DateTime.now(),
      device: json['device'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, scanId, action, performedAt];
}

// ════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════════

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int _parseInt(dynamic value) {
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

T _parseEnum<T extends Enum>(String value, List<T> values, T fallback) {
  final lower = value.toLowerCase();
  for (final v in values) {
    if (v.name.toLowerCase() == lower) return v;
  }
  return fallback;
}

T? _parseEnumNullable<T extends Enum>(String value, List<T> values) {
  final lower = value.toLowerCase();
  for (final v in values) {
    if (v.name.toLowerCase() == lower) return v;
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
