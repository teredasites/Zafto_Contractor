// ZAFTO Schedule Baseline Model — Supabase Backend
// Maps to `schedule_baselines` table. Named baseline snapshots.
// GC1: Phase GC foundation.

class ScheduleBaseline {
  final String id;
  final String companyId;
  final String projectId;
  final String name;
  final String? description;
  final int baselineNumber;
  final DateTime capturedAt;
  final String? capturedBy;
  final DateTime? dataDate;
  final DateTime? plannedStart;
  final DateTime? plannedFinish;
  final int totalTasks;
  final int totalMilestones;
  final double totalCost;
  final bool isActive;
  final DateTime createdAt;

  const ScheduleBaseline({
    this.id = '',
    this.companyId = '',
    this.projectId = '',
    this.name = '',
    this.description,
    this.baselineNumber = 1,
    required this.capturedAt,
    this.capturedBy,
    this.dataDate,
    this.plannedStart,
    this.plannedFinish,
    this.totalTasks = 0,
    this.totalMilestones = 0,
    this.totalCost = 0,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'project_id': projectId,
        'name': name,
        if (description != null) 'description': description,
        'baseline_number': baselineNumber,
        if (dataDate != null) 'data_date': _dateString(dataDate!),
        if (plannedStart != null) 'planned_start': _dateString(plannedStart!),
        if (plannedFinish != null) 'planned_finish': _dateString(plannedFinish!),
        'total_tasks': totalTasks,
        'total_milestones': totalMilestones,
        'total_cost': totalCost,
        'is_active': isActive,
      };

  factory ScheduleBaseline.fromJson(Map<String, dynamic> json) {
    return ScheduleBaseline(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      baselineNumber: json['baseline_number'] as int? ?? 1,
      capturedAt: _parseDate(json['captured_at']),
      capturedBy: json['captured_by'] as String?,
      dataDate: _parseDateNullable(json['data_date']),
      plannedStart: _parseDateNullable(json['planned_start']),
      plannedFinish: _parseDateNullable(json['planned_finish']),
      totalTasks: json['total_tasks'] as int? ?? 0,
      totalMilestones: json['total_milestones'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
    );
  }

  ScheduleBaseline copyWith({
    String? id, String? companyId, String? projectId, String? name,
    String? description, int? baselineNumber, DateTime? capturedAt,
    String? capturedBy, DateTime? dataDate,
    DateTime? plannedStart, DateTime? plannedFinish,
    int? totalTasks, int? totalMilestones, double? totalCost,
    bool? isActive, DateTime? createdAt,
  }) {
    return ScheduleBaseline(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId, name: name ?? this.name,
      description: description ?? this.description,
      baselineNumber: baselineNumber ?? this.baselineNumber,
      capturedAt: capturedAt ?? this.capturedAt,
      capturedBy: capturedBy ?? this.capturedBy,
      dataDate: dataDate ?? this.dataDate,
      plannedStart: plannedStart ?? this.plannedStart,
      plannedFinish: plannedFinish ?? this.plannedFinish,
      totalTasks: totalTasks ?? this.totalTasks,
      totalMilestones: totalMilestones ?? this.totalMilestones,
      totalCost: totalCost ?? this.totalCost,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
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
