// ZAFTO Property Preservation Models
// Created: DEPTH34 — PP work orders, national companies, winterization,
// debris estimation, chargebacks, utility tracking, vendor apps,
// boiler/furnace DB, pricing matrices, stripped property estimates.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ENUMS
// ════════════════════════════════════════════════════════════════

enum PpWorkOrderStatus {
  assigned,
  inProgress,
  completed,
  submitted,
  approved,
  rejected,
  disputed;

  String toJson() {
    switch (this) {
      case PpWorkOrderStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

  static PpWorkOrderStatus fromJson(String value) {
    switch (value) {
      case 'in_progress':
        return PpWorkOrderStatus.inProgress;
      case 'assigned':
        return PpWorkOrderStatus.assigned;
      case 'completed':
        return PpWorkOrderStatus.completed;
      case 'submitted':
        return PpWorkOrderStatus.submitted;
      case 'approved':
        return PpWorkOrderStatus.approved;
      case 'rejected':
        return PpWorkOrderStatus.rejected;
      case 'disputed':
        return PpWorkOrderStatus.disputed;
      default:
        return PpWorkOrderStatus.assigned;
    }
  }
}

enum PhotoMode {
  quick,
  standard,
  fullProtection;

  String toJson() {
    switch (this) {
      case PhotoMode.fullProtection:
        return 'full_protection';
      default:
        return name;
    }
  }

  static PhotoMode fromJson(String value) {
    switch (value) {
      case 'full_protection':
        return PhotoMode.fullProtection;
      case 'quick':
        return PhotoMode.quick;
      default:
        return PhotoMode.standard;
    }
  }
}

enum PpWorkOrderCategory {
  securing,
  winterization,
  debris,
  lawnSnow,
  inspection,
  repair,
  utility,
  specialty;

  String toJson() {
    switch (this) {
      case PpWorkOrderCategory.lawnSnow:
        return 'lawn_snow';
      default:
        return name;
    }
  }

  static PpWorkOrderCategory fromJson(String value) {
    switch (value) {
      case 'lawn_snow':
        return PpWorkOrderCategory.lawnSnow;
      case 'securing':
        return PpWorkOrderCategory.securing;
      case 'winterization':
        return PpWorkOrderCategory.winterization;
      case 'debris':
        return PpWorkOrderCategory.debris;
      case 'inspection':
        return PpWorkOrderCategory.inspection;
      case 'repair':
        return PpWorkOrderCategory.repair;
      case 'utility':
        return PpWorkOrderCategory.utility;
      default:
        return PpWorkOrderCategory.specialty;
    }
  }
}

enum DisputeStatus {
  none,
  submitted,
  underReview,
  resolvedWon,
  resolvedLost,
  denied;

  String toJson() {
    switch (this) {
      case DisputeStatus.underReview:
        return 'under_review';
      case DisputeStatus.resolvedWon:
        return 'resolved_won';
      case DisputeStatus.resolvedLost:
        return 'resolved_lost';
      default:
        return name;
    }
  }

  static DisputeStatus fromJson(String value) {
    switch (value) {
      case 'under_review':
        return DisputeStatus.underReview;
      case 'resolved_won':
        return DisputeStatus.resolvedWon;
      case 'resolved_lost':
        return DisputeStatus.resolvedLost;
      case 'submitted':
        return DisputeStatus.submitted;
      case 'denied':
        return DisputeStatus.denied;
      default:
        return DisputeStatus.none;
    }
  }
}

enum HeatType {
  dry,
  wetRadiant,
  steam,
  electric,
  none;

  String toJson() {
    switch (this) {
      case HeatType.wetRadiant:
        return 'wet_radiant';
      default:
        return name;
    }
  }

  static HeatType fromJson(String? value) {
    switch (value) {
      case 'wet_radiant':
        return HeatType.wetRadiant;
      case 'dry':
        return HeatType.dry;
      case 'steam':
        return HeatType.steam;
      case 'electric':
        return HeatType.electric;
      default:
        return HeatType.none;
    }
  }
}

enum CleanoutLevel {
  broomClean,
  normal,
  heavy,
  hoarder;

  String toJson() {
    switch (this) {
      case CleanoutLevel.broomClean:
        return 'broom_clean';
      default:
        return name;
    }
  }

  static CleanoutLevel fromJson(String? value) {
    switch (value) {
      case 'broom_clean':
        return CleanoutLevel.broomClean;
      case 'normal':
        return CleanoutLevel.normal;
      case 'heavy':
        return CleanoutLevel.heavy;
      case 'hoarder':
        return CleanoutLevel.hoarder;
      default:
        return CleanoutLevel.normal;
    }
  }
}

enum UtilityType {
  electric,
  gas,
  water,
  oil,
  propane;

  String toJson() => name;

  static UtilityType fromJson(String value) {
    return UtilityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UtilityType.electric,
    );
  }
}

enum UtilityStatus {
  on,
  off,
  meterPulled,
  winterized,
  unknown;

  String toJson() {
    switch (this) {
      case UtilityStatus.meterPulled:
        return 'meter_pulled';
      default:
        return name;
    }
  }

  static UtilityStatus fromJson(String value) {
    switch (value) {
      case 'meter_pulled':
        return UtilityStatus.meterPulled;
      case 'on':
        return UtilityStatus.on;
      case 'off':
        return UtilityStatus.off;
      case 'winterized':
        return UtilityStatus.winterized;
      default:
        return UtilityStatus.unknown;
    }
  }
}

enum EquipmentType {
  boiler,
  furnace,
  heatPump,
  waterHeater;

  String toJson() {
    switch (this) {
      case EquipmentType.heatPump:
        return 'heat_pump';
      case EquipmentType.waterHeater:
        return 'water_heater';
      default:
        return name;
    }
  }

  static EquipmentType fromJson(String value) {
    switch (value) {
      case 'heat_pump':
        return EquipmentType.heatPump;
      case 'water_heater':
        return EquipmentType.waterHeater;
      case 'boiler':
        return EquipmentType.boiler;
      default:
        return EquipmentType.furnace;
    }
  }
}

enum StrippedEstimateType {
  repipe,
  rewire,
  hvacReplace,
  waterHeater;

  String toJson() {
    switch (this) {
      case StrippedEstimateType.hvacReplace:
        return 'hvac_replace';
      case StrippedEstimateType.waterHeater:
        return 'water_heater';
      default:
        return name;
    }
  }

  static StrippedEstimateType fromJson(String value) {
    switch (value) {
      case 'hvac_replace':
        return StrippedEstimateType.hvacReplace;
      case 'water_heater':
        return StrippedEstimateType.waterHeater;
      case 'rewire':
        return StrippedEstimateType.rewire;
      default:
        return StrippedEstimateType.repipe;
    }
  }
}

// ════════════════════════════════════════════════════════════════
// PP NATIONAL COMPANY
// ════════════════════════════════════════════════════════════════

class PpNationalCompany extends Equatable {
  final String id;
  final String name;
  final String nameNormalized;
  final String? portalUrl;
  final String? vendorSignupUrl;
  final String? phone;
  final String? email;
  final String? photoNaming;
  final String? photoOrientation;
  final Map<String, dynamic> requiredShots;
  final int submissionDeadlineHours;
  final String? paySchedule;
  final double? insuranceMinimum;
  final String? chargebackPolicy;
  final String? notes;
  final bool isActive;

  const PpNationalCompany({
    required this.id,
    required this.name,
    required this.nameNormalized,
    this.portalUrl,
    this.vendorSignupUrl,
    this.phone,
    this.email,
    this.photoNaming,
    this.photoOrientation,
    this.requiredShots = const {},
    this.submissionDeadlineHours = 48,
    this.paySchedule,
    this.insuranceMinimum,
    this.chargebackPolicy,
    this.notes,
    this.isActive = true,
  });

  factory PpNationalCompany.fromJson(Map<String, dynamic> json) {
    return PpNationalCompany(
      id: json['id'] as String,
      name: json['name'] as String,
      nameNormalized: json['name_normalized'] as String,
      portalUrl: json['portal_url'] as String?,
      vendorSignupUrl: json['vendor_signup_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      photoNaming: json['photo_naming'] as String?,
      photoOrientation: json['photo_orientation'] as String?,
      requiredShots: json['required_shots'] != null
          ? Map<String, dynamic>.from(json['required_shots'] as Map)
          : const {},
      submissionDeadlineHours: json['submission_deadline_hours'] as int? ?? 48,
      paySchedule: json['pay_schedule'] as String?,
      insuranceMinimum: _parseDouble(json['insurance_minimum']),
      chargebackPolicy: json['chargeback_policy'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

// ════════════════════════════════════════════════════════════════
// PP WORK ORDER TYPE
// ════════════════════════════════════════════════════════════════

class PpWorkOrderType extends Equatable {
  final String id;
  final String code;
  final String name;
  final PpWorkOrderCategory category;
  final String? description;
  final List<dynamic> defaultChecklist;
  final List<dynamic> requiredPhotos;
  final double? estimatedHours;
  final String? notes;

  const PpWorkOrderType({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.description,
    this.defaultChecklist = const [],
    this.requiredPhotos = const [],
    this.estimatedHours,
    this.notes,
  });

  factory PpWorkOrderType.fromJson(Map<String, dynamic> json) {
    return PpWorkOrderType(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: PpWorkOrderCategory.fromJson(json['category'] as String),
      description: json['description'] as String?,
      defaultChecklist: json['default_checklist'] as List<dynamic>? ?? const [],
      requiredPhotos: json['required_photos'] as List<dynamic>? ?? const [],
      estimatedHours: _parseDouble(json['estimated_hours']),
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, code, name];
}

// ════════════════════════════════════════════════════════════════
// PP WORK ORDER
// ════════════════════════════════════════════════════════════════

class PpWorkOrder extends Equatable {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? jobId;
  final String? nationalCompanyId;
  final String workOrderTypeId;
  final String? externalOrderId;
  final PpWorkOrderStatus status;
  final String? assignedTo;
  final String? assignedAt;
  final String? startedAt;
  final String? completedAt;
  final String? submittedAt;
  final String? dueDate;
  final double? bidAmount;
  final double? approvedAmount;
  final PhotoMode photoMode;
  final Map<String, dynamic> checklistProgress;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpWorkOrder({
    required this.id,
    required this.companyId,
    this.propertyId,
    this.jobId,
    this.nationalCompanyId,
    required this.workOrderTypeId,
    this.externalOrderId,
    required this.status,
    this.assignedTo,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.submittedAt,
    this.dueDate,
    this.bidAmount,
    this.approvedAmount,
    this.photoMode = PhotoMode.standard,
    this.checklistProgress = const {},
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpWorkOrder.fromJson(Map<String, dynamic> json) {
    return PpWorkOrder(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      propertyId: json['property_id'] as String?,
      jobId: json['job_id'] as String?,
      nationalCompanyId: json['national_company_id'] as String?,
      workOrderTypeId: json['work_order_type_id'] as String,
      externalOrderId: json['external_order_id'] as String?,
      status: PpWorkOrderStatus.fromJson(json['status'] as String),
      assignedTo: json['assigned_to'] as String?,
      assignedAt: json['assigned_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      submittedAt: json['submitted_at'] as String?,
      dueDate: json['due_date'] as String?,
      bidAmount: _parseDouble(json['bid_amount']),
      approvedAmount: _parseDouble(json['approved_amount']),
      photoMode: PhotoMode.fromJson(json['photo_mode'] as String? ?? 'standard'),
      checklistProgress: json['checklist_progress'] != null
          ? Map<String, dynamic>.from(json['checklist_progress'] as Map)
          : const {},
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        'job_id': jobId,
        'national_company_id': nationalCompanyId,
        'work_order_type_id': workOrderTypeId,
        'external_order_id': externalOrderId,
        'status': status.toJson(),
        'assigned_to': assignedTo,
        'due_date': dueDate,
        'bid_amount': bidAmount,
        'photo_mode': photoMode.toJson(),
        'notes': notes,
      };

  bool get isOverdue =>
      dueDate != null &&
      DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) == true &&
      status != PpWorkOrderStatus.completed &&
      status != PpWorkOrderStatus.approved;

  @override
  List<Object?> get props => [id, companyId, workOrderTypeId, status, updatedAt];
}

// ════════════════════════════════════════════════════════════════
// PP CHARGEBACK
// ════════════════════════════════════════════════════════════════

class PpChargeback extends Equatable {
  final String id;
  final String companyId;
  final String? workOrderId;
  final String? nationalCompanyId;
  final String? propertyAddress;
  final double amount;
  final String reason;
  final String chargebackDate;
  final DisputeStatus disputeStatus;
  final String? disputeSubmittedAt;
  final String? disputeResolvedAt;
  final String? evidenceNotes;
  final String createdAt;
  final String updatedAt;

  const PpChargeback({
    required this.id,
    required this.companyId,
    this.workOrderId,
    this.nationalCompanyId,
    this.propertyAddress,
    required this.amount,
    required this.reason,
    required this.chargebackDate,
    required this.disputeStatus,
    this.disputeSubmittedAt,
    this.disputeResolvedAt,
    this.evidenceNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpChargeback.fromJson(Map<String, dynamic> json) {
    return PpChargeback(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      workOrderId: json['work_order_id'] as String?,
      nationalCompanyId: json['national_company_id'] as String?,
      propertyAddress: json['property_address'] as String?,
      amount: _parseDouble(json['amount']) ?? 0,
      reason: json['reason'] as String,
      chargebackDate: json['chargeback_date'] as String,
      disputeStatus: DisputeStatus.fromJson(json['dispute_status'] as String? ?? 'none'),
      disputeSubmittedAt: json['dispute_submitted_at'] as String?,
      disputeResolvedAt: json['dispute_resolved_at'] as String?,
      evidenceNotes: json['evidence_notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'work_order_id': workOrderId,
        'national_company_id': nationalCompanyId,
        'property_address': propertyAddress,
        'amount': amount,
        'reason': reason,
        'chargeback_date': chargebackDate,
        'dispute_status': disputeStatus.toJson(),
        'evidence_notes': evidenceNotes,
      };

  @override
  List<Object?> get props => [id, companyId, amount, chargebackDate];
}

// ════════════════════════════════════════════════════════════════
// PP WINTERIZATION RECORD
// ════════════════════════════════════════════════════════════════

class PpWinterizationRecord extends Equatable {
  final String id;
  final String companyId;
  final String? workOrderId;
  final String? propertyId;
  final String recordType; // 'winterization' or 'dewinterization'
  final HeatType heatType;
  final bool hasWell;
  final bool hasSeptic;
  final bool hasSprinkler;
  final double? pressureTestStartPsi;
  final double? pressureTestEndPsi;
  final int pressureTestDurationMin;
  final bool? pressureTestPassed;
  final double? antifreezeGallons;
  final int? fixtureCount;
  final Map<String, dynamic> checklistData;
  final String? completedBy;
  final String? completedAt;
  final String? certificateUrl;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpWinterizationRecord({
    required this.id,
    required this.companyId,
    this.workOrderId,
    this.propertyId,
    required this.recordType,
    required this.heatType,
    this.hasWell = false,
    this.hasSeptic = false,
    this.hasSprinkler = false,
    this.pressureTestStartPsi,
    this.pressureTestEndPsi,
    this.pressureTestDurationMin = 30,
    this.pressureTestPassed,
    this.antifreezeGallons,
    this.fixtureCount,
    this.checklistData = const {},
    this.completedBy,
    this.completedAt,
    this.certificateUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpWinterizationRecord.fromJson(Map<String, dynamic> json) {
    return PpWinterizationRecord(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      workOrderId: json['work_order_id'] as String?,
      propertyId: json['property_id'] as String?,
      recordType: json['record_type'] as String,
      heatType: HeatType.fromJson(json['heat_type'] as String?),
      hasWell: json['has_well'] as bool? ?? false,
      hasSeptic: json['has_septic'] as bool? ?? false,
      hasSprinkler: json['has_sprinkler'] as bool? ?? false,
      pressureTestStartPsi: _parseDouble(json['pressure_test_start_psi']),
      pressureTestEndPsi: _parseDouble(json['pressure_test_end_psi']),
      pressureTestDurationMin: json['pressure_test_duration_min'] as int? ?? 30,
      pressureTestPassed: json['pressure_test_passed'] as bool?,
      antifreezeGallons: _parseDouble(json['antifreeze_gallons']),
      fixtureCount: json['fixture_count'] as int?,
      checklistData: json['checklist_data'] != null
          ? Map<String, dynamic>.from(json['checklist_data'] as Map)
          : const {},
      completedBy: json['completed_by'] as String?,
      completedAt: json['completed_at'] as String?,
      certificateUrl: json['certificate_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'work_order_id': workOrderId,
        'property_id': propertyId,
        'record_type': recordType,
        'heat_type': heatType.toJson(),
        'has_well': hasWell,
        'has_septic': hasSeptic,
        'has_sprinkler': hasSprinkler,
        'pressure_test_start_psi': pressureTestStartPsi,
        'pressure_test_end_psi': pressureTestEndPsi,
        'pressure_test_duration_min': pressureTestDurationMin,
        'pressure_test_passed': pressureTestPassed,
        'antifreeze_gallons': antifreezeGallons,
        'fixture_count': fixtureCount,
        'checklist_data': checklistData,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, companyId, recordType, propertyId];
}

// ════════════════════════════════════════════════════════════════
// PP DEBRIS ESTIMATE
// ════════════════════════════════════════════════════════════════

class PpDebrisEstimate extends Equatable {
  final String id;
  final String companyId;
  final String? workOrderId;
  final String? propertyId;
  final String estimationMethod;
  final List<dynamic> roomsData;
  final int? propertySqft;
  final CleanoutLevel? cleanoutLevel;
  final int? hoardingLevel;
  final double? totalCubicYards;
  final double? estimatedWeightLbs;
  final int? recommendedDumpsterSize;
  final int dumpsterPulls;
  final double? hudRatePerCy;
  final double? estimatedRevenue;
  final double? estimatedCost;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpDebrisEstimate({
    required this.id,
    required this.companyId,
    this.workOrderId,
    this.propertyId,
    required this.estimationMethod,
    this.roomsData = const [],
    this.propertySqft,
    this.cleanoutLevel,
    this.hoardingLevel,
    this.totalCubicYards,
    this.estimatedWeightLbs,
    this.recommendedDumpsterSize,
    this.dumpsterPulls = 1,
    this.hudRatePerCy,
    this.estimatedRevenue,
    this.estimatedCost,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpDebrisEstimate.fromJson(Map<String, dynamic> json) {
    return PpDebrisEstimate(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      workOrderId: json['work_order_id'] as String?,
      propertyId: json['property_id'] as String?,
      estimationMethod: json['estimation_method'] as String,
      roomsData: json['rooms_data'] as List<dynamic>? ?? const [],
      propertySqft: json['property_sqft'] as int?,
      cleanoutLevel: json['cleanout_level'] != null
          ? CleanoutLevel.fromJson(json['cleanout_level'] as String)
          : null,
      hoardingLevel: json['hoarding_level'] as int?,
      totalCubicYards: _parseDouble(json['total_cubic_yards']),
      estimatedWeightLbs: _parseDouble(json['estimated_weight_lbs']),
      recommendedDumpsterSize: json['recommended_dumpster_size'] as int?,
      dumpsterPulls: json['dumpster_pulls'] as int? ?? 1,
      hudRatePerCy: _parseDouble(json['hud_rate_per_cy']),
      estimatedRevenue: _parseDouble(json['estimated_revenue']),
      estimatedCost: _parseDouble(json['estimated_cost']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'work_order_id': workOrderId,
        'property_id': propertyId,
        'estimation_method': estimationMethod,
        'rooms_data': roomsData,
        'property_sqft': propertySqft,
        'cleanout_level': cleanoutLevel?.toJson(),
        'hoarding_level': hoardingLevel,
        'total_cubic_yards': totalCubicYards,
        'estimated_weight_lbs': estimatedWeightLbs,
        'recommended_dumpster_size': recommendedDumpsterSize,
        'dumpster_pulls': dumpsterPulls,
        'hud_rate_per_cy': hudRatePerCy,
        'estimated_revenue': estimatedRevenue,
        'estimated_cost': estimatedCost,
        'notes': notes,
      };

  double? get margin =>
      estimatedRevenue != null && estimatedCost != null
          ? estimatedRevenue! - estimatedCost!
          : null;

  @override
  List<Object?> get props => [id, companyId, estimationMethod, totalCubicYards];
}

// ════════════════════════════════════════════════════════════════
// PP UTILITY TRACKING
// ════════════════════════════════════════════════════════════════

class PpUtilityTracking extends Equatable {
  final String id;
  final String companyId;
  final String? propertyId;
  final UtilityType utilityType;
  final UtilityStatus status;
  final String? providerName;
  final String? accountNumber;
  final String? contactPhone;
  final String? lastChecked;
  final String? nextAction;
  final String? nextActionDate;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpUtilityTracking({
    required this.id,
    required this.companyId,
    this.propertyId,
    required this.utilityType,
    required this.status,
    this.providerName,
    this.accountNumber,
    this.contactPhone,
    this.lastChecked,
    this.nextAction,
    this.nextActionDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpUtilityTracking.fromJson(Map<String, dynamic> json) {
    return PpUtilityTracking(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      propertyId: json['property_id'] as String?,
      utilityType: UtilityType.fromJson(json['utility_type'] as String),
      status: UtilityStatus.fromJson(json['status'] as String),
      providerName: json['provider_name'] as String?,
      accountNumber: json['account_number'] as String?,
      contactPhone: json['contact_phone'] as String?,
      lastChecked: json['last_checked'] as String?,
      nextAction: json['next_action'] as String?,
      nextActionDate: json['next_action_date'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        'utility_type': utilityType.toJson(),
        'status': status.toJson(),
        'provider_name': providerName,
        'account_number': accountNumber,
        'contact_phone': contactPhone,
        'next_action': nextAction,
        'next_action_date': nextActionDate,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, companyId, propertyId, utilityType, status];
}

// ════════════════════════════════════════════════════════════════
// PP VENDOR APPLICATION
// ════════════════════════════════════════════════════════════════

class PpVendorApplication extends Equatable {
  final String id;
  final String companyId;
  final String nationalCompanyId;
  final String status;
  final String? appliedAt;
  final String? approvedAt;
  final String? rejectedAt;
  final Map<String, dynamic> checklist;
  final String? portalUsername;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpVendorApplication({
    required this.id,
    required this.companyId,
    required this.nationalCompanyId,
    required this.status,
    this.appliedAt,
    this.approvedAt,
    this.rejectedAt,
    this.checklist = const {},
    this.portalUsername,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpVendorApplication.fromJson(Map<String, dynamic> json) {
    return PpVendorApplication(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      nationalCompanyId: json['national_company_id'] as String,
      status: json['status'] as String,
      appliedAt: json['applied_at'] as String?,
      approvedAt: json['approved_at'] as String?,
      rejectedAt: json['rejected_at'] as String?,
      checklist: json['checklist'] != null
          ? Map<String, dynamic>.from(json['checklist'] as Map)
          : const {},
      portalUsername: json['portal_username'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'national_company_id': nationalCompanyId,
        'status': status,
        'checklist': checklist,
        'portal_username': portalUsername,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, companyId, nationalCompanyId, status];
}

// ════════════════════════════════════════════════════════════════
// BOILER/FURNACE MODEL
// ════════════════════════════════════════════════════════════════

class BoilerFurnaceModel extends Equatable {
  final String id;
  final String manufacturer;
  final String modelName;
  final String? modelNumber;
  final EquipmentType equipmentType;
  final String? fuelType;
  final List<dynamic> commonIssues;
  final Map<String, dynamic> errorCodes;
  final String? winterizationNotes;
  final Map<String, dynamic> serialDecoder;
  final List<dynamic> partsCommonlyNeeded;
  final int? approximateLifespanYears;
  final bool isDiscontinued;

  const BoilerFurnaceModel({
    required this.id,
    required this.manufacturer,
    required this.modelName,
    this.modelNumber,
    required this.equipmentType,
    this.fuelType,
    this.commonIssues = const [],
    this.errorCodes = const {},
    this.winterizationNotes,
    this.serialDecoder = const {},
    this.partsCommonlyNeeded = const [],
    this.approximateLifespanYears,
    this.isDiscontinued = false,
  });

  factory BoilerFurnaceModel.fromJson(Map<String, dynamic> json) {
    return BoilerFurnaceModel(
      id: json['id'] as String,
      manufacturer: json['manufacturer'] as String,
      modelName: json['model_name'] as String,
      modelNumber: json['model_number'] as String?,
      equipmentType: EquipmentType.fromJson(json['equipment_type'] as String),
      fuelType: json['fuel_type'] as String?,
      commonIssues: json['common_issues'] as List<dynamic>? ?? const [],
      errorCodes: json['error_codes'] != null
          ? Map<String, dynamic>.from(json['error_codes'] as Map)
          : const {},
      winterizationNotes: json['winterization_notes'] as String?,
      serialDecoder: json['serial_decoder'] != null
          ? Map<String, dynamic>.from(json['serial_decoder'] as Map)
          : const {},
      partsCommonlyNeeded: json['parts_commonly_needed'] as List<dynamic>? ?? const [],
      approximateLifespanYears: json['approximate_lifespan_years'] as int?,
      isDiscontinued: json['is_discontinued'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, manufacturer, modelName, equipmentType];
}

// ════════════════════════════════════════════════════════════════
// PP PRICING MATRIX
// ════════════════════════════════════════════════════════════════

class PpPricingMatrix extends Equatable {
  final String id;
  final String stateCode;
  final String workOrderType;
  final String pricingSource;
  final double rate;
  final String rateUnit;
  final String? conditions;
  final String effectiveDate;

  const PpPricingMatrix({
    required this.id,
    required this.stateCode,
    required this.workOrderType,
    required this.pricingSource,
    required this.rate,
    required this.rateUnit,
    this.conditions,
    required this.effectiveDate,
  });

  factory PpPricingMatrix.fromJson(Map<String, dynamic> json) {
    return PpPricingMatrix(
      id: json['id'] as String,
      stateCode: json['state_code'] as String,
      workOrderType: json['work_order_type'] as String,
      pricingSource: json['pricing_source'] as String,
      rate: _parseDouble(json['rate']) ?? 0,
      rateUnit: json['rate_unit'] as String? ?? 'flat',
      conditions: json['conditions'] as String?,
      effectiveDate: json['effective_date'] as String,
    );
  }

  @override
  List<Object?> get props => [id, stateCode, workOrderType, pricingSource];
}

// ════════════════════════════════════════════════════════════════
// PP STRIPPED PROPERTY ESTIMATE
// ════════════════════════════════════════════════════════════════

class PpStrippedEstimate extends Equatable {
  final String id;
  final String companyId;
  final String? workOrderId;
  final String? propertyId;
  final StrippedEstimateType estimateType;
  final Map<String, dynamic> inputData;
  final List<dynamic> materialsList;
  final double? materialCost;
  final double? laborHours;
  final double? laborCost;
  final double? totalEstimate;
  final double? hudAllowable;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const PpStrippedEstimate({
    required this.id,
    required this.companyId,
    this.workOrderId,
    this.propertyId,
    required this.estimateType,
    this.inputData = const {},
    this.materialsList = const [],
    this.materialCost,
    this.laborHours,
    this.laborCost,
    this.totalEstimate,
    this.hudAllowable,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PpStrippedEstimate.fromJson(Map<String, dynamic> json) {
    return PpStrippedEstimate(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      workOrderId: json['work_order_id'] as String?,
      propertyId: json['property_id'] as String?,
      estimateType: StrippedEstimateType.fromJson(json['estimate_type'] as String),
      inputData: json['input_data'] != null
          ? Map<String, dynamic>.from(json['input_data'] as Map)
          : const {},
      materialsList: json['materials_list'] as List<dynamic>? ?? const [],
      materialCost: _parseDouble(json['material_cost']),
      laborHours: _parseDouble(json['labor_hours']),
      laborCost: _parseDouble(json['labor_cost']),
      totalEstimate: _parseDouble(json['total_estimate']),
      hudAllowable: _parseDouble(json['hud_allowable']),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'work_order_id': workOrderId,
        'property_id': propertyId,
        'estimate_type': estimateType.toJson(),
        'input_data': inputData,
        'materials_list': materialsList,
        'material_cost': materialCost,
        'labor_hours': laborHours,
        'labor_cost': laborCost,
        'total_estimate': totalEstimate,
        'hud_allowable': hudAllowable,
        'notes': notes,
      };

  double? get margin =>
      totalEstimate != null && hudAllowable != null
          ? hudAllowable! - totalEstimate!
          : null;

  @override
  List<Object?> get props => [id, companyId, estimateType];
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
