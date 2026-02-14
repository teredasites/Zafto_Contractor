// ZAFTO Schedule Calendar Exception Model — Supabase Backend
// Maps to `schedule_calendar_exceptions` table.
// Holidays, weather days, overtime, half days, shutdowns.
// GC1: Phase GC foundation.

enum ExceptionType { holiday, weather, overtime, halfDay, shutdown }

class ScheduleCalendarException {
  final String id;
  final String companyId;
  final String calendarId;
  final DateTime exceptionDate;
  final ExceptionType exceptionType;
  final String? name;
  final String? workStartTime;
  final String? workEndTime;
  final double? hoursAvailable;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleCalendarException({
    this.id = '',
    this.companyId = '',
    this.calendarId = '',
    required this.exceptionDate,
    this.exceptionType = ExceptionType.holiday,
    this.name,
    this.workStartTime,
    this.workEndTime,
    this.hoursAvailable,
    this.isRecurring = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isNonWorkDay =>
      exceptionType == ExceptionType.holiday ||
      exceptionType == ExceptionType.weather ||
      exceptionType == ExceptionType.shutdown;

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'calendar_id': calendarId,
        'exception_date': _dateString(exceptionDate),
        'exception_type': _typeToString(exceptionType),
        if (name != null) 'name': name,
        if (workStartTime != null) 'work_start_time': workStartTime,
        if (workEndTime != null) 'work_end_time': workEndTime,
        if (hoursAvailable != null) 'hours_available': hoursAvailable,
        'is_recurring': isRecurring,
      };

  factory ScheduleCalendarException.fromJson(Map<String, dynamic> json) {
    return ScheduleCalendarException(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      calendarId: json['calendar_id'] as String? ?? '',
      exceptionDate: _parseDate(json['exception_date']),
      exceptionType: _parseType(json['exception_type'] as String?),
      name: json['name'] as String?,
      workStartTime: json['work_start_time'] as String?,
      workEndTime: json['work_end_time'] as String?,
      hoursAvailable: (json['hours_available'] as num?)?.toDouble(),
      isRecurring: json['is_recurring'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  ScheduleCalendarException copyWith({
    String? id, String? companyId, String? calendarId,
    DateTime? exceptionDate, ExceptionType? exceptionType, String? name,
    String? workStartTime, String? workEndTime, double? hoursAvailable,
    bool? isRecurring, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ScheduleCalendarException(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      calendarId: calendarId ?? this.calendarId,
      exceptionDate: exceptionDate ?? this.exceptionDate,
      exceptionType: exceptionType ?? this.exceptionType,
      name: name ?? this.name,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      hoursAvailable: hoursAvailable ?? this.hoursAvailable,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ExceptionType _parseType(String? value) {
    if (value == null) return ExceptionType.holiday;
    switch (value) {
      case 'half_day': return ExceptionType.halfDay;
      default:
        return ExceptionType.values.firstWhere(
          (e) => e.name == value, orElse: () => ExceptionType.holiday,
        );
    }
  }

  static String _typeToString(ExceptionType t) {
    if (t == ExceptionType.halfDay) return 'half_day';
    return t.name;
  }

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
