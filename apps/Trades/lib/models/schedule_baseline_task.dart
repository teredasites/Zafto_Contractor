// ZAFTO Schedule Baseline Task Model — Supabase Backend
// Maps to `schedule_baseline_tasks` table. Task state at baseline capture.
// Immutable record — no updates allowed.
// GC1: Phase GC foundation.

class ScheduleBaselineTask {
  final String id;
  final String companyId;
  final String baselineId;
  final String taskId;
  final String? name;
  final String? wbsCode;
  final String? taskType;
  final double? originalDuration;
  final DateTime? plannedStart;
  final DateTime? plannedFinish;
  final DateTime? earlyStart;
  final DateTime? earlyFinish;
  final DateTime? lateStart;
  final DateTime? lateFinish;
  final double? totalFloat;
  final double? freeFloat;
  final bool? isCritical;
  final double? budgetedCost;
  final double? percentComplete;
  final DateTime createdAt;

  const ScheduleBaselineTask({
    this.id = '',
    this.companyId = '',
    this.baselineId = '',
    this.taskId = '',
    this.name,
    this.wbsCode,
    this.taskType,
    this.originalDuration,
    this.plannedStart,
    this.plannedFinish,
    this.earlyStart,
    this.earlyFinish,
    this.lateStart,
    this.lateFinish,
    this.totalFloat,
    this.freeFloat,
    this.isCritical,
    this.budgetedCost,
    this.percentComplete,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'baseline_id': baselineId,
        'task_id': taskId,
        if (name != null) 'name': name,
        if (wbsCode != null) 'wbs_code': wbsCode,
        if (taskType != null) 'task_type': taskType,
        if (originalDuration != null) 'original_duration': originalDuration,
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        if (earlyStart != null) 'early_start': _dateString(earlyStart!),
        if (earlyFinish != null) 'early_finish': _dateString(earlyFinish!),
        if (lateStart != null) 'late_start': _dateString(lateStart!),
        if (lateFinish != null) 'late_finish': _dateString(lateFinish!),
        if (totalFloat != null) 'total_float': totalFloat,
        if (freeFloat != null) 'free_float': freeFloat,
        if (isCritical != null) 'is_critical': isCritical,
        if (budgetedCost != null) 'budgeted_cost': budgetedCost,
        if (percentComplete != null) 'percent_complete': percentComplete,
      };

  factory ScheduleBaselineTask.fromJson(Map<String, dynamic> json) {
    return ScheduleBaselineTask(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      baselineId: json['baseline_id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      name: json['name'] as String?,
      wbsCode: json['wbs_code'] as String?,
      taskType: json['task_type'] as String?,
      originalDuration: (json['original_duration'] as num?)?.toDouble(),
      plannedStart: _parseDateNullable(json['planned_start']),
      plannedFinish: _parseDateNullable(json['planned_finish']),
      earlyStart: _parseDateNullable(json['early_start']),
      earlyFinish: _parseDateNullable(json['early_finish']),
      lateStart: _parseDateNullable(json['late_start']),
      lateFinish: _parseDateNullable(json['late_finish']),
      totalFloat: (json['total_float'] as num?)?.toDouble(),
      freeFloat: (json['free_float'] as num?)?.toDouble(),
      isCritical: json['is_critical'] as bool?,
      budgetedCost: (json['budgeted_cost'] as num?)?.toDouble(),
      percentComplete: (json['percent_complete'] as num?)?.toDouble(),
      createdAt: _parseDate(json['created_at']),
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
