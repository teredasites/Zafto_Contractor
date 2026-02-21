// ZAFTO Estimate Version & Change Order Models
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Estimate version snapshots and change order mutations.

import 'package:equatable/equatable.dart';

// ════════════════════════════════════════════════════════════════
// ESTIMATE VERSION
// ════════════════════════════════════════════════════════════════

class EstimateVersion extends Equatable {
  final String id;
  final String estimateId;
  final int versionNumber;
  final String? label;
  final Map<String, dynamic> snapshotData;
  final String? createdBy;
  final DateTime createdAt;

  const EstimateVersion({
    required this.id,
    required this.estimateId,
    required this.versionNumber,
    this.label,
    this.snapshotData = const {},
    this.createdBy,
    required this.createdAt,
  });

  /// Display label with fallback
  String get displayLabel => label ?? 'Version $versionNumber';

  factory EstimateVersion.fromJson(Map<String, dynamic> json) {
    return EstimateVersion(
      id: json['id'] as String,
      estimateId: json['estimate_id'] as String,
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      label: json['label'] as String?,
      snapshotData: (json['snapshot_data'] as Map<String, dynamic>?) ?? {},
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'estimate_id': estimateId,
        'version_number': versionNumber,
        'label': label,
        'snapshot_data': snapshotData,
        'created_by': createdBy,
      };

  EstimateVersion copyWith({
    String? id,
    String? estimateId,
    int? versionNumber,
    String? label,
    Map<String, dynamic>? snapshotData,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return EstimateVersion(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      versionNumber: versionNumber ?? this.versionNumber,
      label: label ?? this.label,
      snapshotData: snapshotData ?? this.snapshotData,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, estimateId, versionNumber, label, createdBy];
}

// ════════════════════════════════════════════════════════════════
// CHANGE ORDER STATUS
// ════════════════════════════════════════════════════════════════

enum ChangeOrderStatus { draft, sent, approved, rejected }

ChangeOrderStatus parseChangeOrderStatus(String? value) {
  switch (value) {
    case 'sent':
      return ChangeOrderStatus.sent;
    case 'approved':
      return ChangeOrderStatus.approved;
    case 'rejected':
      return ChangeOrderStatus.rejected;
    default:
      return ChangeOrderStatus.draft;
  }
}

String changeOrderStatusToString(ChangeOrderStatus s) {
  switch (s) {
    case ChangeOrderStatus.draft:
      return 'draft';
    case ChangeOrderStatus.sent:
      return 'sent';
    case ChangeOrderStatus.approved:
      return 'approved';
    case ChangeOrderStatus.rejected:
      return 'rejected';
  }
}

String changeOrderStatusLabel(ChangeOrderStatus s) {
  switch (s) {
    case ChangeOrderStatus.draft:
      return 'Draft';
    case ChangeOrderStatus.sent:
      return 'Sent';
    case ChangeOrderStatus.approved:
      return 'Approved';
    case ChangeOrderStatus.rejected:
      return 'Rejected';
  }
}

// ════════════════════════════════════════════════════════════════
// ESTIMATE CHANGE ORDER
// ════════════════════════════════════════════════════════════════

class EstimateChangeOrder extends Equatable {
  final String id;
  final String estimateId;
  final int changeOrderNumber;
  final String title;
  final String? description;
  final ChangeOrderStatus status;
  final List<Map<String, dynamic>> itemsAdded;
  final List<Map<String, dynamic>> itemsModified;
  final List<Map<String, dynamic>> itemsRemoved;
  final double subtotalChange;
  final double taxChange;
  final double totalChange;
  final double newEstimateTotal;
  final String? createdBy;
  final DateTime? approvedAt;
  final DateTime? signedAt;
  final DateTime createdAt;

  const EstimateChangeOrder({
    required this.id,
    required this.estimateId,
    required this.changeOrderNumber,
    required this.title,
    this.description,
    required this.status,
    this.itemsAdded = const [],
    this.itemsModified = const [],
    this.itemsRemoved = const [],
    required this.subtotalChange,
    required this.taxChange,
    required this.totalChange,
    required this.newEstimateTotal,
    this.createdBy,
    this.approvedAt,
    this.signedAt,
    required this.createdAt,
  });

  /// Display name like "CO #1: Kitchen expansion"
  String get displayName => 'CO #$changeOrderNumber: $title';

  /// Whether the change order increases or decreases the total
  bool get isIncrease => totalChange > 0;
  bool get isDecrease => totalChange < 0;

  /// Number of items affected
  int get totalItemsAffected =>
      itemsAdded.length + itemsModified.length + itemsRemoved.length;

  factory EstimateChangeOrder.fromJson(Map<String, dynamic> json) {
    return EstimateChangeOrder(
      id: json['id'] as String,
      estimateId: json['estimate_id'] as String,
      changeOrderNumber: (json['change_order_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: parseChangeOrderStatus(json['status'] as String?),
      itemsAdded: _parseJsonList(json['items_added']),
      itemsModified: _parseJsonList(json['items_modified']),
      itemsRemoved: _parseJsonList(json['items_removed']),
      subtotalChange: (json['subtotal_change'] as num?)?.toDouble() ?? 0,
      taxChange: (json['tax_change'] as num?)?.toDouble() ?? 0,
      totalChange: (json['total_change'] as num?)?.toDouble() ?? 0,
      newEstimateTotal: (json['new_estimate_total'] as num?)?.toDouble() ?? 0,
      createdBy: json['created_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      signedAt: json['signed_at'] != null
          ? DateTime.parse(json['signed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<Map<String, dynamic>> _parseJsonList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'estimate_id': estimateId,
        'change_order_number': changeOrderNumber,
        'title': title,
        'description': description,
        'status': changeOrderStatusToString(status),
        'items_added': itemsAdded,
        'items_modified': itemsModified,
        'items_removed': itemsRemoved,
        'subtotal_change': subtotalChange,
        'tax_change': taxChange,
        'total_change': totalChange,
        'new_estimate_total': newEstimateTotal,
        'created_by': createdBy,
      };

  EstimateChangeOrder copyWith({
    String? id,
    String? estimateId,
    int? changeOrderNumber,
    String? title,
    String? description,
    ChangeOrderStatus? status,
    List<Map<String, dynamic>>? itemsAdded,
    List<Map<String, dynamic>>? itemsModified,
    List<Map<String, dynamic>>? itemsRemoved,
    double? subtotalChange,
    double? taxChange,
    double? totalChange,
    double? newEstimateTotal,
    String? createdBy,
    DateTime? approvedAt,
    DateTime? signedAt,
    DateTime? createdAt,
  }) {
    return EstimateChangeOrder(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      changeOrderNumber: changeOrderNumber ?? this.changeOrderNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      itemsAdded: itemsAdded ?? this.itemsAdded,
      itemsModified: itemsModified ?? this.itemsModified,
      itemsRemoved: itemsRemoved ?? this.itemsRemoved,
      subtotalChange: subtotalChange ?? this.subtotalChange,
      taxChange: taxChange ?? this.taxChange,
      totalChange: totalChange ?? this.totalChange,
      newEstimateTotal: newEstimateTotal ?? this.newEstimateTotal,
      createdBy: createdBy ?? this.createdBy,
      approvedAt: approvedAt ?? this.approvedAt,
      signedAt: signedAt ?? this.signedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        estimateId,
        changeOrderNumber,
        title,
        status,
        subtotalChange,
        taxChange,
        totalChange,
        newEstimateTotal,
      ];
}
