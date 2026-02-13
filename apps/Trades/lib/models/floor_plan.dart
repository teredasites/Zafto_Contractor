// ZAFTO Floor Plan Model — Supabase Backend
// Maps to `property_floor_plans` table. Stores floor plan sketches
// with wall/door/window/fixture data per floor level.
// SK1: Added job_id, estimate_id, status, sync_version, last_synced_at, floor_number

enum FloorPlanStatus { draft, scanning, processing, complete, archived }

class FloorPlan {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? walkthroughId;
  final String? jobId;
  final String? estimateId;
  final String name;
  final int floorLevel;
  final int floorNumber;
  final FloorPlanStatus status;
  final int syncVersion;
  final DateTime? lastSyncedAt;
  final Map<String, dynamic> planData;
  final String? thumbnailPath;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FloorPlan({
    this.id = '',
    this.companyId = '',
    this.propertyId,
    this.walkthroughId,
    this.jobId,
    this.estimateId,
    this.name = '',
    this.floorLevel = 1,
    this.floorNumber = 1,
    this.status = FloorPlanStatus.draft,
    this.syncVersion = 1,
    this.lastSyncedAt,
    this.planData = const {},
    this.thumbnailPath,
    this.source = 'manual_sketch',
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Computed
  bool get isEditable =>
      status != FloorPlanStatus.archived && deletedAt == null;
  bool get isComplete => status == FloorPlanStatus.complete;
  String get floorLabel {
    if (floorNumber == 0) return 'Basement';
    if (floorNumber == 1) return '1st Floor';
    if (floorNumber == 2) return '2nd Floor';
    if (floorNumber == 3) return '3rd Floor';
    return '${floorNumber}th Floor';
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (propertyId != null) 'property_id': propertyId,
        if (walkthroughId != null) 'walkthrough_id': walkthroughId,
        if (jobId != null) 'job_id': jobId,
        if (estimateId != null) 'estimate_id': estimateId,
        'name': name,
        'floor_level': floorLevel,
        'floor_number': floorNumber,
        'status': status.name,
        'sync_version': syncVersion,
        'plan_data': planData,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
        'source': source,
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'floor_level': floorLevel,
        'floor_number': floorNumber,
        'status': status.name,
        'sync_version': syncVersion,
        if (lastSyncedAt != null)
          'last_synced_at': lastSyncedAt!.toUtc().toIso8601String(),
        'plan_data': planData,
        'thumbnail_path': thumbnailPath,
        'source': source,
        'metadata': metadata,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    return FloorPlan(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      propertyId: json['property_id'] as String?,
      walkthroughId: json['walkthrough_id'] as String?,
      jobId: json['job_id'] as String?,
      estimateId: json['estimate_id'] as String?,
      name: json['name'] as String? ?? '',
      floorLevel: json['floor_level'] as int? ?? 1,
      floorNumber: json['floor_number'] as int? ?? 1,
      status: _parseStatus(json['status'] as String?),
      syncVersion: json['sync_version'] as int? ?? 1,
      lastSyncedAt: _parseDateNullable(json['last_synced_at']),
      planData: (json['plan_data'] as Map<String, dynamic>?) ?? const {},
      thumbnailPath: json['thumbnail_path'] as String?,
      source: json['source'] as String? ?? 'manual_sketch',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  FloorPlan copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? walkthroughId,
    String? jobId,
    String? estimateId,
    String? name,
    int? floorLevel,
    int? floorNumber,
    FloorPlanStatus? status,
    int? syncVersion,
    DateTime? lastSyncedAt,
    Map<String, dynamic>? planData,
    String? thumbnailPath,
    String? source,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FloorPlan(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      walkthroughId: walkthroughId ?? this.walkthroughId,
      jobId: jobId ?? this.jobId,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      floorLevel: floorLevel ?? this.floorLevel,
      floorNumber: floorNumber ?? this.floorNumber,
      status: status ?? this.status,
      syncVersion: syncVersion ?? this.syncVersion,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      planData: planData ?? this.planData,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static FloorPlanStatus _parseStatus(String? value) {
    if (value == null) return FloorPlanStatus.draft;
    return FloorPlanStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => FloorPlanStatus.draft,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
