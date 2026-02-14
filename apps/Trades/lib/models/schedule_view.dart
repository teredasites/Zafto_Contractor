// ZAFTO Schedule View Model — Supabase Backend
// Maps to `schedule_views` table. Saved filter/view configurations per user.
// GC1: Phase GC foundation.

class ScheduleView {
  final String id;
  final String companyId;
  final String projectId;
  final String userId;
  final String name;
  final bool isDefault;
  final Map<String, dynamic> filters;
  final List<String> visibleColumns;
  final String sortBy;
  final String sortDirection;
  final String zoomLevel;
  final List<String> collapsedTasks;
  final bool showCriticalPath;
  final bool showFloat;
  final bool showBaselines;
  final bool showDependencies;
  final bool showResources;
  final bool showProgress;
  final String? baselineId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScheduleView({
    this.id = '',
    this.companyId = '',
    this.projectId = '',
    this.userId = '',
    this.name = '',
    this.isDefault = false,
    this.filters = const {},
    this.visibleColumns = const ['name', 'duration', 'start', 'finish', 'float', 'resources'],
    this.sortBy = 'sort_order',
    this.sortDirection = 'asc',
    this.zoomLevel = 'weeks',
    this.collapsedTasks = const [],
    this.showCriticalPath = true,
    this.showFloat = false,
    this.showBaselines = false,
    this.showDependencies = true,
    this.showResources = false,
    this.showProgress = true,
    this.baselineId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'project_id': projectId,
        'user_id': userId,
        'name': name,
        'is_default': isDefault,
        'filters': filters,
        'visible_columns': visibleColumns,
        'sort_by': sortBy,
        'sort_direction': sortDirection,
        'zoom_level': zoomLevel,
        'collapsed_tasks': collapsedTasks,
        'show_critical_path': showCriticalPath,
        'show_float': showFloat,
        'show_baselines': showBaselines,
        'show_dependencies': showDependencies,
        'show_resources': showResources,
        'show_progress': showProgress,
        if (baselineId != null) 'baseline_id': baselineId,
      };

  factory ScheduleView.fromJson(Map<String, dynamic> json) {
    return ScheduleView(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      filters: (json['filters'] as Map<String, dynamic>?) ?? const {},
      visibleColumns: _parseStringList(json['visible_columns']),
      sortBy: json['sort_by'] as String? ?? 'sort_order',
      sortDirection: json['sort_direction'] as String? ?? 'asc',
      zoomLevel: json['zoom_level'] as String? ?? 'weeks',
      collapsedTasks: _parseStringList(json['collapsed_tasks']),
      showCriticalPath: json['show_critical_path'] as bool? ?? true,
      showFloat: json['show_float'] as bool? ?? false,
      showBaselines: json['show_baselines'] as bool? ?? false,
      showDependencies: json['show_dependencies'] as bool? ?? true,
      showResources: json['show_resources'] as bool? ?? false,
      showProgress: json['show_progress'] as bool? ?? true,
      baselineId: json['baseline_id'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  ScheduleView copyWith({
    String? id, String? companyId, String? projectId, String? userId,
    String? name, bool? isDefault, Map<String, dynamic>? filters,
    List<String>? visibleColumns, String? sortBy, String? sortDirection,
    String? zoomLevel, List<String>? collapsedTasks,
    bool? showCriticalPath, bool? showFloat, bool? showBaselines,
    bool? showDependencies, bool? showResources, bool? showProgress,
    String? baselineId, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return ScheduleView(
      id: id ?? this.id, companyId: companyId ?? this.companyId,
      projectId: projectId ?? this.projectId, userId: userId ?? this.userId,
      name: name ?? this.name, isDefault: isDefault ?? this.isDefault,
      filters: filters ?? this.filters,
      visibleColumns: visibleColumns ?? this.visibleColumns,
      sortBy: sortBy ?? this.sortBy, sortDirection: sortDirection ?? this.sortDirection,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      collapsedTasks: collapsedTasks ?? this.collapsedTasks,
      showCriticalPath: showCriticalPath ?? this.showCriticalPath,
      showFloat: showFloat ?? this.showFloat,
      showBaselines: showBaselines ?? this.showBaselines,
      showDependencies: showDependencies ?? this.showDependencies,
      showResources: showResources ?? this.showResources,
      showProgress: showProgress ?? this.showProgress,
      baselineId: baselineId ?? this.baselineId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
