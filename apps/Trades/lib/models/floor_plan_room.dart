// ZAFTO Floor Plan Room Model — Supabase Backend
// Maps to `floor_plan_rooms` table. Rooms detected from wall boundaries
// or manually drawn, with computed measurements and IICRC damage data.

enum RoomType {
  room,
  bedroom,
  bathroom,
  kitchen,
  livingRoom,
  diningRoom,
  hallway,
  garage,
  attic,
  basement,
  closet,
  utility,
  laundry,
  office,
}

enum DamageClass { one, two, three, four }

enum IicrcCategory { one, two, three }

class FloorPlanRoom {
  final String id;
  final String floorPlanId;
  final String companyId;
  final String name;
  final RoomType roomType;
  final List<Map<String, dynamic>> boundaryPoints;
  final List<String> boundaryWallIds;
  final double floorAreaSf;
  final double wallAreaSf;
  final double perimeterLf;
  final int ceilingHeightInches;
  final String? floorMaterial;
  final DamageClass? damageClass;
  final IicrcCategory? iicrcCategory;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const FloorPlanRoom({
    this.id = '',
    required this.floorPlanId,
    required this.companyId,
    this.name = 'Room',
    this.roomType = RoomType.room,
    this.boundaryPoints = const [],
    this.boundaryWallIds = const [],
    this.floorAreaSf = 0,
    this.wallAreaSf = 0,
    this.perimeterLf = 0,
    this.ceilingHeightInches = 96,
    this.floorMaterial,
    this.damageClass,
    this.iicrcCategory,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Computed
  double get ceilingHeightFt => ceilingHeightInches / 12.0;
  double get ceilingAreaSf => floorAreaSf;
  double get totalSurfaceAreaSf => floorAreaSf + ceilingAreaSf + wallAreaSf;
  bool get hasDamage => damageClass != null || iicrcCategory != null;

  String get roomTypeLabel {
    switch (roomType) {
      case RoomType.room:
        return 'Room';
      case RoomType.bedroom:
        return 'Bedroom';
      case RoomType.bathroom:
        return 'Bathroom';
      case RoomType.kitchen:
        return 'Kitchen';
      case RoomType.livingRoom:
        return 'Living Room';
      case RoomType.diningRoom:
        return 'Dining Room';
      case RoomType.hallway:
        return 'Hallway';
      case RoomType.garage:
        return 'Garage';
      case RoomType.attic:
        return 'Attic';
      case RoomType.basement:
        return 'Basement';
      case RoomType.closet:
        return 'Closet';
      case RoomType.utility:
        return 'Utility';
      case RoomType.laundry:
        return 'Laundry';
      case RoomType.office:
        return 'Office';
    }
  }

  Map<String, dynamic> toInsertJson() => {
        'floor_plan_id': floorPlanId,
        'company_id': companyId,
        'name': name,
        'room_type': _roomTypeToDb(roomType),
        'boundary_points': boundaryPoints,
        'boundary_wall_ids': boundaryWallIds,
        'floor_area_sf': floorAreaSf,
        'wall_area_sf': wallAreaSf,
        'perimeter_lf': perimeterLf,
        'ceiling_height_inches': ceilingHeightInches,
        if (floorMaterial != null) 'floor_material': floorMaterial,
        if (damageClass != null)
          'damage_class': _damageClassToDb(damageClass!),
        if (iicrcCategory != null)
          'iicrc_category': _iicrcCategoryToDb(iicrcCategory!),
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'room_type': _roomTypeToDb(roomType),
        'boundary_points': boundaryPoints,
        'boundary_wall_ids': boundaryWallIds,
        'floor_area_sf': floorAreaSf,
        'wall_area_sf': wallAreaSf,
        'perimeter_lf': perimeterLf,
        'ceiling_height_inches': ceilingHeightInches,
        'floor_material': floorMaterial,
        'damage_class':
            damageClass != null ? _damageClassToDb(damageClass!) : null,
        'iicrc_category':
            iicrcCategory != null ? _iicrcCategoryToDb(iicrcCategory!) : null,
        'metadata': metadata,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  factory FloorPlanRoom.fromJson(Map<String, dynamic> json) {
    return FloorPlanRoom(
      id: json['id'] as String? ?? '',
      floorPlanId: json['floor_plan_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Room',
      roomType: _parseRoomType(json['room_type'] as String?),
      boundaryPoints: _parsePointsList(json['boundary_points']),
      boundaryWallIds: _parseStringList(json['boundary_wall_ids']),
      floorAreaSf: _parseDouble(json['floor_area_sf']) ?? 0,
      wallAreaSf: _parseDouble(json['wall_area_sf']) ?? 0,
      perimeterLf: _parseDouble(json['perimeter_lf']) ?? 0,
      ceilingHeightInches: json['ceiling_height_inches'] as int? ?? 96,
      floorMaterial: json['floor_material'] as String?,
      damageClass: _parseDamageClass(json['damage_class'] as String?),
      iicrcCategory: _parseIicrcCategory(json['iicrc_category'] as String?),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  FloorPlanRoom copyWith({
    String? id,
    String? floorPlanId,
    String? companyId,
    String? name,
    RoomType? roomType,
    List<Map<String, dynamic>>? boundaryPoints,
    List<String>? boundaryWallIds,
    double? floorAreaSf,
    double? wallAreaSf,
    double? perimeterLf,
    int? ceilingHeightInches,
    String? floorMaterial,
    DamageClass? damageClass,
    IicrcCategory? iicrcCategory,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return FloorPlanRoom(
      id: id ?? this.id,
      floorPlanId: floorPlanId ?? this.floorPlanId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      roomType: roomType ?? this.roomType,
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
      boundaryWallIds: boundaryWallIds ?? this.boundaryWallIds,
      floorAreaSf: floorAreaSf ?? this.floorAreaSf,
      wallAreaSf: wallAreaSf ?? this.wallAreaSf,
      perimeterLf: perimeterLf ?? this.perimeterLf,
      ceilingHeightInches: ceilingHeightInches ?? this.ceilingHeightInches,
      floorMaterial: floorMaterial ?? this.floorMaterial,
      damageClass: damageClass ?? this.damageClass,
      iicrcCategory: iicrcCategory ?? this.iicrcCategory,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // DB mapping: room_type uses snake_case in DB
  static String _roomTypeToDb(RoomType type) {
    switch (type) {
      case RoomType.livingRoom:
        return 'living_room';
      case RoomType.diningRoom:
        return 'dining_room';
      default:
        return type.name;
    }
  }

  static RoomType _parseRoomType(String? value) {
    if (value == null) return RoomType.room;
    switch (value) {
      case 'living_room':
        return RoomType.livingRoom;
      case 'dining_room':
        return RoomType.diningRoom;
      default:
        return RoomType.values.firstWhere(
          (t) => t.name == value,
          orElse: () => RoomType.room,
        );
    }
  }

  static String _damageClassToDb(DamageClass dc) {
    switch (dc) {
      case DamageClass.one:
        return '1';
      case DamageClass.two:
        return '2';
      case DamageClass.three:
        return '3';
      case DamageClass.four:
        return '4';
    }
  }

  static DamageClass? _parseDamageClass(String? value) {
    switch (value) {
      case '1':
        return DamageClass.one;
      case '2':
        return DamageClass.two;
      case '3':
        return DamageClass.three;
      case '4':
        return DamageClass.four;
      default:
        return null;
    }
  }

  static String _iicrcCategoryToDb(IicrcCategory cat) {
    switch (cat) {
      case IicrcCategory.one:
        return '1';
      case IicrcCategory.two:
        return '2';
      case IicrcCategory.three:
        return '3';
    }
  }

  static IicrcCategory? _parseIicrcCategory(String? value) {
    switch (value) {
      case '1':
        return IicrcCategory.one;
      case '2':
        return IicrcCategory.two;
      case '3':
        return IicrcCategory.three;
      default:
        return null;
    }
  }

  static List<Map<String, dynamic>> _parsePointsList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    }
    return [];
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
