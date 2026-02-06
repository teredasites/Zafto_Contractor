// ZAFTO Photo Model — Supabase Backend
// Maps to `photos` table in Supabase PostgreSQL.

enum PhotoCategory {
  general,
  before,
  after,
  defect,
  markup,
  receipt,
  inspection,
  completion;

  String get dbValue => name;

  String get label {
    switch (this) {
      case PhotoCategory.general:
        return 'General';
      case PhotoCategory.before:
        return 'Before';
      case PhotoCategory.after:
        return 'After';
      case PhotoCategory.defect:
        return 'Defect';
      case PhotoCategory.markup:
        return 'Markup';
      case PhotoCategory.receipt:
        return 'Receipt';
      case PhotoCategory.inspection:
        return 'Inspection';
      case PhotoCategory.completion:
        return 'Completion';
    }
  }

  static PhotoCategory fromString(String? value) {
    if (value == null) return PhotoCategory.general;
    return PhotoCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PhotoCategory.general,
    );
  }
}

class Photo {
  final String id;
  final String companyId;
  final String? jobId;
  final String uploadedByUserId;
  final String storagePath;
  final String? thumbnailPath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final PhotoCategory category;
  final String? caption;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final bool isClientVisible;
  final DateTime? takenAt;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Photo({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.uploadedByUserId = '',
    this.storagePath = '',
    this.thumbnailPath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.category = PhotoCategory.general,
    this.caption,
    this.tags = const [],
    this.metadata = const {},
    this.isClientVisible = false,
    this.takenAt,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.deletedAt,
  });

  // Supabase INSERT — omit id, created_at, deleted_at (DB defaults)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'uploaded_by_user_id': uploadedByUserId,
        'storage_path': storagePath,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
        if (fileName != null) 'file_name': fileName,
        if (fileSize != null) 'file_size': fileSize,
        if (mimeType != null) 'mime_type': mimeType,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'category': category.dbValue,
        if (caption != null) 'caption': caption,
        'tags': tags,
        'metadata': metadata,
        'is_client_visible': isClientVisible,
        if (takenAt != null) 'taken_at': takenAt!.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

  // Supabase UPDATE — omit id, company_id, uploaded_by_user_id, created_at
  Map<String, dynamic> toUpdateJson() => {
        if (jobId != null) 'job_id': jobId,
        if (caption != null) 'caption': caption,
        'tags': tags,
        'metadata': metadata,
        'is_client_visible': isClientVisible,
        'category': category.dbValue,
      };

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ??
          json['companyId'] as String? ??
          '',
      jobId: json['job_id'] as String? ?? json['jobId'] as String?,
      uploadedByUserId: json['uploaded_by_user_id'] as String? ??
          json['uploadedByUserId'] as String? ??
          '',
      storagePath: json['storage_path'] as String? ??
          json['storagePath'] as String? ??
          '',
      thumbnailPath: json['thumbnail_path'] as String? ??
          json['thumbnailPath'] as String?,
      fileName:
          json['file_name'] as String? ?? json['fileName'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt() ??
          (json['fileSize'] as num?)?.toInt(),
      mimeType:
          json['mime_type'] as String? ?? json['mimeType'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      category: PhotoCategory.fromString(
          json['category'] as String? ?? 'general'),
      caption: json['caption'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
      isClientVisible: json['is_client_visible'] as bool? ??
          json['isClientVisible'] as bool? ??
          false,
      takenAt: _parseOptionalDate(json['taken_at'] ?? json['takenAt']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      deletedAt:
          _parseOptionalDate(json['deleted_at'] ?? json['deletedAt']),
    );
  }

  Photo copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? uploadedByUserId,
    String? storagePath,
    String? thumbnailPath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    PhotoCategory? category,
    String? caption,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isClientVisible,
    DateTime? takenAt,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Photo(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      storagePath: storagePath ?? this.storagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      category: category ?? this.category,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isClientVisible: isClientVisible ?? this.isClientVisible,
      takenAt: takenAt ?? this.takenAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Computed properties
  bool get hasLocation => latitude != null && longitude != null;
  bool get hasThumbnail => thumbnailPath != null && thumbnailPath!.isNotEmpty;
  bool get isDeleted => deletedAt != null;

  String get displayName {
    if (caption != null && caption!.isNotEmpty) return caption!;
    if (fileName != null && fileName!.isNotEmpty) return fileName!;
    return '${category.name} photo';
  }

  String get categoryLabel {
    switch (category) {
      case PhotoCategory.general:
        return 'General';
      case PhotoCategory.before:
        return 'Before';
      case PhotoCategory.after:
        return 'After';
      case PhotoCategory.defect:
        return 'Defect';
      case PhotoCategory.markup:
        return 'Markup';
      case PhotoCategory.receipt:
        return 'Receipt';
      case PhotoCategory.inspection:
        return 'Inspection';
      case PhotoCategory.completion:
        return 'Completion';
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
