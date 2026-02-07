// ZAFTO Walkthrough Room Model — Supabase Backend
// Maps to `walkthrough_rooms` table. Each room belongs to a walkthrough
// and tracks dimensions, condition, photos, and completion status.

// Helper class for dimensions JSONB
class RoomDimensions {
  final double? length;
  final double? width;
  final double? height;
  final double? area;
  final double? perimeter;

  const RoomDimensions({
    this.length,
    this.width,
    this.height,
    this.area,
    this.perimeter,
  });

  // Computed: calculate area from length x width if not explicitly set
  double? get computedArea {
    if (area != null) return area;
    if (length != null && width != null) return length! * width!;
    return null;
  }

  // Computed: calculate perimeter from 2*(length + width) if not set
  double? get computedPerimeter {
    if (perimeter != null) return perimeter;
    if (length != null && width != null) return 2 * (length! + width!);
    return null;
  }

  Map<String, dynamic> toJson() => {
        if (length != null) 'length': length,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (area != null) 'area': area,
        if (perimeter != null) 'perimeter': perimeter,
      };

  factory RoomDimensions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RoomDimensions();
    return RoomDimensions(
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      area: (json['area'] as num?)?.toDouble(),
      perimeter: (json['perimeter'] as num?)?.toDouble(),
    );
  }

  RoomDimensions copyWith({
    double? length,
    double? width,
    double? height,
    double? area,
    double? perimeter,
  }) {
    return RoomDimensions(
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
    );
  }
}

class WalkthroughRoom {
  final String id;
  final String walkthroughId;
  final String name;
  final String roomType;
  final int floorLevel;
  final int? sortOrder;
  final RoomDimensions dimensions;
  final int? conditionRating;
  final String? notes;
  final Map<String, dynamic> customFields;
  final List<String> tags;
  final String status;
  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalkthroughRoom({
    this.id = '',
    this.walkthroughId = '',
    this.name = '',
    this.roomType = 'other',
    this.floorLevel = 1,
    this.sortOrder,
    this.dimensions = const RoomDimensions(),
    this.conditionRating,
    this.notes,
    this.customFields = const {},
    this.tags = const [],
    this.status = 'pending',
    this.photoCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'walkthrough_id': walkthroughId,
        'name': name,
        'room_type': roomType,
        'floor_level': floorLevel,
        if (sortOrder != null) 'sort_order': sortOrder,
        'dimensions': dimensions.toJson(),
        if (conditionRating != null) 'condition_rating': conditionRating,
        if (notes != null) 'notes': notes,
        'custom_fields': customFields,
        'tags': tags,
        'status': status,
        'photo_count': photoCount,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'room_type': roomType,
        'floor_level': floorLevel,
        'sort_order': sortOrder,
        'dimensions': dimensions.toJson(),
        'condition_rating': conditionRating,
        'notes': notes,
        'custom_fields': customFields,
        'tags': tags,
        'status': status,
        'photo_count': photoCount,
        'updated_at': DateTime.now().toIso8601String(),
      };

  factory WalkthroughRoom.fromJson(Map<String, dynamic> json) {
    return WalkthroughRoom(
      id: json['id'] as String? ?? '',
      walkthroughId: json['walkthrough_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      roomType: json['room_type'] as String? ?? 'other',
      floorLevel: json['floor_level'] as int? ?? 1,
      sortOrder: json['sort_order'] as int?,
      dimensions: RoomDimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>?,
      ),
      conditionRating: json['condition_rating'] as int?,
      notes: json['notes'] as String?,
      customFields:
          (json['custom_fields'] as Map<String, dynamic>?) ?? const {},
      tags: _parseTags(json['tags']),
      status: json['status'] as String? ?? 'pending',
      photoCount: json['photo_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  WalkthroughRoom copyWith({
    String? id,
    String? walkthroughId,
    String? name,
    String? roomType,
    int? floorLevel,
    int? sortOrder,
    RoomDimensions? dimensions,
    int? conditionRating,
    String? notes,
    Map<String, dynamic>? customFields,
    List<String>? tags,
    String? status,
    int? photoCount,
  }) {
    return WalkthroughRoom(
      id: id ?? this.id,
      walkthroughId: walkthroughId ?? this.walkthroughId,
      name: name ?? this.name,
      roomType: roomType ?? this.roomType,
      floorLevel: floorLevel ?? this.floorLevel,
      sortOrder: sortOrder ?? this.sortOrder,
      dimensions: dimensions ?? this.dimensions,
      conditionRating: conditionRating ?? this.conditionRating,
      notes: notes ?? this.notes,
      customFields: customFields ?? this.customFields,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      photoCount: photoCount ?? this.photoCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
