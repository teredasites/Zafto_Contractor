// Property Management Models — Maintenance Requests
// Maps to `maintenance_requests` and `work_order_actions` tables in Supabase PostgreSQL.
// Handles tenant maintenance requests and work order tracking.

enum MaintenanceUrgency {
  low,
  normal,
  high,
  emergency,
}

enum MaintenanceCategory {
  plumbing,
  electrical,
  hvac,
  appliance,
  structural,
  pest,
  landscaping,
  cleaning,
  painting,
  flooring,
  roofing,
  general,
  other,
}

enum MaintenanceStatus {
  submitted,
  reviewed,
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum WorkOrderActionType {
  created,
  assigned,
  scheduled,
  started,
  updated,
  completed,
  cancelled,
  note,
}

class MaintenanceRequest {
  final String id;
  final String companyId;
  final String propertyId;
  final String? unitId;
  final String? tenantId;
  final String title;
  final String? description;
  final MaintenanceUrgency urgency;
  final MaintenanceCategory category;
  final MaintenanceStatus status;
  final String? assignedTo;
  final String? vendorId;
  final double? estimatedCost;
  final double? actualCost;
  final String? jobId;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final List<String> photos;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceRequest({
    this.id = '',
    this.companyId = '',
    this.propertyId = '',
    this.unitId,
    this.tenantId,
    required this.title,
    this.description,
    this.urgency = MaintenanceUrgency.normal,
    this.category = MaintenanceCategory.general,
    this.status = MaintenanceStatus.submitted,
    this.assignedTo,
    this.vendorId,
    this.estimatedCost,
    this.actualCost,
    this.jobId,
    this.scheduledDate,
    this.completedDate,
    this.photos = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'company_id': companyId,
        'property_id': propertyId,
        if (unitId != null) 'unit_id': unitId,
        if (tenantId != null) 'tenant_id': tenantId,
        'title': title,
        if (description != null) 'description': description,
        'urgency': _enumToDb(urgency),
        'category': _enumToDb(category),
        'status': _enumToDb(status),
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (vendorId != null) 'vendor_id': vendorId,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
        if (actualCost != null) 'actual_cost': actualCost,
        if (jobId != null) 'job_id': jobId,
        if (scheduledDate != null)
          'scheduled_date': scheduledDate!.toUtc().toIso8601String(),
        if (completedDate != null)
          'completed_date': completedDate!.toUtc().toIso8601String(),
        'photos': photos,
        if (notes != null) 'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'unit_id': unitId,
        'tenant_id': tenantId,
        'title': title,
        'description': description,
        'urgency': _enumToDb(urgency),
        'category': _enumToDb(category),
        'status': _enumToDb(status),
        'assigned_to': assignedTo,
        'vendor_id': vendorId,
        'estimated_cost': estimatedCost,
        'actual_cost': actualCost,
        'job_id': jobId,
        'scheduled_date': scheduledDate?.toUtc().toIso8601String(),
        'completed_date': completedDate?.toUtc().toIso8601String(),
        'photos': photos,
        'notes': notes,
      };

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequest(
      id: json['id'] as String? ?? '',
      companyId:
          (json['company_id'] ?? json['companyId']) as String? ?? '',
      propertyId:
          (json['property_id'] ?? json['propertyId']) as String? ?? '',
      unitId: (json['unit_id'] ?? json['unitId']) as String?,
      tenantId: (json['tenant_id'] ?? json['tenantId']) as String?,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      urgency: _parseEnum(
        (json['urgency'] as String?),
        MaintenanceUrgency.values,
        MaintenanceUrgency.normal,
      ),
      category: _parseEnum(
        (json['category'] as String?),
        MaintenanceCategory.values,
        MaintenanceCategory.general,
      ),
      status: _parseEnum(
        (json['status'] as String?),
        MaintenanceStatus.values,
        MaintenanceStatus.submitted,
      ),
      assignedTo:
          (json['assigned_to'] ?? json['assignedTo']) as String?,
      vendorId: (json['vendor_id'] ?? json['vendorId']) as String?,
      estimatedCost:
          (json['estimated_cost'] ?? json['estimatedCost'] as num?)
              ?.toDouble(),
      actualCost:
          (json['actual_cost'] ?? json['actualCost'] as num?)?.toDouble(),
      jobId: (json['job_id'] ?? json['jobId']) as String?,
      scheduledDate: _parseDate(
          json['scheduled_date'] ?? json['scheduledDate']),
      completedDate: _parseDate(
          json['completed_date'] ?? json['completedDate']),
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ??
              DateTime.now(),
      updatedAt:
          _parseDate(json['updated_at'] ?? json['updatedAt']) ??
              DateTime.now(),
    );
  }

  MaintenanceRequest copyWith({
    String? id,
    String? companyId,
    String? propertyId,
    String? unitId,
    String? tenantId,
    String? title,
    String? description,
    MaintenanceUrgency? urgency,
    MaintenanceCategory? category,
    MaintenanceStatus? status,
    String? assignedTo,
    String? vendorId,
    double? estimatedCost,
    double? actualCost,
    String? jobId,
    DateTime? scheduledDate,
    DateTime? completedDate,
    List<String>? photos,
    String? notes,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      category: category ?? this.category,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      vendorId: vendorId ?? this.vendorId,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      jobId: jobId ?? this.jobId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static T _parseEnum<T extends Enum>(
    String? value,
    List<T> values,
    T defaultValue,
  ) {
    if (value == null || value.isEmpty) return defaultValue;
    for (final v in values) {
      if (v.name == value) return v;
    }
    final camel = _snakeToCamel(value);
    for (final v in values) {
      if (v.name == camel) return v;
    }
    return defaultValue;
  }

  static String _snakeToCamel(String value) {
    final parts = value.split('_');
    if (parts.length <= 1) return value;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty
            ? ''
            : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }

  static String _enumToDb<T extends Enum>(T value) {
    return value.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

class WorkOrderAction {
  final String id;
  final String maintenanceRequestId;
  final WorkOrderActionType actionType;
  final String? performedBy;
  final String? details;
  final DateTime createdAt;

  const WorkOrderAction({
    this.id = '',
    this.maintenanceRequestId = '',
    this.actionType = WorkOrderActionType.created,
    this.performedBy,
    this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toInsertJson() => {
        'maintenance_request_id': maintenanceRequestId,
        'action_type': MaintenanceRequest._enumToDb(actionType),
        if (performedBy != null) 'performed_by': performedBy,
        if (details != null) 'details': details,
      };

  // Work order actions are immutable (audit trail) — no toUpdateJson.

  factory WorkOrderAction.fromJson(Map<String, dynamic> json) {
    return WorkOrderAction(
      id: json['id'] as String? ?? '',
      maintenanceRequestId:
          (json['maintenance_request_id'] ?? json['maintenanceRequestId'])
              as String? ??
          '',
      actionType: MaintenanceRequest._parseEnum(
        (json['action_type'] ?? json['actionType']) as String?,
        WorkOrderActionType.values,
        WorkOrderActionType.created,
      ),
      performedBy:
          (json['performed_by'] ?? json['performedBy']) as String?,
      details: json['details'] as String?,
      createdAt:
          MaintenanceRequest._parseDate(
              json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  WorkOrderAction copyWith({
    String? id,
    String? maintenanceRequestId,
    WorkOrderActionType? actionType,
    String? performedBy,
    String? details,
  }) {
    return WorkOrderAction(
      id: id ?? this.id,
      maintenanceRequestId:
          maintenanceRequestId ?? this.maintenanceRequestId,
      actionType: actionType ?? this.actionType,
      performedBy: performedBy ?? this.performedBy,
      details: details ?? this.details,
      createdAt: createdAt,
    );
  }
}
