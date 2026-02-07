// ZAFTO TPI Inspection Model — Supabase Backend
// Maps to `tpi_scheduling` table. Third-Party Inspector appointments.

enum TpiInspectionType {
  initial,
  progress,
  supplement,
  finalInspection,
  reInspection;

  String get dbValue {
    switch (this) {
      case TpiInspectionType.initial:
        return 'initial';
      case TpiInspectionType.progress:
        return 'progress';
      case TpiInspectionType.supplement:
        return 'supplement';
      case TpiInspectionType.finalInspection:
        return 'final';
      case TpiInspectionType.reInspection:
        return 're_inspection';
    }
  }

  String get label {
    switch (this) {
      case TpiInspectionType.initial:
        return 'Initial';
      case TpiInspectionType.progress:
        return 'Progress';
      case TpiInspectionType.supplement:
        return 'Supplement';
      case TpiInspectionType.finalInspection:
        return 'Final';
      case TpiInspectionType.reInspection:
        return 'Re-Inspection';
    }
  }

  static TpiInspectionType fromString(String? value) {
    if (value == null) return TpiInspectionType.progress;
    switch (value) {
      case 'initial':
        return TpiInspectionType.initial;
      case 'progress':
        return TpiInspectionType.progress;
      case 'supplement':
        return TpiInspectionType.supplement;
      case 'final':
        return TpiInspectionType.finalInspection;
      case 're_inspection':
        return TpiInspectionType.reInspection;
      default:
        return TpiInspectionType.progress;
    }
  }
}

enum TpiStatus {
  pending,
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled;

  String get dbValue {
    switch (this) {
      case TpiStatus.pending:
        return 'pending';
      case TpiStatus.scheduled:
        return 'scheduled';
      case TpiStatus.confirmed:
        return 'confirmed';
      case TpiStatus.inProgress:
        return 'in_progress';
      case TpiStatus.completed:
        return 'completed';
      case TpiStatus.cancelled:
        return 'cancelled';
      case TpiStatus.rescheduled:
        return 'rescheduled';
    }
  }

  String get label {
    switch (this) {
      case TpiStatus.pending:
        return 'Pending';
      case TpiStatus.scheduled:
        return 'Scheduled';
      case TpiStatus.confirmed:
        return 'Confirmed';
      case TpiStatus.inProgress:
        return 'In Progress';
      case TpiStatus.completed:
        return 'Completed';
      case TpiStatus.cancelled:
        return 'Cancelled';
      case TpiStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  static TpiStatus fromString(String? value) {
    if (value == null) return TpiStatus.pending;
    switch (value) {
      case 'pending':
        return TpiStatus.pending;
      case 'scheduled':
        return TpiStatus.scheduled;
      case 'confirmed':
        return TpiStatus.confirmed;
      case 'in_progress':
        return TpiStatus.inProgress;
      case 'completed':
        return TpiStatus.completed;
      case 'cancelled':
        return TpiStatus.cancelled;
      case 'rescheduled':
        return TpiStatus.rescheduled;
      default:
        return TpiStatus.pending;
    }
  }
}

enum TpiResult {
  passed,
  failed,
  conditional,
  deferred;

  String get dbValue => name;

  String get label {
    switch (this) {
      case TpiResult.passed:
        return 'Passed';
      case TpiResult.failed:
        return 'Failed';
      case TpiResult.conditional:
        return 'Conditional';
      case TpiResult.deferred:
        return 'Deferred';
    }
  }

  static TpiResult? fromString(String? value) {
    if (value == null) return null;
    return TpiResult.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => TpiResult.deferred,
    );
  }
}

class TpiInspection {
  final String id;
  final String companyId;
  final String claimId;
  final String jobId;
  final String? inspectorName;
  final String? inspectorCompany;
  final String? inspectorPhone;
  final String? inspectorEmail;
  final TpiInspectionType inspectionType;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final TpiStatus status;
  final TpiResult? result;
  final String? findings;
  final List<Map<String, dynamic>> photos;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TpiInspection({
    this.id = '',
    this.companyId = '',
    this.claimId = '',
    this.jobId = '',
    this.inspectorName,
    this.inspectorCompany,
    this.inspectorPhone,
    this.inspectorEmail,
    this.inspectionType = TpiInspectionType.progress,
    this.scheduledDate,
    this.completedDate,
    this.status = TpiStatus.pending,
    this.result,
    this.findings,
    this.photos = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'claim_id': claimId,
        'job_id': jobId,
        if (inspectorName != null) 'inspector_name': inspectorName,
        if (inspectorCompany != null) 'inspector_company': inspectorCompany,
        if (inspectorPhone != null) 'inspector_phone': inspectorPhone,
        if (inspectorEmail != null) 'inspector_email': inspectorEmail,
        'inspection_type': inspectionType.dbValue,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate!.toUtc().toIso8601String(),
        'status': status.dbValue,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'inspector_name': inspectorName,
        'inspector_company': inspectorCompany,
        'inspector_phone': inspectorPhone,
        'inspector_email': inspectorEmail,
        'inspection_type': inspectionType.dbValue,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate!.toUtc().toIso8601String(),
        if (completedDate != null)
          'completed_date': completedDate!.toUtc().toIso8601String(),
        'status': status.dbValue,
        if (result != null) 'result': result!.dbValue,
        'findings': findings,
        'photos': photos,
        'notes': notes,
      };

  factory TpiInspection.fromJson(Map<String, dynamic> json) {
    return TpiInspection(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      claimId: json['claim_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      inspectorName: json['inspector_name'] as String?,
      inspectorCompany: json['inspector_company'] as String?,
      inspectorPhone: json['inspector_phone'] as String?,
      inspectorEmail: json['inspector_email'] as String?,
      inspectionType:
          TpiInspectionType.fromString(json['inspection_type'] as String?),
      scheduledDate: _parseOptionalDate(json['scheduled_date']),
      completedDate: _parseOptionalDate(json['completed_date']),
      status: TpiStatus.fromString(json['status'] as String?),
      result: TpiResult.fromString(json['result'] as String?),
      findings: json['findings'] as String?,
      photos: _parseJsonList(json['photos']),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get isScheduled =>
      status == TpiStatus.scheduled || status == TpiStatus.confirmed;
  bool get isCompleted => status == TpiStatus.completed;
  bool get isPassed => result == TpiResult.passed;
  bool get isFailed => result == TpiResult.failed;
  bool get hasInspector =>
      inspectorName != null && inspectorName!.isNotEmpty;

  static List<Map<String, dynamic>> _parseJsonList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    }
    return const [];
  }

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
