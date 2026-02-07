// ZAFTO Drying Log Model — Supabase Backend
// Maps to `drying_logs` table. Immutable timestamped entries (legal compliance).
// INSERT-ONLY — no update/delete allowed.

enum DryingLogType {
  setup,
  daily,
  adjustment,
  equipmentChange,
  completion,
  note;

  String get dbValue {
    switch (this) {
      case DryingLogType.setup:
        return 'setup';
      case DryingLogType.daily:
        return 'daily';
      case DryingLogType.adjustment:
        return 'adjustment';
      case DryingLogType.equipmentChange:
        return 'equipment_change';
      case DryingLogType.completion:
        return 'completion';
      case DryingLogType.note:
        return 'note';
    }
  }

  String get label {
    switch (this) {
      case DryingLogType.setup:
        return 'Setup';
      case DryingLogType.daily:
        return 'Daily Check';
      case DryingLogType.adjustment:
        return 'Adjustment';
      case DryingLogType.equipmentChange:
        return 'Equipment Change';
      case DryingLogType.completion:
        return 'Completion';
      case DryingLogType.note:
        return 'Note';
    }
  }

  static DryingLogType fromString(String? value) {
    if (value == null) return DryingLogType.daily;
    switch (value) {
      case 'setup':
        return DryingLogType.setup;
      case 'daily':
        return DryingLogType.daily;
      case 'adjustment':
        return DryingLogType.adjustment;
      case 'equipment_change':
        return DryingLogType.equipmentChange;
      case 'completion':
        return DryingLogType.completion;
      case 'note':
        return DryingLogType.note;
      default:
        return DryingLogType.daily;
    }
  }
}

class DryingLog {
  final String id;
  final String companyId;
  final String jobId;
  final String? claimId;
  final DryingLogType logType;
  final String summary;
  final String? details;
  final int equipmentCount;
  final int dehumidifiersRunning;
  final int airMoversRunning;
  final int airScrubbersRunning;
  final double? outdoorTempF;
  final double? outdoorHumidity;
  final double? indoorTempF;
  final double? indoorHumidity;
  final List<Map<String, dynamic>> photos;
  final String? recordedByUserId;
  final DateTime recordedAt;
  final DateTime createdAt;

  const DryingLog({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.claimId,
    this.logType = DryingLogType.daily,
    required this.summary,
    this.details,
    this.equipmentCount = 0,
    this.dehumidifiersRunning = 0,
    this.airMoversRunning = 0,
    this.airScrubbersRunning = 0,
    this.outdoorTempF,
    this.outdoorHumidity,
    this.indoorTempF,
    this.indoorHumidity,
    this.photos = const [],
    this.recordedByUserId,
    required this.recordedAt,
    required this.createdAt,
  });

  // INSERT-ONLY — no toUpdateJson (immutable legal record)
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        if (claimId != null) 'claim_id': claimId,
        'log_type': logType.dbValue,
        'summary': summary,
        if (details != null) 'details': details,
        'equipment_count': equipmentCount,
        'dehumidifiers_running': dehumidifiersRunning,
        'air_movers_running': airMoversRunning,
        'air_scrubbers_running': airScrubbersRunning,
        if (outdoorTempF != null) 'outdoor_temp_f': outdoorTempF,
        if (outdoorHumidity != null) 'outdoor_humidity': outdoorHumidity,
        if (indoorTempF != null) 'indoor_temp_f': indoorTempF,
        if (indoorHumidity != null) 'indoor_humidity': indoorHumidity,
        'photos': photos,
        if (recordedByUserId != null) 'recorded_by_user_id': recordedByUserId,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  factory DryingLog.fromJson(Map<String, dynamic> json) {
    return DryingLog(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      claimId: json['claim_id'] as String?,
      logType: DryingLogType.fromString(json['log_type'] as String?),
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String?,
      equipmentCount: json['equipment_count'] as int? ?? 0,
      dehumidifiersRunning: json['dehumidifiers_running'] as int? ?? 0,
      airMoversRunning: json['air_movers_running'] as int? ?? 0,
      airScrubbersRunning: json['air_scrubbers_running'] as int? ?? 0,
      outdoorTempF: (json['outdoor_temp_f'] as num?)?.toDouble(),
      outdoorHumidity: (json['outdoor_humidity'] as num?)?.toDouble(),
      indoorTempF: (json['indoor_temp_f'] as num?)?.toDouble(),
      indoorHumidity: (json['indoor_humidity'] as num?)?.toDouble(),
      photos: _parseJsonList(json['photos']),
      recordedByUserId: json['recorded_by_user_id'] as String?,
      recordedAt: _parseDate(json['recorded_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  int get totalEquipmentRunning =>
      dehumidifiersRunning + airMoversRunning + airScrubbersRunning;
  bool get isCompletion => logType == DryingLogType.completion;
  bool get isSetup => logType == DryingLogType.setup;

  static List<Map<String, dynamic>> _parseJsonList(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList();
    }
    return const [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
