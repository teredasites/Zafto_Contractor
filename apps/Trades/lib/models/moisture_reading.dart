// ZAFTO Moisture Reading Model — Supabase Backend
// Maps to `moisture_readings` table. Daily tracked readings per affected area.

enum MaterialType {
  drywall,
  wood,
  concrete,
  carpet,
  pad,
  insulation,
  subfloor,
  hardwood,
  laminate,
  tileBacker,
  other;

  String get dbValue {
    switch (this) {
      case MaterialType.tileBacker:
        return 'tile_backer';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case MaterialType.drywall:
        return 'Drywall';
      case MaterialType.wood:
        return 'Wood';
      case MaterialType.concrete:
        return 'Concrete';
      case MaterialType.carpet:
        return 'Carpet';
      case MaterialType.pad:
        return 'Pad';
      case MaterialType.insulation:
        return 'Insulation';
      case MaterialType.subfloor:
        return 'Subfloor';
      case MaterialType.hardwood:
        return 'Hardwood';
      case MaterialType.laminate:
        return 'Laminate';
      case MaterialType.tileBacker:
        return 'Tile Backer';
      case MaterialType.other:
        return 'Other';
    }
  }

  // Default target dry value for this material type (percent)
  double get defaultTarget {
    switch (this) {
      case MaterialType.drywall:
        return 12.0;
      case MaterialType.wood:
      case MaterialType.hardwood:
      case MaterialType.subfloor:
        return 15.0;
      case MaterialType.concrete:
        return 17.0;
      case MaterialType.carpet:
      case MaterialType.pad:
        return 10.0;
      case MaterialType.insulation:
        return 8.0;
      case MaterialType.laminate:
        return 12.0;
      case MaterialType.tileBacker:
        return 12.0;
      case MaterialType.other:
        return 15.0;
    }
  }

  static MaterialType fromString(String? value) {
    if (value == null) return MaterialType.drywall;
    switch (value) {
      case 'tile_backer':
        return MaterialType.tileBacker;
      default:
        return MaterialType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => MaterialType.other,
        );
    }
  }
}

enum ReadingUnit {
  percent,
  relative,
  wme,
  grains;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ReadingUnit.percent:
        return '%';
      case ReadingUnit.relative:
        return 'REL';
      case ReadingUnit.wme:
        return 'WME';
      case ReadingUnit.grains:
        return 'GPP';
    }
  }

  static ReadingUnit fromString(String? value) {
    if (value == null) return ReadingUnit.percent;
    return ReadingUnit.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ReadingUnit.percent,
    );
  }
}

class MoistureReading {
  final String id;
  final String companyId;
  final String jobId;
  final String? claimId;
  final String areaName;
  final String? floorLevel;
  final MaterialType materialType;
  final double readingValue;
  final ReadingUnit readingUnit;
  final double? targetValue;
  final String? meterType;
  final String? meterModel;
  final double? ambientTempF;
  final double? ambientHumidity;
  final bool isDry;
  final String? recordedByUserId;
  final DateTime recordedAt;
  final DateTime createdAt;

  const MoistureReading({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.claimId,
    required this.areaName,
    this.floorLevel,
    this.materialType = MaterialType.drywall,
    required this.readingValue,
    this.readingUnit = ReadingUnit.percent,
    this.targetValue,
    this.meterType,
    this.meterModel,
    this.ambientTempF,
    this.ambientHumidity,
    this.isDry = false,
    this.recordedByUserId,
    required this.recordedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        if (claimId != null) 'claim_id': claimId,
        'area_name': areaName,
        if (floorLevel != null) 'floor_level': floorLevel,
        'material_type': materialType.dbValue,
        'reading_value': readingValue,
        'reading_unit': readingUnit.dbValue,
        if (targetValue != null) 'target_value': targetValue,
        if (meterType != null) 'meter_type': meterType,
        if (meterModel != null) 'meter_model': meterModel,
        if (ambientTempF != null) 'ambient_temp_f': ambientTempF,
        if (ambientHumidity != null) 'ambient_humidity': ambientHumidity,
        'is_dry': isDry,
        if (recordedByUserId != null) 'recorded_by_user_id': recordedByUserId,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  factory MoistureReading.fromJson(Map<String, dynamic> json) {
    return MoistureReading(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      claimId: json['claim_id'] as String?,
      areaName: json['area_name'] as String? ?? '',
      floorLevel: json['floor_level'] as String?,
      materialType: MaterialType.fromString(json['material_type'] as String?),
      readingValue: (json['reading_value'] as num?)?.toDouble() ?? 0,
      readingUnit: ReadingUnit.fromString(json['reading_unit'] as String?),
      targetValue: (json['target_value'] as num?)?.toDouble(),
      meterType: json['meter_type'] as String?,
      meterModel: json['meter_model'] as String?,
      ambientTempF: (json['ambient_temp_f'] as num?)?.toDouble(),
      ambientHumidity: (json['ambient_humidity'] as num?)?.toDouble(),
      isDry: json['is_dry'] as bool? ?? false,
      recordedByUserId: json['recorded_by_user_id'] as String?,
      recordedAt: _parseDate(json['recorded_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  // Computed: reading at or below target = dry
  bool get isAtTarget =>
      targetValue != null && readingValue <= targetValue!;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
