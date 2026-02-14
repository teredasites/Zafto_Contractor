// ZAFTO Lien Tracking Model
// L5: Per-job mechanic's lien lifecycle tracking.

import 'package:equatable/equatable.dart';

enum LienStatus {
  monitoring,
  noticeDue,
  noticeSent,
  lienEligible,
  lienFiled,
  paymentReceived,
  lienReleased,
  enforcement,
  resolved,
  expired;

  String get dbValue {
    switch (this) {
      case LienStatus.monitoring: return 'monitoring';
      case LienStatus.noticeDue: return 'notice_due';
      case LienStatus.noticeSent: return 'notice_sent';
      case LienStatus.lienEligible: return 'lien_eligible';
      case LienStatus.lienFiled: return 'lien_filed';
      case LienStatus.paymentReceived: return 'payment_received';
      case LienStatus.lienReleased: return 'lien_released';
      case LienStatus.enforcement: return 'enforcement';
      case LienStatus.resolved: return 'resolved';
      case LienStatus.expired: return 'expired';
    }
  }

  static LienStatus fromDb(String? value) {
    switch (value) {
      case 'monitoring': return LienStatus.monitoring;
      case 'notice_due': return LienStatus.noticeDue;
      case 'notice_sent': return LienStatus.noticeSent;
      case 'lien_eligible': return LienStatus.lienEligible;
      case 'lien_filed': return LienStatus.lienFiled;
      case 'payment_received': return LienStatus.paymentReceived;
      case 'lien_released': return LienStatus.lienReleased;
      case 'enforcement': return LienStatus.enforcement;
      case 'resolved': return LienStatus.resolved;
      case 'expired': return LienStatus.expired;
      default: return LienStatus.monitoring;
    }
  }

  String get label {
    switch (this) {
      case LienStatus.monitoring: return 'Monitoring';
      case LienStatus.noticeDue: return 'Notice Due';
      case LienStatus.noticeSent: return 'Notice Sent';
      case LienStatus.lienEligible: return 'Lien Eligible';
      case LienStatus.lienFiled: return 'Lien Filed';
      case LienStatus.paymentReceived: return 'Payment Received';
      case LienStatus.lienReleased: return 'Lien Released';
      case LienStatus.enforcement: return 'Enforcement';
      case LienStatus.resolved: return 'Resolved';
      case LienStatus.expired: return 'Expired';
    }
  }

  bool get isActive => this == LienStatus.monitoring ||
      this == LienStatus.noticeDue ||
      this == LienStatus.noticeSent ||
      this == LienStatus.lienEligible ||
      this == LienStatus.lienFiled ||
      this == LienStatus.enforcement;

  bool get isUrgent => this == LienStatus.noticeDue || this == LienStatus.enforcement;
}

class LienTracking extends Equatable {
  final String id;
  final String companyId;
  final String jobId;
  final String? customerId;
  final String propertyAddress;
  final String? propertyCity;
  final String propertyState;
  final String stateCode;
  final double? contractAmount;
  final double? amountOwed;
  final DateTime? firstWorkDate;
  final DateTime? lastWorkDate;
  final DateTime? completionDate;
  final bool preliminaryNoticeSent;
  final DateTime? preliminaryNoticeDate;
  final String? preliminaryNoticeDocumentPath;
  final bool noticeOfIntentSent;
  final DateTime? noticeOfIntentDate;
  final String? noticeOfIntentDocumentPath;
  final bool lienFiled;
  final DateTime? lienFilingDate;
  final String? lienFilingDocumentPath;
  final bool lienReleased;
  final DateTime? lienReleaseDate;
  final String? lienReleaseDocumentPath;
  final bool enforcementFiled;
  final DateTime? enforcementFilingDate;
  final LienStatus status;
  final String? notes;
  final DateTime createdAt;

  const LienTracking({
    required this.id,
    required this.companyId,
    required this.jobId,
    this.customerId,
    required this.propertyAddress,
    this.propertyCity,
    required this.propertyState,
    required this.stateCode,
    this.contractAmount,
    this.amountOwed,
    this.firstWorkDate,
    this.lastWorkDate,
    this.completionDate,
    required this.preliminaryNoticeSent,
    this.preliminaryNoticeDate,
    this.preliminaryNoticeDocumentPath,
    required this.noticeOfIntentSent,
    this.noticeOfIntentDate,
    this.noticeOfIntentDocumentPath,
    required this.lienFiled,
    this.lienFilingDate,
    this.lienFilingDocumentPath,
    required this.lienReleased,
    this.lienReleaseDate,
    this.lienReleaseDocumentPath,
    required this.enforcementFiled,
    this.enforcementFilingDate,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory LienTracking.fromJson(Map<String, dynamic> json) {
    return LienTracking(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      jobId: json['job_id'] as String,
      customerId: json['customer_id'] as String?,
      propertyAddress: json['property_address'] as String,
      propertyCity: json['property_city'] as String?,
      propertyState: json['property_state'] as String,
      stateCode: json['state_code'] as String,
      contractAmount: (json['contract_amount'] as num?)?.toDouble(),
      amountOwed: (json['amount_owed'] as num?)?.toDouble(),
      firstWorkDate: json['first_work_date'] != null ? DateTime.parse(json['first_work_date'] as String) : null,
      lastWorkDate: json['last_work_date'] != null ? DateTime.parse(json['last_work_date'] as String) : null,
      completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date'] as String) : null,
      preliminaryNoticeSent: json['preliminary_notice_sent'] as bool? ?? false,
      preliminaryNoticeDate: json['preliminary_notice_date'] != null ? DateTime.parse(json['preliminary_notice_date'] as String) : null,
      preliminaryNoticeDocumentPath: json['preliminary_notice_document_path'] as String?,
      noticeOfIntentSent: json['notice_of_intent_sent'] as bool? ?? false,
      noticeOfIntentDate: json['notice_of_intent_date'] != null ? DateTime.parse(json['notice_of_intent_date'] as String) : null,
      noticeOfIntentDocumentPath: json['notice_of_intent_document_path'] as String?,
      lienFiled: json['lien_filed'] as bool? ?? false,
      lienFilingDate: json['lien_filing_date'] != null ? DateTime.parse(json['lien_filing_date'] as String) : null,
      lienFilingDocumentPath: json['lien_filing_document_path'] as String?,
      lienReleased: json['lien_released'] as bool? ?? false,
      lienReleaseDate: json['lien_release_date'] != null ? DateTime.parse(json['lien_release_date'] as String) : null,
      lienReleaseDocumentPath: json['lien_release_document_path'] as String?,
      enforcementFiled: json['enforcement_filed'] as bool? ?? false,
      enforcementFilingDate: json['enforcement_filing_date'] != null ? DateTime.parse(json['enforcement_filing_date'] as String) : null,
      status: LienStatus.fromDb(json['status'] as String?),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'job_id': jobId,
    'customer_id': customerId,
    'property_address': propertyAddress,
    'property_city': propertyCity,
    'property_state': propertyState,
    'state_code': stateCode,
    'contract_amount': contractAmount,
    'amount_owed': amountOwed,
    'first_work_date': firstWorkDate?.toIso8601String().split('T').first,
    'last_work_date': lastWorkDate?.toIso8601String().split('T').first,
    'completion_date': completionDate?.toIso8601String().split('T').first,
    'preliminary_notice_sent': preliminaryNoticeSent,
    'preliminary_notice_date': preliminaryNoticeDate?.toIso8601String().split('T').first,
    'preliminary_notice_document_path': preliminaryNoticeDocumentPath,
    'notice_of_intent_sent': noticeOfIntentSent,
    'notice_of_intent_date': noticeOfIntentDate?.toIso8601String().split('T').first,
    'notice_of_intent_document_path': noticeOfIntentDocumentPath,
    'lien_filed': lienFiled,
    'lien_filing_date': lienFilingDate?.toIso8601String().split('T').first,
    'lien_filing_document_path': lienFilingDocumentPath,
    'lien_released': lienReleased,
    'lien_release_date': lienReleaseDate?.toIso8601String().split('T').first,
    'lien_release_document_path': lienReleaseDocumentPath,
    'enforcement_filed': enforcementFiled,
    'enforcement_filing_date': enforcementFilingDate?.toIso8601String().split('T').first,
    'status': status.dbValue,
    'notes': notes,
  };

  LienTracking copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? customerId,
    String? propertyAddress,
    String? propertyCity,
    String? propertyState,
    String? stateCode,
    double? contractAmount,
    double? amountOwed,
    DateTime? firstWorkDate,
    DateTime? lastWorkDate,
    DateTime? completionDate,
    bool? preliminaryNoticeSent,
    DateTime? preliminaryNoticeDate,
    String? preliminaryNoticeDocumentPath,
    bool? noticeOfIntentSent,
    DateTime? noticeOfIntentDate,
    String? noticeOfIntentDocumentPath,
    bool? lienFiled,
    DateTime? lienFilingDate,
    String? lienFilingDocumentPath,
    bool? lienReleased,
    DateTime? lienReleaseDate,
    String? lienReleaseDocumentPath,
    bool? enforcementFiled,
    DateTime? enforcementFilingDate,
    LienStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return LienTracking(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      customerId: customerId ?? this.customerId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyCity: propertyCity ?? this.propertyCity,
      propertyState: propertyState ?? this.propertyState,
      stateCode: stateCode ?? this.stateCode,
      contractAmount: contractAmount ?? this.contractAmount,
      amountOwed: amountOwed ?? this.amountOwed,
      firstWorkDate: firstWorkDate ?? this.firstWorkDate,
      lastWorkDate: lastWorkDate ?? this.lastWorkDate,
      completionDate: completionDate ?? this.completionDate,
      preliminaryNoticeSent: preliminaryNoticeSent ?? this.preliminaryNoticeSent,
      preliminaryNoticeDate: preliminaryNoticeDate ?? this.preliminaryNoticeDate,
      preliminaryNoticeDocumentPath: preliminaryNoticeDocumentPath ?? this.preliminaryNoticeDocumentPath,
      noticeOfIntentSent: noticeOfIntentSent ?? this.noticeOfIntentSent,
      noticeOfIntentDate: noticeOfIntentDate ?? this.noticeOfIntentDate,
      noticeOfIntentDocumentPath: noticeOfIntentDocumentPath ?? this.noticeOfIntentDocumentPath,
      lienFiled: lienFiled ?? this.lienFiled,
      lienFilingDate: lienFilingDate ?? this.lienFilingDate,
      lienFilingDocumentPath: lienFilingDocumentPath ?? this.lienFilingDocumentPath,
      lienReleased: lienReleased ?? this.lienReleased,
      lienReleaseDate: lienReleaseDate ?? this.lienReleaseDate,
      lienReleaseDocumentPath: lienReleaseDocumentPath ?? this.lienReleaseDocumentPath,
      enforcementFiled: enforcementFiled ?? this.enforcementFiled,
      enforcementFilingDate: enforcementFilingDate ?? this.enforcementFilingDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Days until lien filing deadline expires (based on last_work_date + state deadline)
  int? daysUntilLienDeadline(int lienFilingDeadlineDays) {
    final referenceDate = lastWorkDate ?? completionDate;
    if (referenceDate == null) return null;
    final deadline = referenceDate.add(Duration(days: lienFilingDeadlineDays));
    return deadline.difference(DateTime.now()).inDays;
  }

  bool get isAtRisk => status.isUrgent || (amountOwed != null && amountOwed! > 0);

  @override
  List<Object?> get props => [id, jobId, stateCode, status];
}
