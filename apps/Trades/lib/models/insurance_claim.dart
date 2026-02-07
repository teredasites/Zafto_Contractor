// ZAFTO Insurance Claim Model — Supabase Backend
// Maps to `insurance_claims` table. Linked to jobs with type='insurance_claim'.

enum ClaimStatus {
  newClaim,
  scopeRequested,
  scopeSubmitted,
  estimatePending,
  estimateApproved,
  supplementSubmitted,
  supplementApproved,
  workInProgress,
  workComplete,
  finalInspection,
  settled,
  closed,
  denied;

  String get dbValue {
    switch (this) {
      case ClaimStatus.newClaim:
        return 'new';
      case ClaimStatus.scopeRequested:
        return 'scope_requested';
      case ClaimStatus.scopeSubmitted:
        return 'scope_submitted';
      case ClaimStatus.estimatePending:
        return 'estimate_pending';
      case ClaimStatus.estimateApproved:
        return 'estimate_approved';
      case ClaimStatus.supplementSubmitted:
        return 'supplement_submitted';
      case ClaimStatus.supplementApproved:
        return 'supplement_approved';
      case ClaimStatus.workInProgress:
        return 'work_in_progress';
      case ClaimStatus.workComplete:
        return 'work_complete';
      case ClaimStatus.finalInspection:
        return 'final_inspection';
      case ClaimStatus.settled:
        return 'settled';
      case ClaimStatus.closed:
        return 'closed';
      case ClaimStatus.denied:
        return 'denied';
    }
  }

  String get label {
    switch (this) {
      case ClaimStatus.newClaim:
        return 'New';
      case ClaimStatus.scopeRequested:
        return 'Scope Requested';
      case ClaimStatus.scopeSubmitted:
        return 'Scope Submitted';
      case ClaimStatus.estimatePending:
        return 'Estimate Pending';
      case ClaimStatus.estimateApproved:
        return 'Estimate Approved';
      case ClaimStatus.supplementSubmitted:
        return 'Supplement Submitted';
      case ClaimStatus.supplementApproved:
        return 'Supplement Approved';
      case ClaimStatus.workInProgress:
        return 'Work In Progress';
      case ClaimStatus.workComplete:
        return 'Work Complete';
      case ClaimStatus.finalInspection:
        return 'Final Inspection';
      case ClaimStatus.settled:
        return 'Settled';
      case ClaimStatus.closed:
        return 'Closed';
      case ClaimStatus.denied:
        return 'Denied';
    }
  }

  static ClaimStatus fromString(String? value) {
    if (value == null) return ClaimStatus.newClaim;
    switch (value) {
      case 'new':
        return ClaimStatus.newClaim;
      case 'scope_requested':
        return ClaimStatus.scopeRequested;
      case 'scope_submitted':
        return ClaimStatus.scopeSubmitted;
      case 'estimate_pending':
        return ClaimStatus.estimatePending;
      case 'estimate_approved':
        return ClaimStatus.estimateApproved;
      case 'supplement_submitted':
        return ClaimStatus.supplementSubmitted;
      case 'supplement_approved':
        return ClaimStatus.supplementApproved;
      case 'work_in_progress':
        return ClaimStatus.workInProgress;
      case 'work_complete':
        return ClaimStatus.workComplete;
      case 'final_inspection':
        return ClaimStatus.finalInspection;
      case 'settled':
        return ClaimStatus.settled;
      case 'closed':
        return ClaimStatus.closed;
      case 'denied':
        return ClaimStatus.denied;
      default:
        return ClaimStatus.newClaim;
    }
  }
}

enum LossType {
  fire,
  water,
  storm,
  wind,
  hail,
  theft,
  vandalism,
  mold,
  flood,
  earthquake,
  other,
  unknown;

  String get dbValue => name;

  String get label {
    switch (this) {
      case LossType.fire:
        return 'Fire';
      case LossType.water:
        return 'Water';
      case LossType.storm:
        return 'Storm';
      case LossType.wind:
        return 'Wind';
      case LossType.hail:
        return 'Hail';
      case LossType.theft:
        return 'Theft';
      case LossType.vandalism:
        return 'Vandalism';
      case LossType.mold:
        return 'Mold';
      case LossType.flood:
        return 'Flood';
      case LossType.earthquake:
        return 'Earthquake';
      case LossType.other:
        return 'Other';
      case LossType.unknown:
        return 'Unknown';
    }
  }

  static LossType fromString(String? value) {
    if (value == null) return LossType.unknown;
    return LossType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => LossType.unknown,
    );
  }
}

enum ClaimCategory {
  restoration,
  storm,
  reconstruction,
  commercial;

  String get dbValue => name;

  String get label {
    switch (this) {
      case ClaimCategory.restoration:
        return 'Restoration';
      case ClaimCategory.storm:
        return 'Storm/Weather';
      case ClaimCategory.reconstruction:
        return 'Reconstruction';
      case ClaimCategory.commercial:
        return 'Commercial';
    }
  }

  String get description {
    switch (this) {
      case ClaimCategory.restoration:
        return 'Water, mold, fire mitigation';
      case ClaimCategory.storm:
        return 'Wind, hail, flood, storm damage';
      case ClaimCategory.reconstruction:
        return 'Full structure rebuild';
      case ClaimCategory.commercial:
        return 'Business property claims';
    }
  }

  static ClaimCategory fromString(String? value) {
    if (value == null) return ClaimCategory.restoration;
    return ClaimCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ClaimCategory.restoration,
    );
  }
}

// Typed JSONB data for Storm/Weather vertical
class StormData {
  final DateTime? weatherEventDate;
  final String stormSeverity; // minor, moderate, severe, catastrophic
  final bool aerialAssessmentNeeded;
  final String? batchEventId;
  final bool emergencyTarped;
  final String? temporaryRepairs;
  final String? weatherEventType; // hurricane, tornado, hailstorm, thunderstorm, ice_storm, flood
  final int? affectedUnits;

  const StormData({
    this.weatherEventDate,
    this.stormSeverity = 'moderate',
    this.aerialAssessmentNeeded = false,
    this.batchEventId,
    this.emergencyTarped = false,
    this.temporaryRepairs,
    this.weatherEventType,
    this.affectedUnits,
  });

  factory StormData.fromJson(Map<String, dynamic> json) => StormData(
        weatherEventDate: json['weatherEventDate'] != null
            ? DateTime.tryParse(json['weatherEventDate'].toString())
            : null,
        stormSeverity: json['stormSeverity'] as String? ?? 'moderate',
        aerialAssessmentNeeded:
            json['aerialAssessmentNeeded'] as bool? ?? false,
        batchEventId: json['batchEventId'] as String?,
        emergencyTarped: json['emergencyTarped'] as bool? ?? false,
        temporaryRepairs: json['temporaryRepairs'] as String?,
        weatherEventType: json['weatherEventType'] as String?,
        affectedUnits: json['affectedUnits'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (weatherEventDate != null)
          'weatherEventDate': weatherEventDate!.toIso8601String(),
        'stormSeverity': stormSeverity,
        'aerialAssessmentNeeded': aerialAssessmentNeeded,
        if (batchEventId != null) 'batchEventId': batchEventId,
        'emergencyTarped': emergencyTarped,
        if (temporaryRepairs != null) 'temporaryRepairs': temporaryRepairs,
        if (weatherEventType != null) 'weatherEventType': weatherEventType,
        if (affectedUnits != null) 'affectedUnits': affectedUnits,
      };
}

// Typed JSONB data for Reconstruction vertical
class ReconstructionData {
  final String currentPhase; // scope_review, selections, materials, demo, rough_in, inspection, finish, walkthrough, supplements, payment
  final List<ReconstructionPhase> phases;
  final bool multiContractor;
  final int? expectedDurationMonths;
  final bool permitsRequired;
  final String? permitStatus; // not_applied, pending, approved, denied

  const ReconstructionData({
    this.currentPhase = 'scope_review',
    this.phases = const [],
    this.multiContractor = false,
    this.expectedDurationMonths,
    this.permitsRequired = false,
    this.permitStatus,
  });

  factory ReconstructionData.fromJson(Map<String, dynamic> json) =>
      ReconstructionData(
        currentPhase: json['currentPhase'] as String? ?? 'scope_review',
        phases: (json['phases'] as List<dynamic>?)
                ?.map((e) =>
                    ReconstructionPhase.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        multiContractor: json['multiContractor'] as bool? ?? false,
        expectedDurationMonths: json['expectedDurationMonths'] as int?,
        permitsRequired: json['permitsRequired'] as bool? ?? false,
        permitStatus: json['permitStatus'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'currentPhase': currentPhase,
        'phases': phases.map((p) => p.toJson()).toList(),
        'multiContractor': multiContractor,
        if (expectedDurationMonths != null)
          'expectedDurationMonths': expectedDurationMonths,
        'permitsRequired': permitsRequired,
        if (permitStatus != null) 'permitStatus': permitStatus,
      };
}

class ReconstructionPhase {
  final String name;
  final String status; // pending, in_progress, complete
  final double? budgetAmount;
  final double? completionPercent;

  const ReconstructionPhase({
    required this.name,
    this.status = 'pending',
    this.budgetAmount,
    this.completionPercent,
  });

  factory ReconstructionPhase.fromJson(Map<String, dynamic> json) =>
      ReconstructionPhase(
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
        completionPercent: (json['completionPercent'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
        if (budgetAmount != null) 'budgetAmount': budgetAmount,
        if (completionPercent != null) 'completionPercent': completionPercent,
      };
}

// Typed JSONB data for Commercial vertical
class CommercialData {
  final String? propertyType; // office, retail, warehouse, restaurant, industrial, multi_unit, hotel, other
  final String? businessName;
  final String? tenantName;
  final String? tenantContact;
  final double? businessIncomeLoss;
  final int? businessInterruptionDays;
  final double? emergencyAuthAmount;
  final bool emergencyServiceAuthorized;

  const CommercialData({
    this.propertyType,
    this.businessName,
    this.tenantName,
    this.tenantContact,
    this.businessIncomeLoss,
    this.businessInterruptionDays,
    this.emergencyAuthAmount,
    this.emergencyServiceAuthorized = false,
  });

  factory CommercialData.fromJson(Map<String, dynamic> json) => CommercialData(
        propertyType: json['propertyType'] as String?,
        businessName: json['businessName'] as String?,
        tenantName: json['tenantName'] as String?,
        tenantContact: json['tenantContact'] as String?,
        businessIncomeLoss:
            (json['businessIncomeLoss'] as num?)?.toDouble(),
        businessInterruptionDays: json['businessInterruptionDays'] as int?,
        emergencyAuthAmount:
            (json['emergencyAuthAmount'] as num?)?.toDouble(),
        emergencyServiceAuthorized:
            json['emergencyServiceAuthorized'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (propertyType != null) 'propertyType': propertyType,
        if (businessName != null) 'businessName': businessName,
        if (tenantName != null) 'tenantName': tenantName,
        if (tenantContact != null) 'tenantContact': tenantContact,
        if (businessIncomeLoss != null) 'businessIncomeLoss': businessIncomeLoss,
        if (businessInterruptionDays != null)
          'businessInterruptionDays': businessInterruptionDays,
        if (emergencyAuthAmount != null)
          'emergencyAuthAmount': emergencyAuthAmount,
        'emergencyServiceAuthorized': emergencyServiceAuthorized,
      };
}

class InsuranceClaim {
  final String id;
  final String companyId;
  final String jobId;
  final String insuranceCompany;
  final String claimNumber;
  final String? policyNumber;
  final DateTime dateOfLoss;
  final LossType lossType;
  final String? lossDescription;
  final String? adjusterName;
  final String? adjusterPhone;
  final String? adjusterEmail;
  final String? adjusterCompany;
  final double deductible;
  final double? coverageLimit;
  final double? approvedAmount;
  final double supplementTotal;
  final double depreciation;
  final double? acv;
  final double? rcv;
  final ClaimStatus claimStatus;
  final DateTime? scopeSubmittedAt;
  final DateTime? estimateApprovedAt;
  final DateTime? workStartedAt;
  final DateTime? workCompletedAt;
  final DateTime? settledAt;
  final String? xactimateClaimId;
  final String? xactimateFileUrl;
  final bool depreciationRecovered;
  final double amountCollected;
  final ClaimCategory claimCategory;
  final String? notes;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const InsuranceClaim({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    required this.insuranceCompany,
    required this.claimNumber,
    this.policyNumber,
    required this.dateOfLoss,
    this.lossType = LossType.unknown,
    this.lossDescription,
    this.adjusterName,
    this.adjusterPhone,
    this.adjusterEmail,
    this.adjusterCompany,
    this.deductible = 0,
    this.coverageLimit,
    this.approvedAmount,
    this.supplementTotal = 0,
    this.depreciation = 0,
    this.acv,
    this.rcv,
    this.depreciationRecovered = false,
    this.amountCollected = 0,
    this.claimStatus = ClaimStatus.newClaim,
    this.claimCategory = ClaimCategory.restoration,
    this.scopeSubmittedAt,
    this.estimateApprovedAt,
    this.workStartedAt,
    this.workCompletedAt,
    this.settledAt,
    this.xactimateClaimId,
    this.xactimateFileUrl,
    this.notes,
    this.data = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'insurance_company': insuranceCompany,
        'claim_number': claimNumber,
        if (policyNumber != null) 'policy_number': policyNumber,
        'date_of_loss': dateOfLoss.toIso8601String().split('T').first,
        'loss_type': lossType.dbValue,
        if (lossDescription != null) 'loss_description': lossDescription,
        if (adjusterName != null) 'adjuster_name': adjusterName,
        if (adjusterPhone != null) 'adjuster_phone': adjusterPhone,
        if (adjusterEmail != null) 'adjuster_email': adjusterEmail,
        if (adjusterCompany != null) 'adjuster_company': adjusterCompany,
        'deductible': deductible,
        if (coverageLimit != null) 'coverage_limit': coverageLimit,
        if (approvedAmount != null) 'approved_amount': approvedAmount,
        'claim_status': claimStatus.dbValue,
        'claim_category': claimCategory.dbValue,
        if (notes != null) 'notes': notes,
        'data': data,
      };

  Map<String, dynamic> toUpdateJson() => {
        'insurance_company': insuranceCompany,
        'claim_number': claimNumber,
        'policy_number': policyNumber,
        'date_of_loss': dateOfLoss.toIso8601String().split('T').first,
        'loss_type': lossType.dbValue,
        'loss_description': lossDescription,
        'adjuster_name': adjusterName,
        'adjuster_phone': adjusterPhone,
        'adjuster_email': adjusterEmail,
        'adjuster_company': adjusterCompany,
        'deductible': deductible,
        'coverage_limit': coverageLimit,
        'approved_amount': approvedAmount,
        'supplement_total': supplementTotal,
        'depreciation': depreciation,
        'acv': acv,
        'rcv': rcv,
        'depreciation_recovered': depreciationRecovered,
        'amount_collected': amountCollected,
        'claim_status': claimStatus.dbValue,
        'claim_category': claimCategory.dbValue,
        if (scopeSubmittedAt != null)
          'scope_submitted_at': scopeSubmittedAt!.toUtc().toIso8601String(),
        if (estimateApprovedAt != null)
          'estimate_approved_at':
              estimateApprovedAt!.toUtc().toIso8601String(),
        if (workStartedAt != null)
          'work_started_at': workStartedAt!.toUtc().toIso8601String(),
        if (workCompletedAt != null)
          'work_completed_at': workCompletedAt!.toUtc().toIso8601String(),
        if (settledAt != null)
          'settled_at': settledAt!.toUtc().toIso8601String(),
        'xactimate_claim_id': xactimateClaimId,
        'xactimate_file_url': xactimateFileUrl,
        'notes': notes,
        'data': data,
      };

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      insuranceCompany: json['insurance_company'] as String? ?? '',
      claimNumber: json['claim_number'] as String? ?? '',
      policyNumber: json['policy_number'] as String?,
      dateOfLoss: _parseDate(json['date_of_loss']),
      lossType: LossType.fromString(json['loss_type'] as String?),
      lossDescription: json['loss_description'] as String?,
      adjusterName: json['adjuster_name'] as String?,
      adjusterPhone: json['adjuster_phone'] as String?,
      adjusterEmail: json['adjuster_email'] as String?,
      adjusterCompany: json['adjuster_company'] as String?,
      deductible: (json['deductible'] as num?)?.toDouble() ?? 0,
      coverageLimit: (json['coverage_limit'] as num?)?.toDouble(),
      approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
      supplementTotal: (json['supplement_total'] as num?)?.toDouble() ?? 0,
      depreciation: (json['depreciation'] as num?)?.toDouble() ?? 0,
      acv: (json['acv'] as num?)?.toDouble(),
      rcv: (json['rcv'] as num?)?.toDouble(),
      depreciationRecovered: json['depreciation_recovered'] as bool? ?? false,
      amountCollected: (json['amount_collected'] as num?)?.toDouble() ?? 0,
      claimStatus: ClaimStatus.fromString(json['claim_status'] as String?),
      claimCategory: ClaimCategory.fromString(json['claim_category'] as String?),
      scopeSubmittedAt: _parseOptionalDate(json['scope_submitted_at']),
      estimateApprovedAt: _parseOptionalDate(json['estimate_approved_at']),
      workStartedAt: _parseOptionalDate(json['work_started_at']),
      workCompletedAt: _parseOptionalDate(json['work_completed_at']),
      settledAt: _parseOptionalDate(json['settled_at']),
      xactimateClaimId: json['xactimate_claim_id'] as String?,
      xactimateFileUrl: json['xactimate_file_url'] as String?,
      notes: json['notes'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseOptionalDate(json['deleted_at']),
    );
  }

  InsuranceClaim copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? insuranceCompany,
    String? claimNumber,
    String? policyNumber,
    DateTime? dateOfLoss,
    LossType? lossType,
    String? lossDescription,
    String? adjusterName,
    String? adjusterPhone,
    String? adjusterEmail,
    String? adjusterCompany,
    double? deductible,
    double? coverageLimit,
    double? approvedAmount,
    double? supplementTotal,
    double? depreciation,
    double? acv,
    double? rcv,
    bool? depreciationRecovered,
    double? amountCollected,
    ClaimStatus? claimStatus,
    ClaimCategory? claimCategory,
    DateTime? scopeSubmittedAt,
    DateTime? estimateApprovedAt,
    DateTime? workStartedAt,
    DateTime? workCompletedAt,
    DateTime? settledAt,
    String? xactimateClaimId,
    String? xactimateFileUrl,
    String? notes,
    Map<String, dynamic>? data,
  }) {
    return InsuranceClaim(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      claimNumber: claimNumber ?? this.claimNumber,
      policyNumber: policyNumber ?? this.policyNumber,
      dateOfLoss: dateOfLoss ?? this.dateOfLoss,
      lossType: lossType ?? this.lossType,
      lossDescription: lossDescription ?? this.lossDescription,
      adjusterName: adjusterName ?? this.adjusterName,
      adjusterPhone: adjusterPhone ?? this.adjusterPhone,
      adjusterEmail: adjusterEmail ?? this.adjusterEmail,
      adjusterCompany: adjusterCompany ?? this.adjusterCompany,
      deductible: deductible ?? this.deductible,
      coverageLimit: coverageLimit ?? this.coverageLimit,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      supplementTotal: supplementTotal ?? this.supplementTotal,
      depreciation: depreciation ?? this.depreciation,
      acv: acv ?? this.acv,
      rcv: rcv ?? this.rcv,
      depreciationRecovered: depreciationRecovered ?? this.depreciationRecovered,
      amountCollected: amountCollected ?? this.amountCollected,
      claimStatus: claimStatus ?? this.claimStatus,
      claimCategory: claimCategory ?? this.claimCategory,
      scopeSubmittedAt: scopeSubmittedAt ?? this.scopeSubmittedAt,
      estimateApprovedAt: estimateApprovedAt ?? this.estimateApprovedAt,
      workStartedAt: workStartedAt ?? this.workStartedAt,
      workCompletedAt: workCompletedAt ?? this.workCompletedAt,
      settledAt: settledAt ?? this.settledAt,
      xactimateClaimId: xactimateClaimId ?? this.xactimateClaimId,
      xactimateFileUrl: xactimateFileUrl ?? this.xactimateFileUrl,
      notes: notes ?? this.notes,
      data: data ?? this.data,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Typed JSONB data accessors by category
  StormData get stormData => StormData.fromJson(data);
  ReconstructionData get reconstructionData =>
      ReconstructionData.fromJson(data);
  CommercialData get commercialData => CommercialData.fromJson(data);

  // Computed properties
  bool get isActive =>
      claimStatus != ClaimStatus.closed &&
      claimStatus != ClaimStatus.denied &&
      claimStatus != ClaimStatus.settled;
  bool get isDenied => claimStatus == ClaimStatus.denied;
  bool get isSettled => claimStatus == ClaimStatus.settled;
  bool get hasAdjuster => adjusterName != null && adjusterName!.isNotEmpty;
  bool get hasXactimate =>
      xactimateClaimId != null && xactimateClaimId!.isNotEmpty;
  double get netPayable =>
      (approvedAmount ?? 0) + supplementTotal - deductible - depreciation;
  double get depreciationHoldback => depreciationRecovered ? 0 : depreciation;
  double get outstandingBalance => netPayable - amountCollected;

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
