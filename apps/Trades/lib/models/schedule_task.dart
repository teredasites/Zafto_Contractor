// ZAFTO Schedule Task Model — Supabase Backend
// Maps to `schedule_tasks` table. Core task with WBS hierarchy + CPM fields.
// GC1: Phase GC foundation.

enum ScheduleTaskType { task, milestone, summary, hammock }

enum ConstraintType { asap, alap, snet, snlt, fnet, fnlt, mso, mfo }

class ScheduleTask {
  final String id;
  final String companyId;
  final String projectId;
  final String? parentId;
  final String? wbsCode;
  final int sortOrder;
  final int indentLevel;
  final String name;
  final String? description;
  final ScheduleTaskType taskType;
  // Duration & Progress
  final double? originalDuration;
  final double? remainingDuration;
  final double? actualDuration;
  final double percentComplete;
  // Dates
  final DateTime? plannedStart;
  final DateTime? plannedFinish;
  final DateTime? actualStart;
  final DateTime? actualFinish;
  // CPM calculated
  final DateTime? earlyStart;
  final DateTime? earlyFinish;
  final DateTime? lateStart;
  final DateTime? lateFinish;
  final double? totalFloat;
  final double? freeFloat;
  final bool isCritical;
  // Constraints
  final ConstraintType constraintType;
  final DateTime? constraintDate;
  // Calendar override
  final String? calendarId;
  // ZAFTO integration
  final String? jobId;
  final String? estimateItemId;
  final String? assignedTo;
  // Costing
  final double budgetedCost;
  final double actualCost;
  // Display
  final String? color;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const ScheduleTask({
    this.id = '',
    this.companyId = '',
    this.projectId = '',
    this.parentId,
    this.wbsCode,
    this.sortOrder = 0,
    this.indentLevel = 0,
    this.name = '',
    this.description,
    this.taskType = ScheduleTaskType.task,
    this.originalDuration,
    this.remainingDuration,
    this.actualDuration,
    this.percentComplete = 0,
    this.plannedStart,
    this.plannedFinish,
    this.actualStart,
    this.actualFinish,
    this.earlyStart,
    this.earlyFinish,
    this.lateStart,
    this.lateFinish,
    this.totalFloat,
    this.freeFloat,
    this.isCritical = false,
    this.constraintType = ConstraintType.asap,
    this.constraintDate,
    this.calendarId,
    this.jobId,
    this.estimateItemId,
    this.assignedTo,
    this.budgetedCost = 0,
    this.actualCost = 0,
    this.color,
    this.notes,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isMilestone => taskType == ScheduleTaskType.milestone;
  bool get isSummary => taskType == ScheduleTaskType.summary;
  bool get isComplete => percentComplete >= 100;
  bool get isStarted => percentComplete > 0 || actualStart != null;
  double get costVariance => budgetedCost - actualCost;

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'project_id': projectId,
        if (parentId != null) 'parent_id': parentId,
        if (wbsCode != null) 'wbs_code': wbsCode,
        'sort_order': sortOrder,
        'indent_level': indentLevel,
        'name': name,
        if (description != null) 'description': description,
        'task_type': taskType.name,
        if (originalDuration != null) 'original_duration': originalDuration,
        if (remainingDuration != null) 'remaining_duration': remainingDuration,
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        'constraint_type': constraintType.name,
        if (constraintDate != null) 'constraint_date': _dateString(constraintDate!),
        if (calendarId != null) 'calendar_id': calendarId,
        if (jobId != null) 'job_id': jobId,
        if (estimateItemId != null) 'estimate_item_id': estimateItemId,
        if (assignedTo != null) 'assigned_to': assignedTo,
        'budgeted_cost': budgetedCost,
        if (color != null) 'color': color,
        if (notes != null) 'notes': notes,
        'metadata': metadata,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        if (parentId != null) 'parent_id': parentId,
        if (wbsCode != null) 'wbs_code': wbsCode,
        'sort_order': sortOrder,
        'indent_level': indentLevel,
        if (description != null) 'description': description,
        'task_type': taskType.name,
        if (originalDuration != null) 'original_duration': originalDuration,
        if (remainingDuration != null) 'remaining_duration': remainingDuration,
        if (actualDuration != null) 'actual_duration': actualDuration,
        'percent_complete': percentComplete,
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        if (actualStart != null) 'actual_start': _dateString(actualStart!),
        if (actualFinish != null) 'actual_finish': _dateString(actualFinish!),
        'constraint_type': constraintType.name,
        if (constraintDate != null) 'constraint_date': _dateString(constraintDate!),
        if (calendarId != null) 'calendar_id': calendarId,
        if (assignedTo != null) 'assigned_to': assignedTo,
        'budgeted_cost': budgetedCost,
        'actual_cost': actualCost,
        if (color != null) 'color': color,
        if (notes != null) 'notes': notes,
        'metadata': metadata,
      };

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    return ScheduleTask(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      wbsCode: json['wbs_code'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      indentLevel: json['indent_level'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      taskType: _parseTaskType(json['task_type'] as String?),
      originalDuration: (json['original_duration'] as num?)?.toDouble(),
      remainingDuration: (json['remaining_duration'] as num?)?.toDouble(),
      actualDuration: (json['actual_duration'] as num?)?.toDouble(),
      percentComplete: (json['percent_complete'] as num?)?.toDouble() ?? 0,
      plannedStart: _parseDateNullable(json['planned_start']),
      plannedFinish: _parseDateNullable(json['planned_finish']),
      actualStart: _parseDateNullable(json['actual_start']),
      actualFinish: _parseDateNullable(json['actual_finish']),
      earlyStart: _parseDateNullable(json['early_start']),
      earlyFinish: _parseDateNullable(json['early_finish']),
      lateStart: _parseDateNullable(json['late_start']),
      lateFinish: _parseDateNullable(json['late_finish']),
      totalFloat: (json['total_float'] as num?)?.toDouble(),
      freeFloat: (json['free_float'] as num?)?.toDouble(),
      isCritical: json['is_critical'] as bool? ?? false,
      constraintType: _parseConstraint(json['constraint_type'] as String?),
      constraintDate: _parseDateNullable(json['constraint_date']),
      calendarId: json['calendar_id'] as String?,
      jobId: json['job_id'] as String?,
      estimateItemId: json['estimate_item_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      budgetedCost: (json['budgeted_cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String?,
      notes: json['notes'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseDateNullable(json['deleted_at']),
    );
  }

  ScheduleTask copyWith({
    String? id, String? companyId, String? projectId, String? parentId,
    String? wbsCode, int? sortOrder, int? indentLevel, String? name,
    String? description, ScheduleTaskType? taskType,
    double? originalDuration, double? remainingDuration, double? actualDuration,
    double? percentComplete,
    DateTime? plannedStart, DateTime? plannedFinish,
    DateTime? actualStart, DateTime? actualFinish,
    DateTime? earlyStart, DateTime? earlyFinish,
    DateTime? lateStart, DateTime? lateFinish,
    double? totalFloat, double? freeFloat, bool? isCritical,
    ConstraintType? constraintType, DateTime? constraintDate,
    String? calendarId, String? jobId, String? estimateItemId, String? assignedTo,
    double? budgetedCost, double? actualCost,
    String? color, String? notes, Map<String, dynamic>? metadata,
    DateTime? createdAt, DateTime? updatedAt, DateTime? deletedAt,
  }) {
    return ScheduleTask(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId, parentId: parentId ?? this.parentId,
      wbsCode: wbsCode ?? this.wbsCode, sortOrder: sortOrder ?? this.sortOrder,
      indentLevel: indentLevel ?? this.indentLevel, name: name ?? this.name,
      description: description ?? this.description, taskType: taskType ?? this.taskType,
      originalDuration: originalDuration ?? this.originalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      percentComplete: percentComplete ?? this.percentComplete,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedFinish: plannedFinish ?? this.plannedFinish,
      actualStart: actualStart ?? this.actualStart,
      actualFinish: actualFinish ?? this.actualFinish,
      earlyStart: earlyStart ?? this.earlyStart,
      earlyFinish: earlyFinish ?? this.earlyFinish,
      lateStart: lateStart ?? this.lateStart,
      lateFinish: lateFinish ?? this.lateFinish,
      totalFloat: totalFloat ?? this.totalFloat,
      freeFloat: freeFloat ?? this.freeFloat,
      isCritical: isCritical ?? this.isCritical,
      constraintType: constraintType ?? this.constraintType,
      constraintDate: constraintDate ?? this.constraintDate,
      calendarId: calendarId ?? this.calendarId,
      jobId: jobId ?? this.jobId,
      estimateItemId: estimateItemId ?? this.estimateItemId,
      assignedTo: assignedTo ?? this.assignedTo,
      budgetedCost: budgetedCost ?? this.budgetedCost,
      actualCost: actualCost ?? this.actualCost,
      color: color ?? this.color, notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static ScheduleTaskType _parseTaskType(String? value) {
    if (value == null) return ScheduleTaskType.task;
    return ScheduleTaskType.values.firstWhere(
      (t) => t.name == value, orElse: () => ScheduleTaskType.task,
    );
  }

  static ConstraintType _parseConstraint(String? value) {
    if (value == null) return ConstraintType.asap;
    return ConstraintType.values.firstWhere(
      (c) => c.name == value, orElse: () => ConstraintType.asap,
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
