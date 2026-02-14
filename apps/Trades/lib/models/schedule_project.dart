// ZAFTO Schedule Project Model — Supabase Backend
// Maps to `schedule_projects` table. Project-level scheduling container.
// GC1: Phase GC foundation.

enum ScheduleProjectStatus { draft, active, onHold, complete, archived }

enum DurationUnit { hours, days, weeks }

class ScheduleProject {
  final String id;
  final String companyId;
  final String? jobId;
  final String name;
  final String? description;
  final ScheduleProjectStatus status;
  final DateTime? plannedStart;
  final DateTime? plannedFinish;
  final DateTime? actualStart;
  final DateTime? actualFinish;
  final DateTime? dataDate;
  final String? defaultCalendarId;
  final DurationUnit durationUnit;
  final double hoursPerDay;
  final String currency;
  final double overallPercentComplete;
  final Map<String, dynamic> metadata;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ScheduleProject({
    this.id = '',
    this.companyId = '',
    this.jobId,
    this.name = '',
    this.description,
    this.status = ScheduleProjectStatus.draft,
    this.plannedStart,
    this.plannedFinish,
    this.actualStart,
    this.actualFinish,
    this.dataDate,
    this.defaultCalendarId,
    this.durationUnit = DurationUnit.days,
    this.hoursPerDay = 8,
    this.currency = 'USD',
    this.overallPercentComplete = 0,
    this.metadata = const {},
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isActive => status == ScheduleProjectStatus.active;
  bool get isComplete => status == ScheduleProjectStatus.complete;
  bool get isEditable =>
      status != ScheduleProjectStatus.archived && deletedAt == null;

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        if (jobId != null) 'job_id': jobId,
        'name': name,
        if (description != null) 'description': description,
        'status': _statusToString(status),
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        if (defaultCalendarId != null) 'default_calendar_id': defaultCalendarId,
        'duration_unit': durationUnit.name,
        'hours_per_day': hoursPerDay,
        'currency': currency,
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        if (description != null) 'description': description,
        'status': _statusToString(status),
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        if (actualStart != null) 'actual_start': _dateString(actualStart!),
        if (actualFinish != null) 'actual_finish': _dateString(actualFinish!),
        if (dataDate != null) 'data_date': _dateString(dataDate!),
        if (defaultCalendarId != null) 'default_calendar_id': defaultCalendarId,
        'duration_unit': durationUnit.name,
        'hours_per_day': hoursPerDay,
        'overall_percent_complete': overallPercentComplete,
        'metadata': metadata,
      };

  factory ScheduleProject.fromJson(Map<String, dynamic> json) {
    return ScheduleProject(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String?),
      plannedStart: _parseDateNullable(json['planned_start']),
      plannedFinish: _parseDateNullable(json['planned_finish']),
      actualStart: _parseDateNullable(json['actual_start']),
      actualFinish: _parseDateNullable(json['actual_finish']),
      dataDate: _parseDateNullable(json['data_date']),
      defaultCalendarId: json['default_calendar_id'] as String?,
      durationUnit: _parseDurationUnit(json['duration_unit'] as String?),
      hoursPerDay: (json['hours_per_day'] as num?)?.toDouble() ?? 8,
      currency: json['currency'] as String? ?? 'USD',
      overallPercentComplete:
          (json['overall_percent_complete'] as num?)?.toDouble() ?? 0,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdBy: json['created_by'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  ScheduleProject copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? name,
    String? description,
    ScheduleProjectStatus? status,
    DateTime? plannedStart,
    DateTime? plannedFinish,
    DateTime? actualStart,
    DateTime? actualFinish,
    DateTime? dataDate,
    String? defaultCalendarId,
    DurationUnit? durationUnit,
    double? hoursPerDay,
    String? currency,
    double? overallPercentComplete,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ScheduleProject(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedFinish: plannedFinish ?? this.plannedFinish,
      actualStart: actualStart ?? this.actualStart,
      actualFinish: actualFinish ?? this.actualFinish,
      dataDate: dataDate ?? this.dataDate,
      defaultCalendarId: defaultCalendarId ?? this.defaultCalendarId,
      durationUnit: durationUnit ?? this.durationUnit,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      currency: currency ?? this.currency,
      overallPercentComplete:
          overallPercentComplete ?? this.overallPercentComplete,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static ScheduleProjectStatus _parseStatus(String? value) {
    if (value == null) return ScheduleProjectStatus.draft;
    switch (value) {
      case 'on_hold': return ScheduleProjectStatus.onHold;
      default:
        return ScheduleProjectStatus.values.firstWhere(
          (s) => s.name == value,
          orElse: () => ScheduleProjectStatus.draft,
        );
    }
  }

  static String _statusToString(ScheduleProjectStatus s) {
    if (s == ScheduleProjectStatus.onHold) return 'on_hold';
    return s.name;
  }

  static DurationUnit _parseDurationUnit(String? value) {
    if (value == null) return DurationUnit.days;
    return DurationUnit.values.firstWhere(
      (d) => d.name == value,
      orElse: () => DurationUnit.days,
    );
  }

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
