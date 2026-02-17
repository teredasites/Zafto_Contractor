// ZAFTO Mold Assessment Model — Supabase Backend
// Maps to `mold_assessments` table. Sprint REST2.
// IICRC S520 compliant: levels 1-3, containment, air sampling, clearance.

enum IicrcLevel {
  level1(1),
  level2(2),
  level3(3);

  final int value;
  const IicrcLevel(this.value);

  String get label {
    switch (this) {
      case IicrcLevel.level1:
        return 'Level 1 — Small (<10 sqft)';
      case IicrcLevel.level2:
        return 'Level 2 — Medium (10-30 sqft)';
      case IicrcLevel.level3:
        return 'Level 3 — Large (>30 sqft)';
    }
  }

  String get containmentRequired {
    switch (this) {
      case IicrcLevel.level1:
        return 'None or limited. Work area isolation.';
      case IicrcLevel.level2:
        return 'Limited or full. Poly sheeting, negative air recommended.';
      case IicrcLevel.level3:
        return 'Full containment REQUIRED. Negative air, decon chamber, HEPA.';
    }
  }

  String get ppeRequired {
    switch (this) {
      case IicrcLevel.level1:
        return 'N95 respirator, goggles, gloves';
      case IicrcLevel.level2:
        return 'Half-face P100, goggles, Tyvek, gloves';
      case IicrcLevel.level3:
        return 'Full-face P100, goggles, full Tyvek, boot covers, gloves';
    }
  }

  String get airSampling {
    switch (this) {
      case IicrcLevel.level1:
        return 'Not typically required';
      case IicrcLevel.level2:
        return 'Recommended. Pre and post remediation.';
      case IicrcLevel.level3:
        return 'REQUIRED. Pre-remediation, post-remediation, outdoor baseline. Clearance testing mandatory.';
    }
  }

  static IicrcLevel fromInt(int? value) {
    if (value == null || value < 1) return IicrcLevel.level2;
    if (value >= 3) return IicrcLevel.level3;
    return IicrcLevel.values.firstWhere((e) => e.value == value, orElse: () => IicrcLevel.level2);
  }
}

enum ContainmentType {
  none,
  limited,
  full;

  String get label {
    switch (this) {
      case ContainmentType.none:
        return 'None';
      case ContainmentType.limited:
        return 'Limited';
      case ContainmentType.full:
        return 'Full';
    }
  }

  static ContainmentType fromString(String? value) {
    if (value == null) return ContainmentType.none;
    return ContainmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContainmentType.none,
    );
  }
}

enum MoldClearanceStatus {
  pending,
  sampling,
  awaitingResults,
  passed,
  failed,
  notRequired;

  String get dbValue {
    switch (this) {
      case MoldClearanceStatus.awaitingResults:
        return 'awaiting_results';
      case MoldClearanceStatus.notRequired:
        return 'not_required';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case MoldClearanceStatus.pending:
        return 'Pending';
      case MoldClearanceStatus.sampling:
        return 'Sampling';
      case MoldClearanceStatus.awaitingResults:
        return 'Awaiting Results';
      case MoldClearanceStatus.passed:
        return 'PASSED';
      case MoldClearanceStatus.failed:
        return 'FAILED';
      case MoldClearanceStatus.notRequired:
        return 'Not Required';
    }
  }

  static MoldClearanceStatus fromString(String? value) {
    if (value == null) return MoldClearanceStatus.pending;
    switch (value) {
      case 'awaiting_results':
        return MoldClearanceStatus.awaitingResults;
      case 'not_required':
        return MoldClearanceStatus.notRequired;
      default:
        return MoldClearanceStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => MoldClearanceStatus.pending,
        );
    }
  }
}

enum MoldAssessmentStatus {
  inProgress,
  pendingReview,
  remediationActive,
  awaitingClearance,
  cleared,
  failedClearance;

  String get dbValue {
    switch (this) {
      case MoldAssessmentStatus.inProgress:
        return 'in_progress';
      case MoldAssessmentStatus.pendingReview:
        return 'pending_review';
      case MoldAssessmentStatus.remediationActive:
        return 'remediation_active';
      case MoldAssessmentStatus.awaitingClearance:
        return 'awaiting_clearance';
      case MoldAssessmentStatus.failedClearance:
        return 'failed_clearance';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case MoldAssessmentStatus.inProgress:
        return 'In Progress';
      case MoldAssessmentStatus.pendingReview:
        return 'Pending Review';
      case MoldAssessmentStatus.remediationActive:
        return 'Remediation Active';
      case MoldAssessmentStatus.awaitingClearance:
        return 'Awaiting Clearance';
      case MoldAssessmentStatus.cleared:
        return 'Cleared';
      case MoldAssessmentStatus.failedClearance:
        return 'Failed Clearance';
    }
  }

  static MoldAssessmentStatus fromString(String? value) {
    if (value == null) return MoldAssessmentStatus.inProgress;
    switch (value) {
      case 'in_progress':
        return MoldAssessmentStatus.inProgress;
      case 'pending_review':
        return MoldAssessmentStatus.pendingReview;
      case 'remediation_active':
        return MoldAssessmentStatus.remediationActive;
      case 'awaiting_clearance':
        return MoldAssessmentStatus.awaitingClearance;
      case 'failed_clearance':
        return MoldAssessmentStatus.failedClearance;
      default:
        return MoldAssessmentStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => MoldAssessmentStatus.inProgress,
        );
    }
  }
}

enum SampleType {
  air,
  surface,
  bulk,
  tapeLift;

  String get dbValue {
    switch (this) {
      case SampleType.tapeLift:
        return 'tape_lift';
      default:
        return name;
    }
  }

  String get label {
    switch (this) {
      case SampleType.air:
        return 'Air Sample';
      case SampleType.surface:
        return 'Surface Sample';
      case SampleType.bulk:
        return 'Bulk Sample';
      case SampleType.tapeLift:
        return 'Tape Lift';
    }
  }

  static SampleType fromString(String? value) {
    if (value == null) return SampleType.air;
    switch (value) {
      case 'tape_lift':
        return SampleType.tapeLift;
      default:
        return SampleType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => SampleType.air,
        );
    }
  }
}

// =============================================================================
// MAIN MODEL
// =============================================================================

class MoldAssessment {
  final String id;
  final String companyId;
  final String jobId;
  final String? insuranceClaimId;
  final String? createdByUserId;

  // IICRC
  final IicrcLevel iicrcLevel;
  final double? affectedAreaSqft;
  final String? moldType;
  final String? moistureSource;

  // Containment
  final ContainmentType containmentType;
  final bool negativePressure;
  final String? containmentNotes;
  final List<Map<String, dynamic>> containmentChecks;

  // Air sampling
  final bool airSamplingRequired;
  final List<Map<String, dynamic>> preSamples;
  final List<Map<String, dynamic>> postSamples;
  final Map<String, dynamic>? outdoorBaseline;

  // Clearance
  final MoldClearanceStatus clearanceStatus;
  final DateTime? clearanceDate;
  final String? clearanceInspector;
  final String? clearanceCompany;

  // Lab
  final String? labName;
  final String? labSampleId;
  final double? sporeCountBefore;
  final double? sporeCountAfter;

  // Protocol
  final String? protocolLevel;
  final List<Map<String, dynamic>> protocolSteps;
  final List<Map<String, dynamic>> materialRemoval;
  final List<Map<String, dynamic>> equipmentDeployed;
  final String? ppeLevel;
  final List<Map<String, dynamic>> antimicrobialTreatments;

  // Photos
  final List<Map<String, dynamic>> photos;

  // Status
  final MoldAssessmentStatus assessmentStatus;
  final String? notes;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoldAssessment({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.insuranceClaimId,
    this.createdByUserId,
    this.iicrcLevel = IicrcLevel.level2,
    this.affectedAreaSqft,
    this.moldType,
    this.moistureSource,
    this.containmentType = ContainmentType.none,
    this.negativePressure = false,
    this.containmentNotes,
    this.containmentChecks = const [],
    this.airSamplingRequired = false,
    this.preSamples = const [],
    this.postSamples = const [],
    this.outdoorBaseline,
    this.clearanceStatus = MoldClearanceStatus.pending,
    this.clearanceDate,
    this.clearanceInspector,
    this.clearanceCompany,
    this.labName,
    this.labSampleId,
    this.sporeCountBefore,
    this.sporeCountAfter,
    this.protocolLevel,
    this.protocolSteps = const [],
    this.materialRemoval = const [],
    this.equipmentDeployed = const [],
    this.ppeLevel,
    this.antimicrobialTreatments = const [],
    this.photos = const [],
    this.assessmentStatus = MoldAssessmentStatus.inProgress,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        if (insuranceClaimId != null) 'insurance_claim_id': insuranceClaimId,
        if (createdByUserId != null) 'created_by_user_id': createdByUserId,
        'iicrc_level': iicrcLevel.value,
        if (affectedAreaSqft != null) 'affected_area_sqft': affectedAreaSqft,
        if (moldType != null) 'mold_type': moldType,
        if (moistureSource != null) 'moisture_source': moistureSource,
        'containment_type': containmentType.name,
        'negative_pressure': negativePressure,
        if (containmentNotes != null) 'containment_notes': containmentNotes,
        'containment_checks': containmentChecks,
        'air_sampling_required': airSamplingRequired,
        'pre_samples': preSamples,
        'post_samples': postSamples,
        if (outdoorBaseline != null) 'outdoor_baseline': outdoorBaseline,
        'clearance_status': clearanceStatus.dbValue,
        if (protocolLevel != null) 'protocol_level': protocolLevel,
        'protocol_steps': protocolSteps,
        'material_removal': materialRemoval,
        'equipment_deployed': equipmentDeployed,
        if (ppeLevel != null) 'ppe_level': ppeLevel,
        'antimicrobial_treatments': antimicrobialTreatments,
        'photos': photos,
        'assessment_status': assessmentStatus.dbValue,
        if (notes != null) 'notes': notes,
      };

  factory MoldAssessment.fromJson(Map<String, dynamic> json) {
    return MoldAssessment(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      insuranceClaimId: json['insurance_claim_id'] as String?,
      createdByUserId: json['created_by_user_id'] as String?,
      iicrcLevel: IicrcLevel.fromInt(json['iicrc_level'] as int?),
      affectedAreaSqft: (json['affected_area_sqft'] as num?)?.toDouble(),
      moldType: json['mold_type'] as String?,
      moistureSource: json['moisture_source'] as String?,
      containmentType: ContainmentType.fromString(json['containment_type'] as String?),
      negativePressure: json['negative_pressure'] as bool? ?? false,
      containmentNotes: json['containment_notes'] as String?,
      containmentChecks: _parseRaw(json['containment_checks']),
      airSamplingRequired: json['air_sampling_required'] as bool? ?? false,
      preSamples: _parseRaw(json['pre_samples']),
      postSamples: _parseRaw(json['post_samples']),
      outdoorBaseline: json['outdoor_baseline'] as Map<String, dynamic>?,
      clearanceStatus: MoldClearanceStatus.fromString(json['clearance_status'] as String?),
      clearanceDate: _parseDate(json['clearance_date']),
      clearanceInspector: json['clearance_inspector'] as String?,
      clearanceCompany: json['clearance_company'] as String?,
      labName: json['lab_name'] as String?,
      labSampleId: json['lab_sample_id'] as String?,
      sporeCountBefore: (json['spore_count_before'] as num?)?.toDouble(),
      sporeCountAfter: (json['spore_count_after'] as num?)?.toDouble(),
      protocolLevel: json['protocol_level'] as String?,
      protocolSteps: _parseRaw(json['protocol_steps']),
      materialRemoval: _parseRaw(json['material_removal']),
      equipmentDeployed: _parseRaw(json['equipment_deployed']),
      ppeLevel: json['ppe_level'] as String?,
      antimicrobialTreatments: _parseRaw(json['antimicrobial_treatments']),
      photos: _parseRaw(json['photos']),
      assessmentStatus: MoldAssessmentStatus.fromString(json['assessment_status'] as String?),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  // Computed
  bool get isCleared => clearanceStatus == MoldClearanceStatus.passed;
  bool get needsClearance =>
      iicrcLevel == IicrcLevel.level3 ||
      (iicrcLevel == IicrcLevel.level2 && airSamplingRequired);

  double get sporeReduction {
    if (sporeCountBefore == null || sporeCountAfter == null || sporeCountBefore == 0) return 0;
    return ((sporeCountBefore! - sporeCountAfter!) / sporeCountBefore!) * 100;
  }
}

List<Map<String, dynamic>> _parseRaw(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.whereType<Map<String, dynamic>>().toList();
  return [];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
