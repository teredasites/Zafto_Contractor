// ZAFTO Punch List Item Model — Supabase Backend
// Maps to `punch_list_items` table in Supabase PostgreSQL.
// Task checklist for jobs: open → in_progress → completed/skipped.

enum PunchListPriority {
  low,
  normal,
  high,
  urgent;

  String get dbValue => name;

  String get label {
    switch (this) {
      case PunchListPriority.low:
        return 'Low';
      case PunchListPriority.normal:
        return 'Normal';
      case PunchListPriority.high:
        return 'High';
      case PunchListPriority.urgent:
        return 'Urgent';
    }
  }

  static PunchListPriority fromString(String? value) {
    if (value == null) return PunchListPriority.normal;
    return PunchListPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => PunchListPriority.normal,
    );
  }
}

enum PunchListStatus {
  open,
  inProgress,
  completed,
  skipped;

  String get dbValue {
    switch (this) {
      case PunchListStatus.open:
        return 'open';
      case PunchListStatus.inProgress:
        return 'in_progress';
      case PunchListStatus.completed:
        return 'completed';
      case PunchListStatus.skipped:
        return 'skipped';
    }
  }

  String get label {
    switch (this) {
      case PunchListStatus.open:
        return 'Open';
      case PunchListStatus.inProgress:
        return 'In Progress';
      case PunchListStatus.completed:
        return 'Completed';
      case PunchListStatus.skipped:
        return 'Skipped';
    }
  }

  static PunchListStatus fromString(String? value) {
    if (value == null) return PunchListStatus.open;
    switch (value) {
      case 'open':
        return PunchListStatus.open;
      case 'in_progress':
        return PunchListStatus.inProgress;
      case 'completed':
        return PunchListStatus.completed;
      case 'skipped':
        return PunchListStatus.skipped;
      default:
        return PunchListStatus.open;
    }
  }
}

class PunchListItem {
  final String id;
  final String companyId;
  final String jobId;
  final String createdByUserId;
  final String? assignedToUserId;
  final String title;
  final String? description;
  final String? category;
  final PunchListPriority priority;
  final PunchListStatus status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? completedByUserId;
  final List<String> photoIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  PunchListItem({
    this.id = '',
    this.companyId = '',
    this.jobId = '',
    this.createdByUserId = '',
    this.assignedToUserId,
    required this.title,
    this.description,
    this.category,
    this.priority = PunchListPriority.normal,
    this.status = PunchListStatus.open,
    this.dueDate,
    this.completedAt,
    this.completedByUserId,
    this.photoIds = const [],
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isNew => id.isEmpty;
  bool get isOpen => status == PunchListStatus.open;
  bool get isCompleted => status == PunchListStatus.completed;
  bool get isDone =>
      status == PunchListStatus.completed || status == PunchListStatus.skipped;

  // Supabase INSERT — omit id, created_at, updated_at (DB defaults).
  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'job_id': jobId,
        'created_by_user_id': createdByUserId,
        if (assignedToUserId != null) 'assigned_to_user_id': assignedToUserId,
        'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        'priority': priority.dbValue,
        'status': status.dbValue,
        if (dueDate != null) 'due_date': _formatDate(dueDate!),
        'photo_ids': photoIds,
        'sort_order': sortOrder,
      };

  // Supabase UPDATE — editable fields.
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'category': category,
        'priority': priority.dbValue,
        'status': status.dbValue,
        'assigned_to_user_id': assignedToUserId,
        'due_date': dueDate != null ? _formatDate(dueDate!) : null,
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'completed_by_user_id': completedByUserId,
        'photo_ids': photoIds,
        'sort_order': sortOrder,
      };

  factory PunchListItem.fromJson(Map<String, dynamic> json) {
    return PunchListItem(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String? ?? '',
      jobId: json['job_id'] as String? ?? '',
      createdByUserId: json['created_by_user_id'] as String? ?? '',
      assignedToUserId: json['assigned_to_user_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      priority: PunchListPriority.fromString(json['priority'] as String?),
      status: PunchListStatus.fromString(json['status'] as String?),
      dueDate: _parseOptionalDate(json['due_date']),
      completedAt: _parseOptionalTimestamp(json['completed_at']),
      completedByUserId: json['completed_by_user_id'] as String?,
      photoIds: (json['photo_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: _parseTimestamp(json['created_at']),
      updatedAt: _parseTimestamp(json['updated_at']),
    );
  }

  PunchListItem copyWith({
    String? id,
    String? companyId,
    String? jobId,
    String? createdByUserId,
    String? assignedToUserId,
    String? title,
    String? description,
    String? category,
    PunchListPriority? priority,
    PunchListStatus? status,
    DateTime? dueDate,
    DateTime? completedAt,
    String? completedByUserId,
    List<String>? photoIds,
    int? sortOrder,
  }) {
    return PunchListItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      jobId: jobId ?? this.jobId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      completedByUserId: completedByUserId ?? this.completedByUserId,
      photoIds: photoIds ?? this.photoIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}
