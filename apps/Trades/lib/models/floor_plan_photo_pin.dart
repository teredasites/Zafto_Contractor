// ZAFTO Floor Plan Photo Pin Model — Supabase Backend
// Maps to `floor_plan_photo_pins` table. Links photos to specific (x,y)
// locations on floor plans for walkthrough documentation and damage mapping.

enum PinType { photo, damage, note, measurement, before, after }

class FloorPlanPhotoPin {
  final String id;
  final String floorPlanId;
  final String companyId;
  final String? photoId;
  final String? photoPath;
  final double positionX;
  final double positionY;
  final String? roomId;
  final String? label;
  final PinType pinType;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FloorPlanPhotoPin({
    this.id = '',
    required this.floorPlanId,
    required this.companyId,
    this.photoId,
    this.photoPath,
    required this.positionX,
    required this.positionY,
    this.roomId,
    this.label,
    this.pinType = PinType.photo,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed
  String get displayLabel => label ?? _pinTypeLabel(pinType);
  bool get hasPhoto => photoPath != null || photoId != null;

  static String _pinTypeLabel(PinType type) {
    switch (type) {
      case PinType.photo:
        return 'Photo';
      case PinType.damage:
        return 'Damage';
      case PinType.note:
        return 'Note';
      case PinType.measurement:
        return 'Measurement';
      case PinType.before:
        return 'Before';
      case PinType.after:
        return 'After';
    }
  }

  Map<String, dynamic> toInsertJson() => {
        'floor_plan_id': floorPlanId,
        'company_id': companyId,
        if (photoId != null) 'photo_id': photoId,
        if (photoPath != null) 'photo_path': photoPath,
        'position_x': positionX,
        'position_y': positionY,
        if (roomId != null) 'room_id': roomId,
        if (label != null) 'label': label,
        'pin_type': pinType.name,
        if (createdBy != null) 'created_by': createdBy,
      };

  factory FloorPlanPhotoPin.fromJson(Map<String, dynamic> json) {
    return FloorPlanPhotoPin(
      id: json['id'] as String? ?? '',
      floorPlanId: json['floor_plan_id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      photoId: json['photo_id'] as String?,
      photoPath: json['photo_path'] as String?,
      positionX: _parseDouble(json['position_x']) ?? 0.0,
      positionY: _parseDouble(json['position_y']) ?? 0.0,
      roomId: json['room_id'] as String?,
      label: json['label'] as String?,
      pinType: _parsePinType(json['pin_type'] as String?),
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  FloorPlanPhotoPin copyWith({
    String? id,
    String? floorPlanId,
    String? companyId,
    String? photoId,
    String? photoPath,
    double? positionX,
    double? positionY,
    String? roomId,
    String? label,
    PinType? pinType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FloorPlanPhotoPin(
      id: id ?? this.id,
      floorPlanId: floorPlanId ?? this.floorPlanId,
      companyId: companyId ?? this.companyId,
      photoId: photoId ?? this.photoId,
      photoPath: photoPath ?? this.photoPath,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      roomId: roomId ?? this.roomId,
      label: label ?? this.label,
      pinType: pinType ?? this.pinType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PinType _parsePinType(String? value) {
    if (value == null) return PinType.photo;
    return PinType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PinType.photo,
    );
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
}
