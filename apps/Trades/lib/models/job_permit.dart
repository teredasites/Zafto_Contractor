// ZAFTO Job Permit Model
// L1: Per-job permit tracking with lifecycle status.

import 'package:equatable/equatable.dart';

enum PermitStatus {
  notStarted,
  applied,
  pendingReview,
  correctionsNeeded,
  approved,
  active,
  expired,
  closed,
  denied;

  String get dbValue {
    switch (this) {
      case PermitStatus.notStarted: return 'not_started';
      case PermitStatus.applied: return 'applied';
      case PermitStatus.pendingReview: return 'pending_review';
      case PermitStatus.correctionsNeeded: return 'corrections_needed';
      case PermitStatus.approved: return 'approved';
      case PermitStatus.active: return 'active';
      case PermitStatus.expired: return 'expired';
      case PermitStatus.closed: return 'closed';
      case PermitStatus.denied: return 'denied';
    }
  }

  static PermitStatus fromDb(String? value) {
    switch (value) {
      case 'not_started': return PermitStatus.notStarted;
      case 'applied': return PermitStatus.applied;
      case 'pending_review': return PermitStatus.pendingReview;
      case 'corrections_needed': return PermitStatus.correctionsNeeded;
      case 'approved': return PermitStatus.approved;
      case 'active': return PermitStatus.active;
      case 'expired': return PermitStatus.expired;
      case 'closed': return PermitStatus.closed;
      case 'denied': return PermitStatus.denied;
      default: return PermitStatus.notStarted;
    }
  }

  String get label {
    switch (this) {
      case PermitStatus.notStarted: return 'Not Started';
      case PermitStatus.applied: return 'Applied';
      case PermitStatus.pendingReview: return 'Pending Review';
      case PermitStatus.correctionsNeeded: return 'Corrections Needed';
      case PermitStatus.approved: return 'Approved';
      case PermitStatus.active: return 'Active';
      case PermitStatus.expired: return 'Expired';
      case PermitStatus.closed: return 'Closed';
      case PermitStatus.denied: return 'Denied';
    }
  }

  bool get isActionable => this == PermitStatus.notStarted ||
      this == PermitStatus.correctionsNeeded ||
      this == PermitStatus.expired;

  bool get isActive => this == PermitStatus.approved || this == PermitStatus.active;
}

class JobPermit extends Equatable {
  final String id;
  final String companyId;
  final String jobId;
  final String? jurisdictionId;
  final String permitType;
  final String? permitNumber;
  final DateTime? applicationDate;
  final DateTime? approvalDate;
  final DateTime? expirationDate;
  final double? feePaid;
  final PermitStatus status;
  final String? notes;
  final String? documentPath;
  final DateTime createdAt;

  const JobPermit({
    required this.id,
    required this.companyId,
    required this.jobId,
    this.jurisdictionId,
    required this.permitType,
    this.permitNumber,
    this.applicationDate,
    this.approvalDate,
    this.expirationDate,
    this.feePaid,
    required this.status,
    this.notes,
    this.documentPath,
    required this.createdAt,
  });

  factory JobPermit.fromJson(Map<String, dynamic> json) {
    return JobPermit(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String,
      jurisdictionId: json['jurisdiction_id'] as String?,
      permitType: json['permit_type'] as String,
      permitNumber: json['permit_number'] as String?,
      applicationDate: json['application_date'] != null ? DateTime.parse(json['application_date'] as String) : null,
      approvalDate: json['approval_date'] != null ? DateTime.parse(json['approval_date'] as String) : null,
      expirationDate: json['expiration_date'] != null ? DateTime.parse(json['expiration_date'] as String) : null,
      feePaid: (json['fee_paid'] as num?)?.toDouble(),
      status: PermitStatus.fromDb(json['status'] as String?),
      notes: json['notes'] as String?,
      documentPath: json['document_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'job_id': jobId,
    'jurisdiction_id': jurisdictionId,
    'permit_type': permitType,
    'permit_number': permitNumber,
    'application_date': applicationDate?.toIso8601String().split('T').first,
    'approval_date': approvalDate?.toIso8601String().split('T').first,
    'expiration_date': expirationDate?.toIso8601String().split('T').first,
    'fee_paid': feePaid,
    'status': status.dbValue,
    'notes': notes,
    'document_path': documentPath,
  };

  JobPermit copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? jurisdictionId,
    String? permitType,
    String? permitNumber,
    DateTime? applicationDate,
    DateTime? approvalDate,
    DateTime? expirationDate,
    double? feePaid,
    PermitStatus? status,
    String? notes,
    String? documentPath,
    DateTime? createdAt,
  }) {
    return JobPermit(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      jurisdictionId: jurisdictionId ?? this.jurisdictionId,
      permitType: permitType ?? this.permitType,
      permitNumber: permitNumber ?? this.permitNumber,
      applicationDate: applicationDate ?? this.applicationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      expirationDate: expirationDate ?? this.expirationDate,
      feePaid: feePaid ?? this.feePaid,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      documentPath: documentPath ?? this.documentPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    return expirationDate!.difference(DateTime.now()).inDays <= 30;
  }

  @override
  List<Object?> get props => [id, jobId, permitType, status];
}
