// ZAFTO Floor Plan Snapshot Model — Supabase Backend
// Maps to `floor_plan_snapshots` table. Version history for floor plans.
// Auto-snapshots on significant edits, manual snapshots for change orders.

enum SnapshotReason { manual, auto, preChangeOrder, preEdit }

class FloorPlanSnapshot {
  final String id;
  final String floorPlanId;
  final String companyId;
  final Map<String, dynamic> planData;
  final SnapshotReason snapshotReason;
  final String? snapshotLabel;
  final String? createdBy;
  final DateTime createdAt;

  const FloorPlanSnapshot({
    this.id = '',
    required this.floorPlanId,
    required this.companyId,
    required this.planData,
    this.snapshotReason = SnapshotReason.manual,
    this.snapshotLabel,
    this.createdBy,
    required this.createdAt,
  });

  // Computed
  String get displayLabel =>
      snapshotLabel ?? _reasonLabel(snapshotReason);
  bool get isAutoSnapshot =>
      snapshotReason == SnapshotReason.auto;

  static String _reasonLabel(SnapshotReason reason) {
    switch (reason) {
      case SnapshotReason.manual:
        return 'Manual Snapshot';
      case SnapshotReason.auto:
        return 'Auto-Save';
      case SnapshotReason.preChangeOrder:
        return 'Pre-Change Order';
      case SnapshotReason.preEdit:
        return 'Pre-Edit';
    }
  }

  Map<String, dynamic> toInsertJson() => {
        'floor_plan_id': floorPlanId,
        'company_id': companyId,
        'plan_data': planData,
        'snapshot_reason': _reasonToDb(snapshotReason),
        if (snapshotLabel != null) 'snapshot_label': snapshotLabel,
        if (createdBy != null) 'created_by': createdBy,
      };

  factory FloorPlanSnapshot.fromJson(Map<String, dynamic> json) {
    return FloorPlanSnapshot(
      id: json['id'] as String? ?? '',
      floorPlanId: json['floor_plan_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      planData: (json['plan_data'] as Map<String, dynamic>?) ?? const {},
      snapshotReason: _parseReason(json['snapshot_reason'] as String?),
      snapshotLabel: json['snapshot_label'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  FloorPlanSnapshot copyWith({
    String? id,
    String? floorPlanId,
    String? companyId,
    Map<String, dynamic>? planData,
    SnapshotReason? snapshotReason,
    String? snapshotLabel,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return FloorPlanSnapshot(
      id: id ?? this.id,
      floorPlanId: floorPlanId ?? this.floorPlanId,
      companyId: companyId ?? this.companyId,
      planData: planData ?? this.planData,
      snapshotReason: snapshotReason ?? this.snapshotReason,
      snapshotLabel: snapshotLabel ?? this.snapshotLabel,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static SnapshotReason _parseReason(String? value) {
    switch (value) {
      case 'manual':
        return SnapshotReason.manual;
      case 'auto':
        return SnapshotReason.auto;
      case 'pre_change_order':
        return SnapshotReason.preChangeOrder;
      case 'pre_edit':
        return SnapshotReason.preEdit;
      default:
        return SnapshotReason.manual;
    }
  }

  static String _reasonToDb(SnapshotReason reason) {
    switch (reason) {
      case SnapshotReason.manual:
        return 'manual';
      case SnapshotReason.auto:
        return 'auto';
      case SnapshotReason.preChangeOrder:
        return 'pre_change_order';
      case SnapshotReason.preEdit:
        return 'pre_edit';
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
