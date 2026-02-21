// ZAFTO Mold Remediation Models
// Created: DEPTH35 — Assessment, moisture mapping, remediation plans,
// equipment deployments, lab samples, clearance tests, state licensing.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum MoldSuspectedCause {
  waterIntrusion,
  hvacIssue,
  plumbingLeak,
  flooding,
  condensation,
  unknown,
  roofLeak,
  foundationCrack;

  String toJson() {
    switch (this) {
      case MoldSuspectedCause.waterIntrusion:
        return 'water_intrusion';
      case MoldSuspectedCause.hvacIssue:
        return 'hvac_issue';
      case MoldSuspectedCause.plumbingLeak:
        return 'plumbing_leak';
      case MoldSuspectedCause.roofLeak:
        return 'roof_leak';
      case MoldSuspectedCause.foundationCrack:
        return 'foundation_crack';
      default:
        return name;
    }
  }

  static MoldSuspectedCause fromJson(String? value) {
    switch (value) {
      case 'water_intrusion':
        return MoldSuspectedCause.waterIntrusion;
      case 'hvac_issue':
        return MoldSuspectedCause.hvacIssue;
      case 'plumbing_leak':
        return MoldSuspectedCause.plumbingLeak;
      case 'roof_leak':
        return MoldSuspectedCause.roofLeak;
      case 'foundation_crack':
        return MoldSuspectedCause.foundationCrack;
      case 'flooding':
        return MoldSuspectedCause.flooding;
      case 'condensation':
        return MoldSuspectedCause.condensation;
      default:
        return MoldSuspectedCause.unknown;
    }
  }
}

enum MoistureSourceStatus {
  activeLeak,
  resolved,
  unknown;

  String toJson() {
    switch (this) {
      case MoistureSourceStatus.activeLeak:
        return 'active_leak';
      default:
        return name;
    }
  }

  static MoistureSourceStatus fromJson(String? value) {
    switch (value) {
      case 'active_leak':
        return MoistureSourceStatus.activeLeak;
      case 'resolved':
        return MoistureSourceStatus.resolved;
      default:
        return MoistureSourceStatus.unknown;
    }
  }
}

enum OccupancyStatus {
  occupied,
  vacant,
  evacuated;

  String toJson() => name;

  static OccupancyStatus fromJson(String? value) {
    return OccupancyStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OccupancyStatus.vacant,
    );
  }
}

enum MoistureReadingType {
  surfacePin,
  relativeHumidity,
  dewPoint,
  woodMoistureContent;

  String toJson() {
    switch (this) {
      case MoistureReadingType.surfacePin:
        return 'surface_pin';
      case MoistureReadingType.relativeHumidity:
        return 'relative_humidity';
      case MoistureReadingType.dewPoint:
        return 'dew_point';
      case MoistureReadingType.woodMoistureContent:
        return 'wood_moisture_content';
    }
  }

  static MoistureReadingType fromJson(String value) {
    switch (value) {
      case 'surface_pin':
        return MoistureReadingType.surfacePin;
      case 'relative_humidity':
        return MoistureReadingType.relativeHumidity;
      case 'dew_point':
        return MoistureReadingType.dewPoint;
      case 'wood_moisture_content':
        return MoistureReadingType.woodMoistureContent;
      default:
        return MoistureReadingType.surfacePin;
    }
  }
}

enum MoistureSeverity {
  normal,
  concern,
  saturation;

  String toJson() => name;

  static MoistureSeverity fromJson(String? value) {
    return MoistureSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MoistureSeverity.normal,
    );
  }
}

enum RemediationPlanStatus {
  planned,
  inProgress,
  completed,
  onHold;

  String toJson() {
    switch (this) {
      case RemediationPlanStatus.inProgress:
        return 'in_progress';
      case RemediationPlanStatus.onHold:
        return 'on_hold';
      default:
        return name;
    }
  }

  static RemediationPlanStatus fromJson(String value) {
    switch (value) {
      case 'in_progress':
        return RemediationPlanStatus.inProgress;
      case 'on_hold':
        return RemediationPlanStatus.onHold;
      case 'completed':
        return RemediationPlanStatus.completed;
      default:
        return RemediationPlanStatus.planned;
    }
  }
}

enum ContainmentType {
  minimal,
  limited,
  full;

  String toJson() => name;

  static ContainmentType fromJson(String? value) {
    return ContainmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ContainmentType.minimal,
    );
  }
}

enum MoldEquipmentType {
  dehumidifier,
  airScrubber,
  negativeAirMachine,
  airMover,
  moistureMeter,
  thermoHygrometer,
  hepaVacuum,
  sprayer,
  other;

  String toJson() {
    switch (this) {
      case MoldEquipmentType.airScrubber:
        return 'air_scrubber';
      case MoldEquipmentType.negativeAirMachine:
        return 'negative_air_machine';
      case MoldEquipmentType.airMover:
        return 'air_mover';
      case MoldEquipmentType.moistureMeter:
        return 'moisture_meter';
      case MoldEquipmentType.thermoHygrometer:
        return 'thermo_hygrometer';
      case MoldEquipmentType.hepaVacuum:
        return 'hepa_vacuum';
      default:
        return name;
    }
  }

  static MoldEquipmentType fromJson(String value) {
    switch (value) {
      case 'air_scrubber':
        return MoldEquipmentType.airScrubber;
      case 'negative_air_machine':
        return MoldEquipmentType.negativeAirMachine;
      case 'air_mover':
        return MoldEquipmentType.airMover;
      case 'moisture_meter':
        return MoldEquipmentType.moistureMeter;
      case 'thermo_hygrometer':
        return MoldEquipmentType.thermoHygrometer;
      case 'hepa_vacuum':
        return MoldEquipmentType.hepaVacuum;
      default:
        return MoldEquipmentType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => MoldEquipmentType.other,
        );
    }
  }
}

enum LabSampleType {
  airCassette,
  tapeLift,
  bulkSwab,
  surfaceWipe;

  String toJson() {
    switch (this) {
      case LabSampleType.airCassette:
        return 'air_cassette';
      case LabSampleType.tapeLift:
        return 'tape_lift';
      case LabSampleType.bulkSwab:
        return 'bulk_swab';
      case LabSampleType.surfaceWipe:
        return 'surface_wipe';
    }
  }

  static LabSampleType fromJson(String value) {
    switch (value) {
      case 'air_cassette':
        return LabSampleType.airCassette;
      case 'tape_lift':
        return LabSampleType.tapeLift;
      case 'bulk_swab':
        return LabSampleType.bulkSwab;
      case 'surface_wipe':
        return LabSampleType.surfaceWipe;
      default:
        return LabSampleType.airCassette;
    }
  }
}

enum LabSampleStatus {
  pending,
  sent,
  received,
  resultsIn;

  String toJson() {
    switch (this) {
      case LabSampleStatus.resultsIn:
        return 'results_in';
      default:
        return name;
    }
  }

  static LabSampleStatus fromJson(String value) {
    switch (value) {
      case 'results_in':
        return LabSampleStatus.resultsIn;
      case 'sent':
        return LabSampleStatus.sent;
      case 'received':
        return LabSampleStatus.received;
      default:
        return LabSampleStatus.pending;
    }
  }
}

enum ClearanceResult {
  pass,
  fail,
  conditional;

  String toJson() => name;

  static ClearanceResult? fromJson(String? value) {
    if (value == null) return null;
    return ClearanceResult.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClearanceResult.fail,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// MOLD STATE LICENSING
// ════════════════════════════════════════════════════════════════

class MoldStateLicensing extends Equatable {
  final String id;
  final String stateCode;
  final String stateName;
  final bool licenseRequired;
  final List<dynamic> licenseTypes;
  final String? issuingAgency;
  final String? agencyUrl;
  final String? costRange;
  final String? renewalPeriod;
  final String? ceRequirements;
  final List<dynamic> reciprocityStates;
  final String? notes;

  const MoldStateLicensing({
    required this.id,
    required this.stateCode,
    required this.stateName,
    required this.licenseRequired,
    this.licenseTypes = const [],
    this.issuingAgency,
    this.agencyUrl,
    this.costRange,
    this.renewalPeriod,
    this.ceRequirements,
    this.reciprocityStates = const [],
    this.notes,
  });

  factory MoldStateLicensing.fromJson(Map<String, dynamic> json) {
    return MoldStateLicensing(
      id: json['id'] as String,
      stateCode: json['state_code'] as String,
      stateName: json['state_name'] as String,
      licenseRequired: json['license_required'] as bool? ?? false,
      licenseTypes: json['license_types'] as List<dynamic>? ?? const [],
      issuingAgency: json['issuing_agency'] as String?,
      agencyUrl: json['agency_url'] as String?,
      costRange: json['cost_range'] as String?,
      renewalPeriod: json['renewal_period'] as String?,
      ceRequirements: json['ce_requirements'] as String?,
      reciprocityStates:
          json['reciprocity_states'] as List<dynamic>? ?? const [],
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, stateCode];
}

// ════════════════════════════════════════════════════════════════
// MOLD ASSESSMENT
// ════════════════════════════════════════════════════════════════

class MoldAssessment extends Equatable {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? jobId;
  final String? assessedBy;
  final String assessmentDate;
  final MoldSuspectedCause suspectedCause;
  final double? affectedAreaSqft;
  final List<dynamic> affectedMaterials;
  final List<dynamic> visibleMoldType;
  final MoistureSourceStatus moistureSourceStatus;
  final OccupancyStatus occupancyStatus;
  final int? remediationLevel;
  final String? overallNotes;
  final String createdAt;
  final String updatedAt;

  const MoldAssessment({
    required this.id,
    required this.companyId,
    this.propertyId,
    this.jobId,
    this.assessedBy,
    required this.assessmentDate,
    required this.suspectedCause,
    this.affectedAreaSqft,
    this.affectedMaterials = const [],
    this.visibleMoldType = const [],
    required this.moistureSourceStatus,
    required this.occupancyStatus,
    this.remediationLevel,
    this.overallNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoldAssessment.fromJson(Map<String, dynamic> json) {
    return MoldAssessment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      propertyId: json['property_id'] as String?,
      jobId: json['job_id'] as String?,
      assessedBy: json['assessed_by'] as String?,
      assessmentDate: json['assessment_date'] as String,
      suspectedCause:
          MoldSuspectedCause.fromJson(json['suspected_cause'] as String?),
      affectedAreaSqft: _parseDouble(json['affected_area_sqft']),
      affectedMaterials:
          json['affected_materials'] as List<dynamic>? ?? const [],
      visibleMoldType:
          json['visible_mold_type'] as List<dynamic>? ?? const [],
      moistureSourceStatus: MoistureSourceStatus.fromJson(
          json['moisture_source_status'] as String?),
      occupancyStatus:
          OccupancyStatus.fromJson(json['occupancy_status'] as String?),
      remediationLevel: json['remediation_level'] as int?,
      overallNotes: json['overall_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        'job_id': jobId,
        'assessed_by': assessedBy,
        'suspected_cause': suspectedCause.toJson(),
        'affected_area_sqft': affectedAreaSqft,
        'affected_materials': affectedMaterials,
        'visible_mold_type': visibleMoldType,
        'moisture_source_status': moistureSourceStatus.toJson(),
        'occupancy_status': occupancyStatus.toJson(),
        'remediation_level': remediationLevel,
        'overall_notes': overallNotes,
      };

  /// Auto-determine IICRC S520 level from affected area
  int get suggestedLevel {
    if (affectedAreaSqft == null) return 1;
    if (affectedAreaSqft! <= 10) return 1;
    if (affectedAreaSqft! <= 30) return 2;
    return 3;
  }

  @override
  List<Object?> get props => [id, companyId, propertyId, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MOLD MOISTURE READING
// ════════════════════════════════════════════════════════════════

class MoldMoistureReading extends Equatable {
  final String id;
  final String companyId;
  final String assessmentId;
  final String roomName;
  final String? locationDetail;
  final MoistureReadingType readingType;
  final double readingValue;
  final String readingUnit;
  final MoistureSeverity? severity;
  final String? meterModel;
  final String? notes;
  final String createdAt;

  const MoldMoistureReading({
    required this.id,
    required this.companyId,
    required this.assessmentId,
    required this.roomName,
    this.locationDetail,
    required this.readingType,
    required this.readingValue,
    this.readingUnit = '%',
    this.severity,
    this.meterModel,
    this.notes,
    required this.createdAt,
  });

  factory MoldMoistureReading.fromJson(Map<String, dynamic> json) {
    return MoldMoistureReading(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      assessmentId: json['assessment_id'] as String,
      roomName: json['room_name'] as String,
      locationDetail: json['location_detail'] as String?,
      readingType:
          MoistureReadingType.fromJson(json['reading_type'] as String),
      readingValue: _parseDouble(json['reading_value']) ?? 0,
      readingUnit: json['reading_unit'] as String? ?? '%',
      severity: json['severity'] != null
          ? MoistureSeverity.fromJson(json['severity'] as String)
          : null,
      meterModel: json['meter_model'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'assessment_id': assessmentId,
        'room_name': roomName,
        'location_detail': locationDetail,
        'reading_type': readingType.toJson(),
        'reading_value': readingValue,
        'reading_unit': readingUnit,
        'severity': severity?.toJson(),
        'meter_model': meterModel,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, assessmentId, roomName, readingType];
}

// ════════════════════════════════════════════════════════════════
// MOLD REMEDIATION PLAN
// ════════════════════════════════════════════════════════════════

class MoldRemediationPlan extends Equatable {
  final String id;
  final String companyId;
  final String assessmentId;
  final String? jobId;
  final int remediationLevel;
  final ContainmentType? containmentType;
  final String? scopeDescription;
  final List<dynamic> materialsToRemove;
  final Map<String, dynamic> checklistProgress;
  final RemediationPlanStatus status;
  final String? startedAt;
  final String? completedAt;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const MoldRemediationPlan({
    required this.id,
    required this.companyId,
    required this.assessmentId,
    this.jobId,
    required this.remediationLevel,
    this.containmentType,
    this.scopeDescription,
    this.materialsToRemove = const [],
    this.checklistProgress = const {},
    required this.status,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoldRemediationPlan.fromJson(Map<String, dynamic> json) {
    return MoldRemediationPlan(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      assessmentId: json['assessment_id'] as String,
      jobId: json['job_id'] as String?,
      remediationLevel: json['remediation_level'] as int,
      containmentType: json['containment_type'] != null
          ? ContainmentType.fromJson(json['containment_type'] as String)
          : null,
      scopeDescription: json['scope_description'] as String?,
      materialsToRemove:
          json['materials_to_remove'] as List<dynamic>? ?? const [],
      checklistProgress: json['checklist_progress'] != null
          ? Map<String, dynamic>.from(json['checklist_progress'] as Map)
          : const {},
      status: RemediationPlanStatus.fromJson(json['status'] as String),
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'assessment_id': assessmentId,
        'job_id': jobId,
        'remediation_level': remediationLevel,
        'containment_type': containmentType?.toJson(),
        'scope_description': scopeDescription,
        'materials_to_remove': materialsToRemove,
        'checklist_progress': checklistProgress,
        'status': status.toJson(),
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, companyId, assessmentId, status, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// MOLD EQUIPMENT DEPLOYMENT
// ════════════════════════════════════════════════════════════════

class MoldEquipmentDeployment extends Equatable {
  final String id;
  final String companyId;
  final String? remediationId;
  final MoldEquipmentType equipmentType;
  final String? modelName;
  final String? serialNumber;
  final String? capacity;
  final String? placementLocation;
  final String deployedAt;
  final String? retrievedAt;
  final double? runtimeHours;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const MoldEquipmentDeployment({
    required this.id,
    required this.companyId,
    this.remediationId,
    required this.equipmentType,
    this.modelName,
    this.serialNumber,
    this.capacity,
    this.placementLocation,
    required this.deployedAt,
    this.retrievedAt,
    this.runtimeHours,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoldEquipmentDeployment.fromJson(Map<String, dynamic> json) {
    return MoldEquipmentDeployment(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      remediationId: json['remediation_id'] as String?,
      equipmentType:
          MoldEquipmentType.fromJson(json['equipment_type'] as String),
      modelName: json['model_name'] as String?,
      serialNumber: json['serial_number'] as String?,
      capacity: json['capacity'] as String?,
      placementLocation: json['placement_location'] as String?,
      deployedAt: json['deployed_at'] as String,
      retrievedAt: json['retrieved_at'] as String?,
      runtimeHours: _parseDouble(json['runtime_hours']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'remediation_id': remediationId,
        'equipment_type': equipmentType.toJson(),
        'model_name': modelName,
        'serial_number': serialNumber,
        'capacity': capacity,
        'placement_location': placementLocation,
        'notes': notes,
      };

  bool get isDeployed => retrievedAt == null;

  @override
  List<Object?> get props => [id, companyId, equipmentType, deployedAt];
}

// ════════════════════════════════════════════════════════════════
// MOLD LAB SAMPLE
// ════════════════════════════════════════════════════════════════

class MoldLabSample extends Equatable {
  final String id;
  final String companyId;
  final String? assessmentId;
  final LabSampleType sampleType;
  final String sampleLocation;
  final String? roomName;
  final String dateCollected;
  final String? collectedBy;
  final String? labName;
  final String? labReference;
  final LabSampleStatus status;
  final List<dynamic> speciesFound;
  final double? sporeCount;
  final String sporeCountUnit;
  final double? outdoorBaseline;
  final String? passFail;
  final String? resultsNotes;
  final String createdAt;
  final String updatedAt;

  const MoldLabSample({
    required this.id,
    required this.companyId,
    this.assessmentId,
    required this.sampleType,
    required this.sampleLocation,
    this.roomName,
    required this.dateCollected,
    this.collectedBy,
    this.labName,
    this.labReference,
    required this.status,
    this.speciesFound = const [],
    this.sporeCount,
    this.sporeCountUnit = 'spores_per_m3',
    this.outdoorBaseline,
    this.passFail,
    this.resultsNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoldLabSample.fromJson(Map<String, dynamic> json) {
    return MoldLabSample(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      assessmentId: json['assessment_id'] as String?,
      sampleType: LabSampleType.fromJson(json['sample_type'] as String),
      sampleLocation: json['sample_location'] as String,
      roomName: json['room_name'] as String?,
      dateCollected: json['date_collected'] as String,
      collectedBy: json['collected_by'] as String?,
      labName: json['lab_name'] as String?,
      labReference: json['lab_reference'] as String?,
      status: LabSampleStatus.fromJson(json['status'] as String),
      speciesFound: json['species_found'] as List<dynamic>? ?? const [],
      sporeCount: _parseDouble(json['spore_count']),
      sporeCountUnit: json['spore_count_unit'] as String? ?? 'spores_per_m3',
      outdoorBaseline: _parseDouble(json['outdoor_baseline']),
      passFail: json['pass_fail'] as String?,
      resultsNotes: json['results_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'assessment_id': assessmentId,
        'sample_type': sampleType.toJson(),
        'sample_location': sampleLocation,
        'room_name': roomName,
        'lab_name': labName,
        'lab_reference': labReference,
        'status': status.toJson(),
        'species_found': speciesFound,
        'spore_count': sporeCount,
        'outdoor_baseline': outdoorBaseline,
        'results_notes': resultsNotes,
      };

  bool get hasResults => status == LabSampleStatus.resultsIn;

  @override
  List<Object?> get props => [id, companyId, sampleType, status];
}

// ════════════════════════════════════════════════════════════════
// MOLD CLEARANCE TEST
// ════════════════════════════════════════════════════════════════

class MoldClearanceTest extends Equatable {
  final String id;
  final String companyId;
  final String? remediationId;
  final String? assessmentId;
  final String clearanceDate;
  final String? assessorName;
  final String? assessorCompany;
  final String? assessorLicense;
  final bool? visualPass;
  final bool? moisturePass;
  final bool? airQualityPass;
  final bool? odorPass;
  final ClearanceResult? overallResult;
  final List<dynamic> postMoistureReadings;
  final String? labResultsRef;
  final String? certificateNumber;
  final String? certificateUrl;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const MoldClearanceTest({
    required this.id,
    required this.companyId,
    this.remediationId,
    this.assessmentId,
    required this.clearanceDate,
    this.assessorName,
    this.assessorCompany,
    this.assessorLicense,
    this.visualPass,
    this.moisturePass,
    this.airQualityPass,
    this.odorPass,
    this.overallResult,
    this.postMoistureReadings = const [],
    this.labResultsRef,
    this.certificateNumber,
    this.certificateUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoldClearanceTest.fromJson(Map<String, dynamic> json) {
    return MoldClearanceTest(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      remediationId: json['remediation_id'] as String?,
      assessmentId: json['assessment_id'] as String?,
      clearanceDate: json['clearance_date'] as String,
      assessorName: json['assessor_name'] as String?,
      assessorCompany: json['assessor_company'] as String?,
      assessorLicense: json['assessor_license'] as String?,
      visualPass: json['visual_pass'] as bool?,
      moisturePass: json['moisture_pass'] as bool?,
      airQualityPass: json['air_quality_pass'] as bool?,
      odorPass: json['odor_pass'] as bool?,
      overallResult:
          ClearanceResult.fromJson(json['overall_result'] as String?),
      postMoistureReadings:
          json['post_moisture_readings'] as List<dynamic>? ?? const [],
      labResultsRef: json['lab_results_ref'] as String?,
      certificateNumber: json['certificate_number'] as String?,
      certificateUrl: json['certificate_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'remediation_id': remediationId,
        'assessment_id': assessmentId,
        'assessor_name': assessorName,
        'assessor_company': assessorCompany,
        'assessor_license': assessorLicense,
        'visual_pass': visualPass,
        'moisture_pass': moisturePass,
        'air_quality_pass': airQualityPass,
        'odor_pass': odorPass,
        'overall_result': overallResult?.toJson(),
        'post_moisture_readings': postMoistureReadings,
        'lab_results_ref': labResultsRef,
        'certificate_number': certificateNumber,
        'notes': notes,
      };

  bool get passed => overallResult == ClearanceResult.pass;

  @override
  List<Object?> get props => [id, companyId, overallResult, clearanceDate];
}

// ════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
