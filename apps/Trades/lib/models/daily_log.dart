// ZAFTO Daily Log Model — Supabase Backend
// Maps to `daily_logs` table in Supabase PostgreSQL.
// One log per job per day. Tracks weather, work performed, issues, crew.

class DailyLog {
  final String id;
  final String companyId;
  final String jobId;
  final String authorUserId;
  final DateTime logDate;
  final String? weather;
  final int? temperatureF;
  final String summary;
  final String? workPerformed;
  final String? issues;
  final String? delays;
  final String? visitors;
  final List<String> crewMembers;
  final int crewCount;
  final double? hoursWorked;
  final List<String> photoIds;
  final String? safetyNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyLog({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.authorUserId = '',
    required this.logDate,
    this.weather,
    this.temperatureF,
    this.summary = '',
    this.workPerformed,
    this.issues,
    this.delays,
    this.visitors,
    this.crewMembers = const [],
    this.crewCount = 1,
    this.hoursWorked,
    this.photoIds = const [],
    this.safetyNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Supabase INSERT — omit id, created_at, updated_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'author_user_id': authorUserId,
        'log_date': _formatDate(logDate),
        if (weather != null) 'weather': weather,
        if (temperatureF != null) 'temperature_f': temperatureF,
        'summary': summary,
        if (workPerformed != null) 'work_performed': workPerformed,
        if (issues != null) 'issues': issues,
        if (delays != null) 'delays': delays,
        if (visitors != null) 'visitors': visitors,
        'crew_members': crewMembers,
        'crew_count': crewCount,
        if (hoursWorked != null) 'hours_worked': hoursWorked,
        'photo_ids': photoIds,
        if (safetyNotes != null) 'safety_notes': safetyNotes,
      };

  // Supabase UPDATE — all editable fields.
  Map<String, dynamic> toUpdateJson() => {
        'weather': weather,
        'temperature_f': temperatureF,
        'summary': summary,
        'work_performed': workPerformed,
        'issues': issues,
        'delays': delays,
        'visitors': visitors,
        'crew_members': crewMembers,
        'crew_count': crewCount,
        'hours_worked': hoursWorked,
        'photo_ids': photoIds,
        'safety_notes': safetyNotes,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      authorUserId: json['author_user_id'] as String? ?? '',
      logDate: _parseDateOnly(json['log_date']),
      weather: json['weather'] as String?,
      temperatureF: json['temperature_f'] as int?,
      summary: json['summary'] as String? ?? '',
      workPerformed: json['work_performed'] as String?,
      issues: json['issues'] as String?,
      delays: json['delays'] as String?,
      visitors: json['visitors'] as String?,
      crewMembers: (json['crew_members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      crewCount: json['crew_count'] as int? ?? 1,
      hoursWorked: (json['hours_worked'] as num?)?.toDouble(),
      photoIds: (json['photo_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      safetyNotes: json['safety_notes'] as String?,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  DailyLog copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? authorUserId,
    DateTime? logDate,
    String? weather,
    int? temperatureF,
    String? summary,
    String? workPerformed,
    String? issues,
    String? delays,
    String? visitors,
    List<String>? crewMembers,
    int? crewCount,
    double? hoursWorked,
    List<String>? photoIds,
    String? safetyNotes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      authorUserId: authorUserId ?? this.authorUserId,
      logDate: logDate ?? this.logDate,
      weather: weather ?? this.weather,
      temperatureF: temperatureF ?? this.temperatureF,
      summary: summary ?? this.summary,
      workPerformed: workPerformed ?? this.workPerformed,
      issues: issues ?? this.issues,
      delays: delays ?? this.delays,
      visitors: visitors ?? this.visitors,
      crewMembers: crewMembers ?? this.crewMembers,
      crewCount: crewCount ?? this.crewCount,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      photoIds: photoIds ?? this.photoIds,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isNew => id.isEmpty;
  bool get hasIssues => issues != null && issues!.isNotEmpty;
  bool get hasDelays => delays != null && delays!.isNotEmpty;

  // Format date as YYYY-MM-DD for Supabase date column.
  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDateOnly(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString();
    // Handle "YYYY-MM-DD" (date only) and full timestamps
    return DateTime.tryParse(str) ?? DateTime.now();
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
