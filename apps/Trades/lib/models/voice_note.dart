// ZAFTO Voice Note Model — Supabase Backend
// Maps to `voice_notes` table in Supabase PostgreSQL.
// Stores audio recordings linked to jobs with optional transcription.

enum TranscriptionStatus {
  pending,
  processing,
  completed,
  failed;

  String get dbValue => name;

  static TranscriptionStatus fromString(String? value) {
    if (value == null) return TranscriptionStatus.pending;
    return TranscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TranscriptionStatus.pending,
    );
  }
}

class VoiceNote {
  final String id;
  final String companyId;
  final String? jobId;
  final String recordedByUserId;
  final String storagePath;
  final int? durationSeconds;
  final int? fileSize;
  final String? transcription;
  final TranscriptionStatus transcriptionStatus;
  final List<String> tags;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const VoiceNote({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.recordedByUserId = '',
    this.storagePath = '',
    this.durationSeconds,
    this.fileSize,
    this.transcription,
    this.transcriptionStatus = TranscriptionStatus.pending,
    this.tags = const [],
    required this.recordedAt,
    DateTime? createdAt,
    this.deletedAt,
  }) : createdAt = createdAt ?? recordedAt;

  // Supabase INSERT — omit id, created_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'recorded_by_user_id': recordedByUserId,
        'storage_path': storagePath,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (fileSize != null) 'file_size': fileSize,
        if (transcription != null) 'transcription': transcription,
        'transcription_status': transcriptionStatus.dbValue,
        'tags': tags,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      recordedByUserId: json['recorded_by_user_id'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int?,
      fileSize: json['file_size'] as int?,
      transcription: json['transcription'] as String?,
      transcriptionStatus: TranscriptionStatus.fromString(
        json['transcription_status'] as String?,
      ),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recordedAt: _parseDate(json['recorded_at']),
      createdAt: _parseDate(json['created_at']),
      deletedAt: _parseOptionalDate(json['deleted_at']),
    );
  }

  VoiceNote copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? recordedByUserId,
    String? storagePath,
    int? durationSeconds,
    int? fileSize,
    String? transcription,
    TranscriptionStatus? transcriptionStatus,
    List<String>? tags,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return VoiceNote(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      recordedByUserId: recordedByUserId ?? this.recordedByUserId,
      storagePath: storagePath ?? this.storagePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSize: fileSize ?? this.fileSize,
      transcription: transcription ?? this.transcription,
      transcriptionStatus: transcriptionStatus ?? this.transcriptionStatus,
      tags: tags ?? this.tags,
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  bool get hasTranscription =>
      transcription != null && transcription!.isNotEmpty;
  bool get isTranscribed =>
      transcriptionStatus == TranscriptionStatus.completed;
  bool get isDeleted => deletedAt != null;

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
