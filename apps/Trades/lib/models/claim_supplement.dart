// ZAFTO Claim Supplement Model — Supabase Backend
// Maps to `claim_supplements` table. Tracks additional scope/cost beyond original estimate.

enum SupplementStatus {
  draft,
  submitted,
  underReview,
  approved,
  denied,
  partiallyApproved;

  String get dbValue {
    switch (this) {
      case SupplementStatus.draft:
        return 'draft';
      case SupplementStatus.submitted:
        return 'submitted';
      case SupplementStatus.underReview:
        return 'under_review';
      case SupplementStatus.approved:
        return 'approved';
      case SupplementStatus.denied:
        return 'denied';
      case SupplementStatus.partiallyApproved:
        return 'partially_approved';
    }
  }

  String get label {
    switch (this) {
      case SupplementStatus.draft:
        return 'Draft';
      case SupplementStatus.submitted:
        return 'Submitted';
      case SupplementStatus.underReview:
        return 'Under Review';
      case SupplementStatus.approved:
        return 'Approved';
      case SupplementStatus.denied:
        return 'Denied';
      case SupplementStatus.partiallyApproved:
        return 'Partially Approved';
    }
  }

  static SupplementStatus fromString(String? value) {
    if (value == null) return SupplementStatus.draft;
    switch (value) {
      case 'draft':
        return SupplementStatus.draft;
      case 'submitted':
        return SupplementStatus.submitted;
      case 'under_review':
        return SupplementStatus.underReview;
      case 'approved':
        return SupplementStatus.approved;
      case 'denied':
        return SupplementStatus.denied;
      case 'partially_approved':
        return SupplementStatus.partiallyApproved;
      default:
        return SupplementStatus.draft;
    }
  }
}

enum SupplementReason {
  hiddenDamage,
  codeUpgrade,
  scopeChange,
  materialUpgrade,
  additionalRepair,
  other;

  String get dbValue {
    switch (this) {
      case SupplementReason.hiddenDamage:
        return 'hidden_damage';
      case SupplementReason.codeUpgrade:
        return 'code_upgrade';
      case SupplementReason.scopeChange:
        return 'scope_change';
      case SupplementReason.materialUpgrade:
        return 'material_upgrade';
      case SupplementReason.additionalRepair:
        return 'additional_repair';
      case SupplementReason.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case SupplementReason.hiddenDamage:
        return 'Hidden Damage';
      case SupplementReason.codeUpgrade:
        return 'Code Upgrade';
      case SupplementReason.scopeChange:
        return 'Scope Change';
      case SupplementReason.materialUpgrade:
        return 'Material Upgrade';
      case SupplementReason.additionalRepair:
        return 'Additional Repair';
      case SupplementReason.other:
        return 'Other';
    }
  }

  static SupplementReason fromString(String? value) {
    if (value == null) return SupplementReason.hiddenDamage;
    switch (value) {
      case 'hidden_damage':
        return SupplementReason.hiddenDamage;
      case 'code_upgrade':
        return SupplementReason.codeUpgrade;
      case 'scope_change':
        return SupplementReason.scopeChange;
      case 'material_upgrade':
        return SupplementReason.materialUpgrade;
      case 'additional_repair':
        return SupplementReason.additionalRepair;
      case 'other':
        return SupplementReason.other;
      default:
        return SupplementReason.hiddenDamage;
    }
  }
}

class ClaimSupplement {
  final String id;
  final String companyId;
  final String claimId;
  final int supplementNumber;
  final String title;
  final String? description;
  final SupplementReason reason;
  final double amount;
  final double? rcvAmount;
  final double? acvAmount;
  final double depreciationAmount;
  final SupplementStatus status;
  final double? approvedAmount;
  final List<Map<String, dynamic>> lineItems;
  final List<Map<String, dynamic>> photos;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClaimSupplement({
    this.id = '',
    this.companyId = '',
    this.claimId = '',
    this.supplementNumber = 1,
    required this.title,
    this.description,
    this.reason = SupplementReason.hiddenDamage,
    this.amount = 0,
    this.rcvAmount,
    this.acvAmount,
    this.depreciationAmount = 0,
    this.status = SupplementStatus.draft,
    this.approvedAmount,
    this.lineItems = const [],
    this.photos = const [],
    this.submittedAt,
    this.reviewedAt,
    this.reviewerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'claim_id': claimId,
        'supplement_number': supplementNumber,
        'title': title,
        if (description != null) 'description': description,
        'reason': reason.dbValue,
        'amount': amount,
        if (rcvAmount != null) 'rcv_amount': rcvAmount,
        if (acvAmount != null) 'acv_amount': acvAmount,
        'depreciation_amount': depreciationAmount,
        'status': status.dbValue,
        'line_items': lineItems,
        'photos': photos,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'reason': reason.dbValue,
        'amount': amount,
        'rcv_amount': rcvAmount,
        'acv_amount': acvAmount,
        'depreciation_amount': depreciationAmount,
        'status': status.dbValue,
        'approved_amount': approvedAmount,
        'line_items': lineItems,
        'photos': photos,
        'reviewer_notes': reviewerNotes,
        if (submittedAt != null)
          'submitted_at': submittedAt!.toUtc().toIso8601String(),
        if (reviewedAt != null)
          'reviewed_at': reviewedAt!.toUtc().toIso8601String(),
      };

  factory ClaimSupplement.fromJson(Map<String, dynamic> json) {
    return ClaimSupplement(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      claimId: json['claim_id'] as String? ?? '',
      supplementNumber: json['supplement_number'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      reason: SupplementReason.fromString(json['reason'] as String?),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      rcvAmount: (json['rcv_amount'] as num?)?.toDouble(),
      acvAmount: (json['acv_amount'] as num?)?.toDouble(),
      depreciationAmount: (json['depreciation_amount'] as num?)?.toDouble() ?? 0,
      status: SupplementStatus.fromString(json['status'] as String?),
      approvedAmount: (json['approved_amount'] as num?)?.toDouble(),
      lineItems: _parseJsonList(json['line_items']),
      photos: _parseJsonList(json['photos']),
      submittedAt: _parseOptionalDate(json['submitted_at']),
      reviewedAt: _parseOptionalDate(json['reviewed_at']),
      reviewerNotes: json['reviewer_notes'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  bool get isDraft => status == SupplementStatus.draft;
  bool get isApproved => status == SupplementStatus.approved;
  bool get isPending =>
      status == SupplementStatus.submitted ||
      status == SupplementStatus.underReview;

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
