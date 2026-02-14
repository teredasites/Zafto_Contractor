// ZAFTO Schedule Calendar Model — Supabase Backend
// Maps to `schedule_calendars` table. Work calendar definitions.
// GC1: Phase GC foundation.

class ScheduleCalendar {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final String calendarType;
  final int workDaysMask; // bitmask: Mon=1 Tue=2 Wed=4 Thu=8 Fri=16 Sat=32 Sun=64
  final String workStartTime;
  final String workEndTime;
  final double hoursPerDay;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ScheduleCalendar({
    this.id = '',
    this.companyId = '',
    this.name = '',
    this.description,
    this.calendarType = 'standard',
    this.workDaysMask = 31, // Mon-Fri
    this.workStartTime = '07:00',
    this.workEndTime = '15:30',
    this.hoursPerDay = 8,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Check if a specific day of the week is a work day
  // DateTime.weekday: Mon=1 .. Sun=7
  bool isWorkDay(int weekday) {
    final bit = 1 << (weekday - 1); // Mon=1, Tue=2, Wed=4...
    return (workDaysMask & bit) != 0;
  }

  List<String> get workDayNames {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return [
      for (int i = 0; i < 7; i++)
        if ((workDaysMask & (1 << i)) != 0) days[i],
    ];
  }

  int get workDaysPerWeek {
    int count = 0;
    for (int i = 0; i < 7; i++) {
      if ((workDaysMask & (1 << i)) != 0) count++;
    }
    return count;
  }

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'name': name,
        if (description != null) 'description': description,
        'calendar_type': calendarType,
        'work_days_mask': workDaysMask,
        'work_start_time': workStartTime,
        'work_end_time': workEndTime,
        'hours_per_day': hoursPerDay,
        'is_default': isDefault,
      };

  factory ScheduleCalendar.fromJson(Map<String, dynamic> json) {
    return ScheduleCalendar(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      calendarType: json['calendar_type'] as String? ?? 'standard',
      workDaysMask: json['work_days_mask'] as int? ?? 31,
      workStartTime: json['work_start_time'] as String? ?? '07:00',
      workEndTime: json['work_end_time'] as String? ?? '15:30',
      hoursPerDay: (json['hours_per_day'] as num?)?.toDouble() ?? 8,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  ScheduleCalendar copyWith({
    String? id, String? companyId, String? name, String? description,
    String? calendarType, int? workDaysMask,
    String? workStartTime, String? workEndTime,
    double? hoursPerDay, bool? isDefault,
    DateTime? createdAt, DateTime? updatedAt, DateTime? deletedAt,
  }) {
    return ScheduleCalendar(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      name: name ?? this.name, description: description ?? this.description,
      calendarType: calendarType ?? this.calendarType,
      workDaysMask: workDaysMask ?? this.workDaysMask,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
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
