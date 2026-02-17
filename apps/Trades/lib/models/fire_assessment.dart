// ZAFTO Fire Damage Assessment Model — Supabase Backend
// Maps to `fire_assessments` table. Sprint REST1.
// Fire damage zones, soot classification, odor treatment, board-up, air quality.

enum DamageSeverity {
  minor,
  moderate,
  major,
  totalLoss;

  String get dbValue {
    switch (this) {
      case DamageSeverity.totalLoss:
        return 'total_loss';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case DamageSeverity.minor:
        return 'Minor';
      case DamageSeverity.moderate:
        return 'Moderate';
      case DamageSeverity.major:
        return 'Major';
      case DamageSeverity.totalLoss:
        return 'Total Loss';
    }
  }

  static DamageSeverity fromString(String? value) {
    if (value == null) return DamageSeverity.moderate;
    switch (value) {
      case 'total_loss':
        return DamageSeverity.totalLoss;
      default:
        return DamageSeverity.values.firstWhere(
          (e) => e.name == value,
          orElse: () => DamageSeverity.moderate,
        );
    }
  }
}

enum DamageZoneType {
  directFlame,
  smoke,
  heat,
  waterSuppression;

  String get dbValue {
    switch (this) {
      case DamageZoneType.directFlame:
        return 'direct_flame';
      case DamageZoneType.waterSuppression:
        return 'water_suppression';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case DamageZoneType.directFlame:
        return 'Direct Flame';
      case DamageZoneType.smoke:
        return 'Smoke';
      case DamageZoneType.heat:
        return 'Heat';
      case DamageZoneType.waterSuppression:
        return 'Water (Suppression)';
    }
  }

  static DamageZoneType fromString(String? value) {
    if (value == null) return DamageZoneType.smoke;
    switch (value) {
      case 'direct_flame':
        return DamageZoneType.directFlame;
      case 'water_suppression':
        return DamageZoneType.waterSuppression;
      default:
        return DamageZoneType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => DamageZoneType.smoke,
        );
    }
  }
}

enum SootType {
  wetSmoke,
  drySmoke,
  protein,
  fuelOil,
  mixed;

  String get dbValue {
    switch (this) {
      case SootType.wetSmoke:
        return 'wet_smoke';
      case SootType.drySmoke:
        return 'dry_smoke';
      case SootType.fuelOil:
        return 'fuel_oil';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case SootType.wetSmoke:
        return 'Wet Smoke';
      case SootType.drySmoke:
        return 'Dry Smoke';
      case SootType.protein:
        return 'Protein';
      case SootType.fuelOil:
        return 'Fuel Oil';
      case SootType.mixed:
        return 'Mixed';
    }
  }

  String get description {
    switch (this) {
      case SootType.wetSmoke:
        return 'Low heat, smoldering — thick, sticky, pungent residue. Hard to clean.';
      case SootType.drySmoke:
        return 'High heat, fast burn — dry, powdery, non-smeary. Easier to clean.';
      case SootType.protein:
        return 'Cooking fire — nearly invisible residue, extreme odor, discolors paints.';
      case SootType.fuelOil:
        return 'Petroleum product — thick, black, sticky. Requires specialized solvents.';
      case SootType.mixed:
        return 'Multiple soot types present — requires layered cleaning approach.';
    }
  }

  String get cleaningMethod {
    switch (this) {
      case SootType.wetSmoke:
        return 'Degreaser + multiple passes, avoid spreading. May need encapsulant.';
      case SootType.drySmoke:
        return 'Dry sponge first, then wet wipe. Do NOT wet first (smears).';
      case SootType.protein:
        return 'Enzyme-based cleaner. Standard cleaners spread residue. May need repaint.';
      case SootType.fuelOil:
        return 'Solvent-based cleaner. Heavy PPE. Multiple passes. Seal afterward.';
      case SootType.mixed:
        return 'Test each surface. Start with least aggressive method, escalate as needed.';
    }
  }

  static SootType fromString(String? value) {
    if (value == null) return SootType.drySmoke;
    switch (value) {
      case 'wet_smoke':
        return SootType.wetSmoke;
      case 'dry_smoke':
        return SootType.drySmoke;
      case 'fuel_oil':
        return SootType.fuelOil;
      default:
        return SootType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => SootType.mixed,
        );
    }
  }
}

enum OdorTreatmentMethod {
  thermalFog,
  ozone,
  hydroxyl,
  airScrub,
  sealer;

  String get dbValue {
    switch (this) {
      case OdorTreatmentMethod.thermalFog:
        return 'thermal_fog';
      case OdorTreatmentMethod.airScrub:
        return 'air_scrub';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case OdorTreatmentMethod.thermalFog:
        return 'Thermal Fogging';
      case OdorTreatmentMethod.ozone:
        return 'Ozone Treatment';
      case OdorTreatmentMethod.hydroxyl:
        return 'Hydroxyl Generator';
      case OdorTreatmentMethod.airScrub:
        return 'Air Scrubber';
      case OdorTreatmentMethod.sealer:
        return 'Odor Sealer';
    }
  }

  String get safetyNote {
    switch (this) {
      case OdorTreatmentMethod.thermalFog:
        return 'Vacancy recommended. Residue may stain light surfaces.';
      case OdorTreatmentMethod.ozone:
        return 'VACANCY REQUIRED. Harmful to humans, pets, plants. 24hr minimum.';
      case OdorTreatmentMethod.hydroxyl:
        return 'Safe for occupied spaces. Slower than ozone but no vacancy needed.';
      case OdorTreatmentMethod.airScrub:
        return 'HEPA + carbon filter. Safe for occupied spaces.';
      case OdorTreatmentMethod.sealer:
        return 'Apply after cleaning. BIN shellac or Kilz Original recommended.';
    }
  }

  static OdorTreatmentMethod fromString(String? value) {
    if (value == null) return OdorTreatmentMethod.thermalFog;
    switch (value) {
      case 'thermal_fog':
        return OdorTreatmentMethod.thermalFog;
      case 'air_scrub':
        return OdorTreatmentMethod.airScrub;
      default:
        return OdorTreatmentMethod.values.firstWhere(
          (e) => e.name == value,
          orElse: () => OdorTreatmentMethod.thermalFog,
        );
    }
  }
}

enum AssessmentStatus {
  inProgress,
  pendingReview,
  approved,
  submittedToCarrier;

  String get dbValue {
    switch (this) {
      case AssessmentStatus.inProgress:
        return 'in_progress';
      case AssessmentStatus.pendingReview:
        return 'pending_review';
      case AssessmentStatus.submittedToCarrier:
        return 'submitted_to_carrier';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case AssessmentStatus.inProgress:
        return 'In Progress';
      case AssessmentStatus.pendingReview:
        return 'Pending Review';
      case AssessmentStatus.approved:
        return 'Approved';
      case AssessmentStatus.submittedToCarrier:
        return 'Submitted to Carrier';
    }
  }

  static AssessmentStatus fromString(String? value) {
    if (value == null) return AssessmentStatus.inProgress;
    switch (value) {
      case 'in_progress':
        return AssessmentStatus.inProgress;
      case 'pending_review':
        return AssessmentStatus.pendingReview;
      case 'submitted_to_carrier':
        return AssessmentStatus.submittedToCarrier;
      default:
        return AssessmentStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => AssessmentStatus.inProgress,
        );
    }
  }
}

// =============================================================================
// SUB-MODELS (JSONB nested data)
// =============================================================================

class DamageZone {
  final String room;
  final DamageZoneType zoneType;
  final String severity; // light, moderate, heavy
  final SootType? sootType;
  final String? notes;
  final List<String> photos;

  const DamageZone({
    required this.room,
    required this.zoneType,
    this.severity = 'moderate',
    this.sootType,
    this.notes,
    this.photos = const [],
  });

  Map<String, dynamic> toJson() => {
        'room': room,
        'zone_type': zoneType.dbValue,
        'severity': severity,
        if (sootType != null) 'soot_type': sootType!.dbValue,
        if (notes != null) 'notes': notes,
        'photos': photos,
      };

  factory DamageZone.fromJson(Map<String, dynamic> json) => DamageZone(
        room: json['room'] as String? ?? '',
        zoneType: DamageZoneType.fromString(json['zone_type'] as String?),
        severity: json['severity'] as String? ?? 'moderate',
        sootType: json['soot_type'] != null
            ? SootType.fromString(json['soot_type'] as String?)
            : null,
        notes: json['notes'] as String?,
        photos: (json['photos'] as List?)?.cast<String>() ?? [],
      );
}

class SootAssessment {
  final String room;
  final SootType sootType;
  final List<String> surfaceTypes;
  final String cleaningMethod;
  final String? notes;

  const SootAssessment({
    required this.room,
    required this.sootType,
    this.surfaceTypes = const [],
    this.cleaningMethod = '',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'room': room,
        'soot_type': sootType.dbValue,
        'surface_types': surfaceTypes,
        'cleaning_method': cleaningMethod,
        if (notes != null) 'notes': notes,
      };

  factory SootAssessment.fromJson(Map<String, dynamic> json) => SootAssessment(
        room: json['room'] as String? ?? '',
        sootType: SootType.fromString(json['soot_type'] as String?),
        surfaceTypes: (json['surface_types'] as List?)?.cast<String>() ?? [],
        cleaningMethod: json['cleaning_method'] as String? ?? '',
        notes: json['notes'] as String?,
      );
}

class OdorTreatment {
  final OdorTreatmentMethod method;
  final String room;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? equipmentId;
  final double? preReading;
  final double? postReading;
  final String? notes;

  const OdorTreatment({
    required this.method,
    required this.room,
    this.startTime,
    this.endTime,
    this.equipmentId,
    this.preReading,
    this.postReading,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'method': method.dbValue,
        'room': room,
        if (startTime != null)
          'start_time': startTime!.toUtc().toIso8601String(),
        if (endTime != null) 'end_time': endTime!.toUtc().toIso8601String(),
        if (equipmentId != null) 'equipment_id': equipmentId,
        if (preReading != null) 'pre_reading': preReading,
        if (postReading != null) 'post_reading': postReading,
        if (notes != null) 'notes': notes,
      };

  factory OdorTreatment.fromJson(Map<String, dynamic> json) => OdorTreatment(
        method:
            OdorTreatmentMethod.fromString(json['method'] as String?),
        room: json['room'] as String? ?? '',
        startTime: _parseDate(json['start_time']),
        endTime: _parseDate(json['end_time']),
        equipmentId: json['equipment_id'] as String?,
        preReading: (json['pre_reading'] as num?)?.toDouble(),
        postReading: (json['post_reading'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
      );

  bool get isComplete => endTime != null;
  Duration? get duration =>
      startTime != null && endTime != null ? endTime!.difference(startTime!) : null;
}

class BoardUpEntry {
  final String openingType; // window, door, roof, wall
  final String location;
  final String? material;
  final String? dimensions;
  final String? photoBefore;
  final String? photoAfter;
  final String? securedBy;
  final DateTime? securedAt;

  const BoardUpEntry({
    required this.openingType,
    required this.location,
    this.material,
    this.dimensions,
    this.photoBefore,
    this.photoAfter,
    this.securedBy,
    this.securedAt,
  });

  Map<String, dynamic> toJson() => {
        'opening_type': openingType,
        'location': location,
        if (material != null) 'material': material,
        if (dimensions != null) 'dimensions': dimensions,
        if (photoBefore != null) 'photo_before': photoBefore,
        if (photoAfter != null) 'photo_after': photoAfter,
        if (securedBy != null) 'secured_by': securedBy,
        if (securedAt != null)
          'secured_at': securedAt!.toUtc().toIso8601String(),
      };

  factory BoardUpEntry.fromJson(Map<String, dynamic> json) => BoardUpEntry(
        openingType: json['opening_type'] as String? ?? 'window',
        location: json['location'] as String? ?? '',
        material: json['material'] as String?,
        dimensions: json['dimensions'] as String?,
        photoBefore: json['photo_before'] as String?,
        photoAfter: json['photo_after'] as String?,
        securedBy: json['secured_by'] as String?,
        securedAt: _parseDate(json['secured_at']),
      );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

// =============================================================================
// MAIN MODEL
// =============================================================================

class FireAssessment {
  final String id;
  final String companyId;
  final String jobId;
  final String? insuranceClaimId;
  final String? createdByUserId;

  // Fire origin
  final String? originRoom;
  final String? originDescription;
  final String? fireDepartmentReportNumber;
  final String? fireDepartmentName;
  final DateTime? dateOfLoss;

  // Severity
  final DamageSeverity damageSeverity;

  // Structural
  final bool structuralCompromise;
  final bool roofDamage;
  final bool foundationDamage;
  final bool loadBearingAffected;
  final String? structuralNotes;

  // JSONB arrays
  final List<DamageZone> damageZones;
  final List<SootAssessment> sootAssessments;
  final List<OdorTreatment> odorTreatments;
  final List<BoardUpEntry> boardUpEntries;
  final List<Map<String, dynamic>> airQualityReadings;

  // Water from suppression
  final bool waterDamageFromSuppression;
  final String? waterDamageAssessmentId;

  // Photos
  final List<Map<String, dynamic>> photos;

  // Status
  final AssessmentStatus assessmentStatus;
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const FireAssessment({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.insuranceClaimId,
    this.createdByUserId,
    this.originRoom,
    this.originDescription,
    this.fireDepartmentReportNumber,
    this.fireDepartmentName,
    this.dateOfLoss,
    this.damageSeverity = DamageSeverity.moderate,
    this.structuralCompromise = false,
    this.roofDamage = false,
    this.foundationDamage = false,
    this.loadBearingAffected = false,
    this.structuralNotes,
    this.damageZones = const [],
    this.sootAssessments = const [],
    this.odorTreatments = const [],
    this.boardUpEntries = const [],
    this.airQualityReadings = const [],
    this.waterDamageFromSuppression = false,
    this.waterDamageAssessmentId,
    this.photos = const [],
    this.assessmentStatus = AssessmentStatus.inProgress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        if (insuranceClaimId != null) 'insurance_claim_id': insuranceClaimId,
        if (createdByUserId != null) 'created_by_user_id': createdByUserId,
        if (originRoom != null) 'origin_room': originRoom,
        if (originDescription != null)
          'origin_description': originDescription,
        if (fireDepartmentReportNumber != null)
          'fire_department_report_number': fireDepartmentReportNumber,
        if (fireDepartmentName != null)
          'fire_department_name': fireDepartmentName,
        if (dateOfLoss != null)
          'date_of_loss': dateOfLoss!.toUtc().toIso8601String(),
        'damage_severity': damageSeverity.dbValue,
        'structural_compromise': structuralCompromise,
        'roof_damage': roofDamage,
        'foundation_damage': foundationDamage,
        'load_bearing_affected': loadBearingAffected,
        if (structuralNotes != null) 'structural_notes': structuralNotes,
        'damage_zones': damageZones.map((z) => z.toJson()).toList(),
        'soot_assessments': sootAssessments.map((s) => s.toJson()).toList(),
        'odor_treatments': odorTreatments.map((o) => o.toJson()).toList(),
        'board_up_entries': boardUpEntries.map((b) => b.toJson()).toList(),
        'air_quality_readings': airQualityReadings,
        'water_damage_from_suppression': waterDamageFromSuppression,
        if (waterDamageAssessmentId != null)
          'water_damage_assessment_id': waterDamageAssessmentId,
        'photos': photos,
        'assessment_status': assessmentStatus.dbValue,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        if (originRoom != null) 'origin_room': originRoom,
        if (originDescription != null)
          'origin_description': originDescription,
        if (fireDepartmentReportNumber != null)
          'fire_department_report_number': fireDepartmentReportNumber,
        if (fireDepartmentName != null)
          'fire_department_name': fireDepartmentName,
        if (dateOfLoss != null)
          'date_of_loss': dateOfLoss!.toUtc().toIso8601String(),
        'damage_severity': damageSeverity.dbValue,
        'structural_compromise': structuralCompromise,
        'roof_damage': roofDamage,
        'foundation_damage': foundationDamage,
        'load_bearing_affected': loadBearingAffected,
        if (structuralNotes != null) 'structural_notes': structuralNotes,
        'damage_zones': damageZones.map((z) => z.toJson()).toList(),
        'soot_assessments': sootAssessments.map((s) => s.toJson()).toList(),
        'odor_treatments': odorTreatments.map((o) => o.toJson()).toList(),
        'board_up_entries': boardUpEntries.map((b) => b.toJson()).toList(),
        'air_quality_readings': airQualityReadings,
        'water_damage_from_suppression': waterDamageFromSuppression,
        'photos': photos,
        'assessment_status': assessmentStatus.dbValue,
        if (notes != null) 'notes': notes,
      };

  factory FireAssessment.fromJson(Map<String, dynamic> json) {
    return FireAssessment(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      insuranceClaimId: json['insurance_claim_id'] as String?,
      createdByUserId: json['created_by_user_id'] as String?,
      originRoom: json['origin_room'] as String?,
      originDescription: json['origin_description'] as String?,
      fireDepartmentReportNumber:
          json['fire_department_report_number'] as String?,
      fireDepartmentName: json['fire_department_name'] as String?,
      dateOfLoss: _parseDate(json['date_of_loss']),
      damageSeverity:
          DamageSeverity.fromString(json['damage_severity'] as String?),
      structuralCompromise: json['structural_compromise'] as bool? ?? false,
      roofDamage: json['roof_damage'] as bool? ?? false,
      foundationDamage: json['foundation_damage'] as bool? ?? false,
      loadBearingAffected: json['load_bearing_affected'] as bool? ?? false,
      structuralNotes: json['structural_notes'] as String?,
      damageZones: _parseJsonList(json['damage_zones'], DamageZone.fromJson),
      sootAssessments:
          _parseJsonList(json['soot_assessments'], SootAssessment.fromJson),
      odorTreatments:
          _parseJsonList(json['odor_treatments'], OdorTreatment.fromJson),
      boardUpEntries:
          _parseJsonList(json['board_up_entries'], BoardUpEntry.fromJson),
      airQualityReadings: _parseRawJsonList(json['air_quality_readings']),
      waterDamageFromSuppression:
          json['water_damage_from_suppression'] as bool? ?? false,
      waterDamageAssessmentId:
          json['water_damage_assessment_id'] as String?,
      photos: _parseRawJsonList(json['photos']),
      assessmentStatus:
          AssessmentStatus.fromString(json['assessment_status'] as String?),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  // Computed
  int get totalRoomsAffected {
    final rooms = <String>{};
    for (final z in damageZones) {
      rooms.add(z.room);
    }
    return rooms.length;
  }

  bool get hasDirectFlame =>
      damageZones.any((z) => z.zoneType == DamageZoneType.directFlame);

  bool get hasStructuralConcerns =>
      structuralCompromise ||
      roofDamage ||
      foundationDamage ||
      loadBearingAffected;

  int get totalBoardUps => boardUpEntries.length;

  int get completedOdorTreatments =>
      odorTreatments.where((t) => t.isComplete).length;
}

// =============================================================================
// HELPERS
// =============================================================================

List<T> _parseJsonList<T>(
    dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value == null) return [];
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((item) => fromJson(item))
        .toList();
  }
  return [];
}

List<Map<String, dynamic>> _parseRawJsonList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().toList();
  }
  return [];
}
