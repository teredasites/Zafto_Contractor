// ZAFTO Floor Plan Model — Supabase Backend
// Maps to `property_floor_plans` table. Stores floor plan sketches
// with wall/door/window/fixture data per floor level.

class FloorPlan {
  final String id;
  final String companyId;
  final String? propertyId;
  final String? walkthroughId;
  final String name;
  final int floorLevel;
  final Map<String, dynamic> planData;
  final String? thumbnailPath;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FloorPlan({
    this.id = '',
    this.companyId = '',
    this.propertyId,
    this.walkthroughId,
    this.name = '',
    this.floorLevel = 1,
    this.planData = const {},
    this.thumbnailPath,
    this.source = 'manual_sketch',
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (propertyId != null) 'property_id': propertyId,
        if (walkthroughId != null) 'walkthrough_id': walkthroughId,
        'name': name,
        'floor_level': floorLevel,
        'plan_data': planData,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
        'source': source,
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'floor_level': floorLevel,
        'plan_data': planData,
        'thumbnail_path': thumbnailPath,
        'source': source,
        'metadata': metadata,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    return FloorPlan(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      propertyId: json['property_id'] as String?,
      walkthroughId: json['walkthrough_id'] as String?,
      name: json['name'] as String? ?? '',
      floorLevel: json['floor_level'] as int? ?? 1,
      planData: (json['plan_data'] as Map<String, dynamic>?) ?? const {},
      thumbnailPath: json['thumbnail_path'] as String?,
      source: json['source'] as String? ?? 'manual_sketch',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  FloorPlan copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? walkthroughId,
    String? name,
    int? floorLevel,
    Map<String, dynamic>? planData,
    String? thumbnailPath,
    String? source,
    Map<String, dynamic>? metadata,
  }) {
    return FloorPlan(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      walkthroughId: walkthroughId ?? this.walkthroughId,
      name: name ?? this.name,
      floorLevel: floorLevel ?? this.floorLevel,
      planData: planData ?? this.planData,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
