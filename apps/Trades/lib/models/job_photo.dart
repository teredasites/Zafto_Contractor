import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Photo type classification
enum PhotoType {
  before,      // Before work photos
  during,      // Progress photos
  after,       // Completed work photos
  issue,       // Problem/violation documentation
  equipment,   // Equipment/material photos
  signature,   // Customer signature capture
  permit,      // Permit documentation
  invoice,     // Signed invoice
  other,       // General photos
}

/// Photo annotation for marking up images
class PhotoAnnotation extends Equatable {
  final String id;
  final String type; // 'arrow', 'circle', 'text', 'line'
  final double x;
  final double y;
  final double? x2; // For lines/arrows
  final double? y2;
  final String? text;
  final String color;

  const PhotoAnnotation({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.x2,
    this.y2,
    this.text,
    this.color = '#FFD700', // Default yellow
  });

  @override
  List<Object?> get props => [id, type, x, y, x2, y2, text, color];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'x2': x2,
      'y2': y2,
      'text': text,
      'color': color,
    };
  }

  factory PhotoAnnotation.fromMap(Map<String, dynamic> map) {
    return PhotoAnnotation(
      id: map['id'] as String,
      type: map['type'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      x2: (map['x2'] as num?)?.toDouble(),
      y2: (map['y2'] as num?)?.toDouble(),
      text: map['text'] as String?,
      color: map['color'] as String? ?? '#FFD700',
    );
  }
}

/// Job photo model for documentation
class JobPhoto extends Equatable {
  final String id;
  final String companyId;
  final String jobId;
  final String uploadedByUserId;

  // File info
  final String fileName;
  final String storageUrl;       // Cloud Storage URL
  final String? thumbnailUrl;    // Thumbnail for list views
  final int fileSize;            // Bytes
  final String mimeType;

  // Classification
  final PhotoType type;
  final String? caption;
  final String? notes;

  // Location (where photo was taken)
  final double? latitude;
  final double? longitude;

  // Annotations (markup on photo)
  final List<PhotoAnnotation> annotations;

  // AI Analysis results
  final String? aiAnalysis;      // Claude's analysis of the photo
  final List<String>? detectedIssues;
  final List<String>? detectedEquipment;

  // Metadata
  final DateTime takenAt;        // When photo was captured
  final DateTime uploadedAt;
  final bool isPrivate;          // Hidden from customer view

  const JobPhoto({
    required this.id,
    required this.companyId,
    required this.jobId,
    required this.uploadedByUserId,
    required this.fileName,
    required this.storageUrl,
    this.thumbnailUrl,
    required this.fileSize,
    this.mimeType = 'image/jpeg',
    required this.type,
    this.caption,
    this.notes,
    this.latitude,
    this.longitude,
    this.annotations = const [],
    this.aiAnalysis,
    this.detectedIssues,
    this.detectedEquipment,
    required this.takenAt,
    required this.uploadedAt,
    this.isPrivate = false,
  });

  @override
  List<Object?> get props => [id, jobId, storageUrl, uploadedAt];

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Get display label for photo type
  String get typeLabel {
    switch (type) {
      case PhotoType.before:
        return 'Before';
      case PhotoType.during:
        return 'During';
      case PhotoType.after:
        return 'After';
      case PhotoType.issue:
        return 'Issue';
      case PhotoType.equipment:
        return 'Equipment';
      case PhotoType.signature:
        return 'Signature';
      case PhotoType.permit:
        return 'Permit';
      case PhotoType.invoice:
        return 'Invoice';
      case PhotoType.other:
        return 'Photo';
    }
  }

  /// Check if photo has annotations
  bool get hasAnnotations => annotations.isNotEmpty;

  /// Check if photo has AI analysis
  bool get hasAiAnalysis => aiAnalysis != null && aiAnalysis!.isNotEmpty;

  /// Check if photo has location data
  bool get hasLocation => latitude != null && longitude != null;

  /// File size in human readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'jobId': jobId,
      'uploadedByUserId': uploadedByUserId,
      'fileName': fileName,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'type': type.name,
      'caption': caption,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'annotations': annotations.map((a) => a.toMap()).toList(),
      'aiAnalysis': aiAnalysis,
      'detectedIssues': detectedIssues,
      'detectedEquipment': detectedEquipment,
      'takenAt': takenAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'isPrivate': isPrivate,
    };
  }

  factory JobPhoto.fromMap(Map<String, dynamic> map) {
    return JobPhoto(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      jobId: map['jobId'] as String,
      uploadedByUserId: map['uploadedByUserId'] as String,
      fileName: map['fileName'] as String,
      storageUrl: map['storageUrl'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      fileSize: map['fileSize'] as int? ?? 0,
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      type: PhotoType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PhotoType.other,
      ),
      caption: map['caption'] as String?,
      notes: map['notes'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      annotations: (map['annotations'] as List<dynamic>?)
              ?.map((a) => PhotoAnnotation.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      aiAnalysis: map['aiAnalysis'] as String?,
      detectedIssues: (map['detectedIssues'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      detectedEquipment: (map['detectedEquipment'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      takenAt: _parseDateTime(map['takenAt']),
      uploadedAt: _parseDateTime(map['uploadedAt']),
      isPrivate: map['isPrivate'] as bool? ?? false,
    );
  }

  factory JobPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobPhoto.fromMap({...data, 'id': doc.id});
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  JobPhoto copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? uploadedByUserId,
    String? fileName,
    String? storageUrl,
    String? thumbnailUrl,
    int? fileSize,
    String? mimeType,
    PhotoType? type,
    String? caption,
    String? notes,
    double? latitude,
    double? longitude,
    List<PhotoAnnotation>? annotations,
    String? aiAnalysis,
    List<String>? detectedIssues,
    List<String>? detectedEquipment,
    DateTime? takenAt,
    DateTime? uploadedAt,
    bool? isPrivate,
  }) {
    return JobPhoto(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      fileName: fileName ?? this.fileName,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      annotations: annotations ?? this.annotations,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      detectedIssues: detectedIssues ?? this.detectedIssues,
      detectedEquipment: detectedEquipment ?? this.detectedEquipment,
      takenAt: takenAt ?? this.takenAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
