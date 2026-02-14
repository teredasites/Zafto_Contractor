// ZAFTO Schedule Dependency Model — Supabase Backend
// Maps to `schedule_dependencies` table. FS/FF/SS/SF with lag/lead.
// GC1: Phase GC foundation.

enum DependencyType { FS, FF, SS, SF }

class ScheduleDependency {
  final String id;
  final String companyId;
  final String projectId;
  final String predecessorId;
  final String successorId;
  final DependencyType dependencyType;
  final double lagDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleDependency({
    this.id = '',
    this.companyId = '',
    this.projectId = '',
    this.predecessorId = '',
    this.successorId = '',
    this.dependencyType = DependencyType.FS,
    this.lagDays = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLag => lagDays != 0;
  bool get isLead => lagDays < 0;
  String get label => '${dependencyType.name}${lagDays != 0 ? (lagDays > 0 ? '+${lagDays.toStringAsFixed(0)}d' : '${lagDays.toStringAsFixed(0)}d') : ''}';

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'project_id': projectId,
        'predecessor_id': predecessorId,
        'successor_id': successorId,
        'dependency_type': dependencyType.name,
        'lag_days': lagDays,
      };

  factory ScheduleDependency.fromJson(Map<String, dynamic> json) {
    return ScheduleDependency(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      predecessorId: json['predecessor_id'] as String? ?? '',
      successorId: json['successor_id'] as String? ?? '',
      dependencyType: _parseDependencyType(json['dependency_type'] as String?),
      lagDays: (json['lag_days'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  ScheduleDependency copyWith({
    String? id, String? companyId, String? projectId,
    String? predecessorId, String? successorId,
    DependencyType? dependencyType, double? lagDays,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ScheduleDependency(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId,
      predecessorId: predecessorId ?? this.predecessorId,
      successorId: successorId ?? this.successorId,
      dependencyType: dependencyType ?? this.dependencyType,
      lagDays: lagDays ?? this.lagDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DependencyType _parseDependencyType(String? value) {
    if (value == null) return DependencyType.FS;
    return DependencyType.values.firstWhere(
      (d) => d.name == value, orElse: () => DependencyType.FS,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
