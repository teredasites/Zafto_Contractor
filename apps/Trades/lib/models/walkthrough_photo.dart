// ZAFTO Walkthrough Photo Model — Supabase Backend
// Maps to `walkthrough_photos` table. Each photo belongs to a walkthrough
// and optionally a room. Supports captions, annotations, GPS data, and AI analysis.

class WalkthroughPhoto {
  final String id;
  final String walkthroughId;
  final String? roomId;
  final String storagePath;
  final String? thumbnailPath;
  final String? caption;
  final String photoType;
  final Map<String, dynamic>? annotations;
  final Map<String, dynamic>? aiAnalysis;
  final int? sortOrder;
  final Map<String, dynamic> metadata;

  // GPS & sensor data
  final double? gpsLatitude;
  final double? gpsLongitude;
  final double? compassHeading;
  final double? altitude;
  final double? accuracy;
  final String? floorLevel;

  final DateTime createdAt;

  const WalkthroughPhoto({
    this.id = '',
    this.walkthroughId = '',
    this.roomId,
    this.storagePath = '',
    this.thumbnailPath,
    this.caption,
    this.photoType = 'overview',
    this.annotations,
    this.aiAnalysis,
    this.sortOrder,
    this.metadata = const {},
    this.gpsLatitude,
    this.gpsLongitude,
    this.compassHeading,
    this.altitude,
    this.accuracy,
    this.floorLevel,
    required this.createdAt,
  });

  /// Whether this photo has valid GPS coordinates
  bool get hasGps => gpsLatitude != null && gpsLongitude != null;

  Map<String, dynamic> toInsertJson() => {
        'walkthrough_id': walkthroughId,
        if (roomId != null) 'room_id': roomId,
        'storage_path': storagePath,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
        if (caption != null) 'caption': caption,
        'photo_type': photoType,
        if (annotations != null) 'annotations': annotations,
        if (aiAnalysis != null) 'ai_analysis': aiAnalysis,
        if (sortOrder != null) 'sort_order': sortOrder,
        'metadata': metadata,
        if (gpsLatitude != null) 'gps_latitude': gpsLatitude,
        if (gpsLongitude != null) 'gps_longitude': gpsLongitude,
        if (compassHeading != null) 'compass_heading': compassHeading,
        if (altitude != null) 'altitude': altitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (floorLevel != null) 'floor_level': floorLevel,
      };

  factory WalkthroughPhoto.fromJson(Map<String, dynamic> json) {
    return WalkthroughPhoto(
      id: json['id'] as String? ?? '',
      walkthroughId: json['walkthrough_id'] as String? ?? '',
      roomId: json['room_id'] as String?,
      storagePath: json['storage_path'] as String? ?? '',
      thumbnailPath: json['thumbnail_path'] as String?,
      caption: json['caption'] as String?,
      photoType: json['photo_type'] as String? ?? 'overview',
      annotations: json['annotations'] as Map<String, dynamic>?,
      aiAnalysis: json['ai_analysis'] as Map<String, dynamic>?,
      sortOrder: json['sort_order'] as int?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      gpsLatitude: (json['gps_latitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gps_longitude'] as num?)?.toDouble(),
      compassHeading: (json['compass_heading'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      floorLevel: json['floor_level'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  WalkthroughPhoto copyWith({
    String? id,
    String? walkthroughId,
    String? roomId,
    String? storagePath,
    String? thumbnailPath,
    String? caption,
    String? photoType,
    Map<String, dynamic>? annotations,
    Map<String, dynamic>? aiAnalysis,
    int? sortOrder,
    Map<String, dynamic>? metadata,
    double? gpsLatitude,
    double? gpsLongitude,
    double? compassHeading,
    double? altitude,
    double? accuracy,
    String? floorLevel,
  }) {
    return WalkthroughPhoto(
      id: id ?? this.id,
      walkthroughId: walkthroughId ?? this.walkthroughId,
      roomId: roomId ?? this.roomId,
      storagePath: storagePath ?? this.storagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      caption: caption ?? this.caption,
      photoType: photoType ?? this.photoType,
      annotations: annotations ?? this.annotations,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      compassHeading: compassHeading ?? this.compassHeading,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      floorLevel: floorLevel ?? this.floorLevel,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
