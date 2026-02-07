// ZAFTO Change Order Model — Supabase Backend
// Maps to `change_orders` table in Supabase PostgreSQL.
// Workflow: draft → pending_approval → approved/rejected/voided.
// Line items stored as JSONB array.

enum ChangeOrderStatus {
  draft,
  pendingApproval,
  approved,
  rejected,
  voided;

  String get dbValue {
    switch (this) {
      case ChangeOrderStatus.draft:
        return 'draft';
      case ChangeOrderStatus.pendingApproval:
        return 'pending_approval';
      case ChangeOrderStatus.approved:
        return 'approved';
      case ChangeOrderStatus.rejected:
        return 'rejected';
      case ChangeOrderStatus.voided:
        return 'voided';
    }
  }

  String get label {
    switch (this) {
      case ChangeOrderStatus.draft:
        return 'Draft';
      case ChangeOrderStatus.pendingApproval:
        return 'Pending Approval';
      case ChangeOrderStatus.approved:
        return 'Approved';
      case ChangeOrderStatus.rejected:
        return 'Rejected';
      case ChangeOrderStatus.voided:
        return 'Voided';
    }
  }

  static ChangeOrderStatus fromString(String? value) {
    if (value == null) return ChangeOrderStatus.draft;
    switch (value) {
      case 'draft':
        return ChangeOrderStatus.draft;
      case 'pending_approval':
        return ChangeOrderStatus.pendingApproval;
      case 'approved':
        return ChangeOrderStatus.approved;
      case 'rejected':
        return ChangeOrderStatus.rejected;
      case 'voided':
        return ChangeOrderStatus.voided;
      default:
        return ChangeOrderStatus.draft;
    }
  }
}

// Line item within a change order (stored as JSONB).
class ChangeOrderLineItem {
  final String description;
  final double quantity;
  final double unitPrice;

  const ChangeOrderLineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
      };

  factory ChangeOrderLineItem.fromJson(Map<String, dynamic> json) {
    return ChangeOrderLineItem(
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ChangeOrder {
  final String id;
  final String companyId;
  final String jobId;
  final String createdByUserId;
  final String changeOrderNumber;
  final String title;
  final String description;
  final String? reason;
  final List<ChangeOrderLineItem> lineItems;
  final double amount;
  final ChangeOrderStatus status;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? signatureId;
  final List<String> photoIds;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChangeOrder({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.createdByUserId = '',
    this.changeOrderNumber = '',
    required this.title,
    required this.description,
    this.reason,
    this.lineItems = const [],
    this.amount = 0,
    this.status = ChangeOrderStatus.draft,
    this.approvedByName,
    this.approvedAt,
    this.signatureId,
    this.photoIds = const [],
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isNew => id.isEmpty;
  bool get isDraft => status == ChangeOrderStatus.draft;
  bool get isApproved => status == ChangeOrderStatus.approved;
  bool get isResolved =>
      status == ChangeOrderStatus.approved ||
      status == ChangeOrderStatus.rejected ||
      status == ChangeOrderStatus.voided;

  // Compute total from line items (if any).
  double get computedAmount {
    if (lineItems.isEmpty) return amount;
    return lineItems.fold<double>(0.0, (sum, li) => sum + li.total);
  }

  // Supabase INSERT — omit id, created_at, updated_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'created_by_user_id': createdByUserId,
        'change_order_number': changeOrderNumber,
        'title': title,
        'description': description,
        if (reason != null) 'reason': reason,
        'line_items': lineItems.map((li) => li.toJson()).toList(),
        'amount': computedAmount,
        'status': status.dbValue,
        'photo_ids': photoIds,
        if (notes != null) 'notes': notes,
      };

  // Supabase UPDATE — editable fields.
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'reason': reason,
        'line_items': lineItems.map((li) => li.toJson()).toList(),
        'amount': computedAmount,
        'status': status.dbValue,
        'approved_by_name': approvedByName,
        'approved_at': approvedAt?.toUtc().toIso8601String(),
        'signature_id': signatureId,
        'photo_ids': photoIds,
        'notes': notes,
      };

  factory ChangeOrder.fromJson(Map<String, dynamic> json) {
    return ChangeOrder(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      changeOrderNumber: json['change_order_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      reason: json['reason'] as String?,
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) =>
                  ChangeOrderLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: ChangeOrderStatus.fromString(json['status'] as String?),
      approvedByName: json['approved_by_name'] as String?,
      approvedAt: _parseOptionalTimestamp(json['approved_at']),
      signatureId: json['signature_id'] as String?,
      photoIds: (json['photo_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  ChangeOrder copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? createdByUserId,
    String? changeOrderNumber,
    String? title,
    String? description,
    String? reason,
    List<ChangeOrderLineItem>? lineItems,
    double? amount,
    ChangeOrderStatus? status,
    String? approvedByName,
    DateTime? approvedAt,
    String? signatureId,
    List<String>? photoIds,
    String? notes,
  }) {
    return ChangeOrder(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      changeOrderNumber: changeOrderNumber ?? this.changeOrderNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      lineItems: lineItems ?? this.lineItems,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      signatureId: signatureId ?? this.signatureId,
      photoIds: photoIds ?? this.photoIds,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
