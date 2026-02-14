// ZAFTO Schedule Task Resource Model — Supabase Backend
// Maps to `schedule_task_resources` table. Resource allocation per task.
// GC1: Phase GC foundation.

class ScheduleTaskResource {
  final String id;
  final String companyId;
  final String taskId;
  final String resourceId;
  final double unitsAssigned;
  final double? hoursPerDay;
  final double budgetedCost;
  final double actualCost;
  final double? quantityNeeded;
  final double quantityUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleTaskResource({
    this.id = '',
    this.companyId = '',
    this.taskId = '',
    this.resourceId = '',
    this.unitsAssigned = 1,
    this.hoursPerDay,
    this.budgetedCost = 0,
    this.actualCost = 0,
    this.quantityNeeded,
    this.quantityUsed = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get costVariance => budgetedCost - actualCost;
  double get quantityRemaining =>
      (quantityNeeded ?? 0) - quantityUsed;

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'task_id': taskId,
        'resource_id': resourceId,
        'units_assigned': unitsAssigned,
        if (hoursPerDay != null) 'hours_per_day': hoursPerDay,
        'budgeted_cost': budgetedCost,
        if (quantityNeeded != null) 'quantity_needed': quantityNeeded,
      };

  factory ScheduleTaskResource.fromJson(Map<String, dynamic> json) {
    return ScheduleTaskResource(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      resourceId: json['resource_id'] as String? ?? '',
      unitsAssigned: (json['units_assigned'] as num?)?.toDouble() ?? 1,
      hoursPerDay: (json['hours_per_day'] as num?)?.toDouble(),
      budgetedCost: (json['budgeted_cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      quantityNeeded: (json['quantity_needed'] as num?)?.toDouble(),
      quantityUsed: (json['quantity_used'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  ScheduleTaskResource copyWith({
    String? id, String? companyId, String? taskId, String? resourceId,
    double? unitsAssigned, double? hoursPerDay,
    double? budgetedCost, double? actualCost,
    double? quantityNeeded, double? quantityUsed,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ScheduleTaskResource(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      taskId: taskId ?? this.taskId, resourceId: resourceId ?? this.resourceId,
      unitsAssigned: unitsAssigned ?? this.unitsAssigned,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      budgetedCost: budgetedCost ?? this.budgetedCost,
      actualCost: actualCost ?? this.actualCost,
      quantityNeeded: quantityNeeded ?? this.quantityNeeded,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
